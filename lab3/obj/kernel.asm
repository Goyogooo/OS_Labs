
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:


int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	0000a517          	auipc	a0,0xa
ffffffffc0200036:	00e50513          	addi	a0,a0,14 # ffffffffc020a040 <ide>
ffffffffc020003a:	00011617          	auipc	a2,0x11
ffffffffc020003e:	53e60613          	addi	a2,a2,1342 # ffffffffc0211578 <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16 # ffffffffc0208ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	4dc040ef          	jal	ffffffffc0204526 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020004e:	00004597          	auipc	a1,0x4
ffffffffc0200052:	50258593          	addi	a1,a1,1282 # ffffffffc0204550 <etext>
ffffffffc0200056:	00004517          	auipc	a0,0x4
ffffffffc020005a:	51a50513          	addi	a0,a0,1306 # ffffffffc0204570 <etext+0x20>
ffffffffc020005e:	05c000ef          	jal	ffffffffc02000ba <cprintf>

    print_kerninfo();
ffffffffc0200062:	09e000ef          	jal	ffffffffc0200100 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc0200066:	2db010ef          	jal	ffffffffc0201b40 <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006a:	4e8000ef          	jal	ffffffffc0200552 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020006e:	716030ef          	jal	ffffffffc0203784 <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200072:	40e000ef          	jal	ffffffffc0200480 <ide_init>
    swap_init();                // init swap
ffffffffc0200076:	167020ef          	jal	ffffffffc02029dc <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020007a:	344000ef          	jal	ffffffffc02003be <clock_init>
    // intr_enable();              // enable irq interrupt



    /* do nothing */
    while (1);
ffffffffc020007e:	a001                	j	ffffffffc020007e <kern_init+0x4c>

ffffffffc0200080 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200080:	1141                	addi	sp,sp,-16
ffffffffc0200082:	e022                	sd	s0,0(sp)
ffffffffc0200084:	e406                	sd	ra,8(sp)
ffffffffc0200086:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200088:	388000ef          	jal	ffffffffc0200410 <cons_putc>
    (*cnt) ++;
ffffffffc020008c:	401c                	lw	a5,0(s0)
}
ffffffffc020008e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200090:	2785                	addiw	a5,a5,1
ffffffffc0200092:	c01c                	sw	a5,0(s0)
}
ffffffffc0200094:	6402                	ld	s0,0(sp)
ffffffffc0200096:	0141                	addi	sp,sp,16
ffffffffc0200098:	8082                	ret

ffffffffc020009a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009a:	1101                	addi	sp,sp,-32
ffffffffc020009c:	862a                	mv	a2,a0
ffffffffc020009e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	00000517          	auipc	a0,0x0
ffffffffc02000a4:	fe050513          	addi	a0,a0,-32 # ffffffffc0200080 <cputch>
ffffffffc02000a8:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000aa:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ac:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ae:	7b5030ef          	jal	ffffffffc0204062 <vprintfmt>
    return cnt;
}
ffffffffc02000b2:	60e2                	ld	ra,24(sp)
ffffffffc02000b4:	4532                	lw	a0,12(sp)
ffffffffc02000b6:	6105                	addi	sp,sp,32
ffffffffc02000b8:	8082                	ret

ffffffffc02000ba <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000ba:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000bc:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000c0:	f42e                	sd	a1,40(sp)
ffffffffc02000c2:	f832                	sd	a2,48(sp)
ffffffffc02000c4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c6:	862a                	mv	a2,a0
ffffffffc02000c8:	004c                	addi	a1,sp,4
ffffffffc02000ca:	00000517          	auipc	a0,0x0
ffffffffc02000ce:	fb650513          	addi	a0,a0,-74 # ffffffffc0200080 <cputch>
ffffffffc02000d2:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d4:	ec06                	sd	ra,24(sp)
ffffffffc02000d6:	e0ba                	sd	a4,64(sp)
ffffffffc02000d8:	e4be                	sd	a5,72(sp)
ffffffffc02000da:	e8c2                	sd	a6,80(sp)
ffffffffc02000dc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000de:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e0:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e2:	781030ef          	jal	ffffffffc0204062 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e6:	60e2                	ld	ra,24(sp)
ffffffffc02000e8:	4512                	lw	a0,4(sp)
ffffffffc02000ea:	6125                	addi	sp,sp,96
ffffffffc02000ec:	8082                	ret

ffffffffc02000ee <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000ee:	a60d                	j	ffffffffc0200410 <cons_putc>

ffffffffc02000f0 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f0:	1141                	addi	sp,sp,-16
ffffffffc02000f2:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000f4:	350000ef          	jal	ffffffffc0200444 <cons_getc>
ffffffffc02000f8:	dd75                	beqz	a0,ffffffffc02000f4 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02000fa:	60a2                	ld	ra,8(sp)
ffffffffc02000fc:	0141                	addi	sp,sp,16
ffffffffc02000fe:	8082                	ret

ffffffffc0200100 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200100:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200102:	00004517          	auipc	a0,0x4
ffffffffc0200106:	47650513          	addi	a0,a0,1142 # ffffffffc0204578 <etext+0x28>
void print_kerninfo(void) {
ffffffffc020010a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020010c:	fafff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200110:	00000597          	auipc	a1,0x0
ffffffffc0200114:	f2258593          	addi	a1,a1,-222 # ffffffffc0200032 <kern_init>
ffffffffc0200118:	00004517          	auipc	a0,0x4
ffffffffc020011c:	48050513          	addi	a0,a0,1152 # ffffffffc0204598 <etext+0x48>
ffffffffc0200120:	f9bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200124:	00004597          	auipc	a1,0x4
ffffffffc0200128:	42c58593          	addi	a1,a1,1068 # ffffffffc0204550 <etext>
ffffffffc020012c:	00004517          	auipc	a0,0x4
ffffffffc0200130:	48c50513          	addi	a0,a0,1164 # ffffffffc02045b8 <etext+0x68>
ffffffffc0200134:	f87ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200138:	0000a597          	auipc	a1,0xa
ffffffffc020013c:	f0858593          	addi	a1,a1,-248 # ffffffffc020a040 <ide>
ffffffffc0200140:	00004517          	auipc	a0,0x4
ffffffffc0200144:	49850513          	addi	a0,a0,1176 # ffffffffc02045d8 <etext+0x88>
ffffffffc0200148:	f73ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020014c:	00011597          	auipc	a1,0x11
ffffffffc0200150:	42c58593          	addi	a1,a1,1068 # ffffffffc0211578 <end>
ffffffffc0200154:	00004517          	auipc	a0,0x4
ffffffffc0200158:	4a450513          	addi	a0,a0,1188 # ffffffffc02045f8 <etext+0xa8>
ffffffffc020015c:	f5fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200160:	00012797          	auipc	a5,0x12
ffffffffc0200164:	81778793          	addi	a5,a5,-2025 # ffffffffc0211977 <end+0x3ff>
ffffffffc0200168:	00000717          	auipc	a4,0x0
ffffffffc020016c:	eca70713          	addi	a4,a4,-310 # ffffffffc0200032 <kern_init>
ffffffffc0200170:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200172:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200176:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200178:	3ff5f593          	andi	a1,a1,1023
ffffffffc020017c:	95be                	add	a1,a1,a5
ffffffffc020017e:	85a9                	srai	a1,a1,0xa
ffffffffc0200180:	00004517          	auipc	a0,0x4
ffffffffc0200184:	49850513          	addi	a0,a0,1176 # ffffffffc0204618 <etext+0xc8>
}
ffffffffc0200188:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020018a:	bf05                	j	ffffffffc02000ba <cprintf>

ffffffffc020018c <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020018c:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc020018e:	00004617          	auipc	a2,0x4
ffffffffc0200192:	4ba60613          	addi	a2,a2,1210 # ffffffffc0204648 <etext+0xf8>
ffffffffc0200196:	04e00593          	li	a1,78
ffffffffc020019a:	00004517          	auipc	a0,0x4
ffffffffc020019e:	4c650513          	addi	a0,a0,1222 # ffffffffc0204660 <etext+0x110>
void print_stackframe(void) {
ffffffffc02001a2:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001a4:	1bc000ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02001a8 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001a8:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001aa:	00004617          	auipc	a2,0x4
ffffffffc02001ae:	4ce60613          	addi	a2,a2,1230 # ffffffffc0204678 <etext+0x128>
ffffffffc02001b2:	00004597          	auipc	a1,0x4
ffffffffc02001b6:	4e658593          	addi	a1,a1,1254 # ffffffffc0204698 <etext+0x148>
ffffffffc02001ba:	00004517          	auipc	a0,0x4
ffffffffc02001be:	4e650513          	addi	a0,a0,1254 # ffffffffc02046a0 <etext+0x150>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001c2:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001c4:	ef7ff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02001c8:	00004617          	auipc	a2,0x4
ffffffffc02001cc:	4e860613          	addi	a2,a2,1256 # ffffffffc02046b0 <etext+0x160>
ffffffffc02001d0:	00004597          	auipc	a1,0x4
ffffffffc02001d4:	50858593          	addi	a1,a1,1288 # ffffffffc02046d8 <etext+0x188>
ffffffffc02001d8:	00004517          	auipc	a0,0x4
ffffffffc02001dc:	4c850513          	addi	a0,a0,1224 # ffffffffc02046a0 <etext+0x150>
ffffffffc02001e0:	edbff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02001e4:	00004617          	auipc	a2,0x4
ffffffffc02001e8:	50460613          	addi	a2,a2,1284 # ffffffffc02046e8 <etext+0x198>
ffffffffc02001ec:	00004597          	auipc	a1,0x4
ffffffffc02001f0:	51c58593          	addi	a1,a1,1308 # ffffffffc0204708 <etext+0x1b8>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	4ac50513          	addi	a0,a0,1196 # ffffffffc02046a0 <etext+0x150>
ffffffffc02001fc:	ebfff0ef          	jal	ffffffffc02000ba <cprintf>
    }
    return 0;
}
ffffffffc0200200:	60a2                	ld	ra,8(sp)
ffffffffc0200202:	4501                	li	a0,0
ffffffffc0200204:	0141                	addi	sp,sp,16
ffffffffc0200206:	8082                	ret

ffffffffc0200208 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200208:	1141                	addi	sp,sp,-16
ffffffffc020020a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020020c:	ef5ff0ef          	jal	ffffffffc0200100 <print_kerninfo>
    return 0;
}
ffffffffc0200210:	60a2                	ld	ra,8(sp)
ffffffffc0200212:	4501                	li	a0,0
ffffffffc0200214:	0141                	addi	sp,sp,16
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200218:	1141                	addi	sp,sp,-16
ffffffffc020021a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020021c:	f71ff0ef          	jal	ffffffffc020018c <print_stackframe>
    return 0;
}
ffffffffc0200220:	60a2                	ld	ra,8(sp)
ffffffffc0200222:	4501                	li	a0,0
ffffffffc0200224:	0141                	addi	sp,sp,16
ffffffffc0200226:	8082                	ret

ffffffffc0200228 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200228:	7115                	addi	sp,sp,-224
ffffffffc020022a:	f15a                	sd	s6,160(sp)
ffffffffc020022c:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020022e:	00004517          	auipc	a0,0x4
ffffffffc0200232:	4ea50513          	addi	a0,a0,1258 # ffffffffc0204718 <etext+0x1c8>
kmonitor(struct trapframe *tf) {
ffffffffc0200236:	ed86                	sd	ra,216(sp)
ffffffffc0200238:	e9a2                	sd	s0,208(sp)
ffffffffc020023a:	e5a6                	sd	s1,200(sp)
ffffffffc020023c:	e1ca                	sd	s2,192(sp)
ffffffffc020023e:	fd4e                	sd	s3,184(sp)
ffffffffc0200240:	f952                	sd	s4,176(sp)
ffffffffc0200242:	f556                	sd	s5,168(sp)
ffffffffc0200244:	ed5e                	sd	s7,152(sp)
ffffffffc0200246:	e962                	sd	s8,144(sp)
ffffffffc0200248:	e566                	sd	s9,136(sp)
ffffffffc020024a:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020024c:	e6fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200250:	00004517          	auipc	a0,0x4
ffffffffc0200254:	4f050513          	addi	a0,a0,1264 # ffffffffc0204740 <etext+0x1f0>
ffffffffc0200258:	e63ff0ef          	jal	ffffffffc02000ba <cprintf>
    if (tf != NULL) {
ffffffffc020025c:	000b0563          	beqz	s6,ffffffffc0200266 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200260:	855a                	mv	a0,s6
ffffffffc0200262:	4da000ef          	jal	ffffffffc020073c <print_trapframe>
ffffffffc0200266:	00006c17          	auipc	s8,0x6
ffffffffc020026a:	ebac0c13          	addi	s8,s8,-326 # ffffffffc0206120 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc020026e:	00006917          	auipc	s2,0x6
ffffffffc0200272:	85a90913          	addi	s2,s2,-1958 # ffffffffc0205ac8 <etext+0x1578>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200276:	00004497          	auipc	s1,0x4
ffffffffc020027a:	4f248493          	addi	s1,s1,1266 # ffffffffc0204768 <etext+0x218>
        if (argc == MAXARGS - 1) {
ffffffffc020027e:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200280:	00004a97          	auipc	s5,0x4
ffffffffc0200284:	4f0a8a93          	addi	s5,s5,1264 # ffffffffc0204770 <etext+0x220>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200288:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020028a:	00004b97          	auipc	s7,0x4
ffffffffc020028e:	506b8b93          	addi	s7,s7,1286 # ffffffffc0204790 <etext+0x240>
        if ((buf = readline("")) != NULL) {
ffffffffc0200292:	854a                	mv	a0,s2
ffffffffc0200294:	148040ef          	jal	ffffffffc02043dc <readline>
ffffffffc0200298:	842a                	mv	s0,a0
ffffffffc020029a:	dd65                	beqz	a0,ffffffffc0200292 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020029c:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002a0:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002a2:	e59d                	bnez	a1,ffffffffc02002d0 <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc02002a4:	fe0c87e3          	beqz	s9,ffffffffc0200292 <kmonitor+0x6a>
ffffffffc02002a8:	00006d17          	auipc	s10,0x6
ffffffffc02002ac:	e78d0d13          	addi	s10,s10,-392 # ffffffffc0206120 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002b0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002b2:	6582                	ld	a1,0(sp)
ffffffffc02002b4:	000d3503          	ld	a0,0(s10)
ffffffffc02002b8:	220040ef          	jal	ffffffffc02044d8 <strcmp>
ffffffffc02002bc:	c53d                	beqz	a0,ffffffffc020032a <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002be:	2405                	addiw	s0,s0,1
ffffffffc02002c0:	0d61                	addi	s10,s10,24
ffffffffc02002c2:	ff4418e3          	bne	s0,s4,ffffffffc02002b2 <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002c6:	6582                	ld	a1,0(sp)
ffffffffc02002c8:	855e                	mv	a0,s7
ffffffffc02002ca:	df1ff0ef          	jal	ffffffffc02000ba <cprintf>
    return 0;
ffffffffc02002ce:	b7d1                	j	ffffffffc0200292 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d0:	8526                	mv	a0,s1
ffffffffc02002d2:	23e040ef          	jal	ffffffffc0204510 <strchr>
ffffffffc02002d6:	c901                	beqz	a0,ffffffffc02002e6 <kmonitor+0xbe>
ffffffffc02002d8:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02002dc:	00040023          	sb	zero,0(s0)
ffffffffc02002e0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e2:	d1e9                	beqz	a1,ffffffffc02002a4 <kmonitor+0x7c>
ffffffffc02002e4:	b7f5                	j	ffffffffc02002d0 <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc02002e6:	00044783          	lbu	a5,0(s0)
ffffffffc02002ea:	dfcd                	beqz	a5,ffffffffc02002a4 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02002ec:	033c8a63          	beq	s9,s3,ffffffffc0200320 <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc02002f0:	003c9793          	slli	a5,s9,0x3
ffffffffc02002f4:	08078793          	addi	a5,a5,128
ffffffffc02002f8:	978a                	add	a5,a5,sp
ffffffffc02002fa:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02002fe:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200302:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200304:	e591                	bnez	a1,ffffffffc0200310 <kmonitor+0xe8>
ffffffffc0200306:	bf79                	j	ffffffffc02002a4 <kmonitor+0x7c>
ffffffffc0200308:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020030c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020030e:	d9d9                	beqz	a1,ffffffffc02002a4 <kmonitor+0x7c>
ffffffffc0200310:	8526                	mv	a0,s1
ffffffffc0200312:	1fe040ef          	jal	ffffffffc0204510 <strchr>
ffffffffc0200316:	d96d                	beqz	a0,ffffffffc0200308 <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200318:	00044583          	lbu	a1,0(s0)
ffffffffc020031c:	d5c1                	beqz	a1,ffffffffc02002a4 <kmonitor+0x7c>
ffffffffc020031e:	bf4d                	j	ffffffffc02002d0 <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200320:	45c1                	li	a1,16
ffffffffc0200322:	8556                	mv	a0,s5
ffffffffc0200324:	d97ff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc0200328:	b7e1                	j	ffffffffc02002f0 <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020032a:	00141793          	slli	a5,s0,0x1
ffffffffc020032e:	97a2                	add	a5,a5,s0
ffffffffc0200330:	078e                	slli	a5,a5,0x3
ffffffffc0200332:	97e2                	add	a5,a5,s8
ffffffffc0200334:	6b9c                	ld	a5,16(a5)
ffffffffc0200336:	865a                	mv	a2,s6
ffffffffc0200338:	002c                	addi	a1,sp,8
ffffffffc020033a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020033e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200340:	f40559e3          	bgez	a0,ffffffffc0200292 <kmonitor+0x6a>
}
ffffffffc0200344:	60ee                	ld	ra,216(sp)
ffffffffc0200346:	644e                	ld	s0,208(sp)
ffffffffc0200348:	64ae                	ld	s1,200(sp)
ffffffffc020034a:	690e                	ld	s2,192(sp)
ffffffffc020034c:	79ea                	ld	s3,184(sp)
ffffffffc020034e:	7a4a                	ld	s4,176(sp)
ffffffffc0200350:	7aaa                	ld	s5,168(sp)
ffffffffc0200352:	7b0a                	ld	s6,160(sp)
ffffffffc0200354:	6bea                	ld	s7,152(sp)
ffffffffc0200356:	6c4a                	ld	s8,144(sp)
ffffffffc0200358:	6caa                	ld	s9,136(sp)
ffffffffc020035a:	6d0a                	ld	s10,128(sp)
ffffffffc020035c:	612d                	addi	sp,sp,224
ffffffffc020035e:	8082                	ret

ffffffffc0200360 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200360:	00011317          	auipc	t1,0x11
ffffffffc0200364:	19830313          	addi	t1,t1,408 # ffffffffc02114f8 <is_panic>
ffffffffc0200368:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020036c:	715d                	addi	sp,sp,-80
ffffffffc020036e:	ec06                	sd	ra,24(sp)
ffffffffc0200370:	f436                	sd	a3,40(sp)
ffffffffc0200372:	f83a                	sd	a4,48(sp)
ffffffffc0200374:	fc3e                	sd	a5,56(sp)
ffffffffc0200376:	e0c2                	sd	a6,64(sp)
ffffffffc0200378:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020037a:	020e1c63          	bnez	t3,ffffffffc02003b2 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020037e:	4785                	li	a5,1
ffffffffc0200380:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200384:	e822                	sd	s0,16(sp)
ffffffffc0200386:	103c                	addi	a5,sp,40
ffffffffc0200388:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020038a:	862e                	mv	a2,a1
ffffffffc020038c:	85aa                	mv	a1,a0
ffffffffc020038e:	00004517          	auipc	a0,0x4
ffffffffc0200392:	41a50513          	addi	a0,a0,1050 # ffffffffc02047a8 <etext+0x258>
    va_start(ap, fmt);
ffffffffc0200396:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200398:	d23ff0ef          	jal	ffffffffc02000ba <cprintf>
    vcprintf(fmt, ap);
ffffffffc020039c:	65a2                	ld	a1,8(sp)
ffffffffc020039e:	8522                	mv	a0,s0
ffffffffc02003a0:	cfbff0ef          	jal	ffffffffc020009a <vcprintf>
    cprintf("\n");
ffffffffc02003a4:	00005517          	auipc	a0,0x5
ffffffffc02003a8:	27450513          	addi	a0,a0,628 # ffffffffc0205618 <etext+0x10c8>
ffffffffc02003ac:	d0fff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02003b0:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003b2:	12a000ef          	jal	ffffffffc02004dc <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003b6:	4501                	li	a0,0
ffffffffc02003b8:	e71ff0ef          	jal	ffffffffc0200228 <kmonitor>
    while (1) {
ffffffffc02003bc:	bfed                	j	ffffffffc02003b6 <__panic+0x56>

ffffffffc02003be <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02003be:	67e1                	lui	a5,0x18
ffffffffc02003c0:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02003c4:	00011717          	auipc	a4,0x11
ffffffffc02003c8:	12f73e23          	sd	a5,316(a4) # ffffffffc0211500 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02003cc:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02003d0:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02003d2:	953e                	add	a0,a0,a5
ffffffffc02003d4:	4601                	li	a2,0
ffffffffc02003d6:	4881                	li	a7,0
ffffffffc02003d8:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02003dc:	02000793          	li	a5,32
ffffffffc02003e0:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02003e4:	00004517          	auipc	a0,0x4
ffffffffc02003e8:	3e450513          	addi	a0,a0,996 # ffffffffc02047c8 <etext+0x278>
    ticks = 0;
ffffffffc02003ec:	00011797          	auipc	a5,0x11
ffffffffc02003f0:	1007be23          	sd	zero,284(a5) # ffffffffc0211508 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02003f4:	b1d9                	j	ffffffffc02000ba <cprintf>

ffffffffc02003f6 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02003f6:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02003fa:	00011797          	auipc	a5,0x11
ffffffffc02003fe:	1067b783          	ld	a5,262(a5) # ffffffffc0211500 <timebase>
ffffffffc0200402:	953e                	add	a0,a0,a5
ffffffffc0200404:	4581                	li	a1,0
ffffffffc0200406:	4601                	li	a2,0
ffffffffc0200408:	4881                	li	a7,0
ffffffffc020040a:	00000073          	ecall
ffffffffc020040e:	8082                	ret

ffffffffc0200410 <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200410:	100027f3          	csrr	a5,sstatus
ffffffffc0200414:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200416:	0ff57513          	zext.b	a0,a0
ffffffffc020041a:	e799                	bnez	a5,ffffffffc0200428 <cons_putc+0x18>
ffffffffc020041c:	4581                	li	a1,0
ffffffffc020041e:	4601                	li	a2,0
ffffffffc0200420:	4885                	li	a7,1
ffffffffc0200422:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200426:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200428:	1101                	addi	sp,sp,-32
ffffffffc020042a:	ec06                	sd	ra,24(sp)
ffffffffc020042c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020042e:	0ae000ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0200432:	6522                	ld	a0,8(sp)
ffffffffc0200434:	4581                	li	a1,0
ffffffffc0200436:	4601                	li	a2,0
ffffffffc0200438:	4885                	li	a7,1
ffffffffc020043a:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc020043e:	60e2                	ld	ra,24(sp)
ffffffffc0200440:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200442:	a851                	j	ffffffffc02004d6 <intr_enable>

ffffffffc0200444 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200444:	100027f3          	csrr	a5,sstatus
ffffffffc0200448:	8b89                	andi	a5,a5,2
ffffffffc020044a:	eb89                	bnez	a5,ffffffffc020045c <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020044c:	4501                	li	a0,0
ffffffffc020044e:	4581                	li	a1,0
ffffffffc0200450:	4601                	li	a2,0
ffffffffc0200452:	4889                	li	a7,2
ffffffffc0200454:	00000073          	ecall
ffffffffc0200458:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020045a:	8082                	ret
int cons_getc(void) {
ffffffffc020045c:	1101                	addi	sp,sp,-32
ffffffffc020045e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200460:	07c000ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0200464:	4501                	li	a0,0
ffffffffc0200466:	4581                	li	a1,0
ffffffffc0200468:	4601                	li	a2,0
ffffffffc020046a:	4889                	li	a7,2
ffffffffc020046c:	00000073          	ecall
ffffffffc0200470:	2501                	sext.w	a0,a0
ffffffffc0200472:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200474:	062000ef          	jal	ffffffffc02004d6 <intr_enable>
}
ffffffffc0200478:	60e2                	ld	ra,24(sp)
ffffffffc020047a:	6522                	ld	a0,8(sp)
ffffffffc020047c:	6105                	addi	sp,sp,32
ffffffffc020047e:	8082                	ret

ffffffffc0200480 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc0200480:	8082                	ret

ffffffffc0200482 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc0200482:	00253513          	sltiu	a0,a0,2
ffffffffc0200486:	8082                	ret

ffffffffc0200488 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc0200488:	03800513          	li	a0,56
ffffffffc020048c:	8082                	ret

ffffffffc020048e <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020048e:	0000a797          	auipc	a5,0xa
ffffffffc0200492:	bb278793          	addi	a5,a5,-1102 # ffffffffc020a040 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc0200496:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc020049a:	1141                	addi	sp,sp,-16
ffffffffc020049c:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020049e:	95be                	add	a1,a1,a5
ffffffffc02004a0:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02004a4:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004a6:	092040ef          	jal	ffffffffc0204538 <memcpy>
    return 0;
}
ffffffffc02004aa:	60a2                	ld	ra,8(sp)
ffffffffc02004ac:	4501                	li	a0,0
ffffffffc02004ae:	0141                	addi	sp,sp,16
ffffffffc02004b0:	8082                	ret

ffffffffc02004b2 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc02004b2:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004b6:	0000a517          	auipc	a0,0xa
ffffffffc02004ba:	b8a50513          	addi	a0,a0,-1142 # ffffffffc020a040 <ide>
                   size_t nsecs) {
ffffffffc02004be:	1141                	addi	sp,sp,-16
ffffffffc02004c0:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004c2:	953e                	add	a0,a0,a5
ffffffffc02004c4:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc02004c8:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004ca:	06e040ef          	jal	ffffffffc0204538 <memcpy>
    return 0;
}
ffffffffc02004ce:	60a2                	ld	ra,8(sp)
ffffffffc02004d0:	4501                	li	a0,0
ffffffffc02004d2:	0141                	addi	sp,sp,16
ffffffffc02004d4:	8082                	ret

ffffffffc02004d6 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004d6:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004da:	8082                	ret

ffffffffc02004dc <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004dc:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004e0:	8082                	ret

ffffffffc02004e2 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004e2:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004e6:	1141                	addi	sp,sp,-16
ffffffffc02004e8:	e022                	sd	s0,0(sp)
ffffffffc02004ea:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004ec:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02004f0:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004f4:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02004f6:	04b00613          	li	a2,75
ffffffffc02004fa:	e399                	bnez	a5,ffffffffc0200500 <pgfault_handler+0x1e>
ffffffffc02004fc:	05500613          	li	a2,85
ffffffffc0200500:	11843703          	ld	a4,280(s0)
ffffffffc0200504:	47bd                	li	a5,15
ffffffffc0200506:	05200693          	li	a3,82
ffffffffc020050a:	00f71463          	bne	a4,a5,ffffffffc0200512 <pgfault_handler+0x30>
ffffffffc020050e:	05700693          	li	a3,87
ffffffffc0200512:	00004517          	auipc	a0,0x4
ffffffffc0200516:	2d650513          	addi	a0,a0,726 # ffffffffc02047e8 <etext+0x298>
ffffffffc020051a:	ba1ff0ef          	jal	ffffffffc02000ba <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc020051e:	00011517          	auipc	a0,0x11
ffffffffc0200522:	05253503          	ld	a0,82(a0) # ffffffffc0211570 <check_mm_struct>
ffffffffc0200526:	c911                	beqz	a0,ffffffffc020053a <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200528:	11043603          	ld	a2,272(s0)
ffffffffc020052c:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200530:	6402                	ld	s0,0(sp)
ffffffffc0200532:	60a2                	ld	ra,8(sp)
ffffffffc0200534:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200536:	03d0306f          	j	ffffffffc0203d72 <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc020053a:	00004617          	auipc	a2,0x4
ffffffffc020053e:	2ce60613          	addi	a2,a2,718 # ffffffffc0204808 <etext+0x2b8>
ffffffffc0200542:	07800593          	li	a1,120
ffffffffc0200546:	00004517          	auipc	a0,0x4
ffffffffc020054a:	2da50513          	addi	a0,a0,730 # ffffffffc0204820 <etext+0x2d0>
ffffffffc020054e:	e13ff0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0200552 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200552:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200556:	00000797          	auipc	a5,0x0
ffffffffc020055a:	4ca78793          	addi	a5,a5,1226 # ffffffffc0200a20 <__alltraps>
ffffffffc020055e:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc0200562:	100167f3          	csrrsi	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200566:	000407b7          	lui	a5,0x40
ffffffffc020056a:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020056e:	8082                	ret

ffffffffc0200570 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200570:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200572:	1141                	addi	sp,sp,-16
ffffffffc0200574:	e022                	sd	s0,0(sp)
ffffffffc0200576:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200578:	00004517          	auipc	a0,0x4
ffffffffc020057c:	2c050513          	addi	a0,a0,704 # ffffffffc0204838 <etext+0x2e8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200580:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200582:	b39ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200586:	640c                	ld	a1,8(s0)
ffffffffc0200588:	00004517          	auipc	a0,0x4
ffffffffc020058c:	2c850513          	addi	a0,a0,712 # ffffffffc0204850 <etext+0x300>
ffffffffc0200590:	b2bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200594:	680c                	ld	a1,16(s0)
ffffffffc0200596:	00004517          	auipc	a0,0x4
ffffffffc020059a:	2d250513          	addi	a0,a0,722 # ffffffffc0204868 <etext+0x318>
ffffffffc020059e:	b1dff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005a2:	6c0c                	ld	a1,24(s0)
ffffffffc02005a4:	00004517          	auipc	a0,0x4
ffffffffc02005a8:	2dc50513          	addi	a0,a0,732 # ffffffffc0204880 <etext+0x330>
ffffffffc02005ac:	b0fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005b0:	700c                	ld	a1,32(s0)
ffffffffc02005b2:	00004517          	auipc	a0,0x4
ffffffffc02005b6:	2e650513          	addi	a0,a0,742 # ffffffffc0204898 <etext+0x348>
ffffffffc02005ba:	b01ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005be:	740c                	ld	a1,40(s0)
ffffffffc02005c0:	00004517          	auipc	a0,0x4
ffffffffc02005c4:	2f050513          	addi	a0,a0,752 # ffffffffc02048b0 <etext+0x360>
ffffffffc02005c8:	af3ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005cc:	780c                	ld	a1,48(s0)
ffffffffc02005ce:	00004517          	auipc	a0,0x4
ffffffffc02005d2:	2fa50513          	addi	a0,a0,762 # ffffffffc02048c8 <etext+0x378>
ffffffffc02005d6:	ae5ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005da:	7c0c                	ld	a1,56(s0)
ffffffffc02005dc:	00004517          	auipc	a0,0x4
ffffffffc02005e0:	30450513          	addi	a0,a0,772 # ffffffffc02048e0 <etext+0x390>
ffffffffc02005e4:	ad7ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02005e8:	602c                	ld	a1,64(s0)
ffffffffc02005ea:	00004517          	auipc	a0,0x4
ffffffffc02005ee:	30e50513          	addi	a0,a0,782 # ffffffffc02048f8 <etext+0x3a8>
ffffffffc02005f2:	ac9ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02005f6:	642c                	ld	a1,72(s0)
ffffffffc02005f8:	00004517          	auipc	a0,0x4
ffffffffc02005fc:	31850513          	addi	a0,a0,792 # ffffffffc0204910 <etext+0x3c0>
ffffffffc0200600:	abbff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200604:	682c                	ld	a1,80(s0)
ffffffffc0200606:	00004517          	auipc	a0,0x4
ffffffffc020060a:	32250513          	addi	a0,a0,802 # ffffffffc0204928 <etext+0x3d8>
ffffffffc020060e:	aadff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200612:	6c2c                	ld	a1,88(s0)
ffffffffc0200614:	00004517          	auipc	a0,0x4
ffffffffc0200618:	32c50513          	addi	a0,a0,812 # ffffffffc0204940 <etext+0x3f0>
ffffffffc020061c:	a9fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200620:	702c                	ld	a1,96(s0)
ffffffffc0200622:	00004517          	auipc	a0,0x4
ffffffffc0200626:	33650513          	addi	a0,a0,822 # ffffffffc0204958 <etext+0x408>
ffffffffc020062a:	a91ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020062e:	742c                	ld	a1,104(s0)
ffffffffc0200630:	00004517          	auipc	a0,0x4
ffffffffc0200634:	34050513          	addi	a0,a0,832 # ffffffffc0204970 <etext+0x420>
ffffffffc0200638:	a83ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020063c:	782c                	ld	a1,112(s0)
ffffffffc020063e:	00004517          	auipc	a0,0x4
ffffffffc0200642:	34a50513          	addi	a0,a0,842 # ffffffffc0204988 <etext+0x438>
ffffffffc0200646:	a75ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020064a:	7c2c                	ld	a1,120(s0)
ffffffffc020064c:	00004517          	auipc	a0,0x4
ffffffffc0200650:	35450513          	addi	a0,a0,852 # ffffffffc02049a0 <etext+0x450>
ffffffffc0200654:	a67ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200658:	604c                	ld	a1,128(s0)
ffffffffc020065a:	00004517          	auipc	a0,0x4
ffffffffc020065e:	35e50513          	addi	a0,a0,862 # ffffffffc02049b8 <etext+0x468>
ffffffffc0200662:	a59ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200666:	644c                	ld	a1,136(s0)
ffffffffc0200668:	00004517          	auipc	a0,0x4
ffffffffc020066c:	36850513          	addi	a0,a0,872 # ffffffffc02049d0 <etext+0x480>
ffffffffc0200670:	a4bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200674:	684c                	ld	a1,144(s0)
ffffffffc0200676:	00004517          	auipc	a0,0x4
ffffffffc020067a:	37250513          	addi	a0,a0,882 # ffffffffc02049e8 <etext+0x498>
ffffffffc020067e:	a3dff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200682:	6c4c                	ld	a1,152(s0)
ffffffffc0200684:	00004517          	auipc	a0,0x4
ffffffffc0200688:	37c50513          	addi	a0,a0,892 # ffffffffc0204a00 <etext+0x4b0>
ffffffffc020068c:	a2fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200690:	704c                	ld	a1,160(s0)
ffffffffc0200692:	00004517          	auipc	a0,0x4
ffffffffc0200696:	38650513          	addi	a0,a0,902 # ffffffffc0204a18 <etext+0x4c8>
ffffffffc020069a:	a21ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020069e:	744c                	ld	a1,168(s0)
ffffffffc02006a0:	00004517          	auipc	a0,0x4
ffffffffc02006a4:	39050513          	addi	a0,a0,912 # ffffffffc0204a30 <etext+0x4e0>
ffffffffc02006a8:	a13ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006ac:	784c                	ld	a1,176(s0)
ffffffffc02006ae:	00004517          	auipc	a0,0x4
ffffffffc02006b2:	39a50513          	addi	a0,a0,922 # ffffffffc0204a48 <etext+0x4f8>
ffffffffc02006b6:	a05ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006ba:	7c4c                	ld	a1,184(s0)
ffffffffc02006bc:	00004517          	auipc	a0,0x4
ffffffffc02006c0:	3a450513          	addi	a0,a0,932 # ffffffffc0204a60 <etext+0x510>
ffffffffc02006c4:	9f7ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006c8:	606c                	ld	a1,192(s0)
ffffffffc02006ca:	00004517          	auipc	a0,0x4
ffffffffc02006ce:	3ae50513          	addi	a0,a0,942 # ffffffffc0204a78 <etext+0x528>
ffffffffc02006d2:	9e9ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006d6:	646c                	ld	a1,200(s0)
ffffffffc02006d8:	00004517          	auipc	a0,0x4
ffffffffc02006dc:	3b850513          	addi	a0,a0,952 # ffffffffc0204a90 <etext+0x540>
ffffffffc02006e0:	9dbff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02006e4:	686c                	ld	a1,208(s0)
ffffffffc02006e6:	00004517          	auipc	a0,0x4
ffffffffc02006ea:	3c250513          	addi	a0,a0,962 # ffffffffc0204aa8 <etext+0x558>
ffffffffc02006ee:	9cdff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02006f2:	6c6c                	ld	a1,216(s0)
ffffffffc02006f4:	00004517          	auipc	a0,0x4
ffffffffc02006f8:	3cc50513          	addi	a0,a0,972 # ffffffffc0204ac0 <etext+0x570>
ffffffffc02006fc:	9bfff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200700:	706c                	ld	a1,224(s0)
ffffffffc0200702:	00004517          	auipc	a0,0x4
ffffffffc0200706:	3d650513          	addi	a0,a0,982 # ffffffffc0204ad8 <etext+0x588>
ffffffffc020070a:	9b1ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020070e:	746c                	ld	a1,232(s0)
ffffffffc0200710:	00004517          	auipc	a0,0x4
ffffffffc0200714:	3e050513          	addi	a0,a0,992 # ffffffffc0204af0 <etext+0x5a0>
ffffffffc0200718:	9a3ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020071c:	786c                	ld	a1,240(s0)
ffffffffc020071e:	00004517          	auipc	a0,0x4
ffffffffc0200722:	3ea50513          	addi	a0,a0,1002 # ffffffffc0204b08 <etext+0x5b8>
ffffffffc0200726:	995ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020072a:	7c6c                	ld	a1,248(s0)
}
ffffffffc020072c:	6402                	ld	s0,0(sp)
ffffffffc020072e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200730:	00004517          	auipc	a0,0x4
ffffffffc0200734:	3f050513          	addi	a0,a0,1008 # ffffffffc0204b20 <etext+0x5d0>
}
ffffffffc0200738:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020073a:	b241                	j	ffffffffc02000ba <cprintf>

ffffffffc020073c <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020073c:	1141                	addi	sp,sp,-16
ffffffffc020073e:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200740:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200742:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200744:	00004517          	auipc	a0,0x4
ffffffffc0200748:	3f450513          	addi	a0,a0,1012 # ffffffffc0204b38 <etext+0x5e8>
void print_trapframe(struct trapframe *tf) {
ffffffffc020074c:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020074e:	96dff0ef          	jal	ffffffffc02000ba <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200752:	8522                	mv	a0,s0
ffffffffc0200754:	e1dff0ef          	jal	ffffffffc0200570 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200758:	10043583          	ld	a1,256(s0)
ffffffffc020075c:	00004517          	auipc	a0,0x4
ffffffffc0200760:	3f450513          	addi	a0,a0,1012 # ffffffffc0204b50 <etext+0x600>
ffffffffc0200764:	957ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200768:	10843583          	ld	a1,264(s0)
ffffffffc020076c:	00004517          	auipc	a0,0x4
ffffffffc0200770:	3fc50513          	addi	a0,a0,1020 # ffffffffc0204b68 <etext+0x618>
ffffffffc0200774:	947ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200778:	11043583          	ld	a1,272(s0)
ffffffffc020077c:	00004517          	auipc	a0,0x4
ffffffffc0200780:	40450513          	addi	a0,a0,1028 # ffffffffc0204b80 <etext+0x630>
ffffffffc0200784:	937ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200788:	11843583          	ld	a1,280(s0)
}
ffffffffc020078c:	6402                	ld	s0,0(sp)
ffffffffc020078e:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200790:	00004517          	auipc	a0,0x4
ffffffffc0200794:	40850513          	addi	a0,a0,1032 # ffffffffc0204b98 <etext+0x648>
}
ffffffffc0200798:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020079a:	921ff06f          	j	ffffffffc02000ba <cprintf>

ffffffffc020079e <interrupt_handler>:
static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc020079e:	11853783          	ld	a5,280(a0)
ffffffffc02007a2:	472d                	li	a4,11
ffffffffc02007a4:	0786                	slli	a5,a5,0x1
ffffffffc02007a6:	8385                	srli	a5,a5,0x1
ffffffffc02007a8:	08f76963          	bltu	a4,a5,ffffffffc020083a <interrupt_handler+0x9c>
ffffffffc02007ac:	00006717          	auipc	a4,0x6
ffffffffc02007b0:	9bc70713          	addi	a4,a4,-1604 # ffffffffc0206168 <commands+0x48>
ffffffffc02007b4:	078a                	slli	a5,a5,0x2
ffffffffc02007b6:	97ba                	add	a5,a5,a4
ffffffffc02007b8:	439c                	lw	a5,0(a5)
ffffffffc02007ba:	97ba                	add	a5,a5,a4
ffffffffc02007bc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02007be:	00004517          	auipc	a0,0x4
ffffffffc02007c2:	45250513          	addi	a0,a0,1106 # ffffffffc0204c10 <etext+0x6c0>
ffffffffc02007c6:	8f5ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007ca:	00004517          	auipc	a0,0x4
ffffffffc02007ce:	42650513          	addi	a0,a0,1062 # ffffffffc0204bf0 <etext+0x6a0>
ffffffffc02007d2:	8e9ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007d6:	00004517          	auipc	a0,0x4
ffffffffc02007da:	3da50513          	addi	a0,a0,986 # ffffffffc0204bb0 <etext+0x660>
ffffffffc02007de:	8ddff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02007e2:	00004517          	auipc	a0,0x4
ffffffffc02007e6:	3ee50513          	addi	a0,a0,1006 # ffffffffc0204bd0 <etext+0x680>
ffffffffc02007ea:	8d1ff06f          	j	ffffffffc02000ba <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02007ee:	1141                	addi	sp,sp,-16
ffffffffc02007f0:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02007f2:	c05ff0ef          	jal	ffffffffc02003f6 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02007f6:	00011697          	auipc	a3,0x11
ffffffffc02007fa:	d1268693          	addi	a3,a3,-750 # ffffffffc0211508 <ticks>
ffffffffc02007fe:	629c                	ld	a5,0(a3)
ffffffffc0200800:	06400713          	li	a4,100
ffffffffc0200804:	0785                	addi	a5,a5,1 # 40001 <kern_entry-0xffffffffc01bffff>
ffffffffc0200806:	02e7f733          	remu	a4,a5,a4
ffffffffc020080a:	e29c                	sd	a5,0(a3)
ffffffffc020080c:	cb05                	beqz	a4,ffffffffc020083c <interrupt_handler+0x9e>
                print_ticks();
                num++;          //new
            }
            if(num == 10){      //new
ffffffffc020080e:	00011717          	auipc	a4,0x11
ffffffffc0200812:	d0272703          	lw	a4,-766(a4) # ffffffffc0211510 <num>
ffffffffc0200816:	47a9                	li	a5,10
ffffffffc0200818:	00f71863          	bne	a4,a5,ffffffffc0200828 <interrupt_handler+0x8a>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020081c:	4501                	li	a0,0
ffffffffc020081e:	4581                	li	a1,0
ffffffffc0200820:	4601                	li	a2,0
ffffffffc0200822:	48a1                	li	a7,8
ffffffffc0200824:	00000073          	ecall
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200828:	60a2                	ld	ra,8(sp)
ffffffffc020082a:	0141                	addi	sp,sp,16
ffffffffc020082c:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc020082e:	00004517          	auipc	a0,0x4
ffffffffc0200832:	41250513          	addi	a0,a0,1042 # ffffffffc0204c40 <etext+0x6f0>
ffffffffc0200836:	885ff06f          	j	ffffffffc02000ba <cprintf>
            print_trapframe(tf);
ffffffffc020083a:	b709                	j	ffffffffc020073c <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020083c:	06400593          	li	a1,100
ffffffffc0200840:	00004517          	auipc	a0,0x4
ffffffffc0200844:	3f050513          	addi	a0,a0,1008 # ffffffffc0204c30 <etext+0x6e0>
ffffffffc0200848:	873ff0ef          	jal	ffffffffc02000ba <cprintf>
                num++;          //new
ffffffffc020084c:	00011697          	auipc	a3,0x11
ffffffffc0200850:	cc468693          	addi	a3,a3,-828 # ffffffffc0211510 <num>
ffffffffc0200854:	429c                	lw	a5,0(a3)
ffffffffc0200856:	0017871b          	addiw	a4,a5,1
ffffffffc020085a:	c298                	sw	a4,0(a3)
ffffffffc020085c:	bf6d                	j	ffffffffc0200816 <interrupt_handler+0x78>

ffffffffc020085e <exception_handler>:


void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc020085e:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200862:	1101                	addi	sp,sp,-32
ffffffffc0200864:	e822                	sd	s0,16(sp)
ffffffffc0200866:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200868:	473d                	li	a4,15
void exception_handler(struct trapframe *tf) {
ffffffffc020086a:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc020086c:	16f76b63          	bltu	a4,a5,ffffffffc02009e2 <exception_handler+0x184>
ffffffffc0200870:	00006717          	auipc	a4,0x6
ffffffffc0200874:	92870713          	addi	a4,a4,-1752 # ffffffffc0206198 <commands+0x78>
ffffffffc0200878:	078a                	slli	a5,a5,0x2
ffffffffc020087a:	97ba                	add	a5,a5,a4
ffffffffc020087c:	439c                	lw	a5,0(a5)
ffffffffc020087e:	97ba                	add	a5,a5,a4
ffffffffc0200880:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200882:	00004517          	auipc	a0,0x4
ffffffffc0200886:	57e50513          	addi	a0,a0,1406 # ffffffffc0204e00 <etext+0x8b0>
ffffffffc020088a:	e426                	sd	s1,8(sp)
ffffffffc020088c:	82fff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200890:	8522                	mv	a0,s0
ffffffffc0200892:	c51ff0ef          	jal	ffffffffc02004e2 <pgfault_handler>
ffffffffc0200896:	84aa                	mv	s1,a0
ffffffffc0200898:	14051a63          	bnez	a0,ffffffffc02009ec <exception_handler+0x18e>
ffffffffc020089c:	64a2                	ld	s1,8(sp)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020089e:	60e2                	ld	ra,24(sp)
ffffffffc02008a0:	6442                	ld	s0,16(sp)
ffffffffc02008a2:	6105                	addi	sp,sp,32
ffffffffc02008a4:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc02008a6:	00004517          	auipc	a0,0x4
ffffffffc02008aa:	3ba50513          	addi	a0,a0,954 # ffffffffc0204c60 <etext+0x710>
}
ffffffffc02008ae:	6442                	ld	s0,16(sp)
ffffffffc02008b0:	60e2                	ld	ra,24(sp)
ffffffffc02008b2:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc02008b4:	807ff06f          	j	ffffffffc02000ba <cprintf>
ffffffffc02008b8:	00004517          	auipc	a0,0x4
ffffffffc02008bc:	3c850513          	addi	a0,a0,968 # ffffffffc0204c80 <etext+0x730>
ffffffffc02008c0:	b7fd                	j	ffffffffc02008ae <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02008c2:	00004517          	auipc	a0,0x4
ffffffffc02008c6:	3de50513          	addi	a0,a0,990 # ffffffffc0204ca0 <etext+0x750>
ffffffffc02008ca:	ff0ff0ef          	jal	ffffffffc02000ba <cprintf>
            tf->epc += 4;//new
ffffffffc02008ce:	10843783          	ld	a5,264(s0)
ffffffffc02008d2:	0791                	addi	a5,a5,4
ffffffffc02008d4:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc02008d8:	b7d9                	j	ffffffffc020089e <exception_handler+0x40>
            cprintf("Breakpoint\n");
ffffffffc02008da:	00004517          	auipc	a0,0x4
ffffffffc02008de:	3de50513          	addi	a0,a0,990 # ffffffffc0204cb8 <etext+0x768>
ffffffffc02008e2:	fd8ff0ef          	jal	ffffffffc02000ba <cprintf>
            tf->epc += 4;//new
ffffffffc02008e6:	10843783          	ld	a5,264(s0)
ffffffffc02008ea:	0791                	addi	a5,a5,4
ffffffffc02008ec:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc02008f0:	b77d                	j	ffffffffc020089e <exception_handler+0x40>
            cprintf("Load address misaligned\n");
ffffffffc02008f2:	00004517          	auipc	a0,0x4
ffffffffc02008f6:	3d650513          	addi	a0,a0,982 # ffffffffc0204cc8 <etext+0x778>
ffffffffc02008fa:	bf55                	j	ffffffffc02008ae <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008fc:	00004517          	auipc	a0,0x4
ffffffffc0200900:	3ec50513          	addi	a0,a0,1004 # ffffffffc0204ce8 <etext+0x798>
ffffffffc0200904:	e426                	sd	s1,8(sp)
ffffffffc0200906:	fb4ff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020090a:	8522                	mv	a0,s0
ffffffffc020090c:	bd7ff0ef          	jal	ffffffffc02004e2 <pgfault_handler>
ffffffffc0200910:	84aa                	mv	s1,a0
ffffffffc0200912:	d549                	beqz	a0,ffffffffc020089c <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200914:	8522                	mv	a0,s0
ffffffffc0200916:	e27ff0ef          	jal	ffffffffc020073c <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc020091a:	86a6                	mv	a3,s1
ffffffffc020091c:	00004617          	auipc	a2,0x4
ffffffffc0200920:	3e460613          	addi	a2,a2,996 # ffffffffc0204d00 <etext+0x7b0>
ffffffffc0200924:	0d000593          	li	a1,208
ffffffffc0200928:	00004517          	auipc	a0,0x4
ffffffffc020092c:	ef850513          	addi	a0,a0,-264 # ffffffffc0204820 <etext+0x2d0>
ffffffffc0200930:	a31ff0ef          	jal	ffffffffc0200360 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc0200934:	00004517          	auipc	a0,0x4
ffffffffc0200938:	3ec50513          	addi	a0,a0,1004 # ffffffffc0204d20 <etext+0x7d0>
ffffffffc020093c:	bf8d                	j	ffffffffc02008ae <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc020093e:	00004517          	auipc	a0,0x4
ffffffffc0200942:	3fa50513          	addi	a0,a0,1018 # ffffffffc0204d38 <etext+0x7e8>
ffffffffc0200946:	e426                	sd	s1,8(sp)
ffffffffc0200948:	f72ff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020094c:	8522                	mv	a0,s0
ffffffffc020094e:	b95ff0ef          	jal	ffffffffc02004e2 <pgfault_handler>
ffffffffc0200952:	84aa                	mv	s1,a0
ffffffffc0200954:	d521                	beqz	a0,ffffffffc020089c <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200956:	8522                	mv	a0,s0
ffffffffc0200958:	de5ff0ef          	jal	ffffffffc020073c <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc020095c:	86a6                	mv	a3,s1
ffffffffc020095e:	00004617          	auipc	a2,0x4
ffffffffc0200962:	3a260613          	addi	a2,a2,930 # ffffffffc0204d00 <etext+0x7b0>
ffffffffc0200966:	0da00593          	li	a1,218
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	eb650513          	addi	a0,a0,-330 # ffffffffc0204820 <etext+0x2d0>
ffffffffc0200972:	9efff0ef          	jal	ffffffffc0200360 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200976:	00004517          	auipc	a0,0x4
ffffffffc020097a:	3da50513          	addi	a0,a0,986 # ffffffffc0204d50 <etext+0x800>
ffffffffc020097e:	bf05                	j	ffffffffc02008ae <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200980:	00004517          	auipc	a0,0x4
ffffffffc0200984:	3f050513          	addi	a0,a0,1008 # ffffffffc0204d70 <etext+0x820>
ffffffffc0200988:	b71d                	j	ffffffffc02008ae <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc020098a:	00004517          	auipc	a0,0x4
ffffffffc020098e:	40650513          	addi	a0,a0,1030 # ffffffffc0204d90 <etext+0x840>
ffffffffc0200992:	bf31                	j	ffffffffc02008ae <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200994:	00004517          	auipc	a0,0x4
ffffffffc0200998:	41c50513          	addi	a0,a0,1052 # ffffffffc0204db0 <etext+0x860>
ffffffffc020099c:	bf09                	j	ffffffffc02008ae <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc020099e:	00004517          	auipc	a0,0x4
ffffffffc02009a2:	43250513          	addi	a0,a0,1074 # ffffffffc0204dd0 <etext+0x880>
ffffffffc02009a6:	b721                	j	ffffffffc02008ae <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc02009a8:	00004517          	auipc	a0,0x4
ffffffffc02009ac:	44050513          	addi	a0,a0,1088 # ffffffffc0204de8 <etext+0x898>
ffffffffc02009b0:	e426                	sd	s1,8(sp)
ffffffffc02009b2:	f08ff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009b6:	8522                	mv	a0,s0
ffffffffc02009b8:	b2bff0ef          	jal	ffffffffc02004e2 <pgfault_handler>
ffffffffc02009bc:	84aa                	mv	s1,a0
ffffffffc02009be:	ec050fe3          	beqz	a0,ffffffffc020089c <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009c2:	8522                	mv	a0,s0
ffffffffc02009c4:	d79ff0ef          	jal	ffffffffc020073c <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009c8:	86a6                	mv	a3,s1
ffffffffc02009ca:	00004617          	auipc	a2,0x4
ffffffffc02009ce:	33660613          	addi	a2,a2,822 # ffffffffc0204d00 <etext+0x7b0>
ffffffffc02009d2:	0f000593          	li	a1,240
ffffffffc02009d6:	00004517          	auipc	a0,0x4
ffffffffc02009da:	e4a50513          	addi	a0,a0,-438 # ffffffffc0204820 <etext+0x2d0>
ffffffffc02009de:	983ff0ef          	jal	ffffffffc0200360 <__panic>
            print_trapframe(tf);
ffffffffc02009e2:	8522                	mv	a0,s0
}
ffffffffc02009e4:	6442                	ld	s0,16(sp)
ffffffffc02009e6:	60e2                	ld	ra,24(sp)
ffffffffc02009e8:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc02009ea:	bb89                	j	ffffffffc020073c <print_trapframe>
                print_trapframe(tf);
ffffffffc02009ec:	8522                	mv	a0,s0
ffffffffc02009ee:	d4fff0ef          	jal	ffffffffc020073c <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009f2:	86a6                	mv	a3,s1
ffffffffc02009f4:	00004617          	auipc	a2,0x4
ffffffffc02009f8:	30c60613          	addi	a2,a2,780 # ffffffffc0204d00 <etext+0x7b0>
ffffffffc02009fc:	0f700593          	li	a1,247
ffffffffc0200a00:	00004517          	auipc	a0,0x4
ffffffffc0200a04:	e2050513          	addi	a0,a0,-480 # ffffffffc0204820 <etext+0x2d0>
ffffffffc0200a08:	959ff0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0200a0c <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200a0c:	11853783          	ld	a5,280(a0)
ffffffffc0200a10:	0007c363          	bltz	a5,ffffffffc0200a16 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200a14:	b5a9                	j	ffffffffc020085e <exception_handler>
        interrupt_handler(tf);
ffffffffc0200a16:	b361                	j	ffffffffc020079e <interrupt_handler>
	...

ffffffffc0200a20 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200a20:	14011073          	csrw	sscratch,sp
ffffffffc0200a24:	712d                	addi	sp,sp,-288
ffffffffc0200a26:	e406                	sd	ra,8(sp)
ffffffffc0200a28:	ec0e                	sd	gp,24(sp)
ffffffffc0200a2a:	f012                	sd	tp,32(sp)
ffffffffc0200a2c:	f416                	sd	t0,40(sp)
ffffffffc0200a2e:	f81a                	sd	t1,48(sp)
ffffffffc0200a30:	fc1e                	sd	t2,56(sp)
ffffffffc0200a32:	e0a2                	sd	s0,64(sp)
ffffffffc0200a34:	e4a6                	sd	s1,72(sp)
ffffffffc0200a36:	e8aa                	sd	a0,80(sp)
ffffffffc0200a38:	ecae                	sd	a1,88(sp)
ffffffffc0200a3a:	f0b2                	sd	a2,96(sp)
ffffffffc0200a3c:	f4b6                	sd	a3,104(sp)
ffffffffc0200a3e:	f8ba                	sd	a4,112(sp)
ffffffffc0200a40:	fcbe                	sd	a5,120(sp)
ffffffffc0200a42:	e142                	sd	a6,128(sp)
ffffffffc0200a44:	e546                	sd	a7,136(sp)
ffffffffc0200a46:	e94a                	sd	s2,144(sp)
ffffffffc0200a48:	ed4e                	sd	s3,152(sp)
ffffffffc0200a4a:	f152                	sd	s4,160(sp)
ffffffffc0200a4c:	f556                	sd	s5,168(sp)
ffffffffc0200a4e:	f95a                	sd	s6,176(sp)
ffffffffc0200a50:	fd5e                	sd	s7,184(sp)
ffffffffc0200a52:	e1e2                	sd	s8,192(sp)
ffffffffc0200a54:	e5e6                	sd	s9,200(sp)
ffffffffc0200a56:	e9ea                	sd	s10,208(sp)
ffffffffc0200a58:	edee                	sd	s11,216(sp)
ffffffffc0200a5a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a5c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a5e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a60:	fdfe                	sd	t6,248(sp)
ffffffffc0200a62:	14002473          	csrr	s0,sscratch
ffffffffc0200a66:	100024f3          	csrr	s1,sstatus
ffffffffc0200a6a:	14102973          	csrr	s2,sepc
ffffffffc0200a6e:	143029f3          	csrr	s3,stval
ffffffffc0200a72:	14202a73          	csrr	s4,scause
ffffffffc0200a76:	e822                	sd	s0,16(sp)
ffffffffc0200a78:	e226                	sd	s1,256(sp)
ffffffffc0200a7a:	e64a                	sd	s2,264(sp)
ffffffffc0200a7c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a7e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a80:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a82:	f8bff0ef          	jal	ffffffffc0200a0c <trap>

ffffffffc0200a86 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a86:	6492                	ld	s1,256(sp)
ffffffffc0200a88:	6932                	ld	s2,264(sp)
ffffffffc0200a8a:	10049073          	csrw	sstatus,s1
ffffffffc0200a8e:	14191073          	csrw	sepc,s2
ffffffffc0200a92:	60a2                	ld	ra,8(sp)
ffffffffc0200a94:	61e2                	ld	gp,24(sp)
ffffffffc0200a96:	7202                	ld	tp,32(sp)
ffffffffc0200a98:	72a2                	ld	t0,40(sp)
ffffffffc0200a9a:	7342                	ld	t1,48(sp)
ffffffffc0200a9c:	73e2                	ld	t2,56(sp)
ffffffffc0200a9e:	6406                	ld	s0,64(sp)
ffffffffc0200aa0:	64a6                	ld	s1,72(sp)
ffffffffc0200aa2:	6546                	ld	a0,80(sp)
ffffffffc0200aa4:	65e6                	ld	a1,88(sp)
ffffffffc0200aa6:	7606                	ld	a2,96(sp)
ffffffffc0200aa8:	76a6                	ld	a3,104(sp)
ffffffffc0200aaa:	7746                	ld	a4,112(sp)
ffffffffc0200aac:	77e6                	ld	a5,120(sp)
ffffffffc0200aae:	680a                	ld	a6,128(sp)
ffffffffc0200ab0:	68aa                	ld	a7,136(sp)
ffffffffc0200ab2:	694a                	ld	s2,144(sp)
ffffffffc0200ab4:	69ea                	ld	s3,152(sp)
ffffffffc0200ab6:	7a0a                	ld	s4,160(sp)
ffffffffc0200ab8:	7aaa                	ld	s5,168(sp)
ffffffffc0200aba:	7b4a                	ld	s6,176(sp)
ffffffffc0200abc:	7bea                	ld	s7,184(sp)
ffffffffc0200abe:	6c0e                	ld	s8,192(sp)
ffffffffc0200ac0:	6cae                	ld	s9,200(sp)
ffffffffc0200ac2:	6d4e                	ld	s10,208(sp)
ffffffffc0200ac4:	6dee                	ld	s11,216(sp)
ffffffffc0200ac6:	7e0e                	ld	t3,224(sp)
ffffffffc0200ac8:	7eae                	ld	t4,232(sp)
ffffffffc0200aca:	7f4e                	ld	t5,240(sp)
ffffffffc0200acc:	7fee                	ld	t6,248(sp)
ffffffffc0200ace:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200ad0:	10200073          	sret
	...

ffffffffc0200ae0 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ae0:	00010797          	auipc	a5,0x10
ffffffffc0200ae4:	56078793          	addi	a5,a5,1376 # ffffffffc0211040 <free_area>
ffffffffc0200ae8:	e79c                	sd	a5,8(a5)
ffffffffc0200aea:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200aec:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200af0:	8082                	ret

ffffffffc0200af2 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200af2:	00010517          	auipc	a0,0x10
ffffffffc0200af6:	55e56503          	lwu	a0,1374(a0) # ffffffffc0211050 <free_area+0x10>
ffffffffc0200afa:	8082                	ret

ffffffffc0200afc <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200afc:	715d                	addi	sp,sp,-80
ffffffffc0200afe:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b00:	00010417          	auipc	s0,0x10
ffffffffc0200b04:	54040413          	addi	s0,s0,1344 # ffffffffc0211040 <free_area>
ffffffffc0200b08:	641c                	ld	a5,8(s0)
ffffffffc0200b0a:	e486                	sd	ra,72(sp)
ffffffffc0200b0c:	fc26                	sd	s1,56(sp)
ffffffffc0200b0e:	f84a                	sd	s2,48(sp)
ffffffffc0200b10:	f44e                	sd	s3,40(sp)
ffffffffc0200b12:	f052                	sd	s4,32(sp)
ffffffffc0200b14:	ec56                	sd	s5,24(sp)
ffffffffc0200b16:	e85a                	sd	s6,16(sp)
ffffffffc0200b18:	e45e                	sd	s7,8(sp)
ffffffffc0200b1a:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b1c:	2e878063          	beq	a5,s0,ffffffffc0200dfc <default_check+0x300>
    int count = 0, total = 0;
ffffffffc0200b20:	4481                	li	s1,0
ffffffffc0200b22:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200b24:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200b28:	8b09                	andi	a4,a4,2
ffffffffc0200b2a:	2c070d63          	beqz	a4,ffffffffc0200e04 <default_check+0x308>
        count ++, total += p->property;
ffffffffc0200b2e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b32:	679c                	ld	a5,8(a5)
ffffffffc0200b34:	2905                	addiw	s2,s2,1
ffffffffc0200b36:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b38:	fe8796e3          	bne	a5,s0,ffffffffc0200b24 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200b3c:	89a6                	mv	s3,s1
ffffffffc0200b3e:	395000ef          	jal	ffffffffc02016d2 <nr_free_pages>
ffffffffc0200b42:	73351163          	bne	a0,s3,ffffffffc0201264 <default_check+0x768>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200b46:	4505                	li	a0,1
ffffffffc0200b48:	2bb000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200b4c:	8a2a                	mv	s4,a0
ffffffffc0200b4e:	44050b63          	beqz	a0,ffffffffc0200fa4 <default_check+0x4a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200b52:	4505                	li	a0,1
ffffffffc0200b54:	2af000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200b58:	89aa                	mv	s3,a0
ffffffffc0200b5a:	72050563          	beqz	a0,ffffffffc0201284 <default_check+0x788>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b5e:	4505                	li	a0,1
ffffffffc0200b60:	2a3000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200b64:	8aaa                	mv	s5,a0
ffffffffc0200b66:	4a050f63          	beqz	a0,ffffffffc0201024 <default_check+0x528>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b6a:	2b3a0d63          	beq	s4,s3,ffffffffc0200e24 <default_check+0x328>
ffffffffc0200b6e:	2aaa0b63          	beq	s4,a0,ffffffffc0200e24 <default_check+0x328>
ffffffffc0200b72:	2aa98963          	beq	s3,a0,ffffffffc0200e24 <default_check+0x328>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b76:	000a2783          	lw	a5,0(s4)
ffffffffc0200b7a:	2c079563          	bnez	a5,ffffffffc0200e44 <default_check+0x348>
ffffffffc0200b7e:	0009a783          	lw	a5,0(s3)
ffffffffc0200b82:	2c079163          	bnez	a5,ffffffffc0200e44 <default_check+0x348>
ffffffffc0200b86:	411c                	lw	a5,0(a0)
ffffffffc0200b88:	2a079e63          	bnez	a5,ffffffffc0200e44 <default_check+0x348>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b8c:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0200b90:	e3978793          	addi	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c1>
ffffffffc0200b94:	07b2                	slli	a5,a5,0xc
ffffffffc0200b96:	e3978793          	addi	a5,a5,-455
ffffffffc0200b9a:	07b2                	slli	a5,a5,0xc
ffffffffc0200b9c:	00011717          	auipc	a4,0x11
ffffffffc0200ba0:	9a473703          	ld	a4,-1628(a4) # ffffffffc0211540 <pages>
ffffffffc0200ba4:	e3978793          	addi	a5,a5,-455
ffffffffc0200ba8:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200bac:	07b2                	slli	a5,a5,0xc
ffffffffc0200bae:	868d                	srai	a3,a3,0x3
ffffffffc0200bb0:	e3978793          	addi	a5,a5,-455
ffffffffc0200bb4:	02f686b3          	mul	a3,a3,a5
ffffffffc0200bb8:	00005597          	auipc	a1,0x5
ffffffffc0200bbc:	7e85b583          	ld	a1,2024(a1) # ffffffffc02063a0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200bc0:	00011617          	auipc	a2,0x11
ffffffffc0200bc4:	97863603          	ld	a2,-1672(a2) # ffffffffc0211538 <npage>
ffffffffc0200bc8:	0632                	slli	a2,a2,0xc
ffffffffc0200bca:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bcc:	06b2                	slli	a3,a3,0xc
ffffffffc0200bce:	28c6fb63          	bgeu	a3,a2,ffffffffc0200e64 <default_check+0x368>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bd2:	40e986b3          	sub	a3,s3,a4
ffffffffc0200bd6:	868d                	srai	a3,a3,0x3
ffffffffc0200bd8:	02f686b3          	mul	a3,a3,a5
ffffffffc0200bdc:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bde:	06b2                	slli	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200be0:	4cc6f263          	bgeu	a3,a2,ffffffffc02010a4 <default_check+0x5a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200be4:	40e50733          	sub	a4,a0,a4
ffffffffc0200be8:	870d                	srai	a4,a4,0x3
ffffffffc0200bea:	02f707b3          	mul	a5,a4,a5
ffffffffc0200bee:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bf0:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200bf2:	30c7f963          	bgeu	a5,a2,ffffffffc0200f04 <default_check+0x408>
    assert(alloc_page() == NULL);
ffffffffc0200bf6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200bf8:	00043c03          	ld	s8,0(s0)
ffffffffc0200bfc:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200c00:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200c04:	e400                	sd	s0,8(s0)
ffffffffc0200c06:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200c08:	00010797          	auipc	a5,0x10
ffffffffc0200c0c:	4407a423          	sw	zero,1096(a5) # ffffffffc0211050 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200c10:	1f3000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200c14:	2c051863          	bnez	a0,ffffffffc0200ee4 <default_check+0x3e8>
    free_page(p0);
ffffffffc0200c18:	4585                	li	a1,1
ffffffffc0200c1a:	8552                	mv	a0,s4
ffffffffc0200c1c:	277000ef          	jal	ffffffffc0201692 <free_pages>
    free_page(p1);
ffffffffc0200c20:	4585                	li	a1,1
ffffffffc0200c22:	854e                	mv	a0,s3
ffffffffc0200c24:	26f000ef          	jal	ffffffffc0201692 <free_pages>
    free_page(p2);
ffffffffc0200c28:	4585                	li	a1,1
ffffffffc0200c2a:	8556                	mv	a0,s5
ffffffffc0200c2c:	267000ef          	jal	ffffffffc0201692 <free_pages>
    assert(nr_free == 3);
ffffffffc0200c30:	4818                	lw	a4,16(s0)
ffffffffc0200c32:	478d                	li	a5,3
ffffffffc0200c34:	28f71863          	bne	a4,a5,ffffffffc0200ec4 <default_check+0x3c8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c38:	4505                	li	a0,1
ffffffffc0200c3a:	1c9000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200c3e:	89aa                	mv	s3,a0
ffffffffc0200c40:	26050263          	beqz	a0,ffffffffc0200ea4 <default_check+0x3a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c44:	4505                	li	a0,1
ffffffffc0200c46:	1bd000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200c4a:	8aaa                	mv	s5,a0
ffffffffc0200c4c:	3a050c63          	beqz	a0,ffffffffc0201004 <default_check+0x508>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c50:	4505                	li	a0,1
ffffffffc0200c52:	1b1000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200c56:	8a2a                	mv	s4,a0
ffffffffc0200c58:	38050663          	beqz	a0,ffffffffc0200fe4 <default_check+0x4e8>
    assert(alloc_page() == NULL);
ffffffffc0200c5c:	4505                	li	a0,1
ffffffffc0200c5e:	1a5000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200c62:	36051163          	bnez	a0,ffffffffc0200fc4 <default_check+0x4c8>
    free_page(p0);
ffffffffc0200c66:	4585                	li	a1,1
ffffffffc0200c68:	854e                	mv	a0,s3
ffffffffc0200c6a:	229000ef          	jal	ffffffffc0201692 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200c6e:	641c                	ld	a5,8(s0)
ffffffffc0200c70:	20878a63          	beq	a5,s0,ffffffffc0200e84 <default_check+0x388>
    assert((p = alloc_page()) == p0);
ffffffffc0200c74:	4505                	li	a0,1
ffffffffc0200c76:	18d000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200c7a:	30a99563          	bne	s3,a0,ffffffffc0200f84 <default_check+0x488>
    assert(alloc_page() == NULL);
ffffffffc0200c7e:	4505                	li	a0,1
ffffffffc0200c80:	183000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200c84:	2e051063          	bnez	a0,ffffffffc0200f64 <default_check+0x468>
    assert(nr_free == 0);
ffffffffc0200c88:	481c                	lw	a5,16(s0)
ffffffffc0200c8a:	2a079d63          	bnez	a5,ffffffffc0200f44 <default_check+0x448>
    free_page(p);
ffffffffc0200c8e:	854e                	mv	a0,s3
ffffffffc0200c90:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200c92:	01843023          	sd	s8,0(s0)
ffffffffc0200c96:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200c9a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200c9e:	1f5000ef          	jal	ffffffffc0201692 <free_pages>
    free_page(p1);
ffffffffc0200ca2:	4585                	li	a1,1
ffffffffc0200ca4:	8556                	mv	a0,s5
ffffffffc0200ca6:	1ed000ef          	jal	ffffffffc0201692 <free_pages>
    free_page(p2);
ffffffffc0200caa:	4585                	li	a1,1
ffffffffc0200cac:	8552                	mv	a0,s4
ffffffffc0200cae:	1e5000ef          	jal	ffffffffc0201692 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200cb2:	4515                	li	a0,5
ffffffffc0200cb4:	14f000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200cb8:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200cba:	26050563          	beqz	a0,ffffffffc0200f24 <default_check+0x428>
ffffffffc0200cbe:	651c                	ld	a5,8(a0)
ffffffffc0200cc0:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200cc2:	8b85                	andi	a5,a5,1
ffffffffc0200cc4:	54079063          	bnez	a5,ffffffffc0201204 <default_check+0x708>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200cc8:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200cca:	00043b03          	ld	s6,0(s0)
ffffffffc0200cce:	00843a83          	ld	s5,8(s0)
ffffffffc0200cd2:	e000                	sd	s0,0(s0)
ffffffffc0200cd4:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200cd6:	12d000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200cda:	50051563          	bnez	a0,ffffffffc02011e4 <default_check+0x6e8>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200cde:	09098a13          	addi	s4,s3,144
ffffffffc0200ce2:	8552                	mv	a0,s4
ffffffffc0200ce4:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200ce6:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200cea:	00010797          	auipc	a5,0x10
ffffffffc0200cee:	3607a323          	sw	zero,870(a5) # ffffffffc0211050 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200cf2:	1a1000ef          	jal	ffffffffc0201692 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200cf6:	4511                	li	a0,4
ffffffffc0200cf8:	10b000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200cfc:	4c051463          	bnez	a0,ffffffffc02011c4 <default_check+0x6c8>
ffffffffc0200d00:	0989b783          	ld	a5,152(s3)
ffffffffc0200d04:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200d06:	8b85                	andi	a5,a5,1
ffffffffc0200d08:	48078e63          	beqz	a5,ffffffffc02011a4 <default_check+0x6a8>
ffffffffc0200d0c:	0a89a703          	lw	a4,168(s3)
ffffffffc0200d10:	478d                	li	a5,3
ffffffffc0200d12:	48f71963          	bne	a4,a5,ffffffffc02011a4 <default_check+0x6a8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200d16:	450d                	li	a0,3
ffffffffc0200d18:	0eb000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200d1c:	8c2a                	mv	s8,a0
ffffffffc0200d1e:	46050363          	beqz	a0,ffffffffc0201184 <default_check+0x688>
    assert(alloc_page() == NULL);
ffffffffc0200d22:	4505                	li	a0,1
ffffffffc0200d24:	0df000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200d28:	42051e63          	bnez	a0,ffffffffc0201164 <default_check+0x668>
    assert(p0 + 2 == p1);
ffffffffc0200d2c:	418a1c63          	bne	s4,s8,ffffffffc0201144 <default_check+0x648>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200d30:	4585                	li	a1,1
ffffffffc0200d32:	854e                	mv	a0,s3
ffffffffc0200d34:	15f000ef          	jal	ffffffffc0201692 <free_pages>
    free_pages(p1, 3);
ffffffffc0200d38:	458d                	li	a1,3
ffffffffc0200d3a:	8552                	mv	a0,s4
ffffffffc0200d3c:	157000ef          	jal	ffffffffc0201692 <free_pages>
ffffffffc0200d40:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200d44:	04898c13          	addi	s8,s3,72
ffffffffc0200d48:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200d4a:	8b85                	andi	a5,a5,1
ffffffffc0200d4c:	3c078c63          	beqz	a5,ffffffffc0201124 <default_check+0x628>
ffffffffc0200d50:	0189a703          	lw	a4,24(s3)
ffffffffc0200d54:	4785                	li	a5,1
ffffffffc0200d56:	3cf71763          	bne	a4,a5,ffffffffc0201124 <default_check+0x628>
ffffffffc0200d5a:	008a3783          	ld	a5,8(s4)
ffffffffc0200d5e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200d60:	8b85                	andi	a5,a5,1
ffffffffc0200d62:	3a078163          	beqz	a5,ffffffffc0201104 <default_check+0x608>
ffffffffc0200d66:	018a2703          	lw	a4,24(s4)
ffffffffc0200d6a:	478d                	li	a5,3
ffffffffc0200d6c:	38f71c63          	bne	a4,a5,ffffffffc0201104 <default_check+0x608>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200d70:	4505                	li	a0,1
ffffffffc0200d72:	091000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200d76:	36a99763          	bne	s3,a0,ffffffffc02010e4 <default_check+0x5e8>
    free_page(p0);
ffffffffc0200d7a:	4585                	li	a1,1
ffffffffc0200d7c:	117000ef          	jal	ffffffffc0201692 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200d80:	4509                	li	a0,2
ffffffffc0200d82:	081000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200d86:	32aa1f63          	bne	s4,a0,ffffffffc02010c4 <default_check+0x5c8>

    free_pages(p0, 2);
ffffffffc0200d8a:	4589                	li	a1,2
ffffffffc0200d8c:	107000ef          	jal	ffffffffc0201692 <free_pages>
    free_page(p2);
ffffffffc0200d90:	4585                	li	a1,1
ffffffffc0200d92:	8562                	mv	a0,s8
ffffffffc0200d94:	0ff000ef          	jal	ffffffffc0201692 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200d98:	4515                	li	a0,5
ffffffffc0200d9a:	069000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200d9e:	89aa                	mv	s3,a0
ffffffffc0200da0:	48050263          	beqz	a0,ffffffffc0201224 <default_check+0x728>
    assert(alloc_page() == NULL);
ffffffffc0200da4:	4505                	li	a0,1
ffffffffc0200da6:	05d000ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0200daa:	2c051d63          	bnez	a0,ffffffffc0201084 <default_check+0x588>

    assert(nr_free == 0);
ffffffffc0200dae:	481c                	lw	a5,16(s0)
ffffffffc0200db0:	2a079a63          	bnez	a5,ffffffffc0201064 <default_check+0x568>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200db4:	4595                	li	a1,5
ffffffffc0200db6:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200db8:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200dbc:	01643023          	sd	s6,0(s0)
ffffffffc0200dc0:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200dc4:	0cf000ef          	jal	ffffffffc0201692 <free_pages>
    return listelm->next;
ffffffffc0200dc8:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dca:	00878963          	beq	a5,s0,ffffffffc0200ddc <default_check+0x2e0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200dce:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200dd2:	679c                	ld	a5,8(a5)
ffffffffc0200dd4:	397d                	addiw	s2,s2,-1
ffffffffc0200dd6:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dd8:	fe879be3          	bne	a5,s0,ffffffffc0200dce <default_check+0x2d2>
    }
    assert(count == 0);
ffffffffc0200ddc:	26091463          	bnez	s2,ffffffffc0201044 <default_check+0x548>
    assert(total == 0);
ffffffffc0200de0:	46049263          	bnez	s1,ffffffffc0201244 <default_check+0x748>
}
ffffffffc0200de4:	60a6                	ld	ra,72(sp)
ffffffffc0200de6:	6406                	ld	s0,64(sp)
ffffffffc0200de8:	74e2                	ld	s1,56(sp)
ffffffffc0200dea:	7942                	ld	s2,48(sp)
ffffffffc0200dec:	79a2                	ld	s3,40(sp)
ffffffffc0200dee:	7a02                	ld	s4,32(sp)
ffffffffc0200df0:	6ae2                	ld	s5,24(sp)
ffffffffc0200df2:	6b42                	ld	s6,16(sp)
ffffffffc0200df4:	6ba2                	ld	s7,8(sp)
ffffffffc0200df6:	6c02                	ld	s8,0(sp)
ffffffffc0200df8:	6161                	addi	sp,sp,80
ffffffffc0200dfa:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dfc:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200dfe:	4481                	li	s1,0
ffffffffc0200e00:	4901                	li	s2,0
ffffffffc0200e02:	bb35                	j	ffffffffc0200b3e <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200e04:	00004697          	auipc	a3,0x4
ffffffffc0200e08:	01468693          	addi	a3,a3,20 # ffffffffc0204e18 <etext+0x8c8>
ffffffffc0200e0c:	00004617          	auipc	a2,0x4
ffffffffc0200e10:	01c60613          	addi	a2,a2,28 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200e14:	0f000593          	li	a1,240
ffffffffc0200e18:	00004517          	auipc	a0,0x4
ffffffffc0200e1c:	02850513          	addi	a0,a0,40 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200e20:	d40ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e24:	00004697          	auipc	a3,0x4
ffffffffc0200e28:	0b468693          	addi	a3,a3,180 # ffffffffc0204ed8 <etext+0x988>
ffffffffc0200e2c:	00004617          	auipc	a2,0x4
ffffffffc0200e30:	ffc60613          	addi	a2,a2,-4 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200e34:	0bd00593          	li	a1,189
ffffffffc0200e38:	00004517          	auipc	a0,0x4
ffffffffc0200e3c:	00850513          	addi	a0,a0,8 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200e40:	d20ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e44:	00004697          	auipc	a3,0x4
ffffffffc0200e48:	0bc68693          	addi	a3,a3,188 # ffffffffc0204f00 <etext+0x9b0>
ffffffffc0200e4c:	00004617          	auipc	a2,0x4
ffffffffc0200e50:	fdc60613          	addi	a2,a2,-36 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200e54:	0be00593          	li	a1,190
ffffffffc0200e58:	00004517          	auipc	a0,0x4
ffffffffc0200e5c:	fe850513          	addi	a0,a0,-24 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200e60:	d00ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e64:	00004697          	auipc	a3,0x4
ffffffffc0200e68:	0dc68693          	addi	a3,a3,220 # ffffffffc0204f40 <etext+0x9f0>
ffffffffc0200e6c:	00004617          	auipc	a2,0x4
ffffffffc0200e70:	fbc60613          	addi	a2,a2,-68 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200e74:	0c000593          	li	a1,192
ffffffffc0200e78:	00004517          	auipc	a0,0x4
ffffffffc0200e7c:	fc850513          	addi	a0,a0,-56 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200e80:	ce0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200e84:	00004697          	auipc	a3,0x4
ffffffffc0200e88:	14468693          	addi	a3,a3,324 # ffffffffc0204fc8 <etext+0xa78>
ffffffffc0200e8c:	00004617          	auipc	a2,0x4
ffffffffc0200e90:	f9c60613          	addi	a2,a2,-100 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200e94:	0d900593          	li	a1,217
ffffffffc0200e98:	00004517          	auipc	a0,0x4
ffffffffc0200e9c:	fa850513          	addi	a0,a0,-88 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200ea0:	cc0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ea4:	00004697          	auipc	a3,0x4
ffffffffc0200ea8:	fd468693          	addi	a3,a3,-44 # ffffffffc0204e78 <etext+0x928>
ffffffffc0200eac:	00004617          	auipc	a2,0x4
ffffffffc0200eb0:	f7c60613          	addi	a2,a2,-132 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200eb4:	0d200593          	li	a1,210
ffffffffc0200eb8:	00004517          	auipc	a0,0x4
ffffffffc0200ebc:	f8850513          	addi	a0,a0,-120 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200ec0:	ca0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free == 3);
ffffffffc0200ec4:	00004697          	auipc	a3,0x4
ffffffffc0200ec8:	0f468693          	addi	a3,a3,244 # ffffffffc0204fb8 <etext+0xa68>
ffffffffc0200ecc:	00004617          	auipc	a2,0x4
ffffffffc0200ed0:	f5c60613          	addi	a2,a2,-164 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200ed4:	0d000593          	li	a1,208
ffffffffc0200ed8:	00004517          	auipc	a0,0x4
ffffffffc0200edc:	f6850513          	addi	a0,a0,-152 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200ee0:	c80ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ee4:	00004697          	auipc	a3,0x4
ffffffffc0200ee8:	0bc68693          	addi	a3,a3,188 # ffffffffc0204fa0 <etext+0xa50>
ffffffffc0200eec:	00004617          	auipc	a2,0x4
ffffffffc0200ef0:	f3c60613          	addi	a2,a2,-196 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200ef4:	0cb00593          	li	a1,203
ffffffffc0200ef8:	00004517          	auipc	a0,0x4
ffffffffc0200efc:	f4850513          	addi	a0,a0,-184 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200f00:	c60ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f04:	00004697          	auipc	a3,0x4
ffffffffc0200f08:	07c68693          	addi	a3,a3,124 # ffffffffc0204f80 <etext+0xa30>
ffffffffc0200f0c:	00004617          	auipc	a2,0x4
ffffffffc0200f10:	f1c60613          	addi	a2,a2,-228 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200f14:	0c200593          	li	a1,194
ffffffffc0200f18:	00004517          	auipc	a0,0x4
ffffffffc0200f1c:	f2850513          	addi	a0,a0,-216 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200f20:	c40ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(p0 != NULL);
ffffffffc0200f24:	00004697          	auipc	a3,0x4
ffffffffc0200f28:	0ec68693          	addi	a3,a3,236 # ffffffffc0205010 <etext+0xac0>
ffffffffc0200f2c:	00004617          	auipc	a2,0x4
ffffffffc0200f30:	efc60613          	addi	a2,a2,-260 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200f34:	0f800593          	li	a1,248
ffffffffc0200f38:	00004517          	auipc	a0,0x4
ffffffffc0200f3c:	f0850513          	addi	a0,a0,-248 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200f40:	c20ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free == 0);
ffffffffc0200f44:	00004697          	auipc	a3,0x4
ffffffffc0200f48:	0bc68693          	addi	a3,a3,188 # ffffffffc0205000 <etext+0xab0>
ffffffffc0200f4c:	00004617          	auipc	a2,0x4
ffffffffc0200f50:	edc60613          	addi	a2,a2,-292 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200f54:	0df00593          	li	a1,223
ffffffffc0200f58:	00004517          	auipc	a0,0x4
ffffffffc0200f5c:	ee850513          	addi	a0,a0,-280 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200f60:	c00ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f64:	00004697          	auipc	a3,0x4
ffffffffc0200f68:	03c68693          	addi	a3,a3,60 # ffffffffc0204fa0 <etext+0xa50>
ffffffffc0200f6c:	00004617          	auipc	a2,0x4
ffffffffc0200f70:	ebc60613          	addi	a2,a2,-324 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200f74:	0dd00593          	li	a1,221
ffffffffc0200f78:	00004517          	auipc	a0,0x4
ffffffffc0200f7c:	ec850513          	addi	a0,a0,-312 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200f80:	be0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f84:	00004697          	auipc	a3,0x4
ffffffffc0200f88:	05c68693          	addi	a3,a3,92 # ffffffffc0204fe0 <etext+0xa90>
ffffffffc0200f8c:	00004617          	auipc	a2,0x4
ffffffffc0200f90:	e9c60613          	addi	a2,a2,-356 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200f94:	0dc00593          	li	a1,220
ffffffffc0200f98:	00004517          	auipc	a0,0x4
ffffffffc0200f9c:	ea850513          	addi	a0,a0,-344 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200fa0:	bc0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fa4:	00004697          	auipc	a3,0x4
ffffffffc0200fa8:	ed468693          	addi	a3,a3,-300 # ffffffffc0204e78 <etext+0x928>
ffffffffc0200fac:	00004617          	auipc	a2,0x4
ffffffffc0200fb0:	e7c60613          	addi	a2,a2,-388 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200fb4:	0b900593          	li	a1,185
ffffffffc0200fb8:	00004517          	auipc	a0,0x4
ffffffffc0200fbc:	e8850513          	addi	a0,a0,-376 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200fc0:	ba0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fc4:	00004697          	auipc	a3,0x4
ffffffffc0200fc8:	fdc68693          	addi	a3,a3,-36 # ffffffffc0204fa0 <etext+0xa50>
ffffffffc0200fcc:	00004617          	auipc	a2,0x4
ffffffffc0200fd0:	e5c60613          	addi	a2,a2,-420 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200fd4:	0d600593          	li	a1,214
ffffffffc0200fd8:	00004517          	auipc	a0,0x4
ffffffffc0200fdc:	e6850513          	addi	a0,a0,-408 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0200fe0:	b80ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fe4:	00004697          	auipc	a3,0x4
ffffffffc0200fe8:	ed468693          	addi	a3,a3,-300 # ffffffffc0204eb8 <etext+0x968>
ffffffffc0200fec:	00004617          	auipc	a2,0x4
ffffffffc0200ff0:	e3c60613          	addi	a2,a2,-452 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0200ff4:	0d400593          	li	a1,212
ffffffffc0200ff8:	00004517          	auipc	a0,0x4
ffffffffc0200ffc:	e4850513          	addi	a0,a0,-440 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201000:	b60ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201004:	00004697          	auipc	a3,0x4
ffffffffc0201008:	e9468693          	addi	a3,a3,-364 # ffffffffc0204e98 <etext+0x948>
ffffffffc020100c:	00004617          	auipc	a2,0x4
ffffffffc0201010:	e1c60613          	addi	a2,a2,-484 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201014:	0d300593          	li	a1,211
ffffffffc0201018:	00004517          	auipc	a0,0x4
ffffffffc020101c:	e2850513          	addi	a0,a0,-472 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201020:	b40ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201024:	00004697          	auipc	a3,0x4
ffffffffc0201028:	e9468693          	addi	a3,a3,-364 # ffffffffc0204eb8 <etext+0x968>
ffffffffc020102c:	00004617          	auipc	a2,0x4
ffffffffc0201030:	dfc60613          	addi	a2,a2,-516 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201034:	0bb00593          	li	a1,187
ffffffffc0201038:	00004517          	auipc	a0,0x4
ffffffffc020103c:	e0850513          	addi	a0,a0,-504 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201040:	b20ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(count == 0);
ffffffffc0201044:	00004697          	auipc	a3,0x4
ffffffffc0201048:	11c68693          	addi	a3,a3,284 # ffffffffc0205160 <etext+0xc10>
ffffffffc020104c:	00004617          	auipc	a2,0x4
ffffffffc0201050:	ddc60613          	addi	a2,a2,-548 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201054:	12500593          	li	a1,293
ffffffffc0201058:	00004517          	auipc	a0,0x4
ffffffffc020105c:	de850513          	addi	a0,a0,-536 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201060:	b00ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free == 0);
ffffffffc0201064:	00004697          	auipc	a3,0x4
ffffffffc0201068:	f9c68693          	addi	a3,a3,-100 # ffffffffc0205000 <etext+0xab0>
ffffffffc020106c:	00004617          	auipc	a2,0x4
ffffffffc0201070:	dbc60613          	addi	a2,a2,-580 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201074:	11a00593          	li	a1,282
ffffffffc0201078:	00004517          	auipc	a0,0x4
ffffffffc020107c:	dc850513          	addi	a0,a0,-568 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201080:	ae0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201084:	00004697          	auipc	a3,0x4
ffffffffc0201088:	f1c68693          	addi	a3,a3,-228 # ffffffffc0204fa0 <etext+0xa50>
ffffffffc020108c:	00004617          	auipc	a2,0x4
ffffffffc0201090:	d9c60613          	addi	a2,a2,-612 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201094:	11800593          	li	a1,280
ffffffffc0201098:	00004517          	auipc	a0,0x4
ffffffffc020109c:	da850513          	addi	a0,a0,-600 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02010a0:	ac0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010a4:	00004697          	auipc	a3,0x4
ffffffffc02010a8:	ebc68693          	addi	a3,a3,-324 # ffffffffc0204f60 <etext+0xa10>
ffffffffc02010ac:	00004617          	auipc	a2,0x4
ffffffffc02010b0:	d7c60613          	addi	a2,a2,-644 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02010b4:	0c100593          	li	a1,193
ffffffffc02010b8:	00004517          	auipc	a0,0x4
ffffffffc02010bc:	d8850513          	addi	a0,a0,-632 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02010c0:	aa0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02010c4:	00004697          	auipc	a3,0x4
ffffffffc02010c8:	05c68693          	addi	a3,a3,92 # ffffffffc0205120 <etext+0xbd0>
ffffffffc02010cc:	00004617          	auipc	a2,0x4
ffffffffc02010d0:	d5c60613          	addi	a2,a2,-676 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02010d4:	11200593          	li	a1,274
ffffffffc02010d8:	00004517          	auipc	a0,0x4
ffffffffc02010dc:	d6850513          	addi	a0,a0,-664 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02010e0:	a80ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02010e4:	00004697          	auipc	a3,0x4
ffffffffc02010e8:	01c68693          	addi	a3,a3,28 # ffffffffc0205100 <etext+0xbb0>
ffffffffc02010ec:	00004617          	auipc	a2,0x4
ffffffffc02010f0:	d3c60613          	addi	a2,a2,-708 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02010f4:	11000593          	li	a1,272
ffffffffc02010f8:	00004517          	auipc	a0,0x4
ffffffffc02010fc:	d4850513          	addi	a0,a0,-696 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201100:	a60ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201104:	00004697          	auipc	a3,0x4
ffffffffc0201108:	fd468693          	addi	a3,a3,-44 # ffffffffc02050d8 <etext+0xb88>
ffffffffc020110c:	00004617          	auipc	a2,0x4
ffffffffc0201110:	d1c60613          	addi	a2,a2,-740 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201114:	10e00593          	li	a1,270
ffffffffc0201118:	00004517          	auipc	a0,0x4
ffffffffc020111c:	d2850513          	addi	a0,a0,-728 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201120:	a40ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201124:	00004697          	auipc	a3,0x4
ffffffffc0201128:	f8c68693          	addi	a3,a3,-116 # ffffffffc02050b0 <etext+0xb60>
ffffffffc020112c:	00004617          	auipc	a2,0x4
ffffffffc0201130:	cfc60613          	addi	a2,a2,-772 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201134:	10d00593          	li	a1,269
ffffffffc0201138:	00004517          	auipc	a0,0x4
ffffffffc020113c:	d0850513          	addi	a0,a0,-760 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201140:	a20ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201144:	00004697          	auipc	a3,0x4
ffffffffc0201148:	f5c68693          	addi	a3,a3,-164 # ffffffffc02050a0 <etext+0xb50>
ffffffffc020114c:	00004617          	auipc	a2,0x4
ffffffffc0201150:	cdc60613          	addi	a2,a2,-804 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201154:	10800593          	li	a1,264
ffffffffc0201158:	00004517          	auipc	a0,0x4
ffffffffc020115c:	ce850513          	addi	a0,a0,-792 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201160:	a00ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201164:	00004697          	auipc	a3,0x4
ffffffffc0201168:	e3c68693          	addi	a3,a3,-452 # ffffffffc0204fa0 <etext+0xa50>
ffffffffc020116c:	00004617          	auipc	a2,0x4
ffffffffc0201170:	cbc60613          	addi	a2,a2,-836 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201174:	10700593          	li	a1,263
ffffffffc0201178:	00004517          	auipc	a0,0x4
ffffffffc020117c:	cc850513          	addi	a0,a0,-824 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201180:	9e0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201184:	00004697          	auipc	a3,0x4
ffffffffc0201188:	efc68693          	addi	a3,a3,-260 # ffffffffc0205080 <etext+0xb30>
ffffffffc020118c:	00004617          	auipc	a2,0x4
ffffffffc0201190:	c9c60613          	addi	a2,a2,-868 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201194:	10600593          	li	a1,262
ffffffffc0201198:	00004517          	auipc	a0,0x4
ffffffffc020119c:	ca850513          	addi	a0,a0,-856 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02011a0:	9c0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011a4:	00004697          	auipc	a3,0x4
ffffffffc02011a8:	eac68693          	addi	a3,a3,-340 # ffffffffc0205050 <etext+0xb00>
ffffffffc02011ac:	00004617          	auipc	a2,0x4
ffffffffc02011b0:	c7c60613          	addi	a2,a2,-900 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02011b4:	10500593          	li	a1,261
ffffffffc02011b8:	00004517          	auipc	a0,0x4
ffffffffc02011bc:	c8850513          	addi	a0,a0,-888 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02011c0:	9a0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02011c4:	00004697          	auipc	a3,0x4
ffffffffc02011c8:	e7468693          	addi	a3,a3,-396 # ffffffffc0205038 <etext+0xae8>
ffffffffc02011cc:	00004617          	auipc	a2,0x4
ffffffffc02011d0:	c5c60613          	addi	a2,a2,-932 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02011d4:	10400593          	li	a1,260
ffffffffc02011d8:	00004517          	auipc	a0,0x4
ffffffffc02011dc:	c6850513          	addi	a0,a0,-920 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02011e0:	980ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011e4:	00004697          	auipc	a3,0x4
ffffffffc02011e8:	dbc68693          	addi	a3,a3,-580 # ffffffffc0204fa0 <etext+0xa50>
ffffffffc02011ec:	00004617          	auipc	a2,0x4
ffffffffc02011f0:	c3c60613          	addi	a2,a2,-964 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02011f4:	0fe00593          	li	a1,254
ffffffffc02011f8:	00004517          	auipc	a0,0x4
ffffffffc02011fc:	c4850513          	addi	a0,a0,-952 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201200:	960ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201204:	00004697          	auipc	a3,0x4
ffffffffc0201208:	e1c68693          	addi	a3,a3,-484 # ffffffffc0205020 <etext+0xad0>
ffffffffc020120c:	00004617          	auipc	a2,0x4
ffffffffc0201210:	c1c60613          	addi	a2,a2,-996 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201214:	0f900593          	li	a1,249
ffffffffc0201218:	00004517          	auipc	a0,0x4
ffffffffc020121c:	c2850513          	addi	a0,a0,-984 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201220:	940ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201224:	00004697          	auipc	a3,0x4
ffffffffc0201228:	f1c68693          	addi	a3,a3,-228 # ffffffffc0205140 <etext+0xbf0>
ffffffffc020122c:	00004617          	auipc	a2,0x4
ffffffffc0201230:	bfc60613          	addi	a2,a2,-1028 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201234:	11700593          	li	a1,279
ffffffffc0201238:	00004517          	auipc	a0,0x4
ffffffffc020123c:	c0850513          	addi	a0,a0,-1016 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201240:	920ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(total == 0);
ffffffffc0201244:	00004697          	auipc	a3,0x4
ffffffffc0201248:	f2c68693          	addi	a3,a3,-212 # ffffffffc0205170 <etext+0xc20>
ffffffffc020124c:	00004617          	auipc	a2,0x4
ffffffffc0201250:	bdc60613          	addi	a2,a2,-1060 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201254:	12600593          	li	a1,294
ffffffffc0201258:	00004517          	auipc	a0,0x4
ffffffffc020125c:	be850513          	addi	a0,a0,-1048 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201260:	900ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201264:	00004697          	auipc	a3,0x4
ffffffffc0201268:	bf468693          	addi	a3,a3,-1036 # ffffffffc0204e58 <etext+0x908>
ffffffffc020126c:	00004617          	auipc	a2,0x4
ffffffffc0201270:	bbc60613          	addi	a2,a2,-1092 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201274:	0f300593          	li	a1,243
ffffffffc0201278:	00004517          	auipc	a0,0x4
ffffffffc020127c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201280:	8e0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201284:	00004697          	auipc	a3,0x4
ffffffffc0201288:	c1468693          	addi	a3,a3,-1004 # ffffffffc0204e98 <etext+0x948>
ffffffffc020128c:	00004617          	auipc	a2,0x4
ffffffffc0201290:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0201294:	0ba00593          	li	a1,186
ffffffffc0201298:	00004517          	auipc	a0,0x4
ffffffffc020129c:	ba850513          	addi	a0,a0,-1112 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02012a0:	8c0ff0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02012a4 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02012a4:	1141                	addi	sp,sp,-16
ffffffffc02012a6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02012a8:	14058a63          	beqz	a1,ffffffffc02013fc <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc02012ac:	00359713          	slli	a4,a1,0x3
ffffffffc02012b0:	972e                	add	a4,a4,a1
ffffffffc02012b2:	070e                	slli	a4,a4,0x3
ffffffffc02012b4:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02012b8:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02012ba:	c30d                	beqz	a4,ffffffffc02012dc <default_free_pages+0x38>
ffffffffc02012bc:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02012be:	8b05                	andi	a4,a4,1
ffffffffc02012c0:	10071e63          	bnez	a4,ffffffffc02013dc <default_free_pages+0x138>
ffffffffc02012c4:	6798                	ld	a4,8(a5)
ffffffffc02012c6:	8b09                	andi	a4,a4,2
ffffffffc02012c8:	10071a63          	bnez	a4,ffffffffc02013dc <default_free_pages+0x138>
        p->flags = 0;
ffffffffc02012cc:	0007b423          	sd	zero,8(a5)
    return pa2page(PDE_ADDR(pde));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02012d0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02012d4:	04878793          	addi	a5,a5,72
ffffffffc02012d8:	fed792e3          	bne	a5,a3,ffffffffc02012bc <default_free_pages+0x18>
    base->property = n;
ffffffffc02012dc:	2581                	sext.w	a1,a1
ffffffffc02012de:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc02012e0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02012e4:	4789                	li	a5,2
ffffffffc02012e6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02012ea:	00010697          	auipc	a3,0x10
ffffffffc02012ee:	d5668693          	addi	a3,a3,-682 # ffffffffc0211040 <free_area>
ffffffffc02012f2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02012f4:	669c                	ld	a5,8(a3)
ffffffffc02012f6:	9f2d                	addw	a4,a4,a1
ffffffffc02012f8:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02012fa:	0ad78563          	beq	a5,a3,ffffffffc02013a4 <default_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc02012fe:	fe078713          	addi	a4,a5,-32
ffffffffc0201302:	4581                	li	a1,0
ffffffffc0201304:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0201308:	00e56a63          	bltu	a0,a4,ffffffffc020131c <default_free_pages+0x78>
    return listelm->next;
ffffffffc020130c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020130e:	06d70263          	beq	a4,a3,ffffffffc0201372 <default_free_pages+0xce>
    struct Page *p = base;
ffffffffc0201312:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201314:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0201318:	fee57ae3          	bgeu	a0,a4,ffffffffc020130c <default_free_pages+0x68>
ffffffffc020131c:	c199                	beqz	a1,ffffffffc0201322 <default_free_pages+0x7e>
ffffffffc020131e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201322:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201324:	e390                	sd	a2,0(a5)
ffffffffc0201326:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201328:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020132a:	f118                	sd	a4,32(a0)
    if (le != &free_list) {
ffffffffc020132c:	02d70063          	beq	a4,a3,ffffffffc020134c <default_free_pages+0xa8>
        if (p + p->property == base) {
ffffffffc0201330:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201334:	fe070593          	addi	a1,a4,-32
        if (p + p->property == base) {
ffffffffc0201338:	02081613          	slli	a2,a6,0x20
ffffffffc020133c:	9201                	srli	a2,a2,0x20
ffffffffc020133e:	00361793          	slli	a5,a2,0x3
ffffffffc0201342:	97b2                	add	a5,a5,a2
ffffffffc0201344:	078e                	slli	a5,a5,0x3
ffffffffc0201346:	97ae                	add	a5,a5,a1
ffffffffc0201348:	02f50f63          	beq	a0,a5,ffffffffc0201386 <default_free_pages+0xe2>
    return listelm->next;
ffffffffc020134c:	7518                	ld	a4,40(a0)
    if (le != &free_list) {
ffffffffc020134e:	00d70f63          	beq	a4,a3,ffffffffc020136c <default_free_pages+0xc8>
        if (base + base->property == p) {
ffffffffc0201352:	4d0c                	lw	a1,24(a0)
        p = le2page(le, page_link);
ffffffffc0201354:	fe070693          	addi	a3,a4,-32
        if (base + base->property == p) {
ffffffffc0201358:	02059613          	slli	a2,a1,0x20
ffffffffc020135c:	9201                	srli	a2,a2,0x20
ffffffffc020135e:	00361793          	slli	a5,a2,0x3
ffffffffc0201362:	97b2                	add	a5,a5,a2
ffffffffc0201364:	078e                	slli	a5,a5,0x3
ffffffffc0201366:	97aa                	add	a5,a5,a0
ffffffffc0201368:	04f68a63          	beq	a3,a5,ffffffffc02013bc <default_free_pages+0x118>
}
ffffffffc020136c:	60a2                	ld	ra,8(sp)
ffffffffc020136e:	0141                	addi	sp,sp,16
ffffffffc0201370:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201372:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201374:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0201376:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201378:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020137a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020137c:	02d70d63          	beq	a4,a3,ffffffffc02013b6 <default_free_pages+0x112>
ffffffffc0201380:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201382:	87ba                	mv	a5,a4
ffffffffc0201384:	bf41                	j	ffffffffc0201314 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201386:	4d1c                	lw	a5,24(a0)
ffffffffc0201388:	010787bb          	addw	a5,a5,a6
ffffffffc020138c:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201390:	57f5                	li	a5,-3
ffffffffc0201392:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201396:	7110                	ld	a2,32(a0)
ffffffffc0201398:	751c                	ld	a5,40(a0)
            base = p;
ffffffffc020139a:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020139c:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc020139e:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02013a0:	e390                	sd	a2,0(a5)
ffffffffc02013a2:	b775                	j	ffffffffc020134e <default_free_pages+0xaa>
}
ffffffffc02013a4:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02013a6:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc02013aa:	e398                	sd	a4,0(a5)
ffffffffc02013ac:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02013ae:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02013b0:	f11c                	sd	a5,32(a0)
}
ffffffffc02013b2:	0141                	addi	sp,sp,16
ffffffffc02013b4:	8082                	ret
ffffffffc02013b6:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02013b8:	873e                	mv	a4,a5
ffffffffc02013ba:	bf8d                	j	ffffffffc020132c <default_free_pages+0x88>
            base->property += p->property;
ffffffffc02013bc:	ff872783          	lw	a5,-8(a4)
ffffffffc02013c0:	fe870693          	addi	a3,a4,-24
ffffffffc02013c4:	9fad                	addw	a5,a5,a1
ffffffffc02013c6:	cd1c                	sw	a5,24(a0)
ffffffffc02013c8:	57f5                	li	a5,-3
ffffffffc02013ca:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02013ce:	6314                	ld	a3,0(a4)
ffffffffc02013d0:	671c                	ld	a5,8(a4)
}
ffffffffc02013d2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02013d4:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02013d6:	e394                	sd	a3,0(a5)
ffffffffc02013d8:	0141                	addi	sp,sp,16
ffffffffc02013da:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02013dc:	00004697          	auipc	a3,0x4
ffffffffc02013e0:	dac68693          	addi	a3,a3,-596 # ffffffffc0205188 <etext+0xc38>
ffffffffc02013e4:	00004617          	auipc	a2,0x4
ffffffffc02013e8:	a4460613          	addi	a2,a2,-1468 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02013ec:	08300593          	li	a1,131
ffffffffc02013f0:	00004517          	auipc	a0,0x4
ffffffffc02013f4:	a5050513          	addi	a0,a0,-1456 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02013f8:	f69fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(n > 0);
ffffffffc02013fc:	00004697          	auipc	a3,0x4
ffffffffc0201400:	d8468693          	addi	a3,a3,-636 # ffffffffc0205180 <etext+0xc30>
ffffffffc0201404:	00004617          	auipc	a2,0x4
ffffffffc0201408:	a2460613          	addi	a2,a2,-1500 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020140c:	08000593          	li	a1,128
ffffffffc0201410:	00004517          	auipc	a0,0x4
ffffffffc0201414:	a3050513          	addi	a0,a0,-1488 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc0201418:	f49fe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020141c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020141c:	c959                	beqz	a0,ffffffffc02014b2 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc020141e:	00010617          	auipc	a2,0x10
ffffffffc0201422:	c2260613          	addi	a2,a2,-990 # ffffffffc0211040 <free_area>
ffffffffc0201426:	4a0c                	lw	a1,16(a2)
ffffffffc0201428:	86aa                	mv	a3,a0
ffffffffc020142a:	02059793          	slli	a5,a1,0x20
ffffffffc020142e:	9381                	srli	a5,a5,0x20
ffffffffc0201430:	00a7eb63          	bltu	a5,a0,ffffffffc0201446 <default_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc0201434:	87b2                	mv	a5,a2
ffffffffc0201436:	a029                	j	ffffffffc0201440 <default_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc0201438:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020143c:	00d77763          	bgeu	a4,a3,ffffffffc020144a <default_alloc_pages+0x2e>
    return listelm->next;
ffffffffc0201440:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201442:	fec79be3          	bne	a5,a2,ffffffffc0201438 <default_alloc_pages+0x1c>
        return NULL;
ffffffffc0201446:	4501                	li	a0,0
}
ffffffffc0201448:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc020144a:	6798                	ld	a4,8(a5)
    return listelm->prev;
ffffffffc020144c:	0007b803          	ld	a6,0(a5)
        if (page->property > n) {
ffffffffc0201450:	ff87a883          	lw	a7,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201454:	fe078513          	addi	a0,a5,-32
    prev->next = next;
ffffffffc0201458:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020145c:	01073023          	sd	a6,0(a4)
        if (page->property > n) {
ffffffffc0201460:	02089713          	slli	a4,a7,0x20
ffffffffc0201464:	9301                	srli	a4,a4,0x20
            p->property = page->property - n;
ffffffffc0201466:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc020146a:	02e6fc63          	bgeu	a3,a4,ffffffffc02014a2 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020146e:	00369713          	slli	a4,a3,0x3
ffffffffc0201472:	9736                	add	a4,a4,a3
ffffffffc0201474:	070e                	slli	a4,a4,0x3
ffffffffc0201476:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201478:	406888bb          	subw	a7,a7,t1
ffffffffc020147c:	01172c23          	sw	a7,24(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201480:	4689                	li	a3,2
ffffffffc0201482:	00870593          	addi	a1,a4,8
ffffffffc0201486:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020148a:	00883683          	ld	a3,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020148e:	02070893          	addi	a7,a4,32
        nr_free -= n;
ffffffffc0201492:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc0201494:	0116b023          	sd	a7,0(a3)
ffffffffc0201498:	01183423          	sd	a7,8(a6)
    elm->next = next;
ffffffffc020149c:	f714                	sd	a3,40(a4)
    elm->prev = prev;
ffffffffc020149e:	03073023          	sd	a6,32(a4)
ffffffffc02014a2:	406585bb          	subw	a1,a1,t1
ffffffffc02014a6:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014a8:	5775                	li	a4,-3
ffffffffc02014aa:	17a1                	addi	a5,a5,-24
ffffffffc02014ac:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02014b0:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02014b2:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02014b4:	00004697          	auipc	a3,0x4
ffffffffc02014b8:	ccc68693          	addi	a3,a3,-820 # ffffffffc0205180 <etext+0xc30>
ffffffffc02014bc:	00004617          	auipc	a2,0x4
ffffffffc02014c0:	96c60613          	addi	a2,a2,-1684 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02014c4:	06200593          	li	a1,98
ffffffffc02014c8:	00004517          	auipc	a0,0x4
ffffffffc02014cc:	97850513          	addi	a0,a0,-1672 # ffffffffc0204e40 <etext+0x8f0>
default_alloc_pages(size_t n) {
ffffffffc02014d0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02014d2:	e8ffe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02014d6 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02014d6:	1141                	addi	sp,sp,-16
ffffffffc02014d8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02014da:	c9e1                	beqz	a1,ffffffffc02015aa <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02014dc:	00359713          	slli	a4,a1,0x3
ffffffffc02014e0:	972e                	add	a4,a4,a1
ffffffffc02014e2:	070e                	slli	a4,a4,0x3
ffffffffc02014e4:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02014e8:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02014ea:	cf11                	beqz	a4,ffffffffc0201506 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02014ec:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02014ee:	8b05                	andi	a4,a4,1
ffffffffc02014f0:	cf49                	beqz	a4,ffffffffc020158a <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02014f2:	0007ac23          	sw	zero,24(a5)
ffffffffc02014f6:	0007b423          	sd	zero,8(a5)
ffffffffc02014fa:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014fe:	04878793          	addi	a5,a5,72
ffffffffc0201502:	fed795e3          	bne	a5,a3,ffffffffc02014ec <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201506:	2581                	sext.w	a1,a1
ffffffffc0201508:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020150a:	4789                	li	a5,2
ffffffffc020150c:	00850713          	addi	a4,a0,8
ffffffffc0201510:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201514:	00010697          	auipc	a3,0x10
ffffffffc0201518:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0211040 <free_area>
ffffffffc020151c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020151e:	669c                	ld	a5,8(a3)
ffffffffc0201520:	9f2d                	addw	a4,a4,a1
ffffffffc0201522:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201524:	04d78663          	beq	a5,a3,ffffffffc0201570 <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201528:	fe078713          	addi	a4,a5,-32
ffffffffc020152c:	4581                	li	a1,0
ffffffffc020152e:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0201532:	00e56a63          	bltu	a0,a4,ffffffffc0201546 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201536:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201538:	02d70263          	beq	a4,a3,ffffffffc020155c <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc020153c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020153e:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0201542:	fee57ae3          	bgeu	a0,a4,ffffffffc0201536 <default_init_memmap+0x60>
ffffffffc0201546:	c199                	beqz	a1,ffffffffc020154c <default_init_memmap+0x76>
ffffffffc0201548:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020154c:	6398                	ld	a4,0(a5)
}
ffffffffc020154e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201550:	e390                	sd	a2,0(a5)
ffffffffc0201552:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201554:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0201556:	f118                	sd	a4,32(a0)
ffffffffc0201558:	0141                	addi	sp,sp,16
ffffffffc020155a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020155c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020155e:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0201560:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201562:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc0201564:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201566:	00d70e63          	beq	a4,a3,ffffffffc0201582 <default_init_memmap+0xac>
ffffffffc020156a:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020156c:	87ba                	mv	a5,a4
ffffffffc020156e:	bfc1                	j	ffffffffc020153e <default_init_memmap+0x68>
}
ffffffffc0201570:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201572:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc0201576:	e398                	sd	a4,0(a5)
ffffffffc0201578:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020157a:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020157c:	f11c                	sd	a5,32(a0)
}
ffffffffc020157e:	0141                	addi	sp,sp,16
ffffffffc0201580:	8082                	ret
ffffffffc0201582:	60a2                	ld	ra,8(sp)
ffffffffc0201584:	e290                	sd	a2,0(a3)
ffffffffc0201586:	0141                	addi	sp,sp,16
ffffffffc0201588:	8082                	ret
        assert(PageReserved(p));
ffffffffc020158a:	00004697          	auipc	a3,0x4
ffffffffc020158e:	c2668693          	addi	a3,a3,-986 # ffffffffc02051b0 <etext+0xc60>
ffffffffc0201592:	00004617          	auipc	a2,0x4
ffffffffc0201596:	89660613          	addi	a2,a2,-1898 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020159a:	04900593          	li	a1,73
ffffffffc020159e:	00004517          	auipc	a0,0x4
ffffffffc02015a2:	8a250513          	addi	a0,a0,-1886 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02015a6:	dbbfe0ef          	jal	ffffffffc0200360 <__panic>
    assert(n > 0);
ffffffffc02015aa:	00004697          	auipc	a3,0x4
ffffffffc02015ae:	bd668693          	addi	a3,a3,-1066 # ffffffffc0205180 <etext+0xc30>
ffffffffc02015b2:	00004617          	auipc	a2,0x4
ffffffffc02015b6:	87660613          	addi	a2,a2,-1930 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02015ba:	04600593          	li	a1,70
ffffffffc02015be:	00004517          	auipc	a0,0x4
ffffffffc02015c2:	88250513          	addi	a0,a0,-1918 # ffffffffc0204e40 <etext+0x8f0>
ffffffffc02015c6:	d9bfe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02015ca <pa2page.part.0>:
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc02015ca:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02015cc:	00004617          	auipc	a2,0x4
ffffffffc02015d0:	c0c60613          	addi	a2,a2,-1012 # ffffffffc02051d8 <etext+0xc88>
ffffffffc02015d4:	06500593          	li	a1,101
ffffffffc02015d8:	00004517          	auipc	a0,0x4
ffffffffc02015dc:	c2050513          	addi	a0,a0,-992 # ffffffffc02051f8 <etext+0xca8>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc02015e0:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc02015e2:	d7ffe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02015e6 <pte2page.part.0>:
static inline struct Page *pte2page(pte_t pte) {
ffffffffc02015e6:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc02015e8:	00004617          	auipc	a2,0x4
ffffffffc02015ec:	c2060613          	addi	a2,a2,-992 # ffffffffc0205208 <etext+0xcb8>
ffffffffc02015f0:	07000593          	li	a1,112
ffffffffc02015f4:	00004517          	auipc	a0,0x4
ffffffffc02015f8:	c0450513          	addi	a0,a0,-1020 # ffffffffc02051f8 <etext+0xca8>
static inline struct Page *pte2page(pte_t pte) {
ffffffffc02015fc:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc02015fe:	d63fe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0201602 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201602:	7139                	addi	sp,sp,-64
ffffffffc0201604:	f426                	sd	s1,40(sp)
ffffffffc0201606:	f04a                	sd	s2,32(sp)
ffffffffc0201608:	ec4e                	sd	s3,24(sp)
ffffffffc020160a:	e852                	sd	s4,16(sp)
ffffffffc020160c:	e456                	sd	s5,8(sp)
ffffffffc020160e:	e05a                	sd	s6,0(sp)
ffffffffc0201610:	fc06                	sd	ra,56(sp)
ffffffffc0201612:	f822                	sd	s0,48(sp)
ffffffffc0201614:	84aa                	mv	s1,a0
ffffffffc0201616:	00010917          	auipc	s2,0x10
ffffffffc020161a:	f0290913          	addi	s2,s2,-254 # ffffffffc0211518 <pmm_manager>
    while (1) {
        local_intr_save(intr_flag);
        { page = pmm_manager->alloc_pages(n); }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc020161e:	4a05                	li	s4,1
ffffffffc0201620:	00010a97          	auipc	s5,0x10
ffffffffc0201624:	f28a8a93          	addi	s5,s5,-216 # ffffffffc0211548 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201628:	0005099b          	sext.w	s3,a0
ffffffffc020162c:	00010b17          	auipc	s6,0x10
ffffffffc0201630:	f44b0b13          	addi	s6,s6,-188 # ffffffffc0211570 <check_mm_struct>
ffffffffc0201634:	a015                	j	ffffffffc0201658 <alloc_pages+0x56>
        { page = pmm_manager->alloc_pages(n); }
ffffffffc0201636:	00093783          	ld	a5,0(s2)
ffffffffc020163a:	6f9c                	ld	a5,24(a5)
ffffffffc020163c:	9782                	jalr	a5
ffffffffc020163e:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0201640:	4601                	li	a2,0
ffffffffc0201642:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201644:	ec05                	bnez	s0,ffffffffc020167c <alloc_pages+0x7a>
ffffffffc0201646:	029a6b63          	bltu	s4,s1,ffffffffc020167c <alloc_pages+0x7a>
ffffffffc020164a:	000aa783          	lw	a5,0(s5)
ffffffffc020164e:	c79d                	beqz	a5,ffffffffc020167c <alloc_pages+0x7a>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201650:	000b3503          	ld	a0,0(s6)
ffffffffc0201654:	233010ef          	jal	ffffffffc0203086 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201658:	100027f3          	csrr	a5,sstatus
ffffffffc020165c:	8b89                	andi	a5,a5,2
        { page = pmm_manager->alloc_pages(n); }
ffffffffc020165e:	8526                	mv	a0,s1
ffffffffc0201660:	dbf9                	beqz	a5,ffffffffc0201636 <alloc_pages+0x34>
        intr_disable();
ffffffffc0201662:	e7bfe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0201666:	00093783          	ld	a5,0(s2)
ffffffffc020166a:	8526                	mv	a0,s1
ffffffffc020166c:	6f9c                	ld	a5,24(a5)
ffffffffc020166e:	9782                	jalr	a5
ffffffffc0201670:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201672:	e65fe0ef          	jal	ffffffffc02004d6 <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201676:	4601                	li	a2,0
ffffffffc0201678:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc020167a:	d471                	beqz	s0,ffffffffc0201646 <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc020167c:	70e2                	ld	ra,56(sp)
ffffffffc020167e:	8522                	mv	a0,s0
ffffffffc0201680:	7442                	ld	s0,48(sp)
ffffffffc0201682:	74a2                	ld	s1,40(sp)
ffffffffc0201684:	7902                	ld	s2,32(sp)
ffffffffc0201686:	69e2                	ld	s3,24(sp)
ffffffffc0201688:	6a42                	ld	s4,16(sp)
ffffffffc020168a:	6aa2                	ld	s5,8(sp)
ffffffffc020168c:	6b02                	ld	s6,0(sp)
ffffffffc020168e:	6121                	addi	sp,sp,64
ffffffffc0201690:	8082                	ret

ffffffffc0201692 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201692:	100027f3          	csrr	a5,sstatus
ffffffffc0201696:	8b89                	andi	a5,a5,2
ffffffffc0201698:	e799                	bnez	a5,ffffffffc02016a6 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;

    local_intr_save(intr_flag);
    { pmm_manager->free_pages(base, n); }
ffffffffc020169a:	00010797          	auipc	a5,0x10
ffffffffc020169e:	e7e7b783          	ld	a5,-386(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc02016a2:	739c                	ld	a5,32(a5)
ffffffffc02016a4:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02016a6:	1101                	addi	sp,sp,-32
ffffffffc02016a8:	ec06                	sd	ra,24(sp)
ffffffffc02016aa:	e822                	sd	s0,16(sp)
ffffffffc02016ac:	e426                	sd	s1,8(sp)
ffffffffc02016ae:	842a                	mv	s0,a0
ffffffffc02016b0:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02016b2:	e2bfe0ef          	jal	ffffffffc02004dc <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc02016b6:	00010797          	auipc	a5,0x10
ffffffffc02016ba:	e627b783          	ld	a5,-414(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc02016be:	739c                	ld	a5,32(a5)
ffffffffc02016c0:	85a6                	mv	a1,s1
ffffffffc02016c2:	8522                	mv	a0,s0
ffffffffc02016c4:	9782                	jalr	a5
    local_intr_restore(intr_flag);
}
ffffffffc02016c6:	6442                	ld	s0,16(sp)
ffffffffc02016c8:	60e2                	ld	ra,24(sp)
ffffffffc02016ca:	64a2                	ld	s1,8(sp)
ffffffffc02016cc:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02016ce:	e09fe06f          	j	ffffffffc02004d6 <intr_enable>

ffffffffc02016d2 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016d2:	100027f3          	csrr	a5,sstatus
ffffffffc02016d6:	8b89                	andi	a5,a5,2
ffffffffc02016d8:	e799                	bnez	a5,ffffffffc02016e6 <nr_free_pages+0x14>
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02016da:	00010797          	auipc	a5,0x10
ffffffffc02016de:	e3e7b783          	ld	a5,-450(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc02016e2:	779c                	ld	a5,40(a5)
ffffffffc02016e4:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02016e6:	1141                	addi	sp,sp,-16
ffffffffc02016e8:	e406                	sd	ra,8(sp)
ffffffffc02016ea:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02016ec:	df1fe0ef          	jal	ffffffffc02004dc <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02016f0:	00010797          	auipc	a5,0x10
ffffffffc02016f4:	e287b783          	ld	a5,-472(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc02016f8:	779c                	ld	a5,40(a5)
ffffffffc02016fa:	9782                	jalr	a5
ffffffffc02016fc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02016fe:	dd9fe0ef          	jal	ffffffffc02004d6 <intr_enable>
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201702:	60a2                	ld	ra,8(sp)
ffffffffc0201704:	8522                	mv	a0,s0
ffffffffc0201706:	6402                	ld	s0,0(sp)
ffffffffc0201708:	0141                	addi	sp,sp,16
ffffffffc020170a:	8082                	ret

ffffffffc020170c <get_pte>:
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020170c:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201710:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201714:	715d                	addi	sp,sp,-80
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201716:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201718:	f052                	sd	s4,32(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020171a:	00f50a33          	add	s4,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc020171e:	000a3683          	ld	a3,0(s4)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201722:	f84a                	sd	s2,48(sp)
ffffffffc0201724:	f44e                	sd	s3,40(sp)
ffffffffc0201726:	ec56                	sd	s5,24(sp)
ffffffffc0201728:	e486                	sd	ra,72(sp)
ffffffffc020172a:	e0a2                	sd	s0,64(sp)
ffffffffc020172c:	e85a                	sd	s6,16(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc020172e:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201732:	892e                	mv	s2,a1
ffffffffc0201734:	8ab2                	mv	s5,a2
ffffffffc0201736:	00010997          	auipc	s3,0x10
ffffffffc020173a:	e0298993          	addi	s3,s3,-510 # ffffffffc0211538 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc020173e:	efc1                	bnez	a5,ffffffffc02017d6 <get_pte+0xca>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201740:	18060663          	beqz	a2,ffffffffc02018cc <get_pte+0x1c0>
ffffffffc0201744:	4505                	li	a0,1
ffffffffc0201746:	ebdff0ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc020174a:	842a                	mv	s0,a0
ffffffffc020174c:	18050063          	beqz	a0,ffffffffc02018cc <get_pte+0x1c0>
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201750:	fc26                	sd	s1,56(sp)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201752:	f8e394b7          	lui	s1,0xf8e39
ffffffffc0201756:	e3948493          	addi	s1,s1,-455 # fffffffff8e38e39 <end+0x38c278c1>
ffffffffc020175a:	e45e                	sd	s7,8(sp)
ffffffffc020175c:	04b2                	slli	s1,s1,0xc
ffffffffc020175e:	00010b97          	auipc	s7,0x10
ffffffffc0201762:	de2b8b93          	addi	s7,s7,-542 # ffffffffc0211540 <pages>
ffffffffc0201766:	000bb503          	ld	a0,0(s7)
ffffffffc020176a:	e3948493          	addi	s1,s1,-455
ffffffffc020176e:	04b2                	slli	s1,s1,0xc
ffffffffc0201770:	e3948493          	addi	s1,s1,-455
ffffffffc0201774:	40a40533          	sub	a0,s0,a0
ffffffffc0201778:	04b2                	slli	s1,s1,0xc
ffffffffc020177a:	850d                	srai	a0,a0,0x3
ffffffffc020177c:	e3948493          	addi	s1,s1,-455
ffffffffc0201780:	02950533          	mul	a0,a0,s1
ffffffffc0201784:	00080b37          	lui	s6,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201788:	00010997          	auipc	s3,0x10
ffffffffc020178c:	db098993          	addi	s3,s3,-592 # ffffffffc0211538 <npage>
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201790:	4785                	li	a5,1
ffffffffc0201792:	0009b703          	ld	a4,0(s3)
ffffffffc0201796:	c01c                	sw	a5,0(s0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201798:	955a                	add	a0,a0,s6
ffffffffc020179a:	00c51793          	slli	a5,a0,0xc
ffffffffc020179e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02017a0:	0532                	slli	a0,a0,0xc
ffffffffc02017a2:	16e7ff63          	bgeu	a5,a4,ffffffffc0201920 <get_pte+0x214>
ffffffffc02017a6:	00010797          	auipc	a5,0x10
ffffffffc02017aa:	d8a7b783          	ld	a5,-630(a5) # ffffffffc0211530 <va_pa_offset>
ffffffffc02017ae:	953e                	add	a0,a0,a5
ffffffffc02017b0:	6605                	lui	a2,0x1
ffffffffc02017b2:	4581                	li	a1,0
ffffffffc02017b4:	573020ef          	jal	ffffffffc0204526 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017b8:	000bb783          	ld	a5,0(s7)
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02017bc:	6ba2                	ld	s7,8(sp)
ffffffffc02017be:	40f406b3          	sub	a3,s0,a5
ffffffffc02017c2:	868d                	srai	a3,a3,0x3
ffffffffc02017c4:	029686b3          	mul	a3,a3,s1
ffffffffc02017c8:	74e2                	ld	s1,56(sp)
ffffffffc02017ca:	96da                	add	a3,a3,s6

static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02017cc:	06aa                	slli	a3,a3,0xa
ffffffffc02017ce:	0116e693          	ori	a3,a3,17
ffffffffc02017d2:	00da3023          	sd	a3,0(s4)
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02017d6:	77fd                	lui	a5,0xfffff
ffffffffc02017d8:	068a                	slli	a3,a3,0x2
ffffffffc02017da:	0009b703          	ld	a4,0(s3)
ffffffffc02017de:	8efd                	and	a3,a3,a5
ffffffffc02017e0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02017e4:	0ee7f663          	bgeu	a5,a4,ffffffffc02018d0 <get_pte+0x1c4>
ffffffffc02017e8:	00010b17          	auipc	s6,0x10
ffffffffc02017ec:	d48b0b13          	addi	s6,s6,-696 # ffffffffc0211530 <va_pa_offset>
ffffffffc02017f0:	000b3603          	ld	a2,0(s6)
ffffffffc02017f4:	01595793          	srli	a5,s2,0x15
ffffffffc02017f8:	1ff7f793          	andi	a5,a5,511
ffffffffc02017fc:	96b2                	add	a3,a3,a2
ffffffffc02017fe:	078e                	slli	a5,a5,0x3
ffffffffc0201800:	00f68433          	add	s0,a3,a5
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201804:	6014                	ld	a3,0(s0)
ffffffffc0201806:	0016f793          	andi	a5,a3,1
ffffffffc020180a:	e7d1                	bnez	a5,ffffffffc0201896 <get_pte+0x18a>
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
ffffffffc020180c:	0c0a8063          	beqz	s5,ffffffffc02018cc <get_pte+0x1c0>
ffffffffc0201810:	4505                	li	a0,1
ffffffffc0201812:	fc26                	sd	s1,56(sp)
ffffffffc0201814:	defff0ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0201818:	84aa                	mv	s1,a0
ffffffffc020181a:	c945                	beqz	a0,ffffffffc02018ca <get_pte+0x1be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020181c:	f8e39a37          	lui	s4,0xf8e39
ffffffffc0201820:	e39a0a13          	addi	s4,s4,-455 # fffffffff8e38e39 <end+0x38c278c1>
ffffffffc0201824:	e45e                	sd	s7,8(sp)
ffffffffc0201826:	0a32                	slli	s4,s4,0xc
ffffffffc0201828:	00010b97          	auipc	s7,0x10
ffffffffc020182c:	d18b8b93          	addi	s7,s7,-744 # ffffffffc0211540 <pages>
ffffffffc0201830:	000bb683          	ld	a3,0(s7)
ffffffffc0201834:	e39a0a13          	addi	s4,s4,-455
ffffffffc0201838:	0a32                	slli	s4,s4,0xc
ffffffffc020183a:	e39a0a13          	addi	s4,s4,-455
ffffffffc020183e:	40d506b3          	sub	a3,a0,a3
ffffffffc0201842:	0a32                	slli	s4,s4,0xc
ffffffffc0201844:	868d                	srai	a3,a3,0x3
ffffffffc0201846:	e39a0a13          	addi	s4,s4,-455
ffffffffc020184a:	034686b3          	mul	a3,a3,s4
ffffffffc020184e:	00080ab7          	lui	s5,0x80
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201852:	4785                	li	a5,1
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201854:	0009b703          	ld	a4,0(s3)
ffffffffc0201858:	c11c                	sw	a5,0(a0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020185a:	96d6                	add	a3,a3,s5
ffffffffc020185c:	00c69793          	slli	a5,a3,0xc
ffffffffc0201860:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201862:	06b2                	slli	a3,a3,0xc
ffffffffc0201864:	0ae7f263          	bgeu	a5,a4,ffffffffc0201908 <get_pte+0x1fc>
ffffffffc0201868:	000b3503          	ld	a0,0(s6)
ffffffffc020186c:	6605                	lui	a2,0x1
ffffffffc020186e:	4581                	li	a1,0
ffffffffc0201870:	9536                	add	a0,a0,a3
ffffffffc0201872:	4b5020ef          	jal	ffffffffc0204526 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201876:	000bb783          	ld	a5,0(s7)
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020187a:	6ba2                	ld	s7,8(sp)
ffffffffc020187c:	40f486b3          	sub	a3,s1,a5
ffffffffc0201880:	868d                	srai	a3,a3,0x3
ffffffffc0201882:	034686b3          	mul	a3,a3,s4
ffffffffc0201886:	74e2                	ld	s1,56(sp)
ffffffffc0201888:	96d6                	add	a3,a3,s5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020188a:	06aa                	slli	a3,a3,0xa
ffffffffc020188c:	0116e693          	ori	a3,a3,17
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201890:	e014                	sd	a3,0(s0)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201892:	0009b703          	ld	a4,0(s3)
ffffffffc0201896:	77fd                	lui	a5,0xfffff
ffffffffc0201898:	068a                	slli	a3,a3,0x2
ffffffffc020189a:	8efd                	and	a3,a3,a5
ffffffffc020189c:	00c6d793          	srli	a5,a3,0xc
ffffffffc02018a0:	04e7f663          	bgeu	a5,a4,ffffffffc02018ec <get_pte+0x1e0>
ffffffffc02018a4:	000b3783          	ld	a5,0(s6)
ffffffffc02018a8:	00c95913          	srli	s2,s2,0xc
ffffffffc02018ac:	1ff97913          	andi	s2,s2,511
ffffffffc02018b0:	96be                	add	a3,a3,a5
ffffffffc02018b2:	090e                	slli	s2,s2,0x3
ffffffffc02018b4:	01268533          	add	a0,a3,s2
}
ffffffffc02018b8:	60a6                	ld	ra,72(sp)
ffffffffc02018ba:	6406                	ld	s0,64(sp)
ffffffffc02018bc:	7942                	ld	s2,48(sp)
ffffffffc02018be:	79a2                	ld	s3,40(sp)
ffffffffc02018c0:	7a02                	ld	s4,32(sp)
ffffffffc02018c2:	6ae2                	ld	s5,24(sp)
ffffffffc02018c4:	6b42                	ld	s6,16(sp)
ffffffffc02018c6:	6161                	addi	sp,sp,80
ffffffffc02018c8:	8082                	ret
ffffffffc02018ca:	74e2                	ld	s1,56(sp)
            return NULL;
ffffffffc02018cc:	4501                	li	a0,0
ffffffffc02018ce:	b7ed                	j	ffffffffc02018b8 <get_pte+0x1ac>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02018d0:	00004617          	auipc	a2,0x4
ffffffffc02018d4:	96060613          	addi	a2,a2,-1696 # ffffffffc0205230 <etext+0xce0>
ffffffffc02018d8:	10200593          	li	a1,258
ffffffffc02018dc:	00004517          	auipc	a0,0x4
ffffffffc02018e0:	97c50513          	addi	a0,a0,-1668 # ffffffffc0205258 <etext+0xd08>
ffffffffc02018e4:	fc26                	sd	s1,56(sp)
ffffffffc02018e6:	e45e                	sd	s7,8(sp)
ffffffffc02018e8:	a79fe0ef          	jal	ffffffffc0200360 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02018ec:	00004617          	auipc	a2,0x4
ffffffffc02018f0:	94460613          	addi	a2,a2,-1724 # ffffffffc0205230 <etext+0xce0>
ffffffffc02018f4:	10f00593          	li	a1,271
ffffffffc02018f8:	00004517          	auipc	a0,0x4
ffffffffc02018fc:	96050513          	addi	a0,a0,-1696 # ffffffffc0205258 <etext+0xd08>
ffffffffc0201900:	fc26                	sd	s1,56(sp)
ffffffffc0201902:	e45e                	sd	s7,8(sp)
ffffffffc0201904:	a5dfe0ef          	jal	ffffffffc0200360 <__panic>
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201908:	00004617          	auipc	a2,0x4
ffffffffc020190c:	92860613          	addi	a2,a2,-1752 # ffffffffc0205230 <etext+0xce0>
ffffffffc0201910:	10b00593          	li	a1,267
ffffffffc0201914:	00004517          	auipc	a0,0x4
ffffffffc0201918:	94450513          	addi	a0,a0,-1724 # ffffffffc0205258 <etext+0xd08>
ffffffffc020191c:	a45fe0ef          	jal	ffffffffc0200360 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201920:	86aa                	mv	a3,a0
ffffffffc0201922:	00004617          	auipc	a2,0x4
ffffffffc0201926:	90e60613          	addi	a2,a2,-1778 # ffffffffc0205230 <etext+0xce0>
ffffffffc020192a:	0ff00593          	li	a1,255
ffffffffc020192e:	00004517          	auipc	a0,0x4
ffffffffc0201932:	92a50513          	addi	a0,a0,-1750 # ffffffffc0205258 <etext+0xd08>
ffffffffc0201936:	a2bfe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020193a <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc020193a:	1141                	addi	sp,sp,-16
ffffffffc020193c:	e022                	sd	s0,0(sp)
ffffffffc020193e:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201940:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201942:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201944:	dc9ff0ef          	jal	ffffffffc020170c <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201948:	c011                	beqz	s0,ffffffffc020194c <get_page+0x12>
        *ptep_store = ptep;
ffffffffc020194a:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020194c:	c511                	beqz	a0,ffffffffc0201958 <get_page+0x1e>
ffffffffc020194e:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201950:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201952:	0017f713          	andi	a4,a5,1
ffffffffc0201956:	e709                	bnez	a4,ffffffffc0201960 <get_page+0x26>
}
ffffffffc0201958:	60a2                	ld	ra,8(sp)
ffffffffc020195a:	6402                	ld	s0,0(sp)
ffffffffc020195c:	0141                	addi	sp,sp,16
ffffffffc020195e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201960:	078a                	slli	a5,a5,0x2
ffffffffc0201962:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201964:	00010717          	auipc	a4,0x10
ffffffffc0201968:	bd473703          	ld	a4,-1068(a4) # ffffffffc0211538 <npage>
ffffffffc020196c:	02e7f263          	bgeu	a5,a4,ffffffffc0201990 <get_page+0x56>
    return &pages[PPN(pa) - nbase];
ffffffffc0201970:	fff80737          	lui	a4,0xfff80
ffffffffc0201974:	97ba                	add	a5,a5,a4
ffffffffc0201976:	60a2                	ld	ra,8(sp)
ffffffffc0201978:	6402                	ld	s0,0(sp)
ffffffffc020197a:	00379713          	slli	a4,a5,0x3
ffffffffc020197e:	97ba                	add	a5,a5,a4
ffffffffc0201980:	00010517          	auipc	a0,0x10
ffffffffc0201984:	bc053503          	ld	a0,-1088(a0) # ffffffffc0211540 <pages>
ffffffffc0201988:	078e                	slli	a5,a5,0x3
ffffffffc020198a:	953e                	add	a0,a0,a5
ffffffffc020198c:	0141                	addi	sp,sp,16
ffffffffc020198e:	8082                	ret
ffffffffc0201990:	c3bff0ef          	jal	ffffffffc02015ca <pa2page.part.0>

ffffffffc0201994 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201994:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201996:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201998:	ec06                	sd	ra,24(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020199a:	d73ff0ef          	jal	ffffffffc020170c <get_pte>
    if (ptep != NULL) {
ffffffffc020199e:	c901                	beqz	a0,ffffffffc02019ae <page_remove+0x1a>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc02019a0:	611c                	ld	a5,0(a0)
ffffffffc02019a2:	e822                	sd	s0,16(sp)
ffffffffc02019a4:	842a                	mv	s0,a0
ffffffffc02019a6:	0017f713          	andi	a4,a5,1
ffffffffc02019aa:	e709                	bnez	a4,ffffffffc02019b4 <page_remove+0x20>
ffffffffc02019ac:	6442                	ld	s0,16(sp)
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc02019ae:	60e2                	ld	ra,24(sp)
ffffffffc02019b0:	6105                	addi	sp,sp,32
ffffffffc02019b2:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02019b4:	078a                	slli	a5,a5,0x2
ffffffffc02019b6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02019b8:	00010717          	auipc	a4,0x10
ffffffffc02019bc:	b8073703          	ld	a4,-1152(a4) # ffffffffc0211538 <npage>
ffffffffc02019c0:	06e7f563          	bgeu	a5,a4,ffffffffc0201a2a <page_remove+0x96>
    return &pages[PPN(pa) - nbase];
ffffffffc02019c4:	fff80737          	lui	a4,0xfff80
ffffffffc02019c8:	97ba                	add	a5,a5,a4
ffffffffc02019ca:	00379713          	slli	a4,a5,0x3
ffffffffc02019ce:	97ba                	add	a5,a5,a4
ffffffffc02019d0:	078e                	slli	a5,a5,0x3
ffffffffc02019d2:	00010517          	auipc	a0,0x10
ffffffffc02019d6:	b6e53503          	ld	a0,-1170(a0) # ffffffffc0211540 <pages>
ffffffffc02019da:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02019dc:	411c                	lw	a5,0(a0)
ffffffffc02019de:	fff7871b          	addiw	a4,a5,-1 # ffffffffffffefff <end+0x3fdeda87>
ffffffffc02019e2:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02019e4:	cb09                	beqz	a4,ffffffffc02019f6 <page_remove+0x62>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc02019e6:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc02019ea:	12000073          	sfence.vma
ffffffffc02019ee:	6442                	ld	s0,16(sp)
}
ffffffffc02019f0:	60e2                	ld	ra,24(sp)
ffffffffc02019f2:	6105                	addi	sp,sp,32
ffffffffc02019f4:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019f6:	100027f3          	csrr	a5,sstatus
ffffffffc02019fa:	8b89                	andi	a5,a5,2
ffffffffc02019fc:	eb89                	bnez	a5,ffffffffc0201a0e <page_remove+0x7a>
    { pmm_manager->free_pages(base, n); }
ffffffffc02019fe:	00010797          	auipc	a5,0x10
ffffffffc0201a02:	b1a7b783          	ld	a5,-1254(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc0201a06:	739c                	ld	a5,32(a5)
ffffffffc0201a08:	4585                	li	a1,1
ffffffffc0201a0a:	9782                	jalr	a5
    if (flag) {
ffffffffc0201a0c:	bfe9                	j	ffffffffc02019e6 <page_remove+0x52>
        intr_disable();
ffffffffc0201a0e:	e42a                	sd	a0,8(sp)
ffffffffc0201a10:	acdfe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0201a14:	00010797          	auipc	a5,0x10
ffffffffc0201a18:	b047b783          	ld	a5,-1276(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc0201a1c:	739c                	ld	a5,32(a5)
ffffffffc0201a1e:	6522                	ld	a0,8(sp)
ffffffffc0201a20:	4585                	li	a1,1
ffffffffc0201a22:	9782                	jalr	a5
        intr_enable();
ffffffffc0201a24:	ab3fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0201a28:	bf7d                	j	ffffffffc02019e6 <page_remove+0x52>
ffffffffc0201a2a:	ba1ff0ef          	jal	ffffffffc02015ca <pa2page.part.0>

ffffffffc0201a2e <page_insert>:
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201a2e:	7179                	addi	sp,sp,-48
ffffffffc0201a30:	87b2                	mv	a5,a2
ffffffffc0201a32:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a34:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201a36:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a38:	85be                	mv	a1,a5
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201a3a:	ec26                	sd	s1,24(sp)
ffffffffc0201a3c:	f406                	sd	ra,40(sp)
ffffffffc0201a3e:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a40:	ccdff0ef          	jal	ffffffffc020170c <get_pte>
    if (ptep == NULL) {
ffffffffc0201a44:	c975                	beqz	a0,ffffffffc0201b38 <page_insert+0x10a>
    page->ref += 1;
ffffffffc0201a46:	4014                	lw	a3,0(s0)
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V) {
ffffffffc0201a48:	611c                	ld	a5,0(a0)
ffffffffc0201a4a:	e44e                	sd	s3,8(sp)
ffffffffc0201a4c:	0016871b          	addiw	a4,a3,1
ffffffffc0201a50:	c018                	sw	a4,0(s0)
ffffffffc0201a52:	0017f713          	andi	a4,a5,1
ffffffffc0201a56:	89aa                	mv	s3,a0
ffffffffc0201a58:	eb21                	bnez	a4,ffffffffc0201aa8 <page_insert+0x7a>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a5a:	00010717          	auipc	a4,0x10
ffffffffc0201a5e:	ae673703          	ld	a4,-1306(a4) # ffffffffc0211540 <pages>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201a62:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0201a66:	e3978793          	addi	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c1>
ffffffffc0201a6a:	07b2                	slli	a5,a5,0xc
ffffffffc0201a6c:	e3978793          	addi	a5,a5,-455
ffffffffc0201a70:	07b2                	slli	a5,a5,0xc
ffffffffc0201a72:	e3978793          	addi	a5,a5,-455
ffffffffc0201a76:	8c19                	sub	s0,s0,a4
ffffffffc0201a78:	07b2                	slli	a5,a5,0xc
ffffffffc0201a7a:	840d                	srai	s0,s0,0x3
ffffffffc0201a7c:	e3978793          	addi	a5,a5,-455
ffffffffc0201a80:	02f407b3          	mul	a5,s0,a5
ffffffffc0201a84:	00080737          	lui	a4,0x80
ffffffffc0201a88:	97ba                	add	a5,a5,a4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201a8a:	07aa                	slli	a5,a5,0xa
ffffffffc0201a8c:	8cdd                	or	s1,s1,a5
ffffffffc0201a8e:	0014e493          	ori	s1,s1,1
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0201a92:	0099b023          	sd	s1,0(s3)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201a96:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);
    return 0;
ffffffffc0201a9a:	69a2                	ld	s3,8(sp)
ffffffffc0201a9c:	4501                	li	a0,0
}
ffffffffc0201a9e:	70a2                	ld	ra,40(sp)
ffffffffc0201aa0:	7402                	ld	s0,32(sp)
ffffffffc0201aa2:	64e2                	ld	s1,24(sp)
ffffffffc0201aa4:	6145                	addi	sp,sp,48
ffffffffc0201aa6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201aa8:	078a                	slli	a5,a5,0x2
ffffffffc0201aaa:	e84a                	sd	s2,16(sp)
ffffffffc0201aac:	e052                	sd	s4,0(sp)
ffffffffc0201aae:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201ab0:	00010717          	auipc	a4,0x10
ffffffffc0201ab4:	a8873703          	ld	a4,-1400(a4) # ffffffffc0211538 <npage>
ffffffffc0201ab8:	08e7f263          	bgeu	a5,a4,ffffffffc0201b3c <page_insert+0x10e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201abc:	fff80737          	lui	a4,0xfff80
ffffffffc0201ac0:	97ba                	add	a5,a5,a4
ffffffffc0201ac2:	00010a17          	auipc	s4,0x10
ffffffffc0201ac6:	a7ea0a13          	addi	s4,s4,-1410 # ffffffffc0211540 <pages>
ffffffffc0201aca:	000a3703          	ld	a4,0(s4)
ffffffffc0201ace:	00379913          	slli	s2,a5,0x3
ffffffffc0201ad2:	993e                	add	s2,s2,a5
ffffffffc0201ad4:	090e                	slli	s2,s2,0x3
ffffffffc0201ad6:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0201ad8:	03240263          	beq	s0,s2,ffffffffc0201afc <page_insert+0xce>
    page->ref -= 1;
ffffffffc0201adc:	00092783          	lw	a5,0(s2)
ffffffffc0201ae0:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201ae4:	00e92023          	sw	a4,0(s2)
        if (page_ref(page) ==
ffffffffc0201ae8:	cf11                	beqz	a4,ffffffffc0201b04 <page_insert+0xd6>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201aea:	0009b023          	sd	zero,0(s3)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201aee:	12000073          	sfence.vma
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201af2:	000a3703          	ld	a4,0(s4)
ffffffffc0201af6:	6942                	ld	s2,16(sp)
ffffffffc0201af8:	6a02                	ld	s4,0(sp)
}
ffffffffc0201afa:	b7a5                	j	ffffffffc0201a62 <page_insert+0x34>
    return page->ref;
ffffffffc0201afc:	6942                	ld	s2,16(sp)
ffffffffc0201afe:	6a02                	ld	s4,0(sp)
    page->ref -= 1;
ffffffffc0201b00:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201b02:	b785                	j	ffffffffc0201a62 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b04:	100027f3          	csrr	a5,sstatus
ffffffffc0201b08:	8b89                	andi	a5,a5,2
ffffffffc0201b0a:	eb91                	bnez	a5,ffffffffc0201b1e <page_insert+0xf0>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201b0c:	00010797          	auipc	a5,0x10
ffffffffc0201b10:	a0c7b783          	ld	a5,-1524(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc0201b14:	739c                	ld	a5,32(a5)
ffffffffc0201b16:	4585                	li	a1,1
ffffffffc0201b18:	854a                	mv	a0,s2
ffffffffc0201b1a:	9782                	jalr	a5
    if (flag) {
ffffffffc0201b1c:	b7f9                	j	ffffffffc0201aea <page_insert+0xbc>
        intr_disable();
ffffffffc0201b1e:	9bffe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0201b22:	00010797          	auipc	a5,0x10
ffffffffc0201b26:	9f67b783          	ld	a5,-1546(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc0201b2a:	739c                	ld	a5,32(a5)
ffffffffc0201b2c:	4585                	li	a1,1
ffffffffc0201b2e:	854a                	mv	a0,s2
ffffffffc0201b30:	9782                	jalr	a5
        intr_enable();
ffffffffc0201b32:	9a5fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0201b36:	bf55                	j	ffffffffc0201aea <page_insert+0xbc>
        return -E_NO_MEM;
ffffffffc0201b38:	5571                	li	a0,-4
ffffffffc0201b3a:	b795                	j	ffffffffc0201a9e <page_insert+0x70>
ffffffffc0201b3c:	a8fff0ef          	jal	ffffffffc02015ca <pa2page.part.0>

ffffffffc0201b40 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201b40:	00004797          	auipc	a5,0x4
ffffffffc0201b44:	69878793          	addi	a5,a5,1688 # ffffffffc02061d8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b48:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201b4a:	7159                	addi	sp,sp,-112
ffffffffc0201b4c:	f486                	sd	ra,104(sp)
ffffffffc0201b4e:	eca6                	sd	s1,88(sp)
ffffffffc0201b50:	e4ce                	sd	s3,72(sp)
ffffffffc0201b52:	f85a                	sd	s6,48(sp)
ffffffffc0201b54:	f45e                	sd	s7,40(sp)
ffffffffc0201b56:	f0a2                	sd	s0,96(sp)
ffffffffc0201b58:	e8ca                	sd	s2,80(sp)
ffffffffc0201b5a:	e0d2                	sd	s4,64(sp)
ffffffffc0201b5c:	fc56                	sd	s5,56(sp)
ffffffffc0201b5e:	f062                	sd	s8,32(sp)
ffffffffc0201b60:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201b62:	00010b97          	auipc	s7,0x10
ffffffffc0201b66:	9b6b8b93          	addi	s7,s7,-1610 # ffffffffc0211518 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b6a:	00003517          	auipc	a0,0x3
ffffffffc0201b6e:	6fe50513          	addi	a0,a0,1790 # ffffffffc0205268 <etext+0xd18>
    pmm_manager = &default_pmm_manager;
ffffffffc0201b72:	00fbb023          	sd	a5,0(s7)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b76:	d44fe0ef          	jal	ffffffffc02000ba <cprintf>
    pmm_manager->init();
ffffffffc0201b7a:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b7e:	00010997          	auipc	s3,0x10
ffffffffc0201b82:	9b298993          	addi	s3,s3,-1614 # ffffffffc0211530 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc0201b86:	00010497          	auipc	s1,0x10
ffffffffc0201b8a:	9b248493          	addi	s1,s1,-1614 # ffffffffc0211538 <npage>
    pmm_manager->init();
ffffffffc0201b8e:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201b90:	00010b17          	auipc	s6,0x10
ffffffffc0201b94:	9b0b0b13          	addi	s6,s6,-1616 # ffffffffc0211540 <pages>
    pmm_manager->init();
ffffffffc0201b98:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b9a:	57f5                	li	a5,-3
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b9c:	4645                	li	a2,17
ffffffffc0201b9e:	40100593          	li	a1,1025
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201ba2:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201ba4:	07e006b7          	lui	a3,0x7e00
ffffffffc0201ba8:	066e                	slli	a2,a2,0x1b
ffffffffc0201baa:	05d6                	slli	a1,a1,0x15
ffffffffc0201bac:	00003517          	auipc	a0,0x3
ffffffffc0201bb0:	6d450513          	addi	a0,a0,1748 # ffffffffc0205280 <etext+0xd30>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201bb4:	00f9b023          	sd	a5,0(s3)
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201bb8:	d02fe0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0201bbc:	00003517          	auipc	a0,0x3
ffffffffc0201bc0:	6f450513          	addi	a0,a0,1780 # ffffffffc02052b0 <etext+0xd60>
ffffffffc0201bc4:	cf6fe0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201bc8:	46c5                	li	a3,17
ffffffffc0201bca:	06ee                	slli	a3,a3,0x1b
ffffffffc0201bcc:	40100613          	li	a2,1025
ffffffffc0201bd0:	16fd                	addi	a3,a3,-1 # 7dfffff <kern_entry-0xffffffffb8400001>
ffffffffc0201bd2:	0656                	slli	a2,a2,0x15
ffffffffc0201bd4:	07e005b7          	lui	a1,0x7e00
ffffffffc0201bd8:	00003517          	auipc	a0,0x3
ffffffffc0201bdc:	6f050513          	addi	a0,a0,1776 # ffffffffc02052c8 <etext+0xd78>
ffffffffc0201be0:	cdafe0ef          	jal	ffffffffc02000ba <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201be4:	777d                	lui	a4,0xfffff
ffffffffc0201be6:	00011797          	auipc	a5,0x11
ffffffffc0201bea:	99178793          	addi	a5,a5,-1647 # ffffffffc0212577 <end+0xfff>
ffffffffc0201bee:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201bf0:	00088737          	lui	a4,0x88
ffffffffc0201bf4:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201bf6:	00fb3023          	sd	a5,0(s6)
ffffffffc0201bfa:	4705                	li	a4,1
ffffffffc0201bfc:	07a1                	addi	a5,a5,8
ffffffffc0201bfe:	40e7b02f          	amoor.d	zero,a4,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201c02:	04800693          	li	a3,72
ffffffffc0201c06:	4505                	li	a0,1
ffffffffc0201c08:	fff805b7          	lui	a1,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201c0c:	000b3783          	ld	a5,0(s6)
ffffffffc0201c10:	97b6                	add	a5,a5,a3
ffffffffc0201c12:	07a1                	addi	a5,a5,8
ffffffffc0201c14:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201c18:	609c                	ld	a5,0(s1)
ffffffffc0201c1a:	0705                	addi	a4,a4,1 # 88001 <kern_entry-0xffffffffc0177fff>
ffffffffc0201c1c:	04868693          	addi	a3,a3,72
ffffffffc0201c20:	00b78633          	add	a2,a5,a1
ffffffffc0201c24:	fec764e3          	bltu	a4,a2,ffffffffc0201c0c <pmm_init+0xcc>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201c28:	000b3503          	ld	a0,0(s6)
ffffffffc0201c2c:	00379693          	slli	a3,a5,0x3
ffffffffc0201c30:	96be                	add	a3,a3,a5
ffffffffc0201c32:	fdc00737          	lui	a4,0xfdc00
ffffffffc0201c36:	972a                	add	a4,a4,a0
ffffffffc0201c38:	068e                	slli	a3,a3,0x3
ffffffffc0201c3a:	96ba                	add	a3,a3,a4
ffffffffc0201c3c:	c0200737          	lui	a4,0xc0200
ffffffffc0201c40:	68e6e563          	bltu	a3,a4,ffffffffc02022ca <pmm_init+0x78a>
ffffffffc0201c44:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end) {
ffffffffc0201c48:	4645                	li	a2,17
ffffffffc0201c4a:	066e                	slli	a2,a2,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201c4c:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201c4e:	50c6e363          	bltu	a3,a2,ffffffffc0202154 <pmm_init+0x614>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201c52:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201c56:	00010917          	auipc	s2,0x10
ffffffffc0201c5a:	8d290913          	addi	s2,s2,-1838 # ffffffffc0211528 <boot_pgdir>
    pmm_manager->check();
ffffffffc0201c5e:	7b9c                	ld	a5,48(a5)
ffffffffc0201c60:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201c62:	00003517          	auipc	a0,0x3
ffffffffc0201c66:	6b650513          	addi	a0,a0,1718 # ffffffffc0205318 <etext+0xdc8>
ffffffffc0201c6a:	c50fe0ef          	jal	ffffffffc02000ba <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201c6e:	00007697          	auipc	a3,0x7
ffffffffc0201c72:	39268693          	addi	a3,a3,914 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc0201c76:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201c7a:	c02007b7          	lui	a5,0xc0200
ffffffffc0201c7e:	22f6eee3          	bltu	a3,a5,ffffffffc02026ba <pmm_init+0xb7a>
ffffffffc0201c82:	0009b783          	ld	a5,0(s3)
ffffffffc0201c86:	8e9d                	sub	a3,a3,a5
ffffffffc0201c88:	00010797          	auipc	a5,0x10
ffffffffc0201c8c:	88d7bc23          	sd	a3,-1896(a5) # ffffffffc0211520 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c90:	100027f3          	csrr	a5,sstatus
ffffffffc0201c94:	8b89                	andi	a5,a5,2
ffffffffc0201c96:	4e079863          	bnez	a5,ffffffffc0202186 <pmm_init+0x646>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201c9a:	000bb783          	ld	a5,0(s7)
ffffffffc0201c9e:	779c                	ld	a5,40(a5)
ffffffffc0201ca0:	9782                	jalr	a5
ffffffffc0201ca2:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201ca4:	6098                	ld	a4,0(s1)
ffffffffc0201ca6:	c80007b7          	lui	a5,0xc8000
ffffffffc0201caa:	83b1                	srli	a5,a5,0xc
ffffffffc0201cac:	66e7eb63          	bltu	a5,a4,ffffffffc0202322 <pmm_init+0x7e2>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201cb0:	00093503          	ld	a0,0(s2)
ffffffffc0201cb4:	64050763          	beqz	a0,ffffffffc0202302 <pmm_init+0x7c2>
ffffffffc0201cb8:	03451793          	slli	a5,a0,0x34
ffffffffc0201cbc:	64079363          	bnez	a5,ffffffffc0202302 <pmm_init+0x7c2>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201cc0:	4601                	li	a2,0
ffffffffc0201cc2:	4581                	li	a1,0
ffffffffc0201cc4:	c77ff0ef          	jal	ffffffffc020193a <get_page>
ffffffffc0201cc8:	6a051f63          	bnez	a0,ffffffffc0202386 <pmm_init+0x846>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0201ccc:	4505                	li	a0,1
ffffffffc0201cce:	935ff0ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0201cd2:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201cd4:	00093503          	ld	a0,0(s2)
ffffffffc0201cd8:	4681                	li	a3,0
ffffffffc0201cda:	4601                	li	a2,0
ffffffffc0201cdc:	85d2                	mv	a1,s4
ffffffffc0201cde:	d51ff0ef          	jal	ffffffffc0201a2e <page_insert>
ffffffffc0201ce2:	68051263          	bnez	a0,ffffffffc0202366 <pmm_init+0x826>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201ce6:	00093503          	ld	a0,0(s2)
ffffffffc0201cea:	4601                	li	a2,0
ffffffffc0201cec:	4581                	li	a1,0
ffffffffc0201cee:	a1fff0ef          	jal	ffffffffc020170c <get_pte>
ffffffffc0201cf2:	64050a63          	beqz	a0,ffffffffc0202346 <pmm_init+0x806>
    assert(pte2page(*ptep) == p1);
ffffffffc0201cf6:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201cf8:	0017f713          	andi	a4,a5,1
ffffffffc0201cfc:	64070363          	beqz	a4,ffffffffc0202342 <pmm_init+0x802>
    if (PPN(pa) >= npage) {
ffffffffc0201d00:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201d02:	078a                	slli	a5,a5,0x2
ffffffffc0201d04:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201d06:	5ac7f063          	bgeu	a5,a2,ffffffffc02022a6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d0a:	fff80737          	lui	a4,0xfff80
ffffffffc0201d0e:	97ba                	add	a5,a5,a4
ffffffffc0201d10:	000b3683          	ld	a3,0(s6)
ffffffffc0201d14:	00379713          	slli	a4,a5,0x3
ffffffffc0201d18:	97ba                	add	a5,a5,a4
ffffffffc0201d1a:	078e                	slli	a5,a5,0x3
ffffffffc0201d1c:	97b6                	add	a5,a5,a3
ffffffffc0201d1e:	58fa1663          	bne	s4,a5,ffffffffc02022aa <pmm_init+0x76a>
    assert(page_ref(p1) == 1);
ffffffffc0201d22:	000a2703          	lw	a4,0(s4)
ffffffffc0201d26:	4785                	li	a5,1
ffffffffc0201d28:	1cf711e3          	bne	a4,a5,ffffffffc02026ea <pmm_init+0xbaa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201d2c:	00093503          	ld	a0,0(s2)
ffffffffc0201d30:	77fd                	lui	a5,0xfffff
ffffffffc0201d32:	6114                	ld	a3,0(a0)
ffffffffc0201d34:	068a                	slli	a3,a3,0x2
ffffffffc0201d36:	8efd                	and	a3,a3,a5
ffffffffc0201d38:	00c6d713          	srli	a4,a3,0xc
ffffffffc0201d3c:	18c77be3          	bgeu	a4,a2,ffffffffc02026d2 <pmm_init+0xb92>
ffffffffc0201d40:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d44:	96e2                	add	a3,a3,s8
ffffffffc0201d46:	0006ba83          	ld	s5,0(a3)
ffffffffc0201d4a:	0a8a                	slli	s5,s5,0x2
ffffffffc0201d4c:	00fafab3          	and	s5,s5,a5
ffffffffc0201d50:	00cad793          	srli	a5,s5,0xc
ffffffffc0201d54:	6ac7f963          	bgeu	a5,a2,ffffffffc0202406 <pmm_init+0x8c6>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d58:	4601                	li	a2,0
ffffffffc0201d5a:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d5c:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d5e:	9afff0ef          	jal	ffffffffc020170c <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d62:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d64:	69851163          	bne	a0,s8,ffffffffc02023e6 <pmm_init+0x8a6>

    p2 = alloc_page();
ffffffffc0201d68:	4505                	li	a0,1
ffffffffc0201d6a:	899ff0ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0201d6e:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201d70:	00093503          	ld	a0,0(s2)
ffffffffc0201d74:	46d1                	li	a3,20
ffffffffc0201d76:	6605                	lui	a2,0x1
ffffffffc0201d78:	85d6                	mv	a1,s5
ffffffffc0201d7a:	cb5ff0ef          	jal	ffffffffc0201a2e <page_insert>
ffffffffc0201d7e:	64051463          	bnez	a0,ffffffffc02023c6 <pmm_init+0x886>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201d82:	00093503          	ld	a0,0(s2)
ffffffffc0201d86:	4601                	li	a2,0
ffffffffc0201d88:	6585                	lui	a1,0x1
ffffffffc0201d8a:	983ff0ef          	jal	ffffffffc020170c <get_pte>
ffffffffc0201d8e:	60050c63          	beqz	a0,ffffffffc02023a6 <pmm_init+0x866>
    assert(*ptep & PTE_U);
ffffffffc0201d92:	611c                	ld	a5,0(a0)
ffffffffc0201d94:	0107f713          	andi	a4,a5,16
ffffffffc0201d98:	76070463          	beqz	a4,ffffffffc0202500 <pmm_init+0x9c0>
    assert(*ptep & PTE_W);
ffffffffc0201d9c:	8b91                	andi	a5,a5,4
ffffffffc0201d9e:	74078163          	beqz	a5,ffffffffc02024e0 <pmm_init+0x9a0>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201da2:	00093503          	ld	a0,0(s2)
ffffffffc0201da6:	611c                	ld	a5,0(a0)
ffffffffc0201da8:	8bc1                	andi	a5,a5,16
ffffffffc0201daa:	70078b63          	beqz	a5,ffffffffc02024c0 <pmm_init+0x980>
    assert(page_ref(p2) == 1);
ffffffffc0201dae:	000aa703          	lw	a4,0(s5) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0201db2:	4785                	li	a5,1
ffffffffc0201db4:	6ef71663          	bne	a4,a5,ffffffffc02024a0 <pmm_init+0x960>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201db8:	4681                	li	a3,0
ffffffffc0201dba:	6605                	lui	a2,0x1
ffffffffc0201dbc:	85d2                	mv	a1,s4
ffffffffc0201dbe:	c71ff0ef          	jal	ffffffffc0201a2e <page_insert>
ffffffffc0201dc2:	6a051f63          	bnez	a0,ffffffffc0202480 <pmm_init+0x940>
    assert(page_ref(p1) == 2);
ffffffffc0201dc6:	000a2703          	lw	a4,0(s4)
ffffffffc0201dca:	4789                	li	a5,2
ffffffffc0201dcc:	68f71a63          	bne	a4,a5,ffffffffc0202460 <pmm_init+0x920>
    assert(page_ref(p2) == 0);
ffffffffc0201dd0:	000aa783          	lw	a5,0(s5)
ffffffffc0201dd4:	66079663          	bnez	a5,ffffffffc0202440 <pmm_init+0x900>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201dd8:	00093503          	ld	a0,0(s2)
ffffffffc0201ddc:	4601                	li	a2,0
ffffffffc0201dde:	6585                	lui	a1,0x1
ffffffffc0201de0:	92dff0ef          	jal	ffffffffc020170c <get_pte>
ffffffffc0201de4:	62050e63          	beqz	a0,ffffffffc0202420 <pmm_init+0x8e0>
    assert(pte2page(*ptep) == p1);
ffffffffc0201de8:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201dea:	00177793          	andi	a5,a4,1
ffffffffc0201dee:	54078a63          	beqz	a5,ffffffffc0202342 <pmm_init+0x802>
    if (PPN(pa) >= npage) {
ffffffffc0201df2:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201df4:	00271793          	slli	a5,a4,0x2
ffffffffc0201df8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201dfa:	4ad7f663          	bgeu	a5,a3,ffffffffc02022a6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dfe:	fff806b7          	lui	a3,0xfff80
ffffffffc0201e02:	97b6                	add	a5,a5,a3
ffffffffc0201e04:	000b3603          	ld	a2,0(s6)
ffffffffc0201e08:	00379693          	slli	a3,a5,0x3
ffffffffc0201e0c:	97b6                	add	a5,a5,a3
ffffffffc0201e0e:	078e                	slli	a5,a5,0x3
ffffffffc0201e10:	97b2                	add	a5,a5,a2
ffffffffc0201e12:	76fa1763          	bne	s4,a5,ffffffffc0202580 <pmm_init+0xa40>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201e16:	8b41                	andi	a4,a4,16
ffffffffc0201e18:	74071463          	bnez	a4,ffffffffc0202560 <pmm_init+0xa20>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201e1c:	00093503          	ld	a0,0(s2)
ffffffffc0201e20:	4581                	li	a1,0
ffffffffc0201e22:	b73ff0ef          	jal	ffffffffc0201994 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201e26:	000a2703          	lw	a4,0(s4)
ffffffffc0201e2a:	4785                	li	a5,1
ffffffffc0201e2c:	70f71a63          	bne	a4,a5,ffffffffc0202540 <pmm_init+0xa00>
    assert(page_ref(p2) == 0);
ffffffffc0201e30:	000aa783          	lw	a5,0(s5)
ffffffffc0201e34:	6e079663          	bnez	a5,ffffffffc0202520 <pmm_init+0x9e0>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0201e38:	00093503          	ld	a0,0(s2)
ffffffffc0201e3c:	6585                	lui	a1,0x1
ffffffffc0201e3e:	b57ff0ef          	jal	ffffffffc0201994 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201e42:	000a2783          	lw	a5,0(s4)
ffffffffc0201e46:	7a079a63          	bnez	a5,ffffffffc02025fa <pmm_init+0xaba>
    assert(page_ref(p2) == 0);
ffffffffc0201e4a:	000aa783          	lw	a5,0(s5)
ffffffffc0201e4e:	78079663          	bnez	a5,ffffffffc02025da <pmm_init+0xa9a>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201e52:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0201e56:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e58:	000a3783          	ld	a5,0(s4)
ffffffffc0201e5c:	078a                	slli	a5,a5,0x2
ffffffffc0201e5e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e60:	44c7f363          	bgeu	a5,a2,ffffffffc02022a6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e64:	fff80737          	lui	a4,0xfff80
ffffffffc0201e68:	97ba                	add	a5,a5,a4
ffffffffc0201e6a:	00379713          	slli	a4,a5,0x3
ffffffffc0201e6e:	000b3503          	ld	a0,0(s6)
ffffffffc0201e72:	973e                	add	a4,a4,a5
ffffffffc0201e74:	070e                	slli	a4,a4,0x3
static inline int page_ref(struct Page *page) { return page->ref; }
ffffffffc0201e76:	00e507b3          	add	a5,a0,a4
ffffffffc0201e7a:	4394                	lw	a3,0(a5)
ffffffffc0201e7c:	4785                	li	a5,1
ffffffffc0201e7e:	72f69e63          	bne	a3,a5,ffffffffc02025ba <pmm_init+0xa7a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201e82:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0201e86:	e3978793          	addi	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c1>
ffffffffc0201e8a:	07b2                	slli	a5,a5,0xc
ffffffffc0201e8c:	e3978793          	addi	a5,a5,-455
ffffffffc0201e90:	07b2                	slli	a5,a5,0xc
ffffffffc0201e92:	e3978793          	addi	a5,a5,-455
ffffffffc0201e96:	07b2                	slli	a5,a5,0xc
ffffffffc0201e98:	870d                	srai	a4,a4,0x3
ffffffffc0201e9a:	e3978793          	addi	a5,a5,-455
ffffffffc0201e9e:	02f707b3          	mul	a5,a4,a5
ffffffffc0201ea2:	00080737          	lui	a4,0x80
ffffffffc0201ea6:	97ba                	add	a5,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ea8:	00c79693          	slli	a3,a5,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201eac:	6ec7fb63          	bgeu	a5,a2,ffffffffc02025a2 <pmm_init+0xa62>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201eb0:	0009b783          	ld	a5,0(s3)
ffffffffc0201eb4:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0201eb6:	639c                	ld	a5,0(a5)
ffffffffc0201eb8:	078a                	slli	a5,a5,0x2
ffffffffc0201eba:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201ebc:	3ec7f563          	bgeu	a5,a2,ffffffffc02022a6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ec0:	8f99                	sub	a5,a5,a4
ffffffffc0201ec2:	00379713          	slli	a4,a5,0x3
ffffffffc0201ec6:	97ba                	add	a5,a5,a4
ffffffffc0201ec8:	078e                	slli	a5,a5,0x3
ffffffffc0201eca:	953e                	add	a0,a0,a5
ffffffffc0201ecc:	100027f3          	csrr	a5,sstatus
ffffffffc0201ed0:	8b89                	andi	a5,a5,2
ffffffffc0201ed2:	30079463          	bnez	a5,ffffffffc02021da <pmm_init+0x69a>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201ed6:	000bb783          	ld	a5,0(s7)
ffffffffc0201eda:	4585                	li	a1,1
ffffffffc0201edc:	739c                	ld	a5,32(a5)
ffffffffc0201ede:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201ee0:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0201ee4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201ee6:	078a                	slli	a5,a5,0x2
ffffffffc0201ee8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201eea:	3ae7fe63          	bgeu	a5,a4,ffffffffc02022a6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201eee:	fff80737          	lui	a4,0xfff80
ffffffffc0201ef2:	97ba                	add	a5,a5,a4
ffffffffc0201ef4:	000b3503          	ld	a0,0(s6)
ffffffffc0201ef8:	00379713          	slli	a4,a5,0x3
ffffffffc0201efc:	97ba                	add	a5,a5,a4
ffffffffc0201efe:	078e                	slli	a5,a5,0x3
ffffffffc0201f00:	953e                	add	a0,a0,a5
ffffffffc0201f02:	100027f3          	csrr	a5,sstatus
ffffffffc0201f06:	8b89                	andi	a5,a5,2
ffffffffc0201f08:	2a079d63          	bnez	a5,ffffffffc02021c2 <pmm_init+0x682>
ffffffffc0201f0c:	000bb783          	ld	a5,0(s7)
ffffffffc0201f10:	4585                	li	a1,1
ffffffffc0201f12:	739c                	ld	a5,32(a5)
ffffffffc0201f14:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0201f16:	00093783          	ld	a5,0(s2)
ffffffffc0201f1a:	0007b023          	sd	zero,0(a5)
ffffffffc0201f1e:	100027f3          	csrr	a5,sstatus
ffffffffc0201f22:	8b89                	andi	a5,a5,2
ffffffffc0201f24:	28079563          	bnez	a5,ffffffffc02021ae <pmm_init+0x66e>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201f28:	000bb783          	ld	a5,0(s7)
ffffffffc0201f2c:	779c                	ld	a5,40(a5)
ffffffffc0201f2e:	9782                	jalr	a5
ffffffffc0201f30:	8a2a                	mv	s4,a0

    assert(nr_free_store==nr_free_pages());
ffffffffc0201f32:	77441463          	bne	s0,s4,ffffffffc020269a <pmm_init+0xb5a>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201f36:	00003517          	auipc	a0,0x3
ffffffffc0201f3a:	6ca50513          	addi	a0,a0,1738 # ffffffffc0205600 <etext+0x10b0>
ffffffffc0201f3e:	97cfe0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc0201f42:	100027f3          	csrr	a5,sstatus
ffffffffc0201f46:	8b89                	andi	a5,a5,2
ffffffffc0201f48:	24079963          	bnez	a5,ffffffffc020219a <pmm_init+0x65a>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201f4c:	000bb783          	ld	a5,0(s7)
ffffffffc0201f50:	779c                	ld	a5,40(a5)
ffffffffc0201f52:	9782                	jalr	a5
ffffffffc0201f54:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201f56:	6098                	ld	a4,0(s1)
ffffffffc0201f58:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f5c:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201f5e:	00c71793          	slli	a5,a4,0xc
ffffffffc0201f62:	6a05                	lui	s4,0x1
ffffffffc0201f64:	02f47c63          	bgeu	s0,a5,ffffffffc0201f9c <pmm_init+0x45c>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201f68:	00c45793          	srli	a5,s0,0xc
ffffffffc0201f6c:	00093503          	ld	a0,0(s2)
ffffffffc0201f70:	2ce7fe63          	bgeu	a5,a4,ffffffffc020224c <pmm_init+0x70c>
ffffffffc0201f74:	0009b583          	ld	a1,0(s3)
ffffffffc0201f78:	4601                	li	a2,0
ffffffffc0201f7a:	95a2                	add	a1,a1,s0
ffffffffc0201f7c:	f90ff0ef          	jal	ffffffffc020170c <get_pte>
ffffffffc0201f80:	30050363          	beqz	a0,ffffffffc0202286 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f84:	611c                	ld	a5,0(a0)
ffffffffc0201f86:	078a                	slli	a5,a5,0x2
ffffffffc0201f88:	0157f7b3          	and	a5,a5,s5
ffffffffc0201f8c:	2c879d63          	bne	a5,s0,ffffffffc0202266 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201f90:	6098                	ld	a4,0(s1)
ffffffffc0201f92:	9452                	add	s0,s0,s4
ffffffffc0201f94:	00c71793          	slli	a5,a4,0xc
ffffffffc0201f98:	fcf468e3          	bltu	s0,a5,ffffffffc0201f68 <pmm_init+0x428>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0201f9c:	00093783          	ld	a5,0(s2)
ffffffffc0201fa0:	639c                	ld	a5,0(a5)
ffffffffc0201fa2:	6c079c63          	bnez	a5,ffffffffc020267a <pmm_init+0xb3a>

    struct Page *p;
    p = alloc_page();
ffffffffc0201fa6:	4505                	li	a0,1
ffffffffc0201fa8:	e5aff0ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0201fac:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201fae:	00093503          	ld	a0,0(s2)
ffffffffc0201fb2:	4699                	li	a3,6
ffffffffc0201fb4:	10000613          	li	a2,256
ffffffffc0201fb8:	85d2                	mv	a1,s4
ffffffffc0201fba:	a75ff0ef          	jal	ffffffffc0201a2e <page_insert>
ffffffffc0201fbe:	68051e63          	bnez	a0,ffffffffc020265a <pmm_init+0xb1a>
    assert(page_ref(p) == 1);
ffffffffc0201fc2:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201fc6:	4785                	li	a5,1
ffffffffc0201fc8:	66f71963          	bne	a4,a5,ffffffffc020263a <pmm_init+0xafa>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201fcc:	00093503          	ld	a0,0(s2)
ffffffffc0201fd0:	6605                	lui	a2,0x1
ffffffffc0201fd2:	4699                	li	a3,6
ffffffffc0201fd4:	10060613          	addi	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0201fd8:	85d2                	mv	a1,s4
ffffffffc0201fda:	a55ff0ef          	jal	ffffffffc0201a2e <page_insert>
ffffffffc0201fde:	62051e63          	bnez	a0,ffffffffc020261a <pmm_init+0xada>
    assert(page_ref(p) == 2);
ffffffffc0201fe2:	000a2703          	lw	a4,0(s4)
ffffffffc0201fe6:	4789                	li	a5,2
ffffffffc0201fe8:	76f71163          	bne	a4,a5,ffffffffc020274a <pmm_init+0xc0a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201fec:	00003597          	auipc	a1,0x3
ffffffffc0201ff0:	74c58593          	addi	a1,a1,1868 # ffffffffc0205738 <etext+0x11e8>
ffffffffc0201ff4:	10000513          	li	a0,256
ffffffffc0201ff8:	4ce020ef          	jal	ffffffffc02044c6 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201ffc:	6585                	lui	a1,0x1
ffffffffc0201ffe:	10058593          	addi	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0202002:	10000513          	li	a0,256
ffffffffc0202006:	4d2020ef          	jal	ffffffffc02044d8 <strcmp>
ffffffffc020200a:	72051063          	bnez	a0,ffffffffc020272a <pmm_init+0xbea>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020200e:	f8e39437          	lui	s0,0xf8e39
ffffffffc0202012:	e3940413          	addi	s0,s0,-455 # fffffffff8e38e39 <end+0x38c278c1>
ffffffffc0202016:	0432                	slli	s0,s0,0xc
ffffffffc0202018:	000b3683          	ld	a3,0(s6)
ffffffffc020201c:	e3940413          	addi	s0,s0,-455
ffffffffc0202020:	0432                	slli	s0,s0,0xc
ffffffffc0202022:	e3940413          	addi	s0,s0,-455
ffffffffc0202026:	40da06b3          	sub	a3,s4,a3
ffffffffc020202a:	0432                	slli	s0,s0,0xc
ffffffffc020202c:	868d                	srai	a3,a3,0x3
ffffffffc020202e:	e3940413          	addi	s0,s0,-455
ffffffffc0202032:	028686b3          	mul	a3,a3,s0
ffffffffc0202036:	00080cb7          	lui	s9,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020203a:	6098                	ld	a4,0(s1)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020203c:	96e6                	add	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020203e:	00c69793          	slli	a5,a3,0xc
ffffffffc0202042:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202044:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202046:	54e7fe63          	bgeu	a5,a4,ffffffffc02025a2 <pmm_init+0xa62>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020204a:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020204e:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202052:	97b6                	add	a5,a5,a3
ffffffffc0202054:	10078023          	sb	zero,256(a5)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202058:	438020ef          	jal	ffffffffc0204490 <strlen>
ffffffffc020205c:	6a051763          	bnez	a0,ffffffffc020270a <pmm_init+0xbca>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202060:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202064:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202066:	000ab783          	ld	a5,0(s5) # fffffffffffff000 <end+0x3fdeda88>
ffffffffc020206a:	078a                	slli	a5,a5,0x2
ffffffffc020206c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020206e:	22c7fc63          	bgeu	a5,a2,ffffffffc02022a6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202072:	419787b3          	sub	a5,a5,s9
ffffffffc0202076:	00379713          	slli	a4,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020207a:	97ba                	add	a5,a5,a4
ffffffffc020207c:	028787b3          	mul	a5,a5,s0
ffffffffc0202080:	97e6                	add	a5,a5,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc0202082:	00c79413          	slli	s0,a5,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202086:	50c7fd63          	bgeu	a5,a2,ffffffffc02025a0 <pmm_init+0xa60>
ffffffffc020208a:	0009b783          	ld	a5,0(s3)
ffffffffc020208e:	943e                	add	s0,s0,a5
ffffffffc0202090:	100027f3          	csrr	a5,sstatus
ffffffffc0202094:	8b89                	andi	a5,a5,2
ffffffffc0202096:	1a079063          	bnez	a5,ffffffffc0202236 <pmm_init+0x6f6>
    { pmm_manager->free_pages(base, n); }
ffffffffc020209a:	000bb783          	ld	a5,0(s7)
ffffffffc020209e:	4585                	li	a1,1
ffffffffc02020a0:	8552                	mv	a0,s4
ffffffffc02020a2:	739c                	ld	a5,32(a5)
ffffffffc02020a4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02020a6:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc02020a8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02020aa:	078a                	slli	a5,a5,0x2
ffffffffc02020ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02020ae:	1ee7fc63          	bgeu	a5,a4,ffffffffc02022a6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02020b2:	fff80737          	lui	a4,0xfff80
ffffffffc02020b6:	97ba                	add	a5,a5,a4
ffffffffc02020b8:	000b3503          	ld	a0,0(s6)
ffffffffc02020bc:	00379713          	slli	a4,a5,0x3
ffffffffc02020c0:	97ba                	add	a5,a5,a4
ffffffffc02020c2:	078e                	slli	a5,a5,0x3
ffffffffc02020c4:	953e                	add	a0,a0,a5
ffffffffc02020c6:	100027f3          	csrr	a5,sstatus
ffffffffc02020ca:	8b89                	andi	a5,a5,2
ffffffffc02020cc:	14079963          	bnez	a5,ffffffffc020221e <pmm_init+0x6de>
ffffffffc02020d0:	000bb783          	ld	a5,0(s7)
ffffffffc02020d4:	4585                	li	a1,1
ffffffffc02020d6:	739c                	ld	a5,32(a5)
ffffffffc02020d8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02020da:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc02020de:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02020e0:	078a                	slli	a5,a5,0x2
ffffffffc02020e2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02020e4:	1ce7f163          	bgeu	a5,a4,ffffffffc02022a6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02020e8:	fff80737          	lui	a4,0xfff80
ffffffffc02020ec:	97ba                	add	a5,a5,a4
ffffffffc02020ee:	000b3503          	ld	a0,0(s6)
ffffffffc02020f2:	00379713          	slli	a4,a5,0x3
ffffffffc02020f6:	97ba                	add	a5,a5,a4
ffffffffc02020f8:	078e                	slli	a5,a5,0x3
ffffffffc02020fa:	953e                	add	a0,a0,a5
ffffffffc02020fc:	100027f3          	csrr	a5,sstatus
ffffffffc0202100:	8b89                	andi	a5,a5,2
ffffffffc0202102:	10079263          	bnez	a5,ffffffffc0202206 <pmm_init+0x6c6>
ffffffffc0202106:	000bb783          	ld	a5,0(s7)
ffffffffc020210a:	4585                	li	a1,1
ffffffffc020210c:	739c                	ld	a5,32(a5)
ffffffffc020210e:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202110:	00093783          	ld	a5,0(s2)
ffffffffc0202114:	0007b023          	sd	zero,0(a5)
ffffffffc0202118:	100027f3          	csrr	a5,sstatus
ffffffffc020211c:	8b89                	andi	a5,a5,2
ffffffffc020211e:	0c079a63          	bnez	a5,ffffffffc02021f2 <pmm_init+0x6b2>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0202122:	000bb783          	ld	a5,0(s7)
ffffffffc0202126:	779c                	ld	a5,40(a5)
ffffffffc0202128:	9782                	jalr	a5
ffffffffc020212a:	842a                	mv	s0,a0

    assert(nr_free_store==nr_free_pages());
ffffffffc020212c:	1a8c1b63          	bne	s8,s0,ffffffffc02022e2 <pmm_init+0x7a2>
}
ffffffffc0202130:	7406                	ld	s0,96(sp)
ffffffffc0202132:	70a6                	ld	ra,104(sp)
ffffffffc0202134:	64e6                	ld	s1,88(sp)
ffffffffc0202136:	6946                	ld	s2,80(sp)
ffffffffc0202138:	69a6                	ld	s3,72(sp)
ffffffffc020213a:	6a06                	ld	s4,64(sp)
ffffffffc020213c:	7ae2                	ld	s5,56(sp)
ffffffffc020213e:	7b42                	ld	s6,48(sp)
ffffffffc0202140:	7ba2                	ld	s7,40(sp)
ffffffffc0202142:	7c02                	ld	s8,32(sp)
ffffffffc0202144:	6ce2                	ld	s9,24(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202146:	00003517          	auipc	a0,0x3
ffffffffc020214a:	66a50513          	addi	a0,a0,1642 # ffffffffc02057b0 <etext+0x1260>
}
ffffffffc020214e:	6165                	addi	sp,sp,112
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202150:	f6bfd06f          	j	ffffffffc02000ba <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202154:	6705                	lui	a4,0x1
ffffffffc0202156:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202158:	96ba                	add	a3,a3,a4
ffffffffc020215a:	777d                	lui	a4,0xfffff
ffffffffc020215c:	8f75                	and	a4,a4,a3
    if (PPN(pa) >= npage) {
ffffffffc020215e:	00c75693          	srli	a3,a4,0xc
ffffffffc0202162:	14f6f263          	bgeu	a3,a5,ffffffffc02022a6 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202166:	000bb583          	ld	a1,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc020216a:	fff807b7          	lui	a5,0xfff80
ffffffffc020216e:	96be                	add	a3,a3,a5
ffffffffc0202170:	00369793          	slli	a5,a3,0x3
ffffffffc0202174:	97b6                	add	a5,a5,a3
ffffffffc0202176:	6994                	ld	a3,16(a1)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202178:	8e19                	sub	a2,a2,a4
ffffffffc020217a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020217c:	00c65593          	srli	a1,a2,0xc
ffffffffc0202180:	953e                	add	a0,a0,a5
ffffffffc0202182:	9682                	jalr	a3
}
ffffffffc0202184:	b4f9                	j	ffffffffc0201c52 <pmm_init+0x112>
        intr_disable();
ffffffffc0202186:	b56fe0ef          	jal	ffffffffc02004dc <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc020218a:	000bb783          	ld	a5,0(s7)
ffffffffc020218e:	779c                	ld	a5,40(a5)
ffffffffc0202190:	9782                	jalr	a5
ffffffffc0202192:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202194:	b42fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0202198:	b631                	j	ffffffffc0201ca4 <pmm_init+0x164>
        intr_disable();
ffffffffc020219a:	b42fe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc020219e:	000bb783          	ld	a5,0(s7)
ffffffffc02021a2:	779c                	ld	a5,40(a5)
ffffffffc02021a4:	9782                	jalr	a5
ffffffffc02021a6:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02021a8:	b2efe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02021ac:	b36d                	j	ffffffffc0201f56 <pmm_init+0x416>
        intr_disable();
ffffffffc02021ae:	b2efe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc02021b2:	000bb783          	ld	a5,0(s7)
ffffffffc02021b6:	779c                	ld	a5,40(a5)
ffffffffc02021b8:	9782                	jalr	a5
ffffffffc02021ba:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02021bc:	b1afe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02021c0:	bb8d                	j	ffffffffc0201f32 <pmm_init+0x3f2>
ffffffffc02021c2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02021c4:	b18fe0ef          	jal	ffffffffc02004dc <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc02021c8:	000bb783          	ld	a5,0(s7)
ffffffffc02021cc:	6522                	ld	a0,8(sp)
ffffffffc02021ce:	4585                	li	a1,1
ffffffffc02021d0:	739c                	ld	a5,32(a5)
ffffffffc02021d2:	9782                	jalr	a5
        intr_enable();
ffffffffc02021d4:	b02fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02021d8:	bb3d                	j	ffffffffc0201f16 <pmm_init+0x3d6>
ffffffffc02021da:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02021dc:	b00fe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc02021e0:	000bb783          	ld	a5,0(s7)
ffffffffc02021e4:	6522                	ld	a0,8(sp)
ffffffffc02021e6:	4585                	li	a1,1
ffffffffc02021e8:	739c                	ld	a5,32(a5)
ffffffffc02021ea:	9782                	jalr	a5
        intr_enable();
ffffffffc02021ec:	aeafe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02021f0:	b9c5                	j	ffffffffc0201ee0 <pmm_init+0x3a0>
        intr_disable();
ffffffffc02021f2:	aeafe0ef          	jal	ffffffffc02004dc <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02021f6:	000bb783          	ld	a5,0(s7)
ffffffffc02021fa:	779c                	ld	a5,40(a5)
ffffffffc02021fc:	9782                	jalr	a5
ffffffffc02021fe:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202200:	ad6fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0202204:	b725                	j	ffffffffc020212c <pmm_init+0x5ec>
ffffffffc0202206:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202208:	ad4fe0ef          	jal	ffffffffc02004dc <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc020220c:	000bb783          	ld	a5,0(s7)
ffffffffc0202210:	6522                	ld	a0,8(sp)
ffffffffc0202212:	4585                	li	a1,1
ffffffffc0202214:	739c                	ld	a5,32(a5)
ffffffffc0202216:	9782                	jalr	a5
        intr_enable();
ffffffffc0202218:	abefe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc020221c:	bdd5                	j	ffffffffc0202110 <pmm_init+0x5d0>
ffffffffc020221e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202220:	abcfe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0202224:	000bb783          	ld	a5,0(s7)
ffffffffc0202228:	6522                	ld	a0,8(sp)
ffffffffc020222a:	4585                	li	a1,1
ffffffffc020222c:	739c                	ld	a5,32(a5)
ffffffffc020222e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202230:	aa6fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0202234:	b55d                	j	ffffffffc02020da <pmm_init+0x59a>
        intr_disable();
ffffffffc0202236:	aa6fe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc020223a:	000bb783          	ld	a5,0(s7)
ffffffffc020223e:	4585                	li	a1,1
ffffffffc0202240:	8552                	mv	a0,s4
ffffffffc0202242:	739c                	ld	a5,32(a5)
ffffffffc0202244:	9782                	jalr	a5
        intr_enable();
ffffffffc0202246:	a90fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc020224a:	bdb1                	j	ffffffffc02020a6 <pmm_init+0x566>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020224c:	86a2                	mv	a3,s0
ffffffffc020224e:	00003617          	auipc	a2,0x3
ffffffffc0202252:	fe260613          	addi	a2,a2,-30 # ffffffffc0205230 <etext+0xce0>
ffffffffc0202256:	1cd00593          	li	a1,461
ffffffffc020225a:	00003517          	auipc	a0,0x3
ffffffffc020225e:	ffe50513          	addi	a0,a0,-2 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202262:	8fefe0ef          	jal	ffffffffc0200360 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202266:	00003697          	auipc	a3,0x3
ffffffffc020226a:	3fa68693          	addi	a3,a3,1018 # ffffffffc0205660 <etext+0x1110>
ffffffffc020226e:	00003617          	auipc	a2,0x3
ffffffffc0202272:	bba60613          	addi	a2,a2,-1094 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202276:	1ce00593          	li	a1,462
ffffffffc020227a:	00003517          	auipc	a0,0x3
ffffffffc020227e:	fde50513          	addi	a0,a0,-34 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202282:	8defe0ef          	jal	ffffffffc0200360 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202286:	00003697          	auipc	a3,0x3
ffffffffc020228a:	39a68693          	addi	a3,a3,922 # ffffffffc0205620 <etext+0x10d0>
ffffffffc020228e:	00003617          	auipc	a2,0x3
ffffffffc0202292:	b9a60613          	addi	a2,a2,-1126 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202296:	1cd00593          	li	a1,461
ffffffffc020229a:	00003517          	auipc	a0,0x3
ffffffffc020229e:	fbe50513          	addi	a0,a0,-66 # ffffffffc0205258 <etext+0xd08>
ffffffffc02022a2:	8befe0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc02022a6:	b24ff0ef          	jal	ffffffffc02015ca <pa2page.part.0>
    assert(pte2page(*ptep) == p1);
ffffffffc02022aa:	00003697          	auipc	a3,0x3
ffffffffc02022ae:	16e68693          	addi	a3,a3,366 # ffffffffc0205418 <etext+0xec8>
ffffffffc02022b2:	00003617          	auipc	a2,0x3
ffffffffc02022b6:	b7660613          	addi	a2,a2,-1162 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02022ba:	19b00593          	li	a1,411
ffffffffc02022be:	00003517          	auipc	a0,0x3
ffffffffc02022c2:	f9a50513          	addi	a0,a0,-102 # ffffffffc0205258 <etext+0xd08>
ffffffffc02022c6:	89afe0ef          	jal	ffffffffc0200360 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02022ca:	00003617          	auipc	a2,0x3
ffffffffc02022ce:	02660613          	addi	a2,a2,38 # ffffffffc02052f0 <etext+0xda0>
ffffffffc02022d2:	07700593          	li	a1,119
ffffffffc02022d6:	00003517          	auipc	a0,0x3
ffffffffc02022da:	f8250513          	addi	a0,a0,-126 # ffffffffc0205258 <etext+0xd08>
ffffffffc02022de:	882fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc02022e2:	00003697          	auipc	a3,0x3
ffffffffc02022e6:	2fe68693          	addi	a3,a3,766 # ffffffffc02055e0 <etext+0x1090>
ffffffffc02022ea:	00003617          	auipc	a2,0x3
ffffffffc02022ee:	b3e60613          	addi	a2,a2,-1218 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02022f2:	1e800593          	li	a1,488
ffffffffc02022f6:	00003517          	auipc	a0,0x3
ffffffffc02022fa:	f6250513          	addi	a0,a0,-158 # ffffffffc0205258 <etext+0xd08>
ffffffffc02022fe:	862fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202302:	00003697          	auipc	a3,0x3
ffffffffc0202306:	05668693          	addi	a3,a3,86 # ffffffffc0205358 <etext+0xe08>
ffffffffc020230a:	00003617          	auipc	a2,0x3
ffffffffc020230e:	b1e60613          	addi	a2,a2,-1250 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202312:	19300593          	li	a1,403
ffffffffc0202316:	00003517          	auipc	a0,0x3
ffffffffc020231a:	f4250513          	addi	a0,a0,-190 # ffffffffc0205258 <etext+0xd08>
ffffffffc020231e:	842fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202322:	00003697          	auipc	a3,0x3
ffffffffc0202326:	01668693          	addi	a3,a3,22 # ffffffffc0205338 <etext+0xde8>
ffffffffc020232a:	00003617          	auipc	a2,0x3
ffffffffc020232e:	afe60613          	addi	a2,a2,-1282 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202332:	19200593          	li	a1,402
ffffffffc0202336:	00003517          	auipc	a0,0x3
ffffffffc020233a:	f2250513          	addi	a0,a0,-222 # ffffffffc0205258 <etext+0xd08>
ffffffffc020233e:	822fe0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc0202342:	aa4ff0ef          	jal	ffffffffc02015e6 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202346:	00003697          	auipc	a3,0x3
ffffffffc020234a:	0a268693          	addi	a3,a3,162 # ffffffffc02053e8 <etext+0xe98>
ffffffffc020234e:	00003617          	auipc	a2,0x3
ffffffffc0202352:	ada60613          	addi	a2,a2,-1318 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202356:	19a00593          	li	a1,410
ffffffffc020235a:	00003517          	auipc	a0,0x3
ffffffffc020235e:	efe50513          	addi	a0,a0,-258 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202362:	ffffd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202366:	00003697          	auipc	a3,0x3
ffffffffc020236a:	05268693          	addi	a3,a3,82 # ffffffffc02053b8 <etext+0xe68>
ffffffffc020236e:	00003617          	auipc	a2,0x3
ffffffffc0202372:	aba60613          	addi	a2,a2,-1350 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202376:	19800593          	li	a1,408
ffffffffc020237a:	00003517          	auipc	a0,0x3
ffffffffc020237e:	ede50513          	addi	a0,a0,-290 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202382:	fdffd0ef          	jal	ffffffffc0200360 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202386:	00003697          	auipc	a3,0x3
ffffffffc020238a:	00a68693          	addi	a3,a3,10 # ffffffffc0205390 <etext+0xe40>
ffffffffc020238e:	00003617          	auipc	a2,0x3
ffffffffc0202392:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202396:	19400593          	li	a1,404
ffffffffc020239a:	00003517          	auipc	a0,0x3
ffffffffc020239e:	ebe50513          	addi	a0,a0,-322 # ffffffffc0205258 <etext+0xd08>
ffffffffc02023a2:	fbffd0ef          	jal	ffffffffc0200360 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02023a6:	00003697          	auipc	a3,0x3
ffffffffc02023aa:	10268693          	addi	a3,a3,258 # ffffffffc02054a8 <etext+0xf58>
ffffffffc02023ae:	00003617          	auipc	a2,0x3
ffffffffc02023b2:	a7a60613          	addi	a2,a2,-1414 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02023b6:	1a400593          	li	a1,420
ffffffffc02023ba:	00003517          	auipc	a0,0x3
ffffffffc02023be:	e9e50513          	addi	a0,a0,-354 # ffffffffc0205258 <etext+0xd08>
ffffffffc02023c2:	f9ffd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02023c6:	00003697          	auipc	a3,0x3
ffffffffc02023ca:	0aa68693          	addi	a3,a3,170 # ffffffffc0205470 <etext+0xf20>
ffffffffc02023ce:	00003617          	auipc	a2,0x3
ffffffffc02023d2:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02023d6:	1a300593          	li	a1,419
ffffffffc02023da:	00003517          	auipc	a0,0x3
ffffffffc02023de:	e7e50513          	addi	a0,a0,-386 # ffffffffc0205258 <etext+0xd08>
ffffffffc02023e2:	f7ffd0ef          	jal	ffffffffc0200360 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02023e6:	00003697          	auipc	a3,0x3
ffffffffc02023ea:	06268693          	addi	a3,a3,98 # ffffffffc0205448 <etext+0xef8>
ffffffffc02023ee:	00003617          	auipc	a2,0x3
ffffffffc02023f2:	a3a60613          	addi	a2,a2,-1478 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02023f6:	1a000593          	li	a1,416
ffffffffc02023fa:	00003517          	auipc	a0,0x3
ffffffffc02023fe:	e5e50513          	addi	a0,a0,-418 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202402:	f5ffd0ef          	jal	ffffffffc0200360 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202406:	86d6                	mv	a3,s5
ffffffffc0202408:	00003617          	auipc	a2,0x3
ffffffffc020240c:	e2860613          	addi	a2,a2,-472 # ffffffffc0205230 <etext+0xce0>
ffffffffc0202410:	19f00593          	li	a1,415
ffffffffc0202414:	00003517          	auipc	a0,0x3
ffffffffc0202418:	e4450513          	addi	a0,a0,-444 # ffffffffc0205258 <etext+0xd08>
ffffffffc020241c:	f45fd0ef          	jal	ffffffffc0200360 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202420:	00003697          	auipc	a3,0x3
ffffffffc0202424:	08868693          	addi	a3,a3,136 # ffffffffc02054a8 <etext+0xf58>
ffffffffc0202428:	00003617          	auipc	a2,0x3
ffffffffc020242c:	a0060613          	addi	a2,a2,-1536 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202430:	1ad00593          	li	a1,429
ffffffffc0202434:	00003517          	auipc	a0,0x3
ffffffffc0202438:	e2450513          	addi	a0,a0,-476 # ffffffffc0205258 <etext+0xd08>
ffffffffc020243c:	f25fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202440:	00003697          	auipc	a3,0x3
ffffffffc0202444:	13068693          	addi	a3,a3,304 # ffffffffc0205570 <etext+0x1020>
ffffffffc0202448:	00003617          	auipc	a2,0x3
ffffffffc020244c:	9e060613          	addi	a2,a2,-1568 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202450:	1ac00593          	li	a1,428
ffffffffc0202454:	00003517          	auipc	a0,0x3
ffffffffc0202458:	e0450513          	addi	a0,a0,-508 # ffffffffc0205258 <etext+0xd08>
ffffffffc020245c:	f05fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202460:	00003697          	auipc	a3,0x3
ffffffffc0202464:	0f868693          	addi	a3,a3,248 # ffffffffc0205558 <etext+0x1008>
ffffffffc0202468:	00003617          	auipc	a2,0x3
ffffffffc020246c:	9c060613          	addi	a2,a2,-1600 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202470:	1ab00593          	li	a1,427
ffffffffc0202474:	00003517          	auipc	a0,0x3
ffffffffc0202478:	de450513          	addi	a0,a0,-540 # ffffffffc0205258 <etext+0xd08>
ffffffffc020247c:	ee5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202480:	00003697          	auipc	a3,0x3
ffffffffc0202484:	0a868693          	addi	a3,a3,168 # ffffffffc0205528 <etext+0xfd8>
ffffffffc0202488:	00003617          	auipc	a2,0x3
ffffffffc020248c:	9a060613          	addi	a2,a2,-1632 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202490:	1aa00593          	li	a1,426
ffffffffc0202494:	00003517          	auipc	a0,0x3
ffffffffc0202498:	dc450513          	addi	a0,a0,-572 # ffffffffc0205258 <etext+0xd08>
ffffffffc020249c:	ec5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02024a0:	00003697          	auipc	a3,0x3
ffffffffc02024a4:	07068693          	addi	a3,a3,112 # ffffffffc0205510 <etext+0xfc0>
ffffffffc02024a8:	00003617          	auipc	a2,0x3
ffffffffc02024ac:	98060613          	addi	a2,a2,-1664 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02024b0:	1a800593          	li	a1,424
ffffffffc02024b4:	00003517          	auipc	a0,0x3
ffffffffc02024b8:	da450513          	addi	a0,a0,-604 # ffffffffc0205258 <etext+0xd08>
ffffffffc02024bc:	ea5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02024c0:	00003697          	auipc	a3,0x3
ffffffffc02024c4:	03868693          	addi	a3,a3,56 # ffffffffc02054f8 <etext+0xfa8>
ffffffffc02024c8:	00003617          	auipc	a2,0x3
ffffffffc02024cc:	96060613          	addi	a2,a2,-1696 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02024d0:	1a700593          	li	a1,423
ffffffffc02024d4:	00003517          	auipc	a0,0x3
ffffffffc02024d8:	d8450513          	addi	a0,a0,-636 # ffffffffc0205258 <etext+0xd08>
ffffffffc02024dc:	e85fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02024e0:	00003697          	auipc	a3,0x3
ffffffffc02024e4:	00868693          	addi	a3,a3,8 # ffffffffc02054e8 <etext+0xf98>
ffffffffc02024e8:	00003617          	auipc	a2,0x3
ffffffffc02024ec:	94060613          	addi	a2,a2,-1728 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02024f0:	1a600593          	li	a1,422
ffffffffc02024f4:	00003517          	auipc	a0,0x3
ffffffffc02024f8:	d6450513          	addi	a0,a0,-668 # ffffffffc0205258 <etext+0xd08>
ffffffffc02024fc:	e65fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202500:	00003697          	auipc	a3,0x3
ffffffffc0202504:	fd868693          	addi	a3,a3,-40 # ffffffffc02054d8 <etext+0xf88>
ffffffffc0202508:	00003617          	auipc	a2,0x3
ffffffffc020250c:	92060613          	addi	a2,a2,-1760 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202510:	1a500593          	li	a1,421
ffffffffc0202514:	00003517          	auipc	a0,0x3
ffffffffc0202518:	d4450513          	addi	a0,a0,-700 # ffffffffc0205258 <etext+0xd08>
ffffffffc020251c:	e45fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202520:	00003697          	auipc	a3,0x3
ffffffffc0202524:	05068693          	addi	a3,a3,80 # ffffffffc0205570 <etext+0x1020>
ffffffffc0202528:	00003617          	auipc	a2,0x3
ffffffffc020252c:	90060613          	addi	a2,a2,-1792 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202530:	1b300593          	li	a1,435
ffffffffc0202534:	00003517          	auipc	a0,0x3
ffffffffc0202538:	d2450513          	addi	a0,a0,-732 # ffffffffc0205258 <etext+0xd08>
ffffffffc020253c:	e25fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202540:	00003697          	auipc	a3,0x3
ffffffffc0202544:	ef068693          	addi	a3,a3,-272 # ffffffffc0205430 <etext+0xee0>
ffffffffc0202548:	00003617          	auipc	a2,0x3
ffffffffc020254c:	8e060613          	addi	a2,a2,-1824 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202550:	1b200593          	li	a1,434
ffffffffc0202554:	00003517          	auipc	a0,0x3
ffffffffc0202558:	d0450513          	addi	a0,a0,-764 # ffffffffc0205258 <etext+0xd08>
ffffffffc020255c:	e05fd0ef          	jal	ffffffffc0200360 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202560:	00003697          	auipc	a3,0x3
ffffffffc0202564:	02868693          	addi	a3,a3,40 # ffffffffc0205588 <etext+0x1038>
ffffffffc0202568:	00003617          	auipc	a2,0x3
ffffffffc020256c:	8c060613          	addi	a2,a2,-1856 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202570:	1af00593          	li	a1,431
ffffffffc0202574:	00003517          	auipc	a0,0x3
ffffffffc0202578:	ce450513          	addi	a0,a0,-796 # ffffffffc0205258 <etext+0xd08>
ffffffffc020257c:	de5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202580:	00003697          	auipc	a3,0x3
ffffffffc0202584:	e9868693          	addi	a3,a3,-360 # ffffffffc0205418 <etext+0xec8>
ffffffffc0202588:	00003617          	auipc	a2,0x3
ffffffffc020258c:	8a060613          	addi	a2,a2,-1888 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202590:	1ae00593          	li	a1,430
ffffffffc0202594:	00003517          	auipc	a0,0x3
ffffffffc0202598:	cc450513          	addi	a0,a0,-828 # ffffffffc0205258 <etext+0xd08>
ffffffffc020259c:	dc5fd0ef          	jal	ffffffffc0200360 <__panic>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02025a0:	86a2                	mv	a3,s0
ffffffffc02025a2:	00003617          	auipc	a2,0x3
ffffffffc02025a6:	c8e60613          	addi	a2,a2,-882 # ffffffffc0205230 <etext+0xce0>
ffffffffc02025aa:	06a00593          	li	a1,106
ffffffffc02025ae:	00003517          	auipc	a0,0x3
ffffffffc02025b2:	c4a50513          	addi	a0,a0,-950 # ffffffffc02051f8 <etext+0xca8>
ffffffffc02025b6:	dabfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02025ba:	00003697          	auipc	a3,0x3
ffffffffc02025be:	ffe68693          	addi	a3,a3,-2 # ffffffffc02055b8 <etext+0x1068>
ffffffffc02025c2:	00003617          	auipc	a2,0x3
ffffffffc02025c6:	86660613          	addi	a2,a2,-1946 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02025ca:	1b900593          	li	a1,441
ffffffffc02025ce:	00003517          	auipc	a0,0x3
ffffffffc02025d2:	c8a50513          	addi	a0,a0,-886 # ffffffffc0205258 <etext+0xd08>
ffffffffc02025d6:	d8bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02025da:	00003697          	auipc	a3,0x3
ffffffffc02025de:	f9668693          	addi	a3,a3,-106 # ffffffffc0205570 <etext+0x1020>
ffffffffc02025e2:	00003617          	auipc	a2,0x3
ffffffffc02025e6:	84660613          	addi	a2,a2,-1978 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02025ea:	1b700593          	li	a1,439
ffffffffc02025ee:	00003517          	auipc	a0,0x3
ffffffffc02025f2:	c6a50513          	addi	a0,a0,-918 # ffffffffc0205258 <etext+0xd08>
ffffffffc02025f6:	d6bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02025fa:	00003697          	auipc	a3,0x3
ffffffffc02025fe:	fa668693          	addi	a3,a3,-90 # ffffffffc02055a0 <etext+0x1050>
ffffffffc0202602:	00003617          	auipc	a2,0x3
ffffffffc0202606:	82660613          	addi	a2,a2,-2010 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020260a:	1b600593          	li	a1,438
ffffffffc020260e:	00003517          	auipc	a0,0x3
ffffffffc0202612:	c4a50513          	addi	a0,a0,-950 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202616:	d4bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020261a:	00003697          	auipc	a3,0x3
ffffffffc020261e:	0c668693          	addi	a3,a3,198 # ffffffffc02056e0 <etext+0x1190>
ffffffffc0202622:	00003617          	auipc	a2,0x3
ffffffffc0202626:	80660613          	addi	a2,a2,-2042 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020262a:	1d800593          	li	a1,472
ffffffffc020262e:	00003517          	auipc	a0,0x3
ffffffffc0202632:	c2a50513          	addi	a0,a0,-982 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202636:	d2bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020263a:	00003697          	auipc	a3,0x3
ffffffffc020263e:	08e68693          	addi	a3,a3,142 # ffffffffc02056c8 <etext+0x1178>
ffffffffc0202642:	00002617          	auipc	a2,0x2
ffffffffc0202646:	7e660613          	addi	a2,a2,2022 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020264a:	1d700593          	li	a1,471
ffffffffc020264e:	00003517          	auipc	a0,0x3
ffffffffc0202652:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202656:	d0bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020265a:	00003697          	auipc	a3,0x3
ffffffffc020265e:	03668693          	addi	a3,a3,54 # ffffffffc0205690 <etext+0x1140>
ffffffffc0202662:	00002617          	auipc	a2,0x2
ffffffffc0202666:	7c660613          	addi	a2,a2,1990 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020266a:	1d600593          	li	a1,470
ffffffffc020266e:	00003517          	auipc	a0,0x3
ffffffffc0202672:	bea50513          	addi	a0,a0,-1046 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202676:	cebfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc020267a:	00003697          	auipc	a3,0x3
ffffffffc020267e:	ffe68693          	addi	a3,a3,-2 # ffffffffc0205678 <etext+0x1128>
ffffffffc0202682:	00002617          	auipc	a2,0x2
ffffffffc0202686:	7a660613          	addi	a2,a2,1958 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020268a:	1d200593          	li	a1,466
ffffffffc020268e:	00003517          	auipc	a0,0x3
ffffffffc0202692:	bca50513          	addi	a0,a0,-1078 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202696:	ccbfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020269a:	00003697          	auipc	a3,0x3
ffffffffc020269e:	f4668693          	addi	a3,a3,-186 # ffffffffc02055e0 <etext+0x1090>
ffffffffc02026a2:	00002617          	auipc	a2,0x2
ffffffffc02026a6:	78660613          	addi	a2,a2,1926 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02026aa:	1c000593          	li	a1,448
ffffffffc02026ae:	00003517          	auipc	a0,0x3
ffffffffc02026b2:	baa50513          	addi	a0,a0,-1110 # ffffffffc0205258 <etext+0xd08>
ffffffffc02026b6:	cabfd0ef          	jal	ffffffffc0200360 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02026ba:	00003617          	auipc	a2,0x3
ffffffffc02026be:	c3660613          	addi	a2,a2,-970 # ffffffffc02052f0 <etext+0xda0>
ffffffffc02026c2:	0bd00593          	li	a1,189
ffffffffc02026c6:	00003517          	auipc	a0,0x3
ffffffffc02026ca:	b9250513          	addi	a0,a0,-1134 # ffffffffc0205258 <etext+0xd08>
ffffffffc02026ce:	c93fd0ef          	jal	ffffffffc0200360 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02026d2:	00003617          	auipc	a2,0x3
ffffffffc02026d6:	b5e60613          	addi	a2,a2,-1186 # ffffffffc0205230 <etext+0xce0>
ffffffffc02026da:	19e00593          	li	a1,414
ffffffffc02026de:	00003517          	auipc	a0,0x3
ffffffffc02026e2:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0205258 <etext+0xd08>
ffffffffc02026e6:	c7bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02026ea:	00003697          	auipc	a3,0x3
ffffffffc02026ee:	d4668693          	addi	a3,a3,-698 # ffffffffc0205430 <etext+0xee0>
ffffffffc02026f2:	00002617          	auipc	a2,0x2
ffffffffc02026f6:	73660613          	addi	a2,a2,1846 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02026fa:	19c00593          	li	a1,412
ffffffffc02026fe:	00003517          	auipc	a0,0x3
ffffffffc0202702:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202706:	c5bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020270a:	00003697          	auipc	a3,0x3
ffffffffc020270e:	07e68693          	addi	a3,a3,126 # ffffffffc0205788 <etext+0x1238>
ffffffffc0202712:	00002617          	auipc	a2,0x2
ffffffffc0202716:	71660613          	addi	a2,a2,1814 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020271a:	1e000593          	li	a1,480
ffffffffc020271e:	00003517          	auipc	a0,0x3
ffffffffc0202722:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202726:	c3bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020272a:	00003697          	auipc	a3,0x3
ffffffffc020272e:	02668693          	addi	a3,a3,38 # ffffffffc0205750 <etext+0x1200>
ffffffffc0202732:	00002617          	auipc	a2,0x2
ffffffffc0202736:	6f660613          	addi	a2,a2,1782 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020273a:	1dd00593          	li	a1,477
ffffffffc020273e:	00003517          	auipc	a0,0x3
ffffffffc0202742:	b1a50513          	addi	a0,a0,-1254 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202746:	c1bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p) == 2);
ffffffffc020274a:	00003697          	auipc	a3,0x3
ffffffffc020274e:	fd668693          	addi	a3,a3,-42 # ffffffffc0205720 <etext+0x11d0>
ffffffffc0202752:	00002617          	auipc	a2,0x2
ffffffffc0202756:	6d660613          	addi	a2,a2,1750 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020275a:	1d900593          	li	a1,473
ffffffffc020275e:	00003517          	auipc	a0,0x3
ffffffffc0202762:	afa50513          	addi	a0,a0,-1286 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202766:	bfbfd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020276a <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc020276a:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc020276e:	8082                	ret

ffffffffc0202770 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202770:	7179                	addi	sp,sp,-48
ffffffffc0202772:	e84a                	sd	s2,16(sp)
ffffffffc0202774:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0202776:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202778:	ec26                	sd	s1,24(sp)
ffffffffc020277a:	e44e                	sd	s3,8(sp)
ffffffffc020277c:	f406                	sd	ra,40(sp)
ffffffffc020277e:	f022                	sd	s0,32(sp)
ffffffffc0202780:	84ae                	mv	s1,a1
ffffffffc0202782:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0202784:	e7ffe0ef          	jal	ffffffffc0201602 <alloc_pages>
    if (page != NULL) {
ffffffffc0202788:	c131                	beqz	a0,ffffffffc02027cc <pgdir_alloc_page+0x5c>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc020278a:	842a                	mv	s0,a0
ffffffffc020278c:	85aa                	mv	a1,a0
ffffffffc020278e:	86ce                	mv	a3,s3
ffffffffc0202790:	8626                	mv	a2,s1
ffffffffc0202792:	854a                	mv	a0,s2
ffffffffc0202794:	a9aff0ef          	jal	ffffffffc0201a2e <page_insert>
ffffffffc0202798:	ed11                	bnez	a0,ffffffffc02027b4 <pgdir_alloc_page+0x44>
        if (swap_init_ok) {
ffffffffc020279a:	0000f797          	auipc	a5,0xf
ffffffffc020279e:	dae7a783          	lw	a5,-594(a5) # ffffffffc0211548 <swap_init_ok>
ffffffffc02027a2:	e79d                	bnez	a5,ffffffffc02027d0 <pgdir_alloc_page+0x60>
}
ffffffffc02027a4:	70a2                	ld	ra,40(sp)
ffffffffc02027a6:	8522                	mv	a0,s0
ffffffffc02027a8:	7402                	ld	s0,32(sp)
ffffffffc02027aa:	64e2                	ld	s1,24(sp)
ffffffffc02027ac:	6942                	ld	s2,16(sp)
ffffffffc02027ae:	69a2                	ld	s3,8(sp)
ffffffffc02027b0:	6145                	addi	sp,sp,48
ffffffffc02027b2:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02027b4:	100027f3          	csrr	a5,sstatus
ffffffffc02027b8:	8b89                	andi	a5,a5,2
ffffffffc02027ba:	eba9                	bnez	a5,ffffffffc020280c <pgdir_alloc_page+0x9c>
    { pmm_manager->free_pages(base, n); }
ffffffffc02027bc:	0000f797          	auipc	a5,0xf
ffffffffc02027c0:	d5c7b783          	ld	a5,-676(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc02027c4:	739c                	ld	a5,32(a5)
ffffffffc02027c6:	4585                	li	a1,1
ffffffffc02027c8:	8522                	mv	a0,s0
ffffffffc02027ca:	9782                	jalr	a5
            return NULL;
ffffffffc02027cc:	4401                	li	s0,0
ffffffffc02027ce:	bfd9                	j	ffffffffc02027a4 <pgdir_alloc_page+0x34>
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc02027d0:	4681                	li	a3,0
ffffffffc02027d2:	8622                	mv	a2,s0
ffffffffc02027d4:	85a6                	mv	a1,s1
ffffffffc02027d6:	0000f517          	auipc	a0,0xf
ffffffffc02027da:	d9a53503          	ld	a0,-614(a0) # ffffffffc0211570 <check_mm_struct>
ffffffffc02027de:	09d000ef          	jal	ffffffffc020307a <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc02027e2:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc02027e4:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc02027e6:	4785                	li	a5,1
ffffffffc02027e8:	faf70ee3          	beq	a4,a5,ffffffffc02027a4 <pgdir_alloc_page+0x34>
ffffffffc02027ec:	00003697          	auipc	a3,0x3
ffffffffc02027f0:	fe468693          	addi	a3,a3,-28 # ffffffffc02057d0 <etext+0x1280>
ffffffffc02027f4:	00002617          	auipc	a2,0x2
ffffffffc02027f8:	63460613          	addi	a2,a2,1588 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02027fc:	17a00593          	li	a1,378
ffffffffc0202800:	00003517          	auipc	a0,0x3
ffffffffc0202804:	a5850513          	addi	a0,a0,-1448 # ffffffffc0205258 <etext+0xd08>
ffffffffc0202808:	b59fd0ef          	jal	ffffffffc0200360 <__panic>
        intr_disable();
ffffffffc020280c:	cd1fd0ef          	jal	ffffffffc02004dc <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0202810:	0000f797          	auipc	a5,0xf
ffffffffc0202814:	d087b783          	ld	a5,-760(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc0202818:	739c                	ld	a5,32(a5)
ffffffffc020281a:	8522                	mv	a0,s0
ffffffffc020281c:	4585                	li	a1,1
ffffffffc020281e:	9782                	jalr	a5
            return NULL;
ffffffffc0202820:	4401                	li	s0,0
        intr_enable();
ffffffffc0202822:	cb5fd0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0202826:	bfbd                	j	ffffffffc02027a4 <pgdir_alloc_page+0x34>

ffffffffc0202828 <kmalloc>:
}

void *kmalloc(size_t n) {
ffffffffc0202828:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020282a:	67d5                	lui	a5,0x15
void *kmalloc(size_t n) {
ffffffffc020282c:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020282e:	fff50713          	addi	a4,a0,-1
ffffffffc0202832:	17f9                	addi	a5,a5,-2 # 14ffe <kern_entry-0xffffffffc01eb002>
ffffffffc0202834:	06e7e363          	bltu	a5,a4,ffffffffc020289a <kmalloc+0x72>
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc0202838:	6785                	lui	a5,0x1
ffffffffc020283a:	17fd                	addi	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020283c:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc020283e:	8131                	srli	a0,a0,0xc
ffffffffc0202840:	dc3fe0ef          	jal	ffffffffc0201602 <alloc_pages>
    assert(base != NULL);
ffffffffc0202844:	c941                	beqz	a0,ffffffffc02028d4 <kmalloc+0xac>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202846:	f8e397b7          	lui	a5,0xf8e39
ffffffffc020284a:	e3978793          	addi	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c1>
ffffffffc020284e:	07b2                	slli	a5,a5,0xc
ffffffffc0202850:	e3978793          	addi	a5,a5,-455
ffffffffc0202854:	07b2                	slli	a5,a5,0xc
ffffffffc0202856:	0000f717          	auipc	a4,0xf
ffffffffc020285a:	cea73703          	ld	a4,-790(a4) # ffffffffc0211540 <pages>
ffffffffc020285e:	e3978793          	addi	a5,a5,-455
ffffffffc0202862:	8d19                	sub	a0,a0,a4
ffffffffc0202864:	07b2                	slli	a5,a5,0xc
ffffffffc0202866:	e3978793          	addi	a5,a5,-455
ffffffffc020286a:	850d                	srai	a0,a0,0x3
ffffffffc020286c:	02f50533          	mul	a0,a0,a5
ffffffffc0202870:	000807b7          	lui	a5,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202874:	0000f717          	auipc	a4,0xf
ffffffffc0202878:	cc473703          	ld	a4,-828(a4) # ffffffffc0211538 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020287c:	953e                	add	a0,a0,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020287e:	00c51793          	slli	a5,a0,0xc
ffffffffc0202882:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202884:	0532                	slli	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202886:	02e7fa63          	bgeu	a5,a4,ffffffffc02028ba <kmalloc+0x92>
    ptr = page2kva(base);
    return ptr;
}
ffffffffc020288a:	60a2                	ld	ra,8(sp)
ffffffffc020288c:	0000f797          	auipc	a5,0xf
ffffffffc0202890:	ca47b783          	ld	a5,-860(a5) # ffffffffc0211530 <va_pa_offset>
ffffffffc0202894:	953e                	add	a0,a0,a5
ffffffffc0202896:	0141                	addi	sp,sp,16
ffffffffc0202898:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020289a:	00003697          	auipc	a3,0x3
ffffffffc020289e:	f4e68693          	addi	a3,a3,-178 # ffffffffc02057e8 <etext+0x1298>
ffffffffc02028a2:	00002617          	auipc	a2,0x2
ffffffffc02028a6:	58660613          	addi	a2,a2,1414 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02028aa:	1f000593          	li	a1,496
ffffffffc02028ae:	00003517          	auipc	a0,0x3
ffffffffc02028b2:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0205258 <etext+0xd08>
ffffffffc02028b6:	aabfd0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc02028ba:	86aa                	mv	a3,a0
ffffffffc02028bc:	00003617          	auipc	a2,0x3
ffffffffc02028c0:	97460613          	addi	a2,a2,-1676 # ffffffffc0205230 <etext+0xce0>
ffffffffc02028c4:	06a00593          	li	a1,106
ffffffffc02028c8:	00003517          	auipc	a0,0x3
ffffffffc02028cc:	93050513          	addi	a0,a0,-1744 # ffffffffc02051f8 <etext+0xca8>
ffffffffc02028d0:	a91fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(base != NULL);
ffffffffc02028d4:	00003697          	auipc	a3,0x3
ffffffffc02028d8:	f3468693          	addi	a3,a3,-204 # ffffffffc0205808 <etext+0x12b8>
ffffffffc02028dc:	00002617          	auipc	a2,0x2
ffffffffc02028e0:	54c60613          	addi	a2,a2,1356 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02028e4:	1f300593          	li	a1,499
ffffffffc02028e8:	00003517          	auipc	a0,0x3
ffffffffc02028ec:	97050513          	addi	a0,a0,-1680 # ffffffffc0205258 <etext+0xd08>
ffffffffc02028f0:	a71fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02028f4 <kfree>:

void kfree(void *ptr, size_t n) {
ffffffffc02028f4:	1101                	addi	sp,sp,-32
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02028f6:	67d5                	lui	a5,0x15
void kfree(void *ptr, size_t n) {
ffffffffc02028f8:	ec06                	sd	ra,24(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02028fa:	fff58713          	addi	a4,a1,-1
ffffffffc02028fe:	17f9                	addi	a5,a5,-2 # 14ffe <kern_entry-0xffffffffc01eb002>
ffffffffc0202900:	0ae7ee63          	bltu	a5,a4,ffffffffc02029bc <kfree+0xc8>
    assert(ptr != NULL);
ffffffffc0202904:	cd41                	beqz	a0,ffffffffc020299c <kfree+0xa8>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc0202906:	6785                	lui	a5,0x1
ffffffffc0202908:	17fd                	addi	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020290a:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc020290c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202910:	81b1                	srli	a1,a1,0xc
ffffffffc0202912:	06f56863          	bltu	a0,a5,ffffffffc0202982 <kfree+0x8e>
ffffffffc0202916:	0000f797          	auipc	a5,0xf
ffffffffc020291a:	c1a7b783          	ld	a5,-998(a5) # ffffffffc0211530 <va_pa_offset>
ffffffffc020291e:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc0202920:	8131                	srli	a0,a0,0xc
ffffffffc0202922:	0000f797          	auipc	a5,0xf
ffffffffc0202926:	c167b783          	ld	a5,-1002(a5) # ffffffffc0211538 <npage>
ffffffffc020292a:	04f57a63          	bgeu	a0,a5,ffffffffc020297e <kfree+0x8a>
    return &pages[PPN(pa) - nbase];
ffffffffc020292e:	fff807b7          	lui	a5,0xfff80
ffffffffc0202932:	953e                	add	a0,a0,a5
ffffffffc0202934:	00351793          	slli	a5,a0,0x3
ffffffffc0202938:	97aa                	add	a5,a5,a0
ffffffffc020293a:	078e                	slli	a5,a5,0x3
ffffffffc020293c:	0000f517          	auipc	a0,0xf
ffffffffc0202940:	c0453503          	ld	a0,-1020(a0) # ffffffffc0211540 <pages>
ffffffffc0202944:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202946:	100027f3          	csrr	a5,sstatus
ffffffffc020294a:	8b89                	andi	a5,a5,2
ffffffffc020294c:	eb89                	bnez	a5,ffffffffc020295e <kfree+0x6a>
    { pmm_manager->free_pages(base, n); }
ffffffffc020294e:	0000f797          	auipc	a5,0xf
ffffffffc0202952:	bca7b783          	ld	a5,-1078(a5) # ffffffffc0211518 <pmm_manager>
    base = kva2page(ptr);
    free_pages(base, num_pages);
}
ffffffffc0202956:	60e2                	ld	ra,24(sp)
    { pmm_manager->free_pages(base, n); }
ffffffffc0202958:	739c                	ld	a5,32(a5)
}
ffffffffc020295a:	6105                	addi	sp,sp,32
    { pmm_manager->free_pages(base, n); }
ffffffffc020295c:	8782                	jr	a5
        intr_disable();
ffffffffc020295e:	e42a                	sd	a0,8(sp)
ffffffffc0202960:	e02e                	sd	a1,0(sp)
ffffffffc0202962:	b7bfd0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0202966:	0000f797          	auipc	a5,0xf
ffffffffc020296a:	bb27b783          	ld	a5,-1102(a5) # ffffffffc0211518 <pmm_manager>
ffffffffc020296e:	6582                	ld	a1,0(sp)
ffffffffc0202970:	6522                	ld	a0,8(sp)
ffffffffc0202972:	739c                	ld	a5,32(a5)
ffffffffc0202974:	9782                	jalr	a5
}
ffffffffc0202976:	60e2                	ld	ra,24(sp)
ffffffffc0202978:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020297a:	b5dfd06f          	j	ffffffffc02004d6 <intr_enable>
ffffffffc020297e:	c4dfe0ef          	jal	ffffffffc02015ca <pa2page.part.0>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0202982:	86aa                	mv	a3,a0
ffffffffc0202984:	00003617          	auipc	a2,0x3
ffffffffc0202988:	96c60613          	addi	a2,a2,-1684 # ffffffffc02052f0 <etext+0xda0>
ffffffffc020298c:	06c00593          	li	a1,108
ffffffffc0202990:	00003517          	auipc	a0,0x3
ffffffffc0202994:	86850513          	addi	a0,a0,-1944 # ffffffffc02051f8 <etext+0xca8>
ffffffffc0202998:	9c9fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(ptr != NULL);
ffffffffc020299c:	00003697          	auipc	a3,0x3
ffffffffc02029a0:	e7c68693          	addi	a3,a3,-388 # ffffffffc0205818 <etext+0x12c8>
ffffffffc02029a4:	00002617          	auipc	a2,0x2
ffffffffc02029a8:	48460613          	addi	a2,a2,1156 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02029ac:	1fa00593          	li	a1,506
ffffffffc02029b0:	00003517          	auipc	a0,0x3
ffffffffc02029b4:	8a850513          	addi	a0,a0,-1880 # ffffffffc0205258 <etext+0xd08>
ffffffffc02029b8:	9a9fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02029bc:	00003697          	auipc	a3,0x3
ffffffffc02029c0:	e2c68693          	addi	a3,a3,-468 # ffffffffc02057e8 <etext+0x1298>
ffffffffc02029c4:	00002617          	auipc	a2,0x2
ffffffffc02029c8:	46460613          	addi	a2,a2,1124 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02029cc:	1f900593          	li	a1,505
ffffffffc02029d0:	00003517          	auipc	a0,0x3
ffffffffc02029d4:	88850513          	addi	a0,a0,-1912 # ffffffffc0205258 <etext+0xd08>
ffffffffc02029d8:	989fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02029dc <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc02029dc:	7135                	addi	sp,sp,-160
ffffffffc02029de:	ed06                	sd	ra,152(sp)
     swapfs_init();
ffffffffc02029e0:	484010ef          	jal	ffffffffc0203e64 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02029e4:	0000f697          	auipc	a3,0xf
ffffffffc02029e8:	b6c6b683          	ld	a3,-1172(a3) # ffffffffc0211550 <max_swap_offset>
ffffffffc02029ec:	010007b7          	lui	a5,0x1000
ffffffffc02029f0:	ff968713          	addi	a4,a3,-7
ffffffffc02029f4:	17e1                	addi	a5,a5,-8 # fffff8 <kern_entry-0xffffffffbf200008>
ffffffffc02029f6:	40e7e463          	bltu	a5,a4,ffffffffc0202dfe <swap_init+0x422>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc02029fa:	00007797          	auipc	a5,0x7
ffffffffc02029fe:	60678793          	addi	a5,a5,1542 # ffffffffc020a000 <swap_manager_clock>
     int r = sm->init();
ffffffffc0202a02:	6798                	ld	a4,8(a5)
ffffffffc0202a04:	fcce                	sd	s3,120(sp)
ffffffffc0202a06:	f0da                	sd	s6,96(sp)
     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc0202a08:	0000fb17          	auipc	s6,0xf
ffffffffc0202a0c:	b50b0b13          	addi	s6,s6,-1200 # ffffffffc0211558 <sm>
ffffffffc0202a10:	00fb3023          	sd	a5,0(s6)
     int r = sm->init();
ffffffffc0202a14:	9702                	jalr	a4
ffffffffc0202a16:	89aa                	mv	s3,a0
     
     if (r == 0)
ffffffffc0202a18:	c519                	beqz	a0,ffffffffc0202a26 <swap_init+0x4a>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0202a1a:	60ea                	ld	ra,152(sp)
ffffffffc0202a1c:	7b06                	ld	s6,96(sp)
ffffffffc0202a1e:	854e                	mv	a0,s3
ffffffffc0202a20:	79e6                	ld	s3,120(sp)
ffffffffc0202a22:	610d                	addi	sp,sp,160
ffffffffc0202a24:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202a26:	000b3783          	ld	a5,0(s6)
ffffffffc0202a2a:	00003517          	auipc	a0,0x3
ffffffffc0202a2e:	e2e50513          	addi	a0,a0,-466 # ffffffffc0205858 <etext+0x1308>
ffffffffc0202a32:	e922                	sd	s0,144(sp)
ffffffffc0202a34:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0202a36:	4785                	li	a5,1
ffffffffc0202a38:	e526                	sd	s1,136(sp)
ffffffffc0202a3a:	e0ea                	sd	s10,64(sp)
ffffffffc0202a3c:	0000f717          	auipc	a4,0xf
ffffffffc0202a40:	b0f72623          	sw	a5,-1268(a4) # ffffffffc0211548 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202a44:	e14a                	sd	s2,128(sp)
ffffffffc0202a46:	f8d2                	sd	s4,112(sp)
ffffffffc0202a48:	f4d6                	sd	s5,104(sp)
ffffffffc0202a4a:	ecde                	sd	s7,88(sp)
ffffffffc0202a4c:	e8e2                	sd	s8,80(sp)
ffffffffc0202a4e:	e4e6                	sd	s9,72(sp)
ffffffffc0202a50:	fc6e                	sd	s11,56(sp)
    return listelm->next;
ffffffffc0202a52:	0000e497          	auipc	s1,0xe
ffffffffc0202a56:	5ee48493          	addi	s1,s1,1518 # ffffffffc0211040 <free_area>
ffffffffc0202a5a:	e60fd0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc0202a5e:	649c                	ld	a5,8(s1)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0202a60:	4401                	li	s0,0
ffffffffc0202a62:	4d01                	li	s10,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202a64:	2e978363          	beq	a5,s1,ffffffffc0202d4a <swap_init+0x36e>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202a68:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202a6c:	8b09                	andi	a4,a4,2
ffffffffc0202a6e:	2e070063          	beqz	a4,ffffffffc0202d4e <swap_init+0x372>
        count ++, total += p->property;
ffffffffc0202a72:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202a76:	679c                	ld	a5,8(a5)
ffffffffc0202a78:	2d05                	addiw	s10,s10,1
ffffffffc0202a7a:	9c39                	addw	s0,s0,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202a7c:	fe9796e3          	bne	a5,s1,ffffffffc0202a68 <swap_init+0x8c>
     }
     assert(total == nr_free_pages());
ffffffffc0202a80:	8922                	mv	s2,s0
ffffffffc0202a82:	c51fe0ef          	jal	ffffffffc02016d2 <nr_free_pages>
ffffffffc0202a86:	4b251463          	bne	a0,s2,ffffffffc0202f2e <swap_init+0x552>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202a8a:	8622                	mv	a2,s0
ffffffffc0202a8c:	85ea                	mv	a1,s10
ffffffffc0202a8e:	00003517          	auipc	a0,0x3
ffffffffc0202a92:	de250513          	addi	a0,a0,-542 # ffffffffc0205870 <etext+0x1320>
ffffffffc0202a96:	e24fd0ef          	jal	ffffffffc02000ba <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0202a9a:	32f000ef          	jal	ffffffffc02035c8 <mm_create>
ffffffffc0202a9e:	ec2a                	sd	a0,24(sp)
     assert(mm != NULL);
ffffffffc0202aa0:	56050763          	beqz	a0,ffffffffc020300e <swap_init+0x632>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202aa4:	0000f797          	auipc	a5,0xf
ffffffffc0202aa8:	acc78793          	addi	a5,a5,-1332 # ffffffffc0211570 <check_mm_struct>
ffffffffc0202aac:	6398                	ld	a4,0(a5)
ffffffffc0202aae:	58071063          	bnez	a4,ffffffffc020302e <swap_init+0x652>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202ab2:	0000f697          	auipc	a3,0xf
ffffffffc0202ab6:	a766b683          	ld	a3,-1418(a3) # ffffffffc0211528 <boot_pgdir>
     check_mm_struct = mm;
ffffffffc0202aba:	6662                	ld	a2,24(sp)
     assert(pgdir[0] == 0);
ffffffffc0202abc:	6298                	ld	a4,0(a3)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202abe:	e836                	sd	a3,16(sp)
     check_mm_struct = mm;
ffffffffc0202ac0:	e390                	sd	a2,0(a5)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202ac2:	ee14                	sd	a3,24(a2)
     assert(pgdir[0] == 0);
ffffffffc0202ac4:	40071563          	bnez	a4,ffffffffc0202ece <swap_init+0x4f2>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202ac8:	6599                	lui	a1,0x6
ffffffffc0202aca:	460d                	li	a2,3
ffffffffc0202acc:	6505                	lui	a0,0x1
ffffffffc0202ace:	343000ef          	jal	ffffffffc0203610 <vma_create>
ffffffffc0202ad2:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202ad4:	40050d63          	beqz	a0,ffffffffc0202eee <swap_init+0x512>

     insert_vma_struct(mm, vma);
ffffffffc0202ad8:	6962                	ld	s2,24(sp)
ffffffffc0202ada:	854a                	mv	a0,s2
ffffffffc0202adc:	3a3000ef          	jal	ffffffffc020367e <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202ae0:	00003517          	auipc	a0,0x3
ffffffffc0202ae4:	e0050513          	addi	a0,a0,-512 # ffffffffc02058e0 <etext+0x1390>
ffffffffc0202ae8:	dd2fd0ef          	jal	ffffffffc02000ba <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202aec:	01893503          	ld	a0,24(s2)
ffffffffc0202af0:	4605                	li	a2,1
ffffffffc0202af2:	6585                	lui	a1,0x1
ffffffffc0202af4:	c19fe0ef          	jal	ffffffffc020170c <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0202af8:	40050b63          	beqz	a0,ffffffffc0202f0e <swap_init+0x532>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202afc:	00003517          	auipc	a0,0x3
ffffffffc0202b00:	e3450513          	addi	a0,a0,-460 # ffffffffc0205930 <etext+0x13e0>
ffffffffc0202b04:	0000e917          	auipc	s2,0xe
ffffffffc0202b08:	57490913          	addi	s2,s2,1396 # ffffffffc0211078 <check_rp>
ffffffffc0202b0c:	daefd0ef          	jal	ffffffffc02000ba <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202b10:	0000ea17          	auipc	s4,0xe
ffffffffc0202b14:	588a0a13          	addi	s4,s4,1416 # ffffffffc0211098 <swap_out_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202b18:	8c4a                	mv	s8,s2
          check_rp[i] = alloc_page();
ffffffffc0202b1a:	4505                	li	a0,1
ffffffffc0202b1c:	ae7fe0ef          	jal	ffffffffc0201602 <alloc_pages>
ffffffffc0202b20:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc0202b24:	2a050d63          	beqz	a0,ffffffffc0202dde <swap_init+0x402>
ffffffffc0202b28:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202b2a:	8b89                	andi	a5,a5,2
ffffffffc0202b2c:	28079963          	bnez	a5,ffffffffc0202dbe <swap_init+0x3e2>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202b30:	0c21                	addi	s8,s8,8
ffffffffc0202b32:	ff4c14e3          	bne	s8,s4,ffffffffc0202b1a <swap_init+0x13e>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202b36:	609c                	ld	a5,0(s1)
ffffffffc0202b38:	0084bd83          	ld	s11,8(s1)
    elm->prev = elm->next = elm;
ffffffffc0202b3c:	e084                	sd	s1,0(s1)
ffffffffc0202b3e:	f03e                	sd	a5,32(sp)
     list_init(&free_list);
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
ffffffffc0202b40:	489c                	lw	a5,16(s1)
ffffffffc0202b42:	e484                	sd	s1,8(s1)
     nr_free = 0;
ffffffffc0202b44:	0000ec17          	auipc	s8,0xe
ffffffffc0202b48:	534c0c13          	addi	s8,s8,1332 # ffffffffc0211078 <check_rp>
     unsigned int nr_free_store = nr_free;
ffffffffc0202b4c:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc0202b4e:	0000e797          	auipc	a5,0xe
ffffffffc0202b52:	5007a123          	sw	zero,1282(a5) # ffffffffc0211050 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202b56:	000c3503          	ld	a0,0(s8)
ffffffffc0202b5a:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202b5c:	0c21                	addi	s8,s8,8
        free_pages(check_rp[i],1);
ffffffffc0202b5e:	b35fe0ef          	jal	ffffffffc0201692 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202b62:	ff4c1ae3          	bne	s8,s4,ffffffffc0202b56 <swap_init+0x17a>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202b66:	0104ac03          	lw	s8,16(s1)
ffffffffc0202b6a:	4791                	li	a5,4
ffffffffc0202b6c:	4efc1163          	bne	s8,a5,ffffffffc020304e <swap_init+0x672>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202b70:	00003517          	auipc	a0,0x3
ffffffffc0202b74:	e4850513          	addi	a0,a0,-440 # ffffffffc02059b8 <etext+0x1468>
ffffffffc0202b78:	d42fd0ef          	jal	ffffffffc02000ba <cprintf>
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202b7c:	0000f797          	auipc	a5,0xf
ffffffffc0202b80:	9e07a623          	sw	zero,-1556(a5) # ffffffffc0211568 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202b84:	6785                	lui	a5,0x1
ffffffffc0202b86:	4529                	li	a0,10
ffffffffc0202b88:	00a78023          	sb	a0,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0202b8c:	0000f597          	auipc	a1,0xf
ffffffffc0202b90:	9dc5a583          	lw	a1,-1572(a1) # ffffffffc0211568 <pgfault_num>
ffffffffc0202b94:	4605                	li	a2,1
ffffffffc0202b96:	0000f797          	auipc	a5,0xf
ffffffffc0202b9a:	9d278793          	addi	a5,a5,-1582 # ffffffffc0211568 <pgfault_num>
ffffffffc0202b9e:	42c59863          	bne	a1,a2,ffffffffc0202fce <swap_init+0x5f2>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202ba2:	6605                	lui	a2,0x1
ffffffffc0202ba4:	00a60823          	sb	a0,16(a2) # 1010 <kern_entry-0xffffffffc01feff0>
     assert(pgfault_num==1);
ffffffffc0202ba8:	4388                	lw	a0,0(a5)
ffffffffc0202baa:	44b51263          	bne	a0,a1,ffffffffc0202fee <swap_init+0x612>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202bae:	6609                	lui	a2,0x2
ffffffffc0202bb0:	45ad                	li	a1,11
ffffffffc0202bb2:	00b60023          	sb	a1,0(a2) # 2000 <kern_entry-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0202bb6:	4390                	lw	a2,0(a5)
ffffffffc0202bb8:	4809                	li	a6,2
ffffffffc0202bba:	0006051b          	sext.w	a0,a2
ffffffffc0202bbe:	39061863          	bne	a2,a6,ffffffffc0202f4e <swap_init+0x572>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202bc2:	6609                	lui	a2,0x2
ffffffffc0202bc4:	00b60823          	sb	a1,16(a2) # 2010 <kern_entry-0xffffffffc01fdff0>
     assert(pgfault_num==2);
ffffffffc0202bc8:	438c                	lw	a1,0(a5)
ffffffffc0202bca:	3aa59263          	bne	a1,a0,ffffffffc0202f6e <swap_init+0x592>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202bce:	660d                	lui	a2,0x3
ffffffffc0202bd0:	45b1                	li	a1,12
ffffffffc0202bd2:	00b60023          	sb	a1,0(a2) # 3000 <kern_entry-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0202bd6:	4390                	lw	a2,0(a5)
ffffffffc0202bd8:	480d                	li	a6,3
ffffffffc0202bda:	0006051b          	sext.w	a0,a2
ffffffffc0202bde:	3b061863          	bne	a2,a6,ffffffffc0202f8e <swap_init+0x5b2>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202be2:	660d                	lui	a2,0x3
ffffffffc0202be4:	00b60823          	sb	a1,16(a2) # 3010 <kern_entry-0xffffffffc01fcff0>
     assert(pgfault_num==3);
ffffffffc0202be8:	438c                	lw	a1,0(a5)
ffffffffc0202bea:	3ca59263          	bne	a1,a0,ffffffffc0202fae <swap_init+0x5d2>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202bee:	6611                	lui	a2,0x4
ffffffffc0202bf0:	45b5                	li	a1,13
ffffffffc0202bf2:	00b60023          	sb	a1,0(a2) # 4000 <kern_entry-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0202bf6:	4390                	lw	a2,0(a5)
ffffffffc0202bf8:	0006051b          	sext.w	a0,a2
ffffffffc0202bfc:	25861963          	bne	a2,s8,ffffffffc0202e4e <swap_init+0x472>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202c00:	6611                	lui	a2,0x4
ffffffffc0202c02:	00b60823          	sb	a1,16(a2) # 4010 <kern_entry-0xffffffffc01fbff0>
     assert(pgfault_num==4);
ffffffffc0202c06:	439c                	lw	a5,0(a5)
ffffffffc0202c08:	26a79363          	bne	a5,a0,ffffffffc0202e6e <swap_init+0x492>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0202c0c:	489c                	lw	a5,16(s1)
ffffffffc0202c0e:	28079063          	bnez	a5,ffffffffc0202e8e <swap_init+0x4b2>
ffffffffc0202c12:	0000e797          	auipc	a5,0xe
ffffffffc0202c16:	4ae78793          	addi	a5,a5,1198 # ffffffffc02110c0 <swap_in_seq_no>
ffffffffc0202c1a:	0000e617          	auipc	a2,0xe
ffffffffc0202c1e:	47e60613          	addi	a2,a2,1150 # ffffffffc0211098 <swap_out_seq_no>
ffffffffc0202c22:	0000e517          	auipc	a0,0xe
ffffffffc0202c26:	4c650513          	addi	a0,a0,1222 # ffffffffc02110e8 <pra_list_head>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202c2a:	55fd                	li	a1,-1
ffffffffc0202c2c:	c38c                	sw	a1,0(a5)
ffffffffc0202c2e:	c20c                	sw	a1,0(a2)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202c30:	0791                	addi	a5,a5,4
ffffffffc0202c32:	0611                	addi	a2,a2,4
ffffffffc0202c34:	fea79ce3          	bne	a5,a0,ffffffffc0202c2c <swap_init+0x250>
ffffffffc0202c38:	0000e817          	auipc	a6,0xe
ffffffffc0202c3c:	42080813          	addi	a6,a6,1056 # ffffffffc0211058 <check_ptep>
ffffffffc0202c40:	0000e897          	auipc	a7,0xe
ffffffffc0202c44:	43888893          	addi	a7,a7,1080 # ffffffffc0211078 <check_rp>
ffffffffc0202c48:	6a85                	lui	s5,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202c4a:	0000fb97          	auipc	s7,0xf
ffffffffc0202c4e:	8eeb8b93          	addi	s7,s7,-1810 # ffffffffc0211538 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c52:	0000fc17          	auipc	s8,0xf
ffffffffc0202c56:	8eec0c13          	addi	s8,s8,-1810 # ffffffffc0211540 <pages>
ffffffffc0202c5a:	00003c97          	auipc	s9,0x3
ffffffffc0202c5e:	746c8c93          	addi	s9,s9,1862 # ffffffffc02063a0 <nbase>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c62:	6542                	ld	a0,16(sp)
         check_ptep[i]=0;
ffffffffc0202c64:	00083023          	sd	zero,0(a6)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c68:	4601                	li	a2,0
ffffffffc0202c6a:	85d6                	mv	a1,s5
ffffffffc0202c6c:	e446                	sd	a7,8(sp)
         check_ptep[i]=0;
ffffffffc0202c6e:	e042                	sd	a6,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c70:	a9dfe0ef          	jal	ffffffffc020170c <get_pte>
ffffffffc0202c74:	6802                	ld	a6,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202c76:	68a2                	ld	a7,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c78:	00a83023          	sd	a0,0(a6)
         assert(check_ptep[i] != NULL);
ffffffffc0202c7c:	1a050963          	beqz	a0,ffffffffc0202e2e <swap_init+0x452>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202c80:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202c82:	0017f613          	andi	a2,a5,1
ffffffffc0202c86:	10060463          	beqz	a2,ffffffffc0202d8e <swap_init+0x3b2>
    if (PPN(pa) >= npage) {
ffffffffc0202c8a:	000bb603          	ld	a2,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202c8e:	078a                	slli	a5,a5,0x2
ffffffffc0202c90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202c92:	10c7fa63          	bgeu	a5,a2,ffffffffc0202da6 <swap_init+0x3ca>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c96:	000cb603          	ld	a2,0(s9)
ffffffffc0202c9a:	000c3503          	ld	a0,0(s8)
ffffffffc0202c9e:	0008bf03          	ld	t5,0(a7)
ffffffffc0202ca2:	8f91                	sub	a5,a5,a2
ffffffffc0202ca4:	00379613          	slli	a2,a5,0x3
ffffffffc0202ca8:	97b2                	add	a5,a5,a2
ffffffffc0202caa:	078e                	slli	a5,a5,0x3
ffffffffc0202cac:	6705                	lui	a4,0x1
ffffffffc0202cae:	97aa                	add	a5,a5,a0
ffffffffc0202cb0:	08a1                	addi	a7,a7,8
ffffffffc0202cb2:	0821                	addi	a6,a6,8
ffffffffc0202cb4:	9aba                	add	s5,s5,a4
ffffffffc0202cb6:	0aff1c63          	bne	t5,a5,ffffffffc0202d6e <swap_init+0x392>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202cba:	6795                	lui	a5,0x5
ffffffffc0202cbc:	fafa93e3          	bne	s5,a5,ffffffffc0202c62 <swap_init+0x286>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202cc0:	00003517          	auipc	a0,0x3
ffffffffc0202cc4:	da050513          	addi	a0,a0,-608 # ffffffffc0205a60 <etext+0x1510>
ffffffffc0202cc8:	bf2fd0ef          	jal	ffffffffc02000ba <cprintf>
    int ret = sm->check_swap();
ffffffffc0202ccc:	000b3783          	ld	a5,0(s6)
ffffffffc0202cd0:	7f9c                	ld	a5,56(a5)
ffffffffc0202cd2:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0202cd4:	1c051d63          	bnez	a0,ffffffffc0202eae <swap_init+0x4d2>
     
     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0202cd8:	00093503          	ld	a0,0(s2)
ffffffffc0202cdc:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202cde:	0921                	addi	s2,s2,8
         free_pages(check_rp[i],1);
ffffffffc0202ce0:	9b3fe0ef          	jal	ffffffffc0201692 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202ce4:	ff491ae3          	bne	s2,s4,ffffffffc0202cd8 <swap_init+0x2fc>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0202ce8:	6562                	ld	a0,24(sp)
ffffffffc0202cea:	265000ef          	jal	ffffffffc020374e <mm_destroy>
         
     nr_free = nr_free_store;
ffffffffc0202cee:	77a2                	ld	a5,40(sp)
     free_list = free_list_store;
ffffffffc0202cf0:	01b4b423          	sd	s11,8(s1)
     nr_free = nr_free_store;
ffffffffc0202cf4:	c89c                	sw	a5,16(s1)
     free_list = free_list_store;
ffffffffc0202cf6:	7782                	ld	a5,32(sp)
ffffffffc0202cf8:	e09c                	sd	a5,0(s1)

     
     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202cfa:	009d8a63          	beq	s11,s1,ffffffffc0202d0e <swap_init+0x332>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0202cfe:	ff8da783          	lw	a5,-8(s11)
    return listelm->next;
ffffffffc0202d02:	008dbd83          	ld	s11,8(s11)
ffffffffc0202d06:	3d7d                	addiw	s10,s10,-1
ffffffffc0202d08:	9c1d                	subw	s0,s0,a5
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202d0a:	fe9d9ae3          	bne	s11,s1,ffffffffc0202cfe <swap_init+0x322>
     }
     cprintf("count is %d, total is %d\n",count,total);
ffffffffc0202d0e:	8622                	mv	a2,s0
ffffffffc0202d10:	85ea                	mv	a1,s10
ffffffffc0202d12:	00003517          	auipc	a0,0x3
ffffffffc0202d16:	d7e50513          	addi	a0,a0,-642 # ffffffffc0205a90 <etext+0x1540>
ffffffffc0202d1a:	ba0fd0ef          	jal	ffffffffc02000ba <cprintf>
     //assert(count == 0);
     
     cprintf("check_swap() succeeded!\n");
ffffffffc0202d1e:	00003517          	auipc	a0,0x3
ffffffffc0202d22:	d9250513          	addi	a0,a0,-622 # ffffffffc0205ab0 <etext+0x1560>
ffffffffc0202d26:	b94fd0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc0202d2a:	60ea                	ld	ra,152(sp)
     cprintf("check_swap() succeeded!\n");
ffffffffc0202d2c:	644a                	ld	s0,144(sp)
ffffffffc0202d2e:	64aa                	ld	s1,136(sp)
ffffffffc0202d30:	690a                	ld	s2,128(sp)
ffffffffc0202d32:	7a46                	ld	s4,112(sp)
ffffffffc0202d34:	7aa6                	ld	s5,104(sp)
ffffffffc0202d36:	6be6                	ld	s7,88(sp)
ffffffffc0202d38:	6c46                	ld	s8,80(sp)
ffffffffc0202d3a:	6ca6                	ld	s9,72(sp)
ffffffffc0202d3c:	6d06                	ld	s10,64(sp)
ffffffffc0202d3e:	7de2                	ld	s11,56(sp)
}
ffffffffc0202d40:	7b06                	ld	s6,96(sp)
ffffffffc0202d42:	854e                	mv	a0,s3
ffffffffc0202d44:	79e6                	ld	s3,120(sp)
ffffffffc0202d46:	610d                	addi	sp,sp,160
ffffffffc0202d48:	8082                	ret
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202d4a:	4901                	li	s2,0
ffffffffc0202d4c:	bb1d                	j	ffffffffc0202a82 <swap_init+0xa6>
        assert(PageProperty(p));
ffffffffc0202d4e:	00002697          	auipc	a3,0x2
ffffffffc0202d52:	0ca68693          	addi	a3,a3,202 # ffffffffc0204e18 <etext+0x8c8>
ffffffffc0202d56:	00002617          	auipc	a2,0x2
ffffffffc0202d5a:	0d260613          	addi	a2,a2,210 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202d5e:	0ba00593          	li	a1,186
ffffffffc0202d62:	00003517          	auipc	a0,0x3
ffffffffc0202d66:	ae650513          	addi	a0,a0,-1306 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202d6a:	df6fd0ef          	jal	ffffffffc0200360 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202d6e:	00003697          	auipc	a3,0x3
ffffffffc0202d72:	cca68693          	addi	a3,a3,-822 # ffffffffc0205a38 <etext+0x14e8>
ffffffffc0202d76:	00002617          	auipc	a2,0x2
ffffffffc0202d7a:	0b260613          	addi	a2,a2,178 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202d7e:	0fa00593          	li	a1,250
ffffffffc0202d82:	00003517          	auipc	a0,0x3
ffffffffc0202d86:	ac650513          	addi	a0,a0,-1338 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202d8a:	dd6fd0ef          	jal	ffffffffc0200360 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202d8e:	00002617          	auipc	a2,0x2
ffffffffc0202d92:	47a60613          	addi	a2,a2,1146 # ffffffffc0205208 <etext+0xcb8>
ffffffffc0202d96:	07000593          	li	a1,112
ffffffffc0202d9a:	00002517          	auipc	a0,0x2
ffffffffc0202d9e:	45e50513          	addi	a0,a0,1118 # ffffffffc02051f8 <etext+0xca8>
ffffffffc0202da2:	dbefd0ef          	jal	ffffffffc0200360 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202da6:	00002617          	auipc	a2,0x2
ffffffffc0202daa:	43260613          	addi	a2,a2,1074 # ffffffffc02051d8 <etext+0xc88>
ffffffffc0202dae:	06500593          	li	a1,101
ffffffffc0202db2:	00002517          	auipc	a0,0x2
ffffffffc0202db6:	44650513          	addi	a0,a0,1094 # ffffffffc02051f8 <etext+0xca8>
ffffffffc0202dba:	da6fd0ef          	jal	ffffffffc0200360 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202dbe:	00003697          	auipc	a3,0x3
ffffffffc0202dc2:	bb268693          	addi	a3,a3,-1102 # ffffffffc0205970 <etext+0x1420>
ffffffffc0202dc6:	00002617          	auipc	a2,0x2
ffffffffc0202dca:	06260613          	addi	a2,a2,98 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202dce:	0db00593          	li	a1,219
ffffffffc0202dd2:	00003517          	auipc	a0,0x3
ffffffffc0202dd6:	a7650513          	addi	a0,a0,-1418 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202dda:	d86fd0ef          	jal	ffffffffc0200360 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202dde:	00003697          	auipc	a3,0x3
ffffffffc0202de2:	b7a68693          	addi	a3,a3,-1158 # ffffffffc0205958 <etext+0x1408>
ffffffffc0202de6:	00002617          	auipc	a2,0x2
ffffffffc0202dea:	04260613          	addi	a2,a2,66 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202dee:	0da00593          	li	a1,218
ffffffffc0202df2:	00003517          	auipc	a0,0x3
ffffffffc0202df6:	a5650513          	addi	a0,a0,-1450 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202dfa:	d66fd0ef          	jal	ffffffffc0200360 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202dfe:	00003617          	auipc	a2,0x3
ffffffffc0202e02:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0205828 <etext+0x12d8>
ffffffffc0202e06:	02700593          	li	a1,39
ffffffffc0202e0a:	00003517          	auipc	a0,0x3
ffffffffc0202e0e:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202e12:	e922                	sd	s0,144(sp)
ffffffffc0202e14:	e526                	sd	s1,136(sp)
ffffffffc0202e16:	e14a                	sd	s2,128(sp)
ffffffffc0202e18:	fcce                	sd	s3,120(sp)
ffffffffc0202e1a:	f8d2                	sd	s4,112(sp)
ffffffffc0202e1c:	f4d6                	sd	s5,104(sp)
ffffffffc0202e1e:	f0da                	sd	s6,96(sp)
ffffffffc0202e20:	ecde                	sd	s7,88(sp)
ffffffffc0202e22:	e8e2                	sd	s8,80(sp)
ffffffffc0202e24:	e4e6                	sd	s9,72(sp)
ffffffffc0202e26:	e0ea                	sd	s10,64(sp)
ffffffffc0202e28:	fc6e                	sd	s11,56(sp)
ffffffffc0202e2a:	d36fd0ef          	jal	ffffffffc0200360 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202e2e:	00003697          	auipc	a3,0x3
ffffffffc0202e32:	bf268693          	addi	a3,a3,-1038 # ffffffffc0205a20 <etext+0x14d0>
ffffffffc0202e36:	00002617          	auipc	a2,0x2
ffffffffc0202e3a:	ff260613          	addi	a2,a2,-14 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202e3e:	0f900593          	li	a1,249
ffffffffc0202e42:	00003517          	auipc	a0,0x3
ffffffffc0202e46:	a0650513          	addi	a0,a0,-1530 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202e4a:	d16fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==4);
ffffffffc0202e4e:	00003697          	auipc	a3,0x3
ffffffffc0202e52:	bc268693          	addi	a3,a3,-1086 # ffffffffc0205a10 <etext+0x14c0>
ffffffffc0202e56:	00002617          	auipc	a2,0x2
ffffffffc0202e5a:	fd260613          	addi	a2,a2,-46 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202e5e:	09d00593          	li	a1,157
ffffffffc0202e62:	00003517          	auipc	a0,0x3
ffffffffc0202e66:	9e650513          	addi	a0,a0,-1562 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202e6a:	cf6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==4);
ffffffffc0202e6e:	00003697          	auipc	a3,0x3
ffffffffc0202e72:	ba268693          	addi	a3,a3,-1118 # ffffffffc0205a10 <etext+0x14c0>
ffffffffc0202e76:	00002617          	auipc	a2,0x2
ffffffffc0202e7a:	fb260613          	addi	a2,a2,-78 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202e7e:	09f00593          	li	a1,159
ffffffffc0202e82:	00003517          	auipc	a0,0x3
ffffffffc0202e86:	9c650513          	addi	a0,a0,-1594 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202e8a:	cd6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert( nr_free == 0);         
ffffffffc0202e8e:	00002697          	auipc	a3,0x2
ffffffffc0202e92:	17268693          	addi	a3,a3,370 # ffffffffc0205000 <etext+0xab0>
ffffffffc0202e96:	00002617          	auipc	a2,0x2
ffffffffc0202e9a:	f9260613          	addi	a2,a2,-110 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202e9e:	0f100593          	li	a1,241
ffffffffc0202ea2:	00003517          	auipc	a0,0x3
ffffffffc0202ea6:	9a650513          	addi	a0,a0,-1626 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202eaa:	cb6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(ret==0);
ffffffffc0202eae:	00003697          	auipc	a3,0x3
ffffffffc0202eb2:	bda68693          	addi	a3,a3,-1062 # ffffffffc0205a88 <etext+0x1538>
ffffffffc0202eb6:	00002617          	auipc	a2,0x2
ffffffffc0202eba:	f7260613          	addi	a2,a2,-142 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202ebe:	10000593          	li	a1,256
ffffffffc0202ec2:	00003517          	auipc	a0,0x3
ffffffffc0202ec6:	98650513          	addi	a0,a0,-1658 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202eca:	c96fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202ece:	00003697          	auipc	a3,0x3
ffffffffc0202ed2:	9f268693          	addi	a3,a3,-1550 # ffffffffc02058c0 <etext+0x1370>
ffffffffc0202ed6:	00002617          	auipc	a2,0x2
ffffffffc0202eda:	f5260613          	addi	a2,a2,-174 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202ede:	0ca00593          	li	a1,202
ffffffffc0202ee2:	00003517          	auipc	a0,0x3
ffffffffc0202ee6:	96650513          	addi	a0,a0,-1690 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202eea:	c76fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(vma != NULL);
ffffffffc0202eee:	00003697          	auipc	a3,0x3
ffffffffc0202ef2:	9e268693          	addi	a3,a3,-1566 # ffffffffc02058d0 <etext+0x1380>
ffffffffc0202ef6:	00002617          	auipc	a2,0x2
ffffffffc0202efa:	f3260613          	addi	a2,a2,-206 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202efe:	0cd00593          	li	a1,205
ffffffffc0202f02:	00003517          	auipc	a0,0x3
ffffffffc0202f06:	94650513          	addi	a0,a0,-1722 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202f0a:	c56fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0202f0e:	00003697          	auipc	a3,0x3
ffffffffc0202f12:	a0a68693          	addi	a3,a3,-1526 # ffffffffc0205918 <etext+0x13c8>
ffffffffc0202f16:	00002617          	auipc	a2,0x2
ffffffffc0202f1a:	f1260613          	addi	a2,a2,-238 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202f1e:	0d500593          	li	a1,213
ffffffffc0202f22:	00003517          	auipc	a0,0x3
ffffffffc0202f26:	92650513          	addi	a0,a0,-1754 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202f2a:	c36fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202f2e:	00002697          	auipc	a3,0x2
ffffffffc0202f32:	f2a68693          	addi	a3,a3,-214 # ffffffffc0204e58 <etext+0x908>
ffffffffc0202f36:	00002617          	auipc	a2,0x2
ffffffffc0202f3a:	ef260613          	addi	a2,a2,-270 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202f3e:	0bd00593          	li	a1,189
ffffffffc0202f42:	00003517          	auipc	a0,0x3
ffffffffc0202f46:	90650513          	addi	a0,a0,-1786 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202f4a:	c16fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==2);
ffffffffc0202f4e:	00003697          	auipc	a3,0x3
ffffffffc0202f52:	aa268693          	addi	a3,a3,-1374 # ffffffffc02059f0 <etext+0x14a0>
ffffffffc0202f56:	00002617          	auipc	a2,0x2
ffffffffc0202f5a:	ed260613          	addi	a2,a2,-302 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202f5e:	09500593          	li	a1,149
ffffffffc0202f62:	00003517          	auipc	a0,0x3
ffffffffc0202f66:	8e650513          	addi	a0,a0,-1818 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202f6a:	bf6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==2);
ffffffffc0202f6e:	00003697          	auipc	a3,0x3
ffffffffc0202f72:	a8268693          	addi	a3,a3,-1406 # ffffffffc02059f0 <etext+0x14a0>
ffffffffc0202f76:	00002617          	auipc	a2,0x2
ffffffffc0202f7a:	eb260613          	addi	a2,a2,-334 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202f7e:	09700593          	li	a1,151
ffffffffc0202f82:	00003517          	auipc	a0,0x3
ffffffffc0202f86:	8c650513          	addi	a0,a0,-1850 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202f8a:	bd6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==3);
ffffffffc0202f8e:	00003697          	auipc	a3,0x3
ffffffffc0202f92:	a7268693          	addi	a3,a3,-1422 # ffffffffc0205a00 <etext+0x14b0>
ffffffffc0202f96:	00002617          	auipc	a2,0x2
ffffffffc0202f9a:	e9260613          	addi	a2,a2,-366 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202f9e:	09900593          	li	a1,153
ffffffffc0202fa2:	00003517          	auipc	a0,0x3
ffffffffc0202fa6:	8a650513          	addi	a0,a0,-1882 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202faa:	bb6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==3);
ffffffffc0202fae:	00003697          	auipc	a3,0x3
ffffffffc0202fb2:	a5268693          	addi	a3,a3,-1454 # ffffffffc0205a00 <etext+0x14b0>
ffffffffc0202fb6:	00002617          	auipc	a2,0x2
ffffffffc0202fba:	e7260613          	addi	a2,a2,-398 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202fbe:	09b00593          	li	a1,155
ffffffffc0202fc2:	00003517          	auipc	a0,0x3
ffffffffc0202fc6:	88650513          	addi	a0,a0,-1914 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202fca:	b96fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==1);
ffffffffc0202fce:	00003697          	auipc	a3,0x3
ffffffffc0202fd2:	a1268693          	addi	a3,a3,-1518 # ffffffffc02059e0 <etext+0x1490>
ffffffffc0202fd6:	00002617          	auipc	a2,0x2
ffffffffc0202fda:	e5260613          	addi	a2,a2,-430 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202fde:	09100593          	li	a1,145
ffffffffc0202fe2:	00003517          	auipc	a0,0x3
ffffffffc0202fe6:	86650513          	addi	a0,a0,-1946 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0202fea:	b76fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==1);
ffffffffc0202fee:	00003697          	auipc	a3,0x3
ffffffffc0202ff2:	9f268693          	addi	a3,a3,-1550 # ffffffffc02059e0 <etext+0x1490>
ffffffffc0202ff6:	00002617          	auipc	a2,0x2
ffffffffc0202ffa:	e3260613          	addi	a2,a2,-462 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0202ffe:	09300593          	li	a1,147
ffffffffc0203002:	00003517          	auipc	a0,0x3
ffffffffc0203006:	84650513          	addi	a0,a0,-1978 # ffffffffc0205848 <etext+0x12f8>
ffffffffc020300a:	b56fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(mm != NULL);
ffffffffc020300e:	00003697          	auipc	a3,0x3
ffffffffc0203012:	88a68693          	addi	a3,a3,-1910 # ffffffffc0205898 <etext+0x1348>
ffffffffc0203016:	00002617          	auipc	a2,0x2
ffffffffc020301a:	e1260613          	addi	a2,a2,-494 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020301e:	0c200593          	li	a1,194
ffffffffc0203022:	00003517          	auipc	a0,0x3
ffffffffc0203026:	82650513          	addi	a0,a0,-2010 # ffffffffc0205848 <etext+0x12f8>
ffffffffc020302a:	b36fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc020302e:	00003697          	auipc	a3,0x3
ffffffffc0203032:	87a68693          	addi	a3,a3,-1926 # ffffffffc02058a8 <etext+0x1358>
ffffffffc0203036:	00002617          	auipc	a2,0x2
ffffffffc020303a:	df260613          	addi	a2,a2,-526 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020303e:	0c500593          	li	a1,197
ffffffffc0203042:	00003517          	auipc	a0,0x3
ffffffffc0203046:	80650513          	addi	a0,a0,-2042 # ffffffffc0205848 <etext+0x12f8>
ffffffffc020304a:	b16fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc020304e:	00003697          	auipc	a3,0x3
ffffffffc0203052:	94268693          	addi	a3,a3,-1726 # ffffffffc0205990 <etext+0x1440>
ffffffffc0203056:	00002617          	auipc	a2,0x2
ffffffffc020305a:	dd260613          	addi	a2,a2,-558 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020305e:	0e800593          	li	a1,232
ffffffffc0203062:	00002517          	auipc	a0,0x2
ffffffffc0203066:	7e650513          	addi	a0,a0,2022 # ffffffffc0205848 <etext+0x12f8>
ffffffffc020306a:	af6fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020306e <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc020306e:	0000e797          	auipc	a5,0xe
ffffffffc0203072:	4ea7b783          	ld	a5,1258(a5) # ffffffffc0211558 <sm>
ffffffffc0203076:	6b9c                	ld	a5,16(a5)
ffffffffc0203078:	8782                	jr	a5

ffffffffc020307a <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc020307a:	0000e797          	auipc	a5,0xe
ffffffffc020307e:	4de7b783          	ld	a5,1246(a5) # ffffffffc0211558 <sm>
ffffffffc0203082:	739c                	ld	a5,32(a5)
ffffffffc0203084:	8782                	jr	a5

ffffffffc0203086 <swap_out>:
{
ffffffffc0203086:	711d                	addi	sp,sp,-96
ffffffffc0203088:	ec86                	sd	ra,88(sp)
ffffffffc020308a:	e8a2                	sd	s0,80(sp)
     for (i = 0; i != n; ++ i)
ffffffffc020308c:	0e058663          	beqz	a1,ffffffffc0203178 <swap_out+0xf2>
ffffffffc0203090:	e0ca                	sd	s2,64(sp)
ffffffffc0203092:	fc4e                	sd	s3,56(sp)
ffffffffc0203094:	f852                	sd	s4,48(sp)
ffffffffc0203096:	f456                	sd	s5,40(sp)
ffffffffc0203098:	f05a                	sd	s6,32(sp)
ffffffffc020309a:	ec5e                	sd	s7,24(sp)
ffffffffc020309c:	e4a6                	sd	s1,72(sp)
ffffffffc020309e:	e862                	sd	s8,16(sp)
ffffffffc02030a0:	8a2e                	mv	s4,a1
ffffffffc02030a2:	892a                	mv	s2,a0
ffffffffc02030a4:	8ab2                	mv	s5,a2
ffffffffc02030a6:	4401                	li	s0,0
ffffffffc02030a8:	0000e997          	auipc	s3,0xe
ffffffffc02030ac:	4b098993          	addi	s3,s3,1200 # ffffffffc0211558 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02030b0:	00003b17          	auipc	s6,0x3
ffffffffc02030b4:	a80b0b13          	addi	s6,s6,-1408 # ffffffffc0205b30 <etext+0x15e0>
                    cprintf("SWAP: failed to save\n");
ffffffffc02030b8:	00003b97          	auipc	s7,0x3
ffffffffc02030bc:	a60b8b93          	addi	s7,s7,-1440 # ffffffffc0205b18 <etext+0x15c8>
ffffffffc02030c0:	a825                	j	ffffffffc02030f8 <swap_out+0x72>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02030c2:	67a2                	ld	a5,8(sp)
ffffffffc02030c4:	8626                	mv	a2,s1
ffffffffc02030c6:	85a2                	mv	a1,s0
ffffffffc02030c8:	63b4                	ld	a3,64(a5)
ffffffffc02030ca:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc02030cc:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02030ce:	82b1                	srli	a3,a3,0xc
ffffffffc02030d0:	0685                	addi	a3,a3,1
ffffffffc02030d2:	fe9fc0ef          	jal	ffffffffc02000ba <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc02030d6:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc02030d8:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc02030da:	613c                	ld	a5,64(a0)
ffffffffc02030dc:	83b1                	srli	a5,a5,0xc
ffffffffc02030de:	0785                	addi	a5,a5,1
ffffffffc02030e0:	07a2                	slli	a5,a5,0x8
ffffffffc02030e2:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc02030e6:	dacfe0ef          	jal	ffffffffc0201692 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc02030ea:	01893503          	ld	a0,24(s2)
ffffffffc02030ee:	85a6                	mv	a1,s1
ffffffffc02030f0:	e7aff0ef          	jal	ffffffffc020276a <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc02030f4:	048a0d63          	beq	s4,s0,ffffffffc020314e <swap_out+0xc8>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc02030f8:	0009b783          	ld	a5,0(s3)
ffffffffc02030fc:	8656                	mv	a2,s5
ffffffffc02030fe:	002c                	addi	a1,sp,8
ffffffffc0203100:	7b9c                	ld	a5,48(a5)
ffffffffc0203102:	854a                	mv	a0,s2
ffffffffc0203104:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203106:	e12d                	bnez	a0,ffffffffc0203168 <swap_out+0xe2>
          v=page->pra_vaddr; 
ffffffffc0203108:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020310a:	01893503          	ld	a0,24(s2)
ffffffffc020310e:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203110:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203112:	85a6                	mv	a1,s1
ffffffffc0203114:	df8fe0ef          	jal	ffffffffc020170c <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203118:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020311a:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc020311c:	8b85                	andi	a5,a5,1
ffffffffc020311e:	cfb9                	beqz	a5,ffffffffc020317c <swap_out+0xf6>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203120:	65a2                	ld	a1,8(sp)
ffffffffc0203122:	61bc                	ld	a5,64(a1)
ffffffffc0203124:	83b1                	srli	a5,a5,0xc
ffffffffc0203126:	0785                	addi	a5,a5,1
ffffffffc0203128:	00879513          	slli	a0,a5,0x8
ffffffffc020312c:	61d000ef          	jal	ffffffffc0203f48 <swapfs_write>
ffffffffc0203130:	d949                	beqz	a0,ffffffffc02030c2 <swap_out+0x3c>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203132:	855e                	mv	a0,s7
ffffffffc0203134:	f87fc0ef          	jal	ffffffffc02000ba <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203138:	0009b783          	ld	a5,0(s3)
ffffffffc020313c:	6622                	ld	a2,8(sp)
ffffffffc020313e:	4681                	li	a3,0
ffffffffc0203140:	739c                	ld	a5,32(a5)
ffffffffc0203142:	85a6                	mv	a1,s1
ffffffffc0203144:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203146:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203148:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc020314a:	fa8a17e3          	bne	s4,s0,ffffffffc02030f8 <swap_out+0x72>
ffffffffc020314e:	64a6                	ld	s1,72(sp)
ffffffffc0203150:	6906                	ld	s2,64(sp)
ffffffffc0203152:	79e2                	ld	s3,56(sp)
ffffffffc0203154:	7a42                	ld	s4,48(sp)
ffffffffc0203156:	7aa2                	ld	s5,40(sp)
ffffffffc0203158:	7b02                	ld	s6,32(sp)
ffffffffc020315a:	6be2                	ld	s7,24(sp)
ffffffffc020315c:	6c42                	ld	s8,16(sp)
}
ffffffffc020315e:	60e6                	ld	ra,88(sp)
ffffffffc0203160:	8522                	mv	a0,s0
ffffffffc0203162:	6446                	ld	s0,80(sp)
ffffffffc0203164:	6125                	addi	sp,sp,96
ffffffffc0203166:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203168:	85a2                	mv	a1,s0
ffffffffc020316a:	00003517          	auipc	a0,0x3
ffffffffc020316e:	96650513          	addi	a0,a0,-1690 # ffffffffc0205ad0 <etext+0x1580>
ffffffffc0203172:	f49fc0ef          	jal	ffffffffc02000ba <cprintf>
                  break;
ffffffffc0203176:	bfe1                	j	ffffffffc020314e <swap_out+0xc8>
     for (i = 0; i != n; ++ i)
ffffffffc0203178:	4401                	li	s0,0
ffffffffc020317a:	b7d5                	j	ffffffffc020315e <swap_out+0xd8>
          assert((*ptep & PTE_V) != 0);
ffffffffc020317c:	00003697          	auipc	a3,0x3
ffffffffc0203180:	98468693          	addi	a3,a3,-1660 # ffffffffc0205b00 <etext+0x15b0>
ffffffffc0203184:	00002617          	auipc	a2,0x2
ffffffffc0203188:	ca460613          	addi	a2,a2,-860 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020318c:	06600593          	li	a1,102
ffffffffc0203190:	00002517          	auipc	a0,0x2
ffffffffc0203194:	6b850513          	addi	a0,a0,1720 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0203198:	9c8fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020319c <swap_in>:
{
ffffffffc020319c:	7179                	addi	sp,sp,-48
ffffffffc020319e:	e84a                	sd	s2,16(sp)
ffffffffc02031a0:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc02031a2:	4505                	li	a0,1
{
ffffffffc02031a4:	ec26                	sd	s1,24(sp)
ffffffffc02031a6:	e44e                	sd	s3,8(sp)
ffffffffc02031a8:	f406                	sd	ra,40(sp)
ffffffffc02031aa:	f022                	sd	s0,32(sp)
ffffffffc02031ac:	84ae                	mv	s1,a1
ffffffffc02031ae:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc02031b0:	c52fe0ef          	jal	ffffffffc0201602 <alloc_pages>
     assert(result!=NULL);
ffffffffc02031b4:	c129                	beqz	a0,ffffffffc02031f6 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc02031b6:	842a                	mv	s0,a0
ffffffffc02031b8:	01893503          	ld	a0,24(s2)
ffffffffc02031bc:	4601                	li	a2,0
ffffffffc02031be:	85a6                	mv	a1,s1
ffffffffc02031c0:	d4cfe0ef          	jal	ffffffffc020170c <get_pte>
ffffffffc02031c4:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc02031c6:	6108                	ld	a0,0(a0)
ffffffffc02031c8:	85a2                	mv	a1,s0
ffffffffc02031ca:	4d3000ef          	jal	ffffffffc0203e9c <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc02031ce:	00093583          	ld	a1,0(s2)
ffffffffc02031d2:	8626                	mv	a2,s1
ffffffffc02031d4:	00003517          	auipc	a0,0x3
ffffffffc02031d8:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0205b80 <etext+0x1630>
ffffffffc02031dc:	81a1                	srli	a1,a1,0x8
ffffffffc02031de:	eddfc0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc02031e2:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc02031e4:	0089b023          	sd	s0,0(s3)
}
ffffffffc02031e8:	7402                	ld	s0,32(sp)
ffffffffc02031ea:	64e2                	ld	s1,24(sp)
ffffffffc02031ec:	6942                	ld	s2,16(sp)
ffffffffc02031ee:	69a2                	ld	s3,8(sp)
ffffffffc02031f0:	4501                	li	a0,0
ffffffffc02031f2:	6145                	addi	sp,sp,48
ffffffffc02031f4:	8082                	ret
     assert(result!=NULL);
ffffffffc02031f6:	00003697          	auipc	a3,0x3
ffffffffc02031fa:	97a68693          	addi	a3,a3,-1670 # ffffffffc0205b70 <etext+0x1620>
ffffffffc02031fe:	00002617          	auipc	a2,0x2
ffffffffc0203202:	c2a60613          	addi	a2,a2,-982 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203206:	07c00593          	li	a1,124
ffffffffc020320a:	00002517          	auipc	a0,0x2
ffffffffc020320e:	63e50513          	addi	a0,a0,1598 # ffffffffc0205848 <etext+0x12f8>
ffffffffc0203212:	94efd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203216 <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc0203216:	4501                	li	a0,0
ffffffffc0203218:	8082                	ret

ffffffffc020321a <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc020321a:	4501                	li	a0,0
ffffffffc020321c:	8082                	ret

ffffffffc020321e <_clock_tick_event>:

static int
_clock_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc020321e:	4501                	li	a0,0
ffffffffc0203220:	8082                	ret

ffffffffc0203222 <_clock_check_swap>:
_clock_check_swap(void) {
ffffffffc0203222:	1141                	addi	sp,sp,-16
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203224:	4731                	li	a4,12
_clock_check_swap(void) {
ffffffffc0203226:	e406                	sd	ra,8(sp)
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203228:	678d                	lui	a5,0x3
ffffffffc020322a:	00e78023          	sb	a4,0(a5) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc020322e:	0000e717          	auipc	a4,0xe
ffffffffc0203232:	33a72703          	lw	a4,826(a4) # ffffffffc0211568 <pgfault_num>
ffffffffc0203236:	4691                	li	a3,4
ffffffffc0203238:	0ad71663          	bne	a4,a3,ffffffffc02032e4 <_clock_check_swap+0xc2>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020323c:	6685                	lui	a3,0x1
ffffffffc020323e:	4629                	li	a2,10
ffffffffc0203240:	00c68023          	sb	a2,0(a3) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0203244:	0000e797          	auipc	a5,0xe
ffffffffc0203248:	32478793          	addi	a5,a5,804 # ffffffffc0211568 <pgfault_num>
    assert(pgfault_num==4);
ffffffffc020324c:	4394                	lw	a3,0(a5)
ffffffffc020324e:	0006861b          	sext.w	a2,a3
ffffffffc0203252:	20e69963          	bne	a3,a4,ffffffffc0203464 <_clock_check_swap+0x242>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203256:	6711                	lui	a4,0x4
ffffffffc0203258:	46b5                	li	a3,13
ffffffffc020325a:	00d70023          	sb	a3,0(a4) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc020325e:	4398                	lw	a4,0(a5)
ffffffffc0203260:	0007069b          	sext.w	a3,a4
ffffffffc0203264:	1ec71063          	bne	a4,a2,ffffffffc0203444 <_clock_check_swap+0x222>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203268:	6709                	lui	a4,0x2
ffffffffc020326a:	462d                	li	a2,11
ffffffffc020326c:	00c70023          	sb	a2,0(a4) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc0203270:	4398                	lw	a4,0(a5)
ffffffffc0203272:	1ad71963          	bne	a4,a3,ffffffffc0203424 <_clock_check_swap+0x202>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203276:	6715                	lui	a4,0x5
ffffffffc0203278:	46b9                	li	a3,14
ffffffffc020327a:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc020327e:	4398                	lw	a4,0(a5)
ffffffffc0203280:	4615                	li	a2,5
ffffffffc0203282:	0007069b          	sext.w	a3,a4
ffffffffc0203286:	16c71f63          	bne	a4,a2,ffffffffc0203404 <_clock_check_swap+0x1e2>
    assert(pgfault_num==5);
ffffffffc020328a:	4398                	lw	a4,0(a5)
ffffffffc020328c:	0007061b          	sext.w	a2,a4
ffffffffc0203290:	14d71a63          	bne	a4,a3,ffffffffc02033e4 <_clock_check_swap+0x1c2>
    assert(pgfault_num==5);
ffffffffc0203294:	4398                	lw	a4,0(a5)
ffffffffc0203296:	0007069b          	sext.w	a3,a4
ffffffffc020329a:	12c71563          	bne	a4,a2,ffffffffc02033c4 <_clock_check_swap+0x1a2>
    assert(pgfault_num==5);
ffffffffc020329e:	4398                	lw	a4,0(a5)
ffffffffc02032a0:	0007061b          	sext.w	a2,a4
ffffffffc02032a4:	10d71063          	bne	a4,a3,ffffffffc02033a4 <_clock_check_swap+0x182>
    assert(pgfault_num==5);
ffffffffc02032a8:	4398                	lw	a4,0(a5)
ffffffffc02032aa:	0007069b          	sext.w	a3,a4
ffffffffc02032ae:	0cc71b63          	bne	a4,a2,ffffffffc0203384 <_clock_check_swap+0x162>
    assert(pgfault_num==5);
ffffffffc02032b2:	4398                	lw	a4,0(a5)
ffffffffc02032b4:	0ad71863          	bne	a4,a3,ffffffffc0203364 <_clock_check_swap+0x142>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02032b8:	6715                	lui	a4,0x5
ffffffffc02032ba:	46b9                	li	a3,14
ffffffffc02032bc:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc02032c0:	4394                	lw	a3,0(a5)
ffffffffc02032c2:	4715                	li	a4,5
ffffffffc02032c4:	08e69063          	bne	a3,a4,ffffffffc0203344 <_clock_check_swap+0x122>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02032c8:	6705                	lui	a4,0x1
ffffffffc02032ca:	00074683          	lbu	a3,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02032ce:	4729                	li	a4,10
ffffffffc02032d0:	04e69a63          	bne	a3,a4,ffffffffc0203324 <_clock_check_swap+0x102>
    assert(pgfault_num==6);
ffffffffc02032d4:	4398                	lw	a4,0(a5)
ffffffffc02032d6:	4799                	li	a5,6
ffffffffc02032d8:	02f71663          	bne	a4,a5,ffffffffc0203304 <_clock_check_swap+0xe2>
}
ffffffffc02032dc:	60a2                	ld	ra,8(sp)
ffffffffc02032de:	4501                	li	a0,0
ffffffffc02032e0:	0141                	addi	sp,sp,16
ffffffffc02032e2:	8082                	ret
    assert(pgfault_num==4);
ffffffffc02032e4:	00002697          	auipc	a3,0x2
ffffffffc02032e8:	72c68693          	addi	a3,a3,1836 # ffffffffc0205a10 <etext+0x14c0>
ffffffffc02032ec:	00002617          	auipc	a2,0x2
ffffffffc02032f0:	b3c60613          	addi	a2,a2,-1220 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02032f4:	09800593          	li	a1,152
ffffffffc02032f8:	00003517          	auipc	a0,0x3
ffffffffc02032fc:	8c850513          	addi	a0,a0,-1848 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203300:	860fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==6);
ffffffffc0203304:	00003697          	auipc	a3,0x3
ffffffffc0203308:	90c68693          	addi	a3,a3,-1780 # ffffffffc0205c10 <etext+0x16c0>
ffffffffc020330c:	00002617          	auipc	a2,0x2
ffffffffc0203310:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203314:	0af00593          	li	a1,175
ffffffffc0203318:	00003517          	auipc	a0,0x3
ffffffffc020331c:	8a850513          	addi	a0,a0,-1880 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203320:	840fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203324:	00003697          	auipc	a3,0x3
ffffffffc0203328:	8c468693          	addi	a3,a3,-1852 # ffffffffc0205be8 <etext+0x1698>
ffffffffc020332c:	00002617          	auipc	a2,0x2
ffffffffc0203330:	afc60613          	addi	a2,a2,-1284 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203334:	0ad00593          	li	a1,173
ffffffffc0203338:	00003517          	auipc	a0,0x3
ffffffffc020333c:	88850513          	addi	a0,a0,-1912 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203340:	820fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc0203344:	00003697          	auipc	a3,0x3
ffffffffc0203348:	89468693          	addi	a3,a3,-1900 # ffffffffc0205bd8 <etext+0x1688>
ffffffffc020334c:	00002617          	auipc	a2,0x2
ffffffffc0203350:	adc60613          	addi	a2,a2,-1316 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203354:	0ac00593          	li	a1,172
ffffffffc0203358:	00003517          	auipc	a0,0x3
ffffffffc020335c:	86850513          	addi	a0,a0,-1944 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203360:	800fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc0203364:	00003697          	auipc	a3,0x3
ffffffffc0203368:	87468693          	addi	a3,a3,-1932 # ffffffffc0205bd8 <etext+0x1688>
ffffffffc020336c:	00002617          	auipc	a2,0x2
ffffffffc0203370:	abc60613          	addi	a2,a2,-1348 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203374:	0aa00593          	li	a1,170
ffffffffc0203378:	00003517          	auipc	a0,0x3
ffffffffc020337c:	84850513          	addi	a0,a0,-1976 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203380:	fe1fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc0203384:	00003697          	auipc	a3,0x3
ffffffffc0203388:	85468693          	addi	a3,a3,-1964 # ffffffffc0205bd8 <etext+0x1688>
ffffffffc020338c:	00002617          	auipc	a2,0x2
ffffffffc0203390:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203394:	0a800593          	li	a1,168
ffffffffc0203398:	00003517          	auipc	a0,0x3
ffffffffc020339c:	82850513          	addi	a0,a0,-2008 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc02033a0:	fc1fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc02033a4:	00003697          	auipc	a3,0x3
ffffffffc02033a8:	83468693          	addi	a3,a3,-1996 # ffffffffc0205bd8 <etext+0x1688>
ffffffffc02033ac:	00002617          	auipc	a2,0x2
ffffffffc02033b0:	a7c60613          	addi	a2,a2,-1412 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02033b4:	0a600593          	li	a1,166
ffffffffc02033b8:	00003517          	auipc	a0,0x3
ffffffffc02033bc:	80850513          	addi	a0,a0,-2040 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc02033c0:	fa1fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc02033c4:	00003697          	auipc	a3,0x3
ffffffffc02033c8:	81468693          	addi	a3,a3,-2028 # ffffffffc0205bd8 <etext+0x1688>
ffffffffc02033cc:	00002617          	auipc	a2,0x2
ffffffffc02033d0:	a5c60613          	addi	a2,a2,-1444 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02033d4:	0a400593          	li	a1,164
ffffffffc02033d8:	00002517          	auipc	a0,0x2
ffffffffc02033dc:	7e850513          	addi	a0,a0,2024 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc02033e0:	f81fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc02033e4:	00002697          	auipc	a3,0x2
ffffffffc02033e8:	7f468693          	addi	a3,a3,2036 # ffffffffc0205bd8 <etext+0x1688>
ffffffffc02033ec:	00002617          	auipc	a2,0x2
ffffffffc02033f0:	a3c60613          	addi	a2,a2,-1476 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02033f4:	0a200593          	li	a1,162
ffffffffc02033f8:	00002517          	auipc	a0,0x2
ffffffffc02033fc:	7c850513          	addi	a0,a0,1992 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203400:	f61fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc0203404:	00002697          	auipc	a3,0x2
ffffffffc0203408:	7d468693          	addi	a3,a3,2004 # ffffffffc0205bd8 <etext+0x1688>
ffffffffc020340c:	00002617          	auipc	a2,0x2
ffffffffc0203410:	a1c60613          	addi	a2,a2,-1508 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203414:	0a000593          	li	a1,160
ffffffffc0203418:	00002517          	auipc	a0,0x2
ffffffffc020341c:	7a850513          	addi	a0,a0,1960 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203420:	f41fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==4);
ffffffffc0203424:	00002697          	auipc	a3,0x2
ffffffffc0203428:	5ec68693          	addi	a3,a3,1516 # ffffffffc0205a10 <etext+0x14c0>
ffffffffc020342c:	00002617          	auipc	a2,0x2
ffffffffc0203430:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203434:	09e00593          	li	a1,158
ffffffffc0203438:	00002517          	auipc	a0,0x2
ffffffffc020343c:	78850513          	addi	a0,a0,1928 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203440:	f21fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==4);
ffffffffc0203444:	00002697          	auipc	a3,0x2
ffffffffc0203448:	5cc68693          	addi	a3,a3,1484 # ffffffffc0205a10 <etext+0x14c0>
ffffffffc020344c:	00002617          	auipc	a2,0x2
ffffffffc0203450:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203454:	09c00593          	li	a1,156
ffffffffc0203458:	00002517          	auipc	a0,0x2
ffffffffc020345c:	76850513          	addi	a0,a0,1896 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203460:	f01fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==4);
ffffffffc0203464:	00002697          	auipc	a3,0x2
ffffffffc0203468:	5ac68693          	addi	a3,a3,1452 # ffffffffc0205a10 <etext+0x14c0>
ffffffffc020346c:	00002617          	auipc	a2,0x2
ffffffffc0203470:	9bc60613          	addi	a2,a2,-1604 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203474:	09a00593          	li	a1,154
ffffffffc0203478:	00002517          	auipc	a0,0x2
ffffffffc020347c:	74850513          	addi	a0,a0,1864 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203480:	ee1fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203484 <_clock_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203484:	7514                	ld	a3,40(a0)
{
ffffffffc0203486:	1141                	addi	sp,sp,-16
ffffffffc0203488:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc020348a:	cebd                	beqz	a3,ffffffffc0203508 <_clock_swap_out_victim+0x84>
     assert(in_tick==0);
ffffffffc020348c:	ee31                	bnez	a2,ffffffffc02034e8 <_clock_swap_out_victim+0x64>
    return listelm->prev;
ffffffffc020348e:	6298                	ld	a4,0(a3)
ffffffffc0203490:	852e                	mv	a0,a1
        if(page->visited == 1)
ffffffffc0203492:	4605                	li	a2,1
        if (current == head) {
ffffffffc0203494:	00e68f63          	beq	a3,a4,ffffffffc02034b2 <_clock_swap_out_victim+0x2e>
        if(page->visited == 0)
ffffffffc0203498:	fe073783          	ld	a5,-32(a4)
ffffffffc020349c:	c38d                	beqz	a5,ffffffffc02034be <_clock_swap_out_victim+0x3a>
        if(page->visited == 1)
ffffffffc020349e:	fec79be3          	bne	a5,a2,ffffffffc0203494 <_clock_swap_out_victim+0x10>
            page->visited = 0;
ffffffffc02034a2:	fe073023          	sd	zero,-32(a4)
            curr_ptr = current;
ffffffffc02034a6:	0000e797          	auipc	a5,0xe
ffffffffc02034aa:	0ae7bd23          	sd	a4,186(a5) # ffffffffc0211560 <curr_ptr>
        if (current == head) {
ffffffffc02034ae:	fee695e3          	bne	a3,a4,ffffffffc0203498 <_clock_swap_out_victim+0x14>
}
ffffffffc02034b2:	60a2                	ld	ra,8(sp)
            *ptr_page = NULL;
ffffffffc02034b4:	00053023          	sd	zero,0(a0)
}
ffffffffc02034b8:	4501                	li	a0,0
ffffffffc02034ba:	0141                	addi	sp,sp,16
ffffffffc02034bc:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc02034be:	6314                	ld	a3,0(a4)
ffffffffc02034c0:	671c                	ld	a5,8(a4)
            cprintf("curr_ptr %p\n", curr_ptr);
ffffffffc02034c2:	0000e597          	auipc	a1,0xe
ffffffffc02034c6:	09e5b583          	ld	a1,158(a1) # ffffffffc0211560 <curr_ptr>
            *ptr_page = le2page(current, pra_page_link); 
ffffffffc02034ca:	fd070713          	addi	a4,a4,-48
    prev->next = next;
ffffffffc02034ce:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02034d0:	e394                	sd	a3,0(a5)
ffffffffc02034d2:	e118                	sd	a4,0(a0)
            cprintf("curr_ptr %p\n", curr_ptr);
ffffffffc02034d4:	00002517          	auipc	a0,0x2
ffffffffc02034d8:	76c50513          	addi	a0,a0,1900 # ffffffffc0205c40 <etext+0x16f0>
ffffffffc02034dc:	bdffc0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc02034e0:	60a2                	ld	ra,8(sp)
ffffffffc02034e2:	4501                	li	a0,0
ffffffffc02034e4:	0141                	addi	sp,sp,16
ffffffffc02034e6:	8082                	ret
     assert(in_tick==0);
ffffffffc02034e8:	00002697          	auipc	a3,0x2
ffffffffc02034ec:	74868693          	addi	a3,a3,1864 # ffffffffc0205c30 <etext+0x16e0>
ffffffffc02034f0:	00002617          	auipc	a2,0x2
ffffffffc02034f4:	93860613          	addi	a2,a2,-1736 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02034f8:	04f00593          	li	a1,79
ffffffffc02034fc:	00002517          	auipc	a0,0x2
ffffffffc0203500:	6c450513          	addi	a0,a0,1732 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203504:	e5dfc0ef          	jal	ffffffffc0200360 <__panic>
         assert(head != NULL);
ffffffffc0203508:	00002697          	auipc	a3,0x2
ffffffffc020350c:	71868693          	addi	a3,a3,1816 # ffffffffc0205c20 <etext+0x16d0>
ffffffffc0203510:	00002617          	auipc	a2,0x2
ffffffffc0203514:	91860613          	addi	a2,a2,-1768 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203518:	04e00593          	li	a1,78
ffffffffc020351c:	00002517          	auipc	a0,0x2
ffffffffc0203520:	6a450513          	addi	a0,a0,1700 # ffffffffc0205bc0 <etext+0x1670>
ffffffffc0203524:	e3dfc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203528 <_clock_init_mm>:
{     
ffffffffc0203528:	1141                	addi	sp,sp,-16
ffffffffc020352a:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc020352c:	0000e797          	auipc	a5,0xe
ffffffffc0203530:	bbc78793          	addi	a5,a5,-1092 # ffffffffc02110e8 <pra_list_head>
     mm->sm_priv=&pra_list_head;
ffffffffc0203534:	f51c                	sd	a5,40(a0)
     cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
ffffffffc0203536:	85be                	mv	a1,a5
ffffffffc0203538:	00002517          	auipc	a0,0x2
ffffffffc020353c:	71850513          	addi	a0,a0,1816 # ffffffffc0205c50 <etext+0x1700>
ffffffffc0203540:	e79c                	sd	a5,8(a5)
ffffffffc0203542:	e39c                	sd	a5,0(a5)
     curr_ptr=&pra_list_head;
ffffffffc0203544:	0000e717          	auipc	a4,0xe
ffffffffc0203548:	00f73e23          	sd	a5,28(a4) # ffffffffc0211560 <curr_ptr>
     cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
ffffffffc020354c:	b6ffc0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc0203550:	60a2                	ld	ra,8(sp)
ffffffffc0203552:	4501                	li	a0,0
ffffffffc0203554:	0141                	addi	sp,sp,16
ffffffffc0203556:	8082                	ret

ffffffffc0203558 <_clock_map_swappable>:
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203558:	0000e797          	auipc	a5,0xe
ffffffffc020355c:	0087b783          	ld	a5,8(a5) # ffffffffc0211560 <curr_ptr>
ffffffffc0203560:	c385                	beqz	a5,ffffffffc0203580 <_clock_map_swappable+0x28>
    __list_add(elm, listelm, listelm->next);
ffffffffc0203562:	0000e797          	auipc	a5,0xe
ffffffffc0203566:	b8678793          	addi	a5,a5,-1146 # ffffffffc02110e8 <pra_list_head>
ffffffffc020356a:	6794                	ld	a3,8(a5)
ffffffffc020356c:	03060713          	addi	a4,a2,48
}
ffffffffc0203570:	4501                	li	a0,0
    prev->next = next->prev = elm;
ffffffffc0203572:	e298                	sd	a4,0(a3)
ffffffffc0203574:	e798                	sd	a4,8(a5)
    elm->prev = prev;
ffffffffc0203576:	fa1c                	sd	a5,48(a2)
    page->visited =1;
ffffffffc0203578:	4785                	li	a5,1
    elm->next = next;
ffffffffc020357a:	fe14                	sd	a3,56(a2)
ffffffffc020357c:	ea1c                	sd	a5,16(a2)
}
ffffffffc020357e:	8082                	ret
{
ffffffffc0203580:	1141                	addi	sp,sp,-16
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203582:	00002697          	auipc	a3,0x2
ffffffffc0203586:	6f668693          	addi	a3,a3,1782 # ffffffffc0205c78 <etext+0x1728>
ffffffffc020358a:	00002617          	auipc	a2,0x2
ffffffffc020358e:	89e60613          	addi	a2,a2,-1890 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203592:	03a00593          	li	a1,58
ffffffffc0203596:	00002517          	auipc	a0,0x2
ffffffffc020359a:	62a50513          	addi	a0,a0,1578 # ffffffffc0205bc0 <etext+0x1670>
{
ffffffffc020359e:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc02035a0:	dc1fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02035a4 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02035a4:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02035a6:	00002697          	auipc	a3,0x2
ffffffffc02035aa:	71268693          	addi	a3,a3,1810 # ffffffffc0205cb8 <etext+0x1768>
ffffffffc02035ae:	00002617          	auipc	a2,0x2
ffffffffc02035b2:	87a60613          	addi	a2,a2,-1926 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02035b6:	07d00593          	li	a1,125
ffffffffc02035ba:	00002517          	auipc	a0,0x2
ffffffffc02035be:	71e50513          	addi	a0,a0,1822 # ffffffffc0205cd8 <etext+0x1788>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02035c2:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02035c4:	d9dfc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02035c8 <mm_create>:
mm_create(void) {
ffffffffc02035c8:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035ca:	03000513          	li	a0,48
mm_create(void) {
ffffffffc02035ce:	e022                	sd	s0,0(sp)
ffffffffc02035d0:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035d2:	a56ff0ef          	jal	ffffffffc0202828 <kmalloc>
ffffffffc02035d6:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc02035d8:	c105                	beqz	a0,ffffffffc02035f8 <mm_create+0x30>
    elm->prev = elm->next = elm;
ffffffffc02035da:	e408                	sd	a0,8(s0)
ffffffffc02035dc:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02035de:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02035e2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02035e6:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02035ea:	0000e797          	auipc	a5,0xe
ffffffffc02035ee:	f5e7a783          	lw	a5,-162(a5) # ffffffffc0211548 <swap_init_ok>
ffffffffc02035f2:	eb81                	bnez	a5,ffffffffc0203602 <mm_create+0x3a>
        else mm->sm_priv = NULL;
ffffffffc02035f4:	02053423          	sd	zero,40(a0)
}
ffffffffc02035f8:	60a2                	ld	ra,8(sp)
ffffffffc02035fa:	8522                	mv	a0,s0
ffffffffc02035fc:	6402                	ld	s0,0(sp)
ffffffffc02035fe:	0141                	addi	sp,sp,16
ffffffffc0203600:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203602:	a6dff0ef          	jal	ffffffffc020306e <swap_init_mm>
}
ffffffffc0203606:	60a2                	ld	ra,8(sp)
ffffffffc0203608:	8522                	mv	a0,s0
ffffffffc020360a:	6402                	ld	s0,0(sp)
ffffffffc020360c:	0141                	addi	sp,sp,16
ffffffffc020360e:	8082                	ret

ffffffffc0203610 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0203610:	1101                	addi	sp,sp,-32
ffffffffc0203612:	e04a                	sd	s2,0(sp)
ffffffffc0203614:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203616:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc020361a:	e822                	sd	s0,16(sp)
ffffffffc020361c:	e426                	sd	s1,8(sp)
ffffffffc020361e:	ec06                	sd	ra,24(sp)
ffffffffc0203620:	84ae                	mv	s1,a1
ffffffffc0203622:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203624:	a04ff0ef          	jal	ffffffffc0202828 <kmalloc>
    if (vma != NULL) {
ffffffffc0203628:	c509                	beqz	a0,ffffffffc0203632 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc020362a:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc020362e:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203630:	ed00                	sd	s0,24(a0)
}
ffffffffc0203632:	60e2                	ld	ra,24(sp)
ffffffffc0203634:	6442                	ld	s0,16(sp)
ffffffffc0203636:	64a2                	ld	s1,8(sp)
ffffffffc0203638:	6902                	ld	s2,0(sp)
ffffffffc020363a:	6105                	addi	sp,sp,32
ffffffffc020363c:	8082                	ret

ffffffffc020363e <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc020363e:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc0203640:	c505                	beqz	a0,ffffffffc0203668 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0203642:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0203644:	c501                	beqz	a0,ffffffffc020364c <find_vma+0xe>
ffffffffc0203646:	651c                	ld	a5,8(a0)
ffffffffc0203648:	02f5f663          	bgeu	a1,a5,ffffffffc0203674 <find_vma+0x36>
    return listelm->next;
ffffffffc020364c:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc020364e:	00f68d63          	beq	a3,a5,ffffffffc0203668 <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0203652:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203656:	00e5e663          	bltu	a1,a4,ffffffffc0203662 <find_vma+0x24>
ffffffffc020365a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020365e:	00e5e763          	bltu	a1,a4,ffffffffc020366c <find_vma+0x2e>
ffffffffc0203662:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0203664:	fef697e3          	bne	a3,a5,ffffffffc0203652 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203668:	4501                	li	a0,0
}
ffffffffc020366a:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc020366c:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203670:	ea88                	sd	a0,16(a3)
ffffffffc0203672:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0203674:	691c                	ld	a5,16(a0)
ffffffffc0203676:	fcf5fbe3          	bgeu	a1,a5,ffffffffc020364c <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020367a:	ea88                	sd	a0,16(a3)
ffffffffc020367c:	8082                	ret

ffffffffc020367e <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc020367e:	6590                	ld	a2,8(a1)
ffffffffc0203680:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0203684:	1141                	addi	sp,sp,-16
ffffffffc0203686:	e406                	sd	ra,8(sp)
ffffffffc0203688:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020368a:	01066763          	bltu	a2,a6,ffffffffc0203698 <insert_vma_struct+0x1a>
ffffffffc020368e:	a085                	j	ffffffffc02036ee <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0203690:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203694:	04e66863          	bltu	a2,a4,ffffffffc02036e4 <insert_vma_struct+0x66>
ffffffffc0203698:	86be                	mv	a3,a5
ffffffffc020369a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc020369c:	fef51ae3          	bne	a0,a5,ffffffffc0203690 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc02036a0:	02a68463          	beq	a3,a0,ffffffffc02036c8 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02036a4:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036a8:	fe86b883          	ld	a7,-24(a3)
ffffffffc02036ac:	08e8f163          	bgeu	a7,a4,ffffffffc020372e <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036b0:	04e66f63          	bltu	a2,a4,ffffffffc020370e <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc02036b4:	00f50a63          	beq	a0,a5,ffffffffc02036c8 <insert_vma_struct+0x4a>
ffffffffc02036b8:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036bc:	05076963          	bltu	a4,a6,ffffffffc020370e <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc02036c0:	ff07b603          	ld	a2,-16(a5)
ffffffffc02036c4:	02c77363          	bgeu	a4,a2,ffffffffc02036ea <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc02036c8:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02036ca:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02036cc:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02036d0:	e390                	sd	a2,0(a5)
ffffffffc02036d2:	e690                	sd	a2,8(a3)
}
ffffffffc02036d4:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02036d6:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02036d8:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc02036da:	0017079b          	addiw	a5,a4,1
ffffffffc02036de:	d11c                	sw	a5,32(a0)
}
ffffffffc02036e0:	0141                	addi	sp,sp,16
ffffffffc02036e2:	8082                	ret
    if (le_prev != list) {
ffffffffc02036e4:	fca690e3          	bne	a3,a0,ffffffffc02036a4 <insert_vma_struct+0x26>
ffffffffc02036e8:	bfd1                	j	ffffffffc02036bc <insert_vma_struct+0x3e>
ffffffffc02036ea:	ebbff0ef          	jal	ffffffffc02035a4 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036ee:	00002697          	auipc	a3,0x2
ffffffffc02036f2:	5fa68693          	addi	a3,a3,1530 # ffffffffc0205ce8 <etext+0x1798>
ffffffffc02036f6:	00001617          	auipc	a2,0x1
ffffffffc02036fa:	73260613          	addi	a2,a2,1842 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc02036fe:	08400593          	li	a1,132
ffffffffc0203702:	00002517          	auipc	a0,0x2
ffffffffc0203706:	5d650513          	addi	a0,a0,1494 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc020370a:	c57fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020370e:	00002697          	auipc	a3,0x2
ffffffffc0203712:	61a68693          	addi	a3,a3,1562 # ffffffffc0205d28 <etext+0x17d8>
ffffffffc0203716:	00001617          	auipc	a2,0x1
ffffffffc020371a:	71260613          	addi	a2,a2,1810 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020371e:	07c00593          	li	a1,124
ffffffffc0203722:	00002517          	auipc	a0,0x2
ffffffffc0203726:	5b650513          	addi	a0,a0,1462 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc020372a:	c37fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020372e:	00002697          	auipc	a3,0x2
ffffffffc0203732:	5da68693          	addi	a3,a3,1498 # ffffffffc0205d08 <etext+0x17b8>
ffffffffc0203736:	00001617          	auipc	a2,0x1
ffffffffc020373a:	6f260613          	addi	a2,a2,1778 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc020373e:	07b00593          	li	a1,123
ffffffffc0203742:	00002517          	auipc	a0,0x2
ffffffffc0203746:	59650513          	addi	a0,a0,1430 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc020374a:	c17fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020374e <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc020374e:	1141                	addi	sp,sp,-16
ffffffffc0203750:	e022                	sd	s0,0(sp)
ffffffffc0203752:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203754:	6508                	ld	a0,8(a0)
ffffffffc0203756:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0203758:	00a40e63          	beq	s0,a0,ffffffffc0203774 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020375c:	6118                	ld	a4,0(a0)
ffffffffc020375e:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc0203760:	03000593          	li	a1,48
ffffffffc0203764:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203766:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203768:	e398                	sd	a4,0(a5)
ffffffffc020376a:	98aff0ef          	jal	ffffffffc02028f4 <kfree>
    return listelm->next;
ffffffffc020376e:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203770:	fea416e3          	bne	s0,a0,ffffffffc020375c <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203774:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0203776:	6402                	ld	s0,0(sp)
ffffffffc0203778:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc020377a:	03000593          	li	a1,48
}
ffffffffc020377e:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203780:	974ff06f          	j	ffffffffc02028f4 <kfree>

ffffffffc0203784 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0203784:	715d                	addi	sp,sp,-80
ffffffffc0203786:	e486                	sd	ra,72(sp)
ffffffffc0203788:	f44e                	sd	s3,40(sp)
ffffffffc020378a:	f052                	sd	s4,32(sp)
ffffffffc020378c:	e0a2                	sd	s0,64(sp)
ffffffffc020378e:	fc26                	sd	s1,56(sp)
ffffffffc0203790:	f84a                	sd	s2,48(sp)
ffffffffc0203792:	ec56                	sd	s5,24(sp)
ffffffffc0203794:	e85a                	sd	s6,16(sp)
ffffffffc0203796:	e45e                	sd	s7,8(sp)
ffffffffc0203798:	e062                	sd	s8,0(sp)
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020379a:	f39fd0ef          	jal	ffffffffc02016d2 <nr_free_pages>
ffffffffc020379e:	89aa                	mv	s3,a0
    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02037a0:	f33fd0ef          	jal	ffffffffc02016d2 <nr_free_pages>
ffffffffc02037a4:	8a2a                	mv	s4,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02037a6:	03000513          	li	a0,48
ffffffffc02037aa:	87eff0ef          	jal	ffffffffc0202828 <kmalloc>
    if (mm != NULL) {
ffffffffc02037ae:	30050563          	beqz	a0,ffffffffc0203ab8 <vmm_init+0x334>
    elm->prev = elm->next = elm;
ffffffffc02037b2:	e508                	sd	a0,8(a0)
ffffffffc02037b4:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02037b6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02037ba:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02037be:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02037c2:	0000e797          	auipc	a5,0xe
ffffffffc02037c6:	d867a783          	lw	a5,-634(a5) # ffffffffc0211548 <swap_init_ok>
ffffffffc02037ca:	842a                	mv	s0,a0
ffffffffc02037cc:	2c079363          	bnez	a5,ffffffffc0203a92 <vmm_init+0x30e>
        else mm->sm_priv = NULL;
ffffffffc02037d0:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc02037d4:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02037d8:	03000513          	li	a0,48
ffffffffc02037dc:	84cff0ef          	jal	ffffffffc0202828 <kmalloc>
ffffffffc02037e0:	00248913          	addi	s2,s1,2
ffffffffc02037e4:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc02037e6:	2a050963          	beqz	a0,ffffffffc0203a98 <vmm_init+0x314>
        vma->vm_start = vm_start;
ffffffffc02037ea:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02037ec:	01253823          	sd	s2,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02037f0:	00053c23          	sd	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc02037f4:	14ed                	addi	s1,s1,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02037f6:	8522                	mv	a0,s0
ffffffffc02037f8:	e87ff0ef          	jal	ffffffffc020367e <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc02037fc:	fcf1                	bnez	s1,ffffffffc02037d8 <vmm_init+0x54>
ffffffffc02037fe:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203802:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203806:	03000513          	li	a0,48
ffffffffc020380a:	81eff0ef          	jal	ffffffffc0202828 <kmalloc>
ffffffffc020380e:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc0203810:	2c050463          	beqz	a0,ffffffffc0203ad8 <vmm_init+0x354>
        vma->vm_end = vm_end;
ffffffffc0203814:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203818:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc020381a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020381c:	00053c23          	sd	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203820:	0495                	addi	s1,s1,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203822:	8522                	mv	a0,s0
ffffffffc0203824:	e5bff0ef          	jal	ffffffffc020367e <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203828:	fd249fe3          	bne	s1,s2,ffffffffc0203806 <vmm_init+0x82>
    return listelm->next;
ffffffffc020382c:	00843b03          	ld	s6,8(s0)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc0203830:	3c8b0b63          	beq	s6,s0,ffffffffc0203c06 <vmm_init+0x482>
    list_entry_t *le = list_next(&(mm->mmap_list));
ffffffffc0203834:	87da                	mv	a5,s6
        assert(le != &(mm->mmap_list));
ffffffffc0203836:	4715                	li	a4,5
    for (i = 1; i <= step2; i ++) {
ffffffffc0203838:	1f400593          	li	a1,500
ffffffffc020383c:	a021                	j	ffffffffc0203844 <vmm_init+0xc0>
        assert(le != &(mm->mmap_list));
ffffffffc020383e:	0715                	addi	a4,a4,5
ffffffffc0203840:	3c878363          	beq	a5,s0,ffffffffc0203c06 <vmm_init+0x482>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203844:	fe87b683          	ld	a3,-24(a5)
ffffffffc0203848:	32e69f63          	bne	a3,a4,ffffffffc0203b86 <vmm_init+0x402>
ffffffffc020384c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203850:	00270693          	addi	a3,a4,2
ffffffffc0203854:	32d61963          	bne	a2,a3,ffffffffc0203b86 <vmm_init+0x402>
ffffffffc0203858:	679c                	ld	a5,8(a5)
    for (i = 1; i <= step2; i ++) {
ffffffffc020385a:	feb712e3          	bne	a4,a1,ffffffffc020383e <vmm_init+0xba>
ffffffffc020385e:	4b9d                	li	s7,7
ffffffffc0203860:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203862:	1f900c13          	li	s8,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203866:	85a6                	mv	a1,s1
ffffffffc0203868:	8522                	mv	a0,s0
ffffffffc020386a:	dd5ff0ef          	jal	ffffffffc020363e <find_vma>
ffffffffc020386e:	8aaa                	mv	s5,a0
        assert(vma1 != NULL);
ffffffffc0203870:	3c050b63          	beqz	a0,ffffffffc0203c46 <vmm_init+0x4c2>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0203874:	00148593          	addi	a1,s1,1
ffffffffc0203878:	8522                	mv	a0,s0
ffffffffc020387a:	dc5ff0ef          	jal	ffffffffc020363e <find_vma>
ffffffffc020387e:	892a                	mv	s2,a0
        assert(vma2 != NULL);
ffffffffc0203880:	3a050363          	beqz	a0,ffffffffc0203c26 <vmm_init+0x4a2>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0203884:	85de                	mv	a1,s7
ffffffffc0203886:	8522                	mv	a0,s0
ffffffffc0203888:	db7ff0ef          	jal	ffffffffc020363e <find_vma>
        assert(vma3 == NULL);
ffffffffc020388c:	32051d63          	bnez	a0,ffffffffc0203bc6 <vmm_init+0x442>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0203890:	00348593          	addi	a1,s1,3
ffffffffc0203894:	8522                	mv	a0,s0
ffffffffc0203896:	da9ff0ef          	jal	ffffffffc020363e <find_vma>
        assert(vma4 == NULL);
ffffffffc020389a:	30051663          	bnez	a0,ffffffffc0203ba6 <vmm_init+0x422>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc020389e:	00448593          	addi	a1,s1,4
ffffffffc02038a2:	8522                	mv	a0,s0
ffffffffc02038a4:	d9bff0ef          	jal	ffffffffc020363e <find_vma>
        assert(vma5 == NULL);
ffffffffc02038a8:	32051f63          	bnez	a0,ffffffffc0203be6 <vmm_init+0x462>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02038ac:	008ab783          	ld	a5,8(s5) # 1008 <kern_entry-0xffffffffc01feff8>
ffffffffc02038b0:	2a979b63          	bne	a5,s1,ffffffffc0203b66 <vmm_init+0x3e2>
ffffffffc02038b4:	010ab783          	ld	a5,16(s5)
ffffffffc02038b8:	2afb9763          	bne	s7,a5,ffffffffc0203b66 <vmm_init+0x3e2>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02038bc:	00893783          	ld	a5,8(s2)
ffffffffc02038c0:	28979363          	bne	a5,s1,ffffffffc0203b46 <vmm_init+0x3c2>
ffffffffc02038c4:	01093783          	ld	a5,16(s2)
ffffffffc02038c8:	26fb9f63          	bne	s7,a5,ffffffffc0203b46 <vmm_init+0x3c2>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02038cc:	0495                	addi	s1,s1,5
ffffffffc02038ce:	0b95                	addi	s7,s7,5
ffffffffc02038d0:	f9849be3          	bne	s1,s8,ffffffffc0203866 <vmm_init+0xe2>
ffffffffc02038d4:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc02038d6:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc02038d8:	85a6                	mv	a1,s1
ffffffffc02038da:	8522                	mv	a0,s0
ffffffffc02038dc:	d63ff0ef          	jal	ffffffffc020363e <find_vma>
        if (vma_below_5 != NULL ) {
ffffffffc02038e0:	3a051363          	bnez	a0,ffffffffc0203c86 <vmm_init+0x502>
    for (i =4; i>=0; i--) {
ffffffffc02038e4:	14fd                	addi	s1,s1,-1
ffffffffc02038e6:	ff2499e3          	bne	s1,s2,ffffffffc02038d8 <vmm_init+0x154>
    __list_del(listelm->prev, listelm->next);
ffffffffc02038ea:	000b3703          	ld	a4,0(s6)
ffffffffc02038ee:	008b3783          	ld	a5,8(s6)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc02038f2:	fe0b0513          	addi	a0,s6,-32
ffffffffc02038f6:	03000593          	li	a1,48
    prev->next = next;
ffffffffc02038fa:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02038fc:	e398                	sd	a4,0(a5)
ffffffffc02038fe:	ff7fe0ef          	jal	ffffffffc02028f4 <kfree>
    return listelm->next;
ffffffffc0203902:	00843b03          	ld	s6,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203906:	ff6412e3          	bne	s0,s6,ffffffffc02038ea <vmm_init+0x166>
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc020390a:	03000593          	li	a1,48
ffffffffc020390e:	8522                	mv	a0,s0
ffffffffc0203910:	fe5fe0ef          	jal	ffffffffc02028f4 <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203914:	dbffd0ef          	jal	ffffffffc02016d2 <nr_free_pages>
ffffffffc0203918:	3caa1163          	bne	s4,a0,ffffffffc0203cda <vmm_init+0x556>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc020391c:	00002517          	auipc	a0,0x2
ffffffffc0203920:	59450513          	addi	a0,a0,1428 # ffffffffc0205eb0 <etext+0x1960>
ffffffffc0203924:	f96fc0ef          	jal	ffffffffc02000ba <cprintf>

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
	// char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203928:	dabfd0ef          	jal	ffffffffc02016d2 <nr_free_pages>
ffffffffc020392c:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020392e:	03000513          	li	a0,48
ffffffffc0203932:	ef7fe0ef          	jal	ffffffffc0202828 <kmalloc>
ffffffffc0203936:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0203938:	1e050063          	beqz	a0,ffffffffc0203b18 <vmm_init+0x394>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc020393c:	0000e797          	auipc	a5,0xe
ffffffffc0203940:	c0c7a783          	lw	a5,-1012(a5) # ffffffffc0211548 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc0203944:	e508                	sd	a0,8(a0)
ffffffffc0203946:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203948:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020394c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203950:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203954:	1e079663          	bnez	a5,ffffffffc0203b40 <vmm_init+0x3bc>
        else mm->sm_priv = NULL;
ffffffffc0203958:	02053423          	sd	zero,40(a0)

    check_mm_struct = mm_create();

    assert(check_mm_struct != NULL);
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020395c:	0000ea17          	auipc	s4,0xe
ffffffffc0203960:	bcca3a03          	ld	s4,-1076(s4) # ffffffffc0211528 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0203964:	000a3783          	ld	a5,0(s4)
    check_mm_struct = mm_create();
ffffffffc0203968:	0000e717          	auipc	a4,0xe
ffffffffc020396c:	c0873423          	sd	s0,-1016(a4) # ffffffffc0211570 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203970:	01443c23          	sd	s4,24(s0)
    assert(pgdir[0] == 0);
ffffffffc0203974:	2e079963          	bnez	a5,ffffffffc0203c66 <vmm_init+0x4e2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203978:	03000513          	li	a0,48
ffffffffc020397c:	eadfe0ef          	jal	ffffffffc0202828 <kmalloc>
ffffffffc0203980:	892a                	mv	s2,a0
    if (vma != NULL) {
ffffffffc0203982:	16050b63          	beqz	a0,ffffffffc0203af8 <vmm_init+0x374>
        vma->vm_end = vm_end;
ffffffffc0203986:	002007b7          	lui	a5,0x200
ffffffffc020398a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020398c:	4789                	li	a5,2
ffffffffc020398e:	ed1c                	sd	a5,24(a0)

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0203990:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203992:	00053423          	sd	zero,8(a0)
    insert_vma_struct(mm, vma);
ffffffffc0203996:	8522                	mv	a0,s0
ffffffffc0203998:	ce7ff0ef          	jal	ffffffffc020367e <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc020399c:	10000593          	li	a1,256
ffffffffc02039a0:	8522                	mv	a0,s0
ffffffffc02039a2:	c9dff0ef          	jal	ffffffffc020363e <find_vma>
ffffffffc02039a6:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc02039aa:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc02039ae:	30a91663          	bne	s2,a0,ffffffffc0203cba <vmm_init+0x536>
        *(char *)(addr + i) = i;
ffffffffc02039b2:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc02039b6:	0785                	addi	a5,a5,1
ffffffffc02039b8:	fee79de3          	bne	a5,a4,ffffffffc02039b2 <vmm_init+0x22e>
ffffffffc02039bc:	6705                	lui	a4,0x1
ffffffffc02039be:	10000793          	li	a5,256
ffffffffc02039c2:	35670713          	addi	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
ffffffffc02039c6:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc02039ca:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc02039ce:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc02039d0:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc02039d2:	fec79ce3          	bne	a5,a2,ffffffffc02039ca <vmm_init+0x246>
    }
    assert(sum == 0);
ffffffffc02039d6:	32071e63          	bnez	a4,ffffffffc0203d12 <vmm_init+0x58e>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02039da:	4581                	li	a1,0
ffffffffc02039dc:	8552                	mv	a0,s4
ffffffffc02039de:	fb7fd0ef          	jal	ffffffffc0201994 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02039e2:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02039e6:	0000e717          	auipc	a4,0xe
ffffffffc02039ea:	b5273703          	ld	a4,-1198(a4) # ffffffffc0211538 <npage>
    return pa2page(PDE_ADDR(pde));
ffffffffc02039ee:	078a                	slli	a5,a5,0x2
ffffffffc02039f0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02039f2:	30e7f463          	bgeu	a5,a4,ffffffffc0203cfa <vmm_init+0x576>
    return &pages[PPN(pa) - nbase];
ffffffffc02039f6:	00003717          	auipc	a4,0x3
ffffffffc02039fa:	9aa73703          	ld	a4,-1622(a4) # ffffffffc02063a0 <nbase>
ffffffffc02039fe:	8f99                	sub	a5,a5,a4
ffffffffc0203a00:	00379713          	slli	a4,a5,0x3
ffffffffc0203a04:	97ba                	add	a5,a5,a4
ffffffffc0203a06:	078e                	slli	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc0203a08:	0000e517          	auipc	a0,0xe
ffffffffc0203a0c:	b3853503          	ld	a0,-1224(a0) # ffffffffc0211540 <pages>
ffffffffc0203a10:	953e                	add	a0,a0,a5
ffffffffc0203a12:	4585                	li	a1,1
ffffffffc0203a14:	c7ffd0ef          	jal	ffffffffc0201692 <free_pages>
    return listelm->next;
ffffffffc0203a18:	6408                	ld	a0,8(s0)

    pgdir[0] = 0;
ffffffffc0203a1a:	000a3023          	sd	zero,0(s4)

    mm->pgdir = NULL;
ffffffffc0203a1e:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203a22:	00850e63          	beq	a0,s0,ffffffffc0203a3e <vmm_init+0x2ba>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203a26:	6118                	ld	a4,0(a0)
ffffffffc0203a28:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc0203a2a:	03000593          	li	a1,48
ffffffffc0203a2e:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203a30:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203a32:	e398                	sd	a4,0(a5)
ffffffffc0203a34:	ec1fe0ef          	jal	ffffffffc02028f4 <kfree>
    return listelm->next;
ffffffffc0203a38:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203a3a:	fea416e3          	bne	s0,a0,ffffffffc0203a26 <vmm_init+0x2a2>
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203a3e:	03000593          	li	a1,48
ffffffffc0203a42:	8522                	mv	a0,s0
ffffffffc0203a44:	eb1fe0ef          	jal	ffffffffc02028f4 <kfree>
    mm_destroy(mm);

    check_mm_struct = NULL;
    nr_free_pages_store--;	// szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc0203a48:	14fd                	addi	s1,s1,-1
    check_mm_struct = NULL;
ffffffffc0203a4a:	0000e797          	auipc	a5,0xe
ffffffffc0203a4e:	b207b323          	sd	zero,-1242(a5) # ffffffffc0211570 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203a52:	c81fd0ef          	jal	ffffffffc02016d2 <nr_free_pages>
ffffffffc0203a56:	2ea49e63          	bne	s1,a0,ffffffffc0203d52 <vmm_init+0x5ce>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203a5a:	00002517          	auipc	a0,0x2
ffffffffc0203a5e:	4be50513          	addi	a0,a0,1214 # ffffffffc0205f18 <etext+0x19c8>
ffffffffc0203a62:	e58fc0ef          	jal	ffffffffc02000ba <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203a66:	c6dfd0ef          	jal	ffffffffc02016d2 <nr_free_pages>
    nr_free_pages_store--;	// szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc0203a6a:	19fd                	addi	s3,s3,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203a6c:	2ca99363          	bne	s3,a0,ffffffffc0203d32 <vmm_init+0x5ae>
}
ffffffffc0203a70:	6406                	ld	s0,64(sp)
ffffffffc0203a72:	60a6                	ld	ra,72(sp)
ffffffffc0203a74:	74e2                	ld	s1,56(sp)
ffffffffc0203a76:	7942                	ld	s2,48(sp)
ffffffffc0203a78:	79a2                	ld	s3,40(sp)
ffffffffc0203a7a:	7a02                	ld	s4,32(sp)
ffffffffc0203a7c:	6ae2                	ld	s5,24(sp)
ffffffffc0203a7e:	6b42                	ld	s6,16(sp)
ffffffffc0203a80:	6ba2                	ld	s7,8(sp)
ffffffffc0203a82:	6c02                	ld	s8,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a84:	00002517          	auipc	a0,0x2
ffffffffc0203a88:	4b450513          	addi	a0,a0,1204 # ffffffffc0205f38 <etext+0x19e8>
}
ffffffffc0203a8c:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a8e:	e2cfc06f          	j	ffffffffc02000ba <cprintf>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203a92:	ddcff0ef          	jal	ffffffffc020306e <swap_init_mm>
    for (i = step1; i >= 1; i --) {
ffffffffc0203a96:	bb3d                	j	ffffffffc02037d4 <vmm_init+0x50>
        assert(vma != NULL);
ffffffffc0203a98:	00002697          	auipc	a3,0x2
ffffffffc0203a9c:	e3868693          	addi	a3,a3,-456 # ffffffffc02058d0 <etext+0x1380>
ffffffffc0203aa0:	00001617          	auipc	a2,0x1
ffffffffc0203aa4:	38860613          	addi	a2,a2,904 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203aa8:	0ce00593          	li	a1,206
ffffffffc0203aac:	00002517          	auipc	a0,0x2
ffffffffc0203ab0:	22c50513          	addi	a0,a0,556 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203ab4:	8adfc0ef          	jal	ffffffffc0200360 <__panic>
    assert(mm != NULL);
ffffffffc0203ab8:	00002697          	auipc	a3,0x2
ffffffffc0203abc:	de068693          	addi	a3,a3,-544 # ffffffffc0205898 <etext+0x1348>
ffffffffc0203ac0:	00001617          	auipc	a2,0x1
ffffffffc0203ac4:	36860613          	addi	a2,a2,872 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203ac8:	0c700593          	li	a1,199
ffffffffc0203acc:	00002517          	auipc	a0,0x2
ffffffffc0203ad0:	20c50513          	addi	a0,a0,524 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203ad4:	88dfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma != NULL);
ffffffffc0203ad8:	00002697          	auipc	a3,0x2
ffffffffc0203adc:	df868693          	addi	a3,a3,-520 # ffffffffc02058d0 <etext+0x1380>
ffffffffc0203ae0:	00001617          	auipc	a2,0x1
ffffffffc0203ae4:	34860613          	addi	a2,a2,840 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203ae8:	0d400593          	li	a1,212
ffffffffc0203aec:	00002517          	auipc	a0,0x2
ffffffffc0203af0:	1ec50513          	addi	a0,a0,492 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203af4:	86dfc0ef          	jal	ffffffffc0200360 <__panic>
    assert(vma != NULL);
ffffffffc0203af8:	00002697          	auipc	a3,0x2
ffffffffc0203afc:	dd868693          	addi	a3,a3,-552 # ffffffffc02058d0 <etext+0x1380>
ffffffffc0203b00:	00001617          	auipc	a2,0x1
ffffffffc0203b04:	32860613          	addi	a2,a2,808 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203b08:	11100593          	li	a1,273
ffffffffc0203b0c:	00002517          	auipc	a0,0x2
ffffffffc0203b10:	1cc50513          	addi	a0,a0,460 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203b14:	84dfc0ef          	jal	ffffffffc0200360 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0203b18:	00002697          	auipc	a3,0x2
ffffffffc0203b1c:	3b868693          	addi	a3,a3,952 # ffffffffc0205ed0 <etext+0x1980>
ffffffffc0203b20:	00001617          	auipc	a2,0x1
ffffffffc0203b24:	30860613          	addi	a2,a2,776 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203b28:	10a00593          	li	a1,266
ffffffffc0203b2c:	00002517          	auipc	a0,0x2
ffffffffc0203b30:	1ac50513          	addi	a0,a0,428 # ffffffffc0205cd8 <etext+0x1788>
    check_mm_struct = mm_create();
ffffffffc0203b34:	0000e797          	auipc	a5,0xe
ffffffffc0203b38:	a207be23          	sd	zero,-1476(a5) # ffffffffc0211570 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc0203b3c:	825fc0ef          	jal	ffffffffc0200360 <__panic>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203b40:	d2eff0ef          	jal	ffffffffc020306e <swap_init_mm>
    assert(check_mm_struct != NULL);
ffffffffc0203b44:	bd21                	j	ffffffffc020395c <vmm_init+0x1d8>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203b46:	00002697          	auipc	a3,0x2
ffffffffc0203b4a:	2d268693          	addi	a3,a3,722 # ffffffffc0205e18 <etext+0x18c8>
ffffffffc0203b4e:	00001617          	auipc	a2,0x1
ffffffffc0203b52:	2da60613          	addi	a2,a2,730 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203b56:	0ee00593          	li	a1,238
ffffffffc0203b5a:	00002517          	auipc	a0,0x2
ffffffffc0203b5e:	17e50513          	addi	a0,a0,382 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203b62:	ffefc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203b66:	00002697          	auipc	a3,0x2
ffffffffc0203b6a:	28268693          	addi	a3,a3,642 # ffffffffc0205de8 <etext+0x1898>
ffffffffc0203b6e:	00001617          	auipc	a2,0x1
ffffffffc0203b72:	2ba60613          	addi	a2,a2,698 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203b76:	0ed00593          	li	a1,237
ffffffffc0203b7a:	00002517          	auipc	a0,0x2
ffffffffc0203b7e:	15e50513          	addi	a0,a0,350 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203b82:	fdefc0ef          	jal	ffffffffc0200360 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b86:	00002697          	auipc	a3,0x2
ffffffffc0203b8a:	1da68693          	addi	a3,a3,474 # ffffffffc0205d60 <etext+0x1810>
ffffffffc0203b8e:	00001617          	auipc	a2,0x1
ffffffffc0203b92:	29a60613          	addi	a2,a2,666 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203b96:	0dd00593          	li	a1,221
ffffffffc0203b9a:	00002517          	auipc	a0,0x2
ffffffffc0203b9e:	13e50513          	addi	a0,a0,318 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203ba2:	fbefc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma4 == NULL);
ffffffffc0203ba6:	00002697          	auipc	a3,0x2
ffffffffc0203baa:	22268693          	addi	a3,a3,546 # ffffffffc0205dc8 <etext+0x1878>
ffffffffc0203bae:	00001617          	auipc	a2,0x1
ffffffffc0203bb2:	27a60613          	addi	a2,a2,634 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203bb6:	0e900593          	li	a1,233
ffffffffc0203bba:	00002517          	auipc	a0,0x2
ffffffffc0203bbe:	11e50513          	addi	a0,a0,286 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203bc2:	f9efc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma3 == NULL);
ffffffffc0203bc6:	00002697          	auipc	a3,0x2
ffffffffc0203bca:	1f268693          	addi	a3,a3,498 # ffffffffc0205db8 <etext+0x1868>
ffffffffc0203bce:	00001617          	auipc	a2,0x1
ffffffffc0203bd2:	25a60613          	addi	a2,a2,602 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203bd6:	0e700593          	li	a1,231
ffffffffc0203bda:	00002517          	auipc	a0,0x2
ffffffffc0203bde:	0fe50513          	addi	a0,a0,254 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203be2:	f7efc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma5 == NULL);
ffffffffc0203be6:	00002697          	auipc	a3,0x2
ffffffffc0203bea:	1f268693          	addi	a3,a3,498 # ffffffffc0205dd8 <etext+0x1888>
ffffffffc0203bee:	00001617          	auipc	a2,0x1
ffffffffc0203bf2:	23a60613          	addi	a2,a2,570 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203bf6:	0eb00593          	li	a1,235
ffffffffc0203bfa:	00002517          	auipc	a0,0x2
ffffffffc0203bfe:	0de50513          	addi	a0,a0,222 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203c02:	f5efc0ef          	jal	ffffffffc0200360 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c06:	00002697          	auipc	a3,0x2
ffffffffc0203c0a:	14268693          	addi	a3,a3,322 # ffffffffc0205d48 <etext+0x17f8>
ffffffffc0203c0e:	00001617          	auipc	a2,0x1
ffffffffc0203c12:	21a60613          	addi	a2,a2,538 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203c16:	0db00593          	li	a1,219
ffffffffc0203c1a:	00002517          	auipc	a0,0x2
ffffffffc0203c1e:	0be50513          	addi	a0,a0,190 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203c22:	f3efc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma2 != NULL);
ffffffffc0203c26:	00002697          	auipc	a3,0x2
ffffffffc0203c2a:	18268693          	addi	a3,a3,386 # ffffffffc0205da8 <etext+0x1858>
ffffffffc0203c2e:	00001617          	auipc	a2,0x1
ffffffffc0203c32:	1fa60613          	addi	a2,a2,506 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203c36:	0e500593          	li	a1,229
ffffffffc0203c3a:	00002517          	auipc	a0,0x2
ffffffffc0203c3e:	09e50513          	addi	a0,a0,158 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203c42:	f1efc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma1 != NULL);
ffffffffc0203c46:	00002697          	auipc	a3,0x2
ffffffffc0203c4a:	15268693          	addi	a3,a3,338 # ffffffffc0205d98 <etext+0x1848>
ffffffffc0203c4e:	00001617          	auipc	a2,0x1
ffffffffc0203c52:	1da60613          	addi	a2,a2,474 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203c56:	0e300593          	li	a1,227
ffffffffc0203c5a:	00002517          	auipc	a0,0x2
ffffffffc0203c5e:	07e50513          	addi	a0,a0,126 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203c62:	efefc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203c66:	00002697          	auipc	a3,0x2
ffffffffc0203c6a:	c5a68693          	addi	a3,a3,-934 # ffffffffc02058c0 <etext+0x1370>
ffffffffc0203c6e:	00001617          	auipc	a2,0x1
ffffffffc0203c72:	1ba60613          	addi	a2,a2,442 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203c76:	10d00593          	li	a1,269
ffffffffc0203c7a:	00002517          	auipc	a0,0x2
ffffffffc0203c7e:	05e50513          	addi	a0,a0,94 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203c82:	edefc0ef          	jal	ffffffffc0200360 <__panic>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0203c86:	6914                	ld	a3,16(a0)
ffffffffc0203c88:	6510                	ld	a2,8(a0)
ffffffffc0203c8a:	0004859b          	sext.w	a1,s1
ffffffffc0203c8e:	00002517          	auipc	a0,0x2
ffffffffc0203c92:	1ba50513          	addi	a0,a0,442 # ffffffffc0205e48 <etext+0x18f8>
ffffffffc0203c96:	c24fc0ef          	jal	ffffffffc02000ba <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203c9a:	00002697          	auipc	a3,0x2
ffffffffc0203c9e:	1d668693          	addi	a3,a3,470 # ffffffffc0205e70 <etext+0x1920>
ffffffffc0203ca2:	00001617          	auipc	a2,0x1
ffffffffc0203ca6:	18660613          	addi	a2,a2,390 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203caa:	0f600593          	li	a1,246
ffffffffc0203cae:	00002517          	auipc	a0,0x2
ffffffffc0203cb2:	02a50513          	addi	a0,a0,42 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203cb6:	eaafc0ef          	jal	ffffffffc0200360 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203cba:	00002697          	auipc	a3,0x2
ffffffffc0203cbe:	22e68693          	addi	a3,a3,558 # ffffffffc0205ee8 <etext+0x1998>
ffffffffc0203cc2:	00001617          	auipc	a2,0x1
ffffffffc0203cc6:	16660613          	addi	a2,a2,358 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203cca:	11600593          	li	a1,278
ffffffffc0203cce:	00002517          	auipc	a0,0x2
ffffffffc0203cd2:	00a50513          	addi	a0,a0,10 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203cd6:	e8afc0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203cda:	00002697          	auipc	a3,0x2
ffffffffc0203cde:	1ae68693          	addi	a3,a3,430 # ffffffffc0205e88 <etext+0x1938>
ffffffffc0203ce2:	00001617          	auipc	a2,0x1
ffffffffc0203ce6:	14660613          	addi	a2,a2,326 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203cea:	0fb00593          	li	a1,251
ffffffffc0203cee:	00002517          	auipc	a0,0x2
ffffffffc0203cf2:	fea50513          	addi	a0,a0,-22 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203cf6:	e6afc0ef          	jal	ffffffffc0200360 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203cfa:	00001617          	auipc	a2,0x1
ffffffffc0203cfe:	4de60613          	addi	a2,a2,1246 # ffffffffc02051d8 <etext+0xc88>
ffffffffc0203d02:	06500593          	li	a1,101
ffffffffc0203d06:	00001517          	auipc	a0,0x1
ffffffffc0203d0a:	4f250513          	addi	a0,a0,1266 # ffffffffc02051f8 <etext+0xca8>
ffffffffc0203d0e:	e52fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(sum == 0);
ffffffffc0203d12:	00002697          	auipc	a3,0x2
ffffffffc0203d16:	1f668693          	addi	a3,a3,502 # ffffffffc0205f08 <etext+0x19b8>
ffffffffc0203d1a:	00001617          	auipc	a2,0x1
ffffffffc0203d1e:	10e60613          	addi	a2,a2,270 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203d22:	12000593          	li	a1,288
ffffffffc0203d26:	00002517          	auipc	a0,0x2
ffffffffc0203d2a:	fb250513          	addi	a0,a0,-78 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203d2e:	e32fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203d32:	00002697          	auipc	a3,0x2
ffffffffc0203d36:	15668693          	addi	a3,a3,342 # ffffffffc0205e88 <etext+0x1938>
ffffffffc0203d3a:	00001617          	auipc	a2,0x1
ffffffffc0203d3e:	0ee60613          	addi	a2,a2,238 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203d42:	0bd00593          	li	a1,189
ffffffffc0203d46:	00002517          	auipc	a0,0x2
ffffffffc0203d4a:	f9250513          	addi	a0,a0,-110 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203d4e:	e12fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203d52:	00002697          	auipc	a3,0x2
ffffffffc0203d56:	13668693          	addi	a3,a3,310 # ffffffffc0205e88 <etext+0x1938>
ffffffffc0203d5a:	00001617          	auipc	a2,0x1
ffffffffc0203d5e:	0ce60613          	addi	a2,a2,206 # ffffffffc0204e28 <etext+0x8d8>
ffffffffc0203d62:	12e00593          	li	a1,302
ffffffffc0203d66:	00002517          	auipc	a0,0x2
ffffffffc0203d6a:	f7250513          	addi	a0,a0,-142 # ffffffffc0205cd8 <etext+0x1788>
ffffffffc0203d6e:	df2fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203d72 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0203d72:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203d74:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0203d76:	f022                	sd	s0,32(sp)
ffffffffc0203d78:	ec26                	sd	s1,24(sp)
ffffffffc0203d7a:	f406                	sd	ra,40(sp)
ffffffffc0203d7c:	8432                	mv	s0,a2
ffffffffc0203d7e:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203d80:	8bfff0ef          	jal	ffffffffc020363e <find_vma>

    pgfault_num++;
ffffffffc0203d84:	0000d797          	auipc	a5,0xd
ffffffffc0203d88:	7e47a783          	lw	a5,2020(a5) # ffffffffc0211568 <pgfault_num>
ffffffffc0203d8c:	2785                	addiw	a5,a5,1
ffffffffc0203d8e:	0000d717          	auipc	a4,0xd
ffffffffc0203d92:	7cf72d23          	sw	a5,2010(a4) # ffffffffc0211568 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0203d96:	c549                	beqz	a0,ffffffffc0203e20 <do_pgfault+0xae>
ffffffffc0203d98:	651c                	ld	a5,8(a0)
ffffffffc0203d9a:	08f46363          	bltu	s0,a5,ffffffffc0203e20 <do_pgfault+0xae>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203d9e:	6d1c                	ld	a5,24(a0)
ffffffffc0203da0:	e84a                	sd	s2,16(sp)
        perm |= (PTE_R | PTE_W);
ffffffffc0203da2:	4959                	li	s2,22
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203da4:	8b89                	andi	a5,a5,2
ffffffffc0203da6:	cfa1                	beqz	a5,ffffffffc0203dfe <do_pgfault+0x8c>
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203da8:	77fd                	lui	a5,0xfffff
    *   mm->pgdir : the PDT of these vma
    *
    */


    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc0203daa:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203dac:	8c7d                	and	s0,s0,a5
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc0203dae:	85a2                	mv	a1,s0
ffffffffc0203db0:	4605                	li	a2,1
ffffffffc0203db2:	95bfd0ef          	jal	ffffffffc020170c <get_pte>
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) {
ffffffffc0203db6:	610c                	ld	a1,0(a0)
ffffffffc0203db8:	c5a9                	beqz	a1,ffffffffc0203e02 <do_pgfault+0x90>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0203dba:	0000d797          	auipc	a5,0xd
ffffffffc0203dbe:	78e7a783          	lw	a5,1934(a5) # ffffffffc0211548 <swap_init_ok>
ffffffffc0203dc2:	cba5                	beqz	a5,ffffffffc0203e32 <do_pgfault+0xc0>
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            //begin
            // 从交换区加载页面
            if (swap_in(mm, addr, &page) != 0) {
ffffffffc0203dc4:	0030                	addi	a2,sp,8
ffffffffc0203dc6:	85a2                	mv	a1,s0
ffffffffc0203dc8:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0203dca:	e402                	sd	zero,8(sp)
            if (swap_in(mm, addr, &page) != 0) {
ffffffffc0203dcc:	bd0ff0ef          	jal	ffffffffc020319c <swap_in>
ffffffffc0203dd0:	e925                	bnez	a0,ffffffffc0203e40 <do_pgfault+0xce>
                cprintf("swap_in() failed\n");
                goto failed;
            }

            // 重新映射页面
            if (page_insert(mm->pgdir, page, addr, perm) != 0) {
ffffffffc0203dd2:	65a2                	ld	a1,8(sp)
ffffffffc0203dd4:	6c88                	ld	a0,24(s1)
ffffffffc0203dd6:	86ca                	mv	a3,s2
ffffffffc0203dd8:	8622                	mv	a2,s0
ffffffffc0203dda:	c55fd0ef          	jal	ffffffffc0201a2e <page_insert>
ffffffffc0203dde:	e925                	bnez	a0,ffffffffc0203e4e <do_pgfault+0xdc>
                free_page(page);
                goto failed;
            }

            // 设置页面为可交换
            swap_map_swappable(mm, addr, page, 0);
ffffffffc0203de0:	6622                	ld	a2,8(sp)
ffffffffc0203de2:	4681                	li	a3,0
ffffffffc0203de4:	85a2                	mv	a1,s0
ffffffffc0203de6:	8526                	mv	a0,s1
ffffffffc0203de8:	a92ff0ef          	jal	ffffffffc020307a <swap_map_swappable>
            //end
            page->pra_vaddr = addr;
ffffffffc0203dec:	67a2                	ld	a5,8(sp)
ffffffffc0203dee:	e3a0                	sd	s0,64(a5)
ffffffffc0203df0:	6942                	ld	s2,16(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
ffffffffc0203df2:	4501                	li	a0,0
failed:
    return ret;
}
ffffffffc0203df4:	70a2                	ld	ra,40(sp)
ffffffffc0203df6:	7402                	ld	s0,32(sp)
ffffffffc0203df8:	64e2                	ld	s1,24(sp)
ffffffffc0203dfa:	6145                	addi	sp,sp,48
ffffffffc0203dfc:	8082                	ret
    uint32_t perm = PTE_U;
ffffffffc0203dfe:	4941                	li	s2,16
ffffffffc0203e00:	b765                	j	ffffffffc0203da8 <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0203e02:	6c88                	ld	a0,24(s1)
ffffffffc0203e04:	864a                	mv	a2,s2
ffffffffc0203e06:	85a2                	mv	a1,s0
ffffffffc0203e08:	969fe0ef          	jal	ffffffffc0202770 <pgdir_alloc_page>
ffffffffc0203e0c:	f175                	bnez	a0,ffffffffc0203df0 <do_pgfault+0x7e>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0203e0e:	00002517          	auipc	a0,0x2
ffffffffc0203e12:	17250513          	addi	a0,a0,370 # ffffffffc0205f80 <etext+0x1a30>
ffffffffc0203e16:	aa4fc0ef          	jal	ffffffffc02000ba <cprintf>
            goto failed;
ffffffffc0203e1a:	6942                	ld	s2,16(sp)
    ret = -E_NO_MEM;
ffffffffc0203e1c:	5571                	li	a0,-4
ffffffffc0203e1e:	bfd9                	j	ffffffffc0203df4 <do_pgfault+0x82>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0203e20:	85a2                	mv	a1,s0
ffffffffc0203e22:	00002517          	auipc	a0,0x2
ffffffffc0203e26:	12e50513          	addi	a0,a0,302 # ffffffffc0205f50 <etext+0x1a00>
ffffffffc0203e2a:	a90fc0ef          	jal	ffffffffc02000ba <cprintf>
    int ret = -E_INVAL;
ffffffffc0203e2e:	5575                	li	a0,-3
        goto failed;
ffffffffc0203e30:	b7d1                	j	ffffffffc0203df4 <do_pgfault+0x82>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0203e32:	00002517          	auipc	a0,0x2
ffffffffc0203e36:	1b650513          	addi	a0,a0,438 # ffffffffc0205fe8 <etext+0x1a98>
ffffffffc0203e3a:	a80fc0ef          	jal	ffffffffc02000ba <cprintf>
            goto failed;
ffffffffc0203e3e:	bff1                	j	ffffffffc0203e1a <do_pgfault+0xa8>
                cprintf("swap_in() failed\n");
ffffffffc0203e40:	00002517          	auipc	a0,0x2
ffffffffc0203e44:	16850513          	addi	a0,a0,360 # ffffffffc0205fa8 <etext+0x1a58>
ffffffffc0203e48:	a72fc0ef          	jal	ffffffffc02000ba <cprintf>
                goto failed;
ffffffffc0203e4c:	b7f9                	j	ffffffffc0203e1a <do_pgfault+0xa8>
                cprintf("page_insert() after swap_in() failed\n");
ffffffffc0203e4e:	00002517          	auipc	a0,0x2
ffffffffc0203e52:	17250513          	addi	a0,a0,370 # ffffffffc0205fc0 <etext+0x1a70>
ffffffffc0203e56:	a64fc0ef          	jal	ffffffffc02000ba <cprintf>
                free_page(page);
ffffffffc0203e5a:	6522                	ld	a0,8(sp)
ffffffffc0203e5c:	4585                	li	a1,1
ffffffffc0203e5e:	835fd0ef          	jal	ffffffffc0201692 <free_pages>
                goto failed;
ffffffffc0203e62:	bf65                	j	ffffffffc0203e1a <do_pgfault+0xa8>

ffffffffc0203e64 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203e64:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203e66:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203e68:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203e6a:	e18fc0ef          	jal	ffffffffc0200482 <ide_device_valid>
ffffffffc0203e6e:	cd01                	beqz	a0,ffffffffc0203e86 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203e70:	4505                	li	a0,1
ffffffffc0203e72:	e16fc0ef          	jal	ffffffffc0200488 <ide_device_size>
}
ffffffffc0203e76:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203e78:	810d                	srli	a0,a0,0x3
ffffffffc0203e7a:	0000d797          	auipc	a5,0xd
ffffffffc0203e7e:	6ca7bb23          	sd	a0,1750(a5) # ffffffffc0211550 <max_swap_offset>
}
ffffffffc0203e82:	0141                	addi	sp,sp,16
ffffffffc0203e84:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203e86:	00002617          	auipc	a2,0x2
ffffffffc0203e8a:	18a60613          	addi	a2,a2,394 # ffffffffc0206010 <etext+0x1ac0>
ffffffffc0203e8e:	45b5                	li	a1,13
ffffffffc0203e90:	00002517          	auipc	a0,0x2
ffffffffc0203e94:	1a050513          	addi	a0,a0,416 # ffffffffc0206030 <etext+0x1ae0>
ffffffffc0203e98:	cc8fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203e9c <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0203e9c:	1141                	addi	sp,sp,-16
ffffffffc0203e9e:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203ea0:	00855713          	srli	a4,a0,0x8
ffffffffc0203ea4:	cb2d                	beqz	a4,ffffffffc0203f16 <swapfs_read+0x7a>
ffffffffc0203ea6:	0000d797          	auipc	a5,0xd
ffffffffc0203eaa:	6aa7b783          	ld	a5,1706(a5) # ffffffffc0211550 <max_swap_offset>
ffffffffc0203eae:	06f77463          	bgeu	a4,a5,ffffffffc0203f16 <swapfs_read+0x7a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203eb2:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0203eb6:	e3978793          	addi	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c1>
ffffffffc0203eba:	07b2                	slli	a5,a5,0xc
ffffffffc0203ebc:	e3978793          	addi	a5,a5,-455
ffffffffc0203ec0:	07b2                	slli	a5,a5,0xc
ffffffffc0203ec2:	0000d697          	auipc	a3,0xd
ffffffffc0203ec6:	67e6b683          	ld	a3,1662(a3) # ffffffffc0211540 <pages>
ffffffffc0203eca:	e3978793          	addi	a5,a5,-455
ffffffffc0203ece:	8d95                	sub	a1,a1,a3
ffffffffc0203ed0:	07b2                	slli	a5,a5,0xc
ffffffffc0203ed2:	4035d613          	srai	a2,a1,0x3
ffffffffc0203ed6:	e3978793          	addi	a5,a5,-455
ffffffffc0203eda:	02f60633          	mul	a2,a2,a5
ffffffffc0203ede:	00002797          	auipc	a5,0x2
ffffffffc0203ee2:	4c27b783          	ld	a5,1218(a5) # ffffffffc02063a0 <nbase>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203ee6:	0000d697          	auipc	a3,0xd
ffffffffc0203eea:	6526b683          	ld	a3,1618(a3) # ffffffffc0211538 <npage>
ffffffffc0203eee:	0037159b          	slliw	a1,a4,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203ef2:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203ef4:	00c61793          	slli	a5,a2,0xc
ffffffffc0203ef8:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203efa:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203efc:	02d7f963          	bgeu	a5,a3,ffffffffc0203f2e <swapfs_read+0x92>
}
ffffffffc0203f00:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203f02:	0000d797          	auipc	a5,0xd
ffffffffc0203f06:	62e7b783          	ld	a5,1582(a5) # ffffffffc0211530 <va_pa_offset>
ffffffffc0203f0a:	46a1                	li	a3,8
ffffffffc0203f0c:	963e                	add	a2,a2,a5
ffffffffc0203f0e:	4505                	li	a0,1
}
ffffffffc0203f10:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203f12:	d7cfc06f          	j	ffffffffc020048e <ide_read_secs>
ffffffffc0203f16:	86aa                	mv	a3,a0
ffffffffc0203f18:	00002617          	auipc	a2,0x2
ffffffffc0203f1c:	13060613          	addi	a2,a2,304 # ffffffffc0206048 <etext+0x1af8>
ffffffffc0203f20:	45d1                	li	a1,20
ffffffffc0203f22:	00002517          	auipc	a0,0x2
ffffffffc0203f26:	10e50513          	addi	a0,a0,270 # ffffffffc0206030 <etext+0x1ae0>
ffffffffc0203f2a:	c36fc0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc0203f2e:	86b2                	mv	a3,a2
ffffffffc0203f30:	06a00593          	li	a1,106
ffffffffc0203f34:	00001617          	auipc	a2,0x1
ffffffffc0203f38:	2fc60613          	addi	a2,a2,764 # ffffffffc0205230 <etext+0xce0>
ffffffffc0203f3c:	00001517          	auipc	a0,0x1
ffffffffc0203f40:	2bc50513          	addi	a0,a0,700 # ffffffffc02051f8 <etext+0xca8>
ffffffffc0203f44:	c1cfc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203f48 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203f48:	1141                	addi	sp,sp,-16
ffffffffc0203f4a:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203f4c:	00855713          	srli	a4,a0,0x8
ffffffffc0203f50:	cb2d                	beqz	a4,ffffffffc0203fc2 <swapfs_write+0x7a>
ffffffffc0203f52:	0000d797          	auipc	a5,0xd
ffffffffc0203f56:	5fe7b783          	ld	a5,1534(a5) # ffffffffc0211550 <max_swap_offset>
ffffffffc0203f5a:	06f77463          	bgeu	a4,a5,ffffffffc0203fc2 <swapfs_write+0x7a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203f5e:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0203f62:	e3978793          	addi	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c1>
ffffffffc0203f66:	07b2                	slli	a5,a5,0xc
ffffffffc0203f68:	e3978793          	addi	a5,a5,-455
ffffffffc0203f6c:	07b2                	slli	a5,a5,0xc
ffffffffc0203f6e:	0000d697          	auipc	a3,0xd
ffffffffc0203f72:	5d26b683          	ld	a3,1490(a3) # ffffffffc0211540 <pages>
ffffffffc0203f76:	e3978793          	addi	a5,a5,-455
ffffffffc0203f7a:	8d95                	sub	a1,a1,a3
ffffffffc0203f7c:	07b2                	slli	a5,a5,0xc
ffffffffc0203f7e:	4035d613          	srai	a2,a1,0x3
ffffffffc0203f82:	e3978793          	addi	a5,a5,-455
ffffffffc0203f86:	02f60633          	mul	a2,a2,a5
ffffffffc0203f8a:	00002797          	auipc	a5,0x2
ffffffffc0203f8e:	4167b783          	ld	a5,1046(a5) # ffffffffc02063a0 <nbase>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203f92:	0000d697          	auipc	a3,0xd
ffffffffc0203f96:	5a66b683          	ld	a3,1446(a3) # ffffffffc0211538 <npage>
ffffffffc0203f9a:	0037159b          	slliw	a1,a4,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203f9e:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203fa0:	00c61793          	slli	a5,a2,0xc
ffffffffc0203fa4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203fa6:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203fa8:	02d7f963          	bgeu	a5,a3,ffffffffc0203fda <swapfs_write+0x92>
}
ffffffffc0203fac:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203fae:	0000d797          	auipc	a5,0xd
ffffffffc0203fb2:	5827b783          	ld	a5,1410(a5) # ffffffffc0211530 <va_pa_offset>
ffffffffc0203fb6:	46a1                	li	a3,8
ffffffffc0203fb8:	963e                	add	a2,a2,a5
ffffffffc0203fba:	4505                	li	a0,1
}
ffffffffc0203fbc:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203fbe:	cf4fc06f          	j	ffffffffc02004b2 <ide_write_secs>
ffffffffc0203fc2:	86aa                	mv	a3,a0
ffffffffc0203fc4:	00002617          	auipc	a2,0x2
ffffffffc0203fc8:	08460613          	addi	a2,a2,132 # ffffffffc0206048 <etext+0x1af8>
ffffffffc0203fcc:	45e5                	li	a1,25
ffffffffc0203fce:	00002517          	auipc	a0,0x2
ffffffffc0203fd2:	06250513          	addi	a0,a0,98 # ffffffffc0206030 <etext+0x1ae0>
ffffffffc0203fd6:	b8afc0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc0203fda:	86b2                	mv	a3,a2
ffffffffc0203fdc:	06a00593          	li	a1,106
ffffffffc0203fe0:	00001617          	auipc	a2,0x1
ffffffffc0203fe4:	25060613          	addi	a2,a2,592 # ffffffffc0205230 <etext+0xce0>
ffffffffc0203fe8:	00001517          	auipc	a0,0x1
ffffffffc0203fec:	21050513          	addi	a0,a0,528 # ffffffffc02051f8 <etext+0xca8>
ffffffffc0203ff0:	b70fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203ff4 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203ff4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203ff8:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203ffa:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203ffe:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0204000:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204004:	f022                	sd	s0,32(sp)
ffffffffc0204006:	ec26                	sd	s1,24(sp)
ffffffffc0204008:	e84a                	sd	s2,16(sp)
ffffffffc020400a:	f406                	sd	ra,40(sp)
ffffffffc020400c:	84aa                	mv	s1,a0
ffffffffc020400e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0204010:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0204014:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0204016:	05067063          	bgeu	a2,a6,ffffffffc0204056 <printnum+0x62>
ffffffffc020401a:	e44e                	sd	s3,8(sp)
ffffffffc020401c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020401e:	4785                	li	a5,1
ffffffffc0204020:	00e7d763          	bge	a5,a4,ffffffffc020402e <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0204024:	85ca                	mv	a1,s2
ffffffffc0204026:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0204028:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020402a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020402c:	fc65                	bnez	s0,ffffffffc0204024 <printnum+0x30>
ffffffffc020402e:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204030:	1a02                	slli	s4,s4,0x20
ffffffffc0204032:	020a5a13          	srli	s4,s4,0x20
ffffffffc0204036:	00002797          	auipc	a5,0x2
ffffffffc020403a:	03278793          	addi	a5,a5,50 # ffffffffc0206068 <etext+0x1b18>
ffffffffc020403e:	97d2                	add	a5,a5,s4
}
ffffffffc0204040:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204042:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0204046:	70a2                	ld	ra,40(sp)
ffffffffc0204048:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020404a:	85ca                	mv	a1,s2
ffffffffc020404c:	87a6                	mv	a5,s1
}
ffffffffc020404e:	6942                	ld	s2,16(sp)
ffffffffc0204050:	64e2                	ld	s1,24(sp)
ffffffffc0204052:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204054:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0204056:	03065633          	divu	a2,a2,a6
ffffffffc020405a:	8722                	mv	a4,s0
ffffffffc020405c:	f99ff0ef          	jal	ffffffffc0203ff4 <printnum>
ffffffffc0204060:	bfc1                	j	ffffffffc0204030 <printnum+0x3c>

ffffffffc0204062 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0204062:	7119                	addi	sp,sp,-128
ffffffffc0204064:	f4a6                	sd	s1,104(sp)
ffffffffc0204066:	f0ca                	sd	s2,96(sp)
ffffffffc0204068:	ecce                	sd	s3,88(sp)
ffffffffc020406a:	e8d2                	sd	s4,80(sp)
ffffffffc020406c:	e4d6                	sd	s5,72(sp)
ffffffffc020406e:	e0da                	sd	s6,64(sp)
ffffffffc0204070:	f862                	sd	s8,48(sp)
ffffffffc0204072:	fc86                	sd	ra,120(sp)
ffffffffc0204074:	f8a2                	sd	s0,112(sp)
ffffffffc0204076:	fc5e                	sd	s7,56(sp)
ffffffffc0204078:	f466                	sd	s9,40(sp)
ffffffffc020407a:	f06a                	sd	s10,32(sp)
ffffffffc020407c:	ec6e                	sd	s11,24(sp)
ffffffffc020407e:	892a                	mv	s2,a0
ffffffffc0204080:	84ae                	mv	s1,a1
ffffffffc0204082:	8c32                	mv	s8,a2
ffffffffc0204084:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204086:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020408a:	05500b13          	li	s6,85
ffffffffc020408e:	00002a97          	auipc	s5,0x2
ffffffffc0204092:	182a8a93          	addi	s5,s5,386 # ffffffffc0206210 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204096:	000c4503          	lbu	a0,0(s8)
ffffffffc020409a:	001c0413          	addi	s0,s8,1
ffffffffc020409e:	01350a63          	beq	a0,s3,ffffffffc02040b2 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02040a2:	cd0d                	beqz	a0,ffffffffc02040dc <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02040a4:	85a6                	mv	a1,s1
ffffffffc02040a6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02040a8:	00044503          	lbu	a0,0(s0)
ffffffffc02040ac:	0405                	addi	s0,s0,1
ffffffffc02040ae:	ff351ae3          	bne	a0,s3,ffffffffc02040a2 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc02040b2:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02040b6:	4b81                	li	s7,0
ffffffffc02040b8:	4601                	li	a2,0
        width = precision = -1;
ffffffffc02040ba:	5d7d                	li	s10,-1
ffffffffc02040bc:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040be:	00044683          	lbu	a3,0(s0)
ffffffffc02040c2:	00140c13          	addi	s8,s0,1
ffffffffc02040c6:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02040ca:	0ff5f593          	zext.b	a1,a1
ffffffffc02040ce:	02bb6663          	bltu	s6,a1,ffffffffc02040fa <vprintfmt+0x98>
ffffffffc02040d2:	058a                	slli	a1,a1,0x2
ffffffffc02040d4:	95d6                	add	a1,a1,s5
ffffffffc02040d6:	4198                	lw	a4,0(a1)
ffffffffc02040d8:	9756                	add	a4,a4,s5
ffffffffc02040da:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02040dc:	70e6                	ld	ra,120(sp)
ffffffffc02040de:	7446                	ld	s0,112(sp)
ffffffffc02040e0:	74a6                	ld	s1,104(sp)
ffffffffc02040e2:	7906                	ld	s2,96(sp)
ffffffffc02040e4:	69e6                	ld	s3,88(sp)
ffffffffc02040e6:	6a46                	ld	s4,80(sp)
ffffffffc02040e8:	6aa6                	ld	s5,72(sp)
ffffffffc02040ea:	6b06                	ld	s6,64(sp)
ffffffffc02040ec:	7be2                	ld	s7,56(sp)
ffffffffc02040ee:	7c42                	ld	s8,48(sp)
ffffffffc02040f0:	7ca2                	ld	s9,40(sp)
ffffffffc02040f2:	7d02                	ld	s10,32(sp)
ffffffffc02040f4:	6de2                	ld	s11,24(sp)
ffffffffc02040f6:	6109                	addi	sp,sp,128
ffffffffc02040f8:	8082                	ret
            putch('%', putdat);
ffffffffc02040fa:	85a6                	mv	a1,s1
ffffffffc02040fc:	02500513          	li	a0,37
ffffffffc0204100:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204102:	fff44703          	lbu	a4,-1(s0)
ffffffffc0204106:	02500793          	li	a5,37
ffffffffc020410a:	8c22                	mv	s8,s0
ffffffffc020410c:	f8f705e3          	beq	a4,a5,ffffffffc0204096 <vprintfmt+0x34>
ffffffffc0204110:	02500713          	li	a4,37
ffffffffc0204114:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0204118:	1c7d                	addi	s8,s8,-1
ffffffffc020411a:	fee79de3          	bne	a5,a4,ffffffffc0204114 <vprintfmt+0xb2>
ffffffffc020411e:	bfa5                	j	ffffffffc0204096 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0204120:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0204124:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0204126:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc020412a:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc020412e:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204132:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0204134:	02b76563          	bltu	a4,a1,ffffffffc020415e <vprintfmt+0xfc>
ffffffffc0204138:	4525                	li	a0,9
                ch = *fmt;
ffffffffc020413a:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020413e:	002d171b          	slliw	a4,s10,0x2
ffffffffc0204142:	01a7073b          	addw	a4,a4,s10
ffffffffc0204146:	0017171b          	slliw	a4,a4,0x1
ffffffffc020414a:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc020414c:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0204150:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204152:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0204156:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc020415a:	feb570e3          	bgeu	a0,a1,ffffffffc020413a <vprintfmt+0xd8>
            if (width < 0)
ffffffffc020415e:	f60cd0e3          	bgez	s9,ffffffffc02040be <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0204162:	8cea                	mv	s9,s10
ffffffffc0204164:	5d7d                	li	s10,-1
ffffffffc0204166:	bfa1                	j	ffffffffc02040be <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204168:	8db6                	mv	s11,a3
ffffffffc020416a:	8462                	mv	s0,s8
ffffffffc020416c:	bf89                	j	ffffffffc02040be <vprintfmt+0x5c>
ffffffffc020416e:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0204170:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0204172:	b7b1                	j	ffffffffc02040be <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0204174:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204176:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc020417a:	00c7c463          	blt	a5,a2,ffffffffc0204182 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc020417e:	1a060163          	beqz	a2,ffffffffc0204320 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0204182:	000a3603          	ld	a2,0(s4)
ffffffffc0204186:	46c1                	li	a3,16
ffffffffc0204188:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020418a:	000d879b          	sext.w	a5,s11
ffffffffc020418e:	8766                	mv	a4,s9
ffffffffc0204190:	85a6                	mv	a1,s1
ffffffffc0204192:	854a                	mv	a0,s2
ffffffffc0204194:	e61ff0ef          	jal	ffffffffc0203ff4 <printnum>
            break;
ffffffffc0204198:	bdfd                	j	ffffffffc0204096 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc020419a:	000a2503          	lw	a0,0(s4)
ffffffffc020419e:	85a6                	mv	a1,s1
ffffffffc02041a0:	0a21                	addi	s4,s4,8
ffffffffc02041a2:	9902                	jalr	s2
            break;
ffffffffc02041a4:	bdcd                	j	ffffffffc0204096 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02041a6:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02041a8:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc02041ac:	00c7c463          	blt	a5,a2,ffffffffc02041b4 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc02041b0:	16060363          	beqz	a2,ffffffffc0204316 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc02041b4:	000a3603          	ld	a2,0(s4)
ffffffffc02041b8:	46a9                	li	a3,10
ffffffffc02041ba:	8a3a                	mv	s4,a4
ffffffffc02041bc:	b7f9                	j	ffffffffc020418a <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc02041be:	85a6                	mv	a1,s1
ffffffffc02041c0:	03000513          	li	a0,48
ffffffffc02041c4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02041c6:	85a6                	mv	a1,s1
ffffffffc02041c8:	07800513          	li	a0,120
ffffffffc02041cc:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02041ce:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02041d2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02041d4:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02041d6:	bf55                	j	ffffffffc020418a <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc02041d8:	85a6                	mv	a1,s1
ffffffffc02041da:	02500513          	li	a0,37
ffffffffc02041de:	9902                	jalr	s2
            break;
ffffffffc02041e0:	bd5d                	j	ffffffffc0204096 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02041e2:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041e6:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02041e8:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02041ea:	bf95                	j	ffffffffc020415e <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc02041ec:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02041ee:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc02041f2:	00c7c463          	blt	a5,a2,ffffffffc02041fa <vprintfmt+0x198>
    else if (lflag) {
ffffffffc02041f6:	10060b63          	beqz	a2,ffffffffc020430c <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc02041fa:	000a3603          	ld	a2,0(s4)
ffffffffc02041fe:	46a1                	li	a3,8
ffffffffc0204200:	8a3a                	mv	s4,a4
ffffffffc0204202:	b761                	j	ffffffffc020418a <vprintfmt+0x128>
            if (width < 0)
ffffffffc0204204:	fffcc793          	not	a5,s9
ffffffffc0204208:	97fd                	srai	a5,a5,0x3f
ffffffffc020420a:	00fcf7b3          	and	a5,s9,a5
ffffffffc020420e:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204212:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0204214:	b56d                	j	ffffffffc02040be <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204216:	000a3403          	ld	s0,0(s4)
ffffffffc020421a:	008a0793          	addi	a5,s4,8
ffffffffc020421e:	e43e                	sd	a5,8(sp)
ffffffffc0204220:	12040063          	beqz	s0,ffffffffc0204340 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0204224:	0d905963          	blez	s9,ffffffffc02042f6 <vprintfmt+0x294>
ffffffffc0204228:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020422c:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0204230:	12fd9763          	bne	s11,a5,ffffffffc020435e <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204234:	00044783          	lbu	a5,0(s0)
ffffffffc0204238:	0007851b          	sext.w	a0,a5
ffffffffc020423c:	cb9d                	beqz	a5,ffffffffc0204272 <vprintfmt+0x210>
ffffffffc020423e:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204240:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204244:	000d4563          	bltz	s10,ffffffffc020424e <vprintfmt+0x1ec>
ffffffffc0204248:	3d7d                	addiw	s10,s10,-1
ffffffffc020424a:	028d0263          	beq	s10,s0,ffffffffc020426e <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc020424e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204250:	0c0b8d63          	beqz	s7,ffffffffc020432a <vprintfmt+0x2c8>
ffffffffc0204254:	3781                	addiw	a5,a5,-32
ffffffffc0204256:	0cfdfa63          	bgeu	s11,a5,ffffffffc020432a <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc020425a:	03f00513          	li	a0,63
ffffffffc020425e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204260:	000a4783          	lbu	a5,0(s4)
ffffffffc0204264:	3cfd                	addiw	s9,s9,-1
ffffffffc0204266:	0a05                	addi	s4,s4,1
ffffffffc0204268:	0007851b          	sext.w	a0,a5
ffffffffc020426c:	ffe1                	bnez	a5,ffffffffc0204244 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc020426e:	01905963          	blez	s9,ffffffffc0204280 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0204272:	85a6                	mv	a1,s1
ffffffffc0204274:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0204278:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc020427a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020427c:	fe0c9be3          	bnez	s9,ffffffffc0204272 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204280:	6a22                	ld	s4,8(sp)
ffffffffc0204282:	bd11                	j	ffffffffc0204096 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0204284:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204286:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc020428a:	00c7c363          	blt	a5,a2,ffffffffc0204290 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc020428e:	ce25                	beqz	a2,ffffffffc0204306 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0204290:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0204294:	08044d63          	bltz	s0,ffffffffc020432e <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0204298:	8622                	mv	a2,s0
ffffffffc020429a:	8a5e                	mv	s4,s7
ffffffffc020429c:	46a9                	li	a3,10
ffffffffc020429e:	b5f5                	j	ffffffffc020418a <vprintfmt+0x128>
            if (err < 0) {
ffffffffc02042a0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02042a4:	4619                	li	a2,6
            if (err < 0) {
ffffffffc02042a6:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02042aa:	8fb9                	xor	a5,a5,a4
ffffffffc02042ac:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02042b0:	02d64663          	blt	a2,a3,ffffffffc02042dc <vprintfmt+0x27a>
ffffffffc02042b4:	00369713          	slli	a4,a3,0x3
ffffffffc02042b8:	00002797          	auipc	a5,0x2
ffffffffc02042bc:	0b078793          	addi	a5,a5,176 # ffffffffc0206368 <error_string>
ffffffffc02042c0:	97ba                	add	a5,a5,a4
ffffffffc02042c2:	639c                	ld	a5,0(a5)
ffffffffc02042c4:	cf81                	beqz	a5,ffffffffc02042dc <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02042c6:	86be                	mv	a3,a5
ffffffffc02042c8:	00002617          	auipc	a2,0x2
ffffffffc02042cc:	dd060613          	addi	a2,a2,-560 # ffffffffc0206098 <etext+0x1b48>
ffffffffc02042d0:	85a6                	mv	a1,s1
ffffffffc02042d2:	854a                	mv	a0,s2
ffffffffc02042d4:	0e8000ef          	jal	ffffffffc02043bc <printfmt>
            err = va_arg(ap, int);
ffffffffc02042d8:	0a21                	addi	s4,s4,8
ffffffffc02042da:	bb75                	j	ffffffffc0204096 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02042dc:	00002617          	auipc	a2,0x2
ffffffffc02042e0:	dac60613          	addi	a2,a2,-596 # ffffffffc0206088 <etext+0x1b38>
ffffffffc02042e4:	85a6                	mv	a1,s1
ffffffffc02042e6:	854a                	mv	a0,s2
ffffffffc02042e8:	0d4000ef          	jal	ffffffffc02043bc <printfmt>
            err = va_arg(ap, int);
ffffffffc02042ec:	0a21                	addi	s4,s4,8
ffffffffc02042ee:	b365                	j	ffffffffc0204096 <vprintfmt+0x34>
            lflag ++;
ffffffffc02042f0:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02042f2:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02042f4:	b3e9                	j	ffffffffc02040be <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02042f6:	00044783          	lbu	a5,0(s0)
ffffffffc02042fa:	0007851b          	sext.w	a0,a5
ffffffffc02042fe:	d3c9                	beqz	a5,ffffffffc0204280 <vprintfmt+0x21e>
ffffffffc0204300:	00140a13          	addi	s4,s0,1
ffffffffc0204304:	bf2d                	j	ffffffffc020423e <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0204306:	000a2403          	lw	s0,0(s4)
ffffffffc020430a:	b769                	j	ffffffffc0204294 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc020430c:	000a6603          	lwu	a2,0(s4)
ffffffffc0204310:	46a1                	li	a3,8
ffffffffc0204312:	8a3a                	mv	s4,a4
ffffffffc0204314:	bd9d                	j	ffffffffc020418a <vprintfmt+0x128>
ffffffffc0204316:	000a6603          	lwu	a2,0(s4)
ffffffffc020431a:	46a9                	li	a3,10
ffffffffc020431c:	8a3a                	mv	s4,a4
ffffffffc020431e:	b5b5                	j	ffffffffc020418a <vprintfmt+0x128>
ffffffffc0204320:	000a6603          	lwu	a2,0(s4)
ffffffffc0204324:	46c1                	li	a3,16
ffffffffc0204326:	8a3a                	mv	s4,a4
ffffffffc0204328:	b58d                	j	ffffffffc020418a <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc020432a:	9902                	jalr	s2
ffffffffc020432c:	bf15                	j	ffffffffc0204260 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc020432e:	85a6                	mv	a1,s1
ffffffffc0204330:	02d00513          	li	a0,45
ffffffffc0204334:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204336:	40800633          	neg	a2,s0
ffffffffc020433a:	8a5e                	mv	s4,s7
ffffffffc020433c:	46a9                	li	a3,10
ffffffffc020433e:	b5b1                	j	ffffffffc020418a <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0204340:	01905663          	blez	s9,ffffffffc020434c <vprintfmt+0x2ea>
ffffffffc0204344:	02d00793          	li	a5,45
ffffffffc0204348:	04fd9263          	bne	s11,a5,ffffffffc020438c <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020434c:	02800793          	li	a5,40
ffffffffc0204350:	00002a17          	auipc	s4,0x2
ffffffffc0204354:	d31a0a13          	addi	s4,s4,-719 # ffffffffc0206081 <etext+0x1b31>
ffffffffc0204358:	02800513          	li	a0,40
ffffffffc020435c:	b5cd                	j	ffffffffc020423e <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020435e:	85ea                	mv	a1,s10
ffffffffc0204360:	8522                	mv	a0,s0
ffffffffc0204362:	148000ef          	jal	ffffffffc02044aa <strnlen>
ffffffffc0204366:	40ac8cbb          	subw	s9,s9,a0
ffffffffc020436a:	01905963          	blez	s9,ffffffffc020437c <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc020436e:	2d81                	sext.w	s11,s11
ffffffffc0204370:	85a6                	mv	a1,s1
ffffffffc0204372:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204374:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0204376:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204378:	fe0c9ce3          	bnez	s9,ffffffffc0204370 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020437c:	00044783          	lbu	a5,0(s0)
ffffffffc0204380:	0007851b          	sext.w	a0,a5
ffffffffc0204384:	ea079de3          	bnez	a5,ffffffffc020423e <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204388:	6a22                	ld	s4,8(sp)
ffffffffc020438a:	b331                	j	ffffffffc0204096 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020438c:	85ea                	mv	a1,s10
ffffffffc020438e:	00002517          	auipc	a0,0x2
ffffffffc0204392:	cf250513          	addi	a0,a0,-782 # ffffffffc0206080 <etext+0x1b30>
ffffffffc0204396:	114000ef          	jal	ffffffffc02044aa <strnlen>
ffffffffc020439a:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc020439e:	00002417          	auipc	s0,0x2
ffffffffc02043a2:	ce240413          	addi	s0,s0,-798 # ffffffffc0206080 <etext+0x1b30>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02043a6:	00002a17          	auipc	s4,0x2
ffffffffc02043aa:	cdba0a13          	addi	s4,s4,-805 # ffffffffc0206081 <etext+0x1b31>
ffffffffc02043ae:	02800793          	li	a5,40
ffffffffc02043b2:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02043b6:	fb904ce3          	bgtz	s9,ffffffffc020436e <vprintfmt+0x30c>
ffffffffc02043ba:	b551                	j	ffffffffc020423e <vprintfmt+0x1dc>

ffffffffc02043bc <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02043bc:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02043be:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02043c2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02043c4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02043c6:	ec06                	sd	ra,24(sp)
ffffffffc02043c8:	f83a                	sd	a4,48(sp)
ffffffffc02043ca:	fc3e                	sd	a5,56(sp)
ffffffffc02043cc:	e0c2                	sd	a6,64(sp)
ffffffffc02043ce:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02043d0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02043d2:	c91ff0ef          	jal	ffffffffc0204062 <vprintfmt>
}
ffffffffc02043d6:	60e2                	ld	ra,24(sp)
ffffffffc02043d8:	6161                	addi	sp,sp,80
ffffffffc02043da:	8082                	ret

ffffffffc02043dc <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02043dc:	715d                	addi	sp,sp,-80
ffffffffc02043de:	e486                	sd	ra,72(sp)
ffffffffc02043e0:	e0a2                	sd	s0,64(sp)
ffffffffc02043e2:	fc26                	sd	s1,56(sp)
ffffffffc02043e4:	f84a                	sd	s2,48(sp)
ffffffffc02043e6:	f44e                	sd	s3,40(sp)
ffffffffc02043e8:	f052                	sd	s4,32(sp)
ffffffffc02043ea:	ec56                	sd	s5,24(sp)
ffffffffc02043ec:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc02043ee:	c901                	beqz	a0,ffffffffc02043fe <readline+0x22>
ffffffffc02043f0:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02043f2:	00002517          	auipc	a0,0x2
ffffffffc02043f6:	ca650513          	addi	a0,a0,-858 # ffffffffc0206098 <etext+0x1b48>
ffffffffc02043fa:	cc1fb0ef          	jal	ffffffffc02000ba <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02043fe:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204400:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc0204402:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0204404:	4a29                	li	s4,10
ffffffffc0204406:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc0204408:	0000db17          	auipc	s6,0xd
ffffffffc020440c:	cf0b0b13          	addi	s6,s6,-784 # ffffffffc02110f8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204410:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc0204414:	cddfb0ef          	jal	ffffffffc02000f0 <getchar>
        if (c < 0) {
ffffffffc0204418:	00054a63          	bltz	a0,ffffffffc020442c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020441c:	00a4da63          	bge	s1,a0,ffffffffc0204430 <readline+0x54>
ffffffffc0204420:	0289d263          	bge	s3,s0,ffffffffc0204444 <readline+0x68>
        c = getchar();
ffffffffc0204424:	ccdfb0ef          	jal	ffffffffc02000f0 <getchar>
        if (c < 0) {
ffffffffc0204428:	fe055ae3          	bgez	a0,ffffffffc020441c <readline+0x40>
            return NULL;
ffffffffc020442c:	4501                	li	a0,0
ffffffffc020442e:	a091                	j	ffffffffc0204472 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0204430:	03251463          	bne	a0,s2,ffffffffc0204458 <readline+0x7c>
ffffffffc0204434:	04804963          	bgtz	s0,ffffffffc0204486 <readline+0xaa>
        c = getchar();
ffffffffc0204438:	cb9fb0ef          	jal	ffffffffc02000f0 <getchar>
        if (c < 0) {
ffffffffc020443c:	fe0548e3          	bltz	a0,ffffffffc020442c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204440:	fea4d8e3          	bge	s1,a0,ffffffffc0204430 <readline+0x54>
            cputchar(c);
ffffffffc0204444:	e42a                	sd	a0,8(sp)
ffffffffc0204446:	ca9fb0ef          	jal	ffffffffc02000ee <cputchar>
            buf[i ++] = c;
ffffffffc020444a:	6522                	ld	a0,8(sp)
ffffffffc020444c:	008b07b3          	add	a5,s6,s0
ffffffffc0204450:	2405                	addiw	s0,s0,1
ffffffffc0204452:	00a78023          	sb	a0,0(a5)
ffffffffc0204456:	bf7d                	j	ffffffffc0204414 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0204458:	01450463          	beq	a0,s4,ffffffffc0204460 <readline+0x84>
ffffffffc020445c:	fb551ce3          	bne	a0,s5,ffffffffc0204414 <readline+0x38>
            cputchar(c);
ffffffffc0204460:	c8ffb0ef          	jal	ffffffffc02000ee <cputchar>
            buf[i] = '\0';
ffffffffc0204464:	0000d517          	auipc	a0,0xd
ffffffffc0204468:	c9450513          	addi	a0,a0,-876 # ffffffffc02110f8 <buf>
ffffffffc020446c:	942a                	add	s0,s0,a0
ffffffffc020446e:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0204472:	60a6                	ld	ra,72(sp)
ffffffffc0204474:	6406                	ld	s0,64(sp)
ffffffffc0204476:	74e2                	ld	s1,56(sp)
ffffffffc0204478:	7942                	ld	s2,48(sp)
ffffffffc020447a:	79a2                	ld	s3,40(sp)
ffffffffc020447c:	7a02                	ld	s4,32(sp)
ffffffffc020447e:	6ae2                	ld	s5,24(sp)
ffffffffc0204480:	6b42                	ld	s6,16(sp)
ffffffffc0204482:	6161                	addi	sp,sp,80
ffffffffc0204484:	8082                	ret
            cputchar(c);
ffffffffc0204486:	4521                	li	a0,8
ffffffffc0204488:	c67fb0ef          	jal	ffffffffc02000ee <cputchar>
            i --;
ffffffffc020448c:	347d                	addiw	s0,s0,-1
ffffffffc020448e:	b759                	j	ffffffffc0204414 <readline+0x38>

ffffffffc0204490 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0204490:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0204494:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0204496:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0204498:	cb81                	beqz	a5,ffffffffc02044a8 <strlen+0x18>
        cnt ++;
ffffffffc020449a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020449c:	00a707b3          	add	a5,a4,a0
ffffffffc02044a0:	0007c783          	lbu	a5,0(a5)
ffffffffc02044a4:	fbfd                	bnez	a5,ffffffffc020449a <strlen+0xa>
ffffffffc02044a6:	8082                	ret
    }
    return cnt;
}
ffffffffc02044a8:	8082                	ret

ffffffffc02044aa <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02044aa:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02044ac:	e589                	bnez	a1,ffffffffc02044b6 <strnlen+0xc>
ffffffffc02044ae:	a811                	j	ffffffffc02044c2 <strnlen+0x18>
        cnt ++;
ffffffffc02044b0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02044b2:	00f58863          	beq	a1,a5,ffffffffc02044c2 <strnlen+0x18>
ffffffffc02044b6:	00f50733          	add	a4,a0,a5
ffffffffc02044ba:	00074703          	lbu	a4,0(a4)
ffffffffc02044be:	fb6d                	bnez	a4,ffffffffc02044b0 <strnlen+0x6>
ffffffffc02044c0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02044c2:	852e                	mv	a0,a1
ffffffffc02044c4:	8082                	ret

ffffffffc02044c6 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02044c6:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02044c8:	0005c703          	lbu	a4,0(a1)
ffffffffc02044cc:	0785                	addi	a5,a5,1
ffffffffc02044ce:	0585                	addi	a1,a1,1
ffffffffc02044d0:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02044d4:	fb75                	bnez	a4,ffffffffc02044c8 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02044d6:	8082                	ret

ffffffffc02044d8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02044d8:	00054783          	lbu	a5,0(a0)
ffffffffc02044dc:	e791                	bnez	a5,ffffffffc02044e8 <strcmp+0x10>
ffffffffc02044de:	a02d                	j	ffffffffc0204508 <strcmp+0x30>
ffffffffc02044e0:	00054783          	lbu	a5,0(a0)
ffffffffc02044e4:	cf89                	beqz	a5,ffffffffc02044fe <strcmp+0x26>
ffffffffc02044e6:	85b6                	mv	a1,a3
ffffffffc02044e8:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02044ec:	0505                	addi	a0,a0,1
ffffffffc02044ee:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02044f2:	fef707e3          	beq	a4,a5,ffffffffc02044e0 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02044f6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02044fa:	9d19                	subw	a0,a0,a4
ffffffffc02044fc:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02044fe:	0015c703          	lbu	a4,1(a1)
ffffffffc0204502:	4501                	li	a0,0
}
ffffffffc0204504:	9d19                	subw	a0,a0,a4
ffffffffc0204506:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204508:	0005c703          	lbu	a4,0(a1)
ffffffffc020450c:	4501                	li	a0,0
ffffffffc020450e:	b7f5                	j	ffffffffc02044fa <strcmp+0x22>

ffffffffc0204510 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0204510:	00054783          	lbu	a5,0(a0)
ffffffffc0204514:	c799                	beqz	a5,ffffffffc0204522 <strchr+0x12>
        if (*s == c) {
ffffffffc0204516:	00f58763          	beq	a1,a5,ffffffffc0204524 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020451a:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020451e:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204520:	fbfd                	bnez	a5,ffffffffc0204516 <strchr+0x6>
    }
    return NULL;
ffffffffc0204522:	4501                	li	a0,0
}
ffffffffc0204524:	8082                	ret

ffffffffc0204526 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204526:	ca01                	beqz	a2,ffffffffc0204536 <memset+0x10>
ffffffffc0204528:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020452a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020452c:	0785                	addi	a5,a5,1
ffffffffc020452e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204532:	fef61de3          	bne	a2,a5,ffffffffc020452c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204536:	8082                	ret

ffffffffc0204538 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204538:	ca19                	beqz	a2,ffffffffc020454e <memcpy+0x16>
ffffffffc020453a:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020453c:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020453e:	0005c703          	lbu	a4,0(a1)
ffffffffc0204542:	0585                	addi	a1,a1,1
ffffffffc0204544:	0785                	addi	a5,a5,1
ffffffffc0204546:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020454a:	feb61ae3          	bne	a2,a1,ffffffffc020453e <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020454e:	8082                	ret
