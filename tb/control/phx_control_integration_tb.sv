`timescale 1ns/1ps
module phx_control_integration_tb; 
    logic[31:0] instruction;
    logic       branch_taken;
    logic       reg_write;
    logic       alu_src_a;
    logic       alu_src;
    logic       mem_read;
    logic       mem_write;
    logic [1:0] wb_select;

    logic [3:0] alu_control;

    logic       branch;
    logic       jump;
    logic       jump_reg;

    logic [1:0] pc_select;

phx_control_integration DUT (
           .instruction(instruction),
           .branch_taken(branch_taken),
           .reg_write(reg_write),
           .alu_src_a(alu_src_a),
           .alu_src(alu_src),
           .mem_read(mem_read),
           .mem_write(mem_write),
           .wb_select(wb_select),
           .alu_control(alu_control),
           .branch(branch),
           .jump(jump),
           .jump_reg(jump_reg),
           .pc_select(pc_select)
);

typedef struct packed {

    logic       reg_write;
    logic       alu_src_a;
    logic       alu_src;
    logic       mem_read;
    logic       mem_write;
    logic [1:0] wb_select;

    logic [3:0] alu_control;

    logic       branch;
    logic       jump;
    logic       jump_reg;

    logic [1:0] pc_select;

} control_t;

control_t expected;
control_t actual;



typedef struct packed {
    logic [31:0] instruction;
    logic        branch_taken;
} stimulus_t;


function automatic control_t expected_main_control(
    input logic [31:0] instr
);

    logic [6:0] opcode;
    control_t result;


    opcode = instr[6:0];

    result = '0;

    case (opcode)

        // R-type
        7'b0110011: begin
            result.reg_write = 1'b1;
            result.wb_select = 2'b00;
        end

        // I-type ALU
        7'b0010011: begin
            result.reg_write = 1'b1;
            result.alu_src   = 1'b1;
            result.wb_select = 2'b00;
        end

       
       
        // Load Word (LW)
        7'b0000011: begin
            result.reg_write = 1'b1;
            result.alu_src   = 1'b1;
            result.mem_read  = 1'b1;
            result.wb_select = 2'b01;
        end

        // Store Word (SW)
        7'b0100011: begin
            
             result.alu_src   = 1'b1;
             result.mem_write = 1'b1;
             result.wb_select = 2'b00;
        end

        // Conditional Branch
        7'b1100011: begin
            
             result.branch    = 1'b1;
        end

        // Load Upper Immediate (LUI)
        7'b0110111: begin
             result.reg_write = 1'b1;
             result.wb_select = 2'b11;
        end

        // Add Upper Immediate to PC (AUIPC)
        7'b0010111: begin
             result.reg_write = 1'b1;
             result.alu_src_a = 1'b1;
             result.alu_src   = 1'b1;
             result.wb_select = 2'b00;
        end

        // Jump and Link (JAL)
        7'b1101111: begin
             result.reg_write = 1'b1;
             result.wb_select = 2'b10;
             result.jump      = 1'b1;
            
        end

        // Jump and Link Register (JALR)
        7'b1100111: begin
             result.reg_write = 1'b1;
             result.alu_src   = 1'b1;
             result.wb_select = 2'b10;
             result.jump      = 1'b1;
             result.jump_reg  = 1'b1;
        end


    endcase

    return result;

endfunction

function automatic logic [3:0] expected_alu_control(
    input logic [31:0] instr
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    opcode = instr[6:0];
    funct3 = instr[14:12];
    funct7 = instr[31:25];

    expected_alu_control = 4'b0000;

    case (opcode)

    7'b0110011: begin

        case ({funct7, funct3})

            10'b0000000000:
                expected_alu_control = 4'b0000; // ADD

            10'b0100000000:
                expected_alu_control = 4'b0001; // SUB

           
                
            10'b0000000111:
                expected_alu_control=4'b0010;//AND
                

              
            10'b0000000110:
                expected_alu_control=4'b0011; //OR
                

                
            10'b0000000100:
                expected_alu_control=4'b0100;//XOR
                
               	
            10'b0000000001:	
                expected_alu_control=4'b0101;
                
                	
            10'b0000000101:	
                expected_alu_control=4'b0110;//SRL
                
                	
            10'b0100000101:	
                expected_alu_control=4'b0111;//SRA
                
                	
            10'b0000000010:	
                expected_alu_control=4'b1000;//SLT
                
                	
            10'b0000000011:
                expected_alu_control=4'b1001;//SLTU
                
            default:
            expected_alu_control = 4'b0000;
                
            endcase
    end
     7'b0010011:begin 

        case (funct3)

        // ADDI
        3'b000: 
            expected_alu_control = 4'b0000;
        

        // SLTI
        3'b010: 
            expected_alu_control = 4'b1000;
        

        // SLTIU
        3'b011: 
            expected_alu_control = 4'b1001;
        

        // XORI
        3'b100: 
            expected_alu_control = 4'b0100;
        

        // ORI
        3'b110: 
            expected_alu_control = 4'b0011;
        

        // ANDI
        3'b111: 
            expected_alu_control = 4'b0010;
        

        // SLLI
        3'b001: 
            if (funct7 == 7'b0000000)
                expected_alu_control = 4'b0101;
            else
                expected_alu_control = 4'b0000;
        

        // SRLI / SRAI
        3'b101: 

            case (funct7)

                // SRLI
                7'b0000000: 
                    expected_alu_control = 4'b0110;
                

                // SRAI
                7'b0100000: 
                    expected_alu_control = 4'b0111;
                

                default: 
                    expected_alu_control = 4'b0000;
                

            endcase

        

        default: 
            expected_alu_control = 4'b0000;
        

        endcase
     end 

        

        
        7'b0000011:begin
            expected_alu_control=4'b0000;
        end
        7'b0100011:begin
            expected_alu_control=4'b0000;
        end
        7'b1100011:begin
            expected_alu_control=4'b0001;
        end
        7'b0010111:begin
            expected_alu_control=4'b0000;
        end
        7'b1100111:begin
            expected_alu_control=4'b0000;
        end
        7'b0110111:begin
            expected_alu_control=4'b0000;
        end
        default: 
        expected_alu_control=4'b0000;
    endcase

endfunction

function automatic logic [1:0] expected_pc_select(
    input logic branch,
    input logic branch_taken,
    input logic jump,
    input logic jump_reg
);

    expected_pc_select = 2'b00;

    if (jump && jump_reg)
        expected_pc_select = 2'b11;

    else if (jump)
        expected_pc_select = 2'b10;

    else if (branch && branch_taken)
        expected_pc_select = 2'b01;

endfunction


function automatic control_t calculate_expected(
    input logic [31:0] instr,
    input logic        br_taken
);

    control_t main_expected;

    begin
        // Get main-control reference result
        main_expected = expected_main_control(instr);

        // Start with all outputs inactive
        calculate_expected = '0;

        // Main-control outputs
        calculate_expected.reg_write  = main_expected.reg_write;
        calculate_expected.alu_src_a  = main_expected.alu_src_a;
        calculate_expected.alu_src    = main_expected.alu_src;
        calculate_expected.mem_read   = main_expected.mem_read;
        calculate_expected.mem_write  = main_expected.mem_write;
        calculate_expected.wb_select  = main_expected.wb_select;

        // ALU decoder reference
        calculate_expected.alu_control =
            expected_alu_control(instr);

        // Main-control branch/jump outputs
        calculate_expected.branch   = main_expected.branch;
        calculate_expected.jump     = main_expected.jump;
        calculate_expected.jump_reg = main_expected.jump_reg;

        // PC selection reference
        calculate_expected.pc_select =
            expected_pc_select(
                main_expected.branch,
                br_taken,
                main_expected.jump,
                main_expected.jump_reg
            );
    end

endfunction



typedef enum {
    TEST_R_TYPE,
    TEST_I_TYPE,
    TEST_MEMORY,
    TEST_BRANCH,
    TEST_JUMP,
    TEST_UPPER_IMM,
    TEST_RANDOM,

    TEST_RANDOM_R,
    TEST_RANDOM_I,
    TEST_RANDOM_MEMORY,
    TEST_RANDOM_BRANCH,
    TEST_RANDOM_JUMP
} test_category_t;



test_category_t current_category;

integer passed_count;
integer failed_count;


task automatic run_test(
    input stimulus_t stimulus,
    input test_category_t category
);

    current_category = category;

    // Drive DUT
    instruction  = stimulus.instruction;
    branch_taken = stimulus.branch_taken;

    // Reference model
    expected = calculate_expected(
        stimulus.instruction,
        stimulus.branch_taken
    );

    // Allow combinational DUT to settle
    #1;

    // Capture DUT
    actual.reg_write   = reg_write;
    actual.alu_src_a   = alu_src_a;
    actual.alu_src     = alu_src;
    actual.mem_read    = mem_read;
    actual.mem_write   = mem_write;
    actual.wb_select   = wb_select;
    actual.alu_control = alu_control;
    actual.branch      = branch;
    actual.jump        = jump;
    actual.jump_reg    = jump_reg;
    actual.pc_select   = pc_select;

    // Self-check
    assert (actual === expected)
    begin
        passed_count++;

        $display(
            "PASS [%s] instruction=%h branch_taken=%b",
            category.name(),
            stimulus.instruction,
            stimulus.branch_taken
        );
    end
    else
    begin
        failed_count++;

        $error(
            "FAIL [%s] instruction=%h branch_taken=%b\n actual   = %b\n expected = %b",
            category.name(),
            stimulus.instruction,
            stimulus.branch_taken,
            actual,
            expected
        );
    end

endtask




task automatic apply_test(
    input logic [31:0] instr,
    input logic        br_taken,
    input test_category_t category
);

    stimulus_t s;

    s.instruction  = instr;
    s.branch_taken = br_taken;

    run_test(s, category);

endtask



//random R-type generator 
function automatic logic [31:0] random_r_instruction;

    integer op;

    logic [4:0] rd;
    logic [4:0] rs1;
    logic [4:0] rs2;

    logic [6:0] funct7;
    logic [2:0] funct3;

    begin

        op = $urandom_range(0,9);

        rd  = $urandom_range(0,31);
        rs1 = $urandom_range(0,31);
        rs2 = $urandom_range(0,31);

        case (op)

            0: begin funct7=7'b0000000; funct3=3'b000; end
            1: begin funct7=7'b0100000; funct3=3'b000; end
            2: begin funct7=7'b0000000; funct3=3'b111; end
            3: begin funct7=7'b0000000; funct3=3'b110; end
            4: begin funct7=7'b0000000; funct3=3'b100; end
            5: begin funct7=7'b0000000; funct3=3'b001; end
            6: begin funct7=7'b0000000; funct3=3'b101; end
            7: begin funct7=7'b0100000; funct3=3'b101; end
            8: begin funct7=7'b0000000; funct3=3'b010; end
            9: begin funct7=7'b0000000; funct3=3'b011; end

        endcase

        random_r_instruction =
        {
            funct7,
            rs2,
            rs1,
            funct3,
            rd,
            7'b0110011
        };

    end

endfunction


//random I-type generator 
function automatic logic [31:0] random_i_instruction;

    logic [4:0] rd;
    logic [4:0] rs1;
    logic [11:0] imm;

    logic [2:0] funct3;
    logic [6:0] funct7;

    integer op;

    begin

        rd  = $urandom_range(0,31);
        rs1 = $urandom_range(0,31);
        imm = $urandom;

        op = $urandom_range(0,8);

        funct7 = 7'b0000000;

        case (op)

            0: funct3 = 3'b000;
            1: funct3 = 3'b010;
            2: funct3 = 3'b011;
            3: funct3 = 3'b100;
            4: funct3 = 3'b110;
            5: funct3 = 3'b111;
            6: funct3 = 3'b001;

            7: funct3 = 3'b101;

            8: begin
                funct3 = 3'b101;
                funct7 = 7'b0100000;
            end

        endcase

        // Shift instructions require a restricted immediate upper field
        if ((funct3 == 3'b001) ||
            (funct3 == 3'b101))
            imm = {funct7, imm[4:0]};

        random_i_instruction =
        {
            imm,
            rs1,
            funct3,
            rd,
            7'b0010011
        };

    end

endfunction



//other instruction class
function automatic logic [31:0] random_lw_instruction;

    logic [4:0] rd;
    logic [4:0] rs1;
    logic [11:0] imm;

    begin

        rd  = $urandom_range(0,31);
        rs1 = $urandom_range(0,31);
        imm = $urandom;

        random_lw_instruction =
        {
            imm,
            rs1,
            3'b010,
            rd,
            7'b0000011
        };

    end

endfunction


//other invalid encoding testing 
function automatic logic [31:0] random_invalid_r;

    begin

        random_invalid_r = {
            $urandom_range(0,127),
            $urandom_range(0,31),
            $urandom_range(0,31),
            $urandom_range(0,7),
            $urandom_range(0,31),
            7'b0110011
        };

    end

endfunction


task automatic test_r_type();

    // ADD
    apply_test(
        32'h001101B3,
        1'b0,
        TEST_R_TYPE
    );

    // SUB
    apply_test(
        32'h401101B3,
        1'b0,
        TEST_R_TYPE
    );

    // AND
    apply_test(
        32'h001171B3,
        1'b0,
        TEST_R_TYPE
    );

    // OR
    apply_test(
        32'h001161B3,
        1'b0,
        TEST_R_TYPE
    );

    // XOR
    apply_test(
        32'h001141B3,
        1'b0,
        TEST_R_TYPE
    );

    // SLL
    apply_test(
        32'h001111B3,
        1'b0,
        TEST_R_TYPE
    );

    // SRL
    apply_test(
        32'h001151B3,
        1'b0,
        TEST_R_TYPE
    );

    // SRA
    apply_test(
        32'h401151B3,
        1'b0,
        TEST_R_TYPE
    );

    // SLT
    apply_test(
        32'h001121B3,
        1'b0,
        TEST_R_TYPE
    );

    // SLTU
    apply_test(
        32'h001131B3,
        1'b0,
        TEST_R_TYPE
    );

endtask


task automatic test_i_type();

    // ADDI
    apply_test(
        32'h00508113,
        1'b0,
        TEST_I_TYPE
    );

    // SLTI
    apply_test(
        32'h0050A113,
        1'b0,
        TEST_I_TYPE
    );

    // SLTIU
    apply_test(
        32'h0050B113,
        1'b0,
        TEST_I_TYPE
    );

    // XORI
    apply_test(
        32'h0050C113,
        1'b0,
        TEST_I_TYPE
    );

    // ORI
    apply_test(
        32'h0050E113,
        1'b0,
        TEST_I_TYPE
    );

    // ANDI
    apply_test(
        32'h0050F113,
        1'b0,
        TEST_I_TYPE
    );

    // SLLI
    apply_test(
        32'h00509113,
        1'b0,
        TEST_I_TYPE
    );

    // SRLI
    apply_test(
        32'h0050D113,
        1'b0,
        TEST_I_TYPE
    );

    // SRAI
    apply_test(
        32'h4050D113,
        1'b0,
        TEST_I_TYPE
    );

endtask

task automatic test_memory();

    // LW
    apply_test(
        32'h0080A103,
        1'b0,
        TEST_MEMORY
    );

    // SW
    apply_test(
        32'h0020A423,
        1'b0,
        TEST_MEMORY
    );

endtask

task automatic test_branch();

    // Not taken
    apply_test(
        32'h00208063,
        1'b0,
        TEST_BRANCH
    );

    // Taken
    apply_test(
        32'h00208063,
        1'b1,
        TEST_BRANCH
    );

endtask


task automatic test_upper_immediate();

    // AUIPC
    apply_test(
        32'h00001117,
        1'b0,
        TEST_UPPER_IMM
    );

    // LUI
    apply_test(
        32'h00001137,
        1'b0,
        TEST_UPPER_IMM
    );

endtask



task automatic test_jump();

    // JAL
    apply_test(
        32'h001000EF,
        1'b0,
        TEST_JUMP
    );

    // JALR
    apply_test(
        32'h00808167,
        1'b0,
        TEST_JUMP
    );

endtask



task automatic test_random_r_type(input integer count);

    integer op;
    logic [6:0] rand_funct7;
    logic [2:0] rand_funct3;


    logic [31:0] random_instr;
    repeat (count) begin

        


        op = $urandom_range(0,9);

        case (op)

            0: begin
                rand_funct7 = 7'b0000000;
                rand_funct3 = 3'b000;       // ADD
            end

            1: begin
                rand_funct7 = 7'b0100000;
                rand_funct3 = 3'b000;       // SUB
            end

            2: begin
                rand_funct7 = 7'b0000000;
                rand_funct3 = 3'b111;       // AND
            end

            3: begin
                rand_funct7 = 7'b0000000;
                rand_funct3 = 3'b110;       // OR
            end

            4: begin
                rand_funct7 = 7'b0000000;
                rand_funct3 = 3'b100;       // XOR
            end

            5: begin
                rand_funct7 = 7'b0000000;
                rand_funct3 = 3'b001;       // SLL
            end

            6: begin
                rand_funct7 = 7'b0000000;
                rand_funct3 = 3'b101;       // SRL
            end

            7: begin
                rand_funct7 = 7'b0100000;
                rand_funct3 = 3'b101;       // SRA
            end

            8: begin
                rand_funct7 = 7'b0000000;
                rand_funct3 = 3'b010;       // SLT
            end

            9: begin
                rand_funct7 = 7'b0000000;
                rand_funct3 = 3'b011;       // SLTU
            end

        endcase

      
    random_instr = {
    rand_funct7,
    $urandom_range(0,31),
    $urandom_range(0,31),
    rand_funct3,
    $urandom_range(0,31),
    7'b0110011
};

apply_test(
    random_instr,
    1'b0,
    TEST_RANDOM
);  

    end

endtask

task automatic test_random_i_type(input integer count);

    integer op;
    integer rd;
    integer rs1;
    integer imm;

    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [31:0] random_instr;

    repeat (count) begin

        op  = $urandom_range(0,8);

        rd  = $urandom_range(0,31);
        rs1 = $urandom_range(0,31);

        // 5-bit immediate is enough for this control test
        imm = $urandom_range(0,31);

        funct7 = 7'b0000000;

        case (op)

            // ADDI
            0: funct3 = 3'b000;

            // SLTI
            1: funct3 = 3'b010;

            // SLTIU
            2: funct3 = 3'b011;

            // XORI
            3: funct3 = 3'b100;

            // ORI
            4: funct3 = 3'b110;

            // ANDI
            5: funct3 = 3'b111;

            // SLLI
            6: begin
                funct3 = 3'b001;
                funct7 = 7'b0000000;
            end

            // SRLI
            7: begin
                funct3 = 3'b101;
                funct7 = 7'b0000000;
            end

            // SRAI
            8: begin
                funct3 = 3'b101;
                funct7 = 7'b0100000;
            end

            default: begin
                funct3 = 3'b000;
                funct7 = 7'b0000000;
            end

        endcase

        random_instr = {
            funct7,
            imm[4:0],
            rs1[4:0],
            funct3,
            rd[4:0],
            7'b0010011
        };

        apply_test(
            random_instr,
            1'b0,
            TEST_RANDOM
        );

    end

endtask

task automatic test_random_memory(input integer count);

    integer op;
    integer rd_rs2;
    integer rs1;
    integer imm;

    logic [31:0] random_instr;

    repeat (count) begin

        op = $urandom_range(0,1);

        rd_rs2 = $urandom_range(0,31);
        rs1    = $urandom_range(0,31);
        imm    = $urandom_range(0,31);

        case (op)

            // LW
            0: begin

                random_instr = {
                    7'b0000000,
                    rs1[4:0],
                    3'b010,
                    rd_rs2[4:0],
                    7'b0000011
                };

                apply_test(
                    random_instr,
                    1'b0,
                    TEST_RANDOM
                );

            end

            // SW
            1: begin

                random_instr = {
                    7'b0000000,
                    rd_rs2[4:0],
                    rs1[4:0],
                    3'b010,
                    imm[4:0],
                    7'b0100011
                };

                apply_test(
                    random_instr,
                    1'b0,
                    TEST_RANDOM
                );

            end

        endcase

    end

endtask


task automatic test_random_branch(input integer count);

    integer branch_type;
    integer rs1;
    integer rs2;
    integer imm;

    logic [2:0] funct3;
    logic [31:0] random_instr;

    repeat (count) begin

        branch_type = $urandom_range(0,5);

        rs1 = $urandom_range(0,31);
        rs2 = $urandom_range(0,31);
        imm = $urandom_range(0,31);

        case (branch_type)

            // BEQ
            0: funct3 = 3'b000;

            // BNE
            1: funct3 = 3'b001;

            // BLT
            2: funct3 = 3'b100;

            // BGE
            3: funct3 = 3'b101;

            // BLTU
            4: funct3 = 3'b110;

            // BGEU
            5: funct3 = 3'b111;

            default:
                funct3 = 3'b000;

        endcase

        random_instr = {
            1'b0,              // imm[12]
            6'b000000,         // imm[10:5]
            rs2[4:0],
            rs1[4:0],
            funct3,
            imm[4:1],          // simplified imm[4:1]
            1'b0,              // imm[11]
            7'b1100011
        };

        apply_test(
            random_instr,
            $urandom_range(0,1),
            TEST_RANDOM
        );

    end

endtask


task automatic test_random_jump(input integer count);

    integer jump_type;
    integer rd;
    integer rs1;
    integer imm;

    logic [31:0] random_instr;

    repeat (count) begin

        jump_type = $urandom_range(0,1);

        rd  = $urandom_range(0,31);
        rs1 = $urandom_range(0,31);
        imm = $urandom_range(0,31);

        case (jump_type)

            // JAL
            0: begin

                random_instr = {
                    1'b0,          // imm[20]
                    10'b0000000000,// imm[10:1]
                    1'b0,          // imm[11]
                    8'b00000000,   // imm[19:12]
                    rd[4:0],
                    7'b1101111
                };

                apply_test(
                    random_instr,
                    1'b0,
                    TEST_RANDOM
                );

            end

            // JALR
            1: begin

                random_instr = {
                    12'b000000000000,
                    rs1[4:0],
                    3'b000,
                    rd[4:0],
                    7'b1100111
                };

                apply_test(
                    random_instr,
                    1'b0,
                    TEST_RANDOM
                );

            end

            default: begin
                random_instr = 32'b0;
            end

        endcase

    end

endtask

initial begin

    $dumpfile("sim/phx_control_integration_tb.vcd");
    $dumpvars(0, phx_control_integration_tb);

    passed_count = 0;
    failed_count = 0;

    
    // R-TYPE
    

    apply_test(
        32'b0000000_00001_00010_000_00011_0110011,
        1'b0,
        TEST_R_TYPE
    );

    
    // I-TYPE
    

    apply_test(
        32'b000000000101_00001_000_00010_0010011,
        1'b0,
        TEST_I_TYPE
    );

    
    // LOAD
    

    apply_test(
        32'b000000001000_00001_010_00010_0000011,
        1'b0,
        TEST_MEMORY
    );

    
    // STORE
    

    apply_test(
        32'b0000000_00010_00001_010_01000_0100011,
        1'b0,
        TEST_MEMORY
    );

    
    // BRANCH NOT TAKEN
    

    apply_test(
        32'b0000000_00010_00001_000_00000_1100011,
        1'b0,
        TEST_BRANCH
    );

    
    // BRANCH TAKEN
    

    apply_test(
        32'b0000000_00010_00001_000_00000_1100011,
        1'b1,
        TEST_BRANCH
    );

    
    // AUIPC
    

    apply_test(
        32'b00000000000000000001_00010_0010111,
        1'b0,
        TEST_UPPER_IMM
    );

    
    // LUI
    

    apply_test(
        32'b00000000000000000001_00010_0110111,
        1'b0,
        TEST_UPPER_IMM
    );

    
    // JAL
    

    apply_test(
        32'b00000000000100000000_00001_1101111,
        1'b0,
        TEST_JUMP
    );

    
    // JALR
    

    apply_test(
        32'b000000001000_00001_000_00010_1100111,
        1'b0,
        TEST_JUMP
    );





    test_r_type();
    test_i_type();
    test_memory();
    test_branch();
    test_upper_immediate();
    test_jump();

    test_random_r_type(100);
    /*test_random_i_type(100);
    test_random_memory(50);
    test_random_branch(50);
    test_random_jump(50);
    */
    // FINAL REPORT
    

    $display(" PASSED : %0d", passed_count);
    $display(" FAILED : %0d", failed_count);
    
    if (failed_count == 0)
        $display("  all tests are passed ");
    else
        $display("  verification failed ");

    $finish;

end
endmodule