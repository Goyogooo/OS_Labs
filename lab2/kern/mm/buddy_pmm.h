#ifndef __KERN_MM_BUDDY_SYSTEM_PMM_H__
#define __KERN_MM_BUDDY_SYSTEM_PMM_H__

#include <pmm.h>

/* Define the size of each buddy system level */
#define MAX_BUDDY_ORDER 10  // Max order (i.e., 2^MAX_BUDDY_ORDER is the maximum block size)

/* Buddy system page structure */
struct buddy_page {
    unsigned long flags;     // Flags indicating the state of the page (e.g., free or reserved)
    int order;               // The order of the free block
    list_entry_t page_link;  // Link to the next buddy in the free list
};

/* Externally defined buddy system memory manager structure */
extern const struct pmm_manager buddy_pmm_manager;

/* Function prototypes for buddy system memory management */
void buddy_init(void);
void buddy_init_memmap(struct Page *base, size_t n);
struct Page *buddy_alloc_pages(size_t n);
void buddy_free_pages(struct Page *base, size_t n);
size_t buddy_nr_free_pages(void);
void buddy_check(void);

#endif /* !__KERN_MM_BUDDY_SYSTEM_PMM_H__ */
