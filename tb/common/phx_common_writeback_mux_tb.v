`timescale 1ns / 1ps  
module phx_common_writeback_mux_tb;
    reg[31:0] alu_result;
    reg[31:0] memory_data;
    reg[31:0] pc_plus_4;
    reg[31:0] immediate;

    reg[1:0] writeback_select;

    wire [31:0] writeback_data;

phx_common_writeback_mux uut (
    .alu_result(alu_result),
    .memory_data(memory_data),
    .pc_plus_4(pc_plus_4),
    .immediate(immediate),
    .writeback_select(writeback_select),
    .writeback_data(writeback_data)
);

reg [31:0] expected;
integer test;   
integer passed_count;
integer failed_count;
integer i;


task check_writeback_mux;
begin
    if(writeback_data !== expected) begin
        $display("FAILED: test =%0d alu_result=%h memory_data=%h pc_plus_4=%h immediate=%h Writeback_select=%b  Writeback_data=%h  Expected Writeback_data=%h",
                 test,
                 alu_result,
                 memory_data,
                 pc_plus_4,
                 immediate,
                 writeback_select,
                 writeback_data,
                 expected);
        failed_count = failed_count + 1;
    end
    else begin
        passed_count = passed_count + 1;
    end
    test=test+1;

end
endtask

initial begin
    $dumpfile("sim/phx_common_writeback_mux_tb.vcd"); 
    $dumpvars(0, phx_common_writeback_mux_tb);    
    

    test=0;
    passed_count=0;
    failed_count=0;

    alu_result=32'b0;
    memory_data=32'b0;  
    pc_plus_4=32'b0;
    immediate=32'b0;
    writeback_select=2'b00;
    expected=32'b0;

    //direct test cases
    alu_result=32'h00000011;
    memory_data=32'h22222222;   
    pc_plus_4=32'h33333333;
    immediate=32'h44444444;
    writeback_select=2'b00;
    expected = 32'h00000011;
    #1;
    check_writeback_mux();


     alu_result=32'h11111111;
    memory_data=32'hABCDEF01;   
    pc_plus_4=32'h33333333;
    immediate=32'h44444444;
    writeback_select=2'b01;
    expected = 32'hABCDEF01;
    #1;
    check_writeback_mux();


     alu_result=32'h11111111;
    memory_data=32'h22222222;   
    pc_plus_4=32'h00000004;
    immediate=32'h44444444;
    writeback_select=2'b10;
    expected = 32'h00000004;
    #1;
    check_writeback_mux();


     alu_result=32'h11111111;
    memory_data=32'h22222222;   
    pc_plus_4=32'h33333333;
    immediate=32'h80000000;
    writeback_select=2'b11;
    expected = 32'h80000000;
    #1;
    check_writeback_mux();



    for(i=0;i<50;i=i+1) begin
        writeback_select=i[1:0];
        alu_result=$random;
        memory_data=$random;
        pc_plus_4=$random;
        immediate=$random;

        case(writeback_select)
            2'b00: expected = alu_result;
            2'b01: expected = memory_data;
            2'b10: expected = pc_plus_4;
            2'b11: expected = immediate;
            default: expected = 32'b0;
        endcase

        #10; 
        check_writeback_mux();
    end

    $display("Test completed. Passed: %d, Failed: %d", passed_count, failed_count);
    $finish;
end
endmodule