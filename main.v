module main(
    //input wire clk,
    input rst,

    // output wire [31:0] pc_out,
    // output wire [31:0] instr,
    // output wire [31:0] alu_res,
    //output wire [31:0] debug_x5,
    output led
);
    wire clk;
    //wire rst = 1'b0;
    wire [31:0] instr;
    wire [31:0] alu_res;
    wire [31:0] pc_out;
    wire [31:0] debug_x5;

    oscilator oscilator (.clk(clk));

    wire [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
    assign pc_out = pc;
    wire [31:0] branch_target;
    wire [31:0] jump_target;
    wire pc_src; 

    wire [4:0] rs1, rs2, rd;
    wire [31:0] imm;
    wire reg_write;
    wire alu_src;
    wire [3:0] alu_control;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire [1:0] mem_size;
    wire mem_unsigned;

    wire branch;              // branch instr flag
    wire jump;                // jump instr flag
    wire jalr;                // JALR flag
    wire auipc;               // AUIPC flag
    wire [2:0] branch_type;   // BEQ, BNE, BLT, BGE, BLTU, BGEU

    wire alu_zero, alu_carry, alu_overflow, alu_sign;
    wire [31:0] data1;
    wire [31:0] data2;
    wire [31:0] alu_input2; // either an immediate or reg value 
    wire [31:0] alu_input1;

    wire less_than_flag;
    wire equal_flag;
    wire greater_than_flag;
    wire [31:0] mem_data;
    wire [31:0] write_back_data;
    wire [31:0] final_write_data;
    
    wire branch_taken;
    wire [31:0] pc_plus_imm;


    // forwarding vars
    wire [1:0] forwardA;     // forward select for rs1
    wire [1:0] forwardB;     // forward select for rs2
    wire [31:0] alu_input1_fwd;
    wire [31:0] alu_input2_fwd;

    // stalling signal
    wire stall;

    // flushing signals
    wire flush;
    wire EX_branch_taken;
    wire EX_jump;

    assign flush = EX_branch_taken || EX_jump;

    wire x5_correct, x6_correct, x7_correct, x9_correct;
    wire [31:0] debug_x6, debug_x7, debug_x9;
    wire test_pass;
    wire [31:0] debug_mem;
    
    assign x5_correct = (debug_x5 == 32'd10);
    assign x6_correct = (debug_x6 == 32'd10);
    assign x7_correct = (debug_x7 == 32'd20);
    assign x9_correct = (debug_x9 == 32'd10);
    
    // LED
    assign led = ~(x5_correct & x6_correct & x7_correct & x9_correct);  // active LOW LED

    // IF / ID
    reg [31:0] IF_ID_pc;
    reg [31:0] IF_ID_instr;
    reg [31:0] IF_ID_pc_plus_4;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            IF_ID_pc <= 0;
            IF_ID_instr <= 0;
            IF_ID_pc_plus_4 <= 0;
        end else if (flush) begin
            IF_ID_pc <= 0;
            IF_ID_instr <= 32'h00000013; // (NOP)
            IF_ID_pc_plus_4 <= 0;
        end else if (!stall) begin
            IF_ID_pc <= pc;
            IF_ID_instr <= instr;
            IF_ID_pc_plus_4 <= pc_plus_4;
        end
    end

    // ID / EX
    reg [31:0] ID_EX_data1;
    reg [31:0] ID_EX_data2;
    reg [31:0] ID_EX_imm;
    reg [4:0] ID_EX_rd;
    reg [3:0] ID_EX_alu_control;
    reg ID_EX_alu_src;
    reg ID_EX_reg_write;
    reg ID_EX_mem_read;
    reg ID_EX_mem_write;
    reg ID_EX_mem_to_reg;
    reg ID_EX_auipc;
    reg [31:0] ID_EX_pc;
    reg [31:0] ID_EX_pc_plus_4;
    reg ID_EX_jump;
    reg ID_EX_branch;
    reg [2:0] ID_EX_branch_type;
    reg ID_EX_jalr;
    reg [4:0] ID_EX_rs1;
    reg [4:0] ID_EX_rs2;
    reg [1:0] ID_EX_mem_size;
    reg ID_EX_mem_unsigned;

    // stalling logic
    assign stall = ID_EX_mem_read &&
               ((ID_EX_rd == rs1) || (ID_EX_rd == rs2 && !ID_EX_mem_write)) &&
               (ID_EX_rd != 0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ID_EX_data1 <= 0;
            ID_EX_data2 <= 0;
            ID_EX_imm <= 0;
            ID_EX_rd <= 0;
            ID_EX_alu_control <= 0;
            ID_EX_alu_src <= 0;
            ID_EX_reg_write <= 0;
            ID_EX_mem_write <= 0;
            ID_EX_mem_read <= 0;
            ID_EX_mem_to_reg <= 0;
            ID_EX_auipc <= 0;
            ID_EX_pc <= 0;
            ID_EX_pc_plus_4 <= 0;
            ID_EX_jump <= 0;
            ID_EX_branch <= 0;
            ID_EX_branch_type <= 0;
            ID_EX_jalr <= 0;
            ID_EX_rs1 <= 0;
            ID_EX_rs2 <= 0;
            ID_EX_mem_size <= 0;
            ID_EX_mem_unsigned <= 0;
        end else if (flush) begin
            // clear control signals but keep data
            ID_EX_rd <= 0;
            ID_EX_reg_write <= 0;
            ID_EX_mem_write <= 0;
            ID_EX_mem_read <= 0;
            ID_EX_jump <= 0;
            ID_EX_branch <= 0;
        end else if (stall) begin
            ID_EX_rd <= 0;
            ID_EX_reg_write <= 0;
            ID_EX_mem_write <= 0;
            ID_EX_mem_read <= 0;
            ID_EX_mem_to_reg <= 0;
            ID_EX_alu_control <= 0;
            ID_EX_alu_src <= 0;
            ID_EX_branch <= 0;
            ID_EX_jump <= 0;
        end else begin
            ID_EX_data1 <= data1;
            ID_EX_data2 <= data2;
            ID_EX_imm <= imm;
            ID_EX_rd <= rd;
            ID_EX_alu_control <= alu_control;
            ID_EX_alu_src <= alu_src;
            ID_EX_reg_write <= reg_write;
            ID_EX_auipc <= auipc;
            ID_EX_pc <= IF_ID_pc;
            ID_EX_pc_plus_4 <= IF_ID_pc_plus_4;
            ID_EX_jump <= jump;
            ID_EX_branch <= branch;
            ID_EX_branch_type <= branch_type;
            ID_EX_jalr <= jalr;
            ID_EX_mem_read <= mem_read;
            ID_EX_mem_write <= mem_write;
            ID_EX_mem_to_reg <= mem_to_reg;
            ID_EX_rs1 <= rs1;
            ID_EX_rs2 <= rs2;
            ID_EX_mem_size <= mem_size;
            ID_EX_mem_unsigned <= mem_unsigned;
        end
    end

    // EX / MEM
    reg [31:0] EX_MEM_alu_res;
    reg [31:0] EX_MEM_data2;
    reg [4:0] EX_MEM_rd;
    reg EX_MEM_reg_write;
    reg EX_MEM_mem_to_reg;
    reg EX_MEM_mem_read;
    reg EX_MEM_mem_write;
    reg [31:0] EX_MEM_pc_plus_4;
    reg EX_MEM_jump;
    reg [1:0] EX_MEM_mem_size;
    reg EX_MEM_mem_unsigned;

    // forwarding for mem to mem hazard
    wire [31:0] store_data2_fwd;

    assign store_data2_fwd = (EX_MEM_mem_read && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs2))
                                    ? mem_data
                                    : alu_input2_fwd;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            EX_MEM_alu_res <= 0;
            EX_MEM_data2 <= 0;
            EX_MEM_rd <= 0;
            EX_MEM_reg_write <= 0;
            EX_MEM_mem_to_reg <= 0;
            EX_MEM_mem_read <= 0;
            EX_MEM_mem_write <= 0;
            EX_MEM_pc_plus_4 <= 0;
            EX_MEM_jump <= 0;
            EX_MEM_mem_size <= 0;
            EX_MEM_mem_unsigned <= 0;
        end else begin
            EX_MEM_alu_res <= alu_res;
            EX_MEM_data2 <= store_data2_fwd;
            EX_MEM_rd <= ID_EX_rd;
            EX_MEM_reg_write <= ID_EX_reg_write;
            EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
            EX_MEM_mem_read <= ID_EX_mem_read;
            EX_MEM_mem_write <= ID_EX_mem_write;
            EX_MEM_pc_plus_4 <= ID_EX_pc_plus_4;
            EX_MEM_jump <= ID_EX_jump;
            EX_MEM_mem_size <= ID_EX_mem_size;
            EX_MEM_mem_unsigned <= ID_EX_mem_unsigned;
        end
    end

    // MEM / WB
    reg [31:0] MEM_WB_mem_data;
    reg [31:0] MEM_WB_alu_res;
    reg [4:0] MEM_WB_rd;
    reg MEM_WB_reg_write;
    reg MEM_WB_mem_to_reg;
    reg [31:0] MEM_WB_pc_plus_4;
    reg MEM_WB_jump;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            MEM_WB_mem_data <= 0;
            MEM_WB_alu_res <= 0;
            MEM_WB_rd <= 0;
            MEM_WB_reg_write <= 0;
            MEM_WB_mem_to_reg <= 0;
            MEM_WB_pc_plus_4 <= 0;
            MEM_WB_jump <= 0;
        end else begin
            MEM_WB_mem_data <= mem_data;
            MEM_WB_alu_res <= EX_MEM_alu_res;
            MEM_WB_rd <= EX_MEM_rd;
            MEM_WB_reg_write <= EX_MEM_reg_write;
            MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
            MEM_WB_pc_plus_4 <= EX_MEM_pc_plus_4;
            MEM_WB_jump <= EX_MEM_jump;
        end
    end
    
    program_counter PC (
        .clk(clk),
        .rst(rst),
        .pc_nxt(pc_next),
        .curr(pc)
    );

    // PC + 4 
    assign pc_plus_4 = pc + 4;
    
    wire [31:0] EX_pc_plus_imm;
    assign EX_pc_plus_imm = ID_EX_pc + ID_EX_imm;

    wire [31:0] EX_jump_target;
    assign EX_jump_target =
            ID_EX_jalr ? ((alu_input1_fwd + ID_EX_imm) & 32'hFFFFFFFE)
                    : EX_pc_plus_imm;
    
    // Branch decision logic
    assign EX_branch_taken = ID_EX_branch && (
        (ID_EX_branch_type == 3'b000 && equal_flag) ||
        (ID_EX_branch_type == 3'b001 && !equal_flag) ||
        (ID_EX_branch_type == 3'b100 && less_than_flag) ||
        (ID_EX_branch_type == 3'b101 && !less_than_flag) ||
        (ID_EX_branch_type == 3'b110 && less_than_flag) ||
        (ID_EX_branch_type == 3'b111 && !less_than_flag)
    );

    assign EX_jump = ID_EX_jump;
    
    
    // Next PC mux
    assign pc_src = EX_branch_taken || ID_EX_jump;

    // STALLING PC
    assign pc_next = stall ? pc : 
                 (pc_src ? EX_jump_target : pc_plus_4);

    // forwwarding unit
    forwarding_unit FU (
        .ID_EX_rs1(ID_EX_rs1),               
        .ID_EX_rs2(ID_EX_rs2),              
        .EX_MEM_rd(EX_MEM_rd),         
        .MEM_WB_rd(MEM_WB_rd),         
        .EX_MEM_reg_write(EX_MEM_reg_write), 
        .MEM_WB_reg_write(MEM_WB_reg_write), 
        .forwardA(forwardA),           
        .forwardB(forwardB)            
    );

    instr_memory IMEM (
        .pc(pc),
        .instr(instr),
        .write_enable(1'b0),
        .write_addr(32'b0),
        .write_data(32'b0),
        .debug_mem(debug_mem)
    );

    instr_decode DECODE (
        .instr(IF_ID_instr),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .alu_control(alu_control),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .mem_size(mem_size),
        .mem_unsigned(mem_unsigned),
        .jump(jump),
        .branch(branch),
        .jalr(jalr),
        .auipc(auipc),
        .branch_type(branch_type)
    );

    register_file REGFILE (
        .clk(clk),
        .reset(rst),
        .r_addr1(rs1),
        .r_addr2(rs2),
        .r_data1(data1),
        .r_data2(data2),
        .w_enable(MEM_WB_reg_write),
        .w_addr(MEM_WB_rd),
        .w_data(final_write_data),
        .debug_x5(debug_x5),
        .debug_x6(debug_x6),
        .debug_x7(debug_x7),
        .debug_x9(debug_x9)
    );

    assign alu_input1_fwd = (forwardA == 2'b10) ? EX_MEM_alu_res :
                        (forwardA == 2'b01) ? write_back_data :
                        ID_EX_data1;
    assign alu_input1 = ID_EX_auipc ? ID_EX_pc : alu_input1_fwd;

    // Operand 2
    assign alu_input2_fwd = (forwardB == 2'b10) ? EX_MEM_alu_res :
                             (forwardB == 2'b01) ? write_back_data :
                             ID_EX_data2;
    assign alu_input2 = ID_EX_alu_src ? ID_EX_imm : alu_input2_fwd;  

    alu A (
        .in1(alu_input1),
        .in2(alu_input2),
        .control(ID_EX_alu_control),
        .res(alu_res),
        .carry(alu_carry),
        .sign(alu_sign),
        .overflow(alu_overflow),
        .zero(alu_zero),
        .less_than(less_than_flag),
        .greater_than(greater_than_flag),
        .equal(equal_flag)
    );

    data_mem DMEM (
        .clk(clk),
        .addr(EX_MEM_alu_res),
        .write_data(EX_MEM_data2),
        .mem_read(EX_MEM_mem_read),
        .mem_write(EX_MEM_mem_write),
        .mem_size(EX_MEM_mem_size),
        .mem_unsigned(EX_MEM_mem_unsigned),
        .read_data(mem_data)
    );

    assign write_back_data = MEM_WB_mem_to_reg ? MEM_WB_mem_data : MEM_WB_alu_res;
    assign final_write_data = MEM_WB_jump ? MEM_WB_pc_plus_4 : write_back_data;

endmodule