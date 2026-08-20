`timescale 1ns/1ps
module phx_common_decoder_tb;
parameter INPUT_WIDTH=2;
reg  [1:0] sel_2;
wire [3:0] decoded_2;

reg  [2:0] sel_3;
wire [7:0] decoded_3;

reg  [3:0] sel_4;
wire [15:0] decoded_4;



phx_common_decoder
 #(.INPUT_WIDTH(2))uut_2
( .sel(sel_2),
.decoded(decoded_2));

;
phx_common_decoder
 #(.INPUT_WIDTH(3))uut_3
( .sel(sel_3),
.decoded(decoded_3));

phx_common_decoder
 #(.INPUT_WIDTH(4))uut_4
( .sel(sel_4),
.decoded(decoded_4));


integer passed_count;
integer failed_count;
integer test;


reg [3:0] expected_2;
reg [7:0] expected_3;
reg [15:0] expected_4;


task decoder_check_2;
begin
    case(sel_2)
    2'b00: expected_2=4'b0001;
    2'b01: expected_2=4'b0010;
    2'b10: expected_2=4'b0100;
    2'b11: expected_2=4'b1000;
    endcase 

    if(expected_2 !== decoded_2)
    begin
    $display("FAILED  test=%0d sel=%b expected=%b  decoded=%b ",test,sel_2,expected_2,decoded_2);
     failed_count=failed_count+1;
    end
    else 
    begin
     passed_count=passed_count+1;
    end




end
endtask

task decoder_check_3;
begin
    expected_3='0;
    expected_3[sel_3]=1'b1;

    if(expected_3 !== decoded_3)
    begin
    $display("FAILED    test=%0d  sel=%b  expected=%b   decoded=%b ",test,sel_3,expected_3,decoded_3);
     failed_count=failed_count+1;
    end
    else 
    begin
     passed_count=passed_count+1;
    end

    



end
endtask

task decoder_check_4;
begin
    expected_4='0;
    expected_4[sel_4]=1'b1;

    if(expected_4 !== decoded_4)
    begin
    $display("FAILED    test=%0d  sel=%b  expected=%b   decoded=%b ",test,sel_4,expected_4,decoded_4);
     failed_count=failed_count+1;
    end
    else 
    begin
     passed_count=passed_count+1;
    end

   



end
endtask

initial begin
    passed_count=0;
    failed_count=0;
    test=0;
   

    $dumpfile("sim/phx_common_decoder_tb.vcd");
    $dumpvars(0,phx_common_decoder_tb);

    //direct test for 2-4 decoder.
    sel_2=2'b00;
    #1
    decoder_check_2;

    sel_2=2'b01;
    #1
    decoder_check_2;

    sel_2=2'b10;
    #1
    decoder_check_2;

    sel_2=2'b11;
    #1
    decoder_check_2;


    // direct test for 3->9 decoder.
    for (test=0;test<8;test=test+1)
    begin
    sel_3=test;
    #1
    decoder_check_3;
    end

    //direct test for 4->16 decoder.
    for (test=0;test<16;test=test+1)
    begin
    sel_4=test;
    #1;
    decoder_check_4;
    end

    $display("========================================");
    $display("PhoenixRV common parametarized decoder");
    $display("========================================");
    $display("Directed tests");
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
