`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2020 05:11:01 PM
// Design Name: 
// Module Name: dual_ram
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


module single_ram#(
    parameter PAYLOAD_BITS = 32, 
    parameter NUM_BRAM_ADDR_BITS = 7,
    parameter NUM_ADDR_BITS = 7,
    parameter RAM_TYPE = "block",
    localparam BRAM_DEPTH = 2**(NUM_BRAM_ADDR_BITS)
    //localparam BRAM_DEPTH = 128
    )(
    input clk,
    input reset,
    input wea,
    input web,
    input [NUM_ADDR_BITS-1:0] addra,
    input [NUM_ADDR_BITS-1:0] addrb,
    input [PAYLOAD_BITS:0] dina,
    input [PAYLOAD_BITS:0] dinb,
    output [PAYLOAD_BITS:0] doutb
    );

reg valid;  



(* ram_style = "distributed" *) reg vld_mem[0:BRAM_DEPTH-1];
initial begin
    $readmemh("./vld_mem_data.dat", vld_mem);
end



always@(posedge clk) begin
    if(reset) begin
        valid <= 0;
    end else begin
        valid <= vld_mem[addrb];
    end
end

always@(posedge clk) begin
    if(wea && web) begin
        if(addra == addrb) begin
            vld_mem[addra] = dina[PAYLOAD_BITS];
        end else begin 
            vld_mem[addra] = dina[PAYLOAD_BITS];
            vld_mem[addrb] = dinb[PAYLOAD_BITS];
        end    
    end else if(wea) begin
        vld_mem[addra] = dina[PAYLOAD_BITS];
    end else if(web) begin
        vld_mem[addrb] = dinb[PAYLOAD_BITS];
    end else begin
        vld_mem[addra] = vld_mem[addra];
    end
end

assign doutb[PAYLOAD_BITS] = valid;

ram0 #(
    .DWIDTH(PAYLOAD_BITS),
    .AWIDTH(NUM_ADDR_BITS),
    .RAM_TYPE(RAM_TYPE)
    )dat_mem(                                                         
    .wrclk(clk),                                                  
    .di(dina[PAYLOAD_BITS-1:0]),                                                      
    .wren(wea),                                                  
    .wraddr(addra),                                                                                                
    .rdclk(clk),
    .rden(1'b1),                                                  
    .rdaddr(addrb),                                              
    .do(doutb[PAYLOAD_BITS-1:0])                                                       
);             



endmodule
