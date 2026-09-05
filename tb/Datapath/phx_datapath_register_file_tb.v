`timescale 1ns/1ps
module phx_datapath_register_file_tb;


    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 5;

    reg clk;
    reg reset;
    reg write_enable;

    reg [ADDR_WIDTH-1:0] write_address;
    reg [DATA_WIDTH-1:0] write_data;

    reg [ADDR_WIDTH-1:0] read_address1;
    reg [ADDR_WIDTH-1:0] read_address2;

    wire [DATA_WIDTH-1:0] read_data1;
    wire [DATA_WIDTH-1:0] read_data2;

    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_address(write_address),
        .write_data(write_data),
        .read_address1(read_address1),
        .read_address2(read_address2),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

integer i;
integer j;
integer passed_count;
integer failed_count;


always #5 clk = ~clk;

reg [DATA_WIDTH-1:0]expected_registers[0:(2**ADDR_WIDTH)-1];    

task check_register_file;
begin
    //checking internal register state
    for(j=0;j<2**ADDR_WIDTH;j=j+1) begin
        if(uut.registers[j] !== expected_registers[j]) begin
            $display("FAILED: Register[%0d] = %h    Expected = %h", j, uut.registers[j], expected_registers[j]);
            failed_count = failed_count + 1;
        end
        else begin
            passed_count = passed_count + 1;
        end
    end


    // checking read port against expected value 
    if (read_data1 !== expected_registers[read_address1]) begin
    $display("FAILED: Read Port 1 | Address = %0d | Got = %h | Expected = %h",
             read_address1, read_data1, expected_registers[read_address1]);
    failed_count = failed_count + 1;
    end
    else begin
    passed_count = passed_count + 1;
    end

    if (read_data2 !== expected_registers[read_address2]) begin
    $display("FAILED: Read Port 2 | Address = %0d | Got = %h | Expected = %h",
             read_address2, read_data2, expected_registers[read_address2]);
    failed_count = failed_count + 1;
    end
    else begin
    passed_count = passed_count + 1;
    end

    
end
endtask

initial begin
    $display("=== REG-001 TEST STARTED ===");
    clk = 0;
    reset = 1;
    write_enable = 0;
    write_address = 0;
    write_data = 0;
    read_address1 = 0;
    read_address2 = 0;

    passed_count = 0;
    failed_count = 0;
    

     $dumpfile("sim/phx_datapath_register_file_tb.vcd");
    $dumpvars(0, phx_datapath_register_file_tb);


    // Initialize expected_registers to zero
    for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
        expected_registers[i] = {DATA_WIDTH{1'b0}};
    end
     #10 
     reset = 0;

    check_register_file; // Check after reset

//direct tests
//basic read and write tests
write_enable = 1;
write_address = 5'd5;
write_data = 32'h12345678;

@(posedge clk);
#1;

expected_registers[5] = 32'h12345678;

write_enable = 0;

read_address1 = 5'd5;
read_address2 = 5'd5;

#1;
check_register_file;

//two different read ports simultaneously
write_enable = 1;
write_address = 5'd5;
write_data = 32'h12345678;
@(posedge clk);
#1;
expected_registers[5] = 32'h12345678;

write_enable = 1;
write_address = 5'd10;
write_data = 32'hABCD1234;
@(posedge clk);
#1;
expected_registers[10] = 32'hABCD1234;

write_enable = 0;

read_address1 = 5'd5;
read_address2 = 5'd10;

#1;
check_register_file;

//asynchronous read test
write_enable = 1;
write_address = 5'd7;
write_data = 32'h123ABC78;
#1;
 // x7 should still be 0 because write hasn't occurred yet


write_enable = 1;
write_address = 5'd8;
write_data = 32'hABCD1134;
#1;
 // x8 should still be 0 because write hasn't occurred yet


write_enable = 0;

read_address1 = 5'd7;
read_address2 = 5'd8;
#1;
check_register_file;

read_address1 = 5'd5;
read_address2 = 5'd10;

#1;
check_register_file;

read_address1 = 5'd10;
read_address2 = 5'd5;

#1;
check_register_file;

//write enable off test
write_enable = 1;
write_address = 5'd15;
write_data = 32'hDEADBEEF;
@(posedge clk);
#1;
write_enable = 0;
write_address = 5'd15;
write_data = 32'hCAFEBABE;
@(posedge clk);
#1;
expected_registers[15] = 32'hDEADBEEF; // x15 should still be DEADBEEF because write_enable was off 
read_address1 = 5'd15;
#1;
check_register_file;

//X0 register test
write_enable = 1;
write_address = 5'd0;
write_data = 32'hFFFFFFFF;

@(posedge clk);
#1;
read_address1 = 5'd0;
read_address2 = 5'd0;
#1;
check_register_file; // x0 should still be 0 because writes to x0 are ignored   


//write happens only on clock edge
write_enable = 1;
write_address = 5'd12;
write_data = 32'h11112222;
#2;
 
check_register_file;
@(posedge clk);
#1;
expected_registers[12] = 32'h11112222; // x12 should now be 11112222 because write has occurred
check_register_file;


//random tests
$display("=== DIRECTED TESTS COMPLETED ===");
for(i=0;i<500;i=i+1) begin
    if (i % 100 == 0)
    $display("Random test iteration = %0d", i);
    write_enable = $urandom_range(0, 1);
    write_address = $urandom_range(0, (2**ADDR_WIDTH) - 1);
    read_address1 = $urandom_range(0, (2**ADDR_WIDTH) - 1);
    read_address2 = $urandom_range(0, (2**ADDR_WIDTH) - 1);
     write_data = $urandom;
    @(posedge clk);
    #1;
    if(write_enable && write_address != 0) begin
        expected_registers[write_address] = write_data;
    end

    check_register_file;

    

end

   $display("=== ALL TESTS COMPLETED ===");
   $display("Test completed. Passed: %0d, Failed: %0d",
         passed_count, failed_count);
    $finish;
end

endmodule

