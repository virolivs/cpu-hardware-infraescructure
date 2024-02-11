module sign_extend_16to32(
    input wire  [15:0] data_in,
    output wire [31:0] data_out
);
assign data_out = (data_in[15]) ? {{16{1'b1}}, data_in} : {{16{1'b0}}, data_in}; //bit 1 ou 0 repetido 16 vezes concatenado com o data in

endmodule