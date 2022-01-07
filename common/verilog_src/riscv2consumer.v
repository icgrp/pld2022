module riscv2consumer#(
  parameter DATA_WIDTH = 32
  )(
  input clk,
  input reset,
  input [DATA_WIDTH-1:0] din,
  input val_in,
  output reg ready_upward,
  output reg [DATA_WIDTH-1:0] dout,
  output reg val_out,
  input ready_downward
  );

  parameter TR = 1'b0; //transparent
  parameter RE = 1'b1; //resend

  reg state, next_state;
  reg [DATA_WIDTH-1:0] dtmp;

  always@(posedge clk) begin
    if(reset) state <= TR;
    else state <= next_state;
  end


  always@(*) begin
    case(state)
      TR: begin
        if(val_in == 0) begin
          next_state = TR;
        end else if (ready_downward == 1) begin
          next_state = TR;
        end else begin
          next_state = RE;
        end
      end

      RE: begin
        if(ready_downward == 1) begin
          next_state = TR;
        end else begin
          next_state = RE;
        end
      end
    endcase
  end

  always@(posedge clk) begin
    if(reset) begin
      dtmp <= 0;
    end else if(state == TR) begin
      dtmp <= din;
    end else begin
      dtmp <= dtmp;
    end
  end

   always@(*) begin
    case(state)
      TR: begin
        ready_upward = ready_downward;
        val_out = val_in;
        dout = din;
      end

      RE: begin
        ready_upward = 0;
        val_out = 1;
        dout = dtmp;
      end
    endcase
  end

 

endmodule
