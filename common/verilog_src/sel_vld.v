`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2020 04:06:19 PM
// Design Name: 
// Module Name: sel_vld
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


module sel_vld(
    input [48:0] in_port,
    output vld_out

    );
    
    assign vld_out = in_port[48];
endmodule
