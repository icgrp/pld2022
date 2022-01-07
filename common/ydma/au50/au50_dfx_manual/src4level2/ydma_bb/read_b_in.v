
/** port == 2, bram_in_2 to user logic or
* if it needs to update freespcae, freespace_update is asserted
*
* The reason why it has *_early and *_prev signals is that this function's output is dependent on
* what's in bram_in. And once we know that b_in_outb is invalid, we need to restore b_in_addrb.
*/

module read_b_in #(
    parameter FREESPACE_UPDATE_SIZE = 64,
    parameter PAYLOAD_BITS = 64,
    parameter NUM_ADDR_BITS = 7,
    localparam R0W1 = 1'b0, //
    localparam R1W0 = 1'b1
    )(
    input clk,
    input reset,
    input ack_user2b_in,
    input [PAYLOAD_BITS:0] doutb_0,
    input [PAYLOAD_BITS:0] doutb_1,

    output reg [NUM_ADDR_BITS-2:0] addrb_0,
    output reg [NUM_ADDR_BITS-2:0] addrb_1,
    output [PAYLOAD_BITS-1:0] dout_leaf_interface2user,
    output vld_bram_in2user,
    output reg freespace_update,
    // b_in_web invalidates used data by deassert the valid bit
    output reg web_0,
    output reg web_1
    );

    reg [NUM_ADDR_BITS-2:0] numConsumed;
    reg state;
    reg next_state;
    
    assign dout_leaf_interface2user = (state == R0W1) ? doutb_0[PAYLOAD_BITS-1:0] : doutb_1[PAYLOAD_BITS-1:0];
    assign vld_bram_in2user = (state == R0W1) ? doutb_0[PAYLOAD_BITS] : doutb_1[PAYLOAD_BITS];
    
    always@(posedge clk) 
    begin
        if(reset) begin
            state <= R0W1;
        end
        else begin
            state <= next_state;
        end
    end

    // state transition table
    always@(*) begin
        case(state)
            R0W1: begin
                if(vld_bram_in2user && ack_user2b_in) begin
                    next_state = R1W0;
                end else begin
                    next_state = R0W1;
                end
            end
            R1W0: begin
                if(vld_bram_in2user && ack_user2b_in) begin
                    next_state = R0W1;
                end else begin
                    next_state = R1W0;
                end
            end
        endcase
    end

   //addrb
   always@(posedge clk) begin
       if(reset) begin
           addrb_0 <= 0;
           addrb_1 <= 0;
       end
       else begin
           case(state)
               R0W1: begin
                   if(vld_bram_in2user && ack_user2b_in) begin
                        addrb_0 <= addrb_0+1;
                        addrb_1 <= addrb_1;
                   end else begin
                        addrb_0 <= addrb_0;
                        addrb_1 <= addrb_1;     
                   end
               end
               R1W0: begin
                   if(vld_bram_in2user && ack_user2b_in) begin
                        addrb_0 <= addrb_0;
                        addrb_1 <= addrb_1+1;
                   end else begin
                        addrb_0 <= addrb_0;
                        addrb_1 <= addrb_1;     
                   end
               end
           endcase
       end
   end  

   //numConsumed
    always@(posedge clk) begin
        if(reset) begin
            numConsumed <= 0;
        end else if(vld_bram_in2user && ack_user2b_in) begin
            numConsumed <= numConsumed + 1;
        end else begin
            numConsumed <= numConsumed;              
        end
    end  
   

   //freespace_update
    always@(posedge clk) begin
        if(reset) begin
            freespace_update <= 0;
        end else if(vld_bram_in2user && ack_user2b_in && numConsumed==FREESPACE_UPDATE_SIZE-1) begin
            freespace_update <= 1;
        end else begin
            freespace_update <= 0;            
       end
   end  
   
   
   //web_0
   always@(*) begin
       if(state == R0W1 && vld_bram_in2user && ack_user2b_in) begin
            web_0 = 1;
       end else begin
            web_0 = 0;              
       end
    end
   
   //web_1
    always@(*) begin
        if(state == R1W0 && vld_bram_in2user && ack_user2b_in) begin
             web_1 = 1;
        end else begin
             web_1 = 0;              
        end
     end   
     

endmodule
