`timescale 1ns / 1ps

`ifdef IO
module ctrl_dec(
  ctrl, sel, clk, rst, oe, we, ad);
 
  input  [`CN:0] ctrl;  //abstract control bus
  input  sel;           //peripheral select
  output clk;           //clock
  output rst;           //reset
  output [3:0] oe;      //byte output enables 
  output [3:0] we;      //byte wire enables
  output [`CRAN:0] ad;  //ctrl reg addr
  
  wire [3:0] oe_, we_;
  
  //unpack control bus
  assign { oe_, we_, ad, rst, clk } = ctrl;
  
  //generate output enables
  assign oe[0] = sel & oe_[0];
  assign oe[1] = sel & oe_[1];
  assign oe[2] = sel & oe_[2];
  assign oe[3] = sel & oe_[3];
  
  //generate write enables
  assign we[0] = sel & we_[0];
  assign we[1] = sel & we_[1];
  assign we[2] = sel & we_[2];
  assign we[3] = sel & we_[3];
 endmodule

`endif


