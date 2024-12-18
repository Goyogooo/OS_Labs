
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc0200024:	c020b137          	lui	sp,0xc020b

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

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00092517          	auipc	a0,0x92
ffffffffc0200036:	78650513          	addi	a0,a0,1926 # ffffffffc02927b8 <buf>
ffffffffc020003a:	0009e617          	auipc	a2,0x9e
ffffffffc020003e:	cde60613          	addi	a2,a2,-802 # ffffffffc029dd18 <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16 # ffffffffc020aff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	748060ef          	jal	ffffffffc0206792 <memset>
    cons_init();                // init the console
ffffffffc020004e:	524000ef          	jal	ffffffffc0200572 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00006597          	auipc	a1,0x6
ffffffffc0200056:	76e58593          	addi	a1,a1,1902 # ffffffffc02067c0 <etext+0x4>
ffffffffc020005a:	00006517          	auipc	a0,0x6
ffffffffc020005e:	78650513          	addi	a0,a0,1926 # ffffffffc02067e0 <etext+0x24>
ffffffffc0200062:	11e000ef          	jal	ffffffffc0200180 <cprintf>

    print_kerninfo();
ffffffffc0200066:	1ae000ef          	jal	ffffffffc0200214 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	500020ef          	jal	ffffffffc020256a <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	5d8000ef          	jal	ffffffffc0200646 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5d6000ef          	jal	ffffffffc0200648 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	454040ef          	jal	ffffffffc02044ca <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	661050ef          	jal	ffffffffc0205eda <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	566000ef          	jal	ffffffffc02005e4 <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	35a030ef          	jal	ffffffffc02033dc <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	49a000ef          	jal	ffffffffc0200520 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	5b0000ef          	jal	ffffffffc020063a <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc020008e:	7e7050ef          	jal	ffffffffc0206074 <cpu_idle>

ffffffffc0200092 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200092:	715d                	addi	sp,sp,-80
ffffffffc0200094:	e486                	sd	ra,72(sp)
ffffffffc0200096:	e0a2                	sd	s0,64(sp)
ffffffffc0200098:	fc26                	sd	s1,56(sp)
ffffffffc020009a:	f84a                	sd	s2,48(sp)
ffffffffc020009c:	f44e                	sd	s3,40(sp)
ffffffffc020009e:	f052                	sd	s4,32(sp)
ffffffffc02000a0:	ec56                	sd	s5,24(sp)
ffffffffc02000a2:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc02000a4:	c901                	beqz	a0,ffffffffc02000b4 <readline+0x22>
ffffffffc02000a6:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000a8:	00006517          	auipc	a0,0x6
ffffffffc02000ac:	74050513          	addi	a0,a0,1856 # ffffffffc02067e8 <etext+0x2c>
ffffffffc02000b0:	0d0000ef          	jal	ffffffffc0200180 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000b4:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000b6:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000b8:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ba:	4a29                	li	s4,10
ffffffffc02000bc:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc02000be:	00092b17          	auipc	s6,0x92
ffffffffc02000c2:	6fab0b13          	addi	s6,s6,1786 # ffffffffc02927b8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c6:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc02000ca:	13a000ef          	jal	ffffffffc0200204 <getchar>
        if (c < 0) {
ffffffffc02000ce:	00054a63          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d2:	00a4da63          	bge	s1,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000d6:	0289d263          	bge	s3,s0,ffffffffc02000fa <readline+0x68>
        c = getchar();
ffffffffc02000da:	12a000ef          	jal	ffffffffc0200204 <getchar>
        if (c < 0) {
ffffffffc02000de:	fe055ae3          	bgez	a0,ffffffffc02000d2 <readline+0x40>
            return NULL;
ffffffffc02000e2:	4501                	li	a0,0
ffffffffc02000e4:	a091                	j	ffffffffc0200128 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000e6:	03251463          	bne	a0,s2,ffffffffc020010e <readline+0x7c>
ffffffffc02000ea:	04804963          	bgtz	s0,ffffffffc020013c <readline+0xaa>
        c = getchar();
ffffffffc02000ee:	116000ef          	jal	ffffffffc0200204 <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe0548e3          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000f6:	fea4d8e3          	bge	s1,a0,ffffffffc02000e6 <readline+0x54>
            cputchar(c);
ffffffffc02000fa:	e42a                	sd	a0,8(sp)
ffffffffc02000fc:	0b8000ef          	jal	ffffffffc02001b4 <cputchar>
            buf[i ++] = c;
ffffffffc0200100:	6522                	ld	a0,8(sp)
ffffffffc0200102:	008b07b3          	add	a5,s6,s0
ffffffffc0200106:	2405                	addiw	s0,s0,1
ffffffffc0200108:	00a78023          	sb	a0,0(a5)
ffffffffc020010c:	bf7d                	j	ffffffffc02000ca <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020010e:	01450463          	beq	a0,s4,ffffffffc0200116 <readline+0x84>
ffffffffc0200112:	fb551ce3          	bne	a0,s5,ffffffffc02000ca <readline+0x38>
            cputchar(c);
ffffffffc0200116:	09e000ef          	jal	ffffffffc02001b4 <cputchar>
            buf[i] = '\0';
ffffffffc020011a:	00092517          	auipc	a0,0x92
ffffffffc020011e:	69e50513          	addi	a0,a0,1694 # ffffffffc02927b8 <buf>
ffffffffc0200122:	942a                	add	s0,s0,a0
ffffffffc0200124:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0200128:	60a6                	ld	ra,72(sp)
ffffffffc020012a:	6406                	ld	s0,64(sp)
ffffffffc020012c:	74e2                	ld	s1,56(sp)
ffffffffc020012e:	7942                	ld	s2,48(sp)
ffffffffc0200130:	79a2                	ld	s3,40(sp)
ffffffffc0200132:	7a02                	ld	s4,32(sp)
ffffffffc0200134:	6ae2                	ld	s5,24(sp)
ffffffffc0200136:	6b42                	ld	s6,16(sp)
ffffffffc0200138:	6161                	addi	sp,sp,80
ffffffffc020013a:	8082                	ret
            cputchar(c);
ffffffffc020013c:	4521                	li	a0,8
ffffffffc020013e:	076000ef          	jal	ffffffffc02001b4 <cputchar>
            i --;
ffffffffc0200142:	347d                	addiw	s0,s0,-1
ffffffffc0200144:	b759                	j	ffffffffc02000ca <readline+0x38>

ffffffffc0200146 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200146:	1141                	addi	sp,sp,-16
ffffffffc0200148:	e022                	sd	s0,0(sp)
ffffffffc020014a:	e406                	sd	ra,8(sp)
ffffffffc020014c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020014e:	426000ef          	jal	ffffffffc0200574 <cons_putc>
    (*cnt) ++;
ffffffffc0200152:	401c                	lw	a5,0(s0)
}
ffffffffc0200154:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200156:	2785                	addiw	a5,a5,1
ffffffffc0200158:	c01c                	sw	a5,0(s0)
}
ffffffffc020015a:	6402                	ld	s0,0(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200160:	1101                	addi	sp,sp,-32
ffffffffc0200162:	862a                	mv	a2,a0
ffffffffc0200164:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200166:	00000517          	auipc	a0,0x0
ffffffffc020016a:	fe050513          	addi	a0,a0,-32 # ffffffffc0200146 <cputch>
ffffffffc020016e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200172:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200174:	20e060ef          	jal	ffffffffc0206382 <vprintfmt>
    return cnt;
}
ffffffffc0200178:	60e2                	ld	ra,24(sp)
ffffffffc020017a:	4532                	lw	a0,12(sp)
ffffffffc020017c:	6105                	addi	sp,sp,32
ffffffffc020017e:	8082                	ret

ffffffffc0200180 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200180:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200182:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200186:	f42e                	sd	a1,40(sp)
ffffffffc0200188:	f832                	sd	a2,48(sp)
ffffffffc020018a:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020018c:	862a                	mv	a2,a0
ffffffffc020018e:	004c                	addi	a1,sp,4
ffffffffc0200190:	00000517          	auipc	a0,0x0
ffffffffc0200194:	fb650513          	addi	a0,a0,-74 # ffffffffc0200146 <cputch>
ffffffffc0200198:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc020019a:	ec06                	sd	ra,24(sp)
ffffffffc020019c:	e0ba                	sd	a4,64(sp)
ffffffffc020019e:	e4be                	sd	a5,72(sp)
ffffffffc02001a0:	e8c2                	sd	a6,80(sp)
ffffffffc02001a2:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001a4:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001a6:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001a8:	1da060ef          	jal	ffffffffc0206382 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ac:	60e2                	ld	ra,24(sp)
ffffffffc02001ae:	4512                	lw	a0,4(sp)
ffffffffc02001b0:	6125                	addi	sp,sp,96
ffffffffc02001b2:	8082                	ret

ffffffffc02001b4 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001b4:	a6c1                	j	ffffffffc0200574 <cons_putc>

ffffffffc02001b6 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02001b6:	1101                	addi	sp,sp,-32
ffffffffc02001b8:	ec06                	sd	ra,24(sp)
ffffffffc02001ba:	e822                	sd	s0,16(sp)
ffffffffc02001bc:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	00054503          	lbu	a0,0(a0)
ffffffffc02001c2:	c905                	beqz	a0,ffffffffc02001f2 <cputs+0x3c>
ffffffffc02001c4:	e426                	sd	s1,8(sp)
ffffffffc02001c6:	00178493          	addi	s1,a5,1
ffffffffc02001ca:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc02001cc:	3a8000ef          	jal	ffffffffc0200574 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001d0:	00044503          	lbu	a0,0(s0)
ffffffffc02001d4:	87a2                	mv	a5,s0
ffffffffc02001d6:	0405                	addi	s0,s0,1
ffffffffc02001d8:	f975                	bnez	a0,ffffffffc02001cc <cputs+0x16>
    (*cnt) ++;
ffffffffc02001da:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc02001dc:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001de:	0027841b          	addiw	s0,a5,2
ffffffffc02001e2:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001e4:	390000ef          	jal	ffffffffc0200574 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001e8:	60e2                	ld	ra,24(sp)
ffffffffc02001ea:	8522                	mv	a0,s0
ffffffffc02001ec:	6442                	ld	s0,16(sp)
ffffffffc02001ee:	6105                	addi	sp,sp,32
ffffffffc02001f0:	8082                	ret
    cons_putc(c);
ffffffffc02001f2:	4529                	li	a0,10
ffffffffc02001f4:	380000ef          	jal	ffffffffc0200574 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001f8:	4405                	li	s0,1
}
ffffffffc02001fa:	60e2                	ld	ra,24(sp)
ffffffffc02001fc:	8522                	mv	a0,s0
ffffffffc02001fe:	6442                	ld	s0,16(sp)
ffffffffc0200200:	6105                	addi	sp,sp,32
ffffffffc0200202:	8082                	ret

ffffffffc0200204 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200204:	1141                	addi	sp,sp,-16
ffffffffc0200206:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200208:	3a0000ef          	jal	ffffffffc02005a8 <cons_getc>
ffffffffc020020c:	dd75                	beqz	a0,ffffffffc0200208 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020020e:	60a2                	ld	ra,8(sp)
ffffffffc0200210:	0141                	addi	sp,sp,16
ffffffffc0200212:	8082                	ret

ffffffffc0200214 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200214:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200216:	00006517          	auipc	a0,0x6
ffffffffc020021a:	5da50513          	addi	a0,a0,1498 # ffffffffc02067f0 <etext+0x34>
void print_kerninfo(void) {
ffffffffc020021e:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200220:	f61ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200224:	00000597          	auipc	a1,0x0
ffffffffc0200228:	e0e58593          	addi	a1,a1,-498 # ffffffffc0200032 <kern_init>
ffffffffc020022c:	00006517          	auipc	a0,0x6
ffffffffc0200230:	5e450513          	addi	a0,a0,1508 # ffffffffc0206810 <etext+0x54>
ffffffffc0200234:	f4dff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200238:	00006597          	auipc	a1,0x6
ffffffffc020023c:	58458593          	addi	a1,a1,1412 # ffffffffc02067bc <etext>
ffffffffc0200240:	00006517          	auipc	a0,0x6
ffffffffc0200244:	5f050513          	addi	a0,a0,1520 # ffffffffc0206830 <etext+0x74>
ffffffffc0200248:	f39ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020024c:	00092597          	auipc	a1,0x92
ffffffffc0200250:	56c58593          	addi	a1,a1,1388 # ffffffffc02927b8 <buf>
ffffffffc0200254:	00006517          	auipc	a0,0x6
ffffffffc0200258:	5fc50513          	addi	a0,a0,1532 # ffffffffc0206850 <etext+0x94>
ffffffffc020025c:	f25ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200260:	0009e597          	auipc	a1,0x9e
ffffffffc0200264:	ab858593          	addi	a1,a1,-1352 # ffffffffc029dd18 <end>
ffffffffc0200268:	00006517          	auipc	a0,0x6
ffffffffc020026c:	60850513          	addi	a0,a0,1544 # ffffffffc0206870 <etext+0xb4>
ffffffffc0200270:	f11ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200274:	0009e797          	auipc	a5,0x9e
ffffffffc0200278:	ea378793          	addi	a5,a5,-349 # ffffffffc029e117 <end+0x3ff>
ffffffffc020027c:	00000717          	auipc	a4,0x0
ffffffffc0200280:	db670713          	addi	a4,a4,-586 # ffffffffc0200032 <kern_init>
ffffffffc0200284:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200286:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020028a:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020028c:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200290:	95be                	add	a1,a1,a5
ffffffffc0200292:	85a9                	srai	a1,a1,0xa
ffffffffc0200294:	00006517          	auipc	a0,0x6
ffffffffc0200298:	5fc50513          	addi	a0,a0,1532 # ffffffffc0206890 <etext+0xd4>
}
ffffffffc020029c:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	b5cd                	j	ffffffffc0200180 <cprintf>

ffffffffc02002a0 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002a0:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002a2:	00006617          	auipc	a2,0x6
ffffffffc02002a6:	61e60613          	addi	a2,a2,1566 # ffffffffc02068c0 <etext+0x104>
ffffffffc02002aa:	04d00593          	li	a1,77
ffffffffc02002ae:	00006517          	auipc	a0,0x6
ffffffffc02002b2:	62a50513          	addi	a0,a0,1578 # ffffffffc02068d8 <etext+0x11c>
void print_stackframe(void) {
ffffffffc02002b6:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002b8:	1bc000ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02002bc <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002bc:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002be:	00006617          	auipc	a2,0x6
ffffffffc02002c2:	63260613          	addi	a2,a2,1586 # ffffffffc02068f0 <etext+0x134>
ffffffffc02002c6:	00006597          	auipc	a1,0x6
ffffffffc02002ca:	64a58593          	addi	a1,a1,1610 # ffffffffc0206910 <etext+0x154>
ffffffffc02002ce:	00006517          	auipc	a0,0x6
ffffffffc02002d2:	64a50513          	addi	a0,a0,1610 # ffffffffc0206918 <etext+0x15c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002d6:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002d8:	ea9ff0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc02002dc:	00006617          	auipc	a2,0x6
ffffffffc02002e0:	64c60613          	addi	a2,a2,1612 # ffffffffc0206928 <etext+0x16c>
ffffffffc02002e4:	00006597          	auipc	a1,0x6
ffffffffc02002e8:	66c58593          	addi	a1,a1,1644 # ffffffffc0206950 <etext+0x194>
ffffffffc02002ec:	00006517          	auipc	a0,0x6
ffffffffc02002f0:	62c50513          	addi	a0,a0,1580 # ffffffffc0206918 <etext+0x15c>
ffffffffc02002f4:	e8dff0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc02002f8:	00006617          	auipc	a2,0x6
ffffffffc02002fc:	66860613          	addi	a2,a2,1640 # ffffffffc0206960 <etext+0x1a4>
ffffffffc0200300:	00006597          	auipc	a1,0x6
ffffffffc0200304:	68058593          	addi	a1,a1,1664 # ffffffffc0206980 <etext+0x1c4>
ffffffffc0200308:	00006517          	auipc	a0,0x6
ffffffffc020030c:	61050513          	addi	a0,a0,1552 # ffffffffc0206918 <etext+0x15c>
ffffffffc0200310:	e71ff0ef          	jal	ffffffffc0200180 <cprintf>
    }
    return 0;
}
ffffffffc0200314:	60a2                	ld	ra,8(sp)
ffffffffc0200316:	4501                	li	a0,0
ffffffffc0200318:	0141                	addi	sp,sp,16
ffffffffc020031a:	8082                	ret

ffffffffc020031c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020031c:	1141                	addi	sp,sp,-16
ffffffffc020031e:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200320:	ef5ff0ef          	jal	ffffffffc0200214 <print_kerninfo>
    return 0;
}
ffffffffc0200324:	60a2                	ld	ra,8(sp)
ffffffffc0200326:	4501                	li	a0,0
ffffffffc0200328:	0141                	addi	sp,sp,16
ffffffffc020032a:	8082                	ret

ffffffffc020032c <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032c:	1141                	addi	sp,sp,-16
ffffffffc020032e:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200330:	f71ff0ef          	jal	ffffffffc02002a0 <print_stackframe>
    return 0;
}
ffffffffc0200334:	60a2                	ld	ra,8(sp)
ffffffffc0200336:	4501                	li	a0,0
ffffffffc0200338:	0141                	addi	sp,sp,16
ffffffffc020033a:	8082                	ret

ffffffffc020033c <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020033c:	7115                	addi	sp,sp,-224
ffffffffc020033e:	f15a                	sd	s6,160(sp)
ffffffffc0200340:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200342:	00006517          	auipc	a0,0x6
ffffffffc0200346:	64e50513          	addi	a0,a0,1614 # ffffffffc0206990 <etext+0x1d4>
kmonitor(struct trapframe *tf) {
ffffffffc020034a:	ed86                	sd	ra,216(sp)
ffffffffc020034c:	e9a2                	sd	s0,208(sp)
ffffffffc020034e:	e5a6                	sd	s1,200(sp)
ffffffffc0200350:	e1ca                	sd	s2,192(sp)
ffffffffc0200352:	fd4e                	sd	s3,184(sp)
ffffffffc0200354:	f952                	sd	s4,176(sp)
ffffffffc0200356:	f556                	sd	s5,168(sp)
ffffffffc0200358:	ed5e                	sd	s7,152(sp)
ffffffffc020035a:	e962                	sd	s8,144(sp)
ffffffffc020035c:	e566                	sd	s9,136(sp)
ffffffffc020035e:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200360:	e21ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200364:	00006517          	auipc	a0,0x6
ffffffffc0200368:	65450513          	addi	a0,a0,1620 # ffffffffc02069b8 <etext+0x1fc>
ffffffffc020036c:	e15ff0ef          	jal	ffffffffc0200180 <cprintf>
    if (tf != NULL) {
ffffffffc0200370:	000b0563          	beqz	s6,ffffffffc020037a <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200374:	855a                	mv	a0,s6
ffffffffc0200376:	4ba000ef          	jal	ffffffffc0200830 <print_trapframe>
ffffffffc020037a:	00008c17          	auipc	s8,0x8
ffffffffc020037e:	726c0c13          	addi	s8,s8,1830 # ffffffffc0208aa0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200382:	00006917          	auipc	s2,0x6
ffffffffc0200386:	65e90913          	addi	s2,s2,1630 # ffffffffc02069e0 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	00006497          	auipc	s1,0x6
ffffffffc020038e:	65e48493          	addi	s1,s1,1630 # ffffffffc02069e8 <etext+0x22c>
        if (argc == MAXARGS - 1) {
ffffffffc0200392:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200394:	00006a97          	auipc	s5,0x6
ffffffffc0200398:	65ca8a93          	addi	s5,s5,1628 # ffffffffc02069f0 <etext+0x234>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039c:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039e:	00006b97          	auipc	s7,0x6
ffffffffc02003a2:	672b8b93          	addi	s7,s7,1650 # ffffffffc0206a10 <etext+0x254>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003a6:	854a                	mv	a0,s2
ffffffffc02003a8:	cebff0ef          	jal	ffffffffc0200092 <readline>
ffffffffc02003ac:	842a                	mv	s0,a0
ffffffffc02003ae:	dd65                	beqz	a0,ffffffffc02003a6 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b0:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003b4:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b6:	e59d                	bnez	a1,ffffffffc02003e4 <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc02003b8:	fe0c87e3          	beqz	s9,ffffffffc02003a6 <kmonitor+0x6a>
ffffffffc02003bc:	00008d17          	auipc	s10,0x8
ffffffffc02003c0:	6e4d0d13          	addi	s10,s10,1764 # ffffffffc0208aa0 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003c4:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	000d3503          	ld	a0,0(s10)
ffffffffc02003cc:	378060ef          	jal	ffffffffc0206744 <strcmp>
ffffffffc02003d0:	c53d                	beqz	a0,ffffffffc020043e <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d2:	2405                	addiw	s0,s0,1
ffffffffc02003d4:	0d61                	addi	s10,s10,24
ffffffffc02003d6:	ff4418e3          	bne	s0,s4,ffffffffc02003c6 <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003da:	6582                	ld	a1,0(sp)
ffffffffc02003dc:	855e                	mv	a0,s7
ffffffffc02003de:	da3ff0ef          	jal	ffffffffc0200180 <cprintf>
    return 0;
ffffffffc02003e2:	b7d1                	j	ffffffffc02003a6 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003e4:	8526                	mv	a0,s1
ffffffffc02003e6:	396060ef          	jal	ffffffffc020677c <strchr>
ffffffffc02003ea:	c901                	beqz	a0,ffffffffc02003fa <kmonitor+0xbe>
ffffffffc02003ec:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003f0:	00040023          	sb	zero,0(s0)
ffffffffc02003f4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f6:	d1e9                	beqz	a1,ffffffffc02003b8 <kmonitor+0x7c>
ffffffffc02003f8:	b7f5                	j	ffffffffc02003e4 <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc02003fa:	00044783          	lbu	a5,0(s0)
ffffffffc02003fe:	dfcd                	beqz	a5,ffffffffc02003b8 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200400:	033c8a63          	beq	s9,s3,ffffffffc0200434 <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc0200404:	003c9793          	slli	a5,s9,0x3
ffffffffc0200408:	08078793          	addi	a5,a5,128
ffffffffc020040c:	978a                	add	a5,a5,sp
ffffffffc020040e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200412:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200416:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200418:	e591                	bnez	a1,ffffffffc0200424 <kmonitor+0xe8>
ffffffffc020041a:	bf79                	j	ffffffffc02003b8 <kmonitor+0x7c>
ffffffffc020041c:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200420:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200422:	d9d9                	beqz	a1,ffffffffc02003b8 <kmonitor+0x7c>
ffffffffc0200424:	8526                	mv	a0,s1
ffffffffc0200426:	356060ef          	jal	ffffffffc020677c <strchr>
ffffffffc020042a:	d96d                	beqz	a0,ffffffffc020041c <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042c:	00044583          	lbu	a1,0(s0)
ffffffffc0200430:	d5c1                	beqz	a1,ffffffffc02003b8 <kmonitor+0x7c>
ffffffffc0200432:	bf4d                	j	ffffffffc02003e4 <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200434:	45c1                	li	a1,16
ffffffffc0200436:	8556                	mv	a0,s5
ffffffffc0200438:	d49ff0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc020043c:	b7e1                	j	ffffffffc0200404 <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020043e:	00141793          	slli	a5,s0,0x1
ffffffffc0200442:	97a2                	add	a5,a5,s0
ffffffffc0200444:	078e                	slli	a5,a5,0x3
ffffffffc0200446:	97e2                	add	a5,a5,s8
ffffffffc0200448:	6b9c                	ld	a5,16(a5)
ffffffffc020044a:	865a                	mv	a2,s6
ffffffffc020044c:	002c                	addi	a1,sp,8
ffffffffc020044e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200452:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200454:	f40559e3          	bgez	a0,ffffffffc02003a6 <kmonitor+0x6a>
}
ffffffffc0200458:	60ee                	ld	ra,216(sp)
ffffffffc020045a:	644e                	ld	s0,208(sp)
ffffffffc020045c:	64ae                	ld	s1,200(sp)
ffffffffc020045e:	690e                	ld	s2,192(sp)
ffffffffc0200460:	79ea                	ld	s3,184(sp)
ffffffffc0200462:	7a4a                	ld	s4,176(sp)
ffffffffc0200464:	7aaa                	ld	s5,168(sp)
ffffffffc0200466:	7b0a                	ld	s6,160(sp)
ffffffffc0200468:	6bea                	ld	s7,152(sp)
ffffffffc020046a:	6c4a                	ld	s8,144(sp)
ffffffffc020046c:	6caa                	ld	s9,136(sp)
ffffffffc020046e:	6d0a                	ld	s10,128(sp)
ffffffffc0200470:	612d                	addi	sp,sp,224
ffffffffc0200472:	8082                	ret

ffffffffc0200474 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200474:	0009e317          	auipc	t1,0x9e
ffffffffc0200478:	80c30313          	addi	t1,t1,-2036 # ffffffffc029dc80 <is_panic>
ffffffffc020047c:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200480:	715d                	addi	sp,sp,-80
ffffffffc0200482:	ec06                	sd	ra,24(sp)
ffffffffc0200484:	f436                	sd	a3,40(sp)
ffffffffc0200486:	f83a                	sd	a4,48(sp)
ffffffffc0200488:	fc3e                	sd	a5,56(sp)
ffffffffc020048a:	e0c2                	sd	a6,64(sp)
ffffffffc020048c:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020048e:	020e1c63          	bnez	t3,ffffffffc02004c6 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200492:	4785                	li	a5,1
ffffffffc0200494:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200498:	e822                	sd	s0,16(sp)
ffffffffc020049a:	103c                	addi	a5,sp,40
ffffffffc020049c:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020049e:	862e                	mv	a2,a1
ffffffffc02004a0:	85aa                	mv	a1,a0
ffffffffc02004a2:	00006517          	auipc	a0,0x6
ffffffffc02004a6:	58650513          	addi	a0,a0,1414 # ffffffffc0206a28 <etext+0x26c>
    va_start(ap, fmt);
ffffffffc02004aa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004ac:	cd5ff0ef          	jal	ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004b0:	65a2                	ld	a1,8(sp)
ffffffffc02004b2:	8522                	mv	a0,s0
ffffffffc02004b4:	cadff0ef          	jal	ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc02004b8:	00006517          	auipc	a0,0x6
ffffffffc02004bc:	59050513          	addi	a0,a0,1424 # ffffffffc0206a48 <etext+0x28c>
ffffffffc02004c0:	cc1ff0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc02004c4:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004c6:	4501                	li	a0,0
ffffffffc02004c8:	4581                	li	a1,0
ffffffffc02004ca:	4601                	li	a2,0
ffffffffc02004cc:	48a1                	li	a7,8
ffffffffc02004ce:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004d2:	16e000ef          	jal	ffffffffc0200640 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004d6:	4501                	li	a0,0
ffffffffc02004d8:	e65ff0ef          	jal	ffffffffc020033c <kmonitor>
    while (1) {
ffffffffc02004dc:	bfed                	j	ffffffffc02004d6 <__panic+0x62>

ffffffffc02004de <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004de:	715d                	addi	sp,sp,-80
ffffffffc02004e0:	e822                	sd	s0,16(sp)
ffffffffc02004e2:	fc3e                	sd	a5,56(sp)
ffffffffc02004e4:	8432                	mv	s0,a2
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004e6:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004e8:	862e                	mv	a2,a1
ffffffffc02004ea:	85aa                	mv	a1,a0
ffffffffc02004ec:	00006517          	auipc	a0,0x6
ffffffffc02004f0:	56450513          	addi	a0,a0,1380 # ffffffffc0206a50 <etext+0x294>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004f4:	ec06                	sd	ra,24(sp)
ffffffffc02004f6:	f436                	sd	a3,40(sp)
ffffffffc02004f8:	f83a                	sd	a4,48(sp)
ffffffffc02004fa:	e0c2                	sd	a6,64(sp)
ffffffffc02004fc:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004fe:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200500:	c81ff0ef          	jal	ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200504:	65a2                	ld	a1,8(sp)
ffffffffc0200506:	8522                	mv	a0,s0
ffffffffc0200508:	c59ff0ef          	jal	ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc020050c:	00006517          	auipc	a0,0x6
ffffffffc0200510:	53c50513          	addi	a0,a0,1340 # ffffffffc0206a48 <etext+0x28c>
ffffffffc0200514:	c6dff0ef          	jal	ffffffffc0200180 <cprintf>
    va_end(ap);
}
ffffffffc0200518:	60e2                	ld	ra,24(sp)
ffffffffc020051a:	6442                	ld	s0,16(sp)
ffffffffc020051c:	6161                	addi	sp,sp,80
ffffffffc020051e:	8082                	ret

ffffffffc0200520 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200520:	67e1                	lui	a5,0x18
ffffffffc0200522:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xeb38>
ffffffffc0200526:	0009d717          	auipc	a4,0x9d
ffffffffc020052a:	76f73123          	sd	a5,1890(a4) # ffffffffc029dc88 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020052e:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200532:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200534:	953e                	add	a0,a0,a5
ffffffffc0200536:	4601                	li	a2,0
ffffffffc0200538:	4881                	li	a7,0
ffffffffc020053a:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc020053e:	02000793          	li	a5,32
ffffffffc0200542:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200546:	00006517          	auipc	a0,0x6
ffffffffc020054a:	52a50513          	addi	a0,a0,1322 # ffffffffc0206a70 <etext+0x2b4>
    ticks = 0;
ffffffffc020054e:	0009d797          	auipc	a5,0x9d
ffffffffc0200552:	7407b123          	sd	zero,1858(a5) # ffffffffc029dc90 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200556:	b12d                	j	ffffffffc0200180 <cprintf>

ffffffffc0200558 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200558:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020055c:	0009d797          	auipc	a5,0x9d
ffffffffc0200560:	72c7b783          	ld	a5,1836(a5) # ffffffffc029dc88 <timebase>
ffffffffc0200564:	953e                	add	a0,a0,a5
ffffffffc0200566:	4581                	li	a1,0
ffffffffc0200568:	4601                	li	a2,0
ffffffffc020056a:	4881                	li	a7,0
ffffffffc020056c:	00000073          	ecall
ffffffffc0200570:	8082                	ret

ffffffffc0200572 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200572:	8082                	ret

ffffffffc0200574 <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200574:	100027f3          	csrr	a5,sstatus
ffffffffc0200578:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020057a:	0ff57513          	zext.b	a0,a0
ffffffffc020057e:	e799                	bnez	a5,ffffffffc020058c <cons_putc+0x18>
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4885                	li	a7,1
ffffffffc0200586:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc020058a:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc020058c:	1101                	addi	sp,sp,-32
ffffffffc020058e:	ec06                	sd	ra,24(sp)
ffffffffc0200590:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200592:	0ae000ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc0200596:	6522                	ld	a0,8(sp)
ffffffffc0200598:	4581                	li	a1,0
ffffffffc020059a:	4601                	li	a2,0
ffffffffc020059c:	4885                	li	a7,1
ffffffffc020059e:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005a2:	60e2                	ld	ra,24(sp)
ffffffffc02005a4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02005a6:	a851                	j	ffffffffc020063a <intr_enable>

ffffffffc02005a8 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005a8:	100027f3          	csrr	a5,sstatus
ffffffffc02005ac:	8b89                	andi	a5,a5,2
ffffffffc02005ae:	eb89                	bnez	a5,ffffffffc02005c0 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005b0:	4501                	li	a0,0
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4889                	li	a7,2
ffffffffc02005b8:	00000073          	ecall
ffffffffc02005bc:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005be:	8082                	ret
int cons_getc(void) {
ffffffffc02005c0:	1101                	addi	sp,sp,-32
ffffffffc02005c2:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005c4:	07c000ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc02005c8:	4501                	li	a0,0
ffffffffc02005ca:	4581                	li	a1,0
ffffffffc02005cc:	4601                	li	a2,0
ffffffffc02005ce:	4889                	li	a7,2
ffffffffc02005d0:	00000073          	ecall
ffffffffc02005d4:	2501                	sext.w	a0,a0
ffffffffc02005d6:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005d8:	062000ef          	jal	ffffffffc020063a <intr_enable>
}
ffffffffc02005dc:	60e2                	ld	ra,24(sp)
ffffffffc02005de:	6522                	ld	a0,8(sp)
ffffffffc02005e0:	6105                	addi	sp,sp,32
ffffffffc02005e2:	8082                	ret

ffffffffc02005e4 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02005e4:	8082                	ret

ffffffffc02005e6 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02005e6:	00253513          	sltiu	a0,a0,2
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02005ec:	03800513          	li	a0,56
ffffffffc02005f0:	8082                	ret

ffffffffc02005f2 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02005f2:	00092797          	auipc	a5,0x92
ffffffffc02005f6:	5c678793          	addi	a5,a5,1478 # ffffffffc0292bb8 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc02005fa:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02005fe:	1141                	addi	sp,sp,-16
ffffffffc0200600:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200602:	95be                	add	a1,a1,a5
ffffffffc0200604:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc0200608:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020060a:	19a060ef          	jal	ffffffffc02067a4 <memcpy>
    return 0;
}
ffffffffc020060e:	60a2                	ld	ra,8(sp)
ffffffffc0200610:	4501                	li	a0,0
ffffffffc0200612:	0141                	addi	sp,sp,16
ffffffffc0200614:	8082                	ret

ffffffffc0200616 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc0200616:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020061a:	00092517          	auipc	a0,0x92
ffffffffc020061e:	59e50513          	addi	a0,a0,1438 # ffffffffc0292bb8 <ide>
                   size_t nsecs) {
ffffffffc0200622:	1141                	addi	sp,sp,-16
ffffffffc0200624:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200626:	953e                	add	a0,a0,a5
ffffffffc0200628:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc020062c:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020062e:	176060ef          	jal	ffffffffc02067a4 <memcpy>
    return 0;
}
ffffffffc0200632:	60a2                	ld	ra,8(sp)
ffffffffc0200634:	4501                	li	a0,0
ffffffffc0200636:	0141                	addi	sp,sp,16
ffffffffc0200638:	8082                	ret

ffffffffc020063a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020063a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020063e:	8082                	ret

ffffffffc0200640 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200640:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200644:	8082                	ret

ffffffffc0200646 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200646:	8082                	ret

ffffffffc0200648 <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200648:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020064c:	00000797          	auipc	a5,0x0
ffffffffc0200650:	64478793          	addi	a5,a5,1604 # ffffffffc0200c90 <__alltraps>
ffffffffc0200654:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200658:	000407b7          	lui	a5,0x40
ffffffffc020065c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200660:	8082                	ret

ffffffffc0200662 <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200662:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc0200664:	1141                	addi	sp,sp,-16
ffffffffc0200666:	e022                	sd	s0,0(sp)
ffffffffc0200668:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020066a:	00006517          	auipc	a0,0x6
ffffffffc020066e:	42650513          	addi	a0,a0,1062 # ffffffffc0206a90 <etext+0x2d4>
void print_regs(struct pushregs* gpr) {
ffffffffc0200672:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200674:	b0dff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200678:	640c                	ld	a1,8(s0)
ffffffffc020067a:	00006517          	auipc	a0,0x6
ffffffffc020067e:	42e50513          	addi	a0,a0,1070 # ffffffffc0206aa8 <etext+0x2ec>
ffffffffc0200682:	affff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200686:	680c                	ld	a1,16(s0)
ffffffffc0200688:	00006517          	auipc	a0,0x6
ffffffffc020068c:	43850513          	addi	a0,a0,1080 # ffffffffc0206ac0 <etext+0x304>
ffffffffc0200690:	af1ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200694:	6c0c                	ld	a1,24(s0)
ffffffffc0200696:	00006517          	auipc	a0,0x6
ffffffffc020069a:	44250513          	addi	a0,a0,1090 # ffffffffc0206ad8 <etext+0x31c>
ffffffffc020069e:	ae3ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006a2:	700c                	ld	a1,32(s0)
ffffffffc02006a4:	00006517          	auipc	a0,0x6
ffffffffc02006a8:	44c50513          	addi	a0,a0,1100 # ffffffffc0206af0 <etext+0x334>
ffffffffc02006ac:	ad5ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006b0:	740c                	ld	a1,40(s0)
ffffffffc02006b2:	00006517          	auipc	a0,0x6
ffffffffc02006b6:	45650513          	addi	a0,a0,1110 # ffffffffc0206b08 <etext+0x34c>
ffffffffc02006ba:	ac7ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006be:	780c                	ld	a1,48(s0)
ffffffffc02006c0:	00006517          	auipc	a0,0x6
ffffffffc02006c4:	46050513          	addi	a0,a0,1120 # ffffffffc0206b20 <etext+0x364>
ffffffffc02006c8:	ab9ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006cc:	7c0c                	ld	a1,56(s0)
ffffffffc02006ce:	00006517          	auipc	a0,0x6
ffffffffc02006d2:	46a50513          	addi	a0,a0,1130 # ffffffffc0206b38 <etext+0x37c>
ffffffffc02006d6:	aabff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006da:	602c                	ld	a1,64(s0)
ffffffffc02006dc:	00006517          	auipc	a0,0x6
ffffffffc02006e0:	47450513          	addi	a0,a0,1140 # ffffffffc0206b50 <etext+0x394>
ffffffffc02006e4:	a9dff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006e8:	642c                	ld	a1,72(s0)
ffffffffc02006ea:	00006517          	auipc	a0,0x6
ffffffffc02006ee:	47e50513          	addi	a0,a0,1150 # ffffffffc0206b68 <etext+0x3ac>
ffffffffc02006f2:	a8fff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006f6:	682c                	ld	a1,80(s0)
ffffffffc02006f8:	00006517          	auipc	a0,0x6
ffffffffc02006fc:	48850513          	addi	a0,a0,1160 # ffffffffc0206b80 <etext+0x3c4>
ffffffffc0200700:	a81ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200704:	6c2c                	ld	a1,88(s0)
ffffffffc0200706:	00006517          	auipc	a0,0x6
ffffffffc020070a:	49250513          	addi	a0,a0,1170 # ffffffffc0206b98 <etext+0x3dc>
ffffffffc020070e:	a73ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200712:	702c                	ld	a1,96(s0)
ffffffffc0200714:	00006517          	auipc	a0,0x6
ffffffffc0200718:	49c50513          	addi	a0,a0,1180 # ffffffffc0206bb0 <etext+0x3f4>
ffffffffc020071c:	a65ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200720:	742c                	ld	a1,104(s0)
ffffffffc0200722:	00006517          	auipc	a0,0x6
ffffffffc0200726:	4a650513          	addi	a0,a0,1190 # ffffffffc0206bc8 <etext+0x40c>
ffffffffc020072a:	a57ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020072e:	782c                	ld	a1,112(s0)
ffffffffc0200730:	00006517          	auipc	a0,0x6
ffffffffc0200734:	4b050513          	addi	a0,a0,1200 # ffffffffc0206be0 <etext+0x424>
ffffffffc0200738:	a49ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020073c:	7c2c                	ld	a1,120(s0)
ffffffffc020073e:	00006517          	auipc	a0,0x6
ffffffffc0200742:	4ba50513          	addi	a0,a0,1210 # ffffffffc0206bf8 <etext+0x43c>
ffffffffc0200746:	a3bff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020074a:	604c                	ld	a1,128(s0)
ffffffffc020074c:	00006517          	auipc	a0,0x6
ffffffffc0200750:	4c450513          	addi	a0,a0,1220 # ffffffffc0206c10 <etext+0x454>
ffffffffc0200754:	a2dff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200758:	644c                	ld	a1,136(s0)
ffffffffc020075a:	00006517          	auipc	a0,0x6
ffffffffc020075e:	4ce50513          	addi	a0,a0,1230 # ffffffffc0206c28 <etext+0x46c>
ffffffffc0200762:	a1fff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200766:	684c                	ld	a1,144(s0)
ffffffffc0200768:	00006517          	auipc	a0,0x6
ffffffffc020076c:	4d850513          	addi	a0,a0,1240 # ffffffffc0206c40 <etext+0x484>
ffffffffc0200770:	a11ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200774:	6c4c                	ld	a1,152(s0)
ffffffffc0200776:	00006517          	auipc	a0,0x6
ffffffffc020077a:	4e250513          	addi	a0,a0,1250 # ffffffffc0206c58 <etext+0x49c>
ffffffffc020077e:	a03ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200782:	704c                	ld	a1,160(s0)
ffffffffc0200784:	00006517          	auipc	a0,0x6
ffffffffc0200788:	4ec50513          	addi	a0,a0,1260 # ffffffffc0206c70 <etext+0x4b4>
ffffffffc020078c:	9f5ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200790:	744c                	ld	a1,168(s0)
ffffffffc0200792:	00006517          	auipc	a0,0x6
ffffffffc0200796:	4f650513          	addi	a0,a0,1270 # ffffffffc0206c88 <etext+0x4cc>
ffffffffc020079a:	9e7ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020079e:	784c                	ld	a1,176(s0)
ffffffffc02007a0:	00006517          	auipc	a0,0x6
ffffffffc02007a4:	50050513          	addi	a0,a0,1280 # ffffffffc0206ca0 <etext+0x4e4>
ffffffffc02007a8:	9d9ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007ac:	7c4c                	ld	a1,184(s0)
ffffffffc02007ae:	00006517          	auipc	a0,0x6
ffffffffc02007b2:	50a50513          	addi	a0,a0,1290 # ffffffffc0206cb8 <etext+0x4fc>
ffffffffc02007b6:	9cbff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007ba:	606c                	ld	a1,192(s0)
ffffffffc02007bc:	00006517          	auipc	a0,0x6
ffffffffc02007c0:	51450513          	addi	a0,a0,1300 # ffffffffc0206cd0 <etext+0x514>
ffffffffc02007c4:	9bdff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007c8:	646c                	ld	a1,200(s0)
ffffffffc02007ca:	00006517          	auipc	a0,0x6
ffffffffc02007ce:	51e50513          	addi	a0,a0,1310 # ffffffffc0206ce8 <etext+0x52c>
ffffffffc02007d2:	9afff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007d6:	686c                	ld	a1,208(s0)
ffffffffc02007d8:	00006517          	auipc	a0,0x6
ffffffffc02007dc:	52850513          	addi	a0,a0,1320 # ffffffffc0206d00 <etext+0x544>
ffffffffc02007e0:	9a1ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007e4:	6c6c                	ld	a1,216(s0)
ffffffffc02007e6:	00006517          	auipc	a0,0x6
ffffffffc02007ea:	53250513          	addi	a0,a0,1330 # ffffffffc0206d18 <etext+0x55c>
ffffffffc02007ee:	993ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007f2:	706c                	ld	a1,224(s0)
ffffffffc02007f4:	00006517          	auipc	a0,0x6
ffffffffc02007f8:	53c50513          	addi	a0,a0,1340 # ffffffffc0206d30 <etext+0x574>
ffffffffc02007fc:	985ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200800:	746c                	ld	a1,232(s0)
ffffffffc0200802:	00006517          	auipc	a0,0x6
ffffffffc0200806:	54650513          	addi	a0,a0,1350 # ffffffffc0206d48 <etext+0x58c>
ffffffffc020080a:	977ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020080e:	786c                	ld	a1,240(s0)
ffffffffc0200810:	00006517          	auipc	a0,0x6
ffffffffc0200814:	55050513          	addi	a0,a0,1360 # ffffffffc0206d60 <etext+0x5a4>
ffffffffc0200818:	969ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020081c:	7c6c                	ld	a1,248(s0)
}
ffffffffc020081e:	6402                	ld	s0,0(sp)
ffffffffc0200820:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200822:	00006517          	auipc	a0,0x6
ffffffffc0200826:	55650513          	addi	a0,a0,1366 # ffffffffc0206d78 <etext+0x5bc>
}
ffffffffc020082a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020082c:	955ff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0200830 <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc0200830:	1141                	addi	sp,sp,-16
ffffffffc0200832:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200834:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc0200836:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200838:	00006517          	auipc	a0,0x6
ffffffffc020083c:	55850513          	addi	a0,a0,1368 # ffffffffc0206d90 <etext+0x5d4>
print_trapframe(struct trapframe *tf) {
ffffffffc0200840:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200842:	93fff0ef          	jal	ffffffffc0200180 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200846:	8522                	mv	a0,s0
ffffffffc0200848:	e1bff0ef          	jal	ffffffffc0200662 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020084c:	10043583          	ld	a1,256(s0)
ffffffffc0200850:	00006517          	auipc	a0,0x6
ffffffffc0200854:	55850513          	addi	a0,a0,1368 # ffffffffc0206da8 <etext+0x5ec>
ffffffffc0200858:	929ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020085c:	10843583          	ld	a1,264(s0)
ffffffffc0200860:	00006517          	auipc	a0,0x6
ffffffffc0200864:	56050513          	addi	a0,a0,1376 # ffffffffc0206dc0 <etext+0x604>
ffffffffc0200868:	919ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc020086c:	11043583          	ld	a1,272(s0)
ffffffffc0200870:	00006517          	auipc	a0,0x6
ffffffffc0200874:	56850513          	addi	a0,a0,1384 # ffffffffc0206dd8 <etext+0x61c>
ffffffffc0200878:	909ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020087c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200880:	6402                	ld	s0,0(sp)
ffffffffc0200882:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200884:	00006517          	auipc	a0,0x6
ffffffffc0200888:	56450513          	addi	a0,a0,1380 # ffffffffc0206de8 <etext+0x62c>
}
ffffffffc020088c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020088e:	8f3ff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0200892 <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc0200892:	1101                	addi	sp,sp,-32
ffffffffc0200894:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc0200896:	0009d497          	auipc	s1,0x9d
ffffffffc020089a:	45a48493          	addi	s1,s1,1114 # ffffffffc029dcf0 <check_mm_struct>
ffffffffc020089e:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008a0:	e822                	sd	s0,16(sp)
ffffffffc02008a2:	ec06                	sd	ra,24(sp)
ffffffffc02008a4:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008a6:	cfb9                	beqz	a5,ffffffffc0200904 <pgfault_handler+0x72>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008a8:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008ac:	11053583          	ld	a1,272(a0)
ffffffffc02008b0:	05500613          	li	a2,85
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008b4:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008b8:	c399                	beqz	a5,ffffffffc02008be <pgfault_handler+0x2c>
ffffffffc02008ba:	04b00613          	li	a2,75
ffffffffc02008be:	11843703          	ld	a4,280(s0)
ffffffffc02008c2:	47bd                	li	a5,15
ffffffffc02008c4:	05200693          	li	a3,82
ffffffffc02008c8:	04f70e63          	beq	a4,a5,ffffffffc0200924 <pgfault_handler+0x92>
ffffffffc02008cc:	00006517          	auipc	a0,0x6
ffffffffc02008d0:	53450513          	addi	a0,a0,1332 # ffffffffc0206e00 <etext+0x644>
ffffffffc02008d4:	8adff0ef          	jal	ffffffffc0200180 <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008d8:	6088                	ld	a0,0(s1)
ffffffffc02008da:	c50d                	beqz	a0,ffffffffc0200904 <pgfault_handler+0x72>
        assert(current == idleproc);
ffffffffc02008dc:	0009d717          	auipc	a4,0x9d
ffffffffc02008e0:	42473703          	ld	a4,1060(a4) # ffffffffc029dd00 <current>
ffffffffc02008e4:	0009d797          	auipc	a5,0x9d
ffffffffc02008e8:	42c7b783          	ld	a5,1068(a5) # ffffffffc029dd10 <idleproc>
ffffffffc02008ec:	02f71f63          	bne	a4,a5,ffffffffc020092a <pgfault_handler+0x98>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc02008f0:	11043603          	ld	a2,272(s0)
ffffffffc02008f4:	11843583          	ld	a1,280(s0)
}
ffffffffc02008f8:	6442                	ld	s0,16(sp)
ffffffffc02008fa:	60e2                	ld	ra,24(sp)
ffffffffc02008fc:	64a2                	ld	s1,8(sp)
ffffffffc02008fe:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200900:	0fc0406f          	j	ffffffffc02049fc <do_pgfault>
        if (current == NULL) {
ffffffffc0200904:	0009d797          	auipc	a5,0x9d
ffffffffc0200908:	3fc7b783          	ld	a5,1020(a5) # ffffffffc029dd00 <current>
ffffffffc020090c:	cf9d                	beqz	a5,ffffffffc020094a <pgfault_handler+0xb8>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020090e:	11043603          	ld	a2,272(s0)
ffffffffc0200912:	11843583          	ld	a1,280(s0)
}
ffffffffc0200916:	6442                	ld	s0,16(sp)
ffffffffc0200918:	60e2                	ld	ra,24(sp)
ffffffffc020091a:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc020091c:	7788                	ld	a0,40(a5)
}
ffffffffc020091e:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200920:	0dc0406f          	j	ffffffffc02049fc <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200924:	05700693          	li	a3,87
ffffffffc0200928:	b755                	j	ffffffffc02008cc <pgfault_handler+0x3a>
        assert(current == idleproc);
ffffffffc020092a:	00006697          	auipc	a3,0x6
ffffffffc020092e:	4f668693          	addi	a3,a3,1270 # ffffffffc0206e20 <etext+0x664>
ffffffffc0200932:	00006617          	auipc	a2,0x6
ffffffffc0200936:	50660613          	addi	a2,a2,1286 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020093a:	06b00593          	li	a1,107
ffffffffc020093e:	00006517          	auipc	a0,0x6
ffffffffc0200942:	51250513          	addi	a0,a0,1298 # ffffffffc0206e50 <etext+0x694>
ffffffffc0200946:	b2fff0ef          	jal	ffffffffc0200474 <__panic>
            print_trapframe(tf);
ffffffffc020094a:	8522                	mv	a0,s0
ffffffffc020094c:	ee5ff0ef          	jal	ffffffffc0200830 <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200950:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200954:	11043583          	ld	a1,272(s0)
ffffffffc0200958:	05500613          	li	a2,85
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020095c:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200960:	c399                	beqz	a5,ffffffffc0200966 <pgfault_handler+0xd4>
ffffffffc0200962:	04b00613          	li	a2,75
ffffffffc0200966:	11843703          	ld	a4,280(s0)
ffffffffc020096a:	47bd                	li	a5,15
ffffffffc020096c:	05200693          	li	a3,82
ffffffffc0200970:	00f71463          	bne	a4,a5,ffffffffc0200978 <pgfault_handler+0xe6>
ffffffffc0200974:	05700693          	li	a3,87
ffffffffc0200978:	00006517          	auipc	a0,0x6
ffffffffc020097c:	48850513          	addi	a0,a0,1160 # ffffffffc0206e00 <etext+0x644>
ffffffffc0200980:	801ff0ef          	jal	ffffffffc0200180 <cprintf>
            panic("unhandled page fault.\n");
ffffffffc0200984:	00006617          	auipc	a2,0x6
ffffffffc0200988:	4e460613          	addi	a2,a2,1252 # ffffffffc0206e68 <etext+0x6ac>
ffffffffc020098c:	07200593          	li	a1,114
ffffffffc0200990:	00006517          	auipc	a0,0x6
ffffffffc0200994:	4c050513          	addi	a0,a0,1216 # ffffffffc0206e50 <etext+0x694>
ffffffffc0200998:	addff0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc020099c <interrupt_handler>:
static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc020099c:	11853783          	ld	a5,280(a0)
ffffffffc02009a0:	472d                	li	a4,11
ffffffffc02009a2:	0786                	slli	a5,a5,0x1
ffffffffc02009a4:	8385                	srli	a5,a5,0x1
ffffffffc02009a6:	08f76363          	bltu	a4,a5,ffffffffc0200a2c <interrupt_handler+0x90>
ffffffffc02009aa:	00008717          	auipc	a4,0x8
ffffffffc02009ae:	13e70713          	addi	a4,a4,318 # ffffffffc0208ae8 <commands+0x48>
ffffffffc02009b2:	078a                	slli	a5,a5,0x2
ffffffffc02009b4:	97ba                	add	a5,a5,a4
ffffffffc02009b6:	439c                	lw	a5,0(a5)
ffffffffc02009b8:	97ba                	add	a5,a5,a4
ffffffffc02009ba:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009bc:	00006517          	auipc	a0,0x6
ffffffffc02009c0:	52450513          	addi	a0,a0,1316 # ffffffffc0206ee0 <etext+0x724>
ffffffffc02009c4:	fbcff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009c8:	00006517          	auipc	a0,0x6
ffffffffc02009cc:	4f850513          	addi	a0,a0,1272 # ffffffffc0206ec0 <etext+0x704>
ffffffffc02009d0:	fb0ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02009d4:	00006517          	auipc	a0,0x6
ffffffffc02009d8:	4ac50513          	addi	a0,a0,1196 # ffffffffc0206e80 <etext+0x6c4>
ffffffffc02009dc:	fa4ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02009e0:	00006517          	auipc	a0,0x6
ffffffffc02009e4:	4c050513          	addi	a0,a0,1216 # ffffffffc0206ea0 <etext+0x6e4>
ffffffffc02009e8:	f98ff06f          	j	ffffffffc0200180 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02009ec:	1141                	addi	sp,sp,-16
ffffffffc02009ee:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02009f0:	b69ff0ef          	jal	ffffffffc0200558 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc02009f4:	0009d697          	auipc	a3,0x9d
ffffffffc02009f8:	29c68693          	addi	a3,a3,668 # ffffffffc029dc90 <ticks>
ffffffffc02009fc:	629c                	ld	a5,0(a3)
ffffffffc02009fe:	06400713          	li	a4,100
ffffffffc0200a02:	0785                	addi	a5,a5,1
ffffffffc0200a04:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a08:	e29c                	sd	a5,0(a3)
ffffffffc0200a0a:	eb01                	bnez	a4,ffffffffc0200a1a <interrupt_handler+0x7e>
ffffffffc0200a0c:	0009d797          	auipc	a5,0x9d
ffffffffc0200a10:	2f47b783          	ld	a5,756(a5) # ffffffffc029dd00 <current>
ffffffffc0200a14:	c399                	beqz	a5,ffffffffc0200a1a <interrupt_handler+0x7e>
                // print_ticks();
                current->need_resched = 1;
ffffffffc0200a16:	4705                	li	a4,1
ffffffffc0200a18:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a1a:	60a2                	ld	ra,8(sp)
ffffffffc0200a1c:	0141                	addi	sp,sp,16
ffffffffc0200a1e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a20:	00006517          	auipc	a0,0x6
ffffffffc0200a24:	4e050513          	addi	a0,a0,1248 # ffffffffc0206f00 <etext+0x744>
ffffffffc0200a28:	f58ff06f          	j	ffffffffc0200180 <cprintf>
            print_trapframe(tf);
ffffffffc0200a2c:	b511                	j	ffffffffc0200830 <print_trapframe>

ffffffffc0200a2e <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a2e:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a32:	1101                	addi	sp,sp,-32
ffffffffc0200a34:	e822                	sd	s0,16(sp)
ffffffffc0200a36:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200a38:	473d                	li	a4,15
void exception_handler(struct trapframe *tf) {
ffffffffc0200a3a:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200a3c:	18f76663          	bltu	a4,a5,ffffffffc0200bc8 <exception_handler+0x19a>
ffffffffc0200a40:	00008717          	auipc	a4,0x8
ffffffffc0200a44:	0d870713          	addi	a4,a4,216 # ffffffffc0208b18 <commands+0x78>
ffffffffc0200a48:	078a                	slli	a5,a5,0x2
ffffffffc0200a4a:	97ba                	add	a5,a5,a4
ffffffffc0200a4c:	439c                	lw	a5,0(a5)
ffffffffc0200a4e:	97ba                	add	a5,a5,a4
ffffffffc0200a50:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a52:	00006517          	auipc	a0,0x6
ffffffffc0200a56:	5be50513          	addi	a0,a0,1470 # ffffffffc0207010 <etext+0x854>
ffffffffc0200a5a:	f26ff0ef          	jal	ffffffffc0200180 <cprintf>
            tf->epc += 4;
ffffffffc0200a5e:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a62:	60e2                	ld	ra,24(sp)
            tf->epc += 4;
ffffffffc0200a64:	0791                	addi	a5,a5,4
ffffffffc0200a66:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200a6a:	6442                	ld	s0,16(sp)
ffffffffc0200a6c:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200a6e:	0110506f          	j	ffffffffc020627e <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a72:	00006517          	auipc	a0,0x6
ffffffffc0200a76:	5be50513          	addi	a0,a0,1470 # ffffffffc0207030 <etext+0x874>
}
ffffffffc0200a7a:	6442                	ld	s0,16(sp)
ffffffffc0200a7c:	60e2                	ld	ra,24(sp)
ffffffffc0200a7e:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200a80:	f00ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a84:	00006517          	auipc	a0,0x6
ffffffffc0200a88:	5cc50513          	addi	a0,a0,1484 # ffffffffc0207050 <etext+0x894>
ffffffffc0200a8c:	b7fd                	j	ffffffffc0200a7a <exception_handler+0x4c>
            cprintf("Instruction page fault\n");
ffffffffc0200a8e:	00006517          	auipc	a0,0x6
ffffffffc0200a92:	5e250513          	addi	a0,a0,1506 # ffffffffc0207070 <etext+0x8b4>
ffffffffc0200a96:	b7d5                	j	ffffffffc0200a7a <exception_handler+0x4c>
            cprintf("Load page fault\n");
ffffffffc0200a98:	00006517          	auipc	a0,0x6
ffffffffc0200a9c:	5f050513          	addi	a0,a0,1520 # ffffffffc0207088 <etext+0x8cc>
ffffffffc0200aa0:	e426                	sd	s1,8(sp)
ffffffffc0200aa2:	edeff0ef          	jal	ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200aa6:	8522                	mv	a0,s0
ffffffffc0200aa8:	debff0ef          	jal	ffffffffc0200892 <pgfault_handler>
ffffffffc0200aac:	84aa                	mv	s1,a0
ffffffffc0200aae:	12051f63          	bnez	a0,ffffffffc0200bec <exception_handler+0x1be>
ffffffffc0200ab2:	64a2                	ld	s1,8(sp)
}
ffffffffc0200ab4:	60e2                	ld	ra,24(sp)
ffffffffc0200ab6:	6442                	ld	s0,16(sp)
ffffffffc0200ab8:	6105                	addi	sp,sp,32
ffffffffc0200aba:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200abc:	00006517          	auipc	a0,0x6
ffffffffc0200ac0:	5e450513          	addi	a0,a0,1508 # ffffffffc02070a0 <etext+0x8e4>
ffffffffc0200ac4:	e426                	sd	s1,8(sp)
ffffffffc0200ac6:	ebaff0ef          	jal	ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200aca:	8522                	mv	a0,s0
ffffffffc0200acc:	dc7ff0ef          	jal	ffffffffc0200892 <pgfault_handler>
ffffffffc0200ad0:	84aa                	mv	s1,a0
ffffffffc0200ad2:	d165                	beqz	a0,ffffffffc0200ab2 <exception_handler+0x84>
                print_trapframe(tf);
ffffffffc0200ad4:	8522                	mv	a0,s0
ffffffffc0200ad6:	d5bff0ef          	jal	ffffffffc0200830 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200ada:	86a6                	mv	a3,s1
ffffffffc0200adc:	00006617          	auipc	a2,0x6
ffffffffc0200ae0:	4e460613          	addi	a2,a2,1252 # ffffffffc0206fc0 <etext+0x804>
ffffffffc0200ae4:	0f800593          	li	a1,248
ffffffffc0200ae8:	00006517          	auipc	a0,0x6
ffffffffc0200aec:	36850513          	addi	a0,a0,872 # ffffffffc0206e50 <etext+0x694>
ffffffffc0200af0:	985ff0ef          	jal	ffffffffc0200474 <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200af4:	00006517          	auipc	a0,0x6
ffffffffc0200af8:	42c50513          	addi	a0,a0,1068 # ffffffffc0206f20 <etext+0x764>
ffffffffc0200afc:	bfbd                	j	ffffffffc0200a7a <exception_handler+0x4c>
            cprintf("Instruction access fault\n");
ffffffffc0200afe:	00006517          	auipc	a0,0x6
ffffffffc0200b02:	44250513          	addi	a0,a0,1090 # ffffffffc0206f40 <etext+0x784>
ffffffffc0200b06:	bf95                	j	ffffffffc0200a7a <exception_handler+0x4c>
            cprintf("Illegal instruction\n");
ffffffffc0200b08:	00006517          	auipc	a0,0x6
ffffffffc0200b0c:	45850513          	addi	a0,a0,1112 # ffffffffc0206f60 <etext+0x7a4>
ffffffffc0200b10:	b7ad                	j	ffffffffc0200a7a <exception_handler+0x4c>
            cprintf("Breakpoint\n");
ffffffffc0200b12:	00006517          	auipc	a0,0x6
ffffffffc0200b16:	46650513          	addi	a0,a0,1126 # ffffffffc0206f78 <etext+0x7bc>
ffffffffc0200b1a:	e66ff0ef          	jal	ffffffffc0200180 <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b1e:	6458                	ld	a4,136(s0)
ffffffffc0200b20:	47a9                	li	a5,10
ffffffffc0200b22:	f8f719e3          	bne	a4,a5,ffffffffc0200ab4 <exception_handler+0x86>
                tf->epc += 4;
ffffffffc0200b26:	10843783          	ld	a5,264(s0)
ffffffffc0200b2a:	0791                	addi	a5,a5,4
ffffffffc0200b2c:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200b30:	74e050ef          	jal	ffffffffc020627e <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b34:	0009d797          	auipc	a5,0x9d
ffffffffc0200b38:	1cc7b783          	ld	a5,460(a5) # ffffffffc029dd00 <current>
ffffffffc0200b3c:	6b9c                	ld	a5,16(a5)
ffffffffc0200b3e:	8522                	mv	a0,s0
}
ffffffffc0200b40:	6442                	ld	s0,16(sp)
ffffffffc0200b42:	60e2                	ld	ra,24(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b44:	6589                	lui	a1,0x2
ffffffffc0200b46:	95be                	add	a1,a1,a5
}
ffffffffc0200b48:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b4a:	ac11                	j	ffffffffc0200d5e <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200b4c:	00006517          	auipc	a0,0x6
ffffffffc0200b50:	43c50513          	addi	a0,a0,1084 # ffffffffc0206f88 <etext+0x7cc>
ffffffffc0200b54:	b71d                	j	ffffffffc0200a7a <exception_handler+0x4c>
            cprintf("Load access fault\n");
ffffffffc0200b56:	00006517          	auipc	a0,0x6
ffffffffc0200b5a:	45250513          	addi	a0,a0,1106 # ffffffffc0206fa8 <etext+0x7ec>
ffffffffc0200b5e:	e426                	sd	s1,8(sp)
ffffffffc0200b60:	e20ff0ef          	jal	ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b64:	8522                	mv	a0,s0
ffffffffc0200b66:	d2dff0ef          	jal	ffffffffc0200892 <pgfault_handler>
ffffffffc0200b6a:	84aa                	mv	s1,a0
ffffffffc0200b6c:	d139                	beqz	a0,ffffffffc0200ab2 <exception_handler+0x84>
                print_trapframe(tf);
ffffffffc0200b6e:	8522                	mv	a0,s0
ffffffffc0200b70:	cc1ff0ef          	jal	ffffffffc0200830 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b74:	86a6                	mv	a3,s1
ffffffffc0200b76:	00006617          	auipc	a2,0x6
ffffffffc0200b7a:	44a60613          	addi	a2,a2,1098 # ffffffffc0206fc0 <etext+0x804>
ffffffffc0200b7e:	0cd00593          	li	a1,205
ffffffffc0200b82:	00006517          	auipc	a0,0x6
ffffffffc0200b86:	2ce50513          	addi	a0,a0,718 # ffffffffc0206e50 <etext+0x694>
ffffffffc0200b8a:	8ebff0ef          	jal	ffffffffc0200474 <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200b8e:	00006517          	auipc	a0,0x6
ffffffffc0200b92:	46a50513          	addi	a0,a0,1130 # ffffffffc0206ff8 <etext+0x83c>
ffffffffc0200b96:	e426                	sd	s1,8(sp)
ffffffffc0200b98:	de8ff0ef          	jal	ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b9c:	8522                	mv	a0,s0
ffffffffc0200b9e:	cf5ff0ef          	jal	ffffffffc0200892 <pgfault_handler>
ffffffffc0200ba2:	84aa                	mv	s1,a0
ffffffffc0200ba4:	f00507e3          	beqz	a0,ffffffffc0200ab2 <exception_handler+0x84>
                print_trapframe(tf);
ffffffffc0200ba8:	8522                	mv	a0,s0
ffffffffc0200baa:	c87ff0ef          	jal	ffffffffc0200830 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bae:	86a6                	mv	a3,s1
ffffffffc0200bb0:	00006617          	auipc	a2,0x6
ffffffffc0200bb4:	41060613          	addi	a2,a2,1040 # ffffffffc0206fc0 <etext+0x804>
ffffffffc0200bb8:	0d700593          	li	a1,215
ffffffffc0200bbc:	00006517          	auipc	a0,0x6
ffffffffc0200bc0:	29450513          	addi	a0,a0,660 # ffffffffc0206e50 <etext+0x694>
ffffffffc0200bc4:	8b1ff0ef          	jal	ffffffffc0200474 <__panic>
            print_trapframe(tf);
ffffffffc0200bc8:	8522                	mv	a0,s0
}
ffffffffc0200bca:	6442                	ld	s0,16(sp)
ffffffffc0200bcc:	60e2                	ld	ra,24(sp)
ffffffffc0200bce:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200bd0:	b185                	j	ffffffffc0200830 <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200bd2:	00006617          	auipc	a2,0x6
ffffffffc0200bd6:	40e60613          	addi	a2,a2,1038 # ffffffffc0206fe0 <etext+0x824>
ffffffffc0200bda:	0d100593          	li	a1,209
ffffffffc0200bde:	00006517          	auipc	a0,0x6
ffffffffc0200be2:	27250513          	addi	a0,a0,626 # ffffffffc0206e50 <etext+0x694>
ffffffffc0200be6:	e426                	sd	s1,8(sp)
ffffffffc0200be8:	88dff0ef          	jal	ffffffffc0200474 <__panic>
                print_trapframe(tf);
ffffffffc0200bec:	8522                	mv	a0,s0
ffffffffc0200bee:	c43ff0ef          	jal	ffffffffc0200830 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bf2:	86a6                	mv	a3,s1
ffffffffc0200bf4:	00006617          	auipc	a2,0x6
ffffffffc0200bf8:	3cc60613          	addi	a2,a2,972 # ffffffffc0206fc0 <etext+0x804>
ffffffffc0200bfc:	0f100593          	li	a1,241
ffffffffc0200c00:	00006517          	auipc	a0,0x6
ffffffffc0200c04:	25050513          	addi	a0,a0,592 # ffffffffc0206e50 <etext+0x694>
ffffffffc0200c08:	86dff0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0200c0c <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c0c:	1101                	addi	sp,sp,-32
ffffffffc0200c0e:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c10:	0009d417          	auipc	s0,0x9d
ffffffffc0200c14:	0f040413          	addi	s0,s0,240 # ffffffffc029dd00 <current>
ffffffffc0200c18:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c1a:	ec06                	sd	ra,24(sp)
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c1c:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c20:	c329                	beqz	a4,ffffffffc0200c62 <trap+0x56>
ffffffffc0200c22:	e426                	sd	s1,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c24:	10053483          	ld	s1,256(a0)
ffffffffc0200c28:	e04a                	sd	s2,0(sp)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c2a:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c2e:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c30:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c34:	0206c463          	bltz	a3,ffffffffc0200c5c <trap+0x50>
        exception_handler(tf);
ffffffffc0200c38:	df7ff0ef          	jal	ffffffffc0200a2e <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c3c:	601c                	ld	a5,0(s0)
ffffffffc0200c3e:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c42:	e499                	bnez	s1,ffffffffc0200c50 <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c44:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c48:	8b05                	andi	a4,a4,1
ffffffffc0200c4a:	ef0d                	bnez	a4,ffffffffc0200c84 <trap+0x78>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c4c:	6f9c                	ld	a5,24(a5)
ffffffffc0200c4e:	e785                	bnez	a5,ffffffffc0200c76 <trap+0x6a>
                schedule();
            }
        }
    }
}
ffffffffc0200c50:	60e2                	ld	ra,24(sp)
ffffffffc0200c52:	6442                	ld	s0,16(sp)
ffffffffc0200c54:	64a2                	ld	s1,8(sp)
ffffffffc0200c56:	6902                	ld	s2,0(sp)
ffffffffc0200c58:	6105                	addi	sp,sp,32
ffffffffc0200c5a:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200c5c:	d41ff0ef          	jal	ffffffffc020099c <interrupt_handler>
ffffffffc0200c60:	bff1                	j	ffffffffc0200c3c <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c62:	0006c663          	bltz	a3,ffffffffc0200c6e <trap+0x62>
}
ffffffffc0200c66:	6442                	ld	s0,16(sp)
ffffffffc0200c68:	60e2                	ld	ra,24(sp)
ffffffffc0200c6a:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200c6c:	b3c9                	j	ffffffffc0200a2e <exception_handler>
}
ffffffffc0200c6e:	6442                	ld	s0,16(sp)
ffffffffc0200c70:	60e2                	ld	ra,24(sp)
ffffffffc0200c72:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200c74:	b325                	j	ffffffffc020099c <interrupt_handler>
}
ffffffffc0200c76:	6442                	ld	s0,16(sp)
                schedule();
ffffffffc0200c78:	64a2                	ld	s1,8(sp)
ffffffffc0200c7a:	6902                	ld	s2,0(sp)
}
ffffffffc0200c7c:	60e2                	ld	ra,24(sp)
ffffffffc0200c7e:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200c80:	5120506f          	j	ffffffffc0206192 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200c84:	555d                	li	a0,-9
ffffffffc0200c86:	7b0040ef          	jal	ffffffffc0205436 <do_exit>
            if (current->need_resched) {
ffffffffc0200c8a:	601c                	ld	a5,0(s0)
ffffffffc0200c8c:	b7c1                	j	ffffffffc0200c4c <trap+0x40>
	...

ffffffffc0200c90 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200c90:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200c94:	00011463          	bnez	sp,ffffffffc0200c9c <__alltraps+0xc>
ffffffffc0200c98:	14002173          	csrr	sp,sscratch
ffffffffc0200c9c:	712d                	addi	sp,sp,-288
ffffffffc0200c9e:	e002                	sd	zero,0(sp)
ffffffffc0200ca0:	e406                	sd	ra,8(sp)
ffffffffc0200ca2:	ec0e                	sd	gp,24(sp)
ffffffffc0200ca4:	f012                	sd	tp,32(sp)
ffffffffc0200ca6:	f416                	sd	t0,40(sp)
ffffffffc0200ca8:	f81a                	sd	t1,48(sp)
ffffffffc0200caa:	fc1e                	sd	t2,56(sp)
ffffffffc0200cac:	e0a2                	sd	s0,64(sp)
ffffffffc0200cae:	e4a6                	sd	s1,72(sp)
ffffffffc0200cb0:	e8aa                	sd	a0,80(sp)
ffffffffc0200cb2:	ecae                	sd	a1,88(sp)
ffffffffc0200cb4:	f0b2                	sd	a2,96(sp)
ffffffffc0200cb6:	f4b6                	sd	a3,104(sp)
ffffffffc0200cb8:	f8ba                	sd	a4,112(sp)
ffffffffc0200cba:	fcbe                	sd	a5,120(sp)
ffffffffc0200cbc:	e142                	sd	a6,128(sp)
ffffffffc0200cbe:	e546                	sd	a7,136(sp)
ffffffffc0200cc0:	e94a                	sd	s2,144(sp)
ffffffffc0200cc2:	ed4e                	sd	s3,152(sp)
ffffffffc0200cc4:	f152                	sd	s4,160(sp)
ffffffffc0200cc6:	f556                	sd	s5,168(sp)
ffffffffc0200cc8:	f95a                	sd	s6,176(sp)
ffffffffc0200cca:	fd5e                	sd	s7,184(sp)
ffffffffc0200ccc:	e1e2                	sd	s8,192(sp)
ffffffffc0200cce:	e5e6                	sd	s9,200(sp)
ffffffffc0200cd0:	e9ea                	sd	s10,208(sp)
ffffffffc0200cd2:	edee                	sd	s11,216(sp)
ffffffffc0200cd4:	f1f2                	sd	t3,224(sp)
ffffffffc0200cd6:	f5f6                	sd	t4,232(sp)
ffffffffc0200cd8:	f9fa                	sd	t5,240(sp)
ffffffffc0200cda:	fdfe                	sd	t6,248(sp)
ffffffffc0200cdc:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ce0:	100024f3          	csrr	s1,sstatus
ffffffffc0200ce4:	14102973          	csrr	s2,sepc
ffffffffc0200ce8:	143029f3          	csrr	s3,stval
ffffffffc0200cec:	14202a73          	csrr	s4,scause
ffffffffc0200cf0:	e822                	sd	s0,16(sp)
ffffffffc0200cf2:	e226                	sd	s1,256(sp)
ffffffffc0200cf4:	e64a                	sd	s2,264(sp)
ffffffffc0200cf6:	ea4e                	sd	s3,272(sp)
ffffffffc0200cf8:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200cfa:	850a                	mv	a0,sp
    jal trap
ffffffffc0200cfc:	f11ff0ef          	jal	ffffffffc0200c0c <trap>

ffffffffc0200d00 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d00:	6492                	ld	s1,256(sp)
ffffffffc0200d02:	6932                	ld	s2,264(sp)
ffffffffc0200d04:	1004f413          	andi	s0,s1,256
ffffffffc0200d08:	e401                	bnez	s0,ffffffffc0200d10 <__trapret+0x10>
ffffffffc0200d0a:	1200                	addi	s0,sp,288
ffffffffc0200d0c:	14041073          	csrw	sscratch,s0
ffffffffc0200d10:	10049073          	csrw	sstatus,s1
ffffffffc0200d14:	14191073          	csrw	sepc,s2
ffffffffc0200d18:	60a2                	ld	ra,8(sp)
ffffffffc0200d1a:	61e2                	ld	gp,24(sp)
ffffffffc0200d1c:	7202                	ld	tp,32(sp)
ffffffffc0200d1e:	72a2                	ld	t0,40(sp)
ffffffffc0200d20:	7342                	ld	t1,48(sp)
ffffffffc0200d22:	73e2                	ld	t2,56(sp)
ffffffffc0200d24:	6406                	ld	s0,64(sp)
ffffffffc0200d26:	64a6                	ld	s1,72(sp)
ffffffffc0200d28:	6546                	ld	a0,80(sp)
ffffffffc0200d2a:	65e6                	ld	a1,88(sp)
ffffffffc0200d2c:	7606                	ld	a2,96(sp)
ffffffffc0200d2e:	76a6                	ld	a3,104(sp)
ffffffffc0200d30:	7746                	ld	a4,112(sp)
ffffffffc0200d32:	77e6                	ld	a5,120(sp)
ffffffffc0200d34:	680a                	ld	a6,128(sp)
ffffffffc0200d36:	68aa                	ld	a7,136(sp)
ffffffffc0200d38:	694a                	ld	s2,144(sp)
ffffffffc0200d3a:	69ea                	ld	s3,152(sp)
ffffffffc0200d3c:	7a0a                	ld	s4,160(sp)
ffffffffc0200d3e:	7aaa                	ld	s5,168(sp)
ffffffffc0200d40:	7b4a                	ld	s6,176(sp)
ffffffffc0200d42:	7bea                	ld	s7,184(sp)
ffffffffc0200d44:	6c0e                	ld	s8,192(sp)
ffffffffc0200d46:	6cae                	ld	s9,200(sp)
ffffffffc0200d48:	6d4e                	ld	s10,208(sp)
ffffffffc0200d4a:	6dee                	ld	s11,216(sp)
ffffffffc0200d4c:	7e0e                	ld	t3,224(sp)
ffffffffc0200d4e:	7eae                	ld	t4,232(sp)
ffffffffc0200d50:	7f4e                	ld	t5,240(sp)
ffffffffc0200d52:	7fee                	ld	t6,248(sp)
ffffffffc0200d54:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200d56:	10200073          	sret

ffffffffc0200d5a <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d5a:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d5c:	b755                	j	ffffffffc0200d00 <__trapret>

ffffffffc0200d5e <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200d5e:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6730>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200d62:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200d66:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200d6a:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200d6e:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200d72:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200d76:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200d7a:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200d7e:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200d82:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200d84:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200d86:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200d88:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200d8a:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200d8c:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200d8e:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200d90:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200d92:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200d94:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200d96:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200d98:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200d9a:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200d9c:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200d9e:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200da0:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200da2:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200da4:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200da6:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200da8:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200daa:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200dac:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200dae:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200db0:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200db2:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200db4:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200db6:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200db8:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200dba:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200dbc:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200dbe:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200dc0:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200dc2:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200dc4:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200dc6:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200dc8:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200dca:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200dcc:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200dce:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200dd0:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200dd2:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200dd4:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200dd6:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200dd8:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200dda:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200ddc:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200dde:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200de0:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200de2:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200de4:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200de6:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200de8:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200dea:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200dec:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200dee:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200df0:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200df2:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200df4:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200df6:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200df8:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200dfa:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200dfc:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200dfe:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e00:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e02:	812e                	mv	sp,a1
ffffffffc0200e04:	bdf5                	j	ffffffffc0200d00 <__trapret>

ffffffffc0200e06 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e06:	00099797          	auipc	a5,0x99
ffffffffc0200e0a:	db278793          	addi	a5,a5,-590 # ffffffffc0299bb8 <free_area>
ffffffffc0200e0e:	e79c                	sd	a5,8(a5)
ffffffffc0200e10:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e12:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e16:	8082                	ret

ffffffffc0200e18 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e18:	00099517          	auipc	a0,0x99
ffffffffc0200e1c:	db056503          	lwu	a0,-592(a0) # ffffffffc0299bc8 <free_area+0x10>
ffffffffc0200e20:	8082                	ret

ffffffffc0200e22 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e22:	715d                	addi	sp,sp,-80
ffffffffc0200e24:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e26:	00099417          	auipc	s0,0x99
ffffffffc0200e2a:	d9240413          	addi	s0,s0,-622 # ffffffffc0299bb8 <free_area>
ffffffffc0200e2e:	641c                	ld	a5,8(s0)
ffffffffc0200e30:	e486                	sd	ra,72(sp)
ffffffffc0200e32:	fc26                	sd	s1,56(sp)
ffffffffc0200e34:	f84a                	sd	s2,48(sp)
ffffffffc0200e36:	f44e                	sd	s3,40(sp)
ffffffffc0200e38:	f052                	sd	s4,32(sp)
ffffffffc0200e3a:	ec56                	sd	s5,24(sp)
ffffffffc0200e3c:	e85a                	sd	s6,16(sp)
ffffffffc0200e3e:	e45e                	sd	s7,8(sp)
ffffffffc0200e40:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e42:	2a878963          	beq	a5,s0,ffffffffc02010f4 <default_check+0x2d2>
    int count = 0, total = 0;
ffffffffc0200e46:	4481                	li	s1,0
ffffffffc0200e48:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e4a:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e4e:	8b09                	andi	a4,a4,2
ffffffffc0200e50:	2a070663          	beqz	a4,ffffffffc02010fc <default_check+0x2da>
        count ++, total += p->property;
ffffffffc0200e54:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e58:	679c                	ld	a5,8(a5)
ffffffffc0200e5a:	2905                	addiw	s2,s2,1
ffffffffc0200e5c:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e5e:	fe8796e3          	bne	a5,s0,ffffffffc0200e4a <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e62:	89a6                	mv	s3,s1
ffffffffc0200e64:	70d000ef          	jal	ffffffffc0201d70 <nr_free_pages>
ffffffffc0200e68:	6f351a63          	bne	a0,s3,ffffffffc020155c <default_check+0x73a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e6c:	4505                	li	a0,1
ffffffffc0200e6e:	633000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200e72:	8aaa                	mv	s5,a0
ffffffffc0200e74:	42050463          	beqz	a0,ffffffffc020129c <default_check+0x47a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e78:	4505                	li	a0,1
ffffffffc0200e7a:	627000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200e7e:	89aa                	mv	s3,a0
ffffffffc0200e80:	6e050e63          	beqz	a0,ffffffffc020157c <default_check+0x75a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e84:	4505                	li	a0,1
ffffffffc0200e86:	61b000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200e8a:	8a2a                	mv	s4,a0
ffffffffc0200e8c:	48050863          	beqz	a0,ffffffffc020131c <default_check+0x4fa>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e90:	293a8663          	beq	s5,s3,ffffffffc020111c <default_check+0x2fa>
ffffffffc0200e94:	28aa8463          	beq	s5,a0,ffffffffc020111c <default_check+0x2fa>
ffffffffc0200e98:	28a98263          	beq	s3,a0,ffffffffc020111c <default_check+0x2fa>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e9c:	000aa783          	lw	a5,0(s5)
ffffffffc0200ea0:	28079e63          	bnez	a5,ffffffffc020113c <default_check+0x31a>
ffffffffc0200ea4:	0009a783          	lw	a5,0(s3)
ffffffffc0200ea8:	28079a63          	bnez	a5,ffffffffc020113c <default_check+0x31a>
ffffffffc0200eac:	411c                	lw	a5,0(a0)
ffffffffc0200eae:	28079763          	bnez	a5,ffffffffc020113c <default_check+0x31a>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200eb2:	0009d797          	auipc	a5,0x9d
ffffffffc0200eb6:	e167b783          	ld	a5,-490(a5) # ffffffffc029dcc8 <pages>
ffffffffc0200eba:	40fa8733          	sub	a4,s5,a5
ffffffffc0200ebe:	00008617          	auipc	a2,0x8
ffffffffc0200ec2:	ff263603          	ld	a2,-14(a2) # ffffffffc0208eb0 <nbase>
ffffffffc0200ec6:	8719                	srai	a4,a4,0x6
ffffffffc0200ec8:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200eca:	0009d697          	auipc	a3,0x9d
ffffffffc0200ece:	df66b683          	ld	a3,-522(a3) # ffffffffc029dcc0 <npage>
ffffffffc0200ed2:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ed4:	0732                	slli	a4,a4,0xc
ffffffffc0200ed6:	28d77363          	bgeu	a4,a3,ffffffffc020115c <default_check+0x33a>
    return page - pages + nbase;
ffffffffc0200eda:	40f98733          	sub	a4,s3,a5
ffffffffc0200ede:	8719                	srai	a4,a4,0x6
ffffffffc0200ee0:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ee2:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200ee4:	4ad77c63          	bgeu	a4,a3,ffffffffc020139c <default_check+0x57a>
    return page - pages + nbase;
ffffffffc0200ee8:	40f507b3          	sub	a5,a0,a5
ffffffffc0200eec:	8799                	srai	a5,a5,0x6
ffffffffc0200eee:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ef0:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ef2:	30d7f563          	bgeu	a5,a3,ffffffffc02011fc <default_check+0x3da>
    assert(alloc_page() == NULL);
ffffffffc0200ef6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ef8:	00043c03          	ld	s8,0(s0)
ffffffffc0200efc:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f00:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200f04:	e400                	sd	s0,8(s0)
ffffffffc0200f06:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f08:	00099797          	auipc	a5,0x99
ffffffffc0200f0c:	cc07a023          	sw	zero,-832(a5) # ffffffffc0299bc8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f10:	591000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f14:	2c051463          	bnez	a0,ffffffffc02011dc <default_check+0x3ba>
    free_page(p0);
ffffffffc0200f18:	4585                	li	a1,1
ffffffffc0200f1a:	8556                	mv	a0,s5
ffffffffc0200f1c:	615000ef          	jal	ffffffffc0201d30 <free_pages>
    free_page(p1);
ffffffffc0200f20:	4585                	li	a1,1
ffffffffc0200f22:	854e                	mv	a0,s3
ffffffffc0200f24:	60d000ef          	jal	ffffffffc0201d30 <free_pages>
    free_page(p2);
ffffffffc0200f28:	4585                	li	a1,1
ffffffffc0200f2a:	8552                	mv	a0,s4
ffffffffc0200f2c:	605000ef          	jal	ffffffffc0201d30 <free_pages>
    assert(nr_free == 3);
ffffffffc0200f30:	4818                	lw	a4,16(s0)
ffffffffc0200f32:	478d                	li	a5,3
ffffffffc0200f34:	28f71463          	bne	a4,a5,ffffffffc02011bc <default_check+0x39a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f38:	4505                	li	a0,1
ffffffffc0200f3a:	567000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f3e:	89aa                	mv	s3,a0
ffffffffc0200f40:	24050e63          	beqz	a0,ffffffffc020119c <default_check+0x37a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f44:	4505                	li	a0,1
ffffffffc0200f46:	55b000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f4a:	8aaa                	mv	s5,a0
ffffffffc0200f4c:	3a050863          	beqz	a0,ffffffffc02012fc <default_check+0x4da>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f50:	4505                	li	a0,1
ffffffffc0200f52:	54f000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f56:	8a2a                	mv	s4,a0
ffffffffc0200f58:	38050263          	beqz	a0,ffffffffc02012dc <default_check+0x4ba>
    assert(alloc_page() == NULL);
ffffffffc0200f5c:	4505                	li	a0,1
ffffffffc0200f5e:	543000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f62:	34051d63          	bnez	a0,ffffffffc02012bc <default_check+0x49a>
    free_page(p0);
ffffffffc0200f66:	4585                	li	a1,1
ffffffffc0200f68:	854e                	mv	a0,s3
ffffffffc0200f6a:	5c7000ef          	jal	ffffffffc0201d30 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f6e:	641c                	ld	a5,8(s0)
ffffffffc0200f70:	20878663          	beq	a5,s0,ffffffffc020117c <default_check+0x35a>
    assert((p = alloc_page()) == p0);
ffffffffc0200f74:	4505                	li	a0,1
ffffffffc0200f76:	52b000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f7a:	30a99163          	bne	s3,a0,ffffffffc020127c <default_check+0x45a>
    assert(alloc_page() == NULL);
ffffffffc0200f7e:	4505                	li	a0,1
ffffffffc0200f80:	521000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f84:	2c051c63          	bnez	a0,ffffffffc020125c <default_check+0x43a>
    assert(nr_free == 0);
ffffffffc0200f88:	481c                	lw	a5,16(s0)
ffffffffc0200f8a:	2a079963          	bnez	a5,ffffffffc020123c <default_check+0x41a>
    free_page(p);
ffffffffc0200f8e:	854e                	mv	a0,s3
ffffffffc0200f90:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f92:	01843023          	sd	s8,0(s0)
ffffffffc0200f96:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f9a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f9e:	593000ef          	jal	ffffffffc0201d30 <free_pages>
    free_page(p1);
ffffffffc0200fa2:	4585                	li	a1,1
ffffffffc0200fa4:	8556                	mv	a0,s5
ffffffffc0200fa6:	58b000ef          	jal	ffffffffc0201d30 <free_pages>
    free_page(p2);
ffffffffc0200faa:	4585                	li	a1,1
ffffffffc0200fac:	8552                	mv	a0,s4
ffffffffc0200fae:	583000ef          	jal	ffffffffc0201d30 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200fb2:	4515                	li	a0,5
ffffffffc0200fb4:	4ed000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200fb8:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200fba:	26050163          	beqz	a0,ffffffffc020121c <default_check+0x3fa>
ffffffffc0200fbe:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc0200fc0:	8b89                	andi	a5,a5,2
ffffffffc0200fc2:	52079d63          	bnez	a5,ffffffffc02014fc <default_check+0x6da>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200fc6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fc8:	00043b83          	ld	s7,0(s0)
ffffffffc0200fcc:	00843b03          	ld	s6,8(s0)
ffffffffc0200fd0:	e000                	sd	s0,0(s0)
ffffffffc0200fd2:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200fd4:	4cd000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200fd8:	50051263          	bnez	a0,ffffffffc02014dc <default_check+0x6ba>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200fdc:	08098a13          	addi	s4,s3,128
ffffffffc0200fe0:	8552                	mv	a0,s4
ffffffffc0200fe2:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200fe4:	01042c03          	lw	s8,16(s0)
    nr_free = 0;
ffffffffc0200fe8:	00099797          	auipc	a5,0x99
ffffffffc0200fec:	be07a023          	sw	zero,-1056(a5) # ffffffffc0299bc8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200ff0:	541000ef          	jal	ffffffffc0201d30 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ff4:	4511                	li	a0,4
ffffffffc0200ff6:	4ab000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0200ffa:	4c051163          	bnez	a0,ffffffffc02014bc <default_check+0x69a>
ffffffffc0200ffe:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201002:	8b89                	andi	a5,a5,2
ffffffffc0201004:	48078c63          	beqz	a5,ffffffffc020149c <default_check+0x67a>
ffffffffc0201008:	0909a703          	lw	a4,144(s3)
ffffffffc020100c:	478d                	li	a5,3
ffffffffc020100e:	48f71763          	bne	a4,a5,ffffffffc020149c <default_check+0x67a>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201012:	450d                	li	a0,3
ffffffffc0201014:	48d000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0201018:	8aaa                	mv	s5,a0
ffffffffc020101a:	46050163          	beqz	a0,ffffffffc020147c <default_check+0x65a>
    assert(alloc_page() == NULL);
ffffffffc020101e:	4505                	li	a0,1
ffffffffc0201020:	481000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0201024:	42051c63          	bnez	a0,ffffffffc020145c <default_check+0x63a>
    assert(p0 + 2 == p1);
ffffffffc0201028:	415a1a63          	bne	s4,s5,ffffffffc020143c <default_check+0x61a>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020102c:	4585                	li	a1,1
ffffffffc020102e:	854e                	mv	a0,s3
ffffffffc0201030:	501000ef          	jal	ffffffffc0201d30 <free_pages>
    free_pages(p1, 3);
ffffffffc0201034:	458d                	li	a1,3
ffffffffc0201036:	8552                	mv	a0,s4
ffffffffc0201038:	4f9000ef          	jal	ffffffffc0201d30 <free_pages>
ffffffffc020103c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201040:	04098a93          	addi	s5,s3,64
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201044:	8b89                	andi	a5,a5,2
ffffffffc0201046:	3c078b63          	beqz	a5,ffffffffc020141c <default_check+0x5fa>
ffffffffc020104a:	0109a703          	lw	a4,16(s3)
ffffffffc020104e:	4785                	li	a5,1
ffffffffc0201050:	3cf71663          	bne	a4,a5,ffffffffc020141c <default_check+0x5fa>
ffffffffc0201054:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201058:	8b89                	andi	a5,a5,2
ffffffffc020105a:	3a078163          	beqz	a5,ffffffffc02013fc <default_check+0x5da>
ffffffffc020105e:	010a2703          	lw	a4,16(s4)
ffffffffc0201062:	478d                	li	a5,3
ffffffffc0201064:	38f71c63          	bne	a4,a5,ffffffffc02013fc <default_check+0x5da>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201068:	4505                	li	a0,1
ffffffffc020106a:	437000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc020106e:	36a99763          	bne	s3,a0,ffffffffc02013dc <default_check+0x5ba>
    free_page(p0);
ffffffffc0201072:	4585                	li	a1,1
ffffffffc0201074:	4bd000ef          	jal	ffffffffc0201d30 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201078:	4509                	li	a0,2
ffffffffc020107a:	427000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc020107e:	32aa1f63          	bne	s4,a0,ffffffffc02013bc <default_check+0x59a>

    free_pages(p0, 2);
ffffffffc0201082:	4589                	li	a1,2
ffffffffc0201084:	4ad000ef          	jal	ffffffffc0201d30 <free_pages>
    free_page(p2);
ffffffffc0201088:	4585                	li	a1,1
ffffffffc020108a:	8556                	mv	a0,s5
ffffffffc020108c:	4a5000ef          	jal	ffffffffc0201d30 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201090:	4515                	li	a0,5
ffffffffc0201092:	40f000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0201096:	89aa                	mv	s3,a0
ffffffffc0201098:	48050263          	beqz	a0,ffffffffc020151c <default_check+0x6fa>
    assert(alloc_page() == NULL);
ffffffffc020109c:	4505                	li	a0,1
ffffffffc020109e:	403000ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc02010a2:	2c051d63          	bnez	a0,ffffffffc020137c <default_check+0x55a>

    assert(nr_free == 0);
ffffffffc02010a6:	481c                	lw	a5,16(s0)
ffffffffc02010a8:	2a079a63          	bnez	a5,ffffffffc020135c <default_check+0x53a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02010ac:	4595                	li	a1,5
ffffffffc02010ae:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02010b0:	01842823          	sw	s8,16(s0)
    free_list = free_list_store;
ffffffffc02010b4:	01743023          	sd	s7,0(s0)
ffffffffc02010b8:	01643423          	sd	s6,8(s0)
    free_pages(p0, 5);
ffffffffc02010bc:	475000ef          	jal	ffffffffc0201d30 <free_pages>
    return listelm->next;
ffffffffc02010c0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010c2:	00878963          	beq	a5,s0,ffffffffc02010d4 <default_check+0x2b2>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02010c6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010ca:	679c                	ld	a5,8(a5)
ffffffffc02010cc:	397d                	addiw	s2,s2,-1
ffffffffc02010ce:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010d0:	fe879be3          	bne	a5,s0,ffffffffc02010c6 <default_check+0x2a4>
    }
    assert(count == 0);
ffffffffc02010d4:	26091463          	bnez	s2,ffffffffc020133c <default_check+0x51a>
    assert(total == 0);
ffffffffc02010d8:	46049263          	bnez	s1,ffffffffc020153c <default_check+0x71a>
}
ffffffffc02010dc:	60a6                	ld	ra,72(sp)
ffffffffc02010de:	6406                	ld	s0,64(sp)
ffffffffc02010e0:	74e2                	ld	s1,56(sp)
ffffffffc02010e2:	7942                	ld	s2,48(sp)
ffffffffc02010e4:	79a2                	ld	s3,40(sp)
ffffffffc02010e6:	7a02                	ld	s4,32(sp)
ffffffffc02010e8:	6ae2                	ld	s5,24(sp)
ffffffffc02010ea:	6b42                	ld	s6,16(sp)
ffffffffc02010ec:	6ba2                	ld	s7,8(sp)
ffffffffc02010ee:	6c02                	ld	s8,0(sp)
ffffffffc02010f0:	6161                	addi	sp,sp,80
ffffffffc02010f2:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010f4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02010f6:	4481                	li	s1,0
ffffffffc02010f8:	4901                	li	s2,0
ffffffffc02010fa:	b3ad                	j	ffffffffc0200e64 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02010fc:	00006697          	auipc	a3,0x6
ffffffffc0201100:	fbc68693          	addi	a3,a3,-68 # ffffffffc02070b8 <etext+0x8fc>
ffffffffc0201104:	00006617          	auipc	a2,0x6
ffffffffc0201108:	d3460613          	addi	a2,a2,-716 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020110c:	0f000593          	li	a1,240
ffffffffc0201110:	00006517          	auipc	a0,0x6
ffffffffc0201114:	fb850513          	addi	a0,a0,-72 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201118:	b5cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020111c:	00006697          	auipc	a3,0x6
ffffffffc0201120:	04468693          	addi	a3,a3,68 # ffffffffc0207160 <etext+0x9a4>
ffffffffc0201124:	00006617          	auipc	a2,0x6
ffffffffc0201128:	d1460613          	addi	a2,a2,-748 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020112c:	0bd00593          	li	a1,189
ffffffffc0201130:	00006517          	auipc	a0,0x6
ffffffffc0201134:	f9850513          	addi	a0,a0,-104 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201138:	b3cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020113c:	00006697          	auipc	a3,0x6
ffffffffc0201140:	04c68693          	addi	a3,a3,76 # ffffffffc0207188 <etext+0x9cc>
ffffffffc0201144:	00006617          	auipc	a2,0x6
ffffffffc0201148:	cf460613          	addi	a2,a2,-780 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020114c:	0be00593          	li	a1,190
ffffffffc0201150:	00006517          	auipc	a0,0x6
ffffffffc0201154:	f7850513          	addi	a0,a0,-136 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201158:	b1cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020115c:	00006697          	auipc	a3,0x6
ffffffffc0201160:	06c68693          	addi	a3,a3,108 # ffffffffc02071c8 <etext+0xa0c>
ffffffffc0201164:	00006617          	auipc	a2,0x6
ffffffffc0201168:	cd460613          	addi	a2,a2,-812 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020116c:	0c000593          	li	a1,192
ffffffffc0201170:	00006517          	auipc	a0,0x6
ffffffffc0201174:	f5850513          	addi	a0,a0,-168 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201178:	afcff0ef          	jal	ffffffffc0200474 <__panic>
    assert(!list_empty(&free_list));
ffffffffc020117c:	00006697          	auipc	a3,0x6
ffffffffc0201180:	0d468693          	addi	a3,a3,212 # ffffffffc0207250 <etext+0xa94>
ffffffffc0201184:	00006617          	auipc	a2,0x6
ffffffffc0201188:	cb460613          	addi	a2,a2,-844 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020118c:	0d900593          	li	a1,217
ffffffffc0201190:	00006517          	auipc	a0,0x6
ffffffffc0201194:	f3850513          	addi	a0,a0,-200 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201198:	adcff0ef          	jal	ffffffffc0200474 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020119c:	00006697          	auipc	a3,0x6
ffffffffc02011a0:	f6468693          	addi	a3,a3,-156 # ffffffffc0207100 <etext+0x944>
ffffffffc02011a4:	00006617          	auipc	a2,0x6
ffffffffc02011a8:	c9460613          	addi	a2,a2,-876 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02011ac:	0d200593          	li	a1,210
ffffffffc02011b0:	00006517          	auipc	a0,0x6
ffffffffc02011b4:	f1850513          	addi	a0,a0,-232 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02011b8:	abcff0ef          	jal	ffffffffc0200474 <__panic>
    assert(nr_free == 3);
ffffffffc02011bc:	00006697          	auipc	a3,0x6
ffffffffc02011c0:	08468693          	addi	a3,a3,132 # ffffffffc0207240 <etext+0xa84>
ffffffffc02011c4:	00006617          	auipc	a2,0x6
ffffffffc02011c8:	c7460613          	addi	a2,a2,-908 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02011cc:	0d000593          	li	a1,208
ffffffffc02011d0:	00006517          	auipc	a0,0x6
ffffffffc02011d4:	ef850513          	addi	a0,a0,-264 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02011d8:	a9cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011dc:	00006697          	auipc	a3,0x6
ffffffffc02011e0:	04c68693          	addi	a3,a3,76 # ffffffffc0207228 <etext+0xa6c>
ffffffffc02011e4:	00006617          	auipc	a2,0x6
ffffffffc02011e8:	c5460613          	addi	a2,a2,-940 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02011ec:	0cb00593          	li	a1,203
ffffffffc02011f0:	00006517          	auipc	a0,0x6
ffffffffc02011f4:	ed850513          	addi	a0,a0,-296 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02011f8:	a7cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011fc:	00006697          	auipc	a3,0x6
ffffffffc0201200:	00c68693          	addi	a3,a3,12 # ffffffffc0207208 <etext+0xa4c>
ffffffffc0201204:	00006617          	auipc	a2,0x6
ffffffffc0201208:	c3460613          	addi	a2,a2,-972 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020120c:	0c200593          	li	a1,194
ffffffffc0201210:	00006517          	auipc	a0,0x6
ffffffffc0201214:	eb850513          	addi	a0,a0,-328 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201218:	a5cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(p0 != NULL);
ffffffffc020121c:	00006697          	auipc	a3,0x6
ffffffffc0201220:	07c68693          	addi	a3,a3,124 # ffffffffc0207298 <etext+0xadc>
ffffffffc0201224:	00006617          	auipc	a2,0x6
ffffffffc0201228:	c1460613          	addi	a2,a2,-1004 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020122c:	0f800593          	li	a1,248
ffffffffc0201230:	00006517          	auipc	a0,0x6
ffffffffc0201234:	e9850513          	addi	a0,a0,-360 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201238:	a3cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(nr_free == 0);
ffffffffc020123c:	00006697          	auipc	a3,0x6
ffffffffc0201240:	04c68693          	addi	a3,a3,76 # ffffffffc0207288 <etext+0xacc>
ffffffffc0201244:	00006617          	auipc	a2,0x6
ffffffffc0201248:	bf460613          	addi	a2,a2,-1036 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020124c:	0df00593          	li	a1,223
ffffffffc0201250:	00006517          	auipc	a0,0x6
ffffffffc0201254:	e7850513          	addi	a0,a0,-392 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201258:	a1cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020125c:	00006697          	auipc	a3,0x6
ffffffffc0201260:	fcc68693          	addi	a3,a3,-52 # ffffffffc0207228 <etext+0xa6c>
ffffffffc0201264:	00006617          	auipc	a2,0x6
ffffffffc0201268:	bd460613          	addi	a2,a2,-1068 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020126c:	0dd00593          	li	a1,221
ffffffffc0201270:	00006517          	auipc	a0,0x6
ffffffffc0201274:	e5850513          	addi	a0,a0,-424 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201278:	9fcff0ef          	jal	ffffffffc0200474 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020127c:	00006697          	auipc	a3,0x6
ffffffffc0201280:	fec68693          	addi	a3,a3,-20 # ffffffffc0207268 <etext+0xaac>
ffffffffc0201284:	00006617          	auipc	a2,0x6
ffffffffc0201288:	bb460613          	addi	a2,a2,-1100 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020128c:	0dc00593          	li	a1,220
ffffffffc0201290:	00006517          	auipc	a0,0x6
ffffffffc0201294:	e3850513          	addi	a0,a0,-456 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201298:	9dcff0ef          	jal	ffffffffc0200474 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020129c:	00006697          	auipc	a3,0x6
ffffffffc02012a0:	e6468693          	addi	a3,a3,-412 # ffffffffc0207100 <etext+0x944>
ffffffffc02012a4:	00006617          	auipc	a2,0x6
ffffffffc02012a8:	b9460613          	addi	a2,a2,-1132 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02012ac:	0b900593          	li	a1,185
ffffffffc02012b0:	00006517          	auipc	a0,0x6
ffffffffc02012b4:	e1850513          	addi	a0,a0,-488 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02012b8:	9bcff0ef          	jal	ffffffffc0200474 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012bc:	00006697          	auipc	a3,0x6
ffffffffc02012c0:	f6c68693          	addi	a3,a3,-148 # ffffffffc0207228 <etext+0xa6c>
ffffffffc02012c4:	00006617          	auipc	a2,0x6
ffffffffc02012c8:	b7460613          	addi	a2,a2,-1164 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02012cc:	0d600593          	li	a1,214
ffffffffc02012d0:	00006517          	auipc	a0,0x6
ffffffffc02012d4:	df850513          	addi	a0,a0,-520 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02012d8:	99cff0ef          	jal	ffffffffc0200474 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012dc:	00006697          	auipc	a3,0x6
ffffffffc02012e0:	e6468693          	addi	a3,a3,-412 # ffffffffc0207140 <etext+0x984>
ffffffffc02012e4:	00006617          	auipc	a2,0x6
ffffffffc02012e8:	b5460613          	addi	a2,a2,-1196 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02012ec:	0d400593          	li	a1,212
ffffffffc02012f0:	00006517          	auipc	a0,0x6
ffffffffc02012f4:	dd850513          	addi	a0,a0,-552 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02012f8:	97cff0ef          	jal	ffffffffc0200474 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012fc:	00006697          	auipc	a3,0x6
ffffffffc0201300:	e2468693          	addi	a3,a3,-476 # ffffffffc0207120 <etext+0x964>
ffffffffc0201304:	00006617          	auipc	a2,0x6
ffffffffc0201308:	b3460613          	addi	a2,a2,-1228 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020130c:	0d300593          	li	a1,211
ffffffffc0201310:	00006517          	auipc	a0,0x6
ffffffffc0201314:	db850513          	addi	a0,a0,-584 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201318:	95cff0ef          	jal	ffffffffc0200474 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020131c:	00006697          	auipc	a3,0x6
ffffffffc0201320:	e2468693          	addi	a3,a3,-476 # ffffffffc0207140 <etext+0x984>
ffffffffc0201324:	00006617          	auipc	a2,0x6
ffffffffc0201328:	b1460613          	addi	a2,a2,-1260 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020132c:	0bb00593          	li	a1,187
ffffffffc0201330:	00006517          	auipc	a0,0x6
ffffffffc0201334:	d9850513          	addi	a0,a0,-616 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201338:	93cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(count == 0);
ffffffffc020133c:	00006697          	auipc	a3,0x6
ffffffffc0201340:	0ac68693          	addi	a3,a3,172 # ffffffffc02073e8 <etext+0xc2c>
ffffffffc0201344:	00006617          	auipc	a2,0x6
ffffffffc0201348:	af460613          	addi	a2,a2,-1292 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020134c:	12500593          	li	a1,293
ffffffffc0201350:	00006517          	auipc	a0,0x6
ffffffffc0201354:	d7850513          	addi	a0,a0,-648 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201358:	91cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(nr_free == 0);
ffffffffc020135c:	00006697          	auipc	a3,0x6
ffffffffc0201360:	f2c68693          	addi	a3,a3,-212 # ffffffffc0207288 <etext+0xacc>
ffffffffc0201364:	00006617          	auipc	a2,0x6
ffffffffc0201368:	ad460613          	addi	a2,a2,-1324 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020136c:	11a00593          	li	a1,282
ffffffffc0201370:	00006517          	auipc	a0,0x6
ffffffffc0201374:	d5850513          	addi	a0,a0,-680 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201378:	8fcff0ef          	jal	ffffffffc0200474 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020137c:	00006697          	auipc	a3,0x6
ffffffffc0201380:	eac68693          	addi	a3,a3,-340 # ffffffffc0207228 <etext+0xa6c>
ffffffffc0201384:	00006617          	auipc	a2,0x6
ffffffffc0201388:	ab460613          	addi	a2,a2,-1356 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020138c:	11800593          	li	a1,280
ffffffffc0201390:	00006517          	auipc	a0,0x6
ffffffffc0201394:	d3850513          	addi	a0,a0,-712 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201398:	8dcff0ef          	jal	ffffffffc0200474 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020139c:	00006697          	auipc	a3,0x6
ffffffffc02013a0:	e4c68693          	addi	a3,a3,-436 # ffffffffc02071e8 <etext+0xa2c>
ffffffffc02013a4:	00006617          	auipc	a2,0x6
ffffffffc02013a8:	a9460613          	addi	a2,a2,-1388 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02013ac:	0c100593          	li	a1,193
ffffffffc02013b0:	00006517          	auipc	a0,0x6
ffffffffc02013b4:	d1850513          	addi	a0,a0,-744 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02013b8:	8bcff0ef          	jal	ffffffffc0200474 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02013bc:	00006697          	auipc	a3,0x6
ffffffffc02013c0:	fec68693          	addi	a3,a3,-20 # ffffffffc02073a8 <etext+0xbec>
ffffffffc02013c4:	00006617          	auipc	a2,0x6
ffffffffc02013c8:	a7460613          	addi	a2,a2,-1420 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02013cc:	11200593          	li	a1,274
ffffffffc02013d0:	00006517          	auipc	a0,0x6
ffffffffc02013d4:	cf850513          	addi	a0,a0,-776 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02013d8:	89cff0ef          	jal	ffffffffc0200474 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02013dc:	00006697          	auipc	a3,0x6
ffffffffc02013e0:	fac68693          	addi	a3,a3,-84 # ffffffffc0207388 <etext+0xbcc>
ffffffffc02013e4:	00006617          	auipc	a2,0x6
ffffffffc02013e8:	a5460613          	addi	a2,a2,-1452 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02013ec:	11000593          	li	a1,272
ffffffffc02013f0:	00006517          	auipc	a0,0x6
ffffffffc02013f4:	cd850513          	addi	a0,a0,-808 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02013f8:	87cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02013fc:	00006697          	auipc	a3,0x6
ffffffffc0201400:	f6468693          	addi	a3,a3,-156 # ffffffffc0207360 <etext+0xba4>
ffffffffc0201404:	00006617          	auipc	a2,0x6
ffffffffc0201408:	a3460613          	addi	a2,a2,-1484 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020140c:	10e00593          	li	a1,270
ffffffffc0201410:	00006517          	auipc	a0,0x6
ffffffffc0201414:	cb850513          	addi	a0,a0,-840 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201418:	85cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020141c:	00006697          	auipc	a3,0x6
ffffffffc0201420:	f1c68693          	addi	a3,a3,-228 # ffffffffc0207338 <etext+0xb7c>
ffffffffc0201424:	00006617          	auipc	a2,0x6
ffffffffc0201428:	a1460613          	addi	a2,a2,-1516 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020142c:	10d00593          	li	a1,269
ffffffffc0201430:	00006517          	auipc	a0,0x6
ffffffffc0201434:	c9850513          	addi	a0,a0,-872 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201438:	83cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(p0 + 2 == p1);
ffffffffc020143c:	00006697          	auipc	a3,0x6
ffffffffc0201440:	eec68693          	addi	a3,a3,-276 # ffffffffc0207328 <etext+0xb6c>
ffffffffc0201444:	00006617          	auipc	a2,0x6
ffffffffc0201448:	9f460613          	addi	a2,a2,-1548 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020144c:	10800593          	li	a1,264
ffffffffc0201450:	00006517          	auipc	a0,0x6
ffffffffc0201454:	c7850513          	addi	a0,a0,-904 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201458:	81cff0ef          	jal	ffffffffc0200474 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020145c:	00006697          	auipc	a3,0x6
ffffffffc0201460:	dcc68693          	addi	a3,a3,-564 # ffffffffc0207228 <etext+0xa6c>
ffffffffc0201464:	00006617          	auipc	a2,0x6
ffffffffc0201468:	9d460613          	addi	a2,a2,-1580 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020146c:	10700593          	li	a1,263
ffffffffc0201470:	00006517          	auipc	a0,0x6
ffffffffc0201474:	c5850513          	addi	a0,a0,-936 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201478:	ffdfe0ef          	jal	ffffffffc0200474 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020147c:	00006697          	auipc	a3,0x6
ffffffffc0201480:	e8c68693          	addi	a3,a3,-372 # ffffffffc0207308 <etext+0xb4c>
ffffffffc0201484:	00006617          	auipc	a2,0x6
ffffffffc0201488:	9b460613          	addi	a2,a2,-1612 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020148c:	10600593          	li	a1,262
ffffffffc0201490:	00006517          	auipc	a0,0x6
ffffffffc0201494:	c3850513          	addi	a0,a0,-968 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201498:	fddfe0ef          	jal	ffffffffc0200474 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020149c:	00006697          	auipc	a3,0x6
ffffffffc02014a0:	e3c68693          	addi	a3,a3,-452 # ffffffffc02072d8 <etext+0xb1c>
ffffffffc02014a4:	00006617          	auipc	a2,0x6
ffffffffc02014a8:	99460613          	addi	a2,a2,-1644 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02014ac:	10500593          	li	a1,261
ffffffffc02014b0:	00006517          	auipc	a0,0x6
ffffffffc02014b4:	c1850513          	addi	a0,a0,-1000 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02014b8:	fbdfe0ef          	jal	ffffffffc0200474 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02014bc:	00006697          	auipc	a3,0x6
ffffffffc02014c0:	e0468693          	addi	a3,a3,-508 # ffffffffc02072c0 <etext+0xb04>
ffffffffc02014c4:	00006617          	auipc	a2,0x6
ffffffffc02014c8:	97460613          	addi	a2,a2,-1676 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02014cc:	10400593          	li	a1,260
ffffffffc02014d0:	00006517          	auipc	a0,0x6
ffffffffc02014d4:	bf850513          	addi	a0,a0,-1032 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02014d8:	f9dfe0ef          	jal	ffffffffc0200474 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014dc:	00006697          	auipc	a3,0x6
ffffffffc02014e0:	d4c68693          	addi	a3,a3,-692 # ffffffffc0207228 <etext+0xa6c>
ffffffffc02014e4:	00006617          	auipc	a2,0x6
ffffffffc02014e8:	95460613          	addi	a2,a2,-1708 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02014ec:	0fe00593          	li	a1,254
ffffffffc02014f0:	00006517          	auipc	a0,0x6
ffffffffc02014f4:	bd850513          	addi	a0,a0,-1064 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02014f8:	f7dfe0ef          	jal	ffffffffc0200474 <__panic>
    assert(!PageProperty(p0));
ffffffffc02014fc:	00006697          	auipc	a3,0x6
ffffffffc0201500:	dac68693          	addi	a3,a3,-596 # ffffffffc02072a8 <etext+0xaec>
ffffffffc0201504:	00006617          	auipc	a2,0x6
ffffffffc0201508:	93460613          	addi	a2,a2,-1740 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020150c:	0f900593          	li	a1,249
ffffffffc0201510:	00006517          	auipc	a0,0x6
ffffffffc0201514:	bb850513          	addi	a0,a0,-1096 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201518:	f5dfe0ef          	jal	ffffffffc0200474 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020151c:	00006697          	auipc	a3,0x6
ffffffffc0201520:	eac68693          	addi	a3,a3,-340 # ffffffffc02073c8 <etext+0xc0c>
ffffffffc0201524:	00006617          	auipc	a2,0x6
ffffffffc0201528:	91460613          	addi	a2,a2,-1772 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020152c:	11700593          	li	a1,279
ffffffffc0201530:	00006517          	auipc	a0,0x6
ffffffffc0201534:	b9850513          	addi	a0,a0,-1128 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201538:	f3dfe0ef          	jal	ffffffffc0200474 <__panic>
    assert(total == 0);
ffffffffc020153c:	00006697          	auipc	a3,0x6
ffffffffc0201540:	ebc68693          	addi	a3,a3,-324 # ffffffffc02073f8 <etext+0xc3c>
ffffffffc0201544:	00006617          	auipc	a2,0x6
ffffffffc0201548:	8f460613          	addi	a2,a2,-1804 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020154c:	12600593          	li	a1,294
ffffffffc0201550:	00006517          	auipc	a0,0x6
ffffffffc0201554:	b7850513          	addi	a0,a0,-1160 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201558:	f1dfe0ef          	jal	ffffffffc0200474 <__panic>
    assert(total == nr_free_pages());
ffffffffc020155c:	00006697          	auipc	a3,0x6
ffffffffc0201560:	b8468693          	addi	a3,a3,-1148 # ffffffffc02070e0 <etext+0x924>
ffffffffc0201564:	00006617          	auipc	a2,0x6
ffffffffc0201568:	8d460613          	addi	a2,a2,-1836 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020156c:	0f300593          	li	a1,243
ffffffffc0201570:	00006517          	auipc	a0,0x6
ffffffffc0201574:	b5850513          	addi	a0,a0,-1192 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201578:	efdfe0ef          	jal	ffffffffc0200474 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020157c:	00006697          	auipc	a3,0x6
ffffffffc0201580:	ba468693          	addi	a3,a3,-1116 # ffffffffc0207120 <etext+0x964>
ffffffffc0201584:	00006617          	auipc	a2,0x6
ffffffffc0201588:	8b460613          	addi	a2,a2,-1868 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020158c:	0ba00593          	li	a1,186
ffffffffc0201590:	00006517          	auipc	a0,0x6
ffffffffc0201594:	b3850513          	addi	a0,a0,-1224 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201598:	eddfe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc020159c <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc020159c:	1141                	addi	sp,sp,-16
ffffffffc020159e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015a0:	14058463          	beqz	a1,ffffffffc02016e8 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc02015a4:	00659713          	slli	a4,a1,0x6
ffffffffc02015a8:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02015ac:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02015ae:	c30d                	beqz	a4,ffffffffc02015d0 <default_free_pages+0x34>
ffffffffc02015b0:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015b2:	8b05                	andi	a4,a4,1
ffffffffc02015b4:	10071a63          	bnez	a4,ffffffffc02016c8 <default_free_pages+0x12c>
ffffffffc02015b8:	6798                	ld	a4,8(a5)
ffffffffc02015ba:	8b09                	andi	a4,a4,2
ffffffffc02015bc:	10071663          	bnez	a4,ffffffffc02016c8 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02015c0:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc02015c4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015c8:	04078793          	addi	a5,a5,64
ffffffffc02015cc:	fed792e3          	bne	a5,a3,ffffffffc02015b0 <default_free_pages+0x14>
    base->property = n;
ffffffffc02015d0:	2581                	sext.w	a1,a1
ffffffffc02015d2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02015d4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015d8:	4789                	li	a5,2
ffffffffc02015da:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02015de:	00098697          	auipc	a3,0x98
ffffffffc02015e2:	5da68693          	addi	a3,a3,1498 # ffffffffc0299bb8 <free_area>
ffffffffc02015e6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015e8:	669c                	ld	a5,8(a3)
ffffffffc02015ea:	9f2d                	addw	a4,a4,a1
ffffffffc02015ec:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015ee:	0ad78163          	beq	a5,a3,ffffffffc0201690 <default_free_pages+0xf4>
            struct Page* page = le2page(le, page_link);
ffffffffc02015f2:	fe878713          	addi	a4,a5,-24
ffffffffc02015f6:	4581                	li	a1,0
ffffffffc02015f8:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02015fc:	00e56a63          	bltu	a0,a4,ffffffffc0201610 <default_free_pages+0x74>
    return listelm->next;
ffffffffc0201600:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201602:	04d70c63          	beq	a4,a3,ffffffffc020165a <default_free_pages+0xbe>
    struct Page *p = base;
ffffffffc0201606:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201608:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020160c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201600 <default_free_pages+0x64>
ffffffffc0201610:	c199                	beqz	a1,ffffffffc0201616 <default_free_pages+0x7a>
ffffffffc0201612:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201616:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201618:	e390                	sd	a2,0(a5)
ffffffffc020161a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020161c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020161e:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201620:	00d70d63          	beq	a4,a3,ffffffffc020163a <default_free_pages+0x9e>
        if (p + p->property == base) {
ffffffffc0201624:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201628:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc020162c:	02059813          	slli	a6,a1,0x20
ffffffffc0201630:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201634:	97b2                	add	a5,a5,a2
ffffffffc0201636:	02f50c63          	beq	a0,a5,ffffffffc020166e <default_free_pages+0xd2>
    return listelm->next;
ffffffffc020163a:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc020163c:	00d78c63          	beq	a5,a3,ffffffffc0201654 <default_free_pages+0xb8>
        if (base + base->property == p) {
ffffffffc0201640:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201642:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0201646:	02061593          	slli	a1,a2,0x20
ffffffffc020164a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020164e:	972a                	add	a4,a4,a0
ffffffffc0201650:	04e68c63          	beq	a3,a4,ffffffffc02016a8 <default_free_pages+0x10c>
}
ffffffffc0201654:	60a2                	ld	ra,8(sp)
ffffffffc0201656:	0141                	addi	sp,sp,16
ffffffffc0201658:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020165a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020165c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020165e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201660:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201662:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201664:	02d70f63          	beq	a4,a3,ffffffffc02016a2 <default_free_pages+0x106>
ffffffffc0201668:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020166a:	87ba                	mv	a5,a4
ffffffffc020166c:	bf71                	j	ffffffffc0201608 <default_free_pages+0x6c>
            p->property += base->property;
ffffffffc020166e:	491c                	lw	a5,16(a0)
ffffffffc0201670:	9fad                	addw	a5,a5,a1
ffffffffc0201672:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201676:	57f5                	li	a5,-3
ffffffffc0201678:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020167c:	01853803          	ld	a6,24(a0)
ffffffffc0201680:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201682:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201684:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201688:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020168a:	0105b023          	sd	a6,0(a1)
ffffffffc020168e:	b77d                	j	ffffffffc020163c <default_free_pages+0xa0>
}
ffffffffc0201690:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201692:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201696:	e398                	sd	a4,0(a5)
ffffffffc0201698:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020169a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020169c:	ed1c                	sd	a5,24(a0)
}
ffffffffc020169e:	0141                	addi	sp,sp,16
ffffffffc02016a0:	8082                	ret
ffffffffc02016a2:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02016a4:	873e                	mv	a4,a5
ffffffffc02016a6:	bfad                	j	ffffffffc0201620 <default_free_pages+0x84>
            base->property += p->property;
ffffffffc02016a8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02016ac:	ff078693          	addi	a3,a5,-16
ffffffffc02016b0:	9f31                	addw	a4,a4,a2
ffffffffc02016b2:	c918                	sw	a4,16(a0)
ffffffffc02016b4:	5775                	li	a4,-3
ffffffffc02016b6:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016ba:	6398                	ld	a4,0(a5)
ffffffffc02016bc:	679c                	ld	a5,8(a5)
}
ffffffffc02016be:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02016c0:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02016c2:	e398                	sd	a4,0(a5)
ffffffffc02016c4:	0141                	addi	sp,sp,16
ffffffffc02016c6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016c8:	00006697          	auipc	a3,0x6
ffffffffc02016cc:	d4868693          	addi	a3,a3,-696 # ffffffffc0207410 <etext+0xc54>
ffffffffc02016d0:	00005617          	auipc	a2,0x5
ffffffffc02016d4:	76860613          	addi	a2,a2,1896 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02016d8:	08300593          	li	a1,131
ffffffffc02016dc:	00006517          	auipc	a0,0x6
ffffffffc02016e0:	9ec50513          	addi	a0,a0,-1556 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02016e4:	d91fe0ef          	jal	ffffffffc0200474 <__panic>
    assert(n > 0);
ffffffffc02016e8:	00006697          	auipc	a3,0x6
ffffffffc02016ec:	d2068693          	addi	a3,a3,-736 # ffffffffc0207408 <etext+0xc4c>
ffffffffc02016f0:	00005617          	auipc	a2,0x5
ffffffffc02016f4:	74860613          	addi	a2,a2,1864 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02016f8:	08000593          	li	a1,128
ffffffffc02016fc:	00006517          	auipc	a0,0x6
ffffffffc0201700:	9cc50513          	addi	a0,a0,-1588 # ffffffffc02070c8 <etext+0x90c>
ffffffffc0201704:	d71fe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0201708 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201708:	c949                	beqz	a0,ffffffffc020179a <default_alloc_pages+0x92>
    if (n > nr_free) {
ffffffffc020170a:	00098617          	auipc	a2,0x98
ffffffffc020170e:	4ae60613          	addi	a2,a2,1198 # ffffffffc0299bb8 <free_area>
ffffffffc0201712:	4a0c                	lw	a1,16(a2)
ffffffffc0201714:	872a                	mv	a4,a0
ffffffffc0201716:	02059793          	slli	a5,a1,0x20
ffffffffc020171a:	9381                	srli	a5,a5,0x20
ffffffffc020171c:	00a7eb63          	bltu	a5,a0,ffffffffc0201732 <default_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc0201720:	87b2                	mv	a5,a2
ffffffffc0201722:	a029                	j	ffffffffc020172c <default_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc0201724:	ff87e683          	lwu	a3,-8(a5)
ffffffffc0201728:	00e6f763          	bgeu	a3,a4,ffffffffc0201736 <default_alloc_pages+0x2e>
    return listelm->next;
ffffffffc020172c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020172e:	fec79be3          	bne	a5,a2,ffffffffc0201724 <default_alloc_pages+0x1c>
        return NULL;
ffffffffc0201732:	4501                	li	a0,0
}
ffffffffc0201734:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0201736:	0087b883          	ld	a7,8(a5)
        if (page->property > n) {
ffffffffc020173a:	ff87a803          	lw	a6,-8(a5)
    return listelm->prev;
ffffffffc020173e:	6394                	ld	a3,0(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201740:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc0201744:	02081313          	slli	t1,a6,0x20
    prev->next = next;
ffffffffc0201748:	0116b423          	sd	a7,8(a3)
    next->prev = prev;
ffffffffc020174c:	00d8b023          	sd	a3,0(a7)
ffffffffc0201750:	02035313          	srli	t1,t1,0x20
            p->property = page->property - n;
ffffffffc0201754:	0007089b          	sext.w	a7,a4
        if (page->property > n) {
ffffffffc0201758:	02677963          	bgeu	a4,t1,ffffffffc020178a <default_alloc_pages+0x82>
            struct Page *p = page + n;
ffffffffc020175c:	071a                	slli	a4,a4,0x6
ffffffffc020175e:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201760:	4118083b          	subw	a6,a6,a7
ffffffffc0201764:	01072823          	sw	a6,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201768:	4589                	li	a1,2
ffffffffc020176a:	00870813          	addi	a6,a4,8
ffffffffc020176e:	40b8302f          	amoor.d	zero,a1,(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201772:	0086b803          	ld	a6,8(a3)
            list_add(prev, &(p->page_link));
ffffffffc0201776:	01870313          	addi	t1,a4,24
        nr_free -= n;
ffffffffc020177a:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc020177c:	00683023          	sd	t1,0(a6)
ffffffffc0201780:	0066b423          	sd	t1,8(a3)
    elm->next = next;
ffffffffc0201784:	03073023          	sd	a6,32(a4)
    elm->prev = prev;
ffffffffc0201788:	ef14                	sd	a3,24(a4)
ffffffffc020178a:	411585bb          	subw	a1,a1,a7
ffffffffc020178e:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201790:	5775                	li	a4,-3
ffffffffc0201792:	17c1                	addi	a5,a5,-16
ffffffffc0201794:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201798:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020179a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020179c:	00006697          	auipc	a3,0x6
ffffffffc02017a0:	c6c68693          	addi	a3,a3,-916 # ffffffffc0207408 <etext+0xc4c>
ffffffffc02017a4:	00005617          	auipc	a2,0x5
ffffffffc02017a8:	69460613          	addi	a2,a2,1684 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02017ac:	06200593          	li	a1,98
ffffffffc02017b0:	00006517          	auipc	a0,0x6
ffffffffc02017b4:	91850513          	addi	a0,a0,-1768 # ffffffffc02070c8 <etext+0x90c>
default_alloc_pages(size_t n) {
ffffffffc02017b8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017ba:	cbbfe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02017be <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02017be:	1141                	addi	sp,sp,-16
ffffffffc02017c0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017c2:	c5f1                	beqz	a1,ffffffffc020188e <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc02017c4:	00659713          	slli	a4,a1,0x6
ffffffffc02017c8:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02017cc:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02017ce:	cf11                	beqz	a4,ffffffffc02017ea <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02017d0:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02017d2:	8b05                	andi	a4,a4,1
ffffffffc02017d4:	cf49                	beqz	a4,ffffffffc020186e <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02017d6:	0007a823          	sw	zero,16(a5)
ffffffffc02017da:	0007b423          	sd	zero,8(a5)
ffffffffc02017de:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02017e2:	04078793          	addi	a5,a5,64
ffffffffc02017e6:	fed795e3          	bne	a5,a3,ffffffffc02017d0 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02017ea:	2581                	sext.w	a1,a1
ffffffffc02017ec:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017ee:	4789                	li	a5,2
ffffffffc02017f0:	00850713          	addi	a4,a0,8
ffffffffc02017f4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02017f8:	00098697          	auipc	a3,0x98
ffffffffc02017fc:	3c068693          	addi	a3,a3,960 # ffffffffc0299bb8 <free_area>
ffffffffc0201800:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201802:	669c                	ld	a5,8(a3)
ffffffffc0201804:	9f2d                	addw	a4,a4,a1
ffffffffc0201806:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201808:	04d78663          	beq	a5,a3,ffffffffc0201854 <default_init_memmap+0x96>
            struct Page* page = le2page(le, page_link);
ffffffffc020180c:	fe878713          	addi	a4,a5,-24
ffffffffc0201810:	4581                	li	a1,0
ffffffffc0201812:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201816:	00e56a63          	bltu	a0,a4,ffffffffc020182a <default_init_memmap+0x6c>
    return listelm->next;
ffffffffc020181a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020181c:	02d70263          	beq	a4,a3,ffffffffc0201840 <default_init_memmap+0x82>
    struct Page *p = base;
ffffffffc0201820:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201822:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201826:	fee57ae3          	bgeu	a0,a4,ffffffffc020181a <default_init_memmap+0x5c>
ffffffffc020182a:	c199                	beqz	a1,ffffffffc0201830 <default_init_memmap+0x72>
ffffffffc020182c:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201830:	6398                	ld	a4,0(a5)
}
ffffffffc0201832:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201834:	e390                	sd	a2,0(a5)
ffffffffc0201836:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201838:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020183a:	ed18                	sd	a4,24(a0)
ffffffffc020183c:	0141                	addi	sp,sp,16
ffffffffc020183e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201840:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201842:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201844:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201846:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201848:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020184a:	00d70e63          	beq	a4,a3,ffffffffc0201866 <default_init_memmap+0xa8>
ffffffffc020184e:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201850:	87ba                	mv	a5,a4
ffffffffc0201852:	bfc1                	j	ffffffffc0201822 <default_init_memmap+0x64>
}
ffffffffc0201854:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201856:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020185a:	e398                	sd	a4,0(a5)
ffffffffc020185c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020185e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201860:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201862:	0141                	addi	sp,sp,16
ffffffffc0201864:	8082                	ret
ffffffffc0201866:	60a2                	ld	ra,8(sp)
ffffffffc0201868:	e290                	sd	a2,0(a3)
ffffffffc020186a:	0141                	addi	sp,sp,16
ffffffffc020186c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020186e:	00006697          	auipc	a3,0x6
ffffffffc0201872:	bca68693          	addi	a3,a3,-1078 # ffffffffc0207438 <etext+0xc7c>
ffffffffc0201876:	00005617          	auipc	a2,0x5
ffffffffc020187a:	5c260613          	addi	a2,a2,1474 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020187e:	04900593          	li	a1,73
ffffffffc0201882:	00006517          	auipc	a0,0x6
ffffffffc0201886:	84650513          	addi	a0,a0,-1978 # ffffffffc02070c8 <etext+0x90c>
ffffffffc020188a:	bebfe0ef          	jal	ffffffffc0200474 <__panic>
    assert(n > 0);
ffffffffc020188e:	00006697          	auipc	a3,0x6
ffffffffc0201892:	b7a68693          	addi	a3,a3,-1158 # ffffffffc0207408 <etext+0xc4c>
ffffffffc0201896:	00005617          	auipc	a2,0x5
ffffffffc020189a:	5a260613          	addi	a2,a2,1442 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020189e:	04600593          	li	a1,70
ffffffffc02018a2:	00006517          	auipc	a0,0x6
ffffffffc02018a6:	82650513          	addi	a0,a0,-2010 # ffffffffc02070c8 <etext+0x90c>
ffffffffc02018aa:	bcbfe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02018ae <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02018ae:	cd49                	beqz	a0,ffffffffc0201948 <slob_free+0x9a>
{
ffffffffc02018b0:	1141                	addi	sp,sp,-16
ffffffffc02018b2:	e022                	sd	s0,0(sp)
ffffffffc02018b4:	e406                	sd	ra,8(sp)
ffffffffc02018b6:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc02018b8:	eda1                	bnez	a1,ffffffffc0201910 <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018ba:	100027f3          	csrr	a5,sstatus
ffffffffc02018be:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018c0:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018c2:	efb9                	bnez	a5,ffffffffc0201920 <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018c4:	00091617          	auipc	a2,0x91
ffffffffc02018c8:	ee460613          	addi	a2,a2,-284 # ffffffffc02927a8 <slobfree>
ffffffffc02018cc:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018ce:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018d0:	0287fa63          	bgeu	a5,s0,ffffffffc0201904 <slob_free+0x56>
ffffffffc02018d4:	00e46463          	bltu	s0,a4,ffffffffc02018dc <slob_free+0x2e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018d8:	02e7ea63          	bltu	a5,a4,ffffffffc020190c <slob_free+0x5e>
			break;

	if (b + b->units == cur->next) {
ffffffffc02018dc:	400c                	lw	a1,0(s0)
ffffffffc02018de:	00459693          	slli	a3,a1,0x4
ffffffffc02018e2:	96a2                	add	a3,a3,s0
ffffffffc02018e4:	04d70d63          	beq	a4,a3,ffffffffc020193e <slob_free+0x90>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc02018e8:	438c                	lw	a1,0(a5)
ffffffffc02018ea:	e418                	sd	a4,8(s0)
ffffffffc02018ec:	00459693          	slli	a3,a1,0x4
ffffffffc02018f0:	96be                	add	a3,a3,a5
ffffffffc02018f2:	04d40063          	beq	s0,a3,ffffffffc0201932 <slob_free+0x84>
ffffffffc02018f6:	e780                	sd	s0,8(a5)
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;

	slobfree = cur;
ffffffffc02018f8:	e21c                	sd	a5,0(a2)
    if (flag) {
ffffffffc02018fa:	e51d                	bnez	a0,ffffffffc0201928 <slob_free+0x7a>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018fc:	60a2                	ld	ra,8(sp)
ffffffffc02018fe:	6402                	ld	s0,0(sp)
ffffffffc0201900:	0141                	addi	sp,sp,16
ffffffffc0201902:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201904:	00e7e463          	bltu	a5,a4,ffffffffc020190c <slob_free+0x5e>
ffffffffc0201908:	fce46ae3          	bltu	s0,a4,ffffffffc02018dc <slob_free+0x2e>
        return 1;
ffffffffc020190c:	87ba                	mv	a5,a4
ffffffffc020190e:	b7c1                	j	ffffffffc02018ce <slob_free+0x20>
		b->units = SLOB_UNITS(size);
ffffffffc0201910:	25bd                	addiw	a1,a1,15
ffffffffc0201912:	8191                	srli	a1,a1,0x4
ffffffffc0201914:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201916:	100027f3          	csrr	a5,sstatus
ffffffffc020191a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020191c:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020191e:	d3dd                	beqz	a5,ffffffffc02018c4 <slob_free+0x16>
        intr_disable();
ffffffffc0201920:	d21fe0ef          	jal	ffffffffc0200640 <intr_disable>
        return 1;
ffffffffc0201924:	4505                	li	a0,1
ffffffffc0201926:	bf79                	j	ffffffffc02018c4 <slob_free+0x16>
}
ffffffffc0201928:	6402                	ld	s0,0(sp)
ffffffffc020192a:	60a2                	ld	ra,8(sp)
ffffffffc020192c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020192e:	d0dfe06f          	j	ffffffffc020063a <intr_enable>
		cur->units += b->units;
ffffffffc0201932:	4014                	lw	a3,0(s0)
		cur->next = b->next;
ffffffffc0201934:	843a                	mv	s0,a4
		cur->units += b->units;
ffffffffc0201936:	00b6873b          	addw	a4,a3,a1
ffffffffc020193a:	c398                	sw	a4,0(a5)
		cur->next = b->next;
ffffffffc020193c:	bf6d                	j	ffffffffc02018f6 <slob_free+0x48>
		b->units += cur->next->units;
ffffffffc020193e:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201940:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201942:	9ead                	addw	a3,a3,a1
ffffffffc0201944:	c014                	sw	a3,0(s0)
		b->next = cur->next->next;
ffffffffc0201946:	b74d                	j	ffffffffc02018e8 <slob_free+0x3a>
ffffffffc0201948:	8082                	ret

ffffffffc020194a <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc020194a:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020194c:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc020194e:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201952:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201954:	34c000ef          	jal	ffffffffc0201ca0 <alloc_pages>
  if(!page)
ffffffffc0201958:	c91d                	beqz	a0,ffffffffc020198e <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc020195a:	0009c797          	auipc	a5,0x9c
ffffffffc020195e:	36e7b783          	ld	a5,878(a5) # ffffffffc029dcc8 <pages>
ffffffffc0201962:	8d1d                	sub	a0,a0,a5
ffffffffc0201964:	8519                	srai	a0,a0,0x6
ffffffffc0201966:	00007797          	auipc	a5,0x7
ffffffffc020196a:	54a7b783          	ld	a5,1354(a5) # ffffffffc0208eb0 <nbase>
ffffffffc020196e:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201970:	00c51793          	slli	a5,a0,0xc
ffffffffc0201974:	83b1                	srli	a5,a5,0xc
ffffffffc0201976:	0009c717          	auipc	a4,0x9c
ffffffffc020197a:	34a73703          	ld	a4,842(a4) # ffffffffc029dcc0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc020197e:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201980:	00e7fa63          	bgeu	a5,a4,ffffffffc0201994 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201984:	0009c797          	auipc	a5,0x9c
ffffffffc0201988:	3347b783          	ld	a5,820(a5) # ffffffffc029dcb8 <va_pa_offset>
ffffffffc020198c:	953e                	add	a0,a0,a5
}
ffffffffc020198e:	60a2                	ld	ra,8(sp)
ffffffffc0201990:	0141                	addi	sp,sp,16
ffffffffc0201992:	8082                	ret
ffffffffc0201994:	86aa                	mv	a3,a0
ffffffffc0201996:	00006617          	auipc	a2,0x6
ffffffffc020199a:	aca60613          	addi	a2,a2,-1334 # ffffffffc0207460 <etext+0xca4>
ffffffffc020199e:	06900593          	li	a1,105
ffffffffc02019a2:	00006517          	auipc	a0,0x6
ffffffffc02019a6:	ae650513          	addi	a0,a0,-1306 # ffffffffc0207488 <etext+0xccc>
ffffffffc02019aa:	acbfe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02019ae <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02019ae:	1101                	addi	sp,sp,-32
ffffffffc02019b0:	ec06                	sd	ra,24(sp)
ffffffffc02019b2:	e822                	sd	s0,16(sp)
ffffffffc02019b4:	e426                	sd	s1,8(sp)
ffffffffc02019b6:	e04a                	sd	s2,0(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc02019b8:	01050713          	addi	a4,a0,16
ffffffffc02019bc:	6785                	lui	a5,0x1
ffffffffc02019be:	0cf77363          	bgeu	a4,a5,ffffffffc0201a84 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019c2:	00f50493          	addi	s1,a0,15
ffffffffc02019c6:	8091                	srli	s1,s1,0x4
ffffffffc02019c8:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019ca:	10002673          	csrr	a2,sstatus
ffffffffc02019ce:	8a09                	andi	a2,a2,2
ffffffffc02019d0:	e25d                	bnez	a2,ffffffffc0201a76 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02019d2:	00091917          	auipc	s2,0x91
ffffffffc02019d6:	dd690913          	addi	s2,s2,-554 # ffffffffc02927a8 <slobfree>
ffffffffc02019da:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02019de:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02019e0:	4398                	lw	a4,0(a5)
ffffffffc02019e2:	08975e63          	bge	a4,s1,ffffffffc0201a7e <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc02019e6:	00f68b63          	beq	a3,a5,ffffffffc02019fc <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02019ea:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02019ec:	4018                	lw	a4,0(s0)
ffffffffc02019ee:	02975a63          	bge	a4,s1,ffffffffc0201a22 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc02019f2:	00093683          	ld	a3,0(s2)
ffffffffc02019f6:	87a2                	mv	a5,s0
ffffffffc02019f8:	fef699e3          	bne	a3,a5,ffffffffc02019ea <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc02019fc:	ee31                	bnez	a2,ffffffffc0201a58 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019fe:	4501                	li	a0,0
ffffffffc0201a00:	f4bff0ef          	jal	ffffffffc020194a <__slob_get_free_pages.constprop.0>
ffffffffc0201a04:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201a06:	cd05                	beqz	a0,ffffffffc0201a3e <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201a08:	6585                	lui	a1,0x1
ffffffffc0201a0a:	ea5ff0ef          	jal	ffffffffc02018ae <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a0e:	10002673          	csrr	a2,sstatus
ffffffffc0201a12:	8a09                	andi	a2,a2,2
ffffffffc0201a14:	ee05                	bnez	a2,ffffffffc0201a4c <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201a16:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a1a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a1c:	4018                	lw	a4,0(s0)
ffffffffc0201a1e:	fc974ae3          	blt	a4,s1,ffffffffc02019f2 <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc0201a22:	04e48763          	beq	s1,a4,ffffffffc0201a70 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a26:	00449693          	slli	a3,s1,0x4
ffffffffc0201a2a:	96a2                	add	a3,a3,s0
ffffffffc0201a2c:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a2e:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a30:	9f05                	subw	a4,a4,s1
ffffffffc0201a32:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a34:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a36:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201a38:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201a3c:	e20d                	bnez	a2,ffffffffc0201a5e <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201a3e:	60e2                	ld	ra,24(sp)
ffffffffc0201a40:	8522                	mv	a0,s0
ffffffffc0201a42:	6442                	ld	s0,16(sp)
ffffffffc0201a44:	64a2                	ld	s1,8(sp)
ffffffffc0201a46:	6902                	ld	s2,0(sp)
ffffffffc0201a48:	6105                	addi	sp,sp,32
ffffffffc0201a4a:	8082                	ret
        intr_disable();
ffffffffc0201a4c:	bf5fe0ef          	jal	ffffffffc0200640 <intr_disable>
			cur = slobfree;
ffffffffc0201a50:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201a54:	4605                	li	a2,1
ffffffffc0201a56:	b7d1                	j	ffffffffc0201a1a <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201a58:	be3fe0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0201a5c:	b74d                	j	ffffffffc02019fe <slob_alloc.constprop.0+0x50>
ffffffffc0201a5e:	bddfe0ef          	jal	ffffffffc020063a <intr_enable>
}
ffffffffc0201a62:	60e2                	ld	ra,24(sp)
ffffffffc0201a64:	8522                	mv	a0,s0
ffffffffc0201a66:	6442                	ld	s0,16(sp)
ffffffffc0201a68:	64a2                	ld	s1,8(sp)
ffffffffc0201a6a:	6902                	ld	s2,0(sp)
ffffffffc0201a6c:	6105                	addi	sp,sp,32
ffffffffc0201a6e:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a70:	6418                	ld	a4,8(s0)
ffffffffc0201a72:	e798                	sd	a4,8(a5)
ffffffffc0201a74:	b7d1                	j	ffffffffc0201a38 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a76:	bcbfe0ef          	jal	ffffffffc0200640 <intr_disable>
        return 1;
ffffffffc0201a7a:	4605                	li	a2,1
ffffffffc0201a7c:	bf99                	j	ffffffffc02019d2 <slob_alloc.constprop.0+0x24>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a7e:	843e                	mv	s0,a5
	prev = slobfree;
ffffffffc0201a80:	87b6                	mv	a5,a3
ffffffffc0201a82:	b745                	j	ffffffffc0201a22 <slob_alloc.constprop.0+0x74>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201a84:	00006697          	auipc	a3,0x6
ffffffffc0201a88:	a1468693          	addi	a3,a3,-1516 # ffffffffc0207498 <etext+0xcdc>
ffffffffc0201a8c:	00005617          	auipc	a2,0x5
ffffffffc0201a90:	3ac60613          	addi	a2,a2,940 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0201a94:	06400593          	li	a1,100
ffffffffc0201a98:	00006517          	auipc	a0,0x6
ffffffffc0201a9c:	a2050513          	addi	a0,a0,-1504 # ffffffffc02074b8 <etext+0xcfc>
ffffffffc0201aa0:	9d5fe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0201aa4 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201aa4:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201aa6:	00006517          	auipc	a0,0x6
ffffffffc0201aaa:	a2a50513          	addi	a0,a0,-1494 # ffffffffc02074d0 <etext+0xd14>
kmalloc_init(void) {
ffffffffc0201aae:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201ab0:	ed0fe0ef          	jal	ffffffffc0200180 <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201ab4:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ab6:	00006517          	auipc	a0,0x6
ffffffffc0201aba:	a3250513          	addi	a0,a0,-1486 # ffffffffc02074e8 <etext+0xd2c>
}
ffffffffc0201abe:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ac0:	ec0fe06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0201ac4 <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0201ac4:	4501                	li	a0,0
ffffffffc0201ac6:	8082                	ret

ffffffffc0201ac8 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201ac8:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201aca:	6785                	lui	a5,0x1
{
ffffffffc0201acc:	e822                	sd	s0,16(sp)
ffffffffc0201ace:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201ad0:	17bd                	addi	a5,a5,-17 # fef <_binary_obj___user_softint_out_size-0x7621>
{
ffffffffc0201ad2:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201ad4:	04a7fa63          	bgeu	a5,a0,ffffffffc0201b28 <kmalloc+0x60>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ad8:	4561                	li	a0,24
ffffffffc0201ada:	e426                	sd	s1,8(sp)
ffffffffc0201adc:	ed3ff0ef          	jal	ffffffffc02019ae <slob_alloc.constprop.0>
ffffffffc0201ae0:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201ae2:	c549                	beqz	a0,ffffffffc0201b6c <kmalloc+0xa4>
ffffffffc0201ae4:	e04a                	sd	s2,0(sp)
	bb->order = find_order(size);
ffffffffc0201ae6:	0004079b          	sext.w	a5,s0
ffffffffc0201aea:	6905                	lui	s2,0x1
	int order = 0;
ffffffffc0201aec:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201aee:	00f95763          	bge	s2,a5,ffffffffc0201afc <kmalloc+0x34>
ffffffffc0201af2:	6705                	lui	a4,0x1
ffffffffc0201af4:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201af6:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201af8:	fef74ee3          	blt	a4,a5,ffffffffc0201af4 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201afc:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201afe:	e4dff0ef          	jal	ffffffffc020194a <__slob_get_free_pages.constprop.0>
ffffffffc0201b02:	e488                	sd	a0,8(s1)
	if (bb->pages) {
ffffffffc0201b04:	cd21                	beqz	a0,ffffffffc0201b5c <kmalloc+0x94>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b06:	100027f3          	csrr	a5,sstatus
ffffffffc0201b0a:	8b89                	andi	a5,a5,2
ffffffffc0201b0c:	e795                	bnez	a5,ffffffffc0201b38 <kmalloc+0x70>
		bb->next = bigblocks;
ffffffffc0201b0e:	0009c797          	auipc	a5,0x9c
ffffffffc0201b12:	18a78793          	addi	a5,a5,394 # ffffffffc029dc98 <bigblocks>
ffffffffc0201b16:	6398                	ld	a4,0(a5)
ffffffffc0201b18:	6902                	ld	s2,0(sp)
		bigblocks = bb;
ffffffffc0201b1a:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b1c:	e898                	sd	a4,16(s1)
    if (flag) {
ffffffffc0201b1e:	64a2                	ld	s1,8(sp)
  return __kmalloc(size, 0);
}
ffffffffc0201b20:	60e2                	ld	ra,24(sp)
ffffffffc0201b22:	6442                	ld	s0,16(sp)
ffffffffc0201b24:	6105                	addi	sp,sp,32
ffffffffc0201b26:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b28:	0541                	addi	a0,a0,16
ffffffffc0201b2a:	e85ff0ef          	jal	ffffffffc02019ae <slob_alloc.constprop.0>
ffffffffc0201b2e:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b30:	0541                	addi	a0,a0,16
ffffffffc0201b32:	f7fd                	bnez	a5,ffffffffc0201b20 <kmalloc+0x58>
		return 0;
ffffffffc0201b34:	4501                	li	a0,0
  return __kmalloc(size, 0);
ffffffffc0201b36:	b7ed                	j	ffffffffc0201b20 <kmalloc+0x58>
        intr_disable();
ffffffffc0201b38:	b09fe0ef          	jal	ffffffffc0200640 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b3c:	0009c797          	auipc	a5,0x9c
ffffffffc0201b40:	15c78793          	addi	a5,a5,348 # ffffffffc029dc98 <bigblocks>
ffffffffc0201b44:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b46:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b48:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201b4a:	af1fe0ef          	jal	ffffffffc020063a <intr_enable>
}
ffffffffc0201b4e:	60e2                	ld	ra,24(sp)
ffffffffc0201b50:	6442                	ld	s0,16(sp)
		return bb->pages;
ffffffffc0201b52:	6488                	ld	a0,8(s1)
ffffffffc0201b54:	6902                	ld	s2,0(sp)
ffffffffc0201b56:	64a2                	ld	s1,8(sp)
}
ffffffffc0201b58:	6105                	addi	sp,sp,32
ffffffffc0201b5a:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b5c:	8526                	mv	a0,s1
ffffffffc0201b5e:	45e1                	li	a1,24
ffffffffc0201b60:	d4fff0ef          	jal	ffffffffc02018ae <slob_free>
		return 0;
ffffffffc0201b64:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b66:	64a2                	ld	s1,8(sp)
ffffffffc0201b68:	6902                	ld	s2,0(sp)
ffffffffc0201b6a:	bf5d                	j	ffffffffc0201b20 <kmalloc+0x58>
ffffffffc0201b6c:	64a2                	ld	s1,8(sp)
		return 0;
ffffffffc0201b6e:	4501                	li	a0,0
ffffffffc0201b70:	bf45                	j	ffffffffc0201b20 <kmalloc+0x58>

ffffffffc0201b72 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b72:	c169                	beqz	a0,ffffffffc0201c34 <kfree+0xc2>
{
ffffffffc0201b74:	1101                	addi	sp,sp,-32
ffffffffc0201b76:	e822                	sd	s0,16(sp)
ffffffffc0201b78:	ec06                	sd	ra,24(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201b7a:	03451793          	slli	a5,a0,0x34
ffffffffc0201b7e:	842a                	mv	s0,a0
ffffffffc0201b80:	e7c9                	bnez	a5,ffffffffc0201c0a <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b82:	100027f3          	csrr	a5,sstatus
ffffffffc0201b86:	8b89                	andi	a5,a5,2
ffffffffc0201b88:	ebc1                	bnez	a5,ffffffffc0201c18 <kfree+0xa6>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201b8a:	0009c797          	auipc	a5,0x9c
ffffffffc0201b8e:	10e7b783          	ld	a5,270(a5) # ffffffffc029dc98 <bigblocks>
    return 0;
ffffffffc0201b92:	4601                	li	a2,0
ffffffffc0201b94:	cbbd                	beqz	a5,ffffffffc0201c0a <kfree+0x98>
ffffffffc0201b96:	e426                	sd	s1,8(sp)
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b98:	0009c697          	auipc	a3,0x9c
ffffffffc0201b9c:	10068693          	addi	a3,a3,256 # ffffffffc029dc98 <bigblocks>
ffffffffc0201ba0:	a021                	j	ffffffffc0201ba8 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201ba2:	01048693          	addi	a3,s1,16
ffffffffc0201ba6:	c3a5                	beqz	a5,ffffffffc0201c06 <kfree+0x94>
			if (bb->pages == block) {
ffffffffc0201ba8:	6798                	ld	a4,8(a5)
ffffffffc0201baa:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc0201bac:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc0201bae:	fe871ae3          	bne	a4,s0,ffffffffc0201ba2 <kfree+0x30>
				*last = bb->next;
ffffffffc0201bb2:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201bb4:	ee2d                	bnez	a2,ffffffffc0201c2e <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201bb6:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201bba:	4098                	lw	a4,0(s1)
ffffffffc0201bbc:	08f46963          	bltu	s0,a5,ffffffffc0201c4e <kfree+0xdc>
ffffffffc0201bc0:	0009c797          	auipc	a5,0x9c
ffffffffc0201bc4:	0f87b783          	ld	a5,248(a5) # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0201bc8:	8c1d                	sub	s0,s0,a5
    if (PPN(pa) >= npage) {
ffffffffc0201bca:	8031                	srli	s0,s0,0xc
ffffffffc0201bcc:	0009c797          	auipc	a5,0x9c
ffffffffc0201bd0:	0f47b783          	ld	a5,244(a5) # ffffffffc029dcc0 <npage>
ffffffffc0201bd4:	06f47163          	bgeu	s0,a5,ffffffffc0201c36 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bd8:	00007797          	auipc	a5,0x7
ffffffffc0201bdc:	2d87b783          	ld	a5,728(a5) # ffffffffc0208eb0 <nbase>
ffffffffc0201be0:	8c1d                	sub	s0,s0,a5
ffffffffc0201be2:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201be4:	0009c517          	auipc	a0,0x9c
ffffffffc0201be8:	0e453503          	ld	a0,228(a0) # ffffffffc029dcc8 <pages>
ffffffffc0201bec:	4585                	li	a1,1
ffffffffc0201bee:	9522                	add	a0,a0,s0
ffffffffc0201bf0:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201bf4:	13c000ef          	jal	ffffffffc0201d30 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201bf8:	6442                	ld	s0,16(sp)
ffffffffc0201bfa:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bfc:	8526                	mv	a0,s1
ffffffffc0201bfe:	64a2                	ld	s1,8(sp)
ffffffffc0201c00:	45e1                	li	a1,24
}
ffffffffc0201c02:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c04:	b16d                	j	ffffffffc02018ae <slob_free>
ffffffffc0201c06:	64a2                	ld	s1,8(sp)
ffffffffc0201c08:	e205                	bnez	a2,ffffffffc0201c28 <kfree+0xb6>
ffffffffc0201c0a:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201c0e:	6442                	ld	s0,16(sp)
ffffffffc0201c10:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c12:	4581                	li	a1,0
}
ffffffffc0201c14:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c16:	b961                	j	ffffffffc02018ae <slob_free>
        intr_disable();
ffffffffc0201c18:	a29fe0ef          	jal	ffffffffc0200640 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201c1c:	0009c797          	auipc	a5,0x9c
ffffffffc0201c20:	07c7b783          	ld	a5,124(a5) # ffffffffc029dc98 <bigblocks>
        return 1;
ffffffffc0201c24:	4605                	li	a2,1
ffffffffc0201c26:	fba5                	bnez	a5,ffffffffc0201b96 <kfree+0x24>
        intr_enable();
ffffffffc0201c28:	a13fe0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0201c2c:	bff9                	j	ffffffffc0201c0a <kfree+0x98>
ffffffffc0201c2e:	a0dfe0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0201c32:	b751                	j	ffffffffc0201bb6 <kfree+0x44>
ffffffffc0201c34:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c36:	00006617          	auipc	a2,0x6
ffffffffc0201c3a:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0207530 <etext+0xd74>
ffffffffc0201c3e:	06200593          	li	a1,98
ffffffffc0201c42:	00006517          	auipc	a0,0x6
ffffffffc0201c46:	84650513          	addi	a0,a0,-1978 # ffffffffc0207488 <etext+0xccc>
ffffffffc0201c4a:	82bfe0ef          	jal	ffffffffc0200474 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c4e:	86a2                	mv	a3,s0
ffffffffc0201c50:	00006617          	auipc	a2,0x6
ffffffffc0201c54:	8b860613          	addi	a2,a2,-1864 # ffffffffc0207508 <etext+0xd4c>
ffffffffc0201c58:	06e00593          	li	a1,110
ffffffffc0201c5c:	00006517          	auipc	a0,0x6
ffffffffc0201c60:	82c50513          	addi	a0,a0,-2004 # ffffffffc0207488 <etext+0xccc>
ffffffffc0201c64:	811fe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0201c68 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0201c68:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c6a:	00006617          	auipc	a2,0x6
ffffffffc0201c6e:	8c660613          	addi	a2,a2,-1850 # ffffffffc0207530 <etext+0xd74>
ffffffffc0201c72:	06200593          	li	a1,98
ffffffffc0201c76:	00006517          	auipc	a0,0x6
ffffffffc0201c7a:	81250513          	addi	a0,a0,-2030 # ffffffffc0207488 <etext+0xccc>
pa2page(uintptr_t pa) {
ffffffffc0201c7e:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c80:	ff4fe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0201c84 <pte2page.part.0>:
pte2page(pte_t pte) {
ffffffffc0201c84:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201c86:	00006617          	auipc	a2,0x6
ffffffffc0201c8a:	8ca60613          	addi	a2,a2,-1846 # ffffffffc0207550 <etext+0xd94>
ffffffffc0201c8e:	07400593          	li	a1,116
ffffffffc0201c92:	00005517          	auipc	a0,0x5
ffffffffc0201c96:	7f650513          	addi	a0,a0,2038 # ffffffffc0207488 <etext+0xccc>
pte2page(pte_t pte) {
ffffffffc0201c9a:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201c9c:	fd8fe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0201ca0 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201ca0:	7139                	addi	sp,sp,-64
ffffffffc0201ca2:	f426                	sd	s1,40(sp)
ffffffffc0201ca4:	f04a                	sd	s2,32(sp)
ffffffffc0201ca6:	ec4e                	sd	s3,24(sp)
ffffffffc0201ca8:	e852                	sd	s4,16(sp)
ffffffffc0201caa:	e456                	sd	s5,8(sp)
ffffffffc0201cac:	e05a                	sd	s6,0(sp)
ffffffffc0201cae:	fc06                	sd	ra,56(sp)
ffffffffc0201cb0:	f822                	sd	s0,48(sp)
ffffffffc0201cb2:	84aa                	mv	s1,a0
ffffffffc0201cb4:	0009c917          	auipc	s2,0x9c
ffffffffc0201cb8:	fec90913          	addi	s2,s2,-20 # ffffffffc029dca0 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201cbc:	4a05                	li	s4,1
ffffffffc0201cbe:	0009ca97          	auipc	s5,0x9c
ffffffffc0201cc2:	012a8a93          	addi	s5,s5,18 # ffffffffc029dcd0 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201cc6:	0005099b          	sext.w	s3,a0
ffffffffc0201cca:	0009cb17          	auipc	s6,0x9c
ffffffffc0201cce:	026b0b13          	addi	s6,s6,38 # ffffffffc029dcf0 <check_mm_struct>
ffffffffc0201cd2:	a015                	j	ffffffffc0201cf6 <alloc_pages+0x56>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201cd4:	00093783          	ld	a5,0(s2)
ffffffffc0201cd8:	6f9c                	ld	a5,24(a5)
ffffffffc0201cda:	9782                	jalr	a5
ffffffffc0201cdc:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0201cde:	4601                	li	a2,0
ffffffffc0201ce0:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201ce2:	ec05                	bnez	s0,ffffffffc0201d1a <alloc_pages+0x7a>
ffffffffc0201ce4:	029a6b63          	bltu	s4,s1,ffffffffc0201d1a <alloc_pages+0x7a>
ffffffffc0201ce8:	000aa783          	lw	a5,0(s5)
ffffffffc0201cec:	c79d                	beqz	a5,ffffffffc0201d1a <alloc_pages+0x7a>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201cee:	000b3503          	ld	a0,0(s6)
ffffffffc0201cf2:	673010ef          	jal	ffffffffc0203b64 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cf6:	100027f3          	csrr	a5,sstatus
ffffffffc0201cfa:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201cfc:	8526                	mv	a0,s1
ffffffffc0201cfe:	dbf9                	beqz	a5,ffffffffc0201cd4 <alloc_pages+0x34>
        intr_disable();
ffffffffc0201d00:	941fe0ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc0201d04:	00093783          	ld	a5,0(s2)
ffffffffc0201d08:	8526                	mv	a0,s1
ffffffffc0201d0a:	6f9c                	ld	a5,24(a5)
ffffffffc0201d0c:	9782                	jalr	a5
ffffffffc0201d0e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d10:	92bfe0ef          	jal	ffffffffc020063a <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d14:	4601                	li	a2,0
ffffffffc0201d16:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201d18:	d471                	beqz	s0,ffffffffc0201ce4 <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201d1a:	70e2                	ld	ra,56(sp)
ffffffffc0201d1c:	8522                	mv	a0,s0
ffffffffc0201d1e:	7442                	ld	s0,48(sp)
ffffffffc0201d20:	74a2                	ld	s1,40(sp)
ffffffffc0201d22:	7902                	ld	s2,32(sp)
ffffffffc0201d24:	69e2                	ld	s3,24(sp)
ffffffffc0201d26:	6a42                	ld	s4,16(sp)
ffffffffc0201d28:	6aa2                	ld	s5,8(sp)
ffffffffc0201d2a:	6b02                	ld	s6,0(sp)
ffffffffc0201d2c:	6121                	addi	sp,sp,64
ffffffffc0201d2e:	8082                	ret

ffffffffc0201d30 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d30:	100027f3          	csrr	a5,sstatus
ffffffffc0201d34:	8b89                	andi	a5,a5,2
ffffffffc0201d36:	e799                	bnez	a5,ffffffffc0201d44 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201d38:	0009c797          	auipc	a5,0x9c
ffffffffc0201d3c:	f687b783          	ld	a5,-152(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0201d40:	739c                	ld	a5,32(a5)
ffffffffc0201d42:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201d44:	1101                	addi	sp,sp,-32
ffffffffc0201d46:	ec06                	sd	ra,24(sp)
ffffffffc0201d48:	e822                	sd	s0,16(sp)
ffffffffc0201d4a:	e426                	sd	s1,8(sp)
ffffffffc0201d4c:	842a                	mv	s0,a0
ffffffffc0201d4e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201d50:	8f1fe0ef          	jal	ffffffffc0200640 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201d54:	0009c797          	auipc	a5,0x9c
ffffffffc0201d58:	f4c7b783          	ld	a5,-180(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0201d5c:	739c                	ld	a5,32(a5)
ffffffffc0201d5e:	85a6                	mv	a1,s1
ffffffffc0201d60:	8522                	mv	a0,s0
ffffffffc0201d62:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201d64:	6442                	ld	s0,16(sp)
ffffffffc0201d66:	60e2                	ld	ra,24(sp)
ffffffffc0201d68:	64a2                	ld	s1,8(sp)
ffffffffc0201d6a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201d6c:	8cffe06f          	j	ffffffffc020063a <intr_enable>

ffffffffc0201d70 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d70:	100027f3          	csrr	a5,sstatus
ffffffffc0201d74:	8b89                	andi	a5,a5,2
ffffffffc0201d76:	e799                	bnez	a5,ffffffffc0201d84 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d78:	0009c797          	auipc	a5,0x9c
ffffffffc0201d7c:	f287b783          	ld	a5,-216(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0201d80:	779c                	ld	a5,40(a5)
ffffffffc0201d82:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201d84:	1141                	addi	sp,sp,-16
ffffffffc0201d86:	e406                	sd	ra,8(sp)
ffffffffc0201d88:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201d8a:	8b7fe0ef          	jal	ffffffffc0200640 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d8e:	0009c797          	auipc	a5,0x9c
ffffffffc0201d92:	f127b783          	ld	a5,-238(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0201d96:	779c                	ld	a5,40(a5)
ffffffffc0201d98:	9782                	jalr	a5
ffffffffc0201d9a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d9c:	89ffe0ef          	jal	ffffffffc020063a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201da0:	60a2                	ld	ra,8(sp)
ffffffffc0201da2:	8522                	mv	a0,s0
ffffffffc0201da4:	6402                	ld	s0,0(sp)
ffffffffc0201da6:	0141                	addi	sp,sp,16
ffffffffc0201da8:	8082                	ret

ffffffffc0201daa <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201daa:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201dae:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201db2:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201db4:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201db6:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201db8:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201dbc:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201dbe:	f04a                	sd	s2,32(sp)
ffffffffc0201dc0:	ec4e                	sd	s3,24(sp)
ffffffffc0201dc2:	e852                	sd	s4,16(sp)
ffffffffc0201dc4:	fc06                	sd	ra,56(sp)
ffffffffc0201dc6:	f822                	sd	s0,48(sp)
ffffffffc0201dc8:	e456                	sd	s5,8(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201dca:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201dce:	892e                	mv	s2,a1
ffffffffc0201dd0:	89b2                	mv	s3,a2
ffffffffc0201dd2:	0009ca17          	auipc	s4,0x9c
ffffffffc0201dd6:	eeea0a13          	addi	s4,s4,-274 # ffffffffc029dcc0 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201dda:	eba5                	bnez	a5,ffffffffc0201e4a <get_pte+0xa0>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201ddc:	12060e63          	beqz	a2,ffffffffc0201f18 <get_pte+0x16e>
ffffffffc0201de0:	4505                	li	a0,1
ffffffffc0201de2:	ebfff0ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0201de6:	842a                	mv	s0,a0
ffffffffc0201de8:	12050863          	beqz	a0,ffffffffc0201f18 <get_pte+0x16e>
    page->ref = val;
ffffffffc0201dec:	e05a                	sd	s6,0(sp)
    return page - pages + nbase;
ffffffffc0201dee:	0009cb17          	auipc	s6,0x9c
ffffffffc0201df2:	edab0b13          	addi	s6,s6,-294 # ffffffffc029dcc8 <pages>
ffffffffc0201df6:	000b3503          	ld	a0,0(s6)
ffffffffc0201dfa:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201dfe:	0009ca17          	auipc	s4,0x9c
ffffffffc0201e02:	ec2a0a13          	addi	s4,s4,-318 # ffffffffc029dcc0 <npage>
ffffffffc0201e06:	40a40533          	sub	a0,s0,a0
ffffffffc0201e0a:	8519                	srai	a0,a0,0x6
ffffffffc0201e0c:	9556                	add	a0,a0,s5
ffffffffc0201e0e:	000a3703          	ld	a4,0(s4)
ffffffffc0201e12:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e16:	4685                	li	a3,1
ffffffffc0201e18:	c014                	sw	a3,0(s0)
ffffffffc0201e1a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e1c:	0532                	slli	a0,a0,0xc
ffffffffc0201e1e:	14e7f563          	bgeu	a5,a4,ffffffffc0201f68 <get_pte+0x1be>
ffffffffc0201e22:	0009c797          	auipc	a5,0x9c
ffffffffc0201e26:	e967b783          	ld	a5,-362(a5) # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0201e2a:	953e                	add	a0,a0,a5
ffffffffc0201e2c:	6605                	lui	a2,0x1
ffffffffc0201e2e:	4581                	li	a1,0
ffffffffc0201e30:	163040ef          	jal	ffffffffc0206792 <memset>
    return page - pages + nbase;
ffffffffc0201e34:	000b3783          	ld	a5,0(s6)
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e38:	6b02                	ld	s6,0(sp)
ffffffffc0201e3a:	40f406b3          	sub	a3,s0,a5
ffffffffc0201e3e:	8699                	srai	a3,a3,0x6
ffffffffc0201e40:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e42:	06aa                	slli	a3,a3,0xa
ffffffffc0201e44:	0116e693          	ori	a3,a3,17
ffffffffc0201e48:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201e4a:	77fd                	lui	a5,0xfffff
ffffffffc0201e4c:	068a                	slli	a3,a3,0x2
ffffffffc0201e4e:	000a3703          	ld	a4,0(s4)
ffffffffc0201e52:	8efd                	and	a3,a3,a5
ffffffffc0201e54:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e58:	0ce7f263          	bgeu	a5,a4,ffffffffc0201f1c <get_pte+0x172>
ffffffffc0201e5c:	0009ca97          	auipc	s5,0x9c
ffffffffc0201e60:	e5ca8a93          	addi	s5,s5,-420 # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0201e64:	000ab603          	ld	a2,0(s5)
ffffffffc0201e68:	01595793          	srli	a5,s2,0x15
ffffffffc0201e6c:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e70:	96b2                	add	a3,a3,a2
ffffffffc0201e72:	078e                	slli	a5,a5,0x3
ffffffffc0201e74:	00f68433          	add	s0,a3,a5
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201e78:	6014                	ld	a3,0(s0)
ffffffffc0201e7a:	0016f793          	andi	a5,a3,1
ffffffffc0201e7e:	e3bd                	bnez	a5,ffffffffc0201ee4 <get_pte+0x13a>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201e80:	08098c63          	beqz	s3,ffffffffc0201f18 <get_pte+0x16e>
ffffffffc0201e84:	4505                	li	a0,1
ffffffffc0201e86:	e1bff0ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0201e8a:	84aa                	mv	s1,a0
ffffffffc0201e8c:	c551                	beqz	a0,ffffffffc0201f18 <get_pte+0x16e>
    page->ref = val;
ffffffffc0201e8e:	e05a                	sd	s6,0(sp)
    return page - pages + nbase;
ffffffffc0201e90:	0009cb17          	auipc	s6,0x9c
ffffffffc0201e94:	e38b0b13          	addi	s6,s6,-456 # ffffffffc029dcc8 <pages>
ffffffffc0201e98:	000b3683          	ld	a3,0(s6)
ffffffffc0201e9c:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ea0:	000a3703          	ld	a4,0(s4)
ffffffffc0201ea4:	40d506b3          	sub	a3,a0,a3
ffffffffc0201ea8:	8699                	srai	a3,a3,0x6
ffffffffc0201eaa:	96ce                	add	a3,a3,s3
ffffffffc0201eac:	00c69793          	slli	a5,a3,0xc
    page->ref = val;
ffffffffc0201eb0:	4605                	li	a2,1
ffffffffc0201eb2:	c110                	sw	a2,0(a0)
ffffffffc0201eb4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201eb6:	06b2                	slli	a3,a3,0xc
ffffffffc0201eb8:	08e7fc63          	bgeu	a5,a4,ffffffffc0201f50 <get_pte+0x1a6>
ffffffffc0201ebc:	000ab503          	ld	a0,0(s5)
ffffffffc0201ec0:	6605                	lui	a2,0x1
ffffffffc0201ec2:	4581                	li	a1,0
ffffffffc0201ec4:	9536                	add	a0,a0,a3
ffffffffc0201ec6:	0cd040ef          	jal	ffffffffc0206792 <memset>
    return page - pages + nbase;
ffffffffc0201eca:	000b3783          	ld	a5,0(s6)
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ece:	6b02                	ld	s6,0(sp)
ffffffffc0201ed0:	40f486b3          	sub	a3,s1,a5
ffffffffc0201ed4:	8699                	srai	a3,a3,0x6
ffffffffc0201ed6:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ed8:	06aa                	slli	a3,a3,0xa
ffffffffc0201eda:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ede:	e014                	sd	a3,0(s0)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ee0:	000a3703          	ld	a4,0(s4)
ffffffffc0201ee4:	77fd                	lui	a5,0xfffff
ffffffffc0201ee6:	068a                	slli	a3,a3,0x2
ffffffffc0201ee8:	8efd                	and	a3,a3,a5
ffffffffc0201eea:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201eee:	04e7f463          	bgeu	a5,a4,ffffffffc0201f36 <get_pte+0x18c>
ffffffffc0201ef2:	000ab783          	ld	a5,0(s5)
ffffffffc0201ef6:	00c95913          	srli	s2,s2,0xc
ffffffffc0201efa:	1ff97913          	andi	s2,s2,511
ffffffffc0201efe:	96be                	add	a3,a3,a5
ffffffffc0201f00:	090e                	slli	s2,s2,0x3
ffffffffc0201f02:	01268533          	add	a0,a3,s2
}
ffffffffc0201f06:	70e2                	ld	ra,56(sp)
ffffffffc0201f08:	7442                	ld	s0,48(sp)
ffffffffc0201f0a:	74a2                	ld	s1,40(sp)
ffffffffc0201f0c:	7902                	ld	s2,32(sp)
ffffffffc0201f0e:	69e2                	ld	s3,24(sp)
ffffffffc0201f10:	6a42                	ld	s4,16(sp)
ffffffffc0201f12:	6aa2                	ld	s5,8(sp)
ffffffffc0201f14:	6121                	addi	sp,sp,64
ffffffffc0201f16:	8082                	ret
            return NULL;
ffffffffc0201f18:	4501                	li	a0,0
ffffffffc0201f1a:	b7f5                	j	ffffffffc0201f06 <get_pte+0x15c>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f1c:	00005617          	auipc	a2,0x5
ffffffffc0201f20:	54460613          	addi	a2,a2,1348 # ffffffffc0207460 <etext+0xca4>
ffffffffc0201f24:	0e300593          	li	a1,227
ffffffffc0201f28:	00005517          	auipc	a0,0x5
ffffffffc0201f2c:	65050513          	addi	a0,a0,1616 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0201f30:	e05a                	sd	s6,0(sp)
ffffffffc0201f32:	d42fe0ef          	jal	ffffffffc0200474 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f36:	00005617          	auipc	a2,0x5
ffffffffc0201f3a:	52a60613          	addi	a2,a2,1322 # ffffffffc0207460 <etext+0xca4>
ffffffffc0201f3e:	0ee00593          	li	a1,238
ffffffffc0201f42:	00005517          	auipc	a0,0x5
ffffffffc0201f46:	63650513          	addi	a0,a0,1590 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0201f4a:	e05a                	sd	s6,0(sp)
ffffffffc0201f4c:	d28fe0ef          	jal	ffffffffc0200474 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f50:	00005617          	auipc	a2,0x5
ffffffffc0201f54:	51060613          	addi	a2,a2,1296 # ffffffffc0207460 <etext+0xca4>
ffffffffc0201f58:	0eb00593          	li	a1,235
ffffffffc0201f5c:	00005517          	auipc	a0,0x5
ffffffffc0201f60:	61c50513          	addi	a0,a0,1564 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0201f64:	d10fe0ef          	jal	ffffffffc0200474 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f68:	86aa                	mv	a3,a0
ffffffffc0201f6a:	00005617          	auipc	a2,0x5
ffffffffc0201f6e:	4f660613          	addi	a2,a2,1270 # ffffffffc0207460 <etext+0xca4>
ffffffffc0201f72:	0df00593          	li	a1,223
ffffffffc0201f76:	00005517          	auipc	a0,0x5
ffffffffc0201f7a:	60250513          	addi	a0,a0,1538 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0201f7e:	cf6fe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0201f82 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201f82:	1141                	addi	sp,sp,-16
ffffffffc0201f84:	e022                	sd	s0,0(sp)
ffffffffc0201f86:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f88:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201f8a:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f8c:	e1fff0ef          	jal	ffffffffc0201daa <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201f90:	c011                	beqz	s0,ffffffffc0201f94 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0201f92:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201f94:	c511                	beqz	a0,ffffffffc0201fa0 <get_page+0x1e>
ffffffffc0201f96:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f98:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201f9a:	0017f713          	andi	a4,a5,1
ffffffffc0201f9e:	e709                	bnez	a4,ffffffffc0201fa8 <get_page+0x26>
}
ffffffffc0201fa0:	60a2                	ld	ra,8(sp)
ffffffffc0201fa2:	6402                	ld	s0,0(sp)
ffffffffc0201fa4:	0141                	addi	sp,sp,16
ffffffffc0201fa6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fa8:	078a                	slli	a5,a5,0x2
ffffffffc0201faa:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201fac:	0009c717          	auipc	a4,0x9c
ffffffffc0201fb0:	d1473703          	ld	a4,-748(a4) # ffffffffc029dcc0 <npage>
ffffffffc0201fb4:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fd2 <get_page+0x50>
ffffffffc0201fb8:	60a2                	ld	ra,8(sp)
ffffffffc0201fba:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201fbc:	fff80737          	lui	a4,0xfff80
ffffffffc0201fc0:	97ba                	add	a5,a5,a4
ffffffffc0201fc2:	0009c517          	auipc	a0,0x9c
ffffffffc0201fc6:	d0653503          	ld	a0,-762(a0) # ffffffffc029dcc8 <pages>
ffffffffc0201fca:	079a                	slli	a5,a5,0x6
ffffffffc0201fcc:	953e                	add	a0,a0,a5
ffffffffc0201fce:	0141                	addi	sp,sp,16
ffffffffc0201fd0:	8082                	ret
ffffffffc0201fd2:	c97ff0ef          	jal	ffffffffc0201c68 <pa2page.part.0>

ffffffffc0201fd6 <unmap_range>:
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0201fd6:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201fd8:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0201fdc:	e486                	sd	ra,72(sp)
ffffffffc0201fde:	e0a2                	sd	s0,64(sp)
ffffffffc0201fe0:	fc26                	sd	s1,56(sp)
ffffffffc0201fe2:	f84a                	sd	s2,48(sp)
ffffffffc0201fe4:	f44e                	sd	s3,40(sp)
ffffffffc0201fe6:	f052                	sd	s4,32(sp)
ffffffffc0201fe8:	ec56                	sd	s5,24(sp)
ffffffffc0201fea:	e85a                	sd	s6,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201fec:	17d2                	slli	a5,a5,0x34
ffffffffc0201fee:	e7f9                	bnez	a5,ffffffffc02020bc <unmap_range+0xe6>
    assert(USER_ACCESS(start, end));
ffffffffc0201ff0:	002007b7          	lui	a5,0x200
ffffffffc0201ff4:	842e                	mv	s0,a1
ffffffffc0201ff6:	0ef5e363          	bltu	a1,a5,ffffffffc02020dc <unmap_range+0x106>
ffffffffc0201ffa:	8932                	mv	s2,a2
ffffffffc0201ffc:	0ec5f063          	bgeu	a1,a2,ffffffffc02020dc <unmap_range+0x106>
ffffffffc0202000:	4785                	li	a5,1
ffffffffc0202002:	07fe                	slli	a5,a5,0x1f
ffffffffc0202004:	0cc7ec63          	bltu	a5,a2,ffffffffc02020dc <unmap_range+0x106>
ffffffffc0202008:	89aa                	mv	s3,a0
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020200a:	6a05                	lui	s4,0x1
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020200c:	00200b37          	lui	s6,0x200
ffffffffc0202010:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202014:	4601                	li	a2,0
ffffffffc0202016:	85a2                	mv	a1,s0
ffffffffc0202018:	854e                	mv	a0,s3
ffffffffc020201a:	d91ff0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc020201e:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc0202020:	c125                	beqz	a0,ffffffffc0202080 <unmap_range+0xaa>
        if (*ptep != 0) {
ffffffffc0202022:	611c                	ld	a5,0(a0)
ffffffffc0202024:	ef99                	bnez	a5,ffffffffc0202042 <unmap_range+0x6c>
        start += PGSIZE;
ffffffffc0202026:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202028:	c019                	beqz	s0,ffffffffc020202e <unmap_range+0x58>
ffffffffc020202a:	ff2465e3          	bltu	s0,s2,ffffffffc0202014 <unmap_range+0x3e>
}
ffffffffc020202e:	60a6                	ld	ra,72(sp)
ffffffffc0202030:	6406                	ld	s0,64(sp)
ffffffffc0202032:	74e2                	ld	s1,56(sp)
ffffffffc0202034:	7942                	ld	s2,48(sp)
ffffffffc0202036:	79a2                	ld	s3,40(sp)
ffffffffc0202038:	7a02                	ld	s4,32(sp)
ffffffffc020203a:	6ae2                	ld	s5,24(sp)
ffffffffc020203c:	6b42                	ld	s6,16(sp)
ffffffffc020203e:	6161                	addi	sp,sp,80
ffffffffc0202040:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0202042:	0017f713          	andi	a4,a5,1
ffffffffc0202046:	d365                	beqz	a4,ffffffffc0202026 <unmap_range+0x50>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202048:	078a                	slli	a5,a5,0x2
ffffffffc020204a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020204c:	0009c717          	auipc	a4,0x9c
ffffffffc0202050:	c7473703          	ld	a4,-908(a4) # ffffffffc029dcc0 <npage>
ffffffffc0202054:	0ae7f463          	bgeu	a5,a4,ffffffffc02020fc <unmap_range+0x126>
    return &pages[PPN(pa) - nbase];
ffffffffc0202058:	fff80737          	lui	a4,0xfff80
ffffffffc020205c:	97ba                	add	a5,a5,a4
ffffffffc020205e:	079a                	slli	a5,a5,0x6
ffffffffc0202060:	0009c517          	auipc	a0,0x9c
ffffffffc0202064:	c6853503          	ld	a0,-920(a0) # ffffffffc029dcc8 <pages>
ffffffffc0202068:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020206a:	411c                	lw	a5,0(a0)
ffffffffc020206c:	fff7871b          	addiw	a4,a5,-1 # 1fffff <_binary_obj___user_exit_out_size+0x1f6497>
ffffffffc0202070:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202072:	cb19                	beqz	a4,ffffffffc0202088 <unmap_range+0xb2>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202074:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202078:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020207c:	9452                	add	s0,s0,s4
ffffffffc020207e:	b76d                	j	ffffffffc0202028 <unmap_range+0x52>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202080:	945a                	add	s0,s0,s6
ffffffffc0202082:	01547433          	and	s0,s0,s5
            continue;
ffffffffc0202086:	b74d                	j	ffffffffc0202028 <unmap_range+0x52>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202088:	100027f3          	csrr	a5,sstatus
ffffffffc020208c:	8b89                	andi	a5,a5,2
ffffffffc020208e:	eb89                	bnez	a5,ffffffffc02020a0 <unmap_range+0xca>
        pmm_manager->free_pages(base, n);
ffffffffc0202090:	0009c797          	auipc	a5,0x9c
ffffffffc0202094:	c107b783          	ld	a5,-1008(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0202098:	739c                	ld	a5,32(a5)
ffffffffc020209a:	4585                	li	a1,1
ffffffffc020209c:	9782                	jalr	a5
    if (flag) {
ffffffffc020209e:	bfd9                	j	ffffffffc0202074 <unmap_range+0x9e>
        intr_disable();
ffffffffc02020a0:	e42a                	sd	a0,8(sp)
ffffffffc02020a2:	d9efe0ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc02020a6:	0009c797          	auipc	a5,0x9c
ffffffffc02020aa:	bfa7b783          	ld	a5,-1030(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc02020ae:	739c                	ld	a5,32(a5)
ffffffffc02020b0:	6522                	ld	a0,8(sp)
ffffffffc02020b2:	4585                	li	a1,1
ffffffffc02020b4:	9782                	jalr	a5
        intr_enable();
ffffffffc02020b6:	d84fe0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc02020ba:	bf6d                	j	ffffffffc0202074 <unmap_range+0x9e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020bc:	00005697          	auipc	a3,0x5
ffffffffc02020c0:	4cc68693          	addi	a3,a3,1228 # ffffffffc0207588 <etext+0xdcc>
ffffffffc02020c4:	00005617          	auipc	a2,0x5
ffffffffc02020c8:	d7460613          	addi	a2,a2,-652 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02020cc:	10f00593          	li	a1,271
ffffffffc02020d0:	00005517          	auipc	a0,0x5
ffffffffc02020d4:	4a850513          	addi	a0,a0,1192 # ffffffffc0207578 <etext+0xdbc>
ffffffffc02020d8:	b9cfe0ef          	jal	ffffffffc0200474 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02020dc:	00005697          	auipc	a3,0x5
ffffffffc02020e0:	4dc68693          	addi	a3,a3,1244 # ffffffffc02075b8 <etext+0xdfc>
ffffffffc02020e4:	00005617          	auipc	a2,0x5
ffffffffc02020e8:	d5460613          	addi	a2,a2,-684 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02020ec:	11000593          	li	a1,272
ffffffffc02020f0:	00005517          	auipc	a0,0x5
ffffffffc02020f4:	48850513          	addi	a0,a0,1160 # ffffffffc0207578 <etext+0xdbc>
ffffffffc02020f8:	b7cfe0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc02020fc:	b6dff0ef          	jal	ffffffffc0201c68 <pa2page.part.0>

ffffffffc0202100 <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202100:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202102:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202106:	fc86                	sd	ra,120(sp)
ffffffffc0202108:	f8a2                	sd	s0,112(sp)
ffffffffc020210a:	f4a6                	sd	s1,104(sp)
ffffffffc020210c:	f0ca                	sd	s2,96(sp)
ffffffffc020210e:	ecce                	sd	s3,88(sp)
ffffffffc0202110:	e8d2                	sd	s4,80(sp)
ffffffffc0202112:	e4d6                	sd	s5,72(sp)
ffffffffc0202114:	e0da                	sd	s6,64(sp)
ffffffffc0202116:	fc5e                	sd	s7,56(sp)
ffffffffc0202118:	f862                	sd	s8,48(sp)
ffffffffc020211a:	f466                	sd	s9,40(sp)
ffffffffc020211c:	f06a                	sd	s10,32(sp)
ffffffffc020211e:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202120:	17d2                	slli	a5,a5,0x34
ffffffffc0202122:	24079163          	bnez	a5,ffffffffc0202364 <exit_range+0x264>
    assert(USER_ACCESS(start, end));
ffffffffc0202126:	002007b7          	lui	a5,0x200
ffffffffc020212a:	28f5e863          	bltu	a1,a5,ffffffffc02023ba <exit_range+0x2ba>
ffffffffc020212e:	8b32                	mv	s6,a2
ffffffffc0202130:	28c5f563          	bgeu	a1,a2,ffffffffc02023ba <exit_range+0x2ba>
ffffffffc0202134:	4785                	li	a5,1
ffffffffc0202136:	07fe                	slli	a5,a5,0x1f
ffffffffc0202138:	28c7e163          	bltu	a5,a2,ffffffffc02023ba <exit_range+0x2ba>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020213c:	c0000a37          	lui	s4,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202140:	ffe007b7          	lui	a5,0xffe00
ffffffffc0202144:	8d2a                	mv	s10,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202146:	0145fa33          	and	s4,a1,s4
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020214a:	00f5f4b3          	and	s1,a1,a5
        d1start += PDSIZE;
ffffffffc020214e:	40000db7          	lui	s11,0x40000
    if (PPN(pa) >= npage) {
ffffffffc0202152:	0009c617          	auipc	a2,0x9c
ffffffffc0202156:	b6e60613          	addi	a2,a2,-1170 # ffffffffc029dcc0 <npage>
    return KADDR(page2pa(page));
ffffffffc020215a:	0009c817          	auipc	a6,0x9c
ffffffffc020215e:	b5e80813          	addi	a6,a6,-1186 # ffffffffc029dcb8 <va_pa_offset>
    return &pages[PPN(pa) - nbase];
ffffffffc0202162:	0009ce97          	auipc	t4,0x9c
ffffffffc0202166:	b66e8e93          	addi	t4,t4,-1178 # ffffffffc029dcc8 <pages>
                d0start += PTSIZE;
ffffffffc020216a:	00200c37          	lui	s8,0x200
ffffffffc020216e:	a819                	j	ffffffffc0202184 <exit_range+0x84>
        d1start += PDSIZE;
ffffffffc0202170:	01ba09b3          	add	s3,s4,s11
    } while (d1start != 0 && d1start < end);
ffffffffc0202174:	14098763          	beqz	s3,ffffffffc02022c2 <exit_range+0x1c2>
        d1start += PDSIZE;
ffffffffc0202178:	40000a37          	lui	s4,0x40000
        d0start = d1start;
ffffffffc020217c:	400004b7          	lui	s1,0x40000
    } while (d1start != 0 && d1start < end);
ffffffffc0202180:	1569f163          	bgeu	s3,s6,ffffffffc02022c2 <exit_range+0x1c2>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202184:	01ea5913          	srli	s2,s4,0x1e
ffffffffc0202188:	1ff97913          	andi	s2,s2,511
ffffffffc020218c:	090e                	slli	s2,s2,0x3
ffffffffc020218e:	996a                	add	s2,s2,s10
ffffffffc0202190:	00093a83          	ld	s5,0(s2)
        if (pde1&PTE_V){
ffffffffc0202194:	001af793          	andi	a5,s5,1
ffffffffc0202198:	dfe1                	beqz	a5,ffffffffc0202170 <exit_range+0x70>
    if (PPN(pa) >= npage) {
ffffffffc020219a:	6214                	ld	a3,0(a2)
    return pa2page(PDE_ADDR(pde));
ffffffffc020219c:	0a8a                	slli	s5,s5,0x2
ffffffffc020219e:	00cada93          	srli	s5,s5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02021a2:	20dafa63          	bgeu	s5,a3,ffffffffc02023b6 <exit_range+0x2b6>
    return &pages[PPN(pa) - nbase];
ffffffffc02021a6:	fff80737          	lui	a4,0xfff80
ffffffffc02021aa:	9756                	add	a4,a4,s5
    return page - pages + nbase;
ffffffffc02021ac:	000807b7          	lui	a5,0x80
ffffffffc02021b0:	97ba                	add	a5,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc02021b2:	00c79b93          	slli	s7,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02021b6:	071a                	slli	a4,a4,0x6
    return KADDR(page2pa(page));
ffffffffc02021b8:	1ed7f263          	bgeu	a5,a3,ffffffffc020239c <exit_range+0x29c>
ffffffffc02021bc:	00083783          	ld	a5,0(a6)
            free_pd0 = 1;
ffffffffc02021c0:	4c85                	li	s9,1
    return &pages[PPN(pa) - nbase];
ffffffffc02021c2:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02021c6:	9bbe                	add	s7,s7,a5
    return page - pages + nbase;
ffffffffc02021c8:	00080337          	lui	t1,0x80
ffffffffc02021cc:	6885                	lui	a7,0x1
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc02021ce:	01ba09b3          	add	s3,s4,s11
ffffffffc02021d2:	a801                	j	ffffffffc02021e2 <exit_range+0xe2>
                    free_pd0 = 0;
ffffffffc02021d4:	4c81                	li	s9,0
                d0start += PTSIZE;
ffffffffc02021d6:	94e2                	add	s1,s1,s8
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc02021d8:	ccd1                	beqz	s1,ffffffffc0202274 <exit_range+0x174>
ffffffffc02021da:	0934fd63          	bgeu	s1,s3,ffffffffc0202274 <exit_range+0x174>
ffffffffc02021de:	1164f163          	bgeu	s1,s6,ffffffffc02022e0 <exit_range+0x1e0>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02021e2:	0154d413          	srli	s0,s1,0x15
ffffffffc02021e6:	1ff47413          	andi	s0,s0,511
ffffffffc02021ea:	040e                	slli	s0,s0,0x3
ffffffffc02021ec:	945e                	add	s0,s0,s7
ffffffffc02021ee:	601c                	ld	a5,0(s0)
                if (pde0&PTE_V) {
ffffffffc02021f0:	0017f693          	andi	a3,a5,1
ffffffffc02021f4:	d2e5                	beqz	a3,ffffffffc02021d4 <exit_range+0xd4>
    if (PPN(pa) >= npage) {
ffffffffc02021f6:	00063f03          	ld	t5,0(a2)
    return pa2page(PDE_ADDR(pde));
ffffffffc02021fa:	078a                	slli	a5,a5,0x2
ffffffffc02021fc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02021fe:	1be7fc63          	bgeu	a5,t5,ffffffffc02023b6 <exit_range+0x2b6>
    return &pages[PPN(pa) - nbase];
ffffffffc0202202:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc0202204:	00678fb3          	add	t6,a5,t1
    return &pages[PPN(pa) - nbase];
ffffffffc0202208:	000eb503          	ld	a0,0(t4)
ffffffffc020220c:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202210:	00cf9693          	slli	a3,t6,0xc
    return KADDR(page2pa(page));
ffffffffc0202214:	17eff863          	bgeu	t6,t5,ffffffffc0202384 <exit_range+0x284>
ffffffffc0202218:	00083783          	ld	a5,0(a6)
ffffffffc020221c:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc020221e:	01168f33          	add	t5,a3,a7
                        if (pt[i]&PTE_V){
ffffffffc0202222:	629c                	ld	a5,0(a3)
ffffffffc0202224:	8b85                	andi	a5,a5,1
ffffffffc0202226:	fbc5                	bnez	a5,ffffffffc02021d6 <exit_range+0xd6>
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc0202228:	06a1                	addi	a3,a3,8
ffffffffc020222a:	ffe69ce3          	bne	a3,t5,ffffffffc0202222 <exit_range+0x122>
    return &pages[PPN(pa) - nbase];
ffffffffc020222e:	952e                	add	a0,a0,a1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202230:	100027f3          	csrr	a5,sstatus
ffffffffc0202234:	8b89                	andi	a5,a5,2
ffffffffc0202236:	ebc5                	bnez	a5,ffffffffc02022e6 <exit_range+0x1e6>
        pmm_manager->free_pages(base, n);
ffffffffc0202238:	0009c797          	auipc	a5,0x9c
ffffffffc020223c:	a687b783          	ld	a5,-1432(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0202240:	739c                	ld	a5,32(a5)
ffffffffc0202242:	4585                	li	a1,1
ffffffffc0202244:	e03a                	sd	a4,0(sp)
ffffffffc0202246:	9782                	jalr	a5
    if (flag) {
ffffffffc0202248:	6702                	ld	a4,0(sp)
ffffffffc020224a:	fff80e37          	lui	t3,0xfff80
ffffffffc020224e:	00080337          	lui	t1,0x80
ffffffffc0202252:	6885                	lui	a7,0x1
ffffffffc0202254:	0009c617          	auipc	a2,0x9c
ffffffffc0202258:	a6c60613          	addi	a2,a2,-1428 # ffffffffc029dcc0 <npage>
ffffffffc020225c:	0009c817          	auipc	a6,0x9c
ffffffffc0202260:	a5c80813          	addi	a6,a6,-1444 # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0202264:	0009ce97          	auipc	t4,0x9c
ffffffffc0202268:	a64e8e93          	addi	t4,t4,-1436 # ffffffffc029dcc8 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020226c:	00043023          	sd	zero,0(s0)
                d0start += PTSIZE;
ffffffffc0202270:	94e2                	add	s1,s1,s8
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0202272:	f4a5                	bnez	s1,ffffffffc02021da <exit_range+0xda>
            if (free_pd0) {
ffffffffc0202274:	ee0c8ee3          	beqz	s9,ffffffffc0202170 <exit_range+0x70>
    if (PPN(pa) >= npage) {
ffffffffc0202278:	621c                	ld	a5,0(a2)
ffffffffc020227a:	12fafe63          	bgeu	s5,a5,ffffffffc02023b6 <exit_range+0x2b6>
    return &pages[PPN(pa) - nbase];
ffffffffc020227e:	0009c517          	auipc	a0,0x9c
ffffffffc0202282:	a4a53503          	ld	a0,-1462(a0) # ffffffffc029dcc8 <pages>
ffffffffc0202286:	953a                	add	a0,a0,a4
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202288:	100027f3          	csrr	a5,sstatus
ffffffffc020228c:	8b89                	andi	a5,a5,2
ffffffffc020228e:	efd9                	bnez	a5,ffffffffc020232c <exit_range+0x22c>
        pmm_manager->free_pages(base, n);
ffffffffc0202290:	0009c797          	auipc	a5,0x9c
ffffffffc0202294:	a107b783          	ld	a5,-1520(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0202298:	739c                	ld	a5,32(a5)
ffffffffc020229a:	4585                	li	a1,1
ffffffffc020229c:	9782                	jalr	a5
ffffffffc020229e:	0009ce97          	auipc	t4,0x9c
ffffffffc02022a2:	a2ae8e93          	addi	t4,t4,-1494 # ffffffffc029dcc8 <pages>
ffffffffc02022a6:	0009c817          	auipc	a6,0x9c
ffffffffc02022aa:	a1280813          	addi	a6,a6,-1518 # ffffffffc029dcb8 <va_pa_offset>
ffffffffc02022ae:	0009c617          	auipc	a2,0x9c
ffffffffc02022b2:	a1260613          	addi	a2,a2,-1518 # ffffffffc029dcc0 <npage>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02022b6:	00093023          	sd	zero,0(s2)
        d1start += PDSIZE;
ffffffffc02022ba:	01ba09b3          	add	s3,s4,s11
    } while (d1start != 0 && d1start < end);
ffffffffc02022be:	ea099de3          	bnez	s3,ffffffffc0202178 <exit_range+0x78>
}
ffffffffc02022c2:	70e6                	ld	ra,120(sp)
ffffffffc02022c4:	7446                	ld	s0,112(sp)
ffffffffc02022c6:	74a6                	ld	s1,104(sp)
ffffffffc02022c8:	7906                	ld	s2,96(sp)
ffffffffc02022ca:	69e6                	ld	s3,88(sp)
ffffffffc02022cc:	6a46                	ld	s4,80(sp)
ffffffffc02022ce:	6aa6                	ld	s5,72(sp)
ffffffffc02022d0:	6b06                	ld	s6,64(sp)
ffffffffc02022d2:	7be2                	ld	s7,56(sp)
ffffffffc02022d4:	7c42                	ld	s8,48(sp)
ffffffffc02022d6:	7ca2                	ld	s9,40(sp)
ffffffffc02022d8:	7d02                	ld	s10,32(sp)
ffffffffc02022da:	6de2                	ld	s11,24(sp)
ffffffffc02022dc:	6109                	addi	sp,sp,128
ffffffffc02022de:	8082                	ret
            if (free_pd0) {
ffffffffc02022e0:	e80c8ce3          	beqz	s9,ffffffffc0202178 <exit_range+0x78>
ffffffffc02022e4:	bf51                	j	ffffffffc0202278 <exit_range+0x178>
        intr_disable();
ffffffffc02022e6:	e03a                	sd	a4,0(sp)
ffffffffc02022e8:	e42a                	sd	a0,8(sp)
ffffffffc02022ea:	b56fe0ef          	jal	ffffffffc0200640 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02022ee:	0009c797          	auipc	a5,0x9c
ffffffffc02022f2:	9b27b783          	ld	a5,-1614(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc02022f6:	739c                	ld	a5,32(a5)
ffffffffc02022f8:	6522                	ld	a0,8(sp)
ffffffffc02022fa:	4585                	li	a1,1
ffffffffc02022fc:	9782                	jalr	a5
        intr_enable();
ffffffffc02022fe:	b3cfe0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202302:	6702                	ld	a4,0(sp)
ffffffffc0202304:	0009ce97          	auipc	t4,0x9c
ffffffffc0202308:	9c4e8e93          	addi	t4,t4,-1596 # ffffffffc029dcc8 <pages>
ffffffffc020230c:	0009c817          	auipc	a6,0x9c
ffffffffc0202310:	9ac80813          	addi	a6,a6,-1620 # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0202314:	0009c617          	auipc	a2,0x9c
ffffffffc0202318:	9ac60613          	addi	a2,a2,-1620 # ffffffffc029dcc0 <npage>
ffffffffc020231c:	6885                	lui	a7,0x1
ffffffffc020231e:	00080337          	lui	t1,0x80
ffffffffc0202322:	fff80e37          	lui	t3,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202326:	00043023          	sd	zero,0(s0)
ffffffffc020232a:	b799                	j	ffffffffc0202270 <exit_range+0x170>
        intr_disable();
ffffffffc020232c:	e02a                	sd	a0,0(sp)
ffffffffc020232e:	b12fe0ef          	jal	ffffffffc0200640 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202332:	0009c797          	auipc	a5,0x9c
ffffffffc0202336:	96e7b783          	ld	a5,-1682(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc020233a:	739c                	ld	a5,32(a5)
ffffffffc020233c:	6502                	ld	a0,0(sp)
ffffffffc020233e:	4585                	li	a1,1
ffffffffc0202340:	9782                	jalr	a5
        intr_enable();
ffffffffc0202342:	af8fe0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202346:	0009c617          	auipc	a2,0x9c
ffffffffc020234a:	97a60613          	addi	a2,a2,-1670 # ffffffffc029dcc0 <npage>
ffffffffc020234e:	0009c817          	auipc	a6,0x9c
ffffffffc0202352:	96a80813          	addi	a6,a6,-1686 # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0202356:	0009ce97          	auipc	t4,0x9c
ffffffffc020235a:	972e8e93          	addi	t4,t4,-1678 # ffffffffc029dcc8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020235e:	00093023          	sd	zero,0(s2)
ffffffffc0202362:	bfa1                	j	ffffffffc02022ba <exit_range+0x1ba>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202364:	00005697          	auipc	a3,0x5
ffffffffc0202368:	22468693          	addi	a3,a3,548 # ffffffffc0207588 <etext+0xdcc>
ffffffffc020236c:	00005617          	auipc	a2,0x5
ffffffffc0202370:	acc60613          	addi	a2,a2,-1332 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202374:	12000593          	li	a1,288
ffffffffc0202378:	00005517          	auipc	a0,0x5
ffffffffc020237c:	20050513          	addi	a0,a0,512 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202380:	8f4fe0ef          	jal	ffffffffc0200474 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202384:	00005617          	auipc	a2,0x5
ffffffffc0202388:	0dc60613          	addi	a2,a2,220 # ffffffffc0207460 <etext+0xca4>
ffffffffc020238c:	06900593          	li	a1,105
ffffffffc0202390:	00005517          	auipc	a0,0x5
ffffffffc0202394:	0f850513          	addi	a0,a0,248 # ffffffffc0207488 <etext+0xccc>
ffffffffc0202398:	8dcfe0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc020239c:	86de                	mv	a3,s7
ffffffffc020239e:	00005617          	auipc	a2,0x5
ffffffffc02023a2:	0c260613          	addi	a2,a2,194 # ffffffffc0207460 <etext+0xca4>
ffffffffc02023a6:	06900593          	li	a1,105
ffffffffc02023aa:	00005517          	auipc	a0,0x5
ffffffffc02023ae:	0de50513          	addi	a0,a0,222 # ffffffffc0207488 <etext+0xccc>
ffffffffc02023b2:	8c2fe0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc02023b6:	8b3ff0ef          	jal	ffffffffc0201c68 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02023ba:	00005697          	auipc	a3,0x5
ffffffffc02023be:	1fe68693          	addi	a3,a3,510 # ffffffffc02075b8 <etext+0xdfc>
ffffffffc02023c2:	00005617          	auipc	a2,0x5
ffffffffc02023c6:	a7660613          	addi	a2,a2,-1418 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02023ca:	12100593          	li	a1,289
ffffffffc02023ce:	00005517          	auipc	a0,0x5
ffffffffc02023d2:	1aa50513          	addi	a0,a0,426 # ffffffffc0207578 <etext+0xdbc>
ffffffffc02023d6:	89efe0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02023da <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02023da:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02023dc:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02023de:	ec26                	sd	s1,24(sp)
ffffffffc02023e0:	f406                	sd	ra,40(sp)
ffffffffc02023e2:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02023e4:	9c7ff0ef          	jal	ffffffffc0201daa <get_pte>
    if (ptep != NULL) {
ffffffffc02023e8:	c901                	beqz	a0,ffffffffc02023f8 <page_remove+0x1e>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc02023ea:	611c                	ld	a5,0(a0)
ffffffffc02023ec:	f022                	sd	s0,32(sp)
ffffffffc02023ee:	842a                	mv	s0,a0
ffffffffc02023f0:	0017f713          	andi	a4,a5,1
ffffffffc02023f4:	e711                	bnez	a4,ffffffffc0202400 <page_remove+0x26>
ffffffffc02023f6:	7402                	ld	s0,32(sp)
}
ffffffffc02023f8:	70a2                	ld	ra,40(sp)
ffffffffc02023fa:	64e2                	ld	s1,24(sp)
ffffffffc02023fc:	6145                	addi	sp,sp,48
ffffffffc02023fe:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202400:	078a                	slli	a5,a5,0x2
ffffffffc0202402:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202404:	0009c717          	auipc	a4,0x9c
ffffffffc0202408:	8bc73703          	ld	a4,-1860(a4) # ffffffffc029dcc0 <npage>
ffffffffc020240c:	06e7f363          	bgeu	a5,a4,ffffffffc0202472 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202410:	fff80737          	lui	a4,0xfff80
ffffffffc0202414:	97ba                	add	a5,a5,a4
ffffffffc0202416:	079a                	slli	a5,a5,0x6
ffffffffc0202418:	0009c517          	auipc	a0,0x9c
ffffffffc020241c:	8b053503          	ld	a0,-1872(a0) # ffffffffc029dcc8 <pages>
ffffffffc0202420:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202422:	411c                	lw	a5,0(a0)
ffffffffc0202424:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202428:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020242a:	cb11                	beqz	a4,ffffffffc020243e <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc020242c:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202430:	12048073          	sfence.vma	s1
ffffffffc0202434:	7402                	ld	s0,32(sp)
}
ffffffffc0202436:	70a2                	ld	ra,40(sp)
ffffffffc0202438:	64e2                	ld	s1,24(sp)
ffffffffc020243a:	6145                	addi	sp,sp,48
ffffffffc020243c:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020243e:	100027f3          	csrr	a5,sstatus
ffffffffc0202442:	8b89                	andi	a5,a5,2
ffffffffc0202444:	eb89                	bnez	a5,ffffffffc0202456 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202446:	0009c797          	auipc	a5,0x9c
ffffffffc020244a:	85a7b783          	ld	a5,-1958(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc020244e:	739c                	ld	a5,32(a5)
ffffffffc0202450:	4585                	li	a1,1
ffffffffc0202452:	9782                	jalr	a5
    if (flag) {
ffffffffc0202454:	bfe1                	j	ffffffffc020242c <page_remove+0x52>
        intr_disable();
ffffffffc0202456:	e42a                	sd	a0,8(sp)
ffffffffc0202458:	9e8fe0ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc020245c:	0009c797          	auipc	a5,0x9c
ffffffffc0202460:	8447b783          	ld	a5,-1980(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0202464:	739c                	ld	a5,32(a5)
ffffffffc0202466:	6522                	ld	a0,8(sp)
ffffffffc0202468:	4585                	li	a1,1
ffffffffc020246a:	9782                	jalr	a5
        intr_enable();
ffffffffc020246c:	9cefe0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202470:	bf75                	j	ffffffffc020242c <page_remove+0x52>
ffffffffc0202472:	ff6ff0ef          	jal	ffffffffc0201c68 <pa2page.part.0>

ffffffffc0202476 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202476:	7139                	addi	sp,sp,-64
ffffffffc0202478:	e852                	sd	s4,16(sp)
ffffffffc020247a:	8a32                	mv	s4,a2
ffffffffc020247c:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020247e:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202480:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202482:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202484:	f426                	sd	s1,40(sp)
ffffffffc0202486:	fc06                	sd	ra,56(sp)
ffffffffc0202488:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020248a:	921ff0ef          	jal	ffffffffc0201daa <get_pte>
    if (ptep == NULL) {
ffffffffc020248e:	c971                	beqz	a0,ffffffffc0202562 <page_insert+0xec>
    page->ref += 1;
ffffffffc0202490:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0202492:	611c                	ld	a5,0(a0)
ffffffffc0202494:	ec4e                	sd	s3,24(sp)
ffffffffc0202496:	0016871b          	addiw	a4,a3,1
ffffffffc020249a:	c018                	sw	a4,0(s0)
ffffffffc020249c:	0017f713          	andi	a4,a5,1
ffffffffc02024a0:	89aa                	mv	s3,a0
ffffffffc02024a2:	eb15                	bnez	a4,ffffffffc02024d6 <page_insert+0x60>
    return &pages[PPN(pa) - nbase];
ffffffffc02024a4:	0009c717          	auipc	a4,0x9c
ffffffffc02024a8:	82473703          	ld	a4,-2012(a4) # ffffffffc029dcc8 <pages>
    return page - pages + nbase;
ffffffffc02024ac:	8c19                	sub	s0,s0,a4
ffffffffc02024ae:	000807b7          	lui	a5,0x80
ffffffffc02024b2:	8419                	srai	s0,s0,0x6
ffffffffc02024b4:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02024b6:	042a                	slli	s0,s0,0xa
ffffffffc02024b8:	8cc1                	or	s1,s1,s0
ffffffffc02024ba:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02024be:	0099b023          	sd	s1,0(s3) # 80000 <_binary_obj___user_exit_out_size+0x76498>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02024c2:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02024c6:	69e2                	ld	s3,24(sp)
ffffffffc02024c8:	4501                	li	a0,0
}
ffffffffc02024ca:	70e2                	ld	ra,56(sp)
ffffffffc02024cc:	7442                	ld	s0,48(sp)
ffffffffc02024ce:	74a2                	ld	s1,40(sp)
ffffffffc02024d0:	6a42                	ld	s4,16(sp)
ffffffffc02024d2:	6121                	addi	sp,sp,64
ffffffffc02024d4:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02024d6:	078a                	slli	a5,a5,0x2
ffffffffc02024d8:	f04a                	sd	s2,32(sp)
ffffffffc02024da:	e456                	sd	s5,8(sp)
ffffffffc02024dc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02024de:	0009b717          	auipc	a4,0x9b
ffffffffc02024e2:	7e273703          	ld	a4,2018(a4) # ffffffffc029dcc0 <npage>
ffffffffc02024e6:	08e7f063          	bgeu	a5,a4,ffffffffc0202566 <page_insert+0xf0>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ea:	0009ba97          	auipc	s5,0x9b
ffffffffc02024ee:	7dea8a93          	addi	s5,s5,2014 # ffffffffc029dcc8 <pages>
ffffffffc02024f2:	000ab703          	ld	a4,0(s5)
ffffffffc02024f6:	fff80637          	lui	a2,0xfff80
ffffffffc02024fa:	00c78933          	add	s2,a5,a2
ffffffffc02024fe:	091a                	slli	s2,s2,0x6
ffffffffc0202500:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0202502:	01240e63          	beq	s0,s2,ffffffffc020251e <page_insert+0xa8>
    page->ref -= 1;
ffffffffc0202506:	00092783          	lw	a5,0(s2)
ffffffffc020250a:	fff7869b          	addiw	a3,a5,-1 # 7ffff <_binary_obj___user_exit_out_size+0x76497>
ffffffffc020250e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0202512:	ca91                	beqz	a3,ffffffffc0202526 <page_insert+0xb0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202514:	120a0073          	sfence.vma	s4
ffffffffc0202518:	7902                	ld	s2,32(sp)
ffffffffc020251a:	6aa2                	ld	s5,8(sp)
}
ffffffffc020251c:	bf41                	j	ffffffffc02024ac <page_insert+0x36>
    return page->ref;
ffffffffc020251e:	7902                	ld	s2,32(sp)
ffffffffc0202520:	6aa2                	ld	s5,8(sp)
    page->ref -= 1;
ffffffffc0202522:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202524:	b761                	j	ffffffffc02024ac <page_insert+0x36>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202526:	100027f3          	csrr	a5,sstatus
ffffffffc020252a:	8b89                	andi	a5,a5,2
ffffffffc020252c:	ef81                	bnez	a5,ffffffffc0202544 <page_insert+0xce>
        pmm_manager->free_pages(base, n);
ffffffffc020252e:	0009b797          	auipc	a5,0x9b
ffffffffc0202532:	7727b783          	ld	a5,1906(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0202536:	739c                	ld	a5,32(a5)
ffffffffc0202538:	4585                	li	a1,1
ffffffffc020253a:	854a                	mv	a0,s2
ffffffffc020253c:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020253e:	000ab703          	ld	a4,0(s5)
ffffffffc0202542:	bfc9                	j	ffffffffc0202514 <page_insert+0x9e>
        intr_disable();
ffffffffc0202544:	8fcfe0ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc0202548:	0009b797          	auipc	a5,0x9b
ffffffffc020254c:	7587b783          	ld	a5,1880(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0202550:	739c                	ld	a5,32(a5)
ffffffffc0202552:	4585                	li	a1,1
ffffffffc0202554:	854a                	mv	a0,s2
ffffffffc0202556:	9782                	jalr	a5
        intr_enable();
ffffffffc0202558:	8e2fe0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc020255c:	000ab703          	ld	a4,0(s5)
ffffffffc0202560:	bf55                	j	ffffffffc0202514 <page_insert+0x9e>
        return -E_NO_MEM;
ffffffffc0202562:	5571                	li	a0,-4
ffffffffc0202564:	b79d                	j	ffffffffc02024ca <page_insert+0x54>
ffffffffc0202566:	f02ff0ef          	jal	ffffffffc0201c68 <pa2page.part.0>

ffffffffc020256a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020256a:	00006797          	auipc	a5,0x6
ffffffffc020256e:	5ee78793          	addi	a5,a5,1518 # ffffffffc0208b58 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202572:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0202574:	711d                	addi	sp,sp,-96
ffffffffc0202576:	ec86                	sd	ra,88(sp)
ffffffffc0202578:	e4a6                	sd	s1,72(sp)
ffffffffc020257a:	fc4e                	sd	s3,56(sp)
ffffffffc020257c:	f05a                	sd	s6,32(sp)
ffffffffc020257e:	ec5e                	sd	s7,24(sp)
ffffffffc0202580:	e8a2                	sd	s0,80(sp)
ffffffffc0202582:	e0ca                	sd	s2,64(sp)
ffffffffc0202584:	f852                	sd	s4,48(sp)
ffffffffc0202586:	f456                	sd	s5,40(sp)
ffffffffc0202588:	e862                	sd	s8,16(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020258a:	0009bb97          	auipc	s7,0x9b
ffffffffc020258e:	716b8b93          	addi	s7,s7,1814 # ffffffffc029dca0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202592:	00005517          	auipc	a0,0x5
ffffffffc0202596:	03e50513          	addi	a0,a0,62 # ffffffffc02075d0 <etext+0xe14>
    pmm_manager = &default_pmm_manager;
ffffffffc020259a:	00fbb023          	sd	a5,0(s7)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020259e:	be3fd0ef          	jal	ffffffffc0200180 <cprintf>
    pmm_manager->init();
ffffffffc02025a2:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02025a6:	0009b997          	auipc	s3,0x9b
ffffffffc02025aa:	71298993          	addi	s3,s3,1810 # ffffffffc029dcb8 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc02025ae:	0009b497          	auipc	s1,0x9b
ffffffffc02025b2:	71248493          	addi	s1,s1,1810 # ffffffffc029dcc0 <npage>
    pmm_manager->init();
ffffffffc02025b6:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02025b8:	0009bb17          	auipc	s6,0x9b
ffffffffc02025bc:	710b0b13          	addi	s6,s6,1808 # ffffffffc029dcc8 <pages>
    pmm_manager->init();
ffffffffc02025c0:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02025c2:	57f5                	li	a5,-3
ffffffffc02025c4:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02025c6:	00005517          	auipc	a0,0x5
ffffffffc02025ca:	02250513          	addi	a0,a0,34 # ffffffffc02075e8 <etext+0xe2c>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02025ce:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc02025d2:	baffd0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02025d6:	46c5                	li	a3,17
ffffffffc02025d8:	06ee                	slli	a3,a3,0x1b
ffffffffc02025da:	40100613          	li	a2,1025
ffffffffc02025de:	16fd                	addi	a3,a3,-1
ffffffffc02025e0:	0656                	slli	a2,a2,0x15
ffffffffc02025e2:	07e005b7          	lui	a1,0x7e00
ffffffffc02025e6:	00005517          	auipc	a0,0x5
ffffffffc02025ea:	01a50513          	addi	a0,a0,26 # ffffffffc0207600 <etext+0xe44>
ffffffffc02025ee:	b93fd0ef          	jal	ffffffffc0200180 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02025f2:	777d                	lui	a4,0xfffff
ffffffffc02025f4:	0009c797          	auipc	a5,0x9c
ffffffffc02025f8:	72378793          	addi	a5,a5,1827 # ffffffffc029ed17 <end+0xfff>
ffffffffc02025fc:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02025fe:	00088737          	lui	a4,0x88
ffffffffc0202602:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202604:	00fb3023          	sd	a5,0(s6)
ffffffffc0202608:	4705                	li	a4,1
ffffffffc020260a:	07a1                	addi	a5,a5,8
ffffffffc020260c:	40e7b02f          	amoor.d	zero,a4,(a5)
ffffffffc0202610:	4505                	li	a0,1
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202612:	fff805b7          	lui	a1,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202616:	000b3783          	ld	a5,0(s6)
ffffffffc020261a:	00671693          	slli	a3,a4,0x6
ffffffffc020261e:	97b6                	add	a5,a5,a3
ffffffffc0202620:	07a1                	addi	a5,a5,8
ffffffffc0202622:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202626:	6090                	ld	a2,0(s1)
ffffffffc0202628:	0705                	addi	a4,a4,1 # 88001 <_binary_obj___user_exit_out_size+0x7e499>
ffffffffc020262a:	00b607b3          	add	a5,a2,a1
ffffffffc020262e:	fef764e3          	bltu	a4,a5,ffffffffc0202616 <pmm_init+0xac>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202632:	000b3503          	ld	a0,0(s6)
ffffffffc0202636:	079a                	slli	a5,a5,0x6
ffffffffc0202638:	c0200737          	lui	a4,0xc0200
ffffffffc020263c:	00f506b3          	add	a3,a0,a5
ffffffffc0202640:	60e6e463          	bltu	a3,a4,ffffffffc0202c48 <pmm_init+0x6de>
ffffffffc0202644:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0202648:	4745                	li	a4,17
ffffffffc020264a:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020264c:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc020264e:	4ae6e363          	bltu	a3,a4,ffffffffc0202af4 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202652:	00005517          	auipc	a0,0x5
ffffffffc0202656:	fd650513          	addi	a0,a0,-42 # ffffffffc0207628 <etext+0xe6c>
ffffffffc020265a:	b27fd0ef          	jal	ffffffffc0200180 <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020265e:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202662:	0009b917          	auipc	s2,0x9b
ffffffffc0202666:	64e90913          	addi	s2,s2,1614 # ffffffffc029dcb0 <boot_pgdir>
    pmm_manager->check();
ffffffffc020266a:	7b9c                	ld	a5,48(a5)
ffffffffc020266c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020266e:	00005517          	auipc	a0,0x5
ffffffffc0202672:	fd250513          	addi	a0,a0,-46 # ffffffffc0207640 <etext+0xe84>
ffffffffc0202676:	b0bfd0ef          	jal	ffffffffc0200180 <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020267a:	00009697          	auipc	a3,0x9
ffffffffc020267e:	98668693          	addi	a3,a3,-1658 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202682:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202686:	c02007b7          	lui	a5,0xc0200
ffffffffc020268a:	5cf6eb63          	bltu	a3,a5,ffffffffc0202c60 <pmm_init+0x6f6>
ffffffffc020268e:	0009b783          	ld	a5,0(s3)
ffffffffc0202692:	8e9d                	sub	a3,a3,a5
ffffffffc0202694:	0009b797          	auipc	a5,0x9b
ffffffffc0202698:	60d7ba23          	sd	a3,1556(a5) # ffffffffc029dca8 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020269c:	100027f3          	csrr	a5,sstatus
ffffffffc02026a0:	8b89                	andi	a5,a5,2
ffffffffc02026a2:	48079163          	bnez	a5,ffffffffc0202b24 <pmm_init+0x5ba>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026a6:	000bb783          	ld	a5,0(s7)
ffffffffc02026aa:	779c                	ld	a5,40(a5)
ffffffffc02026ac:	9782                	jalr	a5
ffffffffc02026ae:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02026b0:	6098                	ld	a4,0(s1)
ffffffffc02026b2:	c80007b7          	lui	a5,0xc8000
ffffffffc02026b6:	83b1                	srli	a5,a5,0xc
ffffffffc02026b8:	5ee7e063          	bltu	a5,a4,ffffffffc0202c98 <pmm_init+0x72e>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02026bc:	00093503          	ld	a0,0(s2)
ffffffffc02026c0:	5a050c63          	beqz	a0,ffffffffc0202c78 <pmm_init+0x70e>
ffffffffc02026c4:	03451793          	slli	a5,a0,0x34
ffffffffc02026c8:	5a079863          	bnez	a5,ffffffffc0202c78 <pmm_init+0x70e>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02026cc:	4601                	li	a2,0
ffffffffc02026ce:	4581                	li	a1,0
ffffffffc02026d0:	8b3ff0ef          	jal	ffffffffc0201f82 <get_page>
ffffffffc02026d4:	62051463          	bnez	a0,ffffffffc0202cfc <pmm_init+0x792>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02026d8:	4505                	li	a0,1
ffffffffc02026da:	dc6ff0ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc02026de:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02026e0:	00093503          	ld	a0,0(s2)
ffffffffc02026e4:	4681                	li	a3,0
ffffffffc02026e6:	4601                	li	a2,0
ffffffffc02026e8:	85d2                	mv	a1,s4
ffffffffc02026ea:	d8dff0ef          	jal	ffffffffc0202476 <page_insert>
ffffffffc02026ee:	5e051763          	bnez	a0,ffffffffc0202cdc <pmm_init+0x772>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02026f2:	00093503          	ld	a0,0(s2)
ffffffffc02026f6:	4601                	li	a2,0
ffffffffc02026f8:	4581                	li	a1,0
ffffffffc02026fa:	eb0ff0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc02026fe:	5a050f63          	beqz	a0,ffffffffc0202cbc <pmm_init+0x752>
    assert(pte2page(*ptep) == p1);
ffffffffc0202702:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202704:	0017f713          	andi	a4,a5,1
ffffffffc0202708:	5a070863          	beqz	a4,ffffffffc0202cb8 <pmm_init+0x74e>
    if (PPN(pa) >= npage) {
ffffffffc020270c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020270e:	078a                	slli	a5,a5,0x2
ffffffffc0202710:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202712:	52e7f963          	bgeu	a5,a4,ffffffffc0202c44 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc0202716:	000b3683          	ld	a3,0(s6)
ffffffffc020271a:	fff80637          	lui	a2,0xfff80
ffffffffc020271e:	97b2                	add	a5,a5,a2
ffffffffc0202720:	079a                	slli	a5,a5,0x6
ffffffffc0202722:	97b6                	add	a5,a5,a3
ffffffffc0202724:	10fa15e3          	bne	s4,a5,ffffffffc020302e <pmm_init+0xac4>
    assert(page_ref(p1) == 1);
ffffffffc0202728:	000a2683          	lw	a3,0(s4) # 40000000 <_binary_obj___user_exit_out_size+0x3fff6498>
ffffffffc020272c:	4785                	li	a5,1
ffffffffc020272e:	12f69ce3          	bne	a3,a5,ffffffffc0203066 <pmm_init+0xafc>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202732:	00093503          	ld	a0,0(s2)
ffffffffc0202736:	77fd                	lui	a5,0xfffff
ffffffffc0202738:	6114                	ld	a3,0(a0)
ffffffffc020273a:	068a                	slli	a3,a3,0x2
ffffffffc020273c:	8efd                	and	a3,a3,a5
ffffffffc020273e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202742:	10e676e3          	bgeu	a2,a4,ffffffffc020304e <pmm_init+0xae4>
ffffffffc0202746:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020274a:	96e2                	add	a3,a3,s8
ffffffffc020274c:	0006ba83          	ld	s5,0(a3)
ffffffffc0202750:	0a8a                	slli	s5,s5,0x2
ffffffffc0202752:	00fafab3          	and	s5,s5,a5
ffffffffc0202756:	00cad793          	srli	a5,s5,0xc
ffffffffc020275a:	62e7f163          	bgeu	a5,a4,ffffffffc0202d7c <pmm_init+0x812>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020275e:	4601                	li	a2,0
ffffffffc0202760:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202762:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202764:	e46ff0ef          	jal	ffffffffc0201daa <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202768:	0c21                	addi	s8,s8,8 # 200008 <_binary_obj___user_exit_out_size+0x1f64a0>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020276a:	5f851963          	bne	a0,s8,ffffffffc0202d5c <pmm_init+0x7f2>

    p2 = alloc_page();
ffffffffc020276e:	4505                	li	a0,1
ffffffffc0202770:	d30ff0ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0202774:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202776:	00093503          	ld	a0,0(s2)
ffffffffc020277a:	46d1                	li	a3,20
ffffffffc020277c:	6605                	lui	a2,0x1
ffffffffc020277e:	85d6                	mv	a1,s5
ffffffffc0202780:	cf7ff0ef          	jal	ffffffffc0202476 <page_insert>
ffffffffc0202784:	58051c63          	bnez	a0,ffffffffc0202d1c <pmm_init+0x7b2>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202788:	00093503          	ld	a0,0(s2)
ffffffffc020278c:	4601                	li	a2,0
ffffffffc020278e:	6585                	lui	a1,0x1
ffffffffc0202790:	e1aff0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc0202794:	0e0509e3          	beqz	a0,ffffffffc0203086 <pmm_init+0xb1c>
    assert(*ptep & PTE_U);
ffffffffc0202798:	611c                	ld	a5,0(a0)
ffffffffc020279a:	0107f713          	andi	a4,a5,16
ffffffffc020279e:	6e070c63          	beqz	a4,ffffffffc0202e96 <pmm_init+0x92c>
    assert(*ptep & PTE_W);
ffffffffc02027a2:	8b91                	andi	a5,a5,4
ffffffffc02027a4:	6a078963          	beqz	a5,ffffffffc0202e56 <pmm_init+0x8ec>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02027a8:	00093503          	ld	a0,0(s2)
ffffffffc02027ac:	611c                	ld	a5,0(a0)
ffffffffc02027ae:	8bc1                	andi	a5,a5,16
ffffffffc02027b0:	68078363          	beqz	a5,ffffffffc0202e36 <pmm_init+0x8cc>
    assert(page_ref(p2) == 1);
ffffffffc02027b4:	000aa703          	lw	a4,0(s5)
ffffffffc02027b8:	4785                	li	a5,1
ffffffffc02027ba:	58f71163          	bne	a4,a5,ffffffffc0202d3c <pmm_init+0x7d2>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02027be:	4681                	li	a3,0
ffffffffc02027c0:	6605                	lui	a2,0x1
ffffffffc02027c2:	85d2                	mv	a1,s4
ffffffffc02027c4:	cb3ff0ef          	jal	ffffffffc0202476 <page_insert>
ffffffffc02027c8:	62051763          	bnez	a0,ffffffffc0202df6 <pmm_init+0x88c>
    assert(page_ref(p1) == 2);
ffffffffc02027cc:	000a2703          	lw	a4,0(s4)
ffffffffc02027d0:	4789                	li	a5,2
ffffffffc02027d2:	60f71263          	bne	a4,a5,ffffffffc0202dd6 <pmm_init+0x86c>
    assert(page_ref(p2) == 0);
ffffffffc02027d6:	000aa783          	lw	a5,0(s5)
ffffffffc02027da:	5c079e63          	bnez	a5,ffffffffc0202db6 <pmm_init+0x84c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02027de:	00093503          	ld	a0,0(s2)
ffffffffc02027e2:	4601                	li	a2,0
ffffffffc02027e4:	6585                	lui	a1,0x1
ffffffffc02027e6:	dc4ff0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc02027ea:	5a050663          	beqz	a0,ffffffffc0202d96 <pmm_init+0x82c>
    assert(pte2page(*ptep) == p1);
ffffffffc02027ee:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02027f0:	00177793          	andi	a5,a4,1
ffffffffc02027f4:	4c078263          	beqz	a5,ffffffffc0202cb8 <pmm_init+0x74e>
    if (PPN(pa) >= npage) {
ffffffffc02027f8:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02027fa:	00271793          	slli	a5,a4,0x2
ffffffffc02027fe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202800:	44d7f263          	bgeu	a5,a3,ffffffffc0202c44 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc0202804:	000b3683          	ld	a3,0(s6)
ffffffffc0202808:	fff80637          	lui	a2,0xfff80
ffffffffc020280c:	97b2                	add	a5,a5,a2
ffffffffc020280e:	079a                	slli	a5,a5,0x6
ffffffffc0202810:	97b6                	add	a5,a5,a3
ffffffffc0202812:	6efa1263          	bne	s4,a5,ffffffffc0202ef6 <pmm_init+0x98c>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202816:	8b41                	andi	a4,a4,16
ffffffffc0202818:	6a071f63          	bnez	a4,ffffffffc0202ed6 <pmm_init+0x96c>

    page_remove(boot_pgdir, 0x0);
ffffffffc020281c:	00093503          	ld	a0,0(s2)
ffffffffc0202820:	4581                	li	a1,0
ffffffffc0202822:	bb9ff0ef          	jal	ffffffffc02023da <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202826:	000a2703          	lw	a4,0(s4)
ffffffffc020282a:	4785                	li	a5,1
ffffffffc020282c:	68f71563          	bne	a4,a5,ffffffffc0202eb6 <pmm_init+0x94c>
    assert(page_ref(p2) == 0);
ffffffffc0202830:	000aa783          	lw	a5,0(s5)
ffffffffc0202834:	74079d63          	bnez	a5,ffffffffc0202f8e <pmm_init+0xa24>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0202838:	00093503          	ld	a0,0(s2)
ffffffffc020283c:	6585                	lui	a1,0x1
ffffffffc020283e:	b9dff0ef          	jal	ffffffffc02023da <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202842:	000a2783          	lw	a5,0(s4)
ffffffffc0202846:	72079463          	bnez	a5,ffffffffc0202f6e <pmm_init+0xa04>
    assert(page_ref(p2) == 0);
ffffffffc020284a:	000aa783          	lw	a5,0(s5)
ffffffffc020284e:	70079063          	bnez	a5,ffffffffc0202f4e <pmm_init+0x9e4>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202852:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202856:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202858:	000a3783          	ld	a5,0(s4)
ffffffffc020285c:	078a                	slli	a5,a5,0x2
ffffffffc020285e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202860:	3ee7f263          	bgeu	a5,a4,ffffffffc0202c44 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc0202864:	fff806b7          	lui	a3,0xfff80
ffffffffc0202868:	000b3503          	ld	a0,0(s6)
ffffffffc020286c:	97b6                	add	a5,a5,a3
ffffffffc020286e:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202870:	00f506b3          	add	a3,a0,a5
ffffffffc0202874:	4290                	lw	a2,0(a3)
ffffffffc0202876:	4685                	li	a3,1
ffffffffc0202878:	6ad61b63          	bne	a2,a3,ffffffffc0202f2e <pmm_init+0x9c4>
    return page - pages + nbase;
ffffffffc020287c:	8799                	srai	a5,a5,0x6
ffffffffc020287e:	00080637          	lui	a2,0x80
ffffffffc0202882:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202884:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202888:	68e7f763          	bgeu	a5,a4,ffffffffc0202f16 <pmm_init+0x9ac>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020288c:	0009b783          	ld	a5,0(s3)
ffffffffc0202890:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202892:	639c                	ld	a5,0(a5)
ffffffffc0202894:	078a                	slli	a5,a5,0x2
ffffffffc0202896:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202898:	3ae7f663          	bgeu	a5,a4,ffffffffc0202c44 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc020289c:	8f91                	sub	a5,a5,a2
ffffffffc020289e:	079a                	slli	a5,a5,0x6
ffffffffc02028a0:	953e                	add	a0,a0,a5
ffffffffc02028a2:	100027f3          	csrr	a5,sstatus
ffffffffc02028a6:	8b89                	andi	a5,a5,2
ffffffffc02028a8:	2c079863          	bnez	a5,ffffffffc0202b78 <pmm_init+0x60e>
        pmm_manager->free_pages(base, n);
ffffffffc02028ac:	000bb783          	ld	a5,0(s7)
ffffffffc02028b0:	4585                	li	a1,1
ffffffffc02028b2:	739c                	ld	a5,32(a5)
ffffffffc02028b4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02028b6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02028ba:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02028bc:	078a                	slli	a5,a5,0x2
ffffffffc02028be:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028c0:	38e7f263          	bgeu	a5,a4,ffffffffc0202c44 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc02028c4:	000b3503          	ld	a0,0(s6)
ffffffffc02028c8:	fff80737          	lui	a4,0xfff80
ffffffffc02028cc:	97ba                	add	a5,a5,a4
ffffffffc02028ce:	079a                	slli	a5,a5,0x6
ffffffffc02028d0:	953e                	add	a0,a0,a5
ffffffffc02028d2:	100027f3          	csrr	a5,sstatus
ffffffffc02028d6:	8b89                	andi	a5,a5,2
ffffffffc02028d8:	28079463          	bnez	a5,ffffffffc0202b60 <pmm_init+0x5f6>
ffffffffc02028dc:	000bb783          	ld	a5,0(s7)
ffffffffc02028e0:	4585                	li	a1,1
ffffffffc02028e2:	739c                	ld	a5,32(a5)
ffffffffc02028e4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02028e6:	00093783          	ld	a5,0(s2)
ffffffffc02028ea:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd612e8>
  asm volatile("sfence.vma");
ffffffffc02028ee:	12000073          	sfence.vma
ffffffffc02028f2:	100027f3          	csrr	a5,sstatus
ffffffffc02028f6:	8b89                	andi	a5,a5,2
ffffffffc02028f8:	24079a63          	bnez	a5,ffffffffc0202b4c <pmm_init+0x5e2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028fc:	000bb783          	ld	a5,0(s7)
ffffffffc0202900:	779c                	ld	a5,40(a5)
ffffffffc0202902:	9782                	jalr	a5
ffffffffc0202904:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202906:	71441463          	bne	s0,s4,ffffffffc020300e <pmm_init+0xaa4>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020290a:	00005517          	auipc	a0,0x5
ffffffffc020290e:	01e50513          	addi	a0,a0,30 # ffffffffc0207928 <etext+0x116c>
ffffffffc0202912:	86ffd0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc0202916:	100027f3          	csrr	a5,sstatus
ffffffffc020291a:	8b89                	andi	a5,a5,2
ffffffffc020291c:	20079e63          	bnez	a5,ffffffffc0202b38 <pmm_init+0x5ce>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202920:	000bb783          	ld	a5,0(s7)
ffffffffc0202924:	779c                	ld	a5,40(a5)
ffffffffc0202926:	9782                	jalr	a5
ffffffffc0202928:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020292a:	6098                	ld	a4,0(s1)
ffffffffc020292c:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202930:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202932:	00c71793          	slli	a5,a4,0xc
ffffffffc0202936:	6a05                	lui	s4,0x1
ffffffffc0202938:	02f47c63          	bgeu	s0,a5,ffffffffc0202970 <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020293c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202940:	00093503          	ld	a0,0(s2)
ffffffffc0202944:	2ee7f363          	bgeu	a5,a4,ffffffffc0202c2a <pmm_init+0x6c0>
ffffffffc0202948:	0009b583          	ld	a1,0(s3)
ffffffffc020294c:	4601                	li	a2,0
ffffffffc020294e:	95a2                	add	a1,a1,s0
ffffffffc0202950:	c5aff0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc0202954:	2a050b63          	beqz	a0,ffffffffc0202c0a <pmm_init+0x6a0>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202958:	611c                	ld	a5,0(a0)
ffffffffc020295a:	078a                	slli	a5,a5,0x2
ffffffffc020295c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202960:	28879563          	bne	a5,s0,ffffffffc0202bea <pmm_init+0x680>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202964:	6098                	ld	a4,0(s1)
ffffffffc0202966:	9452                	add	s0,s0,s4
ffffffffc0202968:	00c71793          	slli	a5,a4,0xc
ffffffffc020296c:	fcf468e3          	bltu	s0,a5,ffffffffc020293c <pmm_init+0x3d2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0202970:	00093783          	ld	a5,0(s2)
ffffffffc0202974:	639c                	ld	a5,0(a5)
ffffffffc0202976:	66079c63          	bnez	a5,ffffffffc0202fee <pmm_init+0xa84>

    struct Page *p;
    p = alloc_page();
ffffffffc020297a:	4505                	li	a0,1
ffffffffc020297c:	b24ff0ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0202980:	842a                	mv	s0,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202982:	00093503          	ld	a0,0(s2)
ffffffffc0202986:	4699                	li	a3,6
ffffffffc0202988:	10000613          	li	a2,256
ffffffffc020298c:	85a2                	mv	a1,s0
ffffffffc020298e:	ae9ff0ef          	jal	ffffffffc0202476 <page_insert>
ffffffffc0202992:	62051e63          	bnez	a0,ffffffffc0202fce <pmm_init+0xa64>
    assert(page_ref(p) == 1);
ffffffffc0202996:	4018                	lw	a4,0(s0)
ffffffffc0202998:	4785                	li	a5,1
ffffffffc020299a:	60f71a63          	bne	a4,a5,ffffffffc0202fae <pmm_init+0xa44>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020299e:	00093503          	ld	a0,0(s2)
ffffffffc02029a2:	6605                	lui	a2,0x1
ffffffffc02029a4:	4699                	li	a3,6
ffffffffc02029a6:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7510>
ffffffffc02029aa:	85a2                	mv	a1,s0
ffffffffc02029ac:	acbff0ef          	jal	ffffffffc0202476 <page_insert>
ffffffffc02029b0:	46051363          	bnez	a0,ffffffffc0202e16 <pmm_init+0x8ac>
    assert(page_ref(p) == 2);
ffffffffc02029b4:	4018                	lw	a4,0(s0)
ffffffffc02029b6:	4789                	li	a5,2
ffffffffc02029b8:	72f71763          	bne	a4,a5,ffffffffc02030e6 <pmm_init+0xb7c>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02029bc:	00005597          	auipc	a1,0x5
ffffffffc02029c0:	0a458593          	addi	a1,a1,164 # ffffffffc0207a60 <etext+0x12a4>
ffffffffc02029c4:	10000513          	li	a0,256
ffffffffc02029c8:	56b030ef          	jal	ffffffffc0206732 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02029cc:	6585                	lui	a1,0x1
ffffffffc02029ce:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7510>
ffffffffc02029d2:	10000513          	li	a0,256
ffffffffc02029d6:	56f030ef          	jal	ffffffffc0206744 <strcmp>
ffffffffc02029da:	6e051663          	bnez	a0,ffffffffc02030c6 <pmm_init+0xb5c>
    return page - pages + nbase;
ffffffffc02029de:	000b3683          	ld	a3,0(s6)
ffffffffc02029e2:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc02029e6:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc02029e8:	40d406b3          	sub	a3,s0,a3
ffffffffc02029ec:	8699                	srai	a3,a3,0x6
ffffffffc02029ee:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02029f0:	00c69793          	slli	a5,a3,0xc
ffffffffc02029f4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02029f6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02029f8:	50e7ff63          	bgeu	a5,a4,ffffffffc0202f16 <pmm_init+0x9ac>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02029fc:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202a00:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202a04:	97b6                	add	a5,a5,a3
ffffffffc0202a06:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_exit_out_size+0x76598>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202a0a:	4f3030ef          	jal	ffffffffc02066fc <strlen>
ffffffffc0202a0e:	68051c63          	bnez	a0,ffffffffc02030a6 <pmm_init+0xb3c>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202a12:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202a16:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a18:	000a3783          	ld	a5,0(s4) # 1000 <_binary_obj___user_softint_out_size-0x7610>
ffffffffc0202a1c:	078a                	slli	a5,a5,0x2
ffffffffc0202a1e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a20:	22e7f263          	bgeu	a5,a4,ffffffffc0202c44 <pmm_init+0x6da>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a24:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202a28:	4ee7f763          	bgeu	a5,a4,ffffffffc0202f16 <pmm_init+0x9ac>
ffffffffc0202a2c:	0009b783          	ld	a5,0(s3)
ffffffffc0202a30:	00f689b3          	add	s3,a3,a5
ffffffffc0202a34:	100027f3          	csrr	a5,sstatus
ffffffffc0202a38:	8b89                	andi	a5,a5,2
ffffffffc0202a3a:	18079d63          	bnez	a5,ffffffffc0202bd4 <pmm_init+0x66a>
        pmm_manager->free_pages(base, n);
ffffffffc0202a3e:	000bb783          	ld	a5,0(s7)
ffffffffc0202a42:	4585                	li	a1,1
ffffffffc0202a44:	8522                	mv	a0,s0
ffffffffc0202a46:	739c                	ld	a5,32(a5)
ffffffffc0202a48:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a4a:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202a4e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a50:	078a                	slli	a5,a5,0x2
ffffffffc0202a52:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a54:	1ee7f863          	bgeu	a5,a4,ffffffffc0202c44 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a58:	000b3503          	ld	a0,0(s6)
ffffffffc0202a5c:	fff80737          	lui	a4,0xfff80
ffffffffc0202a60:	97ba                	add	a5,a5,a4
ffffffffc0202a62:	079a                	slli	a5,a5,0x6
ffffffffc0202a64:	953e                	add	a0,a0,a5
ffffffffc0202a66:	100027f3          	csrr	a5,sstatus
ffffffffc0202a6a:	8b89                	andi	a5,a5,2
ffffffffc0202a6c:	14079863          	bnez	a5,ffffffffc0202bbc <pmm_init+0x652>
ffffffffc0202a70:	000bb783          	ld	a5,0(s7)
ffffffffc0202a74:	4585                	li	a1,1
ffffffffc0202a76:	739c                	ld	a5,32(a5)
ffffffffc0202a78:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a7a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0202a7e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a80:	078a                	slli	a5,a5,0x2
ffffffffc0202a82:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a84:	1ce7f063          	bgeu	a5,a4,ffffffffc0202c44 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a88:	000b3503          	ld	a0,0(s6)
ffffffffc0202a8c:	fff80737          	lui	a4,0xfff80
ffffffffc0202a90:	97ba                	add	a5,a5,a4
ffffffffc0202a92:	079a                	slli	a5,a5,0x6
ffffffffc0202a94:	953e                	add	a0,a0,a5
ffffffffc0202a96:	100027f3          	csrr	a5,sstatus
ffffffffc0202a9a:	8b89                	andi	a5,a5,2
ffffffffc0202a9c:	10079463          	bnez	a5,ffffffffc0202ba4 <pmm_init+0x63a>
ffffffffc0202aa0:	000bb783          	ld	a5,0(s7)
ffffffffc0202aa4:	4585                	li	a1,1
ffffffffc0202aa6:	739c                	ld	a5,32(a5)
ffffffffc0202aa8:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202aaa:	00093783          	ld	a5,0(s2)
ffffffffc0202aae:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc0202ab2:	12000073          	sfence.vma
ffffffffc0202ab6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aba:	8b89                	andi	a5,a5,2
ffffffffc0202abc:	0c079a63          	bnez	a5,ffffffffc0202b90 <pmm_init+0x626>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ac0:	000bb783          	ld	a5,0(s7)
ffffffffc0202ac4:	779c                	ld	a5,40(a5)
ffffffffc0202ac6:	9782                	jalr	a5
ffffffffc0202ac8:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202aca:	3a8c1663          	bne	s8,s0,ffffffffc0202e76 <pmm_init+0x90c>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202ace:	00005517          	auipc	a0,0x5
ffffffffc0202ad2:	00a50513          	addi	a0,a0,10 # ffffffffc0207ad8 <etext+0x131c>
ffffffffc0202ad6:	eaafd0ef          	jal	ffffffffc0200180 <cprintf>
}
ffffffffc0202ada:	6446                	ld	s0,80(sp)
ffffffffc0202adc:	60e6                	ld	ra,88(sp)
ffffffffc0202ade:	64a6                	ld	s1,72(sp)
ffffffffc0202ae0:	6906                	ld	s2,64(sp)
ffffffffc0202ae2:	79e2                	ld	s3,56(sp)
ffffffffc0202ae4:	7a42                	ld	s4,48(sp)
ffffffffc0202ae6:	7aa2                	ld	s5,40(sp)
ffffffffc0202ae8:	7b02                	ld	s6,32(sp)
ffffffffc0202aea:	6be2                	ld	s7,24(sp)
ffffffffc0202aec:	6c42                	ld	s8,16(sp)
ffffffffc0202aee:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc0202af0:	fb5fe06f          	j	ffffffffc0201aa4 <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202af4:	6785                	lui	a5,0x1
ffffffffc0202af6:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7611>
ffffffffc0202af8:	96be                	add	a3,a3,a5
ffffffffc0202afa:	77fd                	lui	a5,0xfffff
ffffffffc0202afc:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc0202afe:	00c7d693          	srli	a3,a5,0xc
ffffffffc0202b02:	14c6f163          	bgeu	a3,a2,ffffffffc0202c44 <pmm_init+0x6da>
    pmm_manager->init_memmap(base, n);
ffffffffc0202b06:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0202b0a:	fff805b7          	lui	a1,0xfff80
ffffffffc0202b0e:	96ae                	add	a3,a3,a1
ffffffffc0202b10:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202b12:	8f1d                	sub	a4,a4,a5
ffffffffc0202b14:	069a                	slli	a3,a3,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202b16:	00c75593          	srli	a1,a4,0xc
ffffffffc0202b1a:	9536                	add	a0,a0,a3
ffffffffc0202b1c:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202b1e:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202b22:	be05                	j	ffffffffc0202652 <pmm_init+0xe8>
        intr_disable();
ffffffffc0202b24:	b1dfd0ef          	jal	ffffffffc0200640 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b28:	000bb783          	ld	a5,0(s7)
ffffffffc0202b2c:	779c                	ld	a5,40(a5)
ffffffffc0202b2e:	9782                	jalr	a5
ffffffffc0202b30:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202b32:	b09fd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202b36:	bead                	j	ffffffffc02026b0 <pmm_init+0x146>
        intr_disable();
ffffffffc0202b38:	b09fd0ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc0202b3c:	000bb783          	ld	a5,0(s7)
ffffffffc0202b40:	779c                	ld	a5,40(a5)
ffffffffc0202b42:	9782                	jalr	a5
ffffffffc0202b44:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202b46:	af5fd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202b4a:	b3c5                	j	ffffffffc020292a <pmm_init+0x3c0>
        intr_disable();
ffffffffc0202b4c:	af5fd0ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc0202b50:	000bb783          	ld	a5,0(s7)
ffffffffc0202b54:	779c                	ld	a5,40(a5)
ffffffffc0202b56:	9782                	jalr	a5
ffffffffc0202b58:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202b5a:	ae1fd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202b5e:	b365                	j	ffffffffc0202906 <pmm_init+0x39c>
ffffffffc0202b60:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202b62:	adffd0ef          	jal	ffffffffc0200640 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202b66:	000bb783          	ld	a5,0(s7)
ffffffffc0202b6a:	6522                	ld	a0,8(sp)
ffffffffc0202b6c:	4585                	li	a1,1
ffffffffc0202b6e:	739c                	ld	a5,32(a5)
ffffffffc0202b70:	9782                	jalr	a5
        intr_enable();
ffffffffc0202b72:	ac9fd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202b76:	bb85                	j	ffffffffc02028e6 <pmm_init+0x37c>
ffffffffc0202b78:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202b7a:	ac7fd0ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc0202b7e:	000bb783          	ld	a5,0(s7)
ffffffffc0202b82:	6522                	ld	a0,8(sp)
ffffffffc0202b84:	4585                	li	a1,1
ffffffffc0202b86:	739c                	ld	a5,32(a5)
ffffffffc0202b88:	9782                	jalr	a5
        intr_enable();
ffffffffc0202b8a:	ab1fd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202b8e:	b325                	j	ffffffffc02028b6 <pmm_init+0x34c>
        intr_disable();
ffffffffc0202b90:	ab1fd0ef          	jal	ffffffffc0200640 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b94:	000bb783          	ld	a5,0(s7)
ffffffffc0202b98:	779c                	ld	a5,40(a5)
ffffffffc0202b9a:	9782                	jalr	a5
ffffffffc0202b9c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202b9e:	a9dfd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202ba2:	b725                	j	ffffffffc0202aca <pmm_init+0x560>
ffffffffc0202ba4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ba6:	a9bfd0ef          	jal	ffffffffc0200640 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202baa:	000bb783          	ld	a5,0(s7)
ffffffffc0202bae:	6522                	ld	a0,8(sp)
ffffffffc0202bb0:	4585                	li	a1,1
ffffffffc0202bb2:	739c                	ld	a5,32(a5)
ffffffffc0202bb4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bb6:	a85fd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202bba:	bdc5                	j	ffffffffc0202aaa <pmm_init+0x540>
ffffffffc0202bbc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202bbe:	a83fd0ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc0202bc2:	000bb783          	ld	a5,0(s7)
ffffffffc0202bc6:	6522                	ld	a0,8(sp)
ffffffffc0202bc8:	4585                	li	a1,1
ffffffffc0202bca:	739c                	ld	a5,32(a5)
ffffffffc0202bcc:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bce:	a6dfd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202bd2:	b565                	j	ffffffffc0202a7a <pmm_init+0x510>
        intr_disable();
ffffffffc0202bd4:	a6dfd0ef          	jal	ffffffffc0200640 <intr_disable>
ffffffffc0202bd8:	000bb783          	ld	a5,0(s7)
ffffffffc0202bdc:	4585                	li	a1,1
ffffffffc0202bde:	8522                	mv	a0,s0
ffffffffc0202be0:	739c                	ld	a5,32(a5)
ffffffffc0202be2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202be4:	a57fd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0202be8:	b58d                	j	ffffffffc0202a4a <pmm_init+0x4e0>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bea:	00005697          	auipc	a3,0x5
ffffffffc0202bee:	d9e68693          	addi	a3,a3,-610 # ffffffffc0207988 <etext+0x11cc>
ffffffffc0202bf2:	00004617          	auipc	a2,0x4
ffffffffc0202bf6:	24660613          	addi	a2,a2,582 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202bfa:	23500593          	li	a1,565
ffffffffc0202bfe:	00005517          	auipc	a0,0x5
ffffffffc0202c02:	97a50513          	addi	a0,a0,-1670 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202c06:	86ffd0ef          	jal	ffffffffc0200474 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202c0a:	00005697          	auipc	a3,0x5
ffffffffc0202c0e:	d3e68693          	addi	a3,a3,-706 # ffffffffc0207948 <etext+0x118c>
ffffffffc0202c12:	00004617          	auipc	a2,0x4
ffffffffc0202c16:	22660613          	addi	a2,a2,550 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202c1a:	23400593          	li	a1,564
ffffffffc0202c1e:	00005517          	auipc	a0,0x5
ffffffffc0202c22:	95a50513          	addi	a0,a0,-1702 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202c26:	84ffd0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc0202c2a:	86a2                	mv	a3,s0
ffffffffc0202c2c:	00005617          	auipc	a2,0x5
ffffffffc0202c30:	83460613          	addi	a2,a2,-1996 # ffffffffc0207460 <etext+0xca4>
ffffffffc0202c34:	23400593          	li	a1,564
ffffffffc0202c38:	00005517          	auipc	a0,0x5
ffffffffc0202c3c:	94050513          	addi	a0,a0,-1728 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202c40:	835fd0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc0202c44:	824ff0ef          	jal	ffffffffc0201c68 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202c48:	00005617          	auipc	a2,0x5
ffffffffc0202c4c:	8c060613          	addi	a2,a2,-1856 # ffffffffc0207508 <etext+0xd4c>
ffffffffc0202c50:	07f00593          	li	a1,127
ffffffffc0202c54:	00005517          	auipc	a0,0x5
ffffffffc0202c58:	92450513          	addi	a0,a0,-1756 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202c5c:	819fd0ef          	jal	ffffffffc0200474 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202c60:	00005617          	auipc	a2,0x5
ffffffffc0202c64:	8a860613          	addi	a2,a2,-1880 # ffffffffc0207508 <etext+0xd4c>
ffffffffc0202c68:	0c100593          	li	a1,193
ffffffffc0202c6c:	00005517          	auipc	a0,0x5
ffffffffc0202c70:	90c50513          	addi	a0,a0,-1780 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202c74:	801fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202c78:	00005697          	auipc	a3,0x5
ffffffffc0202c7c:	a0868693          	addi	a3,a3,-1528 # ffffffffc0207680 <etext+0xec4>
ffffffffc0202c80:	00004617          	auipc	a2,0x4
ffffffffc0202c84:	1b860613          	addi	a2,a2,440 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202c88:	1f800593          	li	a1,504
ffffffffc0202c8c:	00005517          	auipc	a0,0x5
ffffffffc0202c90:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202c94:	fe0fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202c98:	00005697          	auipc	a3,0x5
ffffffffc0202c9c:	9c868693          	addi	a3,a3,-1592 # ffffffffc0207660 <etext+0xea4>
ffffffffc0202ca0:	00004617          	auipc	a2,0x4
ffffffffc0202ca4:	19860613          	addi	a2,a2,408 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202ca8:	1f700593          	li	a1,503
ffffffffc0202cac:	00005517          	auipc	a0,0x5
ffffffffc0202cb0:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202cb4:	fc0fd0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc0202cb8:	fcdfe0ef          	jal	ffffffffc0201c84 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202cbc:	00005697          	auipc	a3,0x5
ffffffffc0202cc0:	a5468693          	addi	a3,a3,-1452 # ffffffffc0207710 <etext+0xf54>
ffffffffc0202cc4:	00004617          	auipc	a2,0x4
ffffffffc0202cc8:	17460613          	addi	a2,a2,372 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202ccc:	20000593          	li	a1,512
ffffffffc0202cd0:	00005517          	auipc	a0,0x5
ffffffffc0202cd4:	8a850513          	addi	a0,a0,-1880 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202cd8:	f9cfd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202cdc:	00005697          	auipc	a3,0x5
ffffffffc0202ce0:	a0468693          	addi	a3,a3,-1532 # ffffffffc02076e0 <etext+0xf24>
ffffffffc0202ce4:	00004617          	auipc	a2,0x4
ffffffffc0202ce8:	15460613          	addi	a2,a2,340 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202cec:	1fd00593          	li	a1,509
ffffffffc0202cf0:	00005517          	auipc	a0,0x5
ffffffffc0202cf4:	88850513          	addi	a0,a0,-1912 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202cf8:	f7cfd0ef          	jal	ffffffffc0200474 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202cfc:	00005697          	auipc	a3,0x5
ffffffffc0202d00:	9bc68693          	addi	a3,a3,-1604 # ffffffffc02076b8 <etext+0xefc>
ffffffffc0202d04:	00004617          	auipc	a2,0x4
ffffffffc0202d08:	13460613          	addi	a2,a2,308 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202d0c:	1f900593          	li	a1,505
ffffffffc0202d10:	00005517          	auipc	a0,0x5
ffffffffc0202d14:	86850513          	addi	a0,a0,-1944 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202d18:	f5cfd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d1c:	00005697          	auipc	a3,0x5
ffffffffc0202d20:	a7c68693          	addi	a3,a3,-1412 # ffffffffc0207798 <etext+0xfdc>
ffffffffc0202d24:	00004617          	auipc	a2,0x4
ffffffffc0202d28:	11460613          	addi	a2,a2,276 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202d2c:	20900593          	li	a1,521
ffffffffc0202d30:	00005517          	auipc	a0,0x5
ffffffffc0202d34:	84850513          	addi	a0,a0,-1976 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202d38:	f3cfd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202d3c:	00005697          	auipc	a3,0x5
ffffffffc0202d40:	afc68693          	addi	a3,a3,-1284 # ffffffffc0207838 <etext+0x107c>
ffffffffc0202d44:	00004617          	auipc	a2,0x4
ffffffffc0202d48:	0f460613          	addi	a2,a2,244 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202d4c:	20e00593          	li	a1,526
ffffffffc0202d50:	00005517          	auipc	a0,0x5
ffffffffc0202d54:	82850513          	addi	a0,a0,-2008 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202d58:	f1cfd0ef          	jal	ffffffffc0200474 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202d5c:	00005697          	auipc	a3,0x5
ffffffffc0202d60:	a1468693          	addi	a3,a3,-1516 # ffffffffc0207770 <etext+0xfb4>
ffffffffc0202d64:	00004617          	auipc	a2,0x4
ffffffffc0202d68:	0d460613          	addi	a2,a2,212 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202d6c:	20600593          	li	a1,518
ffffffffc0202d70:	00005517          	auipc	a0,0x5
ffffffffc0202d74:	80850513          	addi	a0,a0,-2040 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202d78:	efcfd0ef          	jal	ffffffffc0200474 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202d7c:	86d6                	mv	a3,s5
ffffffffc0202d7e:	00004617          	auipc	a2,0x4
ffffffffc0202d82:	6e260613          	addi	a2,a2,1762 # ffffffffc0207460 <etext+0xca4>
ffffffffc0202d86:	20500593          	li	a1,517
ffffffffc0202d8a:	00004517          	auipc	a0,0x4
ffffffffc0202d8e:	7ee50513          	addi	a0,a0,2030 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202d92:	ee2fd0ef          	jal	ffffffffc0200474 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202d96:	00005697          	auipc	a3,0x5
ffffffffc0202d9a:	a3a68693          	addi	a3,a3,-1478 # ffffffffc02077d0 <etext+0x1014>
ffffffffc0202d9e:	00004617          	auipc	a2,0x4
ffffffffc0202da2:	09a60613          	addi	a2,a2,154 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202da6:	21300593          	li	a1,531
ffffffffc0202daa:	00004517          	auipc	a0,0x4
ffffffffc0202dae:	7ce50513          	addi	a0,a0,1998 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202db2:	ec2fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202db6:	00005697          	auipc	a3,0x5
ffffffffc0202dba:	ae268693          	addi	a3,a3,-1310 # ffffffffc0207898 <etext+0x10dc>
ffffffffc0202dbe:	00004617          	auipc	a2,0x4
ffffffffc0202dc2:	07a60613          	addi	a2,a2,122 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202dc6:	21200593          	li	a1,530
ffffffffc0202dca:	00004517          	auipc	a0,0x4
ffffffffc0202dce:	7ae50513          	addi	a0,a0,1966 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202dd2:	ea2fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202dd6:	00005697          	auipc	a3,0x5
ffffffffc0202dda:	aaa68693          	addi	a3,a3,-1366 # ffffffffc0207880 <etext+0x10c4>
ffffffffc0202dde:	00004617          	auipc	a2,0x4
ffffffffc0202de2:	05a60613          	addi	a2,a2,90 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202de6:	21100593          	li	a1,529
ffffffffc0202dea:	00004517          	auipc	a0,0x4
ffffffffc0202dee:	78e50513          	addi	a0,a0,1934 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202df2:	e82fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202df6:	00005697          	auipc	a3,0x5
ffffffffc0202dfa:	a5a68693          	addi	a3,a3,-1446 # ffffffffc0207850 <etext+0x1094>
ffffffffc0202dfe:	00004617          	auipc	a2,0x4
ffffffffc0202e02:	03a60613          	addi	a2,a2,58 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202e06:	21000593          	li	a1,528
ffffffffc0202e0a:	00004517          	auipc	a0,0x4
ffffffffc0202e0e:	76e50513          	addi	a0,a0,1902 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202e12:	e62fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202e16:	00005697          	auipc	a3,0x5
ffffffffc0202e1a:	bf268693          	addi	a3,a3,-1038 # ffffffffc0207a08 <etext+0x124c>
ffffffffc0202e1e:	00004617          	auipc	a2,0x4
ffffffffc0202e22:	01a60613          	addi	a2,a2,26 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202e26:	23f00593          	li	a1,575
ffffffffc0202e2a:	00004517          	auipc	a0,0x4
ffffffffc0202e2e:	74e50513          	addi	a0,a0,1870 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202e32:	e42fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202e36:	00005697          	auipc	a3,0x5
ffffffffc0202e3a:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0207820 <etext+0x1064>
ffffffffc0202e3e:	00004617          	auipc	a2,0x4
ffffffffc0202e42:	ffa60613          	addi	a2,a2,-6 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202e46:	20d00593          	li	a1,525
ffffffffc0202e4a:	00004517          	auipc	a0,0x4
ffffffffc0202e4e:	72e50513          	addi	a0,a0,1838 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202e52:	e22fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202e56:	00005697          	auipc	a3,0x5
ffffffffc0202e5a:	9ba68693          	addi	a3,a3,-1606 # ffffffffc0207810 <etext+0x1054>
ffffffffc0202e5e:	00004617          	auipc	a2,0x4
ffffffffc0202e62:	fda60613          	addi	a2,a2,-38 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202e66:	20c00593          	li	a1,524
ffffffffc0202e6a:	00004517          	auipc	a0,0x4
ffffffffc0202e6e:	70e50513          	addi	a0,a0,1806 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202e72:	e02fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202e76:	00005697          	auipc	a3,0x5
ffffffffc0202e7a:	a9268693          	addi	a3,a3,-1390 # ffffffffc0207908 <etext+0x114c>
ffffffffc0202e7e:	00004617          	auipc	a2,0x4
ffffffffc0202e82:	fba60613          	addi	a2,a2,-70 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202e86:	25000593          	li	a1,592
ffffffffc0202e8a:	00004517          	auipc	a0,0x4
ffffffffc0202e8e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202e92:	de2fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202e96:	00005697          	auipc	a3,0x5
ffffffffc0202e9a:	96a68693          	addi	a3,a3,-1686 # ffffffffc0207800 <etext+0x1044>
ffffffffc0202e9e:	00004617          	auipc	a2,0x4
ffffffffc0202ea2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202ea6:	20b00593          	li	a1,523
ffffffffc0202eaa:	00004517          	auipc	a0,0x4
ffffffffc0202eae:	6ce50513          	addi	a0,a0,1742 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202eb2:	dc2fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202eb6:	00005697          	auipc	a3,0x5
ffffffffc0202eba:	8a268693          	addi	a3,a3,-1886 # ffffffffc0207758 <etext+0xf9c>
ffffffffc0202ebe:	00004617          	auipc	a2,0x4
ffffffffc0202ec2:	f7a60613          	addi	a2,a2,-134 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202ec6:	21800593          	li	a1,536
ffffffffc0202eca:	00004517          	auipc	a0,0x4
ffffffffc0202ece:	6ae50513          	addi	a0,a0,1710 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202ed2:	da2fd0ef          	jal	ffffffffc0200474 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202ed6:	00005697          	auipc	a3,0x5
ffffffffc0202eda:	9da68693          	addi	a3,a3,-1574 # ffffffffc02078b0 <etext+0x10f4>
ffffffffc0202ede:	00004617          	auipc	a2,0x4
ffffffffc0202ee2:	f5a60613          	addi	a2,a2,-166 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202ee6:	21500593          	li	a1,533
ffffffffc0202eea:	00004517          	auipc	a0,0x4
ffffffffc0202eee:	68e50513          	addi	a0,a0,1678 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202ef2:	d82fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202ef6:	00005697          	auipc	a3,0x5
ffffffffc0202efa:	84a68693          	addi	a3,a3,-1974 # ffffffffc0207740 <etext+0xf84>
ffffffffc0202efe:	00004617          	auipc	a2,0x4
ffffffffc0202f02:	f3a60613          	addi	a2,a2,-198 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202f06:	21400593          	li	a1,532
ffffffffc0202f0a:	00004517          	auipc	a0,0x4
ffffffffc0202f0e:	66e50513          	addi	a0,a0,1646 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202f12:	d62fd0ef          	jal	ffffffffc0200474 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f16:	00004617          	auipc	a2,0x4
ffffffffc0202f1a:	54a60613          	addi	a2,a2,1354 # ffffffffc0207460 <etext+0xca4>
ffffffffc0202f1e:	06900593          	li	a1,105
ffffffffc0202f22:	00004517          	auipc	a0,0x4
ffffffffc0202f26:	56650513          	addi	a0,a0,1382 # ffffffffc0207488 <etext+0xccc>
ffffffffc0202f2a:	d4afd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202f2e:	00005697          	auipc	a3,0x5
ffffffffc0202f32:	9b268693          	addi	a3,a3,-1614 # ffffffffc02078e0 <etext+0x1124>
ffffffffc0202f36:	00004617          	auipc	a2,0x4
ffffffffc0202f3a:	f0260613          	addi	a2,a2,-254 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202f3e:	21f00593          	li	a1,543
ffffffffc0202f42:	00004517          	auipc	a0,0x4
ffffffffc0202f46:	63650513          	addi	a0,a0,1590 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202f4a:	d2afd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f4e:	00005697          	auipc	a3,0x5
ffffffffc0202f52:	94a68693          	addi	a3,a3,-1718 # ffffffffc0207898 <etext+0x10dc>
ffffffffc0202f56:	00004617          	auipc	a2,0x4
ffffffffc0202f5a:	ee260613          	addi	a2,a2,-286 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202f5e:	21d00593          	li	a1,541
ffffffffc0202f62:	00004517          	auipc	a0,0x4
ffffffffc0202f66:	61650513          	addi	a0,a0,1558 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202f6a:	d0afd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f6e:	00005697          	auipc	a3,0x5
ffffffffc0202f72:	95a68693          	addi	a3,a3,-1702 # ffffffffc02078c8 <etext+0x110c>
ffffffffc0202f76:	00004617          	auipc	a2,0x4
ffffffffc0202f7a:	ec260613          	addi	a2,a2,-318 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202f7e:	21c00593          	li	a1,540
ffffffffc0202f82:	00004517          	auipc	a0,0x4
ffffffffc0202f86:	5f650513          	addi	a0,a0,1526 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202f8a:	ceafd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f8e:	00005697          	auipc	a3,0x5
ffffffffc0202f92:	90a68693          	addi	a3,a3,-1782 # ffffffffc0207898 <etext+0x10dc>
ffffffffc0202f96:	00004617          	auipc	a2,0x4
ffffffffc0202f9a:	ea260613          	addi	a2,a2,-350 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202f9e:	21900593          	li	a1,537
ffffffffc0202fa2:	00004517          	auipc	a0,0x4
ffffffffc0202fa6:	5d650513          	addi	a0,a0,1494 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202faa:	ccafd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fae:	00005697          	auipc	a3,0x5
ffffffffc0202fb2:	a4268693          	addi	a3,a3,-1470 # ffffffffc02079f0 <etext+0x1234>
ffffffffc0202fb6:	00004617          	auipc	a2,0x4
ffffffffc0202fba:	e8260613          	addi	a2,a2,-382 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202fbe:	23e00593          	li	a1,574
ffffffffc0202fc2:	00004517          	auipc	a0,0x4
ffffffffc0202fc6:	5b650513          	addi	a0,a0,1462 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202fca:	caafd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202fce:	00005697          	auipc	a3,0x5
ffffffffc0202fd2:	9ea68693          	addi	a3,a3,-1558 # ffffffffc02079b8 <etext+0x11fc>
ffffffffc0202fd6:	00004617          	auipc	a2,0x4
ffffffffc0202fda:	e6260613          	addi	a2,a2,-414 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202fde:	23d00593          	li	a1,573
ffffffffc0202fe2:	00004517          	auipc	a0,0x4
ffffffffc0202fe6:	59650513          	addi	a0,a0,1430 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0202fea:	c8afd0ef          	jal	ffffffffc0200474 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0202fee:	00005697          	auipc	a3,0x5
ffffffffc0202ff2:	9b268693          	addi	a3,a3,-1614 # ffffffffc02079a0 <etext+0x11e4>
ffffffffc0202ff6:	00004617          	auipc	a2,0x4
ffffffffc0202ffa:	e4260613          	addi	a2,a2,-446 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0202ffe:	23900593          	li	a1,569
ffffffffc0203002:	00004517          	auipc	a0,0x4
ffffffffc0203006:	57650513          	addi	a0,a0,1398 # ffffffffc0207578 <etext+0xdbc>
ffffffffc020300a:	c6afd0ef          	jal	ffffffffc0200474 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020300e:	00005697          	auipc	a3,0x5
ffffffffc0203012:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0207908 <etext+0x114c>
ffffffffc0203016:	00004617          	auipc	a2,0x4
ffffffffc020301a:	e2260613          	addi	a2,a2,-478 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020301e:	22700593          	li	a1,551
ffffffffc0203022:	00004517          	auipc	a0,0x4
ffffffffc0203026:	55650513          	addi	a0,a0,1366 # ffffffffc0207578 <etext+0xdbc>
ffffffffc020302a:	c4afd0ef          	jal	ffffffffc0200474 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020302e:	00004697          	auipc	a3,0x4
ffffffffc0203032:	71268693          	addi	a3,a3,1810 # ffffffffc0207740 <etext+0xf84>
ffffffffc0203036:	00004617          	auipc	a2,0x4
ffffffffc020303a:	e0260613          	addi	a2,a2,-510 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020303e:	20100593          	li	a1,513
ffffffffc0203042:	00004517          	auipc	a0,0x4
ffffffffc0203046:	53650513          	addi	a0,a0,1334 # ffffffffc0207578 <etext+0xdbc>
ffffffffc020304a:	c2afd0ef          	jal	ffffffffc0200474 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020304e:	00004617          	auipc	a2,0x4
ffffffffc0203052:	41260613          	addi	a2,a2,1042 # ffffffffc0207460 <etext+0xca4>
ffffffffc0203056:	20400593          	li	a1,516
ffffffffc020305a:	00004517          	auipc	a0,0x4
ffffffffc020305e:	51e50513          	addi	a0,a0,1310 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0203062:	c12fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203066:	00004697          	auipc	a3,0x4
ffffffffc020306a:	6f268693          	addi	a3,a3,1778 # ffffffffc0207758 <etext+0xf9c>
ffffffffc020306e:	00004617          	auipc	a2,0x4
ffffffffc0203072:	dca60613          	addi	a2,a2,-566 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203076:	20200593          	li	a1,514
ffffffffc020307a:	00004517          	auipc	a0,0x4
ffffffffc020307e:	4fe50513          	addi	a0,a0,1278 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0203082:	bf2fd0ef          	jal	ffffffffc0200474 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203086:	00004697          	auipc	a3,0x4
ffffffffc020308a:	74a68693          	addi	a3,a3,1866 # ffffffffc02077d0 <etext+0x1014>
ffffffffc020308e:	00004617          	auipc	a2,0x4
ffffffffc0203092:	daa60613          	addi	a2,a2,-598 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203096:	20a00593          	li	a1,522
ffffffffc020309a:	00004517          	auipc	a0,0x4
ffffffffc020309e:	4de50513          	addi	a0,a0,1246 # ffffffffc0207578 <etext+0xdbc>
ffffffffc02030a2:	bd2fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02030a6:	00005697          	auipc	a3,0x5
ffffffffc02030aa:	a0a68693          	addi	a3,a3,-1526 # ffffffffc0207ab0 <etext+0x12f4>
ffffffffc02030ae:	00004617          	auipc	a2,0x4
ffffffffc02030b2:	d8a60613          	addi	a2,a2,-630 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02030b6:	24700593          	li	a1,583
ffffffffc02030ba:	00004517          	auipc	a0,0x4
ffffffffc02030be:	4be50513          	addi	a0,a0,1214 # ffffffffc0207578 <etext+0xdbc>
ffffffffc02030c2:	bb2fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02030c6:	00005697          	auipc	a3,0x5
ffffffffc02030ca:	9b268693          	addi	a3,a3,-1614 # ffffffffc0207a78 <etext+0x12bc>
ffffffffc02030ce:	00004617          	auipc	a2,0x4
ffffffffc02030d2:	d6a60613          	addi	a2,a2,-662 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02030d6:	24400593          	li	a1,580
ffffffffc02030da:	00004517          	auipc	a0,0x4
ffffffffc02030de:	49e50513          	addi	a0,a0,1182 # ffffffffc0207578 <etext+0xdbc>
ffffffffc02030e2:	b92fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02030e6:	00005697          	auipc	a3,0x5
ffffffffc02030ea:	96268693          	addi	a3,a3,-1694 # ffffffffc0207a48 <etext+0x128c>
ffffffffc02030ee:	00004617          	auipc	a2,0x4
ffffffffc02030f2:	d4a60613          	addi	a2,a2,-694 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02030f6:	24000593          	li	a1,576
ffffffffc02030fa:	00004517          	auipc	a0,0x4
ffffffffc02030fe:	47e50513          	addi	a0,a0,1150 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0203102:	b72fd0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0203106 <copy_range>:
               bool share) {
ffffffffc0203106:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203108:	00d667b3          	or	a5,a2,a3
               bool share) {
ffffffffc020310c:	fc86                	sd	ra,120(sp)
ffffffffc020310e:	f8a2                	sd	s0,112(sp)
ffffffffc0203110:	f4a6                	sd	s1,104(sp)
ffffffffc0203112:	f0ca                	sd	s2,96(sp)
ffffffffc0203114:	ecce                	sd	s3,88(sp)
ffffffffc0203116:	e8d2                	sd	s4,80(sp)
ffffffffc0203118:	e4d6                	sd	s5,72(sp)
ffffffffc020311a:	e0da                	sd	s6,64(sp)
ffffffffc020311c:	fc5e                	sd	s7,56(sp)
ffffffffc020311e:	f862                	sd	s8,48(sp)
ffffffffc0203120:	f466                	sd	s9,40(sp)
ffffffffc0203122:	f06a                	sd	s10,32(sp)
ffffffffc0203124:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203126:	17d2                	slli	a5,a5,0x34
ffffffffc0203128:	1a079c63          	bnez	a5,ffffffffc02032e0 <copy_range+0x1da>
    assert(USER_ACCESS(start, end));
ffffffffc020312c:	002007b7          	lui	a5,0x200
ffffffffc0203130:	8432                	mv	s0,a2
ffffffffc0203132:	14f66863          	bltu	a2,a5,ffffffffc0203282 <copy_range+0x17c>
ffffffffc0203136:	89b6                	mv	s3,a3
ffffffffc0203138:	14d67563          	bgeu	a2,a3,ffffffffc0203282 <copy_range+0x17c>
ffffffffc020313c:	4785                	li	a5,1
ffffffffc020313e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203140:	14d7e163          	bltu	a5,a3,ffffffffc0203282 <copy_range+0x17c>
ffffffffc0203144:	8aaa                	mv	s5,a0
ffffffffc0203146:	892e                	mv	s2,a1
ffffffffc0203148:	8b3a                	mv	s6,a4
        start += PGSIZE;
ffffffffc020314a:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc020314c:	0009bc97          	auipc	s9,0x9b
ffffffffc0203150:	b74c8c93          	addi	s9,s9,-1164 # ffffffffc029dcc0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203154:	0009bc17          	auipc	s8,0x9b
ffffffffc0203158:	b74c0c13          	addi	s8,s8,-1164 # ffffffffc029dcc8 <pages>
ffffffffc020315c:	fff80bb7          	lui	s7,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203160:	00200db7          	lui	s11,0x200
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203164:	4601                	li	a2,0
ffffffffc0203166:	85a2                	mv	a1,s0
ffffffffc0203168:	854a                	mv	a0,s2
ffffffffc020316a:	c41fe0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc020316e:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc0203170:	c555                	beqz	a0,ffffffffc020321c <copy_range+0x116>
        if (*ptep & PTE_V) {
ffffffffc0203172:	611c                	ld	a5,0(a0)
ffffffffc0203174:	8b85                	andi	a5,a5,1
ffffffffc0203176:	e78d                	bnez	a5,ffffffffc02031a0 <copy_range+0x9a>
        start += PGSIZE;
ffffffffc0203178:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020317a:	c019                	beqz	s0,ffffffffc0203180 <copy_range+0x7a>
ffffffffc020317c:	ff3464e3          	bltu	s0,s3,ffffffffc0203164 <copy_range+0x5e>
    return 0;
ffffffffc0203180:	4501                	li	a0,0
}
ffffffffc0203182:	70e6                	ld	ra,120(sp)
ffffffffc0203184:	7446                	ld	s0,112(sp)
ffffffffc0203186:	74a6                	ld	s1,104(sp)
ffffffffc0203188:	7906                	ld	s2,96(sp)
ffffffffc020318a:	69e6                	ld	s3,88(sp)
ffffffffc020318c:	6a46                	ld	s4,80(sp)
ffffffffc020318e:	6aa6                	ld	s5,72(sp)
ffffffffc0203190:	6b06                	ld	s6,64(sp)
ffffffffc0203192:	7be2                	ld	s7,56(sp)
ffffffffc0203194:	7c42                	ld	s8,48(sp)
ffffffffc0203196:	7ca2                	ld	s9,40(sp)
ffffffffc0203198:	7d02                	ld	s10,32(sp)
ffffffffc020319a:	6de2                	ld	s11,24(sp)
ffffffffc020319c:	6109                	addi	sp,sp,128
ffffffffc020319e:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc02031a0:	4605                	li	a2,1
ffffffffc02031a2:	85a2                	mv	a1,s0
ffffffffc02031a4:	8556                	mv	a0,s5
ffffffffc02031a6:	c05fe0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc02031aa:	cd35                	beqz	a0,ffffffffc0203226 <copy_range+0x120>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02031ac:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V)) {
ffffffffc02031ae:	0017f713          	andi	a4,a5,1
ffffffffc02031b2:	00078d1b          	sext.w	s10,a5
ffffffffc02031b6:	10070963          	beqz	a4,ffffffffc02032c8 <copy_range+0x1c2>
    if (PPN(pa) >= npage) {
ffffffffc02031ba:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02031be:	078a                	slli	a5,a5,0x2
ffffffffc02031c0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02031c2:	0ae7f463          	bgeu	a5,a4,ffffffffc020326a <copy_range+0x164>
    return &pages[PPN(pa) - nbase];
ffffffffc02031c6:	000c3483          	ld	s1,0(s8)
ffffffffc02031ca:	97de                	add	a5,a5,s7
ffffffffc02031cc:	079a                	slli	a5,a5,0x6
ffffffffc02031ce:	94be                	add	s1,s1,a5
            struct Page *npage = alloc_page();
ffffffffc02031d0:	4505                	li	a0,1
ffffffffc02031d2:	acffe0ef          	jal	ffffffffc0201ca0 <alloc_pages>
            assert(page != NULL);
ffffffffc02031d6:	c8b5                	beqz	s1,ffffffffc020324a <copy_range+0x144>
            assert(npage != NULL);
ffffffffc02031d8:	c929                	beqz	a0,ffffffffc020322a <copy_range+0x124>
            if (share) {
ffffffffc02031da:	0c0b0463          	beqz	s6,ffffffffc02032a2 <copy_range+0x19c>
            page_insert(from, page, start, perm & (~PTE_W));
ffffffffc02031de:	01bd7693          	andi	a3,s10,27
ffffffffc02031e2:	8622                	mv	a2,s0
ffffffffc02031e4:	85a6                	mv	a1,s1
ffffffffc02031e6:	854a                	mv	a0,s2
ffffffffc02031e8:	e436                	sd	a3,8(sp)
ffffffffc02031ea:	a8cff0ef          	jal	ffffffffc0202476 <page_insert>
        ret = page_insert(to, page, start, perm & (~PTE_W));
ffffffffc02031ee:	66a2                	ld	a3,8(sp)
ffffffffc02031f0:	8622                	mv	a2,s0
ffffffffc02031f2:	85a6                	mv	a1,s1
ffffffffc02031f4:	8556                	mv	a0,s5
ffffffffc02031f6:	a80ff0ef          	jal	ffffffffc0202476 <page_insert>
            assert(ret == 0);
ffffffffc02031fa:	dd3d                	beqz	a0,ffffffffc0203178 <copy_range+0x72>
ffffffffc02031fc:	00005697          	auipc	a3,0x5
ffffffffc0203200:	92c68693          	addi	a3,a3,-1748 # ffffffffc0207b28 <etext+0x136c>
ffffffffc0203204:	00004617          	auipc	a2,0x4
ffffffffc0203208:	c3460613          	addi	a2,a2,-972 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020320c:	19900593          	li	a1,409
ffffffffc0203210:	00004517          	auipc	a0,0x4
ffffffffc0203214:	36850513          	addi	a0,a0,872 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0203218:	a5cfd0ef          	jal	ffffffffc0200474 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020321c:	946e                	add	s0,s0,s11
ffffffffc020321e:	ffe007b7          	lui	a5,0xffe00
ffffffffc0203222:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc0203224:	bf99                	j	ffffffffc020317a <copy_range+0x74>
                return -E_NO_MEM;
ffffffffc0203226:	5571                	li	a0,-4
ffffffffc0203228:	bfa9                	j	ffffffffc0203182 <copy_range+0x7c>
            assert(npage != NULL);
ffffffffc020322a:	00005697          	auipc	a3,0x5
ffffffffc020322e:	8de68693          	addi	a3,a3,-1826 # ffffffffc0207b08 <etext+0x134c>
ffffffffc0203232:	00004617          	auipc	a2,0x4
ffffffffc0203236:	c0660613          	addi	a2,a2,-1018 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020323a:	17300593          	li	a1,371
ffffffffc020323e:	00004517          	auipc	a0,0x4
ffffffffc0203242:	33a50513          	addi	a0,a0,826 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0203246:	a2efd0ef          	jal	ffffffffc0200474 <__panic>
            assert(page != NULL);
ffffffffc020324a:	00005697          	auipc	a3,0x5
ffffffffc020324e:	8ae68693          	addi	a3,a3,-1874 # ffffffffc0207af8 <etext+0x133c>
ffffffffc0203252:	00004617          	auipc	a2,0x4
ffffffffc0203256:	be660613          	addi	a2,a2,-1050 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020325a:	17200593          	li	a1,370
ffffffffc020325e:	00004517          	auipc	a0,0x4
ffffffffc0203262:	31a50513          	addi	a0,a0,794 # ffffffffc0207578 <etext+0xdbc>
ffffffffc0203266:	a0efd0ef          	jal	ffffffffc0200474 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020326a:	00004617          	auipc	a2,0x4
ffffffffc020326e:	2c660613          	addi	a2,a2,710 # ffffffffc0207530 <etext+0xd74>
ffffffffc0203272:	06200593          	li	a1,98
ffffffffc0203276:	00004517          	auipc	a0,0x4
ffffffffc020327a:	21250513          	addi	a0,a0,530 # ffffffffc0207488 <etext+0xccc>
ffffffffc020327e:	9f6fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203282:	00004697          	auipc	a3,0x4
ffffffffc0203286:	33668693          	addi	a3,a3,822 # ffffffffc02075b8 <etext+0xdfc>
ffffffffc020328a:	00004617          	auipc	a2,0x4
ffffffffc020328e:	bae60613          	addi	a2,a2,-1106 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203292:	15e00593          	li	a1,350
ffffffffc0203296:	00004517          	auipc	a0,0x4
ffffffffc020329a:	2e250513          	addi	a0,a0,738 # ffffffffc0207578 <etext+0xdbc>
ffffffffc020329e:	9d6fd0ef          	jal	ffffffffc0200474 <__panic>
                struct Page * npage=alloc_page();
ffffffffc02032a2:	4505                	li	a0,1
ffffffffc02032a4:	9fdfe0ef          	jal	ffffffffc0201ca0 <alloc_pages>
assert(npage = NULL);
ffffffffc02032a8:	00005697          	auipc	a3,0x5
ffffffffc02032ac:	87068693          	addi	a3,a3,-1936 # ffffffffc0207b18 <etext+0x135c>
ffffffffc02032b0:	00004617          	auipc	a2,0x4
ffffffffc02032b4:	b8860613          	addi	a2,a2,-1144 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02032b8:	18f00593          	li	a1,399
ffffffffc02032bc:	00004517          	auipc	a0,0x4
ffffffffc02032c0:	2bc50513          	addi	a0,a0,700 # ffffffffc0207578 <etext+0xdbc>
ffffffffc02032c4:	9b0fd0ef          	jal	ffffffffc0200474 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02032c8:	00004617          	auipc	a2,0x4
ffffffffc02032cc:	28860613          	addi	a2,a2,648 # ffffffffc0207550 <etext+0xd94>
ffffffffc02032d0:	07400593          	li	a1,116
ffffffffc02032d4:	00004517          	auipc	a0,0x4
ffffffffc02032d8:	1b450513          	addi	a0,a0,436 # ffffffffc0207488 <etext+0xccc>
ffffffffc02032dc:	998fd0ef          	jal	ffffffffc0200474 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032e0:	00004697          	auipc	a3,0x4
ffffffffc02032e4:	2a868693          	addi	a3,a3,680 # ffffffffc0207588 <etext+0xdcc>
ffffffffc02032e8:	00004617          	auipc	a2,0x4
ffffffffc02032ec:	b5060613          	addi	a2,a2,-1200 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02032f0:	15d00593          	li	a1,349
ffffffffc02032f4:	00004517          	auipc	a0,0x4
ffffffffc02032f8:	28450513          	addi	a0,a0,644 # ffffffffc0207578 <etext+0xdbc>
ffffffffc02032fc:	978fd0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0203300 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203300:	12058073          	sfence.vma	a1
}
ffffffffc0203304:	8082                	ret

ffffffffc0203306 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203306:	7179                	addi	sp,sp,-48
ffffffffc0203308:	e84a                	sd	s2,16(sp)
ffffffffc020330a:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc020330c:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc020330e:	ec26                	sd	s1,24(sp)
ffffffffc0203310:	e44e                	sd	s3,8(sp)
ffffffffc0203312:	f406                	sd	ra,40(sp)
ffffffffc0203314:	f022                	sd	s0,32(sp)
ffffffffc0203316:	84ae                	mv	s1,a1
ffffffffc0203318:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020331a:	987fe0ef          	jal	ffffffffc0201ca0 <alloc_pages>
    if (page != NULL) {
ffffffffc020331e:	c12d                	beqz	a0,ffffffffc0203380 <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0203320:	842a                	mv	s0,a0
ffffffffc0203322:	85aa                	mv	a1,a0
ffffffffc0203324:	86ce                	mv	a3,s3
ffffffffc0203326:	8626                	mv	a2,s1
ffffffffc0203328:	854a                	mv	a0,s2
ffffffffc020332a:	94cff0ef          	jal	ffffffffc0202476 <page_insert>
ffffffffc020332e:	ed0d                	bnez	a0,ffffffffc0203368 <pgdir_alloc_page+0x62>
        if (swap_init_ok) {
ffffffffc0203330:	0009b797          	auipc	a5,0x9b
ffffffffc0203334:	9a07a783          	lw	a5,-1632(a5) # ffffffffc029dcd0 <swap_init_ok>
ffffffffc0203338:	c385                	beqz	a5,ffffffffc0203358 <pgdir_alloc_page+0x52>
            if (check_mm_struct != NULL) {
ffffffffc020333a:	0009b517          	auipc	a0,0x9b
ffffffffc020333e:	9b653503          	ld	a0,-1610(a0) # ffffffffc029dcf0 <check_mm_struct>
ffffffffc0203342:	c919                	beqz	a0,ffffffffc0203358 <pgdir_alloc_page+0x52>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0203344:	4681                	li	a3,0
ffffffffc0203346:	8622                	mv	a2,s0
ffffffffc0203348:	85a6                	mv	a1,s1
ffffffffc020334a:	00f000ef          	jal	ffffffffc0203b58 <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc020334e:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc0203350:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc0203352:	4785                	li	a5,1
ffffffffc0203354:	04f71663          	bne	a4,a5,ffffffffc02033a0 <pgdir_alloc_page+0x9a>
}
ffffffffc0203358:	70a2                	ld	ra,40(sp)
ffffffffc020335a:	8522                	mv	a0,s0
ffffffffc020335c:	7402                	ld	s0,32(sp)
ffffffffc020335e:	64e2                	ld	s1,24(sp)
ffffffffc0203360:	6942                	ld	s2,16(sp)
ffffffffc0203362:	69a2                	ld	s3,8(sp)
ffffffffc0203364:	6145                	addi	sp,sp,48
ffffffffc0203366:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203368:	100027f3          	csrr	a5,sstatus
ffffffffc020336c:	8b89                	andi	a5,a5,2
ffffffffc020336e:	eb99                	bnez	a5,ffffffffc0203384 <pgdir_alloc_page+0x7e>
        pmm_manager->free_pages(base, n);
ffffffffc0203370:	0009b797          	auipc	a5,0x9b
ffffffffc0203374:	9307b783          	ld	a5,-1744(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0203378:	739c                	ld	a5,32(a5)
ffffffffc020337a:	4585                	li	a1,1
ffffffffc020337c:	8522                	mv	a0,s0
ffffffffc020337e:	9782                	jalr	a5
            return NULL;
ffffffffc0203380:	4401                	li	s0,0
ffffffffc0203382:	bfd9                	j	ffffffffc0203358 <pgdir_alloc_page+0x52>
        intr_disable();
ffffffffc0203384:	abcfd0ef          	jal	ffffffffc0200640 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203388:	0009b797          	auipc	a5,0x9b
ffffffffc020338c:	9187b783          	ld	a5,-1768(a5) # ffffffffc029dca0 <pmm_manager>
ffffffffc0203390:	739c                	ld	a5,32(a5)
ffffffffc0203392:	8522                	mv	a0,s0
ffffffffc0203394:	4585                	li	a1,1
ffffffffc0203396:	9782                	jalr	a5
            return NULL;
ffffffffc0203398:	4401                	li	s0,0
        intr_enable();
ffffffffc020339a:	aa0fd0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc020339e:	bf6d                	j	ffffffffc0203358 <pgdir_alloc_page+0x52>
                assert(page_ref(page) == 1);
ffffffffc02033a0:	00004697          	auipc	a3,0x4
ffffffffc02033a4:	79868693          	addi	a3,a3,1944 # ffffffffc0207b38 <etext+0x137c>
ffffffffc02033a8:	00004617          	auipc	a2,0x4
ffffffffc02033ac:	a9060613          	addi	a2,a2,-1392 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02033b0:	1d800593          	li	a1,472
ffffffffc02033b4:	00004517          	auipc	a0,0x4
ffffffffc02033b8:	1c450513          	addi	a0,a0,452 # ffffffffc0207578 <etext+0xdbc>
ffffffffc02033bc:	8b8fd0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02033c0 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc02033c0:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02033c2:	00004617          	auipc	a2,0x4
ffffffffc02033c6:	16e60613          	addi	a2,a2,366 # ffffffffc0207530 <etext+0xd74>
ffffffffc02033ca:	06200593          	li	a1,98
ffffffffc02033ce:	00004517          	auipc	a0,0x4
ffffffffc02033d2:	0ba50513          	addi	a0,a0,186 # ffffffffc0207488 <etext+0xccc>
pa2page(uintptr_t pa) {
ffffffffc02033d6:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc02033d8:	89cfd0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02033dc <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc02033dc:	7135                	addi	sp,sp,-160
ffffffffc02033de:	ed06                	sd	ra,152(sp)
     swapfs_init();
ffffffffc02033e0:	08f010ef          	jal	ffffffffc0204c6e <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02033e4:	0009b697          	auipc	a3,0x9b
ffffffffc02033e8:	8f46b683          	ld	a3,-1804(a3) # ffffffffc029dcd8 <max_swap_offset>
ffffffffc02033ec:	010007b7          	lui	a5,0x1000
ffffffffc02033f0:	ff968713          	addi	a4,a3,-7
ffffffffc02033f4:	17e1                	addi	a5,a5,-8 # fffff8 <_binary_obj___user_exit_out_size+0xff6490>
ffffffffc02033f6:	44e7eb63          	bltu	a5,a4,ffffffffc020384c <swap_init+0x470>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc02033fa:	0008f797          	auipc	a5,0x8f
ffffffffc02033fe:	36e78793          	addi	a5,a5,878 # ffffffffc0292768 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0203402:	6798                	ld	a4,8(a5)
ffffffffc0203404:	e14a                	sd	s2,128(sp)
ffffffffc0203406:	f0da                	sd	s6,96(sp)
     sm = &swap_manager_fifo;
ffffffffc0203408:	0009bb17          	auipc	s6,0x9b
ffffffffc020340c:	8d8b0b13          	addi	s6,s6,-1832 # ffffffffc029dce0 <sm>
ffffffffc0203410:	00fb3023          	sd	a5,0(s6)
     int r = sm->init();
ffffffffc0203414:	9702                	jalr	a4
ffffffffc0203416:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc0203418:	c519                	beqz	a0,ffffffffc0203426 <swap_init+0x4a>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc020341a:	60ea                	ld	ra,152(sp)
ffffffffc020341c:	7b06                	ld	s6,96(sp)
ffffffffc020341e:	854a                	mv	a0,s2
ffffffffc0203420:	690a                	ld	s2,128(sp)
ffffffffc0203422:	610d                	addi	sp,sp,160
ffffffffc0203424:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203426:	000b3783          	ld	a5,0(s6)
ffffffffc020342a:	00004517          	auipc	a0,0x4
ffffffffc020342e:	75650513          	addi	a0,a0,1878 # ffffffffc0207b80 <etext+0x13c4>
ffffffffc0203432:	e922                	sd	s0,144(sp)
ffffffffc0203434:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0203436:	4785                	li	a5,1
ffffffffc0203438:	e0ea                	sd	s10,64(sp)
ffffffffc020343a:	fc6e                	sd	s11,56(sp)
ffffffffc020343c:	0009b717          	auipc	a4,0x9b
ffffffffc0203440:	88f72a23          	sw	a5,-1900(a4) # ffffffffc029dcd0 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203444:	e526                	sd	s1,136(sp)
ffffffffc0203446:	fcce                	sd	s3,120(sp)
ffffffffc0203448:	f8d2                	sd	s4,112(sp)
ffffffffc020344a:	f4d6                	sd	s5,104(sp)
ffffffffc020344c:	ecde                	sd	s7,88(sp)
ffffffffc020344e:	e8e2                	sd	s8,80(sp)
ffffffffc0203450:	e4e6                	sd	s9,72(sp)
    return listelm->next;
ffffffffc0203452:	00096417          	auipc	s0,0x96
ffffffffc0203456:	76640413          	addi	s0,s0,1894 # ffffffffc0299bb8 <free_area>
ffffffffc020345a:	d27fc0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc020345e:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0203460:	4d81                	li	s11,0
ffffffffc0203462:	4d01                	li	s10,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203464:	36878463          	beq	a5,s0,ffffffffc02037cc <swap_init+0x3f0>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203468:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020346c:	8b09                	andi	a4,a4,2
ffffffffc020346e:	36070163          	beqz	a4,ffffffffc02037d0 <swap_init+0x3f4>
        count ++, total += p->property;
ffffffffc0203472:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203476:	679c                	ld	a5,8(a5)
ffffffffc0203478:	2d05                	addiw	s10,s10,1
ffffffffc020347a:	01b70dbb          	addw	s11,a4,s11
     while ((le = list_next(le)) != &free_list) {
ffffffffc020347e:	fe8795e3          	bne	a5,s0,ffffffffc0203468 <swap_init+0x8c>
     }
     assert(total == nr_free_pages());
ffffffffc0203482:	84ee                	mv	s1,s11
ffffffffc0203484:	8edfe0ef          	jal	ffffffffc0201d70 <nr_free_pages>
ffffffffc0203488:	46951663          	bne	a0,s1,ffffffffc02038f4 <swap_init+0x518>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc020348c:	866e                	mv	a2,s11
ffffffffc020348e:	85ea                	mv	a1,s10
ffffffffc0203490:	00004517          	auipc	a0,0x4
ffffffffc0203494:	70850513          	addi	a0,a0,1800 # ffffffffc0207b98 <etext+0x13dc>
ffffffffc0203498:	ce9fc0ef          	jal	ffffffffc0200180 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc020349c:	47b000ef          	jal	ffffffffc0204116 <mm_create>
ffffffffc02034a0:	e82a                	sd	a0,16(sp)
     assert(mm != NULL);
ffffffffc02034a2:	4a050963          	beqz	a0,ffffffffc0203954 <swap_init+0x578>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc02034a6:	0009b797          	auipc	a5,0x9b
ffffffffc02034aa:	84a78793          	addi	a5,a5,-1974 # ffffffffc029dcf0 <check_mm_struct>
ffffffffc02034ae:	6398                	ld	a4,0(a5)
ffffffffc02034b0:	42071263          	bnez	a4,ffffffffc02038d4 <swap_init+0x4f8>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02034b4:	0009a717          	auipc	a4,0x9a
ffffffffc02034b8:	7fc70713          	addi	a4,a4,2044 # ffffffffc029dcb0 <boot_pgdir>
ffffffffc02034bc:	00073a83          	ld	s5,0(a4)
     check_mm_struct = mm;
ffffffffc02034c0:	6742                	ld	a4,16(sp)
ffffffffc02034c2:	e398                	sd	a4,0(a5)
     assert(pgdir[0] == 0);
ffffffffc02034c4:	000ab783          	ld	a5,0(s5) # fffffffffffff000 <end+0x3fd612e8>
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02034c8:	01573c23          	sd	s5,24(a4)
     assert(pgdir[0] == 0);
ffffffffc02034cc:	46079463          	bnez	a5,ffffffffc0203934 <swap_init+0x558>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc02034d0:	6599                	lui	a1,0x6
ffffffffc02034d2:	460d                	li	a2,3
ffffffffc02034d4:	6505                	lui	a0,0x1
ffffffffc02034d6:	489000ef          	jal	ffffffffc020415e <vma_create>
ffffffffc02034da:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc02034dc:	56050863          	beqz	a0,ffffffffc0203a4c <swap_init+0x670>

     insert_vma_struct(mm, vma);
ffffffffc02034e0:	64c2                	ld	s1,16(sp)
ffffffffc02034e2:	8526                	mv	a0,s1
ffffffffc02034e4:	4e9000ef          	jal	ffffffffc02041cc <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02034e8:	00004517          	auipc	a0,0x4
ffffffffc02034ec:	72050513          	addi	a0,a0,1824 # ffffffffc0207c08 <etext+0x144c>
ffffffffc02034f0:	c91fc0ef          	jal	ffffffffc0200180 <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02034f4:	6c88                	ld	a0,24(s1)
ffffffffc02034f6:	4605                	li	a2,1
ffffffffc02034f8:	6585                	lui	a1,0x1
ffffffffc02034fa:	8b1fe0ef          	jal	ffffffffc0201daa <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02034fe:	50050763          	beqz	a0,ffffffffc0203a0c <swap_init+0x630>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0203502:	00004517          	auipc	a0,0x4
ffffffffc0203506:	75650513          	addi	a0,a0,1878 # ffffffffc0207c58 <etext+0x149c>
ffffffffc020350a:	00096497          	auipc	s1,0x96
ffffffffc020350e:	6e648493          	addi	s1,s1,1766 # ffffffffc0299bf0 <check_rp>
ffffffffc0203512:	c6ffc0ef          	jal	ffffffffc0200180 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203516:	00096997          	auipc	s3,0x96
ffffffffc020351a:	6fa98993          	addi	s3,s3,1786 # ffffffffc0299c10 <swap_out_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc020351e:	8ba6                	mv	s7,s1
          check_rp[i] = alloc_page();
ffffffffc0203520:	4505                	li	a0,1
ffffffffc0203522:	f7efe0ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0203526:	00abb023          	sd	a0,0(s7) # fffffffffff80000 <end+0x3fce22e8>
          assert(check_rp[i] != NULL );
ffffffffc020352a:	30050163          	beqz	a0,ffffffffc020382c <swap_init+0x450>
ffffffffc020352e:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0203530:	8b89                	andi	a5,a5,2
ffffffffc0203532:	38079163          	bnez	a5,ffffffffc02038b4 <swap_init+0x4d8>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203536:	0ba1                	addi	s7,s7,8
ffffffffc0203538:	ff3b94e3          	bne	s7,s3,ffffffffc0203520 <swap_init+0x144>
     }
     list_entry_t free_list_store = free_list;
ffffffffc020353c:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc020353e:	00096b97          	auipc	s7,0x96
ffffffffc0203542:	6b2b8b93          	addi	s7,s7,1714 # ffffffffc0299bf0 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc0203546:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc0203548:	f43e                	sd	a5,40(sp)
ffffffffc020354a:	641c                	ld	a5,8(s0)
ffffffffc020354c:	e400                	sd	s0,8(s0)
ffffffffc020354e:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0203550:	481c                	lw	a5,16(s0)
ffffffffc0203552:	ec3e                	sd	a5,24(sp)
     nr_free = 0;
ffffffffc0203554:	00096797          	auipc	a5,0x96
ffffffffc0203558:	6607aa23          	sw	zero,1652(a5) # ffffffffc0299bc8 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc020355c:	000bb503          	ld	a0,0(s7)
ffffffffc0203560:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203562:	0ba1                	addi	s7,s7,8
        free_pages(check_rp[i],1);
ffffffffc0203564:	fccfe0ef          	jal	ffffffffc0201d30 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203568:	ff3b9ae3          	bne	s7,s3,ffffffffc020355c <swap_init+0x180>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc020356c:	01042b83          	lw	s7,16(s0)
ffffffffc0203570:	4791                	li	a5,4
ffffffffc0203572:	46fb9d63          	bne	s7,a5,ffffffffc02039ec <swap_init+0x610>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0203576:	00004517          	auipc	a0,0x4
ffffffffc020357a:	76a50513          	addi	a0,a0,1898 # ffffffffc0207ce0 <etext+0x1524>
ffffffffc020357e:	c03fc0ef          	jal	ffffffffc0200180 <cprintf>
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0203582:	0009a797          	auipc	a5,0x9a
ffffffffc0203586:	7607a323          	sw	zero,1894(a5) # ffffffffc029dce8 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc020358a:	6785                	lui	a5,0x1
ffffffffc020358c:	4629                	li	a2,10
ffffffffc020358e:	00c78023          	sb	a2,0(a5) # 1000 <_binary_obj___user_softint_out_size-0x7610>
     assert(pgfault_num==1);
ffffffffc0203592:	0009a697          	auipc	a3,0x9a
ffffffffc0203596:	7566a683          	lw	a3,1878(a3) # ffffffffc029dce8 <pgfault_num>
ffffffffc020359a:	4705                	li	a4,1
ffffffffc020359c:	0009a797          	auipc	a5,0x9a
ffffffffc02035a0:	74c78793          	addi	a5,a5,1868 # ffffffffc029dce8 <pgfault_num>
ffffffffc02035a4:	58e69463          	bne	a3,a4,ffffffffc0203b2c <swap_init+0x750>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc02035a8:	6705                	lui	a4,0x1
ffffffffc02035aa:	00c70823          	sb	a2,16(a4) # 1010 <_binary_obj___user_softint_out_size-0x7600>
     assert(pgfault_num==1);
ffffffffc02035ae:	4390                	lw	a2,0(a5)
ffffffffc02035b0:	40d61e63          	bne	a2,a3,ffffffffc02039cc <swap_init+0x5f0>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc02035b4:	6709                	lui	a4,0x2
ffffffffc02035b6:	46ad                	li	a3,11
ffffffffc02035b8:	00d70023          	sb	a3,0(a4) # 2000 <_binary_obj___user_softint_out_size-0x6610>
     assert(pgfault_num==2);
ffffffffc02035bc:	4398                	lw	a4,0(a5)
ffffffffc02035be:	4589                	li	a1,2
ffffffffc02035c0:	0007061b          	sext.w	a2,a4
ffffffffc02035c4:	4eb71463          	bne	a4,a1,ffffffffc0203aac <swap_init+0x6d0>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc02035c8:	6709                	lui	a4,0x2
ffffffffc02035ca:	00d70823          	sb	a3,16(a4) # 2010 <_binary_obj___user_softint_out_size-0x6600>
     assert(pgfault_num==2);
ffffffffc02035ce:	4394                	lw	a3,0(a5)
ffffffffc02035d0:	4ec69e63          	bne	a3,a2,ffffffffc0203acc <swap_init+0x6f0>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc02035d4:	670d                	lui	a4,0x3
ffffffffc02035d6:	46b1                	li	a3,12
ffffffffc02035d8:	00d70023          	sb	a3,0(a4) # 3000 <_binary_obj___user_softint_out_size-0x5610>
     assert(pgfault_num==3);
ffffffffc02035dc:	4398                	lw	a4,0(a5)
ffffffffc02035de:	458d                	li	a1,3
ffffffffc02035e0:	0007061b          	sext.w	a2,a4
ffffffffc02035e4:	50b71463          	bne	a4,a1,ffffffffc0203aec <swap_init+0x710>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc02035e8:	670d                	lui	a4,0x3
ffffffffc02035ea:	00d70823          	sb	a3,16(a4) # 3010 <_binary_obj___user_softint_out_size-0x5600>
     assert(pgfault_num==3);
ffffffffc02035ee:	4394                	lw	a3,0(a5)
ffffffffc02035f0:	50c69e63          	bne	a3,a2,ffffffffc0203b0c <swap_init+0x730>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02035f4:	6711                	lui	a4,0x4
ffffffffc02035f6:	46b5                	li	a3,13
ffffffffc02035f8:	00d70023          	sb	a3,0(a4) # 4000 <_binary_obj___user_softint_out_size-0x4610>
     assert(pgfault_num==4);
ffffffffc02035fc:	4398                	lw	a4,0(a5)
ffffffffc02035fe:	0007061b          	sext.w	a2,a4
ffffffffc0203602:	47771563          	bne	a4,s7,ffffffffc0203a6c <swap_init+0x690>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0203606:	6711                	lui	a4,0x4
ffffffffc0203608:	00d70823          	sb	a3,16(a4) # 4010 <_binary_obj___user_softint_out_size-0x4600>
     assert(pgfault_num==4);
ffffffffc020360c:	439c                	lw	a5,0(a5)
ffffffffc020360e:	46c79f63          	bne	a5,a2,ffffffffc0203a8c <swap_init+0x6b0>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0203612:	481c                	lw	a5,16(s0)
ffffffffc0203614:	30079063          	bnez	a5,ffffffffc0203914 <swap_init+0x538>
ffffffffc0203618:	00096797          	auipc	a5,0x96
ffffffffc020361c:	62078793          	addi	a5,a5,1568 # ffffffffc0299c38 <swap_in_seq_no>
ffffffffc0203620:	00096717          	auipc	a4,0x96
ffffffffc0203624:	5f070713          	addi	a4,a4,1520 # ffffffffc0299c10 <swap_out_seq_no>
ffffffffc0203628:	00096617          	auipc	a2,0x96
ffffffffc020362c:	63860613          	addi	a2,a2,1592 # ffffffffc0299c60 <pra_list_head>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0203630:	56fd                	li	a3,-1
ffffffffc0203632:	c394                	sw	a3,0(a5)
ffffffffc0203634:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0203636:	0791                	addi	a5,a5,4
ffffffffc0203638:	0711                	addi	a4,a4,4
ffffffffc020363a:	fec79ce3          	bne	a5,a2,ffffffffc0203632 <swap_init+0x256>
ffffffffc020363e:	00096717          	auipc	a4,0x96
ffffffffc0203642:	59270713          	addi	a4,a4,1426 # ffffffffc0299bd0 <check_ptep>
ffffffffc0203646:	00096a17          	auipc	s4,0x96
ffffffffc020364a:	5aaa0a13          	addi	s4,s4,1450 # ffffffffc0299bf0 <check_rp>
ffffffffc020364e:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc0203650:	0009ab97          	auipc	s7,0x9a
ffffffffc0203654:	670b8b93          	addi	s7,s7,1648 # ffffffffc029dcc0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203658:	0009ac17          	auipc	s8,0x9a
ffffffffc020365c:	670c0c13          	addi	s8,s8,1648 # ffffffffc029dcc8 <pages>
ffffffffc0203660:	00006c97          	auipc	s9,0x6
ffffffffc0203664:	850c8c93          	addi	s9,s9,-1968 # ffffffffc0208eb0 <nbase>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0203668:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020366c:	4601                	li	a2,0
ffffffffc020366e:	8556                	mv	a0,s5
ffffffffc0203670:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc0203672:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203674:	f36fe0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc0203678:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc020367a:	65a2                	ld	a1,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020367c:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc020367e:	1e050f63          	beqz	a0,ffffffffc020387c <swap_init+0x4a0>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203682:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203684:	0017f613          	andi	a2,a5,1
ffffffffc0203688:	20060a63          	beqz	a2,ffffffffc020389c <swap_init+0x4c0>
    if (PPN(pa) >= npage) {
ffffffffc020368c:	000bb603          	ld	a2,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203690:	078a                	slli	a5,a5,0x2
ffffffffc0203692:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203694:	16c7f063          	bgeu	a5,a2,ffffffffc02037f4 <swap_init+0x418>
    return &pages[PPN(pa) - nbase];
ffffffffc0203698:	000cb303          	ld	t1,0(s9)
ffffffffc020369c:	000c3603          	ld	a2,0(s8)
ffffffffc02036a0:	000a3503          	ld	a0,0(s4)
ffffffffc02036a4:	406787b3          	sub	a5,a5,t1
ffffffffc02036a8:	079a                	slli	a5,a5,0x6
ffffffffc02036aa:	6685                	lui	a3,0x1
ffffffffc02036ac:	97b2                	add	a5,a5,a2
ffffffffc02036ae:	0a21                	addi	s4,s4,8
ffffffffc02036b0:	0721                	addi	a4,a4,8
ffffffffc02036b2:	95b6                	add	a1,a1,a3
ffffffffc02036b4:	14f51c63          	bne	a0,a5,ffffffffc020380c <swap_init+0x430>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02036b8:	6795                	lui	a5,0x5
ffffffffc02036ba:	faf597e3          	bne	a1,a5,ffffffffc0203668 <swap_init+0x28c>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc02036be:	00004517          	auipc	a0,0x4
ffffffffc02036c2:	6ca50513          	addi	a0,a0,1738 # ffffffffc0207d88 <etext+0x15cc>
ffffffffc02036c6:	abbfc0ef          	jal	ffffffffc0200180 <cprintf>
    int ret = sm->check_swap();
ffffffffc02036ca:	000b3783          	ld	a5,0(s6)
ffffffffc02036ce:	7f9c                	ld	a5,56(a5)
ffffffffc02036d0:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc02036d2:	34051d63          	bnez	a0,ffffffffc0203a2c <swap_init+0x650>

     nr_free = nr_free_store;
ffffffffc02036d6:	67e2                	ld	a5,24(sp)
ffffffffc02036d8:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc02036da:	77a2                	ld	a5,40(sp)
ffffffffc02036dc:	e01c                	sd	a5,0(s0)
ffffffffc02036de:	7782                	ld	a5,32(sp)
ffffffffc02036e0:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc02036e2:	6088                	ld	a0,0(s1)
ffffffffc02036e4:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02036e6:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc02036e8:	e48fe0ef          	jal	ffffffffc0201d30 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02036ec:	ff349be3          	bne	s1,s3,ffffffffc02036e2 <swap_init+0x306>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc02036f0:	67c2                	ld	a5,16(sp)
ffffffffc02036f2:	0007bc23          	sd	zero,24(a5) # 5018 <_binary_obj___user_softint_out_size-0x35f8>
     mm_destroy(mm);
ffffffffc02036f6:	853e                	mv	a0,a5
ffffffffc02036f8:	3a5000ef          	jal	ffffffffc020429c <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02036fc:	0009a797          	auipc	a5,0x9a
ffffffffc0203700:	5b478793          	addi	a5,a5,1460 # ffffffffc029dcb0 <boot_pgdir>
ffffffffc0203704:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0203706:	000bb703          	ld	a4,0(s7)
     check_mm_struct = NULL;
ffffffffc020370a:	0009a697          	auipc	a3,0x9a
ffffffffc020370e:	5e06b323          	sd	zero,1510(a3) # ffffffffc029dcf0 <check_mm_struct>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203712:	639c                	ld	a5,0(a5)
ffffffffc0203714:	078a                	slli	a5,a5,0x2
ffffffffc0203716:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203718:	0ce7fc63          	bgeu	a5,a4,ffffffffc02037f0 <swap_init+0x414>
    return &pages[PPN(pa) - nbase];
ffffffffc020371c:	000cb483          	ld	s1,0(s9)
ffffffffc0203720:	000c3503          	ld	a0,0(s8)
ffffffffc0203724:	409786b3          	sub	a3,a5,s1
ffffffffc0203728:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc020372a:	8699                	srai	a3,a3,0x6
ffffffffc020372c:	96a6                	add	a3,a3,s1
    return KADDR(page2pa(page));
ffffffffc020372e:	00c69793          	slli	a5,a3,0xc
ffffffffc0203732:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203734:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203736:	24e7ff63          	bgeu	a5,a4,ffffffffc0203994 <swap_init+0x5b8>
     free_page(pde2page(pd0[0]));
ffffffffc020373a:	0009a797          	auipc	a5,0x9a
ffffffffc020373e:	57e7b783          	ld	a5,1406(a5) # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0203742:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0203744:	639c                	ld	a5,0(a5)
ffffffffc0203746:	078a                	slli	a5,a5,0x2
ffffffffc0203748:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020374a:	0ae7f363          	bgeu	a5,a4,ffffffffc02037f0 <swap_init+0x414>
    return &pages[PPN(pa) - nbase];
ffffffffc020374e:	8f85                	sub	a5,a5,s1
ffffffffc0203750:	079a                	slli	a5,a5,0x6
ffffffffc0203752:	953e                	add	a0,a0,a5
ffffffffc0203754:	4585                	li	a1,1
ffffffffc0203756:	ddafe0ef          	jal	ffffffffc0201d30 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020375a:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc020375e:	000bb703          	ld	a4,0(s7)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203762:	078a                	slli	a5,a5,0x2
ffffffffc0203764:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203766:	08e7f563          	bgeu	a5,a4,ffffffffc02037f0 <swap_init+0x414>
    return &pages[PPN(pa) - nbase];
ffffffffc020376a:	000c3503          	ld	a0,0(s8)
ffffffffc020376e:	8f85                	sub	a5,a5,s1
ffffffffc0203770:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0203772:	4585                	li	a1,1
ffffffffc0203774:	953e                	add	a0,a0,a5
ffffffffc0203776:	dbafe0ef          	jal	ffffffffc0201d30 <free_pages>
     pgdir[0] = 0;
ffffffffc020377a:	000ab023          	sd	zero,0(s5)
  asm volatile("sfence.vma");
ffffffffc020377e:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203782:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203784:	00878a63          	beq	a5,s0,ffffffffc0203798 <swap_init+0x3bc>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0203788:	ff87a703          	lw	a4,-8(a5)
ffffffffc020378c:	679c                	ld	a5,8(a5)
ffffffffc020378e:	3d7d                	addiw	s10,s10,-1
ffffffffc0203790:	40ed8dbb          	subw	s11,s11,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203794:	fe879ae3          	bne	a5,s0,ffffffffc0203788 <swap_init+0x3ac>
     }
     assert(count==0);
ffffffffc0203798:	200d1a63          	bnez	s10,ffffffffc02039ac <swap_init+0x5d0>
     assert(total==0);
ffffffffc020379c:	1c0d9c63          	bnez	s11,ffffffffc0203974 <swap_init+0x598>

     cprintf("check_swap() succeeded!\n");
ffffffffc02037a0:	00004517          	auipc	a0,0x4
ffffffffc02037a4:	63850513          	addi	a0,a0,1592 # ffffffffc0207dd8 <etext+0x161c>
ffffffffc02037a8:	9d9fc0ef          	jal	ffffffffc0200180 <cprintf>
}
ffffffffc02037ac:	60ea                	ld	ra,152(sp)
     cprintf("check_swap() succeeded!\n");
ffffffffc02037ae:	644a                	ld	s0,144(sp)
ffffffffc02037b0:	64aa                	ld	s1,136(sp)
ffffffffc02037b2:	79e6                	ld	s3,120(sp)
ffffffffc02037b4:	7a46                	ld	s4,112(sp)
ffffffffc02037b6:	7aa6                	ld	s5,104(sp)
ffffffffc02037b8:	6be6                	ld	s7,88(sp)
ffffffffc02037ba:	6c46                	ld	s8,80(sp)
ffffffffc02037bc:	6ca6                	ld	s9,72(sp)
ffffffffc02037be:	6d06                	ld	s10,64(sp)
ffffffffc02037c0:	7de2                	ld	s11,56(sp)
}
ffffffffc02037c2:	7b06                	ld	s6,96(sp)
ffffffffc02037c4:	854a                	mv	a0,s2
ffffffffc02037c6:	690a                	ld	s2,128(sp)
ffffffffc02037c8:	610d                	addi	sp,sp,160
ffffffffc02037ca:	8082                	ret
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037cc:	4481                	li	s1,0
ffffffffc02037ce:	b95d                	j	ffffffffc0203484 <swap_init+0xa8>
        assert(PageProperty(p));
ffffffffc02037d0:	00004697          	auipc	a3,0x4
ffffffffc02037d4:	8e868693          	addi	a3,a3,-1816 # ffffffffc02070b8 <etext+0x8fc>
ffffffffc02037d8:	00003617          	auipc	a2,0x3
ffffffffc02037dc:	66060613          	addi	a2,a2,1632 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02037e0:	0bc00593          	li	a1,188
ffffffffc02037e4:	00004517          	auipc	a0,0x4
ffffffffc02037e8:	38c50513          	addi	a0,a0,908 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc02037ec:	c89fc0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc02037f0:	bd1ff0ef          	jal	ffffffffc02033c0 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc02037f4:	00004617          	auipc	a2,0x4
ffffffffc02037f8:	d3c60613          	addi	a2,a2,-708 # ffffffffc0207530 <etext+0xd74>
ffffffffc02037fc:	06200593          	li	a1,98
ffffffffc0203800:	00004517          	auipc	a0,0x4
ffffffffc0203804:	c8850513          	addi	a0,a0,-888 # ffffffffc0207488 <etext+0xccc>
ffffffffc0203808:	c6dfc0ef          	jal	ffffffffc0200474 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc020380c:	00004697          	auipc	a3,0x4
ffffffffc0203810:	55468693          	addi	a3,a3,1364 # ffffffffc0207d60 <etext+0x15a4>
ffffffffc0203814:	00003617          	auipc	a2,0x3
ffffffffc0203818:	62460613          	addi	a2,a2,1572 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020381c:	0fc00593          	li	a1,252
ffffffffc0203820:	00004517          	auipc	a0,0x4
ffffffffc0203824:	35050513          	addi	a0,a0,848 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203828:	c4dfc0ef          	jal	ffffffffc0200474 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc020382c:	00004697          	auipc	a3,0x4
ffffffffc0203830:	45468693          	addi	a3,a3,1108 # ffffffffc0207c80 <etext+0x14c4>
ffffffffc0203834:	00003617          	auipc	a2,0x3
ffffffffc0203838:	60460613          	addi	a2,a2,1540 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020383c:	0dc00593          	li	a1,220
ffffffffc0203840:	00004517          	auipc	a0,0x4
ffffffffc0203844:	33050513          	addi	a0,a0,816 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203848:	c2dfc0ef          	jal	ffffffffc0200474 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc020384c:	00004617          	auipc	a2,0x4
ffffffffc0203850:	30460613          	addi	a2,a2,772 # ffffffffc0207b50 <etext+0x1394>
ffffffffc0203854:	02800593          	li	a1,40
ffffffffc0203858:	00004517          	auipc	a0,0x4
ffffffffc020385c:	31850513          	addi	a0,a0,792 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203860:	e922                	sd	s0,144(sp)
ffffffffc0203862:	e526                	sd	s1,136(sp)
ffffffffc0203864:	e14a                	sd	s2,128(sp)
ffffffffc0203866:	fcce                	sd	s3,120(sp)
ffffffffc0203868:	f8d2                	sd	s4,112(sp)
ffffffffc020386a:	f4d6                	sd	s5,104(sp)
ffffffffc020386c:	f0da                	sd	s6,96(sp)
ffffffffc020386e:	ecde                	sd	s7,88(sp)
ffffffffc0203870:	e8e2                	sd	s8,80(sp)
ffffffffc0203872:	e4e6                	sd	s9,72(sp)
ffffffffc0203874:	e0ea                	sd	s10,64(sp)
ffffffffc0203876:	fc6e                	sd	s11,56(sp)
ffffffffc0203878:	bfdfc0ef          	jal	ffffffffc0200474 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc020387c:	00004697          	auipc	a3,0x4
ffffffffc0203880:	4cc68693          	addi	a3,a3,1228 # ffffffffc0207d48 <etext+0x158c>
ffffffffc0203884:	00003617          	auipc	a2,0x3
ffffffffc0203888:	5b460613          	addi	a2,a2,1460 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020388c:	0fb00593          	li	a1,251
ffffffffc0203890:	00004517          	auipc	a0,0x4
ffffffffc0203894:	2e050513          	addi	a0,a0,736 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203898:	bddfc0ef          	jal	ffffffffc0200474 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020389c:	00004617          	auipc	a2,0x4
ffffffffc02038a0:	cb460613          	addi	a2,a2,-844 # ffffffffc0207550 <etext+0xd94>
ffffffffc02038a4:	07400593          	li	a1,116
ffffffffc02038a8:	00004517          	auipc	a0,0x4
ffffffffc02038ac:	be050513          	addi	a0,a0,-1056 # ffffffffc0207488 <etext+0xccc>
ffffffffc02038b0:	bc5fc0ef          	jal	ffffffffc0200474 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc02038b4:	00004697          	auipc	a3,0x4
ffffffffc02038b8:	3e468693          	addi	a3,a3,996 # ffffffffc0207c98 <etext+0x14dc>
ffffffffc02038bc:	00003617          	auipc	a2,0x3
ffffffffc02038c0:	57c60613          	addi	a2,a2,1404 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02038c4:	0dd00593          	li	a1,221
ffffffffc02038c8:	00004517          	auipc	a0,0x4
ffffffffc02038cc:	2a850513          	addi	a0,a0,680 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc02038d0:	ba5fc0ef          	jal	ffffffffc0200474 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc02038d4:	00004697          	auipc	a3,0x4
ffffffffc02038d8:	2fc68693          	addi	a3,a3,764 # ffffffffc0207bd0 <etext+0x1414>
ffffffffc02038dc:	00003617          	auipc	a2,0x3
ffffffffc02038e0:	55c60613          	addi	a2,a2,1372 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02038e4:	0c700593          	li	a1,199
ffffffffc02038e8:	00004517          	auipc	a0,0x4
ffffffffc02038ec:	28850513          	addi	a0,a0,648 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc02038f0:	b85fc0ef          	jal	ffffffffc0200474 <__panic>
     assert(total == nr_free_pages());
ffffffffc02038f4:	00003697          	auipc	a3,0x3
ffffffffc02038f8:	7ec68693          	addi	a3,a3,2028 # ffffffffc02070e0 <etext+0x924>
ffffffffc02038fc:	00003617          	auipc	a2,0x3
ffffffffc0203900:	53c60613          	addi	a2,a2,1340 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203904:	0bf00593          	li	a1,191
ffffffffc0203908:	00004517          	auipc	a0,0x4
ffffffffc020390c:	26850513          	addi	a0,a0,616 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203910:	b65fc0ef          	jal	ffffffffc0200474 <__panic>
     assert( nr_free == 0);         
ffffffffc0203914:	00004697          	auipc	a3,0x4
ffffffffc0203918:	97468693          	addi	a3,a3,-1676 # ffffffffc0207288 <etext+0xacc>
ffffffffc020391c:	00003617          	auipc	a2,0x3
ffffffffc0203920:	51c60613          	addi	a2,a2,1308 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203924:	0f300593          	li	a1,243
ffffffffc0203928:	00004517          	auipc	a0,0x4
ffffffffc020392c:	24850513          	addi	a0,a0,584 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203930:	b45fc0ef          	jal	ffffffffc0200474 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0203934:	00004697          	auipc	a3,0x4
ffffffffc0203938:	2b468693          	addi	a3,a3,692 # ffffffffc0207be8 <etext+0x142c>
ffffffffc020393c:	00003617          	auipc	a2,0x3
ffffffffc0203940:	4fc60613          	addi	a2,a2,1276 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203944:	0cc00593          	li	a1,204
ffffffffc0203948:	00004517          	auipc	a0,0x4
ffffffffc020394c:	22850513          	addi	a0,a0,552 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203950:	b25fc0ef          	jal	ffffffffc0200474 <__panic>
     assert(mm != NULL);
ffffffffc0203954:	00004697          	auipc	a3,0x4
ffffffffc0203958:	26c68693          	addi	a3,a3,620 # ffffffffc0207bc0 <etext+0x1404>
ffffffffc020395c:	00003617          	auipc	a2,0x3
ffffffffc0203960:	4dc60613          	addi	a2,a2,1244 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203964:	0c400593          	li	a1,196
ffffffffc0203968:	00004517          	auipc	a0,0x4
ffffffffc020396c:	20850513          	addi	a0,a0,520 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203970:	b05fc0ef          	jal	ffffffffc0200474 <__panic>
     assert(total==0);
ffffffffc0203974:	00004697          	auipc	a3,0x4
ffffffffc0203978:	45468693          	addi	a3,a3,1108 # ffffffffc0207dc8 <etext+0x160c>
ffffffffc020397c:	00003617          	auipc	a2,0x3
ffffffffc0203980:	4bc60613          	addi	a2,a2,1212 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203984:	11e00593          	li	a1,286
ffffffffc0203988:	00004517          	auipc	a0,0x4
ffffffffc020398c:	1e850513          	addi	a0,a0,488 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203990:	ae5fc0ef          	jal	ffffffffc0200474 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203994:	00004617          	auipc	a2,0x4
ffffffffc0203998:	acc60613          	addi	a2,a2,-1332 # ffffffffc0207460 <etext+0xca4>
ffffffffc020399c:	06900593          	li	a1,105
ffffffffc02039a0:	00004517          	auipc	a0,0x4
ffffffffc02039a4:	ae850513          	addi	a0,a0,-1304 # ffffffffc0207488 <etext+0xccc>
ffffffffc02039a8:	acdfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(count==0);
ffffffffc02039ac:	00004697          	auipc	a3,0x4
ffffffffc02039b0:	40c68693          	addi	a3,a3,1036 # ffffffffc0207db8 <etext+0x15fc>
ffffffffc02039b4:	00003617          	auipc	a2,0x3
ffffffffc02039b8:	48460613          	addi	a2,a2,1156 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02039bc:	11d00593          	li	a1,285
ffffffffc02039c0:	00004517          	auipc	a0,0x4
ffffffffc02039c4:	1b050513          	addi	a0,a0,432 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc02039c8:	aadfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(pgfault_num==1);
ffffffffc02039cc:	00004697          	auipc	a3,0x4
ffffffffc02039d0:	33c68693          	addi	a3,a3,828 # ffffffffc0207d08 <etext+0x154c>
ffffffffc02039d4:	00003617          	auipc	a2,0x3
ffffffffc02039d8:	46460613          	addi	a2,a2,1124 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02039dc:	09500593          	li	a1,149
ffffffffc02039e0:	00004517          	auipc	a0,0x4
ffffffffc02039e4:	19050513          	addi	a0,a0,400 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc02039e8:	a8dfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02039ec:	00004697          	auipc	a3,0x4
ffffffffc02039f0:	2cc68693          	addi	a3,a3,716 # ffffffffc0207cb8 <etext+0x14fc>
ffffffffc02039f4:	00003617          	auipc	a2,0x3
ffffffffc02039f8:	44460613          	addi	a2,a2,1092 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02039fc:	0ea00593          	li	a1,234
ffffffffc0203a00:	00004517          	auipc	a0,0x4
ffffffffc0203a04:	17050513          	addi	a0,a0,368 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203a08:	a6dfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203a0c:	00004697          	auipc	a3,0x4
ffffffffc0203a10:	23468693          	addi	a3,a3,564 # ffffffffc0207c40 <etext+0x1484>
ffffffffc0203a14:	00003617          	auipc	a2,0x3
ffffffffc0203a18:	42460613          	addi	a2,a2,1060 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203a1c:	0d700593          	li	a1,215
ffffffffc0203a20:	00004517          	auipc	a0,0x4
ffffffffc0203a24:	15050513          	addi	a0,a0,336 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203a28:	a4dfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(ret==0);
ffffffffc0203a2c:	00004697          	auipc	a3,0x4
ffffffffc0203a30:	38468693          	addi	a3,a3,900 # ffffffffc0207db0 <etext+0x15f4>
ffffffffc0203a34:	00003617          	auipc	a2,0x3
ffffffffc0203a38:	40460613          	addi	a2,a2,1028 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203a3c:	10200593          	li	a1,258
ffffffffc0203a40:	00004517          	auipc	a0,0x4
ffffffffc0203a44:	13050513          	addi	a0,a0,304 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203a48:	a2dfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(vma != NULL);
ffffffffc0203a4c:	00004697          	auipc	a3,0x4
ffffffffc0203a50:	1ac68693          	addi	a3,a3,428 # ffffffffc0207bf8 <etext+0x143c>
ffffffffc0203a54:	00003617          	auipc	a2,0x3
ffffffffc0203a58:	3e460613          	addi	a2,a2,996 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203a5c:	0cf00593          	li	a1,207
ffffffffc0203a60:	00004517          	auipc	a0,0x4
ffffffffc0203a64:	11050513          	addi	a0,a0,272 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203a68:	a0dfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(pgfault_num==4);
ffffffffc0203a6c:	00004697          	auipc	a3,0x4
ffffffffc0203a70:	2cc68693          	addi	a3,a3,716 # ffffffffc0207d38 <etext+0x157c>
ffffffffc0203a74:	00003617          	auipc	a2,0x3
ffffffffc0203a78:	3c460613          	addi	a2,a2,964 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203a7c:	09f00593          	li	a1,159
ffffffffc0203a80:	00004517          	auipc	a0,0x4
ffffffffc0203a84:	0f050513          	addi	a0,a0,240 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203a88:	9edfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(pgfault_num==4);
ffffffffc0203a8c:	00004697          	auipc	a3,0x4
ffffffffc0203a90:	2ac68693          	addi	a3,a3,684 # ffffffffc0207d38 <etext+0x157c>
ffffffffc0203a94:	00003617          	auipc	a2,0x3
ffffffffc0203a98:	3a460613          	addi	a2,a2,932 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203a9c:	0a100593          	li	a1,161
ffffffffc0203aa0:	00004517          	auipc	a0,0x4
ffffffffc0203aa4:	0d050513          	addi	a0,a0,208 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203aa8:	9cdfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(pgfault_num==2);
ffffffffc0203aac:	00004697          	auipc	a3,0x4
ffffffffc0203ab0:	26c68693          	addi	a3,a3,620 # ffffffffc0207d18 <etext+0x155c>
ffffffffc0203ab4:	00003617          	auipc	a2,0x3
ffffffffc0203ab8:	38460613          	addi	a2,a2,900 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203abc:	09700593          	li	a1,151
ffffffffc0203ac0:	00004517          	auipc	a0,0x4
ffffffffc0203ac4:	0b050513          	addi	a0,a0,176 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203ac8:	9adfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(pgfault_num==2);
ffffffffc0203acc:	00004697          	auipc	a3,0x4
ffffffffc0203ad0:	24c68693          	addi	a3,a3,588 # ffffffffc0207d18 <etext+0x155c>
ffffffffc0203ad4:	00003617          	auipc	a2,0x3
ffffffffc0203ad8:	36460613          	addi	a2,a2,868 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203adc:	09900593          	li	a1,153
ffffffffc0203ae0:	00004517          	auipc	a0,0x4
ffffffffc0203ae4:	09050513          	addi	a0,a0,144 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203ae8:	98dfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(pgfault_num==3);
ffffffffc0203aec:	00004697          	auipc	a3,0x4
ffffffffc0203af0:	23c68693          	addi	a3,a3,572 # ffffffffc0207d28 <etext+0x156c>
ffffffffc0203af4:	00003617          	auipc	a2,0x3
ffffffffc0203af8:	34460613          	addi	a2,a2,836 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203afc:	09b00593          	li	a1,155
ffffffffc0203b00:	00004517          	auipc	a0,0x4
ffffffffc0203b04:	07050513          	addi	a0,a0,112 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203b08:	96dfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(pgfault_num==3);
ffffffffc0203b0c:	00004697          	auipc	a3,0x4
ffffffffc0203b10:	21c68693          	addi	a3,a3,540 # ffffffffc0207d28 <etext+0x156c>
ffffffffc0203b14:	00003617          	auipc	a2,0x3
ffffffffc0203b18:	32460613          	addi	a2,a2,804 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203b1c:	09d00593          	li	a1,157
ffffffffc0203b20:	00004517          	auipc	a0,0x4
ffffffffc0203b24:	05050513          	addi	a0,a0,80 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203b28:	94dfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(pgfault_num==1);
ffffffffc0203b2c:	00004697          	auipc	a3,0x4
ffffffffc0203b30:	1dc68693          	addi	a3,a3,476 # ffffffffc0207d08 <etext+0x154c>
ffffffffc0203b34:	00003617          	auipc	a2,0x3
ffffffffc0203b38:	30460613          	addi	a2,a2,772 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203b3c:	09300593          	li	a1,147
ffffffffc0203b40:	00004517          	auipc	a0,0x4
ffffffffc0203b44:	03050513          	addi	a0,a0,48 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203b48:	92dfc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0203b4c <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203b4c:	0009a797          	auipc	a5,0x9a
ffffffffc0203b50:	1947b783          	ld	a5,404(a5) # ffffffffc029dce0 <sm>
ffffffffc0203b54:	6b9c                	ld	a5,16(a5)
ffffffffc0203b56:	8782                	jr	a5

ffffffffc0203b58 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203b58:	0009a797          	auipc	a5,0x9a
ffffffffc0203b5c:	1887b783          	ld	a5,392(a5) # ffffffffc029dce0 <sm>
ffffffffc0203b60:	739c                	ld	a5,32(a5)
ffffffffc0203b62:	8782                	jr	a5

ffffffffc0203b64 <swap_out>:
{
ffffffffc0203b64:	711d                	addi	sp,sp,-96
ffffffffc0203b66:	ec86                	sd	ra,88(sp)
ffffffffc0203b68:	e8a2                	sd	s0,80(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203b6a:	0e058663          	beqz	a1,ffffffffc0203c56 <swap_out+0xf2>
ffffffffc0203b6e:	e0ca                	sd	s2,64(sp)
ffffffffc0203b70:	fc4e                	sd	s3,56(sp)
ffffffffc0203b72:	f852                	sd	s4,48(sp)
ffffffffc0203b74:	f456                	sd	s5,40(sp)
ffffffffc0203b76:	f05a                	sd	s6,32(sp)
ffffffffc0203b78:	ec5e                	sd	s7,24(sp)
ffffffffc0203b7a:	e4a6                	sd	s1,72(sp)
ffffffffc0203b7c:	e862                	sd	s8,16(sp)
ffffffffc0203b7e:	8a2e                	mv	s4,a1
ffffffffc0203b80:	892a                	mv	s2,a0
ffffffffc0203b82:	8ab2                	mv	s5,a2
ffffffffc0203b84:	4401                	li	s0,0
ffffffffc0203b86:	0009a997          	auipc	s3,0x9a
ffffffffc0203b8a:	15a98993          	addi	s3,s3,346 # ffffffffc029dce0 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b8e:	00004b17          	auipc	s6,0x4
ffffffffc0203b92:	2cab0b13          	addi	s6,s6,714 # ffffffffc0207e58 <etext+0x169c>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203b96:	00004b97          	auipc	s7,0x4
ffffffffc0203b9a:	2aab8b93          	addi	s7,s7,682 # ffffffffc0207e40 <etext+0x1684>
ffffffffc0203b9e:	a825                	j	ffffffffc0203bd6 <swap_out+0x72>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203ba0:	67a2                	ld	a5,8(sp)
ffffffffc0203ba2:	8626                	mv	a2,s1
ffffffffc0203ba4:	85a2                	mv	a1,s0
ffffffffc0203ba6:	7f94                	ld	a3,56(a5)
ffffffffc0203ba8:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203baa:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203bac:	82b1                	srli	a3,a3,0xc
ffffffffc0203bae:	0685                	addi	a3,a3,1
ffffffffc0203bb0:	dd0fc0ef          	jal	ffffffffc0200180 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203bb4:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203bb6:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203bb8:	7d1c                	ld	a5,56(a0)
ffffffffc0203bba:	83b1                	srli	a5,a5,0xc
ffffffffc0203bbc:	0785                	addi	a5,a5,1
ffffffffc0203bbe:	07a2                	slli	a5,a5,0x8
ffffffffc0203bc0:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203bc4:	96cfe0ef          	jal	ffffffffc0201d30 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203bc8:	01893503          	ld	a0,24(s2)
ffffffffc0203bcc:	85a6                	mv	a1,s1
ffffffffc0203bce:	f32ff0ef          	jal	ffffffffc0203300 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203bd2:	048a0d63          	beq	s4,s0,ffffffffc0203c2c <swap_out+0xc8>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203bd6:	0009b783          	ld	a5,0(s3)
ffffffffc0203bda:	8656                	mv	a2,s5
ffffffffc0203bdc:	002c                	addi	a1,sp,8
ffffffffc0203bde:	7b9c                	ld	a5,48(a5)
ffffffffc0203be0:	854a                	mv	a0,s2
ffffffffc0203be2:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203be4:	e12d                	bnez	a0,ffffffffc0203c46 <swap_out+0xe2>
          v=page->pra_vaddr; 
ffffffffc0203be6:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203be8:	01893503          	ld	a0,24(s2)
ffffffffc0203bec:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203bee:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bf0:	85a6                	mv	a1,s1
ffffffffc0203bf2:	9b8fe0ef          	jal	ffffffffc0201daa <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bf6:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bf8:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bfa:	8b85                	andi	a5,a5,1
ffffffffc0203bfc:	cfb9                	beqz	a5,ffffffffc0203c5a <swap_out+0xf6>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203bfe:	65a2                	ld	a1,8(sp)
ffffffffc0203c00:	7d9c                	ld	a5,56(a1)
ffffffffc0203c02:	83b1                	srli	a5,a5,0xc
ffffffffc0203c04:	0785                	addi	a5,a5,1
ffffffffc0203c06:	00879513          	slli	a0,a5,0x8
ffffffffc0203c0a:	12a010ef          	jal	ffffffffc0204d34 <swapfs_write>
ffffffffc0203c0e:	d949                	beqz	a0,ffffffffc0203ba0 <swap_out+0x3c>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203c10:	855e                	mv	a0,s7
ffffffffc0203c12:	d6efc0ef          	jal	ffffffffc0200180 <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c16:	0009b783          	ld	a5,0(s3)
ffffffffc0203c1a:	6622                	ld	a2,8(sp)
ffffffffc0203c1c:	4681                	li	a3,0
ffffffffc0203c1e:	739c                	ld	a5,32(a5)
ffffffffc0203c20:	85a6                	mv	a1,s1
ffffffffc0203c22:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203c24:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c26:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203c28:	fa8a17e3          	bne	s4,s0,ffffffffc0203bd6 <swap_out+0x72>
ffffffffc0203c2c:	64a6                	ld	s1,72(sp)
ffffffffc0203c2e:	6906                	ld	s2,64(sp)
ffffffffc0203c30:	79e2                	ld	s3,56(sp)
ffffffffc0203c32:	7a42                	ld	s4,48(sp)
ffffffffc0203c34:	7aa2                	ld	s5,40(sp)
ffffffffc0203c36:	7b02                	ld	s6,32(sp)
ffffffffc0203c38:	6be2                	ld	s7,24(sp)
ffffffffc0203c3a:	6c42                	ld	s8,16(sp)
}
ffffffffc0203c3c:	60e6                	ld	ra,88(sp)
ffffffffc0203c3e:	8522                	mv	a0,s0
ffffffffc0203c40:	6446                	ld	s0,80(sp)
ffffffffc0203c42:	6125                	addi	sp,sp,96
ffffffffc0203c44:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203c46:	85a2                	mv	a1,s0
ffffffffc0203c48:	00004517          	auipc	a0,0x4
ffffffffc0203c4c:	1b050513          	addi	a0,a0,432 # ffffffffc0207df8 <etext+0x163c>
ffffffffc0203c50:	d30fc0ef          	jal	ffffffffc0200180 <cprintf>
                  break;
ffffffffc0203c54:	bfe1                	j	ffffffffc0203c2c <swap_out+0xc8>
     for (i = 0; i != n; ++ i)
ffffffffc0203c56:	4401                	li	s0,0
ffffffffc0203c58:	b7d5                	j	ffffffffc0203c3c <swap_out+0xd8>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c5a:	00004697          	auipc	a3,0x4
ffffffffc0203c5e:	1ce68693          	addi	a3,a3,462 # ffffffffc0207e28 <etext+0x166c>
ffffffffc0203c62:	00003617          	auipc	a2,0x3
ffffffffc0203c66:	1d660613          	addi	a2,a2,470 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203c6a:	06800593          	li	a1,104
ffffffffc0203c6e:	00004517          	auipc	a0,0x4
ffffffffc0203c72:	f0250513          	addi	a0,a0,-254 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203c76:	ffefc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0203c7a <swap_in>:
{
ffffffffc0203c7a:	7179                	addi	sp,sp,-48
ffffffffc0203c7c:	e84a                	sd	s2,16(sp)
ffffffffc0203c7e:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203c80:	4505                	li	a0,1
{
ffffffffc0203c82:	ec26                	sd	s1,24(sp)
ffffffffc0203c84:	e44e                	sd	s3,8(sp)
ffffffffc0203c86:	f406                	sd	ra,40(sp)
ffffffffc0203c88:	f022                	sd	s0,32(sp)
ffffffffc0203c8a:	84ae                	mv	s1,a1
ffffffffc0203c8c:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203c8e:	812fe0ef          	jal	ffffffffc0201ca0 <alloc_pages>
     assert(result!=NULL);
ffffffffc0203c92:	c129                	beqz	a0,ffffffffc0203cd4 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203c94:	842a                	mv	s0,a0
ffffffffc0203c96:	01893503          	ld	a0,24(s2)
ffffffffc0203c9a:	4601                	li	a2,0
ffffffffc0203c9c:	85a6                	mv	a1,s1
ffffffffc0203c9e:	90cfe0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc0203ca2:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203ca4:	6108                	ld	a0,0(a0)
ffffffffc0203ca6:	85a2                	mv	a1,s0
ffffffffc0203ca8:	7ff000ef          	jal	ffffffffc0204ca6 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203cac:	00093583          	ld	a1,0(s2)
ffffffffc0203cb0:	8626                	mv	a2,s1
ffffffffc0203cb2:	00004517          	auipc	a0,0x4
ffffffffc0203cb6:	1f650513          	addi	a0,a0,502 # ffffffffc0207ea8 <etext+0x16ec>
ffffffffc0203cba:	81a1                	srli	a1,a1,0x8
ffffffffc0203cbc:	cc4fc0ef          	jal	ffffffffc0200180 <cprintf>
}
ffffffffc0203cc0:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203cc2:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203cc6:	7402                	ld	s0,32(sp)
ffffffffc0203cc8:	64e2                	ld	s1,24(sp)
ffffffffc0203cca:	6942                	ld	s2,16(sp)
ffffffffc0203ccc:	69a2                	ld	s3,8(sp)
ffffffffc0203cce:	4501                	li	a0,0
ffffffffc0203cd0:	6145                	addi	sp,sp,48
ffffffffc0203cd2:	8082                	ret
     assert(result!=NULL);
ffffffffc0203cd4:	00004697          	auipc	a3,0x4
ffffffffc0203cd8:	1c468693          	addi	a3,a3,452 # ffffffffc0207e98 <etext+0x16dc>
ffffffffc0203cdc:	00003617          	auipc	a2,0x3
ffffffffc0203ce0:	15c60613          	addi	a2,a2,348 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203ce4:	07e00593          	li	a1,126
ffffffffc0203ce8:	00004517          	auipc	a0,0x4
ffffffffc0203cec:	e8850513          	addi	a0,a0,-376 # ffffffffc0207b70 <etext+0x13b4>
ffffffffc0203cf0:	f84fc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0203cf4 <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203cf4:	00096797          	auipc	a5,0x96
ffffffffc0203cf8:	f6c78793          	addi	a5,a5,-148 # ffffffffc0299c60 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0203cfc:	f51c                	sd	a5,40(a0)
ffffffffc0203cfe:	e79c                	sd	a5,8(a5)
ffffffffc0203d00:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0203d02:	4501                	li	a0,0
ffffffffc0203d04:	8082                	ret

ffffffffc0203d06 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203d06:	4501                	li	a0,0
ffffffffc0203d08:	8082                	ret

ffffffffc0203d0a <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203d0a:	4501                	li	a0,0
ffffffffc0203d0c:	8082                	ret

ffffffffc0203d0e <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203d0e:	4501                	li	a0,0
ffffffffc0203d10:	8082                	ret

ffffffffc0203d12 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203d12:	711d                	addi	sp,sp,-96
ffffffffc0203d14:	fc4e                	sd	s3,56(sp)
ffffffffc0203d16:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d18:	00004517          	auipc	a0,0x4
ffffffffc0203d1c:	1d050513          	addi	a0,a0,464 # ffffffffc0207ee8 <etext+0x172c>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d20:	698d                	lui	s3,0x3
ffffffffc0203d22:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0203d24:	e4a6                	sd	s1,72(sp)
ffffffffc0203d26:	ec86                	sd	ra,88(sp)
ffffffffc0203d28:	e8a2                	sd	s0,80(sp)
ffffffffc0203d2a:	e0ca                	sd	s2,64(sp)
ffffffffc0203d2c:	f456                	sd	s5,40(sp)
ffffffffc0203d2e:	f05a                	sd	s6,32(sp)
ffffffffc0203d30:	ec5e                	sd	s7,24(sp)
ffffffffc0203d32:	e862                	sd	s8,16(sp)
ffffffffc0203d34:	e466                	sd	s9,8(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d36:	c4afc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d3a:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_softint_out_size-0x5610>
    assert(pgfault_num==4);
ffffffffc0203d3e:	0009a497          	auipc	s1,0x9a
ffffffffc0203d42:	faa4a483          	lw	s1,-86(s1) # ffffffffc029dce8 <pgfault_num>
ffffffffc0203d46:	4791                	li	a5,4
ffffffffc0203d48:	14f49963          	bne	s1,a5,ffffffffc0203e9a <_fifo_check_swap+0x188>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d4c:	00004517          	auipc	a0,0x4
ffffffffc0203d50:	1dc50513          	addi	a0,a0,476 # ffffffffc0207f28 <etext+0x176c>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d54:	6a85                	lui	s5,0x1
ffffffffc0203d56:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d58:	c28fc0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc0203d5c:	0009a417          	auipc	s0,0x9a
ffffffffc0203d60:	f8c40413          	addi	s0,s0,-116 # ffffffffc029dce8 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d64:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_softint_out_size-0x7610>
    assert(pgfault_num==4);
ffffffffc0203d68:	401c                	lw	a5,0(s0)
ffffffffc0203d6a:	0007891b          	sext.w	s2,a5
ffffffffc0203d6e:	2a979663          	bne	a5,s1,ffffffffc020401a <_fifo_check_swap+0x308>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d72:	00004517          	auipc	a0,0x4
ffffffffc0203d76:	1de50513          	addi	a0,a0,478 # ffffffffc0207f50 <etext+0x1794>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d7a:	6b91                	lui	s7,0x4
ffffffffc0203d7c:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d7e:	c02fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d82:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_softint_out_size-0x4610>
    assert(pgfault_num==4);
ffffffffc0203d86:	401c                	lw	a5,0(s0)
ffffffffc0203d88:	00078c9b          	sext.w	s9,a5
ffffffffc0203d8c:	27279763          	bne	a5,s2,ffffffffc0203ffa <_fifo_check_swap+0x2e8>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d90:	00004517          	auipc	a0,0x4
ffffffffc0203d94:	1e850513          	addi	a0,a0,488 # ffffffffc0207f78 <etext+0x17bc>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d98:	6489                	lui	s1,0x2
ffffffffc0203d9a:	492d                	li	s2,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d9c:	be4fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203da0:	01248023          	sb	s2,0(s1) # 2000 <_binary_obj___user_softint_out_size-0x6610>
    assert(pgfault_num==4);
ffffffffc0203da4:	401c                	lw	a5,0(s0)
ffffffffc0203da6:	23979a63          	bne	a5,s9,ffffffffc0203fda <_fifo_check_swap+0x2c8>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203daa:	00004517          	auipc	a0,0x4
ffffffffc0203dae:	1f650513          	addi	a0,a0,502 # ffffffffc0207fa0 <etext+0x17e4>
ffffffffc0203db2:	bcefc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203db6:	6795                	lui	a5,0x5
ffffffffc0203db8:	4739                	li	a4,14
ffffffffc0203dba:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_softint_out_size-0x3610>
    assert(pgfault_num==5);
ffffffffc0203dbe:	401c                	lw	a5,0(s0)
ffffffffc0203dc0:	4715                	li	a4,5
ffffffffc0203dc2:	00078c9b          	sext.w	s9,a5
ffffffffc0203dc6:	1ee79a63          	bne	a5,a4,ffffffffc0203fba <_fifo_check_swap+0x2a8>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203dca:	00004517          	auipc	a0,0x4
ffffffffc0203dce:	1ae50513          	addi	a0,a0,430 # ffffffffc0207f78 <etext+0x17bc>
ffffffffc0203dd2:	baefc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203dd6:	01248023          	sb	s2,0(s1)
    assert(pgfault_num==5);
ffffffffc0203dda:	401c                	lw	a5,0(s0)
ffffffffc0203ddc:	1b979f63          	bne	a5,s9,ffffffffc0203f9a <_fifo_check_swap+0x288>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203de0:	00004517          	auipc	a0,0x4
ffffffffc0203de4:	14850513          	addi	a0,a0,328 # ffffffffc0207f28 <etext+0x176c>
ffffffffc0203de8:	b98fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203dec:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0203df0:	4018                	lw	a4,0(s0)
ffffffffc0203df2:	4799                	li	a5,6
ffffffffc0203df4:	18f71363          	bne	a4,a5,ffffffffc0203f7a <_fifo_check_swap+0x268>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203df8:	00004517          	auipc	a0,0x4
ffffffffc0203dfc:	18050513          	addi	a0,a0,384 # ffffffffc0207f78 <etext+0x17bc>
ffffffffc0203e00:	b80fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203e04:	01248023          	sb	s2,0(s1)
    assert(pgfault_num==7);
ffffffffc0203e08:	4018                	lw	a4,0(s0)
ffffffffc0203e0a:	479d                	li	a5,7
ffffffffc0203e0c:	14f71763          	bne	a4,a5,ffffffffc0203f5a <_fifo_check_swap+0x248>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203e10:	00004517          	auipc	a0,0x4
ffffffffc0203e14:	0d850513          	addi	a0,a0,216 # ffffffffc0207ee8 <etext+0x172c>
ffffffffc0203e18:	b68fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203e1c:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0203e20:	4018                	lw	a4,0(s0)
ffffffffc0203e22:	47a1                	li	a5,8
ffffffffc0203e24:	10f71b63          	bne	a4,a5,ffffffffc0203f3a <_fifo_check_swap+0x228>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203e28:	00004517          	auipc	a0,0x4
ffffffffc0203e2c:	12850513          	addi	a0,a0,296 # ffffffffc0207f50 <etext+0x1794>
ffffffffc0203e30:	b50fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203e34:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0203e38:	4018                	lw	a4,0(s0)
ffffffffc0203e3a:	47a5                	li	a5,9
ffffffffc0203e3c:	0cf71f63          	bne	a4,a5,ffffffffc0203f1a <_fifo_check_swap+0x208>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203e40:	00004517          	auipc	a0,0x4
ffffffffc0203e44:	16050513          	addi	a0,a0,352 # ffffffffc0207fa0 <etext+0x17e4>
ffffffffc0203e48:	b38fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203e4c:	6795                	lui	a5,0x5
ffffffffc0203e4e:	4739                	li	a4,14
ffffffffc0203e50:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_softint_out_size-0x3610>
    assert(pgfault_num==10);
ffffffffc0203e54:	401c                	lw	a5,0(s0)
ffffffffc0203e56:	4729                	li	a4,10
ffffffffc0203e58:	0007849b          	sext.w	s1,a5
ffffffffc0203e5c:	08e79f63          	bne	a5,a4,ffffffffc0203efa <_fifo_check_swap+0x1e8>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203e60:	00004517          	auipc	a0,0x4
ffffffffc0203e64:	0c850513          	addi	a0,a0,200 # ffffffffc0207f28 <etext+0x176c>
ffffffffc0203e68:	b18fc0ef          	jal	ffffffffc0200180 <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203e6c:	6785                	lui	a5,0x1
ffffffffc0203e6e:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_softint_out_size-0x7610>
ffffffffc0203e72:	06979463          	bne	a5,s1,ffffffffc0203eda <_fifo_check_swap+0x1c8>
    assert(pgfault_num==11);
ffffffffc0203e76:	4018                	lw	a4,0(s0)
ffffffffc0203e78:	47ad                	li	a5,11
ffffffffc0203e7a:	04f71063          	bne	a4,a5,ffffffffc0203eba <_fifo_check_swap+0x1a8>
}
ffffffffc0203e7e:	60e6                	ld	ra,88(sp)
ffffffffc0203e80:	6446                	ld	s0,80(sp)
ffffffffc0203e82:	64a6                	ld	s1,72(sp)
ffffffffc0203e84:	6906                	ld	s2,64(sp)
ffffffffc0203e86:	79e2                	ld	s3,56(sp)
ffffffffc0203e88:	7a42                	ld	s4,48(sp)
ffffffffc0203e8a:	7aa2                	ld	s5,40(sp)
ffffffffc0203e8c:	7b02                	ld	s6,32(sp)
ffffffffc0203e8e:	6be2                	ld	s7,24(sp)
ffffffffc0203e90:	6c42                	ld	s8,16(sp)
ffffffffc0203e92:	6ca2                	ld	s9,8(sp)
ffffffffc0203e94:	4501                	li	a0,0
ffffffffc0203e96:	6125                	addi	sp,sp,96
ffffffffc0203e98:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0203e9a:	00004697          	auipc	a3,0x4
ffffffffc0203e9e:	e9e68693          	addi	a3,a3,-354 # ffffffffc0207d38 <etext+0x157c>
ffffffffc0203ea2:	00003617          	auipc	a2,0x3
ffffffffc0203ea6:	f9660613          	addi	a2,a2,-106 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203eaa:	05100593          	li	a1,81
ffffffffc0203eae:	00004517          	auipc	a0,0x4
ffffffffc0203eb2:	06250513          	addi	a0,a0,98 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203eb6:	dbefc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==11);
ffffffffc0203eba:	00004697          	auipc	a3,0x4
ffffffffc0203ebe:	19668693          	addi	a3,a3,406 # ffffffffc0208050 <etext+0x1894>
ffffffffc0203ec2:	00003617          	auipc	a2,0x3
ffffffffc0203ec6:	f7660613          	addi	a2,a2,-138 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203eca:	07300593          	li	a1,115
ffffffffc0203ece:	00004517          	auipc	a0,0x4
ffffffffc0203ed2:	04250513          	addi	a0,a0,66 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203ed6:	d9efc0ef          	jal	ffffffffc0200474 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203eda:	00004697          	auipc	a3,0x4
ffffffffc0203ede:	14e68693          	addi	a3,a3,334 # ffffffffc0208028 <etext+0x186c>
ffffffffc0203ee2:	00003617          	auipc	a2,0x3
ffffffffc0203ee6:	f5660613          	addi	a2,a2,-170 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203eea:	07100593          	li	a1,113
ffffffffc0203eee:	00004517          	auipc	a0,0x4
ffffffffc0203ef2:	02250513          	addi	a0,a0,34 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203ef6:	d7efc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==10);
ffffffffc0203efa:	00004697          	auipc	a3,0x4
ffffffffc0203efe:	11e68693          	addi	a3,a3,286 # ffffffffc0208018 <etext+0x185c>
ffffffffc0203f02:	00003617          	auipc	a2,0x3
ffffffffc0203f06:	f3660613          	addi	a2,a2,-202 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203f0a:	06f00593          	li	a1,111
ffffffffc0203f0e:	00004517          	auipc	a0,0x4
ffffffffc0203f12:	00250513          	addi	a0,a0,2 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203f16:	d5efc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==9);
ffffffffc0203f1a:	00004697          	auipc	a3,0x4
ffffffffc0203f1e:	0ee68693          	addi	a3,a3,238 # ffffffffc0208008 <etext+0x184c>
ffffffffc0203f22:	00003617          	auipc	a2,0x3
ffffffffc0203f26:	f1660613          	addi	a2,a2,-234 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203f2a:	06c00593          	li	a1,108
ffffffffc0203f2e:	00004517          	auipc	a0,0x4
ffffffffc0203f32:	fe250513          	addi	a0,a0,-30 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203f36:	d3efc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==8);
ffffffffc0203f3a:	00004697          	auipc	a3,0x4
ffffffffc0203f3e:	0be68693          	addi	a3,a3,190 # ffffffffc0207ff8 <etext+0x183c>
ffffffffc0203f42:	00003617          	auipc	a2,0x3
ffffffffc0203f46:	ef660613          	addi	a2,a2,-266 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203f4a:	06900593          	li	a1,105
ffffffffc0203f4e:	00004517          	auipc	a0,0x4
ffffffffc0203f52:	fc250513          	addi	a0,a0,-62 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203f56:	d1efc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==7);
ffffffffc0203f5a:	00004697          	auipc	a3,0x4
ffffffffc0203f5e:	08e68693          	addi	a3,a3,142 # ffffffffc0207fe8 <etext+0x182c>
ffffffffc0203f62:	00003617          	auipc	a2,0x3
ffffffffc0203f66:	ed660613          	addi	a2,a2,-298 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203f6a:	06600593          	li	a1,102
ffffffffc0203f6e:	00004517          	auipc	a0,0x4
ffffffffc0203f72:	fa250513          	addi	a0,a0,-94 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203f76:	cfefc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==6);
ffffffffc0203f7a:	00004697          	auipc	a3,0x4
ffffffffc0203f7e:	05e68693          	addi	a3,a3,94 # ffffffffc0207fd8 <etext+0x181c>
ffffffffc0203f82:	00003617          	auipc	a2,0x3
ffffffffc0203f86:	eb660613          	addi	a2,a2,-330 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203f8a:	06300593          	li	a1,99
ffffffffc0203f8e:	00004517          	auipc	a0,0x4
ffffffffc0203f92:	f8250513          	addi	a0,a0,-126 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203f96:	cdefc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==5);
ffffffffc0203f9a:	00004697          	auipc	a3,0x4
ffffffffc0203f9e:	02e68693          	addi	a3,a3,46 # ffffffffc0207fc8 <etext+0x180c>
ffffffffc0203fa2:	00003617          	auipc	a2,0x3
ffffffffc0203fa6:	e9660613          	addi	a2,a2,-362 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203faa:	06000593          	li	a1,96
ffffffffc0203fae:	00004517          	auipc	a0,0x4
ffffffffc0203fb2:	f6250513          	addi	a0,a0,-158 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203fb6:	cbefc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==5);
ffffffffc0203fba:	00004697          	auipc	a3,0x4
ffffffffc0203fbe:	00e68693          	addi	a3,a3,14 # ffffffffc0207fc8 <etext+0x180c>
ffffffffc0203fc2:	00003617          	auipc	a2,0x3
ffffffffc0203fc6:	e7660613          	addi	a2,a2,-394 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203fca:	05d00593          	li	a1,93
ffffffffc0203fce:	00004517          	auipc	a0,0x4
ffffffffc0203fd2:	f4250513          	addi	a0,a0,-190 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203fd6:	c9efc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==4);
ffffffffc0203fda:	00004697          	auipc	a3,0x4
ffffffffc0203fde:	d5e68693          	addi	a3,a3,-674 # ffffffffc0207d38 <etext+0x157c>
ffffffffc0203fe2:	00003617          	auipc	a2,0x3
ffffffffc0203fe6:	e5660613          	addi	a2,a2,-426 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0203fea:	05a00593          	li	a1,90
ffffffffc0203fee:	00004517          	auipc	a0,0x4
ffffffffc0203ff2:	f2250513          	addi	a0,a0,-222 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0203ff6:	c7efc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==4);
ffffffffc0203ffa:	00004697          	auipc	a3,0x4
ffffffffc0203ffe:	d3e68693          	addi	a3,a3,-706 # ffffffffc0207d38 <etext+0x157c>
ffffffffc0204002:	00003617          	auipc	a2,0x3
ffffffffc0204006:	e3660613          	addi	a2,a2,-458 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020400a:	05700593          	li	a1,87
ffffffffc020400e:	00004517          	auipc	a0,0x4
ffffffffc0204012:	f0250513          	addi	a0,a0,-254 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0204016:	c5efc0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgfault_num==4);
ffffffffc020401a:	00004697          	auipc	a3,0x4
ffffffffc020401e:	d1e68693          	addi	a3,a3,-738 # ffffffffc0207d38 <etext+0x157c>
ffffffffc0204022:	00003617          	auipc	a2,0x3
ffffffffc0204026:	e1660613          	addi	a2,a2,-490 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020402a:	05400593          	li	a1,84
ffffffffc020402e:	00004517          	auipc	a0,0x4
ffffffffc0204032:	ee250513          	addi	a0,a0,-286 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0204036:	c3efc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc020403a <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020403a:	751c                	ld	a5,40(a0)
{
ffffffffc020403c:	1141                	addi	sp,sp,-16
ffffffffc020403e:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc0204040:	cf91                	beqz	a5,ffffffffc020405c <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc0204042:	ee0d                	bnez	a2,ffffffffc020407c <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc0204044:	679c                	ld	a5,8(a5)
}
ffffffffc0204046:	60a2                	ld	ra,8(sp)
ffffffffc0204048:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc020404a:	6394                	ld	a3,0(a5)
ffffffffc020404c:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc020404e:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc0204052:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204054:	e314                	sd	a3,0(a4)
ffffffffc0204056:	e19c                	sd	a5,0(a1)
}
ffffffffc0204058:	0141                	addi	sp,sp,16
ffffffffc020405a:	8082                	ret
         assert(head != NULL);
ffffffffc020405c:	00004697          	auipc	a3,0x4
ffffffffc0204060:	00468693          	addi	a3,a3,4 # ffffffffc0208060 <etext+0x18a4>
ffffffffc0204064:	00003617          	auipc	a2,0x3
ffffffffc0204068:	dd460613          	addi	a2,a2,-556 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020406c:	04100593          	li	a1,65
ffffffffc0204070:	00004517          	auipc	a0,0x4
ffffffffc0204074:	ea050513          	addi	a0,a0,-352 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0204078:	bfcfc0ef          	jal	ffffffffc0200474 <__panic>
     assert(in_tick==0);
ffffffffc020407c:	00004697          	auipc	a3,0x4
ffffffffc0204080:	ff468693          	addi	a3,a3,-12 # ffffffffc0208070 <etext+0x18b4>
ffffffffc0204084:	00003617          	auipc	a2,0x3
ffffffffc0204088:	db460613          	addi	a2,a2,-588 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020408c:	04200593          	li	a1,66
ffffffffc0204090:	00004517          	auipc	a0,0x4
ffffffffc0204094:	e8050513          	addi	a0,a0,-384 # ffffffffc0207f10 <etext+0x1754>
ffffffffc0204098:	bdcfc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc020409c <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020409c:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc020409e:	cb91                	beqz	a5,ffffffffc02040b2 <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02040a0:	6394                	ld	a3,0(a5)
ffffffffc02040a2:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc02040a6:	e398                	sd	a4,0(a5)
ffffffffc02040a8:	e698                	sd	a4,8(a3)
}
ffffffffc02040aa:	4501                	li	a0,0
    elm->next = next;
ffffffffc02040ac:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc02040ae:	f614                	sd	a3,40(a2)
ffffffffc02040b0:	8082                	ret
{
ffffffffc02040b2:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc02040b4:	00004697          	auipc	a3,0x4
ffffffffc02040b8:	fcc68693          	addi	a3,a3,-52 # ffffffffc0208080 <etext+0x18c4>
ffffffffc02040bc:	00003617          	auipc	a2,0x3
ffffffffc02040c0:	d7c60613          	addi	a2,a2,-644 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02040c4:	03200593          	li	a1,50
ffffffffc02040c8:	00004517          	auipc	a0,0x4
ffffffffc02040cc:	e4850513          	addi	a0,a0,-440 # ffffffffc0207f10 <etext+0x1754>
{
ffffffffc02040d0:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc02040d2:	ba2fc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02040d6 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02040d6:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02040d8:	00004697          	auipc	a3,0x4
ffffffffc02040dc:	fe068693          	addi	a3,a3,-32 # ffffffffc02080b8 <etext+0x18fc>
ffffffffc02040e0:	00003617          	auipc	a2,0x3
ffffffffc02040e4:	d5860613          	addi	a2,a2,-680 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02040e8:	06e00593          	li	a1,110
ffffffffc02040ec:	00004517          	auipc	a0,0x4
ffffffffc02040f0:	fec50513          	addi	a0,a0,-20 # ffffffffc02080d8 <etext+0x191c>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02040f4:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02040f6:	b7efc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02040fa <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc02040fa:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02040fc:	00003617          	auipc	a2,0x3
ffffffffc0204100:	43460613          	addi	a2,a2,1076 # ffffffffc0207530 <etext+0xd74>
ffffffffc0204104:	06200593          	li	a1,98
ffffffffc0204108:	00003517          	auipc	a0,0x3
ffffffffc020410c:	38050513          	addi	a0,a0,896 # ffffffffc0207488 <etext+0xccc>
pa2page(uintptr_t pa) {
ffffffffc0204110:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0204112:	b62fc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0204116 <mm_create>:
mm_create(void) {
ffffffffc0204116:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0204118:	04000513          	li	a0,64
mm_create(void) {
ffffffffc020411c:	e022                	sd	s0,0(sp)
ffffffffc020411e:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0204120:	9a9fd0ef          	jal	ffffffffc0201ac8 <kmalloc>
ffffffffc0204124:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0204126:	c505                	beqz	a0,ffffffffc020414e <mm_create+0x38>
    elm->prev = elm->next = elm;
ffffffffc0204128:	e408                	sd	a0,8(s0)
ffffffffc020412a:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc020412c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0204130:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0204134:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0204138:	0009a797          	auipc	a5,0x9a
ffffffffc020413c:	b987a783          	lw	a5,-1128(a5) # ffffffffc029dcd0 <swap_init_ok>
ffffffffc0204140:	ef81                	bnez	a5,ffffffffc0204158 <mm_create+0x42>
        else mm->sm_priv = NULL;
ffffffffc0204142:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc0204146:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc020414a:	02043c23          	sd	zero,56(s0)
}
ffffffffc020414e:	60a2                	ld	ra,8(sp)
ffffffffc0204150:	8522                	mv	a0,s0
ffffffffc0204152:	6402                	ld	s0,0(sp)
ffffffffc0204154:	0141                	addi	sp,sp,16
ffffffffc0204156:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0204158:	9f5ff0ef          	jal	ffffffffc0203b4c <swap_init_mm>
ffffffffc020415c:	b7ed                	j	ffffffffc0204146 <mm_create+0x30>

ffffffffc020415e <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc020415e:	1101                	addi	sp,sp,-32
ffffffffc0204160:	e04a                	sd	s2,0(sp)
ffffffffc0204162:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204164:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0204168:	e822                	sd	s0,16(sp)
ffffffffc020416a:	e426                	sd	s1,8(sp)
ffffffffc020416c:	ec06                	sd	ra,24(sp)
ffffffffc020416e:	84ae                	mv	s1,a1
ffffffffc0204170:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204172:	957fd0ef          	jal	ffffffffc0201ac8 <kmalloc>
    if (vma != NULL) {
ffffffffc0204176:	c509                	beqz	a0,ffffffffc0204180 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0204178:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc020417c:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020417e:	cd00                	sw	s0,24(a0)
}
ffffffffc0204180:	60e2                	ld	ra,24(sp)
ffffffffc0204182:	6442                	ld	s0,16(sp)
ffffffffc0204184:	64a2                	ld	s1,8(sp)
ffffffffc0204186:	6902                	ld	s2,0(sp)
ffffffffc0204188:	6105                	addi	sp,sp,32
ffffffffc020418a:	8082                	ret

ffffffffc020418c <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc020418c:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc020418e:	c505                	beqz	a0,ffffffffc02041b6 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0204190:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0204192:	c501                	beqz	a0,ffffffffc020419a <find_vma+0xe>
ffffffffc0204194:	651c                	ld	a5,8(a0)
ffffffffc0204196:	02f5f663          	bgeu	a1,a5,ffffffffc02041c2 <find_vma+0x36>
    return listelm->next;
ffffffffc020419a:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc020419c:	00f68d63          	beq	a3,a5,ffffffffc02041b6 <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc02041a0:	fe87b703          	ld	a4,-24(a5)
ffffffffc02041a4:	00e5e663          	bltu	a1,a4,ffffffffc02041b0 <find_vma+0x24>
ffffffffc02041a8:	ff07b703          	ld	a4,-16(a5)
ffffffffc02041ac:	00e5e763          	bltu	a1,a4,ffffffffc02041ba <find_vma+0x2e>
ffffffffc02041b0:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc02041b2:	fef697e3          	bne	a3,a5,ffffffffc02041a0 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02041b6:	4501                	li	a0,0
}
ffffffffc02041b8:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc02041ba:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02041be:	ea88                	sd	a0,16(a3)
ffffffffc02041c0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02041c2:	691c                	ld	a5,16(a0)
ffffffffc02041c4:	fcf5fbe3          	bgeu	a1,a5,ffffffffc020419a <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02041c8:	ea88                	sd	a0,16(a3)
ffffffffc02041ca:	8082                	ret

ffffffffc02041cc <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc02041cc:	6590                	ld	a2,8(a1)
ffffffffc02041ce:	0105b803          	ld	a6,16(a1) # 1010 <_binary_obj___user_softint_out_size-0x7600>
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc02041d2:	1141                	addi	sp,sp,-16
ffffffffc02041d4:	e406                	sd	ra,8(sp)
ffffffffc02041d6:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02041d8:	01066763          	bltu	a2,a6,ffffffffc02041e6 <insert_vma_struct+0x1a>
ffffffffc02041dc:	a085                	j	ffffffffc020423c <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc02041de:	fe87b703          	ld	a4,-24(a5)
ffffffffc02041e2:	04e66863          	bltu	a2,a4,ffffffffc0204232 <insert_vma_struct+0x66>
ffffffffc02041e6:	86be                	mv	a3,a5
ffffffffc02041e8:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc02041ea:	fef51ae3          	bne	a0,a5,ffffffffc02041de <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc02041ee:	02a68463          	beq	a3,a0,ffffffffc0204216 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02041f2:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02041f6:	fe86b883          	ld	a7,-24(a3)
ffffffffc02041fa:	08e8f163          	bgeu	a7,a4,ffffffffc020427c <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02041fe:	04e66f63          	bltu	a2,a4,ffffffffc020425c <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc0204202:	00f50a63          	beq	a0,a5,ffffffffc0204216 <insert_vma_struct+0x4a>
ffffffffc0204206:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020420a:	05076963          	bltu	a4,a6,ffffffffc020425c <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020420e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0204212:	02c77363          	bgeu	a4,a2,ffffffffc0204238 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc0204216:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0204218:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020421a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020421e:	e390                	sd	a2,0(a5)
ffffffffc0204220:	e690                	sd	a2,8(a3)
}
ffffffffc0204222:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0204224:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0204226:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0204228:	0017079b          	addiw	a5,a4,1
ffffffffc020422c:	d11c                	sw	a5,32(a0)
}
ffffffffc020422e:	0141                	addi	sp,sp,16
ffffffffc0204230:	8082                	ret
    if (le_prev != list) {
ffffffffc0204232:	fca690e3          	bne	a3,a0,ffffffffc02041f2 <insert_vma_struct+0x26>
ffffffffc0204236:	bfd1                	j	ffffffffc020420a <insert_vma_struct+0x3e>
ffffffffc0204238:	e9fff0ef          	jal	ffffffffc02040d6 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020423c:	00004697          	auipc	a3,0x4
ffffffffc0204240:	eac68693          	addi	a3,a3,-340 # ffffffffc02080e8 <etext+0x192c>
ffffffffc0204244:	00003617          	auipc	a2,0x3
ffffffffc0204248:	bf460613          	addi	a2,a2,-1036 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020424c:	07500593          	li	a1,117
ffffffffc0204250:	00004517          	auipc	a0,0x4
ffffffffc0204254:	e8850513          	addi	a0,a0,-376 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204258:	a1cfc0ef          	jal	ffffffffc0200474 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020425c:	00004697          	auipc	a3,0x4
ffffffffc0204260:	ecc68693          	addi	a3,a3,-308 # ffffffffc0208128 <etext+0x196c>
ffffffffc0204264:	00003617          	auipc	a2,0x3
ffffffffc0204268:	bd460613          	addi	a2,a2,-1068 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020426c:	06d00593          	li	a1,109
ffffffffc0204270:	00004517          	auipc	a0,0x4
ffffffffc0204274:	e6850513          	addi	a0,a0,-408 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204278:	9fcfc0ef          	jal	ffffffffc0200474 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020427c:	00004697          	auipc	a3,0x4
ffffffffc0204280:	e8c68693          	addi	a3,a3,-372 # ffffffffc0208108 <etext+0x194c>
ffffffffc0204284:	00003617          	auipc	a2,0x3
ffffffffc0204288:	bb460613          	addi	a2,a2,-1100 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020428c:	06c00593          	li	a1,108
ffffffffc0204290:	00004517          	auipc	a0,0x4
ffffffffc0204294:	e4850513          	addi	a0,a0,-440 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204298:	9dcfc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc020429c <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc020429c:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc020429e:	1141                	addi	sp,sp,-16
ffffffffc02042a0:	e406                	sd	ra,8(sp)
ffffffffc02042a2:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02042a4:	e78d                	bnez	a5,ffffffffc02042ce <mm_destroy+0x32>
ffffffffc02042a6:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02042a8:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc02042aa:	00a40c63          	beq	s0,a0,ffffffffc02042c2 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02042ae:	6118                	ld	a4,0(a0)
ffffffffc02042b0:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc02042b2:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02042b4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02042b6:	e398                	sd	a4,0(a5)
ffffffffc02042b8:	8bbfd0ef          	jal	ffffffffc0201b72 <kfree>
    return listelm->next;
ffffffffc02042bc:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02042be:	fea418e3          	bne	s0,a0,ffffffffc02042ae <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc02042c2:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc02042c4:	6402                	ld	s0,0(sp)
ffffffffc02042c6:	60a2                	ld	ra,8(sp)
ffffffffc02042c8:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc02042ca:	8a9fd06f          	j	ffffffffc0201b72 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02042ce:	00004697          	auipc	a3,0x4
ffffffffc02042d2:	e7a68693          	addi	a3,a3,-390 # ffffffffc0208148 <etext+0x198c>
ffffffffc02042d6:	00003617          	auipc	a2,0x3
ffffffffc02042da:	b6260613          	addi	a2,a2,-1182 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02042de:	09500593          	li	a1,149
ffffffffc02042e2:	00004517          	auipc	a0,0x4
ffffffffc02042e6:	df650513          	addi	a0,a0,-522 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02042ea:	98afc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02042ee <mm_map>:

int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042ee:	6785                	lui	a5,0x1
ffffffffc02042f0:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7611>
       struct vma_struct **vma_store) {
ffffffffc02042f2:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042f4:	787d                	lui	a6,0xfffff
ffffffffc02042f6:	963e                	add	a2,a2,a5
       struct vma_struct **vma_store) {
ffffffffc02042f8:	f822                	sd	s0,48(sp)
ffffffffc02042fa:	f426                	sd	s1,40(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042fc:	962e                	add	a2,a2,a1
       struct vma_struct **vma_store) {
ffffffffc02042fe:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0204300:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end)) {
ffffffffc0204304:	002007b7          	lui	a5,0x200
ffffffffc0204308:	01067433          	and	s0,a2,a6
ffffffffc020430c:	08f4e363          	bltu	s1,a5,ffffffffc0204392 <mm_map+0xa4>
ffffffffc0204310:	0884f163          	bgeu	s1,s0,ffffffffc0204392 <mm_map+0xa4>
ffffffffc0204314:	4785                	li	a5,1
ffffffffc0204316:	07fe                	slli	a5,a5,0x1f
ffffffffc0204318:	0687ed63          	bltu	a5,s0,ffffffffc0204392 <mm_map+0xa4>
ffffffffc020431c:	ec4e                	sd	s3,24(sp)
ffffffffc020431e:	89aa                	mv	s3,a0
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0204320:	c93d                	beqz	a0,ffffffffc0204396 <mm_map+0xa8>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc0204322:	85a6                	mv	a1,s1
ffffffffc0204324:	e852                	sd	s4,16(sp)
ffffffffc0204326:	e456                	sd	s5,8(sp)
ffffffffc0204328:	8a3a                	mv	s4,a4
ffffffffc020432a:	8ab6                	mv	s5,a3
ffffffffc020432c:	e61ff0ef          	jal	ffffffffc020418c <find_vma>
ffffffffc0204330:	c501                	beqz	a0,ffffffffc0204338 <mm_map+0x4a>
ffffffffc0204332:	651c                	ld	a5,8(a0)
ffffffffc0204334:	0487ec63          	bltu	a5,s0,ffffffffc020438c <mm_map+0x9e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204338:	03000513          	li	a0,48
ffffffffc020433c:	f04a                	sd	s2,32(sp)
ffffffffc020433e:	f8afd0ef          	jal	ffffffffc0201ac8 <kmalloc>
ffffffffc0204342:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0204344:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc0204346:	02090a63          	beqz	s2,ffffffffc020437a <mm_map+0x8c>
        vma->vm_start = vm_start;
ffffffffc020434a:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc020434e:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0204352:	01592c23          	sw	s5,24(s2)

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0204356:	85ca                	mv	a1,s2
ffffffffc0204358:	854e                	mv	a0,s3
ffffffffc020435a:	e73ff0ef          	jal	ffffffffc02041cc <insert_vma_struct>
    if (vma_store != NULL) {
ffffffffc020435e:	000a0463          	beqz	s4,ffffffffc0204366 <mm_map+0x78>
        *vma_store = vma;
ffffffffc0204362:	012a3023          	sd	s2,0(s4)
ffffffffc0204366:	7902                	ld	s2,32(sp)
ffffffffc0204368:	69e2                	ld	s3,24(sp)
ffffffffc020436a:	6a42                	ld	s4,16(sp)
ffffffffc020436c:	6aa2                	ld	s5,8(sp)
    }
    ret = 0;
ffffffffc020436e:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc0204370:	70e2                	ld	ra,56(sp)
ffffffffc0204372:	7442                	ld	s0,48(sp)
ffffffffc0204374:	74a2                	ld	s1,40(sp)
ffffffffc0204376:	6121                	addi	sp,sp,64
ffffffffc0204378:	8082                	ret
ffffffffc020437a:	70e2                	ld	ra,56(sp)
ffffffffc020437c:	7442                	ld	s0,48(sp)
ffffffffc020437e:	7902                	ld	s2,32(sp)
ffffffffc0204380:	69e2                	ld	s3,24(sp)
ffffffffc0204382:	6a42                	ld	s4,16(sp)
ffffffffc0204384:	6aa2                	ld	s5,8(sp)
ffffffffc0204386:	74a2                	ld	s1,40(sp)
ffffffffc0204388:	6121                	addi	sp,sp,64
ffffffffc020438a:	8082                	ret
ffffffffc020438c:	69e2                	ld	s3,24(sp)
ffffffffc020438e:	6a42                	ld	s4,16(sp)
ffffffffc0204390:	6aa2                	ld	s5,8(sp)
        return -E_INVAL;
ffffffffc0204392:	5575                	li	a0,-3
ffffffffc0204394:	bff1                	j	ffffffffc0204370 <mm_map+0x82>
    assert(mm != NULL);
ffffffffc0204396:	00004697          	auipc	a3,0x4
ffffffffc020439a:	82a68693          	addi	a3,a3,-2006 # ffffffffc0207bc0 <etext+0x1404>
ffffffffc020439e:	00003617          	auipc	a2,0x3
ffffffffc02043a2:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02043a6:	0a800593          	li	a1,168
ffffffffc02043aa:	00004517          	auipc	a0,0x4
ffffffffc02043ae:	d2e50513          	addi	a0,a0,-722 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02043b2:	f04a                	sd	s2,32(sp)
ffffffffc02043b4:	e852                	sd	s4,16(sp)
ffffffffc02043b6:	e456                	sd	s5,8(sp)
ffffffffc02043b8:	8bcfc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02043bc <dup_mmap>:

int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc02043bc:	7139                	addi	sp,sp,-64
ffffffffc02043be:	fc06                	sd	ra,56(sp)
ffffffffc02043c0:	f822                	sd	s0,48(sp)
ffffffffc02043c2:	f426                	sd	s1,40(sp)
ffffffffc02043c4:	f04a                	sd	s2,32(sp)
ffffffffc02043c6:	ec4e                	sd	s3,24(sp)
ffffffffc02043c8:	e852                	sd	s4,16(sp)
ffffffffc02043ca:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02043cc:	c525                	beqz	a0,ffffffffc0204434 <dup_mmap+0x78>
ffffffffc02043ce:	892a                	mv	s2,a0
ffffffffc02043d0:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02043d2:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02043d4:	c1a5                	beqz	a1,ffffffffc0204434 <dup_mmap+0x78>
    return listelm->prev;
ffffffffc02043d6:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc02043d8:	04848c63          	beq	s1,s0,ffffffffc0204430 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02043dc:	03000513          	li	a0,48
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02043e0:	fe843a83          	ld	s5,-24(s0)
ffffffffc02043e4:	ff043a03          	ld	s4,-16(s0)
ffffffffc02043e8:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02043ec:	edcfd0ef          	jal	ffffffffc0201ac8 <kmalloc>
ffffffffc02043f0:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc02043f2:	c50d                	beqz	a0,ffffffffc020441c <dup_mmap+0x60>
        vma->vm_start = vm_start;
ffffffffc02043f4:	01553423          	sd	s5,8(a0)
ffffffffc02043f8:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02043fc:	01352c23          	sw	s3,24(a0)
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0204400:	854a                	mv	a0,s2
ffffffffc0204402:	dcbff0ef          	jal	ffffffffc02041cc <insert_vma_struct>
        //将dup_mmap中的share变量的值改为1，启用共享
        bool share = 1;//
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc0204406:	ff043683          	ld	a3,-16(s0)
ffffffffc020440a:	fe843603          	ld	a2,-24(s0)
ffffffffc020440e:	6c8c                	ld	a1,24(s1)
ffffffffc0204410:	01893503          	ld	a0,24(s2)
ffffffffc0204414:	4705                	li	a4,1
ffffffffc0204416:	cf1fe0ef          	jal	ffffffffc0203106 <copy_range>
ffffffffc020441a:	dd55                	beqz	a0,ffffffffc02043d6 <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc020441c:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020441e:	70e2                	ld	ra,56(sp)
ffffffffc0204420:	7442                	ld	s0,48(sp)
ffffffffc0204422:	74a2                	ld	s1,40(sp)
ffffffffc0204424:	7902                	ld	s2,32(sp)
ffffffffc0204426:	69e2                	ld	s3,24(sp)
ffffffffc0204428:	6a42                	ld	s4,16(sp)
ffffffffc020442a:	6aa2                	ld	s5,8(sp)
ffffffffc020442c:	6121                	addi	sp,sp,64
ffffffffc020442e:	8082                	ret
    return 0;
ffffffffc0204430:	4501                	li	a0,0
ffffffffc0204432:	b7f5                	j	ffffffffc020441e <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc0204434:	00004697          	auipc	a3,0x4
ffffffffc0204438:	d2c68693          	addi	a3,a3,-724 # ffffffffc0208160 <etext+0x19a4>
ffffffffc020443c:	00003617          	auipc	a2,0x3
ffffffffc0204440:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0204444:	0c100593          	li	a1,193
ffffffffc0204448:	00004517          	auipc	a0,0x4
ffffffffc020444c:	c9050513          	addi	a0,a0,-880 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204450:	824fc0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0204454 <exit_mmap>:

void
exit_mmap(struct mm_struct *mm) {
ffffffffc0204454:	1101                	addi	sp,sp,-32
ffffffffc0204456:	ec06                	sd	ra,24(sp)
ffffffffc0204458:	e822                	sd	s0,16(sp)
ffffffffc020445a:	e426                	sd	s1,8(sp)
ffffffffc020445c:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020445e:	c531                	beqz	a0,ffffffffc02044aa <exit_mmap+0x56>
ffffffffc0204460:	591c                	lw	a5,48(a0)
ffffffffc0204462:	84aa                	mv	s1,a0
ffffffffc0204464:	e3b9                	bnez	a5,ffffffffc02044aa <exit_mmap+0x56>
    return listelm->next;
ffffffffc0204466:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0204468:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc020446c:	02850663          	beq	a0,s0,ffffffffc0204498 <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0204470:	ff043603          	ld	a2,-16(s0)
ffffffffc0204474:	fe843583          	ld	a1,-24(s0)
ffffffffc0204478:	854a                	mv	a0,s2
ffffffffc020447a:	b5dfd0ef          	jal	ffffffffc0201fd6 <unmap_range>
ffffffffc020447e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0204480:	fe8498e3          	bne	s1,s0,ffffffffc0204470 <exit_mmap+0x1c>
ffffffffc0204484:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc0204486:	00848c63          	beq	s1,s0,ffffffffc020449e <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc020448a:	ff043603          	ld	a2,-16(s0)
ffffffffc020448e:	fe843583          	ld	a1,-24(s0)
ffffffffc0204492:	854a                	mv	a0,s2
ffffffffc0204494:	c6dfd0ef          	jal	ffffffffc0202100 <exit_range>
ffffffffc0204498:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc020449a:	fe8498e3          	bne	s1,s0,ffffffffc020448a <exit_mmap+0x36>
    }
}
ffffffffc020449e:	60e2                	ld	ra,24(sp)
ffffffffc02044a0:	6442                	ld	s0,16(sp)
ffffffffc02044a2:	64a2                	ld	s1,8(sp)
ffffffffc02044a4:	6902                	ld	s2,0(sp)
ffffffffc02044a6:	6105                	addi	sp,sp,32
ffffffffc02044a8:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02044aa:	00004697          	auipc	a3,0x4
ffffffffc02044ae:	cd668693          	addi	a3,a3,-810 # ffffffffc0208180 <etext+0x19c4>
ffffffffc02044b2:	00003617          	auipc	a2,0x3
ffffffffc02044b6:	98660613          	addi	a2,a2,-1658 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02044ba:	0d700593          	li	a1,215
ffffffffc02044be:	00004517          	auipc	a0,0x4
ffffffffc02044c2:	c1a50513          	addi	a0,a0,-998 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02044c6:	faffb0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02044ca <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc02044ca:	7139                	addi	sp,sp,-64
ffffffffc02044cc:	f822                	sd	s0,48(sp)
ffffffffc02044ce:	f426                	sd	s1,40(sp)
ffffffffc02044d0:	fc06                	sd	ra,56(sp)
ffffffffc02044d2:	f04a                	sd	s2,32(sp)
ffffffffc02044d4:	ec4e                	sd	s3,24(sp)
ffffffffc02044d6:	e852                	sd	s4,16(sp)
ffffffffc02044d8:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc02044da:	c3dff0ef          	jal	ffffffffc0204116 <mm_create>
    assert(mm != NULL);
ffffffffc02044de:	842a                	mv	s0,a0
ffffffffc02044e0:	03200493          	li	s1,50
ffffffffc02044e4:	38050463          	beqz	a0,ffffffffc020486c <vmm_init+0x3a2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02044e8:	03000513          	li	a0,48
ffffffffc02044ec:	ddcfd0ef          	jal	ffffffffc0201ac8 <kmalloc>
ffffffffc02044f0:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc02044f2:	26050d63          	beqz	a0,ffffffffc020476c <vmm_init+0x2a2>
        vma->vm_end = vm_end;
ffffffffc02044f6:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc02044fa:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02044fc:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02044fe:	00052c23          	sw	zero,24(a0)

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc0204502:	14ed                	addi	s1,s1,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0204504:	8522                	mv	a0,s0
ffffffffc0204506:	cc7ff0ef          	jal	ffffffffc02041cc <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc020450a:	fcf9                	bnez	s1,ffffffffc02044e8 <vmm_init+0x1e>
ffffffffc020450c:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0204510:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204514:	03000513          	li	a0,48
ffffffffc0204518:	db0fd0ef          	jal	ffffffffc0201ac8 <kmalloc>
ffffffffc020451c:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc020451e:	26050763          	beqz	a0,ffffffffc020478c <vmm_init+0x2c2>
        vma->vm_end = vm_end;
ffffffffc0204522:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0204526:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204528:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020452a:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc020452e:	0495                	addi	s1,s1,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0204530:	8522                	mv	a0,s0
ffffffffc0204532:	c9bff0ef          	jal	ffffffffc02041cc <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0204536:	fd249fe3          	bne	s1,s2,ffffffffc0204514 <vmm_init+0x4a>
ffffffffc020453a:	641c                	ld	a5,8(s0)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc020453c:	30878863          	beq	a5,s0,ffffffffc020484c <vmm_init+0x382>
ffffffffc0204540:	4715                	li	a4,5
    for (i = 1; i <= step2; i ++) {
ffffffffc0204542:	1f400593          	li	a1,500
ffffffffc0204546:	a021                	j	ffffffffc020454e <vmm_init+0x84>
        assert(le != &(mm->mmap_list));
ffffffffc0204548:	0715                	addi	a4,a4,5
ffffffffc020454a:	30878163          	beq	a5,s0,ffffffffc020484c <vmm_init+0x382>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020454e:	fe87b683          	ld	a3,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f6480>
ffffffffc0204552:	2ae69d63          	bne	a3,a4,ffffffffc020480c <vmm_init+0x342>
ffffffffc0204556:	ff07b603          	ld	a2,-16(a5)
ffffffffc020455a:	00270693          	addi	a3,a4,2
ffffffffc020455e:	2ad61763          	bne	a2,a3,ffffffffc020480c <vmm_init+0x342>
ffffffffc0204562:	679c                	ld	a5,8(a5)
    for (i = 1; i <= step2; i ++) {
ffffffffc0204564:	feb712e3          	bne	a4,a1,ffffffffc0204548 <vmm_init+0x7e>
ffffffffc0204568:	4a1d                	li	s4,7
ffffffffc020456a:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020456c:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0204570:	85a6                	mv	a1,s1
ffffffffc0204572:	8522                	mv	a0,s0
ffffffffc0204574:	c19ff0ef          	jal	ffffffffc020418c <find_vma>
ffffffffc0204578:	89aa                	mv	s3,a0
        assert(vma1 != NULL);
ffffffffc020457a:	2a050963          	beqz	a0,ffffffffc020482c <vmm_init+0x362>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc020457e:	00148593          	addi	a1,s1,1
ffffffffc0204582:	8522                	mv	a0,s0
ffffffffc0204584:	c09ff0ef          	jal	ffffffffc020418c <find_vma>
ffffffffc0204588:	892a                	mv	s2,a0
        assert(vma2 != NULL);
ffffffffc020458a:	36050163          	beqz	a0,ffffffffc02048ec <vmm_init+0x422>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc020458e:	85d2                	mv	a1,s4
ffffffffc0204590:	8522                	mv	a0,s0
ffffffffc0204592:	bfbff0ef          	jal	ffffffffc020418c <find_vma>
        assert(vma3 == NULL);
ffffffffc0204596:	32051b63          	bnez	a0,ffffffffc02048cc <vmm_init+0x402>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc020459a:	00348593          	addi	a1,s1,3
ffffffffc020459e:	8522                	mv	a0,s0
ffffffffc02045a0:	bedff0ef          	jal	ffffffffc020418c <find_vma>
        assert(vma4 == NULL);
ffffffffc02045a4:	30051463          	bnez	a0,ffffffffc02048ac <vmm_init+0x3e2>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc02045a8:	00448593          	addi	a1,s1,4
ffffffffc02045ac:	8522                	mv	a0,s0
ffffffffc02045ae:	bdfff0ef          	jal	ffffffffc020418c <find_vma>
        assert(vma5 == NULL);
ffffffffc02045b2:	2c051d63          	bnez	a0,ffffffffc020488c <vmm_init+0x3c2>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02045b6:	0089b783          	ld	a5,8(s3)
ffffffffc02045ba:	22979963          	bne	a5,s1,ffffffffc02047ec <vmm_init+0x322>
ffffffffc02045be:	0109b783          	ld	a5,16(s3)
ffffffffc02045c2:	23479563          	bne	a5,s4,ffffffffc02047ec <vmm_init+0x322>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02045c6:	00893783          	ld	a5,8(s2)
ffffffffc02045ca:	20979163          	bne	a5,s1,ffffffffc02047cc <vmm_init+0x302>
ffffffffc02045ce:	01093783          	ld	a5,16(s2)
ffffffffc02045d2:	1f479d63          	bne	a5,s4,ffffffffc02047cc <vmm_init+0x302>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02045d6:	0495                	addi	s1,s1,5
ffffffffc02045d8:	0a15                	addi	s4,s4,5
ffffffffc02045da:	f9549be3          	bne	s1,s5,ffffffffc0204570 <vmm_init+0xa6>
ffffffffc02045de:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc02045e0:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc02045e2:	85a6                	mv	a1,s1
ffffffffc02045e4:	8522                	mv	a0,s0
ffffffffc02045e6:	ba7ff0ef          	jal	ffffffffc020418c <find_vma>
        if (vma_below_5 != NULL ) {
ffffffffc02045ea:	38051163          	bnez	a0,ffffffffc020496c <vmm_init+0x4a2>
    for (i =4; i>=0; i--) {
ffffffffc02045ee:	14fd                	addi	s1,s1,-1
ffffffffc02045f0:	ff2499e3          	bne	s1,s2,ffffffffc02045e2 <vmm_init+0x118>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc02045f4:	8522                	mv	a0,s0
ffffffffc02045f6:	ca7ff0ef          	jal	ffffffffc020429c <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02045fa:	00004517          	auipc	a0,0x4
ffffffffc02045fe:	ce650513          	addi	a0,a0,-794 # ffffffffc02082e0 <etext+0x1b24>
ffffffffc0204602:	b7ffb0ef          	jal	ffffffffc0200180 <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204606:	f6afd0ef          	jal	ffffffffc0201d70 <nr_free_pages>
ffffffffc020460a:	892a                	mv	s2,a0

    check_mm_struct = mm_create();
ffffffffc020460c:	b0bff0ef          	jal	ffffffffc0204116 <mm_create>
ffffffffc0204610:	00099797          	auipc	a5,0x99
ffffffffc0204614:	6ea7b023          	sd	a0,1760(a5) # ffffffffc029dcf0 <check_mm_struct>
ffffffffc0204618:	842a                	mv	s0,a0
    assert(check_mm_struct != NULL);
ffffffffc020461a:	32050963          	beqz	a0,ffffffffc020494c <vmm_init+0x482>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020461e:	00099497          	auipc	s1,0x99
ffffffffc0204622:	6924b483          	ld	s1,1682(s1) # ffffffffc029dcb0 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0204626:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204628:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc020462a:	30079163          	bnez	a5,ffffffffc020492c <vmm_init+0x462>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020462e:	03000513          	li	a0,48
ffffffffc0204632:	c96fd0ef          	jal	ffffffffc0201ac8 <kmalloc>
ffffffffc0204636:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc0204638:	16050a63          	beqz	a0,ffffffffc02047ac <vmm_init+0x2e2>
        vma->vm_end = vm_end;
ffffffffc020463c:	002007b7          	lui	a5,0x200
ffffffffc0204640:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204642:	4789                	li	a5,2
ffffffffc0204644:	cd1c                	sw	a5,24(a0)

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0204646:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0204648:	00053423          	sd	zero,8(a0)
    insert_vma_struct(mm, vma);
ffffffffc020464c:	8522                	mv	a0,s0
ffffffffc020464e:	b7fff0ef          	jal	ffffffffc02041cc <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0204652:	10000593          	li	a1,256
ffffffffc0204656:	8522                	mv	a0,s0
ffffffffc0204658:	b35ff0ef          	jal	ffffffffc020418c <find_vma>
ffffffffc020465c:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc0204660:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0204664:	2aa99463          	bne	s3,a0,ffffffffc020490c <vmm_init+0x442>
        *(char *)(addr + i) = i;
ffffffffc0204668:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f6498>
    for (i = 0; i < 100; i ++) {
ffffffffc020466c:	0785                	addi	a5,a5,1
ffffffffc020466e:	fee79de3          	bne	a5,a4,ffffffffc0204668 <vmm_init+0x19e>
ffffffffc0204672:	6705                	lui	a4,0x1
ffffffffc0204674:	10000793          	li	a5,256
ffffffffc0204678:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_softint_out_size-0x72ba>
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
ffffffffc020467c:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0204680:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0204684:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0204686:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0204688:	fec79ce3          	bne	a5,a2,ffffffffc0204680 <vmm_init+0x1b6>
    }

    assert(sum == 0);
ffffffffc020468c:	34071863          	bnez	a4,ffffffffc02049dc <vmm_init+0x512>
    return pa2page(PDE_ADDR(pde));
ffffffffc0204690:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0204692:	00099a97          	auipc	s5,0x99
ffffffffc0204696:	62ea8a93          	addi	s5,s5,1582 # ffffffffc029dcc0 <npage>
ffffffffc020469a:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020469e:	078a                	slli	a5,a5,0x2
ffffffffc02046a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046a2:	32e7fb63          	bgeu	a5,a4,ffffffffc02049d8 <vmm_init+0x50e>
    return &pages[PPN(pa) - nbase];
ffffffffc02046a6:	00005a17          	auipc	s4,0x5
ffffffffc02046aa:	80aa3a03          	ld	s4,-2038(s4) # ffffffffc0208eb0 <nbase>
ffffffffc02046ae:	414786b3          	sub	a3,a5,s4
ffffffffc02046b2:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc02046b4:	8699                	srai	a3,a3,0x6
ffffffffc02046b6:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc02046b8:	00c69793          	slli	a5,a3,0xc
ffffffffc02046bc:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02046be:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02046c0:	30e7f063          	bgeu	a5,a4,ffffffffc02049c0 <vmm_init+0x4f6>
ffffffffc02046c4:	00099797          	auipc	a5,0x99
ffffffffc02046c8:	5f47b783          	ld	a5,1524(a5) # ffffffffc029dcb8 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02046cc:	4581                	li	a1,0
ffffffffc02046ce:	8526                	mv	a0,s1
ffffffffc02046d0:	00f689b3          	add	s3,a3,a5
ffffffffc02046d4:	d07fd0ef          	jal	ffffffffc02023da <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02046d8:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc02046dc:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02046e0:	078a                	slli	a5,a5,0x2
ffffffffc02046e2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046e4:	2ee7fa63          	bgeu	a5,a4,ffffffffc02049d8 <vmm_init+0x50e>
    return &pages[PPN(pa) - nbase];
ffffffffc02046e8:	00099997          	auipc	s3,0x99
ffffffffc02046ec:	5e098993          	addi	s3,s3,1504 # ffffffffc029dcc8 <pages>
ffffffffc02046f0:	0009b503          	ld	a0,0(s3)
ffffffffc02046f4:	414787b3          	sub	a5,a5,s4
ffffffffc02046f8:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc02046fa:	953e                	add	a0,a0,a5
ffffffffc02046fc:	4585                	li	a1,1
ffffffffc02046fe:	e32fd0ef          	jal	ffffffffc0201d30 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0204702:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0204704:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0204708:	078a                	slli	a5,a5,0x2
ffffffffc020470a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020470c:	2ce7f663          	bgeu	a5,a4,ffffffffc02049d8 <vmm_init+0x50e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204710:	0009b503          	ld	a0,0(s3)
ffffffffc0204714:	414787b3          	sub	a5,a5,s4
ffffffffc0204718:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc020471a:	4585                	li	a1,1
ffffffffc020471c:	953e                	add	a0,a0,a5
ffffffffc020471e:	e12fd0ef          	jal	ffffffffc0201d30 <free_pages>
    pgdir[0] = 0;
ffffffffc0204722:	0004b023          	sd	zero,0(s1)
  asm volatile("sfence.vma");
ffffffffc0204726:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc020472a:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc020472e:	8522                	mv	a0,s0
ffffffffc0204730:	b6dff0ef          	jal	ffffffffc020429c <mm_destroy>
    check_mm_struct = NULL;
ffffffffc0204734:	00099797          	auipc	a5,0x99
ffffffffc0204738:	5a07be23          	sd	zero,1468(a5) # ffffffffc029dcf0 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020473c:	e34fd0ef          	jal	ffffffffc0201d70 <nr_free_pages>
ffffffffc0204740:	26a91063          	bne	s2,a0,ffffffffc02049a0 <vmm_init+0x4d6>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0204744:	00004517          	auipc	a0,0x4
ffffffffc0204748:	c2c50513          	addi	a0,a0,-980 # ffffffffc0208370 <etext+0x1bb4>
ffffffffc020474c:	a35fb0ef          	jal	ffffffffc0200180 <cprintf>
}
ffffffffc0204750:	7442                	ld	s0,48(sp)
ffffffffc0204752:	70e2                	ld	ra,56(sp)
ffffffffc0204754:	74a2                	ld	s1,40(sp)
ffffffffc0204756:	7902                	ld	s2,32(sp)
ffffffffc0204758:	69e2                	ld	s3,24(sp)
ffffffffc020475a:	6a42                	ld	s4,16(sp)
ffffffffc020475c:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020475e:	00004517          	auipc	a0,0x4
ffffffffc0204762:	c3250513          	addi	a0,a0,-974 # ffffffffc0208390 <etext+0x1bd4>
}
ffffffffc0204766:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0204768:	a19fb06f          	j	ffffffffc0200180 <cprintf>
        assert(vma != NULL);
ffffffffc020476c:	00003697          	auipc	a3,0x3
ffffffffc0204770:	48c68693          	addi	a3,a3,1164 # ffffffffc0207bf8 <etext+0x143c>
ffffffffc0204774:	00002617          	auipc	a2,0x2
ffffffffc0204778:	6c460613          	addi	a2,a2,1732 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020477c:	11400593          	li	a1,276
ffffffffc0204780:	00004517          	auipc	a0,0x4
ffffffffc0204784:	95850513          	addi	a0,a0,-1704 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204788:	cedfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(vma != NULL);
ffffffffc020478c:	00003697          	auipc	a3,0x3
ffffffffc0204790:	46c68693          	addi	a3,a3,1132 # ffffffffc0207bf8 <etext+0x143c>
ffffffffc0204794:	00002617          	auipc	a2,0x2
ffffffffc0204798:	6a460613          	addi	a2,a2,1700 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020479c:	11a00593          	li	a1,282
ffffffffc02047a0:	00004517          	auipc	a0,0x4
ffffffffc02047a4:	93850513          	addi	a0,a0,-1736 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02047a8:	ccdfb0ef          	jal	ffffffffc0200474 <__panic>
    assert(vma != NULL);
ffffffffc02047ac:	00003697          	auipc	a3,0x3
ffffffffc02047b0:	44c68693          	addi	a3,a3,1100 # ffffffffc0207bf8 <etext+0x143c>
ffffffffc02047b4:	00002617          	auipc	a2,0x2
ffffffffc02047b8:	68460613          	addi	a2,a2,1668 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02047bc:	15300593          	li	a1,339
ffffffffc02047c0:	00004517          	auipc	a0,0x4
ffffffffc02047c4:	91850513          	addi	a0,a0,-1768 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02047c8:	cadfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02047cc:	00004697          	auipc	a3,0x4
ffffffffc02047d0:	aa468693          	addi	a3,a3,-1372 # ffffffffc0208270 <etext+0x1ab4>
ffffffffc02047d4:	00002617          	auipc	a2,0x2
ffffffffc02047d8:	66460613          	addi	a2,a2,1636 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02047dc:	13400593          	li	a1,308
ffffffffc02047e0:	00004517          	auipc	a0,0x4
ffffffffc02047e4:	8f850513          	addi	a0,a0,-1800 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02047e8:	c8dfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02047ec:	00004697          	auipc	a3,0x4
ffffffffc02047f0:	a5468693          	addi	a3,a3,-1452 # ffffffffc0208240 <etext+0x1a84>
ffffffffc02047f4:	00002617          	auipc	a2,0x2
ffffffffc02047f8:	64460613          	addi	a2,a2,1604 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02047fc:	13300593          	li	a1,307
ffffffffc0204800:	00004517          	auipc	a0,0x4
ffffffffc0204804:	8d850513          	addi	a0,a0,-1832 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204808:	c6dfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020480c:	00004697          	auipc	a3,0x4
ffffffffc0204810:	9ac68693          	addi	a3,a3,-1620 # ffffffffc02081b8 <etext+0x19fc>
ffffffffc0204814:	00002617          	auipc	a2,0x2
ffffffffc0204818:	62460613          	addi	a2,a2,1572 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020481c:	12300593          	li	a1,291
ffffffffc0204820:	00004517          	auipc	a0,0x4
ffffffffc0204824:	8b850513          	addi	a0,a0,-1864 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204828:	c4dfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(vma1 != NULL);
ffffffffc020482c:	00004697          	auipc	a3,0x4
ffffffffc0204830:	9c468693          	addi	a3,a3,-1596 # ffffffffc02081f0 <etext+0x1a34>
ffffffffc0204834:	00002617          	auipc	a2,0x2
ffffffffc0204838:	60460613          	addi	a2,a2,1540 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020483c:	12900593          	li	a1,297
ffffffffc0204840:	00004517          	auipc	a0,0x4
ffffffffc0204844:	89850513          	addi	a0,a0,-1896 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204848:	c2dfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020484c:	00004697          	auipc	a3,0x4
ffffffffc0204850:	95468693          	addi	a3,a3,-1708 # ffffffffc02081a0 <etext+0x19e4>
ffffffffc0204854:	00002617          	auipc	a2,0x2
ffffffffc0204858:	5e460613          	addi	a2,a2,1508 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020485c:	12100593          	li	a1,289
ffffffffc0204860:	00004517          	auipc	a0,0x4
ffffffffc0204864:	87850513          	addi	a0,a0,-1928 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204868:	c0dfb0ef          	jal	ffffffffc0200474 <__panic>
    assert(mm != NULL);
ffffffffc020486c:	00003697          	auipc	a3,0x3
ffffffffc0204870:	35468693          	addi	a3,a3,852 # ffffffffc0207bc0 <etext+0x1404>
ffffffffc0204874:	00002617          	auipc	a2,0x2
ffffffffc0204878:	5c460613          	addi	a2,a2,1476 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020487c:	10d00593          	li	a1,269
ffffffffc0204880:	00004517          	auipc	a0,0x4
ffffffffc0204884:	85850513          	addi	a0,a0,-1960 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204888:	bedfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(vma5 == NULL);
ffffffffc020488c:	00004697          	auipc	a3,0x4
ffffffffc0204890:	9a468693          	addi	a3,a3,-1628 # ffffffffc0208230 <etext+0x1a74>
ffffffffc0204894:	00002617          	auipc	a2,0x2
ffffffffc0204898:	5a460613          	addi	a2,a2,1444 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020489c:	13100593          	li	a1,305
ffffffffc02048a0:	00004517          	auipc	a0,0x4
ffffffffc02048a4:	83850513          	addi	a0,a0,-1992 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02048a8:	bcdfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(vma4 == NULL);
ffffffffc02048ac:	00004697          	auipc	a3,0x4
ffffffffc02048b0:	97468693          	addi	a3,a3,-1676 # ffffffffc0208220 <etext+0x1a64>
ffffffffc02048b4:	00002617          	auipc	a2,0x2
ffffffffc02048b8:	58460613          	addi	a2,a2,1412 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02048bc:	12f00593          	li	a1,303
ffffffffc02048c0:	00004517          	auipc	a0,0x4
ffffffffc02048c4:	81850513          	addi	a0,a0,-2024 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02048c8:	badfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(vma3 == NULL);
ffffffffc02048cc:	00004697          	auipc	a3,0x4
ffffffffc02048d0:	94468693          	addi	a3,a3,-1724 # ffffffffc0208210 <etext+0x1a54>
ffffffffc02048d4:	00002617          	auipc	a2,0x2
ffffffffc02048d8:	56460613          	addi	a2,a2,1380 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02048dc:	12d00593          	li	a1,301
ffffffffc02048e0:	00003517          	auipc	a0,0x3
ffffffffc02048e4:	7f850513          	addi	a0,a0,2040 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02048e8:	b8dfb0ef          	jal	ffffffffc0200474 <__panic>
        assert(vma2 != NULL);
ffffffffc02048ec:	00004697          	auipc	a3,0x4
ffffffffc02048f0:	91468693          	addi	a3,a3,-1772 # ffffffffc0208200 <etext+0x1a44>
ffffffffc02048f4:	00002617          	auipc	a2,0x2
ffffffffc02048f8:	54460613          	addi	a2,a2,1348 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02048fc:	12b00593          	li	a1,299
ffffffffc0204900:	00003517          	auipc	a0,0x3
ffffffffc0204904:	7d850513          	addi	a0,a0,2008 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204908:	b6dfb0ef          	jal	ffffffffc0200474 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc020490c:	00004697          	auipc	a3,0x4
ffffffffc0204910:	a0c68693          	addi	a3,a3,-1524 # ffffffffc0208318 <etext+0x1b5c>
ffffffffc0204914:	00002617          	auipc	a2,0x2
ffffffffc0204918:	52460613          	addi	a2,a2,1316 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020491c:	15800593          	li	a1,344
ffffffffc0204920:	00003517          	auipc	a0,0x3
ffffffffc0204924:	7b850513          	addi	a0,a0,1976 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204928:	b4dfb0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgdir[0] == 0);
ffffffffc020492c:	00003697          	auipc	a3,0x3
ffffffffc0204930:	2bc68693          	addi	a3,a3,700 # ffffffffc0207be8 <etext+0x142c>
ffffffffc0204934:	00002617          	auipc	a2,0x2
ffffffffc0204938:	50460613          	addi	a2,a2,1284 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020493c:	15000593          	li	a1,336
ffffffffc0204940:	00003517          	auipc	a0,0x3
ffffffffc0204944:	79850513          	addi	a0,a0,1944 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204948:	b2dfb0ef          	jal	ffffffffc0200474 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc020494c:	00004697          	auipc	a3,0x4
ffffffffc0204950:	9b468693          	addi	a3,a3,-1612 # ffffffffc0208300 <etext+0x1b44>
ffffffffc0204954:	00002617          	auipc	a2,0x2
ffffffffc0204958:	4e460613          	addi	a2,a2,1252 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020495c:	14c00593          	li	a1,332
ffffffffc0204960:	00003517          	auipc	a0,0x3
ffffffffc0204964:	77850513          	addi	a0,a0,1912 # ffffffffc02080d8 <etext+0x191c>
ffffffffc0204968:	b0dfb0ef          	jal	ffffffffc0200474 <__panic>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc020496c:	6914                	ld	a3,16(a0)
ffffffffc020496e:	6510                	ld	a2,8(a0)
ffffffffc0204970:	0004859b          	sext.w	a1,s1
ffffffffc0204974:	00004517          	auipc	a0,0x4
ffffffffc0204978:	92c50513          	addi	a0,a0,-1748 # ffffffffc02082a0 <etext+0x1ae4>
ffffffffc020497c:	805fb0ef          	jal	ffffffffc0200180 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0204980:	00004697          	auipc	a3,0x4
ffffffffc0204984:	94868693          	addi	a3,a3,-1720 # ffffffffc02082c8 <etext+0x1b0c>
ffffffffc0204988:	00002617          	auipc	a2,0x2
ffffffffc020498c:	4b060613          	addi	a2,a2,1200 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0204990:	13c00593          	li	a1,316
ffffffffc0204994:	00003517          	auipc	a0,0x3
ffffffffc0204998:	74450513          	addi	a0,a0,1860 # ffffffffc02080d8 <etext+0x191c>
ffffffffc020499c:	ad9fb0ef          	jal	ffffffffc0200474 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02049a0:	00004697          	auipc	a3,0x4
ffffffffc02049a4:	9a868693          	addi	a3,a3,-1624 # ffffffffc0208348 <etext+0x1b8c>
ffffffffc02049a8:	00002617          	auipc	a2,0x2
ffffffffc02049ac:	49060613          	addi	a2,a2,1168 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02049b0:	17100593          	li	a1,369
ffffffffc02049b4:	00003517          	auipc	a0,0x3
ffffffffc02049b8:	72450513          	addi	a0,a0,1828 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02049bc:	ab9fb0ef          	jal	ffffffffc0200474 <__panic>
    return KADDR(page2pa(page));
ffffffffc02049c0:	00003617          	auipc	a2,0x3
ffffffffc02049c4:	aa060613          	addi	a2,a2,-1376 # ffffffffc0207460 <etext+0xca4>
ffffffffc02049c8:	06900593          	li	a1,105
ffffffffc02049cc:	00003517          	auipc	a0,0x3
ffffffffc02049d0:	abc50513          	addi	a0,a0,-1348 # ffffffffc0207488 <etext+0xccc>
ffffffffc02049d4:	aa1fb0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc02049d8:	f22ff0ef          	jal	ffffffffc02040fa <pa2page.part.0>
    assert(sum == 0);
ffffffffc02049dc:	00004697          	auipc	a3,0x4
ffffffffc02049e0:	95c68693          	addi	a3,a3,-1700 # ffffffffc0208338 <etext+0x1b7c>
ffffffffc02049e4:	00002617          	auipc	a2,0x2
ffffffffc02049e8:	45460613          	addi	a2,a2,1108 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02049ec:	16400593          	li	a1,356
ffffffffc02049f0:	00003517          	auipc	a0,0x3
ffffffffc02049f4:	6e850513          	addi	a0,a0,1768 # ffffffffc02080d8 <etext+0x191c>
ffffffffc02049f8:	a7dfb0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02049fc <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02049fc:	715d                	addi	sp,sp,-80
ffffffffc02049fe:	e0a2                	sd	s0,64(sp)
ffffffffc0204a00:	842e                	mv	s0,a1
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0204a02:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0204a04:	fc26                	sd	s1,56(sp)
ffffffffc0204a06:	f84a                	sd	s2,48(sp)
ffffffffc0204a08:	e486                	sd	ra,72(sp)
ffffffffc0204a0a:	84b2                	mv	s1,a2
ffffffffc0204a0c:	892a                	mv	s2,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0204a0e:	f7eff0ef          	jal	ffffffffc020418c <find_vma>

    pgfault_num++;
ffffffffc0204a12:	00099797          	auipc	a5,0x99
ffffffffc0204a16:	2d67a783          	lw	a5,726(a5) # ffffffffc029dce8 <pgfault_num>
ffffffffc0204a1a:	2785                	addiw	a5,a5,1
ffffffffc0204a1c:	00099717          	auipc	a4,0x99
ffffffffc0204a20:	2cf72623          	sw	a5,716(a4) # ffffffffc029dce8 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0204a24:	14050363          	beqz	a0,ffffffffc0204b6a <do_pgfault+0x16e>
ffffffffc0204a28:	651c                	ld	a5,8(a0)
ffffffffc0204a2a:	14f4e063          	bltu	s1,a5,ffffffffc0204b6a <do_pgfault+0x16e>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204a2e:	4d1c                	lw	a5,24(a0)
ffffffffc0204a30:	f44e                	sd	s3,40(sp)
        perm |= READ_WRITE;
ffffffffc0204a32:	49dd                	li	s3,23
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204a34:	8b89                	andi	a5,a5,2
ffffffffc0204a36:	c7b5                	beqz	a5,ffffffffc0204aa2 <do_pgfault+0xa6>
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204a38:	77fd                	lui	a5,0xfffff
    // }


    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204a3a:	01893503          	ld	a0,24(s2)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204a3e:	8cfd                	and	s1,s1,a5
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204a40:	4605                	li	a2,1
ffffffffc0204a42:	85a6                	mv	a1,s1
ffffffffc0204a44:	b66fd0ef          	jal	ffffffffc0201daa <get_pte>
ffffffffc0204a48:	14050163          	beqz	a0,ffffffffc0204b8a <do_pgfault+0x18e>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc0204a4c:	610c                	ld	a1,0(a0)
ffffffffc0204a4e:	0e058763          	beqz	a1,ffffffffc0204b3c <do_pgfault+0x140>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else if ((*ptep & PTE_V) & (error_code & 3 == 3)) {
ffffffffc0204a52:	8c6d                	and	s0,s0,a1
ffffffffc0204a54:	8805                	andi	s0,s0,1
ffffffffc0204a56:	e821                	bnez	s0,ffffffffc0204aa6 <do_pgfault+0xaa>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0204a58:	00099797          	auipc	a5,0x99
ffffffffc0204a5c:	2787a783          	lw	a5,632(a5) # ffffffffc029dcd0 <swap_init_ok>
ffffffffc0204a60:	10078e63          	beqz	a5,ffffffffc0204b7c <do_pgfault+0x180>
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            // cprintf("do_pgfault called!!!\n");
            if((ret = swap_in(mm,addr,&page)) != 0) {
ffffffffc0204a64:	0030                	addi	a2,sp,8
ffffffffc0204a66:	85a6                	mv	a1,s1
ffffffffc0204a68:	854a                	mv	a0,s2
            struct Page *page = NULL;
ffffffffc0204a6a:	e402                	sd	zero,8(sp)
            if((ret = swap_in(mm,addr,&page)) != 0) {
ffffffffc0204a6c:	a0eff0ef          	jal	ffffffffc0203c7a <swap_in>
ffffffffc0204a70:	0e051663          	bnez	a0,ffffffffc0204b5c <do_pgfault+0x160>
                goto failed;
            }
            page_insert(mm->pgdir,page,addr,perm);
ffffffffc0204a74:	65a2                	ld	a1,8(sp)
ffffffffc0204a76:	01893503          	ld	a0,24(s2)
ffffffffc0204a7a:	86ce                	mv	a3,s3
ffffffffc0204a7c:	8626                	mv	a2,s1
ffffffffc0204a7e:	9f9fd0ef          	jal	ffffffffc0202476 <page_insert>
            swap_map_swappable(mm,addr,page,1);
ffffffffc0204a82:	6622                	ld	a2,8(sp)
ffffffffc0204a84:	4685                	li	a3,1
ffffffffc0204a86:	85a6                	mv	a1,s1
ffffffffc0204a88:	854a                	mv	a0,s2
ffffffffc0204a8a:	8ceff0ef          	jal	ffffffffc0203b58 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0204a8e:	67a2                	ld	a5,8(sp)
ffffffffc0204a90:	ff84                	sd	s1,56(a5)
ffffffffc0204a92:	79a2                	ld	s3,40(sp)
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }
   ret = 0;
ffffffffc0204a94:	4501                	li	a0,0
failed:
    return ret;
}
ffffffffc0204a96:	60a6                	ld	ra,72(sp)
ffffffffc0204a98:	6406                	ld	s0,64(sp)
ffffffffc0204a9a:	74e2                	ld	s1,56(sp)
ffffffffc0204a9c:	7942                	ld	s2,48(sp)
ffffffffc0204a9e:	6161                	addi	sp,sp,80
ffffffffc0204aa0:	8082                	ret
    uint32_t perm = PTE_U;
ffffffffc0204aa2:	49c1                	li	s3,16
ffffffffc0204aa4:	bf51                	j	ffffffffc0204a38 <do_pgfault+0x3c>
ffffffffc0204aa6:	f052                	sd	s4,32(sp)
ffffffffc0204aa8:	ec56                	sd	s5,24(sp)
ffffffffc0204aaa:	e85a                	sd	s6,16(sp)
    if (!(pte & PTE_V)) {
ffffffffc0204aac:	0015f793          	andi	a5,a1,1
ffffffffc0204ab0:	10078163          	beqz	a5,ffffffffc0204bb2 <do_pgfault+0x1b6>
    if (PPN(pa) >= npage) {
ffffffffc0204ab4:	00099a97          	auipc	s5,0x99
ffffffffc0204ab8:	20ca8a93          	addi	s5,s5,524 # ffffffffc029dcc0 <npage>
ffffffffc0204abc:	000ab783          	ld	a5,0(s5)
    return pa2page(PTE_ADDR(pte));
ffffffffc0204ac0:	058a                	slli	a1,a1,0x2
ffffffffc0204ac2:	81b1                	srli	a1,a1,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204ac4:	10f5f363          	bgeu	a1,a5,ffffffffc0204bca <do_pgfault+0x1ce>
    return &pages[PPN(pa) - nbase];
ffffffffc0204ac8:	00099b17          	auipc	s6,0x99
ffffffffc0204acc:	200b0b13          	addi	s6,s6,512 # ffffffffc029dcc8 <pages>
ffffffffc0204ad0:	00004a17          	auipc	s4,0x4
ffffffffc0204ad4:	3e0a3a03          	ld	s4,992(s4) # ffffffffc0208eb0 <nbase>
ffffffffc0204ad8:	000b3403          	ld	s0,0(s6)
    struct Page * npage = pgdir_alloc_page(mm-> pgdir, addr, perm);
ffffffffc0204adc:	01893503          	ld	a0,24(s2)
ffffffffc0204ae0:	414585b3          	sub	a1,a1,s4
ffffffffc0204ae4:	00659793          	slli	a5,a1,0x6
ffffffffc0204ae8:	864e                	mv	a2,s3
ffffffffc0204aea:	85a6                	mv	a1,s1
ffffffffc0204aec:	943e                	add	s0,s0,a5
ffffffffc0204aee:	819fe0ef          	jal	ffffffffc0203306 <pgdir_alloc_page>
    return page - pages + nbase;
ffffffffc0204af2:	000b3783          	ld	a5,0(s6)
    return KADDR(page2pa(page));
ffffffffc0204af6:	577d                	li	a4,-1
ffffffffc0204af8:	000ab603          	ld	a2,0(s5)
    return page - pages + nbase;
ffffffffc0204afc:	40f406b3          	sub	a3,s0,a5
ffffffffc0204b00:	8699                	srai	a3,a3,0x6
ffffffffc0204b02:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0204b04:	8331                	srli	a4,a4,0xc
ffffffffc0204b06:	00e6f5b3          	and	a1,a3,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b0a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b0c:	08c5f763          	bgeu	a1,a2,ffffffffc0204b9a <do_pgfault+0x19e>
    return page - pages + nbase;
ffffffffc0204b10:	40f507b3          	sub	a5,a0,a5
ffffffffc0204b14:	8799                	srai	a5,a5,0x6
ffffffffc0204b16:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0204b18:	00099517          	auipc	a0,0x99
ffffffffc0204b1c:	1a053503          	ld	a0,416(a0) # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0204b20:	8f7d                	and	a4,a4,a5
ffffffffc0204b22:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b26:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0204b28:	06c77863          	bgeu	a4,a2,ffffffffc0204b98 <do_pgfault+0x19c>
    memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0204b2c:	6605                	lui	a2,0x1
ffffffffc0204b2e:	953e                	add	a0,a0,a5
ffffffffc0204b30:	475010ef          	jal	ffffffffc02067a4 <memcpy>
ffffffffc0204b34:	7a02                	ld	s4,32(sp)
ffffffffc0204b36:	6ae2                	ld	s5,24(sp)
ffffffffc0204b38:	6b42                	ld	s6,16(sp)
ffffffffc0204b3a:	bfa1                	j	ffffffffc0204a92 <do_pgfault+0x96>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204b3c:	01893503          	ld	a0,24(s2)
ffffffffc0204b40:	864e                	mv	a2,s3
ffffffffc0204b42:	85a6                	mv	a1,s1
ffffffffc0204b44:	fc2fe0ef          	jal	ffffffffc0203306 <pgdir_alloc_page>
ffffffffc0204b48:	f529                	bnez	a0,ffffffffc0204a92 <do_pgfault+0x96>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204b4a:	00004517          	auipc	a0,0x4
ffffffffc0204b4e:	8ae50513          	addi	a0,a0,-1874 # ffffffffc02083f8 <etext+0x1c3c>
ffffffffc0204b52:	e2efb0ef          	jal	ffffffffc0200180 <cprintf>
            goto failed;
ffffffffc0204b56:	79a2                	ld	s3,40(sp)
    ret = -E_NO_MEM;
ffffffffc0204b58:	5571                	li	a0,-4
ffffffffc0204b5a:	bf35                	j	ffffffffc0204a96 <do_pgfault+0x9a>
}
ffffffffc0204b5c:	60a6                	ld	ra,72(sp)
ffffffffc0204b5e:	6406                	ld	s0,64(sp)
ffffffffc0204b60:	79a2                	ld	s3,40(sp)
ffffffffc0204b62:	74e2                	ld	s1,56(sp)
ffffffffc0204b64:	7942                	ld	s2,48(sp)
ffffffffc0204b66:	6161                	addi	sp,sp,80
ffffffffc0204b68:	8082                	ret
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0204b6a:	85a6                	mv	a1,s1
ffffffffc0204b6c:	00004517          	auipc	a0,0x4
ffffffffc0204b70:	83c50513          	addi	a0,a0,-1988 # ffffffffc02083a8 <etext+0x1bec>
ffffffffc0204b74:	e0cfb0ef          	jal	ffffffffc0200180 <cprintf>
    int ret = -E_INVAL;
ffffffffc0204b78:	5575                	li	a0,-3
        goto failed;
ffffffffc0204b7a:	bf31                	j	ffffffffc0204a96 <do_pgfault+0x9a>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0204b7c:	00004517          	auipc	a0,0x4
ffffffffc0204b80:	8a450513          	addi	a0,a0,-1884 # ffffffffc0208420 <etext+0x1c64>
ffffffffc0204b84:	dfcfb0ef          	jal	ffffffffc0200180 <cprintf>
            goto failed;
ffffffffc0204b88:	b7f9                	j	ffffffffc0204b56 <do_pgfault+0x15a>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0204b8a:	00004517          	auipc	a0,0x4
ffffffffc0204b8e:	84e50513          	addi	a0,a0,-1970 # ffffffffc02083d8 <etext+0x1c1c>
ffffffffc0204b92:	deefb0ef          	jal	ffffffffc0200180 <cprintf>
        goto failed;
ffffffffc0204b96:	b7c1                	j	ffffffffc0204b56 <do_pgfault+0x15a>
ffffffffc0204b98:	86be                	mv	a3,a5
ffffffffc0204b9a:	00003617          	auipc	a2,0x3
ffffffffc0204b9e:	8c660613          	addi	a2,a2,-1850 # ffffffffc0207460 <etext+0xca4>
ffffffffc0204ba2:	06900593          	li	a1,105
ffffffffc0204ba6:	00003517          	auipc	a0,0x3
ffffffffc0204baa:	8e250513          	addi	a0,a0,-1822 # ffffffffc0207488 <etext+0xccc>
ffffffffc0204bae:	8c7fb0ef          	jal	ffffffffc0200474 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0204bb2:	00003617          	auipc	a2,0x3
ffffffffc0204bb6:	99e60613          	addi	a2,a2,-1634 # ffffffffc0207550 <etext+0xd94>
ffffffffc0204bba:	07400593          	li	a1,116
ffffffffc0204bbe:	00003517          	auipc	a0,0x3
ffffffffc0204bc2:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0207488 <etext+0xccc>
ffffffffc0204bc6:	8affb0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc0204bca:	d30ff0ef          	jal	ffffffffc02040fa <pa2page.part.0>

ffffffffc0204bce <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0204bce:	7179                	addi	sp,sp,-48
ffffffffc0204bd0:	f022                	sd	s0,32(sp)
ffffffffc0204bd2:	f406                	sd	ra,40(sp)
ffffffffc0204bd4:	842e                	mv	s0,a1
    if (mm != NULL) {
ffffffffc0204bd6:	c535                	beqz	a0,ffffffffc0204c42 <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0204bd8:	002007b7          	lui	a5,0x200
ffffffffc0204bdc:	04f5ee63          	bltu	a1,a5,ffffffffc0204c38 <user_mem_check+0x6a>
ffffffffc0204be0:	ec26                	sd	s1,24(sp)
ffffffffc0204be2:	00c584b3          	add	s1,a1,a2
ffffffffc0204be6:	0695fc63          	bgeu	a1,s1,ffffffffc0204c5e <user_mem_check+0x90>
ffffffffc0204bea:	4785                	li	a5,1
ffffffffc0204bec:	07fe                	slli	a5,a5,0x1f
ffffffffc0204bee:	0697e863          	bltu	a5,s1,ffffffffc0204c5e <user_mem_check+0x90>
ffffffffc0204bf2:	e84a                	sd	s2,16(sp)
ffffffffc0204bf4:	e44e                	sd	s3,8(sp)
ffffffffc0204bf6:	e052                	sd	s4,0(sp)
ffffffffc0204bf8:	892a                	mv	s2,a0
ffffffffc0204bfa:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204bfc:	6a05                	lui	s4,0x1
ffffffffc0204bfe:	a821                	j	ffffffffc0204c16 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204c00:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204c04:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204c06:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204c08:	c685                	beqz	a3,ffffffffc0204c30 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204c0a:	c399                	beqz	a5,ffffffffc0204c10 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204c0c:	02e46263          	bltu	s0,a4,ffffffffc0204c30 <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0204c10:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc0204c12:	04947863          	bgeu	s0,s1,ffffffffc0204c62 <user_mem_check+0x94>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc0204c16:	85a2                	mv	a1,s0
ffffffffc0204c18:	854a                	mv	a0,s2
ffffffffc0204c1a:	d72ff0ef          	jal	ffffffffc020418c <find_vma>
ffffffffc0204c1e:	c909                	beqz	a0,ffffffffc0204c30 <user_mem_check+0x62>
ffffffffc0204c20:	6518                	ld	a4,8(a0)
ffffffffc0204c22:	00e46763          	bltu	s0,a4,ffffffffc0204c30 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204c26:	4d1c                	lw	a5,24(a0)
ffffffffc0204c28:	fc099ce3          	bnez	s3,ffffffffc0204c00 <user_mem_check+0x32>
ffffffffc0204c2c:	8b85                	andi	a5,a5,1
ffffffffc0204c2e:	f3ed                	bnez	a5,ffffffffc0204c10 <user_mem_check+0x42>
ffffffffc0204c30:	64e2                	ld	s1,24(sp)
ffffffffc0204c32:	6942                	ld	s2,16(sp)
ffffffffc0204c34:	69a2                	ld	s3,8(sp)
ffffffffc0204c36:	6a02                	ld	s4,0(sp)
            return 0;
ffffffffc0204c38:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204c3a:	70a2                	ld	ra,40(sp)
ffffffffc0204c3c:	7402                	ld	s0,32(sp)
ffffffffc0204c3e:	6145                	addi	sp,sp,48
ffffffffc0204c40:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204c42:	c02007b7          	lui	a5,0xc0200
ffffffffc0204c46:	4501                	li	a0,0
ffffffffc0204c48:	fef5e9e3          	bltu	a1,a5,ffffffffc0204c3a <user_mem_check+0x6c>
ffffffffc0204c4c:	962e                	add	a2,a2,a1
ffffffffc0204c4e:	fec5f6e3          	bgeu	a1,a2,ffffffffc0204c3a <user_mem_check+0x6c>
ffffffffc0204c52:	c8000537          	lui	a0,0xc8000
ffffffffc0204c56:	0505                	addi	a0,a0,1 # ffffffffc8000001 <end+0x7d622e9>
ffffffffc0204c58:	00a63533          	sltu	a0,a2,a0
ffffffffc0204c5c:	bff9                	j	ffffffffc0204c3a <user_mem_check+0x6c>
ffffffffc0204c5e:	64e2                	ld	s1,24(sp)
ffffffffc0204c60:	bfe1                	j	ffffffffc0204c38 <user_mem_check+0x6a>
ffffffffc0204c62:	64e2                	ld	s1,24(sp)
ffffffffc0204c64:	6942                	ld	s2,16(sp)
ffffffffc0204c66:	69a2                	ld	s3,8(sp)
ffffffffc0204c68:	6a02                	ld	s4,0(sp)
        return 1;
ffffffffc0204c6a:	4505                	li	a0,1
ffffffffc0204c6c:	b7f9                	j	ffffffffc0204c3a <user_mem_check+0x6c>

ffffffffc0204c6e <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204c6e:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204c70:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204c72:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204c74:	973fb0ef          	jal	ffffffffc02005e6 <ide_device_valid>
ffffffffc0204c78:	cd01                	beqz	a0,ffffffffc0204c90 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204c7a:	4505                	li	a0,1
ffffffffc0204c7c:	971fb0ef          	jal	ffffffffc02005ec <ide_device_size>
}
ffffffffc0204c80:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204c82:	810d                	srli	a0,a0,0x3
ffffffffc0204c84:	00099797          	auipc	a5,0x99
ffffffffc0204c88:	04a7ba23          	sd	a0,84(a5) # ffffffffc029dcd8 <max_swap_offset>
}
ffffffffc0204c8c:	0141                	addi	sp,sp,16
ffffffffc0204c8e:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204c90:	00003617          	auipc	a2,0x3
ffffffffc0204c94:	7b860613          	addi	a2,a2,1976 # ffffffffc0208448 <etext+0x1c8c>
ffffffffc0204c98:	45b5                	li	a1,13
ffffffffc0204c9a:	00003517          	auipc	a0,0x3
ffffffffc0204c9e:	7ce50513          	addi	a0,a0,1998 # ffffffffc0208468 <etext+0x1cac>
ffffffffc0204ca2:	fd2fb0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0204ca6 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204ca6:	1141                	addi	sp,sp,-16
ffffffffc0204ca8:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204caa:	00855793          	srli	a5,a0,0x8
ffffffffc0204cae:	cbb1                	beqz	a5,ffffffffc0204d02 <swapfs_read+0x5c>
ffffffffc0204cb0:	00099717          	auipc	a4,0x99
ffffffffc0204cb4:	02873703          	ld	a4,40(a4) # ffffffffc029dcd8 <max_swap_offset>
ffffffffc0204cb8:	04e7f563          	bgeu	a5,a4,ffffffffc0204d02 <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204cbc:	00099717          	auipc	a4,0x99
ffffffffc0204cc0:	00c73703          	ld	a4,12(a4) # ffffffffc029dcc8 <pages>
ffffffffc0204cc4:	8d99                	sub	a1,a1,a4
ffffffffc0204cc6:	4065d613          	srai	a2,a1,0x6
ffffffffc0204cca:	00004717          	auipc	a4,0x4
ffffffffc0204cce:	1e673703          	ld	a4,486(a4) # ffffffffc0208eb0 <nbase>
ffffffffc0204cd2:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204cd4:	00c61713          	slli	a4,a2,0xc
ffffffffc0204cd8:	8331                	srli	a4,a4,0xc
ffffffffc0204cda:	00099697          	auipc	a3,0x99
ffffffffc0204cde:	fe66b683          	ld	a3,-26(a3) # ffffffffc029dcc0 <npage>
ffffffffc0204ce2:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ce6:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204ce8:	02d77963          	bgeu	a4,a3,ffffffffc0204d1a <swapfs_read+0x74>
}
ffffffffc0204cec:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204cee:	00099797          	auipc	a5,0x99
ffffffffc0204cf2:	fca7b783          	ld	a5,-54(a5) # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0204cf6:	46a1                	li	a3,8
ffffffffc0204cf8:	963e                	add	a2,a2,a5
ffffffffc0204cfa:	4505                	li	a0,1
}
ffffffffc0204cfc:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204cfe:	8f5fb06f          	j	ffffffffc02005f2 <ide_read_secs>
ffffffffc0204d02:	86aa                	mv	a3,a0
ffffffffc0204d04:	00003617          	auipc	a2,0x3
ffffffffc0204d08:	77c60613          	addi	a2,a2,1916 # ffffffffc0208480 <etext+0x1cc4>
ffffffffc0204d0c:	45d1                	li	a1,20
ffffffffc0204d0e:	00003517          	auipc	a0,0x3
ffffffffc0204d12:	75a50513          	addi	a0,a0,1882 # ffffffffc0208468 <etext+0x1cac>
ffffffffc0204d16:	f5efb0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc0204d1a:	86b2                	mv	a3,a2
ffffffffc0204d1c:	06900593          	li	a1,105
ffffffffc0204d20:	00002617          	auipc	a2,0x2
ffffffffc0204d24:	74060613          	addi	a2,a2,1856 # ffffffffc0207460 <etext+0xca4>
ffffffffc0204d28:	00002517          	auipc	a0,0x2
ffffffffc0204d2c:	76050513          	addi	a0,a0,1888 # ffffffffc0207488 <etext+0xccc>
ffffffffc0204d30:	f44fb0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0204d34 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204d34:	1141                	addi	sp,sp,-16
ffffffffc0204d36:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204d38:	00855793          	srli	a5,a0,0x8
ffffffffc0204d3c:	cbb1                	beqz	a5,ffffffffc0204d90 <swapfs_write+0x5c>
ffffffffc0204d3e:	00099717          	auipc	a4,0x99
ffffffffc0204d42:	f9a73703          	ld	a4,-102(a4) # ffffffffc029dcd8 <max_swap_offset>
ffffffffc0204d46:	04e7f563          	bgeu	a5,a4,ffffffffc0204d90 <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc0204d4a:	00099717          	auipc	a4,0x99
ffffffffc0204d4e:	f7e73703          	ld	a4,-130(a4) # ffffffffc029dcc8 <pages>
ffffffffc0204d52:	8d99                	sub	a1,a1,a4
ffffffffc0204d54:	4065d613          	srai	a2,a1,0x6
ffffffffc0204d58:	00004717          	auipc	a4,0x4
ffffffffc0204d5c:	15873703          	ld	a4,344(a4) # ffffffffc0208eb0 <nbase>
ffffffffc0204d60:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204d62:	00c61713          	slli	a4,a2,0xc
ffffffffc0204d66:	8331                	srli	a4,a4,0xc
ffffffffc0204d68:	00099697          	auipc	a3,0x99
ffffffffc0204d6c:	f586b683          	ld	a3,-168(a3) # ffffffffc029dcc0 <npage>
ffffffffc0204d70:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d74:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204d76:	02d77963          	bgeu	a4,a3,ffffffffc0204da8 <swapfs_write+0x74>
}
ffffffffc0204d7a:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204d7c:	00099797          	auipc	a5,0x99
ffffffffc0204d80:	f3c7b783          	ld	a5,-196(a5) # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0204d84:	46a1                	li	a3,8
ffffffffc0204d86:	963e                	add	a2,a2,a5
ffffffffc0204d88:	4505                	li	a0,1
}
ffffffffc0204d8a:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204d8c:	88bfb06f          	j	ffffffffc0200616 <ide_write_secs>
ffffffffc0204d90:	86aa                	mv	a3,a0
ffffffffc0204d92:	00003617          	auipc	a2,0x3
ffffffffc0204d96:	6ee60613          	addi	a2,a2,1774 # ffffffffc0208480 <etext+0x1cc4>
ffffffffc0204d9a:	45e5                	li	a1,25
ffffffffc0204d9c:	00003517          	auipc	a0,0x3
ffffffffc0204da0:	6cc50513          	addi	a0,a0,1740 # ffffffffc0208468 <etext+0x1cac>
ffffffffc0204da4:	ed0fb0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc0204da8:	86b2                	mv	a3,a2
ffffffffc0204daa:	06900593          	li	a1,105
ffffffffc0204dae:	00002617          	auipc	a2,0x2
ffffffffc0204db2:	6b260613          	addi	a2,a2,1714 # ffffffffc0207460 <etext+0xca4>
ffffffffc0204db6:	00002517          	auipc	a0,0x2
ffffffffc0204dba:	6d250513          	addi	a0,a0,1746 # ffffffffc0207488 <etext+0xccc>
ffffffffc0204dbe:	eb6fb0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0204dc2 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204dc2:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204dc4:	9402                	jalr	s0

	jal do_exit
ffffffffc0204dc6:	670000ef          	jal	ffffffffc0205436 <do_exit>

ffffffffc0204dca <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204dca:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204dcc:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204dd0:	e022                	sd	s0,0(sp)
ffffffffc0204dd2:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204dd4:	cf5fc0ef          	jal	ffffffffc0201ac8 <kmalloc>
ffffffffc0204dd8:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204dda:	cd21                	beqz	a0,ffffffffc0204e32 <alloc_proc+0x68>
     /*
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
        proc->state = PROC_UNINIT;
ffffffffc0204ddc:	57fd                	li	a5,-1
ffffffffc0204dde:	1782                	slli	a5,a5,0x20
ffffffffc0204de0:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0204de2:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0204de6:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0204dea:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0204dee:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0204df2:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204df6:	07000613          	li	a2,112
ffffffffc0204dfa:	4581                	li	a1,0
ffffffffc0204dfc:	03050513          	addi	a0,a0,48
ffffffffc0204e00:	193010ef          	jal	ffffffffc0206792 <memset>
        proc->tf = NULL;
        proc->cr3 = boot_cr3;
ffffffffc0204e04:	00099797          	auipc	a5,0x99
ffffffffc0204e08:	ea47b783          	ld	a5,-348(a5) # ffffffffc029dca8 <boot_cr3>
        proc->tf = NULL;
ffffffffc0204e0c:	0a043023          	sd	zero,160(s0)
        proc->cr3 = boot_cr3;
ffffffffc0204e10:	f45c                	sd	a5,168(s0)
        proc->flags = 0;
ffffffffc0204e12:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN);
ffffffffc0204e16:	463d                	li	a2,15
ffffffffc0204e18:	4581                	li	a1,0
ffffffffc0204e1a:	0b440513          	addi	a0,s0,180
ffffffffc0204e1e:	175010ef          	jal	ffffffffc0206792 <memset>
        proc->wait_state = 0;
ffffffffc0204e22:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;
ffffffffc0204e26:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;
ffffffffc0204e2a:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;
ffffffffc0204e2e:	0e043c23          	sd	zero,248(s0)
    }
    return proc;
}
ffffffffc0204e32:	60a2                	ld	ra,8(sp)
ffffffffc0204e34:	8522                	mv	a0,s0
ffffffffc0204e36:	6402                	ld	s0,0(sp)
ffffffffc0204e38:	0141                	addi	sp,sp,16
ffffffffc0204e3a:	8082                	ret

ffffffffc0204e3c <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204e3c:	00099797          	auipc	a5,0x99
ffffffffc0204e40:	ec47b783          	ld	a5,-316(a5) # ffffffffc029dd00 <current>
ffffffffc0204e44:	73c8                	ld	a0,160(a5)
ffffffffc0204e46:	f15fb06f          	j	ffffffffc0200d5a <forkrets>

ffffffffc0204e4a <user_main>:

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204e4a:	00099797          	auipc	a5,0x99
ffffffffc0204e4e:	eb67b783          	ld	a5,-330(a5) # ffffffffc029dd00 <current>
ffffffffc0204e52:	43cc                	lw	a1,4(a5)
user_main(void *arg) {
ffffffffc0204e54:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204e56:	00003617          	auipc	a2,0x3
ffffffffc0204e5a:	64a60613          	addi	a2,a2,1610 # ffffffffc02084a0 <etext+0x1ce4>
ffffffffc0204e5e:	00003517          	auipc	a0,0x3
ffffffffc0204e62:	65250513          	addi	a0,a0,1618 # ffffffffc02084b0 <etext+0x1cf4>
user_main(void *arg) {
ffffffffc0204e66:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204e68:	b18fb0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc0204e6c:	3fe04797          	auipc	a5,0x3fe04
ffffffffc0204e70:	43c78793          	addi	a5,a5,1084 # 92a8 <_binary_obj___user_forktest_out_size>
ffffffffc0204e74:	e43e                	sd	a5,8(sp)
ffffffffc0204e76:	00003517          	auipc	a0,0x3
ffffffffc0204e7a:	62a50513          	addi	a0,a0,1578 # ffffffffc02084a0 <etext+0x1ce4>
ffffffffc0204e7e:	0003d797          	auipc	a5,0x3d
ffffffffc0204e82:	31278793          	addi	a5,a5,786 # ffffffffc0242190 <_binary_obj___user_forktest_out_start>
ffffffffc0204e86:	f03e                	sd	a5,32(sp)
ffffffffc0204e88:	f42a                	sd	a0,40(sp)
    int64_t ret=0, len = strlen(name);
ffffffffc0204e8a:	e802                	sd	zero,16(sp)
ffffffffc0204e8c:	071010ef          	jal	ffffffffc02066fc <strlen>
ffffffffc0204e90:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204e92:	4511                	li	a0,4
ffffffffc0204e94:	55a2                	lw	a1,40(sp)
ffffffffc0204e96:	4662                	lw	a2,24(sp)
ffffffffc0204e98:	5682                	lw	a3,32(sp)
ffffffffc0204e9a:	4722                	lw	a4,8(sp)
ffffffffc0204e9c:	48a9                	li	a7,10
ffffffffc0204e9e:	9002                	ebreak
ffffffffc0204ea0:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204ea2:	65c2                	ld	a1,16(sp)
ffffffffc0204ea4:	00003517          	auipc	a0,0x3
ffffffffc0204ea8:	63450513          	addi	a0,a0,1588 # ffffffffc02084d8 <etext+0x1d1c>
ffffffffc0204eac:	ad4fb0ef          	jal	ffffffffc0200180 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204eb0:	00003617          	auipc	a2,0x3
ffffffffc0204eb4:	63860613          	addi	a2,a2,1592 # ffffffffc02084e8 <etext+0x1d2c>
ffffffffc0204eb8:	35500593          	li	a1,853
ffffffffc0204ebc:	00003517          	auipc	a0,0x3
ffffffffc0204ec0:	64c50513          	addi	a0,a0,1612 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0204ec4:	db0fb0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0204ec8 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204ec8:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204eca:	1141                	addi	sp,sp,-16
ffffffffc0204ecc:	e406                	sd	ra,8(sp)
ffffffffc0204ece:	c02007b7          	lui	a5,0xc0200
ffffffffc0204ed2:	02f6ee63          	bltu	a3,a5,ffffffffc0204f0e <put_pgdir+0x46>
ffffffffc0204ed6:	00099797          	auipc	a5,0x99
ffffffffc0204eda:	de27b783          	ld	a5,-542(a5) # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0204ede:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0204ee0:	82b1                	srli	a3,a3,0xc
ffffffffc0204ee2:	00099797          	auipc	a5,0x99
ffffffffc0204ee6:	dde7b783          	ld	a5,-546(a5) # ffffffffc029dcc0 <npage>
ffffffffc0204eea:	02f6fe63          	bgeu	a3,a5,ffffffffc0204f26 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204eee:	00004797          	auipc	a5,0x4
ffffffffc0204ef2:	fc27b783          	ld	a5,-62(a5) # ffffffffc0208eb0 <nbase>
}
ffffffffc0204ef6:	60a2                	ld	ra,8(sp)
ffffffffc0204ef8:	8e9d                	sub	a3,a3,a5
    free_page(kva2page(mm->pgdir));
ffffffffc0204efa:	00099517          	auipc	a0,0x99
ffffffffc0204efe:	dce53503          	ld	a0,-562(a0) # ffffffffc029dcc8 <pages>
ffffffffc0204f02:	069a                	slli	a3,a3,0x6
ffffffffc0204f04:	4585                	li	a1,1
ffffffffc0204f06:	9536                	add	a0,a0,a3
}
ffffffffc0204f08:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204f0a:	e27fc06f          	j	ffffffffc0201d30 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204f0e:	00002617          	auipc	a2,0x2
ffffffffc0204f12:	5fa60613          	addi	a2,a2,1530 # ffffffffc0207508 <etext+0xd4c>
ffffffffc0204f16:	06e00593          	li	a1,110
ffffffffc0204f1a:	00002517          	auipc	a0,0x2
ffffffffc0204f1e:	56e50513          	addi	a0,a0,1390 # ffffffffc0207488 <etext+0xccc>
ffffffffc0204f22:	d52fb0ef          	jal	ffffffffc0200474 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204f26:	00002617          	auipc	a2,0x2
ffffffffc0204f2a:	60a60613          	addi	a2,a2,1546 # ffffffffc0207530 <etext+0xd74>
ffffffffc0204f2e:	06200593          	li	a1,98
ffffffffc0204f32:	00002517          	auipc	a0,0x2
ffffffffc0204f36:	55650513          	addi	a0,a0,1366 # ffffffffc0207488 <etext+0xccc>
ffffffffc0204f3a:	d3afb0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0204f3e <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204f3e:	7179                	addi	sp,sp,-48
ffffffffc0204f40:	ec4a                	sd	s2,24(sp)
    if (proc != current) {
ffffffffc0204f42:	00099917          	auipc	s2,0x99
ffffffffc0204f46:	dbe90913          	addi	s2,s2,-578 # ffffffffc029dd00 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0204f4a:	f026                	sd	s1,32(sp)
    if (proc != current) {
ffffffffc0204f4c:	00093483          	ld	s1,0(s2)
proc_run(struct proc_struct *proc) {
ffffffffc0204f50:	f406                	sd	ra,40(sp)
    if (proc != current) {
ffffffffc0204f52:	02a48a63          	beq	s1,a0,ffffffffc0204f86 <proc_run+0x48>
ffffffffc0204f56:	e84e                	sd	s3,16(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204f58:	100027f3          	csrr	a5,sstatus
ffffffffc0204f5c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204f5e:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204f60:	ef9d                	bnez	a5,ffffffffc0204f9e <proc_run+0x60>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204f62:	755c                	ld	a5,168(a0)
ffffffffc0204f64:	577d                	li	a4,-1
ffffffffc0204f66:	177e                	slli	a4,a4,0x3f
ffffffffc0204f68:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204f6a:	00a93023          	sd	a0,0(s2)
ffffffffc0204f6e:	8fd9                	or	a5,a5,a4
ffffffffc0204f70:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204f74:	03050593          	addi	a1,a0,48
ffffffffc0204f78:	03048513          	addi	a0,s1,48
ffffffffc0204f7c:	112010ef          	jal	ffffffffc020608e <switch_to>
    if (flag) {
ffffffffc0204f80:	00099863          	bnez	s3,ffffffffc0204f90 <proc_run+0x52>
ffffffffc0204f84:	69c2                	ld	s3,16(sp)
}
ffffffffc0204f86:	70a2                	ld	ra,40(sp)
ffffffffc0204f88:	7482                	ld	s1,32(sp)
ffffffffc0204f8a:	6962                	ld	s2,24(sp)
ffffffffc0204f8c:	6145                	addi	sp,sp,48
ffffffffc0204f8e:	8082                	ret
        intr_enable();
ffffffffc0204f90:	69c2                	ld	s3,16(sp)
ffffffffc0204f92:	70a2                	ld	ra,40(sp)
ffffffffc0204f94:	7482                	ld	s1,32(sp)
ffffffffc0204f96:	6962                	ld	s2,24(sp)
ffffffffc0204f98:	6145                	addi	sp,sp,48
ffffffffc0204f9a:	ea0fb06f          	j	ffffffffc020063a <intr_enable>
ffffffffc0204f9e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204fa0:	ea0fb0ef          	jal	ffffffffc0200640 <intr_disable>
        return 1;
ffffffffc0204fa4:	6522                	ld	a0,8(sp)
ffffffffc0204fa6:	4985                	li	s3,1
ffffffffc0204fa8:	bf6d                	j	ffffffffc0204f62 <proc_run+0x24>

ffffffffc0204faa <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204faa:	7119                	addi	sp,sp,-128
ffffffffc0204fac:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204fae:	00099917          	auipc	s2,0x99
ffffffffc0204fb2:	d4a90913          	addi	s2,s2,-694 # ffffffffc029dcf8 <nr_process>
ffffffffc0204fb6:	00092703          	lw	a4,0(s2)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204fba:	fc86                	sd	ra,120(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204fbc:	6785                	lui	a5,0x1
ffffffffc0204fbe:	36f75263          	bge	a4,a5,ffffffffc0205322 <do_fork+0x378>
ffffffffc0204fc2:	f8a2                	sd	s0,112(sp)
ffffffffc0204fc4:	f4a6                	sd	s1,104(sp)
ffffffffc0204fc6:	ecce                	sd	s3,88(sp)
ffffffffc0204fc8:	e8d2                	sd	s4,80(sp)
ffffffffc0204fca:	89ae                	mv	s3,a1
ffffffffc0204fcc:	8a2a                	mv	s4,a0
ffffffffc0204fce:	8432                	mv	s0,a2
    if((proc = alloc_proc()) == NULL) {
ffffffffc0204fd0:	dfbff0ef          	jal	ffffffffc0204dca <alloc_proc>
ffffffffc0204fd4:	84aa                	mv	s1,a0
ffffffffc0204fd6:	32050a63          	beqz	a0,ffffffffc020530a <do_fork+0x360>
    proc->parent = current;
ffffffffc0204fda:	f862                	sd	s8,48(sp)
ffffffffc0204fdc:	00099c17          	auipc	s8,0x99
ffffffffc0204fe0:	d24c0c13          	addi	s8,s8,-732 # ffffffffc029dd00 <current>
ffffffffc0204fe4:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);
ffffffffc0204fe8:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_softint_out_size-0x7524>
    proc->parent = current;
ffffffffc0204fec:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0204fee:	3a071a63          	bnez	a4,ffffffffc02053a2 <do_fork+0x3f8>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204ff2:	4509                	li	a0,2
ffffffffc0204ff4:	cadfc0ef          	jal	ffffffffc0201ca0 <alloc_pages>
    if (page != NULL) {
ffffffffc0204ff8:	30050563          	beqz	a0,ffffffffc0205302 <do_fork+0x358>
ffffffffc0204ffc:	e4d6                	sd	s5,72(sp)
    return page - pages + nbase;
ffffffffc0204ffe:	00099a97          	auipc	s5,0x99
ffffffffc0205002:	ccaa8a93          	addi	s5,s5,-822 # ffffffffc029dcc8 <pages>
ffffffffc0205006:	000ab703          	ld	a4,0(s5)
ffffffffc020500a:	e0da                	sd	s6,64(sp)
ffffffffc020500c:	00004b17          	auipc	s6,0x4
ffffffffc0205010:	ea4b0b13          	addi	s6,s6,-348 # ffffffffc0208eb0 <nbase>
ffffffffc0205014:	000b3783          	ld	a5,0(s6)
ffffffffc0205018:	40e506b3          	sub	a3,a0,a4
ffffffffc020501c:	fc5e                	sd	s7,56(sp)
    return KADDR(page2pa(page));
ffffffffc020501e:	00099b97          	auipc	s7,0x99
ffffffffc0205022:	ca2b8b93          	addi	s7,s7,-862 # ffffffffc029dcc0 <npage>
ffffffffc0205026:	ec6e                	sd	s11,24(sp)
    return page - pages + nbase;
ffffffffc0205028:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020502a:	5dfd                	li	s11,-1
ffffffffc020502c:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0205030:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205032:	00cddd93          	srli	s11,s11,0xc
ffffffffc0205036:	01b6f633          	and	a2,a3,s11
ffffffffc020503a:	f06a                	sd	s10,32(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc020503c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020503e:	30e67d63          	bgeu	a2,a4,ffffffffc0205358 <do_fork+0x3ae>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0205042:	000c3603          	ld	a2,0(s8)
ffffffffc0205046:	00099c17          	auipc	s8,0x99
ffffffffc020504a:	c72c0c13          	addi	s8,s8,-910 # ffffffffc029dcb8 <va_pa_offset>
ffffffffc020504e:	000c3703          	ld	a4,0(s8)
ffffffffc0205052:	02863d03          	ld	s10,40(a2)
ffffffffc0205056:	e43e                	sd	a5,8(sp)
ffffffffc0205058:	9736                	add	a4,a4,a3
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020505a:	e898                	sd	a4,16(s1)
    if (oldmm == NULL) {
ffffffffc020505c:	020d0863          	beqz	s10,ffffffffc020508c <do_fork+0xe2>
    if (clone_flags & CLONE_VM) {
ffffffffc0205060:	100a7a13          	andi	s4,s4,256
ffffffffc0205064:	1c0a0463          	beqz	s4,ffffffffc020522c <do_fork+0x282>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc0205068:	030d2783          	lw	a5,48(s10)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020506c:	018d3683          	ld	a3,24(s10)
ffffffffc0205070:	c0200737          	lui	a4,0xc0200
ffffffffc0205074:	2785                	addiw	a5,a5,1
ffffffffc0205076:	02fd2823          	sw	a5,48(s10)
    proc->mm = mm;
ffffffffc020507a:	03a4b423          	sd	s10,40(s1)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020507e:	2ce6e063          	bltu	a3,a4,ffffffffc020533e <do_fork+0x394>
ffffffffc0205082:	000c3783          	ld	a5,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0205086:	6898                	ld	a4,16(s1)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0205088:	8e9d                	sub	a3,a3,a5
ffffffffc020508a:	f4d4                	sd	a3,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020508c:	6689                	lui	a3,0x2
ffffffffc020508e:	ee068693          	addi	a3,a3,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6730>
ffffffffc0205092:	96ba                	add	a3,a3,a4
    *(proc->tf) = *tf;
ffffffffc0205094:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0205096:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0205098:	87b6                	mv	a5,a3
ffffffffc020509a:	12040313          	addi	t1,s0,288
ffffffffc020509e:	00063883          	ld	a7,0(a2)
ffffffffc02050a2:	00863803          	ld	a6,8(a2)
ffffffffc02050a6:	6a08                	ld	a0,16(a2)
ffffffffc02050a8:	6e0c                	ld	a1,24(a2)
ffffffffc02050aa:	0117b023          	sd	a7,0(a5)
ffffffffc02050ae:	0107b423          	sd	a6,8(a5)
ffffffffc02050b2:	eb88                	sd	a0,16(a5)
ffffffffc02050b4:	ef8c                	sd	a1,24(a5)
ffffffffc02050b6:	02060613          	addi	a2,a2,32
ffffffffc02050ba:	02078793          	addi	a5,a5,32
ffffffffc02050be:	fe6610e3          	bne	a2,t1,ffffffffc020509e <do_fork+0xf4>
    proc->tf->gpr.a0 = 0;
ffffffffc02050c2:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp;
ffffffffc02050c6:	12098d63          	beqz	s3,ffffffffc0205200 <do_fork+0x256>
ffffffffc02050ca:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02050ce:	00000797          	auipc	a5,0x0
ffffffffc02050d2:	d6e78793          	addi	a5,a5,-658 # ffffffffc0204e3c <forkret>
ffffffffc02050d6:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02050d8:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02050da:	100027f3          	csrr	a5,sstatus
ffffffffc02050de:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02050e0:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02050e2:	14079163          	bnez	a5,ffffffffc0205224 <do_fork+0x27a>
    if (++ last_pid >= MAX_PID) {
ffffffffc02050e6:	0008d817          	auipc	a6,0x8d
ffffffffc02050ea:	6ce80813          	addi	a6,a6,1742 # ffffffffc02927b4 <last_pid.1>
ffffffffc02050ee:	00082783          	lw	a5,0(a6)
ffffffffc02050f2:	6709                	lui	a4,0x2
ffffffffc02050f4:	0017851b          	addiw	a0,a5,1
ffffffffc02050f8:	00a82023          	sw	a0,0(a6)
ffffffffc02050fc:	08e55c63          	bge	a0,a4,ffffffffc0205194 <do_fork+0x1ea>
    if (last_pid >= next_safe) {
ffffffffc0205100:	0008d317          	auipc	t1,0x8d
ffffffffc0205104:	6b030313          	addi	t1,t1,1712 # ffffffffc02927b0 <next_safe.0>
ffffffffc0205108:	00032783          	lw	a5,0(t1)
ffffffffc020510c:	00099417          	auipc	s0,0x99
ffffffffc0205110:	b6440413          	addi	s0,s0,-1180 # ffffffffc029dc70 <proc_list>
ffffffffc0205114:	08f55863          	bge	a0,a5,ffffffffc02051a4 <do_fork+0x1fa>
        proc->pid = get_pid();
ffffffffc0205118:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020511a:	45a9                	li	a1,10
ffffffffc020511c:	2501                	sext.w	a0,a0
ffffffffc020511e:	1e0010ef          	jal	ffffffffc02062fe <hash32>
ffffffffc0205122:	02051793          	slli	a5,a0,0x20
ffffffffc0205126:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020512a:	00095797          	auipc	a5,0x95
ffffffffc020512e:	b4678793          	addi	a5,a5,-1210 # ffffffffc0299c70 <hash_list>
ffffffffc0205132:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0205134:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205136:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0205138:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc020513c:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020513e:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0205140:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205142:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0205144:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0205148:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc020514a:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc020514c:	e21c                	sd	a5,0(a2)
ffffffffc020514e:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0205150:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0205152:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0205154:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205158:	10e4b023          	sd	a4,256(s1)
ffffffffc020515c:	c311                	beqz	a4,ffffffffc0205160 <do_fork+0x1b6>
        proc->optr->yptr = proc;
ffffffffc020515e:	ff64                	sd	s1,248(a4)
    nr_process ++;
ffffffffc0205160:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0205164:	fae4                	sd	s1,240(a3)
    nr_process ++;
ffffffffc0205166:	2785                	addiw	a5,a5,1
ffffffffc0205168:	00f92023          	sw	a5,0(s2)
    if (flag) {
ffffffffc020516c:	14099163          	bnez	s3,ffffffffc02052ae <do_fork+0x304>
    wakeup_proc(proc);
ffffffffc0205170:	8526                	mv	a0,s1
ffffffffc0205172:	787000ef          	jal	ffffffffc02060f8 <wakeup_proc>
    ret = proc->pid;
ffffffffc0205176:	40c8                	lw	a0,4(s1)
ffffffffc0205178:	7446                	ld	s0,112(sp)
ffffffffc020517a:	74a6                	ld	s1,104(sp)
ffffffffc020517c:	69e6                	ld	s3,88(sp)
ffffffffc020517e:	6a46                	ld	s4,80(sp)
ffffffffc0205180:	6aa6                	ld	s5,72(sp)
ffffffffc0205182:	6b06                	ld	s6,64(sp)
ffffffffc0205184:	7be2                	ld	s7,56(sp)
ffffffffc0205186:	7c42                	ld	s8,48(sp)
ffffffffc0205188:	7d02                	ld	s10,32(sp)
ffffffffc020518a:	6de2                	ld	s11,24(sp)
}
ffffffffc020518c:	70e6                	ld	ra,120(sp)
ffffffffc020518e:	7906                	ld	s2,96(sp)
ffffffffc0205190:	6109                	addi	sp,sp,128
ffffffffc0205192:	8082                	ret
        last_pid = 1;
ffffffffc0205194:	4785                	li	a5,1
ffffffffc0205196:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020519a:	4505                	li	a0,1
ffffffffc020519c:	0008d317          	auipc	t1,0x8d
ffffffffc02051a0:	61430313          	addi	t1,t1,1556 # ffffffffc02927b0 <next_safe.0>
    return listelm->next;
ffffffffc02051a4:	00099417          	auipc	s0,0x99
ffffffffc02051a8:	acc40413          	addi	s0,s0,-1332 # ffffffffc029dc70 <proc_list>
ffffffffc02051ac:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02051b0:	6789                	lui	a5,0x2
ffffffffc02051b2:	00f32023          	sw	a5,0(t1)
ffffffffc02051b6:	86aa                	mv	a3,a0
ffffffffc02051b8:	4581                	li	a1,0
        while ((le = list_next(le)) != list) {
ffffffffc02051ba:	028e0e63          	beq	t3,s0,ffffffffc02051f6 <do_fork+0x24c>
ffffffffc02051be:	88ae                	mv	a7,a1
ffffffffc02051c0:	87f2                	mv	a5,t3
ffffffffc02051c2:	6609                	lui	a2,0x2
ffffffffc02051c4:	a811                	j	ffffffffc02051d8 <do_fork+0x22e>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc02051c6:	00e6d663          	bge	a3,a4,ffffffffc02051d2 <do_fork+0x228>
ffffffffc02051ca:	00c75463          	bge	a4,a2,ffffffffc02051d2 <do_fork+0x228>
                next_safe = proc->pid;
ffffffffc02051ce:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc02051d0:	4885                	li	a7,1
ffffffffc02051d2:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc02051d4:	00878d63          	beq	a5,s0,ffffffffc02051ee <do_fork+0x244>
            if (proc->pid == last_pid) {
ffffffffc02051d8:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x66d4>
ffffffffc02051dc:	fed715e3          	bne	a4,a3,ffffffffc02051c6 <do_fork+0x21c>
                if (++ last_pid >= next_safe) {
ffffffffc02051e0:	2685                	addiw	a3,a3,1
ffffffffc02051e2:	12c6da63          	bge	a3,a2,ffffffffc0205316 <do_fork+0x36c>
ffffffffc02051e6:	679c                	ld	a5,8(a5)
ffffffffc02051e8:	4585                	li	a1,1
        while ((le = list_next(le)) != list) {
ffffffffc02051ea:	fe8797e3          	bne	a5,s0,ffffffffc02051d8 <do_fork+0x22e>
ffffffffc02051ee:	00088463          	beqz	a7,ffffffffc02051f6 <do_fork+0x24c>
ffffffffc02051f2:	00c32023          	sw	a2,0(t1)
ffffffffc02051f6:	d18d                	beqz	a1,ffffffffc0205118 <do_fork+0x16e>
ffffffffc02051f8:	00d82023          	sw	a3,0(a6)
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc02051fc:	8536                	mv	a0,a3
ffffffffc02051fe:	bf29                	j	ffffffffc0205118 <do_fork+0x16e>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp;
ffffffffc0205200:	6989                	lui	s3,0x2
ffffffffc0205202:	edc98993          	addi	s3,s3,-292 # 1edc <_binary_obj___user_softint_out_size-0x6734>
ffffffffc0205206:	99ba                	add	s3,s3,a4
ffffffffc0205208:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020520c:	00000797          	auipc	a5,0x0
ffffffffc0205210:	c3078793          	addi	a5,a5,-976 # ffffffffc0204e3c <forkret>
ffffffffc0205214:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0205216:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205218:	100027f3          	csrr	a5,sstatus
ffffffffc020521c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020521e:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205220:	ec0783e3          	beqz	a5,ffffffffc02050e6 <do_fork+0x13c>
        intr_disable();
ffffffffc0205224:	c1cfb0ef          	jal	ffffffffc0200640 <intr_disable>
        return 1;
ffffffffc0205228:	4985                	li	s3,1
ffffffffc020522a:	bd75                	j	ffffffffc02050e6 <do_fork+0x13c>
ffffffffc020522c:	f466                	sd	s9,40(sp)
    if ((mm = mm_create()) == NULL) {
ffffffffc020522e:	ee9fe0ef          	jal	ffffffffc0204116 <mm_create>
ffffffffc0205232:	8caa                	mv	s9,a0
ffffffffc0205234:	c949                	beqz	a0,ffffffffc02052c6 <do_fork+0x31c>
    if ((page = alloc_page()) == NULL) {
ffffffffc0205236:	4505                	li	a0,1
ffffffffc0205238:	a69fc0ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc020523c:	c151                	beqz	a0,ffffffffc02052c0 <do_fork+0x316>
    return page - pages + nbase;
ffffffffc020523e:	000ab683          	ld	a3,0(s5)
ffffffffc0205242:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc0205244:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0205248:	40d506b3          	sub	a3,a0,a3
ffffffffc020524c:	8699                	srai	a3,a3,0x6
ffffffffc020524e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205250:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0205254:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205256:	10edfe63          	bgeu	s11,a4,ffffffffc0205372 <do_fork+0x3c8>
ffffffffc020525a:	000c3783          	ld	a5,0(s8)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc020525e:	6605                	lui	a2,0x1
ffffffffc0205260:	00099597          	auipc	a1,0x99
ffffffffc0205264:	a505b583          	ld	a1,-1456(a1) # ffffffffc029dcb0 <boot_pgdir>
ffffffffc0205268:	00f68a33          	add	s4,a3,a5
ffffffffc020526c:	8552                	mv	a0,s4
ffffffffc020526e:	536010ef          	jal	ffffffffc02067a4 <memcpy>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc0205272:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0205276:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020527a:	4785                	li	a5,1
ffffffffc020527c:	40fdb7af          	amoor.d	a5,a5,(s11)
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc0205280:	8b85                	andi	a5,a5,1
ffffffffc0205282:	4a05                	li	s4,1
ffffffffc0205284:	c799                	beqz	a5,ffffffffc0205292 <do_fork+0x2e8>
        schedule();
ffffffffc0205286:	70d000ef          	jal	ffffffffc0206192 <schedule>
ffffffffc020528a:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock)) {
ffffffffc020528e:	8b85                	andi	a5,a5,1
ffffffffc0205290:	fbfd                	bnez	a5,ffffffffc0205286 <do_fork+0x2dc>
        ret = dup_mmap(mm, oldmm);
ffffffffc0205292:	85ea                	mv	a1,s10
ffffffffc0205294:	8566                	mv	a0,s9
ffffffffc0205296:	926ff0ef          	jal	ffffffffc02043bc <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020529a:	57f9                	li	a5,-2
ffffffffc020529c:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc02052a0:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc02052a2:	0e078463          	beqz	a5,ffffffffc020538a <do_fork+0x3e0>
    if ((mm = mm_create()) == NULL) {
ffffffffc02052a6:	8d66                	mv	s10,s9
    if (ret != 0) {
ffffffffc02052a8:	e511                	bnez	a0,ffffffffc02052b4 <do_fork+0x30a>
ffffffffc02052aa:	7ca2                	ld	s9,40(sp)
ffffffffc02052ac:	bb75                	j	ffffffffc0205068 <do_fork+0xbe>
        intr_enable();
ffffffffc02052ae:	b8cfb0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc02052b2:	bd7d                	j	ffffffffc0205170 <do_fork+0x1c6>
    exit_mmap(mm);
ffffffffc02052b4:	8566                	mv	a0,s9
ffffffffc02052b6:	99eff0ef          	jal	ffffffffc0204454 <exit_mmap>
    put_pgdir(mm);
ffffffffc02052ba:	8566                	mv	a0,s9
ffffffffc02052bc:	c0dff0ef          	jal	ffffffffc0204ec8 <put_pgdir>
    mm_destroy(mm);
ffffffffc02052c0:	8566                	mv	a0,s9
ffffffffc02052c2:	fdbfe0ef          	jal	ffffffffc020429c <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02052c6:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc02052c8:	c02007b7          	lui	a5,0xc0200
ffffffffc02052cc:	10f6e163          	bltu	a3,a5,ffffffffc02053ce <do_fork+0x424>
ffffffffc02052d0:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage) {
ffffffffc02052d4:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02052d8:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc02052dc:	83b1                	srli	a5,a5,0xc
ffffffffc02052de:	04e7f463          	bgeu	a5,a4,ffffffffc0205326 <do_fork+0x37c>
    return &pages[PPN(pa) - nbase];
ffffffffc02052e2:	000b3703          	ld	a4,0(s6)
ffffffffc02052e6:	000ab503          	ld	a0,0(s5)
ffffffffc02052ea:	4589                	li	a1,2
ffffffffc02052ec:	8f99                	sub	a5,a5,a4
ffffffffc02052ee:	079a                	slli	a5,a5,0x6
ffffffffc02052f0:	953e                	add	a0,a0,a5
ffffffffc02052f2:	a3ffc0ef          	jal	ffffffffc0201d30 <free_pages>
}
ffffffffc02052f6:	6aa6                	ld	s5,72(sp)
ffffffffc02052f8:	6b06                	ld	s6,64(sp)
ffffffffc02052fa:	7be2                	ld	s7,56(sp)
ffffffffc02052fc:	7ca2                	ld	s9,40(sp)
ffffffffc02052fe:	7d02                	ld	s10,32(sp)
ffffffffc0205300:	6de2                	ld	s11,24(sp)
    kfree(proc);
ffffffffc0205302:	8526                	mv	a0,s1
ffffffffc0205304:	86ffc0ef          	jal	ffffffffc0201b72 <kfree>
ffffffffc0205308:	7c42                	ld	s8,48(sp)
ffffffffc020530a:	7446                	ld	s0,112(sp)
ffffffffc020530c:	74a6                	ld	s1,104(sp)
ffffffffc020530e:	69e6                	ld	s3,88(sp)
ffffffffc0205310:	6a46                	ld	s4,80(sp)
    ret = -E_NO_MEM;
ffffffffc0205312:	5571                	li	a0,-4
    return ret;
ffffffffc0205314:	bda5                	j	ffffffffc020518c <do_fork+0x1e2>
                    if (last_pid >= MAX_PID) {
ffffffffc0205316:	6789                	lui	a5,0x2
ffffffffc0205318:	00f6c363          	blt	a3,a5,ffffffffc020531e <do_fork+0x374>
                        last_pid = 1;
ffffffffc020531c:	4685                	li	a3,1
                    goto repeat;
ffffffffc020531e:	4585                	li	a1,1
ffffffffc0205320:	bd69                	j	ffffffffc02051ba <do_fork+0x210>
    int ret = -E_NO_FREE_PROC;
ffffffffc0205322:	556d                	li	a0,-5
ffffffffc0205324:	b5a5                	j	ffffffffc020518c <do_fork+0x1e2>
        panic("pa2page called with invalid pa");
ffffffffc0205326:	00002617          	auipc	a2,0x2
ffffffffc020532a:	20a60613          	addi	a2,a2,522 # ffffffffc0207530 <etext+0xd74>
ffffffffc020532e:	06200593          	li	a1,98
ffffffffc0205332:	00002517          	auipc	a0,0x2
ffffffffc0205336:	15650513          	addi	a0,a0,342 # ffffffffc0207488 <etext+0xccc>
ffffffffc020533a:	93afb0ef          	jal	ffffffffc0200474 <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020533e:	00002617          	auipc	a2,0x2
ffffffffc0205342:	1ca60613          	addi	a2,a2,458 # ffffffffc0207508 <etext+0xd4c>
ffffffffc0205346:	16700593          	li	a1,359
ffffffffc020534a:	00003517          	auipc	a0,0x3
ffffffffc020534e:	1be50513          	addi	a0,a0,446 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205352:	f466                	sd	s9,40(sp)
ffffffffc0205354:	920fb0ef          	jal	ffffffffc0200474 <__panic>
    return KADDR(page2pa(page));
ffffffffc0205358:	00002617          	auipc	a2,0x2
ffffffffc020535c:	10860613          	addi	a2,a2,264 # ffffffffc0207460 <etext+0xca4>
ffffffffc0205360:	06900593          	li	a1,105
ffffffffc0205364:	00002517          	auipc	a0,0x2
ffffffffc0205368:	12450513          	addi	a0,a0,292 # ffffffffc0207488 <etext+0xccc>
ffffffffc020536c:	f466                	sd	s9,40(sp)
ffffffffc020536e:	906fb0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc0205372:	00002617          	auipc	a2,0x2
ffffffffc0205376:	0ee60613          	addi	a2,a2,238 # ffffffffc0207460 <etext+0xca4>
ffffffffc020537a:	06900593          	li	a1,105
ffffffffc020537e:	00002517          	auipc	a0,0x2
ffffffffc0205382:	10a50513          	addi	a0,a0,266 # ffffffffc0207488 <etext+0xccc>
ffffffffc0205386:	8eefb0ef          	jal	ffffffffc0200474 <__panic>
        panic("Unlock failed.\n");
ffffffffc020538a:	00003617          	auipc	a2,0x3
ffffffffc020538e:	1b660613          	addi	a2,a2,438 # ffffffffc0208540 <etext+0x1d84>
ffffffffc0205392:	03100593          	li	a1,49
ffffffffc0205396:	00003517          	auipc	a0,0x3
ffffffffc020539a:	1ba50513          	addi	a0,a0,442 # ffffffffc0208550 <etext+0x1d94>
ffffffffc020539e:	8d6fb0ef          	jal	ffffffffc0200474 <__panic>
    assert(current->wait_state == 0);
ffffffffc02053a2:	00003697          	auipc	a3,0x3
ffffffffc02053a6:	17e68693          	addi	a3,a3,382 # ffffffffc0208520 <etext+0x1d64>
ffffffffc02053aa:	00002617          	auipc	a2,0x2
ffffffffc02053ae:	a8e60613          	addi	a2,a2,-1394 # ffffffffc0206e38 <etext+0x67c>
ffffffffc02053b2:	1b500593          	li	a1,437
ffffffffc02053b6:	00003517          	auipc	a0,0x3
ffffffffc02053ba:	15250513          	addi	a0,a0,338 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc02053be:	e4d6                	sd	s5,72(sp)
ffffffffc02053c0:	e0da                	sd	s6,64(sp)
ffffffffc02053c2:	fc5e                	sd	s7,56(sp)
ffffffffc02053c4:	f466                	sd	s9,40(sp)
ffffffffc02053c6:	f06a                	sd	s10,32(sp)
ffffffffc02053c8:	ec6e                	sd	s11,24(sp)
ffffffffc02053ca:	8aafb0ef          	jal	ffffffffc0200474 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02053ce:	00002617          	auipc	a2,0x2
ffffffffc02053d2:	13a60613          	addi	a2,a2,314 # ffffffffc0207508 <etext+0xd4c>
ffffffffc02053d6:	06e00593          	li	a1,110
ffffffffc02053da:	00002517          	auipc	a0,0x2
ffffffffc02053de:	0ae50513          	addi	a0,a0,174 # ffffffffc0207488 <etext+0xccc>
ffffffffc02053e2:	892fb0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02053e6 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02053e6:	7129                	addi	sp,sp,-320
ffffffffc02053e8:	fa22                	sd	s0,304(sp)
ffffffffc02053ea:	f626                	sd	s1,296(sp)
ffffffffc02053ec:	f24a                	sd	s2,288(sp)
ffffffffc02053ee:	84ae                	mv	s1,a1
ffffffffc02053f0:	892a                	mv	s2,a0
ffffffffc02053f2:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02053f4:	4581                	li	a1,0
ffffffffc02053f6:	12000613          	li	a2,288
ffffffffc02053fa:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02053fc:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02053fe:	394010ef          	jal	ffffffffc0206792 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0205402:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0205404:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0205406:	100027f3          	csrr	a5,sstatus
ffffffffc020540a:	edd7f793          	andi	a5,a5,-291
ffffffffc020540e:	1207e793          	ori	a5,a5,288
ffffffffc0205412:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205414:	860a                	mv	a2,sp
ffffffffc0205416:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020541a:	00000797          	auipc	a5,0x0
ffffffffc020541e:	9a878793          	addi	a5,a5,-1624 # ffffffffc0204dc2 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205422:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0205424:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205426:	b85ff0ef          	jal	ffffffffc0204faa <do_fork>
}
ffffffffc020542a:	70f2                	ld	ra,312(sp)
ffffffffc020542c:	7452                	ld	s0,304(sp)
ffffffffc020542e:	74b2                	ld	s1,296(sp)
ffffffffc0205430:	7912                	ld	s2,288(sp)
ffffffffc0205432:	6131                	addi	sp,sp,320
ffffffffc0205434:	8082                	ret

ffffffffc0205436 <do_exit>:
do_exit(int error_code) {
ffffffffc0205436:	7179                	addi	sp,sp,-48
ffffffffc0205438:	f022                	sd	s0,32(sp)
    if (current == idleproc) {
ffffffffc020543a:	00099417          	auipc	s0,0x99
ffffffffc020543e:	8c640413          	addi	s0,s0,-1850 # ffffffffc029dd00 <current>
ffffffffc0205442:	601c                	ld	a5,0(s0)
do_exit(int error_code) {
ffffffffc0205444:	f406                	sd	ra,40(sp)
    if (current == idleproc) {
ffffffffc0205446:	00099717          	auipc	a4,0x99
ffffffffc020544a:	8ca73703          	ld	a4,-1846(a4) # ffffffffc029dd10 <idleproc>
ffffffffc020544e:	ec26                	sd	s1,24(sp)
ffffffffc0205450:	0ce78f63          	beq	a5,a4,ffffffffc020552e <do_exit+0xf8>
    if (current == initproc) {
ffffffffc0205454:	00099497          	auipc	s1,0x99
ffffffffc0205458:	8b448493          	addi	s1,s1,-1868 # ffffffffc029dd08 <initproc>
ffffffffc020545c:	6098                	ld	a4,0(s1)
ffffffffc020545e:	e84a                	sd	s2,16(sp)
ffffffffc0205460:	e44e                	sd	s3,8(sp)
ffffffffc0205462:	e052                	sd	s4,0(sp)
ffffffffc0205464:	0ee78e63          	beq	a5,a4,ffffffffc0205560 <do_exit+0x12a>
    struct mm_struct *mm = current->mm;
ffffffffc0205468:	0287b983          	ld	s3,40(a5)
ffffffffc020546c:	892a                	mv	s2,a0
    if (mm != NULL) {
ffffffffc020546e:	02098663          	beqz	s3,ffffffffc020549a <do_exit+0x64>
ffffffffc0205472:	00099797          	auipc	a5,0x99
ffffffffc0205476:	8367b783          	ld	a5,-1994(a5) # ffffffffc029dca8 <boot_cr3>
ffffffffc020547a:	577d                	li	a4,-1
ffffffffc020547c:	177e                	slli	a4,a4,0x3f
ffffffffc020547e:	83b1                	srli	a5,a5,0xc
ffffffffc0205480:	8fd9                	or	a5,a5,a4
ffffffffc0205482:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0205486:	0309a783          	lw	a5,48(s3)
ffffffffc020548a:	fff7871b          	addiw	a4,a5,-1
ffffffffc020548e:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205492:	cf4d                	beqz	a4,ffffffffc020554c <do_exit+0x116>
        current->mm = NULL;
ffffffffc0205494:	601c                	ld	a5,0(s0)
ffffffffc0205496:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020549a:	601c                	ld	a5,0(s0)
ffffffffc020549c:	470d                	li	a4,3
ffffffffc020549e:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02054a0:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02054a4:	100027f3          	csrr	a5,sstatus
ffffffffc02054a8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02054aa:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02054ac:	e7f1                	bnez	a5,ffffffffc0205578 <do_exit+0x142>
        proc = current->parent;
ffffffffc02054ae:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD) {
ffffffffc02054b0:	800007b7          	lui	a5,0x80000
ffffffffc02054b4:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff6499>
        proc = current->parent;
ffffffffc02054b6:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc02054b8:	0ec52703          	lw	a4,236(a0)
ffffffffc02054bc:	0cf70263          	beq	a4,a5,ffffffffc0205580 <do_exit+0x14a>
        while (current->cptr != NULL) {
ffffffffc02054c0:	6018                	ld	a4,0(s0)
ffffffffc02054c2:	7b7c                	ld	a5,240(a4)
ffffffffc02054c4:	c3a1                	beqz	a5,ffffffffc0205504 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02054c6:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02054ca:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02054cc:	0985                	addi	s3,s3,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff6499>
ffffffffc02054ce:	a021                	j	ffffffffc02054d6 <do_exit+0xa0>
        while (current->cptr != NULL) {
ffffffffc02054d0:	6018                	ld	a4,0(s0)
ffffffffc02054d2:	7b7c                	ld	a5,240(a4)
ffffffffc02054d4:	cb85                	beqz	a5,ffffffffc0205504 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02054d6:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02054da:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02054dc:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02054de:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02054e0:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02054e4:	10e7b023          	sd	a4,256(a5)
ffffffffc02054e8:	c311                	beqz	a4,ffffffffc02054ec <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02054ea:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02054ec:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02054ee:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02054f0:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02054f2:	fd271fe3          	bne	a4,s2,ffffffffc02054d0 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02054f6:	0ec52783          	lw	a5,236(a0)
ffffffffc02054fa:	fd379be3          	bne	a5,s3,ffffffffc02054d0 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc02054fe:	3fb000ef          	jal	ffffffffc02060f8 <wakeup_proc>
ffffffffc0205502:	b7f9                	j	ffffffffc02054d0 <do_exit+0x9a>
    if (flag) {
ffffffffc0205504:	020a1263          	bnez	s4,ffffffffc0205528 <do_exit+0xf2>
    schedule();
ffffffffc0205508:	48b000ef          	jal	ffffffffc0206192 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020550c:	601c                	ld	a5,0(s0)
ffffffffc020550e:	00003617          	auipc	a2,0x3
ffffffffc0205512:	07a60613          	addi	a2,a2,122 # ffffffffc0208588 <etext+0x1dcc>
ffffffffc0205516:	20800593          	li	a1,520
ffffffffc020551a:	43d4                	lw	a3,4(a5)
ffffffffc020551c:	00003517          	auipc	a0,0x3
ffffffffc0205520:	fec50513          	addi	a0,a0,-20 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205524:	f51fa0ef          	jal	ffffffffc0200474 <__panic>
        intr_enable();
ffffffffc0205528:	912fb0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc020552c:	bff1                	j	ffffffffc0205508 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc020552e:	00003617          	auipc	a2,0x3
ffffffffc0205532:	03a60613          	addi	a2,a2,58 # ffffffffc0208568 <etext+0x1dac>
ffffffffc0205536:	1dc00593          	li	a1,476
ffffffffc020553a:	00003517          	auipc	a0,0x3
ffffffffc020553e:	fce50513          	addi	a0,a0,-50 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205542:	e84a                	sd	s2,16(sp)
ffffffffc0205544:	e44e                	sd	s3,8(sp)
ffffffffc0205546:	e052                	sd	s4,0(sp)
ffffffffc0205548:	f2dfa0ef          	jal	ffffffffc0200474 <__panic>
            exit_mmap(mm);
ffffffffc020554c:	854e                	mv	a0,s3
ffffffffc020554e:	f07fe0ef          	jal	ffffffffc0204454 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205552:	854e                	mv	a0,s3
ffffffffc0205554:	975ff0ef          	jal	ffffffffc0204ec8 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205558:	854e                	mv	a0,s3
ffffffffc020555a:	d43fe0ef          	jal	ffffffffc020429c <mm_destroy>
ffffffffc020555e:	bf1d                	j	ffffffffc0205494 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0205560:	00003617          	auipc	a2,0x3
ffffffffc0205564:	01860613          	addi	a2,a2,24 # ffffffffc0208578 <etext+0x1dbc>
ffffffffc0205568:	1df00593          	li	a1,479
ffffffffc020556c:	00003517          	auipc	a0,0x3
ffffffffc0205570:	f9c50513          	addi	a0,a0,-100 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205574:	f01fa0ef          	jal	ffffffffc0200474 <__panic>
        intr_disable();
ffffffffc0205578:	8c8fb0ef          	jal	ffffffffc0200640 <intr_disable>
        return 1;
ffffffffc020557c:	4a05                	li	s4,1
ffffffffc020557e:	bf05                	j	ffffffffc02054ae <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0205580:	379000ef          	jal	ffffffffc02060f8 <wakeup_proc>
ffffffffc0205584:	bf35                	j	ffffffffc02054c0 <do_exit+0x8a>

ffffffffc0205586 <do_wait.part.0>:
do_wait(int pid, int *code_store) {
ffffffffc0205586:	7179                	addi	sp,sp,-48
ffffffffc0205588:	ec26                	sd	s1,24(sp)
ffffffffc020558a:	e84a                	sd	s2,16(sp)
ffffffffc020558c:	e44e                	sd	s3,8(sp)
ffffffffc020558e:	f406                	sd	ra,40(sp)
ffffffffc0205590:	f022                	sd	s0,32(sp)
ffffffffc0205592:	84aa                	mv	s1,a0
ffffffffc0205594:	892e                	mv	s2,a1
ffffffffc0205596:	00098997          	auipc	s3,0x98
ffffffffc020559a:	76a98993          	addi	s3,s3,1898 # ffffffffc029dd00 <current>
    if (pid != 0) {
ffffffffc020559e:	c105                	beqz	a0,ffffffffc02055be <do_wait.part.0+0x38>
    if (0 < pid && pid < MAX_PID) {
ffffffffc02055a0:	6789                	lui	a5,0x2
ffffffffc02055a2:	fff5071b          	addiw	a4,a0,-1
ffffffffc02055a6:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6612>
ffffffffc02055a8:	2501                	sext.w	a0,a0
ffffffffc02055aa:	12e7f363          	bgeu	a5,a4,ffffffffc02056d0 <do_wait.part.0+0x14a>
    return -E_BAD_PROC;
ffffffffc02055ae:	5579                	li	a0,-2
}
ffffffffc02055b0:	70a2                	ld	ra,40(sp)
ffffffffc02055b2:	7402                	ld	s0,32(sp)
ffffffffc02055b4:	64e2                	ld	s1,24(sp)
ffffffffc02055b6:	6942                	ld	s2,16(sp)
ffffffffc02055b8:	69a2                	ld	s3,8(sp)
ffffffffc02055ba:	6145                	addi	sp,sp,48
ffffffffc02055bc:	8082                	ret
        proc = current->cptr;
ffffffffc02055be:	0009b683          	ld	a3,0(s3)
ffffffffc02055c2:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc02055c4:	d46d                	beqz	s0,ffffffffc02055ae <do_wait.part.0+0x28>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02055c6:	470d                	li	a4,3
ffffffffc02055c8:	a021                	j	ffffffffc02055d0 <do_wait.part.0+0x4a>
        for (; proc != NULL; proc = proc->optr) {
ffffffffc02055ca:	10043403          	ld	s0,256(s0)
ffffffffc02055ce:	cc71                	beqz	s0,ffffffffc02056aa <do_wait.part.0+0x124>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02055d0:	401c                	lw	a5,0(s0)
ffffffffc02055d2:	fee79ce3          	bne	a5,a4,ffffffffc02055ca <do_wait.part.0+0x44>
    if (proc == idleproc || proc == initproc) {
ffffffffc02055d6:	00098797          	auipc	a5,0x98
ffffffffc02055da:	73a7b783          	ld	a5,1850(a5) # ffffffffc029dd10 <idleproc>
ffffffffc02055de:	14878c63          	beq	a5,s0,ffffffffc0205736 <do_wait.part.0+0x1b0>
ffffffffc02055e2:	00098797          	auipc	a5,0x98
ffffffffc02055e6:	7267b783          	ld	a5,1830(a5) # ffffffffc029dd08 <initproc>
ffffffffc02055ea:	14f40663          	beq	s0,a5,ffffffffc0205736 <do_wait.part.0+0x1b0>
    if (code_store != NULL) {
ffffffffc02055ee:	00090663          	beqz	s2,ffffffffc02055fa <do_wait.part.0+0x74>
        *code_store = proc->exit_code;
ffffffffc02055f2:	0e842783          	lw	a5,232(s0)
ffffffffc02055f6:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02055fa:	100027f3          	csrr	a5,sstatus
ffffffffc02055fe:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205600:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205602:	10079463          	bnez	a5,ffffffffc020570a <do_wait.part.0+0x184>
    __list_del(listelm->prev, listelm->next);
ffffffffc0205606:	6c74                	ld	a3,216(s0)
ffffffffc0205608:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL) {
ffffffffc020560a:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc020560e:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0205610:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0205612:	6474                	ld	a3,200(s0)
ffffffffc0205614:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc0205616:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0205618:	e314                	sd	a3,0(a4)
ffffffffc020561a:	c399                	beqz	a5,ffffffffc0205620 <do_wait.part.0+0x9a>
        proc->optr->yptr = proc->yptr;
ffffffffc020561c:	7c78                	ld	a4,248(s0)
ffffffffc020561e:	fff8                	sd	a4,248(a5)
    if (proc->yptr != NULL) {
ffffffffc0205620:	7c78                	ld	a4,248(s0)
ffffffffc0205622:	c36d                	beqz	a4,ffffffffc0205704 <do_wait.part.0+0x17e>
        proc->yptr->optr = proc->optr;
ffffffffc0205624:	10f73023          	sd	a5,256(a4)
    nr_process --;
ffffffffc0205628:	00098717          	auipc	a4,0x98
ffffffffc020562c:	6d070713          	addi	a4,a4,1744 # ffffffffc029dcf8 <nr_process>
ffffffffc0205630:	431c                	lw	a5,0(a4)
ffffffffc0205632:	37fd                	addiw	a5,a5,-1
ffffffffc0205634:	c31c                	sw	a5,0(a4)
    if (flag) {
ffffffffc0205636:	e661                	bnez	a2,ffffffffc02056fe <do_wait.part.0+0x178>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0205638:	6814                	ld	a3,16(s0)
ffffffffc020563a:	c02007b7          	lui	a5,0xc0200
ffffffffc020563e:	0ef6e063          	bltu	a3,a5,ffffffffc020571e <do_wait.part.0+0x198>
ffffffffc0205642:	00098797          	auipc	a5,0x98
ffffffffc0205646:	6767b783          	ld	a5,1654(a5) # ffffffffc029dcb8 <va_pa_offset>
ffffffffc020564a:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc020564c:	82b1                	srli	a3,a3,0xc
ffffffffc020564e:	00098797          	auipc	a5,0x98
ffffffffc0205652:	6727b783          	ld	a5,1650(a5) # ffffffffc029dcc0 <npage>
ffffffffc0205656:	0ef6fc63          	bgeu	a3,a5,ffffffffc020574e <do_wait.part.0+0x1c8>
    return &pages[PPN(pa) - nbase];
ffffffffc020565a:	00004797          	auipc	a5,0x4
ffffffffc020565e:	8567b783          	ld	a5,-1962(a5) # ffffffffc0208eb0 <nbase>
ffffffffc0205662:	8e9d                	sub	a3,a3,a5
ffffffffc0205664:	069a                	slli	a3,a3,0x6
ffffffffc0205666:	00098517          	auipc	a0,0x98
ffffffffc020566a:	66253503          	ld	a0,1634(a0) # ffffffffc029dcc8 <pages>
ffffffffc020566e:	9536                	add	a0,a0,a3
ffffffffc0205670:	4589                	li	a1,2
ffffffffc0205672:	ebefc0ef          	jal	ffffffffc0201d30 <free_pages>
    kfree(proc);
ffffffffc0205676:	8522                	mv	a0,s0
ffffffffc0205678:	cfafc0ef          	jal	ffffffffc0201b72 <kfree>
}
ffffffffc020567c:	70a2                	ld	ra,40(sp)
ffffffffc020567e:	7402                	ld	s0,32(sp)
ffffffffc0205680:	64e2                	ld	s1,24(sp)
ffffffffc0205682:	6942                	ld	s2,16(sp)
ffffffffc0205684:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc0205686:	4501                	li	a0,0
}
ffffffffc0205688:	6145                	addi	sp,sp,48
ffffffffc020568a:	8082                	ret
        if (proc != NULL && proc->parent == current) {
ffffffffc020568c:	00098997          	auipc	s3,0x98
ffffffffc0205690:	67498993          	addi	s3,s3,1652 # ffffffffc029dd00 <current>
ffffffffc0205694:	0009b683          	ld	a3,0(s3)
ffffffffc0205698:	f4843783          	ld	a5,-184(s0)
ffffffffc020569c:	f0d799e3          	bne	a5,a3,ffffffffc02055ae <do_wait.part.0+0x28>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02056a0:	f2842703          	lw	a4,-216(s0)
ffffffffc02056a4:	478d                	li	a5,3
ffffffffc02056a6:	06f70663          	beq	a4,a5,ffffffffc0205712 <do_wait.part.0+0x18c>
        current->wait_state = WT_CHILD;
ffffffffc02056aa:	800007b7          	lui	a5,0x80000
ffffffffc02056ae:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff6499>
        current->state = PROC_SLEEPING;
ffffffffc02056b0:	4705                	li	a4,1
        current->wait_state = WT_CHILD;
ffffffffc02056b2:	0ef6a623          	sw	a5,236(a3)
        current->state = PROC_SLEEPING;
ffffffffc02056b6:	c298                	sw	a4,0(a3)
        schedule();
ffffffffc02056b8:	2db000ef          	jal	ffffffffc0206192 <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc02056bc:	0009b783          	ld	a5,0(s3)
ffffffffc02056c0:	0b07a783          	lw	a5,176(a5)
ffffffffc02056c4:	8b85                	andi	a5,a5,1
ffffffffc02056c6:	eba9                	bnez	a5,ffffffffc0205718 <do_wait.part.0+0x192>
    if (0 < pid && pid < MAX_PID) {
ffffffffc02056c8:	0004851b          	sext.w	a0,s1
    if (pid != 0) {
ffffffffc02056cc:	ee0489e3          	beqz	s1,ffffffffc02055be <do_wait.part.0+0x38>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02056d0:	45a9                	li	a1,10
ffffffffc02056d2:	42d000ef          	jal	ffffffffc02062fe <hash32>
ffffffffc02056d6:	02051793          	slli	a5,a0,0x20
ffffffffc02056da:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02056de:	00094797          	auipc	a5,0x94
ffffffffc02056e2:	59278793          	addi	a5,a5,1426 # ffffffffc0299c70 <hash_list>
ffffffffc02056e6:	953e                	add	a0,a0,a5
ffffffffc02056e8:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list) {
ffffffffc02056ea:	a029                	j	ffffffffc02056f4 <do_wait.part.0+0x16e>
            if (proc->pid == pid) {
ffffffffc02056ec:	f2c42783          	lw	a5,-212(s0)
ffffffffc02056f0:	f8978ee3          	beq	a5,s1,ffffffffc020568c <do_wait.part.0+0x106>
    return listelm->next;
ffffffffc02056f4:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list) {
ffffffffc02056f6:	fe851be3          	bne	a0,s0,ffffffffc02056ec <do_wait.part.0+0x166>
    return -E_BAD_PROC;
ffffffffc02056fa:	5579                	li	a0,-2
ffffffffc02056fc:	bd55                	j	ffffffffc02055b0 <do_wait.part.0+0x2a>
        intr_enable();
ffffffffc02056fe:	f3dfa0ef          	jal	ffffffffc020063a <intr_enable>
ffffffffc0205702:	bf1d                	j	ffffffffc0205638 <do_wait.part.0+0xb2>
       proc->parent->cptr = proc->optr;
ffffffffc0205704:	7018                	ld	a4,32(s0)
ffffffffc0205706:	fb7c                	sd	a5,240(a4)
ffffffffc0205708:	b705                	j	ffffffffc0205628 <do_wait.part.0+0xa2>
        intr_disable();
ffffffffc020570a:	f37fa0ef          	jal	ffffffffc0200640 <intr_disable>
        return 1;
ffffffffc020570e:	4605                	li	a2,1
ffffffffc0205710:	bddd                	j	ffffffffc0205606 <do_wait.part.0+0x80>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205712:	f2840413          	addi	s0,s0,-216
ffffffffc0205716:	b5c1                	j	ffffffffc02055d6 <do_wait.part.0+0x50>
            do_exit(-E_KILLED);
ffffffffc0205718:	555d                	li	a0,-9
ffffffffc020571a:	d1dff0ef          	jal	ffffffffc0205436 <do_exit>
    return pa2page(PADDR(kva));
ffffffffc020571e:	00002617          	auipc	a2,0x2
ffffffffc0205722:	dea60613          	addi	a2,a2,-534 # ffffffffc0207508 <etext+0xd4c>
ffffffffc0205726:	06e00593          	li	a1,110
ffffffffc020572a:	00002517          	auipc	a0,0x2
ffffffffc020572e:	d5e50513          	addi	a0,a0,-674 # ffffffffc0207488 <etext+0xccc>
ffffffffc0205732:	d43fa0ef          	jal	ffffffffc0200474 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0205736:	00003617          	auipc	a2,0x3
ffffffffc020573a:	e7260613          	addi	a2,a2,-398 # ffffffffc02085a8 <etext+0x1dec>
ffffffffc020573e:	30300593          	li	a1,771
ffffffffc0205742:	00003517          	auipc	a0,0x3
ffffffffc0205746:	dc650513          	addi	a0,a0,-570 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc020574a:	d2bfa0ef          	jal	ffffffffc0200474 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020574e:	00002617          	auipc	a2,0x2
ffffffffc0205752:	de260613          	addi	a2,a2,-542 # ffffffffc0207530 <etext+0xd74>
ffffffffc0205756:	06200593          	li	a1,98
ffffffffc020575a:	00002517          	auipc	a0,0x2
ffffffffc020575e:	d2e50513          	addi	a0,a0,-722 # ffffffffc0207488 <etext+0xccc>
ffffffffc0205762:	d13fa0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0205766 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc0205766:	1141                	addi	sp,sp,-16
ffffffffc0205768:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020576a:	e06fc0ef          	jal	ffffffffc0201d70 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020576e:	b56fc0ef          	jal	ffffffffc0201ac4 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0205772:	4601                	li	a2,0
ffffffffc0205774:	4581                	li	a1,0
ffffffffc0205776:	fffff517          	auipc	a0,0xfffff
ffffffffc020577a:	6d450513          	addi	a0,a0,1748 # ffffffffc0204e4a <user_main>
ffffffffc020577e:	c69ff0ef          	jal	ffffffffc02053e6 <kernel_thread>
    if (pid <= 0) {
ffffffffc0205782:	00a04563          	bgtz	a0,ffffffffc020578c <init_main+0x26>
ffffffffc0205786:	a071                	j	ffffffffc0205812 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
ffffffffc0205788:	20b000ef          	jal	ffffffffc0206192 <schedule>
    if (code_store != NULL) {
ffffffffc020578c:	4581                	li	a1,0
ffffffffc020578e:	4501                	li	a0,0
ffffffffc0205790:	df7ff0ef          	jal	ffffffffc0205586 <do_wait.part.0>
    while (do_wait(0, NULL) == 0) {
ffffffffc0205794:	d975                	beqz	a0,ffffffffc0205788 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0205796:	00003517          	auipc	a0,0x3
ffffffffc020579a:	e5250513          	addi	a0,a0,-430 # ffffffffc02085e8 <etext+0x1e2c>
ffffffffc020579e:	9e3fa0ef          	jal	ffffffffc0200180 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02057a2:	00098797          	auipc	a5,0x98
ffffffffc02057a6:	5667b783          	ld	a5,1382(a5) # ffffffffc029dd08 <initproc>
ffffffffc02057aa:	7bf8                	ld	a4,240(a5)
ffffffffc02057ac:	e339                	bnez	a4,ffffffffc02057f2 <init_main+0x8c>
ffffffffc02057ae:	7ff8                	ld	a4,248(a5)
ffffffffc02057b0:	e329                	bnez	a4,ffffffffc02057f2 <init_main+0x8c>
ffffffffc02057b2:	1007b703          	ld	a4,256(a5)
ffffffffc02057b6:	ef15                	bnez	a4,ffffffffc02057f2 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02057b8:	00098697          	auipc	a3,0x98
ffffffffc02057bc:	5406a683          	lw	a3,1344(a3) # ffffffffc029dcf8 <nr_process>
ffffffffc02057c0:	4709                	li	a4,2
ffffffffc02057c2:	0ae69463          	bne	a3,a4,ffffffffc020586a <init_main+0x104>
ffffffffc02057c6:	00098697          	auipc	a3,0x98
ffffffffc02057ca:	4aa68693          	addi	a3,a3,1194 # ffffffffc029dc70 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02057ce:	6698                	ld	a4,8(a3)
ffffffffc02057d0:	0c878793          	addi	a5,a5,200
ffffffffc02057d4:	06f71b63          	bne	a4,a5,ffffffffc020584a <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02057d8:	629c                	ld	a5,0(a3)
ffffffffc02057da:	04f71863          	bne	a4,a5,ffffffffc020582a <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02057de:	00003517          	auipc	a0,0x3
ffffffffc02057e2:	ef250513          	addi	a0,a0,-270 # ffffffffc02086d0 <etext+0x1f14>
ffffffffc02057e6:	99bfa0ef          	jal	ffffffffc0200180 <cprintf>
    return 0;
}
ffffffffc02057ea:	60a2                	ld	ra,8(sp)
ffffffffc02057ec:	4501                	li	a0,0
ffffffffc02057ee:	0141                	addi	sp,sp,16
ffffffffc02057f0:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02057f2:	00003697          	auipc	a3,0x3
ffffffffc02057f6:	e1e68693          	addi	a3,a3,-482 # ffffffffc0208610 <etext+0x1e54>
ffffffffc02057fa:	00001617          	auipc	a2,0x1
ffffffffc02057fe:	63e60613          	addi	a2,a2,1598 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0205802:	36800593          	li	a1,872
ffffffffc0205806:	00003517          	auipc	a0,0x3
ffffffffc020580a:	d0250513          	addi	a0,a0,-766 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc020580e:	c67fa0ef          	jal	ffffffffc0200474 <__panic>
        panic("create user_main failed.\n");
ffffffffc0205812:	00003617          	auipc	a2,0x3
ffffffffc0205816:	db660613          	addi	a2,a2,-586 # ffffffffc02085c8 <etext+0x1e0c>
ffffffffc020581a:	36000593          	li	a1,864
ffffffffc020581e:	00003517          	auipc	a0,0x3
ffffffffc0205822:	cea50513          	addi	a0,a0,-790 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205826:	c4ffa0ef          	jal	ffffffffc0200474 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020582a:	00003697          	auipc	a3,0x3
ffffffffc020582e:	e7668693          	addi	a3,a3,-394 # ffffffffc02086a0 <etext+0x1ee4>
ffffffffc0205832:	00001617          	auipc	a2,0x1
ffffffffc0205836:	60660613          	addi	a2,a2,1542 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020583a:	36b00593          	li	a1,875
ffffffffc020583e:	00003517          	auipc	a0,0x3
ffffffffc0205842:	cca50513          	addi	a0,a0,-822 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205846:	c2ffa0ef          	jal	ffffffffc0200474 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020584a:	00003697          	auipc	a3,0x3
ffffffffc020584e:	e2668693          	addi	a3,a3,-474 # ffffffffc0208670 <etext+0x1eb4>
ffffffffc0205852:	00001617          	auipc	a2,0x1
ffffffffc0205856:	5e660613          	addi	a2,a2,1510 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020585a:	36a00593          	li	a1,874
ffffffffc020585e:	00003517          	auipc	a0,0x3
ffffffffc0205862:	caa50513          	addi	a0,a0,-854 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205866:	c0ffa0ef          	jal	ffffffffc0200474 <__panic>
    assert(nr_process == 2);
ffffffffc020586a:	00003697          	auipc	a3,0x3
ffffffffc020586e:	df668693          	addi	a3,a3,-522 # ffffffffc0208660 <etext+0x1ea4>
ffffffffc0205872:	00001617          	auipc	a2,0x1
ffffffffc0205876:	5c660613          	addi	a2,a2,1478 # ffffffffc0206e38 <etext+0x67c>
ffffffffc020587a:	36900593          	li	a1,873
ffffffffc020587e:	00003517          	auipc	a0,0x3
ffffffffc0205882:	c8a50513          	addi	a0,a0,-886 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205886:	beffa0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc020588a <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020588a:	7171                	addi	sp,sp,-176
ffffffffc020588c:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020588e:	00098d97          	auipc	s11,0x98
ffffffffc0205892:	472d8d93          	addi	s11,s11,1138 # ffffffffc029dd00 <current>
ffffffffc0205896:	000db783          	ld	a5,0(s11)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020589a:	e54e                	sd	s3,136(sp)
ffffffffc020589c:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020589e:	0287b983          	ld	s3,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02058a2:	e94a                	sd	s2,144(sp)
ffffffffc02058a4:	fcd6                	sd	s5,120(sp)
ffffffffc02058a6:	892a                	mv	s2,a0
ffffffffc02058a8:	84ae                	mv	s1,a1
ffffffffc02058aa:	8ab2                	mv	s5,a2
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc02058ac:	4681                	li	a3,0
ffffffffc02058ae:	862e                	mv	a2,a1
ffffffffc02058b0:	85aa                	mv	a1,a0
ffffffffc02058b2:	854e                	mv	a0,s3
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02058b4:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc02058b6:	b18ff0ef          	jal	ffffffffc0204bce <user_mem_check>
ffffffffc02058ba:	46050163          	beqz	a0,ffffffffc0205d1c <do_execve+0x492>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02058be:	4641                	li	a2,16
ffffffffc02058c0:	4581                	li	a1,0
ffffffffc02058c2:	1808                	addi	a0,sp,48
ffffffffc02058c4:	6cf000ef          	jal	ffffffffc0206792 <memset>
    if (len > PROC_NAME_LEN) {
ffffffffc02058c8:	47bd                	li	a5,15
ffffffffc02058ca:	8626                	mv	a2,s1
ffffffffc02058cc:	1097e263          	bltu	a5,s1,ffffffffc02059d0 <do_execve+0x146>
    memcpy(local_name, name, len);
ffffffffc02058d0:	85ca                	mv	a1,s2
ffffffffc02058d2:	1808                	addi	a0,sp,48
ffffffffc02058d4:	6d1000ef          	jal	ffffffffc02067a4 <memcpy>
    if (mm != NULL) {
ffffffffc02058d8:	10098363          	beqz	s3,ffffffffc02059de <do_execve+0x154>
        cputs("mm != NULL");
ffffffffc02058dc:	00002517          	auipc	a0,0x2
ffffffffc02058e0:	2e450513          	addi	a0,a0,740 # ffffffffc0207bc0 <etext+0x1404>
ffffffffc02058e4:	8d3fa0ef          	jal	ffffffffc02001b6 <cputs>
ffffffffc02058e8:	00098797          	auipc	a5,0x98
ffffffffc02058ec:	3c07b783          	ld	a5,960(a5) # ffffffffc029dca8 <boot_cr3>
ffffffffc02058f0:	577d                	li	a4,-1
ffffffffc02058f2:	177e                	slli	a4,a4,0x3f
ffffffffc02058f4:	83b1                	srli	a5,a5,0xc
ffffffffc02058f6:	8fd9                	or	a5,a5,a4
ffffffffc02058f8:	18079073          	csrw	satp,a5
ffffffffc02058fc:	0309a783          	lw	a5,48(s3)
ffffffffc0205900:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205904:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205908:	2e070663          	beqz	a4,ffffffffc0205bf4 <do_execve+0x36a>
        current->mm = NULL;
ffffffffc020590c:	000db783          	ld	a5,0(s11)
ffffffffc0205910:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc0205914:	803fe0ef          	jal	ffffffffc0204116 <mm_create>
ffffffffc0205918:	84aa                	mv	s1,a0
ffffffffc020591a:	20050463          	beqz	a0,ffffffffc0205b22 <do_execve+0x298>
    if ((page = alloc_page()) == NULL) {
ffffffffc020591e:	4505                	li	a0,1
ffffffffc0205920:	b80fc0ef          	jal	ffffffffc0201ca0 <alloc_pages>
ffffffffc0205924:	40050063          	beqz	a0,ffffffffc0205d24 <do_execve+0x49a>
    return page - pages + nbase;
ffffffffc0205928:	e8ea                	sd	s10,80(sp)
ffffffffc020592a:	00098d17          	auipc	s10,0x98
ffffffffc020592e:	39ed0d13          	addi	s10,s10,926 # ffffffffc029dcc8 <pages>
ffffffffc0205932:	000d3783          	ld	a5,0(s10)
ffffffffc0205936:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc0205938:	00098c97          	auipc	s9,0x98
ffffffffc020593c:	388c8c93          	addi	s9,s9,904 # ffffffffc029dcc0 <npage>
    return page - pages + nbase;
ffffffffc0205940:	40f506b3          	sub	a3,a0,a5
ffffffffc0205944:	00003717          	auipc	a4,0x3
ffffffffc0205948:	56c73703          	ld	a4,1388(a4) # ffffffffc0208eb0 <nbase>
ffffffffc020594c:	f4de                	sd	s7,104(sp)
ffffffffc020594e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205950:	5bfd                	li	s7,-1
ffffffffc0205952:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc0205956:	96ba                	add	a3,a3,a4
ffffffffc0205958:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc020595a:	00cbd713          	srli	a4,s7,0xc
ffffffffc020595e:	f03a                	sd	a4,32(sp)
ffffffffc0205960:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0205962:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205964:	3ef77363          	bgeu	a4,a5,ffffffffc0205d4a <do_execve+0x4c0>
ffffffffc0205968:	f8da                	sd	s6,112(sp)
ffffffffc020596a:	00098b17          	auipc	s6,0x98
ffffffffc020596e:	34eb0b13          	addi	s6,s6,846 # ffffffffc029dcb8 <va_pa_offset>
ffffffffc0205972:	000b3783          	ld	a5,0(s6)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc0205976:	6605                	lui	a2,0x1
ffffffffc0205978:	00098597          	auipc	a1,0x98
ffffffffc020597c:	3385b583          	ld	a1,824(a1) # ffffffffc029dcb0 <boot_pgdir>
ffffffffc0205980:	00f68933          	add	s2,a3,a5
ffffffffc0205984:	854a                	mv	a0,s2
ffffffffc0205986:	e152                	sd	s4,128(sp)
ffffffffc0205988:	61d000ef          	jal	ffffffffc02067a4 <memcpy>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc020598c:	000aa703          	lw	a4,0(s5)
ffffffffc0205990:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0205994:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc0205998:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464baa17>
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020599c:	020aba03          	ld	s4,32(s5)
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc02059a0:	06f70663          	beq	a4,a5,ffffffffc0205a0c <do_execve+0x182>
        ret = -E_INVAL_ELF;
ffffffffc02059a4:	5961                	li	s2,-8
    put_pgdir(mm);
ffffffffc02059a6:	8526                	mv	a0,s1
ffffffffc02059a8:	d20ff0ef          	jal	ffffffffc0204ec8 <put_pgdir>
ffffffffc02059ac:	6a0a                	ld	s4,128(sp)
ffffffffc02059ae:	7b46                	ld	s6,112(sp)
ffffffffc02059b0:	7ba6                	ld	s7,104(sp)
ffffffffc02059b2:	6ce6                	ld	s9,88(sp)
ffffffffc02059b4:	6d46                	ld	s10,80(sp)
    mm_destroy(mm);
ffffffffc02059b6:	8526                	mv	a0,s1
ffffffffc02059b8:	8e5fe0ef          	jal	ffffffffc020429c <mm_destroy>
    do_exit(ret);
ffffffffc02059bc:	854a                	mv	a0,s2
ffffffffc02059be:	f122                	sd	s0,160(sp)
ffffffffc02059c0:	e152                	sd	s4,128(sp)
ffffffffc02059c2:	f8da                	sd	s6,112(sp)
ffffffffc02059c4:	f4de                	sd	s7,104(sp)
ffffffffc02059c6:	f0e2                	sd	s8,96(sp)
ffffffffc02059c8:	ece6                	sd	s9,88(sp)
ffffffffc02059ca:	e8ea                	sd	s10,80(sp)
ffffffffc02059cc:	a6bff0ef          	jal	ffffffffc0205436 <do_exit>
    if (len > PROC_NAME_LEN) {
ffffffffc02059d0:	463d                	li	a2,15
    memcpy(local_name, name, len);
ffffffffc02059d2:	85ca                	mv	a1,s2
ffffffffc02059d4:	1808                	addi	a0,sp,48
ffffffffc02059d6:	5cf000ef          	jal	ffffffffc02067a4 <memcpy>
    if (mm != NULL) {
ffffffffc02059da:	f00991e3          	bnez	s3,ffffffffc02058dc <do_execve+0x52>
    if (current->mm != NULL) {
ffffffffc02059de:	000db783          	ld	a5,0(s11)
ffffffffc02059e2:	779c                	ld	a5,40(a5)
ffffffffc02059e4:	db85                	beqz	a5,ffffffffc0205914 <do_execve+0x8a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02059e6:	00003617          	auipc	a2,0x3
ffffffffc02059ea:	d0a60613          	addi	a2,a2,-758 # ffffffffc02086f0 <etext+0x1f34>
ffffffffc02059ee:	21200593          	li	a1,530
ffffffffc02059f2:	00003517          	auipc	a0,0x3
ffffffffc02059f6:	b1650513          	addi	a0,a0,-1258 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc02059fa:	f122                	sd	s0,160(sp)
ffffffffc02059fc:	e152                	sd	s4,128(sp)
ffffffffc02059fe:	f8da                	sd	s6,112(sp)
ffffffffc0205a00:	f4de                	sd	s7,104(sp)
ffffffffc0205a02:	f0e2                	sd	s8,96(sp)
ffffffffc0205a04:	ece6                	sd	s9,88(sp)
ffffffffc0205a06:	e8ea                	sd	s10,80(sp)
ffffffffc0205a08:	a6dfa0ef          	jal	ffffffffc0200474 <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205a0c:	038ad703          	lhu	a4,56(s5)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205a10:	9a56                	add	s4,s4,s5
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205a12:	f122                	sd	s0,160(sp)
ffffffffc0205a14:	00371793          	slli	a5,a4,0x3
ffffffffc0205a18:	8f99                	sub	a5,a5,a4
ffffffffc0205a1a:	078e                	slli	a5,a5,0x3
ffffffffc0205a1c:	97d2                	add	a5,a5,s4
ffffffffc0205a1e:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph ++) {
ffffffffc0205a20:	00fa7e63          	bgeu	s4,a5,ffffffffc0205a3c <do_execve+0x1b2>
ffffffffc0205a24:	f0e2                	sd	s8,96(sp)
        if (ph->p_type != ELF_PT_LOAD) {
ffffffffc0205a26:	000a2783          	lw	a5,0(s4) # 1000 <_binary_obj___user_softint_out_size-0x7610>
ffffffffc0205a2a:	4705                	li	a4,1
ffffffffc0205a2c:	0ee78d63          	beq	a5,a4,ffffffffc0205b26 <do_execve+0x29c>
    for (; ph < ph_end; ph ++) {
ffffffffc0205a30:	77a2                	ld	a5,40(sp)
ffffffffc0205a32:	038a0a13          	addi	s4,s4,56
ffffffffc0205a36:	fefa68e3          	bltu	s4,a5,ffffffffc0205a26 <do_execve+0x19c>
ffffffffc0205a3a:	7c06                	ld	s8,96(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc0205a3c:	4701                	li	a4,0
ffffffffc0205a3e:	46ad                	li	a3,11
ffffffffc0205a40:	00100637          	lui	a2,0x100
ffffffffc0205a44:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0205a48:	8526                	mv	a0,s1
ffffffffc0205a4a:	8a5fe0ef          	jal	ffffffffc02042ee <mm_map>
ffffffffc0205a4e:	892a                	mv	s2,a0
ffffffffc0205a50:	18051d63          	bnez	a0,ffffffffc0205bea <do_execve+0x360>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205a54:	6c88                	ld	a0,24(s1)
ffffffffc0205a56:	467d                	li	a2,31
ffffffffc0205a58:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0205a5c:	8abfd0ef          	jal	ffffffffc0203306 <pgdir_alloc_page>
ffffffffc0205a60:	38050563          	beqz	a0,ffffffffc0205dea <do_execve+0x560>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205a64:	6c88                	ld	a0,24(s1)
ffffffffc0205a66:	467d                	li	a2,31
ffffffffc0205a68:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0205a6c:	89bfd0ef          	jal	ffffffffc0203306 <pgdir_alloc_page>
ffffffffc0205a70:	34050c63          	beqz	a0,ffffffffc0205dc8 <do_execve+0x53e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205a74:	6c88                	ld	a0,24(s1)
ffffffffc0205a76:	467d                	li	a2,31
ffffffffc0205a78:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205a7c:	88bfd0ef          	jal	ffffffffc0203306 <pgdir_alloc_page>
ffffffffc0205a80:	32050363          	beqz	a0,ffffffffc0205da6 <do_execve+0x51c>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205a84:	6c88                	ld	a0,24(s1)
ffffffffc0205a86:	467d                	li	a2,31
ffffffffc0205a88:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205a8c:	87bfd0ef          	jal	ffffffffc0203306 <pgdir_alloc_page>
ffffffffc0205a90:	2e050a63          	beqz	a0,ffffffffc0205d84 <do_execve+0x4fa>
    mm->mm_count += 1;
ffffffffc0205a94:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0205a96:	000db603          	ld	a2,0(s11)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205a9a:	6c94                	ld	a3,24(s1)
ffffffffc0205a9c:	2785                	addiw	a5,a5,1
ffffffffc0205a9e:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0205aa0:	f604                	sd	s1,40(a2)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205aa2:	c02007b7          	lui	a5,0xc0200
ffffffffc0205aa6:	2cf6e263          	bltu	a3,a5,ffffffffc0205d6a <do_execve+0x4e0>
ffffffffc0205aaa:	000b3783          	ld	a5,0(s6)
ffffffffc0205aae:	577d                	li	a4,-1
ffffffffc0205ab0:	177e                	slli	a4,a4,0x3f
ffffffffc0205ab2:	8e9d                	sub	a3,a3,a5
ffffffffc0205ab4:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205ab8:	f654                	sd	a3,168(a2)
ffffffffc0205aba:	8fd9                	or	a5,a5,a4
ffffffffc0205abc:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205ac0:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205ac2:	4581                	li	a1,0
ffffffffc0205ac4:	12000613          	li	a2,288
ffffffffc0205ac8:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0205aca:	10043983          	ld	s3,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205ace:	4c5000ef          	jal	ffffffffc0206792 <memset>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205ad2:	000db483          	ld	s1,0(s11)
    tf->epc = elf->e_entry;
ffffffffc0205ad6:	018ab703          	ld	a4,24(s5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0205ada:	4785                	li	a5,1
ffffffffc0205adc:	07fe                	slli	a5,a5,0x1f
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205ade:	0b448493          	addi	s1,s1,180
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0205ae2:	edf9f993          	andi	s3,s3,-289
    tf->gpr.sp = USTACKTOP;
ffffffffc0205ae6:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0205ae8:	10e43423          	sd	a4,264(s0)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0205aec:	11343023          	sd	s3,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205af0:	4641                	li	a2,16
ffffffffc0205af2:	4581                	li	a1,0
ffffffffc0205af4:	8526                	mv	a0,s1
ffffffffc0205af6:	49d000ef          	jal	ffffffffc0206792 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205afa:	463d                	li	a2,15
ffffffffc0205afc:	180c                	addi	a1,sp,48
ffffffffc0205afe:	8526                	mv	a0,s1
ffffffffc0205b00:	4a5000ef          	jal	ffffffffc02067a4 <memcpy>
ffffffffc0205b04:	740a                	ld	s0,160(sp)
ffffffffc0205b06:	6a0a                	ld	s4,128(sp)
ffffffffc0205b08:	7b46                	ld	s6,112(sp)
ffffffffc0205b0a:	7ba6                	ld	s7,104(sp)
ffffffffc0205b0c:	6ce6                	ld	s9,88(sp)
ffffffffc0205b0e:	6d46                	ld	s10,80(sp)
}
ffffffffc0205b10:	70aa                	ld	ra,168(sp)
ffffffffc0205b12:	64ea                	ld	s1,152(sp)
ffffffffc0205b14:	69aa                	ld	s3,136(sp)
ffffffffc0205b16:	7ae6                	ld	s5,120(sp)
ffffffffc0205b18:	6da6                	ld	s11,72(sp)
ffffffffc0205b1a:	854a                	mv	a0,s2
ffffffffc0205b1c:	694a                	ld	s2,144(sp)
ffffffffc0205b1e:	614d                	addi	sp,sp,176
ffffffffc0205b20:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0205b22:	5971                	li	s2,-4
ffffffffc0205b24:	bd61                	j	ffffffffc02059bc <do_execve+0x132>
        if (ph->p_filesz > ph->p_memsz) {
ffffffffc0205b26:	028a3603          	ld	a2,40(s4)
ffffffffc0205b2a:	020a3783          	ld	a5,32(s4)
ffffffffc0205b2e:	1ef66f63          	bltu	a2,a5,ffffffffc0205d2c <do_execve+0x4a2>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205b32:	004a2783          	lw	a5,4(s4)
ffffffffc0205b36:	0017f693          	andi	a3,a5,1
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205b3a:	0027f593          	andi	a1,a5,2
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205b3e:	0026971b          	slliw	a4,a3,0x2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205b42:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205b44:	068a                	slli	a3,a3,0x2
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205b46:	e1e9                	bnez	a1,ffffffffc0205c08 <do_execve+0x37e>
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205b48:	1a079b63          	bnez	a5,ffffffffc0205cfe <do_execve+0x474>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205b4c:	47c5                	li	a5,17
ffffffffc0205b4e:	ec3e                	sd	a5,24(sp)
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc0205b50:	0046f793          	andi	a5,a3,4
ffffffffc0205b54:	c789                	beqz	a5,ffffffffc0205b5e <do_execve+0x2d4>
ffffffffc0205b56:	67e2                	ld	a5,24(sp)
ffffffffc0205b58:	0087e793          	ori	a5,a5,8
ffffffffc0205b5c:	ec3e                	sd	a5,24(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
ffffffffc0205b5e:	010a3583          	ld	a1,16(s4)
ffffffffc0205b62:	4701                	li	a4,0
ffffffffc0205b64:	8526                	mv	a0,s1
ffffffffc0205b66:	f88fe0ef          	jal	ffffffffc02042ee <mm_map>
ffffffffc0205b6a:	892a                	mv	s2,a0
ffffffffc0205b6c:	1a051e63          	bnez	a0,ffffffffc0205d28 <do_execve+0x49e>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205b70:	010a3c03          	ld	s8,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205b74:	020a3903          	ld	s2,32(s4)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205b78:	008a3983          	ld	s3,8(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205b7c:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205b7e:	9962                	add	s2,s2,s8
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205b80:	00fc7bb3          	and	s7,s8,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205b84:	99d6                	add	s3,s3,s5
        while (start < end) {
ffffffffc0205b86:	052c6963          	bltu	s8,s2,ffffffffc0205bd8 <do_execve+0x34e>
ffffffffc0205b8a:	aa59                	j	ffffffffc0205d20 <do_execve+0x496>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205b8c:	6785                	lui	a5,0x1
ffffffffc0205b8e:	417c0533          	sub	a0,s8,s7
ffffffffc0205b92:	9bbe                	add	s7,s7,a5
            if (end < la) {
ffffffffc0205b94:	41890633          	sub	a2,s2,s8
ffffffffc0205b98:	01796463          	bltu	s2,s7,ffffffffc0205ba0 <do_execve+0x316>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205b9c:	418b8633          	sub	a2,s7,s8
    return page - pages + nbase;
ffffffffc0205ba0:	000d3683          	ld	a3,0(s10)
ffffffffc0205ba4:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205ba6:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0205baa:	40d406b3          	sub	a3,s0,a3
ffffffffc0205bae:	8699                	srai	a3,a3,0x6
ffffffffc0205bb0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205bb2:	7782                	ld	a5,32(sp)
ffffffffc0205bb4:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205bb8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205bba:	16b87c63          	bgeu	a6,a1,ffffffffc0205d32 <do_execve+0x4a8>
ffffffffc0205bbe:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205bc2:	85ce                	mv	a1,s3
ffffffffc0205bc4:	e432                	sd	a2,8(sp)
ffffffffc0205bc6:	96c2                	add	a3,a3,a6
ffffffffc0205bc8:	9536                	add	a0,a0,a3
ffffffffc0205bca:	3db000ef          	jal	ffffffffc02067a4 <memcpy>
            start += size, from += size;
ffffffffc0205bce:	6622                	ld	a2,8(sp)
ffffffffc0205bd0:	9c32                	add	s8,s8,a2
ffffffffc0205bd2:	99b2                	add	s3,s3,a2
        while (start < end) {
ffffffffc0205bd4:	052c7363          	bgeu	s8,s2,ffffffffc0205c1a <do_execve+0x390>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205bd8:	6c88                	ld	a0,24(s1)
ffffffffc0205bda:	6662                	ld	a2,24(sp)
ffffffffc0205bdc:	85de                	mv	a1,s7
ffffffffc0205bde:	f28fd0ef          	jal	ffffffffc0203306 <pgdir_alloc_page>
ffffffffc0205be2:	842a                	mv	s0,a0
ffffffffc0205be4:	f545                	bnez	a0,ffffffffc0205b8c <do_execve+0x302>
ffffffffc0205be6:	7c06                	ld	s8,96(sp)
        ret = -E_NO_MEM;
ffffffffc0205be8:	5971                	li	s2,-4
    exit_mmap(mm);
ffffffffc0205bea:	8526                	mv	a0,s1
ffffffffc0205bec:	869fe0ef          	jal	ffffffffc0204454 <exit_mmap>
ffffffffc0205bf0:	740a                	ld	s0,160(sp)
ffffffffc0205bf2:	bb55                	j	ffffffffc02059a6 <do_execve+0x11c>
            exit_mmap(mm);
ffffffffc0205bf4:	854e                	mv	a0,s3
ffffffffc0205bf6:	85ffe0ef          	jal	ffffffffc0204454 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205bfa:	854e                	mv	a0,s3
ffffffffc0205bfc:	accff0ef          	jal	ffffffffc0204ec8 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205c00:	854e                	mv	a0,s3
ffffffffc0205c02:	e9afe0ef          	jal	ffffffffc020429c <mm_destroy>
ffffffffc0205c06:	b319                	j	ffffffffc020590c <do_execve+0x82>
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205c08:	10079263          	bnez	a5,ffffffffc0205d0c <do_execve+0x482>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205c0c:	00276713          	ori	a4,a4,2
ffffffffc0205c10:	0007069b          	sext.w	a3,a4
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205c14:	47dd                	li	a5,23
ffffffffc0205c16:	ec3e                	sd	a5,24(sp)
ffffffffc0205c18:	bf25                	j	ffffffffc0205b50 <do_execve+0x2c6>
        end = ph->p_va + ph->p_memsz;
ffffffffc0205c1a:	010a3903          	ld	s2,16(s4)
ffffffffc0205c1e:	028a3683          	ld	a3,40(s4)
ffffffffc0205c22:	9936                	add	s2,s2,a3
        if (start < la) {
ffffffffc0205c24:	077c7a63          	bgeu	s8,s7,ffffffffc0205c98 <do_execve+0x40e>
            if (start == end) {
ffffffffc0205c28:	e18904e3          	beq	s2,s8,ffffffffc0205a30 <do_execve+0x1a6>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205c2c:	6505                	lui	a0,0x1
ffffffffc0205c2e:	9562                	add	a0,a0,s8
ffffffffc0205c30:	41750533          	sub	a0,a0,s7
                size -= la - end;
ffffffffc0205c34:	418909b3          	sub	s3,s2,s8
            if (end < la) {
ffffffffc0205c38:	0d797f63          	bgeu	s2,s7,ffffffffc0205d16 <do_execve+0x48c>
    return page - pages + nbase;
ffffffffc0205c3c:	000d3683          	ld	a3,0(s10)
ffffffffc0205c40:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205c42:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205c46:	40d406b3          	sub	a3,s0,a3
ffffffffc0205c4a:	8699                	srai	a3,a3,0x6
ffffffffc0205c4c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205c4e:	00c69593          	slli	a1,a3,0xc
ffffffffc0205c52:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0205c54:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205c56:	0cc5fe63          	bgeu	a1,a2,ffffffffc0205d32 <do_execve+0x4a8>
ffffffffc0205c5a:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205c5e:	864e                	mv	a2,s3
ffffffffc0205c60:	4581                	li	a1,0
ffffffffc0205c62:	96c2                	add	a3,a3,a6
ffffffffc0205c64:	9536                	add	a0,a0,a3
ffffffffc0205c66:	32d000ef          	jal	ffffffffc0206792 <memset>
            start += size;
ffffffffc0205c6a:	9c4e                	add	s8,s8,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205c6c:	03797463          	bgeu	s2,s7,ffffffffc0205c94 <do_execve+0x40a>
ffffffffc0205c70:	dd8900e3          	beq	s2,s8,ffffffffc0205a30 <do_execve+0x1a6>
ffffffffc0205c74:	00003697          	auipc	a3,0x3
ffffffffc0205c78:	aa468693          	addi	a3,a3,-1372 # ffffffffc0208718 <etext+0x1f5c>
ffffffffc0205c7c:	00001617          	auipc	a2,0x1
ffffffffc0205c80:	1bc60613          	addi	a2,a2,444 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0205c84:	26700593          	li	a1,615
ffffffffc0205c88:	00003517          	auipc	a0,0x3
ffffffffc0205c8c:	88050513          	addi	a0,a0,-1920 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205c90:	fe4fa0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc0205c94:	ff8b90e3          	bne	s7,s8,ffffffffc0205c74 <do_execve+0x3ea>
        while (start < end) {
ffffffffc0205c98:	d92c7ce3          	bgeu	s8,s2,ffffffffc0205a30 <do_execve+0x1a6>
ffffffffc0205c9c:	56fd                	li	a3,-1
ffffffffc0205c9e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205ca2:	e43e                	sd	a5,8(sp)
ffffffffc0205ca4:	a0a9                	j	ffffffffc0205cee <do_execve+0x464>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205ca6:	6785                	lui	a5,0x1
ffffffffc0205ca8:	417c0533          	sub	a0,s8,s7
ffffffffc0205cac:	9bbe                	add	s7,s7,a5
            if (end < la) {
ffffffffc0205cae:	418909b3          	sub	s3,s2,s8
ffffffffc0205cb2:	01796463          	bltu	s2,s7,ffffffffc0205cba <do_execve+0x430>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205cb6:	418b89b3          	sub	s3,s7,s8
    return page - pages + nbase;
ffffffffc0205cba:	000d3683          	ld	a3,0(s10)
ffffffffc0205cbe:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205cc0:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0205cc4:	40d406b3          	sub	a3,s0,a3
ffffffffc0205cc8:	8699                	srai	a3,a3,0x6
ffffffffc0205cca:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205ccc:	67a2                	ld	a5,8(sp)
ffffffffc0205cce:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205cd2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205cd4:	04b87f63          	bgeu	a6,a1,ffffffffc0205d32 <do_execve+0x4a8>
ffffffffc0205cd8:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205cdc:	864e                	mv	a2,s3
ffffffffc0205cde:	4581                	li	a1,0
ffffffffc0205ce0:	96c2                	add	a3,a3,a6
ffffffffc0205ce2:	9536                	add	a0,a0,a3
            start += size;
ffffffffc0205ce4:	9c4e                	add	s8,s8,s3
            memset(page2kva(page) + off, 0, size);
ffffffffc0205ce6:	2ad000ef          	jal	ffffffffc0206792 <memset>
        while (start < end) {
ffffffffc0205cea:	d52c73e3          	bgeu	s8,s2,ffffffffc0205a30 <do_execve+0x1a6>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205cee:	6c88                	ld	a0,24(s1)
ffffffffc0205cf0:	6662                	ld	a2,24(sp)
ffffffffc0205cf2:	85de                	mv	a1,s7
ffffffffc0205cf4:	e12fd0ef          	jal	ffffffffc0203306 <pgdir_alloc_page>
ffffffffc0205cf8:	842a                	mv	s0,a0
ffffffffc0205cfa:	f555                	bnez	a0,ffffffffc0205ca6 <do_execve+0x41c>
ffffffffc0205cfc:	b5ed                	j	ffffffffc0205be6 <do_execve+0x35c>
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205cfe:	00176713          	ori	a4,a4,1
ffffffffc0205d02:	47cd                	li	a5,19
ffffffffc0205d04:	0007069b          	sext.w	a3,a4
ffffffffc0205d08:	ec3e                	sd	a5,24(sp)
ffffffffc0205d0a:	b599                	j	ffffffffc0205b50 <do_execve+0x2c6>
ffffffffc0205d0c:	00376713          	ori	a4,a4,3
ffffffffc0205d10:	0007069b          	sext.w	a3,a4
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205d14:	b701                	j	ffffffffc0205c14 <do_execve+0x38a>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205d16:	418b89b3          	sub	s3,s7,s8
ffffffffc0205d1a:	b70d                	j	ffffffffc0205c3c <do_execve+0x3b2>
        return -E_INVAL;
ffffffffc0205d1c:	5975                	li	s2,-3
ffffffffc0205d1e:	bbcd                	j	ffffffffc0205b10 <do_execve+0x286>
        while (start < end) {
ffffffffc0205d20:	8962                	mv	s2,s8
ffffffffc0205d22:	bdf5                	j	ffffffffc0205c1e <do_execve+0x394>
    int ret = -E_NO_MEM;
ffffffffc0205d24:	5971                	li	s2,-4
ffffffffc0205d26:	b941                	j	ffffffffc02059b6 <do_execve+0x12c>
ffffffffc0205d28:	7c06                	ld	s8,96(sp)
ffffffffc0205d2a:	b5c1                	j	ffffffffc0205bea <do_execve+0x360>
            ret = -E_INVAL_ELF;
ffffffffc0205d2c:	7c06                	ld	s8,96(sp)
ffffffffc0205d2e:	5961                	li	s2,-8
ffffffffc0205d30:	bd6d                	j	ffffffffc0205bea <do_execve+0x360>
ffffffffc0205d32:	00001617          	auipc	a2,0x1
ffffffffc0205d36:	72e60613          	addi	a2,a2,1838 # ffffffffc0207460 <etext+0xca4>
ffffffffc0205d3a:	06900593          	li	a1,105
ffffffffc0205d3e:	00001517          	auipc	a0,0x1
ffffffffc0205d42:	74a50513          	addi	a0,a0,1866 # ffffffffc0207488 <etext+0xccc>
ffffffffc0205d46:	f2efa0ef          	jal	ffffffffc0200474 <__panic>
ffffffffc0205d4a:	00001617          	auipc	a2,0x1
ffffffffc0205d4e:	71660613          	addi	a2,a2,1814 # ffffffffc0207460 <etext+0xca4>
ffffffffc0205d52:	06900593          	li	a1,105
ffffffffc0205d56:	00001517          	auipc	a0,0x1
ffffffffc0205d5a:	73250513          	addi	a0,a0,1842 # ffffffffc0207488 <etext+0xccc>
ffffffffc0205d5e:	f122                	sd	s0,160(sp)
ffffffffc0205d60:	e152                	sd	s4,128(sp)
ffffffffc0205d62:	f8da                	sd	s6,112(sp)
ffffffffc0205d64:	f0e2                	sd	s8,96(sp)
ffffffffc0205d66:	f0efa0ef          	jal	ffffffffc0200474 <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205d6a:	00001617          	auipc	a2,0x1
ffffffffc0205d6e:	79e60613          	addi	a2,a2,1950 # ffffffffc0207508 <etext+0xd4c>
ffffffffc0205d72:	28200593          	li	a1,642
ffffffffc0205d76:	00002517          	auipc	a0,0x2
ffffffffc0205d7a:	79250513          	addi	a0,a0,1938 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205d7e:	f0e2                	sd	s8,96(sp)
ffffffffc0205d80:	ef4fa0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205d84:	00003697          	auipc	a3,0x3
ffffffffc0205d88:	aac68693          	addi	a3,a3,-1364 # ffffffffc0208830 <etext+0x2074>
ffffffffc0205d8c:	00001617          	auipc	a2,0x1
ffffffffc0205d90:	0ac60613          	addi	a2,a2,172 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0205d94:	27d00593          	li	a1,637
ffffffffc0205d98:	00002517          	auipc	a0,0x2
ffffffffc0205d9c:	77050513          	addi	a0,a0,1904 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205da0:	f0e2                	sd	s8,96(sp)
ffffffffc0205da2:	ed2fa0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205da6:	00003697          	auipc	a3,0x3
ffffffffc0205daa:	a4268693          	addi	a3,a3,-1470 # ffffffffc02087e8 <etext+0x202c>
ffffffffc0205dae:	00001617          	auipc	a2,0x1
ffffffffc0205db2:	08a60613          	addi	a2,a2,138 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0205db6:	27c00593          	li	a1,636
ffffffffc0205dba:	00002517          	auipc	a0,0x2
ffffffffc0205dbe:	74e50513          	addi	a0,a0,1870 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205dc2:	f0e2                	sd	s8,96(sp)
ffffffffc0205dc4:	eb0fa0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205dc8:	00003697          	auipc	a3,0x3
ffffffffc0205dcc:	9d868693          	addi	a3,a3,-1576 # ffffffffc02087a0 <etext+0x1fe4>
ffffffffc0205dd0:	00001617          	auipc	a2,0x1
ffffffffc0205dd4:	06860613          	addi	a2,a2,104 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0205dd8:	27b00593          	li	a1,635
ffffffffc0205ddc:	00002517          	auipc	a0,0x2
ffffffffc0205de0:	72c50513          	addi	a0,a0,1836 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205de4:	f0e2                	sd	s8,96(sp)
ffffffffc0205de6:	e8efa0ef          	jal	ffffffffc0200474 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205dea:	00003697          	auipc	a3,0x3
ffffffffc0205dee:	96e68693          	addi	a3,a3,-1682 # ffffffffc0208758 <etext+0x1f9c>
ffffffffc0205df2:	00001617          	auipc	a2,0x1
ffffffffc0205df6:	04660613          	addi	a2,a2,70 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0205dfa:	27a00593          	li	a1,634
ffffffffc0205dfe:	00002517          	auipc	a0,0x2
ffffffffc0205e02:	70a50513          	addi	a0,a0,1802 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0205e06:	f0e2                	sd	s8,96(sp)
ffffffffc0205e08:	e6cfa0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0205e0c <do_yield>:
    current->need_resched = 1;
ffffffffc0205e0c:	00098797          	auipc	a5,0x98
ffffffffc0205e10:	ef47b783          	ld	a5,-268(a5) # ffffffffc029dd00 <current>
ffffffffc0205e14:	4705                	li	a4,1
ffffffffc0205e16:	ef98                	sd	a4,24(a5)
}
ffffffffc0205e18:	4501                	li	a0,0
ffffffffc0205e1a:	8082                	ret

ffffffffc0205e1c <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205e1c:	1101                	addi	sp,sp,-32
ffffffffc0205e1e:	e822                	sd	s0,16(sp)
ffffffffc0205e20:	e426                	sd	s1,8(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0205e22:	00098797          	auipc	a5,0x98
ffffffffc0205e26:	ede7b783          	ld	a5,-290(a5) # ffffffffc029dd00 <current>
do_wait(int pid, int *code_store) {
ffffffffc0205e2a:	ec06                	sd	ra,24(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0205e2c:	779c                	ld	a5,40(a5)
do_wait(int pid, int *code_store) {
ffffffffc0205e2e:	842e                	mv	s0,a1
ffffffffc0205e30:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205e32:	c599                	beqz	a1,ffffffffc0205e40 <do_wait+0x24>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205e34:	4685                	li	a3,1
ffffffffc0205e36:	4611                	li	a2,4
ffffffffc0205e38:	853e                	mv	a0,a5
ffffffffc0205e3a:	d95fe0ef          	jal	ffffffffc0204bce <user_mem_check>
ffffffffc0205e3e:	c909                	beqz	a0,ffffffffc0205e50 <do_wait+0x34>
ffffffffc0205e40:	85a2                	mv	a1,s0
}
ffffffffc0205e42:	6442                	ld	s0,16(sp)
ffffffffc0205e44:	60e2                	ld	ra,24(sp)
ffffffffc0205e46:	8526                	mv	a0,s1
ffffffffc0205e48:	64a2                	ld	s1,8(sp)
ffffffffc0205e4a:	6105                	addi	sp,sp,32
ffffffffc0205e4c:	f3aff06f          	j	ffffffffc0205586 <do_wait.part.0>
ffffffffc0205e50:	60e2                	ld	ra,24(sp)
ffffffffc0205e52:	6442                	ld	s0,16(sp)
ffffffffc0205e54:	64a2                	ld	s1,8(sp)
ffffffffc0205e56:	5575                	li	a0,-3
ffffffffc0205e58:	6105                	addi	sp,sp,32
ffffffffc0205e5a:	8082                	ret

ffffffffc0205e5c <do_kill>:
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205e5c:	6789                	lui	a5,0x2
ffffffffc0205e5e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205e62:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6612>
ffffffffc0205e64:	06e7e963          	bltu	a5,a4,ffffffffc0205ed6 <do_kill+0x7a>
do_kill(int pid) {
ffffffffc0205e68:	1141                	addi	sp,sp,-16
ffffffffc0205e6a:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205e6c:	45a9                	li	a1,10
ffffffffc0205e6e:	842a                	mv	s0,a0
ffffffffc0205e70:	2501                	sext.w	a0,a0
do_kill(int pid) {
ffffffffc0205e72:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205e74:	48a000ef          	jal	ffffffffc02062fe <hash32>
ffffffffc0205e78:	02051793          	slli	a5,a0,0x20
ffffffffc0205e7c:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205e80:	00094797          	auipc	a5,0x94
ffffffffc0205e84:	df078793          	addi	a5,a5,-528 # ffffffffc0299c70 <hash_list>
ffffffffc0205e88:	953e                	add	a0,a0,a5
ffffffffc0205e8a:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list) {
ffffffffc0205e8c:	a029                	j	ffffffffc0205e96 <do_kill+0x3a>
            if (proc->pid == pid) {
ffffffffc0205e8e:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205e92:	00870a63          	beq	a4,s0,ffffffffc0205ea6 <do_kill+0x4a>
ffffffffc0205e96:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205e98:	fef51be3          	bne	a0,a5,ffffffffc0205e8e <do_kill+0x32>
    return -E_INVAL;
ffffffffc0205e9c:	5575                	li	a0,-3
}
ffffffffc0205e9e:	60a2                	ld	ra,8(sp)
ffffffffc0205ea0:	6402                	ld	s0,0(sp)
ffffffffc0205ea2:	0141                	addi	sp,sp,16
ffffffffc0205ea4:	8082                	ret
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205ea6:	fd87a703          	lw	a4,-40(a5)
        return -E_KILLED;
ffffffffc0205eaa:	555d                	li	a0,-9
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205eac:	00177693          	andi	a3,a4,1
ffffffffc0205eb0:	f6fd                	bnez	a3,ffffffffc0205e9e <do_kill+0x42>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205eb2:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0205eb4:	00176713          	ori	a4,a4,1
ffffffffc0205eb8:	fce7ac23          	sw	a4,-40(a5)
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205ebc:	0006c763          	bltz	a3,ffffffffc0205eca <do_kill+0x6e>
            return 0;
ffffffffc0205ec0:	4501                	li	a0,0
}
ffffffffc0205ec2:	60a2                	ld	ra,8(sp)
ffffffffc0205ec4:	6402                	ld	s0,0(sp)
ffffffffc0205ec6:	0141                	addi	sp,sp,16
ffffffffc0205ec8:	8082                	ret
                wakeup_proc(proc);
ffffffffc0205eca:	f2878513          	addi	a0,a5,-216
ffffffffc0205ece:	22a000ef          	jal	ffffffffc02060f8 <wakeup_proc>
            return 0;
ffffffffc0205ed2:	4501                	li	a0,0
ffffffffc0205ed4:	b7fd                	j	ffffffffc0205ec2 <do_kill+0x66>
    return -E_INVAL;
ffffffffc0205ed6:	5575                	li	a0,-3
}
ffffffffc0205ed8:	8082                	ret

ffffffffc0205eda <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0205eda:	1101                	addi	sp,sp,-32
ffffffffc0205edc:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205ede:	00098797          	auipc	a5,0x98
ffffffffc0205ee2:	d9278793          	addi	a5,a5,-622 # ffffffffc029dc70 <proc_list>
ffffffffc0205ee6:	ec06                	sd	ra,24(sp)
ffffffffc0205ee8:	e822                	sd	s0,16(sp)
ffffffffc0205eea:	e04a                	sd	s2,0(sp)
ffffffffc0205eec:	00094497          	auipc	s1,0x94
ffffffffc0205ef0:	d8448493          	addi	s1,s1,-636 # ffffffffc0299c70 <hash_list>
ffffffffc0205ef4:	e79c                	sd	a5,8(a5)
ffffffffc0205ef6:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205ef8:	00098717          	auipc	a4,0x98
ffffffffc0205efc:	d7870713          	addi	a4,a4,-648 # ffffffffc029dc70 <proc_list>
ffffffffc0205f00:	87a6                	mv	a5,s1
ffffffffc0205f02:	e79c                	sd	a5,8(a5)
ffffffffc0205f04:	e39c                	sd	a5,0(a5)
ffffffffc0205f06:	07c1                	addi	a5,a5,16
ffffffffc0205f08:	fee79de3          	bne	a5,a4,ffffffffc0205f02 <proc_init+0x28>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0205f0c:	ebffe0ef          	jal	ffffffffc0204dca <alloc_proc>
ffffffffc0205f10:	00098917          	auipc	s2,0x98
ffffffffc0205f14:	e0090913          	addi	s2,s2,-512 # ffffffffc029dd10 <idleproc>
ffffffffc0205f18:	00a93023          	sd	a0,0(s2)
ffffffffc0205f1c:	10050063          	beqz	a0,ffffffffc020601c <proc_init+0x142>
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205f20:	4789                	li	a5,2
ffffffffc0205f22:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205f24:	00003797          	auipc	a5,0x3
ffffffffc0205f28:	0dc78793          	addi	a5,a5,220 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205f2c:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205f30:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205f32:	4785                	li	a5,1
ffffffffc0205f34:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205f36:	4641                	li	a2,16
ffffffffc0205f38:	4581                	li	a1,0
ffffffffc0205f3a:	8522                	mv	a0,s0
ffffffffc0205f3c:	057000ef          	jal	ffffffffc0206792 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205f40:	463d                	li	a2,15
ffffffffc0205f42:	00003597          	auipc	a1,0x3
ffffffffc0205f46:	94e58593          	addi	a1,a1,-1714 # ffffffffc0208890 <etext+0x20d4>
ffffffffc0205f4a:	8522                	mv	a0,s0
ffffffffc0205f4c:	059000ef          	jal	ffffffffc02067a4 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process ++;
ffffffffc0205f50:	00098717          	auipc	a4,0x98
ffffffffc0205f54:	da870713          	addi	a4,a4,-600 # ffffffffc029dcf8 <nr_process>
ffffffffc0205f58:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205f5a:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205f5e:	4601                	li	a2,0
    nr_process ++;
ffffffffc0205f60:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205f62:	4581                	li	a1,0
ffffffffc0205f64:	00000517          	auipc	a0,0x0
ffffffffc0205f68:	80250513          	addi	a0,a0,-2046 # ffffffffc0205766 <init_main>
    nr_process ++;
ffffffffc0205f6c:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205f6e:	00098797          	auipc	a5,0x98
ffffffffc0205f72:	d8d7b923          	sd	a3,-622(a5) # ffffffffc029dd00 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205f76:	c70ff0ef          	jal	ffffffffc02053e6 <kernel_thread>
ffffffffc0205f7a:	842a                	mv	s0,a0
    if (pid <= 0) {
ffffffffc0205f7c:	08a05463          	blez	a0,ffffffffc0206004 <proc_init+0x12a>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205f80:	6789                	lui	a5,0x2
ffffffffc0205f82:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205f86:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6612>
ffffffffc0205f88:	2501                	sext.w	a0,a0
ffffffffc0205f8a:	02e7e463          	bltu	a5,a4,ffffffffc0205fb2 <proc_init+0xd8>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205f8e:	45a9                	li	a1,10
ffffffffc0205f90:	36e000ef          	jal	ffffffffc02062fe <hash32>
ffffffffc0205f94:	02051713          	slli	a4,a0,0x20
ffffffffc0205f98:	01c75793          	srli	a5,a4,0x1c
ffffffffc0205f9c:	00f486b3          	add	a3,s1,a5
ffffffffc0205fa0:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0205fa2:	a029                	j	ffffffffc0205fac <proc_init+0xd2>
            if (proc->pid == pid) {
ffffffffc0205fa4:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205fa8:	04870b63          	beq	a4,s0,ffffffffc0205ffe <proc_init+0x124>
    return listelm->next;
ffffffffc0205fac:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205fae:	fef69be3          	bne	a3,a5,ffffffffc0205fa4 <proc_init+0xca>
    return NULL;
ffffffffc0205fb2:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205fb4:	0b478493          	addi	s1,a5,180
ffffffffc0205fb8:	4641                	li	a2,16
ffffffffc0205fba:	4581                	li	a1,0
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205fbc:	00098417          	auipc	s0,0x98
ffffffffc0205fc0:	d4c40413          	addi	s0,s0,-692 # ffffffffc029dd08 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205fc4:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205fc6:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205fc8:	7ca000ef          	jal	ffffffffc0206792 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205fcc:	463d                	li	a2,15
ffffffffc0205fce:	00003597          	auipc	a1,0x3
ffffffffc0205fd2:	8ea58593          	addi	a1,a1,-1814 # ffffffffc02088b8 <etext+0x20fc>
ffffffffc0205fd6:	8526                	mv	a0,s1
ffffffffc0205fd8:	7cc000ef          	jal	ffffffffc02067a4 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205fdc:	00093783          	ld	a5,0(s2)
ffffffffc0205fe0:	cbb5                	beqz	a5,ffffffffc0206054 <proc_init+0x17a>
ffffffffc0205fe2:	43dc                	lw	a5,4(a5)
ffffffffc0205fe4:	eba5                	bnez	a5,ffffffffc0206054 <proc_init+0x17a>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205fe6:	601c                	ld	a5,0(s0)
ffffffffc0205fe8:	c7b1                	beqz	a5,ffffffffc0206034 <proc_init+0x15a>
ffffffffc0205fea:	43d8                	lw	a4,4(a5)
ffffffffc0205fec:	4785                	li	a5,1
ffffffffc0205fee:	04f71363          	bne	a4,a5,ffffffffc0206034 <proc_init+0x15a>
}
ffffffffc0205ff2:	60e2                	ld	ra,24(sp)
ffffffffc0205ff4:	6442                	ld	s0,16(sp)
ffffffffc0205ff6:	64a2                	ld	s1,8(sp)
ffffffffc0205ff8:	6902                	ld	s2,0(sp)
ffffffffc0205ffa:	6105                	addi	sp,sp,32
ffffffffc0205ffc:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205ffe:	f2878793          	addi	a5,a5,-216
ffffffffc0206002:	bf4d                	j	ffffffffc0205fb4 <proc_init+0xda>
        panic("create init_main failed.\n");
ffffffffc0206004:	00003617          	auipc	a2,0x3
ffffffffc0206008:	89460613          	addi	a2,a2,-1900 # ffffffffc0208898 <etext+0x20dc>
ffffffffc020600c:	38b00593          	li	a1,907
ffffffffc0206010:	00002517          	auipc	a0,0x2
ffffffffc0206014:	4f850513          	addi	a0,a0,1272 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0206018:	c5cfa0ef          	jal	ffffffffc0200474 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc020601c:	00003617          	auipc	a2,0x3
ffffffffc0206020:	85c60613          	addi	a2,a2,-1956 # ffffffffc0208878 <etext+0x20bc>
ffffffffc0206024:	37d00593          	li	a1,893
ffffffffc0206028:	00002517          	auipc	a0,0x2
ffffffffc020602c:	4e050513          	addi	a0,a0,1248 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0206030:	c44fa0ef          	jal	ffffffffc0200474 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0206034:	00003697          	auipc	a3,0x3
ffffffffc0206038:	8b468693          	addi	a3,a3,-1868 # ffffffffc02088e8 <etext+0x212c>
ffffffffc020603c:	00001617          	auipc	a2,0x1
ffffffffc0206040:	dfc60613          	addi	a2,a2,-516 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0206044:	39200593          	li	a1,914
ffffffffc0206048:	00002517          	auipc	a0,0x2
ffffffffc020604c:	4c050513          	addi	a0,a0,1216 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0206050:	c24fa0ef          	jal	ffffffffc0200474 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0206054:	00003697          	auipc	a3,0x3
ffffffffc0206058:	86c68693          	addi	a3,a3,-1940 # ffffffffc02088c0 <etext+0x2104>
ffffffffc020605c:	00001617          	auipc	a2,0x1
ffffffffc0206060:	ddc60613          	addi	a2,a2,-548 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0206064:	39100593          	li	a1,913
ffffffffc0206068:	00002517          	auipc	a0,0x2
ffffffffc020606c:	4a050513          	addi	a0,a0,1184 # ffffffffc0208508 <etext+0x1d4c>
ffffffffc0206070:	c04fa0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0206074 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0206074:	1141                	addi	sp,sp,-16
ffffffffc0206076:	e022                	sd	s0,0(sp)
ffffffffc0206078:	e406                	sd	ra,8(sp)
ffffffffc020607a:	00098417          	auipc	s0,0x98
ffffffffc020607e:	c8640413          	addi	s0,s0,-890 # ffffffffc029dd00 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0206082:	6018                	ld	a4,0(s0)
ffffffffc0206084:	6f1c                	ld	a5,24(a4)
ffffffffc0206086:	dffd                	beqz	a5,ffffffffc0206084 <cpu_idle+0x10>
            schedule();
ffffffffc0206088:	10a000ef          	jal	ffffffffc0206192 <schedule>
ffffffffc020608c:	bfdd                	j	ffffffffc0206082 <cpu_idle+0xe>

ffffffffc020608e <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020608e:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0206092:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0206096:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0206098:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020609a:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020609e:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02060a2:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02060a6:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02060aa:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02060ae:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02060b2:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02060b6:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02060ba:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02060be:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02060c2:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02060c6:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02060ca:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02060cc:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02060ce:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02060d2:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02060d6:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02060da:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02060de:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02060e2:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02060e6:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02060ea:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02060ee:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02060f2:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02060f6:	8082                	ret

ffffffffc02060f8 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02060f8:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc02060fa:	1141                	addi	sp,sp,-16
ffffffffc02060fc:	e406                	sd	ra,8(sp)
ffffffffc02060fe:	e022                	sd	s0,0(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0206100:	478d                	li	a5,3
ffffffffc0206102:	06f70963          	beq	a4,a5,ffffffffc0206174 <wakeup_proc+0x7c>
ffffffffc0206106:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0206108:	100027f3          	csrr	a5,sstatus
ffffffffc020610c:	8b89                	andi	a5,a5,2
ffffffffc020610e:	eb99                	bnez	a5,ffffffffc0206124 <wakeup_proc+0x2c>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0206110:	4789                	li	a5,2
ffffffffc0206112:	02f70763          	beq	a4,a5,ffffffffc0206140 <wakeup_proc+0x48>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206116:	60a2                	ld	ra,8(sp)
ffffffffc0206118:	6402                	ld	s0,0(sp)
            proc->state = PROC_RUNNABLE;
ffffffffc020611a:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc020611c:	0e052623          	sw	zero,236(a0)
}
ffffffffc0206120:	0141                	addi	sp,sp,16
ffffffffc0206122:	8082                	ret
        intr_disable();
ffffffffc0206124:	d1cfa0ef          	jal	ffffffffc0200640 <intr_disable>
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0206128:	4018                	lw	a4,0(s0)
ffffffffc020612a:	4789                	li	a5,2
ffffffffc020612c:	02f70863          	beq	a4,a5,ffffffffc020615c <wakeup_proc+0x64>
            proc->state = PROC_RUNNABLE;
ffffffffc0206130:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0206132:	0e042623          	sw	zero,236(s0)
}
ffffffffc0206136:	6402                	ld	s0,0(sp)
ffffffffc0206138:	60a2                	ld	ra,8(sp)
ffffffffc020613a:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020613c:	cfefa06f          	j	ffffffffc020063a <intr_enable>
ffffffffc0206140:	6402                	ld	s0,0(sp)
ffffffffc0206142:	60a2                	ld	ra,8(sp)
            warn("wakeup runnable process.\n");
ffffffffc0206144:	00003617          	auipc	a2,0x3
ffffffffc0206148:	80460613          	addi	a2,a2,-2044 # ffffffffc0208948 <etext+0x218c>
ffffffffc020614c:	45c9                	li	a1,18
ffffffffc020614e:	00002517          	auipc	a0,0x2
ffffffffc0206152:	7e250513          	addi	a0,a0,2018 # ffffffffc0208930 <etext+0x2174>
}
ffffffffc0206156:	0141                	addi	sp,sp,16
            warn("wakeup runnable process.\n");
ffffffffc0206158:	b86fa06f          	j	ffffffffc02004de <__warn>
ffffffffc020615c:	00002617          	auipc	a2,0x2
ffffffffc0206160:	7ec60613          	addi	a2,a2,2028 # ffffffffc0208948 <etext+0x218c>
ffffffffc0206164:	45c9                	li	a1,18
ffffffffc0206166:	00002517          	auipc	a0,0x2
ffffffffc020616a:	7ca50513          	addi	a0,a0,1994 # ffffffffc0208930 <etext+0x2174>
ffffffffc020616e:	b70fa0ef          	jal	ffffffffc02004de <__warn>
    if (flag) {
ffffffffc0206172:	b7d1                	j	ffffffffc0206136 <wakeup_proc+0x3e>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0206174:	00002697          	auipc	a3,0x2
ffffffffc0206178:	79c68693          	addi	a3,a3,1948 # ffffffffc0208910 <etext+0x2154>
ffffffffc020617c:	00001617          	auipc	a2,0x1
ffffffffc0206180:	cbc60613          	addi	a2,a2,-836 # ffffffffc0206e38 <etext+0x67c>
ffffffffc0206184:	45a5                	li	a1,9
ffffffffc0206186:	00002517          	auipc	a0,0x2
ffffffffc020618a:	7aa50513          	addi	a0,a0,1962 # ffffffffc0208930 <etext+0x2174>
ffffffffc020618e:	ae6fa0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc0206192 <schedule>:

void
schedule(void) {
ffffffffc0206192:	1141                	addi	sp,sp,-16
ffffffffc0206194:	e406                	sd	ra,8(sp)
ffffffffc0206196:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0206198:	100027f3          	csrr	a5,sstatus
ffffffffc020619c:	8b89                	andi	a5,a5,2
ffffffffc020619e:	4401                	li	s0,0
ffffffffc02061a0:	efbd                	bnez	a5,ffffffffc020621e <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02061a2:	00098897          	auipc	a7,0x98
ffffffffc02061a6:	b5e8b883          	ld	a7,-1186(a7) # ffffffffc029dd00 <current>
ffffffffc02061aa:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02061ae:	00098517          	auipc	a0,0x98
ffffffffc02061b2:	b6253503          	ld	a0,-1182(a0) # ffffffffc029dd10 <idleproc>
ffffffffc02061b6:	04a88e63          	beq	a7,a0,ffffffffc0206212 <schedule+0x80>
ffffffffc02061ba:	0c888693          	addi	a3,a7,200
ffffffffc02061be:	00098617          	auipc	a2,0x98
ffffffffc02061c2:	ab260613          	addi	a2,a2,-1358 # ffffffffc029dc70 <proc_list>
        le = last;
ffffffffc02061c6:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02061c8:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02061ca:	4809                	li	a6,2
ffffffffc02061cc:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc02061ce:	00c78863          	beq	a5,a2,ffffffffc02061de <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc02061d2:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02061d6:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc02061da:	03070163          	beq	a4,a6,ffffffffc02061fc <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc02061de:	fef697e3          	bne	a3,a5,ffffffffc02061cc <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02061e2:	ed89                	bnez	a1,ffffffffc02061fc <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc02061e4:	451c                	lw	a5,8(a0)
ffffffffc02061e6:	2785                	addiw	a5,a5,1
ffffffffc02061e8:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc02061ea:	00a88463          	beq	a7,a0,ffffffffc02061f2 <schedule+0x60>
            proc_run(next);
ffffffffc02061ee:	d51fe0ef          	jal	ffffffffc0204f3e <proc_run>
    if (flag) {
ffffffffc02061f2:	e819                	bnez	s0,ffffffffc0206208 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02061f4:	60a2                	ld	ra,8(sp)
ffffffffc02061f6:	6402                	ld	s0,0(sp)
ffffffffc02061f8:	0141                	addi	sp,sp,16
ffffffffc02061fa:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02061fc:	4198                	lw	a4,0(a1)
ffffffffc02061fe:	4789                	li	a5,2
ffffffffc0206200:	fef712e3          	bne	a4,a5,ffffffffc02061e4 <schedule+0x52>
ffffffffc0206204:	852e                	mv	a0,a1
ffffffffc0206206:	bff9                	j	ffffffffc02061e4 <schedule+0x52>
}
ffffffffc0206208:	6402                	ld	s0,0(sp)
ffffffffc020620a:	60a2                	ld	ra,8(sp)
ffffffffc020620c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020620e:	c2cfa06f          	j	ffffffffc020063a <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0206212:	00098617          	auipc	a2,0x98
ffffffffc0206216:	a5e60613          	addi	a2,a2,-1442 # ffffffffc029dc70 <proc_list>
ffffffffc020621a:	86b2                	mv	a3,a2
ffffffffc020621c:	b76d                	j	ffffffffc02061c6 <schedule+0x34>
        intr_disable();
ffffffffc020621e:	c22fa0ef          	jal	ffffffffc0200640 <intr_disable>
        return 1;
ffffffffc0206222:	4405                	li	s0,1
ffffffffc0206224:	bfbd                	j	ffffffffc02061a2 <schedule+0x10>

ffffffffc0206226 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0206226:	00098797          	auipc	a5,0x98
ffffffffc020622a:	ada7b783          	ld	a5,-1318(a5) # ffffffffc029dd00 <current>
}
ffffffffc020622e:	43c8                	lw	a0,4(a5)
ffffffffc0206230:	8082                	ret

ffffffffc0206232 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0206232:	4501                	li	a0,0
ffffffffc0206234:	8082                	ret

ffffffffc0206236 <sys_putc>:
    cputchar(c);
ffffffffc0206236:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0206238:	1141                	addi	sp,sp,-16
ffffffffc020623a:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020623c:	f79f90ef          	jal	ffffffffc02001b4 <cputchar>
}
ffffffffc0206240:	60a2                	ld	ra,8(sp)
ffffffffc0206242:	4501                	li	a0,0
ffffffffc0206244:	0141                	addi	sp,sp,16
ffffffffc0206246:	8082                	ret

ffffffffc0206248 <sys_kill>:
    return do_kill(pid);
ffffffffc0206248:	4108                	lw	a0,0(a0)
ffffffffc020624a:	c13ff06f          	j	ffffffffc0205e5c <do_kill>

ffffffffc020624e <sys_yield>:
    return do_yield();
ffffffffc020624e:	bbfff06f          	j	ffffffffc0205e0c <do_yield>

ffffffffc0206252 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0206252:	6d14                	ld	a3,24(a0)
ffffffffc0206254:	6910                	ld	a2,16(a0)
ffffffffc0206256:	650c                	ld	a1,8(a0)
ffffffffc0206258:	6108                	ld	a0,0(a0)
ffffffffc020625a:	e30ff06f          	j	ffffffffc020588a <do_execve>

ffffffffc020625e <sys_wait>:
    return do_wait(pid, store);
ffffffffc020625e:	650c                	ld	a1,8(a0)
ffffffffc0206260:	4108                	lw	a0,0(a0)
ffffffffc0206262:	bbbff06f          	j	ffffffffc0205e1c <do_wait>

ffffffffc0206266 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0206266:	00098797          	auipc	a5,0x98
ffffffffc020626a:	a9a7b783          	ld	a5,-1382(a5) # ffffffffc029dd00 <current>
ffffffffc020626e:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0206270:	4501                	li	a0,0
ffffffffc0206272:	6a0c                	ld	a1,16(a2)
ffffffffc0206274:	d37fe06f          	j	ffffffffc0204faa <do_fork>

ffffffffc0206278 <sys_exit>:
    return do_exit(error_code);
ffffffffc0206278:	4108                	lw	a0,0(a0)
ffffffffc020627a:	9bcff06f          	j	ffffffffc0205436 <do_exit>

ffffffffc020627e <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020627e:	715d                	addi	sp,sp,-80
ffffffffc0206280:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0206282:	00098497          	auipc	s1,0x98
ffffffffc0206286:	a7e48493          	addi	s1,s1,-1410 # ffffffffc029dd00 <current>
ffffffffc020628a:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020628c:	e0a2                	sd	s0,64(sp)
ffffffffc020628e:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0206290:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0206292:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0206294:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0206296:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020629a:	0327ee63          	bltu	a5,s2,ffffffffc02062d6 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc020629e:	00391713          	slli	a4,s2,0x3
ffffffffc02062a2:	00003797          	auipc	a5,0x3
ffffffffc02062a6:	8ee78793          	addi	a5,a5,-1810 # ffffffffc0208b90 <syscalls>
ffffffffc02062aa:	97ba                	add	a5,a5,a4
ffffffffc02062ac:	639c                	ld	a5,0(a5)
ffffffffc02062ae:	c785                	beqz	a5,ffffffffc02062d6 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02062b0:	7028                	ld	a0,96(s0)
ffffffffc02062b2:	742c                	ld	a1,104(s0)
ffffffffc02062b4:	7834                	ld	a3,112(s0)
ffffffffc02062b6:	7c38                	ld	a4,120(s0)
ffffffffc02062b8:	6c30                	ld	a2,88(s0)
ffffffffc02062ba:	e82a                	sd	a0,16(sp)
ffffffffc02062bc:	ec2e                	sd	a1,24(sp)
ffffffffc02062be:	e432                	sd	a2,8(sp)
ffffffffc02062c0:	f036                	sd	a3,32(sp)
ffffffffc02062c2:	f43a                	sd	a4,40(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02062c4:	0028                	addi	a0,sp,8
ffffffffc02062c6:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02062c8:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02062ca:	e828                	sd	a0,80(s0)
}
ffffffffc02062cc:	6406                	ld	s0,64(sp)
ffffffffc02062ce:	74e2                	ld	s1,56(sp)
ffffffffc02062d0:	7942                	ld	s2,48(sp)
ffffffffc02062d2:	6161                	addi	sp,sp,80
ffffffffc02062d4:	8082                	ret
    print_trapframe(tf);
ffffffffc02062d6:	8522                	mv	a0,s0
ffffffffc02062d8:	d58fa0ef          	jal	ffffffffc0200830 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02062dc:	609c                	ld	a5,0(s1)
ffffffffc02062de:	86ca                	mv	a3,s2
ffffffffc02062e0:	00002617          	auipc	a2,0x2
ffffffffc02062e4:	68860613          	addi	a2,a2,1672 # ffffffffc0208968 <etext+0x21ac>
ffffffffc02062e8:	43d8                	lw	a4,4(a5)
ffffffffc02062ea:	06200593          	li	a1,98
ffffffffc02062ee:	0b478793          	addi	a5,a5,180
ffffffffc02062f2:	00002517          	auipc	a0,0x2
ffffffffc02062f6:	6a650513          	addi	a0,a0,1702 # ffffffffc0208998 <etext+0x21dc>
ffffffffc02062fa:	97afa0ef          	jal	ffffffffc0200474 <__panic>

ffffffffc02062fe <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02062fe:	9e3707b7          	lui	a5,0x9e370
ffffffffc0206302:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_exit_out_size+0xffffffff9e366499>
ffffffffc0206304:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc0206308:	02000513          	li	a0,32
ffffffffc020630c:	9d0d                	subw	a0,a0,a1
}
ffffffffc020630e:	00a7d53b          	srlw	a0,a5,a0
ffffffffc0206312:	8082                	ret

ffffffffc0206314 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0206314:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206318:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020631a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020631e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0206320:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206324:	f022                	sd	s0,32(sp)
ffffffffc0206326:	ec26                	sd	s1,24(sp)
ffffffffc0206328:	e84a                	sd	s2,16(sp)
ffffffffc020632a:	f406                	sd	ra,40(sp)
ffffffffc020632c:	84aa                	mv	s1,a0
ffffffffc020632e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206330:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0206334:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0206336:	05067063          	bgeu	a2,a6,ffffffffc0206376 <printnum+0x62>
ffffffffc020633a:	e44e                	sd	s3,8(sp)
ffffffffc020633c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020633e:	4785                	li	a5,1
ffffffffc0206340:	00e7d763          	bge	a5,a4,ffffffffc020634e <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0206344:	85ca                	mv	a1,s2
ffffffffc0206346:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0206348:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020634a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020634c:	fc65                	bnez	s0,ffffffffc0206344 <printnum+0x30>
ffffffffc020634e:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206350:	1a02                	slli	s4,s4,0x20
ffffffffc0206352:	020a5a13          	srli	s4,s4,0x20
ffffffffc0206356:	00002797          	auipc	a5,0x2
ffffffffc020635a:	65a78793          	addi	a5,a5,1626 # ffffffffc02089b0 <etext+0x21f4>
ffffffffc020635e:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0206360:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206362:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0206366:	70a2                	ld	ra,40(sp)
ffffffffc0206368:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020636a:	85ca                	mv	a1,s2
ffffffffc020636c:	87a6                	mv	a5,s1
}
ffffffffc020636e:	6942                	ld	s2,16(sp)
ffffffffc0206370:	64e2                	ld	s1,24(sp)
ffffffffc0206372:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206374:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0206376:	03065633          	divu	a2,a2,a6
ffffffffc020637a:	8722                	mv	a4,s0
ffffffffc020637c:	f99ff0ef          	jal	ffffffffc0206314 <printnum>
ffffffffc0206380:	bfc1                	j	ffffffffc0206350 <printnum+0x3c>

ffffffffc0206382 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0206382:	7119                	addi	sp,sp,-128
ffffffffc0206384:	f4a6                	sd	s1,104(sp)
ffffffffc0206386:	f0ca                	sd	s2,96(sp)
ffffffffc0206388:	ecce                	sd	s3,88(sp)
ffffffffc020638a:	e8d2                	sd	s4,80(sp)
ffffffffc020638c:	e4d6                	sd	s5,72(sp)
ffffffffc020638e:	e0da                	sd	s6,64(sp)
ffffffffc0206390:	f862                	sd	s8,48(sp)
ffffffffc0206392:	fc86                	sd	ra,120(sp)
ffffffffc0206394:	f8a2                	sd	s0,112(sp)
ffffffffc0206396:	fc5e                	sd	s7,56(sp)
ffffffffc0206398:	f466                	sd	s9,40(sp)
ffffffffc020639a:	f06a                	sd	s10,32(sp)
ffffffffc020639c:	ec6e                	sd	s11,24(sp)
ffffffffc020639e:	892a                	mv	s2,a0
ffffffffc02063a0:	84ae                	mv	s1,a1
ffffffffc02063a2:	8c32                	mv	s8,a2
ffffffffc02063a4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02063a6:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063aa:	05500b13          	li	s6,85
ffffffffc02063ae:	00003a97          	auipc	s5,0x3
ffffffffc02063b2:	8e2a8a93          	addi	s5,s5,-1822 # ffffffffc0208c90 <syscalls+0x100>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02063b6:	000c4503          	lbu	a0,0(s8)
ffffffffc02063ba:	001c0413          	addi	s0,s8,1
ffffffffc02063be:	01350a63          	beq	a0,s3,ffffffffc02063d2 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02063c2:	cd0d                	beqz	a0,ffffffffc02063fc <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02063c4:	85a6                	mv	a1,s1
ffffffffc02063c6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02063c8:	00044503          	lbu	a0,0(s0)
ffffffffc02063cc:	0405                	addi	s0,s0,1
ffffffffc02063ce:	ff351ae3          	bne	a0,s3,ffffffffc02063c2 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc02063d2:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02063d6:	4b81                	li	s7,0
ffffffffc02063d8:	4601                	li	a2,0
        width = precision = -1;
ffffffffc02063da:	5d7d                	li	s10,-1
ffffffffc02063dc:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063de:	00044683          	lbu	a3,0(s0)
ffffffffc02063e2:	00140c13          	addi	s8,s0,1
ffffffffc02063e6:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02063ea:	0ff5f593          	zext.b	a1,a1
ffffffffc02063ee:	02bb6663          	bltu	s6,a1,ffffffffc020641a <vprintfmt+0x98>
ffffffffc02063f2:	058a                	slli	a1,a1,0x2
ffffffffc02063f4:	95d6                	add	a1,a1,s5
ffffffffc02063f6:	4198                	lw	a4,0(a1)
ffffffffc02063f8:	9756                	add	a4,a4,s5
ffffffffc02063fa:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02063fc:	70e6                	ld	ra,120(sp)
ffffffffc02063fe:	7446                	ld	s0,112(sp)
ffffffffc0206400:	74a6                	ld	s1,104(sp)
ffffffffc0206402:	7906                	ld	s2,96(sp)
ffffffffc0206404:	69e6                	ld	s3,88(sp)
ffffffffc0206406:	6a46                	ld	s4,80(sp)
ffffffffc0206408:	6aa6                	ld	s5,72(sp)
ffffffffc020640a:	6b06                	ld	s6,64(sp)
ffffffffc020640c:	7be2                	ld	s7,56(sp)
ffffffffc020640e:	7c42                	ld	s8,48(sp)
ffffffffc0206410:	7ca2                	ld	s9,40(sp)
ffffffffc0206412:	7d02                	ld	s10,32(sp)
ffffffffc0206414:	6de2                	ld	s11,24(sp)
ffffffffc0206416:	6109                	addi	sp,sp,128
ffffffffc0206418:	8082                	ret
            putch('%', putdat);
ffffffffc020641a:	85a6                	mv	a1,s1
ffffffffc020641c:	02500513          	li	a0,37
ffffffffc0206420:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0206422:	fff44703          	lbu	a4,-1(s0)
ffffffffc0206426:	02500793          	li	a5,37
ffffffffc020642a:	8c22                	mv	s8,s0
ffffffffc020642c:	f8f705e3          	beq	a4,a5,ffffffffc02063b6 <vprintfmt+0x34>
ffffffffc0206430:	02500713          	li	a4,37
ffffffffc0206434:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0206438:	1c7d                	addi	s8,s8,-1
ffffffffc020643a:	fee79de3          	bne	a5,a4,ffffffffc0206434 <vprintfmt+0xb2>
ffffffffc020643e:	bfa5                	j	ffffffffc02063b6 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0206440:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0206444:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0206446:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc020644a:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc020644e:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206452:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0206454:	02b76563          	bltu	a4,a1,ffffffffc020647e <vprintfmt+0xfc>
ffffffffc0206458:	4525                	li	a0,9
                ch = *fmt;
ffffffffc020645a:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020645e:	002d171b          	slliw	a4,s10,0x2
ffffffffc0206462:	01a7073b          	addw	a4,a4,s10
ffffffffc0206466:	0017171b          	slliw	a4,a4,0x1
ffffffffc020646a:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc020646c:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0206470:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0206472:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0206476:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc020647a:	feb570e3          	bgeu	a0,a1,ffffffffc020645a <vprintfmt+0xd8>
            if (width < 0)
ffffffffc020647e:	f60cd0e3          	bgez	s9,ffffffffc02063de <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0206482:	8cea                	mv	s9,s10
ffffffffc0206484:	5d7d                	li	s10,-1
ffffffffc0206486:	bfa1                	j	ffffffffc02063de <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206488:	8db6                	mv	s11,a3
ffffffffc020648a:	8462                	mv	s0,s8
ffffffffc020648c:	bf89                	j	ffffffffc02063de <vprintfmt+0x5c>
ffffffffc020648e:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0206490:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0206492:	b7b1                	j	ffffffffc02063de <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0206494:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0206496:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc020649a:	00c7c463          	blt	a5,a2,ffffffffc02064a2 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc020649e:	1a060163          	beqz	a2,ffffffffc0206640 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc02064a2:	000a3603          	ld	a2,0(s4)
ffffffffc02064a6:	46c1                	li	a3,16
ffffffffc02064a8:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02064aa:	000d879b          	sext.w	a5,s11
ffffffffc02064ae:	8766                	mv	a4,s9
ffffffffc02064b0:	85a6                	mv	a1,s1
ffffffffc02064b2:	854a                	mv	a0,s2
ffffffffc02064b4:	e61ff0ef          	jal	ffffffffc0206314 <printnum>
            break;
ffffffffc02064b8:	bdfd                	j	ffffffffc02063b6 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc02064ba:	000a2503          	lw	a0,0(s4)
ffffffffc02064be:	85a6                	mv	a1,s1
ffffffffc02064c0:	0a21                	addi	s4,s4,8
ffffffffc02064c2:	9902                	jalr	s2
            break;
ffffffffc02064c4:	bdcd                	j	ffffffffc02063b6 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02064c6:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02064c8:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc02064cc:	00c7c463          	blt	a5,a2,ffffffffc02064d4 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc02064d0:	16060363          	beqz	a2,ffffffffc0206636 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc02064d4:	000a3603          	ld	a2,0(s4)
ffffffffc02064d8:	46a9                	li	a3,10
ffffffffc02064da:	8a3a                	mv	s4,a4
ffffffffc02064dc:	b7f9                	j	ffffffffc02064aa <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc02064de:	85a6                	mv	a1,s1
ffffffffc02064e0:	03000513          	li	a0,48
ffffffffc02064e4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02064e6:	85a6                	mv	a1,s1
ffffffffc02064e8:	07800513          	li	a0,120
ffffffffc02064ec:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02064ee:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02064f2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02064f4:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02064f6:	bf55                	j	ffffffffc02064aa <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc02064f8:	85a6                	mv	a1,s1
ffffffffc02064fa:	02500513          	li	a0,37
ffffffffc02064fe:	9902                	jalr	s2
            break;
ffffffffc0206500:	bd5d                	j	ffffffffc02063b6 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0206502:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206506:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0206508:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc020650a:	bf95                	j	ffffffffc020647e <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc020650c:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020650e:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0206512:	00c7c463          	blt	a5,a2,ffffffffc020651a <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0206516:	10060b63          	beqz	a2,ffffffffc020662c <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc020651a:	000a3603          	ld	a2,0(s4)
ffffffffc020651e:	46a1                	li	a3,8
ffffffffc0206520:	8a3a                	mv	s4,a4
ffffffffc0206522:	b761                	j	ffffffffc02064aa <vprintfmt+0x128>
            if (width < 0)
ffffffffc0206524:	fffcc793          	not	a5,s9
ffffffffc0206528:	97fd                	srai	a5,a5,0x3f
ffffffffc020652a:	00fcf7b3          	and	a5,s9,a5
ffffffffc020652e:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206532:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0206534:	b56d                	j	ffffffffc02063de <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206536:	000a3403          	ld	s0,0(s4)
ffffffffc020653a:	008a0793          	addi	a5,s4,8
ffffffffc020653e:	e43e                	sd	a5,8(sp)
ffffffffc0206540:	12040063          	beqz	s0,ffffffffc0206660 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0206544:	0d905963          	blez	s9,ffffffffc0206616 <vprintfmt+0x294>
ffffffffc0206548:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020654c:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0206550:	12fd9763          	bne	s11,a5,ffffffffc020667e <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206554:	00044783          	lbu	a5,0(s0)
ffffffffc0206558:	0007851b          	sext.w	a0,a5
ffffffffc020655c:	cb9d                	beqz	a5,ffffffffc0206592 <vprintfmt+0x210>
ffffffffc020655e:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206560:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206564:	000d4563          	bltz	s10,ffffffffc020656e <vprintfmt+0x1ec>
ffffffffc0206568:	3d7d                	addiw	s10,s10,-1
ffffffffc020656a:	028d0263          	beq	s10,s0,ffffffffc020658e <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc020656e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206570:	0c0b8d63          	beqz	s7,ffffffffc020664a <vprintfmt+0x2c8>
ffffffffc0206574:	3781                	addiw	a5,a5,-32
ffffffffc0206576:	0cfdfa63          	bgeu	s11,a5,ffffffffc020664a <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc020657a:	03f00513          	li	a0,63
ffffffffc020657e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206580:	000a4783          	lbu	a5,0(s4)
ffffffffc0206584:	3cfd                	addiw	s9,s9,-1
ffffffffc0206586:	0a05                	addi	s4,s4,1
ffffffffc0206588:	0007851b          	sext.w	a0,a5
ffffffffc020658c:	ffe1                	bnez	a5,ffffffffc0206564 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc020658e:	01905963          	blez	s9,ffffffffc02065a0 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0206592:	85a6                	mv	a1,s1
ffffffffc0206594:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0206598:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc020659a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020659c:	fe0c9be3          	bnez	s9,ffffffffc0206592 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02065a0:	6a22                	ld	s4,8(sp)
ffffffffc02065a2:	bd11                	j	ffffffffc02063b6 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02065a4:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02065a6:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02065aa:	00c7c363          	blt	a5,a2,ffffffffc02065b0 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc02065ae:	ce25                	beqz	a2,ffffffffc0206626 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc02065b0:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02065b4:	08044d63          	bltz	s0,ffffffffc020664e <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02065b8:	8622                	mv	a2,s0
ffffffffc02065ba:	8a5e                	mv	s4,s7
ffffffffc02065bc:	46a9                	li	a3,10
ffffffffc02065be:	b5f5                	j	ffffffffc02064aa <vprintfmt+0x128>
            if (err < 0) {
ffffffffc02065c0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02065c4:	4661                	li	a2,24
            if (err < 0) {
ffffffffc02065c6:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02065ca:	8fb9                	xor	a5,a5,a4
ffffffffc02065cc:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02065d0:	02d64663          	blt	a2,a3,ffffffffc02065fc <vprintfmt+0x27a>
ffffffffc02065d4:	00369713          	slli	a4,a3,0x3
ffffffffc02065d8:	00003797          	auipc	a5,0x3
ffffffffc02065dc:	81078793          	addi	a5,a5,-2032 # ffffffffc0208de8 <error_string>
ffffffffc02065e0:	97ba                	add	a5,a5,a4
ffffffffc02065e2:	639c                	ld	a5,0(a5)
ffffffffc02065e4:	cf81                	beqz	a5,ffffffffc02065fc <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02065e6:	86be                	mv	a3,a5
ffffffffc02065e8:	00000617          	auipc	a2,0x0
ffffffffc02065ec:	20060613          	addi	a2,a2,512 # ffffffffc02067e8 <etext+0x2c>
ffffffffc02065f0:	85a6                	mv	a1,s1
ffffffffc02065f2:	854a                	mv	a0,s2
ffffffffc02065f4:	0e8000ef          	jal	ffffffffc02066dc <printfmt>
            err = va_arg(ap, int);
ffffffffc02065f8:	0a21                	addi	s4,s4,8
ffffffffc02065fa:	bb75                	j	ffffffffc02063b6 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02065fc:	00002617          	auipc	a2,0x2
ffffffffc0206600:	3d460613          	addi	a2,a2,980 # ffffffffc02089d0 <etext+0x2214>
ffffffffc0206604:	85a6                	mv	a1,s1
ffffffffc0206606:	854a                	mv	a0,s2
ffffffffc0206608:	0d4000ef          	jal	ffffffffc02066dc <printfmt>
            err = va_arg(ap, int);
ffffffffc020660c:	0a21                	addi	s4,s4,8
ffffffffc020660e:	b365                	j	ffffffffc02063b6 <vprintfmt+0x34>
            lflag ++;
ffffffffc0206610:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206612:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0206614:	b3e9                	j	ffffffffc02063de <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206616:	00044783          	lbu	a5,0(s0)
ffffffffc020661a:	0007851b          	sext.w	a0,a5
ffffffffc020661e:	d3c9                	beqz	a5,ffffffffc02065a0 <vprintfmt+0x21e>
ffffffffc0206620:	00140a13          	addi	s4,s0,1
ffffffffc0206624:	bf2d                	j	ffffffffc020655e <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0206626:	000a2403          	lw	s0,0(s4)
ffffffffc020662a:	b769                	j	ffffffffc02065b4 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc020662c:	000a6603          	lwu	a2,0(s4)
ffffffffc0206630:	46a1                	li	a3,8
ffffffffc0206632:	8a3a                	mv	s4,a4
ffffffffc0206634:	bd9d                	j	ffffffffc02064aa <vprintfmt+0x128>
ffffffffc0206636:	000a6603          	lwu	a2,0(s4)
ffffffffc020663a:	46a9                	li	a3,10
ffffffffc020663c:	8a3a                	mv	s4,a4
ffffffffc020663e:	b5b5                	j	ffffffffc02064aa <vprintfmt+0x128>
ffffffffc0206640:	000a6603          	lwu	a2,0(s4)
ffffffffc0206644:	46c1                	li	a3,16
ffffffffc0206646:	8a3a                	mv	s4,a4
ffffffffc0206648:	b58d                	j	ffffffffc02064aa <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc020664a:	9902                	jalr	s2
ffffffffc020664c:	bf15                	j	ffffffffc0206580 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc020664e:	85a6                	mv	a1,s1
ffffffffc0206650:	02d00513          	li	a0,45
ffffffffc0206654:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0206656:	40800633          	neg	a2,s0
ffffffffc020665a:	8a5e                	mv	s4,s7
ffffffffc020665c:	46a9                	li	a3,10
ffffffffc020665e:	b5b1                	j	ffffffffc02064aa <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0206660:	01905663          	blez	s9,ffffffffc020666c <vprintfmt+0x2ea>
ffffffffc0206664:	02d00793          	li	a5,45
ffffffffc0206668:	04fd9263          	bne	s11,a5,ffffffffc02066ac <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020666c:	02800793          	li	a5,40
ffffffffc0206670:	00002a17          	auipc	s4,0x2
ffffffffc0206674:	359a0a13          	addi	s4,s4,857 # ffffffffc02089c9 <etext+0x220d>
ffffffffc0206678:	02800513          	li	a0,40
ffffffffc020667c:	b5cd                	j	ffffffffc020655e <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020667e:	85ea                	mv	a1,s10
ffffffffc0206680:	8522                	mv	a0,s0
ffffffffc0206682:	094000ef          	jal	ffffffffc0206716 <strnlen>
ffffffffc0206686:	40ac8cbb          	subw	s9,s9,a0
ffffffffc020668a:	01905963          	blez	s9,ffffffffc020669c <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc020668e:	2d81                	sext.w	s11,s11
ffffffffc0206690:	85a6                	mv	a1,s1
ffffffffc0206692:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206694:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0206696:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206698:	fe0c9ce3          	bnez	s9,ffffffffc0206690 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020669c:	00044783          	lbu	a5,0(s0)
ffffffffc02066a0:	0007851b          	sext.w	a0,a5
ffffffffc02066a4:	ea079de3          	bnez	a5,ffffffffc020655e <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02066a8:	6a22                	ld	s4,8(sp)
ffffffffc02066aa:	b331                	j	ffffffffc02063b6 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02066ac:	85ea                	mv	a1,s10
ffffffffc02066ae:	00002517          	auipc	a0,0x2
ffffffffc02066b2:	31a50513          	addi	a0,a0,794 # ffffffffc02089c8 <etext+0x220c>
ffffffffc02066b6:	060000ef          	jal	ffffffffc0206716 <strnlen>
ffffffffc02066ba:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc02066be:	00002417          	auipc	s0,0x2
ffffffffc02066c2:	30a40413          	addi	s0,s0,778 # ffffffffc02089c8 <etext+0x220c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02066c6:	00002a17          	auipc	s4,0x2
ffffffffc02066ca:	303a0a13          	addi	s4,s4,771 # ffffffffc02089c9 <etext+0x220d>
ffffffffc02066ce:	02800793          	li	a5,40
ffffffffc02066d2:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02066d6:	fb904ce3          	bgtz	s9,ffffffffc020668e <vprintfmt+0x30c>
ffffffffc02066da:	b551                	j	ffffffffc020655e <vprintfmt+0x1dc>

ffffffffc02066dc <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02066dc:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02066de:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02066e2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02066e4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02066e6:	ec06                	sd	ra,24(sp)
ffffffffc02066e8:	f83a                	sd	a4,48(sp)
ffffffffc02066ea:	fc3e                	sd	a5,56(sp)
ffffffffc02066ec:	e0c2                	sd	a6,64(sp)
ffffffffc02066ee:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02066f0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02066f2:	c91ff0ef          	jal	ffffffffc0206382 <vprintfmt>
}
ffffffffc02066f6:	60e2                	ld	ra,24(sp)
ffffffffc02066f8:	6161                	addi	sp,sp,80
ffffffffc02066fa:	8082                	ret

ffffffffc02066fc <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02066fc:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0206700:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0206702:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0206704:	cb81                	beqz	a5,ffffffffc0206714 <strlen+0x18>
        cnt ++;
ffffffffc0206706:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0206708:	00a707b3          	add	a5,a4,a0
ffffffffc020670c:	0007c783          	lbu	a5,0(a5)
ffffffffc0206710:	fbfd                	bnez	a5,ffffffffc0206706 <strlen+0xa>
ffffffffc0206712:	8082                	ret
    }
    return cnt;
}
ffffffffc0206714:	8082                	ret

ffffffffc0206716 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0206716:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206718:	e589                	bnez	a1,ffffffffc0206722 <strnlen+0xc>
ffffffffc020671a:	a811                	j	ffffffffc020672e <strnlen+0x18>
        cnt ++;
ffffffffc020671c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020671e:	00f58863          	beq	a1,a5,ffffffffc020672e <strnlen+0x18>
ffffffffc0206722:	00f50733          	add	a4,a0,a5
ffffffffc0206726:	00074703          	lbu	a4,0(a4)
ffffffffc020672a:	fb6d                	bnez	a4,ffffffffc020671c <strnlen+0x6>
ffffffffc020672c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020672e:	852e                	mv	a0,a1
ffffffffc0206730:	8082                	ret

ffffffffc0206732 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0206732:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0206734:	0005c703          	lbu	a4,0(a1)
ffffffffc0206738:	0785                	addi	a5,a5,1
ffffffffc020673a:	0585                	addi	a1,a1,1
ffffffffc020673c:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0206740:	fb75                	bnez	a4,ffffffffc0206734 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0206742:	8082                	ret

ffffffffc0206744 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206744:	00054783          	lbu	a5,0(a0)
ffffffffc0206748:	e791                	bnez	a5,ffffffffc0206754 <strcmp+0x10>
ffffffffc020674a:	a02d                	j	ffffffffc0206774 <strcmp+0x30>
ffffffffc020674c:	00054783          	lbu	a5,0(a0)
ffffffffc0206750:	cf89                	beqz	a5,ffffffffc020676a <strcmp+0x26>
ffffffffc0206752:	85b6                	mv	a1,a3
ffffffffc0206754:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0206758:	0505                	addi	a0,a0,1
ffffffffc020675a:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020675e:	fef707e3          	beq	a4,a5,ffffffffc020674c <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206762:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0206766:	9d19                	subw	a0,a0,a4
ffffffffc0206768:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020676a:	0015c703          	lbu	a4,1(a1)
ffffffffc020676e:	4501                	li	a0,0
}
ffffffffc0206770:	9d19                	subw	a0,a0,a4
ffffffffc0206772:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206774:	0005c703          	lbu	a4,0(a1)
ffffffffc0206778:	4501                	li	a0,0
ffffffffc020677a:	b7f5                	j	ffffffffc0206766 <strcmp+0x22>

ffffffffc020677c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020677c:	00054783          	lbu	a5,0(a0)
ffffffffc0206780:	c799                	beqz	a5,ffffffffc020678e <strchr+0x12>
        if (*s == c) {
ffffffffc0206782:	00f58763          	beq	a1,a5,ffffffffc0206790 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0206786:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020678a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020678c:	fbfd                	bnez	a5,ffffffffc0206782 <strchr+0x6>
    }
    return NULL;
ffffffffc020678e:	4501                	li	a0,0
}
ffffffffc0206790:	8082                	ret

ffffffffc0206792 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0206792:	ca01                	beqz	a2,ffffffffc02067a2 <memset+0x10>
ffffffffc0206794:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0206796:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0206798:	0785                	addi	a5,a5,1
ffffffffc020679a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020679e:	fef61de3          	bne	a2,a5,ffffffffc0206798 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02067a2:	8082                	ret

ffffffffc02067a4 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02067a4:	ca19                	beqz	a2,ffffffffc02067ba <memcpy+0x16>
ffffffffc02067a6:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02067a8:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02067aa:	0005c703          	lbu	a4,0(a1)
ffffffffc02067ae:	0585                	addi	a1,a1,1
ffffffffc02067b0:	0785                	addi	a5,a5,1
ffffffffc02067b2:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02067b6:	feb61ae3          	bne	a2,a1,ffffffffc02067aa <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02067ba:	8082                	ret
