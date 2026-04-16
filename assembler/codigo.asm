.org 0x000C
timer_vector:
    br timer_handler

.org 0x0010
gpio_vector:
    br pario_handler

.org 0x0014
uart_vector:
    br uart_handler

.org 0x0020
main:

    //setup baudrate divisor (0x1458)
    imm 0x145        
    addi r2, r1, 8  
    imm 0x830
    addi r3, r1, 2  
    sw r2, 0(r3)    // baudrate register 0x8302 = 0x1458

    //setup uart control (rx=1, en=1) -> 3
    addi r2, r1, 3  
    imm 0x830
    addi r3, r1, 0  
    sw r2, 0(r3)    //control register 0x8300 = 3

    // timer+pario+uart = 4+2+1 = 7
    imm 0x820
    addi r2, r1, 2  
    addi r3, r1, 7  
    sw r3, 0(r2)    //interrupt enable register 0x8202 = 7

loop:
    br loop

uart_handler:
    xor r1, r1
    imm 0x830
    addi r1, r1, 0  // r1 = 0x8300

    //echo: read -> write
    lw r2, 4(r1)    
    sw r2, 4(r1)    
    
    //start tx (keep rx enabled) -> 7 (111b)
    xor r3, r3
    addi r3, r3, 7  
    sw r3, 0(r1)    //start TX

    //clear pic (uart irq = bit 2 -> 4)
    xor r1, r1
    imm 0x820
    addi r1, r1, 0  
    xor r2, r2
    addi r2, r2, 4  
    sw r2, 0(r1)

    reti r0

pario_handler:
    xor r1, r1
    imm 0x810
    addi r1, r1, 0  //r1 = 0x8100
    
    xori r15, 4      //toggle led2
    sw r15, 0(r1)

    //clear pic (gpio irq = bit 1 -> 2)
    xor r1, r1
    imm 0x820
    addi r1, r1, 0  
    xor r2, r2
    addi r2, r2, 2  
    sw r2, 0(r1)

    reti r0

timer_handler:
    addi r9, r9, 1 //increment counter
    
    //(counter == 500) ?
    xor r1, r1
    imm 0x01F
    addi r1, r1, 4  
    cmp r9, r1
    bne clear_timerInt //false

    //true
    xor r9, r9      
    xor r1, r1
    imm 0x810
    addi r1, r1, 0  // r1 = 0x8100
    xori r15, 1      //toggle led0
    sw r15, 0(r1)

clear_timerInt:
    //clear interrupt request
    xor r1, r1
    imm 0x800
    addi r1, r1, 2  
    xor r2, r2      
    sw r2, 0(r1)    // Escreve 0 em 0x8002

    //clear pic (timer irq = bit 0 -> 1)
    xor r1, r1
    imm 0x820
    addi r1, r1, 0  
    xor r2, r2
    addi r2, r2, 1  
    sw r2, 0(r1)

    reti r0