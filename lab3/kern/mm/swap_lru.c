//刘芳宜2213925
#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>
extern list_entry_t pra_list_head;
/*
 * (1) _lru_init_mm: 初始化 pra_list_head 并将 mm->sm_priv 指向 pra_list_head 的地址
 */
static int
_lru_init_mm(struct mm_struct *mm) {   // 移除 static
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
    return 0;
}

/*
 * (2) _lru_map_swappable: 将最近访问的页面放到 pra_list_head 队尾。
 */
static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in) {  // 移除 static
    list_entry_t *head = (list_entry_t *) mm->sm_priv;
    list_entry_t *entry = &(page->pra_page_link);

    assert(entry != NULL && head != NULL);

    // 如果页面已经在队列中，先将其移除
    list_del(entry);
    // 将页面加入 pra_list_head 队尾
    list_add_before(head, entry);
    return 0;
}

/*
 * (3) _lru_swap_out_victim: 根据 LRU 算法，选择队首的页面（最近最少使用的页面）进行换出。
 */
static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick) {  // 移除 static
    list_entry_t *head = (list_entry_t *) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);

    // 选择队首的页面为 victim
    list_entry_t *entry = list_next(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}

/*
 * (4) _lru_check_swap: 检查 LRU 替换策略的正确性
 */
static int
_lru_check_swap(void) {  // 移除 static
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 4);
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 4);
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 4);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 4);
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 6);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 7);
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 8);
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 9);
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 10);
    cprintf("write Virt Page a in lru_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 11);
    return 0;
}

static int
_lru_init(void) {  // 移除 static
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr) {  // 移除 static
    return 0;
}

static int
_lru_tick_event(struct mm_struct *mm) {  // 移除 static
    return 0;
}

const struct swap_manager swap_manager_lru = {
    .name            = "lru swap manager",
    .init            = &_lru_init,
    .init_mm         = &_lru_init_mm,
    .tick_event      = &_lru_tick_event,
    .map_swappable   = &_lru_map_swappable,
    .set_unswappable = &_lru_set_unswappable,
    .swap_out_victim = &_lru_swap_out_victim,
    .check_swap      = &_lru_check_swap,
};
