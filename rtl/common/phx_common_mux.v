module phx_common_mux
#(
    parameter WIDTH =32,
    parameter INPUTS =4 
 )

    (
        input [WIDTH-1:0] input_data [0:INPUTS-1],
        input [$clog2(INPUTS)-1:0] sel,
        output [WIDTH-1:0] mux_out
    );

    assign mux_out = input_data[sel];

endmodule 

/*module phx_common_mux
#(
    parameter WIDTH  = 32,
    parameter INPUTS = 4
)
(
    input  [WIDTH-1:0] input_data [0:INPUTS-1],
    input  [$clog2(INPUTS)-1:0] sel,
    output [WIDTH-1:0] mux_out
);

assign mux_out = input_data[sel];

endmodule*/
