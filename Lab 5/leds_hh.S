/*      leds_hh.S
        Written 12/4/2014 by Henry_Huang@hmc.edu
        Test PIC by turning on LEDs        */

#   #include <P32xxxx.h>

#       Define constants

#     Stack values
#define     T1SET       0xD030      # 1101_0000_0011_0000
#define     T2SET       0xC020      # 1100_0000_0010_0000
#define     NOTPORT     0xFFBF      # 1111_1111_1011_1111
#define     PORTSLOT    0x0040      # 0000_0000_0100_0000
#define     OP_MASK     0xF000
#define     OP_STOP     0x0000
#define     OP_REPEAT   0x1000        
        .global main

#       Compiler instructions
# store the code in the main program section of RAM
        .set noreorder    # do not let the compiler reorganize your code

# Main program

      .ent main    # Start function block

# TMR1 is duration
# TMR2 is half-period

main:

# timer config setup
      la    $t0,  T1CON
      li    $t1,  T1SET
      swr   $t1,  0($t0)

      la    $t0,  T2CON
      li    $t1,  T2SET
      swr   $t1,  0($t0)

# output config setup

      la    $t0,  TRISG             
      lwr   $t1,  0($t0)
      andi  $t1,  NOTPORT          
      swr   $t1,  0($t0)            

      la    $t5,  PORTG

# song data pointer setup
      
      la   $t0,  _tears
      lhu  $t3,  2($t0)
      lhu  $t4,  0($t0)

# timer value setup
      
      la    $t1,  TMR1
      swr   $0,   0($t1) 
      la    $t2,  TMR2
      swr   $0,   0($t2)

check_dur:
      beqz   $t3, check_op
      nop
      lw    $t6,  0($t1)
      ble   $t6,  $t3,  check_per
      nop
      swr   $0,   0($t1)
      addi  $t0,  $t0,  4
      lhu   $t3,  2($t0)
      lhu   $t4,  0($t0)

check_per:
      beqz   $t4, check_dur
      nop
      lw    $t6,  0($t2)
      ble   $t6,  $t4,  check_dur
      nop
      swr   $0,   0($t2)
      lw    $t6,  0($t5)
      xori  $t6,  $t6,  PORTSLOT
      swr   $t6,  0($t5)
      j     check_dur
      nop
      
check_op:

      xori  $t7,  $0,   OP_REPEAT
      xor   $t7,  $t4,  $t7
      andi  $t7,  $t7,  OP_MASK
      beq   $t7,  $0,   do_repeat  
      nop 
      xori  $t7,  $0,   OP_STOP
      xor   $t7,  $t4,  $t7
      andi  $t7,  $t7,  OP_MASK
      beq   $t7,  $0,   shut_down 
      nop 
      j     check_dur
      nop
      
do_repeat:
      addi  $t0,  $t0,  4
      lw    $t0,  0($t0)
      lhu   $t3,  2($t0)
      lhu   $t4,  0($t0)
      j     check_dur
      nop
      
      
      
shut_down:

      swr   $0,   0($t2)
      lw    $t6,  0($t5)
      andi  $t6,  $t6,  NOTPORT
      swr   $t6,  0($t5)
      
      la    $t0,  TRISG             # Load the address of TRISD into $t0
      lwr   $t1,  0($t0)
      ori   $t1,  PORTSLOT          
      swr   $t1,  0($t0)            # TRISD = 0xF00 (bottom 8 bits outputs)
         
finish:
      j     finish
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

.macro  repeat_indef addr=req
.HWORD OP_REPEAT, 0x0000
.WORD  \addr
.endm

.macro  stop_play 
.HWORD OP_STOP, 0x0000
.endm
      
	.section .rodata  # Store this information in FLASH instead of RAM
	
.set     TEMPO,       0x82CA

_bday:
      
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
      note N_F,   3,    4
      stop_play
      
.set     TEMPO,       0x82CA
      
_bike:
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
      
_bike_loop:      
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
      
      repeat_indef      _bike_loop
      
.set     TEMPO,       0x9896
# G A B D E
_tears:
      
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
      
      repeat_indef      _tears
      
      
fur_elise:
      
      .HWORD 0x3b4, 0x989	# Data
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