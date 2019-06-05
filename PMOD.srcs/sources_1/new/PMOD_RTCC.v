`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2019 23:54:16
// Design Name: 
// Module Name: PMOD_RTCC
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


module PMOD_RTCC(
    input CLK,
    input RST_N,
    
    input mfiState,
    output busy,
    
    inout SCL_1,
    inout SDA_1,
    inout SCL_2,
    inout SDA_2,
    
    output missed_ack
    );
    
    parameter CLK_FREQ = 100000000; // 100MHz
    parameter I2C_CLK_FREQ = 200000; // Spec max: 400kHz
    
    localparam [6:0] EEPROM_ADDR = 'b1010111;
    localparam [6:0] RTCC_ADDR   = 'b1101111;
    
    localparam RTCC_REG_START = 0;
    localparam SRAM_START = 'h20;
    
    localparam EEPROM_START = 0;
    localparam EEPROM_PROTECTED_START = 'hF0;
    localparam EEPROM_STATUS_ADDR = 'hFF;
    
    wire [6:0] i2c_cmd_address;
    wire [7:0] i2c_data_in, i2c_data_out;
    
    i2c_master rtcc_i2c (
        .clk (CLK),
        .rst (~RST_N),
        
        /*
        * Host interface
        */
        .cmd_address        (i2c_cmd_address),
        .cmd_start          (i2c_cmd_start),
        .cmd_read           (i2c_cmd_read),
        .cmd_write          (i2c_cmd_write),
        .cmd_write_multiple (i2c_cmd_write_multiple),
        .cmd_stop           (i2c_cmd_stop),
        .cmd_valid          (i2c_cmd_valid),
        .cmd_ready          (i2c_cmd_ready),
        
        .data_in            (i2c_data_in),
        .data_in_valid      (i2c_data_in_valid),
        .data_in_ready      (i2c_data_in_ready),
        .data_in_last       (i2c_data_in_last),
        
        .data_out           (i2c_data_out),
        .data_out_valid     (i2c_data_out_valid),
        .data_out_ready     (i2c_data_out_ready),
        .data_out_last      (i2c_data_out_last),
        
        /*
        * I2C interface
        */
        .scl_i              (i2c_scl_i),
        .scl_o              (i2c_scl_o),
        .scl_t              (i2c_scl_t),
        .sda_i              (i2c_sda_i),
        .sda_o              (i2c_sda_o),
        .sda_t              (i2c_sda_t),
        
        /*
        * Status
        */
        .busy               (i2c_busy),
        .bus_control        (i2c_bus_control),
        .bus_active         (i2c_bus_active),
        .missed_ack         (i2c_missed_ack),
        
        /*
        * Configuration
        */
        .prescale           (CLK_FREQ / (I2C_CLK_FREQ * 4)),
        .stop_on_idle       (1)
    );
    
    assign i2c_scl_i = SCL_1;
    assign SCL_1 = i2c_scl_t ? 1'bz : i2c_scl_o;
    assign SCL_2 = i2c_scl_t ? 1'bz : i2c_scl_o;
    assign i2c_sda_i = SDA_1;
    assign SDA_1 = i2c_sda_t ? 1'bz : i2c_sda_o;
    assign SDA_2 = i2c_sda_t ? 1'bz : i2c_sda_o;

    reg mfiState_prev;
    
    reg [6:0] dev_addr;
    reg [7:0] reg_addr;
    reg [7:0] reg_data;

    reg start;

    always @(posedge CLK) begin
        mfiState_prev <= mfiState;
    end

    always @(posedge CLK) begin
        if (!RST_N) begin
            start <= 0;
            dev_addr <= 0;
            reg_addr <= 0;
            reg_data <= 0;
        end
        else begin
            if (mfiState != mfiState_prev && !busy) begin
                start <= 1;
                
                if (mfiState) begin
                    dev_addr <= RTCC_ADDR;
                    reg_addr <= 'h07;
                    reg_data <= 'b10001000;
                end
                else begin
                    dev_addr <= RTCC_ADDR;
                    reg_addr <= 'h07;
                    reg_data <= 'b00001000;
                end
            end
            else begin
                start <= 0;
            end
        end
    end

    wire [6:0]  cmd_address;
    wire        cmd_start;
    wire        cmd_read;
    wire        cmd_write;
    wire        cmd_write_multiple;
    wire        cmd_stop;
    wire        cmd_valid;
    wire        cmd_ready;

    wire [7:0]  data_out;
    wire        data_out_valid;
    wire        data_out_ready;
    wire        data_out_last;
    
    PMOD_RTCC_Op rtcc_op (
        .clk     (CLK),
        .rst     (!RST_N),
        
        .dev_addr           (dev_addr),
        .reg_addr           (reg_addr),
        .reg_data           (reg_data),
        
        .cmd_address        (cmd_address),
        .cmd_start          (cmd_start),
        .cmd_read           (cmd_read),
        .cmd_write          (cmd_write),
        .cmd_write_multiple (cmd_write_multiple),
        .cmd_stop           (cmd_stop),
        .cmd_valid          (cmd_valid),
        .cmd_ready          (cmd_ready),
        
        .data_out           (data_out),
        .data_out_valid     (data_out_valid),
        .data_out_ready     (data_out_ready),
        .data_out_last      (data_out_last),

        .busy               (busy),
        .start              (start)
        );

    assign i2c_cmd_address         = busy ? cmd_address        : 0;
    assign i2c_cmd_start           = busy ? cmd_start          : 0;
    assign i2c_cmd_read            = busy ? cmd_read           : 0;
    assign i2c_cmd_write           = busy ? cmd_write          : 0;
    assign i2c_cmd_write_multiple  = busy ? cmd_write_multiple : 0;
    assign i2c_cmd_stop            = busy ? cmd_stop           : 0;
    assign i2c_cmd_valid           = busy ? cmd_valid          : 0;

    assign cmd_ready               = i2c_cmd_ready;

    assign i2c_data_in             = busy ? data_out       : 0;
    assign i2c_data_in_valid       = busy ? data_out_valid : 0;

    assign data_out_ready          = i2c_data_in_ready;

    assign i2c_data_in_last        = busy ? data_out_last : 0;
                                     
    assign missed_ack = i2c_missed_ack;

endmodule
