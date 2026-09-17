module phx_control_pc_select (
    input  logic       branch,
    input  logic       branch_taken,
    input  logic       jump,
    input  logic       jump_reg,

    output logic [1:0] pc_select
);

    
    localparam logic [1:0] PC_SEQ    = 2'b00;
    localparam logic [1:0] PC_BRANCH = 2'b01;
    localparam logic [1:0] PC_JAL    = 2'b10;
    localparam logic [1:0] PC_JALR   = 2'b11;

    always_comb begin

        // Safe default:
        pc_select = PC_SEQ;

        // Highest priority: JALR
        if (jump && jump_reg) begin
            pc_select = PC_JALR;
        end

        // JAL
        else if (jump) begin
            pc_select = PC_JAL;
        end

        // Taken conditional branch
        else if (branch && branch_taken) begin
            pc_select = PC_BRANCH;
        end

        // Otherwise PC + 4
        else begin
            pc_select = PC_SEQ;
        end

    end

endmodule