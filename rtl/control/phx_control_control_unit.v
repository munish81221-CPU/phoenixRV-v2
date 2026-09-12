module phx_control_main (
    input  wire [31:0] instruction,

    output reg        reg_write,
    output reg        alu_src_a,
    output reg        alu_src,
    output reg        mem_read,
    output reg        mem_write,
    output reg [1:0]  wb_select,
    output reg        branch,
    output reg        jump,
    output reg        jump_reg
);

wire [6:0] opcode;
assign opcode = instruction[6:0];

always @(*) begin

    // Safe defaults
    reg_write = 1'b0;
    alu_src_a = 1'b0;
    alu_src   = 1'b0;
    mem_read  = 1'b0;
    mem_write = 1'b0;
    wb_select = 2'b00;
    branch    = 1'b0;
    jump      = 1'b0;
    jump_reg  = 1'b0;

    case (opcode)

        // instruction classes here
         // R-type
        7'b0110011: begin
            reg_write = 1'b1;
            alu_src_a = 1'b0;
            alu_src   = 1'b0;
            wb_select = 2'b00;
        end

        // I-type ALU
        7'b0010011: begin
            reg_write = 1'b1;
            alu_src_a = 1'b0;
            alu_src   = 1'b1;
            wb_select = 2'b00;
        end

        // Load Word (LW)
        7'b0000011: begin
            reg_write = 1'b1;
            alu_src_a = 1'b0;
            alu_src   = 1'b1;
            mem_read  = 1'b1;
            wb_select = 2'b01;
        end

        // Store Word (SW)
        7'b0100011: begin
            reg_write = 1'b0;
            alu_src_a = 1'b0;
            alu_src   = 1'b1;
            mem_write = 1'b1;
            wb_select = 2'b00;
        end

        // Conditional Branch
        7'b1100011: begin
            reg_write = 1'b0;
            alu_src_a = 1'b0;
            alu_src   = 1'b0;
            branch    = 1'b1;
        end

        // Load Upper Immediate (LUI)
        7'b0110111: begin
            reg_write = 1'b1;
            wb_select = 2'b11;
        end

        // Add Upper Immediate to PC (AUIPC)
        7'b0010111: begin
            reg_write = 1'b1;
            alu_src_a = 1'b1;
            alu_src   = 1'b1;
            wb_select = 2'b00;
        end

        // Jump and Link (JAL)
        7'b1101111: begin
            reg_write = 1'b1;
            wb_select = 2'b10;
            jump      = 1'b1;
            jump_reg  = 1'b0;
        end

        // Jump and Link Register (JALR)
        7'b1100111: begin
            reg_write = 1'b1;
            alu_src_a = 1'b0;
            alu_src   = 1'b1;
            wb_select = 2'b10;
            jump      = 1'b1;
            jump_reg  = 1'b1;
        end


        default: begin
            // Keep safe defaults
             reg_write = 1'b0;
    alu_src_a = 1'b0;
    alu_src   = 1'b0;
    mem_read  = 1'b0;
    mem_write = 1'b0;
    wb_select = 2'b00;
    branch    = 1'b0;
    jump      = 1'b0;
    jump_reg  = 1'b0;

        end

    endcase
end
endmodule