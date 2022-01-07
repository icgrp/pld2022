`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: ylxiao
// 
// Create Date: 03/09/2020 01:43:45 PM
// Design Name: 
// Module Name: fifo_stream
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   This is a manual designed stream fifo
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_stream_out #(
    parameter PAYLOAD_BITS = 32,
    parameter NUM_BRAM_ADDR_BITS = 9,
    localparam FIFO_DEPTH = (2**NUM_BRAM_ADDR_BITS)
    )(
    input clk,
    input reset,
    input [PAYLOAD_BITS-1: 0] wdata,
    input winc,
    output full,
    output reg [PAYLOAD_BITS-1:0] dout,
    output reg val_out,
    input ready_downward
    );


wire empty;
reg rd_en;

wire [PAYLOAD_BITS-1:0] fifo_out;




SynFIFO SynFIFO_inst (
	.clk(clk),
	.rst_n(!reset),
	.rdata(fifo_out), 
	.wfull(full), 
	.rempty(empty), 
	.wdata(wdata),
	.winc(winc), 
	.rinc(rd_en)
	);
	


localparam NODATA = 1'b0;
localparam VALDATA  = 1'b1;

reg state;
reg next_state;

always@(posedge clk) begin
    if(reset)
        state <= NODATA;
    else
        state <= next_state;
end



//assign dout = state ? (fifo_out) : (empty ? 0 : fifo_out);


always@(*) begin
    case(state)
        NODATA: begin
            if(empty) begin
                next_state = NODATA;
                rd_en = 0;
                dout = 0;
            end else begin
                next_state = VALDATA;
                rd_en = 1;
                dout = fifo_out;
            end
        end
        
        VALDATA: begin
            if(!ready_downward) begin
                next_state = VALDATA;
                rd_en = 0;
                dout = fifo_out;
            end else if (empty) begin
                next_state = NODATA;
                rd_en = 0;
                dout = fifo_out;
            end else begin
                next_state = VALDATA;
                rd_en = 1;
                dout = fifo_out;
            end
        end
    endcase
end

//val_out
always@(posedge clk) begin
    if(reset) begin
        val_out <= 0;
    end else begin
        case(state)
            NODATA: begin
                if(empty) begin
                    val_out <= 0;
                end else begin
                    val_out <= 1;
                end
            end
            
            VALDATA: begin
                if(!ready_downward) begin
                    val_out <= 1;
                end else if (ready_downward && empty) begin
                    val_out <= 0;
                end else if (ready_downward && (!empty)) begin
                    val_out <= 1;
                end
            end
        endcase
    end
end

endmodule
