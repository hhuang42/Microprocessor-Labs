/*      parser_hh.h
        Written 10/23/2014 by Henry_Huang@hmc.edu
        Parses an input string with arithmetic syntax   */


#include <stdlib.h>

// Bitmask of errors in decreasing severity
#define BUFFER_ERROR        0b1
#define SYNTAX_ERROR        0b10
#define VALUE_ERROR         0b100
#define DIV_BY_ZERO_ERROR   0b1000
#define OVERFLOW_ERROR      0b10000

// Data type used to hold values in calculations
typedef long long           value_type;

// Bitfield to hold errors
typedef int                 error_type;

/*
 * Parsing Function Prototypes
 *
 * Parses the input with the grammar given below.
 *
 * Symbols:
 *
 * S: Start         An entire input
 * E: Expression    A syntactically complete substring
 * A: Addition      A sum or difference of two values, or a single value
 * P: Product       A product or quotient of two values, o a single value
 * N: Number        A single signed number (possibly padded with spaces)
 * V: Value         An unsigned value (no spaces) or a parenthetical value
 * D: Digits        A series of at least 1 digit
 * d: Digit         A single digit literal from 0 to 9
 * W: Whitespace    A series of at least 0 spaces
 * Terminals:       +,-,*,/,(,),_,0,1,2,3,4,5,6,7,8,9
 * 
 * Rules:
 *
 * S -> E
 * E -> A
 * A -> P | A+P | A-P
 * P -> N | P*N | P/N
 * N -> WVW | W-VW
 * V -> (E) | D
 * D -> Dd | d
 * W -> W_ | 
 * d -> 0|1|2|3|4|5|6|7|8|9
 *
 * Input:
 *  *str    The c-style input string to be parsed
 *  *len    The length of the remaining unparsed string before the call
 * 
 * Output:
 *  *len    The length of the remaining unparsed string after the call
 *  *value  The value of the parsed substring
 *  *error  A bitfield of potential errors accumulated so far
 *
 * Parsing functions that support infix notation for addition, subtraction,
 * multiplication, integer division, negation, and nested parenthesis.
 * Usual order of operations is enforced, along with left associativity
 * among consecutive operations of equal order.
 *
 * These set of functions perform similarly to LR parsing. In order to enforce
 * left associativity, however, the string is parsed backwards, starting from
 * then last non-null character in the string and progressively reducing the
 * length of the substring that has yet to be parsed. 
 *
 * Lookahead is required to see if '-' should be interpreted as
 * negation or subtraction.
 */

void parse_start(char* str, value_type* value, error_type* error);

void parse_expression(char* str, size_t* len, value_type* value, 
                      error_type* error);
                      
void parse_addition(char* str, size_t* len, value_type* value, 
                    error_type* error);
                    
void parse_product(char* str, size_t* len, value_type* value, 
                   error_type* error);
                   
void parse_number(char* str, size_t* len, value_type* value, 
                  error_type* error);
                  
void parse_value(char* str, size_t* len, value_type* value, 
                 error_type* error);

void parse_digits(char* str, size_t* len, value_type* value, 
                  error_type* error);
                  
void parse_whitespace(char* str, size_t* len);

/*
 * Max supported value of value_type when value_type.
 * Assumes that value_type is signed in 2's complement.
 *
 */
value_type max_value(void);

/*
 * Min supported value of value_type when value_type.
 * Assumes that value_type is signed.
 * 
 * Is defined to be -max_value(), and is thus generally
 * greater than the actual minimum representable type.
 */
value_type min_value(void);

/*
 * Error checking functions
 *
 * Checks whether the arithmetic operations are safe to perform.
 *
 * Input:
 *  a       The c-style input string to be parsed
 *  b       The length of the remaining unparsed string before the call
 * 
 * Output:
 *  *error  A bitfield of potential errors accumulated so far
 *
 * Returns:
 *  A boolean value indicating a detected error
 * 
 * Checks if the appropriate operation will lead to an error state.
 * If so, it sets the error bitfield and returns True.
 * Otherwise, it leaves the error bitfield as-is, and returns False.
 *
 */

// multiplication overflow
int is_mult_overflow(value_type a, value_type b, error_type* error);

// division by zero
int is_div_by_zero(value_type a, value_type b, error_type* error);

// concatenation overflow
int is_cat_overflow(value_type a, value_type b, error_type* error);

// addition overflow
int is_add_overflow(value_type a, value_type b, error_type* error);

/*
 * Peek functions
 *
 * Check if the next character matches expected character(s).
 *
 * Input:
 *  str*    The c-style input string to be parsed
 *  len     The length of the remaining unparsed string before the call
 *  check   The character/list of characters that should be matched	
 * 
 * Returns:
 *  A boolean value indicating that the last character of the unparsed
 *  string matches the check.
 *
 * is_prev_char checks if the character matches the given check character.
 *
 * is_prev_char_in checks if the character matches any of the characters
 * in the given string, including the null string terminator.
 *
 */
int is_prev_char(char* str, size_t len, char check);

int is_prev_char_in(char* str, size_t len, char* checks);

/* 
 * write_error
 * 
 * Overwrites given buffer with an error message if an error occurred.
 *
 * Input:
 *  *buf    The buffer to overwrite if an error occurred
 *  *e      The error bitfield indicating what errors occurred
 *
 * Writes an error message to the buffer if any errors have been indicated
 * on e. Only the most severe error will be addressed in the message.
 *
 * If no recognized error has occurred, the buffer is left in its existing
 * state with no alterations.
 *
 * The errors that are handled are listed with highest severity first:
 *
 * BUFFER_ERROR        Buffer Overflow occurred on reading input.
 * SYNTAX_ERROR        The grammar was unable to parse the entire string.
 * VALUE_ERROR         A given integer value exceeded the maximum value.
 * DIV_BY_ZERO_ERROR   Division by zero occurred.
 * OVERFLOW_ERROR      Arithmetic overflow occurred.
 * 
 */
void write_error(char* buf, error_type* e);


















