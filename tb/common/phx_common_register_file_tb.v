`timescale 1ns/1ps

module phx_common_register_file_tb;

parameter DATA_WIDTH=32;
parameter REG_COUNT=32 ;

    reg clk;
    reg reset;

   reg [$clog2(REG_COUNT)-1:0] rs1;
   reg [$clog2(REG_COUNT)-1:0] rs2;

   reg [$clog2(REG_COUNT)-1:0] rd;
   reg [DATA_WIDTH-1:0] write_data;
   reg write_enable;

   wire [DATA_WIDTH-1:0] read_data1;
   wire [DATA_WIDTH-1:0] read_data2;

phx_common_register_file#(.DATA_WIDTH(DATA_WIDTH),
   .REG_COUNT(REG_COUNT))uut

   (
    .clk(clk),
    .reset(reset),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_data(write_data),
    .write_enable(write_enable),
    .read_data1(read_data1),
    .read_data2(read_data2)
   );

always #5 clk= ~clk;

reg [DATA_WIDTH-1:0] expected_registers[0:REG_COUNT-1];
 
integer i;

integer passed_count;
integer failed_count;
integer test;

//============defining read task ====================
task register_file_read_check;

reg [DATA_WIDTH-1:0] expected_read1;
reg [DATA_WIDTH-1:0] expected_read2;

begin

   
   //expected value for read port 1
   if(rs1==0)
   expected_read1='0;

   else if(write_enable && ( rd==rs1))
   expected_read1=write_data;

   else
   expected_read1=expected_registers[rs1];

   //expected value for  port 2
   if(rs2==0)
   expected_read2='0;

   else if(write_enable && (rd==rs2))
   expected_read2=write_data;

   else
   expected_read2=expected_registers[rs2];



if((expected_read1!==read_data1)||(expected_read2!==read_data2))
begin
   $display("FAILED  test=%d   expected_read1=%h  read_data1=%h   expected_read2=%h  read_data2=%h  ",
   test,
   expected_read1,
    read_data1,
    expected_read2,
     read_data2);

    
      failed_count=failed_count+1;
end
else
begin
      passed_count=passed_count+1;
end

test = test + 1;
end
endtask




// =========== defining write task ===================

task register_file_write_check;

   
   input [$clog2(REG_COUNT)-1:0]address;
   input [DATA_WIDTH-1:0]data;
begin
   
   rd = address;
   write_data = data;
   write_enable = 1'b1;

   @(posedge clk);
   #1;

   if(address != 0)
      expected_registers[address] = data;

      write_enable=1'b0;

end

endtask

initial begin

   clk    =1'b0;
   reset  =1'b0;

   rs1 ='0;
   rs2 ='0;

   rd ='0;
   write_data ='0;
   write_enable =1'b0;

   passed_count =0;
   failed_count =0;
   test =0;

   $dumpfile("sim/phx_common_register_file_tb.vcd");
   $dumpvars(0,phx_common_register_file_tb);

   // doing reset
   reset =1'b1;
   for(i=0; i<REG_COUNT;i=i+1)
   expected_registers[i] = '0;


   @(posedge clk);
   #1;

   reset = 1'b0;

   //check several registers after reset ,just reading tests
   //================test 1 ===================
   rs1 = 0;
   rs2 = 1;
   #1;
   register_file_read_check;
   
   //================test2 ================
   rs1 = 2;
   rs2 = 31;
   #1;
   register_file_read_check;

   //============basic write/read tests ==============
   // basic check
   register_file_write_check(5, 32'h12345678);
   rs1 =5;
   rs2 =0;
   #1;
   register_file_read_check;

   //dual read
   register_file_write_check(5, 32'hABCDEF01);
   rs1 =5;
   rs2 =10;
   #1;
   register_file_read_check;

   //same register
   rs1 =5;
   rs2 =5;
   #1;
   register_file_read_check;

   //x0 protection
   rs1 =0;
   rs2 =0;
   #1;
   register_file_read_check;

   register_file_write_check(0, 32'hFFFFFFFF);
   rs1 =0;
   rs2 =0;
   #1;
   register_file_read_check;

//==========write through both ports test============
   rd  =5;
   write_data =32'h99999999;
   write_enable =1'b1;


   rs1 =5;
   rs2 =10;
   #1;
   register_file_read_check;

   @(posedge clk);
   #1;
   write_enable = 1'b0;
   expected_registers[5] = 32'h99999999;


   rd =10;
   write_data = 32'h55555555;
   write_enable= 1'b1;

   rs1 =5;
   rs2 =10;
   #1;
   register_file_read_check;
   @(posedge clk);
   #1;
   write_enable = 1'b0;
   expected_registers[10] = 32'h55555555;

   rd =5;
   write_data=32'hAAAAAAAA;
   write_enable =1'b1;

   rs1=5;
   rs2=5;

   #1;
   register_file_read_check;

   @(posedge clk);
   #1;
   write_enable =1'b0;
   expected_registers[5] =32'hAAAAAAAA;
   #1;
   register_file_read_check;
  


// random test checking

for(i=0; i<500; i=i+1)begin
   rd = $random%REG_COUNT;
   rs1 = $random%REG_COUNT;
   rs2 = $random%REG_COUNT;
   write_data =$random;
   write_enable =$random&1'b1;

   #1;
   register_file_read_check;

   @(posedge clk);
   #1;

   if(write_enable && (rd != 0))
         expected_registers[rd]=write_data;

         write_enable =1'b0;

end

    $display("========================================");
    $display("PhoenixRV register file verification");
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

   

