`timescale 1ns/1ps
module phx_common_mux2_tb;
    parameter WIDTH = 32;
    reg [WIDTH-1:0] in0;
    reg [WIDTH-1:0] in1;
    reg sel;
    wire [WIDTH-1:0] out;

    phx_common_mux2 #(.WIDTH(WIDTH))uut(
        .in0(in0),
        .in1(in1),
        .sel(sel),
        .out(out)
    ) ;

    initial begin
        $dumpfile("sim/phx_common_mux2_tb.vcd");
        $dumpvars(0, phx_common_mux2_tb);
        //test case 1 here sel is 0 so out should be in0
        in0=32'h123456A7;
        in1=32'h12CAAA6D;
        sel=0;
        #10;
        if(out !== in0)
        begin
            $display("Test case 1 failed: sel=0, out=%h, expected=%h", out, in0);
        end 
        else begin
            $display("Test case 1 passed: sel=0, out=%h, expected=%h", out, in0);
        end
        

        //test case 2 here sel is 1 so out should be in1
        in0=32'h12AB56A7;
        in1=32'h12ACAA67;
        sel=1;

        #10;
        if(out !== in1) 
        begin
            $display("Test case 2 failed: sel=1, out=%h, expected=%h", out, in1);
        end 
        else begin
            $display("Test case 2 passed: sel=1, out=%h, expected=%h", out, in1);
        end

        //test case 3 here sel is 0 so out should be in0
        in0=32'hAAAAAAAA;
        in1=32'h12CAAA6D;
        sel=0;
        #10;
        if(out !== in0) 
        begin
            $display("Test case 3 failed: sel=0, out=%h, expected=%h", out, in0);
        end 
        else begin
            $display("Test case 3 passed: sel=0, out=%h, expected=%h", out, in0);
        end
        $finish;

    end
endmodule