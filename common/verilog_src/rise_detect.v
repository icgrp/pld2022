`timescale 1ns / 1ps

// NUM_LEAF_BITS + NUM_PORT_BITS + NUM_ADDR_BITS == ADDR_TOTAL
// NUM_BRAM_ADDR_BITS =< NUM_ADDR_BITS
// NUM_BRAM_ADDR_BITS = NUM_BRAM_ADDR_BITS + NUM_ADDR_REMAINDER_BITS
// port values == 0,1 reserved for initialization packets
// in thise case, port values == 2,3,4,5,6,7,8 are BRAM_IN
// port values == 9,10,11,12,13,14,15 are BRAM_OUT


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
