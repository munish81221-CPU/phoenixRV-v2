`timescale 1ns/1ps
module phx_common_pc_target_tb;
reg [31:0] pc;
reg [31:0] immediate;
wire [31:0] pc_target;

phx_common_pc_target uut(
    .pc(pc),
    .immediate(immediate),
    .pc_target(pc_target)
);

integer test;
integer passed_count;
integer failed_count;
reg [31:0]expected;
integer i;

task pc_target_check;
begin
    
    expected = pc + immediate;

    if(expected !== pc_target)
    begin
    $display(" FAILED   test=%h  expected=%h  pc_target=%h",test,expected,pc_target);
    failed_count = failed_count + 1;
    end
    else 
    begin
    passed_count = passed_count + 1;
    end

test =test +1;

end
endtask

initial begin
    passed_count = 0;
    failed_count = 0;
    test = 0;
    expected = 0;

    $dumpfile("sim/phx_common_pc_target_tb.vcd");
    $dumpvars(0,phx_common_pc_target_tb);

    pc = 32'h00000000;
    immediate = 32'h00000000;
    #1;
    pc_target_check;


     pc = 32'h00000064;
    immediate = 32'h00000014;
    #1;
    pc_target_check;

     pc = 32'h12345678;
    immediate = 32'h00000000;
    #1;
    pc_target_check;
    
     pc = 32'h00000064;
    immediate = 32'hFFFFFFFC;
    #1;
    pc_target_check;

     pc = 32'h00001000;
    immediate = 32'h00002000;
    #1;
    pc_target_check;

     pc = 32'hFFFFFFFC;
    immediate = 32'h00000001;
    #1;
    pc_target_check;

     pc = 32'h80000000;
    immediate = 32'hFFFFFFF0;
    #1;
    pc_target_check;

    for(i=0; i<=100; i=i+1)
    begin
        pc=$random;
        immediate = $random;
        #10;
        pc_target_check;
    end
    


     $display("========================================");
    $display("PhoenixRV common pc target");
    $display("========================================");
    $display("Directed + random");
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