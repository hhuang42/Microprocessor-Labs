/*      calculator_hh.c
        Written 10/23/2014 by Henry_Huang@hmc.edu
        Implementation for calculator_hh        */

#include <stdio.h>
#include <stdlib.h>
#include "uartio_hh.h"
#include "parser_hh.h"
#include "calculator_hh.h"



void parse_input(void){
    char buf[BUFFER_SIZE];
    value_type value = 0;
    error_type error = 0;

    // read input to buffer
    if(get_str_serial(buf, BUFFER_SIZE)){

        // note any buffer overflow
        error |= BUFFER_ERROR;
    }

    // attempt to parse
    parse_start(buf, &value, &error);

    // write attempted parse value to buffer
    sprintf(buf, "%lld", value);

    // if an error occurred, overwrite with error message
    if (error) {
        write_error(buf, &error);
    }

    // send the message
    send_str_serial(buf);

    // add a new line for legibility
    send_str_serial("");
}


int main(void){

    // setup and then parse indefinitely
    uart_setup();
    while (1) {
        parse_input();
    }
}
