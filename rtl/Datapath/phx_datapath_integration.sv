module phx_datapath_integration #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input logic clk,
    input logic reset,

    // Instruction
    input logic [31:0] instruction,

    // Control signals
    input logic        reg_write,
    input logic        alu_src_a,
    input logic        alu_src,
    input logic        mem_read,
    input logic        mem_write,
    input logic [1:0]  wb_select,
    input logic [3:0]  alu_control,

    input logic [1:0]  pc_select,

    input logic        branch,
    input logic        jump,
    input logic        jump_reg,

    // Datapath result
    output logic        branch_taken,
    output logic [31:0] current_pc,
    output logic [31:0] alu_result,
    output logic [31:0] writeback_data
);

logic [31:0] read_data1;
logic [31:0] read_data2;

logic [31:0] immediate;

logic [2:0] imm_type;

logic [31:0] operand_a;
logic [31:0] operand_b;

logic [31:0] memory_data;

logic [31:0] pc_plus_4;
logic [31:0] branch_target;
logic [31:0] jump_target;
logic [31:0] jalr_target;
logic [31:0] next_pc;

logic [31:0] writeback_data_internal;

logic [2:0] branch_select;

logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;

assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd  = instruction[11:7];

logic [6:0] opcode;

assign opcode = instruction[6:0];



always_comb begin
    imm_type = 3'b000;

    case (opcode)

        // I-type
        7'b0010011,
        7'b0000011,
        7'b1100111:
            imm_type = 3'b000;

        // S-type
        7'b0100011:
            imm_type = 3'b001;

        // B-type
        7'b1100011:
            imm_type = 3'b010;

        // U-type
        7'b0110111,
        7'b0010111:
            imm_type = 3'b011;

        // J-type
        7'b1101111:
            imm_type = 3'b100;

        default:
            imm_type = 3'b000;

    endcase
end


phx_common_imm_gen u_imm_gen (
    .instruction(instruction),
    .imm_type(imm_type),
    .immediate(immediate)
);


register_file #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_register_file (
    .clk(clk),
    .reset(reset),

    .write_enable(reg_write),

    .write_address(rd),
    .write_data(writeback_data),

    .read_address1(rs1),
    .read_address2(rs2),

    .read_data1(read_data1),
    .read_data2(read_data2)
);


phx_datapath_operand_a_mux #(
    .WIDTH(DATA_WIDTH)
) u_operand_a_mux (
    .read_data1(read_data1),
    .pc(current_pc),
    .alu_src_a(alu_src_a),
    .operand_a(operand_a)
);


phx_common_alu_operand_mux u_operand_b_mux (
    .register_operand(read_data2),
    .immediate(immediate),
    .select_immediate(alu_src),
    .alu_operand_b(operand_b)
);


phx_common_ALU #(
    .WIDTH(DATA_WIDTH)
) u_alu (
    .operand_a(operand_a),
    .operand_b(operand_b),
    .alu_control(alu_control),
    .alu_result(alu_result)
);


phx_common_data_memory #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(DATA_WIDTH),
    .DEPTH(256)
) u_data_memory (
    .clk(clk),
    .reset(reset),

    .mem_read(mem_read),
    .mem_write(mem_write),

    .address(alu_result),
    .write_data(read_data2),

    .read_data(memory_data)
);



phx_common_writeback_mux u_writeback_mux (
    .alu_result(alu_result),
    .memory_data(memory_data),
    .pc_plus_4(pc_plus_4),
    .immediate(immediate),

    .writeback_select(wb_select),

    .writeback_data(writeback_data)
);



phx_common_adder #(
    .WIDTH(DATA_WIDTH)
) u_pc_incrementer (
    .add_in0(current_pc),
    .add_in1(32'd4),
    .cin(1'b0),
    .sum(pc_plus_4),
    .cout()
);


phx_datapath_pc_target_adder #(
    .WIDTH(DATA_WIDTH)
) u_pc_target (
    .pc(current_pc),
    .immediate(immediate),
    .target(branch_target)
);


assign jalr_target = {alu_result[31:1], 1'b0};




logic branch_condition;


   assign branch_select = instruction[14:12];


phx_common_branch_select u_branch_select (
    .operand_a(read_data1),
    .operand_b(read_data2),
    .branch_select(branch_select),
    .branch_taken(branch_condition)
);

assign branch_taken = branch && branch_condition;

phx_common_next_pc_mux u_next_pc_mux (
    .pc_plus_4(pc_plus_4),
    .branch_target(branch_target),
    .jump_target(branch_target),
    .alternate_target(jalr_target),

    .select(pc_select),

    .next_pc(next_pc)
);


phx_common_pc_register u_pc_register (
    .clk(clk),
    .reset(reset),
    .next_pc(next_pc),
    .current_pc(current_pc)
);


endmodule 