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

`ifndef _NCPU32K_CONFIG_H
`define _NCPU32K_CONFIG_H

/////////////////////////////////////////////////////////////////////////////
// Configure VIRT Instructions
/////////////////////////////////////////////////////////////////////////////

`define ENABLE_ASR
`define ENABLE_ADD
`define ENABLE_SUB
//`define ENABLE_MUL
//`define ENABLE_DIV
//`define ENABLE_DIVU
//`define ENABLE_MOD
//`define ENABLE_MODU
`define ENABLE_LDB
`define ENABLE_LDBU
`define ENABLE_LDH
`define ENABLE_LDHU
`define ENABLE_STB
`define ENABLE_STH
`define ENABLE_MHI


/////////////////////////////////////////////////////////////////////////////
// Configure I/D Cache
/////////////////////////////////////////////////////////////////////////////

//`define NCPU_ENABLE_ICACHE
//`define NCPU_ENABLE_DCACHE

/////////////////////////////////////////////////////////////////////////////
// Configure Asertions
/////////////////////////////////////////////////////////////////////////////

`define NCPU_ENABLE_ASSERT

/////////////////////////////////////////////////////////////////////////////
// Configure Pipeline
/////////////////////////////////////////////////////////////////////////////

// bypass handshake signal of Pipeline buffer
// 1 = Enabled
// 0 = Disabled : This will insert a register between the long ready-valid chain,
//                which is helpful for timing optimization.
`define NCPU_PIPEBUF_BYPASS 1


/////////////////////////////////////////////////////////////////////////////
// Design Constants
/////////////////////////////////////////////////////////////////////////////


// Data Operand Bitwidth
`define NCPU_DW 32
// Address Bus Bitwidth (<= DW)
`define NCPU_AW 32

// Single instruction Bitwidth
`define NCPU_IW 32

// Regfile address Bitwidth
`define NCPU_REG_AW 5

// Number of IRQ lines
`define NCPU_NIRQ 32


/////////////////////////////////////////////////////////////////////////////
// MSR
/////////////////////////////////////////////////////////////////////////////

// PSR register Bitwidth
`define NCPU_PSR_DW 10
// TLB register address Bitwidth
`define NCPU_TLB_AW 7

`define NCPU_MSR_BANK_OFF_AW 9
`define NCPU_MSR_BANK_AW (14-9) // 14 is imm14 bitwidth

// MSR Banks
`define NCPU_MSR_BANK_PS	0
`define NCPU_MSR_BANK_IMM	1
`define NCPU_MSR_BANK_DMM	2
`define NCPU_MSR_BANK_ICA	3
`define NCPU_MSR_BANK_DCA	4
`define NCPU_MSR_BANK_DBG	5
`define NCPU_MSR_BANK_IRQC	6
`define NCPU_MSR_BANK_TSC	7

//
// PS (One-hot encoding)
//

// PS - PSR
`define NCPU_MSR_PSR	0
// PS - CPUID
`define NCPU_MSR_CPUID 1
// PS - EPSR
`define NCPU_MSR_EPSR 2
// PS - EPC
`define NCPU_MSR_EPC	3
// PS - ELSA
`define NCPU_MSR_ELSA 4
// PS.COREID
`define NCPU_MSR_COREID 5

//
// IMM
//

// IMM TLB (8th bit = TLB sel)
`define NCPU_MSR_IMM_TLBSEL 8
// TLBH (7th bit = TLBH sel)
`define NCPU_MSR_IMM_TLBH_SEL 7

//
// DMM
//

// DMM TLB (8th bit = TLB sel)
`define NCPU_MSR_DMM_TLBSEL 8
// TLBH (7th bit = TLBH sel)
`define NCPU_MSR_DMM_TLBH_SEL 7

//
// IRQC (One-hot encoding)
//
`define NCPU_MSR_IRQC_IMR 0
`define NCPU_MSR_IRQC_IRR 1

//
// TSC
//
`define NCPU_MSR_TSC_TSR 0
`define NCPU_MSR_TSC_TCR 1

`define NCPU_TSC_CNT_DW 28
`define NCPU_MSR_TSC_TCR_EN 28
`define NCPU_MSR_TSC_TCR_I 29
`define NCPU_MSR_TSC_TCR_P 30
`define NCPU_MSR_TSC_TCR_RB1 31

/////////////////////////////////////////////////////////////////////////////
// Exception Vector Table
/////////////////////////////////////////////////////////////////////////////
`define NCPU_ERST_VECTOR 8'h0
`define NCPU_EINSN_VECTOR 8'h4
`define NCPU_EIRQ_VECTOR 8'h8
`define NCPU_ESYSCALL_VECTOR 8'hc
`define NCPU_EBUS_VECTOR 8'h10
`define NCPU_EIPF_VECTOR 8'h14
`define NCPU_EDPF_VECTOR 8'h18
`define NCPU_EITM_VECTOR 8'h1c
`define NCPU_EDTM_VECTOR 8'h20
`define NCPU_EALGIN_VECTOR 8'h24
`define NCPU_EINT_VECTOR 8'h28

`define NCPU_VECT_DW 8

/////////////////////////////////////////////////////////////////////////////
// ISA GROUP - BASE
/////////////////////////////////////////////////////////////////////////////
`define NCPU_OP_AND 6'h0
`define NCPU_OP_AND_I 6'h1
`define NCPU_OP_OR 6'h2
`define NCPU_OP_OR_I 6'h3
`define NCPU_OP_XOR 6'h4
`define NCPU_OP_XOR_I 6'h5
`define NCPU_OP_LSL 6'h6
`define NCPU_OP_LSL_I 6'h7
`define NCPU_OP_LSR 6'h8
`define NCPU_OP_LSR_I 6'h9
`define NCPU_OP_JMP 6'ha
`define NCPU_OP_JMP_I 6'hb
`define NCPU_OP_CMP 6'hc
`define NCPU_OP_BT 6'hd
`define NCPU_OP_BF 6'he
`define NCPU_OP_LDWU 6'hf
`define NCPU_OP_STW 6'h10
`define NCPU_OP_MBARR 6'h11
`define NCPU_OP_SYSCALL 6'h12
`define NCPU_OP_RET 6'h13
`define NCPU_OP_WMSR 6'h14
`define NCPU_OP_RMSR 6'h15
`define NCPU_OP_VENTER 6'h16
`define NCPU_OP_VLEAVE 6'h17
`define NCPU_OP_JMP_LNK_I 6'h18

/////////////////////////////////////////////////////////////////////////////
// ISA GROUP - VIRT:
/////////////////////////////////////////////////////////////////////////////
`define NCPU_OP_ASR 6'h1a
`define NCPU_OP_ASR_I 6'h1b
`define NCPU_OP_ADD 6'h1c
`define NCPU_OP_ADD_I 6'h1d
`define NCPU_OP_SUB 6'h1e
`define NCPU_OP_MUL 6'h1f
`define NCPU_OP_DIV 6'h20
`define NCPU_OP_DIVU 6'h21
`define NCPU_OP_MOD 6'h22
`define NCPU_OP_MODU 6'h23
`define NCPU_OP_LDB 6'h24
`define NCPU_OP_LDBU 6'h25
`define NCPU_OP_LDH 6'h26
`define NCPU_OP_LDHU 6'h27
`define NCPU_OP_STB 6'h28
`define NCPU_OP_STH 6'h29
`define NCPU_OP_MHI 6'h2a
`define NCPU_OP_FADDS 6'h2b
`define NCPU_OP_FSUBS 6'h2c
`define NCPU_OP_FMULS 6'h2d
`define NCPU_OP_FDIVS 6'h2e
`define NCPU_OP_FCMPS 6'h2f
`define NCPU_OP_FITFS 6'h30
`define NCPU_OP_FFTIS 6'h31

`define NCPU_ATTR_EQ 8'd0
`define NCPU_ATTR_GT 8'd1
`define NCPU_ATTR_GTU 8'd2

/////////////////////////////////////////////////////////////////////////////
// Internal OPC
/////////////////////////////////////////////////////////////////////////////

`define NCPU_LU_IOPW 6 // One-hot Insn Opocde Bitwidth
`define NCPU_LU_AND 0
`define NCPU_LU_OR 1
`define NCPU_LU_XOR 2
`define NCPU_LU_LSL 3
`define NCPU_LU_LSR 4
`define NCPU_LU_ASR 5

`define NCPU_AU_IOPW 9 // One-hot Insn Opocde Bitwidth
`define NCPU_AU_CMP 0
`define NCPU_AU_ADD 1
`define NCPU_AU_SUB 2
`define NCPU_AU_MUL 3
`define NCPU_AU_DIV 4
`define NCPU_AU_DIVU 5
`define NCPU_AU_MOD 6
`define NCPU_AU_MODU 7
`define NCPU_AU_MHI 8

`define NCPU_EU_IOPW 2 // One-hot Insn Opocde Bitwidth
`define NCPU_EU_WMSR 0
`define NCPU_EU_RMSR 1

`define NCPU_REGNO_LNK 1 // the only one machine-dependent register


`endif // _NCPU32K_CONFIG_H
