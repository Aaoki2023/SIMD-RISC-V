module data_mem (
    input wire clk,
    
    input wire [31:0] addr,         
    input wire [31:0] write_data,   
    input wire mem_read,            // load
    input wire mem_write,           // store
    input wire [1:0] mem_size,
    input wire mem_unsigned,
    output reg [31:0] read_data     
);

    reg [31:0] mem [0:31]; 
    
    wire [9:0] word_addr = addr[11:2];
    wire [1:0] byte_offset = addr[1:0];

    localparam MEM_BYTE = 2'b00;
    localparam MEM_HALF = 2'b01;
    localparam MEM_WORD = 2'b10;
    
    always @(*) begin
        read_data = 32'b0;
        if (mem_read) begin
            case (mem_size)
                MEM_BYTE: begin  // Load byte
                    case (byte_offset) 
                        2'b00: begin 
                            if (mem_unsigned) 
                                read_data = {24'b0, mem[word_addr][7:0]};    // Zero extend
                            else 
                                read_data = {{24{mem[word_addr][7]}}, mem[word_addr][7:0]};  // Sign extend
                        end
                        2'b01: begin 
                            if (mem_unsigned)
                                read_data = {24'b0, mem[word_addr][15:8]};
                            else
                                read_data = {{24{mem[word_addr][15]}}, mem[word_addr][15:8]};
                        end
                        2'b10: begin 
                            if (mem_unsigned)
                                read_data = {24'b0, mem[word_addr][23:16]};
                            else
                                read_data = {{24{mem[word_addr][23]}}, mem[word_addr][23:16]};
                        end
                        2'b11: begin 
                            if (mem_unsigned)
                                read_data = {24'b0, mem[word_addr][31:24]};
                            else
                                read_data = {{24{mem[word_addr][31]}}, mem[word_addr][31:24]};
                        end
                    endcase
                end
                
                MEM_HALF: begin  // Load Halfword
                    case (byte_offset)
                        2'b00: begin
                            read_data = mem_unsigned ?
                                {16'b0, mem[word_addr][15:0]} :
                                {{16{mem[word_addr][15]}}, mem[word_addr][15:0]};
                        end

                        2'b01: begin
                            read_data = 32'b0;
                        end

                        2'b10: begin
                            // bytes 2 + 3
                            read_data = mem_unsigned ?
                                {16'b0, mem[word_addr][31:16]} :
                                {{16{mem[word_addr][31]}}, mem[word_addr][31:16]};
                        end

                        2'b11: begin
                            
                            read_data = 32'b0;
                        end
                    endcase
                end
                
                MEM_WORD: begin  // Load Word
                    read_data = mem[word_addr];
                end
                
                default: begin
                    read_data = mem[word_addr];
                end
            endcase
        end
    end
    
    always @(posedge clk) begin
        if (mem_write) begin
            case (mem_size)
                MEM_BYTE: begin  // SB
                    case (byte_offset)
                        2'b00: mem[word_addr][7:0]   <= write_data[7:0];
                        2'b01: mem[word_addr][15:8]  <= write_data[7:0];
                        2'b10: mem[word_addr][23:16] <= write_data[7:0];
                        2'b11: mem[word_addr][31:24] <= write_data[7:0];
                    endcase
                end
                
                MEM_HALF: begin  // SH
                    case (byte_offset[1])  // halfword alignment
                        1'b0: mem[word_addr][15:0]  <= write_data[15:0];
                        1'b1: mem[word_addr][31:16] <= write_data[15:0];
                    endcase
                end
                
                MEM_WORD: begin  // SW
                    mem[word_addr] <= write_data;
                end
                
                default: begin
                    mem[word_addr] <= write_data;
                end
            endcase
        end
    end
    
    // initialize
    initial begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            mem[i] = 32'b0;
        end
    end

endmodule