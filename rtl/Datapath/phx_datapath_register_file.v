module register_file #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input clk,
    input reset,
    input write_enable,

    input [ADDR_WIDTH-1:0] write_address,
    input [DATA_WIDTH-1:0] write_data,

    input [ADDR_WIDTH-1:0] read_address1,
    input [ADDR_WIDTH-1:0] read_address2,

    output [DATA_WIDTH-1:0] read_data1,
    output [DATA_WIDTH-1:0] read_data2
);

integer i;

reg [DATA_WIDTH-1:0] registers [0:(2**ADDR_WIDTH)-1];

always @(posedge clk or posedge reset) begin

    if (reset) begin
        for (i = 0; i < 2**ADDR_WIDTH; i = i + 1)
            registers[i] <= {DATA_WIDTH{1'b0}};
    end

    else if (write_enable &&
             write_address != {ADDR_WIDTH{1'b0}}) begin

        registers[write_address] <= write_data;

    end

end

// Asynchronous read ports.
// Register x0 always returns zero.

assign read_data1 =
    (read_address1 == {ADDR_WIDTH{1'b0}})
    ? {DATA_WIDTH{1'b0}}
    : registers[read_address1];

assign read_data2 =
    (read_address2 == {ADDR_WIDTH{1'b0}})
    ? {DATA_WIDTH{1'b0}}
    : registers[read_address2];

endmodule