module DIV (
    input   wire              clk,
    input   wire              reset,
    input   wire              control,
    input   wire    [31:0]    A,    // dividend
    input   wire    [31:0]    B,    // divisor
    output  reg    [31:0]    Hi,   // quotient
    output  reg    [31:0]    Lo,   // remainder
    output  reg	      div_0
);

    reg     [31:0]  dividend;
    reg     [63:0]  divisor;    
    reg     [31:0]  quotient;   // lo
    reg     [63:0]  remainder;  // hi
    reg                     reg_div_0;


    reg [5:0] counter;
    reg [31:0] bits_processed;
    reg sign;
    reg sign_dividend;
    reg div_end;

    always @(posedge clk) begin
        if (reset) begin
            dividend  = 1'b0;
            divisor   = 1'b0;
            quotient  = 1'b0;
            remainder = 1'b0;
            reg_div_0 = 1'b0;
            div_0 = 1'b0;
            bits_processed = 0;
            counter = 6'b000000;
            sign_dividend = 1'b0;
            Hi = 32'b0;
            Lo = 32'b0;
        end

        if (!reset && control) begin
            if (B == 32'b0 && bits_processed == 1'b0) begin
                reg_div_0 <= 1'b1;
            end

            if (!reg_div_0 && bits_processed < 33) begin

                if (counter == 6'b000000) begin
                    if (A[31]) begin
                        dividend = ~A + 1'b1;    
                        sign_dividend = 1'b1;
                    end
                    else begin
                        dividend = A;
                        sign_dividend = 1'b1;
                    end

                    if (B[31]) begin
                        divisor[63:32] = ~B + 1'b1;
                    end
                    else begin
                        divisor[63:32] = B;
                    end

                    counter = counter + 1;
                    
                    if (A[31] ^ B[31]) begin
                        sign = 1'b1;
                    end

                end
                
                if (counter == 6'b000001) begin
                    remainder[31:0] = dividend;
                    counter = counter + 1;
                end

                if (counter == 6'b000010) begin
                    remainder = remainder - divisor;
                    counter = counter + 1;
                end
                
                if (counter == 6'b000011) begin
                    if (remainder[63] == 1'b0) begin        // positivo
                        quotient = quotient << 1'b1;
                        quotient[0] = 1'b1;
                    end
                    else begin
                        remainder = remainder + divisor;
                        quotient = quotient << 1'b1;
                        quotient[0] = 1'b0;
                    end
                    counter = counter + 1;
                end
                
                if (counter == 6'b000100) begin
                    divisor = divisor >> 1'b1;
                    counter = counter + 1;
                end
                
                if (counter == 6'b000101) begin
                    counter = 2'b10;
                    bits_processed = bits_processed + 1;
                end
            end

            if (bits_processed >= 33) begin
                if (sign) begin
                    quotient = ~quotient + 1'b1;
                end

                if (sign_dividend) begin
                    remainder = ~remainder + 1'b1;
                end
                bits_processed = 32'b0;
            end

            Lo = quotient;
            Hi = remainder[31:0];
            div_0 = reg_div_0;
        end
    end
endmodule