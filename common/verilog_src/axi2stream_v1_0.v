
`timescale 1 ns / 1 ps

	module axi2stream_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here
		output ap_start,
        input [ C_S00_AXI_DATA_WIDTH-1 : 0] din1,
        input val_in1,
        output ready_upward1,
        input [ C_S00_AXI_DATA_WIDTH-1 : 0] din2,
        input val_in2,
        output ready_upward2,
        input [ C_S00_AXI_DATA_WIDTH-1 : 0] din3,
        input val_in3,
        output ready_upward3,
        input [ C_S00_AXI_DATA_WIDTH-1 : 0] din4,
        input val_in4,
        output ready_upward4,
        input [ C_S00_AXI_DATA_WIDTH-1 : 0] din5,
        input val_in5,
        output ready_upward5,
        input [ C_S00_AXI_DATA_WIDTH-1 : 0] din6,
        input val_in6,
        output ready_upward6,
        input [ C_S00_AXI_DATA_WIDTH-1 : 0] din7,
        input val_in7,
        output ready_upward7,
        output [ C_S00_AXI_DATA_WIDTH-1 : 0] dout1,
        output val_out1,
        input ready_downward1,
        output [ C_S00_AXI_DATA_WIDTH-1 : 0] dout2,
        output val_out2,
        input ready_downward2,
        output [ C_S00_AXI_DATA_WIDTH-1 : 0] dout3,
        output val_out3,
        input ready_downward3,
        output [ C_S00_AXI_DATA_WIDTH-1 : 0] dout4,
        output val_out4,
        input ready_downward4,
        output [ C_S00_AXI_DATA_WIDTH-1 : 0] dout5,
        output val_out5,
        input ready_downward5,
        output [ C_S00_AXI_DATA_WIDTH-1 : 0] dout6,
        output val_out6,
        input ready_downward6,
        output [ C_S00_AXI_DATA_WIDTH-1 : 0] dout7,
        output val_out7,
        input ready_downward7,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	axi2stream_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) axi2stream_v1_0_S00_AXI_inst (
	    .ap_start(ap_start),
        .din1(din1),
        .val_in1(val_in1),
        .ready_upward1(ready_upward1),
        .din2(din2),
        .val_in2(val_in2),
        .ready_upward2(ready_upward2),
        .din3(din3),
        .val_in3(val_in3),
        .ready_upward3(ready_upward3),
        .din4(din4),
        .val_in4(val_in4),
        .ready_upward4(ready_upward4),
        .din5(din5),
        .val_in5(val_in5),
        .ready_upward5(ready_upward5),
        .din6(din6),
        .val_in6(val_in6),
        .ready_upward6(ready_upward6),
        .din7(din7),
        .val_in7(val_in7),
        .ready_upward7(ready_upward7),
        .dout1(dout1),
        .val_out1(val_out1),
        .ready_downward1(ready_downward1),
        .dout2(dout2),
        .val_out2(val_out2),
        .ready_downward2(ready_downward2),
        .dout3(dout3),
        .val_out3(val_out3),
        .ready_downward3(ready_downward3),
        .dout4(dout4),
        .val_out4(val_out4),
        .ready_downward4(ready_downward4),
        .dout5(dout5),
        .val_out5(val_out5),
        .ready_downward5(ready_downward5),
        .dout6(dout6),
        .val_out6(val_out6),
        .ready_downward6(ready_downward6),
        .dout7(dout7),
        .val_out7(val_out7),
        .ready_downward7(ready_downward7),
        
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here

	// User logic ends

	endmodule


`timescale 1 ns / 1 ps

	module axi2stream_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here
		output ap_start,
        input [C_S_AXI_DATA_WIDTH-1 : 0] din1,
        input val_in1,
        output ready_upward1,
        input [C_S_AXI_DATA_WIDTH-1 : 0] din2,
        input val_in2,
        output ready_upward2,
        input [C_S_AXI_DATA_WIDTH-1 : 0] din3,
        input val_in3,
        output ready_upward3,
        input [C_S_AXI_DATA_WIDTH-1 : 0] din4,
        input val_in4,
        output ready_upward4,
        input [C_S_AXI_DATA_WIDTH-1 : 0] din5,
        input val_in5,
        output ready_upward5,
        input [C_S_AXI_DATA_WIDTH-1 : 0] din6,
        input val_in6,
        output ready_upward6,
        input [C_S_AXI_DATA_WIDTH-1 : 0] din7,
        input val_in7,
        output ready_upward7,
        output [C_S_AXI_DATA_WIDTH-1 : 0] dout1,
        output val_out1,
        input ready_downward1,
        output [C_S_AXI_DATA_WIDTH-1 : 0] dout2,
        output val_out2,
        input ready_downward2,
        output [C_S_AXI_DATA_WIDTH-1 : 0] dout3,
        output val_out3,
        input ready_downward3,
        output [C_S_AXI_DATA_WIDTH-1 : 0] dout4,
        output val_out4,
        input ready_downward4,
        output [C_S_AXI_DATA_WIDTH-1 : 0] dout5,
        output val_out5,
        input ready_downward5,
        output [C_S_AXI_DATA_WIDTH-1 : 0] dout6,
        output val_out6,
        input ready_downward6,
        output [C_S_AXI_DATA_WIDTH-1 : 0] dout7,
        output val_out7,
        input ready_downward7,
        
        
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 16
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg8;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg9;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg10;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg11;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg12;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg13;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg14;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg15;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	//integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	      slv_reg4 <= 0;
	      slv_reg5 <= 0;
	      slv_reg6 <= 0;
	      slv_reg7 <= 0;
	      //slv_reg8 <= 0;
	      //slv_reg9 <= 0;
	      //slv_reg10 <= 0;
	      //slv_reg11 <= 0;
	      //slv_reg12 <= 0;
	      //slv_reg13 <= 0;
	      //slv_reg14 <= 0;
	      //slv_reg15 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          4'h0: slv_reg0 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                //slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          4'h1: slv_reg1 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                //slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          4'h2: slv_reg2 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                //slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          4'h3: slv_reg3 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                //slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          4'h4: slv_reg4 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                //slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          4'h5: slv_reg5 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 5
	                //slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          4'h6: slv_reg6 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 6
	                //slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          4'h7: slv_reg7 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 7
	                //slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          //4'h8: slv_reg8 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 8
	                //slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          //4'h9: slv_reg9 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 9
	                //slv_reg9[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          //4'hA: slv_reg10 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 10
	                //slv_reg10[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          //4'hB: slv_reg11 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 11
	                //slv_reg11[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          //4'hC: slv_reg12 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 12
	                //slv_reg12[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          //4'hD: slv_reg13 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 13
	                //slv_reg13[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          //4'hE: slv_reg14 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 14
	                //slv_reg14[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          //4'hF: slv_reg15 <= S_AXI_WDATA;
	            //for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              //if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 15
	                //slv_reg15[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              //end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                      slv_reg4 <= slv_reg4;
	                      slv_reg5 <= slv_reg5;
	                      slv_reg6 <= slv_reg6;
	                      slv_reg7 <= slv_reg7;
	                      //slv_reg8 <= slv_reg8;
	                      //slv_reg9 <= slv_reg9;
	                      //slv_reg10 <= slv_reg10;
	                      //slv_reg11 <= slv_reg11;
	                      //slv_reg12 <= slv_reg12;
	                      //slv_reg13 <= slv_reg13;
	                      //slv_reg14 <= slv_reg14;
	                      //slv_reg15 <= slv_reg15;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        4'h0   : reg_data_out <= slv_reg0;
	        4'h1   : reg_data_out <= slv_reg1;
	        4'h2   : reg_data_out <= slv_reg2;
	        4'h3   : reg_data_out <= slv_reg3;
	        4'h4   : reg_data_out <= slv_reg4;
	        4'h5   : reg_data_out <= slv_reg5;
	        4'h6   : reg_data_out <= slv_reg6;
	        4'h7   : reg_data_out <= slv_reg7;
	        4'h8   : reg_data_out <= slv_reg8;
	        4'h9   : reg_data_out <= slv_reg9;
	        4'hA   : reg_data_out <= slv_reg10;
	        4'hB   : reg_data_out <= slv_reg11;
	        4'hC   : reg_data_out <= slv_reg12;
	        4'hD   : reg_data_out <= slv_reg13;
	        4'hE   : reg_data_out <= slv_reg14;
	        4'hF   : reg_data_out <= slv_reg15;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

    
	// Add user logic here
    wire winc1, winc2, winc3, winc4, winc5, winc6, winc7; 
    wire rinc1, rinc2, rinc3, rinc4, rinc5, rinc6, rinc7;
    wire wfull1,  wfull2,  wfull3,  wfull4,  wfull5,  wfull6,  wfull7; 
    wire rempty1, rempty2, rempty3, rempty4, rempty5, rempty6, rempty7;
    wire [31:0] slv_reg7_pulse;
    
    assign winc1 = slv_reg7_pulse[0];
    assign rinc1 = slv_reg7_pulse[1];
    assign winc2 = slv_reg7_pulse[2];
    assign rinc2 = slv_reg7_pulse[3];
    assign winc3 = slv_reg7_pulse[4];
    assign rinc3 = slv_reg7_pulse[5];
    assign winc4 = slv_reg7_pulse[6];
    assign rinc4 = slv_reg7_pulse[7];
    assign winc5 = slv_reg7_pulse[8];
    assign rinc5 = slv_reg7_pulse[9];
    assign winc6 = slv_reg7_pulse[10];
    assign rinc6 = slv_reg7_pulse[11];
    assign winc7 = slv_reg7_pulse[12];
    assign rinc7 = slv_reg7_pulse[13];
    assign ap_start = slv_reg7[14];
    
    assign slv_reg15 = {18'd0, wfull7, rempty7, wfull6, rempty6, wfull5, rempty5, wfull4, rempty4, wfull3, rempty3, wfull2, rempty2, wfull1, rempty1};

    toggle_detect #(
    .data_width(32)
    ) toggle_detect1(
    .data_out(slv_reg7_pulse),
    .data_in(slv_reg7),
    .clk(S_AXI_ACLK),
    .reset(~S_AXI_ARESETN)
    );
    
        

    fifo_stream_out #(
    .PAYLOAD_BITS(32),
    .NUM_BRAM_ADDR_BITS(9)
        )arm2fabric1(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .wdata(slv_reg0),
        .winc(winc1),
        .full(wfull1),
        .dout(dout1),
        .val_out(val_out1),
        .ready_downward(ready_downward1)
    );
            
    fifo_stream_out #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )arm2fabric2(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .wdata(slv_reg1),
        .winc(winc2),
        .full(wfull2),
        .dout(dout2),
        .val_out(val_out2),
        .ready_downward(ready_downward2)
        );    
        
    fifo_stream_out #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )arm2fabric3(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .wdata(slv_reg2),
        .winc(winc3),
        .full(wfull3),
        .dout(dout3),
        .val_out(val_out3),
        .ready_downward(ready_downward3)
        );                            


    fifo_stream_out #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )arm2fabric4(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .wdata(slv_reg3),
        .winc(winc4),
        .full(wfull4),
        .dout(dout4),
        .val_out(val_out4),
        .ready_downward(ready_downward4)
        );    

    fifo_stream_out #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )arm2fabric5(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .wdata(slv_reg4),
        .winc(winc5),
        .full(wfull5),
        .dout(dout5),
        .val_out(val_out5),
        .ready_downward(ready_downward5)
        );    

    fifo_stream_out #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )arm2fabric6(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .wdata(slv_reg5),
        .winc(winc6),
        .full(wfull6),
        .dout(dout6),
        .val_out(val_out6),
        .ready_downward(ready_downward6)
        );    

    fifo_stream_out #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )arm2fabric7(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .wdata(slv_reg6),
        .winc(winc7),
        .full(wfull7),
        .dout(dout7),
        .val_out(val_out7),
        .ready_downward(ready_downward7)
        );    



    fifo_stream_in #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )fabric2arm1(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .din(din1),
        .val_in(val_in1),
        .ready_upward(ready_upward1),
        .rdata(slv_reg8),
        .rempty(rempty1),
        .rinc(rinc1)
        );

    fifo_stream_in #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )fabric2arm2(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .din(din2),
        .val_in(val_in2),
        .ready_upward(ready_upward2),
        .rdata(slv_reg9),
        .rempty(rempty2),
        .rinc(rinc2)
        );

    fifo_stream_in #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )fabric2arm3(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .din(din3),
        .val_in(val_in3),
        .ready_upward(ready_upward3),
        .rdata(slv_reg10),
        .rempty(rempty3),
        .rinc(rinc3)
        );
        
    fifo_stream_in #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )fabric2arm4(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .din(din4),
        .val_in(val_in4),
        .ready_upward(ready_upward4),
        .rdata(slv_reg11),
        .rempty(rempty4),
        .rinc(rinc4)
        );
            
    fifo_stream_in #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )fabric2arm5(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .din(din5),
        .val_in(val_in5),
        .ready_upward(ready_upward5),
        .rdata(slv_reg12),
        .rempty(rempty5),
        .rinc(rinc5)
        );

    fifo_stream_in #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )fabric2arm6(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .din(din6),
        .val_in(val_in6),
        .ready_upward(ready_upward6),
        .rdata(slv_reg13),
        .rempty(rempty6),
        .rinc(rinc6)
        );

    fifo_stream_in #(
        .PAYLOAD_BITS(32),
        .NUM_BRAM_ADDR_BITS(9)
        )fabric2arm7(
        .clk(S_AXI_ACLK),
        .reset(~S_AXI_ARESETN),
        .din(din7),
        .val_in(val_in7),
        .ready_upward(ready_upward7),
        .rdata(slv_reg14),
        .rempty(rempty7),
        .rinc(rinc7)
        );    
    
        

         
	// User logic ends

	endmodule

