module rise_detect #(
        parameter integer data_width = 8
    )
    (
        output reg [data_width-1:0]data_out,
        input [data_width-1:0] data_in,
        input clk,
        input reset
    );
    
        reg [data_width-1:0] data_in_1;
        reg [data_width-1:0] data_in_2;
        
        always@(posedge clk) begin 
            if(reset) begin
                {data_in_2, data_in_1} <= 0;
            end else begin
                {data_in_2, data_in_1} <= {data_in_1, data_in};
            end
        end
        
        wire [data_width-1:0] data_out_comb;
        assign data_out_comb = (~data_in_2) & (data_in_1);
        
        always@(posedge clk) begin 
            if(reset) begin
                data_out <= 0;
            end else begin
                data_out <= data_out_comb;
            end
        end
    
    
        
endmodule
