// Vector Register File
// 32 registers × 128-bit (each register holds 4 × 32-bit lanes)
// Supports dual-read, single-write per cycle

module vector_register_file (
    input wire clk,
    input wire reset,
    
    // Read ports
    input wire [4:0] read_addr1,      // Read register address 1 (5 bits for 32 registers)
    output reg [127:0] read_data1,    // 128-bit output 1
    
    input wire [4:0] read_addr2,      // Read register address 2
    output reg [127:0] read_data2,    // 128-bit output 2
    
    // Write port
    input wire [4:0] write_addr,      // Write register address
    input wire [127:0] write_data,    // 128-bit input
    input wire write_enable           // Write enable
);

    // 32 registers, each 128 bits
    reg [127:0] registers [31:0];

    integer i;

    // Initialize registers to zero
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 128'b0;
        end
    end

    // Reset on clock edge or async reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 128'b0;
            end
        end
    end

    // Asynchronous read (combinatorial)
    always @(*) begin
        read_data1 = registers[read_addr1];
        read_data2 = registers[read_addr2];
    end

    // Synchronous write on posedge clock
    always @(posedge clk) begin
        if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end

endmodule
