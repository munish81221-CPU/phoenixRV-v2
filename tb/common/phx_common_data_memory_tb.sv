`timescale 1ns/1ps

module phx_common_data_memory_tb;

    // PARAMETERS

    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 32;
    localparam int DEPTH      = 256;


    // DUT INTERFACE

    logic                   clk;
    logic                   reset;

    logic                   mem_read;
    logic                   mem_write;

    logic [ADDR_WIDTH-1:0]  address;
    logic [DATA_WIDTH-1:0]  write_data;

    logic [DATA_WIDTH-1:0]  read_data;


    // DUT

    phx_common_data_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) DUT (

        .clk       (clk),
        .reset     (reset),

        .mem_read  (mem_read),
        .mem_write (mem_write),

        .address   (address),
        .write_data(write_data),

        .read_data (read_data)

    );


    // TRANSACTION

    typedef struct packed {

        logic [ADDR_WIDTH-1:0] address;
        logic [DATA_WIDTH-1:0] write_data;

        logic mem_read;
        logic mem_write;

    } memory_transaction_t;


    memory_transaction_t stimulus;


    // REFERENCE MEMORY

    logic [DATA_WIDTH-1:0] reference_memory [0:DEPTH-1];


    // TEST COUNTERS

    integer passed_count;
    integer failed_count;


    // CLOCK

    always #5 clk = ~clk;


    // REFERENCE MEMORY INDEX

    function automatic integer reference_index(
        input logic [ADDR_WIDTH-1:0] addr
    );

        reference_index = addr[9:2];

    endfunction


    // RUN TEST

    task automatic run_test(
        input memory_transaction_t tx,
        input string test_name
    );

        integer index;
        logic [DATA_WIDTH-1:0] expected_data;

        
        // Calculate reference index
        

        index = reference_index(tx.address);

        
        // Drive DUT
        

        address    = tx.address;
        write_data = tx.write_data;
        mem_read   = tx.mem_read;
        mem_write  = tx.mem_write;


        
        // WRITE OPERATION
        

        if (tx.mem_write) begin

            
            @(posedge clk);

            reference_memory[index] = tx.write_data;

        end


        
        // Allow combinational read path to settle
        

        #1;


        
        // READ CHECK
        

        if (tx.mem_read) begin

            expected_data = reference_memory[index];

            if (read_data === expected_data) begin

                passed_count++;

                $display(
                    "PASS [%s] address=%h data=%h",
                    test_name,
                    tx.address,
                    read_data
                );

            end
            else begin

                failed_count++;

                $error(
                    "FAIL [%s] address=%h\n actual=%h expected=%h",
                    test_name,
                    tx.address,
                    read_data,
                    expected_data
                );

            end

        end
        else begin

            if (read_data === '0) begin

                passed_count++;

                $display(
                    "PASS [%s] address=%h WRITE=%b READ=%b",
                    test_name,
                    tx.address,
                    tx.mem_write,
                    tx.mem_read
                );

            end
            else begin

                failed_count++;

                $error(
                    "FAIL [%s] read disabled but read_data=%h",
                    test_name,
                    read_data
                );

            end

        end


        
        // Disable controls after transaction
        

        mem_read  = 1'b0;
        mem_write = 1'b0;

        #1;

    endtask


    // APPLY TEST

    task automatic apply_test(
        input logic [ADDR_WIDTH-1:0] address_in,
        input logic [DATA_WIDTH-1:0] data_in,
        input logic                  read_in,
        input logic                  write_in,
        input string                 test_name
    );

        stimulus.address    = address_in;
        stimulus.write_data = data_in;
        stimulus.mem_read   = read_in;
        stimulus.mem_write  = write_in;

        run_test(stimulus, test_name);

    endtask


    // TEST: BASIC WRITE / READ

    task automatic test_basic_write_read();

        apply_test(
            32'h00000000,
            32'h12345678,
            1'b0,
            1'b1,
            "BASIC_WRITE"
        );

        apply_test(
            32'h00000000,
            32'h00000000,
            1'b1,
            1'b0,
            "BASIC_READ"
        );

    endtask


    // TEST: MULTIPLE ADDRESSES

    task automatic test_multiple_addresses();

        apply_test(
            32'h00000004,
            32'h11111111,
            1'b0,
            1'b1,
            "MULTI_WRITE_1"
        );

        apply_test(
            32'h00000008,
            32'h22222222,
            1'b0,
            1'b1,
            "MULTI_WRITE_2"
        );

        apply_test(
            32'h0000000C,
            32'h33333333,
            1'b0,
            1'b1,
            "MULTI_WRITE_3"
        );


        apply_test(
            32'h00000004,
            32'h00000000,
            1'b1,
            1'b0,
            "MULTI_READ_1"
        );

        apply_test(
            32'h00000008,
            32'h00000000,
            1'b1,
            1'b0,
            "MULTI_READ_2"
        );

        apply_test(
            32'h0000000C,
            32'h00000000,
            1'b1,
            1'b0,
            "MULTI_READ_3"
        );

    endtask


    // TEST: OVERWRITE

    task automatic test_overwrite();

        apply_test(
            32'h00000020,
            32'hAAAAAAAA,
            1'b0,
            1'b1,
            "OVERWRITE_FIRST"
        );

        apply_test(
            32'h00000020,
            32'hBBBBBBBB,
            1'b0,
            1'b1,
            "OVERWRITE_SECOND"
        );

        apply_test(
            32'h00000020,
            32'h00000000,
            1'b1,
            1'b0,
            "OVERWRITE_READ"
        );

    endtask


    // TEST: SPECIAL DATA VALUES

    task automatic test_special_values();

        // Zero
        apply_test(
            32'h00000040,
            32'h00000000,
            1'b0,
            1'b1,
            "ZERO_WRITE"
        );

        apply_test(
            32'h00000040,
            32'h00000000,
            1'b1,
            1'b0,
            "ZERO_READ"
        );


        // All ones
        apply_test(
            32'h00000044,
            32'hFFFFFFFF,
            1'b0,
            1'b1,
            "ONES_WRITE"
        );

        apply_test(
            32'h00000044,
            32'h00000000,
            1'b1,
            1'b0,
            "ONES_READ"
        );

    endtask


    // TEST: MEMORY BOUNDARIES

    task automatic test_boundaries();

        // First word
        apply_test(
            32'h00000000,
            32'hCAFEBABE,
            1'b0,
            1'b1,
            "LOWER_BOUNDARY_WRITE"
        );

        apply_test(
            32'h00000000,
            32'h00000000,
            1'b1,
            1'b0,
            "LOWER_BOUNDARY_READ"
        );


        // Last word = 255
        // 255 * 4 = 1020 = 0x3FC

        apply_test(
            32'h000003FC,
            32'hDEADBEEF,
            1'b0,
            1'b1,
            "UPPER_BOUNDARY_WRITE"
        );

        apply_test(
            32'h000003FC,
            32'h00000000,
            1'b1,
            1'b0,
            "UPPER_BOUNDARY_READ"
        );

    endtask


    // TEST: CONTROL SIGNALS

    task automatic test_control_signals();

       
        apply_test(
            32'h00000010,
            32'hAAAAAAAA,
            1'b0,
            1'b0,
            "NO_OPERATION"
        );


       

        apply_test(
            32'h00000010,
            32'h55555555,
            1'b0,
            1'b1,
            "WRITE_ONLY"
        );


        

        apply_test(
            32'h00000010,
            32'h00000000,
            1'b1,
            1'b0,
            "READ_ONLY"
        );

    endtask


    // INITIALIZATION

    initial begin

        clk = 1'b0;

        reset = 1'b1;

        mem_read  = 1'b0;
        mem_write = 1'b0;

        address    = '0;
        write_data = '0;

        passed_count = 0;
        failed_count = 0;

        #10;

        reset = 1'b0;


        
        // Directed tests
        

        test_basic_write_read();

        test_multiple_addresses();

        test_overwrite();

        test_special_values();

        test_boundaries();

        test_control_signals();


        
        // Final report
        

       

        $display(" PASSED : %0d", passed_count);
        $display(" FAILED : %0d", failed_count);

        if (failed_count == 0)
            $display(" all test passed  ");
        else
            $display("  verification failed ");

       


        $finish;

    end


    // WAVEFORM

    initial begin

        $dumpfile("sim/phx_common_data_memory_tb.vcd");

        $dumpvars(0, phx_common_data_memory_tb);

    end

endmodule