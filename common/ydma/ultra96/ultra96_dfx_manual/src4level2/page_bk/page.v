module page(
    input wire clk,
    input wire [48 : 0] din_leaf_bft2interface,
    output reg  [48 : 0] dout_leaf_interface2bft,
    input wire resend,
    input wire reset
    );

always@(posedge clk)begin
  if(reset) begin
    dout_leaf_interface2bft <= 0;
  end else if(resend) begin 
    dout_leaf_interface2bft <= din_leaf_bft2interface;
  end else begin 
    dout_leaf_interface2bft <= dout_leaf_interface2bft;
  end
end

   
endmodule
