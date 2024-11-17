### 练习

对实验报告的要求：

- 基于markdown格式来完成，以文本方式为主
- 填写各个基本练习中要求完成的报告内容
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

   该函数负责将物理页与虚拟地址进行映射。

7. **swapfs_write()**：

   将内存中被换出的页面数据保存到硬盘的交换空间。

8. **swapfs_read()**:

   该函数负责从硬盘读取数据，并将其加载到内存的一个物理页面中。它是执行页面换入操作时的核心部分，调用 `ide_read_secs()` 和 `memcpy()` 来执行磁盘到内存的数据拷贝。

9. **swap out()**:

   页面需要换出时调用该函数。采用消极换出策略，只有内存中空闲页不够时才会换出。

10. **swap_out_victim()**:

    选择一个被换出的页面。在FIFO中会直接调用`_fifo_swap out victim` 进行页面换出，这会将链表最后(最先进入的页面)指定为需要被换出的页面。这部分实现很简单就是去找到fifo算法维护的那个队列的最后一个，也就是代表最老的页进行换出即可。

11. **alloc_page()**:

    分配一个新的物理页面。`alloc_page`为`alloc_pages `的一个宏，会分配一个页面，如果不够用则会用 `swap_out` 换出所需的页面数量。

12. **free_page()**:

    释放一个物理页面。在页面被换出时调用，释放内存中的页面资源，以便重新分配。

13. **swap_map_swappable()**:

    该函数将页面标记为可交换，并将其加入FIFO队列。在使用 FIFO 页面替换算法时会直接调用`_fifo_map_swappable`，这会将新加入的页面存入FIFO 算法所需要维护的队列(使用链表实现)的开头从而保证先进先出的实现。这个函数相当于起到标记这个页面将来是可以再换出的作用，具体的实现就是将该页插到了fifo队列的第一个。

14. **tlb_invalidate():**

    用于无效化 TLB（清除缓存的虚拟到物理地址映射）。它调用 `flush_tlb() `来触发实际的刷新操作。` flush_tlb() `执行 `sfence.vma` 指令，触发 TLB 刷新，确保虚拟地址映射的更新生效。

    

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

我们认为将两个功能都写在get_pte()中这种写法非常合理，而且完全没有必要将其拆开。

如果我们将查找和分配分开，可能会出现以下问题：如果查找函数只是返回 `NULL`，我们将无法明确判断缺失发生在哪一层——是页目录级别（PDE）的问题，还是页表级别（PTE）的问题。这样的设计会导致无法准确知道需要分配哪个层次的页表项，从而增加了额外的开销和复杂性。

例如，若我们将查找与分配分开，实现如下：

```c++
pte_t *find_pte(pde_t *pgdir, uintptr_t la, bool create){
    pde_t *pdep1 = &pgdir[PDX1(la)];
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}
```

这种实现的返回值一旦是 `NULL`，我们就无法直接判断是页目录项（PDE）缺失，还是页表项（PTE）缺失。如果仅仅通过查找，我们无法在查找失败后明确需要在哪一层分配新的页表项。这样，每次查找失败后，我们必须进行多层次的判断，增加了不必要的开销。

相反，如果我们将查找和分配合并，在递归查找每一层页目录或页表项的过程中，能够实时检查并分配缺失的项，这样一旦发现缺失就立即分配相应的页目录项或页表项，从而避免了不必要的后续查找操作。



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

    ```c
    struct Page { 
            int ref; // page frame's reference counter 
            uint_t flags; // array of flags that describe the status of the page frame 
            uint_t visited; 
            unsigned int property; // the num of free block, used in first fit pm manager 
            list_entry_t page_link; // free list link 
            list_entry_t pra_page_link; // used for pra (page replace algorithm) 
            uintptr_t pra_vaddr; // used for pra (page replace algorithm) 
        };
    ```

    总体而言：
     - struct Page 本身是对物理页帧的一种抽象，其中的成员用于跟踪页帧的状态，以及支持页面替换算法（如记录虚拟地址 pra_vaddr）。
     - PTE 中的 PPN 对应着物理页帧，每个物理页帧对应 struct Page 的一个数组项，。
     - PDE 和 PTE 类似， PDE 指向的下一级页表本身也是一个物理页帧，该物理页帧同样通过 struct Page 数组中的对应项进行管理。
  
    具体而言：
    - Ref，页帧被引用时计数。。
    - f1ags，内核状态标志，与表项的标志位协同使用。
    - Visited，操作系统自定义标志，与PTE的 Accessed 位配合使用，用于页面替换算法。
    - pra_page _link，页面替换链表，用于管理和选择换出的页面
    - pra vaddr，保存虚拟地址，便于在页面换出或换入时更新页表项。

6. **vma结构体成员作用**
    ```c
    struct vma_struct {
        struct mm_struct *vm_mm;  
        uintptr_t vm_start;         
        uintptr_t vm_end;        
        uint_t vm_flags;    
        list_entry_t list_link; 
    };
    ```
    - *vm_mm: 指向该 VMA 所属的内存描述符
    - vm_start: VMA 的起始虚拟地址   
    - vm_end: VMA 的结束虚拟地址     
    - vm_flags: 存储该 VMA 的标志信息，描述该虚拟内存区域的权限和属性 
    - list_link: 一个链表节点,用于将 VMA 组织成一个线性链表
    
    


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

3. **clock替换算法正确性验证**
   ```c
   //前述已经触发四次缺页，且测试中规定只有4个可用物理页，5个有效虚拟页
   *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==4);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==4);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==4);
    *(unsigned char *)0x2000 = 0x0b;
    ++ score; cprintf("grading %d/%d points", score, totalscore);
    assert(pgfault_num==4);//都不变，仍为4
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    //0X5000缺页，pgfault加1
   ```



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

6. **交换开销高**

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

lru算法设计：
 1. **_lru_init_mm: 初始化操作**
```c
static int _lru_init_mm(struct mm_struct *mm) {
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
    return 0;
}
```
- 这个函数用于初始化 LRU 算法所使用的页面队列 `pra_list_head`。
- `pra_list_head` 是一个链表的头部，用于管理所有的页面，队列中保存的是按照访问顺序排列的页面。
- 将 `pra_list_head` 的地址赋值给 `mm->sm_priv`，使得每个进程的 `sm_priv` 指向相同的链表头部。

 2. **_lru_map_swappable: 将页面放到队列尾部**
```c
static int _lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in) {
    list_entry_t *head = (list_entry_t *) mm->sm_priv;
    list_entry_t *entry = &(page->pra_page_link);

    assert(entry != NULL && head != NULL);

    // 如果页面已经在队列中，先将其移除
    list_del(entry);
    // 将页面加入 pra_list_head 队尾
    list_add_before(head, entry);
    return 0;
}
```
- **作用**：将指定的页面放到队列的尾部，即标记它为最近使用的页面。
- **流程**：
  - 如果页面已经在队列中，先将其从队列中删除。
  - 然后将该页面重新添加到队列头部（表示它是最新访问的页面）。此操作将页面从队尾移动到队头，确保最少使用的页面始终在队首。
- `swap_in` 参数虽然存在，但在代码中未被使用。它可能用于标记页面是否为换入操作。

 3. **_lru_swap_out_victim: 选择被换出的页面**
```c
static int _lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick) {
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
```
- **作用**：根据 LRU 算法选择一个页面进行换出（将其交换到磁盘或其他存储设备）。
- **流程**：
  - 选择链表中最先进入的页面（队首的页面），即最近最少使用的页面。
  - 如果链表非空，从队列中删除该页面，并将其传递给 `ptr_page`，表示被换出的页面。
  - 如果链表为空，则返回 `NULL`，表示没有页面需要换出。

 4. **_lru_check_swap: 检查 LRU 替换策略的正确性**
```c
static int _lru_check_swap(void) {
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
```
- **作用**：模拟对虚拟页面的访问，并通过写入不同的虚拟地址来触发页面缺失，从而测试 LRU 替换策略的正确性。
- **流程**：
  - 每次访问一个虚拟页面时，都会记录页面缺失（page fault）的次数，并确保 LRU 算法正确地替换了页面。
  - 通过访问不同的虚拟地址来验证替换策略是否按预期工作。

 5. **其他函数**
- **_lru_init**: 初始化 LRU 算法的状态，目前该函数没有实际操作。
- **_lru_set_unswappable**: 设置页面不可交换（不参与 LRU 替换），此函数当前也没有实际操作。
- **_lru_tick_event**: 该函数用于 LRU 算法的周期性更新（例如时间片到期时的处理），但目前没有实现。

 6. **swap_manager_lru: 注册 LRU 算法**
```c
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
- `swap_manager_lru` 是一个结构体，用于注册 LRU 替换算法的各个操作。
- 通过此结构体，操作系统可以识别和使用 LRU 算法进行页面替换。

7. **总结**
LRU（Least Recently Used）算法通过维护一个按访问顺序排列的页面链表，确保最久未使用的页面会被换出。通过这段代码，操作系统可以在内存不足时根据 LRU 策略选择合适的页面进行换出，从而高效地管理虚拟内存。



#### 实验中的知识点

**1.页、页表与多级页表机制**

**实验中的知识点：**

- 页是物理内存与虚拟内存之间的基本单位，支持内存的有效管理。
- 页表用于管理虚拟页到物理页的映射关系，操作系统利用页表进行地址转换。
- 多级页表机制通过分层结构减少单一页表过大所带来的内存开销。

**操作系统原理中的对应知识点：**

- **虚拟内存管理：** 页、页表和多级页表是虚拟内存管理的重要组成部分，它们支持虚拟地址到物理地址的转换，并使得操作系统能够将进程的虚拟地址空间映射到物理内存中。
- **分页机制：** 分页技术使得内存的管理更加灵活，通过固定大小的页来减少碎片问题，并提供内存保护与共享功能。
- **多级页表：** 多级页表是对大内存系统的一种优化方式，特别是在32位和64位系统中，直接使用单一页表会导致非常大的开销，因此多级页表通过分层存储页表，按需加载，有效降低内存消耗。

差异：实验中主要涉及页表和多级页表的基本操作，而操作系统原理则更深入探讨了如何通过这些机制实现内存的虚拟化和管理。

**2.页面置换算法**

**实验中的知识点：**

- **FIFO（先进先出）页替换算法：** 淘汰最早进入内存的页面，简单但在某些场景下不高效。
- **LRU（最久未使用）页替换算法：** 基于页面最近使用的历史来预测未来的访问，淘汰最久未被使用的页面。
- **时钟（Clock）页替换算法：** 近似LRU，利用环形链表和访问位来选择被淘汰的页面，开销较小。
- **改进的时钟算法：** 在时钟算法的基础上增加了修改位，优先淘汰未修改过的页面，以减少磁盘I/O操作。

**操作系统原理中的对应知识点：**

- **页面置换算法：** 页置换是虚拟内存系统中至关重要的机制之一，它处理的是内存不足时如何从内存中淘汰不再使用的页面。FIFO、LRU、Clock和改进的时钟算法都是常见的页替换策略。
- **虚拟内存管理：** 在操作系统原理中，虚拟内存的管理不仅需要页表来映射虚拟地址与物理地址，还需要页替换算法来解决内存不足时，如何有效管理内存中的页面。

含义与关系：页面置换算法解决了虚拟内存系统中的一个关键问题——如何在内存不足时有效地选择页面进行淘汰，以最小化性能损失。通过不同的算法策略，操作系统可以根据访问模式、历史行为等因素来优化内存的使用，保证系统的高效运行。

差异：实验中主要实现了具体的页替换算法，关注如何在程序运行时动态地进行内存页的替换。而操作系统原理更多涉及这些算法的理论基础、优缺点分析以及不同算法之间的性能对比。

#### **操作系统原理中重要但在实验中没有涉及的知识点**

**内存保护和共享**

- **描述：** 操作系统利用页表来提供内存保护和进程隔离，每个进程的虚拟地址空间独立且受到保护，同时也允许共享内存的机制（如共享库和内存映射文件）。
- **实验中的缺失：** 实验主要集中在虚拟地址到物理地址的映射和页面置换上，虽然这些与内存保护紧密相关，但并未深入探讨如何通过页表来实现保护和共享。
