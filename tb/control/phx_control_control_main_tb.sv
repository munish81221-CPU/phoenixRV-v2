`timescale 1ns/1ps
module phx_control_main_tb;
      

     logic        reg_write;
     logic        alu_src_a;
     logic        alu_src;
     logic        mem_read;
     logic        mem_write;
     logic [1:0]  wb_select;
     logic        branch;
     logic        jump;
     logic        jump_reg;
     logic [31:0] instruction;

phx_control_main uut(
.reg_write(reg_write),
.alu_src_a(alu_src_a),
.alu_src(alu_src),
.mem_read(mem_read),
.mem_write(mem_write),
.wb_select(wb_select),
.branch(branch),
.jump(jump),
.jump_reg(jump_reg),
.instruction(instruction)
);

typedef struct packed{

    logic            reg_write;
    logic            alu_src_a;
    logic            alu_src;
    logic            mem_read;
    logic            mem_write;
    logic     [1:0]  wb_select;
    logic            branch;
    logic            jump;
    logic            jump_reg;
     
} control_t;

control_t expected;
control_t actual;
logic [6:0] test_opcodes [0:9];



function automatic control_t expected_control(input logic [6:0] opcode);
    
    control_t result;

    result = '0;

    case (opcode)

        7'b0110011: begin
            result.reg_write = 1'b1;
            result.wb_select = 2'b00;
        end

        7'b0010011: begin
            result.reg_write = 1'b1;
            result.alu_src   = 1'b1;
            result.wb_select = 2'b00;
        end

        7'b0000011: begin
            result.reg_write = 1'b1;
            result.alu_src   = 1'b1;
            result.mem_read  = 1'b1;
            result.wb_select = 2'b01;
        end

        7'b0100011: begin
            result.alu_src   = 1'b1;
            result.mem_write = 1'b1;
        end

        7'b1100011: begin
            result.branch = 1'b1;
        end

        7'b0110111: begin
            result.reg_write = 1'b1;
            result.wb_select = 2'b11;
        end

        7'b0010111: begin
            result.reg_write = 1'b1;
            result.alu_src_a = 1'b1;
            result.alu_src   = 1'b1;
            result.wb_select = 2'b00;
        end

        7'b1101111: begin
            result.reg_write = 1'b1;
            result.wb_select = 2'b10;
            result.jump      = 1'b1;
        end

        7'b1100111: begin
            result.reg_write = 1'b1;
            result.alu_src   = 1'b1;
            result.wb_select = 2'b10;
            result.jump      = 1'b1;
            result.jump_reg  = 1'b1;
        end

        default: begin
            result = '0;
        end

    endcase

    return result;

endfunction

assign actual = {
        reg_write,
        alu_src_a,
        alu_src,
        mem_read,
        mem_write,
        wb_select,
        branch,
        jump,
        jump_reg
    };





integer i;

initial begin

    test_opcodes[0] = 7'b0110011;  // R-type
    test_opcodes[1] = 7'b0010011;  // I-type ALU
    test_opcodes[2] = 7'b0000011;  // LW
    test_opcodes[3] = 7'b0100011;  // SW
    test_opcodes[4] = 7'b1100011;  // Branch
    test_opcodes[5] = 7'b0110111;  // LUI
    test_opcodes[6] = 7'b0010111;  // AUIPC
    test_opcodes[7] = 7'b1101111;  // JAL
    test_opcodes[8] = 7'b1100111;  // JALR
    test_opcodes[9] = 7'b1111111;  // Unsupported

    for (i = 0; i < 10; i++) begin

        instruction = {25'b0, test_opcodes[i]};

        expected = expected_control(instruction[6:0]);

        #1;

        assert (actual == expected)
             $display(
            "PASS: opcode=%07b control=%010b",
            instruction[6:0],
            actual
        );
        else
             $error(
            "FAIL: opcode=%07b actual=%010b expected=%010b",
            instruction[6:0],
            actual,
            expected
        );

    end

   



    
$finish;
end
endmodule

    