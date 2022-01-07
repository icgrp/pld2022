module pipe_ff_1 (
	input clk, 
	input reset, 
	input [data_width-1:0] din,
	output reg [data_width-1:0] dout 
	);

	parameter data_width= 2;


	always @(posedge clk) begin
		if (reset)
			dout <= 0;
		else
			dout <=din;
	end
	
endmodule
