`timescale 1ns/1ps

module main_tb;

    /**
    Use stalling.hex

    You can see stalling occur in this testbench with repeated pc values (i.e pc 14 appears twice)

    The last 4 commands corresponds to the note on the last page of the slides with the subsequenct store
    after load. You can see that no stalling occurs and the expected outputs are 
    x5 = 10
    x6 = 10
    x7 = 20
    x9 = 10
    **/

    reg clk;
    reg rst;

    wire [31:0] pc_out;
    wire [31:0] instr;
    wire [31:0] alu_res;

    // Instantiate cpu
    main cpu (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr(instr),
        .alu_res(alu_res)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;

        #10;
        rst = 0;

        // Run simulation long enough
        #400;

        $display("\n==== FINAL STATES ====");
        $display("x5 = %d", cpu.REGFILE.registers[5]);
        $display("x6 = %d", cpu.REGFILE.registers[6]);
        $display("x7 = %d", cpu.REGFILE.registers[7]);
        $display("x9 = %d", cpu.REGFILE.registers[9]);

        $finish;
    end

    // Monitor pipeline behavior
    always @(posedge clk) begin
        $display("--------------------------------------------------");
        $display("PC = %h | instr = %h", pc_out, instr);

        $display("ID/EX.rs1 = %d rs2 = %d rd = %d",
            cpu.ID_EX_rs1, cpu.ID_EX_rs2, cpu.ID_EX_rd);

        $display("EX/MEM.rd = %d | MEM/WB.rd = %d",
            cpu.EX_MEM_rd, cpu.MEM_WB_rd);

        $display("forwardA = %b | forwardB = %b",
            cpu.forwardA, cpu.forwardB);

        $display("ALU result = %d", alu_res);
    end

// show how many cycles it takes for a testbench to run

endmodule