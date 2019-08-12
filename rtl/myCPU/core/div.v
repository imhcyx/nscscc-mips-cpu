`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/10/04 16:34:38
// Design Name: 
// Module Name: div
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module div(
    input div_clk,
    input resetn,
    input div,
    input div_signed,
    input [31:0] x,
    input [31:0] y,
    output [31:0] s,
    output [31:0] r,
    output complete,
    input cancel
);

  reg [5:0] cnt;
  wire [5:0] cnt_next;
  reg [63:0] x_, y1, y2, y3, y4, y5, y6, y7, y8, y9, y10, y11, y12, y13, y14, y15;
  reg [31:0] quot; // quotient
  reg sign_s, sign_r;
  wire [63:0] y1_wire = {4'd0, (y[31]&&div_signed) ? ~y+1'b1 : y, 28'd0};
  wire [64:0] sub1_res = x_ - y1;
  wire [64:0] sub2_res = x_ - y2;
  wire [64:0] sub3_res = x_ - y3;
  wire [64:0] sub4_res = x_ - y4;
  wire [64:0] sub5_res = x_ - y5;
  wire [64:0] sub6_res = x_ - y6;
  wire [64:0] sub7_res = x_ - y7;
  wire [64:0] sub8_res = x_ - y8;
  wire [64:0] sub9_res = x_ - y9;
  wire [64:0] sub10_res = x_ - y10;
  wire [64:0] sub11_res = x_ - y11;
  wire [64:0] sub12_res = x_ - y12;
  wire [64:0] sub13_res = x_ - y13;
  wire [64:0] sub14_res = x_ - y14;
  wire [64:0] sub15_res = x_ - y15;
  wire working = cnt != 6'd0;

  assign cnt_next = cnt == 6'd9 || cancel ? 6'd0
                  : div ? 6'd1
                  : working ? cnt + 6'd1
                  : 6'd0;
  always @(posedge div_clk) begin
    if (!resetn) cnt <= 6'd0;
    else cnt <= cnt_next;
  end

  always @(posedge div_clk) begin
    if (!resetn) begin
      x_ <= 64'd0;
      y1 <= 64'd0;
      y2 <= 64'd0;
      y3 <= 64'd0;
      y4 <= 64'd0;
      y5 <= 64'd0;
      y6 <= 64'd0;
      y7 <= 64'd0;
      y8 <= 64'd0;
      y9 <= 64'd0;
      y10 <= 64'd0;
      y11 <= 64'd0;
      y12 <= 64'd0;
      y13 <= 64'd0;
      y14 <= 64'd0;
      y15 <= 64'd0;
      quot <= 32'd0;
      sign_s <= 1'b0;
      sign_r <= 1'b0;
    end
    else if (cnt_next == 6'd1) begin
      x_ <= {32'd0, (x[31]&&div_signed) ? ~x+1'b1 : x};
      y1 <= y1_wire;
      y2 <= y1_wire * 2;
      y3 <= y1_wire * 3;
      y4 <= y1_wire * 4;
      y5 <= y1_wire * 5;
      y6 <= y1_wire * 6;
      y7 <= y1_wire * 7;
      y8 <= y1_wire * 8;
      y9 <= y1_wire * 9;
      y10 <= y1_wire * 10;
      y11 <= y1_wire * 11;
      y12 <= y1_wire * 12;
      y13 <= y1_wire * 13;
      y14 <= y1_wire * 14;
      y15 <= y1_wire * 15;
      quot <= 32'd0;
      sign_s <= (x[31]^y[31]) && div_signed;
      sign_r <= x[31] && div_signed;
    end
    else if (cnt != 6'd9) begin
      x_ <= !sub8_res[64] ? (
              !sub12_res[64] ? (
                !sub14_res[64] ? (
                  !sub15_res[64] ? sub15_res[63:0] : sub14_res[63:0]
                ) : (
                  !sub13_res[64] ? sub13_res[63:0] : sub12_res[63:0]
                )
              ) : (
                !sub10_res[64] ? (
                  !sub11_res[64] ? sub11_res[63:0] : sub10_res[63:0]
                ) : (
                  !sub9_res[64] ? sub9_res[63:0] : sub8_res[63:0]
                )
              )
            ) : (
              !sub4_res[64] ? (
                !sub6_res[64] ? (
                  !sub7_res[64] ? sub7_res[63:0] : sub6_res[63:0]
                ) : (
                  !sub5_res[64] ? sub5_res[63:0] : sub4_res[63:0]
                )
              ) : (
                !sub2_res[64] ? (
                  !sub3_res[64] ? sub3_res[63:0] : sub2_res[63:0]
                ) : (
                  !sub1_res[64] ? sub1_res[63:0] : x_
                )
              )
            );
      y1 <= y1 >> 4;
      y2 <= y2 >> 4;
      y3 <= y3 >> 4;
      y4 <= y4 >> 4;
      y5 <= y5 >> 4;
      y6 <= y6 >> 4;
      y7 <= y7 >> 4;
      y8 <= y8 >> 4;
      y9 <= y9 >> 4;
      y10 <= y10 >> 4;
      y11 <= y11 >> 4;
      y12 <= y12 >> 4;
      y13 <= y13 >> 4;
      y14 <= y14 >> 4;
      y15 <= y15 >> 4;
      quot <= (quot << 4) | (
            !sub8_res[64] ? (
              !sub12_res[64] ? (
                !sub14_res[64] ? (
                  !sub15_res[64] ? 32'd15 : 32'd14
                ) : (
                  !sub13_res[64] ? 32'd13 : 32'd12
                )
              ) : (
                !sub10_res[64] ? (
                  !sub11_res[64] ? 32'd11 : 32'd10
                ) : (
                  !sub9_res[64] ? 32'd9 : 32'd8
                )
              )
            ) : (
              !sub4_res[64] ? (
                !sub6_res[64] ? (
                  !sub7_res[64] ? 32'd7 : 32'd6
                ) : (
                  !sub5_res[64] ? 32'd5 : 32'd4
                )
              ) : (
                !sub2_res[64] ? (
                  !sub3_res[64] ? 32'd3 : 32'd2
                ) : (
                  !sub1_res[64] ? 32'd1 : 32'd0
                )
              )
            )
      );
    end
  end

  assign s = sign_s ? ~quot+1'b1 : quot;
  assign r = sign_r ? ~x_[31:0]+1'b1 : x_[31:0];
  assign complete = cnt == 6'd9;

endmodule
