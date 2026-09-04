module phx_common_ALU_tb;
    parameter WIDTH = 32;
    reg [WIDTH-1:0] operand_a;
    reg [WIDTH-1:0] operand_b;
    reg [3:0] alu_control;
    wire [WIDTH-1:0] alu_result;

    phx_common_ALU #(.WIDTH(WIDTH)) uut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_control(alu_control),
        .alu_result(alu_result)
    );

    reg [WIDTH-1:0] expected_result;
    integer test;   
    integer passed_count;
    integer failed_count;
    integer i;

    task check_alu;
    begin   
        if(alu_result !== expected_result) begin
            $display("FAILED: test = %0d operand_a=%h operand_b=%h alu_control=%b  Result=%h  Expected_Result=%h",
                     test,
                     operand_a,
                     operand_b,
                     alu_control,
                     alu_result,
                     expected_result);
            failed_count = failed_count + 1;
        end else begin
            passed_count = passed_count + 1;
        end
        test=test+1;
    end
    endtask

    initial begin
        test = 0;
        passed_count = 0;
        failed_count = 0;
        $dumpfile("sim/phx_common_ALU_tb.vcd");
        $dumpvars(0, phx_common_ALU_tb);


        // Test ADD operation
        operand_a = 32'h00000A05;
        operand_b = 32'h01200003;
        alu_control = 4'b0000; // ADD
        expected_result = operand_a + operand_b;
        #10;
        check_alu();

        // Test SUB operation
        operand_a = 32'h00030005;
        operand_b = 32'h00000403;
        alu_control = 4'b0001; // SUB
        expected_result = operand_a - operand_b;
        #10;
        check_alu();

        // Test AND operation
        operand_a = 32'h0FEC0005;
        operand_b = 32'h00003233;
        alu_control = 4'b0010; // AND
        expected_result = operand_a & operand_b;
        #10;
        check_alu();

        // Test OR operation
        operand_a = 32'h000B0005;
        operand_b = 32'h00123403;
        alu_control = 4'b0011; // OR
        expected_result = operand_a | operand_b;
        #10;
        check_alu();

        // Test XOR operation
        operand_a = 32'h02004005;
        operand_b = 32'h05005603;
        alu_control = 4'b0100; // XOR
        expected_result = operand_a ^ operand_b;
        #10;
        check_alu();

        // Test SLL operation
        operand_a = 32'h00007801;
        operand_b = 32'h000ABC02;
        alu_control = 4'b0101; // SLL
        expected_result = operand_a << operand_b[4:0];
        #10;
        check_alu();

        // Test SRL operation
        operand_a = 32'h0000BC04;
        operand_b = 32'h12345678;
        alu_control = 4'b0110; // SRL
        expected_result = operand_a >> operand_b[4:0];
        #10;
        check_alu();

        // Test SRA operation
        operand_a = 32'hFFFFFFFC; // -4 in signed
        operand_b = 32'h00000001;
        alu_control = 4'b0111; // SRA
        expected_result = $signed(operand_a) >>> operand_b[4:0];
        #10;
        check_alu();

        // Test SLT operation
        operand_a = 32'hFFFFFFFF; // -1 signed
        operand_b = 32'h00000001; // +1
        alu_control = 4'b1000;
        expected_result = ($signed(operand_a) < $signed(operand_b)) ? {{(WIDTH-1){1'b0}},1'b1} : {WIDTH{1'b0}};
        #10;
        check_alu();

        // Test SLTU operation
        operand_a = 32'hFFFFFFFF;
        operand_b = 32'h00000001;
        alu_control = 4'b1001;
        expected_result = (operand_a < operand_b) ? {{(WIDTH-1){1'b0}},1'b1} : {WIDTH{1'b0}};
        #10;
        check_alu();

        //random tests 
        for(i=0; i<1000; i=i+1) begin
            operand_a = $random;
            operand_b = $random;
            alu_control = $urandom_range(0, 9); // Randomly select an operation
            case(alu_control)
                4'b0000: expected_result = operand_a + operand_b; // ADD
                4'b0001: expected_result = operand_a - operand_b; // SUB
                4'b0010: expected_result = operand_a & operand_b; // AND
                4'b0011: expected_result = operand_a | operand_b; // OR
                4'b0100: expected_result = operand_a ^ operand_b; // XOR
                4'b0101: expected_result = operand_a << operand_b[4:0]; // SLL
                4'b0110: expected_result = operand_a >> operand_b[4:0]; // SRL
                4'b0111: expected_result = $signed(operand_a) >>> operand_b[4:0]; // SRA
                4'b1000: expected_result = ($signed(operand_a) < $signed(operand_b)) ? {{(WIDTH-1){1'b0}},1'b1} : {WIDTH{1'b0}}; // SLT
                4'b1001: expected_result = (operand_a < operand_b) ? {{(WIDTH-1){1'b0}},1'b1} : {WIDTH{1'b0}}; // SLTU
                default: expected_result = {WIDTH{1'b0}};
            endcase
            #10;
            check_alu();
        end

        $display("Total tests: %0d, Passed: %0d, Failed: %0d", test, passed_count, failed_count);
        $finish;
    end
endmodule