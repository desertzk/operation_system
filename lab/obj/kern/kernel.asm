
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
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	# PE Protected Mode Enable PG Paging WP Write protect
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

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
# push   %ebp  mov    %esp,%ebp  是C语言进入函数的惯例 保存上一层函数栈指针ebp 然后再把这一层的 esp 赋值给 ebp (在函数运行期间将当前esp值复制到ebp中。)
# On entry to a C function, the function's prologue code normally saves the previous function's base pointer by pushing it onto the stack, and then copies the current esp value into ebp for the duration of the function.
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	e8 72 01 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f010004a:	81 c3 be 12 01 00    	add    $0x112be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 38 08 ff ff    	lea    -0xf7c8(%ebx),%eax
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
f010007d:	8d 83 54 08 ff ff    	lea    -0xf7ac(%ebx),%eax
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
f01000ca:	e8 0c 16 00 00       	call   f01016db <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 3f 05 00 00       	call   f0100613 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 6f 08 ff ff    	lea    -0xf791(%ebx),%eax
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
f0100145:	8d 83 8a 08 ff ff    	lea    -0xf776(%ebx),%eax
f010014b:	50                   	push   %eax
f010014c:	e8 ce 09 00 00       	call   f0100b1f <cprintf>
	vcprintf(fmt, ap);
f0100151:	83 c4 08             	add    $0x8,%esp
f0100154:	56                   	push   %esi
f0100155:	ff 75 10             	pushl  0x10(%ebp)
f0100158:	e8 8b 09 00 00       	call   f0100ae8 <vcprintf>
	cprintf("\n");
f010015d:	8d 83 c6 08 ff ff    	lea    -0xf73a(%ebx),%eax
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
f010018c:	8d 83 a2 08 ff ff    	lea    -0xf75e(%ebx),%eax
f0100192:	50                   	push   %eax
f0100193:	e8 87 09 00 00       	call   f0100b1f <cprintf>
	vcprintf(fmt, ap);
f0100198:	83 c4 08             	add    $0x8,%esp
f010019b:	56                   	push   %esi
f010019c:	ff 75 10             	pushl  0x10(%ebp)
f010019f:	e8 44 09 00 00       	call   f0100ae8 <vcprintf>
	cprintf("\n");
f01001a4:	8d 83 c6 08 ff ff    	lea    -0xf73a(%ebx),%eax
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
f0100290:	0f b6 84 13 f8 09 ff 	movzbl -0xf608(%ebx,%edx,1),%eax
f0100297:	ff 
f0100298:	0b 83 78 1d 00 00    	or     0x1d78(%ebx),%eax
	shift ^= togglecode[data];
f010029e:	0f b6 8c 13 f8 08 ff 	movzbl -0xf708(%ebx,%edx,1),%ecx
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
f01002fb:	0f b6 84 13 f8 09 ff 	movzbl -0xf608(%ebx,%edx,1),%eax
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
f0100337:	8d 83 bc 08 ff ff    	lea    -0xf744(%ebx),%eax
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
f0100548:	e8 d6 11 00 00       	call   f0101723 <memmove>
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
f0100721:	8d 83 c8 08 ff ff    	lea    -0xf738(%ebx),%eax
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
f0100774:	8d 83 f8 0a ff ff    	lea    -0xf508(%ebx),%eax
f010077a:	50                   	push   %eax
f010077b:	8d 83 16 0b ff ff    	lea    -0xf4ea(%ebx),%eax
f0100781:	50                   	push   %eax
f0100782:	8d b3 1b 0b ff ff    	lea    -0xf4e5(%ebx),%esi
f0100788:	56                   	push   %esi
f0100789:	e8 91 03 00 00       	call   f0100b1f <cprintf>
f010078e:	83 c4 0c             	add    $0xc,%esp
f0100791:	8d 83 d4 0b ff ff    	lea    -0xf42c(%ebx),%eax
f0100797:	50                   	push   %eax
f0100798:	8d 83 24 0b ff ff    	lea    -0xf4dc(%ebx),%eax
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
f01007c5:	8d 83 2d 0b ff ff    	lea    -0xf4d3(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 4e 03 00 00       	call   f0100b1f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007d1:	83 c4 08             	add    $0x8,%esp
f01007d4:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007da:	8d 83 fc 0b ff ff    	lea    -0xf404(%ebx),%eax
f01007e0:	50                   	push   %eax
f01007e1:	e8 39 03 00 00       	call   f0100b1f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e6:	83 c4 0c             	add    $0xc,%esp
f01007e9:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007ef:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007f5:	50                   	push   %eax
f01007f6:	57                   	push   %edi
f01007f7:	8d 83 24 0c ff ff    	lea    -0xf3dc(%ebx),%eax
f01007fd:	50                   	push   %eax
f01007fe:	e8 1c 03 00 00       	call   f0100b1f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100803:	83 c4 0c             	add    $0xc,%esp
f0100806:	c7 c0 2d 1b 10 f0    	mov    $0xf0101b2d,%eax
f010080c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100812:	52                   	push   %edx
f0100813:	50                   	push   %eax
f0100814:	8d 83 48 0c ff ff    	lea    -0xf3b8(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 ff 02 00 00       	call   f0100b1f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100820:	83 c4 0c             	add    $0xc,%esp
f0100823:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f0100829:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010082f:	52                   	push   %edx
f0100830:	50                   	push   %eax
f0100831:	8d 83 6c 0c ff ff    	lea    -0xf394(%ebx),%eax
f0100837:	50                   	push   %eax
f0100838:	e8 e2 02 00 00       	call   f0100b1f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010083d:	83 c4 0c             	add    $0xc,%esp
f0100840:	c7 c6 c0 36 11 f0    	mov    $0xf01136c0,%esi
f0100846:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010084c:	50                   	push   %eax
f010084d:	56                   	push   %esi
f010084e:	8d 83 90 0c ff ff    	lea    -0xf370(%ebx),%eax
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
f0100869:	8d 83 b4 0c ff ff    	lea    -0xf34c(%ebx),%eax
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
f0100896:	8d 83 46 0b ff ff    	lea    -0xf4ba(%ebx),%eax
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
f01008a6:	8d 83 56 0b ff ff    	lea    -0xf4aa(%ebx),%eax
f01008ac:	89 04 24             	mov    %eax,(%esp)
f01008af:	e8 6b 02 00 00       	call   f0100b1f <cprintf>
    while (ebp) {
f01008b4:	83 c4 10             	add    $0x10,%esp
      uint32_t eip = ebp[1];
      cprintf("ebp %x  eip %x  args", ebp, eip);
f01008b7:	8d 83 68 0b ff ff    	lea    -0xf498(%ebx),%eax
f01008bd:	89 45 b8             	mov    %eax,-0x48(%ebp)
      int i;
      for (i = 2; i <= 6; ++i)
        cprintf(" %08.x", ebp[i]);
f01008c0:	8d 83 7d 0b ff ff    	lea    -0xf483(%ebx),%eax
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
f010090c:	8d 83 c6 08 ff ff    	lea    -0xf73a(%ebx),%eax
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
f010093d:	8d 83 84 0b ff ff    	lea    -0xf47c(%ebx),%eax
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
f0100977:	8d 83 e0 0c ff ff    	lea    -0xf320(%ebx),%eax
f010097d:	50                   	push   %eax
f010097e:	e8 9c 01 00 00       	call   f0100b1f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100983:	8d 83 04 0d ff ff    	lea    -0xf2fc(%ebx),%eax
f0100989:	89 04 24             	mov    %eax,(%esp)
f010098c:	e8 8e 01 00 00       	call   f0100b1f <cprintf>
f0100991:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100994:	8d bb 99 0b ff ff    	lea    -0xf467(%ebx),%edi
f010099a:	eb 4a                	jmp    f01009e6 <monitor+0x83>
f010099c:	83 ec 08             	sub    $0x8,%esp
f010099f:	0f be c0             	movsbl %al,%eax
f01009a2:	50                   	push   %eax
f01009a3:	57                   	push   %edi
f01009a4:	e8 f3 0c 00 00       	call   f010169c <strchr>
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
f01009d7:	8d 83 9e 0b ff ff    	lea    -0xf462(%ebx),%eax
f01009dd:	50                   	push   %eax
f01009de:	e8 3c 01 00 00       	call   f0100b1f <cprintf>
			return 0;
f01009e3:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009e6:	8d 83 95 0b ff ff    	lea    -0xf46b(%ebx),%eax
f01009ec:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009ef:	83 ec 0c             	sub    $0xc,%esp
f01009f2:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009f5:	e8 4f 0a 00 00       	call   f0101449 <readline>
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
f0100a25:	e8 72 0c 00 00       	call   f010169c <strchr>
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
f0100a4e:	8d 83 16 0b ff ff    	lea    -0xf4ea(%ebx),%eax
f0100a54:	50                   	push   %eax
f0100a55:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a58:	e8 df 0b 00 00       	call   f010163c <strcmp>
f0100a5d:	83 c4 10             	add    $0x10,%esp
f0100a60:	85 c0                	test   %eax,%eax
f0100a62:	74 38                	je     f0100a9c <monitor+0x139>
f0100a64:	83 ec 08             	sub    $0x8,%esp
f0100a67:	8d 83 24 0b ff ff    	lea    -0xf4dc(%ebx),%eax
f0100a6d:	50                   	push   %eax
f0100a6e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a71:	e8 c6 0b 00 00       	call   f010163c <strcmp>
f0100a76:	83 c4 10             	add    $0x10,%esp
f0100a79:	85 c0                	test   %eax,%eax
f0100a7b:	74 1a                	je     f0100a97 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a7d:	83 ec 08             	sub    $0x8,%esp
f0100a80:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a83:	8d 83 bb 0b ff ff    	lea    -0xf445(%ebx),%eax
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
f0100b12:	e8 17 04 00 00       	call   f0100f2e <vprintfmt>
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
f0100c2e:	83 ec 2c             	sub    $0x2c,%esp
f0100c31:	e8 fc 01 00 00       	call   f0100e32 <__x86.get_pc_thunk.cx>
f0100c36:	81 c1 d2 06 01 00    	add    $0x106d2,%ecx
f0100c3c:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100c3f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100c42:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c45:	8d 81 29 0d ff ff    	lea    -0xf2d7(%ecx),%eax
f0100c4b:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100c4d:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100c54:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100c57:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100c5e:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100c61:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c68:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100c6e:	0f 86 f4 00 00 00    	jbe    f0100d68 <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c74:	c7 c0 65 5b 10 f0    	mov    $0xf0105b65,%eax
f0100c7a:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100c80:	0f 86 88 01 00 00    	jbe    f0100e0e <debuginfo_eip+0x1e6>
f0100c86:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100c89:	c7 c0 8d 71 10 f0    	mov    $0xf010718d,%eax
f0100c8f:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100c93:	0f 85 7c 01 00 00    	jne    f0100e15 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c99:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ca0:	c7 c0 4c 22 10 f0    	mov    $0xf010224c,%eax
f0100ca6:	c7 c2 64 5b 10 f0    	mov    $0xf0105b64,%edx
f0100cac:	29 c2                	sub    %eax,%edx
f0100cae:	c1 fa 02             	sar    $0x2,%edx
f0100cb1:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100cb7:	83 ea 01             	sub    $0x1,%edx
f0100cba:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100cbd:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100cc0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100cc3:	83 ec 08             	sub    $0x8,%esp
f0100cc6:	53                   	push   %ebx
f0100cc7:	6a 64                	push   $0x64
f0100cc9:	e8 65 fe ff ff       	call   f0100b33 <stab_binsearch>
	if (lfile == 0)
f0100cce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cd1:	83 c4 10             	add    $0x10,%esp
f0100cd4:	85 c0                	test   %eax,%eax
f0100cd6:	0f 84 40 01 00 00    	je     f0100e1c <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100cdc:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100cdf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ce2:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ce5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ce8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ceb:	83 ec 08             	sub    $0x8,%esp
f0100cee:	53                   	push   %ebx
f0100cef:	6a 24                	push   $0x24
f0100cf1:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100cf4:	c7 c0 4c 22 10 f0    	mov    $0xf010224c,%eax
f0100cfa:	e8 34 fe ff ff       	call   f0100b33 <stab_binsearch>

	if (lfun <= rfun) {
f0100cff:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100d02:	83 c4 10             	add    $0x10,%esp
f0100d05:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100d08:	7f 79                	jg     f0100d83 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100d0a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100d0d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d10:	c7 c2 4c 22 10 f0    	mov    $0xf010224c,%edx
f0100d16:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100d19:	8b 11                	mov    (%ecx),%edx
f0100d1b:	c7 c0 8d 71 10 f0    	mov    $0xf010718d,%eax
f0100d21:	81 e8 65 5b 10 f0    	sub    $0xf0105b65,%eax
f0100d27:	39 c2                	cmp    %eax,%edx
f0100d29:	73 09                	jae    f0100d34 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d2b:	81 c2 65 5b 10 f0    	add    $0xf0105b65,%edx
f0100d31:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d34:	8b 41 08             	mov    0x8(%ecx),%eax
f0100d37:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d3a:	83 ec 08             	sub    $0x8,%esp
f0100d3d:	6a 3a                	push   $0x3a
f0100d3f:	ff 77 08             	pushl  0x8(%edi)
f0100d42:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d45:	e8 75 09 00 00       	call   f01016bf <strfind>
f0100d4a:	2b 47 08             	sub    0x8(%edi),%eax
f0100d4d:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d50:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d53:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100d56:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100d59:	c7 c2 4c 22 10 f0    	mov    $0xf010224c,%edx
f0100d5f:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100d63:	83 c4 10             	add    $0x10,%esp
f0100d66:	eb 29                	jmp    f0100d91 <debuginfo_eip+0x169>
  	        panic("User address");
f0100d68:	83 ec 04             	sub    $0x4,%esp
f0100d6b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d6e:	8d 83 33 0d ff ff    	lea    -0xf2cd(%ebx),%eax
f0100d74:	50                   	push   %eax
f0100d75:	6a 7f                	push   $0x7f
f0100d77:	8d 83 40 0d ff ff    	lea    -0xf2c0(%ebx),%eax
f0100d7d:	50                   	push   %eax
f0100d7e:	e8 83 f3 ff ff       	call   f0100106 <_panic>
		info->eip_fn_addr = addr;
f0100d83:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100d86:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100d89:	eb af                	jmp    f0100d3a <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100d8b:	83 ee 01             	sub    $0x1,%esi
f0100d8e:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100d91:	39 f3                	cmp    %esi,%ebx
f0100d93:	7f 3a                	jg     f0100dcf <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100d95:	0f b6 10             	movzbl (%eax),%edx
f0100d98:	80 fa 84             	cmp    $0x84,%dl
f0100d9b:	74 0b                	je     f0100da8 <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d9d:	80 fa 64             	cmp    $0x64,%dl
f0100da0:	75 e9                	jne    f0100d8b <debuginfo_eip+0x163>
f0100da2:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100da6:	74 e3                	je     f0100d8b <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100da8:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100dab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100dae:	c7 c0 4c 22 10 f0    	mov    $0xf010224c,%eax
f0100db4:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100db7:	c7 c0 8d 71 10 f0    	mov    $0xf010718d,%eax
f0100dbd:	81 e8 65 5b 10 f0    	sub    $0xf0105b65,%eax
f0100dc3:	39 c2                	cmp    %eax,%edx
f0100dc5:	73 08                	jae    f0100dcf <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100dc7:	81 c2 65 5b 10 f0    	add    $0xf0105b65,%edx
f0100dcd:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100dcf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100dd2:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dd5:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0100dda:	39 c8                	cmp    %ecx,%eax
f0100ddc:	7d 4a                	jge    f0100e28 <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100dde:	8d 50 01             	lea    0x1(%eax),%edx
f0100de1:	8d 1c 40             	lea    (%eax,%eax,2),%ebx
f0100de4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100de7:	c7 c0 4c 22 10 f0    	mov    $0xf010224c,%eax
f0100ded:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100df1:	eb 07                	jmp    f0100dfa <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100df3:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100df7:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100dfa:	39 d1                	cmp    %edx,%ecx
f0100dfc:	74 25                	je     f0100e23 <debuginfo_eip+0x1fb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100dfe:	83 c0 0c             	add    $0xc,%eax
f0100e01:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100e05:	74 ec                	je     f0100df3 <debuginfo_eip+0x1cb>
	return 0;
f0100e07:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e0c:	eb 1a                	jmp    f0100e28 <debuginfo_eip+0x200>
		return -1;
f0100e0e:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100e13:	eb 13                	jmp    f0100e28 <debuginfo_eip+0x200>
f0100e15:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100e1a:	eb 0c                	jmp    f0100e28 <debuginfo_eip+0x200>
		return -1;
f0100e1c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100e21:	eb 05                	jmp    f0100e28 <debuginfo_eip+0x200>
	return 0;
f0100e23:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e28:	89 d0                	mov    %edx,%eax
f0100e2a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e2d:	5b                   	pop    %ebx
f0100e2e:	5e                   	pop    %esi
f0100e2f:	5f                   	pop    %edi
f0100e30:	5d                   	pop    %ebp
f0100e31:	c3                   	ret    

f0100e32 <__x86.get_pc_thunk.cx>:
f0100e32:	8b 0c 24             	mov    (%esp),%ecx
f0100e35:	c3                   	ret    

f0100e36 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e36:	55                   	push   %ebp
f0100e37:	89 e5                	mov    %esp,%ebp
f0100e39:	57                   	push   %edi
f0100e3a:	56                   	push   %esi
f0100e3b:	53                   	push   %ebx
f0100e3c:	83 ec 2c             	sub    $0x2c,%esp
f0100e3f:	e8 ee ff ff ff       	call   f0100e32 <__x86.get_pc_thunk.cx>
f0100e44:	81 c1 c4 04 01 00    	add    $0x104c4,%ecx
f0100e4a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100e4d:	89 c7                	mov    %eax,%edi
f0100e4f:	89 d6                	mov    %edx,%esi
f0100e51:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e54:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100e57:	89 d1                	mov    %edx,%ecx
f0100e59:	89 c2                	mov    %eax,%edx
f0100e5b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e5e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100e61:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e64:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e67:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e6a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100e71:	39 c2                	cmp    %eax,%edx
f0100e73:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0100e76:	72 41                	jb     f0100eb9 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100e78:	83 ec 0c             	sub    $0xc,%esp
f0100e7b:	ff 75 18             	pushl  0x18(%ebp)
f0100e7e:	83 eb 01             	sub    $0x1,%ebx
f0100e81:	53                   	push   %ebx
f0100e82:	50                   	push   %eax
f0100e83:	83 ec 08             	sub    $0x8,%esp
f0100e86:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100e89:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e8c:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100e8f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e92:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100e95:	e8 36 0a 00 00       	call   f01018d0 <__udivdi3>
f0100e9a:	83 c4 18             	add    $0x18,%esp
f0100e9d:	52                   	push   %edx
f0100e9e:	50                   	push   %eax
f0100e9f:	89 f2                	mov    %esi,%edx
f0100ea1:	89 f8                	mov    %edi,%eax
f0100ea3:	e8 8e ff ff ff       	call   f0100e36 <printnum>
f0100ea8:	83 c4 20             	add    $0x20,%esp
f0100eab:	eb 13                	jmp    f0100ec0 <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100ead:	83 ec 08             	sub    $0x8,%esp
f0100eb0:	56                   	push   %esi
f0100eb1:	ff 75 18             	pushl  0x18(%ebp)
f0100eb4:	ff d7                	call   *%edi
f0100eb6:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100eb9:	83 eb 01             	sub    $0x1,%ebx
f0100ebc:	85 db                	test   %ebx,%ebx
f0100ebe:	7f ed                	jg     f0100ead <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ec0:	83 ec 08             	sub    $0x8,%esp
f0100ec3:	56                   	push   %esi
f0100ec4:	83 ec 04             	sub    $0x4,%esp
f0100ec7:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100eca:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ecd:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100ed0:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ed3:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100ed6:	e8 05 0b 00 00       	call   f01019e0 <__umoddi3>
f0100edb:	83 c4 14             	add    $0x14,%esp
f0100ede:	0f be 84 03 4e 0d ff 	movsbl -0xf2b2(%ebx,%eax,1),%eax
f0100ee5:	ff 
f0100ee6:	50                   	push   %eax
f0100ee7:	ff d7                	call   *%edi
}
f0100ee9:	83 c4 10             	add    $0x10,%esp
f0100eec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100eef:	5b                   	pop    %ebx
f0100ef0:	5e                   	pop    %esi
f0100ef1:	5f                   	pop    %edi
f0100ef2:	5d                   	pop    %ebp
f0100ef3:	c3                   	ret    

f0100ef4 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ef4:	55                   	push   %ebp
f0100ef5:	89 e5                	mov    %esp,%ebp
f0100ef7:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100efa:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100efe:	8b 10                	mov    (%eax),%edx
f0100f00:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f03:	73 0a                	jae    f0100f0f <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f05:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100f08:	89 08                	mov    %ecx,(%eax)
f0100f0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f0d:	88 02                	mov    %al,(%edx)
}
f0100f0f:	5d                   	pop    %ebp
f0100f10:	c3                   	ret    

f0100f11 <printfmt>:
{
f0100f11:	55                   	push   %ebp
f0100f12:	89 e5                	mov    %esp,%ebp
f0100f14:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100f17:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f1a:	50                   	push   %eax
f0100f1b:	ff 75 10             	pushl  0x10(%ebp)
f0100f1e:	ff 75 0c             	pushl  0xc(%ebp)
f0100f21:	ff 75 08             	pushl  0x8(%ebp)
f0100f24:	e8 05 00 00 00       	call   f0100f2e <vprintfmt>
}
f0100f29:	83 c4 10             	add    $0x10,%esp
f0100f2c:	c9                   	leave  
f0100f2d:	c3                   	ret    

f0100f2e <vprintfmt>:
{
f0100f2e:	55                   	push   %ebp
f0100f2f:	89 e5                	mov    %esp,%ebp
f0100f31:	57                   	push   %edi
f0100f32:	56                   	push   %esi
f0100f33:	53                   	push   %ebx
f0100f34:	83 ec 3c             	sub    $0x3c,%esp
f0100f37:	e8 1d f8 ff ff       	call   f0100759 <__x86.get_pc_thunk.ax>
f0100f3c:	05 cc 03 01 00       	add    $0x103cc,%eax
f0100f41:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f44:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f47:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100f4a:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f4d:	8d 80 20 1d 00 00    	lea    0x1d20(%eax),%eax
f0100f53:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100f56:	eb 0a                	jmp    f0100f62 <vprintfmt+0x34>
			putch(ch, putdat);
f0100f58:	83 ec 08             	sub    $0x8,%esp
f0100f5b:	57                   	push   %edi
f0100f5c:	50                   	push   %eax
f0100f5d:	ff d6                	call   *%esi
f0100f5f:	83 c4 10             	add    $0x10,%esp
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f62:	83 c3 01             	add    $0x1,%ebx
f0100f65:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0100f69:	83 f8 25             	cmp    $0x25,%eax
f0100f6c:	74 0c                	je     f0100f7a <vprintfmt+0x4c>
			if (ch == '\0')
f0100f6e:	85 c0                	test   %eax,%eax
f0100f70:	75 e6                	jne    f0100f58 <vprintfmt+0x2a>
}
f0100f72:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f75:	5b                   	pop    %ebx
f0100f76:	5e                   	pop    %esi
f0100f77:	5f                   	pop    %edi
f0100f78:	5d                   	pop    %ebp
f0100f79:	c3                   	ret    
		padc = ' ';
f0100f7a:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f0100f7e:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f0100f85:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0100f8c:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f0100f93:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f98:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100f9b:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f9e:	8d 43 01             	lea    0x1(%ebx),%eax
f0100fa1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fa4:	0f b6 13             	movzbl (%ebx),%edx
f0100fa7:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100faa:	3c 55                	cmp    $0x55,%al
f0100fac:	0f 87 fb 03 00 00    	ja     f01013ad <.L20>
f0100fb2:	0f b6 c0             	movzbl %al,%eax
f0100fb5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100fb8:	89 ce                	mov    %ecx,%esi
f0100fba:	03 b4 81 dc 0d ff ff 	add    -0xf224(%ecx,%eax,4),%esi
f0100fc1:	ff e6                	jmp    *%esi

f0100fc3 <.L68>:
f0100fc3:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f0100fc6:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f0100fca:	eb d2                	jmp    f0100f9e <vprintfmt+0x70>

f0100fcc <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0100fcc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100fcf:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f0100fd3:	eb c9                	jmp    f0100f9e <vprintfmt+0x70>

f0100fd5 <.L31>:
f0100fd5:	0f b6 d2             	movzbl %dl,%edx
f0100fd8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0100fdb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fe0:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0100fe3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100fe6:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100fea:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0100fed:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100ff0:	83 f9 09             	cmp    $0x9,%ecx
f0100ff3:	77 58                	ja     f010104d <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0100ff5:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0100ff8:	eb e9                	jmp    f0100fe3 <.L31+0xe>

f0100ffa <.L34>:
			precision = va_arg(ap, int);
f0100ffa:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ffd:	8b 00                	mov    (%eax),%eax
f0100fff:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101002:	8b 45 14             	mov    0x14(%ebp),%eax
f0101005:	8d 40 04             	lea    0x4(%eax),%eax
f0101008:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010100b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f010100e:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101012:	79 8a                	jns    f0100f9e <vprintfmt+0x70>
				width = precision, precision = -1;
f0101014:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101017:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010101a:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0101021:	e9 78 ff ff ff       	jmp    f0100f9e <vprintfmt+0x70>

f0101026 <.L33>:
f0101026:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101029:	85 c0                	test   %eax,%eax
f010102b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101030:	0f 49 d0             	cmovns %eax,%edx
f0101033:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101036:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0101039:	e9 60 ff ff ff       	jmp    f0100f9e <vprintfmt+0x70>

f010103e <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f010103e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0101041:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0101048:	e9 51 ff ff ff       	jmp    f0100f9e <vprintfmt+0x70>
f010104d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101050:	89 75 08             	mov    %esi,0x8(%ebp)
f0101053:	eb b9                	jmp    f010100e <.L34+0x14>

f0101055 <.L27>:
			lflag++;
f0101055:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101059:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f010105c:	e9 3d ff ff ff       	jmp    f0100f9e <vprintfmt+0x70>

f0101061 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101061:	8b 75 08             	mov    0x8(%ebp),%esi
f0101064:	8b 45 14             	mov    0x14(%ebp),%eax
f0101067:	8d 58 04             	lea    0x4(%eax),%ebx
f010106a:	83 ec 08             	sub    $0x8,%esp
f010106d:	57                   	push   %edi
f010106e:	ff 30                	pushl  (%eax)
f0101070:	ff d6                	call   *%esi
			break;
f0101072:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0101075:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f0101078:	e9 c6 02 00 00       	jmp    f0101343 <.L25+0x45>

f010107d <.L28>:
			err = va_arg(ap, int);
f010107d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101080:	8b 45 14             	mov    0x14(%ebp),%eax
f0101083:	8d 58 04             	lea    0x4(%eax),%ebx
f0101086:	8b 00                	mov    (%eax),%eax
f0101088:	99                   	cltd   
f0101089:	31 d0                	xor    %edx,%eax
f010108b:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010108d:	83 f8 06             	cmp    $0x6,%eax
f0101090:	7f 27                	jg     f01010b9 <.L28+0x3c>
f0101092:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0101095:	8b 14 82             	mov    (%edx,%eax,4),%edx
f0101098:	85 d2                	test   %edx,%edx
f010109a:	74 1d                	je     f01010b9 <.L28+0x3c>
				printfmt(putch, putdat, "%s", p);
f010109c:	52                   	push   %edx
f010109d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010a0:	8d 80 6f 0d ff ff    	lea    -0xf291(%eax),%eax
f01010a6:	50                   	push   %eax
f01010a7:	57                   	push   %edi
f01010a8:	56                   	push   %esi
f01010a9:	e8 63 fe ff ff       	call   f0100f11 <printfmt>
f01010ae:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010b1:	89 5d 14             	mov    %ebx,0x14(%ebp)
f01010b4:	e9 8a 02 00 00       	jmp    f0101343 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f01010b9:	50                   	push   %eax
f01010ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010bd:	8d 80 66 0d ff ff    	lea    -0xf29a(%eax),%eax
f01010c3:	50                   	push   %eax
f01010c4:	57                   	push   %edi
f01010c5:	56                   	push   %esi
f01010c6:	e8 46 fe ff ff       	call   f0100f11 <printfmt>
f01010cb:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010ce:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01010d1:	e9 6d 02 00 00       	jmp    f0101343 <.L25+0x45>

f01010d6 <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f01010d6:	8b 75 08             	mov    0x8(%ebp),%esi
f01010d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01010dc:	83 c0 04             	add    $0x4,%eax
f01010df:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01010e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e5:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f01010e7:	85 d2                	test   %edx,%edx
f01010e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010ec:	8d 80 5f 0d ff ff    	lea    -0xf2a1(%eax),%eax
f01010f2:	0f 45 c2             	cmovne %edx,%eax
f01010f5:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f01010f8:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01010fc:	7e 06                	jle    f0101104 <.L24+0x2e>
f01010fe:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f0101102:	75 0d                	jne    f0101111 <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101104:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0101107:	89 c3                	mov    %eax,%ebx
f0101109:	03 45 d4             	add    -0x2c(%ebp),%eax
f010110c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010110f:	eb 58                	jmp    f0101169 <.L24+0x93>
f0101111:	83 ec 08             	sub    $0x8,%esp
f0101114:	ff 75 d8             	pushl  -0x28(%ebp)
f0101117:	ff 75 c8             	pushl  -0x38(%ebp)
f010111a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010111d:	e8 44 04 00 00       	call   f0101566 <strnlen>
f0101122:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101125:	29 c2                	sub    %eax,%edx
f0101127:	89 55 bc             	mov    %edx,-0x44(%ebp)
f010112a:	83 c4 10             	add    $0x10,%esp
f010112d:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f010112f:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0101133:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101136:	eb 0f                	jmp    f0101147 <.L24+0x71>
					putch(padc, putdat);
f0101138:	83 ec 08             	sub    $0x8,%esp
f010113b:	57                   	push   %edi
f010113c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010113f:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101141:	83 eb 01             	sub    $0x1,%ebx
f0101144:	83 c4 10             	add    $0x10,%esp
f0101147:	85 db                	test   %ebx,%ebx
f0101149:	7f ed                	jg     f0101138 <.L24+0x62>
f010114b:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010114e:	85 d2                	test   %edx,%edx
f0101150:	b8 00 00 00 00       	mov    $0x0,%eax
f0101155:	0f 49 c2             	cmovns %edx,%eax
f0101158:	29 c2                	sub    %eax,%edx
f010115a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010115d:	eb a5                	jmp    f0101104 <.L24+0x2e>
					putch(ch, putdat);
f010115f:	83 ec 08             	sub    $0x8,%esp
f0101162:	57                   	push   %edi
f0101163:	52                   	push   %edx
f0101164:	ff d6                	call   *%esi
f0101166:	83 c4 10             	add    $0x10,%esp
f0101169:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010116c:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010116e:	83 c3 01             	add    $0x1,%ebx
f0101171:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0101175:	0f be d0             	movsbl %al,%edx
f0101178:	85 d2                	test   %edx,%edx
f010117a:	74 4b                	je     f01011c7 <.L24+0xf1>
f010117c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101180:	78 06                	js     f0101188 <.L24+0xb2>
f0101182:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f0101186:	78 1e                	js     f01011a6 <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f0101188:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f010118c:	74 d1                	je     f010115f <.L24+0x89>
f010118e:	0f be c0             	movsbl %al,%eax
f0101191:	83 e8 20             	sub    $0x20,%eax
f0101194:	83 f8 5e             	cmp    $0x5e,%eax
f0101197:	76 c6                	jbe    f010115f <.L24+0x89>
					putch('?', putdat);
f0101199:	83 ec 08             	sub    $0x8,%esp
f010119c:	57                   	push   %edi
f010119d:	6a 3f                	push   $0x3f
f010119f:	ff d6                	call   *%esi
f01011a1:	83 c4 10             	add    $0x10,%esp
f01011a4:	eb c3                	jmp    f0101169 <.L24+0x93>
f01011a6:	89 cb                	mov    %ecx,%ebx
f01011a8:	eb 0e                	jmp    f01011b8 <.L24+0xe2>
				putch(' ', putdat);
f01011aa:	83 ec 08             	sub    $0x8,%esp
f01011ad:	57                   	push   %edi
f01011ae:	6a 20                	push   $0x20
f01011b0:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01011b2:	83 eb 01             	sub    $0x1,%ebx
f01011b5:	83 c4 10             	add    $0x10,%esp
f01011b8:	85 db                	test   %ebx,%ebx
f01011ba:	7f ee                	jg     f01011aa <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f01011bc:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01011bf:	89 45 14             	mov    %eax,0x14(%ebp)
f01011c2:	e9 7c 01 00 00       	jmp    f0101343 <.L25+0x45>
f01011c7:	89 cb                	mov    %ecx,%ebx
f01011c9:	eb ed                	jmp    f01011b8 <.L24+0xe2>

f01011cb <.L29>:
	if (lflag >= 2)
f01011cb:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01011ce:	8b 75 08             	mov    0x8(%ebp),%esi
f01011d1:	83 f9 01             	cmp    $0x1,%ecx
f01011d4:	7f 1b                	jg     f01011f1 <.L29+0x26>
	else if (lflag)
f01011d6:	85 c9                	test   %ecx,%ecx
f01011d8:	74 63                	je     f010123d <.L29+0x72>
		return va_arg(*ap, long);
f01011da:	8b 45 14             	mov    0x14(%ebp),%eax
f01011dd:	8b 00                	mov    (%eax),%eax
f01011df:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011e2:	99                   	cltd   
f01011e3:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e9:	8d 40 04             	lea    0x4(%eax),%eax
f01011ec:	89 45 14             	mov    %eax,0x14(%ebp)
f01011ef:	eb 17                	jmp    f0101208 <.L29+0x3d>
		return va_arg(*ap, long long);
f01011f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f4:	8b 50 04             	mov    0x4(%eax),%edx
f01011f7:	8b 00                	mov    (%eax),%eax
f01011f9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011fc:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101202:	8d 40 08             	lea    0x8(%eax),%eax
f0101205:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101208:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010120b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010120e:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0101213:	85 c9                	test   %ecx,%ecx
f0101215:	0f 89 0e 01 00 00    	jns    f0101329 <.L25+0x2b>
				putch('-', putdat);
f010121b:	83 ec 08             	sub    $0x8,%esp
f010121e:	57                   	push   %edi
f010121f:	6a 2d                	push   $0x2d
f0101221:	ff d6                	call   *%esi
				num = -(long long) num;
f0101223:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101226:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101229:	f7 da                	neg    %edx
f010122b:	83 d1 00             	adc    $0x0,%ecx
f010122e:	f7 d9                	neg    %ecx
f0101230:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101233:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101238:	e9 ec 00 00 00       	jmp    f0101329 <.L25+0x2b>
		return va_arg(*ap, int);
f010123d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101240:	8b 00                	mov    (%eax),%eax
f0101242:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101245:	99                   	cltd   
f0101246:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101249:	8b 45 14             	mov    0x14(%ebp),%eax
f010124c:	8d 40 04             	lea    0x4(%eax),%eax
f010124f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101252:	eb b4                	jmp    f0101208 <.L29+0x3d>

f0101254 <.L23>:
	if (lflag >= 2)
f0101254:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101257:	8b 75 08             	mov    0x8(%ebp),%esi
f010125a:	83 f9 01             	cmp    $0x1,%ecx
f010125d:	7f 1e                	jg     f010127d <.L23+0x29>
	else if (lflag)
f010125f:	85 c9                	test   %ecx,%ecx
f0101261:	74 32                	je     f0101295 <.L23+0x41>
		return va_arg(*ap, unsigned long);
f0101263:	8b 45 14             	mov    0x14(%ebp),%eax
f0101266:	8b 10                	mov    (%eax),%edx
f0101268:	b9 00 00 00 00       	mov    $0x0,%ecx
f010126d:	8d 40 04             	lea    0x4(%eax),%eax
f0101270:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101273:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f0101278:	e9 ac 00 00 00       	jmp    f0101329 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f010127d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101280:	8b 10                	mov    (%eax),%edx
f0101282:	8b 48 04             	mov    0x4(%eax),%ecx
f0101285:	8d 40 08             	lea    0x8(%eax),%eax
f0101288:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010128b:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f0101290:	e9 94 00 00 00       	jmp    f0101329 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0101295:	8b 45 14             	mov    0x14(%ebp),%eax
f0101298:	8b 10                	mov    (%eax),%edx
f010129a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010129f:	8d 40 04             	lea    0x4(%eax),%eax
f01012a2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012a5:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f01012aa:	eb 7d                	jmp    f0101329 <.L25+0x2b>

f01012ac <.L26>:
	if (lflag >= 2)
f01012ac:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01012af:	8b 75 08             	mov    0x8(%ebp),%esi
f01012b2:	83 f9 01             	cmp    $0x1,%ecx
f01012b5:	7f 1b                	jg     f01012d2 <.L26+0x26>
	else if (lflag)
f01012b7:	85 c9                	test   %ecx,%ecx
f01012b9:	74 2c                	je     f01012e7 <.L26+0x3b>
		return va_arg(*ap, unsigned long);
f01012bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01012be:	8b 10                	mov    (%eax),%edx
f01012c0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012c5:	8d 40 04             	lea    0x4(%eax),%eax
f01012c8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01012cb:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f01012d0:	eb 57                	jmp    f0101329 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01012d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01012d5:	8b 10                	mov    (%eax),%edx
f01012d7:	8b 48 04             	mov    0x4(%eax),%ecx
f01012da:	8d 40 08             	lea    0x8(%eax),%eax
f01012dd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01012e0:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f01012e5:	eb 42                	jmp    f0101329 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01012e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ea:	8b 10                	mov    (%eax),%edx
f01012ec:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012f1:	8d 40 04             	lea    0x4(%eax),%eax
f01012f4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01012f7:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f01012fc:	eb 2b                	jmp    f0101329 <.L25+0x2b>

f01012fe <.L25>:
			putch('0', putdat);
f01012fe:	8b 75 08             	mov    0x8(%ebp),%esi
f0101301:	83 ec 08             	sub    $0x8,%esp
f0101304:	57                   	push   %edi
f0101305:	6a 30                	push   $0x30
f0101307:	ff d6                	call   *%esi
			putch('x', putdat);
f0101309:	83 c4 08             	add    $0x8,%esp
f010130c:	57                   	push   %edi
f010130d:	6a 78                	push   $0x78
f010130f:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101311:	8b 45 14             	mov    0x14(%ebp),%eax
f0101314:	8b 10                	mov    (%eax),%edx
f0101316:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010131b:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010131e:	8d 40 04             	lea    0x4(%eax),%eax
f0101321:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101324:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101329:	83 ec 0c             	sub    $0xc,%esp
f010132c:	0f be 5d cf          	movsbl -0x31(%ebp),%ebx
f0101330:	53                   	push   %ebx
f0101331:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101334:	50                   	push   %eax
f0101335:	51                   	push   %ecx
f0101336:	52                   	push   %edx
f0101337:	89 fa                	mov    %edi,%edx
f0101339:	89 f0                	mov    %esi,%eax
f010133b:	e8 f6 fa ff ff       	call   f0100e36 <printnum>
			break;
f0101340:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101343:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101346:	e9 17 fc ff ff       	jmp    f0100f62 <vprintfmt+0x34>

f010134b <.L21>:
	if (lflag >= 2)
f010134b:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010134e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101351:	83 f9 01             	cmp    $0x1,%ecx
f0101354:	7f 1b                	jg     f0101371 <.L21+0x26>
	else if (lflag)
f0101356:	85 c9                	test   %ecx,%ecx
f0101358:	74 2c                	je     f0101386 <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f010135a:	8b 45 14             	mov    0x14(%ebp),%eax
f010135d:	8b 10                	mov    (%eax),%edx
f010135f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101364:	8d 40 04             	lea    0x4(%eax),%eax
f0101367:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010136a:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f010136f:	eb b8                	jmp    f0101329 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0101371:	8b 45 14             	mov    0x14(%ebp),%eax
f0101374:	8b 10                	mov    (%eax),%edx
f0101376:	8b 48 04             	mov    0x4(%eax),%ecx
f0101379:	8d 40 08             	lea    0x8(%eax),%eax
f010137c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010137f:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f0101384:	eb a3                	jmp    f0101329 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0101386:	8b 45 14             	mov    0x14(%ebp),%eax
f0101389:	8b 10                	mov    (%eax),%edx
f010138b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101390:	8d 40 04             	lea    0x4(%eax),%eax
f0101393:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101396:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f010139b:	eb 8c                	jmp    f0101329 <.L25+0x2b>

f010139d <.L35>:
			putch(ch, putdat);
f010139d:	8b 75 08             	mov    0x8(%ebp),%esi
f01013a0:	83 ec 08             	sub    $0x8,%esp
f01013a3:	57                   	push   %edi
f01013a4:	6a 25                	push   $0x25
f01013a6:	ff d6                	call   *%esi
			break;
f01013a8:	83 c4 10             	add    $0x10,%esp
f01013ab:	eb 96                	jmp    f0101343 <.L25+0x45>

f01013ad <.L20>:
			putch('%', putdat);
f01013ad:	8b 75 08             	mov    0x8(%ebp),%esi
f01013b0:	83 ec 08             	sub    $0x8,%esp
f01013b3:	57                   	push   %edi
f01013b4:	6a 25                	push   $0x25
f01013b6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01013b8:	83 c4 10             	add    $0x10,%esp
f01013bb:	89 d8                	mov    %ebx,%eax
f01013bd:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01013c1:	74 05                	je     f01013c8 <.L20+0x1b>
f01013c3:	83 e8 01             	sub    $0x1,%eax
f01013c6:	eb f5                	jmp    f01013bd <.L20+0x10>
f01013c8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013cb:	e9 73 ff ff ff       	jmp    f0101343 <.L25+0x45>

f01013d0 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01013d0:	55                   	push   %ebp
f01013d1:	89 e5                	mov    %esp,%ebp
f01013d3:	53                   	push   %ebx
f01013d4:	83 ec 14             	sub    $0x14,%esp
f01013d7:	e8 e0 ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01013dc:	81 c3 2c ff 00 00    	add    $0xff2c,%ebx
f01013e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e5:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01013e8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01013eb:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01013ef:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01013f2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01013f9:	85 c0                	test   %eax,%eax
f01013fb:	74 2b                	je     f0101428 <vsnprintf+0x58>
f01013fd:	85 d2                	test   %edx,%edx
f01013ff:	7e 27                	jle    f0101428 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101401:	ff 75 14             	pushl  0x14(%ebp)
f0101404:	ff 75 10             	pushl  0x10(%ebp)
f0101407:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010140a:	50                   	push   %eax
f010140b:	8d 83 ec fb fe ff    	lea    -0x10414(%ebx),%eax
f0101411:	50                   	push   %eax
f0101412:	e8 17 fb ff ff       	call   f0100f2e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101417:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010141a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010141d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101420:	83 c4 10             	add    $0x10,%esp
}
f0101423:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101426:	c9                   	leave  
f0101427:	c3                   	ret    
		return -E_INVAL;
f0101428:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010142d:	eb f4                	jmp    f0101423 <vsnprintf+0x53>

f010142f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010142f:	55                   	push   %ebp
f0101430:	89 e5                	mov    %esp,%ebp
f0101432:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101435:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101438:	50                   	push   %eax
f0101439:	ff 75 10             	pushl  0x10(%ebp)
f010143c:	ff 75 0c             	pushl  0xc(%ebp)
f010143f:	ff 75 08             	pushl  0x8(%ebp)
f0101442:	e8 89 ff ff ff       	call   f01013d0 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101447:	c9                   	leave  
f0101448:	c3                   	ret    

f0101449 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101449:	55                   	push   %ebp
f010144a:	89 e5                	mov    %esp,%ebp
f010144c:	57                   	push   %edi
f010144d:	56                   	push   %esi
f010144e:	53                   	push   %ebx
f010144f:	83 ec 1c             	sub    $0x1c,%esp
f0101452:	e8 65 ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0101457:	81 c3 b1 fe 00 00    	add    $0xfeb1,%ebx
f010145d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101460:	85 c0                	test   %eax,%eax
f0101462:	74 13                	je     f0101477 <readline+0x2e>
		cprintf("%s", prompt);
f0101464:	83 ec 08             	sub    $0x8,%esp
f0101467:	50                   	push   %eax
f0101468:	8d 83 6f 0d ff ff    	lea    -0xf291(%ebx),%eax
f010146e:	50                   	push   %eax
f010146f:	e8 ab f6 ff ff       	call   f0100b1f <cprintf>
f0101474:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101477:	83 ec 0c             	sub    $0xc,%esp
f010147a:	6a 00                	push   $0x0
f010147c:	e8 d2 f2 ff ff       	call   f0100753 <iscons>
f0101481:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101484:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101487:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f010148c:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f0101492:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101495:	eb 45                	jmp    f01014dc <readline+0x93>
			cprintf("read error: %e\n", c);
f0101497:	83 ec 08             	sub    $0x8,%esp
f010149a:	50                   	push   %eax
f010149b:	8d 83 34 0f ff ff    	lea    -0xf0cc(%ebx),%eax
f01014a1:	50                   	push   %eax
f01014a2:	e8 78 f6 ff ff       	call   f0100b1f <cprintf>
			return NULL;
f01014a7:	83 c4 10             	add    $0x10,%esp
f01014aa:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01014af:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014b2:	5b                   	pop    %ebx
f01014b3:	5e                   	pop    %esi
f01014b4:	5f                   	pop    %edi
f01014b5:	5d                   	pop    %ebp
f01014b6:	c3                   	ret    
			if (echoing)
f01014b7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014bb:	75 05                	jne    f01014c2 <readline+0x79>
			i--;
f01014bd:	83 ef 01             	sub    $0x1,%edi
f01014c0:	eb 1a                	jmp    f01014dc <readline+0x93>
				cputchar('\b');
f01014c2:	83 ec 0c             	sub    $0xc,%esp
f01014c5:	6a 08                	push   $0x8
f01014c7:	e8 66 f2 ff ff       	call   f0100732 <cputchar>
f01014cc:	83 c4 10             	add    $0x10,%esp
f01014cf:	eb ec                	jmp    f01014bd <readline+0x74>
			buf[i++] = c;
f01014d1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01014d4:	89 f0                	mov    %esi,%eax
f01014d6:	88 04 39             	mov    %al,(%ecx,%edi,1)
f01014d9:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01014dc:	e8 61 f2 ff ff       	call   f0100742 <getchar>
f01014e1:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01014e3:	85 c0                	test   %eax,%eax
f01014e5:	78 b0                	js     f0101497 <readline+0x4e>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01014e7:	83 f8 08             	cmp    $0x8,%eax
f01014ea:	0f 94 c2             	sete   %dl
f01014ed:	83 f8 7f             	cmp    $0x7f,%eax
f01014f0:	0f 94 c0             	sete   %al
f01014f3:	08 c2                	or     %al,%dl
f01014f5:	74 04                	je     f01014fb <readline+0xb2>
f01014f7:	85 ff                	test   %edi,%edi
f01014f9:	7f bc                	jg     f01014b7 <readline+0x6e>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01014fb:	83 fe 1f             	cmp    $0x1f,%esi
f01014fe:	7e 1c                	jle    f010151c <readline+0xd3>
f0101500:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101506:	7f 14                	jg     f010151c <readline+0xd3>
			if (echoing)
f0101508:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010150c:	74 c3                	je     f01014d1 <readline+0x88>
				cputchar(c);
f010150e:	83 ec 0c             	sub    $0xc,%esp
f0101511:	56                   	push   %esi
f0101512:	e8 1b f2 ff ff       	call   f0100732 <cputchar>
f0101517:	83 c4 10             	add    $0x10,%esp
f010151a:	eb b5                	jmp    f01014d1 <readline+0x88>
		} else if (c == '\n' || c == '\r') {
f010151c:	83 fe 0a             	cmp    $0xa,%esi
f010151f:	74 05                	je     f0101526 <readline+0xdd>
f0101521:	83 fe 0d             	cmp    $0xd,%esi
f0101524:	75 b6                	jne    f01014dc <readline+0x93>
			if (echoing)
f0101526:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010152a:	75 13                	jne    f010153f <readline+0xf6>
			buf[i] = 0;
f010152c:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f0101533:	00 
			return buf;
f0101534:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f010153a:	e9 70 ff ff ff       	jmp    f01014af <readline+0x66>
				cputchar('\n');
f010153f:	83 ec 0c             	sub    $0xc,%esp
f0101542:	6a 0a                	push   $0xa
f0101544:	e8 e9 f1 ff ff       	call   f0100732 <cputchar>
f0101549:	83 c4 10             	add    $0x10,%esp
f010154c:	eb de                	jmp    f010152c <readline+0xe3>

f010154e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010154e:	55                   	push   %ebp
f010154f:	89 e5                	mov    %esp,%ebp
f0101551:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101554:	b8 00 00 00 00       	mov    $0x0,%eax
f0101559:	eb 03                	jmp    f010155e <strlen+0x10>
		n++;
f010155b:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f010155e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101562:	75 f7                	jne    f010155b <strlen+0xd>
	return n;
}
f0101564:	5d                   	pop    %ebp
f0101565:	c3                   	ret    

f0101566 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101566:	55                   	push   %ebp
f0101567:	89 e5                	mov    %esp,%ebp
f0101569:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010156c:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010156f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101574:	eb 03                	jmp    f0101579 <strnlen+0x13>
		n++;
f0101576:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101579:	39 d0                	cmp    %edx,%eax
f010157b:	74 08                	je     f0101585 <strnlen+0x1f>
f010157d:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101581:	75 f3                	jne    f0101576 <strnlen+0x10>
f0101583:	89 c2                	mov    %eax,%edx
	return n;
}
f0101585:	89 d0                	mov    %edx,%eax
f0101587:	5d                   	pop    %ebp
f0101588:	c3                   	ret    

f0101589 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101589:	55                   	push   %ebp
f010158a:	89 e5                	mov    %esp,%ebp
f010158c:	53                   	push   %ebx
f010158d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101590:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101593:	b8 00 00 00 00       	mov    $0x0,%eax
f0101598:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f010159c:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f010159f:	83 c0 01             	add    $0x1,%eax
f01015a2:	84 d2                	test   %dl,%dl
f01015a4:	75 f2                	jne    f0101598 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01015a6:	89 c8                	mov    %ecx,%eax
f01015a8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01015ab:	c9                   	leave  
f01015ac:	c3                   	ret    

f01015ad <strcat>:

char *
strcat(char *dst, const char *src)
{
f01015ad:	55                   	push   %ebp
f01015ae:	89 e5                	mov    %esp,%ebp
f01015b0:	53                   	push   %ebx
f01015b1:	83 ec 10             	sub    $0x10,%esp
f01015b4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01015b7:	53                   	push   %ebx
f01015b8:	e8 91 ff ff ff       	call   f010154e <strlen>
f01015bd:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f01015c0:	ff 75 0c             	pushl  0xc(%ebp)
f01015c3:	01 d8                	add    %ebx,%eax
f01015c5:	50                   	push   %eax
f01015c6:	e8 be ff ff ff       	call   f0101589 <strcpy>
	return dst;
}
f01015cb:	89 d8                	mov    %ebx,%eax
f01015cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01015d0:	c9                   	leave  
f01015d1:	c3                   	ret    

f01015d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01015d2:	55                   	push   %ebp
f01015d3:	89 e5                	mov    %esp,%ebp
f01015d5:	56                   	push   %esi
f01015d6:	53                   	push   %ebx
f01015d7:	8b 75 08             	mov    0x8(%ebp),%esi
f01015da:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015dd:	89 f3                	mov    %esi,%ebx
f01015df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01015e2:	89 f0                	mov    %esi,%eax
f01015e4:	eb 0f                	jmp    f01015f5 <strncpy+0x23>
		*dst++ = *src;
f01015e6:	83 c0 01             	add    $0x1,%eax
f01015e9:	0f b6 0a             	movzbl (%edx),%ecx
f01015ec:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01015ef:	80 f9 01             	cmp    $0x1,%cl
f01015f2:	83 da ff             	sbb    $0xffffffff,%edx
	for (i = 0; i < size; i++) {
f01015f5:	39 d8                	cmp    %ebx,%eax
f01015f7:	75 ed                	jne    f01015e6 <strncpy+0x14>
	}
	return ret;
}
f01015f9:	89 f0                	mov    %esi,%eax
f01015fb:	5b                   	pop    %ebx
f01015fc:	5e                   	pop    %esi
f01015fd:	5d                   	pop    %ebp
f01015fe:	c3                   	ret    

f01015ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01015ff:	55                   	push   %ebp
f0101600:	89 e5                	mov    %esp,%ebp
f0101602:	56                   	push   %esi
f0101603:	53                   	push   %ebx
f0101604:	8b 75 08             	mov    0x8(%ebp),%esi
f0101607:	8b 55 0c             	mov    0xc(%ebp),%edx
f010160a:	8b 45 10             	mov    0x10(%ebp),%eax
f010160d:	89 f3                	mov    %esi,%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010160f:	85 c0                	test   %eax,%eax
f0101611:	74 21                	je     f0101634 <strlcpy+0x35>
f0101613:	8d 5c 06 ff          	lea    -0x1(%esi,%eax,1),%ebx
f0101617:	89 f0                	mov    %esi,%eax
f0101619:	eb 09                	jmp    f0101624 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010161b:	83 c2 01             	add    $0x1,%edx
f010161e:	83 c0 01             	add    $0x1,%eax
f0101621:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101624:	39 d8                	cmp    %ebx,%eax
f0101626:	74 09                	je     f0101631 <strlcpy+0x32>
f0101628:	0f b6 0a             	movzbl (%edx),%ecx
f010162b:	84 c9                	test   %cl,%cl
f010162d:	75 ec                	jne    f010161b <strlcpy+0x1c>
f010162f:	89 c3                	mov    %eax,%ebx
		*dst = '\0';
f0101631:	c6 03 00             	movb   $0x0,(%ebx)
	}
	return dst - dst_in;
f0101634:	89 d8                	mov    %ebx,%eax
f0101636:	29 f0                	sub    %esi,%eax
}
f0101638:	5b                   	pop    %ebx
f0101639:	5e                   	pop    %esi
f010163a:	5d                   	pop    %ebp
f010163b:	c3                   	ret    

f010163c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010163c:	55                   	push   %ebp
f010163d:	89 e5                	mov    %esp,%ebp
f010163f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101642:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101645:	eb 06                	jmp    f010164d <strcmp+0x11>
		p++, q++;
f0101647:	83 c1 01             	add    $0x1,%ecx
f010164a:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010164d:	0f b6 01             	movzbl (%ecx),%eax
f0101650:	84 c0                	test   %al,%al
f0101652:	74 04                	je     f0101658 <strcmp+0x1c>
f0101654:	3a 02                	cmp    (%edx),%al
f0101656:	74 ef                	je     f0101647 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101658:	0f b6 c0             	movzbl %al,%eax
f010165b:	0f b6 12             	movzbl (%edx),%edx
f010165e:	29 d0                	sub    %edx,%eax
}
f0101660:	5d                   	pop    %ebp
f0101661:	c3                   	ret    

f0101662 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101662:	55                   	push   %ebp
f0101663:	89 e5                	mov    %esp,%ebp
f0101665:	53                   	push   %ebx
f0101666:	8b 45 08             	mov    0x8(%ebp),%eax
f0101669:	8b 55 0c             	mov    0xc(%ebp),%edx
f010166c:	89 c3                	mov    %eax,%ebx
f010166e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101671:	eb 06                	jmp    f0101679 <strncmp+0x17>
		n--, p++, q++;
f0101673:	83 c0 01             	add    $0x1,%eax
f0101676:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101679:	39 d8                	cmp    %ebx,%eax
f010167b:	74 18                	je     f0101695 <strncmp+0x33>
f010167d:	0f b6 08             	movzbl (%eax),%ecx
f0101680:	84 c9                	test   %cl,%cl
f0101682:	74 04                	je     f0101688 <strncmp+0x26>
f0101684:	3a 0a                	cmp    (%edx),%cl
f0101686:	74 eb                	je     f0101673 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101688:	0f b6 00             	movzbl (%eax),%eax
f010168b:	0f b6 12             	movzbl (%edx),%edx
f010168e:	29 d0                	sub    %edx,%eax
}
f0101690:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101693:	c9                   	leave  
f0101694:	c3                   	ret    
		return 0;
f0101695:	b8 00 00 00 00       	mov    $0x0,%eax
f010169a:	eb f4                	jmp    f0101690 <strncmp+0x2e>

f010169c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010169c:	55                   	push   %ebp
f010169d:	89 e5                	mov    %esp,%ebp
f010169f:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016a6:	eb 03                	jmp    f01016ab <strchr+0xf>
f01016a8:	83 c0 01             	add    $0x1,%eax
f01016ab:	0f b6 10             	movzbl (%eax),%edx
f01016ae:	84 d2                	test   %dl,%dl
f01016b0:	74 06                	je     f01016b8 <strchr+0x1c>
		if (*s == c)
f01016b2:	38 ca                	cmp    %cl,%dl
f01016b4:	75 f2                	jne    f01016a8 <strchr+0xc>
f01016b6:	eb 05                	jmp    f01016bd <strchr+0x21>
			return (char *) s;
	return 0;
f01016b8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016bd:	5d                   	pop    %ebp
f01016be:	c3                   	ret    

f01016bf <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01016bf:	55                   	push   %ebp
f01016c0:	89 e5                	mov    %esp,%ebp
f01016c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01016c5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016c9:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01016cc:	38 ca                	cmp    %cl,%dl
f01016ce:	74 09                	je     f01016d9 <strfind+0x1a>
f01016d0:	84 d2                	test   %dl,%dl
f01016d2:	74 05                	je     f01016d9 <strfind+0x1a>
	for (; *s; s++)
f01016d4:	83 c0 01             	add    $0x1,%eax
f01016d7:	eb f0                	jmp    f01016c9 <strfind+0xa>
			break;
	return (char *) s;
}
f01016d9:	5d                   	pop    %ebp
f01016da:	c3                   	ret    

f01016db <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01016db:	55                   	push   %ebp
f01016dc:	89 e5                	mov    %esp,%ebp
f01016de:	57                   	push   %edi
f01016df:	56                   	push   %esi
f01016e0:	53                   	push   %ebx
f01016e1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01016e4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01016e7:	85 c9                	test   %ecx,%ecx
f01016e9:	74 31                	je     f010171c <memset+0x41>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01016eb:	89 f8                	mov    %edi,%eax
f01016ed:	09 c8                	or     %ecx,%eax
f01016ef:	a8 03                	test   $0x3,%al
f01016f1:	75 23                	jne    f0101716 <memset+0x3b>
		c &= 0xFF;
f01016f3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01016f7:	89 d3                	mov    %edx,%ebx
f01016f9:	c1 e3 08             	shl    $0x8,%ebx
f01016fc:	89 d0                	mov    %edx,%eax
f01016fe:	c1 e0 18             	shl    $0x18,%eax
f0101701:	89 d6                	mov    %edx,%esi
f0101703:	c1 e6 10             	shl    $0x10,%esi
f0101706:	09 f0                	or     %esi,%eax
f0101708:	09 c2                	or     %eax,%edx
f010170a:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010170c:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010170f:	89 d0                	mov    %edx,%eax
f0101711:	fc                   	cld    
f0101712:	f3 ab                	rep stos %eax,%es:(%edi)
f0101714:	eb 06                	jmp    f010171c <memset+0x41>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101716:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101719:	fc                   	cld    
f010171a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010171c:	89 f8                	mov    %edi,%eax
f010171e:	5b                   	pop    %ebx
f010171f:	5e                   	pop    %esi
f0101720:	5f                   	pop    %edi
f0101721:	5d                   	pop    %ebp
f0101722:	c3                   	ret    

f0101723 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101723:	55                   	push   %ebp
f0101724:	89 e5                	mov    %esp,%ebp
f0101726:	57                   	push   %edi
f0101727:	56                   	push   %esi
f0101728:	8b 45 08             	mov    0x8(%ebp),%eax
f010172b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010172e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101731:	39 c6                	cmp    %eax,%esi
f0101733:	73 32                	jae    f0101767 <memmove+0x44>
f0101735:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101738:	39 c2                	cmp    %eax,%edx
f010173a:	76 2b                	jbe    f0101767 <memmove+0x44>
		s += n;
		d += n;
f010173c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010173f:	89 fe                	mov    %edi,%esi
f0101741:	09 ce                	or     %ecx,%esi
f0101743:	09 d6                	or     %edx,%esi
f0101745:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010174b:	75 0e                	jne    f010175b <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010174d:	83 ef 04             	sub    $0x4,%edi
f0101750:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101753:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101756:	fd                   	std    
f0101757:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101759:	eb 09                	jmp    f0101764 <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010175b:	83 ef 01             	sub    $0x1,%edi
f010175e:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101761:	fd                   	std    
f0101762:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101764:	fc                   	cld    
f0101765:	eb 1a                	jmp    f0101781 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101767:	89 c2                	mov    %eax,%edx
f0101769:	09 ca                	or     %ecx,%edx
f010176b:	09 f2                	or     %esi,%edx
f010176d:	f6 c2 03             	test   $0x3,%dl
f0101770:	75 0a                	jne    f010177c <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101772:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101775:	89 c7                	mov    %eax,%edi
f0101777:	fc                   	cld    
f0101778:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010177a:	eb 05                	jmp    f0101781 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f010177c:	89 c7                	mov    %eax,%edi
f010177e:	fc                   	cld    
f010177f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101781:	5e                   	pop    %esi
f0101782:	5f                   	pop    %edi
f0101783:	5d                   	pop    %ebp
f0101784:	c3                   	ret    

f0101785 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101785:	55                   	push   %ebp
f0101786:	89 e5                	mov    %esp,%ebp
f0101788:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010178b:	ff 75 10             	pushl  0x10(%ebp)
f010178e:	ff 75 0c             	pushl  0xc(%ebp)
f0101791:	ff 75 08             	pushl  0x8(%ebp)
f0101794:	e8 8a ff ff ff       	call   f0101723 <memmove>
}
f0101799:	c9                   	leave  
f010179a:	c3                   	ret    

f010179b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010179b:	55                   	push   %ebp
f010179c:	89 e5                	mov    %esp,%ebp
f010179e:	56                   	push   %esi
f010179f:	53                   	push   %ebx
f01017a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01017a3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01017a6:	89 c6                	mov    %eax,%esi
f01017a8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017ab:	eb 06                	jmp    f01017b3 <memcmp+0x18>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01017ad:	83 c0 01             	add    $0x1,%eax
f01017b0:	83 c2 01             	add    $0x1,%edx
	while (n-- > 0) {
f01017b3:	39 f0                	cmp    %esi,%eax
f01017b5:	74 14                	je     f01017cb <memcmp+0x30>
		if (*s1 != *s2)
f01017b7:	0f b6 08             	movzbl (%eax),%ecx
f01017ba:	0f b6 1a             	movzbl (%edx),%ebx
f01017bd:	38 d9                	cmp    %bl,%cl
f01017bf:	74 ec                	je     f01017ad <memcmp+0x12>
			return (int) *s1 - (int) *s2;
f01017c1:	0f b6 c1             	movzbl %cl,%eax
f01017c4:	0f b6 db             	movzbl %bl,%ebx
f01017c7:	29 d8                	sub    %ebx,%eax
f01017c9:	eb 05                	jmp    f01017d0 <memcmp+0x35>
	}

	return 0;
f01017cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017d0:	5b                   	pop    %ebx
f01017d1:	5e                   	pop    %esi
f01017d2:	5d                   	pop    %ebp
f01017d3:	c3                   	ret    

f01017d4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017d4:	55                   	push   %ebp
f01017d5:	89 e5                	mov    %esp,%ebp
f01017d7:	8b 45 08             	mov    0x8(%ebp),%eax
f01017da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01017dd:	89 c2                	mov    %eax,%edx
f01017df:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017e2:	eb 03                	jmp    f01017e7 <memfind+0x13>
f01017e4:	83 c0 01             	add    $0x1,%eax
f01017e7:	39 d0                	cmp    %edx,%eax
f01017e9:	73 04                	jae    f01017ef <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017eb:	38 08                	cmp    %cl,(%eax)
f01017ed:	75 f5                	jne    f01017e4 <memfind+0x10>
			break;
	return (void *) s;
}
f01017ef:	5d                   	pop    %ebp
f01017f0:	c3                   	ret    

f01017f1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017f1:	55                   	push   %ebp
f01017f2:	89 e5                	mov    %esp,%ebp
f01017f4:	57                   	push   %edi
f01017f5:	56                   	push   %esi
f01017f6:	53                   	push   %ebx
f01017f7:	8b 55 08             	mov    0x8(%ebp),%edx
f01017fa:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017fd:	eb 03                	jmp    f0101802 <strtol+0x11>
		s++;
f01017ff:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0101802:	0f b6 02             	movzbl (%edx),%eax
f0101805:	3c 20                	cmp    $0x20,%al
f0101807:	74 f6                	je     f01017ff <strtol+0xe>
f0101809:	3c 09                	cmp    $0x9,%al
f010180b:	74 f2                	je     f01017ff <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010180d:	3c 2b                	cmp    $0x2b,%al
f010180f:	74 2a                	je     f010183b <strtol+0x4a>
	int neg = 0;
f0101811:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101816:	3c 2d                	cmp    $0x2d,%al
f0101818:	74 2b                	je     f0101845 <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010181a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101820:	75 0f                	jne    f0101831 <strtol+0x40>
f0101822:	80 3a 30             	cmpb   $0x30,(%edx)
f0101825:	74 28                	je     f010184f <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101827:	85 db                	test   %ebx,%ebx
f0101829:	b8 0a 00 00 00       	mov    $0xa,%eax
f010182e:	0f 44 d8             	cmove  %eax,%ebx
f0101831:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101836:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101839:	eb 46                	jmp    f0101881 <strtol+0x90>
		s++;
f010183b:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f010183e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101843:	eb d5                	jmp    f010181a <strtol+0x29>
		s++, neg = 1;
f0101845:	83 c2 01             	add    $0x1,%edx
f0101848:	bf 01 00 00 00       	mov    $0x1,%edi
f010184d:	eb cb                	jmp    f010181a <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010184f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101853:	74 0e                	je     f0101863 <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f0101855:	85 db                	test   %ebx,%ebx
f0101857:	75 d8                	jne    f0101831 <strtol+0x40>
		s++, base = 8;
f0101859:	83 c2 01             	add    $0x1,%edx
f010185c:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101861:	eb ce                	jmp    f0101831 <strtol+0x40>
		s += 2, base = 16;
f0101863:	83 c2 02             	add    $0x2,%edx
f0101866:	bb 10 00 00 00       	mov    $0x10,%ebx
f010186b:	eb c4                	jmp    f0101831 <strtol+0x40>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f010186d:	0f be c0             	movsbl %al,%eax
f0101870:	83 e8 30             	sub    $0x30,%eax
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101873:	3b 45 10             	cmp    0x10(%ebp),%eax
f0101876:	7d 3a                	jge    f01018b2 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101878:	83 c2 01             	add    $0x1,%edx
f010187b:	0f af 4d 10          	imul   0x10(%ebp),%ecx
f010187f:	01 c1                	add    %eax,%ecx
		if (*s >= '0' && *s <= '9')
f0101881:	0f b6 02             	movzbl (%edx),%eax
f0101884:	8d 70 d0             	lea    -0x30(%eax),%esi
f0101887:	89 f3                	mov    %esi,%ebx
f0101889:	80 fb 09             	cmp    $0x9,%bl
f010188c:	76 df                	jbe    f010186d <strtol+0x7c>
		else if (*s >= 'a' && *s <= 'z')
f010188e:	8d 70 9f             	lea    -0x61(%eax),%esi
f0101891:	89 f3                	mov    %esi,%ebx
f0101893:	80 fb 19             	cmp    $0x19,%bl
f0101896:	77 08                	ja     f01018a0 <strtol+0xaf>
			dig = *s - 'a' + 10;
f0101898:	0f be c0             	movsbl %al,%eax
f010189b:	83 e8 57             	sub    $0x57,%eax
f010189e:	eb d3                	jmp    f0101873 <strtol+0x82>
		else if (*s >= 'A' && *s <= 'Z')
f01018a0:	8d 70 bf             	lea    -0x41(%eax),%esi
f01018a3:	89 f3                	mov    %esi,%ebx
f01018a5:	80 fb 19             	cmp    $0x19,%bl
f01018a8:	77 08                	ja     f01018b2 <strtol+0xc1>
			dig = *s - 'A' + 10;
f01018aa:	0f be c0             	movsbl %al,%eax
f01018ad:	83 e8 37             	sub    $0x37,%eax
f01018b0:	eb c1                	jmp    f0101873 <strtol+0x82>
		// we don't properly detect overflow!
	}

	if (endptr)
f01018b2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018b6:	74 05                	je     f01018bd <strtol+0xcc>
		*endptr = (char *) s;
f01018b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01018bb:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f01018bd:	89 c8                	mov    %ecx,%eax
f01018bf:	f7 d8                	neg    %eax
f01018c1:	85 ff                	test   %edi,%edi
f01018c3:	0f 45 c8             	cmovne %eax,%ecx
}
f01018c6:	89 c8                	mov    %ecx,%eax
f01018c8:	5b                   	pop    %ebx
f01018c9:	5e                   	pop    %esi
f01018ca:	5f                   	pop    %edi
f01018cb:	5d                   	pop    %ebp
f01018cc:	c3                   	ret    
f01018cd:	66 90                	xchg   %ax,%ax
f01018cf:	90                   	nop

f01018d0 <__udivdi3>:
f01018d0:	f3 0f 1e fb          	endbr32 
f01018d4:	55                   	push   %ebp
f01018d5:	57                   	push   %edi
f01018d6:	56                   	push   %esi
f01018d7:	53                   	push   %ebx
f01018d8:	83 ec 1c             	sub    $0x1c,%esp
f01018db:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01018df:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01018e3:	8b 74 24 34          	mov    0x34(%esp),%esi
f01018e7:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01018eb:	85 d2                	test   %edx,%edx
f01018ed:	75 19                	jne    f0101908 <__udivdi3+0x38>
f01018ef:	39 f3                	cmp    %esi,%ebx
f01018f1:	76 4d                	jbe    f0101940 <__udivdi3+0x70>
f01018f3:	31 ff                	xor    %edi,%edi
f01018f5:	89 e8                	mov    %ebp,%eax
f01018f7:	89 f2                	mov    %esi,%edx
f01018f9:	f7 f3                	div    %ebx
f01018fb:	89 fa                	mov    %edi,%edx
f01018fd:	83 c4 1c             	add    $0x1c,%esp
f0101900:	5b                   	pop    %ebx
f0101901:	5e                   	pop    %esi
f0101902:	5f                   	pop    %edi
f0101903:	5d                   	pop    %ebp
f0101904:	c3                   	ret    
f0101905:	8d 76 00             	lea    0x0(%esi),%esi
f0101908:	39 f2                	cmp    %esi,%edx
f010190a:	76 14                	jbe    f0101920 <__udivdi3+0x50>
f010190c:	31 ff                	xor    %edi,%edi
f010190e:	31 c0                	xor    %eax,%eax
f0101910:	89 fa                	mov    %edi,%edx
f0101912:	83 c4 1c             	add    $0x1c,%esp
f0101915:	5b                   	pop    %ebx
f0101916:	5e                   	pop    %esi
f0101917:	5f                   	pop    %edi
f0101918:	5d                   	pop    %ebp
f0101919:	c3                   	ret    
f010191a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101920:	0f bd fa             	bsr    %edx,%edi
f0101923:	83 f7 1f             	xor    $0x1f,%edi
f0101926:	75 48                	jne    f0101970 <__udivdi3+0xa0>
f0101928:	39 f2                	cmp    %esi,%edx
f010192a:	72 06                	jb     f0101932 <__udivdi3+0x62>
f010192c:	31 c0                	xor    %eax,%eax
f010192e:	39 eb                	cmp    %ebp,%ebx
f0101930:	77 de                	ja     f0101910 <__udivdi3+0x40>
f0101932:	b8 01 00 00 00       	mov    $0x1,%eax
f0101937:	eb d7                	jmp    f0101910 <__udivdi3+0x40>
f0101939:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101940:	89 d9                	mov    %ebx,%ecx
f0101942:	85 db                	test   %ebx,%ebx
f0101944:	75 0b                	jne    f0101951 <__udivdi3+0x81>
f0101946:	b8 01 00 00 00       	mov    $0x1,%eax
f010194b:	31 d2                	xor    %edx,%edx
f010194d:	f7 f3                	div    %ebx
f010194f:	89 c1                	mov    %eax,%ecx
f0101951:	31 d2                	xor    %edx,%edx
f0101953:	89 f0                	mov    %esi,%eax
f0101955:	f7 f1                	div    %ecx
f0101957:	89 c6                	mov    %eax,%esi
f0101959:	89 e8                	mov    %ebp,%eax
f010195b:	89 f7                	mov    %esi,%edi
f010195d:	f7 f1                	div    %ecx
f010195f:	89 fa                	mov    %edi,%edx
f0101961:	83 c4 1c             	add    $0x1c,%esp
f0101964:	5b                   	pop    %ebx
f0101965:	5e                   	pop    %esi
f0101966:	5f                   	pop    %edi
f0101967:	5d                   	pop    %ebp
f0101968:	c3                   	ret    
f0101969:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101970:	89 f9                	mov    %edi,%ecx
f0101972:	b8 20 00 00 00       	mov    $0x20,%eax
f0101977:	29 f8                	sub    %edi,%eax
f0101979:	d3 e2                	shl    %cl,%edx
f010197b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010197f:	89 c1                	mov    %eax,%ecx
f0101981:	89 da                	mov    %ebx,%edx
f0101983:	d3 ea                	shr    %cl,%edx
f0101985:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101989:	09 d1                	or     %edx,%ecx
f010198b:	89 f2                	mov    %esi,%edx
f010198d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101991:	89 f9                	mov    %edi,%ecx
f0101993:	d3 e3                	shl    %cl,%ebx
f0101995:	89 c1                	mov    %eax,%ecx
f0101997:	d3 ea                	shr    %cl,%edx
f0101999:	89 f9                	mov    %edi,%ecx
f010199b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010199f:	89 eb                	mov    %ebp,%ebx
f01019a1:	d3 e6                	shl    %cl,%esi
f01019a3:	89 c1                	mov    %eax,%ecx
f01019a5:	d3 eb                	shr    %cl,%ebx
f01019a7:	09 de                	or     %ebx,%esi
f01019a9:	89 f0                	mov    %esi,%eax
f01019ab:	f7 74 24 08          	divl   0x8(%esp)
f01019af:	89 d6                	mov    %edx,%esi
f01019b1:	89 c3                	mov    %eax,%ebx
f01019b3:	f7 64 24 0c          	mull   0xc(%esp)
f01019b7:	39 d6                	cmp    %edx,%esi
f01019b9:	72 15                	jb     f01019d0 <__udivdi3+0x100>
f01019bb:	89 f9                	mov    %edi,%ecx
f01019bd:	d3 e5                	shl    %cl,%ebp
f01019bf:	39 c5                	cmp    %eax,%ebp
f01019c1:	73 04                	jae    f01019c7 <__udivdi3+0xf7>
f01019c3:	39 d6                	cmp    %edx,%esi
f01019c5:	74 09                	je     f01019d0 <__udivdi3+0x100>
f01019c7:	89 d8                	mov    %ebx,%eax
f01019c9:	31 ff                	xor    %edi,%edi
f01019cb:	e9 40 ff ff ff       	jmp    f0101910 <__udivdi3+0x40>
f01019d0:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01019d3:	31 ff                	xor    %edi,%edi
f01019d5:	e9 36 ff ff ff       	jmp    f0101910 <__udivdi3+0x40>
f01019da:	66 90                	xchg   %ax,%ax
f01019dc:	66 90                	xchg   %ax,%ax
f01019de:	66 90                	xchg   %ax,%ax

f01019e0 <__umoddi3>:
f01019e0:	f3 0f 1e fb          	endbr32 
f01019e4:	55                   	push   %ebp
f01019e5:	57                   	push   %edi
f01019e6:	56                   	push   %esi
f01019e7:	53                   	push   %ebx
f01019e8:	83 ec 1c             	sub    $0x1c,%esp
f01019eb:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01019ef:	8b 74 24 30          	mov    0x30(%esp),%esi
f01019f3:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01019f7:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01019fb:	85 c0                	test   %eax,%eax
f01019fd:	75 19                	jne    f0101a18 <__umoddi3+0x38>
f01019ff:	39 df                	cmp    %ebx,%edi
f0101a01:	76 5d                	jbe    f0101a60 <__umoddi3+0x80>
f0101a03:	89 f0                	mov    %esi,%eax
f0101a05:	89 da                	mov    %ebx,%edx
f0101a07:	f7 f7                	div    %edi
f0101a09:	89 d0                	mov    %edx,%eax
f0101a0b:	31 d2                	xor    %edx,%edx
f0101a0d:	83 c4 1c             	add    $0x1c,%esp
f0101a10:	5b                   	pop    %ebx
f0101a11:	5e                   	pop    %esi
f0101a12:	5f                   	pop    %edi
f0101a13:	5d                   	pop    %ebp
f0101a14:	c3                   	ret    
f0101a15:	8d 76 00             	lea    0x0(%esi),%esi
f0101a18:	89 f2                	mov    %esi,%edx
f0101a1a:	39 d8                	cmp    %ebx,%eax
f0101a1c:	76 12                	jbe    f0101a30 <__umoddi3+0x50>
f0101a1e:	89 f0                	mov    %esi,%eax
f0101a20:	89 da                	mov    %ebx,%edx
f0101a22:	83 c4 1c             	add    $0x1c,%esp
f0101a25:	5b                   	pop    %ebx
f0101a26:	5e                   	pop    %esi
f0101a27:	5f                   	pop    %edi
f0101a28:	5d                   	pop    %ebp
f0101a29:	c3                   	ret    
f0101a2a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a30:	0f bd e8             	bsr    %eax,%ebp
f0101a33:	83 f5 1f             	xor    $0x1f,%ebp
f0101a36:	75 50                	jne    f0101a88 <__umoddi3+0xa8>
f0101a38:	39 d8                	cmp    %ebx,%eax
f0101a3a:	0f 82 e0 00 00 00    	jb     f0101b20 <__umoddi3+0x140>
f0101a40:	89 d9                	mov    %ebx,%ecx
f0101a42:	39 f7                	cmp    %esi,%edi
f0101a44:	0f 86 d6 00 00 00    	jbe    f0101b20 <__umoddi3+0x140>
f0101a4a:	89 d0                	mov    %edx,%eax
f0101a4c:	89 ca                	mov    %ecx,%edx
f0101a4e:	83 c4 1c             	add    $0x1c,%esp
f0101a51:	5b                   	pop    %ebx
f0101a52:	5e                   	pop    %esi
f0101a53:	5f                   	pop    %edi
f0101a54:	5d                   	pop    %ebp
f0101a55:	c3                   	ret    
f0101a56:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a5d:	8d 76 00             	lea    0x0(%esi),%esi
f0101a60:	89 fd                	mov    %edi,%ebp
f0101a62:	85 ff                	test   %edi,%edi
f0101a64:	75 0b                	jne    f0101a71 <__umoddi3+0x91>
f0101a66:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a6b:	31 d2                	xor    %edx,%edx
f0101a6d:	f7 f7                	div    %edi
f0101a6f:	89 c5                	mov    %eax,%ebp
f0101a71:	89 d8                	mov    %ebx,%eax
f0101a73:	31 d2                	xor    %edx,%edx
f0101a75:	f7 f5                	div    %ebp
f0101a77:	89 f0                	mov    %esi,%eax
f0101a79:	f7 f5                	div    %ebp
f0101a7b:	89 d0                	mov    %edx,%eax
f0101a7d:	31 d2                	xor    %edx,%edx
f0101a7f:	eb 8c                	jmp    f0101a0d <__umoddi3+0x2d>
f0101a81:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a88:	89 e9                	mov    %ebp,%ecx
f0101a8a:	ba 20 00 00 00       	mov    $0x20,%edx
f0101a8f:	29 ea                	sub    %ebp,%edx
f0101a91:	d3 e0                	shl    %cl,%eax
f0101a93:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a97:	89 d1                	mov    %edx,%ecx
f0101a99:	89 f8                	mov    %edi,%eax
f0101a9b:	d3 e8                	shr    %cl,%eax
f0101a9d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101aa1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101aa5:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101aa9:	09 c1                	or     %eax,%ecx
f0101aab:	89 d8                	mov    %ebx,%eax
f0101aad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101ab1:	89 e9                	mov    %ebp,%ecx
f0101ab3:	d3 e7                	shl    %cl,%edi
f0101ab5:	89 d1                	mov    %edx,%ecx
f0101ab7:	d3 e8                	shr    %cl,%eax
f0101ab9:	89 e9                	mov    %ebp,%ecx
f0101abb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101abf:	d3 e3                	shl    %cl,%ebx
f0101ac1:	89 c7                	mov    %eax,%edi
f0101ac3:	89 d1                	mov    %edx,%ecx
f0101ac5:	89 f0                	mov    %esi,%eax
f0101ac7:	d3 e8                	shr    %cl,%eax
f0101ac9:	89 e9                	mov    %ebp,%ecx
f0101acb:	89 fa                	mov    %edi,%edx
f0101acd:	d3 e6                	shl    %cl,%esi
f0101acf:	09 d8                	or     %ebx,%eax
f0101ad1:	f7 74 24 08          	divl   0x8(%esp)
f0101ad5:	89 d1                	mov    %edx,%ecx
f0101ad7:	89 f3                	mov    %esi,%ebx
f0101ad9:	f7 64 24 0c          	mull   0xc(%esp)
f0101add:	89 c6                	mov    %eax,%esi
f0101adf:	89 d7                	mov    %edx,%edi
f0101ae1:	39 d1                	cmp    %edx,%ecx
f0101ae3:	72 06                	jb     f0101aeb <__umoddi3+0x10b>
f0101ae5:	75 10                	jne    f0101af7 <__umoddi3+0x117>
f0101ae7:	39 c3                	cmp    %eax,%ebx
f0101ae9:	73 0c                	jae    f0101af7 <__umoddi3+0x117>
f0101aeb:	2b 44 24 0c          	sub    0xc(%esp),%eax
f0101aef:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0101af3:	89 d7                	mov    %edx,%edi
f0101af5:	89 c6                	mov    %eax,%esi
f0101af7:	89 ca                	mov    %ecx,%edx
f0101af9:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101afe:	29 f3                	sub    %esi,%ebx
f0101b00:	19 fa                	sbb    %edi,%edx
f0101b02:	89 d0                	mov    %edx,%eax
f0101b04:	d3 e0                	shl    %cl,%eax
f0101b06:	89 e9                	mov    %ebp,%ecx
f0101b08:	d3 eb                	shr    %cl,%ebx
f0101b0a:	d3 ea                	shr    %cl,%edx
f0101b0c:	09 d8                	or     %ebx,%eax
f0101b0e:	83 c4 1c             	add    $0x1c,%esp
f0101b11:	5b                   	pop    %ebx
f0101b12:	5e                   	pop    %esi
f0101b13:	5f                   	pop    %edi
f0101b14:	5d                   	pop    %ebp
f0101b15:	c3                   	ret    
f0101b16:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b1d:	8d 76 00             	lea    0x0(%esi),%esi
f0101b20:	89 d9                	mov    %ebx,%ecx
f0101b22:	89 f2                	mov    %esi,%edx
f0101b24:	29 fa                	sub    %edi,%edx
f0101b26:	19 c1                	sbb    %eax,%ecx
f0101b28:	e9 1d ff ff ff       	jmp    f0101a4a <__umoddi3+0x6a>
