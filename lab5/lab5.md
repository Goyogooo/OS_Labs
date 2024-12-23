# lab5实验报告


## 练习0

* 在 `alloc_proc`中添加额外的初始化：
  ```c
  proc->wait_state = 0;
  proc->cptr = NULL; // Child Pointer 表示当前进程的子进程
  proc->optr = NULL; // Older Sibling Pointer 表示当前进程的上一个兄弟进程
  proc->yptr = NULL; // Younger Sibling Pointer 表示当前进程的下一个兄弟进程
  ```
* 在 `do_fork`中修改代码如下：
  ```c
  if((proc = alloc_proc()) == NULL)
  {
      goto fork_out;
  }
  proc->parent = current; // 添加
  assert(current->wait_state == 0);
  if(setup_kstack(proc) != 0)
  {
      goto bad_fork_cleanup_proc;
  }
  ;
  if(copy_mm(clone_flags, proc) != 0)
  {
      goto bad_fork_cleanup_kstack;
  }
  copy_thread(proc, stack, tf);
  bool intr_flag;
  local_intr_save(intr_flag);
  {
      int pid = get_pid();
      proc->pid = pid;
      hash_proc(proc);
      set_links(proc);
  }
  local_intr_restore(intr_flag);
  wakeup_proc(proc);
  ret = proc->pid;
  ```

## 练习1

### 代码

将 `sp`设置为栈顶，`epc`设置为文件的入口地址，`sstatus`的 `SPP`位清零，代表异常来自用户态，之后需要返回用户态；`SPIE`位清零，表示不启用中断。

```c
#include <cow.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>

static int
setup_pgdir(struct mm_struct *mm) {
    struct Page *page;
    if ((page = alloc_page()) == NULL) {
        return -E_NO_MEM;
    }
    pde_t *pgdir = page2kva(page);
    memcpy(pgdir, boot_pgdir, PGSIZE);

    mm->pgdir = pgdir;
    return 0;
}

static void
put_pgdir(struct mm_struct *mm) {
    free_page(kva2page(mm->pgdir));
}

int
cow_copy_mm(struct proc_struct *proc) {
    struct mm_struct *mm, *oldmm = current->mm;

    /* current is a kernel thread */
    if (oldmm == NULL) {
        return 0;
    }
    int ret = 0;
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }
    lock_mm(oldmm);
    {
        ret = cow_copy_mmap(mm, oldmm);
    }
    unlock_mm(oldmm);

    if (ret != 0) {
        goto bad_dup_cleanup_mmap;
    }

good_mm:
    mm_count_inc(mm);
    proc->mm = mm;
    proc->cr3 = PADDR(mm->pgdir);
    return 0;
bad_dup_cleanup_mmap:
    exit_mmap(mm);
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    return ret;
}

int
cow_copy_mmap(struct mm_struct *to, struct mm_struct *from) {
    assert(to != NULL && from != NULL);
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list) {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }
        insert_vma_struct(to, nvma);
        if (cow_copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end) != 0) {
            return -E_NO_MEM;
        }
    }
    return 0;
}

int cow_copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    do {
        pte_t *ptep = get_pte(from, start, 0);
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        if (*ptep & PTE_V) {
            *ptep &= ~PTE_W;
            uint32_t perm = (*ptep & PTE_USER & ~PTE_W);
            struct Page *page = pte2page(*ptep);
            assert(page != NULL);
            int ret = 0;
            ret = page_insert(to, page, start, perm);
            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}

int 
cow_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    cprintf("COW page fault at 0x%x\n", addr);
    int ret = 0;
    pte_t *ptep = NULL;
    ptep = get_pte(mm->pgdir, addr, 0);
    uint32_t perm = (*ptep & PTE_USER) | PTE_W;
    struct Page *page = pte2page(*ptep);
    struct Page *npage = alloc_page();
    assert(page != NULL);
    assert(npage != NULL);
    uintptr_t* src = page2kva(page);
    uintptr_t* dst = page2kva(npage);
    memcpy(dst, src, PGSIZE);
    uintptr_t start = ROUNDDOWN(addr, PGSIZE);
    *ptep = 0;
    ret = page_insert(mm->pgdir, npage, start, perm);
    ptep = get_pte(mm->pgdir, addr, 0);
    return ret;
}
```

### 执行过程

1. 在 `init_main`中通过 `kernel_thread`调用 `do_fork`创建并唤醒线程，使其执行函数 `user_main`，这时该线程状态已经为 `PROC_RUNNABLE`，表明该线程开始运行
2. 在 `user_main`中通过宏 `KERNEL_EXECVE`，调用 `kernel_execve`
3. 在 `kernel_execve`中执行 `ebreak`，发生断点异常，转到 `__alltraps`，转到 `trap`，再到 `trap_dispatch`，然后到 `exception_handler`，最后到 `CAUSE_BREAKPOINT`处
4. 在 `CAUSE_BREAKPOINT`处调用 `syscall`
5. 在 `syscall`中根据参数，确定执行 `sys_exec`，调用 `do_execve`
6. 在 `do_execve`中调用 `load_icode`，加载文件
7. 加载完毕后一路返回，直到 `__alltraps`的末尾，接着执行 `__trapret`后的内容，到 `sret`，表示退出S态，回到用户态执行，这时开始执行用户的应用程序

## 练习2 父进程复制自己的内存空间给子进程（需要编码）

创建子进程的函数`do_fork`在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过`copy_range`函数（位于kern/mm/pmm.c中）实现的，请补充`copy_range`的实现，确保能够正确执行。

请在实验报告中简要说明你的设计实现过程。



在 copy_range 中实现了将父进程的内存空间复制给子进程的功能。逐个内存页进行复制，首先找到父

进程的页表项，然后创建一个子进程新的页表项，设置对应的权限，然后将父进程的页表项对应的内存

页复制到子进程的页表项对应的内存页中，然后将子进程的页表项加入到子进程的页表中。

```c++
void * src_kvaddr = page2kva(page); / 父进程的内存页的 kernel addr
void * dst_kvaddr = page2kva(npage); / 子进程的内存页的 kernel addr
memcpy(dst_kvaddr, src_kvaddr, PGSIZE); / 复制内存页
ret = page_insert(to, npage, start, perm); / 将子进程的页表项加入到子进程的页表中
```

`Copy on Write`机制设计见challenge部分。



#### 练习3: 阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）

##### 3.1 **进程创建：`fork` 系统调用**

`fork` 是用于创建新进程的系统调用。在用户态，调用 `fork()` 后，当前进程（父进程）将请求内核创建一个新的进程（子进程）。当 `fork()` 被调用时，操作系统会进行以下操作：

首先，用户进程通过系统调用进入内核态，调用 `sys_fork()` 函数。该函数会调用 `do_fork()`，这是 `fork` 操作的核心实现。`do_fork()` 中，操作系统通过分配一个新的 `proc_struct`（进程控制块）为子进程创建一个新的进程结构，并设置父进程指针。接着，操作系统为子进程分配内核栈，复制父进程的内存管理信息，或者根据标志决定是否共享父进程的内存结构。然后，操作系统设置子进程的执行状态和上下文，并将子进程插入到进程调度队列中。最后，操作系统通过 `wakeup_proc()` 函数唤醒新进程，使其变为可运行状态。

父进程和子进程会在 `fork()` 调用处返回不同的值：父进程返回子进程的 PID，而子进程则返回 0。这种父子进程的关系和 `fork` 的执行机制为后续的进程调度和资源管理奠定了基础。

##### 3.2 **进程执行：`exec` 系统调用**

`exec` 系统调用用于将当前进程的映像替换为另一个程序的映像。在用户态，调用 `exec()` 后，进程会请求内核加载新的程序，并在进程地址空间中运行该程序。`exec` 的具体实现涉及多个重要步骤：

首先，`sys_exec()` 函数会检查当前进程是否占用了内存资源。如果进程已经加载了某些资源（如内存映射），则会进行清理工作，包括释放内存映射、页目录表和相关的内存管理结构。接下来，内核调用 `do_execve()` 来加载新的程序。`do_execve()` 会根据用户提供的程序路径加载新的二进制文件，将其代码段加载到当前进程的地址空间中。执行完这些操作后，当前进程的内存空间会被新程序的内容完全替代，进程的执行便开始转向新的程序代码。

`exec` 系统调用的一个关键特点是，它并不创建新进程，而是通过替换进程的映像来改变当前进程的行为。这使得 `exec` 成为操作系统中进程生命周期的重要组成部分，通常与 `fork` 配合使用，形成父子进程间的进程替换或继承。

##### 3.3 **进程等待：`wait` 系统调用**

`wait` 系统调用是用于父进程等待子进程结束的机制。父进程通过 `wait()` 请求内核等待其子进程的退出状态。在用户态，父进程调用 `wait()` 系统调用后，内核进入处理阶段。在内核态，调用 `sys_wait()`，它会进一步调用 `do_wait()` 函数来实现父进程的等待。

在 `do_wait()` 中，内核首先检查是否存在子进程。如果父进程的某个子进程已经退出，内核会获取该子进程的退出状态，并释放与子进程相关的资源。如果没有找到已退出的子进程，父进程会进入休眠状态，等待子进程退出。这一过程中，父进程的状态会被设置为 `PROC_SLEEPING`，并且会根据进程调度的需要，进入调度队列，等待唤醒。子进程退出后，父进程会被唤醒，继续执行。

`wait` 系统调用的作用不仅是让父进程等待子进程退出，还能帮助系统回收子进程退出时产生的资源，防止出现“僵尸进程”——那些已经退出但仍占用系统资源的进程。

##### 3.4 **进程退出：`exit` 系统调用**

`exit` 系统调用是用来终止当前进程并进行相关资源清理的机制。当进程执行 `exit()` 时，内核会通过 `sys_exit()` 和 `do_exit()` 完成进程退出的工作。在 `do_exit()` 中，内核首先检查当前进程是否是系统的空闲进程（如 `idleproc` 或 `initproc`）。如果是，则触发内核的 `panic()`，因为这些特殊进程不能被终止。

接下来，内核会进行一系列清理工作：释放进程占用的内存，减少对内存管理结构的引用计数，并在必要时销毁与进程相关的内存映射。进程的状态会被设置为 `PROC_ZOMBIE`，表示进程已经终止，但仍需等待父进程获取其退出状态。

此外，如果父进程正在等待子进程退出，内核会唤醒父进程继续执行。若子进程还有其他子进程，内核会将它们的状态设置为 `PROC_ZOMBIE`，并将它们与初始化进程的子进程链表进行连接，以确保它们在合适的时机被处理。最后，内核通过进程调度器 `schedule()` 选择一个新的进程执行。



#### 扩展练习 Challenge

1. 实现 Copy on Write （COW）机制

   给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。

   这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。

   由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/ 看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。

   这是一个big challenge.

##### 1.1 COW 概述

Copy on Write 是一种懒复制策略，当一个进程的内存页面被标记为只读时，如果该页面被修改，则会触发页面错误（Page Fault），操作系统随后会为该进程分配新的内存页面，并将原页面的内容复制到新的页面中。此时，修改只会影响当前进程，不会影响共享的父进程。

##### 1.2 COW 机制中的状态转换

COW机制的状态可以看作有限状态自动机（FSM）。一个典型的状态转换模型如下：

- **初始化状态**：父进程创建子进程时，父进程的页表中的某些页面标记为只读（read-only），父子进程共享这些页面。
- **修改状态**：当某进程尝试修改共享页面时，会触发页面错误（page fault）。操作系统捕获该错误后会进行页面复制（copy），并将新分配的页面映射到进程的地址空间，修改进程的页面标记为可写（writable）。
- **独立状态**：一旦进程拥有其独立的页面，该页面将不再与其他进程共享，进程可以自由修改，而不影响其他进程。

##### 1.3 COW 实现中的关键步骤

1. **进程创建时标记页面为只读**：当父进程通过 `fork()` 创建子进程时，共享的内存页面标记为只读。
2. **页面错误处理**：当一个进程试图修改这些只读页面时，触发页面错误。操作系统会复制页面内容，分配新的物理页面，并更新进程的页表。
3. **更新页表**：进程的页表需要被更新，确保父子进程在修改内存时拥有独立的页面。

##### 1.4 实现源码

dup_mmap:

```c
int dup_mmap(struct mm_struct to, struct mm_struct from) {
		//省略部分代码；
        bool share = 1;
                
}
```

copy_range:

```C
//省略部分代码；
if(share){
        page_insert(from, page, start, perm & (~PTE_W));
        ret = page_insert(to, page, start, perm & (~PTE_W));
    }
    else{
        struct Page *npage = alloc_page();
        assert(npage != NULL);
        void* src_kvaddr = page2kva(page);
        void* dst_kvaddr = page2kva(npage);
        memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
        ret = page_insert(to, npage, start, perm);
    }
```

do_pgfault:

```C
//省略部分代码；
else if((*ptep & PTE_V) && (error_code == 0xf)) {
        struct Page *page = pte2page(*ptep);
        if(page_ref(page) == 1) {
            page_insert(mm->pgdir, page, addr, perm);
        }
        else {
            struct Page *npage = alloc_page();
            assert(npage != NULL);
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
            if(page_insert(mm->pgdir, npage, addr, perm) != 0) {
                cprintf("page_insert in do_pgfault failed\n");
                goto failed;
            }
        }
    }
```

​	2.说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

##### 2.1 用户程序何时被预加载

在 `execve` 调用中，当前的进程执行环境会被替换成新的程序。具体步骤包括：

1. **清理当前进程的内存空间** ：

* 释放当前进程的用户内存和相关资源。

1. **加载新程序的二进制文件** ：

* 从磁盘读取 ELF 文件或其他可执行格式文件的内容。
* 根据文件内容加载程序代码段和数据段到内存。
* 将程序入口点设置为新进程的起始地址。

1. **初始化运行环境** ：

* 设置栈指针、堆区、用户栈等初始状态。
* 将控制权转交给新加载的程序入口。

因此，程序在 **`execve` 系统调用** 时完成加载。这是一种明确的加载时机，即  **执行时预加载** 。

---

##### 2.2 与常用操作系统的区别

在现代常用操作系统中（如 Linux、Windows），程序的加载采用 **懒加载（Lazy Loading）** 策略，而非预加载：

#### **懒加载**

* 程序代码段和数据段不会立即全部加载到内存。
* 系统仅加载程序的关键元数据（如 ELF 文件头、页表等）以及一部分代码段。
* 只有在实际访问内存页时，触发缺页中断（Page Fault），操作系统才会将对应的页面加载到内存中。

#### **预加载**

* 在操作系统中，某些实验性或简化设计场景下会选择一次性加载整个用户程序到内存。
* 预加载的好处是简化了内存管理和页面调度逻辑，适用于教育场景或小型操作系统。

---

##### **2.3 两种策略的对比**

| **特性**     | **懒加载（现代 OS）**          | **预加载（实验 OS）**              |
| ------------ | ------------------------------ | ---------------------------------- |
| **加载时机** | 程序运行时分块加载             | `execve`时一次性加载整个程序       |
| **内存开销** | 较低，动态按需分配             | 较高，可能加载大量未访问的数据     |
| **性能**     | 初始加载较快，运行中有额外开销 | 初始加载时间较长，但运行时开销较低 |
| **复杂度**   | 需要实现缺页处理和分页机制     | 实现简单，无需分页机制             |
| **适用场景** | 高性能通用操作系统             | 实验系统、小型嵌入式设备           |

---

### 2.4 选择预加载的原因

* **简化实现** ：
* 在实验性操作系统中，内存管理和分页机制可能尚未完全实现，预加载可以避免处理复杂的缺页中断。
* **性能需求** ：
* 在受限环境中，如嵌入式设备或微内核实验系统，预加载的方式可以减少运行时的 I/O 操作，提升响应速度。
* **适应环境** ：
* 若目标系统的内存资源足够且程序规模较小，预加载带来的内存浪费并不显著。

---

总结来说，预加载机制是为了简化实验性操作系统的实现，同时可以提供运行时的快速响应。而常用操作系统选择懒加载是为了提升资源利用率和应对复杂的多任务场景。
