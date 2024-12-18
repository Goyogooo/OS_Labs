#ifndef __KERN_SYNC_SYNC_H__
#define __KERN_SYNC_SYNC_H__

#include <defs.h>
#include <intr.h>
#include <sched.h>
#include <riscv.h>
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {// 如果 SIE 位为 1，表示中断使能
        intr_disable();// 禁用中断
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {// 如果 flag 为 1，则恢复中断，使能中断
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x)      do { x = __intr_save(); } while (0)//while(0) 使得宏内容在展开后会被视为一个合法的单独语句，即使没有分号也不会导致语法错误
#define local_intr_restore(x)   __intr_restore(x);

#endif /* !__KERN_SYNC_SYNC_H__ */

