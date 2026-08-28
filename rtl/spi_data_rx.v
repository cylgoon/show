// ========================================================================
// 模块功能：SPI 从机模式数据接收（MSB 优先）
// 时钟域：使用系统时钟（clk_sys）对 SCLK 进行过采样消抖与边沿检测
// 输出：8 位并行像素数据 + 数据有效脉冲
// ========================================================================

module spi_data_rx (
    input  wire        clk_sys,      // 系统主时钟（100MHz 或 50MHz）
    input  wire        rst_n,        // 异步复位
    input  wire        sclk,         // SPI 串行时钟（由主机提供）
    input  wire        mosi,         // SPI 主出从入数据
    input  wire        cs_n,         // SPI 片选信号（低有效）
    output reg  [7:0]  rx_data,      // 接收到的 8 位并行数据
    output reg         data_ready    // 数据接收完成标志（高脉冲）
);

    // ----------------------------------------------------------------
    // 同步打拍器，消除 SCLK 与 CS_N 的亚稳态
    // ----------------------------------------------------------------
    reg sclk_d1, sclk_d2;
    reg cs_n_d1, cs_n_d2;

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            sclk_d1 <= 1'b0;
            sclk_d2 <= 1'b0;
            cs_n_d1 <= 1'b1;
            cs_n_d2 <= 1'b1;
        end else begin
            sclk_d1 <= sclk;
            sclk_d2 <= sclk_d1;
            cs_n_d1 <= cs_n;
            cs_n_d2 <= cs_n_d1;
        end
    end

    // SCLK 上升沿检测（同步后的信号）
    wire sclk_rise = sclk_d1 & ~sclk_d2;

    // CS_N 下降沿检测（用于复位内部状态，可选）
    wire cs_n_fall = ~cs_n_d1 & cs_n_d2;

    // ----------------------------------------------------------------
    // SPI 接收移位寄存器与位计数器
    // ----------------------------------------------------------------
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt   <= 3'd0;
            shift_reg <= 8'd0;
            rx_data   <= 8'd0;
            data_ready <= 1'b0;
        end else begin
            // 默认拉低 data_ready
            data_ready <= 1'b0;

            // CS_N 为低时（片选有效），才允许接收数据
            if (!cs_n_d1) begin
                if (sclk_rise) begin
                    // MSB 优先，左移输入
                    shift_reg <= {shift_reg[6:0], mosi};

                    if (bit_cnt == 3'd7) begin
                        // 第 8 个 bit 接收完成
                        bit_cnt   <= 3'd0;
                        rx_data   <= {shift_reg[6:0], mosi};   // 锁存完整字节
                        data_ready <= 1'b1;                    // 产生一个周期的高脉冲
                    end else begin
                        bit_cnt <= bit_cnt + 3'd1;
                    end
                end
            end else begin
                // CS_N 高电平（片选无效）时，复位位计数器
                bit_cnt <= 3'd0;
            end
        end
    end

endmodule
