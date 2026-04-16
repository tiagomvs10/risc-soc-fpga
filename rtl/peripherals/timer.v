`timescale 1ns / 1ps
`ifdef IO

module timer(
    input[`CN:0] ctrl,
    inout[`DN:0] data,
    input  sel, i,
    input  [15:0] cnt_init,
    output rdy, irq       
);
 
    wire clk, rst;
    wire [3:0] oe, we;
    wire [`CRAN:0] ad;
  
    //bus decoding
    ctrl_dec d(.ctrl(ctrl), .sel(sel),
        .clk(clk), .rst(rst), .oe(oe),
        .we(we), .ad(ad));
    assign rdy = sel;
 
    //CR#0: control register 0x8000
    reg timer, int_en;
    always @(posedge clk)
        if (rst) {timer,int_en} <= {2'b11};
        else if (we[0] & ~ad[1]) {timer,int_en} <= data[1:0];
 
    //tick Logic
    reg i_last;
    always @(posedge clk) i_last <= i;
    wire tick = (timer&i | ~timer&i&~i_last);
 
    //counter Logic
    reg [15:0] cnt;
    wire [15:0] cnt_nxt;
    wire v; 
    assign {v,cnt_nxt} = cnt + 1;
    always @(posedge clk) begin
        if (rst) cnt <= cnt_init;
        else if (tick) begin
            if (v) cnt <= cnt_init;
            else cnt <= cnt_nxt;
        end
    end
 
    //CR#1: interrupt request register 0x8002
    reg irq_reg;
    
    always @(posedge clk)
        if (rst)
            irq_reg <= 0;
        else if (we[0] && ad[1]) //write to CR#1 clears interrupt request
            irq_reg <= 0;
        else if (tick && v && int_en) //overflow sets interrupt request
            irq_reg <= 1;

    assign irq = irq_reg;

    //read Logic
    assign data[1:0] = oe[0] ? (ad[1]==0 ? {timer,int_en} : irq_reg) : 2'bz;

endmodule
`endif