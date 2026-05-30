`timescale 1ns / 1ps

module cycle_count_tb;

    /*
    Use test_cycle_count.hex

    Expects the program to finish in 27 cycles. There's a breakdown of the cycle count towards the end. Can vary the repeat block 
    value to see that the program won't finish in 26 cycles but does complete in 27 cycles which is what we want.
    */

    reg clk;
    reg rst;
    
    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] alu_res;
    
    integer cycle_count;
    integer last_pc;
    integer pc_stable_count;
    
    main cpu (
        .clk(clk),
        .rst(rst),
        .pc_out(pc),
        .instr(instr),
        .alu_res(alu_res)
    );
    
    // Clock: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        $display("\n========================================");
        $display("  CYCLE COUNT TEST");
        $display("========================================\n");
        
        cycle_count = 0;
        last_pc = 0;
        pc_stable_count = 0;
        
        // Reset
        rst = 1;
        #20;
        rst = 0;
        
        $display("Cycle-by-Cycle Execution:\n");
        $display("Cycle | PC   | Instruction | Flush | Notes");
        $display("------|------|-------------|-------|------------------");
        
        // Run and monitor
        repeat(27) begin
            @(posedge clk);
            #1;  // Let signals settle
            
            cycle_count = cycle_count + 1;
            
            // Display cycle info
            $display("%5d | %4h | %h    |   %b   | %s%s",
                     cycle_count,
                     pc,
                     cpu.IF_ID_instr,
                     cpu.flush,
                     cpu.flush ? "FLUSH " : "",
                     (cpu.IF_ID_instr == 32'h00000013) ? "NOP" : "");
            
        end
        
        $display("\n========================================");
        $display("REGISTER RESULTS");
        $display("========================================\n");
        
        // Verify final register values
        $display("Final Register Values:");
        $display("x1  = %d (expected 10)", cpu.REGFILE.registers[1]);
        $display("x5  = %d (expected 50)", cpu.REGFILE.registers[5]);
        $display("x7  = %d (expected 200)", cpu.REGFILE.registers[7]);
        $display("x8  = %d (expected 100)", cpu.REGFILE.registers[8]);
        $display("x11 = %d (expected 0 - flushed)", cpu.REGFILE.registers[11]);
        $display("x12 = %d (expected 60)", cpu.REGFILE.registers[12]);
        $display("x15 = %d (expected 70)", cpu.REGFILE.registers[15]);
        $display("x17 = %d (expected 0 - flushed)", cpu.REGFILE.registers[17]);
        $display("x18 = %d (expected 80)", cpu.REGFILE.registers[18]);
        $display("x19 = %d (expected 90)", cpu.REGFILE.registers[19]);
        
        $display("\n========================================");
        $display("CYCLE COUNT ANALYSIS");
        $display("========================================\n");
        
        $display("Total Cycles: %0d", cycle_count);
        $display("\nBreakdown:");
        $display("  - Sequential instructions: 13 executed");
        $display("  - Data dependencies: 2 (with forwarding, no stalls)");
        $display("  - Taken branch: 1 (2-cycle penalty)");
        $display("  - Not-taken branch: 1 (0-cycle penalty)");
        $display("  - Jump: 1 (2-cycle penalty)");
        $display("  - Pipeline fill: 4 cycles (initial delay)");
        $display("  - Pipeline flush: 4 cycles (final delay)");

        
        $display("\nExpected cycle range: 27 cycles");
        $display("Actual cycles: %0d", cycle_count);
        
        
        
        $finish;
    end
    
    initial begin
        #1000;
        $display("\nTest timed out after 1000ns");
        $display("Final cycle count: %0d", cycle_count);
        $finish;
    end

endmodule