module shift_left_2(
    input   wire    [31:0]  data_0, // entrada 
    output  wire    [31:0]  data_out // saida 
);

    assign data_out = data_0 << 2; // desloca a entrada dois bits para a esquerda

endmodule