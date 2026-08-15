`timescale 1ns/1ps
module phx_common_shifter_tb;
parameter WIDTH =32 ;
reg [WIDTH-1:0] data_in;
reg [$clog2(WIDTH)-1:0]shift_amount;
reg [1:0]operation;
wire [WIDTH-1:0]shift_out;


phx_common_shifter #(.WIDTH(WIDTH)) uut(
    .data_in(data_in),
    .shift_amount(shift_amount),
    .operation(operation),
    .shift_out(shift_out)

);

reg[WIDTH-1:0]expected;
integer test;
integer passed_count;
integer failed_count;

localparam SLL=2'b00;
localparam SRL=2'b01;
localparam SRA=2'b10;

task check_shifter;

begin
    case(operation)
    SLL:begin
        expected=data_in << shift_amount;
    end
    SRL:begin
        expected=data_in >> shift_amount;
    end
    SRA:begin
        expected=$signed(data_in) >>> shift_amount;

    end
    default:begin
        expected=data_in;

    end
    endcase


if(shift_out != expected)begin
    $display( "FAILED : test=%0d  data_in=%h  operation=%b shift=%d |DUT=%h |expected=%h",
    test,
    data_in,
    operation,
    shift_amount,
    shift_out,
    expected);

    failed_count = failed_count + 1;
end

else begin
    passed_count =passed_count+1;
end
test=test+1;

end
endtask


initial begin
    
    passed_count=0;
    failed_count=0;
    test=0;

    $dumpfile("sim/phx_common_shifter_tb.vcd");
    $dumpvars(0,phx_common_shifter_tb);
// SLL direct test
    data_in =32'h00000001;
    shift_amount=0;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'h00000001;
    shift_amount=1;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'h00000001;
    shift_amount=5;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'h80000000;
    shift_amount=1;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'hFFFFFFFF;
    shift_amount=31;
    operation = SLL;
    #1;
    check_shifter;

// SRL direct test

    data_in =32'h00000000;
    shift_amount=1;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'hFFFFFFFF;
    shift_amount=4;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'h80000000;
    shift_amount=31;
    operation = SLL;
    #1;
    check_shifter;

// SRA direct test

    data_in =32'h80000000;
    shift_amount=1;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'h80000000;
    shift_amount=4;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'hFFFFFFFF;
    shift_amount=16;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'h7FFFFFFF;
    shift_amount=8;
    operation = SLL;
    #1;
    check_shifter;

// direct test with zero shift

    data_in =32'hA5A5A5A5;
    shift_amount=0;
    operation = SLL;
    #1;
    check_shifter;

    data_in =32'hA5A5A5A5;
    shift_amount=0;
    operation = SRL;
    #1;
    check_shifter;

    data_in =32'hA5A5A5A5;
    shift_amount=0;
    operation = SRA;
    #1;
    check_shifter;

//random test

for(test=test; test<1014; test=test+1)begin
    data_in=$random;
    shift_amount=$random;
    operation=$random &2'b11;

    if(operation == 2'b11)
    operation = $random&2'b01;
    #1;

    check_shifter;


end


$display("========================================");
    $display("PhoenixRV shifter");
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
    












