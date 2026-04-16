`include "defines.vh"

module gr0041(
    input  clk, rst,
    input [`AN:0] i_ad_rst,
    input int_req,
    input [15:0] vector_in,
    output insn_ce, 
    output [`AN:0] i_ad, 
    input  [`IN:0] insn, 
    input  hit, 
    output zero_insn,
    output [`AN:0] d_ad, 
    input  rdy, 
    output sw, sb, 
    output [`N:0] do, 
    output lw, lb, 
    inout  [`N:0] data
);

    wire int_en;
    reg int;
    
    gr0040 core(
        .clk(clk), .rst(rst),
        .i_ad_rst(i_ad_rst),
        .insn(insn),
        .int_trigger(int),
        .vector_in(vector_in),    
        .hit(hit | int),     
        .rdy(rdy),
        .data(data),       
        .insn_ce(insn_ce), 
        .i_ad(i_ad),
        .int_en(int_en),
        .d_ad(d_ad), 
        .sw(sw), .sb(sb), 
        .do(do),
        .lw(lw), .lb(lb)
    );
    
    reg isr_active; // 1->(busy in handler)
    wire is_reti = (insn[15:12] == 4'b1010); //opcode 0xA
    
    //non-nested interrupts
    always @(posedge clk) begin
        if (rst) 
            isr_active <= 0;
        else if (int) 
            isr_active <= 1; //block new interrupts
        else if (is_reti && insn_ce) 
            isr_active <= 0; //allow new interrupts after RETI
    end

    
    reg int_req_last, int_pend;
    
    //interrupt edge detection
    always @(posedge clk) begin
        if (rst) int_req_last <= 0;
        else int_req_last <= int_req;
    end

    always @(posedge clk) begin
        if (rst) int_pend <= 0;
        else if (int) int_pend <= 0; 
        else if (int_req && ~int_req_last) int_pend <= 1;
    end
    
    //interrupt trigger
    wire int_nxt = int_pend & int_en & ~int & ~isr_active & ~is_reti;
    
    always @(posedge clk) begin
        if (rst) int <= 0;
        else if (insn_ce) int <= int_nxt;
    end

    assign zero_insn = int_nxt;
    
endmodule