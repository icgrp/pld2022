
`timescale 1 ns / 1 ps 
module read_queue#(
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 64,
    localparam MAX = OUT_WIDTH/IN_WIDTH
    ) (
    clk,
    reset,
    din,
    vld_in,
    rdy_upward,
    dout,
    vld_out,
    rdy_downward 
);

parameter SHIFT = 1'b0;
parameter FLUSH = 1'b1;

input                      clk;
input                      reset;
input [IN_WIDTH-1:0]       din;
input                      vld_in;
output reg                 rdy_upward;
output reg [OUT_WIDTH-1:0] dout;
output reg                 vld_out;
input                      rdy_downward;


reg state, next_state;
reg [31:0] cnt;
reg [OUT_WIDTH-1:0] dtmp;

always@(posedge clk) begin
    if(reset) begin
        state <= 1'b0;
    end else begin
        state <= next_state;
    end
end


always@(*) begin
  case (state)
    SHIFT  : begin
               if(cnt == MAX-2 && vld_in == 1 &&rdy_upward == 1) next_state = FLUSH;
               else       next_state = SHIFT;
             end
    FLUSH  : begin
               if(vld_out == 1 && rdy_upward == 1) next_state =SHIFT;
               else           next_state = FLUSH;
             end
    default: begin
                 next_state = SHIFT;
             end
   endcase
end


always@(*) begin
  case (state)
    SHIFT  : begin
               vld_out     = 1'b0;
               rdy_upward  = 1'b1;
               dout        = 0;
             end
    FLUSH  : begin
               vld_out     = vld_in;
               rdy_upward  = rdy_downward;
               dout        = {din, dtmp[OUT_WIDTH-1:IN_WIDTH]};
             end
    default: begin
                vld_out    = 1'b0;
                rdy_upward = 1'b0;
                dout       = 0;
             end
   endcase
end


always@(posedge clk) begin
    if(reset) begin
        dtmp <= 1'b0;
    end else if(state == SHIFT && rdy_upward == 1 && vld_in == 1) begin
        dtmp <= {din, dtmp[OUT_WIDTH-1:IN_WIDTH]};
    end else begin
        dtmp <= dtmp;
    end
end


always@(posedge clk) begin
    if(reset) begin
        cnt <= 1'b0;
    end else if(state == SHIFT && rdy_upward == 1 && vld_in == 1)begin
        cnt <= cnt + 1;
    end else if(state == FLUSH) begin
        cnt <= 0;
    end else begin
        cnt <= cnt;
    end
end












endmodule
