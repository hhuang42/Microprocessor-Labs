/*
 * Author: Henry Huang
 * Date: 9/13/2014
 * Lab 1
 * 
 * These modules control the LED bar on the microprocessor board
 * in addition to a separate 7-segment 1-digit LED. 
 */

/*
 * lab1_hh
 *
 * Inputs:
 *   clk - a 40MHz clock signal
 *   s - a 4-bit signal to control the LEDs
 * 
 * Output:
 *   led - a 8-bit signal controlling a bar of LEDs
 *   seg - a 7-bit signal controlling a 7-segment one-digit LED
 */
module lab1_hh(input  logic       clk,
               input  logic [3:0] s,
               output logic [7:0] led,
               output logic [6:0] seg);
  seven_seg_led seg0(s, seg);
  eight_seg_led_bar seg1(clk, s, led);
endmodule

/*
 * eight_seg_led_bar
 *
 * Inputs:
 *   clk - a 40MHz clock signal
 *   s - a 4-bit signal to control the LEDs
 * 
 * Output:
 *   led - a 8-bit signal controlling a bar of LEDs
 *
 * The LEDs are on in the following situations:
 *   led[0] : s[0] = 1
 *   led[1] : s[0] = 0
 *   led[2] : s[1] = 1
 *   led[3] : s[2] = 0
 *   led[4] : s[3] = 1
 *   led[5] : s[3] = 0
 *   led[6] : s[3] = 1 & s[4] = 1
 *
 * The signal led[7] blinks at a rate of ~2.4 Hz.
 * 
 *   This module requires that internal registers
 * and output signals are initialized to some valid
 * digital value.
 */
module eight_seg_led_bar(input  logic       clk,
                         input  logic [3:0] s,
                         output logic [7:0] led);
  logic [31:0] count;
  always_ff @ (posedge clk) begin
    if (count == 8_333_333) begin
      led[7] <= ~led[7];
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end
  always_comb begin
    {led[4],led[2],led[0]} = s[2:0];
    {led[5],led[3],led[1]} = ~s[2:0];
    {led[6]} = &s[3:2];
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

