/*      uartio_hh.h
        Written 10/23/2014 by Henry_Huang@hmc.edu
        Provides setup and interface for IO through UART3 */
#include <stddef.h>

/*
 * uart_setup
 *
 * Performs setup to use UART3 for IO.
 *
 * Sets up the UART3 ports to operate with the following:
 *
 * Speed: 115.2k baud
 * Data bits: 8
 * Stop bits: 1
 * Parity: none
 * Flow control: none
 *
 */
void uart_setup(void);


/*
 * get_char_serial
 *
 * Recieves a single character from UART3.
 *
 * Returns:
 *  The char of the oldest 8 bits yet to be read from UART3.
 *
 * Blocks until a character is received from the UART3.
 * Assumes that the UART3 buffer overflow has not occurred.
 * Characters are returned in a FIFO manner.
 *
 */
char get_char_serial(void);

/*
 * get_str_serial
 *
 * Reads in a string from UART3.
 *
 * Input:
 *  buf_size    The max size of the buffer.
 *  *buf        The buffer to write into.
 *
 *
 * Returns:
 *  A boolean indicating if buffer overflow has occurred.
 *
 * Reads input from UART3 up until a newline character is received.
 * Up to the first (buf_size-1) characters up to, but not including,
 * the newline character, are written to the buffer along with a null 
 * terminator, taking up to buf_size characters total.
 * 
 * Any additional characters up to the newline characters are consumed
 * without being written to the buffer.
 *
 * In the case that the number of characters before the newline character
 * exceeds (buf_size-1), the function returns True. Otherwise, it returns
 * False.
 * 
 */
int get_str_serial(char* buf, size_t buf_size);


/*
 * send_char_serial
 *
 * Sends a single character through UART3.
 *
 * Input:
 *  c 		The character to send.
 *
 * Blocks until the character can be sent through UART3.
 * 
 */
void send_char_serial(char c);

/*
 * send_str_serial
 *
 * Sends a c-style string through UART3.
 *
 * Input:
 *  *buf 	The c-style string to send through UART3.
 *
 * Sends the c-style string stored in the given buffer, and
 * also sends a newline character followed by a carriage return
 * character. As a result, sending an empty line will send
 * a newline and a carriage return character. 
 * 
 */
void send_str_serial(char* buf);