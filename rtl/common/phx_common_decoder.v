module phx_common_decoder
#(parameter INPUT_WIDTH =2)
(input [INPUT_WIDTH-1:0]sel,
output [(1<<INPUT_WIDTH)-1:0]decoded);

assign decoded=1'b1 << sel;
endmodule
