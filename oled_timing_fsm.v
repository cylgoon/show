module oled_timing_fsm #(
    parameter H_ACTIVE  = 10'd480,
    parameter H_FRONT   = 10'd20,
    parameter H_SYNC    = 10'd10,
    parameter H_BACK    = 10'd20,
    parameter V_ACTIVE  = 10'd272,
    parameter V_FRONT   = 10'd4,
    parameter V_SYNC    = 10'd2,
    parameter V_BACK    = 10'd2
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        fifo_empty,
    output reg         fifo_rd_en,
    output reg         hsync,
    output reg         vsync,
    output reg         data_en,
    output reg [9:0]   pixel_cnt,
    output reg [9:0]   line_cnt
);

localparam H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
localparam V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

reg [9:0] h_cnt;
reg [9:0] v_cnt;

// 行计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        h_cnt <= 10'd0;
    else if(h_cnt == H_TOTAL - 1'b1)
        h_cnt <= 10'd0;
    else
        h_cnt <= h_cnt + 1'b1;
end

// 场计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        v_cnt <= 10'd0;
    else if(h_cnt == H_TOTAL - 1'b1) begin
        if(v_cnt == V_TOTAL - 1'b1)
            v_cnt <= 10'd0;
        else
            v_cnt <= v_cnt + 1'b1;
    end
end

// 时序信号生成
always @(*) begin
    hsync = 1'b1;
    vsync = 1'b1;
    data_en = 1'b0;
    fifo_rd_en = 1'b0;
    
    // 行同步
    if(h_cnt >= H_ACTIVE + H_FRONT && h_cnt < H_ACTIVE + H_FRONT + H_SYNC)
        hsync = 1'b0;
    
    // 场同步
    if(v_cnt >= V_ACTIVE + V_FRONT && v_cnt < V_ACTIVE + V_FRONT + V_SYNC)
        vsync = 1'b0;
    
    // 数据有效区
    if(h_cnt < H_ACTIVE && v_cnt < V_ACTIVE && !fifo_empty) begin
        data_en = 1'b1;
        fifo_rd_en = 1'b1;
    end
end

assign pixel_cnt = h_cnt;
assign line_cnt = v_cnt;

endmodule
