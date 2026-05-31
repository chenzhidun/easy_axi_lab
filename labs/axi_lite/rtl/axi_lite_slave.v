// AXI4-Lite Slave - 16x32bit 寄存器，在 TODO 处填入实现

`timescale 1ns/1ps

module axi_lite_slave (
    input  wire        aclk,
    input  wire        aresetn,

    // AW
    input  wire        awvalid,
    output reg        awready,
    input  wire [31:0] awaddr,
    input  wire [2:0]  awprot,

    // W
    input  wire        wvalid,
    output reg       wready,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,

    // B
    output reg         bvalid,
    input  wire        bready,
    output wire [1:0]  bresp,//00为写入无错误

    // AR
    input  wire        arvalid,
    output reg        arready,
    input  wire [31:0] araddr,
    input  wire [2:0]  arprot,

    // R
    output reg        rvalid,
    input  wire        rready,
    output reg [31:0] rdata,
    output wire [1:0]  rresp
);

    reg [31:0] regs [0:15];
    reg [31:0] awaddr_in;
    reg [31:0] wdata_in;
    reg [3:0]  wstrb_in;
    reg [31:0] araddr_in;
    reg aw_done;
    reg w_done;
    wire aww_done;
    assign aww_done=aw_done && w_done;
    wire [3:0]idx;
    assign idx=awaddr_in[5:2];
    reg araddr_start;
    
    integer i;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            for (i = 0; i < 16; i = i + 1) regs[i] <= 32'h0;
        end else begin
            // TODO: AW + W 都握手后，按 wstrb 写入 regs[idx]
            if(aww_done)begin
                if(wstrb_in[0])regs[idx][7:0]<=wdata_in[7:0];
                if(wstrb_in[1])regs[idx][15:8]<=wdata_in[15:8];
                if(wstrb_in[2])regs[idx][23:16]<=wdata_in[23:16];
                if(wstrb_in[3])regs[idx][31:24]<=wdata_in[31:24];
            end
        end
    end

    // TODO 1 : AW 通道，awready 握手并锁存 awaddr
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awready <= 1'b1;//空闲状态
            awaddr_in<=32'b0;
            aw_done<=1'b0;
        end else begin
            if(!aw_done && awvalid && awready)begin
                aw_done<=1'b1; 
                awaddr_in<=awaddr;
                awready<=1'b0;
            end 
            else if (aww_done)begin
                awready <= 1'b1;
                aw_done<=1'b0;
            end
        end 
    end

    // TODO 2 : W 通道，wready 握手并锁存 wdata 和 wstrb
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wready <= 1'b1;
            wdata_in<=32'b0;
            wstrb_in<=4'd0;
            w_done<=1'b0;
        end else begin
            if( !w_done && wvalid && wready)begin
                w_done<=1'b1;
                wdata_in<=wdata;
                wstrb_in<=wstrb;
                wready <= 1'b0;
                
            end 
            else if (aww_done)begin
                wready <= 1'b1;
                w_done<=1'b0;
            end
        end 
    end

    // TODO 3 : 写提交 + B 通道
    assign bresp  = 2'b00;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            bvalid <= 1'b0;
        end else begin
            if(aww_done)begin
                bvalid<=1'b1;
            end
            else begin
            if(bvalid && bready)begin
                bvalid <= 1'b0;
            end
        end
    end
    end

    // TODO 4 : AR 通道，arready 握手并锁存 araddr
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            arready <= 1'b1;
            araddr_in<=32'd0;
            araddr_start<=1'b0;
        end else begin
            if(!rvalid && arvalid && arready)begin
                arready <= 1'b0;
                araddr_in<=araddr;//延迟
                araddr_start<=1'b1;//去掉延迟
            end 
            else if(rvalid && rready)arready <= 1'b1;
        end
    end

    // TODO 5 : R 通道
    assign rresp  = 2'b00;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rvalid <= 1'b0;
            rdata  <= 32'h0;
        end else begin
            if(araddr_start)begin
                rvalid <= 1'b1;
                rdata<=regs[araddr_in[5:2]];
            end
            else if(rvalid && rready)rvalid <= 1'b0;
        end
    end
endmodule
