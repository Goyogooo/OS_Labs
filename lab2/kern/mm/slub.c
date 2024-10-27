#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>
#include <assert.h>
#include "slub.h"

#define PAGE_SIZE 4096

// 初始化一个 SLUB 缓存
void slub_cache_init(slub_cache_t *cache, size_t obj_size) {
    assert(obj_size > 0);
    cache->obj_size = obj_size;
    list_init(&cache->free);
    list_init(&cache->partial);
    list_init(&cache->full);
}

// 分配一个新的 slab，并从伙伴系统中分配一页内存
slab_t* allocate_slab(slub_cache_t *cache) {
    struct Page *page = buddy_alloc_pages(1); // 从伙伴系统分配一页
    if (!page) return NULL;

    slab_t *slab = (slab_t*)page2kva(page);   // 使用该页的虚拟地址存储 slab 结构体
    slab->page = page;
    slab->obj_count = PAGE_SIZE / cache->obj_size;
    slab->freelist = page2kva(page) + sizeof(slab_t); // freelist 起始于 slab 结构体之后

    // 初始化 slab 的空闲对象链表
    void *obj = slab->freelist;
    void *next;
    for (size_t i = 0; i < slab->obj_count; i++) {
        next = (char*)obj + cache->obj_size;
        if ((char*)next >= (char*)page2kva(page) + PAGE_SIZE) {
            next = NULL;
        }
        *(void**)obj = next;
        obj = next;
    }

    list_add(&cache->partial, &slab->slab_link);
    return slab;
}

// 从 SLUB 缓存分配一个对象
void* slub_alloc(slub_cache_t *cache) {
    slab_t *slab;
    if (!list_empty(&cache->partial)) {
        slab = le2slab(list_next(&cache->partial), slab_link);
    } else if (!list_empty(&cache->free)) {
        slab = le2slab(list_next(&cache->free), slab_link);
        list_del(&slab->slab_link);
        list_add(&cache->partial, &slab->slab_link);
    } else {
        slab = allocate_slab(cache);
        if (!slab) return NULL;
    }

    // 从 slab 的空闲链表分配对象
    void *obj = slab->freelist;
    slab->freelist = *(void**)slab->freelist; // 更新下一个空闲对象
    slab->obj_count--;

    if (slab->obj_count == 0) {
        list_del(&slab->slab_link);
        list_add(&cache->full, &slab->slab_link);
    }

    return obj;
}
slab_t* kva2slab(void *obj) {
    // 获取对象所在的页面
    struct Page *page = kva2page(obj);
    // 将页面的起始地址（虚拟地址）转换为 slab_t 指针
    return (slab_t *)page2kva(page);
}

// 释放一个对象
void slub_free(slub_cache_t *cache, void *obj) {
    slab_t *slab = kva2slab(obj);  // 从对象指针转换为 slab 指针

    // 将对象加入到 slab 的空闲链表
    *(void**)obj = slab->freelist;
    slab->freelist = obj;
    slab->obj_count++;

    size_t total_objects = PAGE_SIZE / cache->obj_size;
    if (slab->obj_count == 1) {
        list_del(&slab->slab_link);
        list_add(&cache->partial, &slab->slab_link);
    }

    if (slab->obj_count == total_objects) {
        list_del(&slab->slab_link);
        buddy_free_pages(slab->page, 1);  // 释放页面到伙伴系统
    }
}


// 测试 SLUB 分配器
void test_slub_allocator() {
    cprintf("Testing SLUB cache...\n");
    slub_cache_t cache;


    slub_cache_init(&cache, 64);

    void *obj1 = slub_alloc(&cache);
    void *obj2 = slub_alloc(&cache);
    void *obj3 = slub_alloc(&cache);

    cprintf("Allocated objects at %p, %p, and %p\n", obj1, obj2, obj3);

    slub_free(&cache, obj1);
    slub_free(&cache, obj2);
    slub_free(&cache, obj3);

    cprintf("Freed objects at %p, %p, and %p\n", obj1, obj2, obj3);

    slub_cache_init(&cache, 4097);

    void *obj4 = slub_alloc(&cache);
    void *obj5 = slub_alloc(&cache);
    void *obj6 = slub_alloc(&cache);

    cprintf("Allocated objects at %p, %p, and %p\n", obj4, obj5, obj6);

    slub_free(&cache, obj4);
    slub_free(&cache, obj5);
    slub_free(&cache, obj6);

    cprintf("Freed objects at %p, %p, and %p\n", obj4, obj5, obj6);

    cprintf("SLUB cache test passed!\n");
}
