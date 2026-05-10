module alu (
    input wire [31:0] in1,
    input wire [31:0] in2,
    input wire [3:0] control,
    output reg [31:0] res,
    output reg carry,
    output reg sign,
    output reg overflow,
    output reg zero,
    output reg less_than,
    output reg equal,
    output reg greater_than
);

    // switch cases
    localparam AND = 4'b0000;
    localparam OR = 4'b0001;
    localparam XOR = 4'b0010;
    localparam NOT = 4'b0011;
    localparam SHL = 4'b0100;
    localparam SHR = 4'b0101;
    localparam ADD = 4'b0110;
    localparam SUB = 4'b0111;
    localparam CMP = 4'b1010;
    localparam SRA = 4'b1011;
    localparam PASS_B = 4'b1000;

    // result holders
    wire [31:0] sra_res;
    wire [31:0] and_res;
    wire [31:0] or_res;
    wire [31:0] not_res;
    wire [31:0] xor_res;
    wire [31:0] shl_res;
    wire [31:0] shr_res;
    wire [31:0] add_res;
    wire [31:0] sub_res;
    wire [63:0] mul_res;
    wire [31:0] div_res;

    // arith flags
    wire add_carry;
    wire add_overflow;
    wire sub_carry;
    wire sub_overflow;

    // compute
    assign and_res = in1 & in2;
    assign or_res = in1 | in2;
    assign xor_res = in1 ^ in2;
    assign not_res = ~in1;
    assign shl_res = in1 << in2[4:0];
    assign shr_res = in1 >> in2[4:0];
    assign sra_res = $signed(in1) >>> in2[4:0];

    assign {add_carry, add_res} = {1'b0, in1} + {1'b0, in2};
    assign add_overflow = (in1[31] == in2[31] && (add_res[31] != in1[31]));

    wire [31:0] in2_comp;
    assign in2_comp = ~in2;
    assign {sub_carry, sub_res} = {1'b0, in1} + {1'b0, in2_comp} + 33'b1;
    assign sub_overflow = (in1[31] != in2[31]) && (sub_res[31] == in2[31]);

    assign mul_res = in1 * in2;
    assign div_res = (in2 == 0) ? 32'b0 : (in1 / in2);

    wire signed [31:0] sin1 = in1;
    wire signed [31:0] sin2 = in2;
    wire s_less;
    wire s_equal;
    wire s_greater;

    assign s_less = (sin1 < sin2);
    assign s_equal = (in1 == in2);
    assign s_greater = (sin1 > sin2);

    always @(*) begin
        carry = 1'b0;
        overflow = 1'b0;
        sign = 1'b0;
        zero = 1'b0;
        less_than = 1'b0;
        equal = 1'b0;
        greater_than = 1'b0;
        res = 32'b0;

        case (control)
            AND: begin
                res = and_res;
                sign = res[31];
                zero = (res == 0);
            end

            OR: begin
                res = or_res;
                sign = res[31];
                zero = (res == 0);
            end

            XOR: begin
                res = xor_res;
                sign = res[31];
                zero = (res == 0);
            end

            NOT: begin
                res = not_res;
                sign = res[31];
                zero = (res == 0);
            end

            SHL: begin
                res = shl_res;
                sign = res[31];
                zero = (res == 0);
            end

            SHR: begin
                res = shr_res;
                sign = res[31];
                zero = (res == 0);
            end

            SRA: begin
                res = sra_res;
                sign = res[31];
                zero = (res == 0);
            end

            ADD: begin
                res = add_res;
                carry = add_carry;
                overflow = add_overflow;
                sign = res[31];
                zero = (res == 0);
            end

            SUB: begin
                res = sub_res;
                carry = sub_carry;
                overflow = sub_overflow;
                sign = res[31];
                zero = (res == 0);
            end

            PASS_B: begin
                res = in2;
            end
 
            default: begin
                res = 32'b0;
            end

        endcase
        less_than = s_less;
        equal = s_equal;
        greater_than = s_greater;
        sign = res[31];
        zero = (res == 0);
    end
    
endmodule