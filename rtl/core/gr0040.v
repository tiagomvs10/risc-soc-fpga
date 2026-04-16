`include "defines.vh"

module gr0040(
    input  clk, rst,
    input [`AN:0] i_ad_rst,
    input  [`IN:0] insn, 
    input  hit,
    input  rdy, 
    inout  [`N:0] data,
    input int_trigger,
    input [15:0] vector_in,
    output insn_ce, 
    output [`AN:0] i_ad,  
    output int_en,
    output [`AN:0] d_ad, 
    output sw, sb, 
    output [`N:0] do, 
    output lw, lb 
);
    //instruction slicing
    wire [3:0] op   = insn[15:12];
    wire [3:0] rd   = insn[11:8];
    wire [3:0] rs   = insn[7:4];
    wire [3:0] imm  = insn[3:0];
    wire [3:0] cond = insn[11:8];
    wire [11:0] i12 = insn[11:0];
    wire [7:0] disp = insn[7:0];
    wire [3:0] fn   = `RI ? insn[7:4] : insn[3:0];
    
    //control signals
    wire rf_we, br_taken;
    wire ccz, ccn, ccc, ccv;
    wire is_jal, is_addi, is_rr, is_ri, is_imm_prefix; 
    wire is_alu_sum, is_alu_log, is_alu_sr;
    wire is_alu_adc_sbc, is_sub_sbc_cmp;
    wire is_reti;
    wire valid_insn_ce;
    wire ctrl_word_off;
    wire ctrl_signed_op;
    
    ControlUnit cu (
        .clk(clk), .rst(rst),
        .op(op), .fn(fn), .cond(cond), 
        .hit(hit), .rdy(rdy),
        .ccz(ccz), .ccn(ccn), .ccc(ccc), .ccv(ccv),
        .valid_insn_ce(valid_insn_ce),
        .ctrl_word_off(ctrl_word_off),
        .ctrl_signed_op(ctrl_signed_op),
        .is_rr(is_rr),
        .is_ri(is_ri), 
        .is_imm_prefix(is_imm_prefix),
        .rf_we(rf_we), .br_taken(br_taken),
        .is_jal(is_jal), .is_addi(is_addi),
        .is_alu_sum(is_alu_sum), .is_alu_log(is_alu_log), .is_alu_sr(is_alu_sr),
        .is_alu_adc_sbc(is_alu_adc_sbc), .is_sub_sbc_cmp(is_sub_sbc_cmp),
        .is_reti(is_reti),
        .insn_ce(insn_ce), .int_en(int_en),
        .lw(lw), .lb(lb), .sw(sw), .sb(sb)
    );

    Datapath dp (
        .clk(clk), .rst(rst),
        .fn(fn), 
        .rd(rd), .rs(rs), 
        .imm(imm), .i12(i12), .disp(disp),
        .hit(hit), .i_ad_rst(i_ad_rst),
        .valid_insn_ce(valid_insn_ce),
        .ctrl_word_off(ctrl_word_off),
        .ctrl_signed_op(ctrl_signed_op),
        .is_rr(is_rr),
        .is_ri(is_ri),
        .is_imm_prefix(is_imm_prefix),
        .rf_we(rf_we), .br_taken(br_taken), 
        .is_jal(is_jal), .is_addi(is_addi),
        .is_alu_sum(is_alu_sum), .is_alu_log(is_alu_log), .is_alu_sr(is_alu_sr),
        .is_alu_adc_sbc(is_alu_adc_sbc), .is_sub_sbc_cmp(is_sub_sbc_cmp),
        .is_reti(is_reti),
        .int_trigger(int_trigger),.vector_in(vector_in),
        .ccz(ccz), .ccn(ccn), .ccc(ccc), .ccv(ccv),
        .i_ad(i_ad), .d_ad(d_ad), .do(do), .data(data)
    );
endmodule