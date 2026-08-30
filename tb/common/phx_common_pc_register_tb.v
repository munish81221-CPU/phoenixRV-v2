module phx_common_pc_register_tb;
    parameter RESET_ADDRESS =32'h00000000;
    reg clk;
    reg reset;
    reg [31:0]next_pc;
    wire [31:0]current_pc;

 phx_common_pc_register #(.RESET_ADDRESS(RESET_ADDRESS)) uut
 (.clk(clk),
  .reset(reset),
  .next_pc(next_pc),
  .current_pc(current_pc));

  always #5 clk=~clk;
  reg [31:0]expected;

  integer passed_count;
  integer failed_count;
  integer test;
  integer i;

  task check_pc_register;
  begin
     if(expected!== current_pc)
    begin
    $display("failed test=%d expected =%b current_pc=%b"
    ,test,expected,current_pc);
    failed_count = failed_count + 1;
    end 
    else 
    begin
    passed_count = passed_count + 1;
    end 
    test=test+1;

    
  end
  endtask




  initial begin
    clk=1'b0;
    passed_count = 0;
    failed_count = 0;
    test = 0;
    reset =1'b0;
    next_pc = 32'h00000000;
    expected = 32'h00000000;

    $dumpfile("sim/phx_common_pc_register_tb.vcd");
    $dumpvars(0,phx_common_pc_register_tb);

    reset=1;
    @(posedge clk)
    #1;
    expected = 32'h00000000;
    check_pc_register;

    reset=0;
    next_pc = 32'h00000004;
    @(posedge clk);
    #1;
    expected =32'h00000004;
    check_pc_register;

    next_pc = 32'h00000008;
    @(posedge clk);
    #1;
    expected = 32'h00000008;
    check_pc_register;

     next_pc = 32'h80000000;
    @(posedge clk);
    #1;
    expected = 32'h80000000;
    check_pc_register;

    reset=1;
    next_pc = 32'hFFFFFFFF;
    @(posedge clk);
    #1;
    expected = 32'h00000000;
    check_pc_register;

    // reset has more priority over next-pc

    for(i = 0; i < 50; i = i + 1) begin

    reset = $random;
    next_pc = $random;

    if(reset)
    expected = RESET_ADDRESS;
    else
    expected = next_pc;

    @(posedge clk);
    #1;

    check_pc_register;

    end

    $display("========================================");
    $display("PhoenixRV common pc register");
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