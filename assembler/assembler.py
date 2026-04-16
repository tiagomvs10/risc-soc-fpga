import sys
import re
import os

#------------------------------------------------------------------------------
#   instruction set definition
#------------------------------------------------------------------------------
OPCODES = {
    'jal': 0x0, 'addi': 0x1,
    'add': 0x2, 'sub': 0x2, 'and': 0x2, 'xor': 0x2, 'adc': 0x2, 'sbc': 0x2, 'cmp': 0x2, 'srl': 0x2, 'sra': 0x2,
    'rsubi': 0x3, 'adci': 0x3, 'rsbci': 0x3, 'andi': 0x3, 'xori': 0x3, 'rcmpi': 0x3,
    'lw': 0x4, 'lb': 0x5, 'sw': 0x6, 'sb': 0x7,
    'imm': 0x8,
    'br': 0x9, 'beq': 0x9, 'bne': 0x9, 'bc': 0x9, 'bnc': 0x9, 'bv': 0x9, 'bnv': 0x9,
    'blt': 0x9, 'bge': 0x9, 'ble': 0x9, 'bgt': 0x9, 'bltu': 0x9, 'bgeu': 0x9, 'bleu': 0x9, 'bgtu': 0x9,
    'reti': 0xA  
}

ALU_FN = {
    'add': 0x0, 'sub': 0x1, 'and': 0x2, 'xor': 0x3, 'adc': 0x4, 'sbc': 0x5, 'cmp': 0x6, 'srl': 0x7, 'sra': 0x8,
    'rsubi': 0x1, 'adci': 0x4, 'rsbci': 0x5, 'andi': 0x2, 'xori': 0x3, 'rcmpi': 0x6
}

BRANCH_COND = {
    'br': 0x0, 'beq': 0x2, 'bne': 0x3, 'bc': 0x4, 'bnc': 0x5, 'bv': 0x6, 'bnv': 0x7,
    'blt': 0x8, 'bge': 0x9, 'ble': 0xA, 'bgt': 0xB, 'bltu': 0xC, 'bgeu': 0xD, 'bleu': 0xE, 'bgtu': 0xF 
}

#------------------------------------------------------------------------------
#   parser
#------------------------------------------------------------------------------
def parse_reg(s): return int(s.lower().strip()[1:])
def parse_imm(s): 
    s = s.strip()
    if s.lower().startswith('0x') or "16'h" in s: return int(s.replace("16'h", "0x"), 16)
    elif s.lower().startswith('0b'): return int(s, 2)
    return int(s)

def assemble_line(line, current_index, labels):
    parts = re.split(r'\s+', line, 1)
    mnem = parts[0].lower()
    args = [x.strip() for x in re.split(r',|\(|\)', parts[1])] if len(parts) > 1 else []
    
    op = OPCODES[mnem]
    
    if mnem == 'jal': return (op<<12) | (parse_reg(args[0])<<8) | (parse_reg(args[2])<<4) | (parse_imm(args[1])&0xF)
    if mnem == 'addi': return (op<<12) | (parse_reg(args[0])<<8) | (parse_reg(args[1])<<4) | (parse_imm(args[2])&0xF)
    if mnem in ['lw', 'sw', 'lb', 'sb']: return (op<<12) | (parse_reg(args[0])<<8) | (parse_reg(args[2])<<4) | (parse_imm(args[1])&0xF)
    if mnem in ALU_FN and op==2: return (op<<12) | (parse_reg(args[0])<<8) | (parse_reg(args[1])<<4) | (ALU_FN[mnem]&0xF)
    if mnem in ALU_FN and op==3: return (op<<12) | (parse_reg(args[0])<<8) | (ALU_FN[mnem]<<4) | (parse_imm(args[1])&0xF)
    if mnem == 'imm': return (op<<12) | (parse_imm(args[0])&0xFFF)

    if mnem == 'reti':
        reg_val = 0
        if len(args) > 0:
            reg_val = parse_reg(args[0])
            if reg_val != 0:
                print(f"Line {current_index*2:04X}]: 'reti' must use r0")
        return (op << 12) | (reg_val << 8) #returns 0xA000
    
    if mnem in BRANCH_COND:
        tgt = args[0]
        if tgt in labels:
            disp = labels[tgt] - current_index
        else:
            disp = parse_imm(tgt)
        return (op<<12) | (BRANCH_COND[mnem]<<8) | (disp&0xFF)
    return 0

def main():

    input_file = '/home/tiago/Desktop/assembler/codigo.asm'
    output_path = '/home/tiago/Desktop/processador/project_1/project_1.srcs/sources_1/ip/'
    
    try:
        with open(input_file, 'r') as f: lines = f.readlines()
    except:
        print("Error: codigo.asm not found")
        return

    labels = {}
    word_index = 0
    instruction_map = {} 

    # 1-symbol table
    for line in lines:
        line = line.split('//')[0].strip()
        if not line: continue
        if line.startswith('.org'):
            addr_val = parse_imm(line.split()[1])
            word_index = addr_val // 2 
            print(f"--> .org 0x{addr_val:X} (CPU) -> RAM Index {word_index}")
            continue
        if line.endswith(':'):
            labels[line[:-1]] = word_index
        else:
            instruction_map[word_index] = line
            word_index += 1
            
    max_index = word_index
    coe_data = []

    # 2-assembly
    for i in range(max_index):
        if i in instruction_map:
            try:
                hex_val = assemble_line(instruction_map[i], i, labels)
                coe_data.append(hex_val)
                print(f"[PC {i*2:04X}] {instruction_map[i]:<25} -> {hex_val:04X}")
            except Exception as e:
                print(f"Error line '{instruction_map[i]}': {e}")
                return
        else:
            coe_data.append(0x1000) 

    if not os.path.exists(output_path): output_path = "."

    with open(os.path.join(output_path, 'ramh.coe'), 'w') as fh, \
         open(os.path.join(output_path, 'raml.coe'), 'w') as fl:
        header = "memory_initialization_radix=16;\nmemory_initialization_vector=\n"
        fh.write(header); fl.write(header)
        for i, word in enumerate(coe_data):
            sep = ",\n" if i < len(coe_data)-1 else ";\n"
            fh.write(f"{(word>>8)&0xFF:02X}{sep}")
            fl.write(f"{word&0xFF:02X}{sep}")

    print("\nramh.coe and raml.coe generated")


if __name__ == "__main__":
    main()




    