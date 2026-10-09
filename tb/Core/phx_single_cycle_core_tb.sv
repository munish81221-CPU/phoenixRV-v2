`timescale 1ns/1ps

module phx_single_cycle_core_tb;
    // Clock and Reset
    logic clk;
    logic reset;
    // Instruction Interface
    logic [31:0] instruction;
    logic [31:0] current_pc;






    // Temporary Instruction Memory
    logic [31:0] program_memory [0:63];

    
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
    assign instruction = program_memory[current_pc[7:2]];

    localparam logic [6:0] OPCODE_R_TYPE = 7'b0110011;
    localparam logic [6:0] OPCODE_I_TYPE = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD  = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JAL  = 7'b1101111;
    localparam logic [6:0] OPCODE_JALR = 7'b1100111;

    localparam logic [2:0] FUNCT3_ADD_SUB = 3'b000;

    localparam logic [6:0] FUNCT7_ADD = 7'b0000000;
    localparam logic [6:0] FUNCT7_SUB = 7'b0100000;

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
initial begin

        checks_passed = 0;
        checks_failed = 0;
        instructions_executed = 0;


        $dumpfile("phx_single_cycle_core.vcd");
        $dumpvars(0, phx_single_cycle_core_tb);


        for (i = 0; i < 64; i = i + 1)
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

        //  JALR verification
        check_register(26, 32'd164);
        check_register(27, 32'd156);
        check_register(28, 32'd0);
        check_register(30, 32'd0);
        check_register(29, 32'd88);



        check_pc(32'd168);



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