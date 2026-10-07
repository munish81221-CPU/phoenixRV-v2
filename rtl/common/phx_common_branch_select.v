module phx_common_branch_select(
    input  [31:0] operand_a,
    input  [31:0] operand_b,
    input  [2:0]  branch_select,
    output reg    branch_taken
);

always @(*) begin

    branch_taken = 1'b0;

    case (branch_select)

        // BEQ
        3'b000:
            branch_taken = (operand_a == operand_b);

        // BNE
        3'b001:
            branch_taken = (operand_a != operand_b);

        // BLT - signed
        3'b100:
            branch_taken = ($signed(operand_a) < $signed(operand_b));

        // BGE - signed
        3'b101:
            branch_taken = ($signed(operand_a) >= $signed(operand_b));

        // BLTU - unsigned
        3'b110:
            branch_taken = (operand_a < operand_b);

        // BGEU - unsigned
        3'b111:
            branch_taken = (operand_a >= operand_b);

        default:
            branch_taken = 1'b0;

    endcase

end

endmodule