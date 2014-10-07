/*      leds.S
        Written <date> by <your_name>@hmc.edu
        Test PIC by turning on LEDs        */

#   #include <P32xxxx.h>

#       Define constants

#     Stack values
#define S00       0xC0FFEE00
#define S01       0xBEEF0001
#define S02       0x1EAD0002
#define S03       0x13370003
#define S04       0xFABDAD04
#define S05       0xF00D0005
#define S06       0x0DDCA706
#define S07       0x5EED0007
#define S08       0xDD050008
#define S09       0xFA110009
#define S10       0xDAC0000A
#define S11       0x5EA1500B
        .global main

#       Compiler instructions
# store the code in the main program section of RAM
        .set noreorder    # do not let the compiler reorganize your code

# Main program

      .ent main    # Start function block
main:
      la    $t0,  TRISD             # Load the address of TRISD into $t0
      addi  $t1,  $0,   0xFF00
      sw    $t1,  0($t0)            # TRISD = 0xF00 (bottom 8 bits outputs)
      addi  $t1,  $0,   LEDS        # $t1 = LEDS (LEDS + 0)
      

# Initializes stack with 12 elements as defined in macros.
stack_init:
      addi  $sp,  $sp,  -48
      li   $t1,  S00
      sw    $t1,  0($sp)
      li   $t1,  S01
      sw    $t1,  4($sp)
      li   $t1,  S02
      sw    $t1,  8($sp)
      li   $t1,  S03
      sw    $t1,  12($sp)
      li   $t1,  S04
      sw    $t1,  16($sp)   
      li   $t1,  S05
      sw    $t1,  20($sp)
      li   $t1,  S06
      sw    $t1,  24($sp)
      li   $t1,  S07
      sw    $t1,  28($sp)
      li   $t1,  S08
      sw    $t1,  32($sp)
      li   $t1,  S09
      sw    $t1,  36($sp)   
      li   $t1,  S10
      sw    $t1,  40($sp)
      li   $t1,  S11
      sw    $t1,  44($sp)  
      j     max_init                # calculate max of top 5 first
      nop
      
                 
/*
 * Max of Five
 *
 * This function takes the top 5 values of the stack
 * and outputs the largest value to the LEDs.
 * 
 * t2 - the address of the number under consideration
 * t4 - the value under consideration
 * t1 - the running max of the values seen so far
 * t0 - the address of PORTD
 *
 */
max_init:

      addi  $t2,  $sp,  16          # t2 is bottom of 5 numbers
      lw    $t1,  0($t2)            # t1 is value at bottom of stack
        
max_loop: 
      
      addi  $t2,  $t2,  -4          # move t2 up one word in stack
      lw    $t4,  0($t2)            # load new word into t4
      bge   $t1,  $t4,  max_check   # if t1 is bigger, move to next word
      nop                           # otherwise
      move  $t1,  $t4               # set t1 to new max

max_check:

      bne   $t2,  $sp,  max_loop    # repeat when we're not at top of stack
      nop                           # otherwise, finish
      j     write                   # write to LED
      nop

write:          
      la    $t0,  PORTD             # Load the address of PORTD into $t0
      sw    $t1,  0($t0)            # PORTD = $t0
      j     sort_init               # Now do sorting of top 12 elements
      nop

/*
 * Sort 12
 *
 * This function takes the top 12 values of the stack
 * and performs selection sort in place.
 * 
 * t2 - the address where the next smallest value should go
 * 
 * t3 - the address of smallest value so far
 * t4 - the smallest value so far
 * t5 - the address that we're scanning for the smallest value
 * t6 - the value that we're scanning for the smallest value
 *
 *
 */

sort_init:
      
      addi  $t2,  $sp,  44          # t2 is bottom of 12 numbers
      
sort_loop:
min_init:
      
      move  $t5,  $sp               # t5 is address we're looking at
      move  $t3,  $t5               # t3 is address to smallest value so far
      lw    $t4,  0($t3)            # t4 is smallest value so far
      
min_loop:

      addi  $t5,  $t5,  4           # move t5 down one word in stack
      lw    $t6,  0($t5)            # t6 is the new value of t5
      ble   $t4,  $t6,  min_check   # if t4 is smaller, move to next word
      nop                           # otherwise,
      move  $t3,  $t5               # set t3 to be new min address
      lw    $t4,  0($t3)            # set t4 to be new min value
      
min_check:
      
      bne   $t5,  $t2,  min_loop    # repeat when we're not at last of numbers
      nop                           # otherwise,
                                    # since t5 = t2 so t6 is value at t2,
sort_check:

      sw    $t4,  0($t2)            # put min value at bottom
      sw    $t6,  0($t3)            # swap old bottom value to old min address
      addi  $t2,  $t2,  -4          # move t2 up one word in stack
      bne   $t2,  $sp,  sort_loop   # repeat if we're not about to do last one
      nop                           # otherwise, finish
      j     finish_loop             # stop program
      nop
  

finish_loop:
      j     finish_loop             # Jump in place when done
      nop
      .end  main                    # End function block
    