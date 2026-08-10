`timescale 1ns/1ps

module phx_common_adder_tb;

parameter WIDTH = 32;

reg [WIDTH-1:0] add_in0;
reg [WIDTH-1:0] add_in1;
reg cin;

wire [WIDTH-1:0] sum;
wire cout;

phx_common_adder #(.WIDTH(WIDTH)) uut (
    .add_in0(add_in0),
    .add_in1(add_in1),
    .cin(cin),
    .sum(sum),
    .cout(cout)
);

reg [WIDTH:0] expected;

integer test;
integer passed_count;
integer failed_count;

task check_adder;
begin
    expected = {1'b0, add_in0} +
               {1'b0, add_in1} +
               cin;

    if ({cout, sum} !== expected) begin
        $display("FAILED: A=%h B=%h Cin=%b | Sum=%h Cout=%b | Expected Sum=%h Expected Cout=%b",
                 add_in0,
                 add_in1,
                 cin,
                 sum,
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

    $dumpfile("sim/phx_common_adder_tb.vcd");
    $dumpvars(0, phx_common_adder_tb);

    passed_count = 0;
    failed_count = 0;

    // Directed test 1
    add_in0 = 32'h00000000;
    add_in1 = 32'h00000000;
    cin = 1'b0;
    #1;
    check_adder;

    // Directed test 2
    add_in0 = 32'hFFFFFFFF;
    add_in1 = 32'h00000001;
    cin = 1'b0;
    #1;
    check_adder;

    // Directed test 3
    add_in0 = 32'h00000001;
    add_in1 = 32'h00000001;
    cin = 1'b0;
    #1;
    check_adder;

    // Directed test 4
    add_in0 = 32'hFFFFFFFF;
    add_in1 = 32'hFFFFFFFF;
    cin = 1'b0;
    #1;
    check_adder;

    // Directed test 5
    add_in0 = 32'hFFFFFFFF;
    add_in1 = 32'hFFFFFFFF;
    cin = 1'b1;
    #1;
    check_adder;

    // Random tests
    for (test = 0; test < 1000; test = test + 1) begin

        add_in0 = $random;
        add_in1 = $random;
        cin = $random & 1'b1;

        #1;
        check_adder;

    end

    $display("========================================");
    $display("PhoenixRV Kogge-Stone Adder Verification");
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