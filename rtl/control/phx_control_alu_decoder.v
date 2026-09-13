module phx_control_alu_decoder(
    input logic[31:0]instruction,
    output logic[3:0]alu_control
);

logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode = instruction[6:0];
assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];

    localparam  R_type = 7'b0110011;  // R-type
    localparam  I_type = 7'b0010011;  // I-type ALU
    localparam  LW     = 7'b0000011;  // LW
    localparam  SW     = 7'b0100011;  // SW
    localparam  Branch = 7'b1100011;  // Branch
    localparam  AUIPC  = 7'b0010111;  // AUIPC
    localparam  JALR   = 7'b1100111;  // JALR
    localparam  LUI    = 7'b0110111;  // LUI
    

always_comb begin
    
    alu_control = 4'b0000;
    
    case(opcode)

        R_type:begin
            case({funct7,funct3})
                //ADD	
                0000000000:begin
                    alu_control=4'b0000;
                end
                //SUB
                0100000000:begin
                    alu_control=4'b0001;
                end
                //AND
                0000000111:begin
                    alu_control=4'b0010;
                end

                //OR
                0000000110:begin
                    alu_control=4'b0011;
                end

                //XOR	
                0000000100:begin
                    alu_control=4'b0100;
                end
                //SLL	
                0000000001:begin	
                    alu_control=4'b0101;
                end
                //SRL	
                0000000101:begin	
                    alu_control=4'b0110;
                end
                //SRA	
                0100000101:begin	
                    alu_control=4'b0111;
                end
                //SLT	
                0000000010:begin	
                    alu_control=4'b1000;
                end
                //SLTU	
                0000000011:begin
                    alu_control=4'b1001;
                end
                
            endcase
        end
      I_type: begin

        case (funct3)

        // ADDI
        3'b000: begin
            alu_control = 4'b0000;
        end

        // SLTI
        3'b010: begin
            alu_control = 4'b1000;
        end

        // SLTIU
        3'b011: begin
            alu_control = 4'b1001;
        end

        // XORI
        3'b100: begin
            alu_control = 4'b0100;
        end

        // ORI
        3'b110: begin
            alu_control = 4'b0011;
        end

        // ANDI
        3'b111: begin
            alu_control = 4'b0010;
        end

        // SLLI
        3'b001: begin
            if (funct7 == 7'b0000000)
                alu_control = 4'b0101;
            else
                alu_control = 4'b0000;
        end

        // SRLI / SRAI
        3'b101: begin

            case (funct7)

                // SRLI
                7'b0000000: begin
                    alu_control = 4'b0110;
                end

                // SRAI
                7'b0100000: begin
                    alu_control = 4'b0111;
                end

                default: begin
                    alu_control = 4'b0000;
                end

            endcase

        end

        default: begin
            alu_control = 4'b0000;
        end

        endcase

        end

        
        LW:begin
            alu_control=4'b0000;
        end
        SW:begin
            alu_control=4'b0000;
        end
        Branch:begin
            alu_control=4'b0001;
        end
        AUIPC:begin
            alu_control=4'b0000;
        end
        JALR:begin
            alu_control=4'b0000;
        end
        LUI:begin
            alu_control=4'b0000;
        end
        default: 
        alu_control=4'b0000;
    endcase

end
endmodule