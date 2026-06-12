# Vector SIMD Components

This directory contains the standalone vector ALU and vector register file for a SIMD-enabled RISC-V processor. These components operate independently and will be integrated into the main CPU in future phases.

## Components

### 1. vector_alu.v
**Vector Arithmetic Logic Unit** - Performs parallel operations on 4×32-bit lanes (128-bit total).

**Features:**
- **Lanes:** 4 independent 32-bit computation units
- **Operations:** (control signals match scalar ALU)
  - **Logical:** AND (0x0), OR (0x1), XOR (0x2), NOT (0x3)
  - **Shift:** SHL (0x4), SHR (0x5), SRA (0xB)
  - **Arithmetic:** ADD (0x6), SUB (0x7), MUL (0xC), DIV (0xD)
  - **Comparison:** CMP (0xA) - signed comparison
  - **Utility:** PASS_B (0x8) - pass through in2
- **Status Flags (per-lane 4-bit outputs):**
  - `carry[3:0]`: Per-lane carry (for ADD/SUB)
  - `overflow[3:0]`: Per-lane overflow (for ADD/SUB/MUL)
  - `sign[3:0]`: Per-lane sign bit (MSB)
  - `zero[3:0]`: Per-lane zero flag
  - `less_than[3:0]`: Signed less-than (for CMP)
  - `equal[3:0]`: Equality comparison (for CMP)
  - `greater_than[3:0]`: Signed greater-than (for CMP)
  - `all_zero`: True if entire 128-bit result is zero

**Interface:**
```verilog
module vector_alu (
    input wire [127:0] in1,                // 4×32-bit operand 1
    input wire [127:0] in2,                // 4×32-bit operand 2
    input wire [3:0] control,              // Operation select (4-bit)
    output reg [127:0] result,             // 4×32-bit result
    output wire [3:0] overflow,
    output wire [3:0] carry,
    output wire [3:0] sign,
    output wire [3:0] zero,
    output wire [3:0] less_than,
    output wire [3:0] equal,
    output wire [3:0] greater_than,
    output wire all_zero
);
```

**Operation Details:**
- **ADD/SUB:** Overflow and carry flags set only for ADD/SUB
- **MUL:** Overflow flag indicates if result has significant high 32 bits (product > 32-bit)
- **DIV:** Returns 0 if divisor is 0 (no exception thrown)
- **CMP:** Sets comparison flags using signed arithmetic; result holds (in1 - in2)
- **Shift:** Shift amount limited to [4:0] (0-31 bits)
- **NOT:** Only uses in1; in2 is ignored

### 2. vector_register_file.v
**Vector Register File** - Stores 32 registers, each 128-bit (4×32-bit lanes).

**Features:**
- **Registers:** 32 total (5-bit address)
- **Width:** 128 bits per register
- **Read Ports:** 2 asynchronous read ports (combinatorial)
- **Write Port:** 1 synchronous write port
- **Reset:** Clears all registers to zero

**Interface:**
```verilog
module vector_register_file (
    input wire clk,
    input wire reset,
    
    input wire [4:0] read_addr1,
    output reg [127:0] read_data1,
    
    input wire [4:0] read_addr2,
    output reg [127:0] read_data2,
    
    input wire [4:0] write_addr,
    input wire [127:0] write_data,
    input wire write_enable
);
```

### 3. testbenches/vector_alu_tb.v
**Comprehensive Testbench** - Validates all vector ALU operations and register file functionality.

**Tests Included:**
1. **Test 1-4:** Logical operations (AND, OR, XOR, NOT)
2. **Test 5-7:** Shift operations (SHL, SHR, SRA)
3. **Test 8-10:** Basic arithmetic (ADD, SUB, MUL)
4. **Test 11-12:** Division with divide-by-zero handling
5. **Test 13:** Signed comparison (CMP) - tests less_than, equal, greater_than flags
6. **Test 14:** PASS_B passthrough operation
7. **Test 15:** Integration test with vector register file

## Usage

### Running the Testbench

**Using Iverilog/VVP:**
```bash
iverilog -o vector_alu_tb.vvp \
  vector_alu.v \
  vector_register_file.v \
  testbenches/vector_alu_tb.v
vvp vector_alu_tb.vvp
```

**Using Xilinx Vivado or similar:**
- Add `vector_alu.v` and `vector_register_file.v` to your project
- Add `testbenches/vector_alu_tb.v` as a simulation source
- Run behavioral simulation

### Example Operation

```verilog
// Vector ADD: [10, 5, 3, 2] + [2, 1, 1, 1] = [12, 6, 4, 3]
in1      = {32'd10, 32'd5, 32'd3, 32'd2};
in2      = {32'd2,  32'd1, 32'd1, 32'd1};
control  = VADD;
// result = {32'd12, 32'd6, 32'd4, 32'd3}
```

## Architecture Decisions

1. **Lane-based parallelism:** Each 32-bit lane operates independently, enabling efficient pipelined execution
2. **128-bit width:** Chosen to allow 4 independent 32-bit FP or integer operations, a common SIMD width
3. **Asynchronous reads:** Register reads are combinatorial for minimal latency
4. **Synchronous writes:** Register writes occur on clock edges to maintain consistency
5. **Per-lane flags:** Overflow/carry flags are reported per-lane to support selective error handling

## Next Steps (Phase 2)

Once vector ALU is validated:
- Create vector control logic for instruction decoding
- Design vector load/store units for memory operations
- Integrate with main CPU pipeline
- Implement vector memory alignment and masking

