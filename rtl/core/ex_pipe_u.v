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

module ex_pipe_u
#(
   parameter                           CONFIG_AW = 0,
   parameter                           CONFIG_DW = 0,
   parameter                           CONFIG_P_DW = 0,
   parameter                           CONFIG_PHT_P_NUM = 0,
   parameter                           CONFIG_BTB_P_NUM = 0,
   parameter                           CONFIG_ENABLE_MUL = 0,
   parameter                           CONFIG_ENABLE_DIV = 0,
   parameter                           CONFIG_ENABLE_DIVU = 0,
   parameter                           CONFIG_ENABLE_MOD = 0,
   parameter                           CONFIG_ENABLE_MODU = 0,
   parameter                           CONFIG_ENABLE_ASR = 0,
   parameter                           CONFIG_NUM_IRQ = 0,
   parameter                           CONFIG_DC_P_WAYS = 0,
   parameter                           CONFIG_DC_P_SETS = 0,
   parameter                           CONFIG_DC_P_LINE = 0,
   parameter                           CONFIG_P_PAGE_SIZE = 0,
   parameter                           CONFIG_DMMU_ENABLE_UNCACHED_SEG = 0,
   parameter                           CONFIG_ITLB_P_SETS = 0,
   parameter                           CONFIG_DTLB_P_SETS = 0,
   parameter [`EXCP_VECT_W-1:0]        CONFIG_EITM_VECTOR = 0,
   parameter [`EXCP_VECT_W-1:0]        CONFIG_EIPF_VECTOR = 0,
   parameter [`EXCP_VECT_W-1:0]        CONFIG_ESYSCALL_VECTOR = 0,
   parameter [`EXCP_VECT_W-1:0]        CONFIG_EINSN_VECTOR = 0,
   parameter [`EXCP_VECT_W-1:0]        CONFIG_EIRQ_VECTOR = 0,
   parameter [`EXCP_VECT_W-1:0]        CONFIG_EDTM_VECTOR = 0,
   parameter [`EXCP_VECT_W-1:0]        CONFIG_EDPF_VECTOR = 0,
   parameter [`EXCP_VECT_W-1:0]        CONFIG_EALIGN_VECTOR = 0,
   parameter                           AXI_P_DW_BYTES    = 0,
   parameter                           AXI_ADDR_WIDTH    = 0,
   parameter                           AXI_ID_WIDTH      = 0,
   parameter                           AXI_USER_WIDTH    = 0
)
(
   input                               clk,
   input                               rst,
   input                               p_ce_s1,
   input                               p_ce_s2,
   input                               p_ce_s3,
   input                               p_ce_s1_no_icinv_stall,
   input                               flush_s1,
   input                               flush_s2,
   input                               ex_cmt_valid,
   input [`PC_W-1:0]                   ex_npc,
   input                               ex_valid,
   input [`NCPU_ALU_IOPW-1:0]          ex_alu_opc_bus,
   input [`NCPU_LPU_IOPW-1:0]          ex_lpu_opc_bus,
   input [`NCPU_EPU_IOPW-1:0]          ex_epu_opc_bus,
   input [`NCPU_BRU_IOPW-1:0]          ex_bru_opc_bus,
   input [`NCPU_LSU_IOPW-1:0]          ex_lsu_opc_bus,
   input                               ex_bpu_pred_taken,
   input [`PC_W-1:0]                   ex_bpu_pred_tgt,
   input [`PC_W-1:0]                   ex_pc,
   input [CONFIG_DW-1:0]               ex_imm,
   input [CONFIG_DW-1:0]               ex_operand1,
   input [CONFIG_DW-1:0]               ex_operand2,
   input [`NCPU_REG_AW-1:0]            ex_rf_waddr,
   input                               ex_rf_we,
   // To EX
   output                              lsu_stall_req,
   output                              icinv_stall_req,
   output                              se_fail,
   output [`PC_W-1:0]                  se_tgt,
   output                              exc_flush,
   output [`PC_W-1:0]                  exc_flush_tgt,
   output                              b_taken,
   output                              b_cc, b_reg, b_rel,
   // To bypass
   output [CONFIG_DW-1:0]              ro_ex_s1_rf_dout,
   output [CONFIG_DW-1:0]              ro_ex_s2_rf_dout,
   output [CONFIG_DW-1:0]              ro_ex_s3_rf_dout,
   output [CONFIG_DW-1:0]              ro_cmt_rf_wdat,
   output                              ro_ex_s1_rf_we,
   output                              ro_ex_s2_rf_we,
   output                              ro_ex_s3_rf_we,
   output                              ro_cmt_rf_we,
   output [`NCPU_REG_AW-1:0]           ro_ex_s1_rf_waddr,
   output [`NCPU_REG_AW-1:0]           ro_ex_s2_rf_waddr,
   output [`NCPU_REG_AW-1:0]           ro_ex_s3_rf_waddr,
   output [`NCPU_REG_AW-1:0]           ro_cmt_rf_waddr,
   output                              ro_ex_s1_load0,
   output                              ro_ex_s2_load0,
   output                              ro_ex_s3_load0,
   // To commit
   output [CONFIG_DW-1:0]              commit_rf_wdat,
   output [`NCPU_REG_AW-1:0]           commit_rf_waddr,
   output                              commit_rf_we,
   // IRQs
   input [CONFIG_NUM_IRQ-1:0]          irqs,
   output                              irq_async,
   output                              tsc_irq,
   // PSR
   output                              msr_psr_imme,
   output                              msr_psr_rm,
   output                              msr_psr_ice,
   // IMMID
   input [CONFIG_DW-1:0]               msr_immid,
   // ITLBL
   output [CONFIG_ITLB_P_SETS-1:0]     msr_imm_tlbl_idx,
   output [CONFIG_DW-1:0]              msr_imm_tlbl_nxt,
   output                              msr_imm_tlbl_we,
   // ITLBH
   output [CONFIG_ITLB_P_SETS-1:0]     msr_imm_tlbh_idx,
   output [CONFIG_DW-1:0]              msr_imm_tlbh_nxt,
   output                              msr_imm_tlbh_we,
   // ICID
   input [CONFIG_DW-1:0]               msr_icid,
   // ICINV
   output [CONFIG_DW-1:0]              msr_icinv_nxt,
   output                              msr_icinv_we,
   input                               msr_icinv_ready,
   // AXI Master (Cached access)
   input                               dbus_ARREADY,
   output                              dbus_ARVALID,
   output [AXI_ADDR_WIDTH-1:0]         dbus_ARADDR,
   output [2:0]                        dbus_ARPROT,
   output [AXI_ID_WIDTH-1:0]           dbus_ARID,
   output [AXI_USER_WIDTH-1:0]         dbus_ARUSER,
   output [7:0]                        dbus_ARLEN,
   output [2:0]                        dbus_ARSIZE,
   output [1:0]                        dbus_ARBURST,
   output                              dbus_ARLOCK,
   output [3:0]                        dbus_ARCACHE,
   output [3:0]                        dbus_ARQOS,
   output [3:0]                        dbus_ARREGION,

   output                              dbus_RREADY,
   input                               dbus_RVALID,
   input  [(1<<AXI_P_DW_BYTES)*8-1:0]  dbus_RDATA,
   input  [1:0]                        dbus_RRESP,
   input                               dbus_RLAST,
   input  [AXI_ID_WIDTH-1:0]           dbus_RID,
   input  [AXI_USER_WIDTH-1:0]         dbus_RUSER,

   input                               dbus_AWREADY,
   output                              dbus_AWVALID,
   output [AXI_ADDR_WIDTH-1:0]         dbus_AWADDR,
   output [2:0]                        dbus_AWPROT,
   output [AXI_ID_WIDTH-1:0]           dbus_AWID,
   output [AXI_USER_WIDTH-1:0]         dbus_AWUSER,
   output [7:0]                        dbus_AWLEN,
   output [2:0]                        dbus_AWSIZE,
   output [1:0]                        dbus_AWBURST,
   output                              dbus_AWLOCK,
   output [3:0]                        dbus_AWCACHE,
   output [3:0]                        dbus_AWQOS,
   output [3:0]                        dbus_AWREGION,

   input                               dbus_WREADY,
   output                              dbus_WVALID,
   output [(1<<AXI_P_DW_BYTES)*8-1:0]  dbus_WDATA,
   output [(1<<AXI_P_DW_BYTES)-1:0]    dbus_WSTRB,
   output                              dbus_WLAST,
   output [AXI_USER_WIDTH-1:0]         dbus_WUSER,

   output                              dbus_BREADY,
   input                               dbus_BVALID,
   input [1:0]                         dbus_BRESP,
   input [AXI_ID_WIDTH-1:0]            dbus_BID,
   input [AXI_USER_WIDTH-1:0]          dbus_BUSER
);
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [CONFIG_DW-1:0] epu_dout;               // From U_EPU of ex_epu.v
   wire                 epu_dout_valid;         // From U_EPU of ex_epu.v
   wire                 epu_s2i_EALIGN;         // From U_LSU of ex_lsu.v
   wire                 epu_s2i_EDPF;           // From U_LSU of ex_lsu.v
   wire                 epu_s2i_EDTM;           // From U_LSU of ex_lsu.v
   wire [CONFIG_AW-1:0] epu_s2i_vaddr;          // From U_LSU of ex_lsu.v
   wire [CONFIG_DW-1:0] msr_coreid;             // From U_PSR of ex_psr.v
   wire [CONFIG_DW-1:0] msr_cpuid;              // From U_PSR of ex_psr.v
   wire [CONFIG_DW-1:0] msr_dcfls_nxt;          // From U_EPU of ex_epu.v
   wire                 msr_dcfls_we;           // From U_EPU of ex_epu.v
   wire [CONFIG_DW-1:0] msr_dcid;               // From U_LSU of ex_lsu.v
   wire [CONFIG_DW-1:0] msr_dcinv_nxt;          // From U_EPU of ex_epu.v
   wire                 msr_dcinv_we;           // From U_EPU of ex_epu.v
   wire [CONFIG_DTLB_P_SETS-1:0] msr_dmm_tlbh_idx;// From U_EPU of ex_epu.v
   wire [CONFIG_DW-1:0] msr_dmm_tlbh_nxt;       // From U_EPU of ex_epu.v
   wire                 msr_dmm_tlbh_we;        // From U_EPU of ex_epu.v
   wire [CONFIG_DTLB_P_SETS-1:0] msr_dmm_tlbl_idx;// From U_EPU of ex_epu.v
   wire [CONFIG_DW-1:0] msr_dmm_tlbl_nxt;       // From U_EPU of ex_epu.v
   wire                 msr_dmm_tlbl_we;        // From U_EPU of ex_epu.v
   wire [CONFIG_DW-1:0] msr_dmmid;              // From U_LSU of ex_lsu.v
   wire [CONFIG_DW-1:0] msr_elsa;               // From U_PSR of ex_psr.v
   wire [CONFIG_DW-1:0] msr_elsa_nxt;           // From U_EPU of ex_epu.v
   wire                 msr_elsa_we;            // From U_EPU of ex_epu.v
   wire [CONFIG_DW-1:0] msr_epc;                // From U_PSR of ex_psr.v
   wire [CONFIG_DW-1:0] msr_epc_nxt;            // From U_EPU of ex_epu.v
   wire                 msr_epc_we;             // From U_EPU of ex_epu.v
   wire [`NCPU_PSR_DW-1:0] msr_epsr;            // From U_PSR of ex_psr.v
   wire [`NCPU_PSR_DW-1:0] msr_epsr_nxt;        // From U_EPU of ex_epu.v
   wire                 msr_epsr_we;            // From U_EPU of ex_epu.v
   wire [CONFIG_DW-1:0] msr_evect;              // From U_PSR of ex_psr.v
   wire [CONFIG_AW-1:0] msr_evect_nxt;          // From U_EPU of ex_epu.v
   wire                 msr_evect_we;           // From U_EPU of ex_epu.v
   wire [`NCPU_PSR_DW-1:0] msr_psr;             // From U_PSR of ex_psr.v
   wire                 msr_psr_dce;            // From U_PSR of ex_psr.v
   wire                 msr_psr_dce_nxt;        // From U_EPU of ex_epu.v
   wire                 msr_psr_dce_we;         // From U_EPU of ex_epu.v
   wire                 msr_psr_dmme;           // From U_PSR of ex_psr.v
   wire                 msr_psr_dmme_nxt;       // From U_EPU of ex_epu.v
   wire                 msr_psr_dmme_we;        // From U_EPU of ex_epu.v
   wire                 msr_psr_ice_nxt;        // From U_EPU of ex_epu.v
   wire                 msr_psr_ice_we;         // From U_EPU of ex_epu.v
   wire                 msr_psr_imme_nxt;       // From U_EPU of ex_epu.v
   wire                 msr_psr_imme_we;        // From U_EPU of ex_epu.v
   wire                 msr_psr_ire;            // From U_PSR of ex_psr.v
   wire                 msr_psr_ire_nxt;        // From U_EPU of ex_epu.v
   wire                 msr_psr_ire_we;         // From U_EPU of ex_epu.v
   wire                 msr_psr_restore;        // From U_EPU of ex_epu.v
   wire                 msr_psr_rm_nxt;         // From U_EPU of ex_epu.v
   wire                 msr_psr_rm_we;          // From U_EPU of ex_epu.v
   wire                 msr_psr_save;           // From U_EPU of ex_epu.v
   wire [CONFIG_DW*`NCPU_SR_NUM-1:0] msr_sr;    // From U_PSR of ex_psr.v
   wire [CONFIG_DW-1:0] msr_sr_nxt;             // From U_EPU of ex_epu.v
   wire [`NCPU_SR_NUM-1:0] msr_sr_we;           // From U_EPU of ex_epu.v
   // End of automatics
   /*AUTOINPUT*/
   wire [CONFIG_DW-1:0]                bru_dout;
   wire                                bru_dout_valid;
   
   wire                                ex_lsu_load0;
   wire                                add_s;
   wire [CONFIG_DW-1:0]                add_sum;
   wire                                add_carry;
   wire                                add_overflow;
   
   wire [`PC_W-1:0]                    b_tgt;
   
   wire                                agu_en;
   // Stage 1 Input
   wire [CONFIG_DW-1:0]                s1i_rf_dout_1, s1i_rf_dout;
   wire                                s1i_rf_we;
   // Stage 2 Input / Stage 1 Output
   wire [CONFIG_DW-1:0]                s1o_rf_dout;
   wire [`NCPU_REG_AW-1:0]             s1o_rf_waddr;
   wire                                s1o_rf_we;
   wire                                s1o_lsu_load0;
   // Stage 3 Input / Stage 2 Output
   wire [CONFIG_DW-1:0]                s2o_lsu_dout0;
   wire                                s2o_lsu_load0;
   wire [CONFIG_DW-1:0]                s2o_rf_dout;
   wire [`NCPU_REG_AW-1:0]             s2o_rf_waddr;
   wire                                s2o_rf_we;
   wire [CONFIG_DW-1:0]                s3i_rf_wdat;
   genvar i;
   integer j;

   mADD_c_o
      #(.DW(CONFIG_DW))
   U_ADD_AGU
      (
         .a                            (ex_operand1),
         .b                            ((agu_en) ? ex_imm : ex_operand2),
         .s                            (add_s),
         .sum                          (add_sum),
         .carry                        (add_carry),
         .overflow                     (add_overflow)
      );

   ex_alu
      #(/*AUTOINSTPARAM*/
        // Parameters
        .CONFIG_DW                      (CONFIG_DW),
        .CONFIG_ENABLE_MUL              (CONFIG_ENABLE_MUL),
        .CONFIG_ENABLE_DIV              (CONFIG_ENABLE_DIV),
        .CONFIG_ENABLE_DIVU             (CONFIG_ENABLE_DIVU),
        .CONFIG_ENABLE_MOD              (CONFIG_ENABLE_MOD),
        .CONFIG_ENABLE_MODU             (CONFIG_ENABLE_MODU),
        .CONFIG_ENABLE_ASR              (CONFIG_ENABLE_ASR))
   U_ALU
      (
         .ex_alu_opc_bus               (ex_alu_opc_bus),
         .ex_operand1                  (ex_operand1),
         .ex_operand2                  (ex_operand2),
         .add_sum                      (add_sum),
         .alu_result                   (s1i_rf_dout_1)
      );
   
   ex_bru
      #(/*AUTOINSTPARAM*/
        // Parameters
        .CONFIG_DW                      (CONFIG_DW),
        .CONFIG_AW                      (CONFIG_AW))
   U_BRU
      (
         .ex_valid                     (ex_valid),
         .ex_bru_opc_bus               (ex_bru_opc_bus),
         .ex_pc                        (ex_pc),
         .ex_imm                       (ex_imm),
         .ex_operand1                  (ex_operand1),
         .ex_operand2                  (ex_operand2),
         .ex_rf_we                     (ex_rf_we),
         .npc                          (ex_npc),
         .add_sum                      (add_sum),
         .add_carry                    (add_carry),
         .add_overflow                 (add_overflow),
         .b_taken                      (b_taken),
         .b_tgt                        (b_tgt),
         .is_bcc                       (b_cc),
         .is_breg                      (b_reg),
         .is_brel                      (b_rel),
         .bru_dout                     (bru_dout),
         .bru_dout_valid               (bru_dout_valid)
      );

   /* ex_epu AUTO_TEMPLATE (
         .ex_valid         (ex_cmt_valid),
         .ex_pc            (ex_pc[]),
         .ex_npc           (ex_npc[]),
         .ex_epu_opc_bus   (ex_epu_opc_bus[]),
         .ex_operand1      (ex_operand1[]),
         .ex_operand2      (ex_operand2[]),
         .ex_imm           (ex_imm[]),
         .s2i_\(.*\)       (epu_s2i_\1[]),
      ) */
   ex_epu
      #(/*AUTOINSTPARAM*/
        // Parameters
        .CONFIG_DW                      (CONFIG_DW),
        .CONFIG_AW                      (CONFIG_AW),
        .CONFIG_EITM_VECTOR             (CONFIG_EITM_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EIPF_VECTOR             (CONFIG_EIPF_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_ESYSCALL_VECTOR         (CONFIG_ESYSCALL_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EINSN_VECTOR            (CONFIG_EINSN_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EIRQ_VECTOR             (CONFIG_EIRQ_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EDTM_VECTOR             (CONFIG_EDTM_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EDPF_VECTOR             (CONFIG_EDPF_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_EALIGN_VECTOR           (CONFIG_EALIGN_VECTOR[`EXCP_VECT_W-1:0]),
        .CONFIG_ITLB_P_SETS             (CONFIG_ITLB_P_SETS),
        .CONFIG_DTLB_P_SETS             (CONFIG_DTLB_P_SETS),
        .CONFIG_NUM_IRQ                 (CONFIG_NUM_IRQ))
   U_EPU
      (/*AUTOINST*/
       // Outputs
       .epu_dout                        (epu_dout[CONFIG_DW-1:0]),
       .epu_dout_valid                  (epu_dout_valid),
       .exc_flush                       (exc_flush),
       .exc_flush_tgt                   (exc_flush_tgt[`PC_W-1:0]),
       .irq_async                       (irq_async),
       .tsc_irq                         (tsc_irq),
       .msr_psr_rm_nxt                  (msr_psr_rm_nxt),
       .msr_psr_rm_we                   (msr_psr_rm_we),
       .msr_psr_imme_nxt                (msr_psr_imme_nxt),
       .msr_psr_imme_we                 (msr_psr_imme_we),
       .msr_psr_dmme_nxt                (msr_psr_dmme_nxt),
       .msr_psr_dmme_we                 (msr_psr_dmme_we),
       .msr_psr_ire_nxt                 (msr_psr_ire_nxt),
       .msr_psr_ire_we                  (msr_psr_ire_we),
       .msr_psr_ice_nxt                 (msr_psr_ice_nxt),
       .msr_psr_ice_we                  (msr_psr_ice_we),
       .msr_psr_dce_nxt                 (msr_psr_dce_nxt),
       .msr_psr_dce_we                  (msr_psr_dce_we),
       .msr_psr_save                    (msr_psr_save),
       .msr_psr_restore                 (msr_psr_restore),
       .msr_epc_nxt                     (msr_epc_nxt[CONFIG_DW-1:0]),
       .msr_epc_we                      (msr_epc_we),
       .msr_epsr_nxt                    (msr_epsr_nxt[`NCPU_PSR_DW-1:0]),
       .msr_epsr_we                     (msr_epsr_we),
       .msr_elsa_nxt                    (msr_elsa_nxt[CONFIG_DW-1:0]),
       .msr_elsa_we                     (msr_elsa_we),
       .msr_evect_nxt                   (msr_evect_nxt[CONFIG_AW-1:0]),
       .msr_evect_we                    (msr_evect_we),
       .msr_imm_tlbl_idx                (msr_imm_tlbl_idx[CONFIG_ITLB_P_SETS-1:0]),
       .msr_imm_tlbl_nxt                (msr_imm_tlbl_nxt[CONFIG_DW-1:0]),
       .msr_imm_tlbl_we                 (msr_imm_tlbl_we),
       .msr_imm_tlbh_idx                (msr_imm_tlbh_idx[CONFIG_ITLB_P_SETS-1:0]),
       .msr_imm_tlbh_nxt                (msr_imm_tlbh_nxt[CONFIG_DW-1:0]),
       .msr_imm_tlbh_we                 (msr_imm_tlbh_we),
       .msr_dmm_tlbl_idx                (msr_dmm_tlbl_idx[CONFIG_DTLB_P_SETS-1:0]),
       .msr_dmm_tlbl_nxt                (msr_dmm_tlbl_nxt[CONFIG_DW-1:0]),
       .msr_dmm_tlbl_we                 (msr_dmm_tlbl_we),
       .msr_dmm_tlbh_idx                (msr_dmm_tlbh_idx[CONFIG_DTLB_P_SETS-1:0]),
       .msr_dmm_tlbh_nxt                (msr_dmm_tlbh_nxt[CONFIG_DW-1:0]),
       .msr_dmm_tlbh_we                 (msr_dmm_tlbh_we),
       .msr_icinv_nxt                   (msr_icinv_nxt[CONFIG_DW-1:0]),
       .msr_icinv_we                    (msr_icinv_we),
       .msr_dcinv_nxt                   (msr_dcinv_nxt[CONFIG_DW-1:0]),
       .msr_dcinv_we                    (msr_dcinv_we),
       .msr_dcfls_nxt                   (msr_dcfls_nxt[CONFIG_DW-1:0]),
       .msr_dcfls_we                    (msr_dcfls_we),
       .msr_sr_nxt                      (msr_sr_nxt[CONFIG_DW-1:0]),
       .msr_sr_we                       (msr_sr_we[`NCPU_SR_NUM-1:0]),
       // Inputs
       .clk                             (clk),
       .rst                             (rst),
       .flush_s1                        (flush_s1),
       .p_ce_s1                         (p_ce_s1),
       .p_ce_s1_no_icinv_stall          (p_ce_s1_no_icinv_stall),
       .p_ce_s2                         (p_ce_s2),
       .ex_pc                           (ex_pc[`PC_W-1:0]),      // Templated
       .ex_npc                          (ex_npc[`PC_W-1:0]),     // Templated
       .ex_valid                        (ex_cmt_valid),          // Templated
       .ex_epu_opc_bus                  (ex_epu_opc_bus[`NCPU_EPU_IOPW-1:0]), // Templated
       .ex_operand1                     (ex_operand1[CONFIG_DW-1:0]), // Templated
       .ex_operand2                     (ex_operand2[CONFIG_DW-1:0]), // Templated
       .ex_imm                          (ex_imm[CONFIG_DW-1:0]), // Templated
       .s2i_EDTM                        (epu_s2i_EDTM),          // Templated
       .s2i_EDPF                        (epu_s2i_EDPF),          // Templated
       .s2i_EALIGN                      (epu_s2i_EALIGN),        // Templated
       .s2i_vaddr                       (epu_s2i_vaddr[CONFIG_AW-1:0]), // Templated
       .irqs                            (irqs[CONFIG_NUM_IRQ-1:0]),
       .msr_psr                         (msr_psr[`NCPU_PSR_DW-1:0]),
       .msr_psr_ire                     (msr_psr_ire),
       .msr_cpuid                       (msr_cpuid[CONFIG_DW-1:0]),
       .msr_epc                         (msr_epc[CONFIG_DW-1:0]),
       .msr_epsr                        (msr_epsr[`NCPU_PSR_DW-1:0]),
       .msr_elsa                        (msr_elsa[CONFIG_DW-1:0]),
       .msr_evect                       (msr_evect[CONFIG_AW-1:0]),
       .msr_coreid                      (msr_coreid[CONFIG_DW-1:0]),
       .msr_immid                       (msr_immid[CONFIG_DW-1:0]),
       .msr_dmmid                       (msr_dmmid[CONFIG_DW-1:0]),
       .msr_icid                        (msr_icid[CONFIG_DW-1:0]),
       .msr_dcid                        (msr_dcid[CONFIG_DW-1:0]),
       .msr_sr                          (msr_sr[CONFIG_DW*`NCPU_SR_NUM-1:0]));

   // BRU reused the adder of ALU
   assign add_s =
      (
         ex_alu_opc_bus[`NCPU_ALU_SUB] |
         ex_bru_opc_bus[`NCPU_BRU_BEQ] |
         ex_bru_opc_bus[`NCPU_BRU_BNE] |
         ex_bru_opc_bus[`NCPU_BRU_BGTU] |
         ex_bru_opc_bus[`NCPU_BRU_BGT] |
         ex_bru_opc_bus[`NCPU_BRU_BLEU] |
         ex_bru_opc_bus[`NCPU_BRU_BLE]
      );

   // MUX: switch the result of EPU/BRU/ALU (without LSU)
   assign s1i_rf_dout =
      (epu_dout_valid)
         ? epu_dout
         : (bru_dout_valid)
            ? bru_dout
            : s1i_rf_dout_1;


   /* ex_lsu AUTO_TEMPLATE (
         .ex_valid         (ex_cmt_valid),
         .ex_lsu_opc_bus   (ex_lsu_opc_bus[]),
         .add_sum          (add_sum),
         .ex_operand2      (ex_operand2[]),
         .lsu_EDTM         (epu_s2i_EDTM),
         .lsu_EDPF         (epu_s2i_EDPF),
         .lsu_EALIGN       (epu_s2i_EALIGN),
         .lsu_vaddr        (epu_s2i_vaddr[]),
         .lsu_dout         (s2o_lsu_dout0),
      ) */
   ex_lsu
      #(/*AUTOINSTPARAM*/
        // Parameters
        .CONFIG_AW                      (CONFIG_AW),
        .CONFIG_DW                      (CONFIG_DW),
        .CONFIG_P_DW                    (CONFIG_P_DW),
        .CONFIG_P_PAGE_SIZE             (CONFIG_P_PAGE_SIZE),
        .CONFIG_DMMU_ENABLE_UNCACHED_SEG(CONFIG_DMMU_ENABLE_UNCACHED_SEG),
        .CONFIG_DTLB_P_SETS             (CONFIG_DTLB_P_SETS),
        .CONFIG_DC_P_LINE               (CONFIG_DC_P_LINE),
        .CONFIG_DC_P_SETS               (CONFIG_DC_P_SETS),
        .CONFIG_DC_P_WAYS               (CONFIG_DC_P_WAYS),
        .AXI_P_DW_BYTES                 (AXI_P_DW_BYTES),
        .AXI_ADDR_WIDTH                 (AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH                   (AXI_ID_WIDTH),
        .AXI_USER_WIDTH                 (AXI_USER_WIDTH))
   U_LSU
      (/*AUTOINST*/
       // Outputs
       .lsu_stall_req                   (lsu_stall_req),
       .agu_en                          (agu_en),
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
       .lsu_EDTM                        (epu_s2i_EDTM),          // Templated
       .lsu_EDPF                        (epu_s2i_EDPF),          // Templated
       .lsu_EALIGN                      (epu_s2i_EALIGN),        // Templated
       .lsu_vaddr                       (epu_s2i_vaddr[CONFIG_AW-1:0]), // Templated
       .lsu_dout                        (s2o_lsu_dout0),         // Templated
       .msr_dmmid                       (msr_dmmid[CONFIG_DW-1:0]),
       .msr_dcid                        (msr_dcid[CONFIG_DW-1:0]),
       // Inputs
       .clk                             (clk),
       .rst                             (rst),
       .p_ce_s1                         (p_ce_s1),
       .flush_s1                        (flush_s1),
       .ex_valid                        (ex_cmt_valid),          // Templated
       .ex_lsu_opc_bus                  (ex_lsu_opc_bus[`NCPU_LSU_IOPW-1:0]), // Templated
       .add_sum                         (add_sum),               // Templated
       .ex_operand2                     (ex_operand2[CONFIG_DW-1:0]), // Templated
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
       .msr_psr_dmme                    (msr_psr_dmme),
       .msr_psr_rm                      (msr_psr_rm),
       .msr_psr_dce                     (msr_psr_dce),
       .msr_dmm_tlbl_idx                (msr_dmm_tlbl_idx[CONFIG_DTLB_P_SETS-1:0]),
       .msr_dmm_tlbl_nxt                (msr_dmm_tlbl_nxt[CONFIG_DW-1:0]),
       .msr_dmm_tlbl_we                 (msr_dmm_tlbl_we),
       .msr_dmm_tlbh_idx                (msr_dmm_tlbh_idx[CONFIG_DTLB_P_SETS-1:0]),
       .msr_dmm_tlbh_nxt                (msr_dmm_tlbh_nxt[CONFIG_DW-1:0]),
       .msr_dmm_tlbh_we                 (msr_dmm_tlbh_we),
       .msr_dcinv_nxt                   (msr_dcinv_nxt[CONFIG_DW-1:0]),
       .msr_dcinv_we                    (msr_dcinv_we),
       .msr_dcfls_nxt                   (msr_dcfls_nxt[CONFIG_DW-1:0]),
       .msr_dcfls_we                    (msr_dcfls_we));
   
   ex_psr
      #(
        .CONFIG_DW                      (CONFIG_DW),
        .CPUID_VER                      (1),
        .CPUID_REV                      (0),
        .CPUID_FIMM                     (1),
        .CPUID_FDMM                     (1),
        .CPUID_FICA                     (1),
        .CPUID_FDCA                     (1),
        .CPUID_FDBG                     (0),
        .CPUID_FFPU                     (0),
        .CPUID_FIRQC                    (1),
        .CPUID_FTSC                     (1)
     )
   U_PSR
      (/*AUTOINST*/
       // Outputs
       .msr_psr                         (msr_psr[`NCPU_PSR_DW-1:0]),
       .msr_psr_rm                      (msr_psr_rm),
       .msr_psr_ire                     (msr_psr_ire),
       .msr_psr_imme                    (msr_psr_imme),
       .msr_psr_dmme                    (msr_psr_dmme),
       .msr_psr_ice                     (msr_psr_ice),
       .msr_psr_dce                     (msr_psr_dce),
       .msr_cpuid                       (msr_cpuid[CONFIG_DW-1:0]),
       .msr_epsr                        (msr_epsr[`NCPU_PSR_DW-1:0]),
       .msr_epc                         (msr_epc[CONFIG_DW-1:0]),
       .msr_elsa                        (msr_elsa[CONFIG_DW-1:0]),
       .msr_coreid                      (msr_coreid[CONFIG_DW-1:0]),
       .msr_evect                       (msr_evect[CONFIG_DW-1:0]),
       .msr_sr                          (msr_sr[CONFIG_DW*`NCPU_SR_NUM-1:0]),
       // Inputs
       .clk                             (clk),
       .rst                             (rst),
       .msr_psr_save                    (msr_psr_save),
       .msr_psr_restore                 (msr_psr_restore),
       .msr_psr_rm_nxt                  (msr_psr_rm_nxt),
       .msr_psr_rm_we                   (msr_psr_rm_we),
       .msr_psr_ire_nxt                 (msr_psr_ire_nxt),
       .msr_psr_ire_we                  (msr_psr_ire_we),
       .msr_psr_imme_nxt                (msr_psr_imme_nxt),
       .msr_psr_imme_we                 (msr_psr_imme_we),
       .msr_psr_dmme_nxt                (msr_psr_dmme_nxt),
       .msr_psr_dmme_we                 (msr_psr_dmme_we),
       .msr_psr_ice_nxt                 (msr_psr_ice_nxt),
       .msr_psr_ice_we                  (msr_psr_ice_we),
       .msr_psr_dce_nxt                 (msr_psr_dce_nxt),
       .msr_psr_dce_we                  (msr_psr_dce_we),
       .msr_epsr_nxt                    (msr_epsr_nxt[`NCPU_PSR_DW-1:0]),
       .msr_epsr_we                     (msr_epsr_we),
       .msr_epc_nxt                     (msr_epc_nxt[CONFIG_DW-1:0]),
       .msr_epc_we                      (msr_epc_we),
       .msr_elsa_nxt                    (msr_elsa_nxt[CONFIG_DW-1:0]),
       .msr_elsa_we                     (msr_elsa_we),
       .msr_evect_nxt                   (msr_evect_nxt[CONFIG_DW-1:0]),
       .msr_evect_we                    (msr_evect_we),
       .msr_sr_nxt                      (msr_sr_nxt[CONFIG_DW-1:0]),
       .msr_sr_we                       (msr_sr_we[`NCPU_SR_NUM-1:0]));

   assign s1i_rf_we = (ex_cmt_valid & ex_rf_we);

   // MUX for ARF write data
   assign s3i_rf_wdat = (s2o_lsu_load0)
                           ? s2o_lsu_dout0
                           : s2o_rf_dout;

   assign ex_lsu_load0 = ex_lsu_opc_bus[`NCPU_LSU_LOAD];

   // Bypass
   assign ro_ex_s1_rf_dout = s1i_rf_dout;
   assign ro_ex_s2_rf_dout = s1o_rf_dout;
   assign ro_ex_s3_rf_dout = s2o_rf_dout;
   assign ro_cmt_rf_wdat = commit_rf_wdat;
   assign ro_ex_s1_rf_we = s1i_rf_we;
   assign ro_ex_s2_rf_we = s1o_rf_we;
   assign ro_ex_s3_rf_we = s2o_rf_we;
   assign ro_cmt_rf_we = commit_rf_we;
   assign ro_ex_s1_rf_waddr = ex_rf_waddr;
   assign ro_ex_s2_rf_waddr = s1o_rf_waddr;
   assign ro_ex_s3_rf_waddr = s2o_rf_waddr;
   assign ro_cmt_rf_waddr = commit_rf_waddr;
   assign ro_ex_s1_load0 = ex_lsu_load0;
   assign ro_ex_s2_load0 = s1o_lsu_load0;
   assign ro_ex_s3_load0 = s2o_lsu_load0;

   
   // Stall if ICINV is temporarily unavailable during access
   assign icinv_stall_req = (msr_icinv_we & ~msr_icinv_ready);
   
   
   assign se_fail = ex_valid & ((b_taken ^ ex_bpu_pred_taken) | (b_tgt != ex_bpu_pred_tgt)); // FAIL
   //ex_valid[0] & ((b_taken ^ ex_bpu_pred_taken) | (b_taken & (b_tgt != ex_bpu_pred_tgt))); // RIGHT
   assign se_tgt = (b_taken) ? b_tgt : ex_npc;
   
   
   //
   // Pipeline stages
   //
   mDFF_l # (.DW(`NCPU_REG_AW)) ff_s1o_rf_waddr (.CLK(clk), .LOAD(p_ce_s1), .D(ex_rf_waddr), .Q(s1o_rf_waddr) );
   mDFF_lr # (.DW(1)) ff_s1o_rf_we (.CLK(clk), .RST(rst), .LOAD(p_ce_s1|flush_s1), .D(s1i_rf_we & ~flush_s1), .Q(s1o_rf_we) );
   mDFF_l # (.DW(CONFIG_DW)) ff_s1o_rf_dout (.CLK(clk), .LOAD(p_ce_s1), .D(s1i_rf_dout), .Q(s1o_rf_dout) );
   mDFF_lr # (.DW(1)) ff_s1o_lsu_load (.CLK(clk), .RST(rst), .LOAD(p_ce_s1|flush_s1), .D(ex_lsu_load0 & ~flush_s1), .Q(s1o_lsu_load0) );
   
   mDFF_l # (.DW(`NCPU_REG_AW)) ff_s2o_rf_waddr (.CLK(clk), .LOAD(p_ce_s2), .D(s1o_rf_waddr), .Q(s2o_rf_waddr) );
   mDFF_lr # (.DW(1)) ff_s2o_rf_we (.CLK(clk), .RST(rst), .LOAD(p_ce_s2|flush_s2), .D(s1o_rf_we & ~flush_s2), .Q(s2o_rf_we) );
   mDFF_l # (.DW(CONFIG_DW)) ff_s2o_rf_dout (.CLK(clk), .LOAD(p_ce_s2), .D(s1o_rf_dout), .Q(s2o_rf_dout) );
   mDFF_l # (.DW(1)) ff_s2o_lsu_load (.CLK(clk), .LOAD(p_ce_s2), .D(s1o_lsu_load0), .Q(s2o_lsu_load0) );

   mDFF_l # (.DW(`NCPU_REG_AW)) ff_commit_rf_waddr (.CLK(clk), .LOAD(p_ce_s3), .D(s2o_rf_waddr), .Q(commit_rf_waddr) );
   mDFF_lr # (.DW(1)) ff_commit_rf_we (.CLK(clk), .RST(rst), .LOAD(p_ce_s3), .D(s2o_rf_we), .Q(commit_rf_we) );
   mDFF_l # (.DW(CONFIG_DW)) ff_commit_rf_wdat (.CLK(clk), .LOAD(p_ce_s3), .D(s3i_rf_wdat), .Q(commit_rf_wdat) );

endmodule

// Local Variables:
// verilog-library-directories:(
//  "."
//  "../lib"
// )
// End: