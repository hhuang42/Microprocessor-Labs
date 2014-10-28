/*      uartio_hh.c
        Written 10/23/2014 by Henry_Huang@hmc.edu
        Implementation for uartio_hh        */

#include <plib.h>
#include "uartio_hh.h"


// BAUD rate configuration constants
#define SYSTEM_CLOCK        40000000
#define SYS_PER_RATIO       2
#define PERIPHERAL_CLOCK    SYSTEM_CLOCK/SYS_PER_RATIO
#define SMURF_BAUD          115200

void uart_setup(void)
{
    // Use uart library for simplicity and minimize human error
    UARTConfigure(UART3, UART_ENABLE_PINS_TX_RX_ONLY);
    UARTSetLineControl(UART3, UART_DATA_SIZE_8_BITS | UART_PARITY_NONE | 
                       UART_STOP_BITS_1);
    UARTSetDataRate(UART3, PERIPHERAL_CLOCK, SMURF_BAUD);
    UARTEnable(UART3, UART_ENABLE_FLAGS(UART_PERIPHERAL | UART_RX | UART_TX));
}

char get_char_serial(void){

    // block until available
    while (!UARTReceivedDataIsAvailable(UART3)) {}
    return UARTGetDataByte(UART3);
}

int get_str_serial(char* buf, size_t buf_size){
    int buffer_overflow = 0;
    size_t index = 0;
    char read_char;

    // consume all chars up to endline regardless
    while ((read_char = get_char_serial()) != '\r') {

            // only read to buffer when it fits
            if (index < buf_size - 1) {
                buf[index] = read_char;
                ++index;
            } else {
                // set overflow if it doesn't fit
                buffer_overflow = 1;
            }
    } 

    // finish array with null char
    buf[index] = '\0';
    return buffer_overflow;
}

void send_char_serial(char c){

    // block until sendable
    while (!UARTTransmitterIsReady(UART3)) {}
    UARTSendDataByte(UART3, c);
}

void send_str_serial(char* buf){
    while (buf[0] != '\0') {
        send_char_serial(buf[0]);
        ++buf;
    }

    // add newline and carriage return for legibility of output
    send_char_serial('\n');
    send_char_serial('\r');
}
