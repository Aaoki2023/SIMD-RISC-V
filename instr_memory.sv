// need to split read and write so read is on first half clock and write is on second half clock

module instr_memory (
    input wire clk,
    
    input wire [31:0] pc,    // PC idx
    output reg [31:0] instr,    
    
    input wire write_enable,
    input wire [31:0] write_addr,   // Word address
    input wire [31:0] write_data,    // Instruction to write
    output wire [31:0] debug_mem
);

    reg [31:0] mem [0:255];
    
    assign instr = mem[pc[11:2]];
    assign debug_mem = mem[0];
    
    always @(negedge clk) begin
        if (write_enable) begin
            mem[write_addr[9:0]] <= write_data;
            
        end
    end
    
    // default program at initialization
    // yosys doesn't like that you are writing both instructions and 32'h0000013 to a location in memory
    // change the .v to .sv to get rid of for loop warning
    initial begin
        
        integer i;
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;
        mem[0] = 32'h00000093;
        mem[1] = 32'h00500113;
        mem[2] = 32'h0020A023;
        mem[3] = 32'h00528333;
        mem[4] = 32'h0000A283;
        mem[5] = 32'h0050A223;
        mem[6] = 32'h0000A303;
        mem[7] = 32'h0000A283;
        mem[8] = 32'h00528333;
        mem[9] = 32'h006303B3;
        mem[10] = 32'h00500213;
        mem[11] = 32'h004202B3;
        mem[12] = 32'h0050A423;
        mem[13] = 32'h0080a403;
        mem[14] = 32'h0080A623;
        mem[15] = 32'h00C0A483;
        // integer i;
        // for (i = 4; i < 1024; i = i + 1)
        //     mem[i] = 32'h00000013;

        //$readmemh("./testbenches/hex_files/stalling.hex", mem); // streamline your risc-v to hex so that way you know what your hex is doing
    end

endmodule


// 00000093   // addi x1, x0, 0

// 00500113   // addi x2, x0, 5
// 0020A023   // sw x2, 0(x1)

// 0000A283   // lw x5, 0(x1)
// 00528333   // add x6, x5, x5   (10)

// 0000A283   // lw x5, 0(x1)
// 0050A223   // sw x5, 4(x1)

// 0000A303   // lw x6, 4(x1)     (5)

// 0000A283   // lw x5, 0(x1)
// 00528333   // add x6, x5, x5   (10)
// 006303B3   // add x7, x6, x6   (20)

// 00500213   // addi x4, x0, 5
// 004202B3   // add x5, x4, x4   (10)


// 0050A423   // sw x5, 8(x1)
// 0080a403   // lw x8, 8(x1)
// 0080A623   // sw x8, 12(x1)
// 00C0A483   // lw x9, 12(x1)
// check to make sure you can read from two SBRAM in parallel for register file and data memory stages - yes
// add the MUX for the last data hazard (at the very bottom of her ntoes)
// make your tests more complete
// try uploading to upduino, see if you can get your hands on an oscilliscope or multimeter