module mux_MEM_to_REG (
    input   wire    [3:0]   selector,
    input   wire    [31:0]   data_0,
    input   wire    [31:0]   data_1,
    input   wire    [31:0]   data_2,
    input   wire    [31:0]   data_3,
    input   wire    [31:0]   data_4,
    input   wire    [31:0]   data_5,
    input   wire    [31:0]   data_6,
    input   wire    [31:0]   data_7,
    input   wire    [31:0]   data_8,
    output  reg     [31:0]   data_out
);

always @(*) begin
    case (selector)
        1'b0000: data_out = data_0;
        1'b0001: data_out = data_1;
        1'b0010: data_out = data_2;
        1'b0011: data_out = data_1;
        1'b0100: data_out = data_4;
        1'b0101: data_out = data_5;
        1'b0110: data_out = data_6;
        1'b0111: data_out = data_7;
        1'b1000: data_out = data_8;
        default: data_out = 32'b00000000000000000000000011100011; // 227
    endcase
end

endmodule