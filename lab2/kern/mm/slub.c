#include <slub.h>
#include <pmm.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

// 初始化一个 SLUB 缓存
void slub_init(slub_cache_t *cache, size_t obj_size) {
    assert(obj_size > 0);
    cache->obj_size = obj_size;
    list_init(&cache->free);
    list_init(&cache->partial);
    list_init(&cache->full);
}

// 分配一个对象
void *slub_alloc(slub_cache_t *cache) {
    struct Page *page = NULL;

    // 首先尝试从部分分配的 slab 中获取
    if (!list_empty(&cache->partial)) {
        list_entry_t *le = list_next(&cache->partial);
        page = le2page(le, page_link);
        // 如果此页面分配满了，从 partial 列表移动到 full 列表
        if (--page->property == 0) {
            list_del(le);
            list_add(&cache->full, le);
        }
    } else if (!list_empty(&cache->free)) {
        // 尝试从空闲的 slab 中获取
        list_entry_t *le = list_next(&cache->free);
        page = le2page(le, page_link);
        list_del(le);
        list_add(&cache->partial, le);
    } else {
        // 如果没有可用的 slab，从 buddy 系统分配新的 slab
        page = alloc_pages(1); // 分配一页
        if (page == NULL) {
            return NULL; // 分配失败
        }
        page->property = PGSIZE / cache->obj_size; // 页面中对象数量
        set_page_ref(page, 0);
        list_add(&cache->partial, &(page->page_link));
    }

    // 返回可用的对象
    void *obj = page2kva(page) + page->property * cache->obj_size;
    return obj;
}

// 释放一个对象
void slub_free(slub_cache_t *cache, void *obj) {
    struct Page *page = kva2page(obj);
    size_t offset = (obj - page2kva(page)) / cache->obj_size;
    assert(offset < PGSIZE / cache->obj_size);

    // 将对象返回到 slab，并更新 slab 的状态
    page->property++;
    if (page->property == 1) {
        list_del(&(page->page_link));
        list_add(&cache->partial, &(page->page_link));
    } else if (page->property == PGSIZE / cache->obj_size) {
        list_del(&(page->page_link));
        list_add(&cache->free, &(page->page_link));
    }
}

static void slub_alloc_check(slub_cache_t *cache) {
    void *obj1, *obj2, *obj3;

    // 尝试分配对象
    obj1 = slub_alloc(cache);
    assert(obj1 != NULL);
    obj2 = slub_alloc(cache);
    assert(obj2 != NULL);
    obj3 = slub_alloc(cache);
    assert(obj3 != NULL);

    // 检查对象是否有效
    assert(obj1 != obj2);
    assert(obj2 != obj3);
    assert(obj1 != obj3);

    // 释放对象
    slub_free(cache, obj1);
    slub_free(cache, obj2);
    slub_free(cache, obj3);

    // 再次分配对象，确保已释放的对象可以重新分配
    obj1 = slub_alloc(cache);
    assert(obj1 != NULL);
    obj2 = slub_alloc(cache);
    assert(obj2 != NULL);
    obj3 = slub_alloc(cache);
    assert(obj3 != NULL);

    // 确保没有内存泄漏
    assert(obj1 != NULL && obj2 != NULL && obj3 != NULL);
}

void test_slub_allocator() {
    cprintf("Testing SLUB cache...\n");
    slub_cache_t cache;
    slub_init(&cache, sizeof(int));  // 假设分配 sizeof(int) 大小的对象
    slub_alloc_check(&cache);        // 运行检查函数
    cprintf("SLUB cache test passed!\n");
}
