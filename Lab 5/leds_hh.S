/*      leds_hh.S
        Written 10/8/2014 by Henry_Huang@hmc.edu
        Play notes written into file        */

#   #include <P32xxxx.h>

#       Define constants

#     Timer setup values
# 1101_0000_0011_0000
#define     T1SET       0xD030      
# 1100_0000_0010_0000
#define     T2SET       0xC020      

#     Output port markers

# 1111_1111_1011_1111
#define     NOTPORT     0xFFBF      
# 0000_0000_0100_0000
#define     PORTSLOT    0x0040      

#     OP codes and special immediates

# Mask for note OP codes
#define     OP_MASK     0xF000      
# Mask for note immediates
#define     IM_MASK     0x0FFF
# OP code for stopping play      
#define     OP_STOP     0x0000      
# OP code for the top of a loop
#define     OP_LOOP     0x1000      
# Immediate for infinite loop
#define     IM_INF_LOOP	0x0000      
# OP code for the end of a loop
#define     OP_END_LOOP	0x2000      
        
        .global main

#       Compiler instructions
# store the code in the main program section of RAM
        .set noreorder    # do not let the compiler reorganize your code

# Main program

      .ent main    # Start function block

# This code outputs a square wave on the port G6 based on the
# notes written at the bottom of the file.
#
# The code takes advantage of the peripheral Timer 1 and Timer 2
# in order to monitor the duration and period respectively.
#
# Each timer has the following associated components:
#  
# Duration Timer:       TMR1, T1CON, T1SET, t1, t3, 2($t0)
#
# Period Timer:         TMR2, T2CON, T2SET, t2, t4, 0($t0)
#
#
# The following registers are used as given for the majority of the file:
#     sp:   stack pointer 
#     t0:   note pointer,                 setup addresses
#     t1:   duration timer address,       setup values
#     t2:   period timer address
#     t3:   note duration
#     t4:   note period,                  OP values
#     t5:   output port
#     t6:   auxillery register
 
main:
      
# timer config setup

      la    $t0,  T1CON             # Configure Timer 1 to be on [15], pause on
      li    $t1,  T1SET             # debug exception [14], and have a 1:256
      swr   $t1,  0($t0)            # prescale for 19.53 kHz [5:4].

      la    $t0,  T2CON             # Configure Timer 2 to be on [15], pause on
      li    $t1,  T2SET             # debug exception [14], and have a 1:4
      swr   $t1,  0($t0)            # prescale for 1.25 MHz [6:4].

# output config setup

      la    $t0,  TRISG             # Read the current tristate bits for port G
      lwr   $t1,  0($t0)            # and force the port tristate bit to be 0
      andi  $t1,  NOTPORT           # so we can use it as output. Afterwards,
      swr   $t1,  0($t0)            # place the modified tristate bits back.

      la    $t5,  PORTG             # Also, have $t5 point to our output port.

# song data pointer setup
      
      la    $t0,  _notes            # Set $t0 to point to the music notes,
      lhu   $t3,  2($t0)            # and have $t3 store the duration,
      lhu   $t4,  0($t0)            # and have $t4 store the period.

# timer value setup
      
      la    $t1,  TMR1              # Set $t1 to be the address of the duration
      swr   $0,   0($t1)            # timer, Timer 1, and reset it to 0.
      la    $t2,  TMR2              # Set $t2 to be the address of the period
      swr   $0,   0($t2)            # timer, Timer 2, and reset it to 0.

# main loop processing notes

main_loop:

# check if note duration is over

check_dur:
      beqz  $t3,  check_op          # 0 duration indicates an op code to check. 
      nop                           # Otherwise,
      lw    $t6,  0($t1)            # read the value of the duration timer. 
      blt   $t6,  $t3,  check_per   # Move on if the timer is below duration.
      nop                           # Otherwise,
      swr   $0,   0($t1)            # reset the duration timer,
      addi  $t0,  $t0,  4           # update $t0 to point to the next note,
      lhu   $t3,  2($t0)            # and update with the new duration
      lhu   $t4,  0($t0)            # and update with the new period.

# check if note semi-period is over

check_per:
      beqz  $t4,  check_dur         # 0 period indicates a rest to stop notes.
      nop                           # Otherwise,
      lw    $t6,  0($t2)            # read the value of the period timer.
      blt   $t6,  $t4,  check_dur   # Move on if the timer is below period.
      nop                           # Otherwise,
      swr   $0,   0($t2)            # reset the period timer,
      lw    $t6,  0($t5)            # read the current port output,
      xori  $t6,  $t6,  PORTSLOT    # swap the output of our slot,
      swr   $t6,  0($t5)            # and store the modified output.
      j     check_dur               # Afterwards, go back to checking duration.
      nop

# check which OP has been encountered
      
check_op:

      xori  $t6,  $t4,  OP_LOOP     # Check if the OP code
      andi  $t6,  $t6,  OP_MASK     # matches the loop OP code.
      beq   $t6,  $0,   mark_loop   # If it does, mark the loop point in stack.
      nop                           # Otherwise,
      xori  $t6,  $t4,  OP_END_LOOP # check if the OP code
      andi  $t6,  $t6,  OP_MASK     # matches the end loop OP code.
      beq   $t6,  $0,   loop_back   # If it does, loop back to the mark.
      nop                           # Otherwise,
      xori  $t6,  $t4,  OP_STOP     # check if the OP code
      andi  $t6,  $t6,  OP_MASK     # matches the stop OP code.
      beq   $t6,  $0,   shut_down   # If it does, shut down the music.
      nop                           # Otherwise,
      j     finish_op               # finish dealing with the unknown OP.
      nop

# mark the loop's beginning location and iteration count

mark_loop:
      andi  $t6,  $t4,  IM_MASK     # Mask out the desired number of loops
      addi  $sp,  $sp,  -8          # Allocate 2 words on the stack so
      sw    $t0,  4($sp)            # we can store the loop starting address
      sw    $t6,  0($sp)            # and the number of times we loop.
      j     finish_op               # Then, finish dealing with the OP.
      nop

# go back to the beginning of the loop if iterations are left

loop_back:
      lw    $t4,  0($sp)            # Read the remaining loop count.
      xori  $t6,  $t4,  IM_INF_LOOP # If the count indicates an infinite loop,
      beqz  $t6,  jump_back         # jump back to the beginning.
      nop                           # Otherwise,
      addi  $t6,  $t4,  -1          # decrement the number of remaining loops,
      sw    $t6,  0($sp)            # and update the number on the stack.
      bnez  $t6,  jump_back         # Jump back if we have loops left to do.
      nop                           # Otherwise,
      addi  $sp,  $sp,  8           # we no longer need this loop entry,
      j     finish_op               # and can finish dealing with the OP.
      nop
      
# move the note counter to the top of the loop

jump_back:
      lw    $t0,  4($sp)            # Set the note pointer to the loop start.

# move the note counter beyond the op once it is finished

finish_op:
      addi  $t0,  $t0,  4           # Move to the word after the finished OP,
      lhu   $t3,  2($t0)            # and load the new duration
      lhu   $t4,  0($t0)            # and load the new period.
      j     main_loop               # Then, go back to the main loop.
      nop
      
# Cleans up out output port once we're done, setting output to 0
# to minimize output voltage and ensuring that the tristate is no
# longer trying to output.
      
shut_down:

      lw    $t6,  0($t5)            # Load the value of Port G,
      andi  $t6,  $t6,  NOTPORT     # force our output to be 0,
      swr   $t6,  0($t5)            # and store it back in Port G.
      
      la    $t0,  TRISG             # Finally, load the value of the tristate
      lwr   $t1,  0($t0)            # controlling our output port,
      ori   $t1,  PORTSLOT          # set the tristate to no longer output,
      swr   $t1,  0($t0)            # and store it back into the tristate.
         
# Trap in infinite loop when over

finish:
      j     finish                  # Infinite loop after shut down.
      nop

     .end  main                     # End function block



# Song notes

#define     N_Ab      0xBC0
#define     N_A       0xB18      
#define     N_AS      0xA79
#define     N_Bb      0xA79 
#define     N_B       0x9E2      
#define     N_C       0x954 
#define     N_CS      0x8CE      
#define     N_Db      0x8CE 
#define     N_D       0x850 
#define     N_DS      0x7D8
#define     N_Eb      0x7D8      
#define     N_E       0x768 
#define     N_F       0x6FD      
#define     N_FS      0x699
#define     N_Gb      0x699 
#define     N_G       0x63A      
#define     N_GS      0x5E0 
#define     REST      0x000     

# This macro allows a song transcriber to just write down
# the pitch in terms of the given constants above,
# the octave of the note, and what division of 4 beats
# the note is to be played at. The macro also bases
# the tempo off the most recently set tempo above the
# note.


.macro  note freq=0, scale=3, part = 1
      .ifge     (\scale - 3)
            .HWORD  (\freq >> (\scale - 3))
      .else 
            .HWORD  (\freq << (3 - \scale))
      .endif
      .if     \part
            .HWORD  (TEMPO/\part)    
      .else
            .HWORD 0x0000
      .endif
.endm

# This macro marks the start of a loop.
# The number of times the section is played can
# be specified. By default, the value is set to
# 0, indicating an infinite loop. The section is
# defined to be all the notes between this marker
# and the nearest subsequent unmatched end_loop.

.macro  loop n_times = IM_INF_LOOP
.HWORD  (OP_LOOP | \n_times) , 0x0000
.endm

# This macro marks the end of a loop.
# The section of notes corresponding to
# this end loop are played again until
# the number of times specified at the top
# of the loop has been played.

.macro  end_loop
.HWORD  OP_END_LOOP, 0x0000
.endm

# This macro marks the end of the note playing,
# and the program will stop producing output
# once this point has been reached.

.macro  stop_play 
.HWORD  OP_STOP, 0x0000
.endm

      
	.section .rodata  # Store this information in FLASH instead of RAM
_notes:

_bday: 

#     Happy Birthday 
#
#     Sheet Music courtesy of:
#     http://www.8notes.com/scores/1110.asp

.set     TEMPO,       0x82CA  # 140 BPM
      
      note N_C,   3,    8
      note REST,  3,    16
      note N_C,   3,    16
      
      
      note N_D,   3,    4
      note N_C,   3,    4
      note N_F,   3,    4
      
      
      note N_E,   3,    2
      note N_C,   3,    8
      note REST,  3,    16
      note N_C,   3,    16
      
      
      note N_D,   3,    4
      note N_C,   3,    4
      note N_G,   3,    4
      
      note N_F,   3,    2
      note N_C,   3,    8
      note REST,  3,    16
      note N_C,   3,    16
      
      
      note N_C,   4,    4
      note N_A,   4,    4
      note N_F,   3,    4
      
      
      note N_E,   3,    4
      note N_D,   3,    4
      note N_Bb,  4,    8
      note REST,  4,    16
      note N_Bb,  4,    16
      
      
      note N_A,   4,    4
      note N_F,   3,    4
      note N_G,   3,    4
      
      note N_F,   3,    2
      note N_F,   3,    4     # End of Happy Birthday



      # Play: Together We Ride, Bicycle, and Bloody Tears 2 times.
      loop      

_we_ride:

#     Together We Ride
#     Fire Emblem
# 
#     Sheet Music courtesy of:
#     http://www.ninsheetm.us/sheets/FireEmblem/FireEmblem/TogetherweRide.pdf

.set     TEMPO,       0x5731  # 210 BPM
      
      loop 5                  # Play twice

      note N_E,   3,    4
      note REST,  3,    8
      note N_E,   3,    8
      note REST,  3,    8
      note N_E,   3,    8
      note REST,  3,    8
      note N_E,   3,    8


      note N_F,   3,    4
      note REST,  3,    8
      note N_F,   3,    8
      note REST,  3,    8
      note N_F,   3,    8
      note REST,  3,    8
      note N_F,   3,    8


      note N_G,   3,    4
      note REST,  3,    8
      note N_G,   3,    8
      note REST,  3,    8
      note N_G,   3,    8
      note REST,  3,    8
      note N_G,   3,    8


      note N_F,   3,    4
      note REST,  3,    8
      note N_F,   3,    8
      note REST,  3,    8
      note N_F,   3,    8
      note REST,  3,    8
      note N_F,   3,    8



      note N_E,   3,    4
      note REST,  3,    8
      note N_E,   3,    8
      note REST,  3,    8
      note N_E,   3,    8
      note REST,  3,    8
      note N_E,   3,    8


      note N_E,   3,    4
      note REST,  3,    8
      note N_E,   3,    8
      note REST,  3,    8
      note N_E,   3,    8
      note REST,  3,    8
      note N_E,   3,    8


      note N_E,   4,    4
      note REST,  3,    8
      note N_E,   4,    8
      note REST,  3,    8
      note N_E,   4,    8
      note REST,  3,    8
      note N_E,   4,    8


      note N_F,   4,    4
      note REST,  3,    8
      note N_F,   4,    8
      note REST,  3,    8
      note N_F,   4,    8
      note REST,  3,    8
      note N_F,   4,    8


      note N_G,   4,    4
      note REST,  3,    8
      note N_G,   4,    8
      note REST,  3,    8
      note N_G,   4,    8
      note REST,  3,    8
      note N_G,   4,    8



      note N_F,   4,    4
      note REST,  3,    8
      note N_F,   4,    8
      note REST,  3,    8
      note N_F,   4,    8
      note REST,  3,    8
      note N_F,   4,    8


      note N_E,   4,    4
      note REST,  3,    8
      note N_E,   4,    8
      note REST,  3,    8
      note N_E,   4,    8
      note REST,  3,    8
      note N_E,   4,    16
      note REST,  4,    16


      note N_E,   4,    4
      note REST,  3,    2
      note N_E,   3,    8
      note N_E,   3,    16
      note REST,  3,    16

      loop 3

      note N_E,   3,    8
      note N_D,   3,    8
      note N_E,   3,    8
      note N_F,   3,    2
      note N_A,   4,    8

      end_loop

      note N_G,   3,    8
      note N_A,   4,    8
      note N_G,   3,    8
      note N_F,   3,    8
      note N_E,   3,    8
      note N_D,   3,    8
      note N_C,   3,    8
      note N_E,   3,    8

      loop 3

      note N_E,   3,    8
      note N_D,   3,    8
      note N_E,   3,    8
      note N_A,   4,    4
      note N_A,   4,    8
      note N_A,   4,    16
      note REST,  4,    16
      note N_A,   4,    8

      end_loop

      note N_A,   4,    8
      note N_Bb,  4,    8
      note N_A,   4,    8
      note N_G,   3,    8
      note N_A,   4,    8
      note N_G,   3,    8
      note N_F,   3,    8
      note N_E,   3,    8

      loop 2

      note N_F,   3,    8
      note N_E,   3,    8
      note N_D,   3,    8
      note N_A,   3,    2
      note N_A,   3,    8

      end_loop

      note N_F,   3,    8
      note N_E,   3,    8
      note N_D,   3,    8
      note N_A,   3,    2
      note N_A,   3,    8

      note N_E,   3,    4
      note REST,  3,    8
      note N_D,   3,    4
      note N_D,   3,    8
      note N_A,   4,    8
      note REST,  4,    8

      end_loop                # End of Together We Ride


      

_bike:

#     Bicycle
#     Pokemon Gold
#
#     Sheet Music courtesy of:
#     http://www.ninsheetm.us/sheets/Pokemon/PokemonGoldSilver/Bicycle.pdf

.set     TEMPO,       0x82CA  # 140 BPM
      
      
      note N_D,   4,    4
      note N_D,   4,    8
      note N_C,   4,    4
      note N_C,   4,    8
      note N_B,   4,    4
      
      note N_D,   4,    16
      note REST,  4,    16
      note N_D,   4,    16
      note N_E,   4,    16
      note N_D,   4,    16
      note REST,  4,    16
      note N_D,   4,    16
      note N_E,   4,    16
      note N_D,   4,    8
      note N_C,   4,    8
      note N_B,   4,    8
      note N_A,   4,    8
      
      loop  2                 # Play twice
      
      note N_B,   4,    4
      note N_G,   3,    4
      note N_A,   4,    4
      note N_FS,  3,    4
      
      note N_G,   3,    8
      note N_FS,  3,    8
      note N_E,   3,    8
      note N_FS,  3,    8
      note N_D,   3,    2
      
      
      
      note N_E,   3,    4
      note N_G,   3,    4
      note N_E,   3,    8
      note N_B,   4,    8
      note N_A,   4,    8
      note N_G,   3,    8
      
      note N_FS,  3,    8
      note N_G,   3,    8
      note N_A,   4,    8
      note N_G,   3,    8
      note N_FS,  3,    2
      
      note N_B,   4,    4
      note N_G,   3,    4
      note N_A,   4,    4
      note N_FS,  3,    4
      
      note N_G,   3,    8
      note N_FS,  3,    8
      note N_E,   3,    8
      note N_FS,  3,    8
      note N_D,   3,    2
      
      
      
      note N_E,   3,    4
      note N_G,   3,    4
      note N_E,   3,    8
      note N_E,   4,    8
      note N_D,   4,    8
      note N_C,   4,    8
      
      note N_B,   4,    8
      note N_C,   4,    8
      note N_D,   4,    8
      note N_E,   4,    8
      note N_FS,  4,    2
      
      note N_G,   4,    4
      note N_G,   4,    8
      note N_B,   5,    4
      note N_B,   5,    8
      note N_G,   4,    4
      
      note N_FS,  4,    4
      note N_FS,  4,    8
      note N_A,   5,    4
      note N_A,   5,    8
      note N_FS,  4,    4
      
      
      
      note N_E,   4,    4
      note N_E,   4,    8
      note N_G,   4,    4
      note N_G,   4,    8
      note N_E,   4,    4
      
      note N_FS,  4,    4
      note N_A,   5,    8
      note N_D,   4,    8
      note N_E,   4,    8
      note N_F,   4,    8
      note N_FS,  4,    4
      
      note N_G,   4,    4
      note N_G,   4,    8
      note N_B,   5,    4
      note N_B,   5,    8
      note N_G,   4,    4
      
      note N_FS,  4,    4
      note N_FS,  4,    8
      note N_A,   5,    4
      note N_A,   5,    8
      note N_FS,  4,    4
      
      
      
      note N_E,   4,    4
      note N_E,   4,    8
      note N_G,   4,    4
      note N_G,   4,    8
      note N_E,   4,    4
      
      note N_FS,  4,    4
      note N_A,   5,    8
      note N_B,   5,    8
      note N_A,   5,    8
      note N_G,   4,    8
      note N_FS,  4,    4
      
      end_loop                # End of Bicycle
      

_tears:

#     Bloody Tears
#     Castlevania II: Simon's Quest
#
#     Sheet Music courtesy of:
#     http://www.ninsheetm.us/sheets/Castlevania/CastlevaniaIISimonsQuest/BloodyTears.pdf

.set     TEMPO,       0x9896  # 120 BPM
      
      loop 2                  
      
      note N_Bb,  5,    16
      note N_F,   4,    16
      note N_F,   5,    16
      note N_F,   4,    16
      
      note N_Eb,  5,    16
      note N_F,   4,    16
      note N_Db,  5,    16
      note N_F,   4,    16
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Db,  5,    16
      note N_F,   4,    16
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Bb,  5,    16
      note N_F,   4,    16
      
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Db,  5,    16
      note N_F,   4,    16
      
      note N_Eb,  5,    16
      note N_F,   4,    16
      note N_Db,  5,    16
      note N_F,   4,    16
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Ab,  5,    16
      note N_F,   4,    16
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Bb,  5,    16
      note N_F,   4,    16
      
      
      
      note N_Bb,  5,    16
      note N_F,   4,    16
      note N_F,   5,    16
      note N_F,   4,    16
      
      note N_Eb,  5,    16
      note N_F,   4,    16
      note N_Db,  5,    16
      note N_F,   4,    16
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Db,  5,    16
      note N_F,   4,    16
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Bb,  5,    16
      note N_F,   4,    16
      
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Db,  5,    16
      note N_F,   4,    16
      
      note N_Eb,  5,    16
      note N_F,   4,    16
      note N_Db,  5,    16
      note N_F,   4,    16
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Ab,  5,    16
      note N_F,   4,    16
      
      note N_C,   5,    16
      note N_F,   4,    16
      note N_Bb,  5,    16
      note N_F,   4,    16
      


      note N_Eb,  4,    8
      note N_Ab,  5,    16
      note N_F,   4,    8
      note N_C,   3,    16
      note N_Bb,  3,    16
      note N_C,   3,    16
      
      note N_Db,  3,    8
      note N_Eb,  3,    8
      note N_Eb,  4,    8
      note N_Db,  4,    8
      
      
      
      note N_Eb,  4,    8
      note N_Eb,  4,    16
      note N_Ab,  5,    16
      note N_Ab,  5,    8
      note N_F,   4,    8
      note N_F,   4,    4
      
      note N_Eb,  4,    8
      note N_Db,  4,    8
      
      
      note N_Eb,  4,    8
      note N_Ab,  5,    16
      note N_F,   4,    8
      note N_Eb,  3,    16
      note N_Db,  3,    16
      note N_Eb,  3,    16
      
      note N_F,   3,    8
      note N_Gb,  3,    8
      note N_Eb,  4,    8
      note N_F,   4,    8
      
      
      note N_Gb,  4,    8
      note N_Gb,  4,    16
      note N_Ab,  5,    16
      note N_Ab,  5,    4
      
      note N_F,   4,    8
      note N_F,   4,    16
      note N_Gb,  4,    16
      note N_Gb,  4,    4
      
      note N_Eb,  4,    8
      note N_Ab,  5,    16
      note N_F,   4,    8
      note N_C,   3,    16
      note N_Bb,  3,    16
      note N_C,   3,    16
      
      note N_Db,  3,    8
      note N_Eb,  3,    8
      note N_Eb,  4,    8
      note N_Db,  4,    8
      
      
      
      note N_Eb,  4,    8
      note N_Eb,  4,    16
      note N_Ab,  5,    16
      note N_Ab,  5,    8
      note N_F,   4,    8
      note N_F,   4,    4
      
      note N_Eb,  4,    8
      note N_Db,  4,    8
      
      
      note N_Eb,  4,    8
      note N_Ab,  5,    16
      note N_F,   4,    8
      note N_Eb,  3,    16
      note N_Db,  3,    16
      note N_Eb,  3,    16
      
      note N_F,   3,    8
      note N_Gb,  3,    8
      note N_Eb,  4,    8
      note N_F,   4,    8
      
      
      note N_Gb,  4,    8
      note N_Gb,  4,    16
      note N_Ab,  5,    16
      note N_Ab,  5,    4
      
      note N_F,   4,    8
      note N_G,   4,    8
      note N_A,   5,    8
      note N_C,   5,    8
      
      
      note N_C,   4,    8
      note N_C,   4,    16
      note N_Bb,  4,    16
      note N_Bb,  4,    8
      note N_Bb,  5,    8
      
      note N_C,   4,    8
      note N_C,   4,    16
      note N_Bb,  4,    16
      note N_Bb,  4,    8
      note N_Bb,  5,    8
      
      
      
      note N_C,   4,    8
      note N_C,   4,    16
      note N_Bb,  4,    16
      note N_Bb,  4,    8
      note N_Bb,  5,    8
      
      note N_Db,  4,    16
      note N_Db,  5,    16
      note N_C,   4,    16
      note N_C,   5,    16
      
      note N_Bb,  4,    16
      note N_Bb,  5,    16
      note N_Ab,  4,    16
      note N_Ab,  5,    16
      
      
      note N_C,   4,    8
      note N_Bb,  4,    16
      note N_Bb,  5,    16
      note N_Bb,  5,    4
      
      note N_C,   4,    8
      note N_Bb,  4,    16
      note N_Bb,  5,    16
      note N_Bb,  5,    4
      
      
      note N_C,   4,    8
      note N_Bb,  4,    16
      note N_Bb,  5,    16
      note N_Bb,  5,    4
      
      note N_Db,  5,    8
      note N_Eb,  5,    8
      note N_C,   5,    16
      note N_Db,  5,    16
      note N_Db,  5,    8
      
      end_loop                # End of Bloody Tears




      end_loop                # End of Together We Ride, Bicycle, Bloody Tears
      
      
_fur_elise:
      
      .HWORD 0x3b4, 0x989	
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x4f1, 0x989
      .HWORD 0x428, 0x989
      .HWORD 0x4aa, 0x989
      .HWORD 0x58c, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x954, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x58c, 0x989
      .HWORD 0x4f1, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x5e0, 0x989
      .HWORD 0x4f1, 0x989
      .HWORD 0x4aa, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x4f1, 0x989
      .HWORD 0x428, 0x989
      .HWORD 0x4aa, 0x989
      .HWORD 0x58c, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x954, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x58c, 0x989
      .HWORD 0x4f1, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x4aa, 0x989
      .HWORD 0x4f1, 0x989
      .HWORD 0x58c, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x4f1, 0x989
      .HWORD 0x4aa, 0x989
      .HWORD 0x428, 0x989
      .HWORD 0x3b4, 0x1c9c
      .HWORD 0x63a, 0x989
      .HWORD 0x37e, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x428, 0x1c9c
      .HWORD 0x6fd, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x428, 0x989
      .HWORD 0x4aa, 0x1c9c
      .HWORD 0x768, 0x989
      .HWORD 0x428, 0x989
      .HWORD 0x4aa, 0x989
      .HWORD 0x4f1, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x000, 0x989
      .HWORD 0x000, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x1da, 0x989
      .HWORD 0x000, 0x989
      .HWORD 0x000, 0x989
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x000, 0x989
      .HWORD 0x000, 0x989
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x4f1, 0x989
      .HWORD 0x428, 0x989
      .HWORD 0x4aa, 0x989
      .HWORD 0x58c, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x954, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x58c, 0x989
      .HWORD 0x4f1, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x5e0, 0x989
      .HWORD 0x4f1, 0x989
      .HWORD 0x4aa, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x3ec, 0x989
      .HWORD 0x3b4, 0x989
      .HWORD 0x4f1, 0x989
      .HWORD 0x428, 0x989
      .HWORD 0x4aa, 0x989
      .HWORD 0x58c, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x954, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x58c, 0x989
      .HWORD 0x4f1, 0x1312
      .HWORD 0x000, 0x989
      .HWORD 0x768, 0x989
      .HWORD 0x4aa, 0x989
      .HWORD 0x4f1, 0x989
      .HWORD 0x58c, 0x2625
      .HWORD 0x000, 0x000	# end of music