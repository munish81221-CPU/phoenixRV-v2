`timescale 1ns/1ps

module phx_single_cycle_core_tb;
    // Clock and Reset
    logic clk;
    logic reset;
    // Instruction Interface
    logic [31:0] instruction;
    logic [31:0] current_pc;






    // Temporary Instruction Memory
    localparam int PROGRAM_DEPTH = 500;

    logic [31:0] program_memory [0:PROGRAM_DEPTH-1];

    
    // RISC-V Instruction Encoders
    function automatic [31:0] encode_i_type;
        input [11:0] imm;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [4:0]  rd;
        input [6:0]  opcode;

        begin
            encode_i_type = {
                imm,
                rs1,
                funct3,
                rd,
                opcode
            };
        end
    endfunction


    function automatic [31:0] encode_r_type;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;

        begin
            encode_r_type = {
                funct7,
                rs2,
                rs1,
                funct3,
                rd,
                opcode
            };
        end
    endfunction


    // Encode an S-type instruction, such as SW.
function automatic [31:0] encode_s_type;
    input [11:0] imm;
    input [4:0]  rs2;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [6:0]  opcode;

    begin
        encode_s_type = {
            imm[11:5],
            rs2,
            rs1,
            funct3,
            imm[4:0],
            opcode
        };
    end
endfunction


// Encode a B-type instruction, such as BEQ or BLT.
function automatic [31:0] encode_b_type;
    input [12:0] imm;
    input [4:0]  rs2;
    input [4:0]  rs1;
    input [2:0]  funct3;
    input [6:0]  opcode;

    begin
        encode_b_type = {
            imm[12],
            imm[10:5],
            rs2,
            rs1,
            funct3,
            imm[4:1],
            imm[11],
            opcode
        };
    end
endfunction




function automatic [31:0] encode_j_type;
    input [20:0] imm;
    input [4:0]  rd;
    input [6:0]  opcode;

    begin
        encode_j_type = {
            imm[20],
            imm[10:1],
            imm[11],
            imm[19:12],
            rd,
            opcode
        };
    end
endfunction

//u type encoder 
function automatic [31:0] encode_u_type;
    input [19:0] imm;
    input [4:0]  rd;
    input [6:0]  opcode;

    begin
        encode_u_type = {imm, rd, opcode};
    end
endfunction




    
    // DUT
    phx_single_cycle_core dut (
        .clk         (clk),
        .reset       (reset),
        .instruction (instruction),
        .current_pc  (current_pc)
    );


integer checks_passed;
integer checks_failed;
integer instructions_executed;

    // Clock
    always #5 clk = ~clk;

    // Temporary Instruction Memory
    assign instruction = program_memory[current_pc[10:2]];

    localparam logic [6:0] OPCODE_R_TYPE = 7'b0110011;
    localparam logic [6:0] OPCODE_I_TYPE = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD  = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JAL  = 7'b1101111;
    localparam logic [6:0] OPCODE_JALR = 7'b1100111;
    localparam logic [6:0] OPCODE_LUI   = 7'b0110111;
    localparam logic [6:0] OPCODE_AUIPC = 7'b0010111;



    localparam logic [2:0] FUNCT3_ADD_SUB = 3'b000;

    localparam logic [6:0] FUNCT7_ADD = 7'b0000000;
    localparam logic [6:0] FUNCT7_SUB = 7'b0100000;


//  Constrained-Random Verification Variables


integer rand_seed;
integer initial_rand_seed;
integer rand_value;
integer rand_op;
integer rand_rd;
integer rand_rs1;
integer rand_rs2;
integer rand_i;

reg [6:0]  rand_funct7;
reg [2:0]  rand_funct3;

reg [31:0] rand_a;
reg [31:0] rand_b;
reg [31:0] rand_result;

// Independent reference-model register state
reg [31:0] model_regs [0:31];

// Expected results for the randomized instruction stream
reg [31:0] random_expected [0:39];
reg [4:0]  random_dest [0:39];








task automatic check_register;
    input integer register_number;
    input logic [31:0] expected_value;

    logic [31:0] actual_value;

    begin
        actual_value =
            dut.u_datapath.u_register_file.registers[register_number];

        if (actual_value !== expected_value) begin
            checks_failed = checks_failed + 1;

            $display(
                "[FAIL] Register x%0d | Expected: %08h | Actual: %08h",
                register_number,
                expected_value,
                actual_value
            );
        end
        else begin
            checks_passed = checks_passed + 1;
        end
    end
endtask

task automatic check_pc;
    input logic [31:0] expected_pc;

    begin
        if (current_pc !== expected_pc) begin
            checks_failed = checks_failed + 1;

            $display(
                "[FAIL] PC | Expected: %08h | Actual: %08h",
                expected_pc,
                current_pc
            );
        end
        else begin
            checks_passed = checks_passed + 1;
        end
    end
endtask



task automatic check_memory;
    input integer word_index;
    input logic [31:0] expected_value;

    logic [31:0] actual_value;

    begin
        actual_value =
            dut.u_datapath.u_data_memory.memory[word_index];

        if (actual_value !== expected_value) begin
            checks_failed = checks_failed + 1;

            $display(
                "[FAIL] Memory word %0d | Expected: %08h | Actual: %08h",
                word_index,
                expected_value,
                actual_value
            );
        end
        else begin
            checks_passed = checks_passed + 1;
        end
    end
endtask



integer i;

integer alu_op_coverage [0:9];
integer coverage_i;
integer opcode_coverage [0:127];
integer load_funct3_coverage [0:7];
integer store_funct3_coverage [0:7];
integer opcode_cov_i;
integer opcode_coverage_total;




// ============================================================
// CORE-002A: Executed Instruction Opcode Coverage Monitor
// ============================================================

always @(posedge clk) begin

    // Count only when reset is definitely inactive.
    // Ignore unknown instruction values.

    if ((reset === 1'b0) &&
        ((^instruction) !== 1'bx)) begin

        opcode_coverage[instruction[6:0]] =
            opcode_coverage[instruction[6:0]] + 1;

        // Major-opcode coverage cannot distinguish memory sub-operations.
        if (instruction[6:0] == OPCODE_LOAD)
            load_funct3_coverage[instruction[14:12]] =
                load_funct3_coverage[instruction[14:12]] + 1;
        else if (instruction[6:0] == OPCODE_STORE)
            store_funct3_coverage[instruction[14:12]] =
                store_funct3_coverage[instruction[14:12]] + 1;

    end

end



initial begin

        checks_passed = 0;
        checks_failed = 0;
        instructions_executed = 0;

    for (opcode_cov_i = 0;
         opcode_cov_i < 128;
         opcode_cov_i = opcode_cov_i + 1) begin

        opcode_coverage[opcode_cov_i] = 0;

    end

    for (opcode_cov_i = 0; opcode_cov_i < 8; opcode_cov_i = opcode_cov_i + 1) begin
        load_funct3_coverage[opcode_cov_i] = 0;
        store_funct3_coverage[opcode_cov_i] = 0;
    end

    opcode_coverage_total = 0;
        $dumpfile("phx_single_cycle_core.vcd");
        $dumpvars(0, phx_single_cycle_core_tb);


        for (i = 0; i < PROGRAM_DEPTH; i = i + 1)
         program_memory[i] = 32'h00000013;
        
        program_memory[0] = encode_i_type(
            12'd10,
            5'd0,
            3'b000,
            5'd1,
            OPCODE_I_TYPE
        );

        program_memory[1] = encode_i_type(
            12'd20,
            5'd0,
            3'b000,
            5'd2,
            OPCODE_I_TYPE
        );

        program_memory[2] = encode_r_type(
            FUNCT7_ADD,
            5'd2,
            5'd1,
            FUNCT3_ADD_SUB,
            5'd3,
            OPCODE_R_TYPE
        );

        program_memory[3] = encode_r_type(
            FUNCT7_SUB,
            5'd1,
            5'd3,
            FUNCT3_ADD_SUB,
            5'd4,
            OPCODE_R_TYPE
        );

// AND x5, x1, x2
program_memory[4] = encode_r_type(
    FUNCT7_ADD, 5'd2, 5'd1,
    3'b111, 5'd5, OPCODE_R_TYPE
);

// OR x6, x1, x2
program_memory[5] = encode_r_type(
    FUNCT7_ADD, 5'd2, 5'd1,
    3'b110, 5'd6, OPCODE_R_TYPE
);

// XOR x7, x1, x2
program_memory[6] = encode_r_type(
    FUNCT7_ADD, 5'd2, 5'd1,
    3'b100, 5'd7, OPCODE_R_TYPE
);


// SW x3, 4(x0)
// Store x3 at byte address 4.
program_memory[7] = encode_s_type(
    12'd4,
    5'd3,
    5'd0,
    3'b010,
    OPCODE_STORE
);

// LW x8, 4(x0)
// Load the word at byte address 4 into x8.
program_memory[8] = encode_i_type(
    12'd4,
    5'd0,
    3'b010,
    5'd8,
    OPCODE_LOAD
);



// BEQ x1, x1, +8
// Expected: TAKEN because x1 == x1.
program_memory[9] = encode_b_type(
    13'd8, 5'd1, 5'd1, 3'b000, OPCODE_BRANCH
);

// This instruction must be skipped.
program_memory[10] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);


// BNE x1, x2, +8
// Expected: TAKEN because x1 != x2.
program_memory[11] = encode_b_type(
    13'd8, 5'd2, 5'd1, 3'b001, OPCODE_BRANCH
);

// This instruction must be skipped.
program_memory[12] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE
);


// BLT x1, x2, +8
// Expected: TAKEN because signed 10 < signed 20.
program_memory[13] = encode_b_type(
    13'd8, 5'd2, 5'd1, 3'b100, OPCODE_BRANCH
);

// This instruction must be skipped.
program_memory[14] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);


// BGE x2, x1, +8
// Expected: TAKEN because signed 20 >= signed 10.
program_memory[15] = encode_b_type(
    13'd8, 5'd1, 5'd2, 3'b101, OPCODE_BRANCH
);

// This instruction must be skipped.
program_memory[16] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd13, OPCODE_I_TYPE
);


// BLTU x1, x2, +8
// Expected: TAKEN because unsigned 10 < unsigned 20.
program_memory[17] = encode_b_type(
    13'd8, 5'd2, 5'd1, 3'b110, OPCODE_BRANCH
);

// This instruction must be skipped.
program_memory[18] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd14, OPCODE_I_TYPE
);


// BGEU x2, x1, +8
// Expected: TAKEN because unsigned 20 >= unsigned 10.
program_memory[19] = encode_b_type(
    13'd8, 5'd1, 5'd2, 3'b111, OPCODE_BRANCH
);

// This instruction must be skipped.
program_memory[20] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd15, OPCODE_I_TYPE
);


// Final target after the last branch.
// This instruction must execute.
program_memory[21] = encode_i_type(
    12'd99, 5'd0, 3'b000, 5'd9, OPCODE_I_TYPE
);

// BEQ x1, x2, +8
// Not taken because 10 != 20.
program_memory[22] = encode_b_type(
    13'd8, 5'd2, 5'd1, 3'b000, OPCODE_BRANCH
);

// This instruction MUST execute.
program_memory[23] = encode_i_type(
    12'd7, 5'd0, 3'b000, 5'd17, OPCODE_I_TYPE
);


// Used for signed versus unsigned branch testing.
program_memory[24] = encode_i_type(
    12'hFFF,
    5'd0,
    3'b000,
    5'd16,
    OPCODE_I_TYPE
);


// Signed versus unsigned comparison tests

// BLT x16, x2, +8
// Signed comparison: -1 < 20, so TAKEN.
program_memory[25] = encode_b_type(
    13'd8, 5'd2, 5'd16, 3'b100, OPCODE_BRANCH
);

// Marker: must be skipped.
program_memory[26] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd18, OPCODE_I_TYPE
);


// BLTU x16, x2, +8
// Unsigned comparison: 0xFFFFFFFF < 20 is FALSE.
program_memory[27] = encode_b_type(
    13'd8, 5'd2, 5'd16, 3'b110, OPCODE_BRANCH
);

// This instruction must execute.
program_memory[28] = encode_i_type(
    12'd8, 5'd0, 3'b000, 5'd19, OPCODE_I_TYPE
);


// BGE x16, x2, +8
// Signed comparison: -1 >= 20 is FALSE.
program_memory[29] = encode_b_type(
    13'd8, 5'd2, 5'd16, 3'b101, OPCODE_BRANCH
);

// This instruction must execute.
program_memory[30] = encode_i_type(
    12'd9, 5'd0, 3'b000, 5'd20, OPCODE_I_TYPE
);


// BGEU x16, x2, +8
// Unsigned comparison: 0xFFFFFFFF >= 20 is TRUE.
program_memory[31] = encode_b_type(
    13'd8, 5'd2, 5'd16, 3'b111, OPCODE_BRANCH
);

// Marker: must be skipped.
program_memory[32] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd21, OPCODE_I_TYPE
);

// Final target of BGEU at index 31.
// This instruction must execute.
program_memory[33] = encode_i_type(
    12'd123,
    5'd0,
    3'b000,
    5'd22,
    OPCODE_I_TYPE
);


//  JAL and JALR verification
// Index 34: JAL x23, +8
program_memory[34] = encode_j_type(
    21'd8, 5'd23, OPCODE_JAL
);

// Index 35: Skipped marker
program_memory[35] = encode_i_type(
    12'd55, 5'd0, 3'b000, 5'd24, OPCODE_I_TYPE
);

// Index 36: JAL target
program_memory[36] = encode_i_type(
    12'd77, 5'd0, 3'b000, 5'd25, OPCODE_I_TYPE
);

// Index 37: Prepare JALR target address (164)
program_memory[37] = encode_i_type(
    12'd164, 5'd0, 3'b000, 5'd26, OPCODE_I_TYPE
);

// Index 38: JALR x27, 0(x26)
program_memory[38] = encode_i_type(
    12'd0, 5'd26, 3'b000, 5'd27, OPCODE_JALR
);

// Index 39: Skipped marker
program_memory[39] = encode_i_type(
    12'd66, 5'd0, 3'b000, 5'd28, OPCODE_I_TYPE
);

// Index 40: Another skipped marker
program_memory[40] = encode_i_type(
    12'd99, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 41: JALR target
program_memory[41] = encode_i_type(
    12'd88, 5'd0, 3'b000, 5'd29, OPCODE_I_TYPE
);


// Index 42: SLL x31, x1, x2
program_memory[42] = encode_r_type(
    7'b0000000, 5'd2, 5'd1,
    3'b001, 5'd31, OPCODE_R_TYPE
);

// Index 43: SRL x31, x16, x1
program_memory[43] = encode_r_type(
    7'b0000000, 5'd1, 5'd16,
    3'b101, 5'd31, OPCODE_R_TYPE
);

// Index 44: SRA x31, x16, x1
program_memory[44] = encode_r_type(
    7'b0100000, 5'd1, 5'd16,
    3'b101, 5'd31, OPCODE_R_TYPE
);

// Index 45: SLT x31, x16, x2
program_memory[45] = encode_r_type(
    7'b0000000, 5'd2, 5'd16,
    3'b010, 5'd31, OPCODE_R_TYPE
);

// Index 46: SLTU x31, x16, x2
program_memory[46] = encode_r_type(
    7'b0000000, 5'd2, 5'd16,
    3'b011, 5'd31, OPCODE_R_TYPE
);

// Index 47: SLT x31, x2, x16
program_memory[47] = encode_r_type(
    7'b0000000, 5'd16, 5'd2,
    3'b010, 5'd31, OPCODE_R_TYPE
);

// Index 48: SLTU x31, x2, x16
program_memory[48] = encode_r_type(
    7'b0000000, 5'd16, 5'd2,
    3'b011, 5'd31, OPCODE_R_TYPE
);



//  Register x0 corner-case verification


// Index 49: Attempt to write 123 into x0
// Expected: x0 remains zero.
program_memory[49] = encode_i_type(
    12'd123, 5'd0, 3'b000, 5'd0, OPCODE_I_TYPE
);

// Index 50: Read x0 and write the result to x31.
// Expected: x31 = 5.
program_memory[50] = encode_i_type(
    12'd5, 5'd0, 3'b000, 5'd31, OPCODE_I_TYPE
);

// Index 51: Attempt to write x1 + x2 into x0.
// x1 = 10 and x2 = 20, so the attempted result is 30.
program_memory[51] = encode_r_type(
    7'b0000000, 5'd2, 5'd1,
    3'b000, 5'd0, OPCODE_R_TYPE
);

// Index 52: Read x0 again.
// Expected: x30 = 7.
program_memory[52] = encode_i_type(
    12'd7, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 53: Attempt to load a memory value into x0.
// Address 4 contains 30 from our earlier store.
program_memory[53] = encode_i_type(
    12'd4, 5'd0, 3'b010, 5'd0, OPCODE_LOAD
);

// Index 54: Verify that x0 still reads as zero.
// Expected: x29 = 9.
program_memory[54] = encode_i_type(
    12'd9, 5'd0, 3'b000, 5'd29, OPCODE_I_TYPE
);



//  Integrated Load/Store Corner Cases


// Index 55: Store x1 = 10 at byte address 8 (memory word 2)
program_memory[55] = encode_s_type(
    12'd8, 5'd1, 5'd0, 3'b010, OPCODE_STORE
);

// Index 56: Store x2 = 20 at byte address 12 (memory word 3)
program_memory[56] = encode_s_type(
    12'd12, 5'd2, 5'd0, 3'b010, OPCODE_STORE
);

// Index 57: Load memory word 2 into x9
program_memory[57] = encode_i_type(
    12'd8, 5'd0, 3'b010, 5'd9, OPCODE_LOAD
);

// Index 58: Load memory word 3 into x10
program_memory[58] = encode_i_type(
    12'd12, 5'd0, 3'b010, 5'd10, OPCODE_LOAD
);

// Index 59: Store x16 = 0xFFFFFFFF at byte address 16
program_memory[59] = encode_s_type(
    12'd16, 5'd16, 5'd0, 3'b010, OPCODE_STORE
);

// Index 60: Load memory word 4 into x11
program_memory[60] = encode_i_type(
    12'd16, 5'd0, 3'b010, 5'd11, OPCODE_LOAD
);

// Index 61: Store x3 = 30 at the last valid word address, 1020
program_memory[61] = encode_s_type(
    12'd1020, 5'd3, 5'd0, 3'b010, OPCODE_STORE
);

// Index 62: Load the last valid word into x12
program_memory[62] = encode_i_type(
    12'd1020, 5'd0, 3'b010, 5'd12, OPCODE_LOAD
);

// Index 63: Reload byte address 8 into x13
program_memory[63] = encode_i_type(
    12'd8, 5'd0, 3'b010, 5'd13, OPCODE_LOAD
);

// Index 64: Overwrite memory word 2 with x2 = 20
program_memory[64] = encode_s_type(
    12'd8, 5'd2, 5'd0, 3'b010, OPCODE_STORE
);

// Index 65: Read the overwritten value into x14
program_memory[65] = encode_i_type(
    12'd8, 5'd0, 3'b010, 5'd14, OPCODE_LOAD
);

// Index 66: Read memory word 3 again into x15
program_memory[66] = encode_i_type(
    12'd12, 5'd0, 3'b010, 5'd15, OPCODE_LOAD
);

// Index 67: Read memory word 4 again into x17
program_memory[67] = encode_i_type(
    12'd16, 5'd0, 3'b010, 5'd17, OPCODE_LOAD
);

// Index 68: Read the last valid word again into x18
program_memory[68] = encode_i_type(
    12'd1020, 5'd0, 3'b010, 5'd18, OPCODE_LOAD
);




// Immediate arithmetic and comparisons
// Index 69: ADDI x19, x1, -5
program_memory[69] = encode_i_type(
    12'hFFB, 5'd1, 3'b000, 5'd19, OPCODE_I_TYPE
);

// Index 70: SLTI x20, x16, 1
program_memory[70] = encode_i_type(
    12'd1, 5'd16, 3'b010, 5'd20, OPCODE_I_TYPE
);

// Index 71: SLTIU x21, x16, 1
program_memory[71] = encode_i_type(
    12'd1, 5'd16, 3'b011, 5'd21, OPCODE_I_TYPE
);



//  Logical immediate instructions
// Index 72: XORI x22, x1, 15
program_memory[72] = encode_i_type(
    12'd15, 5'd1, 3'b100, 5'd22, OPCODE_I_TYPE
);

// Index 73: ORI x23, x1, 5
program_memory[73] = encode_i_type(
    12'd5, 5'd1, 3'b110, 5'd23, OPCODE_I_TYPE
);

// Index 74: ANDI x24, x2, 12
program_memory[74] = encode_i_type(
    12'd12, 5'd2, 3'b111, 5'd24, OPCODE_I_TYPE
);



// Shift immediate instructions
// Index 75: SLLI x25, x1, 2
program_memory[75] = encode_i_type(
    12'h002, 5'd1, 3'b001, 5'd25, OPCODE_I_TYPE
);

// Index 76: SRLI x26, x16, 4
program_memory[76] = encode_i_type(
    12'h004, 5'd16, 3'b101, 5'd26, OPCODE_I_TYPE
);

// Index 77: SRAI x27, x16, 4
program_memory[77] = encode_i_type(
    12'h404, 5'd16, 3'b101, 5'd27, OPCODE_I_TYPE
);


//  Upper-immediate instructions
// Index 78: LUI x28, 0x12345
program_memory[78] = 32'h12345E37;

// Index 79: AUIPC x29, 1
program_memory[79] = 32'h00001E97;



//  Base-register load/store test
// Index 80: ADDI x30, x0, 8
// Establish a word-aligned base address of 8.
program_memory[80] = encode_i_type(
    12'd8, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 81: SW x2, 8(x30)
// Effective address = 8 + 8 = 16, word index 4.
program_memory[81] = encode_s_type(
    12'd8, 5'd2, 5'd30, 3'b010, OPCODE_STORE
);

// Index 82: LW x31, 8(x30)
program_memory[82] = encode_i_type(
    12'd8, 5'd30, 3'b010, 5'd31, OPCODE_LOAD
);



//  Negative load/store offset


// Index 83: ADDI x30, x0, 24
program_memory[83] = encode_i_type(
    12'd24, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 84: SW x2, -4(x30)
// Effective address = 24 - 4 = 20
program_memory[84] = encode_s_type(
    12'hFFC, 5'd2, 5'd30, 3'b010, OPCODE_STORE
);

// Index 85: LW x31, -4(x30)
// Effective address = 24 - 4 = 20
program_memory[85] = encode_i_type(
    12'hFFC, 5'd30, 3'b010, 5'd31, OPCODE_LOAD
);




// Different base registers, same memory address
// Index 86: ADDI x30, x0, 16
program_memory[86] = encode_i_type(
    12'd16, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 87: ADDI x29, x0, 20
program_memory[87] = encode_i_type(
    12'd20, 5'd0, 3'b000, 5'd29, OPCODE_I_TYPE
);

// Index 88: SW x1, 4(x30)
// Effective address = 16 + 4 = 20
program_memory[88] = encode_s_type(
    12'd4, 5'd1, 5'd30, 3'b010, OPCODE_STORE
);

// Index 89: LW x31, 0(x29)
// Effective address = 20 + 0 = 20
program_memory[89] = encode_i_type(
    12'd0, 5'd29, 3'b010, 5'd31, OPCODE_LOAD
);


// Index 90: SW x1, 0(x30)
// x30 = 16; store x1 = 10 at byte address 16.
program_memory[90] = encode_s_type(
    12'd0, 5'd1, 5'd30, 3'b010, OPCODE_STORE
);

// Index 91: SW x2, 0(x30)
// x30 = 16; overwrite the same address with x2 = 20.
program_memory[91] = encode_s_type(
    12'd0, 5'd2, 5'd30, 3'b010, OPCODE_STORE
);

// Index 92: LW x31, 0(x30)
// Load the updated value from byte address 16.
program_memory[92] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd31, OPCODE_LOAD
);


// Index 93: LW x28, 0(x30)
// Load memory at byte address 16 into x28.
program_memory[93] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd28, OPCODE_LOAD
);

// Index 94: LW x27, 0(x30)
// Load the same memory location into x27.
program_memory[94] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd27, OPCODE_LOAD
);





//  Last Valid Data-Memory Word


// Index 95: ADDI x30, x0, 1020
// Set the base register to the last valid aligned byte address.
program_memory[95] = encode_i_type(
    12'd1020, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 96: SW x1, 0(x30)
// Store x1 = 10 at byte address 1020.
// Expected memory word index = 255.
program_memory[96] = encode_s_type(
    12'd0, 5'd1, 5'd30, 3'b010, OPCODE_STORE
);

// Index 97: LW x31, 0(x30)
// Load the stored value from byte address 1020.
program_memory[97] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd31, OPCODE_LOAD
);



//  First Valid Data-Memory Word



// Index 98: ADDI x30, x0, 0
// Set the base address to zero.
program_memory[98] = encode_i_type(
    12'd0, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 99: SW x1, 0(x30)
// Store x1 = 10 at byte address 0.
program_memory[99] = encode_s_type(
    12'd0, 5'd1, 5'd30, 3'b010, OPCODE_STORE
);

// Index 100: LW x31, 0(x30)
// Load the stored value from byte address 0.
program_memory[100] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd31, OPCODE_LOAD
);




// Negative Value Store/Load

// Index 101: ADDI x26, x0, -1
// Expected x26 = 0xFFFFFFFF.
program_memory[101] = encode_i_type(
    12'hFFF, 5'd0, 3'b000, 5'd26, OPCODE_I_TYPE
);

// Index 102: ADDI x30, x0, 4
// Set the base address to byte address 4.
program_memory[102] = encode_i_type(
    12'd4, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 103: SW x26, 0(x30)
// Store 0xFFFFFFFF at byte address 4.
program_memory[103] = encode_s_type(
    12'd0, 5'd26, 5'd30, 3'b010, OPCODE_STORE
);

// Index 104: LW x25, 0(x30)
// Load the stored value into x25.
program_memory[104] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd25, OPCODE_LOAD
);



//  Mixed-Bit-Pattern Store/Load
// Index 105: LUI x24, 0xA5C3F
// x24 = 0xA5C3F000
program_memory[105] = encode_u_type(
    20'hA5C3F, 5'd24, OPCODE_LUI
);

// Index 106: ADDI x24, x24, 15
// x24 = 0xA5C3F00F
program_memory[106] = encode_i_type(
    12'd15, 5'd24, 3'b000, 5'd24, OPCODE_I_TYPE
);

// Index 107: SW x24, 0(x30)
// x30 currently equals 4, so store at byte address 4.
program_memory[107] = encode_s_type(
    12'd0, 5'd24, 5'd30, 3'b010, OPCODE_STORE
);

// Index 108: LW x23, 0(x30)
// Load the stored value into x23.
program_memory[108] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd23, OPCODE_LOAD
);



//  Systematic Data-Memory Address Mapping


// Index 109: ADDI x30, x0, 0
// Base address = 0.
program_memory[109] = encode_i_type(
    12'd0, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);


// Store different values at selected aligned byte addresses.


// Index 110: SW x1, 0(x30)
// Address 0 -> word index 0; value = 10.
program_memory[110] = encode_s_type(
    12'd0, 5'd1, 5'd30, 3'b010, OPCODE_STORE
);

// Index 111: SW x2, 4(x30)
// Address 4 -> word index 1; value = 20.
program_memory[111] = encode_s_type(
    12'd4, 5'd2, 5'd30, 3'b010, OPCODE_STORE
);

// Index 112: SW x19, 8(x30)
// Address 8 -> word index 2; value = 5.
program_memory[112] = encode_s_type(
    12'd8, 5'd19, 5'd30, 3'b010, OPCODE_STORE
);

// Index 113: SW x20, 12(x30)
// Address 12 -> word index 3; value = 1.
program_memory[113] = encode_s_type(
    12'd12, 5'd20, 5'd30, 3'b010, OPCODE_STORE
);

// Index 114: SW x24, 16(x30)
// Address 16 -> word index 4;
// value = 0xA5C3F00F.
program_memory[114] = encode_s_type(
    12'd16, 5'd24, 5'd30, 3'b010, OPCODE_STORE
);

// Index 115: SW x26, 1020(x30)
// Address 1020 -> word index 255;
// value = 0xFFFFFFFF.
program_memory[115] = encode_s_type(
    12'd1020, 5'd26, 5'd30, 3'b010, OPCODE_STORE
);


// Load each selected word into a separate destination register.


// Index 116: LW x15, 0(x30)
program_memory[116] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd15, OPCODE_LOAD
);

// Index 117: LW x14, 4(x30)
program_memory[117] = encode_i_type(
    12'd4, 5'd30, 3'b010, 5'd14, OPCODE_LOAD
);

// Index 118: LW x13, 8(x30)
program_memory[118] = encode_i_type(
    12'd8, 5'd30, 3'b010, 5'd13, OPCODE_LOAD
);

// Index 119: LW x12, 12(x30)
program_memory[119] = encode_i_type(
    12'd12, 5'd30, 3'b010, 5'd12, OPCODE_LOAD
);

// Index 120: LW x11, 16(x30)
program_memory[120] = encode_i_type(
    12'd16, 5'd30, 3'b010, 5'd11, OPCODE_LOAD
);

// Index 121: LW x10, 1020(x30)
program_memory[121] = encode_i_type(
    12'd1020, 5'd30, 3'b010, 5'd10, OPCODE_LOAD
);



//  I-Type Immediate Boundary Tests


// Index 122: ADDI x9, x0, 0
// Expected: x9 = 0x00000000
program_memory[122] = encode_i_type(
    12'h000, 5'd0, 3'b000, 5'd9, OPCODE_I_TYPE
);

// Index 123: ADDI x8, x0, 2047
// Expected: x8 = 0x000007FF
program_memory[123] = encode_i_type(
    12'h7FF, 5'd0, 3'b000, 5'd8, OPCODE_I_TYPE
);

// Index 124: ADDI x7, x0, -2048
// Expected: x7 = 0xFFFFF800
program_memory[124] = encode_i_type(
    12'h800, 5'd0, 3'b000, 5'd7, OPCODE_I_TYPE
);

// Index 125: ADDI x6, x0, -1
// Expected: x6 = 0xFFFFFFFF
program_memory[125] = encode_i_type(
    12'hFFF, 5'd0, 3'b000, 5'd6, OPCODE_I_TYPE
);




//  S-Type Immediate and Effective-Address Tests


// Index 126: ADDI x30, x0, 0
// Base address = 0.

program_memory[126] = encode_i_type(
    12'd0, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 127: SW x1, 12(x30)
// Effective address = 16 + 12 = 28.
// x1 = 10.
program_memory[127] = encode_s_type(
    12'd12, 5'd1, 5'd30, 3'b010, OPCODE_STORE
);

// Index 128: ADDI x30, x0, 24
// Base address = 24.
program_memory[128] = encode_i_type(
    12'd24, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 129: SW x2, -4(x30)
// Effective address = 24 - 4 = 20.
// x2 = 20.
program_memory[129] = encode_s_type(
    12'hFFC, 5'd2, 5'd30, 3'b010, OPCODE_STORE
);

// Index 130: ADDI x30, x0, 8
// Base address = 8.
program_memory[130] = encode_i_type(
    12'd8, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 131: SW x19, -8(x30)
// Effective address = 8 - 8 = 0.
// x19 = 5.
program_memory[131] = encode_s_type(
    12'hFF8, 5'd19, 5'd30, 3'b010, OPCODE_STORE
);

// Index 132: LW x15, 12(x0)
// Read the value at byte address 12.
program_memory[132] = encode_i_type(
    12'd12, 5'd0, 3'b010, 5'd15, OPCODE_LOAD
);

// Index 133: LW x14, 20(x0)
// Read the value at byte address 20.
program_memory[133] = encode_i_type(
    12'd20, 5'd0, 3'b010, 5'd14, OPCODE_LOAD
);

// Index 134: LW x13, 0(x0)
// Read the value at byte address 0.
program_memory[134] = encode_i_type(
    12'd0, 5'd0, 3'b010, 5'd13, OPCODE_LOAD
);



//  ADDI immediate boundary tests

// ADDI x10, x0, 0
program_memory[135] = encode_i_type(
    12'd0, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);

// ADDI x11, x0, -1
program_memory[136] = encode_i_type(
    12'hFFF, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE
);

// ADDI x12, x0, -2048
program_memory[137] = encode_i_type(
    12'h800, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);


// Construct x10 = 0x7FFFFFFF
program_memory[138] = encode_u_type(
    20'h80000, 5'd10, OPCODE_LUI
);

program_memory[139] = encode_i_type(
    12'hFFF, 5'd10, 3'b000, 5'd10, OPCODE_I_TYPE
);

// Construct x11 = 0x80000000
program_memory[140] = encode_u_type(
    20'h80000, 5'd11, OPCODE_LUI
);

// Construct x12 = 1
program_memory[141] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);


// ADD x13, x10, x12
// Expected: 0x7FFFFFFF + 1 = 0x80000000
program_memory[142] = encode_r_type(
    7'b0000000, 5'd12, 5'd10,
    3'b000, 5'd13, OPCODE_R_TYPE
);

// SUB x14, x11, x12
// Expected: 0x80000000 - 1 = 0x7FFFFFFF
program_memory[143] = encode_r_type(
    7'b0100000, 5'd12, 5'd11,
    3'b000, 5'd14, OPCODE_R_TYPE
);

// SUB x15, x10, x10
// Expected: 0x7FFFFFFF - 0x7FFFFFFF = 0
program_memory[144] = encode_r_type(
    7'b0100000, 5'd10, 5'd10,
    3'b000, 5'd15, OPCODE_R_TYPE
);


//  SLT vs SLTU

// Index 145: ADDI x10, x0, -1
program_memory[145] = encode_i_type(
    12'hFFF, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);

// Index 146: ADDI x11, x0, 1
program_memory[146] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE
);



// Index 147: SLT x12, x10, x11
// Signed: -1 < 1 -> true
program_memory[147] = encode_r_type(
    7'b0000000, 5'd11, 5'd10,
    3'b010, 5'd12, OPCODE_R_TYPE
);

// Index 148: SLTU x13, x10, x11
// Unsigned: 0xFFFFFFFF < 1 -> false
program_memory[148] = encode_r_type(
    7'b0000000, 5'd11, 5'd10,
    3'b011, 5'd13, OPCODE_R_TYPE
);

// Index 149: SLT x14, x11, x10
// Signed: 1 < -1 -> false
program_memory[149] = encode_r_type(
    7'b0000000, 5'd10, 5'd11,
    3'b010, 5'd14, OPCODE_R_TYPE
);

// Index 150: SLTU x15, x11, x10
// Unsigned: 1 < 0xFFFFFFFF -> true
program_memory[150] = encode_r_type(
    7'b0000000, 5'd10, 5'd11,
    3'b011, 5'd15, OPCODE_R_TYPE
);


//  Shift Boundary Verification


// Index 151: ADDI x10, x0, 1
program_memory[151] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);

// Index 152: LUI x11, 0x80000
// x11 = 0x80000000
program_memory[152] = encode_u_type(
    20'h80000, 5'd11, OPCODE_LUI
);

// SLLI: Shift Left Logical Immediate

// Index 153: SLLI x16, x10, 0
program_memory[153] = encode_i_type(
    12'd0, 5'd10, 3'b001, 5'd16, OPCODE_I_TYPE
);

// Index 154: SLLI x17, x10, 1
program_memory[154] = encode_i_type(
    12'd1, 5'd10, 3'b001, 5'd17, OPCODE_I_TYPE
);

// Index 155: SLLI x18, x10, 31
program_memory[155] = encode_i_type(
    12'd31, 5'd10, 3'b001, 5'd18, OPCODE_I_TYPE
);

// SRLI: Shift Right Logical Immediate

// Index 156: SRLI x19, x11, 0
program_memory[156] = encode_i_type(
    12'h000, 5'd11, 3'b101, 5'd19, OPCODE_I_TYPE
);

// Index 157: SRLI x20, x11, 1
program_memory[157] = encode_i_type(
    12'h001, 5'd11, 3'b101, 5'd20, OPCODE_I_TYPE
);

// Index 158: SRLI x21, x11, 31
program_memory[158] = encode_i_type(
    12'h01F, 5'd11, 3'b101, 5'd21, OPCODE_I_TYPE
);

// SRAI: Shift Right Arithmetic Immediate

// Index 159: SRAI x22, x11, 0
// funct7 = 0100000, shamt = 00000
program_memory[159] = encode_i_type(
    12'h400, 5'd11, 3'b101, 5'd22, OPCODE_I_TYPE
);

// Index 160: SRAI x23, x11, 1
program_memory[160] = encode_i_type(
    12'h401, 5'd11, 3'b101, 5'd23, OPCODE_I_TYPE
);

// Index 161: SRAI x24, x11, 31
program_memory[161] = encode_i_type(
    12'h41F, 5'd11, 3'b101, 5'd24, OPCODE_I_TYPE
);



//  Register Dependency Verification


// Index 162: ADDI x5, x0, 10
// Expected: x5 = 10
program_memory[162] = encode_i_type(
    12'd10, 5'd0, 3'b000, 5'd5, OPCODE_I_TYPE
);

// Index 163: ADDI x6, x5, 5
// Expected: x6 = 15
program_memory[163] = encode_i_type(
    12'd5, 5'd5, 3'b000, 5'd6, OPCODE_I_TYPE
);

// Index 164: ADD x7, x5, x6
// Expected: x7 = 10 + 15 = 25
program_memory[164] = encode_r_type(
    7'b0000000,
    5'd6,
    5'd5,
    3'b000,
    5'd7,
    OPCODE_R_TYPE
);





//  Read-After-Write Dependency Chain


// Index 165: ADDI x5, x0, 10
program_memory[165] = encode_i_type(
    12'd10, 5'd0, 3'b000, 5'd5, OPCODE_I_TYPE
);

// Index 166: ADDI x5, x5, 5
program_memory[166] = encode_i_type(
    12'd5, 5'd5, 3'b000, 5'd5, OPCODE_I_TYPE
);

// Index 167: ADDI x5, x5, 3
program_memory[167] = encode_i_type(
    12'd3, 5'd5, 3'b000, 5'd5, OPCODE_I_TYPE
);

// Index 168: ADDI x6, x5, 2
program_memory[168] = encode_i_type(
    12'd2, 5'd5, 3'b000, 5'd6, OPCODE_I_TYPE
);

// Index 169: ADD x7, x5, x6
program_memory[169] = encode_r_type(
    7'b0000000,
    5'd6,
    5'd5,
    3'b000,
    5'd7,
    OPCODE_R_TYPE
);





//  Independent Instruction Interleaving


// Index 170: ADDI x8, x0, 7
program_memory[170] = encode_i_type(
    12'd7, 5'd0, 3'b000, 5'd8, OPCODE_I_TYPE
);

// Index 171: ADDI x9, x0, 20
program_memory[171] = encode_i_type(
    12'd20, 5'd0, 3'b000, 5'd9, OPCODE_I_TYPE
);

// Index 172: ADDI x28, x0, 3
program_memory[172] = encode_i_type(
    12'd3, 5'd0, 3'b000, 5'd28, OPCODE_I_TYPE
);

// Index 173: ADDI x8, x8, 1
program_memory[173] = encode_i_type(
    12'd1, 5'd8, 3'b000, 5'd8, OPCODE_I_TYPE
);

// Index 174: ADDI x9, x9, -2
program_memory[174] = encode_i_type(
    12'hFFE, 5'd9, 3'b000, 5'd9, OPCODE_I_TYPE
);

// Index 175: ADD x29, x28, x9
program_memory[175] = encode_r_type(
    7'b0000000,
    5'd9,
    5'd28,
    3'b000,
    5'd29,
    OPCODE_R_TYPE
);


// Index 176: ADDI x10, x0, 10
program_memory[176] = encode_i_type(
    12'd10, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);

// Index 177: ADDI x11, x0, 20
program_memory[177] = encode_i_type(
    12'd20, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE
);

// Index 178: ADDI x10, x0, 30
// Overwrites the previous value of x10.
program_memory[178] = encode_i_type(
    12'd30, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);

// Index 179: ADD x12, x10, x11
// Uses the latest x10 value.
program_memory[179] = encode_r_type(
    7'b0000000,
    5'd11,
    5'd10,
    3'b000,
    5'd12,
    OPCODE_R_TYPE
);






//  x0 Write Protection with Dependencies


// Index 180: ADDI x10, x0, 7
program_memory[180] = encode_i_type(
    12'd7, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);

// Index 181: ADDI x0, x10, 5
// Attempts to write 12 to x0. The write must be ignored.
program_memory[181] = encode_i_type(
    12'd5, 5'd10, 3'b000, 5'd0, OPCODE_I_TYPE
);

// Index 182: ADD x11, x0, x10
// x0 must still be zero, so x11 = 0 + 7 = 7.
program_memory[182] = encode_r_type(
    7'b0000000,
    5'd10,
    5'd0,
    3'b000,
    5'd11,
    OPCODE_R_TYPE
);

// Index 183: ADDI x12, x0, 1
// Confirms that a subsequent read of x0 still returns zero.
program_memory[183] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);

// Index 184: ADDI x6, x0, 123
program_memory[184] = encode_i_type(
    12'd123, 5'd0, 3'b000, 5'd6, OPCODE_I_TYPE
);

// Index 185: ADDI x5, x0, 10
program_memory[185] = encode_i_type(
    12'd10, 5'd0, 3'b000, 5'd5, OPCODE_I_TYPE
);

// Index 186: BEQ x5, x5, +8
// Branch target: PC 744 + 8 = PC 752 (index 188)
program_memory[186] = encode_b_type(
    13'd8,
    5'd5,  // rs2
    5'd5,  // rs1
    3'b000,
    OPCODE_BRANCH
);

// Index 187: ADDI x6, x0, 99
// Must be skipped.
program_memory[187] = encode_i_type(
    12'd99, 5'd0, 3'b000, 5'd6, OPCODE_I_TYPE
);

// Index 188: ADDI x7, x0, 20
program_memory[188] = encode_i_type(
    12'd20, 5'd0, 3'b000, 5'd7, OPCODE_I_TYPE
);


// Index 189: ADDI x8, x0, 0
// Initialize counter.
program_memory[189] = encode_i_type(
    12'd0, 5'd0, 3'b000, 5'd8, OPCODE_I_TYPE
);

// Index 190: ADDI x8, x8, 1
// Increment counter.
program_memory[190] = encode_i_type(
    12'd1, 5'd8, 3'b000, 5'd8, OPCODE_I_TYPE
);

// Index 191: ADDI x9, x0, 2
// Set comparison value.
program_memory[191] = encode_i_type(
    12'd2, 5'd0, 3'b000, 5'd9, OPCODE_I_TYPE
);

// Index 192: BNE x8, x9, -8
// If x8 != x9, branch backward to index 190.
program_memory[192] = encode_b_type(
    13'h1FF8,       // -8 bytes in 13-bit two's complement
    5'd9,           // rs2
    5'd8,           // rs1
    3'b001,         // BNE
    OPCODE_BRANCH
);

// Index 193: ADDI x10, x0, 77
// Executed when the branch is not taken.
program_memory[193] = encode_i_type(
    12'd77, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);

// Index 194: ADDI x30, x0, 40
// Base address = 40 bytes.
program_memory[194] = encode_i_type(
    12'd40, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 195: ADDI x11, x0, 55
program_memory[195] = encode_i_type(
    12'd55, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE
);

// Index 196: SW x11, 0(x30)
// Initialize memory word 10 to 55.
program_memory[196] = encode_s_type(
    12'd0, 5'd11, 5'd30, 3'b010, OPCODE_STORE
);

// Index 197: ADDI x12, x0, 99
program_memory[197] = encode_i_type(
    12'd99, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);

// Index 198: BEQ x0, x0, +8
// Always taken. Skip index 199 and jump to index 200.
program_memory[198] = encode_b_type(
    13'd8,
    5'd0,             // rs2
    5'd0,             // rs1
    3'b000,           // BEQ
    OPCODE_BRANCH
);

// Index 199: SW x12, 0(x30)
// Must be skipped. If executed, memory word 10 becomes 99.
program_memory[199] = encode_s_type(
    12'd0, 5'd12, 5'd30, 3'b010, OPCODE_STORE
);

// Index 200: LW x13, 0(x30)
// Must load the original value, 55.
program_memory[200] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd13, OPCODE_LOAD
);




// Index 201: ADDI x30, x0, 40
program_memory[201] = encode_i_type(
    12'd40, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE
);

// Index 202: ADDI x11, x0, 55
program_memory[202] = encode_i_type(
    12'd55, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE
);

// Index 203: SW x11, 0(x30)
// Initialize memory word 10 to 55.
program_memory[203] = encode_s_type(
    12'd0, 5'd11, 5'd30, 3'b010, OPCODE_STORE
);

// Index 204: ADDI x12, x0, 0
// Initialize loop counter.
program_memory[204] = encode_i_type(
    12'd0, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);

// Index 205: ADDI x12, x12, 1
// Increment loop counter.
program_memory[205] = encode_i_type(
    12'd1, 5'd12, 3'b000, 5'd12, OPCODE_I_TYPE
);

// Index 206: ADDI x13, x0, 3
// Loop limit.
program_memory[206] = encode_i_type(
    12'd3, 5'd0, 3'b000, 5'd13, OPCODE_I_TYPE
);

// Index 207: BLT x12, x13, -8
// Return to index 205 while x12 < x13.
program_memory[207] = encode_b_type(
    13'h1FF8,
    5'd13,             // rs2
    5'd12,             // rs1
    3'b100,            // BLT
    OPCODE_BRANCH
);

// Index 208: BEQ x0, x0, +8
// Always taken; skip index 209.
program_memory[208] = encode_b_type(
    13'd8,
    5'd0,               // rs2
    5'd0,               // rs1
    3'b000,             // BEQ
    OPCODE_BRANCH
);

// Index 209: SW x13, 0(x30)
// Must be skipped.
program_memory[209] = encode_s_type(
    12'd0, 5'd13, 5'd30, 3'b010, OPCODE_STORE
);

// Index 210: LW x14, 0(x30)
// Load the original memory value.
program_memory[210] = encode_i_type(
    12'd0, 5'd30, 3'b010, 5'd14, OPCODE_LOAD
);

// Index 211 | PC = 844
// Initialize a register before the jump.
program_memory[211] =
    encode_i_type(12'd10, 5'd0, 3'b000, 5'd5, OPCODE_I_TYPE);

program_memory[212] =
    encode_i_type(12'd66, 5'd0, 3'b000, 5'd6, OPCODE_I_TYPE);

program_memory[213] =
    encode_i_type(12'd77, 5'd0, 3'b000, 5'd7, OPCODE_I_TYPE);

// Index 214 | PC = 856
// JAL x20, +12
// Expected link address: 860
// Expected jump target: 868
program_memory[214] =
    encode_j_type(21'd12, 5'd20, OPCODE_JAL);

// Index 215 | PC = 860
// Must be skipped.
program_memory[215] =
    encode_i_type(12'd99, 5'd0, 3'b000, 5'd6, OPCODE_I_TYPE);

// Index 216 | PC = 864
// Must also be skipped.
program_memory[216] =
    encode_i_type(12'd88, 5'd0, 3'b000, 5'd7, OPCODE_I_TYPE);

// Index 217 | PC = 868
// JAL target: execute this instruction.
program_memory[217] =
    encode_i_type(12'd42, 5'd0, 3'b000, 5'd8, OPCODE_I_TYPE);


//  Basic JALR and target bit-zero clearing
// Starts at index 218, PC = 872


program_memory[218] = encode_i_type(
    12'd905, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);

program_memory[219] = encode_i_type(
    12'd66, 5'd0, 3'b000, 5'd6, OPCODE_I_TYPE
);

program_memory[220] = encode_i_type(
    12'd77, 5'd0, 3'b000, 5'd7, OPCODE_I_TYPE
);

program_memory[221] = encode_i_type(
    12'd0, 5'd10, 3'b000, 5'd11, OPCODE_JALR
);

// Instructions skipped by JALR
program_memory[222] = encode_i_type(
    12'd99, 5'd0, 3'b000, 5'd6, OPCODE_I_TYPE
);

program_memory[223] = encode_i_type(
    12'd88, 5'd0, 3'b000, 5'd7, OPCODE_I_TYPE
);

program_memory[224] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd9, OPCODE_I_TYPE
);

program_memory[225] = encode_i_type(
    12'd2, 5'd0, 3'b000, 5'd9, OPCODE_I_TYPE
);

// JALR target
program_memory[226] = encode_i_type(
    12'd42, 5'd0, 3'b000, 5'd8, OPCODE_I_TYPE
);



//  JALR with positive immediate
// Continues after U-A


program_memory[227] = encode_i_type(
    12'd932, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);

program_memory[228] = encode_i_type(
    12'd33, 5'd0, 3'b000, 5'd13, OPCODE_I_TYPE
);

program_memory[229] = encode_i_type(
    12'd55, 5'd0, 3'b000, 5'd15, OPCODE_I_TYPE
);

program_memory[230] = encode_i_type(
    12'd4, 5'd12, 3'b000, 5'd14, OPCODE_JALR
);

// Skipped instructions
program_memory[231] = encode_i_type(
    12'd99, 5'd0, 3'b000, 5'd13, OPCODE_I_TYPE
);

program_memory[232] = encode_i_type(
    12'd88, 5'd0, 3'b000, 5'd15, OPCODE_I_TYPE
);

program_memory[233] = encode_i_type(
    12'd77, 5'd0, 3'b000, 5'd16, OPCODE_I_TYPE
);

// JALR target
program_memory[234] = encode_i_type(
    12'd42, 5'd0, 3'b000, 5'd16, OPCODE_I_TYPE
);



//  JALR with negative immediate


program_memory[235] = encode_i_type(
    12'd964, 5'd0, 3'b000, 5'd17, OPCODE_I_TYPE
);

program_memory[236] = encode_i_type(
    12'd18, 5'd0, 3'b000, 5'd18, OPCODE_I_TYPE
);

program_memory[237] = encode_i_type(
    12'd19, 5'd0, 3'b000, 5'd19, OPCODE_I_TYPE
);

program_memory[238] = encode_i_type(
    12'hFFC, 5'd17, 3'b000, 5'd20, OPCODE_JALR
);

// Skipped instruction
program_memory[239] = encode_i_type(
    12'd99, 5'd0, 3'b000, 5'd18, OPCODE_I_TYPE
);

// JALR target
program_memory[240] = encode_i_type(
    12'd42, 5'd0, 3'b000, 5'd21, OPCODE_I_TYPE
);

// CORE-001V-A
program_memory[241] = encode_i_type(12'd1,  5'd0, 3'b000, 5'd22, OPCODE_I_TYPE);
program_memory[242] = encode_i_type(12'd1,  5'd0, 3'b000, 5'd23, OPCODE_I_TYPE);
program_memory[243] = encode_b_type(13'd8,  5'd23, 5'd22, 3'b000, OPCODE_BRANCH);
program_memory[244] = encode_i_type(12'd99, 5'd0, 3'b000, 5'd21, OPCODE_I_TYPE);
program_memory[245] = encode_i_type(12'd10, 5'd0, 3'b000, 5'd24, OPCODE_I_TYPE);

// CORE-001V-B
program_memory[246] = encode_j_type(21'd8, 5'd25, OPCODE_JAL);
program_memory[247] = encode_i_type(12'd99, 5'd0, 3'b000, 5'd25, OPCODE_I_TYPE);
program_memory[248] = encode_i_type(12'd1017, 5'd0, 3'b000, 5'd26, OPCODE_I_TYPE);

// CORE-001V-C
program_memory[249] = encode_i_type(-12'sd4, 5'd26, 3'b000, 5'd28, OPCODE_JALR);
program_memory[250] = encode_i_type(12'd99, 5'd0, 3'b000, 5'd28, OPCODE_I_TYPE);
program_memory[251] = encode_i_type(12'd88, 5'd0, 3'b000, 5'd29, OPCODE_I_TYPE);
program_memory[252] = encode_i_type(12'd77, 5'd0, 3'b000, 5'd29, OPCODE_I_TYPE);
program_memory[253] = encode_i_type(12'd29, 5'd0, 3'b000, 5'd29, OPCODE_I_TYPE);

// CORE-001V-D
program_memory[254] = encode_i_type(12'd40, 5'd0, 3'b000, 5'd30, OPCODE_I_TYPE);
program_memory[255] = encode_i_type(12'd99, 5'd0, 3'b000, 5'd31, OPCODE_I_TYPE);
program_memory[256] = encode_b_type(13'd8, 5'd0, 5'd0, 3'b000, OPCODE_BRANCH);
program_memory[257] = encode_s_type(12'd0, 5'd31, 5'd30, 3'b010, OPCODE_STORE);
program_memory[258] = encode_i_type(12'd0, 5'd30, 3'b010, 5'd18, OPCODE_LOAD);



program_memory[259] = encode_i_type(
    12'd64, 5'd0, 3'b000, 5'd5, OPCODE_I_TYPE
);  // ADDI x5, x0, 64

program_memory[260] = encode_i_type(
    12'd123, 5'd0, 3'b000, 5'd6, OPCODE_I_TYPE
);  // ADDI x6, x0, 123

program_memory[261] = encode_s_type(
    12'd0, 5'd6, 5'd5, 3'b010, OPCODE_STORE
);  // SW x6, 0(x5)

program_memory[262] = encode_i_type(
    12'd0, 5'd5, 3'b010, 5'd7, OPCODE_LOAD
);  // LW x7, 0(x5)

program_memory[263] = encode_i_type(
    12'd1, 5'd7, 3'b000, 5'd8, OPCODE_I_TYPE
);  // ADDI x8, x7, 1

program_memory[264] = encode_r_type(
    7'b0000000, 5'd8, 5'd7,
    3'b000, 5'd9, OPCODE_R_TYPE
);  // ADD x9, x7, x8


program_memory[265] = encode_i_type(
    12'd0, 5'd5, 3'b010, 5'd10, OPCODE_LOAD
);  // LW x10, 0(x5)

program_memory[266] = encode_i_type(
    12'd123, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE
);  // ADDI x11, x0, 123

program_memory[267] = encode_b_type(
    13'd8, 5'd11, 5'd10, 3'b000, OPCODE_BRANCH
);  // BEQ x10, x11, +8

program_memory[268] = encode_i_type(
    12'd99, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);  // ADDI x12, x0, 99 -- SKIPPED

program_memory[269] = encode_i_type(
    12'd42, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);  // ADDI x12, x0, 42




program_memory[270] = encode_i_type(
    12'd80, 5'd0, 3'b000, 5'd13, OPCODE_I_TYPE
);  // ADDI x13, x0, 80

program_memory[271] = encode_i_type(
    12'd0, 5'd5, 3'b010, 5'd14, OPCODE_LOAD
);  // LW x14, 0(x5)

program_memory[272] = encode_s_type(
    12'd0, 5'd14, 5'd13, 3'b010, OPCODE_STORE
);  // SW x14, 0(x13)

program_memory[273] = encode_i_type(
    12'd0, 5'd13, 3'b010, 5'd15, OPCODE_LOAD
);  // LW x15, 0(x13)

program_memory[274] = encode_i_type(
    12'd85, 5'd15, 3'b100, 5'd16, OPCODE_I_TYPE
);  // XORI x16, x15, 85


program_memory[275] = encode_i_type(
    12'd0, 5'd13, 3'b010, 5'd17, OPCODE_LOAD
);  // LW x17, 0(x13)

program_memory[276] = encode_i_type(
    12'd124, 5'd0, 3'b000, 5'd18, OPCODE_I_TYPE
);  // ADDI x18, x0, 124

program_memory[277] = encode_b_type(
    13'd8, 5'd18, 5'd17, 3'b000, OPCODE_BRANCH
);  // BEQ x17, x18, +8 -- NOT TAKEN

program_memory[278] = encode_i_type(
    12'd7, 5'd0, 3'b000, 5'd19, OPCODE_I_TYPE
);  // ADDI x19, x0, 7



program_memory[279] = encode_i_type(
    -12'sd7, 5'd0, 3'b000, 5'd20, OPCODE_I_TYPE
);  // ADDI x20, x0, -7

program_memory[280] = encode_i_type(
    12'd3, 5'd0, 3'b000, 5'd21, OPCODE_I_TYPE
);  // ADDI x21, x0, 3

program_memory[281] = encode_r_type(
    7'b0000000, 5'd21, 5'd20,
    3'b000, 5'd22, OPCODE_R_TYPE
);  // ADD x22, x20, x21

program_memory[282] = encode_i_type(
    12'd88, 5'd0, 3'b000, 5'd23, OPCODE_I_TYPE
);  // ADDI x23, x0, 88

program_memory[283] = encode_s_type(
    12'd0, 5'd22, 5'd23, 3'b010, OPCODE_STORE
);  // SW x22, 0(x23)

program_memory[284] = encode_i_type(
    12'd0, 5'd23, 3'b010, 5'd24, OPCODE_LOAD
);  // LW x24, 0(x23)

program_memory[285] = encode_i_type(
    -12'sd1, 5'd24, 3'b000, 5'd25, OPCODE_I_TYPE
);  // ADDI x25, x24, -1



program_memory[286] = encode_i_type(
    -12'sd1, 5'd0, 3'b000, 5'd26, OPCODE_I_TYPE
);  // ADDI x26, x0, -1

program_memory[287] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd27, OPCODE_I_TYPE
);  // ADDI x27, x0, 1

program_memory[288] = encode_r_type(
    7'b0000000, 5'd27, 5'd26,
    3'b010, 5'd28, OPCODE_R_TYPE
);  // SLT x28, x26, x27

program_memory[289] = encode_r_type(
    7'b0000000, 5'd27, 5'd26,
    3'b011, 5'd29, OPCODE_R_TYPE
);  // SLTU x29, x26, x27

program_memory[290] = encode_r_type(
    7'b0000000, 5'd26, 5'd27,
    3'b010, 5'd30, OPCODE_R_TYPE
);  // SLT x30, x27, x26

program_memory[291] = encode_r_type(
    7'b0000000, 5'd26, 5'd27,
    3'b011, 5'd31, OPCODE_R_TYPE
);  // SLTU x31, x27, x26


program_memory[292] = encode_i_type(
    12'd0, 5'd23, 3'b010, 5'd10, OPCODE_LOAD
);  // LW x10, 0(x23)

program_memory[293] = encode_i_type(
    -12'sd4, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE
);  // ADDI x11, x0, -4

program_memory[294] = encode_b_type(
    13'd8, 5'd11, 5'd10, 3'b000, OPCODE_BRANCH
);  // BEQ x10, x11, +8

program_memory[295] = encode_i_type(
    12'd99, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);  // ADDI x12, x0, 99 -- SKIPPED

program_memory[296] = encode_i_type(
    12'd42, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);  // ADDI x12, x0, 42



program_memory[297] = encode_r_type(
    7'b0000000, 5'd27, 5'd10,
    3'b000, 5'd14, OPCODE_R_TYPE
);  // ADD x14, x10, x27

program_memory[298] = encode_i_type(
    12'd96, 5'd0, 3'b000, 5'd15, OPCODE_I_TYPE
);  // ADDI x15, x0, 96

program_memory[299] = encode_s_type(
    12'd0, 5'd14, 5'd15, 3'b010, OPCODE_STORE
);  // SW x14, 0(x15)

program_memory[300] = encode_i_type(
    12'd0, 5'd15, 3'b010, 5'd16, OPCODE_LOAD
);  // LW x16, 0(x15)

program_memory[301] = encode_r_type(
    7'b0000000, 5'd27, 5'd16,
    3'b000, 5'd17, OPCODE_R_TYPE
);  // ADD x17, x16, x27

program_memory[302] = encode_i_type(
    12'd15, 5'd17, 3'b100, 5'd18, OPCODE_I_TYPE
);  // XORI x18, x17, 15



program_memory[303] = encode_i_type(
    12'd1, 5'd0, 3'b000, 5'd5, OPCODE_I_TYPE
);  // ADDI x5, x0, 1

program_memory[304] = encode_i_type(
    12'd2, 5'd0, 3'b000, 5'd6, OPCODE_I_TYPE
);  // ADDI x6, x0, 2

program_memory[305] = encode_i_type(
    12'd3, 5'd0, 3'b000, 5'd7, OPCODE_I_TYPE
);  // ADDI x7, x0, 3

program_memory[306] = encode_i_type(
    12'd4, 5'd0, 3'b000, 5'd8, OPCODE_I_TYPE
);  // ADDI x8, x0, 4

program_memory[307] = encode_i_type(
    12'd5, 5'd0, 3'b000, 5'd9, OPCODE_I_TYPE
);  // ADDI x9, x0, 5

program_memory[308] = encode_i_type(
    12'd6, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE
);  // ADDI x10, x0, 6

program_memory[309] = encode_i_type(
    12'd7, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE
);  // ADDI x11, x0, 7

program_memory[310] = encode_i_type(
    12'd8, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE
);  // ADDI x12, x0, 8

program_memory[311] = encode_i_type(
    12'd9, 5'd0, 3'b000, 5'd13, OPCODE_I_TYPE
);  // ADDI x13, x0, 9

program_memory[312] = encode_i_type(
    12'd10, 5'd0, 3'b000, 5'd14, OPCODE_I_TYPE
);  // ADDI x14, x0, 10

program_memory[313] = encode_i_type(
    12'd11, 5'd0, 3'b000, 5'd15, OPCODE_I_TYPE
);  // ADDI x15, x0, 11






//  Deterministic Random Instruction Generation
// Instructions 314 through 353


initial_rand_seed = 32'h50484E58;
rand_seed = initial_rand_seed;

$display("\nRandom verification seed = %h", initial_rand_seed);


//Initialize functional coverage counters.
for (coverage_i = 0; coverage_i < 10; coverage_i = coverage_i + 1) begin
    alu_op_coverage[coverage_i] = 0;
end



// Initialize the independent reference model.
for (rand_i = 0; rand_i < 32; rand_i = rand_i + 1) begin
    model_regs[rand_i] = 32'd0;
end

// Mirror the known initialization values in the reference model.
for (rand_i = 5; rand_i <= 15; rand_i = rand_i + 1) begin
    model_regs[rand_i] = rand_i - 4;
end

// Generate 40 randomized R-type instructions.
for (rand_i = 0; rand_i < 40; rand_i = rand_i + 1) begin

    // Select an operation from 0 through 9.
    rand_value = $random(rand_seed);
    if (rand_value < 0)
        rand_value = -rand_value;
    rand_op = rand_value % 10;




// Record the selected ALU operation.
alu_op_coverage[rand_op] = alu_op_coverage[rand_op] + 1;





    // Select registers x5 through x15.
    rand_value = $random(rand_seed);
    if (rand_value < 0)
        rand_value = -rand_value;
    rand_rd = 5 + (rand_value % 11);

    rand_value = $random(rand_seed);
    if (rand_value < 0)
        rand_value = -rand_value;
    rand_rs1 = 5 + (rand_value % 11);

    rand_value = $random(rand_seed);
    if (rand_value < 0)
        rand_value = -rand_value;
    rand_rs2 = 5 + (rand_value % 11);

    // Read operands from the independent reference model.
    rand_a = model_regs[rand_rs1];
    rand_b = model_regs[rand_rs2];

    // Default encoding.
    rand_funct7 = 7'b0000000;
    rand_funct3 = 3'b000;
    rand_result = 32'd0;

    // Select the instruction encoding and calculate its result.
    case (rand_op)

        // ADD
        0: begin
            rand_funct7 = 7'b0000000;
            rand_funct3 = 3'b000;
            rand_result = rand_a + rand_b;
        end

        // SUB
        1: begin
            rand_funct7 = 7'b0100000;
            rand_funct3 = 3'b000;
            rand_result = rand_a - rand_b;
        end

        // AND
        2: begin
            rand_funct3 = 3'b111;
            rand_result = rand_a & rand_b;
        end

        // OR
        3: begin
            rand_funct3 = 3'b110;
            rand_result = rand_a | rand_b;
        end

        // XOR
        4: begin
            rand_funct3 = 3'b100;
            rand_result = rand_a ^ rand_b;
        end

        // SLL
        5: begin
            rand_funct3 = 3'b001;
            rand_result = rand_a << rand_b[4:0];
        end

        // SRL
        6: begin
            rand_funct3 = 3'b101;
            rand_result = rand_a >> rand_b[4:0];
        end

        // SRA
        7: begin
            rand_funct7 = 7'b0100000;
            rand_funct3 = 3'b101;
            rand_result = $signed(rand_a) >>> rand_b[4:0];
        end

        // SLT: signed comparison
        8: begin
            rand_funct3 = 3'b010;
            rand_result =
                ($signed(rand_a) < $signed(rand_b)) ? 32'd1 : 32'd0;
        end

        // SLTU: unsigned comparison
        9: begin
            rand_funct3 = 3'b011;
            rand_result =
                (rand_a < rand_b) ? 32'd1 : 32'd0;
        end

    endcase

    // Store the generated instruction.
    program_memory[314 + rand_i] = encode_r_type(
        rand_funct7,
        rand_rs2,
        rand_rs1,
        rand_funct3,
        rand_rd,
        OPCODE_R_TYPE
    );

    // Save the independent expected result.
    random_expected[rand_i] = rand_result;
    random_dest[rand_i] = rand_rd;

    // Update the reference model for the next instruction.
    model_regs[rand_rd] = rand_result;

end






// 32-bit Boundary-Value Verification
// Instructions 354 through 365


// Construct 0x80000000
program_memory[354] = encode_u_type(
    20'h80000, 5'd20, OPCODE_LUI
);  // LUI x20, 0x80000

// Construct 0x7FFFFFFF
program_memory[355] = encode_i_type(
    -12'sd1, 5'd20, 3'b000, 5'd21, OPCODE_I_TYPE
);  // ADDI x21, x20, -1

// Construct 0xFFFFFFFF
program_memory[356] = encode_i_type(
    -12'sd1, 5'd0, 3'b000, 5'd22, OPCODE_I_TYPE
);  // ADDI x22, x0, -1

// Addition boundary: 0x80000000 + 0x7FFFFFFF
program_memory[357] = encode_r_type(
    7'b0000000, 5'd21, 5'd20,
    3'b000, 5'd23, OPCODE_R_TYPE
);  // ADD x23, x20, x21

// Subtraction boundary: 0x80000000 - 0x7FFFFFFF
program_memory[358] = encode_r_type(
    7'b0100000, 5'd21, 5'd20,
    3'b000, 5'd24, OPCODE_R_TYPE
);  // SUB x24, x20, x21

// Signed comparison
program_memory[359] = encode_r_type(
    7'b0000000, 5'd21, 5'd20,
    3'b010, 5'd25, OPCODE_R_TYPE
);  // SLT x25, x20, x21

// Unsigned comparison
program_memory[360] = encode_r_type(
    7'b0000000, 5'd21, 5'd20,
    3'b011, 5'd26, OPCODE_R_TYPE
);  // SLTU x26, x20, x21

// Arithmetic right shift by 31
program_memory[361] = encode_i_type(
    12'h41F, 5'd20, 3'b101, 5'd27, OPCODE_I_TYPE
);  // SRAI x27, x20, 31

// Logical right shift by 31
program_memory[362] = encode_i_type(
    12'd31, 5'd20, 3'b101, 5'd28, OPCODE_I_TYPE
);  // SRLI x28, x20, 31

// Left shift of an all-ones value
program_memory[363] = encode_i_type(
    12'd1, 5'd22, 3'b001, 5'd29, OPCODE_I_TYPE
);  // SLLI x29, x22, 1

// XOR with all ones
program_memory[364] = encode_i_type(
    -12'sd1, 5'd22, 3'b100, 5'd30, OPCODE_I_TYPE
);  // XORI x30, x22, -1

// AND with a positive immediate boundary
program_memory[365] = encode_i_type(
    12'h7FF, 5'd22, 3'b111, 5'd31, OPCODE_I_TYPE
);  // ANDI x31, x22, 2047


// CORE-002B: RV32I byte/halfword load-store tests (little-endian).
// The original 345-instruction regression remains unchanged.
program_memory[366] = encode_s_type(12'd128, 5'd22, 5'd0, 3'b010, OPCODE_STORE); // SW x22,128(x0)
program_memory[367] = encode_i_type(12'd128, 5'd0, 3'b000, 5'd10, OPCODE_LOAD); // LB x10,128(x0)
program_memory[368] = encode_i_type(12'd129, 5'd0, 3'b100, 5'd11, OPCODE_LOAD); // LBU x11,129(x0)
program_memory[369] = encode_s_type(12'd130, 5'd21, 5'd0, 3'b001, OPCODE_STORE); // SH x21,130(x0)
program_memory[370] = encode_i_type(12'd130, 5'd0, 3'b001, 5'd12, OPCODE_LOAD); // LH x12,130(x0)
program_memory[371] = encode_i_type(12'd130, 5'd0, 3'b101, 5'd13, OPCODE_LOAD); // LHU x13,130(x0)
program_memory[372] = encode_s_type(12'd129, 5'd20, 5'd0, 3'b000, OPCODE_STORE); // SB x20,129(x0)
program_memory[373] = encode_i_type(12'd128, 5'd0, 3'b010, 5'd14, OPCODE_LOAD); // LW x14,128(x0), preserve other lanes
program_memory[374] = encode_s_type(12'd132, 5'd20, 5'd0, 3'b010, OPCODE_STORE); // SW x20,132(x0)
program_memory[375] = encode_i_type(12'd135, 5'd0, 3'b000, 5'd15, OPCODE_LOAD); // LB x15,135(x0): 0x80 -> sign extend
program_memory[376] = encode_i_type(12'd135, 5'd0, 3'b100, 5'd16, OPCODE_LOAD); // LBU x16,135(x0)
program_memory[377] = encode_i_type(12'd134, 5'd0, 3'b001, 5'd17, OPCODE_LOAD); // LH x17,134(x0)
program_memory[378] = encode_i_type(12'd134, 5'd0, 3'b101, 5'd18, OPCODE_LOAD); // LHU x18,134(x0)
program_memory[379] = encode_s_type(12'd134, 5'd21, 5'd0, 3'b001, OPCODE_STORE); // SH x21,134(x0)








        clk   = 1'b0;
        reset = 1'b1;
        #12;
        reset = 1'b0;

        repeat (31) begin
            @(posedge clk);
             instructions_executed = instructions_executed + 1;
            #1;

            $display(
            "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
            instructions_executed,
            current_pc,
            current_pc,
            instruction
            );
            
                

        end

 //  JALR verification
        check_register(26, 32'd164);
        check_register(27, 32'd156);
        check_register(28, 32'd0);
        check_register(30, 32'd0);
        check_register(29, 32'd88);

       
//  Check each ALU result immediately


repeat (7) begin
    @(posedge clk);

    instructions_executed = instructions_executed + 1;

    #1;

    $display(
        "ALU Test | Step=%0d | PC=%0d | Instruction=%08h",
        instructions_executed,
        current_pc,
        instruction
    );

    case (current_pc)

        // Index 42 executed; PC advances to 172.
        32'd172:
            check_register(31, 32'h00A00000);

        // Index 43 executed; PC advances to 176.
        32'd176:
            check_register(31, 32'h003FFFFF);

        // Index 44 executed; PC advances to 180.
        32'd180:
            check_register(31, 32'hFFFFFFFF);

        // Index 45 executed; PC advances to 184.
        32'd184:
            check_register(31, 32'd1);

        // Index 46 executed; PC advances to 188.
        32'd188:
            check_register(31, 32'd0);

        // Index 47 executed; PC advances to 192.
        32'd192:
            check_register(31, 32'd0);

        // Index 48 executed; PC advances to 196.
        32'd196:
            check_register(31, 32'd1);

        default: begin
            $display(
                "[ERROR] Unexpected PC during CORE-001G: %0d",
                current_pc
            );

            checks_failed = checks_failed + 1;
        end

    endcase
end



//  Verify x0 remains zero


repeat (6) begin

    @(posedge clk);

    instructions_executed = instructions_executed + 1;

    #1;

    case (current_pc)

        // Instruction 49 has executed.
        32'd200: begin
            check_register(0, 32'd0);
        end

        // Instruction 50 has executed.
        32'd204: begin
            check_register(31, 32'd5);
            check_register(0, 32'd0);
        end

        // Instruction 51 has executed.
        32'd208: begin
            check_register(0, 32'd0);
        end

        // Instruction 52 has executed.
        32'd212: begin
            check_register(30, 32'd7);
            check_register(0, 32'd0);
        end

        // Instruction 53 has executed.
        32'd216: begin
            check_register(0, 32'd0);
        end

        // Instruction 54 has executed.
        32'd220: begin
            check_register(29, 32'd9);
            check_register(0, 32'd0);
        end

        default: begin
            $display(
                "[ERROR] Unexpected PC during CORE-001H: %0d",
                current_pc
            );

            checks_failed = checks_failed + 1;
        end

    endcase

end













        check_register(1, 32'd10);
        check_register(2, 32'd20);
        check_register(3, 32'd30);
        check_register(4, 32'd20);


        check_register(5, 32'd0);
        check_register(6, 32'd30);
        check_register(7, 32'd30);
       
        // Verify load result.
        check_register(8, 32'd30);

        // Data memory verification
        check_memory(1, 32'd30);

        // The final target instruction must execute.
        check_register(9, 32'd99);

        // These registers must remain zero because the
        // six branch marker instructions should be skipped.
        check_register(10, 32'd0);
        check_register(11, 32'd0);
        check_register(12, 32'd0);
        check_register(13, 32'd0);
        check_register(14, 32'd0);
        check_register(15, 32'd0);


        check_register(16, 32'hFFFFFFFF);
        check_register(17, 32'd7);
        check_register(18, 32'd0);
        check_register(19, 32'd8);
        check_register(20, 32'd9);
        check_register(21, 32'd0);
        check_register(22, 32'd123);


        //  JAL verification
        check_register(23, 32'd140);
        check_register(24, 32'd0);
        check_register(25, 32'd77);



        // These checks must occur before CORE-001J executes.
        check_register(0,  32'd0);
        check_register(29, 32'd9);
        check_register(30, 32'd7);
        check_register(31, 32'd5);
            
       check_pc(32'd220);


       // Execute 14 load/store corner-case instructions

repeat (14) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;

    // Allow sequential updates to settle.
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end



// Register checks

check_register(9,  32'd10);         // Loaded from word 2 before overwrite
check_register(10, 32'd20);         // Loaded from word 3
check_register(11, 32'hFFFFFFFF);   // Loaded from word 4
check_register(12, 32'd30);         // Loaded from last valid word
check_register(13, 32'd10);         // Reloaded word 2 before overwrite
check_register(14, 32'd20);         // Word 2 after overwrite
check_register(15, 32'd20);         // Word 3 remains unchanged
check_register(17, 32'hFFFFFFFF);   // Word 4 retains its value
check_register(18, 32'd30);         // Last word retains its value

// Data-memory checks
// Arguments: word index, expected 32-bit value

check_memory(1,   32'd30);          // Existing data remains intact
check_memory(2,   32'd20);          // Updated word 2
check_memory(3,   32'd20);          // Independent word 3
check_memory(4,   32'hFFFFFFFF);    // Word 4
check_memory(255, 32'd30);          // Last valid word

// Program-counter check


// Execute three immediate ALU instructions
repeat (3) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;

    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end

//Register verification
check_register(19, 32'd5);
check_register(20, 32'd1);
check_register(21, 32'd0);

check_pc(32'd288);

// Execute logical immediate instructions
repeat (3) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;

    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end
        


check_register(22, 32'd5);
check_register(23, 32'd15);
check_register(24, 32'd4);

check_pc(32'd300);

//Execute shift immediate instructions
repeat (3) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;

    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end


check_register(25, 32'd40);
check_register(26, 32'h0FFFFFFF);
check_register(27, 32'hFFFFFFFF);

check_pc(32'd312);

//Execute LUI and AUIPC
repeat (2) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;

    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end


check_register(28, 32'h12345000);
check_register(29, 32'h0000113C);

check_pc(32'd320);



// Execute base-register load/store test




repeat (3) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;

    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end


// Base register
check_register(30, 32'd8);

// Loaded result
check_register(31, 32'd20);

// Data memory: word index 4 corresponds to byte address 16
check_memory(4, 32'd20);

// Final PC
check_pc(32'd332);




//  Execute negative-offset instructions




repeat (3) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;

    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end

check_register(30, 32'd24);
check_register(31, 32'd20);

check_memory(5, 32'd20);

check_pc(32'd344);





//  Execute different-base address test




repeat (4) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;

    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end


check_register(29, 32'd20);
check_register(30, 32'd16);
check_register(31, 32'd10);

check_memory(5, 32'd10);

check_pc(32'd360);






repeat (3) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end

check_memory(4, 32'd20);
check_register(31, 32'd20);
check_pc(32'd372);



repeat (2) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end

check_register(28, 32'd20);
check_register(27, 32'd20);
check_memory(4, 32'd20);
check_pc(32'd380);






repeat (3) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end


check_register(30, 32'd1020);
check_memory(255, 32'd10);
check_register(31, 32'd10);
check_pc(32'd392);




repeat (3) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end


check_register(30, 32'd0);
check_memory(0, 32'd10);
check_register(31, 32'd10);
check_memory(0,   32'd10);
check_memory(255, 32'd10);
check_pc(32'd404);



// Negative Value Store/Load
repeat (4) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end


check_register(26, 32'hFFFFFFFF);
check_register(30, 32'd4);
check_memory(1, 32'hFFFFFFFF);
check_register(25, 32'hFFFFFFFF);
check_pc(32'd420);






repeat (4) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end


check_register(24, 32'hA5C3F00F);
check_memory(1, 32'hA5C3F00F);
check_register(23, 32'hA5C3F00F);
check_pc(32'd436);




repeat (13) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end



// Base register
check_register(30, 32'd0);

// Verify loaded values
check_register(15, 32'd10);
check_register(14, 32'd20);
check_register(13, 32'd5);
check_register(12, 32'd1);
check_register(11, 32'hA5C3F00F);
check_register(10, 32'hFFFFFFFF);

// Verify memory-word mapping
check_memory(0,   32'd10);
check_memory(1,   32'd20);
check_memory(2,   32'd5);
check_memory(3,   32'd1);
check_memory(4,   32'hA5C3F00F);
check_memory(255, 32'hFFFFFFFF);

// Verify final PC
check_pc(32'd488);





repeat (4) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end




check_register(9, 32'h00000000);
check_register(8, 32'h000007FF);
check_register(7, 32'hFFFFF800);
check_register(6, 32'hFFFFFFFF);

check_pc(32'd504);



repeat (9) begin
    @(posedge clk);
    instructions_executed = instructions_executed + 1;
    #1;

    $display(
        "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
        instructions_executed,
        current_pc,
        current_pc,
        instruction
    );
end






// Q-B1: Positive offset
check_register(15, 32'd10);
check_memory(3, 32'd10);

// Q-B2: Negative offset
check_register(14, 32'd20);
check_memory(5, 32'd20);

// Q-B3: Negative offset reaching address zero
check_register(13, 32'd5);
check_memory(0, 32'd5);

// Final program counter
check_pc(32'd540);



repeat (3) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end




check_register(10, 32'h00000000);
check_register(11, 32'hFFFFFFFF);
check_register(12, 32'hFFFFF800);



repeat (7) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end


check_register(13, 32'h80000000);
check_register(14, 32'h7FFFFFFF);
check_register(15, 32'h00000000);




repeat (6) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end



// CORE-001R-C expected results

check_register(12, 32'd1);
check_register(13, 32'd0);
check_register(14, 32'd0);
check_register(15, 32'd1);






repeat (11) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end



// CORE-001R-D expected results

// SLLI
check_register(16, 32'h00000001);
check_register(17, 32'h00000002);
check_register(18, 32'h80000000);

// SRLI
check_register(19, 32'h80000000);
check_register(20, 32'h40000000);
check_register(21, 32'h00000001);

// SRAI
check_register(22, 32'h80000000);
check_register(23, 32'hC0000000);
check_register(24, 32'hFFFFFFFF);





repeat (3) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end




// CORE-001S-A expected results

check_register(5, 32'd10);
check_register(6, 32'd15);
check_register(7, 32'd25);




repeat (5) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end



// expected results

check_register(5, 32'd18);
check_register(6, 32'd20);
check_register(7, 32'd38);




repeat (6) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end



check_register(8,  32'd8);
check_register(9,  32'd18);
check_register(28, 32'd3);
check_register(29, 32'd21);




repeat (4) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(10, 32'd30);
check_register(11, 32'd20);
check_register(12, 32'd50);


repeat (4) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end


check_register(10, 32'd7);
check_register(0,  32'd0);
check_register(11, 32'd7);
check_register(12, 32'd1);


repeat (4) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(5, 32'd10);
check_register(6, 32'd123);
check_register(7, 32'd20);
check_pc(32'd756);


repeat (8) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end


check_register(8,  32'd2);
check_register(9,  32'd2);
check_register(10, 32'd77);

// PC after executing the instruction at index 193.
check_pc(32'd776);



repeat (6) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

// CORE-001T-C expected results

check_register(13, 32'd55);
check_memory(10, 32'd55);
check_pc(32'd804);



repeat (15) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end



check_register(12, 32'd3);
check_register(13, 32'd3);
check_register(14, 32'd55);

check_memory(10, 32'd55);

check_pc(32'd844);



repeat (3) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end






repeat (5) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(5,  32'd10);
check_register(6,  32'd66);
check_register(7,  32'd77);
check_register(8,  32'd42);
check_register(20, 32'd860);

check_pc(32'd884);



repeat (2) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(10, 32'd905);
check_register(6,  32'd66);
check_register(7,  32'd77);
check_register(8,  32'd42);
check_register(11, 32'd888);
check_pc(32'd908);



repeat (5) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(12, 32'd932);
check_register(13, 32'd33);
check_register(15, 32'd55);
check_register(14, 32'd924);
check_register(16, 32'd42);
check_pc(32'd940);



repeat (5) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(17, 32'd964);
check_register(18, 32'd18);
check_register(19, 32'd19);
check_register(20, 32'd956);
check_register(21, 32'd42);
check_pc(32'd964);



check_pc(32'd964);

repeat (4) begin
    @(posedge clk);
    instructions_executed++;
    #1;
    
end

check_register(22, 32'd1);
check_register(23, 32'd1);
check_register(24, 32'd10);
check_register(21, 32'd42);
check_pc(32'd984);


repeat (1) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(25, 32'd988);
check_pc(32'd992);



repeat (3) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(26, 32'd1017);
check_register(28, 32'd1000);
check_register(29, 32'd29);
check_pc(32'd1016);







repeat (4) begin
    @(posedge clk);
    instructions_executed++;
    #1;
    
end


check_register(30, 32'd40);
check_register(31, 32'd99);
check_register(18, 32'd55);
check_memory(10, 32'd55);
check_pc(32'd1036);



check_pc(32'd1036);

repeat (6) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(5, 32'd64);
check_register(6, 32'd123);
check_register(7, 32'd123);
check_register(8, 32'd124);
check_register(9, 32'd247);
check_memory(16, 32'd123);
check_pc(32'd1060);


check_pc(32'd1060);

repeat (4) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(10, 32'd123);
check_register(11, 32'd123);
check_register(12, 32'd42);
check_pc(32'd1080);

check_pc(32'd1080);

repeat (5) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(13, 32'd80);
check_register(14, 32'd123);
check_register(15, 32'd123);
check_register(16, 32'd46);
check_memory(20, 32'd123);
check_pc(32'd1100);

check_pc(32'd1100);

repeat (4) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(17, 32'd123);
check_register(18, 32'd124);
check_register(19, 32'd7);
check_pc(32'd1116);







check_pc(32'd1116);

repeat (7) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(20, 32'hFFFFFFF9);
check_register(21, 32'd3);
check_register(22, 32'hFFFFFFFC);
check_register(23, 32'd88);
check_register(24, 32'hFFFFFFFC);
check_register(25, 32'hFFFFFFFB);
check_memory(22, 32'hFFFFFFFC);
check_pc(32'd1144);






check_pc(32'd1144);

repeat (6) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(26, 32'hFFFFFFFF);
check_register(27, 32'd1);
check_register(28, 32'd1);
check_register(29, 32'd0);
check_register(30, 32'd0);
check_register(31, 32'd1);
check_pc(32'd1168);




check_pc(32'd1168);

repeat (4) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(10, 32'hFFFFFFFC);
check_register(11, 32'hFFFFFFFC);
check_register(12, 32'd42);
check_pc(32'd1188);




check_pc(32'd1188);

repeat (6) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(14, 32'hFFFFFFFD);
check_register(15, 32'd96);
check_register(16, 32'hFFFFFFFD);
check_register(17, 32'hFFFFFFFE);
check_register(18, 32'hFFFFFFF1);
check_memory(24, 32'hFFFFFFFD);
check_pc(32'd1212);








check_pc(32'd1212);

repeat (11) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(5, 32'd1);
check_register(6, 32'd2);
check_register(7, 32'd3);
check_register(8, 32'd4);
check_register(9, 32'd5);
check_register(10, 32'd6);
check_register(11, 32'd7);
check_register(12, 32'd8);
check_register(13, 32'd9);
check_register(14, 32'd10);
check_register(15, 32'd11);

check_pc(32'd1256);



//random instructions 
for (rand_i = 0; rand_i < 40; rand_i = rand_i + 1) begin

    @(posedge clk);
    instructions_executed++;
    #1;

    check_register(
        random_dest[rand_i],
        random_expected[rand_i]
    );

end

check_pc(32'd1416);

$display("ADD  : %0d", alu_op_coverage[0]);
$display("SUB  : %0d", alu_op_coverage[1]);
$display("AND  : %0d", alu_op_coverage[2]);
$display("OR   : %0d", alu_op_coverage[3]);
$display("XOR  : %0d", alu_op_coverage[4]);
$display("SLL  : %0d", alu_op_coverage[5]);
$display("SRL  : %0d", alu_op_coverage[6]);
$display("SRA  : %0d", alu_op_coverage[7]);
$display("SLT  : %0d", alu_op_coverage[8]);
$display("SLTU : %0d", alu_op_coverage[9]);


check_pc(32'd1416);

repeat (12) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end

check_register(20, 32'h80000000);
check_register(21, 32'h7FFFFFFF);
check_register(22, 32'hFFFFFFFF);
check_register(23, 32'hFFFFFFFF);
check_register(24, 32'h00000001);
check_register(25, 32'h00000001);
check_register(26, 32'h00000000);
check_register(27, 32'hFFFFFFFF);
check_register(28, 32'h00000001);
check_register(29, 32'hFFFFFFFE);
check_register(30, 32'h00000000);
check_register(31, 32'h000007FF);

// Execute the 14 CORE-002B load/store instructions.
repeat (14) begin
    @(posedge clk);
    instructions_executed++;
    #1;
end
check_register(10, 32'hFFFFFFFF); // LB sign extension
check_register(11, 32'h000000FF); // LBU zero extension
check_register(12, 32'hFFFFFFFF); // LH sign extension
check_register(13, 32'h0000FFFF); // LHU zero extension
check_register(14, 32'hFFFF00FF); // SB changed only byte lane 1
check_register(15, 32'hFFFFFF80); // LB of byte 0x80
check_register(16, 32'h00000080); // LBU of byte 0x80
check_register(17, 32'hFFFF8000); // LH of halfword 0x8000
check_register(18, 32'h00008000); // LHU of halfword 0x8000
check_memory(32, 32'hFFFF00FF);   // word at byte address 128
check_memory(33, 32'hFFFF0000);   // SH updates upper halfword at address 134
check_pc(32'd1520);

check_register(0, 32'd0);













// Wait for the falling edge so that reset is asserted
// between rising clock edges.
@(negedge clk);

reset = 1'b1;
#1;

// The PC uses synchronous reset.
// Therefore, it should still hold its previous value.
check_pc(32'd1520);

// Previously written register values should be cleared.
check_register(1, 32'd0);
check_register(2, 32'd0);
check_register(3, 32'd0);
check_register(8, 32'd0);
check_register(16, 32'd0);
check_register(31, 32'd0);



//  Keep reset active through the rising edge.
//
// The PC should now reset to zero.
// The register file should remain cleared.


@(posedge clk);
#1;



check_pc(32'd0);

check_register(1, 32'd0);
check_register(2, 32'd0);
check_register(3, 32'd0);
check_register(8, 32'd0);
check_register(16, 32'd0);
check_register(31, 32'd0);



//  Release reset and execute instruction 0.
//
// Instruction:
//     addi x1, x0, 10
//
// Expected after this instruction:
//     x1 = 10
//     x2 = 0
//     PC = 4


@(negedge clk);

reset = 1'b0;

@(posedge clk);

instructions_executed = instructions_executed + 1;

#1;



$display(
    "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
    instructions_executed,
    current_pc,
    current_pc,
    instruction
);

check_pc(32'd4);

check_register(1, 32'd10);
check_register(2, 32'd0);



// Execute instruction 1.
// Instruction:
//     addi x2, x0, 20
// Expected after this instruction:
//     x1 = 10
//     x2 = 20
//     PC = 8


@(posedge clk);

instructions_executed = instructions_executed + 1;

#1;



$display(
    "Step=%0d | PC=%0d (0x%08h) | Instruction=%08h",
    instructions_executed,
    current_pc,
    current_pc,
    instruction
);

check_pc(32'd8);

check_register(1, 32'd10);
check_register(2, 32'd20);






// ============================================================
// CORE-002A: Instruction Coverage Report
// ============================================================

$display("");
$display("========================================");
$display(" INSTRUCTION OPCODE COVERAGE REPORT");
$display("========================================");

opcode_coverage_total = 0;

for (opcode_cov_i = 0;
     opcode_cov_i < 128;
     opcode_cov_i = opcode_cov_i + 1) begin

    if (opcode_coverage[opcode_cov_i] != 0) begin

        $display(
            "Opcode 0x%02h : Executed %0d times",
            opcode_cov_i,
            opcode_coverage[opcode_cov_i]
        );

        opcode_coverage_total =
            opcode_coverage_total +
            opcode_coverage[opcode_cov_i];

    end

end

$display("----------------------------------------");

$display(
    "Total instructions counted by monitor: %0d",
    opcode_coverage_total
);
$display("");
$display("LOAD funct3 coverage: 000=LB, 001=LH, 010=LW, 100=LBU, 101=LHU");
for (opcode_cov_i = 0; opcode_cov_i < 8; opcode_cov_i = opcode_cov_i + 1)
    if (load_funct3_coverage[opcode_cov_i] != 0)
        $display("  load funct3 %03b : %0d", opcode_cov_i, load_funct3_coverage[opcode_cov_i]);
$display("STORE funct3 coverage: 000=SB, 001=SH, 010=SW");
for (opcode_cov_i = 0; opcode_cov_i < 8; opcode_cov_i = opcode_cov_i + 1)
    if (store_funct3_coverage[opcode_cov_i] != 0)
        $display("  store funct3 %03b : %0d", opcode_cov_i, store_funct3_coverage[opcode_cov_i]);

$display("========================================");
$display("");





        //final verification report
$display("Instructions executed : %0d", instructions_executed);
$display("Checks passed         : %0d", checks_passed);
$display("Checks failed         : %0d", checks_failed);


if (checks_failed == 0) begin
    $display("status passed ");
end

else begin
    $display("status failed ");
end

if (checks_failed != 0)
    $fatal(1, " core verification failed.");

 $finish;

 
end
endmodule