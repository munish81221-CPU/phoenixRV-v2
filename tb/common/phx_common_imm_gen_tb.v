`timescale 1ns/1ps
module phx_common_imm_gen_tb;
reg [31:0] instruction;
reg [2:0] imm_type;
wire [31:0] immediate;

phx_common_imm_gen DUT
(.instruction(instruction),
 .imm_type(imm_type),
 .immediate(immediate));

 integer test;
 integer passed_count;
 integer failed_count;
 reg [31:0] expected;

 task check_immediate;
 begin
    
    if(expected!=immediate)
    begin
        $display("FAILED test=%0d type=%b instruction=%h expected=%h immediate=%h",
        test,
        imm_type,
        instruction,
        expected,
        immediate);

        failed_count = failed_count + 1;

    end
    else 
    begin
        passed_count = passed_count + 1;

    end
    test = test +1;
 end
 endtask

 initial begin

    $dumpfile("sim/phx_common_imm_gen_tb.vcd");
    $dumpvars(0, phx_common_imm_gen_tb);

    passed_count =0;
    failed_count =0;
    test =0;

    instruction =0;
    imm_type=0;
    expected =0;


    //Test I-1: positive
    instruction = 32'h00500000;
    imm_type    = 3'b000;
    expected    = 32'h00000005;
    #1;
    check_immediate;

    //Test I-2: negative
    instruction =32'hFFF00000;
    imm_type =3'b000;
    expected = 32'hFFFFFFFF;
    #1;
    check_immediate;

    //Test I-3: another negative value
    instruction =32'hFF000000;
    imm_type =3'b000;
    expected = 32'hFFFFFFF0;
    #1;
    check_immediate;

    //Test S-1: positive
    instruction =32'h00000280;
    imm_type =3'b001;
    expected = 32'h00000005;
    #1;
    check_immediate;

    //est S-2: negative
    instruction =32'hFE000FE0;
    imm_type =3'b001;
    expected = 32'hFFFFFFFF;
    #1;
    check_immediate;

    //Test B-1: zero offset
    instruction =32'h00000000;
    imm_type =3'b010;
    expected = 32'h00000000;
    #1;
    check_immediate;

    //Test B-2: positive offset
    instruction =32'h02000000;
    imm_type =3'b010;
    expected = 32'h00000020;
    #1;
    check_immediate;

    //Test B-3: negative offset
    instruction =32'hFE000E80;
    imm_type =3'b010;
    expected = 32'hFFFFFFFC;
    #1;
    check_immediate;

    //Test U-1
    instruction =32'h12345000;
    imm_type =3'b011;
    expected = 32'h12345000;
    #1;
    check_immediate;

    //Test U-2
    instruction =32'hABCDE123;
    imm_type =3'b011;
    expected = 32'hABCDE000;
    #1;
    check_immediate;

    //Test J-1: zero
    instruction =32'h00000000;
    imm_type =3'b100;
    expected = 32'h00000000;
    #1;
    check_immediate;

    //Test J-2: positive offset
    instruction =32'h10000000;
    imm_type =3'b100;
    expected = 32'h00000100;
    #1;
    check_immediate;

    //Test J-2: negative offset
    instruction =32'hFFDFF000;
    imm_type =3'b100;
    expected = 32'hFFFFFFFC;
    #1;
    check_immediate;

    //invalid format
    instruction = 32'hFFFFFFFF;
    imm_type    = 3'b111;
    expected    = 32'h00000000;
    #1;
    check_immediate;

     $display("========================================");
    $display("PhoenixRV immediate genarator Verification");
    $display("========================================");
    $display("Directed tests");
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