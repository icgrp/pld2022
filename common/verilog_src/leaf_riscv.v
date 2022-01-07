`timescale 1ns / 1ps
module leaf_riscv(
    input wire clk_bft,
    input wire clk_user,
    input wire [49-1 : 0] din_leaf_bft2interface,
    output wire [49-1 : 0] dout_leaf_interface2bft,
    input wire resend,
    input wire reset_bft,
    input wire ap_start,
    input wire reset
    );
    parameter MEM_SIZE = 4096;
    parameter IS_TRIPLE = 0;
    parameter ADDR_BITS = 13;


    wire [32-1 :0] dout_leaf_interface2user_5;
    wire vld_interface2user_5;
    wire ack_user2interface_5;
    
    wire [32-1 :0] dout_leaf_interface2user_4;
    wire vld_interface2user_4;
    wire ack_user2interface_4;
    
    wire [32-1 :0] dout_leaf_interface2user_3;
    wire vld_interface2user_3;
    wire ack_user2interface_3;
    
    wire [32-1 :0] dout_leaf_interface2user_2;
    wire vld_interface2user_2;
    wire ack_user2interface_2;
    
    wire [32-1 :0] dout_leaf_interface2user_1;
    wire vld_interface2user_1;
    wire ack_user2interface_1;
    
    wire [32-1 :0] din_leaf_user2interface_5;
    wire vld_user2interface_5;
    wire ack_interface2user_5;

    wire [32-1 :0] din_leaf_user2interface_4;
    wire vld_user2interface_4;
    wire ack_interface2user_4;
        
    wire [32-1 :0] din_leaf_user2interface_3;
    wire vld_user2interface_3;
    wire ack_interface2user_3;
    
    wire [32-1 :0] din_leaf_user2interface_2;
    wire vld_user2interface_2;
    wire ack_interface2user_2;
    
    wire [32-1 :0] din_leaf_user2interface_1;
    wire vld_user2interface_1;
    wire ack_interface2user_1;
    
        
    wire [23:0] riscv_addr;
    wire [7:0] riscv_dout;
    wire instr_wr_en_out;
    
    
    leaf_interface #(
        .PACKET_BITS(49 ),
        .PAYLOAD_BITS(32 ), 
.NUM_LEAF_BITS(5),
        .NUM_PORT_BITS(4),
        .NUM_ADDR_BITS(7),
        .NUM_IN_PORTS(5), 
        .NUM_OUT_PORTS(5),
        .NUM_BRAM_ADDR_BITS(7),
        .FREESPACE_UPDATE_SIZE(64)
    )leaf_interface_inst(
        .clk_bft(clk_bft),
        .clk_user(clk_user),
        .reset(reset),
        .reset_bft(reset_bft),
        .din_leaf_bft2interface(din_leaf_bft2interface),
        .dout_leaf_interface2bft(dout_leaf_interface2bft),
        .resend(resend),
        .dout_leaf_interface2user({dout_leaf_interface2user_5,dout_leaf_interface2user_4,dout_leaf_interface2user_3,dout_leaf_interface2user_2,dout_leaf_interface2user_1}),
        .vld_interface2user({vld_interface2user_5,vld_interface2user_4,vld_interface2user_3,vld_interface2user_2,vld_interface2user_1}),
        .ack_user2interface({ack_user2interface_5,ack_user2interface_4,ack_user2interface_3,ack_user2interface_2,ack_user2interface_1}),
        .ack_interface2user({ack_interface2user_5,ack_interface2user_4,ack_interface2user_3,ack_interface2user_2,ack_interface2user_1}),
        .vld_user2interface({vld_user2interface_5,vld_user2interface_4,vld_user2interface_3,vld_user2interface_2,vld_user2interface_1}),
        .din_leaf_user2interface({din_leaf_user2interface_5,din_leaf_user2interface_4,din_leaf_user2interface_3,din_leaf_user2interface_2,din_leaf_user2interface_1}),
        .riscv_addr(riscv_addr),
        .riscv_dout(riscv_dout),
        .instr_wr_en_out(instr_wr_en_out)
    );
    
   picorv32_wrapper#(
       .MEM_SIZE(MEM_SIZE),
       .IS_TRIPLE(IS_TRIPLE),
       .ADDR_BITS(ADDR_BITS)
       )picorv32_wrapper_inst(
       .clk(clk_user),
       
       .instr_config_addr(riscv_addr),
       .instr_config_din(riscv_dout),
       .instr_config_wr_en(instr_wr_en_out),

       .din5(dout_leaf_interface2user_5),
       .val_in5(vld_interface2user_5),
       .ready_upward5(ack_user2interface_5),
       
       .din4(dout_leaf_interface2user_4),
       .val_in4(vld_interface2user_4),
       .ready_upward4(ack_user2interface_4),
       
       .din3(dout_leaf_interface2user_3),
       .val_in3(vld_interface2user_3),
       .ready_upward3(ack_user2interface_3),
       
       .din2(dout_leaf_interface2user_2),
       .val_in2(vld_interface2user_2),
       .ready_upward2(ack_user2interface_2),
       
       .din1(dout_leaf_interface2user_1),
       .val_in1(vld_interface2user_1),
       .ready_upward1(ack_user2interface_1),
 
       .dout5(din_leaf_user2interface_5),
       .val_out5(vld_user2interface_5),
       .ready_downward5(ack_interface2user_5),
              
       .dout4(din_leaf_user2interface_4),
       .val_out4(vld_user2interface_4),
       .ready_downward4(ack_interface2user_4),
       
       .dout3(din_leaf_user2interface_3),
       .val_out3(vld_user2interface_3),
       .ready_downward3(ack_interface2user_3),
       
       .dout2(din_leaf_user2interface_2),
       .val_out2(vld_user2interface_2),
       .ready_downward2(ack_interface2user_2),
       
       .dout1(din_leaf_user2interface_1),
       .val_out1(vld_user2interface_1),
       .ready_downward1(ack_interface2user_1),
       
       .resetn(ap_start&(!reset))
       );
    
endmodule
