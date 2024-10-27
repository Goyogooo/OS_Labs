#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <list.h>
#include <pmm.h>
#define le2slab(le, member) \
    ((slab_t *)((char *)(le) - offsetof(slab_t, member)))

// slab 结构体，用于管理每一页的对象分配情况
typedef struct slab {
    struct Page *page;           // 指向属于该 slab 的页面
    void *freelist;               // 空闲对象链表
    size_t obj_count;             // 当前 slab 中的对象数量
    list_entry_t slab_link;       // 链表节点，用于连接到 partial 或 full 链表
} slab_t;

// SLUB 缓存结构体，用于管理不同大小的对象
typedef struct slub_cache {
    size_t obj_size;              // 单个对象的大小
    list_entry_t free;            // 空闲的 slab 列表
    list_entry_t partial;         // 部分分配的 slab 列表
    list_entry_t full;            // 完全分配的 slab 列表
} slub_cache_t;


void slub_cache_init(slub_cache_t *cache, size_t obj_size);
slab_t* allocate_slab(slub_cache_t *cache);
void* slub_alloc(slub_cache_t *cache) ;
void slub_free(slub_cache_t *cache, void *obj);
void test_slub_allocator(void);

#endif /* !__KERN_MM_SLUB_H__ */
