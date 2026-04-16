`timescale 1ns / 1ps

module BaudRateGen
(
    input rst,
    input clk,
    input en,
    input [15:0] divisor, //divisor value
    output reg baud_tick
);
    //gated clock for enable control
    wire gated_clk;
    assign gated_clk = clk & en;
    
    reg [15:0] cnt_reg;

    always @(posedge gated_clk) begin
        if(rst) begin
            baud_tick <= 0;
            cnt_reg   <= 1;
        end
        else if (cnt_reg == 1) begin
            //toggle output and reload
            baud_tick <= ~baud_tick;
            cnt_reg   <= {1'b0, divisor[15:1]};
        end
        else begin
            cnt_reg <= cnt_reg - 1;
        end
    end
endmodule

