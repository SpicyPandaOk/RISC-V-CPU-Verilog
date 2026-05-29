import re


my_map = {
    'add' : (0b0110011, 0x0, 0x00),
    'sub' : (0b0110011, 0x0, 0x20),
    'xor' : (0b0110011, 0x4, 0x00),
    'or' : (0b0110011, 0x6, 0x00),
    'and' : (0b0110011, 0x7, 0x00),
    'sll' : (0b0110011, 0x1, 0x00),
    'srl' : (0b0110011, 0x5, 0x00),
    'sra' : (0b0110011, 0x5, 0x20),
    'slt' : (0b0110011, 0x2, 0x00),
    'sltu': (0b0110011, 0x3, 0x00),

    'addi': (0b0010011, 0x0, 0x00),
    'xori': (0b0010011, 0x4, 0x00),
    'ori': (0b0010011, 0x6, 0x00),
    'andi': (0b0010011, 0x7, 0x00),
    'slli': (0b0010011, 0x1, 0x00),
    'srli': (0b0010011, 0x5, 0x00),
    'srai': (0b0010011, 0x5, 0x20),
    'slti': (0b0010011, 0x2, 0x00),
    'sltiu': (0b0010011, 0x3,0x00),

    'lb' : (0b0000011, 0x0),
    'lh' : (0b0000011, 0x1),
    'lw' : (0b0000011, 0x2),
    'lbu': (0b0000011, 0x4),
    'lhu': (0b0000011, 0x5),

    'sb':(0b0100011, 0x0),
    'sh': (0b0100011, 0x1),
    'sw': (0b0100011, 0x2),

    'beq' : (0b1100011, 0x0),
    'bne' : (0b1100011, 0x1),
    'blt' : (0b1100011, 0x4),
    'bge' : (0b1100011, 0x5),
    'bltu': (0b1100011, 0x6),
    'bgeu': (0b1100011, 0x7),
    
    'jal': (0b1101111,),
    'jalr': (0b1100111, 0x0)

}
hexout = ""
with open('assembly.txt', 'r') as file:
    content = file.readlines()
    hexline = 0

    labels = {}
    count = 0
    for line in content:
        stripped = line.strip().split("#")[0]
        if stripped.endswith(':'):

            labels[stripped[:-1]] = count
        elif stripped and not stripped.startswith('#'):
            count += 4

    count = 0
    for index, line in enumerate(content):
        line = line.split("#")[0]
        tokens =  line.split(None, 1)
        
        valid_instr = True
        if len(tokens) == 1 and tokens[0].strip().endswith(':'):
            continue
        if len(tokens) == 2: #if has an instr and params
            try: 
                entry = my_map[tokens[0].strip()]
                opcode = (entry[0])

                if opcode != 0b0000011 and opcode != 0b0100011:
                    params = tokens[1].split(',')
                else:
                    params = [p.strip("x )\n") for p in re.split(r'[,(]', tokens[1])]
           
                    

            except KeyError:
                print("malformed instruction, key not in values")
                valid_instr = False
                continue

            if opcode == 0b0110011 and len(params) == 3: #for R type if has the right number params
                
                funct3 = entry[1]
                funct7 = entry[2]
                rd = int(params[0].strip("x "))
                rs1 = int(params[1].strip("x "))
                rs2 = int(params[2].strip("x "))


                intline =  funct7 << 25 |  rs2  << 20 | rs1 << 15 | funct3 << 12| rd << 7 | opcode
                

            elif opcode == 0b0110011:
                print(f"Invalid R type instruction in line {index}")
                valid_instr = False

            elif opcode == 0b0010011 and len(params) == 3: #I type

                funct3 = entry[1]
                rd = int(params[0].strip("x "))
                rs1 = int(params[1].strip("x "))

                if params[2].strip()[0] == '-':
                    immparam = int(params[2].strip()) & 0xFFF

                else:

                    immparam = int(params[2].strip())


                if funct3 == 0x1 or funct3 == 0x5:
                    if(immparam > 31):
                        print("immediate is too large for shift, will be truncated")

                    imm = entry[2] << 5 | immparam

                else:
                    imm = immparam
                
                intline = imm << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode


            elif opcode == 0b0010011:
                print(f"Invalid I type instruction in line {index}")
                valid_instr = False
            
            elif opcode == 0b0000011 and len(params) == 3: #loads
                
                funct3 = entry[1]
                rd = int(params[0])
                rs1 = int(params[2])
                imm = int(params[1]) & 0xFFF

                intline = imm << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode

            elif opcode == 0b0000011:
                print(f"invalid Load instruction in line {index}")
                valid_instr = False 

            elif opcode == 0b0100011 and len(params) == 3: #saves

                funct3 = entry[1]
                rs2 = int(params[0])
                rs1 = int(params[2])
                imm = int(params[1]) & 0xFFF

                intline =  ((imm >> 5) & 0x7F) << 25 | rs2 << 20 |  rs1 << 15 | funct3 << 12 | (imm & 0x1F) << 7  | opcode

            elif opcode == 0b0100011:
                print(f"invalid save instruction in line {index}")
                valid_instr = False

            elif opcode == 0b1100011 and len(params) == 3: #branch

                funct3 = entry[1]
                rs1 = int(params[0].strip("x "))
                rs2 = int(params[1].strip("x "))
                try:
                    imm = int(params[2]) & 0x1FFF
                except ValueError:
                    imm = (labels[params[2].strip()] - count) & 0x1FFF

                intline = (imm >> 12) << 31| ((imm >> 5) & 0x3F)  << 25 | rs2 << 20 | rs1 << 15 | funct3 << 12 |  ((imm >> 1) & 0xF) << 8 | ((imm >> 11) & 0x1) << 7 | opcode  

            elif opcode == 0b1100011:
                print(f"invalid Branch instruction in line {index}")
                valid_instr = False

            elif opcode == 0b1101111 and len(params) == 2:

                rd = int(params[0].strip("x "))
                try:
                    imm = int(params[1]) & 0x1FFFFF
                except ValueError:
                    imm = (labels[params[1].strip()] - count) & 0x1FFFFF

                intline = (imm >> 20) << 31 | ((imm >> 1) & 0x3FF) << 21 | ((imm >> 11) & 0x1) << 20 | ((imm >> 12) & 0xFF) << 12 | rd << 7 | opcode

            elif opcode == 0b1101111:
                print(f"invalid jump instruction on line {index}")
                valid_instr = False


            if valid_instr:
                hexline = hex(intline)[2:]

                while(len(hexline) < 8):
                    hexline = "0" + hexline

                hexout += hexline + '\n'   
                count += 4
            else:
                continue    
            
            
        elif not line.strip():
            continue
        else:
            print(f"invalid instruction format, needs param or operation in line {index}")

with open('instmem.hex', 'w') as file:
    file.write((hexout))

            