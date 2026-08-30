module phx_common_next_pc_mux (
    input [31:0] pc_plus_4,
    input [31:0] branch_target,
    input [31:0] jump_target,
    input [31:0] alternate_target,

    input [1:0] select,

    output reg[31:0] next_pc
    );


    always@(*)begin
        
    //default value defining 
    next_pc = pc_plus_4;

    case(select)
    2'b00:next_pc = pc_plus_4;
    2'b01:next_pc = branch_target;
    2'b10:next_pc = jump_target;
    2'b11:next_pc = alternate_target;

    default: next_pc = pc_plus_4;
    endcase

    end
endmodule