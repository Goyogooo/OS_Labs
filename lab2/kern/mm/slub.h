#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <list.h>
#include <pmm.h>
#include "buddy.h"

typedef struct slub_cache {
    size_t obj_size;               // 单个对象的大小
    struct list_entry free;        // 空闲的 slab 列表
    struct list_entry partial;     // 部分分配的 slab 列表
    struct list_entry full;        // 完全分配的 slab 列表
} slub_cache_t;

void slub_init(slub_cache_t *cache, size_t obj_size);
void *slub_alloc(slub_cache_t *cache);
void slub_free(slub_cache_t *cache, void *obj);
void test_slub_allocator(void);

#endif /* !__KERN_MM_SLUB_H__ */
