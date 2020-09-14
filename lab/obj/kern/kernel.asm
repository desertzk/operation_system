
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
f0100057:	8d 83 98 08 ff ff    	lea    -0xf768(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 d0 0a 00 00       	call   f0100b33 <cprintf>
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
f010007d:	8d 83 b4 08 ff ff    	lea    -0xf74c(%ebx),%eax
f0100083:	50                   	push   %eax
f0100084:	e8 aa 0a 00 00       	call   f0100b33 <cprintf>
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
f010009c:	e8 f8 07 00 00       	call   f0100899 <mon_backtrace>
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
f01000ca:	e8 73 16 00 00       	call   f0101742 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 3f 05 00 00       	call   f0100613 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 cf 08 ff ff    	lea    -0xf731(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 4b 0a 00 00       	call   f0100b33 <cprintf>

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
f01000fc:	e8 79 08 00 00       	call   f010097a <monitor>
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
f0100124:	e8 51 08 00 00       	call   f010097a <monitor>
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
f0100145:	8d 83 ea 08 ff ff    	lea    -0xf716(%ebx),%eax
f010014b:	50                   	push   %eax
f010014c:	e8 e2 09 00 00       	call   f0100b33 <cprintf>
	vcprintf(fmt, ap);
f0100151:	83 c4 08             	add    $0x8,%esp
f0100154:	56                   	push   %esi
f0100155:	ff 75 10             	pushl  0x10(%ebp)
f0100158:	e8 9f 09 00 00       	call   f0100afc <vcprintf>
	cprintf("\n");
f010015d:	8d 83 26 09 ff ff    	lea    -0xf6da(%ebx),%eax
f0100163:	89 04 24             	mov    %eax,(%esp)
f0100166:	e8 c8 09 00 00       	call   f0100b33 <cprintf>
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
f010018c:	8d 83 02 09 ff ff    	lea    -0xf6fe(%ebx),%eax
f0100192:	50                   	push   %eax
f0100193:	e8 9b 09 00 00       	call   f0100b33 <cprintf>
	vcprintf(fmt, ap);
f0100198:	83 c4 08             	add    $0x8,%esp
f010019b:	56                   	push   %esi
f010019c:	ff 75 10             	pushl  0x10(%ebp)
f010019f:	e8 58 09 00 00       	call   f0100afc <vcprintf>
	cprintf("\n");
f01001a4:	8d 83 26 09 ff ff    	lea    -0xf6da(%ebx),%eax
f01001aa:	89 04 24             	mov    %eax,(%esp)
f01001ad:	e8 81 09 00 00       	call   f0100b33 <cprintf>
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
f0100290:	0f b6 84 13 58 0a ff 	movzbl -0xf5a8(%ebx,%edx,1),%eax
f0100297:	ff 
f0100298:	0b 83 78 1d 00 00    	or     0x1d78(%ebx),%eax
	shift ^= togglecode[data];
f010029e:	0f b6 8c 13 58 09 ff 	movzbl -0xf6a8(%ebx,%edx,1),%ecx
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
f01002fb:	0f b6 84 13 58 0a ff 	movzbl -0xf5a8(%ebx,%edx,1),%eax
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
f0100337:	8d 83 1c 09 ff ff    	lea    -0xf6e4(%ebx),%eax
f010033d:	50                   	push   %eax
f010033e:	e8 f0 07 00 00       	call   f0100b33 <cprintf>
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
f0100548:	e8 3d 12 00 00       	call   f010178a <memmove>
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
f0100721:	8d 83 28 09 ff ff    	lea    -0xf6d8(%ebx),%eax
f0100727:	50                   	push   %eax
f0100728:	e8 06 04 00 00       	call   f0100b33 <cprintf>
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
f0100774:	8d 83 58 0b ff ff    	lea    -0xf4a8(%ebx),%eax
f010077a:	50                   	push   %eax
f010077b:	8d 83 76 0b ff ff    	lea    -0xf48a(%ebx),%eax
f0100781:	50                   	push   %eax
f0100782:	8d b3 7b 0b ff ff    	lea    -0xf485(%ebx),%esi
f0100788:	56                   	push   %esi
f0100789:	e8 a5 03 00 00       	call   f0100b33 <cprintf>
f010078e:	83 c4 0c             	add    $0xc,%esp
f0100791:	8d 83 84 0b ff ff    	lea    -0xf47c(%ebx),%eax
f0100797:	50                   	push   %eax
f0100798:	8d 83 8c 0b ff ff    	lea    -0xf474(%ebx),%eax
f010079e:	50                   	push   %eax
f010079f:	56                   	push   %esi
f01007a0:	e8 8e 03 00 00       	call   f0100b33 <cprintf>
f01007a5:	83 c4 0c             	add    $0xc,%esp
f01007a8:	8d 83 44 0c ff ff    	lea    -0xf3bc(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	8d 83 96 0b ff ff    	lea    -0xf46a(%ebx),%eax
f01007b5:	50                   	push   %eax
f01007b6:	56                   	push   %esi
f01007b7:	e8 77 03 00 00       	call   f0100b33 <cprintf>
	return 0;
}
f01007bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007c4:	5b                   	pop    %ebx
f01007c5:	5e                   	pop    %esi
f01007c6:	5d                   	pop    %ebp
f01007c7:	c3                   	ret    

f01007c8 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007c8:	55                   	push   %ebp
f01007c9:	89 e5                	mov    %esp,%ebp
f01007cb:	57                   	push   %edi
f01007cc:	56                   	push   %esi
f01007cd:	53                   	push   %ebx
f01007ce:	83 ec 18             	sub    $0x18,%esp
f01007d1:	e8 e6 f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01007d6:	81 c3 32 0b 01 00    	add    $0x10b32,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007dc:	8d 83 9f 0b ff ff    	lea    -0xf461(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 4b 03 00 00       	call   f0100b33 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e8:	83 c4 08             	add    $0x8,%esp
f01007eb:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007f1:	8d 83 6c 0c ff ff    	lea    -0xf394(%ebx),%eax
f01007f7:	50                   	push   %eax
f01007f8:	e8 36 03 00 00       	call   f0100b33 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007fd:	83 c4 0c             	add    $0xc,%esp
f0100800:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100806:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f010080c:	50                   	push   %eax
f010080d:	57                   	push   %edi
f010080e:	8d 83 94 0c ff ff    	lea    -0xf36c(%ebx),%eax
f0100814:	50                   	push   %eax
f0100815:	e8 19 03 00 00       	call   f0100b33 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010081a:	83 c4 0c             	add    $0xc,%esp
f010081d:	c7 c0 9d 1b 10 f0    	mov    $0xf0101b9d,%eax
f0100823:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100829:	52                   	push   %edx
f010082a:	50                   	push   %eax
f010082b:	8d 83 b8 0c ff ff    	lea    -0xf348(%ebx),%eax
f0100831:	50                   	push   %eax
f0100832:	e8 fc 02 00 00       	call   f0100b33 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100837:	83 c4 0c             	add    $0xc,%esp
f010083a:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f0100840:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100846:	52                   	push   %edx
f0100847:	50                   	push   %eax
f0100848:	8d 83 dc 0c ff ff    	lea    -0xf324(%ebx),%eax
f010084e:	50                   	push   %eax
f010084f:	e8 df 02 00 00       	call   f0100b33 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100854:	83 c4 0c             	add    $0xc,%esp
f0100857:	c7 c6 c0 36 11 f0    	mov    $0xf01136c0,%esi
f010085d:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100863:	50                   	push   %eax
f0100864:	56                   	push   %esi
f0100865:	8d 83 00 0d ff ff    	lea    -0xf300(%ebx),%eax
f010086b:	50                   	push   %eax
f010086c:	e8 c2 02 00 00       	call   f0100b33 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100871:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100874:	29 fe                	sub    %edi,%esi
f0100876:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010087c:	c1 fe 0a             	sar    $0xa,%esi
f010087f:	56                   	push   %esi
f0100880:	8d 83 24 0d ff ff    	lea    -0xf2dc(%ebx),%eax
f0100886:	50                   	push   %eax
f0100887:	e8 a7 02 00 00       	call   f0100b33 <cprintf>
	return 0;
}
f010088c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100891:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100894:	5b                   	pop    %ebx
f0100895:	5e                   	pop    %esi
f0100896:	5f                   	pop    %edi
f0100897:	5d                   	pop    %ebp
f0100898:	c3                   	ret    

f0100899 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100899:	55                   	push   %ebp
f010089a:	89 e5                	mov    %esp,%ebp
f010089c:	57                   	push   %edi
f010089d:	56                   	push   %esi
f010089e:	53                   	push   %ebx
f010089f:	83 ec 48             	sub    $0x48,%esp
f01008a2:	e8 15 f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01008a7:	81 c3 61 0a 01 00    	add    $0x10a61,%ebx
	// Your code here.
	cprintf("mon_backtrace:\n");
f01008ad:	8d 83 b8 0b ff ff    	lea    -0xf448(%ebx),%eax
f01008b3:	50                   	push   %eax
f01008b4:	e8 7a 02 00 00       	call   f0100b33 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008b9:	89 e8                	mov    %ebp,%eax
    uint32_t* ebp = (uint32_t*) read_ebp();
f01008bb:	89 c7                	mov    %eax,%edi
    cprintf("Stack backtrace:\n");
f01008bd:	8d 83 c8 0b ff ff    	lea    -0xf438(%ebx),%eax
f01008c3:	89 04 24             	mov    %eax,(%esp)
f01008c6:	e8 68 02 00 00       	call   f0100b33 <cprintf>
    while (ebp) {
f01008cb:	83 c4 10             	add    $0x10,%esp
      uint32_t eip = ebp[1];
      cprintf("ebp %x  eip %x  args", ebp, eip);
f01008ce:	8d 83 da 0b ff ff    	lea    -0xf426(%ebx),%eax
f01008d4:	89 45 b8             	mov    %eax,-0x48(%ebp)
      int i;
      for (i = 2; i <= 6; ++i)
        cprintf(" %08.x", ebp[i]);
f01008d7:	8d 83 ef 0b ff ff    	lea    -0xf411(%ebx),%eax
f01008dd:	89 45 c4             	mov    %eax,-0x3c(%ebp)
    while (ebp) {
f01008e0:	e9 80 00 00 00       	jmp    f0100965 <mon_backtrace+0xcc>
      uint32_t eip = ebp[1];
f01008e5:	8b 47 04             	mov    0x4(%edi),%eax
f01008e8:	89 45 c0             	mov    %eax,-0x40(%ebp)
      cprintf("ebp %x  eip %x  args", ebp, eip);
f01008eb:	83 ec 04             	sub    $0x4,%esp
f01008ee:	50                   	push   %eax
f01008ef:	57                   	push   %edi
f01008f0:	ff 75 b8             	pushl  -0x48(%ebp)
f01008f3:	e8 3b 02 00 00       	call   f0100b33 <cprintf>
f01008f8:	8d 77 08             	lea    0x8(%edi),%esi
f01008fb:	8d 47 1c             	lea    0x1c(%edi),%eax
f01008fe:	83 c4 10             	add    $0x10,%esp
f0100901:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0100904:	89 c7                	mov    %eax,%edi
        cprintf(" %08.x", ebp[i]);
f0100906:	83 ec 08             	sub    $0x8,%esp
f0100909:	ff 36                	pushl  (%esi)
f010090b:	ff 75 c4             	pushl  -0x3c(%ebp)
f010090e:	e8 20 02 00 00       	call   f0100b33 <cprintf>
      for (i = 2; i <= 6; ++i)
f0100913:	83 c6 04             	add    $0x4,%esi
f0100916:	83 c4 10             	add    $0x10,%esp
f0100919:	39 fe                	cmp    %edi,%esi
f010091b:	75 e9                	jne    f0100906 <mon_backtrace+0x6d>
      cprintf("\n");
f010091d:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0100920:	83 ec 0c             	sub    $0xc,%esp
f0100923:	8d 83 26 09 ff ff    	lea    -0xf6da(%ebx),%eax
f0100929:	50                   	push   %eax
f010092a:	e8 04 02 00 00       	call   f0100b33 <cprintf>
      struct Eipdebuginfo info;
      debuginfo_eip(eip, &info);
f010092f:	83 c4 08             	add    $0x8,%esp
f0100932:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100935:	50                   	push   %eax
f0100936:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0100939:	56                   	push   %esi
f010093a:	e8 fd 02 00 00       	call   f0100c3c <debuginfo_eip>
      cprintf("\t%s:%d: %.*s+%d\n", 
f010093f:	83 c4 08             	add    $0x8,%esp
f0100942:	89 f0                	mov    %esi,%eax
f0100944:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100947:	50                   	push   %eax
f0100948:	ff 75 d8             	pushl  -0x28(%ebp)
f010094b:	ff 75 dc             	pushl  -0x24(%ebp)
f010094e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100951:	ff 75 d0             	pushl  -0x30(%ebp)
f0100954:	8d 83 f6 0b ff ff    	lea    -0xf40a(%ebx),%eax
f010095a:	50                   	push   %eax
f010095b:	e8 d3 01 00 00       	call   f0100b33 <cprintf>
      info.eip_file, info.eip_line,
      info.eip_fn_namelen, info.eip_fn_name,
      eip-info.eip_fn_addr);
  //  kern/monitor.c:143: monitor+106
      ebp = (uint32_t*) *ebp;
f0100960:	8b 3f                	mov    (%edi),%edi
f0100962:	83 c4 20             	add    $0x20,%esp
    while (ebp) {
f0100965:	85 ff                	test   %edi,%edi
f0100967:	0f 85 78 ff ff ff    	jne    f01008e5 <mon_backtrace+0x4c>
    }
  return 0;

}
f010096d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100972:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100975:	5b                   	pop    %ebx
f0100976:	5e                   	pop    %esi
f0100977:	5f                   	pop    %edi
f0100978:	5d                   	pop    %ebp
f0100979:	c3                   	ret    

f010097a <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010097a:	55                   	push   %ebp
f010097b:	89 e5                	mov    %esp,%ebp
f010097d:	57                   	push   %edi
f010097e:	56                   	push   %esi
f010097f:	53                   	push   %ebx
f0100980:	83 ec 68             	sub    $0x68,%esp
f0100983:	e8 34 f8 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100988:	81 c3 80 09 01 00    	add    $0x10980,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010098e:	8d 83 50 0d ff ff    	lea    -0xf2b0(%ebx),%eax
f0100994:	50                   	push   %eax
f0100995:	e8 99 01 00 00       	call   f0100b33 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010099a:	8d 83 74 0d ff ff    	lea    -0xf28c(%ebx),%eax
f01009a0:	89 04 24             	mov    %eax,(%esp)
f01009a3:	e8 8b 01 00 00       	call   f0100b33 <cprintf>
f01009a8:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01009ab:	8d bb 0b 0c ff ff    	lea    -0xf3f5(%ebx),%edi
f01009b1:	eb 4a                	jmp    f01009fd <monitor+0x83>
f01009b3:	83 ec 08             	sub    $0x8,%esp
f01009b6:	0f be c0             	movsbl %al,%eax
f01009b9:	50                   	push   %eax
f01009ba:	57                   	push   %edi
f01009bb:	e8 43 0d 00 00       	call   f0101703 <strchr>
f01009c0:	83 c4 10             	add    $0x10,%esp
f01009c3:	85 c0                	test   %eax,%eax
f01009c5:	74 08                	je     f01009cf <monitor+0x55>
			*buf++ = 0;
f01009c7:	c6 06 00             	movb   $0x0,(%esi)
f01009ca:	8d 76 01             	lea    0x1(%esi),%esi
f01009cd:	eb 76                	jmp    f0100a45 <monitor+0xcb>
		if (*buf == 0)
f01009cf:	80 3e 00             	cmpb   $0x0,(%esi)
f01009d2:	74 7c                	je     f0100a50 <monitor+0xd6>
		if (argc == MAXARGS-1) {
f01009d4:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009d8:	74 0f                	je     f01009e9 <monitor+0x6f>
		argv[argc++] = buf;
f01009da:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009dd:	8d 48 01             	lea    0x1(%eax),%ecx
f01009e0:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009e3:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01009e7:	eb 41                	jmp    f0100a2a <monitor+0xb0>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009e9:	83 ec 08             	sub    $0x8,%esp
f01009ec:	6a 10                	push   $0x10
f01009ee:	8d 83 10 0c ff ff    	lea    -0xf3f0(%ebx),%eax
f01009f4:	50                   	push   %eax
f01009f5:	e8 39 01 00 00       	call   f0100b33 <cprintf>
			return 0;
f01009fa:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009fd:	8d 83 07 0c ff ff    	lea    -0xf3f9(%ebx),%eax
f0100a03:	89 c6                	mov    %eax,%esi
f0100a05:	83 ec 0c             	sub    $0xc,%esp
f0100a08:	56                   	push   %esi
f0100a09:	e8 a2 0a 00 00       	call   f01014b0 <readline>
		if (buf != NULL)
f0100a0e:	83 c4 10             	add    $0x10,%esp
f0100a11:	85 c0                	test   %eax,%eax
f0100a13:	74 f0                	je     f0100a05 <monitor+0x8b>
	argv[argc] = 0;
f0100a15:	89 c6                	mov    %eax,%esi
f0100a17:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a1e:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100a25:	eb 1e                	jmp    f0100a45 <monitor+0xcb>
			buf++;
f0100a27:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a2a:	0f b6 06             	movzbl (%esi),%eax
f0100a2d:	84 c0                	test   %al,%al
f0100a2f:	74 14                	je     f0100a45 <monitor+0xcb>
f0100a31:	83 ec 08             	sub    $0x8,%esp
f0100a34:	0f be c0             	movsbl %al,%eax
f0100a37:	50                   	push   %eax
f0100a38:	57                   	push   %edi
f0100a39:	e8 c5 0c 00 00       	call   f0101703 <strchr>
f0100a3e:	83 c4 10             	add    $0x10,%esp
f0100a41:	85 c0                	test   %eax,%eax
f0100a43:	74 e2                	je     f0100a27 <monitor+0xad>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a45:	0f b6 06             	movzbl (%esi),%eax
f0100a48:	84 c0                	test   %al,%al
f0100a4a:	0f 85 63 ff ff ff    	jne    f01009b3 <monitor+0x39>
	argv[argc] = 0;
f0100a50:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a53:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a5a:	00 
	if (argc == 0)
f0100a5b:	85 c0                	test   %eax,%eax
f0100a5d:	74 9e                	je     f01009fd <monitor+0x83>
f0100a5f:	8d b3 18 1d 00 00    	lea    0x1d18(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a65:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a6a:	89 7d a0             	mov    %edi,-0x60(%ebp)
f0100a6d:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a6f:	83 ec 08             	sub    $0x8,%esp
f0100a72:	ff 36                	pushl  (%esi)
f0100a74:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a77:	e8 27 0c 00 00       	call   f01016a3 <strcmp>
f0100a7c:	83 c4 10             	add    $0x10,%esp
f0100a7f:	85 c0                	test   %eax,%eax
f0100a81:	74 28                	je     f0100aab <monitor+0x131>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a83:	83 c7 01             	add    $0x1,%edi
f0100a86:	83 c6 0c             	add    $0xc,%esi
f0100a89:	83 ff 03             	cmp    $0x3,%edi
f0100a8c:	75 e1                	jne    f0100a6f <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a8e:	8b 7d a0             	mov    -0x60(%ebp),%edi
f0100a91:	83 ec 08             	sub    $0x8,%esp
f0100a94:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a97:	8d 83 2d 0c ff ff    	lea    -0xf3d3(%ebx),%eax
f0100a9d:	50                   	push   %eax
f0100a9e:	e8 90 00 00 00       	call   f0100b33 <cprintf>
	return 0;
f0100aa3:	83 c4 10             	add    $0x10,%esp
f0100aa6:	e9 52 ff ff ff       	jmp    f01009fd <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100aab:	89 f8                	mov    %edi,%eax
f0100aad:	8b 7d a0             	mov    -0x60(%ebp),%edi
f0100ab0:	83 ec 04             	sub    $0x4,%esp
f0100ab3:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100ab6:	ff 75 08             	pushl  0x8(%ebp)
f0100ab9:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100abc:	52                   	push   %edx
f0100abd:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100ac0:	ff 94 83 20 1d 00 00 	call   *0x1d20(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ac7:	83 c4 10             	add    $0x10,%esp
f0100aca:	85 c0                	test   %eax,%eax
f0100acc:	0f 89 2b ff ff ff    	jns    f01009fd <monitor+0x83>
				break;
	}
}
f0100ad2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ad5:	5b                   	pop    %ebx
f0100ad6:	5e                   	pop    %esi
f0100ad7:	5f                   	pop    %edi
f0100ad8:	5d                   	pop    %ebp
f0100ad9:	c3                   	ret    

f0100ada <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100ada:	55                   	push   %ebp
f0100adb:	89 e5                	mov    %esp,%ebp
f0100add:	53                   	push   %ebx
f0100ade:	83 ec 10             	sub    $0x10,%esp
f0100ae1:	e8 d6 f6 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100ae6:	81 c3 22 08 01 00    	add    $0x10822,%ebx
	cputchar(ch);
f0100aec:	ff 75 08             	pushl  0x8(%ebp)
f0100aef:	e8 3e fc ff ff       	call   f0100732 <cputchar>
	*cnt++;
}
f0100af4:	83 c4 10             	add    $0x10,%esp
f0100af7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100afa:	c9                   	leave  
f0100afb:	c3                   	ret    

f0100afc <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100afc:	55                   	push   %ebp
f0100afd:	89 e5                	mov    %esp,%ebp
f0100aff:	53                   	push   %ebx
f0100b00:	83 ec 14             	sub    $0x14,%esp
f0100b03:	e8 b4 f6 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100b08:	81 c3 00 08 01 00    	add    $0x10800,%ebx
	int cnt = 0;
f0100b0e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100b15:	ff 75 0c             	pushl  0xc(%ebp)
f0100b18:	ff 75 08             	pushl  0x8(%ebp)
f0100b1b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100b1e:	50                   	push   %eax
f0100b1f:	8d 83 d2 f7 fe ff    	lea    -0x1082e(%ebx),%eax
f0100b25:	50                   	push   %eax
f0100b26:	e8 66 04 00 00       	call   f0100f91 <vprintfmt>
	return cnt;
}
f0100b2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b2e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b31:	c9                   	leave  
f0100b32:	c3                   	ret    

f0100b33 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b33:	55                   	push   %ebp
f0100b34:	89 e5                	mov    %esp,%ebp
f0100b36:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b39:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b3c:	50                   	push   %eax
f0100b3d:	ff 75 08             	pushl  0x8(%ebp)
f0100b40:	e8 b7 ff ff ff       	call   f0100afc <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b45:	c9                   	leave  
f0100b46:	c3                   	ret    

f0100b47 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b47:	55                   	push   %ebp
f0100b48:	89 e5                	mov    %esp,%ebp
f0100b4a:	57                   	push   %edi
f0100b4b:	56                   	push   %esi
f0100b4c:	53                   	push   %ebx
f0100b4d:	83 ec 14             	sub    $0x14,%esp
f0100b50:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100b53:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100b56:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100b59:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100b5c:	8b 1a                	mov    (%edx),%ebx
f0100b5e:	8b 01                	mov    (%ecx),%eax
f0100b60:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b63:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100b6a:	eb 2f                	jmp    f0100b9b <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100b6c:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b6f:	39 c3                	cmp    %eax,%ebx
f0100b71:	7f 4e                	jg     f0100bc1 <stab_binsearch+0x7a>
f0100b73:	0f b6 0a             	movzbl (%edx),%ecx
f0100b76:	83 ea 0c             	sub    $0xc,%edx
f0100b79:	39 f1                	cmp    %esi,%ecx
f0100b7b:	75 ef                	jne    f0100b6c <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b7d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b80:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b83:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b87:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b8a:	73 3a                	jae    f0100bc6 <stab_binsearch+0x7f>
			*region_left = m;
f0100b8c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100b8f:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100b91:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0100b94:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100b9b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100b9e:	7f 53                	jg     f0100bf3 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0100ba0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ba3:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0100ba6:	89 d0                	mov    %edx,%eax
f0100ba8:	c1 e8 1f             	shr    $0x1f,%eax
f0100bab:	01 d0                	add    %edx,%eax
f0100bad:	89 c7                	mov    %eax,%edi
f0100baf:	d1 ff                	sar    %edi
f0100bb1:	83 e0 fe             	and    $0xfffffffe,%eax
f0100bb4:	01 f8                	add    %edi,%eax
f0100bb6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100bb9:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100bbd:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0100bbf:	eb ae                	jmp    f0100b6f <stab_binsearch+0x28>
			l = true_m + 1;
f0100bc1:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100bc4:	eb d5                	jmp    f0100b9b <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100bc6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100bc9:	76 14                	jbe    f0100bdf <stab_binsearch+0x98>
			*region_right = m - 1;
f0100bcb:	83 e8 01             	sub    $0x1,%eax
f0100bce:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100bd1:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100bd4:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0100bd6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100bdd:	eb bc                	jmp    f0100b9b <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100bdf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100be2:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0100be4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100be8:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0100bea:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100bf1:	eb a8                	jmp    f0100b9b <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100bf3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100bf7:	75 15                	jne    f0100c0e <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0100bf9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bfc:	8b 00                	mov    (%eax),%eax
f0100bfe:	83 e8 01             	sub    $0x1,%eax
f0100c01:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100c04:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100c06:	83 c4 14             	add    $0x14,%esp
f0100c09:	5b                   	pop    %ebx
f0100c0a:	5e                   	pop    %esi
f0100c0b:	5f                   	pop    %edi
f0100c0c:	5d                   	pop    %ebp
f0100c0d:	c3                   	ret    
		for (l = *region_right;
f0100c0e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c11:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100c13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c16:	8b 0f                	mov    (%edi),%ecx
f0100c18:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c1b:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100c1e:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0100c22:	39 c1                	cmp    %eax,%ecx
f0100c24:	7d 0f                	jge    f0100c35 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0100c26:	0f b6 1a             	movzbl (%edx),%ebx
f0100c29:	83 ea 0c             	sub    $0xc,%edx
f0100c2c:	39 f3                	cmp    %esi,%ebx
f0100c2e:	74 05                	je     f0100c35 <stab_binsearch+0xee>
		     l--)
f0100c30:	83 e8 01             	sub    $0x1,%eax
f0100c33:	eb ed                	jmp    f0100c22 <stab_binsearch+0xdb>
		*region_left = l;
f0100c35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c38:	89 07                	mov    %eax,(%edi)
}
f0100c3a:	eb ca                	jmp    f0100c06 <stab_binsearch+0xbf>

f0100c3c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c3c:	55                   	push   %ebp
f0100c3d:	89 e5                	mov    %esp,%ebp
f0100c3f:	57                   	push   %edi
f0100c40:	56                   	push   %esi
f0100c41:	53                   	push   %ebx
f0100c42:	83 ec 3c             	sub    $0x3c,%esp
f0100c45:	e8 72 f5 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100c4a:	81 c3 be 06 01 00    	add    $0x106be,%ebx
f0100c50:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100c53:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c56:	8d 83 99 0d ff ff    	lea    -0xf267(%ebx),%eax
f0100c5c:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0100c5e:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100c65:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100c68:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100c6f:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100c72:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c79:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100c7f:	0f 86 3c 01 00 00    	jbe    f0100dc1 <debuginfo_eip+0x185>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c85:	c7 c0 35 5c 10 f0    	mov    $0xf0105c35,%eax
f0100c8b:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f0100c91:	0f 86 e0 01 00 00    	jbe    f0100e77 <debuginfo_eip+0x23b>
f0100c97:	c7 c0 75 72 10 f0    	mov    $0xf0107275,%eax
f0100c9d:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100ca1:	0f 85 d7 01 00 00    	jne    f0100e7e <debuginfo_eip+0x242>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ca7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100cae:	c7 c0 bc 22 10 f0    	mov    $0xf01022bc,%eax
f0100cb4:	c7 c2 34 5c 10 f0    	mov    $0xf0105c34,%edx
f0100cba:	29 c2                	sub    %eax,%edx
f0100cbc:	c1 fa 02             	sar    $0x2,%edx
f0100cbf:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100cc5:	83 ea 01             	sub    $0x1,%edx
f0100cc8:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ccb:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100cce:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100cd1:	83 ec 08             	sub    $0x8,%esp
f0100cd4:	57                   	push   %edi
f0100cd5:	6a 64                	push   $0x64
f0100cd7:	e8 6b fe ff ff       	call   f0100b47 <stab_binsearch>
	if (lfile == 0)
f0100cdc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cdf:	83 c4 10             	add    $0x10,%esp
f0100ce2:	85 c0                	test   %eax,%eax
f0100ce4:	0f 84 9b 01 00 00    	je     f0100e85 <debuginfo_eip+0x249>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100cea:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ced:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cf0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100cf3:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100cf6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100cf9:	83 ec 08             	sub    $0x8,%esp
f0100cfc:	57                   	push   %edi
f0100cfd:	6a 24                	push   $0x24
f0100cff:	c7 c0 bc 22 10 f0    	mov    $0xf01022bc,%eax
f0100d05:	e8 3d fe ff ff       	call   f0100b47 <stab_binsearch>

	if (lfun <= rfun) {
f0100d0a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d0d:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100d10:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0100d13:	83 c4 10             	add    $0x10,%esp
f0100d16:	39 c8                	cmp    %ecx,%eax
f0100d18:	0f 8f be 00 00 00    	jg     f0100ddc <debuginfo_eip+0x1a0>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100d1e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d21:	c7 c1 bc 22 10 f0    	mov    $0xf01022bc,%ecx
f0100d27:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0100d2a:	8b 11                	mov    (%ecx),%edx
f0100d2c:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0100d2f:	c7 c2 75 72 10 f0    	mov    $0xf0107275,%edx
f0100d35:	81 ea 35 5c 10 f0    	sub    $0xf0105c35,%edx
f0100d3b:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0100d3e:	73 0c                	jae    f0100d4c <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d40:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0100d43:	81 c2 35 5c 10 f0    	add    $0xf0105c35,%edx
f0100d49:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d4c:	8b 51 08             	mov    0x8(%ecx),%edx
f0100d4f:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0100d52:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0100d54:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100d57:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100d5a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d5d:	83 ec 08             	sub    $0x8,%esp
f0100d60:	6a 3a                	push   $0x3a
f0100d62:	ff 76 08             	pushl  0x8(%esi)
f0100d65:	e8 bc 09 00 00       	call   f0101726 <strfind>
f0100d6a:	2b 46 08             	sub    0x8(%esi),%eax
f0100d6d:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100d70:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d73:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d76:	83 c4 08             	add    $0x8,%esp
f0100d79:	57                   	push   %edi
f0100d7a:	6a 44                	push   $0x44
f0100d7c:	c7 c0 bc 22 10 f0    	mov    $0xf01022bc,%eax
f0100d82:	e8 c0 fd ff ff       	call   f0100b47 <stab_binsearch>
    if(lline <= rline){
f0100d87:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100d8a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d8d:	83 c4 10             	add    $0x10,%esp
        info->eip_line = stabs[rline].n_desc;
    }
    else {
        info->eip_line = -1;
f0100d90:	ba ff ff ff ff       	mov    $0xffffffff,%edx
    if(lline <= rline){
f0100d95:	39 c1                	cmp    %eax,%ecx
f0100d97:	7f 0e                	jg     f0100da7 <debuginfo_eip+0x16b>
        info->eip_line = stabs[rline].n_desc;
f0100d99:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d9c:	c7 c0 bc 22 10 f0    	mov    $0xf01022bc,%eax
f0100da2:	0f b7 54 90 06       	movzwl 0x6(%eax,%edx,4),%edx
f0100da7:	89 56 04             	mov    %edx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100daa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100dad:	89 ca                	mov    %ecx,%edx
f0100daf:	8d 0c 49             	lea    (%ecx,%ecx,2),%ecx
f0100db2:	c7 c0 bc 22 10 f0    	mov    $0xf01022bc,%eax
f0100db8:	8d 44 88 04          	lea    0x4(%eax,%ecx,4),%eax
f0100dbc:	89 75 0c             	mov    %esi,0xc(%ebp)
f0100dbf:	eb 35                	jmp    f0100df6 <debuginfo_eip+0x1ba>
  	        panic("User address");
f0100dc1:	83 ec 04             	sub    $0x4,%esp
f0100dc4:	8d 83 a3 0d ff ff    	lea    -0xf25d(%ebx),%eax
f0100dca:	50                   	push   %eax
f0100dcb:	68 80 00 00 00       	push   $0x80
f0100dd0:	8d 83 b0 0d ff ff    	lea    -0xf250(%ebx),%eax
f0100dd6:	50                   	push   %eax
f0100dd7:	e8 2a f3 ff ff       	call   f0100106 <_panic>
		info->eip_fn_addr = addr;
f0100ddc:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100ddf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100de2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100de5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100de8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100deb:	e9 6d ff ff ff       	jmp    f0100d5d <debuginfo_eip+0x121>
f0100df0:	83 ea 01             	sub    $0x1,%edx
f0100df3:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100df6:	39 d7                	cmp    %edx,%edi
f0100df8:	7f 3c                	jg     f0100e36 <debuginfo_eip+0x1fa>
	       && stabs[lline].n_type != N_SOL
f0100dfa:	0f b6 08             	movzbl (%eax),%ecx
f0100dfd:	80 f9 84             	cmp    $0x84,%cl
f0100e00:	74 0b                	je     f0100e0d <debuginfo_eip+0x1d1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100e02:	80 f9 64             	cmp    $0x64,%cl
f0100e05:	75 e9                	jne    f0100df0 <debuginfo_eip+0x1b4>
f0100e07:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100e0b:	74 e3                	je     f0100df0 <debuginfo_eip+0x1b4>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100e0d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100e10:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100e13:	c7 c0 bc 22 10 f0    	mov    $0xf01022bc,%eax
f0100e19:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100e1c:	c7 c0 75 72 10 f0    	mov    $0xf0107275,%eax
f0100e22:	81 e8 35 5c 10 f0    	sub    $0xf0105c35,%eax
f0100e28:	39 c2                	cmp    %eax,%edx
f0100e2a:	73 0d                	jae    f0100e39 <debuginfo_eip+0x1fd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100e2c:	81 c2 35 5c 10 f0    	add    $0xf0105c35,%edx
f0100e32:	89 16                	mov    %edx,(%esi)
f0100e34:	eb 03                	jmp    f0100e39 <debuginfo_eip+0x1fd>
f0100e36:	8b 75 0c             	mov    0xc(%ebp),%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100e39:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e3c:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e3f:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100e44:	39 fa                	cmp    %edi,%edx
f0100e46:	7d 49                	jge    f0100e91 <debuginfo_eip+0x255>
		for (lline = lfun + 1;
f0100e48:	8d 42 01             	lea    0x1(%edx),%eax
f0100e4b:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100e4e:	c7 c2 bc 22 10 f0    	mov    $0xf01022bc,%edx
f0100e54:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0100e58:	eb 04                	jmp    f0100e5e <debuginfo_eip+0x222>
			info->eip_fn_narg++;
f0100e5a:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0100e5e:	39 c7                	cmp    %eax,%edi
f0100e60:	7e 2a                	jle    f0100e8c <debuginfo_eip+0x250>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e62:	0f b6 0a             	movzbl (%edx),%ecx
f0100e65:	83 c0 01             	add    $0x1,%eax
f0100e68:	83 c2 0c             	add    $0xc,%edx
f0100e6b:	80 f9 a0             	cmp    $0xa0,%cl
f0100e6e:	74 ea                	je     f0100e5a <debuginfo_eip+0x21e>
	return 0;
f0100e70:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e75:	eb 1a                	jmp    f0100e91 <debuginfo_eip+0x255>
		return -1;
f0100e77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e7c:	eb 13                	jmp    f0100e91 <debuginfo_eip+0x255>
f0100e7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e83:	eb 0c                	jmp    f0100e91 <debuginfo_eip+0x255>
		return -1;
f0100e85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e8a:	eb 05                	jmp    f0100e91 <debuginfo_eip+0x255>
	return 0;
f0100e8c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e91:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e94:	5b                   	pop    %ebx
f0100e95:	5e                   	pop    %esi
f0100e96:	5f                   	pop    %edi
f0100e97:	5d                   	pop    %ebp
f0100e98:	c3                   	ret    

f0100e99 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e99:	55                   	push   %ebp
f0100e9a:	89 e5                	mov    %esp,%ebp
f0100e9c:	57                   	push   %edi
f0100e9d:	56                   	push   %esi
f0100e9e:	53                   	push   %ebx
f0100e9f:	83 ec 2c             	sub    $0x2c,%esp
f0100ea2:	e8 05 06 00 00       	call   f01014ac <__x86.get_pc_thunk.cx>
f0100ea7:	81 c1 61 04 01 00    	add    $0x10461,%ecx
f0100ead:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100eb0:	89 c7                	mov    %eax,%edi
f0100eb2:	89 d6                	mov    %edx,%esi
f0100eb4:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eb7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100eba:	89 d1                	mov    %edx,%ecx
f0100ebc:	89 c2                	mov    %eax,%edx
f0100ebe:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ec1:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100ec4:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ec7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100eca:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ecd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100ed4:	39 c2                	cmp    %eax,%edx
f0100ed6:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0100ed9:	72 41                	jb     f0100f1c <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100edb:	83 ec 0c             	sub    $0xc,%esp
f0100ede:	ff 75 18             	pushl  0x18(%ebp)
f0100ee1:	83 eb 01             	sub    $0x1,%ebx
f0100ee4:	53                   	push   %ebx
f0100ee5:	50                   	push   %eax
f0100ee6:	83 ec 08             	sub    $0x8,%esp
f0100ee9:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100eec:	ff 75 e0             	pushl  -0x20(%ebp)
f0100eef:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100ef2:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ef5:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100ef8:	e8 43 0a 00 00       	call   f0101940 <__udivdi3>
f0100efd:	83 c4 18             	add    $0x18,%esp
f0100f00:	52                   	push   %edx
f0100f01:	50                   	push   %eax
f0100f02:	89 f2                	mov    %esi,%edx
f0100f04:	89 f8                	mov    %edi,%eax
f0100f06:	e8 8e ff ff ff       	call   f0100e99 <printnum>
f0100f0b:	83 c4 20             	add    $0x20,%esp
f0100f0e:	eb 13                	jmp    f0100f23 <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100f10:	83 ec 08             	sub    $0x8,%esp
f0100f13:	56                   	push   %esi
f0100f14:	ff 75 18             	pushl  0x18(%ebp)
f0100f17:	ff d7                	call   *%edi
f0100f19:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100f1c:	83 eb 01             	sub    $0x1,%ebx
f0100f1f:	85 db                	test   %ebx,%ebx
f0100f21:	7f ed                	jg     f0100f10 <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100f23:	83 ec 08             	sub    $0x8,%esp
f0100f26:	56                   	push   %esi
f0100f27:	83 ec 04             	sub    $0x4,%esp
f0100f2a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100f2d:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f30:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100f33:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f36:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100f39:	e8 12 0b 00 00       	call   f0101a50 <__umoddi3>
f0100f3e:	83 c4 14             	add    $0x14,%esp
f0100f41:	0f be 84 03 be 0d ff 	movsbl -0xf242(%ebx,%eax,1),%eax
f0100f48:	ff 
f0100f49:	50                   	push   %eax
f0100f4a:	ff d7                	call   *%edi
}
f0100f4c:	83 c4 10             	add    $0x10,%esp
f0100f4f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f52:	5b                   	pop    %ebx
f0100f53:	5e                   	pop    %esi
f0100f54:	5f                   	pop    %edi
f0100f55:	5d                   	pop    %ebp
f0100f56:	c3                   	ret    

f0100f57 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f57:	55                   	push   %ebp
f0100f58:	89 e5                	mov    %esp,%ebp
f0100f5a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f5d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f61:	8b 10                	mov    (%eax),%edx
f0100f63:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f66:	73 0a                	jae    f0100f72 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f68:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100f6b:	89 08                	mov    %ecx,(%eax)
f0100f6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f70:	88 02                	mov    %al,(%edx)
}
f0100f72:	5d                   	pop    %ebp
f0100f73:	c3                   	ret    

f0100f74 <printfmt>:
{
f0100f74:	55                   	push   %ebp
f0100f75:	89 e5                	mov    %esp,%ebp
f0100f77:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100f7a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f7d:	50                   	push   %eax
f0100f7e:	ff 75 10             	pushl  0x10(%ebp)
f0100f81:	ff 75 0c             	pushl  0xc(%ebp)
f0100f84:	ff 75 08             	pushl  0x8(%ebp)
f0100f87:	e8 05 00 00 00       	call   f0100f91 <vprintfmt>
}
f0100f8c:	83 c4 10             	add    $0x10,%esp
f0100f8f:	c9                   	leave  
f0100f90:	c3                   	ret    

f0100f91 <vprintfmt>:
{
f0100f91:	55                   	push   %ebp
f0100f92:	89 e5                	mov    %esp,%ebp
f0100f94:	57                   	push   %edi
f0100f95:	56                   	push   %esi
f0100f96:	53                   	push   %ebx
f0100f97:	83 ec 3c             	sub    $0x3c,%esp
f0100f9a:	e8 ba f7 ff ff       	call   f0100759 <__x86.get_pc_thunk.ax>
f0100f9f:	05 69 03 01 00       	add    $0x10369,%eax
f0100fa4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fa7:	8b 75 08             	mov    0x8(%ebp),%esi
f0100faa:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100fad:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fb0:	8d 80 3c 1d 00 00    	lea    0x1d3c(%eax),%eax
f0100fb6:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100fb9:	eb 0a                	jmp    f0100fc5 <vprintfmt+0x34>
			putch(ch, putdat);
f0100fbb:	83 ec 08             	sub    $0x8,%esp
f0100fbe:	57                   	push   %edi
f0100fbf:	50                   	push   %eax
f0100fc0:	ff d6                	call   *%esi
f0100fc2:	83 c4 10             	add    $0x10,%esp
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100fc5:	83 c3 01             	add    $0x1,%ebx
f0100fc8:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0100fcc:	83 f8 25             	cmp    $0x25,%eax
f0100fcf:	74 0c                	je     f0100fdd <vprintfmt+0x4c>
			if (ch == '\0')
f0100fd1:	85 c0                	test   %eax,%eax
f0100fd3:	75 e6                	jne    f0100fbb <vprintfmt+0x2a>
}
f0100fd5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fd8:	5b                   	pop    %ebx
f0100fd9:	5e                   	pop    %esi
f0100fda:	5f                   	pop    %edi
f0100fdb:	5d                   	pop    %ebp
f0100fdc:	c3                   	ret    
		padc = ' ';
f0100fdd:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f0100fe1:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f0100fe8:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0100fef:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f0100ff6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ffb:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100ffe:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101001:	8d 43 01             	lea    0x1(%ebx),%eax
f0101004:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101007:	0f b6 13             	movzbl (%ebx),%edx
f010100a:	8d 42 dd             	lea    -0x23(%edx),%eax
f010100d:	3c 55                	cmp    $0x55,%al
f010100f:	0f 87 fb 03 00 00    	ja     f0101410 <.L20>
f0101015:	0f b6 c0             	movzbl %al,%eax
f0101018:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010101b:	89 ce                	mov    %ecx,%esi
f010101d:	03 b4 81 4c 0e ff ff 	add    -0xf1b4(%ecx,%eax,4),%esi
f0101024:	ff e6                	jmp    *%esi

f0101026 <.L68>:
f0101026:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f0101029:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f010102d:	eb d2                	jmp    f0101001 <vprintfmt+0x70>

f010102f <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f010102f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101032:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f0101036:	eb c9                	jmp    f0101001 <vprintfmt+0x70>

f0101038 <.L31>:
f0101038:	0f b6 d2             	movzbl %dl,%edx
f010103b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f010103e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101043:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0101046:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101049:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010104d:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0101050:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101053:	83 f9 09             	cmp    $0x9,%ecx
f0101056:	77 58                	ja     f01010b0 <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0101058:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f010105b:	eb e9                	jmp    f0101046 <.L31+0xe>

f010105d <.L34>:
			precision = va_arg(ap, int);
f010105d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101060:	8b 00                	mov    (%eax),%eax
f0101062:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101065:	8b 45 14             	mov    0x14(%ebp),%eax
f0101068:	8d 40 04             	lea    0x4(%eax),%eax
f010106b:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010106e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f0101071:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101075:	79 8a                	jns    f0101001 <vprintfmt+0x70>
				width = precision, precision = -1;
f0101077:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010107a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010107d:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0101084:	e9 78 ff ff ff       	jmp    f0101001 <vprintfmt+0x70>

f0101089 <.L33>:
f0101089:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010108c:	85 c0                	test   %eax,%eax
f010108e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101093:	0f 49 d0             	cmovns %eax,%edx
f0101096:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101099:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f010109c:	e9 60 ff ff ff       	jmp    f0101001 <vprintfmt+0x70>

f01010a1 <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f01010a1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f01010a4:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01010ab:	e9 51 ff ff ff       	jmp    f0101001 <vprintfmt+0x70>
f01010b0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010b3:	89 75 08             	mov    %esi,0x8(%ebp)
f01010b6:	eb b9                	jmp    f0101071 <.L34+0x14>

f01010b8 <.L27>:
			lflag++;
f01010b8:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01010bc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01010bf:	e9 3d ff ff ff       	jmp    f0101001 <vprintfmt+0x70>

f01010c4 <.L30>:
			putch(va_arg(ap, int), putdat);
f01010c4:	8b 75 08             	mov    0x8(%ebp),%esi
f01010c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ca:	8d 58 04             	lea    0x4(%eax),%ebx
f01010cd:	83 ec 08             	sub    $0x8,%esp
f01010d0:	57                   	push   %edi
f01010d1:	ff 30                	pushl  (%eax)
f01010d3:	ff d6                	call   *%esi
			break;
f01010d5:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01010d8:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f01010db:	e9 c6 02 00 00       	jmp    f01013a6 <.L25+0x45>

f01010e0 <.L28>:
			err = va_arg(ap, int);
f01010e0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010e3:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e6:	8d 58 04             	lea    0x4(%eax),%ebx
f01010e9:	8b 00                	mov    (%eax),%eax
f01010eb:	99                   	cltd   
f01010ec:	31 d0                	xor    %edx,%eax
f01010ee:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01010f0:	83 f8 06             	cmp    $0x6,%eax
f01010f3:	7f 27                	jg     f010111c <.L28+0x3c>
f01010f5:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01010f8:	8b 14 82             	mov    (%edx,%eax,4),%edx
f01010fb:	85 d2                	test   %edx,%edx
f01010fd:	74 1d                	je     f010111c <.L28+0x3c>
				printfmt(putch, putdat, "%s", p);
f01010ff:	52                   	push   %edx
f0101100:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101103:	8d 80 df 0d ff ff    	lea    -0xf221(%eax),%eax
f0101109:	50                   	push   %eax
f010110a:	57                   	push   %edi
f010110b:	56                   	push   %esi
f010110c:	e8 63 fe ff ff       	call   f0100f74 <printfmt>
f0101111:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101114:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0101117:	e9 8a 02 00 00       	jmp    f01013a6 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f010111c:	50                   	push   %eax
f010111d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101120:	8d 80 d6 0d ff ff    	lea    -0xf22a(%eax),%eax
f0101126:	50                   	push   %eax
f0101127:	57                   	push   %edi
f0101128:	56                   	push   %esi
f0101129:	e8 46 fe ff ff       	call   f0100f74 <printfmt>
f010112e:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101131:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0101134:	e9 6d 02 00 00       	jmp    f01013a6 <.L25+0x45>

f0101139 <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101139:	8b 75 08             	mov    0x8(%ebp),%esi
f010113c:	8b 45 14             	mov    0x14(%ebp),%eax
f010113f:	83 c0 04             	add    $0x4,%eax
f0101142:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0101145:	8b 45 14             	mov    0x14(%ebp),%eax
f0101148:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f010114a:	85 d2                	test   %edx,%edx
f010114c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010114f:	8d 80 cf 0d ff ff    	lea    -0xf231(%eax),%eax
f0101155:	0f 45 c2             	cmovne %edx,%eax
f0101158:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f010115b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010115f:	7e 06                	jle    f0101167 <.L24+0x2e>
f0101161:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f0101165:	75 0d                	jne    f0101174 <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101167:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010116a:	89 c3                	mov    %eax,%ebx
f010116c:	03 45 d4             	add    -0x2c(%ebp),%eax
f010116f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101172:	eb 58                	jmp    f01011cc <.L24+0x93>
f0101174:	83 ec 08             	sub    $0x8,%esp
f0101177:	ff 75 d8             	pushl  -0x28(%ebp)
f010117a:	ff 75 c8             	pushl  -0x38(%ebp)
f010117d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101180:	e8 48 04 00 00       	call   f01015cd <strnlen>
f0101185:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101188:	29 c2                	sub    %eax,%edx
f010118a:	89 55 bc             	mov    %edx,-0x44(%ebp)
f010118d:	83 c4 10             	add    $0x10,%esp
f0101190:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f0101192:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0101196:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101199:	eb 0f                	jmp    f01011aa <.L24+0x71>
					putch(padc, putdat);
f010119b:	83 ec 08             	sub    $0x8,%esp
f010119e:	57                   	push   %edi
f010119f:	ff 75 d4             	pushl  -0x2c(%ebp)
f01011a2:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f01011a4:	83 eb 01             	sub    $0x1,%ebx
f01011a7:	83 c4 10             	add    $0x10,%esp
f01011aa:	85 db                	test   %ebx,%ebx
f01011ac:	7f ed                	jg     f010119b <.L24+0x62>
f01011ae:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01011b1:	85 d2                	test   %edx,%edx
f01011b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b8:	0f 49 c2             	cmovns %edx,%eax
f01011bb:	29 c2                	sub    %eax,%edx
f01011bd:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01011c0:	eb a5                	jmp    f0101167 <.L24+0x2e>
					putch(ch, putdat);
f01011c2:	83 ec 08             	sub    $0x8,%esp
f01011c5:	57                   	push   %edi
f01011c6:	52                   	push   %edx
f01011c7:	ff d6                	call   *%esi
f01011c9:	83 c4 10             	add    $0x10,%esp
f01011cc:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01011cf:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01011d1:	83 c3 01             	add    $0x1,%ebx
f01011d4:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f01011d8:	0f be d0             	movsbl %al,%edx
f01011db:	85 d2                	test   %edx,%edx
f01011dd:	74 4b                	je     f010122a <.L24+0xf1>
f01011df:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01011e3:	78 06                	js     f01011eb <.L24+0xb2>
f01011e5:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f01011e9:	78 1e                	js     f0101209 <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f01011eb:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01011ef:	74 d1                	je     f01011c2 <.L24+0x89>
f01011f1:	0f be c0             	movsbl %al,%eax
f01011f4:	83 e8 20             	sub    $0x20,%eax
f01011f7:	83 f8 5e             	cmp    $0x5e,%eax
f01011fa:	76 c6                	jbe    f01011c2 <.L24+0x89>
					putch('?', putdat);
f01011fc:	83 ec 08             	sub    $0x8,%esp
f01011ff:	57                   	push   %edi
f0101200:	6a 3f                	push   $0x3f
f0101202:	ff d6                	call   *%esi
f0101204:	83 c4 10             	add    $0x10,%esp
f0101207:	eb c3                	jmp    f01011cc <.L24+0x93>
f0101209:	89 cb                	mov    %ecx,%ebx
f010120b:	eb 0e                	jmp    f010121b <.L24+0xe2>
				putch(' ', putdat);
f010120d:	83 ec 08             	sub    $0x8,%esp
f0101210:	57                   	push   %edi
f0101211:	6a 20                	push   $0x20
f0101213:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0101215:	83 eb 01             	sub    $0x1,%ebx
f0101218:	83 c4 10             	add    $0x10,%esp
f010121b:	85 db                	test   %ebx,%ebx
f010121d:	7f ee                	jg     f010120d <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f010121f:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0101222:	89 45 14             	mov    %eax,0x14(%ebp)
f0101225:	e9 7c 01 00 00       	jmp    f01013a6 <.L25+0x45>
f010122a:	89 cb                	mov    %ecx,%ebx
f010122c:	eb ed                	jmp    f010121b <.L24+0xe2>

f010122e <.L29>:
	if (lflag >= 2)
f010122e:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101231:	8b 75 08             	mov    0x8(%ebp),%esi
f0101234:	83 f9 01             	cmp    $0x1,%ecx
f0101237:	7f 1b                	jg     f0101254 <.L29+0x26>
	else if (lflag)
f0101239:	85 c9                	test   %ecx,%ecx
f010123b:	74 63                	je     f01012a0 <.L29+0x72>
		return va_arg(*ap, long);
f010123d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101240:	8b 00                	mov    (%eax),%eax
f0101242:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101245:	99                   	cltd   
f0101246:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101249:	8b 45 14             	mov    0x14(%ebp),%eax
f010124c:	8d 40 04             	lea    0x4(%eax),%eax
f010124f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101252:	eb 17                	jmp    f010126b <.L29+0x3d>
		return va_arg(*ap, long long);
f0101254:	8b 45 14             	mov    0x14(%ebp),%eax
f0101257:	8b 50 04             	mov    0x4(%eax),%edx
f010125a:	8b 00                	mov    (%eax),%eax
f010125c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010125f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101262:	8b 45 14             	mov    0x14(%ebp),%eax
f0101265:	8d 40 08             	lea    0x8(%eax),%eax
f0101268:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010126b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010126e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101271:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0101276:	85 c9                	test   %ecx,%ecx
f0101278:	0f 89 0e 01 00 00    	jns    f010138c <.L25+0x2b>
				putch('-', putdat);
f010127e:	83 ec 08             	sub    $0x8,%esp
f0101281:	57                   	push   %edi
f0101282:	6a 2d                	push   $0x2d
f0101284:	ff d6                	call   *%esi
				num = -(long long) num;
f0101286:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101289:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010128c:	f7 da                	neg    %edx
f010128e:	83 d1 00             	adc    $0x0,%ecx
f0101291:	f7 d9                	neg    %ecx
f0101293:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101296:	b8 0a 00 00 00       	mov    $0xa,%eax
f010129b:	e9 ec 00 00 00       	jmp    f010138c <.L25+0x2b>
		return va_arg(*ap, int);
f01012a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01012a3:	8b 00                	mov    (%eax),%eax
f01012a5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01012a8:	99                   	cltd   
f01012a9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01012ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01012af:	8d 40 04             	lea    0x4(%eax),%eax
f01012b2:	89 45 14             	mov    %eax,0x14(%ebp)
f01012b5:	eb b4                	jmp    f010126b <.L29+0x3d>

f01012b7 <.L23>:
	if (lflag >= 2)
f01012b7:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01012ba:	8b 75 08             	mov    0x8(%ebp),%esi
f01012bd:	83 f9 01             	cmp    $0x1,%ecx
f01012c0:	7f 1e                	jg     f01012e0 <.L23+0x29>
	else if (lflag)
f01012c2:	85 c9                	test   %ecx,%ecx
f01012c4:	74 32                	je     f01012f8 <.L23+0x41>
		return va_arg(*ap, unsigned long);
f01012c6:	8b 45 14             	mov    0x14(%ebp),%eax
f01012c9:	8b 10                	mov    (%eax),%edx
f01012cb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012d0:	8d 40 04             	lea    0x4(%eax),%eax
f01012d3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012d6:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f01012db:	e9 ac 00 00 00       	jmp    f010138c <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01012e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e3:	8b 10                	mov    (%eax),%edx
f01012e5:	8b 48 04             	mov    0x4(%eax),%ecx
f01012e8:	8d 40 08             	lea    0x8(%eax),%eax
f01012eb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012ee:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f01012f3:	e9 94 00 00 00       	jmp    f010138c <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01012f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01012fb:	8b 10                	mov    (%eax),%edx
f01012fd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101302:	8d 40 04             	lea    0x4(%eax),%eax
f0101305:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101308:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f010130d:	eb 7d                	jmp    f010138c <.L25+0x2b>

f010130f <.L26>:
	if (lflag >= 2)
f010130f:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101312:	8b 75 08             	mov    0x8(%ebp),%esi
f0101315:	83 f9 01             	cmp    $0x1,%ecx
f0101318:	7f 1b                	jg     f0101335 <.L26+0x26>
	else if (lflag)
f010131a:	85 c9                	test   %ecx,%ecx
f010131c:	74 2c                	je     f010134a <.L26+0x3b>
		return va_arg(*ap, unsigned long);
f010131e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101321:	8b 10                	mov    (%eax),%edx
f0101323:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101328:	8d 40 04             	lea    0x4(%eax),%eax
f010132b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010132e:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f0101333:	eb 57                	jmp    f010138c <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0101335:	8b 45 14             	mov    0x14(%ebp),%eax
f0101338:	8b 10                	mov    (%eax),%edx
f010133a:	8b 48 04             	mov    0x4(%eax),%ecx
f010133d:	8d 40 08             	lea    0x8(%eax),%eax
f0101340:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101343:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f0101348:	eb 42                	jmp    f010138c <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f010134a:	8b 45 14             	mov    0x14(%ebp),%eax
f010134d:	8b 10                	mov    (%eax),%edx
f010134f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101354:	8d 40 04             	lea    0x4(%eax),%eax
f0101357:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010135a:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f010135f:	eb 2b                	jmp    f010138c <.L25+0x2b>

f0101361 <.L25>:
			putch('0', putdat);
f0101361:	8b 75 08             	mov    0x8(%ebp),%esi
f0101364:	83 ec 08             	sub    $0x8,%esp
f0101367:	57                   	push   %edi
f0101368:	6a 30                	push   $0x30
f010136a:	ff d6                	call   *%esi
			putch('x', putdat);
f010136c:	83 c4 08             	add    $0x8,%esp
f010136f:	57                   	push   %edi
f0101370:	6a 78                	push   $0x78
f0101372:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101374:	8b 45 14             	mov    0x14(%ebp),%eax
f0101377:	8b 10                	mov    (%eax),%edx
f0101379:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010137e:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101381:	8d 40 04             	lea    0x4(%eax),%eax
f0101384:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101387:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010138c:	83 ec 0c             	sub    $0xc,%esp
f010138f:	0f be 5d cf          	movsbl -0x31(%ebp),%ebx
f0101393:	53                   	push   %ebx
f0101394:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101397:	50                   	push   %eax
f0101398:	51                   	push   %ecx
f0101399:	52                   	push   %edx
f010139a:	89 fa                	mov    %edi,%edx
f010139c:	89 f0                	mov    %esi,%eax
f010139e:	e8 f6 fa ff ff       	call   f0100e99 <printnum>
			break;
f01013a3:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01013a6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01013a9:	e9 17 fc ff ff       	jmp    f0100fc5 <vprintfmt+0x34>

f01013ae <.L21>:
	if (lflag >= 2)
f01013ae:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01013b1:	8b 75 08             	mov    0x8(%ebp),%esi
f01013b4:	83 f9 01             	cmp    $0x1,%ecx
f01013b7:	7f 1b                	jg     f01013d4 <.L21+0x26>
	else if (lflag)
f01013b9:	85 c9                	test   %ecx,%ecx
f01013bb:	74 2c                	je     f01013e9 <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f01013bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01013c0:	8b 10                	mov    (%eax),%edx
f01013c2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013c7:	8d 40 04             	lea    0x4(%eax),%eax
f01013ca:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013cd:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f01013d2:	eb b8                	jmp    f010138c <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01013d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01013d7:	8b 10                	mov    (%eax),%edx
f01013d9:	8b 48 04             	mov    0x4(%eax),%ecx
f01013dc:	8d 40 08             	lea    0x8(%eax),%eax
f01013df:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013e2:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f01013e7:	eb a3                	jmp    f010138c <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01013e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ec:	8b 10                	mov    (%eax),%edx
f01013ee:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013f3:	8d 40 04             	lea    0x4(%eax),%eax
f01013f6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013f9:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f01013fe:	eb 8c                	jmp    f010138c <.L25+0x2b>

f0101400 <.L35>:
			putch(ch, putdat);
f0101400:	8b 75 08             	mov    0x8(%ebp),%esi
f0101403:	83 ec 08             	sub    $0x8,%esp
f0101406:	57                   	push   %edi
f0101407:	6a 25                	push   $0x25
f0101409:	ff d6                	call   *%esi
			break;
f010140b:	83 c4 10             	add    $0x10,%esp
f010140e:	eb 96                	jmp    f01013a6 <.L25+0x45>

f0101410 <.L20>:
			putch('%', putdat);
f0101410:	8b 75 08             	mov    0x8(%ebp),%esi
f0101413:	83 ec 08             	sub    $0x8,%esp
f0101416:	57                   	push   %edi
f0101417:	6a 25                	push   $0x25
f0101419:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010141b:	83 c4 10             	add    $0x10,%esp
f010141e:	89 d8                	mov    %ebx,%eax
f0101420:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101424:	74 05                	je     f010142b <.L20+0x1b>
f0101426:	83 e8 01             	sub    $0x1,%eax
f0101429:	eb f5                	jmp    f0101420 <.L20+0x10>
f010142b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010142e:	e9 73 ff ff ff       	jmp    f01013a6 <.L25+0x45>

f0101433 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101433:	55                   	push   %ebp
f0101434:	89 e5                	mov    %esp,%ebp
f0101436:	53                   	push   %ebx
f0101437:	83 ec 14             	sub    $0x14,%esp
f010143a:	e8 7d ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010143f:	81 c3 c9 fe 00 00    	add    $0xfec9,%ebx
f0101445:	8b 45 08             	mov    0x8(%ebp),%eax
f0101448:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010144b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010144e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101452:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101455:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010145c:	85 c0                	test   %eax,%eax
f010145e:	74 2b                	je     f010148b <vsnprintf+0x58>
f0101460:	85 d2                	test   %edx,%edx
f0101462:	7e 27                	jle    f010148b <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101464:	ff 75 14             	pushl  0x14(%ebp)
f0101467:	ff 75 10             	pushl  0x10(%ebp)
f010146a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010146d:	50                   	push   %eax
f010146e:	8d 83 4f fc fe ff    	lea    -0x103b1(%ebx),%eax
f0101474:	50                   	push   %eax
f0101475:	e8 17 fb ff ff       	call   f0100f91 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010147a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010147d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101480:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101483:	83 c4 10             	add    $0x10,%esp
}
f0101486:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101489:	c9                   	leave  
f010148a:	c3                   	ret    
		return -E_INVAL;
f010148b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101490:	eb f4                	jmp    f0101486 <vsnprintf+0x53>

f0101492 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101492:	55                   	push   %ebp
f0101493:	89 e5                	mov    %esp,%ebp
f0101495:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101498:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010149b:	50                   	push   %eax
f010149c:	ff 75 10             	pushl  0x10(%ebp)
f010149f:	ff 75 0c             	pushl  0xc(%ebp)
f01014a2:	ff 75 08             	pushl  0x8(%ebp)
f01014a5:	e8 89 ff ff ff       	call   f0101433 <vsnprintf>
	va_end(ap);

	return rc;
}
f01014aa:	c9                   	leave  
f01014ab:	c3                   	ret    

f01014ac <__x86.get_pc_thunk.cx>:
f01014ac:	8b 0c 24             	mov    (%esp),%ecx
f01014af:	c3                   	ret    

f01014b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01014b0:	55                   	push   %ebp
f01014b1:	89 e5                	mov    %esp,%ebp
f01014b3:	57                   	push   %edi
f01014b4:	56                   	push   %esi
f01014b5:	53                   	push   %ebx
f01014b6:	83 ec 1c             	sub    $0x1c,%esp
f01014b9:	e8 fe ec ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01014be:	81 c3 4a fe 00 00    	add    $0xfe4a,%ebx
f01014c4:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01014c7:	85 c0                	test   %eax,%eax
f01014c9:	74 13                	je     f01014de <readline+0x2e>
		cprintf("%s", prompt);
f01014cb:	83 ec 08             	sub    $0x8,%esp
f01014ce:	50                   	push   %eax
f01014cf:	8d 83 df 0d ff ff    	lea    -0xf221(%ebx),%eax
f01014d5:	50                   	push   %eax
f01014d6:	e8 58 f6 ff ff       	call   f0100b33 <cprintf>
f01014db:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01014de:	83 ec 0c             	sub    $0xc,%esp
f01014e1:	6a 00                	push   $0x0
f01014e3:	e8 6b f2 ff ff       	call   f0100753 <iscons>
f01014e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01014eb:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01014ee:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f01014f3:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f01014f9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01014fc:	eb 45                	jmp    f0101543 <readline+0x93>
			cprintf("read error: %e\n", c);
f01014fe:	83 ec 08             	sub    $0x8,%esp
f0101501:	50                   	push   %eax
f0101502:	8d 83 a4 0f ff ff    	lea    -0xf05c(%ebx),%eax
f0101508:	50                   	push   %eax
f0101509:	e8 25 f6 ff ff       	call   f0100b33 <cprintf>
			return NULL;
f010150e:	83 c4 10             	add    $0x10,%esp
f0101511:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101516:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101519:	5b                   	pop    %ebx
f010151a:	5e                   	pop    %esi
f010151b:	5f                   	pop    %edi
f010151c:	5d                   	pop    %ebp
f010151d:	c3                   	ret    
			if (echoing)
f010151e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101522:	75 05                	jne    f0101529 <readline+0x79>
			i--;
f0101524:	83 ef 01             	sub    $0x1,%edi
f0101527:	eb 1a                	jmp    f0101543 <readline+0x93>
				cputchar('\b');
f0101529:	83 ec 0c             	sub    $0xc,%esp
f010152c:	6a 08                	push   $0x8
f010152e:	e8 ff f1 ff ff       	call   f0100732 <cputchar>
f0101533:	83 c4 10             	add    $0x10,%esp
f0101536:	eb ec                	jmp    f0101524 <readline+0x74>
			buf[i++] = c;
f0101538:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010153b:	89 f0                	mov    %esi,%eax
f010153d:	88 04 39             	mov    %al,(%ecx,%edi,1)
f0101540:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101543:	e8 fa f1 ff ff       	call   f0100742 <getchar>
f0101548:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010154a:	85 c0                	test   %eax,%eax
f010154c:	78 b0                	js     f01014fe <readline+0x4e>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010154e:	83 f8 08             	cmp    $0x8,%eax
f0101551:	0f 94 c2             	sete   %dl
f0101554:	83 f8 7f             	cmp    $0x7f,%eax
f0101557:	0f 94 c0             	sete   %al
f010155a:	08 c2                	or     %al,%dl
f010155c:	74 04                	je     f0101562 <readline+0xb2>
f010155e:	85 ff                	test   %edi,%edi
f0101560:	7f bc                	jg     f010151e <readline+0x6e>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101562:	83 fe 1f             	cmp    $0x1f,%esi
f0101565:	7e 1c                	jle    f0101583 <readline+0xd3>
f0101567:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010156d:	7f 14                	jg     f0101583 <readline+0xd3>
			if (echoing)
f010156f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101573:	74 c3                	je     f0101538 <readline+0x88>
				cputchar(c);
f0101575:	83 ec 0c             	sub    $0xc,%esp
f0101578:	56                   	push   %esi
f0101579:	e8 b4 f1 ff ff       	call   f0100732 <cputchar>
f010157e:	83 c4 10             	add    $0x10,%esp
f0101581:	eb b5                	jmp    f0101538 <readline+0x88>
		} else if (c == '\n' || c == '\r') {
f0101583:	83 fe 0a             	cmp    $0xa,%esi
f0101586:	74 05                	je     f010158d <readline+0xdd>
f0101588:	83 fe 0d             	cmp    $0xd,%esi
f010158b:	75 b6                	jne    f0101543 <readline+0x93>
			if (echoing)
f010158d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101591:	75 13                	jne    f01015a6 <readline+0xf6>
			buf[i] = 0;
f0101593:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f010159a:	00 
			return buf;
f010159b:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f01015a1:	e9 70 ff ff ff       	jmp    f0101516 <readline+0x66>
				cputchar('\n');
f01015a6:	83 ec 0c             	sub    $0xc,%esp
f01015a9:	6a 0a                	push   $0xa
f01015ab:	e8 82 f1 ff ff       	call   f0100732 <cputchar>
f01015b0:	83 c4 10             	add    $0x10,%esp
f01015b3:	eb de                	jmp    f0101593 <readline+0xe3>

f01015b5 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01015b5:	55                   	push   %ebp
f01015b6:	89 e5                	mov    %esp,%ebp
f01015b8:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01015bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01015c0:	eb 03                	jmp    f01015c5 <strlen+0x10>
		n++;
f01015c2:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01015c5:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01015c9:	75 f7                	jne    f01015c2 <strlen+0xd>
	return n;
}
f01015cb:	5d                   	pop    %ebp
f01015cc:	c3                   	ret    

f01015cd <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01015cd:	55                   	push   %ebp
f01015ce:	89 e5                	mov    %esp,%ebp
f01015d0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015d3:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01015db:	eb 03                	jmp    f01015e0 <strnlen+0x13>
		n++;
f01015dd:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015e0:	39 d0                	cmp    %edx,%eax
f01015e2:	74 08                	je     f01015ec <strnlen+0x1f>
f01015e4:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01015e8:	75 f3                	jne    f01015dd <strnlen+0x10>
f01015ea:	89 c2                	mov    %eax,%edx
	return n;
}
f01015ec:	89 d0                	mov    %edx,%eax
f01015ee:	5d                   	pop    %ebp
f01015ef:	c3                   	ret    

f01015f0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01015f0:	55                   	push   %ebp
f01015f1:	89 e5                	mov    %esp,%ebp
f01015f3:	53                   	push   %ebx
f01015f4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015f7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01015fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01015ff:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f0101603:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f0101606:	83 c0 01             	add    $0x1,%eax
f0101609:	84 d2                	test   %dl,%dl
f010160b:	75 f2                	jne    f01015ff <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f010160d:	89 c8                	mov    %ecx,%eax
f010160f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101612:	c9                   	leave  
f0101613:	c3                   	ret    

f0101614 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101614:	55                   	push   %ebp
f0101615:	89 e5                	mov    %esp,%ebp
f0101617:	53                   	push   %ebx
f0101618:	83 ec 10             	sub    $0x10,%esp
f010161b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010161e:	53                   	push   %ebx
f010161f:	e8 91 ff ff ff       	call   f01015b5 <strlen>
f0101624:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0101627:	ff 75 0c             	pushl  0xc(%ebp)
f010162a:	01 d8                	add    %ebx,%eax
f010162c:	50                   	push   %eax
f010162d:	e8 be ff ff ff       	call   f01015f0 <strcpy>
	return dst;
}
f0101632:	89 d8                	mov    %ebx,%eax
f0101634:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101637:	c9                   	leave  
f0101638:	c3                   	ret    

f0101639 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101639:	55                   	push   %ebp
f010163a:	89 e5                	mov    %esp,%ebp
f010163c:	56                   	push   %esi
f010163d:	53                   	push   %ebx
f010163e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101641:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101644:	89 f3                	mov    %esi,%ebx
f0101646:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101649:	89 f0                	mov    %esi,%eax
f010164b:	eb 0f                	jmp    f010165c <strncpy+0x23>
		*dst++ = *src;
f010164d:	83 c0 01             	add    $0x1,%eax
f0101650:	0f b6 0a             	movzbl (%edx),%ecx
f0101653:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101656:	80 f9 01             	cmp    $0x1,%cl
f0101659:	83 da ff             	sbb    $0xffffffff,%edx
	for (i = 0; i < size; i++) {
f010165c:	39 d8                	cmp    %ebx,%eax
f010165e:	75 ed                	jne    f010164d <strncpy+0x14>
	}
	return ret;
}
f0101660:	89 f0                	mov    %esi,%eax
f0101662:	5b                   	pop    %ebx
f0101663:	5e                   	pop    %esi
f0101664:	5d                   	pop    %ebp
f0101665:	c3                   	ret    

f0101666 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101666:	55                   	push   %ebp
f0101667:	89 e5                	mov    %esp,%ebp
f0101669:	56                   	push   %esi
f010166a:	53                   	push   %ebx
f010166b:	8b 75 08             	mov    0x8(%ebp),%esi
f010166e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101671:	8b 45 10             	mov    0x10(%ebp),%eax
f0101674:	89 f3                	mov    %esi,%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101676:	85 c0                	test   %eax,%eax
f0101678:	74 21                	je     f010169b <strlcpy+0x35>
f010167a:	8d 5c 06 ff          	lea    -0x1(%esi,%eax,1),%ebx
f010167e:	89 f0                	mov    %esi,%eax
f0101680:	eb 09                	jmp    f010168b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101682:	83 c2 01             	add    $0x1,%edx
f0101685:	83 c0 01             	add    $0x1,%eax
f0101688:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f010168b:	39 d8                	cmp    %ebx,%eax
f010168d:	74 09                	je     f0101698 <strlcpy+0x32>
f010168f:	0f b6 0a             	movzbl (%edx),%ecx
f0101692:	84 c9                	test   %cl,%cl
f0101694:	75 ec                	jne    f0101682 <strlcpy+0x1c>
f0101696:	89 c3                	mov    %eax,%ebx
		*dst = '\0';
f0101698:	c6 03 00             	movb   $0x0,(%ebx)
	}
	return dst - dst_in;
f010169b:	89 d8                	mov    %ebx,%eax
f010169d:	29 f0                	sub    %esi,%eax
}
f010169f:	5b                   	pop    %ebx
f01016a0:	5e                   	pop    %esi
f01016a1:	5d                   	pop    %ebp
f01016a2:	c3                   	ret    

f01016a3 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01016a3:	55                   	push   %ebp
f01016a4:	89 e5                	mov    %esp,%ebp
f01016a6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01016a9:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01016ac:	eb 06                	jmp    f01016b4 <strcmp+0x11>
		p++, q++;
f01016ae:	83 c1 01             	add    $0x1,%ecx
f01016b1:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01016b4:	0f b6 01             	movzbl (%ecx),%eax
f01016b7:	84 c0                	test   %al,%al
f01016b9:	74 04                	je     f01016bf <strcmp+0x1c>
f01016bb:	3a 02                	cmp    (%edx),%al
f01016bd:	74 ef                	je     f01016ae <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01016bf:	0f b6 c0             	movzbl %al,%eax
f01016c2:	0f b6 12             	movzbl (%edx),%edx
f01016c5:	29 d0                	sub    %edx,%eax
}
f01016c7:	5d                   	pop    %ebp
f01016c8:	c3                   	ret    

f01016c9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01016c9:	55                   	push   %ebp
f01016ca:	89 e5                	mov    %esp,%ebp
f01016cc:	53                   	push   %ebx
f01016cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01016d0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016d3:	89 c3                	mov    %eax,%ebx
f01016d5:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01016d8:	eb 06                	jmp    f01016e0 <strncmp+0x17>
		n--, p++, q++;
f01016da:	83 c0 01             	add    $0x1,%eax
f01016dd:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01016e0:	39 d8                	cmp    %ebx,%eax
f01016e2:	74 18                	je     f01016fc <strncmp+0x33>
f01016e4:	0f b6 08             	movzbl (%eax),%ecx
f01016e7:	84 c9                	test   %cl,%cl
f01016e9:	74 04                	je     f01016ef <strncmp+0x26>
f01016eb:	3a 0a                	cmp    (%edx),%cl
f01016ed:	74 eb                	je     f01016da <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01016ef:	0f b6 00             	movzbl (%eax),%eax
f01016f2:	0f b6 12             	movzbl (%edx),%edx
f01016f5:	29 d0                	sub    %edx,%eax
}
f01016f7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01016fa:	c9                   	leave  
f01016fb:	c3                   	ret    
		return 0;
f01016fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0101701:	eb f4                	jmp    f01016f7 <strncmp+0x2e>

f0101703 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101703:	55                   	push   %ebp
f0101704:	89 e5                	mov    %esp,%ebp
f0101706:	8b 45 08             	mov    0x8(%ebp),%eax
f0101709:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010170d:	eb 03                	jmp    f0101712 <strchr+0xf>
f010170f:	83 c0 01             	add    $0x1,%eax
f0101712:	0f b6 10             	movzbl (%eax),%edx
f0101715:	84 d2                	test   %dl,%dl
f0101717:	74 06                	je     f010171f <strchr+0x1c>
		if (*s == c)
f0101719:	38 ca                	cmp    %cl,%dl
f010171b:	75 f2                	jne    f010170f <strchr+0xc>
f010171d:	eb 05                	jmp    f0101724 <strchr+0x21>
			return (char *) s;
	return 0;
f010171f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101724:	5d                   	pop    %ebp
f0101725:	c3                   	ret    

f0101726 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101726:	55                   	push   %ebp
f0101727:	89 e5                	mov    %esp,%ebp
f0101729:	8b 45 08             	mov    0x8(%ebp),%eax
f010172c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101730:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101733:	38 ca                	cmp    %cl,%dl
f0101735:	74 09                	je     f0101740 <strfind+0x1a>
f0101737:	84 d2                	test   %dl,%dl
f0101739:	74 05                	je     f0101740 <strfind+0x1a>
	for (; *s; s++)
f010173b:	83 c0 01             	add    $0x1,%eax
f010173e:	eb f0                	jmp    f0101730 <strfind+0xa>
			break;
	return (char *) s;
}
f0101740:	5d                   	pop    %ebp
f0101741:	c3                   	ret    

f0101742 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101742:	55                   	push   %ebp
f0101743:	89 e5                	mov    %esp,%ebp
f0101745:	57                   	push   %edi
f0101746:	56                   	push   %esi
f0101747:	53                   	push   %ebx
f0101748:	8b 7d 08             	mov    0x8(%ebp),%edi
f010174b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010174e:	85 c9                	test   %ecx,%ecx
f0101750:	74 31                	je     f0101783 <memset+0x41>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101752:	89 f8                	mov    %edi,%eax
f0101754:	09 c8                	or     %ecx,%eax
f0101756:	a8 03                	test   $0x3,%al
f0101758:	75 23                	jne    f010177d <memset+0x3b>
		c &= 0xFF;
f010175a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010175e:	89 d3                	mov    %edx,%ebx
f0101760:	c1 e3 08             	shl    $0x8,%ebx
f0101763:	89 d0                	mov    %edx,%eax
f0101765:	c1 e0 18             	shl    $0x18,%eax
f0101768:	89 d6                	mov    %edx,%esi
f010176a:	c1 e6 10             	shl    $0x10,%esi
f010176d:	09 f0                	or     %esi,%eax
f010176f:	09 c2                	or     %eax,%edx
f0101771:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101773:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101776:	89 d0                	mov    %edx,%eax
f0101778:	fc                   	cld    
f0101779:	f3 ab                	rep stos %eax,%es:(%edi)
f010177b:	eb 06                	jmp    f0101783 <memset+0x41>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010177d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101780:	fc                   	cld    
f0101781:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101783:	89 f8                	mov    %edi,%eax
f0101785:	5b                   	pop    %ebx
f0101786:	5e                   	pop    %esi
f0101787:	5f                   	pop    %edi
f0101788:	5d                   	pop    %ebp
f0101789:	c3                   	ret    

f010178a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010178a:	55                   	push   %ebp
f010178b:	89 e5                	mov    %esp,%ebp
f010178d:	57                   	push   %edi
f010178e:	56                   	push   %esi
f010178f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101792:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101795:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101798:	39 c6                	cmp    %eax,%esi
f010179a:	73 32                	jae    f01017ce <memmove+0x44>
f010179c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010179f:	39 c2                	cmp    %eax,%edx
f01017a1:	76 2b                	jbe    f01017ce <memmove+0x44>
		s += n;
		d += n;
f01017a3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017a6:	89 fe                	mov    %edi,%esi
f01017a8:	09 ce                	or     %ecx,%esi
f01017aa:	09 d6                	or     %edx,%esi
f01017ac:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01017b2:	75 0e                	jne    f01017c2 <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01017b4:	83 ef 04             	sub    $0x4,%edi
f01017b7:	8d 72 fc             	lea    -0x4(%edx),%esi
f01017ba:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01017bd:	fd                   	std    
f01017be:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017c0:	eb 09                	jmp    f01017cb <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01017c2:	83 ef 01             	sub    $0x1,%edi
f01017c5:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01017c8:	fd                   	std    
f01017c9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01017cb:	fc                   	cld    
f01017cc:	eb 1a                	jmp    f01017e8 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017ce:	89 c2                	mov    %eax,%edx
f01017d0:	09 ca                	or     %ecx,%edx
f01017d2:	09 f2                	or     %esi,%edx
f01017d4:	f6 c2 03             	test   $0x3,%dl
f01017d7:	75 0a                	jne    f01017e3 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01017d9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01017dc:	89 c7                	mov    %eax,%edi
f01017de:	fc                   	cld    
f01017df:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017e1:	eb 05                	jmp    f01017e8 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f01017e3:	89 c7                	mov    %eax,%edi
f01017e5:	fc                   	cld    
f01017e6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01017e8:	5e                   	pop    %esi
f01017e9:	5f                   	pop    %edi
f01017ea:	5d                   	pop    %ebp
f01017eb:	c3                   	ret    

f01017ec <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01017ec:	55                   	push   %ebp
f01017ed:	89 e5                	mov    %esp,%ebp
f01017ef:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01017f2:	ff 75 10             	pushl  0x10(%ebp)
f01017f5:	ff 75 0c             	pushl  0xc(%ebp)
f01017f8:	ff 75 08             	pushl  0x8(%ebp)
f01017fb:	e8 8a ff ff ff       	call   f010178a <memmove>
}
f0101800:	c9                   	leave  
f0101801:	c3                   	ret    

f0101802 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101802:	55                   	push   %ebp
f0101803:	89 e5                	mov    %esp,%ebp
f0101805:	56                   	push   %esi
f0101806:	53                   	push   %ebx
f0101807:	8b 45 08             	mov    0x8(%ebp),%eax
f010180a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010180d:	89 c6                	mov    %eax,%esi
f010180f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101812:	eb 06                	jmp    f010181a <memcmp+0x18>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101814:	83 c0 01             	add    $0x1,%eax
f0101817:	83 c2 01             	add    $0x1,%edx
	while (n-- > 0) {
f010181a:	39 f0                	cmp    %esi,%eax
f010181c:	74 14                	je     f0101832 <memcmp+0x30>
		if (*s1 != *s2)
f010181e:	0f b6 08             	movzbl (%eax),%ecx
f0101821:	0f b6 1a             	movzbl (%edx),%ebx
f0101824:	38 d9                	cmp    %bl,%cl
f0101826:	74 ec                	je     f0101814 <memcmp+0x12>
			return (int) *s1 - (int) *s2;
f0101828:	0f b6 c1             	movzbl %cl,%eax
f010182b:	0f b6 db             	movzbl %bl,%ebx
f010182e:	29 d8                	sub    %ebx,%eax
f0101830:	eb 05                	jmp    f0101837 <memcmp+0x35>
	}

	return 0;
f0101832:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101837:	5b                   	pop    %ebx
f0101838:	5e                   	pop    %esi
f0101839:	5d                   	pop    %ebp
f010183a:	c3                   	ret    

f010183b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010183b:	55                   	push   %ebp
f010183c:	89 e5                	mov    %esp,%ebp
f010183e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101841:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101844:	89 c2                	mov    %eax,%edx
f0101846:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101849:	eb 03                	jmp    f010184e <memfind+0x13>
f010184b:	83 c0 01             	add    $0x1,%eax
f010184e:	39 d0                	cmp    %edx,%eax
f0101850:	73 04                	jae    f0101856 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101852:	38 08                	cmp    %cl,(%eax)
f0101854:	75 f5                	jne    f010184b <memfind+0x10>
			break;
	return (void *) s;
}
f0101856:	5d                   	pop    %ebp
f0101857:	c3                   	ret    

f0101858 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101858:	55                   	push   %ebp
f0101859:	89 e5                	mov    %esp,%ebp
f010185b:	57                   	push   %edi
f010185c:	56                   	push   %esi
f010185d:	53                   	push   %ebx
f010185e:	8b 55 08             	mov    0x8(%ebp),%edx
f0101861:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101864:	eb 03                	jmp    f0101869 <strtol+0x11>
		s++;
f0101866:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0101869:	0f b6 02             	movzbl (%edx),%eax
f010186c:	3c 20                	cmp    $0x20,%al
f010186e:	74 f6                	je     f0101866 <strtol+0xe>
f0101870:	3c 09                	cmp    $0x9,%al
f0101872:	74 f2                	je     f0101866 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101874:	3c 2b                	cmp    $0x2b,%al
f0101876:	74 2a                	je     f01018a2 <strtol+0x4a>
	int neg = 0;
f0101878:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010187d:	3c 2d                	cmp    $0x2d,%al
f010187f:	74 2b                	je     f01018ac <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101881:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101887:	75 0f                	jne    f0101898 <strtol+0x40>
f0101889:	80 3a 30             	cmpb   $0x30,(%edx)
f010188c:	74 28                	je     f01018b6 <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010188e:	85 db                	test   %ebx,%ebx
f0101890:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101895:	0f 44 d8             	cmove  %eax,%ebx
f0101898:	b9 00 00 00 00       	mov    $0x0,%ecx
f010189d:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01018a0:	eb 46                	jmp    f01018e8 <strtol+0x90>
		s++;
f01018a2:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f01018a5:	bf 00 00 00 00       	mov    $0x0,%edi
f01018aa:	eb d5                	jmp    f0101881 <strtol+0x29>
		s++, neg = 1;
f01018ac:	83 c2 01             	add    $0x1,%edx
f01018af:	bf 01 00 00 00       	mov    $0x1,%edi
f01018b4:	eb cb                	jmp    f0101881 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01018b6:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01018ba:	74 0e                	je     f01018ca <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f01018bc:	85 db                	test   %ebx,%ebx
f01018be:	75 d8                	jne    f0101898 <strtol+0x40>
		s++, base = 8;
f01018c0:	83 c2 01             	add    $0x1,%edx
f01018c3:	bb 08 00 00 00       	mov    $0x8,%ebx
f01018c8:	eb ce                	jmp    f0101898 <strtol+0x40>
		s += 2, base = 16;
f01018ca:	83 c2 02             	add    $0x2,%edx
f01018cd:	bb 10 00 00 00       	mov    $0x10,%ebx
f01018d2:	eb c4                	jmp    f0101898 <strtol+0x40>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f01018d4:	0f be c0             	movsbl %al,%eax
f01018d7:	83 e8 30             	sub    $0x30,%eax
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01018da:	3b 45 10             	cmp    0x10(%ebp),%eax
f01018dd:	7d 3a                	jge    f0101919 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01018df:	83 c2 01             	add    $0x1,%edx
f01018e2:	0f af 4d 10          	imul   0x10(%ebp),%ecx
f01018e6:	01 c1                	add    %eax,%ecx
		if (*s >= '0' && *s <= '9')
f01018e8:	0f b6 02             	movzbl (%edx),%eax
f01018eb:	8d 70 d0             	lea    -0x30(%eax),%esi
f01018ee:	89 f3                	mov    %esi,%ebx
f01018f0:	80 fb 09             	cmp    $0x9,%bl
f01018f3:	76 df                	jbe    f01018d4 <strtol+0x7c>
		else if (*s >= 'a' && *s <= 'z')
f01018f5:	8d 70 9f             	lea    -0x61(%eax),%esi
f01018f8:	89 f3                	mov    %esi,%ebx
f01018fa:	80 fb 19             	cmp    $0x19,%bl
f01018fd:	77 08                	ja     f0101907 <strtol+0xaf>
			dig = *s - 'a' + 10;
f01018ff:	0f be c0             	movsbl %al,%eax
f0101902:	83 e8 57             	sub    $0x57,%eax
f0101905:	eb d3                	jmp    f01018da <strtol+0x82>
		else if (*s >= 'A' && *s <= 'Z')
f0101907:	8d 70 bf             	lea    -0x41(%eax),%esi
f010190a:	89 f3                	mov    %esi,%ebx
f010190c:	80 fb 19             	cmp    $0x19,%bl
f010190f:	77 08                	ja     f0101919 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0101911:	0f be c0             	movsbl %al,%eax
f0101914:	83 e8 37             	sub    $0x37,%eax
f0101917:	eb c1                	jmp    f01018da <strtol+0x82>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101919:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010191d:	74 05                	je     f0101924 <strtol+0xcc>
		*endptr = (char *) s;
f010191f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101922:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0101924:	89 c8                	mov    %ecx,%eax
f0101926:	f7 d8                	neg    %eax
f0101928:	85 ff                	test   %edi,%edi
f010192a:	0f 45 c8             	cmovne %eax,%ecx
}
f010192d:	89 c8                	mov    %ecx,%eax
f010192f:	5b                   	pop    %ebx
f0101930:	5e                   	pop    %esi
f0101931:	5f                   	pop    %edi
f0101932:	5d                   	pop    %ebp
f0101933:	c3                   	ret    
f0101934:	66 90                	xchg   %ax,%ax
f0101936:	66 90                	xchg   %ax,%ax
f0101938:	66 90                	xchg   %ax,%ax
f010193a:	66 90                	xchg   %ax,%ax
f010193c:	66 90                	xchg   %ax,%ax
f010193e:	66 90                	xchg   %ax,%ax

f0101940 <__udivdi3>:
f0101940:	f3 0f 1e fb          	endbr32 
f0101944:	55                   	push   %ebp
f0101945:	57                   	push   %edi
f0101946:	56                   	push   %esi
f0101947:	53                   	push   %ebx
f0101948:	83 ec 1c             	sub    $0x1c,%esp
f010194b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010194f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0101953:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101957:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010195b:	85 d2                	test   %edx,%edx
f010195d:	75 19                	jne    f0101978 <__udivdi3+0x38>
f010195f:	39 f3                	cmp    %esi,%ebx
f0101961:	76 4d                	jbe    f01019b0 <__udivdi3+0x70>
f0101963:	31 ff                	xor    %edi,%edi
f0101965:	89 e8                	mov    %ebp,%eax
f0101967:	89 f2                	mov    %esi,%edx
f0101969:	f7 f3                	div    %ebx
f010196b:	89 fa                	mov    %edi,%edx
f010196d:	83 c4 1c             	add    $0x1c,%esp
f0101970:	5b                   	pop    %ebx
f0101971:	5e                   	pop    %esi
f0101972:	5f                   	pop    %edi
f0101973:	5d                   	pop    %ebp
f0101974:	c3                   	ret    
f0101975:	8d 76 00             	lea    0x0(%esi),%esi
f0101978:	39 f2                	cmp    %esi,%edx
f010197a:	76 14                	jbe    f0101990 <__udivdi3+0x50>
f010197c:	31 ff                	xor    %edi,%edi
f010197e:	31 c0                	xor    %eax,%eax
f0101980:	89 fa                	mov    %edi,%edx
f0101982:	83 c4 1c             	add    $0x1c,%esp
f0101985:	5b                   	pop    %ebx
f0101986:	5e                   	pop    %esi
f0101987:	5f                   	pop    %edi
f0101988:	5d                   	pop    %ebp
f0101989:	c3                   	ret    
f010198a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101990:	0f bd fa             	bsr    %edx,%edi
f0101993:	83 f7 1f             	xor    $0x1f,%edi
f0101996:	75 48                	jne    f01019e0 <__udivdi3+0xa0>
f0101998:	39 f2                	cmp    %esi,%edx
f010199a:	72 06                	jb     f01019a2 <__udivdi3+0x62>
f010199c:	31 c0                	xor    %eax,%eax
f010199e:	39 eb                	cmp    %ebp,%ebx
f01019a0:	77 de                	ja     f0101980 <__udivdi3+0x40>
f01019a2:	b8 01 00 00 00       	mov    $0x1,%eax
f01019a7:	eb d7                	jmp    f0101980 <__udivdi3+0x40>
f01019a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019b0:	89 d9                	mov    %ebx,%ecx
f01019b2:	85 db                	test   %ebx,%ebx
f01019b4:	75 0b                	jne    f01019c1 <__udivdi3+0x81>
f01019b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01019bb:	31 d2                	xor    %edx,%edx
f01019bd:	f7 f3                	div    %ebx
f01019bf:	89 c1                	mov    %eax,%ecx
f01019c1:	31 d2                	xor    %edx,%edx
f01019c3:	89 f0                	mov    %esi,%eax
f01019c5:	f7 f1                	div    %ecx
f01019c7:	89 c6                	mov    %eax,%esi
f01019c9:	89 e8                	mov    %ebp,%eax
f01019cb:	89 f7                	mov    %esi,%edi
f01019cd:	f7 f1                	div    %ecx
f01019cf:	89 fa                	mov    %edi,%edx
f01019d1:	83 c4 1c             	add    $0x1c,%esp
f01019d4:	5b                   	pop    %ebx
f01019d5:	5e                   	pop    %esi
f01019d6:	5f                   	pop    %edi
f01019d7:	5d                   	pop    %ebp
f01019d8:	c3                   	ret    
f01019d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019e0:	89 f9                	mov    %edi,%ecx
f01019e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01019e7:	29 f8                	sub    %edi,%eax
f01019e9:	d3 e2                	shl    %cl,%edx
f01019eb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01019ef:	89 c1                	mov    %eax,%ecx
f01019f1:	89 da                	mov    %ebx,%edx
f01019f3:	d3 ea                	shr    %cl,%edx
f01019f5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01019f9:	09 d1                	or     %edx,%ecx
f01019fb:	89 f2                	mov    %esi,%edx
f01019fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a01:	89 f9                	mov    %edi,%ecx
f0101a03:	d3 e3                	shl    %cl,%ebx
f0101a05:	89 c1                	mov    %eax,%ecx
f0101a07:	d3 ea                	shr    %cl,%edx
f0101a09:	89 f9                	mov    %edi,%ecx
f0101a0b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101a0f:	89 eb                	mov    %ebp,%ebx
f0101a11:	d3 e6                	shl    %cl,%esi
f0101a13:	89 c1                	mov    %eax,%ecx
f0101a15:	d3 eb                	shr    %cl,%ebx
f0101a17:	09 de                	or     %ebx,%esi
f0101a19:	89 f0                	mov    %esi,%eax
f0101a1b:	f7 74 24 08          	divl   0x8(%esp)
f0101a1f:	89 d6                	mov    %edx,%esi
f0101a21:	89 c3                	mov    %eax,%ebx
f0101a23:	f7 64 24 0c          	mull   0xc(%esp)
f0101a27:	39 d6                	cmp    %edx,%esi
f0101a29:	72 15                	jb     f0101a40 <__udivdi3+0x100>
f0101a2b:	89 f9                	mov    %edi,%ecx
f0101a2d:	d3 e5                	shl    %cl,%ebp
f0101a2f:	39 c5                	cmp    %eax,%ebp
f0101a31:	73 04                	jae    f0101a37 <__udivdi3+0xf7>
f0101a33:	39 d6                	cmp    %edx,%esi
f0101a35:	74 09                	je     f0101a40 <__udivdi3+0x100>
f0101a37:	89 d8                	mov    %ebx,%eax
f0101a39:	31 ff                	xor    %edi,%edi
f0101a3b:	e9 40 ff ff ff       	jmp    f0101980 <__udivdi3+0x40>
f0101a40:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101a43:	31 ff                	xor    %edi,%edi
f0101a45:	e9 36 ff ff ff       	jmp    f0101980 <__udivdi3+0x40>
f0101a4a:	66 90                	xchg   %ax,%ax
f0101a4c:	66 90                	xchg   %ax,%ax
f0101a4e:	66 90                	xchg   %ax,%ax

f0101a50 <__umoddi3>:
f0101a50:	f3 0f 1e fb          	endbr32 
f0101a54:	55                   	push   %ebp
f0101a55:	57                   	push   %edi
f0101a56:	56                   	push   %esi
f0101a57:	53                   	push   %ebx
f0101a58:	83 ec 1c             	sub    $0x1c,%esp
f0101a5b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101a5f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101a63:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101a67:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101a6b:	85 c0                	test   %eax,%eax
f0101a6d:	75 19                	jne    f0101a88 <__umoddi3+0x38>
f0101a6f:	39 df                	cmp    %ebx,%edi
f0101a71:	76 5d                	jbe    f0101ad0 <__umoddi3+0x80>
f0101a73:	89 f0                	mov    %esi,%eax
f0101a75:	89 da                	mov    %ebx,%edx
f0101a77:	f7 f7                	div    %edi
f0101a79:	89 d0                	mov    %edx,%eax
f0101a7b:	31 d2                	xor    %edx,%edx
f0101a7d:	83 c4 1c             	add    $0x1c,%esp
f0101a80:	5b                   	pop    %ebx
f0101a81:	5e                   	pop    %esi
f0101a82:	5f                   	pop    %edi
f0101a83:	5d                   	pop    %ebp
f0101a84:	c3                   	ret    
f0101a85:	8d 76 00             	lea    0x0(%esi),%esi
f0101a88:	89 f2                	mov    %esi,%edx
f0101a8a:	39 d8                	cmp    %ebx,%eax
f0101a8c:	76 12                	jbe    f0101aa0 <__umoddi3+0x50>
f0101a8e:	89 f0                	mov    %esi,%eax
f0101a90:	89 da                	mov    %ebx,%edx
f0101a92:	83 c4 1c             	add    $0x1c,%esp
f0101a95:	5b                   	pop    %ebx
f0101a96:	5e                   	pop    %esi
f0101a97:	5f                   	pop    %edi
f0101a98:	5d                   	pop    %ebp
f0101a99:	c3                   	ret    
f0101a9a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101aa0:	0f bd e8             	bsr    %eax,%ebp
f0101aa3:	83 f5 1f             	xor    $0x1f,%ebp
f0101aa6:	75 50                	jne    f0101af8 <__umoddi3+0xa8>
f0101aa8:	39 d8                	cmp    %ebx,%eax
f0101aaa:	0f 82 e0 00 00 00    	jb     f0101b90 <__umoddi3+0x140>
f0101ab0:	89 d9                	mov    %ebx,%ecx
f0101ab2:	39 f7                	cmp    %esi,%edi
f0101ab4:	0f 86 d6 00 00 00    	jbe    f0101b90 <__umoddi3+0x140>
f0101aba:	89 d0                	mov    %edx,%eax
f0101abc:	89 ca                	mov    %ecx,%edx
f0101abe:	83 c4 1c             	add    $0x1c,%esp
f0101ac1:	5b                   	pop    %ebx
f0101ac2:	5e                   	pop    %esi
f0101ac3:	5f                   	pop    %edi
f0101ac4:	5d                   	pop    %ebp
f0101ac5:	c3                   	ret    
f0101ac6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101acd:	8d 76 00             	lea    0x0(%esi),%esi
f0101ad0:	89 fd                	mov    %edi,%ebp
f0101ad2:	85 ff                	test   %edi,%edi
f0101ad4:	75 0b                	jne    f0101ae1 <__umoddi3+0x91>
f0101ad6:	b8 01 00 00 00       	mov    $0x1,%eax
f0101adb:	31 d2                	xor    %edx,%edx
f0101add:	f7 f7                	div    %edi
f0101adf:	89 c5                	mov    %eax,%ebp
f0101ae1:	89 d8                	mov    %ebx,%eax
f0101ae3:	31 d2                	xor    %edx,%edx
f0101ae5:	f7 f5                	div    %ebp
f0101ae7:	89 f0                	mov    %esi,%eax
f0101ae9:	f7 f5                	div    %ebp
f0101aeb:	89 d0                	mov    %edx,%eax
f0101aed:	31 d2                	xor    %edx,%edx
f0101aef:	eb 8c                	jmp    f0101a7d <__umoddi3+0x2d>
f0101af1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101af8:	89 e9                	mov    %ebp,%ecx
f0101afa:	ba 20 00 00 00       	mov    $0x20,%edx
f0101aff:	29 ea                	sub    %ebp,%edx
f0101b01:	d3 e0                	shl    %cl,%eax
f0101b03:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101b07:	89 d1                	mov    %edx,%ecx
f0101b09:	89 f8                	mov    %edi,%eax
f0101b0b:	d3 e8                	shr    %cl,%eax
f0101b0d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101b11:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101b15:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101b19:	09 c1                	or     %eax,%ecx
f0101b1b:	89 d8                	mov    %ebx,%eax
f0101b1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101b21:	89 e9                	mov    %ebp,%ecx
f0101b23:	d3 e7                	shl    %cl,%edi
f0101b25:	89 d1                	mov    %edx,%ecx
f0101b27:	d3 e8                	shr    %cl,%eax
f0101b29:	89 e9                	mov    %ebp,%ecx
f0101b2b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101b2f:	d3 e3                	shl    %cl,%ebx
f0101b31:	89 c7                	mov    %eax,%edi
f0101b33:	89 d1                	mov    %edx,%ecx
f0101b35:	89 f0                	mov    %esi,%eax
f0101b37:	d3 e8                	shr    %cl,%eax
f0101b39:	89 e9                	mov    %ebp,%ecx
f0101b3b:	89 fa                	mov    %edi,%edx
f0101b3d:	d3 e6                	shl    %cl,%esi
f0101b3f:	09 d8                	or     %ebx,%eax
f0101b41:	f7 74 24 08          	divl   0x8(%esp)
f0101b45:	89 d1                	mov    %edx,%ecx
f0101b47:	89 f3                	mov    %esi,%ebx
f0101b49:	f7 64 24 0c          	mull   0xc(%esp)
f0101b4d:	89 c6                	mov    %eax,%esi
f0101b4f:	89 d7                	mov    %edx,%edi
f0101b51:	39 d1                	cmp    %edx,%ecx
f0101b53:	72 06                	jb     f0101b5b <__umoddi3+0x10b>
f0101b55:	75 10                	jne    f0101b67 <__umoddi3+0x117>
f0101b57:	39 c3                	cmp    %eax,%ebx
f0101b59:	73 0c                	jae    f0101b67 <__umoddi3+0x117>
f0101b5b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f0101b5f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0101b63:	89 d7                	mov    %edx,%edi
f0101b65:	89 c6                	mov    %eax,%esi
f0101b67:	89 ca                	mov    %ecx,%edx
f0101b69:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b6e:	29 f3                	sub    %esi,%ebx
f0101b70:	19 fa                	sbb    %edi,%edx
f0101b72:	89 d0                	mov    %edx,%eax
f0101b74:	d3 e0                	shl    %cl,%eax
f0101b76:	89 e9                	mov    %ebp,%ecx
f0101b78:	d3 eb                	shr    %cl,%ebx
f0101b7a:	d3 ea                	shr    %cl,%edx
f0101b7c:	09 d8                	or     %ebx,%eax
f0101b7e:	83 c4 1c             	add    $0x1c,%esp
f0101b81:	5b                   	pop    %ebx
f0101b82:	5e                   	pop    %esi
f0101b83:	5f                   	pop    %edi
f0101b84:	5d                   	pop    %ebp
f0101b85:	c3                   	ret    
f0101b86:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b8d:	8d 76 00             	lea    0x0(%esi),%esi
f0101b90:	89 d9                	mov    %ebx,%ecx
f0101b92:	89 f2                	mov    %esi,%edx
f0101b94:	29 fa                	sub    %edi,%edx
f0101b96:	19 c1                	sbb    %eax,%ecx
f0101b98:	e9 1d ff ff ff       	jmp    f0101aba <__umoddi3+0x6a>
