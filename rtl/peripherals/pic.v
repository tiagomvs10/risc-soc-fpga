`include "defines.vh"
`timescale 1ns / 1ps

`ifdef IO

module pic(
    input[`CN:0] ctrl,
    inout[`DN:0] data,
    input sel,
    output rdy,
    output int_req,
    input[7:0] irq_in,    //bit 0: timer, bit 1: pario, bit 2: uart
    output reg[15:0] vector_out
);
    wire clk, rst;
    wire[3:0] oe, we;
    wire[`CRAN:0] ad;

    ctrl_dec d(.ctrl(ctrl), .sel(sel),
               .clk(clk), .rst(rst), .oe(oe),
               .we(we), .ad(ad));
               
    assign rdy = sel;

    reg [7:0] irq_pend; //request pending
    reg [7:0] ie_reg;   //interrupt enable 
    reg [7:0] prio_reg; //priority 
    reg [7:0] irq_prev; //edge detection
    
    always @(posedge clk) begin
        if (rst) irq_prev <= 0;
        else irq_prev <= irq_in;
    end
    
    //posedge detection
    wire [7:0] irq_edge = irq_in & ~irq_prev;

    always @(posedge clk) begin
        if (rst) begin
            irq_pend <= 0;
            ie_reg   <= 0;
            prio_reg <= 0;
        end else begin
            //capture new interrupts, clear handled ones
            if (we[0] && ad[2:0] == 3'b000) begin
                //write 1 to clear specific bit
                irq_pend <= (irq_pend | irq_edge) & ~data[7:0]; 
            end else begin
                //latch new interrupts
                irq_pend <= irq_pend | irq_edge;
            end

            //write to enable/priority registers
            if (we[0]) begin
                if (ad[2:0] == 3'b010) ie_reg   <= data[7:0]; // 0x8202
                if (ad[2:0] == 3'b110) prio_reg <= data[7:0]; // 0x8206
            end
        end
    end


    wire [7:0] irq_active = irq_pend & ie_reg; //mask pending interrupts with enable register
    assign int_req = |irq_active;              //request to CPU

    //2 bit priority levels (0-3)
    wire [1:0] p_timer = prio_reg[1:0];
    wire [1:0] p_gpio  = prio_reg[3:2];
    wire [1:0] p_uart  = prio_reg[5:4];
    
    reg [1:0] current_max_prio;

    always @(*) begin
        vector_out = 16'h0000;
        current_max_prio = 0;
        //if priority register is not configured by user, timer > pario > uart by default
        //candidate timer 0x0C
        //sets the "baseline" if active
        if (irq_active[0]) begin
            vector_out = 16'h000C;
            current_max_prio = p_timer;
        end
        //candidate pario 0x10
        //overrides vector_out if no vector set yet, or if priority > timer set by user
        if (irq_active[1]) begin
            if ((vector_out == 16'h0000) || (p_gpio > current_max_prio)) begin
                vector_out = 16'h0010;
                current_max_prio = p_gpio;
            end
        end
        //candidate uart 0x14
        //overrides vector_out if no vector set yet, or if priority > current winner set by user
        if (irq_active[2]) begin
             if ((vector_out == 16'h0000) || (p_uart > current_max_prio)) begin
                vector_out = 16'h0014;
                current_max_prio = p_uart;
            end
        end
    end

    assign data[7:0] = oe[0] ? (
        (ad[2:0] == 3'b000) ? irq_pend        :   //status 0x8200 
        (ad[2:0] == 3'b010) ? ie_reg          :   //enable 0x8202
        (ad[2:0] == 3'b100) ? vector_out[7:0] :   //vector low 0x8204
        (ad[2:0] == 3'b110) ? prio_reg        :   //priority 0x8206
        8'b0
    ) : 8'bz;

    assign data[15:8] = oe[1] ? (
        (ad[1:0] == 2'b10) ? vector_out[15:8] : //vector high
        8'b0
    ) : 8'bz;
endmodule
`endif