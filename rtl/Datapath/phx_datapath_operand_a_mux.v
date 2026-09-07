module phx_datapath_operand_a_mux
#(parameter WIDTH=32)(
    input [WIDTH-1:0] read_data1,
    input [WIDTH-1:0] pc,
    input             alu_src_a,
    output [WIDTH-1:0] operand_a
);

    phx_common_mux2 #(.WIDTH(WIDTH)) mux (
        .in0(read_data1),
        .in1(pc),
        .sel(alu_src_a),
        .out(operand_a)
    );

endmodule