module phx_common_mux4
#(parameter WIDTH = 32)
(
    input [WIDTH-1:0] in0,
    input [WIDTH-1:0] in1,
    input [WIDTH-1:0] in2,
    input [WIDTH-1:0] in3,
    input [1:0] sel,
    output [WIDTH-1:0] out
);
wire [WIDTH-1:0] mux01_out;
wire [WIDTH-1:0] mux23_out;

phx_common_mux2 #(.WIDTH(WIDTH)) mux01 (
    .in0(in0),
    .in1(in1),
    .sel(sel[0]),
    .out(mux01_out)
);

phx_common_mux2 #(.WIDTH(WIDTH)) mux23 (
    .in0(in2),
    .in1(in3),
    .sel(sel[0]),
    .out(mux23_out)
);

phx_common_mux2 #(.WIDTH(WIDTH)) mux_final (
    .in0(mux01_out),
    .in1(mux23_out),
    .sel(sel[1]),
    .out(out)
);
endmodule