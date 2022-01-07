module counter1 #(
    parameter CNT_WIDTH = 32
)(
  input clk,
  input reset,
  input valid,
  input ready,
  output reg [CNT_WIDTH-1:0] cnt1
);



always@(posedge clk) begin
  if (reset)
    cnt1 <= 0;
  else if(valid && ready)
    cnt1 <= cnt1 + 1;
  else
    cnt1 <= cnt1;
end


endmodule



