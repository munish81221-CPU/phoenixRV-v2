
module phx_common_shifter
#(parameter WIDTH = 32)
(
    input  [WIDTH-1:0] data_in,
    input  [$clog2(WIDTH)-1:0] shift_amount,
    input  [1:0] operation,
    output [WIDTH-1:0] shift_out
);

//calculating how  amny stages are required
localparam STAGES = $clog2(WIDTH);

//defining code number for each operation
localparam SLL = 2'b00;
localparam SRL = 2'b01;
localparam SRA = 2'b10;


//required no of stages with each stage with given no of bits
wire [WIDTH-1:0] stage [0:STAGES];

//connecting stage 1 with inputdata
assign stage[0] = data_in;



// Generate barrel-shifter stages
genvar s;
genvar b;

generate

    for (s = 0; s < STAGES; s = s + 1) begin : shift_stage

        for (b = 0; b < WIDTH; b = b + 1) begin : shift_bit

            
            // calculation for SLL
           

            wire sll_bit;

            if (b >= (1 << s)) begin : sll_valid

                assign sll_bit =
                    stage[s][b - (1 << s)];

            end
            else begin : sll_boundary

                assign sll_bit = 1'b0;

            end


            
            //calculatio for  SRL
            

            wire srl_bit;

            if (b + (1 << s) < WIDTH) begin : srl_valid

                assign srl_bit =
                    stage[s][b + (1 << s)];

            end
            else begin : srl_boundary

                assign srl_bit = 1'b0;

            end


            
            // calculation for SRA
           

            wire sra_bit;

            if (b + (1 << s) < WIDTH) begin : sra_valid

                assign sra_bit =
                    stage[s][b + (1 << s)];

            end
            else begin : sra_boundary

                assign sra_bit =
                    stage[s][WIDTH-1];

            end


            //defining shifted bits as per the given operation like if operation is SLL then use sll_bits

            wire shifted_bit;

            assign shifted_bit =
                (operation == SLL) ? sll_bit :
                (operation == SRL) ? srl_bit :
                (operation == SRA) ? sra_bit :
                                     stage[s][b];


           //given upon the shift_amount we define next stage should receive previous stage 
           //data or the shifted data 
            assign stage[s+1][b] =
                shift_amount[s] ?
                shifted_bit :
                stage[s][b];

        end

    end

endgenerate


//connecting final stage output to module output

assign shift_out = stage[STAGES];

endmodule