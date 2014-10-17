#include <stdio.h>
#include <plib.h>
#include "parser_hh.h"

#define SYSTEM_CLOCK        40000000
#define SYS_PER_RATIO       2
#define PERIPHERAL_CLOCK    SYSTEM_CLOCK/SYS_PER_RATIO
#define SMURF_BAUD          115200

/* 
 * E -> A
 * A -> P | A + P | A - P
 * P -> N * P | N / P | N
 * M -> (E)
 *
 *
 */

void uart_setup(void)
{
    UARTConfigure(UART3, UART_ENABLE_PINS_TX_RX_ONLY);
    UARTSetLineControl(UART3, UART_DATA_SIZE_8_BITS | UART_PARITY_NONE | 
                       UART_STOP_BITS_1);
    UARTSetDataRate(UART3, PERIPHERAL_CLOCK, SMURF_BAUD);
    UARTEnable(UART3, UART_ENABLE_FLAGS(UART_PERIPHERAL | UART_RX | UART_TX));
}

char get_char_serial(void){
    while (!UARTReceivedDataIsAvailable(UART3)) {}
    return UARTGetDataByte(UART3);
}

void get_str_serial(char* buf, size_t buf_size){
    size_t index = 0;
    buf[index] = get_char_serial();
    while ((index < buf_size - 1) && (buf[index] != '\r')) {
            ++index;
            buf[index] = get_char_serial();
    } 
    buf[index] = '\0';
}

void send_char_serial(char c){
    while (!UARTTransmitterIsReady(UART3)) {}
    UARTSendDataByte(UART3, c);
}

void send_str_serial(char* buf){
    while (buf[0] != '\0') {
        send_char_serial(buf[0]);
        ++buf;
    }
    send_char_serial('\n');
    send_char_serial('\r');
}



int main(void){

    char buf[80];
    uart_setup();
    while (1) {
        get_str_serial(buf, 80);
        send_str_serial(buf);
        
    }
    return 0;
}
