module phx_common_branch_select_tb;
reg [31:0]operand_a;
reg [31:0]operand_b;
reg [2:0] branch_select;
wire branch_taken;

phx_common_branch_select uut(
    .operand_a(operand_a),
    .operand_b(operand_b),
    .branch_select(branch_select),
    .branch_taken(branch_taken)
);

integer passed_count;
integer failed_count;
integer test;
integer i;
reg expected;

task check_branch_select;
begin
   
    if (expected !== branch_taken) begin
        $display( "FAILED test=%0d select=%b A=%h B=%h expected=%b branch_taken=%b",
            test,
            branch_select,
            operand_a,
            operand_b,
            expected,
            branch_taken
        );

        failed_count = failed_count + 1;
    end
    else begin
        passed_count = passed_count + 1;
    end

    test = test + 1;

end
endtask

initial begin
    expected = 1'b0;
    passed_count = 0;
    failed_count = 0;
    test = 0;

    $dumpfile("sim/phx_common_branch_select.vcd");
    $dumpvars(0,phx_common_branch_select_tb);

//BEQ
operand_a =32'h000000B ;
operand_b =32'h000000B ;
branch_select =3'b000 ;
expected =1'b1 ;
#1;
check_branch_select;

operand_a =32'h0000000B ;
operand_b =32'h0000000C ;
branch_select =3'b000 ;
expected =1'b0 ;
#1;
check_branch_select;

//BNE
operand_a =32'h0000012B ;
operand_b =32'h0000000B ;
branch_select =3'b001 ;
expected =1'b1 ;
#1;
check_branch_select;

operand_a =32'h00000548 ;
operand_b =32'h00000548 ;
branch_select =3'b001 ;
expected =1'b0 ;
#1;
check_branch_select;

//BLT
operand_a =32'hFFFFFFFF ;
operand_b =32'h00000001 ;
branch_select =3'b010 ;
expected =1'b1 ;
#1;
check_branch_select;

operand_a =32'h00000005 ;
operand_b =32'hFFFFFFFE ;
branch_select =3'b010 ;
expected =1'b0 ;
#1;
check_branch_select;

//BGE
operand_a =32'hFFFFFFFE ;
operand_b =32'h00000005 ;
branch_select =3'b011 ;
expected =1'b1 ;
#1;
check_branch_select;

operand_a =32'hFFFFFFFF ;
operand_b =32'h00000001 ;
branch_select =3'b011 ;
expected =1'b1 ;
#1;
check_branch_select;

operand_a =32'h0000000B ;
operand_b =32'h0000000B ;
branch_select =3'b011 ;
expected =1'b1 ;
#1;
check_branch_select;

//BLTU
operand_a = 32'h00000005;
operand_b = 32'h0000000A;
branch_select = 3'b100;
expected = 1'b1;
#1;
check_branch_select;

operand_a = 32'hFFFFFFFF;
operand_b = 32'h00000001;
branch_select = 3'b100;
expected = 1'b0;
#1;
check_branch_select;

operand_a = 32'h0000000A;
operand_b = 32'h0000000A;
branch_select = 3'b100;
expected = 1'b0;
#1;
check_branch_select;

//BGEU
operand_a = 32'h0000000A;
operand_b = 32'h00000005;
branch_select = 3'b101;
expected = 1'b1;
#1;
check_branch_select;

operand_a = 32'hFFFFFFFF;
operand_b = 32'h00000001;
branch_select = 3'b101;
expected = 1'b1;
#1;
check_branch_select;

operand_a = 32'h0000000A;
operand_b = 32'h0000000A;
branch_select = 3'b101;
expected = 1'b1;
#1;
check_branch_select;

//reserved check
operand_a = 32'h0000000A;
operand_b = 32'h000000BC;
branch_select = 3'b110;
expected = 1'b0;
#1;
check_branch_select;

operand_a = 32'h0000012A;
operand_b = 32'h0000000A;
branch_select = 3'b111;
expected = 1'b0;
#1;
check_branch_select;

//random testing 
for(i=0; i<100; i=i+1)begin
    
    operand_a = $random;
    operand_b = $random;
    branch_select = $random % 8;
case(branch_select)

    //BEQ
    3'b000:
    expected = (operand_a == operand_b);

    //BNE
    3'b001:
    expected = (operand_a != operand_b);

    //BLT - signed comparison
    3'b010:
    expected = ($signed(operand_a) < $signed(operand_b));

    //BGE - signed comparison 
    3'b011:
    expected = ($signed(operand_a)<= $signed(operand_b));

    //BLTU
    3'b100:
    expected = (operand_a < operand_b);

    //BGEU
    3'b101:
    expected = (operand_a >= operand_b);

    default:
    expected = 1'b0;
    endcase
    
    
    #1;
    check_branch_select;
end

$display("========================================");
    $display("PhoenixRV branch select");
    $display("========================================");
    $display("Directed + Random Tests");
    $display("Passed : %0d", passed_count);
    $display("Failed : %0d", failed_count);
    $display("========================================");

    if (failed_count == 0) begin
        $display("ALL TESTS PASSED!");
    end
    else begin
        $display("SOME TESTS FAILED");
    end

    $finish;

end
endmodule