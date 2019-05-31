`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ed Nutting 
// 
// Create Date: 30.05.2019 15:12:07
// Design Name: PMOD demo
// Module Name: PMOD_BT2
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

module PMOD_BT2 (
    input CLK,              // Clock - see also CLKS_PER_BAUD
    input RST_N,            // Active-low reset
    
    input  RTS,             // BT2 Ready-To-Send (Pin 1) 
    output reg RXD,         // BT2 RXD (Pin 2)
    input  TXD,             // BT2 TXD (Pin 3)
    output reg CTS,         // BT2 CTS (Pin 4)
    input  STS,             // BT2 Connection status (Pin 7)
    output wire RST_N_Out,  // BT2 Reset (active low) (Pin 8)
    
    input [7:0] char_in,        // Character (/byte) to send
    output reg [7:0] char_out,  // Character (/byte) received
    input send,                 // Active-high. Set to send. Keep high until 'sent' set.
    output reg sent,            // Active-high. Pulses for 1 clock cycle when 'char_in' finished sending.
    output reg receive,         // Active-high. Set while char_out valid when a byte is received.
    input received              // Active-high. Set for 1 clock cycle to clear 'receive' and being accepting next character.
    );
    
    parameter BAUD = 115200;
    parameter CLK_FREQ = 100000000; // 100MHz
    localparam CLKS_PER_BAUD = CLK_FREQ / BAUD;
    
    localparam [1:0] STATE_IDLE = 0;
    localparam [1:0] STATE_START = 1;
    localparam [1:0] STATE_BIT = 2;
    localparam [1:0] STATE_STOP = 3;

    assign RST_N_Out = RST_N;
    
    reg [1:0] send_state;
    reg [2:0] send_bitnum;
    reg [31:0] send_count;
    
    reg [1:0] receive_state;
    reg [2:0] receive_bitnum;
    reg [31:0] receive_count;
    
    // Double buffer as a low-quality but good-enough way to cross clock domains
    //  Solves frequent metastability issue when receiving characters
    reg TXD_buf1;
    reg TXD_buf2;
    always @(posedge CLK) begin
        TXD_buf1 <= TXD;
        TXD_buf2 <= TXD_buf1;
    end
    
    // Trigger 'sent' signal
    always @(posedge CLK) begin
        if (send) begin
            if (send_state == STATE_STOP && send_count == 0) begin
                sent <= 1;
            end
        end
        else begin
            sent <= 0;
        end
    end
    
    // Ready to start sending when signalled to and BT2 is ready
    // Note: RTS active low for BT2
    wire start_send = send && !sent && !RTS;
    
    // Send timing/state control
    always @(posedge CLK) begin
        if (!RST_N) begin
            send_state <= STATE_START;
            send_bitnum <= 0;
            send_count <= 0;
        end
        // Wait (approx.) duration of a bit in the BT2's clock domain
        else if (send_count == 0) begin
            case (send_state)
                // Shouldn't end up here but anyway...
                STATE_IDLE: begin
                    send_state <= STATE_START;
                end
                
                // Send the start bit
                STATE_START: begin
                    if (start_send) begin
                        send_state <= STATE_BIT;
                        send_bitnum <= 0;
                        send_count <= CLKS_PER_BAUD;
                    end
                    else begin
                        send_state <= STATE_START;
                        send_bitnum <= 0;
                        send_count <= 0;
                    end
                end

                // Send the 8 data bits
                STATE_BIT: begin
                    if (send_bitnum < 7) begin
                        send_bitnum <= send_bitnum + 1;
                    end
                    else begin
                        send_bitnum <= 0;
                        send_state <= STATE_STOP;
                    end
                    send_count <= CLKS_PER_BAUD;
                end
                
                // Send the stop bit
                STATE_STOP: begin
                    send_state <= STATE_START;
                    send_count <= CLKS_PER_BAUD;
                end
            endcase
        end
        else if (send_count > 0) begin
            send_count <= send_count - 1;
        end
    end
    
    // Data line control
    always @(posedge CLK) begin
        if (!RST_N) begin
            // 0 = Start bit, so drive high to avoid data transmission
            RXD <= 1;
        end
        else begin
            // Wait (approx.) duration of a bit in the BT2's clock domain
            if (send_count == 0) begin
                case (send_state)
                    // Send the start bit
                    STATE_START: begin
                        if (start_send) begin
                            RXD <= 0;
                        end
                        else begin
                            RXD <= 1;
                        end
                    end

                    // Send a data bit
                    STATE_BIT: begin
                        RXD <= char_in[send_bitnum];
                    end
                    
                    // Send the stop bit
                    STATE_STOP: begin
                        RXD <= 1;
                    end
                endcase
            end
        end
    end
    
    // Ready to start receiving when the BT2 sends the start bit and any previous byte has been processed
    wire start_receive = TXD_buf2 == 0 && !receive && !received;

    // Receiving timing/state control
    always @(posedge CLK) begin
        if (!RST_N) begin
            receive_state <= STATE_START;
            receive_bitnum <= 0;
            receive_count <= 0;
        end
        // Wait (approx.) duration of a bit in the BT2's clock domain
        else if (receive_count == 0) begin
            case (receive_state)
                // Shouldn't end up here but anyway...
                STATE_IDLE: begin
                    receive_state <= STATE_START;
                end
                
                // Wait for and receive the start bit
                STATE_START: begin
                    if (start_receive) begin
                        receive_bitnum <= 0;
                        receive_count <= CLKS_PER_BAUD + (CLKS_PER_BAUD / 3);
                        receive_state <= STATE_BIT;
                    end
                end

                // Receive data bits
                STATE_BIT: begin
                    if (receive_bitnum < 7) begin
                        receive_bitnum <= receive_bitnum + 1;
                    end
                    else begin
                        receive_bitnum <= 0;
                        receive_state <= STATE_STOP;
                    end

                    receive_count <= CLKS_PER_BAUD;
                end

                // Receive stop bit
                //  Then wait a bit of extra time before returning to START
                //  This ensures CTS goes low after the stop bit has finished transmitting
                STATE_STOP: begin
                    receive_state <= STATE_START;
                    receive_count <= 3 * (CLKS_PER_BAUD / 4);
                end
            endcase
        end
        else if (receive_count > 0) begin
            receive_count <= receive_count - 1;
        end
    end
    
    // Data line input
    always @(posedge CLK) begin
        if (!RST_N) begin
            char_out <= 0;
        end
        // Wait (approx.) duration of a bit in the BT2's clock domain
        else if (receive_count == 0) begin
            case (receive_state)
                // Receive the start bit
                STATE_START: begin
                    if (start_receive) begin
                        char_out <= 0;
                    end
                end

                // Receive a data bit
                STATE_BIT: begin            
                    char_out[receive_bitnum] <= TXD_buf2;
                end
                
                // Stop bit is handled below
            endcase
        end
    end
    
    always @(posedge CLK) begin
        if (!RST_N) begin
            receive <= 0;
        end
        else begin
            // If supposed to be receiving stop bit
            if (receive_state == STATE_STOP && receive_count == 0) begin
                // Check for stop bit
                if (TXD_buf2) begin
                    // Successful byte receive
                    receive <= 1;
                end
                else begin
                    // Fail. Wasn't a proper byte.
                    receive <= 0;
                end
            end
            // Wait for `received` to indicate safe to receive next char
            else if (receive) begin
                if (received) begin
                    receive <= 0;
                end
            end
        end
    end

    // Clear-To-Send control
    // Note: CTS active low for BT2
    always @(posedge CLK) begin
        if (!RST_N) begin
            // Never clear to send while being reset as we can't receive anything 
            CTS <= 1;
        end
        else begin
            // CTS when finished fully receiving/accepting previous byte
            CTS <= receive_state != STATE_START || receive_count > 0 || receive || received;
        end
    end
    
endmodule
