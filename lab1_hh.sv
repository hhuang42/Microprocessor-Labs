/*
 * Author: Henry Huang
 * Date: 9/13/2014
 * Lab 1
 * 
 * This File 
 */

module lab1_hh(input  logic       clk,
               input  logic [3:0] s,
               output logic [7:0] led,
               output logic [6:0] seg);
  seven_seg_led seg0(s, seg);
  eight_seg_led_bar seg1(clk, s, led);
endmodule

module eight_seg_led_bar(input  logic       clk,
                         input  logic [3:0] s,
                         output logic [7:0] led);
  logic [31:0] count ;
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


module seven_seg_led(input  logic [3:0] hex_value,
                     output logic [6:0] seg);
  always_comb begin
    case (hex_value)
      4'h0 : seg = 7'b0000001;
      4'h1 : seg = 7'b1001111;
      4'h2 : seg = 7'b0010010;
      4'h3 : seg = 7'b0000110;
      4'h4 : seg = 7'b1001100;
      4'h5 : seg = 7'b0100100;
      4'h6 : seg = 7'b0100000;
      4'h7 : seg = 7'b0001111;
      4'h8 : seg = 7'b0000000;
      4'h9 : seg = 7'b0000100;
      4'hA : seg = 7'b0001000;
      4'hB : seg = 7'b1100000;
      4'hC : seg = 7'b0110001;
      4'hD : seg = 7'b1000010;
      4'hE : seg = 7'b0110000;
      4'hF : seg = 7'b0111000;
    endcase
  end
endmodule

