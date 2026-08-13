module phx_common_comparator
#(parameter WIDTH = 32)
(input  [WIDTH-1:0] add_in0,
 input [WIDTH-1:0] add_in1,
 input  signed_mode,
 output eq,
 output lt,
 output gt
 );

// lets understand the flow first then implement the code
/*                 add_in0 / add_in1
                         │
                         ▼
                    bit_equal
                    /        \
                   ▼          ▼
                  eq       unsigned
                           comparison
                           /       \
                          ▼         ▼
                    unsigned_gt  unsigned_lt
                          │         │
                          └────┬────┘
                               ▼
                         signed logic
                               │
                         signed_gt/lt
                               │
                         signed_mode
                               │
                         ┌─────┴─────┐
                         ▼           ▼
                         gt          lt

*/

 wire [WIDTH-1:0] bit_equal;
 assign bit_equal= ~(add_in0^add_in1);
 assign eq=&bit_equal;
 //&bit equal is a reduction AND operation that checks if all bits are equal, resulting in 1 if they are equal and 0 otherwise.
 //&bit_equal , for eg bit_equal=4'b1111,then eq=1&1&1&1=1

// unsigned  comparater
wire [WIDTH-1:0] higher_same;
wire [WIDTH-1:0] gt_bits;
wire [WIDTH-1:0] lt_bits;


genvar i;
generate
    for (i=WIDTH-1; i>=0; i=i-1) begin :compare_bits

    if(i==WIDTH-1) begin :msb_compare
    assign higher_same[i] =1'b1;
    end

    else begin :lower_compare
    assign higher_same[i]=higher_same[i+1]&bit_equal[i+1];
    end

    assign gt_bits[i]= add_in0[i]&~add_in1[i]&higher_same[i];
    assign lt_bits[i]= ~add_in0[i]&add_in1[i]&higher_same[i];
    
    end
endgenerate

wire unsigned_gt;
wire unsigned_lt;

assign unsigned_gt = |gt_bits;
assign unsigned_lt = |lt_bits;
// signed comparater



wire a_sign;
wire b_sign;
wire same_sign;
wire signed_gt;
wire signed_lt;

assign a_sign=add_in0[WIDTH-1];
assign b_sign=add_in1[WIDTH-1];

assign same_sign=~(a_sign^b_sign);

assign signed_gt=(~a_sign&b_sign)|(same_sign & unsigned_gt);
assign signed_lt=(a_sign&~b_sign)|(same_sign & unsigned_lt);

assign gt=signed_mode?signed_gt:unsigned_gt;
assign lt=signed_mode?signed_lt:unsigned_lt;


endmodule


