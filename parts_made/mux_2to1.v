module mux_2to1 (
  input                     selector,
  input     wire    [31:0]  data_0,
  input     wire    [31:0]  data_1,
  output    reg     [31:0]  data_out
);

    always @(*) begin
        case (selector)
            1'b0: data_out = data_0;
            1'b1: data_out = data_1;
        endcase
    end

endmodule