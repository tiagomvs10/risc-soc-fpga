`include "defines.vh"
`timescale 1ns / 1ps
`ifdef IO

module UartController
(
    input [`CN:0] ctrl,
    inout [`DN:0] data,
    input sel,
    output rdy,
    input rx_pin,
    output tx_pin,
    output irq_out
);

    wire clk, rst;
    wire [3:0] oe, we;
    wire [`CRAN:0] ad;
    
    ctrl_dec d(
        .ctrl(ctrl), .sel(sel),.clk(clk), .rst(rst), 
        .oe(oe), .we(we), .ad(ad));
  
    assign rdy = sel; 
    wire internal_tick, tx_complete, rx_complete;
    wire [7:0] rx_byte_wire;
    reg [15:0] reg_baudrate;    //0x8302
    reg [7:0]  reg_tx_buffer;   //0x8304
    reg ctrl_en_module;         //0x8300 bit 0
    reg ctrl_en_rx;             //0x8300 bit 1
    reg ctrl_start_tx;          //0x8300 bit 2
    reg last_tx_done; 

    BaudRateGen baud_gen_inst (.rst(rst),.clk(clk),.en(ctrl_en_module),
        .divisor(reg_baudrate),.baud_tick(internal_tick));

    UartTransmitter tx_inst (.baud_tick(internal_tick),.start_tx(ctrl_start_tx),
        .data_byte(reg_tx_buffer),.rst(rst),.tx_serial(tx_pin),.tx_ready(tx_complete));

    UartReceiver rx_inst (.baud_tick(internal_tick),.rst(rst),.rx_enable(ctrl_en_rx),
        .rx_serial(rx_pin),.byte_out(rx_byte_wire),.rx_flag(rx_complete));


    //write (CPU -> UART)
    always @(posedge clk) begin
        if (rst) begin
            ctrl_en_module <= 0;
            ctrl_start_tx  <= 0;
            ctrl_en_rx     <= 0;
            reg_tx_buffer  <= 0;
            reg_baudrate   <= 0;
            last_tx_done   <= 0;
        end
        else begin
            //clear tx start bit when transmission finishes
            if ((tx_complete == 1'b1) && (last_tx_done == 1'b0)) begin
                ctrl_start_tx <= 0;
                last_tx_done  <= tx_complete;
            end    
            else begin
                last_tx_done <= tx_complete;
            end

            //bus write operation
            if (sel && (we[0] || we[1])) begin
                case (ad[2:1]) 
                    2'b00: begin //control register 0x8300
                        {ctrl_start_tx, ctrl_en_rx, ctrl_en_module} <= data[2:0];
                    end
                    
                    2'b01: begin //baudrate divisor 0x8302
                        reg_baudrate <= data;
                    end
                    
                    2'b10: begin //tx data 0x8304
                        reg_tx_buffer <= data[7:0];
                    end
                endcase
            end
        end
    end

    //read logic (UART -> CPU)
    reg [15:0] read_val;

    always @(*) begin
        case (ad[2:1])
            2'b00: begin //status register 0x8300
                read_val = {11'b0, rx_complete, tx_complete, ctrl_start_tx, ctrl_en_rx, ctrl_en_module};
            end
            
            2'b01: begin //read baudate divisor 0x8302
                read_val = reg_baudrate;
            end
            
            2'b10: begin //rx data read 0x8304
                read_val = {8'b0, rx_byte_wire};
            end
            
            default: read_val = 16'h0000;
        endcase
    end

    assign data = (sel && (oe[0] || oe[1])) ? read_val : 16'bz;
    
    //interrupt on valid rx data
    assign irq_out = rx_complete;
    
endmodule

`endif