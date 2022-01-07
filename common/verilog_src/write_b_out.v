module write_b_out#(
    parameter PAYLOAD_BITS = 64
    )(
    input vld_user2b_out,
    input [PAYLOAD_BITS-1:0] din_leaf_user2interface,
    input full,
    
    output reg wr_en,
    output reg [PAYLOAD_BITS-1:0] din);
    
//    assign wr_en = (full) ? 0 : (vld_user2b_out) ? 1 : 0;
//    assign din = (full) ? 42 : (vld_user2b_out) ? din_leaf_user2interface : 42;

    always@(*) begin
        if(full) begin // can't push in to fifo
            wr_en = 0;
            din = 42; // random, because this data won't be written anyway
        end
        else begin
            if(vld_user2b_out) begin
                wr_en = 1;
                din = din_leaf_user2interface;
            end
            else begin
                wr_en = 0;
                din = 42; // random, because this data won't be written anyway
            end                
        end
    end

endmodule