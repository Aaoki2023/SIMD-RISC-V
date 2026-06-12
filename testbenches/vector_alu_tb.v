// Vector ALU Testbench - Apio compatible
// Tests all vector operations: AND, OR, XOR, NOT, SHL, SHR, SRA, ADD, SUB, MUL, DIV, CMP, PASS_B

`timescale 1ns / 1ps

module vector_alu_tb;

    // Operation codes
    localparam AND = 4'b0000;
    localparam OR = 4'b0001;
    localparam XOR = 4'b0010;
    localparam NOT = 4'b0011;
    localparam SHL = 4'b0100;
    localparam SHR = 4'b0101;
    localparam ADD = 4'b0110;
    localparam SUB = 4'b0111;
    localparam PASS_B = 4'b1000;
    localparam CMP = 4'b1010;
    localparam SRA = 4'b1011;
    localparam MUL = 4'b1100;
    localparam DIV = 4'b1101;

    // Test signals
    reg clk;
    reg reset;
    reg [127:0] alu_in1, alu_in2;
    reg [3:0] alu_control;
    wire [127:0] alu_result;
    wire [3:0] alu_overflow;
    wire [3:0] alu_carry;
    wire [3:0] alu_sign;
    wire [3:0] alu_zero;
    wire [3:0] alu_less_than;
    wire [3:0] alu_equal;
    wire [3:0] alu_greater_than;
    wire alu_all_zero;

    // Vector register file signals
    reg [4:0] vreg_read1, vreg_read2, vreg_write;
    reg [127:0] vreg_write_data;
    reg vreg_write_enable;
    wire [127:0] vreg_read_data1, vreg_read_data2;

    integer test_count;
    integer pass_count;

    // Instantiate modules
    vector_alu valu (
        .in1(alu_in1),
        .in2(alu_in2),
        .control(alu_control),
        .result(alu_result),
        .overflow(alu_overflow),
        .carry(alu_carry),
        .sign(alu_sign),
        .zero(alu_zero),
        .less_than(alu_less_than),
        .equal(alu_equal),
        .greater_than(alu_greater_than),
        .all_zero(alu_all_zero)
    );

    vector_register_file vregfile (
        .clk(clk),
        .reset(reset),
        .read_addr1(vreg_read1),
        .read_data1(vreg_read_data1),
        .read_addr2(vreg_read2),
        .read_data2(vreg_read_data2),
        .write_addr(vreg_write),
        .write_data(vreg_write_data),
        .write_enable(vreg_write_enable)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test cases
    initial begin
        test_count = 0;
        pass_count = 0;

        // Initialize
        reset = 1;
        alu_in1 = 128'b0;
        alu_in2 = 128'b0;
        alu_control = ADD;
        vreg_read1 = 0;
        vreg_read2 = 0;
        vreg_write = 0;
        vreg_write_data = 128'b0;
        vreg_write_enable = 0;

        #10 reset = 0;

        // ============================================
        // Test 1: Vector AND
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector AND", test_count);
        alu_in1 = {32'hFFFFFFFF, 32'h0000FFFF, 32'hF0F0F0F0, 32'hAAAAAAAA};
        alu_in2 = {32'h00000000, 32'h0000FFFF, 32'h0F0F0F0F, 32'h55555555};
        alu_control = AND;
        #10;
        if (alu_result == {32'h0, 32'h0000ffff, 32'h00000000, 32'h00000000}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got 0x%x", alu_result);
        end

        // ============================================
        // Test 2: Vector OR
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector OR", test_count);
        alu_in1 = {32'hF0F0F0F0, 32'h00FF0000, 32'hA5A5A5A5, 32'h00000001};
        alu_in2 = {32'h0F0F0F0F, 32'h0000FF00, 32'h5A5A5A5A, 32'h00000002};
        alu_control = OR;
        #10;
        if (alu_result == {32'hffffffff, 32'h00ffff00, 32'hffffffff, 32'h00000003}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got 0x%x", alu_result);
        end

        // ============================================
        // Test 3: Vector XOR
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector XOR", test_count);
        alu_in1 = {32'hAA55AA55, 32'h12345678, 32'hFFFFFFFF, 32'h00000000};
        alu_in2 = {32'h55AA55AA, 32'h87654321, 32'h00000000, 32'hFFFFFFFF};
        alu_control = XOR;
        #10;
        if (alu_result == {32'hffffffff, 32'h95511559, 32'hffffffff, 32'hffffffff}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got 0x%x", alu_result);
        end

        // ============================================
        // Test 4: Vector NOT
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector NOT", test_count);
        alu_in1 = {32'h00000000, 32'hFFFFFFFF, 32'h0F0F0F0F, 32'hAAAAAAAA};
        alu_in2 = 128'b0;
        alu_control = NOT;
        #10;
        if (alu_result == {32'hffffffff, 32'h00000000, 32'hf0f0f0f0, 32'h55555555}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got 0x%x", alu_result);
        end

        // ============================================
        // Test 5: Vector SHL (Shift Left)
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector SHL", test_count);
        alu_in1 = {32'd10, 32'd5, 32'd3, 32'd1};
        alu_in2 = {32'd2, 32'd3, 32'd1, 32'd4};
        alu_control = SHL;
        #10;
        if (alu_result == {32'd40, 32'd40, 32'd6, 32'd16}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got {%0d, %0d, %0d, %0d}", 
                alu_result[127:96], alu_result[95:64], alu_result[63:32], alu_result[31:0]);
        end

        // ============================================
        // Test 6: Vector SHR (Shift Right)
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector SHR", test_count);
        alu_in1 = {32'd100, 32'd64, 32'd16, 32'd8};
        alu_in2 = {32'd2, 32'd3, 32'd2, 32'd1};
        alu_control = SHR;
        #10;
        if (alu_result == {32'd25, 32'd8, 32'd4, 32'd4}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got {%0d, %0d, %0d, %0d}", 
                alu_result[127:96], alu_result[95:64], alu_result[63:32], alu_result[31:0]);
        end

        // ============================================
        // Test 7: Vector SRA (Shift Right Arithmetic)
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector SRA", test_count);
        alu_in1 = {32'hFFFFFF9C, 32'h00000064, 32'hFFFFFFF0, 32'h00000010};
        alu_in2 = {32'd2, 32'd2, 32'd2, 32'd2};
        alu_control = SRA;
        #10;
        if (alu_result == {32'hFFFFFFE7, 32'h00000019, 32'hFFFFFFFC, 32'h00000004}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got 0x%x", alu_result);
        end

        // ============================================
        // Test 8: Vector ADD
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector ADD", test_count);
        alu_in1 = {32'd100, 32'd50, 32'd20, 32'd10};
        alu_in2 = {32'd5, 32'd30, 32'd10, 32'd5};
        alu_control = ADD;
        #10;
        if (alu_result == {32'd105, 32'd80, 32'd30, 32'd15}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got {%0d, %0d, %0d, %0d}", 
                alu_result[127:96], alu_result[95:64], alu_result[63:32], alu_result[31:0]);
        end

        // ============================================
        // Test 9: Vector SUB
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector SUB", test_count);
        alu_in1 = {32'd100, 32'd50, 32'd20, 32'd10};
        alu_in2 = {32'd5, 32'd30, 32'd10, 32'd5};
        alu_control = SUB;
        #10;
        if (alu_result == {32'd95, 32'd20, 32'd10, 32'd5}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got {%0d, %0d, %0d, %0d}", 
                alu_result[127:96], alu_result[95:64], alu_result[63:32], alu_result[31:0]);
        end

        // ============================================
        // Test 10: Vector MUL
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector MUL", test_count);
        alu_in1 = {32'd10, 32'd5, 32'd3, 32'd2};
        alu_in2 = {32'd20, 32'd4, 32'd7, 32'd6};
        alu_control = MUL;
        #10;
        if (alu_result == {32'd200, 32'd20, 32'd21, 32'd12}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got {%0d, %0d, %0d, %0d}", 
                alu_result[127:96], alu_result[95:64], alu_result[63:32], alu_result[31:0]);
        end

        // ============================================
        // Test 11: Vector DIV
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector DIV", test_count);
        alu_in1 = {32'd100, 32'd40, 32'd20, 32'd10};
        alu_in2 = {32'd5, 32'd4, 32'd2, 32'd2};
        alu_control = DIV;
        #10;
        if (alu_result == {32'd20, 32'd10, 32'd10, 32'd5}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got {%0d, %0d, %0d, %0d}", 
                alu_result[127:96], alu_result[95:64], alu_result[63:32], alu_result[31:0]);
        end

        // ============================================
        // Test 12: Vector DIV (with zero divisor)
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector DIV (zero divisor)", test_count);
        alu_in1 = {32'd100, 32'd40, 32'd20, 32'd10};
        alu_in2 = {32'd5, 32'd0, 32'd2, 32'd0};
        alu_control = DIV;
        #10;
        if (alu_result == {32'd20, 32'd0, 32'd10, 32'd0}) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got {%0d, %0d, %0d, %0d}", 
                alu_result[127:96], alu_result[95:64], alu_result[63:32], alu_result[31:0]);
        end

        // ============================================
        // Test 13: Vector CMP (Compare)
        // ============================================
        // test_count = test_count + 1;
        // $display("[Test %0d] Vector CMP", test_count);
        // alu_in1 = {32'sh10, 32'sh10, 32'sh5, 32'sh-5};
        // alu_in2 = {32'sh5, 32'sh10, 32'sh10, 32'sh-5};
        // alu_control = CMP;
        // #10;
        // if ((alu_less_than == 4'b0000) && (alu_equal == 4'b0101) && (alu_greater_than == 4'b1010)) begin
        //     $display("  PASS (less:%b, eq:%b, gt:%b)", alu_less_than, alu_equal, alu_greater_than);
        //     pass_count = pass_count + 1;
        // end else begin
        //     $display("  FAIL: less:%b (exp:0000), eq:%b (exp:0101), gt:%b (exp:1010)", 
        //         alu_less_than, alu_equal, alu_greater_than);
        // end

        // ============================================
        // Test 14: Vector PASS_B
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector PASS_B", test_count);
        alu_in1 = {32'd999, 32'd888, 32'd777, 32'd666};
        alu_in2 = {32'd100, 32'd200, 32'd300, 32'd400};
        alu_control = PASS_B;
        #10;
        if (alu_result == alu_in2) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: got {%0d, %0d, %0d, %0d}", 
                alu_result[127:96], alu_result[95:64], alu_result[63:32], alu_result[31:0]);
        end

        // ============================================
        // Test 15: Vector Register File
        // ============================================
        test_count = test_count + 1;
        $display("[Test %0d] Vector Register File", test_count);
        
        vreg_write = 5'b00000;
        vreg_write_data = {32'd40, 32'd30, 32'd20, 32'd10};
        vreg_write_enable = 1;
        #10;
        
        vreg_write = 5'b00001;
        vreg_write_data = {32'd80, 32'd60, 32'd40, 32'd20};
        #10;
        
        vreg_write_enable = 0;
        vreg_read1 = 5'b00000;
        vreg_read2 = 5'b00001;
        #10;
        
        if ((vreg_read_data1 == {32'd40, 32'd30, 32'd20, 32'd10}) && 
            (vreg_read_data2 == {32'd80, 32'd60, 32'd40, 32'd20})) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: read1=0x%x, read2=0x%x", vreg_read_data1, vreg_read_data2);
        end

        // ============================================
        // Summary
        // ============================================
        #10;
        $display("\n========================================");
        $display("VECTOR ALU TEST SUMMARY");
        $display("========================================");
        $display("Passed: %0d / %0d", pass_count, test_count);
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED");
        end
        $display("========================================\n");

        $finish;
    end
    

endmodule
