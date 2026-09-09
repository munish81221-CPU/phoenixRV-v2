module phx_datapath_pc_target_adder_tb;
parameter WIDTH =32;
reg [WIDTH-1:0] pc;
reg [WIDTH-1:0] immediate;
wire [WIDTH-1:0] target;


phx_datapath_pc_target_adder #(.WIDTH(WIDTH)) uut
(
    .pc(pc),
    .immediate(immediate),
    .target(target)
);


integer passed_count;
integer failed_count;
integer i;


task target_check;
    input [31:0] test_pc;
    input [31:0] test_immediate;

    reg [31:0] expected;

    begin
        pc = test_pc;
        immediate = test_immediate;

        #1;

        expected = test_pc + test_immediate;

        if (target === expected) begin
            $display("PASS: PC=%h Immediate=%h Target=%h Expected=%h",
                     test_pc, test_immediate, target, expected);
            passed_count = passed_count + 1;
        end
        else begin
            $display("FAIL: PC=%h Immediate=%h Target=%h Expected=%h",
                     test_pc, test_immediate, target, expected);
            failed_count = failed_count + 1;
        end
    end
endtask

initial begin
    passed_count =0;
    failed_count =0;

    $dumpfile("sim/phx_datapath_pc_target_adder_tb.vcd");
    $dumpvars(0,phx_datapath_pc_target_adder_tb);


//direct tests 
target_check(32'd0, 32'd0);
target_check(32'd100, 32'd0);
target_check(32'd100, 32'd20);
target_check(32'd100, 32'hFFFFFFEC);       // -20
target_check(32'h00001000, 32'h00000100);
target_check(32'h00001000, 32'hFFFFF000);
target_check(32'hFFFFFFF0, 32'h00000020);
target_check(32'hFFFFFFFF, 32'h00000001);

//random tests 
for (i=0;i<100;i=i+1)
begin 
    
    target_check($random, $random);

end 

$display("passed_count=%d    failed_count=%d",passed_count,failed_count);

$finish;
end
endmodule