
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
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 f0 10 f0       	mov    $0xf010f000,%esp

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
f010004a:	81 c3 be 02 01 00    	add    $0x102be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 58 17 ff ff    	lea    -0xe8a8(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 e1 09 00 00       	call   f0100a44 <cprintf>
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
f010007d:	8d 83 74 17 ff ff    	lea    -0xe88c(%ebx),%eax
f0100083:	50                   	push   %eax
f0100084:	e8 bb 09 00 00       	call   f0100a44 <cprintf>
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
f01000b2:	81 c3 56 02 01 00    	add    $0x10256,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000b8:	c7 c2 60 20 11 f0    	mov    $0xf0112060,%edx
f01000be:	c7 c0 c0 26 11 f0    	mov    $0xf01126c0,%eax
f01000c4:	29 d0                	sub    %edx,%eax
f01000c6:	50                   	push   %eax
f01000c7:	6a 00                	push   $0x0
f01000c9:	52                   	push   %edx
f01000ca:	e8 31 15 00 00       	call   f0101600 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 3f 05 00 00       	call   f0100613 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 8f 17 ff ff    	lea    -0xe871(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 5c 09 00 00       	call   f0100a44 <cprintf>

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
f01000fc:	e8 87 07 00 00       	call   f0100888 <monitor>
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
f0100110:	81 c3 f8 01 01 00    	add    $0x101f8,%ebx
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
f0100124:	e8 5f 07 00 00       	call   f0100888 <monitor>
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
f0100145:	8d 83 aa 17 ff ff    	lea    -0xe856(%ebx),%eax
f010014b:	50                   	push   %eax
f010014c:	e8 f3 08 00 00       	call   f0100a44 <cprintf>
	vcprintf(fmt, ap);
f0100151:	83 c4 08             	add    $0x8,%esp
f0100154:	56                   	push   %esi
f0100155:	ff 75 10             	pushl  0x10(%ebp)
f0100158:	e8 b0 08 00 00       	call   f0100a0d <vcprintf>
	cprintf("\n");
f010015d:	8d 83 e6 17 ff ff    	lea    -0xe81a(%ebx),%eax
f0100163:	89 04 24             	mov    %eax,(%esp)
f0100166:	e8 d9 08 00 00       	call   f0100a44 <cprintf>
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
f010017a:	81 c3 8e 01 01 00    	add    $0x1018e,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100180:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100183:	83 ec 04             	sub    $0x4,%esp
f0100186:	ff 75 0c             	pushl  0xc(%ebp)
f0100189:	ff 75 08             	pushl  0x8(%ebp)
f010018c:	8d 83 c2 17 ff ff    	lea    -0xe83e(%ebx),%eax
f0100192:	50                   	push   %eax
f0100193:	e8 ac 08 00 00       	call   f0100a44 <cprintf>
	vcprintf(fmt, ap);
f0100198:	83 c4 08             	add    $0x8,%esp
f010019b:	56                   	push   %esi
f010019c:	ff 75 10             	pushl  0x10(%ebp)
f010019f:	e8 69 08 00 00       	call   f0100a0d <vcprintf>
	cprintf("\n");
f01001a4:	8d 83 e6 17 ff ff    	lea    -0xe81a(%ebx),%eax
f01001aa:	89 04 24             	mov    %eax,(%esp)
f01001ad:	e8 92 08 00 00       	call   f0100a44 <cprintf>
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
f01001e8:	81 c6 20 01 01 00    	add    $0x10120,%esi
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
f0100248:	81 c3 c0 00 01 00    	add    $0x100c0,%ebx
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
f0100290:	0f b6 84 13 18 19 ff 	movzbl -0xe6e8(%ebx,%edx,1),%eax
f0100297:	ff 
f0100298:	0b 83 78 1d 00 00    	or     0x1d78(%ebx),%eax
	shift ^= togglecode[data];
f010029e:	0f b6 8c 13 18 18 ff 	movzbl -0xe7e8(%ebx,%edx,1),%ecx
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
f01002fb:	0f b6 84 13 18 19 ff 	movzbl -0xe6e8(%ebx,%edx,1),%eax
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
f0100337:	8d 83 dc 17 ff ff    	lea    -0xe824(%ebx),%eax
f010033d:	50                   	push   %eax
f010033e:	e8 01 07 00 00       	call   f0100a44 <cprintf>
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
f0100372:	81 c3 96 ff 00 00    	add    $0xff96,%ebx
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
f0100548:	e8 fb 10 00 00       	call   f0101648 <memmove>
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
f0100580:	05 88 fd 00 00       	add    $0xfd88,%eax
	if (serial_exists)
f0100585:	80 b8 ac 1f 00 00 00 	cmpb   $0x0,0x1fac(%eax)
f010058c:	75 01                	jne    f010058f <serial_intr+0x14>
f010058e:	c3                   	ret    
{
f010058f:	55                   	push   %ebp
f0100590:	89 e5                	mov    %esp,%ebp
f0100592:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100595:	8d 80 b8 fe fe ff    	lea    -0x10148(%eax),%eax
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
f01005ad:	05 5b fd 00 00       	add    $0xfd5b,%eax
	cons_intr(kbd_proc_data);
f01005b2:	8d 80 36 ff fe ff    	lea    -0x100ca(%eax),%eax
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
f01005cb:	81 c3 3d fd 00 00    	add    $0xfd3d,%ebx
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
f0100621:	81 c3 e7 fc 00 00    	add    $0xfce7,%ebx
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
f0100721:	8d 83 e8 17 ff ff    	lea    -0xe818(%ebx),%eax
f0100727:	50                   	push   %eax
f0100728:	e8 17 03 00 00       	call   f0100a44 <cprintf>
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
f010076b:	81 c3 9d fb 00 00    	add    $0xfb9d,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100771:	83 ec 04             	sub    $0x4,%esp
f0100774:	8d 83 18 1a ff ff    	lea    -0xe5e8(%ebx),%eax
f010077a:	50                   	push   %eax
f010077b:	8d 83 36 1a ff ff    	lea    -0xe5ca(%ebx),%eax
f0100781:	50                   	push   %eax
f0100782:	8d b3 3b 1a ff ff    	lea    -0xe5c5(%ebx),%esi
f0100788:	56                   	push   %esi
f0100789:	e8 b6 02 00 00       	call   f0100a44 <cprintf>
f010078e:	83 c4 0c             	add    $0xc,%esp
f0100791:	8d 83 a4 1a ff ff    	lea    -0xe55c(%ebx),%eax
f0100797:	50                   	push   %eax
f0100798:	8d 83 44 1a ff ff    	lea    -0xe5bc(%ebx),%eax
f010079e:	50                   	push   %eax
f010079f:	56                   	push   %esi
f01007a0:	e8 9f 02 00 00       	call   f0100a44 <cprintf>
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
f01007bf:	81 c3 49 fb 00 00    	add    $0xfb49,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007c5:	8d 83 4d 1a ff ff    	lea    -0xe5b3(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 73 02 00 00       	call   f0100a44 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007d1:	83 c4 08             	add    $0x8,%esp
f01007d4:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007da:	8d 83 cc 1a ff ff    	lea    -0xe534(%ebx),%eax
f01007e0:	50                   	push   %eax
f01007e1:	e8 5e 02 00 00       	call   f0100a44 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e6:	83 c4 0c             	add    $0xc,%esp
f01007e9:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007ef:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007f5:	50                   	push   %eax
f01007f6:	57                   	push   %edi
f01007f7:	8d 83 f4 1a ff ff    	lea    -0xe50c(%ebx),%eax
f01007fd:	50                   	push   %eax
f01007fe:	e8 41 02 00 00       	call   f0100a44 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100803:	83 c4 0c             	add    $0xc,%esp
f0100806:	c7 c0 5d 1a 10 f0    	mov    $0xf0101a5d,%eax
f010080c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100812:	52                   	push   %edx
f0100813:	50                   	push   %eax
f0100814:	8d 83 18 1b ff ff    	lea    -0xe4e8(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 24 02 00 00       	call   f0100a44 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100820:	83 c4 0c             	add    $0xc,%esp
f0100823:	c7 c0 60 20 11 f0    	mov    $0xf0112060,%eax
f0100829:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010082f:	52                   	push   %edx
f0100830:	50                   	push   %eax
f0100831:	8d 83 3c 1b ff ff    	lea    -0xe4c4(%ebx),%eax
f0100837:	50                   	push   %eax
f0100838:	e8 07 02 00 00       	call   f0100a44 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010083d:	83 c4 0c             	add    $0xc,%esp
f0100840:	c7 c6 c0 26 11 f0    	mov    $0xf01126c0,%esi
f0100846:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010084c:	50                   	push   %eax
f010084d:	56                   	push   %esi
f010084e:	8d 83 60 1b ff ff    	lea    -0xe4a0(%ebx),%eax
f0100854:	50                   	push   %eax
f0100855:	e8 ea 01 00 00       	call   f0100a44 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010085a:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010085d:	29 fe                	sub    %edi,%esi
f010085f:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100865:	c1 fe 0a             	sar    $0xa,%esi
f0100868:	56                   	push   %esi
f0100869:	8d 83 84 1b ff ff    	lea    -0xe47c(%ebx),%eax
f010086f:	50                   	push   %eax
f0100870:	e8 cf 01 00 00       	call   f0100a44 <cprintf>
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
	// Your code here.
	return 0;
}
f0100882:	b8 00 00 00 00       	mov    $0x0,%eax
f0100887:	c3                   	ret    

f0100888 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100888:	55                   	push   %ebp
f0100889:	89 e5                	mov    %esp,%ebp
f010088b:	57                   	push   %edi
f010088c:	56                   	push   %esi
f010088d:	53                   	push   %ebx
f010088e:	83 ec 68             	sub    $0x68,%esp
f0100891:	e8 26 f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100896:	81 c3 72 fa 00 00    	add    $0xfa72,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010089c:	8d 83 b0 1b ff ff    	lea    -0xe450(%ebx),%eax
f01008a2:	50                   	push   %eax
f01008a3:	e8 9c 01 00 00       	call   f0100a44 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008a8:	8d 83 d4 1b ff ff    	lea    -0xe42c(%ebx),%eax
f01008ae:	89 04 24             	mov    %eax,(%esp)
f01008b1:	e8 8e 01 00 00       	call   f0100a44 <cprintf>
f01008b6:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01008b9:	8d bb 6a 1a ff ff    	lea    -0xe596(%ebx),%edi
f01008bf:	eb 4a                	jmp    f010090b <monitor+0x83>
f01008c1:	83 ec 08             	sub    $0x8,%esp
f01008c4:	0f be c0             	movsbl %al,%eax
f01008c7:	50                   	push   %eax
f01008c8:	57                   	push   %edi
f01008c9:	e8 f3 0c 00 00       	call   f01015c1 <strchr>
f01008ce:	83 c4 10             	add    $0x10,%esp
f01008d1:	85 c0                	test   %eax,%eax
f01008d3:	74 08                	je     f01008dd <monitor+0x55>
			*buf++ = 0;
f01008d5:	c6 06 00             	movb   $0x0,(%esi)
f01008d8:	8d 76 01             	lea    0x1(%esi),%esi
f01008db:	eb 79                	jmp    f0100956 <monitor+0xce>
		if (*buf == 0)
f01008dd:	80 3e 00             	cmpb   $0x0,(%esi)
f01008e0:	74 7f                	je     f0100961 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f01008e2:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01008e6:	74 0f                	je     f01008f7 <monitor+0x6f>
		argv[argc++] = buf;
f01008e8:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01008eb:	8d 48 01             	lea    0x1(%eax),%ecx
f01008ee:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01008f1:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01008f5:	eb 44                	jmp    f010093b <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008f7:	83 ec 08             	sub    $0x8,%esp
f01008fa:	6a 10                	push   $0x10
f01008fc:	8d 83 6f 1a ff ff    	lea    -0xe591(%ebx),%eax
f0100902:	50                   	push   %eax
f0100903:	e8 3c 01 00 00       	call   f0100a44 <cprintf>
			return 0;
f0100908:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010090b:	8d 83 66 1a ff ff    	lea    -0xe59a(%ebx),%eax
f0100911:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100914:	83 ec 0c             	sub    $0xc,%esp
f0100917:	ff 75 a4             	pushl  -0x5c(%ebp)
f010091a:	e8 4f 0a 00 00       	call   f010136e <readline>
f010091f:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100921:	83 c4 10             	add    $0x10,%esp
f0100924:	85 c0                	test   %eax,%eax
f0100926:	74 ec                	je     f0100914 <monitor+0x8c>
	argv[argc] = 0;
f0100928:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010092f:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100936:	eb 1e                	jmp    f0100956 <monitor+0xce>
			buf++;
f0100938:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010093b:	0f b6 06             	movzbl (%esi),%eax
f010093e:	84 c0                	test   %al,%al
f0100940:	74 14                	je     f0100956 <monitor+0xce>
f0100942:	83 ec 08             	sub    $0x8,%esp
f0100945:	0f be c0             	movsbl %al,%eax
f0100948:	50                   	push   %eax
f0100949:	57                   	push   %edi
f010094a:	e8 72 0c 00 00       	call   f01015c1 <strchr>
f010094f:	83 c4 10             	add    $0x10,%esp
f0100952:	85 c0                	test   %eax,%eax
f0100954:	74 e2                	je     f0100938 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100956:	0f b6 06             	movzbl (%esi),%eax
f0100959:	84 c0                	test   %al,%al
f010095b:	0f 85 60 ff ff ff    	jne    f01008c1 <monitor+0x39>
	argv[argc] = 0;
f0100961:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100964:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f010096b:	00 
	if (argc == 0)
f010096c:	85 c0                	test   %eax,%eax
f010096e:	74 9b                	je     f010090b <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100970:	83 ec 08             	sub    $0x8,%esp
f0100973:	8d 83 36 1a ff ff    	lea    -0xe5ca(%ebx),%eax
f0100979:	50                   	push   %eax
f010097a:	ff 75 a8             	pushl  -0x58(%ebp)
f010097d:	e8 df 0b 00 00       	call   f0101561 <strcmp>
f0100982:	83 c4 10             	add    $0x10,%esp
f0100985:	85 c0                	test   %eax,%eax
f0100987:	74 38                	je     f01009c1 <monitor+0x139>
f0100989:	83 ec 08             	sub    $0x8,%esp
f010098c:	8d 83 44 1a ff ff    	lea    -0xe5bc(%ebx),%eax
f0100992:	50                   	push   %eax
f0100993:	ff 75 a8             	pushl  -0x58(%ebp)
f0100996:	e8 c6 0b 00 00       	call   f0101561 <strcmp>
f010099b:	83 c4 10             	add    $0x10,%esp
f010099e:	85 c0                	test   %eax,%eax
f01009a0:	74 1a                	je     f01009bc <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009a2:	83 ec 08             	sub    $0x8,%esp
f01009a5:	ff 75 a8             	pushl  -0x58(%ebp)
f01009a8:	8d 83 8c 1a ff ff    	lea    -0xe574(%ebx),%eax
f01009ae:	50                   	push   %eax
f01009af:	e8 90 00 00 00       	call   f0100a44 <cprintf>
	return 0;
f01009b4:	83 c4 10             	add    $0x10,%esp
f01009b7:	e9 4f ff ff ff       	jmp    f010090b <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009bc:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f01009c1:	83 ec 04             	sub    $0x4,%esp
f01009c4:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01009c7:	ff 75 08             	pushl  0x8(%ebp)
f01009ca:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009cd:	52                   	push   %edx
f01009ce:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009d1:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f01009d8:	83 c4 10             	add    $0x10,%esp
f01009db:	85 c0                	test   %eax,%eax
f01009dd:	0f 89 28 ff ff ff    	jns    f010090b <monitor+0x83>
				break;
	}
}
f01009e3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009e6:	5b                   	pop    %ebx
f01009e7:	5e                   	pop    %esi
f01009e8:	5f                   	pop    %edi
f01009e9:	5d                   	pop    %ebp
f01009ea:	c3                   	ret    

f01009eb <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009eb:	55                   	push   %ebp
f01009ec:	89 e5                	mov    %esp,%ebp
f01009ee:	53                   	push   %ebx
f01009ef:	83 ec 10             	sub    $0x10,%esp
f01009f2:	e8 c5 f7 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01009f7:	81 c3 11 f9 00 00    	add    $0xf911,%ebx
	cputchar(ch);
f01009fd:	ff 75 08             	pushl  0x8(%ebp)
f0100a00:	e8 2d fd ff ff       	call   f0100732 <cputchar>
	*cnt++;
}
f0100a05:	83 c4 10             	add    $0x10,%esp
f0100a08:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a0b:	c9                   	leave  
f0100a0c:	c3                   	ret    

f0100a0d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a0d:	55                   	push   %ebp
f0100a0e:	89 e5                	mov    %esp,%ebp
f0100a10:	53                   	push   %ebx
f0100a11:	83 ec 14             	sub    $0x14,%esp
f0100a14:	e8 a3 f7 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100a19:	81 c3 ef f8 00 00    	add    $0xf8ef,%ebx
	int cnt = 0;
f0100a1f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a26:	ff 75 0c             	pushl  0xc(%ebp)
f0100a29:	ff 75 08             	pushl  0x8(%ebp)
f0100a2c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a2f:	50                   	push   %eax
f0100a30:	8d 83 e3 06 ff ff    	lea    -0xf91d(%ebx),%eax
f0100a36:	50                   	push   %eax
f0100a37:	e8 17 04 00 00       	call   f0100e53 <vprintfmt>
	return cnt;
}
f0100a3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a3f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a42:	c9                   	leave  
f0100a43:	c3                   	ret    

f0100a44 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a44:	55                   	push   %ebp
f0100a45:	89 e5                	mov    %esp,%ebp
f0100a47:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a4a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a4d:	50                   	push   %eax
f0100a4e:	ff 75 08             	pushl  0x8(%ebp)
f0100a51:	e8 b7 ff ff ff       	call   f0100a0d <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a56:	c9                   	leave  
f0100a57:	c3                   	ret    

f0100a58 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a58:	55                   	push   %ebp
f0100a59:	89 e5                	mov    %esp,%ebp
f0100a5b:	57                   	push   %edi
f0100a5c:	56                   	push   %esi
f0100a5d:	53                   	push   %ebx
f0100a5e:	83 ec 14             	sub    $0x14,%esp
f0100a61:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a64:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a67:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a6a:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a6d:	8b 1a                	mov    (%edx),%ebx
f0100a6f:	8b 01                	mov    (%ecx),%eax
f0100a71:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a74:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a7b:	eb 2f                	jmp    f0100aac <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100a7d:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100a80:	39 c3                	cmp    %eax,%ebx
f0100a82:	7f 4e                	jg     f0100ad2 <stab_binsearch+0x7a>
f0100a84:	0f b6 0a             	movzbl (%edx),%ecx
f0100a87:	83 ea 0c             	sub    $0xc,%edx
f0100a8a:	39 f1                	cmp    %esi,%ecx
f0100a8c:	75 ef                	jne    f0100a7d <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a8e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a91:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a94:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a98:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a9b:	73 3a                	jae    f0100ad7 <stab_binsearch+0x7f>
			*region_left = m;
f0100a9d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100aa0:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100aa2:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0100aa5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100aac:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100aaf:	7f 53                	jg     f0100b04 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0100ab1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ab4:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0100ab7:	89 d0                	mov    %edx,%eax
f0100ab9:	c1 e8 1f             	shr    $0x1f,%eax
f0100abc:	01 d0                	add    %edx,%eax
f0100abe:	89 c7                	mov    %eax,%edi
f0100ac0:	d1 ff                	sar    %edi
f0100ac2:	83 e0 fe             	and    $0xfffffffe,%eax
f0100ac5:	01 f8                	add    %edi,%eax
f0100ac7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100aca:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100ace:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0100ad0:	eb ae                	jmp    f0100a80 <stab_binsearch+0x28>
			l = true_m + 1;
f0100ad2:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100ad5:	eb d5                	jmp    f0100aac <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100ad7:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100ada:	76 14                	jbe    f0100af0 <stab_binsearch+0x98>
			*region_right = m - 1;
f0100adc:	83 e8 01             	sub    $0x1,%eax
f0100adf:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100ae2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100ae5:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0100ae7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100aee:	eb bc                	jmp    f0100aac <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100af0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100af3:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0100af5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100af9:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0100afb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b02:	eb a8                	jmp    f0100aac <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100b04:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b08:	75 15                	jne    f0100b1f <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f0100b0a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b0d:	8b 00                	mov    (%eax),%eax
f0100b0f:	83 e8 01             	sub    $0x1,%eax
f0100b12:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100b15:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100b17:	83 c4 14             	add    $0x14,%esp
f0100b1a:	5b                   	pop    %ebx
f0100b1b:	5e                   	pop    %esi
f0100b1c:	5f                   	pop    %edi
f0100b1d:	5d                   	pop    %ebp
f0100b1e:	c3                   	ret    
		for (l = *region_right;
f0100b1f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b22:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b24:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b27:	8b 0f                	mov    (%edi),%ecx
f0100b29:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b2c:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b2f:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0100b33:	39 c1                	cmp    %eax,%ecx
f0100b35:	7d 0f                	jge    f0100b46 <stab_binsearch+0xee>
		     l > *region_left && stabs[l].n_type != type;
f0100b37:	0f b6 1a             	movzbl (%edx),%ebx
f0100b3a:	83 ea 0c             	sub    $0xc,%edx
f0100b3d:	39 f3                	cmp    %esi,%ebx
f0100b3f:	74 05                	je     f0100b46 <stab_binsearch+0xee>
		     l--)
f0100b41:	83 e8 01             	sub    $0x1,%eax
f0100b44:	eb ed                	jmp    f0100b33 <stab_binsearch+0xdb>
		*region_left = l;
f0100b46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b49:	89 07                	mov    %eax,(%edi)
}
f0100b4b:	eb ca                	jmp    f0100b17 <stab_binsearch+0xbf>

f0100b4d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b4d:	55                   	push   %ebp
f0100b4e:	89 e5                	mov    %esp,%ebp
f0100b50:	57                   	push   %edi
f0100b51:	56                   	push   %esi
f0100b52:	53                   	push   %ebx
f0100b53:	83 ec 2c             	sub    $0x2c,%esp
f0100b56:	e8 fc 01 00 00       	call   f0100d57 <__x86.get_pc_thunk.cx>
f0100b5b:	81 c1 ad f7 00 00    	add    $0xf7ad,%ecx
f0100b61:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100b64:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100b67:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b6a:	8d 81 f9 1b ff ff    	lea    -0xe407(%ecx),%eax
f0100b70:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100b72:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100b79:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100b7c:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100b83:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100b86:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b8d:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100b93:	0f 86 f4 00 00 00    	jbe    f0100c8d <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b99:	c7 c0 cd 58 10 f0    	mov    $0xf01058cd,%eax
f0100b9f:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100ba5:	0f 86 88 01 00 00    	jbe    f0100d33 <debuginfo_eip+0x1e6>
f0100bab:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100bae:	c7 c0 f5 6d 10 f0    	mov    $0xf0106df5,%eax
f0100bb4:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100bb8:	0f 85 7c 01 00 00    	jne    f0100d3a <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bbe:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bc5:	c7 c0 1c 21 10 f0    	mov    $0xf010211c,%eax
f0100bcb:	c7 c2 cc 58 10 f0    	mov    $0xf01058cc,%edx
f0100bd1:	29 c2                	sub    %eax,%edx
f0100bd3:	c1 fa 02             	sar    $0x2,%edx
f0100bd6:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100bdc:	83 ea 01             	sub    $0x1,%edx
f0100bdf:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100be2:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100be5:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100be8:	83 ec 08             	sub    $0x8,%esp
f0100beb:	53                   	push   %ebx
f0100bec:	6a 64                	push   $0x64
f0100bee:	e8 65 fe ff ff       	call   f0100a58 <stab_binsearch>
	if (lfile == 0)
f0100bf3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bf6:	83 c4 10             	add    $0x10,%esp
f0100bf9:	85 c0                	test   %eax,%eax
f0100bfb:	0f 84 40 01 00 00    	je     f0100d41 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c01:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c04:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c07:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c0a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c0d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c10:	83 ec 08             	sub    $0x8,%esp
f0100c13:	53                   	push   %ebx
f0100c14:	6a 24                	push   $0x24
f0100c16:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100c19:	c7 c0 1c 21 10 f0    	mov    $0xf010211c,%eax
f0100c1f:	e8 34 fe ff ff       	call   f0100a58 <stab_binsearch>

	if (lfun <= rfun) {
f0100c24:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100c27:	83 c4 10             	add    $0x10,%esp
f0100c2a:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100c2d:	7f 79                	jg     f0100ca8 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c2f:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c32:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c35:	c7 c2 1c 21 10 f0    	mov    $0xf010211c,%edx
f0100c3b:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100c3e:	8b 11                	mov    (%ecx),%edx
f0100c40:	c7 c0 f5 6d 10 f0    	mov    $0xf0106df5,%eax
f0100c46:	81 e8 cd 58 10 f0    	sub    $0xf01058cd,%eax
f0100c4c:	39 c2                	cmp    %eax,%edx
f0100c4e:	73 09                	jae    f0100c59 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c50:	81 c2 cd 58 10 f0    	add    $0xf01058cd,%edx
f0100c56:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c59:	8b 41 08             	mov    0x8(%ecx),%eax
f0100c5c:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c5f:	83 ec 08             	sub    $0x8,%esp
f0100c62:	6a 3a                	push   $0x3a
f0100c64:	ff 77 08             	pushl  0x8(%edi)
f0100c67:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c6a:	e8 75 09 00 00       	call   f01015e4 <strfind>
f0100c6f:	2b 47 08             	sub    0x8(%edi),%eax
f0100c72:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c75:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100c78:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c7b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100c7e:	c7 c2 1c 21 10 f0    	mov    $0xf010211c,%edx
f0100c84:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100c88:	83 c4 10             	add    $0x10,%esp
f0100c8b:	eb 29                	jmp    f0100cb6 <debuginfo_eip+0x169>
  	        panic("User address");
f0100c8d:	83 ec 04             	sub    $0x4,%esp
f0100c90:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c93:	8d 83 03 1c ff ff    	lea    -0xe3fd(%ebx),%eax
f0100c99:	50                   	push   %eax
f0100c9a:	6a 7f                	push   $0x7f
f0100c9c:	8d 83 10 1c ff ff    	lea    -0xe3f0(%ebx),%eax
f0100ca2:	50                   	push   %eax
f0100ca3:	e8 5e f4 ff ff       	call   f0100106 <_panic>
		info->eip_fn_addr = addr;
f0100ca8:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100cab:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cae:	eb af                	jmp    f0100c5f <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100cb0:	83 ee 01             	sub    $0x1,%esi
f0100cb3:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100cb6:	39 f3                	cmp    %esi,%ebx
f0100cb8:	7f 3a                	jg     f0100cf4 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100cba:	0f b6 10             	movzbl (%eax),%edx
f0100cbd:	80 fa 84             	cmp    $0x84,%dl
f0100cc0:	74 0b                	je     f0100ccd <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cc2:	80 fa 64             	cmp    $0x64,%dl
f0100cc5:	75 e9                	jne    f0100cb0 <debuginfo_eip+0x163>
f0100cc7:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100ccb:	74 e3                	je     f0100cb0 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100ccd:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100cd0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cd3:	c7 c0 1c 21 10 f0    	mov    $0xf010211c,%eax
f0100cd9:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100cdc:	c7 c0 f5 6d 10 f0    	mov    $0xf0106df5,%eax
f0100ce2:	81 e8 cd 58 10 f0    	sub    $0xf01058cd,%eax
f0100ce8:	39 c2                	cmp    %eax,%edx
f0100cea:	73 08                	jae    f0100cf4 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cec:	81 c2 cd 58 10 f0    	add    $0xf01058cd,%edx
f0100cf2:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cf4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100cf7:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cfa:	ba 00 00 00 00       	mov    $0x0,%edx
	if (lfun < rfun)
f0100cff:	39 c8                	cmp    %ecx,%eax
f0100d01:	7d 4a                	jge    f0100d4d <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100d03:	8d 50 01             	lea    0x1(%eax),%edx
f0100d06:	8d 1c 40             	lea    (%eax,%eax,2),%ebx
f0100d09:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d0c:	c7 c0 1c 21 10 f0    	mov    $0xf010211c,%eax
f0100d12:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100d16:	eb 07                	jmp    f0100d1f <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100d18:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100d1c:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100d1f:	39 d1                	cmp    %edx,%ecx
f0100d21:	74 25                	je     f0100d48 <debuginfo_eip+0x1fb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d23:	83 c0 0c             	add    $0xc,%eax
f0100d26:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100d2a:	74 ec                	je     f0100d18 <debuginfo_eip+0x1cb>
	return 0;
f0100d2c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d31:	eb 1a                	jmp    f0100d4d <debuginfo_eip+0x200>
		return -1;
f0100d33:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100d38:	eb 13                	jmp    f0100d4d <debuginfo_eip+0x200>
f0100d3a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100d3f:	eb 0c                	jmp    f0100d4d <debuginfo_eip+0x200>
		return -1;
f0100d41:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100d46:	eb 05                	jmp    f0100d4d <debuginfo_eip+0x200>
	return 0;
f0100d48:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d4d:	89 d0                	mov    %edx,%eax
f0100d4f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d52:	5b                   	pop    %ebx
f0100d53:	5e                   	pop    %esi
f0100d54:	5f                   	pop    %edi
f0100d55:	5d                   	pop    %ebp
f0100d56:	c3                   	ret    

f0100d57 <__x86.get_pc_thunk.cx>:
f0100d57:	8b 0c 24             	mov    (%esp),%ecx
f0100d5a:	c3                   	ret    

f0100d5b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d5b:	55                   	push   %ebp
f0100d5c:	89 e5                	mov    %esp,%ebp
f0100d5e:	57                   	push   %edi
f0100d5f:	56                   	push   %esi
f0100d60:	53                   	push   %ebx
f0100d61:	83 ec 2c             	sub    $0x2c,%esp
f0100d64:	e8 ee ff ff ff       	call   f0100d57 <__x86.get_pc_thunk.cx>
f0100d69:	81 c1 9f f5 00 00    	add    $0xf59f,%ecx
f0100d6f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d72:	89 c7                	mov    %eax,%edi
f0100d74:	89 d6                	mov    %edx,%esi
f0100d76:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d79:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d7c:	89 d1                	mov    %edx,%ecx
f0100d7e:	89 c2                	mov    %eax,%edx
f0100d80:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d83:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100d86:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d89:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d8c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d8f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d96:	39 c2                	cmp    %eax,%edx
f0100d98:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0100d9b:	72 41                	jb     f0100dde <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d9d:	83 ec 0c             	sub    $0xc,%esp
f0100da0:	ff 75 18             	pushl  0x18(%ebp)
f0100da3:	83 eb 01             	sub    $0x1,%ebx
f0100da6:	53                   	push   %ebx
f0100da7:	50                   	push   %eax
f0100da8:	83 ec 08             	sub    $0x8,%esp
f0100dab:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100dae:	ff 75 e0             	pushl  -0x20(%ebp)
f0100db1:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100db4:	ff 75 d0             	pushl  -0x30(%ebp)
f0100db7:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100dba:	e8 41 0a 00 00       	call   f0101800 <__udivdi3>
f0100dbf:	83 c4 18             	add    $0x18,%esp
f0100dc2:	52                   	push   %edx
f0100dc3:	50                   	push   %eax
f0100dc4:	89 f2                	mov    %esi,%edx
f0100dc6:	89 f8                	mov    %edi,%eax
f0100dc8:	e8 8e ff ff ff       	call   f0100d5b <printnum>
f0100dcd:	83 c4 20             	add    $0x20,%esp
f0100dd0:	eb 13                	jmp    f0100de5 <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dd2:	83 ec 08             	sub    $0x8,%esp
f0100dd5:	56                   	push   %esi
f0100dd6:	ff 75 18             	pushl  0x18(%ebp)
f0100dd9:	ff d7                	call   *%edi
f0100ddb:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100dde:	83 eb 01             	sub    $0x1,%ebx
f0100de1:	85 db                	test   %ebx,%ebx
f0100de3:	7f ed                	jg     f0100dd2 <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100de5:	83 ec 08             	sub    $0x8,%esp
f0100de8:	56                   	push   %esi
f0100de9:	83 ec 04             	sub    $0x4,%esp
f0100dec:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100def:	ff 75 e0             	pushl  -0x20(%ebp)
f0100df2:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100df5:	ff 75 d0             	pushl  -0x30(%ebp)
f0100df8:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100dfb:	e8 10 0b 00 00       	call   f0101910 <__umoddi3>
f0100e00:	83 c4 14             	add    $0x14,%esp
f0100e03:	0f be 84 03 1e 1c ff 	movsbl -0xe3e2(%ebx,%eax,1),%eax
f0100e0a:	ff 
f0100e0b:	50                   	push   %eax
f0100e0c:	ff d7                	call   *%edi
}
f0100e0e:	83 c4 10             	add    $0x10,%esp
f0100e11:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e14:	5b                   	pop    %ebx
f0100e15:	5e                   	pop    %esi
f0100e16:	5f                   	pop    %edi
f0100e17:	5d                   	pop    %ebp
f0100e18:	c3                   	ret    

f0100e19 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e19:	55                   	push   %ebp
f0100e1a:	89 e5                	mov    %esp,%ebp
f0100e1c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e1f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e23:	8b 10                	mov    (%eax),%edx
f0100e25:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e28:	73 0a                	jae    f0100e34 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e2a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e2d:	89 08                	mov    %ecx,(%eax)
f0100e2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e32:	88 02                	mov    %al,(%edx)
}
f0100e34:	5d                   	pop    %ebp
f0100e35:	c3                   	ret    

f0100e36 <printfmt>:
{
f0100e36:	55                   	push   %ebp
f0100e37:	89 e5                	mov    %esp,%ebp
f0100e39:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100e3c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e3f:	50                   	push   %eax
f0100e40:	ff 75 10             	pushl  0x10(%ebp)
f0100e43:	ff 75 0c             	pushl  0xc(%ebp)
f0100e46:	ff 75 08             	pushl  0x8(%ebp)
f0100e49:	e8 05 00 00 00       	call   f0100e53 <vprintfmt>
}
f0100e4e:	83 c4 10             	add    $0x10,%esp
f0100e51:	c9                   	leave  
f0100e52:	c3                   	ret    

f0100e53 <vprintfmt>:
{
f0100e53:	55                   	push   %ebp
f0100e54:	89 e5                	mov    %esp,%ebp
f0100e56:	57                   	push   %edi
f0100e57:	56                   	push   %esi
f0100e58:	53                   	push   %ebx
f0100e59:	83 ec 3c             	sub    $0x3c,%esp
f0100e5c:	e8 f8 f8 ff ff       	call   f0100759 <__x86.get_pc_thunk.ax>
f0100e61:	05 a7 f4 00 00       	add    $0xf4a7,%eax
f0100e66:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e69:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e6c:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e6f:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e72:	8d 80 20 1d 00 00    	lea    0x1d20(%eax),%eax
f0100e78:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100e7b:	eb 0a                	jmp    f0100e87 <vprintfmt+0x34>
			putch(ch, putdat);
f0100e7d:	83 ec 08             	sub    $0x8,%esp
f0100e80:	57                   	push   %edi
f0100e81:	50                   	push   %eax
f0100e82:	ff d6                	call   *%esi
f0100e84:	83 c4 10             	add    $0x10,%esp
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e87:	83 c3 01             	add    $0x1,%ebx
f0100e8a:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0100e8e:	83 f8 25             	cmp    $0x25,%eax
f0100e91:	74 0c                	je     f0100e9f <vprintfmt+0x4c>
			if (ch == '\0')
f0100e93:	85 c0                	test   %eax,%eax
f0100e95:	75 e6                	jne    f0100e7d <vprintfmt+0x2a>
}
f0100e97:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e9a:	5b                   	pop    %ebx
f0100e9b:	5e                   	pop    %esi
f0100e9c:	5f                   	pop    %edi
f0100e9d:	5d                   	pop    %ebp
f0100e9e:	c3                   	ret    
		padc = ' ';
f0100e9f:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f0100ea3:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f0100eaa:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0100eb1:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f0100eb8:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ebd:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100ec0:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100ec3:	8d 43 01             	lea    0x1(%ebx),%eax
f0100ec6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ec9:	0f b6 13             	movzbl (%ebx),%edx
f0100ecc:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100ecf:	3c 55                	cmp    $0x55,%al
f0100ed1:	0f 87 fb 03 00 00    	ja     f01012d2 <.L20>
f0100ed7:	0f b6 c0             	movzbl %al,%eax
f0100eda:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100edd:	89 ce                	mov    %ecx,%esi
f0100edf:	03 b4 81 ac 1c ff ff 	add    -0xe354(%ecx,%eax,4),%esi
f0100ee6:	ff e6                	jmp    *%esi

f0100ee8 <.L68>:
f0100ee8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f0100eeb:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f0100eef:	eb d2                	jmp    f0100ec3 <vprintfmt+0x70>

f0100ef1 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ef4:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f0100ef8:	eb c9                	jmp    f0100ec3 <vprintfmt+0x70>

f0100efa <.L31>:
f0100efa:	0f b6 d2             	movzbl %dl,%edx
f0100efd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0100f00:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f05:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0100f08:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f0b:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f0f:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0100f12:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f15:	83 f9 09             	cmp    $0x9,%ecx
f0100f18:	77 58                	ja     f0100f72 <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0100f1a:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0100f1d:	eb e9                	jmp    f0100f08 <.L31+0xe>

f0100f1f <.L34>:
			precision = va_arg(ap, int);
f0100f1f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f22:	8b 00                	mov    (%eax),%eax
f0100f24:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f27:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2a:	8d 40 04             	lea    0x4(%eax),%eax
f0100f2d:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f30:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f0100f33:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100f37:	79 8a                	jns    f0100ec3 <vprintfmt+0x70>
				width = precision, precision = -1;
f0100f39:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f3c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100f3f:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100f46:	e9 78 ff ff ff       	jmp    f0100ec3 <vprintfmt+0x70>

f0100f4b <.L33>:
f0100f4b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f4e:	85 c0                	test   %eax,%eax
f0100f50:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f55:	0f 49 d0             	cmovns %eax,%edx
f0100f58:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f5b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0100f5e:	e9 60 ff ff ff       	jmp    f0100ec3 <vprintfmt+0x70>

f0100f63 <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f0100f63:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0100f66:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0100f6d:	e9 51 ff ff ff       	jmp    f0100ec3 <vprintfmt+0x70>
f0100f72:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f75:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f78:	eb b9                	jmp    f0100f33 <.L34+0x14>

f0100f7a <.L27>:
			lflag++;
f0100f7a:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f7e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0100f81:	e9 3d ff ff ff       	jmp    f0100ec3 <vprintfmt+0x70>

f0100f86 <.L30>:
			putch(va_arg(ap, int), putdat);
f0100f86:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f89:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f8c:	8d 58 04             	lea    0x4(%eax),%ebx
f0100f8f:	83 ec 08             	sub    $0x8,%esp
f0100f92:	57                   	push   %edi
f0100f93:	ff 30                	pushl  (%eax)
f0100f95:	ff d6                	call   *%esi
			break;
f0100f97:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0100f9a:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f0100f9d:	e9 c6 02 00 00       	jmp    f0101268 <.L25+0x45>

f0100fa2 <.L28>:
			err = va_arg(ap, int);
f0100fa2:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fa5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa8:	8d 58 04             	lea    0x4(%eax),%ebx
f0100fab:	8b 00                	mov    (%eax),%eax
f0100fad:	99                   	cltd   
f0100fae:	31 d0                	xor    %edx,%eax
f0100fb0:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fb2:	83 f8 06             	cmp    $0x6,%eax
f0100fb5:	7f 27                	jg     f0100fde <.L28+0x3c>
f0100fb7:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0100fba:	8b 14 82             	mov    (%edx,%eax,4),%edx
f0100fbd:	85 d2                	test   %edx,%edx
f0100fbf:	74 1d                	je     f0100fde <.L28+0x3c>
				printfmt(putch, putdat, "%s", p);
f0100fc1:	52                   	push   %edx
f0100fc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fc5:	8d 80 3f 1c ff ff    	lea    -0xe3c1(%eax),%eax
f0100fcb:	50                   	push   %eax
f0100fcc:	57                   	push   %edi
f0100fcd:	56                   	push   %esi
f0100fce:	e8 63 fe ff ff       	call   f0100e36 <printfmt>
f0100fd3:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100fd6:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0100fd9:	e9 8a 02 00 00       	jmp    f0101268 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f0100fde:	50                   	push   %eax
f0100fdf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fe2:	8d 80 36 1c ff ff    	lea    -0xe3ca(%eax),%eax
f0100fe8:	50                   	push   %eax
f0100fe9:	57                   	push   %edi
f0100fea:	56                   	push   %esi
f0100feb:	e8 46 fe ff ff       	call   f0100e36 <printfmt>
f0100ff0:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100ff3:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0100ff6:	e9 6d 02 00 00       	jmp    f0101268 <.L25+0x45>

f0100ffb <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f0100ffb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ffe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101001:	83 c0 04             	add    $0x4,%eax
f0101004:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0101007:	8b 45 14             	mov    0x14(%ebp),%eax
f010100a:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f010100c:	85 d2                	test   %edx,%edx
f010100e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101011:	8d 80 2f 1c ff ff    	lea    -0xe3d1(%eax),%eax
f0101017:	0f 45 c2             	cmovne %edx,%eax
f010101a:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f010101d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101021:	7e 06                	jle    f0101029 <.L24+0x2e>
f0101023:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f0101027:	75 0d                	jne    f0101036 <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101029:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010102c:	89 c3                	mov    %eax,%ebx
f010102e:	03 45 d4             	add    -0x2c(%ebp),%eax
f0101031:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101034:	eb 58                	jmp    f010108e <.L24+0x93>
f0101036:	83 ec 08             	sub    $0x8,%esp
f0101039:	ff 75 d8             	pushl  -0x28(%ebp)
f010103c:	ff 75 c8             	pushl  -0x38(%ebp)
f010103f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101042:	e8 44 04 00 00       	call   f010148b <strnlen>
f0101047:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010104a:	29 c2                	sub    %eax,%edx
f010104c:	89 55 bc             	mov    %edx,-0x44(%ebp)
f010104f:	83 c4 10             	add    $0x10,%esp
f0101052:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f0101054:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0101058:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010105b:	eb 0f                	jmp    f010106c <.L24+0x71>
					putch(padc, putdat);
f010105d:	83 ec 08             	sub    $0x8,%esp
f0101060:	57                   	push   %edi
f0101061:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101064:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101066:	83 eb 01             	sub    $0x1,%ebx
f0101069:	83 c4 10             	add    $0x10,%esp
f010106c:	85 db                	test   %ebx,%ebx
f010106e:	7f ed                	jg     f010105d <.L24+0x62>
f0101070:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0101073:	85 d2                	test   %edx,%edx
f0101075:	b8 00 00 00 00       	mov    $0x0,%eax
f010107a:	0f 49 c2             	cmovns %edx,%eax
f010107d:	29 c2                	sub    %eax,%edx
f010107f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0101082:	eb a5                	jmp    f0101029 <.L24+0x2e>
					putch(ch, putdat);
f0101084:	83 ec 08             	sub    $0x8,%esp
f0101087:	57                   	push   %edi
f0101088:	52                   	push   %edx
f0101089:	ff d6                	call   *%esi
f010108b:	83 c4 10             	add    $0x10,%esp
f010108e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101091:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101093:	83 c3 01             	add    $0x1,%ebx
f0101096:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f010109a:	0f be d0             	movsbl %al,%edx
f010109d:	85 d2                	test   %edx,%edx
f010109f:	74 4b                	je     f01010ec <.L24+0xf1>
f01010a1:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010a5:	78 06                	js     f01010ad <.L24+0xb2>
f01010a7:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f01010ab:	78 1e                	js     f01010cb <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f01010ad:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01010b1:	74 d1                	je     f0101084 <.L24+0x89>
f01010b3:	0f be c0             	movsbl %al,%eax
f01010b6:	83 e8 20             	sub    $0x20,%eax
f01010b9:	83 f8 5e             	cmp    $0x5e,%eax
f01010bc:	76 c6                	jbe    f0101084 <.L24+0x89>
					putch('?', putdat);
f01010be:	83 ec 08             	sub    $0x8,%esp
f01010c1:	57                   	push   %edi
f01010c2:	6a 3f                	push   $0x3f
f01010c4:	ff d6                	call   *%esi
f01010c6:	83 c4 10             	add    $0x10,%esp
f01010c9:	eb c3                	jmp    f010108e <.L24+0x93>
f01010cb:	89 cb                	mov    %ecx,%ebx
f01010cd:	eb 0e                	jmp    f01010dd <.L24+0xe2>
				putch(' ', putdat);
f01010cf:	83 ec 08             	sub    $0x8,%esp
f01010d2:	57                   	push   %edi
f01010d3:	6a 20                	push   $0x20
f01010d5:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01010d7:	83 eb 01             	sub    $0x1,%ebx
f01010da:	83 c4 10             	add    $0x10,%esp
f01010dd:	85 db                	test   %ebx,%ebx
f01010df:	7f ee                	jg     f01010cf <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f01010e1:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01010e4:	89 45 14             	mov    %eax,0x14(%ebp)
f01010e7:	e9 7c 01 00 00       	jmp    f0101268 <.L25+0x45>
f01010ec:	89 cb                	mov    %ecx,%ebx
f01010ee:	eb ed                	jmp    f01010dd <.L24+0xe2>

f01010f0 <.L29>:
	if (lflag >= 2)
f01010f0:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01010f3:	8b 75 08             	mov    0x8(%ebp),%esi
f01010f6:	83 f9 01             	cmp    $0x1,%ecx
f01010f9:	7f 1b                	jg     f0101116 <.L29+0x26>
	else if (lflag)
f01010fb:	85 c9                	test   %ecx,%ecx
f01010fd:	74 63                	je     f0101162 <.L29+0x72>
		return va_arg(*ap, long);
f01010ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101102:	8b 00                	mov    (%eax),%eax
f0101104:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101107:	99                   	cltd   
f0101108:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010110b:	8b 45 14             	mov    0x14(%ebp),%eax
f010110e:	8d 40 04             	lea    0x4(%eax),%eax
f0101111:	89 45 14             	mov    %eax,0x14(%ebp)
f0101114:	eb 17                	jmp    f010112d <.L29+0x3d>
		return va_arg(*ap, long long);
f0101116:	8b 45 14             	mov    0x14(%ebp),%eax
f0101119:	8b 50 04             	mov    0x4(%eax),%edx
f010111c:	8b 00                	mov    (%eax),%eax
f010111e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101121:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101124:	8b 45 14             	mov    0x14(%ebp),%eax
f0101127:	8d 40 08             	lea    0x8(%eax),%eax
f010112a:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010112d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101130:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101133:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0101138:	85 c9                	test   %ecx,%ecx
f010113a:	0f 89 0e 01 00 00    	jns    f010124e <.L25+0x2b>
				putch('-', putdat);
f0101140:	83 ec 08             	sub    $0x8,%esp
f0101143:	57                   	push   %edi
f0101144:	6a 2d                	push   $0x2d
f0101146:	ff d6                	call   *%esi
				num = -(long long) num;
f0101148:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010114b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010114e:	f7 da                	neg    %edx
f0101150:	83 d1 00             	adc    $0x0,%ecx
f0101153:	f7 d9                	neg    %ecx
f0101155:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101158:	b8 0a 00 00 00       	mov    $0xa,%eax
f010115d:	e9 ec 00 00 00       	jmp    f010124e <.L25+0x2b>
		return va_arg(*ap, int);
f0101162:	8b 45 14             	mov    0x14(%ebp),%eax
f0101165:	8b 00                	mov    (%eax),%eax
f0101167:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010116a:	99                   	cltd   
f010116b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010116e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101171:	8d 40 04             	lea    0x4(%eax),%eax
f0101174:	89 45 14             	mov    %eax,0x14(%ebp)
f0101177:	eb b4                	jmp    f010112d <.L29+0x3d>

f0101179 <.L23>:
	if (lflag >= 2)
f0101179:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010117c:	8b 75 08             	mov    0x8(%ebp),%esi
f010117f:	83 f9 01             	cmp    $0x1,%ecx
f0101182:	7f 1e                	jg     f01011a2 <.L23+0x29>
	else if (lflag)
f0101184:	85 c9                	test   %ecx,%ecx
f0101186:	74 32                	je     f01011ba <.L23+0x41>
		return va_arg(*ap, unsigned long);
f0101188:	8b 45 14             	mov    0x14(%ebp),%eax
f010118b:	8b 10                	mov    (%eax),%edx
f010118d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101192:	8d 40 04             	lea    0x4(%eax),%eax
f0101195:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101198:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long);
f010119d:	e9 ac 00 00 00       	jmp    f010124e <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01011a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a5:	8b 10                	mov    (%eax),%edx
f01011a7:	8b 48 04             	mov    0x4(%eax),%ecx
f01011aa:	8d 40 08             	lea    0x8(%eax),%eax
f01011ad:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011b0:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned long long);
f01011b5:	e9 94 00 00 00       	jmp    f010124e <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01011ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01011bd:	8b 10                	mov    (%eax),%edx
f01011bf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011c4:	8d 40 04             	lea    0x4(%eax),%eax
f01011c7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011ca:	b8 0a 00 00 00       	mov    $0xa,%eax
		return va_arg(*ap, unsigned int);
f01011cf:	eb 7d                	jmp    f010124e <.L25+0x2b>

f01011d1 <.L26>:
	if (lflag >= 2)
f01011d1:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01011d4:	8b 75 08             	mov    0x8(%ebp),%esi
f01011d7:	83 f9 01             	cmp    $0x1,%ecx
f01011da:	7f 1b                	jg     f01011f7 <.L26+0x26>
	else if (lflag)
f01011dc:	85 c9                	test   %ecx,%ecx
f01011de:	74 2c                	je     f010120c <.L26+0x3b>
		return va_arg(*ap, unsigned long);
f01011e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e3:	8b 10                	mov    (%eax),%edx
f01011e5:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011ea:	8d 40 04             	lea    0x4(%eax),%eax
f01011ed:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01011f0:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long);
f01011f5:	eb 57                	jmp    f010124e <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01011f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01011fa:	8b 10                	mov    (%eax),%edx
f01011fc:	8b 48 04             	mov    0x4(%eax),%ecx
f01011ff:	8d 40 08             	lea    0x8(%eax),%eax
f0101202:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101205:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned long long);
f010120a:	eb 42                	jmp    f010124e <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f010120c:	8b 45 14             	mov    0x14(%ebp),%eax
f010120f:	8b 10                	mov    (%eax),%edx
f0101211:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101216:	8d 40 04             	lea    0x4(%eax),%eax
f0101219:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010121c:	b8 08 00 00 00       	mov    $0x8,%eax
		return va_arg(*ap, unsigned int);
f0101221:	eb 2b                	jmp    f010124e <.L25+0x2b>

f0101223 <.L25>:
			putch('0', putdat);
f0101223:	8b 75 08             	mov    0x8(%ebp),%esi
f0101226:	83 ec 08             	sub    $0x8,%esp
f0101229:	57                   	push   %edi
f010122a:	6a 30                	push   $0x30
f010122c:	ff d6                	call   *%esi
			putch('x', putdat);
f010122e:	83 c4 08             	add    $0x8,%esp
f0101231:	57                   	push   %edi
f0101232:	6a 78                	push   $0x78
f0101234:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101236:	8b 45 14             	mov    0x14(%ebp),%eax
f0101239:	8b 10                	mov    (%eax),%edx
f010123b:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101240:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101243:	8d 40 04             	lea    0x4(%eax),%eax
f0101246:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101249:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010124e:	83 ec 0c             	sub    $0xc,%esp
f0101251:	0f be 5d cf          	movsbl -0x31(%ebp),%ebx
f0101255:	53                   	push   %ebx
f0101256:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101259:	50                   	push   %eax
f010125a:	51                   	push   %ecx
f010125b:	52                   	push   %edx
f010125c:	89 fa                	mov    %edi,%edx
f010125e:	89 f0                	mov    %esi,%eax
f0101260:	e8 f6 fa ff ff       	call   f0100d5b <printnum>
			break;
f0101265:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101268:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010126b:	e9 17 fc ff ff       	jmp    f0100e87 <vprintfmt+0x34>

f0101270 <.L21>:
	if (lflag >= 2)
f0101270:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101273:	8b 75 08             	mov    0x8(%ebp),%esi
f0101276:	83 f9 01             	cmp    $0x1,%ecx
f0101279:	7f 1b                	jg     f0101296 <.L21+0x26>
	else if (lflag)
f010127b:	85 c9                	test   %ecx,%ecx
f010127d:	74 2c                	je     f01012ab <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f010127f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101282:	8b 10                	mov    (%eax),%edx
f0101284:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101289:	8d 40 04             	lea    0x4(%eax),%eax
f010128c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010128f:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long);
f0101294:	eb b8                	jmp    f010124e <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0101296:	8b 45 14             	mov    0x14(%ebp),%eax
f0101299:	8b 10                	mov    (%eax),%edx
f010129b:	8b 48 04             	mov    0x4(%eax),%ecx
f010129e:	8d 40 08             	lea    0x8(%eax),%eax
f01012a1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012a4:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned long long);
f01012a9:	eb a3                	jmp    f010124e <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01012ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ae:	8b 10                	mov    (%eax),%edx
f01012b0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012b5:	8d 40 04             	lea    0x4(%eax),%eax
f01012b8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012bb:	b8 10 00 00 00       	mov    $0x10,%eax
		return va_arg(*ap, unsigned int);
f01012c0:	eb 8c                	jmp    f010124e <.L25+0x2b>

f01012c2 <.L35>:
			putch(ch, putdat);
f01012c2:	8b 75 08             	mov    0x8(%ebp),%esi
f01012c5:	83 ec 08             	sub    $0x8,%esp
f01012c8:	57                   	push   %edi
f01012c9:	6a 25                	push   $0x25
f01012cb:	ff d6                	call   *%esi
			break;
f01012cd:	83 c4 10             	add    $0x10,%esp
f01012d0:	eb 96                	jmp    f0101268 <.L25+0x45>

f01012d2 <.L20>:
			putch('%', putdat);
f01012d2:	8b 75 08             	mov    0x8(%ebp),%esi
f01012d5:	83 ec 08             	sub    $0x8,%esp
f01012d8:	57                   	push   %edi
f01012d9:	6a 25                	push   $0x25
f01012db:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012dd:	83 c4 10             	add    $0x10,%esp
f01012e0:	89 d8                	mov    %ebx,%eax
f01012e2:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01012e6:	74 05                	je     f01012ed <.L20+0x1b>
f01012e8:	83 e8 01             	sub    $0x1,%eax
f01012eb:	eb f5                	jmp    f01012e2 <.L20+0x10>
f01012ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012f0:	e9 73 ff ff ff       	jmp    f0101268 <.L25+0x45>

f01012f5 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012f5:	55                   	push   %ebp
f01012f6:	89 e5                	mov    %esp,%ebp
f01012f8:	53                   	push   %ebx
f01012f9:	83 ec 14             	sub    $0x14,%esp
f01012fc:	e8 bb ee ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0101301:	81 c3 07 f0 00 00    	add    $0xf007,%ebx
f0101307:	8b 45 08             	mov    0x8(%ebp),%eax
f010130a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010130d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101310:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101314:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101317:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010131e:	85 c0                	test   %eax,%eax
f0101320:	74 2b                	je     f010134d <vsnprintf+0x58>
f0101322:	85 d2                	test   %edx,%edx
f0101324:	7e 27                	jle    f010134d <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101326:	ff 75 14             	pushl  0x14(%ebp)
f0101329:	ff 75 10             	pushl  0x10(%ebp)
f010132c:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010132f:	50                   	push   %eax
f0101330:	8d 83 11 0b ff ff    	lea    -0xf4ef(%ebx),%eax
f0101336:	50                   	push   %eax
f0101337:	e8 17 fb ff ff       	call   f0100e53 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010133c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010133f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101342:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101345:	83 c4 10             	add    $0x10,%esp
}
f0101348:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010134b:	c9                   	leave  
f010134c:	c3                   	ret    
		return -E_INVAL;
f010134d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101352:	eb f4                	jmp    f0101348 <vsnprintf+0x53>

f0101354 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101354:	55                   	push   %ebp
f0101355:	89 e5                	mov    %esp,%ebp
f0101357:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010135a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010135d:	50                   	push   %eax
f010135e:	ff 75 10             	pushl  0x10(%ebp)
f0101361:	ff 75 0c             	pushl  0xc(%ebp)
f0101364:	ff 75 08             	pushl  0x8(%ebp)
f0101367:	e8 89 ff ff ff       	call   f01012f5 <vsnprintf>
	va_end(ap);

	return rc;
}
f010136c:	c9                   	leave  
f010136d:	c3                   	ret    

f010136e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010136e:	55                   	push   %ebp
f010136f:	89 e5                	mov    %esp,%ebp
f0101371:	57                   	push   %edi
f0101372:	56                   	push   %esi
f0101373:	53                   	push   %ebx
f0101374:	83 ec 1c             	sub    $0x1c,%esp
f0101377:	e8 40 ee ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010137c:	81 c3 8c ef 00 00    	add    $0xef8c,%ebx
f0101382:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101385:	85 c0                	test   %eax,%eax
f0101387:	74 13                	je     f010139c <readline+0x2e>
		cprintf("%s", prompt);
f0101389:	83 ec 08             	sub    $0x8,%esp
f010138c:	50                   	push   %eax
f010138d:	8d 83 3f 1c ff ff    	lea    -0xe3c1(%ebx),%eax
f0101393:	50                   	push   %eax
f0101394:	e8 ab f6 ff ff       	call   f0100a44 <cprintf>
f0101399:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010139c:	83 ec 0c             	sub    $0xc,%esp
f010139f:	6a 00                	push   $0x0
f01013a1:	e8 ad f3 ff ff       	call   f0100753 <iscons>
f01013a6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013a9:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01013ac:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f01013b1:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f01013b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01013ba:	eb 45                	jmp    f0101401 <readline+0x93>
			cprintf("read error: %e\n", c);
f01013bc:	83 ec 08             	sub    $0x8,%esp
f01013bf:	50                   	push   %eax
f01013c0:	8d 83 04 1e ff ff    	lea    -0xe1fc(%ebx),%eax
f01013c6:	50                   	push   %eax
f01013c7:	e8 78 f6 ff ff       	call   f0100a44 <cprintf>
			return NULL;
f01013cc:	83 c4 10             	add    $0x10,%esp
f01013cf:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01013d4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013d7:	5b                   	pop    %ebx
f01013d8:	5e                   	pop    %esi
f01013d9:	5f                   	pop    %edi
f01013da:	5d                   	pop    %ebp
f01013db:	c3                   	ret    
			if (echoing)
f01013dc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013e0:	75 05                	jne    f01013e7 <readline+0x79>
			i--;
f01013e2:	83 ef 01             	sub    $0x1,%edi
f01013e5:	eb 1a                	jmp    f0101401 <readline+0x93>
				cputchar('\b');
f01013e7:	83 ec 0c             	sub    $0xc,%esp
f01013ea:	6a 08                	push   $0x8
f01013ec:	e8 41 f3 ff ff       	call   f0100732 <cputchar>
f01013f1:	83 c4 10             	add    $0x10,%esp
f01013f4:	eb ec                	jmp    f01013e2 <readline+0x74>
			buf[i++] = c;
f01013f6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01013f9:	89 f0                	mov    %esi,%eax
f01013fb:	88 04 39             	mov    %al,(%ecx,%edi,1)
f01013fe:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101401:	e8 3c f3 ff ff       	call   f0100742 <getchar>
f0101406:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0101408:	85 c0                	test   %eax,%eax
f010140a:	78 b0                	js     f01013bc <readline+0x4e>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010140c:	83 f8 08             	cmp    $0x8,%eax
f010140f:	0f 94 c2             	sete   %dl
f0101412:	83 f8 7f             	cmp    $0x7f,%eax
f0101415:	0f 94 c0             	sete   %al
f0101418:	08 c2                	or     %al,%dl
f010141a:	74 04                	je     f0101420 <readline+0xb2>
f010141c:	85 ff                	test   %edi,%edi
f010141e:	7f bc                	jg     f01013dc <readline+0x6e>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101420:	83 fe 1f             	cmp    $0x1f,%esi
f0101423:	7e 1c                	jle    f0101441 <readline+0xd3>
f0101425:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010142b:	7f 14                	jg     f0101441 <readline+0xd3>
			if (echoing)
f010142d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101431:	74 c3                	je     f01013f6 <readline+0x88>
				cputchar(c);
f0101433:	83 ec 0c             	sub    $0xc,%esp
f0101436:	56                   	push   %esi
f0101437:	e8 f6 f2 ff ff       	call   f0100732 <cputchar>
f010143c:	83 c4 10             	add    $0x10,%esp
f010143f:	eb b5                	jmp    f01013f6 <readline+0x88>
		} else if (c == '\n' || c == '\r') {
f0101441:	83 fe 0a             	cmp    $0xa,%esi
f0101444:	74 05                	je     f010144b <readline+0xdd>
f0101446:	83 fe 0d             	cmp    $0xd,%esi
f0101449:	75 b6                	jne    f0101401 <readline+0x93>
			if (echoing)
f010144b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010144f:	75 13                	jne    f0101464 <readline+0xf6>
			buf[i] = 0;
f0101451:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f0101458:	00 
			return buf;
f0101459:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f010145f:	e9 70 ff ff ff       	jmp    f01013d4 <readline+0x66>
				cputchar('\n');
f0101464:	83 ec 0c             	sub    $0xc,%esp
f0101467:	6a 0a                	push   $0xa
f0101469:	e8 c4 f2 ff ff       	call   f0100732 <cputchar>
f010146e:	83 c4 10             	add    $0x10,%esp
f0101471:	eb de                	jmp    f0101451 <readline+0xe3>

f0101473 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101473:	55                   	push   %ebp
f0101474:	89 e5                	mov    %esp,%ebp
f0101476:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101479:	b8 00 00 00 00       	mov    $0x0,%eax
f010147e:	eb 03                	jmp    f0101483 <strlen+0x10>
		n++;
f0101480:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101483:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101487:	75 f7                	jne    f0101480 <strlen+0xd>
	return n;
}
f0101489:	5d                   	pop    %ebp
f010148a:	c3                   	ret    

f010148b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010148b:	55                   	push   %ebp
f010148c:	89 e5                	mov    %esp,%ebp
f010148e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101491:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101494:	b8 00 00 00 00       	mov    $0x0,%eax
f0101499:	eb 03                	jmp    f010149e <strnlen+0x13>
		n++;
f010149b:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010149e:	39 d0                	cmp    %edx,%eax
f01014a0:	74 08                	je     f01014aa <strnlen+0x1f>
f01014a2:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01014a6:	75 f3                	jne    f010149b <strnlen+0x10>
f01014a8:	89 c2                	mov    %eax,%edx
	return n;
}
f01014aa:	89 d0                	mov    %edx,%eax
f01014ac:	5d                   	pop    %ebp
f01014ad:	c3                   	ret    

f01014ae <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014ae:	55                   	push   %ebp
f01014af:	89 e5                	mov    %esp,%ebp
f01014b1:	53                   	push   %ebx
f01014b2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014b5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01014bd:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f01014c1:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f01014c4:	83 c0 01             	add    $0x1,%eax
f01014c7:	84 d2                	test   %dl,%dl
f01014c9:	75 f2                	jne    f01014bd <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01014cb:	89 c8                	mov    %ecx,%eax
f01014cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014d0:	c9                   	leave  
f01014d1:	c3                   	ret    

f01014d2 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014d2:	55                   	push   %ebp
f01014d3:	89 e5                	mov    %esp,%ebp
f01014d5:	53                   	push   %ebx
f01014d6:	83 ec 10             	sub    $0x10,%esp
f01014d9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014dc:	53                   	push   %ebx
f01014dd:	e8 91 ff ff ff       	call   f0101473 <strlen>
f01014e2:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f01014e5:	ff 75 0c             	pushl  0xc(%ebp)
f01014e8:	01 d8                	add    %ebx,%eax
f01014ea:	50                   	push   %eax
f01014eb:	e8 be ff ff ff       	call   f01014ae <strcpy>
	return dst;
}
f01014f0:	89 d8                	mov    %ebx,%eax
f01014f2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014f5:	c9                   	leave  
f01014f6:	c3                   	ret    

f01014f7 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014f7:	55                   	push   %ebp
f01014f8:	89 e5                	mov    %esp,%ebp
f01014fa:	56                   	push   %esi
f01014fb:	53                   	push   %ebx
f01014fc:	8b 75 08             	mov    0x8(%ebp),%esi
f01014ff:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101502:	89 f3                	mov    %esi,%ebx
f0101504:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101507:	89 f0                	mov    %esi,%eax
f0101509:	eb 0f                	jmp    f010151a <strncpy+0x23>
		*dst++ = *src;
f010150b:	83 c0 01             	add    $0x1,%eax
f010150e:	0f b6 0a             	movzbl (%edx),%ecx
f0101511:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101514:	80 f9 01             	cmp    $0x1,%cl
f0101517:	83 da ff             	sbb    $0xffffffff,%edx
	for (i = 0; i < size; i++) {
f010151a:	39 d8                	cmp    %ebx,%eax
f010151c:	75 ed                	jne    f010150b <strncpy+0x14>
	}
	return ret;
}
f010151e:	89 f0                	mov    %esi,%eax
f0101520:	5b                   	pop    %ebx
f0101521:	5e                   	pop    %esi
f0101522:	5d                   	pop    %ebp
f0101523:	c3                   	ret    

f0101524 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101524:	55                   	push   %ebp
f0101525:	89 e5                	mov    %esp,%ebp
f0101527:	56                   	push   %esi
f0101528:	53                   	push   %ebx
f0101529:	8b 75 08             	mov    0x8(%ebp),%esi
f010152c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010152f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101532:	89 f3                	mov    %esi,%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101534:	85 c0                	test   %eax,%eax
f0101536:	74 21                	je     f0101559 <strlcpy+0x35>
f0101538:	8d 5c 06 ff          	lea    -0x1(%esi,%eax,1),%ebx
f010153c:	89 f0                	mov    %esi,%eax
f010153e:	eb 09                	jmp    f0101549 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101540:	83 c2 01             	add    $0x1,%edx
f0101543:	83 c0 01             	add    $0x1,%eax
f0101546:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101549:	39 d8                	cmp    %ebx,%eax
f010154b:	74 09                	je     f0101556 <strlcpy+0x32>
f010154d:	0f b6 0a             	movzbl (%edx),%ecx
f0101550:	84 c9                	test   %cl,%cl
f0101552:	75 ec                	jne    f0101540 <strlcpy+0x1c>
f0101554:	89 c3                	mov    %eax,%ebx
		*dst = '\0';
f0101556:	c6 03 00             	movb   $0x0,(%ebx)
	}
	return dst - dst_in;
f0101559:	89 d8                	mov    %ebx,%eax
f010155b:	29 f0                	sub    %esi,%eax
}
f010155d:	5b                   	pop    %ebx
f010155e:	5e                   	pop    %esi
f010155f:	5d                   	pop    %ebp
f0101560:	c3                   	ret    

f0101561 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101561:	55                   	push   %ebp
f0101562:	89 e5                	mov    %esp,%ebp
f0101564:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101567:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010156a:	eb 06                	jmp    f0101572 <strcmp+0x11>
		p++, q++;
f010156c:	83 c1 01             	add    $0x1,%ecx
f010156f:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101572:	0f b6 01             	movzbl (%ecx),%eax
f0101575:	84 c0                	test   %al,%al
f0101577:	74 04                	je     f010157d <strcmp+0x1c>
f0101579:	3a 02                	cmp    (%edx),%al
f010157b:	74 ef                	je     f010156c <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010157d:	0f b6 c0             	movzbl %al,%eax
f0101580:	0f b6 12             	movzbl (%edx),%edx
f0101583:	29 d0                	sub    %edx,%eax
}
f0101585:	5d                   	pop    %ebp
f0101586:	c3                   	ret    

f0101587 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101587:	55                   	push   %ebp
f0101588:	89 e5                	mov    %esp,%ebp
f010158a:	53                   	push   %ebx
f010158b:	8b 45 08             	mov    0x8(%ebp),%eax
f010158e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101591:	89 c3                	mov    %eax,%ebx
f0101593:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101596:	eb 06                	jmp    f010159e <strncmp+0x17>
		n--, p++, q++;
f0101598:	83 c0 01             	add    $0x1,%eax
f010159b:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f010159e:	39 d8                	cmp    %ebx,%eax
f01015a0:	74 18                	je     f01015ba <strncmp+0x33>
f01015a2:	0f b6 08             	movzbl (%eax),%ecx
f01015a5:	84 c9                	test   %cl,%cl
f01015a7:	74 04                	je     f01015ad <strncmp+0x26>
f01015a9:	3a 0a                	cmp    (%edx),%cl
f01015ab:	74 eb                	je     f0101598 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015ad:	0f b6 00             	movzbl (%eax),%eax
f01015b0:	0f b6 12             	movzbl (%edx),%edx
f01015b3:	29 d0                	sub    %edx,%eax
}
f01015b5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01015b8:	c9                   	leave  
f01015b9:	c3                   	ret    
		return 0;
f01015ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01015bf:	eb f4                	jmp    f01015b5 <strncmp+0x2e>

f01015c1 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015c1:	55                   	push   %ebp
f01015c2:	89 e5                	mov    %esp,%ebp
f01015c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c7:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015cb:	eb 03                	jmp    f01015d0 <strchr+0xf>
f01015cd:	83 c0 01             	add    $0x1,%eax
f01015d0:	0f b6 10             	movzbl (%eax),%edx
f01015d3:	84 d2                	test   %dl,%dl
f01015d5:	74 06                	je     f01015dd <strchr+0x1c>
		if (*s == c)
f01015d7:	38 ca                	cmp    %cl,%dl
f01015d9:	75 f2                	jne    f01015cd <strchr+0xc>
f01015db:	eb 05                	jmp    f01015e2 <strchr+0x21>
			return (char *) s;
	return 0;
f01015dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015e2:	5d                   	pop    %ebp
f01015e3:	c3                   	ret    

f01015e4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015e4:	55                   	push   %ebp
f01015e5:	89 e5                	mov    %esp,%ebp
f01015e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ea:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015ee:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01015f1:	38 ca                	cmp    %cl,%dl
f01015f3:	74 09                	je     f01015fe <strfind+0x1a>
f01015f5:	84 d2                	test   %dl,%dl
f01015f7:	74 05                	je     f01015fe <strfind+0x1a>
	for (; *s; s++)
f01015f9:	83 c0 01             	add    $0x1,%eax
f01015fc:	eb f0                	jmp    f01015ee <strfind+0xa>
			break;
	return (char *) s;
}
f01015fe:	5d                   	pop    %ebp
f01015ff:	c3                   	ret    

f0101600 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101600:	55                   	push   %ebp
f0101601:	89 e5                	mov    %esp,%ebp
f0101603:	57                   	push   %edi
f0101604:	56                   	push   %esi
f0101605:	53                   	push   %ebx
f0101606:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101609:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010160c:	85 c9                	test   %ecx,%ecx
f010160e:	74 31                	je     f0101641 <memset+0x41>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101610:	89 f8                	mov    %edi,%eax
f0101612:	09 c8                	or     %ecx,%eax
f0101614:	a8 03                	test   $0x3,%al
f0101616:	75 23                	jne    f010163b <memset+0x3b>
		c &= 0xFF;
f0101618:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010161c:	89 d3                	mov    %edx,%ebx
f010161e:	c1 e3 08             	shl    $0x8,%ebx
f0101621:	89 d0                	mov    %edx,%eax
f0101623:	c1 e0 18             	shl    $0x18,%eax
f0101626:	89 d6                	mov    %edx,%esi
f0101628:	c1 e6 10             	shl    $0x10,%esi
f010162b:	09 f0                	or     %esi,%eax
f010162d:	09 c2                	or     %eax,%edx
f010162f:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101631:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101634:	89 d0                	mov    %edx,%eax
f0101636:	fc                   	cld    
f0101637:	f3 ab                	rep stos %eax,%es:(%edi)
f0101639:	eb 06                	jmp    f0101641 <memset+0x41>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010163b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010163e:	fc                   	cld    
f010163f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101641:	89 f8                	mov    %edi,%eax
f0101643:	5b                   	pop    %ebx
f0101644:	5e                   	pop    %esi
f0101645:	5f                   	pop    %edi
f0101646:	5d                   	pop    %ebp
f0101647:	c3                   	ret    

f0101648 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101648:	55                   	push   %ebp
f0101649:	89 e5                	mov    %esp,%ebp
f010164b:	57                   	push   %edi
f010164c:	56                   	push   %esi
f010164d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101650:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101653:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101656:	39 c6                	cmp    %eax,%esi
f0101658:	73 32                	jae    f010168c <memmove+0x44>
f010165a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010165d:	39 c2                	cmp    %eax,%edx
f010165f:	76 2b                	jbe    f010168c <memmove+0x44>
		s += n;
		d += n;
f0101661:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101664:	89 fe                	mov    %edi,%esi
f0101666:	09 ce                	or     %ecx,%esi
f0101668:	09 d6                	or     %edx,%esi
f010166a:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101670:	75 0e                	jne    f0101680 <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101672:	83 ef 04             	sub    $0x4,%edi
f0101675:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101678:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010167b:	fd                   	std    
f010167c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010167e:	eb 09                	jmp    f0101689 <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101680:	83 ef 01             	sub    $0x1,%edi
f0101683:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101686:	fd                   	std    
f0101687:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101689:	fc                   	cld    
f010168a:	eb 1a                	jmp    f01016a6 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010168c:	89 c2                	mov    %eax,%edx
f010168e:	09 ca                	or     %ecx,%edx
f0101690:	09 f2                	or     %esi,%edx
f0101692:	f6 c2 03             	test   $0x3,%dl
f0101695:	75 0a                	jne    f01016a1 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101697:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010169a:	89 c7                	mov    %eax,%edi
f010169c:	fc                   	cld    
f010169d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010169f:	eb 05                	jmp    f01016a6 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f01016a1:	89 c7                	mov    %eax,%edi
f01016a3:	fc                   	cld    
f01016a4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016a6:	5e                   	pop    %esi
f01016a7:	5f                   	pop    %edi
f01016a8:	5d                   	pop    %ebp
f01016a9:	c3                   	ret    

f01016aa <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01016aa:	55                   	push   %ebp
f01016ab:	89 e5                	mov    %esp,%ebp
f01016ad:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01016b0:	ff 75 10             	pushl  0x10(%ebp)
f01016b3:	ff 75 0c             	pushl  0xc(%ebp)
f01016b6:	ff 75 08             	pushl  0x8(%ebp)
f01016b9:	e8 8a ff ff ff       	call   f0101648 <memmove>
}
f01016be:	c9                   	leave  
f01016bf:	c3                   	ret    

f01016c0 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016c0:	55                   	push   %ebp
f01016c1:	89 e5                	mov    %esp,%ebp
f01016c3:	56                   	push   %esi
f01016c4:	53                   	push   %ebx
f01016c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01016c8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016cb:	89 c6                	mov    %eax,%esi
f01016cd:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016d0:	eb 06                	jmp    f01016d8 <memcmp+0x18>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01016d2:	83 c0 01             	add    $0x1,%eax
f01016d5:	83 c2 01             	add    $0x1,%edx
	while (n-- > 0) {
f01016d8:	39 f0                	cmp    %esi,%eax
f01016da:	74 14                	je     f01016f0 <memcmp+0x30>
		if (*s1 != *s2)
f01016dc:	0f b6 08             	movzbl (%eax),%ecx
f01016df:	0f b6 1a             	movzbl (%edx),%ebx
f01016e2:	38 d9                	cmp    %bl,%cl
f01016e4:	74 ec                	je     f01016d2 <memcmp+0x12>
			return (int) *s1 - (int) *s2;
f01016e6:	0f b6 c1             	movzbl %cl,%eax
f01016e9:	0f b6 db             	movzbl %bl,%ebx
f01016ec:	29 d8                	sub    %ebx,%eax
f01016ee:	eb 05                	jmp    f01016f5 <memcmp+0x35>
	}

	return 0;
f01016f0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016f5:	5b                   	pop    %ebx
f01016f6:	5e                   	pop    %esi
f01016f7:	5d                   	pop    %ebp
f01016f8:	c3                   	ret    

f01016f9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016f9:	55                   	push   %ebp
f01016fa:	89 e5                	mov    %esp,%ebp
f01016fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101702:	89 c2                	mov    %eax,%edx
f0101704:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101707:	eb 03                	jmp    f010170c <memfind+0x13>
f0101709:	83 c0 01             	add    $0x1,%eax
f010170c:	39 d0                	cmp    %edx,%eax
f010170e:	73 04                	jae    f0101714 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101710:	38 08                	cmp    %cl,(%eax)
f0101712:	75 f5                	jne    f0101709 <memfind+0x10>
			break;
	return (void *) s;
}
f0101714:	5d                   	pop    %ebp
f0101715:	c3                   	ret    

f0101716 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101716:	55                   	push   %ebp
f0101717:	89 e5                	mov    %esp,%ebp
f0101719:	57                   	push   %edi
f010171a:	56                   	push   %esi
f010171b:	53                   	push   %ebx
f010171c:	8b 55 08             	mov    0x8(%ebp),%edx
f010171f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101722:	eb 03                	jmp    f0101727 <strtol+0x11>
		s++;
f0101724:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0101727:	0f b6 02             	movzbl (%edx),%eax
f010172a:	3c 20                	cmp    $0x20,%al
f010172c:	74 f6                	je     f0101724 <strtol+0xe>
f010172e:	3c 09                	cmp    $0x9,%al
f0101730:	74 f2                	je     f0101724 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101732:	3c 2b                	cmp    $0x2b,%al
f0101734:	74 2a                	je     f0101760 <strtol+0x4a>
	int neg = 0;
f0101736:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010173b:	3c 2d                	cmp    $0x2d,%al
f010173d:	74 2b                	je     f010176a <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010173f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101745:	75 0f                	jne    f0101756 <strtol+0x40>
f0101747:	80 3a 30             	cmpb   $0x30,(%edx)
f010174a:	74 28                	je     f0101774 <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010174c:	85 db                	test   %ebx,%ebx
f010174e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101753:	0f 44 d8             	cmove  %eax,%ebx
f0101756:	b9 00 00 00 00       	mov    $0x0,%ecx
f010175b:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010175e:	eb 46                	jmp    f01017a6 <strtol+0x90>
		s++;
f0101760:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0101763:	bf 00 00 00 00       	mov    $0x0,%edi
f0101768:	eb d5                	jmp    f010173f <strtol+0x29>
		s++, neg = 1;
f010176a:	83 c2 01             	add    $0x1,%edx
f010176d:	bf 01 00 00 00       	mov    $0x1,%edi
f0101772:	eb cb                	jmp    f010173f <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101774:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101778:	74 0e                	je     f0101788 <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f010177a:	85 db                	test   %ebx,%ebx
f010177c:	75 d8                	jne    f0101756 <strtol+0x40>
		s++, base = 8;
f010177e:	83 c2 01             	add    $0x1,%edx
f0101781:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101786:	eb ce                	jmp    f0101756 <strtol+0x40>
		s += 2, base = 16;
f0101788:	83 c2 02             	add    $0x2,%edx
f010178b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101790:	eb c4                	jmp    f0101756 <strtol+0x40>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0101792:	0f be c0             	movsbl %al,%eax
f0101795:	83 e8 30             	sub    $0x30,%eax
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101798:	3b 45 10             	cmp    0x10(%ebp),%eax
f010179b:	7d 3a                	jge    f01017d7 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f010179d:	83 c2 01             	add    $0x1,%edx
f01017a0:	0f af 4d 10          	imul   0x10(%ebp),%ecx
f01017a4:	01 c1                	add    %eax,%ecx
		if (*s >= '0' && *s <= '9')
f01017a6:	0f b6 02             	movzbl (%edx),%eax
f01017a9:	8d 70 d0             	lea    -0x30(%eax),%esi
f01017ac:	89 f3                	mov    %esi,%ebx
f01017ae:	80 fb 09             	cmp    $0x9,%bl
f01017b1:	76 df                	jbe    f0101792 <strtol+0x7c>
		else if (*s >= 'a' && *s <= 'z')
f01017b3:	8d 70 9f             	lea    -0x61(%eax),%esi
f01017b6:	89 f3                	mov    %esi,%ebx
f01017b8:	80 fb 19             	cmp    $0x19,%bl
f01017bb:	77 08                	ja     f01017c5 <strtol+0xaf>
			dig = *s - 'a' + 10;
f01017bd:	0f be c0             	movsbl %al,%eax
f01017c0:	83 e8 57             	sub    $0x57,%eax
f01017c3:	eb d3                	jmp    f0101798 <strtol+0x82>
		else if (*s >= 'A' && *s <= 'Z')
f01017c5:	8d 70 bf             	lea    -0x41(%eax),%esi
f01017c8:	89 f3                	mov    %esi,%ebx
f01017ca:	80 fb 19             	cmp    $0x19,%bl
f01017cd:	77 08                	ja     f01017d7 <strtol+0xc1>
			dig = *s - 'A' + 10;
f01017cf:	0f be c0             	movsbl %al,%eax
f01017d2:	83 e8 37             	sub    $0x37,%eax
f01017d5:	eb c1                	jmp    f0101798 <strtol+0x82>
		// we don't properly detect overflow!
	}

	if (endptr)
f01017d7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017db:	74 05                	je     f01017e2 <strtol+0xcc>
		*endptr = (char *) s;
f01017dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017e0:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f01017e2:	89 c8                	mov    %ecx,%eax
f01017e4:	f7 d8                	neg    %eax
f01017e6:	85 ff                	test   %edi,%edi
f01017e8:	0f 45 c8             	cmovne %eax,%ecx
}
f01017eb:	89 c8                	mov    %ecx,%eax
f01017ed:	5b                   	pop    %ebx
f01017ee:	5e                   	pop    %esi
f01017ef:	5f                   	pop    %edi
f01017f0:	5d                   	pop    %ebp
f01017f1:	c3                   	ret    
f01017f2:	66 90                	xchg   %ax,%ax
f01017f4:	66 90                	xchg   %ax,%ax
f01017f6:	66 90                	xchg   %ax,%ax
f01017f8:	66 90                	xchg   %ax,%ax
f01017fa:	66 90                	xchg   %ax,%ax
f01017fc:	66 90                	xchg   %ax,%ax
f01017fe:	66 90                	xchg   %ax,%ax

f0101800 <__udivdi3>:
f0101800:	f3 0f 1e fb          	endbr32 
f0101804:	55                   	push   %ebp
f0101805:	57                   	push   %edi
f0101806:	56                   	push   %esi
f0101807:	53                   	push   %ebx
f0101808:	83 ec 1c             	sub    $0x1c,%esp
f010180b:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010180f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0101813:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101817:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010181b:	85 d2                	test   %edx,%edx
f010181d:	75 19                	jne    f0101838 <__udivdi3+0x38>
f010181f:	39 f3                	cmp    %esi,%ebx
f0101821:	76 4d                	jbe    f0101870 <__udivdi3+0x70>
f0101823:	31 ff                	xor    %edi,%edi
f0101825:	89 e8                	mov    %ebp,%eax
f0101827:	89 f2                	mov    %esi,%edx
f0101829:	f7 f3                	div    %ebx
f010182b:	89 fa                	mov    %edi,%edx
f010182d:	83 c4 1c             	add    $0x1c,%esp
f0101830:	5b                   	pop    %ebx
f0101831:	5e                   	pop    %esi
f0101832:	5f                   	pop    %edi
f0101833:	5d                   	pop    %ebp
f0101834:	c3                   	ret    
f0101835:	8d 76 00             	lea    0x0(%esi),%esi
f0101838:	39 f2                	cmp    %esi,%edx
f010183a:	76 14                	jbe    f0101850 <__udivdi3+0x50>
f010183c:	31 ff                	xor    %edi,%edi
f010183e:	31 c0                	xor    %eax,%eax
f0101840:	89 fa                	mov    %edi,%edx
f0101842:	83 c4 1c             	add    $0x1c,%esp
f0101845:	5b                   	pop    %ebx
f0101846:	5e                   	pop    %esi
f0101847:	5f                   	pop    %edi
f0101848:	5d                   	pop    %ebp
f0101849:	c3                   	ret    
f010184a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101850:	0f bd fa             	bsr    %edx,%edi
f0101853:	83 f7 1f             	xor    $0x1f,%edi
f0101856:	75 48                	jne    f01018a0 <__udivdi3+0xa0>
f0101858:	39 f2                	cmp    %esi,%edx
f010185a:	72 06                	jb     f0101862 <__udivdi3+0x62>
f010185c:	31 c0                	xor    %eax,%eax
f010185e:	39 eb                	cmp    %ebp,%ebx
f0101860:	77 de                	ja     f0101840 <__udivdi3+0x40>
f0101862:	b8 01 00 00 00       	mov    $0x1,%eax
f0101867:	eb d7                	jmp    f0101840 <__udivdi3+0x40>
f0101869:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101870:	89 d9                	mov    %ebx,%ecx
f0101872:	85 db                	test   %ebx,%ebx
f0101874:	75 0b                	jne    f0101881 <__udivdi3+0x81>
f0101876:	b8 01 00 00 00       	mov    $0x1,%eax
f010187b:	31 d2                	xor    %edx,%edx
f010187d:	f7 f3                	div    %ebx
f010187f:	89 c1                	mov    %eax,%ecx
f0101881:	31 d2                	xor    %edx,%edx
f0101883:	89 f0                	mov    %esi,%eax
f0101885:	f7 f1                	div    %ecx
f0101887:	89 c6                	mov    %eax,%esi
f0101889:	89 e8                	mov    %ebp,%eax
f010188b:	89 f7                	mov    %esi,%edi
f010188d:	f7 f1                	div    %ecx
f010188f:	89 fa                	mov    %edi,%edx
f0101891:	83 c4 1c             	add    $0x1c,%esp
f0101894:	5b                   	pop    %ebx
f0101895:	5e                   	pop    %esi
f0101896:	5f                   	pop    %edi
f0101897:	5d                   	pop    %ebp
f0101898:	c3                   	ret    
f0101899:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01018a0:	89 f9                	mov    %edi,%ecx
f01018a2:	b8 20 00 00 00       	mov    $0x20,%eax
f01018a7:	29 f8                	sub    %edi,%eax
f01018a9:	d3 e2                	shl    %cl,%edx
f01018ab:	89 54 24 08          	mov    %edx,0x8(%esp)
f01018af:	89 c1                	mov    %eax,%ecx
f01018b1:	89 da                	mov    %ebx,%edx
f01018b3:	d3 ea                	shr    %cl,%edx
f01018b5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01018b9:	09 d1                	or     %edx,%ecx
f01018bb:	89 f2                	mov    %esi,%edx
f01018bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018c1:	89 f9                	mov    %edi,%ecx
f01018c3:	d3 e3                	shl    %cl,%ebx
f01018c5:	89 c1                	mov    %eax,%ecx
f01018c7:	d3 ea                	shr    %cl,%edx
f01018c9:	89 f9                	mov    %edi,%ecx
f01018cb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01018cf:	89 eb                	mov    %ebp,%ebx
f01018d1:	d3 e6                	shl    %cl,%esi
f01018d3:	89 c1                	mov    %eax,%ecx
f01018d5:	d3 eb                	shr    %cl,%ebx
f01018d7:	09 de                	or     %ebx,%esi
f01018d9:	89 f0                	mov    %esi,%eax
f01018db:	f7 74 24 08          	divl   0x8(%esp)
f01018df:	89 d6                	mov    %edx,%esi
f01018e1:	89 c3                	mov    %eax,%ebx
f01018e3:	f7 64 24 0c          	mull   0xc(%esp)
f01018e7:	39 d6                	cmp    %edx,%esi
f01018e9:	72 15                	jb     f0101900 <__udivdi3+0x100>
f01018eb:	89 f9                	mov    %edi,%ecx
f01018ed:	d3 e5                	shl    %cl,%ebp
f01018ef:	39 c5                	cmp    %eax,%ebp
f01018f1:	73 04                	jae    f01018f7 <__udivdi3+0xf7>
f01018f3:	39 d6                	cmp    %edx,%esi
f01018f5:	74 09                	je     f0101900 <__udivdi3+0x100>
f01018f7:	89 d8                	mov    %ebx,%eax
f01018f9:	31 ff                	xor    %edi,%edi
f01018fb:	e9 40 ff ff ff       	jmp    f0101840 <__udivdi3+0x40>
f0101900:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101903:	31 ff                	xor    %edi,%edi
f0101905:	e9 36 ff ff ff       	jmp    f0101840 <__udivdi3+0x40>
f010190a:	66 90                	xchg   %ax,%ax
f010190c:	66 90                	xchg   %ax,%ax
f010190e:	66 90                	xchg   %ax,%ax

f0101910 <__umoddi3>:
f0101910:	f3 0f 1e fb          	endbr32 
f0101914:	55                   	push   %ebp
f0101915:	57                   	push   %edi
f0101916:	56                   	push   %esi
f0101917:	53                   	push   %ebx
f0101918:	83 ec 1c             	sub    $0x1c,%esp
f010191b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010191f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101923:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101927:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010192b:	85 c0                	test   %eax,%eax
f010192d:	75 19                	jne    f0101948 <__umoddi3+0x38>
f010192f:	39 df                	cmp    %ebx,%edi
f0101931:	76 5d                	jbe    f0101990 <__umoddi3+0x80>
f0101933:	89 f0                	mov    %esi,%eax
f0101935:	89 da                	mov    %ebx,%edx
f0101937:	f7 f7                	div    %edi
f0101939:	89 d0                	mov    %edx,%eax
f010193b:	31 d2                	xor    %edx,%edx
f010193d:	83 c4 1c             	add    $0x1c,%esp
f0101940:	5b                   	pop    %ebx
f0101941:	5e                   	pop    %esi
f0101942:	5f                   	pop    %edi
f0101943:	5d                   	pop    %ebp
f0101944:	c3                   	ret    
f0101945:	8d 76 00             	lea    0x0(%esi),%esi
f0101948:	89 f2                	mov    %esi,%edx
f010194a:	39 d8                	cmp    %ebx,%eax
f010194c:	76 12                	jbe    f0101960 <__umoddi3+0x50>
f010194e:	89 f0                	mov    %esi,%eax
f0101950:	89 da                	mov    %ebx,%edx
f0101952:	83 c4 1c             	add    $0x1c,%esp
f0101955:	5b                   	pop    %ebx
f0101956:	5e                   	pop    %esi
f0101957:	5f                   	pop    %edi
f0101958:	5d                   	pop    %ebp
f0101959:	c3                   	ret    
f010195a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101960:	0f bd e8             	bsr    %eax,%ebp
f0101963:	83 f5 1f             	xor    $0x1f,%ebp
f0101966:	75 50                	jne    f01019b8 <__umoddi3+0xa8>
f0101968:	39 d8                	cmp    %ebx,%eax
f010196a:	0f 82 e0 00 00 00    	jb     f0101a50 <__umoddi3+0x140>
f0101970:	89 d9                	mov    %ebx,%ecx
f0101972:	39 f7                	cmp    %esi,%edi
f0101974:	0f 86 d6 00 00 00    	jbe    f0101a50 <__umoddi3+0x140>
f010197a:	89 d0                	mov    %edx,%eax
f010197c:	89 ca                	mov    %ecx,%edx
f010197e:	83 c4 1c             	add    $0x1c,%esp
f0101981:	5b                   	pop    %ebx
f0101982:	5e                   	pop    %esi
f0101983:	5f                   	pop    %edi
f0101984:	5d                   	pop    %ebp
f0101985:	c3                   	ret    
f0101986:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010198d:	8d 76 00             	lea    0x0(%esi),%esi
f0101990:	89 fd                	mov    %edi,%ebp
f0101992:	85 ff                	test   %edi,%edi
f0101994:	75 0b                	jne    f01019a1 <__umoddi3+0x91>
f0101996:	b8 01 00 00 00       	mov    $0x1,%eax
f010199b:	31 d2                	xor    %edx,%edx
f010199d:	f7 f7                	div    %edi
f010199f:	89 c5                	mov    %eax,%ebp
f01019a1:	89 d8                	mov    %ebx,%eax
f01019a3:	31 d2                	xor    %edx,%edx
f01019a5:	f7 f5                	div    %ebp
f01019a7:	89 f0                	mov    %esi,%eax
f01019a9:	f7 f5                	div    %ebp
f01019ab:	89 d0                	mov    %edx,%eax
f01019ad:	31 d2                	xor    %edx,%edx
f01019af:	eb 8c                	jmp    f010193d <__umoddi3+0x2d>
f01019b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019b8:	89 e9                	mov    %ebp,%ecx
f01019ba:	ba 20 00 00 00       	mov    $0x20,%edx
f01019bf:	29 ea                	sub    %ebp,%edx
f01019c1:	d3 e0                	shl    %cl,%eax
f01019c3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019c7:	89 d1                	mov    %edx,%ecx
f01019c9:	89 f8                	mov    %edi,%eax
f01019cb:	d3 e8                	shr    %cl,%eax
f01019cd:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01019d1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01019d5:	8b 54 24 04          	mov    0x4(%esp),%edx
f01019d9:	09 c1                	or     %eax,%ecx
f01019db:	89 d8                	mov    %ebx,%eax
f01019dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01019e1:	89 e9                	mov    %ebp,%ecx
f01019e3:	d3 e7                	shl    %cl,%edi
f01019e5:	89 d1                	mov    %edx,%ecx
f01019e7:	d3 e8                	shr    %cl,%eax
f01019e9:	89 e9                	mov    %ebp,%ecx
f01019eb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019ef:	d3 e3                	shl    %cl,%ebx
f01019f1:	89 c7                	mov    %eax,%edi
f01019f3:	89 d1                	mov    %edx,%ecx
f01019f5:	89 f0                	mov    %esi,%eax
f01019f7:	d3 e8                	shr    %cl,%eax
f01019f9:	89 e9                	mov    %ebp,%ecx
f01019fb:	89 fa                	mov    %edi,%edx
f01019fd:	d3 e6                	shl    %cl,%esi
f01019ff:	09 d8                	or     %ebx,%eax
f0101a01:	f7 74 24 08          	divl   0x8(%esp)
f0101a05:	89 d1                	mov    %edx,%ecx
f0101a07:	89 f3                	mov    %esi,%ebx
f0101a09:	f7 64 24 0c          	mull   0xc(%esp)
f0101a0d:	89 c6                	mov    %eax,%esi
f0101a0f:	89 d7                	mov    %edx,%edi
f0101a11:	39 d1                	cmp    %edx,%ecx
f0101a13:	72 06                	jb     f0101a1b <__umoddi3+0x10b>
f0101a15:	75 10                	jne    f0101a27 <__umoddi3+0x117>
f0101a17:	39 c3                	cmp    %eax,%ebx
f0101a19:	73 0c                	jae    f0101a27 <__umoddi3+0x117>
f0101a1b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f0101a1f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0101a23:	89 d7                	mov    %edx,%edi
f0101a25:	89 c6                	mov    %eax,%esi
f0101a27:	89 ca                	mov    %ecx,%edx
f0101a29:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a2e:	29 f3                	sub    %esi,%ebx
f0101a30:	19 fa                	sbb    %edi,%edx
f0101a32:	89 d0                	mov    %edx,%eax
f0101a34:	d3 e0                	shl    %cl,%eax
f0101a36:	89 e9                	mov    %ebp,%ecx
f0101a38:	d3 eb                	shr    %cl,%ebx
f0101a3a:	d3 ea                	shr    %cl,%edx
f0101a3c:	09 d8                	or     %ebx,%eax
f0101a3e:	83 c4 1c             	add    $0x1c,%esp
f0101a41:	5b                   	pop    %ebx
f0101a42:	5e                   	pop    %esi
f0101a43:	5f                   	pop    %edi
f0101a44:	5d                   	pop    %ebp
f0101a45:	c3                   	ret    
f0101a46:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a4d:	8d 76 00             	lea    0x0(%esi),%esi
f0101a50:	89 d9                	mov    %ebx,%ecx
f0101a52:	89 f2                	mov    %esi,%edx
f0101a54:	29 fa                	sub    %edi,%edx
f0101a56:	19 c1                	sbb    %eax,%ecx
f0101a58:	e9 1d ff ff ff       	jmp    f010197a <__umoddi3+0x6a>
