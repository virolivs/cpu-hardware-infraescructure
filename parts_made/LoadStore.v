module LoadStore (
    input   wire              clk,
    input   wire              reset,
    input   wire    [2:0]     control,
    input   wire    [31:0]    MDR,
    input   wire    [31:0]    B,
    output  reg    [31:0]    out
);

always @(posedge clk) begin
    if (reset) begin
        out = 32'b0;
    end
    else begin
        if (control) begin
            case (control)
                3'b001: begin       // lw
                    out = MDR;
                end
                3'b010: begin       // lh
                    out = {16'b0, MDR[15:0]};
                end
                3'b011: begin       // lb
                    out = {24'b0, MDR[7:0]};
                end
                3'b100: begin       // sw
                    out = B;
                end
                3'b101: begin       // sh
                    out = {MDR[31:16], B[15:0]};
                end
                3'b110: begin       // sb
                    out = {MDR[31:8], B[7:0]};
                end
            endcase
        end
        else begin
            out = MDR;
        end
    end
end
endmodule