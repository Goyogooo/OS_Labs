### 练习

对实验报告的要求：

- 基于markdown格式来完成，以文本方式为主
- 填写各个基本练习中要求完成的报告内容
- 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
- 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
- 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

#### 练习0：填写已有实验

本实验依赖实验1/2。请把你做的实验1/2的代码填入本实验中代码中有“LAB1”,“LAB2”的注释相应部分。

#### 练习1：理解基于FIFO的页面替换算法（思考题）

描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了 `kern/mm/swap_fifo.c`文件中，这点请同学们注意）

- 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数

1. **do_pgfault()**：

   该函数是页面置换的核心，处理缺页异常。首先，它通过 `get_pte()` 获取页表项，判断该页表项是否有效。如果有效，可能需要将硬盘上的数据换入内存，并根据情况选择是否换出内存中的一个页面。它是页面置换处理的入口。

2. **assert()**：

   断言用于验证每一步操作是否正确，确保程序在页面置换过程中没有出现意外的错误。

3. **find_vma()**：

   判断访问出错的虚拟地址是否在该页表的合法虚拟地址集合（所有可用的虚拟地址/虚拟页的集合，不论当前这个虚拟地址对应的页在内存上还是在硬盘上）里。如果返回NULL，说明查询的虚拟地址不存在/不合法，既不对应内存里的某个页，也不对应硬盘里某个可以换进来的页。

4. **get_pte()**：

   该函数用于获取虚拟地址 `addr` 对应的页表项。如果页表项不存在，函数会分配新的页表项（包括分配新的页目录和页表项）。它是确定一个虚拟地址是否需要换入或创建页表项的关键函数。

5. **swap in()**：

   该函数负责将一个被交换到硬盘上的页面加载回物理内存，并将其映射到虚拟地址 `addr`。它首先分配一个物理页面，然后从硬盘读取数据到该页面

6. **page_insert()：**

   该函数负责将物理页与虚拟地址进行映射。具体来说，它将 `swap_in()` 中加载到物理内存的页面映射到页表中指定的虚拟地址。它是在 `swap_in()` 之后调用的，完成虚拟地址和物理地址的绑定。

7. **swapfs_write()**：

   将内存中被换出的页面数据保存到硬盘的交换空间。

8. **swapfs_read()**:

   该函数负责从硬盘读取数据，并将其加载到内存的一个物理页面中。它是执行页面换入操作时的核心部分，调用 `ide_read_secs()` 和 `memcpy()` 来执行磁盘到内存的数据拷贝。

9. **swap out()**:

   页面需要换出时调用该函数。采用消极换出策略，只有内存中空闲页不够时才会换出。

10. **swap_out_victim()**:

    选择一个被换出的页面。在FIFO中，它从FIFO队列中选择最先被加载的页面作为受害页面，将其换出到硬盘。

11. **alloc_page()**:

    分配一个新的物理页面。

12. **free_page()**:

    释放一个物理页面。在页面被换出时调用，释放内存中的页面资源，以便重新分配。

13. **swap_map_swappable()**:

    该函数将页面标记为可交换，并将其加入FIFO队列。

14. **tlb_invalidate():**

​		用于无效化 TLB（清除缓存的虚拟到物理地址映射）。它调用 `flush_tlb()` 来触发实际的刷新操作。		     `flush_tlb()` 执行 `sfence.vma` 指令，触发 TLB 刷新，确保虚拟地址映射的更新生效。



#### 练习2：深入理解不同分页模式的工作原理（思考题）

get_pte()函数（位于 `kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。

- get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
- 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

```c++
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}

```

##### `get_pte()` 函数中两段代码相似的原因

##### sv32，sv39，sv48的异同

无论是 **sv32**、**sv39** 还是 **sv48**，它们都遵循类似的分层结构来管理虚拟地址空间。虚拟地址被划分为多个部分，每一部分对应一个页表或页目录的索引。具体来说：

- **SV32**：将虚拟地址分为两部分：页目录项（10位）和页表项（10位），因此使用两级页表。
- **SV39**：将虚拟地址分为三部分：页目录项（9位）、页表项（9位）和页内偏移（12位），使用三级页表。
- **SV48**：将虚拟地址分为四部分：页目录项（9位）、页表项（9位）、次级页表项（9位）和页内偏移（12位），使用四级页表。

在我们的ucore实验中使用的是sv39模式，页表被分为了:PDX1、PDX0和PTX。在`get_pte()` 函数中，前后两段代码分别用于处理第一级页目录（`PDX1`）和第二级页目录（`PDX0`），查找或创建特定线性地址（`la`）对应的页表项（PTE）。

这两段代码都包含以下步骤：

- **查找页目录项或页表项**：通过虚拟地址中的相应部分，查找页目录项或页表项。
- **检查项是否有效**：如果项无效（即没有映射到有效的物理页面），则需要为其分配新的页面并创建新的页目录项或页表项。
- **分配新的页**：如果项无效，调用 `alloc_page()` 分配新的物理页面，并初始化该页面。
- **更新页目录项或页表项**：将新的物理页面的地址写入页目录项或页表项。

虽然每段代码分别处理不同级别的页表（即第一级页目录和第二级页目录），但是它们的工作流程几乎完全一致。这是因为每一层的页表项（不论是页目录还是页表）都承担着类似的职责：它们指向下一级页表或物理页面，确保虚拟地址能够正确映射到物理内存。



**查找和分配的功能**

经过探讨，我们小组认为这种get_pte()函数将页表项的查找和页表项的分配合并在一个函数的写法并不好。虽然对于ucore中需要实现的sv39分页机制，这种写法能够实现功能且能够增强代码的复用，减少可能出现的错误，但是可扩展性较差，存在一些明显的问题。

将查找和分配功能拆分到两个独立的函数中后，每个函数专注于单一职责，这种设计不仅能让代码结构更清晰，更易维护，还能在问题定位时更加高效精准。此外，拆分后的设计可以明确区分查找失败和分配失败的场景，使调用方能够针对不同的失败原因进行适当的错误处理。如果 `get_pte()` 将查找和分配合并在一起，一旦查找失败，调用方无法明确区分是查找失败还是分配失败，从而增加了问题定位的难度。



#### 练习3：给未被映射的地址映射上物理页（需要编程）

补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
- 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
- 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

**1. codes**

```c
//kern/mm/vmm.c
//...
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++;
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {//没有或越界
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }

    /* IF (write an existed addr ) OR
     *    (write an non_existed addr && addr is writable) OR
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {//通过vma确定写权限
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);//页为单位对齐

    ret = -E_NO_MEM;

    pte_t *ptep=NULL;
    /*
    * Maybe you want help comment, BELOW comments can help you finish the code
    *
    * Some Useful MACROs and DEFINEs, you can use them in below implementation.
    * MACROs or Functions:
    *   get_pte : get an pte and return the kernel virtual address of this pte for la
    *             if the PT contians this pte didn't exist, alloc a page for PT (notice the 3th parameter '1')
    *   pgdir_alloc_page : call alloc_page & page_insert functions to allocate a page size memory & setup
    *             an addr map pa<--->la with linear address la and the PDT pgdir
    * DEFINES:
    *   VM_WRITE  : If vma->vm_flags & VM_WRITE == 1/0, then the vma is writable/non writable
    *   PTE_W           0x002                   // page table/directory entry flags bit : Writeable
    *   PTE_U           0x004                   // page table/directory entry flags bit : User can access
    * VARIABLES:
    *   mm->pgdir : the PDT of these vma
    *
    */

    //获取对应页表项
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) {//为空则分配一个新的物理页
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else {
        /*LAB3 EXERCISE 3: YOUR CODE
        * 请你根据以下信息提示，补充函数
        * 现在我们认为pte是一个交换条目，那我们应该从磁盘加载数据并放到带有phy addr的页面，
        * 并将phy addr与逻辑addr映射，触发交换管理器记录该页面的访问情况
        *
        *  一些有用的宏和定义，可能会对你接下来代码的编写产生帮助(显然是有帮助的)
        *  宏或函数:
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {//不为空但是不在内存中，在页面交换初始化完成后，加载页面进入内存
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            //begin
            // 从交换区加载页面
            if (swap_in(mm, addr, &page) != 0) {
                cprintf("swap_in() failed\n");
                goto failed;
            }

            // 重新映射页面，在这里回更新tlb表
            if (page_insert(mm->pgdir, page, addr, perm) != 0) {
                cprintf("page_insert() after swap_in() failed\n");
                free_page(page);
                goto failed;
            }

            // 设置页面为可交换
            swap_map_swappable(mm, addr, page, 0);
            //end
            page->pra_vaddr = addr;
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
failed:
    return ret;
}
//...
```
2. **实现过程**

    - 通过find_vma函数，查找addr所属的虚拟内存区域（VMA）。如果找不到或者地址超出范围，说明地址非法，直接退出。
    - 根据vma->vm_flags判断地址是否可写（VM_WRITE）。随后将addr向下取整到页边界（ROUNDDOWN(addr, PGSIZE)）对齐，计算页表项的权限位perm。
    - 调用get_pte函数，获取addr对应的页表项。如果目标页表不存在，则自动分配。
    - 分配加载页面：
        - 情况1：页表项为空（新建页）：调用pgdir_alloc_page分配物理页，并建立地址映射。如果分配失败，返回错误。
        - 情况2：页表项存在但需要从交换区加载进来。调用swap_in，从交换区读取对应磁盘页到内存，通过page_insert将物理地址与逻辑地址映射，完成内存页插入，最后调用swap_map_swappable，将页面标记为可交换。
    - 如果任一环节失败（例如地址非法、分配失败或交换失败），输出错误信息，并返回错误码-E_INVAL或-E_NO_MEM。
    - 若所有步骤成功，返回值为0，表示页错误处理完成。

3. **请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。**


            +----26---+----9---+----9---+---2----+-------8-------+

            |  PPN[2] | PPN[1] | PPN[0] |Reserved|D|A|G|U|X|W|R|V|

            +---------+--------+--------+--------+---------------+

    - PPN[2], PPN[1], PPN[0]：PPN 表示物理页号，用于将虚拟地址映射到物理地址。当页面需要换出到磁盘时，uCore 使用 PPN 来识别并操作对应的物理页帧。页面换入时，通过更新 PPN，重新映射虚拟地址到新分配的物理页帧。
    - D (Dirty) 位：脏位指示页面是否被写入过。页面换出时，如果 D 位为 1，则需要将页面内容写回到磁盘。如果 D 位为 0，则页面内容未修改，可以直接丢弃。
    - A (Accessed) 位：访问位指示页面是否被访问过。如果 A 位为 0，表示没被访问，可能被换出，为 1 则跳过。
    - V (Valid) 位：有效位指示页面是否在内存中。如果页面不在内存中（V 位为 0），会触发缺页异常。缺页处理程序会决定是否需要换出其他页面以腾出空间。
    - 权限位（U, W, R, X）：指示页面是否可读、可写、可执行，或者是否允许用户态访问。如果页面访问权限不足，会触发缺页异常。uCore 可以根据这些权限位为每个页面设置合适的权限，防止非法访问。
    - G (Global) 位：指示页面是否是全局的（即不随上下文切换而失效）。
    - Reserved：保留位，未被使用。

4. **如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？**
    - 硬件触发新的缺页异常：硬件会检测到当前访问的页面不可用（页表项无效、未加载到内存），将新的缺页异常信息写入特定寄存器（ scause异常类型 和 stval错误地址）。
    - 保存异常上下文：硬件会保存当前的程序状态（寄存器值等）到内核堆栈，以便操作系统可以恢复执行。
    - 根据异常向量表，跳转到对应的入口：根据 stvec 寄存器的值跳转到异常处理程序（__alltraps），进入内核，由操作系统进行异常处理逻辑。

5. **数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？**

    - struct Page 本身是对物理页帧的一种抽象，其中的成员用于跟踪页帧的状态，以及支持页面替换算法（如记录虚拟地址 pra_vaddr）。
    - PTE 中的 PPN 对应着物理页帧，每个物理页帧对应 struct Page 的一个数组项，。
    - PDE 和 PTE 类似， PDE 指向的下一级页表本身也是一个物理页帧，该物理页帧同样通过 struct Page 数组中的对应项进行管理。

#### 练习4：补充完成Clock页替换算法（需要编程）

通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 比较Clock页替换算法和FIFO算法的不同。

 **1. codes**

```c
 //kern/mm/swap_clock.c
 //...
 extern list_entry_t pra_list_head;//哨兵队头
list_entry_t *curr_ptr;//指示当前的节点
/*
 * (2) _fifo_init_mm: init pra_list_head and let  mm->sm_priv point to the addr of pra_list_head.
 *              Now, From the memory control struct mm_struct, we can access FIFO PRA
 */
static int
_clock_init_mm(struct mm_struct *mm)
{   
     /*LAB3 EXERCISE 4: YOUR CODE*/ 
     // 初始化pra_list_head为空链表
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     //begin
     list_init(&pra_list_head);
     curr_ptr=&pra_list_head;
     mm->sm_priv=&pra_list_head;
     cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     //end
     return 0;
}
/*
 * (3)_fifo_map_swappable: According FIFO PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && curr_ptr != NULL);
    //record the page access situlation
    /*LAB3 EXERCISE 4: YOUR CODE*/ 
    // link the most recent arrival page at the back of the pra_list_head qeueue.
    // 将页面page插入到页面链表pra_list_head的末尾
    // 将页面的visited标志置为1，表示该页面已被访问
    //begin
    list_add(&pra_list_head, entry);//添加活跃页到队头的后面
    page->visited =1;//访问位置为1
    curr_ptr = entry；//更新指针位置
    cprint("curr_ptr %p\n", curr_ptr);
    //end
    return 0;
}
/*
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 */
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
     list_entry_t *temp = head;//临时存储后向节点
    while (1) {
        /*LAB3 EXERCISE 4: YOUR CODE*/ 
        // 编写代码
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        // 获取当前页面对应的Page结构指针
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
        //begin
        list_entry_t* current = list_prev(temp);//向前遍历，当前节点
        struct Page *page = le2page(current, pra_page_link);//转换成对应的page
        if(page->visited == 0)//没访问，替换
        {
            list_del(current);//删掉节点
            *ptr_page = page; //返回对应的页
            cprintf("curr_ptr %p\n", curr_ptr);
            break;
        }
        if(page->visited == 1)//访问过，跳过
        {
            page->visited = 0;//重新清零      
        }
        temp = current;//传递节点
        //end
    }
    return 0;
}
//...
```

2. **比较Clock页替换算法和FIFO算法的不同。**

    - FIFO 页替换算法：按照页面到达的顺序，优先替换最早进入内存的页面。只需要使用一个简单的队列来维护页面顺序。
    - Clock 页替换算法：使用一个循环队列模拟时钟，每个页面有一个访问位（visited 位）。如果当前页面的 visited 位为 0，则替换该页面。如果 visited 位为 1，则清零并移动指针到下一个页面。
    - FIFO 是一个简单直接的页面替换算法，不需要关注页面访问的频率或时间，仅根据插入顺序来替换页面。Clock 是 FIFO 的优化版本，它结合了页面访问的状态（visited 位），在替换页面时更加智能，性能接近于 LRU。
    - 在代码实现中，FIFO 的实现逻辑更为直观，而 Clock 算法通过遍历和判断 visited 位，使得页面替换更加高效。


#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）

如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

大页映射和分级页表是两种常见的虚拟内存管理方式。大页映射将更大范围的虚拟地址直接映射到物理内存，而分级页表通过多层次映射提供更灵活的管理。如果我们采用”一个大页“ 的页表映射方式:

#### **优点：**

1. **减少页表的存储开销**
   - 大页的映射方式中，一个页表项能够覆盖更大的地址范围，例如 1GB 或 2MB 的内存区域。与分级页表相比，减少了页表项的数量，从而降低了页表的存储开销。
2. **提高 TLB 命中率**
   - 大页覆盖更大的内存范围，因此 TLB（Translation Lookaside Buffer）中的一个条目可以减少更多虚拟地址到物理地址的映射，从而显著减少 TLB 缺失（TLB miss）的次数。
3. **减少内存访问开销**
   - 大页页表通常只需一次访问即可完成映射，而分级页表需要逐级访问页目录和页表。
   - 对于频繁访问页表的应用（如多任务操作系统），减少内存访问次数可以降低延迟。
4. **适合大数据应用**
   - 当应用程序需要频繁访问大块内存时，大页映射非常高效。例如高性能计算、虚拟化场景中，虚拟机和主机之间的内存交互大多使用大页来优化性能。

#### **缺点：**

1. **内存碎片问题**

   - 大页需要分配连续的物理内存空间。如果内存被碎片化（即可用的内存块不连续），分配大页可能失败。例如，尽管系统有足够的可用内存，但因无法找到一个完整的连续大页区域而导致分配失败。

2. **内存浪费**

   - 如果应用程序实际只需要大页中的一小部分内存，仍然需要分配整块大页，这会造成内存浪费。例如，分配 2MB 的大页，但只使用其中的 16KB，剩余部分即为浪费。

3. **不够灵活**

   - 大页限制了细粒度内存管理。对于内存需求动态变化的程序或需要频繁释放内存的场景，大页映射无法灵活调整映射关系，可能导致更多的不必要开销。

4. **硬件要求高**

   - 并非所有硬件都支持大页映射。支持大页的硬件通常需要额外的设计复杂度和资源。

5. **安全风险**

   - 大页的映射范围大，一旦发生安全漏洞或内存泄露，攻击者可能获得更大的内存范围，从而增加安全隐患。

6. **交换（swap）开销高**

   - 当使用大页时，如果需要将某个大页置换到硬盘或恢复到内存，操作需要处理整个大页的数据。例如，一个 1GB 大页的换入/换出开销比 4KB 小页要大得多。

   

#### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）

challenge部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。

```c++
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

```

