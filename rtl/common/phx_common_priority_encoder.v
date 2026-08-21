module phx_common_priority_encoder
#(parameter INPUT =8)
( input [INPUT-1:0] input_data,
  output reg [$clog2(INPUT)-1:0] encoded,
  output reg valid );

  integer i;
  reg found;

  always @(*) begin
    
    //Default values 
    encoded ='0;
    valid =1'b0;
    found =1'b0;

    //searching from higher priority to lower priority

    for(i=INPUT-1;i>=0;i=i-1)
    begin
        if((input_data[i]==1'b1)&&(found ==1'b0))
        begin
            encoded=i;
            valid =1'b1;
            found =1'b1;

        end
    end
  end
endmodule