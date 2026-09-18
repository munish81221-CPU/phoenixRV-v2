`timescale 1ns/1ps
module phx_control_pc_select_tb;
logic branch;
logic branch_taken;
logic jump;
logic jump_reg;
logic [1:0] pc_select;
logic [1:0] expected;

phx_control_pc_select dut (
    .branch(branch),
    .branch_taken(branch_taken),
    .jump(jump),
    .jump_reg(jump_reg),
    .pc_select(pc_select)
);

integer passed_count;
integer failed_count;



//defining function for checking expected and original value

function automatic logic[1:0]  expected_pc_select(
    input logic branch,
    input logic branch_taken,
    input logic jump,
    input logic jump_reg
);
//body of function
begin
//default value 
expected_pc_select=2'b00;

//highest priority:JALR
if(jump && jump_reg)
    expected_pc_select=2'b11;

//JAL
else if(jump)
    expected_pc_select=2'b10;

//taken conditional branch
else if(branch && branch_taken)
    expected_pc_select=2'b01;

//otherwise normal pc+4
else 
    expected_pc_select=2'b00;
end


endfunction

integer i;

initial begin
    $dumpfile("sim/phx_control_pc_select_tb.vcd");
    $dumpvars(0,phx_control_pc_select_tb);

    passed_count =0;
    failed_count =0;

 
 for(i=0;i<16;i=i+1)begin

//generate all possible input combination
 branch =i[3];
 branch_taken =i[2];
 jump =i[1];
 jump_reg =i[0];

 //calculate expected result
 expected = expected_pc_select(branch,branch_taken,jump,jump_reg);

 #1;

 //self checking assertion
 assert (pc_select === expected)

 begin
    passed_count = passed_count + 1;
 end 

 else begin
    failed_count = failed_count + 1;
    $error("failed :  branch=%b  branch_taken=%b jump=%b jump_reg=%b  pc_select=%b expected=%b",
    branch,
    branch_taken,
    jump,
    jump_reg,
    pc_select,
    expected
    );

 end
 end

if(failed_count==0)
    $display("STATUS   : PASS");

else
    $display("STATUS   : FAILED");

    $finish;
end
endmodule

