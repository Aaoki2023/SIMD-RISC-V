module register_file (
    input wire clk,
    input wire reset,
    input wire [4:0] r_addr1,
    input wire [4:0] r_addr2,
    input wire w_enable,
    input wire [4:0] w_addr,
    input wire [31:0] w_data,


    output wire check,
    output reg [31:0] r_data1,
    output reg [31:0] r_data2,

    output wire [31:0] debug_x5,
    output wire [31:0] debug_x6,
    output wire [31:0] debug_x7,
    output wire [31:0] debug_x9
);

    reg [31:0] registers [31:0]; // make sure the register file is running fast enough to fit within the clock cycle along with load/stores and alu
                                 // figure out how to tell if something is going wrong in hardware so that you can start actually testing with the upduino
                                 // try to get jumps and branches done
                                 // look into pipelining try to get up to Part 3 done
                                 // how would you actually test the hardware itself
    integer i;

    // initalize registers
    always @(posedge clk or posedge reset) begin

        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] = 32'b0;
            end
        end

        // make sure 0 address is always 0
        // can also write on negative clock edge
        else begin
            if (w_enable && w_addr != 5'b00000) begin
                registers[w_addr] <= w_data; 
            end
        end
    end

    // always @(*) begin

    //     $display("r_data 1 = %d", r_data1);
    //     $display("r_data 2 = %d", r_data2);
    // end
    // assign r_data1 = (r_addr1 == 5'b00000) ? 32'b0 : registers[r_addr1];
    // assign r_data2 = (r_addr2 == 5'b00000) ? 32'b0 :registers[r_addr2];
    // always @(negedge clk) begin  
    //     r_data1 = registers[r_addr1];   
    //     r_data2 = registers[r_addr2];
    // end
    assign r_data1 = (r_addr1 == 0) ? 0 :
                 (w_enable && w_addr == r_addr1) ? w_data :
                 registers[r_addr1];

    assign r_data2 = (r_addr2 == 0) ? 0 :
                    (w_enable && w_addr == r_addr2) ? w_data :
                    registers[r_addr2];
        
    assign debug_x5 = registers[5];
    assign debug_x6 = registers[6];
    assign debug_x7 = registers[7];
    assign debug_x9 = registers[9];
endmodule


// try to look into seeing if there is some onboard storage of the updiono / how we can do instruction memory with the upduino
// reads should go on the negative edge in order to prevent race conditions between subsequent instructions to the same registers
// add in a test to make sure this holds

// write the instr_mem and data_mem as BRAM blocks, ensure they are separate blocks with different addresses so that they don't corrupt each other
// ensure the PC cycle is long enough to allow the worst case pathway to run, basically make sure all time delays are copacetic
// if u have time think of making some sort of interface to allow you to upload assembly to ur pc, this will poroabbly look like an arduino file that converts your assembly o machine code and apsses it to the fpga
// worst case scenario is the load instruction, need to add load instruction
// look into the differences between LB, LH, LW, LBU, and LHU
// SPRAM loads in 16 bits, BRAM can load in 2, 4, 8, or 16 --> LW will now take 2 loads since its 32 bits
// 

// BRAM read and write widths are 16 bits. So what if instead we use two BRAM blocks one that contains the lower 16 bits and the other with 16 upper bits. Then I could read from both of them to get the full word width, this may also make the LB and LH simpler too.
// I think for instr_mem I may run into the same issue since instructions are 32 bits. So maybe do the same thing? 

// make sure the byte stores and loads will not override any of the upper 8 bits stored


// branch prediction -- this one Milda really likes it seems
// SIMD instructions
// dual instruction read instructions
// basically just make your processor closer to modern processors
// floating point unit, SIMD --> this is what ARM Neon does but is currently theoretical in RISC-V, divide unit (from textbook), register renaming (probably not feasible though), build a GPU? impossible on a FPGA but could just do HDL? - it's like SIMD on steroids