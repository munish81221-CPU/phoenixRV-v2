module phx_common_pc_register #(
    parameter RESET_ADDRESS =32'h00000000
)(
    input clk,
    input reset,
    input [31:0]next_pc,
    output reg[31:0]current_pc
);

always @(posedge clk) begin
    if (reset)
        current_pc <= RESET_ADDRESS;
    else
        current_pc <= next_pc;
end
endmodule