`ifndef NCPU64K_CONFIG_H_
`define NCPU64K_CONFIG_H_

/* Synthesis switch */
//`define SYNTHESIS

/* Asynchronous/synchronous reset */
//`define NCPU_RST_ASYNC
`undef NCPU_RST_ASYNC

/* Reset Polarity */
`define NCPU_RST_POS_POLARITY
//`undef NCPU_RST_POS_POLARITY

/* Assert in simulation */
`define NCPU_ENABLE_ASSERT
//`undef NCPU_ENABLE_ASSERT

/* Check X state in simulation */
//`define NCPU_CHECK_X
`undef NCPU_CHECK_X

/* Length of a insn */
`define NCPU_P_INSN_LEN 2 /* $clog2(4) */
`define NCPU_INSN_LEN (`NCPU_P_INSN_LEN<<1)
`define NCPU_INSN_DW (`NCPU_INSN_LEN*8)

/* Use technology library */
//`define NCPU_USE_TECHLIB
`undef NCPU_USE_TECHLIB

/* AXI Definitions */
/* Burst types */
`define AXI_BURST_TYPE_FIXED                                2'b00
`define AXI_BURST_TYPE_INCR                                 2'b01
`define AXI_BURST_TYPE_WRAP                                 2'b10
/* Access permissions */
`define AXI_PROT_UNPRIVILEGED_ACCESS                        3'b000
`define AXI_PROT_PRIVILEGED_ACCESS                          3'b001
`define AXI_PROT_SECURE_ACCESS                              3'b000
`define AXI_PROT_NON_SECURE_ACCESS                          3'b010
`define AXI_PROT_DATA_ACCESS                                3'b000
`define AXI_PROT_INSTRUCTION_ACCESS                         3'b100
/* Memory types (AR) */
`define AXI_ARCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_ARCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_ARCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b1110
`define AXI_ARCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_ARCACHE_WRITE_BACK_NO_ALLOCATE                  4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_ALLOCATE                4'b1111
`define AXI_ARCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111
/* Memory types (AW) */
`define AXI_AWCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_AWCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_AWCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1110
`define AXI_AWCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_AWCACHE_WRITE_BACK_NO_ALLOCATE                  4'b0111
`define AXI_AWCACHE_WRITE_BACK_READ_ALLOCATE                4'b0111
`define AXI_AWCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1111
`define AXI_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111
/* Size */
`define AXI_SIZE_BYTES_1                                    3'b000
`define AXI_SIZE_BYTES_2                                    3'b001
`define AXI_SIZE_BYTES_4                                    3'b010
`define AXI_SIZE_BYTES_8                                    3'b011
`define AXI_SIZE_BYTES_16                                   3'b100
`define AXI_SIZE_BYTES_32                                   3'b101
`define AXI_SIZE_BYTES_64                                   3'b110
`define AXI_SIZE_BYTES_128                                  3'b111

/* Frontend exception */
`define FNT_EXC_W 2
`define FNT_EXC_EITM 0
`define FNT_EXC_EIPF 1

/* BPU packet width */
`define BPU_UPD_W (2 + CONFIG_PHT_P_NUM + CONFIG_BTB_P_NUM + 1)
`define BPU_UPD_TAKEN 0


/* Exception Vector Table */
`define NCPU_ERST_VECTOR 32'h0
`define NCPU_EINSN_VECTOR 32'h4
`define NCPU_EIRQ_VECTOR 32'h8
`define NCPU_ESYSCALL_VECTOR 32'hc
`define NCPU_EBUS_VECTOR 32'h10
`define NCPU_EIPF_VECTOR 32'h14
`define NCPU_EDPF_VECTOR 32'h18
`define NCPU_EITM_VECTOR 32'h1c
`define NCPU_EDTM_VECTOR 32'h20
`define NCPU_EALIGN_VECTOR 32'h24


/* Internal OPC (one-hot encoding) */

// Single-cycle operations
`define NCPU_ALU_IOPW 9 // Bitwidth
`define NCPU_ALU_ADD 0
`define NCPU_ALU_SUB 1
`define NCPU_ALU_MHI 2
`define NCPU_ALU_AND 3
`define NCPU_ALU_OR 4
`define NCPU_ALU_XOR 5
`define NCPU_ALU_LSL 6
`define NCPU_ALU_LSR 7
`define NCPU_ALU_ASR 8

// Branch operations
`define NCPU_BRU_IOPW 8
`define NCPU_BRU_BEQ 0
`define NCPU_BRU_BNE 1
`define NCPU_BRU_BGT 2
`define NCPU_BRU_BGTU 3
`define NCPU_BRU_BLE 4
`define NCPU_BRU_BLEU 5
`define NCPU_BRU_JMPREG 6
`define NCPU_BRU_JMPREL 7

// Multi-clks-latency operations
`define NCPU_LPU_IOPW 5 // Bitwidth
`define NCPU_LPU_MUL 0
`define NCPU_LPU_DIV 1
`define NCPU_LPU_DIVU 2
`define NCPU_LPU_MOD 3
`define NCPU_LPU_MODU 4

// EPU (Exception and Extended Processor Unit)
`define NCPU_EPU_IOPW 8
`define NCPU_EPU_WMSR 0
`define NCPU_EPU_RMSR 1
`define NCPU_EPU_ESYSCALL 2
`define NCPU_EPU_ERET 3
`define NCPU_EPU_EITM 4
`define NCPU_EPU_EIPF 5
`define NCPU_EPU_EIRQ 6
`define NCPU_EPU_EINSN (`NCPU_EPU_IOPW-1)

// LSU
`define NCPU_LSU_IOPW 7
`define NCPU_LSU_LOAD 0
`define NCPU_LSU_STORE 1
`define NCPU_LSU_BARR 2
`define NCPU_LSU_SIGN_EXT 3
`define NCPU_LSU_SIZE 6:4


`define NCPU_REGNO_LNK 1 // the only one machine-dependent register

/* Regfile index width */
`define NCPU_REG_AW 5

`endif
