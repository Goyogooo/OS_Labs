#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc, 
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:
                                            
  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+ 
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->do_wait
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep 
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit   
SYS_getpid      : get the process's pid

*/

/*
PROC_UNINIT：未初始化状态。alloc_proc（分配进程结构体）

PROC_RUNNABLE：可运行状态，表示进程可以被调度。proc_init、wakeup_proc（进程初始化或唤醒进程）

PROC_SLEEPING：睡眠状态，表示进程正在等待某种事件发生。try_free_pages、do_wait、do_sleep（等待、睡眠或释放内存）

PROC_ZOMBIE：僵尸状态，表示进程已终止但尚未被父进程回收资源。do_exit（进程退出）

进程状态从 PROC_UNINIT 到 PROC_ZOMBIE 的转变过程如下：

alloc_proc：分配一个新的进程。
proc_init / wakeup_proc：将进程状态设为 PROC_RUNNABLE，使进程可以被调度运行。
try_free_pages / do_wait / do_sleep：进程进入 PROC_SLEEPING 状态，表示进程处于等待或休眠中。
do_exit：进程进入 PROC_ZOMBIE 状态，表示进程已经终止，但尚未被完全清理。

父进程：通过 proc->parent 获取，proc 是子进程。
子进程：通过 proc->cptr 获取，proc 是父进程。
年长的兄弟进程：通过 proc->optr 获取，proc 是年轻的兄弟进程。
年轻的兄弟进程：通过 proc->yptr 获取，proc 是年长的兄弟进程。

与进程相关的系统调用：
SYS_exit：进程退出，通过 do_exit 实现。
SYS_fork：创建子进程，并复制父进程的内存空间（dup mm），通过 do_fork 创建子进程并调用 wakeup_proc 唤醒新进程。
SYS_wait：等待进程结束，通过 do_wait 实现。
SYS_exec：进程调用 exec 系统调用后，加载程序并刷新内存管理信息。
SYS_clone：创建子线程，类似于 fork，但线程共享父进程的内存空间，通过 do_fork 和 wakeup_proc 实现。
SYS_yield：进程表示自己需要被重新调度（设置 proc->need_sched = 1），然后调度器将重新调度此进程。
SYS_sleep：进程进入睡眠状态，通过 do_sleep 实现。
SYS_kill：终止进程，通过 do_kill 和设置 proc->flags |= PF_EXITING 使进程退出，然后调用 wakeup_proc 和 do_wait 来清理进程。
SYS_getpid：获取当前进程的 PID。

*/
// the process set's list
list_entry_t proc_list;

#define HASH_SHIFT          10
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc
struct proc_struct *idleproc = NULL;
// init proc
struct proc_struct *initproc = NULL;
// current proc
struct proc_struct *current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
//初始化
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE
    /*
     * below fields in proc_struct need to be initialized
     *       enum proc_state state;                      // Process state
     *       int pid;                                    // Process ID
     *       int runs;                                   // the running times of Proces
     *       uintptr_t kstack;                           // Process kernel stack
     *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
     *       struct proc_struct *parent;                 // the parent process
     *       struct mm_struct *mm;                       // Process's memory management field
     *       struct context context;                     // Switch here to run process
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
    proc->state = PROC_UNINIT;  //设置进程为“初始”态
    proc->pid = -1;             //设置进程pid的未初始化值
    proc->cr3 = boot_cr3;       //使用内核页目录表的基址
    proc->runs=0;               //设置进程运行次数为0
    proc->kstack=0;             //设置内核栈地址为0(还未分配)
    proc->need_resched =0;      //设置不需要重新调度   
    proc->parent = NULL;        // 设置父进程为空 
    proc->mm = NULL;            // 设置内存管理字段为空
    memset(&(proc->context),0,sizeof(struct context));          // 初始化上下文信息为0
    proc->tf = NULL;            //设置trapframe为空
    proc->flags =0;             // 设置进程标志为0
    memset(proc->name,0,PROC_NAME_LEN);         //初始化进程名为0
    }
    return proc;
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}
//遍历 proc_list，寻找一个未被占用的 PID，确保每个进程的 PID 是唯一的
// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;//在遍历进程列表时指向当前的进程结构体
    list_entry_t *list = &proc_list, *le;// 定义进程列表的入口指针，le 用来遍历列表
    static int next_safe = MAX_PID, last_pid = MAX_PID;// next_safe 用来存储下一个可用的安全 PID
    //到达上限 MAX_PID，重置为 1
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;//准备重新开始遍历整个进程列表来寻找未使用的 PID
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {//list_next(le) 来遍历链表
            proc = le2proc(le, list_link);//将链表节点 le 转换为进程结构体 proc
            if (proc->pid == last_pid) {//last_pid 已被占用
                if (++ last_pid >= next_safe) {//递增 last_pid，并检查是否超过 next_safe
                    if (last_pid >= MAX_PID) {//如果超过，则重置 last_pid 为 1
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {//更新 next_safe 为当前进程的 PID
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

//将指定的进程切换到CPU上运行
/*
- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
- 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
- 切换当前进程为要运行的进程。
- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lcr3(unsigned int cr3)`函数，可实现修改CR3寄存器值的功能。
- 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
- 允许中断。
*/
// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
        local_intr_save(intr_flag);//禁用中断
        {
            current = proc;
            lcr3(next->cr3);//更新 CR3 寄存器（切换页表）
            switch_to(&(prev->context), &(next->context));//上下文切换，将当前进程切换为 proc 进程
        }
        local_intr_restore(intr_flag);//启用中断
    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
//新的进程/线程在创建后从这个函数开始执行
//设置进程的内核栈和 trapframe，然后调用 forkrets() 函数
static void
forkret(void) {
    forkrets(current->tf);//当前进程的 trapframe 指针
}

//将进程添加到哈希链表中，便于根据 PID 查找进程
// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

//在哈希表中查找指定 PID 的进程，若找到则返回该进程结构体
// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}

//创建一个新的内核线程
// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    struct trapframe tf;//为新线程分配一个 trapframe
    memset(&tf, 0, sizeof(struct trapframe));
    tf.gpr.s0 = (uintptr_t)fn;
    tf.gpr.s1 = (uintptr_t)arg;
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    tf.epc = (uintptr_t)kernel_thread_entry;
    return do_fork(clone_flags | CLONE_VM, 0, &tf);//调用 do_fork 创建子进程
}

//为进程分配一块内存作为内核栈
// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
static int
setup_kstack(struct proc_struct *proc) {
    struct Page *page = alloc_pages(KSTACKPAGE);
    if (page != NULL) {
        proc->kstack = (uintptr_t)page2kva(page);
        return 0;
    }
    return -E_NO_MEM;
}
//释放进程的内核栈
// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    assert(current->mm == NULL);
    /* do nothing in this project */
    return 0;
}

//为新进程/线程设置内核栈和陷入处理框架（trapframe），并设置上下文
// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
    *(proc->tf) = *tf;

    // Set a0 to 0 so a child process knows it's just forked
    proc->tf->gpr.a0 = 0;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;

    proc->context.ra = (uintptr_t)forkret;
    proc->context.sp = (uintptr_t)(proc->tf);
}
//给线程分配资源，并且复制原进程的状态
/* do_fork -     parent process for a new child process
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {//无法创建更多进程
        goto fork_out;
    }
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid

    

    proc = alloc_proc();//为新进程分配资源
    proc->parent = current;
    setup_kstack(proc);//为子进程分配内核栈
    copy_mm(clone_flags, proc);//复制父进程的内存管理信息
    copy_thread(proc, stack, tf);//复制父进程的线程信息
    int pid = get_pid();//分配一个唯一的进程 ID
    proc->pid = pid;
    hash_proc(proc);
    list_add(&proc_list, &(proc->list_link));//将进程加入哈希表（方便进程查找）和进程链表
    nr_process++;//当前活跃进程的数量
    proc->state = PROC_RUNNABLE;//可运行状态
    ret = proc->pid;//将新进程的 PID 返回

fork_out:
    return ret;
//用于在进程创建过程中发生错误时进行清理工作
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}

// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int
do_exit(int error_code) {
    panic("process exit!!.\n");
}

// 进程退出。清理进程的资源（如内存），设置进程状态为 PROC_ZOMBIE，通知父进程回收资源，并调用 scheduler 切换到其他进程。

//初始化进程 initproc
// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
    cprintf("To U: \"%s\".\n", (const char *)arg);
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
    return 0;
}

//启动第一个进程（idleproc）和第二个进程（initproc）
// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int*) kmalloc(sizeof(struct context));
    memset(context_mem, 0, sizeof(struct context));
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));

    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
    ){
        cprintf("alloc_proc() correct!\n");

    }
    
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    set_proc_name(idleproc, "idle");
    nr_process ++;

    current = idleproc;

    int pid = kernel_thread(init_main, "Hello world!!", 0);//通过 kernel_thread 创建 init_main 进程
    if (pid <= 0) {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

//当没有进程可调度时，idleproc 进程将一直执行此函数cpu空转
// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
    while (1) {
        if (current->need_resched) {//在循环中检查当前进程是否需要重新调度，如果需要则调用 schedule 进行进程调度
            schedule();//PROC_RUNNABLE
        }
    }
}
/*
1．设置当前内核线程current->need_resched为0； 

2．在proc_list队列中查找下一个处于“就绪”态的线程或进程next；

 3．找到这样的进程后，就调用**proc_run函数**（调用switch_to函数），保存当前进程current的执行现场（进程上下文），恢复新进程的执行现场，完成进程切换。
*/