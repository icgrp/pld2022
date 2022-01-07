module instr_config(
  input clk_bft,
  input clk_user,
  input instr_wr_en_in,
  input [31:0] instr_packet,
  output [23:0] addr,
  output [7:0] dout,
  output reg instr_wr_en_out,
  input reset_bft,
  input reset
  );


  wire rd_en;
  wire empty;
  
  always@(posedge clk_user) begin
    if(reset) begin
        instr_wr_en_out <= 0;
    end else begin
        instr_wr_en_out <= ~empty;
    end
  end
  
  assign rd_en = ~empty;
  
  xpm_fifo_async # (

  .FIFO_MEMORY_TYPE          ("block"),           //string; "auto", "block", or "distributed";
  .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
  .RELATED_CLOCKS            (0),                //positive integer; 0 or 1
  .FIFO_WRITE_DEPTH          (128),             //positive integer
  .WRITE_DATA_WIDTH          (32),               //positive integer
  .WR_DATA_COUNT_WIDTH       (7),               //positive integer
  .PROG_FULL_THRESH          (10),               //positive integer
  .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
  .READ_MODE                 ("std"),            //string; "std" or "fwft";
  .FIFO_READ_LATENCY         (1),                //positive integer;
  .READ_DATA_WIDTH           (32),               //positive integer
  .RD_DATA_COUNT_WIDTH       (7),               //positive integer
  .PROG_EMPTY_THRESH         (10),               //positive integer
  .DOUT_RESET_VALUE          ("0"),              //string
  .CDC_SYNC_STAGES           (2),                //positive integer
  .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;

) xpm_fifo_async_inst (

  .rst              (reset),
  .wr_clk           (clk_bft),
  .wr_en            (instr_wr_en_in),
  .din              (instr_packet),
  .full             (full),
  .overflow         (overflow),
  .wr_rst_busy      (wr_rst_busy),
  .rd_clk           (clk_user),
  .rd_en            (rd_en),
  .dout             ({addr, dout}),
  .empty            (empty),
  .underflow        (underflow),
  .rd_rst_busy      (rd_rst_busy),
  .prog_full        (prog_full),
  .wr_data_count    (wr_data_count),
  .prog_empty       (prog_empty),
  .rd_data_count    (rd_data_count),
  .sleep            (1'b0),
  .injectsbiterr    (1'b0),
  .injectdbiterr    (1'b0),
  .sbiterr          (),
  .dbiterr          ()

);



endmodule
