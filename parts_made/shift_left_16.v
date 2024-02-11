module shift_left_16(
    input   wire    [15:0]  data_0, // A entrada são os 16 bits da instrução
    output  wire    [31:0]  data_out // a saída vai pro mux men to reg entrada 5
);

    assign data_out = {data_0, {16{1'b0}}}; // concatena a entrada de 16 bits mais 16 bits para ficar com 32

endmodule