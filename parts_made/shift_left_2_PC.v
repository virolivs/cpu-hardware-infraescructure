module shift_left_2_PC (
    input wire [25:0] data_0, // entrada são os 26 bits da instrução
    output wire [27:0] data_out // saida para pc source
);
    assign data_out =  {data_0, {2{1'b0}}}; //concatena in com 0 extendido para 2 bits

endmodule