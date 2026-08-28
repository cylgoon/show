// ========================================================================
// Testbench：验证 top_module 的 SPI 接收、FIFO 缓存与 OLED 时序
// 模拟 SPI 主机发送 0xA3、0x5A、0xFF 三个字节
// 生成 VCD 波形文件供 GTKWave 或 Vivado 查看
// ========================================================================

`timescale 1ns / 1ps

module tb_top();

    // ----------------------------------------------------------------
    // 输入激励信号定义
    // ----------------------------------------------------------------
    reg  sys_clk;
    reg  pixel_clk;
    reg  rst_n;
    reg  spi_sclk;
    reg  spi_mosi;
    reg  spi_cs_n;

    // 顶层模块输出（监测）
    wire oled_hs;
    wire oled_vs;
    wire oled_de;
    wire [7:0] oled_rgb_data;

    // ----------------------------------------------------------------
    // 时钟生成
    // ----------------------------------------------------------------
    always #5  sys_clk   = ~sys_clk;     // 100MHz
    always #6.73 pixel_clk = ~pixel_clk; // 约 74.25MHz

    // ----------------------------------------------------------------
    // 实例化被测模块（DUT）
    // ----------------------------------------------------------------
    top_module uut (
        .sys_clk    (sys_clk),
        .pixel_clk  (pixel_clk),
        .rst_n      (rst_n),
        .spi_sclk   (spi_sclk),
        .spi_mosi   (spi_mosi),
        .spi_cs_n   (spi_cs_n),
        .oled_hs    (oled_hs),
        .oled_vs    (oled_vs),
        .oled_de    (oled_de),
        .oled_rgb_data(oled_rgb_data)
    );

    // ----------------------------------------------------------------
    // SPI 主机发送任务（模拟 SPI 时序，CPOL=0, CPHA=0）
    // ----------------------------------------------------------------
    task send_spi_byte;
        input [7:0] tx_data;
        integer i;
        begin
            // 片选拉低，开始传输
            spi_cs_n = 1'b0;
            #100;   // 等待稳定

            for (i = 7; i >= 0; i = i - 1) begin
                spi_mosi = tx_data[i];
                // SCLK 上升沿发送数据
                spi_sclk = 1'b0;
                #50;
                spi_sclk = 1'b1;
                #50;
            end

            // 片选拉高，结束传输
            spi_cs_n = 1'b1;
            #200;   // 帧间隔
        end
    endtask

    // ----------------------------------------------------------------
    // 主激励序列
    // ----------------------------------------------------------------
    initial begin
        // 初始化所有信号
        sys_clk   = 1'b0;
        pixel_clk = 1'b0;
        rst_n     = 1'b0;
        spi_sclk  = 1'b0;
        spi_mosi  = 1'b0;
        spi_cs_n  = 1'b1;

        // 释放复位（保持 10 个系统周期）
        #100;
        rst_n = 1'b1;
        #200;

        // 连续发送 3 个 SPI 字节
        send_spi_byte(8'hA3);   // 0xA3
        send_spi_byte(8'h5A);   // 0x5A
        send_spi_byte(8'hFF);   // 0xFF

        // 继续运行一段时间，观察 OLED 时序输出
        #20000;

        // 结束仿真
        $display("Simulation finished at time %t", $time);
        $finish;
    end

    // ----------------------------------------------------------------
    // 生成 VCD 波形文件（用于 GTKWave 或 Vivado 查看）
    // ----------------------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
    end

    // ----------------------------------------------------------------
    // 打印关键信号信息（便于调试）
    // ----------------------------------------------------------------
    always @(posedge pixel_clk) begin
        if (oled_de)
            $display("OLED DE=1, Data=0x%h, H_Cnt=%d, V_Cnt=%d", oled_rgb_data, uut.h_cnt, uut.v_cnt);
    end

endmodule
