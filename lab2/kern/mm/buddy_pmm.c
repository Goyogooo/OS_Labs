#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>
#include <assert.h>

#define MAX_ORDER 10  // 最大块阶数，例如：2^10=1024 页

typedef struct {
    list_entry_t free_list[MAX_ORDER + 1]; // 每个阶数的空闲链表
    size_t nr_free[MAX_ORDER + 1];         // 每个阶数的空闲块数
} buddy_system_t;

static buddy_system_t buddy_system;

void buddy_init(void) {
    for (int i = 0; i <= MAX_ORDER; i++) {
        list_init(&buddy_system.free_list[i]); // 确保 list_init 传入的是 list_entry_t 类型的指针
        buddy_system.nr_free[i] = 0;
    }
}

void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    size_t order = MAX_ORDER;
    while ((1 << order) > n) {
        order--;
    }

    struct Page *p = base;
    for (size_t i = 0; i < n; i += (1 << order)) {
        p[i].flags = 0;
        set_page_ref(&p[i], 0);
        p[i].property = 1 << order;
        SetPageProperty(&p[i]);
        list_add(&buddy_system.free_list[order], &(p[i].page_link)); // 确保 list_add 传入正确类型的指针
        buddy_system.nr_free[order]++;
    }
}

struct Page *buddy_alloc_pages(size_t n) {
    int order = 0;
    while ((1 << order) < n) {
        order++;
    }
    if (order > MAX_ORDER) {
        return NULL;
    }

    for (int current_order = order; current_order <= MAX_ORDER; current_order++) {
        if (!list_empty(&buddy_system.free_list[current_order])) { // 确保 list_empty 传入的是 list_entry_t 类型的指针
            // 修改 buddy_alloc_pages 中的 list_first 使用为 list_next
            list_entry_t *le = list_next(&buddy_system.free_list[current_order]);

            struct Page *page = le2page(le, page_link);
            list_del(le); // 确保 list_del 传入的是 list_entry_t 类型的指针
            ClearPageProperty(page);
            buddy_system.nr_free[current_order]--;

            while (current_order > order) {
                current_order--;
                struct Page *buddy = page + (1 << current_order);
                buddy->property = 1 << current_order;
                SetPageProperty(buddy);
                list_add(&buddy_system.free_list[current_order], &(buddy->page_link)); // 确保 list_add 传入正确类型的指针
                buddy_system.nr_free[current_order]++;
            }

            return page;
        }
    }
    return NULL;
}

void buddy_free_pages(struct Page *base, size_t n) {
    int order = 0;
    while ((1 << order) < n) {
        order++;
    }

    struct Page *p = base;
    for (int current_order = order; current_order <= MAX_ORDER; current_order++) {
        struct Page *buddy = p + (1 << current_order);
        if (buddy->property != (1 << current_order) || PageReserved(buddy)) {
            break;
        }

        list_del(&(buddy->page_link)); // 确保 list_del 传入的是 list_entry_t 类型的指针
        buddy_system.nr_free[current_order]--;
        ClearPageProperty(buddy);

        if (p > buddy) {
            p = buddy;
        }
    }

    p->property = 1 << order;
    SetPageProperty(p);
    list_add(&buddy_system.free_list[order], &(p->page_link)); // 确保 list_add 传入的是 list_entry_t 类型的指针
    buddy_system.nr_free[order]++;
}

size_t buddy_nr_free_pages(void) {
    size_t total_free = 0;
    for (int i = 0; i <= MAX_ORDER; i++) {
        total_free += buddy_system.nr_free[i] * (1 << i);
    }
    return total_free;
}

void buddy_check(void) {
    struct Page *p0 = buddy_alloc_pages(4);
    assert(p0 != NULL);
    cprintf("Allocated 4 pages at %p\n", p0);

    buddy_free_pages(p0, 4);
    cprintf("Freed 4 pages at %p\n", p0);

    p0 = buddy_alloc_pages(8);
    assert(p0 != NULL);
    cprintf("Allocated 8 pages at %p\n", p0);

    buddy_free_pages(p0, 8);
    cprintf("Freed 8 pages at %p\n", p0);
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
