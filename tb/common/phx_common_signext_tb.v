module phx_common_signext_tb;
parameter IN_WIDTH =8;
parameter OUT_WIDTH =32;
reg [IN_WIDTH-1:0]data_in;
wire [OUT_WIDTH-1:0]data_out;

phx_common_signext #(.IN_WIDTH(IN_WIDTH),
.OUT_WIDTH(OUT_WIDTH)) uut_8
(.data_in(data_in),
 .data_out(data_out));

//module instantiation for 5->32 parameterized.
reg [4:0] data_in_5;
wire [31:0] data_out_5;
phx_common_signext #(.IN_WIDTH(5),
.OUT_WIDTH(32)) uut_5
(.data_in(data_in_5),
.data_out(data_out_5));


//module instantiation for 16->32 parameterized.
reg [15:0] data_in_16;
wire [31:0] data_out_16;
phx_common_signext #(.IN_WIDTH(16),
.OUT_WIDTH(32)) uut_16
(.data_in(data_in_16),
.data_out(data_out_16));


reg [OUT_WIDTH-1:0] expected;
reg [OUT_WIDTH-1:0] expected_5;
reg [OUT_WIDTH-1:0] expected_16;


integer test;
integer test_5;
integer test_16;
integer passed_count;
integer failed_count;

integer passed_count_5;
integer failed_count_5;

integer passed_count_16;
integer failed_count_16;

task check_signext;

begin
    expected ={{(OUT_WIDTH-IN_WIDTH){data_in[IN_WIDTH-1]}},data_in};

    if(data_out !== expected )begin
        $display("FAILED : test=%0d data_in=%h data_out=%h expected=%h",
        test,
        data_in,
        data_out,
        expected);
        failed_count=failed_count+1;
        end

        else begin
            passed_count=passed_count+1;
        end

        test=test+1;
end
endtask


//task declaration for 5->32
task check_5_to_32;

begin

    expected_5 = {{27{data_in_5[4]}}, data_in_5};

    if (data_out_5 !== expected_5) begin

        $display("FAILED : test_5=%0d data_in=%h data_out=%h expected=%h",
            
            test_5,
            data_in_5,
            data_out_5,
            expected_5
        );

        failed_count_5 = failed_count_5 + 1;

    end
    else begin

        passed_count_5 = passed_count_5 + 1;

    end

    test_5 = test_5 + 1;

end

endtask

//teask declaration for 16->32 
task check_16_to_32;

begin

    expected_16 = {{16{data_in_16[15]}}, data_in_16};

    if (data_out_16 !== expected_16) begin

        $display("FAILED : test=%0d data_in=%h data_out=%h expected=%h",
            
            test_16,
            data_in_16,
            data_out_16,
            expected_16
        );

        failed_count_16 = failed_count_16 + 1;

    end
    else begin

        passed_count_16 = passed_count_16 + 1;

    end

    test_16 = test_16 + 1;

end

endtask

initial begin
    passed_count=0;
    failed_count=0;

    passed_count_5 = 0;
    failed_count_5 = 0;

    passed_count_16 = 0;
    failed_count_16 = 0;


    $dumpfile("sim/phx_common_signext_tb.vcd");
    $dumpvars(0,phx_common_signext_tb);

//positive values 
    data_in =8'b00000000;
    #1;
    check_signext;

    data_in =8'b00000001;
    #1;
    check_signext;

    data_in =8'b00000111;
    #1;
    check_signext;

    data_in =8'b01111111;
    #1;
    check_signext;

//negative values
    data_in =8'b10000000;
    #1;
    check_signext;

    data_in =8'b10000001;
    #1;
    check_signext;

    data_in =8'b11111011;
    #1;
    check_signext;

    data_in =8'b11111110;
    #1;
    check_signext;

    data_in =8'b11111111;
    #1;
    check_signext;

//pattern check

    data_in =8'b10101010;
    #1;
    check_signext;

    data_in =8'b01010101;
    #1;
    check_signext;
    

//test cases for other different parameterized dut.
//5->32 positive
data_in_5 = 5'b00000;
#1;
check_5_to_32;

data_in_5 = 5'b01111;
#1;
check_5_to_32;

data_in_5 = 5'b10000;
#1;
check_5_to_32;

data_in_5 = 5'b11111;
#1;
check_5_to_32;

//16->32
data_in_16 = 16'h0000;
#1;
check_16_to_32;

data_in_16 = 16'h7FFF;
#1;
check_16_to_32;

data_in_16 = 16'h8000;
#1;
check_16_to_32;

data_in_16 = 16'hFFFF;
#1;
check_16_to_32;

$display("========================================");
$display("PhoenixRV Sign Extension Verification");
$display("========================================");

$display("8 -> 32 Tests");
$display("Passed : %0d", passed_count);
$display("Failed : %0d", failed_count);

$display("========================================");

$display("5 -> 32 Tests");
$display("Passed : %0d", passed_count_5);
$display("Failed : %0d", failed_count_5);

$display("========================================");

$display("16 -> 32 Tests");
$display("Passed : %0d", passed_count_16);
$display("Failed : %0d", failed_count_16);

$display("========================================");


if ((failed_count == 0) &&
    (failed_count_5 == 0) &&
    (failed_count_16 == 0)) begin

    $display("ALL TESTS PASSED!");

end
else begin

    $display("SOME TESTS FAILED.");

end
   $finish;
end

endmodule







