





module xram_triple #(
  parameter RAM_WIDTH = 8,
  parameter RAM_DEPTH = 65536,
  parameter RAM_TYPE = "block",
  parameter RAM_PERFORMANCE = "LOW_LATENCY",
  parameter INIT_FILE = ""
) (
  input [clogb2(RAM_DEPTH-1)-1:0] addra,
  input [clogb2(RAM_DEPTH-1)-1:0] addrb,
  input [RAM_WIDTH-1:0] dina,
  input [RAM_WIDTH-1:0] dinb,
  input clka,
  input wea,
  input web,
  input ena,
  input enb,
  input rsta,
  input rstb,
  input regcea,
  input regceb,
  output reg [RAM_WIDTH-1:0] douta,
  output reg [RAM_WIDTH-1:0] doutb
);


  wire [RAM_WIDTH-1:0] douta_0;
  wire [RAM_WIDTH-1:0] doutb_0;
  wire [RAM_WIDTH-1:0] douta_1;
  wire [RAM_WIDTH-1:0] doutb_1;
  wire [RAM_WIDTH-1:0] douta_2;
  wire [RAM_WIDTH-1:0] doutb_2;
  wire [RAM_WIDTH-1:0] douta_3;
  wire [RAM_WIDTH-1:0] doutb_3;

reg [1:0] sela, selb;

always@(posedge clka) begin
	if(rsta) begin
		sela <= 0;
		selb <= 0;
	end else begin
		sela <= addra[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2];
		selb <= addrb[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2];
	end
end

always@(*) begin
	case(sela)
		2'b00: douta = douta_0;
		2'b01: douta = douta_1;
		2'b10: douta = douta_2;
		2'b11: douta = douta_3;
		default: douta = 0;
	endcase
end


always@(*) begin
	case(selb)
		2'b00: doutb = doutb_0;
		2'b01: doutb = doutb_1;
		2'b10: doutb = doutb_2;
		2'b11: doutb = doutb_3;
		default: doutb = 0;
	endcase
end



  xram2 #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH>>2),
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .INIT_FILE(INIT_FILE)
  ) ram_bank0 (
    .addra(addra[clogb2(RAM_DEPTH-1)-3:0]),
    .addrb(addrb[clogb2(RAM_DEPTH-1)-3:0]),
    .dina(dina),
    .dinb(dinb),
    .clka(clka),
    .wea((wea&&addra[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2]==2'b00)),
    .web((web&&addrb[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2]==2'b00)),
    .ena(ena),
    .enb(enb),
    .rsta(rsta),
    .rstb(rstb),
    .regcea(regcea),
    .regceb(regceb),
    .douta(douta_0),
    .doutb(doutb_0)
  );

  xram2 #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH>>2),
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .INIT_FILE(INIT_FILE)
  ) ram_bank1 (
    .addra(addra[clogb2(RAM_DEPTH-1)-3:0]),
    .addrb(addrb[clogb2(RAM_DEPTH-1)-3:0]),
    .dina(dina),
    .dinb(dinb),
    .clka(clka),
    .wea((wea&&addra[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2]==2'b01)),
    .web((web&&addrb[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2]==2'b01)),
    .ena(ena),
    .enb(enb),
    .rsta(rsta),
    .rstb(rstb),
    .regcea(regcea),
    .regceb(regceb),
    .douta(douta_1),
    .doutb(doutb_1)
  );

  xram2 #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH>>2),
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .INIT_FILE(INIT_FILE)
  ) ram_bank2 (
    .addra(addra[clogb2(RAM_DEPTH-1)-3:0]),
    .addrb(addrb[clogb2(RAM_DEPTH-1)-3:0]),
    .dina(dina),
    .dinb(dinb),
    .clka(clka),
    .wea((wea&&addra[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2]==2'b10)),
    .web((web&&addrb[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2]==2'b10)),
    .ena(ena),
    .enb(enb),
    .rsta(rsta),
    .rstb(rstb),
    .regcea(regcea),
    .regceb(regceb),
    .douta(douta_2),
    .doutb(doutb_2)
  );

assign douta_3 = 0;
assign doutb_3 = 0;

/*
  xram2 #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH>>2),
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .INIT_FILE(INIT_FILE)
  ) ram_bank3 (
    .addra(addra[clogb2(RAM_DEPTH-1)-3:0]),
    .addrb(addrb[clogb2(RAM_DEPTH-1)-3:0]),
    .dina(dina),
    .dinb(dinb),
    .clka(clka),
    .wea((wea&&addra[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2]==2'b11)),
    .web((web&&addrb[clogb2(RAM_DEPTH-1)-1:clogb2(RAM_DEPTH-1)-2]==2'b11)),
    .ena(ena),
    .enb(enb),
    .rsta(rsta),
    .rstb(rstb),
    .regcea(regcea),
    .regceb(regceb),
    .douta(douta_3),
    .doutb(doutb_3)
  );
*/
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
  
endmodule

// The following is an instantiation template for xilinx_true_dual_port_no_change_1_clock_ram
/*
  //  Xilinx True Dual Port RAM, No Change, Single Clock
  xilinx_true_dual_port_no_change_1_clock_ram #(
    .RAM_WIDTH(18),                       // Specify RAM data width
    .RAM_DEPTH(1024),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) your_instance_name (
    .addra(addra),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(addrb),   // Port B address bus, width determined from RAM_DEPTH
    .dina(dina),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(dinb),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clka),     // Clock
    .wea(wea),       // Port A write enable
    .web(web),       // Port B write enable
    .ena(ena),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(enb),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rsta),     // Port A output reset (does not affect memory contents)
    .rstb(rstb),     // Port B output reset (does not affect memory contents)
    .regcea(regcea), // Port A output register enable
    .regceb(regceb), // Port B output register enable
    .douta(douta),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(doutb)    // Port B RAM output data, width determined from RAM_WIDTH
  );
*/
							
							
