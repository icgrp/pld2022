module picorv32_wrapper#(
  //parameter MEM_SIZE = 128*1024/4
  parameter MEM_SIZE = 4096,
  parameter IS_TRIPLE = 0,
  parameter ADDR_BITS = 14
  )(
  input clk,
  input resetn,
  output reg [48:0] print_out,
  input instr_config_wr_en,
  input [23:0] instr_config_addr,
  input [7:0] instr_config_din,
  input val_in1,
  input val_in2,
  input val_in3,
  input val_in4,
  input val_in5,
  output ready_upward1,
  output ready_upward2,
  output ready_upward3,
  output ready_upward4,
  output ready_upward5,
  input [31:0] din1,
  input [31:0] din2,
  input [31:0] din3,
  input [31:0] din4,
  input [31:0] din5,
  output val_out1,
  output val_out2,
  output val_out3,
  output val_out4,
  output val_out5,
  input ready_downward1,
  input ready_downward2,
  input ready_downward3,
  input ready_downward4,
  input ready_downward5,
  output [31:0] dout1,
  output [31:0] dout2,
  output [31:0] dout3,
  output [31:0] dout4,
  output [31:0] dout5,
  output trap
);
  wire mem_valid;
  wire mem_instr;
  wire mem_ready;
  wire [31:0] mem_addr;
  wire [31:0] mem_wdata;
  wire [3:0] mem_wstrb;
  wire [31:0] mem_rdata;
  wire [31:0] irq;


 wire val_out1_tmp;
 wire val_out2_tmp;
 wire val_out3_tmp;
 wire val_out4_tmp;
 wire val_out5_tmp;
 
 wire ready_downward1_tmp;
 wire ready_downward2_tmp;
 wire ready_downward3_tmp;
 wire ready_downward4_tmp;
 wire ready_downward5_tmp;
 
 wire [31:0] dout1_tmp;
 wire [31:0] dout2_tmp;
 wire [31:0] dout3_tmp;
 wire [31:0] dout4_tmp;
 wire [31:0] dout5_tmp;
 
 

 
 
 
	picorv32 #(
        .MEM_SIZE(MEM_SIZE) 
	) uut (
	.clk         (clk        ),
	.resetn      (resetn     ),
	.trap        (trap       ),
	.mem_valid   (mem_valid  ),
	.mem_instr   (mem_instr  ),
	.mem_ready   (mem_ready  ),
	.mem_addr    (mem_addr   ),
	.mem_wdata   (mem_wdata  ),
	.mem_wstrb   (mem_wstrb  ),
	.mem_rdata   (mem_rdata  ),
	.irq         (irq        )
	);
	
	riscv2consumer#(
      .DATA_WIDTH(32)
      )port1(
      .clk(clk),
      .reset(~resetn),
      .din(dout1_tmp),
      .val_in(val_out1_tmp),
      .ready_upward(ready_downward1_tmp),
      .dout(dout1),
      .val_out(val_out1),
      .ready_downward(ready_downward1)
      );
      
	riscv2consumer#(
        .DATA_WIDTH(32)
        )port2(
        .clk(clk),
        .reset(~resetn),
        .din(dout2_tmp),
        .val_in(val_out2_tmp),
        .ready_upward(ready_downward2_tmp),
        .dout(dout2),
        .val_out(val_out2),
        .ready_downward(ready_downward2)
        );
        
	riscv2consumer#(
      .DATA_WIDTH(32)
      )port3(
      .clk(clk),
      .reset(~resetn),
      .din(dout3_tmp),
      .val_in(val_out3_tmp),
      .ready_upward(ready_downward3_tmp),
      .dout(dout3),
      .val_out(val_out3),
      .ready_downward(ready_downward3)
      );

	riscv2consumer#(
      .DATA_WIDTH(32)
      )port4(
      .clk(clk),
      .reset(~resetn),
      .din(dout1_tmp),
      .val_in(val_out4_tmp),
      .ready_upward(ready_downward4_tmp),
      .dout(dout4),
      .val_out(val_out4),
      .ready_downward(ready_downward4)
      );      
      
	riscv2consumer#(
        .DATA_WIDTH(32)
        )port5(
        .clk(clk),
        .reset(~resetn),
        .din(dout5_tmp),
        .val_in(val_out5_tmp),
        .ready_upward(ready_downward5_tmp),
        .dout(dout5),
        .val_out(val_out5),
        .ready_downward(ready_downward5)
        );      
        
        
        
	picorv_mem#(
        .MEM_SIZE(MEM_SIZE),
        .IS_TRIPLE(IS_TRIPLE),
        .ADDR_BITS(ADDR_BITS)
	) picorv_mem_inst (
        .clk         (clk),
        .resetn      (resetn     ),
        .mem_valid   (mem_valid  ),
        .mem_instr   (mem_instr  ),
        .mem_ready   (mem_ready  ),
        .mem_addr    (mem_addr   ),
        .mem_wdata   (mem_wdata  ),
        .mem_wstrb   (mem_wstrb  ),
        .mem_rdata   (mem_rdata  ),
        .instr_config_wr_en(instr_config_wr_en),
        .instr_config_addr(instr_config_addr),
        .instr_config_din(instr_config_din),
        .val_out1    (val_out1_tmp    ),
        .val_out2    (val_out2_tmp    ),
        .val_out3    (val_out3_tmp    ),
        .val_out4    (val_out4_tmp    ),
        .val_out5    (val_out5_tmp    ),
        .ready_downward1(ready_downward1_tmp),
        .ready_downward2(ready_downward2_tmp),
        .ready_downward3(ready_downward3_tmp),
        .ready_downward4(ready_downward4_tmp),
        .ready_downward5(ready_downward5_tmp),
        .dout1       (dout1_tmp       ),
        .dout2       (dout2_tmp       ),
        .dout3       (dout3_tmp       ),
        .dout4       (dout4_tmp       ),
        .dout5       (dout5_tmp       ),
        .val_in1     (val_in1   ),
        .val_in2     (val_in2   ),
        .val_in3     (val_in3   ),
        .val_in4     (val_in4   ),
        .val_in5     (val_in5   ),
        .ready_upward1(ready_upward1),
        .ready_upward2(ready_upward2),
        .ready_upward3(ready_upward3),
        .ready_upward4(ready_upward4),
        .ready_upward5(ready_upward5),
        .din1        (din1      ),
        .din2        (din2      ),
        .din3        (din3      ),
        .din4        (din4      ),
        .din5        (din5      ),
        .irq         (irq        )
	); 

	
    always@(posedge clk) begin
        if(!resetn) begin
          print_out <= 0;
        end else begin
          if(mem_addr == 32'h1000_0000 && mem_ready==1)
            print_out <= {1'b1, 40'h0000000000, mem_wdata[7:0]};
          else
            print_out <= {1'b0, 48'h0000_0000_0000};
        end          
    end
    

   /* 
    fifo_stream fifo_stream_inst(
        .clk(clk),
        .reset(!resetn),
        .din(din),
        .val_in(val_in),
        .ready_upward(ready_upward),
        .dout(dout),
        .val_out(val_out),
        .ready_downward(ready_downward)
        );
     */   
        

endmodule
