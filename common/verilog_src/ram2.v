module ram2#(
    parameter DWIDTH=16,
    parameter AWIDTH=7,
    parameter RAM_TYPE = "block",
    parameter INIT_VALUE = "/home/ylxiao/ws_riscv/picorv32/firmware/firmware.hex"
    )(                                                          
    // Write port                                                     
    input clk,                                                      
    input [DWIDTH-1:0] dia,                                                  
    input [DWIDTH-1:0] dib,                                                  
    input wrena,                                                       
    input wrenb,                                                       
    input [AWIDTH-1:0] wraddra,                                               
    input [AWIDTH-1:0] wraddrb,                                               
    // Read port                                                                                                           
    input rdena,                                                       
    input rdenb,                                                       
    input [AWIDTH-1:0] rdaddra,                                               
    input [AWIDTH-1:0] rdaddrb,                                               
    output reg [DWIDTH-1:0] doa,                                          
    output reg [DWIDTH-1:0] dob);                                            
             
    localparam BRAM_DEPTH = (1<<AWIDTH);                                                         
    
    (* ram_style = RAM_TYPE *) (* cascade_height = 1 *) reg [DWIDTH-1:0] ram[0:BRAM_DEPTH-1];                 

	//initial begin
    //  $readmemh(INIT_VALUE, ram);
    //end
                                                           
                                                                      
    always @ (posedge clk) begin                                    
        if(wrena == 1) begin                                           
            ram[wraddra] <= dia;                                        
        end                                                           
    end                                                               

    always @ (posedge clk) begin                                    
        if(wrenb == 1) begin                                           
            ram[wraddrb] <= dib;                                        
        end                                                           
    end     
                                                                          
    always @ (posedge clk) begin                                    
        if(rdena == 1) begin                                           
            doa <= ram[rdaddra];                                        
        end                                                           
    end    
    
    always @ (posedge clk) begin                                    
        if(rdenb == 1) begin                                           
            dob <= ram[rdaddrb];                                        
        end                                                           
    end                                                           
                                                                      
endmodule          
