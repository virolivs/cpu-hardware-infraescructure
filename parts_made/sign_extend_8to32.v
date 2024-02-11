module sign_extend_8to32(
    input   wire    [7:0]   data_in,
    output  wire    [31:0]  data_out
);

    assign data_out =  {{24{1'b0}}, data_in}; //bit 1 ou 0 repetido 16 vezes concatenado com o data in

endmodule