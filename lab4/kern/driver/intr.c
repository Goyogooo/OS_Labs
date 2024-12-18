#include <intr.h>
#include <riscv.h>
//SIE 位设置为 1，从而启用中断
/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
//SIE 位清除为 0，从而禁用中断
/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }

//状态寄存器 sstatus的SSTATUS_SIE 位