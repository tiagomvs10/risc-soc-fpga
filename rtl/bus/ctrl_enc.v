`timescale 1ns / 1ps

`ifdef IO
 
 module ctrl_enc(
  clk, rst, io, io_ad, lw, lb, sw, sb, ctrl, sel);
  
  input  clk, rst, io;
  input  [`AN:0] io_ad;
  input  lw, lb, sw, sb;
  output [`CN:0] ctrl;
  output [`SELN:0] sel;
 
  // on-chip bus abstract control bus
  wire [3:0] oe, we;
  
  //generate byte enables
  assign oe[0] = io & (lw | lb);
  assign oe[1] = io & lw;
  assign oe[2] = 0;
  assign oe[3] = 0;
  assign we[0] = io & (sw | sb);
  assign we[1] = io & sw;
  assign we[2] = 0;
  assign we[3] = 0;
  
  //pack control bus
  assign ctrl={oe,we,io_ad[`CRAN:0],rst,clk };
 
  //address decoding
  assign sel[0] = io & (io_ad[11:8] == 0);
  assign sel[1] = io & (io_ad[11:8] == 1);
  assign sel[2] = io & (io_ad[11:8] == 2);
  assign sel[3] = io & (io_ad[11:8] == 3);
  assign sel[4] = io & (io_ad[11:8] == 4);
  assign sel[5] = io & (io_ad[11:8] == 5);
  assign sel[6] = io & (io_ad[11:8] == 6);
  assign sel[7] = io & (io_ad[11:8] == 7);
 endmodule
 `endif
 
 