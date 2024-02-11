module MULT (
    input                        clk,
    input                        rst,
    input                        control,
    input   wire signed  [31:0]  A,
    input   wire signed  [31:0]  B,
    output  reg signed  [31:0]  Lo,
    output  reg signed  [31:0]  Hi
);

    reg [63:0]  multiplicando;
    reg [31:0]  multiplicador;
    reg signed [63:0]  product;
    reg         [5:0]   counter;
    reg         [5:0]   repetitions;

    reg sign;

    always @(posedge clk) begin
        if (rst) begin
            multiplicando   = 64'b0;
            multiplicador   = 32'b0;
            product         = 64'b0;
            repetitions     = 6'b0;
            counter         = 6'b0;
            Lo              = 32'b0;
            Hi              = 32'b0;
            sign = 1'b0;
        end
        
        if (!rst && control) begin
            if (repetitions < 32) begin
                if (counter == 6'b000000) begin
                    if (A[31]) begin
                        multiplicando[31:0] = ~A + 1'b1;
                    end
                    else begin
                        multiplicando[31:0] = A;
                    end

                    if (B[31]) begin
                        multiplicador = ~B + 1'b1;
                    end
                    else begin
                        multiplicador = B;
                    end

                    if (A[31] ^ B[31]) begin
                        sign = 1'b1;
                    end

                    counter = counter + 1;
                end

                if (counter == 6'b000001) begin
                    if (multiplicador[0] == 1'b1) begin
                        product = product + multiplicando;
                    end
                    counter = counter + 1;
                end
                
                if (counter == 6'b000010) begin
                    multiplicando = multiplicando << 1'b1;
                    counter = counter + 1;
                end

                if (counter == 6'b000011) begin
                    multiplicador = multiplicador >> 1'b1;
                    counter = counter + 1;
                end

                if (counter == 6'b000100) begin
                    counter = 6'b000001;
                    repetitions = repetitions + 1;
                end
            end

            if (repetitions >= 32) begin
                if (sign) begin
                    product = ~product + 1'b1;
                end
            end

            Hi = product[31:0];
            Lo = product[63:32];
        end
    end

endmodule
