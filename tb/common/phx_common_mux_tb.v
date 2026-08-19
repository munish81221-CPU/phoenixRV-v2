`timescale 1ns/1ps
module phx_common_mux_tb;
parameter WIDTH=32;
parameter INPUTS=4;
reg [WIDTH-1:0] input_data[INPUTS-1:0];
reg [$clog2(INPUTS)-1:0]sel;
wire [WIDTH-1:0] mux_out;

phx_common_mux #(.WIDTH(WIDTH),
.INPUTS(INPUTS)) uut
(.input_data(input_data),
.sel(sel),
.mux_out(mux_out));

  integer passed_count;
  integer failed_count;
  integer test;
  integer random_test;

  reg [WIDTH-1:0]expected;

  task check_mux;
    begin
        case(sel)
        2'b00:expected=input_data[0];
        2'b01:expected=input_data[1];
        2'b10:expected=input_data[2];
        2'b11:expected=input_data[3];
        endcase
        if(expected!==mux_out)
        begin
            $display("FAILED test=%0d expected=%h   mux_out=%h   sel=%b   ",test,expected,mux_out,sel );
            failed_count=failed_count+1;
        end
        else  
        begin
            passed_count=passed_count+1;
        end
        test=test+1;
    end
  endtask

  initial begin
    
    passed_count=0;
    failed_count=0;
    test=0;

    $dumpfile("sim/phx_common_nux_tb.vcd");
    $dumpvars(0,phx_common_mux_tb);
//direct test 
    input_data[0] = 32'h11111111;
    input_data[1] = 32'h22222222;
    input_data[2] = 32'h33333333;
    input_data[3] = 32'h44444444;

    sel =2'b00;
    #1;
    check_mux;

    sel =2'b01;
    #1;
    check_mux;

     sel =2'b10;
    #1;
    check_mux;

     sel =2'b11;
    #1;
    check_mux;

    input_data[0] = 32'h00000000;
    input_data[1] = 32'hFFFFFFFF;
    input_data[2] = 32'h80000000;
    input_data[3] = 32'h7FFFFFFF;

    sel =2'b00;
    #1;
    check_mux;

    sel =2'b01;
    #1;
    check_mux;

     sel =2'b10;
    #1;
    check_mux;

     sel =2'b11;
    #1;
    check_mux;

// random tests
for(random_test=0; random_test<200 ; random_test=random_test+1)
begin
    input_data[0] = $random;
    input_data[1] = $random;
    input_data[2] = $random;
    input_data[3] = $random;

    sel=$random & 2'b11;
    #1;
    check_mux;
end
    $display("========================================");
    $display("PhoenixRV common parametarized mux");
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