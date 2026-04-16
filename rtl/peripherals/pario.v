`timescale 1ns / 1ps

`ifdef IO

//8-bit parallel i/o peripheral 0x8100
module pario(
    input  [`CN:0] ctrl,
    inout  [`DN:0] data,
    input  sel,
    output rdy,
    input  [7:0] i,
    output [7:0] o
);
    reg [7:0] o;
 
    wire clk;
    wire [3:0] oe, we;

    //bus decoding
    ctrl_dec d(
        .ctrl(ctrl), .sel(sel),
        .clk(clk), .oe(oe), .we(we)
    );
    
    assign rdy = sel;
 
    //write logic
    always @(posedge clk)
        if (we[0])
            o <= data[7:0];

    //read logic
    assign data[7:0] = oe[0] ? i[7:0] : 8'bz;

endmodule

`endif




