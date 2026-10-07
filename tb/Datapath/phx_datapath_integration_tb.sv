`timescale 1ns/1ps

module phx_datapath_integration_tb;

    // Testbench Parameters
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 5;

    // Clock and Reset
    logic clk;
    logic reset;

    // Instruction
    logic [31:0] instruction;

    // Control Signals
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

    // DUT Outputs
    logic        branch_taken;
    logic [31:0] current_pc;
    logic [31:0] alu_result;
    logic [31:0] writeback_data;

    


    //verification type 
    typedef enum logic [3:0] {
    TEST_R_TYPE,
    TEST_I_TYPE,
    TEST_LOAD,
    TEST_STORE,
    TEST_BRANCH,
    TEST_LUI,
    TEST_AUIPC,
    TEST_JAL,
    TEST_JALR
} test_category_t;


typedef struct packed {
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
} control_t;

control_t control;

typedef struct packed {
    logic [31:0] instruction;
    control_t    control;
} stimulus_t;
    

integer pass_count;
integer fail_count;


    // DUT
    phx_datapath_integration #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),

        .instruction(instruction),

        .reg_write   (control.reg_write),
        .alu_src_a   (control.alu_src_a),
        .alu_src     (control.alu_src),
        .mem_read    (control.mem_read),
        .mem_write   (control.mem_write),
        .wb_select   (control.wb_select),
        .alu_control (control.alu_control),
        .pc_select   (control.pc_select),
        .branch      (control.branch),
        .jump        (control.jump),
        .jump_reg    (control.jump_reg),


        .branch_taken(branch_taken),
        .current_pc(current_pc),
        .alu_result(alu_result),
        .writeback_data(writeback_data)
    );





    // Clock Generation
    always #5 clk = ~clk;

function automatic logic [3:0] decode_r_alu(
    input logic [2:0] funct3,
    input logic [6:0] funct7
);
    begin
        case (funct3)

            3'b000:
                decode_r_alu = (funct7 == 7'b0100000)
                              ? 4'b0001 : 4'b0000; // SUB / ADD

            3'b111: decode_r_alu = 4'b0010; // AND
            3'b110: decode_r_alu = 4'b0011; // OR
            3'b100: decode_r_alu = 4'b0100; // XOR
            3'b001: decode_r_alu = 4'b0101; // SLL
            3'b101:
                decode_r_alu = (funct7 == 7'b0100000)
                              ? 4'b0111 : 4'b0110; // SRA / SRL
            3'b010: decode_r_alu = 4'b1000; // SLT
            3'b011: decode_r_alu = 4'b1001; // SLTU

            default: decode_r_alu = 4'b0000;

        endcase
    end
endfunction


function automatic logic [3:0] decode_i_alu(
    input logic [2:0] funct3,
    input logic [6:0] funct7
);
    begin
        case (funct3)

            3'b000: decode_i_alu = 4'b0000; // ADDI
            3'b111: decode_i_alu = 4'b0010; // ANDI
            3'b110: decode_i_alu = 4'b0011; // ORI
            3'b100: decode_i_alu = 4'b0100; // XORI
            3'b010: decode_i_alu = 4'b1000; // SLTI
            3'b011: decode_i_alu = 4'b1001; // SLTIU
            3'b001: decode_i_alu = 4'b0101; // SLLI

            3'b101:
                decode_i_alu = (funct7 == 7'b0100000)
                              ? 4'b0111 : 4'b0110; // SRAI / SRLI

            default: decode_i_alu = 4'b0000;

        endcase
    end
endfunction


function automatic control_t get_control(
    input logic [31:0] instruction_in,
    input test_category_t category
);

    control_t ctrl;

    begin

        // Safe defaults
        ctrl = '0;

        case (category)

            TEST_R_TYPE: begin
                ctrl.reg_write   = 1'b1;
                ctrl.alu_src_a   = 1'b0;
                ctrl.alu_src     = 1'b0;
                ctrl.wb_select   = 2'b00;
                ctrl.alu_control = decode_r_alu(
                                                    instruction_in[14:12],
                                                    instruction_in[31:25]
                                               );
                ctrl.pc_select   = 2'b00;
            end

            TEST_I_TYPE: begin
                ctrl.reg_write   = 1'b1;
                ctrl.alu_src_a   = 1'b0;
                ctrl.alu_src     = 1'b1;
                ctrl.wb_select   = 2'b00;
                ctrl.alu_control =   decode_i_alu(
                                                    instruction_in[14:12],
                                                    instruction_in[31:25]
                                                 );
                ctrl.pc_select   = 2'b00;
            end

            TEST_LOAD: begin
                ctrl.reg_write   = 1'b1;
                ctrl.alu_src_a   = 1'b0;
                ctrl.alu_src     = 1'b1;
                ctrl.mem_read    = 1'b1;
                ctrl.wb_select   = 2'b01;
                ctrl.alu_control = 4'b0000;
                ctrl.pc_select   = 2'b00;
            end

            TEST_STORE: begin
                ctrl.reg_write   = 1'b0;
                ctrl.alu_src_a   = 1'b0;
                ctrl.alu_src     = 1'b1;
                ctrl.mem_write   = 1'b1;
                ctrl.alu_control = 4'b0000;
                ctrl.pc_select   = 2'b00;
            end

            TEST_BRANCH: begin
                ctrl.reg_write   = 1'b0;
                ctrl.alu_src_a   = 1'b0;
                ctrl.alu_src     = 1'b0;
                ctrl.alu_control = 4'b0001;
                ctrl.pc_select   = 2'b01;
                ctrl.branch      = 1'b1;
            end

            TEST_LUI: begin
                ctrl.reg_write   = 1'b1;
                ctrl.wb_select   = 2'b11;
                ctrl.alu_control = 4'b0000;
                ctrl.pc_select   = 2'b00;
            end

            TEST_AUIPC: begin
                ctrl.reg_write   = 1'b1;
                ctrl.alu_src_a   = 1'b1;
                ctrl.alu_src     = 1'b1;
                ctrl.wb_select   = 2'b00;
                ctrl.alu_control = 4'b0000;
                ctrl.pc_select   = 2'b00;
            end

            TEST_JAL: begin
                ctrl.reg_write   = 1'b1;
                ctrl.wb_select   = 2'b10;
                ctrl.pc_select   = 2'b10;
                ctrl.jump        = 1'b1;
            end

            TEST_JALR: begin
                ctrl.reg_write   = 1'b1;
                ctrl.alu_src     = 1'b1;
                ctrl.wb_select   = 2'b10;
                ctrl.alu_control = 4'b0000;
                ctrl.pc_select   = 2'b11;
                ctrl.jump        = 1'b1;
                ctrl.jump_reg    = 1'b1;
            end

            default: begin
                ctrl = '0;
            end

        endcase

        return ctrl;

    end

endfunction




//i-type encoder
function automatic logic [31:0] make_i_type(
    input logic [4:0]  rd,
    input logic [4:0]  rs1,
    input logic [2:0]  funct3,
    input logic [11:0] immediate
);

    begin
        make_i_type = {
            immediate,
            rs1,
            funct3,
            rd,
            7'b0010011
        };
    end

endfunction


//r-type encoder
function automatic logic [31:0] make_r_type(
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [2:0] funct3,
    input logic [6:0] funct7
);

    begin
        make_r_type = {
            funct7,
            rs2,
            rs1,
            funct3,
            rd,
            7'b0110011
        };
    end

endfunction


//s-type encoder
function automatic logic [31:0] make_s_type(
    input logic [4:0]  rs1,
    input logic [4:0]  rs2,
    input logic [2:0]  funct3,
    input logic [11:0] immediate
);

    begin
        make_s_type = {
            immediate[11:5],
            rs2,
            rs1,
            funct3,
            immediate[4:0],
            7'b0100011
        };
    end

endfunction


//b-type encoder
function automatic logic [31:0] make_b_type(
    input logic [4:0]  rs1,
    input logic [4:0]  rs2,
    input logic [2:0]  funct3,
    input logic [12:0] immediate
);

    begin
        make_b_type = {
            immediate[12],
            immediate[10:5],
            rs2,
            rs1,
            funct3,
            immediate[4:1],
            immediate[11],
            1'b0,
            7'b1100011
        };
    end

endfunction

//u-type encoder
function automatic logic [31:0] make_u_type(
    input logic [4:0]  rd,
    input logic [19:0] immediate,
    input logic [6:0]  opcode
);

    begin
        make_u_type = {
            immediate,
            rd,
            opcode
        };
    end

endfunction

//j-type encoder
function automatic logic [31:0] make_j_type(
    input logic [4:0]  rd,
    input logic [20:0] immediate
);

    begin
        make_j_type = {
            immediate[20],
            immediate[10:1],
            immediate[11],
            immediate[19:12],
            rd,
            7'b1101111
        };
    end

endfunction

task automatic check_memory_summary;

    integer i;
    logic mismatch;
    integer checked_count;

    begin

        mismatch     = 1'b0;
        checked_count = 0;

        for (i = 0; i < 256; i = i + 1) begin

            // Only check memory locations that have
            // been written by the reference model.
            if (reference_memory_valid[i]) begin

                checked_count = checked_count + 1;

                if (dut.u_data_memory.memory[i] !==
                    reference_memory[i]) begin

                    mismatch = 1'b1;

                    $display(
                        "[FAIL] MEM[%0d] : DUT = %h Expected = %h",
                        i,
                        dut.u_data_memory.memory[i],
                        reference_memory[i]
                    );

                end

            end

        end

      if (!mismatch) begin

            pass_count = pass_count + 1;

        end
        else begin

            fail_count = fail_count + 1;

        end 

    end

endtask



task automatic run_test(
    input logic [31:0] instruction_in,
    input test_category_t category
);

    control_t ctrl;

    begin

       
        // Generate control signals
       

        ctrl = get_control(
            instruction_in,
            category
        );
        // Apply instruction and control to DUT
       

        instruction = instruction_in;
        control     = ctrl;
        // Allow combinational datapath to settle
       

        #1;

       



       



        // Execute independent reference model
        execute_reference(
            instruction_in,
            ctrl
        );

       
        // Check combinational output
        check_value(
            "ALU result",
            alu_result,
            expected_alu_result
        );

        check_value(
            "Writeback data",
            writeback_data,
            expected_writeback_data
        );

        check_value(
            "Branch taken",
            {31'b0, branch_taken},
            {31'b0, expected_branch_taken}
        );

    
        // Wait for sequential state update
       

       @(posedge clk);
        #1;

       
        // Check architectural state
        check_register_file_summary();

        check_memory_summary();

        check_pc();

    end

endtask







task automatic check_value(
    input string name,
    input logic [31:0] actual,
    input logic [31:0] expected
);

    begin

        if (actual === expected) begin

            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "[FAIL] %-25s Actual = %h Expected = %h",
                name,
                actual,
                expected
            );

            fail_count = fail_count + 1;

        end

    end

endtask

//reference model construction
logic [31:0] reference_registers [0:31];
logic [31:0] reference_memory    [0:255];
logic        reference_memory_valid [0:255];
logic [31:0] reference_pc;

// Expected DUT outputs generated by reference model
logic [31:0] expected_alu_result;
logic [31:0] expected_writeback_data;
logic [31:0] expected_next_pc;
logic        expected_branch_taken;


task automatic reset_reference_model;

    integer i;

    begin

        reference_pc = 32'b0;

        for (i = 0; i < 32; i = i + 1)begin
            reference_registers[i] = 32'b0;
        end 


        for (i = 0; i < 256; i = i + 1)begin
            reference_memory[i] = 32'b0;
            reference_memory_valid[i] = 1'b0;

        end


    reference_registers[0] = 32'b0;

    end
    
endtask


function automatic logic [31:0] reference_alu(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [3:0]  alu_control
);

    begin

        case (alu_control)

            4'b0000: reference_alu = a + b;
            4'b0001: reference_alu = a - b;
            4'b0010: reference_alu = a & b;
            4'b0011: reference_alu = a | b;
            4'b0100: reference_alu = a ^ b;
            4'b0101: reference_alu = a << b[4:0];
            4'b0110: reference_alu = a >> b[4:0];
            4'b0111: reference_alu = $signed(a) >>> b[4:0];

            4'b1000:
                reference_alu =
                    ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;

            4'b1001:
                reference_alu =
                    (a < b) ? 32'd1 : 32'd0;

            default:
                reference_alu = 32'b0;

        endcase

    end

endfunction


function automatic logic [31:0] reference_immediate(
    input logic [31:0] instruction
);

    logic [6:0] opcode;

    begin

        opcode = instruction[6:0];

        case (opcode)

            // I-type
            7'b0010011,
            7'b0000011,
            7'b1100111:

                reference_immediate =
                    {{20{instruction[31]}},
                     instruction[31:20]};


            // S-type
            7'b0100011:

                reference_immediate =
                    {{20{instruction[31]}},
                     instruction[31:25],
                     instruction[11:7]};


            // B-type
            7'b1100011:

                reference_immediate =
                    {{19{instruction[31]}},
                     instruction[31],
                     instruction[7],
                     instruction[30:25],
                     instruction[11:8],
                     1'b0};


            // U-type
            7'b0110111,
            7'b0010111:

                reference_immediate =
                    {instruction[31:12], 12'b0};


            // J-type
            7'b1101111:

                reference_immediate =
                    {{11{instruction[31]}},
                     instruction[31],
                     instruction[19:12],
                     instruction[20],
                     instruction[30:21],
                     1'b0};


            default:
                reference_immediate = 32'b0;

        endcase

    end

endfunction


task automatic execute_reference(
    input logic [31:0] instruction_in,
    input control_t    ctrl
);

    logic [6:0]  opcode;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [2:0]  funct3;

    logic [31:0] immediate;
    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [31:0] alu_result_ref;
    logic [31:0] writeback_ref;

    logic        branch_condition;
    logic        branch_taken_ref;

    logic [31:0] next_pc_ref;

    integer memory_index;

    begin

        opcode = instruction_in[6:0];
        rd     = instruction_in[11:7];
        funct3 = instruction_in[14:12];
        rs1    = instruction_in[19:15];
        rs2    = instruction_in[24:20];

        immediate = reference_immediate(instruction_in);

        
        // Operand selection
        

        if (ctrl.alu_src_a)
            operand_a = reference_pc;
        else
            operand_a = reference_registers[rs1];

        if (ctrl.alu_src)
            operand_b = immediate;
        else
            operand_b = reference_registers[rs2];

        
        // ALU
        

        alu_result_ref =
            reference_alu(
                operand_a,
                operand_b,
                ctrl.alu_control
            );

        expected_alu_result = alu_result_ref;
        // Branch condition
        

        branch_condition = 1'b0;

        if (opcode == 7'b1100011) begin

            case (funct3)

                3'b000:
                    branch_condition =
                        (reference_registers[rs1] ==
                         reference_registers[rs2]);

                3'b001:
                    branch_condition =
                        (reference_registers[rs1] !=
                         reference_registers[rs2]);

                3'b100:
                    branch_condition =
                        ($signed(reference_registers[rs1]) <
                         $signed(reference_registers[rs2]));

                3'b101:
                    branch_condition =
                        ($signed(reference_registers[rs1]) >=
                         $signed(reference_registers[rs2]));

                3'b110:
                    branch_condition =
                        (reference_registers[rs1] <
                         reference_registers[rs2]);

                3'b111:
                    branch_condition =
                        (reference_registers[rs1] >=
                         reference_registers[rs2]);

                default:
                    branch_condition = 1'b0;

            endcase

        end

        branch_taken_ref = ctrl.branch && branch_condition;
        expected_branch_taken = branch_taken_ref;




        


        
        // Writeback selection
        

        case (ctrl.wb_select)

            2'b00:
                writeback_ref = alu_result_ref;

           2'b01: begin

                    memory_index =
                        alu_result_ref[9:2];

                   

                    writeback_ref =
                        reference_memory[memory_index];

                end

            2'b10:
                writeback_ref = reference_pc + 32'd4;

            2'b11:
                writeback_ref = immediate;

            default:
                writeback_ref = 32'b0;

        endcase
        expected_writeback_data = writeback_ref;
        
        // Memory write
        

        if (ctrl.mem_write) begin

            memory_index =
                alu_result_ref[9:2];

            reference_memory[memory_index] =
                reference_registers[rs2];
            reference_memory_valid[memory_index] = 1'b1;    

        end

        
        // Register write
        

        if (ctrl.reg_write && (rd != 5'd0))
            reference_registers[rd] = writeback_ref;

        
        // x0 invariant
        

        reference_registers[0] = 32'b0;

        
        // Next PC
        

        case (ctrl.pc_select)

            2'b00:
                next_pc_ref = reference_pc + 32'd4;

            2'b01:
                next_pc_ref = reference_pc + immediate;

            2'b10:
                next_pc_ref = reference_pc + immediate;

            2'b11:
                next_pc_ref =
                    {alu_result_ref[31:1], 1'b0};

            default:
                next_pc_ref = reference_pc + 32'd4;

        endcase

        expected_next_pc = next_pc_ref;
        reference_pc = next_pc_ref;

    end

endtask





task automatic check_register_file_summary;

    integer i;
    logic mismatch;

    begin

        mismatch = 1'b0;

        for (i = 0; i < 32; i = i + 1) begin

            if (dut.u_register_file.registers[i] !==
                reference_registers[i]) begin

                mismatch = 1'b1;

                $display(
                    "[FAIL] x%0d : DUT = %h Expected = %h",
                    i,
                    dut.u_register_file.registers[i],
                    reference_registers[i]
                );

            end

        end

        if (!mismatch) begin
           
            pass_count = pass_count + 1;
        end
        else begin
            fail_count = fail_count + 1;
        end

    end

endtask

task automatic check_pc;

    begin

        if (current_pc === expected_next_pc) begin

           

            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "[FAIL] PC : DUT = %h Expected = %h",
                current_pc,
                expected_next_pc
            );

            fail_count = fail_count + 1;

        end

    end

endtask


task automatic test_random_instructions(
    input integer count
);

    integer i;
    integer instruction_type;

    logic [31:0] random_instruction;

    logic [4:0]  rd;
    logic [4:0]  rs1;
    logic [4:0]  rs2;

    logic [2:0]  funct3;
    logic [6:0]  funct7;

    logic [11:0] immediate_i;
    logic [11:0] immediate_s;
    logic [12:0] immediate_b;

    logic [19:0] immediate_u;
    logic [20:0] immediate_j;

    test_category_t category;

    begin

        for (i = 0; i < count; i = i + 1) begin

            // Select one of the nine supported instruction classes
            instruction_type = $urandom_range(0, 8);

            // Random register fields
            rd  = $urandom_range(0, 31);
            rs1 = $urandom_range(0, 31);
            rs2 = $urandom_range(0, 31);

            // Random immediates
            immediate_i = $urandom_range(0, 4095);
            immediate_s = $urandom_range(0, 4095);

            // Keep branch offsets relatively small and aligned
            immediate_b = $urandom_range(0, 63);
            immediate_b = {immediate_b[12:1], 1'b0};

            immediate_u = $urandom_range(0, 20'hFFFFF);

            // Keep JAL offsets relatively small and aligned
            immediate_j = $urandom_range(0, 255);
            immediate_j = {immediate_j[20:1], 1'b0};

            case (instruction_type)

                // -------------------------------------------------
                // R-TYPE
                // -------------------------------------------------

                0: begin

                    category = TEST_R_TYPE;

                    funct3 = $urandom_range(0, 7);

                    // Generate only legal funct7 values
                    if ((funct3 == 3'b000) ||
                        (funct3 == 3'b101)) begin

                        if ($urandom_range(0, 1))
                            funct7 = 7'b0100000;
                        else
                            funct7 = 7'b0000000;

                    end
                    else begin

                        funct7 = 7'b0000000;

                    end

                    random_instruction = make_r_type(
                        rd,
                        rs1,
                        rs2,
                        funct3,
                        funct7
                    );

                end


                // -------------------------------------------------
                // I-TYPE ALU
                // -------------------------------------------------

                1: begin

    category = TEST_I_TYPE;

    case ($urandom_range(0, 7))

        0: begin
            funct3 = 3'b000;       // ADDI
            immediate_i = $urandom_range(0, 4095);
        end

        1: begin
            funct3 = 3'b010;       // SLTI
            immediate_i = $urandom_range(0, 4095);
        end

        2: begin
            funct3 = 3'b011;       // SLTIU
            immediate_i = $urandom_range(0, 4095);
        end

        3: begin
            funct3 = 3'b100;       // XORI
            immediate_i = $urandom_range(0, 4095);
        end

        4: begin
            funct3 = 3'b110;       // ORI
            immediate_i = $urandom_range(0, 4095);
        end

        5: begin
            funct3 = 3'b111;       // ANDI
            immediate_i = $urandom_range(0, 4095);
        end

        6: begin
            funct3 = 3'b001;       // SLLI
            immediate_i = {
                7'b0000000,
                $urandom_range(0, 31)
            };
        end

        7: begin
            funct3 = 3'b101;       // SRLI / SRAI

            if ($urandom_range(0, 1))
                immediate_i = {
                    7'b0100000,
                    $urandom_range(0, 31)
                };
            else
                immediate_i = {
                    7'b0000000,
                    $urandom_range(0, 31)
                };
        end

    endcase

    random_instruction = make_i_type(
        rd,
        rs1,
        funct3,
        immediate_i
    );

end


                // -------------------------------------------------
                // LOAD
                // -------------------------------------------------

                2: begin

                    category = TEST_LOAD;

                    random_instruction = {
                        immediate_i,
                        rs1,
                        3'b010,       // LW
                        rd,
                        7'b0000011
                    };

                end


                // -------------------------------------------------
                // STORE
                // -------------------------------------------------

                3: begin

                    category = TEST_STORE;

                    random_instruction = make_s_type(
                        rs1,
                        rs2,
                        3'b010,       // SW
                        immediate_s
                    );

                end


                // -------------------------------------------------
                // BRANCH
                // -------------------------------------------------

                4: begin

                    category = TEST_BRANCH;

                   

                    // Only legal branch funct3 values
                    case ($urandom_range(0, 5))

                        0: funct3 = 3'b000; // BEQ
                        1: funct3 = 3'b001; // BNE
                        2: funct3 = 3'b100; // BLT
                        3: funct3 = 3'b101; // BGE
                        4: funct3 = 3'b110; // BLTU
                        5: funct3 = 3'b111; // BGEU

                    endcase

                    random_instruction = make_b_type(
                        rs1,
                        rs2,
                        funct3,
                        immediate_b
                    );

                end


                // -------------------------------------------------
                // LUI
                // -------------------------------------------------

                5: begin

                    category = TEST_LUI;

                    random_instruction = make_u_type(
                        rd,
                        immediate_u,
                        7'b0110111
                    );

                end


                // -------------------------------------------------
                // AUIPC
                // -------------------------------------------------

                6: begin

                    category = TEST_AUIPC;

                    random_instruction = make_u_type(
                        rd,
                        immediate_u,
                        7'b0010111
                    );

                end


                // -------------------------------------------------
                // JAL
                // -------------------------------------------------

                7: begin

                    category = TEST_JAL;

                    random_instruction = make_j_type(
                        rd,
                        immediate_j
                    );

                end


                // -------------------------------------------------
                // JALR
                // -------------------------------------------------

                8: begin

                    category = TEST_JALR;

                    random_instruction = {
                        immediate_i,
                        rs1,
                        3'b000,
                        rd,
                        7'b1100111
                    };

                end

            endcase


            // -----------------------------------------------------
            // Execute through common verification infrastructure
            // -----------------------------------------------------

            run_test(
                random_instruction,
                category
            );

        end

    end

endtask

integer i;
integer directed_test_count;
integer random_test_count;
integer test_count;
    // Waveform Dump
    initial begin
        $dumpfile("phx_datapath_integration.vcd");
        $dumpvars(0, phx_datapath_integration_tb);
    end


    // Testbench Initialization
    initial begin

        pass_count=0;
        fail_count=0;


        // Clock
        clk = 1'b0;

        // Reset
        reset = 1'b1;

        reset_reference_model();


        for (i = 0; i < 256; i = i + 1) begin
            dut.u_data_memory.memory[i] = 32'b0;
            reference_memory[i] = 32'b0;
            reference_memory_valid[i] = 1'b0;
        end



        // Instruction
        instruction = 32'b0;

        control = '0;

        // Hold reset for two clock cycles
        #20;

        reset = 1'b0;

        // direct tests for module
        
run_test(32'h00A00093, TEST_I_TYPE);  // ADDI x1, x0, 10


run_test(32'h01400113, TEST_I_TYPE);  // ADDI x2, x0, 20


run_test(32'h002081B3, TEST_R_TYPE);  // ADD x3, x1, x2

 
run_test(32'h00302023, TEST_STORE);   // SW x3, 0(x0)

 
run_test(32'h00002203, TEST_LOAD);    // LW x4, 0(x0)

 
run_test(32'h123452B7, TEST_LUI);     // LUI x5, 0x12345

run_test(32'h00001317, TEST_AUIPC);   // AUIPC x6, 0x1

 
run_test(32'h00208463, TEST_BRANCH);  // BEQ x1, x2, +8


run_test(32'h008003EF, TEST_JAL);     // JAL x7, +8


run_test(32'h000083E7, TEST_JALR);    // JALR x7, 0(x1)



//random inputs testing 
$display("random instruction regression");
test_random_instructions(1000);
        
directed_test_count=10;
random_test_count=1000;
test_count=1010;
        
$display("  Datapath Integration Verification");

$display("Directed tests : %0d", directed_test_count);
$display("Random tests   : %0d", random_test_count);
$display("Total tests    : %0d", test_count);
$display("Passed check   : %0d", pass_count);
$display("Failed check   : %0d", fail_count);


if (fail_count == 0)
    $display("status - passed ");
else
    $display("status - failed ");

$display("every test goes from many testing so have to pass different checks ");
$display("ALU result");
$display("Writeback data");

$display("Branch taken");
$display("Register file");
$display("Memory");
$display("PC");


$finish;
    end 


endmodule