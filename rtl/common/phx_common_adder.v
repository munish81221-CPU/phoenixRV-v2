module phx_common_adder
#(parameter WIDTH=32)
(
    input [WIDTH-1:0]add_in0,
    input [WIDTH-1:0]add_in1,
    input cin,
    output [WIDTH-1:0]sum,
    output cout

);
//calculate the number of stages needed for the prefix adder
localparam STAGES = $clog2(WIDTH);
//generate propagate and generate signals for each stage
wire[WIDTH-1:0] P[0:STAGES];
wire[WIDTH-1:0] G[0:STAGES];
wire [WIDTH:0] C;
//initial propagate and generate signals
assign P[0] = add_in0 ^ add_in1;
assign G[0] = add_in0 & add_in1;
assign C[0] = cin;

genvar s;
//prefix generation for each stage
generate
    for (s = 0; s < STAGES; s = s + 1) begin : prefix_stage
        localparam integer DIST = (1 << s);
        genvar i;

        for(i=0;i<WIDTH;i=i+1)begin :prefix_bit 
         if(i>=DIST)begin : has_prefix

         assign G[s+1][i]=G[s][i]|(P[s][i]&G[s][i-DIST]);

         assign P[s+1][i]=P[s][i]&P[s][i-DIST];
         end

         else begin : no_prefix

         assign G[s+1][i]=G[s][i];
         assign P[s+1][i]=P[s][i];


         end
        end

    end
endgenerate
//carry genaration for each bit
genvar k;
generate 
    for(k=0;k<WIDTH;k=k+1)begin : carry_gen
        assign C[k+1]=G[STAGES][k]|(P[STAGES][k]&cin);
    end
    endgenerate
//final sum and carry genaration 
    assign sum = P[0] ^ C[WIDTH-1:0];
    assign cout = C[WIDTH];
endmodule
