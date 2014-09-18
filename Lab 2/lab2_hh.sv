/*
 * Author: Henry Huang
 * Date: 9/17/2014
 * Lab 2
 *  
 */

/*
 */
module lab2_hh (input  logic       clk,
                input  logic [3:0] left_value, right_value,
                output logic left_off, right_off,
                output logic [6:0] seven_seg_digit,
                output logic [4:0] sum);
  logic oscil;  
  logic [3:0] value;
  exp_2_oscillator exp_19_oscil(clk, oscil);
  always_comb begin
    sum = left_value + right_value;
    value = oscil ? left_value : right_value;
    {left_off, right_off} = {~oscil, oscil};
  end
  seven_seg_led seg0(value, seven_seg_digit);
endmodule

/*
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

