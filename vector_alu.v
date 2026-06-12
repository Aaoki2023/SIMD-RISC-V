// Vector ALU - operates on 4 parallel 32-bit lanes
// Each lane can perform: ADD, SUB, MUL, DIV, AND, OR, XOR, NOT, SHL, SHR, SRA, CMP, PASS_B
// Total width: 128 bits (4 × 32-bit lanes)

module vector_alu (
    input wire [127:0] in1,           // 4 × 32-bit operands
    input wire [127:0] in2,           // 4 × 32-bit operands
    input wire [3:0] control,         // Operation select (matches scalar ALU)
    output reg [127:0] result,        // 4 × 32-bit results
    output wire [3:0] overflow,       // Per-lane overflow flags
    output wire [3:0] carry,          // Per-lane carry flags
    output wire [3:0] sign,           // Per-lane sign bits (MSB)
    output wire [3:0] zero,           // Per-lane zero flags
    output wire [3:0] less_than,      // Per-lane less-than comparison
    output wire [3:0] equal,          // Per-lane equal comparison
    output wire [3:0] greater_than,   // Per-lane greater-than comparison
    output wire all_zero              // True if all lanes are zero
);

    // Operation codes (matching scalar ALU)
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

    // Extract 32-bit lanes
    wire [31:0] in1_lane [0:3];
    wire [31:0] in2_lane [0:3];
    wire [31:0] result_lane [0:3];

    genvar i;

    // Unpack input lanes
    assign in1_lane[0] = in1[31:0];
    assign in1_lane[1] = in1[63:32];
    assign in1_lane[2] = in1[95:64];
    assign in1_lane[3] = in1[127:96];

    assign in2_lane[0] = in2[31:0];
    assign in2_lane[1] = in2[63:32];
    assign in2_lane[2] = in2[95:64];
    assign in2_lane[3] = in2[127:96];

    // Result computation signals for each lane
    wire [31:0] and_res [0:3];
    wire [31:0] or_res [0:3];
    wire [31:0] xor_res [0:3];
    wire [31:0] not_res [0:3];
    wire [31:0] shl_res [0:3];
    wire [31:0] shr_res [0:3];
    wire [31:0] sra_res [0:3];
    wire [63:0] add_result [0:3];
    wire [31:0] add_res_32 [0:3];
    wire [63:0] sub_result [0:3];
    wire [31:0] sub_res_32 [0:3];
    wire [63:0] mul_result [0:3];
    wire [31:0] mul_res_32 [0:3];
    wire [31:0] div_res [0:3];

    // Arithmetic flags per lane
    wire add_carry_flag [0:3];
    wire add_overflow_flag [0:3];
    wire sub_carry_flag [0:3];
    wire sub_overflow_flag [0:3];
    wire mul_overflow_flag [0:3];

    // Comparison results per lane
    wire cmp_less [0:3];
    wire cmp_equal [0:3];
    wire cmp_greater [0:3];

    // Generate parallel lane operations
    generate
        for (i = 0; i < 4; i = i + 1) begin : VECTOR_LANES

            // Logical operations
            assign and_res[i] = in1_lane[i] & in2_lane[i];
            assign or_res[i] = in1_lane[i] | in2_lane[i];
            assign xor_res[i] = in1_lane[i] ^ in2_lane[i];
            assign not_res[i] = ~in1_lane[i];

            // Shift operations
            assign shl_res[i] = in1_lane[i] << in2_lane[i][4:0];
            assign shr_res[i] = in1_lane[i] >> in2_lane[i][4:0];
            assign sra_res[i] = $signed(in1_lane[i]) >>> in2_lane[i][4:0];

            // ADD: result = in1 + in2
            assign {add_carry_flag[i], add_res_32[i]} = in1_lane[i] + in2_lane[i];
            assign add_overflow_flag[i] = (in1_lane[i][31] == in2_lane[i][31]) && 
                                          (add_res_32[i][31] != in1_lane[i][31]);

            // SUB: result = in1 - in2
            wire [31:0] in2_comp;
            assign in2_comp = ~in2_lane[i];
            assign {sub_carry_flag[i], sub_res_32[i]} = in1_lane[i] + in2_comp + 32'b1;
            assign sub_overflow_flag[i] = (in1_lane[i][31] != in2_lane[i][31]) && 
                                          (sub_res_32[i][31] == in2_lane[i][31]);

            // MUL: result = in1 × in2 (lower 32 bits, detect overflow from upper bits)
            assign mul_result[i] = in1_lane[i] * in2_lane[i];
            assign mul_res_32[i] = mul_result[i][31:0];
            assign mul_overflow_flag[i] = (mul_result[i][63:32] != 32'b0);

            // DIV: result = in1 / in2 (handle divide by zero)
            assign div_res[i] = (in2_lane[i] == 32'b0) ? 32'b0 : (in1_lane[i] / in2_lane[i]);

            // CMP: Signed comparison
            wire signed [31:0] sin1 = in1_lane[i];
            wire signed [31:0] sin2 = in2_lane[i];
            assign cmp_less[i] = (sin1 < sin2);
            assign cmp_equal[i] = (in1_lane[i] == in2_lane[i]);
            assign cmp_greater[i] = (sin1 > sin2);

            // Mux for operation result
            assign result_lane[i] = (control == AND) ? and_res[i] :
                                    (control == OR) ? or_res[i] :
                                    (control == XOR) ? xor_res[i] :
                                    (control == NOT) ? not_res[i] :
                                    (control == SHL) ? shl_res[i] :
                                    (control == SHR) ? shr_res[i] :
                                    (control == SRA) ? sra_res[i] :
                                    (control == ADD) ? add_res_32[i] :
                                    (control == SUB) ? sub_res_32[i] :
                                    (control == MUL) ? mul_res_32[i] :
                                    (control == DIV) ? div_res[i] :
                                    (control == PASS_B) ? in2_lane[i] :
                                    (control == CMP) ? sub_res_32[i] :  // CMP uses SUB result
                                    32'b0;
        end
    endgenerate

    // Pack results back into 128-bit output
    always @(*) begin
        result = {result_lane[3], result_lane[2], result_lane[1], result_lane[0]};
    end

    // Output per-lane status flags
    // Carry flag (for ADD/SUB)
    assign carry[0] = (control == ADD) ? add_carry_flag[0] : 
                      (control == SUB) ? sub_carry_flag[0] : 1'b0;
    assign carry[1] = (control == ADD) ? add_carry_flag[1] : 
                      (control == SUB) ? sub_carry_flag[1] : 1'b0;
    assign carry[2] = (control == ADD) ? add_carry_flag[2] : 
                      (control == SUB) ? sub_carry_flag[2] : 1'b0;
    assign carry[3] = (control == ADD) ? add_carry_flag[3] : 
                      (control == SUB) ? sub_carry_flag[3] : 1'b0;

    // Overflow flag (for ADD/SUB/MUL)
    assign overflow[0] = (control == ADD) ? add_overflow_flag[0] :
                         (control == SUB) ? sub_overflow_flag[0] :
                         (control == MUL) ? mul_overflow_flag[0] : 1'b0;
    assign overflow[1] = (control == ADD) ? add_overflow_flag[1] :
                         (control == SUB) ? sub_overflow_flag[1] :
                         (control == MUL) ? mul_overflow_flag[1] : 1'b0;
    assign overflow[2] = (control == ADD) ? add_overflow_flag[2] :
                         (control == SUB) ? sub_overflow_flag[2] :
                         (control == MUL) ? mul_overflow_flag[2] : 1'b0;
    assign overflow[3] = (control == ADD) ? add_overflow_flag[3] :
                         (control == SUB) ? sub_overflow_flag[3] :
                         (control == MUL) ? mul_overflow_flag[3] : 1'b0;

    // Sign flag (MSB of result for all operations)
    assign sign[0] = result_lane[0][31];
    assign sign[1] = result_lane[1][31];
    assign sign[2] = result_lane[2][31];
    assign sign[3] = result_lane[3][31];

    // Zero flag (per lane)
    assign zero[0] = (result_lane[0] == 32'b0);
    assign zero[1] = (result_lane[1] == 32'b0);
    assign zero[2] = (result_lane[2] == 32'b0);
    assign zero[3] = (result_lane[3] == 32'b0);

    // Comparison flags (for CMP operation)
    assign less_than[0] = (control == CMP) ? cmp_less[0] : 1'b0;
    assign less_than[1] = (control == CMP) ? cmp_less[1] : 1'b0;
    assign less_than[2] = (control == CMP) ? cmp_less[2] : 1'b0;
    assign less_than[3] = (control == CMP) ? cmp_less[3] : 1'b0;

    assign equal[0] = (control == CMP) ? cmp_equal[0] : 1'b0;
    assign equal[1] = (control == CMP) ? cmp_equal[1] : 1'b0;
    assign equal[2] = (control == CMP) ? cmp_equal[2] : 1'b0;
    assign equal[3] = (control == CMP) ? cmp_equal[3] : 1'b0;

    assign greater_than[0] = (control == CMP) ? cmp_greater[0] : 1'b0;
    assign greater_than[1] = (control == CMP) ? cmp_greater[1] : 1'b0;
    assign greater_than[2] = (control == CMP) ? cmp_greater[2] : 1'b0;
    assign greater_than[3] = (control == CMP) ? cmp_greater[3] : 1'b0;

    // All zero flag (true if entire 128-bit result is zero)
    assign all_zero = (result == 128'b0);

endmodule
