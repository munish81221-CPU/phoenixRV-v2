module phx_common_writeback_mux(

    input [31:0] alu_result,
    input [31:0] memory_data,
    input [31:0] pc_plus_4,
    input [31:0] immediate,

    input [1:0] writeback_select,

    output reg [31:0] writeback_data

);


    always @(*) begin
        
        case(writeback_select)
            2'b00: writeback_data = alu_result;
            2'b01: writeback_data = memory_data;
            2'b10: writeback_data = pc_plus_4;
            2'b11: writeback_data = immediate;
            default: writeback_data = 32'b0;
        endcase
    end

    endmodule