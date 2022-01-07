module ram0#(
    parameter DWIDTH=16,
    parameter AWIDTH=7,
    parameter RAM_TYPE = "block",
    parameter INIT_VALUE = "/home/ylxiao/ws_riscv/picorv32/firmware/firmware.hex"
    )(                                                          
    // Write port                                                     
    input clk,                                                      
    input [DWIDTH-1:0] di,                                                  
    input wren,                                                       
    input [AWIDTH-1:0] wraddr,                                               
    // Read port                                                                                                           
    input rden,                                                       
    input [AWIDTH-1:0] rdaddr,                                               
    output reg [DWIDTH-1:0] do);                                            
             
    localparam BRAM_DEPTH = (1<<AWIDTH);                                                         
    
    (* ram_style = RAM_TYPE *) (* cascade_height = 1 *) reg [DWIDTH-1:0] ram[0:BRAM_DEPTH-1];                 

	initial begin
      $readmemh(INIT_VALUE, ram);
    end
                                                           
                                                                      
    always @ (posedge clk) begin                                    
        if(wren == 1) begin                                           
            ram[wraddr] <= di;                                        
        end                                                           
    end                                                               
                                                                      
    always @ (posedge clk) begin                                    
        if(rden == 1) begin                                           
            do <= ram[rdaddr];                                        
        end                                                           
    end                                                               
                                                                      
endmodule          
