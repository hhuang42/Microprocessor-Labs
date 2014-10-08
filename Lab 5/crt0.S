# #include <p32xxxx.h>

#ifdef __LIBBUILD__
  .file 1 "crt0.S"
  .loc 1 0
#endif
##################################################################
# Entry point of the entire application
##################################################################
       .section .reset,"ax",@progbits
       .set noreorder
       .ent _reset
_reset:
	# Initialize stack and global pointers
	#la		$sp, _stack
	lui 	$sp, 0xa001
	addiu	$sp, $sp, 0
	la		$gp, _gp

       la      $t0,_main_entry	# Jump to startup mem, then main program
       jr      $t0
       nop

       .end _reset
       .globl _reset

##################################################################
# Startup code
# Empty section, kept to keep compiler happy
##################################################################
       .section .startup,"ax",@progbits
       .set noreorder
       .ent _startup
_startup:
       nop
       .end _startup


##################################################################
# General Exception Vector Handler
# Jumps to _general_exception_handler
##################################################################
       .section .gen_handler,"ax",@progbits
       .set noreorder
       .ent _gen_exception
_gen_exception:
       la      $k0,_general_exception_context
       jr      $k0
       nop

       .end _gen_exception


       .text
       .ent _main_entry
_main_entry:
##################################################################
# Call main. We do this via a thunk in the text section so that
# a normal jump and link can be used, enabling the startup code
# to work properly whether main is written in MIPS16 or MIPS32
# code. I.e., the linker will correctly adjust the JAL to JALX if
# necessary
##################################################################
       jal main
       nop

##################################################################
# Call exit
##################################################################
       jal    exit
       nop

##################################################################
# Just in case, go into infinite loop
##################################################################
1:
       b       1b
       nop
       .end _main_entry
