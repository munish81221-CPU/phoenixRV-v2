module phx_single_cycle_core (
    input logic        clk,
    input logic        reset,
    input logic [31:0] instruction,

    output logic [31:0] current_pc
);

    logic        branch_taken;

    logic        reg_write;
    logic        alu_src_a;
    logic        alu_src;
    logic        mem_read;
    logic        mem_write;
    logic [1:0]  wb_select;
    logic [3:0]  alu_control;
    logic [1:0]  pc_select;
    logic        branch;
    logic        jump;
    logic        jump_reg;

    logic [31:0] alu_result;
    logic [31:0] writeback_data;


    phx_control_integration u_control (
        .instruction  (instruction),
        .branch_taken (branch_taken),

        .reg_write    (reg_write),
        .alu_src_a    (alu_src_a),
        .alu_src      (alu_src),
        .mem_read     (mem_read),
        .mem_write    (mem_write),
        .wb_select    (wb_select),
        .alu_control  (alu_control),
        .pc_select    (pc_select),
        .branch       (branch),
        .jump         (jump),
        .jump_reg     (jump_reg)
    );


    phx_datapath_integration u_datapath (
        .clk          (clk),
        .reset        (reset),
        .instruction  (instruction),

        .reg_write    (reg_write),
        .alu_src_a    (alu_src_a),
        .alu_src      (alu_src),
        .mem_read     (mem_read),
        .mem_write    (mem_write),
        .wb_select    (wb_select),
        .alu_control  (alu_control),
        .pc_select    (pc_select),
        .branch       (branch),
        .jump         (jump),
        .jump_reg     (jump_reg),

        .branch_taken (branch_taken),
        .current_pc   (current_pc),
        .alu_result   (alu_result),
        .writeback_data(writeback_data)
    );

endmodule