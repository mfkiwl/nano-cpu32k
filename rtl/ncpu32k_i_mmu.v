/***************************************************************************/
/*  Nano-cpu 32000 (Scalable Ultra-Low-Power Processor)                    */
/*                                                                         */
/*  Copyright (C) 2019 cassuto <psc-system@outlook.com>, China.            */
/*  This project is free edition; you can redistribute it and/or           */
/*  modify it under the terms of the GNU Lesser General Public             */
/*  License(GPL) as published by the Free Software Foundation; either      */
/*  version 2.1 of the License, or (at your option) any later version.     */
/*                                                                         */
/*  This project is distributed in the hope that it will be useful,        */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of         */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      */
/*  Lesser General Public License for more details.                        */
/***************************************************************************/

`include "ncpu32k_config.h"

module ncpu32k_i_mmu
#(
   parameter TLB_NSETS_LOG2 = 7 // (2^TLB_NSETS_LOG2) entries
)
(
   input                   clk,
   input                   rst_n,
   output                  ibus_dout_valid, /* Insn is presented at immu's output */
   input                   ibus_dout_ready, /* ifu is ready to accepted Insn */
   output [`NCPU_IW-1:0]   ibus_dout,
   output                  ibus_cmd_ready, /* ibus is ready to accept cmd */
   input                   ibus_cmd_valid, /* cmd is presented at ibus'input */
   input [`NCPU_AW-1:0]    ibus_cmd_addr,
   input                   ibus_cmd_flush,
   output                  ibus_flush_ack,
   output [`NCPU_AW-1:0]   ibus_out_id,
   output [`NCPU_AW-1:0]   ibus_out_id_nxt,
   input                   icache_dout_valid, /* Insn is presented at ibus */
   output                  icache_dout_ready, /* ifu is ready to accepted Insn */
   input [`NCPU_IW-1:0]    icache_dout,
   input                   icache_cmd_ready, /* icache is ready to accept cmd */
   output                  icache_cmd_valid, /* cmd is presented at icache's input */
   output [`NCPU_AW-1:0]   icache_cmd_addr,
   output                  exp_imm_tlb_miss,
   output                  exp_imm_page_fault,
   // PSR
   input                   msr_psr_imme,
   input                   msr_psr_rm,
   // IMMID
   output [`NCPU_DW-1:0]   msr_immid,
   // TLBL
   output [`NCPU_DW-1:0]   msr_imm_tlbl,
   input [`NCPU_TLB_AW-1:0] msr_imm_tlbl_idx,
   input [`NCPU_DW-1:0]    msr_imm_tlbl_nxt,
   input                   msr_imm_tlbl_we,
   // TLBH
   output [`NCPU_DW-1:0]   msr_imm_tlbh,
   input [`NCPU_TLB_AW-1:0] msr_imm_tlbh_idx,
   input [`NCPU_DW-1:0]    msr_imm_tlbh_nxt,
   input                   msr_imm_tlbh_we
   
);

   // VPN shift bit
   localparam VPN_SHIFT = 13;
   // PPN shift bit
   localparam PPN_SHIFT = 13;
   // Bitwidth of Virtual Page Number
   localparam VPN_DW = `NCPU_DW-VPN_SHIFT;
   // Bitwidth of Physical Page Number
   localparam PPN_DW = `NCPU_DW-PPN_SHIFT;
   
   localparam CLEAR_ON_INIT = 1;


   // MMU FSM
   wire hds_ibus_cmd;
   wire hds_ibus_dout;
   wire hds_icache_cmd;
   wire icache_cmd_valid_w;
   
   // Cancel the current command request to icache
   // Occurs only if the icache accepts cmd while the output is valid.
   // There is no need to cacnel the dout of the cmd that has been handshaked before
   // this clk.
   ncpu32k_cell_dff_r #(1) dff_flush_ack
                   (clk,rst_n, ibus_cmd_flush & hds_icache_cmd, ibus_flush_ack);
   wire flush_strobe = (ibus_cmd_flush&~ibus_flush_ack);
   
   ncpu32k_cell_pipebuf #(`NCPU_IW) pipebuf_ifu
      (
         .clk        (clk),
         .rst_n      (rst_n),
         .din        (),
         .dout       (),
         .in_valid   (ibus_cmd_valid),
         .in_ready   (ibus_cmd_ready),
         .out_valid  (icache_cmd_valid_w),
         .out_ready  (icache_cmd_ready | flush_strobe),
         .cas        (hds_ibus_cmd)
      );
      
   assign hds_ibus_dout = ibus_dout_valid & ibus_dout_ready;
      
   assign hds_icache_cmd = icache_cmd_valid & icache_cmd_ready;
   
   // Cacnel the cmd request to icache when flushing.
   assign icache_cmd_valid = ~flush_strobe & icache_cmd_valid_w;

   assign icache_dout_ready = ibus_dout_ready;
   
   assign ibus_dout_valid = icache_dout_valid;
   
   assign ibus_dout = icache_dout;
   
   // TLB is to be read
   // When flushing there is no need to handshake with command
   // We assume that such a handshake is always succeeded (03052146)
   wire tlb_read = hds_ibus_cmd | ibus_cmd_flush;

   ////////////////////////////////////////////////////////////////////////////////
   // The following flip-flops are used to maintain the address of the (output-valid) insn
   // dff_id_nxt : Sync address with TLB
   //              (after the cur is sent to TLB, the NEXT insn addr should be is presented at ibus_cmd_addr )
   // dff_id     : Sync address with ibus dout
   //              (after handshaked with ibus dout, the NEXT insn addr is valid at ibus_out_id )
   ////////////////////////////////////////////////////////////////////////////////
   
   // Flush current-insn-PC indicator
   wire [`NCPU_AW-1:0] ibus_out_id_nxt_bypass = ibus_cmd_flush ? ibus_cmd_addr[`NCPU_AW-1:0] : ibus_out_id_nxt[`NCPU_AW-1:0];

   // Transfer when TLB is to be read
   ncpu32k_cell_dff_lr #(`NCPU_AW, `NCPU_ERST_VECTOR-`NCPU_AW'd4) dff_id_nxt
                   (clk,rst_n, tlb_read, ibus_cmd_addr[`NCPU_AW-1:0], ibus_out_id_nxt[`NCPU_AW-1:0]);
   // Transfer when handshaked with downstream module
   ncpu32k_cell_dff_lr #(`NCPU_AW, `NCPU_ERST_VECTOR) dff_id
                   (clk,rst_n, hds_ibus_dout, ibus_out_id_nxt_bypass, ibus_out_id[`NCPU_AW-1:0]);

   ////////////////////////////////////////////////////////////////////////////////

   // MSR.IMMID
   assign msr_immid = {{32-3{1'b0}}, TLB_NSETS_LOG2[2:0]};

   // TLB
   wire msr_psr_imme_r;
   wire msr_psr_rm_r;
   wire [PPN_SHIFT-1:0] tgt_page_offset_r;
   wire [VPN_DW-1:0] tgt_vpn_r;
   wire [`NCPU_DW-1:0] tlb_l_r;
   wire [`NCPU_DW-1:0] tlb_h_r;
   wire [`NCPU_AW-1:0] tlb_dummy_addr;
   wire [`NCPU_AW-1:0] tlb_addr;
   
   wire [PPN_SHIFT-1:0] tgt_page_offset_nxt = ibus_cmd_addr[PPN_SHIFT-1:0];
   wire [VPN_DW-1:0] tgt_vpn_nxt = ibus_cmd_addr[VPN_DW+VPN_SHIFT-1:VPN_SHIFT];
   // Assert (03061058)
   wire [TLB_NSETS_LOG2-1:0] tgt_index_nxt = tgt_vpn_nxt[TLB_NSETS_LOG2-1:0];

   ncpu32k_cell_dff_lr #(1) dff_msr_psr_imme_r
                (clk,rst_n, tlb_read, msr_psr_imme, msr_psr_imme_r);
   ncpu32k_cell_dff_lr #(1) dff_msr_psr_rm_r
                (clk,rst_n, tlb_read, msr_psr_rm, msr_psr_rm_r);
   ncpu32k_cell_dff_lr #(PPN_SHIFT) dff_tgt_page_offset_r
                (clk,rst_n, tlb_read, tgt_page_offset_nxt[PPN_SHIFT-1:0], tgt_page_offset_r[PPN_SHIFT-1:0]);
   ncpu32k_cell_dff_lr #(VPN_DW) dff_tgt_vpn_r
                (clk,rst_n, tlb_read, tgt_vpn_nxt[VPN_DW-1:0], tgt_vpn_r[VPN_DW-1:0]);

   // Dummy TLB (No translation)
   ncpu32k_cell_dff_lr #(`NCPU_AW) dff_tlb
                (clk,rst_n, tlb_read, ibus_cmd_addr[`NCPU_AW-1:0], tlb_dummy_addr[`NCPU_AW-1:0]);
                
                
   // Instance of lowpart TLB
   ncpu32k_cell_tdpram_sclk
      #(
         .AW (TLB_NSETS_LOG2),
         .DW (`NCPU_DW),
         .CLEAR_ON_INIT (CLEAR_ON_INIT)
         )
      tlb_l_sclk
         (
          .clk    (clk),
          .rst_n  (rst_n),
          // Port A
          .addr_a (tgt_index_nxt[TLB_NSETS_LOG2-1:0]),
          .we_a   (1'b0),
          .din_a  (),
          .dout_a (tlb_l_r[`NCPU_DW-1:0]),
          .re_a   (tlb_read),
          // Port B
          .addr_b (msr_imm_tlbl_idx[TLB_NSETS_LOG2-1:0]),
          .we_b   (msr_imm_tlbl_we),
          .din_b  (msr_imm_tlbl_nxt),
          .dout_b (msr_imm_tlbl),
          .re_b   (1'b1)
         );

   // Instance of highpart TLB
   ncpu32k_cell_tdpram_sclk
      #(
         .AW (TLB_NSETS_LOG2),
         .DW (`NCPU_DW),
         .CLEAR_ON_INIT (CLEAR_ON_INIT)
         )
      tlb_h_sclk
         (
          .clk    (clk),
          .rst_n  (rst_n),
          // Port A
          .addr_a (tgt_index_nxt[TLB_NSETS_LOG2-1:0]),
          .we_a   (1'b0),
          .din_a  (),
          .dout_a (tlb_h_r[`NCPU_DW-1:0]),
          .re_a   (tlb_read),
          // Port B
          .addr_b (msr_imm_tlbh_idx[TLB_NSETS_LOG2-1:0]),
          .we_b   (msr_imm_tlbh_we),
          .din_b  (msr_imm_tlbh_nxt),
          .dout_b (msr_imm_tlbh),
          .re_b   (1'b1)
         );
   
   wire tlb_v = tlb_l_r[0];
   wire [VPN_DW-1:0] tlb_vpn = tlb_l_r[`NCPU_DW-1:`NCPU_DW-VPN_DW];
   wire tlb_p = tlb_h_r[0];
   wire tlb_ux = tlb_h_r[3];
   wire tlb_rx = tlb_h_r[4];
   wire tlb_s = tlb_h_r[8];
   wire [PPN_DW-1:0] tlb_ppn = tlb_h_r[`NCPU_DW-1:`NCPU_DW-PPN_DW];
   
   assign perm_denied = ((msr_psr_rm_r & ~tlb_rx) |
                         (~msr_psr_rm_r & ~tlb_ux));
   
   // Permission check, Page Fault exception
   wire exp_imm_page_fault_nxt = perm_denied & msr_psr_imme_r;

   // TLB miss exception
   wire exp_imm_tlb_miss_nxt = ~(tlb_v & tlb_vpn == tgt_vpn_r) & ~perm_denied & msr_psr_imme_r;
   
   ncpu32k_cell_dff_lr #(1) dff_exp_imm_page_fault
                (clk,rst_n, hds_icache_cmd, exp_imm_page_fault_nxt, exp_imm_page_fault);
   ncpu32k_cell_dff_lr #(1) dff_exp_imm_tlb_miss
                (clk,rst_n, hds_icache_cmd, exp_imm_tlb_miss_nxt, exp_imm_tlb_miss);
   
   assign tlb_addr = {tlb_ppn[PPN_DW-1:0], tgt_page_offset_r[PPN_SHIFT-1:0]};

   assign icache_cmd_addr =
      (
         // IMMU is enabled and TLB hit (speculative exec exception to flush TLB)
         msr_psr_imme_r ? tlb_addr
         // IMMU is disabled
         : tlb_dummy_addr
      );
   
   // Assertion (03052146)
`ifdef NCPU_ENABLE_ASSERT
   always @(posedge clk) begin
      if(ibus_cmd_flush & ~hds_ibus_cmd)
         $fatal (0, "\n ibus cmd port should be handshaked when flushing.\n");
   end
`endif

   // Assertion (03061058)
`ifdef NCPU_ENABLE_ASSERT
   initial begin
      if (!(TLB_NSETS_LOG2 <= VPN_DW)) begin
         $fatal (0, "\n TLB_NSETS_LOG2 should <= VPN_DW\n");
      end
   end
`endif

   // Assertions
`ifdef NCPU_ENABLE_ASSERT
   always @(posedge clk) begin
      if ((exp_imm_tlb_miss|exp_imm_page_fault) &
           ~(exp_imm_tlb_miss^exp_imm_page_fault))
         $fatal ("\n EITM and EIPF should be mutex\n");
   end
`endif


endmodule
