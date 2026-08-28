module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8  // 深度256
)(
    input  wire wr_clk,
    input  wire wr_rst_n,
    input  wire wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    
    input  wire rd_clk,
    input  wire rd_rst_n,
    input  wire rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    
    output wire full,
    output wire empty
);

// 格雷码指针
reg [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_gray;
reg [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_gray;

// 写指针：二进制转格雷码
always @(posedge wr_clk or negedge wr_rst_n) begin
    if(!wr_rst_n) begin
        wr_ptr_bin <= 'd0;
        wr_ptr_gray <= 'd0;
    end else if(wr_en && !full) begin
        wr_ptr_bin <= wr_ptr_bin + 1'b1;
        wr_ptr_gray <= (wr_ptr_bin + 1'b1) ^ ((wr_ptr_bin + 1'b1) >> 1);
    end
end

// 读指针：二进制转格雷码
always @(posedge rd_clk or negedge rd_rst_n) begin
    if(!rd_rst_n) begin
        rd_ptr_bin <= 'd0;
        rd_ptr_gray <= 'd0;
    end else if(rd_en && !empty) begin
        rd_ptr_bin <= rd_ptr_bin + 1'b1;
        rd_ptr_gray <= (rd_ptr_bin + 1'b1) ^ ((rd_ptr_bin + 1'b1) >> 1);
    end
end

// 跨时钟域指针同步（双级触发器）
reg [ADDR_WIDTH:0] wr_ptr_sync1, wr_ptr_sync2;
reg [ADDR_WIDTH:0] rd_ptr_sync1, rd_ptr_sync2;

always @(posedge rd_clk or negedge rd_rst_n) begin
    if(!rd_rst_n) begin
        wr_ptr_sync1 <= 'd0;
        wr_ptr_sync2 <= 'd0;
    end else begin
        wr_ptr_sync1 <= wr_ptr_gray;
        wr_ptr_sync2 <= wr_ptr_sync1;
    end
end

always @(posedge wr_clk or negedge wr_rst_n) begin
    if(!wr_rst_n) begin
        rd_ptr_sync1 <= 'd0;
        rd_ptr_sync2 <= 'd0;
    end else begin
        rd_ptr_sync1 <= rd_ptr_gray;
        rd_ptr_sync2 <= rd_ptr_sync1;
    end
end

// 空满判断
assign empty = (rd_ptr_gray == wr_ptr_sync2);
assign full  = (wr_ptr_gray[ADDR_WIDTH] != rd_ptr_sync2[ADDR_WIDTH]) &&
               (wr_ptr_gray[ADDR_WIDTH-1] != rd_ptr_sync2[ADDR_WIDTH-1]) &&
               (wr_ptr_gray[ADDR_WIDTH-2:0] == rd_ptr_sync2[ADDR_WIDTH-2:0]);

// 双口RAM（省略完整实现，保留接口说明即可）
// reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

endmodule
