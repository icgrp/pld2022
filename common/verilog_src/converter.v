`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2018 03:44:20 PM
// Design Name: 
// Module Name: dma_converter
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


module dma_converter(
    input clk,
    input reset,
    
    output last,
    output reg [3:0] keep,
    
    input [31:0] dout,
    input valid,
    input ready,
    
    output reg [31:0] OutCnt

    );

    always@(posedge clk/* or negedge reset*/) begin
        if(reset)
            OutCnt <= 0;
        else begin
            if(valid && ready) begin
                if(OutCnt)
                    OutCnt <= OutCnt - 1;
                else
                    OutCnt <= dout - 1;
            end else begin
                OutCnt <= OutCnt;
            end
        end
    end
    
    /*always@(*) begin
        if(OutCnt == 0)
            last = 1;
        else
            last = 0;
    end*/
    assign last = (!OutCnt)? ((valid && ready)? 0 : 1) : ((OutCnt == 1)? 1 : 0);
    
    always@(posedge clk/* or negedge reset*/) begin
        if(reset)
            keep <= 0;
        else
            keep <= 4'b1111;
    end
endmodule
