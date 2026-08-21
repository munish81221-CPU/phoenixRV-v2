`timescale 1ns/1ps
module phx_common_priority_encoder_tb;
parameter INPUTS = 8;
reg [INPUTS-1:0] input_data ;
wire [$clog2(INPUTS)-1:0] encoded;
wire valid;

phx_common_priority_encoder #(.INPUT(INPUTS)) uut_8
(.input_data(input_data),
 .encoded(encoded),
 .valid(valid));

 integer test;
 reg [$clog2(INPUTS)-1:0]expected_encoded;
 reg expected_valid;
integer passed_count;
integer failed_count;
integer i;

task priority_encoder_check;
begin
    if(input_data[7])begin
        expected_encoded = 3'd7;
        expected_valid = 1'b1;
    end

    else if(input_data[6])begin
        expected_encoded = 3'd6;
        expected_valid = 1'b1;
    end

    else if(input_data[5])begin
        expected_encoded = 3'd5;
        expected_valid = 1'b1;
    end

    else if(input_data[4])begin
        expected_encoded = 3'd4;
        expected_valid = 1'b1;
    end

    else if(input_data[3])begin
        expected_encoded = 3'd3;
        expected_valid = 1'b1;
    end

    else if(input_data[2])begin
        expected_encoded = 3'd2;
        expected_valid = 1'b1;
    end

    else if(input_data[1])begin
        expected_encoded = 3'd1;
        expected_valid = 1'b1;
    end

    else if(input_data[0])begin
        expected_encoded = 3'd0;
        expected_valid = 1'b1;
    end

    else begin
        expected_encoded = 3'd0;
        expected_valid = 1'b0;
    end

    if((expected_encoded!==encoded)||(expected_valid!==valid))
    begin
        $display("FAILED  test=%d  encoded=%b valid=%b expected_encoded=%b expected_valid=%b",test,encoded,valid,expected_encoded,expected_valid);
        failed_count=failed_count+1;
    
    end
    else begin
        passed_count=passed_count+1;

    end
    test=test+1;
end 
endtask

initial begin
    passed_count=0;
    failed_count=0;
    test=0;
    $dumpfile("sim/phx_common_priority_encoder_tb.vcd");
    $dumpvars(0,phx_common_priority_encoder_tb);

    //direct tests
    input_data =8'b01001100;
    #1;
     priority_encoder_check;

    input_data =8'b01101100;
    #1;
     priority_encoder_check;

    input_data =8'b00001100;
    #1;
     priority_encoder_check;

    input_data =8'b11111111;
    #1;
     priority_encoder_check;

    input_data =8'b00000000;
    #1;
     priority_encoder_check;

     input_data = 8'b00000001;
    #1;
    priority_encoder_check;

    input_data = 8'b10000000;
    #1;
    priority_encoder_check;
    //randon tests
    for(i=0;i<256;i=i+1)
    begin
        input_data=$random;
        #1;
        priority_encoder_check;

    end

    $display("========================================");
    $display("PhoenixRV priority encoder test");
    $display("========================================");
    $display("Directed + Random Tests");
    $display("Passed : %0d", passed_count);
    $display("Failed : %0d", failed_count);
    $display("========================================");

    if (failed_count == 0) begin
        $display("ALL TESTS PASSED!");
    end
    else begin
        $display("SOME TESTS FAILED.");
    end

    $finish;

end
endmodule
