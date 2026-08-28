// ========================================================================
// 模块功能：顶层集成模块
// 将 SPI 接收、异步 FIFO 缓存、OLED 时序控制三个模块互联
// 形成完整的显示驱动数据链路
// ========================================================================

module top_module (
    // 系统级信号
    input  wire        sys_clk,      // 系统主时钟（100MHz，用于 SPI 采样）
    input  wire        pixel_clk,    // 像素驱动时钟（74.25MHz，用于 OLED 时序）
    input  wire        rst_n,        // 全局复位

    // SPI 接口（来自面板主控）
    input  wire        spi_sclk,
    input  wire        spi_mosi,
    input  wire        spi_cs_n,

    // OLED 面板驱动接口
    output wire        oled_hs,
    output wire        oled_vs,
    output wire        oled_de,
    output wire [7:0]  oled_rgb_data
);

    // ----------------------------------------------------------------
    // 内部信号互联
    // ----------------------------------------------------------------
    wire [7:0] spi_rx_data;
    wire       spi_data_ready;

    wire [7:0] fifo_dout;
    wire       fifo_empty;
    wire       fifo_full;
    wire [4:0] fifo_level;

    wire       oled_data_en;
    wire [11:0] h_cnt, v_cnt;

    // 从 FIFO 读取数据的使能信号：
    // 只有当 OLED 处于数据有效区间 且 FIFO 非空时，才发起读请求
    wire fifo_rd_en = oled_data_en & ~fifo_empty;

    // ----------------------------------------------------------------
    // 实例化 1：SPI 数据接收
    // ----------------------------------------------------------------
    spi_data_rx u_spi_rx (
        .clk_sys   (sys_clk),
        .rst_n     (rst_n),
        .sclk      (spi_sclk),
        .mosi      (spi_mosi),
        .cs_n      (spi_cs_n),
        .rx_data   (spi_rx_data),
        .data_ready(spi_data_ready)
    );

    // ----------------------------------------------------------------
    // 实例化 2：异步 FIFO 跨时钟缓冲
    // 写时钟 = sys_clk（SPI 采样时钟），读时钟 = pixel_clk（显示时钟）
    // ----------------------------------------------------------------
    async_fifo u_async_fifo (
        .wr_clk    (sys_clk),
        .rd_clk    (pixel_clk),
        .rst_n     (rst_n),
        .din       (spi_rx_data),
        .wr_en     (spi_data_ready),
        .rd_en     (fifo_rd_en),
        .dout      (fifo_dout),
        .full      (fifo_full),
        .empty     (fifo_empty),
        .data_count(fifo_level)
    );

    // ----------------------------------------------------------------
    // 实例化 3：OLED 驱动时序状态机
    // ----------------------------------------------------------------
    oled_timing_fsm u_timing_fsm (
        .clk    (pixel_clk),
        .rst_n  (rst_n),
        .hsync  (oled_hs),
        .vsync  (oled_vs),
        .data_en(oled_data_en),
        .h_cnt  (h_cnt),
        .v_cnt  (v_cnt)
    );

    // ----------------------------------------------------------------
    // 输出数据赋值：直接取 FIFO 读出数据
    // 在 data_en 为低时，数据线可输出 0 或保持，此处赋 0
    // ----------------------------------------------------------------
    assign oled_data_en   = oled_data_en;   // 直接连接
    assign oled_rgb_data  = (oled_data_en) ? fifo_dout : 8'h00;

endmodule
