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

`include "ncpu64k_config.vh"

module id
#(
   parameter                           CONFIG_AW = 0,
   parameter                           CONFIG_DW = 0,
   parameter                           CONFIG_P_ISSUE_WIDTH = 0,
   parameter                           CONFIG_PHT_P_NUM = 0,
   parameter                           CONFIG_BTB_P_NUM = 0,
   parameter                           CONFIG_ENABLE_MUL = 0,
   parameter                           CONFIG_ENABLE_DIV = 0,
   parameter                           CONFIG_ENABLE_DIVU = 0,
   parameter                           CONFIG_ENABLE_MOD = 0,
   parameter                           CONFIG_ENABLE_MODU = 0,
   parameter                           CONFIG_ENABLE_ASR = 0
)
(
   input                               clk,
   input                               rst,
   input                               flush,
   input                               stall,
   // From frontend
   input [(1<<CONFIG_P_ISSUE_WIDTH)-1:0] id_valid,
   output [CONFIG_P_ISSUE_WIDTH:0]      id_pop_cnt,
   input [`NCPU_INSN_DW * (1<<CONFIG_P_ISSUE_WIDTH)-1:0] id_ins,
   input [`PC_W * (1<<CONFIG_P_ISSUE_WIDTH)-1:0] id_pc,
   input [`FNT_EXC_W * (1<<CONFIG_P_ISSUE_WIDTH)-1:0] id_exc,
   input [`BPU_UPD_W * (1<<CONFIG_P_ISSUE_WIDTH)-1:0] id_bpu_upd,
   // IRQ
   input                               irq_async,
   // To EX
   output [(1<<CONFIG_P_ISSUE_WIDTH)-1:0]                ex_valid,
   output [`NCPU_ALU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_alu_opc_bus,
   output [`NCPU_LPU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_lpu_opc_bus,
   output [`NCPU_EPU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_epu_opc_bus,
   output [`NCPU_BRU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_bru_opc_bus,
   output [`NCPU_LSU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_lsu_opc_bus,
   output [`BPU_UPD_W*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_bpu_upd,
   output [`PC_W*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_pc,
   output [CONFIG_DW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_imm,
   output [CONFIG_DW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_operand1,
   output [CONFIG_DW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_operand2,
   output [`NCPU_REG_AW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_rf_waddr,
   output [(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ex_rf_we,
   // RO
   input [CONFIG_DW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ro_ex_s1_rf_dout,
   input [CONFIG_DW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ro_ex_s2_rf_dout,
   input [CONFIG_DW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ro_ex_s3_rf_wdat,
   input [(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ro_ex_s1_rf_we,
   input [(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ro_ex_s2_rf_we,
   input [(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ro_ex_s3_rf_we,
   input [`NCPU_REG_AW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ro_ex_s1_rf_waddr,
   input [`NCPU_REG_AW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ro_ex_s2_rf_waddr,
   input [`NCPU_REG_AW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] ro_ex_s3_rf_waddr,
   input ro_ex_s1_load0,
   input ro_ex_s2_load0,
   // Regfile
   output [(1<<CONFIG_P_ISSUE_WIDTH)*2-1:0] arf_RE,
   output [(1<<CONFIG_P_ISSUE_WIDTH)*2*`NCPU_REG_AW-1:0] arf_RADDR,
   input [(1<<CONFIG_P_ISSUE_WIDTH)*2*CONFIG_DW-1:0] arf_RDATA
);
   localparam IW                       = (1<<CONFIG_P_ISSUE_WIDTH);
   
   wire                                p_ce;
   reg [IW-1:0]                        valid_msk;
   wire [IW-1:0]                       valid;
   wire [IW-1:0]                       single_fu;
   reg [IW-1:0]                        raw_dep;
   wire [`NCPU_ALU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] s1i_alu_opc_bus;
   wire [`NCPU_LPU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] s1i_lpu_opc_bus;
   wire [`NCPU_EPU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] s1i_epu_opc_bus;
   wire [`NCPU_BRU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] s1i_bru_opc_bus;
   wire [`NCPU_LSU_IOPW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] s1i_lsu_opc_bus;
   wire [CONFIG_DW*(1<<CONFIG_P_ISSUE_WIDTH)-1:0] s1i_imm;
   wire [IW-1:0]                       rf_we;
   wire [`NCPU_REG_AW*IW-1:0]          rf_waddr;
   wire [IW-1:0]                       rf_rs1_re;
   wire [`NCPU_REG_AW-1:0]             rf_rs1_addr                   [IW-1:0];
   wire [IW-1:0]                       rf_rs2_re;
   wire [`NCPU_REG_AW-1:0]             rf_rs2_addr                   [IW-1:0];
   wire [IW-1:0]                       s1o_rf_rs2_re;
   wire [CONFIG_DW*2*IW-1:0]           byp_dout;
   wire [CONFIG_DW-1:0]                rop1                          [IW-1:0];
   wire [CONFIG_DW-1:0]                rop2                          [IW-1:0];
   wire [2*IW-1:0]                     raw_dep_load0;
   genvar i;
   integer j, k;
   
   generate
      for(i=0;i<IW;i=i+1)
         begin : gen_dec
            id_dec
               #(/*AUTOINSTPARAM*/
                 // Parameters
                 .CONFIG_AW             (CONFIG_AW),
                 .CONFIG_DW             (CONFIG_DW),
                 .CONFIG_ENABLE_MUL     (CONFIG_ENABLE_MUL),
                 .CONFIG_ENABLE_DIV     (CONFIG_ENABLE_DIV),
                 .CONFIG_ENABLE_DIVU    (CONFIG_ENABLE_DIVU),
                 .CONFIG_ENABLE_MOD     (CONFIG_ENABLE_MOD),
                 .CONFIG_ENABLE_MODU    (CONFIG_ENABLE_MODU),
                 .CONFIG_ENABLE_ASR     (CONFIG_ENABLE_ASR))
            U_DEC
               (
                  .id_valid            (id_valid[i]),
                  .id_ins              (id_ins[i*`NCPU_INSN_DW +: `NCPU_INSN_DW]),
                  .id_exc              (id_exc[i*`FNT_EXC_W +: `FNT_EXC_W]),
                  .irq_async           (irq_async),
                  .single_fu           (single_fu[i]),
                  
                  .alu_opc_bus         (s1i_alu_opc_bus[i*`NCPU_ALU_IOPW +: `NCPU_ALU_IOPW]),
                  .lpu_opc_bus         (s1i_lpu_opc_bus[i*`NCPU_LPU_IOPW +: `NCPU_LPU_IOPW]),
                  .epu_opc_bus         (s1i_epu_opc_bus[i*`NCPU_EPU_IOPW +: `NCPU_EPU_IOPW]),
                  .bru_opc_bus         (s1i_bru_opc_bus[i*`NCPU_BRU_IOPW +: `NCPU_BRU_IOPW]),
                  .lsu_opc_bus         (s1i_lsu_opc_bus[i*`NCPU_LSU_IOPW +: `NCPU_LSU_IOPW]),
                  .imm                 (s1i_imm[i*CONFIG_DW +: CONFIG_DW]),
                  .rf_we               (rf_we[i]),
                  .rf_waddr            (rf_waddr[i*`NCPU_REG_AW +:`NCPU_REG_AW ]),
                  .rf_rs1_re           (rf_rs1_re[i]),
                  .rf_rs1_addr         (rf_rs1_addr[i]),
                  .rf_rs2_re           (rf_rs2_re[i]),
                  .rf_rs2_addr         (rf_rs2_addr[i])
               );
         end
   endgenerate
   
   // Detect RAW hazard in the issue window
   always @(*)
      for(k=0;k<IW;k=k+1)
         begin
            raw_dep[k] = (raw_dep_load0[(k<<1)] | raw_dep_load0[(k<<1)+1]);
            for(j=0;j<k;j=j+1)
               raw_dep[k] = raw_dep[k] | (rf_we[j] &
                                          ((rf_rs1_re[k] & (rf_rs1_addr[k]==rf_waddr[j*`NCPU_REG_AW +:`NCPU_REG_AW ])) |
                                             (rf_rs2_re[k] & (rf_rs2_addr[k]==rf_waddr[j*`NCPU_REG_AW +:`NCPU_REG_AW ]))));
         end
   
   always @(*)
      begin
         valid_msk[0] = ~raw_dep[0];
         for(j=1;j<IW;j=j+1)
            valid_msk[j] = valid_msk[j-1] & ~single_fu[j] & ~raw_dep[j];
      end
      
   // Issue NOPs if RO is not ready.
   assign valid = (valid_msk & id_valid);
   
   // Count the number of inst that will be issued
   popcnt #(.DW(IW), .P_DW(CONFIG_P_ISSUE_WIDTH)) U_CLO (.bitmap(valid & {IW{p_ce}}), .count(id_pop_cnt) );

   assign p_ce = (~stall);
   
   id_ro
      #(/*AUTOINSTPARAM*/
        // Parameters
        .CONFIG_AW                      (CONFIG_AW),
        .CONFIG_DW                      (CONFIG_DW),
        .CONFIG_P_ISSUE_WIDTH           (CONFIG_P_ISSUE_WIDTH))
   U_RO
      (
         .clk        (clk),
         .ro_ex_s1_rf_dout    (ro_ex_s1_rf_dout),
         .ro_ex_s2_rf_dout    (ro_ex_s2_rf_dout),
         .ro_ex_s3_rf_wdat    (ro_ex_s3_rf_wdat),
         .ro_ex_s1_rf_we      (ro_ex_s1_rf_we),
         .ro_ex_s2_rf_we      (ro_ex_s2_rf_we),
         .ro_ex_s3_rf_we      (ro_ex_s3_rf_we),
         .ro_ex_s1_rf_waddr   (ro_ex_s1_rf_waddr),
         .ro_ex_s2_rf_waddr   (ro_ex_s2_rf_waddr),
         .ro_ex_s3_rf_waddr   (ro_ex_s3_rf_waddr),
         .ro_ex_s1_load0      (ro_ex_s1_load0),
         .ro_ex_s2_load0      (ro_ex_s2_load0),
         .raddr               (arf_RADDR),
         .re                  (arf_RE),
         .rf_din              (arf_RDATA),
         .byp_dout            (byp_dout),
         .raw_dep_load0       (raw_dep_load0)
      );
   
   // Read the operand from ARF
   // ARF has 1 cycle latency before output the result
   generate
      for(i=0;i<IW;i=i+1)
         begin
            assign arf_RE[(i<<1)] = (p_ce & rf_rs1_re[i]);
            assign arf_RE[(i<<1)+1] = (p_ce & rf_rs2_re[i]);
            assign arf_RADDR[(i<<1)*`NCPU_REG_AW +: `NCPU_REG_AW] = rf_rs1_addr[i];
            assign arf_RADDR[((i<<1)+1)*`NCPU_REG_AW +: `NCPU_REG_AW] = rf_rs2_addr[i];
            
            assign rop1[i] = byp_dout[(i<<1)*CONFIG_DW +: CONFIG_DW];
            assign rop2[i] = byp_dout[((i<<1)+1)*CONFIG_DW +: CONFIG_DW];
            
            assign ex_operand1[i*CONFIG_DW +: CONFIG_DW] = rop1[i];
            assign ex_operand2[i*CONFIG_DW +: CONFIG_DW] = (s1o_rf_rs2_re[i]) ? rop2[i] : ex_imm[i*CONFIG_DW +: CONFIG_DW];
         end
   endgenerate
   
   //
   // Pipeline stage
   //
   mDFF_lr # (.DW(IW)) ff_ex_valid (.CLK(clk), .RST(rst), .LOAD(p_ce|flush), .D(valid & {IW{~flush}}), .Q(ex_valid) );
   mDFF_l # (.DW(`NCPU_ALU_IOPW*IW)) ff_ex_alu_opc_bus (.CLK(clk), .LOAD(p_ce), .D(s1i_alu_opc_bus), .Q(ex_alu_opc_bus) );
   mDFF_l # (.DW(`NCPU_LPU_IOPW*IW)) ff_ex_lpu_opc_bus (.CLK(clk), .LOAD(p_ce), .D(s1i_lpu_opc_bus), .Q(ex_lpu_opc_bus) );
   mDFF_l # (.DW(`NCPU_EPU_IOPW*IW)) ff_ex_epu_opc_bus (.CLK(clk), .LOAD(p_ce), .D(s1i_epu_opc_bus), .Q(ex_epu_opc_bus) );
   mDFF_l # (.DW(`NCPU_BRU_IOPW*IW)) ff_ex_bru_opc_bus (.CLK(clk), .LOAD(p_ce), .D(s1i_bru_opc_bus), .Q(ex_bru_opc_bus) );
   mDFF_l # (.DW(`NCPU_LSU_IOPW*IW)) ff_ex_lsu_opc_bus (.CLK(clk), .LOAD(p_ce), .D(s1i_lsu_opc_bus), .Q(ex_lsu_opc_bus) );
   mDFF_l # (.DW(`BPU_UPD_W*IW)) ff_ex_bpu_upd (.CLK(clk), .LOAD(p_ce), .D(id_bpu_upd), .Q(ex_bpu_upd) );
   mDFF_l # (.DW(`PC_W*IW)) ff_ex_pc (.CLK(clk), .LOAD(p_ce), .D(id_pc), .Q(ex_pc) );
   mDFF_l # (.DW(CONFIG_DW*IW)) ff_ex_imm (.CLK(clk), .LOAD(p_ce), .D(s1i_imm), .Q(ex_imm) );
   mDFF_l # (.DW(IW)) ff_s1o_rf_rs2_re (.CLK(clk), .LOAD(p_ce), .D(rf_rs2_re), .Q(s1o_rf_rs2_re) );
   mDFF_l # (.DW(IW)) ff_ex_rf_we (.CLK(clk), .LOAD(p_ce), .D(rf_we), .Q(ex_rf_we) );
   mDFF_l # (.DW(`NCPU_REG_AW*IW)) ff_ex_rf_waddr (.CLK(clk), .LOAD(p_ce), .D(rf_waddr), .Q(ex_rf_waddr) );
   
endmodule