Lab2
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
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
- 你的first fit算法是否有进一步的改进空间？

#### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
(在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
- 你的 Best-Fit 算法是否有进一步的改进空间？)

1. 编程内容：
内存映射初始化函(best_fit_init_memmap)：
- 用于初始化从 base 开始的一段连续的页面块，并将其插入到空闲链表中。
- 遍历每个页面并将其设置为可分配状态。
- 使用链表的插入操作，将新页面块插入到 - free_list 中，确保链表按照页面的物理地址顺序排列，以方便后续释放时合并页面块。

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

2. 代码对物理内存的分配与释放:

- 分配过程：在 best_fit_alloc_pages 中，通过遍历空闲链表来找到最合适的页面块。每次找到一个符合条件的页面块时，都会比较当前块的大小，以选择满足请求并且大小最小的块。当找到适合的块后，如果块大小大于请求页面数，则会将多余部分分割出来并重新插入到空闲链表中。具体来说,当一个块满足 p->property >= n 时，将其标记为候选块。继续遍历链表，以找到更小的满足条件的块，最终选择最合适的块进行分配。分配后，更新 nr_free，并从空闲链表中移除已分配的页面。

- 释放过程：在 best_fit_free_pages 中，将释放的页面块重新插回空闲链表，并保持链表的顺序。释放后，通过检查释放块与前后的页面块是否相邻，如果相邻则合并这些页面块，形成更大的空闲块。这可以有效地减少内存碎片，提高后续内存分配的效率。

3. 是否有进一步改进空间:

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

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

 -  参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。
 
#### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

#### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？

方法 1：BIOS/UEFI 内存检测

- 在大多数 x86 架构系统上，BIOS 或 UEFI 会在启动时将系统内存的布局信息提供给操作系统。
- 操作系统可以使用 BIOS 提供的中断（通常是 INT 0x15，带参数 EAX = 0xE820）获取内存布局。这个中断调用会返回一个内存区域描述符列表，包含系统中物理内存的各种段（例如可用内存、保留内存等）的详细信息。
- 在使用 UEFI 时，UEFI 提供了 EFI_BOOT_SERVICES 的 GetMemoryMap 函数，可以用来获取可用的物理内存区域，以及哪些区域已经被占用或是不可用的。这些描述符将帮助操作系统了解内存的实际布局并正确初始化物理内存管理器。

方法 2：通过启动加载程序（Bootloader）获取内存信息
如果使用启动加载程序（如 GRUB）引导操作系统，则加载程序可以帮助操作系统收集可用物理内存的信息。GRUB 是一个常见的启动加载程序，它遵循 Multiboot 协议。在通过 GRUB 引导时，GRUB 会把系统内存的布局信息传递给操作系统。具体来说，GRUB 会通过 multiboot_info 结构提供一个内存映射表，这些信息包括哪些内存区域是可用的，哪些是被保留的。操作系统可以读取这些内存描述符，以获取所有可用的物理内存范围。

方法 3：ACPI 表格

- ACPI（Advanced Configuration and Power Interface） 表格可以包含硬件资源的信息，包括内存的可用性。
- ACPI 的 SRAT 表格（Static Resource Affinity Table）可以告诉操作系统内存和处理器之间的关联。
- 操作系统可以读取 ACPI 表格，以获取更准确的内存范围，尤其是对于 NUMA（非统一内存访问）架构的系统。

方法 4：内存探测
- 内存探测是一种较为低级但可以在硬件和固件信息不足的情况下使用的方法。OS 可以尝试逐步探测所有可能的内存地址，以找到实际可用的内存范围。

- 逐步探测：操作系统可以从一个合理的基地址（例如 0x00100000）开始，依次向更高的地址写入和读取，验证该地址是否有效。
通过探测内存并观察是否发生访问错误，可以大致推测哪些区域是有效内存。这种方法在低端系统中可能比较常见，但是它的速度较慢，特别是对大内存系统，逐字节探测是不可行的。

> Challenges是选做，完成Challenge的同学可单独提交Challenge。完成得好的同学可获得最终考试成绩的加分。