/*      leds_hh.S
        Written 12/4/2014 by Henry_Huang@hmc.edu
        Test PIC by turning on LEDs        */

#   #include <P32xxxx.h>

#       Define constants

#     Stack values
#define     T1SET       0xD030      # 1101_0000_0011_0000
#define     T2SET       0xC020      # 1100_0000_0010_0000
        .global main

#       Compiler instructions
# store the code in the main program section of RAM
        .set noreorder    # do not let the compiler reorganize your code

# Main program

      .ent main    # Start function block
main:
      la    $t0,  T1CON
      li    $t1,  T1SET
      sw    $t1,  0($t0)

      la    $t0,  T2CON
      li    $t1,  T2SET
      sw    $t1,  0($t0)

      la    $t0,  TRISG             # Load the address of TRISD into $t0
      addi  $t1,  $0,   0xFF00
      sw    $t1,  0($t0)            # TRISD = 0xF00 (bottom 8 bits outputs)
      

write:          
      la    $t0,  PORTD             # Load the address of PORTD into $t0
      sw    $t1,  0($t0)            # PORTD = $t0
      j     sort_init               # Now do sorting of top 12 elements
      nop
