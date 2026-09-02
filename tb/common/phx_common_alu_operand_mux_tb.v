`timescale 1ns/1ps
module phx_common_alu_operand_mux_tb;
reg [31:0] register_operand;
reg [31:0] immediate;   
reg select_immediate;
wire [31:0] alu_operand_b;


phx_common_alu_operand_mux uut
(.register_operand(register_operand),
 .immediate(immediate),
 .select_immediate(select_immediate),
 .alu_operand_b(alu_operand_b));

 reg [31:0] expected;
 integer test;
 integer passed_count;  
integer failed_count;
integer i;

task check_alu_operand_mux;
begin
    if(expected!=alu_operand_b)
    begin
        $display("FAILED test=%0d select_immediate=%b register_operand=%h immediate=%h expected=%h alu_operand_b=%h",
        test,
        select_immediate,
        register_operand,
        immediate,
        expected,
        alu_operand_b);

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

    $dumpfile("sim/phx_common_alu_operand_mux_tb.vcd");
    $dumpvars(0, phx_common_alu_operand_mux_tb);

    passed_count =0;
    failed_count =0;
    test =0;

    register_operand = 32'h00000000;
    immediate        = 32'h00000000;
    select_immediate = 1'b0;
    expected         = 32'h00000000;

    //Test 1: select register_operand
    
    register_operand = 32'h00000005;
    immediate       = 32'h0000000A;
    select_immediate = 1'b0;
    expected = 32'h00000005;
    check_alu_operand_mux();

    //Test 2: select immediate
    register_operand = 32'h00000005;
    immediate       = 32'h0000000A;
    select_immediate = 1'b1;
    expected = 32'h0000000A;
    check_alu_operand_mux();

    //Test 3: select register_operand with negative value
    register_operand = 32'hFFFFFFFF;    
    immediate       = 32'h12345678;
    select_immediate = 1'b0;
    expected = 32'hFFFFFFFF;
    check_alu_operand_mux();


    //Test 4: select immediate with negative value
    register_operand = 32'hABCDEF01;
    immediate       = 32'h80000000;
    select_immediate = 1'b1;
    expected = 32'h80000000;
    check_alu_operand_mux();

    //randommized tests
    for( i = 0; i < 100; i = i + 1) begin
        register_operand = $random;
        immediate       = $random;
        select_immediate = $random;
        expected = select_immediate ? immediate : register_operand;
        #1;
        check_alu_operand_mux();
    end

    $display("Total Passed: %0d, Total Failed: %0d", passed_count, failed_count);
    $finish;

end
endmodule