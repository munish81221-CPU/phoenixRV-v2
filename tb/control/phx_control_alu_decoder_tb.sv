`timescale 1ns/1ps
module phx_control_alu_decoder_tb;

    logic [31:0] instruction;
    wire [3:0]  alu_control;
    logic [3:0]  expected;

phx_control_alu_decoder DUT
(
    .instruction(instruction),
    .alu_control(alu_control)
);


    localparam  R_type = 7'b0110011;  // R-type
    localparam  I_type = 7'b0010011;  // I-type ALU
    localparam  LW     = 7'b0000011;  // LW
    localparam  SW     = 7'b0100011;  // SW
    localparam  Branch = 7'b1100011;  // Branch
    localparam  AUIPC  = 7'b0010111;  // AUIPC
    localparam  JALR   = 7'b1100111;  // JALR
    localparam  LUI    = 7'b0110111;  // LUI
    localparam  JAL    = 7'b1101111;   // JAL


integer error_count=0;

task check_result(
    input string name,
    input logic [3:0] expected_value
);
    begin
        if (alu_control !== expected_value) begin
            $display("FAIL %s: actual=%b expected=%b",
                     name, alu_control, expected_value);
            error_count = error_count + 1;
        end
        else begin
            $display("PASS %s: alu_control=%b",
                     name, alu_control);
            pass_count = pass_count + 1;
        end
    end
endtask

function automatic logic [3:0] expected_alu_control(
    input logic [31:0] instr
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    begin

        opcode = instr[6:0];
        funct3 = instr[14:12];
        funct7 = instr[31:25];

        expected_alu_control = 4'b0000;

        // Decoder model will go here
        case(opcode)

        R_type:begin
            case({funct7,funct3})
                //ADD	
                0000000000:begin
                    expected_alu_control=4'b0000;
                end
                //SUB
                0100000000:begin
                    expected_alu_control=4'b0001;
                end
                //AND
                0000000111:begin
                    expected_alu_control=4'b0010;
                end

                //OR
                0000000110:begin
                    expected_alu_control=4'b0011;
                end

                //XOR	
                0000000100:begin
                    expected_alu_control=4'b0100;
                end
                //SLL	
                0000000001:begin	
                    expected_alu_control=4'b0101;
                end
                //SRL	
                0000000101:begin	
                    expected_alu_control=4'b0110;
                end
                //SRA	
                0100000101:begin	
                    expected_alu_control=4'b0111;
                end
                //SLT	
                0000000010:begin	
                    expected_alu_control=4'b1000;
                end
                //SLTU	
                0000000011:begin
                    expected_alu_control=4'b1001;
                end
                
            endcase
        end
       I_type: begin

    case (funct3)

        3'b000: begin
            // ADDI
            expected_alu_control = 4'b0000;
        end

        3'b010: begin
            // SLTI
            expected_alu_control = 4'b1000;
        end

        3'b011: begin
            // SLTIU
            expected_alu_control = 4'b1001;
        end

        3'b100: begin
            // XORI
            expected_alu_control = 4'b0100;
        end

        3'b110: begin
            // ORI
            expected_alu_control = 4'b0011;
        end

        3'b111: begin
            // ANDI
            expected_alu_control = 4'b0010;
        end

        3'b001: begin
            // SLLI
            if (funct7 == 7'b0000000)
                expected_alu_control = 4'b0101;
            else
                expected_alu_control = 4'b0000;
        end

        3'b101: begin

            case (funct7)

                7'b0000000: begin
                    // SRLI
                    expected_alu_control = 4'b0110;
                end

                7'b0100000: begin
                    // SRAI
                    expected_alu_control = 4'b0111;
                end

                default: begin
                    expected_alu_control = 4'b0000;
                end

            endcase

        end

        default: begin
            expected_alu_control = 4'b0000;
        end

    endcase

end
        

        LW:begin
            expected_alu_control=4'b0000;
        end

        SW:begin
            expected_alu_control=4'b0000;
        end

        Branch:begin
            expected_alu_control=4'b0001;
        end

        AUIPC:begin
            expected_alu_control=4'b0000;
        end

        JALR:begin
            expected_alu_control=4'b0000;
        end

        LUI:begin
            expected_alu_control=4'b0000;
        end

        default: 
        expected_alu_control=4'b0000;


        endcase  
    end
    
endfunction

                                                                                                                            

function automatic logic [31:0] generate_random_r_type();

    logic [3:0] operation;
    logic [6:0] random_funct7;
    logic [2:0] random_funct3;
    logic [4:0] random_rs1;
    logic [4:0] random_rs2;
    logic [4:0] random_rd;

    begin

        // Select one of the 10 legal R-type operations
        operation = $urandom_range(0, 9);

        // Default values
        random_funct7 = 7'b0000000;
        random_funct3 = 3'b000;
        
        case (operation)

            4'd0: begin
                // ADD
                random_funct7 = 7'b0000000;
                random_funct3 = 3'b000;
            end

            4'd1: begin
                // SUB
                random_funct7 = 7'b0100000;
                random_funct3 = 3'b000;
            end

            4'd2: begin
                // AND
                random_funct7 = 7'b0000000;
                random_funct3 = 3'b111;
            end

            4'd3: begin
                // OR
                random_funct7 = 7'b0000000;
                random_funct3 = 3'b110;
            end

            4'd4: begin
                // XOR
                random_funct7 = 7'b0000000;
                random_funct3 = 3'b100;
            end

            4'd5: begin
                // SLL
                random_funct7 = 7'b0000000;
                random_funct3 = 3'b001;
            end

            4'd6: begin
                // SRL
                random_funct7 = 7'b0000000;
                random_funct3 = 3'b101;
            end

            4'd7: begin
                // SRA
                random_funct7 = 7'b0100000;
                random_funct3 = 3'b101;
            end

            4'd8: begin
                // SLT
                random_funct7 = 7'b0000000;
                random_funct3 = 3'b010;
            end

            4'd9: begin
                // SLTU
                random_funct7 = 7'b0000000;
                random_funct3 = 3'b011;
            end

        endcase

        // Randomize fields that do not affect CTRL-002
        random_rs1 = $urandom_range(0, 31);
        random_rs2 = $urandom_range(0, 31);
        random_rd  = $urandom_range(0, 31);

        // Construct complete R-type instruction
        generate_random_r_type = {
            random_funct7,
            random_rs2,
            random_rs1,
            random_funct3,
            random_rd,
            R_type
        };

    end

endfunction


function automatic logic [31:0] generate_random_i_type();

    logic [3:0] operation;
    logic [11:0] immediate;
    logic [4:0] random_rs1;
    logic [4:0] random_rd;

    begin

        operation = $urandom_range(0, 8);

        immediate = $urandom_range(0, 4095);

        random_rs1 = $urandom_range(0, 31);
        random_rd  = $urandom_range(0, 31);

        case (operation)

            4'd0: begin
                // ADDI
                generate_random_i_type =
                    {immediate, random_rs1, 3'b000, random_rd, I_type};
            end

            4'd1: begin
                // SLTI
                generate_random_i_type =
                    {immediate, random_rs1, 3'b010, random_rd, I_type};
            end

            4'd2: begin
                // SLTIU
                generate_random_i_type =
                    {immediate, random_rs1, 3'b011, random_rd, I_type};
            end

            4'd3: begin
                // XORI
                generate_random_i_type =
                    {immediate, random_rs1, 3'b100, random_rd, I_type};
            end

            4'd4: begin
                // ORI
                generate_random_i_type =
                    {immediate, random_rs1, 3'b110, random_rd, I_type};
            end

            4'd5: begin
                // ANDI
                generate_random_i_type =
                    {immediate, random_rs1, 3'b111, random_rd, I_type};
            end

            4'd6: begin
                // SLLI
                generate_random_i_type =
                    {7'b0000000, immediate[4:0],
                     random_rs1, 3'b001, random_rd, I_type};
            end

            4'd7: begin
                // SRLI
                generate_random_i_type =
                    {7'b0000000, immediate[4:0],
                     random_rs1, 3'b101, random_rd, I_type};
            end

            4'd8: begin
                // SRAI
                generate_random_i_type =
                    {7'b0100000, immediate[4:0],
                     random_rs1, 3'b101, random_rd, I_type};
            end

        endcase

    end

endfunction




integer r_type_count;
integer i_type_count;
integer pass_count;
integer fail_count;
initial begin

    $dumpfile("sim/ctrl002.vcd");
    $dumpvars(0, phx_control_alu_decoder_tb);


    //for R type instruction verification loop
    for (r_type_count = 0; r_type_count < 100; r_type_count = r_type_count + 1) begin

       
         instruction = generate_random_r_type();
       

        expected = expected_alu_control(instruction);

        #1;

        assert (alu_control === expected)
            $display(
                "PASS: instruction=%08h opcode=%07b funct7=%07b funct3=%03b actual=%04b expected=%04b",
                instruction,
                instruction[6:0],
                instruction[31:25],
                instruction[14:12],
                alu_control,
                expected
            );
        else
            $error(
                "FAIL: instruction=%08h opcode=%07b funct7=%07b funct3=%03b actual=%04b expected=%04b",
                instruction,
                instruction[6:0],
                instruction[31:25],
                instruction[14:12],
                alu_control,
                expected
            );

    end


    // for I type instruction verification loop
    for (i_type_count = 0; i_type_count < 100; i_type_count = i_type_count + 1) begin

        instruction = generate_random_i_type();

        expected = expected_alu_control(instruction);

        #1;

        assert (alu_control === expected) begin

            pass_count++;

            $display(
                "PASS I[%0d]: instruction=%08h funct7=%07b funct3=%03b actual=%04b expected=%04b",
                i_type_count,
                instruction,
                instruction[31:25],
                instruction[14:12],
                alu_control,
                expected
            );

        end
        else begin

            fail_count++;

            $error(
                "FAIL I[%0d]: instruction=%08h funct7=%07b funct3=%03b actual=%04b expected=%04b",
                i_type_count,
                instruction,
                instruction[31:25],
                instruction[14:12],
                alu_control,
                expected
            );

        end

    end

// ============================================================
// Remaining Instruction Classes
// ============================================================

// LW
instruction = {12'b0, 5'd1, 3'b010, 5'd2, LW};
#1;
check_result("LW", 4'b0000);

// SW
instruction = {7'b0, 5'd2, 5'd1, 3'b010, 5'b0, SW};
#1;
check_result("SW", 4'b0000);

// ------------------------------------------------------------
// Branch instructions
// All branch instructions require SUB in the ALU.
// The individual branch condition is handled separately
// by COM-016 Branch Select.
// ------------------------------------------------------------

// BEQ
instruction = {7'b0, 5'd2, 5'd1, 3'b000, 5'b0, Branch};
#1;
check_result("BEQ", 4'b0001);

// BNE
instruction = {7'b0, 5'd2, 5'd1, 3'b001, 5'b0, Branch};
#1;
check_result("BNE", 4'b0001);

// BLT
instruction = {7'b0, 5'd2, 5'd1, 3'b100, 5'b0, Branch};
#1;
check_result("BLT", 4'b0001);

// BGE
instruction = {7'b0, 5'd2, 5'd1, 3'b101, 5'b0, Branch};
#1;
check_result("BGE", 4'b0001);

// BLTU
instruction = {7'b0, 5'd2, 5'd1, 3'b110, 5'b0, Branch};
#1;
check_result("BLTU", 4'b0001);

// BGEU
instruction = {7'b0, 5'd2, 5'd1, 3'b111, 5'b0, Branch};
#1;
check_result("BGEU", 4'b0001);

// ------------------------------------------------------------
// U-type instructions
// ------------------------------------------------------------

// LUI
instruction = {20'hABCDE, 5'd2, LUI};
#1;
check_result("LUI", 4'b0000);

// AUIPC
instruction = {20'hABCDE, 5'd2, AUIPC};
#1;
check_result("AUIPC", 4'b0000);

// ------------------------------------------------------------
// Jump instructions
// ------------------------------------------------------------

// JAL
instruction = {20'hABCDE, 5'd2, JAL};
#1;
check_result("JAL", 4'b0000);

// JALR
instruction = {12'h123, 5'd1, 3'b000, 5'd2, JALR};
#1;
check_result("JALR", 4'b0000);



    $finish;

end


endmodule