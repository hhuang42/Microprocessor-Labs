/*
 * Author: Henry Huang
 * Date: 9/24/2014
 * Lab 3
 *  
 */

/*
 * lab3_hh
 * 
 * Inputs:
 *   clk - a clock signal to synchronize the logic with
 *   reset - a reset signal to clear the internal state
 *   col_values - the signals read from all keypad columns
 * 
 * Output:
 *   row_values - the signal to set on for all keypad rows
 *   left_off - a signal indicating if the left digit should be powered off
 *   right_off - a signal indicating if the right digit should be powered off
 *   
 *   This module detects the keypresses of a matrix keyboard connected to 
 * the given row and column. It detects distinct keypresses on the keyboard, and
 * outputs them to a time multiplexed dual digit LED component.
 * 
 */
 
module lab3_hh (input  logic       clk,
                input  logic       reset,
                input  logic [3:0] col_values,
                output logic [3:0] row_values,
                output logic       left_off, right_off,
                output logic [6:0] seven_seg_digit);
  logic [3:0] read_hex;
  logic       read_signal;
  logic       activate;
  
  hex_scanner scanner(clk, reset, col_values, row_values, read_signal, read_hex);
  hex_debouncer debouncer(clk, reset, read_signal, read_hex, activate);
  hex_writer writer(clk, reset, read_hex, activate, 
                    left_off, right_off, seven_seg_digit);
  
endmodule

/*
 * hex_scanner
 * 
 * Inputs:
 *   clk - a clock signal to synchronize the logic with
 *   reset - a reset signal to clear the internal state
 *   col_values - the signals read from all keypad columns
 *   
 * Output:
 *   row_values - the signal to set on for all keypad rows
 *   read_signal - the signal corresponding to the read_hex
 *   read_hex - the value read from the keypad
 *   
 *   This module manipulates the column and row pins to read a new hex key
 * every clock cycle, and outputs the read_hex, the signal for that key.
 *  
 */

module hex_scanner (input  logic       clk,
                    input  logic       reset,
                    input  logic [3:0] col_values,
                    output logic [3:0] row_values,
                    output logic       read_signal,
                    output logic [3:0] read_hex);
  logic [3:0] raw_hex;
  logic       raw_signal;
  logic [1:0] input_row;
  logic [1:0] output_col;
  hex_generator generator(clk, reset, raw_hex, input_row, output_col);
  key_reader reader(input_row, output_col, col_values, row_values, raw_signal);
  key_synchronizer synchronizer(clk, reset, raw_signal, raw_hex, read_signal, read_hex);
endmodule

/*
 * hex_debouncer
 * 
 * Inputs:
 *   clk - a clock signal to synchronize the logic with
 *   reset - a reset signal to clear the internal state
 *   read_signal - the signal corresponding to the read_hex
 *   read_hex - the value read from the keypad
 *   
 * Output:
 *   activate - a signal that the keypad value has just been pressed
 *
 *   This module takes in the value of the scanned key and the corresponding
 * signal and decides when the signal is a new button press by setting the 
 * output signal activate to high when the read_signal constitutes a unique
 * button press for the key indicated by read_hex.
 *  
 */

module hex_debouncer (input  logic       clk,
                      input  logic       reset,
                      input  logic       read_signal,
                      input  logic [3:0] read_hex,
                      output logic       activate);
  logic deactivate;
  logic tracking;
  logic tracked_signal;
  key_trigger trigger(tracking, read_signal, activate);
  key_tracker tracker(clk, reset, read_signal, read_hex, deactivate,
                        activate, tracking, tracked_signal);
  key_deactivator #(20) deactivator(clk, reset, tracking, tracked_signal, deactivate);
endmodule

/*
 * hex_writer
 * 
 * Inputs:
 *   clk - a clock signal to synchronize the logic with
 *   reset - a reset signal to clear the internal state
 *   read_hex - the value read from the keypad
 *   activate - a signal that the keypad value has just been pressed
 * 
 * Output:
 *   left_off, right_off - the signals to indictate when the LEDs are off
 *   seven_seg_digit - the decoded signals for the time-multiplexed LED digits
 *
 *   This module reads in hex values when the activate signal indicates
 * that a new button has been pressed. It then displays the last two pressed
 * values by LED control signals, with the most recent on the right LED.
 *  
 */

module hex_writer(input  logic       clk,
                  input  logic       reset,
                  input  logic [3:0] read_hex,
                  input  logic       activate,
                  output logic       left_off, right_off,
                  output logic [6:0] seven_seg_digit);
  logic [3:0] left_hex;
  logic [3:0] right_hex;
  key_record record(clk, reset, read_hex, activate, left_hex, right_hex);
  hex_display display(clk, left_hex, right_hex, left_off, right_off, seven_seg_digit);
endmodule
                      
/*
 * hex_generator
 * 
 * Inputs:
 *   clk - a clock signal to synchronize the logic with
 *   reset - a reset signal to clear the internal state
 * 
 * Output:
 *   hex_values - the value of the key to read next
 *   input_row - the row of the key to read next
 *   output_col - the column of the key to read next
 *
 *   This module scrolls through all 16 hex values, one per clock
 * cycle, and outputs the row and column for the appropriate key.
 *  
 */

module hex_generator (input  logic clk,
                      input  logic reset,
                      output logic [3:0] hex_value,
                      output logic [1:0] input_row,
                      output logic [1:0] output_col);
  logic [3:0] key_index;
  always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
      key_index <= '0;
    end else begin
      key_index <= key_index + 4'h1;
    end
  end
  always_comb begin
    {input_row, output_col} = key_index;
    case (key_index)
      4'h0 : hex_value = 4'h1;
      4'h1 : hex_value = 4'h2;
      4'h2 : hex_value = 4'h3;
      4'h3 : hex_value = 4'hA;
      4'h4 : hex_value = 4'h4;
      4'h5 : hex_value = 4'h5;
      4'h6 : hex_value = 4'h6;
      4'h7 : hex_value = 4'hB;
      4'h8 : hex_value = 4'h7;
      4'h9 : hex_value = 4'h8;
      4'hA : hex_value = 4'h9;
      4'hB : hex_value = 4'hC;
      4'hC : hex_value = 4'hE;
      4'hD : hex_value = 4'h0;
      4'hE : hex_value = 4'hF;
      4'hF : hex_value = 4'hD;
    endcase
  end
endmodule
  
/*
 * key_reader
 * 
 * Inputs:
 *   input_row - the row of the key to read
 *   output_col - the column of the key to read
 *   col_values - the signals read from all keypad columns
 * 
 * Output:
 *   row_values - the signal to set on for all keypad rows
 *   read_signal - the value of the key associated with the previous cycle
 *
 *   This module manipulates the column and row pins connected to the
 * matrix keypad in order to find whether the key at the specified input_row
 * and output_col is maintaining contact. The output of the key is shown in 
 * read_signal.
 *
 *   This module requires that the pins for col_values have pulldown resistors
 * that can bring the signal to a low within 1 clock cycle, since rows are
 * powered to either high or high impedance.
 *  
 */

module key_reader (input  logic [1:0] input_row,
                   input  logic [1:0] output_col,
                   input  logic [3:0] col_values,
                   output logic [3:0] row_values,
                   output logic       read_signal);
  always_comb begin
    case (input_row)
		4'h0 : row_values = 4'bzzz1;
		4'h1 : row_values = 4'bzz1z;
		4'h2 : row_values = 4'bz1zz;
		4'h3 : row_values = 4'b1zzz;
    endcase
    read_signal = col_values[output_col];
  end
endmodule

/*
 * key_synchronizer
 * 
 * Inputs:
 *   clk - a clock signal to synchronize the logic with
 *   reset - a reset signal to clear the internal state
 *   raw_signal - a non-synchronized signal directly from the key pad
 *   raw_hex - the value of the key that the raw_signal is associated with
 * 
 * Output:
 *   read_signal - a delayed synchronized signal from the previous cycle
 *   read_hex - the value of the key associated with the previous cycle
 *
 *   This module synchronizes the read_signal by forcing it to settle for
 * a clock cycle before propagating through the rest of the system. The hex
 * value is also delayed by a clock cycle to stay in sync with the signal.
 *  
 */

module key_synchronizer (input  logic       clk,
                         input  logic       reset,
                         input  logic       raw_signal,
                         input  logic [3:0] raw_hex,
                         output logic       read_signal,
                         output logic [3:0] read_hex);
  always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
      read_signal <= '0;
      read_hex    <= '0;
    end else begin
      read_signal <= raw_signal;
      read_hex    <= raw_hex;
    end
  end
endmodule

/*
 * key_trigger
 * 
 * Inputs:
 *   tracking - a signal that a key press is currently being tracked
 *   read_signal - a signal that the read key has contact
 * 
 * Output:
 *   activate - a signal that tracking of the currently read key should start
 *
 *   This module triggers the activate output signal when an active signal is
 * read from a key when no key is currently being tracked. This module is entirely
 * combinatoric, so the output value refers to the key being read within the same
 * clock cycle, rather than during the previous one.
 *  
 */
 
module key_trigger (input  logic tracking,
                    input  logic read_signal,
                    output logic activate);
  always_comb begin
    activate = read_signal & ~tracking;
  end
endmodule  

/*
 * key_tracker
 * 
 * Inputs:
 *   clk - a clock signal to synchronize the logic with
 *   reset - a reset signal to clear the internal state
 *   read_signal - a signal that the read key has contact
 *   read_hex - a 4-bit value indicating the value of the read key
 *   deactivate - a signal that the current tracking be deactivated
 *   activate - a signal that the currently read key should be tracked
 * 
 * Output:
 *   tracking - a signal that this module is currently tracking a key press
 *   tracked_signal - a signal indicating whether the tracked key has contact
 *
 *   This module maintains the state of whether a key press is tracked or not.
 * When it receives an activate signal in a clock cycle, it stores the hex 
 * value of the currently read key, and outputs a high signal on the tracking
 * output. It continues to maintain this tracking state until it receives a
 * deactivate signal, at which point it again waits for an activate signal.
 *
 *   While the module is in an activated state, it checks if the read_hex
 * matches the tracked_hex value, and if the respective signal from the
 * key is active. If so, it sets the tracked_signal to be active.
 * Otherwise, if the read key differs from the tracked key, or the tracked
 * key's signal is not active, the module outputs a low value for the
 * tracked_signal.
 *
 *   The tracked_signal's value is undefined when the module is not in its
 * tracking state. 
 *  
 */
 
module key_tracker (input  logic       clk,
                    input  logic       reset,
                    input  logic       read_signal,
                    input  logic [3:0] read_hex,
                    input  logic       deactivate,
                    input  logic       activate,
                    output logic       tracking,
                    output logic       tracked_signal);
  logic [3:0] tracked_hex;
  always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
      tracking         <= '0;
      tracked_hex    <= 4'h0;
      tracked_signal <= '0;
    end else begin
      tracking       <= deactivate ? '0 : activate ? '1 : tracking;
      tracked_hex    <= activate ? read_hex : tracked_hex;
      tracked_signal <= (read_hex == tracked_hex) ? read_signal : '0;
    end
  end
endmodule

/*
 * key_deactivator
 *
 * Parameter:
 *   COUNTDOWN_BITS - the number of bits used to track the number of inactive
 *                    clock cycles before a keypress is deactivated.
 * 
 * Inputs:
 *   clk - a clock signal to synchronize the logic with
 *   reset - a reset signal to clear the internal state
 *   tracking - a signal indicating that a key press is currently being tracked
 *   tracked_signal - a signal indicating whether the tracked key has contact
 * 
 * Output:
 *   deactivate - a signal indicating that the key press tracking should be
 *                deactivated
 *
 *   This module is active when a tracking signal indicates that key press
 * tracking is currently activated, and should be deactivated when there have
 * been no signal from the relevant key for (2^COUNTDOWN_BITS - 1) cycles.
 *
 *   This module begins counting the number of consecutive cycles where no 
 * key contact signal arrives. If (2^COUNTDOWN_BITS - 1) cycles of inactivity
 * occur, this module signals that the key tracking should be deactivated.
 *
 *   Otherwise, if a key contact signal arrives before the countdown finishes,
 * the timer resets, and the module will restart counting up to 
 * (2^COUNTDOWN_BITS - 1) cycles.
 *
 *   Once the key tracking's deactivation is confirmed via the tracking signal,
 * the module resets its countdown and ceases activity until key tracking is 
 * reactivated.
 *  
 */

module key_deactivator #(parameter COUNTDOWN_BITS = 20) 
                        (input  logic clk,
                         input  logic reset,
                         input  logic tracking,
                         input  logic tracked_signal,
                         output logic deactivate);
  logic [(COUNTDOWN_BITS-1):0] inactivity_counter;
  always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
      inactivity_counter <= '0;
    end else begin
      inactivity_counter <= 
          (tracking & ~tracked_signal) ? (inactivity_counter + 1) : '0;
    end
  end
  always_comb begin
    deactivate = (inactivity_counter == '1);
  end
endmodule

/*
 * hex_record
 * 
 * Inputs:
 *   clk - a clock signal to synchronize the logic with
 *   reset - a reset signal to clear the internal state of the record to 42
 *   new_hex - a 4-bit value to store as input
 *   activate - an enable signal allowing new_hex to be stored
 * 
 * Output:
 *   left_hex - the second most recent hex value to be stored
 *   right_hex - the most recent hex value to be stored
 * 
 *   This module stores the last two hex values assigned to new_hex
 * when the activate enable signal is turned on. The most recent value
 * is stored as the right hex, and the second most recent value is
 * stored as the left hex. Note that the recorded hex values are updated
 * for every clock cycle where the activate signal is enabled, such that
 * in order to store a single new value, the activate signal must be high
 * for only a single cycle.
 *   
 */

module key_record (input  logic       clk,
                   input  logic       reset,
                   input  logic [3:0] new_hex,
                   input  logic       activate,
                   output logic [3:0] left_hex,
                   output logic [3:0] right_hex);
  always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
      left_hex  <= 4'h4;
      right_hex <= 4'h2;
    end else if (activate) begin
      left_hex  <= right_hex;
      right_hex <= new_hex;
    end else begin
      left_hex  <= left_hex;
      right_hex <= right_hex;
    end
  end
endmodule

/*
 * hex_display
 * 
 * Inputs:
 *   clk - a 40 MHz clock signal
 *   left_value - a 4-bit value to display on the left digit of the LED digit
 *   right_value - a 4-bit value to display on the right digit of the LED digit
 * 
 * Output:
 *   left_off - a signal indicating if the left digit should be powered off
 *   right_off - a signal indicating if the right digit should be powered off
 *   seven_seg_digit - the control signal for the currently powered 7 
 *                     segment LED digit
 * 
 *   This module controls a time-multiplexed set of 2 digits by specifying when
 * each of the two digits is to be turned off (while the other digit remains
 * powered), and sending the appropriate signal for that digit to the 7 segment
 * LED, based on the input values of the left_value and right_value signals.
 *   
 */
  
module hex_display (input  logic       clk,
                    input  logic [3:0] left_value, right_value,
                    output logic       left_off, right_off,
                    output logic [6:0] seven_seg_digit);
  logic oscil;  
  logic [3:0] value;
  exp_2_oscillator exp_oscil(clk, oscil);
  always_comb begin
    value = oscil ? left_value : right_value;
    {left_off, right_off} = {~oscil, oscil};
  end
  seven_seg_led seg0(value, seven_seg_digit);
endmodule

/*
 * exp_2_oscillator
 * 
 * Parameter: 
 *   SLOWDOWN_EXP - the power of two that the output signal is slowed by
 *
 * Inputs:
 *   clk - the base oscillating signal to base the output signal off of
 *
 * Output:
 *   oscil - a signal that oscillates at a slower rate than clk based
 *           on the SLOWDOWN_EXP.
 *
 *   The output signal will invert every 2^SLOWDOWN_EXP clk cycles. However,
 * since the signal needs to be inverted twice for every cycle, the output
 * signal will be 2^(SLOWDOWN_EXP+1) times slower than the original signal.
 *   
 */
module exp_2_oscillator #(parameter SLOWDOWN_EXP = 17)
                         (input  logic clk,
                          output logic oscil);
  logic [SLOWDOWN_EXP:0] count;
  always_ff @ (posedge clk) begin
      count <= count + 1;
  end
  always_comb begin
    oscil = count[SLOWDOWN_EXP];
  end
endmodule

/*
 * seven_seg_led
 *
 * Inputs:
 *   hex_value - the hexadecimal value to represent on the bar
 * 
 * Output:
 *   seg - a 7-bit signal controlling a 7-segment one-digit LED
 * 
 *   This module assumes standard placement of the 7 segments, and
 * assigns A to seg[0], B to seg[1]..., G to seg[6]. It also assumes
 * a common anode configuration where segments are driven on by a
 * value of 0. 
 */
module seven_seg_led(input  logic [3:0] hex_value,
                     output logic [6:0] seg);
  logic a,b,c,d,e,f,g;
  always_comb begin
    case (hex_value)
      4'h0 : {a,b,c,d,e,f,g} = 7'b0000001;
      4'h1 : {a,b,c,d,e,f,g} = 7'b1001111;
      4'h2 : {a,b,c,d,e,f,g} = 7'b0010010;
      4'h3 : {a,b,c,d,e,f,g} = 7'b0000110;
      4'h4 : {a,b,c,d,e,f,g} = 7'b1001100;
      4'h5 : {a,b,c,d,e,f,g} = 7'b0100100;
      4'h6 : {a,b,c,d,e,f,g} = 7'b0100000;
      4'h7 : {a,b,c,d,e,f,g} = 7'b0001111;
      4'h8 : {a,b,c,d,e,f,g} = 7'b0000000;
      4'h9 : {a,b,c,d,e,f,g} = 7'b0000100;
      4'hA : {a,b,c,d,e,f,g} = 7'b0001000;
      4'hB : {a,b,c,d,e,f,g} = 7'b1100000;
      4'hC : {a,b,c,d,e,f,g} = 7'b0110001;
      4'hD : {a,b,c,d,e,f,g} = 7'b1000010;
      4'hE : {a,b,c,d,e,f,g} = 7'b0110000;
      4'hF : {a,b,c,d,e,f,g} = 7'b0111000;
    endcase
    seg = {g,f,e,d,c,b,a};
  end
endmodule

