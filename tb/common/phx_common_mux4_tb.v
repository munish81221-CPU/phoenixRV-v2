`timescale 1ns/1ps
module phx_common_mux4_tb;
    parameter WIDTH = 32;
    reg [WIDTH-1:0] in0;
    reg [WIDTH-1:0] in1;
    reg [WIDTH-1:0] in2;
    reg [WIDTH-1:0] in3;
    reg [1:0] sel;
    wire [WIDTH-1:0] out;

    phx_common_mux4 #(.WIDTH(WIDTH))uut(
        .in0(in0),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .sel(sel),
        .out(out)
    ) ;

    initial begin
        $dumpfile("sim/phx_common_mux4_tb.vcd");
        $dumpvars(0, phx_common_mux4_tb);
        //test case 1 here sel is 00 so out should be in0
        in0=32'h123456A7;
        in1=32'h12CAAA6D;
        in2=32'h12AB56A7;
        in3=32'h12ACAA67;
        sel=2'b00;
        #10;
        if(out !== in0)
        begin
            $display("Test case 1 failed: sel=00, out=%h, expected=%h", out, in0);
        end 
        else begin
            $display("Test case 1 passed: sel=00, out=%h, expected=%h", out, in0);
        end
        

        //test case 2 here sel is 01 so out should be in1
        in0=32'h12AB56A7;
        in1=32'h12ACAA67;
        in2=32'h12CAAA6D;
        in3=32'h12CACA67;
        sel=2'b01;
        #10;
        if(out !== in1) 
        begin
            $display("Test case 2 failed: sel=01, out=%h, expected=%h", out, in1);
        end 
        else begin
            $display("Test case 2 passed: sel=01, out=%h, expected=%h", out, in1);
        end

        //test case 3 here sel is 10 so out should be in2
        in0=32'hAAAAAAAA;
        in1=32'hBBBBBBBB;
        in2=32'hCCCCCCCC;
        in3=32'hDDDDDDDD;
        sel=2'b10;
        #10;
        if(out !== in2) 
        begin
            $display("Test case 3 failed: sel=10, out=%h, expected=%h", out, in2);
        end 
        else begin
            $display("Test case 3 passed: sel=10, out=%h, expected=%h", out, in2);
        end
        //test case 4 here sel is 11 so out should be in3
        in0=32'hAAAAAAAA;
        in1=32'hBBBBBBBB;
        in2=32'hCCCCCCCC;
        in3=32'hDDDDDDDD;
        sel=2'b11;
        #10;
        if(out !== in3) 
        begin
            $display("Test case 4 failed: sel=11, out=%h, expected=%h", out, in3);
        end 
        else begin
            $display("Test case 4 passed: sel=11, out=%h, expected=%h", out, in3);
        end
        $finish;

    end
endmodule