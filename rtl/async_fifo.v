// ========================================================================
// 模块功能：异步 FIFO（格雷码指针）
// 写时钟域：SPI 数据接收时钟（wr_clk）
// 读时钟域：OLED 像素时钟（rd_clk）
// 深度：16（地址宽度 4 位），数据宽度 8 位
// ========================================================================

module async_fifo (
    input  wire        wr_clk,       // 写时钟
    input  wire        rd_clk,       // 读时钟
    input  wire        rst_n,        // 异步复位（同时复位两个时钟域）
    input  wire [7:0]  din,          // 写数据
    input  wire        wr_en,        // 写使能
    input  wire        rd_en,        // 读使能
    output reg  [7:0]  dout,         // 读数据
    output wire        full,         // 满标志
    output wire        empty,        // 空标志
    output wire [4:0]  data_count    // FIFO 内数据量（仅作参考，近似值）
);

    // ----------------------------------------------------------------
    // 参数与内存定义
    // ----------------------------------------------------------------
    localparam ADDR_WIDTH = 4;
    localparam DEPTH      = 16;

    reg [7:0] mem [0:DEPTH-1];       // 双端口 RAM

    // 写指针（二进制 + 格雷码）
    reg [ADDR_WIDTH:0] wr_ptr_bin;   // 多 1 位用于比较空/满
    reg [ADDR_WIDTH:0] wr_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync2;

    // 读指针（二进制 + 格雷码）
    reg [ADDR_WIDTH:0] rd_ptr_bin;
    reg [ADDR_WIDTH:0] rd_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync2;

    // ----------------------------------------------------------------
    // 格雷码转换函数
    // ----------------------------------------------------------------
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction

    // ----------------------------------------------------------------
    // 写时钟域逻辑
    // ----------------------------------------------------------------
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= din;
                wr_ptr_bin  <= wr_ptr_bin + 1;
                wr_ptr_gray <= bin_to_gray(wr_ptr_bin + 1);
            end
        end
    end

    // 将读指针同步到写时钟域
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // 写满标志：写指针格雷码与同步过来的读指针格雷码比较
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});

    // ----------------------------------------------------------------
    // 读时钟域逻辑
    // ----------------------------------------------------------------
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
        end else begin
            if (rd_en && !empty) begin
                dout        <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
                rd_ptr_bin  <= rd_ptr_bin + 1;
                rd_ptr_gray <= bin_to_gray(rd_ptr_bin + 1);
            end
        end
    end

    // 将写指针同步到读时钟域
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // 读空标志：读指针格雷码与同步过来的写指针格雷码比较
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

    // ----------------------------------------------------------------
    // FIFO 数据量（近似值，用于观察水位）
    // 仅作仿真示意，实际综合时可用 IP 核内部计数
    // ----------------------------------------------------------------
    assign data_count = (wr_ptr_bin >= rd_ptr_bin) ? 
                        (wr_ptr_bin - rd_ptr_bin) : 
                        (DEPTH + wr_ptr_bin - rd_ptr_bin);

endmodule
// 双口RAM（省略完整实现，保留接口说明即可）
// reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

endmodule
