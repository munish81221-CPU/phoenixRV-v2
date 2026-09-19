module phx_control_integration (

    input  logic [31:0] instruction,
    input  logic        branch_taken,

    output logic        reg_write,
    output logic        alu_src_a,
    output logic        alu_src,
    output logic        mem_read,
    output logic        mem_write,
    output logic [1:0]  wb_select,

    output logic [3:0]  alu_control,

    output logic [1:0]  pc_select,
    output logic        branch,
    output logic        jump,
    output logic        jump_reg

);

    // Internal control signals
   
    logic main_reg_write;
    logic main_alu_src_a;
    logic main_alu_src;
    logic main_mem_read;
    logic main_mem_write;
    logic [1:0] main_wb_select;

    logic main_branch;
    logic main_jump;
    logic main_jump_reg;

    
    // Main Control
   
    phx_control_main u_main_control (

        .instruction (instruction),
        .reg_write   (main_reg_write),
        .alu_src_a   (main_alu_src_a),
        .alu_src     (main_alu_src),
        .mem_read    (main_mem_read),
        .mem_write   (main_mem_write),
        .wb_select   (main_wb_select),
        .branch      (main_branch),
        .jump        (main_jump),
        .jump_reg    (main_jump_reg)

    );

    // ALU Decoder
   
    phx_control_alu_decoder u_alu_decoder (

        .instruction (instruction),
        .alu_control (alu_control)

    );

    // PC Select
   
    phx_control_pc_select u_pc_select (

        .branch       (main_branch),
        .branch_taken (branch_taken),
        .jump         (main_jump),
        .jump_reg     (main_jump_reg),
        .pc_select    (pc_select)

    );

    // Control Signal Connections
    assign reg_write = main_reg_write;
    assign alu_src_a = main_alu_src_a;
    assign alu_src   = main_alu_src;
    assign mem_read  = main_mem_read;
    assign mem_write = main_mem_write;
    assign wb_select = main_wb_select;

    assign branch    = main_branch;
    assign jump      = main_jump;
    assign jump_reg  = main_jump_reg;


endmodule