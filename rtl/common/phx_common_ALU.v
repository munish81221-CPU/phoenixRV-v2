module phx_common_ALU #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] operand_a,
    input  wire [WIDTH-1:0] operand_b,
    input  wire [3:0]       alu_control,
    output reg  [WIDTH-1:0] alu_result
);

always@(*)
begin
    case(alu_control)
    //basic alu operantions 
        4'b0000: alu_result = operand_a + operand_b; //ADD
        4'b0001: alu_result = operand_a - operand_b; //SUB
        4'b0010: alu_result = operand_a & operand_b; //AND
        4'b0011: alu_result = operand_a | operand_b; //OR
        4'b0100: alu_result = operand_a ^ operand_b; //XOR

//shift operantions 
        4'b0101: alu_result = operand_a << operand_b[4:0]; //SLL
        4'b0110: alu_result = operand_a >> operand_b[4:0]; //SRL
        4'b0111: alu_result = $signed(operand_a) >>> operand_b[4:0]; //SRA
        
//comparison operantions    
        4'b1000: alu_result = ($signed(operand_a) < $signed(operand_b)) ? {{(WIDTH-1){1'b0}},1'b1} : {WIDTH{1'b0}}; // SLT
        4'b1001: alu_result = (operand_a < operand_b) ? {{(WIDTH-1){1'b0}},1'b1} : {WIDTH{1'b0}}; // SLTU
//default 
       default: alu_result = {WIDTH{1'b0}};
    endcase
end

endmodule 