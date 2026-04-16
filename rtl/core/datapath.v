`include "defines.vh"

module Datapath(
    input  clk, rst,
    input [3:0] fn, rd, rs, imm,   
    input [11:0] i12,
    input [7:0] disp,
    input  hit,
    input  [`AN:0] i_ad_rst,
    input  valid_insn_ce,
    input  rf_we, br_taken,
    input  is_jal, is_addi,
    input  is_rr, is_ri,                  
    input  is_imm_prefix,   
    input  ctrl_word_off,   
    input  ctrl_signed_op,  
    input  is_alu_sum, is_alu_log, is_alu_sr,
    input  is_alu_adc_sbc, is_sub_sbc_cmp,
    input int_trigger,
    input [15:0] vector_in,
    input is_reti,
    
    output reg ccz, ccn, ccc, ccv,
    output [`AN:0] i_ad, 
    output [`AN:0] d_ad, 
    output [`N:0] do,    
    inout  [`N:0] data    
);

    wire [`N:0] dreg, sreg;
    wire [3:0] reg_addr_b = is_ri ? rd : rs; 
    
    dist_mem_gen_0 regfile (
        .a(rd),                
        .d(data),             
        .dpra(reg_addr_b), 
        .clk(clk), 
        .we(rf_we), 
        .spo(dreg), 
        .dpo(sreg)
    );
    assign do = dreg;

    //immediate generation
    reg imm_pre;
    reg [11:0] i12_pre;
    
    always @(posedge clk) begin
        if (rst) imm_pre <= 0;
        else if (valid_insn_ce) imm_pre <= is_imm_prefix;
    end
    always @(posedge clk) begin
        if (valid_insn_ce) i12_pre <= i12;
    end

    wire sxi = ctrl_signed_op & imm[3]; 
    wire [10:0] sxi11 = {11{sxi}};
    wire i_4 = sxi | (ctrl_word_off & imm[0]);
    wire i_0 = ~ctrl_word_off & imm[0];
    
    wire [`N:0] imm16 = imm_pre ? {i12_pre, imm} : {sxi11, i_4, imm[3:1], i_0};

    //ALU operations
    wire [`N:0] a = is_rr ? dreg : imm16; 
    wire [`N:0] b = sreg;
    wire [`N:0] sum;
    wire add = ~is_sub_sbc_cmp;
    
    reg c;
    wire ci = add ? c : ~c;
    wire c_W, x;
    
    addsub adder(.add(add), .ci(ci), .a(a), .b(b), .sum(sum), .x(x), .co(c_W));
  
    //condition code flags
    wire z = sum == 0;
    wire n = sum[`N];
    wire co = add ? c_W : ~c_W;
    wire v = c_W ^ sum[`N] ^ a[`N] ^ b[`N];
    
    always @(posedge clk) begin
        if (rst) {ccz, ccn, ccc, ccv} <= 0;
        else if (valid_insn_ce) {ccz, ccn, ccc, ccv} <= {z, n, co, v};
    end

    always @(posedge clk) begin
        if (rst) c <= 0;
        else if (valid_insn_ce) c <= co & is_alu_adc_sbc;
    end

    //ALU result mux
    wire [`N:0] log = fn[0] ? (a^b) : (a&b); 
    wire [`N:0] sr  = {(`SRA ? b[`N] : 0), b[`N:1]}; 
    wire sum_en = is_alu_sum | is_addi;
    reg [`AN:0] pc;
    
    assign data = sum_en     ? sum : 16'bz;
    assign data = is_alu_log ? log : 16'bz;
    assign data = is_alu_sr  ? sr  : 16'bz;
    assign data = is_jal     ? pc  : 16'bz;
    assign data = is_reti    ? 16'h0000 : 16'bz;
    
    wire [6:0] sxd7   = {7{disp[7]}};
    wire [`N:0] sxd16 = {sxd7, disp, 1'b0};
    wire [`N:0] pcinc = br_taken ? sxd16 : {hit, 1'b0};
    wire [`N:0] pcincd = pc + pcinc;
    

    assign i_ad = (int_trigger)    ? vector_in :  //jump to interrupt vector
                  (hit & is_reti)  ? dreg      : 
                  (hit & is_jal)   ? sum       : 
                  pcincd;
    
    
    assign d_ad = sum;

    always @(posedge clk) begin
        if (rst) pc <= i_ad_rst;
        else if (valid_insn_ce) pc <= i_ad;
    end

endmodule

module addsub(input add, ci, input [15:0] a, b, output [15:0] sum, output x, co);
    assign {co,sum,x} = add ? {a,ci}+{b,1'b1} : {a,ci}-{b,1'b1};
endmodule