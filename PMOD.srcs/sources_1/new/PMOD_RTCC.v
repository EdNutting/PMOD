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
    output setmfi_busy,
    output clearmfi_busy,
    
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

    reg setmfi_start;
    reg clearmfi_start;
    reg mfiState_prev;
    
    always @(posedge CLK) begin
        mfiState_prev <= mfiState;
    end

    always @(posedge CLK) begin
        if (!RST_N) begin
            setmfi_start <= 0;
            clearmfi_start <= 0;
        end
        else begin
            if (mfiState != mfiState_prev && !setmfi_busy && !clearmfi_busy) begin
                if (mfiState) begin
                    setmfi_start <= 1;
                    clearmfi_start <= 0;
                end
                else begin
                    setmfi_start <= 0;
                    clearmfi_start <= 1;
                end
            end
            else begin
                setmfi_start <= 0;
                clearmfi_start <= 0;
            end
        end
    end

    wire [6:0]  setmfi_cmd_address;
    wire        setmfi_cmd_start;
    wire        setmfi_cmd_read;
    wire        setmfi_cmd_write;
    wire        setmfi_cmd_write_multiple;
    wire        setmfi_cmd_stop;
    wire        setmfi_cmd_valid;
    wire        setmfi_cmd_ready;

    wire [7:0]  setmfi_data_out;
    wire        setmfi_data_out_valid;
    wire        setmfi_data_out_ready;
    wire        setmfi_data_out_last;
    
    PMOD_RTCC_SetMFI mfi_set (
        .clk     (CLK),
        .rst     (!RST_N),
        
        .cmd_address        (setmfi_cmd_address),
        .cmd_start          (setmfi_cmd_start),
        .cmd_read           (setmfi_cmd_read),
        .cmd_write          (setmfi_cmd_write),
        .cmd_write_multiple (setmfi_cmd_write_multiple),
        .cmd_stop           (setmfi_cmd_stop),
        .cmd_valid          (setmfi_cmd_valid),
        .cmd_ready          (setmfi_cmd_ready),
        
        .data_out           (setmfi_data_out),
        .data_out_valid     (setmfi_data_out_valid),
        .data_out_ready     (setmfi_data_out_ready),
        .data_out_last      (setmfi_data_out_last),

        .busy               (setmfi_busy),
        .start              (setmfi_start)
        );

    wire [6:0]  clearmfi_cmd_address;
    wire        clearmfi_cmd_start;
    wire        clearmfi_cmd_read;
    wire        clearmfi_cmd_write;
    wire        clearmfi_cmd_write_multiple;
    wire        clearmfi_cmd_stop;
    wire        clearmfi_cmd_valid;
    wire        clearmfi_cmd_ready;

    wire [7:0]  clearmfi_data_out;
    wire        clearmfi_data_out_valid;
    wire        clearmfi_data_out_ready;
    wire        clearmfi_data_out_last;
    
    PMOD_RTCC_ClearMFI mfi_clear (
        .clk     (CLK),
        .rst     (!RST_N),
        
        .cmd_address        (clearmfi_cmd_address),
        .cmd_start          (clearmfi_cmd_start),
        .cmd_read           (clearmfi_cmd_read),
        .cmd_write          (clearmfi_cmd_write),
        .cmd_write_multiple (clearmfi_cmd_write_multiple),
        .cmd_stop           (clearmfi_cmd_stop),
        .cmd_valid          (clearmfi_cmd_valid),
        .cmd_ready          (clearmfi_cmd_ready),
        
        .data_out           (clearmfi_data_out),
        .data_out_valid     (clearmfi_data_out_valid),
        .data_out_ready     (clearmfi_data_out_ready),
        .data_out_last      (clearmfi_data_out_last),

        .busy               (clearmfi_busy),
        .start              (clearmfi_start)
        );
        
    assign i2c_cmd_address         = setmfi_busy   ? setmfi_cmd_address   :
                                     clearmfi_busy ? clearmfi_cmd_address :
                                     0;
    assign i2c_cmd_start           = setmfi_busy   ? setmfi_cmd_start   :
                                     clearmfi_busy ? clearmfi_cmd_start :
                                     0;
    assign i2c_cmd_read            = setmfi_busy   ? setmfi_cmd_read   :
                                     clearmfi_busy ? clearmfi_cmd_read :
                                     0;
    assign i2c_cmd_write           = setmfi_busy   ? setmfi_cmd_write   :
                                     clearmfi_busy ? clearmfi_cmd_write :
                                     0;
    assign i2c_cmd_write_multiple  = setmfi_busy   ? setmfi_cmd_write_multiple   :
                                     clearmfi_busy ? clearmfi_cmd_write_multiple :
                                     0;
    assign i2c_cmd_stop            = setmfi_busy   ? setmfi_cmd_stop   :
                                     clearmfi_busy ? clearmfi_cmd_stop :
                                     0;
    assign i2c_cmd_valid           = setmfi_busy   ? setmfi_cmd_valid   :
                                     clearmfi_busy ? clearmfi_cmd_valid :
                                     0;

    assign setmfi_cmd_ready        = i2c_cmd_ready;
    assign clearmfi_cmd_ready      = i2c_cmd_ready;

    assign i2c_data_in             = setmfi_busy   ? setmfi_data_out   :
                                     clearmfi_busy ? clearmfi_data_out :
                                     0;
    assign i2c_data_in_valid       = setmfi_busy   ? setmfi_data_out_valid   :
                                     clearmfi_busy ? clearmfi_data_out_valid :
                                     0;

    assign setmfi_data_out_ready   = i2c_data_in_ready;
    assign clearmfi_data_out_ready = i2c_data_in_ready;

    assign i2c_data_in_last        = setmfi_busy   ? setmfi_data_out_last   :
                                     clearmfi_busy ? clearmfi_data_out_last :
                                     0;
                                     
    assign missed_ack = i2c_missed_ack;

endmodule
