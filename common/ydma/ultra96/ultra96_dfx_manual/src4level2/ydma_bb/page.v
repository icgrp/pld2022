module page(
    input wire clk,
    input wire [48 : 0] din_leaf_bft2interface,
    output wire [48 : 0] dout_leaf_interface2bft,
    input wire resend,
    input wire reset
    );

    wire [31:0] dout_leaf_interface2user_1;
    wire vld_interface2user_1;
    wire ack_user2interface_1;
    wire [31:0] din_leaf_user2interface_1;
    wire vld_user2interface_1;
    wire ack_interface2user_1;
    leaf_interface #(
        .PACKET_BITS(49),
        .PAYLOAD_BITS(32), 
        .NUM_LEAF_BITS(5),
        .NUM_PORT_BITS(4),
        .NUM_ADDR_BITS(7),
        .NUM_IN_PORTS(1), 
        .NUM_OUT_PORTS(1),
        .NUM_BRAM_ADDR_BITS(7),
        .FREESPACE_UPDATE_SIZE(64)
    )leaf_interface_inst(
        .clk(clk),
        .reset(reset),
        .din_leaf_bft2interface(din_leaf_bft2interface),
        .dout_leaf_interface2bft(dout_leaf_interface2bft),
        .dout_leaf_interface2user({dout_leaf_interface2user_1}),
        .vld_interface2user({vld_interface2user_1}),
        .ack_user2interface({ack_user2interface_1}),
        .ack_interface2user({ack_interface2user_1}),
        .vld_user2interface({vld_user2interface_1}),
        .din_leaf_user2interface({din_leaf_user2interface_1}),
        .resend(resend)
    );
    user_kernel user_kernel_inst(
        .ap_clk(clk),
        .ap_rst(~reset),
        .ap_start(1'b1),
        .ap_done(),
        .ap_idle(),
        .Input_1_V_V(dout_leaf_interface2user_1),
        .Input_1_V_V_ap_vld(vld_interface2user_1),
        .Input_1_V_V_ap_ack(ack_user2interface_1),
        .Output_1_V_V(din_leaf_user2interface_1),
        .Output_1_V_V_ap_vld(vld_user2interface_1),
        .Output_1_V_V_ap_ack(ack_interface2user_1),
        .ap_ready()
        );  

    
endmodule
