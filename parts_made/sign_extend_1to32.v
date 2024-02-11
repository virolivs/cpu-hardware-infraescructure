module sign_extend_1to32(
    input wire data_in, // entrada de um bit vindo da flag lt
    output wire [31:0] data_out // saida para o mux men to reg
);

    assign data_out =  {{31{1'b0}}, data_in}; 

endmodule