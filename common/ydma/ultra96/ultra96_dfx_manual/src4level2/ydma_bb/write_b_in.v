/** port == 2,3,4
*   bft to bram_in_2,bram_in_3,bram_in_4
*/

module write_b_in#(
    parameter NUM_PORT_BITS = 4,
    parameter PAYLOAD_BITS = 64,
    parameter NUM_ADDR_BITS = 7,
    parameter PORT_No = 2
    )(
    output reg wea,
    output reg [NUM_ADDR_BITS-1:0] addra,
    output reg [PAYLOAD_BITS:0] dina,
    input clk,
    input reset,
    input [NUM_PORT_BITS-1:0] port,
    input [NUM_ADDR_BITS-1:0] addr,
    input vldBit,
    input [PAYLOAD_BITS-1:0] payload);
    
    always@(posedge clk) begin
        if(reset) begin
            wea <= 0;
            addra <= 0;
            dina <= 0;
        end
        else begin
            if(port==PORT_No && vldBit) begin // need to be changed!
                wea <= 1;
                addra <= addr;
                dina <= {vldBit,payload};        
            end
            else begin
                wea <= 0;
                addra <= 0; // random
                dina <= 0; // random
            end
        end
    end
    
endmodule
