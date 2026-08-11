`timescale 1ns/1ps

module phx_common_add_sub_tb;

parameter WIDTH = 32;

reg [WIDTH-1:0] add_in0;
reg [WIDTH-1:0] add_in1;
reg sel;

wire [WIDTH-1:0] result;
wire cout;

phx_common_add_sub #(.WIDTH(WIDTH)) uut (
    .add_in0(add_in0),
    .add_in1(add_in1),
    .sel(sel),
    .result(result),
    .cout(cout)
);

reg [WIDTH:0] expected;

integer test;
integer passed_count;
integer failed_count;


task check_add_sub;
begin
    if (sel == 1'b0) begin
        expected = {1'b0, add_in0} +
                   {1'b0, add_in1};
    end else begin
        expected = {1'b0, add_in0} +
                   {1'b0, ~add_in1} + 1'b1;
    end

    if ({cout, result} !== expected) begin
        $display("FAILED: A=%h B=%h Sel=%b | Result=%h Cout=%b | Expected Result=%h Expected Cout=%b",
                 add_in0,
                 add_in1,
                 sel,
                 result,
                 cout,
                 expected[WIDTH-1:0],
                 expected[WIDTH]);

        failed_count = failed_count + 1;
    end
    else begin
        passed_count = passed_count + 1;
    end
end
endtask


initial begin
    passed_count = 0;   
    failed_count = 0;
    $dumpfile("sim/phx_common_add_sub_tb.vcd");
    $dumpvars(0, phx_common_add_sub_tb);
//now adding test cases for the adder and subtractor
//direst addition test
    add_in0 = 32'h00000000;
    add_in1 = 32'h00000000;
    sel = 1'b0; // addition
    #1;
    check_add_sub;

    add_in0 = 32'h00000001;
    add_in1 = 32'h00000001;
    sel = 1'b0; // addition
    #1;
    check_add_sub;
    
    add_in0 = 32'hFFFFFFFF;
    add_in1 = 32'h00000001;
    sel = 1'b0; // addition
    #1;
    check_add_sub;

    add_in0 = 32'hFFFFFFFF;
    add_in1 = 32'hFFFFFFFF;
    sel = 1'b0; // addition
    #1;
    check_add_sub;

    //subtration test cases
    add_in0 = 32'h00000000;
    add_in1 = 32'h00000000;
    sel = 1'b1; // subtraction  
    #1;
    check_add_sub;

    add_in0 = 32'h00000005;
    add_in1 = 32'h00000003;
    sel = 1'b1; // subtraction
    #1;
    check_add_sub;

    add_in0 = 32'h00000003;
    add_in1 = 32'h00000005;
    sel = 1'b1; // subtraction
    #1;
    check_add_sub;

    add_in0 = 32'hFFFFFFFF;
    add_in1 = 32'h00000001;
    sel = 1'b1; // subtraction
    #1;
    check_add_sub;

    add_in0 = 32'h12345678;
    add_in1 = 32'h12345678;
    sel = 1'b1; // subtraction
    #1;
    check_add_sub;


    // Random tests
    for (test = 0; test < 1000; test = test + 1) begin
        add_in0 = $random;
        add_in1 = $random;
        sel = $random & 1'b1; // Randomly choose addition or subtraction

        #1;
        check_add_sub;
    end
    
     $display("========================================");
    $display("PhoenixRV add/subVerification");
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

    
        
    
    