
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c. 这个机制的实现方式是通过写了一个c语言的页表，entry_pgdir，
	# 这个手写的页表可以自动的把[0xf0000000-0xf0400000]这4MB的虚拟地址空间映射为[0x00000000-0x00400000]的物理地址空间。可见这个页表的映射能力还是比较有限的，只能映射一个区域
	movl	$(RELOC(entry_pgdir)), %eax # 第1句，它的功能是把entry_pgdir这个页表的起始物理地址送给%eax，这里RELOC宏的功能是计算输入参数的物理地址
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3 # 第2句，把entry_pgdir这个页表的起始地址传送给寄存器%cr3。
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	# PE Protected Mode Enable PG Paging WP Write protect
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0
	# 第3~5句，修改cr0寄存器的值，把cr0的PE位，PG位, WP位都置位1。其中PE位是启用保护标识位，如果被置1代表将会运行在保护模式下。PG位是分页标识位，如果这一位被置1，则代表开启了分页机制。WP位是写保护标识，如果被置位为1，则处理器会禁止超级用户程序向用户级只读页面执行写操作。
	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code. 然后下面两条指令就把当前运行程序的地址空间提高到[0xf0000000-0xf0400000]范围内
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
	# 这两个指令分别设置了%ebp，%esp两个寄存器的值。其中%ebp被修改为0。%esp则被修改为bootstacktop的值。这个值为0xf0110000。
	# 另外在entry.S的末尾还定义了一个值，bootstack。注意，在数据段中定义栈顶bootstacktop之前，首先分配了KSTKSIZE这么多的存储空间，专门用于堆栈，这个KSTKSIZE = 8 * PGSIZE  = 8 * 4096 = 32KB。所以用于堆栈的地址空间为 0xf0108000-0xf0110000，其中栈顶指针指向0xf0110000. 那么这个堆栈实际坐落在内存的 0x00108000-0x00110000物理地址空间中
	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 68 00 00 00       	call   f01000a6 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/pmap.h>
#include <kern/kclock.h>

void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	e8 6b 01 00 00       	call   f01001b5 <__x86.get_pc_thunk.bx>
f010004a:	81 c3 c2 72 01 00    	add    $0x172c2,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 34 cf fe ff    	lea    -0x130cc(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 85 31 00 00       	call   f01031e8 <cprintf>
	if (x > 0)
f0100063:	83 c4 10             	add    $0x10,%esp
f0100066:	85 f6                	test   %esi,%esi
f0100068:	7f 2b                	jg     f0100095 <test_backtrace+0x55>
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
f010006a:	83 ec 04             	sub    $0x4,%esp
f010006d:	6a 00                	push   $0x0
f010006f:	6a 00                	push   $0x0
f0100071:	6a 00                	push   $0x0
f0100073:	e8 1b 08 00 00       	call   f0100893 <mon_backtrace>
f0100078:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007b:	83 ec 08             	sub    $0x8,%esp
f010007e:	56                   	push   %esi
f010007f:	8d 83 50 cf fe ff    	lea    -0x130b0(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 5d 31 00 00       	call   f01031e8 <cprintf>
}
f010008b:	83 c4 10             	add    $0x10,%esp
f010008e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100091:	5b                   	pop    %ebx
f0100092:	5e                   	pop    %esi
f0100093:	5d                   	pop    %ebp
f0100094:	c3                   	ret    
		test_backtrace(x-1);
f0100095:	83 ec 0c             	sub    $0xc,%esp
f0100098:	8d 46 ff             	lea    -0x1(%esi),%eax
f010009b:	50                   	push   %eax
f010009c:	e8 9f ff ff ff       	call   f0100040 <test_backtrace>
f01000a1:	83 c4 10             	add    $0x10,%esp
f01000a4:	eb d5                	jmp    f010007b <test_backtrace+0x3b>

f01000a6 <i386_init>:

void
i386_init(void)
{
f01000a6:	55                   	push   %ebp
f01000a7:	89 e5                	mov    %esp,%ebp
f01000a9:	53                   	push   %ebx
f01000aa:	83 ec 08             	sub    $0x8,%esp
f01000ad:	e8 03 01 00 00       	call   f01001b5 <__x86.get_pc_thunk.bx>
f01000b2:	81 c3 5a 72 01 00    	add    $0x1725a,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000b8:	c7 c2 60 90 11 f0    	mov    $0xf0119060,%edx
f01000be:	c7 c0 c0 96 11 f0    	mov    $0xf01196c0,%eax
f01000c4:	29 d0                	sub    %edx,%eax
f01000c6:	50                   	push   %eax
f01000c7:	6a 00                	push   $0x0
f01000c9:	52                   	push   %edx
f01000ca:	e8 33 3d 00 00       	call   f0103e02 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 36 05 00 00       	call   f010060a <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 6b cf fe ff    	lea    -0x13095(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 00 31 00 00       	call   f01031e8 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	//test_backtrace(5);
	// Lab 2 memory management initialization functions
	mem_init();
f01000e8:	e8 5d 13 00 00       	call   f010144a <mem_init>
f01000ed:	83 c4 10             	add    $0x10,%esp
	

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000f0:	83 ec 0c             	sub    $0xc,%esp
f01000f3:	6a 00                	push   $0x0
f01000f5:	e8 7d 08 00 00       	call   f0100977 <monitor>
f01000fa:	83 c4 10             	add    $0x10,%esp
f01000fd:	eb f1                	jmp    f01000f0 <i386_init+0x4a>

f01000ff <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000ff:	55                   	push   %ebp
f0100100:	89 e5                	mov    %esp,%ebp
f0100102:	57                   	push   %edi
f0100103:	56                   	push   %esi
f0100104:	53                   	push   %ebx
f0100105:	83 ec 0c             	sub    $0xc,%esp
f0100108:	e8 a8 00 00 00       	call   f01001b5 <__x86.get_pc_thunk.bx>
f010010d:	81 c3 ff 71 01 00    	add    $0x171ff,%ebx
f0100113:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f0100116:	c7 c0 c4 96 11 f0    	mov    $0xf01196c4,%eax
f010011c:	83 38 00             	cmpl   $0x0,(%eax)
f010011f:	74 0f                	je     f0100130 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100121:	83 ec 0c             	sub    $0xc,%esp
f0100124:	6a 00                	push   $0x0
f0100126:	e8 4c 08 00 00       	call   f0100977 <monitor>
f010012b:	83 c4 10             	add    $0x10,%esp
f010012e:	eb f1                	jmp    f0100121 <_panic+0x22>
	panicstr = fmt;
f0100130:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f0100132:	fa                   	cli    
f0100133:	fc                   	cld    
	va_start(ap, fmt);
f0100134:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f0100137:	83 ec 04             	sub    $0x4,%esp
f010013a:	ff 75 0c             	pushl  0xc(%ebp)
f010013d:	ff 75 08             	pushl  0x8(%ebp)
f0100140:	8d 83 86 cf fe ff    	lea    -0x1307a(%ebx),%eax
f0100146:	50                   	push   %eax
f0100147:	e8 9c 30 00 00       	call   f01031e8 <cprintf>
	vcprintf(fmt, ap);
f010014c:	83 c4 08             	add    $0x8,%esp
f010014f:	56                   	push   %esi
f0100150:	57                   	push   %edi
f0100151:	e8 5b 30 00 00       	call   f01031b1 <vcprintf>
	cprintf("\n");
f0100156:	8d 83 3b d7 fe ff    	lea    -0x128c5(%ebx),%eax
f010015c:	89 04 24             	mov    %eax,(%esp)
f010015f:	e8 84 30 00 00       	call   f01031e8 <cprintf>
f0100164:	83 c4 10             	add    $0x10,%esp
f0100167:	eb b8                	jmp    f0100121 <_panic+0x22>

f0100169 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100169:	55                   	push   %ebp
f010016a:	89 e5                	mov    %esp,%ebp
f010016c:	56                   	push   %esi
f010016d:	53                   	push   %ebx
f010016e:	e8 42 00 00 00       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0100173:	81 c3 99 71 01 00    	add    $0x17199,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100179:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f010017c:	83 ec 04             	sub    $0x4,%esp
f010017f:	ff 75 0c             	pushl  0xc(%ebp)
f0100182:	ff 75 08             	pushl  0x8(%ebp)
f0100185:	8d 83 9e cf fe ff    	lea    -0x13062(%ebx),%eax
f010018b:	50                   	push   %eax
f010018c:	e8 57 30 00 00       	call   f01031e8 <cprintf>
	vcprintf(fmt, ap);
f0100191:	83 c4 08             	add    $0x8,%esp
f0100194:	56                   	push   %esi
f0100195:	ff 75 10             	pushl  0x10(%ebp)
f0100198:	e8 14 30 00 00       	call   f01031b1 <vcprintf>
	cprintf("\n");
f010019d:	8d 83 3b d7 fe ff    	lea    -0x128c5(%ebx),%eax
f01001a3:	89 04 24             	mov    %eax,(%esp)
f01001a6:	e8 3d 30 00 00       	call   f01031e8 <cprintf>
	va_end(ap);
}
f01001ab:	83 c4 10             	add    $0x10,%esp
f01001ae:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001b1:	5b                   	pop    %ebx
f01001b2:	5e                   	pop    %esi
f01001b3:	5d                   	pop    %ebp
f01001b4:	c3                   	ret    

f01001b5 <__x86.get_pc_thunk.bx>:
f01001b5:	8b 1c 24             	mov    (%esp),%ebx
f01001b8:	c3                   	ret    

f01001b9 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001b9:	55                   	push   %ebp
f01001ba:	89 e5                	mov    %esp,%ebp
//Receives a 8/16/32-bit value from an I/O location. Traditional names are inb, inw and inl respectively.
static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001bc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c1:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001c2:	a8 01                	test   $0x1,%al
f01001c4:	74 0b                	je     f01001d1 <serial_proc_data+0x18>
f01001c6:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001cb:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001cc:	0f b6 c0             	movzbl %al,%eax
}
f01001cf:	5d                   	pop    %ebp
f01001d0:	c3                   	ret    
		return -1;
f01001d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001d6:	eb f7                	jmp    f01001cf <serial_proc_data+0x16>

f01001d8 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001d8:	55                   	push   %ebp
f01001d9:	89 e5                	mov    %esp,%ebp
f01001db:	56                   	push   %esi
f01001dc:	53                   	push   %ebx
f01001dd:	e8 d3 ff ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f01001e2:	81 c3 2a 71 01 00    	add    $0x1712a,%ebx
f01001e8:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f01001ea:	ff d6                	call   *%esi
f01001ec:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ef:	74 2e                	je     f010021f <cons_intr+0x47>
		if (c == 0)
f01001f1:	85 c0                	test   %eax,%eax
f01001f3:	74 f5                	je     f01001ea <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01001f5:	8b 8b 78 1f 00 00    	mov    0x1f78(%ebx),%ecx
f01001fb:	8d 51 01             	lea    0x1(%ecx),%edx
f01001fe:	89 93 78 1f 00 00    	mov    %edx,0x1f78(%ebx)
f0100204:	88 84 0b 74 1d 00 00 	mov    %al,0x1d74(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f010020b:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100211:	75 d7                	jne    f01001ea <cons_intr+0x12>
			cons.wpos = 0;
f0100213:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010021a:	00 00 00 
f010021d:	eb cb                	jmp    f01001ea <cons_intr+0x12>
	}
}
f010021f:	5b                   	pop    %ebx
f0100220:	5e                   	pop    %esi
f0100221:	5d                   	pop    %ebp
f0100222:	c3                   	ret    

f0100223 <kbd_proc_data>:
{
f0100223:	55                   	push   %ebp
f0100224:	89 e5                	mov    %esp,%ebp
f0100226:	56                   	push   %esi
f0100227:	53                   	push   %ebx
f0100228:	e8 88 ff ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f010022d:	81 c3 df 70 01 00    	add    $0x170df,%ebx
f0100233:	ba 64 00 00 00       	mov    $0x64,%edx
f0100238:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100239:	a8 01                	test   $0x1,%al
f010023b:	0f 84 06 01 00 00    	je     f0100347 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f0100241:	a8 20                	test   $0x20,%al
f0100243:	0f 85 05 01 00 00    	jne    f010034e <kbd_proc_data+0x12b>
f0100249:	ba 60 00 00 00       	mov    $0x60,%edx
f010024e:	ec                   	in     (%dx),%al
f010024f:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100251:	3c e0                	cmp    $0xe0,%al
f0100253:	0f 84 93 00 00 00    	je     f01002ec <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f0100259:	84 c0                	test   %al,%al
f010025b:	0f 88 a0 00 00 00    	js     f0100301 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100261:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f0100267:	f6 c1 40             	test   $0x40,%cl
f010026a:	74 0e                	je     f010027a <kbd_proc_data+0x57>
		data |= 0x80;
f010026c:	83 c8 80             	or     $0xffffff80,%eax
f010026f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100271:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100274:	89 8b 54 1d 00 00    	mov    %ecx,0x1d54(%ebx)
	shift |= shiftcode[data];
f010027a:	0f b6 d2             	movzbl %dl,%edx
f010027d:	0f b6 84 13 f4 d0 fe 	movzbl -0x12f0c(%ebx,%edx,1),%eax
f0100284:	ff 
f0100285:	0b 83 54 1d 00 00    	or     0x1d54(%ebx),%eax
	shift ^= togglecode[data];
f010028b:	0f b6 8c 13 f4 cf fe 	movzbl -0x1300c(%ebx,%edx,1),%ecx
f0100292:	ff 
f0100293:	31 c8                	xor    %ecx,%eax
f0100295:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f010029b:	89 c1                	mov    %eax,%ecx
f010029d:	83 e1 03             	and    $0x3,%ecx
f01002a0:	8b 8c 8b f4 1c 00 00 	mov    0x1cf4(%ebx,%ecx,4),%ecx
f01002a7:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ab:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002ae:	a8 08                	test   $0x8,%al
f01002b0:	74 0d                	je     f01002bf <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f01002b2:	89 f2                	mov    %esi,%edx
f01002b4:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002b7:	83 f9 19             	cmp    $0x19,%ecx
f01002ba:	77 7a                	ja     f0100336 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f01002bc:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002bf:	f7 d0                	not    %eax
f01002c1:	a8 06                	test   $0x6,%al
f01002c3:	75 33                	jne    f01002f8 <kbd_proc_data+0xd5>
f01002c5:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002cb:	75 2b                	jne    f01002f8 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f01002cd:	83 ec 0c             	sub    $0xc,%esp
f01002d0:	8d 83 b8 cf fe ff    	lea    -0x13048(%ebx),%eax
f01002d6:	50                   	push   %eax
f01002d7:	e8 0c 2f 00 00       	call   f01031e8 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002dc:	b8 03 00 00 00       	mov    $0x3,%eax
f01002e1:	ba 92 00 00 00       	mov    $0x92,%edx
f01002e6:	ee                   	out    %al,(%dx)
f01002e7:	83 c4 10             	add    $0x10,%esp
f01002ea:	eb 0c                	jmp    f01002f8 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f01002ec:	83 8b 54 1d 00 00 40 	orl    $0x40,0x1d54(%ebx)
		return 0;
f01002f3:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002f8:	89 f0                	mov    %esi,%eax
f01002fa:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01002fd:	5b                   	pop    %ebx
f01002fe:	5e                   	pop    %esi
f01002ff:	5d                   	pop    %ebp
f0100300:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100301:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f0100307:	89 ce                	mov    %ecx,%esi
f0100309:	83 e6 40             	and    $0x40,%esi
f010030c:	83 e0 7f             	and    $0x7f,%eax
f010030f:	85 f6                	test   %esi,%esi
f0100311:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100314:	0f b6 d2             	movzbl %dl,%edx
f0100317:	0f b6 84 13 f4 d0 fe 	movzbl -0x12f0c(%ebx,%edx,1),%eax
f010031e:	ff 
f010031f:	83 c8 40             	or     $0x40,%eax
f0100322:	0f b6 c0             	movzbl %al,%eax
f0100325:	f7 d0                	not    %eax
f0100327:	21 c8                	and    %ecx,%eax
f0100329:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
		return 0;
f010032f:	be 00 00 00 00       	mov    $0x0,%esi
f0100334:	eb c2                	jmp    f01002f8 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f0100336:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100339:	8d 4e 20             	lea    0x20(%esi),%ecx
f010033c:	83 fa 1a             	cmp    $0x1a,%edx
f010033f:	0f 42 f1             	cmovb  %ecx,%esi
f0100342:	e9 78 ff ff ff       	jmp    f01002bf <kbd_proc_data+0x9c>
		return -1;
f0100347:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010034c:	eb aa                	jmp    f01002f8 <kbd_proc_data+0xd5>
		return -1;
f010034e:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100353:	eb a3                	jmp    f01002f8 <kbd_proc_data+0xd5>

f0100355 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100355:	55                   	push   %ebp
f0100356:	89 e5                	mov    %esp,%ebp
f0100358:	57                   	push   %edi
f0100359:	56                   	push   %esi
f010035a:	53                   	push   %ebx
f010035b:	83 ec 1c             	sub    $0x1c,%esp
f010035e:	e8 52 fe ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0100363:	81 c3 a9 6f 01 00    	add    $0x16fa9,%ebx
f0100369:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f010036c:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100371:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100376:	b9 84 00 00 00       	mov    $0x84,%ecx
f010037b:	eb 09                	jmp    f0100386 <cons_putc+0x31>
f010037d:	89 ca                	mov    %ecx,%edx
f010037f:	ec                   	in     (%dx),%al
f0100380:	ec                   	in     (%dx),%al
f0100381:	ec                   	in     (%dx),%al
f0100382:	ec                   	in     (%dx),%al
	     i++)
f0100383:	83 c6 01             	add    $0x1,%esi
f0100386:	89 fa                	mov    %edi,%edx
f0100388:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100389:	a8 20                	test   $0x20,%al
f010038b:	75 08                	jne    f0100395 <cons_putc+0x40>
f010038d:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100393:	7e e8                	jle    f010037d <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f0100395:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100398:	89 f8                	mov    %edi,%eax
f010039a:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010039d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003a2:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003a3:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003a8:	bf 79 03 00 00       	mov    $0x379,%edi
f01003ad:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003b2:	eb 09                	jmp    f01003bd <cons_putc+0x68>
f01003b4:	89 ca                	mov    %ecx,%edx
f01003b6:	ec                   	in     (%dx),%al
f01003b7:	ec                   	in     (%dx),%al
f01003b8:	ec                   	in     (%dx),%al
f01003b9:	ec                   	in     (%dx),%al
f01003ba:	83 c6 01             	add    $0x1,%esi
f01003bd:	89 fa                	mov    %edi,%edx
f01003bf:	ec                   	in     (%dx),%al
f01003c0:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003c6:	7f 04                	jg     f01003cc <cons_putc+0x77>
f01003c8:	84 c0                	test   %al,%al
f01003ca:	79 e8                	jns    f01003b4 <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003cc:	ba 78 03 00 00       	mov    $0x378,%edx
f01003d1:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01003d5:	ee                   	out    %al,(%dx)
f01003d6:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01003db:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003e0:	ee                   	out    %al,(%dx)
f01003e1:	b8 08 00 00 00       	mov    $0x8,%eax
f01003e6:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f01003e7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003ea:	89 fa                	mov    %edi,%edx
f01003ec:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003f2:	89 f8                	mov    %edi,%eax
f01003f4:	80 cc 07             	or     $0x7,%ah
f01003f7:	85 d2                	test   %edx,%edx
f01003f9:	0f 45 c7             	cmovne %edi,%eax
f01003fc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f01003ff:	0f b6 c0             	movzbl %al,%eax
f0100402:	83 f8 09             	cmp    $0x9,%eax
f0100405:	0f 84 b9 00 00 00    	je     f01004c4 <cons_putc+0x16f>
f010040b:	83 f8 09             	cmp    $0x9,%eax
f010040e:	7e 74                	jle    f0100484 <cons_putc+0x12f>
f0100410:	83 f8 0a             	cmp    $0xa,%eax
f0100413:	0f 84 9e 00 00 00    	je     f01004b7 <cons_putc+0x162>
f0100419:	83 f8 0d             	cmp    $0xd,%eax
f010041c:	0f 85 d9 00 00 00    	jne    f01004fb <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100422:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f0100429:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010042f:	c1 e8 16             	shr    $0x16,%eax
f0100432:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100435:	c1 e0 04             	shl    $0x4,%eax
f0100438:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f010043f:	66 81 bb 7c 1f 00 00 	cmpw   $0x7cf,0x1f7c(%ebx)
f0100446:	cf 07 
f0100448:	0f 87 d4 00 00 00    	ja     f0100522 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f010044e:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f0100454:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100459:	89 ca                	mov    %ecx,%edx
f010045b:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045c:	0f b7 9b 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%ebx
f0100463:	8d 71 01             	lea    0x1(%ecx),%esi
f0100466:	89 d8                	mov    %ebx,%eax
f0100468:	66 c1 e8 08          	shr    $0x8,%ax
f010046c:	89 f2                	mov    %esi,%edx
f010046e:	ee                   	out    %al,(%dx)
f010046f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100474:	89 ca                	mov    %ecx,%edx
f0100476:	ee                   	out    %al,(%dx)
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	89 f2                	mov    %esi,%edx
f010047b:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047f:	5b                   	pop    %ebx
f0100480:	5e                   	pop    %esi
f0100481:	5f                   	pop    %edi
f0100482:	5d                   	pop    %ebp
f0100483:	c3                   	ret    
	switch (c & 0xff) {
f0100484:	83 f8 08             	cmp    $0x8,%eax
f0100487:	75 72                	jne    f01004fb <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100489:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f0100490:	66 85 c0             	test   %ax,%ax
f0100493:	74 b9                	je     f010044e <cons_putc+0xf9>
			crt_pos--;
f0100495:	83 e8 01             	sub    $0x1,%eax
f0100498:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010049f:	0f b7 c0             	movzwl %ax,%eax
f01004a2:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004a6:	b2 00                	mov    $0x0,%dl
f01004a8:	83 ca 20             	or     $0x20,%edx
f01004ab:	8b 8b 80 1f 00 00    	mov    0x1f80(%ebx),%ecx
f01004b1:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004b5:	eb 88                	jmp    f010043f <cons_putc+0xea>
		crt_pos += CRT_COLS;
f01004b7:	66 83 83 7c 1f 00 00 	addw   $0x50,0x1f7c(%ebx)
f01004be:	50 
f01004bf:	e9 5e ff ff ff       	jmp    f0100422 <cons_putc+0xcd>
		cons_putc(' ');
f01004c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01004c9:	e8 87 fe ff ff       	call   f0100355 <cons_putc>
		cons_putc(' ');
f01004ce:	b8 20 00 00 00       	mov    $0x20,%eax
f01004d3:	e8 7d fe ff ff       	call   f0100355 <cons_putc>
		cons_putc(' ');
f01004d8:	b8 20 00 00 00       	mov    $0x20,%eax
f01004dd:	e8 73 fe ff ff       	call   f0100355 <cons_putc>
		cons_putc(' ');
f01004e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e7:	e8 69 fe ff ff       	call   f0100355 <cons_putc>
		cons_putc(' ');
f01004ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f1:	e8 5f fe ff ff       	call   f0100355 <cons_putc>
f01004f6:	e9 44 ff ff ff       	jmp    f010043f <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004fb:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f0100502:	8d 50 01             	lea    0x1(%eax),%edx
f0100505:	66 89 93 7c 1f 00 00 	mov    %dx,0x1f7c(%ebx)
f010050c:	0f b7 c0             	movzwl %ax,%eax
f010050f:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f0100515:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f0100519:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010051d:	e9 1d ff ff ff       	jmp    f010043f <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100522:	8b 83 80 1f 00 00    	mov    0x1f80(%ebx),%eax
f0100528:	83 ec 04             	sub    $0x4,%esp
f010052b:	68 00 0f 00 00       	push   $0xf00
f0100530:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100536:	52                   	push   %edx
f0100537:	50                   	push   %eax
f0100538:	e8 12 39 00 00       	call   f0103e4f <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010053d:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f0100543:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100549:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010054f:	83 c4 10             	add    $0x10,%esp
f0100552:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100557:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010055a:	39 d0                	cmp    %edx,%eax
f010055c:	75 f4                	jne    f0100552 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f010055e:	66 83 ab 7c 1f 00 00 	subw   $0x50,0x1f7c(%ebx)
f0100565:	50 
f0100566:	e9 e3 fe ff ff       	jmp    f010044e <cons_putc+0xf9>

f010056b <serial_intr>:
{
f010056b:	e8 e7 01 00 00       	call   f0100757 <__x86.get_pc_thunk.ax>
f0100570:	05 9c 6d 01 00       	add    $0x16d9c,%eax
	if (serial_exists)
f0100575:	80 b8 88 1f 00 00 00 	cmpb   $0x0,0x1f88(%eax)
f010057c:	75 02                	jne    f0100580 <serial_intr+0x15>
f010057e:	f3 c3                	repz ret 
{
f0100580:	55                   	push   %ebp
f0100581:	89 e5                	mov    %esp,%ebp
f0100583:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100586:	8d 80 ad 8e fe ff    	lea    -0x17153(%eax),%eax
f010058c:	e8 47 fc ff ff       	call   f01001d8 <cons_intr>
}
f0100591:	c9                   	leave  
f0100592:	c3                   	ret    

f0100593 <kbd_intr>:
{
f0100593:	55                   	push   %ebp
f0100594:	89 e5                	mov    %esp,%ebp
f0100596:	83 ec 08             	sub    $0x8,%esp
f0100599:	e8 b9 01 00 00       	call   f0100757 <__x86.get_pc_thunk.ax>
f010059e:	05 6e 6d 01 00       	add    $0x16d6e,%eax
	cons_intr(kbd_proc_data);
f01005a3:	8d 80 17 8f fe ff    	lea    -0x170e9(%eax),%eax
f01005a9:	e8 2a fc ff ff       	call   f01001d8 <cons_intr>
}
f01005ae:	c9                   	leave  
f01005af:	c3                   	ret    

f01005b0 <cons_getc>:
{
f01005b0:	55                   	push   %ebp
f01005b1:	89 e5                	mov    %esp,%ebp
f01005b3:	53                   	push   %ebx
f01005b4:	83 ec 04             	sub    $0x4,%esp
f01005b7:	e8 f9 fb ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f01005bc:	81 c3 50 6d 01 00    	add    $0x16d50,%ebx
	serial_intr();
f01005c2:	e8 a4 ff ff ff       	call   f010056b <serial_intr>
	kbd_intr();
f01005c7:	e8 c7 ff ff ff       	call   f0100593 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005cc:	8b 93 74 1f 00 00    	mov    0x1f74(%ebx),%edx
	return 0;
f01005d2:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005d7:	3b 93 78 1f 00 00    	cmp    0x1f78(%ebx),%edx
f01005dd:	74 19                	je     f01005f8 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f01005df:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005e2:	89 8b 74 1f 00 00    	mov    %ecx,0x1f74(%ebx)
f01005e8:	0f b6 84 13 74 1d 00 	movzbl 0x1d74(%ebx,%edx,1),%eax
f01005ef:	00 
		if (cons.rpos == CONSBUFSIZE)
f01005f0:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005f6:	74 06                	je     f01005fe <cons_getc+0x4e>
}
f01005f8:	83 c4 04             	add    $0x4,%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5d                   	pop    %ebp
f01005fd:	c3                   	ret    
			cons.rpos = 0;
f01005fe:	c7 83 74 1f 00 00 00 	movl   $0x0,0x1f74(%ebx)
f0100605:	00 00 00 
f0100608:	eb ee                	jmp    f01005f8 <cons_getc+0x48>

f010060a <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010060a:	55                   	push   %ebp
f010060b:	89 e5                	mov    %esp,%ebp
f010060d:	57                   	push   %edi
f010060e:	56                   	push   %esi
f010060f:	53                   	push   %ebx
f0100610:	83 ec 1c             	sub    $0x1c,%esp
f0100613:	e8 9d fb ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0100618:	81 c3 f4 6c 01 00    	add    $0x16cf4,%ebx
	was = *cp;
f010061e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100625:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010062c:	5a a5 
	if (*cp != 0xA55A) {
f010062e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100635:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100639:	0f 84 bc 00 00 00    	je     f01006fb <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f010063f:	c7 83 84 1f 00 00 b4 	movl   $0x3b4,0x1f84(%ebx)
f0100646:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100649:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100650:	8b bb 84 1f 00 00    	mov    0x1f84(%ebx),%edi
f0100656:	b8 0e 00 00 00       	mov    $0xe,%eax
f010065b:	89 fa                	mov    %edi,%edx
f010065d:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010065e:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100661:	89 ca                	mov    %ecx,%edx
f0100663:	ec                   	in     (%dx),%al
f0100664:	0f b6 f0             	movzbl %al,%esi
f0100667:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010066a:	b8 0f 00 00 00       	mov    $0xf,%eax
f010066f:	89 fa                	mov    %edi,%edx
f0100671:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100672:	89 ca                	mov    %ecx,%edx
f0100674:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100675:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100678:	89 bb 80 1f 00 00    	mov    %edi,0x1f80(%ebx)
	pos |= inb(addr_6845 + 1);
f010067e:	0f b6 c0             	movzbl %al,%eax
f0100681:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100683:	66 89 b3 7c 1f 00 00 	mov    %si,0x1f7c(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010068a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010068f:	89 c8                	mov    %ecx,%eax
f0100691:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100696:	ee                   	out    %al,(%dx)
f0100697:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010069c:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006a1:	89 fa                	mov    %edi,%edx
f01006a3:	ee                   	out    %al,(%dx)
f01006a4:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006a9:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006ae:	ee                   	out    %al,(%dx)
f01006af:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006b4:	89 c8                	mov    %ecx,%eax
f01006b6:	89 f2                	mov    %esi,%edx
f01006b8:	ee                   	out    %al,(%dx)
f01006b9:	b8 03 00 00 00       	mov    $0x3,%eax
f01006be:	89 fa                	mov    %edi,%edx
f01006c0:	ee                   	out    %al,(%dx)
f01006c1:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006c6:	89 c8                	mov    %ecx,%eax
f01006c8:	ee                   	out    %al,(%dx)
f01006c9:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ce:	89 f2                	mov    %esi,%edx
f01006d0:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006d1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006d6:	ec                   	in     (%dx),%al
f01006d7:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006d9:	3c ff                	cmp    $0xff,%al
f01006db:	0f 95 83 88 1f 00 00 	setne  0x1f88(%ebx)
f01006e2:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006e7:	ec                   	in     (%dx),%al
f01006e8:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006ed:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006ee:	80 f9 ff             	cmp    $0xff,%cl
f01006f1:	74 25                	je     f0100718 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f01006f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006f6:	5b                   	pop    %ebx
f01006f7:	5e                   	pop    %esi
f01006f8:	5f                   	pop    %edi
f01006f9:	5d                   	pop    %ebp
f01006fa:	c3                   	ret    
		*cp = was;
f01006fb:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100702:	c7 83 84 1f 00 00 d4 	movl   $0x3d4,0x1f84(%ebx)
f0100709:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010070c:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f0100713:	e9 38 ff ff ff       	jmp    f0100650 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f0100718:	83 ec 0c             	sub    $0xc,%esp
f010071b:	8d 83 c4 cf fe ff    	lea    -0x1303c(%ebx),%eax
f0100721:	50                   	push   %eax
f0100722:	e8 c1 2a 00 00       	call   f01031e8 <cprintf>
f0100727:	83 c4 10             	add    $0x10,%esp
}
f010072a:	eb c7                	jmp    f01006f3 <cons_init+0xe9>

f010072c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010072c:	55                   	push   %ebp
f010072d:	89 e5                	mov    %esp,%ebp
f010072f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100732:	8b 45 08             	mov    0x8(%ebp),%eax
f0100735:	e8 1b fc ff ff       	call   f0100355 <cons_putc>
}
f010073a:	c9                   	leave  
f010073b:	c3                   	ret    

f010073c <getchar>:

int
getchar(void)
{
f010073c:	55                   	push   %ebp
f010073d:	89 e5                	mov    %esp,%ebp
f010073f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100742:	e8 69 fe ff ff       	call   f01005b0 <cons_getc>
f0100747:	85 c0                	test   %eax,%eax
f0100749:	74 f7                	je     f0100742 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010074b:	c9                   	leave  
f010074c:	c3                   	ret    

f010074d <iscons>:

int
iscons(int fdnum)
{
f010074d:	55                   	push   %ebp
f010074e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100750:	b8 01 00 00 00       	mov    $0x1,%eax
f0100755:	5d                   	pop    %ebp
f0100756:	c3                   	ret    

f0100757 <__x86.get_pc_thunk.ax>:
f0100757:	8b 04 24             	mov    (%esp),%eax
f010075a:	c3                   	ret    

f010075b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010075b:	55                   	push   %ebp
f010075c:	89 e5                	mov    %esp,%ebp
f010075e:	56                   	push   %esi
f010075f:	53                   	push   %ebx
f0100760:	e8 50 fa ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0100765:	81 c3 a7 6b 01 00    	add    $0x16ba7,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010076b:	83 ec 04             	sub    $0x4,%esp
f010076e:	8d 83 f4 d1 fe ff    	lea    -0x12e0c(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	8d 83 12 d2 fe ff    	lea    -0x12dee(%ebx),%eax
f010077b:	50                   	push   %eax
f010077c:	8d b3 17 d2 fe ff    	lea    -0x12de9(%ebx),%esi
f0100782:	56                   	push   %esi
f0100783:	e8 60 2a 00 00       	call   f01031e8 <cprintf>
f0100788:	83 c4 0c             	add    $0xc,%esp
f010078b:	8d 83 20 d2 fe ff    	lea    -0x12de0(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	8d 83 28 d2 fe ff    	lea    -0x12dd8(%ebx),%eax
f0100798:	50                   	push   %eax
f0100799:	56                   	push   %esi
f010079a:	e8 49 2a 00 00       	call   f01031e8 <cprintf>
f010079f:	83 c4 0c             	add    $0xc,%esp
f01007a2:	8d 83 e0 d2 fe ff    	lea    -0x12d20(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	8d 83 32 d2 fe ff    	lea    -0x12dce(%ebx),%eax
f01007af:	50                   	push   %eax
f01007b0:	56                   	push   %esi
f01007b1:	e8 32 2a 00 00       	call   f01031e8 <cprintf>
	return 0;
}
f01007b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01007bb:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007be:	5b                   	pop    %ebx
f01007bf:	5e                   	pop    %esi
f01007c0:	5d                   	pop    %ebp
f01007c1:	c3                   	ret    

f01007c2 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007c2:	55                   	push   %ebp
f01007c3:	89 e5                	mov    %esp,%ebp
f01007c5:	57                   	push   %edi
f01007c6:	56                   	push   %esi
f01007c7:	53                   	push   %ebx
f01007c8:	83 ec 18             	sub    $0x18,%esp
f01007cb:	e8 e5 f9 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f01007d0:	81 c3 3c 6b 01 00    	add    $0x16b3c,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007d6:	8d 83 3b d2 fe ff    	lea    -0x12dc5(%ebx),%eax
f01007dc:	50                   	push   %eax
f01007dd:	e8 06 2a 00 00       	call   f01031e8 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e2:	83 c4 08             	add    $0x8,%esp
f01007e5:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f01007eb:	8d 83 08 d3 fe ff    	lea    -0x12cf8(%ebx),%eax
f01007f1:	50                   	push   %eax
f01007f2:	e8 f1 29 00 00       	call   f01031e8 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007f7:	83 c4 0c             	add    $0xc,%esp
f01007fa:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100800:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100806:	50                   	push   %eax
f0100807:	57                   	push   %edi
f0100808:	8d 83 30 d3 fe ff    	lea    -0x12cd0(%ebx),%eax
f010080e:	50                   	push   %eax
f010080f:	e8 d4 29 00 00       	call   f01031e8 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100814:	83 c4 0c             	add    $0xc,%esp
f0100817:	c7 c0 39 42 10 f0    	mov    $0xf0104239,%eax
f010081d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100823:	52                   	push   %edx
f0100824:	50                   	push   %eax
f0100825:	8d 83 54 d3 fe ff    	lea    -0x12cac(%ebx),%eax
f010082b:	50                   	push   %eax
f010082c:	e8 b7 29 00 00       	call   f01031e8 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100831:	83 c4 0c             	add    $0xc,%esp
f0100834:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f010083a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100840:	52                   	push   %edx
f0100841:	50                   	push   %eax
f0100842:	8d 83 78 d3 fe ff    	lea    -0x12c88(%ebx),%eax
f0100848:	50                   	push   %eax
f0100849:	e8 9a 29 00 00       	call   f01031e8 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010084e:	83 c4 0c             	add    $0xc,%esp
f0100851:	c7 c6 c0 96 11 f0    	mov    $0xf01196c0,%esi
f0100857:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010085d:	50                   	push   %eax
f010085e:	56                   	push   %esi
f010085f:	8d 83 9c d3 fe ff    	lea    -0x12c64(%ebx),%eax
f0100865:	50                   	push   %eax
f0100866:	e8 7d 29 00 00       	call   f01031e8 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010086b:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010086e:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100874:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100876:	c1 fe 0a             	sar    $0xa,%esi
f0100879:	56                   	push   %esi
f010087a:	8d 83 c0 d3 fe ff    	lea    -0x12c40(%ebx),%eax
f0100880:	50                   	push   %eax
f0100881:	e8 62 29 00 00       	call   f01031e8 <cprintf>
	return 0;
}
f0100886:	b8 00 00 00 00       	mov    $0x0,%eax
f010088b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010088e:	5b                   	pop    %ebx
f010088f:	5e                   	pop    %esi
f0100890:	5f                   	pop    %edi
f0100891:	5d                   	pop    %ebp
f0100892:	c3                   	ret    

f0100893 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100893:	55                   	push   %ebp
f0100894:	89 e5                	mov    %esp,%ebp
f0100896:	57                   	push   %edi
f0100897:	56                   	push   %esi
f0100898:	53                   	push   %ebx
f0100899:	83 ec 58             	sub    $0x58,%esp
f010089c:	e8 14 f9 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f01008a1:	81 c3 6b 6a 01 00    	add    $0x16a6b,%ebx
	// Your code here.
	cprintf("mon_backtrace:\n");
f01008a7:	8d 83 54 d2 fe ff    	lea    -0x12dac(%ebx),%eax
f01008ad:	50                   	push   %eax
f01008ae:	e8 35 29 00 00       	call   f01031e8 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008b3:	89 e8                	mov    %ebp,%eax
    uint32_t* ebp = (uint32_t*) read_ebp();
f01008b5:	89 c7                	mov    %eax,%edi
    cprintf("Stack backtrace:\n");
f01008b7:	8d 83 64 d2 fe ff    	lea    -0x12d9c(%ebx),%eax
f01008bd:	89 04 24             	mov    %eax,(%esp)
f01008c0:	e8 23 29 00 00       	call   f01031e8 <cprintf>
    while (ebp) {
f01008c5:	83 c4 10             	add    $0x10,%esp
      uint32_t eip = ebp[1];
      cprintf("ebp %x  eip %x  args", ebp, eip);
f01008c8:	8d 83 76 d2 fe ff    	lea    -0x12d8a(%ebx),%eax
f01008ce:	89 45 b8             	mov    %eax,-0x48(%ebp)
      int i;
      for (i = 2; i <= 6; ++i)
        cprintf(" %08.x", ebp[i]);
f01008d1:	8d 83 8b d2 fe ff    	lea    -0x12d75(%ebx),%eax
f01008d7:	89 45 b4             	mov    %eax,-0x4c(%ebp)
    while (ebp) {
f01008da:	e9 83 00 00 00       	jmp    f0100962 <mon_backtrace+0xcf>
      uint32_t eip = ebp[1];
f01008df:	8b 47 04             	mov    0x4(%edi),%eax
f01008e2:	89 45 c0             	mov    %eax,-0x40(%ebp)
      cprintf("ebp %x  eip %x  args", ebp, eip);
f01008e5:	83 ec 04             	sub    $0x4,%esp
f01008e8:	50                   	push   %eax
f01008e9:	57                   	push   %edi
f01008ea:	ff 75 b8             	pushl  -0x48(%ebp)
f01008ed:	e8 f6 28 00 00       	call   f01031e8 <cprintf>
f01008f2:	8d 77 08             	lea    0x8(%edi),%esi
f01008f5:	8d 47 1c             	lea    0x1c(%edi),%eax
f01008f8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01008fb:	83 c4 10             	add    $0x10,%esp
f01008fe:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0100901:	8b 7d b4             	mov    -0x4c(%ebp),%edi
        cprintf(" %08.x", ebp[i]);
f0100904:	83 ec 08             	sub    $0x8,%esp
f0100907:	ff 36                	pushl  (%esi)
f0100909:	57                   	push   %edi
f010090a:	e8 d9 28 00 00       	call   f01031e8 <cprintf>
f010090f:	83 c6 04             	add    $0x4,%esi
      for (i = 2; i <= 6; ++i)
f0100912:	83 c4 10             	add    $0x10,%esp
f0100915:	3b 75 c4             	cmp    -0x3c(%ebp),%esi
f0100918:	75 ea                	jne    f0100904 <mon_backtrace+0x71>
f010091a:	8b 7d bc             	mov    -0x44(%ebp),%edi
      cprintf("\n");
f010091d:	83 ec 0c             	sub    $0xc,%esp
f0100920:	8d 83 3b d7 fe ff    	lea    -0x128c5(%ebx),%eax
f0100926:	50                   	push   %eax
f0100927:	e8 bc 28 00 00       	call   f01031e8 <cprintf>
      struct Eipdebuginfo info;
      debuginfo_eip(eip, &info);
f010092c:	83 c4 08             	add    $0x8,%esp
f010092f:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100932:	50                   	push   %eax
f0100933:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0100936:	56                   	push   %esi
f0100937:	e8 b0 29 00 00       	call   f01032ec <debuginfo_eip>
      cprintf("\t%s:%d: %.*s+%d\n", 
f010093c:	83 c4 08             	add    $0x8,%esp
f010093f:	89 f0                	mov    %esi,%eax
f0100941:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100944:	50                   	push   %eax
f0100945:	ff 75 d8             	pushl  -0x28(%ebp)
f0100948:	ff 75 dc             	pushl  -0x24(%ebp)
f010094b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010094e:	ff 75 d0             	pushl  -0x30(%ebp)
f0100951:	8d 83 92 d2 fe ff    	lea    -0x12d6e(%ebx),%eax
f0100957:	50                   	push   %eax
f0100958:	e8 8b 28 00 00       	call   f01031e8 <cprintf>
      info.eip_file, info.eip_line,
      info.eip_fn_namelen, info.eip_fn_name,
      eip-info.eip_fn_addr);
  //  kern/monitor.c:143: monitor+106
      ebp = (uint32_t*) *ebp;
f010095d:	8b 3f                	mov    (%edi),%edi
f010095f:	83 c4 20             	add    $0x20,%esp
    while (ebp) {
f0100962:	85 ff                	test   %edi,%edi
f0100964:	0f 85 75 ff ff ff    	jne    f01008df <mon_backtrace+0x4c>
    }
  return 0;

}
f010096a:	b8 00 00 00 00       	mov    $0x0,%eax
f010096f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100972:	5b                   	pop    %ebx
f0100973:	5e                   	pop    %esi
f0100974:	5f                   	pop    %edi
f0100975:	5d                   	pop    %ebp
f0100976:	c3                   	ret    

f0100977 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100977:	55                   	push   %ebp
f0100978:	89 e5                	mov    %esp,%ebp
f010097a:	57                   	push   %edi
f010097b:	56                   	push   %esi
f010097c:	53                   	push   %ebx
f010097d:	83 ec 68             	sub    $0x68,%esp
f0100980:	e8 30 f8 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0100985:	81 c3 87 69 01 00    	add    $0x16987,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010098b:	8d 83 ec d3 fe ff    	lea    -0x12c14(%ebx),%eax
f0100991:	50                   	push   %eax
f0100992:	e8 51 28 00 00       	call   f01031e8 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100997:	8d 83 10 d4 fe ff    	lea    -0x12bf0(%ebx),%eax
f010099d:	89 04 24             	mov    %eax,(%esp)
f01009a0:	e8 43 28 00 00       	call   f01031e8 <cprintf>
f01009a5:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01009a8:	8d bb a7 d2 fe ff    	lea    -0x12d59(%ebx),%edi
f01009ae:	eb 4a                	jmp    f01009fa <monitor+0x83>
f01009b0:	83 ec 08             	sub    $0x8,%esp
f01009b3:	0f be c0             	movsbl %al,%eax
f01009b6:	50                   	push   %eax
f01009b7:	57                   	push   %edi
f01009b8:	e8 08 34 00 00       	call   f0103dc5 <strchr>
f01009bd:	83 c4 10             	add    $0x10,%esp
f01009c0:	85 c0                	test   %eax,%eax
f01009c2:	74 08                	je     f01009cc <monitor+0x55>
			*buf++ = 0;
f01009c4:	c6 06 00             	movb   $0x0,(%esi)
f01009c7:	8d 76 01             	lea    0x1(%esi),%esi
f01009ca:	eb 79                	jmp    f0100a45 <monitor+0xce>
		if (*buf == 0)
f01009cc:	80 3e 00             	cmpb   $0x0,(%esi)
f01009cf:	74 7f                	je     f0100a50 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f01009d1:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009d5:	74 0f                	je     f01009e6 <monitor+0x6f>
		argv[argc++] = buf;
f01009d7:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009da:	8d 48 01             	lea    0x1(%eax),%ecx
f01009dd:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009e0:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f01009e4:	eb 44                	jmp    f0100a2a <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009e6:	83 ec 08             	sub    $0x8,%esp
f01009e9:	6a 10                	push   $0x10
f01009eb:	8d 83 ac d2 fe ff    	lea    -0x12d54(%ebx),%eax
f01009f1:	50                   	push   %eax
f01009f2:	e8 f1 27 00 00       	call   f01031e8 <cprintf>
f01009f7:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009fa:	8d 83 a3 d2 fe ff    	lea    -0x12d5d(%ebx),%eax
f0100a00:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100a03:	83 ec 0c             	sub    $0xc,%esp
f0100a06:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a09:	e8 7f 31 00 00       	call   f0103b8d <readline>
f0100a0e:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100a10:	83 c4 10             	add    $0x10,%esp
f0100a13:	85 c0                	test   %eax,%eax
f0100a15:	74 ec                	je     f0100a03 <monitor+0x8c>
	argv[argc] = 0;
f0100a17:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a1e:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100a25:	eb 1e                	jmp    f0100a45 <monitor+0xce>
			buf++;
f0100a27:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a2a:	0f b6 06             	movzbl (%esi),%eax
f0100a2d:	84 c0                	test   %al,%al
f0100a2f:	74 14                	je     f0100a45 <monitor+0xce>
f0100a31:	83 ec 08             	sub    $0x8,%esp
f0100a34:	0f be c0             	movsbl %al,%eax
f0100a37:	50                   	push   %eax
f0100a38:	57                   	push   %edi
f0100a39:	e8 87 33 00 00       	call   f0103dc5 <strchr>
f0100a3e:	83 c4 10             	add    $0x10,%esp
f0100a41:	85 c0                	test   %eax,%eax
f0100a43:	74 e2                	je     f0100a27 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a45:	0f b6 06             	movzbl (%esi),%eax
f0100a48:	84 c0                	test   %al,%al
f0100a4a:	0f 85 60 ff ff ff    	jne    f01009b0 <monitor+0x39>
	argv[argc] = 0;
f0100a50:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a53:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a5a:	00 
	if (argc == 0)
f0100a5b:	85 c0                	test   %eax,%eax
f0100a5d:	74 9b                	je     f01009fa <monitor+0x83>
f0100a5f:	8d b3 14 1d 00 00    	lea    0x1d14(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a65:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a6c:	83 ec 08             	sub    $0x8,%esp
f0100a6f:	ff 36                	pushl  (%esi)
f0100a71:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a74:	e8 ee 32 00 00       	call   f0103d67 <strcmp>
f0100a79:	83 c4 10             	add    $0x10,%esp
f0100a7c:	85 c0                	test   %eax,%eax
f0100a7e:	74 29                	je     f0100aa9 <monitor+0x132>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a80:	83 45 a0 01          	addl   $0x1,-0x60(%ebp)
f0100a84:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a87:	83 c6 0c             	add    $0xc,%esi
f0100a8a:	83 f8 03             	cmp    $0x3,%eax
f0100a8d:	75 dd                	jne    f0100a6c <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a8f:	83 ec 08             	sub    $0x8,%esp
f0100a92:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a95:	8d 83 c9 d2 fe ff    	lea    -0x12d37(%ebx),%eax
f0100a9b:	50                   	push   %eax
f0100a9c:	e8 47 27 00 00       	call   f01031e8 <cprintf>
f0100aa1:	83 c4 10             	add    $0x10,%esp
f0100aa4:	e9 51 ff ff ff       	jmp    f01009fa <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100aa9:	83 ec 04             	sub    $0x4,%esp
f0100aac:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100aaf:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100ab2:	ff 75 08             	pushl  0x8(%ebp)
f0100ab5:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100ab8:	52                   	push   %edx
f0100ab9:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100abc:	ff 94 83 1c 1d 00 00 	call   *0x1d1c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ac3:	83 c4 10             	add    $0x10,%esp
f0100ac6:	85 c0                	test   %eax,%eax
f0100ac8:	0f 89 2c ff ff ff    	jns    f01009fa <monitor+0x83>
				break;
	}
}
f0100ace:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ad1:	5b                   	pop    %ebx
f0100ad2:	5e                   	pop    %esi
f0100ad3:	5f                   	pop    %edi
f0100ad4:	5d                   	pop    %ebp
f0100ad5:	c3                   	ret    

f0100ad6 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ad6:	55                   	push   %ebp
f0100ad7:	89 e5                	mov    %esp,%ebp
f0100ad9:	57                   	push   %edi
f0100ada:	56                   	push   %esi
f0100adb:	53                   	push   %ebx
f0100adc:	83 ec 18             	sub    $0x18,%esp
f0100adf:	e8 d1 f6 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0100ae4:	81 c3 28 68 01 00    	add    $0x16828,%ebx
f0100aea:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100aec:	50                   	push   %eax
f0100aed:	e8 6f 26 00 00       	call   f0103161 <mc146818_read>
f0100af2:	89 c6                	mov    %eax,%esi
f0100af4:	83 c7 01             	add    $0x1,%edi
f0100af7:	89 3c 24             	mov    %edi,(%esp)
f0100afa:	e8 62 26 00 00       	call   f0103161 <mc146818_read>
f0100aff:	c1 e0 08             	shl    $0x8,%eax
f0100b02:	09 f0                	or     %esi,%eax
}
f0100b04:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b07:	5b                   	pop    %ebx
f0100b08:	5e                   	pop    %esi
f0100b09:	5f                   	pop    %edi
f0100b0a:	5d                   	pop    %ebp
f0100b0b:	c3                   	ret    

f0100b0c <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b0c:	55                   	push   %ebp
f0100b0d:	89 e5                	mov    %esp,%ebp
f0100b0f:	56                   	push   %esi
f0100b10:	53                   	push   %ebx
f0100b11:	e8 43 26 00 00       	call   f0103159 <__x86.get_pc_thunk.cx>
f0100b16:	81 c1 f6 67 01 00    	add    $0x167f6,%ecx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b1c:	83 b9 8c 1f 00 00 00 	cmpl   $0x0,0x1f8c(%ecx)
f0100b23:	74 37                	je     f0100b5c <boot_alloc+0x50>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100b25:	8b b1 8c 1f 00 00    	mov    0x1f8c(%ecx),%esi
	nextfree = ROUNDUP(nextfree+n,PGSIZE);
f0100b2b:	8d 94 06 ff 0f 00 00 	lea    0xfff(%esi,%eax,1),%edx
f0100b32:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b38:	89 91 8c 1f 00 00    	mov    %edx,0x1f8c(%ecx)
	if((uint32_t)nextfree - KERNBASE > (npages * PGSIZE))
f0100b3e:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100b44:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100b4a:	8b 18                	mov    (%eax),%ebx
f0100b4c:	c1 e3 0c             	shl    $0xc,%ebx
f0100b4f:	39 da                	cmp    %ebx,%edx
f0100b51:	77 23                	ja     f0100b76 <boot_alloc+0x6a>
		panic("Out of memory!\n");
	return result;
}
f0100b53:	89 f0                	mov    %esi,%eax
f0100b55:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b58:	5b                   	pop    %ebx
f0100b59:	5e                   	pop    %esi
f0100b5a:	5d                   	pop    %ebp
f0100b5b:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);//这里的end是在kernel.ld定义的.bss段后面的
f0100b5c:	c7 c2 c0 96 11 f0    	mov    $0xf01196c0,%edx
f0100b62:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100b68:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b6e:	89 91 8c 1f 00 00    	mov    %edx,0x1f8c(%ecx)
f0100b74:	eb af                	jmp    f0100b25 <boot_alloc+0x19>
		panic("Out of memory!\n");
f0100b76:	83 ec 04             	sub    $0x4,%esp
f0100b79:	8d 81 35 d4 fe ff    	lea    -0x12bcb(%ecx),%eax
f0100b7f:	50                   	push   %eax
f0100b80:	6a 6f                	push   $0x6f
f0100b82:	8d 81 45 d4 fe ff    	lea    -0x12bbb(%ecx),%eax
f0100b88:	50                   	push   %eax
f0100b89:	89 cb                	mov    %ecx,%ebx
f0100b8b:	e8 6f f5 ff ff       	call   f01000ff <_panic>

f0100b90 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b90:	55                   	push   %ebp
f0100b91:	89 e5                	mov    %esp,%ebp
f0100b93:	56                   	push   %esi
f0100b94:	53                   	push   %ebx
f0100b95:	e8 bf 25 00 00       	call   f0103159 <__x86.get_pc_thunk.cx>
f0100b9a:	81 c1 72 67 01 00    	add    $0x16772,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100ba0:	89 d3                	mov    %edx,%ebx
f0100ba2:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100ba5:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100ba8:	a8 01                	test   $0x1,%al
f0100baa:	74 5a                	je     f0100c06 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bb1:	89 c6                	mov    %eax,%esi
f0100bb3:	c1 ee 0c             	shr    $0xc,%esi
f0100bb6:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0100bbc:	3b 33                	cmp    (%ebx),%esi
f0100bbe:	73 2b                	jae    f0100beb <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100bc0:	c1 ea 0c             	shr    $0xc,%edx
f0100bc3:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100bc9:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100bd0:	89 c2                	mov    %eax,%edx
f0100bd2:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100bd5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bda:	85 d2                	test   %edx,%edx
f0100bdc:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100be1:	0f 44 c2             	cmove  %edx,%eax
}
f0100be4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100be7:	5b                   	pop    %ebx
f0100be8:	5e                   	pop    %esi
f0100be9:	5d                   	pop    %ebp
f0100bea:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100beb:	50                   	push   %eax
f0100bec:	8d 81 70 d7 fe ff    	lea    -0x12890(%ecx),%eax
f0100bf2:	50                   	push   %eax
f0100bf3:	68 61 03 00 00       	push   $0x361
f0100bf8:	8d 81 45 d4 fe ff    	lea    -0x12bbb(%ecx),%eax
f0100bfe:	50                   	push   %eax
f0100bff:	89 cb                	mov    %ecx,%ebx
f0100c01:	e8 f9 f4 ff ff       	call   f01000ff <_panic>
		return ~0;
f0100c06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c0b:	eb d7                	jmp    f0100be4 <check_va2pa+0x54>

f0100c0d <check_page_free_list>:
{
f0100c0d:	55                   	push   %ebp
f0100c0e:	89 e5                	mov    %esp,%ebp
f0100c10:	57                   	push   %edi
f0100c11:	56                   	push   %esi
f0100c12:	53                   	push   %ebx
f0100c13:	83 ec 3c             	sub    $0x3c,%esp
f0100c16:	e8 42 25 00 00       	call   f010315d <__x86.get_pc_thunk.di>
f0100c1b:	81 c7 f1 66 01 00    	add    $0x166f1,%edi
f0100c21:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c24:	84 c0                	test   %al,%al
f0100c26:	0f 85 dd 02 00 00    	jne    f0100f09 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100c2c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100c2f:	83 b8 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%eax)
f0100c36:	74 0c                	je     f0100c44 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c38:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100c3f:	e9 2f 03 00 00       	jmp    f0100f73 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100c44:	83 ec 04             	sub    $0x4,%esp
f0100c47:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c4a:	8d 83 94 d7 fe ff    	lea    -0x1286c(%ebx),%eax
f0100c50:	50                   	push   %eax
f0100c51:	68 a2 02 00 00       	push   $0x2a2
f0100c56:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100c5c:	50                   	push   %eax
f0100c5d:	e8 9d f4 ff ff       	call   f01000ff <_panic>
f0100c62:	50                   	push   %eax
f0100c63:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c66:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0100c6c:	50                   	push   %eax
f0100c6d:	6a 64                	push   $0x64
f0100c6f:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f0100c75:	50                   	push   %eax
f0100c76:	e8 84 f4 ff ff       	call   f01000ff <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c7b:	8b 36                	mov    (%esi),%esi
f0100c7d:	85 f6                	test   %esi,%esi
f0100c7f:	74 40                	je     f0100cc1 <check_page_free_list+0xb4>
page2pa(struct PageInfo *pp)
{
	//pages PageInfo数组首地址 所以通过pp(pages[i])-pages可以得到页的编号i，
	//在通过i<<12就可以得到pp所对应的页的物理内存，由于实现系统的物理内存和虚拟内存的转换比较简单，
	//虚拟内存=物理内存+ 0xF0000000.所以通过pages这个结构体，在知道具体的物理页时，就可以很容易得到物理页对应的物理地址和虚拟地址
	return (pp - pages) << PGSHIFT;
f0100c81:	89 f0                	mov    %esi,%eax
f0100c83:	2b 07                	sub    (%edi),%eax
f0100c85:	c1 f8 03             	sar    $0x3,%eax
f0100c88:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c8b:	89 c2                	mov    %eax,%edx
f0100c8d:	c1 ea 16             	shr    $0x16,%edx
f0100c90:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c93:	73 e6                	jae    f0100c7b <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100c95:	89 c2                	mov    %eax,%edx
f0100c97:	c1 ea 0c             	shr    $0xc,%edx
f0100c9a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c9d:	3b 11                	cmp    (%ecx),%edx
f0100c9f:	73 c1                	jae    f0100c62 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100ca1:	83 ec 04             	sub    $0x4,%esp
f0100ca4:	68 80 00 00 00       	push   $0x80
f0100ca9:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100cae:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cb3:	50                   	push   %eax
f0100cb4:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cb7:	e8 46 31 00 00       	call   f0103e02 <memset>
f0100cbc:	83 c4 10             	add    $0x10,%esp
f0100cbf:	eb ba                	jmp    f0100c7b <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100cc1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cc6:	e8 41 fe ff ff       	call   f0100b0c <boot_alloc>
f0100ccb:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cce:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100cd1:	8b 97 90 1f 00 00    	mov    0x1f90(%edi),%edx
		assert(pp >= pages);
f0100cd7:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100cdd:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100cdf:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100ce5:	8b 00                	mov    (%eax),%eax
f0100ce7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100cea:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ced:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cf0:	bf 00 00 00 00       	mov    $0x0,%edi
f0100cf5:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cf8:	e9 08 01 00 00       	jmp    f0100e05 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100cfd:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d00:	8d 83 5f d4 fe ff    	lea    -0x12ba1(%ebx),%eax
f0100d06:	50                   	push   %eax
f0100d07:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100d0d:	50                   	push   %eax
f0100d0e:	68 bc 02 00 00       	push   $0x2bc
f0100d13:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100d19:	50                   	push   %eax
f0100d1a:	e8 e0 f3 ff ff       	call   f01000ff <_panic>
		assert(pp < pages + npages);
f0100d1f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d22:	8d 83 80 d4 fe ff    	lea    -0x12b80(%ebx),%eax
f0100d28:	50                   	push   %eax
f0100d29:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100d2f:	50                   	push   %eax
f0100d30:	68 bd 02 00 00       	push   $0x2bd
f0100d35:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100d3b:	50                   	push   %eax
f0100d3c:	e8 be f3 ff ff       	call   f01000ff <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d41:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d44:	8d 83 b8 d7 fe ff    	lea    -0x12848(%ebx),%eax
f0100d4a:	50                   	push   %eax
f0100d4b:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100d51:	50                   	push   %eax
f0100d52:	68 be 02 00 00       	push   $0x2be
f0100d57:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100d5d:	50                   	push   %eax
f0100d5e:	e8 9c f3 ff ff       	call   f01000ff <_panic>
		assert(page2pa(pp) != 0);
f0100d63:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d66:	8d 83 94 d4 fe ff    	lea    -0x12b6c(%ebx),%eax
f0100d6c:	50                   	push   %eax
f0100d6d:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100d73:	50                   	push   %eax
f0100d74:	68 c1 02 00 00       	push   $0x2c1
f0100d79:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100d7f:	50                   	push   %eax
f0100d80:	e8 7a f3 ff ff       	call   f01000ff <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d85:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d88:	8d 83 a5 d4 fe ff    	lea    -0x12b5b(%ebx),%eax
f0100d8e:	50                   	push   %eax
f0100d8f:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100d95:	50                   	push   %eax
f0100d96:	68 c2 02 00 00       	push   $0x2c2
f0100d9b:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100da1:	50                   	push   %eax
f0100da2:	e8 58 f3 ff ff       	call   f01000ff <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100da7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100daa:	8d 83 ec d7 fe ff    	lea    -0x12814(%ebx),%eax
f0100db0:	50                   	push   %eax
f0100db1:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100db7:	50                   	push   %eax
f0100db8:	68 c3 02 00 00       	push   $0x2c3
f0100dbd:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100dc3:	50                   	push   %eax
f0100dc4:	e8 36 f3 ff ff       	call   f01000ff <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dc9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100dcc:	8d 83 be d4 fe ff    	lea    -0x12b42(%ebx),%eax
f0100dd2:	50                   	push   %eax
f0100dd3:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100dd9:	50                   	push   %eax
f0100dda:	68 c4 02 00 00       	push   $0x2c4
f0100ddf:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100de5:	50                   	push   %eax
f0100de6:	e8 14 f3 ff ff       	call   f01000ff <_panic>
	if (PGNUM(pa) >= npages)
f0100deb:	89 c6                	mov    %eax,%esi
f0100ded:	c1 ee 0c             	shr    $0xc,%esi
f0100df0:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100df3:	76 70                	jbe    f0100e65 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100df5:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dfa:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100dfd:	77 7f                	ja     f0100e7e <check_page_free_list+0x271>
			++nfree_extmem;
f0100dff:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e03:	8b 12                	mov    (%edx),%edx
f0100e05:	85 d2                	test   %edx,%edx
f0100e07:	0f 84 93 00 00 00    	je     f0100ea0 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100e0d:	39 d1                	cmp    %edx,%ecx
f0100e0f:	0f 87 e8 fe ff ff    	ja     f0100cfd <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100e15:	39 d3                	cmp    %edx,%ebx
f0100e17:	0f 86 02 ff ff ff    	jbe    f0100d1f <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e1d:	89 d0                	mov    %edx,%eax
f0100e1f:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100e22:	a8 07                	test   $0x7,%al
f0100e24:	0f 85 17 ff ff ff    	jne    f0100d41 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100e2a:	c1 f8 03             	sar    $0x3,%eax
f0100e2d:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100e30:	85 c0                	test   %eax,%eax
f0100e32:	0f 84 2b ff ff ff    	je     f0100d63 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e38:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e3d:	0f 84 42 ff ff ff    	je     f0100d85 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e43:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e48:	0f 84 59 ff ff ff    	je     f0100da7 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e4e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e53:	0f 84 70 ff ff ff    	je     f0100dc9 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e59:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e5e:	77 8b                	ja     f0100deb <check_page_free_list+0x1de>
			++nfree_basemem;
f0100e60:	83 c7 01             	add    $0x1,%edi
f0100e63:	eb 9e                	jmp    f0100e03 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e65:	50                   	push   %eax
f0100e66:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e69:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0100e6f:	50                   	push   %eax
f0100e70:	6a 64                	push   $0x64
f0100e72:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f0100e78:	50                   	push   %eax
f0100e79:	e8 81 f2 ff ff       	call   f01000ff <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e7e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e81:	8d 83 10 d8 fe ff    	lea    -0x127f0(%ebx),%eax
f0100e87:	50                   	push   %eax
f0100e88:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100e8e:	50                   	push   %eax
f0100e8f:	68 c5 02 00 00       	push   $0x2c5
f0100e94:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100e9a:	50                   	push   %eax
f0100e9b:	e8 5f f2 ff ff       	call   f01000ff <_panic>
f0100ea0:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100ea3:	85 ff                	test   %edi,%edi
f0100ea5:	7e 1e                	jle    f0100ec5 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100ea7:	85 f6                	test   %esi,%esi
f0100ea9:	7e 3c                	jle    f0100ee7 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100eab:	83 ec 0c             	sub    $0xc,%esp
f0100eae:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100eb1:	8d 83 58 d8 fe ff    	lea    -0x127a8(%ebx),%eax
f0100eb7:	50                   	push   %eax
f0100eb8:	e8 2b 23 00 00       	call   f01031e8 <cprintf>
}
f0100ebd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ec0:	5b                   	pop    %ebx
f0100ec1:	5e                   	pop    %esi
f0100ec2:	5f                   	pop    %edi
f0100ec3:	5d                   	pop    %ebp
f0100ec4:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100ec5:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ec8:	8d 83 d8 d4 fe ff    	lea    -0x12b28(%ebx),%eax
f0100ece:	50                   	push   %eax
f0100ecf:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100ed5:	50                   	push   %eax
f0100ed6:	68 cd 02 00 00       	push   $0x2cd
f0100edb:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100ee1:	50                   	push   %eax
f0100ee2:	e8 18 f2 ff ff       	call   f01000ff <_panic>
	assert(nfree_extmem > 0);
f0100ee7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100eea:	8d 83 ea d4 fe ff    	lea    -0x12b16(%ebx),%eax
f0100ef0:	50                   	push   %eax
f0100ef1:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0100ef7:	50                   	push   %eax
f0100ef8:	68 ce 02 00 00       	push   $0x2ce
f0100efd:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0100f03:	50                   	push   %eax
f0100f04:	e8 f6 f1 ff ff       	call   f01000ff <_panic>
	if (!page_free_list)
f0100f09:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100f0c:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f0100f12:	85 c0                	test   %eax,%eax
f0100f14:	0f 84 2a fd ff ff    	je     f0100c44 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100f1a:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100f1d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f20:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100f23:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100f26:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100f29:	c7 c3 d0 96 11 f0    	mov    $0xf01196d0,%ebx
f0100f2f:	89 c2                	mov    %eax,%edx
f0100f31:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100f33:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100f39:	0f 95 c2             	setne  %dl
f0100f3c:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100f3f:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100f43:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100f45:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f49:	8b 00                	mov    (%eax),%eax
f0100f4b:	85 c0                	test   %eax,%eax
f0100f4d:	75 e0                	jne    f0100f2f <check_page_free_list+0x322>
		*tp[1] = 0;
f0100f4f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f52:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100f58:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f5b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f5e:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f60:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f63:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100f66:	89 87 90 1f 00 00    	mov    %eax,0x1f90(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f6c:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f73:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100f76:	8b b0 90 1f 00 00    	mov    0x1f90(%eax),%esi
f0100f7c:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
	if (PGNUM(pa) >= npages)
f0100f82:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100f88:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f8b:	e9 ed fc ff ff       	jmp    f0100c7d <check_page_free_list+0x70>

f0100f90 <page_init>:
{
f0100f90:	55                   	push   %ebp
f0100f91:	89 e5                	mov    %esp,%ebp
f0100f93:	57                   	push   %edi
f0100f94:	56                   	push   %esi
f0100f95:	53                   	push   %ebx
f0100f96:	83 ec 2c             	sub    $0x2c,%esp
f0100f99:	e8 17 f2 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0100f9e:	81 c3 6e 63 01 00    	add    $0x1636e,%ebx
	page_free_list = NULL;
f0100fa4:	c7 83 90 1f 00 00 00 	movl   $0x0,0x1f90(%ebx)
f0100fab:	00 00 00 
	int num_extmem_alloc = ((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE;
f0100fae:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb3:	e8 54 fb ff ff       	call   f0100b0c <boot_alloc>
		}else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_extmem_alloc){
f0100fb8:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
f0100fbe:	89 75 dc             	mov    %esi,-0x24(%ebp)
	int num_extmem_alloc = ((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE;
f0100fc1:	05 00 00 00 10       	add    $0x10000000,%eax
f0100fc6:	c1 e8 0c             	shr    $0xc,%eax
		}else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_extmem_alloc){
f0100fc9:	8d 44 06 60          	lea    0x60(%esi,%eax,1),%eax
f0100fcd:	89 45 d8             	mov    %eax,-0x28(%ebp)
	for (i = 0; i < npages; i++) {
f0100fd0:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fd5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100fdc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fe1:	c7 c6 c8 96 11 f0    	mov    $0xf01196c8,%esi
			pages[i].pp_ref = 0;
f0100fe7:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
f0100fed:	89 7d e0             	mov    %edi,-0x20(%ebp)
        	pages[i].pp_ref = 1;
f0100ff0:	89 7d d0             	mov    %edi,-0x30(%ebp)
        	pages[i].pp_ref = 1;
f0100ff3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
	for (i = 0; i < npages; i++) {
f0100ff6:	eb 3c                	jmp    f0101034 <page_init+0xa4>
        	pages[i].pp_ref = 1;
f0100ff8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100ffb:	8b 17                	mov    (%edi),%edx
f0100ffd:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
        	pages[i].pp_link = NULL;
f0101003:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
        	continue;
f0101009:	eb 26                	jmp    f0101031 <page_init+0xa1>
f010100b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
			pages[i].pp_ref = 0;
f0101012:	89 d1                	mov    %edx,%ecx
f0101014:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101017:	03 0f                	add    (%edi),%ecx
f0101019:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f010101f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101022:	89 39                	mov    %edi,(%ecx)
			page_free_list = &pages[i];
f0101024:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101027:	03 17                	add    (%edi),%edx
f0101029:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010102c:	b9 01 00 00 00       	mov    $0x1,%ecx
	for (i = 0; i < npages; i++) {
f0101031:	83 c0 01             	add    $0x1,%eax
f0101034:	39 06                	cmp    %eax,(%esi)
f0101036:	76 24                	jbe    f010105c <page_init+0xcc>
		if(i==0)
f0101038:	85 c0                	test   %eax,%eax
f010103a:	74 bc                	je     f0100ff8 <page_init+0x68>
		}else if(i>=npages_basemem && i<npages_basemem+num_iohole+num_extmem_alloc){
f010103c:	39 45 dc             	cmp    %eax,-0x24(%ebp)
f010103f:	77 ca                	ja     f010100b <page_init+0x7b>
f0101041:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f0101044:	76 c5                	jbe    f010100b <page_init+0x7b>
        	pages[i].pp_ref = 1;
f0101046:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0101049:	8b 17                	mov    (%edi),%edx
f010104b:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f010104e:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
        	pages[i].pp_link = NULL;
f0101054:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
        	continue;
f010105a:	eb d5                	jmp    f0101031 <page_init+0xa1>
f010105c:	84 c9                	test   %cl,%cl
f010105e:	75 08                	jne    f0101068 <page_init+0xd8>
}
f0101060:	83 c4 2c             	add    $0x2c,%esp
f0101063:	5b                   	pop    %ebx
f0101064:	5e                   	pop    %esi
f0101065:	5f                   	pop    %edi
f0101066:	5d                   	pop    %ebp
f0101067:	c3                   	ret    
f0101068:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010106b:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
f0101071:	eb ed                	jmp    f0101060 <page_init+0xd0>

f0101073 <page_alloc>:
{
f0101073:	55                   	push   %ebp
f0101074:	89 e5                	mov    %esp,%ebp
f0101076:	56                   	push   %esi
f0101077:	53                   	push   %ebx
f0101078:	e8 38 f1 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f010107d:	81 c3 8f 62 01 00    	add    $0x1628f,%ebx
	if(page_free_list==NULL)
f0101083:	8b b3 90 1f 00 00    	mov    0x1f90(%ebx),%esi
f0101089:	85 f6                	test   %esi,%esi
f010108b:	74 14                	je     f01010a1 <page_alloc+0x2e>
	page_free_list = result->pp_link;
f010108d:	8b 06                	mov    (%esi),%eax
f010108f:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
	result->pp_link = NULL;
f0101095:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if(alloc_flags & ALLOC_ZERO)
f010109b:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010109f:	75 09                	jne    f01010aa <page_alloc+0x37>
}
f01010a1:	89 f0                	mov    %esi,%eax
f01010a3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010a6:	5b                   	pop    %ebx
f01010a7:	5e                   	pop    %esi
f01010a8:	5d                   	pop    %ebp
f01010a9:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f01010aa:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01010b0:	89 f2                	mov    %esi,%edx
f01010b2:	2b 10                	sub    (%eax),%edx
f01010b4:	89 d0                	mov    %edx,%eax
f01010b6:	c1 f8 03             	sar    $0x3,%eax
f01010b9:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01010bc:	89 c1                	mov    %eax,%ecx
f01010be:	c1 e9 0c             	shr    $0xc,%ecx
f01010c1:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01010c7:	3b 0a                	cmp    (%edx),%ecx
f01010c9:	73 1a                	jae    f01010e5 <page_alloc+0x72>
		memset(kernel_virual_address,0,PGSIZE);
f01010cb:	83 ec 04             	sub    $0x4,%esp
f01010ce:	68 00 10 00 00       	push   $0x1000
f01010d3:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f01010d5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010da:	50                   	push   %eax
f01010db:	e8 22 2d 00 00       	call   f0103e02 <memset>
f01010e0:	83 c4 10             	add    $0x10,%esp
f01010e3:	eb bc                	jmp    f01010a1 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010e5:	50                   	push   %eax
f01010e6:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f01010ec:	50                   	push   %eax
f01010ed:	6a 64                	push   $0x64
f01010ef:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f01010f5:	50                   	push   %eax
f01010f6:	e8 04 f0 ff ff       	call   f01000ff <_panic>

f01010fb <page_free>:
{
f01010fb:	55                   	push   %ebp
f01010fc:	89 e5                	mov    %esp,%ebp
f01010fe:	53                   	push   %ebx
f01010ff:	83 ec 04             	sub    $0x4,%esp
f0101102:	e8 ae f0 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0101107:	81 c3 05 62 01 00    	add    $0x16205,%ebx
f010110d:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(pp->pp_ref == 0);
f0101110:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101115:	75 18                	jne    f010112f <page_free+0x34>
	assert(pp->pp_link == NULL);
f0101117:	83 38 00             	cmpl   $0x0,(%eax)
f010111a:	75 32                	jne    f010114e <page_free+0x53>
	pp->pp_link = page_free_list;
f010111c:	8b 8b 90 1f 00 00    	mov    0x1f90(%ebx),%ecx
f0101122:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;        //置成当前需要的free page
f0101124:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
}
f010112a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010112d:	c9                   	leave  
f010112e:	c3                   	ret    
	assert(pp->pp_ref == 0);
f010112f:	8d 83 fb d4 fe ff    	lea    -0x12b05(%ebx),%eax
f0101135:	50                   	push   %eax
f0101136:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010113c:	50                   	push   %eax
f010113d:	68 6f 01 00 00       	push   $0x16f
f0101142:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101148:	50                   	push   %eax
f0101149:	e8 b1 ef ff ff       	call   f01000ff <_panic>
	assert(pp->pp_link == NULL);
f010114e:	8d 83 0b d5 fe ff    	lea    -0x12af5(%ebx),%eax
f0101154:	50                   	push   %eax
f0101155:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010115b:	50                   	push   %eax
f010115c:	68 70 01 00 00       	push   $0x170
f0101161:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101167:	50                   	push   %eax
f0101168:	e8 92 ef ff ff       	call   f01000ff <_panic>

f010116d <page_decref>:
{
f010116d:	55                   	push   %ebp
f010116e:	89 e5                	mov    %esp,%ebp
f0101170:	83 ec 08             	sub    $0x8,%esp
f0101173:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101176:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010117a:	83 e8 01             	sub    $0x1,%eax
f010117d:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101181:	66 85 c0             	test   %ax,%ax
f0101184:	74 02                	je     f0101188 <page_decref+0x1b>
}
f0101186:	c9                   	leave  
f0101187:	c3                   	ret    
		page_free(pp);
f0101188:	83 ec 0c             	sub    $0xc,%esp
f010118b:	52                   	push   %edx
f010118c:	e8 6a ff ff ff       	call   f01010fb <page_free>
f0101191:	83 c4 10             	add    $0x10,%esp
}
f0101194:	eb f0                	jmp    f0101186 <page_decref+0x19>

f0101196 <pgdir_walk>:
{
f0101196:	55                   	push   %ebp
f0101197:	89 e5                	mov    %esp,%ebp
f0101199:	57                   	push   %edi
f010119a:	56                   	push   %esi
f010119b:	53                   	push   %ebx
f010119c:	83 ec 0c             	sub    $0xc,%esp
f010119f:	e8 11 f0 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f01011a4:	81 c3 68 61 01 00    	add    $0x16168,%ebx
f01011aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ad:	8b 75 0c             	mov    0xc(%ebp),%esi
	assert(pgdir!=NULL);
f01011b0:	85 c0                	test   %eax,%eax
f01011b2:	74 72                	je     f0101226 <pgdir_walk+0x90>
	pde_t *ppg_dir_entry=&pgdir[PDX(va)];
f01011b4:	89 f2                	mov    %esi,%edx
f01011b6:	c1 ea 16             	shr    $0x16,%edx
f01011b9:	8d 3c 90             	lea    (%eax,%edx,4),%edi
	if(!(*ppg_dir_entry & PTE_P)){
f01011bc:	f6 07 01             	testb  $0x1,(%edi)
f01011bf:	75 37                	jne    f01011f8 <pgdir_walk+0x62>
		if(create)
f01011c1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01011c5:	0f 84 93 00 00 00    	je     f010125e <pgdir_walk+0xc8>
			new_page = page_alloc(ALLOC_ZERO);
f01011cb:	83 ec 0c             	sub    $0xc,%esp
f01011ce:	6a 01                	push   $0x1
f01011d0:	e8 9e fe ff ff       	call   f0101073 <page_alloc>
			if(new_page == NULL)
f01011d5:	83 c4 10             	add    $0x10,%esp
f01011d8:	85 c0                	test   %eax,%eax
f01011da:	0f 84 85 00 00 00    	je     f0101265 <pgdir_walk+0xcf>
			++new_page->pp_ref;
f01011e0:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01011e5:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f01011eb:	2b 02                	sub    (%edx),%eax
f01011ed:	c1 f8 03             	sar    $0x3,%eax
f01011f0:	c1 e0 0c             	shl    $0xc,%eax
			*ppg_dir_entry = (page2pa(new_page) | PTE_P |PTE_W | PTE_U);
f01011f3:	83 c8 07             	or     $0x7,%eax
f01011f6:	89 07                	mov    %eax,(%edi)
	page_table = (pte_t *)KADDR(PTE_ADDR(*ppg_dir_entry));
f01011f8:	8b 07                	mov    (%edi),%eax
f01011fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01011ff:	89 c1                	mov    %eax,%ecx
f0101201:	c1 e9 0c             	shr    $0xc,%ecx
f0101204:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010120a:	3b 0a                	cmp    (%edx),%ecx
f010120c:	73 37                	jae    f0101245 <pgdir_walk+0xaf>
	pte_t *page_table_result = page_table + PTX(va);	
f010120e:	c1 ee 0a             	shr    $0xa,%esi
f0101211:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101217:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
}
f010121e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101221:	5b                   	pop    %ebx
f0101222:	5e                   	pop    %esi
f0101223:	5f                   	pop    %edi
f0101224:	5d                   	pop    %ebp
f0101225:	c3                   	ret    
	assert(pgdir!=NULL);
f0101226:	8d 83 1f d5 fe ff    	lea    -0x12ae1(%ebx),%eax
f010122c:	50                   	push   %eax
f010122d:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0101233:	50                   	push   %eax
f0101234:	68 b9 01 00 00       	push   $0x1b9
f0101239:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010123f:	50                   	push   %eax
f0101240:	e8 ba ee ff ff       	call   f01000ff <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101245:	50                   	push   %eax
f0101246:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f010124c:	50                   	push   %eax
f010124d:	68 d1 01 00 00       	push   $0x1d1
f0101252:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101258:	50                   	push   %eax
f0101259:	e8 a1 ee ff ff       	call   f01000ff <_panic>
			return NULL;  	
f010125e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101263:	eb b9                	jmp    f010121e <pgdir_walk+0x88>
				return NULL;
f0101265:	b8 00 00 00 00       	mov    $0x0,%eax
f010126a:	eb b2                	jmp    f010121e <pgdir_walk+0x88>

f010126c <boot_map_region>:
{
f010126c:	55                   	push   %ebp
f010126d:	89 e5                	mov    %esp,%ebp
f010126f:	57                   	push   %edi
f0101270:	56                   	push   %esi
f0101271:	53                   	push   %ebx
f0101272:	83 ec 1c             	sub    $0x1c,%esp
f0101275:	e8 e3 1e 00 00       	call   f010315d <__x86.get_pc_thunk.di>
f010127a:	81 c7 92 60 01 00    	add    $0x16092,%edi
f0101280:	89 7d d8             	mov    %edi,-0x28(%ebp)
f0101283:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101286:	8b 45 08             	mov    0x8(%ebp),%eax
	uint32_t page_num=size/PGSIZE;
f0101289:	c1 e9 0c             	shr    $0xc,%ecx
f010128c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(i=0;i<page_num;i++){
f010128f:	89 c3                	mov    %eax,%ebx
f0101291:	be 00 00 00 00       	mov    $0x0,%esi
		pg_table_entry = pgdir_walk(pgdir,(void *)va,1);
f0101296:	89 d7                	mov    %edx,%edi
f0101298:	29 c7                	sub    %eax,%edi
		*pg_table_entry = pa| perm | PTE_P;
f010129a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010129d:	83 c8 01             	or     $0x1,%eax
f01012a0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for(i=0;i<page_num;i++){
f01012a3:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01012a6:	74 4c                	je     f01012f4 <boot_map_region+0x88>
		pg_table_entry = pgdir_walk(pgdir,(void *)va,1);
f01012a8:	83 ec 04             	sub    $0x4,%esp
f01012ab:	6a 01                	push   $0x1
f01012ad:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f01012b0:	50                   	push   %eax
f01012b1:	ff 75 e0             	pushl  -0x20(%ebp)
f01012b4:	e8 dd fe ff ff       	call   f0101196 <pgdir_walk>
		assert(pg_table_entry!=NULL);
f01012b9:	83 c4 10             	add    $0x10,%esp
f01012bc:	85 c0                	test   %eax,%eax
f01012be:	74 12                	je     f01012d2 <boot_map_region+0x66>
		*pg_table_entry = pa| perm | PTE_P;
f01012c0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01012c3:	09 da                	or     %ebx,%edx
f01012c5:	89 10                	mov    %edx,(%eax)
		pa+=PGSIZE;
f01012c7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for(i=0;i<page_num;i++){
f01012cd:	83 c6 01             	add    $0x1,%esi
f01012d0:	eb d1                	jmp    f01012a3 <boot_map_region+0x37>
		assert(pg_table_entry!=NULL);
f01012d2:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01012d5:	8d 83 2b d5 fe ff    	lea    -0x12ad5(%ebx),%eax
f01012db:	50                   	push   %eax
f01012dc:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01012e2:	50                   	push   %eax
f01012e3:	68 f7 01 00 00       	push   $0x1f7
f01012e8:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01012ee:	50                   	push   %eax
f01012ef:	e8 0b ee ff ff       	call   f01000ff <_panic>
}
f01012f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012f7:	5b                   	pop    %ebx
f01012f8:	5e                   	pop    %esi
f01012f9:	5f                   	pop    %edi
f01012fa:	5d                   	pop    %ebp
f01012fb:	c3                   	ret    

f01012fc <page_lookup>:
{
f01012fc:	55                   	push   %ebp
f01012fd:	89 e5                	mov    %esp,%ebp
f01012ff:	56                   	push   %esi
f0101300:	53                   	push   %ebx
f0101301:	e8 af ee ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0101306:	81 c3 06 60 01 00    	add    $0x16006,%ebx
f010130c:	8b 75 10             	mov    0x10(%ebp),%esi
	entry = pgdir_walk(pgdir,va,false);
f010130f:	83 ec 04             	sub    $0x4,%esp
f0101312:	6a 00                	push   $0x0
f0101314:	ff 75 0c             	pushl  0xc(%ebp)
f0101317:	ff 75 08             	pushl  0x8(%ebp)
f010131a:	e8 77 fe ff ff       	call   f0101196 <pgdir_walk>
	if(entry == NULL)
f010131f:	83 c4 10             	add    $0x10,%esp
f0101322:	85 c0                	test   %eax,%eax
f0101324:	74 46                	je     f010136c <page_lookup+0x70>
f0101326:	89 c1                	mov    %eax,%ecx
	if(!(*entry & PTE_P))
f0101328:	8b 10                	mov    (%eax),%edx
f010132a:	f6 c2 01             	test   $0x1,%dl
f010132d:	74 44                	je     f0101373 <page_lookup+0x77>
f010132f:	c1 ea 0c             	shr    $0xc,%edx

// 由物理地址得到PageInfo结构体
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101332:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101338:	39 10                	cmp    %edx,(%eax)
f010133a:	76 18                	jbe    f0101354 <page_lookup+0x58>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010133c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101342:	8b 00                	mov    (%eax),%eax
f0101344:	8d 04 d0             	lea    (%eax,%edx,8),%eax
	if(pte_store != NULL)
f0101347:	85 f6                	test   %esi,%esi
f0101349:	74 02                	je     f010134d <page_lookup+0x51>
		*pte_store = entry;
f010134b:	89 0e                	mov    %ecx,(%esi)
}
f010134d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101350:	5b                   	pop    %ebx
f0101351:	5e                   	pop    %esi
f0101352:	5d                   	pop    %ebp
f0101353:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101354:	83 ec 04             	sub    $0x4,%esp
f0101357:	8d 83 7c d8 fe ff    	lea    -0x12784(%ebx),%eax
f010135d:	50                   	push   %eax
f010135e:	6a 5b                	push   $0x5b
f0101360:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f0101366:	50                   	push   %eax
f0101367:	e8 93 ed ff ff       	call   f01000ff <_panic>
		return NULL;
f010136c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101371:	eb da                	jmp    f010134d <page_lookup+0x51>
		return NULL;
f0101373:	b8 00 00 00 00       	mov    $0x0,%eax
f0101378:	eb d3                	jmp    f010134d <page_lookup+0x51>

f010137a <page_remove>:
{
f010137a:	55                   	push   %ebp
f010137b:	89 e5                	mov    %esp,%ebp
f010137d:	53                   	push   %ebx
f010137e:	83 ec 18             	sub    $0x18,%esp
f0101381:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *entry = NULL;
f0101384:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &entry);
f010138b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010138e:	50                   	push   %eax
f010138f:	53                   	push   %ebx
f0101390:	ff 75 08             	pushl  0x8(%ebp)
f0101393:	e8 64 ff ff ff       	call   f01012fc <page_lookup>
	if(page == NULL)
f0101398:	83 c4 10             	add    $0x10,%esp
f010139b:	85 c0                	test   %eax,%eax
f010139d:	75 05                	jne    f01013a4 <page_remove+0x2a>
}
f010139f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01013a2:	c9                   	leave  
f01013a3:	c3                   	ret    
	page_decref(page);
f01013a4:	83 ec 0c             	sub    $0xc,%esp
f01013a7:	50                   	push   %eax
f01013a8:	e8 c0 fd ff ff       	call   f010116d <page_decref>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01013ad:	0f 01 3b             	invlpg (%ebx)
	*entry = 0;
f01013b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013b3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01013b9:	83 c4 10             	add    $0x10,%esp
f01013bc:	eb e1                	jmp    f010139f <page_remove+0x25>

f01013be <page_insert>:
{
f01013be:	55                   	push   %ebp
f01013bf:	89 e5                	mov    %esp,%ebp
f01013c1:	57                   	push   %edi
f01013c2:	56                   	push   %esi
f01013c3:	53                   	push   %ebx
f01013c4:	83 ec 10             	sub    $0x10,%esp
f01013c7:	e8 91 1d 00 00       	call   f010315d <__x86.get_pc_thunk.di>
f01013cc:	81 c7 40 5f 01 00    	add    $0x15f40,%edi
f01013d2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir,va,1);
f01013d5:	6a 01                	push   $0x1
f01013d7:	ff 75 10             	pushl  0x10(%ebp)
f01013da:	53                   	push   %ebx
f01013db:	e8 b6 fd ff ff       	call   f0101196 <pgdir_walk>
	if(pte == NULL)
f01013e0:	83 c4 10             	add    $0x10,%esp
f01013e3:	85 c0                	test   %eax,%eax
f01013e5:	74 5c                	je     f0101443 <page_insert+0x85>
f01013e7:	89 c6                	mov    %eax,%esi
	pp->pp_ref++;
f01013e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013ec:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if(*pte&PTE_P)
f01013f1:	f6 06 01             	testb  $0x1,(%esi)
f01013f4:	75 36                	jne    f010142c <page_insert+0x6e>
	return (pp - pages) << PGSHIFT;
f01013f6:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01013fc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013ff:	2b 08                	sub    (%eax),%ecx
f0101401:	89 c8                	mov    %ecx,%eax
f0101403:	c1 f8 03             	sar    $0x3,%eax
f0101406:	c1 e0 0c             	shl    $0xc,%eax
	*pte = pa | perm | PTE_P;
f0101409:	8b 55 14             	mov    0x14(%ebp),%edx
f010140c:	83 ca 01             	or     $0x1,%edx
f010140f:	09 d0                	or     %edx,%eax
f0101411:	89 06                	mov    %eax,(%esi)
	pgdir[PDX(va)] |= perm;
f0101413:	8b 45 10             	mov    0x10(%ebp),%eax
f0101416:	c1 e8 16             	shr    $0x16,%eax
f0101419:	8b 7d 14             	mov    0x14(%ebp),%edi
f010141c:	09 3c 83             	or     %edi,(%ebx,%eax,4)
	return 0;
f010141f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101424:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101427:	5b                   	pop    %ebx
f0101428:	5e                   	pop    %esi
f0101429:	5f                   	pop    %edi
f010142a:	5d                   	pop    %ebp
f010142b:	c3                   	ret    
f010142c:	8b 45 10             	mov    0x10(%ebp),%eax
f010142f:	0f 01 38             	invlpg (%eax)
		page_remove(pgdir,va);
f0101432:	83 ec 08             	sub    $0x8,%esp
f0101435:	ff 75 10             	pushl  0x10(%ebp)
f0101438:	53                   	push   %ebx
f0101439:	e8 3c ff ff ff       	call   f010137a <page_remove>
f010143e:	83 c4 10             	add    $0x10,%esp
f0101441:	eb b3                	jmp    f01013f6 <page_insert+0x38>
		return -E_NO_MEM;
f0101443:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101448:	eb da                	jmp    f0101424 <page_insert+0x66>

f010144a <mem_init>:
{
f010144a:	55                   	push   %ebp
f010144b:	89 e5                	mov    %esp,%ebp
f010144d:	57                   	push   %edi
f010144e:	56                   	push   %esi
f010144f:	53                   	push   %ebx
f0101450:	83 ec 3c             	sub    $0x3c,%esp
f0101453:	e8 ff f2 ff ff       	call   f0100757 <__x86.get_pc_thunk.ax>
f0101458:	05 b4 5e 01 00       	add    $0x15eb4,%eax
f010145d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f0101460:	b8 15 00 00 00       	mov    $0x15,%eax
f0101465:	e8 6c f6 ff ff       	call   f0100ad6 <nvram_read>
f010146a:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010146c:	b8 17 00 00 00       	mov    $0x17,%eax
f0101471:	e8 60 f6 ff ff       	call   f0100ad6 <nvram_read>
f0101476:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101478:	b8 34 00 00 00       	mov    $0x34,%eax
f010147d:	e8 54 f6 ff ff       	call   f0100ad6 <nvram_read>
f0101482:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0101485:	85 c0                	test   %eax,%eax
f0101487:	0f 85 cd 00 00 00    	jne    f010155a <mem_init+0x110>
		totalmem = 1 * 1024 + extmem;
f010148d:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101493:	85 f6                	test   %esi,%esi
f0101495:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101498:	89 c1                	mov    %eax,%ecx
f010149a:	c1 e9 02             	shr    $0x2,%ecx
f010149d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01014a0:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01014a6:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01014a8:	89 da                	mov    %ebx,%edx
f01014aa:	c1 ea 02             	shr    $0x2,%edx
f01014ad:	89 97 94 1f 00 00    	mov    %edx,0x1f94(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014b3:	89 c2                	mov    %eax,%edx
f01014b5:	29 da                	sub    %ebx,%edx
f01014b7:	52                   	push   %edx
f01014b8:	53                   	push   %ebx
f01014b9:	50                   	push   %eax
f01014ba:	8d 87 9c d8 fe ff    	lea    -0x12764(%edi),%eax
f01014c0:	50                   	push   %eax
f01014c1:	89 fb                	mov    %edi,%ebx
f01014c3:	e8 20 1d 00 00       	call   f01031e8 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01014c8:	b8 00 10 00 00       	mov    $0x1000,%eax
f01014cd:	e8 3a f6 ff ff       	call   f0100b0c <boot_alloc>
f01014d2:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f01014d8:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01014da:	83 c4 0c             	add    $0xc,%esp
f01014dd:	68 00 10 00 00       	push   $0x1000
f01014e2:	6a 00                	push   $0x0
f01014e4:	50                   	push   %eax
f01014e5:	e8 18 29 00 00       	call   f0103e02 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014ea:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01014ec:	83 c4 10             	add    $0x10,%esp
f01014ef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014f4:	76 6e                	jbe    f0101564 <mem_init+0x11a>
	return (physaddr_t)kva - KERNBASE;
f01014f6:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014fc:	83 ca 05             	or     $0x5,%edx
f01014ff:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0101505:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101508:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f010150e:	8b 03                	mov    (%ebx),%eax
f0101510:	c1 e0 03             	shl    $0x3,%eax
f0101513:	e8 f4 f5 ff ff       	call   f0100b0c <boot_alloc>
f0101518:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f010151e:	89 06                	mov    %eax,(%esi)
	memset(pages,0,npages*sizeof(struct PageInfo));
f0101520:	83 ec 04             	sub    $0x4,%esp
f0101523:	8b 13                	mov    (%ebx),%edx
f0101525:	c1 e2 03             	shl    $0x3,%edx
f0101528:	52                   	push   %edx
f0101529:	6a 00                	push   $0x0
f010152b:	50                   	push   %eax
f010152c:	89 fb                	mov    %edi,%ebx
f010152e:	e8 cf 28 00 00       	call   f0103e02 <memset>
	page_init();
f0101533:	e8 58 fa ff ff       	call   f0100f90 <page_init>
	check_page_free_list(1);
f0101538:	b8 01 00 00 00       	mov    $0x1,%eax
f010153d:	e8 cb f6 ff ff       	call   f0100c0d <check_page_free_list>
	if (!pages)
f0101542:	83 c4 10             	add    $0x10,%esp
f0101545:	83 3e 00             	cmpl   $0x0,(%esi)
f0101548:	74 36                	je     f0101580 <mem_init+0x136>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010154a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010154d:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f0101553:	be 00 00 00 00       	mov    $0x0,%esi
f0101558:	eb 49                	jmp    f01015a3 <mem_init+0x159>
		totalmem = 16 * 1024 + ext16mem;
f010155a:	05 00 40 00 00       	add    $0x4000,%eax
f010155f:	e9 34 ff ff ff       	jmp    f0101498 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101564:	50                   	push   %eax
f0101565:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101568:	8d 83 d8 d8 fe ff    	lea    -0x12728(%ebx),%eax
f010156e:	50                   	push   %eax
f010156f:	68 9d 00 00 00       	push   $0x9d
f0101574:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010157a:	50                   	push   %eax
f010157b:	e8 7f eb ff ff       	call   f01000ff <_panic>
		panic("'pages' is a null pointer!");
f0101580:	83 ec 04             	sub    $0x4,%esp
f0101583:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101586:	8d 83 40 d5 fe ff    	lea    -0x12ac0(%ebx),%eax
f010158c:	50                   	push   %eax
f010158d:	68 e1 02 00 00       	push   $0x2e1
f0101592:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101598:	50                   	push   %eax
f0101599:	e8 61 eb ff ff       	call   f01000ff <_panic>
		++nfree;
f010159e:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015a1:	8b 00                	mov    (%eax),%eax
f01015a3:	85 c0                	test   %eax,%eax
f01015a5:	75 f7                	jne    f010159e <mem_init+0x154>
	assert((pp0 = page_alloc(0)));
f01015a7:	83 ec 0c             	sub    $0xc,%esp
f01015aa:	6a 00                	push   $0x0
f01015ac:	e8 c2 fa ff ff       	call   f0101073 <page_alloc>
f01015b1:	89 c3                	mov    %eax,%ebx
f01015b3:	83 c4 10             	add    $0x10,%esp
f01015b6:	85 c0                	test   %eax,%eax
f01015b8:	0f 84 3b 02 00 00    	je     f01017f9 <mem_init+0x3af>
	assert((pp1 = page_alloc(0)));
f01015be:	83 ec 0c             	sub    $0xc,%esp
f01015c1:	6a 00                	push   $0x0
f01015c3:	e8 ab fa ff ff       	call   f0101073 <page_alloc>
f01015c8:	89 c7                	mov    %eax,%edi
f01015ca:	83 c4 10             	add    $0x10,%esp
f01015cd:	85 c0                	test   %eax,%eax
f01015cf:	0f 84 46 02 00 00    	je     f010181b <mem_init+0x3d1>
	assert((pp2 = page_alloc(0)));
f01015d5:	83 ec 0c             	sub    $0xc,%esp
f01015d8:	6a 00                	push   $0x0
f01015da:	e8 94 fa ff ff       	call   f0101073 <page_alloc>
f01015df:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015e2:	83 c4 10             	add    $0x10,%esp
f01015e5:	85 c0                	test   %eax,%eax
f01015e7:	0f 84 50 02 00 00    	je     f010183d <mem_init+0x3f3>
	assert(pp1 && pp1 != pp0);
f01015ed:	39 fb                	cmp    %edi,%ebx
f01015ef:	0f 84 6a 02 00 00    	je     f010185f <mem_init+0x415>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015f8:	39 c7                	cmp    %eax,%edi
f01015fa:	0f 84 81 02 00 00    	je     f0101881 <mem_init+0x437>
f0101600:	39 c3                	cmp    %eax,%ebx
f0101602:	0f 84 79 02 00 00    	je     f0101881 <mem_init+0x437>
	return (pp - pages) << PGSHIFT;
f0101608:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010160b:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101611:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101613:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101619:	8b 10                	mov    (%eax),%edx
f010161b:	c1 e2 0c             	shl    $0xc,%edx
f010161e:	89 d8                	mov    %ebx,%eax
f0101620:	29 c8                	sub    %ecx,%eax
f0101622:	c1 f8 03             	sar    $0x3,%eax
f0101625:	c1 e0 0c             	shl    $0xc,%eax
f0101628:	39 d0                	cmp    %edx,%eax
f010162a:	0f 83 73 02 00 00    	jae    f01018a3 <mem_init+0x459>
f0101630:	89 f8                	mov    %edi,%eax
f0101632:	29 c8                	sub    %ecx,%eax
f0101634:	c1 f8 03             	sar    $0x3,%eax
f0101637:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010163a:	39 c2                	cmp    %eax,%edx
f010163c:	0f 86 83 02 00 00    	jbe    f01018c5 <mem_init+0x47b>
f0101642:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101645:	29 c8                	sub    %ecx,%eax
f0101647:	c1 f8 03             	sar    $0x3,%eax
f010164a:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010164d:	39 c2                	cmp    %eax,%edx
f010164f:	0f 86 92 02 00 00    	jbe    f01018e7 <mem_init+0x49d>
	fl = page_free_list;
f0101655:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101658:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f010165e:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101661:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f0101668:	00 00 00 
	assert(!page_alloc(0));
f010166b:	83 ec 0c             	sub    $0xc,%esp
f010166e:	6a 00                	push   $0x0
f0101670:	e8 fe f9 ff ff       	call   f0101073 <page_alloc>
f0101675:	83 c4 10             	add    $0x10,%esp
f0101678:	85 c0                	test   %eax,%eax
f010167a:	0f 85 89 02 00 00    	jne    f0101909 <mem_init+0x4bf>
	page_free(pp0);
f0101680:	83 ec 0c             	sub    $0xc,%esp
f0101683:	53                   	push   %ebx
f0101684:	e8 72 fa ff ff       	call   f01010fb <page_free>
	page_free(pp1);
f0101689:	89 3c 24             	mov    %edi,(%esp)
f010168c:	e8 6a fa ff ff       	call   f01010fb <page_free>
	page_free(pp2);
f0101691:	83 c4 04             	add    $0x4,%esp
f0101694:	ff 75 d0             	pushl  -0x30(%ebp)
f0101697:	e8 5f fa ff ff       	call   f01010fb <page_free>
	assert((pp0 = page_alloc(0)));
f010169c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016a3:	e8 cb f9 ff ff       	call   f0101073 <page_alloc>
f01016a8:	89 c7                	mov    %eax,%edi
f01016aa:	83 c4 10             	add    $0x10,%esp
f01016ad:	85 c0                	test   %eax,%eax
f01016af:	0f 84 76 02 00 00    	je     f010192b <mem_init+0x4e1>
	assert((pp1 = page_alloc(0)));
f01016b5:	83 ec 0c             	sub    $0xc,%esp
f01016b8:	6a 00                	push   $0x0
f01016ba:	e8 b4 f9 ff ff       	call   f0101073 <page_alloc>
f01016bf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01016c2:	83 c4 10             	add    $0x10,%esp
f01016c5:	85 c0                	test   %eax,%eax
f01016c7:	0f 84 80 02 00 00    	je     f010194d <mem_init+0x503>
	assert((pp2 = page_alloc(0)));
f01016cd:	83 ec 0c             	sub    $0xc,%esp
f01016d0:	6a 00                	push   $0x0
f01016d2:	e8 9c f9 ff ff       	call   f0101073 <page_alloc>
f01016d7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016da:	83 c4 10             	add    $0x10,%esp
f01016dd:	85 c0                	test   %eax,%eax
f01016df:	0f 84 8a 02 00 00    	je     f010196f <mem_init+0x525>
	assert(pp1 && pp1 != pp0);
f01016e5:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f01016e8:	0f 84 a3 02 00 00    	je     f0101991 <mem_init+0x547>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016ee:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01016f1:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01016f4:	0f 84 b9 02 00 00    	je     f01019b3 <mem_init+0x569>
f01016fa:	39 c7                	cmp    %eax,%edi
f01016fc:	0f 84 b1 02 00 00    	je     f01019b3 <mem_init+0x569>
	assert(!page_alloc(0));
f0101702:	83 ec 0c             	sub    $0xc,%esp
f0101705:	6a 00                	push   $0x0
f0101707:	e8 67 f9 ff ff       	call   f0101073 <page_alloc>
f010170c:	83 c4 10             	add    $0x10,%esp
f010170f:	85 c0                	test   %eax,%eax
f0101711:	0f 85 be 02 00 00    	jne    f01019d5 <mem_init+0x58b>
f0101717:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010171a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101720:	89 f9                	mov    %edi,%ecx
f0101722:	2b 08                	sub    (%eax),%ecx
f0101724:	89 c8                	mov    %ecx,%eax
f0101726:	c1 f8 03             	sar    $0x3,%eax
f0101729:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010172c:	89 c1                	mov    %eax,%ecx
f010172e:	c1 e9 0c             	shr    $0xc,%ecx
f0101731:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101737:	3b 0a                	cmp    (%edx),%ecx
f0101739:	0f 83 b8 02 00 00    	jae    f01019f7 <mem_init+0x5ad>
	memset(page2kva(pp0), 1, PGSIZE);
f010173f:	83 ec 04             	sub    $0x4,%esp
f0101742:	68 00 10 00 00       	push   $0x1000
f0101747:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101749:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010174e:	50                   	push   %eax
f010174f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101752:	e8 ab 26 00 00       	call   f0103e02 <memset>
	page_free(pp0);
f0101757:	89 3c 24             	mov    %edi,(%esp)
f010175a:	e8 9c f9 ff ff       	call   f01010fb <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010175f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101766:	e8 08 f9 ff ff       	call   f0101073 <page_alloc>
f010176b:	83 c4 10             	add    $0x10,%esp
f010176e:	85 c0                	test   %eax,%eax
f0101770:	0f 84 97 02 00 00    	je     f0101a0d <mem_init+0x5c3>
	assert(pp && pp0 == pp);
f0101776:	39 c7                	cmp    %eax,%edi
f0101778:	0f 85 b1 02 00 00    	jne    f0101a2f <mem_init+0x5e5>
	return (pp - pages) << PGSHIFT;
f010177e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101781:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101787:	89 fa                	mov    %edi,%edx
f0101789:	2b 10                	sub    (%eax),%edx
f010178b:	c1 fa 03             	sar    $0x3,%edx
f010178e:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101791:	89 d1                	mov    %edx,%ecx
f0101793:	c1 e9 0c             	shr    $0xc,%ecx
f0101796:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f010179c:	3b 08                	cmp    (%eax),%ecx
f010179e:	0f 83 ad 02 00 00    	jae    f0101a51 <mem_init+0x607>
	return (void *)(pa + KERNBASE);
f01017a4:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01017aa:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01017b0:	80 38 00             	cmpb   $0x0,(%eax)
f01017b3:	0f 85 ae 02 00 00    	jne    f0101a67 <mem_init+0x61d>
f01017b9:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01017bc:	39 d0                	cmp    %edx,%eax
f01017be:	75 f0                	jne    f01017b0 <mem_init+0x366>
	page_free_list = fl;
f01017c0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017c3:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01017c6:	89 8b 90 1f 00 00    	mov    %ecx,0x1f90(%ebx)
	page_free(pp0);
f01017cc:	83 ec 0c             	sub    $0xc,%esp
f01017cf:	57                   	push   %edi
f01017d0:	e8 26 f9 ff ff       	call   f01010fb <page_free>
	page_free(pp1);
f01017d5:	83 c4 04             	add    $0x4,%esp
f01017d8:	ff 75 d0             	pushl  -0x30(%ebp)
f01017db:	e8 1b f9 ff ff       	call   f01010fb <page_free>
	page_free(pp2);
f01017e0:	83 c4 04             	add    $0x4,%esp
f01017e3:	ff 75 cc             	pushl  -0x34(%ebp)
f01017e6:	e8 10 f9 ff ff       	call   f01010fb <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017eb:	8b 83 90 1f 00 00    	mov    0x1f90(%ebx),%eax
f01017f1:	83 c4 10             	add    $0x10,%esp
f01017f4:	e9 95 02 00 00       	jmp    f0101a8e <mem_init+0x644>
	assert((pp0 = page_alloc(0)));
f01017f9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017fc:	8d 83 5b d5 fe ff    	lea    -0x12aa5(%ebx),%eax
f0101802:	50                   	push   %eax
f0101803:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0101809:	50                   	push   %eax
f010180a:	68 e9 02 00 00       	push   $0x2e9
f010180f:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101815:	50                   	push   %eax
f0101816:	e8 e4 e8 ff ff       	call   f01000ff <_panic>
	assert((pp1 = page_alloc(0)));
f010181b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010181e:	8d 83 71 d5 fe ff    	lea    -0x12a8f(%ebx),%eax
f0101824:	50                   	push   %eax
f0101825:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010182b:	50                   	push   %eax
f010182c:	68 ea 02 00 00       	push   $0x2ea
f0101831:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101837:	50                   	push   %eax
f0101838:	e8 c2 e8 ff ff       	call   f01000ff <_panic>
	assert((pp2 = page_alloc(0)));
f010183d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101840:	8d 83 87 d5 fe ff    	lea    -0x12a79(%ebx),%eax
f0101846:	50                   	push   %eax
f0101847:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010184d:	50                   	push   %eax
f010184e:	68 eb 02 00 00       	push   $0x2eb
f0101853:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101859:	50                   	push   %eax
f010185a:	e8 a0 e8 ff ff       	call   f01000ff <_panic>
	assert(pp1 && pp1 != pp0);
f010185f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101862:	8d 83 9d d5 fe ff    	lea    -0x12a63(%ebx),%eax
f0101868:	50                   	push   %eax
f0101869:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010186f:	50                   	push   %eax
f0101870:	68 ee 02 00 00       	push   $0x2ee
f0101875:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010187b:	50                   	push   %eax
f010187c:	e8 7e e8 ff ff       	call   f01000ff <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101881:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101884:	8d 83 fc d8 fe ff    	lea    -0x12704(%ebx),%eax
f010188a:	50                   	push   %eax
f010188b:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0101891:	50                   	push   %eax
f0101892:	68 ef 02 00 00       	push   $0x2ef
f0101897:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010189d:	50                   	push   %eax
f010189e:	e8 5c e8 ff ff       	call   f01000ff <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01018a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018a6:	8d 83 af d5 fe ff    	lea    -0x12a51(%ebx),%eax
f01018ac:	50                   	push   %eax
f01018ad:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01018b3:	50                   	push   %eax
f01018b4:	68 f0 02 00 00       	push   $0x2f0
f01018b9:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01018bf:	50                   	push   %eax
f01018c0:	e8 3a e8 ff ff       	call   f01000ff <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01018c5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018c8:	8d 83 cc d5 fe ff    	lea    -0x12a34(%ebx),%eax
f01018ce:	50                   	push   %eax
f01018cf:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01018d5:	50                   	push   %eax
f01018d6:	68 f1 02 00 00       	push   $0x2f1
f01018db:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01018e1:	50                   	push   %eax
f01018e2:	e8 18 e8 ff ff       	call   f01000ff <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01018e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018ea:	8d 83 e9 d5 fe ff    	lea    -0x12a17(%ebx),%eax
f01018f0:	50                   	push   %eax
f01018f1:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01018f7:	50                   	push   %eax
f01018f8:	68 f2 02 00 00       	push   $0x2f2
f01018fd:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101903:	50                   	push   %eax
f0101904:	e8 f6 e7 ff ff       	call   f01000ff <_panic>
	assert(!page_alloc(0));
f0101909:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010190c:	8d 83 06 d6 fe ff    	lea    -0x129fa(%ebx),%eax
f0101912:	50                   	push   %eax
f0101913:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0101919:	50                   	push   %eax
f010191a:	68 f9 02 00 00       	push   $0x2f9
f010191f:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101925:	50                   	push   %eax
f0101926:	e8 d4 e7 ff ff       	call   f01000ff <_panic>
	assert((pp0 = page_alloc(0)));
f010192b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010192e:	8d 83 5b d5 fe ff    	lea    -0x12aa5(%ebx),%eax
f0101934:	50                   	push   %eax
f0101935:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010193b:	50                   	push   %eax
f010193c:	68 00 03 00 00       	push   $0x300
f0101941:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101947:	50                   	push   %eax
f0101948:	e8 b2 e7 ff ff       	call   f01000ff <_panic>
	assert((pp1 = page_alloc(0)));
f010194d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101950:	8d 83 71 d5 fe ff    	lea    -0x12a8f(%ebx),%eax
f0101956:	50                   	push   %eax
f0101957:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010195d:	50                   	push   %eax
f010195e:	68 01 03 00 00       	push   $0x301
f0101963:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101969:	50                   	push   %eax
f010196a:	e8 90 e7 ff ff       	call   f01000ff <_panic>
	assert((pp2 = page_alloc(0)));
f010196f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101972:	8d 83 87 d5 fe ff    	lea    -0x12a79(%ebx),%eax
f0101978:	50                   	push   %eax
f0101979:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010197f:	50                   	push   %eax
f0101980:	68 02 03 00 00       	push   $0x302
f0101985:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010198b:	50                   	push   %eax
f010198c:	e8 6e e7 ff ff       	call   f01000ff <_panic>
	assert(pp1 && pp1 != pp0);
f0101991:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101994:	8d 83 9d d5 fe ff    	lea    -0x12a63(%ebx),%eax
f010199a:	50                   	push   %eax
f010199b:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01019a1:	50                   	push   %eax
f01019a2:	68 04 03 00 00       	push   $0x304
f01019a7:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01019ad:	50                   	push   %eax
f01019ae:	e8 4c e7 ff ff       	call   f01000ff <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019b6:	8d 83 fc d8 fe ff    	lea    -0x12704(%ebx),%eax
f01019bc:	50                   	push   %eax
f01019bd:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01019c3:	50                   	push   %eax
f01019c4:	68 05 03 00 00       	push   $0x305
f01019c9:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01019cf:	50                   	push   %eax
f01019d0:	e8 2a e7 ff ff       	call   f01000ff <_panic>
	assert(!page_alloc(0));
f01019d5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019d8:	8d 83 06 d6 fe ff    	lea    -0x129fa(%ebx),%eax
f01019de:	50                   	push   %eax
f01019df:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01019e5:	50                   	push   %eax
f01019e6:	68 06 03 00 00       	push   $0x306
f01019eb:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01019f1:	50                   	push   %eax
f01019f2:	e8 08 e7 ff ff       	call   f01000ff <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019f7:	50                   	push   %eax
f01019f8:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f01019fe:	50                   	push   %eax
f01019ff:	6a 64                	push   $0x64
f0101a01:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f0101a07:	50                   	push   %eax
f0101a08:	e8 f2 e6 ff ff       	call   f01000ff <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a0d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a10:	8d 83 15 d6 fe ff    	lea    -0x129eb(%ebx),%eax
f0101a16:	50                   	push   %eax
f0101a17:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0101a1d:	50                   	push   %eax
f0101a1e:	68 0b 03 00 00       	push   $0x30b
f0101a23:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101a29:	50                   	push   %eax
f0101a2a:	e8 d0 e6 ff ff       	call   f01000ff <_panic>
	assert(pp && pp0 == pp);
f0101a2f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a32:	8d 83 33 d6 fe ff    	lea    -0x129cd(%ebx),%eax
f0101a38:	50                   	push   %eax
f0101a39:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0101a3f:	50                   	push   %eax
f0101a40:	68 0c 03 00 00       	push   $0x30c
f0101a45:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101a4b:	50                   	push   %eax
f0101a4c:	e8 ae e6 ff ff       	call   f01000ff <_panic>
f0101a51:	52                   	push   %edx
f0101a52:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0101a58:	50                   	push   %eax
f0101a59:	6a 64                	push   $0x64
f0101a5b:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f0101a61:	50                   	push   %eax
f0101a62:	e8 98 e6 ff ff       	call   f01000ff <_panic>
		assert(c[i] == 0);
f0101a67:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a6a:	8d 83 43 d6 fe ff    	lea    -0x129bd(%ebx),%eax
f0101a70:	50                   	push   %eax
f0101a71:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0101a77:	50                   	push   %eax
f0101a78:	68 0f 03 00 00       	push   $0x30f
f0101a7d:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0101a83:	50                   	push   %eax
f0101a84:	e8 76 e6 ff ff       	call   f01000ff <_panic>
		--nfree;
f0101a89:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a8c:	8b 00                	mov    (%eax),%eax
f0101a8e:	85 c0                	test   %eax,%eax
f0101a90:	75 f7                	jne    f0101a89 <mem_init+0x63f>
	assert(nfree == 0);
f0101a92:	85 f6                	test   %esi,%esi
f0101a94:	0f 85 55 08 00 00    	jne    f01022ef <mem_init+0xea5>
	cprintf("check_page_alloc() succeeded!\n");
f0101a9a:	83 ec 0c             	sub    $0xc,%esp
f0101a9d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101aa0:	8d 83 1c d9 fe ff    	lea    -0x126e4(%ebx),%eax
f0101aa6:	50                   	push   %eax
f0101aa7:	e8 3c 17 00 00       	call   f01031e8 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101aac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ab3:	e8 bb f5 ff ff       	call   f0101073 <page_alloc>
f0101ab8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101abb:	83 c4 10             	add    $0x10,%esp
f0101abe:	85 c0                	test   %eax,%eax
f0101ac0:	0f 84 4b 08 00 00    	je     f0102311 <mem_init+0xec7>
	assert((pp1 = page_alloc(0)));
f0101ac6:	83 ec 0c             	sub    $0xc,%esp
f0101ac9:	6a 00                	push   $0x0
f0101acb:	e8 a3 f5 ff ff       	call   f0101073 <page_alloc>
f0101ad0:	89 c7                	mov    %eax,%edi
f0101ad2:	83 c4 10             	add    $0x10,%esp
f0101ad5:	85 c0                	test   %eax,%eax
f0101ad7:	0f 84 56 08 00 00    	je     f0102333 <mem_init+0xee9>
	assert((pp2 = page_alloc(0)));
f0101add:	83 ec 0c             	sub    $0xc,%esp
f0101ae0:	6a 00                	push   $0x0
f0101ae2:	e8 8c f5 ff ff       	call   f0101073 <page_alloc>
f0101ae7:	89 c6                	mov    %eax,%esi
f0101ae9:	83 c4 10             	add    $0x10,%esp
f0101aec:	85 c0                	test   %eax,%eax
f0101aee:	0f 84 61 08 00 00    	je     f0102355 <mem_init+0xf0b>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101af4:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101af7:	0f 84 7a 08 00 00    	je     f0102377 <mem_init+0xf2d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101afd:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101b00:	0f 84 93 08 00 00    	je     f0102399 <mem_init+0xf4f>
f0101b06:	39 c7                	cmp    %eax,%edi
f0101b08:	0f 84 8b 08 00 00    	je     f0102399 <mem_init+0xf4f>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b11:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f0101b17:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101b1a:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f0101b21:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b24:	83 ec 0c             	sub    $0xc,%esp
f0101b27:	6a 00                	push   $0x0
f0101b29:	e8 45 f5 ff ff       	call   f0101073 <page_alloc>
f0101b2e:	83 c4 10             	add    $0x10,%esp
f0101b31:	85 c0                	test   %eax,%eax
f0101b33:	0f 85 82 08 00 00    	jne    f01023bb <mem_init+0xf71>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101b39:	83 ec 04             	sub    $0x4,%esp
f0101b3c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b3f:	50                   	push   %eax
f0101b40:	6a 00                	push   $0x0
f0101b42:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b45:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b4b:	ff 30                	pushl  (%eax)
f0101b4d:	e8 aa f7 ff ff       	call   f01012fc <page_lookup>
f0101b52:	83 c4 10             	add    $0x10,%esp
f0101b55:	85 c0                	test   %eax,%eax
f0101b57:	0f 85 80 08 00 00    	jne    f01023dd <mem_init+0xf93>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101b5d:	6a 02                	push   $0x2
f0101b5f:	6a 00                	push   $0x0
f0101b61:	57                   	push   %edi
f0101b62:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b65:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b6b:	ff 30                	pushl  (%eax)
f0101b6d:	e8 4c f8 ff ff       	call   f01013be <page_insert>
f0101b72:	83 c4 10             	add    $0x10,%esp
f0101b75:	85 c0                	test   %eax,%eax
f0101b77:	0f 89 82 08 00 00    	jns    f01023ff <mem_init+0xfb5>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101b7d:	83 ec 0c             	sub    $0xc,%esp
f0101b80:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b83:	e8 73 f5 ff ff       	call   f01010fb <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b88:	6a 02                	push   $0x2
f0101b8a:	6a 00                	push   $0x0
f0101b8c:	57                   	push   %edi
f0101b8d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b90:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b96:	ff 30                	pushl  (%eax)
f0101b98:	e8 21 f8 ff ff       	call   f01013be <page_insert>
f0101b9d:	83 c4 20             	add    $0x20,%esp
f0101ba0:	85 c0                	test   %eax,%eax
f0101ba2:	0f 85 79 08 00 00    	jne    f0102421 <mem_init+0xfd7>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ba8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bab:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bb1:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101bb3:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101bb9:	8b 08                	mov    (%eax),%ecx
f0101bbb:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101bbe:	8b 13                	mov    (%ebx),%edx
f0101bc0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101bc6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bc9:	29 c8                	sub    %ecx,%eax
f0101bcb:	c1 f8 03             	sar    $0x3,%eax
f0101bce:	c1 e0 0c             	shl    $0xc,%eax
f0101bd1:	39 c2                	cmp    %eax,%edx
f0101bd3:	0f 85 6a 08 00 00    	jne    f0102443 <mem_init+0xff9>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101bd9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bde:	89 d8                	mov    %ebx,%eax
f0101be0:	e8 ab ef ff ff       	call   f0100b90 <check_va2pa>
f0101be5:	89 fa                	mov    %edi,%edx
f0101be7:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101bea:	c1 fa 03             	sar    $0x3,%edx
f0101bed:	c1 e2 0c             	shl    $0xc,%edx
f0101bf0:	39 d0                	cmp    %edx,%eax
f0101bf2:	0f 85 6d 08 00 00    	jne    f0102465 <mem_init+0x101b>
	assert(pp1->pp_ref == 1);
f0101bf8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101bfd:	0f 85 84 08 00 00    	jne    f0102487 <mem_init+0x103d>
	assert(pp0->pp_ref == 1);
f0101c03:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c06:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c0b:	0f 85 98 08 00 00    	jne    f01024a9 <mem_init+0x105f>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c11:	6a 02                	push   $0x2
f0101c13:	68 00 10 00 00       	push   $0x1000
f0101c18:	56                   	push   %esi
f0101c19:	53                   	push   %ebx
f0101c1a:	e8 9f f7 ff ff       	call   f01013be <page_insert>
f0101c1f:	83 c4 10             	add    $0x10,%esp
f0101c22:	85 c0                	test   %eax,%eax
f0101c24:	0f 85 a1 08 00 00    	jne    f01024cb <mem_init+0x1081>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c2a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c2f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c32:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c38:	8b 00                	mov    (%eax),%eax
f0101c3a:	e8 51 ef ff ff       	call   f0100b90 <check_va2pa>
f0101c3f:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101c45:	89 f1                	mov    %esi,%ecx
f0101c47:	2b 0a                	sub    (%edx),%ecx
f0101c49:	89 ca                	mov    %ecx,%edx
f0101c4b:	c1 fa 03             	sar    $0x3,%edx
f0101c4e:	c1 e2 0c             	shl    $0xc,%edx
f0101c51:	39 d0                	cmp    %edx,%eax
f0101c53:	0f 85 94 08 00 00    	jne    f01024ed <mem_init+0x10a3>
	assert(pp2->pp_ref == 1);
f0101c59:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c5e:	0f 85 ab 08 00 00    	jne    f010250f <mem_init+0x10c5>

	// should be no free memory
	assert(!page_alloc(0));
f0101c64:	83 ec 0c             	sub    $0xc,%esp
f0101c67:	6a 00                	push   $0x0
f0101c69:	e8 05 f4 ff ff       	call   f0101073 <page_alloc>
f0101c6e:	83 c4 10             	add    $0x10,%esp
f0101c71:	85 c0                	test   %eax,%eax
f0101c73:	0f 85 b8 08 00 00    	jne    f0102531 <mem_init+0x10e7>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c79:	6a 02                	push   $0x2
f0101c7b:	68 00 10 00 00       	push   $0x1000
f0101c80:	56                   	push   %esi
f0101c81:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c84:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c8a:	ff 30                	pushl  (%eax)
f0101c8c:	e8 2d f7 ff ff       	call   f01013be <page_insert>
f0101c91:	83 c4 10             	add    $0x10,%esp
f0101c94:	85 c0                	test   %eax,%eax
f0101c96:	0f 85 b7 08 00 00    	jne    f0102553 <mem_init+0x1109>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c9c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ca1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ca4:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101caa:	8b 00                	mov    (%eax),%eax
f0101cac:	e8 df ee ff ff       	call   f0100b90 <check_va2pa>
f0101cb1:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101cb7:	89 f1                	mov    %esi,%ecx
f0101cb9:	2b 0a                	sub    (%edx),%ecx
f0101cbb:	89 ca                	mov    %ecx,%edx
f0101cbd:	c1 fa 03             	sar    $0x3,%edx
f0101cc0:	c1 e2 0c             	shl    $0xc,%edx
f0101cc3:	39 d0                	cmp    %edx,%eax
f0101cc5:	0f 85 aa 08 00 00    	jne    f0102575 <mem_init+0x112b>
	assert(pp2->pp_ref == 1);
f0101ccb:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cd0:	0f 85 c1 08 00 00    	jne    f0102597 <mem_init+0x114d>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cd6:	83 ec 0c             	sub    $0xc,%esp
f0101cd9:	6a 00                	push   $0x0
f0101cdb:	e8 93 f3 ff ff       	call   f0101073 <page_alloc>
f0101ce0:	83 c4 10             	add    $0x10,%esp
f0101ce3:	85 c0                	test   %eax,%eax
f0101ce5:	0f 85 ce 08 00 00    	jne    f01025b9 <mem_init+0x116f>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ceb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101cee:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cf4:	8b 10                	mov    (%eax),%edx
f0101cf6:	8b 02                	mov    (%edx),%eax
f0101cf8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101cfd:	89 c3                	mov    %eax,%ebx
f0101cff:	c1 eb 0c             	shr    $0xc,%ebx
f0101d02:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101d08:	3b 19                	cmp    (%ecx),%ebx
f0101d0a:	0f 83 cb 08 00 00    	jae    f01025db <mem_init+0x1191>
	return (void *)(pa + KERNBASE);
f0101d10:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d15:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d18:	83 ec 04             	sub    $0x4,%esp
f0101d1b:	6a 00                	push   $0x0
f0101d1d:	68 00 10 00 00       	push   $0x1000
f0101d22:	52                   	push   %edx
f0101d23:	e8 6e f4 ff ff       	call   f0101196 <pgdir_walk>
f0101d28:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d2b:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d2e:	83 c4 10             	add    $0x10,%esp
f0101d31:	39 d0                	cmp    %edx,%eax
f0101d33:	0f 85 be 08 00 00    	jne    f01025f7 <mem_init+0x11ad>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d39:	6a 06                	push   $0x6
f0101d3b:	68 00 10 00 00       	push   $0x1000
f0101d40:	56                   	push   %esi
f0101d41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d44:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d4a:	ff 30                	pushl  (%eax)
f0101d4c:	e8 6d f6 ff ff       	call   f01013be <page_insert>
f0101d51:	83 c4 10             	add    $0x10,%esp
f0101d54:	85 c0                	test   %eax,%eax
f0101d56:	0f 85 bd 08 00 00    	jne    f0102619 <mem_init+0x11cf>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d5c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d5f:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d65:	8b 18                	mov    (%eax),%ebx
f0101d67:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d6c:	89 d8                	mov    %ebx,%eax
f0101d6e:	e8 1d ee ff ff       	call   f0100b90 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101d73:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101d76:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101d7c:	89 f1                	mov    %esi,%ecx
f0101d7e:	2b 0a                	sub    (%edx),%ecx
f0101d80:	89 ca                	mov    %ecx,%edx
f0101d82:	c1 fa 03             	sar    $0x3,%edx
f0101d85:	c1 e2 0c             	shl    $0xc,%edx
f0101d88:	39 d0                	cmp    %edx,%eax
f0101d8a:	0f 85 ab 08 00 00    	jne    f010263b <mem_init+0x11f1>
	assert(pp2->pp_ref == 1);
f0101d90:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d95:	0f 85 c2 08 00 00    	jne    f010265d <mem_init+0x1213>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d9b:	83 ec 04             	sub    $0x4,%esp
f0101d9e:	6a 00                	push   $0x0
f0101da0:	68 00 10 00 00       	push   $0x1000
f0101da5:	53                   	push   %ebx
f0101da6:	e8 eb f3 ff ff       	call   f0101196 <pgdir_walk>
f0101dab:	83 c4 10             	add    $0x10,%esp
f0101dae:	f6 00 04             	testb  $0x4,(%eax)
f0101db1:	0f 84 c8 08 00 00    	je     f010267f <mem_init+0x1235>
	assert(kern_pgdir[0] & PTE_U);
f0101db7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dba:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101dc0:	8b 00                	mov    (%eax),%eax
f0101dc2:	f6 00 04             	testb  $0x4,(%eax)
f0101dc5:	0f 84 d6 08 00 00    	je     f01026a1 <mem_init+0x1257>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101dcb:	6a 02                	push   $0x2
f0101dcd:	68 00 10 00 00       	push   $0x1000
f0101dd2:	56                   	push   %esi
f0101dd3:	50                   	push   %eax
f0101dd4:	e8 e5 f5 ff ff       	call   f01013be <page_insert>
f0101dd9:	83 c4 10             	add    $0x10,%esp
f0101ddc:	85 c0                	test   %eax,%eax
f0101dde:	0f 85 df 08 00 00    	jne    f01026c3 <mem_init+0x1279>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101de4:	83 ec 04             	sub    $0x4,%esp
f0101de7:	6a 00                	push   $0x0
f0101de9:	68 00 10 00 00       	push   $0x1000
f0101dee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101df1:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101df7:	ff 30                	pushl  (%eax)
f0101df9:	e8 98 f3 ff ff       	call   f0101196 <pgdir_walk>
f0101dfe:	83 c4 10             	add    $0x10,%esp
f0101e01:	f6 00 02             	testb  $0x2,(%eax)
f0101e04:	0f 84 db 08 00 00    	je     f01026e5 <mem_init+0x129b>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e0a:	83 ec 04             	sub    $0x4,%esp
f0101e0d:	6a 00                	push   $0x0
f0101e0f:	68 00 10 00 00       	push   $0x1000
f0101e14:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e17:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e1d:	ff 30                	pushl  (%eax)
f0101e1f:	e8 72 f3 ff ff       	call   f0101196 <pgdir_walk>
f0101e24:	83 c4 10             	add    $0x10,%esp
f0101e27:	f6 00 04             	testb  $0x4,(%eax)
f0101e2a:	0f 85 d7 08 00 00    	jne    f0102707 <mem_init+0x12bd>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e30:	6a 02                	push   $0x2
f0101e32:	68 00 00 40 00       	push   $0x400000
f0101e37:	ff 75 d0             	pushl  -0x30(%ebp)
f0101e3a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e3d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e43:	ff 30                	pushl  (%eax)
f0101e45:	e8 74 f5 ff ff       	call   f01013be <page_insert>
f0101e4a:	83 c4 10             	add    $0x10,%esp
f0101e4d:	85 c0                	test   %eax,%eax
f0101e4f:	0f 89 d4 08 00 00    	jns    f0102729 <mem_init+0x12df>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e55:	6a 02                	push   $0x2
f0101e57:	68 00 10 00 00       	push   $0x1000
f0101e5c:	57                   	push   %edi
f0101e5d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e60:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e66:	ff 30                	pushl  (%eax)
f0101e68:	e8 51 f5 ff ff       	call   f01013be <page_insert>
f0101e6d:	83 c4 10             	add    $0x10,%esp
f0101e70:	85 c0                	test   %eax,%eax
f0101e72:	0f 85 d3 08 00 00    	jne    f010274b <mem_init+0x1301>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e78:	83 ec 04             	sub    $0x4,%esp
f0101e7b:	6a 00                	push   $0x0
f0101e7d:	68 00 10 00 00       	push   $0x1000
f0101e82:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e85:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e8b:	ff 30                	pushl  (%eax)
f0101e8d:	e8 04 f3 ff ff       	call   f0101196 <pgdir_walk>
f0101e92:	83 c4 10             	add    $0x10,%esp
f0101e95:	f6 00 04             	testb  $0x4,(%eax)
f0101e98:	0f 85 cf 08 00 00    	jne    f010276d <mem_init+0x1323>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e9e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ea1:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ea7:	8b 18                	mov    (%eax),%ebx
f0101ea9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101eae:	89 d8                	mov    %ebx,%eax
f0101eb0:	e8 db ec ff ff       	call   f0100b90 <check_va2pa>
f0101eb5:	89 c2                	mov    %eax,%edx
f0101eb7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101eba:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ebd:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101ec3:	89 f9                	mov    %edi,%ecx
f0101ec5:	2b 08                	sub    (%eax),%ecx
f0101ec7:	89 c8                	mov    %ecx,%eax
f0101ec9:	c1 f8 03             	sar    $0x3,%eax
f0101ecc:	c1 e0 0c             	shl    $0xc,%eax
f0101ecf:	39 c2                	cmp    %eax,%edx
f0101ed1:	0f 85 b8 08 00 00    	jne    f010278f <mem_init+0x1345>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ed7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101edc:	89 d8                	mov    %ebx,%eax
f0101ede:	e8 ad ec ff ff       	call   f0100b90 <check_va2pa>
f0101ee3:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ee6:	0f 85 c5 08 00 00    	jne    f01027b1 <mem_init+0x1367>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101eec:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101ef1:	0f 85 dc 08 00 00    	jne    f01027d3 <mem_init+0x1389>
	assert(pp2->pp_ref == 0);
f0101ef7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101efc:	0f 85 f3 08 00 00    	jne    f01027f5 <mem_init+0x13ab>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f02:	83 ec 0c             	sub    $0xc,%esp
f0101f05:	6a 00                	push   $0x0
f0101f07:	e8 67 f1 ff ff       	call   f0101073 <page_alloc>
f0101f0c:	83 c4 10             	add    $0x10,%esp
f0101f0f:	39 c6                	cmp    %eax,%esi
f0101f11:	0f 85 00 09 00 00    	jne    f0102817 <mem_init+0x13cd>
f0101f17:	85 c0                	test   %eax,%eax
f0101f19:	0f 84 f8 08 00 00    	je     f0102817 <mem_init+0x13cd>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f1f:	83 ec 08             	sub    $0x8,%esp
f0101f22:	6a 00                	push   $0x0
f0101f24:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f27:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101f2d:	ff 33                	pushl  (%ebx)
f0101f2f:	e8 46 f4 ff ff       	call   f010137a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f34:	8b 1b                	mov    (%ebx),%ebx
f0101f36:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f3b:	89 d8                	mov    %ebx,%eax
f0101f3d:	e8 4e ec ff ff       	call   f0100b90 <check_va2pa>
f0101f42:	83 c4 10             	add    $0x10,%esp
f0101f45:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f48:	0f 85 eb 08 00 00    	jne    f0102839 <mem_init+0x13ef>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f4e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f53:	89 d8                	mov    %ebx,%eax
f0101f55:	e8 36 ec ff ff       	call   f0100b90 <check_va2pa>
f0101f5a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101f5d:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101f63:	89 f9                	mov    %edi,%ecx
f0101f65:	2b 0a                	sub    (%edx),%ecx
f0101f67:	89 ca                	mov    %ecx,%edx
f0101f69:	c1 fa 03             	sar    $0x3,%edx
f0101f6c:	c1 e2 0c             	shl    $0xc,%edx
f0101f6f:	39 d0                	cmp    %edx,%eax
f0101f71:	0f 85 e4 08 00 00    	jne    f010285b <mem_init+0x1411>
	assert(pp1->pp_ref == 1);
f0101f77:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101f7c:	0f 85 fb 08 00 00    	jne    f010287d <mem_init+0x1433>
	assert(pp2->pp_ref == 0);
f0101f82:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f87:	0f 85 12 09 00 00    	jne    f010289f <mem_init+0x1455>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f8d:	6a 00                	push   $0x0
f0101f8f:	68 00 10 00 00       	push   $0x1000
f0101f94:	57                   	push   %edi
f0101f95:	53                   	push   %ebx
f0101f96:	e8 23 f4 ff ff       	call   f01013be <page_insert>
f0101f9b:	83 c4 10             	add    $0x10,%esp
f0101f9e:	85 c0                	test   %eax,%eax
f0101fa0:	0f 85 1b 09 00 00    	jne    f01028c1 <mem_init+0x1477>
	assert(pp1->pp_ref);
f0101fa6:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101fab:	0f 84 32 09 00 00    	je     f01028e3 <mem_init+0x1499>
	assert(pp1->pp_link == NULL);
f0101fb1:	83 3f 00             	cmpl   $0x0,(%edi)
f0101fb4:	0f 85 4b 09 00 00    	jne    f0102905 <mem_init+0x14bb>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101fba:	83 ec 08             	sub    $0x8,%esp
f0101fbd:	68 00 10 00 00       	push   $0x1000
f0101fc2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc5:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101fcb:	ff 33                	pushl  (%ebx)
f0101fcd:	e8 a8 f3 ff ff       	call   f010137a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fd2:	8b 1b                	mov    (%ebx),%ebx
f0101fd4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fd9:	89 d8                	mov    %ebx,%eax
f0101fdb:	e8 b0 eb ff ff       	call   f0100b90 <check_va2pa>
f0101fe0:	83 c4 10             	add    $0x10,%esp
f0101fe3:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fe6:	0f 85 3b 09 00 00    	jne    f0102927 <mem_init+0x14dd>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101fec:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ff1:	89 d8                	mov    %ebx,%eax
f0101ff3:	e8 98 eb ff ff       	call   f0100b90 <check_va2pa>
f0101ff8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ffb:	0f 85 48 09 00 00    	jne    f0102949 <mem_init+0x14ff>
	assert(pp1->pp_ref == 0);
f0102001:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102006:	0f 85 5f 09 00 00    	jne    f010296b <mem_init+0x1521>
	assert(pp2->pp_ref == 0);
f010200c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102011:	0f 85 76 09 00 00    	jne    f010298d <mem_init+0x1543>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102017:	83 ec 0c             	sub    $0xc,%esp
f010201a:	6a 00                	push   $0x0
f010201c:	e8 52 f0 ff ff       	call   f0101073 <page_alloc>
f0102021:	83 c4 10             	add    $0x10,%esp
f0102024:	85 c0                	test   %eax,%eax
f0102026:	0f 84 83 09 00 00    	je     f01029af <mem_init+0x1565>
f010202c:	39 c7                	cmp    %eax,%edi
f010202e:	0f 85 7b 09 00 00    	jne    f01029af <mem_init+0x1565>

	// should be no free memory
	assert(!page_alloc(0));
f0102034:	83 ec 0c             	sub    $0xc,%esp
f0102037:	6a 00                	push   $0x0
f0102039:	e8 35 f0 ff ff       	call   f0101073 <page_alloc>
f010203e:	83 c4 10             	add    $0x10,%esp
f0102041:	85 c0                	test   %eax,%eax
f0102043:	0f 85 88 09 00 00    	jne    f01029d1 <mem_init+0x1587>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102049:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010204c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102052:	8b 08                	mov    (%eax),%ecx
f0102054:	8b 11                	mov    (%ecx),%edx
f0102056:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010205c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102062:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102065:	2b 18                	sub    (%eax),%ebx
f0102067:	89 d8                	mov    %ebx,%eax
f0102069:	c1 f8 03             	sar    $0x3,%eax
f010206c:	c1 e0 0c             	shl    $0xc,%eax
f010206f:	39 c2                	cmp    %eax,%edx
f0102071:	0f 85 7c 09 00 00    	jne    f01029f3 <mem_init+0x15a9>
	kern_pgdir[0] = 0;
f0102077:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010207d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102080:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102085:	0f 85 8a 09 00 00    	jne    f0102a15 <mem_init+0x15cb>
	pp0->pp_ref = 0;
f010208b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010208e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102094:	83 ec 0c             	sub    $0xc,%esp
f0102097:	50                   	push   %eax
f0102098:	e8 5e f0 ff ff       	call   f01010fb <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010209d:	83 c4 0c             	add    $0xc,%esp
f01020a0:	6a 01                	push   $0x1
f01020a2:	68 00 10 40 00       	push   $0x401000
f01020a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020aa:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f01020b0:	ff 33                	pushl  (%ebx)
f01020b2:	e8 df f0 ff ff       	call   f0101196 <pgdir_walk>
f01020b7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01020bd:	8b 1b                	mov    (%ebx),%ebx
f01020bf:	8b 53 04             	mov    0x4(%ebx),%edx
f01020c2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01020c8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01020cb:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f01020d1:	8b 09                	mov    (%ecx),%ecx
f01020d3:	89 d0                	mov    %edx,%eax
f01020d5:	c1 e8 0c             	shr    $0xc,%eax
f01020d8:	83 c4 10             	add    $0x10,%esp
f01020db:	39 c8                	cmp    %ecx,%eax
f01020dd:	0f 83 54 09 00 00    	jae    f0102a37 <mem_init+0x15ed>
	assert(ptep == ptep1 + PTX(va));
f01020e3:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01020e9:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f01020ec:	0f 85 61 09 00 00    	jne    f0102a53 <mem_init+0x1609>
	kern_pgdir[PDX(va)] = 0;
f01020f2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f01020f9:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01020fc:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102102:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102105:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010210b:	2b 18                	sub    (%eax),%ebx
f010210d:	89 d8                	mov    %ebx,%eax
f010210f:	c1 f8 03             	sar    $0x3,%eax
f0102112:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102115:	89 c2                	mov    %eax,%edx
f0102117:	c1 ea 0c             	shr    $0xc,%edx
f010211a:	39 d1                	cmp    %edx,%ecx
f010211c:	0f 86 53 09 00 00    	jbe    f0102a75 <mem_init+0x162b>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102122:	83 ec 04             	sub    $0x4,%esp
f0102125:	68 00 10 00 00       	push   $0x1000
f010212a:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010212f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102134:	50                   	push   %eax
f0102135:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102138:	e8 c5 1c 00 00       	call   f0103e02 <memset>
	page_free(pp0);
f010213d:	83 c4 04             	add    $0x4,%esp
f0102140:	ff 75 d0             	pushl  -0x30(%ebp)
f0102143:	e8 b3 ef ff ff       	call   f01010fb <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102148:	83 c4 0c             	add    $0xc,%esp
f010214b:	6a 01                	push   $0x1
f010214d:	6a 00                	push   $0x0
f010214f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102152:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102158:	ff 30                	pushl  (%eax)
f010215a:	e8 37 f0 ff ff       	call   f0101196 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f010215f:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102165:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102168:	2b 10                	sub    (%eax),%edx
f010216a:	c1 fa 03             	sar    $0x3,%edx
f010216d:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102170:	89 d1                	mov    %edx,%ecx
f0102172:	c1 e9 0c             	shr    $0xc,%ecx
f0102175:	83 c4 10             	add    $0x10,%esp
f0102178:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f010217e:	3b 08                	cmp    (%eax),%ecx
f0102180:	0f 83 08 09 00 00    	jae    f0102a8e <mem_init+0x1644>
	return (void *)(pa + KERNBASE);
f0102186:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010218c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010218f:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102195:	f6 00 01             	testb  $0x1,(%eax)
f0102198:	0f 85 09 09 00 00    	jne    f0102aa7 <mem_init+0x165d>
f010219e:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01021a1:	39 d0                	cmp    %edx,%eax
f01021a3:	75 f0                	jne    f0102195 <mem_init+0xd4b>
	kern_pgdir[0] = 0;
f01021a5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021a8:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01021ae:	8b 00                	mov    (%eax),%eax
f01021b0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021b6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021b9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01021bf:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01021c2:	89 93 90 1f 00 00    	mov    %edx,0x1f90(%ebx)

	// free the pages we took
	page_free(pp0);
f01021c8:	83 ec 0c             	sub    $0xc,%esp
f01021cb:	50                   	push   %eax
f01021cc:	e8 2a ef ff ff       	call   f01010fb <page_free>
	page_free(pp1);
f01021d1:	89 3c 24             	mov    %edi,(%esp)
f01021d4:	e8 22 ef ff ff       	call   f01010fb <page_free>
	page_free(pp2);
f01021d9:	89 34 24             	mov    %esi,(%esp)
f01021dc:	e8 1a ef ff ff       	call   f01010fb <page_free>

	cprintf("check_page() succeeded!\n");
f01021e1:	8d 83 24 d7 fe ff    	lea    -0x128dc(%ebx),%eax
f01021e7:	89 04 24             	mov    %eax,(%esp)
f01021ea:	e8 f9 0f 00 00       	call   f01031e8 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01021ef:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01021f5:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01021f7:	83 c4 10             	add    $0x10,%esp
f01021fa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021ff:	0f 86 c4 08 00 00    	jbe    f0102ac9 <mem_init+0x167f>
f0102205:	83 ec 08             	sub    $0x8,%esp
f0102208:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010220a:	05 00 00 00 10       	add    $0x10000000,%eax
f010220f:	50                   	push   %eax
f0102210:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102215:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010221a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010221d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102223:	8b 00                	mov    (%eax),%eax
f0102225:	e8 42 f0 ff ff       	call   f010126c <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010222a:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f0102230:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102233:	83 c4 10             	add    $0x10,%esp
f0102236:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010223b:	0f 86 a4 08 00 00    	jbe    f0102ae5 <mem_init+0x169b>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102241:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102244:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f010224a:	83 ec 08             	sub    $0x8,%esp
f010224d:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f010224f:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102252:	05 00 00 00 10       	add    $0x10000000,%eax
f0102257:	50                   	push   %eax
f0102258:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010225d:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102262:	8b 03                	mov    (%ebx),%eax
f0102264:	e8 03 f0 ff ff       	call   f010126c <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f0102269:	83 c4 08             	add    $0x8,%esp
f010226c:	6a 02                	push   $0x2
f010226e:	6a 00                	push   $0x0
f0102270:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102275:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010227a:	8b 03                	mov    (%ebx),%eax
f010227c:	e8 eb ef ff ff       	call   f010126c <boot_map_region>
	pgdir = kern_pgdir;
f0102281:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102283:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0102289:	8b 00                	mov    (%eax),%eax
f010228b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010228e:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102295:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010229a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010229d:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01022a3:	8b 00                	mov    (%eax),%eax
f01022a5:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01022a8:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01022ab:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f01022b1:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f01022b4:	bf 00 00 00 00       	mov    $0x0,%edi
f01022b9:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f01022bc:	0f 86 84 08 00 00    	jbe    f0102b46 <mem_init+0x16fc>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022c2:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f01022c8:	89 f0                	mov    %esi,%eax
f01022ca:	e8 c1 e8 ff ff       	call   f0100b90 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01022cf:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01022d6:	0f 86 2a 08 00 00    	jbe    f0102b06 <mem_init+0x16bc>
f01022dc:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f01022df:	39 c2                	cmp    %eax,%edx
f01022e1:	0f 85 3d 08 00 00    	jne    f0102b24 <mem_init+0x16da>
	for (i = 0; i < n; i += PGSIZE)
f01022e7:	81 c7 00 10 00 00    	add    $0x1000,%edi
f01022ed:	eb ca                	jmp    f01022b9 <mem_init+0xe6f>
	assert(nfree == 0);
f01022ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022f2:	8d 83 4d d6 fe ff    	lea    -0x129b3(%ebx),%eax
f01022f8:	50                   	push   %eax
f01022f9:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01022ff:	50                   	push   %eax
f0102300:	68 1c 03 00 00       	push   $0x31c
f0102305:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010230b:	50                   	push   %eax
f010230c:	e8 ee dd ff ff       	call   f01000ff <_panic>
	assert((pp0 = page_alloc(0)));
f0102311:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102314:	8d 83 5b d5 fe ff    	lea    -0x12aa5(%ebx),%eax
f010231a:	50                   	push   %eax
f010231b:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102321:	50                   	push   %eax
f0102322:	68 75 03 00 00       	push   $0x375
f0102327:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010232d:	50                   	push   %eax
f010232e:	e8 cc dd ff ff       	call   f01000ff <_panic>
	assert((pp1 = page_alloc(0)));
f0102333:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102336:	8d 83 71 d5 fe ff    	lea    -0x12a8f(%ebx),%eax
f010233c:	50                   	push   %eax
f010233d:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102343:	50                   	push   %eax
f0102344:	68 76 03 00 00       	push   $0x376
f0102349:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010234f:	50                   	push   %eax
f0102350:	e8 aa dd ff ff       	call   f01000ff <_panic>
	assert((pp2 = page_alloc(0)));
f0102355:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102358:	8d 83 87 d5 fe ff    	lea    -0x12a79(%ebx),%eax
f010235e:	50                   	push   %eax
f010235f:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102365:	50                   	push   %eax
f0102366:	68 77 03 00 00       	push   $0x377
f010236b:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102371:	50                   	push   %eax
f0102372:	e8 88 dd ff ff       	call   f01000ff <_panic>
	assert(pp1 && pp1 != pp0);
f0102377:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010237a:	8d 83 9d d5 fe ff    	lea    -0x12a63(%ebx),%eax
f0102380:	50                   	push   %eax
f0102381:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102387:	50                   	push   %eax
f0102388:	68 7a 03 00 00       	push   $0x37a
f010238d:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102393:	50                   	push   %eax
f0102394:	e8 66 dd ff ff       	call   f01000ff <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102399:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010239c:	8d 83 fc d8 fe ff    	lea    -0x12704(%ebx),%eax
f01023a2:	50                   	push   %eax
f01023a3:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01023a9:	50                   	push   %eax
f01023aa:	68 7b 03 00 00       	push   $0x37b
f01023af:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01023b5:	50                   	push   %eax
f01023b6:	e8 44 dd ff ff       	call   f01000ff <_panic>
	assert(!page_alloc(0));
f01023bb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023be:	8d 83 06 d6 fe ff    	lea    -0x129fa(%ebx),%eax
f01023c4:	50                   	push   %eax
f01023c5:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01023cb:	50                   	push   %eax
f01023cc:	68 82 03 00 00       	push   $0x382
f01023d1:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01023d7:	50                   	push   %eax
f01023d8:	e8 22 dd ff ff       	call   f01000ff <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01023dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023e0:	8d 83 3c d9 fe ff    	lea    -0x126c4(%ebx),%eax
f01023e6:	50                   	push   %eax
f01023e7:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01023ed:	50                   	push   %eax
f01023ee:	68 85 03 00 00       	push   $0x385
f01023f3:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01023f9:	50                   	push   %eax
f01023fa:	e8 00 dd ff ff       	call   f01000ff <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01023ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102402:	8d 83 74 d9 fe ff    	lea    -0x1268c(%ebx),%eax
f0102408:	50                   	push   %eax
f0102409:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010240f:	50                   	push   %eax
f0102410:	68 88 03 00 00       	push   $0x388
f0102415:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010241b:	50                   	push   %eax
f010241c:	e8 de dc ff ff       	call   f01000ff <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102421:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102424:	8d 83 a4 d9 fe ff    	lea    -0x1265c(%ebx),%eax
f010242a:	50                   	push   %eax
f010242b:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102431:	50                   	push   %eax
f0102432:	68 8c 03 00 00       	push   $0x38c
f0102437:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010243d:	50                   	push   %eax
f010243e:	e8 bc dc ff ff       	call   f01000ff <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102443:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102446:	8d 83 d4 d9 fe ff    	lea    -0x1262c(%ebx),%eax
f010244c:	50                   	push   %eax
f010244d:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102453:	50                   	push   %eax
f0102454:	68 8d 03 00 00       	push   $0x38d
f0102459:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010245f:	50                   	push   %eax
f0102460:	e8 9a dc ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102465:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102468:	8d 83 fc d9 fe ff    	lea    -0x12604(%ebx),%eax
f010246e:	50                   	push   %eax
f010246f:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102475:	50                   	push   %eax
f0102476:	68 8e 03 00 00       	push   $0x38e
f010247b:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102481:	50                   	push   %eax
f0102482:	e8 78 dc ff ff       	call   f01000ff <_panic>
	assert(pp1->pp_ref == 1);
f0102487:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010248a:	8d 83 58 d6 fe ff    	lea    -0x129a8(%ebx),%eax
f0102490:	50                   	push   %eax
f0102491:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102497:	50                   	push   %eax
f0102498:	68 8f 03 00 00       	push   $0x38f
f010249d:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01024a3:	50                   	push   %eax
f01024a4:	e8 56 dc ff ff       	call   f01000ff <_panic>
	assert(pp0->pp_ref == 1);
f01024a9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024ac:	8d 83 69 d6 fe ff    	lea    -0x12997(%ebx),%eax
f01024b2:	50                   	push   %eax
f01024b3:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01024b9:	50                   	push   %eax
f01024ba:	68 90 03 00 00       	push   $0x390
f01024bf:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01024c5:	50                   	push   %eax
f01024c6:	e8 34 dc ff ff       	call   f01000ff <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024cb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024ce:	8d 83 2c da fe ff    	lea    -0x125d4(%ebx),%eax
f01024d4:	50                   	push   %eax
f01024d5:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01024db:	50                   	push   %eax
f01024dc:	68 93 03 00 00       	push   $0x393
f01024e1:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01024e7:	50                   	push   %eax
f01024e8:	e8 12 dc ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024ed:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024f0:	8d 83 68 da fe ff    	lea    -0x12598(%ebx),%eax
f01024f6:	50                   	push   %eax
f01024f7:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01024fd:	50                   	push   %eax
f01024fe:	68 94 03 00 00       	push   $0x394
f0102503:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102509:	50                   	push   %eax
f010250a:	e8 f0 db ff ff       	call   f01000ff <_panic>
	assert(pp2->pp_ref == 1);
f010250f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102512:	8d 83 7a d6 fe ff    	lea    -0x12986(%ebx),%eax
f0102518:	50                   	push   %eax
f0102519:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010251f:	50                   	push   %eax
f0102520:	68 95 03 00 00       	push   $0x395
f0102525:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010252b:	50                   	push   %eax
f010252c:	e8 ce db ff ff       	call   f01000ff <_panic>
	assert(!page_alloc(0));
f0102531:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102534:	8d 83 06 d6 fe ff    	lea    -0x129fa(%ebx),%eax
f010253a:	50                   	push   %eax
f010253b:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102541:	50                   	push   %eax
f0102542:	68 98 03 00 00       	push   $0x398
f0102547:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010254d:	50                   	push   %eax
f010254e:	e8 ac db ff ff       	call   f01000ff <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102553:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102556:	8d 83 2c da fe ff    	lea    -0x125d4(%ebx),%eax
f010255c:	50                   	push   %eax
f010255d:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102563:	50                   	push   %eax
f0102564:	68 9b 03 00 00       	push   $0x39b
f0102569:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010256f:	50                   	push   %eax
f0102570:	e8 8a db ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102575:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102578:	8d 83 68 da fe ff    	lea    -0x12598(%ebx),%eax
f010257e:	50                   	push   %eax
f010257f:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102585:	50                   	push   %eax
f0102586:	68 9c 03 00 00       	push   $0x39c
f010258b:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102591:	50                   	push   %eax
f0102592:	e8 68 db ff ff       	call   f01000ff <_panic>
	assert(pp2->pp_ref == 1);
f0102597:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010259a:	8d 83 7a d6 fe ff    	lea    -0x12986(%ebx),%eax
f01025a0:	50                   	push   %eax
f01025a1:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01025a7:	50                   	push   %eax
f01025a8:	68 9d 03 00 00       	push   $0x39d
f01025ad:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01025b3:	50                   	push   %eax
f01025b4:	e8 46 db ff ff       	call   f01000ff <_panic>
	assert(!page_alloc(0));
f01025b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025bc:	8d 83 06 d6 fe ff    	lea    -0x129fa(%ebx),%eax
f01025c2:	50                   	push   %eax
f01025c3:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01025c9:	50                   	push   %eax
f01025ca:	68 a1 03 00 00       	push   $0x3a1
f01025cf:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01025d5:	50                   	push   %eax
f01025d6:	e8 24 db ff ff       	call   f01000ff <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025db:	50                   	push   %eax
f01025dc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025df:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f01025e5:	50                   	push   %eax
f01025e6:	68 a4 03 00 00       	push   $0x3a4
f01025eb:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01025f1:	50                   	push   %eax
f01025f2:	e8 08 db ff ff       	call   f01000ff <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01025f7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025fa:	8d 83 98 da fe ff    	lea    -0x12568(%ebx),%eax
f0102600:	50                   	push   %eax
f0102601:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102607:	50                   	push   %eax
f0102608:	68 a5 03 00 00       	push   $0x3a5
f010260d:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102613:	50                   	push   %eax
f0102614:	e8 e6 da ff ff       	call   f01000ff <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102619:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010261c:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0102622:	50                   	push   %eax
f0102623:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102629:	50                   	push   %eax
f010262a:	68 a8 03 00 00       	push   $0x3a8
f010262f:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102635:	50                   	push   %eax
f0102636:	e8 c4 da ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010263b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010263e:	8d 83 68 da fe ff    	lea    -0x12598(%ebx),%eax
f0102644:	50                   	push   %eax
f0102645:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010264b:	50                   	push   %eax
f010264c:	68 a9 03 00 00       	push   $0x3a9
f0102651:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102657:	50                   	push   %eax
f0102658:	e8 a2 da ff ff       	call   f01000ff <_panic>
	assert(pp2->pp_ref == 1);
f010265d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102660:	8d 83 7a d6 fe ff    	lea    -0x12986(%ebx),%eax
f0102666:	50                   	push   %eax
f0102667:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010266d:	50                   	push   %eax
f010266e:	68 aa 03 00 00       	push   $0x3aa
f0102673:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102679:	50                   	push   %eax
f010267a:	e8 80 da ff ff       	call   f01000ff <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010267f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102682:	8d 83 18 db fe ff    	lea    -0x124e8(%ebx),%eax
f0102688:	50                   	push   %eax
f0102689:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010268f:	50                   	push   %eax
f0102690:	68 ab 03 00 00       	push   $0x3ab
f0102695:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f010269b:	50                   	push   %eax
f010269c:	e8 5e da ff ff       	call   f01000ff <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01026a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026a4:	8d 83 8b d6 fe ff    	lea    -0x12975(%ebx),%eax
f01026aa:	50                   	push   %eax
f01026ab:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01026b1:	50                   	push   %eax
f01026b2:	68 ac 03 00 00       	push   $0x3ac
f01026b7:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01026bd:	50                   	push   %eax
f01026be:	e8 3c da ff ff       	call   f01000ff <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01026c3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026c6:	8d 83 2c da fe ff    	lea    -0x125d4(%ebx),%eax
f01026cc:	50                   	push   %eax
f01026cd:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01026d3:	50                   	push   %eax
f01026d4:	68 af 03 00 00       	push   $0x3af
f01026d9:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01026df:	50                   	push   %eax
f01026e0:	e8 1a da ff ff       	call   f01000ff <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01026e5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026e8:	8d 83 4c db fe ff    	lea    -0x124b4(%ebx),%eax
f01026ee:	50                   	push   %eax
f01026ef:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01026f5:	50                   	push   %eax
f01026f6:	68 b0 03 00 00       	push   $0x3b0
f01026fb:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102701:	50                   	push   %eax
f0102702:	e8 f8 d9 ff ff       	call   f01000ff <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102707:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010270a:	8d 83 80 db fe ff    	lea    -0x12480(%ebx),%eax
f0102710:	50                   	push   %eax
f0102711:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102717:	50                   	push   %eax
f0102718:	68 b1 03 00 00       	push   $0x3b1
f010271d:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102723:	50                   	push   %eax
f0102724:	e8 d6 d9 ff ff       	call   f01000ff <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102729:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010272c:	8d 83 b8 db fe ff    	lea    -0x12448(%ebx),%eax
f0102732:	50                   	push   %eax
f0102733:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102739:	50                   	push   %eax
f010273a:	68 b4 03 00 00       	push   $0x3b4
f010273f:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102745:	50                   	push   %eax
f0102746:	e8 b4 d9 ff ff       	call   f01000ff <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010274b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010274e:	8d 83 f0 db fe ff    	lea    -0x12410(%ebx),%eax
f0102754:	50                   	push   %eax
f0102755:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010275b:	50                   	push   %eax
f010275c:	68 b7 03 00 00       	push   $0x3b7
f0102761:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102767:	50                   	push   %eax
f0102768:	e8 92 d9 ff ff       	call   f01000ff <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010276d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102770:	8d 83 80 db fe ff    	lea    -0x12480(%ebx),%eax
f0102776:	50                   	push   %eax
f0102777:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010277d:	50                   	push   %eax
f010277e:	68 b8 03 00 00       	push   $0x3b8
f0102783:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102789:	50                   	push   %eax
f010278a:	e8 70 d9 ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010278f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102792:	8d 83 2c dc fe ff    	lea    -0x123d4(%ebx),%eax
f0102798:	50                   	push   %eax
f0102799:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010279f:	50                   	push   %eax
f01027a0:	68 bb 03 00 00       	push   $0x3bb
f01027a5:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01027ab:	50                   	push   %eax
f01027ac:	e8 4e d9 ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027b4:	8d 83 58 dc fe ff    	lea    -0x123a8(%ebx),%eax
f01027ba:	50                   	push   %eax
f01027bb:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01027c1:	50                   	push   %eax
f01027c2:	68 bc 03 00 00       	push   $0x3bc
f01027c7:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01027cd:	50                   	push   %eax
f01027ce:	e8 2c d9 ff ff       	call   f01000ff <_panic>
	assert(pp1->pp_ref == 2);
f01027d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027d6:	8d 83 a1 d6 fe ff    	lea    -0x1295f(%ebx),%eax
f01027dc:	50                   	push   %eax
f01027dd:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01027e3:	50                   	push   %eax
f01027e4:	68 be 03 00 00       	push   $0x3be
f01027e9:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01027ef:	50                   	push   %eax
f01027f0:	e8 0a d9 ff ff       	call   f01000ff <_panic>
	assert(pp2->pp_ref == 0);
f01027f5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027f8:	8d 83 b2 d6 fe ff    	lea    -0x1294e(%ebx),%eax
f01027fe:	50                   	push   %eax
f01027ff:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102805:	50                   	push   %eax
f0102806:	68 bf 03 00 00       	push   $0x3bf
f010280b:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102811:	50                   	push   %eax
f0102812:	e8 e8 d8 ff ff       	call   f01000ff <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102817:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010281a:	8d 83 88 dc fe ff    	lea    -0x12378(%ebx),%eax
f0102820:	50                   	push   %eax
f0102821:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102827:	50                   	push   %eax
f0102828:	68 c2 03 00 00       	push   $0x3c2
f010282d:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102833:	50                   	push   %eax
f0102834:	e8 c6 d8 ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102839:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010283c:	8d 83 ac dc fe ff    	lea    -0x12354(%ebx),%eax
f0102842:	50                   	push   %eax
f0102843:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102849:	50                   	push   %eax
f010284a:	68 c6 03 00 00       	push   $0x3c6
f010284f:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102855:	50                   	push   %eax
f0102856:	e8 a4 d8 ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010285b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010285e:	8d 83 58 dc fe ff    	lea    -0x123a8(%ebx),%eax
f0102864:	50                   	push   %eax
f0102865:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010286b:	50                   	push   %eax
f010286c:	68 c7 03 00 00       	push   $0x3c7
f0102871:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102877:	50                   	push   %eax
f0102878:	e8 82 d8 ff ff       	call   f01000ff <_panic>
	assert(pp1->pp_ref == 1);
f010287d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102880:	8d 83 58 d6 fe ff    	lea    -0x129a8(%ebx),%eax
f0102886:	50                   	push   %eax
f0102887:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010288d:	50                   	push   %eax
f010288e:	68 c8 03 00 00       	push   $0x3c8
f0102893:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102899:	50                   	push   %eax
f010289a:	e8 60 d8 ff ff       	call   f01000ff <_panic>
	assert(pp2->pp_ref == 0);
f010289f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028a2:	8d 83 b2 d6 fe ff    	lea    -0x1294e(%ebx),%eax
f01028a8:	50                   	push   %eax
f01028a9:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01028af:	50                   	push   %eax
f01028b0:	68 c9 03 00 00       	push   $0x3c9
f01028b5:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01028bb:	50                   	push   %eax
f01028bc:	e8 3e d8 ff ff       	call   f01000ff <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01028c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028c4:	8d 83 d0 dc fe ff    	lea    -0x12330(%ebx),%eax
f01028ca:	50                   	push   %eax
f01028cb:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01028d1:	50                   	push   %eax
f01028d2:	68 cc 03 00 00       	push   $0x3cc
f01028d7:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01028dd:	50                   	push   %eax
f01028de:	e8 1c d8 ff ff       	call   f01000ff <_panic>
	assert(pp1->pp_ref);
f01028e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028e6:	8d 83 c3 d6 fe ff    	lea    -0x1293d(%ebx),%eax
f01028ec:	50                   	push   %eax
f01028ed:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01028f3:	50                   	push   %eax
f01028f4:	68 cd 03 00 00       	push   $0x3cd
f01028f9:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01028ff:	50                   	push   %eax
f0102900:	e8 fa d7 ff ff       	call   f01000ff <_panic>
	assert(pp1->pp_link == NULL);
f0102905:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102908:	8d 83 cf d6 fe ff    	lea    -0x12931(%ebx),%eax
f010290e:	50                   	push   %eax
f010290f:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102915:	50                   	push   %eax
f0102916:	68 ce 03 00 00       	push   $0x3ce
f010291b:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102921:	50                   	push   %eax
f0102922:	e8 d8 d7 ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102927:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010292a:	8d 83 ac dc fe ff    	lea    -0x12354(%ebx),%eax
f0102930:	50                   	push   %eax
f0102931:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102937:	50                   	push   %eax
f0102938:	68 d2 03 00 00       	push   $0x3d2
f010293d:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102943:	50                   	push   %eax
f0102944:	e8 b6 d7 ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102949:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010294c:	8d 83 08 dd fe ff    	lea    -0x122f8(%ebx),%eax
f0102952:	50                   	push   %eax
f0102953:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102959:	50                   	push   %eax
f010295a:	68 d3 03 00 00       	push   $0x3d3
f010295f:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102965:	50                   	push   %eax
f0102966:	e8 94 d7 ff ff       	call   f01000ff <_panic>
	assert(pp1->pp_ref == 0);
f010296b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010296e:	8d 83 e4 d6 fe ff    	lea    -0x1291c(%ebx),%eax
f0102974:	50                   	push   %eax
f0102975:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010297b:	50                   	push   %eax
f010297c:	68 d4 03 00 00       	push   $0x3d4
f0102981:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102987:	50                   	push   %eax
f0102988:	e8 72 d7 ff ff       	call   f01000ff <_panic>
	assert(pp2->pp_ref == 0);
f010298d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102990:	8d 83 b2 d6 fe ff    	lea    -0x1294e(%ebx),%eax
f0102996:	50                   	push   %eax
f0102997:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010299d:	50                   	push   %eax
f010299e:	68 d5 03 00 00       	push   $0x3d5
f01029a3:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01029a9:	50                   	push   %eax
f01029aa:	e8 50 d7 ff ff       	call   f01000ff <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01029af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029b2:	8d 83 30 dd fe ff    	lea    -0x122d0(%ebx),%eax
f01029b8:	50                   	push   %eax
f01029b9:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01029bf:	50                   	push   %eax
f01029c0:	68 d8 03 00 00       	push   $0x3d8
f01029c5:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01029cb:	50                   	push   %eax
f01029cc:	e8 2e d7 ff ff       	call   f01000ff <_panic>
	assert(!page_alloc(0));
f01029d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029d4:	8d 83 06 d6 fe ff    	lea    -0x129fa(%ebx),%eax
f01029da:	50                   	push   %eax
f01029db:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01029e1:	50                   	push   %eax
f01029e2:	68 db 03 00 00       	push   $0x3db
f01029e7:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01029ed:	50                   	push   %eax
f01029ee:	e8 0c d7 ff ff       	call   f01000ff <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01029f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029f6:	8d 83 d4 d9 fe ff    	lea    -0x1262c(%ebx),%eax
f01029fc:	50                   	push   %eax
f01029fd:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102a03:	50                   	push   %eax
f0102a04:	68 de 03 00 00       	push   $0x3de
f0102a09:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102a0f:	50                   	push   %eax
f0102a10:	e8 ea d6 ff ff       	call   f01000ff <_panic>
	assert(pp0->pp_ref == 1);
f0102a15:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a18:	8d 83 69 d6 fe ff    	lea    -0x12997(%ebx),%eax
f0102a1e:	50                   	push   %eax
f0102a1f:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102a25:	50                   	push   %eax
f0102a26:	68 e0 03 00 00       	push   $0x3e0
f0102a2b:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102a31:	50                   	push   %eax
f0102a32:	e8 c8 d6 ff ff       	call   f01000ff <_panic>
f0102a37:	52                   	push   %edx
f0102a38:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a3b:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0102a41:	50                   	push   %eax
f0102a42:	68 e7 03 00 00       	push   $0x3e7
f0102a47:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102a4d:	50                   	push   %eax
f0102a4e:	e8 ac d6 ff ff       	call   f01000ff <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102a53:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a56:	8d 83 f5 d6 fe ff    	lea    -0x1290b(%ebx),%eax
f0102a5c:	50                   	push   %eax
f0102a5d:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102a63:	50                   	push   %eax
f0102a64:	68 e8 03 00 00       	push   $0x3e8
f0102a69:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102a6f:	50                   	push   %eax
f0102a70:	e8 8a d6 ff ff       	call   f01000ff <_panic>
f0102a75:	50                   	push   %eax
f0102a76:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a79:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0102a7f:	50                   	push   %eax
f0102a80:	6a 64                	push   $0x64
f0102a82:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f0102a88:	50                   	push   %eax
f0102a89:	e8 71 d6 ff ff       	call   f01000ff <_panic>
f0102a8e:	52                   	push   %edx
f0102a8f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a92:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0102a98:	50                   	push   %eax
f0102a99:	6a 64                	push   $0x64
f0102a9b:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f0102aa1:	50                   	push   %eax
f0102aa2:	e8 58 d6 ff ff       	call   f01000ff <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102aa7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102aaa:	8d 83 0d d7 fe ff    	lea    -0x128f3(%ebx),%eax
f0102ab0:	50                   	push   %eax
f0102ab1:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102ab7:	50                   	push   %eax
f0102ab8:	68 f2 03 00 00       	push   $0x3f2
f0102abd:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102ac3:	50                   	push   %eax
f0102ac4:	e8 36 d6 ff ff       	call   f01000ff <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ac9:	50                   	push   %eax
f0102aca:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102acd:	8d 83 d8 d8 fe ff    	lea    -0x12728(%ebx),%eax
f0102ad3:	50                   	push   %eax
f0102ad4:	68 c3 00 00 00       	push   $0xc3
f0102ad9:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102adf:	50                   	push   %eax
f0102ae0:	e8 1a d6 ff ff       	call   f01000ff <_panic>
f0102ae5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ae8:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102aee:	8d 83 d8 d8 fe ff    	lea    -0x12728(%ebx),%eax
f0102af4:	50                   	push   %eax
f0102af5:	68 d1 00 00 00       	push   $0xd1
f0102afa:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102b00:	50                   	push   %eax
f0102b01:	e8 f9 d5 ff ff       	call   f01000ff <_panic>
f0102b06:	ff 75 c0             	pushl  -0x40(%ebp)
f0102b09:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b0c:	8d 83 d8 d8 fe ff    	lea    -0x12728(%ebx),%eax
f0102b12:	50                   	push   %eax
f0102b13:	68 34 03 00 00       	push   $0x334
f0102b18:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102b1e:	50                   	push   %eax
f0102b1f:	e8 db d5 ff ff       	call   f01000ff <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102b24:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b27:	8d 83 54 dd fe ff    	lea    -0x122ac(%ebx),%eax
f0102b2d:	50                   	push   %eax
f0102b2e:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102b34:	50                   	push   %eax
f0102b35:	68 34 03 00 00       	push   $0x334
f0102b3a:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102b40:	50                   	push   %eax
f0102b41:	e8 b9 d5 ff ff       	call   f01000ff <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b46:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102b49:	c1 e7 0c             	shl    $0xc,%edi
f0102b4c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102b51:	eb 17                	jmp    f0102b6a <mem_init+0x1720>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102b53:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102b59:	89 f0                	mov    %esi,%eax
f0102b5b:	e8 30 e0 ff ff       	call   f0100b90 <check_va2pa>
f0102b60:	39 c3                	cmp    %eax,%ebx
f0102b62:	75 51                	jne    f0102bb5 <mem_init+0x176b>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b64:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102b6a:	39 fb                	cmp    %edi,%ebx
f0102b6c:	72 e5                	jb     f0102b53 <mem_init+0x1709>
f0102b6e:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b73:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102b76:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102b7c:	89 da                	mov    %ebx,%edx
f0102b7e:	89 f0                	mov    %esi,%eax
f0102b80:	e8 0b e0 ff ff       	call   f0100b90 <check_va2pa>
f0102b85:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102b88:	39 c2                	cmp    %eax,%edx
f0102b8a:	75 4b                	jne    f0102bd7 <mem_init+0x178d>
f0102b8c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b92:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102b98:	75 e2                	jne    f0102b7c <mem_init+0x1732>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b9a:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b9f:	89 f0                	mov    %esi,%eax
f0102ba1:	e8 ea df ff ff       	call   f0100b90 <check_va2pa>
f0102ba6:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102ba9:	75 4e                	jne    f0102bf9 <mem_init+0x17af>
	for (i = 0; i < NPDENTRIES; i++) {
f0102bab:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb0:	e9 8f 00 00 00       	jmp    f0102c44 <mem_init+0x17fa>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102bb5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bb8:	8d 83 88 dd fe ff    	lea    -0x12278(%ebx),%eax
f0102bbe:	50                   	push   %eax
f0102bbf:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102bc5:	50                   	push   %eax
f0102bc6:	68 39 03 00 00       	push   $0x339
f0102bcb:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102bd1:	50                   	push   %eax
f0102bd2:	e8 28 d5 ff ff       	call   f01000ff <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102bd7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bda:	8d 83 b0 dd fe ff    	lea    -0x12250(%ebx),%eax
f0102be0:	50                   	push   %eax
f0102be1:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102be7:	50                   	push   %eax
f0102be8:	68 3d 03 00 00       	push   $0x33d
f0102bed:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102bf3:	50                   	push   %eax
f0102bf4:	e8 06 d5 ff ff       	call   f01000ff <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102bf9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bfc:	8d 83 f8 dd fe ff    	lea    -0x12208(%ebx),%eax
f0102c02:	50                   	push   %eax
f0102c03:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102c09:	50                   	push   %eax
f0102c0a:	68 3e 03 00 00       	push   $0x33e
f0102c0f:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102c15:	50                   	push   %eax
f0102c16:	e8 e4 d4 ff ff       	call   f01000ff <_panic>
			assert(pgdir[i] & PTE_P);
f0102c1b:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102c1f:	74 52                	je     f0102c73 <mem_init+0x1829>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c21:	83 c0 01             	add    $0x1,%eax
f0102c24:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102c29:	0f 87 bb 00 00 00    	ja     f0102cea <mem_init+0x18a0>
		switch (i) {
f0102c2f:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102c34:	72 0e                	jb     f0102c44 <mem_init+0x17fa>
f0102c36:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102c3b:	76 de                	jbe    f0102c1b <mem_init+0x17d1>
f0102c3d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c42:	74 d7                	je     f0102c1b <mem_init+0x17d1>
			if (i >= PDX(KERNBASE)) {
f0102c44:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c49:	77 4a                	ja     f0102c95 <mem_init+0x184b>
				assert(pgdir[i] == 0);
f0102c4b:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102c4f:	74 d0                	je     f0102c21 <mem_init+0x17d7>
f0102c51:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c54:	8d 83 5f d7 fe ff    	lea    -0x128a1(%ebx),%eax
f0102c5a:	50                   	push   %eax
f0102c5b:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102c61:	50                   	push   %eax
f0102c62:	68 4d 03 00 00       	push   $0x34d
f0102c67:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102c6d:	50                   	push   %eax
f0102c6e:	e8 8c d4 ff ff       	call   f01000ff <_panic>
			assert(pgdir[i] & PTE_P);
f0102c73:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c76:	8d 83 3d d7 fe ff    	lea    -0x128c3(%ebx),%eax
f0102c7c:	50                   	push   %eax
f0102c7d:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102c83:	50                   	push   %eax
f0102c84:	68 46 03 00 00       	push   $0x346
f0102c89:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102c8f:	50                   	push   %eax
f0102c90:	e8 6a d4 ff ff       	call   f01000ff <_panic>
				assert(pgdir[i] & PTE_P);
f0102c95:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102c98:	f6 c2 01             	test   $0x1,%dl
f0102c9b:	74 2b                	je     f0102cc8 <mem_init+0x187e>
				assert(pgdir[i] & PTE_W);
f0102c9d:	f6 c2 02             	test   $0x2,%dl
f0102ca0:	0f 85 7b ff ff ff    	jne    f0102c21 <mem_init+0x17d7>
f0102ca6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ca9:	8d 83 4e d7 fe ff    	lea    -0x128b2(%ebx),%eax
f0102caf:	50                   	push   %eax
f0102cb0:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102cb6:	50                   	push   %eax
f0102cb7:	68 4b 03 00 00       	push   $0x34b
f0102cbc:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102cc2:	50                   	push   %eax
f0102cc3:	e8 37 d4 ff ff       	call   f01000ff <_panic>
				assert(pgdir[i] & PTE_P);
f0102cc8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ccb:	8d 83 3d d7 fe ff    	lea    -0x128c3(%ebx),%eax
f0102cd1:	50                   	push   %eax
f0102cd2:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102cd8:	50                   	push   %eax
f0102cd9:	68 4a 03 00 00       	push   $0x34a
f0102cde:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102ce4:	50                   	push   %eax
f0102ce5:	e8 15 d4 ff ff       	call   f01000ff <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102cea:	83 ec 0c             	sub    $0xc,%esp
f0102ced:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102cf0:	8d 87 28 de fe ff    	lea    -0x121d8(%edi),%eax
f0102cf6:	50                   	push   %eax
f0102cf7:	89 fb                	mov    %edi,%ebx
f0102cf9:	e8 ea 04 00 00       	call   f01031e8 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102cfe:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d04:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102d06:	83 c4 10             	add    $0x10,%esp
f0102d09:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d0e:	0f 86 44 02 00 00    	jbe    f0102f58 <mem_init+0x1b0e>
	return (physaddr_t)kva - KERNBASE;
f0102d14:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102d19:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102d1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d21:	e8 e7 de ff ff       	call   f0100c0d <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102d26:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102d29:	83 e0 f3             	and    $0xfffffff3,%eax
f0102d2c:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102d31:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102d34:	83 ec 0c             	sub    $0xc,%esp
f0102d37:	6a 00                	push   $0x0
f0102d39:	e8 35 e3 ff ff       	call   f0101073 <page_alloc>
f0102d3e:	89 c6                	mov    %eax,%esi
f0102d40:	83 c4 10             	add    $0x10,%esp
f0102d43:	85 c0                	test   %eax,%eax
f0102d45:	0f 84 29 02 00 00    	je     f0102f74 <mem_init+0x1b2a>
	assert((pp1 = page_alloc(0)));
f0102d4b:	83 ec 0c             	sub    $0xc,%esp
f0102d4e:	6a 00                	push   $0x0
f0102d50:	e8 1e e3 ff ff       	call   f0101073 <page_alloc>
f0102d55:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102d58:	83 c4 10             	add    $0x10,%esp
f0102d5b:	85 c0                	test   %eax,%eax
f0102d5d:	0f 84 33 02 00 00    	je     f0102f96 <mem_init+0x1b4c>
	assert((pp2 = page_alloc(0)));
f0102d63:	83 ec 0c             	sub    $0xc,%esp
f0102d66:	6a 00                	push   $0x0
f0102d68:	e8 06 e3 ff ff       	call   f0101073 <page_alloc>
f0102d6d:	89 c7                	mov    %eax,%edi
f0102d6f:	83 c4 10             	add    $0x10,%esp
f0102d72:	85 c0                	test   %eax,%eax
f0102d74:	0f 84 3e 02 00 00    	je     f0102fb8 <mem_init+0x1b6e>
	page_free(pp0);
f0102d7a:	83 ec 0c             	sub    $0xc,%esp
f0102d7d:	56                   	push   %esi
f0102d7e:	e8 78 e3 ff ff       	call   f01010fb <page_free>
	return (pp - pages) << PGSHIFT;
f0102d83:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d86:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102d8c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102d8f:	2b 08                	sub    (%eax),%ecx
f0102d91:	89 c8                	mov    %ecx,%eax
f0102d93:	c1 f8 03             	sar    $0x3,%eax
f0102d96:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d99:	89 c1                	mov    %eax,%ecx
f0102d9b:	c1 e9 0c             	shr    $0xc,%ecx
f0102d9e:	83 c4 10             	add    $0x10,%esp
f0102da1:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102da7:	3b 0a                	cmp    (%edx),%ecx
f0102da9:	0f 83 2b 02 00 00    	jae    f0102fda <mem_init+0x1b90>
	memset(page2kva(pp1), 1, PGSIZE);
f0102daf:	83 ec 04             	sub    $0x4,%esp
f0102db2:	68 00 10 00 00       	push   $0x1000
f0102db7:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102db9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102dbe:	50                   	push   %eax
f0102dbf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dc2:	e8 3b 10 00 00       	call   f0103e02 <memset>
	return (pp - pages) << PGSHIFT;
f0102dc7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dca:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102dd0:	89 f9                	mov    %edi,%ecx
f0102dd2:	2b 08                	sub    (%eax),%ecx
f0102dd4:	89 c8                	mov    %ecx,%eax
f0102dd6:	c1 f8 03             	sar    $0x3,%eax
f0102dd9:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102ddc:	89 c1                	mov    %eax,%ecx
f0102dde:	c1 e9 0c             	shr    $0xc,%ecx
f0102de1:	83 c4 10             	add    $0x10,%esp
f0102de4:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102dea:	3b 0a                	cmp    (%edx),%ecx
f0102dec:	0f 83 fe 01 00 00    	jae    f0102ff0 <mem_init+0x1ba6>
	memset(page2kva(pp2), 2, PGSIZE);
f0102df2:	83 ec 04             	sub    $0x4,%esp
f0102df5:	68 00 10 00 00       	push   $0x1000
f0102dfa:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102dfc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e01:	50                   	push   %eax
f0102e02:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e05:	e8 f8 0f 00 00       	call   f0103e02 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102e0a:	6a 02                	push   $0x2
f0102e0c:	68 00 10 00 00       	push   $0x1000
f0102e11:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102e14:	53                   	push   %ebx
f0102e15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e18:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102e1e:	ff 30                	pushl  (%eax)
f0102e20:	e8 99 e5 ff ff       	call   f01013be <page_insert>
	assert(pp1->pp_ref == 1);
f0102e25:	83 c4 20             	add    $0x20,%esp
f0102e28:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e2d:	0f 85 d3 01 00 00    	jne    f0103006 <mem_init+0x1bbc>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e33:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102e3a:	01 01 01 
f0102e3d:	0f 85 e5 01 00 00    	jne    f0103028 <mem_init+0x1bde>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102e43:	6a 02                	push   $0x2
f0102e45:	68 00 10 00 00       	push   $0x1000
f0102e4a:	57                   	push   %edi
f0102e4b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e4e:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102e54:	ff 30                	pushl  (%eax)
f0102e56:	e8 63 e5 ff ff       	call   f01013be <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e5b:	83 c4 10             	add    $0x10,%esp
f0102e5e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102e65:	02 02 02 
f0102e68:	0f 85 dc 01 00 00    	jne    f010304a <mem_init+0x1c00>
	assert(pp2->pp_ref == 1);
f0102e6e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102e73:	0f 85 f3 01 00 00    	jne    f010306c <mem_init+0x1c22>
	assert(pp1->pp_ref == 0);
f0102e79:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102e7c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102e81:	0f 85 07 02 00 00    	jne    f010308e <mem_init+0x1c44>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102e87:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102e8e:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102e91:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e94:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102e9a:	89 f9                	mov    %edi,%ecx
f0102e9c:	2b 08                	sub    (%eax),%ecx
f0102e9e:	89 c8                	mov    %ecx,%eax
f0102ea0:	c1 f8 03             	sar    $0x3,%eax
f0102ea3:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102ea6:	89 c1                	mov    %eax,%ecx
f0102ea8:	c1 e9 0c             	shr    $0xc,%ecx
f0102eab:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102eb1:	3b 0a                	cmp    (%edx),%ecx
f0102eb3:	0f 83 f7 01 00 00    	jae    f01030b0 <mem_init+0x1c66>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102eb9:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102ec0:	03 03 03 
f0102ec3:	0f 85 fd 01 00 00    	jne    f01030c6 <mem_init+0x1c7c>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102ec9:	83 ec 08             	sub    $0x8,%esp
f0102ecc:	68 00 10 00 00       	push   $0x1000
f0102ed1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ed4:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102eda:	ff 30                	pushl  (%eax)
f0102edc:	e8 99 e4 ff ff       	call   f010137a <page_remove>
	assert(pp2->pp_ref == 0);
f0102ee1:	83 c4 10             	add    $0x10,%esp
f0102ee4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102ee9:	0f 85 f9 01 00 00    	jne    f01030e8 <mem_init+0x1c9e>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102eef:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102ef2:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102ef8:	8b 08                	mov    (%eax),%ecx
f0102efa:	8b 11                	mov    (%ecx),%edx
f0102efc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102f02:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102f08:	89 f7                	mov    %esi,%edi
f0102f0a:	2b 38                	sub    (%eax),%edi
f0102f0c:	89 f8                	mov    %edi,%eax
f0102f0e:	c1 f8 03             	sar    $0x3,%eax
f0102f11:	c1 e0 0c             	shl    $0xc,%eax
f0102f14:	39 c2                	cmp    %eax,%edx
f0102f16:	0f 85 ee 01 00 00    	jne    f010310a <mem_init+0x1cc0>
	kern_pgdir[0] = 0;
f0102f1c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102f22:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102f27:	0f 85 ff 01 00 00    	jne    f010312c <mem_init+0x1ce2>
	pp0->pp_ref = 0;
f0102f2d:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102f33:	83 ec 0c             	sub    $0xc,%esp
f0102f36:	56                   	push   %esi
f0102f37:	e8 bf e1 ff ff       	call   f01010fb <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102f3c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f3f:	8d 83 bc de fe ff    	lea    -0x12144(%ebx),%eax
f0102f45:	89 04 24             	mov    %eax,(%esp)
f0102f48:	e8 9b 02 00 00       	call   f01031e8 <cprintf>
}
f0102f4d:	83 c4 10             	add    $0x10,%esp
f0102f50:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f53:	5b                   	pop    %ebx
f0102f54:	5e                   	pop    %esi
f0102f55:	5f                   	pop    %edi
f0102f56:	5d                   	pop    %ebp
f0102f57:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f58:	50                   	push   %eax
f0102f59:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f5c:	8d 83 d8 d8 fe ff    	lea    -0x12728(%ebx),%eax
f0102f62:	50                   	push   %eax
f0102f63:	68 e7 00 00 00       	push   $0xe7
f0102f68:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102f6e:	50                   	push   %eax
f0102f6f:	e8 8b d1 ff ff       	call   f01000ff <_panic>
	assert((pp0 = page_alloc(0)));
f0102f74:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f77:	8d 83 5b d5 fe ff    	lea    -0x12aa5(%ebx),%eax
f0102f7d:	50                   	push   %eax
f0102f7e:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102f84:	50                   	push   %eax
f0102f85:	68 0d 04 00 00       	push   $0x40d
f0102f8a:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102f90:	50                   	push   %eax
f0102f91:	e8 69 d1 ff ff       	call   f01000ff <_panic>
	assert((pp1 = page_alloc(0)));
f0102f96:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f99:	8d 83 71 d5 fe ff    	lea    -0x12a8f(%ebx),%eax
f0102f9f:	50                   	push   %eax
f0102fa0:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102fa6:	50                   	push   %eax
f0102fa7:	68 0e 04 00 00       	push   $0x40e
f0102fac:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102fb2:	50                   	push   %eax
f0102fb3:	e8 47 d1 ff ff       	call   f01000ff <_panic>
	assert((pp2 = page_alloc(0)));
f0102fb8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fbb:	8d 83 87 d5 fe ff    	lea    -0x12a79(%ebx),%eax
f0102fc1:	50                   	push   %eax
f0102fc2:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0102fc8:	50                   	push   %eax
f0102fc9:	68 0f 04 00 00       	push   $0x40f
f0102fce:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0102fd4:	50                   	push   %eax
f0102fd5:	e8 25 d1 ff ff       	call   f01000ff <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fda:	50                   	push   %eax
f0102fdb:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0102fe1:	50                   	push   %eax
f0102fe2:	6a 64                	push   $0x64
f0102fe4:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f0102fea:	50                   	push   %eax
f0102feb:	e8 0f d1 ff ff       	call   f01000ff <_panic>
f0102ff0:	50                   	push   %eax
f0102ff1:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0102ff7:	50                   	push   %eax
f0102ff8:	6a 64                	push   $0x64
f0102ffa:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f0103000:	50                   	push   %eax
f0103001:	e8 f9 d0 ff ff       	call   f01000ff <_panic>
	assert(pp1->pp_ref == 1);
f0103006:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103009:	8d 83 58 d6 fe ff    	lea    -0x129a8(%ebx),%eax
f010300f:	50                   	push   %eax
f0103010:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0103016:	50                   	push   %eax
f0103017:	68 14 04 00 00       	push   $0x414
f010301c:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0103022:	50                   	push   %eax
f0103023:	e8 d7 d0 ff ff       	call   f01000ff <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103028:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010302b:	8d 83 48 de fe ff    	lea    -0x121b8(%ebx),%eax
f0103031:	50                   	push   %eax
f0103032:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f0103038:	50                   	push   %eax
f0103039:	68 15 04 00 00       	push   $0x415
f010303e:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0103044:	50                   	push   %eax
f0103045:	e8 b5 d0 ff ff       	call   f01000ff <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010304a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010304d:	8d 83 6c de fe ff    	lea    -0x12194(%ebx),%eax
f0103053:	50                   	push   %eax
f0103054:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010305a:	50                   	push   %eax
f010305b:	68 17 04 00 00       	push   $0x417
f0103060:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0103066:	50                   	push   %eax
f0103067:	e8 93 d0 ff ff       	call   f01000ff <_panic>
	assert(pp2->pp_ref == 1);
f010306c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010306f:	8d 83 7a d6 fe ff    	lea    -0x12986(%ebx),%eax
f0103075:	50                   	push   %eax
f0103076:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010307c:	50                   	push   %eax
f010307d:	68 18 04 00 00       	push   $0x418
f0103082:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0103088:	50                   	push   %eax
f0103089:	e8 71 d0 ff ff       	call   f01000ff <_panic>
	assert(pp1->pp_ref == 0);
f010308e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103091:	8d 83 e4 d6 fe ff    	lea    -0x1291c(%ebx),%eax
f0103097:	50                   	push   %eax
f0103098:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010309e:	50                   	push   %eax
f010309f:	68 19 04 00 00       	push   $0x419
f01030a4:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01030aa:	50                   	push   %eax
f01030ab:	e8 4f d0 ff ff       	call   f01000ff <_panic>
f01030b0:	50                   	push   %eax
f01030b1:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f01030b7:	50                   	push   %eax
f01030b8:	6a 64                	push   $0x64
f01030ba:	8d 83 51 d4 fe ff    	lea    -0x12baf(%ebx),%eax
f01030c0:	50                   	push   %eax
f01030c1:	e8 39 d0 ff ff       	call   f01000ff <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01030c6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030c9:	8d 83 90 de fe ff    	lea    -0x12170(%ebx),%eax
f01030cf:	50                   	push   %eax
f01030d0:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01030d6:	50                   	push   %eax
f01030d7:	68 1b 04 00 00       	push   $0x41b
f01030dc:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f01030e2:	50                   	push   %eax
f01030e3:	e8 17 d0 ff ff       	call   f01000ff <_panic>
	assert(pp2->pp_ref == 0);
f01030e8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030eb:	8d 83 b2 d6 fe ff    	lea    -0x1294e(%ebx),%eax
f01030f1:	50                   	push   %eax
f01030f2:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f01030f8:	50                   	push   %eax
f01030f9:	68 1d 04 00 00       	push   $0x41d
f01030fe:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0103104:	50                   	push   %eax
f0103105:	e8 f5 cf ff ff       	call   f01000ff <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010310a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010310d:	8d 83 d4 d9 fe ff    	lea    -0x1262c(%ebx),%eax
f0103113:	50                   	push   %eax
f0103114:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010311a:	50                   	push   %eax
f010311b:	68 20 04 00 00       	push   $0x420
f0103120:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0103126:	50                   	push   %eax
f0103127:	e8 d3 cf ff ff       	call   f01000ff <_panic>
	assert(pp0->pp_ref == 1);
f010312c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010312f:	8d 83 69 d6 fe ff    	lea    -0x12997(%ebx),%eax
f0103135:	50                   	push   %eax
f0103136:	8d 83 6b d4 fe ff    	lea    -0x12b95(%ebx),%eax
f010313c:	50                   	push   %eax
f010313d:	68 22 04 00 00       	push   $0x422
f0103142:	8d 83 45 d4 fe ff    	lea    -0x12bbb(%ebx),%eax
f0103148:	50                   	push   %eax
f0103149:	e8 b1 cf ff ff       	call   f01000ff <_panic>

f010314e <tlb_invalidate>:
{
f010314e:	55                   	push   %ebp
f010314f:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103151:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103154:	0f 01 38             	invlpg (%eax)
}
f0103157:	5d                   	pop    %ebp
f0103158:	c3                   	ret    

f0103159 <__x86.get_pc_thunk.cx>:
f0103159:	8b 0c 24             	mov    (%esp),%ecx
f010315c:	c3                   	ret    

f010315d <__x86.get_pc_thunk.di>:
f010315d:	8b 3c 24             	mov    (%esp),%edi
f0103160:	c3                   	ret    

f0103161 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103161:	55                   	push   %ebp
f0103162:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103164:	8b 45 08             	mov    0x8(%ebp),%eax
f0103167:	ba 70 00 00 00       	mov    $0x70,%edx
f010316c:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010316d:	ba 71 00 00 00       	mov    $0x71,%edx
f0103172:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103173:	0f b6 c0             	movzbl %al,%eax
}
f0103176:	5d                   	pop    %ebp
f0103177:	c3                   	ret    

f0103178 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103178:	55                   	push   %ebp
f0103179:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010317b:	8b 45 08             	mov    0x8(%ebp),%eax
f010317e:	ba 70 00 00 00       	mov    $0x70,%edx
f0103183:	ee                   	out    %al,(%dx)
f0103184:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103187:	ba 71 00 00 00       	mov    $0x71,%edx
f010318c:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010318d:	5d                   	pop    %ebp
f010318e:	c3                   	ret    

f010318f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010318f:	55                   	push   %ebp
f0103190:	89 e5                	mov    %esp,%ebp
f0103192:	53                   	push   %ebx
f0103193:	83 ec 10             	sub    $0x10,%esp
f0103196:	e8 1a d0 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f010319b:	81 c3 71 41 01 00    	add    $0x14171,%ebx
	cputchar(ch);
f01031a1:	ff 75 08             	pushl  0x8(%ebp)
f01031a4:	e8 83 d5 ff ff       	call   f010072c <cputchar>
	*cnt++;
}
f01031a9:	83 c4 10             	add    $0x10,%esp
f01031ac:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01031af:	c9                   	leave  
f01031b0:	c3                   	ret    

f01031b1 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01031b1:	55                   	push   %ebp
f01031b2:	89 e5                	mov    %esp,%ebp
f01031b4:	53                   	push   %ebx
f01031b5:	83 ec 14             	sub    $0x14,%esp
f01031b8:	e8 f8 cf ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f01031bd:	81 c3 4f 41 01 00    	add    $0x1414f,%ebx
	int cnt = 0;
f01031c3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01031ca:	ff 75 0c             	pushl  0xc(%ebp)
f01031cd:	ff 75 08             	pushl  0x8(%ebp)
f01031d0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01031d3:	50                   	push   %eax
f01031d4:	8d 83 83 be fe ff    	lea    -0x1417d(%ebx),%eax
f01031da:	50                   	push   %eax
f01031db:	e8 a1 04 00 00       	call   f0103681 <vprintfmt>
	return cnt;
}
f01031e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01031e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01031e6:	c9                   	leave  
f01031e7:	c3                   	ret    

f01031e8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01031e8:	55                   	push   %ebp
f01031e9:	89 e5                	mov    %esp,%ebp
f01031eb:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01031ee:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01031f1:	50                   	push   %eax
f01031f2:	ff 75 08             	pushl  0x8(%ebp)
f01031f5:	e8 b7 ff ff ff       	call   f01031b1 <vcprintf>
	va_end(ap);

	return cnt;
}
f01031fa:	c9                   	leave  
f01031fb:	c3                   	ret    

f01031fc <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01031fc:	55                   	push   %ebp
f01031fd:	89 e5                	mov    %esp,%ebp
f01031ff:	57                   	push   %edi
f0103200:	56                   	push   %esi
f0103201:	53                   	push   %ebx
f0103202:	83 ec 14             	sub    $0x14,%esp
f0103205:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103208:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010320b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010320e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103211:	8b 32                	mov    (%edx),%esi
f0103213:	8b 01                	mov    (%ecx),%eax
f0103215:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103218:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010321f:	eb 2f                	jmp    f0103250 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103221:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103224:	39 c6                	cmp    %eax,%esi
f0103226:	7f 49                	jg     f0103271 <stab_binsearch+0x75>
f0103228:	0f b6 0a             	movzbl (%edx),%ecx
f010322b:	83 ea 0c             	sub    $0xc,%edx
f010322e:	39 f9                	cmp    %edi,%ecx
f0103230:	75 ef                	jne    f0103221 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103232:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103235:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103238:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010323c:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010323f:	73 35                	jae    f0103276 <stab_binsearch+0x7a>
			*region_left = m;
f0103241:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103244:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0103246:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0103249:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103250:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0103253:	7f 4e                	jg     f01032a3 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0103255:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103258:	01 f0                	add    %esi,%eax
f010325a:	89 c3                	mov    %eax,%ebx
f010325c:	c1 eb 1f             	shr    $0x1f,%ebx
f010325f:	01 c3                	add    %eax,%ebx
f0103261:	d1 fb                	sar    %ebx
f0103263:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103266:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103269:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010326d:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f010326f:	eb b3                	jmp    f0103224 <stab_binsearch+0x28>
			l = true_m + 1;
f0103271:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0103274:	eb da                	jmp    f0103250 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0103276:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103279:	76 14                	jbe    f010328f <stab_binsearch+0x93>
			*region_right = m - 1;
f010327b:	83 e8 01             	sub    $0x1,%eax
f010327e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103281:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103284:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0103286:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010328d:	eb c1                	jmp    f0103250 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010328f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103292:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103294:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103298:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010329a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01032a1:	eb ad                	jmp    f0103250 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01032a3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01032a7:	74 16                	je     f01032bf <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01032a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032ac:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01032ae:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01032b1:	8b 0e                	mov    (%esi),%ecx
f01032b3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01032b6:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01032b9:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01032bd:	eb 12                	jmp    f01032d1 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01032bf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032c2:	8b 00                	mov    (%eax),%eax
f01032c4:	83 e8 01             	sub    $0x1,%eax
f01032c7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01032ca:	89 07                	mov    %eax,(%edi)
f01032cc:	eb 16                	jmp    f01032e4 <stab_binsearch+0xe8>
		     l--)
f01032ce:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01032d1:	39 c1                	cmp    %eax,%ecx
f01032d3:	7d 0a                	jge    f01032df <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01032d5:	0f b6 1a             	movzbl (%edx),%ebx
f01032d8:	83 ea 0c             	sub    $0xc,%edx
f01032db:	39 fb                	cmp    %edi,%ebx
f01032dd:	75 ef                	jne    f01032ce <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01032df:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01032e2:	89 07                	mov    %eax,(%edi)
	}
}
f01032e4:	83 c4 14             	add    $0x14,%esp
f01032e7:	5b                   	pop    %ebx
f01032e8:	5e                   	pop    %esi
f01032e9:	5f                   	pop    %edi
f01032ea:	5d                   	pop    %ebp
f01032eb:	c3                   	ret    

f01032ec <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01032ec:	55                   	push   %ebp
f01032ed:	89 e5                	mov    %esp,%ebp
f01032ef:	57                   	push   %edi
f01032f0:	56                   	push   %esi
f01032f1:	53                   	push   %ebx
f01032f2:	83 ec 3c             	sub    $0x3c,%esp
f01032f5:	e8 bb ce ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f01032fa:	81 c3 12 40 01 00    	add    $0x14012,%ebx
f0103300:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103303:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103306:	8d 83 e8 de fe ff    	lea    -0x12118(%ebx),%eax
f010330c:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f010330e:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103315:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103318:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010331f:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103322:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103329:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010332f:	0f 86 3b 01 00 00    	jbe    f0103470 <debuginfo_eip+0x184>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103335:	c7 c0 55 bd 10 f0    	mov    $0xf010bd55,%eax
f010333b:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f0103341:	0f 86 14 02 00 00    	jbe    f010355b <debuginfo_eip+0x26f>
f0103347:	c7 c0 1e dc 10 f0    	mov    $0xf010dc1e,%eax
f010334d:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103351:	0f 85 0b 02 00 00    	jne    f0103562 <debuginfo_eip+0x276>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103357:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010335e:	c7 c0 0c 54 10 f0    	mov    $0xf010540c,%eax
f0103364:	c7 c2 54 bd 10 f0    	mov    $0xf010bd54,%edx
f010336a:	29 c2                	sub    %eax,%edx
f010336c:	c1 fa 02             	sar    $0x2,%edx
f010336f:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103375:	83 ea 01             	sub    $0x1,%edx
f0103378:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010337b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010337e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103381:	83 ec 08             	sub    $0x8,%esp
f0103384:	57                   	push   %edi
f0103385:	6a 64                	push   $0x64
f0103387:	e8 70 fe ff ff       	call   f01031fc <stab_binsearch>
	if (lfile == 0)
f010338c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010338f:	83 c4 10             	add    $0x10,%esp
f0103392:	85 c0                	test   %eax,%eax
f0103394:	0f 84 cf 01 00 00    	je     f0103569 <debuginfo_eip+0x27d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010339a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010339d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033a0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01033a3:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01033a6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01033a9:	83 ec 08             	sub    $0x8,%esp
f01033ac:	57                   	push   %edi
f01033ad:	6a 24                	push   $0x24
f01033af:	c7 c0 0c 54 10 f0    	mov    $0xf010540c,%eax
f01033b5:	e8 42 fe ff ff       	call   f01031fc <stab_binsearch>

	if (lfun <= rfun) {
f01033ba:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033bd:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01033c0:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f01033c3:	83 c4 10             	add    $0x10,%esp
f01033c6:	39 c8                	cmp    %ecx,%eax
f01033c8:	0f 8f bd 00 00 00    	jg     f010348b <debuginfo_eip+0x19f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01033ce:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01033d1:	c7 c1 0c 54 10 f0    	mov    $0xf010540c,%ecx
f01033d7:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f01033da:	8b 11                	mov    (%ecx),%edx
f01033dc:	89 55 c0             	mov    %edx,-0x40(%ebp)
f01033df:	c7 c2 1e dc 10 f0    	mov    $0xf010dc1e,%edx
f01033e5:	81 ea 55 bd 10 f0    	sub    $0xf010bd55,%edx
f01033eb:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f01033ee:	73 0c                	jae    f01033fc <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01033f0:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01033f3:	81 c2 55 bd 10 f0    	add    $0xf010bd55,%edx
f01033f9:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01033fc:	8b 51 08             	mov    0x8(%ecx),%edx
f01033ff:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103402:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0103404:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103407:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010340a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010340d:	83 ec 08             	sub    $0x8,%esp
f0103410:	6a 3a                	push   $0x3a
f0103412:	ff 76 08             	pushl  0x8(%esi)
f0103415:	e8 cc 09 00 00       	call   f0103de6 <strfind>
f010341a:	2b 46 08             	sub    0x8(%esi),%eax
f010341d:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103420:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103423:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103426:	83 c4 08             	add    $0x8,%esp
f0103429:	57                   	push   %edi
f010342a:	6a 44                	push   $0x44
f010342c:	c7 c0 0c 54 10 f0    	mov    $0xf010540c,%eax
f0103432:	e8 c5 fd ff ff       	call   f01031fc <stab_binsearch>
    if(lline <= rline){
f0103437:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010343a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010343d:	83 c4 10             	add    $0x10,%esp
f0103440:	39 c2                	cmp    %eax,%edx
f0103442:	7f 5b                	jg     f010349f <debuginfo_eip+0x1b3>
        info->eip_line = stabs[rline].n_desc;
f0103444:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0103447:	c7 c0 0c 54 10 f0    	mov    $0xf010540c,%eax
f010344d:	0f b7 44 88 06       	movzwl 0x6(%eax,%ecx,4),%eax
f0103452:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103455:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103458:	89 d0                	mov    %edx,%eax
f010345a:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f010345d:	c7 c2 0c 54 10 f0    	mov    $0xf010540c,%edx
f0103463:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0103467:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010346b:	89 75 0c             	mov    %esi,0xc(%ebp)
f010346e:	eb 42                	jmp    f01034b2 <debuginfo_eip+0x1c6>
  	        panic("User address");
f0103470:	83 ec 04             	sub    $0x4,%esp
f0103473:	8d 83 f2 de fe ff    	lea    -0x1210e(%ebx),%eax
f0103479:	50                   	push   %eax
f010347a:	68 80 00 00 00       	push   $0x80
f010347f:	8d 83 ff de fe ff    	lea    -0x12101(%ebx),%eax
f0103485:	50                   	push   %eax
f0103486:	e8 74 cc ff ff       	call   f01000ff <_panic>
		info->eip_fn_addr = addr;
f010348b:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010348e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103491:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103494:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103497:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010349a:	e9 6e ff ff ff       	jmp    f010340d <debuginfo_eip+0x121>
        info->eip_line = -1;
f010349f:	c7 46 04 ff ff ff ff 	movl   $0xffffffff,0x4(%esi)
f01034a6:	eb ad                	jmp    f0103455 <debuginfo_eip+0x169>
f01034a8:	83 e8 01             	sub    $0x1,%eax
f01034ab:	83 ea 0c             	sub    $0xc,%edx
f01034ae:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01034b2:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f01034b5:	39 c7                	cmp    %eax,%edi
f01034b7:	7f 24                	jg     f01034dd <debuginfo_eip+0x1f1>
	       && stabs[lline].n_type != N_SOL
f01034b9:	0f b6 0a             	movzbl (%edx),%ecx
f01034bc:	80 f9 84             	cmp    $0x84,%cl
f01034bf:	74 46                	je     f0103507 <debuginfo_eip+0x21b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01034c1:	80 f9 64             	cmp    $0x64,%cl
f01034c4:	75 e2                	jne    f01034a8 <debuginfo_eip+0x1bc>
f01034c6:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f01034ca:	74 dc                	je     f01034a8 <debuginfo_eip+0x1bc>
f01034cc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01034cf:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01034d3:	74 3b                	je     f0103510 <debuginfo_eip+0x224>
f01034d5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01034d8:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01034db:	eb 33                	jmp    f0103510 <debuginfo_eip+0x224>
f01034dd:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01034e0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034e3:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01034e6:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01034eb:	39 fa                	cmp    %edi,%edx
f01034ed:	0f 8d 82 00 00 00    	jge    f0103575 <debuginfo_eip+0x289>
		for (lline = lfun + 1;
f01034f3:	83 c2 01             	add    $0x1,%edx
f01034f6:	89 d0                	mov    %edx,%eax
f01034f8:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f01034fb:	c7 c2 0c 54 10 f0    	mov    $0xf010540c,%edx
f0103501:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0103505:	eb 3b                	jmp    f0103542 <debuginfo_eip+0x256>
f0103507:	8b 75 0c             	mov    0xc(%ebp),%esi
f010350a:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010350e:	75 26                	jne    f0103536 <debuginfo_eip+0x24a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103510:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103513:	c7 c0 0c 54 10 f0    	mov    $0xf010540c,%eax
f0103519:	8b 14 90             	mov    (%eax,%edx,4),%edx
f010351c:	c7 c0 1e dc 10 f0    	mov    $0xf010dc1e,%eax
f0103522:	81 e8 55 bd 10 f0    	sub    $0xf010bd55,%eax
f0103528:	39 c2                	cmp    %eax,%edx
f010352a:	73 b4                	jae    f01034e0 <debuginfo_eip+0x1f4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010352c:	81 c2 55 bd 10 f0    	add    $0xf010bd55,%edx
f0103532:	89 16                	mov    %edx,(%esi)
f0103534:	eb aa                	jmp    f01034e0 <debuginfo_eip+0x1f4>
f0103536:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103539:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010353c:	eb d2                	jmp    f0103510 <debuginfo_eip+0x224>
			info->eip_fn_narg++;
f010353e:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0103542:	39 c7                	cmp    %eax,%edi
f0103544:	7e 2a                	jle    f0103570 <debuginfo_eip+0x284>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103546:	0f b6 0a             	movzbl (%edx),%ecx
f0103549:	83 c0 01             	add    $0x1,%eax
f010354c:	83 c2 0c             	add    $0xc,%edx
f010354f:	80 f9 a0             	cmp    $0xa0,%cl
f0103552:	74 ea                	je     f010353e <debuginfo_eip+0x252>
	return 0;
f0103554:	b8 00 00 00 00       	mov    $0x0,%eax
f0103559:	eb 1a                	jmp    f0103575 <debuginfo_eip+0x289>
		return -1;
f010355b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103560:	eb 13                	jmp    f0103575 <debuginfo_eip+0x289>
f0103562:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103567:	eb 0c                	jmp    f0103575 <debuginfo_eip+0x289>
		return -1;
f0103569:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010356e:	eb 05                	jmp    f0103575 <debuginfo_eip+0x289>
	return 0;
f0103570:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103575:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103578:	5b                   	pop    %ebx
f0103579:	5e                   	pop    %esi
f010357a:	5f                   	pop    %edi
f010357b:	5d                   	pop    %ebp
f010357c:	c3                   	ret    

f010357d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010357d:	55                   	push   %ebp
f010357e:	89 e5                	mov    %esp,%ebp
f0103580:	57                   	push   %edi
f0103581:	56                   	push   %esi
f0103582:	53                   	push   %ebx
f0103583:	83 ec 2c             	sub    $0x2c,%esp
f0103586:	e8 ce fb ff ff       	call   f0103159 <__x86.get_pc_thunk.cx>
f010358b:	81 c1 81 3d 01 00    	add    $0x13d81,%ecx
f0103591:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103594:	89 c7                	mov    %eax,%edi
f0103596:	89 d6                	mov    %edx,%esi
f0103598:	8b 45 08             	mov    0x8(%ebp),%eax
f010359b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010359e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01035a1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01035a4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01035a7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01035ac:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01035af:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01035b2:	39 d3                	cmp    %edx,%ebx
f01035b4:	72 09                	jb     f01035bf <printnum+0x42>
f01035b6:	39 45 10             	cmp    %eax,0x10(%ebp)
f01035b9:	0f 87 83 00 00 00    	ja     f0103642 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01035bf:	83 ec 0c             	sub    $0xc,%esp
f01035c2:	ff 75 18             	pushl  0x18(%ebp)
f01035c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01035c8:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01035cb:	53                   	push   %ebx
f01035cc:	ff 75 10             	pushl  0x10(%ebp)
f01035cf:	83 ec 08             	sub    $0x8,%esp
f01035d2:	ff 75 dc             	pushl  -0x24(%ebp)
f01035d5:	ff 75 d8             	pushl  -0x28(%ebp)
f01035d8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01035db:	ff 75 d0             	pushl  -0x30(%ebp)
f01035de:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01035e1:	e8 1a 0a 00 00       	call   f0104000 <__udivdi3>
f01035e6:	83 c4 18             	add    $0x18,%esp
f01035e9:	52                   	push   %edx
f01035ea:	50                   	push   %eax
f01035eb:	89 f2                	mov    %esi,%edx
f01035ed:	89 f8                	mov    %edi,%eax
f01035ef:	e8 89 ff ff ff       	call   f010357d <printnum>
f01035f4:	83 c4 20             	add    $0x20,%esp
f01035f7:	eb 13                	jmp    f010360c <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01035f9:	83 ec 08             	sub    $0x8,%esp
f01035fc:	56                   	push   %esi
f01035fd:	ff 75 18             	pushl  0x18(%ebp)
f0103600:	ff d7                	call   *%edi
f0103602:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103605:	83 eb 01             	sub    $0x1,%ebx
f0103608:	85 db                	test   %ebx,%ebx
f010360a:	7f ed                	jg     f01035f9 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010360c:	83 ec 08             	sub    $0x8,%esp
f010360f:	56                   	push   %esi
f0103610:	83 ec 04             	sub    $0x4,%esp
f0103613:	ff 75 dc             	pushl  -0x24(%ebp)
f0103616:	ff 75 d8             	pushl  -0x28(%ebp)
f0103619:	ff 75 d4             	pushl  -0x2c(%ebp)
f010361c:	ff 75 d0             	pushl  -0x30(%ebp)
f010361f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103622:	89 f3                	mov    %esi,%ebx
f0103624:	e8 f7 0a 00 00       	call   f0104120 <__umoddi3>
f0103629:	83 c4 14             	add    $0x14,%esp
f010362c:	0f be 84 06 0d df fe 	movsbl -0x120f3(%esi,%eax,1),%eax
f0103633:	ff 
f0103634:	50                   	push   %eax
f0103635:	ff d7                	call   *%edi
}
f0103637:	83 c4 10             	add    $0x10,%esp
f010363a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010363d:	5b                   	pop    %ebx
f010363e:	5e                   	pop    %esi
f010363f:	5f                   	pop    %edi
f0103640:	5d                   	pop    %ebp
f0103641:	c3                   	ret    
f0103642:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103645:	eb be                	jmp    f0103605 <printnum+0x88>

f0103647 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103647:	55                   	push   %ebp
f0103648:	89 e5                	mov    %esp,%ebp
f010364a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010364d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103651:	8b 10                	mov    (%eax),%edx
f0103653:	3b 50 04             	cmp    0x4(%eax),%edx
f0103656:	73 0a                	jae    f0103662 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103658:	8d 4a 01             	lea    0x1(%edx),%ecx
f010365b:	89 08                	mov    %ecx,(%eax)
f010365d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103660:	88 02                	mov    %al,(%edx)
}
f0103662:	5d                   	pop    %ebp
f0103663:	c3                   	ret    

f0103664 <printfmt>:
{
f0103664:	55                   	push   %ebp
f0103665:	89 e5                	mov    %esp,%ebp
f0103667:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010366a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010366d:	50                   	push   %eax
f010366e:	ff 75 10             	pushl  0x10(%ebp)
f0103671:	ff 75 0c             	pushl  0xc(%ebp)
f0103674:	ff 75 08             	pushl  0x8(%ebp)
f0103677:	e8 05 00 00 00       	call   f0103681 <vprintfmt>
}
f010367c:	83 c4 10             	add    $0x10,%esp
f010367f:	c9                   	leave  
f0103680:	c3                   	ret    

f0103681 <vprintfmt>:
{
f0103681:	55                   	push   %ebp
f0103682:	89 e5                	mov    %esp,%ebp
f0103684:	57                   	push   %edi
f0103685:	56                   	push   %esi
f0103686:	53                   	push   %ebx
f0103687:	83 ec 2c             	sub    $0x2c,%esp
f010368a:	e8 26 cb ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f010368f:	81 c3 7d 3c 01 00    	add    $0x13c7d,%ebx
f0103695:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103698:	8b 7d 10             	mov    0x10(%ebp),%edi
f010369b:	e9 c3 03 00 00       	jmp    f0103a63 <.L35+0x48>
		padc = ' ';
f01036a0:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01036a4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01036ab:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f01036b2:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01036b9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036be:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01036c1:	8d 47 01             	lea    0x1(%edi),%eax
f01036c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036c7:	0f b6 17             	movzbl (%edi),%edx
f01036ca:	8d 42 dd             	lea    -0x23(%edx),%eax
f01036cd:	3c 55                	cmp    $0x55,%al
f01036cf:	0f 87 16 04 00 00    	ja     f0103aeb <.L22>
f01036d5:	0f b6 c0             	movzbl %al,%eax
f01036d8:	89 d9                	mov    %ebx,%ecx
f01036da:	03 8c 83 98 df fe ff 	add    -0x12068(%ebx,%eax,4),%ecx
f01036e1:	ff e1                	jmp    *%ecx

f01036e3 <.L69>:
f01036e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01036e6:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01036ea:	eb d5                	jmp    f01036c1 <vprintfmt+0x40>

f01036ec <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01036ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01036ef:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01036f3:	eb cc                	jmp    f01036c1 <vprintfmt+0x40>

f01036f5 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f01036f5:	0f b6 d2             	movzbl %dl,%edx
f01036f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01036fb:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0103700:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103703:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103707:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010370a:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010370d:	83 f9 09             	cmp    $0x9,%ecx
f0103710:	77 55                	ja     f0103767 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0103712:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103715:	eb e9                	jmp    f0103700 <.L29+0xb>

f0103717 <.L26>:
			precision = va_arg(ap, int);
f0103717:	8b 45 14             	mov    0x14(%ebp),%eax
f010371a:	8b 00                	mov    (%eax),%eax
f010371c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010371f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103722:	8d 40 04             	lea    0x4(%eax),%eax
f0103725:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103728:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f010372b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010372f:	79 90                	jns    f01036c1 <vprintfmt+0x40>
				width = precision, precision = -1;
f0103731:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103734:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103737:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f010373e:	eb 81                	jmp    f01036c1 <vprintfmt+0x40>

f0103740 <.L27>:
f0103740:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103743:	85 c0                	test   %eax,%eax
f0103745:	ba 00 00 00 00       	mov    $0x0,%edx
f010374a:	0f 49 d0             	cmovns %eax,%edx
f010374d:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103750:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103753:	e9 69 ff ff ff       	jmp    f01036c1 <vprintfmt+0x40>

f0103758 <.L23>:
f0103758:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f010375b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103762:	e9 5a ff ff ff       	jmp    f01036c1 <vprintfmt+0x40>
f0103767:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010376a:	eb bf                	jmp    f010372b <.L26+0x14>

f010376c <.L33>:
			lflag++;
f010376c:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103770:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0103773:	e9 49 ff ff ff       	jmp    f01036c1 <vprintfmt+0x40>

f0103778 <.L30>:
			putch(va_arg(ap, int), putdat);
f0103778:	8b 45 14             	mov    0x14(%ebp),%eax
f010377b:	8d 78 04             	lea    0x4(%eax),%edi
f010377e:	83 ec 08             	sub    $0x8,%esp
f0103781:	56                   	push   %esi
f0103782:	ff 30                	pushl  (%eax)
f0103784:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103787:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010378a:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010378d:	e9 ce 02 00 00       	jmp    f0103a60 <.L35+0x45>

f0103792 <.L32>:
			err = va_arg(ap, int);
f0103792:	8b 45 14             	mov    0x14(%ebp),%eax
f0103795:	8d 78 04             	lea    0x4(%eax),%edi
f0103798:	8b 00                	mov    (%eax),%eax
f010379a:	99                   	cltd   
f010379b:	31 d0                	xor    %edx,%eax
f010379d:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010379f:	83 f8 06             	cmp    $0x6,%eax
f01037a2:	7f 27                	jg     f01037cb <.L32+0x39>
f01037a4:	8b 94 83 38 1d 00 00 	mov    0x1d38(%ebx,%eax,4),%edx
f01037ab:	85 d2                	test   %edx,%edx
f01037ad:	74 1c                	je     f01037cb <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01037af:	52                   	push   %edx
f01037b0:	8d 83 7d d4 fe ff    	lea    -0x12b83(%ebx),%eax
f01037b6:	50                   	push   %eax
f01037b7:	56                   	push   %esi
f01037b8:	ff 75 08             	pushl  0x8(%ebp)
f01037bb:	e8 a4 fe ff ff       	call   f0103664 <printfmt>
f01037c0:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01037c3:	89 7d 14             	mov    %edi,0x14(%ebp)
f01037c6:	e9 95 02 00 00       	jmp    f0103a60 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01037cb:	50                   	push   %eax
f01037cc:	8d 83 25 df fe ff    	lea    -0x120db(%ebx),%eax
f01037d2:	50                   	push   %eax
f01037d3:	56                   	push   %esi
f01037d4:	ff 75 08             	pushl  0x8(%ebp)
f01037d7:	e8 88 fe ff ff       	call   f0103664 <printfmt>
f01037dc:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01037df:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01037e2:	e9 79 02 00 00       	jmp    f0103a60 <.L35+0x45>

f01037e7 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01037e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01037ea:	83 c0 04             	add    $0x4,%eax
f01037ed:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01037f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01037f3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01037f5:	85 ff                	test   %edi,%edi
f01037f7:	8d 83 1e df fe ff    	lea    -0x120e2(%ebx),%eax
f01037fd:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103800:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103804:	0f 8e b5 00 00 00    	jle    f01038bf <.L36+0xd8>
f010380a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010380e:	75 08                	jne    f0103818 <.L36+0x31>
f0103810:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103813:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103816:	eb 6d                	jmp    f0103885 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103818:	83 ec 08             	sub    $0x8,%esp
f010381b:	ff 75 cc             	pushl  -0x34(%ebp)
f010381e:	57                   	push   %edi
f010381f:	e8 7e 04 00 00       	call   f0103ca2 <strnlen>
f0103824:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103827:	29 c2                	sub    %eax,%edx
f0103829:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010382c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010382f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103833:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103836:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103839:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f010383b:	eb 10                	jmp    f010384d <.L36+0x66>
					putch(padc, putdat);
f010383d:	83 ec 08             	sub    $0x8,%esp
f0103840:	56                   	push   %esi
f0103841:	ff 75 e0             	pushl  -0x20(%ebp)
f0103844:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103847:	83 ef 01             	sub    $0x1,%edi
f010384a:	83 c4 10             	add    $0x10,%esp
f010384d:	85 ff                	test   %edi,%edi
f010384f:	7f ec                	jg     f010383d <.L36+0x56>
f0103851:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103854:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0103857:	85 d2                	test   %edx,%edx
f0103859:	b8 00 00 00 00       	mov    $0x0,%eax
f010385e:	0f 49 c2             	cmovns %edx,%eax
f0103861:	29 c2                	sub    %eax,%edx
f0103863:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103866:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103869:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010386c:	eb 17                	jmp    f0103885 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010386e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103872:	75 30                	jne    f01038a4 <.L36+0xbd>
					putch(ch, putdat);
f0103874:	83 ec 08             	sub    $0x8,%esp
f0103877:	ff 75 0c             	pushl  0xc(%ebp)
f010387a:	50                   	push   %eax
f010387b:	ff 55 08             	call   *0x8(%ebp)
f010387e:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103881:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0103885:	83 c7 01             	add    $0x1,%edi
f0103888:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f010388c:	0f be c2             	movsbl %dl,%eax
f010388f:	85 c0                	test   %eax,%eax
f0103891:	74 52                	je     f01038e5 <.L36+0xfe>
f0103893:	85 f6                	test   %esi,%esi
f0103895:	78 d7                	js     f010386e <.L36+0x87>
f0103897:	83 ee 01             	sub    $0x1,%esi
f010389a:	79 d2                	jns    f010386e <.L36+0x87>
f010389c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010389f:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01038a2:	eb 32                	jmp    f01038d6 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01038a4:	0f be d2             	movsbl %dl,%edx
f01038a7:	83 ea 20             	sub    $0x20,%edx
f01038aa:	83 fa 5e             	cmp    $0x5e,%edx
f01038ad:	76 c5                	jbe    f0103874 <.L36+0x8d>
					putch('?', putdat);
f01038af:	83 ec 08             	sub    $0x8,%esp
f01038b2:	ff 75 0c             	pushl  0xc(%ebp)
f01038b5:	6a 3f                	push   $0x3f
f01038b7:	ff 55 08             	call   *0x8(%ebp)
f01038ba:	83 c4 10             	add    $0x10,%esp
f01038bd:	eb c2                	jmp    f0103881 <.L36+0x9a>
f01038bf:	89 75 0c             	mov    %esi,0xc(%ebp)
f01038c2:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01038c5:	eb be                	jmp    f0103885 <.L36+0x9e>
				putch(' ', putdat);
f01038c7:	83 ec 08             	sub    $0x8,%esp
f01038ca:	56                   	push   %esi
f01038cb:	6a 20                	push   $0x20
f01038cd:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01038d0:	83 ef 01             	sub    $0x1,%edi
f01038d3:	83 c4 10             	add    $0x10,%esp
f01038d6:	85 ff                	test   %edi,%edi
f01038d8:	7f ed                	jg     f01038c7 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01038da:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01038dd:	89 45 14             	mov    %eax,0x14(%ebp)
f01038e0:	e9 7b 01 00 00       	jmp    f0103a60 <.L35+0x45>
f01038e5:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01038e8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01038eb:	eb e9                	jmp    f01038d6 <.L36+0xef>

f01038ed <.L31>:
f01038ed:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01038f0:	83 f9 01             	cmp    $0x1,%ecx
f01038f3:	7e 40                	jle    f0103935 <.L31+0x48>
		return va_arg(*ap, long long);
f01038f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01038f8:	8b 50 04             	mov    0x4(%eax),%edx
f01038fb:	8b 00                	mov    (%eax),%eax
f01038fd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103900:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103903:	8b 45 14             	mov    0x14(%ebp),%eax
f0103906:	8d 40 08             	lea    0x8(%eax),%eax
f0103909:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010390c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103910:	79 55                	jns    f0103967 <.L31+0x7a>
				putch('-', putdat);
f0103912:	83 ec 08             	sub    $0x8,%esp
f0103915:	56                   	push   %esi
f0103916:	6a 2d                	push   $0x2d
f0103918:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010391b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010391e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103921:	f7 da                	neg    %edx
f0103923:	83 d1 00             	adc    $0x0,%ecx
f0103926:	f7 d9                	neg    %ecx
f0103928:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010392b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103930:	e9 10 01 00 00       	jmp    f0103a45 <.L35+0x2a>
	else if (lflag)
f0103935:	85 c9                	test   %ecx,%ecx
f0103937:	75 17                	jne    f0103950 <.L31+0x63>
		return va_arg(*ap, int);
f0103939:	8b 45 14             	mov    0x14(%ebp),%eax
f010393c:	8b 00                	mov    (%eax),%eax
f010393e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103941:	99                   	cltd   
f0103942:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103945:	8b 45 14             	mov    0x14(%ebp),%eax
f0103948:	8d 40 04             	lea    0x4(%eax),%eax
f010394b:	89 45 14             	mov    %eax,0x14(%ebp)
f010394e:	eb bc                	jmp    f010390c <.L31+0x1f>
		return va_arg(*ap, long);
f0103950:	8b 45 14             	mov    0x14(%ebp),%eax
f0103953:	8b 00                	mov    (%eax),%eax
f0103955:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103958:	99                   	cltd   
f0103959:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010395c:	8b 45 14             	mov    0x14(%ebp),%eax
f010395f:	8d 40 04             	lea    0x4(%eax),%eax
f0103962:	89 45 14             	mov    %eax,0x14(%ebp)
f0103965:	eb a5                	jmp    f010390c <.L31+0x1f>
			num = getint(&ap, lflag);
f0103967:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010396a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010396d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103972:	e9 ce 00 00 00       	jmp    f0103a45 <.L35+0x2a>

f0103977 <.L37>:
f0103977:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010397a:	83 f9 01             	cmp    $0x1,%ecx
f010397d:	7e 18                	jle    f0103997 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f010397f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103982:	8b 10                	mov    (%eax),%edx
f0103984:	8b 48 04             	mov    0x4(%eax),%ecx
f0103987:	8d 40 08             	lea    0x8(%eax),%eax
f010398a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010398d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103992:	e9 ae 00 00 00       	jmp    f0103a45 <.L35+0x2a>
	else if (lflag)
f0103997:	85 c9                	test   %ecx,%ecx
f0103999:	75 1a                	jne    f01039b5 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f010399b:	8b 45 14             	mov    0x14(%ebp),%eax
f010399e:	8b 10                	mov    (%eax),%edx
f01039a0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01039a5:	8d 40 04             	lea    0x4(%eax),%eax
f01039a8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01039ab:	b8 0a 00 00 00       	mov    $0xa,%eax
f01039b0:	e9 90 00 00 00       	jmp    f0103a45 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01039b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01039b8:	8b 10                	mov    (%eax),%edx
f01039ba:	b9 00 00 00 00       	mov    $0x0,%ecx
f01039bf:	8d 40 04             	lea    0x4(%eax),%eax
f01039c2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01039c5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01039ca:	eb 79                	jmp    f0103a45 <.L35+0x2a>

f01039cc <.L34>:
f01039cc:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01039cf:	83 f9 01             	cmp    $0x1,%ecx
f01039d2:	7e 15                	jle    f01039e9 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f01039d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01039d7:	8b 10                	mov    (%eax),%edx
f01039d9:	8b 48 04             	mov    0x4(%eax),%ecx
f01039dc:	8d 40 08             	lea    0x8(%eax),%eax
f01039df:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01039e2:	b8 08 00 00 00       	mov    $0x8,%eax
f01039e7:	eb 5c                	jmp    f0103a45 <.L35+0x2a>
	else if (lflag)
f01039e9:	85 c9                	test   %ecx,%ecx
f01039eb:	75 17                	jne    f0103a04 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f01039ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01039f0:	8b 10                	mov    (%eax),%edx
f01039f2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01039f7:	8d 40 04             	lea    0x4(%eax),%eax
f01039fa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01039fd:	b8 08 00 00 00       	mov    $0x8,%eax
f0103a02:	eb 41                	jmp    f0103a45 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103a04:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a07:	8b 10                	mov    (%eax),%edx
f0103a09:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a0e:	8d 40 04             	lea    0x4(%eax),%eax
f0103a11:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103a14:	b8 08 00 00 00       	mov    $0x8,%eax
f0103a19:	eb 2a                	jmp    f0103a45 <.L35+0x2a>

f0103a1b <.L35>:
			putch('0', putdat);
f0103a1b:	83 ec 08             	sub    $0x8,%esp
f0103a1e:	56                   	push   %esi
f0103a1f:	6a 30                	push   $0x30
f0103a21:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103a24:	83 c4 08             	add    $0x8,%esp
f0103a27:	56                   	push   %esi
f0103a28:	6a 78                	push   $0x78
f0103a2a:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0103a2d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a30:	8b 10                	mov    (%eax),%edx
f0103a32:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103a37:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103a3a:	8d 40 04             	lea    0x4(%eax),%eax
f0103a3d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103a40:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103a45:	83 ec 0c             	sub    $0xc,%esp
f0103a48:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103a4c:	57                   	push   %edi
f0103a4d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a50:	50                   	push   %eax
f0103a51:	51                   	push   %ecx
f0103a52:	52                   	push   %edx
f0103a53:	89 f2                	mov    %esi,%edx
f0103a55:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a58:	e8 20 fb ff ff       	call   f010357d <printnum>
			break;
f0103a5d:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103a60:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103a63:	83 c7 01             	add    $0x1,%edi
f0103a66:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103a6a:	83 f8 25             	cmp    $0x25,%eax
f0103a6d:	0f 84 2d fc ff ff    	je     f01036a0 <vprintfmt+0x1f>
			if (ch == '\0')
f0103a73:	85 c0                	test   %eax,%eax
f0103a75:	0f 84 91 00 00 00    	je     f0103b0c <.L22+0x21>
			putch(ch, putdat);
f0103a7b:	83 ec 08             	sub    $0x8,%esp
f0103a7e:	56                   	push   %esi
f0103a7f:	50                   	push   %eax
f0103a80:	ff 55 08             	call   *0x8(%ebp)
f0103a83:	83 c4 10             	add    $0x10,%esp
f0103a86:	eb db                	jmp    f0103a63 <.L35+0x48>

f0103a88 <.L38>:
f0103a88:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103a8b:	83 f9 01             	cmp    $0x1,%ecx
f0103a8e:	7e 15                	jle    f0103aa5 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0103a90:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a93:	8b 10                	mov    (%eax),%edx
f0103a95:	8b 48 04             	mov    0x4(%eax),%ecx
f0103a98:	8d 40 08             	lea    0x8(%eax),%eax
f0103a9b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103a9e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103aa3:	eb a0                	jmp    f0103a45 <.L35+0x2a>
	else if (lflag)
f0103aa5:	85 c9                	test   %ecx,%ecx
f0103aa7:	75 17                	jne    f0103ac0 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0103aa9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103aac:	8b 10                	mov    (%eax),%edx
f0103aae:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ab3:	8d 40 04             	lea    0x4(%eax),%eax
f0103ab6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103ab9:	b8 10 00 00 00       	mov    $0x10,%eax
f0103abe:	eb 85                	jmp    f0103a45 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103ac0:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ac3:	8b 10                	mov    (%eax),%edx
f0103ac5:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103aca:	8d 40 04             	lea    0x4(%eax),%eax
f0103acd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103ad0:	b8 10 00 00 00       	mov    $0x10,%eax
f0103ad5:	e9 6b ff ff ff       	jmp    f0103a45 <.L35+0x2a>

f0103ada <.L25>:
			putch(ch, putdat);
f0103ada:	83 ec 08             	sub    $0x8,%esp
f0103add:	56                   	push   %esi
f0103ade:	6a 25                	push   $0x25
f0103ae0:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103ae3:	83 c4 10             	add    $0x10,%esp
f0103ae6:	e9 75 ff ff ff       	jmp    f0103a60 <.L35+0x45>

f0103aeb <.L22>:
			putch('%', putdat);
f0103aeb:	83 ec 08             	sub    $0x8,%esp
f0103aee:	56                   	push   %esi
f0103aef:	6a 25                	push   $0x25
f0103af1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103af4:	83 c4 10             	add    $0x10,%esp
f0103af7:	89 f8                	mov    %edi,%eax
f0103af9:	eb 03                	jmp    f0103afe <.L22+0x13>
f0103afb:	83 e8 01             	sub    $0x1,%eax
f0103afe:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103b02:	75 f7                	jne    f0103afb <.L22+0x10>
f0103b04:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103b07:	e9 54 ff ff ff       	jmp    f0103a60 <.L35+0x45>
}
f0103b0c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b0f:	5b                   	pop    %ebx
f0103b10:	5e                   	pop    %esi
f0103b11:	5f                   	pop    %edi
f0103b12:	5d                   	pop    %ebp
f0103b13:	c3                   	ret    

f0103b14 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103b14:	55                   	push   %ebp
f0103b15:	89 e5                	mov    %esp,%ebp
f0103b17:	53                   	push   %ebx
f0103b18:	83 ec 14             	sub    $0x14,%esp
f0103b1b:	e8 95 c6 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0103b20:	81 c3 ec 37 01 00    	add    $0x137ec,%ebx
f0103b26:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b29:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103b2c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103b2f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103b33:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103b36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103b3d:	85 c0                	test   %eax,%eax
f0103b3f:	74 2b                	je     f0103b6c <vsnprintf+0x58>
f0103b41:	85 d2                	test   %edx,%edx
f0103b43:	7e 27                	jle    f0103b6c <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103b45:	ff 75 14             	pushl  0x14(%ebp)
f0103b48:	ff 75 10             	pushl  0x10(%ebp)
f0103b4b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103b4e:	50                   	push   %eax
f0103b4f:	8d 83 3b c3 fe ff    	lea    -0x13cc5(%ebx),%eax
f0103b55:	50                   	push   %eax
f0103b56:	e8 26 fb ff ff       	call   f0103681 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103b5b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103b5e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103b61:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103b64:	83 c4 10             	add    $0x10,%esp
}
f0103b67:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b6a:	c9                   	leave  
f0103b6b:	c3                   	ret    
		return -E_INVAL;
f0103b6c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103b71:	eb f4                	jmp    f0103b67 <vsnprintf+0x53>

f0103b73 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103b73:	55                   	push   %ebp
f0103b74:	89 e5                	mov    %esp,%ebp
f0103b76:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103b79:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103b7c:	50                   	push   %eax
f0103b7d:	ff 75 10             	pushl  0x10(%ebp)
f0103b80:	ff 75 0c             	pushl  0xc(%ebp)
f0103b83:	ff 75 08             	pushl  0x8(%ebp)
f0103b86:	e8 89 ff ff ff       	call   f0103b14 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103b8b:	c9                   	leave  
f0103b8c:	c3                   	ret    

f0103b8d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103b8d:	55                   	push   %ebp
f0103b8e:	89 e5                	mov    %esp,%ebp
f0103b90:	57                   	push   %edi
f0103b91:	56                   	push   %esi
f0103b92:	53                   	push   %ebx
f0103b93:	83 ec 1c             	sub    $0x1c,%esp
f0103b96:	e8 1a c6 ff ff       	call   f01001b5 <__x86.get_pc_thunk.bx>
f0103b9b:	81 c3 71 37 01 00    	add    $0x13771,%ebx
f0103ba1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103ba4:	85 c0                	test   %eax,%eax
f0103ba6:	74 13                	je     f0103bbb <readline+0x2e>
		cprintf("%s", prompt);
f0103ba8:	83 ec 08             	sub    $0x8,%esp
f0103bab:	50                   	push   %eax
f0103bac:	8d 83 7d d4 fe ff    	lea    -0x12b83(%ebx),%eax
f0103bb2:	50                   	push   %eax
f0103bb3:	e8 30 f6 ff ff       	call   f01031e8 <cprintf>
f0103bb8:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103bbb:	83 ec 0c             	sub    $0xc,%esp
f0103bbe:	6a 00                	push   $0x0
f0103bc0:	e8 88 cb ff ff       	call   f010074d <iscons>
f0103bc5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103bc8:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103bcb:	bf 00 00 00 00       	mov    $0x0,%edi
f0103bd0:	eb 46                	jmp    f0103c18 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103bd2:	83 ec 08             	sub    $0x8,%esp
f0103bd5:	50                   	push   %eax
f0103bd6:	8d 83 f0 e0 fe ff    	lea    -0x11f10(%ebx),%eax
f0103bdc:	50                   	push   %eax
f0103bdd:	e8 06 f6 ff ff       	call   f01031e8 <cprintf>
			return NULL;
f0103be2:	83 c4 10             	add    $0x10,%esp
f0103be5:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103bea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103bed:	5b                   	pop    %ebx
f0103bee:	5e                   	pop    %esi
f0103bef:	5f                   	pop    %edi
f0103bf0:	5d                   	pop    %ebp
f0103bf1:	c3                   	ret    
			if (echoing)
f0103bf2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103bf6:	75 05                	jne    f0103bfd <readline+0x70>
			i--;
f0103bf8:	83 ef 01             	sub    $0x1,%edi
f0103bfb:	eb 1b                	jmp    f0103c18 <readline+0x8b>
				cputchar('\b');
f0103bfd:	83 ec 0c             	sub    $0xc,%esp
f0103c00:	6a 08                	push   $0x8
f0103c02:	e8 25 cb ff ff       	call   f010072c <cputchar>
f0103c07:	83 c4 10             	add    $0x10,%esp
f0103c0a:	eb ec                	jmp    f0103bf8 <readline+0x6b>
			buf[i++] = c;
f0103c0c:	89 f0                	mov    %esi,%eax
f0103c0e:	88 84 3b b4 1f 00 00 	mov    %al,0x1fb4(%ebx,%edi,1)
f0103c15:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103c18:	e8 1f cb ff ff       	call   f010073c <getchar>
f0103c1d:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103c1f:	85 c0                	test   %eax,%eax
f0103c21:	78 af                	js     f0103bd2 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103c23:	83 f8 08             	cmp    $0x8,%eax
f0103c26:	0f 94 c2             	sete   %dl
f0103c29:	83 f8 7f             	cmp    $0x7f,%eax
f0103c2c:	0f 94 c0             	sete   %al
f0103c2f:	08 c2                	or     %al,%dl
f0103c31:	74 04                	je     f0103c37 <readline+0xaa>
f0103c33:	85 ff                	test   %edi,%edi
f0103c35:	7f bb                	jg     f0103bf2 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103c37:	83 fe 1f             	cmp    $0x1f,%esi
f0103c3a:	7e 1c                	jle    f0103c58 <readline+0xcb>
f0103c3c:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103c42:	7f 14                	jg     f0103c58 <readline+0xcb>
			if (echoing)
f0103c44:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c48:	74 c2                	je     f0103c0c <readline+0x7f>
				cputchar(c);
f0103c4a:	83 ec 0c             	sub    $0xc,%esp
f0103c4d:	56                   	push   %esi
f0103c4e:	e8 d9 ca ff ff       	call   f010072c <cputchar>
f0103c53:	83 c4 10             	add    $0x10,%esp
f0103c56:	eb b4                	jmp    f0103c0c <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103c58:	83 fe 0a             	cmp    $0xa,%esi
f0103c5b:	74 05                	je     f0103c62 <readline+0xd5>
f0103c5d:	83 fe 0d             	cmp    $0xd,%esi
f0103c60:	75 b6                	jne    f0103c18 <readline+0x8b>
			if (echoing)
f0103c62:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c66:	75 13                	jne    f0103c7b <readline+0xee>
			buf[i] = 0;
f0103c68:	c6 84 3b b4 1f 00 00 	movb   $0x0,0x1fb4(%ebx,%edi,1)
f0103c6f:	00 
			return buf;
f0103c70:	8d 83 b4 1f 00 00    	lea    0x1fb4(%ebx),%eax
f0103c76:	e9 6f ff ff ff       	jmp    f0103bea <readline+0x5d>
				cputchar('\n');
f0103c7b:	83 ec 0c             	sub    $0xc,%esp
f0103c7e:	6a 0a                	push   $0xa
f0103c80:	e8 a7 ca ff ff       	call   f010072c <cputchar>
f0103c85:	83 c4 10             	add    $0x10,%esp
f0103c88:	eb de                	jmp    f0103c68 <readline+0xdb>

f0103c8a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103c8a:	55                   	push   %ebp
f0103c8b:	89 e5                	mov    %esp,%ebp
f0103c8d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103c90:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c95:	eb 03                	jmp    f0103c9a <strlen+0x10>
		n++;
f0103c97:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103c9a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103c9e:	75 f7                	jne    f0103c97 <strlen+0xd>
	return n;
}
f0103ca0:	5d                   	pop    %ebp
f0103ca1:	c3                   	ret    

f0103ca2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103ca2:	55                   	push   %ebp
f0103ca3:	89 e5                	mov    %esp,%ebp
f0103ca5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103ca8:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103cab:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cb0:	eb 03                	jmp    f0103cb5 <strnlen+0x13>
		n++;
f0103cb2:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103cb5:	39 d0                	cmp    %edx,%eax
f0103cb7:	74 06                	je     f0103cbf <strnlen+0x1d>
f0103cb9:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103cbd:	75 f3                	jne    f0103cb2 <strnlen+0x10>
	return n;
}
f0103cbf:	5d                   	pop    %ebp
f0103cc0:	c3                   	ret    

f0103cc1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103cc1:	55                   	push   %ebp
f0103cc2:	89 e5                	mov    %esp,%ebp
f0103cc4:	53                   	push   %ebx
f0103cc5:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cc8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103ccb:	89 c2                	mov    %eax,%edx
f0103ccd:	83 c1 01             	add    $0x1,%ecx
f0103cd0:	83 c2 01             	add    $0x1,%edx
f0103cd3:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103cd7:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103cda:	84 db                	test   %bl,%bl
f0103cdc:	75 ef                	jne    f0103ccd <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103cde:	5b                   	pop    %ebx
f0103cdf:	5d                   	pop    %ebp
f0103ce0:	c3                   	ret    

f0103ce1 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103ce1:	55                   	push   %ebp
f0103ce2:	89 e5                	mov    %esp,%ebp
f0103ce4:	53                   	push   %ebx
f0103ce5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103ce8:	53                   	push   %ebx
f0103ce9:	e8 9c ff ff ff       	call   f0103c8a <strlen>
f0103cee:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103cf1:	ff 75 0c             	pushl  0xc(%ebp)
f0103cf4:	01 d8                	add    %ebx,%eax
f0103cf6:	50                   	push   %eax
f0103cf7:	e8 c5 ff ff ff       	call   f0103cc1 <strcpy>
	return dst;
}
f0103cfc:	89 d8                	mov    %ebx,%eax
f0103cfe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103d01:	c9                   	leave  
f0103d02:	c3                   	ret    

f0103d03 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103d03:	55                   	push   %ebp
f0103d04:	89 e5                	mov    %esp,%ebp
f0103d06:	56                   	push   %esi
f0103d07:	53                   	push   %ebx
f0103d08:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d0b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103d0e:	89 f3                	mov    %esi,%ebx
f0103d10:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103d13:	89 f2                	mov    %esi,%edx
f0103d15:	eb 0f                	jmp    f0103d26 <strncpy+0x23>
		*dst++ = *src;
f0103d17:	83 c2 01             	add    $0x1,%edx
f0103d1a:	0f b6 01             	movzbl (%ecx),%eax
f0103d1d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103d20:	80 39 01             	cmpb   $0x1,(%ecx)
f0103d23:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103d26:	39 da                	cmp    %ebx,%edx
f0103d28:	75 ed                	jne    f0103d17 <strncpy+0x14>
	}
	return ret;
}
f0103d2a:	89 f0                	mov    %esi,%eax
f0103d2c:	5b                   	pop    %ebx
f0103d2d:	5e                   	pop    %esi
f0103d2e:	5d                   	pop    %ebp
f0103d2f:	c3                   	ret    

f0103d30 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103d30:	55                   	push   %ebp
f0103d31:	89 e5                	mov    %esp,%ebp
f0103d33:	56                   	push   %esi
f0103d34:	53                   	push   %ebx
f0103d35:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d38:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d3b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103d3e:	89 f0                	mov    %esi,%eax
f0103d40:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103d44:	85 c9                	test   %ecx,%ecx
f0103d46:	75 0b                	jne    f0103d53 <strlcpy+0x23>
f0103d48:	eb 17                	jmp    f0103d61 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103d4a:	83 c2 01             	add    $0x1,%edx
f0103d4d:	83 c0 01             	add    $0x1,%eax
f0103d50:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103d53:	39 d8                	cmp    %ebx,%eax
f0103d55:	74 07                	je     f0103d5e <strlcpy+0x2e>
f0103d57:	0f b6 0a             	movzbl (%edx),%ecx
f0103d5a:	84 c9                	test   %cl,%cl
f0103d5c:	75 ec                	jne    f0103d4a <strlcpy+0x1a>
		*dst = '\0';
f0103d5e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103d61:	29 f0                	sub    %esi,%eax
}
f0103d63:	5b                   	pop    %ebx
f0103d64:	5e                   	pop    %esi
f0103d65:	5d                   	pop    %ebp
f0103d66:	c3                   	ret    

f0103d67 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103d67:	55                   	push   %ebp
f0103d68:	89 e5                	mov    %esp,%ebp
f0103d6a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103d6d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103d70:	eb 06                	jmp    f0103d78 <strcmp+0x11>
		p++, q++;
f0103d72:	83 c1 01             	add    $0x1,%ecx
f0103d75:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103d78:	0f b6 01             	movzbl (%ecx),%eax
f0103d7b:	84 c0                	test   %al,%al
f0103d7d:	74 04                	je     f0103d83 <strcmp+0x1c>
f0103d7f:	3a 02                	cmp    (%edx),%al
f0103d81:	74 ef                	je     f0103d72 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103d83:	0f b6 c0             	movzbl %al,%eax
f0103d86:	0f b6 12             	movzbl (%edx),%edx
f0103d89:	29 d0                	sub    %edx,%eax
}
f0103d8b:	5d                   	pop    %ebp
f0103d8c:	c3                   	ret    

f0103d8d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103d8d:	55                   	push   %ebp
f0103d8e:	89 e5                	mov    %esp,%ebp
f0103d90:	53                   	push   %ebx
f0103d91:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d94:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d97:	89 c3                	mov    %eax,%ebx
f0103d99:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103d9c:	eb 06                	jmp    f0103da4 <strncmp+0x17>
		n--, p++, q++;
f0103d9e:	83 c0 01             	add    $0x1,%eax
f0103da1:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103da4:	39 d8                	cmp    %ebx,%eax
f0103da6:	74 16                	je     f0103dbe <strncmp+0x31>
f0103da8:	0f b6 08             	movzbl (%eax),%ecx
f0103dab:	84 c9                	test   %cl,%cl
f0103dad:	74 04                	je     f0103db3 <strncmp+0x26>
f0103daf:	3a 0a                	cmp    (%edx),%cl
f0103db1:	74 eb                	je     f0103d9e <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103db3:	0f b6 00             	movzbl (%eax),%eax
f0103db6:	0f b6 12             	movzbl (%edx),%edx
f0103db9:	29 d0                	sub    %edx,%eax
}
f0103dbb:	5b                   	pop    %ebx
f0103dbc:	5d                   	pop    %ebp
f0103dbd:	c3                   	ret    
		return 0;
f0103dbe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103dc3:	eb f6                	jmp    f0103dbb <strncmp+0x2e>

f0103dc5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103dc5:	55                   	push   %ebp
f0103dc6:	89 e5                	mov    %esp,%ebp
f0103dc8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dcb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103dcf:	0f b6 10             	movzbl (%eax),%edx
f0103dd2:	84 d2                	test   %dl,%dl
f0103dd4:	74 09                	je     f0103ddf <strchr+0x1a>
		if (*s == c)
f0103dd6:	38 ca                	cmp    %cl,%dl
f0103dd8:	74 0a                	je     f0103de4 <strchr+0x1f>
	for (; *s; s++)
f0103dda:	83 c0 01             	add    $0x1,%eax
f0103ddd:	eb f0                	jmp    f0103dcf <strchr+0xa>
			return (char *) s;
	return 0;
f0103ddf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103de4:	5d                   	pop    %ebp
f0103de5:	c3                   	ret    

f0103de6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103de6:	55                   	push   %ebp
f0103de7:	89 e5                	mov    %esp,%ebp
f0103de9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103df0:	eb 03                	jmp    f0103df5 <strfind+0xf>
f0103df2:	83 c0 01             	add    $0x1,%eax
f0103df5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103df8:	38 ca                	cmp    %cl,%dl
f0103dfa:	74 04                	je     f0103e00 <strfind+0x1a>
f0103dfc:	84 d2                	test   %dl,%dl
f0103dfe:	75 f2                	jne    f0103df2 <strfind+0xc>
			break;
	return (char *) s;
}
f0103e00:	5d                   	pop    %ebp
f0103e01:	c3                   	ret    

f0103e02 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103e02:	55                   	push   %ebp
f0103e03:	89 e5                	mov    %esp,%ebp
f0103e05:	57                   	push   %edi
f0103e06:	56                   	push   %esi
f0103e07:	53                   	push   %ebx
f0103e08:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103e0b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103e0e:	85 c9                	test   %ecx,%ecx
f0103e10:	74 13                	je     f0103e25 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103e12:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103e18:	75 05                	jne    f0103e1f <memset+0x1d>
f0103e1a:	f6 c1 03             	test   $0x3,%cl
f0103e1d:	74 0d                	je     f0103e2c <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103e1f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e22:	fc                   	cld    
f0103e23:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103e25:	89 f8                	mov    %edi,%eax
f0103e27:	5b                   	pop    %ebx
f0103e28:	5e                   	pop    %esi
f0103e29:	5f                   	pop    %edi
f0103e2a:	5d                   	pop    %ebp
f0103e2b:	c3                   	ret    
		c &= 0xFF;
f0103e2c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103e30:	89 d3                	mov    %edx,%ebx
f0103e32:	c1 e3 08             	shl    $0x8,%ebx
f0103e35:	89 d0                	mov    %edx,%eax
f0103e37:	c1 e0 18             	shl    $0x18,%eax
f0103e3a:	89 d6                	mov    %edx,%esi
f0103e3c:	c1 e6 10             	shl    $0x10,%esi
f0103e3f:	09 f0                	or     %esi,%eax
f0103e41:	09 c2                	or     %eax,%edx
f0103e43:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103e45:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103e48:	89 d0                	mov    %edx,%eax
f0103e4a:	fc                   	cld    
f0103e4b:	f3 ab                	rep stos %eax,%es:(%edi)
f0103e4d:	eb d6                	jmp    f0103e25 <memset+0x23>

f0103e4f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103e4f:	55                   	push   %ebp
f0103e50:	89 e5                	mov    %esp,%ebp
f0103e52:	57                   	push   %edi
f0103e53:	56                   	push   %esi
f0103e54:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e57:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e5a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103e5d:	39 c6                	cmp    %eax,%esi
f0103e5f:	73 35                	jae    f0103e96 <memmove+0x47>
f0103e61:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103e64:	39 c2                	cmp    %eax,%edx
f0103e66:	76 2e                	jbe    f0103e96 <memmove+0x47>
		s += n;
		d += n;
f0103e68:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103e6b:	89 d6                	mov    %edx,%esi
f0103e6d:	09 fe                	or     %edi,%esi
f0103e6f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103e75:	74 0c                	je     f0103e83 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103e77:	83 ef 01             	sub    $0x1,%edi
f0103e7a:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103e7d:	fd                   	std    
f0103e7e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103e80:	fc                   	cld    
f0103e81:	eb 21                	jmp    f0103ea4 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103e83:	f6 c1 03             	test   $0x3,%cl
f0103e86:	75 ef                	jne    f0103e77 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103e88:	83 ef 04             	sub    $0x4,%edi
f0103e8b:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103e8e:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103e91:	fd                   	std    
f0103e92:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103e94:	eb ea                	jmp    f0103e80 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103e96:	89 f2                	mov    %esi,%edx
f0103e98:	09 c2                	or     %eax,%edx
f0103e9a:	f6 c2 03             	test   $0x3,%dl
f0103e9d:	74 09                	je     f0103ea8 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103e9f:	89 c7                	mov    %eax,%edi
f0103ea1:	fc                   	cld    
f0103ea2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103ea4:	5e                   	pop    %esi
f0103ea5:	5f                   	pop    %edi
f0103ea6:	5d                   	pop    %ebp
f0103ea7:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103ea8:	f6 c1 03             	test   $0x3,%cl
f0103eab:	75 f2                	jne    f0103e9f <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103ead:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103eb0:	89 c7                	mov    %eax,%edi
f0103eb2:	fc                   	cld    
f0103eb3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103eb5:	eb ed                	jmp    f0103ea4 <memmove+0x55>

f0103eb7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103eb7:	55                   	push   %ebp
f0103eb8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103eba:	ff 75 10             	pushl  0x10(%ebp)
f0103ebd:	ff 75 0c             	pushl  0xc(%ebp)
f0103ec0:	ff 75 08             	pushl  0x8(%ebp)
f0103ec3:	e8 87 ff ff ff       	call   f0103e4f <memmove>
}
f0103ec8:	c9                   	leave  
f0103ec9:	c3                   	ret    

f0103eca <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103eca:	55                   	push   %ebp
f0103ecb:	89 e5                	mov    %esp,%ebp
f0103ecd:	56                   	push   %esi
f0103ece:	53                   	push   %ebx
f0103ecf:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ed2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ed5:	89 c6                	mov    %eax,%esi
f0103ed7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103eda:	39 f0                	cmp    %esi,%eax
f0103edc:	74 1c                	je     f0103efa <memcmp+0x30>
		if (*s1 != *s2)
f0103ede:	0f b6 08             	movzbl (%eax),%ecx
f0103ee1:	0f b6 1a             	movzbl (%edx),%ebx
f0103ee4:	38 d9                	cmp    %bl,%cl
f0103ee6:	75 08                	jne    f0103ef0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103ee8:	83 c0 01             	add    $0x1,%eax
f0103eeb:	83 c2 01             	add    $0x1,%edx
f0103eee:	eb ea                	jmp    f0103eda <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103ef0:	0f b6 c1             	movzbl %cl,%eax
f0103ef3:	0f b6 db             	movzbl %bl,%ebx
f0103ef6:	29 d8                	sub    %ebx,%eax
f0103ef8:	eb 05                	jmp    f0103eff <memcmp+0x35>
	}

	return 0;
f0103efa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103eff:	5b                   	pop    %ebx
f0103f00:	5e                   	pop    %esi
f0103f01:	5d                   	pop    %ebp
f0103f02:	c3                   	ret    

f0103f03 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103f03:	55                   	push   %ebp
f0103f04:	89 e5                	mov    %esp,%ebp
f0103f06:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f09:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103f0c:	89 c2                	mov    %eax,%edx
f0103f0e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103f11:	39 d0                	cmp    %edx,%eax
f0103f13:	73 09                	jae    f0103f1e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103f15:	38 08                	cmp    %cl,(%eax)
f0103f17:	74 05                	je     f0103f1e <memfind+0x1b>
	for (; s < ends; s++)
f0103f19:	83 c0 01             	add    $0x1,%eax
f0103f1c:	eb f3                	jmp    f0103f11 <memfind+0xe>
			break;
	return (void *) s;
}
f0103f1e:	5d                   	pop    %ebp
f0103f1f:	c3                   	ret    

f0103f20 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103f20:	55                   	push   %ebp
f0103f21:	89 e5                	mov    %esp,%ebp
f0103f23:	57                   	push   %edi
f0103f24:	56                   	push   %esi
f0103f25:	53                   	push   %ebx
f0103f26:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103f29:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103f2c:	eb 03                	jmp    f0103f31 <strtol+0x11>
		s++;
f0103f2e:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103f31:	0f b6 01             	movzbl (%ecx),%eax
f0103f34:	3c 20                	cmp    $0x20,%al
f0103f36:	74 f6                	je     f0103f2e <strtol+0xe>
f0103f38:	3c 09                	cmp    $0x9,%al
f0103f3a:	74 f2                	je     f0103f2e <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103f3c:	3c 2b                	cmp    $0x2b,%al
f0103f3e:	74 2e                	je     f0103f6e <strtol+0x4e>
	int neg = 0;
f0103f40:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103f45:	3c 2d                	cmp    $0x2d,%al
f0103f47:	74 2f                	je     f0103f78 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103f49:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103f4f:	75 05                	jne    f0103f56 <strtol+0x36>
f0103f51:	80 39 30             	cmpb   $0x30,(%ecx)
f0103f54:	74 2c                	je     f0103f82 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103f56:	85 db                	test   %ebx,%ebx
f0103f58:	75 0a                	jne    f0103f64 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103f5a:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103f5f:	80 39 30             	cmpb   $0x30,(%ecx)
f0103f62:	74 28                	je     f0103f8c <strtol+0x6c>
		base = 10;
f0103f64:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f69:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103f6c:	eb 50                	jmp    f0103fbe <strtol+0x9e>
		s++;
f0103f6e:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103f71:	bf 00 00 00 00       	mov    $0x0,%edi
f0103f76:	eb d1                	jmp    f0103f49 <strtol+0x29>
		s++, neg = 1;
f0103f78:	83 c1 01             	add    $0x1,%ecx
f0103f7b:	bf 01 00 00 00       	mov    $0x1,%edi
f0103f80:	eb c7                	jmp    f0103f49 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103f82:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103f86:	74 0e                	je     f0103f96 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103f88:	85 db                	test   %ebx,%ebx
f0103f8a:	75 d8                	jne    f0103f64 <strtol+0x44>
		s++, base = 8;
f0103f8c:	83 c1 01             	add    $0x1,%ecx
f0103f8f:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103f94:	eb ce                	jmp    f0103f64 <strtol+0x44>
		s += 2, base = 16;
f0103f96:	83 c1 02             	add    $0x2,%ecx
f0103f99:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103f9e:	eb c4                	jmp    f0103f64 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103fa0:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103fa3:	89 f3                	mov    %esi,%ebx
f0103fa5:	80 fb 19             	cmp    $0x19,%bl
f0103fa8:	77 29                	ja     f0103fd3 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103faa:	0f be d2             	movsbl %dl,%edx
f0103fad:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103fb0:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103fb3:	7d 30                	jge    f0103fe5 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103fb5:	83 c1 01             	add    $0x1,%ecx
f0103fb8:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103fbc:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103fbe:	0f b6 11             	movzbl (%ecx),%edx
f0103fc1:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103fc4:	89 f3                	mov    %esi,%ebx
f0103fc6:	80 fb 09             	cmp    $0x9,%bl
f0103fc9:	77 d5                	ja     f0103fa0 <strtol+0x80>
			dig = *s - '0';
f0103fcb:	0f be d2             	movsbl %dl,%edx
f0103fce:	83 ea 30             	sub    $0x30,%edx
f0103fd1:	eb dd                	jmp    f0103fb0 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103fd3:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103fd6:	89 f3                	mov    %esi,%ebx
f0103fd8:	80 fb 19             	cmp    $0x19,%bl
f0103fdb:	77 08                	ja     f0103fe5 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103fdd:	0f be d2             	movsbl %dl,%edx
f0103fe0:	83 ea 37             	sub    $0x37,%edx
f0103fe3:	eb cb                	jmp    f0103fb0 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103fe5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103fe9:	74 05                	je     f0103ff0 <strtol+0xd0>
		*endptr = (char *) s;
f0103feb:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103fee:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103ff0:	89 c2                	mov    %eax,%edx
f0103ff2:	f7 da                	neg    %edx
f0103ff4:	85 ff                	test   %edi,%edi
f0103ff6:	0f 45 c2             	cmovne %edx,%eax
}
f0103ff9:	5b                   	pop    %ebx
f0103ffa:	5e                   	pop    %esi
f0103ffb:	5f                   	pop    %edi
f0103ffc:	5d                   	pop    %ebp
f0103ffd:	c3                   	ret    
f0103ffe:	66 90                	xchg   %ax,%ax

f0104000 <__udivdi3>:
f0104000:	55                   	push   %ebp
f0104001:	57                   	push   %edi
f0104002:	56                   	push   %esi
f0104003:	53                   	push   %ebx
f0104004:	83 ec 1c             	sub    $0x1c,%esp
f0104007:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010400b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010400f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104013:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0104017:	85 d2                	test   %edx,%edx
f0104019:	75 35                	jne    f0104050 <__udivdi3+0x50>
f010401b:	39 f3                	cmp    %esi,%ebx
f010401d:	0f 87 bd 00 00 00    	ja     f01040e0 <__udivdi3+0xe0>
f0104023:	85 db                	test   %ebx,%ebx
f0104025:	89 d9                	mov    %ebx,%ecx
f0104027:	75 0b                	jne    f0104034 <__udivdi3+0x34>
f0104029:	b8 01 00 00 00       	mov    $0x1,%eax
f010402e:	31 d2                	xor    %edx,%edx
f0104030:	f7 f3                	div    %ebx
f0104032:	89 c1                	mov    %eax,%ecx
f0104034:	31 d2                	xor    %edx,%edx
f0104036:	89 f0                	mov    %esi,%eax
f0104038:	f7 f1                	div    %ecx
f010403a:	89 c6                	mov    %eax,%esi
f010403c:	89 e8                	mov    %ebp,%eax
f010403e:	89 f7                	mov    %esi,%edi
f0104040:	f7 f1                	div    %ecx
f0104042:	89 fa                	mov    %edi,%edx
f0104044:	83 c4 1c             	add    $0x1c,%esp
f0104047:	5b                   	pop    %ebx
f0104048:	5e                   	pop    %esi
f0104049:	5f                   	pop    %edi
f010404a:	5d                   	pop    %ebp
f010404b:	c3                   	ret    
f010404c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104050:	39 f2                	cmp    %esi,%edx
f0104052:	77 7c                	ja     f01040d0 <__udivdi3+0xd0>
f0104054:	0f bd fa             	bsr    %edx,%edi
f0104057:	83 f7 1f             	xor    $0x1f,%edi
f010405a:	0f 84 98 00 00 00    	je     f01040f8 <__udivdi3+0xf8>
f0104060:	89 f9                	mov    %edi,%ecx
f0104062:	b8 20 00 00 00       	mov    $0x20,%eax
f0104067:	29 f8                	sub    %edi,%eax
f0104069:	d3 e2                	shl    %cl,%edx
f010406b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010406f:	89 c1                	mov    %eax,%ecx
f0104071:	89 da                	mov    %ebx,%edx
f0104073:	d3 ea                	shr    %cl,%edx
f0104075:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0104079:	09 d1                	or     %edx,%ecx
f010407b:	89 f2                	mov    %esi,%edx
f010407d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104081:	89 f9                	mov    %edi,%ecx
f0104083:	d3 e3                	shl    %cl,%ebx
f0104085:	89 c1                	mov    %eax,%ecx
f0104087:	d3 ea                	shr    %cl,%edx
f0104089:	89 f9                	mov    %edi,%ecx
f010408b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010408f:	d3 e6                	shl    %cl,%esi
f0104091:	89 eb                	mov    %ebp,%ebx
f0104093:	89 c1                	mov    %eax,%ecx
f0104095:	d3 eb                	shr    %cl,%ebx
f0104097:	09 de                	or     %ebx,%esi
f0104099:	89 f0                	mov    %esi,%eax
f010409b:	f7 74 24 08          	divl   0x8(%esp)
f010409f:	89 d6                	mov    %edx,%esi
f01040a1:	89 c3                	mov    %eax,%ebx
f01040a3:	f7 64 24 0c          	mull   0xc(%esp)
f01040a7:	39 d6                	cmp    %edx,%esi
f01040a9:	72 0c                	jb     f01040b7 <__udivdi3+0xb7>
f01040ab:	89 f9                	mov    %edi,%ecx
f01040ad:	d3 e5                	shl    %cl,%ebp
f01040af:	39 c5                	cmp    %eax,%ebp
f01040b1:	73 5d                	jae    f0104110 <__udivdi3+0x110>
f01040b3:	39 d6                	cmp    %edx,%esi
f01040b5:	75 59                	jne    f0104110 <__udivdi3+0x110>
f01040b7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01040ba:	31 ff                	xor    %edi,%edi
f01040bc:	89 fa                	mov    %edi,%edx
f01040be:	83 c4 1c             	add    $0x1c,%esp
f01040c1:	5b                   	pop    %ebx
f01040c2:	5e                   	pop    %esi
f01040c3:	5f                   	pop    %edi
f01040c4:	5d                   	pop    %ebp
f01040c5:	c3                   	ret    
f01040c6:	8d 76 00             	lea    0x0(%esi),%esi
f01040c9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01040d0:	31 ff                	xor    %edi,%edi
f01040d2:	31 c0                	xor    %eax,%eax
f01040d4:	89 fa                	mov    %edi,%edx
f01040d6:	83 c4 1c             	add    $0x1c,%esp
f01040d9:	5b                   	pop    %ebx
f01040da:	5e                   	pop    %esi
f01040db:	5f                   	pop    %edi
f01040dc:	5d                   	pop    %ebp
f01040dd:	c3                   	ret    
f01040de:	66 90                	xchg   %ax,%ax
f01040e0:	31 ff                	xor    %edi,%edi
f01040e2:	89 e8                	mov    %ebp,%eax
f01040e4:	89 f2                	mov    %esi,%edx
f01040e6:	f7 f3                	div    %ebx
f01040e8:	89 fa                	mov    %edi,%edx
f01040ea:	83 c4 1c             	add    $0x1c,%esp
f01040ed:	5b                   	pop    %ebx
f01040ee:	5e                   	pop    %esi
f01040ef:	5f                   	pop    %edi
f01040f0:	5d                   	pop    %ebp
f01040f1:	c3                   	ret    
f01040f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01040f8:	39 f2                	cmp    %esi,%edx
f01040fa:	72 06                	jb     f0104102 <__udivdi3+0x102>
f01040fc:	31 c0                	xor    %eax,%eax
f01040fe:	39 eb                	cmp    %ebp,%ebx
f0104100:	77 d2                	ja     f01040d4 <__udivdi3+0xd4>
f0104102:	b8 01 00 00 00       	mov    $0x1,%eax
f0104107:	eb cb                	jmp    f01040d4 <__udivdi3+0xd4>
f0104109:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104110:	89 d8                	mov    %ebx,%eax
f0104112:	31 ff                	xor    %edi,%edi
f0104114:	eb be                	jmp    f01040d4 <__udivdi3+0xd4>
f0104116:	66 90                	xchg   %ax,%ax
f0104118:	66 90                	xchg   %ax,%ax
f010411a:	66 90                	xchg   %ax,%ax
f010411c:	66 90                	xchg   %ax,%ax
f010411e:	66 90                	xchg   %ax,%ax

f0104120 <__umoddi3>:
f0104120:	55                   	push   %ebp
f0104121:	57                   	push   %edi
f0104122:	56                   	push   %esi
f0104123:	53                   	push   %ebx
f0104124:	83 ec 1c             	sub    $0x1c,%esp
f0104127:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010412b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010412f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104133:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104137:	85 ed                	test   %ebp,%ebp
f0104139:	89 f0                	mov    %esi,%eax
f010413b:	89 da                	mov    %ebx,%edx
f010413d:	75 19                	jne    f0104158 <__umoddi3+0x38>
f010413f:	39 df                	cmp    %ebx,%edi
f0104141:	0f 86 b1 00 00 00    	jbe    f01041f8 <__umoddi3+0xd8>
f0104147:	f7 f7                	div    %edi
f0104149:	89 d0                	mov    %edx,%eax
f010414b:	31 d2                	xor    %edx,%edx
f010414d:	83 c4 1c             	add    $0x1c,%esp
f0104150:	5b                   	pop    %ebx
f0104151:	5e                   	pop    %esi
f0104152:	5f                   	pop    %edi
f0104153:	5d                   	pop    %ebp
f0104154:	c3                   	ret    
f0104155:	8d 76 00             	lea    0x0(%esi),%esi
f0104158:	39 dd                	cmp    %ebx,%ebp
f010415a:	77 f1                	ja     f010414d <__umoddi3+0x2d>
f010415c:	0f bd cd             	bsr    %ebp,%ecx
f010415f:	83 f1 1f             	xor    $0x1f,%ecx
f0104162:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104166:	0f 84 b4 00 00 00    	je     f0104220 <__umoddi3+0x100>
f010416c:	b8 20 00 00 00       	mov    $0x20,%eax
f0104171:	89 c2                	mov    %eax,%edx
f0104173:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104177:	29 c2                	sub    %eax,%edx
f0104179:	89 c1                	mov    %eax,%ecx
f010417b:	89 f8                	mov    %edi,%eax
f010417d:	d3 e5                	shl    %cl,%ebp
f010417f:	89 d1                	mov    %edx,%ecx
f0104181:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104185:	d3 e8                	shr    %cl,%eax
f0104187:	09 c5                	or     %eax,%ebp
f0104189:	8b 44 24 04          	mov    0x4(%esp),%eax
f010418d:	89 c1                	mov    %eax,%ecx
f010418f:	d3 e7                	shl    %cl,%edi
f0104191:	89 d1                	mov    %edx,%ecx
f0104193:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104197:	89 df                	mov    %ebx,%edi
f0104199:	d3 ef                	shr    %cl,%edi
f010419b:	89 c1                	mov    %eax,%ecx
f010419d:	89 f0                	mov    %esi,%eax
f010419f:	d3 e3                	shl    %cl,%ebx
f01041a1:	89 d1                	mov    %edx,%ecx
f01041a3:	89 fa                	mov    %edi,%edx
f01041a5:	d3 e8                	shr    %cl,%eax
f01041a7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01041ac:	09 d8                	or     %ebx,%eax
f01041ae:	f7 f5                	div    %ebp
f01041b0:	d3 e6                	shl    %cl,%esi
f01041b2:	89 d1                	mov    %edx,%ecx
f01041b4:	f7 64 24 08          	mull   0x8(%esp)
f01041b8:	39 d1                	cmp    %edx,%ecx
f01041ba:	89 c3                	mov    %eax,%ebx
f01041bc:	89 d7                	mov    %edx,%edi
f01041be:	72 06                	jb     f01041c6 <__umoddi3+0xa6>
f01041c0:	75 0e                	jne    f01041d0 <__umoddi3+0xb0>
f01041c2:	39 c6                	cmp    %eax,%esi
f01041c4:	73 0a                	jae    f01041d0 <__umoddi3+0xb0>
f01041c6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01041ca:	19 ea                	sbb    %ebp,%edx
f01041cc:	89 d7                	mov    %edx,%edi
f01041ce:	89 c3                	mov    %eax,%ebx
f01041d0:	89 ca                	mov    %ecx,%edx
f01041d2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01041d7:	29 de                	sub    %ebx,%esi
f01041d9:	19 fa                	sbb    %edi,%edx
f01041db:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01041df:	89 d0                	mov    %edx,%eax
f01041e1:	d3 e0                	shl    %cl,%eax
f01041e3:	89 d9                	mov    %ebx,%ecx
f01041e5:	d3 ee                	shr    %cl,%esi
f01041e7:	d3 ea                	shr    %cl,%edx
f01041e9:	09 f0                	or     %esi,%eax
f01041eb:	83 c4 1c             	add    $0x1c,%esp
f01041ee:	5b                   	pop    %ebx
f01041ef:	5e                   	pop    %esi
f01041f0:	5f                   	pop    %edi
f01041f1:	5d                   	pop    %ebp
f01041f2:	c3                   	ret    
f01041f3:	90                   	nop
f01041f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01041f8:	85 ff                	test   %edi,%edi
f01041fa:	89 f9                	mov    %edi,%ecx
f01041fc:	75 0b                	jne    f0104209 <__umoddi3+0xe9>
f01041fe:	b8 01 00 00 00       	mov    $0x1,%eax
f0104203:	31 d2                	xor    %edx,%edx
f0104205:	f7 f7                	div    %edi
f0104207:	89 c1                	mov    %eax,%ecx
f0104209:	89 d8                	mov    %ebx,%eax
f010420b:	31 d2                	xor    %edx,%edx
f010420d:	f7 f1                	div    %ecx
f010420f:	89 f0                	mov    %esi,%eax
f0104211:	f7 f1                	div    %ecx
f0104213:	e9 31 ff ff ff       	jmp    f0104149 <__umoddi3+0x29>
f0104218:	90                   	nop
f0104219:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104220:	39 dd                	cmp    %ebx,%ebp
f0104222:	72 08                	jb     f010422c <__umoddi3+0x10c>
f0104224:	39 f7                	cmp    %esi,%edi
f0104226:	0f 87 21 ff ff ff    	ja     f010414d <__umoddi3+0x2d>
f010422c:	89 da                	mov    %ebx,%edx
f010422e:	89 f0                	mov    %esi,%eax
f0104230:	29 f8                	sub    %edi,%eax
f0104232:	19 ea                	sbb    %ebp,%edx
f0104234:	e9 14 ff ff ff       	jmp    f010414d <__umoddi3+0x2d>
