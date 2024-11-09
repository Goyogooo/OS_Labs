#ifndef __SWAP_LRU_H__
#define __SWAP_LRU_H__

#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <list.h>
extern list_entry_t pra_list_head;

// 函数声明
static int _lru_init_mm(struct mm_struct *mm);
static int _lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in);
static int _lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick);
static int _lru_check_swap(void);
static int _lru_init(void);
static int _lru_set_unswappable(struct mm_struct *mm, uintptr_t addr);
static int _lru_tick_event(struct mm_struct *mm);

#endif // __SWAP_LRU_H__
