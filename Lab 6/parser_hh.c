/*      parser_hh.c
        Written 10/23/2014 by Henry_Huang@hmc.edu
        Implementation for parser_hh        */

#include <string.h>
#include <stdio.h>
#include "parser_hh.h"
#include "calculator_hh.h"


// A sign bit of 0 followed by all 1s. Easily done by negating
// a single left-shifted bit.
value_type max_value(void){
    return ~((value_type)1 << (8 * sizeof(value_type) - 1));
}

// The negated max_value, to avoid issues with the non-negatable
// "true" min_value.
value_type min_value(void){
    return -max_value();
}


// Checks what is the max value that b can be multiplied by without
// overflowing, and sees if a exceeds that amount.
int is_mult_overflow(value_type a, value_type b, error_type* error){
    if (a == 0 || b == 0){
        return 0;
    } else {
        value_type bound_one = max_value() / b;
        value_type bound_two = min_value() / b;
        
        if((bound_one <= a && a <= bound_two) ||
           (bound_two <= a && a <= bound_one)){
            return 0;
        } else {
            *error |= OVERFLOW_ERROR;
            return 1;
        }
    }
}

// Checks if divisor is 0
int is_div_by_zero(value_type a, value_type b, error_type* error){
    if (b != 0){
        return 0;
    } else {
        *error |= DIV_BY_ZERO_ERROR;
        return 1;
    }
}

// Similarly to the multiplier overflow check, checks what is the
// greatest value a can be without leading to overflow, and sees
// if it is no greater than that cutoff value.
int is_cat_overflow(value_type a, value_type b, error_type* error){
    if (a <= (max_value() - b) / 10) {
        return 0;
    } else {
        *error |= VALUE_ERROR;
    }
}

// Calculates what the sum and negated sum would be when right shifted
// by 1 bit, and ensure that neither exceed the max value shifted by 
// 1 bit.
int is_add_overflow(value_type a, value_type b, error_type* error){
    value_type pos_half_sum = (a >> 1) + (b >> 1) + (1 & a & b);
    value_type neg_half_sum = (-a >> 1) + (-b >> 1) + (1 & a & b);
    if ((pos_half_sum <= (max_value() >> 1)) &&
        (neg_half_sum <= (max_value() >> 1))) {
        return 0;
    } else {
        *error |= OVERFLOW_ERROR;
        return 1;
    }
    
}

int is_prev_char(char* str, size_t len, char check){
    return len > 0 && str[len - 1] == check;
}

int is_prev_char_in(char* str, size_t len, char* checks){
    (len > 0) && (strchr(checks,str[len - 1])!=NULL);
}





/* 
 * Rules:
 * 
 * S -> E
 * E -> A
 * A -> P | A+P | A-P
 * P -> N | P*N | P/N
 * N -> WVW | W-VW
 * V -> (E) | D
 * D -> Dd | d
 * W -> W_ | _
 * d -> 0|1|2|3|4|5|6|7|8|9
 */
 

void parse_start(char* str, value_type* value, error_type* error){
    size_t length = strlen(str);

    // goes straight to expression
    parse_expression(str, &length, value, error);

    // if there's unparsed characters left, some syntax error happened
    if (length != 0) {
        *error |= SYNTAX_ERROR;
    }
    
}

void parse_expression(char* str, size_t* len, 
                      value_type* value, error_type* error){

    // all expressions are additions at the highest level
    parse_addition(str, len, value, error);
}

void parse_addition(char* str, size_t* len, 
                    value_type* value, error_type* error){
    value_type P;
    value_type A;

    // parse P since addition always ends with P
    parse_product(str, len, &P, error);
    
    // check if '+', '-', or something else follows and use appropriate rule
    if (is_prev_char(str, *len, '+')) {
        --(*len);
        parse_addition(str, len, &A, error);
        if (!is_add_overflow(A, P, error)){
            *value = A+P;
        } 
    } else if (is_prev_char(str, *len, '-')) {
        --(*len);
        parse_addition(str, len, &A, error);
        if (!is_add_overflow(A, -P, error)){
            *value = A-P;
        } 
    } else {
        *value = P;
    }
}

void parse_product(char* str, size_t* len, 
                   value_type* value, error_type* error){
    value_type N;
    value_type P;

    // product always ends in number, so parse number first
    parse_number(str, len, &N, error);
    
    // check if '*', '/', or something else follows
    if (is_prev_char(str, *len, '*')) {
        --(*len);
        parse_product(str, len, &P, error);
        if (!is_mult_overflow(P, N, error)){
            *value = P*N;
        }
    } else if (is_prev_char(str, *len, '/')) {
        --(*len);
        parse_product(str, len, &P, error);
        if (!is_div_by_zero(P, N, error)){
            *value = P/N;
        }
    } else {
        *value = N;
    }
}

void parse_number(char* str, size_t* len, 
                  value_type* value, error_type* error){
    // remove white space before the value
    parse_whitespace(str, len);

    // parse the actual value
    parse_value(str, len, value, error);

    // minus sign means we need to check if negation or subtraction
    if (is_prev_char(str, *len, '-')) {
        size_t lookahead = *len;
        --lookahead;
        parse_whitespace(str, &lookahead);

        // if the minus sign doesn't follow a value, it's a negation
        if (!is_prev_char_in(str, lookahead, "0123456789)")){
            *value *= -1;
            --(*len);
        }
    }

    // parse remaining whitespace
    parse_whitespace(str, len);
}

void parse_value(char* str, size_t* len, 
                 value_type* value, error_type* error){

    // parenthesis mark a nested expression
    if (is_prev_char(str, *len, ')')) {
        --(*len);
        parse_expression(str, len, value, error);

        // has to have matching parens or it's an error
        if (is_prev_char(str, *len, '(')){
            --(*len);
        } else {
            *error |= SYNTAX_ERROR;
        }
    } else {

        // otherwise, it's a digit
        parse_digits(str, len, value, error);
    }
}

void parse_digits(char* str, size_t* len, 
                  value_type* value, error_type* error){
    value_type d;
    value_type D;
    // make sure we have a digit
    if (is_prev_char_in(str, *len, "0123456789")) {
        --(*len);
        d = str[*len] - '0';

        // if there's more digits, we need to concat to get the total value
        if (is_prev_char_in(str, *len, "0123456789")) {
            parse_digits(str, len, &D, error);
            if (!is_cat_overflow(D, d, error)){
                *value = 10*D + d;
            }
        } else {
            *value = d;
        }
    } else {
        // no digits when expected is an error
        *error |= SYNTAX_ERROR;
    }
}
    
    
void parse_whitespace(char* str, size_t* len){

    // shortcut with a loop instead of recursion for simplicity
    while(*len > 0 && (str[*len-1]==' ')){
        --(*len);
    }
}


void write_error(char* buf, error_type* e){

    // psuedo switch with bitwise or'd values
    if (*e & BUFFER_ERROR) {
        sprintf(buf, "ERROR: BUFFER OVERFLOW\n\r"
                "Input cannot exceed %d characters.", BUFFER_SIZE-1);
    } else if (*e & SYNTAX_ERROR) {
        sprintf(buf, "ERROR: UNRECOGNIZED SYNTAX\n\r"
                     "Input contained unrecognized syntax.");
    } else if (*e & VALUE_ERROR) {
        sprintf(buf, "ERROR: VALUE OVERFLOW\n\r"
                     "Input values cannot exceed %lld.", max_value());
    } else if (*e & DIV_BY_ZERO_ERROR) {
        sprintf(buf, "ERROR: DIVISION BY ZERO\n\r"
                     "Division by zero occured.", max_value());
    } else if (*e & OVERFLOW_ERROR) {
        sprintf(buf, "ERROR: ARITHMETIC OVERFLOW\n\r"
                     "Calculations exceed the numerical range:\n\r"
                     "[%lld, %lld].",
                      min_value(), max_value());
    }
}