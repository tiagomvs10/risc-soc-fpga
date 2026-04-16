`include "defines.vh"

module soc(    
    input  clk,rst,
    input[7:0] par_i, 
    output[7:0] par_o,
    input  uart_rx,
    output uart_tx
);
    wire[`AN:0] i_ad, d_ad;
    wire[`N:0] insn, do, data;    
    wire zero_insn, rdy, sw, sb, lw, lb, cpu_req, timer_irq, uart_irq;
    wire [15:0] pic_vector;
    wire gpio_irq=par_i[0]; //mapped to board physical button
    wire[7:0] irq_sources = {5'b0, uart_irq, gpio_irq, timer_irq};    
    
    gr0041 p(
        .clk(clk), .rst(rst),.i_ad_rst(16'h0020), 
        .int_req(cpu_req),.insn_ce(insn_ce), 
        .i_ad(i_ad),.insn(insn), .hit(~rst),
        .zero_insn(zero_insn),.d_ad(d_ad), 
        .rdy(rdy),.sw(sw), .sb(sb),.do(do),
        .lw(lw), .lb(lb), .data(data),.vector_in(pic_vector));

    reg loaded;
    always @(posedge clk)
        if (rst) loaded <= 0;
        else if (insn_ce) loaded <= 0;
        else loaded <= (lw|lb);
`ifdef IO
    wire io_nxt = d_ad[`AN];
`else
    wire io_nxt = 0;
`endif
    reg io; //peripheral I/O valid access 
    always @(posedge clk)
        if (rst)
            io <= 0;
        else if (insn_ce)
            io <= 0;
        else
            io <= io_nxt;

    wire io_rdy;
    assign rdy = ~io_nxt & ~((lw|lb) & ~loaded) | io & io_rdy | rst;

    wire h_we = ~rst & (sw | sb & ~d_ad[0]);    //byte addressable memory acess
    wire l_we = ~rst & (sw | sb &  d_ad[0]);
    wire [7:0] do_h = sw ? do[15:8] : do[7:0];
    wire [`N:0] di;

    blk_memh ramh(
        .rsta(zero_insn), .wea(1'b0),.ena(insn_ce), .clka(clk),
        .addra(i_ad[9:1]), .dina(8'b0),.douta(insn[15:8]),.rstb(rst),
        .web(h_we),.enb(1'b1), .clkb(clk),.addrb(d_ad[9:1]), .dinb(do_h),
        .doutb(di[15:8]));

    blk_meml raml(
        .rsta(zero_insn), .wea(1'b0),.ena(insn_ce), .clka(clk),
        .addra(i_ad[9:1]), .dina(8'b0),.douta(insn[7:0]),
        .rstb(rst), .web(l_we),.enb(1'b1), .clkb(clk),
        .addrb(d_ad[9:1]), .dinb(do[7:0]),.doutb(di[7:0]));

    wire w_oe = ~io & lw;
    wire l_oe = ~io & (lb & d_ad[0] | lw);
    wire h_oe = ~io & (lb & ~d_ad[0]);
    wire io_wr_word = io & sw;
    wire io_wr_byte = io & sb;

    //bus data 8MSB
    assign data[15:8] = (w_oe)        ? di[15:8] : 
                        (lb & ~io)    ? 8'b0     : 
                        (io_wr_word)  ? do[15:8] : 
                        (io_wr_byte)  ? do[7:0]  : 
                        8'bz;                      

    //bus data 8LSB
    assign data[7:0]  = (l_oe)        ? di[7:0]  : 
                        (h_oe)        ? di[15:8] : 
                        (io_wr_word | io_wr_byte) ? do[7:0] :
                        8'bz;                      

    //io controller
`ifdef IO
    reg [`AN:0] io_ad;
    always @(posedge clk) io_ad <= d_ad;
    wire [`CN:0] ctrl;
    wire [`SELN:0] sel;
    
    ctrl_enc enc(
        .clk(clk), .rst(rst), .io(io),.io_ad(io_ad),.lw(lw),
        .lb(lb), .sw(sw),.sb(sb), .ctrl(ctrl), .sel(sel));
        
    wire [`SELN:0] per_rdy;
    assign io_rdy = | (sel & per_rdy);

    timer timer(
        .ctrl(ctrl),.data(data),.sel(sel[0]), .rdy(per_rdy[0]),
        .irq(timer_irq), .i(1'b1),.cnt_init(16'h0001));

    pario par(
        .ctrl(ctrl), .data(data),.sel(sel[1]),
        .rdy(per_rdy[1]),.i(par_i), .o(par_o));

    pic interrupt_controller(
        .ctrl(ctrl), .data(data),.sel(sel[2]), .rdy(per_rdy[2]),
        .int_req(cpu_req),.irq_in(irq_sources),.vector_out(pic_vector));
    
    UartController uart (
        .ctrl(ctrl),.data(data),.sel(sel[3]),     
        .rdy(per_rdy[3]),.rx_pin(uart_rx),
        .tx_pin(uart_tx), .irq_out(uart_irq) 
    );
`else
    assign cpu_req = 0;
    assign io_rdy = 0; 
`endif
endmodule