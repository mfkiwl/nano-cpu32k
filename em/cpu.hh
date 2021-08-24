#ifndef CPU_H_
#define CPU_H_

#include "common.hh"

struct regfile_s
{
    cpu_word_t r[32];
};

struct psr_s
{
    char CY;
    char OV;
    char OE;
    char RM;
    char IRE;
    char IMME;
    char DMME;
    char ICAE;
    char DCAE;
};
/* ITLB */
struct itlbl_s
{
    char V;
    vm_addr_t VPN;
};
struct itlbh_s
{
    char P;
    char D;
    char A;
    char UX;
    char RX;
    char NC;
    char S;
    vm_addr_t PPN;
};
/* DTLB */
struct dtlbl_s
{
    char V;
    vm_addr_t VPN;
};
struct dtlbh_s
{
    char P;
    char D;
    char A;
    char UW;
    char UR;
    char RW;
    char RR;
    char NC;
    char S;
    vm_addr_t PPN;
};

struct tcr_s
{
    uint32_t CNT;
    char EN;
    char I;
    char P;
};

class msr_s
{
public:
    msr_s(uint32_t immu_tlb_count, uint32_t dmmu_tlb_count)
        : ITLBL(new itlbl_s[immu_tlb_count]),
          ITLBH(new itlbh_s[immu_tlb_count]),
          DTLBL(new dtlbl_s[dmmu_tlb_count]),
          DTLBH(new dtlbh_s[dmmu_tlb_count])
    {
        PSR.CY=
        PSR.OV=
        PSR.OE=
        PSR.RM=
        PSR.IRE=
        PSR.IMME=
        PSR.DMME=
        PSR.ICAE=
        PSR.DCAE=0;
        TSR=0;
        IMR=0;
        IRR=0;
    }
    struct psr_s PSR;
    struct psr_s EPSR;
    vm_addr_t EPC;
    vm_addr_t ELSA;
    struct itlbl_s *ITLBL;
    struct itlbh_s *ITLBH;
    struct dtlbl_s *DTLBL;
    struct dtlbh_s *DTLBH;
    cpu_unsigned_word_t TSR;
    struct tcr_s TCR;
    cpu_unsigned_word_t IMR;
    cpu_unsigned_word_t IRR;
};

class CPU
{
public:
    CPU(int dmmu_tlb_count_, int immu_tlb_count_,
        bool dmmu_enable_uncached_seg_,
        int icache_p_ways_, int icache_p_sets_, int icache_p_line_,
        int dcache_p_ways_, int dcache_p_sets_, int dcache_p_line_,
        size_t memory_size_, phy_addr_t mmio_phy_base_,
        int IRQ_TSC_);
    ~CPU();

    void reset(vm_addr_t reset_vect);
    vm_addr_t step(vm_addr_t pc);

    void set_reg(uint16_t addr, cpu_word_t val);
    cpu_word_t get_reg(uint16_t addr);

private:
    vm_addr_t raise_exception(vm_addr_t pc, vm_addr_t vector, vm_addr_t lsa, bool is_syscall);
    int check_vma_align(vm_addr_t va, int size);

    /* mmu.cc */
    int dmmu_translate_vma(vm_addr_t va, phy_addr_t *pa, bool *uncached, bool store_insn);
    int immu_translate_vma(vm_addr_t va, phy_addr_t *pa);

    /* msr.cc */
    void wmsr(msr_index_t index, cpu_word_t v);
    cpu_word_t rmsr(msr_index_t index);
    void warn_illegal_access_reg(const char *reg);

    /* tsc.cc */
    void tsc_clk(int delta);
    void tsc_update_tcr();

    /* irqc.cc */
    void irqc_set_interrupt(int channel, char raise);
    int irqc_is_masked(int channel);
    int irqc_handle_irqs();

private:
    vm_addr_t pc;
    msr_s msr;
    struct regfile_s regfile;
    int dmmu_tlb_count, immu_tlb_count;
    bool dmmu_enable_uncached_seg;
    int icache_p_ways, icache_p_sets, icache_p_line;
    int dcache_p_ways, dcache_p_sets, dcache_p_line;
    Memory *mem;
    Cache *icache, *dcache;
    int IRQ_TSC;
};

#endif // CPU_H_