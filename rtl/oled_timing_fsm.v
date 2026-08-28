// ========================================================================
// 模块功能：OLED 显示驱动时序控制器
// 对应信号：VSYNC（场同步）、HSYNC（行同步）、DATA_EN（数据使能）
// 时序标准：1280x720@60Hz（H_TOTAL=1650, V_TOTAL=750）
// 可参数化修改为 1080p 或其他分辨率
// ========================================================================

module oled_timing_fsm (
    input  wire        clk,          // 像素时钟（建议 74.25MHz）
    input  wire        rst_n,        // 异步复位，低有效
    output reg         hsync,        // 行同步信号
    output reg         vsync,        // 场同步信号
    output reg         data_en,      // 数据有效使能
    output reg  [11:0] h_cnt,        // 行计数器（0~1649）
    output reg  [11:0] v_cnt         // 场计数器（0~749）
);

    // ----------------------------------------------------------------
    // 时序参数定义（720p 标准）
    // ----------------------------------------------------------------
    localparam H_TOTAL = 12'd1650;    // 一行总周期数
    localparam H_SYNC  = 12'd40;      // 行同步脉冲宽度
    localparam H_BACK  = 12'd220;     // 行同步后沿（消隐）
    localparam H_ACT   = 12'd1280;    // 行有效像素数
    localparam H_FRONT = 12'd110;     // 行同步前沿（H_TOTAL - H_SYNC - H_BACK - H_ACT）

    localparam V_TOTAL = 12'd750;     // 一场总行数
    localparam V_SYNC  = 12'd5;       // 场同步脉冲宽度
    localparam V_BACK  = 12'd20;      // 场同步后沿（消隐）
    localparam V_ACT   = 12'd720;     // 场有效行数
    localparam V_FRONT = 12'd5;       // 场同步前沿（V_TOTAL - V_SYNC - V_BACK - V_ACT）

    // ----------------------------------------------------------------
    // 行计数器与场计数器递增逻辑
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 12'd0;
            v_cnt <= 12'd0;
        end else begin
            if (h_cnt == H_TOTAL - 12'd1) begin      // 一行结束
                h_cnt <= 12'd0;
                if (v_cnt == V_TOTAL - 12'd1)        // 一场结束
                    v_cnt <= 12'd0;
                else
                    v_cnt <= v_cnt + 12'd1;
            end else begin
                h_cnt <= h_cnt + 12'd1;
            end
        end
    end

    // ----------------------------------------------------------------
    // 同步信号与数据使能的组合逻辑（寄存器输出）
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hsync   <= 1'b1;
            vsync   <= 1'b1;
            data_en <= 1'b0;
        end else begin
            // HSYNC：在行同步脉冲区间拉低
            hsync <= (h_cnt < H_SYNC) ? 1'b0 : 1'b1;

            // VSYNC：在场同步脉冲区间拉低
            vsync <= (v_cnt < V_SYNC) ? 1'b0 : 1'b1;

            // DATA_EN：只有在行有效区间 且 场有效区间 才为高
            if ((h_cnt >= H_SYNC + H_BACK) && (h_cnt < H_SYNC + H_BACK + H_ACT) &&
                (v_cnt >= V_SYNC + V_BACK) && (v_cnt < V_SYNC + V_BACK + V_ACT))
                data_en <= 1'b1;
            else
                data_en <= 1'b0;
        end
    end

endmodule
