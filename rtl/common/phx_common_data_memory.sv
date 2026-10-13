module phx_common_data_memory #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 32,
    parameter int DEPTH      = 256
)(
    input  logic                  clk,
    input  logic                  reset,

    input  logic                  mem_read,
    input  logic                  mem_write,
    input  logic [2:0]            access_funct3,

    input  logic [ADDR_WIDTH-1:0] address,
    input  logic [DATA_WIDTH-1:0] write_data,

    output logic [DATA_WIDTH-1:0] read_data
);

    localparam int INDEX_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    logic [INDEX_WIDTH-1:0] word_index;
    logic [31:0] selected_word;
    logic [7:0] selected_byte;
    logic [15:0] selected_half;
    integer lane;

    assign word_index = address[INDEX_WIDTH+1:2];
    assign selected_word = memory[word_index];
    assign selected_byte = selected_word[8*address[1:0] +: 8];
    assign selected_half = selected_word[16*address[1] +: 16];

    // Little-endian byte/halfword writes. Unselected lanes are preserved.
    always_ff @(posedge clk) begin
        if (mem_write) begin
            case (access_funct3)
                3'b000: begin // SB
                    for (lane = 0; lane < 4; lane = lane + 1)
                        if (address[1:0] == lane)
                            memory[word_index][8*lane +: 8] <= write_data[7:0];
                end
                3'b001: begin // SH: naturally aligned offsets 0 or 2
                    if (address[0] == 1'b0)
                        memory[word_index][16*address[1] +: 16] <= write_data[15:0];
                end
                3'b010: memory[word_index] <= write_data; // SW
                default: ; // Unsupported store width: no write
            endcase
        end
    end

    always_comb begin
        read_data = '0;
        if (mem_read) begin
            case (access_funct3)
                3'b000: read_data = {{24{selected_byte[7]}}, selected_byte}; // LB
                3'b001: read_data = {{16{selected_half[15]}}, selected_half}; // LH
                3'b010: read_data = selected_word; // LW
                3'b100: read_data = {24'b0, selected_byte}; // LBU
                3'b101: read_data = {16'b0, selected_half}; // LHU
                default: read_data = '0;
            endcase
        end
    end

endmodule