module phx_common_data_memory #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 32,
    parameter int DEPTH      = 256
)(
    input  logic                  clk,
    input  logic                  reset,

    input  logic                  mem_read,
    input  logic                  mem_write,

    input  logic [ADDR_WIDTH-1:0] address,
    input  logic [DATA_WIDTH-1:0] write_data,

    output logic [DATA_WIDTH-1:0] read_data
);

    localparam int INDEX_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    logic [INDEX_WIDTH-1:0] word_index;

    assign word_index = address[INDEX_WIDTH+1:2];

    always_ff @(posedge clk) begin
        if (mem_write)
            memory[word_index] <= write_data;
    end

    always_comb begin
        if (mem_read)
            read_data = memory[word_index];
        else
            read_data = '0;
    end

endmodule