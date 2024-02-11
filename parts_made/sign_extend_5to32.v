module sign_extend_5to32(
    input wire [0:4] data_in, // entrada de um bit vindo da flag lt
    output wire [31:0] data_out // saida para o mux men to reg
);

    assign data_out =  {{27{1'b0}}, data_in}; 

endmodule
