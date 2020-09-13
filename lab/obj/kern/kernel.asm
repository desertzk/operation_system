
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 68 00 00 00       	call   f01000a6 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	e8 72 01 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f010004a:	81 c3 be 12 01 00    	add    $0x112be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 78 08 ff ff    	lea    -0xf788(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 bc 0a 00 00       	call   f0100b1f <cprintf>
	if (x > 0)
f0100063:	83 c4 10             	add    $0x10,%esp
f0100066:	85 f6                	test   %esi,%esi
f0100068:	7e 29                	jle    f0100093 <test_backtrace+0x53>
		test_backtrace(x-1);
f010006a:	83 ec 0c             	sub    $0xc,%esp
f010006d:	8d 46 ff             	lea    -0x1(%esi),%eax
f0100070:	50                   	push   %eax
f0100071:	e8 ca ff ff ff       	call   f0100040 <test_backtrace>
f0100076:	83 c4 10             	add    $0x10,%esp
	else
		mon_backtrace(0, 0, 0);
	cprintf("leaving test_backtrace %d\n", x);
f0100079:	83 ec 08             	sub    $0x8,%esp
f010007c:	56                   	push   %esi
f010007d:	8d 83 94 08 ff ff    	lea    -0xf76c(%ebx),%eax
f0100083:	50                   	push   %eax
f0100084:	e8 96 0a 00 00       	call   f0100b1f <cprintf>
}
f0100089:	83 c4 10             	add    $0x10,%esp
f010008c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010008f:	5b                   	pop    %ebx
f0100090:	5e                   	pop    %esi
f0100091:	5d                   	pop    %ebp
f0100092:	c3                   	ret    
		mon_backtrace(0, 0, 0);
f0100093:	83 ec 04             	sub    $0x4,%esp
f0100096:	6a 00                	push   $0x0
f0100098:	6a 00                	push   $0x0
f010009a:	6a 00                	push   $0x0
f010009c:	e8 e1 07 00 00       	call   f0100882 <mon_backtrace>
f01000a1:	83 c4 10             	add    $0x10,%esp
f01000a4:	eb d3                	jmp    f0100079 <test_backtrace+0x39>

f01000a6 <i386_init>:

void
i386_init(void)
{
f01000a6:	55                   	push   %ebp
f01000a7:	89 e5                	mov    %esp,%ebp
f01000a9:	53                   	push   %ebx
f01000aa:	83 ec 08             	sub    $0x8,%esp
f01000ad:	e8 0a 01 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f01000b2:	81 c3 56 12 01 00    	add    $0x11256,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000b8:	c7 c2 60 30 11 f0    	mov    $0xf0113060,%edx
f01000be:	c7 c0 c0 36 11 f0    	mov    $0xf01136c0,%eax
f01000c4:	29 d0                	sub    %edx,%eax
f01000c6:	50                   	push   %eax
f01000c7:	6a 00                	push   $0x0
f01000c9:	52                   	push   %edx
f01000ca:	e8 5f 16 00 00       	call   f010172e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 3f 05 00 00       	call   f0100613 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 af 08 ff ff    	lea    -0xf751(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 37 0a 00 00       	call   f0100b1f <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000e8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ef:	e8 4c ff ff ff       	call   f0100040 <test_backtrace>
f01000f4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000f7:	83 ec 0c             	sub    $0xc,%esp
f01000fa:	6a 00                	push   $0x0
f01000fc:	e8 62 08 00 00       	call   f0100963 <monitor>
f0100101:	83 c4 10             	add    $0x10,%esp
f0100104:	eb f1                	jmp    f01000f7 <i386_init+0x51>

f0100106 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100106:	55                   	push   %ebp
f0100107:	89 e5                	mov    %esp,%ebp
f0100109:	56                   	push   %esi
f010010a:	53                   	push   %ebx
f010010b:	e8 ac 00 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100110:	81 c3 f8 11 01 00    	add    $0x111f8,%ebx
	va_list ap;

	if (panicstr)
f0100116:	83 bb 58 1d 00 00 00 	cmpl   $0x0,0x1d58(%ebx)
f010011d:	74 0f                	je     f010012e <_panic+0x28>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010011f:	83 ec 0c             	sub    $0xc,%esp
f0100122:	6a 00                	push   $0x0
f0100124:	e8 3a 08 00 00       	call   f0100963 <monitor>
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	eb f1                	jmp    f010011f <_panic+0x19>
	panicstr = fmt;
f010012e:	8b 45 10             	mov    0x10(%ebp),%eax
f0100131:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	asm volatile("cli; cld");
f0100137:	fa                   	cli    
f0100138:	fc                   	cld    
	va_start(ap, fmt);
f0100139:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f010013c:	83 ec 04             	sub    $0x4,%esp
f010013f:	ff 75 0c             	pushl  0xc(%ebp)
f0100142:	ff 75 08             	pushl  0x8(%ebp)
f0100145:	8d 83 ca 08 ff ff    	lea    -0xf736(%ebx),%eax
f010014b:	50                   	push   %eax
f010014c:	e8 ce 09 00 00       	call   f0100b1f <cprintf>
	vcprintf(fmt, ap);
f0100151:	83 c4 08             	add    $0x8,%esp
f0100154:	56                   	push   %esi
f0100155:	ff 75 10             	pushl  0x10(%ebp)
f0100158:	e8 8b 09 00 00       	call   f0100ae8 <vcprintf>
	cprintf("\n");
f010015d:	8d 83 06 09 ff ff    	lea    -0xf6fa(%ebx),%eax
f0100163:	89 04 24             	mov    %eax,(%esp)
f0100166:	e8 b4 09 00 00       	call   f0100b1f <cprintf>
f010016b:	83 c4 10             	add    $0x10,%esp
f010016e:	eb af                	jmp    f010011f <_panic+0x19>

f0100170 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100170:	55                   	push   %ebp
f0100171:	89 e5                	mov    %esp,%ebp
f0100173:	56                   	push   %esi
f0100174:	53                   	push   %ebx
f0100175:	e8 42 00 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f010017a:	81 c3 8e 11 01 00    	add    $0x1118e,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100180:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100183:	83 ec 04             	sub    $0x4,%esp
f0100186:	ff 75 0c             	pushl  0xc(%ebp)
f0100189:	ff 75 08             	pushl  0x8(%ebp)
f010018c:	8d 83 e2 08 ff ff    	lea    -0xf71e(%ebx),%eax
f0100192:	50                   	push   %eax
f0100193:	e8 87 09 00 00       	call   f0100b1f <cprintf>
	vcprintf(fmt, ap);
f0100198:	83 c4 08             	add    $0x8,%esp
f010019b:	56                   	push   %esi
f010019c:	ff 75 10             	pushl  0x10(%ebp)
f010019f:	e8 44 09 00 00       	call   f0100ae8 <vcprintf>
	cprintf("\n");
f01001a4:	8d 83 06 09 ff ff    	lea    -0xf6fa(%ebx),%eax
f01001aa:	89 04 24             	mov    %eax,(%esp)
f01001ad:	e8 6d 09 00 00       	call   f0100b1f <cprintf>
	va_end(ap);
}
f01001b2:	83 c4 10             	add    $0x10,%esp
f01001b5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001b8:	5b                   	pop    %ebx
f01001b9:	5e                   	pop    %esi
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <__x86.get_pc_thunk.bx>:
f01001bc:	8b 1c 24             	mov    (%esp),%ebx
f01001bf:	c3                   	ret    

f01001c0 <serial_proc_data>:
//Receives a 8/16/32-bit value from an I/O location. Traditional names are inb, inw and inl respectively.
static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001c0:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c5:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001c6:	a8 01                	test   $0x1,%al
f01001c8:	74 0a                	je     f01001d4 <serial_proc_data+0x14>
f01001ca:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	c3                   	ret    
		return -1;
f01001d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01001d9:	c3                   	ret    

f01001da <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001da:	55                   	push   %ebp
f01001db:	89 e5                	mov    %esp,%ebp
f01001dd:	57                   	push   %edi
f01001de:	56                   	push   %esi
f01001df:	53                   	push   %ebx
f01001e0:	83 ec 1c             	sub    $0x1c,%esp
f01001e3:	e8 75 05 00 00       	call   f010075d <__x86.get_pc_thunk.si>
f01001e8:	81 c6 20 11 01 00    	add    $0x11120,%esi
f01001ee:	89 c7                	mov    %eax,%edi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01001f0:	8d 1d 98 1d 00 00    	lea    0x1d98,%ebx
f01001f6:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f01001f9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01001fc:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	while ((c = (*proc)()) != -1) {
f01001ff:	eb 25                	jmp    f0100226 <cons_intr+0x4c>
		cons.buf[cons.wpos++] = c;
f0100201:	8b 8c 1e 04 02 00 00 	mov    0x204(%esi,%ebx,1),%ecx
f0100208:	8d 51 01             	lea    0x1(%ecx),%edx
f010020b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010020e:	88 04 0f             	mov    %al,(%edi,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f0100211:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f0100217:	b8 00 00 00 00       	mov    $0x0,%eax
f010021c:	0f 44 d0             	cmove  %eax,%edx
f010021f:	89 94 1e 04 02 00 00 	mov    %edx,0x204(%esi,%ebx,1)
	while ((c = (*proc)()) != -1) {
f0100226:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100229:	ff d0                	call   *%eax
f010022b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010022e:	74 06                	je     f0100236 <cons_intr+0x5c>
		if (c == 0)
f0100230:	85 c0                	test   %eax,%eax
f0100232:	75 cd                	jne    f0100201 <cons_intr+0x27>
f0100234:	eb f0                	jmp    f0100226 <cons_intr+0x4c>
	}
}
f0100236:	83 c4 1c             	add    $0x1c,%esp
f0100239:	5b                   	pop    %ebx
f010023a:	5e                   	pop    %esi
f010023b:	5f                   	pop    %edi
f010023c:	5d                   	pop    %ebp
f010023d:	c3                   	ret    

f010023e <kbd_proc_data>:
{
f010023e:	55                   	push   %ebp
f010023f:	89 e5                	mov    %esp,%ebp
f0100241:	56                   	push   %esi
f0100242:	53                   	push   %ebx
f0100243:	e8 74 ff ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100248:	81 c3 c0 10 01 00    	add    $0x110c0,%ebx
f010024e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100253:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100254:	a8 01                	test   $0x1,%al
f0100256:	0f 84 f7 00 00 00    	je     f0100353 <kbd_proc_data+0x115>
	if (stat & KBS_TERR)
f010025c:	a8 20                	test   $0x20,%al
f010025e:	0f 85 f6 00 00 00    	jne    f010035a <kbd_proc_data+0x11c>
f0100264:	ba 60 00 00 00       	mov    $0x60,%edx
f0100269:	ec                   	in     (%dx),%al
f010026a:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f010026c:	3c e0                	cmp    $0xe0,%al
f010026e:	74 64                	je     f01002d4 <kbd_proc_data+0x96>
	} else if (data & 0x80) {
f0100270:	84 c0                	test   %al,%al
f0100272:	78 75                	js     f01002e9 <kbd_proc_data+0xab>
	} else if (shift & E0ESC) {
f0100274:	8b 8b 78 1d 00 00    	mov    0x1d78(%ebx),%ecx
f010027a:	f6 c1 40             	test   $0x40,%cl
f010027d:	74 0e                	je     f010028d <kbd_proc_data+0x4f>
		data |= 0x80;
f010027f:	83 c8 80             	or     $0xffffff80,%eax
f0100282:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100284:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100287:	89 8b 78 1d 00 00    	mov    %ecx,0x1d78(%ebx)
	shift |= shiftcode[data];
f010028d:	0f b6 d2             	movzbl %dl,%edx
f0100290:	0f b6 84 13 38 0a ff 	movzbl -0xf5c8(%ebx,%edx,1),%eax
f0100297:	ff 
f0100298:	0b 83 78 1d 00 00    	or     0x1d78(%ebx),%eax
	shift ^= togglecode[data];
f010029e:	0f b6 8c 13 38 09 ff 	movzbl -0xf6c8(%ebx,%edx,1),%ecx
f01002a5:	ff 
f01002a6:	31 c8                	xor    %ecx,%eax
f01002a8:	89 83 78 1d 00 00    	mov    %eax,0x1d78(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f01002ae:	89 c1                	mov    %eax,%ecx
f01002b0:	83 e1 03             	and    $0x3,%ecx
f01002b3:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f01002ba:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002be:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002c1:	a8 08                	test   $0x8,%al
f01002c3:	74 61                	je     f0100326 <kbd_proc_data+0xe8>
		if ('a' <= c && c <= 'z')
f01002c5:	89 f2                	mov    %esi,%edx
f01002c7:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002ca:	83 f9 19             	cmp    $0x19,%ecx
f01002cd:	77 4b                	ja     f010031a <kbd_proc_data+0xdc>
			c += 'A' - 'a';
f01002cf:	83 ee 20             	sub    $0x20,%esi
f01002d2:	eb 0c                	jmp    f01002e0 <kbd_proc_data+0xa2>
		shift |= E0ESC;
f01002d4:	83 8b 78 1d 00 00 40 	orl    $0x40,0x1d78(%ebx)
		return 0;
f01002db:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002e0:	89 f0                	mov    %esi,%eax
f01002e2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01002e5:	5b                   	pop    %ebx
f01002e6:	5e                   	pop    %esi
f01002e7:	5d                   	pop    %ebp
f01002e8:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f01002e9:	8b 8b 78 1d 00 00    	mov    0x1d78(%ebx),%ecx
f01002ef:	83 e0 7f             	and    $0x7f,%eax
f01002f2:	f6 c1 40             	test   $0x40,%cl
f01002f5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002f8:	0f b6 d2             	movzbl %dl,%edx
f01002fb:	0f b6 84 13 38 0a ff 	movzbl -0xf5c8(%ebx,%edx,1),%eax
f0100302:	ff 
f0100303:	83 c8 40             	or     $0x40,%eax
f0100306:	0f b6 c0             	movzbl %al,%eax
f0100309:	f7 d0                	not    %eax
f010030b:	21 c8                	and    %ecx,%eax
f010030d:	89 83 78 1d 00 00    	mov    %eax,0x1d78(%ebx)
		return 0;
f0100313:	be 00 00 00 00       	mov    $0x0,%esi
f0100318:	eb c6                	jmp    f01002e0 <kbd_proc_data+0xa2>
		else if ('A' <= c && c <= 'Z')
f010031a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010031d:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100320:	83 fa 1a             	cmp    $0x1a,%edx
f0100323:	0f 42 f1             	cmovb  %ecx,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100326:	f7 d0                	not    %eax
f0100328:	a8 06                	test   $0x6,%al
f010032a:	75 b4                	jne    f01002e0 <kbd_proc_data+0xa2>
f010032c:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100332:	75 ac                	jne    f01002e0 <kbd_proc_data+0xa2>
		cprintf("Rebooting!\n");
f0100334:	83 ec 0c             	sub    $0xc,%esp
f0100337:	8d 83 fc 08 ff ff    	lea    -0xf704(%ebx),%eax
f010033d:	50                   	push   %eax
f010033e:	e8 dc 07 00 00       	call   f0100b1f <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100343:	b8 03 00 00 00       	mov    $0x3,%eax
f0100348:	ba 92 00 00 00       	mov    $0x92,%edx
f010034d:	ee                   	out    %al,(%dx)
}
f010034e:	83 c4 10             	add    $0x10,%esp
f0100351:	eb 8d                	jmp    f01002e0 <kbd_proc_data+0xa2>
		return -1;
f0100353:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100358:	eb 86                	jmp    f01002e0 <kbd_proc_data+0xa2>
		return -1;
f010035a:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010035f:	e9 7c ff ff ff       	jmp    f01002e0 <kbd_proc_data+0xa2>

f0100364 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100364:	55                   	push   %ebp
f0100365:	89 e5                	mov    %esp,%ebp
f0100367:	57                   	push   %edi
f0100368:	56                   	push   %esi
f0100369:	53                   	push   %ebx
f010036a:	83 ec 1c             	sub    $0x1c,%esp
f010036d:	e8 4a fe ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100372:	81 c3 96 0f 01 00    	add    $0x10f96,%ebx
f0100378:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f010037b:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100380:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100385:	b9 84 00 00 00       	mov    $0x84,%ecx
f010038a:	89 fa                	mov    %edi,%edx
f010038c:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010038d:	a8 20                	test   $0x20,%al
f010038f:	75 13                	jne    f01003a4 <cons_putc+0x40>
f0100391:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100397:	7f 0b                	jg     f01003a4 <cons_putc+0x40>
f0100399:	89 ca                	mov    %ecx,%edx
f010039b:	ec                   	in     (%dx),%al
f010039c:	ec                   	in     (%dx),%al
f010039d:	ec                   	in     (%dx),%al
f010039e:	ec                   	in     (%dx),%al
	     i++)
f010039f:	83 c6 01             	add    $0x1,%esi
f01003a2:	eb e6                	jmp    f010038a <cons_putc+0x26>
	outb(COM1 + COM_TX, c);
f01003a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003a7:	89 f8                	mov    %edi,%eax
f01003a9:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003ac:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003b1:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003b2:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003b7:	bf 79 03 00 00       	mov    $0x379,%edi
f01003bc:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003c1:	89 fa                	mov    %edi,%edx
f01003c3:	ec                   	in     (%dx),%al
f01003c4:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003ca:	7f 0f                	jg     f01003db <cons_putc+0x77>
f01003cc:	84 c0                	test   %al,%al
f01003ce:	78 0b                	js     f01003db <cons_putc+0x77>
f01003d0:	89 ca                	mov    %ecx,%edx
f01003d2:	ec                   	in     (%dx),%al
f01003d3:	ec                   	in     (%dx),%al
f01003d4:	ec                   	in     (%dx),%al
f01003d5:	ec                   	in     (%dx),%al
f01003d6:	83 c6 01             	add    $0x1,%esi
f01003d9:	eb e6                	jmp    f01003c1 <cons_putc+0x5d>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003db:	ba 78 03 00 00       	mov    $0x378,%edx
f01003e0:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01003e4:	ee                   	out    %al,(%dx)
f01003e5:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01003ea:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003ef:	ee                   	out    %al,(%dx)
f01003f0:	b8 08 00 00 00       	mov    $0x8,%eax
f01003f5:	ee                   	out    %al,(%dx)
		c |= 0x0700;
f01003f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003f9:	89 f8                	mov    %edi,%eax
f01003fb:	80 cc 07             	or     $0x7,%ah
f01003fe:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100404:	0f 45 c7             	cmovne %edi,%eax
f0100407:	89 c7                	mov    %eax,%edi
f0100409:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f010040c:	0f b6 c0             	movzbl %al,%eax
f010040f:	89 f9                	mov    %edi,%ecx
f0100411:	80 f9 0a             	cmp    $0xa,%cl
f0100414:	0f 84 e4 00 00 00    	je     f01004fe <cons_putc+0x19a>
f010041a:	83 f8 0a             	cmp    $0xa,%eax
f010041d:	7f 46                	jg     f0100465 <cons_putc+0x101>
f010041f:	83 f8 08             	cmp    $0x8,%eax
f0100422:	0f 84 a8 00 00 00    	je     f01004d0 <cons_putc+0x16c>
f0100428:	83 f8 09             	cmp    $0x9,%eax
f010042b:	0f 85 da 00 00 00    	jne    f010050b <cons_putc+0x1a7>
		cons_putc(' ');
f0100431:	b8 20 00 00 00       	mov    $0x20,%eax
f0100436:	e8 29 ff ff ff       	call   f0100364 <cons_putc>
		cons_putc(' ');
f010043b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100440:	e8 1f ff ff ff       	call   f0100364 <cons_putc>
		cons_putc(' ');
f0100445:	b8 20 00 00 00       	mov    $0x20,%eax
f010044a:	e8 15 ff ff ff       	call   f0100364 <cons_putc>
		cons_putc(' ');
f010044f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100454:	e8 0b ff ff ff       	call   f0100364 <cons_putc>
		cons_putc(' ');
f0100459:	b8 20 00 00 00       	mov    $0x20,%eax
f010045e:	e8 01 ff ff ff       	call   f0100364 <cons_putc>
		break;
f0100463:	eb 26                	jmp    f010048b <cons_putc+0x127>
	switch (c & 0xff) {
f0100465:	83 f8 0d             	cmp    $0xd,%eax
f0100468:	0f 85 9d 00 00 00    	jne    f010050b <cons_putc+0x1a7>
		crt_pos -= (crt_pos % CRT_COLS);
f010046e:	0f b7 83 a0 1f 00 00 	movzwl 0x1fa0(%ebx),%eax
f0100475:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010047b:	c1 e8 16             	shr    $0x16,%eax
f010047e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100481:	c1 e0 04             	shl    $0x4,%eax
f0100484:	66 89 83 a0 1f 00 00 	mov    %ax,0x1fa0(%ebx)
	if (crt_pos >= CRT_SIZE) {
f010048b:	66 81 bb a0 1f 00 00 	cmpw   $0x7cf,0x1fa0(%ebx)
f0100492:	cf 07 
f0100494:	0f 87 98 00 00 00    	ja     f0100532 <cons_putc+0x1ce>
	outb(addr_6845, 14);
f010049a:	8b 8b a8 1f 00 00    	mov    0x1fa8(%ebx),%ecx
f01004a0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a5:	89 ca                	mov    %ecx,%edx
f01004a7:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a8:	0f b7 9b a0 1f 00 00 	movzwl 0x1fa0(%ebx),%ebx
f01004af:	8d 71 01             	lea    0x1(%ecx),%esi
f01004b2:	89 d8                	mov    %ebx,%eax
f01004b4:	66 c1 e8 08          	shr    $0x8,%ax
f01004b8:	89 f2                	mov    %esi,%edx
f01004ba:	ee                   	out    %al,(%dx)
f01004bb:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004c0:	89 ca                	mov    %ecx,%edx
f01004c2:	ee                   	out    %al,(%dx)
f01004c3:	89 d8                	mov    %ebx,%eax
f01004c5:	89 f2                	mov    %esi,%edx
f01004c7:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004cb:	5b                   	pop    %ebx
f01004cc:	5e                   	pop    %esi
f01004cd:	5f                   	pop    %edi
f01004ce:	5d                   	pop    %ebp
f01004cf:	c3                   	ret    
		if (crt_pos > 0) {
f01004d0:	0f b7 83 a0 1f 00 00 	movzwl 0x1fa0(%ebx),%eax
f01004d7:	66 85 c0             	test   %ax,%ax
f01004da:	74 be                	je     f010049a <cons_putc+0x136>
			crt_pos--;
f01004dc:	83 e8 01             	sub    $0x1,%eax
f01004df:	66 89 83 a0 1f 00 00 	mov    %ax,0x1fa0(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004e6:	0f b7 c0             	movzwl %ax,%eax
f01004e9:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004ed:	b2 00                	mov    $0x0,%dl
f01004ef:	83 ca 20             	or     $0x20,%edx
f01004f2:	8b 8b a4 1f 00 00    	mov    0x1fa4(%ebx),%ecx
f01004f8:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004fc:	eb 8d                	jmp    f010048b <cons_putc+0x127>
		crt_pos += CRT_COLS;
f01004fe:	66 83 83 a0 1f 00 00 	addw   $0x50,0x1fa0(%ebx)
f0100505:	50 
f0100506:	e9 63 ff ff ff       	jmp    f010046e <cons_putc+0x10a>
		crt_buf[crt_pos++] = c;		/* write the character */
f010050b:	0f b7 83 a0 1f 00 00 	movzwl 0x1fa0(%ebx),%eax
f0100512:	8d 50 01             	lea    0x1(%eax),%edx
f0100515:	66 89 93 a0 1f 00 00 	mov    %dx,0x1fa0(%ebx)
f010051c:	0f b7 c0             	movzwl %ax,%eax
f010051f:	8b 93 a4 1f 00 00    	mov    0x1fa4(%ebx),%edx
f0100525:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f0100529:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
f010052d:	e9 59 ff ff ff       	jmp    f010048b <cons_putc+0x127>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100532:	8b 83 a4 1f 00 00    	mov    0x1fa4(%ebx),%eax
f0100538:	83 ec 04             	sub    $0x4,%esp
f010053b:	68 00 0f 00 00       	push   $0xf00
f0100540:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100546:	52                   	push   %edx
f0100547:	50                   	push   %eax
f0100548:	e8 29 12 00 00       	call   f0101776 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010054d:	8b 93 a4 1f 00 00    	mov    0x1fa4(%ebx),%edx
f0100553:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100559:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010055f:	83 c4 10             	add    $0x10,%esp
f0100562:	66 c7 00 20 07       	movw   $0x720,(%eax)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100567:	83 c0 02             	add    $0x2,%eax
f010056a:	39 d0                	cmp    %edx,%eax
f010056c:	75 f4                	jne    f0100562 <cons_putc+0x1fe>
		crt_pos -= CRT_COLS;
f010056e:	66 83 ab a0 1f 00 00 	subw   $0x50,0x1fa0(%ebx)
f0100575:	50 
f0100576:	e9 1f ff ff ff       	jmp    f010049a <cons_putc+0x136>

f010057b <serial_intr>:
{
f010057b:	e8 d9 01 00 00       	call   f0100759 <__x86.get_pc_thunk.ax>
f0100580:	05 88 0d 01 00       	add    $0x10d88,%eax
	if (serial_exists)
f0100585:	80 b8 ac 1f 00 00 00 	cmpb   $0x0,0x1fac(%eax)
f010058c:	75 01                	jne    f010058f <serial_intr+0x14>
f010058e:	c3                   	ret    
{
f010058f:	55                   	push   %ebp
f0100590:	89 e5                	mov    %esp,%ebp
f0100592:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100595:	8d 80 b8 ee fe ff    	lea    -0x11148(%eax),%eax
f010059b:	e8 3a fc ff ff       	call   f01001da <cons_intr>
}
f01005a0:	c9                   	leave  
f01005a1:	c3                   	ret    

f01005a2 <kbd_intr>:
{
f01005a2:	55                   	push   %ebp
f01005a3:	89 e5                	mov    %esp,%ebp
f01005a5:	83 ec 08             	sub    $0x8,%esp
f01005a8:	e8 ac 01 00 00       	call   f0100759 <__x86.get_pc_thunk.ax>
f01005ad:	05 5b 0d 01 00       	add    $0x10d5b,%eax
	cons_intr(kbd_proc_data);
f01005b2:	8d 80 36 ef fe ff    	lea    -0x110ca(%eax),%eax
f01005b8:	e8 1d fc ff ff       	call   f01001da <cons_intr>
}
f01005bd:	c9                   	leave  
f01005be:	c3                   	ret    

f01005bf <cons_getc>:
{
f01005bf:	55                   	push   %ebp
f01005c0:	89 e5                	mov    %esp,%ebp
f01005c2:	53                   	push   %ebx
f01005c3:	83 ec 04             	sub    $0x4,%esp
f01005c6:	e8 f1 fb ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01005cb:	81 c3 3d 0d 01 00    	add    $0x10d3d,%ebx
	serial_intr();
f01005d1:	e8 a5 ff ff ff       	call   f010057b <serial_intr>
	kbd_intr();
f01005d6:	e8 c7 ff ff ff       	call   f01005a2 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005db:	8b 83 98 1f 00 00    	mov    0x1f98(%ebx),%eax
	return 0;
f01005e1:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f01005e6:	3b 83 9c 1f 00 00    	cmp    0x1f9c(%ebx),%eax
f01005ec:	74 1e                	je     f010060c <cons_getc+0x4d>
		c = cons.buf[cons.rpos++];
f01005ee:	8d 48 01             	lea    0x1(%eax),%ecx
f01005f1:	0f b6 94 03 98 1d 00 	movzbl 0x1d98(%ebx,%eax,1),%edx
f01005f8:	00 
			cons.rpos = 0;
f01005f9:	3d ff 01 00 00       	cmp    $0x1ff,%eax
f01005fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100603:	0f 45 c1             	cmovne %ecx,%eax
f0100606:	89 83 98 1f 00 00    	mov    %eax,0x1f98(%ebx)
}
f010060c:	89 d0                	mov    %edx,%eax
f010060e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
f0100616:	57                   	push   %edi
f0100617:	56                   	push   %esi
f0100618:	53                   	push   %ebx
f0100619:	83 ec 1c             	sub    $0x1c,%esp
f010061c:	e8 9b fb ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100621:	81 c3 e7 0c 01 00    	add    $0x10ce7,%ebx
	was = *cp;
f0100627:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010062e:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100635:	5a a5 
	if (*cp != 0xA55A) {
f0100637:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010063e:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100642:	0f 84 bb 00 00 00    	je     f0100703 <cons_init+0xf0>
		addr_6845 = MONO_BASE;
f0100648:	c7 83 a8 1f 00 00 b4 	movl   $0x3b4,0x1fa8(%ebx)
f010064f:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100652:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
	outb(addr_6845, 14);
f0100657:	8b 8b a8 1f 00 00    	mov    0x1fa8(%ebx),%ecx
f010065d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100662:	89 ca                	mov    %ecx,%edx
f0100664:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100665:	8d 71 01             	lea    0x1(%ecx),%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ec                   	in     (%dx),%al
f010066b:	0f b6 c0             	movzbl %al,%eax
f010066e:	c1 e0 08             	shl    $0x8,%eax
f0100671:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100674:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100679:	89 ca                	mov    %ecx,%edx
f010067b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010067c:	89 f2                	mov    %esi,%edx
f010067e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010067f:	89 bb a4 1f 00 00    	mov    %edi,0x1fa4(%ebx)
	pos |= inb(addr_6845 + 1);
f0100685:	0f b6 c0             	movzbl %al,%eax
f0100688:	0b 45 e4             	or     -0x1c(%ebp),%eax
	crt_pos = pos;
f010068b:	66 89 83 a0 1f 00 00 	mov    %ax,0x1fa0(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100692:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100697:	89 c8                	mov    %ecx,%eax
f0100699:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010069e:	ee                   	out    %al,(%dx)
f010069f:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006a4:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006a9:	89 fa                	mov    %edi,%edx
f01006ab:	ee                   	out    %al,(%dx)
f01006ac:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006b1:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006b6:	ee                   	out    %al,(%dx)
f01006b7:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006bc:	89 c8                	mov    %ecx,%eax
f01006be:	89 f2                	mov    %esi,%edx
f01006c0:	ee                   	out    %al,(%dx)
f01006c1:	b8 03 00 00 00       	mov    $0x3,%eax
f01006c6:	89 fa                	mov    %edi,%edx
f01006c8:	ee                   	out    %al,(%dx)
f01006c9:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006ce:	89 c8                	mov    %ecx,%eax
f01006d0:	ee                   	out    %al,(%dx)
f01006d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01006d6:	89 f2                	mov    %esi,%edx
f01006d8:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006d9:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006de:	ec                   	in     (%dx),%al
f01006df:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006e1:	3c ff                	cmp    $0xff,%al
f01006e3:	0f 95 83 ac 1f 00 00 	setne  0x1fac(%ebx)
f01006ea:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006ef:	ec                   	in     (%dx),%al
f01006f0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006f5:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006f6:	80 f9 ff             	cmp    $0xff,%cl
f01006f9:	74 23                	je     f010071e <cons_init+0x10b>
		cprintf("Serial port does not exist!\n");
}
f01006fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006fe:	5b                   	pop    %ebx
f01006ff:	5e                   	pop    %esi
f0100700:	5f                   	pop    %edi
f0100701:	5d                   	pop    %ebp
f0100702:	c3                   	ret    
		*cp = was;
f0100703:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010070a:	c7 83 a8 1f 00 00 d4 	movl   $0x3d4,0x1fa8(%ebx)
f0100711:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100714:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
f0100719:	e9 39 ff ff ff       	jmp    f0100657 <cons_init+0x44>
		cprintf("Serial port does not exist!\n");
f010071e:	83 ec 0c             	sub    $0xc,%esp
f0100721:	8d 83 08 09 ff ff    	lea    -0xf6f8(%ebx),%eax
f0100727:	50                   	push   %eax
f0100728:	e8 f2 03 00 00       	call   f0100b1f <cprintf>
f010072d:	83 c4 10             	add    $0x10,%esp
}
f0100730:	eb c9                	jmp    f01006fb <cons_init+0xe8>

f0100732 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100732:	55                   	push   %ebp
f0100733:	89 e5                	mov    %esp,%ebp
f0100735:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100738:	8b 45 08             	mov    0x8(%ebp),%eax
f010073b:	e8 24 fc ff ff       	call   f0100364 <cons_putc>
}
f0100740:	c9                   	leave  
f0100741:	c3                   	ret    

f0100742 <getchar>:

int
getchar(void)
{
f0100742:	55                   	push   %ebp
f0100743:	89 e5                	mov    %esp,%ebp
f0100745:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100748:	e8 72 fe ff ff       	call   f01005bf <cons_getc>
f010074d:	85 c0                	test   %eax,%eax
f010074f:	74 f7                	je     f0100748 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100751:	c9                   	leave  
f0100752:	c3                   	ret    

f0100753 <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f0100753:	b8 01 00 00 00       	mov    $0x1,%eax
f0100758:	c3                   	ret    

f0100759 <__x86.get_pc_thunk.ax>:
f0100759:	8b 04 24             	mov    (%esp),%eax
f010075c:	c3                   	ret    

f010075d <__x86.get_pc_thunk.si>:
f010075d:	8b 34 24             	mov    (%esp),%esi
f0100760:	c3                   	ret    

f0100761 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100761:	55                   	push   %ebp
f0100762:	89 e5                	mov    %esp,%ebp
f0100764:	56                   	push   %esi
f0100765:	53                   	push   %ebx
f0100766:	e8 51 fa ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010076b:	81 c3 9d 0b 01 00    	add    $0x10b9d,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100771:	83 ec 04             	sub    $0x4,%esp
f0100774:	8d 83 38 0b ff ff    	lea    -0xf4c8(%ebx),%eax
f010077a:	50                   	push   %eax
f010077b:	8d 83 56 0b ff ff    	lea    -0xf4aa(%ebx),%eax
f0100781:	50                   	push   %eax
f0100782:	8d b3 5b 0b ff ff    	lea    -0xf4a5(%ebx),%esi
f0100788:	56                   	push   %esi
f0100789:	e8 91 03 00 00       	call   f0100b1f <cprintf>
f010078e:	83 c4 0c             	add    $0xc,%esp
f0100791:	8d 83 14 0c ff ff    	lea    -0xf3ec(%ebx),%eax
f0100797:	50                   	push   %eax
f0100798:	8d 83 64 0b ff ff    	lea    -0xf49c(%ebx),%eax
f010079e:	50                   	push   %eax
f010079f:	56                   	push   %esi
f01007a0:	e8 7a 03 00 00       	call   f0100b1f <cprintf>
	return 0;
}
f01007a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007aa:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007ad:	5b                   	pop    %ebx
f01007ae:	5e                   	pop    %esi
f01007af:	5d                   	pop    %ebp
f01007b0:	c3                   	ret    

f01007b1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007b1:	55                   	push   %ebp
f01007b2:	89 e5                	mov    %esp,%ebp
f01007b4:	57                   	push   %edi
f01007b5:	56                   	push   %esi
f01007b6:	53                   	push   %ebx
f01007b7:	83 ec 18             	sub    $0x18,%esp
f01007ba:	e8 fd f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01007bf:	81 c3 49 0b 01 00    	add    $0x10b49,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007c5:	8d 83 6d 0b ff ff    	lea    -0xf493(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 4e 03 00 00       	call   f0100b1f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007d1:	83 c4 08             	add    $0x8,%esp
f01007d4:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007da:	8d 83 3c 0c ff ff    	lea    -0xf3c4(%ebx),%eax
f01007e0:	50                   	push   %eax
f01007e1:	e8 39 03 00 00       	call   f0100b1f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e6:	83 c4 0c             	add    $0xc,%esp
f01007e9:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007ef:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007f5:	50                   	push   %eax
f01007f6:	57                   	push   %edi
f01007f7:	8d 83 64 0c ff ff    	lea    -0xf39c(%ebx),%eax
f01007fd:	50                   	push   %eax
f01007fe:	e8 1c 03 00 00       	call   f0100b1f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100803:	83 c4 0c             	add    $0xc,%esp
f0100806:	c7 c0 7d 1b 10 f0    	mov    $0xf0101b7d,%eax
f010080c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100812:	52                   	push   %edx
f0100813:	50                   	push   %eax
f0100814:	8d 83 88 0c ff ff    	lea    -0xf378(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 ff 02 00 00       	call   f0100b1f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100820:	83 c4 0c             	add    $0xc,%esp
f0100823:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f0100829:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010082f:	52                   	push   %edx
f0100830:	50                   	push   %eax
f0100831:	8d 83 ac 0c ff ff    	lea    -0xf354(%ebx),%eax
f0100837:	50                   	push   %eax
f0100838:	e8 e2 02 00 00       	call   f0100b1f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010083d:	83 c4 0c             	add    $0xc,%esp
f0100840:	c7 c6 c0 36 11 f0    	mov    $0xf01136c0,%esi
f0100846:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010084c:	50                   	push   %eax
f010084d:	56                   	push   %esi
f010084e:	8d 83 d0 0c ff ff    	lea    -0xf330(%ebx),%eax
f0100854:	50                   	push   %eax
f0100855:	e8 c5 02 00 00       	call   f0100b1f <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010085a:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010085d:	29 fe                	sub    %edi,%esi
f010085f:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100865:	c1 fe 0a             	sar    $0xa,%esi
f0100868:	56                   	push   %esi
f0100869:	8d 83 f4 0c ff ff    	lea    -0xf30c(%ebx),%eax
f010086f:	50                   	push   %eax
f0100870:	e8 aa 02 00 00       	call   f0100b1f <cprintf>
	return 0;
}
f0100875:	b8 00 00 00 00       	mov    $0x0,%eax
f010087a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010087d:	5b                   	pop    %ebx
f010087e:	5e                   	pop    %esi
f010087f:	5f                   	pop    %edi
f0100880:	5d                   	pop    %ebp
f0100881:	c3                   	ret    

f0100882 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100882:	55                   	push   %ebp
f0100883:	89 e5                	mov    %esp,%ebp
f0100885:	57                   	push   %edi
f0100886:	56                   	push   %esi
f0100887:	53                   	push   %ebx
f0100888:	83 ec 48             	sub    $0x48,%esp
f010088b:	e8 2c f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100890:	81 c3 78 0a 01 00    	add    $0x10a78,%ebx
	// Your code here.
	cprintf("mon_backtrace:\n");
f0100896:	8d 83 86 0b ff ff    	lea    -0xf47a(%ebx),%eax
f010089c:	50                   	push   %eax
f010089d:	e8 7d 02 00 00       	call   f0100b1f <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008a2:	89 e8                	mov    %ebp,%eax
    uint32_t* ebp = (uint32_t*) read_ebp();
f01008a4:	89 c7                	mov    %eax,%edi
    cprintf("Stack backtrace:\n");
f01008a6:	8d 83 96 0b ff ff    	lea    -0xf46a(%ebx),%eax
f01008ac:	89 04 24             	mov    %eax,(%esp)
f01008af:	e8 6b 02 00 00       	call   f0100b1f <cprintf>
    while (ebp) {
f01008b4:	83 c4 10             	add    $0x10,%esp
      uint32_t eip = ebp[1];
      cprintf("ebp %x  eip %x  args", ebp, eip);
f01008b7:	8d 83 a8 0b ff ff    	lea    -0xf458(%ebx),%eax
f01008bd:	89 45 b8             	mov    %eax,-0x48(%ebp)
      int i;
      for (i = 2; i <= 6; ++i)
        cprintf(" %08.x", ebp[i]);
f01008c0:	8d 83 bd 0b ff ff    	lea    -0xf443(%ebx),%eax
f01008c6:	89 45 c4             	mov    %eax,-0x3c(%ebp)
    while (ebp) {
f01008c9:	e9 80 00 00 00       	jmp    f010094e <mon_backtrace+0xcc>
      uint32_t eip = ebp[1];
f01008ce:	8b 47 04             	mov    0x4(%edi),%eax
f01008d1:	89 45 c0             	mov    %eax,-0x40(%ebp)
      cprintf("ebp %x  eip %x  args", ebp, eip);
f01008d4:	83 ec 04             	sub    $0x4,%esp
f01008d7:	50                   	push   %eax
f01008d8:	57                   	push   %edi
f01008d9:	ff 75 b8             	pushl  -0x48(%ebp)
f01008dc:	e8 3e 02 00 00       	call   f0100b1f <cprintf>
f01008e1:	8d 77 08             	lea    0x8(%edi),%esi
f01008e4:	8d 47 1c             	lea    0x1c(%edi),%eax
f01008e7:	83 c4 10             	add    $0x10,%esp
f01008ea:	89 7d bc             	mov    %edi,-0x44(%ebp)
f01008ed:	89 c7                	mov    %eax,%edi
        cprintf(" %08.x", ebp[i]);
f01008ef:	83 ec 08             	sub    $0x8,%esp
f01008f2:	ff 36                	pushl  (%esi)
f01008f4:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008f7:	e8 23 02 00 00       	call   f0100b1f <cprintf>
      for (i = 2; i <= 6; ++i)
f01008fc:	83 c6 04             	add    $0x4,%esi
f01008ff:	83 c4 10             	add    $0x10,%esp
f0100902:	39 fe                	cmp    %edi,%esi
f0100904:	75 e9                	jne    f01008ef <mon_backtrace+0x6d>
      cprintf("\n");
f0100906:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0100909:	83 ec 0c             	sub    $0xc,%esp
f010090c:	8d 83 06 09 ff ff    	lea    -0xf6fa(%ebx),%eax
f0100912:	50                   	push   %eax
f0100913:	e8 07 02 00 00       	call   f0100b1f <cprintf>
      struct Eipdebuginfo info;
      debuginfo_eip(eip, &info);
f0100918:	83 c4 08             	add    $0x8,%esp
f010091b:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010091e:	50                   	push   %eax
f010091f:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0100922:	56                   	push   %esi
f0100923:	e8 00 03 00 00       	call   f0100c28 <debuginfo_eip>
      cprintf("\t%s:%d: %.*s+%d\n", 
f0100928:	83 c4 08             	add    $0x8,%esp
f010092b:	89 f0                	mov    %esi,%eax
f010092d:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100930:	50                   	push   %eax
f0100931:	ff 75 d8             	pushl  -0x28(%ebp)
f0100934:	ff 75 dc             	pushl  -0x24(%ebp)
f0100937:	ff 75 d4             	pushl  -0x2c(%ebp)
f010093a:	ff 75 d0             	pushl  -0x30(%ebp)
f010093d:	8d 83 c4 0b ff ff    	lea    -0xf43c(%ebx),%eax
f0100943:	50                   	push   %eax
f0100944:	e8 d6 01 00 00       	call   f0100b1f <cprintf>
      info.eip_file, info.eip_line,
      info.eip_fn_namelen, info.eip_fn_name,
      eip-info.eip_fn_addr);
  //  kern/monitor.c:143: monitor+106
      ebp = (uint32_t*) *ebp;
f0100949:	8b 3f                	mov    (%edi),%edi
f010094b:	83 c4 20             	add    $0x20,%esp
    while (ebp) {
f010094e:	85 ff                	test   %edi,%edi
f0100950:	0f 85 78 ff ff ff    	jne    f01008ce <mon_backtrace+0x4c>
    }
  return 0;

}
f0100956:	b8 00 00 00 00       	mov    $0x0,%eax
f010095b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010095e:	5b                   	pop    %ebx
f010095f:	5e                   	pop    %esi
f0100960:	5f                   	pop    %edi
f0100961:	5d                   	pop    %ebp
f0100962:	c3                   	ret    

f0100963 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100963:	55                   	push   %ebp
f0100964:	89 e5                	mov    %esp,%ebp
f0100966:	57                   	push   %edi
f0100967:	56                   	push   %esi
f0100968:	53                   	push   %ebx
f0100969:	83 ec 68             	sub    $0x68,%esp
f010096c:	e8 4b f8 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100971:	81 c3 97 09 01 00    	add    $0x10997,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100977:	8d 83 20 0d ff ff    	lea    -0xf2e0(%ebx),%eax
f010097d:	50                   	push   %eax
f010097e:	e8 9c 01 00 00       	call   f0100b1f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100983:	8d 83 44 0d ff ff    	lea    -0xf2bc(%ebx),%eax
f0100989:	89 04 24             	mov    %eax,(%esp)
f010098c:	e8 8e 01 00 00       	call   f0100b1f <cprintf>
f0100991:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100994:	8d bb d9 0b ff ff    	lea    -0xf427(%ebx),%edi
f010099a:	eb 4a                	jmp    f01009e6 <monitor+0x83>
f010099c:	83 ec 08             	sub    $0x8,%esp
f010099f:	0f be c0             	movsbl %al,%eax
f01009a2:	50                   	push   %eax
f01009a3:	57                   	push   %edi
f01009a4:	e8 46 0d 00 00       	call   f01016ef <strchr>
f01009a9:	83 c4 10             	add    $0x10,%esp
f01009ac:	85 c0                	test   %eax,%eax
f01009ae:	74 08                	je     f01009b8 <monitor+0x55>
			*buf++ = 0;
f01009b0:	c6 06 00             	movb   $0x0,(%esi)
f01009b3:	8d 76 01             	lea    0x1(%esi),%esi
f01009b6:	eb 79                	jmp    f0100a31 <monitor+0xce>
		if (*buf == 0)
f01009b8:	80 3e 00             	cmpb   $0x0,(%esi)
f01009bb:	74 7f                	je     f0100a3c <monitor+0xd9>
		if (argc == MAXARGS-1) {
f01009bd:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009c1:	74 0f                	je     f01009d2 <monitor+0x6f>
		argv[argc++] = buf;
f01009c3:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009c6:	8d 48 01             	lea    0x1(%eax),%ecx
f01009c9:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009cc:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01009d0:	eb 44                	jmp    f0100a16 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009d2:	83 ec 08             	sub    $0x8,%esp
f01009d5:	6a 10                	push   $0x10
f01009d7:	8d 83 de 0b ff ff    	lea    -0xf422(%ebx),%eax
f01009dd:	50                   	push   %eax
f01009de:	e8 3c 01 00 00       	call   f0100b1f <cprintf>
			return 0;
f01009e3:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009e6:	8d 83 d5 0b ff ff    	lea    -0xf42b(%ebx),%eax
f01009ec:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009ef:	83 ec 0c             	sub    $0xc,%esp
f01009f2:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009f5:	e8 a2 0a 00 00       	call   f010149c <readline>
f01009fa:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009fc:	83 c4 10             	add    $0x10,%esp
f01009ff:	85 c0                	test   %eax,%eax
f0100a01:	74 ec                	je     f01009ef <monitor+0x8c>
	argv[argc] = 0;
f0100a03:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a0a:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100a11:	eb 1e                	jmp    f0100a31 <monitor+0xce>
			buf++;
f0100a13:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a16:	0f b6 06             	movzbl (%esi),%eax
f0100a19:	84 c0                	test   %al,%al
f0100a1b:	74 14                	je     f0100a31 <monitor+0xce>
f0100a1d:	83 ec 08             	sub    $0x8,%esp
f0100a20:	0f be c0             	movsbl %al,%eax
f0100a23:	50                   	push   %eax
f0100a24:	57                   	push   %edi
f0100a25:	e8 c5 0c 00 00       	call   f01016ef <strchr>
f0100a2a:	83 c4 10             	add    $0x10,%esp
f0100a2d:	85 c0                	test   %eax,%eax
f0100a2f:	74 e2                	je     f0100a13 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a31:	0f b6 06             	movzbl (%esi),%eax
f0100a34:	84 c0                	test   %al,%al
f0100a36:	0f 85 60 ff ff ff    	jne    f010099c <monitor+0x39>
	argv[argc] = 0;
f0100a3c:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a3f:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a46:	00 
	if (argc == 0)
f0100a47:	85 c0                	test   %eax,%eax
f0100a49:	74 9b                	je     f01009e6 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a4b:	83 ec 08             	sub    $0x8,%esp
f0100a4e:	8d 83 56 0b ff ff    	lea    -0xf4aa(%ebx),%eax
f0100a54:	50                   	push   %eax
f0100a55:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a58:	e8 32 0c 00 00       	call   f010168f <strcmp>
f0100a5d:	83 c4 10             	add    $0x10,%esp
f0100a60:	85 c0                	test   %eax,%eax
f0100a62:	74 38                	je     f0100a9c <monitor+0x139>
f0100a64:	83 ec 08             	sub    $0x8,%esp
f0100a67:	8d 83 64 0b ff ff    	lea    -0xf49c(%ebx),%eax
f0100a6d:	50                   	push   %eax
f0100a6e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a71:	e8 19 0c 00 00       	call   f010168f <strcmp>
f0100a76:	83 c4 10             	add    $0x10,%esp
f0100a79:	85 c0                	test   %eax,%eax
f0100a7b:	74 1a                	je     f0100a97 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a7d:	83 ec 08             	sub    $0x8,%esp
f0100a80:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a83:	8d 83 fb 0b ff ff    	lea    -0xf405(%ebx),%eax
f0100a89:	50                   	push   %eax
f0100a8a:	e8 90 00 00 00       	call   f0100b1f <cprintf>
	return 0;
f0100a8f:	83 c4 10             	add    $0x10,%esp
f0100a92:	e9 4f ff ff ff       	jmp    f01009e6 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a97:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100a9c:	83 ec 04             	sub    $0x4,%esp
f0100a9f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100aa2:	ff 75 08             	pushl  0x8(%ebp)
f0100aa5:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100aa8:	52                   	push   %edx
f0100aa9:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100aac:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ab3:	83 c4 10             	add    $0x10,%esp
f0100ab6:	85 c0                	test   %eax,%eax
f0100ab8:	0f 89 28 ff ff ff    	jns    f01009e6 <monitor+0x83>
				break;
	}
}
f0100abe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ac1:	5b                   	pop    %ebx
f0100ac2:	5e                   	pop    %esi
f0100ac3:	5f                   	pop    %edi
f0100ac4:	5d                   	pop    %ebp
f0100ac5:	c3                   	ret    

f0100ac6 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100ac6:	55                   	push   %ebp
f0100ac7:	89 e5                	mov    %esp,%ebp
f0100ac9:	53                   	push   %ebx
f0100aca:	83 ec 10             	sub    $0x10,%esp
f0100acd:	e8 ea f6 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100ad2:	81 c3 36 08 01 00    	add    $0x10836,%ebx
	cputchar(ch);
f0100ad8:	ff 75 08             	pushl  0x8(%ebp)
f0100adb:	e8 52 fc ff ff       	call   f0100732 <cputchar>
	*cnt++;
}
f0100ae0:	83 c4 10             	add    $0x10,%esp
f0100ae3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ae6:	c9                   	leave  
f0100ae7:	c3                   	ret    

f0100ae8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100ae8:	55                   	push   %ebp
f0100ae9:	89 e5                	mov    %esp,%ebp
f0100aeb:	53                   	push   %ebx
f0100aec:	83 ec 14             	sub    $0x14,%esp
f0100aef:	e8 c8 f6 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100af4:	81 c3 14 08 01 00    	add    $0x10814,%ebx
	int cnt = 0;
f0100afa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100b01:	ff 75 0c             	pushl  0xc(%ebp)
f0100b04:	ff 75 08             	pushl  0x8(%ebp)
f0100b07:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100b0a:	50                   	push   %eax
f0100b0b:	8d 83 be f7 fe ff    	lea    -0x10842(%ebx),%eax
f0100b11:	50                   	push   %eax
f0100b12:	e8 66 04 00 00       	call   f0100f7d <vprintfmt>
	return cnt;
}
f0100b17:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b1a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b1d:	c9                   	leave  
f0100b1e:	c3                   	ret    

f0100b1f <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b1f:	55                   	push   %ebp
f0100b20:	89 e5                	mov    %esp,%ebp
f0100b22:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b25:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b28:	50                   	push   %eax
f0100b29:	ff 75 08             	pushl  0x8(%ebp)
f0100b2c:	e8 b7 ff ff ff       	call   f0100ae8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b31:	c9                   	leave  
f0100b32:	c3                   	ret    

f0100b33 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b33:	55                   	push   %ebp
f0100b34:	89 e5                	mov    %esp,%ebp
f0100b36:	57                   	push   %edi
f0100b37:	56                   	push   %esi
f0100b38:	53                   	push   %ebx
f0100b39:	83 ec 14             	sub    $0x14,%esp
f0100b3c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100b3f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100b42:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100b45:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100b48:	8b 1a                	mov    (%edx),%ebx
f0100b4a:	8b 01                	mov    (%ecx),%eax
f0100b4c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b4f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100b56:	eb 2f                	jmp    f0100b87 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100b58:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b5b:	39 c3                	cmp    %eax,%ebx
f0100b5d:	7f 4e                	jg     f0100bad <stab_binsearch+0x7a>
f0100b5f:	0f b6 0a             	movzbl (%edx),%ecx
f0100b62:	83 ea 0c             	sub    $0xc,%edx
f0100b65:	39 f1                	cmp    %esi,%ecx
f0100b67:	75 ef                	jne    f0100b58 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b69:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b6c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b6f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b73:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b76:	73 3a                	jae    f0100bb2 <stab_binsearch+0x7f>
			*region_left = m;
f0100b78:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100b7b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100b7d:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0100b80:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100b87:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100b8a:	7f 53                	jg     f0100bdf <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0100b8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b8f:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0100b92:	89 d0                	mov    %edx,%eax
f0100b94:	c1 e8 1f             	shr    $0x1f,%eax
f0100b97:	01 d0                	add    %edx,%eax
f0100b99:	89 c7                	mov    %eax,%edi
f0100b9b:	d1 ff                	sar    %edi
f0100b9d:	83 e0 fe             	and    $0xfffffffe,%eax
f0100ba0:	01 f8                	add    %edi,%eax
f0100ba2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ba5:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100ba9:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0100bab:	eb ae                	jmp    f0100b5b <stab_binsearch+0x28>
			l = true_m + 1;
f0100bad:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100bb0:	eb d5                	jmp    f0100b87 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100bb2:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100bb5:	76 14                	jbe    f0100bcb <stab_binsearch+0x98>
			*region_right = m - 1;
f0100bb7:	83 e8 01             	sub    $0x1,%eax
f0100bba:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100bbd:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100bc0:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0100bc2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100bc9:	eb bc                	jmp    f0100b87 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100bcb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bce:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0100bd0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100bd4:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0100bd6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100bdd:	eb a8                	jmp    f0100b87 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100bdf:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100be3:	75 15                	jne    f0100bfa <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0100be5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100be8:	8b 00                	mov    (%eax),%eax
f0100bea:	83 e8 01             	sub    $0x1,%eax
f0100bed:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100bf0:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100bf2:	83 c4 14             	add    $0x14,%esp
f0100bf5:	5b                   	pop    %ebx
f0100bf6:	5e                   	pop    %esi
f0100bf7:	5f                   	pop    %edi
f0100bf8:	5d                   	pop    %ebp
f0100bf9:	c3                   	ret    
		for (l = *region_right;
f0100bfa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bfd:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100bff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c02:	8b 0f                	mov    (%edi),%ecx
f0100c04:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c07:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100c0a:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0100c0e:	39 c1                	cmp    %eax,%ecx
f0100c10:	7d 0f                	jge    f0100c21 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0100c12:	0f b6 1a             	movzbl (%edx),%ebx
f0100c15:	83 ea 0c             	sub    $0xc,%edx
f0100c18:	39 f3                	cmp    %esi,%ebx
f0100c1a:	74 05                	je     f0100c21 <stab_binsearch+0xee>
		     l--)
f0100c1c:	83 e8 01             	sub    $0x1,%eax
f0100c1f:	eb ed                	jmp    f0100c0e <stab_binsearch+0xdb>
		*region_left = l;
f0100c21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c24:	89 07                	mov    %eax,(%edi)
}
f0100c26:	eb ca                	jmp    f0100bf2 <stab_binsearch+0xbf>

f0100c28 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c28:	55                   	push   %ebp
f0100c29:	89 e5                	mov    %esp,%ebp
f0100c2b:	57                   	push   %edi
f0100c2c:	56                   	push   %esi
f0100c2d:	53                   	push   %ebx
f0100c2e:	83 ec 3c             	sub    $0x3c,%esp
f0100c31:	e8 86 f5 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100c36:	81 c3 d2 06 01 00    	add    $0x106d2,%ebx
f0100c3c:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100c3f:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c42:	8d 83 69 0d ff ff    	lea    -0xf297(%ebx),%eax
f0100c48:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0100c4a:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100c51:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100c54:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100c5b:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100c5e:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c65:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100c6b:	0f 86 3c 01 00 00    	jbe    f0100dad <debuginfo_eip+0x185>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c71:	c7 c0 1d 5c 10 f0    	mov    $0xf0105c1d,%eax
f0100c77:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f0100c7d:	0f 86 e0 01 00 00    	jbe    f0100e63 <debuginfo_eip+0x23b>
f0100c83:	c7 c0 5d 72 10 f0    	mov    $0xf010725d,%eax
f0100c89:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100c8d:	0f 85 d7 01 00 00    	jne    f0100e6a <debuginfo_eip+0x242>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c93:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c9a:	c7 c0 8c 22 10 f0    	mov    $0xf010228c,%eax
f0100ca0:	c7 c2 1c 5c 10 f0    	mov    $0xf0105c1c,%edx
f0100ca6:	29 c2                	sub    %eax,%edx
f0100ca8:	c1 fa 02             	sar    $0x2,%edx
f0100cab:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100cb1:	83 ea 01             	sub    $0x1,%edx
f0100cb4:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100cb7:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100cba:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100cbd:	83 ec 08             	sub    $0x8,%esp
f0100cc0:	57                   	push   %edi
f0100cc1:	6a 64                	push   $0x64
f0100cc3:	e8 6b fe ff ff       	call   f0100b33 <stab_binsearch>
	if (lfile == 0)
f0100cc8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ccb:	83 c4 10             	add    $0x10,%esp
f0100cce:	85 c0                	test   %eax,%eax
f0100cd0:	0f 84 9b 01 00 00    	je     f0100e71 <debuginfo_eip+0x249>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100cd6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100cd9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cdc:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100cdf:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ce2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ce5:	83 ec 08             	sub    $0x8,%esp
f0100ce8:	57                   	push   %edi
f0100ce9:	6a 24                	push   $0x24
f0100ceb:	c7 c0 8c 22 10 f0    	mov    $0xf010228c,%eax
f0100cf1:	e8 3d fe ff ff       	call   f0100b33 <stab_binsearch>

	if (lfun <= rfun) {
f0100cf6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100cf9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100cfc:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0100cff:	83 c4 10             	add    $0x10,%esp
f0100d02:	39 c8                	cmp    %ecx,%eax
f0100d04:	0f 8f be 00 00 00    	jg     f0100dc8 <debuginfo_eip+0x1a0>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100d0a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d0d:	c7 c1 8c 22 10 f0    	mov    $0xf010228c,%ecx
f0100d13:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0100d16:	8b 11                	mov    (%ecx),%edx
f0100d18:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0100d1b:	c7 c2 5d 72 10 f0    	mov    $0xf010725d,%edx
f0100d21:	81 ea 1d 5c 10 f0    	sub    $0xf0105c1d,%edx
f0100d27:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0100d2a:	73 0c                	jae    f0100d38 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d2c:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0100d2f:	81 c2 1d 5c 10 f0    	add    $0xf0105c1d,%edx
f0100d35:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d38:	8b 51 08             	mov    0x8(%ecx),%edx
f0100d3b:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0100d3e:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0100d40:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100d43:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100d46:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d49:	83 ec 08             	sub    $0x8,%esp
f0100d4c:	6a 3a                	push   $0x3a
f0100d4e:	ff 76 08             	pushl  0x8(%esi)
f0100d51:	e8 bc 09 00 00       	call   f0101712 <strfind>
f0100d56:	2b 46 08             	sub    0x8(%esi),%eax
f0100d59:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100d5c:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d5f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d62:	83 c4 08             	add    $0x8,%esp
f0100d65:	57                   	push   %edi
f0100d66:	6a 44                	push   $0x44
f0100d68:	c7 c0 8c 22 10 f0    	mov    $0xf010228c,%eax
f0100d6e:	e8 c0 fd ff ff       	call   f0100b33 <stab_binsearch>
    if(lline <= rline){
f0100d73:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100d76:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d79:	83 c4 10             	add    $0x10,%esp
        info->eip_line = stabs[rline].n_desc;
    }
    else {
        info->eip_line = -1;
f0100d7c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
    if(lline <= rline){
f0100d81:	39 c1                	cmp    %eax,%ecx
f0100d83:	7f 0e                	jg     f0100d93 <debuginfo_eip+0x16b>
        info->eip_line = stabs[rline].n_desc;
f0100d85:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d88:	c7 c0 8c 22 10 f0    	mov    $0xf010228c,%eax
f0100d8e:	0f b7 54 90 06       	movzwl 0x6(%eax,%edx,4),%edx
f0100d93:	89 56 04             	mov    %edx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d96:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d99:	89 ca                	mov    %ecx,%edx
f0100d9b:	8d 0c 49             	lea    (%ecx,%ecx,2),%ecx
f0100d9e:	c7 c0 8c 22 10 f0    	mov    $0xf010228c,%eax
f0100da4:	8d 44 88 04          	lea    0x4(%eax,%ecx,4),%eax
f0100da8:	89 75 0c             	mov    %esi,0xc(%ebp)
f0100dab:	eb 35                	jmp    f0100de2 <debuginfo_eip+0x1ba>
  	        panic("User address");
f0100dad:	83 ec 04             	sub    $0x4,%esp
f0100db0:	8d 83 73 0d ff ff    	lea    -0xf28d(%ebx),%eax
f0100db6:	50                   	push   %eax
f0100db7:	68 80 00 00 00       	push   $0x80
f0100dbc:	8d 83 80 0d ff ff    	lea    -0xf280(%ebx),%eax
f0100dc2:	50                   	push   %eax
f0100dc3:	e8 3e f3 ff ff       	call   f0100106 <_panic>
		info->eip_fn_addr = addr;
f0100dc8:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100dcb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100dd1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dd4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100dd7:	e9 6d ff ff ff       	jmp    f0100d49 <debuginfo_eip+0x121>
f0100ddc:	83 ea 01             	sub    $0x1,%edx
f0100ddf:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100de2:	39 d7                	cmp    %edx,%edi
f0100de4:	7f 3c                	jg     f0100e22 <debuginfo_eip+0x1fa>
	       && stabs[lline].n_type != N_SOL
f0100de6:	0f b6 08             	movzbl (%eax),%ecx
f0100de9:	80 f9 84             	cmp    $0x84,%cl
f0100dec:	74 0b                	je     f0100df9 <debuginfo_eip+0x1d1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100dee:	80 f9 64             	cmp    $0x64,%cl
f0100df1:	75 e9                	jne    f0100ddc <debuginfo_eip+0x1b4>
f0100df3:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100df7:	74 e3                	je     f0100ddc <debuginfo_eip+0x1b4>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100df9:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100dfc:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100dff:	c7 c0 8c 22 10 f0    	mov    $0xf010228c,%eax
f0100e05:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100e08:	c7 c0 5d 72 10 f0    	mov    $0xf010725d,%eax
f0100e0e:	81 e8 1d 5c 10 f0    	sub    $0xf0105c1d,%eax
f0100e14:	39 c2                	cmp    %eax,%edx
f0100e16:	73 0d                	jae    f0100e25 <debuginfo_eip+0x1fd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100e18:	81 c2 1d 5c 10 f0    	add    $0xf0105c1d,%edx
f0100e1e:	89 16                	mov    %edx,(%esi)
f0100e20:	eb 03                	jmp    f0100e25 <debuginfo_eip+0x1fd>
f0100e22:	8b 75 0c             	mov    0xc(%ebp),%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100e25:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e28:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e2b:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100e30:	39 fa                	cmp    %edi,%edx
f0100e32:	7d 49                	jge    f0100e7d <debuginfo_eip+0x255>
		for (lline = lfun + 1;
f0100e34:	8d 42 01             	lea    0x1(%edx),%eax
f0100e37:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100e3a:	c7 c2 8c 22 10 f0    	mov    $0xf010228c,%edx
f0100e40:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0100e44:	eb 04                	jmp    f0100e4a <debuginfo_eip+0x222>
			info->eip_fn_narg++;
f0100e46:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0100e4a:	39 c7                	cmp    %eax,%edi
f0100e4c:	7e 2a                	jle    f0100e78 <debuginfo_eip+0x250>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e4e:	0f b6 0a             	movzbl (%edx),%ecx
f0100e51:	83 c0 01             	add    $0x1,%eax
f0100e54:	83 c2 0c             	add    $0xc,%edx
f0100e57:	80 f9 a0             	cmp    $0xa0,%cl
f0100e5a:	74 ea                	je     f0100e46 <debuginfo_eip+0x21e>
	return 0;
f0100e5c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e61:	eb 1a                	jmp    f0100e7d <debuginfo_eip+0x255>
		return -1;
f0100e63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e68:	eb 13                	jmp    f0100e7d <debuginfo_eip+0x255>
f0100e6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e6f:	eb 0c                	jmp    f0100e7d <debuginfo_eip+0x255>
		return -1;
f0100e71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e76:	eb 05                	jmp    f0100e7d <debuginfo_eip+0x255>
	return 0;
f0100e78:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e7d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e80:	5b                   	pop    %ebx
f0100e81:	5e                   	pop    %esi
f0100e82:	5f                   	pop    %edi
f0100e83:	5d                   	pop    %ebp
f0100e84:	c3                   	ret    

f0100e85 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e85:	55                   	push   %ebp
f0100e86:	89 e5                	mov    %esp,%ebp
f0100e88:	57                   	push   %edi
f0100e89:	56                   	push   %esi
f0100e8a:	53                   	push   %ebx
f0100e8b:	83 ec 2c             	sub    $0x2c,%esp
f0100e8e:	e8 05 06 00 00       	call   f0101498 <__x86.get_pc_thunk.cx>
f0100e93:	81 c1 75 04 01 00    	add    $0x10475,%ecx
f0100e99:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100e9c:	89 c7                	mov    %eax,%edi
f0100e9e:	89 d6                	mov    %edx,%esi
f0100ea0:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ea3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ea6:	89 d1                	mov    %edx,%ecx
f0100ea8:	89 c2                	mov    %eax,%edx
f0100eaa:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ead:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100eb0:	8b 45 10             	mov    0x10(%ebp),%eax
f0100eb3:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100eb6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100eb9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100ec0:	39 c2                	cmp    %eax,%edx
f0100ec2:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0100ec5:	72 41                	jb     f0100f08 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ec7:	83 ec 0c             	sub    $0xc,%esp
f0100eca:	ff 75 18             	pushl  0x18(%ebp)
f0100ecd:	83 eb 01             	sub    $0x1,%ebx
f0100ed0:	53                   	push   %ebx
f0100ed1:	50                   	push   %eax
f0100ed2:	83 ec 08             	sub    $0x8,%esp
f0100ed5:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100ed8:	ff 75 e0             	pushl  -0x20(%ebp)
f0100edb:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100ede:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ee1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100ee4:	e8 37 0a 00 00       	call   f0101920 <__udivdi3>
f0100ee9:	83 c4 18             	add    $0x18,%esp
f0100eec:	52                   	push   %edx
f0100eed:	50                   	push   %eax
f0100eee:	89 f2                	mov    %esi,%edx
f0100ef0:	89 f8                	mov    %edi,%eax
f0100ef2:	e8 8e ff ff ff       	call   f0100e85 <printnum>
f0100ef7:	83 c4 20             	add    $0x20,%esp
f0100efa:	eb 13                	jmp    f0100f0f <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100efc:	83 ec 08             	sub    $0x8,%esp
f0100eff:	56                   	push   %esi
f0100f00:	ff 75 18             	pushl  0x18(%ebp)
f0100f03:	ff d7                	call   *%edi
f0100f05:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100f08:	83 eb 01             	sub    $0x1,%ebx
f0100f0b:	85 db                	test   %ebx,%ebx
f0100f0d:	7f ed                	jg     f0100efc <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100f0f:	83 ec 08             	sub    $0x8,%esp
f0100f12:	56                   	push   %esi
f0100f13:	83 ec 04             	sub    $0x4,%esp
f0100f16:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100f19:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f1c:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100f1f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f22:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100f25:	e8 06 0b 00 00       	call   f0101a30 <__umoddi3>
f0100f2a:	83 c4 14             	add    $0x14,%esp
f0100f2d:	0f be 84 03 8e 0d ff 	movsbl -0xf272(%ebx,%eax,1),%eax
f0100f34:	ff 
f0100f35:	50                   	push   %eax
f0100f36:	ff d7                	call   *%edi
}
f0100f38:	83 c4 10             	add    $0x10,%esp
f0100f3b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f3e:	5b                   	pop    %ebx
f0100f3f:	5e                   	pop    %esi
f0100f40:	5f                   	pop    %edi
f0100f41:	5d                   	pop    %ebp
f0100f42:	c3                   	ret    

f0100f43 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f43:	55                   	push   %ebp
f0100f44:	89 e5                	mov    %esp,%ebp
f0100f46:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f49:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f4d:	8b 10                	mov    (%eax),%edx
f0100f4f:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f52:	73 0a                	jae    f0100f5e <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f54:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100f57:	89 08                	mov    %ecx,(%eax)
f0100f59:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f5c:	88 02                	mov    %al,(%edx)
}
f0100f5e:	5d                   	pop    %ebp
f0100f5f:	c3                   	ret    

f0100f60 <printfmt>:
{
f0100f60:	55                   	push   %ebp
f0100f61:	89 e5                	mov    %esp,%ebp
f0100f63:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100f66:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f69:	50                   	push   %eax
f0100f6a:	ff 75 10             	pushl  0x10(%ebp)
f0100f6d:	ff 75 0c             	pushl  0xc(%ebp)
f0100f70:	ff 75 08             	pushl  0x8(%ebp)
f0100f73:	e8 05 00 00 00       	call   f0100f7d <vprintfmt>
}
f0100f78:	83 c4 10             	add    $0x10,%esp
f0100f7b:	c9                   	leave  
f0100f7c:	c3                   	ret    

f0100f7d <vprintfmt>:
{
f0100f7d:	55                   	push   %ebp
f0100f7e:	89 e5                	mov    %esp,%ebp
f0100f80:	57                   	push   %edi
f0100f81:	56                   	push   %esi
f0100f82:	53                   	push   %ebx
f0100f83:	83 ec 3c             	sub    $0x3c,%esp
f0100f86:	e8 ce f7 ff ff       	call   f0100759 <__x86.get_pc_thunk.ax>
f0100f8b:	05 7d 03 01 00       	add    $0x1037d,%eax
f0100f90:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f93:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f96:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100f99:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f9c:	8d 80 20 1d 00 00    	lea    0x1d20(%eax),%eax
f0100fa2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100fa5:	eb 0a                	jmp    f0100fb1 <vprintfmt+0x34>
			putch(ch, putdat);
f0100fa7:	83 ec 08             	sub    $0x8,%esp
f0100faa:	57                   	push   %edi
f0100fab:	50                   	push   %eax
f0100fac:	ff d6                	call   *%esi
f0100fae:	83 c4 10             	add    $0x10,%esp
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100fb1:	83 c3 01             	add    $0x1,%ebx
f0100fb4:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0100fb8:	83 f8 25             	cmp    $0x25,%eax
f0100fbb:	74 0c                	je     f0100fc9 <vprintfmt+0x4c>
			if (ch == '\0')
f0100fbd:	85 c0                	test   %eax,%eax
f0100fbf:	75 e6                	jne    f0100fa7 <vprintfmt+0x2a>
}
f0100fc1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fc4:	5b                   	pop    %ebx
f0100fc5:	5e                   	pop    %esi
f0100fc6:	5f                   	pop    %edi
f0100fc7:	5d                   	pop    %ebp
f0100fc8:	c3                   	ret    
		padc = ' ';
f0100fc9:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f0100fcd:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f0100fd4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0100fdb:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f0100fe2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fe7:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100fea:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100fed:	8d 43 01             	lea    0x1(%ebx),%eax
f0100ff0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ff3:	0f b6 13             	movzbl (%ebx),%edx
f0100ff6:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100ff9:	3c 55                	cmp    $0x55,%al
f0100ffb:	0f 87 fb 03 00 00    	ja     f01013fc <.L20>
f0101001:	0f b6 c0             	movzbl %al,%eax
f0101004:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101007:	89 ce                	mov    %ecx,%esi
f0101009:	03 b4 81 1c 0e ff ff 	add    -0xf1e4(%ecx,%eax,4),%esi
f0101010:	ff e6                	jmp    *%esi

f0101012 <.L68>:
f0101012:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f0101015:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f0101019:	eb d2                	jmp    f0100fed <vprintfmt+0x70>

f010101b <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f010101b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010101e:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f0101022:	eb c9                	jmp    f0100fed <vprintfmt+0x70>

f0101024 <.L31>:
f0101024:	0f b6 d2             	movzbl %dl,%edx
f0101027:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f010102a:	b8 00 00 00 00       	mov    $0x0,%eax
f010102f:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0101032:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101035:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101039:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f010103c:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010103f:	83 f9 09             	cmp    $0x9,%ecx
f0101042:	77 58                	ja     f010109c <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0101044:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0101047:	eb e9                	jmp    f0101032 <.L31+0xe>

f0101049 <.L34>:
			precision = va_arg(ap, int);
f0101049:	8b 45 14             	mov    0x14(%ebp),%eax
f010104c:	8b 00                	mov    (%eax),%eax
f010104e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101051:	8b 45 14             	mov    0x14(%ebp),%eax
f0101054:	8d 40 04             	lea    0x4(%eax),%eax
f0101057:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010105a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f010105d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101061:	79 8a                	jns    f0100fed <vprintfmt+0x70>
				width = precision, precision = -1;
f0101063:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101066:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101069:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0101070:	e9 78 ff ff ff       	jmp    f0100fed <vprintfmt+0x70>

f0101075 <.L33>:
f0101075:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101078:	85 c0                	test   %eax,%eax
f010107a:	ba 00 00 00 00       	mov    $0x0,%edx
f010107f:	0f 49 d0             	cmovns %eax,%edx
f0101082:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101085:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0101088:	e9 60 ff ff ff       	jmp    f0100fed <vprintfmt+0x70>

f010108d <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f010108d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0101090:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0101097:	e9 51 ff ff ff       	jmp    f0100fed <vprintfmt+0x70>
f010109c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010109f:	89 75 08             	mov    %esi,0x8(%ebp)
f01010a2:	eb b9                	jmp    f010105d <.L34+0x14>

f01010a4 <.L27>:
			lflag++;
f01010a4:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01010a8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01010ab:	e9 3d ff ff ff       	jmp    f0100fed <vprintfmt+0x70>

f01010b0 <.L30>:
			putch(va_arg(ap, int), putdat);
f01010b0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b6:	8d 58 04             	lea    0x4(%eax),%ebx
f01010b9:	83 ec 08             	sub    $0x8,%esp
f01010bc:	57                   	push   %edi
f01010bd:	ff 30                	pushl  (%eax)
f01010bf:	ff d6                	call   *%esi
			break;
f01010c1:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01010c4:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f01010c7:	e9 c6 02 00 00       	jmp    f0101392 <.L25+0x45>

f01010cc <.L28>:
			err = va_arg(ap, int);
f01010cc:	8b 75 08             	mov    0x8(%ebp),%esi
f01010cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d2:	8d 58 04             	lea    0x4(%eax),%ebx
f01010d5:	8b 00                	mov    (%eax),%eax
f01010d7:	99                   	cltd   
f01010d8:	31 d0                	xor    %edx,%eax
f01010da:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01010dc:	83 f8 06             	cmp    $0x6,%eax
f01010df:	7f 27                	jg     f0101108 <.L28+0x3c>
f01010e1:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01010e4:	8b 14 82             	mov    (%edx,%eax,4),%edx
f01010e7:	85 d2                	test   %edx,%edx
f01010e9:	74 1d                	je     f0101108 <.L28+0x3c>
				printfmt(putch, putdat, "%s", p);
f01010eb:	52                   	push   %edx
f01010ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010ef:	8d 80 af 0d ff ff    	lea    -0xf251(%eax),%eax
f01010f5:	50                   	push   %eax
f01010f6:	57                   	push   %edi
f01010f7:	56                   	push   %esi
f01010f8:	e8 63 fe ff ff       	call   f0100f60 <printfmt>
f01010fd:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101100:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0101103:	e9 8a 02 00 00       	jmp    f0101392 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f0101108:	50                   	push   %eax
f0101109:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010110c:	8d 80 a6 0d ff ff    	lea    -0xf25a(%eax),%eax
f0101112:	50                   	push   %eax
f0101113:	57                   	push   %edi
f0101114:	56                   	push   %esi
f0101115:	e8 46 fe ff ff       	call   f0100f60 <printfmt>
f010111a:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010111d:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0101120:	e9 6d 02 00 00       	jmp    f0101392 <.L25+0x45>

f0101125 <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101125:	8b 75 08             	mov    0x8(%ebp),%esi
f0101128:	8b 45 14             	mov    0x14(%ebp),%eax
f010112b:	83 c0 04             	add    $0x4,%eax
f010112e:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0101131:	8b 45 14             	mov    0x14(%ebp),%eax
f0101134:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0101136:	85 d2                	test   %edx,%edx
f0101138:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010113b:	8d 80 9f 0d ff ff    	lea    -0xf261(%eax),%eax
f0101141:	0f 45 c2             	cmovne %edx,%eax
f0101144:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f0101147:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010114b:	7e 06                	jle    f0101153 <.L24+0x2e>
f010114d:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f0101151:	75 0d                	jne    f0101160 <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101153:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0101156:	89 c3                	mov    %eax,%ebx
f0101158:	03 45 d4             	add    -0x2c(%ebp),%eax
f010115b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010115e:	eb 58                	jmp    f01011b8 <.L24+0x93>
f0101160:	83 ec 08             	sub    $0x8,%esp
f0101163:	ff 75 d8             	pushl  -0x28(%ebp)
f0101166:	ff 75 c8             	pushl  -0x38(%ebp)
f0101169:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010116c:	e8 48 04 00 00       	call   f01015b9 <strnlen>
f0101171:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101174:	29 c2                	sub    %eax,%edx
f0101176:	89 55 bc             	mov    %edx,-0x44(%ebp)
f0101179:	83 c4 10             	add    $0x10,%esp
f010117c:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f010117e:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0101182:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101185:	eb 0f                	jmp    f0101196 <.L24+0x71>
					putch(padc, putdat);
f0101187:	83 ec 08             	sub    $0x8,%esp
f010118a:	57                   	push   %edi
f010118b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010118e:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101190:	83 eb 01             	sub    $0x1,%ebx
f0101193:	83 c4 10             	add    $0x10,%esp
f0101196:	85 db                	test   %ebx,%ebx
f0101198:	7f ed                	jg     f0101187 <.L24+0x62>
f010119a:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010119d:	85 d2                	test   %edx,%edx
f010119f:	b8 00 00 00 00       	mov    $0x0,%eax
f01011a4:	0f 49 c2             	cmovns %edx,%eax
f01011a7:	29 c2                	sub    %eax,%edx
f01011a9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01011ac:	eb a5                	jmp    f0101153 <.L24+0x2e>
					putch(ch, putdat);
f01011ae:	83 ec 08             	sub    $0x8,%esp
f01011b1:	57                   	push   %edi
f01011b2:	52                   	push   %edx
f01011b3:	ff d6                	call   *%esi
f01011b5:	83 c4 10             	add    $0x10,%esp
f01011b8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01011bb:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01011bd:	83 c3 01             	add    $0x1,%ebx
f01011c0:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f01011c4:	0f be d0             	movsbl %al,%edx
f01011c7:	85 d2                	test   %edx,%edx
f01011c9:	74 4b                	je     f0101216 <.L24+0xf1>
f01011cb:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01011cf:	78 06                	js     f01011d7 <.L24+0xb2>
f01011d1:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f01011d5:	78 1e                	js     f01011f5 <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f01011d7:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01011db:	74 d1                	je     f01011ae <.L24+0x89>
f01011dd:	0f be c0             	movsbl %al,%eax
f01011e0:	83 e8 20             	sub    $0x20,%eax
f01011e3:	83 f8 5e             	cmp    $0x5e,%eax
f01011e6:	76 c6                	jbe    f01011ae <.L24+0x89>
					putch('?', putdat);
f01011e8:	83 ec 08             	sub    $0x8,%esp
f01011eb:	57                   	push   %edi
f01011ec:	6a 3f                	push   $0x3f
f01011ee:	ff d6                	call   *%esi
f01011f0:	83 c4 10             	add    $0x10,%esp
f01011f3:	eb c3                	jmp    f01011b8 <.L24+0x93>
f01011f5:	89 cb                	mov    %ecx,%ebx
f01011f7:	eb 0e                	jmp    f0101207 <.L24+0xe2>
				putch(' ', putdat);
f01011f9:	83 ec 08             	sub    $0x8,%esp
f01011fc:	57                   	push   %edi
f01011fd:	6a 20                	push   $0x20
f01011ff:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0101201:	83 eb 01             	sub    $0x1,%ebx
f0101204:	83 c4 10             	add    $0x10,%esp
f0101207:	85 db                	test   %ebx,%ebx
f0101209:	7f ee                	jg     f01011f9 <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f010120b:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010120e:	89 45 14             	mov    %eax,0x14(%ebp)
f0101211:	e9 7c 01 00 00       	jmp    f0101392 <.L25+0x45>
f0101216:	89 cb                	mov    %ecx,%ebx
f0101218:	eb ed                	jmp    f0101207 <.L24+0xe2>

f010121a <.L29>:
	if (lflag >= 2)
f010121a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010121d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101220:	83 f9 01             	cmp    $0x1,%ecx
f0101223:	7f 1b                	jg     f0101240 <.L29+0x26>
	else if (lflag)
f0101225:	85 c9                	test   %ecx,%ecx
f0101227:	74 63                	je     f010128c <.L29+0x72>
		return va_arg(*ap, long);
f0101229:	8b 45 14             	mov    0x14(%ebp),%eax
f010122c:	8b 00                	mov    (%eax),%eax
f010122e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101231:	99                   	cltd   
f0101232:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101235:	8b 45 14             	mov    0x14(%ebp),%eax
f0101238:	8d 40 04             	lea    0x4(%eax),%eax
f010123b:	89 45 14             	mov    %eax,0x14(%ebp)
f010123e:	eb 17                	jmp    f0101257 <.L29+0x3d>
		return va_arg(*ap, long long);
f0101240:	8b 45 14             	mov    0x14(%ebp),%eax
f0101243:	8b 50 04             	mov    0x4(%eax),%edx
f0101246:	8b 00                	mov    (%eax),%eax
f0101248:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010124b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010124e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101251:	8d 40 08             	lea    0x8(%eax),%eax
f0101254:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101257:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010125a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010125d:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0101262:	85 c9                	test   %ecx,%ecx
f0101264:	0f 89 0e 01 00 00    	jns    f0101378 <.L25+0x2b>
				putch('-', putdat);
f010126a:	83 ec 08             	sub    $0x8,%esp
f010126d:	57                   	push   %edi
f010126e:	6a 2d                	push   $0x2d
f0101270:	ff d6                	call   *%esi
				num = -(long long) num;
f0101272:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101275:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101278:	f7 da                	neg    %edx
f010127a:	83 d1 00             	adc    $0x0,%ecx
f010127d:	f7 d9                	neg    %ecx
f010127f:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101282:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101287:	e9 ec 00 00 00       	jmp    f0101378 <.L25+0x2b>
		return va_arg(*ap, int);
f010128c:	8b 45 14             	mov    0x14(%ebp),%eax
f010128f:	8b 00                	mov    (%eax),%eax
f0101291:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101294:	99                   	cltd   
f0101295:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101298:	8b 45 14             	mov    0x14(%ebp),%eax
f010129b:	8d 40 04             	lea    0x4(%eax),%eax
f010129e:	89 45 14             	mov    %eax,0x14(%ebp)
f01012a1:	eb b4                	jmp    f0101257 <.L29+0x3d>

f01012a3 <.L23>:
	if (lflag >= 2)
f01012a3:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01012a6:	8b 75 08             	mov    0x8(%ebp),%esi
f01012a9:	83 f9 01             	cmp    $0x1,%ecx
f01012ac:	7f 1e                	jg     f01012cc <.L23+0x29>
	else if (lflag)
f01012ae:	85 c9                	test   %ecx,%ecx
f01012b0:	74 32                	je     f01012e4 <.L23+0x41>
		return va_arg(*ap, unsigned long);
f01012b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b5:	8b 10                	mov    (%eax),%edx
f01012b7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012bc:	8d 40 04             	lea    0x4(%eax),%eax
f01012bf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012c2:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f01012c7:	e9 ac 00 00 00       	jmp    f0101378 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01012cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01012cf:	8b 10                	mov    (%eax),%edx
f01012d1:	8b 48 04             	mov    0x4(%eax),%ecx
f01012d4:	8d 40 08             	lea    0x8(%eax),%eax
f01012d7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012da:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f01012df:	e9 94 00 00 00       	jmp    f0101378 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01012e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e7:	8b 10                	mov    (%eax),%edx
f01012e9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012ee:	8d 40 04             	lea    0x4(%eax),%eax
f01012f1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012f4:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f01012f9:	eb 7d                	jmp    f0101378 <.L25+0x2b>

f01012fb <.L26>:
	if (lflag >= 2)
f01012fb:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01012fe:	8b 75 08             	mov    0x8(%ebp),%esi
f0101301:	83 f9 01             	cmp    $0x1,%ecx
f0101304:	7f 1b                	jg     f0101321 <.L26+0x26>
	else if (lflag)
f0101306:	85 c9                	test   %ecx,%ecx
f0101308:	74 2c                	je     f0101336 <.L26+0x3b>
		return va_arg(*ap, unsigned long);
f010130a:	8b 45 14             	mov    0x14(%ebp),%eax
f010130d:	8b 10                	mov    (%eax),%edx
f010130f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101314:	8d 40 04             	lea    0x4(%eax),%eax
f0101317:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010131a:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f010131f:	eb 57                	jmp    f0101378 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0101321:	8b 45 14             	mov    0x14(%ebp),%eax
f0101324:	8b 10                	mov    (%eax),%edx
f0101326:	8b 48 04             	mov    0x4(%eax),%ecx
f0101329:	8d 40 08             	lea    0x8(%eax),%eax
f010132c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010132f:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f0101334:	eb 42                	jmp    f0101378 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0101336:	8b 45 14             	mov    0x14(%ebp),%eax
f0101339:	8b 10                	mov    (%eax),%edx
f010133b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101340:	8d 40 04             	lea    0x4(%eax),%eax
f0101343:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101346:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f010134b:	eb 2b                	jmp    f0101378 <.L25+0x2b>

f010134d <.L25>:
			putch('0', putdat);
f010134d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101350:	83 ec 08             	sub    $0x8,%esp
f0101353:	57                   	push   %edi
f0101354:	6a 30                	push   $0x30
f0101356:	ff d6                	call   *%esi
			putch('x', putdat);
f0101358:	83 c4 08             	add    $0x8,%esp
f010135b:	57                   	push   %edi
f010135c:	6a 78                	push   $0x78
f010135e:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101360:	8b 45 14             	mov    0x14(%ebp),%eax
f0101363:	8b 10                	mov    (%eax),%edx
f0101365:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010136a:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010136d:	8d 40 04             	lea    0x4(%eax),%eax
f0101370:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101373:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101378:	83 ec 0c             	sub    $0xc,%esp
f010137b:	0f be 5d cf          	movsbl -0x31(%ebp),%ebx
f010137f:	53                   	push   %ebx
f0101380:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101383:	50                   	push   %eax
f0101384:	51                   	push   %ecx
f0101385:	52                   	push   %edx
f0101386:	89 fa                	mov    %edi,%edx
f0101388:	89 f0                	mov    %esi,%eax
f010138a:	e8 f6 fa ff ff       	call   f0100e85 <printnum>
			break;
f010138f:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101392:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101395:	e9 17 fc ff ff       	jmp    f0100fb1 <vprintfmt+0x34>

f010139a <.L21>:
	if (lflag >= 2)
f010139a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010139d:	8b 75 08             	mov    0x8(%ebp),%esi
f01013a0:	83 f9 01             	cmp    $0x1,%ecx
f01013a3:	7f 1b                	jg     f01013c0 <.L21+0x26>
	else if (lflag)
f01013a5:	85 c9                	test   %ecx,%ecx
f01013a7:	74 2c                	je     f01013d5 <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f01013a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ac:	8b 10                	mov    (%eax),%edx
f01013ae:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013b3:	8d 40 04             	lea    0x4(%eax),%eax
f01013b6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013b9:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f01013be:	eb b8                	jmp    f0101378 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01013c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01013c3:	8b 10                	mov    (%eax),%edx
f01013c5:	8b 48 04             	mov    0x4(%eax),%ecx
f01013c8:	8d 40 08             	lea    0x8(%eax),%eax
f01013cb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013ce:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f01013d3:	eb a3                	jmp    f0101378 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01013d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01013d8:	8b 10                	mov    (%eax),%edx
f01013da:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013df:	8d 40 04             	lea    0x4(%eax),%eax
f01013e2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013e5:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f01013ea:	eb 8c                	jmp    f0101378 <.L25+0x2b>

f01013ec <.L35>:
			putch(ch, putdat);
f01013ec:	8b 75 08             	mov    0x8(%ebp),%esi
f01013ef:	83 ec 08             	sub    $0x8,%esp
f01013f2:	57                   	push   %edi
f01013f3:	6a 25                	push   $0x25
f01013f5:	ff d6                	call   *%esi
			break;
f01013f7:	83 c4 10             	add    $0x10,%esp
f01013fa:	eb 96                	jmp    f0101392 <.L25+0x45>

f01013fc <.L20>:
			putch('%', putdat);
f01013fc:	8b 75 08             	mov    0x8(%ebp),%esi
f01013ff:	83 ec 08             	sub    $0x8,%esp
f0101402:	57                   	push   %edi
f0101403:	6a 25                	push   $0x25
f0101405:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101407:	83 c4 10             	add    $0x10,%esp
f010140a:	89 d8                	mov    %ebx,%eax
f010140c:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101410:	74 05                	je     f0101417 <.L20+0x1b>
f0101412:	83 e8 01             	sub    $0x1,%eax
f0101415:	eb f5                	jmp    f010140c <.L20+0x10>
f0101417:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010141a:	e9 73 ff ff ff       	jmp    f0101392 <.L25+0x45>

f010141f <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010141f:	55                   	push   %ebp
f0101420:	89 e5                	mov    %esp,%ebp
f0101422:	53                   	push   %ebx
f0101423:	83 ec 14             	sub    $0x14,%esp
f0101426:	e8 91 ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010142b:	81 c3 dd fe 00 00    	add    $0xfedd,%ebx
f0101431:	8b 45 08             	mov    0x8(%ebp),%eax
f0101434:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101437:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010143a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010143e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101441:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101448:	85 c0                	test   %eax,%eax
f010144a:	74 2b                	je     f0101477 <vsnprintf+0x58>
f010144c:	85 d2                	test   %edx,%edx
f010144e:	7e 27                	jle    f0101477 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101450:	ff 75 14             	pushl  0x14(%ebp)
f0101453:	ff 75 10             	pushl  0x10(%ebp)
f0101456:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101459:	50                   	push   %eax
f010145a:	8d 83 3b fc fe ff    	lea    -0x103c5(%ebx),%eax
f0101460:	50                   	push   %eax
f0101461:	e8 17 fb ff ff       	call   f0100f7d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101466:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101469:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010146c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010146f:	83 c4 10             	add    $0x10,%esp
}
f0101472:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101475:	c9                   	leave  
f0101476:	c3                   	ret    
		return -E_INVAL;
f0101477:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010147c:	eb f4                	jmp    f0101472 <vsnprintf+0x53>

f010147e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010147e:	55                   	push   %ebp
f010147f:	89 e5                	mov    %esp,%ebp
f0101481:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101484:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101487:	50                   	push   %eax
f0101488:	ff 75 10             	pushl  0x10(%ebp)
f010148b:	ff 75 0c             	pushl  0xc(%ebp)
f010148e:	ff 75 08             	pushl  0x8(%ebp)
f0101491:	e8 89 ff ff ff       	call   f010141f <vsnprintf>
	va_end(ap);

	return rc;
}
f0101496:	c9                   	leave  
f0101497:	c3                   	ret    

f0101498 <__x86.get_pc_thunk.cx>:
f0101498:	8b 0c 24             	mov    (%esp),%ecx
f010149b:	c3                   	ret    

f010149c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010149c:	55                   	push   %ebp
f010149d:	89 e5                	mov    %esp,%ebp
f010149f:	57                   	push   %edi
f01014a0:	56                   	push   %esi
f01014a1:	53                   	push   %ebx
f01014a2:	83 ec 1c             	sub    $0x1c,%esp
f01014a5:	e8 12 ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01014aa:	81 c3 5e fe 00 00    	add    $0xfe5e,%ebx
f01014b0:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01014b3:	85 c0                	test   %eax,%eax
f01014b5:	74 13                	je     f01014ca <readline+0x2e>
		cprintf("%s", prompt);
f01014b7:	83 ec 08             	sub    $0x8,%esp
f01014ba:	50                   	push   %eax
f01014bb:	8d 83 af 0d ff ff    	lea    -0xf251(%ebx),%eax
f01014c1:	50                   	push   %eax
f01014c2:	e8 58 f6 ff ff       	call   f0100b1f <cprintf>
f01014c7:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01014ca:	83 ec 0c             	sub    $0xc,%esp
f01014cd:	6a 00                	push   $0x0
f01014cf:	e8 7f f2 ff ff       	call   f0100753 <iscons>
f01014d4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01014d7:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01014da:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f01014df:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f01014e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01014e8:	eb 45                	jmp    f010152f <readline+0x93>
			cprintf("read error: %e\n", c);
f01014ea:	83 ec 08             	sub    $0x8,%esp
f01014ed:	50                   	push   %eax
f01014ee:	8d 83 74 0f ff ff    	lea    -0xf08c(%ebx),%eax
f01014f4:	50                   	push   %eax
f01014f5:	e8 25 f6 ff ff       	call   f0100b1f <cprintf>
			return NULL;
f01014fa:	83 c4 10             	add    $0x10,%esp
f01014fd:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101502:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101505:	5b                   	pop    %ebx
f0101506:	5e                   	pop    %esi
f0101507:	5f                   	pop    %edi
f0101508:	5d                   	pop    %ebp
f0101509:	c3                   	ret    
			if (echoing)
f010150a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010150e:	75 05                	jne    f0101515 <readline+0x79>
			i--;
f0101510:	83 ef 01             	sub    $0x1,%edi
f0101513:	eb 1a                	jmp    f010152f <readline+0x93>
				cputchar('\b');
f0101515:	83 ec 0c             	sub    $0xc,%esp
f0101518:	6a 08                	push   $0x8
f010151a:	e8 13 f2 ff ff       	call   f0100732 <cputchar>
f010151f:	83 c4 10             	add    $0x10,%esp
f0101522:	eb ec                	jmp    f0101510 <readline+0x74>
			buf[i++] = c;
f0101524:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101527:	89 f0                	mov    %esi,%eax
f0101529:	88 04 39             	mov    %al,(%ecx,%edi,1)
f010152c:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f010152f:	e8 0e f2 ff ff       	call   f0100742 <getchar>
f0101534:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0101536:	85 c0                	test   %eax,%eax
f0101538:	78 b0                	js     f01014ea <readline+0x4e>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010153a:	83 f8 08             	cmp    $0x8,%eax
f010153d:	0f 94 c2             	sete   %dl
f0101540:	83 f8 7f             	cmp    $0x7f,%eax
f0101543:	0f 94 c0             	sete   %al
f0101546:	08 c2                	or     %al,%dl
f0101548:	74 04                	je     f010154e <readline+0xb2>
f010154a:	85 ff                	test   %edi,%edi
f010154c:	7f bc                	jg     f010150a <readline+0x6e>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010154e:	83 fe 1f             	cmp    $0x1f,%esi
f0101551:	7e 1c                	jle    f010156f <readline+0xd3>
f0101553:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101559:	7f 14                	jg     f010156f <readline+0xd3>
			if (echoing)
f010155b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010155f:	74 c3                	je     f0101524 <readline+0x88>
				cputchar(c);
f0101561:	83 ec 0c             	sub    $0xc,%esp
f0101564:	56                   	push   %esi
f0101565:	e8 c8 f1 ff ff       	call   f0100732 <cputchar>
f010156a:	83 c4 10             	add    $0x10,%esp
f010156d:	eb b5                	jmp    f0101524 <readline+0x88>
		} else if (c == '\n' || c == '\r') {
f010156f:	83 fe 0a             	cmp    $0xa,%esi
f0101572:	74 05                	je     f0101579 <readline+0xdd>
f0101574:	83 fe 0d             	cmp    $0xd,%esi
f0101577:	75 b6                	jne    f010152f <readline+0x93>
			if (echoing)
f0101579:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010157d:	75 13                	jne    f0101592 <readline+0xf6>
			buf[i] = 0;
f010157f:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f0101586:	00 
			return buf;
f0101587:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f010158d:	e9 70 ff ff ff       	jmp    f0101502 <readline+0x66>
				cputchar('\n');
f0101592:	83 ec 0c             	sub    $0xc,%esp
f0101595:	6a 0a                	push   $0xa
f0101597:	e8 96 f1 ff ff       	call   f0100732 <cputchar>
f010159c:	83 c4 10             	add    $0x10,%esp
f010159f:	eb de                	jmp    f010157f <readline+0xe3>

f01015a1 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01015a1:	55                   	push   %ebp
f01015a2:	89 e5                	mov    %esp,%ebp
f01015a4:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01015a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01015ac:	eb 03                	jmp    f01015b1 <strlen+0x10>
		n++;
f01015ae:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01015b1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01015b5:	75 f7                	jne    f01015ae <strlen+0xd>
	return n;
}
f01015b7:	5d                   	pop    %ebp
f01015b8:	c3                   	ret    

f01015b9 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01015b9:	55                   	push   %ebp
f01015ba:	89 e5                	mov    %esp,%ebp
f01015bc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015bf:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01015c7:	eb 03                	jmp    f01015cc <strnlen+0x13>
		n++;
f01015c9:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015cc:	39 d0                	cmp    %edx,%eax
f01015ce:	74 08                	je     f01015d8 <strnlen+0x1f>
f01015d0:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01015d4:	75 f3                	jne    f01015c9 <strnlen+0x10>
f01015d6:	89 c2                	mov    %eax,%edx
	return n;
}
f01015d8:	89 d0                	mov    %edx,%eax
f01015da:	5d                   	pop    %ebp
f01015db:	c3                   	ret    

f01015dc <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01015dc:	55                   	push   %ebp
f01015dd:	89 e5                	mov    %esp,%ebp
f01015df:	53                   	push   %ebx
f01015e0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015e3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01015e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01015eb:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f01015ef:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f01015f2:	83 c0 01             	add    $0x1,%eax
f01015f5:	84 d2                	test   %dl,%dl
f01015f7:	75 f2                	jne    f01015eb <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01015f9:	89 c8                	mov    %ecx,%eax
f01015fb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01015fe:	c9                   	leave  
f01015ff:	c3                   	ret    

f0101600 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101600:	55                   	push   %ebp
f0101601:	89 e5                	mov    %esp,%ebp
f0101603:	53                   	push   %ebx
f0101604:	83 ec 10             	sub    $0x10,%esp
f0101607:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010160a:	53                   	push   %ebx
f010160b:	e8 91 ff ff ff       	call   f01015a1 <strlen>
f0101610:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0101613:	ff 75 0c             	pushl  0xc(%ebp)
f0101616:	01 d8                	add    %ebx,%eax
f0101618:	50                   	push   %eax
f0101619:	e8 be ff ff ff       	call   f01015dc <strcpy>
	return dst;
}
f010161e:	89 d8                	mov    %ebx,%eax
f0101620:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101623:	c9                   	leave  
f0101624:	c3                   	ret    

f0101625 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101625:	55                   	push   %ebp
f0101626:	89 e5                	mov    %esp,%ebp
f0101628:	56                   	push   %esi
f0101629:	53                   	push   %ebx
f010162a:	8b 75 08             	mov    0x8(%ebp),%esi
f010162d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101630:	89 f3                	mov    %esi,%ebx
f0101632:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101635:	89 f0                	mov    %esi,%eax
f0101637:	eb 0f                	jmp    f0101648 <strncpy+0x23>
		*dst++ = *src;
f0101639:	83 c0 01             	add    $0x1,%eax
f010163c:	0f b6 0a             	movzbl (%edx),%ecx
f010163f:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101642:	80 f9 01             	cmp    $0x1,%cl
f0101645:	83 da ff             	sbb    $0xffffffff,%edx
	for (i = 0; i < size; i++) {
f0101648:	39 d8                	cmp    %ebx,%eax
f010164a:	75 ed                	jne    f0101639 <strncpy+0x14>
	}
	return ret;
}
f010164c:	89 f0                	mov    %esi,%eax
f010164e:	5b                   	pop    %ebx
f010164f:	5e                   	pop    %esi
f0101650:	5d                   	pop    %ebp
f0101651:	c3                   	ret    

f0101652 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101652:	55                   	push   %ebp
f0101653:	89 e5                	mov    %esp,%ebp
f0101655:	56                   	push   %esi
f0101656:	53                   	push   %ebx
f0101657:	8b 75 08             	mov    0x8(%ebp),%esi
f010165a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010165d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101660:	89 f3                	mov    %esi,%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101662:	85 c0                	test   %eax,%eax
f0101664:	74 21                	je     f0101687 <strlcpy+0x35>
f0101666:	8d 5c 06 ff          	lea    -0x1(%esi,%eax,1),%ebx
f010166a:	89 f0                	mov    %esi,%eax
f010166c:	eb 09                	jmp    f0101677 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010166e:	83 c2 01             	add    $0x1,%edx
f0101671:	83 c0 01             	add    $0x1,%eax
f0101674:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101677:	39 d8                	cmp    %ebx,%eax
f0101679:	74 09                	je     f0101684 <strlcpy+0x32>
f010167b:	0f b6 0a             	movzbl (%edx),%ecx
f010167e:	84 c9                	test   %cl,%cl
f0101680:	75 ec                	jne    f010166e <strlcpy+0x1c>
f0101682:	89 c3                	mov    %eax,%ebx
		*dst = '\0';
f0101684:	c6 03 00             	movb   $0x0,(%ebx)
	}
	return dst - dst_in;
f0101687:	89 d8                	mov    %ebx,%eax
f0101689:	29 f0                	sub    %esi,%eax
}
f010168b:	5b                   	pop    %ebx
f010168c:	5e                   	pop    %esi
f010168d:	5d                   	pop    %ebp
f010168e:	c3                   	ret    

f010168f <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010168f:	55                   	push   %ebp
f0101690:	89 e5                	mov    %esp,%ebp
f0101692:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101695:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101698:	eb 06                	jmp    f01016a0 <strcmp+0x11>
		p++, q++;
f010169a:	83 c1 01             	add    $0x1,%ecx
f010169d:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01016a0:	0f b6 01             	movzbl (%ecx),%eax
f01016a3:	84 c0                	test   %al,%al
f01016a5:	74 04                	je     f01016ab <strcmp+0x1c>
f01016a7:	3a 02                	cmp    (%edx),%al
f01016a9:	74 ef                	je     f010169a <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01016ab:	0f b6 c0             	movzbl %al,%eax
f01016ae:	0f b6 12             	movzbl (%edx),%edx
f01016b1:	29 d0                	sub    %edx,%eax
}
f01016b3:	5d                   	pop    %ebp
f01016b4:	c3                   	ret    

f01016b5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01016b5:	55                   	push   %ebp
f01016b6:	89 e5                	mov    %esp,%ebp
f01016b8:	53                   	push   %ebx
f01016b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01016bc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016bf:	89 c3                	mov    %eax,%ebx
f01016c1:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01016c4:	eb 06                	jmp    f01016cc <strncmp+0x17>
		n--, p++, q++;
f01016c6:	83 c0 01             	add    $0x1,%eax
f01016c9:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01016cc:	39 d8                	cmp    %ebx,%eax
f01016ce:	74 18                	je     f01016e8 <strncmp+0x33>
f01016d0:	0f b6 08             	movzbl (%eax),%ecx
f01016d3:	84 c9                	test   %cl,%cl
f01016d5:	74 04                	je     f01016db <strncmp+0x26>
f01016d7:	3a 0a                	cmp    (%edx),%cl
f01016d9:	74 eb                	je     f01016c6 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01016db:	0f b6 00             	movzbl (%eax),%eax
f01016de:	0f b6 12             	movzbl (%edx),%edx
f01016e1:	29 d0                	sub    %edx,%eax
}
f01016e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01016e6:	c9                   	leave  
f01016e7:	c3                   	ret    
		return 0;
f01016e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01016ed:	eb f4                	jmp    f01016e3 <strncmp+0x2e>

f01016ef <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01016ef:	55                   	push   %ebp
f01016f0:	89 e5                	mov    %esp,%ebp
f01016f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01016f5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016f9:	eb 03                	jmp    f01016fe <strchr+0xf>
f01016fb:	83 c0 01             	add    $0x1,%eax
f01016fe:	0f b6 10             	movzbl (%eax),%edx
f0101701:	84 d2                	test   %dl,%dl
f0101703:	74 06                	je     f010170b <strchr+0x1c>
		if (*s == c)
f0101705:	38 ca                	cmp    %cl,%dl
f0101707:	75 f2                	jne    f01016fb <strchr+0xc>
f0101709:	eb 05                	jmp    f0101710 <strchr+0x21>
			return (char *) s;
	return 0;
f010170b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101710:	5d                   	pop    %ebp
f0101711:	c3                   	ret    

f0101712 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101712:	55                   	push   %ebp
f0101713:	89 e5                	mov    %esp,%ebp
f0101715:	8b 45 08             	mov    0x8(%ebp),%eax
f0101718:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010171c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010171f:	38 ca                	cmp    %cl,%dl
f0101721:	74 09                	je     f010172c <strfind+0x1a>
f0101723:	84 d2                	test   %dl,%dl
f0101725:	74 05                	je     f010172c <strfind+0x1a>
	for (; *s; s++)
f0101727:	83 c0 01             	add    $0x1,%eax
f010172a:	eb f0                	jmp    f010171c <strfind+0xa>
			break;
	return (char *) s;
}
f010172c:	5d                   	pop    %ebp
f010172d:	c3                   	ret    

f010172e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010172e:	55                   	push   %ebp
f010172f:	89 e5                	mov    %esp,%ebp
f0101731:	57                   	push   %edi
f0101732:	56                   	push   %esi
f0101733:	53                   	push   %ebx
f0101734:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101737:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010173a:	85 c9                	test   %ecx,%ecx
f010173c:	74 31                	je     f010176f <memset+0x41>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010173e:	89 f8                	mov    %edi,%eax
f0101740:	09 c8                	or     %ecx,%eax
f0101742:	a8 03                	test   $0x3,%al
f0101744:	75 23                	jne    f0101769 <memset+0x3b>
		c &= 0xFF;
f0101746:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010174a:	89 d3                	mov    %edx,%ebx
f010174c:	c1 e3 08             	shl    $0x8,%ebx
f010174f:	89 d0                	mov    %edx,%eax
f0101751:	c1 e0 18             	shl    $0x18,%eax
f0101754:	89 d6                	mov    %edx,%esi
f0101756:	c1 e6 10             	shl    $0x10,%esi
f0101759:	09 f0                	or     %esi,%eax
f010175b:	09 c2                	or     %eax,%edx
f010175d:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010175f:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101762:	89 d0                	mov    %edx,%eax
f0101764:	fc                   	cld    
f0101765:	f3 ab                	rep stos %eax,%es:(%edi)
f0101767:	eb 06                	jmp    f010176f <memset+0x41>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101769:	8b 45 0c             	mov    0xc(%ebp),%eax
f010176c:	fc                   	cld    
f010176d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010176f:	89 f8                	mov    %edi,%eax
f0101771:	5b                   	pop    %ebx
f0101772:	5e                   	pop    %esi
f0101773:	5f                   	pop    %edi
f0101774:	5d                   	pop    %ebp
f0101775:	c3                   	ret    

f0101776 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101776:	55                   	push   %ebp
f0101777:	89 e5                	mov    %esp,%ebp
f0101779:	57                   	push   %edi
f010177a:	56                   	push   %esi
f010177b:	8b 45 08             	mov    0x8(%ebp),%eax
f010177e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101781:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101784:	39 c6                	cmp    %eax,%esi
f0101786:	73 32                	jae    f01017ba <memmove+0x44>
f0101788:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010178b:	39 c2                	cmp    %eax,%edx
f010178d:	76 2b                	jbe    f01017ba <memmove+0x44>
		s += n;
		d += n;
f010178f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101792:	89 fe                	mov    %edi,%esi
f0101794:	09 ce                	or     %ecx,%esi
f0101796:	09 d6                	or     %edx,%esi
f0101798:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010179e:	75 0e                	jne    f01017ae <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01017a0:	83 ef 04             	sub    $0x4,%edi
f01017a3:	8d 72 fc             	lea    -0x4(%edx),%esi
f01017a6:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01017a9:	fd                   	std    
f01017aa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017ac:	eb 09                	jmp    f01017b7 <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01017ae:	83 ef 01             	sub    $0x1,%edi
f01017b1:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01017b4:	fd                   	std    
f01017b5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01017b7:	fc                   	cld    
f01017b8:	eb 1a                	jmp    f01017d4 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017ba:	89 c2                	mov    %eax,%edx
f01017bc:	09 ca                	or     %ecx,%edx
f01017be:	09 f2                	or     %esi,%edx
f01017c0:	f6 c2 03             	test   $0x3,%dl
f01017c3:	75 0a                	jne    f01017cf <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01017c5:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01017c8:	89 c7                	mov    %eax,%edi
f01017ca:	fc                   	cld    
f01017cb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017cd:	eb 05                	jmp    f01017d4 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f01017cf:	89 c7                	mov    %eax,%edi
f01017d1:	fc                   	cld    
f01017d2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01017d4:	5e                   	pop    %esi
f01017d5:	5f                   	pop    %edi
f01017d6:	5d                   	pop    %ebp
f01017d7:	c3                   	ret    

f01017d8 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01017d8:	55                   	push   %ebp
f01017d9:	89 e5                	mov    %esp,%ebp
f01017db:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01017de:	ff 75 10             	pushl  0x10(%ebp)
f01017e1:	ff 75 0c             	pushl  0xc(%ebp)
f01017e4:	ff 75 08             	pushl  0x8(%ebp)
f01017e7:	e8 8a ff ff ff       	call   f0101776 <memmove>
}
f01017ec:	c9                   	leave  
f01017ed:	c3                   	ret    

f01017ee <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01017ee:	55                   	push   %ebp
f01017ef:	89 e5                	mov    %esp,%ebp
f01017f1:	56                   	push   %esi
f01017f2:	53                   	push   %ebx
f01017f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01017f6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01017f9:	89 c6                	mov    %eax,%esi
f01017fb:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017fe:	eb 06                	jmp    f0101806 <memcmp+0x18>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101800:	83 c0 01             	add    $0x1,%eax
f0101803:	83 c2 01             	add    $0x1,%edx
	while (n-- > 0) {
f0101806:	39 f0                	cmp    %esi,%eax
f0101808:	74 14                	je     f010181e <memcmp+0x30>
		if (*s1 != *s2)
f010180a:	0f b6 08             	movzbl (%eax),%ecx
f010180d:	0f b6 1a             	movzbl (%edx),%ebx
f0101810:	38 d9                	cmp    %bl,%cl
f0101812:	74 ec                	je     f0101800 <memcmp+0x12>
			return (int) *s1 - (int) *s2;
f0101814:	0f b6 c1             	movzbl %cl,%eax
f0101817:	0f b6 db             	movzbl %bl,%ebx
f010181a:	29 d8                	sub    %ebx,%eax
f010181c:	eb 05                	jmp    f0101823 <memcmp+0x35>
	}

	return 0;
f010181e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101823:	5b                   	pop    %ebx
f0101824:	5e                   	pop    %esi
f0101825:	5d                   	pop    %ebp
f0101826:	c3                   	ret    

f0101827 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101827:	55                   	push   %ebp
f0101828:	89 e5                	mov    %esp,%ebp
f010182a:	8b 45 08             	mov    0x8(%ebp),%eax
f010182d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101830:	89 c2                	mov    %eax,%edx
f0101832:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101835:	eb 03                	jmp    f010183a <memfind+0x13>
f0101837:	83 c0 01             	add    $0x1,%eax
f010183a:	39 d0                	cmp    %edx,%eax
f010183c:	73 04                	jae    f0101842 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f010183e:	38 08                	cmp    %cl,(%eax)
f0101840:	75 f5                	jne    f0101837 <memfind+0x10>
			break;
	return (void *) s;
}
f0101842:	5d                   	pop    %ebp
f0101843:	c3                   	ret    

f0101844 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101844:	55                   	push   %ebp
f0101845:	89 e5                	mov    %esp,%ebp
f0101847:	57                   	push   %edi
f0101848:	56                   	push   %esi
f0101849:	53                   	push   %ebx
f010184a:	8b 55 08             	mov    0x8(%ebp),%edx
f010184d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101850:	eb 03                	jmp    f0101855 <strtol+0x11>
		s++;
f0101852:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0101855:	0f b6 02             	movzbl (%edx),%eax
f0101858:	3c 20                	cmp    $0x20,%al
f010185a:	74 f6                	je     f0101852 <strtol+0xe>
f010185c:	3c 09                	cmp    $0x9,%al
f010185e:	74 f2                	je     f0101852 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101860:	3c 2b                	cmp    $0x2b,%al
f0101862:	74 2a                	je     f010188e <strtol+0x4a>
	int neg = 0;
f0101864:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101869:	3c 2d                	cmp    $0x2d,%al
f010186b:	74 2b                	je     f0101898 <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010186d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101873:	75 0f                	jne    f0101884 <strtol+0x40>
f0101875:	80 3a 30             	cmpb   $0x30,(%edx)
f0101878:	74 28                	je     f01018a2 <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010187a:	85 db                	test   %ebx,%ebx
f010187c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101881:	0f 44 d8             	cmove  %eax,%ebx
f0101884:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101889:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010188c:	eb 46                	jmp    f01018d4 <strtol+0x90>
		s++;
f010188e:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0101891:	bf 00 00 00 00       	mov    $0x0,%edi
f0101896:	eb d5                	jmp    f010186d <strtol+0x29>
		s++, neg = 1;
f0101898:	83 c2 01             	add    $0x1,%edx
f010189b:	bf 01 00 00 00       	mov    $0x1,%edi
f01018a0:	eb cb                	jmp    f010186d <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01018a2:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01018a6:	74 0e                	je     f01018b6 <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f01018a8:	85 db                	test   %ebx,%ebx
f01018aa:	75 d8                	jne    f0101884 <strtol+0x40>
		s++, base = 8;
f01018ac:	83 c2 01             	add    $0x1,%edx
f01018af:	bb 08 00 00 00       	mov    $0x8,%ebx
f01018b4:	eb ce                	jmp    f0101884 <strtol+0x40>
		s += 2, base = 16;
f01018b6:	83 c2 02             	add    $0x2,%edx
f01018b9:	bb 10 00 00 00       	mov    $0x10,%ebx
f01018be:	eb c4                	jmp    f0101884 <strtol+0x40>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f01018c0:	0f be c0             	movsbl %al,%eax
f01018c3:	83 e8 30             	sub    $0x30,%eax
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01018c6:	3b 45 10             	cmp    0x10(%ebp),%eax
f01018c9:	7d 3a                	jge    f0101905 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01018cb:	83 c2 01             	add    $0x1,%edx
f01018ce:	0f af 4d 10          	imul   0x10(%ebp),%ecx
f01018d2:	01 c1                	add    %eax,%ecx
		if (*s >= '0' && *s <= '9')
f01018d4:	0f b6 02             	movzbl (%edx),%eax
f01018d7:	8d 70 d0             	lea    -0x30(%eax),%esi
f01018da:	89 f3                	mov    %esi,%ebx
f01018dc:	80 fb 09             	cmp    $0x9,%bl
f01018df:	76 df                	jbe    f01018c0 <strtol+0x7c>
		else if (*s >= 'a' && *s <= 'z')
f01018e1:	8d 70 9f             	lea    -0x61(%eax),%esi
f01018e4:	89 f3                	mov    %esi,%ebx
f01018e6:	80 fb 19             	cmp    $0x19,%bl
f01018e9:	77 08                	ja     f01018f3 <strtol+0xaf>
			dig = *s - 'a' + 10;
f01018eb:	0f be c0             	movsbl %al,%eax
f01018ee:	83 e8 57             	sub    $0x57,%eax
f01018f1:	eb d3                	jmp    f01018c6 <strtol+0x82>
		else if (*s >= 'A' && *s <= 'Z')
f01018f3:	8d 70 bf             	lea    -0x41(%eax),%esi
f01018f6:	89 f3                	mov    %esi,%ebx
f01018f8:	80 fb 19             	cmp    $0x19,%bl
f01018fb:	77 08                	ja     f0101905 <strtol+0xc1>
			dig = *s - 'A' + 10;
f01018fd:	0f be c0             	movsbl %al,%eax
f0101900:	83 e8 37             	sub    $0x37,%eax
f0101903:	eb c1                	jmp    f01018c6 <strtol+0x82>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101905:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101909:	74 05                	je     f0101910 <strtol+0xcc>
		*endptr = (char *) s;
f010190b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010190e:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0101910:	89 c8                	mov    %ecx,%eax
f0101912:	f7 d8                	neg    %eax
f0101914:	85 ff                	test   %edi,%edi
f0101916:	0f 45 c8             	cmovne %eax,%ecx
}
f0101919:	89 c8                	mov    %ecx,%eax
f010191b:	5b                   	pop    %ebx
f010191c:	5e                   	pop    %esi
f010191d:	5f                   	pop    %edi
f010191e:	5d                   	pop    %ebp
f010191f:	c3                   	ret    

f0101920 <__udivdi3>:
f0101920:	f3 0f 1e fb          	endbr32 
f0101924:	55                   	push   %ebp
f0101925:	57                   	push   %edi
f0101926:	56                   	push   %esi
f0101927:	53                   	push   %ebx
f0101928:	83 ec 1c             	sub    $0x1c,%esp
f010192b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010192f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0101933:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101937:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010193b:	85 d2                	test   %edx,%edx
f010193d:	75 19                	jne    f0101958 <__udivdi3+0x38>
f010193f:	39 f3                	cmp    %esi,%ebx
f0101941:	76 4d                	jbe    f0101990 <__udivdi3+0x70>
f0101943:	31 ff                	xor    %edi,%edi
f0101945:	89 e8                	mov    %ebp,%eax
f0101947:	89 f2                	mov    %esi,%edx
f0101949:	f7 f3                	div    %ebx
f010194b:	89 fa                	mov    %edi,%edx
f010194d:	83 c4 1c             	add    $0x1c,%esp
f0101950:	5b                   	pop    %ebx
f0101951:	5e                   	pop    %esi
f0101952:	5f                   	pop    %edi
f0101953:	5d                   	pop    %ebp
f0101954:	c3                   	ret    
f0101955:	8d 76 00             	lea    0x0(%esi),%esi
f0101958:	39 f2                	cmp    %esi,%edx
f010195a:	76 14                	jbe    f0101970 <__udivdi3+0x50>
f010195c:	31 ff                	xor    %edi,%edi
f010195e:	31 c0                	xor    %eax,%eax
f0101960:	89 fa                	mov    %edi,%edx
f0101962:	83 c4 1c             	add    $0x1c,%esp
f0101965:	5b                   	pop    %ebx
f0101966:	5e                   	pop    %esi
f0101967:	5f                   	pop    %edi
f0101968:	5d                   	pop    %ebp
f0101969:	c3                   	ret    
f010196a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101970:	0f bd fa             	bsr    %edx,%edi
f0101973:	83 f7 1f             	xor    $0x1f,%edi
f0101976:	75 48                	jne    f01019c0 <__udivdi3+0xa0>
f0101978:	39 f2                	cmp    %esi,%edx
f010197a:	72 06                	jb     f0101982 <__udivdi3+0x62>
f010197c:	31 c0                	xor    %eax,%eax
f010197e:	39 eb                	cmp    %ebp,%ebx
f0101980:	77 de                	ja     f0101960 <__udivdi3+0x40>
f0101982:	b8 01 00 00 00       	mov    $0x1,%eax
f0101987:	eb d7                	jmp    f0101960 <__udivdi3+0x40>
f0101989:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101990:	89 d9                	mov    %ebx,%ecx
f0101992:	85 db                	test   %ebx,%ebx
f0101994:	75 0b                	jne    f01019a1 <__udivdi3+0x81>
f0101996:	b8 01 00 00 00       	mov    $0x1,%eax
f010199b:	31 d2                	xor    %edx,%edx
f010199d:	f7 f3                	div    %ebx
f010199f:	89 c1                	mov    %eax,%ecx
f01019a1:	31 d2                	xor    %edx,%edx
f01019a3:	89 f0                	mov    %esi,%eax
f01019a5:	f7 f1                	div    %ecx
f01019a7:	89 c6                	mov    %eax,%esi
f01019a9:	89 e8                	mov    %ebp,%eax
f01019ab:	89 f7                	mov    %esi,%edi
f01019ad:	f7 f1                	div    %ecx
f01019af:	89 fa                	mov    %edi,%edx
f01019b1:	83 c4 1c             	add    $0x1c,%esp
f01019b4:	5b                   	pop    %ebx
f01019b5:	5e                   	pop    %esi
f01019b6:	5f                   	pop    %edi
f01019b7:	5d                   	pop    %ebp
f01019b8:	c3                   	ret    
f01019b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019c0:	89 f9                	mov    %edi,%ecx
f01019c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01019c7:	29 f8                	sub    %edi,%eax
f01019c9:	d3 e2                	shl    %cl,%edx
f01019cb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01019cf:	89 c1                	mov    %eax,%ecx
f01019d1:	89 da                	mov    %ebx,%edx
f01019d3:	d3 ea                	shr    %cl,%edx
f01019d5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01019d9:	09 d1                	or     %edx,%ecx
f01019db:	89 f2                	mov    %esi,%edx
f01019dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01019e1:	89 f9                	mov    %edi,%ecx
f01019e3:	d3 e3                	shl    %cl,%ebx
f01019e5:	89 c1                	mov    %eax,%ecx
f01019e7:	d3 ea                	shr    %cl,%edx
f01019e9:	89 f9                	mov    %edi,%ecx
f01019eb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01019ef:	89 eb                	mov    %ebp,%ebx
f01019f1:	d3 e6                	shl    %cl,%esi
f01019f3:	89 c1                	mov    %eax,%ecx
f01019f5:	d3 eb                	shr    %cl,%ebx
f01019f7:	09 de                	or     %ebx,%esi
f01019f9:	89 f0                	mov    %esi,%eax
f01019fb:	f7 74 24 08          	divl   0x8(%esp)
f01019ff:	89 d6                	mov    %edx,%esi
f0101a01:	89 c3                	mov    %eax,%ebx
f0101a03:	f7 64 24 0c          	mull   0xc(%esp)
f0101a07:	39 d6                	cmp    %edx,%esi
f0101a09:	72 15                	jb     f0101a20 <__udivdi3+0x100>
f0101a0b:	89 f9                	mov    %edi,%ecx
f0101a0d:	d3 e5                	shl    %cl,%ebp
f0101a0f:	39 c5                	cmp    %eax,%ebp
f0101a11:	73 04                	jae    f0101a17 <__udivdi3+0xf7>
f0101a13:	39 d6                	cmp    %edx,%esi
f0101a15:	74 09                	je     f0101a20 <__udivdi3+0x100>
f0101a17:	89 d8                	mov    %ebx,%eax
f0101a19:	31 ff                	xor    %edi,%edi
f0101a1b:	e9 40 ff ff ff       	jmp    f0101960 <__udivdi3+0x40>
f0101a20:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101a23:	31 ff                	xor    %edi,%edi
f0101a25:	e9 36 ff ff ff       	jmp    f0101960 <__udivdi3+0x40>
f0101a2a:	66 90                	xchg   %ax,%ax
f0101a2c:	66 90                	xchg   %ax,%ax
f0101a2e:	66 90                	xchg   %ax,%ax

f0101a30 <__umoddi3>:
f0101a30:	f3 0f 1e fb          	endbr32 
f0101a34:	55                   	push   %ebp
f0101a35:	57                   	push   %edi
f0101a36:	56                   	push   %esi
f0101a37:	53                   	push   %ebx
f0101a38:	83 ec 1c             	sub    $0x1c,%esp
f0101a3b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101a3f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101a43:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101a47:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101a4b:	85 c0                	test   %eax,%eax
f0101a4d:	75 19                	jne    f0101a68 <__umoddi3+0x38>
f0101a4f:	39 df                	cmp    %ebx,%edi
f0101a51:	76 5d                	jbe    f0101ab0 <__umoddi3+0x80>
f0101a53:	89 f0                	mov    %esi,%eax
f0101a55:	89 da                	mov    %ebx,%edx
f0101a57:	f7 f7                	div    %edi
f0101a59:	89 d0                	mov    %edx,%eax
f0101a5b:	31 d2                	xor    %edx,%edx
f0101a5d:	83 c4 1c             	add    $0x1c,%esp
f0101a60:	5b                   	pop    %ebx
f0101a61:	5e                   	pop    %esi
f0101a62:	5f                   	pop    %edi
f0101a63:	5d                   	pop    %ebp
f0101a64:	c3                   	ret    
f0101a65:	8d 76 00             	lea    0x0(%esi),%esi
f0101a68:	89 f2                	mov    %esi,%edx
f0101a6a:	39 d8                	cmp    %ebx,%eax
f0101a6c:	76 12                	jbe    f0101a80 <__umoddi3+0x50>
f0101a6e:	89 f0                	mov    %esi,%eax
f0101a70:	89 da                	mov    %ebx,%edx
f0101a72:	83 c4 1c             	add    $0x1c,%esp
f0101a75:	5b                   	pop    %ebx
f0101a76:	5e                   	pop    %esi
f0101a77:	5f                   	pop    %edi
f0101a78:	5d                   	pop    %ebp
f0101a79:	c3                   	ret    
f0101a7a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a80:	0f bd e8             	bsr    %eax,%ebp
f0101a83:	83 f5 1f             	xor    $0x1f,%ebp
f0101a86:	75 50                	jne    f0101ad8 <__umoddi3+0xa8>
f0101a88:	39 d8                	cmp    %ebx,%eax
f0101a8a:	0f 82 e0 00 00 00    	jb     f0101b70 <__umoddi3+0x140>
f0101a90:	89 d9                	mov    %ebx,%ecx
f0101a92:	39 f7                	cmp    %esi,%edi
f0101a94:	0f 86 d6 00 00 00    	jbe    f0101b70 <__umoddi3+0x140>
f0101a9a:	89 d0                	mov    %edx,%eax
f0101a9c:	89 ca                	mov    %ecx,%edx
f0101a9e:	83 c4 1c             	add    $0x1c,%esp
f0101aa1:	5b                   	pop    %ebx
f0101aa2:	5e                   	pop    %esi
f0101aa3:	5f                   	pop    %edi
f0101aa4:	5d                   	pop    %ebp
f0101aa5:	c3                   	ret    
f0101aa6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101aad:	8d 76 00             	lea    0x0(%esi),%esi
f0101ab0:	89 fd                	mov    %edi,%ebp
f0101ab2:	85 ff                	test   %edi,%edi
f0101ab4:	75 0b                	jne    f0101ac1 <__umoddi3+0x91>
f0101ab6:	b8 01 00 00 00       	mov    $0x1,%eax
f0101abb:	31 d2                	xor    %edx,%edx
f0101abd:	f7 f7                	div    %edi
f0101abf:	89 c5                	mov    %eax,%ebp
f0101ac1:	89 d8                	mov    %ebx,%eax
f0101ac3:	31 d2                	xor    %edx,%edx
f0101ac5:	f7 f5                	div    %ebp
f0101ac7:	89 f0                	mov    %esi,%eax
f0101ac9:	f7 f5                	div    %ebp
f0101acb:	89 d0                	mov    %edx,%eax
f0101acd:	31 d2                	xor    %edx,%edx
f0101acf:	eb 8c                	jmp    f0101a5d <__umoddi3+0x2d>
f0101ad1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ad8:	89 e9                	mov    %ebp,%ecx
f0101ada:	ba 20 00 00 00       	mov    $0x20,%edx
f0101adf:	29 ea                	sub    %ebp,%edx
f0101ae1:	d3 e0                	shl    %cl,%eax
f0101ae3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101ae7:	89 d1                	mov    %edx,%ecx
f0101ae9:	89 f8                	mov    %edi,%eax
f0101aeb:	d3 e8                	shr    %cl,%eax
f0101aed:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101af1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101af5:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101af9:	09 c1                	or     %eax,%ecx
f0101afb:	89 d8                	mov    %ebx,%eax
f0101afd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101b01:	89 e9                	mov    %ebp,%ecx
f0101b03:	d3 e7                	shl    %cl,%edi
f0101b05:	89 d1                	mov    %edx,%ecx
f0101b07:	d3 e8                	shr    %cl,%eax
f0101b09:	89 e9                	mov    %ebp,%ecx
f0101b0b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101b0f:	d3 e3                	shl    %cl,%ebx
f0101b11:	89 c7                	mov    %eax,%edi
f0101b13:	89 d1                	mov    %edx,%ecx
f0101b15:	89 f0                	mov    %esi,%eax
f0101b17:	d3 e8                	shr    %cl,%eax
f0101b19:	89 e9                	mov    %ebp,%ecx
f0101b1b:	89 fa                	mov    %edi,%edx
f0101b1d:	d3 e6                	shl    %cl,%esi
f0101b1f:	09 d8                	or     %ebx,%eax
f0101b21:	f7 74 24 08          	divl   0x8(%esp)
f0101b25:	89 d1                	mov    %edx,%ecx
f0101b27:	89 f3                	mov    %esi,%ebx
f0101b29:	f7 64 24 0c          	mull   0xc(%esp)
f0101b2d:	89 c6                	mov    %eax,%esi
f0101b2f:	89 d7                	mov    %edx,%edi
f0101b31:	39 d1                	cmp    %edx,%ecx
f0101b33:	72 06                	jb     f0101b3b <__umoddi3+0x10b>
f0101b35:	75 10                	jne    f0101b47 <__umoddi3+0x117>
f0101b37:	39 c3                	cmp    %eax,%ebx
f0101b39:	73 0c                	jae    f0101b47 <__umoddi3+0x117>
f0101b3b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f0101b3f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0101b43:	89 d7                	mov    %edx,%edi
f0101b45:	89 c6                	mov    %eax,%esi
f0101b47:	89 ca                	mov    %ecx,%edx
f0101b49:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b4e:	29 f3                	sub    %esi,%ebx
f0101b50:	19 fa                	sbb    %edi,%edx
f0101b52:	89 d0                	mov    %edx,%eax
f0101b54:	d3 e0                	shl    %cl,%eax
f0101b56:	89 e9                	mov    %ebp,%ecx
f0101b58:	d3 eb                	shr    %cl,%ebx
f0101b5a:	d3 ea                	shr    %cl,%edx
f0101b5c:	09 d8                	or     %ebx,%eax
f0101b5e:	83 c4 1c             	add    $0x1c,%esp
f0101b61:	5b                   	pop    %ebx
f0101b62:	5e                   	pop    %esi
f0101b63:	5f                   	pop    %edi
f0101b64:	5d                   	pop    %ebp
f0101b65:	c3                   	ret    
f0101b66:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b6d:	8d 76 00             	lea    0x0(%esi),%esi
f0101b70:	89 d9                	mov    %ebx,%ecx
f0101b72:	89 f2                	mov    %esi,%edx
f0101b74:	29 fa                	sub    %edi,%edx
f0101b76:	19 c1                	sbb    %eax,%ecx
f0101b78:	e9 1d ff ff ff       	jmp    f0101a9a <__umoddi3+0x6a>
