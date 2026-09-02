module phx_common_alu_operand_mux(
    input [31:0] register_operand,
    input [31:0] immediate,
    input select_immediate,

    output reg [31:0] alu_operand_b
);

always @(*) begin
    if (select_immediate)
        alu_operand_b = immediate;
    else
        alu_operand_b = register_operand;
end

endmodule