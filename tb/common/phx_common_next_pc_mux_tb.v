module phx_common_next_pc_mux_tb;
reg [31:0]pc_plus_4;
reg [31:0]branch_target;
reg [31:0]jump_target;
reg [31:0]alternate_target;
reg [1:0]select;
wire [31:0]next_pc;


phx_common_next_pc_mux uut(
    .pc_plus_4(pc_plus_4),
    .branch_target(branch_target),
    .jump_target(jump_target),
    .alternate_target(alternate_target),
    .select(select),
    .next_pc(next_pc)
);

reg [31:0]expected;

integer passed_count;
integer failed_count;
integer test;
integer i;

task check_next_pc;
begin
    case(select)
    2'b00:expected = pc_plus_4;
    2'b01:expected = branch_target;
    2'b10:expected = jump_target;
    2'b11:expected = alternate_target;

    default: expected = pc_plus_4;
    endcase

    if(expected!== next_pc)
    begin
    $display("failed test=%d expected =%b next_pc=%b",test,expected,next_pc);
    failed_count = failed_count + 1;
    end 
    else 
    begin
    passed_count = passed_count + 1;
    end 
    test=test+1;

    end
endtask

initial begin;
passed_count = 0;
failed_count = 0;
test = 0;
expected = 0;

$dumpfile("sim/phx_common_next_pc_mux_tb.vcd");
$dumpvars(0,phx_common_next_pc_mux_tb);
 
// first direct tests
pc_plus_4       = 32'h11111111;
branch_target   = 32'h22222222;
jump_target     = 32'h33333333;
alternate_target = 32'h44444444;

select = 2'b00; 
#1;
check_next_pc;
select = 2'b01; 
#1; 
check_next_pc;
select = 2'b10; 
#1; 
check_next_pc;
select = 2'b11; 
#1; 
check_next_pc;

// second diresct tests
pc_plus_4        = 32'h00000000;
branch_target    = 32'hFFFFFFFF;
jump_target      = 32'h12345678;
alternate_target = 32'hABCDEF01;

select = 2'b00; 
#1;
check_next_pc;
select = 2'b01; 
#1; 
check_next_pc;
select = 2'b10; 
#1; 
check_next_pc;
select = 2'b11; 
#1; 
check_next_pc;

// random tests

for (i=0; i<50 ; i=i+1)
begin
    select=$random;
    #1;
    check_next_pc;

end

    $display("========================================");
    $display("PhoenixRV common next pc");
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