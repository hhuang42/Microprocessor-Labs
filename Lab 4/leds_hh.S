/*      leds.S
        Written <date> by <your_name>@hmc.edu
        Test PIC by turning on LEDs        */

#   #include <P32xxxx.h>

#       Define constants

#define LEDS      0xA5
#define S00       0xC0FFEEC0
#define S01       0xBEEFBA11
#define S02       0x0A11BA22
#define S03       0x13375A33
#define S04       0x00000004
#define S05       0x00000005
#define S06       0x00000006
#define S07       0x00000007
#define S08       0x00000008
#define S09       0xFFFFFFF9
#define S10       0xFFFFFFFA
#define S11       0xDAD15FAB
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
      ble   $t6,  $t4,  min_check   # if t4 is smaller, move to next word
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
      j     write                   # write down results from top 5 max
                   
                   
                   
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
      j     sort_init               # sort the stack next
        
    
    

write:          # This is a label you can jump to
      la    $t0,  PORTD             # Load the address of PORTD into $t0
      sw    $t1,  0($t0)            # PORTD = $t0
      j     write                   # Jump back to write
      nop
      .end  main                    # End function block
    