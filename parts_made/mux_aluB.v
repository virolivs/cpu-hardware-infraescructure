module mux_aluB (
    input  wire [1:0]  selector,
    input  wire [31:0] data_0, //b_out
    input  wire [31:0] data_1, //sign extend 16
    input  wire [31:0] data_2, //shift left 2 branch
    output reg [31:0] data_out
);

    always @(*) begin
        case (selector)
            2'b00: data_out = data_0;
            2'b01: data_out = 32'b00000000000000000000000000000100;
            2'b10: data_out = data_1;
            2'b11: data_out = data_2;
        endcase
    end     

endmodule
