`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/09/2020 01:43:45 PM
// Design Name: 
// Module Name: Input_Wrapper
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


module stream_shell #(
    parameter PAYLOAD_BITS = 128,
    parameter NUM_BRAM_ADDR_BITS = 7,
    localparam FIFO_DEPTH = (2**NUM_BRAM_ADDR_BITS)
    )(
    input clk,
    input reset,
    input [PAYLOAD_BITS-1:0] din,
    input val_in,
    output ready_upward,
    output reg [PAYLOAD_BITS-1:0] dout,
    output reg val_out,
    input ready_downward
    );


wire empty;
reg rd_en;
wire full;
wire wr_en;

wire [PAYLOAD_BITS-1:0] fifo_out;
wire [PAYLOAD_BITS-1:0] fifo_in;


assign ready_upward = ~full;
assign wr_en = val_in;
assign fifo_in = din;


xpm_fifo_sync # (

  .FIFO_MEMORY_TYPE          ("block"),           //string; "auto", "block", or "distributed";
  .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
  //.RELATED_CLOCKS            (0),                //positive integer; 0 or 1
  .FIFO_WRITE_DEPTH          (FIFO_DEPTH),             //positive integer
  .WRITE_DATA_WIDTH          (PAYLOAD_BITS),               //positive integer
  .WR_DATA_COUNT_WIDTH       (NUM_BRAM_ADDR_BITS),               //positive integer
  .PROG_FULL_THRESH          (10),               //positive integer
  .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
  .READ_MODE                 ("std"),            //string; "std" or "fwft";
  .FIFO_READ_LATENCY         (1),                //positive integer;
  .READ_DATA_WIDTH           (PAYLOAD_BITS),               //positive integer
  .RD_DATA_COUNT_WIDTH       (NUM_BRAM_ADDR_BITS),               //positive integer
  .PROG_EMPTY_THRESH         (10),               //positive integer
  .DOUT_RESET_VALUE          ("0"),              //string
  //.CDC_SYNC_STAGES           (2),                //positive integer
  .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;

) xpm_fifo_sync_inst (

  .rst              (reset),
  .wr_clk           (clk),
  .wr_en            (wr_en),
  .din              (fifo_in),
  .full             (full),
  .overflow         (overflow),
  .wr_rst_busy      (wr_rst_busy),
  //.rd_clk           (clk),
  .rd_en            (rd_en),
  .dout             (fifo_out),
  .empty            (empty),
  .underflow        (underflow),
  .rd_rst_busy      (rd_rst_busy),
  .prog_full        (prog_full),
  .wr_data_count    (wr_data_count),
  .prog_empty       (prog_empty),
  .rd_data_count    (rd_data_count),
  .sleep            (1'b0),
  .injectsbiterr    (1'b0),
  .injectdbiterr    (1'b0),
  .sbiterr          (),
  .dbiterr          ()

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
