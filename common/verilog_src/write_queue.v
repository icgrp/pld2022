
`timescale 1 ns / 1 ps 
module write_queue#(
    parameter IN_WIDTH = 512,
    parameter OUT_WIDTH = 32,
    localparam MAX = IN_WIDTH/OUT_WIDTH
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

parameter P2P = 1'b0;
parameter QUE = 1'b1;

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
reg [IN_WIDTH-OUT_WIDTH-1:0] dtmp;


always@(posedge clk) begin
    if(reset) begin
        state <= 1'b0;
    end else begin
        state <= next_state;
    end
end


always@(*) begin
  case (state)
    P2P    : begin
               if(vld_in && (rdy_upward == 1)) next_state = QUE;
               else       next_state = P2P;
             end
    QUE    : begin
               if(cnt == MAX-2 && vld_out && rdy_downward) next_state = P2P;
               else           next_state = QUE;
             end
    default: begin
                 next_state = P2P;
             end
   endcase
end


always@(*) begin
  case (state)
    P2P    : begin
               vld_out     = vld_in;
               rdy_upward  = rdy_downward;
               dout        = din[OUT_WIDTH-1:0];
             end
    QUE    : begin
               vld_out     = 1'b1;
               rdy_upward  = 1'b0;
               dout        = dtmp[OUT_WIDTH-1:0];
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
    end else if(state == P2P) begin
        dtmp <= din[IN_WIDTH-1:32];
    end else if(state == QUE && rdy_downward == 1 && vld_out == 1) begin
        dtmp <= dtmp >> OUT_WIDTH;
    end
end


always@(posedge clk) begin
    if(reset) begin
        cnt <= 1'b0;
    end else if(state == QUE && rdy_downward == 1 && vld_out == 1)begin
        cnt <= cnt + 1;
    end else if(state == P2P) begin
        cnt <= 0;
    end else begin
        cnt <= cnt;
    end
end












endmodule
