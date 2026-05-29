# RISC-V-CPU-Verilog

## Overview
single cycle 32RVI cpu, constructed from scratch in EDA playground along with a test bench and assembler for instructions. 

## Architecture
includes: ALU, instruction decoder, 32 registers, program counter, instruction memory, data memory, control center, ALU control, and a main CPU module to connect together
connection: PC -> inst_mem -> inst_decoder ->control + ALU control -> reg_file -> ALU -> data_mem -> writeback

## Supported Instructions
|R type | I type | S type | B type | J type  |
|------|---------|--------|--------|---------|
|ADD| ADDI | SB|BEQ| JAL|
| SUB | XORI| SH| BNE|
| XOR | ORI | SW|BLT|
| OR  | ANDI| BGE|
| AND | SLLI |BLTU|
| SLL | SRLI |BGEU|
|SRL | SRAI |
| SRA | SLTI |
|SLT | SLTIU |
| SLTU | LB|
||LH|
||LW|
||LBU|
||LHU|
||JALR|



## File Structure
cpu.v: top level verilog module with all submodules within
cpu_tb.v: testbench for testing the cpu
assembler.py: custom built python assembler to turn instructions into hex
assembly.txt: input assembly code for instructions
instmem.hex: assembled output, read into instruction memory

## Getting Started
### Assembling
python assembler.py # reads assembly.txt and writes to instmem.hex

### Simulating
#### e.g. using Icarus Verilog:
iverilog -o cpu_sim cpu.v cpu_tb.v && cpu_sim
#### via EDA Playground

## Assembler usage
syntax: {lower case instruction} registers in the form x1, x2 etc, immediates as a number or for jumps and branches they may be targets to a label
labels: use format "{label name}:" with no other information in the line
for load and save instructions follows the "lw x1, 0(x2)" syntax
currently no pseudos can be used, and max of 256 instructions

## Testing
test bench runs through each type of operation and verifies the correct result
made to run with the program:
|asembly|hex|
|-------|---|
addi x1, x0, 10  |00a00093 |
addi x2, x0, 20 |01400113 |
add x3, x2, x1 |001101b3 |
addi x4,x3, 20 |01418213 |
sw x4, 2(x1) |0040a123 |
lw x5, 2(x1) |0020a283 |
beq x4, x5, 8 |00520463 | 
add x0, x0, x0 |00000033 |
jal x6, 12 |00c0036f |


## Tools used
mostly verilog with a few system verilog pieces of syntax, python 3, EDA Playground with Icarus Verilog 12.0
