`timescale 1ns/1ps
/**
    By Mossad ElMahgob
    Module: CDC_FIFO_tb
    Comprehensive Testbench for the CDC FIFO
*/
module CDC_FIFO_tb();

    parameter DEPTH = 8;
    
    // Signals
    reg w_clk, r_clk;
    reg w_rst_n, r_rst_n;
    reg w_req, r_req;
    reg [7:0] w_data;
    wire [7:0] r_data;
    wire full, empty;

    // Instantiate DUT
    CDC_FIFO #(.depth(DEPTH)) dut (
        .write_clk(w_clk),
        .read_clk(r_clk),
        .write_rst_n(w_rst_n),
        .read_rst_n(r_rst_n),
        .write_request(w_req),
        .read_request(r_req),
        .write_data(w_data),
        .read_data(r_data),
        .full(full),
        .empty(empty)
    );

    // Clock Generation
    // Initial clock periods: Write = 10ns (100MHz), Read = 24ns (~41MHz).
    reg [31:0] w_half_period = 5;
    reg [31:0] r_half_period = 12;

    always #w_half_period w_clk = ~w_clk;
    always #r_half_period r_clk = ~r_clk;

    // Variables for loops
    integer i, j;

    // Testbench Tasks
    // reset both domains
    task reset_system;
    begin
        w_rst_n = 0;
        r_rst_n = 0;
        w_req = 0;
        r_req = 0;
        w_data = 0;
        #(50);
        w_rst_n = 1;
        r_rst_n = 1;
        #(50); // Wait for resets to clear the synchronizers safely
        $display("[%0t] System Reset Complete.", $time);
    end
    endtask

    // Perform a single synchronous write
    task write_byte(input [7:0] data);
    begin
        @(posedge w_clk);
        #1; // Emulate setup/hold time
        w_req = 1;
        w_data = data;
        @(posedge w_clk);
        #1;
        w_req = 0;
    end
    endtask

    // Perform a single synchronous read and automatically verify the output
    task read_byte(input [7:0] expected_data);
    begin
        @(posedge r_clk);
        #1; // Emulate setup/hold time
        r_req = 1;
        @(posedge r_clk);
        #1;
        r_req = 0;
        if (r_data !== expected_data) begin
            $error("[%0t] [FAIL] DATA MISMATCH: Expected %h, Got %h", $time, expected_data, r_data);
        end else begin
            $display("[%0t] [PASS] Data Match: %h", $time, r_data);
        end
    end
    endtask

    // wait for the FIFO to not be full on the write clock
    task wait_not_full;
    begin
        while (full) @(posedge w_clk);
    end
    endtask

    // wait for the FIFO to not be empty on the read clock
    task wait_not_empty;
    begin
        while (empty) @(posedge r_clk);
    end
    endtask


    // Main Test Stimulus
    initial begin
        // Initialize clocks
        w_clk = 0;
        r_clk = 0;

        // Test 1: Initialization & Reset Checks
        $display("\n[%0t] STARTING TEST 1: Reset Check", $time);
        reset_system();
        if (empty !== 1) $error("[%0t] [FAIL] FIFO should be empty after reset.", $time);
        if (full !== 0) $error("[%0t] [FAIL] FIFO should not be full after reset.", $time);


        // Test 2: Burst Write to Full & Overflow Prevention
        $display("\n[%0t] STARTING TEST 2: Burst Write (Overflow Check)", $time);
        for (i = 0; i < DEPTH; i = i + 1) begin
            write_byte(i);
        end
        
        @(posedge w_clk); #1;
        if (full !== 1) $error("[%0t] [FAIL] FIFO should be full after %0d writes.", $time, DEPTH);
        else $display("[%0t] [PASS] FIFO Full boundary flag operates correctly.", $time);
        
        // Attempt an extraneous write while full (verify pointer doesn't smash data)
        $display("[%0t] Checking Overflow Prevention...", $time);
        $display("[%0t] Attempting to write 0xFF to a FULL FIFO. This should be ignored.", $time);
        write_byte(8'hFF); 
        @(posedge w_clk);
        // Proof of no corruption happens in Test 3: If 0xFF overwrote data, the read loop will fail!


        // Test 3: Burst Read to Empty & Underflow Prevention
        $display("\n[%0t] STARTING TEST 3: Burst Read (Underflow Check)", $time);
        
        // Wait a few cycles to ensure syncing to read domain is complete
        #(100); 

        for (j = 0; j < DEPTH; j = j + 1) begin
            read_byte(j);
        end
        
        @(posedge r_clk); #1;
        if (empty !== 1) $error("[%0t] [FAIL] FIFO should be empty after %0d reads.", $time, DEPTH);
        else $display("[%0t] [PASS] FIFO Empty boundary flag operates correctly.", $time);
        
        // Attempt reading while empty
        $display("[%0t] Checking Underflow Prevention...", $time);
        $display("[%0t] Attempting an invalid read from an EMPTY FIFO.", $time);
        r_req = 1;
        @(posedge r_clk);
        #1;
        r_req = 0;
        
        // To prove pointers didn't corrupt and skip a slot, write a new value and read it back
        #(100);
        $display("[%0t] Writing 'hAA and verifying we retrieve 'hAA properly to confirm pointers are intact...", $time);
        write_byte(8'hAA);
        #(100);
        read_byte(8'hAA);

        // Test 4: Concurrent Operations - Fast Write, Slow Read (Wraparound Check)
        $display("\n[%0t] STARTING TEST 4: Concurrent Operations (Fast Write, Slow Read)", $time);
        reset_system();
        
        w_half_period = 5;  // Fast write clock
        r_half_period = 15; // Slow read clock

        fork
            // Write Thread
            begin
                // Write 3x DEPTH elements to force multiple wraparounds of the pointer
                for (i = 0; i < DEPTH * 3; i = i + 1) begin 
                    wait_not_full();
                    write_byte(i);
                end
            end
            
            // Read Thread
            begin
                for (j = 0; j < DEPTH * 3; j = j + 1) begin
                    wait_not_empty();
                    read_byte(j);
                end
            end
        join


        // Test 5: Concurrent Operations - Slow Write, Fast Read (Wraparound Check)
        $display("\n[%0t] STARTING TEST 5: Concurrent Operations (Slow Write, Fast Read)", $time);
        #(100);
        reset_system();
        
        // Reverse speeds
        w_half_period = 15; // Slow write clock
        r_half_period = 5;  // Fast read clock
        
        fork
            // Write Thread
            begin
                for (i = 0; i < DEPTH * 3; i = i + 1) begin 
                    wait_not_full();
                    write_byte(i + 100);
                end
            end
            
            // Read Thread
            begin
                for (j = 0; j < DEPTH * 3; j = j + 1) begin
                    wait_not_empty();
                    read_byte(j + 100);
                end
            end
        join

        #(100);
        $display("\n[%0t] ALL TESTS COMPLETED SUCCESSFULLY", $time);
        $finish;
    end

endmodule
