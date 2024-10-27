# Lab2
### 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

#### 练习0：填写已有实验

(本实验依赖实验1。请把你做的实验1的代码填入本实验中代码中有“LAB1”的注释相应部分并按照实验手册进行进一步的修改。具体来说，就是跟着实验手册的教程一步步做，然后完成教程后继续完成完成exercise部分的剩余练习。)

在kern/trap/trap.c中补全Lab1代码如下：

```c
#include <sbi.h>
static int num = 0;//new
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        //...
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            /*
            clock_set_next_event();
            if (++ticks % TICK_NUM == 0) {
                print_ticks();
            }
            break;
            */
            //begin
            clock_set_next_event();
            if (++ticks % TICK_NUM == 0) {
                print_ticks();
                num++;
            }
            if(num==10){
                sbi_shutdown();
            }
            break;
            //end
        //...
    }
}

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        //...
        case CAUSE_ILLEGAL_INSTRUCTION:
            //begin
            cprintf("Exception type:Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
            tf->epc += 4;
            //end
            break;
        case CAUSE_BREAKPOINT:
            //begin
            cprintf("Exception type:breakpoint\n");
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            tf->epc += 4;
            //end
            break;
        //...
    }
}
```
在libs/sbi.c中增加sbi_shutdown函数代码如下：

```c
void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
}
```

#### 练习1：理解first-fit 连续物理内存分配算法（思考题）
（first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
- 你的first fit算法是否有进一步的改进空间？）

##### **代码分析**

**1.default_init**：初始化内存管理器，设置空闲链表（`free_list`）为空并将可用物理页面数（`nr_free`）设为 0。

```c
static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}
```

**2.default_init_memmap**：初始化一组内存页，将其加入空闲链表并更新可用物理页面数。

```c
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));//确保当前页是未分配的
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
```

- 首先，它遍历链表，寻找第一个大于 `base` 的页面，如果找到了，则在该页面前插入 `base`。

- 如果循环到达链表末尾且没有找到合适的位置，则将 `base` 页直接添加到链表的末尾。

**3.default_alloc_pages**：查找并分配所需的内存页。

```c
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;//page分配后剩余的空闲页
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

- 遍历链表，需找合适的页。找到之后，将其从空闲链表中删除。
- 如果找到的页 `page` 的 `property` 大于请求的页数 `n`，表示该页还有多余的空间。将剩余页的 `property` 设置为 `page` 的 `property` 减去请求的页数 `n`，表示剩余空闲的页面数量。
- 在链表中将新创建的剩余空闲页 `p` 插入到之前节点 `prev` 后面，更新链表以包含这个新的空闲块。

**4.default_free_pages**：释放已分配的内存页并将其重新链接到空闲链表。

```c
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```

- 遍历释放的页，重置标志位和引用计数。

- 更新释放页的属性，将其标记为有效的空闲页。

- 将释放的页插入到空闲链表中，保持链表的有序性。

- 尝试合并相邻的空闲块，减少内存碎片。

#####  **物理内存分配过程**

1. **初始化**：
   - 系统启动时，调用 `default_init` 来初始化内存管理。
   - 当内存块初始化时，`default_init_memmap` 会被调用，以设置每个内存页的状态并将其加入空闲链表。
2. **分配内存**：
   - 当请求分配内存时，`default_alloc_pages` 被调用。
   - 它遍历空闲链表，寻找第一个能够满足请求的块。
   - 如果找到合适的块，它会更新块的状态并返回该块的地址。
3. **释放内存**：
   - 当不再需要某些内存时，`default_free_pages` 被调用以释放这些页。
   - 释放时，它将更新状态并尝试合并相邻的空闲块，以减少内存碎片。

##### **first fit算法的改进空间**

1.对于相邻的空闲块，可以采用延迟合并策略。只有在新的内存请求到来时，才检查合并条件，这样可以减少合并操作的频率。

2.考虑在内存使用率较低时，动态调整空闲链表的组织方式，例如定期整理链表，以确保能够快速分配和释放内存。

3.first fit只关注找到第一个适合的空闲块，可能会留下较小的、不可用的碎片。引入更复杂的合并策略可以有效地减少内存碎片，提高内存利用率。


#### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
(在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
- 你的 Best-Fit 算法是否有进一步的改进空间？)

##### 编程内容：
内存映射初始化函(best_fit_init_memmap)：
- 用于初始化从 base 开始的一段连续的页面块，并将其插入到空闲链表中。
- 遍历每个页面并将其设置为可分配状态。
- 使用链表的插入操作，将新页面块插入到 free_list （双向链表）中，确保链表按照页面的物理地址顺序排列，以方便后续释放时合并页面块。

```c
static void
best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));

        /*LAB2 EXERCISE 2: YOUR CODE*/ 
        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        p->flags = p->property = 0;
        set_page_ref(p,0);
        //end
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
             /*LAB2 EXERCISE 2: YOUR CODE*/ 
            // 编写代码
            // 1、当base < page时，找到第一个大于base的页，将base插入到它前面，并退出循环
            // 2、当list_next(le) == &free_list时，若已经到达链表结尾，将base插入到链表尾部
	    if(base<page){
	    	list_add_before(le, &(base->page_link));
	    	break;
	    }
	    else if(list_next(le)== &free_list){
	    	list_add(le, &(base->page_link));
	    }
	    //end
        }
    }
}
```

页面分配函数 (best_fit_alloc_pages)：

- 实现 Best Fit 算法，首先遍历整个空闲页面链表，找到一个大小满足需求并且最适合的页面块。
- 分配页面时，更新页面属性，并从链表中移除分配的页面块；如果块大小大于请求的页面数，则将剩余部分重新插入到空闲链表中。
- 最后返回分配的页面块的指针。
```c
static struct Page *
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
     /*LAB2 EXERCISE 2: YOUR CODE*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        /*
        if (p->property >= n) {
            page = p;
            break;
        }
        */
        //begin
        if(p->property >=n && p->property < min_size){
            min_size = p->property;
            page = p;
        }
        //end
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```
页面释放函数 (best_fit_free_pages)：
- 在页面释放时，首先将释放的页面块插回到空闲链表中，并保持链表按物理地址排序。
- 尝试与前后的页面块合并，以减少内存碎片并提高内存利用率。

```c
static void
best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    /*LAB2 EXERCISE 2: YOUR CODE*/ 
    // 编写代码
    // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    //end

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        /*LAB2 EXERCISE 2: YOUR CODE*/ 
         // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
        // 3、清除当前页块的属性标记，表示不再是空闲页块
        // 4、从链表中删除当前页块
        // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
        if(p + p->property == base){
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
        //end
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```

##### 代码对物理内存的分配与释放:

- 分配过程：在 best_fit_alloc_pages 中，通过遍历空闲链表来找到最合适的页面块。每次找到一个符合条件的页面块时，都会比较当前块的大小，以选择满足请求并且大小最小的块。当找到适合的块后，如果块大小大于请求页面数，则会将多余部分分割出来并重新插入到空闲链表中。具体来说,当一个块满足 p->property >= n 时，将其标记为候选块。继续遍历链表，以找到更小的满足条件的块，最终选择最合适的块进行分配。分配后，更新 nr_free，并从空闲链表中移除已分配的页面。

- 释放过程：在 best_fit_free_pages 中，将释放的页面块重新插回空闲链表，并保持链表的顺序。释放后，通过检查释放块与前后的页面块是否相邻，如果相邻则合并这些页面块，形成更大的空闲块。这可以有效地减少内存碎片，提高后续内存分配的效率。

##### 是否有进一步改进空间:
Best Fit 算法有进一步的改进空间。

- 查找效率：
    -改进查找的时间复杂度：在目前的实现中，Best Fit 需要遍历整个空闲链表，以找到满足条件的最小块。这一过程的时间复杂度为 $O(N)$，其中 $N$ 是空闲块的数量。如果使用更高效的数据结构（例如平衡树或最小堆），可以将查找的复杂度降低到 $O(\log N)$，从而提高内存分配的效率。
    - 链表优化：目前的实现使用链表来管理空闲页面块，但链表在查找操作上性能较差。如果改用红黑树或AVL 树，则能够快速找到大小合适的空闲块，从而优化分配效率。
- 内存碎片问题：
    - 合并相邻块的优化：当前实现中，在释放页面时尝试合并相邻块以减少碎片，但如果系统频繁分配和释放内存，还是会产生一定的碎片。可以考虑引入延迟合并策略，或者使用更智能的合并策略，例如批量合并空闲块，以进一步减少内存碎片。
- 内存回收策略：
    - 空闲块的维护和合并：目前释放块后就立即合并相邻块，合并过程涉及链表的插入和删除，性能不稳定。可以考虑设置一个空闲块回收阈值，当碎片块数量或大小超过某个阈值时再进行合并操作，从而减少不必要的合并开销，提高系统整体性能。
- 分配算法改进：
     - 分区策略：可以将空闲内存分为不同的分区（例如小块和大块），以便更高效地处理不同大小的内存请求。比如将较大的请求优先分配给大块内存，较小请求分配给小块内存，以此来降低碎片化。
- 结合其他算法的混合策略：
    - 混合策略：Best Fit 有时会造成较多的小碎片，不适合快速分配，可以考虑结合First Fit 或 Worst Fit 来实现混合策略。例如，当内存请求比较小的时候使用 First Fit，当请求比较大的时候使用 Best Fit，以平衡分配速度和碎片率。

#### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

（Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

 -  参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。）
  伙伴系统（Buddy System）是一种内存分配算法，旨在有效地管理内存并减少内存碎片。以下是伙伴系统的基本算法原理和步骤：

##### 基本原理

1. **内存块划分**：
   - 内存被划分为大小为 \(2^n\) 的块（页），例如 \(1KB, 2KB, 4KB, \ldots\)。
   - 每个块称为一个“伙伴”，即两个相同大小的块可以合并形成一个更大的块。

2. **二叉树结构**：
   - 采用二叉树结构来管理这些块，树的每个节点代表一个内存块。根节点代表整个内存，叶子节点代表最小块。
   - 通过树的结构，可以有效地查找、分配和释放内存块。

3. **分配与释放**：
   - 当请求内存时，首先查找足够大的块。如果没有足够大的块，则向上查找以找到合适的块并将其分裂成两个较小的块。
   - 当释放内存时，检查相邻的伙伴块是否也被释放。如果是，则将这两个块合并为一个更大的块。

##### 具体步骤

1. **初始化**：
   - 初始化时，将整个可用内存视为一个大块，形成一棵二叉树。

2. **分配内存（`buddy_insert`）**：
   - 接收请求的内存大小，向上寻找第一个能够满足请求的块。
   - 如果找到的块大于请求大小，使用分裂策略将该块分裂为两个较小的块，直到找到能够满足请求的块。
   - 更新树结构以反映当前分配的状态。

3. **释放内存（`buddy_free`）**：
   - 当释放内存块时，首先将该块标记为可用。
   - 检查其伙伴块是否可用。如果伙伴块也是空闲的，则合并这两个块并向上更新树的状态。
   - 重复这一过程，直到无法合并为止，确保内存尽可能地合并回原来的大块。

4. **空闲内存统计（`buddy_nr_free_pages`）**：
   - 遍历树结构，统计当前空闲的内存块数量。

##### 优点与缺点

- **优点**：
  - 伙伴系统具有较快的分配和释放速度，因为分配和合并操作只涉及树的简单遍历。
  - 相比于其他动态内存分配方法，它可以有效减少内存碎片。

- **缺点**：
  - 内存分配和释放的大小只能是 \(2^n\) 的倍数，这可能导致某些小块的内存无法使用。
  - 在高负载的情况下，可能会出现“外部碎片”，即在内存中有足够的空间，但无法满足请求的连续大小。

##### 示例

假设内存可用大小为 32KB，初始化时将其划分为：

- 1个 32KB 块（根节点）
  - 2个 16KB 块
    - 4个 8KB 块
      - 8个 4KB 块
        - 16个 2KB 块
          - 32个 1KB 块

当请求 6KB 的内存时，首先找到一个 8KB 的块，将其分裂成两个 4KB 的块，分配其中一个块，另一个块留空。释放时，如果释放的块的伙伴块也空闲，则合并为 8KB 块，依此类推。

##### 总结

伙伴系统是一种高效的内存分配算法，通过采用树结构和分裂/合并策略，能够较好地管理内存空间，适用于实时系统和高效内存管理需求的场景。
 
#### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

（slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。）

SLUB 分配器是一种面向小对象的内存分配算法，通过将内存划分为不同大小的固定块以减少碎片化，提高分配效率。它基于 slab 的设计思想，使用一个 slub_cache 结构体来管理不同大小的对象，每个 slub_cache 维护三个链表来追踪内存的使用情况。每个 slab 是一个内存页（一般为 4KB），存储一定数量的对象，并通过空闲链表记录哪些对象可用。SLUB 分配器将这些 slab页面分为 free、partial 和 full 三类，以便于快速查找和分配合适的内存块。

slub分配算法是非常复杂的，还需要考虑缓存对齐、NUMA等非常多的问题，由于ucore是⼀个实验性质的操作系统，我们不考虑这些复杂因素。以下是一个简化版的slub设计：

首先定义两个结构：

```c
// slab 结构体，用于管理每一页的对象分配情况
typedef struct slab {
    struct Page *page;           // 指向属于该 slab 的页面
    void *freelist;               // 空闲对象链表
    size_t obj_count;             // 当前 slab 中的对象数量
    list_entry_t slab_link;       // 链表节点，用于连接到 free、partial或full链表
} slab_t;
```

```c
// SLUB 缓存结构体，用于管理不同大小的对象
typedef struct slub_cache {
    size_t obj_size;              // 单个对象的大小
    list_entry_t free;            // 空闲的 slab 列表
    list_entry_t partial;         // 部分分配的 slab 列表
    list_entry_t full;            // 完全分配的 slab 列表
} slub_cache_t;
```

**slub_cache_init：**初始化缓存结构体 slub_cache_t，设置对象大小，并初始化 free、partial 和 full 链表。链表的初始状态为空。

```c
void slub_cache_init(slub_cache_t *cache, size_t obj_size) {
    assert(obj_size > 0);
    cache->obj_size = obj_size;
    list_init(&cache->free);
    list_init(&cache->partial);
    list_init(&cache->full);
}
```

**allocate_slab**：分配 slab 页面时会通过buddy system 从内存池中分配一个页面，并初始化其 freelist 和 obj_count。对象大小由 PAGE_SIZE /obj_size 决定。空闲对象链表通过 freelist 字段链接，freelist 起始于 slab 结构体之后。

- 初始化 freelist：遍历 slab 的空闲对象，将每个空闲对象地址以链表方式存入 freelist 中。
- 将新的 slab 节点加入 partial 链表，以便记录部分分配的 slab 页面。

```c
slab_t* allocate_slab(slub_cache_t *cache) {
    struct Page *page = buddy_alloc_pages(1);
    if (!page) return NULL;
    slab_t *slab = (slab_t*)page2kva(page);   
    slab->page = page;
    slab->obj_count = PAGE_SIZE / cache->obj_size;
    slab->freelist = page2kva(page) + sizeof(slab_t); 
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
```

**slub_alloc**：从 slub_cache 中分配一个对象。

1.查找合适的 slab：

- 优先从 partial 链表中选择一个未满的 slab。

- 若 partial 链表为空，则从 free 链表中选取完全空闲的 slab。

- 如果 free 链表也为空，则调用 allocate_slab 创建一个新的 slab。

2.分配对象：

- 从 slab 的 freelist 中取出一个空闲对象，将其从 freelist 中移除。
- 更新 obj_count，如果 obj_count 减至零，则将 slab 移动至 full 链表。

```c
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
    void *obj = slab->freelist;
    slab->freelist = *(void**)slab->freelist;
    slab->obj_count--;
    if (slab->obj_count == 0) {
        list_del(&slab->slab_link);
        list_add(&cache->full, &slab->slab_link);
    }
    return obj;
}
```

**slub_free**：释放对象。

1. 通过 kva2slab 函数获取该对象所在的 slab 结构体。
2. 更新 freelist：将释放的对象添加回 freelist，并增加 obj_count。
3. 如果 slab 的 obj_count 增至 1，则从 full 链表移至 partial 链表。
   若 obj_count 达到该 slab 的总容量，则将 slab 从 partial 链表移至 free 链表，并释放页面回buddy_system。

**test_slub_allocator**：测试 slub 分配器。

```c
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
```

我们进行了不同大小对象（64字节和4097字节）的内存分配测试。

1. 64字节对象的分配：对象分配在 SLUB 分配器中进行，将对象分别存储在同一页的多个空闲块中，有效地利用了内存空间。对象在 SLUB 缓存中按链表管理，通过 slab 结构的空闲链表 freelist 依次分配与释放。
2. 4097字节对象的分配：由于对象大小超出 SLUB 分配器的单页（4KB）限制，因此 SLUB 分配器会调用 buddy_system 来分配多个连续页（即多页内存块），以满足大对象的分配需求。


#### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
 （ 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？）

方法 1：设备树内存节点检测

- OpenSBI的⽂档中说明OpenSBI在进⼊内核前会将扁平化的设备树位置写⼊内存中，并且将设备树对应的内存物理地址存⼊a1寄存器中。
- 可以通过调试找到设备树的内存物理地址。
- 在设备树头部结构体中，会存储多种信息，其中在structure block中会存储memory节点中的信息。
- 对这个结构体的内部数据进行解析，找到对应的内存节点就能知道物理内存的范围信息。

方法 2：ACPI 表格

- ACPI（Advanced Configuration and Power Interface） 表格可以包含硬件资源的信息，包括内存的可用性。
- ACPI 的 SRAT 表格（Static Resource Affinity Table）可以告诉操作系统内存和处理器之间的关联。
- 操作系统可以读取 ACPI 表格，以获取更准确的内存范围，尤其是对于 NUMA（非统一内存访问）架构的系统。

方法 3：内存探测
- 内存探测是一种较为低级但可以在硬件和固件信息不足的情况下使用的方法。OS 可以尝试逐步探测所有可能的内存地址，以找到实际可用的内存范围。

- 逐步探测：操作系统可以从一个合理的基地址（例如 0x00100000）开始，依次向更高的地址写入和读取，验证该地址是否有效。
通过探测内存并观察是否发生访问错误，可以大致推测哪些区域是有效内存。这种方法在低端系统中可能比较常见，但是它的速度较慢，特别是对大内存系统，逐字节探测是不可行的。

> Challenges是选做，完成Challenge的同学可单独提交Challenge。完成得好的同学可获得最终考试成绩的加分。


### 实验知识点

**虚拟内存与页表机制**

- **含义**：虚拟内存通过页表将进程的虚拟地址映射到物理内存地址，实现内存的有效分配和隔离。页表是虚拟地址与物理地址之间的映射表。
- **对应的 OS 原理**：操作系统的虚拟内存管理通过页表映射实现多进程共享物理内存资源，提高系统的安全性和内存管理效率。
- **关系与差异**：实验中，我们实现了 RISC-V 的 SV39 页表机制，这是 RISC-V 页表的三级页表结构，而 OS 理论中页表机制包括多种方式，如单级页表、多级页表和倒排页表等。实验聚焦于三级页表，而没有深入多级页表的其他细节和实现优化，例如 SV48 或 SV57 等更大页表。

**页面分配算法**

页面分配算法用于操作系统中的内存管理，帮助高效地分配和释放内存资源。本次实验中使用到了4种经典的页面分配算法。

1. First Fit算法
   原理：按顺序找到第一个能满足请求的空闲块并分配，剩余部分继续保留。
   优缺点：简单高效，但易造成碎片，长期使用后内存变零散。
   应用：适合小型嵌入式系统。
2. Best Fit算法
   原理：找到满足请求且剩余空间最少的块进行分配。
   优缺点：减少碎片，但增加分配时间，易产生小碎片。
   应用：适合对内存碎片控制要求较高的系统。
3. Buddy System算法
   原理：按 2 的幂次分裂内存块，满足请求后分配。释放时若伙伴块未使用则合并，形成更大的块。
   优缺点：分配/释放效率高，易合并，减少碎片，但若请求非 2 的幂大小会有空间浪费。
   应用：广泛应用于操作系统的内存管理模块，如 Linux 内核。
4. SLUB Allocator算法
   原理：适用于小对象的分配，使用多个 slab 缓存池，每个缓存池管理固定大小的对象。
   优缺点：高效、减少碎片，适合小对象分配，但不适用于大对象。
   应用：Linux 内核内存管理，用于频繁分配/释放的小对象，如 PCB、文件描述符。
