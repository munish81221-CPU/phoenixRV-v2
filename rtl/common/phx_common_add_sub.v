module phx_common_add_sub #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] add_in0,
    input  wire [WIDTH-1:0] add_in1,
    input  wire                   sel,
    output wire [WIDTH-1:0] result,
    output wire                  cout
);
wire [WIDTH-1:0] b_operand;
assign b_operand =add_in1^{WIDTH{sel}}; 

phx_common_adder #(
    .WIDTH(WIDTH)
) adder (
    .add_in0(add_in0),
    .add_in1(b_operand),
    .cin(sel),
    .sum(result),
    .cout(cout)
);
   
endmodule