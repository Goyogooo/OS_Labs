
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
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
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fe650513          	addi	a0,a0,-26 # ffffffffc0206018 <free_area>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	44660613          	addi	a2,a2,1094 # ffffffffc0206480 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	247010ef          	jal	ffffffffc0201a90 <memset>
    cons_init();  // init the console
ffffffffc020004e:	3f8000ef          	jal	ffffffffc0200446 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	a5650513          	addi	a0,a0,-1450 # ffffffffc0201aa8 <etext+0x6>
ffffffffc020005a:	08e000ef          	jal	ffffffffc02000e8 <cputs>

    print_kerninfo();
ffffffffc020005e:	0e8000ef          	jal	ffffffffc0200146 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	3fe000ef          	jal	ffffffffc0200460 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	316010ef          	jal	ffffffffc020137c <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3f6000ef          	jal	ffffffffc0200460 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	396000ef          	jal	ffffffffc0200404 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3e2000ef          	jal	ffffffffc0200454 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3c8000ef          	jal	ffffffffc0200448 <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	4e8010ef          	jal	ffffffffc020158e <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	f42e                	sd	a1,40(sp)
ffffffffc02000ba:	f832                	sd	a2,48(sp)
ffffffffc02000bc:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	862a                	mv	a2,a0
ffffffffc02000c0:	004c                	addi	a1,sp,4
ffffffffc02000c2:	00000517          	auipc	a0,0x0
ffffffffc02000c6:	fb650513          	addi	a0,a0,-74 # ffffffffc0200078 <cputch>
ffffffffc02000ca:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000cc:	ec06                	sd	ra,24(sp)
ffffffffc02000ce:	e0ba                	sd	a4,64(sp)
ffffffffc02000d0:	e4be                	sd	a5,72(sp)
ffffffffc02000d2:	e8c2                	sd	a6,80(sp)
ffffffffc02000d4:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d6:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000d8:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000da:	4b4010ef          	jal	ffffffffc020158e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000de:	60e2                	ld	ra,24(sp)
ffffffffc02000e0:	4512                	lw	a0,4(sp)
ffffffffc02000e2:	6125                	addi	sp,sp,96
ffffffffc02000e4:	8082                	ret

ffffffffc02000e6 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e6:	a68d                	j	ffffffffc0200448 <cons_putc>

ffffffffc02000e8 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000e8:	1101                	addi	sp,sp,-32
ffffffffc02000ea:	ec06                	sd	ra,24(sp)
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f0:	00054503          	lbu	a0,0(a0)
ffffffffc02000f4:	c905                	beqz	a0,ffffffffc0200124 <cputs+0x3c>
ffffffffc02000f6:	e426                	sd	s1,8(sp)
ffffffffc02000f8:	00178493          	addi	s1,a5,1
ffffffffc02000fc:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc02000fe:	34a000ef          	jal	ffffffffc0200448 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200102:	00044503          	lbu	a0,0(s0)
ffffffffc0200106:	87a2                	mv	a5,s0
ffffffffc0200108:	0405                	addi	s0,s0,1
ffffffffc020010a:	f975                	bnez	a0,ffffffffc02000fe <cputs+0x16>
    (*cnt) ++;
ffffffffc020010c:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc020010e:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc0200110:	0027841b          	addiw	s0,a5,2
ffffffffc0200114:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc0200116:	332000ef          	jal	ffffffffc0200448 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	6105                	addi	sp,sp,32
ffffffffc0200122:	8082                	ret
    cons_putc(c);
ffffffffc0200124:	4529                	li	a0,10
ffffffffc0200126:	322000ef          	jal	ffffffffc0200448 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
}
ffffffffc020012c:	60e2                	ld	ra,24(sp)
ffffffffc020012e:	8522                	mv	a0,s0
ffffffffc0200130:	6442                	ld	s0,16(sp)
ffffffffc0200132:	6105                	addi	sp,sp,32
ffffffffc0200134:	8082                	ret

ffffffffc0200136 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200136:	1141                	addi	sp,sp,-16
ffffffffc0200138:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020013a:	316000ef          	jal	ffffffffc0200450 <cons_getc>
ffffffffc020013e:	dd75                	beqz	a0,ffffffffc020013a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200140:	60a2                	ld	ra,8(sp)
ffffffffc0200142:	0141                	addi	sp,sp,16
ffffffffc0200144:	8082                	ret

ffffffffc0200146 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200146:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200148:	00002517          	auipc	a0,0x2
ffffffffc020014c:	98050513          	addi	a0,a0,-1664 # ffffffffc0201ac8 <etext+0x26>
void print_kerninfo(void) {
ffffffffc0200150:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200152:	f61ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200156:	00000597          	auipc	a1,0x0
ffffffffc020015a:	edc58593          	addi	a1,a1,-292 # ffffffffc0200032 <kern_init>
ffffffffc020015e:	00002517          	auipc	a0,0x2
ffffffffc0200162:	98a50513          	addi	a0,a0,-1654 # ffffffffc0201ae8 <etext+0x46>
ffffffffc0200166:	f4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020016a:	00002597          	auipc	a1,0x2
ffffffffc020016e:	93858593          	addi	a1,a1,-1736 # ffffffffc0201aa2 <etext>
ffffffffc0200172:	00002517          	auipc	a0,0x2
ffffffffc0200176:	99650513          	addi	a0,a0,-1642 # ffffffffc0201b08 <etext+0x66>
ffffffffc020017a:	f39ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020017e:	00006597          	auipc	a1,0x6
ffffffffc0200182:	e9a58593          	addi	a1,a1,-358 # ffffffffc0206018 <free_area>
ffffffffc0200186:	00002517          	auipc	a0,0x2
ffffffffc020018a:	9a250513          	addi	a0,a0,-1630 # ffffffffc0201b28 <etext+0x86>
ffffffffc020018e:	f25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200192:	00006597          	auipc	a1,0x6
ffffffffc0200196:	2ee58593          	addi	a1,a1,750 # ffffffffc0206480 <end>
ffffffffc020019a:	00002517          	auipc	a0,0x2
ffffffffc020019e:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0201b48 <etext+0xa6>
ffffffffc02001a2:	f11ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001a6:	00006797          	auipc	a5,0x6
ffffffffc02001aa:	6d978793          	addi	a5,a5,1753 # ffffffffc020687f <end+0x3ff>
ffffffffc02001ae:	00000717          	auipc	a4,0x0
ffffffffc02001b2:	e8470713          	addi	a4,a4,-380 # ffffffffc0200032 <kern_init>
ffffffffc02001b6:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b8:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001bc:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001be:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001c2:	95be                	add	a1,a1,a5
ffffffffc02001c4:	85a9                	srai	a1,a1,0xa
ffffffffc02001c6:	00002517          	auipc	a0,0x2
ffffffffc02001ca:	9a250513          	addi	a0,a0,-1630 # ffffffffc0201b68 <etext+0xc6>
}
ffffffffc02001ce:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d0:	b5cd                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001d2 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001d2:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d4:	00002617          	auipc	a2,0x2
ffffffffc02001d8:	9c460613          	addi	a2,a2,-1596 # ffffffffc0201b98 <etext+0xf6>
ffffffffc02001dc:	04e00593          	li	a1,78
ffffffffc02001e0:	00002517          	auipc	a0,0x2
ffffffffc02001e4:	9d050513          	addi	a0,a0,-1584 # ffffffffc0201bb0 <etext+0x10e>
void print_stackframe(void) {
ffffffffc02001e8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001ea:	1bc000ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc02001ee <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ee:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001f0:	00002617          	auipc	a2,0x2
ffffffffc02001f4:	9d860613          	addi	a2,a2,-1576 # ffffffffc0201bc8 <etext+0x126>
ffffffffc02001f8:	00002597          	auipc	a1,0x2
ffffffffc02001fc:	9f058593          	addi	a1,a1,-1552 # ffffffffc0201be8 <etext+0x146>
ffffffffc0200200:	00002517          	auipc	a0,0x2
ffffffffc0200204:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201bf0 <etext+0x14e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200208:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020a:	ea9ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020020e:	00002617          	auipc	a2,0x2
ffffffffc0200212:	9f260613          	addi	a2,a2,-1550 # ffffffffc0201c00 <etext+0x15e>
ffffffffc0200216:	00002597          	auipc	a1,0x2
ffffffffc020021a:	a1258593          	addi	a1,a1,-1518 # ffffffffc0201c28 <etext+0x186>
ffffffffc020021e:	00002517          	auipc	a0,0x2
ffffffffc0200222:	9d250513          	addi	a0,a0,-1582 # ffffffffc0201bf0 <etext+0x14e>
ffffffffc0200226:	e8dff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	a0e60613          	addi	a2,a2,-1522 # ffffffffc0201c38 <etext+0x196>
ffffffffc0200232:	00002597          	auipc	a1,0x2
ffffffffc0200236:	a2658593          	addi	a1,a1,-1498 # ffffffffc0201c58 <etext+0x1b6>
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	9b650513          	addi	a0,a0,-1610 # ffffffffc0201bf0 <etext+0x14e>
ffffffffc0200242:	e71ff0ef          	jal	ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc0200246:	60a2                	ld	ra,8(sp)
ffffffffc0200248:	4501                	li	a0,0
ffffffffc020024a:	0141                	addi	sp,sp,16
ffffffffc020024c:	8082                	ret

ffffffffc020024e <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024e:	1141                	addi	sp,sp,-16
ffffffffc0200250:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200252:	ef5ff0ef          	jal	ffffffffc0200146 <print_kerninfo>
    return 0;
}
ffffffffc0200256:	60a2                	ld	ra,8(sp)
ffffffffc0200258:	4501                	li	a0,0
ffffffffc020025a:	0141                	addi	sp,sp,16
ffffffffc020025c:	8082                	ret

ffffffffc020025e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025e:	1141                	addi	sp,sp,-16
ffffffffc0200260:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200262:	f71ff0ef          	jal	ffffffffc02001d2 <print_stackframe>
    return 0;
}
ffffffffc0200266:	60a2                	ld	ra,8(sp)
ffffffffc0200268:	4501                	li	a0,0
ffffffffc020026a:	0141                	addi	sp,sp,16
ffffffffc020026c:	8082                	ret

ffffffffc020026e <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026e:	7115                	addi	sp,sp,-224
ffffffffc0200270:	f15a                	sd	s6,160(sp)
ffffffffc0200272:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200274:	00002517          	auipc	a0,0x2
ffffffffc0200278:	9f450513          	addi	a0,a0,-1548 # ffffffffc0201c68 <etext+0x1c6>
kmonitor(struct trapframe *tf) {
ffffffffc020027c:	ed86                	sd	ra,216(sp)
ffffffffc020027e:	e9a2                	sd	s0,208(sp)
ffffffffc0200280:	e5a6                	sd	s1,200(sp)
ffffffffc0200282:	e1ca                	sd	s2,192(sp)
ffffffffc0200284:	fd4e                	sd	s3,184(sp)
ffffffffc0200286:	f952                	sd	s4,176(sp)
ffffffffc0200288:	f556                	sd	s5,168(sp)
ffffffffc020028a:	ed5e                	sd	s7,152(sp)
ffffffffc020028c:	e962                	sd	s8,144(sp)
ffffffffc020028e:	e566                	sd	s9,136(sp)
ffffffffc0200290:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200292:	e21ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0201c90 <etext+0x1ee>
ffffffffc020029e:	e15ff0ef          	jal	ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc02002a2:	000b0563          	beqz	s6,ffffffffc02002ac <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a6:	855a                	mv	a0,s6
ffffffffc02002a8:	396000ef          	jal	ffffffffc020063e <print_trapframe>
ffffffffc02002ac:	00002c17          	auipc	s8,0x2
ffffffffc02002b0:	494c0c13          	addi	s8,s8,1172 # ffffffffc0202740 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b4:	00002917          	auipc	s2,0x2
ffffffffc02002b8:	a0490913          	addi	s2,s2,-1532 # ffffffffc0201cb8 <etext+0x216>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002bc:	00002497          	auipc	s1,0x2
ffffffffc02002c0:	a0448493          	addi	s1,s1,-1532 # ffffffffc0201cc0 <etext+0x21e>
        if (argc == MAXARGS - 1) {
ffffffffc02002c4:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c6:	00002a97          	auipc	s5,0x2
ffffffffc02002ca:	a02a8a93          	addi	s5,s5,-1534 # ffffffffc0201cc8 <etext+0x226>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ce:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002d0:	00002b97          	auipc	s7,0x2
ffffffffc02002d4:	a18b8b93          	addi	s7,s7,-1512 # ffffffffc0201ce8 <etext+0x246>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d8:	854a                	mv	a0,s2
ffffffffc02002da:	62e010ef          	jal	ffffffffc0201908 <readline>
ffffffffc02002de:	842a                	mv	s0,a0
ffffffffc02002e0:	dd65                	beqz	a0,ffffffffc02002d8 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e2:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e6:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e8:	e59d                	bnez	a1,ffffffffc0200316 <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc02002ea:	fe0c87e3          	beqz	s9,ffffffffc02002d8 <kmonitor+0x6a>
ffffffffc02002ee:	00002d17          	auipc	s10,0x2
ffffffffc02002f2:	452d0d13          	addi	s10,s10,1106 # ffffffffc0202740 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f8:	6582                	ld	a1,0(sp)
ffffffffc02002fa:	000d3503          	ld	a0,0(s10)
ffffffffc02002fe:	744010ef          	jal	ffffffffc0201a42 <strcmp>
ffffffffc0200302:	c53d                	beqz	a0,ffffffffc0200370 <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200304:	2405                	addiw	s0,s0,1
ffffffffc0200306:	0d61                	addi	s10,s10,24
ffffffffc0200308:	ff4418e3          	bne	s0,s4,ffffffffc02002f8 <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020030c:	6582                	ld	a1,0(sp)
ffffffffc020030e:	855e                	mv	a0,s7
ffffffffc0200310:	da3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc0200314:	b7d1                	j	ffffffffc02002d8 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200316:	8526                	mv	a0,s1
ffffffffc0200318:	762010ef          	jal	ffffffffc0201a7a <strchr>
ffffffffc020031c:	c901                	beqz	a0,ffffffffc020032c <kmonitor+0xbe>
ffffffffc020031e:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200322:	00040023          	sb	zero,0(s0)
ffffffffc0200326:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200328:	d1e9                	beqz	a1,ffffffffc02002ea <kmonitor+0x7c>
ffffffffc020032a:	b7f5                	j	ffffffffc0200316 <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc020032c:	00044783          	lbu	a5,0(s0)
ffffffffc0200330:	dfcd                	beqz	a5,ffffffffc02002ea <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200332:	033c8a63          	beq	s9,s3,ffffffffc0200366 <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc0200336:	003c9793          	slli	a5,s9,0x3
ffffffffc020033a:	08078793          	addi	a5,a5,128
ffffffffc020033e:	978a                	add	a5,a5,sp
ffffffffc0200340:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200344:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200348:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020034a:	e591                	bnez	a1,ffffffffc0200356 <kmonitor+0xe8>
ffffffffc020034c:	bf79                	j	ffffffffc02002ea <kmonitor+0x7c>
ffffffffc020034e:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200352:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200354:	d9d9                	beqz	a1,ffffffffc02002ea <kmonitor+0x7c>
ffffffffc0200356:	8526                	mv	a0,s1
ffffffffc0200358:	722010ef          	jal	ffffffffc0201a7a <strchr>
ffffffffc020035c:	d96d                	beqz	a0,ffffffffc020034e <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035e:	00044583          	lbu	a1,0(s0)
ffffffffc0200362:	d5c1                	beqz	a1,ffffffffc02002ea <kmonitor+0x7c>
ffffffffc0200364:	bf4d                	j	ffffffffc0200316 <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200366:	45c1                	li	a1,16
ffffffffc0200368:	8556                	mv	a0,s5
ffffffffc020036a:	d49ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020036e:	b7e1                	j	ffffffffc0200336 <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200370:	00141793          	slli	a5,s0,0x1
ffffffffc0200374:	97a2                	add	a5,a5,s0
ffffffffc0200376:	078e                	slli	a5,a5,0x3
ffffffffc0200378:	97e2                	add	a5,a5,s8
ffffffffc020037a:	6b9c                	ld	a5,16(a5)
ffffffffc020037c:	865a                	mv	a2,s6
ffffffffc020037e:	002c                	addi	a1,sp,8
ffffffffc0200380:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200384:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200386:	f40559e3          	bgez	a0,ffffffffc02002d8 <kmonitor+0x6a>
}
ffffffffc020038a:	60ee                	ld	ra,216(sp)
ffffffffc020038c:	644e                	ld	s0,208(sp)
ffffffffc020038e:	64ae                	ld	s1,200(sp)
ffffffffc0200390:	690e                	ld	s2,192(sp)
ffffffffc0200392:	79ea                	ld	s3,184(sp)
ffffffffc0200394:	7a4a                	ld	s4,176(sp)
ffffffffc0200396:	7aaa                	ld	s5,168(sp)
ffffffffc0200398:	7b0a                	ld	s6,160(sp)
ffffffffc020039a:	6bea                	ld	s7,152(sp)
ffffffffc020039c:	6c4a                	ld	s8,144(sp)
ffffffffc020039e:	6caa                	ld	s9,136(sp)
ffffffffc02003a0:	6d0a                	ld	s10,128(sp)
ffffffffc02003a2:	612d                	addi	sp,sp,224
ffffffffc02003a4:	8082                	ret

ffffffffc02003a6 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003a6:	00006317          	auipc	t1,0x6
ffffffffc02003aa:	08a30313          	addi	t1,t1,138 # ffffffffc0206430 <is_panic>
ffffffffc02003ae:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b2:	715d                	addi	sp,sp,-80
ffffffffc02003b4:	ec06                	sd	ra,24(sp)
ffffffffc02003b6:	f436                	sd	a3,40(sp)
ffffffffc02003b8:	f83a                	sd	a4,48(sp)
ffffffffc02003ba:	fc3e                	sd	a5,56(sp)
ffffffffc02003bc:	e0c2                	sd	a6,64(sp)
ffffffffc02003be:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c0:	020e1c63          	bnez	t3,ffffffffc02003f8 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003c4:	4785                	li	a5,1
ffffffffc02003c6:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003ca:	e822                	sd	s0,16(sp)
ffffffffc02003cc:	103c                	addi	a5,sp,40
ffffffffc02003ce:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d0:	862e                	mv	a2,a1
ffffffffc02003d2:	85aa                	mv	a1,a0
ffffffffc02003d4:	00002517          	auipc	a0,0x2
ffffffffc02003d8:	92c50513          	addi	a0,a0,-1748 # ffffffffc0201d00 <etext+0x25e>
    va_start(ap, fmt);
ffffffffc02003dc:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003de:	cd5ff0ef          	jal	ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e2:	65a2                	ld	a1,8(sp)
ffffffffc02003e4:	8522                	mv	a0,s0
ffffffffc02003e6:	cadff0ef          	jal	ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003ea:	00002517          	auipc	a0,0x2
ffffffffc02003ee:	93650513          	addi	a0,a0,-1738 # ffffffffc0201d20 <etext+0x27e>
ffffffffc02003f2:	cc1ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc02003f6:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003f8:	062000ef          	jal	ffffffffc020045a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003fc:	4501                	li	a0,0
ffffffffc02003fe:	e71ff0ef          	jal	ffffffffc020026e <kmonitor>
    while (1) {
ffffffffc0200402:	bfed                	j	ffffffffc02003fc <__panic+0x56>

ffffffffc0200404 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200404:	1141                	addi	sp,sp,-16
ffffffffc0200406:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200408:	02000793          	li	a5,32
ffffffffc020040c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200410:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200414:	67e1                	lui	a5,0x18
ffffffffc0200416:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041a:	953e                	add	a0,a0,a5
ffffffffc020041c:	5ba010ef          	jal	ffffffffc02019d6 <sbi_set_timer>
}
ffffffffc0200420:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200422:	00006797          	auipc	a5,0x6
ffffffffc0200426:	0007bb23          	sd	zero,22(a5) # ffffffffc0206438 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042a:	00002517          	auipc	a0,0x2
ffffffffc020042e:	8fe50513          	addi	a0,a0,-1794 # ffffffffc0201d28 <etext+0x286>
}
ffffffffc0200432:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200434:	b9bd                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200436 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200436:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043a:	67e1                	lui	a5,0x18
ffffffffc020043c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200440:	953e                	add	a0,a0,a5
ffffffffc0200442:	5940106f          	j	ffffffffc02019d6 <sbi_set_timer>

ffffffffc0200446 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200446:	8082                	ret

ffffffffc0200448 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200448:	0ff57513          	zext.b	a0,a0
ffffffffc020044c:	5700106f          	j	ffffffffc02019bc <sbi_console_putchar>

ffffffffc0200450 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200450:	5a00106f          	j	ffffffffc02019f0 <sbi_console_getchar>

ffffffffc0200454 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200454:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200458:	8082                	ret

ffffffffc020045a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020045e:	8082                	ret

ffffffffc0200460 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200460:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200464:	00000797          	auipc	a5,0x0
ffffffffc0200468:	38c78793          	addi	a5,a5,908 # ffffffffc02007f0 <__alltraps>
ffffffffc020046c:	10579073          	csrw	stvec,a5
}
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200472:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200474:	1141                	addi	sp,sp,-16
ffffffffc0200476:	e022                	sd	s0,0(sp)
ffffffffc0200478:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047a:	00002517          	auipc	a0,0x2
ffffffffc020047e:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0201d48 <etext+0x2a6>
void print_regs(struct pushregs *gpr) {
ffffffffc0200482:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	c2fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200488:	640c                	ld	a1,8(s0)
ffffffffc020048a:	00002517          	auipc	a0,0x2
ffffffffc020048e:	8d650513          	addi	a0,a0,-1834 # ffffffffc0201d60 <etext+0x2be>
ffffffffc0200492:	c21ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200496:	680c                	ld	a1,16(s0)
ffffffffc0200498:	00002517          	auipc	a0,0x2
ffffffffc020049c:	8e050513          	addi	a0,a0,-1824 # ffffffffc0201d78 <etext+0x2d6>
ffffffffc02004a0:	c13ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a4:	6c0c                	ld	a1,24(s0)
ffffffffc02004a6:	00002517          	auipc	a0,0x2
ffffffffc02004aa:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0201d90 <etext+0x2ee>
ffffffffc02004ae:	c05ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b2:	700c                	ld	a1,32(s0)
ffffffffc02004b4:	00002517          	auipc	a0,0x2
ffffffffc02004b8:	8f450513          	addi	a0,a0,-1804 # ffffffffc0201da8 <etext+0x306>
ffffffffc02004bc:	bf7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c0:	740c                	ld	a1,40(s0)
ffffffffc02004c2:	00002517          	auipc	a0,0x2
ffffffffc02004c6:	8fe50513          	addi	a0,a0,-1794 # ffffffffc0201dc0 <etext+0x31e>
ffffffffc02004ca:	be9ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004ce:	780c                	ld	a1,48(s0)
ffffffffc02004d0:	00002517          	auipc	a0,0x2
ffffffffc02004d4:	90850513          	addi	a0,a0,-1784 # ffffffffc0201dd8 <etext+0x336>
ffffffffc02004d8:	bdbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004dc:	7c0c                	ld	a1,56(s0)
ffffffffc02004de:	00002517          	auipc	a0,0x2
ffffffffc02004e2:	91250513          	addi	a0,a0,-1774 # ffffffffc0201df0 <etext+0x34e>
ffffffffc02004e6:	bcdff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ea:	602c                	ld	a1,64(s0)
ffffffffc02004ec:	00002517          	auipc	a0,0x2
ffffffffc02004f0:	91c50513          	addi	a0,a0,-1764 # ffffffffc0201e08 <etext+0x366>
ffffffffc02004f4:	bbfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004f8:	642c                	ld	a1,72(s0)
ffffffffc02004fa:	00002517          	auipc	a0,0x2
ffffffffc02004fe:	92650513          	addi	a0,a0,-1754 # ffffffffc0201e20 <etext+0x37e>
ffffffffc0200502:	bb1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200506:	682c                	ld	a1,80(s0)
ffffffffc0200508:	00002517          	auipc	a0,0x2
ffffffffc020050c:	93050513          	addi	a0,a0,-1744 # ffffffffc0201e38 <etext+0x396>
ffffffffc0200510:	ba3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200514:	6c2c                	ld	a1,88(s0)
ffffffffc0200516:	00002517          	auipc	a0,0x2
ffffffffc020051a:	93a50513          	addi	a0,a0,-1734 # ffffffffc0201e50 <etext+0x3ae>
ffffffffc020051e:	b95ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200522:	702c                	ld	a1,96(s0)
ffffffffc0200524:	00002517          	auipc	a0,0x2
ffffffffc0200528:	94450513          	addi	a0,a0,-1724 # ffffffffc0201e68 <etext+0x3c6>
ffffffffc020052c:	b87ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200530:	742c                	ld	a1,104(s0)
ffffffffc0200532:	00002517          	auipc	a0,0x2
ffffffffc0200536:	94e50513          	addi	a0,a0,-1714 # ffffffffc0201e80 <etext+0x3de>
ffffffffc020053a:	b79ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020053e:	782c                	ld	a1,112(s0)
ffffffffc0200540:	00002517          	auipc	a0,0x2
ffffffffc0200544:	95850513          	addi	a0,a0,-1704 # ffffffffc0201e98 <etext+0x3f6>
ffffffffc0200548:	b6bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020054c:	7c2c                	ld	a1,120(s0)
ffffffffc020054e:	00002517          	auipc	a0,0x2
ffffffffc0200552:	96250513          	addi	a0,a0,-1694 # ffffffffc0201eb0 <etext+0x40e>
ffffffffc0200556:	b5dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055a:	604c                	ld	a1,128(s0)
ffffffffc020055c:	00002517          	auipc	a0,0x2
ffffffffc0200560:	96c50513          	addi	a0,a0,-1684 # ffffffffc0201ec8 <etext+0x426>
ffffffffc0200564:	b4fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200568:	644c                	ld	a1,136(s0)
ffffffffc020056a:	00002517          	auipc	a0,0x2
ffffffffc020056e:	97650513          	addi	a0,a0,-1674 # ffffffffc0201ee0 <etext+0x43e>
ffffffffc0200572:	b41ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200576:	684c                	ld	a1,144(s0)
ffffffffc0200578:	00002517          	auipc	a0,0x2
ffffffffc020057c:	98050513          	addi	a0,a0,-1664 # ffffffffc0201ef8 <etext+0x456>
ffffffffc0200580:	b33ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200584:	6c4c                	ld	a1,152(s0)
ffffffffc0200586:	00002517          	auipc	a0,0x2
ffffffffc020058a:	98a50513          	addi	a0,a0,-1654 # ffffffffc0201f10 <etext+0x46e>
ffffffffc020058e:	b25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200592:	704c                	ld	a1,160(s0)
ffffffffc0200594:	00002517          	auipc	a0,0x2
ffffffffc0200598:	99450513          	addi	a0,a0,-1644 # ffffffffc0201f28 <etext+0x486>
ffffffffc020059c:	b17ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a0:	744c                	ld	a1,168(s0)
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	99e50513          	addi	a0,a0,-1634 # ffffffffc0201f40 <etext+0x49e>
ffffffffc02005aa:	b09ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005ae:	784c                	ld	a1,176(s0)
ffffffffc02005b0:	00002517          	auipc	a0,0x2
ffffffffc02005b4:	9a850513          	addi	a0,a0,-1624 # ffffffffc0201f58 <etext+0x4b6>
ffffffffc02005b8:	afbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005bc:	7c4c                	ld	a1,184(s0)
ffffffffc02005be:	00002517          	auipc	a0,0x2
ffffffffc02005c2:	9b250513          	addi	a0,a0,-1614 # ffffffffc0201f70 <etext+0x4ce>
ffffffffc02005c6:	aedff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ca:	606c                	ld	a1,192(s0)
ffffffffc02005cc:	00002517          	auipc	a0,0x2
ffffffffc02005d0:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0201f88 <etext+0x4e6>
ffffffffc02005d4:	adfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005d8:	646c                	ld	a1,200(s0)
ffffffffc02005da:	00002517          	auipc	a0,0x2
ffffffffc02005de:	9c650513          	addi	a0,a0,-1594 # ffffffffc0201fa0 <etext+0x4fe>
ffffffffc02005e2:	ad1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005e6:	686c                	ld	a1,208(s0)
ffffffffc02005e8:	00002517          	auipc	a0,0x2
ffffffffc02005ec:	9d050513          	addi	a0,a0,-1584 # ffffffffc0201fb8 <etext+0x516>
ffffffffc02005f0:	ac3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f4:	6c6c                	ld	a1,216(s0)
ffffffffc02005f6:	00002517          	auipc	a0,0x2
ffffffffc02005fa:	9da50513          	addi	a0,a0,-1574 # ffffffffc0201fd0 <etext+0x52e>
ffffffffc02005fe:	ab5ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200602:	706c                	ld	a1,224(s0)
ffffffffc0200604:	00002517          	auipc	a0,0x2
ffffffffc0200608:	9e450513          	addi	a0,a0,-1564 # ffffffffc0201fe8 <etext+0x546>
ffffffffc020060c:	aa7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200610:	746c                	ld	a1,232(s0)
ffffffffc0200612:	00002517          	auipc	a0,0x2
ffffffffc0200616:	9ee50513          	addi	a0,a0,-1554 # ffffffffc0202000 <etext+0x55e>
ffffffffc020061a:	a99ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020061e:	786c                	ld	a1,240(s0)
ffffffffc0200620:	00002517          	auipc	a0,0x2
ffffffffc0200624:	9f850513          	addi	a0,a0,-1544 # ffffffffc0202018 <etext+0x576>
ffffffffc0200628:	a8bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020062c:	7c6c                	ld	a1,248(s0)
}
ffffffffc020062e:	6402                	ld	s0,0(sp)
ffffffffc0200630:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200632:	00002517          	auipc	a0,0x2
ffffffffc0200636:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0202030 <etext+0x58e>
}
ffffffffc020063a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	bc9d                	j	ffffffffc02000b2 <cprintf>

ffffffffc020063e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020063e:	1141                	addi	sp,sp,-16
ffffffffc0200640:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200642:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200644:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	00002517          	auipc	a0,0x2
ffffffffc020064a:	a0250513          	addi	a0,a0,-1534 # ffffffffc0202048 <etext+0x5a6>
void print_trapframe(struct trapframe *tf) {
ffffffffc020064e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200650:	a63ff0ef          	jal	ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200654:	8522                	mv	a0,s0
ffffffffc0200656:	e1dff0ef          	jal	ffffffffc0200472 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065a:	10043583          	ld	a1,256(s0)
ffffffffc020065e:	00002517          	auipc	a0,0x2
ffffffffc0200662:	a0250513          	addi	a0,a0,-1534 # ffffffffc0202060 <etext+0x5be>
ffffffffc0200666:	a4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066a:	10843583          	ld	a1,264(s0)
ffffffffc020066e:	00002517          	auipc	a0,0x2
ffffffffc0200672:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0202078 <etext+0x5d6>
ffffffffc0200676:	a3dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067a:	11043583          	ld	a1,272(s0)
ffffffffc020067e:	00002517          	auipc	a0,0x2
ffffffffc0200682:	a1250513          	addi	a0,a0,-1518 # ffffffffc0202090 <etext+0x5ee>
ffffffffc0200686:	a2dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068a:	11843583          	ld	a1,280(s0)
}
ffffffffc020068e:	6402                	ld	s0,0(sp)
ffffffffc0200690:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200692:	00002517          	auipc	a0,0x2
ffffffffc0200696:	a1650513          	addi	a0,a0,-1514 # ffffffffc02020a8 <etext+0x606>
}
ffffffffc020069a:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069c:	bc19                	j	ffffffffc02000b2 <cprintf>

ffffffffc020069e <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc020069e:	11853783          	ld	a5,280(a0)
ffffffffc02006a2:	472d                	li	a4,11
ffffffffc02006a4:	0786                	slli	a5,a5,0x1
ffffffffc02006a6:	8385                	srli	a5,a5,0x1
ffffffffc02006a8:	08f76463          	bltu	a4,a5,ffffffffc0200730 <interrupt_handler+0x92>
ffffffffc02006ac:	00002717          	auipc	a4,0x2
ffffffffc02006b0:	0dc70713          	addi	a4,a4,220 # ffffffffc0202788 <commands+0x48>
ffffffffc02006b4:	078a                	slli	a5,a5,0x2
ffffffffc02006b6:	97ba                	add	a5,a5,a4
ffffffffc02006b8:	439c                	lw	a5,0(a5)
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006be:	00002517          	auipc	a0,0x2
ffffffffc02006c2:	a6250513          	addi	a0,a0,-1438 # ffffffffc0202120 <etext+0x67e>
ffffffffc02006c6:	b2f5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006c8:	00002517          	auipc	a0,0x2
ffffffffc02006cc:	a3850513          	addi	a0,a0,-1480 # ffffffffc0202100 <etext+0x65e>
ffffffffc02006d0:	b2cd                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d2:	00002517          	auipc	a0,0x2
ffffffffc02006d6:	9ee50513          	addi	a0,a0,-1554 # ffffffffc02020c0 <etext+0x61e>
ffffffffc02006da:	bae1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006dc:	00002517          	auipc	a0,0x2
ffffffffc02006e0:	a6450513          	addi	a0,a0,-1436 # ffffffffc0202140 <etext+0x69e>
ffffffffc02006e4:	b2f9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006e6:	1141                	addi	sp,sp,-16
ffffffffc02006e8:	e406                	sd	ra,8(sp)
                print_ticks();
            }
            break;
            */
            //begin
            clock_set_next_event();
ffffffffc02006ea:	d4dff0ef          	jal	ffffffffc0200436 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006ee:	00006697          	auipc	a3,0x6
ffffffffc02006f2:	d4a68693          	addi	a3,a3,-694 # ffffffffc0206438 <ticks>
ffffffffc02006f6:	629c                	ld	a5,0(a3)
ffffffffc02006f8:	06400713          	li	a4,100
ffffffffc02006fc:	0785                	addi	a5,a5,1
ffffffffc02006fe:	02e7f733          	remu	a4,a5,a4
ffffffffc0200702:	e29c                	sd	a5,0(a3)
ffffffffc0200704:	c71d                	beqz	a4,ffffffffc0200732 <interrupt_handler+0x94>
                print_ticks();
                num++;
            }
            if(num==10){
ffffffffc0200706:	00006717          	auipc	a4,0x6
ffffffffc020070a:	d3a72703          	lw	a4,-710(a4) # ffffffffc0206440 <num>
ffffffffc020070e:	47a9                	li	a5,10
ffffffffc0200710:	04f70263          	beq	a4,a5,ffffffffc0200754 <interrupt_handler+0xb6>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200714:	60a2                	ld	ra,8(sp)
ffffffffc0200716:	0141                	addi	sp,sp,16
ffffffffc0200718:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc020071a:	00002517          	auipc	a0,0x2
ffffffffc020071e:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0202168 <etext+0x6c6>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200724:	00002517          	auipc	a0,0x2
ffffffffc0200728:	9bc50513          	addi	a0,a0,-1604 # ffffffffc02020e0 <etext+0x63e>
ffffffffc020072c:	987ff06f          	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200730:	b739                	j	ffffffffc020063e <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200732:	06400593          	li	a1,100
ffffffffc0200736:	00002517          	auipc	a0,0x2
ffffffffc020073a:	a2250513          	addi	a0,a0,-1502 # ffffffffc0202158 <etext+0x6b6>
ffffffffc020073e:	975ff0ef          	jal	ffffffffc02000b2 <cprintf>
                num++;
ffffffffc0200742:	00006697          	auipc	a3,0x6
ffffffffc0200746:	cfe68693          	addi	a3,a3,-770 # ffffffffc0206440 <num>
ffffffffc020074a:	429c                	lw	a5,0(a3)
ffffffffc020074c:	0017871b          	addiw	a4,a5,1
ffffffffc0200750:	c298                	sw	a4,0(a3)
ffffffffc0200752:	bf75                	j	ffffffffc020070e <interrupt_handler+0x70>
}
ffffffffc0200754:	60a2                	ld	ra,8(sp)
ffffffffc0200756:	0141                	addi	sp,sp,16
                sbi_shutdown();
ffffffffc0200758:	2b40106f          	j	ffffffffc0201a0c <sbi_shutdown>

ffffffffc020075c <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc020075c:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200760:	1141                	addi	sp,sp,-16
ffffffffc0200762:	e022                	sd	s0,0(sp)
ffffffffc0200764:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200766:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200768:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc020076a:	04e78663          	beq	a5,a4,ffffffffc02007b6 <exception_handler+0x5a>
ffffffffc020076e:	02f76c63          	bltu	a4,a5,ffffffffc02007a6 <exception_handler+0x4a>
ffffffffc0200772:	4709                	li	a4,2
ffffffffc0200774:	02e79563          	bne	a5,a4,ffffffffc020079e <exception_handler+0x42>
            break;
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
            //begin
            cprintf("Exception type:Illegal instruction\n");
ffffffffc0200778:	00002517          	auipc	a0,0x2
ffffffffc020077c:	a1050513          	addi	a0,a0,-1520 # ffffffffc0202188 <etext+0x6e6>
ffffffffc0200780:	933ff0ef          	jal	ffffffffc02000b2 <cprintf>
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200784:	10843583          	ld	a1,264(s0)
ffffffffc0200788:	00002517          	auipc	a0,0x2
ffffffffc020078c:	a2850513          	addi	a0,a0,-1496 # ffffffffc02021b0 <etext+0x70e>
ffffffffc0200790:	923ff0ef          	jal	ffffffffc02000b2 <cprintf>
            tf->epc += 4;
ffffffffc0200794:	10843783          	ld	a5,264(s0)
ffffffffc0200798:	0791                	addi	a5,a5,4
ffffffffc020079a:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020079e:	60a2                	ld	ra,8(sp)
ffffffffc02007a0:	6402                	ld	s0,0(sp)
ffffffffc02007a2:	0141                	addi	sp,sp,16
ffffffffc02007a4:	8082                	ret
    switch (tf->cause) {
ffffffffc02007a6:	17f1                	addi	a5,a5,-4
ffffffffc02007a8:	471d                	li	a4,7
ffffffffc02007aa:	fef77ae3          	bgeu	a4,a5,ffffffffc020079e <exception_handler+0x42>
}
ffffffffc02007ae:	6402                	ld	s0,0(sp)
ffffffffc02007b0:	60a2                	ld	ra,8(sp)
ffffffffc02007b2:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc02007b4:	b569                	j	ffffffffc020063e <print_trapframe>
            cprintf("Exception type:breakpoint\n");
ffffffffc02007b6:	00002517          	auipc	a0,0x2
ffffffffc02007ba:	a2250513          	addi	a0,a0,-1502 # ffffffffc02021d8 <etext+0x736>
ffffffffc02007be:	8f5ff0ef          	jal	ffffffffc02000b2 <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc02007c2:	10843583          	ld	a1,264(s0)
ffffffffc02007c6:	00002517          	auipc	a0,0x2
ffffffffc02007ca:	a3250513          	addi	a0,a0,-1486 # ffffffffc02021f8 <etext+0x756>
ffffffffc02007ce:	8e5ff0ef          	jal	ffffffffc02000b2 <cprintf>
            tf->epc += 4;
ffffffffc02007d2:	10843783          	ld	a5,264(s0)
}
ffffffffc02007d6:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
ffffffffc02007d8:	0791                	addi	a5,a5,4
ffffffffc02007da:	10f43423          	sd	a5,264(s0)
}
ffffffffc02007de:	6402                	ld	s0,0(sp)
ffffffffc02007e0:	0141                	addi	sp,sp,16
ffffffffc02007e2:	8082                	ret

ffffffffc02007e4 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc02007e4:	11853783          	ld	a5,280(a0)
ffffffffc02007e8:	0007c363          	bltz	a5,ffffffffc02007ee <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02007ec:	bf85                	j	ffffffffc020075c <exception_handler>
        interrupt_handler(tf);
ffffffffc02007ee:	bd45                	j	ffffffffc020069e <interrupt_handler>

ffffffffc02007f0 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc02007f0:	14011073          	csrw	sscratch,sp
ffffffffc02007f4:	712d                	addi	sp,sp,-288
ffffffffc02007f6:	e002                	sd	zero,0(sp)
ffffffffc02007f8:	e406                	sd	ra,8(sp)
ffffffffc02007fa:	ec0e                	sd	gp,24(sp)
ffffffffc02007fc:	f012                	sd	tp,32(sp)
ffffffffc02007fe:	f416                	sd	t0,40(sp)
ffffffffc0200800:	f81a                	sd	t1,48(sp)
ffffffffc0200802:	fc1e                	sd	t2,56(sp)
ffffffffc0200804:	e0a2                	sd	s0,64(sp)
ffffffffc0200806:	e4a6                	sd	s1,72(sp)
ffffffffc0200808:	e8aa                	sd	a0,80(sp)
ffffffffc020080a:	ecae                	sd	a1,88(sp)
ffffffffc020080c:	f0b2                	sd	a2,96(sp)
ffffffffc020080e:	f4b6                	sd	a3,104(sp)
ffffffffc0200810:	f8ba                	sd	a4,112(sp)
ffffffffc0200812:	fcbe                	sd	a5,120(sp)
ffffffffc0200814:	e142                	sd	a6,128(sp)
ffffffffc0200816:	e546                	sd	a7,136(sp)
ffffffffc0200818:	e94a                	sd	s2,144(sp)
ffffffffc020081a:	ed4e                	sd	s3,152(sp)
ffffffffc020081c:	f152                	sd	s4,160(sp)
ffffffffc020081e:	f556                	sd	s5,168(sp)
ffffffffc0200820:	f95a                	sd	s6,176(sp)
ffffffffc0200822:	fd5e                	sd	s7,184(sp)
ffffffffc0200824:	e1e2                	sd	s8,192(sp)
ffffffffc0200826:	e5e6                	sd	s9,200(sp)
ffffffffc0200828:	e9ea                	sd	s10,208(sp)
ffffffffc020082a:	edee                	sd	s11,216(sp)
ffffffffc020082c:	f1f2                	sd	t3,224(sp)
ffffffffc020082e:	f5f6                	sd	t4,232(sp)
ffffffffc0200830:	f9fa                	sd	t5,240(sp)
ffffffffc0200832:	fdfe                	sd	t6,248(sp)
ffffffffc0200834:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200838:	100024f3          	csrr	s1,sstatus
ffffffffc020083c:	14102973          	csrr	s2,sepc
ffffffffc0200840:	143029f3          	csrr	s3,stval
ffffffffc0200844:	14202a73          	csrr	s4,scause
ffffffffc0200848:	e822                	sd	s0,16(sp)
ffffffffc020084a:	e226                	sd	s1,256(sp)
ffffffffc020084c:	e64a                	sd	s2,264(sp)
ffffffffc020084e:	ea4e                	sd	s3,272(sp)
ffffffffc0200850:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200852:	850a                	mv	a0,sp
    jal trap
ffffffffc0200854:	f91ff0ef          	jal	ffffffffc02007e4 <trap>

ffffffffc0200858 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200858:	6492                	ld	s1,256(sp)
ffffffffc020085a:	6932                	ld	s2,264(sp)
ffffffffc020085c:	10049073          	csrw	sstatus,s1
ffffffffc0200860:	14191073          	csrw	sepc,s2
ffffffffc0200864:	60a2                	ld	ra,8(sp)
ffffffffc0200866:	61e2                	ld	gp,24(sp)
ffffffffc0200868:	7202                	ld	tp,32(sp)
ffffffffc020086a:	72a2                	ld	t0,40(sp)
ffffffffc020086c:	7342                	ld	t1,48(sp)
ffffffffc020086e:	73e2                	ld	t2,56(sp)
ffffffffc0200870:	6406                	ld	s0,64(sp)
ffffffffc0200872:	64a6                	ld	s1,72(sp)
ffffffffc0200874:	6546                	ld	a0,80(sp)
ffffffffc0200876:	65e6                	ld	a1,88(sp)
ffffffffc0200878:	7606                	ld	a2,96(sp)
ffffffffc020087a:	76a6                	ld	a3,104(sp)
ffffffffc020087c:	7746                	ld	a4,112(sp)
ffffffffc020087e:	77e6                	ld	a5,120(sp)
ffffffffc0200880:	680a                	ld	a6,128(sp)
ffffffffc0200882:	68aa                	ld	a7,136(sp)
ffffffffc0200884:	694a                	ld	s2,144(sp)
ffffffffc0200886:	69ea                	ld	s3,152(sp)
ffffffffc0200888:	7a0a                	ld	s4,160(sp)
ffffffffc020088a:	7aaa                	ld	s5,168(sp)
ffffffffc020088c:	7b4a                	ld	s6,176(sp)
ffffffffc020088e:	7bea                	ld	s7,184(sp)
ffffffffc0200890:	6c0e                	ld	s8,192(sp)
ffffffffc0200892:	6cae                	ld	s9,200(sp)
ffffffffc0200894:	6d4e                	ld	s10,208(sp)
ffffffffc0200896:	6dee                	ld	s11,216(sp)
ffffffffc0200898:	7e0e                	ld	t3,224(sp)
ffffffffc020089a:	7eae                	ld	t4,232(sp)
ffffffffc020089c:	7f4e                	ld	t5,240(sp)
ffffffffc020089e:	7fee                	ld	t6,248(sp)
ffffffffc02008a0:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02008a2:	10200073          	sret

ffffffffc02008a6 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02008a6:	00005797          	auipc	a5,0x5
ffffffffc02008aa:	77278793          	addi	a5,a5,1906 # ffffffffc0206018 <free_area>
ffffffffc02008ae:	e79c                	sd	a5,8(a5)
ffffffffc02008b0:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02008b2:	0007a823          	sw	zero,16(a5)
}
ffffffffc02008b6:	8082                	ret

ffffffffc02008b8 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02008b8:	00005517          	auipc	a0,0x5
ffffffffc02008bc:	77056503          	lwu	a0,1904(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc02008c0:	8082                	ret

ffffffffc02008c2 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02008c2:	c14d                	beqz	a0,ffffffffc0200964 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc02008c4:	00005617          	auipc	a2,0x5
ffffffffc02008c8:	75460613          	addi	a2,a2,1876 # ffffffffc0206018 <free_area>
ffffffffc02008cc:	01062803          	lw	a6,16(a2)
ffffffffc02008d0:	86aa                	mv	a3,a0
ffffffffc02008d2:	02081793          	slli	a5,a6,0x20
ffffffffc02008d6:	9381                	srli	a5,a5,0x20
ffffffffc02008d8:	08a7e463          	bltu	a5,a0,ffffffffc0200960 <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02008dc:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc02008de:	0018059b          	addiw	a1,a6,1
ffffffffc02008e2:	1582                	slli	a1,a1,0x20
ffffffffc02008e4:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc02008e6:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008e8:	06c78b63          	beq	a5,a2,ffffffffc020095e <best_fit_alloc_pages+0x9c>
        if(p->property >=n && p->property < min_size){
ffffffffc02008ec:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02008f0:	00d76763          	bltu	a4,a3,ffffffffc02008fe <best_fit_alloc_pages+0x3c>
ffffffffc02008f4:	00b77563          	bgeu	a4,a1,ffffffffc02008fe <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc02008f8:	fe878513          	addi	a0,a5,-24
            min_size = p->property;
ffffffffc02008fc:	85ba                	mv	a1,a4
ffffffffc02008fe:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200900:	fec796e3          	bne	a5,a2,ffffffffc02008ec <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200904:	cd29                	beqz	a0,ffffffffc020095e <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200906:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200908:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc020090a:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc020090c:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200910:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200912:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200914:	02059793          	slli	a5,a1,0x20
ffffffffc0200918:	9381                	srli	a5,a5,0x20
ffffffffc020091a:	02f6f863          	bgeu	a3,a5,ffffffffc020094a <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc020091e:	00269793          	slli	a5,a3,0x2
ffffffffc0200922:	97b6                	add	a5,a5,a3
ffffffffc0200924:	078e                	slli	a5,a5,0x3
ffffffffc0200926:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200928:	411585bb          	subw	a1,a1,a7
ffffffffc020092c:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020092e:	4689                	li	a3,2
ffffffffc0200930:	00878593          	addi	a1,a5,8
ffffffffc0200934:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200938:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc020093a:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc020093e:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200942:	e28c                	sd	a1,0(a3)
ffffffffc0200944:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200946:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200948:	ef98                	sd	a4,24(a5)
ffffffffc020094a:	4118083b          	subw	a6,a6,a7
ffffffffc020094e:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200952:	57f5                	li	a5,-3
ffffffffc0200954:	00850713          	addi	a4,a0,8
ffffffffc0200958:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc020095c:	8082                	ret
}
ffffffffc020095e:	8082                	ret
        return NULL;
ffffffffc0200960:	4501                	li	a0,0
ffffffffc0200962:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200964:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200966:	00002697          	auipc	a3,0x2
ffffffffc020096a:	8b268693          	addi	a3,a3,-1870 # ffffffffc0202218 <etext+0x776>
ffffffffc020096e:	00002617          	auipc	a2,0x2
ffffffffc0200972:	8b260613          	addi	a2,a2,-1870 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200976:	06e00593          	li	a1,110
ffffffffc020097a:	00002517          	auipc	a0,0x2
ffffffffc020097e:	8be50513          	addi	a0,a0,-1858 # ffffffffc0202238 <etext+0x796>
best_fit_alloc_pages(size_t n) {
ffffffffc0200982:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200984:	a23ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200988 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200988:	715d                	addi	sp,sp,-80
ffffffffc020098a:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc020098c:	00005417          	auipc	s0,0x5
ffffffffc0200990:	68c40413          	addi	s0,s0,1676 # ffffffffc0206018 <free_area>
ffffffffc0200994:	641c                	ld	a5,8(s0)
ffffffffc0200996:	e486                	sd	ra,72(sp)
ffffffffc0200998:	fc26                	sd	s1,56(sp)
ffffffffc020099a:	f84a                	sd	s2,48(sp)
ffffffffc020099c:	f44e                	sd	s3,40(sp)
ffffffffc020099e:	f052                	sd	s4,32(sp)
ffffffffc02009a0:	ec56                	sd	s5,24(sp)
ffffffffc02009a2:	e85a                	sd	s6,16(sp)
ffffffffc02009a4:	e45e                	sd	s7,8(sp)
ffffffffc02009a6:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02009a8:	28878463          	beq	a5,s0,ffffffffc0200c30 <best_fit_check+0x2a8>
    int count = 0, total = 0;
ffffffffc02009ac:	4481                	li	s1,0
ffffffffc02009ae:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02009b0:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02009b4:	8b09                	andi	a4,a4,2
ffffffffc02009b6:	28070163          	beqz	a4,ffffffffc0200c38 <best_fit_check+0x2b0>
        count ++, total += p->property;
ffffffffc02009ba:	ff87a703          	lw	a4,-8(a5)
ffffffffc02009be:	679c                	ld	a5,8(a5)
ffffffffc02009c0:	2905                	addiw	s2,s2,1
ffffffffc02009c2:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02009c4:	fe8796e3          	bne	a5,s0,ffffffffc02009b0 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02009c8:	89a6                	mv	s3,s1
ffffffffc02009ca:	179000ef          	jal	ffffffffc0201342 <nr_free_pages>
ffffffffc02009ce:	35351563          	bne	a0,s3,ffffffffc0200d18 <best_fit_check+0x390>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02009d2:	4505                	li	a0,1
ffffffffc02009d4:	0f1000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc02009d8:	8a2a                	mv	s4,a0
ffffffffc02009da:	36050f63          	beqz	a0,ffffffffc0200d58 <best_fit_check+0x3d0>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009de:	4505                	li	a0,1
ffffffffc02009e0:	0e5000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc02009e4:	89aa                	mv	s3,a0
ffffffffc02009e6:	34050963          	beqz	a0,ffffffffc0200d38 <best_fit_check+0x3b0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009ea:	4505                	li	a0,1
ffffffffc02009ec:	0d9000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc02009f0:	8aaa                	mv	s5,a0
ffffffffc02009f2:	2e050363          	beqz	a0,ffffffffc0200cd8 <best_fit_check+0x350>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02009f6:	273a0163          	beq	s4,s3,ffffffffc0200c58 <best_fit_check+0x2d0>
ffffffffc02009fa:	24aa0f63          	beq	s4,a0,ffffffffc0200c58 <best_fit_check+0x2d0>
ffffffffc02009fe:	24a98d63          	beq	s3,a0,ffffffffc0200c58 <best_fit_check+0x2d0>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200a02:	000a2783          	lw	a5,0(s4)
ffffffffc0200a06:	26079963          	bnez	a5,ffffffffc0200c78 <best_fit_check+0x2f0>
ffffffffc0200a0a:	0009a783          	lw	a5,0(s3)
ffffffffc0200a0e:	26079563          	bnez	a5,ffffffffc0200c78 <best_fit_check+0x2f0>
ffffffffc0200a12:	411c                	lw	a5,0(a0)
ffffffffc0200a14:	26079263          	bnez	a5,ffffffffc0200c78 <best_fit_check+0x2f0>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a18:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200a1c:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac684d>
ffffffffc0200a20:	07b2                	slli	a5,a5,0xc
ffffffffc0200a22:	ccd78793          	addi	a5,a5,-819
ffffffffc0200a26:	07b2                	slli	a5,a5,0xc
ffffffffc0200a28:	00006717          	auipc	a4,0x6
ffffffffc0200a2c:	a4873703          	ld	a4,-1464(a4) # ffffffffc0206470 <pages>
ffffffffc0200a30:	ccd78793          	addi	a5,a5,-819
ffffffffc0200a34:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200a38:	07b2                	slli	a5,a5,0xc
ffffffffc0200a3a:	868d                	srai	a3,a3,0x3
ffffffffc0200a3c:	ccd78793          	addi	a5,a5,-819
ffffffffc0200a40:	02f686b3          	mul	a3,a3,a5
ffffffffc0200a44:	00002597          	auipc	a1,0x2
ffffffffc0200a48:	f3c5b583          	ld	a1,-196(a1) # ffffffffc0202980 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200a4c:	00006617          	auipc	a2,0x6
ffffffffc0200a50:	a1c63603          	ld	a2,-1508(a2) # ffffffffc0206468 <npage>
ffffffffc0200a54:	0632                	slli	a2,a2,0xc
ffffffffc0200a56:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a58:	06b2                	slli	a3,a3,0xc
ffffffffc0200a5a:	22c6ff63          	bgeu	a3,a2,ffffffffc0200c98 <best_fit_check+0x310>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a5e:	40e986b3          	sub	a3,s3,a4
ffffffffc0200a62:	868d                	srai	a3,a3,0x3
ffffffffc0200a64:	02f686b3          	mul	a3,a3,a5
ffffffffc0200a68:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a6a:	06b2                	slli	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200a6c:	3ec6f663          	bgeu	a3,a2,ffffffffc0200e58 <best_fit_check+0x4d0>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a70:	40e50733          	sub	a4,a0,a4
ffffffffc0200a74:	870d                	srai	a4,a4,0x3
ffffffffc0200a76:	02f707b3          	mul	a5,a4,a5
ffffffffc0200a7a:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a7c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a7e:	3ac7fd63          	bgeu	a5,a2,ffffffffc0200e38 <best_fit_check+0x4b0>
    assert(alloc_page() == NULL);
ffffffffc0200a82:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a84:	00043c03          	ld	s8,0(s0)
ffffffffc0200a88:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200a8c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200a90:	e400                	sd	s0,8(s0)
ffffffffc0200a92:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200a94:	00005797          	auipc	a5,0x5
ffffffffc0200a98:	5807aa23          	sw	zero,1428(a5) # ffffffffc0206028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200a9c:	029000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200aa0:	36051c63          	bnez	a0,ffffffffc0200e18 <best_fit_check+0x490>
    free_page(p0);
ffffffffc0200aa4:	4585                	li	a1,1
ffffffffc0200aa6:	8552                	mv	a0,s4
ffffffffc0200aa8:	05b000ef          	jal	ffffffffc0201302 <free_pages>
    free_page(p1);
ffffffffc0200aac:	4585                	li	a1,1
ffffffffc0200aae:	854e                	mv	a0,s3
ffffffffc0200ab0:	053000ef          	jal	ffffffffc0201302 <free_pages>
    free_page(p2);
ffffffffc0200ab4:	4585                	li	a1,1
ffffffffc0200ab6:	8556                	mv	a0,s5
ffffffffc0200ab8:	04b000ef          	jal	ffffffffc0201302 <free_pages>
    assert(nr_free == 3);
ffffffffc0200abc:	4818                	lw	a4,16(s0)
ffffffffc0200abe:	478d                	li	a5,3
ffffffffc0200ac0:	32f71c63          	bne	a4,a5,ffffffffc0200df8 <best_fit_check+0x470>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ac4:	4505                	li	a0,1
ffffffffc0200ac6:	7fe000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200aca:	89aa                	mv	s3,a0
ffffffffc0200acc:	30050663          	beqz	a0,ffffffffc0200dd8 <best_fit_check+0x450>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ad0:	4505                	li	a0,1
ffffffffc0200ad2:	7f2000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200ad6:	8aaa                	mv	s5,a0
ffffffffc0200ad8:	2e050063          	beqz	a0,ffffffffc0200db8 <best_fit_check+0x430>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200adc:	4505                	li	a0,1
ffffffffc0200ade:	7e6000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200ae2:	8a2a                	mv	s4,a0
ffffffffc0200ae4:	2a050a63          	beqz	a0,ffffffffc0200d98 <best_fit_check+0x410>
    assert(alloc_page() == NULL);
ffffffffc0200ae8:	4505                	li	a0,1
ffffffffc0200aea:	7da000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200aee:	28051563          	bnez	a0,ffffffffc0200d78 <best_fit_check+0x3f0>
    free_page(p0);
ffffffffc0200af2:	4585                	li	a1,1
ffffffffc0200af4:	854e                	mv	a0,s3
ffffffffc0200af6:	00d000ef          	jal	ffffffffc0201302 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200afa:	641c                	ld	a5,8(s0)
ffffffffc0200afc:	1a878e63          	beq	a5,s0,ffffffffc0200cb8 <best_fit_check+0x330>
    assert((p = alloc_page()) == p0);
ffffffffc0200b00:	4505                	li	a0,1
ffffffffc0200b02:	7c2000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200b06:	52a99963          	bne	s3,a0,ffffffffc0201038 <best_fit_check+0x6b0>
    assert(alloc_page() == NULL);
ffffffffc0200b0a:	4505                	li	a0,1
ffffffffc0200b0c:	7b8000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200b10:	50051463          	bnez	a0,ffffffffc0201018 <best_fit_check+0x690>
    assert(nr_free == 0);
ffffffffc0200b14:	481c                	lw	a5,16(s0)
ffffffffc0200b16:	4e079163          	bnez	a5,ffffffffc0200ff8 <best_fit_check+0x670>
    free_page(p);
ffffffffc0200b1a:	854e                	mv	a0,s3
ffffffffc0200b1c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200b1e:	01843023          	sd	s8,0(s0)
ffffffffc0200b22:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200b26:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200b2a:	7d8000ef          	jal	ffffffffc0201302 <free_pages>
    free_page(p1);
ffffffffc0200b2e:	4585                	li	a1,1
ffffffffc0200b30:	8556                	mv	a0,s5
ffffffffc0200b32:	7d0000ef          	jal	ffffffffc0201302 <free_pages>
    free_page(p2);
ffffffffc0200b36:	4585                	li	a1,1
ffffffffc0200b38:	8552                	mv	a0,s4
ffffffffc0200b3a:	7c8000ef          	jal	ffffffffc0201302 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200b3e:	4515                	li	a0,5
ffffffffc0200b40:	784000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200b44:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200b46:	48050963          	beqz	a0,ffffffffc0200fd8 <best_fit_check+0x650>
ffffffffc0200b4a:	651c                	ld	a5,8(a0)
ffffffffc0200b4c:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200b4e:	8b85                	andi	a5,a5,1
ffffffffc0200b50:	46079463          	bnez	a5,ffffffffc0200fb8 <best_fit_check+0x630>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200b54:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200b56:	00043a83          	ld	s5,0(s0)
ffffffffc0200b5a:	00843a03          	ld	s4,8(s0)
ffffffffc0200b5e:	e000                	sd	s0,0(s0)
ffffffffc0200b60:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200b62:	762000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200b66:	42051963          	bnez	a0,ffffffffc0200f98 <best_fit_check+0x610>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200b6a:	4589                	li	a1,2
ffffffffc0200b6c:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200b70:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200b74:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200b78:	00005797          	auipc	a5,0x5
ffffffffc0200b7c:	4a07a823          	sw	zero,1200(a5) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200b80:	782000ef          	jal	ffffffffc0201302 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200b84:	8562                	mv	a0,s8
ffffffffc0200b86:	4585                	li	a1,1
ffffffffc0200b88:	77a000ef          	jal	ffffffffc0201302 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200b8c:	4511                	li	a0,4
ffffffffc0200b8e:	736000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200b92:	3e051363          	bnez	a0,ffffffffc0200f78 <best_fit_check+0x5f0>
ffffffffc0200b96:	0309b783          	ld	a5,48(s3)
ffffffffc0200b9a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200b9c:	8b85                	andi	a5,a5,1
ffffffffc0200b9e:	3a078d63          	beqz	a5,ffffffffc0200f58 <best_fit_check+0x5d0>
ffffffffc0200ba2:	0389a703          	lw	a4,56(s3)
ffffffffc0200ba6:	4789                	li	a5,2
ffffffffc0200ba8:	3af71863          	bne	a4,a5,ffffffffc0200f58 <best_fit_check+0x5d0>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200bac:	4505                	li	a0,1
ffffffffc0200bae:	716000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200bb2:	8baa                	mv	s7,a0
ffffffffc0200bb4:	38050263          	beqz	a0,ffffffffc0200f38 <best_fit_check+0x5b0>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200bb8:	4509                	li	a0,2
ffffffffc0200bba:	70a000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200bbe:	34050d63          	beqz	a0,ffffffffc0200f18 <best_fit_check+0x590>
    assert(p0 + 4 == p1);
ffffffffc0200bc2:	337c1b63          	bne	s8,s7,ffffffffc0200ef8 <best_fit_check+0x570>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200bc6:	854e                	mv	a0,s3
ffffffffc0200bc8:	4595                	li	a1,5
ffffffffc0200bca:	738000ef          	jal	ffffffffc0201302 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bce:	4515                	li	a0,5
ffffffffc0200bd0:	6f4000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200bd4:	89aa                	mv	s3,a0
ffffffffc0200bd6:	30050163          	beqz	a0,ffffffffc0200ed8 <best_fit_check+0x550>
    assert(alloc_page() == NULL);
ffffffffc0200bda:	4505                	li	a0,1
ffffffffc0200bdc:	6e8000ef          	jal	ffffffffc02012c4 <alloc_pages>
ffffffffc0200be0:	2c051c63          	bnez	a0,ffffffffc0200eb8 <best_fit_check+0x530>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200be4:	481c                	lw	a5,16(s0)
ffffffffc0200be6:	2a079963          	bnez	a5,ffffffffc0200e98 <best_fit_check+0x510>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200bea:	4595                	li	a1,5
ffffffffc0200bec:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200bee:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200bf2:	01543023          	sd	s5,0(s0)
ffffffffc0200bf6:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200bfa:	708000ef          	jal	ffffffffc0201302 <free_pages>
    return listelm->next;
ffffffffc0200bfe:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c00:	00878963          	beq	a5,s0,ffffffffc0200c12 <best_fit_check+0x28a>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200c04:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c08:	679c                	ld	a5,8(a5)
ffffffffc0200c0a:	397d                	addiw	s2,s2,-1
ffffffffc0200c0c:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c0e:	fe879be3          	bne	a5,s0,ffffffffc0200c04 <best_fit_check+0x27c>
    }
    assert(count == 0);
ffffffffc0200c12:	26091363          	bnez	s2,ffffffffc0200e78 <best_fit_check+0x4f0>
    assert(total == 0);
ffffffffc0200c16:	e0ed                	bnez	s1,ffffffffc0200cf8 <best_fit_check+0x370>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200c18:	60a6                	ld	ra,72(sp)
ffffffffc0200c1a:	6406                	ld	s0,64(sp)
ffffffffc0200c1c:	74e2                	ld	s1,56(sp)
ffffffffc0200c1e:	7942                	ld	s2,48(sp)
ffffffffc0200c20:	79a2                	ld	s3,40(sp)
ffffffffc0200c22:	7a02                	ld	s4,32(sp)
ffffffffc0200c24:	6ae2                	ld	s5,24(sp)
ffffffffc0200c26:	6b42                	ld	s6,16(sp)
ffffffffc0200c28:	6ba2                	ld	s7,8(sp)
ffffffffc0200c2a:	6c02                	ld	s8,0(sp)
ffffffffc0200c2c:	6161                	addi	sp,sp,80
ffffffffc0200c2e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c30:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200c32:	4481                	li	s1,0
ffffffffc0200c34:	4901                	li	s2,0
ffffffffc0200c36:	bb51                	j	ffffffffc02009ca <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200c38:	00001697          	auipc	a3,0x1
ffffffffc0200c3c:	61868693          	addi	a3,a3,1560 # ffffffffc0202250 <etext+0x7ae>
ffffffffc0200c40:	00001617          	auipc	a2,0x1
ffffffffc0200c44:	5e060613          	addi	a2,a2,1504 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200c48:	11700593          	li	a1,279
ffffffffc0200c4c:	00001517          	auipc	a0,0x1
ffffffffc0200c50:	5ec50513          	addi	a0,a0,1516 # ffffffffc0202238 <etext+0x796>
ffffffffc0200c54:	f52ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c58:	00001697          	auipc	a3,0x1
ffffffffc0200c5c:	68868693          	addi	a3,a3,1672 # ffffffffc02022e0 <etext+0x83e>
ffffffffc0200c60:	00001617          	auipc	a2,0x1
ffffffffc0200c64:	5c060613          	addi	a2,a2,1472 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200c68:	0e300593          	li	a1,227
ffffffffc0200c6c:	00001517          	auipc	a0,0x1
ffffffffc0200c70:	5cc50513          	addi	a0,a0,1484 # ffffffffc0202238 <etext+0x796>
ffffffffc0200c74:	f32ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c78:	00001697          	auipc	a3,0x1
ffffffffc0200c7c:	69068693          	addi	a3,a3,1680 # ffffffffc0202308 <etext+0x866>
ffffffffc0200c80:	00001617          	auipc	a2,0x1
ffffffffc0200c84:	5a060613          	addi	a2,a2,1440 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200c88:	0e400593          	li	a1,228
ffffffffc0200c8c:	00001517          	auipc	a0,0x1
ffffffffc0200c90:	5ac50513          	addi	a0,a0,1452 # ffffffffc0202238 <etext+0x796>
ffffffffc0200c94:	f12ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c98:	00001697          	auipc	a3,0x1
ffffffffc0200c9c:	6b068693          	addi	a3,a3,1712 # ffffffffc0202348 <etext+0x8a6>
ffffffffc0200ca0:	00001617          	auipc	a2,0x1
ffffffffc0200ca4:	58060613          	addi	a2,a2,1408 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200ca8:	0e600593          	li	a1,230
ffffffffc0200cac:	00001517          	auipc	a0,0x1
ffffffffc0200cb0:	58c50513          	addi	a0,a0,1420 # ffffffffc0202238 <etext+0x796>
ffffffffc0200cb4:	ef2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200cb8:	00001697          	auipc	a3,0x1
ffffffffc0200cbc:	71868693          	addi	a3,a3,1816 # ffffffffc02023d0 <etext+0x92e>
ffffffffc0200cc0:	00001617          	auipc	a2,0x1
ffffffffc0200cc4:	56060613          	addi	a2,a2,1376 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200cc8:	0ff00593          	li	a1,255
ffffffffc0200ccc:	00001517          	auipc	a0,0x1
ffffffffc0200cd0:	56c50513          	addi	a0,a0,1388 # ffffffffc0202238 <etext+0x796>
ffffffffc0200cd4:	ed2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cd8:	00001697          	auipc	a3,0x1
ffffffffc0200cdc:	5e868693          	addi	a3,a3,1512 # ffffffffc02022c0 <etext+0x81e>
ffffffffc0200ce0:	00001617          	auipc	a2,0x1
ffffffffc0200ce4:	54060613          	addi	a2,a2,1344 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200ce8:	0e100593          	li	a1,225
ffffffffc0200cec:	00001517          	auipc	a0,0x1
ffffffffc0200cf0:	54c50513          	addi	a0,a0,1356 # ffffffffc0202238 <etext+0x796>
ffffffffc0200cf4:	eb2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(total == 0);
ffffffffc0200cf8:	00002697          	auipc	a3,0x2
ffffffffc0200cfc:	80868693          	addi	a3,a3,-2040 # ffffffffc0202500 <etext+0xa5e>
ffffffffc0200d00:	00001617          	auipc	a2,0x1
ffffffffc0200d04:	52060613          	addi	a2,a2,1312 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200d08:	15900593          	li	a1,345
ffffffffc0200d0c:	00001517          	auipc	a0,0x1
ffffffffc0200d10:	52c50513          	addi	a0,a0,1324 # ffffffffc0202238 <etext+0x796>
ffffffffc0200d14:	e92ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200d18:	00001697          	auipc	a3,0x1
ffffffffc0200d1c:	54868693          	addi	a3,a3,1352 # ffffffffc0202260 <etext+0x7be>
ffffffffc0200d20:	00001617          	auipc	a2,0x1
ffffffffc0200d24:	50060613          	addi	a2,a2,1280 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200d28:	11a00593          	li	a1,282
ffffffffc0200d2c:	00001517          	auipc	a0,0x1
ffffffffc0200d30:	50c50513          	addi	a0,a0,1292 # ffffffffc0202238 <etext+0x796>
ffffffffc0200d34:	e72ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d38:	00001697          	auipc	a3,0x1
ffffffffc0200d3c:	56868693          	addi	a3,a3,1384 # ffffffffc02022a0 <etext+0x7fe>
ffffffffc0200d40:	00001617          	auipc	a2,0x1
ffffffffc0200d44:	4e060613          	addi	a2,a2,1248 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200d48:	0e000593          	li	a1,224
ffffffffc0200d4c:	00001517          	auipc	a0,0x1
ffffffffc0200d50:	4ec50513          	addi	a0,a0,1260 # ffffffffc0202238 <etext+0x796>
ffffffffc0200d54:	e52ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d58:	00001697          	auipc	a3,0x1
ffffffffc0200d5c:	52868693          	addi	a3,a3,1320 # ffffffffc0202280 <etext+0x7de>
ffffffffc0200d60:	00001617          	auipc	a2,0x1
ffffffffc0200d64:	4c060613          	addi	a2,a2,1216 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200d68:	0df00593          	li	a1,223
ffffffffc0200d6c:	00001517          	auipc	a0,0x1
ffffffffc0200d70:	4cc50513          	addi	a0,a0,1228 # ffffffffc0202238 <etext+0x796>
ffffffffc0200d74:	e32ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d78:	00001697          	auipc	a3,0x1
ffffffffc0200d7c:	63068693          	addi	a3,a3,1584 # ffffffffc02023a8 <etext+0x906>
ffffffffc0200d80:	00001617          	auipc	a2,0x1
ffffffffc0200d84:	4a060613          	addi	a2,a2,1184 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200d88:	0fc00593          	li	a1,252
ffffffffc0200d8c:	00001517          	auipc	a0,0x1
ffffffffc0200d90:	4ac50513          	addi	a0,a0,1196 # ffffffffc0202238 <etext+0x796>
ffffffffc0200d94:	e12ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d98:	00001697          	auipc	a3,0x1
ffffffffc0200d9c:	52868693          	addi	a3,a3,1320 # ffffffffc02022c0 <etext+0x81e>
ffffffffc0200da0:	00001617          	auipc	a2,0x1
ffffffffc0200da4:	48060613          	addi	a2,a2,1152 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200da8:	0fa00593          	li	a1,250
ffffffffc0200dac:	00001517          	auipc	a0,0x1
ffffffffc0200db0:	48c50513          	addi	a0,a0,1164 # ffffffffc0202238 <etext+0x796>
ffffffffc0200db4:	df2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200db8:	00001697          	auipc	a3,0x1
ffffffffc0200dbc:	4e868693          	addi	a3,a3,1256 # ffffffffc02022a0 <etext+0x7fe>
ffffffffc0200dc0:	00001617          	auipc	a2,0x1
ffffffffc0200dc4:	46060613          	addi	a2,a2,1120 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200dc8:	0f900593          	li	a1,249
ffffffffc0200dcc:	00001517          	auipc	a0,0x1
ffffffffc0200dd0:	46c50513          	addi	a0,a0,1132 # ffffffffc0202238 <etext+0x796>
ffffffffc0200dd4:	dd2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dd8:	00001697          	auipc	a3,0x1
ffffffffc0200ddc:	4a868693          	addi	a3,a3,1192 # ffffffffc0202280 <etext+0x7de>
ffffffffc0200de0:	00001617          	auipc	a2,0x1
ffffffffc0200de4:	44060613          	addi	a2,a2,1088 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200de8:	0f800593          	li	a1,248
ffffffffc0200dec:	00001517          	auipc	a0,0x1
ffffffffc0200df0:	44c50513          	addi	a0,a0,1100 # ffffffffc0202238 <etext+0x796>
ffffffffc0200df4:	db2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(nr_free == 3);
ffffffffc0200df8:	00001697          	auipc	a3,0x1
ffffffffc0200dfc:	5c868693          	addi	a3,a3,1480 # ffffffffc02023c0 <etext+0x91e>
ffffffffc0200e00:	00001617          	auipc	a2,0x1
ffffffffc0200e04:	42060613          	addi	a2,a2,1056 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200e08:	0f600593          	li	a1,246
ffffffffc0200e0c:	00001517          	auipc	a0,0x1
ffffffffc0200e10:	42c50513          	addi	a0,a0,1068 # ffffffffc0202238 <etext+0x796>
ffffffffc0200e14:	d92ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e18:	00001697          	auipc	a3,0x1
ffffffffc0200e1c:	59068693          	addi	a3,a3,1424 # ffffffffc02023a8 <etext+0x906>
ffffffffc0200e20:	00001617          	auipc	a2,0x1
ffffffffc0200e24:	40060613          	addi	a2,a2,1024 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200e28:	0f100593          	li	a1,241
ffffffffc0200e2c:	00001517          	auipc	a0,0x1
ffffffffc0200e30:	40c50513          	addi	a0,a0,1036 # ffffffffc0202238 <etext+0x796>
ffffffffc0200e34:	d72ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e38:	00001697          	auipc	a3,0x1
ffffffffc0200e3c:	55068693          	addi	a3,a3,1360 # ffffffffc0202388 <etext+0x8e6>
ffffffffc0200e40:	00001617          	auipc	a2,0x1
ffffffffc0200e44:	3e060613          	addi	a2,a2,992 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200e48:	0e800593          	li	a1,232
ffffffffc0200e4c:	00001517          	auipc	a0,0x1
ffffffffc0200e50:	3ec50513          	addi	a0,a0,1004 # ffffffffc0202238 <etext+0x796>
ffffffffc0200e54:	d52ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e58:	00001697          	auipc	a3,0x1
ffffffffc0200e5c:	51068693          	addi	a3,a3,1296 # ffffffffc0202368 <etext+0x8c6>
ffffffffc0200e60:	00001617          	auipc	a2,0x1
ffffffffc0200e64:	3c060613          	addi	a2,a2,960 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200e68:	0e700593          	li	a1,231
ffffffffc0200e6c:	00001517          	auipc	a0,0x1
ffffffffc0200e70:	3cc50513          	addi	a0,a0,972 # ffffffffc0202238 <etext+0x796>
ffffffffc0200e74:	d32ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(count == 0);
ffffffffc0200e78:	00001697          	auipc	a3,0x1
ffffffffc0200e7c:	67868693          	addi	a3,a3,1656 # ffffffffc02024f0 <etext+0xa4e>
ffffffffc0200e80:	00001617          	auipc	a2,0x1
ffffffffc0200e84:	3a060613          	addi	a2,a2,928 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200e88:	15800593          	li	a1,344
ffffffffc0200e8c:	00001517          	auipc	a0,0x1
ffffffffc0200e90:	3ac50513          	addi	a0,a0,940 # ffffffffc0202238 <etext+0x796>
ffffffffc0200e94:	d12ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(nr_free == 0);
ffffffffc0200e98:	00001697          	auipc	a3,0x1
ffffffffc0200e9c:	57068693          	addi	a3,a3,1392 # ffffffffc0202408 <etext+0x966>
ffffffffc0200ea0:	00001617          	auipc	a2,0x1
ffffffffc0200ea4:	38060613          	addi	a2,a2,896 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200ea8:	14d00593          	li	a1,333
ffffffffc0200eac:	00001517          	auipc	a0,0x1
ffffffffc0200eb0:	38c50513          	addi	a0,a0,908 # ffffffffc0202238 <etext+0x796>
ffffffffc0200eb4:	cf2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200eb8:	00001697          	auipc	a3,0x1
ffffffffc0200ebc:	4f068693          	addi	a3,a3,1264 # ffffffffc02023a8 <etext+0x906>
ffffffffc0200ec0:	00001617          	auipc	a2,0x1
ffffffffc0200ec4:	36060613          	addi	a2,a2,864 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200ec8:	14700593          	li	a1,327
ffffffffc0200ecc:	00001517          	auipc	a0,0x1
ffffffffc0200ed0:	36c50513          	addi	a0,a0,876 # ffffffffc0202238 <etext+0x796>
ffffffffc0200ed4:	cd2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ed8:	00001697          	auipc	a3,0x1
ffffffffc0200edc:	5f868693          	addi	a3,a3,1528 # ffffffffc02024d0 <etext+0xa2e>
ffffffffc0200ee0:	00001617          	auipc	a2,0x1
ffffffffc0200ee4:	34060613          	addi	a2,a2,832 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200ee8:	14600593          	li	a1,326
ffffffffc0200eec:	00001517          	auipc	a0,0x1
ffffffffc0200ef0:	34c50513          	addi	a0,a0,844 # ffffffffc0202238 <etext+0x796>
ffffffffc0200ef4:	cb2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200ef8:	00001697          	auipc	a3,0x1
ffffffffc0200efc:	5c868693          	addi	a3,a3,1480 # ffffffffc02024c0 <etext+0xa1e>
ffffffffc0200f00:	00001617          	auipc	a2,0x1
ffffffffc0200f04:	32060613          	addi	a2,a2,800 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200f08:	13e00593          	li	a1,318
ffffffffc0200f0c:	00001517          	auipc	a0,0x1
ffffffffc0200f10:	32c50513          	addi	a0,a0,812 # ffffffffc0202238 <etext+0x796>
ffffffffc0200f14:	c92ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200f18:	00001697          	auipc	a3,0x1
ffffffffc0200f1c:	59068693          	addi	a3,a3,1424 # ffffffffc02024a8 <etext+0xa06>
ffffffffc0200f20:	00001617          	auipc	a2,0x1
ffffffffc0200f24:	30060613          	addi	a2,a2,768 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200f28:	13d00593          	li	a1,317
ffffffffc0200f2c:	00001517          	auipc	a0,0x1
ffffffffc0200f30:	30c50513          	addi	a0,a0,780 # ffffffffc0202238 <etext+0x796>
ffffffffc0200f34:	c72ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f38:	00001697          	auipc	a3,0x1
ffffffffc0200f3c:	55068693          	addi	a3,a3,1360 # ffffffffc0202488 <etext+0x9e6>
ffffffffc0200f40:	00001617          	auipc	a2,0x1
ffffffffc0200f44:	2e060613          	addi	a2,a2,736 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200f48:	13c00593          	li	a1,316
ffffffffc0200f4c:	00001517          	auipc	a0,0x1
ffffffffc0200f50:	2ec50513          	addi	a0,a0,748 # ffffffffc0202238 <etext+0x796>
ffffffffc0200f54:	c52ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f58:	00001697          	auipc	a3,0x1
ffffffffc0200f5c:	50068693          	addi	a3,a3,1280 # ffffffffc0202458 <etext+0x9b6>
ffffffffc0200f60:	00001617          	auipc	a2,0x1
ffffffffc0200f64:	2c060613          	addi	a2,a2,704 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200f68:	13a00593          	li	a1,314
ffffffffc0200f6c:	00001517          	auipc	a0,0x1
ffffffffc0200f70:	2cc50513          	addi	a0,a0,716 # ffffffffc0202238 <etext+0x796>
ffffffffc0200f74:	c32ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f78:	00001697          	auipc	a3,0x1
ffffffffc0200f7c:	4c868693          	addi	a3,a3,1224 # ffffffffc0202440 <etext+0x99e>
ffffffffc0200f80:	00001617          	auipc	a2,0x1
ffffffffc0200f84:	2a060613          	addi	a2,a2,672 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200f88:	13900593          	li	a1,313
ffffffffc0200f8c:	00001517          	auipc	a0,0x1
ffffffffc0200f90:	2ac50513          	addi	a0,a0,684 # ffffffffc0202238 <etext+0x796>
ffffffffc0200f94:	c12ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f98:	00001697          	auipc	a3,0x1
ffffffffc0200f9c:	41068693          	addi	a3,a3,1040 # ffffffffc02023a8 <etext+0x906>
ffffffffc0200fa0:	00001617          	auipc	a2,0x1
ffffffffc0200fa4:	28060613          	addi	a2,a2,640 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200fa8:	12d00593          	li	a1,301
ffffffffc0200fac:	00001517          	auipc	a0,0x1
ffffffffc0200fb0:	28c50513          	addi	a0,a0,652 # ffffffffc0202238 <etext+0x796>
ffffffffc0200fb4:	bf2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200fb8:	00001697          	auipc	a3,0x1
ffffffffc0200fbc:	47068693          	addi	a3,a3,1136 # ffffffffc0202428 <etext+0x986>
ffffffffc0200fc0:	00001617          	auipc	a2,0x1
ffffffffc0200fc4:	26060613          	addi	a2,a2,608 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200fc8:	12400593          	li	a1,292
ffffffffc0200fcc:	00001517          	auipc	a0,0x1
ffffffffc0200fd0:	26c50513          	addi	a0,a0,620 # ffffffffc0202238 <etext+0x796>
ffffffffc0200fd4:	bd2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 != NULL);
ffffffffc0200fd8:	00001697          	auipc	a3,0x1
ffffffffc0200fdc:	44068693          	addi	a3,a3,1088 # ffffffffc0202418 <etext+0x976>
ffffffffc0200fe0:	00001617          	auipc	a2,0x1
ffffffffc0200fe4:	24060613          	addi	a2,a2,576 # ffffffffc0202220 <etext+0x77e>
ffffffffc0200fe8:	12300593          	li	a1,291
ffffffffc0200fec:	00001517          	auipc	a0,0x1
ffffffffc0200ff0:	24c50513          	addi	a0,a0,588 # ffffffffc0202238 <etext+0x796>
ffffffffc0200ff4:	bb2ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(nr_free == 0);
ffffffffc0200ff8:	00001697          	auipc	a3,0x1
ffffffffc0200ffc:	41068693          	addi	a3,a3,1040 # ffffffffc0202408 <etext+0x966>
ffffffffc0201000:	00001617          	auipc	a2,0x1
ffffffffc0201004:	22060613          	addi	a2,a2,544 # ffffffffc0202220 <etext+0x77e>
ffffffffc0201008:	10500593          	li	a1,261
ffffffffc020100c:	00001517          	auipc	a0,0x1
ffffffffc0201010:	22c50513          	addi	a0,a0,556 # ffffffffc0202238 <etext+0x796>
ffffffffc0201014:	b92ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201018:	00001697          	auipc	a3,0x1
ffffffffc020101c:	39068693          	addi	a3,a3,912 # ffffffffc02023a8 <etext+0x906>
ffffffffc0201020:	00001617          	auipc	a2,0x1
ffffffffc0201024:	20060613          	addi	a2,a2,512 # ffffffffc0202220 <etext+0x77e>
ffffffffc0201028:	10300593          	li	a1,259
ffffffffc020102c:	00001517          	auipc	a0,0x1
ffffffffc0201030:	20c50513          	addi	a0,a0,524 # ffffffffc0202238 <etext+0x796>
ffffffffc0201034:	b72ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201038:	00001697          	auipc	a3,0x1
ffffffffc020103c:	3b068693          	addi	a3,a3,944 # ffffffffc02023e8 <etext+0x946>
ffffffffc0201040:	00001617          	auipc	a2,0x1
ffffffffc0201044:	1e060613          	addi	a2,a2,480 # ffffffffc0202220 <etext+0x77e>
ffffffffc0201048:	10200593          	li	a1,258
ffffffffc020104c:	00001517          	auipc	a0,0x1
ffffffffc0201050:	1ec50513          	addi	a0,a0,492 # ffffffffc0202238 <etext+0x796>
ffffffffc0201054:	b52ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0201058 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201058:	1141                	addi	sp,sp,-16
ffffffffc020105a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020105c:	14058a63          	beqz	a1,ffffffffc02011b0 <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201060:	00259713          	slli	a4,a1,0x2
ffffffffc0201064:	972e                	add	a4,a4,a1
ffffffffc0201066:	070e                	slli	a4,a4,0x3
ffffffffc0201068:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020106c:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020106e:	c30d                	beqz	a4,ffffffffc0201090 <best_fit_free_pages+0x38>
ffffffffc0201070:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201072:	8b05                	andi	a4,a4,1
ffffffffc0201074:	10071e63          	bnez	a4,ffffffffc0201190 <best_fit_free_pages+0x138>
ffffffffc0201078:	6798                	ld	a4,8(a5)
ffffffffc020107a:	8b09                	andi	a4,a4,2
ffffffffc020107c:	10071a63          	bnez	a4,ffffffffc0201190 <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc0201080:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201084:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201088:	02878793          	addi	a5,a5,40
ffffffffc020108c:	fed792e3          	bne	a5,a3,ffffffffc0201070 <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0201090:	2581                	sext.w	a1,a1
ffffffffc0201092:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201094:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201098:	4789                	li	a5,2
ffffffffc020109a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020109e:	00005697          	auipc	a3,0x5
ffffffffc02010a2:	f7a68693          	addi	a3,a3,-134 # ffffffffc0206018 <free_area>
ffffffffc02010a6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02010a8:	669c                	ld	a5,8(a3)
ffffffffc02010aa:	9f2d                	addw	a4,a4,a1
ffffffffc02010ac:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02010ae:	0ad78563          	beq	a5,a3,ffffffffc0201158 <best_fit_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc02010b2:	fe878713          	addi	a4,a5,-24
ffffffffc02010b6:	4581                	li	a1,0
ffffffffc02010b8:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02010bc:	00e56a63          	bltu	a0,a4,ffffffffc02010d0 <best_fit_free_pages+0x78>
    return listelm->next;
ffffffffc02010c0:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02010c2:	06d70263          	beq	a4,a3,ffffffffc0201126 <best_fit_free_pages+0xce>
    struct Page *p = base;
ffffffffc02010c6:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02010c8:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02010cc:	fee57ae3          	bgeu	a0,a4,ffffffffc02010c0 <best_fit_free_pages+0x68>
ffffffffc02010d0:	c199                	beqz	a1,ffffffffc02010d6 <best_fit_free_pages+0x7e>
ffffffffc02010d2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02010d6:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02010d8:	e390                	sd	a2,0(a5)
ffffffffc02010da:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02010dc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010de:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02010e0:	02d70063          	beq	a4,a3,ffffffffc0201100 <best_fit_free_pages+0xa8>
        if(p + p->property == base){
ffffffffc02010e4:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02010e8:	fe870593          	addi	a1,a4,-24
        if(p + p->property == base){
ffffffffc02010ec:	02081613          	slli	a2,a6,0x20
ffffffffc02010f0:	9201                	srli	a2,a2,0x20
ffffffffc02010f2:	00261793          	slli	a5,a2,0x2
ffffffffc02010f6:	97b2                	add	a5,a5,a2
ffffffffc02010f8:	078e                	slli	a5,a5,0x3
ffffffffc02010fa:	97ae                	add	a5,a5,a1
ffffffffc02010fc:	02f50f63          	beq	a0,a5,ffffffffc020113a <best_fit_free_pages+0xe2>
    return listelm->next;
ffffffffc0201100:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201102:	00d70f63          	beq	a4,a3,ffffffffc0201120 <best_fit_free_pages+0xc8>
        if (base + base->property == p) {
ffffffffc0201106:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201108:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc020110c:	02059613          	slli	a2,a1,0x20
ffffffffc0201110:	9201                	srli	a2,a2,0x20
ffffffffc0201112:	00261793          	slli	a5,a2,0x2
ffffffffc0201116:	97b2                	add	a5,a5,a2
ffffffffc0201118:	078e                	slli	a5,a5,0x3
ffffffffc020111a:	97aa                	add	a5,a5,a0
ffffffffc020111c:	04f68a63          	beq	a3,a5,ffffffffc0201170 <best_fit_free_pages+0x118>
}
ffffffffc0201120:	60a2                	ld	ra,8(sp)
ffffffffc0201122:	0141                	addi	sp,sp,16
ffffffffc0201124:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201126:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201128:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020112a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020112c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020112e:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201130:	02d70d63          	beq	a4,a3,ffffffffc020116a <best_fit_free_pages+0x112>
ffffffffc0201134:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201136:	87ba                	mv	a5,a4
ffffffffc0201138:	bf41                	j	ffffffffc02010c8 <best_fit_free_pages+0x70>
            p->property += base->property;
ffffffffc020113a:	491c                	lw	a5,16(a0)
ffffffffc020113c:	010787bb          	addw	a5,a5,a6
ffffffffc0201140:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201144:	57f5                	li	a5,-3
ffffffffc0201146:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020114a:	6d10                	ld	a2,24(a0)
ffffffffc020114c:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc020114e:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc0201150:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201152:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201154:	e390                	sd	a2,0(a5)
ffffffffc0201156:	b775                	j	ffffffffc0201102 <best_fit_free_pages+0xaa>
}
ffffffffc0201158:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020115a:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020115e:	e398                	sd	a4,0(a5)
ffffffffc0201160:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201162:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201164:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201166:	0141                	addi	sp,sp,16
ffffffffc0201168:	8082                	ret
ffffffffc020116a:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020116c:	873e                	mv	a4,a5
ffffffffc020116e:	bf8d                	j	ffffffffc02010e0 <best_fit_free_pages+0x88>
            base->property += p->property;
ffffffffc0201170:	ff872783          	lw	a5,-8(a4)
ffffffffc0201174:	ff070693          	addi	a3,a4,-16
ffffffffc0201178:	9fad                	addw	a5,a5,a1
ffffffffc020117a:	c91c                	sw	a5,16(a0)
ffffffffc020117c:	57f5                	li	a5,-3
ffffffffc020117e:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201182:	6314                	ld	a3,0(a4)
ffffffffc0201184:	671c                	ld	a5,8(a4)
}
ffffffffc0201186:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201188:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020118a:	e394                	sd	a3,0(a5)
ffffffffc020118c:	0141                	addi	sp,sp,16
ffffffffc020118e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201190:	00001697          	auipc	a3,0x1
ffffffffc0201194:	38068693          	addi	a3,a3,896 # ffffffffc0202510 <etext+0xa6e>
ffffffffc0201198:	00001617          	auipc	a2,0x1
ffffffffc020119c:	08860613          	addi	a2,a2,136 # ffffffffc0202220 <etext+0x77e>
ffffffffc02011a0:	09d00593          	li	a1,157
ffffffffc02011a4:	00001517          	auipc	a0,0x1
ffffffffc02011a8:	09450513          	addi	a0,a0,148 # ffffffffc0202238 <etext+0x796>
ffffffffc02011ac:	9faff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(n > 0);
ffffffffc02011b0:	00001697          	auipc	a3,0x1
ffffffffc02011b4:	06868693          	addi	a3,a3,104 # ffffffffc0202218 <etext+0x776>
ffffffffc02011b8:	00001617          	auipc	a2,0x1
ffffffffc02011bc:	06860613          	addi	a2,a2,104 # ffffffffc0202220 <etext+0x77e>
ffffffffc02011c0:	09a00593          	li	a1,154
ffffffffc02011c4:	00001517          	auipc	a0,0x1
ffffffffc02011c8:	07450513          	addi	a0,a0,116 # ffffffffc0202238 <etext+0x796>
ffffffffc02011cc:	9daff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc02011d0 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02011d0:	1141                	addi	sp,sp,-16
ffffffffc02011d2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02011d4:	c9e1                	beqz	a1,ffffffffc02012a4 <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02011d6:	00259713          	slli	a4,a1,0x2
ffffffffc02011da:	972e                	add	a4,a4,a1
ffffffffc02011dc:	070e                	slli	a4,a4,0x3
ffffffffc02011de:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02011e2:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02011e4:	cf11                	beqz	a4,ffffffffc0201200 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02011e6:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02011e8:	8b05                	andi	a4,a4,1
ffffffffc02011ea:	cf49                	beqz	a4,ffffffffc0201284 <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02011ec:	0007a823          	sw	zero,16(a5)
ffffffffc02011f0:	0007b423          	sd	zero,8(a5)
ffffffffc02011f4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02011f8:	02878793          	addi	a5,a5,40
ffffffffc02011fc:	fed795e3          	bne	a5,a3,ffffffffc02011e6 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc0201200:	2581                	sext.w	a1,a1
ffffffffc0201202:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201204:	4789                	li	a5,2
ffffffffc0201206:	00850713          	addi	a4,a0,8
ffffffffc020120a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020120e:	00005697          	auipc	a3,0x5
ffffffffc0201212:	e0a68693          	addi	a3,a3,-502 # ffffffffc0206018 <free_area>
ffffffffc0201216:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201218:	669c                	ld	a5,8(a3)
ffffffffc020121a:	9f2d                	addw	a4,a4,a1
ffffffffc020121c:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020121e:	04d78663          	beq	a5,a3,ffffffffc020126a <best_fit_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201222:	fe878713          	addi	a4,a5,-24
ffffffffc0201226:	4581                	li	a1,0
ffffffffc0201228:	01850613          	addi	a2,a0,24
	    if(base<page){
ffffffffc020122c:	00e56a63          	bltu	a0,a4,ffffffffc0201240 <best_fit_init_memmap+0x70>
    return listelm->next;
ffffffffc0201230:	6798                	ld	a4,8(a5)
	    else if(list_next(le)== &free_list){
ffffffffc0201232:	02d70263          	beq	a4,a3,ffffffffc0201256 <best_fit_init_memmap+0x86>
    struct Page *p = base;
ffffffffc0201236:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201238:	fe878713          	addi	a4,a5,-24
	    if(base<page){
ffffffffc020123c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201230 <best_fit_init_memmap+0x60>
ffffffffc0201240:	c199                	beqz	a1,ffffffffc0201246 <best_fit_init_memmap+0x76>
ffffffffc0201242:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201246:	6398                	ld	a4,0(a5)
}
ffffffffc0201248:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020124a:	e390                	sd	a2,0(a5)
ffffffffc020124c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020124e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201250:	ed18                	sd	a4,24(a0)
ffffffffc0201252:	0141                	addi	sp,sp,16
ffffffffc0201254:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201256:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201258:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020125a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020125c:	ed1c                	sd	a5,24(a0)
	    	list_add(le, &(base->page_link));
ffffffffc020125e:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201260:	00d70e63          	beq	a4,a3,ffffffffc020127c <best_fit_init_memmap+0xac>
ffffffffc0201264:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201266:	87ba                	mv	a5,a4
ffffffffc0201268:	bfc1                	j	ffffffffc0201238 <best_fit_init_memmap+0x68>
}
ffffffffc020126a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020126c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201270:	e398                	sd	a4,0(a5)
ffffffffc0201272:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201274:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201276:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201278:	0141                	addi	sp,sp,16
ffffffffc020127a:	8082                	ret
ffffffffc020127c:	60a2                	ld	ra,8(sp)
ffffffffc020127e:	e290                	sd	a2,0(a3)
ffffffffc0201280:	0141                	addi	sp,sp,16
ffffffffc0201282:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201284:	00001697          	auipc	a3,0x1
ffffffffc0201288:	2b468693          	addi	a3,a3,692 # ffffffffc0202538 <etext+0xa96>
ffffffffc020128c:	00001617          	auipc	a2,0x1
ffffffffc0201290:	f9460613          	addi	a2,a2,-108 # ffffffffc0202220 <etext+0x77e>
ffffffffc0201294:	04b00593          	li	a1,75
ffffffffc0201298:	00001517          	auipc	a0,0x1
ffffffffc020129c:	fa050513          	addi	a0,a0,-96 # ffffffffc0202238 <etext+0x796>
ffffffffc02012a0:	906ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(n > 0);
ffffffffc02012a4:	00001697          	auipc	a3,0x1
ffffffffc02012a8:	f7468693          	addi	a3,a3,-140 # ffffffffc0202218 <etext+0x776>
ffffffffc02012ac:	00001617          	auipc	a2,0x1
ffffffffc02012b0:	f7460613          	addi	a2,a2,-140 # ffffffffc0202220 <etext+0x77e>
ffffffffc02012b4:	04800593          	li	a1,72
ffffffffc02012b8:	00001517          	auipc	a0,0x1
ffffffffc02012bc:	f8050513          	addi	a0,a0,-128 # ffffffffc0202238 <etext+0x796>
ffffffffc02012c0:	8e6ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc02012c4 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02012c4:	100027f3          	csrr	a5,sstatus
ffffffffc02012c8:	8b89                	andi	a5,a5,2
ffffffffc02012ca:	e799                	bnez	a5,ffffffffc02012d8 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02012cc:	00005797          	auipc	a5,0x5
ffffffffc02012d0:	17c7b783          	ld	a5,380(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc02012d4:	6f9c                	ld	a5,24(a5)
ffffffffc02012d6:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02012d8:	1141                	addi	sp,sp,-16
ffffffffc02012da:	e406                	sd	ra,8(sp)
ffffffffc02012dc:	e022                	sd	s0,0(sp)
ffffffffc02012de:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02012e0:	97aff0ef          	jal	ffffffffc020045a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02012e4:	00005797          	auipc	a5,0x5
ffffffffc02012e8:	1647b783          	ld	a5,356(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc02012ec:	6f9c                	ld	a5,24(a5)
ffffffffc02012ee:	8522                	mv	a0,s0
ffffffffc02012f0:	9782                	jalr	a5
ffffffffc02012f2:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02012f4:	960ff0ef          	jal	ffffffffc0200454 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02012f8:	60a2                	ld	ra,8(sp)
ffffffffc02012fa:	8522                	mv	a0,s0
ffffffffc02012fc:	6402                	ld	s0,0(sp)
ffffffffc02012fe:	0141                	addi	sp,sp,16
ffffffffc0201300:	8082                	ret

ffffffffc0201302 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201302:	100027f3          	csrr	a5,sstatus
ffffffffc0201306:	8b89                	andi	a5,a5,2
ffffffffc0201308:	e799                	bnez	a5,ffffffffc0201316 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020130a:	00005797          	auipc	a5,0x5
ffffffffc020130e:	13e7b783          	ld	a5,318(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc0201312:	739c                	ld	a5,32(a5)
ffffffffc0201314:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201316:	1101                	addi	sp,sp,-32
ffffffffc0201318:	ec06                	sd	ra,24(sp)
ffffffffc020131a:	e822                	sd	s0,16(sp)
ffffffffc020131c:	e426                	sd	s1,8(sp)
ffffffffc020131e:	842a                	mv	s0,a0
ffffffffc0201320:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201322:	938ff0ef          	jal	ffffffffc020045a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201326:	00005797          	auipc	a5,0x5
ffffffffc020132a:	1227b783          	ld	a5,290(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc020132e:	739c                	ld	a5,32(a5)
ffffffffc0201330:	85a6                	mv	a1,s1
ffffffffc0201332:	8522                	mv	a0,s0
ffffffffc0201334:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201336:	6442                	ld	s0,16(sp)
ffffffffc0201338:	60e2                	ld	ra,24(sp)
ffffffffc020133a:	64a2                	ld	s1,8(sp)
ffffffffc020133c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020133e:	916ff06f          	j	ffffffffc0200454 <intr_enable>

ffffffffc0201342 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201342:	100027f3          	csrr	a5,sstatus
ffffffffc0201346:	8b89                	andi	a5,a5,2
ffffffffc0201348:	e799                	bnez	a5,ffffffffc0201356 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020134a:	00005797          	auipc	a5,0x5
ffffffffc020134e:	0fe7b783          	ld	a5,254(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc0201352:	779c                	ld	a5,40(a5)
ffffffffc0201354:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201356:	1141                	addi	sp,sp,-16
ffffffffc0201358:	e406                	sd	ra,8(sp)
ffffffffc020135a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020135c:	8feff0ef          	jal	ffffffffc020045a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201360:	00005797          	auipc	a5,0x5
ffffffffc0201364:	0e87b783          	ld	a5,232(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc0201368:	779c                	ld	a5,40(a5)
ffffffffc020136a:	9782                	jalr	a5
ffffffffc020136c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020136e:	8e6ff0ef          	jal	ffffffffc0200454 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201372:	60a2                	ld	ra,8(sp)
ffffffffc0201374:	8522                	mv	a0,s0
ffffffffc0201376:	6402                	ld	s0,0(sp)
ffffffffc0201378:	0141                	addi	sp,sp,16
ffffffffc020137a:	8082                	ret

ffffffffc020137c <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020137c:	00001797          	auipc	a5,0x1
ffffffffc0201380:	43c78793          	addi	a5,a5,1084 # ffffffffc02027b8 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201384:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201386:	1101                	addi	sp,sp,-32
ffffffffc0201388:	ec06                	sd	ra,24(sp)
ffffffffc020138a:	e822                	sd	s0,16(sp)
ffffffffc020138c:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020138e:	00001517          	auipc	a0,0x1
ffffffffc0201392:	1d250513          	addi	a0,a0,466 # ffffffffc0202560 <etext+0xabe>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201396:	00005497          	auipc	s1,0x5
ffffffffc020139a:	0b248493          	addi	s1,s1,178 # ffffffffc0206448 <pmm_manager>
ffffffffc020139e:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02013a0:	d13fe0ef          	jal	ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc02013a4:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02013a6:	00005417          	auipc	s0,0x5
ffffffffc02013aa:	0ba40413          	addi	s0,s0,186 # ffffffffc0206460 <va_pa_offset>
    pmm_manager->init();
ffffffffc02013ae:	679c                	ld	a5,8(a5)
ffffffffc02013b0:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02013b2:	57f5                	li	a5,-3
ffffffffc02013b4:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02013b6:	00001517          	auipc	a0,0x1
ffffffffc02013ba:	1c250513          	addi	a0,a0,450 # ffffffffc0202578 <etext+0xad6>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02013be:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc02013c0:	cf3fe0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02013c4:	46c5                	li	a3,17
ffffffffc02013c6:	06ee                	slli	a3,a3,0x1b
ffffffffc02013c8:	40100613          	li	a2,1025
ffffffffc02013cc:	16fd                	addi	a3,a3,-1
ffffffffc02013ce:	0656                	slli	a2,a2,0x15
ffffffffc02013d0:	07e005b7          	lui	a1,0x7e00
ffffffffc02013d4:	00001517          	auipc	a0,0x1
ffffffffc02013d8:	1bc50513          	addi	a0,a0,444 # ffffffffc0202590 <etext+0xaee>
ffffffffc02013dc:	cd7fe0ef          	jal	ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02013e0:	777d                	lui	a4,0xfffff
ffffffffc02013e2:	00006797          	auipc	a5,0x6
ffffffffc02013e6:	09d78793          	addi	a5,a5,157 # ffffffffc020747f <end+0xfff>
ffffffffc02013ea:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02013ec:	00005517          	auipc	a0,0x5
ffffffffc02013f0:	07c50513          	addi	a0,a0,124 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02013f4:	00005597          	auipc	a1,0x5
ffffffffc02013f8:	07c58593          	addi	a1,a1,124 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02013fc:	00088737          	lui	a4,0x88
ffffffffc0201400:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201402:	e19c                	sd	a5,0(a1)
ffffffffc0201404:	4705                	li	a4,1
ffffffffc0201406:	07a1                	addi	a5,a5,8
ffffffffc0201408:	40e7b02f          	amoor.d	zero,a4,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020140c:	02800693          	li	a3,40
ffffffffc0201410:	4885                	li	a7,1
ffffffffc0201412:	fff80837          	lui	a6,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201416:	619c                	ld	a5,0(a1)
ffffffffc0201418:	97b6                	add	a5,a5,a3
ffffffffc020141a:	07a1                	addi	a5,a5,8
ffffffffc020141c:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201420:	611c                	ld	a5,0(a0)
ffffffffc0201422:	0705                	addi	a4,a4,1 # 88001 <kern_entry-0xffffffffc0177fff>
ffffffffc0201424:	02868693          	addi	a3,a3,40
ffffffffc0201428:	01078633          	add	a2,a5,a6
ffffffffc020142c:	fec765e3          	bltu	a4,a2,ffffffffc0201416 <pmm_init+0x9a>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201430:	6190                	ld	a2,0(a1)
ffffffffc0201432:	00279693          	slli	a3,a5,0x2
ffffffffc0201436:	96be                	add	a3,a3,a5
ffffffffc0201438:	fec00737          	lui	a4,0xfec00
ffffffffc020143c:	9732                	add	a4,a4,a2
ffffffffc020143e:	068e                	slli	a3,a3,0x3
ffffffffc0201440:	96ba                	add	a3,a3,a4
ffffffffc0201442:	c0200737          	lui	a4,0xc0200
ffffffffc0201446:	0ae6e463          	bltu	a3,a4,ffffffffc02014ee <pmm_init+0x172>
ffffffffc020144a:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc020144c:	45c5                	li	a1,17
ffffffffc020144e:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201450:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201452:	04b6e963          	bltu	a3,a1,ffffffffc02014a4 <pmm_init+0x128>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201456:	609c                	ld	a5,0(s1)
ffffffffc0201458:	7b9c                	ld	a5,48(a5)
ffffffffc020145a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020145c:	00001517          	auipc	a0,0x1
ffffffffc0201460:	1cc50513          	addi	a0,a0,460 # ffffffffc0202628 <etext+0xb86>
ffffffffc0201464:	c4ffe0ef          	jal	ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201468:	00004597          	auipc	a1,0x4
ffffffffc020146c:	b9858593          	addi	a1,a1,-1128 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201470:	00005797          	auipc	a5,0x5
ffffffffc0201474:	feb7b423          	sd	a1,-24(a5) # ffffffffc0206458 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201478:	c02007b7          	lui	a5,0xc0200
ffffffffc020147c:	08f5e563          	bltu	a1,a5,ffffffffc0201506 <pmm_init+0x18a>
ffffffffc0201480:	601c                	ld	a5,0(s0)
}
ffffffffc0201482:	6442                	ld	s0,16(sp)
ffffffffc0201484:	60e2                	ld	ra,24(sp)
ffffffffc0201486:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201488:	40f586b3          	sub	a3,a1,a5
ffffffffc020148c:	00005797          	auipc	a5,0x5
ffffffffc0201490:	fcd7b223          	sd	a3,-60(a5) # ffffffffc0206450 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201494:	00001517          	auipc	a0,0x1
ffffffffc0201498:	1b450513          	addi	a0,a0,436 # ffffffffc0202648 <etext+0xba6>
ffffffffc020149c:	8636                	mv	a2,a3
}
ffffffffc020149e:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02014a0:	c13fe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02014a4:	6705                	lui	a4,0x1
ffffffffc02014a6:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02014a8:	96ba                	add	a3,a3,a4
ffffffffc02014aa:	777d                	lui	a4,0xfffff
ffffffffc02014ac:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02014ae:	00c6d713          	srli	a4,a3,0xc
ffffffffc02014b2:	02f77263          	bgeu	a4,a5,ffffffffc02014d6 <pmm_init+0x15a>
    pmm_manager->init_memmap(base, n);
ffffffffc02014b6:	0004b803          	ld	a6,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02014ba:	fff807b7          	lui	a5,0xfff80
ffffffffc02014be:	97ba                	add	a5,a5,a4
ffffffffc02014c0:	00279513          	slli	a0,a5,0x2
ffffffffc02014c4:	953e                	add	a0,a0,a5
ffffffffc02014c6:	01083783          	ld	a5,16(a6) # fffffffffff80010 <end+0x3fd79b90>
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02014ca:	8d95                	sub	a1,a1,a3
ffffffffc02014cc:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02014ce:	81b1                	srli	a1,a1,0xc
ffffffffc02014d0:	9532                	add	a0,a0,a2
ffffffffc02014d2:	9782                	jalr	a5
}
ffffffffc02014d4:	b749                	j	ffffffffc0201456 <pmm_init+0xda>
        panic("pa2page called with invalid pa");
ffffffffc02014d6:	00001617          	auipc	a2,0x1
ffffffffc02014da:	12260613          	addi	a2,a2,290 # ffffffffc02025f8 <etext+0xb56>
ffffffffc02014de:	06b00593          	li	a1,107
ffffffffc02014e2:	00001517          	auipc	a0,0x1
ffffffffc02014e6:	13650513          	addi	a0,a0,310 # ffffffffc0202618 <etext+0xb76>
ffffffffc02014ea:	ebdfe0ef          	jal	ffffffffc02003a6 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02014ee:	00001617          	auipc	a2,0x1
ffffffffc02014f2:	0d260613          	addi	a2,a2,210 # ffffffffc02025c0 <etext+0xb1e>
ffffffffc02014f6:	06e00593          	li	a1,110
ffffffffc02014fa:	00001517          	auipc	a0,0x1
ffffffffc02014fe:	0ee50513          	addi	a0,a0,238 # ffffffffc02025e8 <etext+0xb46>
ffffffffc0201502:	ea5fe0ef          	jal	ffffffffc02003a6 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201506:	86ae                	mv	a3,a1
ffffffffc0201508:	00001617          	auipc	a2,0x1
ffffffffc020150c:	0b860613          	addi	a2,a2,184 # ffffffffc02025c0 <etext+0xb1e>
ffffffffc0201510:	08900593          	li	a1,137
ffffffffc0201514:	00001517          	auipc	a0,0x1
ffffffffc0201518:	0d450513          	addi	a0,a0,212 # ffffffffc02025e8 <etext+0xb46>
ffffffffc020151c:	e8bfe0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0201520 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201520:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201524:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201526:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020152a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020152c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201530:	f022                	sd	s0,32(sp)
ffffffffc0201532:	ec26                	sd	s1,24(sp)
ffffffffc0201534:	e84a                	sd	s2,16(sp)
ffffffffc0201536:	f406                	sd	ra,40(sp)
ffffffffc0201538:	84aa                	mv	s1,a0
ffffffffc020153a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020153c:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf8b7f>
    unsigned mod = do_div(result, base);
ffffffffc0201540:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201542:	05067063          	bgeu	a2,a6,ffffffffc0201582 <printnum+0x62>
ffffffffc0201546:	e44e                	sd	s3,8(sp)
ffffffffc0201548:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020154a:	4785                	li	a5,1
ffffffffc020154c:	00e7d763          	bge	a5,a4,ffffffffc020155a <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0201550:	85ca                	mv	a1,s2
ffffffffc0201552:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201554:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201556:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201558:	fc65                	bnez	s0,ffffffffc0201550 <printnum+0x30>
ffffffffc020155a:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020155c:	1a02                	slli	s4,s4,0x20
ffffffffc020155e:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201562:	00001797          	auipc	a5,0x1
ffffffffc0201566:	12678793          	addi	a5,a5,294 # ffffffffc0202688 <etext+0xbe6>
ffffffffc020156a:	97d2                	add	a5,a5,s4
}
ffffffffc020156c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020156e:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201572:	70a2                	ld	ra,40(sp)
ffffffffc0201574:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201576:	85ca                	mv	a1,s2
ffffffffc0201578:	87a6                	mv	a5,s1
}
ffffffffc020157a:	6942                	ld	s2,16(sp)
ffffffffc020157c:	64e2                	ld	s1,24(sp)
ffffffffc020157e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201580:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201582:	03065633          	divu	a2,a2,a6
ffffffffc0201586:	8722                	mv	a4,s0
ffffffffc0201588:	f99ff0ef          	jal	ffffffffc0201520 <printnum>
ffffffffc020158c:	bfc1                	j	ffffffffc020155c <printnum+0x3c>

ffffffffc020158e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020158e:	7119                	addi	sp,sp,-128
ffffffffc0201590:	f4a6                	sd	s1,104(sp)
ffffffffc0201592:	f0ca                	sd	s2,96(sp)
ffffffffc0201594:	ecce                	sd	s3,88(sp)
ffffffffc0201596:	e8d2                	sd	s4,80(sp)
ffffffffc0201598:	e4d6                	sd	s5,72(sp)
ffffffffc020159a:	e0da                	sd	s6,64(sp)
ffffffffc020159c:	f862                	sd	s8,48(sp)
ffffffffc020159e:	fc86                	sd	ra,120(sp)
ffffffffc02015a0:	f8a2                	sd	s0,112(sp)
ffffffffc02015a2:	fc5e                	sd	s7,56(sp)
ffffffffc02015a4:	f466                	sd	s9,40(sp)
ffffffffc02015a6:	f06a                	sd	s10,32(sp)
ffffffffc02015a8:	ec6e                	sd	s11,24(sp)
ffffffffc02015aa:	892a                	mv	s2,a0
ffffffffc02015ac:	84ae                	mv	s1,a1
ffffffffc02015ae:	8c32                	mv	s8,a2
ffffffffc02015b0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015b2:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015b6:	05500b13          	li	s6,85
ffffffffc02015ba:	00001a97          	auipc	s5,0x1
ffffffffc02015be:	236a8a93          	addi	s5,s5,566 # ffffffffc02027f0 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015c2:	000c4503          	lbu	a0,0(s8)
ffffffffc02015c6:	001c0413          	addi	s0,s8,1
ffffffffc02015ca:	01350a63          	beq	a0,s3,ffffffffc02015de <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02015ce:	cd0d                	beqz	a0,ffffffffc0201608 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02015d0:	85a6                	mv	a1,s1
ffffffffc02015d2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015d4:	00044503          	lbu	a0,0(s0)
ffffffffc02015d8:	0405                	addi	s0,s0,1
ffffffffc02015da:	ff351ae3          	bne	a0,s3,ffffffffc02015ce <vprintfmt+0x40>
        char padc = ' ';
ffffffffc02015de:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02015e2:	4b81                	li	s7,0
ffffffffc02015e4:	4601                	li	a2,0
        width = precision = -1;
ffffffffc02015e6:	5d7d                	li	s10,-1
ffffffffc02015e8:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015ea:	00044683          	lbu	a3,0(s0)
ffffffffc02015ee:	00140c13          	addi	s8,s0,1
ffffffffc02015f2:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02015f6:	0ff5f593          	zext.b	a1,a1
ffffffffc02015fa:	02bb6663          	bltu	s6,a1,ffffffffc0201626 <vprintfmt+0x98>
ffffffffc02015fe:	058a                	slli	a1,a1,0x2
ffffffffc0201600:	95d6                	add	a1,a1,s5
ffffffffc0201602:	4198                	lw	a4,0(a1)
ffffffffc0201604:	9756                	add	a4,a4,s5
ffffffffc0201606:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201608:	70e6                	ld	ra,120(sp)
ffffffffc020160a:	7446                	ld	s0,112(sp)
ffffffffc020160c:	74a6                	ld	s1,104(sp)
ffffffffc020160e:	7906                	ld	s2,96(sp)
ffffffffc0201610:	69e6                	ld	s3,88(sp)
ffffffffc0201612:	6a46                	ld	s4,80(sp)
ffffffffc0201614:	6aa6                	ld	s5,72(sp)
ffffffffc0201616:	6b06                	ld	s6,64(sp)
ffffffffc0201618:	7be2                	ld	s7,56(sp)
ffffffffc020161a:	7c42                	ld	s8,48(sp)
ffffffffc020161c:	7ca2                	ld	s9,40(sp)
ffffffffc020161e:	7d02                	ld	s10,32(sp)
ffffffffc0201620:	6de2                	ld	s11,24(sp)
ffffffffc0201622:	6109                	addi	sp,sp,128
ffffffffc0201624:	8082                	ret
            putch('%', putdat);
ffffffffc0201626:	85a6                	mv	a1,s1
ffffffffc0201628:	02500513          	li	a0,37
ffffffffc020162c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020162e:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201632:	02500793          	li	a5,37
ffffffffc0201636:	8c22                	mv	s8,s0
ffffffffc0201638:	f8f705e3          	beq	a4,a5,ffffffffc02015c2 <vprintfmt+0x34>
ffffffffc020163c:	02500713          	li	a4,37
ffffffffc0201640:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201644:	1c7d                	addi	s8,s8,-1
ffffffffc0201646:	fee79de3          	bne	a5,a4,ffffffffc0201640 <vprintfmt+0xb2>
ffffffffc020164a:	bfa5                	j	ffffffffc02015c2 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020164c:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201650:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0201652:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201656:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc020165a:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020165e:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0201660:	02b76563          	bltu	a4,a1,ffffffffc020168a <vprintfmt+0xfc>
ffffffffc0201664:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0201666:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020166a:	002d171b          	slliw	a4,s10,0x2
ffffffffc020166e:	01a7073b          	addw	a4,a4,s10
ffffffffc0201672:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201676:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201678:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020167c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020167e:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0201682:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201686:	feb570e3          	bgeu	a0,a1,ffffffffc0201666 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc020168a:	f60cd0e3          	bgez	s9,ffffffffc02015ea <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc020168e:	8cea                	mv	s9,s10
ffffffffc0201690:	5d7d                	li	s10,-1
ffffffffc0201692:	bfa1                	j	ffffffffc02015ea <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201694:	8db6                	mv	s11,a3
ffffffffc0201696:	8462                	mv	s0,s8
ffffffffc0201698:	bf89                	j	ffffffffc02015ea <vprintfmt+0x5c>
ffffffffc020169a:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc020169c:	4b85                	li	s7,1
            goto reswitch;
ffffffffc020169e:	b7b1                	j	ffffffffc02015ea <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02016a0:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02016a2:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc02016a6:	00c7c463          	blt	a5,a2,ffffffffc02016ae <vprintfmt+0x120>
    else if (lflag) {
ffffffffc02016aa:	1a060163          	beqz	a2,ffffffffc020184c <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc02016ae:	000a3603          	ld	a2,0(s4)
ffffffffc02016b2:	46c1                	li	a3,16
ffffffffc02016b4:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02016b6:	000d879b          	sext.w	a5,s11
ffffffffc02016ba:	8766                	mv	a4,s9
ffffffffc02016bc:	85a6                	mv	a1,s1
ffffffffc02016be:	854a                	mv	a0,s2
ffffffffc02016c0:	e61ff0ef          	jal	ffffffffc0201520 <printnum>
            break;
ffffffffc02016c4:	bdfd                	j	ffffffffc02015c2 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc02016c6:	000a2503          	lw	a0,0(s4)
ffffffffc02016ca:	85a6                	mv	a1,s1
ffffffffc02016cc:	0a21                	addi	s4,s4,8
ffffffffc02016ce:	9902                	jalr	s2
            break;
ffffffffc02016d0:	bdcd                	j	ffffffffc02015c2 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02016d2:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02016d4:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc02016d8:	00c7c463          	blt	a5,a2,ffffffffc02016e0 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc02016dc:	16060363          	beqz	a2,ffffffffc0201842 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc02016e0:	000a3603          	ld	a2,0(s4)
ffffffffc02016e4:	46a9                	li	a3,10
ffffffffc02016e6:	8a3a                	mv	s4,a4
ffffffffc02016e8:	b7f9                	j	ffffffffc02016b6 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc02016ea:	85a6                	mv	a1,s1
ffffffffc02016ec:	03000513          	li	a0,48
ffffffffc02016f0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02016f2:	85a6                	mv	a1,s1
ffffffffc02016f4:	07800513          	li	a0,120
ffffffffc02016f8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02016fa:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02016fe:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201700:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201702:	bf55                	j	ffffffffc02016b6 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0201704:	85a6                	mv	a1,s1
ffffffffc0201706:	02500513          	li	a0,37
ffffffffc020170a:	9902                	jalr	s2
            break;
ffffffffc020170c:	bd5d                	j	ffffffffc02015c2 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020170e:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201712:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201714:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201716:	bf95                	j	ffffffffc020168a <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0201718:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020171a:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc020171e:	00c7c463          	blt	a5,a2,ffffffffc0201726 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0201722:	10060b63          	beqz	a2,ffffffffc0201838 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0201726:	000a3603          	ld	a2,0(s4)
ffffffffc020172a:	46a1                	li	a3,8
ffffffffc020172c:	8a3a                	mv	s4,a4
ffffffffc020172e:	b761                	j	ffffffffc02016b6 <vprintfmt+0x128>
            if (width < 0)
ffffffffc0201730:	fffcc793          	not	a5,s9
ffffffffc0201734:	97fd                	srai	a5,a5,0x3f
ffffffffc0201736:	00fcf7b3          	and	a5,s9,a5
ffffffffc020173a:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020173e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201740:	b56d                	j	ffffffffc02015ea <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201742:	000a3403          	ld	s0,0(s4)
ffffffffc0201746:	008a0793          	addi	a5,s4,8
ffffffffc020174a:	e43e                	sd	a5,8(sp)
ffffffffc020174c:	12040063          	beqz	s0,ffffffffc020186c <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201750:	0d905963          	blez	s9,ffffffffc0201822 <vprintfmt+0x294>
ffffffffc0201754:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201758:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc020175c:	12fd9763          	bne	s11,a5,ffffffffc020188a <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201760:	00044783          	lbu	a5,0(s0)
ffffffffc0201764:	0007851b          	sext.w	a0,a5
ffffffffc0201768:	cb9d                	beqz	a5,ffffffffc020179e <vprintfmt+0x210>
ffffffffc020176a:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020176c:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201770:	000d4563          	bltz	s10,ffffffffc020177a <vprintfmt+0x1ec>
ffffffffc0201774:	3d7d                	addiw	s10,s10,-1
ffffffffc0201776:	028d0263          	beq	s10,s0,ffffffffc020179a <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc020177a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020177c:	0c0b8d63          	beqz	s7,ffffffffc0201856 <vprintfmt+0x2c8>
ffffffffc0201780:	3781                	addiw	a5,a5,-32
ffffffffc0201782:	0cfdfa63          	bgeu	s11,a5,ffffffffc0201856 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0201786:	03f00513          	li	a0,63
ffffffffc020178a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020178c:	000a4783          	lbu	a5,0(s4)
ffffffffc0201790:	3cfd                	addiw	s9,s9,-1
ffffffffc0201792:	0a05                	addi	s4,s4,1
ffffffffc0201794:	0007851b          	sext.w	a0,a5
ffffffffc0201798:	ffe1                	bnez	a5,ffffffffc0201770 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc020179a:	01905963          	blez	s9,ffffffffc02017ac <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc020179e:	85a6                	mv	a1,s1
ffffffffc02017a0:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02017a4:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc02017a6:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02017a8:	fe0c9be3          	bnez	s9,ffffffffc020179e <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02017ac:	6a22                	ld	s4,8(sp)
ffffffffc02017ae:	bd11                	j	ffffffffc02015c2 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02017b0:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02017b2:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02017b6:	00c7c363          	blt	a5,a2,ffffffffc02017bc <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc02017ba:	ce25                	beqz	a2,ffffffffc0201832 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc02017bc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02017c0:	08044d63          	bltz	s0,ffffffffc020185a <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02017c4:	8622                	mv	a2,s0
ffffffffc02017c6:	8a5e                	mv	s4,s7
ffffffffc02017c8:	46a9                	li	a3,10
ffffffffc02017ca:	b5f5                	j	ffffffffc02016b6 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc02017cc:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017d0:	4619                	li	a2,6
            if (err < 0) {
ffffffffc02017d2:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02017d6:	8fb9                	xor	a5,a5,a4
ffffffffc02017d8:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017dc:	02d64663          	blt	a2,a3,ffffffffc0201808 <vprintfmt+0x27a>
ffffffffc02017e0:	00369713          	slli	a4,a3,0x3
ffffffffc02017e4:	00001797          	auipc	a5,0x1
ffffffffc02017e8:	16478793          	addi	a5,a5,356 # ffffffffc0202948 <error_string>
ffffffffc02017ec:	97ba                	add	a5,a5,a4
ffffffffc02017ee:	639c                	ld	a5,0(a5)
ffffffffc02017f0:	cf81                	beqz	a5,ffffffffc0201808 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02017f2:	86be                	mv	a3,a5
ffffffffc02017f4:	00001617          	auipc	a2,0x1
ffffffffc02017f8:	ec460613          	addi	a2,a2,-316 # ffffffffc02026b8 <etext+0xc16>
ffffffffc02017fc:	85a6                	mv	a1,s1
ffffffffc02017fe:	854a                	mv	a0,s2
ffffffffc0201800:	0e8000ef          	jal	ffffffffc02018e8 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201804:	0a21                	addi	s4,s4,8
ffffffffc0201806:	bb75                	j	ffffffffc02015c2 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201808:	00001617          	auipc	a2,0x1
ffffffffc020180c:	ea060613          	addi	a2,a2,-352 # ffffffffc02026a8 <etext+0xc06>
ffffffffc0201810:	85a6                	mv	a1,s1
ffffffffc0201812:	854a                	mv	a0,s2
ffffffffc0201814:	0d4000ef          	jal	ffffffffc02018e8 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201818:	0a21                	addi	s4,s4,8
ffffffffc020181a:	b365                	j	ffffffffc02015c2 <vprintfmt+0x34>
            lflag ++;
ffffffffc020181c:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020181e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201820:	b3e9                	j	ffffffffc02015ea <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201822:	00044783          	lbu	a5,0(s0)
ffffffffc0201826:	0007851b          	sext.w	a0,a5
ffffffffc020182a:	d3c9                	beqz	a5,ffffffffc02017ac <vprintfmt+0x21e>
ffffffffc020182c:	00140a13          	addi	s4,s0,1
ffffffffc0201830:	bf2d                	j	ffffffffc020176a <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0201832:	000a2403          	lw	s0,0(s4)
ffffffffc0201836:	b769                	j	ffffffffc02017c0 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0201838:	000a6603          	lwu	a2,0(s4)
ffffffffc020183c:	46a1                	li	a3,8
ffffffffc020183e:	8a3a                	mv	s4,a4
ffffffffc0201840:	bd9d                	j	ffffffffc02016b6 <vprintfmt+0x128>
ffffffffc0201842:	000a6603          	lwu	a2,0(s4)
ffffffffc0201846:	46a9                	li	a3,10
ffffffffc0201848:	8a3a                	mv	s4,a4
ffffffffc020184a:	b5b5                	j	ffffffffc02016b6 <vprintfmt+0x128>
ffffffffc020184c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201850:	46c1                	li	a3,16
ffffffffc0201852:	8a3a                	mv	s4,a4
ffffffffc0201854:	b58d                	j	ffffffffc02016b6 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0201856:	9902                	jalr	s2
ffffffffc0201858:	bf15                	j	ffffffffc020178c <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc020185a:	85a6                	mv	a1,s1
ffffffffc020185c:	02d00513          	li	a0,45
ffffffffc0201860:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201862:	40800633          	neg	a2,s0
ffffffffc0201866:	8a5e                	mv	s4,s7
ffffffffc0201868:	46a9                	li	a3,10
ffffffffc020186a:	b5b1                	j	ffffffffc02016b6 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc020186c:	01905663          	blez	s9,ffffffffc0201878 <vprintfmt+0x2ea>
ffffffffc0201870:	02d00793          	li	a5,45
ffffffffc0201874:	04fd9263          	bne	s11,a5,ffffffffc02018b8 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201878:	02800793          	li	a5,40
ffffffffc020187c:	00001a17          	auipc	s4,0x1
ffffffffc0201880:	e25a0a13          	addi	s4,s4,-475 # ffffffffc02026a1 <etext+0xbff>
ffffffffc0201884:	02800513          	li	a0,40
ffffffffc0201888:	b5cd                	j	ffffffffc020176a <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020188a:	85ea                	mv	a1,s10
ffffffffc020188c:	8522                	mv	a0,s0
ffffffffc020188e:	198000ef          	jal	ffffffffc0201a26 <strnlen>
ffffffffc0201892:	40ac8cbb          	subw	s9,s9,a0
ffffffffc0201896:	01905963          	blez	s9,ffffffffc02018a8 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc020189a:	2d81                	sext.w	s11,s11
ffffffffc020189c:	85a6                	mv	a1,s1
ffffffffc020189e:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02018a0:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc02018a2:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02018a4:	fe0c9ce3          	bnez	s9,ffffffffc020189c <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018a8:	00044783          	lbu	a5,0(s0)
ffffffffc02018ac:	0007851b          	sext.w	a0,a5
ffffffffc02018b0:	ea079de3          	bnez	a5,ffffffffc020176a <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02018b4:	6a22                	ld	s4,8(sp)
ffffffffc02018b6:	b331                	j	ffffffffc02015c2 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02018b8:	85ea                	mv	a1,s10
ffffffffc02018ba:	00001517          	auipc	a0,0x1
ffffffffc02018be:	de650513          	addi	a0,a0,-538 # ffffffffc02026a0 <etext+0xbfe>
ffffffffc02018c2:	164000ef          	jal	ffffffffc0201a26 <strnlen>
ffffffffc02018c6:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc02018ca:	00001417          	auipc	s0,0x1
ffffffffc02018ce:	dd640413          	addi	s0,s0,-554 # ffffffffc02026a0 <etext+0xbfe>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018d2:	00001a17          	auipc	s4,0x1
ffffffffc02018d6:	dcfa0a13          	addi	s4,s4,-561 # ffffffffc02026a1 <etext+0xbff>
ffffffffc02018da:	02800793          	li	a5,40
ffffffffc02018de:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02018e2:	fb904ce3          	bgtz	s9,ffffffffc020189a <vprintfmt+0x30c>
ffffffffc02018e6:	b551                	j	ffffffffc020176a <vprintfmt+0x1dc>

ffffffffc02018e8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02018e8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02018ea:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02018ee:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02018f0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02018f2:	ec06                	sd	ra,24(sp)
ffffffffc02018f4:	f83a                	sd	a4,48(sp)
ffffffffc02018f6:	fc3e                	sd	a5,56(sp)
ffffffffc02018f8:	e0c2                	sd	a6,64(sp)
ffffffffc02018fa:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02018fc:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02018fe:	c91ff0ef          	jal	ffffffffc020158e <vprintfmt>
}
ffffffffc0201902:	60e2                	ld	ra,24(sp)
ffffffffc0201904:	6161                	addi	sp,sp,80
ffffffffc0201906:	8082                	ret

ffffffffc0201908 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201908:	715d                	addi	sp,sp,-80
ffffffffc020190a:	e486                	sd	ra,72(sp)
ffffffffc020190c:	e0a2                	sd	s0,64(sp)
ffffffffc020190e:	fc26                	sd	s1,56(sp)
ffffffffc0201910:	f84a                	sd	s2,48(sp)
ffffffffc0201912:	f44e                	sd	s3,40(sp)
ffffffffc0201914:	f052                	sd	s4,32(sp)
ffffffffc0201916:	ec56                	sd	s5,24(sp)
ffffffffc0201918:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc020191a:	c901                	beqz	a0,ffffffffc020192a <readline+0x22>
ffffffffc020191c:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020191e:	00001517          	auipc	a0,0x1
ffffffffc0201922:	d9a50513          	addi	a0,a0,-614 # ffffffffc02026b8 <etext+0xc16>
ffffffffc0201926:	f8cfe0ef          	jal	ffffffffc02000b2 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc020192a:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020192c:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc020192e:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201930:	4a29                	li	s4,10
ffffffffc0201932:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc0201934:	00004b17          	auipc	s6,0x4
ffffffffc0201938:	6fcb0b13          	addi	s6,s6,1788 # ffffffffc0206030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020193c:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc0201940:	ff6fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc0201944:	00054a63          	bltz	a0,ffffffffc0201958 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201948:	00a4da63          	bge	s1,a0,ffffffffc020195c <readline+0x54>
ffffffffc020194c:	0289d263          	bge	s3,s0,ffffffffc0201970 <readline+0x68>
        c = getchar();
ffffffffc0201950:	fe6fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc0201954:	fe055ae3          	bgez	a0,ffffffffc0201948 <readline+0x40>
            return NULL;
ffffffffc0201958:	4501                	li	a0,0
ffffffffc020195a:	a091                	j	ffffffffc020199e <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020195c:	03251463          	bne	a0,s2,ffffffffc0201984 <readline+0x7c>
ffffffffc0201960:	04804963          	bgtz	s0,ffffffffc02019b2 <readline+0xaa>
        c = getchar();
ffffffffc0201964:	fd2fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc0201968:	fe0548e3          	bltz	a0,ffffffffc0201958 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020196c:	fea4d8e3          	bge	s1,a0,ffffffffc020195c <readline+0x54>
            cputchar(c);
ffffffffc0201970:	e42a                	sd	a0,8(sp)
ffffffffc0201972:	f74fe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i ++] = c;
ffffffffc0201976:	6522                	ld	a0,8(sp)
ffffffffc0201978:	008b07b3          	add	a5,s6,s0
ffffffffc020197c:	2405                	addiw	s0,s0,1
ffffffffc020197e:	00a78023          	sb	a0,0(a5)
ffffffffc0201982:	bf7d                	j	ffffffffc0201940 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201984:	01450463          	beq	a0,s4,ffffffffc020198c <readline+0x84>
ffffffffc0201988:	fb551ce3          	bne	a0,s5,ffffffffc0201940 <readline+0x38>
            cputchar(c);
ffffffffc020198c:	f5afe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i] = '\0';
ffffffffc0201990:	00004517          	auipc	a0,0x4
ffffffffc0201994:	6a050513          	addi	a0,a0,1696 # ffffffffc0206030 <buf>
ffffffffc0201998:	942a                	add	s0,s0,a0
ffffffffc020199a:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc020199e:	60a6                	ld	ra,72(sp)
ffffffffc02019a0:	6406                	ld	s0,64(sp)
ffffffffc02019a2:	74e2                	ld	s1,56(sp)
ffffffffc02019a4:	7942                	ld	s2,48(sp)
ffffffffc02019a6:	79a2                	ld	s3,40(sp)
ffffffffc02019a8:	7a02                	ld	s4,32(sp)
ffffffffc02019aa:	6ae2                	ld	s5,24(sp)
ffffffffc02019ac:	6b42                	ld	s6,16(sp)
ffffffffc02019ae:	6161                	addi	sp,sp,80
ffffffffc02019b0:	8082                	ret
            cputchar(c);
ffffffffc02019b2:	4521                	li	a0,8
ffffffffc02019b4:	f32fe0ef          	jal	ffffffffc02000e6 <cputchar>
            i --;
ffffffffc02019b8:	347d                	addiw	s0,s0,-1
ffffffffc02019ba:	b759                	j	ffffffffc0201940 <readline+0x38>

ffffffffc02019bc <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02019bc:	4781                	li	a5,0
ffffffffc02019be:	00004717          	auipc	a4,0x4
ffffffffc02019c2:	65273703          	ld	a4,1618(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02019c6:	88ba                	mv	a7,a4
ffffffffc02019c8:	852a                	mv	a0,a0
ffffffffc02019ca:	85be                	mv	a1,a5
ffffffffc02019cc:	863e                	mv	a2,a5
ffffffffc02019ce:	00000073          	ecall
ffffffffc02019d2:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02019d4:	8082                	ret

ffffffffc02019d6 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc02019d6:	4781                	li	a5,0
ffffffffc02019d8:	00005717          	auipc	a4,0x5
ffffffffc02019dc:	aa073703          	ld	a4,-1376(a4) # ffffffffc0206478 <SBI_SET_TIMER>
ffffffffc02019e0:	88ba                	mv	a7,a4
ffffffffc02019e2:	852a                	mv	a0,a0
ffffffffc02019e4:	85be                	mv	a1,a5
ffffffffc02019e6:	863e                	mv	a2,a5
ffffffffc02019e8:	00000073          	ecall
ffffffffc02019ec:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc02019ee:	8082                	ret

ffffffffc02019f0 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc02019f0:	4501                	li	a0,0
ffffffffc02019f2:	00004797          	auipc	a5,0x4
ffffffffc02019f6:	6167b783          	ld	a5,1558(a5) # ffffffffc0206008 <SBI_CONSOLE_GETCHAR>
ffffffffc02019fa:	88be                	mv	a7,a5
ffffffffc02019fc:	852a                	mv	a0,a0
ffffffffc02019fe:	85aa                	mv	a1,a0
ffffffffc0201a00:	862a                	mv	a2,a0
ffffffffc0201a02:	00000073          	ecall
ffffffffc0201a06:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201a08:	2501                	sext.w	a0,a0
ffffffffc0201a0a:	8082                	ret

ffffffffc0201a0c <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201a0c:	4781                	li	a5,0
ffffffffc0201a0e:	00004717          	auipc	a4,0x4
ffffffffc0201a12:	5f273703          	ld	a4,1522(a4) # ffffffffc0206000 <SBI_SHUTDOWN>
ffffffffc0201a16:	88ba                	mv	a7,a4
ffffffffc0201a18:	853e                	mv	a0,a5
ffffffffc0201a1a:	85be                	mv	a1,a5
ffffffffc0201a1c:	863e                	mv	a2,a5
ffffffffc0201a1e:	00000073          	ecall
ffffffffc0201a22:	87aa                	mv	a5,a0

//begin
void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
}
ffffffffc0201a24:	8082                	ret

ffffffffc0201a26 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201a26:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a28:	e589                	bnez	a1,ffffffffc0201a32 <strnlen+0xc>
ffffffffc0201a2a:	a811                	j	ffffffffc0201a3e <strnlen+0x18>
        cnt ++;
ffffffffc0201a2c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a2e:	00f58863          	beq	a1,a5,ffffffffc0201a3e <strnlen+0x18>
ffffffffc0201a32:	00f50733          	add	a4,a0,a5
ffffffffc0201a36:	00074703          	lbu	a4,0(a4)
ffffffffc0201a3a:	fb6d                	bnez	a4,ffffffffc0201a2c <strnlen+0x6>
ffffffffc0201a3c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201a3e:	852e                	mv	a0,a1
ffffffffc0201a40:	8082                	ret

ffffffffc0201a42 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a42:	00054783          	lbu	a5,0(a0)
ffffffffc0201a46:	e791                	bnez	a5,ffffffffc0201a52 <strcmp+0x10>
ffffffffc0201a48:	a02d                	j	ffffffffc0201a72 <strcmp+0x30>
ffffffffc0201a4a:	00054783          	lbu	a5,0(a0)
ffffffffc0201a4e:	cf89                	beqz	a5,ffffffffc0201a68 <strcmp+0x26>
ffffffffc0201a50:	85b6                	mv	a1,a3
ffffffffc0201a52:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201a56:	0505                	addi	a0,a0,1
ffffffffc0201a58:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a5c:	fef707e3          	beq	a4,a5,ffffffffc0201a4a <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a60:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201a64:	9d19                	subw	a0,a0,a4
ffffffffc0201a66:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a68:	0015c703          	lbu	a4,1(a1)
ffffffffc0201a6c:	4501                	li	a0,0
}
ffffffffc0201a6e:	9d19                	subw	a0,a0,a4
ffffffffc0201a70:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a72:	0005c703          	lbu	a4,0(a1)
ffffffffc0201a76:	4501                	li	a0,0
ffffffffc0201a78:	b7f5                	j	ffffffffc0201a64 <strcmp+0x22>

ffffffffc0201a7a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201a7a:	00054783          	lbu	a5,0(a0)
ffffffffc0201a7e:	c799                	beqz	a5,ffffffffc0201a8c <strchr+0x12>
        if (*s == c) {
ffffffffc0201a80:	00f58763          	beq	a1,a5,ffffffffc0201a8e <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201a84:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201a88:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201a8a:	fbfd                	bnez	a5,ffffffffc0201a80 <strchr+0x6>
    }
    return NULL;
ffffffffc0201a8c:	4501                	li	a0,0
}
ffffffffc0201a8e:	8082                	ret

ffffffffc0201a90 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201a90:	ca01                	beqz	a2,ffffffffc0201aa0 <memset+0x10>
ffffffffc0201a92:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201a94:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201a96:	0785                	addi	a5,a5,1
ffffffffc0201a98:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201a9c:	fef61de3          	bne	a2,a5,ffffffffc0201a96 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201aa0:	8082                	ret
