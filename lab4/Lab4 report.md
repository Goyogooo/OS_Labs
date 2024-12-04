### 练习

对实验报告的要求：

- 基于markdown格式来完成，以文本方式为主
- 填写各个基本练习中要求完成的报告内容
- 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
- 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

#### 练习0：填写已有实验

本实验依赖实验2/3。请把你做的实验2/3的代码填入本实验中代码中有“LAB2”,“LAB3”的注释相应部分。

#### 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

> 【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）



初始化代码如下：

```c++
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 2213025
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
```

设计过程：alloc_proc函数通过kmalloc函数获得proc_struct结构的一块内存块作为第0个进程控制块并把proc进行初步初始化（即把proc_struct中的各个成员变量清零）

- state设置为未初始化状态；
- 由于刚创建进程，pid设置为-1；
- 进程运行次数run初始化为0；
- 内核栈地址kstack默认从0开始；
- need_resched是一个用于判断当前进程是否需要被调度的bool类型变量，为1则需要进行调度。初始化为0，表示不需要调度；
- 父进程parent设置为空；
- 内存空间初始化为空；
- 上下文结构体context初始化为0；
- 中断帧指针tf设置为空；
- 页目录cr3设置为为内核页目录表的基址boot_cr3；
- 标志位flags设置为0；
- 进程名name初始化为0；

问题回答：

在操作系统中， proc_struct 数据结构用于存储有关进程的各种信息。struct context 和struct trapframe 是proc_struct 中的成员，它们的**成员变量含义**如下:

`struct context context`用于保存进程上下文，即进程被中断或切换出CPU时需要保存的几个关键的寄存器，如程序计数器(PC)、堆栈指针(SP)和其他寄存器。当操作系统决定恢复一个进程的执行时，会从这个结构体中恢复寄存器的状态，从而继续执行进程。在 ucore 中，context 结构通常在上下文切换函数 switch_to 中被使用。

`struct trapframe *tf`指针指向一个 trapframe 结构，该结构包含了当进程进入内核模式时(比如因为系统调用或硬件中断)需要保存的信息。 trapframe 保存了中断发生时的CPU状态，包括所有的寄存器值和程序计数器(epc)。这使得操作系统可以准确地了解中断发生时进程的状态，并且可以在处理完中断后恢复到之前的状态继续执行。在系统调用或中断处理的代码中经常会用到这个结构。

在本实验中，这两个结构在进程调度和中断处理的**作用**是:

`context` 结构体用于保存进程的执行上下文，包括一些关键的寄存器值（如 `ra`、`sp` 和 `s0` 至 `s11` 等），这些寄存器用于进程切换时保存和恢复进程的状态。进程调度时，当操作系统需要切换进程时，当前进程的寄存器状态会被保存在 `context` 中，以便在下次调度时恢复执行。

`tf` 是进程的中断帧，在处理系统调用、异常或中断时使用。当进程从用户模式切换到内核模式时，用户模式下的状态(如寄存器)会被保存在 trapframe 中。内核完成处理后，可以使用这些信息来恢复进程的状态并继续用户模式下的执行。



#### 练习2：为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要"fork"的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

- 调用alloc_proc，首先获得一块用户信息块。
- 为进程分配一个内核栈。
- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
- 复制原进程上下文到新进程
- 将新进程添加到进程列表
- 唤醒新进程
- 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

#### 练习3：编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
- 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
- 切换当前进程为要运行的进程。
- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lcr3(unsigned int cr3)`函数，可实现修改CR3寄存器值的功能。
- 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
- 允许中断。

请回答如下问题：

- 在本实验的执行过程中，创建且运行了几个内核线程？

完成代码编写后，编译并运行代码：make qemu

如果可以得到如 附录A所示的显示内容（仅供参考，不是标准答案输出），则基本正确。

##### 1）实现代码

```c
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
        local_intr_save(intr_flag);
        {
            
            current = proc;
            lcr3(next->cr3);//new PDT
            switch_to(&(prev->context), &(next->context));
            //STORE ra, 0*REGBYTES(a0)   LOAD ra, 0*REGBYTES(a1)
            //ra（返回地址寄存器）：保存函数返回地址。
            //sp（堆栈指针寄存器）：保存堆栈指针。
            //s0 - s11（保存寄存器）：这些寄存器用于保存需要跨函数调用保持的数据。
            //因为线程切换在一个函数当中，所以编译器会自动帮助我们生成保存和恢复调用者保存寄存器的代码，
            //在实际的进程切换过程中我们只需要保存被调用者保存寄存器.
        }
        local_intr_restore(intr_flag);
        //sync.h:
        
#define local_intr_restore(x) __intr_restore(x);
        
    }
}
```

##### 2）在本实验的执行过程中，创建且运行了几个内核线程？

答：两个内核线程  **idleproc ** (pid = 0) 和 **initproc** (pid = 1) 。

分析：进程模块的初始化主要分为两步，首先创建第0个内核进程，idleproc。在kern_init函数中，当完成虚拟内存的初始化工作后，就调用了proc_init函数。这个函数完成了idleproc内核线程和initproc内核线程的创建或复制工作，idleproc内核线程的工作就是不停地查询，看是否有其他内核线程可以执行了，如果有，马上让调度器选择那个内核线程执行。接着就是调用kernel_thread函数来创建initproc内核线程，initproc内核线程的工作就是显示“Hello World”，表明自己存在且能正常工作了。



#### 扩展练习 Challenge：

- 说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

  ```c
  //相关的函数
  static inline bool __intr_save(void) {
      if (read_csr(sstatus) & SSTATUS_SIE) {//读取中断状态寄存器如果使能位为开启状态
          intr_disable();//clear 清零禁用中断
          return 1;//原来启用
      }
      return 0;//原来禁用
  }
  
  static inline void __intr_restore(bool flag) {
      if (flag) {//原来启用中断
          intr_enable();//重新置位开启中断
      }
      //原来禁用不用开启
  }
  
  #define local_intr_save(x) \
      do {                   \
          x = __intr_save(); \
      } while (0)\\保证安全性
  #define local_intr_restore(x) __intr_restore(x);
  
  void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }//给sstatus的SIE置位
  
  
  void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }//给sstatus的SIE清零
  
  ```

  核心是通过给sstatus寄存器的SIE位置位和清零实现的开启中断和禁用中断。