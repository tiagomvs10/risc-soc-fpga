`include "defines.vh"

module ControlUnit(
    input  clk, rst,
    input [3:0] op, fn, cond,
    input  hit, rdy,
    input  ccz, ccn, ccc, ccv,
    output valid_insn_ce,
    output rf_we,          
    output br_taken,       
    output is_jal, is_addi,           
    output is_alu_sum, is_alu_log,         
    output is_alu_sr,      
    output is_alu_adc_sbc, 
    output is_sub_sbc_cmp, 
    output is_reti,
    
    output is_rr,          
    output is_ri,           
    output is_imm_prefix,   
    output ctrl_word_off,   
    output ctrl_signed_op,  

    output insn_ce,        
    output int_en,         
    output lw, lb, sw, sb  
);

    wire mem = hit & (`LB|`LW|`SB|`SW);
    assign insn_ce = rst | ~(mem & ~rdy);
    assign valid_insn_ce = hit & insn_ce;

    //register file write enable
    assign rf_we = valid_insn_ce & ~rst & ((`ALU & ~`CMP)|`ADDI|`LB|`LW|`JAL|`RETI);

    //decoding signals
    assign is_rr          = `RR;   
    assign is_ri          = `RI;  
    assign is_imm_prefix  = `IMM;  
    assign ctrl_word_off  = `LW | `SW | `JAL;
    assign ctrl_signed_op = `ADDI | `ALU;

    //ALU controls
    assign is_jal         = `JAL;
    assign is_addi        = `ADDI;
    assign is_alu_sum     = `ALU & `SUM;
    assign is_alu_log     = `ALU & `LOG;
    assign is_alu_sr      = `ALU & `SR;
    assign is_alu_adc_sbc = `ALU & (`ADC | `SBC);
    assign is_sub_sbc_cmp = `ALU & (`SUB | `SBC | `CMP);
    assign is_reti = `RETI;
   
    //memory outputs
    assign lw = hit & `LW;
    assign lb = hit & `LB;
    assign sw = hit & `SW;
    assign sb = hit & `SB;
    assign int_en = hit & ~(`IMM | `ALU & (`ADC | `SBC | `CMP));

    //branch logic
    reg t;
    always @(*) begin
        case (cond & 4'b1110)
            `BR:   t = 1;
            `BEQ:  t = ccz;
            `BC:   t = ccc;
            `BV:   t = ccv;
            `BLT:  t = ccn ^ ccv;
            `BLE:  t = (ccn ^ ccv) | ccz;
            `BLTU: t = ~ccz & ~ccc;
            `BLEU: t = ccz | ~ccc;
            default: t = 0;
        endcase
    end
    assign br_taken = hit & `Bx & (cond[0] ? ~t : t);

endmodule