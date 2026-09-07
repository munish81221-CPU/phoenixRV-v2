`timescale 1ns/1ps
module phx_datapath_operand_a_mux_tb;
    parameter WIDTH = 32;
    reg [WIDTH-1:0] read_data1;
    reg [WIDTH-1:0] pc;
    reg alu_src_a;
    wire [WIDTH-1:0] operand_a;

    phx_datapath_operand_a_mux #(.WIDTH(WIDTH))uut(
        .read_data1(read_data1),
        .pc(pc),
        .alu_src_a(alu_src_a),
        .operand_a(operand_a)
    ) ;

integer i;
integer passed_count;
integer failed_count;
reg [WIDTH-1:0] expected;


task mux_check;
begin

    if(expected !== operand_a)begin
    $display("failed test expected = %d  operand_a = %d ", expected , operand_a);
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
        #1;
        $dumpfile("sim/phx_datapath_operand_a_mux_tb.vcd");
        $dumpvars(0, phx_datapath_operand_a_mux_tb);
        //direct test 

        read_data1 = 32'h123ABC78;
        pc = 32'h123456A7;
        alu_src_a = 1;
        expected = pc;
        #1;
         mux_check;

        read_data1 = 32'h00000000;
        pc         = 32'h00000004;
        alu_src_a = 1;
         expected = pc;
         #1;
         mux_check;

        read_data1 =32'hFFFFFFFF;
        pc         =32'h00000000;
        alu_src_a = 0;
         expected = read_data1;
         #1;
         mux_check;

        read_data1 = 32'hAAAAAAAA;
        pc         = 32'h55555555;
        alu_src_a = 1;
         expected = pc;
         #1;
         mux_check;

        read_data1 =32'h12345678;
        pc         = 32'hABCDEF00;
        alu_src_a = 0;
         expected = read_data1;
         #1;
         mux_check;

        read_data1 =32'h80000000;
        pc         =32'h7FFFFFFC;
        alu_src_a = 1;
        expected = pc;
        #1;
         mux_check;

         //random tests
        for(i=0; i<=100; i=i+1)begin
        read_data1 = $random;
        pc = $random;
        alu_src_a = $urandom_range(0,1);
        if (alu_src_a)
         expected = pc;
        else
         expected = read_data1;
         #1;
        mux_check;

        end
        $display("passed_count = %d   failed_count = %d", passed_count, failed_count);
        $finish;


    end
endmodule


