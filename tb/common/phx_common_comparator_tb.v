`timescale 1ns/1ps
module phx_common_comparator_tb
    #(parameter WIDTH =32);

    reg  [WIDTH-1:0] add_in0;
    reg  [WIDTH-1:0] add_in1;
    reg  signed_mode;
    wire  eq;
    wire  lt;
    wire  gt;


phx_common_comparator #(
    .WIDTH(WIDTH) ) uut(
        .add_in0(add_in0),
        .add_in1(add_in1),
        .signed_mode(signed_mode),
        .eq(eq),
        .lt(lt),
        .gt(gt)
    );


    reg expected_eq;
    reg expected_lt;
    reg expected_gt;

    integer test;
    integer passed_count;   
    integer failed_count;

task check_comparator;
begin
    //equality is sam for both signed and unsigned values
    expected_eq = (add_in0 == add_in1);

    if(signed_mode==1'b0) begin
        //unsigned comparison
        expected_lt=(add_in0 < add_in1);
        expected_gt=(add_in0 > add_in1);
    end

    else begin
        //signed comparison
        expected_lt=($signed(add_in0) < $signed(add_in1));
        expected_gt=($signed(add_in0) > $signed(add_in1));
    end


    if((eq !==expected_eq)||(lt !==expected_lt)||
       (gt !==expected_gt)) begin
        $display("FAILED: test =%0d A=%h B=%h Signed_mode=%b | EQ=%b LT=%b GT=%b | Expected EQ=%b Expected LT=%b Expected GT=%b",
                 test,
                 add_in0,
                 add_in1,
                 signed_mode,
                 eq,
                 lt,
                 gt,
                 expected_eq,
                 expected_lt,
                 expected_gt);
        failed_count=failed_count+1;
    end
    else begin
        passed_count=passed_count+1;
    end 
end 
endtask

initial begin
    passed_count =0;
    failed_count=0;

    $dumpfile("sim/phx_common_comparator_tb.vcd");
    $dumpvars(0, phx_common_comparator_tb);

//unsigned direct cases

add_in0 = 32'h00000000;
add_in1 = 32'h00000000;
signed_mode=1'b0;   
#1;
check_comparator;

add_in0 = 32'h00000001;
add_in1 = 32'h00000002;
signed_mode=1'b0;   
#1;
check_comparator;

add_in0 = 32'h00000002;
add_in1 = 32'h00000001;
signed_mode=1'b0;   
#1;
check_comparator;

add_in0 = 32'hFFFFFFFF;
add_in1 = 32'h00000001;
signed_mode=1'b0;   
#1;
check_comparator;

add_in0 = 32'h00000001;
add_in1 = 32'hFFFFFFFF;
signed_mode=1'b0;   
#1;
check_comparator;

//signed direct cases 

add_in0 = 32'hFFFFFFFF;
add_in1 = 32'h00000001;
signed_mode=1'b1;   
#1;
check_comparator;

add_in0 = 32'h00000001;
add_in1 = 32'hFFFFFFFF; 
signed_mode=1'b1;
#1;
check_comparator;


add_in0 = 32'hFFFFFFFD;
add_in1 = 32'hFFFFFFFF;
signed_mode=1'b1;   
#1;
check_comparator;

add_in0 = 32'hFFFFFFFA;
add_in1 = 32'hFFFFFFFD;
signed_mode=1'b1;   
#1;
check_comparator;

add_in0 = 32'hFFFFFFFF;
add_in1 = 32'hFFFFFFFF;
signed_mode=1'b1;   
#1;
check_comparator;


// random tests
for(test=0; test<1000; test=test+1) begin
    add_in0 = $random;
    add_in1 = $random;
    signed_mode = $random & 1'b1;
    #1;
    check_comparator;



end
 $display("========================================");
    $display("PhoenixRV comparator");
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