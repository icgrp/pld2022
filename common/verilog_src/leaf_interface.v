`timescale 1ns / 1ps

// NUM_LEAF_BITS + NUM_PORT_BITS + NUM_ADDR_BITS == ADDR_TOTAL
// NUM_BRAM_ADDR_BITS =< NUM_ADDR_BITS
// NUM_BRAM_ADDR_BITS = NUM_BRAM_ADDR_BITS + NUM_ADDR_REMAINDER_BITS
// port values == 0,1 reserved for initialization packets
// in thise case, port values == 2,3,4,5,6,7,8 are BRAM_IN
// port values == 9,10,11,12,13,14,15 are BRAM_OUT


module leaf_interface #(
    
    parameter PACKET_BITS = 49,
    parameter PAYLOAD_BITS = 32, 
    parameter NUM_LEAF_BITS = 3,
    parameter NUM_PORT_BITS = 4,
    parameter NUM_ADDR_BITS = 7,
    parameter NUM_IN_PORTS = 1, 
    parameter NUM_OUT_PORTS = 1,
    parameter NUM_BRAM_ADDR_BITS = 7,
    parameter FREESPACE_UPDATE_SIZE = 64,
    localparam OUT_PORTS_REG_BITS = NUM_LEAF_BITS+NUM_PORT_BITS+NUM_ADDR_BITS+NUM_BRAM_ADDR_BITS+3,
    localparam IN_PORTS_REG_BITS = NUM_LEAF_BITS+NUM_PORT_BITS,
    localparam REG_CONTROL_BITS = OUT_PORTS_REG_BITS*NUM_OUT_PORTS+IN_PORTS_REG_BITS*NUM_IN_PORTS
    )(
    input clk,
    input reset,
    
    //data from BFT
    input [PACKET_BITS-1:0] din_leaf_bft2interface,
    
    //data to BFT
    output [PACKET_BITS-1:0] dout_leaf_interface2bft,
    input resend,

    //data to USER
    output [PAYLOAD_BITS*NUM_IN_PORTS-1:0] dout_leaf_interface2user,
    output [NUM_IN_PORTS-1:0] vld_interface2user,
    input [NUM_IN_PORTS-1:0] ack_user2interface,
    
    //data from USER
    output [NUM_OUT_PORTS-1:0] ack_interface2user,
    input [NUM_OUT_PORTS-1:0] vld_user2interface,
    input [PAYLOAD_BITS*NUM_OUT_PORTS-1:0] din_leaf_user2interface,
    
    // interface to configure the instruction mem for riscv
    output [23:0] riscv_addr,
    output [7:0] riscv_dout,
    output instr_wr_en_out,
    
    // ap_start control the kernel logic
    output ap_start
    
    );
   
    
    wire [PACKET_BITS-1:0] stream_ExCtrl2sfc;
    wire [PACKET_BITS-1:0] stream_sfc2ExCtrl;
    wire [PACKET_BITS-1:0] configure_ExCtrl2ConCtrl;
    wire [REG_CONTROL_BITS-1:0] control_reg;
    wire resend_ExCtrl2sfc; 
    wire instr_wr_en_in;
    wire [31:0] instr_packet;
    
    
    Extract_Control # (
        .PACKET_BITS(PACKET_BITS),
        .PAYLOAD_BITS(PAYLOAD_BITS),
        .NUM_LEAF_BITS(NUM_LEAF_BITS),
        .NUM_PORT_BITS(NUM_PORT_BITS)
    )ExCtrl(
        .clk(clk),
        .reset(reset),
        .din_leaf_bft2interface(din_leaf_bft2interface),
        .dout_leaf_interface2bft(dout_leaf_interface2bft),
        .resend(resend),
        .resend_out(resend_ExCtrl2sfc),
        .stream_in(stream_sfc2ExCtrl),
        .stream_out(stream_ExCtrl2sfc),
        .configure_out(configure_ExCtrl2ConCtrl),
        .instr_wr_en(instr_wr_en_in),
        .instr_packet(instr_packet),
        .ap_start(ap_start)
    );


instr_config riscv_config(
    .clk(clk),
    .instr_wr_en_in(instr_wr_en_in),
    .instr_packet(instr_packet),
    .addr(riscv_addr),
    .dout(riscv_dout),
    .instr_wr_en_out(instr_wr_en_out),
    .reset(reset)
  );

    Config_Controls # (
        .PACKET_BITS(PACKET_BITS),
        .NUM_LEAF_BITS(NUM_LEAF_BITS),
        .NUM_PORT_BITS(NUM_PORT_BITS),
        .NUM_ADDR_BITS(NUM_ADDR_BITS),
        .PAYLOAD_BITS(PAYLOAD_BITS),
        .NUM_IN_PORTS(NUM_IN_PORTS),
        .NUM_OUT_PORTS(NUM_OUT_PORTS),
        .NUM_BRAM_ADDR_BITS(NUM_BRAM_ADDR_BITS)
    )ConCtrl(
        .control_reg(control_reg),
        .clk(clk),
        .reset(reset),
        .configure_in(configure_ExCtrl2ConCtrl)
    );
    

    
    
    Stream_Flow_Control#(
        .PACKET_BITS(PACKET_BITS),
        .NUM_LEAF_BITS(NUM_LEAF_BITS),
        .NUM_PORT_BITS(NUM_PORT_BITS),
        .NUM_ADDR_BITS(NUM_ADDR_BITS),
        .PAYLOAD_BITS(PAYLOAD_BITS),
        .NUM_IN_PORTS(NUM_IN_PORTS),
        .NUM_OUT_PORTS(NUM_OUT_PORTS),
        .NUM_BRAM_ADDR_BITS(NUM_BRAM_ADDR_BITS),
        .FREESPACE_UPDATE_SIZE(FREESPACE_UPDATE_SIZE)
    )sfc(
        .resend(resend_ExCtrl2sfc),
        .clk(clk),
        .reset(reset),
        .stream_in(stream_ExCtrl2sfc),
        .stream_out(stream_sfc2ExCtrl),
        .control_reg(control_reg),
        .dout_leaf_interface2user(dout_leaf_interface2user),
        .vld_interface2user(vld_interface2user),
        .ack_user2interface(ack_user2interface),
        .ack_interface2user(ack_interface2user),
        .vld_user2interface(vld_user2interface),
        .din_leaf_user2interface(din_leaf_user2interface)
    );
    
endmodule

module rise_detect #(
        parameter integer data_width = 8
    )
    (
        output reg [data_width-1:0]data_out,
        input [data_width-1:0] data_in,
        input clk,
        input reset
    );
    
        reg [data_width-1:0] data_in_1;
        reg [data_width-1:0] data_in_2;
        
        always@(posedge clk) begin 
            if(reset) begin
                {data_in_2, data_in_1} <= 0;
            end else begin
                {data_in_2, data_in_1} <= {data_in_1, data_in};
            end
        end
        
        wire [data_width-1:0] data_out_comb;
        assign data_out_comb = (~data_in_2) & (data_in_1);
        
        always@(posedge clk) begin 
            if(reset) begin
                data_out <= 0;
            end else begin
                data_out <= data_out_comb;
            end
        end
    
    
        
        
    endmodule
/*
module toggle_detect #(
        parameter integer data_width = 8
    )
    (
        output reg [data_width-1:0]data_out,
        input [data_width-1:0] data_in,
        input clk,
        input reset
    );
    
        reg [data_width-1:0] data_in_1;
        reg [data_width-1:0] data_in_2;
        
        always@(posedge clk) begin 
            if(reset) begin
                {data_in_2, data_in_1} <= 0;
            end else begin
                {data_in_2, data_in_1} <= {data_in_1, data_in};
            end
        end
        
        wire [data_width-1:0] data_out_comb;
        assign data_out_comb = data_in_2 ^ data_in_1;
        
        always@(posedge clk) begin 
            if(reset) begin
                data_out <= 0;
            end else begin
                data_out <= data_out_comb;
            end
        end
    
    
        
        
    endmodule


module data_cnt#(
        parameter data_width = 8
        )(
        output reg [data_width-1:0] d_out,
        input clk,
        input reset,
        input en
        );
        
        always@(posedge clk) begin
            if(reset)
                d_out <= 1'b0;
            else
            begin
                if(en)
                    d_out <= d_out + 1;
                else
                    d_out <= d_out;
            end
        end
    endmodule*/
