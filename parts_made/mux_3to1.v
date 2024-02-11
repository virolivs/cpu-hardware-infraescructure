module mux_3to1 (
  input         [1:0]   selector,
  output reg    [31:0]  data_out
);

    always @(*) begin
        case (selector)
            1'b0: data_out = 32'b000000000000000011111101;
            1'b1: data_out = 32'b000000000000000011111110;
            default: data_out = 32'b000000000000000011111111;
        endcase
    end

endmodule