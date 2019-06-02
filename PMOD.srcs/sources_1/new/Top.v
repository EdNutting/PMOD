`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ed Nutting 
// 
// Create Date: 30.05.2019 15:12:07
// Design Name: PMOD demo
// Module Name: top
// Project Name: PMOD
// Target Devices: Zedboard (Zynq 7020)
// Tool Versions: Vivado 2016.1
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// Licensed under MIT license - refer to LICENSE file.
// 
//////////////////////////////////////////////////////////////////////////////////

module top(
    input GCLK, // Clock
    input BTNC, // Button center (reset all when pressed)
    input BTND, // Button down   (change LED 3 blink speed)
    input BTNU, // Buttown up    (transmit fixed text)

    output LD0, // LED 0
    output LD1, // LED 1
    output LD2, // LED 2
    output LD3, // LED 3
    output LD4, // LED 4
    output LD5, // LED 5
    output LD6, // LED 6
    output LD7, // LED 7
    
    // PMOD Port A (JA1-JA12) (PMOD RTCC)
    
    input JA2,   // Return input of MFI pin
    inout JA3,   // SCL (1)
    inout JA4,   // SDA (1)
    inout JA9,   // SCL (2)
    inout JA10,  // SDA (2)

    // PMOD Port B (JB1-JB12) (PMOD BT2)
    input  JB1,  // RTS
    output JB2,  // RXD
    input  JB3,  // TXD
    output JB4,  // CTS
    input  JB7,  // Connection status
    output JB8,  // Reset
    input  JB9,  // Not connected
    input  JB10, // Not connected
    
    // PMOD Port C (JC1-JC12) (PMOD Step)
    output JC1_N, // SIG1 - Secondary motor
    output JC1_P, // SIG2 - Secondary motor
    output JC2_N, // SIG3 - Secondary motor
    output JC2_P, // SIG4 - Secondary motor
    output JC3_N, // SIG5 - Primary motor
    output JC3_P, // SIG6 - Primary motor
    output JC4_N, // SIG7 - Primary motor
    output JC4_P  // SIG8 - Primary motor
    );
    
    // See constraints file - global clock should be from Y9 package pin @ 100MHz
    wire CLK = GCLK;

    // Reset-low signal - reset when button is pressed
    wire RST_N = !BTNC;
    
    // De-bounced switches
    //  Useful for debugging - use to control `bt2.RST` and `bt2.received`
    //      Note: When debugging, remember to isolate BT2_RST_N from the BT2 module using: 
    //                assign BT2_RST_N = RST_N;
    //            And changing BT2_RST_N to BT2_RST_N_Unused in bt2 declaration.

    DeBounce BTND_debounce (
        .clk(CLK),
        .n_reset(RST_N),
        .button_in(BTND),
        .DB_out(BTND_pressed)
        );

    reg BTND_pressed_prev;
    always @(posedge CLK) begin
        BTND_pressed_prev <= BTND_pressed;
    end
    
    DeBounce BTNU_debounce (
        .clk(CLK),
        .n_reset(RST_N),
        .button_in(BTNU),
        .DB_out(BTNU_pressed)
        );

    reg BTNU_pressed_prev;
    always @(posedge CLK) begin
        BTNU_pressed_prev <= BTNU_pressed;
    end
    
    // PMOD BT2 - Bluetooth connection
    
    // BT2 input signals
    assign BT2_RTS = JB1;
    assign BT2_TXD = JB3;
    assign BT2_STS = JB7;

    // BT2 indicator LEDs
    assign LD0 = BT2_STS;
    // LEDs for debug
    /*
    assign LD1 = BT2_RXD;
    assign LD2 = BT2_TXD;
    assign LD3 = BT2_RTS;
    assign LD4 = BT2_CTS;
    assign LD5 = BT2_receive;
    assign LD6 = BT2_sent;
    */

    // BT2 outputs
    assign JB2 = BT2_RXD;
    assign JB4 = BT2_CTS;
    assign JB8 = BT2_RST_N;

    wire [7:0] BT2_char_out;
    wire [7:0] BT2_char_in;

    // BT2 module
    PMOD_BT2 bt2 (
        .CLK        (CLK),
        .RST_N      (RST_N),

        .RTS        (BT2_RTS),
        .RXD        (BT2_RXD),
        .TXD        (BT2_TXD),
        .CTS        (BT2_CTS),
        .STS        (BT2_STS),
        .RST_N_Out  (BT2_RST_N),
        
        .char_in    (BT2_char_in),
        .char_out   (BT2_char_out),
        .send       (BT2_send),
        .sent       (BT2_sent),
        .receive    (BT2_receive),
        .received   (BT2_received)
        );
        
    // Configure BT2 as an echo device
    assign BT2_char_in = BT2_char_out;
    assign BT2_send = BT2_receive && !BT2_sent;
    assign BT2_received = BT2_sent;
    
    reg BT2_receive_prev;
    always @(posedge CLK) begin
        BT2_receive_prev <= BT2_receive;
    end
    
    // PMOD Step - Stepper motor drivers
    // Commands F, B, L, R, and S (stop) accepted from Bluetooth
    //  Cause 1 full revolution of motors then stop.
    //  Commands can be interrupted by subsequent ones.

    wire step_dirL, step_dirR;
    wire step_enbL, step_enbR;
    wire step_steppedL, step_steppedR;

    StepMotorInterface #(
        .SIDE (1'b1)
        ) stepMotorIntfL (
        .CLK        (CLK),
        .RST_N      (RST_N),
        .char_vld   (BT2_receive),
        .char       (BT2_char_out),
        .enb        (step_enbL),
        .dir        (step_dirL),
        .stepped    (step_steppedL)
        );

    StepMotorInterface #(
        .SIDE (1'b0)
        ) stepMotorIntfR (
        .CLK        (CLK),
        .RST_N      (RST_N),
        .char_vld   (BT2_receive),
        .char       (BT2_char_out),
        .enb        (step_enbR),
        .dir        (step_dirR),
        .stepped    (step_steppedR)
        );

    PMOD_Step stepLeft (
        .CLK    (CLK),
        .RST_N  (RST_N),

        .DIR    (step_dirL),
        .ENB    (step_enbL),
        
        .stepped (step_steppedL),

        .SIG1   (JC3_N),
        .SIG2   (JC3_P),
        .SIG3   (JC4_N),
        .SIG4   (JC4_P)
        );

    PMOD_Step stepRight (
        .CLK    (CLK),
        .RST_N  (RST_N),

        .DIR    (step_dirR),
        .ENB    (step_enbR),
        
        .stepped (step_steppedR),

        .SIG1   (JC1_N),
        .SIG2   (JC1_P),
        .SIG3   (JC2_N),
        .SIG4   (JC2_P)
        );


    // PMOD RTCC - PMOD Real-time Clock/Calendar
    
    reg rtcc_mfiState;
    wire triggerMFIToggle =  (BT2_receive && (BT2_receive != BT2_receive_prev) && BT2_char_out == "T")
                          || (BTNU_pressed && !BTNU_pressed_prev);
    
    assign LD6 = rtcc_mfiState;
    assign LD7 = JA2;
        
    always @(posedge CLK) begin
        if (!RST_N) begin
            rtcc_mfiState <= 0;
        end
        else begin
            if (triggerMFIToggle) begin
                rtcc_mfiState <= !rtcc_mfiState;
            end
        end
    end
    
    PMOD_RTCC rtcc (
        .CLK    (CLK),
        .RST_N  (RST_N),
        
        .mfiState (rtcc_mfiState),
        .setmfi_busy (LD4),
        .clearmfi_busy (LD5),
        
        .SCL_1    (JA3),
        .SDA_1    (JA4),
        .SCL_2    (JA9),
        .SDA_2    (JA10)
        );

endmodule
