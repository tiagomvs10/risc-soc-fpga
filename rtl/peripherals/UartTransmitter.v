`timescale 1ns / 1ps

module UartTransmitter(input baud_tick,input start_tx, rst,
    input [7:0] data_byte,
    output reg tx_serial, output reg tx_ready);
    
    parameter STATE_IDLE=2'b00, STATE_START=2'b01, STATE_SHIFT=2'b10, STATE_STOP=2'b11;
    reg [1:0] current_state;
    reg [7:0] shift_reg;
    reg [2:0] bit_pos;

    always@(posedge baud_tick or posedge rst) begin
        if(rst) begin
            current_state = STATE_IDLE;
            tx_serial <= 1'b1;
            tx_ready  <= 0; end
        else begin
            case(current_state)
                STATE_IDLE: begin   //wait for start command
                    if((start_tx == 1'b1)) begin
                       tx_ready <= 0;
                       current_state = STATE_START; end end
                STATE_START: begin
                    tx_serial <= 0;          //send start bit (0)
                    shift_reg <= data_byte;  //load buffer
                    bit_pos   <= 7;
                    current_state = STATE_SHIFT; end
                STATE_SHIFT: begin
                    tx_serial <= shift_reg[0]; //send LSB
                    bit_pos   <= bit_pos - 1;
                    shift_reg = {1'b0, shift_reg[7:1]}; //shift right

                    if(bit_pos == 0)
                        current_state = STATE_STOP; end
               STATE_STOP: begin
                   tx_ready  <= 1;
                   tx_serial <= 1;     //send stop bit (1)
                   current_state = STATE_IDLE; end
               default:
                    current_state = STATE_IDLE;
            endcase end end
endmodule
