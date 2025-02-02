/*
Copyright 2021 GaoZiBo <diyer175@hotmail.com>
Powered by YSYX https://oscpu.github.io/ysyx

Licensed under The MIT License (MIT).
-------------------------------------
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

module ysyx_210479
(
   input	clock,
   input	reset,
   input	io_interrupt,
   // AXI4 Master
   input io_master_awready,
   output io_master_awvalid,
   output [31:0]	io_master_awaddr,
   output [3:0]	io_master_awid,
   output [7:0]	io_master_awlen,
   output [2:0]	io_master_awsize,
   output [1:0]	io_master_awburst,
   input io_master_wready,
   output io_master_wvalid,
   output [63:0]	io_master_wdata,
   output [7:0]	io_master_wstrb,
   output io_master_wlast,
   output io_master_bready,
   input io_master_bvalid,
   input	[1:0]	io_master_bresp,
   input	[3:0]	io_master_bid,
   input io_master_arready,
   output io_master_arvalid,
   output [31:0]	io_master_araddr,
   output [3:0]	io_master_arid,
   output [7:0]	io_master_arlen,
   output [2:0]	io_master_arsize,
   output io_master_rready,
   input io_master_rvalid,
   input	[1:0]	io_master_rresp,
   input	[63:0]	io_master_rdata,
   input io_master_rlast,
   input	[3:0]	io_master_rid,

   // AXI4 Slave
   output io_slave_awready,
	input io_slave_awvalid,
	input	[31:0]	io_slave_awaddr,
	input	[3:0]	io_slave_awid,
	input	[7:0]	io_slave_awlen,
	input	[2:0]	io_slave_awsize,
	input	[1:0]	io_slave_awburst,
	output io_slave_wready,
   input io_slave_wvalid,
	input	[63:0]	io_slave_wdata,
	input	[7:0]	io_slave_wstrb,
	input io_slave_wlast,
	input io_slave_bready,
	output io_slave_bvalid,
	output [1:0]	io_slave_bresp,
	output [3:0]	io_slave_bid,
	output io_slave_arready,
	input io_slave_arvalid,
	input	[31:0]	io_slave_araddr,
	input	[3:0]	io_slave_arid,
	input	[7:0]	io_slave_arlen,
	input	[2:0]	io_slave_arsize,
   output [1:0]	io_master_arburst,
	input	[1:0]	io_slave_arburst,
	input io_slave_rready,
	output io_slave_rvalid,
	output [1:0]	io_slave_rresp,
	output [63:0]	io_slave_rdata,
	output io_slave_rlast,
	output [3:0]	io_slave_rid
);

   // CPU configurations
   localparam                           CONFIG_AW = 32;
   localparam                           CONFIG_DW = 32;
   localparam                           CONFIG_P_DW = 5;
   localparam                           CONFIG_P_FETCH_WIDTH = 2;
   localparam                           CONFIG_P_ISSUE_WIDTH = 1;
   localparam                           CONFIG_P_PAGE_SIZE = 13;
   localparam                           CONFIG_IC_P_LINE = 6;
   localparam                           CONFIG_IC_P_SETS = 4;
   localparam                           CONFIG_IC_P_WAYS = 1;
   localparam                           CONFIG_DC_P_LINE = 6;
   localparam                           CONFIG_DC_P_SETS = 4;
   localparam                           CONFIG_DC_P_WAYS = 1;
   localparam                           CONFIG_PHT_P_NUM = 3;
   localparam                           CONFIG_BTB_P_NUM = 3;
   localparam                           CONFIG_P_IQ_DEPTH = 2;
//   localparam                           CONFIG_ENABLE_MUL = 0;
//   localparam                           CONFIG_ENABLE_DIV = 0;
//   localparam                           CONFIG_ENABLE_DIVU = 0;
//   localparam                           CONFIG_ENABLE_MOD = 0;
//   localparam                           CONFIG_ENABLE_MODU = 0;
   localparam                           CONFIG_ENABLE_ASR = 1;
   localparam                           CONFIG_IMMU_ENABLE_UNCACHED_SEG = 1;
   localparam                           CONFIG_DMMU_ENABLE_UNCACHED_SEG = 1;
   localparam                           CONFIG_DTLB_P_SETS = 4;
   localparam                           CONFIG_ITLB_P_SETS = 4;

   localparam [CONFIG_AW-1:0]           CONFIG_PC_RST = 32'h30000000;
   localparam [`EXCP_VECT_W-1:0]        CONFIG_EITM_VECTOR = 8'h1c;
   localparam [`EXCP_VECT_W-1:0]        CONFIG_EIPF_VECTOR = 8'h14;
   localparam [`EXCP_VECT_W-1:0]        CONFIG_ESYSCALL_VECTOR = 8'hc;
   localparam [`EXCP_VECT_W-1:0]        CONFIG_EINSN_VECTOR = 8'h4;
   localparam [`EXCP_VECT_W-1:0]        CONFIG_EIRQ_VECTOR = 8'h8;
   localparam [`EXCP_VECT_W-1:0]        CONFIG_EDTM_VECTOR = 8'h20;
   localparam [`EXCP_VECT_W-1:0]        CONFIG_EDPF_VECTOR = 8'h18;
   localparam [`EXCP_VECT_W-1:0]        CONFIG_EALIGN_VECTOR = 8'h24;
   
   localparam                           CONFIG_NUM_IRQ = 32;
   
   localparam                           CONFIG_P_RS_DEPTH = 2;
   localparam                           CONFIG_P_ROB_DEPTH = 3;

   localparam AXI_P_DW_BYTES   = 3; // 8 Bytes
   localparam AXI_UNCACHED_P_DW_BYTES = 2; // 4 Bytes max. for uncached devices
   localparam AXI_ADDR_WIDTH    = 32;
   localparam AXI_ID_WIDTH      = 4;
   localparam AXI_USER_WIDTH    = 1;

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [AXI_ADDR_WIDTH-1:0] dbus_ARADDR;       // From U_CORE of ncpu64k.v
   wire [1:0]           dbus_ARBURST;           // From U_CORE of ncpu64k.v
   wire [3:0]           dbus_ARCACHE;           // From U_CORE of ncpu64k.v
   wire [AXI_ID_WIDTH-1:0] dbus_ARID;           // From U_CORE of ncpu64k.v
   wire [7:0]           dbus_ARLEN;             // From U_CORE of ncpu64k.v
   wire                 dbus_ARLOCK;            // From U_CORE of ncpu64k.v
   wire [2:0]           dbus_ARPROT;            // From U_CORE of ncpu64k.v
   wire [3:0]           dbus_ARQOS;             // From U_CORE of ncpu64k.v
   wire                 dbus_ARREADY;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           dbus_ARREGION;          // From U_CORE of ncpu64k.v
   wire [2:0]           dbus_ARSIZE;            // From U_CORE of ncpu64k.v
   wire [AXI_USER_WIDTH-1:0] dbus_ARUSER;       // From U_CORE of ncpu64k.v
   wire                 dbus_ARVALID;           // From U_CORE of ncpu64k.v
   wire [AXI_ADDR_WIDTH-1:0] dbus_AWADDR;       // From U_CORE of ncpu64k.v
   wire [1:0]           dbus_AWBURST;           // From U_CORE of ncpu64k.v
   wire [3:0]           dbus_AWCACHE;           // From U_CORE of ncpu64k.v
   wire [AXI_ID_WIDTH-1:0] dbus_AWID;           // From U_CORE of ncpu64k.v
   wire [7:0]           dbus_AWLEN;             // From U_CORE of ncpu64k.v
   wire                 dbus_AWLOCK;            // From U_CORE of ncpu64k.v
   wire [2:0]           dbus_AWPROT;            // From U_CORE of ncpu64k.v
   wire [3:0]           dbus_AWQOS;             // From U_CORE of ncpu64k.v
   wire                 dbus_AWREADY;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           dbus_AWREGION;          // From U_CORE of ncpu64k.v
   wire [2:0]           dbus_AWSIZE;            // From U_CORE of ncpu64k.v
   wire [AXI_USER_WIDTH-1:0] dbus_AWUSER;       // From U_CORE of ncpu64k.v
   wire                 dbus_AWVALID;           // From U_CORE of ncpu64k.v
   wire [AXI_ID_WIDTH-1:0] dbus_BID;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 dbus_BREADY;            // From U_CORE of ncpu64k.v
   wire [1:0]           dbus_BRESP;             // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] dbus_BUSER;        // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 dbus_BVALID;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [(1<<AXI_P_DW_BYTES)*8-1:0] dbus_RDATA; // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_ID_WIDTH-1:0] dbus_RID;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 dbus_RLAST;             // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 dbus_RREADY;            // From U_CORE of ncpu64k.v
   wire [1:0]           dbus_RRESP;             // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] dbus_RUSER;        // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 dbus_RVALID;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [(1<<AXI_P_DW_BYTES)*8-1:0] dbus_WDATA; // From U_CORE of ncpu64k.v
   wire                 dbus_WLAST;             // From U_CORE of ncpu64k.v
   wire                 dbus_WREADY;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [(1<<AXI_P_DW_BYTES)-1:0] dbus_WSTRB;   // From U_CORE of ncpu64k.v
   wire [AXI_USER_WIDTH-1:0] dbus_WUSER;        // From U_CORE of ncpu64k.v
   wire                 dbus_WVALID;            // From U_CORE of ncpu64k.v
   wire [AXI_ADDR_WIDTH-1:0] ibus_ARADDR;       // From U_CORE of ncpu64k.v
   wire [1:0]           ibus_ARBURST;           // From U_CORE of ncpu64k.v
   wire [3:0]           ibus_ARCACHE;           // From U_CORE of ncpu64k.v
   wire [AXI_ID_WIDTH-1:0] ibus_ARID;           // From U_CORE of ncpu64k.v
   wire [7:0]           ibus_ARLEN;             // From U_CORE of ncpu64k.v
   wire                 ibus_ARLOCK;            // From U_CORE of ncpu64k.v
   wire [2:0]           ibus_ARPROT;            // From U_CORE of ncpu64k.v
   wire [3:0]           ibus_ARQOS;             // From U_CORE of ncpu64k.v
   wire                 ibus_ARREADY;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           ibus_ARREGION;          // From U_CORE of ncpu64k.v
   wire [2:0]           ibus_ARSIZE;            // From U_CORE of ncpu64k.v
   wire [AXI_USER_WIDTH-1:0] ibus_ARUSER;       // From U_CORE of ncpu64k.v
   wire                 ibus_ARVALID;           // From U_CORE of ncpu64k.v
   wire                 ibus_AWREADY;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_ID_WIDTH-1:0] ibus_BID;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [1:0]           ibus_BRESP;             // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] ibus_BUSER;        // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_BVALID;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [(1<<AXI_P_DW_BYTES)*8-1:0] ibus_RDATA; // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_ID_WIDTH-1:0] ibus_RID;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_RLAST;             // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_RREADY;            // From U_CORE of ncpu64k.v
   wire [1:0]           ibus_RRESP;             // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] ibus_RUSER;        // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_RVALID;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_WREADY;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_ADDR_WIDTH-1:0] inner_ARADDR;      // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [1:0]           inner_ARBURST;          // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           inner_ARCACHE;          // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_ID_WIDTH-1:0] inner_ARID;          // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [7:0]           inner_ARLEN;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 inner_ARLOCK;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [2:0]           inner_ARPROT;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           inner_ARQOS;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 inner_ARREADY;          // From U_AXI4_reg_slice_R of axi4_buf_r.v
   wire [3:0]           inner_ARREGION;         // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [2:0]           inner_ARSIZE;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] inner_ARUSER;      // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 inner_ARVALID;          // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_ADDR_WIDTH-1:0] inner_AWADDR;      // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [1:0]           inner_AWBURST;          // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           inner_AWCACHE;          // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_ID_WIDTH-1:0] inner_AWID;          // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [7:0]           inner_AWLEN;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 inner_AWLOCK;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [2:0]           inner_AWPROT;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           inner_AWQOS;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 inner_AWREADY;          // From U_AXI4_reg_slice_W of axi4_buf_w.v
   wire [3:0]           inner_AWREGION;         // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [2:0]           inner_AWSIZE;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] inner_AWUSER;      // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 inner_AWVALID;          // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_ID_WIDTH-1:0] inner_BID;           // From U_AXI4_reg_slice_W of axi4_buf_w.v
   wire                 inner_BREADY;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [1:0]           inner_BRESP;            // From U_AXI4_reg_slice_W of axi4_buf_w.v
   wire [AXI_USER_WIDTH-1:0] inner_BUSER;       // From U_AXI4_reg_slice_W of axi4_buf_w.v
   wire                 inner_BVALID;           // From U_AXI4_reg_slice_W of axi4_buf_w.v
   wire [(1<<AXI_P_DW_BYTES)*8-1:0] inner_RDATA;// From U_AXI4_reg_slice_R of axi4_buf_r.v
   wire [AXI_ID_WIDTH-1:0] inner_RID;           // From U_AXI4_reg_slice_R of axi4_buf_r.v
   wire                 inner_RLAST;            // From U_AXI4_reg_slice_R of axi4_buf_r.v
   wire                 inner_RREADY;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [1:0]           inner_RRESP;            // From U_AXI4_reg_slice_R of axi4_buf_r.v
   wire [AXI_USER_WIDTH-1:0] inner_RUSER;       // From U_AXI4_reg_slice_R of axi4_buf_r.v
   wire                 inner_RVALID;           // From U_AXI4_reg_slice_R of axi4_buf_r.v
   wire [(1<<AXI_P_DW_BYTES)*8-1:0] inner_WDATA;// From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 inner_WLAST;            // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 inner_WREADY;           // From U_AXI4_reg_slice_W of axi4_buf_w.v
   wire [(1<<AXI_P_DW_BYTES)-1:0] inner_WSTRB;  // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] inner_WUSER;       // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 inner_WVALID;           // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 tsc_irq;                // From U_CORE of ncpu64k.v
   // End of automatics
   /*AUTOINPUT*/

   // unused
   wire [3:0]           io_master_arcache;      // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 io_master_arlock;       // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [2:0]           io_master_arprot;       // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           io_master_arqos;        // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           io_master_arregion;     // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] io_master_aruser;  // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           io_master_awcache;      // From U_AXI4_ARBITER of axi4_arbiter.v
   wire                 io_master_awlock;       // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [2:0]           io_master_awprot;       // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           io_master_awqos;        // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [3:0]           io_master_awregion;     // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] io_master_awuser;  // From U_AXI4_ARBITER of axi4_arbiter.v
   wire [AXI_USER_WIDTH-1:0] io_master_wuser;   // From U_AXI4_ARBITER of axi4_arbiter.v

   wire                 clk;                    // To U_CORE of ncpu64k.v, ...
   wire                 rst;                    // To U_CORE of ncpu64k.v, ...
   wire  [CONFIG_NUM_IRQ-1:0] irqs;             // To U_CORE of ncpu64k.v
   
   wire  [AXI_ADDR_WIDTH-1:0] ibus_AWADDR;      // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [1:0]          ibus_AWBURST;           // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [3:0]          ibus_AWCACHE;           // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [AXI_ID_WIDTH-1:0] ibus_AWID;          // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [7:0]          ibus_AWLEN;             // To U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_AWLOCK;            // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [2:0]          ibus_AWPROT;            // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [3:0]          ibus_AWQOS;             // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [3:0]          ibus_AWREGION;          // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [2:0]          ibus_AWSIZE;            // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [AXI_USER_WIDTH-1:0] ibus_AWUSER;      // To U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_AWVALID;           // To U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_BREADY;            // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [(1<<AXI_P_DW_BYTES)*8-1:0] ibus_WDATA;// To U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_WLAST;             // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [(1<<AXI_P_DW_BYTES)-1:0] ibus_WSTRB;  // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [AXI_USER_WIDTH-1:0] ibus_WUSER;       // To U_AXI4_ARBITER of axi4_arbiter.v
   wire                 ibus_WVALID;            // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [AXI_USER_WIDTH-1:0] io_master_buser;  // To U_AXI4_ARBITER of axi4_arbiter.v
   wire  [AXI_USER_WIDTH-1:0] io_master_ruser;  // To U_AXI4_ARBITER of axi4_arbiter.v
   
   assign clk = clock;
   assign rst = reset;

   ncpu64k
      #(/*AUTOINSTPARAM*/
        // Parameters
        .CONFIG_AW                      (CONFIG_AW),
        .CONFIG_DW                      (CONFIG_DW),
        .CONFIG_P_DW                    (CONFIG_P_DW),
        .CONFIG_P_FETCH_WIDTH           (CONFIG_P_FETCH_WIDTH),
        .CONFIG_P_ISSUE_WIDTH           (CONFIG_P_ISSUE_WIDTH),
        .CONFIG_P_PAGE_SIZE             (CONFIG_P_PAGE_SIZE),
        .CONFIG_IC_P_LINE               (CONFIG_IC_P_LINE),
        .CONFIG_IC_P_SETS               (CONFIG_IC_P_SETS),
        .CONFIG_IC_P_WAYS               (CONFIG_IC_P_WAYS),
        .CONFIG_DC_P_LINE               (CONFIG_DC_P_LINE),
        .CONFIG_DC_P_SETS               (CONFIG_DC_P_SETS),
        .CONFIG_DC_P_WAYS               (CONFIG_DC_P_WAYS),
        .CONFIG_PHT_P_NUM               (CONFIG_PHT_P_NUM),
        .CONFIG_BTB_P_NUM               (CONFIG_BTB_P_NUM),
        .CONFIG_P_IQ_DEPTH              (CONFIG_P_IQ_DEPTH),
        .CONFIG_ENABLE_ASR              (CONFIG_ENABLE_ASR),
        .CONFIG_IMMU_ENABLE_UNCACHED_SEG(CONFIG_IMMU_ENABLE_UNCACHED_SEG),
        .CONFIG_DMMU_ENABLE_UNCACHED_SEG(CONFIG_DMMU_ENABLE_UNCACHED_SEG),
        .CONFIG_DTLB_P_SETS             (CONFIG_DTLB_P_SETS),
        .CONFIG_ITLB_P_SETS             (CONFIG_ITLB_P_SETS),
        .CONFIG_PC_RST                  (CONFIG_PC_RST[CONFIG_AW-1:0]),
        .CONFIG_EITM_VECTOR             (CONFIG_EITM_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EIPF_VECTOR             (CONFIG_EIPF_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_ESYSCALL_VECTOR         (CONFIG_ESYSCALL_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EINSN_VECTOR            (CONFIG_EINSN_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EIRQ_VECTOR             (CONFIG_EIRQ_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EDTM_VECTOR             (CONFIG_EDTM_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EDPF_VECTOR             (CONFIG_EDPF_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EALIGN_VECTOR           (CONFIG_EALIGN_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_NUM_IRQ                 (CONFIG_NUM_IRQ),
        .CONFIG_P_RS_DEPTH              (CONFIG_P_RS_DEPTH),
        .CONFIG_P_ROB_DEPTH             (CONFIG_P_ROB_DEPTH),
        .AXI_P_DW_BYTES                 (AXI_P_DW_BYTES),
        .AXI_UNCACHED_P_DW_BYTES        (AXI_UNCACHED_P_DW_BYTES),
        .AXI_ADDR_WIDTH                 (AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH                   (AXI_ID_WIDTH),
        .AXI_USER_WIDTH                 (AXI_USER_WIDTH))
   U_CORE
      (/*AUTOINST*/
       // Outputs
       .ibus_ARVALID                    (ibus_ARVALID),
       .ibus_ARADDR                     (ibus_ARADDR[AXI_ADDR_WIDTH-1:0]),
       .ibus_ARPROT                     (ibus_ARPROT[2:0]),
       .ibus_ARID                       (ibus_ARID[AXI_ID_WIDTH-1:0]),
       .ibus_ARUSER                     (ibus_ARUSER[AXI_USER_WIDTH-1:0]),
       .ibus_ARLEN                      (ibus_ARLEN[7:0]),
       .ibus_ARSIZE                     (ibus_ARSIZE[2:0]),
       .ibus_ARBURST                    (ibus_ARBURST[1:0]),
       .ibus_ARLOCK                     (ibus_ARLOCK),
       .ibus_ARCACHE                    (ibus_ARCACHE[3:0]),
       .ibus_ARQOS                      (ibus_ARQOS[3:0]),
       .ibus_ARREGION                   (ibus_ARREGION[3:0]),
       .ibus_RREADY                     (ibus_RREADY),
       .dbus_ARVALID                    (dbus_ARVALID),
       .dbus_ARADDR                     (dbus_ARADDR[AXI_ADDR_WIDTH-1:0]),
       .dbus_ARPROT                     (dbus_ARPROT[2:0]),
       .dbus_ARID                       (dbus_ARID[AXI_ID_WIDTH-1:0]),
       .dbus_ARUSER                     (dbus_ARUSER[AXI_USER_WIDTH-1:0]),
       .dbus_ARLEN                      (dbus_ARLEN[7:0]),
       .dbus_ARSIZE                     (dbus_ARSIZE[2:0]),
       .dbus_ARBURST                    (dbus_ARBURST[1:0]),
       .dbus_ARLOCK                     (dbus_ARLOCK),
       .dbus_ARCACHE                    (dbus_ARCACHE[3:0]),
       .dbus_ARQOS                      (dbus_ARQOS[3:0]),
       .dbus_ARREGION                   (dbus_ARREGION[3:0]),
       .dbus_RREADY                     (dbus_RREADY),
       .dbus_AWVALID                    (dbus_AWVALID),
       .dbus_AWADDR                     (dbus_AWADDR[AXI_ADDR_WIDTH-1:0]),
       .dbus_AWPROT                     (dbus_AWPROT[2:0]),
       .dbus_AWID                       (dbus_AWID[AXI_ID_WIDTH-1:0]),
       .dbus_AWUSER                     (dbus_AWUSER[AXI_USER_WIDTH-1:0]),
       .dbus_AWLEN                      (dbus_AWLEN[7:0]),
       .dbus_AWSIZE                     (dbus_AWSIZE[2:0]),
       .dbus_AWBURST                    (dbus_AWBURST[1:0]),
       .dbus_AWLOCK                     (dbus_AWLOCK),
       .dbus_AWCACHE                    (dbus_AWCACHE[3:0]),
       .dbus_AWQOS                      (dbus_AWQOS[3:0]),
       .dbus_AWREGION                   (dbus_AWREGION[3:0]),
       .dbus_WVALID                     (dbus_WVALID),
       .dbus_WDATA                      (dbus_WDATA[(1<<AXI_P_DW_BYTES)*8-1:0]),
       .dbus_WSTRB                      (dbus_WSTRB[(1<<AXI_P_DW_BYTES)-1:0]),
       .dbus_WLAST                      (dbus_WLAST),
       .dbus_WUSER                      (dbus_WUSER[AXI_USER_WIDTH-1:0]),
       .dbus_BREADY                     (dbus_BREADY),
       .tsc_irq                         (tsc_irq),
       // Inputs
       .clk                             (clk),
       .rst                             (rst),
       .ibus_ARREADY                    (ibus_ARREADY),
       .ibus_RVALID                     (ibus_RVALID),
       .ibus_RDATA                      (ibus_RDATA[(1<<AXI_P_DW_BYTES)*8-1:0]),
       .ibus_RLAST                      (ibus_RLAST),
       .ibus_RRESP                      (ibus_RRESP[1:0]),
       .ibus_RID                        (ibus_RID[AXI_ID_WIDTH-1:0]),
       .ibus_RUSER                      (ibus_RUSER[AXI_USER_WIDTH-1:0]),
       .dbus_ARREADY                    (dbus_ARREADY),
       .dbus_RVALID                     (dbus_RVALID),
       .dbus_RDATA                      (dbus_RDATA[(1<<AXI_P_DW_BYTES)*8-1:0]),
       .dbus_RRESP                      (dbus_RRESP[1:0]),
       .dbus_RLAST                      (dbus_RLAST),
       .dbus_RID                        (dbus_RID[AXI_ID_WIDTH-1:0]),
       .dbus_RUSER                      (dbus_RUSER[AXI_USER_WIDTH-1:0]),
       .dbus_AWREADY                    (dbus_AWREADY),
       .dbus_WREADY                     (dbus_WREADY),
       .dbus_BVALID                     (dbus_BVALID),
       .dbus_BRESP                      (dbus_BRESP[1:0]),
       .dbus_BID                        (dbus_BID[AXI_ID_WIDTH-1:0]),
       .dbus_BUSER                      (dbus_BUSER[AXI_USER_WIDTH-1:0]),
       .irqs                            (irqs[CONFIG_NUM_IRQ-1:0]));

   /* axi4_arbiter AUTO_TEMPLATE(
      .s0_\(.*\) (ibus_\1[]),
      .s1_\(.*\) (dbus_\1[]),
      .m_\(.*\) (inner_@"(substring vl-name 2)"[]),
   ); */
   axi4_arbiter
      #(/*AUTOINSTPARAM*/
        // Parameters
        .AXI_P_DW_BYTES                 (AXI_P_DW_BYTES),
        .AXI_ADDR_WIDTH                 (AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH                   (AXI_ID_WIDTH),
        .AXI_USER_WIDTH                 (AXI_USER_WIDTH))
   U_AXI4_ARBITER
      (/*AUTOINST*/
       // Outputs
       .s0_ARREADY                      (ibus_ARREADY),          // Templated
       .s0_RVALID                       (ibus_RVALID),           // Templated
       .s0_RDATA                        (ibus_RDATA[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .s0_RRESP                        (ibus_RRESP[1:0]),       // Templated
       .s0_RLAST                        (ibus_RLAST),            // Templated
       .s0_RID                          (ibus_RID[AXI_ID_WIDTH-1:0]), // Templated
       .s0_RUSER                        (ibus_RUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s0_AWREADY                      (ibus_AWREADY),          // Templated
       .s0_WREADY                       (ibus_WREADY),           // Templated
       .s0_BVALID                       (ibus_BVALID),           // Templated
       .s0_BRESP                        (ibus_BRESP[1:0]),       // Templated
       .s0_BID                          (ibus_BID[AXI_ID_WIDTH-1:0]), // Templated
       .s0_BUSER                        (ibus_BUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s1_ARREADY                      (dbus_ARREADY),          // Templated
       .s1_RVALID                       (dbus_RVALID),           // Templated
       .s1_RDATA                        (dbus_RDATA[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .s1_RRESP                        (dbus_RRESP[1:0]),       // Templated
       .s1_RLAST                        (dbus_RLAST),            // Templated
       .s1_RID                          (dbus_RID[AXI_ID_WIDTH-1:0]), // Templated
       .s1_RUSER                        (dbus_RUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s1_AWREADY                      (dbus_AWREADY),          // Templated
       .s1_WREADY                       (dbus_WREADY),           // Templated
       .s1_BVALID                       (dbus_BVALID),           // Templated
       .s1_BRESP                        (dbus_BRESP[1:0]),       // Templated
       .s1_BID                          (dbus_BID[AXI_ID_WIDTH-1:0]), // Templated
       .s1_BUSER                        (dbus_BUSER[AXI_USER_WIDTH-1:0]), // Templated
       .m_ARVALID                       (inner_ARVALID),         // Templated
       .m_ARADDR                        (inner_ARADDR[AXI_ADDR_WIDTH-1:0]), // Templated
       .m_ARPROT                        (inner_ARPROT[2:0]),     // Templated
       .m_ARID                          (inner_ARID[AXI_ID_WIDTH-1:0]), // Templated
       .m_ARUSER                        (inner_ARUSER[AXI_USER_WIDTH-1:0]), // Templated
       .m_ARLEN                         (inner_ARLEN[7:0]),      // Templated
       .m_ARSIZE                        (inner_ARSIZE[2:0]),     // Templated
       .m_ARBURST                       (inner_ARBURST[1:0]),    // Templated
       .m_ARLOCK                        (inner_ARLOCK),          // Templated
       .m_ARCACHE                       (inner_ARCACHE[3:0]),    // Templated
       .m_ARQOS                         (inner_ARQOS[3:0]),      // Templated
       .m_ARREGION                      (inner_ARREGION[3:0]),   // Templated
       .m_RREADY                        (inner_RREADY),          // Templated
       .m_AWVALID                       (inner_AWVALID),         // Templated
       .m_AWADDR                        (inner_AWADDR[AXI_ADDR_WIDTH-1:0]), // Templated
       .m_AWPROT                        (inner_AWPROT[2:0]),     // Templated
       .m_AWID                          (inner_AWID[AXI_ID_WIDTH-1:0]), // Templated
       .m_AWUSER                        (inner_AWUSER[AXI_USER_WIDTH-1:0]), // Templated
       .m_AWLEN                         (inner_AWLEN[7:0]),      // Templated
       .m_AWSIZE                        (inner_AWSIZE[2:0]),     // Templated
       .m_AWBURST                       (inner_AWBURST[1:0]),    // Templated
       .m_AWLOCK                        (inner_AWLOCK),          // Templated
       .m_AWCACHE                       (inner_AWCACHE[3:0]),    // Templated
       .m_AWQOS                         (inner_AWQOS[3:0]),      // Templated
       .m_AWREGION                      (inner_AWREGION[3:0]),   // Templated
       .m_WVALID                        (inner_WVALID),          // Templated
       .m_WDATA                         (inner_WDATA[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .m_WSTRB                         (inner_WSTRB[(1<<AXI_P_DW_BYTES)-1:0]), // Templated
       .m_WLAST                         (inner_WLAST),           // Templated
       .m_WUSER                         (inner_WUSER[AXI_USER_WIDTH-1:0]), // Templated
       .m_BREADY                        (inner_BREADY),          // Templated
       // Inputs
       .clk                             (clk),
       .rst                             (rst),
       .s0_ARVALID                      (ibus_ARVALID),          // Templated
       .s0_ARADDR                       (ibus_ARADDR[AXI_ADDR_WIDTH-1:0]), // Templated
       .s0_ARPROT                       (ibus_ARPROT[2:0]),      // Templated
       .s0_ARID                         (ibus_ARID[AXI_ID_WIDTH-1:0]), // Templated
       .s0_ARUSER                       (ibus_ARUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s0_ARLEN                        (ibus_ARLEN[7:0]),       // Templated
       .s0_ARSIZE                       (ibus_ARSIZE[2:0]),      // Templated
       .s0_ARBURST                      (ibus_ARBURST[1:0]),     // Templated
       .s0_ARLOCK                       (ibus_ARLOCK),           // Templated
       .s0_ARCACHE                      (ibus_ARCACHE[3:0]),     // Templated
       .s0_ARQOS                        (ibus_ARQOS[3:0]),       // Templated
       .s0_ARREGION                     (ibus_ARREGION[3:0]),    // Templated
       .s0_RREADY                       (ibus_RREADY),           // Templated
       .s0_AWVALID                      (ibus_AWVALID),          // Templated
       .s0_AWADDR                       (ibus_AWADDR[AXI_ADDR_WIDTH-1:0]), // Templated
       .s0_AWPROT                       (ibus_AWPROT[2:0]),      // Templated
       .s0_AWID                         (ibus_AWID[AXI_ID_WIDTH-1:0]), // Templated
       .s0_AWUSER                       (ibus_AWUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s0_AWLEN                        (ibus_AWLEN[7:0]),       // Templated
       .s0_AWSIZE                       (ibus_AWSIZE[2:0]),      // Templated
       .s0_AWBURST                      (ibus_AWBURST[1:0]),     // Templated
       .s0_AWLOCK                       (ibus_AWLOCK),           // Templated
       .s0_AWCACHE                      (ibus_AWCACHE[3:0]),     // Templated
       .s0_AWQOS                        (ibus_AWQOS[3:0]),       // Templated
       .s0_AWREGION                     (ibus_AWREGION[3:0]),    // Templated
       .s0_WVALID                       (ibus_WVALID),           // Templated
       .s0_WDATA                        (ibus_WDATA[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .s0_WSTRB                        (ibus_WSTRB[(1<<AXI_P_DW_BYTES)-1:0]), // Templated
       .s0_WLAST                        (ibus_WLAST),            // Templated
       .s0_WUSER                        (ibus_WUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s0_BREADY                       (ibus_BREADY),           // Templated
       .s1_ARVALID                      (dbus_ARVALID),          // Templated
       .s1_ARADDR                       (dbus_ARADDR[AXI_ADDR_WIDTH-1:0]), // Templated
       .s1_ARPROT                       (dbus_ARPROT[2:0]),      // Templated
       .s1_ARID                         (dbus_ARID[AXI_ID_WIDTH-1:0]), // Templated
       .s1_ARUSER                       (dbus_ARUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s1_ARLEN                        (dbus_ARLEN[7:0]),       // Templated
       .s1_ARSIZE                       (dbus_ARSIZE[2:0]),      // Templated
       .s1_ARBURST                      (dbus_ARBURST[1:0]),     // Templated
       .s1_ARLOCK                       (dbus_ARLOCK),           // Templated
       .s1_ARCACHE                      (dbus_ARCACHE[3:0]),     // Templated
       .s1_ARQOS                        (dbus_ARQOS[3:0]),       // Templated
       .s1_ARREGION                     (dbus_ARREGION[3:0]),    // Templated
       .s1_RREADY                       (dbus_RREADY),           // Templated
       .s1_AWVALID                      (dbus_AWVALID),          // Templated
       .s1_AWADDR                       (dbus_AWADDR[AXI_ADDR_WIDTH-1:0]), // Templated
       .s1_AWPROT                       (dbus_AWPROT[2:0]),      // Templated
       .s1_AWID                         (dbus_AWID[AXI_ID_WIDTH-1:0]), // Templated
       .s1_AWUSER                       (dbus_AWUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s1_AWLEN                        (dbus_AWLEN[7:0]),       // Templated
       .s1_AWSIZE                       (dbus_AWSIZE[2:0]),      // Templated
       .s1_AWBURST                      (dbus_AWBURST[1:0]),     // Templated
       .s1_AWLOCK                       (dbus_AWLOCK),           // Templated
       .s1_AWCACHE                      (dbus_AWCACHE[3:0]),     // Templated
       .s1_AWQOS                        (dbus_AWQOS[3:0]),       // Templated
       .s1_AWREGION                     (dbus_AWREGION[3:0]),    // Templated
       .s1_WVALID                       (dbus_WVALID),           // Templated
       .s1_WDATA                        (dbus_WDATA[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .s1_WSTRB                        (dbus_WSTRB[(1<<AXI_P_DW_BYTES)-1:0]), // Templated
       .s1_WLAST                        (dbus_WLAST),            // Templated
       .s1_WUSER                        (dbus_WUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s1_BREADY                       (dbus_BREADY),           // Templated
       .m_ARREADY                       (inner_ARREADY),         // Templated
       .m_RVALID                        (inner_RVALID),          // Templated
       .m_RDATA                         (inner_RDATA[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .m_RRESP                         (inner_RRESP[1:0]),      // Templated
       .m_RLAST                         (inner_RLAST),           // Templated
       .m_RID                           (inner_RID[AXI_ID_WIDTH-1:0]), // Templated
       .m_RUSER                         (inner_RUSER[AXI_USER_WIDTH-1:0]), // Templated
       .m_AWREADY                       (inner_AWREADY),         // Templated
       .m_WREADY                        (inner_WREADY),          // Templated
       .m_BVALID                        (inner_BVALID),          // Templated
       .m_BRESP                         (inner_BRESP[1:0]),      // Templated
       .m_BID                           (inner_BID[AXI_ID_WIDTH-1:0]), // Templated
       .m_BUSER                         (inner_BUSER[AXI_USER_WIDTH-1:0])); // Templated

   /* axi4_buf_r AUTO_TEMPLATE(
      .s_\(.*\) (inner_\1[]),
      .m_\(.*\) (io_master_@"(downcase (substring vl-name 2))"[]),
   ); */
   axi4_buf_r
      #(/*AUTOINSTPARAM*/
        // Parameters
        .AXI_P_DW_BYTES                 (AXI_P_DW_BYTES),
        .AXI_ADDR_WIDTH                 (AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH                   (AXI_ID_WIDTH),
        .AXI_USER_WIDTH                 (AXI_USER_WIDTH))
   U_AXI4_reg_slice_R
      (/*AUTOINST*/
       // Outputs
       .s_ARREADY                       (inner_ARREADY),         // Templated
       .s_RVALID                        (inner_RVALID),          // Templated
       .s_RDATA                         (inner_RDATA[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .s_RRESP                         (inner_RRESP[1:0]),      // Templated
       .s_RLAST                         (inner_RLAST),           // Templated
       .s_RID                           (inner_RID[AXI_ID_WIDTH-1:0]), // Templated
       .s_RUSER                         (inner_RUSER[AXI_USER_WIDTH-1:0]), // Templated
       .m_ARVALID                       (io_master_arvalid),     // Templated
       .m_ARADDR                        (io_master_araddr[AXI_ADDR_WIDTH-1:0]), // Templated
       .m_ARPROT                        (io_master_arprot[2:0]), // Templated
       .m_ARID                          (io_master_arid[AXI_ID_WIDTH-1:0]), // Templated
       .m_ARUSER                        (io_master_aruser[AXI_USER_WIDTH-1:0]), // Templated
       .m_ARLEN                         (io_master_arlen[7:0]),  // Templated
       .m_ARSIZE                        (io_master_arsize[2:0]), // Templated
       .m_ARBURST                       (io_master_arburst[1:0]), // Templated
       .m_ARLOCK                        (io_master_arlock),      // Templated
       .m_ARCACHE                       (io_master_arcache[3:0]), // Templated
       .m_ARQOS                         (io_master_arqos[3:0]),  // Templated
       .m_ARREGION                      (io_master_arregion[3:0]), // Templated
       .m_RREADY                        (io_master_rready),      // Templated
       // Inputs
       .clk                             (clk),
       .rst                             (rst),
       .s_ARVALID                       (inner_ARVALID),         // Templated
       .s_ARADDR                        (inner_ARADDR[AXI_ADDR_WIDTH-1:0]), // Templated
       .s_ARPROT                        (inner_ARPROT[2:0]),     // Templated
       .s_ARID                          (inner_ARID[AXI_ID_WIDTH-1:0]), // Templated
       .s_ARUSER                        (inner_ARUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s_ARLEN                         (inner_ARLEN[7:0]),      // Templated
       .s_ARSIZE                        (inner_ARSIZE[2:0]),     // Templated
       .s_ARBURST                       (inner_ARBURST[1:0]),    // Templated
       .s_ARLOCK                        (inner_ARLOCK),          // Templated
       .s_ARCACHE                       (inner_ARCACHE[3:0]),    // Templated
       .s_ARQOS                         (inner_ARQOS[3:0]),      // Templated
       .s_ARREGION                      (inner_ARREGION[3:0]),   // Templated
       .s_RREADY                        (inner_RREADY),          // Templated
       .m_ARREADY                       (io_master_arready),     // Templated
       .m_RVALID                        (io_master_rvalid),      // Templated
       .m_RDATA                         (io_master_rdata[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .m_RRESP                         (io_master_rresp[1:0]),  // Templated
       .m_RLAST                         (io_master_rlast),       // Templated
       .m_RID                           (io_master_rid[AXI_ID_WIDTH-1:0]), // Templated
       .m_RUSER                         (io_master_ruser[AXI_USER_WIDTH-1:0])); // Templated
   
   /* axi4_buf_w AUTO_TEMPLATE(
      .s_\(.*\) (inner_\1[]),
      .m_\(.*\) (io_master_@"(downcase (substring vl-name 2))"[]),
   ); */
   axi4_buf_w
      #(/*AUTOINSTPARAM*/
        // Parameters
        .AXI_P_DW_BYTES                 (AXI_P_DW_BYTES),
        .AXI_ADDR_WIDTH                 (AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH                   (AXI_ID_WIDTH),
        .AXI_USER_WIDTH                 (AXI_USER_WIDTH))
   U_AXI4_reg_slice_W
      (/*AUTOINST*/
       // Outputs
       .s_AWREADY                       (inner_AWREADY),         // Templated
       .s_WREADY                        (inner_WREADY),          // Templated
       .s_BVALID                        (inner_BVALID),          // Templated
       .s_BRESP                         (inner_BRESP[1:0]),      // Templated
       .s_BID                           (inner_BID[AXI_ID_WIDTH-1:0]), // Templated
       .s_BUSER                         (inner_BUSER[AXI_USER_WIDTH-1:0]), // Templated
       .m_AWVALID                       (io_master_awvalid),     // Templated
       .m_AWADDR                        (io_master_awaddr[AXI_ADDR_WIDTH-1:0]), // Templated
       .m_AWPROT                        (io_master_awprot[2:0]), // Templated
       .m_AWID                          (io_master_awid[AXI_ID_WIDTH-1:0]), // Templated
       .m_AWUSER                        (io_master_awuser[AXI_USER_WIDTH-1:0]), // Templated
       .m_AWLEN                         (io_master_awlen[7:0]),  // Templated
       .m_AWSIZE                        (io_master_awsize[2:0]), // Templated
       .m_AWBURST                       (io_master_awburst[1:0]), // Templated
       .m_AWLOCK                        (io_master_awlock),      // Templated
       .m_AWCACHE                       (io_master_awcache[3:0]), // Templated
       .m_AWQOS                         (io_master_awqos[3:0]),  // Templated
       .m_AWREGION                      (io_master_awregion[3:0]), // Templated
       .m_WVALID                        (io_master_wvalid),      // Templated
       .m_WDATA                         (io_master_wdata[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .m_WSTRB                         (io_master_wstrb[(1<<AXI_P_DW_BYTES)-1:0]), // Templated
       .m_WLAST                         (io_master_wlast),       // Templated
       .m_WUSER                         (io_master_wuser[AXI_USER_WIDTH-1:0]), // Templated
       .m_BREADY                        (io_master_bready),      // Templated
       // Inputs
       .clk                             (clk),
       .rst                             (rst),
       .s_AWVALID                       (inner_AWVALID),         // Templated
       .s_AWADDR                        (inner_AWADDR[AXI_ADDR_WIDTH-1:0]), // Templated
       .s_AWPROT                        (inner_AWPROT[2:0]),     // Templated
       .s_AWID                          (inner_AWID[AXI_ID_WIDTH-1:0]), // Templated
       .s_AWUSER                        (inner_AWUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s_AWLEN                         (inner_AWLEN[7:0]),      // Templated
       .s_AWSIZE                        (inner_AWSIZE[2:0]),     // Templated
       .s_AWBURST                       (inner_AWBURST[1:0]),    // Templated
       .s_AWLOCK                        (inner_AWLOCK),          // Templated
       .s_AWCACHE                       (inner_AWCACHE[3:0]),    // Templated
       .s_AWQOS                         (inner_AWQOS[3:0]),      // Templated
       .s_AWREGION                      (inner_AWREGION[3:0]),   // Templated
       .s_WVALID                        (inner_WVALID),          // Templated
       .s_WDATA                         (inner_WDATA[(1<<AXI_P_DW_BYTES)*8-1:0]), // Templated
       .s_WSTRB                         (inner_WSTRB[(1<<AXI_P_DW_BYTES)-1:0]), // Templated
       .s_WLAST                         (inner_WLAST),           // Templated
       .s_WUSER                         (inner_WUSER[AXI_USER_WIDTH-1:0]), // Templated
       .s_BREADY                        (inner_BREADY),          // Templated
       .m_AWREADY                       (io_master_awready),     // Templated
       .m_WREADY                        (io_master_wready),      // Templated
       .m_BVALID                        (io_master_bvalid),      // Templated
       .m_BRESP                         (io_master_bresp[1:0]),  // Templated
       .m_BID                           (io_master_bid[AXI_ID_WIDTH-1:0]), // Templated
       .m_BUSER                         (io_master_buser[AXI_USER_WIDTH-1:0])); // Templated
      
   // ibus is read only
   assign ibus_AWADDR = {AXI_ADDR_WIDTH{1'b0}};
   assign ibus_AWBURST = 2'b0;
   assign ibus_AWCACHE = 4'b0;
   assign ibus_AWID = {AXI_ID_WIDTH{1'b0}};
   assign ibus_AWLEN = 8'b0;
   assign ibus_AWLOCK = 1'b0;
   assign ibus_AWPROT = 3'b0;
   assign ibus_AWQOS = 4'b0;
   assign ibus_AWREGION = 4'b0;
   assign ibus_AWSIZE = 3'b0;
   assign ibus_AWUSER = {AXI_USER_WIDTH{1'b0}};
   assign ibus_AWVALID = 1'b0;
   assign ibus_BREADY = 1'b0;
   assign ibus_WDATA = {(1<<AXI_P_DW_BYTES)*8{1'b0}};
   assign ibus_WLAST = 1'b0;
   assign ibus_WSTRB = {(1<<AXI_P_DW_BYTES){1'b0}};
   assign ibus_WUSER = {AXI_USER_WIDTH{1'b0}};
   assign ibus_WVALID = 1'b0;
   
   // These signals are unsupported by SoC
   assign io_master_buser = {AXI_USER_WIDTH{1'b0}};
   assign io_master_ruser = {AXI_USER_WIDTH{1'b0}};
   
   // Interrupts
   assign irqs[0] = tsc_irq;
   assign irqs[1] = io_interrupt;
   assign irqs[31:2] = 30'b0;
       
   // AXI Slave is unused
   assign io_slave_awready = 1'b0;
	assign io_slave_wready = 1'b0;
	assign io_slave_bvalid = 1'b0;
	assign io_slave_bresp = 2'b0;
	assign io_slave_bid = 4'b0;
	assign io_slave_arready = 1'b0;
	assign io_slave_rvalid = 1'b0;
	assign io_slave_rresp = 2'b0;
	assign io_slave_rdata = 64'b0;
	assign io_slave_rlast = 1'b0;
	assign io_slave_rid = 4'b0;

endmodule

// Local Variables:
// verilog-library-directories:(
//  "."
//  "../../core"
//  "../../fabric"
// )
// End:
