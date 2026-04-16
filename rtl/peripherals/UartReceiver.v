`timescale 1ns / 1ps
module UartReceiver(input baud_tick, input rst, input rx_enable, input rx_serial,
    output reg [7:0] byte_out,
    output reg rx_flag);
    
    parameter STATE_WAIT = 2'b00, STATE_READ = 2'b01, STATE_END  = 2'b10;
    reg [3:0] sample_cnt;
    reg [7:0] rx_buffer;
    reg [1:0] rx_state;
    
    always@(posedge baud_tick or posedge rst) begin
        if(rst) begin
            rx_state <= STATE_WAIT;
            rx_flag  <= 0;
            byte_out <= 0;
        end
        else if(rx_enable == 1'b1) begin
            case(rx_state)
               STATE_WAIT: begin
                    rx_flag <= 0;
                    //detect start bit (falling edge)
                    if(rx_serial == 1'b0) begin    
                        sample_cnt <= 0;
                        rx_buffer  <= 0;
                        rx_state   <= STATE_READ;
                    end end
               STATE_READ: begin //shift in data            
                    rx_buffer  <= {rx_serial, rx_buffer[7:1]};
                    sample_cnt =  sample_cnt + 1;
                    if(sample_cnt[3]) //8 bits received
                        rx_state <= STATE_END;
               end
               STATE_END: begin //output valid data
                    byte_out <= rx_buffer;
                    rx_flag  <= 1;
                    rx_state <= STATE_WAIT;
               end
               default:
                    rx_state <= STATE_WAIT;
            endcase end 
        end
endmodule


