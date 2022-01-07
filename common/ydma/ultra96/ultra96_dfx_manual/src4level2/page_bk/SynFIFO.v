module SynFIFO (
	clk,
	rst_n,
	rdata, 
	wfull, 
	rempty, 
	wdata,
	winc, 
	rinc
	);
	
parameter DSIZE = 32;
parameter ASIZE = 9;
parameter MEMDEPTH = 1<<ASIZE;
parameter RAM_TYPE = "block";     // Type of RAM: string; "auto", "block", or "distributed";

output reg [DSIZE-1:0] rdata;
output wfull;
output rempty;

input [DSIZE-1:0] wdata;
input winc, rinc, clk, rst_n;

reg [ASIZE:0] wptr;
reg [ASIZE:0] rptr;
(* ram_style = RAM_TYPE *) reg [DSIZE-1:0] ex_mem [0:MEMDEPTH-1];
wire [DSIZE-1:0] rdata_tmp;

wire wfull_r;
wire [ASIZE:0] wptr_1;

always @(posedge clk)
	if (!rst_n) wptr <= 0;
	else if (winc && !wfull) begin
		ex_mem[wptr[ASIZE-1:0]] <= wdata;
		wptr <= wptr+1;
	end


always @(posedge clk)
	if (!rst_n) rptr <= 0;
	else if (rinc && !rempty) rptr <= rptr+1;

assign wptr_1 = wptr + 1;	
assign rdata_tmp = ex_mem[rptr[ASIZE-1:0]];
assign rempty = (rptr == wptr);
assign wfull = ((wptr_1[ASIZE-1:0] == rptr[ASIZE-1:0]) && (wptr_1[ASIZE] != rptr[ASIZE])) || wfull_r;
assign wfull_r = (wptr[ASIZE-1:0] == rptr[ASIZE-1:0]) && (wptr[ASIZE] != rptr[ASIZE]);

always @(posedge clk) begin
    if(!rst_n) begin
        rdata <= 0;
    end else if(rinc) begin
        rdata <= rdata_tmp;
    end else begin
        rdata <= rdata;
    end
end




endmodule
