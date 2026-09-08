module phx_datapath_pc_target_adder
#(parameter WIDTH=32)(
    input  [WIDTH-1:0] pc,
    input  [WIDTH-1:0] immediate,
    output [WIDTH-1:0] target
);


wire unused_cout;
phx_common_adder #(.WIDTH(WIDTH)) pc_target_adder

(
     .add_in0(pc),
     .add_in1(immediate),
     .cin(1'b0),
     .sum(target),
     .cout(unused_cout)

);

endmodule