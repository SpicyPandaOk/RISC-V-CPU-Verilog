// Code your design here
module alu (
  input [31:0] a,b,
  input [3:0] sel,
  output reg [31:0] result,
  output reg  zero, negative, overflow);
  
  wire[31:0] add_out, sub_out, and_out, or_out, xor_out, left_out, right_outl, right_outa, slt_out, sltu_out;
  wire carry_add;
  
  add add1(.a(a), .b(b), .cout(carry_add), .sum(add_out));
  sub sub1(.a(a), .b(b), .sum(sub_out));
  xorer xor1 (.a(a), .b(b), .result(xor_out));
  orer or1 (.a(a), .b(b),  .result(or_out));
  ander and1(.a(a), .b(b), .result(and_out));
  l_shift left1 (.a(a), .result(left_out), .amount(b));
  r_shiftl rightl1 (.a(a), .result(right_outl), .amount(b));
  r_shifta righta1 (.a(a), .result(right_outa), .amount(b));
  slt slt1 (.a(a), .b(b), .result(slt_out));
  sltu sltu1 (.a(a), .b(b), .result(sltu_out));

  
 
  always @(*) begin
    case(sel)
      4'd0: result = add_out;
      4'd1: result = sub_out;
      4'd2: result = xor_out;
      4'd3: result = or_out;
      4'd4: result = and_out;
      4'd5: result = left_out;
      4'd6: result = right_outl;
      4'd7: result = right_outa;
      4'd8: result = slt_out;
      4'd9: result = sltu_out;
      default: result = 0;
    endcase
    zero = result == 32'd0;
    negative =  result[31];
    overflow = (sel == 4'b0) ? (a[31] == b[31]) && (result[31] != a[31]): (sel== 3'b1) ? (a[31] != b[31]) && (result[31] != a[31]): 1'd0;
  end
endmodule





module inst_decoder (
  input [31:0] instr,
  output reg [6:0] opcode,
  output reg [4:0] rd,
  output reg [2:0] funct3,
  output reg [4:0] rs1, rs2,
  output reg [6:0] funct7,
  output reg [31:0] imm);
  always @(*) begin
    opcode = instr[6:0];
    rd     = 5'b0;
 	  funct3 = 3'b0;
 	  rs1    = 5'b0;
 	  rs2    = 5'b0;
 	  funct7 = 7'b0;
  	imm    = 32'b0;
    if (opcode == (7'b0110011)) begin
	
      rd = instr[11:7];
      funct3 = instr[14:12];
      rs1 = instr[19:15];
      rs2 = instr[24:20];
      funct7 = instr[31:25];
    end
    else if(opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b1100111) begin
      rd = instr[11:7];
      funct3 = instr[14:12];
      rs1 = instr[19:15];
      imm = {{20{instr[31]}}, instr[31:20]};
    end
    else if (opcode == 7'b0100011) begin
      imm[4:0] = instr[11:7];
      funct3 = instr[14:12];
      rs1 = instr[19:15];
      rs2 = instr[24:20];
      imm[11:5] = instr[31:25];
      imm[31:12] = {20{instr[31]}};
    end
    else if (opcode == 7'b1100011) begin
      imm[11]= instr[7];
      imm[4:1] = instr[11:8];
      funct3 = instr[14:12];
      rs1 = instr[19:15];
      rs2 = instr[24:20];
      imm[10:5] = instr[30:25];
      imm[12] = instr[31];
      imm[31:13] = {19{instr[31]}};
      
    end
    else if (opcode == 7'b1101111) begin
      rd = instr[11:7];
      imm[19:12] = instr[19:12];
      imm[11] = instr[20];
      imm[10:1] = instr[30:21];
      imm[20] = instr[31];
      imm[31:21] = {11{instr[31]}};
    end
  end
  
      
endmodule




module reg_file(
  input clk, we,
  input [4:0] rs1, rs2, rd,
  input [31:0] write_data,
  output [31:0] read1, read2);
  
  reg [31:0] regs[0:31];
  assign read1 = (rs1 == 0) ? 0 : regs[rs1];
  assign read2 = (rs2 == 0) ? 0 : regs[rs2];
  
  always @(posedge clk) begin
    if(we && rd != 0) begin
      regs[rd] <= write_data;
    end
  end
  
  initial begin
    integer i;
    for(i = 0; i < 32; i = i + 1)
      regs[i] = 32'b0;
  end
  
  
endmodule

  
  
module prog_counter(
  input b_ena, clk, ce, rst,
  input [31:0] branch_target,
  output reg [31:0] count);

  always@(posedge clk) begin
    if(rst) begin
      count <= 0;
    end
    else begin
      if(b_ena) begin
        count <= branch_target;
      end
      else if (ce) begin
        count <= count + 4;
      end
    end
  end
endmodule
    
 


module inst_mem(
  input [31:0] addr,
  output [31:0] instr);
  
  reg [31:0] rom [0:255];
  
  initial begin
    $readmemh("instmem.hex", rom);
  end
  
  assign instr = rom[addr[9:2]];
endmodule



module data_mem(
  input[31:0] addr,
  input MemRead, MemWrite, clk,
  input [31:0] write_data,
  input[2:0] funct3,
  output reg[31:0] data);
  
  
  
  reg[31:0] dregs [0:255];
  wire [31:0] word;
  assign word = dregs[addr[9:2]];
  
  
  initial begin
    for(int i = 0; i < 256; i = i + 1) begin
      dregs[i] = 32'b0;
    end
  end
  always@(*) begin
    if (MemRead) begin
      case(funct3)
        3'h0: begin
          case(addr[1:0])
            2'b00: data = {{24{word[7]}}, word[7:0]};
            2'b01: data = {{24{word[15]}}, word[15:8]};
            2'b10: data = {{24{word[23]}}, word[23:16]};
            2'b11: data = {{24{word[31]}}, word[31:24]};
          endcase
        end
        
        3'h1: begin
          case(addr[1])
            1'b0: data = {{16{word[15]}}, word[15:0]};
            1'b1: data = {{16{word[31]}}, word[31:16]};
          endcase
        end
        
        3'h2: data = word;
        
 		3'h4: begin
          case(addr[1:0]) 
            2'b00: data = {24'b0, word[7:0]};
            2'b01: data = {24'b0, word[15:8]};
            2'b10: data = {24'b0, word[23:16]};
            2'b11: data = {24'b0, word[31:24]};
          endcase
        end
        
        
        3'h5: begin
          case(addr[1])
            1'b0: data = {16'b0, word[15:0]};
            1'b1: data = {16'b0, word[31:16]};
          endcase
        end
        
        default: data = 32'b0;
      endcase
    end
    else begin
      data = 32'b0;
    end
  end
  
  
  always@(posedge clk) begin
    if(MemWrite) begin
      case(funct3)
        3'h0: begin
          case(addr[1:0])
            2'b00: dregs[addr[9:2]][7:0] <= write_data[7:0];
            2'b01: dregs[addr[9:2]][15:8] <= write_data[7:0];
            2'b10: dregs[addr[9:2]][23:16] <= write_data[7:0];
            2'b11: dregs[addr[9:2]][31:24] <= write_data[7:0];
            
          endcase
        end
        3'h1: begin
          case(addr[1])
            1'b0: dregs[addr[9:2]][15:0] <= write_data[15:0];
            1'b1: dregs[addr[9:2]][31:16] <= write_data[15:0];
          endcase
        end
        
        3'h2: dregs[addr[9:2]][31:0] <= write_data[31:0];
      endcase
    end
  end
     
        
  
endmodule





module control(
  input [6:0] opcode,
  output reg [2:0] ALUOp,
  output reg RegWrite,ALUSrc, MemRead, MemWrite, MemToReg, branch);
  
  
  localparam R_type = 3'd0, I_type = 3'd1, LOAD_type = 3'd2, S_type = 3'd3, B_type  = 3'd4, J_type = 3'd5;
  
  always @(*) begin
    
  	if(opcode == 7'b0110011) begin
      ALUOp = R_type;
      RegWrite = 1;
      ALUSrc = 0;
      MemRead = 0;
      MemWrite = 0;
      MemToReg = 0;
      branch = 0;
    end
    else if (opcode == 7'b0010011) begin
      ALUOp = I_type;
      RegWrite  = 1;
      ALUSrc = 1;
      MemRead = 0;
      MemWrite = 0;
      MemToReg = 0;
      branch = 0;
    end
    else if (opcode == 7'b0000011) begin
      ALUOp = LOAD_type;
      RegWrite = 1;
      ALUSrc = 1;
      MemRead = 1;
      MemWrite = 0;
      MemToReg = 1;
      branch = 0;

    end
    else if (opcode == 7'b0100011) begin
      ALUOp = S_type;
      RegWrite = 0;
      ALUSrc = 1;
      MemRead = 0;
      MemWrite = 1;
      MemToReg = 0;
      branch = 0;
    end
    else if(opcode == 7'b1100011) begin
      ALUOp = B_type;
      RegWrite = 0;
      ALUSrc = 0;
      MemRead = 0;
      MemWrite = 0;
      MemToReg = 0;
	  branch = 1;
    end
    else if(opcode == 7'b1101111 || opcode == 7'b1100111) begin
      ALUOp = J_type;
      RegWrite = 1;
      ALUSrc = 1;
      MemRead = 0;
      MemWrite = 0;
      MemToReg = 0;
      branch = 1;
    end
    else begin
      ALUOp = R_type;
      RegWrite = 0;
      ALUSrc = 0;
      MemRead = 0;
      MemWrite = 0;
      MemToReg = 0;
      branch = 0;
    end
  end
endmodule
    


module alu_control(
  input [2:0] ALUOp,
  input [2:0] funct3, 
  input [6:0] funct7,
  input [31:0] imm,
  output reg [3:0] sel);

  localparam ALU_ADD = 4'd0,
  ALU_SUB = 4'd1,
  ALU_XOR = 4'd2, 
  ALU_OR = 4'd3,
  ALU_AND = 4'd4,
  ALU_SLL = 4'd5,
  ALU_SRL = 4'd6,
  ALU_SRA = 4'd7,
  ALU_SLT = 4'd8,
  ALU_SLTU = 4'd9;
  
  localparam R_type = 3'd0, I_type = 3'd1, LOAD_type = 3'd2, S_type = 3'd3, B_type  = 3'd4, J_type = 3'd5;
  
  always@(*) begin
    if(ALUOp == R_type) begin
      
      case(funct3) 
        3'h0: 	if(funct7 == 7'b0000000) sel = ALU_ADD;
        else if(funct7 == 7'b0100000) sel = ALU_SUB;
        		else sel = ALU_ADD;
          
        3'h4: sel = ALU_XOR;
        3'h6: sel = ALU_OR;
        3'h7: sel = ALU_AND;
        3'h1: sel = ALU_SLL;
        3'h5: begin 
          if(funct7 == 7'h20) sel = ALU_SRA;
          else sel = ALU_SRL;
        end

         
        3'h2: sel = ALU_SLT;
        3'h3: sel = ALU_SLTU;
        default: sel = ALU_ADD;
      endcase
    end
    else if (ALUOp == I_type) begin
      case(funct3)
        3'h0: sel = ALU_ADD;
        3'h4: sel = ALU_XOR;
        3'h6: sel = ALU_OR;
        3'h7: sel = ALU_AND;
        3'h1: sel = ALU_SLL;
        3'h5: begin
          if(imm[11:5] == 7'h20) sel = ALU_SRA;
          else sel = ALU_SRL;
        end
        3'h2: sel = ALU_SLT;
        3'h3: sel = ALU_SLTU;
        default: sel = ALU_ADD;
      endcase
    end
    else if(ALUOp == LOAD_type) begin
      sel = ALU_ADD;
    end
    else if(ALUOp == S_type) begin
      sel = ALU_ADD;
    end
    else if(ALUOp == B_type) begin
      sel = ALU_SUB;
    end
    else begin
      sel = ALU_ADD;
    end
  end
endmodule





module cpu(
  input clk, rst,
  output[31:0] result);
  
  wire[31:0] iaddress;
  
  wire [31:0] branch_target;
  wire branch;
  wire[31:0] daddress;
  wire[31:0] data;
  
  wire [6:0] opcode;
  wire [4:0] rd;
  wire [2:0] funct3;
  wire [4:0] rs1, rs2;
  wire [6:0] funct7;
  wire negative, overflow, zero;
  wire [3:0] sel;
  
  wire [2:0] OpType;
  
  wire RW, ALUSrc, MR, MW, MTR;
  
  wire [31:0] r1, r2;
  
  wire[31:0] instr;
  wire [31:0] imm;
  
  wire [31:0] pc_plus;
  assign pc_plus= iaddress + 4;
  
  reg b_ena;
    localparam R_type = 3'd0, I_type = 3'd1, LOAD_type = 3'd2, S_type = 3'd3, B_type  = 3'd4, J_type = 3'd5;
  
  assign branch_target = (opcode == 7'b1100111) ? ((r1 + imm) & ~32'b1): iaddress + imm;
  
  always@(*) begin
    if(opcode == 7'b1100011 && branch) begin
      case(funct3)
        3'h0: b_ena = (zero);
        3'h1: b_ena = (~zero);
        3'h4: b_ena = (negative != overflow);
        3'h5: b_ena = (negative == overflow);
        3'h6: b_ena = (r1 < r2);
        3'h7: b_ena = (r1 >= r2);
        default: b_ena = 0;
      endcase
    end
    else if(opcode == 7'b1101111 || opcode == 7'b1100111) begin
      b_ena = 1'b1;
    end
    else begin
      b_ena = 0;
    end
    
  end
  
  
  
  assign daddress = result;
  prog_counter my_counter (
    .clk(clk),
    .rst(rst),
    .b_ena(b_ena),
    .ce(1'b1),
    .branch_target(branch_target),
    .count(iaddress));
  
  inst_mem my_inst_mem(
    .addr(iaddress),
    .instr(instr));
  
  data_mem my_data_mem(
    .addr(daddress),
    .data(data),
    .MemRead(MR),
    .funct3(funct3),
    .MemWrite(MW),
    .clk(clk),
    .write_data(r2));

  
  inst_decoder my_decoder(
    .instr(instr), 
    .opcode(opcode),
    .rd(rd), 
    .funct3(funct3),
    .rs1(rs1), 
    .rs2(rs2), 
    .funct7(funct7),
    .imm(imm));
  
  
  control my_control(
    .opcode(opcode),
    .ALUOp(OpType),
    .MemRead(MR),
    .RegWrite(RW),
    .ALUSrc(ALUSrc),
    .MemWrite(MW),
    .MemToReg(MTR),
    .branch(branch));
  
  
  alu_control my_control_alu (
    .ALUOp(OpType), 
    .funct3(funct3),
    .funct7(funct7),
    .imm(imm),
    .sel(sel));
  
  reg_file my_reg(
    .clk(clk), 
    .we(RW),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_data(MTR ? data: (OpType == J_type || opcode == 7'b1100111)? pc_plus : result),
    .read1(r1),
    .read2(r2));
  
  alu my_alu(
    .a(r1),
    .b(ALUSrc ? imm:  r2),
    .sel(sel),
    .result(result),
    .overflow(overflow),
    .negative(negative),
    .zero(zero));
  
  
endmodule



module l_shift(
  input [31:0] a, 
  input [31:0] amount,
  output [31:0] result);
  assign result = a << amount[4:0];
endmodule

module r_shiftl(
  input [31:0] a,
  input[31:0] amount,
  output [31:0] result);
  assign result = a >> amount[4:0];
endmodule
    
module r_shifta(
  input [31:0] a,
  input [31:0] amount,
  output [31:0] result);

  assign result = $signed(a) >>> amount[4:0];
  endmodule    

module slt(
  input [31:0] a, b,
  output [31:0] result);

  assign result = ($signed(a) < $signed(b)) ? 32'd1: 32'd0;
endmodule

module sltu(
  input [31:0] a,b,
  output [31:0] result);

  assign result = (a < b) ? 32'd1: 32'd0;
endmodule


module ander (
  input [31:0] a, b,
  output [31:0] result);
  
  assign result = a & b;
endmodule

module orer (
  input [31:0] a, b,
  output [31:0] result);
  
  assign result = a | b;
endmodule

module xorer(
  input [31:0] a, b,
  output [31:0] result);
  
  assign result = a ^ b;
endmodule
 

module add(
  input[31:0] a, b,
  output [31:0] sum,
  output cout);
  
  wire[7:0] c_outs;
  
  genvar i;
  generate
    for(i = 0; i < 8; i = i + 1) begin : add_block
      if(i  == 0) begin
        cla_bloc cla1 (
          .a(a[3:0]), 
          .b(b[3:0]), 
          .cin(1'b0), 
          .cout(c_outs[0]), 
          .sum(sum[3:0]));
      end
      else begin
        cla_bloc cla_inst (
          .a(a[i*4 +:4]),
          .b(b[i*4 +: 4]),
          .cin(c_outs[i-1]),
          .cout(c_outs[i]),
          .sum(sum[i*4 +: 4]));
      end
    end
    assign cout = c_outs[7];
  endgenerate
        
  
endmodule

module sub(
  input [31:0] a, b,
  output [31:0] sum,
  output cout);
  
  wire[7:0] c_outs;
  
  genvar i;
  generate 
    for(i = 0; i < 8; i = i + 1) begin : sub_block
      if(i == 0) begin
        cla_bloc cla1 (
          .a(a[3:0]), 
          .b(~b[3:0]),
          .cin(1'b1),
          .sum(sum[3:0]),
          .cout(c_outs[0]));
      end else begin
        cla_bloc cla_inst (
          .a(a[i*4 +: 4]),
          .b(~b[i*4 +: 4]),
          .cin(c_outs[i - 1]),
          .sum(sum[i*4 +: 4]),
          .cout(c_outs[i]));
      end
    end
  endgenerate
  assign cout = c_outs[7];
endmodule


module cla_bloc(
  input [3:0] a, b,
  input cin,
  output [3:0] sum,
  output cout);
  
  wire [3:0] g, p,c;
  assign g = a&b;
  assign p = a ^b;
  
  assign c[0] = cin;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & g[0] ) | (p[1] & p[0] & c[0]);
  assign  c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
  assign cout = g[3] | (p[3] & c[3]);
  assign sum = p ^ c;
endmodule
