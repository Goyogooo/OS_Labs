<div style="page-break-before: always; height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center;">
    <h1 style="margin-bottom: 50px;">操作系统实验报告1</h1>
    <h3>易文嘉 刘芳宜 高玉格</h3>
</div>

[TOC]

------



# lab0.5

## 练习1：使用GDB验证启动流程
### 实验过程
1. 环境配置好后在项目根目录下执行如下命令编译内核和生成镜像文件：
```shell
make
```
编译所有源文件，生成内核二进制文件 os.bin，并创建对应的调试文件。

2. 使用如下命令启动 QEMU，并挂起等待 GDB 的连接：
```shell
make debug
```
启动 QEMU 虚拟机，设置 CPU 挂起并等待调试器连接。

3. 在另一个终端中，运行命令如下命令启动 GDB 并连接到 QEMU:
```shell
make gdb
```
启动 GDB，设置好 RISC-V 架构并连接到 QEMU，准备调试。

   4.首先使用下面这条指令显示即将执行的10条汇编指令：

```shell
x/10i $pc
```

得到结果为：

```assembly
0x1000:	auipc	t0,0x0
0x1004:	addi	a1,t0,32
0x1008:	csrr	a0,mhartid
0x100c:	ld	t0,24(t0)
0x1010:	jr	t0
0x1014:	unimp
0x1016:	unimp
0x1018:	unimp
0x101a:	.insn	2, 0x8000
0x101c:	unimp
```

可以发现pc的初始值为0x1000。我们对汇编指令进行分析：

首先， auipc t0,0x0 指令将把符号位扩展的 20 位(左移 12 位) 立即数加到 pc 上，结果写入 t0，此时t0的值是**0x1000**。

然后，addi a1,t0,32 指令将 t0 中的 PC 高20位地址加上偏移量32,结果放入 a1 寄存器，此时a1寄存器的值是 **0x1020**。

其次，csrr a0,mhartid 指令从CSR的 mhartid 寄存器中读取并存入a0中。mhartid寄存器一般包括**硬件线程id**。执行后 a0 寄存器的值为 **0x0000** **0000** **0000** **0000。**

随后，ld t0,24(t0)指令从 t0+24 （0x1018）位置读取64位值加载至 t0 中。该指令执行后 t0 寄存器的值是 **0x80000000。**目的是为后续跳转指令提供目标地址值。

最后，jr t0 指令根据 t0 的值执行跳转指令。目的是跳转OpenSBI加载地址（即0x80000000）。

   5.我们使用si单步执行汇编指令进行验证，发现程序在执行到0x1010之后下一条指令是0x80000000，这说明0x1000是一个复位地址，加电后，cpu会跳转到0x1000处来执行复位代码，在复位代码中跳转到0x80000000处，这一地址是系统启动代码的入口点。

   6.显示 0x80000000 处的10条汇编指令：

```assembly
x/10i 0x80000000
```

```assembly
0x80000000:	csrr	a6,mhartid
0x80000004:	bgtz	a6,0x80000108
0x80000008:	auipc	t0,0x0
0x8000000c:	addi	t0,t0,1032
0x80000010:	auipc	t1,0x0
0x80000014:	addi	t1,t1,-16
0x80000018:	sd	t1,0(t0)
0x8000001c:	auipc	t0,0x0
0x80000020:	addi	t0,t0,1020
0x80000024:	ld	t0,0(t0)
```

   7.在 GDB 中，执行如下命令设置断点并继续执行：

```shell
break *0x80200000
continue
```
   8.发现最终程序输出：

```assembly
Breakpoint 1, kern_entry () at kern/init/entry.S:7
7	    la sp, bootstacktop
```

说明程序已进入 `kern_entry` 函数，并且将名为 `bootstacktop` 的内存地址加载到栈指针寄存器 `sp` 中，这通常是在系统初始化时设置栈的开始位置。

### 启动流程分析

1. 硬件加电后的第一条指令：
- 地址： 0x80000000
- 位置： 位于硬件固件或 Bootloader 区域（在本次实验中是 QEMU 自带的 OpenSBI 固件）
- 功能： 初始化硬件状态，包括设置堆栈指针、寄存器等基本的 CPU 设置。
2. 引导程序（Bootloader）的执行：

- 功能： 负责内存初始化、设备初始化、设置页表等，准备操作系统内核的加载。
- 细节： 将内核镜像从硬盘或其他存储器加载到物理内存中的指定位置。
  
3. 加载内核到内存：

- 地址： 内核镜像被加载到指定位置，这是操作系统内核的起始地址。
- 功能： Bootloader 将操作系统的代码和数据加载到指定内存区域，为内核的执行做好准备。
  
4. 跳转到内核入口地址：

- 功能： 设置程序计数器（PC），将 CPU 控制权交给内核，这个地址通常是 0x80200000。
- 关键点： 当执行到这个地址时，标志着硬件初始化完成，控制权交由操作系统内核。
  
### RISC-V硬件加电后的几条指令的位置及对应功能
1. 第一条指令位置： 0x80000000，在固件或 Bootloader 中，初始化 CPU 核心和硬件环境。
2. 后续初始化指令： 在 Bootloader 或固件中执行，负责设置堆栈指针、初始化寄存器，设置硬件状态，准备加载内核。
3. 内核加载指令： Bootloader 将内核镜像加载到内存地址通常为0x80200000，将操作系统代码和数据加载到指定内存区域。
4. 跳转指令： Bootloader 将 PC 设置为指定地址，将控制权移交给操作系统内核，开始执行内核的初始化代码。

### 本实验中的重要知识点

本实验中，我们构建了一个最小可执行内核，它能够进行格式化的输出并进入死循环。通过理解本实验的项目组成，我们了解了从处理器复位地址开始执行复位代码并启动Bootloader（OpenSBI固件）,Bootloader加载操作系统内核并跳转到操作系统入口点kern_entry，并随之跳转到”真正的入口点“kern_init中。在kern/init/init.c中的kern_init函数完成了格式化输出cprintf()后进入死循环。



------



# lab1

## 练习1：理解内核启动中的程序入口操作

### **la sp, bootstacktop**

这条指令将栈指针 `sp` 初始化为内核栈顶 `bootstacktop`。其目的是为内核的初始化阶段设置一个安全的栈空间，以便后续执行函数调用时有足够的栈空间。

### **tail kern_init**

`tail kern_init` 完成了跳转到 `kern_init` 函数的操作，同时它是一个尾调用优化形式，意味着它在执行过程中不会保留当前函数的返回地址，而是直接跳转到 `kern_init`，从而节省栈空间。目的是为了进行内核初始化。

### 关键知识点：

- 栈指针 `sp` 的初始化是为了确保内核在执行时有一个栈供其使用。
- `tail` 调用可以优化跳转操作，减少不必要的栈操作。

---

## 练习2：完善中断处理

### 实现 `trap.c` 中时钟中断处理

1. 首先在中断处理函数中，调用 `clock_set_next_event()` 设置下次时钟中断。
2. 每次时钟中断时，计数器 `ticks` 递增。当 `ticks` 达到 100 时，调用 `print_ticks()` 输出 "100 ticks"。
3. 每次输出 100 ticks 后，计数器 `num` 递增，判断是否已经打印了 10 次，如果是，则调用 `sbi.h` 中的 `shutdown()` 函数关机。

### 代码：

```c
// kern/trap/trap.c
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        case IRQ_U_SOFT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_SOFT:
            cprintf("Supervisor software interrupt\n");
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_TIMER:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB1 EXERCISE2   2213025 :  */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
            if (++ticks % TICK_NUM == 0) {
                print_ticks();
                num++;
            }
            if(num==10){
                sbi_shutdown();
            }
            break;
        case IRQ_H_TIMER:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_TIMER:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
            break;
        case IRQ_H_EXT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_EXT:
            cprintf("Machine software interrupt\n");
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
```

![64a249dd2a47fb3e9fd37924ad43cd5](D:\wwchat\WeChat Files\wxid_ivzcpp8606pg22\FileStorage\Temp\64a249dd2a47fb3e9fd37924ad43cd5.png)

运行`make qemu`，成功输出10行100 ticks。

### 关键知识点：

- 时钟中断的处理：每次时钟中断触发后，需要设置下次时钟事件。
- 通过计数器控制定时输出，并实现最终的关机操作。

---

## Challenge 1：中断处理流程

### **ucore处理中断异常的流程**

   在 RISC-V 中，当 CPU 遇到中断或异常时，系统会自动跳转到预先设置好的中断向量表中定义的中断处理程序。在 uCore 操作系统中，处理中断异常的流程如下：

- **异常发生**：

  - CPU 遇到一个中断或异常。
  - 当前执行流的状态（包括寄存器、程序计数器等）需要保存下来，以便处理完异常后能够恢复正常执行。
- **切换到异常处理代码**：

  - RISC-V 的 `stvec` 寄存器指向的地址保存了异常处理程序的入口地址。在 `idt_init()` 函数中，`stvec` 被设置为 `__alltraps`，该函数是中断/异常的统一入口。
- **进入 `__alltraps`**：

  - `__alltraps` 是汇编实现的入口函数，负责保存当前的 CPU 状态（包括所有寄存器）到栈中，以便后续的 C 语言代码能够使用这些寄存器，并处理中断或异常。
- **保存寄存器状态**：

  - `__alltraps` 会调用 `SAVE_ALL` 宏，将当前的所有寄存器保存到栈上。保存状态的顺序是预先定义好的，通常是按照 RISC-V 的寄存器 ABI 规范。
- **切换到内核栈**：

  - 在 `SAVE_ALL` 中的 `mov a0, sp`，将栈指针寄存器 `sp` 的值传递给 `a0`，这是为了将当前的栈指针传递给内核的 C 语言中断处理函数，以便后续的中断处理函数能够访问保存的寄存器信息。
- **进入 `trap`**：
  - 中断处理程序会调用 `trap` 函数，`trap` 根据 `scause` 寄存器的值来判断中断或异常的类型，然后分发给具体的中断处理函数或者异常处理函数。
- **处理完中断后恢复寄存器**：
  - 中断处理结束后，控制权返回到 `__alltraps`，从栈中恢复所有保存的寄存器状态，最后返回到被中断的程序位置，继续执行未完成的任务。

### mov a0, sp 的目的

该指令将当前栈指针 `sp` 的值保存到寄存器 `a0` 中，目的是将栈指针传递给异常处理函数，以便处理函数可以访问保存的寄存器状态。

在 `__alltraps` 中的 `mov a0, sp` 是将栈指针寄存器 `sp` 的值移动到寄存器 `a0` 中。其目的是为了将当前内核栈的栈顶指针传递给 C 语言函数 `trap`，从而让 `trap` 函数能够使用该栈指针来访问保存的寄存器状态和其他上下文信息。这样可以确保 C 语言的异常处理函数能够正确处理和访问保存的 CPU 状态。

### SAVE_ALL 中寄存器保存在栈中的位置确定

寄存器保存的位置根据 `sp` 的当前值向下偏移依次存储。每个寄存器对应的栈位置通过特定的偏移量来访问。

### __alltraps 中是否需要保存所有寄存器

是的。在中断发生时，需要保存所有寄存器，以确保中断处理完成后能够正确恢复被打断的进程的状态。这是因为中断可能会打断任意时刻的执行，因此需要保留所有的寄存器信息。

### 总结

中断处理流程从中断发生、保存寄存器状态到处理完中断后恢复寄存器状态，涉及多个关键步骤。`mov a0, sp` 是为了传递栈指针给中断处理函数，而 `SAVE_ALL` 确保所有寄存器都被保存，以便恢复时能回到中断前的状态。

---

## Challenge 2：理解上下文切换机制

### csrw sscratch, sp 和 csrrw s0, sscratch, x0 的作用

- `csrw sscratch, sp`：将当前栈指针 `sp` 的值保存到 `sscratch` CSR 中。
- `csrrw s0, sscratch, x0`：将 `sscratch` 寄存器中的当前值读取到通用寄存器 `s0` 中。
  将 `x0`（即 0）写入到 `sscratch` 寄存器中，将 `sscratch` 寄存器清零。

这两条指令的作用是保存当前的栈指针，并使用一个中间寄存器 `sscratch`作为临时存储，以确保中断处理函数能够访问到当前的栈。

### 保存了 `stval` 和 `scause`，但不还原的原因

`stval` 和 `scause` 是异常和中断的状态寄存器，用于记录异常类型和发生的地址。保存它们是为了在中断处理过程中能够参考这些信息，但在恢复时不需要还原，因为它们的内容已经在处理中使用过，不影响恢复原有的执行状态。

---

## Challenge 3：完善异常中断处理

增加了异常处理的代码，以及非法指令，来完善并测试异常中断处理。

```c
// kern/trap/trap.c
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
            case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3   2213025 :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type:Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
            tf->epc += 4;
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   2213025 :  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type:breakpoint\n");
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            tf->epc += 4;
            break;
    }
}

// kern/init/init.c
intr_enable(); // enable irq interrupt

asm("mret");// 测试非法指令异常
asm("ebreak");// 测试断点异常

while (1)
        ;
```

运行`make qemu`，输出如下：

![image-20240926193727678](C:\Users\vinga\AppData\Roaming\Typora\typora-user-images\image-20240926193727678.png)

## 总结

### 实验中的重要知识点

- **中断处理**：处理不同类型的中断和异常，保证系统能够正常应对外部和内部事件。
- **上下文切换**：保存和恢复上下文是内核调度和中断处理中的关键操作。
- **异常处理机制**：正确捕获和处理非法指令及断点，是确保系统稳定性的重要环节。

### OS原理中的重要知识点但实验中未涉及

- **进程调度算法**：实验中没有深入实现进程的调度策略。
- **内存管理机制**：虽然涉及到栈指针的使用，但没有具体实现内存分配和页面管理。
