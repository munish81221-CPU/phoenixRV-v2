`timescale 1ns/1ps
module phx_control_integration 
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

function automatic control_t expected_main_control(
    input logic [31:0] instr
    logic [6:0] opcode;
    control_t result;

begin
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
end
);
endfunction

function automatic logic [3:0] expected_alu_control(
    input logic [31:0] instr

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
        7b'0010111:begin
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


        

   
);


endfunction

function automatic logic [1:0] expected_pc_select(
    input logic branch,
    input logic branch_taken,
    input logic jump,
    input logic jump_reg
);

begin

    expected_pc_select = 2'b00;

    if (jump && jump_reg)
        expected_pc_select = 2'b11;

    else if (jump)
        expected_pc_select = 2'b10;

    else if (branch && branch_taken)
        expected_pc_select = 2'b01;

end

endfunction

main_expected = expected_main_control(instruction);
alu_expected  = expected_alu_control(instruction);
pc_expected   = expected_pc_select(
                    main_expected.branch,
                    branch_taken,
                    main_expected.jump,
                    main_expected.jump_reg
                );