module phx_common_pc_target(
    input [31:0] pc,
    input [31:0] immediate,
    output [31:0] pc_target
);

assign pc_target = pc + immediate;
endmodule
