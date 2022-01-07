`timescale 1 ns / 1 ps

module test();


reg  clk_bft;
reg  clk_user;
reg reset_n;
reg ap_start;
reg ap_start_1;

wire [31:0]  din;
wire  val_in;
wire ready_upward;

wire [31:0] m_axis_mm2s_tdata;
wire [15:0]  m_axis_mm2s_tkeep;
wire         m_axis_mm2s_tlast;
reg          m_axis_mm2s_tready;
wire         m_axis_mm2s_tvalid;

reg [48:0] leaf_0_in;
wire [48:0] leaf_0_out2;

floorplan_static_wrapper i1(
    .Input_1_V_V(din),
    .Input_1_V_V_ap_ack(ready_upward),
    .Input_1_V_V_ap_vld(val_in),
    .Output_1_V_V(m_axis_mm2s_tdata),
    .Output_1_V_V_ap_ack(m_axis_mm2s_tready),
    .Output_1_V_V_ap_vld(m_axis_mm2s_tvalid),
    .ap_start(ap_start_1),
    .clk_bft(clk_bft),
    .clk_user(clk_user),
    .leaf_0_in(leaf_0_in),
    .reset_n(reset_n));    

    
    
wire ap_done;
wire ap_idle;
wire ap_ready;

data_gen i2(
    .ap_clk(clk_user),
    .ap_rst(~reset_n),
    .ap_start(ap_start),
    .ap_done(ap_done),
    .ap_idle(ap_idle),
    .ap_ready(ap_ready),
    .Output_1_V_V(din),
    .Output_1_V_V_ap_vld(val_in),
    .Output_1_V_V_ap_ack(ready_upward)
    //.Output_1_V_V_ap_ack(1'b1)
);



always #5 clk_bft = ~clk_bft;
always #5 clk_user = ~clk_user;

initial begin 
    clk_bft = 0;
    clk_user = 0;
    leaf_0_in = 0;
    m_axis_mm2s_tready = 0;
    reset_n = 0;
    ap_start = 0;
    ap_start_1 = 0;
    #1007
    reset_n = 1;
    #100000
    m_axis_mm2s_tready = 1;



  //write_to_fifo(0x800, 0x94100fe0, &ctrl_reg);
//flow_calc_1.Output_1->output_fun.Input_1
  leaf_0_in =49'h1_2000_9b100fe0;#10
  leaf_0_in =49'h1_b080_22480000;#10
//tensor_weight_y2.Output_1->tensor_weight_x2.Input_1
  leaf_0_in =49'h1_6800_99900fe0;#10
  leaf_0_in =49'h1_9880_26c80000;#10
//gradient_xyz_calc.Output_1->gradient_weight_y_1.Input_1
  leaf_0_in =49'h1_4000_94900fe0;#10
  leaf_0_in =49'h1_4880_24480000;#10
//flow_calc_2.Output_1->output_fun.Input_2
  leaf_0_in =49'h1_1800_9b180fe0;#10
  leaf_0_in =49'h1_b080_31c80000;#10
//output_fun.Output_1->DMA.Input_1
  leaf_0_in =49'h1_b000_90900fe0;#10
  leaf_0_in =49'h1_0880_2b480000;#10
//gradient_xyz_calc.Output_3->gradient_weight_y_3.Input_1
  leaf_0_in =49'h1_4000_b6100fe0;#10
  leaf_0_in =49'h1_6080_24580000;#10
//gradient_weight_y_3.Output_1->gradient_weight_x3.Input_1
  leaf_0_in =49'h1_6000_93100fe0;#10
  leaf_0_in =49'h1_3080_26480000;#10
//gradient_weight_x3.Output_2->outer_product2.Input_3
  leaf_0_in =49'h1_3000_a7200fe0;#10
  leaf_0_in =49'h1_7080_43500000;#10
//outer_product1.Output_1->tensor_weight_y1.Input_1
  leaf_0_in =49'h1_7800_98100fe0;#10
  leaf_0_in =49'h1_8080_27c80000;#10
//tensor_weight_x1.Output_1->flow_calc_1.Input_1
  leaf_0_in =49'h1_9000_92100fe0;#10
  leaf_0_in =49'h1_2080_29480000;#10
//gradient_weight_x2.Output_1->outer_product1.Input_2
  leaf_0_in =49'h1_3800_97980fe0;#10
  leaf_0_in =49'h1_7880_33c80000;#10
//tensor_weight_x2.Output_2->flow_calc_2.Input_2
  leaf_0_in =49'h1_9800_a1980fe0;#10
  leaf_0_in =49'h1_1880_39d00000;#10
//gradient_weight_y_2.Output_1->gradient_weight_x2.Input_1
  leaf_0_in =49'h1_8800_93900fe0;#10
  leaf_0_in =49'h1_3880_28c80000;#10
//gradient_weight_x1.Output_1->outer_product1.Input_1
  leaf_0_in =49'h1_2800_97900fe0;#10
  leaf_0_in =49'h1_7880_22c80000;#10
//tensor_weight_x2.Output_1->flow_calc_1.Input_2
  leaf_0_in =49'h1_9800_92180fe0;#10
  leaf_0_in =49'h1_2080_39c80000;#10
//gradient_xyz_calc.Output_2->gradient_weight_y_2.Input_1
  leaf_0_in =49'h1_4000_a8900fe0;#10
  leaf_0_in =49'h1_8880_24500000;#10
//gradient_weight_x3.Output_1->outer_product1.Input_3
  leaf_0_in =49'h1_3000_97a00fe0;#10
  leaf_0_in =49'h1_7880_43480000;#10
//DMA.Output_1->gradient_xyz_calc.Input_1
  leaf_0_in =49'h1_0800_94100fe0;#10
  leaf_0_in =49'h1_4080_20c80000;#10
//tensor_weight_y1.Output_1->tensor_weight_x1.Input_1
  leaf_0_in =49'h1_8000_99100fe0;#10
  leaf_0_in =49'h1_9080_28480000;#10
//tensor_weight_x1.Output_2->flow_calc_2.Input_1
  leaf_0_in =49'h1_9000_a1900fe0;#10
  leaf_0_in =49'h1_1880_29500000;#10
//gradient_weight_x2.Output_2->outer_product2.Input_2
  leaf_0_in =49'h1_3800_a7180fe0;#10
  leaf_0_in =49'h1_7080_33d00000;#10
//gradient_weight_x1.Output_2->outer_product2.Input_1
  leaf_0_in =49'h1_2800_a7100fe0;#10
  leaf_0_in =49'h1_7080_22d00000;#10
//outer_product2.Output_1->tensor_weight_y2.Input_1
  leaf_0_in =49'h1_7000_96900fe0;#10
  leaf_0_in =49'h1_6880_27480000;#10
//gradient_weight_y_1.Output_1->gradient_weight_x1.Input_1
  leaf_0_in =49'h1_4800_92900fe0;#10
  leaf_0_in =49'h1_2880_24c80000;#10
//packet anchor



    leaf_0_in = 0;
    #100000
    ap_start = 1;
    ap_start_1 = 1;
    #100
    ap_start = 0;
    

    #1_000_000_000
    $stop();

end

endmodule
