/*      calculator_hh.h
        Written 10/23/2014 by Henry_Huang@hmc.edu
        Evaluates the value of arithmetic input through UART3  */


// Size of input and output buffer
#define BUFFER_SIZE         256

/*
 * parse_input
 *
 * Waits for an input from UART3, parses it once, and then prints out the 
 * evaluated value of the input expression, or an error message if the 
 * input expression could not be evaluated, back to the UART3 ports.
 *
 */
void parse_input(void);