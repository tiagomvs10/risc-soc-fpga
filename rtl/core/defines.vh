`define W    16  //register width
`define N    15  //register MSB
`define AN   15  //address MSB
`define IN   15  //instruction MSB

//opcode Definitions
`define JAL      (op==0)
`define ADDI     (op==1)
`define RR       (op==2)
`define RI       (op==3)
`define LW       (op==4)
`define LB       (op==5)
`define SW       (op==6)
`define SB       (op==7)
`define IMM      (op==8)
`define Bx       (op==9)
`define ALU      (`RR|`RI)
`define RETI     (op=='hA)

//function Definitions
`define ADD      (fn==0)
`define SUB      (fn==1)
`define AND      (fn==2)
`define XOR      (fn==3)
`define ADC      (fn==4)
`define SBC      (fn==5)
`define CMP      (fn==6)
`define SRL      (fn==7)
`define SRA      (fn==8)
`define SUM      (`ADD|`SUB|`ADC|`SBC)
`define LOG      (`AND|`XOR)
`define SR       (`SRL|`SRA)

//branch Conditions
`define BR       0
`define BEQ      2
`define BC       4
`define BV       6
`define BLT      8
`define BLE      'hA
`define BLTU     'hC
`define BLEU     'hE

//on-chip peripheral bus defines
`define IO       //on-chip periphs enabled
`define CN   31  //ctrl bus MSB
`define CRAN 7   //control reg addr MSB
`define DN   15  //data bus MSB
`define SELN 7   //select bus MSB
 