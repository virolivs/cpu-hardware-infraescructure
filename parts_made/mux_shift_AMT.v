module mux_shift_AMT (
  input                     selector,
  input     wire    [31:0]   data_0,
  input     wire    [4:0]   data_1,
  output    reg    [4:0]   data_out
);

    always @(*) begin
        case (selector)
            5'b00000: data_out = data_0;
            5'b00001: data_out = data_1;
        endcase
    end

endmodule