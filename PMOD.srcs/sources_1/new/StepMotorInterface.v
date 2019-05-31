`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ed Nutting 
// 
// Create Date: 30.05.2019 15:12:07
// Design Name: PMOD demo
// Module Name: StepMotorInterface
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


module StepMotorInterface #(
    parameter STEPS_PER_REVOLUTION = 64 * 2 * 64,
    parameter [0:0] SIDE  = 1'b1
    ) (
    input CLK,
    input RST_N,
    input char_vld,
    input [7:0] char,
    output enb,
    output reg dir,
    input stepped
    );
    
    reg [31:0] count;
    
    assign enb = count > 0;
    
    always @(posedge CLK) begin
        if (!RST_N) begin
            count <= 0;
            dir <= 1;
        end
        else begin
            if (char_vld) begin
                case (char)
                    "F": begin 
                        dir <= SIDE ? 1 : 0;
                        count <= STEPS_PER_REVOLUTION;
                    end
                    "B": begin 
                        dir <= SIDE ? 0 : 1;
                        count <= STEPS_PER_REVOLUTION;
                    end
                    "L": begin 
                        dir <= 1;
                        count <= STEPS_PER_REVOLUTION;
                    end
                    "R": begin 
                        dir <= 0;
                        count <= STEPS_PER_REVOLUTION;
                    end
                    "S": begin 
                        dir <= 0;
                        count <= 0;
                    end
                endcase
            end
            else if (count > 0 && stepped) begin
                count <= count - 1;
            end
        end
    end

endmodule
