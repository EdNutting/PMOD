`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.06.2019 19:41:22
// Design Name: 
// Module Name: top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_tb();

    reg CLK;
    reg BTNC, BTND, BTNU;
    
    wire JA3, JA4, JA9, JA10;
    
    pullup(JA3);
    pullup(JA4);
    pullup(JA9);
    pullup(JA10);
    
    initial begin
        CLK = 0;
        BTNC = 1;
        #10;
        #10;
        BTNC = 0;
        BTNU = 0;
        #40;
        BTNU = 1;
        #20;
        BTNU = 0;
        #100000;
        $stop();
    end
    
    always begin
        #5 CLK = ~CLK;
    end
    
    top dut (
        .GCLK(CLK), // Clock
        .BTNC(BTNC), // Button center (reset all when pressed)
        .BTND(BTND), // Button down   (change LED 3 blink speed)
        .BTNU(BTNU), // Buttown up    (transmit fixed text)
    
        .LD0(LD0), // LED 0
        .LD1(LD1), // LED 1
        .LD2(LD2), // LED 2
        .LD3(LD3), // LED 3
        .LD4(LD4), // LED 4
        .LD5(LD5), // LED 5
        .LD6(LD6), // LED 6
        .LD7(LD7), // LED 7
        
        // PMOD Port A (JA1-JA12) (PMOD RTCC)
        
        .JA2(JA2),   // Return input of MFI pin
        .JA3(JA3),   // SCL (1)
        .JA4(JA4),   // SDA (1)
        .JA9(JA9),   // SCL (2)
        .JA10(JA10),   // SDA (2)
    
        // PMOD Port B (JB1-JB12) (PMOD BT2)
        .JB1(JB1),  // RTS
        .JB2(JB2),  // RXD
        .JB3(JB3),  // TXD
        .JB4(JB4),  // CTS
        .JB7(JB7),  // Connection status
        .JB8(JB8),  // Reset
        .JB9(JB9),  // Not connected
        .JB10(JB10), // Not connected
        
        // PMOD Port C (JC1-JC12) (PMOD Step)
        .JC1_N(JC1_N), // SIG1 - Secondary motor
        .JC1_P(JC1_P), // SIG2 - Secondary motor
        .JC2_N(JC2_N), // SIG3 - Secondary motor
        .JC2_P(JC2_P), // SIG4 - Secondary motor
        .JC3_N(JC3_N), // SIG5 - Primary motor
        .JC3_P(JC3_P), // SIG6 - Primary motor
        .JC4_N(JC4_N), // SIG7 - Primary motor
        .JC4_P(JC4_P)  // SIG8 - Primary motor
        );

endmodule
