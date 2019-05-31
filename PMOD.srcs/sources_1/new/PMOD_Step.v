`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ed Nutting 
// 
// Create Date: 30.05.2019 15:12:07
// Design Name: PMOD demo
// Module Name: PMOD_Step
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


module PMOD_Step (
    input CLK,
    input RST_N,

    input DIR, // Direction : 1 = Forwards, 0 = Backwards
    input ENB, // Enable (active high)
    
    output stepped, // Active-high for one clock cycle when motors steps
    
    output SIG1,
    output SIG2,
    output SIG3,
    output SIG4
    );

    // Set frequency of clock divider to whatever your motors can handle
    ClockDivider #(
        .TARGET_CLOCK_FREQ (1000) // E.g. 120 = 120Hz
        ) 
        step_clk_div (
        .CLK        (CLK),
        .RST_N      (RST_N),
        .CLK_Out    (CLK_low)
        );
        
    reg[3:0] signal;
    
    assign SIG1 = signal[0];
    assign SIG2 = signal[1];
    assign SIG3 = signal[2];
    assign SIG4 = signal[3];

    localparam st1 = 3'b000;
    localparam st2 = 3'b001;
    localparam st3 = 3'b011;
    localparam st4 = 3'b010;
    localparam st5 = 3'b110;
    localparam st6 = 3'b111;
    localparam st7 = 3'b101;
    localparam st8 = 3'b100;
    
    reg CLK_low_prev;
    always @(posedge CLK) begin
        CLK_low_prev <= CLK_low;
    end
    
    assign stepped = (CLK_low != CLK_low_prev) && ENB;
    
    reg [2:0] present_state, next_state;
    
    always @(present_state, DIR, ENB)
    begin
        if (ENB) begin
            case(present_state)
                st1: next_state = DIR ? st2 : st8;
                st2: next_state = DIR ? st3 : st1;
                st3: next_state = DIR ? st4 : st2;
                st4: next_state = DIR ? st5 : st3;
                st5: next_state = DIR ? st6 : st4;
                st6: next_state = DIR ? st7 : st5;
                st7: next_state = DIR ? st8 : st6;
                st8: next_state = DIR ? st1 : st7;
            endcase
        end
        else begin
            next_state = present_state;
        end
    end

    always @(posedge CLK_low)
    begin
        if (!RST_N) begin
            present_state = st1;
        end
        else begin 
            present_state = next_state;
        end
    end

    always @(posedge CLK_low)
    begin
        case (present_state)
            st1: signal <= 4'b1000;
            st2: signal <= 4'b1100;
            st3: signal <= 4'b0100;
            st4: signal <= 4'b0110;
            st5: signal <= 4'b0010;
            st6: signal <= 4'b0011;
            st7: signal <= 4'b0001;
            st8: signal <= 4'b1001;
        endcase
    end
    
endmodule
