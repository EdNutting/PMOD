`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ed Nutting 
// 
// Create Date: 30.05.2019 15:12:07
// Design Name: PMOD demo
// Module Name: ClockDivider
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

module ClockDivider #(
    parameter TARGET_CLOCK_FREQ = 10, // 10Hz
    parameter SOUREC_CLK_FREQ = 100000000 // 100MHz
    ) (
    input CLK,
    input RST_N,
    output reg CLK_Out
    );
    localparam COUNTS_PER_CLOCK = SOUREC_CLK_FREQ / (2 * TARGET_CLOCK_FREQ);

    reg [31:0] count;
    
    always @ (posedge CLK) begin
        if (!RST_N) begin 
            count <= 0;
            CLK_Out <= 0;
        end
        else if (count == COUNTS_PER_CLOCK) begin
            count <= 0;
            CLK_Out <= ~CLK_Out;
        end        
        else begin
            count <= count + 1;
        end
    end

endmodule
