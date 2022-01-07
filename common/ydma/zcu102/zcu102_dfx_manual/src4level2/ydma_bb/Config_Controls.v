`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2018 04:00:58 PM
// Design Name: 
// Module Name: Config_Controls
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define INPUT_PORT_MAX_NUM 8
`define OUTPUT_PORT_MIN_NUM 9

module Config_Controls # (
    parameter PACKET_BITS = 97,
    parameter NUM_LEAF_BITS = 6,
    parameter NUM_PORT_BITS = 4,
    parameter NUM_ADDR_BITS = 7,
    parameter PAYLOAD_BITS = 64, 
    parameter NUM_IN_PORTS = 7, 
    parameter NUM_OUT_PORTS = 7,
    parameter NUM_BRAM_ADDR_BITS = 7,
    localparam OUT_PORTS_REG_BITS = NUM_LEAF_BITS+NUM_PORT_BITS+NUM_ADDR_BITS+NUM_ADDR_BITS+3,
    localparam IN_PORTS_REG_BITS = NUM_LEAF_BITS+NUM_PORT_BITS,
    localparam REG_CONTROL_BITS = OUT_PORTS_REG_BITS*NUM_OUT_PORTS+IN_PORTS_REG_BITS*NUM_IN_PORTS
    )(
    output [REG_CONTROL_BITS-1:0] control_reg,
    input clk,
    input reset,
    input [PACKET_BITS-1:0] configure_in
    );
    
    wire vldBit;
    wire [NUM_LEAF_BITS-1:0] leaf;
    wire [NUM_PORT_BITS-1:0] port;
    wire [PAYLOAD_BITS-1:0]  payload;
    wire [NUM_PORT_BITS-1:0] self_port;
    wire [NUM_LEAF_BITS-1:0] dst_src_leaf;
    wire [NUM_PORT_BITS-1:0] dst_src_port;
    wire [NUM_ADDR_BITS-1:0] bram_addr;
    wire [NUM_ADDR_BITS-1:0] freespace;
    
    assign vldBit           = configure_in[PACKET_BITS-1]; // 1 bit
    assign leaf             = configure_in[PACKET_BITS-2:PACKET_BITS-2-NUM_LEAF_BITS+1];
    assign port             = configure_in[PACKET_BITS-2-NUM_LEAF_BITS:PACKET_BITS-2-NUM_LEAF_BITS-NUM_PORT_BITS+1];
    assign payload          = configure_in[PAYLOAD_BITS-1:0];
    assign self_port        = payload[PAYLOAD_BITS-1:PAYLOAD_BITS-NUM_PORT_BITS];
    assign dst_src_leaf     = payload[PAYLOAD_BITS-NUM_PORT_BITS-1:PAYLOAD_BITS-NUM_PORT_BITS-NUM_LEAF_BITS];
    assign dst_src_port     = payload[PAYLOAD_BITS-NUM_PORT_BITS-NUM_LEAF_BITS-1:PAYLOAD_BITS-NUM_PORT_BITS-NUM_LEAF_BITS-NUM_PORT_BITS];
    assign bram_addr        = payload[PAYLOAD_BITS-NUM_PORT_BITS-NUM_LEAF_BITS-NUM_PORT_BITS-1:PAYLOAD_BITS-NUM_PORT_BITS-NUM_LEAF_BITS-NUM_PORT_BITS-NUM_ADDR_BITS];
    assign freespace        = payload[PAYLOAD_BITS-NUM_PORT_BITS-NUM_LEAF_BITS-NUM_PORT_BITS-NUM_ADDR_BITS-1:PAYLOAD_BITS-NUM_PORT_BITS-NUM_LEAF_BITS-NUM_PORT_BITS-NUM_ADDR_BITS-NUM_BRAM_ADDR_BITS];


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//configure the input port regsiters
    reg [NUM_LEAF_BITS-1:0] src_leaf_reg [NUM_IN_PORTS-1:0];
    reg [NUM_PORT_BITS-1:0] src_port_reg [NUM_IN_PORTS-1:0];
    
    genvar gv_i;
    generate
        for(gv_i = 0; gv_i < NUM_IN_PORTS; gv_i = gv_i + 1) begin : in_port_reg
            always@(posedge clk) begin
                if(reset) begin
                    src_leaf_reg[gv_i] <= 0;
                    src_port_reg[gv_i] <= 9;
                end else if(vldBit && (port == 1) && (self_port == gv_i+2)) begin
                    src_leaf_reg[gv_i] <= dst_src_leaf;
                    src_port_reg[gv_i] <= dst_src_port;
                end
            end    
        end
    endgenerate   
//////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//connect the input port regsiters to output
    genvar gv_j;
    generate
        for(gv_j = 0; gv_j < NUM_IN_PORTS; gv_j = gv_j + 1) begin : input_port_reg_output
            assign control_reg[IN_PORTS_REG_BITS*(gv_j+1)-1: IN_PORTS_REG_BITS*gv_j] = {src_leaf_reg[gv_j],src_port_reg[gv_j]};
        end
    endgenerate
//////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//configure the output port regsiters
    reg [NUM_LEAF_BITS-1:0] dst_leaf_reg [NUM_OUT_PORTS-1:0];
    reg [NUM_PORT_BITS-1:0] dst_port_reg [NUM_OUT_PORTS-1:0];
    reg [NUM_ADDR_BITS-1:0] bram_addr_reg [NUM_OUT_PORTS-1:0];
    reg [NUM_ADDR_BITS-1:0] freespace_reg [NUM_OUT_PORTS-1:0];
    reg [NUM_OUT_PORTS-1:0] update_freespace_en;
    reg [NUM_OUT_PORTS-1:0] update_bram_addr_en;
    reg [NUM_OUT_PORTS-1:0] add_freespace_en;
    
    genvar gv_k;
    generate
        for(gv_k = 0; gv_k < NUM_OUT_PORTS; gv_k = gv_k + 1) begin : out_port_reg
            always@(posedge clk) begin
                if(reset) begin
                    dst_leaf_reg[gv_k] <= 0;
                    dst_port_reg[gv_k] <= 2;
                    bram_addr_reg[gv_k] <= 0;
                    freespace_reg[gv_k] <= 127;
                end else if(vldBit && (port == 0) && (self_port == gv_k+`OUTPUT_PORT_MIN_NUM)) begin
                    dst_leaf_reg[gv_k] <= dst_src_leaf;
                    dst_port_reg[gv_k] <= dst_src_port;
                    bram_addr_reg[gv_k] <= bram_addr;
                    freespace_reg[gv_k] <= freespace;
                end
            end    
            
            always@(posedge clk) begin
                if(reset) begin
                    update_freespace_en[gv_k] <= 0;
                    update_bram_addr_en[gv_k] <= 0;
                end else if(vldBit && (port == 0) && (self_port == gv_k+`OUTPUT_PORT_MIN_NUM)) begin
                    update_freespace_en[gv_k] <= 1'b1;
                    update_bram_addr_en[gv_k] <= 1'b1;                
                end else begin
                    update_freespace_en[gv_k] <= 1'b0;
                    update_bram_addr_en[gv_k] <= 1'b0;
                end                       
            end     

            always@(posedge clk) begin
                if(reset) begin
                    add_freespace_en[gv_k] <= 0;
                end else if(vldBit && (port == gv_k+`OUTPUT_PORT_MIN_NUM)) begin
                    add_freespace_en[gv_k] <= payload[0];                   
                end
                else begin
                    add_freespace_en[gv_k] <= 0;
                end                       
            end          
                       
        end
    endgenerate
//////////////////////////////////////////////////////////////////////////////////////////////////////////   


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//connect the output port regsiters to output    
    genvar gv_l;
    generate
        for(gv_l = 0; gv_l < NUM_OUT_PORTS; gv_l = gv_l + 1) begin : output_port_reg_output
            assign control_reg[OUT_PORTS_REG_BITS*(gv_l+1)-1+IN_PORTS_REG_BITS*NUM_IN_PORTS: OUT_PORTS_REG_BITS*gv_l+IN_PORTS_REG_BITS*NUM_IN_PORTS] = {update_freespace_en[gv_l],
                                                                                                                                                        update_bram_addr_en[gv_l],
                                                                                                                                                        add_freespace_en[gv_l],
                                                                                                                                                        dst_leaf_reg[gv_l],
                                                                                                                                                        dst_port_reg[gv_l],
                                                                                                                                                        bram_addr_reg[gv_l], 
                                                                                                                                                        freespace_reg[gv_l]};
        end
    endgenerate    
    
endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////    
