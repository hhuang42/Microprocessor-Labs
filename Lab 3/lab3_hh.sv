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
 * 
 * Output:
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
 
module key_trigger (input  logic tracking,
                    input  logic read_signal,
                    output logic activate);
  always_comb begin
    activate = read_signal & ~tracking;
  end
endmodule  
 
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

