
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:
into memory and executes it. Appendix B explains the details. Xv6’s boot loader loads
the xv6 kernel from disk and executes it starting at entry*/
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  /*Now entry needs to transfer to the kernel’s C code, and run it in high memory.
  First it makes the stack pointer, %esp, point to memory to be used as a stack*/
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 30 c6 10 80       	mov    $0x8010c630,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 4b 38 10 80       	mov    $0x8010384b,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	83 ec 08             	sub    $0x8,%esp
8010003d:	68 58 83 10 80       	push   $0x80108358
80100042:	68 40 c6 10 80       	push   $0x8010c640
80100047:	e8 01 4f 00 00       	call   80104f4d <initlock>
8010004c:	83 c4 10             	add    $0x10,%esp

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004f:	c7 05 8c 0d 11 80 3c 	movl   $0x80110d3c,0x80110d8c
80100056:	0d 11 80 
  bcache.head.next = &bcache.head;
80100059:	c7 05 90 0d 11 80 3c 	movl   $0x80110d3c,0x80110d90
80100060:	0d 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100063:	c7 45 f4 74 c6 10 80 	movl   $0x8010c674,-0xc(%ebp)
8010006a:	eb 47                	jmp    801000b3 <binit+0x7f>
    b->next = bcache.head.next;
8010006c:	8b 15 90 0d 11 80    	mov    0x80110d90,%edx
80100072:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100075:	89 50 54             	mov    %edx,0x54(%eax)
    b->prev = &bcache.head;
80100078:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007b:	c7 40 50 3c 0d 11 80 	movl   $0x80110d3c,0x50(%eax)
    initsleeplock(&b->lock, "buffer");
80100082:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100085:	83 c0 0c             	add    $0xc,%eax
80100088:	83 ec 08             	sub    $0x8,%esp
8010008b:	68 5f 83 10 80       	push   $0x8010835f
80100090:	50                   	push   %eax
80100091:	e8 34 4d 00 00       	call   80104dca <initsleeplock>
80100096:	83 c4 10             	add    $0x10,%esp
    bcache.head.next->prev = b;
80100099:	a1 90 0d 11 80       	mov    0x80110d90,%eax
8010009e:	8b 55 f4             	mov    -0xc(%ebp),%edx
801000a1:	89 50 50             	mov    %edx,0x50(%eax)
    bcache.head.next = b;
801000a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000a7:	a3 90 0d 11 80       	mov    %eax,0x80110d90
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
801000ac:	81 45 f4 5c 02 00 00 	addl   $0x25c,-0xc(%ebp)
801000b3:	b8 3c 0d 11 80       	mov    $0x80110d3c,%eax
801000b8:	39 45 f4             	cmp    %eax,-0xc(%ebp)
801000bb:	72 af                	jb     8010006c <binit+0x38>
  }
}
801000bd:	90                   	nop
801000be:	c9                   	leave  
801000bf:	c3                   	ret    

801000c0 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
801000c0:	55                   	push   %ebp
801000c1:	89 e5                	mov    %esp,%ebp
801000c3:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000c6:	83 ec 0c             	sub    $0xc,%esp
801000c9:	68 40 c6 10 80       	push   $0x8010c640
801000ce:	e8 9c 4e 00 00       	call   80104f6f <acquire>
801000d3:	83 c4 10             	add    $0x10,%esp

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000d6:	a1 90 0d 11 80       	mov    0x80110d90,%eax
801000db:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000de:	eb 58                	jmp    80100138 <bget+0x78>
    if(b->dev == dev && b->blockno == blockno){
801000e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e3:	8b 40 04             	mov    0x4(%eax),%eax
801000e6:	39 45 08             	cmp    %eax,0x8(%ebp)
801000e9:	75 44                	jne    8010012f <bget+0x6f>
801000eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000ee:	8b 40 08             	mov    0x8(%eax),%eax
801000f1:	39 45 0c             	cmp    %eax,0xc(%ebp)
801000f4:	75 39                	jne    8010012f <bget+0x6f>
      b->refcnt++;
801000f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f9:	8b 40 4c             	mov    0x4c(%eax),%eax
801000fc:	8d 50 01             	lea    0x1(%eax),%edx
801000ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100102:	89 50 4c             	mov    %edx,0x4c(%eax)
      release(&bcache.lock);
80100105:	83 ec 0c             	sub    $0xc,%esp
80100108:	68 40 c6 10 80       	push   $0x8010c640
8010010d:	e8 cb 4e 00 00       	call   80104fdd <release>
80100112:	83 c4 10             	add    $0x10,%esp
      acquiresleep(&b->lock);
80100115:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100118:	83 c0 0c             	add    $0xc,%eax
8010011b:	83 ec 0c             	sub    $0xc,%esp
8010011e:	50                   	push   %eax
8010011f:	e8 e2 4c 00 00       	call   80104e06 <acquiresleep>
80100124:	83 c4 10             	add    $0x10,%esp
      return b;
80100127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010012a:	e9 9d 00 00 00       	jmp    801001cc <bget+0x10c>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010012f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100132:	8b 40 54             	mov    0x54(%eax),%eax
80100135:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100138:	81 7d f4 3c 0d 11 80 	cmpl   $0x80110d3c,-0xc(%ebp)
8010013f:	75 9f                	jne    801000e0 <bget+0x20>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100141:	a1 8c 0d 11 80       	mov    0x80110d8c,%eax
80100146:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100149:	eb 6b                	jmp    801001b6 <bget+0xf6>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
8010014b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010014e:	8b 40 4c             	mov    0x4c(%eax),%eax
80100151:	85 c0                	test   %eax,%eax
80100153:	75 58                	jne    801001ad <bget+0xed>
80100155:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100158:	8b 00                	mov    (%eax),%eax
8010015a:	83 e0 04             	and    $0x4,%eax
8010015d:	85 c0                	test   %eax,%eax
8010015f:	75 4c                	jne    801001ad <bget+0xed>
      b->dev = dev;
80100161:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100164:	8b 55 08             	mov    0x8(%ebp),%edx
80100167:	89 50 04             	mov    %edx,0x4(%eax)
      b->blockno = blockno;
8010016a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016d:	8b 55 0c             	mov    0xc(%ebp),%edx
80100170:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = 0;
80100173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100176:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      b->refcnt = 1;
8010017c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010017f:	c7 40 4c 01 00 00 00 	movl   $0x1,0x4c(%eax)
      release(&bcache.lock);
80100186:	83 ec 0c             	sub    $0xc,%esp
80100189:	68 40 c6 10 80       	push   $0x8010c640
8010018e:	e8 4a 4e 00 00       	call   80104fdd <release>
80100193:	83 c4 10             	add    $0x10,%esp
      acquiresleep(&b->lock);
80100196:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100199:	83 c0 0c             	add    $0xc,%eax
8010019c:	83 ec 0c             	sub    $0xc,%esp
8010019f:	50                   	push   %eax
801001a0:	e8 61 4c 00 00       	call   80104e06 <acquiresleep>
801001a5:	83 c4 10             	add    $0x10,%esp
      return b;
801001a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001ab:	eb 1f                	jmp    801001cc <bget+0x10c>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
801001ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001b0:	8b 40 50             	mov    0x50(%eax),%eax
801001b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801001b6:	81 7d f4 3c 0d 11 80 	cmpl   $0x80110d3c,-0xc(%ebp)
801001bd:	75 8c                	jne    8010014b <bget+0x8b>
    }
  }
  panic("bget: no buffers");
801001bf:	83 ec 0c             	sub    $0xc,%esp
801001c2:	68 66 83 10 80       	push   $0x80108366
801001c7:	e8 d0 03 00 00       	call   8010059c <panic>
}
801001cc:	c9                   	leave  
801001cd:	c3                   	ret    

801001ce <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
801001ce:	55                   	push   %ebp
801001cf:	89 e5                	mov    %esp,%ebp
801001d1:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  b = bget(dev, blockno);
801001d4:	83 ec 08             	sub    $0x8,%esp
801001d7:	ff 75 0c             	pushl  0xc(%ebp)
801001da:	ff 75 08             	pushl  0x8(%ebp)
801001dd:	e8 de fe ff ff       	call   801000c0 <bget>
801001e2:	83 c4 10             	add    $0x10,%esp
801001e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((b->flags & B_VALID) == 0) {
801001e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001eb:	8b 00                	mov    (%eax),%eax
801001ed:	83 e0 02             	and    $0x2,%eax
801001f0:	85 c0                	test   %eax,%eax
801001f2:	75 0e                	jne    80100202 <bread+0x34>
    iderw(b);
801001f4:	83 ec 0c             	sub    $0xc,%esp
801001f7:	ff 75 f4             	pushl  -0xc(%ebp)
801001fa:	e8 49 27 00 00       	call   80102948 <iderw>
801001ff:	83 c4 10             	add    $0x10,%esp
  }
  return b;
80100202:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80100205:	c9                   	leave  
80100206:	c3                   	ret    

80100207 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
80100207:	55                   	push   %ebp
80100208:	89 e5                	mov    %esp,%ebp
8010020a:	83 ec 08             	sub    $0x8,%esp
  if(!holdingsleep(&b->lock))
8010020d:	8b 45 08             	mov    0x8(%ebp),%eax
80100210:	83 c0 0c             	add    $0xc,%eax
80100213:	83 ec 0c             	sub    $0xc,%esp
80100216:	50                   	push   %eax
80100217:	e8 9c 4c 00 00       	call   80104eb8 <holdingsleep>
8010021c:	83 c4 10             	add    $0x10,%esp
8010021f:	85 c0                	test   %eax,%eax
80100221:	75 0d                	jne    80100230 <bwrite+0x29>
    panic("bwrite");
80100223:	83 ec 0c             	sub    $0xc,%esp
80100226:	68 77 83 10 80       	push   $0x80108377
8010022b:	e8 6c 03 00 00       	call   8010059c <panic>
  b->flags |= B_DIRTY;
80100230:	8b 45 08             	mov    0x8(%ebp),%eax
80100233:	8b 00                	mov    (%eax),%eax
80100235:	83 c8 04             	or     $0x4,%eax
80100238:	89 c2                	mov    %eax,%edx
8010023a:	8b 45 08             	mov    0x8(%ebp),%eax
8010023d:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010023f:	83 ec 0c             	sub    $0xc,%esp
80100242:	ff 75 08             	pushl  0x8(%ebp)
80100245:	e8 fe 26 00 00       	call   80102948 <iderw>
8010024a:	83 c4 10             	add    $0x10,%esp
}
8010024d:	90                   	nop
8010024e:	c9                   	leave  
8010024f:	c3                   	ret    

80100250 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100250:	55                   	push   %ebp
80100251:	89 e5                	mov    %esp,%ebp
80100253:	83 ec 08             	sub    $0x8,%esp
  if(!holdingsleep(&b->lock))
80100256:	8b 45 08             	mov    0x8(%ebp),%eax
80100259:	83 c0 0c             	add    $0xc,%eax
8010025c:	83 ec 0c             	sub    $0xc,%esp
8010025f:	50                   	push   %eax
80100260:	e8 53 4c 00 00       	call   80104eb8 <holdingsleep>
80100265:	83 c4 10             	add    $0x10,%esp
80100268:	85 c0                	test   %eax,%eax
8010026a:	75 0d                	jne    80100279 <brelse+0x29>
    panic("brelse");
8010026c:	83 ec 0c             	sub    $0xc,%esp
8010026f:	68 7e 83 10 80       	push   $0x8010837e
80100274:	e8 23 03 00 00       	call   8010059c <panic>

  releasesleep(&b->lock);
80100279:	8b 45 08             	mov    0x8(%ebp),%eax
8010027c:	83 c0 0c             	add    $0xc,%eax
8010027f:	83 ec 0c             	sub    $0xc,%esp
80100282:	50                   	push   %eax
80100283:	e8 e2 4b 00 00       	call   80104e6a <releasesleep>
80100288:	83 c4 10             	add    $0x10,%esp

  acquire(&bcache.lock);
8010028b:	83 ec 0c             	sub    $0xc,%esp
8010028e:	68 40 c6 10 80       	push   $0x8010c640
80100293:	e8 d7 4c 00 00       	call   80104f6f <acquire>
80100298:	83 c4 10             	add    $0x10,%esp
  b->refcnt--;
8010029b:	8b 45 08             	mov    0x8(%ebp),%eax
8010029e:	8b 40 4c             	mov    0x4c(%eax),%eax
801002a1:	8d 50 ff             	lea    -0x1(%eax),%edx
801002a4:	8b 45 08             	mov    0x8(%ebp),%eax
801002a7:	89 50 4c             	mov    %edx,0x4c(%eax)
  if (b->refcnt == 0) {
801002aa:	8b 45 08             	mov    0x8(%ebp),%eax
801002ad:	8b 40 4c             	mov    0x4c(%eax),%eax
801002b0:	85 c0                	test   %eax,%eax
801002b2:	75 47                	jne    801002fb <brelse+0xab>
    // no one is waiting for it.
    b->next->prev = b->prev;
801002b4:	8b 45 08             	mov    0x8(%ebp),%eax
801002b7:	8b 40 54             	mov    0x54(%eax),%eax
801002ba:	8b 55 08             	mov    0x8(%ebp),%edx
801002bd:	8b 52 50             	mov    0x50(%edx),%edx
801002c0:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
801002c3:	8b 45 08             	mov    0x8(%ebp),%eax
801002c6:	8b 40 50             	mov    0x50(%eax),%eax
801002c9:	8b 55 08             	mov    0x8(%ebp),%edx
801002cc:	8b 52 54             	mov    0x54(%edx),%edx
801002cf:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
801002d2:	8b 15 90 0d 11 80    	mov    0x80110d90,%edx
801002d8:	8b 45 08             	mov    0x8(%ebp),%eax
801002db:	89 50 54             	mov    %edx,0x54(%eax)
    b->prev = &bcache.head;
801002de:	8b 45 08             	mov    0x8(%ebp),%eax
801002e1:	c7 40 50 3c 0d 11 80 	movl   $0x80110d3c,0x50(%eax)
    bcache.head.next->prev = b;
801002e8:	a1 90 0d 11 80       	mov    0x80110d90,%eax
801002ed:	8b 55 08             	mov    0x8(%ebp),%edx
801002f0:	89 50 50             	mov    %edx,0x50(%eax)
    bcache.head.next = b;
801002f3:	8b 45 08             	mov    0x8(%ebp),%eax
801002f6:	a3 90 0d 11 80       	mov    %eax,0x80110d90
  }
  
  release(&bcache.lock);
801002fb:	83 ec 0c             	sub    $0xc,%esp
801002fe:	68 40 c6 10 80       	push   $0x8010c640
80100303:	e8 d5 4c 00 00       	call   80104fdd <release>
80100308:	83 c4 10             	add    $0x10,%esp
}
8010030b:	90                   	nop
8010030c:	c9                   	leave  
8010030d:	c3                   	ret    

8010030e <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010030e:	55                   	push   %ebp
8010030f:	89 e5                	mov    %esp,%ebp
80100311:	83 ec 14             	sub    $0x14,%esp
80100314:	8b 45 08             	mov    0x8(%ebp),%eax
80100317:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010031b:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010031f:	89 c2                	mov    %eax,%edx
80100321:	ec                   	in     (%dx),%al
80100322:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80100325:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80100329:	c9                   	leave  
8010032a:	c3                   	ret    

8010032b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010032b:	55                   	push   %ebp
8010032c:	89 e5                	mov    %esp,%ebp
8010032e:	83 ec 08             	sub    $0x8,%esp
80100331:	8b 55 08             	mov    0x8(%ebp),%edx
80100334:	8b 45 0c             	mov    0xc(%ebp),%eax
80100337:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010033b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010033e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80100342:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80100346:	ee                   	out    %al,(%dx)
}
80100347:	90                   	nop
80100348:	c9                   	leave  
80100349:	c3                   	ret    

8010034a <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
8010034a:	55                   	push   %ebp
8010034b:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
8010034d:	fa                   	cli    
}
8010034e:	90                   	nop
8010034f:	5d                   	pop    %ebp
80100350:	c3                   	ret    

80100351 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
80100351:	55                   	push   %ebp
80100352:	89 e5                	mov    %esp,%ebp
80100354:	83 ec 28             	sub    $0x28,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100357:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010035b:	74 1c                	je     80100379 <printint+0x28>
8010035d:	8b 45 08             	mov    0x8(%ebp),%eax
80100360:	c1 e8 1f             	shr    $0x1f,%eax
80100363:	0f b6 c0             	movzbl %al,%eax
80100366:	89 45 10             	mov    %eax,0x10(%ebp)
80100369:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010036d:	74 0a                	je     80100379 <printint+0x28>
    x = -xx;
8010036f:	8b 45 08             	mov    0x8(%ebp),%eax
80100372:	f7 d8                	neg    %eax
80100374:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100377:	eb 06                	jmp    8010037f <printint+0x2e>
  else
    x = xx;
80100379:	8b 45 08             	mov    0x8(%ebp),%eax
8010037c:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
8010037f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100386:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100389:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010038c:	ba 00 00 00 00       	mov    $0x0,%edx
80100391:	f7 f1                	div    %ecx
80100393:	89 d1                	mov    %edx,%ecx
80100395:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100398:	8d 50 01             	lea    0x1(%eax),%edx
8010039b:	89 55 f4             	mov    %edx,-0xc(%ebp)
8010039e:	0f b6 91 04 90 10 80 	movzbl -0x7fef6ffc(%ecx),%edx
801003a5:	88 54 05 e0          	mov    %dl,-0x20(%ebp,%eax,1)
  }while((x /= base) != 0);
801003a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801003ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801003af:	ba 00 00 00 00       	mov    $0x0,%edx
801003b4:	f7 f1                	div    %ecx
801003b6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801003b9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801003bd:	75 c7                	jne    80100386 <printint+0x35>

  if(sign)
801003bf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801003c3:	74 2a                	je     801003ef <printint+0x9e>
    buf[i++] = '-';
801003c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801003c8:	8d 50 01             	lea    0x1(%eax),%edx
801003cb:	89 55 f4             	mov    %edx,-0xc(%ebp)
801003ce:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
801003d3:	eb 1a                	jmp    801003ef <printint+0x9e>
    consputc(buf[i]);
801003d5:	8d 55 e0             	lea    -0x20(%ebp),%edx
801003d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801003db:	01 d0                	add    %edx,%eax
801003dd:	0f b6 00             	movzbl (%eax),%eax
801003e0:	0f be c0             	movsbl %al,%eax
801003e3:	83 ec 0c             	sub    $0xc,%esp
801003e6:	50                   	push   %eax
801003e7:	e8 dd 03 00 00       	call   801007c9 <consputc>
801003ec:	83 c4 10             	add    $0x10,%esp
  while(--i >= 0)
801003ef:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
801003f3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801003f7:	79 dc                	jns    801003d5 <printint+0x84>
}
801003f9:	90                   	nop
801003fa:	c9                   	leave  
801003fb:	c3                   	ret    

801003fc <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003fc:	55                   	push   %ebp
801003fd:	89 e5                	mov    %esp,%ebp
801003ff:	83 ec 28             	sub    $0x28,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
80100402:	a1 d4 b5 10 80       	mov    0x8010b5d4,%eax
80100407:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
8010040a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010040e:	74 10                	je     80100420 <cprintf+0x24>
    acquire(&cons.lock);
80100410:	83 ec 0c             	sub    $0xc,%esp
80100413:	68 a0 b5 10 80       	push   $0x8010b5a0
80100418:	e8 52 4b 00 00       	call   80104f6f <acquire>
8010041d:	83 c4 10             	add    $0x10,%esp

  if (fmt == 0)
80100420:	8b 45 08             	mov    0x8(%ebp),%eax
80100423:	85 c0                	test   %eax,%eax
80100425:	75 0d                	jne    80100434 <cprintf+0x38>
    panic("null fmt");
80100427:	83 ec 0c             	sub    $0xc,%esp
8010042a:	68 85 83 10 80       	push   $0x80108385
8010042f:	e8 68 01 00 00       	call   8010059c <panic>

  argp = (uint*)(void*)(&fmt + 1);
80100434:	8d 45 0c             	lea    0xc(%ebp),%eax
80100437:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
8010043a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100441:	e9 1a 01 00 00       	jmp    80100560 <cprintf+0x164>
    if(c != '%'){
80100446:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
8010044a:	74 13                	je     8010045f <cprintf+0x63>
      consputc(c);
8010044c:	83 ec 0c             	sub    $0xc,%esp
8010044f:	ff 75 e4             	pushl  -0x1c(%ebp)
80100452:	e8 72 03 00 00       	call   801007c9 <consputc>
80100457:	83 c4 10             	add    $0x10,%esp
      continue;
8010045a:	e9 fd 00 00 00       	jmp    8010055c <cprintf+0x160>
    }
    c = fmt[++i] & 0xff;
8010045f:	8b 55 08             	mov    0x8(%ebp),%edx
80100462:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100466:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100469:	01 d0                	add    %edx,%eax
8010046b:	0f b6 00             	movzbl (%eax),%eax
8010046e:	0f be c0             	movsbl %al,%eax
80100471:	25 ff 00 00 00       	and    $0xff,%eax
80100476:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100479:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010047d:	0f 84 ff 00 00 00    	je     80100582 <cprintf+0x186>
      break;
    switch(c){
80100483:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100486:	83 f8 70             	cmp    $0x70,%eax
80100489:	74 47                	je     801004d2 <cprintf+0xd6>
8010048b:	83 f8 70             	cmp    $0x70,%eax
8010048e:	7f 13                	jg     801004a3 <cprintf+0xa7>
80100490:	83 f8 25             	cmp    $0x25,%eax
80100493:	0f 84 98 00 00 00    	je     80100531 <cprintf+0x135>
80100499:	83 f8 64             	cmp    $0x64,%eax
8010049c:	74 14                	je     801004b2 <cprintf+0xb6>
8010049e:	e9 9d 00 00 00       	jmp    80100540 <cprintf+0x144>
801004a3:	83 f8 73             	cmp    $0x73,%eax
801004a6:	74 47                	je     801004ef <cprintf+0xf3>
801004a8:	83 f8 78             	cmp    $0x78,%eax
801004ab:	74 25                	je     801004d2 <cprintf+0xd6>
801004ad:	e9 8e 00 00 00       	jmp    80100540 <cprintf+0x144>
    case 'd':
      printint(*argp++, 10, 1);
801004b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004b5:	8d 50 04             	lea    0x4(%eax),%edx
801004b8:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004bb:	8b 00                	mov    (%eax),%eax
801004bd:	83 ec 04             	sub    $0x4,%esp
801004c0:	6a 01                	push   $0x1
801004c2:	6a 0a                	push   $0xa
801004c4:	50                   	push   %eax
801004c5:	e8 87 fe ff ff       	call   80100351 <printint>
801004ca:	83 c4 10             	add    $0x10,%esp
      break;
801004cd:	e9 8a 00 00 00       	jmp    8010055c <cprintf+0x160>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
801004d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004d5:	8d 50 04             	lea    0x4(%eax),%edx
801004d8:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004db:	8b 00                	mov    (%eax),%eax
801004dd:	83 ec 04             	sub    $0x4,%esp
801004e0:	6a 00                	push   $0x0
801004e2:	6a 10                	push   $0x10
801004e4:	50                   	push   %eax
801004e5:	e8 67 fe ff ff       	call   80100351 <printint>
801004ea:	83 c4 10             	add    $0x10,%esp
      break;
801004ed:	eb 6d                	jmp    8010055c <cprintf+0x160>
    case 's':
      if((s = (char*)*argp++) == 0)
801004ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004f2:	8d 50 04             	lea    0x4(%eax),%edx
801004f5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004f8:	8b 00                	mov    (%eax),%eax
801004fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004fd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80100501:	75 22                	jne    80100525 <cprintf+0x129>
        s = "(null)";
80100503:	c7 45 ec 8e 83 10 80 	movl   $0x8010838e,-0x14(%ebp)
      for(; *s; s++)
8010050a:	eb 19                	jmp    80100525 <cprintf+0x129>
        consputc(*s);
8010050c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010050f:	0f b6 00             	movzbl (%eax),%eax
80100512:	0f be c0             	movsbl %al,%eax
80100515:	83 ec 0c             	sub    $0xc,%esp
80100518:	50                   	push   %eax
80100519:	e8 ab 02 00 00       	call   801007c9 <consputc>
8010051e:	83 c4 10             	add    $0x10,%esp
      for(; *s; s++)
80100521:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100525:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100528:	0f b6 00             	movzbl (%eax),%eax
8010052b:	84 c0                	test   %al,%al
8010052d:	75 dd                	jne    8010050c <cprintf+0x110>
      break;
8010052f:	eb 2b                	jmp    8010055c <cprintf+0x160>
    case '%':
      consputc('%');
80100531:	83 ec 0c             	sub    $0xc,%esp
80100534:	6a 25                	push   $0x25
80100536:	e8 8e 02 00 00       	call   801007c9 <consputc>
8010053b:	83 c4 10             	add    $0x10,%esp
      break;
8010053e:	eb 1c                	jmp    8010055c <cprintf+0x160>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
80100540:	83 ec 0c             	sub    $0xc,%esp
80100543:	6a 25                	push   $0x25
80100545:	e8 7f 02 00 00       	call   801007c9 <consputc>
8010054a:	83 c4 10             	add    $0x10,%esp
      consputc(c);
8010054d:	83 ec 0c             	sub    $0xc,%esp
80100550:	ff 75 e4             	pushl  -0x1c(%ebp)
80100553:	e8 71 02 00 00       	call   801007c9 <consputc>
80100558:	83 c4 10             	add    $0x10,%esp
      break;
8010055b:	90                   	nop
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
8010055c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100560:	8b 55 08             	mov    0x8(%ebp),%edx
80100563:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100566:	01 d0                	add    %edx,%eax
80100568:	0f b6 00             	movzbl (%eax),%eax
8010056b:	0f be c0             	movsbl %al,%eax
8010056e:	25 ff 00 00 00       	and    $0xff,%eax
80100573:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80100576:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010057a:	0f 85 c6 fe ff ff    	jne    80100446 <cprintf+0x4a>
80100580:	eb 01                	jmp    80100583 <cprintf+0x187>
      break;
80100582:	90                   	nop
    }
  }

  if(locking)
80100583:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80100587:	74 10                	je     80100599 <cprintf+0x19d>
    release(&cons.lock);
80100589:	83 ec 0c             	sub    $0xc,%esp
8010058c:	68 a0 b5 10 80       	push   $0x8010b5a0
80100591:	e8 47 4a 00 00       	call   80104fdd <release>
80100596:	83 c4 10             	add    $0x10,%esp
}
80100599:	90                   	nop
8010059a:	c9                   	leave  
8010059b:	c3                   	ret    

8010059c <panic>:

void
panic(char *s)
{
8010059c:	55                   	push   %ebp
8010059d:	89 e5                	mov    %esp,%ebp
8010059f:	83 ec 38             	sub    $0x38,%esp
  int i;
  uint pcs[10];

  cli();
801005a2:	e8 a3 fd ff ff       	call   8010034a <cli>
  cons.locking = 0;
801005a7:	c7 05 d4 b5 10 80 00 	movl   $0x0,0x8010b5d4
801005ae:	00 00 00 
  // use lapiccpunum so that we can call panic from mycpu()
  cprintf("lapicid %d: panic: ", lapicid());
801005b1:	e8 21 2a 00 00       	call   80102fd7 <lapicid>
801005b6:	83 ec 08             	sub    $0x8,%esp
801005b9:	50                   	push   %eax
801005ba:	68 95 83 10 80       	push   $0x80108395
801005bf:	e8 38 fe ff ff       	call   801003fc <cprintf>
801005c4:	83 c4 10             	add    $0x10,%esp
  cprintf(s);
801005c7:	8b 45 08             	mov    0x8(%ebp),%eax
801005ca:	83 ec 0c             	sub    $0xc,%esp
801005cd:	50                   	push   %eax
801005ce:	e8 29 fe ff ff       	call   801003fc <cprintf>
801005d3:	83 c4 10             	add    $0x10,%esp
  cprintf("\n");
801005d6:	83 ec 0c             	sub    $0xc,%esp
801005d9:	68 a9 83 10 80       	push   $0x801083a9
801005de:	e8 19 fe ff ff       	call   801003fc <cprintf>
801005e3:	83 c4 10             	add    $0x10,%esp
  getcallerpcs(&s, pcs);
801005e6:	83 ec 08             	sub    $0x8,%esp
801005e9:	8d 45 cc             	lea    -0x34(%ebp),%eax
801005ec:	50                   	push   %eax
801005ed:	8d 45 08             	lea    0x8(%ebp),%eax
801005f0:	50                   	push   %eax
801005f1:	e8 39 4a 00 00       	call   8010502f <getcallerpcs>
801005f6:	83 c4 10             	add    $0x10,%esp
  for(i=0; i<10; i++)
801005f9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100600:	eb 1c                	jmp    8010061e <panic+0x82>
    cprintf(" %p", pcs[i]);
80100602:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100605:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
80100609:	83 ec 08             	sub    $0x8,%esp
8010060c:	50                   	push   %eax
8010060d:	68 ab 83 10 80       	push   $0x801083ab
80100612:	e8 e5 fd ff ff       	call   801003fc <cprintf>
80100617:	83 c4 10             	add    $0x10,%esp
  for(i=0; i<10; i++)
8010061a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010061e:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80100622:	7e de                	jle    80100602 <panic+0x66>
  panicked = 1; // freeze other CPU
80100624:	c7 05 80 b5 10 80 01 	movl   $0x1,0x8010b580
8010062b:	00 00 00 
  for(;;)
8010062e:	eb fe                	jmp    8010062e <panic+0x92>

80100630 <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
80100630:	55                   	push   %ebp
80100631:	89 e5                	mov    %esp,%ebp
80100633:	53                   	push   %ebx
80100634:	83 ec 14             	sub    $0x14,%esp
  int pos;

  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
80100637:	6a 0e                	push   $0xe
80100639:	68 d4 03 00 00       	push   $0x3d4
8010063e:	e8 e8 fc ff ff       	call   8010032b <outb>
80100643:	83 c4 08             	add    $0x8,%esp
  pos = inb(CRTPORT+1) << 8;
80100646:	68 d5 03 00 00       	push   $0x3d5
8010064b:	e8 be fc ff ff       	call   8010030e <inb>
80100650:	83 c4 04             	add    $0x4,%esp
80100653:	0f b6 c0             	movzbl %al,%eax
80100656:	c1 e0 08             	shl    $0x8,%eax
80100659:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
8010065c:	6a 0f                	push   $0xf
8010065e:	68 d4 03 00 00       	push   $0x3d4
80100663:	e8 c3 fc ff ff       	call   8010032b <outb>
80100668:	83 c4 08             	add    $0x8,%esp
  pos |= inb(CRTPORT+1);
8010066b:	68 d5 03 00 00       	push   $0x3d5
80100670:	e8 99 fc ff ff       	call   8010030e <inb>
80100675:	83 c4 04             	add    $0x4,%esp
80100678:	0f b6 c0             	movzbl %al,%eax
8010067b:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010067e:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100682:	75 30                	jne    801006b4 <cgaputc+0x84>
    pos += 80 - pos%80;
80100684:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100687:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010068c:	89 c8                	mov    %ecx,%eax
8010068e:	f7 ea                	imul   %edx
80100690:	c1 fa 05             	sar    $0x5,%edx
80100693:	89 c8                	mov    %ecx,%eax
80100695:	c1 f8 1f             	sar    $0x1f,%eax
80100698:	29 c2                	sub    %eax,%edx
8010069a:	89 d0                	mov    %edx,%eax
8010069c:	c1 e0 02             	shl    $0x2,%eax
8010069f:	01 d0                	add    %edx,%eax
801006a1:	c1 e0 04             	shl    $0x4,%eax
801006a4:	29 c1                	sub    %eax,%ecx
801006a6:	89 ca                	mov    %ecx,%edx
801006a8:	b8 50 00 00 00       	mov    $0x50,%eax
801006ad:	29 d0                	sub    %edx,%eax
801006af:	01 45 f4             	add    %eax,-0xc(%ebp)
801006b2:	eb 38                	jmp    801006ec <cgaputc+0xbc>
  else if(c == BACKSPACE){
801006b4:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
801006bb:	75 0c                	jne    801006c9 <cgaputc+0x99>
    if(pos > 0) --pos;
801006bd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801006c1:	7e 29                	jle    801006ec <cgaputc+0xbc>
801006c3:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
801006c7:	eb 23                	jmp    801006ec <cgaputc+0xbc>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
801006c9:	8b 45 08             	mov    0x8(%ebp),%eax
801006cc:	0f b6 c0             	movzbl %al,%eax
801006cf:	80 cc 07             	or     $0x7,%ah
801006d2:	89 c3                	mov    %eax,%ebx
801006d4:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
801006da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006dd:	8d 50 01             	lea    0x1(%eax),%edx
801006e0:	89 55 f4             	mov    %edx,-0xc(%ebp)
801006e3:	01 c0                	add    %eax,%eax
801006e5:	01 c8                	add    %ecx,%eax
801006e7:	89 da                	mov    %ebx,%edx
801006e9:	66 89 10             	mov    %dx,(%eax)

  if(pos < 0 || pos > 25*80)
801006ec:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801006f0:	78 09                	js     801006fb <cgaputc+0xcb>
801006f2:	81 7d f4 d0 07 00 00 	cmpl   $0x7d0,-0xc(%ebp)
801006f9:	7e 0d                	jle    80100708 <cgaputc+0xd8>
    panic("pos under/overflow");
801006fb:	83 ec 0c             	sub    $0xc,%esp
801006fe:	68 af 83 10 80       	push   $0x801083af
80100703:	e8 94 fe ff ff       	call   8010059c <panic>

  if((pos/80) >= 24){  // Scroll up.
80100708:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
8010070f:	7e 4c                	jle    8010075d <cgaputc+0x12d>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100711:	a1 00 90 10 80       	mov    0x80109000,%eax
80100716:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010071c:	a1 00 90 10 80       	mov    0x80109000,%eax
80100721:	83 ec 04             	sub    $0x4,%esp
80100724:	68 60 0e 00 00       	push   $0xe60
80100729:	52                   	push   %edx
8010072a:	50                   	push   %eax
8010072b:	e8 85 4b 00 00       	call   801052b5 <memmove>
80100730:	83 c4 10             	add    $0x10,%esp
    pos -= 80;
80100733:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
80100737:	b8 80 07 00 00       	mov    $0x780,%eax
8010073c:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010073f:	8d 14 00             	lea    (%eax,%eax,1),%edx
80100742:	a1 00 90 10 80       	mov    0x80109000,%eax
80100747:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010074a:	01 c9                	add    %ecx,%ecx
8010074c:	01 c8                	add    %ecx,%eax
8010074e:	83 ec 04             	sub    $0x4,%esp
80100751:	52                   	push   %edx
80100752:	6a 00                	push   $0x0
80100754:	50                   	push   %eax
80100755:	e8 9c 4a 00 00       	call   801051f6 <memset>
8010075a:	83 c4 10             	add    $0x10,%esp
  }

  outb(CRTPORT, 14);
8010075d:	83 ec 08             	sub    $0x8,%esp
80100760:	6a 0e                	push   $0xe
80100762:	68 d4 03 00 00       	push   $0x3d4
80100767:	e8 bf fb ff ff       	call   8010032b <outb>
8010076c:	83 c4 10             	add    $0x10,%esp
  outb(CRTPORT+1, pos>>8);
8010076f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100772:	c1 f8 08             	sar    $0x8,%eax
80100775:	0f b6 c0             	movzbl %al,%eax
80100778:	83 ec 08             	sub    $0x8,%esp
8010077b:	50                   	push   %eax
8010077c:	68 d5 03 00 00       	push   $0x3d5
80100781:	e8 a5 fb ff ff       	call   8010032b <outb>
80100786:	83 c4 10             	add    $0x10,%esp
  outb(CRTPORT, 15);
80100789:	83 ec 08             	sub    $0x8,%esp
8010078c:	6a 0f                	push   $0xf
8010078e:	68 d4 03 00 00       	push   $0x3d4
80100793:	e8 93 fb ff ff       	call   8010032b <outb>
80100798:	83 c4 10             	add    $0x10,%esp
  outb(CRTPORT+1, pos);
8010079b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010079e:	0f b6 c0             	movzbl %al,%eax
801007a1:	83 ec 08             	sub    $0x8,%esp
801007a4:	50                   	push   %eax
801007a5:	68 d5 03 00 00       	push   $0x3d5
801007aa:	e8 7c fb ff ff       	call   8010032b <outb>
801007af:	83 c4 10             	add    $0x10,%esp
  crt[pos] = ' ' | 0x0700;
801007b2:	a1 00 90 10 80       	mov    0x80109000,%eax
801007b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801007ba:	01 d2                	add    %edx,%edx
801007bc:	01 d0                	add    %edx,%eax
801007be:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
801007c3:	90                   	nop
801007c4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801007c7:	c9                   	leave  
801007c8:	c3                   	ret    

801007c9 <consputc>:

void
consputc(int c)
{
801007c9:	55                   	push   %ebp
801007ca:	89 e5                	mov    %esp,%ebp
801007cc:	83 ec 08             	sub    $0x8,%esp
  if(panicked){
801007cf:	a1 80 b5 10 80       	mov    0x8010b580,%eax
801007d4:	85 c0                	test   %eax,%eax
801007d6:	74 07                	je     801007df <consputc+0x16>
    cli();
801007d8:	e8 6d fb ff ff       	call   8010034a <cli>
    for(;;)
801007dd:	eb fe                	jmp    801007dd <consputc+0x14>
      ;
  }

  if(c == BACKSPACE){
801007df:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
801007e6:	75 29                	jne    80100811 <consputc+0x48>
    uartputc('\b'); uartputc(' '); uartputc('\b');
801007e8:	83 ec 0c             	sub    $0xc,%esp
801007eb:	6a 08                	push   $0x8
801007ed:	e8 16 63 00 00       	call   80106b08 <uartputc>
801007f2:	83 c4 10             	add    $0x10,%esp
801007f5:	83 ec 0c             	sub    $0xc,%esp
801007f8:	6a 20                	push   $0x20
801007fa:	e8 09 63 00 00       	call   80106b08 <uartputc>
801007ff:	83 c4 10             	add    $0x10,%esp
80100802:	83 ec 0c             	sub    $0xc,%esp
80100805:	6a 08                	push   $0x8
80100807:	e8 fc 62 00 00       	call   80106b08 <uartputc>
8010080c:	83 c4 10             	add    $0x10,%esp
8010080f:	eb 0e                	jmp    8010081f <consputc+0x56>
  } else
    uartputc(c);
80100811:	83 ec 0c             	sub    $0xc,%esp
80100814:	ff 75 08             	pushl  0x8(%ebp)
80100817:	e8 ec 62 00 00       	call   80106b08 <uartputc>
8010081c:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010081f:	83 ec 0c             	sub    $0xc,%esp
80100822:	ff 75 08             	pushl  0x8(%ebp)
80100825:	e8 06 fe ff ff       	call   80100630 <cgaputc>
8010082a:	83 c4 10             	add    $0x10,%esp
}
8010082d:	90                   	nop
8010082e:	c9                   	leave  
8010082f:	c3                   	ret    

80100830 <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
80100830:	55                   	push   %ebp
80100831:	89 e5                	mov    %esp,%ebp
80100833:	83 ec 18             	sub    $0x18,%esp
  int c, doprocdump = 0;
80100836:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
8010083d:	83 ec 0c             	sub    $0xc,%esp
80100840:	68 a0 b5 10 80       	push   $0x8010b5a0
80100845:	e8 25 47 00 00       	call   80104f6f <acquire>
8010084a:	83 c4 10             	add    $0x10,%esp
  while((c = getc()) >= 0){
8010084d:	e9 44 01 00 00       	jmp    80100996 <consoleintr+0x166>
    switch(c){
80100852:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100855:	83 f8 10             	cmp    $0x10,%eax
80100858:	74 1e                	je     80100878 <consoleintr+0x48>
8010085a:	83 f8 10             	cmp    $0x10,%eax
8010085d:	7f 0a                	jg     80100869 <consoleintr+0x39>
8010085f:	83 f8 08             	cmp    $0x8,%eax
80100862:	74 6b                	je     801008cf <consoleintr+0x9f>
80100864:	e9 9b 00 00 00       	jmp    80100904 <consoleintr+0xd4>
80100869:	83 f8 15             	cmp    $0x15,%eax
8010086c:	74 33                	je     801008a1 <consoleintr+0x71>
8010086e:	83 f8 7f             	cmp    $0x7f,%eax
80100871:	74 5c                	je     801008cf <consoleintr+0x9f>
80100873:	e9 8c 00 00 00       	jmp    80100904 <consoleintr+0xd4>
    case C('P'):  // Process listing.
      // procdump() locks cons.lock indirectly; invoke later
      doprocdump = 1;
80100878:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
8010087f:	e9 12 01 00 00       	jmp    80100996 <consoleintr+0x166>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100884:	a1 28 10 11 80       	mov    0x80111028,%eax
80100889:	83 e8 01             	sub    $0x1,%eax
8010088c:	a3 28 10 11 80       	mov    %eax,0x80111028
        consputc(BACKSPACE);
80100891:	83 ec 0c             	sub    $0xc,%esp
80100894:	68 00 01 00 00       	push   $0x100
80100899:	e8 2b ff ff ff       	call   801007c9 <consputc>
8010089e:	83 c4 10             	add    $0x10,%esp
      while(input.e != input.w &&
801008a1:	8b 15 28 10 11 80    	mov    0x80111028,%edx
801008a7:	a1 24 10 11 80       	mov    0x80111024,%eax
801008ac:	39 c2                	cmp    %eax,%edx
801008ae:	0f 84 e2 00 00 00    	je     80100996 <consoleintr+0x166>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
801008b4:	a1 28 10 11 80       	mov    0x80111028,%eax
801008b9:	83 e8 01             	sub    $0x1,%eax
801008bc:	83 e0 7f             	and    $0x7f,%eax
801008bf:	0f b6 80 a0 0f 11 80 	movzbl -0x7feef060(%eax),%eax
      while(input.e != input.w &&
801008c6:	3c 0a                	cmp    $0xa,%al
801008c8:	75 ba                	jne    80100884 <consoleintr+0x54>
      }
      break;
801008ca:	e9 c7 00 00 00       	jmp    80100996 <consoleintr+0x166>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
801008cf:	8b 15 28 10 11 80    	mov    0x80111028,%edx
801008d5:	a1 24 10 11 80       	mov    0x80111024,%eax
801008da:	39 c2                	cmp    %eax,%edx
801008dc:	0f 84 b4 00 00 00    	je     80100996 <consoleintr+0x166>
        input.e--;
801008e2:	a1 28 10 11 80       	mov    0x80111028,%eax
801008e7:	83 e8 01             	sub    $0x1,%eax
801008ea:	a3 28 10 11 80       	mov    %eax,0x80111028
        consputc(BACKSPACE);
801008ef:	83 ec 0c             	sub    $0xc,%esp
801008f2:	68 00 01 00 00       	push   $0x100
801008f7:	e8 cd fe ff ff       	call   801007c9 <consputc>
801008fc:	83 c4 10             	add    $0x10,%esp
      }
      break;
801008ff:	e9 92 00 00 00       	jmp    80100996 <consoleintr+0x166>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100904:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100908:	0f 84 87 00 00 00    	je     80100995 <consoleintr+0x165>
8010090e:	8b 15 28 10 11 80    	mov    0x80111028,%edx
80100914:	a1 20 10 11 80       	mov    0x80111020,%eax
80100919:	29 c2                	sub    %eax,%edx
8010091b:	89 d0                	mov    %edx,%eax
8010091d:	83 f8 7f             	cmp    $0x7f,%eax
80100920:	77 73                	ja     80100995 <consoleintr+0x165>
        c = (c == '\r') ? '\n' : c;
80100922:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80100926:	74 05                	je     8010092d <consoleintr+0xfd>
80100928:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010092b:	eb 05                	jmp    80100932 <consoleintr+0x102>
8010092d:	b8 0a 00 00 00       	mov    $0xa,%eax
80100932:	89 45 f0             	mov    %eax,-0x10(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
80100935:	a1 28 10 11 80       	mov    0x80111028,%eax
8010093a:	8d 50 01             	lea    0x1(%eax),%edx
8010093d:	89 15 28 10 11 80    	mov    %edx,0x80111028
80100943:	83 e0 7f             	and    $0x7f,%eax
80100946:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100949:	88 90 a0 0f 11 80    	mov    %dl,-0x7feef060(%eax)
        consputc(c);
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	ff 75 f0             	pushl  -0x10(%ebp)
80100955:	e8 6f fe ff ff       	call   801007c9 <consputc>
8010095a:	83 c4 10             	add    $0x10,%esp
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
8010095d:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100961:	74 18                	je     8010097b <consoleintr+0x14b>
80100963:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100967:	74 12                	je     8010097b <consoleintr+0x14b>
80100969:	a1 28 10 11 80       	mov    0x80111028,%eax
8010096e:	8b 15 20 10 11 80    	mov    0x80111020,%edx
80100974:	83 ea 80             	sub    $0xffffff80,%edx
80100977:	39 d0                	cmp    %edx,%eax
80100979:	75 1a                	jne    80100995 <consoleintr+0x165>
          input.w = input.e;
8010097b:	a1 28 10 11 80       	mov    0x80111028,%eax
80100980:	a3 24 10 11 80       	mov    %eax,0x80111024
          wakeup(&input.r);
80100985:	83 ec 0c             	sub    $0xc,%esp
80100988:	68 20 10 11 80       	push   $0x80111020
8010098d:	e8 84 42 00 00       	call   80104c16 <wakeup>
80100992:	83 c4 10             	add    $0x10,%esp
        }
      }
      break;
80100995:	90                   	nop
  while((c = getc()) >= 0){
80100996:	8b 45 08             	mov    0x8(%ebp),%eax
80100999:	ff d0                	call   *%eax
8010099b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010099e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801009a2:	0f 89 aa fe ff ff    	jns    80100852 <consoleintr+0x22>
    }
  }
  release(&cons.lock);
801009a8:	83 ec 0c             	sub    $0xc,%esp
801009ab:	68 a0 b5 10 80       	push   $0x8010b5a0
801009b0:	e8 28 46 00 00       	call   80104fdd <release>
801009b5:	83 c4 10             	add    $0x10,%esp
  if(doprocdump) {
801009b8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801009bc:	74 05                	je     801009c3 <consoleintr+0x193>
    procdump();  // now call procdump() wo. cons.lock held
801009be:	e8 0e 43 00 00       	call   80104cd1 <procdump>
  }
}
801009c3:	90                   	nop
801009c4:	c9                   	leave  
801009c5:	c3                   	ret    

801009c6 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
801009c6:	55                   	push   %ebp
801009c7:	89 e5                	mov    %esp,%ebp
801009c9:	83 ec 18             	sub    $0x18,%esp
  uint target;
  int c;

  iunlock(ip);
801009cc:	83 ec 0c             	sub    $0xc,%esp
801009cf:	ff 75 08             	pushl  0x8(%ebp)
801009d2:	e8 3d 11 00 00       	call   80101b14 <iunlock>
801009d7:	83 c4 10             	add    $0x10,%esp
  target = n;
801009da:	8b 45 10             	mov    0x10(%ebp),%eax
801009dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
801009e0:	83 ec 0c             	sub    $0xc,%esp
801009e3:	68 a0 b5 10 80       	push   $0x8010b5a0
801009e8:	e8 82 45 00 00       	call   80104f6f <acquire>
801009ed:	83 c4 10             	add    $0x10,%esp
  while(n > 0){
801009f0:	e9 ab 00 00 00       	jmp    80100aa0 <consoleread+0xda>
    while(input.r == input.w){
      if(myproc()->killed){
801009f5:	e8 7f 38 00 00       	call   80104279 <myproc>
801009fa:	8b 40 24             	mov    0x24(%eax),%eax
801009fd:	85 c0                	test   %eax,%eax
801009ff:	74 28                	je     80100a29 <consoleread+0x63>
        release(&cons.lock);
80100a01:	83 ec 0c             	sub    $0xc,%esp
80100a04:	68 a0 b5 10 80       	push   $0x8010b5a0
80100a09:	e8 cf 45 00 00       	call   80104fdd <release>
80100a0e:	83 c4 10             	add    $0x10,%esp
        ilock(ip);
80100a11:	83 ec 0c             	sub    $0xc,%esp
80100a14:	ff 75 08             	pushl  0x8(%ebp)
80100a17:	e8 e5 0f 00 00       	call   80101a01 <ilock>
80100a1c:	83 c4 10             	add    $0x10,%esp
        return -1;
80100a1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100a24:	e9 ab 00 00 00       	jmp    80100ad4 <consoleread+0x10e>
      }
      sleep(&input.r, &cons.lock);
80100a29:	83 ec 08             	sub    $0x8,%esp
80100a2c:	68 a0 b5 10 80       	push   $0x8010b5a0
80100a31:	68 20 10 11 80       	push   $0x80111020
80100a36:	e8 f5 40 00 00       	call   80104b30 <sleep>
80100a3b:	83 c4 10             	add    $0x10,%esp
    while(input.r == input.w){
80100a3e:	8b 15 20 10 11 80    	mov    0x80111020,%edx
80100a44:	a1 24 10 11 80       	mov    0x80111024,%eax
80100a49:	39 c2                	cmp    %eax,%edx
80100a4b:	74 a8                	je     801009f5 <consoleread+0x2f>
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100a4d:	a1 20 10 11 80       	mov    0x80111020,%eax
80100a52:	8d 50 01             	lea    0x1(%eax),%edx
80100a55:	89 15 20 10 11 80    	mov    %edx,0x80111020
80100a5b:	83 e0 7f             	and    $0x7f,%eax
80100a5e:	0f b6 80 a0 0f 11 80 	movzbl -0x7feef060(%eax),%eax
80100a65:	0f be c0             	movsbl %al,%eax
80100a68:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
80100a6b:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100a6f:	75 17                	jne    80100a88 <consoleread+0xc2>
      if(n < target){
80100a71:	8b 45 10             	mov    0x10(%ebp),%eax
80100a74:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80100a77:	76 2f                	jbe    80100aa8 <consoleread+0xe2>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
80100a79:	a1 20 10 11 80       	mov    0x80111020,%eax
80100a7e:	83 e8 01             	sub    $0x1,%eax
80100a81:	a3 20 10 11 80       	mov    %eax,0x80111020
      }
      break;
80100a86:	eb 20                	jmp    80100aa8 <consoleread+0xe2>
    }
    *dst++ = c;
80100a88:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a8b:	8d 50 01             	lea    0x1(%eax),%edx
80100a8e:	89 55 0c             	mov    %edx,0xc(%ebp)
80100a91:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100a94:	88 10                	mov    %dl,(%eax)
    --n;
80100a96:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100a9a:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100a9e:	74 0b                	je     80100aab <consoleread+0xe5>
  while(n > 0){
80100aa0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100aa4:	7f 98                	jg     80100a3e <consoleread+0x78>
80100aa6:	eb 04                	jmp    80100aac <consoleread+0xe6>
      break;
80100aa8:	90                   	nop
80100aa9:	eb 01                	jmp    80100aac <consoleread+0xe6>
      break;
80100aab:	90                   	nop
  }
  release(&cons.lock);
80100aac:	83 ec 0c             	sub    $0xc,%esp
80100aaf:	68 a0 b5 10 80       	push   $0x8010b5a0
80100ab4:	e8 24 45 00 00       	call   80104fdd <release>
80100ab9:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80100abc:	83 ec 0c             	sub    $0xc,%esp
80100abf:	ff 75 08             	pushl  0x8(%ebp)
80100ac2:	e8 3a 0f 00 00       	call   80101a01 <ilock>
80100ac7:	83 c4 10             	add    $0x10,%esp

  return target - n;
80100aca:	8b 45 10             	mov    0x10(%ebp),%eax
80100acd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100ad0:	29 c2                	sub    %eax,%edx
80100ad2:	89 d0                	mov    %edx,%eax
}
80100ad4:	c9                   	leave  
80100ad5:	c3                   	ret    

80100ad6 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100ad6:	55                   	push   %ebp
80100ad7:	89 e5                	mov    %esp,%ebp
80100ad9:	83 ec 18             	sub    $0x18,%esp
  int i;

  iunlock(ip);
80100adc:	83 ec 0c             	sub    $0xc,%esp
80100adf:	ff 75 08             	pushl  0x8(%ebp)
80100ae2:	e8 2d 10 00 00       	call   80101b14 <iunlock>
80100ae7:	83 c4 10             	add    $0x10,%esp
  acquire(&cons.lock);
80100aea:	83 ec 0c             	sub    $0xc,%esp
80100aed:	68 a0 b5 10 80       	push   $0x8010b5a0
80100af2:	e8 78 44 00 00       	call   80104f6f <acquire>
80100af7:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < n; i++)
80100afa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100b01:	eb 21                	jmp    80100b24 <consolewrite+0x4e>
    consputc(buf[i] & 0xff);
80100b03:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100b06:	8b 45 0c             	mov    0xc(%ebp),%eax
80100b09:	01 d0                	add    %edx,%eax
80100b0b:	0f b6 00             	movzbl (%eax),%eax
80100b0e:	0f be c0             	movsbl %al,%eax
80100b11:	0f b6 c0             	movzbl %al,%eax
80100b14:	83 ec 0c             	sub    $0xc,%esp
80100b17:	50                   	push   %eax
80100b18:	e8 ac fc ff ff       	call   801007c9 <consputc>
80100b1d:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < n; i++)
80100b20:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100b24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100b27:	3b 45 10             	cmp    0x10(%ebp),%eax
80100b2a:	7c d7                	jl     80100b03 <consolewrite+0x2d>
  release(&cons.lock);
80100b2c:	83 ec 0c             	sub    $0xc,%esp
80100b2f:	68 a0 b5 10 80       	push   $0x8010b5a0
80100b34:	e8 a4 44 00 00       	call   80104fdd <release>
80100b39:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80100b3c:	83 ec 0c             	sub    $0xc,%esp
80100b3f:	ff 75 08             	pushl  0x8(%ebp)
80100b42:	e8 ba 0e 00 00       	call   80101a01 <ilock>
80100b47:	83 c4 10             	add    $0x10,%esp

  return n;
80100b4a:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100b4d:	c9                   	leave  
80100b4e:	c3                   	ret    

80100b4f <consoleinit>:

void
consoleinit(void)
{
80100b4f:	55                   	push   %ebp
80100b50:	89 e5                	mov    %esp,%ebp
80100b52:	83 ec 08             	sub    $0x8,%esp
  initlock(&cons.lock, "console");
80100b55:	83 ec 08             	sub    $0x8,%esp
80100b58:	68 c2 83 10 80       	push   $0x801083c2
80100b5d:	68 a0 b5 10 80       	push   $0x8010b5a0
80100b62:	e8 e6 43 00 00       	call   80104f4d <initlock>
80100b67:	83 c4 10             	add    $0x10,%esp

  devsw[CONSOLE].write = consolewrite;
80100b6a:	c7 05 ec 19 11 80 d6 	movl   $0x80100ad6,0x801119ec
80100b71:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100b74:	c7 05 e8 19 11 80 c6 	movl   $0x801009c6,0x801119e8
80100b7b:	09 10 80 
  cons.locking = 1;
80100b7e:	c7 05 d4 b5 10 80 01 	movl   $0x1,0x8010b5d4
80100b85:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
80100b88:	83 ec 08             	sub    $0x8,%esp
80100b8b:	6a 00                	push   $0x0
80100b8d:	6a 01                	push   $0x1
80100b8f:	e8 7c 1f 00 00       	call   80102b10 <ioapicenable>
80100b94:	83 c4 10             	add    $0x10,%esp
}
80100b97:	90                   	nop
80100b98:	c9                   	leave  
80100b99:	c3                   	ret    

80100b9a <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100b9a:	55                   	push   %ebp
80100b9b:	89 e5                	mov    %esp,%ebp
80100b9d:	81 ec 18 01 00 00    	sub    $0x118,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
80100ba3:	e8 d1 36 00 00       	call   80104279 <myproc>
80100ba8:	89 45 d0             	mov    %eax,-0x30(%ebp)

  begin_op();
80100bab:	e8 73 29 00 00       	call   80103523 <begin_op>

  if((ip = namei(path)) == 0){
80100bb0:	83 ec 0c             	sub    $0xc,%esp
80100bb3:	ff 75 08             	pushl  0x8(%ebp)
80100bb6:	e8 81 19 00 00       	call   8010253c <namei>
80100bbb:	83 c4 10             	add    $0x10,%esp
80100bbe:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100bc1:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100bc5:	75 1f                	jne    80100be6 <exec+0x4c>
    end_op();
80100bc7:	e8 e3 29 00 00       	call   801035af <end_op>
    cprintf("exec: fail\n");
80100bcc:	83 ec 0c             	sub    $0xc,%esp
80100bcf:	68 ca 83 10 80       	push   $0x801083ca
80100bd4:	e8 23 f8 ff ff       	call   801003fc <cprintf>
80100bd9:	83 c4 10             	add    $0x10,%esp
    return -1;
80100bdc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100be1:	e9 f1 03 00 00       	jmp    80100fd7 <exec+0x43d>
  }
  ilock(ip);
80100be6:	83 ec 0c             	sub    $0xc,%esp
80100be9:	ff 75 d8             	pushl  -0x28(%ebp)
80100bec:	e8 10 0e 00 00       	call   80101a01 <ilock>
80100bf1:	83 c4 10             	add    $0x10,%esp
  pgdir = 0;
80100bf4:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
80100bfb:	6a 34                	push   $0x34
80100bfd:	6a 00                	push   $0x0
80100bff:	8d 85 08 ff ff ff    	lea    -0xf8(%ebp),%eax
80100c05:	50                   	push   %eax
80100c06:	ff 75 d8             	pushl  -0x28(%ebp)
80100c09:	e8 df 12 00 00       	call   80101eed <readi>
80100c0e:	83 c4 10             	add    $0x10,%esp
80100c11:	83 f8 34             	cmp    $0x34,%eax
80100c14:	0f 85 66 03 00 00    	jne    80100f80 <exec+0x3e6>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100c1a:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100c20:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100c25:	0f 85 58 03 00 00    	jne    80100f83 <exec+0x3e9>
    goto bad;

  if((pgdir = setupkvm()) == 0)
80100c2b:	e8 d4 6e 00 00       	call   80107b04 <setupkvm>
80100c30:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100c33:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100c37:	0f 84 49 03 00 00    	je     80100f86 <exec+0x3ec>
    goto bad;

  // Load program into memory.
  sz = 0;
80100c3d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c44:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100c4b:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100c51:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c54:	e9 de 00 00 00       	jmp    80100d37 <exec+0x19d>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100c59:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c5c:	6a 20                	push   $0x20
80100c5e:	50                   	push   %eax
80100c5f:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100c65:	50                   	push   %eax
80100c66:	ff 75 d8             	pushl  -0x28(%ebp)
80100c69:	e8 7f 12 00 00       	call   80101eed <readi>
80100c6e:	83 c4 10             	add    $0x10,%esp
80100c71:	83 f8 20             	cmp    $0x20,%eax
80100c74:	0f 85 0f 03 00 00    	jne    80100f89 <exec+0x3ef>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100c7a:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100c80:	83 f8 01             	cmp    $0x1,%eax
80100c83:	0f 85 a0 00 00 00    	jne    80100d29 <exec+0x18f>
      continue;
    if(ph.memsz < ph.filesz)
80100c89:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100c8f:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100c95:	39 c2                	cmp    %eax,%edx
80100c97:	0f 82 ef 02 00 00    	jb     80100f8c <exec+0x3f2>
      goto bad;
    if(ph.vaddr + ph.memsz < ph.vaddr)
80100c9d:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100ca3:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100ca9:	01 c2                	add    %eax,%edx
80100cab:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100cb1:	39 c2                	cmp    %eax,%edx
80100cb3:	0f 82 d6 02 00 00    	jb     80100f8f <exec+0x3f5>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100cb9:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100cbf:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100cc5:	01 d0                	add    %edx,%eax
80100cc7:	83 ec 04             	sub    $0x4,%esp
80100cca:	50                   	push   %eax
80100ccb:	ff 75 e0             	pushl  -0x20(%ebp)
80100cce:	ff 75 d4             	pushl  -0x2c(%ebp)
80100cd1:	e8 d6 71 00 00       	call   80107eac <allocuvm>
80100cd6:	83 c4 10             	add    $0x10,%esp
80100cd9:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cdc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100ce0:	0f 84 ac 02 00 00    	je     80100f92 <exec+0x3f8>
      goto bad;
    if(ph.vaddr % PGSIZE != 0)
80100ce6:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100cec:	25 ff 0f 00 00       	and    $0xfff,%eax
80100cf1:	85 c0                	test   %eax,%eax
80100cf3:	0f 85 9c 02 00 00    	jne    80100f95 <exec+0x3fb>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100cf9:	8b 95 f8 fe ff ff    	mov    -0x108(%ebp),%edx
80100cff:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100d05:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100d0b:	83 ec 0c             	sub    $0xc,%esp
80100d0e:	52                   	push   %edx
80100d0f:	50                   	push   %eax
80100d10:	ff 75 d8             	pushl  -0x28(%ebp)
80100d13:	51                   	push   %ecx
80100d14:	ff 75 d4             	pushl  -0x2c(%ebp)
80100d17:	e8 c3 70 00 00       	call   80107ddf <loaduvm>
80100d1c:	83 c4 20             	add    $0x20,%esp
80100d1f:	85 c0                	test   %eax,%eax
80100d21:	0f 88 71 02 00 00    	js     80100f98 <exec+0x3fe>
80100d27:	eb 01                	jmp    80100d2a <exec+0x190>
      continue;
80100d29:	90                   	nop
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100d2a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100d2e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100d31:	83 c0 20             	add    $0x20,%eax
80100d34:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d37:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100d3e:	0f b7 c0             	movzwl %ax,%eax
80100d41:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80100d44:	0f 8c 0f ff ff ff    	jl     80100c59 <exec+0xbf>
      goto bad;
  }
  iunlockput(ip);
80100d4a:	83 ec 0c             	sub    $0xc,%esp
80100d4d:	ff 75 d8             	pushl  -0x28(%ebp)
80100d50:	e8 dd 0e 00 00       	call   80101c32 <iunlockput>
80100d55:	83 c4 10             	add    $0x10,%esp
  end_op();
80100d58:	e8 52 28 00 00       	call   801035af <end_op>
  ip = 0;
80100d5d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100d64:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d67:	05 ff 0f 00 00       	add    $0xfff,%eax
80100d6c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100d71:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100d74:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d77:	05 00 20 00 00       	add    $0x2000,%eax
80100d7c:	83 ec 04             	sub    $0x4,%esp
80100d7f:	50                   	push   %eax
80100d80:	ff 75 e0             	pushl  -0x20(%ebp)
80100d83:	ff 75 d4             	pushl  -0x2c(%ebp)
80100d86:	e8 21 71 00 00       	call   80107eac <allocuvm>
80100d8b:	83 c4 10             	add    $0x10,%esp
80100d8e:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d91:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d95:	0f 84 00 02 00 00    	je     80100f9b <exec+0x401>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100d9b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d9e:	2d 00 20 00 00       	sub    $0x2000,%eax
80100da3:	83 ec 08             	sub    $0x8,%esp
80100da6:	50                   	push   %eax
80100da7:	ff 75 d4             	pushl  -0x2c(%ebp)
80100daa:	e8 5f 73 00 00       	call   8010810e <clearpteu>
80100daf:	83 c4 10             	add    $0x10,%esp
  sp = sz;
80100db2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100db5:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100db8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100dbf:	e9 96 00 00 00       	jmp    80100e5a <exec+0x2c0>
    if(argc >= MAXARG)
80100dc4:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100dc8:	0f 87 d0 01 00 00    	ja     80100f9e <exec+0x404>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100dce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ddb:	01 d0                	add    %edx,%eax
80100ddd:	8b 00                	mov    (%eax),%eax
80100ddf:	83 ec 0c             	sub    $0xc,%esp
80100de2:	50                   	push   %eax
80100de3:	e8 5b 46 00 00       	call   80105443 <strlen>
80100de8:	83 c4 10             	add    $0x10,%esp
80100deb:	89 c2                	mov    %eax,%edx
80100ded:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100df0:	29 d0                	sub    %edx,%eax
80100df2:	83 e8 01             	sub    $0x1,%eax
80100df5:	83 e0 fc             	and    $0xfffffffc,%eax
80100df8:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100dfb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfe:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e05:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e08:	01 d0                	add    %edx,%eax
80100e0a:	8b 00                	mov    (%eax),%eax
80100e0c:	83 ec 0c             	sub    $0xc,%esp
80100e0f:	50                   	push   %eax
80100e10:	e8 2e 46 00 00       	call   80105443 <strlen>
80100e15:	83 c4 10             	add    $0x10,%esp
80100e18:	83 c0 01             	add    $0x1,%eax
80100e1b:	89 c1                	mov    %eax,%ecx
80100e1d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e20:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e27:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e2a:	01 d0                	add    %edx,%eax
80100e2c:	8b 00                	mov    (%eax),%eax
80100e2e:	51                   	push   %ecx
80100e2f:	50                   	push   %eax
80100e30:	ff 75 dc             	pushl  -0x24(%ebp)
80100e33:	ff 75 d4             	pushl  -0x2c(%ebp)
80100e36:	e8 7f 74 00 00       	call   801082ba <copyout>
80100e3b:	83 c4 10             	add    $0x10,%esp
80100e3e:	85 c0                	test   %eax,%eax
80100e40:	0f 88 5b 01 00 00    	js     80100fa1 <exec+0x407>
      goto bad;
    ustack[3+argc] = sp;
80100e46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e49:	8d 50 03             	lea    0x3(%eax),%edx
80100e4c:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e4f:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
  for(argc = 0; argv[argc]; argc++) {
80100e56:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100e5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e5d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e64:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e67:	01 d0                	add    %edx,%eax
80100e69:	8b 00                	mov    (%eax),%eax
80100e6b:	85 c0                	test   %eax,%eax
80100e6d:	0f 85 51 ff ff ff    	jne    80100dc4 <exec+0x22a>
  }
  ustack[3+argc] = 0;
80100e73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e76:	83 c0 03             	add    $0x3,%eax
80100e79:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100e80:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100e84:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100e8b:	ff ff ff 
  ustack[1] = argc;
80100e8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e91:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100e97:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e9a:	83 c0 01             	add    $0x1,%eax
80100e9d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ea4:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ea7:	29 d0                	sub    %edx,%eax
80100ea9:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100eaf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eb2:	83 c0 04             	add    $0x4,%eax
80100eb5:	c1 e0 02             	shl    $0x2,%eax
80100eb8:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100ebb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ebe:	83 c0 04             	add    $0x4,%eax
80100ec1:	c1 e0 02             	shl    $0x2,%eax
80100ec4:	50                   	push   %eax
80100ec5:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100ecb:	50                   	push   %eax
80100ecc:	ff 75 dc             	pushl  -0x24(%ebp)
80100ecf:	ff 75 d4             	pushl  -0x2c(%ebp)
80100ed2:	e8 e3 73 00 00       	call   801082ba <copyout>
80100ed7:	83 c4 10             	add    $0x10,%esp
80100eda:	85 c0                	test   %eax,%eax
80100edc:	0f 88 c2 00 00 00    	js     80100fa4 <exec+0x40a>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100ee2:	8b 45 08             	mov    0x8(%ebp),%eax
80100ee5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100ee8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100eeb:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100eee:	eb 17                	jmp    80100f07 <exec+0x36d>
    if(*s == '/')
80100ef0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ef3:	0f b6 00             	movzbl (%eax),%eax
80100ef6:	3c 2f                	cmp    $0x2f,%al
80100ef8:	75 09                	jne    80100f03 <exec+0x369>
      last = s+1;
80100efa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100efd:	83 c0 01             	add    $0x1,%eax
80100f00:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(last=s=path; *s; s++)
80100f03:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100f07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f0a:	0f b6 00             	movzbl (%eax),%eax
80100f0d:	84 c0                	test   %al,%al
80100f0f:	75 df                	jne    80100ef0 <exec+0x356>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100f11:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f14:	83 c0 6c             	add    $0x6c,%eax
80100f17:	83 ec 04             	sub    $0x4,%esp
80100f1a:	6a 10                	push   $0x10
80100f1c:	ff 75 f0             	pushl  -0x10(%ebp)
80100f1f:	50                   	push   %eax
80100f20:	e8 d4 44 00 00       	call   801053f9 <safestrcpy>
80100f25:	83 c4 10             	add    $0x10,%esp

  // Commit to the user image.
  oldpgdir = curproc->pgdir;
80100f28:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f2b:	8b 40 04             	mov    0x4(%eax),%eax
80100f2e:	89 45 cc             	mov    %eax,-0x34(%ebp)
  curproc->pgdir = pgdir;
80100f31:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f34:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100f37:	89 50 04             	mov    %edx,0x4(%eax)
  curproc->sz = sz;
80100f3a:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f3d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f40:	89 10                	mov    %edx,(%eax)
  curproc->tf->eip = elf.entry;  // main
80100f42:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f45:	8b 40 18             	mov    0x18(%eax),%eax
80100f48:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100f4e:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100f51:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f54:	8b 40 18             	mov    0x18(%eax),%eax
80100f57:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100f5a:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(curproc);
80100f5d:	83 ec 0c             	sub    $0xc,%esp
80100f60:	ff 75 d0             	pushl  -0x30(%ebp)
80100f63:	e8 66 6c 00 00       	call   80107bce <switchuvm>
80100f68:	83 c4 10             	add    $0x10,%esp
  freevm(oldpgdir);
80100f6b:	83 ec 0c             	sub    $0xc,%esp
80100f6e:	ff 75 cc             	pushl  -0x34(%ebp)
80100f71:	e8 ff 70 00 00       	call   80108075 <freevm>
80100f76:	83 c4 10             	add    $0x10,%esp
  return 0;
80100f79:	b8 00 00 00 00       	mov    $0x0,%eax
80100f7e:	eb 57                	jmp    80100fd7 <exec+0x43d>
    goto bad;
80100f80:	90                   	nop
80100f81:	eb 22                	jmp    80100fa5 <exec+0x40b>
    goto bad;
80100f83:	90                   	nop
80100f84:	eb 1f                	jmp    80100fa5 <exec+0x40b>
    goto bad;
80100f86:	90                   	nop
80100f87:	eb 1c                	jmp    80100fa5 <exec+0x40b>
      goto bad;
80100f89:	90                   	nop
80100f8a:	eb 19                	jmp    80100fa5 <exec+0x40b>
      goto bad;
80100f8c:	90                   	nop
80100f8d:	eb 16                	jmp    80100fa5 <exec+0x40b>
      goto bad;
80100f8f:	90                   	nop
80100f90:	eb 13                	jmp    80100fa5 <exec+0x40b>
      goto bad;
80100f92:	90                   	nop
80100f93:	eb 10                	jmp    80100fa5 <exec+0x40b>
      goto bad;
80100f95:	90                   	nop
80100f96:	eb 0d                	jmp    80100fa5 <exec+0x40b>
      goto bad;
80100f98:	90                   	nop
80100f99:	eb 0a                	jmp    80100fa5 <exec+0x40b>
    goto bad;
80100f9b:	90                   	nop
80100f9c:	eb 07                	jmp    80100fa5 <exec+0x40b>
      goto bad;
80100f9e:	90                   	nop
80100f9f:	eb 04                	jmp    80100fa5 <exec+0x40b>
      goto bad;
80100fa1:	90                   	nop
80100fa2:	eb 01                	jmp    80100fa5 <exec+0x40b>
    goto bad;
80100fa4:	90                   	nop

 bad:
  if(pgdir)
80100fa5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100fa9:	74 0e                	je     80100fb9 <exec+0x41f>
    freevm(pgdir);
80100fab:	83 ec 0c             	sub    $0xc,%esp
80100fae:	ff 75 d4             	pushl  -0x2c(%ebp)
80100fb1:	e8 bf 70 00 00       	call   80108075 <freevm>
80100fb6:	83 c4 10             	add    $0x10,%esp
  if(ip){
80100fb9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100fbd:	74 13                	je     80100fd2 <exec+0x438>
    iunlockput(ip);
80100fbf:	83 ec 0c             	sub    $0xc,%esp
80100fc2:	ff 75 d8             	pushl  -0x28(%ebp)
80100fc5:	e8 68 0c 00 00       	call   80101c32 <iunlockput>
80100fca:	83 c4 10             	add    $0x10,%esp
    end_op();
80100fcd:	e8 dd 25 00 00       	call   801035af <end_op>
  }
  return -1;
80100fd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100fd7:	c9                   	leave  
80100fd8:	c3                   	ret    

80100fd9 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100fd9:	55                   	push   %ebp
80100fda:	89 e5                	mov    %esp,%ebp
80100fdc:	83 ec 08             	sub    $0x8,%esp
  initlock(&ftable.lock, "ftable");
80100fdf:	83 ec 08             	sub    $0x8,%esp
80100fe2:	68 d6 83 10 80       	push   $0x801083d6
80100fe7:	68 40 10 11 80       	push   $0x80111040
80100fec:	e8 5c 3f 00 00       	call   80104f4d <initlock>
80100ff1:	83 c4 10             	add    $0x10,%esp
}
80100ff4:	90                   	nop
80100ff5:	c9                   	leave  
80100ff6:	c3                   	ret    

80100ff7 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100ff7:	55                   	push   %ebp
80100ff8:	89 e5                	mov    %esp,%ebp
80100ffa:	83 ec 18             	sub    $0x18,%esp
  struct file *f;

  acquire(&ftable.lock);
80100ffd:	83 ec 0c             	sub    $0xc,%esp
80101000:	68 40 10 11 80       	push   $0x80111040
80101005:	e8 65 3f 00 00       	call   80104f6f <acquire>
8010100a:	83 c4 10             	add    $0x10,%esp
  for(f = ftable.file; f < ftable.file + NFILE; f++){
8010100d:	c7 45 f4 74 10 11 80 	movl   $0x80111074,-0xc(%ebp)
80101014:	eb 2d                	jmp    80101043 <filealloc+0x4c>
    if(f->ref == 0){
80101016:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101019:	8b 40 04             	mov    0x4(%eax),%eax
8010101c:	85 c0                	test   %eax,%eax
8010101e:	75 1f                	jne    8010103f <filealloc+0x48>
      f->ref = 1;
80101020:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101023:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
8010102a:	83 ec 0c             	sub    $0xc,%esp
8010102d:	68 40 10 11 80       	push   $0x80111040
80101032:	e8 a6 3f 00 00       	call   80104fdd <release>
80101037:	83 c4 10             	add    $0x10,%esp
      return f;
8010103a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010103d:	eb 23                	jmp    80101062 <filealloc+0x6b>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
8010103f:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80101043:	b8 d4 19 11 80       	mov    $0x801119d4,%eax
80101048:	39 45 f4             	cmp    %eax,-0xc(%ebp)
8010104b:	72 c9                	jb     80101016 <filealloc+0x1f>
    }
  }
  release(&ftable.lock);
8010104d:	83 ec 0c             	sub    $0xc,%esp
80101050:	68 40 10 11 80       	push   $0x80111040
80101055:	e8 83 3f 00 00       	call   80104fdd <release>
8010105a:	83 c4 10             	add    $0x10,%esp
  return 0;
8010105d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101062:	c9                   	leave  
80101063:	c3                   	ret    

80101064 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80101064:	55                   	push   %ebp
80101065:	89 e5                	mov    %esp,%ebp
80101067:	83 ec 08             	sub    $0x8,%esp
  acquire(&ftable.lock);
8010106a:	83 ec 0c             	sub    $0xc,%esp
8010106d:	68 40 10 11 80       	push   $0x80111040
80101072:	e8 f8 3e 00 00       	call   80104f6f <acquire>
80101077:	83 c4 10             	add    $0x10,%esp
  if(f->ref < 1)
8010107a:	8b 45 08             	mov    0x8(%ebp),%eax
8010107d:	8b 40 04             	mov    0x4(%eax),%eax
80101080:	85 c0                	test   %eax,%eax
80101082:	7f 0d                	jg     80101091 <filedup+0x2d>
    panic("filedup");
80101084:	83 ec 0c             	sub    $0xc,%esp
80101087:	68 dd 83 10 80       	push   $0x801083dd
8010108c:	e8 0b f5 ff ff       	call   8010059c <panic>
  f->ref++;
80101091:	8b 45 08             	mov    0x8(%ebp),%eax
80101094:	8b 40 04             	mov    0x4(%eax),%eax
80101097:	8d 50 01             	lea    0x1(%eax),%edx
8010109a:	8b 45 08             	mov    0x8(%ebp),%eax
8010109d:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801010a0:	83 ec 0c             	sub    $0xc,%esp
801010a3:	68 40 10 11 80       	push   $0x80111040
801010a8:	e8 30 3f 00 00       	call   80104fdd <release>
801010ad:	83 c4 10             	add    $0x10,%esp
  return f;
801010b0:	8b 45 08             	mov    0x8(%ebp),%eax
}
801010b3:	c9                   	leave  
801010b4:	c3                   	ret    

801010b5 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
801010b5:	55                   	push   %ebp
801010b6:	89 e5                	mov    %esp,%ebp
801010b8:	83 ec 28             	sub    $0x28,%esp
  struct file ff;

  acquire(&ftable.lock);
801010bb:	83 ec 0c             	sub    $0xc,%esp
801010be:	68 40 10 11 80       	push   $0x80111040
801010c3:	e8 a7 3e 00 00       	call   80104f6f <acquire>
801010c8:	83 c4 10             	add    $0x10,%esp
  if(f->ref < 1)
801010cb:	8b 45 08             	mov    0x8(%ebp),%eax
801010ce:	8b 40 04             	mov    0x4(%eax),%eax
801010d1:	85 c0                	test   %eax,%eax
801010d3:	7f 0d                	jg     801010e2 <fileclose+0x2d>
    panic("fileclose");
801010d5:	83 ec 0c             	sub    $0xc,%esp
801010d8:	68 e5 83 10 80       	push   $0x801083e5
801010dd:	e8 ba f4 ff ff       	call   8010059c <panic>
  if(--f->ref > 0){
801010e2:	8b 45 08             	mov    0x8(%ebp),%eax
801010e5:	8b 40 04             	mov    0x4(%eax),%eax
801010e8:	8d 50 ff             	lea    -0x1(%eax),%edx
801010eb:	8b 45 08             	mov    0x8(%ebp),%eax
801010ee:	89 50 04             	mov    %edx,0x4(%eax)
801010f1:	8b 45 08             	mov    0x8(%ebp),%eax
801010f4:	8b 40 04             	mov    0x4(%eax),%eax
801010f7:	85 c0                	test   %eax,%eax
801010f9:	7e 15                	jle    80101110 <fileclose+0x5b>
    release(&ftable.lock);
801010fb:	83 ec 0c             	sub    $0xc,%esp
801010fe:	68 40 10 11 80       	push   $0x80111040
80101103:	e8 d5 3e 00 00       	call   80104fdd <release>
80101108:	83 c4 10             	add    $0x10,%esp
8010110b:	e9 8b 00 00 00       	jmp    8010119b <fileclose+0xe6>
    return;
  }
  ff = *f;
80101110:	8b 45 08             	mov    0x8(%ebp),%eax
80101113:	8b 10                	mov    (%eax),%edx
80101115:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101118:	8b 50 04             	mov    0x4(%eax),%edx
8010111b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010111e:	8b 50 08             	mov    0x8(%eax),%edx
80101121:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101124:	8b 50 0c             	mov    0xc(%eax),%edx
80101127:	89 55 ec             	mov    %edx,-0x14(%ebp)
8010112a:	8b 50 10             	mov    0x10(%eax),%edx
8010112d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101130:	8b 40 14             	mov    0x14(%eax),%eax
80101133:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101136:	8b 45 08             	mov    0x8(%ebp),%eax
80101139:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101140:	8b 45 08             	mov    0x8(%ebp),%eax
80101143:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101149:	83 ec 0c             	sub    $0xc,%esp
8010114c:	68 40 10 11 80       	push   $0x80111040
80101151:	e8 87 3e 00 00       	call   80104fdd <release>
80101156:	83 c4 10             	add    $0x10,%esp

  if(ff.type == FD_PIPE)
80101159:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010115c:	83 f8 01             	cmp    $0x1,%eax
8010115f:	75 19                	jne    8010117a <fileclose+0xc5>
    pipeclose(ff.pipe, ff.writable);
80101161:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101165:	0f be d0             	movsbl %al,%edx
80101168:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010116b:	83 ec 08             	sub    $0x8,%esp
8010116e:	52                   	push   %edx
8010116f:	50                   	push   %eax
80101170:	e8 8e 2d 00 00       	call   80103f03 <pipeclose>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb 21                	jmp    8010119b <fileclose+0xe6>
  else if(ff.type == FD_INODE){
8010117a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010117d:	83 f8 02             	cmp    $0x2,%eax
80101180:	75 19                	jne    8010119b <fileclose+0xe6>
    begin_op();
80101182:	e8 9c 23 00 00       	call   80103523 <begin_op>
    iput(ff.ip);
80101187:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010118a:	83 ec 0c             	sub    $0xc,%esp
8010118d:	50                   	push   %eax
8010118e:	e8 cf 09 00 00       	call   80101b62 <iput>
80101193:	83 c4 10             	add    $0x10,%esp
    end_op();
80101196:	e8 14 24 00 00       	call   801035af <end_op>
  }
}
8010119b:	c9                   	leave  
8010119c:	c3                   	ret    

8010119d <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
8010119d:	55                   	push   %ebp
8010119e:	89 e5                	mov    %esp,%ebp
801011a0:	83 ec 08             	sub    $0x8,%esp
  if(f->type == FD_INODE){
801011a3:	8b 45 08             	mov    0x8(%ebp),%eax
801011a6:	8b 00                	mov    (%eax),%eax
801011a8:	83 f8 02             	cmp    $0x2,%eax
801011ab:	75 40                	jne    801011ed <filestat+0x50>
    ilock(f->ip);
801011ad:	8b 45 08             	mov    0x8(%ebp),%eax
801011b0:	8b 40 10             	mov    0x10(%eax),%eax
801011b3:	83 ec 0c             	sub    $0xc,%esp
801011b6:	50                   	push   %eax
801011b7:	e8 45 08 00 00       	call   80101a01 <ilock>
801011bc:	83 c4 10             	add    $0x10,%esp
    stati(f->ip, st);
801011bf:	8b 45 08             	mov    0x8(%ebp),%eax
801011c2:	8b 40 10             	mov    0x10(%eax),%eax
801011c5:	83 ec 08             	sub    $0x8,%esp
801011c8:	ff 75 0c             	pushl  0xc(%ebp)
801011cb:	50                   	push   %eax
801011cc:	e8 d6 0c 00 00       	call   80101ea7 <stati>
801011d1:	83 c4 10             	add    $0x10,%esp
    iunlock(f->ip);
801011d4:	8b 45 08             	mov    0x8(%ebp),%eax
801011d7:	8b 40 10             	mov    0x10(%eax),%eax
801011da:	83 ec 0c             	sub    $0xc,%esp
801011dd:	50                   	push   %eax
801011de:	e8 31 09 00 00       	call   80101b14 <iunlock>
801011e3:	83 c4 10             	add    $0x10,%esp
    return 0;
801011e6:	b8 00 00 00 00       	mov    $0x0,%eax
801011eb:	eb 05                	jmp    801011f2 <filestat+0x55>
  }
  return -1;
801011ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801011f2:	c9                   	leave  
801011f3:	c3                   	ret    

801011f4 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801011f4:	55                   	push   %ebp
801011f5:	89 e5                	mov    %esp,%ebp
801011f7:	83 ec 18             	sub    $0x18,%esp
  int r;

  if(f->readable == 0)
801011fa:	8b 45 08             	mov    0x8(%ebp),%eax
801011fd:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101201:	84 c0                	test   %al,%al
80101203:	75 0a                	jne    8010120f <fileread+0x1b>
    return -1;
80101205:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010120a:	e9 9b 00 00 00       	jmp    801012aa <fileread+0xb6>
  if(f->type == FD_PIPE)
8010120f:	8b 45 08             	mov    0x8(%ebp),%eax
80101212:	8b 00                	mov    (%eax),%eax
80101214:	83 f8 01             	cmp    $0x1,%eax
80101217:	75 1a                	jne    80101233 <fileread+0x3f>
    return piperead(f->pipe, addr, n);
80101219:	8b 45 08             	mov    0x8(%ebp),%eax
8010121c:	8b 40 0c             	mov    0xc(%eax),%eax
8010121f:	83 ec 04             	sub    $0x4,%esp
80101222:	ff 75 10             	pushl  0x10(%ebp)
80101225:	ff 75 0c             	pushl  0xc(%ebp)
80101228:	50                   	push   %eax
80101229:	e8 81 2e 00 00       	call   801040af <piperead>
8010122e:	83 c4 10             	add    $0x10,%esp
80101231:	eb 77                	jmp    801012aa <fileread+0xb6>
  if(f->type == FD_INODE){
80101233:	8b 45 08             	mov    0x8(%ebp),%eax
80101236:	8b 00                	mov    (%eax),%eax
80101238:	83 f8 02             	cmp    $0x2,%eax
8010123b:	75 60                	jne    8010129d <fileread+0xa9>
    ilock(f->ip);
8010123d:	8b 45 08             	mov    0x8(%ebp),%eax
80101240:	8b 40 10             	mov    0x10(%eax),%eax
80101243:	83 ec 0c             	sub    $0xc,%esp
80101246:	50                   	push   %eax
80101247:	e8 b5 07 00 00       	call   80101a01 <ilock>
8010124c:	83 c4 10             	add    $0x10,%esp
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010124f:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101252:	8b 45 08             	mov    0x8(%ebp),%eax
80101255:	8b 50 14             	mov    0x14(%eax),%edx
80101258:	8b 45 08             	mov    0x8(%ebp),%eax
8010125b:	8b 40 10             	mov    0x10(%eax),%eax
8010125e:	51                   	push   %ecx
8010125f:	52                   	push   %edx
80101260:	ff 75 0c             	pushl  0xc(%ebp)
80101263:	50                   	push   %eax
80101264:	e8 84 0c 00 00       	call   80101eed <readi>
80101269:	83 c4 10             	add    $0x10,%esp
8010126c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010126f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101273:	7e 11                	jle    80101286 <fileread+0x92>
      f->off += r;
80101275:	8b 45 08             	mov    0x8(%ebp),%eax
80101278:	8b 50 14             	mov    0x14(%eax),%edx
8010127b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010127e:	01 c2                	add    %eax,%edx
80101280:	8b 45 08             	mov    0x8(%ebp),%eax
80101283:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
80101286:	8b 45 08             	mov    0x8(%ebp),%eax
80101289:	8b 40 10             	mov    0x10(%eax),%eax
8010128c:	83 ec 0c             	sub    $0xc,%esp
8010128f:	50                   	push   %eax
80101290:	e8 7f 08 00 00       	call   80101b14 <iunlock>
80101295:	83 c4 10             	add    $0x10,%esp
    return r;
80101298:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010129b:	eb 0d                	jmp    801012aa <fileread+0xb6>
  }
  panic("fileread");
8010129d:	83 ec 0c             	sub    $0xc,%esp
801012a0:	68 ef 83 10 80       	push   $0x801083ef
801012a5:	e8 f2 f2 ff ff       	call   8010059c <panic>
}
801012aa:	c9                   	leave  
801012ab:	c3                   	ret    

801012ac <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801012ac:	55                   	push   %ebp
801012ad:	89 e5                	mov    %esp,%ebp
801012af:	53                   	push   %ebx
801012b0:	83 ec 14             	sub    $0x14,%esp
  int r;

  if(f->writable == 0)
801012b3:	8b 45 08             	mov    0x8(%ebp),%eax
801012b6:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801012ba:	84 c0                	test   %al,%al
801012bc:	75 0a                	jne    801012c8 <filewrite+0x1c>
    return -1;
801012be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012c3:	e9 1b 01 00 00       	jmp    801013e3 <filewrite+0x137>
  if(f->type == FD_PIPE)
801012c8:	8b 45 08             	mov    0x8(%ebp),%eax
801012cb:	8b 00                	mov    (%eax),%eax
801012cd:	83 f8 01             	cmp    $0x1,%eax
801012d0:	75 1d                	jne    801012ef <filewrite+0x43>
    return pipewrite(f->pipe, addr, n);
801012d2:	8b 45 08             	mov    0x8(%ebp),%eax
801012d5:	8b 40 0c             	mov    0xc(%eax),%eax
801012d8:	83 ec 04             	sub    $0x4,%esp
801012db:	ff 75 10             	pushl  0x10(%ebp)
801012de:	ff 75 0c             	pushl  0xc(%ebp)
801012e1:	50                   	push   %eax
801012e2:	e8 c6 2c 00 00       	call   80103fad <pipewrite>
801012e7:	83 c4 10             	add    $0x10,%esp
801012ea:	e9 f4 00 00 00       	jmp    801013e3 <filewrite+0x137>
  if(f->type == FD_INODE){
801012ef:	8b 45 08             	mov    0x8(%ebp),%eax
801012f2:	8b 00                	mov    (%eax),%eax
801012f4:	83 f8 02             	cmp    $0x2,%eax
801012f7:	0f 85 d9 00 00 00    	jne    801013d6 <filewrite+0x12a>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
801012fd:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101304:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
8010130b:	e9 a3 00 00 00       	jmp    801013b3 <filewrite+0x107>
      int n1 = n - i;
80101310:	8b 45 10             	mov    0x10(%ebp),%eax
80101313:	2b 45 f4             	sub    -0xc(%ebp),%eax
80101316:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101319:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010131c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010131f:	7e 06                	jle    80101327 <filewrite+0x7b>
        n1 = max;
80101321:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101324:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101327:	e8 f7 21 00 00       	call   80103523 <begin_op>
      ilock(f->ip);
8010132c:	8b 45 08             	mov    0x8(%ebp),%eax
8010132f:	8b 40 10             	mov    0x10(%eax),%eax
80101332:	83 ec 0c             	sub    $0xc,%esp
80101335:	50                   	push   %eax
80101336:	e8 c6 06 00 00       	call   80101a01 <ilock>
8010133b:	83 c4 10             	add    $0x10,%esp
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
8010133e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101341:	8b 45 08             	mov    0x8(%ebp),%eax
80101344:	8b 50 14             	mov    0x14(%eax),%edx
80101347:	8b 5d f4             	mov    -0xc(%ebp),%ebx
8010134a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010134d:	01 c3                	add    %eax,%ebx
8010134f:	8b 45 08             	mov    0x8(%ebp),%eax
80101352:	8b 40 10             	mov    0x10(%eax),%eax
80101355:	51                   	push   %ecx
80101356:	52                   	push   %edx
80101357:	53                   	push   %ebx
80101358:	50                   	push   %eax
80101359:	e8 e6 0c 00 00       	call   80102044 <writei>
8010135e:	83 c4 10             	add    $0x10,%esp
80101361:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101364:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101368:	7e 11                	jle    8010137b <filewrite+0xcf>
        f->off += r;
8010136a:	8b 45 08             	mov    0x8(%ebp),%eax
8010136d:	8b 50 14             	mov    0x14(%eax),%edx
80101370:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101373:	01 c2                	add    %eax,%edx
80101375:	8b 45 08             	mov    0x8(%ebp),%eax
80101378:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
8010137b:	8b 45 08             	mov    0x8(%ebp),%eax
8010137e:	8b 40 10             	mov    0x10(%eax),%eax
80101381:	83 ec 0c             	sub    $0xc,%esp
80101384:	50                   	push   %eax
80101385:	e8 8a 07 00 00       	call   80101b14 <iunlock>
8010138a:	83 c4 10             	add    $0x10,%esp
      end_op();
8010138d:	e8 1d 22 00 00       	call   801035af <end_op>

      if(r < 0)
80101392:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101396:	78 29                	js     801013c1 <filewrite+0x115>
        break;
      if(r != n1)
80101398:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010139b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010139e:	74 0d                	je     801013ad <filewrite+0x101>
        panic("short filewrite");
801013a0:	83 ec 0c             	sub    $0xc,%esp
801013a3:	68 f8 83 10 80       	push   $0x801083f8
801013a8:	e8 ef f1 ff ff       	call   8010059c <panic>
      i += r;
801013ad:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013b0:	01 45 f4             	add    %eax,-0xc(%ebp)
    while(i < n){
801013b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b6:	3b 45 10             	cmp    0x10(%ebp),%eax
801013b9:	0f 8c 51 ff ff ff    	jl     80101310 <filewrite+0x64>
801013bf:	eb 01                	jmp    801013c2 <filewrite+0x116>
        break;
801013c1:	90                   	nop
    }
    return i == n ? n : -1;
801013c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c5:	3b 45 10             	cmp    0x10(%ebp),%eax
801013c8:	75 05                	jne    801013cf <filewrite+0x123>
801013ca:	8b 45 10             	mov    0x10(%ebp),%eax
801013cd:	eb 14                	jmp    801013e3 <filewrite+0x137>
801013cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801013d4:	eb 0d                	jmp    801013e3 <filewrite+0x137>
  }
  panic("filewrite");
801013d6:	83 ec 0c             	sub    $0xc,%esp
801013d9:	68 08 84 10 80       	push   $0x80108408
801013de:	e8 b9 f1 ff ff       	call   8010059c <panic>
}
801013e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801013e6:	c9                   	leave  
801013e7:	c3                   	ret    

801013e8 <readsb>:
struct superblock sb; 

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801013e8:	55                   	push   %ebp
801013e9:	89 e5                	mov    %esp,%ebp
801013eb:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;

  bp = bread(dev, 1);
801013ee:	8b 45 08             	mov    0x8(%ebp),%eax
801013f1:	83 ec 08             	sub    $0x8,%esp
801013f4:	6a 01                	push   $0x1
801013f6:	50                   	push   %eax
801013f7:	e8 d2 ed ff ff       	call   801001ce <bread>
801013fc:	83 c4 10             	add    $0x10,%esp
801013ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101405:	83 c0 5c             	add    $0x5c,%eax
80101408:	83 ec 04             	sub    $0x4,%esp
8010140b:	6a 1c                	push   $0x1c
8010140d:	50                   	push   %eax
8010140e:	ff 75 0c             	pushl  0xc(%ebp)
80101411:	e8 9f 3e 00 00       	call   801052b5 <memmove>
80101416:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
80101419:	83 ec 0c             	sub    $0xc,%esp
8010141c:	ff 75 f4             	pushl  -0xc(%ebp)
8010141f:	e8 2c ee ff ff       	call   80100250 <brelse>
80101424:	83 c4 10             	add    $0x10,%esp
}
80101427:	90                   	nop
80101428:	c9                   	leave  
80101429:	c3                   	ret    

8010142a <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
8010142a:	55                   	push   %ebp
8010142b:	89 e5                	mov    %esp,%ebp
8010142d:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;

  bp = bread(dev, bno);
80101430:	8b 55 0c             	mov    0xc(%ebp),%edx
80101433:	8b 45 08             	mov    0x8(%ebp),%eax
80101436:	83 ec 08             	sub    $0x8,%esp
80101439:	52                   	push   %edx
8010143a:	50                   	push   %eax
8010143b:	e8 8e ed ff ff       	call   801001ce <bread>
80101440:	83 c4 10             	add    $0x10,%esp
80101443:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101446:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101449:	83 c0 5c             	add    $0x5c,%eax
8010144c:	83 ec 04             	sub    $0x4,%esp
8010144f:	68 00 02 00 00       	push   $0x200
80101454:	6a 00                	push   $0x0
80101456:	50                   	push   %eax
80101457:	e8 9a 3d 00 00       	call   801051f6 <memset>
8010145c:	83 c4 10             	add    $0x10,%esp
  log_write(bp);
8010145f:	83 ec 0c             	sub    $0xc,%esp
80101462:	ff 75 f4             	pushl  -0xc(%ebp)
80101465:	e8 f1 22 00 00       	call   8010375b <log_write>
8010146a:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
8010146d:	83 ec 0c             	sub    $0xc,%esp
80101470:	ff 75 f4             	pushl  -0xc(%ebp)
80101473:	e8 d8 ed ff ff       	call   80100250 <brelse>
80101478:	83 c4 10             	add    $0x10,%esp
}
8010147b:	90                   	nop
8010147c:	c9                   	leave  
8010147d:	c3                   	ret    

8010147e <balloc>:
// Blocks.

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
8010147e:	55                   	push   %ebp
8010147f:	89 e5                	mov    %esp,%ebp
80101481:	83 ec 18             	sub    $0x18,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
80101484:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
8010148b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101492:	e9 13 01 00 00       	jmp    801015aa <balloc+0x12c>
    bp = bread(dev, BBLOCK(b, sb));
80101497:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010149a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801014a0:	85 c0                	test   %eax,%eax
801014a2:	0f 48 c2             	cmovs  %edx,%eax
801014a5:	c1 f8 0c             	sar    $0xc,%eax
801014a8:	89 c2                	mov    %eax,%edx
801014aa:	a1 58 1a 11 80       	mov    0x80111a58,%eax
801014af:	01 d0                	add    %edx,%eax
801014b1:	83 ec 08             	sub    $0x8,%esp
801014b4:	50                   	push   %eax
801014b5:	ff 75 08             	pushl  0x8(%ebp)
801014b8:	e8 11 ed ff ff       	call   801001ce <bread>
801014bd:	83 c4 10             	add    $0x10,%esp
801014c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014c3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801014ca:	e9 a6 00 00 00       	jmp    80101575 <balloc+0xf7>
      m = 1 << (bi % 8);
801014cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014d2:	99                   	cltd   
801014d3:	c1 ea 1d             	shr    $0x1d,%edx
801014d6:	01 d0                	add    %edx,%eax
801014d8:	83 e0 07             	and    $0x7,%eax
801014db:	29 d0                	sub    %edx,%eax
801014dd:	ba 01 00 00 00       	mov    $0x1,%edx
801014e2:	89 c1                	mov    %eax,%ecx
801014e4:	d3 e2                	shl    %cl,%edx
801014e6:	89 d0                	mov    %edx,%eax
801014e8:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801014eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014ee:	8d 50 07             	lea    0x7(%eax),%edx
801014f1:	85 c0                	test   %eax,%eax
801014f3:	0f 48 c2             	cmovs  %edx,%eax
801014f6:	c1 f8 03             	sar    $0x3,%eax
801014f9:	89 c2                	mov    %eax,%edx
801014fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014fe:	0f b6 44 10 5c       	movzbl 0x5c(%eax,%edx,1),%eax
80101503:	0f b6 c0             	movzbl %al,%eax
80101506:	23 45 e8             	and    -0x18(%ebp),%eax
80101509:	85 c0                	test   %eax,%eax
8010150b:	75 64                	jne    80101571 <balloc+0xf3>
        bp->data[bi/8] |= m;  // Mark block in use.
8010150d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101510:	8d 50 07             	lea    0x7(%eax),%edx
80101513:	85 c0                	test   %eax,%eax
80101515:	0f 48 c2             	cmovs  %edx,%eax
80101518:	c1 f8 03             	sar    $0x3,%eax
8010151b:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010151e:	0f b6 54 02 5c       	movzbl 0x5c(%edx,%eax,1),%edx
80101523:	89 d1                	mov    %edx,%ecx
80101525:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101528:	09 ca                	or     %ecx,%edx
8010152a:	89 d1                	mov    %edx,%ecx
8010152c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010152f:	88 4c 02 5c          	mov    %cl,0x5c(%edx,%eax,1)
        log_write(bp);
80101533:	83 ec 0c             	sub    $0xc,%esp
80101536:	ff 75 ec             	pushl  -0x14(%ebp)
80101539:	e8 1d 22 00 00       	call   8010375b <log_write>
8010153e:	83 c4 10             	add    $0x10,%esp
        brelse(bp);
80101541:	83 ec 0c             	sub    $0xc,%esp
80101544:	ff 75 ec             	pushl  -0x14(%ebp)
80101547:	e8 04 ed ff ff       	call   80100250 <brelse>
8010154c:	83 c4 10             	add    $0x10,%esp
        bzero(dev, b + bi);
8010154f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101552:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101555:	01 c2                	add    %eax,%edx
80101557:	8b 45 08             	mov    0x8(%ebp),%eax
8010155a:	83 ec 08             	sub    $0x8,%esp
8010155d:	52                   	push   %edx
8010155e:	50                   	push   %eax
8010155f:	e8 c6 fe ff ff       	call   8010142a <bzero>
80101564:	83 c4 10             	add    $0x10,%esp
        return b + bi;
80101567:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010156a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010156d:	01 d0                	add    %edx,%eax
8010156f:	eb 57                	jmp    801015c8 <balloc+0x14a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101571:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101575:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
8010157c:	7f 17                	jg     80101595 <balloc+0x117>
8010157e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101581:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101584:	01 d0                	add    %edx,%eax
80101586:	89 c2                	mov    %eax,%edx
80101588:	a1 40 1a 11 80       	mov    0x80111a40,%eax
8010158d:	39 c2                	cmp    %eax,%edx
8010158f:	0f 82 3a ff ff ff    	jb     801014cf <balloc+0x51>
      }
    }
    brelse(bp);
80101595:	83 ec 0c             	sub    $0xc,%esp
80101598:	ff 75 ec             	pushl  -0x14(%ebp)
8010159b:	e8 b0 ec ff ff       	call   80100250 <brelse>
801015a0:	83 c4 10             	add    $0x10,%esp
  for(b = 0; b < sb.size; b += BPB){
801015a3:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801015aa:	8b 15 40 1a 11 80    	mov    0x80111a40,%edx
801015b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015b3:	39 c2                	cmp    %eax,%edx
801015b5:	0f 87 dc fe ff ff    	ja     80101497 <balloc+0x19>
  }
  panic("balloc: out of blocks");
801015bb:	83 ec 0c             	sub    $0xc,%esp
801015be:	68 14 84 10 80       	push   $0x80108414
801015c3:	e8 d4 ef ff ff       	call   8010059c <panic>
}
801015c8:	c9                   	leave  
801015c9:	c3                   	ret    

801015ca <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801015ca:	55                   	push   %ebp
801015cb:	89 e5                	mov    %esp,%ebp
801015cd:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
801015d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801015d3:	c1 e8 0c             	shr    $0xc,%eax
801015d6:	89 c2                	mov    %eax,%edx
801015d8:	a1 58 1a 11 80       	mov    0x80111a58,%eax
801015dd:	01 c2                	add    %eax,%edx
801015df:	8b 45 08             	mov    0x8(%ebp),%eax
801015e2:	83 ec 08             	sub    $0x8,%esp
801015e5:	52                   	push   %edx
801015e6:	50                   	push   %eax
801015e7:	e8 e2 eb ff ff       	call   801001ce <bread>
801015ec:	83 c4 10             	add    $0x10,%esp
801015ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
801015f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801015f5:	25 ff 0f 00 00       	and    $0xfff,%eax
801015fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
801015fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101600:	99                   	cltd   
80101601:	c1 ea 1d             	shr    $0x1d,%edx
80101604:	01 d0                	add    %edx,%eax
80101606:	83 e0 07             	and    $0x7,%eax
80101609:	29 d0                	sub    %edx,%eax
8010160b:	ba 01 00 00 00       	mov    $0x1,%edx
80101610:	89 c1                	mov    %eax,%ecx
80101612:	d3 e2                	shl    %cl,%edx
80101614:	89 d0                	mov    %edx,%eax
80101616:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101619:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010161c:	8d 50 07             	lea    0x7(%eax),%edx
8010161f:	85 c0                	test   %eax,%eax
80101621:	0f 48 c2             	cmovs  %edx,%eax
80101624:	c1 f8 03             	sar    $0x3,%eax
80101627:	89 c2                	mov    %eax,%edx
80101629:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010162c:	0f b6 44 10 5c       	movzbl 0x5c(%eax,%edx,1),%eax
80101631:	0f b6 c0             	movzbl %al,%eax
80101634:	23 45 ec             	and    -0x14(%ebp),%eax
80101637:	85 c0                	test   %eax,%eax
80101639:	75 0d                	jne    80101648 <bfree+0x7e>
    panic("freeing free block");
8010163b:	83 ec 0c             	sub    $0xc,%esp
8010163e:	68 2a 84 10 80       	push   $0x8010842a
80101643:	e8 54 ef ff ff       	call   8010059c <panic>
  bp->data[bi/8] &= ~m;
80101648:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010164b:	8d 50 07             	lea    0x7(%eax),%edx
8010164e:	85 c0                	test   %eax,%eax
80101650:	0f 48 c2             	cmovs  %edx,%eax
80101653:	c1 f8 03             	sar    $0x3,%eax
80101656:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101659:	0f b6 54 02 5c       	movzbl 0x5c(%edx,%eax,1),%edx
8010165e:	89 d1                	mov    %edx,%ecx
80101660:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101663:	f7 d2                	not    %edx
80101665:	21 ca                	and    %ecx,%edx
80101667:	89 d1                	mov    %edx,%ecx
80101669:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010166c:	88 4c 02 5c          	mov    %cl,0x5c(%edx,%eax,1)
  log_write(bp);
80101670:	83 ec 0c             	sub    $0xc,%esp
80101673:	ff 75 f4             	pushl  -0xc(%ebp)
80101676:	e8 e0 20 00 00       	call   8010375b <log_write>
8010167b:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
8010167e:	83 ec 0c             	sub    $0xc,%esp
80101681:	ff 75 f4             	pushl  -0xc(%ebp)
80101684:	e8 c7 eb ff ff       	call   80100250 <brelse>
80101689:	83 c4 10             	add    $0x10,%esp
}
8010168c:	90                   	nop
8010168d:	c9                   	leave  
8010168e:	c3                   	ret    

8010168f <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
8010168f:	55                   	push   %ebp
80101690:	89 e5                	mov    %esp,%ebp
80101692:	57                   	push   %edi
80101693:	56                   	push   %esi
80101694:	53                   	push   %ebx
80101695:	83 ec 2c             	sub    $0x2c,%esp
  int i = 0;
80101698:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  
  initlock(&icache.lock, "icache");
8010169f:	83 ec 08             	sub    $0x8,%esp
801016a2:	68 3d 84 10 80       	push   $0x8010843d
801016a7:	68 60 1a 11 80       	push   $0x80111a60
801016ac:	e8 9c 38 00 00       	call   80104f4d <initlock>
801016b1:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NINODE; i++) {
801016b4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801016bb:	eb 2d                	jmp    801016ea <iinit+0x5b>
    initsleeplock(&icache.inode[i].lock, "inode");
801016bd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801016c0:	89 d0                	mov    %edx,%eax
801016c2:	c1 e0 03             	shl    $0x3,%eax
801016c5:	01 d0                	add    %edx,%eax
801016c7:	c1 e0 04             	shl    $0x4,%eax
801016ca:	83 c0 30             	add    $0x30,%eax
801016cd:	05 60 1a 11 80       	add    $0x80111a60,%eax
801016d2:	83 c0 10             	add    $0x10,%eax
801016d5:	83 ec 08             	sub    $0x8,%esp
801016d8:	68 44 84 10 80       	push   $0x80108444
801016dd:	50                   	push   %eax
801016de:	e8 e7 36 00 00       	call   80104dca <initsleeplock>
801016e3:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NINODE; i++) {
801016e6:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801016ea:	83 7d e4 31          	cmpl   $0x31,-0x1c(%ebp)
801016ee:	7e cd                	jle    801016bd <iinit+0x2e>
  }

  readsb(dev, &sb);
801016f0:	83 ec 08             	sub    $0x8,%esp
801016f3:	68 40 1a 11 80       	push   $0x80111a40
801016f8:	ff 75 08             	pushl  0x8(%ebp)
801016fb:	e8 e8 fc ff ff       	call   801013e8 <readsb>
80101700:	83 c4 10             	add    $0x10,%esp
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101703:	a1 58 1a 11 80       	mov    0x80111a58,%eax
80101708:	89 45 d4             	mov    %eax,-0x2c(%ebp)
8010170b:	8b 3d 54 1a 11 80    	mov    0x80111a54,%edi
80101711:	8b 35 50 1a 11 80    	mov    0x80111a50,%esi
80101717:	8b 1d 4c 1a 11 80    	mov    0x80111a4c,%ebx
8010171d:	8b 0d 48 1a 11 80    	mov    0x80111a48,%ecx
80101723:	8b 15 44 1a 11 80    	mov    0x80111a44,%edx
80101729:	a1 40 1a 11 80       	mov    0x80111a40,%eax
8010172e:	ff 75 d4             	pushl  -0x2c(%ebp)
80101731:	57                   	push   %edi
80101732:	56                   	push   %esi
80101733:	53                   	push   %ebx
80101734:	51                   	push   %ecx
80101735:	52                   	push   %edx
80101736:	50                   	push   %eax
80101737:	68 4c 84 10 80       	push   $0x8010844c
8010173c:	e8 bb ec ff ff       	call   801003fc <cprintf>
80101741:	83 c4 20             	add    $0x20,%esp
 inodestart %d bmap start %d\n", sb.size, sb.nblocks,
          sb.ninodes, sb.nlog, sb.logstart, sb.inodestart,
          sb.bmapstart);
}
80101744:	90                   	nop
80101745:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101748:	5b                   	pop    %ebx
80101749:	5e                   	pop    %esi
8010174a:	5f                   	pop    %edi
8010174b:	5d                   	pop    %ebp
8010174c:	c3                   	ret    

8010174d <ialloc>:
// Allocate an inode on device dev.
// Mark it as allocated by  giving it type type.
// Returns an unlocked but allocated and referenced inode.
struct inode*
ialloc(uint dev, short type)
{
8010174d:	55                   	push   %ebp
8010174e:	89 e5                	mov    %esp,%ebp
80101750:	83 ec 28             	sub    $0x28,%esp
80101753:	8b 45 0c             	mov    0xc(%ebp),%eax
80101756:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
8010175a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101761:	e9 9e 00 00 00       	jmp    80101804 <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
80101766:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101769:	c1 e8 03             	shr    $0x3,%eax
8010176c:	89 c2                	mov    %eax,%edx
8010176e:	a1 54 1a 11 80       	mov    0x80111a54,%eax
80101773:	01 d0                	add    %edx,%eax
80101775:	83 ec 08             	sub    $0x8,%esp
80101778:	50                   	push   %eax
80101779:	ff 75 08             	pushl  0x8(%ebp)
8010177c:	e8 4d ea ff ff       	call   801001ce <bread>
80101781:	83 c4 10             	add    $0x10,%esp
80101784:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101787:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010178a:	8d 50 5c             	lea    0x5c(%eax),%edx
8010178d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101790:	83 e0 07             	and    $0x7,%eax
80101793:	c1 e0 06             	shl    $0x6,%eax
80101796:	01 d0                	add    %edx,%eax
80101798:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
8010179b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010179e:	0f b7 00             	movzwl (%eax),%eax
801017a1:	66 85 c0             	test   %ax,%ax
801017a4:	75 4c                	jne    801017f2 <ialloc+0xa5>
      memset(dip, 0, sizeof(*dip));
801017a6:	83 ec 04             	sub    $0x4,%esp
801017a9:	6a 40                	push   $0x40
801017ab:	6a 00                	push   $0x0
801017ad:	ff 75 ec             	pushl  -0x14(%ebp)
801017b0:	e8 41 3a 00 00       	call   801051f6 <memset>
801017b5:	83 c4 10             	add    $0x10,%esp
      dip->type = type;
801017b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017bb:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
801017bf:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801017c2:	83 ec 0c             	sub    $0xc,%esp
801017c5:	ff 75 f0             	pushl  -0x10(%ebp)
801017c8:	e8 8e 1f 00 00       	call   8010375b <log_write>
801017cd:	83 c4 10             	add    $0x10,%esp
      brelse(bp);
801017d0:	83 ec 0c             	sub    $0xc,%esp
801017d3:	ff 75 f0             	pushl  -0x10(%ebp)
801017d6:	e8 75 ea ff ff       	call   80100250 <brelse>
801017db:	83 c4 10             	add    $0x10,%esp
      return iget(dev, inum);
801017de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017e1:	83 ec 08             	sub    $0x8,%esp
801017e4:	50                   	push   %eax
801017e5:	ff 75 08             	pushl  0x8(%ebp)
801017e8:	e8 f8 00 00 00       	call   801018e5 <iget>
801017ed:	83 c4 10             	add    $0x10,%esp
801017f0:	eb 30                	jmp    80101822 <ialloc+0xd5>
    }
    brelse(bp);
801017f2:	83 ec 0c             	sub    $0xc,%esp
801017f5:	ff 75 f0             	pushl  -0x10(%ebp)
801017f8:	e8 53 ea ff ff       	call   80100250 <brelse>
801017fd:	83 c4 10             	add    $0x10,%esp
  for(inum = 1; inum < sb.ninodes; inum++){
80101800:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101804:	8b 15 48 1a 11 80    	mov    0x80111a48,%edx
8010180a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010180d:	39 c2                	cmp    %eax,%edx
8010180f:	0f 87 51 ff ff ff    	ja     80101766 <ialloc+0x19>
  }
  panic("ialloc: no inodes");
80101815:	83 ec 0c             	sub    $0xc,%esp
80101818:	68 9f 84 10 80       	push   $0x8010849f
8010181d:	e8 7a ed ff ff       	call   8010059c <panic>
}
80101822:	c9                   	leave  
80101823:	c3                   	ret    

80101824 <iupdate>:
// Must be called after every change to an ip->xxx field
// that lives on disk, since i-node cache is write-through.
// Caller must hold ip->lock.
void
iupdate(struct inode *ip)
{
80101824:	55                   	push   %ebp
80101825:	89 e5                	mov    %esp,%ebp
80101827:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
8010182a:	8b 45 08             	mov    0x8(%ebp),%eax
8010182d:	8b 40 04             	mov    0x4(%eax),%eax
80101830:	c1 e8 03             	shr    $0x3,%eax
80101833:	89 c2                	mov    %eax,%edx
80101835:	a1 54 1a 11 80       	mov    0x80111a54,%eax
8010183a:	01 c2                	add    %eax,%edx
8010183c:	8b 45 08             	mov    0x8(%ebp),%eax
8010183f:	8b 00                	mov    (%eax),%eax
80101841:	83 ec 08             	sub    $0x8,%esp
80101844:	52                   	push   %edx
80101845:	50                   	push   %eax
80101846:	e8 83 e9 ff ff       	call   801001ce <bread>
8010184b:	83 c4 10             	add    $0x10,%esp
8010184e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101851:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101854:	8d 50 5c             	lea    0x5c(%eax),%edx
80101857:	8b 45 08             	mov    0x8(%ebp),%eax
8010185a:	8b 40 04             	mov    0x4(%eax),%eax
8010185d:	83 e0 07             	and    $0x7,%eax
80101860:	c1 e0 06             	shl    $0x6,%eax
80101863:	01 d0                	add    %edx,%eax
80101865:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101868:	8b 45 08             	mov    0x8(%ebp),%eax
8010186b:	0f b7 50 50          	movzwl 0x50(%eax),%edx
8010186f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101872:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101875:	8b 45 08             	mov    0x8(%ebp),%eax
80101878:	0f b7 50 52          	movzwl 0x52(%eax),%edx
8010187c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010187f:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101883:	8b 45 08             	mov    0x8(%ebp),%eax
80101886:	0f b7 50 54          	movzwl 0x54(%eax),%edx
8010188a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010188d:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101891:	8b 45 08             	mov    0x8(%ebp),%eax
80101894:	0f b7 50 56          	movzwl 0x56(%eax),%edx
80101898:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010189b:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010189f:	8b 45 08             	mov    0x8(%ebp),%eax
801018a2:	8b 50 58             	mov    0x58(%eax),%edx
801018a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018a8:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801018ab:	8b 45 08             	mov    0x8(%ebp),%eax
801018ae:	8d 50 5c             	lea    0x5c(%eax),%edx
801018b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018b4:	83 c0 0c             	add    $0xc,%eax
801018b7:	83 ec 04             	sub    $0x4,%esp
801018ba:	6a 34                	push   $0x34
801018bc:	52                   	push   %edx
801018bd:	50                   	push   %eax
801018be:	e8 f2 39 00 00       	call   801052b5 <memmove>
801018c3:	83 c4 10             	add    $0x10,%esp
  log_write(bp);
801018c6:	83 ec 0c             	sub    $0xc,%esp
801018c9:	ff 75 f4             	pushl  -0xc(%ebp)
801018cc:	e8 8a 1e 00 00       	call   8010375b <log_write>
801018d1:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
801018d4:	83 ec 0c             	sub    $0xc,%esp
801018d7:	ff 75 f4             	pushl  -0xc(%ebp)
801018da:	e8 71 e9 ff ff       	call   80100250 <brelse>
801018df:	83 c4 10             	add    $0x10,%esp
}
801018e2:	90                   	nop
801018e3:	c9                   	leave  
801018e4:	c3                   	ret    

801018e5 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801018e5:	55                   	push   %ebp
801018e6:	89 e5                	mov    %esp,%ebp
801018e8:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801018eb:	83 ec 0c             	sub    $0xc,%esp
801018ee:	68 60 1a 11 80       	push   $0x80111a60
801018f3:	e8 77 36 00 00       	call   80104f6f <acquire>
801018f8:	83 c4 10             	add    $0x10,%esp

  // Is the inode already cached?
  empty = 0;
801018fb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101902:	c7 45 f4 94 1a 11 80 	movl   $0x80111a94,-0xc(%ebp)
80101909:	eb 60                	jmp    8010196b <iget+0x86>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010190b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010190e:	8b 40 08             	mov    0x8(%eax),%eax
80101911:	85 c0                	test   %eax,%eax
80101913:	7e 39                	jle    8010194e <iget+0x69>
80101915:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101918:	8b 00                	mov    (%eax),%eax
8010191a:	39 45 08             	cmp    %eax,0x8(%ebp)
8010191d:	75 2f                	jne    8010194e <iget+0x69>
8010191f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101922:	8b 40 04             	mov    0x4(%eax),%eax
80101925:	39 45 0c             	cmp    %eax,0xc(%ebp)
80101928:	75 24                	jne    8010194e <iget+0x69>
      ip->ref++;
8010192a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010192d:	8b 40 08             	mov    0x8(%eax),%eax
80101930:	8d 50 01             	lea    0x1(%eax),%edx
80101933:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101936:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101939:	83 ec 0c             	sub    $0xc,%esp
8010193c:	68 60 1a 11 80       	push   $0x80111a60
80101941:	e8 97 36 00 00       	call   80104fdd <release>
80101946:	83 c4 10             	add    $0x10,%esp
      return ip;
80101949:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010194c:	eb 77                	jmp    801019c5 <iget+0xe0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010194e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101952:	75 10                	jne    80101964 <iget+0x7f>
80101954:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101957:	8b 40 08             	mov    0x8(%eax),%eax
8010195a:	85 c0                	test   %eax,%eax
8010195c:	75 06                	jne    80101964 <iget+0x7f>
      empty = ip;
8010195e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101961:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101964:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
8010196b:	81 7d f4 b4 36 11 80 	cmpl   $0x801136b4,-0xc(%ebp)
80101972:	72 97                	jb     8010190b <iget+0x26>
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101974:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101978:	75 0d                	jne    80101987 <iget+0xa2>
    panic("iget: no inodes");
8010197a:	83 ec 0c             	sub    $0xc,%esp
8010197d:	68 b1 84 10 80       	push   $0x801084b1
80101982:	e8 15 ec ff ff       	call   8010059c <panic>

  ip = empty;
80101987:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010198a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
8010198d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101990:	8b 55 08             	mov    0x8(%ebp),%edx
80101993:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101995:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101998:	8b 55 0c             	mov    0xc(%ebp),%edx
8010199b:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
8010199e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019a1:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->valid = 0;
801019a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019ab:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  release(&icache.lock);
801019b2:	83 ec 0c             	sub    $0xc,%esp
801019b5:	68 60 1a 11 80       	push   $0x80111a60
801019ba:	e8 1e 36 00 00       	call   80104fdd <release>
801019bf:	83 c4 10             	add    $0x10,%esp

  return ip;
801019c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801019c5:	c9                   	leave  
801019c6:	c3                   	ret    

801019c7 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801019c7:	55                   	push   %ebp
801019c8:	89 e5                	mov    %esp,%ebp
801019ca:	83 ec 08             	sub    $0x8,%esp
  acquire(&icache.lock);
801019cd:	83 ec 0c             	sub    $0xc,%esp
801019d0:	68 60 1a 11 80       	push   $0x80111a60
801019d5:	e8 95 35 00 00       	call   80104f6f <acquire>
801019da:	83 c4 10             	add    $0x10,%esp
  ip->ref++;
801019dd:	8b 45 08             	mov    0x8(%ebp),%eax
801019e0:	8b 40 08             	mov    0x8(%eax),%eax
801019e3:	8d 50 01             	lea    0x1(%eax),%edx
801019e6:	8b 45 08             	mov    0x8(%ebp),%eax
801019e9:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801019ec:	83 ec 0c             	sub    $0xc,%esp
801019ef:	68 60 1a 11 80       	push   $0x80111a60
801019f4:	e8 e4 35 00 00       	call   80104fdd <release>
801019f9:	83 c4 10             	add    $0x10,%esp
  return ip;
801019fc:	8b 45 08             	mov    0x8(%ebp),%eax
}
801019ff:	c9                   	leave  
80101a00:	c3                   	ret    

80101a01 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101a01:	55                   	push   %ebp
80101a02:	89 e5                	mov    %esp,%ebp
80101a04:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101a07:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a0b:	74 0a                	je     80101a17 <ilock+0x16>
80101a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a10:	8b 40 08             	mov    0x8(%eax),%eax
80101a13:	85 c0                	test   %eax,%eax
80101a15:	7f 0d                	jg     80101a24 <ilock+0x23>
    panic("ilock");
80101a17:	83 ec 0c             	sub    $0xc,%esp
80101a1a:	68 c1 84 10 80       	push   $0x801084c1
80101a1f:	e8 78 eb ff ff       	call   8010059c <panic>

  acquiresleep(&ip->lock);
80101a24:	8b 45 08             	mov    0x8(%ebp),%eax
80101a27:	83 c0 0c             	add    $0xc,%eax
80101a2a:	83 ec 0c             	sub    $0xc,%esp
80101a2d:	50                   	push   %eax
80101a2e:	e8 d3 33 00 00       	call   80104e06 <acquiresleep>
80101a33:	83 c4 10             	add    $0x10,%esp

  if(ip->valid == 0){
80101a36:	8b 45 08             	mov    0x8(%ebp),%eax
80101a39:	8b 40 4c             	mov    0x4c(%eax),%eax
80101a3c:	85 c0                	test   %eax,%eax
80101a3e:	0f 85 cd 00 00 00    	jne    80101b11 <ilock+0x110>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101a44:	8b 45 08             	mov    0x8(%ebp),%eax
80101a47:	8b 40 04             	mov    0x4(%eax),%eax
80101a4a:	c1 e8 03             	shr    $0x3,%eax
80101a4d:	89 c2                	mov    %eax,%edx
80101a4f:	a1 54 1a 11 80       	mov    0x80111a54,%eax
80101a54:	01 c2                	add    %eax,%edx
80101a56:	8b 45 08             	mov    0x8(%ebp),%eax
80101a59:	8b 00                	mov    (%eax),%eax
80101a5b:	83 ec 08             	sub    $0x8,%esp
80101a5e:	52                   	push   %edx
80101a5f:	50                   	push   %eax
80101a60:	e8 69 e7 ff ff       	call   801001ce <bread>
80101a65:	83 c4 10             	add    $0x10,%esp
80101a68:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101a6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a6e:	8d 50 5c             	lea    0x5c(%eax),%edx
80101a71:	8b 45 08             	mov    0x8(%ebp),%eax
80101a74:	8b 40 04             	mov    0x4(%eax),%eax
80101a77:	83 e0 07             	and    $0x7,%eax
80101a7a:	c1 e0 06             	shl    $0x6,%eax
80101a7d:	01 d0                	add    %edx,%eax
80101a7f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101a82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a85:	0f b7 10             	movzwl (%eax),%edx
80101a88:	8b 45 08             	mov    0x8(%ebp),%eax
80101a8b:	66 89 50 50          	mov    %dx,0x50(%eax)
    ip->major = dip->major;
80101a8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a92:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101a96:	8b 45 08             	mov    0x8(%ebp),%eax
80101a99:	66 89 50 52          	mov    %dx,0x52(%eax)
    ip->minor = dip->minor;
80101a9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aa0:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101aa4:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa7:	66 89 50 54          	mov    %dx,0x54(%eax)
    ip->nlink = dip->nlink;
80101aab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aae:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101ab2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab5:	66 89 50 56          	mov    %dx,0x56(%eax)
    ip->size = dip->size;
80101ab9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101abc:	8b 50 08             	mov    0x8(%eax),%edx
80101abf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac2:	89 50 58             	mov    %edx,0x58(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101ac5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ac8:	8d 50 0c             	lea    0xc(%eax),%edx
80101acb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ace:	83 c0 5c             	add    $0x5c,%eax
80101ad1:	83 ec 04             	sub    $0x4,%esp
80101ad4:	6a 34                	push   $0x34
80101ad6:	52                   	push   %edx
80101ad7:	50                   	push   %eax
80101ad8:	e8 d8 37 00 00       	call   801052b5 <memmove>
80101add:	83 c4 10             	add    $0x10,%esp
    brelse(bp);
80101ae0:	83 ec 0c             	sub    $0xc,%esp
80101ae3:	ff 75 f4             	pushl  -0xc(%ebp)
80101ae6:	e8 65 e7 ff ff       	call   80100250 <brelse>
80101aeb:	83 c4 10             	add    $0x10,%esp
    ip->valid = 1;
80101aee:	8b 45 08             	mov    0x8(%ebp),%eax
80101af1:	c7 40 4c 01 00 00 00 	movl   $0x1,0x4c(%eax)
    if(ip->type == 0)
80101af8:	8b 45 08             	mov    0x8(%ebp),%eax
80101afb:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80101aff:	66 85 c0             	test   %ax,%ax
80101b02:	75 0d                	jne    80101b11 <ilock+0x110>
      panic("ilock: no type");
80101b04:	83 ec 0c             	sub    $0xc,%esp
80101b07:	68 c7 84 10 80       	push   $0x801084c7
80101b0c:	e8 8b ea ff ff       	call   8010059c <panic>
  }
}
80101b11:	90                   	nop
80101b12:	c9                   	leave  
80101b13:	c3                   	ret    

80101b14 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101b14:	55                   	push   %ebp
80101b15:	89 e5                	mov    %esp,%ebp
80101b17:	83 ec 08             	sub    $0x8,%esp
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
80101b1a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101b1e:	74 20                	je     80101b40 <iunlock+0x2c>
80101b20:	8b 45 08             	mov    0x8(%ebp),%eax
80101b23:	83 c0 0c             	add    $0xc,%eax
80101b26:	83 ec 0c             	sub    $0xc,%esp
80101b29:	50                   	push   %eax
80101b2a:	e8 89 33 00 00       	call   80104eb8 <holdingsleep>
80101b2f:	83 c4 10             	add    $0x10,%esp
80101b32:	85 c0                	test   %eax,%eax
80101b34:	74 0a                	je     80101b40 <iunlock+0x2c>
80101b36:	8b 45 08             	mov    0x8(%ebp),%eax
80101b39:	8b 40 08             	mov    0x8(%eax),%eax
80101b3c:	85 c0                	test   %eax,%eax
80101b3e:	7f 0d                	jg     80101b4d <iunlock+0x39>
    panic("iunlock");
80101b40:	83 ec 0c             	sub    $0xc,%esp
80101b43:	68 d6 84 10 80       	push   $0x801084d6
80101b48:	e8 4f ea ff ff       	call   8010059c <panic>

  releasesleep(&ip->lock);
80101b4d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b50:	83 c0 0c             	add    $0xc,%eax
80101b53:	83 ec 0c             	sub    $0xc,%esp
80101b56:	50                   	push   %eax
80101b57:	e8 0e 33 00 00       	call   80104e6a <releasesleep>
80101b5c:	83 c4 10             	add    $0x10,%esp
}
80101b5f:	90                   	nop
80101b60:	c9                   	leave  
80101b61:	c3                   	ret    

80101b62 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101b62:	55                   	push   %ebp
80101b63:	89 e5                	mov    %esp,%ebp
80101b65:	83 ec 18             	sub    $0x18,%esp
  acquiresleep(&ip->lock);
80101b68:	8b 45 08             	mov    0x8(%ebp),%eax
80101b6b:	83 c0 0c             	add    $0xc,%eax
80101b6e:	83 ec 0c             	sub    $0xc,%esp
80101b71:	50                   	push   %eax
80101b72:	e8 8f 32 00 00       	call   80104e06 <acquiresleep>
80101b77:	83 c4 10             	add    $0x10,%esp
  if(ip->valid && ip->nlink == 0){
80101b7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7d:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b80:	85 c0                	test   %eax,%eax
80101b82:	74 6a                	je     80101bee <iput+0x8c>
80101b84:	8b 45 08             	mov    0x8(%ebp),%eax
80101b87:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80101b8b:	66 85 c0             	test   %ax,%ax
80101b8e:	75 5e                	jne    80101bee <iput+0x8c>
    acquire(&icache.lock);
80101b90:	83 ec 0c             	sub    $0xc,%esp
80101b93:	68 60 1a 11 80       	push   $0x80111a60
80101b98:	e8 d2 33 00 00       	call   80104f6f <acquire>
80101b9d:	83 c4 10             	add    $0x10,%esp
    int r = ip->ref;
80101ba0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba3:	8b 40 08             	mov    0x8(%eax),%eax
80101ba6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    release(&icache.lock);
80101ba9:	83 ec 0c             	sub    $0xc,%esp
80101bac:	68 60 1a 11 80       	push   $0x80111a60
80101bb1:	e8 27 34 00 00       	call   80104fdd <release>
80101bb6:	83 c4 10             	add    $0x10,%esp
    if(r == 1){
80101bb9:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80101bbd:	75 2f                	jne    80101bee <iput+0x8c>
      // inode has no links and no other references: truncate and free.
      itrunc(ip);
80101bbf:	83 ec 0c             	sub    $0xc,%esp
80101bc2:	ff 75 08             	pushl  0x8(%ebp)
80101bc5:	e8 ad 01 00 00       	call   80101d77 <itrunc>
80101bca:	83 c4 10             	add    $0x10,%esp
      ip->type = 0;
80101bcd:	8b 45 08             	mov    0x8(%ebp),%eax
80101bd0:	66 c7 40 50 00 00    	movw   $0x0,0x50(%eax)
      iupdate(ip);
80101bd6:	83 ec 0c             	sub    $0xc,%esp
80101bd9:	ff 75 08             	pushl  0x8(%ebp)
80101bdc:	e8 43 fc ff ff       	call   80101824 <iupdate>
80101be1:	83 c4 10             	add    $0x10,%esp
      ip->valid = 0;
80101be4:	8b 45 08             	mov    0x8(%ebp),%eax
80101be7:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
    }
  }
  releasesleep(&ip->lock);
80101bee:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf1:	83 c0 0c             	add    $0xc,%eax
80101bf4:	83 ec 0c             	sub    $0xc,%esp
80101bf7:	50                   	push   %eax
80101bf8:	e8 6d 32 00 00       	call   80104e6a <releasesleep>
80101bfd:	83 c4 10             	add    $0x10,%esp

  acquire(&icache.lock);
80101c00:	83 ec 0c             	sub    $0xc,%esp
80101c03:	68 60 1a 11 80       	push   $0x80111a60
80101c08:	e8 62 33 00 00       	call   80104f6f <acquire>
80101c0d:	83 c4 10             	add    $0x10,%esp
  ip->ref--;
80101c10:	8b 45 08             	mov    0x8(%ebp),%eax
80101c13:	8b 40 08             	mov    0x8(%eax),%eax
80101c16:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c19:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1c:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c1f:	83 ec 0c             	sub    $0xc,%esp
80101c22:	68 60 1a 11 80       	push   $0x80111a60
80101c27:	e8 b1 33 00 00       	call   80104fdd <release>
80101c2c:	83 c4 10             	add    $0x10,%esp
}
80101c2f:	90                   	nop
80101c30:	c9                   	leave  
80101c31:	c3                   	ret    

80101c32 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101c32:	55                   	push   %ebp
80101c33:	89 e5                	mov    %esp,%ebp
80101c35:	83 ec 08             	sub    $0x8,%esp
  iunlock(ip);
80101c38:	83 ec 0c             	sub    $0xc,%esp
80101c3b:	ff 75 08             	pushl  0x8(%ebp)
80101c3e:	e8 d1 fe ff ff       	call   80101b14 <iunlock>
80101c43:	83 c4 10             	add    $0x10,%esp
  iput(ip);
80101c46:	83 ec 0c             	sub    $0xc,%esp
80101c49:	ff 75 08             	pushl  0x8(%ebp)
80101c4c:	e8 11 ff ff ff       	call   80101b62 <iput>
80101c51:	83 c4 10             	add    $0x10,%esp
}
80101c54:	90                   	nop
80101c55:	c9                   	leave  
80101c56:	c3                   	ret    

80101c57 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101c57:	55                   	push   %ebp
80101c58:	89 e5                	mov    %esp,%ebp
80101c5a:	83 ec 18             	sub    $0x18,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101c5d:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101c61:	77 42                	ja     80101ca5 <bmap+0x4e>
    if((addr = ip->addrs[bn]) == 0)
80101c63:	8b 45 08             	mov    0x8(%ebp),%eax
80101c66:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c69:	83 c2 14             	add    $0x14,%edx
80101c6c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c70:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c73:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c77:	75 24                	jne    80101c9d <bmap+0x46>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101c79:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7c:	8b 00                	mov    (%eax),%eax
80101c7e:	83 ec 0c             	sub    $0xc,%esp
80101c81:	50                   	push   %eax
80101c82:	e8 f7 f7 ff ff       	call   8010147e <balloc>
80101c87:	83 c4 10             	add    $0x10,%esp
80101c8a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101c90:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c93:	8d 4a 14             	lea    0x14(%edx),%ecx
80101c96:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c99:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101c9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ca0:	e9 d0 00 00 00       	jmp    80101d75 <bmap+0x11e>
  }
  bn -= NDIRECT;
80101ca5:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101ca9:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101cad:	0f 87 b5 00 00 00    	ja     80101d68 <bmap+0x111>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101cb3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cb6:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101cbc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cbf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cc3:	75 20                	jne    80101ce5 <bmap+0x8e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101cc5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc8:	8b 00                	mov    (%eax),%eax
80101cca:	83 ec 0c             	sub    $0xc,%esp
80101ccd:	50                   	push   %eax
80101cce:	e8 ab f7 ff ff       	call   8010147e <balloc>
80101cd3:	83 c4 10             	add    $0x10,%esp
80101cd6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cd9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cdc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cdf:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
    bp = bread(ip->dev, addr);
80101ce5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ce8:	8b 00                	mov    (%eax),%eax
80101cea:	83 ec 08             	sub    $0x8,%esp
80101ced:	ff 75 f4             	pushl  -0xc(%ebp)
80101cf0:	50                   	push   %eax
80101cf1:	e8 d8 e4 ff ff       	call   801001ce <bread>
80101cf6:	83 c4 10             	add    $0x10,%esp
80101cf9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101cfc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cff:	83 c0 5c             	add    $0x5c,%eax
80101d02:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101d05:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d08:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d0f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d12:	01 d0                	add    %edx,%eax
80101d14:	8b 00                	mov    (%eax),%eax
80101d16:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d1d:	75 36                	jne    80101d55 <bmap+0xfe>
      a[bn] = addr = balloc(ip->dev);
80101d1f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d22:	8b 00                	mov    (%eax),%eax
80101d24:	83 ec 0c             	sub    $0xc,%esp
80101d27:	50                   	push   %eax
80101d28:	e8 51 f7 ff ff       	call   8010147e <balloc>
80101d2d:	83 c4 10             	add    $0x10,%esp
80101d30:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d33:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d36:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d40:	01 c2                	add    %eax,%edx
80101d42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d45:	89 02                	mov    %eax,(%edx)
      log_write(bp);
80101d47:	83 ec 0c             	sub    $0xc,%esp
80101d4a:	ff 75 f0             	pushl  -0x10(%ebp)
80101d4d:	e8 09 1a 00 00       	call   8010375b <log_write>
80101d52:	83 c4 10             	add    $0x10,%esp
    }
    brelse(bp);
80101d55:	83 ec 0c             	sub    $0xc,%esp
80101d58:	ff 75 f0             	pushl  -0x10(%ebp)
80101d5b:	e8 f0 e4 ff ff       	call   80100250 <brelse>
80101d60:	83 c4 10             	add    $0x10,%esp
    return addr;
80101d63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d66:	eb 0d                	jmp    80101d75 <bmap+0x11e>
  }

  panic("bmap: out of range");
80101d68:	83 ec 0c             	sub    $0xc,%esp
80101d6b:	68 de 84 10 80       	push   $0x801084de
80101d70:	e8 27 e8 ff ff       	call   8010059c <panic>
}
80101d75:	c9                   	leave  
80101d76:	c3                   	ret    

80101d77 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101d77:	55                   	push   %ebp
80101d78:	89 e5                	mov    %esp,%ebp
80101d7a:	83 ec 18             	sub    $0x18,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d7d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101d84:	eb 45                	jmp    80101dcb <itrunc+0x54>
    if(ip->addrs[i]){
80101d86:	8b 45 08             	mov    0x8(%ebp),%eax
80101d89:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d8c:	83 c2 14             	add    $0x14,%edx
80101d8f:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101d93:	85 c0                	test   %eax,%eax
80101d95:	74 30                	je     80101dc7 <itrunc+0x50>
      bfree(ip->dev, ip->addrs[i]);
80101d97:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d9d:	83 c2 14             	add    $0x14,%edx
80101da0:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101da4:	8b 55 08             	mov    0x8(%ebp),%edx
80101da7:	8b 12                	mov    (%edx),%edx
80101da9:	83 ec 08             	sub    $0x8,%esp
80101dac:	50                   	push   %eax
80101dad:	52                   	push   %edx
80101dae:	e8 17 f8 ff ff       	call   801015ca <bfree>
80101db3:	83 c4 10             	add    $0x10,%esp
      ip->addrs[i] = 0;
80101db6:	8b 45 08             	mov    0x8(%ebp),%eax
80101db9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101dbc:	83 c2 14             	add    $0x14,%edx
80101dbf:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101dc6:	00 
  for(i = 0; i < NDIRECT; i++){
80101dc7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101dcb:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101dcf:	7e b5                	jle    80101d86 <itrunc+0xf>
    }
  }

  if(ip->addrs[NDIRECT]){
80101dd1:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd4:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101dda:	85 c0                	test   %eax,%eax
80101ddc:	0f 84 aa 00 00 00    	je     80101e8c <itrunc+0x115>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101de2:	8b 45 08             	mov    0x8(%ebp),%eax
80101de5:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80101deb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dee:	8b 00                	mov    (%eax),%eax
80101df0:	83 ec 08             	sub    $0x8,%esp
80101df3:	52                   	push   %edx
80101df4:	50                   	push   %eax
80101df5:	e8 d4 e3 ff ff       	call   801001ce <bread>
80101dfa:	83 c4 10             	add    $0x10,%esp
80101dfd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101e00:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e03:	83 c0 5c             	add    $0x5c,%eax
80101e06:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101e09:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101e10:	eb 3c                	jmp    80101e4e <itrunc+0xd7>
      if(a[j])
80101e12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e15:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e1c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e1f:	01 d0                	add    %edx,%eax
80101e21:	8b 00                	mov    (%eax),%eax
80101e23:	85 c0                	test   %eax,%eax
80101e25:	74 23                	je     80101e4a <itrunc+0xd3>
        bfree(ip->dev, a[j]);
80101e27:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e2a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e31:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e34:	01 d0                	add    %edx,%eax
80101e36:	8b 00                	mov    (%eax),%eax
80101e38:	8b 55 08             	mov    0x8(%ebp),%edx
80101e3b:	8b 12                	mov    (%edx),%edx
80101e3d:	83 ec 08             	sub    $0x8,%esp
80101e40:	50                   	push   %eax
80101e41:	52                   	push   %edx
80101e42:	e8 83 f7 ff ff       	call   801015ca <bfree>
80101e47:	83 c4 10             	add    $0x10,%esp
    for(j = 0; j < NINDIRECT; j++){
80101e4a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101e4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e51:	83 f8 7f             	cmp    $0x7f,%eax
80101e54:	76 bc                	jbe    80101e12 <itrunc+0x9b>
    }
    brelse(bp);
80101e56:	83 ec 0c             	sub    $0xc,%esp
80101e59:	ff 75 ec             	pushl  -0x14(%ebp)
80101e5c:	e8 ef e3 ff ff       	call   80100250 <brelse>
80101e61:	83 c4 10             	add    $0x10,%esp
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101e64:	8b 45 08             	mov    0x8(%ebp),%eax
80101e67:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101e6d:	8b 55 08             	mov    0x8(%ebp),%edx
80101e70:	8b 12                	mov    (%edx),%edx
80101e72:	83 ec 08             	sub    $0x8,%esp
80101e75:	50                   	push   %eax
80101e76:	52                   	push   %edx
80101e77:	e8 4e f7 ff ff       	call   801015ca <bfree>
80101e7c:	83 c4 10             	add    $0x10,%esp
    ip->addrs[NDIRECT] = 0;
80101e7f:	8b 45 08             	mov    0x8(%ebp),%eax
80101e82:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80101e89:	00 00 00 
  }

  ip->size = 0;
80101e8c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8f:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
  iupdate(ip);
80101e96:	83 ec 0c             	sub    $0xc,%esp
80101e99:	ff 75 08             	pushl  0x8(%ebp)
80101e9c:	e8 83 f9 ff ff       	call   80101824 <iupdate>
80101ea1:	83 c4 10             	add    $0x10,%esp
}
80101ea4:	90                   	nop
80101ea5:	c9                   	leave  
80101ea6:	c3                   	ret    

80101ea7 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
80101ea7:	55                   	push   %ebp
80101ea8:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101eaa:	8b 45 08             	mov    0x8(%ebp),%eax
80101ead:	8b 00                	mov    (%eax),%eax
80101eaf:	89 c2                	mov    %eax,%edx
80101eb1:	8b 45 0c             	mov    0xc(%ebp),%eax
80101eb4:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101eb7:	8b 45 08             	mov    0x8(%ebp),%eax
80101eba:	8b 50 04             	mov    0x4(%eax),%edx
80101ebd:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ec0:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101ec3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec6:	0f b7 50 50          	movzwl 0x50(%eax),%edx
80101eca:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ecd:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101ed0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed3:	0f b7 50 56          	movzwl 0x56(%eax),%edx
80101ed7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101eda:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101ede:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee1:	8b 50 58             	mov    0x58(%eax),%edx
80101ee4:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ee7:	89 50 10             	mov    %edx,0x10(%eax)
}
80101eea:	90                   	nop
80101eeb:	5d                   	pop    %ebp
80101eec:	c3                   	ret    

80101eed <readi>:
//PAGEBREAK!
// Read data from inode.
// Caller must hold ip->lock.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101eed:	55                   	push   %ebp
80101eee:	89 e5                	mov    %esp,%ebp
80101ef0:	83 ec 18             	sub    $0x18,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101ef3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef6:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80101efa:	66 83 f8 03          	cmp    $0x3,%ax
80101efe:	75 5c                	jne    80101f5c <readi+0x6f>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101f00:	8b 45 08             	mov    0x8(%ebp),%eax
80101f03:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f07:	66 85 c0             	test   %ax,%ax
80101f0a:	78 20                	js     80101f2c <readi+0x3f>
80101f0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f0f:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f13:	66 83 f8 09          	cmp    $0x9,%ax
80101f17:	7f 13                	jg     80101f2c <readi+0x3f>
80101f19:	8b 45 08             	mov    0x8(%ebp),%eax
80101f1c:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f20:	98                   	cwtl   
80101f21:	8b 04 c5 e0 19 11 80 	mov    -0x7feee620(,%eax,8),%eax
80101f28:	85 c0                	test   %eax,%eax
80101f2a:	75 0a                	jne    80101f36 <readi+0x49>
      return -1;
80101f2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f31:	e9 0c 01 00 00       	jmp    80102042 <readi+0x155>
    return devsw[ip->major].read(ip, dst, n);
80101f36:	8b 45 08             	mov    0x8(%ebp),%eax
80101f39:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f3d:	98                   	cwtl   
80101f3e:	8b 04 c5 e0 19 11 80 	mov    -0x7feee620(,%eax,8),%eax
80101f45:	8b 55 14             	mov    0x14(%ebp),%edx
80101f48:	83 ec 04             	sub    $0x4,%esp
80101f4b:	52                   	push   %edx
80101f4c:	ff 75 0c             	pushl  0xc(%ebp)
80101f4f:	ff 75 08             	pushl  0x8(%ebp)
80101f52:	ff d0                	call   *%eax
80101f54:	83 c4 10             	add    $0x10,%esp
80101f57:	e9 e6 00 00 00       	jmp    80102042 <readi+0x155>
  }

  if(off > ip->size || off + n < off)
80101f5c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f5f:	8b 40 58             	mov    0x58(%eax),%eax
80101f62:	39 45 10             	cmp    %eax,0x10(%ebp)
80101f65:	77 0d                	ja     80101f74 <readi+0x87>
80101f67:	8b 55 10             	mov    0x10(%ebp),%edx
80101f6a:	8b 45 14             	mov    0x14(%ebp),%eax
80101f6d:	01 d0                	add    %edx,%eax
80101f6f:	39 45 10             	cmp    %eax,0x10(%ebp)
80101f72:	76 0a                	jbe    80101f7e <readi+0x91>
    return -1;
80101f74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f79:	e9 c4 00 00 00       	jmp    80102042 <readi+0x155>
  if(off + n > ip->size)
80101f7e:	8b 55 10             	mov    0x10(%ebp),%edx
80101f81:	8b 45 14             	mov    0x14(%ebp),%eax
80101f84:	01 c2                	add    %eax,%edx
80101f86:	8b 45 08             	mov    0x8(%ebp),%eax
80101f89:	8b 40 58             	mov    0x58(%eax),%eax
80101f8c:	39 c2                	cmp    %eax,%edx
80101f8e:	76 0c                	jbe    80101f9c <readi+0xaf>
    n = ip->size - off;
80101f90:	8b 45 08             	mov    0x8(%ebp),%eax
80101f93:	8b 40 58             	mov    0x58(%eax),%eax
80101f96:	2b 45 10             	sub    0x10(%ebp),%eax
80101f99:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f9c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fa3:	e9 8b 00 00 00       	jmp    80102033 <readi+0x146>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fa8:	8b 45 10             	mov    0x10(%ebp),%eax
80101fab:	c1 e8 09             	shr    $0x9,%eax
80101fae:	83 ec 08             	sub    $0x8,%esp
80101fb1:	50                   	push   %eax
80101fb2:	ff 75 08             	pushl  0x8(%ebp)
80101fb5:	e8 9d fc ff ff       	call   80101c57 <bmap>
80101fba:	83 c4 10             	add    $0x10,%esp
80101fbd:	89 c2                	mov    %eax,%edx
80101fbf:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc2:	8b 00                	mov    (%eax),%eax
80101fc4:	83 ec 08             	sub    $0x8,%esp
80101fc7:	52                   	push   %edx
80101fc8:	50                   	push   %eax
80101fc9:	e8 00 e2 ff ff       	call   801001ce <bread>
80101fce:	83 c4 10             	add    $0x10,%esp
80101fd1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101fd4:	8b 45 10             	mov    0x10(%ebp),%eax
80101fd7:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fdc:	ba 00 02 00 00       	mov    $0x200,%edx
80101fe1:	29 c2                	sub    %eax,%edx
80101fe3:	8b 45 14             	mov    0x14(%ebp),%eax
80101fe6:	2b 45 f4             	sub    -0xc(%ebp),%eax
80101fe9:	39 c2                	cmp    %eax,%edx
80101feb:	0f 46 c2             	cmovbe %edx,%eax
80101fee:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101ff1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ff4:	8d 50 5c             	lea    0x5c(%eax),%edx
80101ff7:	8b 45 10             	mov    0x10(%ebp),%eax
80101ffa:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fff:	01 d0                	add    %edx,%eax
80102001:	83 ec 04             	sub    $0x4,%esp
80102004:	ff 75 ec             	pushl  -0x14(%ebp)
80102007:	50                   	push   %eax
80102008:	ff 75 0c             	pushl  0xc(%ebp)
8010200b:	e8 a5 32 00 00       	call   801052b5 <memmove>
80102010:	83 c4 10             	add    $0x10,%esp
    brelse(bp);
80102013:	83 ec 0c             	sub    $0xc,%esp
80102016:	ff 75 f0             	pushl  -0x10(%ebp)
80102019:	e8 32 e2 ff ff       	call   80100250 <brelse>
8010201e:	83 c4 10             	add    $0x10,%esp
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102021:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102024:	01 45 f4             	add    %eax,-0xc(%ebp)
80102027:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010202a:	01 45 10             	add    %eax,0x10(%ebp)
8010202d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102030:	01 45 0c             	add    %eax,0xc(%ebp)
80102033:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102036:	3b 45 14             	cmp    0x14(%ebp),%eax
80102039:	0f 82 69 ff ff ff    	jb     80101fa8 <readi+0xbb>
  }
  return n;
8010203f:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102042:	c9                   	leave  
80102043:	c3                   	ret    

80102044 <writei>:
// PAGEBREAK!
// Write data to inode.
// Caller must hold ip->lock.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102044:	55                   	push   %ebp
80102045:	89 e5                	mov    %esp,%ebp
80102047:	83 ec 18             	sub    $0x18,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
8010204a:	8b 45 08             	mov    0x8(%ebp),%eax
8010204d:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80102051:	66 83 f8 03          	cmp    $0x3,%ax
80102055:	75 5c                	jne    801020b3 <writei+0x6f>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102057:	8b 45 08             	mov    0x8(%ebp),%eax
8010205a:	0f b7 40 52          	movzwl 0x52(%eax),%eax
8010205e:	66 85 c0             	test   %ax,%ax
80102061:	78 20                	js     80102083 <writei+0x3f>
80102063:	8b 45 08             	mov    0x8(%ebp),%eax
80102066:	0f b7 40 52          	movzwl 0x52(%eax),%eax
8010206a:	66 83 f8 09          	cmp    $0x9,%ax
8010206e:	7f 13                	jg     80102083 <writei+0x3f>
80102070:	8b 45 08             	mov    0x8(%ebp),%eax
80102073:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80102077:	98                   	cwtl   
80102078:	8b 04 c5 e4 19 11 80 	mov    -0x7feee61c(,%eax,8),%eax
8010207f:	85 c0                	test   %eax,%eax
80102081:	75 0a                	jne    8010208d <writei+0x49>
      return -1;
80102083:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102088:	e9 3d 01 00 00       	jmp    801021ca <writei+0x186>
    return devsw[ip->major].write(ip, src, n);
8010208d:	8b 45 08             	mov    0x8(%ebp),%eax
80102090:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80102094:	98                   	cwtl   
80102095:	8b 04 c5 e4 19 11 80 	mov    -0x7feee61c(,%eax,8),%eax
8010209c:	8b 55 14             	mov    0x14(%ebp),%edx
8010209f:	83 ec 04             	sub    $0x4,%esp
801020a2:	52                   	push   %edx
801020a3:	ff 75 0c             	pushl  0xc(%ebp)
801020a6:	ff 75 08             	pushl  0x8(%ebp)
801020a9:	ff d0                	call   *%eax
801020ab:	83 c4 10             	add    $0x10,%esp
801020ae:	e9 17 01 00 00       	jmp    801021ca <writei+0x186>
  }

  if(off > ip->size || off + n < off)
801020b3:	8b 45 08             	mov    0x8(%ebp),%eax
801020b6:	8b 40 58             	mov    0x58(%eax),%eax
801020b9:	39 45 10             	cmp    %eax,0x10(%ebp)
801020bc:	77 0d                	ja     801020cb <writei+0x87>
801020be:	8b 55 10             	mov    0x10(%ebp),%edx
801020c1:	8b 45 14             	mov    0x14(%ebp),%eax
801020c4:	01 d0                	add    %edx,%eax
801020c6:	39 45 10             	cmp    %eax,0x10(%ebp)
801020c9:	76 0a                	jbe    801020d5 <writei+0x91>
    return -1;
801020cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020d0:	e9 f5 00 00 00       	jmp    801021ca <writei+0x186>
  if(off + n > MAXFILE*BSIZE)
801020d5:	8b 55 10             	mov    0x10(%ebp),%edx
801020d8:	8b 45 14             	mov    0x14(%ebp),%eax
801020db:	01 d0                	add    %edx,%eax
801020dd:	3d 00 18 01 00       	cmp    $0x11800,%eax
801020e2:	76 0a                	jbe    801020ee <writei+0xaa>
    return -1;
801020e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020e9:	e9 dc 00 00 00       	jmp    801021ca <writei+0x186>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801020ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020f5:	e9 99 00 00 00       	jmp    80102193 <writei+0x14f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801020fa:	8b 45 10             	mov    0x10(%ebp),%eax
801020fd:	c1 e8 09             	shr    $0x9,%eax
80102100:	83 ec 08             	sub    $0x8,%esp
80102103:	50                   	push   %eax
80102104:	ff 75 08             	pushl  0x8(%ebp)
80102107:	e8 4b fb ff ff       	call   80101c57 <bmap>
8010210c:	83 c4 10             	add    $0x10,%esp
8010210f:	89 c2                	mov    %eax,%edx
80102111:	8b 45 08             	mov    0x8(%ebp),%eax
80102114:	8b 00                	mov    (%eax),%eax
80102116:	83 ec 08             	sub    $0x8,%esp
80102119:	52                   	push   %edx
8010211a:	50                   	push   %eax
8010211b:	e8 ae e0 ff ff       	call   801001ce <bread>
80102120:	83 c4 10             	add    $0x10,%esp
80102123:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102126:	8b 45 10             	mov    0x10(%ebp),%eax
80102129:	25 ff 01 00 00       	and    $0x1ff,%eax
8010212e:	ba 00 02 00 00       	mov    $0x200,%edx
80102133:	29 c2                	sub    %eax,%edx
80102135:	8b 45 14             	mov    0x14(%ebp),%eax
80102138:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010213b:	39 c2                	cmp    %eax,%edx
8010213d:	0f 46 c2             	cmovbe %edx,%eax
80102140:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102143:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102146:	8d 50 5c             	lea    0x5c(%eax),%edx
80102149:	8b 45 10             	mov    0x10(%ebp),%eax
8010214c:	25 ff 01 00 00       	and    $0x1ff,%eax
80102151:	01 d0                	add    %edx,%eax
80102153:	83 ec 04             	sub    $0x4,%esp
80102156:	ff 75 ec             	pushl  -0x14(%ebp)
80102159:	ff 75 0c             	pushl  0xc(%ebp)
8010215c:	50                   	push   %eax
8010215d:	e8 53 31 00 00       	call   801052b5 <memmove>
80102162:	83 c4 10             	add    $0x10,%esp
    log_write(bp);
80102165:	83 ec 0c             	sub    $0xc,%esp
80102168:	ff 75 f0             	pushl  -0x10(%ebp)
8010216b:	e8 eb 15 00 00       	call   8010375b <log_write>
80102170:	83 c4 10             	add    $0x10,%esp
    brelse(bp);
80102173:	83 ec 0c             	sub    $0xc,%esp
80102176:	ff 75 f0             	pushl  -0x10(%ebp)
80102179:	e8 d2 e0 ff ff       	call   80100250 <brelse>
8010217e:	83 c4 10             	add    $0x10,%esp
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102181:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102184:	01 45 f4             	add    %eax,-0xc(%ebp)
80102187:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010218a:	01 45 10             	add    %eax,0x10(%ebp)
8010218d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102190:	01 45 0c             	add    %eax,0xc(%ebp)
80102193:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102196:	3b 45 14             	cmp    0x14(%ebp),%eax
80102199:	0f 82 5b ff ff ff    	jb     801020fa <writei+0xb6>
  }

  if(n > 0 && off > ip->size){
8010219f:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801021a3:	74 22                	je     801021c7 <writei+0x183>
801021a5:	8b 45 08             	mov    0x8(%ebp),%eax
801021a8:	8b 40 58             	mov    0x58(%eax),%eax
801021ab:	39 45 10             	cmp    %eax,0x10(%ebp)
801021ae:	76 17                	jbe    801021c7 <writei+0x183>
    ip->size = off;
801021b0:	8b 45 08             	mov    0x8(%ebp),%eax
801021b3:	8b 55 10             	mov    0x10(%ebp),%edx
801021b6:	89 50 58             	mov    %edx,0x58(%eax)
    iupdate(ip);
801021b9:	83 ec 0c             	sub    $0xc,%esp
801021bc:	ff 75 08             	pushl  0x8(%ebp)
801021bf:	e8 60 f6 ff ff       	call   80101824 <iupdate>
801021c4:	83 c4 10             	add    $0x10,%esp
  }
  return n;
801021c7:	8b 45 14             	mov    0x14(%ebp),%eax
}
801021ca:	c9                   	leave  
801021cb:	c3                   	ret    

801021cc <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801021cc:	55                   	push   %ebp
801021cd:	89 e5                	mov    %esp,%ebp
801021cf:	83 ec 08             	sub    $0x8,%esp
  return strncmp(s, t, DIRSIZ);
801021d2:	83 ec 04             	sub    $0x4,%esp
801021d5:	6a 0e                	push   $0xe
801021d7:	ff 75 0c             	pushl  0xc(%ebp)
801021da:	ff 75 08             	pushl  0x8(%ebp)
801021dd:	e8 69 31 00 00       	call   8010534b <strncmp>
801021e2:	83 c4 10             	add    $0x10,%esp
}
801021e5:	c9                   	leave  
801021e6:	c3                   	ret    

801021e7 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801021e7:	55                   	push   %ebp
801021e8:	89 e5                	mov    %esp,%ebp
801021ea:	83 ec 28             	sub    $0x28,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801021ed:	8b 45 08             	mov    0x8(%ebp),%eax
801021f0:	0f b7 40 50          	movzwl 0x50(%eax),%eax
801021f4:	66 83 f8 01          	cmp    $0x1,%ax
801021f8:	74 0d                	je     80102207 <dirlookup+0x20>
    panic("dirlookup not DIR");
801021fa:	83 ec 0c             	sub    $0xc,%esp
801021fd:	68 f1 84 10 80       	push   $0x801084f1
80102202:	e8 95 e3 ff ff       	call   8010059c <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102207:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010220e:	eb 7b                	jmp    8010228b <dirlookup+0xa4>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102210:	6a 10                	push   $0x10
80102212:	ff 75 f4             	pushl  -0xc(%ebp)
80102215:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102218:	50                   	push   %eax
80102219:	ff 75 08             	pushl  0x8(%ebp)
8010221c:	e8 cc fc ff ff       	call   80101eed <readi>
80102221:	83 c4 10             	add    $0x10,%esp
80102224:	83 f8 10             	cmp    $0x10,%eax
80102227:	74 0d                	je     80102236 <dirlookup+0x4f>
      panic("dirlookup read");
80102229:	83 ec 0c             	sub    $0xc,%esp
8010222c:	68 03 85 10 80       	push   $0x80108503
80102231:	e8 66 e3 ff ff       	call   8010059c <panic>
    if(de.inum == 0)
80102236:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010223a:	66 85 c0             	test   %ax,%ax
8010223d:	74 47                	je     80102286 <dirlookup+0x9f>
      continue;
    if(namecmp(name, de.name) == 0){
8010223f:	83 ec 08             	sub    $0x8,%esp
80102242:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102245:	83 c0 02             	add    $0x2,%eax
80102248:	50                   	push   %eax
80102249:	ff 75 0c             	pushl  0xc(%ebp)
8010224c:	e8 7b ff ff ff       	call   801021cc <namecmp>
80102251:	83 c4 10             	add    $0x10,%esp
80102254:	85 c0                	test   %eax,%eax
80102256:	75 2f                	jne    80102287 <dirlookup+0xa0>
      // entry matches path element
      if(poff)
80102258:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010225c:	74 08                	je     80102266 <dirlookup+0x7f>
        *poff = off;
8010225e:	8b 45 10             	mov    0x10(%ebp),%eax
80102261:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102264:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102266:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010226a:	0f b7 c0             	movzwl %ax,%eax
8010226d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102270:	8b 45 08             	mov    0x8(%ebp),%eax
80102273:	8b 00                	mov    (%eax),%eax
80102275:	83 ec 08             	sub    $0x8,%esp
80102278:	ff 75 f0             	pushl  -0x10(%ebp)
8010227b:	50                   	push   %eax
8010227c:	e8 64 f6 ff ff       	call   801018e5 <iget>
80102281:	83 c4 10             	add    $0x10,%esp
80102284:	eb 19                	jmp    8010229f <dirlookup+0xb8>
      continue;
80102286:	90                   	nop
  for(off = 0; off < dp->size; off += sizeof(de)){
80102287:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010228b:	8b 45 08             	mov    0x8(%ebp),%eax
8010228e:	8b 40 58             	mov    0x58(%eax),%eax
80102291:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80102294:	0f 82 76 ff ff ff    	jb     80102210 <dirlookup+0x29>
    }
  }

  return 0;
8010229a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010229f:	c9                   	leave  
801022a0:	c3                   	ret    

801022a1 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801022a1:	55                   	push   %ebp
801022a2:	89 e5                	mov    %esp,%ebp
801022a4:	83 ec 28             	sub    $0x28,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801022a7:	83 ec 04             	sub    $0x4,%esp
801022aa:	6a 00                	push   $0x0
801022ac:	ff 75 0c             	pushl  0xc(%ebp)
801022af:	ff 75 08             	pushl  0x8(%ebp)
801022b2:	e8 30 ff ff ff       	call   801021e7 <dirlookup>
801022b7:	83 c4 10             	add    $0x10,%esp
801022ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
801022bd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801022c1:	74 18                	je     801022db <dirlink+0x3a>
    iput(ip);
801022c3:	83 ec 0c             	sub    $0xc,%esp
801022c6:	ff 75 f0             	pushl  -0x10(%ebp)
801022c9:	e8 94 f8 ff ff       	call   80101b62 <iput>
801022ce:	83 c4 10             	add    $0x10,%esp
    return -1;
801022d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022d6:	e9 9c 00 00 00       	jmp    80102377 <dirlink+0xd6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801022db:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801022e2:	eb 39                	jmp    8010231d <dirlink+0x7c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801022e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022e7:	6a 10                	push   $0x10
801022e9:	50                   	push   %eax
801022ea:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022ed:	50                   	push   %eax
801022ee:	ff 75 08             	pushl  0x8(%ebp)
801022f1:	e8 f7 fb ff ff       	call   80101eed <readi>
801022f6:	83 c4 10             	add    $0x10,%esp
801022f9:	83 f8 10             	cmp    $0x10,%eax
801022fc:	74 0d                	je     8010230b <dirlink+0x6a>
      panic("dirlink read");
801022fe:	83 ec 0c             	sub    $0xc,%esp
80102301:	68 12 85 10 80       	push   $0x80108512
80102306:	e8 91 e2 ff ff       	call   8010059c <panic>
    if(de.inum == 0)
8010230b:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010230f:	66 85 c0             	test   %ax,%ax
80102312:	74 18                	je     8010232c <dirlink+0x8b>
  for(off = 0; off < dp->size; off += sizeof(de)){
80102314:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102317:	83 c0 10             	add    $0x10,%eax
8010231a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010231d:	8b 45 08             	mov    0x8(%ebp),%eax
80102320:	8b 50 58             	mov    0x58(%eax),%edx
80102323:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102326:	39 c2                	cmp    %eax,%edx
80102328:	77 ba                	ja     801022e4 <dirlink+0x43>
8010232a:	eb 01                	jmp    8010232d <dirlink+0x8c>
      break;
8010232c:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
8010232d:	83 ec 04             	sub    $0x4,%esp
80102330:	6a 0e                	push   $0xe
80102332:	ff 75 0c             	pushl  0xc(%ebp)
80102335:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102338:	83 c0 02             	add    $0x2,%eax
8010233b:	50                   	push   %eax
8010233c:	e8 60 30 00 00       	call   801053a1 <strncpy>
80102341:	83 c4 10             	add    $0x10,%esp
  de.inum = inum;
80102344:	8b 45 10             	mov    0x10(%ebp),%eax
80102347:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010234b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010234e:	6a 10                	push   $0x10
80102350:	50                   	push   %eax
80102351:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102354:	50                   	push   %eax
80102355:	ff 75 08             	pushl  0x8(%ebp)
80102358:	e8 e7 fc ff ff       	call   80102044 <writei>
8010235d:	83 c4 10             	add    $0x10,%esp
80102360:	83 f8 10             	cmp    $0x10,%eax
80102363:	74 0d                	je     80102372 <dirlink+0xd1>
    panic("dirlink");
80102365:	83 ec 0c             	sub    $0xc,%esp
80102368:	68 1f 85 10 80       	push   $0x8010851f
8010236d:	e8 2a e2 ff ff       	call   8010059c <panic>

  return 0;
80102372:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102377:	c9                   	leave  
80102378:	c3                   	ret    

80102379 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102379:	55                   	push   %ebp
8010237a:	89 e5                	mov    %esp,%ebp
8010237c:	83 ec 18             	sub    $0x18,%esp
  char *s;
  int len;

  while(*path == '/')
8010237f:	eb 04                	jmp    80102385 <skipelem+0xc>
    path++;
80102381:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
80102385:	8b 45 08             	mov    0x8(%ebp),%eax
80102388:	0f b6 00             	movzbl (%eax),%eax
8010238b:	3c 2f                	cmp    $0x2f,%al
8010238d:	74 f2                	je     80102381 <skipelem+0x8>
  if(*path == 0)
8010238f:	8b 45 08             	mov    0x8(%ebp),%eax
80102392:	0f b6 00             	movzbl (%eax),%eax
80102395:	84 c0                	test   %al,%al
80102397:	75 07                	jne    801023a0 <skipelem+0x27>
    return 0;
80102399:	b8 00 00 00 00       	mov    $0x0,%eax
8010239e:	eb 7b                	jmp    8010241b <skipelem+0xa2>
  s = path;
801023a0:	8b 45 08             	mov    0x8(%ebp),%eax
801023a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801023a6:	eb 04                	jmp    801023ac <skipelem+0x33>
    path++;
801023a8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path != '/' && *path != 0)
801023ac:	8b 45 08             	mov    0x8(%ebp),%eax
801023af:	0f b6 00             	movzbl (%eax),%eax
801023b2:	3c 2f                	cmp    $0x2f,%al
801023b4:	74 0a                	je     801023c0 <skipelem+0x47>
801023b6:	8b 45 08             	mov    0x8(%ebp),%eax
801023b9:	0f b6 00             	movzbl (%eax),%eax
801023bc:	84 c0                	test   %al,%al
801023be:	75 e8                	jne    801023a8 <skipelem+0x2f>
  len = path - s;
801023c0:	8b 55 08             	mov    0x8(%ebp),%edx
801023c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023c6:	29 c2                	sub    %eax,%edx
801023c8:	89 d0                	mov    %edx,%eax
801023ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801023cd:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801023d1:	7e 15                	jle    801023e8 <skipelem+0x6f>
    memmove(name, s, DIRSIZ);
801023d3:	83 ec 04             	sub    $0x4,%esp
801023d6:	6a 0e                	push   $0xe
801023d8:	ff 75 f4             	pushl  -0xc(%ebp)
801023db:	ff 75 0c             	pushl  0xc(%ebp)
801023de:	e8 d2 2e 00 00       	call   801052b5 <memmove>
801023e3:	83 c4 10             	add    $0x10,%esp
801023e6:	eb 26                	jmp    8010240e <skipelem+0x95>
  else {
    memmove(name, s, len);
801023e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023eb:	83 ec 04             	sub    $0x4,%esp
801023ee:	50                   	push   %eax
801023ef:	ff 75 f4             	pushl  -0xc(%ebp)
801023f2:	ff 75 0c             	pushl  0xc(%ebp)
801023f5:	e8 bb 2e 00 00       	call   801052b5 <memmove>
801023fa:	83 c4 10             	add    $0x10,%esp
    name[len] = 0;
801023fd:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102400:	8b 45 0c             	mov    0xc(%ebp),%eax
80102403:	01 d0                	add    %edx,%eax
80102405:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102408:	eb 04                	jmp    8010240e <skipelem+0x95>
    path++;
8010240a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
8010240e:	8b 45 08             	mov    0x8(%ebp),%eax
80102411:	0f b6 00             	movzbl (%eax),%eax
80102414:	3c 2f                	cmp    $0x2f,%al
80102416:	74 f2                	je     8010240a <skipelem+0x91>
  return path;
80102418:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010241b:	c9                   	leave  
8010241c:	c3                   	ret    

8010241d <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
8010241d:	55                   	push   %ebp
8010241e:	89 e5                	mov    %esp,%ebp
80102420:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102423:	8b 45 08             	mov    0x8(%ebp),%eax
80102426:	0f b6 00             	movzbl (%eax),%eax
80102429:	3c 2f                	cmp    $0x2f,%al
8010242b:	75 17                	jne    80102444 <namex+0x27>
    ip = iget(ROOTDEV, ROOTINO);
8010242d:	83 ec 08             	sub    $0x8,%esp
80102430:	6a 01                	push   $0x1
80102432:	6a 01                	push   $0x1
80102434:	e8 ac f4 ff ff       	call   801018e5 <iget>
80102439:	83 c4 10             	add    $0x10,%esp
8010243c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010243f:	e9 ba 00 00 00       	jmp    801024fe <namex+0xe1>
  else
    ip = idup(myproc()->cwd);
80102444:	e8 30 1e 00 00       	call   80104279 <myproc>
80102449:	8b 40 68             	mov    0x68(%eax),%eax
8010244c:	83 ec 0c             	sub    $0xc,%esp
8010244f:	50                   	push   %eax
80102450:	e8 72 f5 ff ff       	call   801019c7 <idup>
80102455:	83 c4 10             	add    $0x10,%esp
80102458:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010245b:	e9 9e 00 00 00       	jmp    801024fe <namex+0xe1>
    ilock(ip);
80102460:	83 ec 0c             	sub    $0xc,%esp
80102463:	ff 75 f4             	pushl  -0xc(%ebp)
80102466:	e8 96 f5 ff ff       	call   80101a01 <ilock>
8010246b:	83 c4 10             	add    $0x10,%esp
    if(ip->type != T_DIR){
8010246e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102471:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80102475:	66 83 f8 01          	cmp    $0x1,%ax
80102479:	74 18                	je     80102493 <namex+0x76>
      iunlockput(ip);
8010247b:	83 ec 0c             	sub    $0xc,%esp
8010247e:	ff 75 f4             	pushl  -0xc(%ebp)
80102481:	e8 ac f7 ff ff       	call   80101c32 <iunlockput>
80102486:	83 c4 10             	add    $0x10,%esp
      return 0;
80102489:	b8 00 00 00 00       	mov    $0x0,%eax
8010248e:	e9 a7 00 00 00       	jmp    8010253a <namex+0x11d>
    }
    if(nameiparent && *path == '\0'){
80102493:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102497:	74 20                	je     801024b9 <namex+0x9c>
80102499:	8b 45 08             	mov    0x8(%ebp),%eax
8010249c:	0f b6 00             	movzbl (%eax),%eax
8010249f:	84 c0                	test   %al,%al
801024a1:	75 16                	jne    801024b9 <namex+0x9c>
      // Stop one level early.
      iunlock(ip);
801024a3:	83 ec 0c             	sub    $0xc,%esp
801024a6:	ff 75 f4             	pushl  -0xc(%ebp)
801024a9:	e8 66 f6 ff ff       	call   80101b14 <iunlock>
801024ae:	83 c4 10             	add    $0x10,%esp
      return ip;
801024b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024b4:	e9 81 00 00 00       	jmp    8010253a <namex+0x11d>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801024b9:	83 ec 04             	sub    $0x4,%esp
801024bc:	6a 00                	push   $0x0
801024be:	ff 75 10             	pushl  0x10(%ebp)
801024c1:	ff 75 f4             	pushl  -0xc(%ebp)
801024c4:	e8 1e fd ff ff       	call   801021e7 <dirlookup>
801024c9:	83 c4 10             	add    $0x10,%esp
801024cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
801024cf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801024d3:	75 15                	jne    801024ea <namex+0xcd>
      iunlockput(ip);
801024d5:	83 ec 0c             	sub    $0xc,%esp
801024d8:	ff 75 f4             	pushl  -0xc(%ebp)
801024db:	e8 52 f7 ff ff       	call   80101c32 <iunlockput>
801024e0:	83 c4 10             	add    $0x10,%esp
      return 0;
801024e3:	b8 00 00 00 00       	mov    $0x0,%eax
801024e8:	eb 50                	jmp    8010253a <namex+0x11d>
    }
    iunlockput(ip);
801024ea:	83 ec 0c             	sub    $0xc,%esp
801024ed:	ff 75 f4             	pushl  -0xc(%ebp)
801024f0:	e8 3d f7 ff ff       	call   80101c32 <iunlockput>
801024f5:	83 c4 10             	add    $0x10,%esp
    ip = next;
801024f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while((path = skipelem(path, name)) != 0){
801024fe:	83 ec 08             	sub    $0x8,%esp
80102501:	ff 75 10             	pushl  0x10(%ebp)
80102504:	ff 75 08             	pushl  0x8(%ebp)
80102507:	e8 6d fe ff ff       	call   80102379 <skipelem>
8010250c:	83 c4 10             	add    $0x10,%esp
8010250f:	89 45 08             	mov    %eax,0x8(%ebp)
80102512:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102516:	0f 85 44 ff ff ff    	jne    80102460 <namex+0x43>
  }
  if(nameiparent){
8010251c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102520:	74 15                	je     80102537 <namex+0x11a>
    iput(ip);
80102522:	83 ec 0c             	sub    $0xc,%esp
80102525:	ff 75 f4             	pushl  -0xc(%ebp)
80102528:	e8 35 f6 ff ff       	call   80101b62 <iput>
8010252d:	83 c4 10             	add    $0x10,%esp
    return 0;
80102530:	b8 00 00 00 00       	mov    $0x0,%eax
80102535:	eb 03                	jmp    8010253a <namex+0x11d>
  }
  return ip;
80102537:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010253a:	c9                   	leave  
8010253b:	c3                   	ret    

8010253c <namei>:

struct inode*
namei(char *path)
{
8010253c:	55                   	push   %ebp
8010253d:	89 e5                	mov    %esp,%ebp
8010253f:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102542:	83 ec 04             	sub    $0x4,%esp
80102545:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102548:	50                   	push   %eax
80102549:	6a 00                	push   $0x0
8010254b:	ff 75 08             	pushl  0x8(%ebp)
8010254e:	e8 ca fe ff ff       	call   8010241d <namex>
80102553:	83 c4 10             	add    $0x10,%esp
}
80102556:	c9                   	leave  
80102557:	c3                   	ret    

80102558 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102558:	55                   	push   %ebp
80102559:	89 e5                	mov    %esp,%ebp
8010255b:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
8010255e:	83 ec 04             	sub    $0x4,%esp
80102561:	ff 75 0c             	pushl  0xc(%ebp)
80102564:	6a 01                	push   $0x1
80102566:	ff 75 08             	pushl  0x8(%ebp)
80102569:	e8 af fe ff ff       	call   8010241d <namex>
8010256e:	83 c4 10             	add    $0x10,%esp
}
80102571:	c9                   	leave  
80102572:	c3                   	ret    

80102573 <inb>:
{
80102573:	55                   	push   %ebp
80102574:	89 e5                	mov    %esp,%ebp
80102576:	83 ec 14             	sub    $0x14,%esp
80102579:	8b 45 08             	mov    0x8(%ebp),%eax
8010257c:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102580:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102584:	89 c2                	mov    %eax,%edx
80102586:	ec                   	in     (%dx),%al
80102587:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010258a:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010258e:	c9                   	leave  
8010258f:	c3                   	ret    

80102590 <insl>:
{
80102590:	55                   	push   %ebp
80102591:	89 e5                	mov    %esp,%ebp
80102593:	57                   	push   %edi
80102594:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102595:	8b 55 08             	mov    0x8(%ebp),%edx
80102598:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010259b:	8b 45 10             	mov    0x10(%ebp),%eax
8010259e:	89 cb                	mov    %ecx,%ebx
801025a0:	89 df                	mov    %ebx,%edi
801025a2:	89 c1                	mov    %eax,%ecx
801025a4:	fc                   	cld    
801025a5:	f3 6d                	rep insl (%dx),%es:(%edi)
801025a7:	89 c8                	mov    %ecx,%eax
801025a9:	89 fb                	mov    %edi,%ebx
801025ab:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025ae:	89 45 10             	mov    %eax,0x10(%ebp)
}
801025b1:	90                   	nop
801025b2:	5b                   	pop    %ebx
801025b3:	5f                   	pop    %edi
801025b4:	5d                   	pop    %ebp
801025b5:	c3                   	ret    

801025b6 <outb>:
{
801025b6:	55                   	push   %ebp
801025b7:	89 e5                	mov    %esp,%ebp
801025b9:	83 ec 08             	sub    $0x8,%esp
801025bc:	8b 55 08             	mov    0x8(%ebp),%edx
801025bf:	8b 45 0c             	mov    0xc(%ebp),%eax
801025c2:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801025c6:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801025c9:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801025cd:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801025d1:	ee                   	out    %al,(%dx)
}
801025d2:	90                   	nop
801025d3:	c9                   	leave  
801025d4:	c3                   	ret    

801025d5 <outsl>:
{
801025d5:	55                   	push   %ebp
801025d6:	89 e5                	mov    %esp,%ebp
801025d8:	56                   	push   %esi
801025d9:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801025da:	8b 55 08             	mov    0x8(%ebp),%edx
801025dd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025e0:	8b 45 10             	mov    0x10(%ebp),%eax
801025e3:	89 cb                	mov    %ecx,%ebx
801025e5:	89 de                	mov    %ebx,%esi
801025e7:	89 c1                	mov    %eax,%ecx
801025e9:	fc                   	cld    
801025ea:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801025ec:	89 c8                	mov    %ecx,%eax
801025ee:	89 f3                	mov    %esi,%ebx
801025f0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025f3:	89 45 10             	mov    %eax,0x10(%ebp)
}
801025f6:	90                   	nop
801025f7:	5b                   	pop    %ebx
801025f8:	5e                   	pop    %esi
801025f9:	5d                   	pop    %ebp
801025fa:	c3                   	ret    

801025fb <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801025fb:	55                   	push   %ebp
801025fc:	89 e5                	mov    %esp,%ebp
801025fe:	83 ec 10             	sub    $0x10,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80102601:	90                   	nop
80102602:	68 f7 01 00 00       	push   $0x1f7
80102607:	e8 67 ff ff ff       	call   80102573 <inb>
8010260c:	83 c4 04             	add    $0x4,%esp
8010260f:	0f b6 c0             	movzbl %al,%eax
80102612:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102615:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102618:	25 c0 00 00 00       	and    $0xc0,%eax
8010261d:	83 f8 40             	cmp    $0x40,%eax
80102620:	75 e0                	jne    80102602 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102622:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102626:	74 11                	je     80102639 <idewait+0x3e>
80102628:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010262b:	83 e0 21             	and    $0x21,%eax
8010262e:	85 c0                	test   %eax,%eax
80102630:	74 07                	je     80102639 <idewait+0x3e>
    return -1;
80102632:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102637:	eb 05                	jmp    8010263e <idewait+0x43>
  return 0;
80102639:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010263e:	c9                   	leave  
8010263f:	c3                   	ret    

80102640 <ideinit>:

void
ideinit(void)
{
80102640:	55                   	push   %ebp
80102641:	89 e5                	mov    %esp,%ebp
80102643:	83 ec 18             	sub    $0x18,%esp
  int i;

  initlock(&idelock, "ide");
80102646:	83 ec 08             	sub    $0x8,%esp
80102649:	68 27 85 10 80       	push   $0x80108527
8010264e:	68 e0 b5 10 80       	push   $0x8010b5e0
80102653:	e8 f5 28 00 00       	call   80104f4d <initlock>
80102658:	83 c4 10             	add    $0x10,%esp
  ioapicenable(IRQ_IDE, ncpu - 1);
8010265b:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80102660:	83 e8 01             	sub    $0x1,%eax
80102663:	83 ec 08             	sub    $0x8,%esp
80102666:	50                   	push   %eax
80102667:	6a 0e                	push   $0xe
80102669:	e8 a2 04 00 00       	call   80102b10 <ioapicenable>
8010266e:	83 c4 10             	add    $0x10,%esp
  idewait(0);
80102671:	83 ec 0c             	sub    $0xc,%esp
80102674:	6a 00                	push   $0x0
80102676:	e8 80 ff ff ff       	call   801025fb <idewait>
8010267b:	83 c4 10             	add    $0x10,%esp

  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
8010267e:	83 ec 08             	sub    $0x8,%esp
80102681:	68 f0 00 00 00       	push   $0xf0
80102686:	68 f6 01 00 00       	push   $0x1f6
8010268b:	e8 26 ff ff ff       	call   801025b6 <outb>
80102690:	83 c4 10             	add    $0x10,%esp
  for(i=0; i<1000; i++){
80102693:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010269a:	eb 24                	jmp    801026c0 <ideinit+0x80>
    if(inb(0x1f7) != 0){
8010269c:	83 ec 0c             	sub    $0xc,%esp
8010269f:	68 f7 01 00 00       	push   $0x1f7
801026a4:	e8 ca fe ff ff       	call   80102573 <inb>
801026a9:	83 c4 10             	add    $0x10,%esp
801026ac:	84 c0                	test   %al,%al
801026ae:	74 0c                	je     801026bc <ideinit+0x7c>
      havedisk1 = 1;
801026b0:	c7 05 18 b6 10 80 01 	movl   $0x1,0x8010b618
801026b7:	00 00 00 
      break;
801026ba:	eb 0d                	jmp    801026c9 <ideinit+0x89>
  for(i=0; i<1000; i++){
801026bc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801026c0:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801026c7:	7e d3                	jle    8010269c <ideinit+0x5c>
    }
  }

  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801026c9:	83 ec 08             	sub    $0x8,%esp
801026cc:	68 e0 00 00 00       	push   $0xe0
801026d1:	68 f6 01 00 00       	push   $0x1f6
801026d6:	e8 db fe ff ff       	call   801025b6 <outb>
801026db:	83 c4 10             	add    $0x10,%esp
}
801026de:	90                   	nop
801026df:	c9                   	leave  
801026e0:	c3                   	ret    

801026e1 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801026e1:	55                   	push   %ebp
801026e2:	89 e5                	mov    %esp,%ebp
801026e4:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801026e7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026eb:	75 0d                	jne    801026fa <idestart+0x19>
    panic("idestart");
801026ed:	83 ec 0c             	sub    $0xc,%esp
801026f0:	68 2b 85 10 80       	push   $0x8010852b
801026f5:	e8 a2 de ff ff       	call   8010059c <panic>
  if(b->blockno >= FSSIZE)
801026fa:	8b 45 08             	mov    0x8(%ebp),%eax
801026fd:	8b 40 08             	mov    0x8(%eax),%eax
80102700:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102705:	76 0d                	jbe    80102714 <idestart+0x33>
    panic("incorrect blockno");
80102707:	83 ec 0c             	sub    $0xc,%esp
8010270a:	68 34 85 10 80       	push   $0x80108534
8010270f:	e8 88 de ff ff       	call   8010059c <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102714:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
8010271b:	8b 45 08             	mov    0x8(%ebp),%eax
8010271e:	8b 50 08             	mov    0x8(%eax),%edx
80102721:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102724:	0f af c2             	imul   %edx,%eax
80102727:	89 45 f0             	mov    %eax,-0x10(%ebp)
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
8010272a:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
8010272e:	75 07                	jne    80102737 <idestart+0x56>
80102730:	b8 20 00 00 00       	mov    $0x20,%eax
80102735:	eb 05                	jmp    8010273c <idestart+0x5b>
80102737:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010273c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;
8010273f:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80102743:	75 07                	jne    8010274c <idestart+0x6b>
80102745:	b8 30 00 00 00       	mov    $0x30,%eax
8010274a:	eb 05                	jmp    80102751 <idestart+0x70>
8010274c:	b8 c5 00 00 00       	mov    $0xc5,%eax
80102751:	89 45 e8             	mov    %eax,-0x18(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102754:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102758:	7e 0d                	jle    80102767 <idestart+0x86>
8010275a:	83 ec 0c             	sub    $0xc,%esp
8010275d:	68 2b 85 10 80       	push   $0x8010852b
80102762:	e8 35 de ff ff       	call   8010059c <panic>

  idewait(0);
80102767:	83 ec 0c             	sub    $0xc,%esp
8010276a:	6a 00                	push   $0x0
8010276c:	e8 8a fe ff ff       	call   801025fb <idewait>
80102771:	83 c4 10             	add    $0x10,%esp
  outb(0x3f6, 0);  // generate interrupt
80102774:	83 ec 08             	sub    $0x8,%esp
80102777:	6a 00                	push   $0x0
80102779:	68 f6 03 00 00       	push   $0x3f6
8010277e:	e8 33 fe ff ff       	call   801025b6 <outb>
80102783:	83 c4 10             	add    $0x10,%esp
  outb(0x1f2, sector_per_block);  // number of sectors
80102786:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102789:	0f b6 c0             	movzbl %al,%eax
8010278c:	83 ec 08             	sub    $0x8,%esp
8010278f:	50                   	push   %eax
80102790:	68 f2 01 00 00       	push   $0x1f2
80102795:	e8 1c fe ff ff       	call   801025b6 <outb>
8010279a:	83 c4 10             	add    $0x10,%esp
  outb(0x1f3, sector & 0xff);
8010279d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027a0:	0f b6 c0             	movzbl %al,%eax
801027a3:	83 ec 08             	sub    $0x8,%esp
801027a6:	50                   	push   %eax
801027a7:	68 f3 01 00 00       	push   $0x1f3
801027ac:	e8 05 fe ff ff       	call   801025b6 <outb>
801027b1:	83 c4 10             	add    $0x10,%esp
  outb(0x1f4, (sector >> 8) & 0xff);
801027b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027b7:	c1 f8 08             	sar    $0x8,%eax
801027ba:	0f b6 c0             	movzbl %al,%eax
801027bd:	83 ec 08             	sub    $0x8,%esp
801027c0:	50                   	push   %eax
801027c1:	68 f4 01 00 00       	push   $0x1f4
801027c6:	e8 eb fd ff ff       	call   801025b6 <outb>
801027cb:	83 c4 10             	add    $0x10,%esp
  outb(0x1f5, (sector >> 16) & 0xff);
801027ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027d1:	c1 f8 10             	sar    $0x10,%eax
801027d4:	0f b6 c0             	movzbl %al,%eax
801027d7:	83 ec 08             	sub    $0x8,%esp
801027da:	50                   	push   %eax
801027db:	68 f5 01 00 00       	push   $0x1f5
801027e0:	e8 d1 fd ff ff       	call   801025b6 <outb>
801027e5:	83 c4 10             	add    $0x10,%esp
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
801027e8:	8b 45 08             	mov    0x8(%ebp),%eax
801027eb:	8b 40 04             	mov    0x4(%eax),%eax
801027ee:	c1 e0 04             	shl    $0x4,%eax
801027f1:	83 e0 10             	and    $0x10,%eax
801027f4:	89 c2                	mov    %eax,%edx
801027f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027f9:	c1 f8 18             	sar    $0x18,%eax
801027fc:	83 e0 0f             	and    $0xf,%eax
801027ff:	09 d0                	or     %edx,%eax
80102801:	83 c8 e0             	or     $0xffffffe0,%eax
80102804:	0f b6 c0             	movzbl %al,%eax
80102807:	83 ec 08             	sub    $0x8,%esp
8010280a:	50                   	push   %eax
8010280b:	68 f6 01 00 00       	push   $0x1f6
80102810:	e8 a1 fd ff ff       	call   801025b6 <outb>
80102815:	83 c4 10             	add    $0x10,%esp
  if(b->flags & B_DIRTY){
80102818:	8b 45 08             	mov    0x8(%ebp),%eax
8010281b:	8b 00                	mov    (%eax),%eax
8010281d:	83 e0 04             	and    $0x4,%eax
80102820:	85 c0                	test   %eax,%eax
80102822:	74 35                	je     80102859 <idestart+0x178>
    outb(0x1f7, write_cmd);
80102824:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102827:	0f b6 c0             	movzbl %al,%eax
8010282a:	83 ec 08             	sub    $0x8,%esp
8010282d:	50                   	push   %eax
8010282e:	68 f7 01 00 00       	push   $0x1f7
80102833:	e8 7e fd ff ff       	call   801025b6 <outb>
80102838:	83 c4 10             	add    $0x10,%esp
    outsl(0x1f0, b->data, BSIZE/4);
8010283b:	8b 45 08             	mov    0x8(%ebp),%eax
8010283e:	83 c0 5c             	add    $0x5c,%eax
80102841:	83 ec 04             	sub    $0x4,%esp
80102844:	68 80 00 00 00       	push   $0x80
80102849:	50                   	push   %eax
8010284a:	68 f0 01 00 00       	push   $0x1f0
8010284f:	e8 81 fd ff ff       	call   801025d5 <outsl>
80102854:	83 c4 10             	add    $0x10,%esp
  } else {
    outb(0x1f7, read_cmd);
  }
}
80102857:	eb 17                	jmp    80102870 <idestart+0x18f>
    outb(0x1f7, read_cmd);
80102859:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010285c:	0f b6 c0             	movzbl %al,%eax
8010285f:	83 ec 08             	sub    $0x8,%esp
80102862:	50                   	push   %eax
80102863:	68 f7 01 00 00       	push   $0x1f7
80102868:	e8 49 fd ff ff       	call   801025b6 <outb>
8010286d:	83 c4 10             	add    $0x10,%esp
}
80102870:	90                   	nop
80102871:	c9                   	leave  
80102872:	c3                   	ret    

80102873 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102873:	55                   	push   %ebp
80102874:	89 e5                	mov    %esp,%ebp
80102876:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102879:	83 ec 0c             	sub    $0xc,%esp
8010287c:	68 e0 b5 10 80       	push   $0x8010b5e0
80102881:	e8 e9 26 00 00       	call   80104f6f <acquire>
80102886:	83 c4 10             	add    $0x10,%esp

  if((b = idequeue) == 0){
80102889:	a1 14 b6 10 80       	mov    0x8010b614,%eax
8010288e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102891:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102895:	75 15                	jne    801028ac <ideintr+0x39>
    release(&idelock);
80102897:	83 ec 0c             	sub    $0xc,%esp
8010289a:	68 e0 b5 10 80       	push   $0x8010b5e0
8010289f:	e8 39 27 00 00       	call   80104fdd <release>
801028a4:	83 c4 10             	add    $0x10,%esp
    return;
801028a7:	e9 9a 00 00 00       	jmp    80102946 <ideintr+0xd3>
  }
  idequeue = b->qnext;
801028ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028af:	8b 40 58             	mov    0x58(%eax),%eax
801028b2:	a3 14 b6 10 80       	mov    %eax,0x8010b614

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801028b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028ba:	8b 00                	mov    (%eax),%eax
801028bc:	83 e0 04             	and    $0x4,%eax
801028bf:	85 c0                	test   %eax,%eax
801028c1:	75 2d                	jne    801028f0 <ideintr+0x7d>
801028c3:	83 ec 0c             	sub    $0xc,%esp
801028c6:	6a 01                	push   $0x1
801028c8:	e8 2e fd ff ff       	call   801025fb <idewait>
801028cd:	83 c4 10             	add    $0x10,%esp
801028d0:	85 c0                	test   %eax,%eax
801028d2:	78 1c                	js     801028f0 <ideintr+0x7d>
    insl(0x1f0, b->data, BSIZE/4);
801028d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028d7:	83 c0 5c             	add    $0x5c,%eax
801028da:	83 ec 04             	sub    $0x4,%esp
801028dd:	68 80 00 00 00       	push   $0x80
801028e2:	50                   	push   %eax
801028e3:	68 f0 01 00 00       	push   $0x1f0
801028e8:	e8 a3 fc ff ff       	call   80102590 <insl>
801028ed:	83 c4 10             	add    $0x10,%esp

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
801028f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028f3:	8b 00                	mov    (%eax),%eax
801028f5:	83 c8 02             	or     $0x2,%eax
801028f8:	89 c2                	mov    %eax,%edx
801028fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028fd:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
801028ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102902:	8b 00                	mov    (%eax),%eax
80102904:	83 e0 fb             	and    $0xfffffffb,%eax
80102907:	89 c2                	mov    %eax,%edx
80102909:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010290c:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010290e:	83 ec 0c             	sub    $0xc,%esp
80102911:	ff 75 f4             	pushl  -0xc(%ebp)
80102914:	e8 fd 22 00 00       	call   80104c16 <wakeup>
80102919:	83 c4 10             	add    $0x10,%esp

  // Start disk on next buf in queue.
  if(idequeue != 0)
8010291c:	a1 14 b6 10 80       	mov    0x8010b614,%eax
80102921:	85 c0                	test   %eax,%eax
80102923:	74 11                	je     80102936 <ideintr+0xc3>
    idestart(idequeue);
80102925:	a1 14 b6 10 80       	mov    0x8010b614,%eax
8010292a:	83 ec 0c             	sub    $0xc,%esp
8010292d:	50                   	push   %eax
8010292e:	e8 ae fd ff ff       	call   801026e1 <idestart>
80102933:	83 c4 10             	add    $0x10,%esp

  release(&idelock);
80102936:	83 ec 0c             	sub    $0xc,%esp
80102939:	68 e0 b5 10 80       	push   $0x8010b5e0
8010293e:	e8 9a 26 00 00       	call   80104fdd <release>
80102943:	83 c4 10             	add    $0x10,%esp
}
80102946:	c9                   	leave  
80102947:	c3                   	ret    

80102948 <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102948:	55                   	push   %ebp
80102949:	89 e5                	mov    %esp,%ebp
8010294b:	83 ec 18             	sub    $0x18,%esp
  struct buf **pp;

  if(!holdingsleep(&b->lock))
8010294e:	8b 45 08             	mov    0x8(%ebp),%eax
80102951:	83 c0 0c             	add    $0xc,%eax
80102954:	83 ec 0c             	sub    $0xc,%esp
80102957:	50                   	push   %eax
80102958:	e8 5b 25 00 00       	call   80104eb8 <holdingsleep>
8010295d:	83 c4 10             	add    $0x10,%esp
80102960:	85 c0                	test   %eax,%eax
80102962:	75 0d                	jne    80102971 <iderw+0x29>
    panic("iderw: buf not locked");
80102964:	83 ec 0c             	sub    $0xc,%esp
80102967:	68 46 85 10 80       	push   $0x80108546
8010296c:	e8 2b dc ff ff       	call   8010059c <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102971:	8b 45 08             	mov    0x8(%ebp),%eax
80102974:	8b 00                	mov    (%eax),%eax
80102976:	83 e0 06             	and    $0x6,%eax
80102979:	83 f8 02             	cmp    $0x2,%eax
8010297c:	75 0d                	jne    8010298b <iderw+0x43>
    panic("iderw: nothing to do");
8010297e:	83 ec 0c             	sub    $0xc,%esp
80102981:	68 5c 85 10 80       	push   $0x8010855c
80102986:	e8 11 dc ff ff       	call   8010059c <panic>
  if(b->dev != 0 && !havedisk1)
8010298b:	8b 45 08             	mov    0x8(%ebp),%eax
8010298e:	8b 40 04             	mov    0x4(%eax),%eax
80102991:	85 c0                	test   %eax,%eax
80102993:	74 16                	je     801029ab <iderw+0x63>
80102995:	a1 18 b6 10 80       	mov    0x8010b618,%eax
8010299a:	85 c0                	test   %eax,%eax
8010299c:	75 0d                	jne    801029ab <iderw+0x63>
    panic("iderw: ide disk 1 not present");
8010299e:	83 ec 0c             	sub    $0xc,%esp
801029a1:	68 71 85 10 80       	push   $0x80108571
801029a6:	e8 f1 db ff ff       	call   8010059c <panic>

  acquire(&idelock);  //DOC:acquire-lock
801029ab:	83 ec 0c             	sub    $0xc,%esp
801029ae:	68 e0 b5 10 80       	push   $0x8010b5e0
801029b3:	e8 b7 25 00 00       	call   80104f6f <acquire>
801029b8:	83 c4 10             	add    $0x10,%esp

  // Append b to idequeue.
  b->qnext = 0;
801029bb:	8b 45 08             	mov    0x8(%ebp),%eax
801029be:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
801029c5:	c7 45 f4 14 b6 10 80 	movl   $0x8010b614,-0xc(%ebp)
801029cc:	eb 0b                	jmp    801029d9 <iderw+0x91>
801029ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029d1:	8b 00                	mov    (%eax),%eax
801029d3:	83 c0 58             	add    $0x58,%eax
801029d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029dc:	8b 00                	mov    (%eax),%eax
801029de:	85 c0                	test   %eax,%eax
801029e0:	75 ec                	jne    801029ce <iderw+0x86>
    ;
  *pp = b;
801029e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e5:	8b 55 08             	mov    0x8(%ebp),%edx
801029e8:	89 10                	mov    %edx,(%eax)

  // Start disk if necessary.
  if(idequeue == b)
801029ea:	a1 14 b6 10 80       	mov    0x8010b614,%eax
801029ef:	39 45 08             	cmp    %eax,0x8(%ebp)
801029f2:	75 23                	jne    80102a17 <iderw+0xcf>
    idestart(b);
801029f4:	83 ec 0c             	sub    $0xc,%esp
801029f7:	ff 75 08             	pushl  0x8(%ebp)
801029fa:	e8 e2 fc ff ff       	call   801026e1 <idestart>
801029ff:	83 c4 10             	add    $0x10,%esp

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a02:	eb 13                	jmp    80102a17 <iderw+0xcf>
    sleep(b, &idelock);
80102a04:	83 ec 08             	sub    $0x8,%esp
80102a07:	68 e0 b5 10 80       	push   $0x8010b5e0
80102a0c:	ff 75 08             	pushl  0x8(%ebp)
80102a0f:	e8 1c 21 00 00       	call   80104b30 <sleep>
80102a14:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a17:	8b 45 08             	mov    0x8(%ebp),%eax
80102a1a:	8b 00                	mov    (%eax),%eax
80102a1c:	83 e0 06             	and    $0x6,%eax
80102a1f:	83 f8 02             	cmp    $0x2,%eax
80102a22:	75 e0                	jne    80102a04 <iderw+0xbc>
  }


  release(&idelock);
80102a24:	83 ec 0c             	sub    $0xc,%esp
80102a27:	68 e0 b5 10 80       	push   $0x8010b5e0
80102a2c:	e8 ac 25 00 00       	call   80104fdd <release>
80102a31:	83 c4 10             	add    $0x10,%esp
}
80102a34:	90                   	nop
80102a35:	c9                   	leave  
80102a36:	c3                   	ret    

80102a37 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102a37:	55                   	push   %ebp
80102a38:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a3a:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a3f:	8b 55 08             	mov    0x8(%ebp),%edx
80102a42:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102a44:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a49:	8b 40 10             	mov    0x10(%eax),%eax
}
80102a4c:	5d                   	pop    %ebp
80102a4d:	c3                   	ret    

80102a4e <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102a4e:	55                   	push   %ebp
80102a4f:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a51:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a56:	8b 55 08             	mov    0x8(%ebp),%edx
80102a59:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102a5b:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a60:	8b 55 0c             	mov    0xc(%ebp),%edx
80102a63:	89 50 10             	mov    %edx,0x10(%eax)
}
80102a66:	90                   	nop
80102a67:	5d                   	pop    %ebp
80102a68:	c3                   	ret    

80102a69 <ioapicinit>:

void
ioapicinit(void)
{
80102a69:	55                   	push   %ebp
80102a6a:	89 e5                	mov    %esp,%ebp
80102a6c:	83 ec 18             	sub    $0x18,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102a6f:	c7 05 b4 36 11 80 00 	movl   $0xfec00000,0x801136b4
80102a76:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102a79:	6a 01                	push   $0x1
80102a7b:	e8 b7 ff ff ff       	call   80102a37 <ioapicread>
80102a80:	83 c4 04             	add    $0x4,%esp
80102a83:	c1 e8 10             	shr    $0x10,%eax
80102a86:	25 ff 00 00 00       	and    $0xff,%eax
80102a8b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102a8e:	6a 00                	push   $0x0
80102a90:	e8 a2 ff ff ff       	call   80102a37 <ioapicread>
80102a95:	83 c4 04             	add    $0x4,%esp
80102a98:	c1 e8 18             	shr    $0x18,%eax
80102a9b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102a9e:	0f b6 05 e0 37 11 80 	movzbl 0x801137e0,%eax
80102aa5:	0f b6 c0             	movzbl %al,%eax
80102aa8:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80102aab:	74 10                	je     80102abd <ioapicinit+0x54>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102aad:	83 ec 0c             	sub    $0xc,%esp
80102ab0:	68 90 85 10 80       	push   $0x80108590
80102ab5:	e8 42 d9 ff ff       	call   801003fc <cprintf>
80102aba:	83 c4 10             	add    $0x10,%esp

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102abd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102ac4:	eb 3f                	jmp    80102b05 <ioapicinit+0x9c>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102ac6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ac9:	83 c0 20             	add    $0x20,%eax
80102acc:	0d 00 00 01 00       	or     $0x10000,%eax
80102ad1:	89 c2                	mov    %eax,%edx
80102ad3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ad6:	83 c0 08             	add    $0x8,%eax
80102ad9:	01 c0                	add    %eax,%eax
80102adb:	83 ec 08             	sub    $0x8,%esp
80102ade:	52                   	push   %edx
80102adf:	50                   	push   %eax
80102ae0:	e8 69 ff ff ff       	call   80102a4e <ioapicwrite>
80102ae5:	83 c4 10             	add    $0x10,%esp
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102ae8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aeb:	83 c0 08             	add    $0x8,%eax
80102aee:	01 c0                	add    %eax,%eax
80102af0:	83 c0 01             	add    $0x1,%eax
80102af3:	83 ec 08             	sub    $0x8,%esp
80102af6:	6a 00                	push   $0x0
80102af8:	50                   	push   %eax
80102af9:	e8 50 ff ff ff       	call   80102a4e <ioapicwrite>
80102afe:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i <= maxintr; i++){
80102b01:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b08:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102b0b:	7e b9                	jle    80102ac6 <ioapicinit+0x5d>
  }
}
80102b0d:	90                   	nop
80102b0e:	c9                   	leave  
80102b0f:	c3                   	ret    

80102b10 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102b10:	55                   	push   %ebp
80102b11:	89 e5                	mov    %esp,%ebp
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102b13:	8b 45 08             	mov    0x8(%ebp),%eax
80102b16:	83 c0 20             	add    $0x20,%eax
80102b19:	89 c2                	mov    %eax,%edx
80102b1b:	8b 45 08             	mov    0x8(%ebp),%eax
80102b1e:	83 c0 08             	add    $0x8,%eax
80102b21:	01 c0                	add    %eax,%eax
80102b23:	52                   	push   %edx
80102b24:	50                   	push   %eax
80102b25:	e8 24 ff ff ff       	call   80102a4e <ioapicwrite>
80102b2a:	83 c4 08             	add    $0x8,%esp
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102b2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b30:	c1 e0 18             	shl    $0x18,%eax
80102b33:	89 c2                	mov    %eax,%edx
80102b35:	8b 45 08             	mov    0x8(%ebp),%eax
80102b38:	83 c0 08             	add    $0x8,%eax
80102b3b:	01 c0                	add    %eax,%eax
80102b3d:	83 c0 01             	add    $0x1,%eax
80102b40:	52                   	push   %edx
80102b41:	50                   	push   %eax
80102b42:	e8 07 ff ff ff       	call   80102a4e <ioapicwrite>
80102b47:	83 c4 08             	add    $0x8,%esp
}
80102b4a:	90                   	nop
80102b4b:	c9                   	leave  
80102b4c:	c3                   	ret    

80102b4d <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102b4d:	55                   	push   %ebp
80102b4e:	89 e5                	mov    %esp,%ebp
80102b50:	83 ec 08             	sub    $0x8,%esp
  initlock(&kmem.lock, "kmem");
80102b53:	83 ec 08             	sub    $0x8,%esp
80102b56:	68 c2 85 10 80       	push   $0x801085c2
80102b5b:	68 c0 36 11 80       	push   $0x801136c0
80102b60:	e8 e8 23 00 00       	call   80104f4d <initlock>
80102b65:	83 c4 10             	add    $0x10,%esp
  kmem.use_lock = 0;
80102b68:	c7 05 f4 36 11 80 00 	movl   $0x0,0x801136f4
80102b6f:	00 00 00 
  freerange(vstart, vend);
80102b72:	83 ec 08             	sub    $0x8,%esp
80102b75:	ff 75 0c             	pushl  0xc(%ebp)
80102b78:	ff 75 08             	pushl  0x8(%ebp)
80102b7b:	e8 2a 00 00 00       	call   80102baa <freerange>
80102b80:	83 c4 10             	add    $0x10,%esp
}
80102b83:	90                   	nop
80102b84:	c9                   	leave  
80102b85:	c3                   	ret    

80102b86 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102b86:	55                   	push   %ebp
80102b87:	89 e5                	mov    %esp,%ebp
80102b89:	83 ec 08             	sub    $0x8,%esp
  freerange(vstart, vend);
80102b8c:	83 ec 08             	sub    $0x8,%esp
80102b8f:	ff 75 0c             	pushl  0xc(%ebp)
80102b92:	ff 75 08             	pushl  0x8(%ebp)
80102b95:	e8 10 00 00 00       	call   80102baa <freerange>
80102b9a:	83 c4 10             	add    $0x10,%esp
  kmem.use_lock = 1;
80102b9d:	c7 05 f4 36 11 80 01 	movl   $0x1,0x801136f4
80102ba4:	00 00 00 
}
80102ba7:	90                   	nop
80102ba8:	c9                   	leave  
80102ba9:	c3                   	ret    

80102baa <freerange>:

void
freerange(void *vstart, void *vend)
{
80102baa:	55                   	push   %ebp
80102bab:	89 e5                	mov    %esp,%ebp
80102bad:	83 ec 18             	sub    $0x18,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102bb0:	8b 45 08             	mov    0x8(%ebp),%eax
80102bb3:	05 ff 0f 00 00       	add    $0xfff,%eax
80102bb8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102bbd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102bc0:	eb 15                	jmp    80102bd7 <freerange+0x2d>
    kfree(p);
80102bc2:	83 ec 0c             	sub    $0xc,%esp
80102bc5:	ff 75 f4             	pushl  -0xc(%ebp)
80102bc8:	e8 1a 00 00 00       	call   80102be7 <kfree>
80102bcd:	83 c4 10             	add    $0x10,%esp
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102bd0:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102bd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bda:	05 00 10 00 00       	add    $0x1000,%eax
80102bdf:	39 45 0c             	cmp    %eax,0xc(%ebp)
80102be2:	73 de                	jae    80102bc2 <freerange+0x18>
}
80102be4:	90                   	nop
80102be5:	c9                   	leave  
80102be6:	c3                   	ret    

80102be7 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102be7:	55                   	push   %ebp
80102be8:	89 e5                	mov    %esp,%ebp
80102bea:	83 ec 18             	sub    $0x18,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102bed:	8b 45 08             	mov    0x8(%ebp),%eax
80102bf0:	25 ff 0f 00 00       	and    $0xfff,%eax
80102bf5:	85 c0                	test   %eax,%eax
80102bf7:	75 18                	jne    80102c11 <kfree+0x2a>
80102bf9:	81 7d 08 28 65 11 80 	cmpl   $0x80116528,0x8(%ebp)
80102c00:	72 0f                	jb     80102c11 <kfree+0x2a>
80102c02:	8b 45 08             	mov    0x8(%ebp),%eax
80102c05:	05 00 00 00 80       	add    $0x80000000,%eax
80102c0a:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102c0f:	76 0d                	jbe    80102c1e <kfree+0x37>
    panic("kfree");
80102c11:	83 ec 0c             	sub    $0xc,%esp
80102c14:	68 c7 85 10 80       	push   $0x801085c7
80102c19:	e8 7e d9 ff ff       	call   8010059c <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102c1e:	83 ec 04             	sub    $0x4,%esp
80102c21:	68 00 10 00 00       	push   $0x1000
80102c26:	6a 01                	push   $0x1
80102c28:	ff 75 08             	pushl  0x8(%ebp)
80102c2b:	e8 c6 25 00 00       	call   801051f6 <memset>
80102c30:	83 c4 10             	add    $0x10,%esp

  if(kmem.use_lock)
80102c33:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102c38:	85 c0                	test   %eax,%eax
80102c3a:	74 10                	je     80102c4c <kfree+0x65>
    acquire(&kmem.lock);
80102c3c:	83 ec 0c             	sub    $0xc,%esp
80102c3f:	68 c0 36 11 80       	push   $0x801136c0
80102c44:	e8 26 23 00 00       	call   80104f6f <acquire>
80102c49:	83 c4 10             	add    $0x10,%esp
  r = (struct run*)v;
80102c4c:	8b 45 08             	mov    0x8(%ebp),%eax
80102c4f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102c52:	8b 15 f8 36 11 80    	mov    0x801136f8,%edx
80102c58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c5b:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102c5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c60:	a3 f8 36 11 80       	mov    %eax,0x801136f8
  if(kmem.use_lock)
80102c65:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102c6a:	85 c0                	test   %eax,%eax
80102c6c:	74 10                	je     80102c7e <kfree+0x97>
    release(&kmem.lock);
80102c6e:	83 ec 0c             	sub    $0xc,%esp
80102c71:	68 c0 36 11 80       	push   $0x801136c0
80102c76:	e8 62 23 00 00       	call   80104fdd <release>
80102c7b:	83 c4 10             	add    $0x10,%esp
}
80102c7e:	90                   	nop
80102c7f:	c9                   	leave  
80102c80:	c3                   	ret    

80102c81 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102c81:	55                   	push   %ebp
80102c82:	89 e5                	mov    %esp,%ebp
80102c84:	83 ec 18             	sub    $0x18,%esp
  struct run *r;

  if(kmem.use_lock)
80102c87:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102c8c:	85 c0                	test   %eax,%eax
80102c8e:	74 10                	je     80102ca0 <kalloc+0x1f>
    acquire(&kmem.lock);
80102c90:	83 ec 0c             	sub    $0xc,%esp
80102c93:	68 c0 36 11 80       	push   $0x801136c0
80102c98:	e8 d2 22 00 00       	call   80104f6f <acquire>
80102c9d:	83 c4 10             	add    $0x10,%esp
  r = kmem.freelist;
80102ca0:	a1 f8 36 11 80       	mov    0x801136f8,%eax
80102ca5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102ca8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102cac:	74 0a                	je     80102cb8 <kalloc+0x37>
    kmem.freelist = r->next;
80102cae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cb1:	8b 00                	mov    (%eax),%eax
80102cb3:	a3 f8 36 11 80       	mov    %eax,0x801136f8
  if(kmem.use_lock)
80102cb8:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102cbd:	85 c0                	test   %eax,%eax
80102cbf:	74 10                	je     80102cd1 <kalloc+0x50>
    release(&kmem.lock);
80102cc1:	83 ec 0c             	sub    $0xc,%esp
80102cc4:	68 c0 36 11 80       	push   $0x801136c0
80102cc9:	e8 0f 23 00 00       	call   80104fdd <release>
80102cce:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
80102cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102cd4:	c9                   	leave  
80102cd5:	c3                   	ret    

80102cd6 <inb>:
{
80102cd6:	55                   	push   %ebp
80102cd7:	89 e5                	mov    %esp,%ebp
80102cd9:	83 ec 14             	sub    $0x14,%esp
80102cdc:	8b 45 08             	mov    0x8(%ebp),%eax
80102cdf:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ce3:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102ce7:	89 c2                	mov    %eax,%edx
80102ce9:	ec                   	in     (%dx),%al
80102cea:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102ced:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102cf1:	c9                   	leave  
80102cf2:	c3                   	ret    

80102cf3 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102cf3:	55                   	push   %ebp
80102cf4:	89 e5                	mov    %esp,%ebp
80102cf6:	83 ec 10             	sub    $0x10,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102cf9:	6a 64                	push   $0x64
80102cfb:	e8 d6 ff ff ff       	call   80102cd6 <inb>
80102d00:	83 c4 04             	add    $0x4,%esp
80102d03:	0f b6 c0             	movzbl %al,%eax
80102d06:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102d09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d0c:	83 e0 01             	and    $0x1,%eax
80102d0f:	85 c0                	test   %eax,%eax
80102d11:	75 0a                	jne    80102d1d <kbdgetc+0x2a>
    return -1;
80102d13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d18:	e9 23 01 00 00       	jmp    80102e40 <kbdgetc+0x14d>
  data = inb(KBDATAP);
80102d1d:	6a 60                	push   $0x60
80102d1f:	e8 b2 ff ff ff       	call   80102cd6 <inb>
80102d24:	83 c4 04             	add    $0x4,%esp
80102d27:	0f b6 c0             	movzbl %al,%eax
80102d2a:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102d2d:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102d34:	75 17                	jne    80102d4d <kbdgetc+0x5a>
    shift |= E0ESC;
80102d36:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d3b:	83 c8 40             	or     $0x40,%eax
80102d3e:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
    return 0;
80102d43:	b8 00 00 00 00       	mov    $0x0,%eax
80102d48:	e9 f3 00 00 00       	jmp    80102e40 <kbdgetc+0x14d>
  } else if(data & 0x80){
80102d4d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d50:	25 80 00 00 00       	and    $0x80,%eax
80102d55:	85 c0                	test   %eax,%eax
80102d57:	74 45                	je     80102d9e <kbdgetc+0xab>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102d59:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d5e:	83 e0 40             	and    $0x40,%eax
80102d61:	85 c0                	test   %eax,%eax
80102d63:	75 08                	jne    80102d6d <kbdgetc+0x7a>
80102d65:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d68:	83 e0 7f             	and    $0x7f,%eax
80102d6b:	eb 03                	jmp    80102d70 <kbdgetc+0x7d>
80102d6d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d70:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102d73:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d76:	05 20 90 10 80       	add    $0x80109020,%eax
80102d7b:	0f b6 00             	movzbl (%eax),%eax
80102d7e:	83 c8 40             	or     $0x40,%eax
80102d81:	0f b6 c0             	movzbl %al,%eax
80102d84:	f7 d0                	not    %eax
80102d86:	89 c2                	mov    %eax,%edx
80102d88:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d8d:	21 d0                	and    %edx,%eax
80102d8f:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
    return 0;
80102d94:	b8 00 00 00 00       	mov    $0x0,%eax
80102d99:	e9 a2 00 00 00       	jmp    80102e40 <kbdgetc+0x14d>
  } else if(shift & E0ESC){
80102d9e:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102da3:	83 e0 40             	and    $0x40,%eax
80102da6:	85 c0                	test   %eax,%eax
80102da8:	74 14                	je     80102dbe <kbdgetc+0xcb>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102daa:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102db1:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102db6:	83 e0 bf             	and    $0xffffffbf,%eax
80102db9:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  }

  shift |= shiftcode[data];
80102dbe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dc1:	05 20 90 10 80       	add    $0x80109020,%eax
80102dc6:	0f b6 00             	movzbl (%eax),%eax
80102dc9:	0f b6 d0             	movzbl %al,%edx
80102dcc:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102dd1:	09 d0                	or     %edx,%eax
80102dd3:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  shift ^= togglecode[data];
80102dd8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102ddb:	05 20 91 10 80       	add    $0x80109120,%eax
80102de0:	0f b6 00             	movzbl (%eax),%eax
80102de3:	0f b6 d0             	movzbl %al,%edx
80102de6:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102deb:	31 d0                	xor    %edx,%eax
80102ded:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  c = charcode[shift & (CTL | SHIFT)][data];
80102df2:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102df7:	83 e0 03             	and    $0x3,%eax
80102dfa:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102e01:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e04:	01 d0                	add    %edx,%eax
80102e06:	0f b6 00             	movzbl (%eax),%eax
80102e09:	0f b6 c0             	movzbl %al,%eax
80102e0c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102e0f:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102e14:	83 e0 08             	and    $0x8,%eax
80102e17:	85 c0                	test   %eax,%eax
80102e19:	74 22                	je     80102e3d <kbdgetc+0x14a>
    if('a' <= c && c <= 'z')
80102e1b:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102e1f:	76 0c                	jbe    80102e2d <kbdgetc+0x13a>
80102e21:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102e25:	77 06                	ja     80102e2d <kbdgetc+0x13a>
      c += 'A' - 'a';
80102e27:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102e2b:	eb 10                	jmp    80102e3d <kbdgetc+0x14a>
    else if('A' <= c && c <= 'Z')
80102e2d:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102e31:	76 0a                	jbe    80102e3d <kbdgetc+0x14a>
80102e33:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102e37:	77 04                	ja     80102e3d <kbdgetc+0x14a>
      c += 'a' - 'A';
80102e39:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102e3d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102e40:	c9                   	leave  
80102e41:	c3                   	ret    

80102e42 <kbdintr>:

void
kbdintr(void)
{
80102e42:	55                   	push   %ebp
80102e43:	89 e5                	mov    %esp,%ebp
80102e45:	83 ec 08             	sub    $0x8,%esp
  consoleintr(kbdgetc);
80102e48:	83 ec 0c             	sub    $0xc,%esp
80102e4b:	68 f3 2c 10 80       	push   $0x80102cf3
80102e50:	e8 db d9 ff ff       	call   80100830 <consoleintr>
80102e55:	83 c4 10             	add    $0x10,%esp
}
80102e58:	90                   	nop
80102e59:	c9                   	leave  
80102e5a:	c3                   	ret    

80102e5b <inb>:
{
80102e5b:	55                   	push   %ebp
80102e5c:	89 e5                	mov    %esp,%ebp
80102e5e:	83 ec 14             	sub    $0x14,%esp
80102e61:	8b 45 08             	mov    0x8(%ebp),%eax
80102e64:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e68:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102e6c:	89 c2                	mov    %eax,%edx
80102e6e:	ec                   	in     (%dx),%al
80102e6f:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102e72:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102e76:	c9                   	leave  
80102e77:	c3                   	ret    

80102e78 <outb>:
{
80102e78:	55                   	push   %ebp
80102e79:	89 e5                	mov    %esp,%ebp
80102e7b:	83 ec 08             	sub    $0x8,%esp
80102e7e:	8b 55 08             	mov    0x8(%ebp),%edx
80102e81:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e84:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102e88:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e8b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102e8f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102e93:	ee                   	out    %al,(%dx)
}
80102e94:	90                   	nop
80102e95:	c9                   	leave  
80102e96:	c3                   	ret    

80102e97 <lapicw>:
volatile uint *lapic;  // Initialized in mp.c

//PAGEBREAK!
static void
lapicw(int index, int value)
{
80102e97:	55                   	push   %ebp
80102e98:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102e9a:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102e9f:	8b 55 08             	mov    0x8(%ebp),%edx
80102ea2:	c1 e2 02             	shl    $0x2,%edx
80102ea5:	01 c2                	add    %eax,%edx
80102ea7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102eaa:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102eac:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102eb1:	83 c0 20             	add    $0x20,%eax
80102eb4:	8b 00                	mov    (%eax),%eax
}
80102eb6:	90                   	nop
80102eb7:	5d                   	pop    %ebp
80102eb8:	c3                   	ret    

80102eb9 <lapicinit>:

void
lapicinit(void)
{
80102eb9:	55                   	push   %ebp
80102eba:	89 e5                	mov    %esp,%ebp
  if(!lapic)
80102ebc:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102ec1:	85 c0                	test   %eax,%eax
80102ec3:	0f 84 0b 01 00 00    	je     80102fd4 <lapicinit+0x11b>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102ec9:	68 3f 01 00 00       	push   $0x13f
80102ece:	6a 3c                	push   $0x3c
80102ed0:	e8 c2 ff ff ff       	call   80102e97 <lapicw>
80102ed5:	83 c4 08             	add    $0x8,%esp

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102ed8:	6a 0b                	push   $0xb
80102eda:	68 f8 00 00 00       	push   $0xf8
80102edf:	e8 b3 ff ff ff       	call   80102e97 <lapicw>
80102ee4:	83 c4 08             	add    $0x8,%esp
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102ee7:	68 20 00 02 00       	push   $0x20020
80102eec:	68 c8 00 00 00       	push   $0xc8
80102ef1:	e8 a1 ff ff ff       	call   80102e97 <lapicw>
80102ef6:	83 c4 08             	add    $0x8,%esp
  lapicw(TICR, 10000000);
80102ef9:	68 80 96 98 00       	push   $0x989680
80102efe:	68 e0 00 00 00       	push   $0xe0
80102f03:	e8 8f ff ff ff       	call   80102e97 <lapicw>
80102f08:	83 c4 08             	add    $0x8,%esp

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102f0b:	68 00 00 01 00       	push   $0x10000
80102f10:	68 d4 00 00 00       	push   $0xd4
80102f15:	e8 7d ff ff ff       	call   80102e97 <lapicw>
80102f1a:	83 c4 08             	add    $0x8,%esp
  lapicw(LINT1, MASKED);
80102f1d:	68 00 00 01 00       	push   $0x10000
80102f22:	68 d8 00 00 00       	push   $0xd8
80102f27:	e8 6b ff ff ff       	call   80102e97 <lapicw>
80102f2c:	83 c4 08             	add    $0x8,%esp

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102f2f:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102f34:	83 c0 30             	add    $0x30,%eax
80102f37:	8b 00                	mov    (%eax),%eax
80102f39:	c1 e8 10             	shr    $0x10,%eax
80102f3c:	0f b6 c0             	movzbl %al,%eax
80102f3f:	83 f8 03             	cmp    $0x3,%eax
80102f42:	76 12                	jbe    80102f56 <lapicinit+0x9d>
    lapicw(PCINT, MASKED);
80102f44:	68 00 00 01 00       	push   $0x10000
80102f49:	68 d0 00 00 00       	push   $0xd0
80102f4e:	e8 44 ff ff ff       	call   80102e97 <lapicw>
80102f53:	83 c4 08             	add    $0x8,%esp

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102f56:	6a 33                	push   $0x33
80102f58:	68 dc 00 00 00       	push   $0xdc
80102f5d:	e8 35 ff ff ff       	call   80102e97 <lapicw>
80102f62:	83 c4 08             	add    $0x8,%esp

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102f65:	6a 00                	push   $0x0
80102f67:	68 a0 00 00 00       	push   $0xa0
80102f6c:	e8 26 ff ff ff       	call   80102e97 <lapicw>
80102f71:	83 c4 08             	add    $0x8,%esp
  lapicw(ESR, 0);
80102f74:	6a 00                	push   $0x0
80102f76:	68 a0 00 00 00       	push   $0xa0
80102f7b:	e8 17 ff ff ff       	call   80102e97 <lapicw>
80102f80:	83 c4 08             	add    $0x8,%esp

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102f83:	6a 00                	push   $0x0
80102f85:	6a 2c                	push   $0x2c
80102f87:	e8 0b ff ff ff       	call   80102e97 <lapicw>
80102f8c:	83 c4 08             	add    $0x8,%esp

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102f8f:	6a 00                	push   $0x0
80102f91:	68 c4 00 00 00       	push   $0xc4
80102f96:	e8 fc fe ff ff       	call   80102e97 <lapicw>
80102f9b:	83 c4 08             	add    $0x8,%esp
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102f9e:	68 00 85 08 00       	push   $0x88500
80102fa3:	68 c0 00 00 00       	push   $0xc0
80102fa8:	e8 ea fe ff ff       	call   80102e97 <lapicw>
80102fad:	83 c4 08             	add    $0x8,%esp
  while(lapic[ICRLO] & DELIVS)
80102fb0:	90                   	nop
80102fb1:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102fb6:	05 00 03 00 00       	add    $0x300,%eax
80102fbb:	8b 00                	mov    (%eax),%eax
80102fbd:	25 00 10 00 00       	and    $0x1000,%eax
80102fc2:	85 c0                	test   %eax,%eax
80102fc4:	75 eb                	jne    80102fb1 <lapicinit+0xf8>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102fc6:	6a 00                	push   $0x0
80102fc8:	6a 20                	push   $0x20
80102fca:	e8 c8 fe ff ff       	call   80102e97 <lapicw>
80102fcf:	83 c4 08             	add    $0x8,%esp
80102fd2:	eb 01                	jmp    80102fd5 <lapicinit+0x11c>
    return;
80102fd4:	90                   	nop
}
80102fd5:	c9                   	leave  
80102fd6:	c3                   	ret    

80102fd7 <lapicid>:

int
lapicid(void)
{
80102fd7:	55                   	push   %ebp
80102fd8:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102fda:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102fdf:	85 c0                	test   %eax,%eax
80102fe1:	75 07                	jne    80102fea <lapicid+0x13>
    return 0;
80102fe3:	b8 00 00 00 00       	mov    $0x0,%eax
80102fe8:	eb 0d                	jmp    80102ff7 <lapicid+0x20>
  return lapic[ID] >> 24;
80102fea:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102fef:	83 c0 20             	add    $0x20,%eax
80102ff2:	8b 00                	mov    (%eax),%eax
80102ff4:	c1 e8 18             	shr    $0x18,%eax
}
80102ff7:	5d                   	pop    %ebp
80102ff8:	c3                   	ret    

80102ff9 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102ff9:	55                   	push   %ebp
80102ffa:	89 e5                	mov    %esp,%ebp
  if(lapic)
80102ffc:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80103001:	85 c0                	test   %eax,%eax
80103003:	74 0c                	je     80103011 <lapiceoi+0x18>
    lapicw(EOI, 0);
80103005:	6a 00                	push   $0x0
80103007:	6a 2c                	push   $0x2c
80103009:	e8 89 fe ff ff       	call   80102e97 <lapicw>
8010300e:	83 c4 08             	add    $0x8,%esp
}
80103011:	90                   	nop
80103012:	c9                   	leave  
80103013:	c3                   	ret    

80103014 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103014:	55                   	push   %ebp
80103015:	89 e5                	mov    %esp,%ebp
}
80103017:	90                   	nop
80103018:	5d                   	pop    %ebp
80103019:	c3                   	ret    

8010301a <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010301a:	55                   	push   %ebp
8010301b:	89 e5                	mov    %esp,%ebp
8010301d:	83 ec 14             	sub    $0x14,%esp
80103020:	8b 45 08             	mov    0x8(%ebp),%eax
80103023:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;

  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80103026:	6a 0f                	push   $0xf
80103028:	6a 70                	push   $0x70
8010302a:	e8 49 fe ff ff       	call   80102e78 <outb>
8010302f:	83 c4 08             	add    $0x8,%esp
  outb(CMOS_PORT+1, 0x0A);
80103032:	6a 0a                	push   $0xa
80103034:	6a 71                	push   $0x71
80103036:	e8 3d fe ff ff       	call   80102e78 <outb>
8010303b:	83 c4 08             	add    $0x8,%esp
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
8010303e:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103045:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103048:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
8010304d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103050:	c1 e8 04             	shr    $0x4,%eax
80103053:	89 c2                	mov    %eax,%edx
80103055:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103058:	83 c0 02             	add    $0x2,%eax
8010305b:	66 89 10             	mov    %dx,(%eax)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
8010305e:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103062:	c1 e0 18             	shl    $0x18,%eax
80103065:	50                   	push   %eax
80103066:	68 c4 00 00 00       	push   $0xc4
8010306b:	e8 27 fe ff ff       	call   80102e97 <lapicw>
80103070:	83 c4 08             	add    $0x8,%esp
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103073:	68 00 c5 00 00       	push   $0xc500
80103078:	68 c0 00 00 00       	push   $0xc0
8010307d:	e8 15 fe ff ff       	call   80102e97 <lapicw>
80103082:	83 c4 08             	add    $0x8,%esp
  microdelay(200);
80103085:	68 c8 00 00 00       	push   $0xc8
8010308a:	e8 85 ff ff ff       	call   80103014 <microdelay>
8010308f:	83 c4 04             	add    $0x4,%esp
  lapicw(ICRLO, INIT | LEVEL);
80103092:	68 00 85 00 00       	push   $0x8500
80103097:	68 c0 00 00 00       	push   $0xc0
8010309c:	e8 f6 fd ff ff       	call   80102e97 <lapicw>
801030a1:	83 c4 08             	add    $0x8,%esp
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801030a4:	6a 64                	push   $0x64
801030a6:	e8 69 ff ff ff       	call   80103014 <microdelay>
801030ab:	83 c4 04             	add    $0x4,%esp
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801030ae:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801030b5:	eb 3d                	jmp    801030f4 <lapicstartap+0xda>
    lapicw(ICRHI, apicid<<24);
801030b7:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801030bb:	c1 e0 18             	shl    $0x18,%eax
801030be:	50                   	push   %eax
801030bf:	68 c4 00 00 00       	push   $0xc4
801030c4:	e8 ce fd ff ff       	call   80102e97 <lapicw>
801030c9:	83 c4 08             	add    $0x8,%esp
    lapicw(ICRLO, STARTUP | (addr>>12));
801030cc:	8b 45 0c             	mov    0xc(%ebp),%eax
801030cf:	c1 e8 0c             	shr    $0xc,%eax
801030d2:	80 cc 06             	or     $0x6,%ah
801030d5:	50                   	push   %eax
801030d6:	68 c0 00 00 00       	push   $0xc0
801030db:	e8 b7 fd ff ff       	call   80102e97 <lapicw>
801030e0:	83 c4 08             	add    $0x8,%esp
    microdelay(200);
801030e3:	68 c8 00 00 00       	push   $0xc8
801030e8:	e8 27 ff ff ff       	call   80103014 <microdelay>
801030ed:	83 c4 04             	add    $0x4,%esp
  for(i = 0; i < 2; i++){
801030f0:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801030f4:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801030f8:	7e bd                	jle    801030b7 <lapicstartap+0x9d>
  }
}
801030fa:	90                   	nop
801030fb:	c9                   	leave  
801030fc:	c3                   	ret    

801030fd <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
801030fd:	55                   	push   %ebp
801030fe:	89 e5                	mov    %esp,%ebp
  outb(CMOS_PORT,  reg);
80103100:	8b 45 08             	mov    0x8(%ebp),%eax
80103103:	0f b6 c0             	movzbl %al,%eax
80103106:	50                   	push   %eax
80103107:	6a 70                	push   $0x70
80103109:	e8 6a fd ff ff       	call   80102e78 <outb>
8010310e:	83 c4 08             	add    $0x8,%esp
  microdelay(200);
80103111:	68 c8 00 00 00       	push   $0xc8
80103116:	e8 f9 fe ff ff       	call   80103014 <microdelay>
8010311b:	83 c4 04             	add    $0x4,%esp

  return inb(CMOS_RETURN);
8010311e:	6a 71                	push   $0x71
80103120:	e8 36 fd ff ff       	call   80102e5b <inb>
80103125:	83 c4 04             	add    $0x4,%esp
80103128:	0f b6 c0             	movzbl %al,%eax
}
8010312b:	c9                   	leave  
8010312c:	c3                   	ret    

8010312d <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
8010312d:	55                   	push   %ebp
8010312e:	89 e5                	mov    %esp,%ebp
  r->second = cmos_read(SECS);
80103130:	6a 00                	push   $0x0
80103132:	e8 c6 ff ff ff       	call   801030fd <cmos_read>
80103137:	83 c4 04             	add    $0x4,%esp
8010313a:	89 c2                	mov    %eax,%edx
8010313c:	8b 45 08             	mov    0x8(%ebp),%eax
8010313f:	89 10                	mov    %edx,(%eax)
  r->minute = cmos_read(MINS);
80103141:	6a 02                	push   $0x2
80103143:	e8 b5 ff ff ff       	call   801030fd <cmos_read>
80103148:	83 c4 04             	add    $0x4,%esp
8010314b:	89 c2                	mov    %eax,%edx
8010314d:	8b 45 08             	mov    0x8(%ebp),%eax
80103150:	89 50 04             	mov    %edx,0x4(%eax)
  r->hour   = cmos_read(HOURS);
80103153:	6a 04                	push   $0x4
80103155:	e8 a3 ff ff ff       	call   801030fd <cmos_read>
8010315a:	83 c4 04             	add    $0x4,%esp
8010315d:	89 c2                	mov    %eax,%edx
8010315f:	8b 45 08             	mov    0x8(%ebp),%eax
80103162:	89 50 08             	mov    %edx,0x8(%eax)
  r->day    = cmos_read(DAY);
80103165:	6a 07                	push   $0x7
80103167:	e8 91 ff ff ff       	call   801030fd <cmos_read>
8010316c:	83 c4 04             	add    $0x4,%esp
8010316f:	89 c2                	mov    %eax,%edx
80103171:	8b 45 08             	mov    0x8(%ebp),%eax
80103174:	89 50 0c             	mov    %edx,0xc(%eax)
  r->month  = cmos_read(MONTH);
80103177:	6a 08                	push   $0x8
80103179:	e8 7f ff ff ff       	call   801030fd <cmos_read>
8010317e:	83 c4 04             	add    $0x4,%esp
80103181:	89 c2                	mov    %eax,%edx
80103183:	8b 45 08             	mov    0x8(%ebp),%eax
80103186:	89 50 10             	mov    %edx,0x10(%eax)
  r->year   = cmos_read(YEAR);
80103189:	6a 09                	push   $0x9
8010318b:	e8 6d ff ff ff       	call   801030fd <cmos_read>
80103190:	83 c4 04             	add    $0x4,%esp
80103193:	89 c2                	mov    %eax,%edx
80103195:	8b 45 08             	mov    0x8(%ebp),%eax
80103198:	89 50 14             	mov    %edx,0x14(%eax)
}
8010319b:	90                   	nop
8010319c:	c9                   	leave  
8010319d:	c3                   	ret    

8010319e <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
8010319e:	55                   	push   %ebp
8010319f:	89 e5                	mov    %esp,%ebp
801031a1:	83 ec 48             	sub    $0x48,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801031a4:	6a 0b                	push   $0xb
801031a6:	e8 52 ff ff ff       	call   801030fd <cmos_read>
801031ab:	83 c4 04             	add    $0x4,%esp
801031ae:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801031b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031b4:	83 e0 04             	and    $0x4,%eax
801031b7:	85 c0                	test   %eax,%eax
801031b9:	0f 94 c0             	sete   %al
801031bc:	0f b6 c0             	movzbl %al,%eax
801031bf:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801031c2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801031c5:	50                   	push   %eax
801031c6:	e8 62 ff ff ff       	call   8010312d <fill_rtcdate>
801031cb:	83 c4 04             	add    $0x4,%esp
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801031ce:	6a 0a                	push   $0xa
801031d0:	e8 28 ff ff ff       	call   801030fd <cmos_read>
801031d5:	83 c4 04             	add    $0x4,%esp
801031d8:	25 80 00 00 00       	and    $0x80,%eax
801031dd:	85 c0                	test   %eax,%eax
801031df:	75 27                	jne    80103208 <cmostime+0x6a>
        continue;
    fill_rtcdate(&t2);
801031e1:	8d 45 c0             	lea    -0x40(%ebp),%eax
801031e4:	50                   	push   %eax
801031e5:	e8 43 ff ff ff       	call   8010312d <fill_rtcdate>
801031ea:	83 c4 04             	add    $0x4,%esp
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801031ed:	83 ec 04             	sub    $0x4,%esp
801031f0:	6a 18                	push   $0x18
801031f2:	8d 45 c0             	lea    -0x40(%ebp),%eax
801031f5:	50                   	push   %eax
801031f6:	8d 45 d8             	lea    -0x28(%ebp),%eax
801031f9:	50                   	push   %eax
801031fa:	e8 5e 20 00 00       	call   8010525d <memcmp>
801031ff:	83 c4 10             	add    $0x10,%esp
80103202:	85 c0                	test   %eax,%eax
80103204:	74 05                	je     8010320b <cmostime+0x6d>
80103206:	eb ba                	jmp    801031c2 <cmostime+0x24>
        continue;
80103208:	90                   	nop
    fill_rtcdate(&t1);
80103209:	eb b7                	jmp    801031c2 <cmostime+0x24>
      break;
8010320b:	90                   	nop
  }

  // convert
  if(bcd) {
8010320c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103210:	0f 84 b4 00 00 00    	je     801032ca <cmostime+0x12c>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80103216:	8b 45 d8             	mov    -0x28(%ebp),%eax
80103219:	c1 e8 04             	shr    $0x4,%eax
8010321c:	89 c2                	mov    %eax,%edx
8010321e:	89 d0                	mov    %edx,%eax
80103220:	c1 e0 02             	shl    $0x2,%eax
80103223:	01 d0                	add    %edx,%eax
80103225:	01 c0                	add    %eax,%eax
80103227:	89 c2                	mov    %eax,%edx
80103229:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010322c:	83 e0 0f             	and    $0xf,%eax
8010322f:	01 d0                	add    %edx,%eax
80103231:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103234:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103237:	c1 e8 04             	shr    $0x4,%eax
8010323a:	89 c2                	mov    %eax,%edx
8010323c:	89 d0                	mov    %edx,%eax
8010323e:	c1 e0 02             	shl    $0x2,%eax
80103241:	01 d0                	add    %edx,%eax
80103243:	01 c0                	add    %eax,%eax
80103245:	89 c2                	mov    %eax,%edx
80103247:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010324a:	83 e0 0f             	and    $0xf,%eax
8010324d:	01 d0                	add    %edx,%eax
8010324f:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103252:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103255:	c1 e8 04             	shr    $0x4,%eax
80103258:	89 c2                	mov    %eax,%edx
8010325a:	89 d0                	mov    %edx,%eax
8010325c:	c1 e0 02             	shl    $0x2,%eax
8010325f:	01 d0                	add    %edx,%eax
80103261:	01 c0                	add    %eax,%eax
80103263:	89 c2                	mov    %eax,%edx
80103265:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103268:	83 e0 0f             	and    $0xf,%eax
8010326b:	01 d0                	add    %edx,%eax
8010326d:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103270:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103273:	c1 e8 04             	shr    $0x4,%eax
80103276:	89 c2                	mov    %eax,%edx
80103278:	89 d0                	mov    %edx,%eax
8010327a:	c1 e0 02             	shl    $0x2,%eax
8010327d:	01 d0                	add    %edx,%eax
8010327f:	01 c0                	add    %eax,%eax
80103281:	89 c2                	mov    %eax,%edx
80103283:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103286:	83 e0 0f             	and    $0xf,%eax
80103289:	01 d0                	add    %edx,%eax
8010328b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
8010328e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103291:	c1 e8 04             	shr    $0x4,%eax
80103294:	89 c2                	mov    %eax,%edx
80103296:	89 d0                	mov    %edx,%eax
80103298:	c1 e0 02             	shl    $0x2,%eax
8010329b:	01 d0                	add    %edx,%eax
8010329d:	01 c0                	add    %eax,%eax
8010329f:	89 c2                	mov    %eax,%edx
801032a1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032a4:	83 e0 0f             	and    $0xf,%eax
801032a7:	01 d0                	add    %edx,%eax
801032a9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801032ac:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032af:	c1 e8 04             	shr    $0x4,%eax
801032b2:	89 c2                	mov    %eax,%edx
801032b4:	89 d0                	mov    %edx,%eax
801032b6:	c1 e0 02             	shl    $0x2,%eax
801032b9:	01 d0                	add    %edx,%eax
801032bb:	01 c0                	add    %eax,%eax
801032bd:	89 c2                	mov    %eax,%edx
801032bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032c2:	83 e0 0f             	and    $0xf,%eax
801032c5:	01 d0                	add    %edx,%eax
801032c7:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801032ca:	8b 45 08             	mov    0x8(%ebp),%eax
801032cd:	8b 55 d8             	mov    -0x28(%ebp),%edx
801032d0:	89 10                	mov    %edx,(%eax)
801032d2:	8b 55 dc             	mov    -0x24(%ebp),%edx
801032d5:	89 50 04             	mov    %edx,0x4(%eax)
801032d8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801032db:	89 50 08             	mov    %edx,0x8(%eax)
801032de:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801032e1:	89 50 0c             	mov    %edx,0xc(%eax)
801032e4:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032e7:	89 50 10             	mov    %edx,0x10(%eax)
801032ea:	8b 55 ec             	mov    -0x14(%ebp),%edx
801032ed:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
801032f0:	8b 45 08             	mov    0x8(%ebp),%eax
801032f3:	8b 40 14             	mov    0x14(%eax),%eax
801032f6:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
801032fc:	8b 45 08             	mov    0x8(%ebp),%eax
801032ff:	89 50 14             	mov    %edx,0x14(%eax)
}
80103302:	90                   	nop
80103303:	c9                   	leave  
80103304:	c3                   	ret    

80103305 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
80103305:	55                   	push   %ebp
80103306:	89 e5                	mov    %esp,%ebp
80103308:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010330b:	83 ec 08             	sub    $0x8,%esp
8010330e:	68 cd 85 10 80       	push   $0x801085cd
80103313:	68 00 37 11 80       	push   $0x80113700
80103318:	e8 30 1c 00 00       	call   80104f4d <initlock>
8010331d:	83 c4 10             	add    $0x10,%esp
  readsb(dev, &sb);
80103320:	83 ec 08             	sub    $0x8,%esp
80103323:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103326:	50                   	push   %eax
80103327:	ff 75 08             	pushl  0x8(%ebp)
8010332a:	e8 b9 e0 ff ff       	call   801013e8 <readsb>
8010332f:	83 c4 10             	add    $0x10,%esp
  log.start = sb.logstart;
80103332:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103335:	a3 34 37 11 80       	mov    %eax,0x80113734
  log.size = sb.nlog;
8010333a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010333d:	a3 38 37 11 80       	mov    %eax,0x80113738
  log.dev = dev;
80103342:	8b 45 08             	mov    0x8(%ebp),%eax
80103345:	a3 44 37 11 80       	mov    %eax,0x80113744
  recover_from_log();
8010334a:	e8 b2 01 00 00       	call   80103501 <recover_from_log>
}
8010334f:	90                   	nop
80103350:	c9                   	leave  
80103351:	c3                   	ret    

80103352 <install_trans>:

// Copy committed blocks from log to their home location
static void
install_trans(void)
{
80103352:	55                   	push   %ebp
80103353:	89 e5                	mov    %esp,%ebp
80103355:	83 ec 18             	sub    $0x18,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103358:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010335f:	e9 95 00 00 00       	jmp    801033f9 <install_trans+0xa7>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103364:	8b 15 34 37 11 80    	mov    0x80113734,%edx
8010336a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010336d:	01 d0                	add    %edx,%eax
8010336f:	83 c0 01             	add    $0x1,%eax
80103372:	89 c2                	mov    %eax,%edx
80103374:	a1 44 37 11 80       	mov    0x80113744,%eax
80103379:	83 ec 08             	sub    $0x8,%esp
8010337c:	52                   	push   %edx
8010337d:	50                   	push   %eax
8010337e:	e8 4b ce ff ff       	call   801001ce <bread>
80103383:	83 c4 10             	add    $0x10,%esp
80103386:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103389:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010338c:	83 c0 10             	add    $0x10,%eax
8010338f:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
80103396:	89 c2                	mov    %eax,%edx
80103398:	a1 44 37 11 80       	mov    0x80113744,%eax
8010339d:	83 ec 08             	sub    $0x8,%esp
801033a0:	52                   	push   %edx
801033a1:	50                   	push   %eax
801033a2:	e8 27 ce ff ff       	call   801001ce <bread>
801033a7:	83 c4 10             	add    $0x10,%esp
801033aa:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801033ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033b0:	8d 50 5c             	lea    0x5c(%eax),%edx
801033b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033b6:	83 c0 5c             	add    $0x5c,%eax
801033b9:	83 ec 04             	sub    $0x4,%esp
801033bc:	68 00 02 00 00       	push   $0x200
801033c1:	52                   	push   %edx
801033c2:	50                   	push   %eax
801033c3:	e8 ed 1e 00 00       	call   801052b5 <memmove>
801033c8:	83 c4 10             	add    $0x10,%esp
    bwrite(dbuf);  // write dst to disk
801033cb:	83 ec 0c             	sub    $0xc,%esp
801033ce:	ff 75 ec             	pushl  -0x14(%ebp)
801033d1:	e8 31 ce ff ff       	call   80100207 <bwrite>
801033d6:	83 c4 10             	add    $0x10,%esp
    brelse(lbuf);
801033d9:	83 ec 0c             	sub    $0xc,%esp
801033dc:	ff 75 f0             	pushl  -0x10(%ebp)
801033df:	e8 6c ce ff ff       	call   80100250 <brelse>
801033e4:	83 c4 10             	add    $0x10,%esp
    brelse(dbuf);
801033e7:	83 ec 0c             	sub    $0xc,%esp
801033ea:	ff 75 ec             	pushl  -0x14(%ebp)
801033ed:	e8 5e ce ff ff       	call   80100250 <brelse>
801033f2:	83 c4 10             	add    $0x10,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801033f5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033f9:	a1 48 37 11 80       	mov    0x80113748,%eax
801033fe:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80103401:	0f 8c 5d ff ff ff    	jl     80103364 <install_trans+0x12>
  }
}
80103407:	90                   	nop
80103408:	c9                   	leave  
80103409:	c3                   	ret    

8010340a <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010340a:	55                   	push   %ebp
8010340b:	89 e5                	mov    %esp,%ebp
8010340d:	83 ec 18             	sub    $0x18,%esp
  struct buf *buf = bread(log.dev, log.start);
80103410:	a1 34 37 11 80       	mov    0x80113734,%eax
80103415:	89 c2                	mov    %eax,%edx
80103417:	a1 44 37 11 80       	mov    0x80113744,%eax
8010341c:	83 ec 08             	sub    $0x8,%esp
8010341f:	52                   	push   %edx
80103420:	50                   	push   %eax
80103421:	e8 a8 cd ff ff       	call   801001ce <bread>
80103426:	83 c4 10             	add    $0x10,%esp
80103429:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010342c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010342f:	83 c0 5c             	add    $0x5c,%eax
80103432:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103435:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103438:	8b 00                	mov    (%eax),%eax
8010343a:	a3 48 37 11 80       	mov    %eax,0x80113748
  for (i = 0; i < log.lh.n; i++) {
8010343f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103446:	eb 1b                	jmp    80103463 <read_head+0x59>
    log.lh.block[i] = lh->block[i];
80103448:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010344b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010344e:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103452:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103455:	83 c2 10             	add    $0x10,%edx
80103458:	89 04 95 0c 37 11 80 	mov    %eax,-0x7feec8f4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
8010345f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103463:	a1 48 37 11 80       	mov    0x80113748,%eax
80103468:	39 45 f4             	cmp    %eax,-0xc(%ebp)
8010346b:	7c db                	jl     80103448 <read_head+0x3e>
  }
  brelse(buf);
8010346d:	83 ec 0c             	sub    $0xc,%esp
80103470:	ff 75 f0             	pushl  -0x10(%ebp)
80103473:	e8 d8 cd ff ff       	call   80100250 <brelse>
80103478:	83 c4 10             	add    $0x10,%esp
}
8010347b:	90                   	nop
8010347c:	c9                   	leave  
8010347d:	c3                   	ret    

8010347e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010347e:	55                   	push   %ebp
8010347f:	89 e5                	mov    %esp,%ebp
80103481:	83 ec 18             	sub    $0x18,%esp
  struct buf *buf = bread(log.dev, log.start);
80103484:	a1 34 37 11 80       	mov    0x80113734,%eax
80103489:	89 c2                	mov    %eax,%edx
8010348b:	a1 44 37 11 80       	mov    0x80113744,%eax
80103490:	83 ec 08             	sub    $0x8,%esp
80103493:	52                   	push   %edx
80103494:	50                   	push   %eax
80103495:	e8 34 cd ff ff       	call   801001ce <bread>
8010349a:	83 c4 10             	add    $0x10,%esp
8010349d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801034a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034a3:	83 c0 5c             	add    $0x5c,%eax
801034a6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801034a9:	8b 15 48 37 11 80    	mov    0x80113748,%edx
801034af:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034b2:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801034b4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801034bb:	eb 1b                	jmp    801034d8 <write_head+0x5a>
    hb->block[i] = log.lh.block[i];
801034bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034c0:	83 c0 10             	add    $0x10,%eax
801034c3:	8b 0c 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%ecx
801034ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801034d0:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801034d4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801034d8:	a1 48 37 11 80       	mov    0x80113748,%eax
801034dd:	39 45 f4             	cmp    %eax,-0xc(%ebp)
801034e0:	7c db                	jl     801034bd <write_head+0x3f>
  }
  bwrite(buf);
801034e2:	83 ec 0c             	sub    $0xc,%esp
801034e5:	ff 75 f0             	pushl  -0x10(%ebp)
801034e8:	e8 1a cd ff ff       	call   80100207 <bwrite>
801034ed:	83 c4 10             	add    $0x10,%esp
  brelse(buf);
801034f0:	83 ec 0c             	sub    $0xc,%esp
801034f3:	ff 75 f0             	pushl  -0x10(%ebp)
801034f6:	e8 55 cd ff ff       	call   80100250 <brelse>
801034fb:	83 c4 10             	add    $0x10,%esp
}
801034fe:	90                   	nop
801034ff:	c9                   	leave  
80103500:	c3                   	ret    

80103501 <recover_from_log>:

static void
recover_from_log(void)
{
80103501:	55                   	push   %ebp
80103502:	89 e5                	mov    %esp,%ebp
80103504:	83 ec 08             	sub    $0x8,%esp
  read_head();
80103507:	e8 fe fe ff ff       	call   8010340a <read_head>
  install_trans(); // if committed, copy from log to disk
8010350c:	e8 41 fe ff ff       	call   80103352 <install_trans>
  log.lh.n = 0;
80103511:	c7 05 48 37 11 80 00 	movl   $0x0,0x80113748
80103518:	00 00 00 
  write_head(); // clear the log
8010351b:	e8 5e ff ff ff       	call   8010347e <write_head>
}
80103520:	90                   	nop
80103521:	c9                   	leave  
80103522:	c3                   	ret    

80103523 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103523:	55                   	push   %ebp
80103524:	89 e5                	mov    %esp,%ebp
80103526:	83 ec 08             	sub    $0x8,%esp
  acquire(&log.lock);
80103529:	83 ec 0c             	sub    $0xc,%esp
8010352c:	68 00 37 11 80       	push   $0x80113700
80103531:	e8 39 1a 00 00       	call   80104f6f <acquire>
80103536:	83 c4 10             	add    $0x10,%esp
  while(1){
    if(log.committing){
80103539:	a1 40 37 11 80       	mov    0x80113740,%eax
8010353e:	85 c0                	test   %eax,%eax
80103540:	74 17                	je     80103559 <begin_op+0x36>
      sleep(&log, &log.lock);
80103542:	83 ec 08             	sub    $0x8,%esp
80103545:	68 00 37 11 80       	push   $0x80113700
8010354a:	68 00 37 11 80       	push   $0x80113700
8010354f:	e8 dc 15 00 00       	call   80104b30 <sleep>
80103554:	83 c4 10             	add    $0x10,%esp
80103557:	eb e0                	jmp    80103539 <begin_op+0x16>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103559:	8b 0d 48 37 11 80    	mov    0x80113748,%ecx
8010355f:	a1 3c 37 11 80       	mov    0x8011373c,%eax
80103564:	8d 50 01             	lea    0x1(%eax),%edx
80103567:	89 d0                	mov    %edx,%eax
80103569:	c1 e0 02             	shl    $0x2,%eax
8010356c:	01 d0                	add    %edx,%eax
8010356e:	01 c0                	add    %eax,%eax
80103570:	01 c8                	add    %ecx,%eax
80103572:	83 f8 1e             	cmp    $0x1e,%eax
80103575:	7e 17                	jle    8010358e <begin_op+0x6b>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103577:	83 ec 08             	sub    $0x8,%esp
8010357a:	68 00 37 11 80       	push   $0x80113700
8010357f:	68 00 37 11 80       	push   $0x80113700
80103584:	e8 a7 15 00 00       	call   80104b30 <sleep>
80103589:	83 c4 10             	add    $0x10,%esp
8010358c:	eb ab                	jmp    80103539 <begin_op+0x16>
    } else {
      log.outstanding += 1;
8010358e:	a1 3c 37 11 80       	mov    0x8011373c,%eax
80103593:	83 c0 01             	add    $0x1,%eax
80103596:	a3 3c 37 11 80       	mov    %eax,0x8011373c
      release(&log.lock);
8010359b:	83 ec 0c             	sub    $0xc,%esp
8010359e:	68 00 37 11 80       	push   $0x80113700
801035a3:	e8 35 1a 00 00       	call   80104fdd <release>
801035a8:	83 c4 10             	add    $0x10,%esp
      break;
801035ab:	90                   	nop
    }
  }
}
801035ac:	90                   	nop
801035ad:	c9                   	leave  
801035ae:	c3                   	ret    

801035af <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
801035af:	55                   	push   %ebp
801035b0:	89 e5                	mov    %esp,%ebp
801035b2:	83 ec 18             	sub    $0x18,%esp
  int do_commit = 0;
801035b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801035bc:	83 ec 0c             	sub    $0xc,%esp
801035bf:	68 00 37 11 80       	push   $0x80113700
801035c4:	e8 a6 19 00 00       	call   80104f6f <acquire>
801035c9:	83 c4 10             	add    $0x10,%esp
  log.outstanding -= 1;
801035cc:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801035d1:	83 e8 01             	sub    $0x1,%eax
801035d4:	a3 3c 37 11 80       	mov    %eax,0x8011373c
  if(log.committing)
801035d9:	a1 40 37 11 80       	mov    0x80113740,%eax
801035de:	85 c0                	test   %eax,%eax
801035e0:	74 0d                	je     801035ef <end_op+0x40>
    panic("log.committing");
801035e2:	83 ec 0c             	sub    $0xc,%esp
801035e5:	68 d1 85 10 80       	push   $0x801085d1
801035ea:	e8 ad cf ff ff       	call   8010059c <panic>
  if(log.outstanding == 0){
801035ef:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801035f4:	85 c0                	test   %eax,%eax
801035f6:	75 13                	jne    8010360b <end_op+0x5c>
    do_commit = 1;
801035f8:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
801035ff:	c7 05 40 37 11 80 01 	movl   $0x1,0x80113740
80103606:	00 00 00 
80103609:	eb 10                	jmp    8010361b <end_op+0x6c>
  } else {
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
8010360b:	83 ec 0c             	sub    $0xc,%esp
8010360e:	68 00 37 11 80       	push   $0x80113700
80103613:	e8 fe 15 00 00       	call   80104c16 <wakeup>
80103618:	83 c4 10             	add    $0x10,%esp
  }
  release(&log.lock);
8010361b:	83 ec 0c             	sub    $0xc,%esp
8010361e:	68 00 37 11 80       	push   $0x80113700
80103623:	e8 b5 19 00 00       	call   80104fdd <release>
80103628:	83 c4 10             	add    $0x10,%esp

  if(do_commit){
8010362b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010362f:	74 3f                	je     80103670 <end_op+0xc1>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103631:	e8 f5 00 00 00       	call   8010372b <commit>
    acquire(&log.lock);
80103636:	83 ec 0c             	sub    $0xc,%esp
80103639:	68 00 37 11 80       	push   $0x80113700
8010363e:	e8 2c 19 00 00       	call   80104f6f <acquire>
80103643:	83 c4 10             	add    $0x10,%esp
    log.committing = 0;
80103646:	c7 05 40 37 11 80 00 	movl   $0x0,0x80113740
8010364d:	00 00 00 
    wakeup(&log);
80103650:	83 ec 0c             	sub    $0xc,%esp
80103653:	68 00 37 11 80       	push   $0x80113700
80103658:	e8 b9 15 00 00       	call   80104c16 <wakeup>
8010365d:	83 c4 10             	add    $0x10,%esp
    release(&log.lock);
80103660:	83 ec 0c             	sub    $0xc,%esp
80103663:	68 00 37 11 80       	push   $0x80113700
80103668:	e8 70 19 00 00       	call   80104fdd <release>
8010366d:	83 c4 10             	add    $0x10,%esp
  }
}
80103670:	90                   	nop
80103671:	c9                   	leave  
80103672:	c3                   	ret    

80103673 <write_log>:

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80103673:	55                   	push   %ebp
80103674:	89 e5                	mov    %esp,%ebp
80103676:	83 ec 18             	sub    $0x18,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103679:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103680:	e9 95 00 00 00       	jmp    8010371a <write_log+0xa7>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103685:	8b 15 34 37 11 80    	mov    0x80113734,%edx
8010368b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010368e:	01 d0                	add    %edx,%eax
80103690:	83 c0 01             	add    $0x1,%eax
80103693:	89 c2                	mov    %eax,%edx
80103695:	a1 44 37 11 80       	mov    0x80113744,%eax
8010369a:	83 ec 08             	sub    $0x8,%esp
8010369d:	52                   	push   %edx
8010369e:	50                   	push   %eax
8010369f:	e8 2a cb ff ff       	call   801001ce <bread>
801036a4:	83 c4 10             	add    $0x10,%esp
801036a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801036aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036ad:	83 c0 10             	add    $0x10,%eax
801036b0:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801036b7:	89 c2                	mov    %eax,%edx
801036b9:	a1 44 37 11 80       	mov    0x80113744,%eax
801036be:	83 ec 08             	sub    $0x8,%esp
801036c1:	52                   	push   %edx
801036c2:	50                   	push   %eax
801036c3:	e8 06 cb ff ff       	call   801001ce <bread>
801036c8:	83 c4 10             	add    $0x10,%esp
801036cb:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
801036ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036d1:	8d 50 5c             	lea    0x5c(%eax),%edx
801036d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036d7:	83 c0 5c             	add    $0x5c,%eax
801036da:	83 ec 04             	sub    $0x4,%esp
801036dd:	68 00 02 00 00       	push   $0x200
801036e2:	52                   	push   %edx
801036e3:	50                   	push   %eax
801036e4:	e8 cc 1b 00 00       	call   801052b5 <memmove>
801036e9:	83 c4 10             	add    $0x10,%esp
    bwrite(to);  // write the log
801036ec:	83 ec 0c             	sub    $0xc,%esp
801036ef:	ff 75 f0             	pushl  -0x10(%ebp)
801036f2:	e8 10 cb ff ff       	call   80100207 <bwrite>
801036f7:	83 c4 10             	add    $0x10,%esp
    brelse(from);
801036fa:	83 ec 0c             	sub    $0xc,%esp
801036fd:	ff 75 ec             	pushl  -0x14(%ebp)
80103700:	e8 4b cb ff ff       	call   80100250 <brelse>
80103705:	83 c4 10             	add    $0x10,%esp
    brelse(to);
80103708:	83 ec 0c             	sub    $0xc,%esp
8010370b:	ff 75 f0             	pushl  -0x10(%ebp)
8010370e:	e8 3d cb ff ff       	call   80100250 <brelse>
80103713:	83 c4 10             	add    $0x10,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80103716:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010371a:	a1 48 37 11 80       	mov    0x80113748,%eax
8010371f:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80103722:	0f 8c 5d ff ff ff    	jl     80103685 <write_log+0x12>
  }
}
80103728:	90                   	nop
80103729:	c9                   	leave  
8010372a:	c3                   	ret    

8010372b <commit>:

static void
commit()
{
8010372b:	55                   	push   %ebp
8010372c:	89 e5                	mov    %esp,%ebp
8010372e:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103731:	a1 48 37 11 80       	mov    0x80113748,%eax
80103736:	85 c0                	test   %eax,%eax
80103738:	7e 1e                	jle    80103758 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
8010373a:	e8 34 ff ff ff       	call   80103673 <write_log>
    write_head();    // Write header to disk -- the real commit
8010373f:	e8 3a fd ff ff       	call   8010347e <write_head>
    install_trans(); // Now install writes to home locations
80103744:	e8 09 fc ff ff       	call   80103352 <install_trans>
    log.lh.n = 0;
80103749:	c7 05 48 37 11 80 00 	movl   $0x0,0x80113748
80103750:	00 00 00 
    write_head();    // Erase the transaction from the log
80103753:	e8 26 fd ff ff       	call   8010347e <write_head>
  }
}
80103758:	90                   	nop
80103759:	c9                   	leave  
8010375a:	c3                   	ret    

8010375b <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010375b:	55                   	push   %ebp
8010375c:	89 e5                	mov    %esp,%ebp
8010375e:	83 ec 18             	sub    $0x18,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103761:	a1 48 37 11 80       	mov    0x80113748,%eax
80103766:	83 f8 1d             	cmp    $0x1d,%eax
80103769:	7f 12                	jg     8010377d <log_write+0x22>
8010376b:	a1 48 37 11 80       	mov    0x80113748,%eax
80103770:	8b 15 38 37 11 80    	mov    0x80113738,%edx
80103776:	83 ea 01             	sub    $0x1,%edx
80103779:	39 d0                	cmp    %edx,%eax
8010377b:	7c 0d                	jl     8010378a <log_write+0x2f>
    panic("too big a transaction");
8010377d:	83 ec 0c             	sub    $0xc,%esp
80103780:	68 e0 85 10 80       	push   $0x801085e0
80103785:	e8 12 ce ff ff       	call   8010059c <panic>
  if (log.outstanding < 1)
8010378a:	a1 3c 37 11 80       	mov    0x8011373c,%eax
8010378f:	85 c0                	test   %eax,%eax
80103791:	7f 0d                	jg     801037a0 <log_write+0x45>
    panic("log_write outside of trans");
80103793:	83 ec 0c             	sub    $0xc,%esp
80103796:	68 f6 85 10 80       	push   $0x801085f6
8010379b:	e8 fc cd ff ff       	call   8010059c <panic>

  acquire(&log.lock);
801037a0:	83 ec 0c             	sub    $0xc,%esp
801037a3:	68 00 37 11 80       	push   $0x80113700
801037a8:	e8 c2 17 00 00       	call   80104f6f <acquire>
801037ad:	83 c4 10             	add    $0x10,%esp
  for (i = 0; i < log.lh.n; i++) {
801037b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801037b7:	eb 1d                	jmp    801037d6 <log_write+0x7b>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
801037b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037bc:	83 c0 10             	add    $0x10,%eax
801037bf:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801037c6:	89 c2                	mov    %eax,%edx
801037c8:	8b 45 08             	mov    0x8(%ebp),%eax
801037cb:	8b 40 08             	mov    0x8(%eax),%eax
801037ce:	39 c2                	cmp    %eax,%edx
801037d0:	74 10                	je     801037e2 <log_write+0x87>
  for (i = 0; i < log.lh.n; i++) {
801037d2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037d6:	a1 48 37 11 80       	mov    0x80113748,%eax
801037db:	39 45 f4             	cmp    %eax,-0xc(%ebp)
801037de:	7c d9                	jl     801037b9 <log_write+0x5e>
801037e0:	eb 01                	jmp    801037e3 <log_write+0x88>
      break;
801037e2:	90                   	nop
  }
  log.lh.block[i] = b->blockno;
801037e3:	8b 45 08             	mov    0x8(%ebp),%eax
801037e6:	8b 40 08             	mov    0x8(%eax),%eax
801037e9:	89 c2                	mov    %eax,%edx
801037eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037ee:	83 c0 10             	add    $0x10,%eax
801037f1:	89 14 85 0c 37 11 80 	mov    %edx,-0x7feec8f4(,%eax,4)
  if (i == log.lh.n)
801037f8:	a1 48 37 11 80       	mov    0x80113748,%eax
801037fd:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80103800:	75 0d                	jne    8010380f <log_write+0xb4>
    log.lh.n++;
80103802:	a1 48 37 11 80       	mov    0x80113748,%eax
80103807:	83 c0 01             	add    $0x1,%eax
8010380a:	a3 48 37 11 80       	mov    %eax,0x80113748
  b->flags |= B_DIRTY; // prevent eviction
8010380f:	8b 45 08             	mov    0x8(%ebp),%eax
80103812:	8b 00                	mov    (%eax),%eax
80103814:	83 c8 04             	or     $0x4,%eax
80103817:	89 c2                	mov    %eax,%edx
80103819:	8b 45 08             	mov    0x8(%ebp),%eax
8010381c:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
8010381e:	83 ec 0c             	sub    $0xc,%esp
80103821:	68 00 37 11 80       	push   $0x80113700
80103826:	e8 b2 17 00 00       	call   80104fdd <release>
8010382b:	83 c4 10             	add    $0x10,%esp
}
8010382e:	90                   	nop
8010382f:	c9                   	leave  
80103830:	c3                   	ret    

80103831 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103831:	55                   	push   %ebp
80103832:	89 e5                	mov    %esp,%ebp
80103834:	83 ec 10             	sub    $0x10,%esp
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103837:	8b 55 08             	mov    0x8(%ebp),%edx
8010383a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010383d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103840:	f0 87 02             	lock xchg %eax,(%edx)
80103843:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103846:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103849:	c9                   	leave  
8010384a:	c3                   	ret    

8010384b <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010384b:	8d 4c 24 04          	lea    0x4(%esp),%ecx
8010384f:	83 e4 f0             	and    $0xfffffff0,%esp
80103852:	ff 71 fc             	pushl  -0x4(%ecx)
80103855:	55                   	push   %ebp
80103856:	89 e5                	mov    %esp,%ebp
80103858:	51                   	push   %ecx
80103859:	83 ec 04             	sub    $0x4,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010385c:	83 ec 08             	sub    $0x8,%esp
8010385f:	68 00 00 40 80       	push   $0x80400000
80103864:	68 28 65 11 80       	push   $0x80116528
80103869:	e8 df f2 ff ff       	call   80102b4d <kinit1>
8010386e:	83 c4 10             	add    $0x10,%esp
  kvmalloc();      // kernel page table
80103871:	e8 27 43 00 00       	call   80107b9d <kvmalloc>
  mpinit();        // detect other processors
80103876:	e8 ba 03 00 00       	call   80103c35 <mpinit>
  lapicinit();     // interrupt controller
8010387b:	e8 39 f6 ff ff       	call   80102eb9 <lapicinit>
  seginit();       // segment descriptors
80103880:	e8 03 3e 00 00       	call   80107688 <seginit>
  picinit();       // disable pic
80103885:	e8 fc 04 00 00       	call   80103d86 <picinit>
  ioapicinit();    // another interrupt controller
8010388a:	e8 da f1 ff ff       	call   80102a69 <ioapicinit>
  consoleinit();   // console hardware
8010388f:	e8 bb d2 ff ff       	call   80100b4f <consoleinit>
  uartinit();      // serial port
80103894:	e8 88 31 00 00       	call   80106a21 <uartinit>
  pinit();         // process table
80103899:	e8 24 09 00 00       	call   801041c2 <pinit>
  tvinit();        // trap vectors
8010389e:	e8 60 2d 00 00       	call   80106603 <tvinit>
  binit();         // buffer cache
801038a3:	e8 8c c7 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801038a8:	e8 2c d7 ff ff       	call   80100fd9 <fileinit>
  ideinit();       // disk 
801038ad:	e8 8e ed ff ff       	call   80102640 <ideinit>
  startothers();   // start other processors
801038b2:	e8 80 00 00 00       	call   80103937 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801038b7:	83 ec 08             	sub    $0x8,%esp
801038ba:	68 00 00 00 8e       	push   $0x8e000000
801038bf:	68 00 00 40 80       	push   $0x80400000
801038c4:	e8 bd f2 ff ff       	call   80102b86 <kinit2>
801038c9:	83 c4 10             	add    $0x10,%esp
  userinit();      // first user process it creates the first process by calling userinit
801038cc:	e8 d7 0a 00 00       	call   801043a8 <userinit>
  mpmain();        // finish this processor's setup
801038d1:	e8 1a 00 00 00       	call   801038f0 <mpmain>

801038d6 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801038d6:	55                   	push   %ebp
801038d7:	89 e5                	mov    %esp,%ebp
801038d9:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
801038dc:	e8 d4 42 00 00       	call   80107bb5 <switchkvm>
  seginit();
801038e1:	e8 a2 3d 00 00       	call   80107688 <seginit>
  lapicinit();
801038e6:	e8 ce f5 ff ff       	call   80102eb9 <lapicinit>
  mpmain();
801038eb:	e8 00 00 00 00       	call   801038f0 <mpmain>

801038f0 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801038f0:	55                   	push   %ebp
801038f1:	89 e5                	mov    %esp,%ebp
801038f3:	53                   	push   %ebx
801038f4:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
801038f7:	e8 e4 08 00 00       	call   801041e0 <cpuid>
801038fc:	89 c3                	mov    %eax,%ebx
801038fe:	e8 dd 08 00 00       	call   801041e0 <cpuid>
80103903:	83 ec 04             	sub    $0x4,%esp
80103906:	53                   	push   %ebx
80103907:	50                   	push   %eax
80103908:	68 11 86 10 80       	push   $0x80108611
8010390d:	e8 ea ca ff ff       	call   801003fc <cprintf>
80103912:	83 c4 10             	add    $0x10,%esp
  idtinit();       // load idt register
80103915:	e8 5f 2e 00 00       	call   80106779 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
8010391a:	e8 e2 08 00 00       	call   80104201 <mycpu>
8010391f:	05 a0 00 00 00       	add    $0xa0,%eax
80103924:	83 ec 08             	sub    $0x8,%esp
80103927:	6a 01                	push   $0x1
80103929:	50                   	push   %eax
8010392a:	e8 02 ff ff ff       	call   80103831 <xchg>
8010392f:	83 c4 10             	add    $0x10,%esp
  scheduler();     // start running processes
80103932:	e8 06 10 00 00       	call   8010493d <scheduler>

80103937 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103937:	55                   	push   %ebp
80103938:	89 e5                	mov    %esp,%ebp
8010393a:	83 ec 18             	sub    $0x18,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
8010393d:	c7 45 f0 00 70 00 80 	movl   $0x80007000,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103944:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103949:	83 ec 04             	sub    $0x4,%esp
8010394c:	50                   	push   %eax
8010394d:	68 ec b4 10 80       	push   $0x8010b4ec
80103952:	ff 75 f0             	pushl  -0x10(%ebp)
80103955:	e8 5b 19 00 00       	call   801052b5 <memmove>
8010395a:	83 c4 10             	add    $0x10,%esp

  for(c = cpus; c < cpus+ncpu; c++){
8010395d:	c7 45 f4 00 38 11 80 	movl   $0x80113800,-0xc(%ebp)
80103964:	eb 79                	jmp    801039df <startothers+0xa8>
    if(c == mycpu())  // We've started already.
80103966:	e8 96 08 00 00       	call   80104201 <mycpu>
8010396b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
8010396e:	74 67                	je     801039d7 <startothers+0xa0>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103970:	e8 0c f3 ff ff       	call   80102c81 <kalloc>
80103975:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103978:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010397b:	83 e8 04             	sub    $0x4,%eax
8010397e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103981:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103987:	89 10                	mov    %edx,(%eax)
    *(void(**)(void))(code-8) = mpenter;
80103989:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010398c:	83 e8 08             	sub    $0x8,%eax
8010398f:	c7 00 d6 38 10 80    	movl   $0x801038d6,(%eax)
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80103995:	b8 00 a0 10 80       	mov    $0x8010a000,%eax
8010399a:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
801039a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039a3:	83 e8 0c             	sub    $0xc,%eax
801039a6:	89 10                	mov    %edx,(%eax)

    lapicstartap(c->apicid, V2P(code));
801039a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039ab:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
801039b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039b4:	0f b6 00             	movzbl (%eax),%eax
801039b7:	0f b6 c0             	movzbl %al,%eax
801039ba:	83 ec 08             	sub    $0x8,%esp
801039bd:	52                   	push   %edx
801039be:	50                   	push   %eax
801039bf:	e8 56 f6 ff ff       	call   8010301a <lapicstartap>
801039c4:	83 c4 10             	add    $0x10,%esp

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801039c7:	90                   	nop
801039c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039cb:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
801039d1:	85 c0                	test   %eax,%eax
801039d3:	74 f3                	je     801039c8 <startothers+0x91>
801039d5:	eb 01                	jmp    801039d8 <startothers+0xa1>
      continue;
801039d7:	90                   	nop
  for(c = cpus; c < cpus+ncpu; c++){
801039d8:	81 45 f4 b0 00 00 00 	addl   $0xb0,-0xc(%ebp)
801039df:	a1 80 3d 11 80       	mov    0x80113d80,%eax
801039e4:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
801039ea:	05 00 38 11 80       	add    $0x80113800,%eax
801039ef:	39 45 f4             	cmp    %eax,-0xc(%ebp)
801039f2:	0f 82 6e ff ff ff    	jb     80103966 <startothers+0x2f>
      ;
  }
}
801039f8:	90                   	nop
801039f9:	c9                   	leave  
801039fa:	c3                   	ret    

801039fb <inb>:
{
801039fb:	55                   	push   %ebp
801039fc:	89 e5                	mov    %esp,%ebp
801039fe:	83 ec 14             	sub    $0x14,%esp
80103a01:	8b 45 08             	mov    0x8(%ebp),%eax
80103a04:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103a08:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103a0c:	89 c2                	mov    %eax,%edx
80103a0e:	ec                   	in     (%dx),%al
80103a0f:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103a12:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103a16:	c9                   	leave  
80103a17:	c3                   	ret    

80103a18 <outb>:
{
80103a18:	55                   	push   %ebp
80103a19:	89 e5                	mov    %esp,%ebp
80103a1b:	83 ec 08             	sub    $0x8,%esp
80103a1e:	8b 55 08             	mov    0x8(%ebp),%edx
80103a21:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a24:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103a28:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103a2b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103a2f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103a33:	ee                   	out    %al,(%dx)
}
80103a34:	90                   	nop
80103a35:	c9                   	leave  
80103a36:	c3                   	ret    

80103a37 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80103a37:	55                   	push   %ebp
80103a38:	89 e5                	mov    %esp,%ebp
80103a3a:	83 ec 10             	sub    $0x10,%esp
  int i, sum;

  sum = 0;
80103a3d:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103a44:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103a4b:	eb 15                	jmp    80103a62 <sum+0x2b>
    sum += addr[i];
80103a4d:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103a50:	8b 45 08             	mov    0x8(%ebp),%eax
80103a53:	01 d0                	add    %edx,%eax
80103a55:	0f b6 00             	movzbl (%eax),%eax
80103a58:	0f b6 c0             	movzbl %al,%eax
80103a5b:	01 45 f8             	add    %eax,-0x8(%ebp)
  for(i=0; i<len; i++)
80103a5e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103a62:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a65:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103a68:	7c e3                	jl     80103a4d <sum+0x16>
  return sum;
80103a6a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103a6d:	c9                   	leave  
80103a6e:	c3                   	ret    

80103a6f <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103a6f:	55                   	push   %ebp
80103a70:	89 e5                	mov    %esp,%ebp
80103a72:	83 ec 18             	sub    $0x18,%esp
  uchar *e, *p, *addr;

  addr = P2V(a);
80103a75:	8b 45 08             	mov    0x8(%ebp),%eax
80103a78:	05 00 00 00 80       	add    $0x80000000,%eax
80103a7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103a80:	8b 55 0c             	mov    0xc(%ebp),%edx
80103a83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a86:	01 d0                	add    %edx,%eax
80103a88:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103a8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a91:	eb 36                	jmp    80103ac9 <mpsearch1+0x5a>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103a93:	83 ec 04             	sub    $0x4,%esp
80103a96:	6a 04                	push   $0x4
80103a98:	68 28 86 10 80       	push   $0x80108628
80103a9d:	ff 75 f4             	pushl  -0xc(%ebp)
80103aa0:	e8 b8 17 00 00       	call   8010525d <memcmp>
80103aa5:	83 c4 10             	add    $0x10,%esp
80103aa8:	85 c0                	test   %eax,%eax
80103aaa:	75 19                	jne    80103ac5 <mpsearch1+0x56>
80103aac:	83 ec 08             	sub    $0x8,%esp
80103aaf:	6a 10                	push   $0x10
80103ab1:	ff 75 f4             	pushl  -0xc(%ebp)
80103ab4:	e8 7e ff ff ff       	call   80103a37 <sum>
80103ab9:	83 c4 10             	add    $0x10,%esp
80103abc:	84 c0                	test   %al,%al
80103abe:	75 05                	jne    80103ac5 <mpsearch1+0x56>
      return (struct mp*)p;
80103ac0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ac3:	eb 11                	jmp    80103ad6 <mpsearch1+0x67>
  for(p = addr; p < e; p += sizeof(struct mp))
80103ac5:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103ac9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103acc:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103acf:	72 c2                	jb     80103a93 <mpsearch1+0x24>
  return 0;
80103ad1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103ad6:	c9                   	leave  
80103ad7:	c3                   	ret    

80103ad8 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103ad8:	55                   	push   %ebp
80103ad9:	89 e5                	mov    %esp,%ebp
80103adb:	83 ec 18             	sub    $0x18,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103ade:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103ae5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ae8:	83 c0 0f             	add    $0xf,%eax
80103aeb:	0f b6 00             	movzbl (%eax),%eax
80103aee:	0f b6 c0             	movzbl %al,%eax
80103af1:	c1 e0 08             	shl    $0x8,%eax
80103af4:	89 c2                	mov    %eax,%edx
80103af6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103af9:	83 c0 0e             	add    $0xe,%eax
80103afc:	0f b6 00             	movzbl (%eax),%eax
80103aff:	0f b6 c0             	movzbl %al,%eax
80103b02:	09 d0                	or     %edx,%eax
80103b04:	c1 e0 04             	shl    $0x4,%eax
80103b07:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103b0a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103b0e:	74 21                	je     80103b31 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103b10:	83 ec 08             	sub    $0x8,%esp
80103b13:	68 00 04 00 00       	push   $0x400
80103b18:	ff 75 f0             	pushl  -0x10(%ebp)
80103b1b:	e8 4f ff ff ff       	call   80103a6f <mpsearch1>
80103b20:	83 c4 10             	add    $0x10,%esp
80103b23:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b26:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b2a:	74 51                	je     80103b7d <mpsearch+0xa5>
      return mp;
80103b2c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b2f:	eb 61                	jmp    80103b92 <mpsearch+0xba>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103b31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b34:	83 c0 14             	add    $0x14,%eax
80103b37:	0f b6 00             	movzbl (%eax),%eax
80103b3a:	0f b6 c0             	movzbl %al,%eax
80103b3d:	c1 e0 08             	shl    $0x8,%eax
80103b40:	89 c2                	mov    %eax,%edx
80103b42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b45:	83 c0 13             	add    $0x13,%eax
80103b48:	0f b6 00             	movzbl (%eax),%eax
80103b4b:	0f b6 c0             	movzbl %al,%eax
80103b4e:	09 d0                	or     %edx,%eax
80103b50:	c1 e0 0a             	shl    $0xa,%eax
80103b53:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103b56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b59:	2d 00 04 00 00       	sub    $0x400,%eax
80103b5e:	83 ec 08             	sub    $0x8,%esp
80103b61:	68 00 04 00 00       	push   $0x400
80103b66:	50                   	push   %eax
80103b67:	e8 03 ff ff ff       	call   80103a6f <mpsearch1>
80103b6c:	83 c4 10             	add    $0x10,%esp
80103b6f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b72:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b76:	74 05                	je     80103b7d <mpsearch+0xa5>
      return mp;
80103b78:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b7b:	eb 15                	jmp    80103b92 <mpsearch+0xba>
  }
  return mpsearch1(0xF0000, 0x10000);
80103b7d:	83 ec 08             	sub    $0x8,%esp
80103b80:	68 00 00 01 00       	push   $0x10000
80103b85:	68 00 00 0f 00       	push   $0xf0000
80103b8a:	e8 e0 fe ff ff       	call   80103a6f <mpsearch1>
80103b8f:	83 c4 10             	add    $0x10,%esp
}
80103b92:	c9                   	leave  
80103b93:	c3                   	ret    

80103b94 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103b94:	55                   	push   %ebp
80103b95:	89 e5                	mov    %esp,%ebp
80103b97:	83 ec 18             	sub    $0x18,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103b9a:	e8 39 ff ff ff       	call   80103ad8 <mpsearch>
80103b9f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103ba2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103ba6:	74 0a                	je     80103bb2 <mpconfig+0x1e>
80103ba8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bab:	8b 40 04             	mov    0x4(%eax),%eax
80103bae:	85 c0                	test   %eax,%eax
80103bb0:	75 07                	jne    80103bb9 <mpconfig+0x25>
    return 0;
80103bb2:	b8 00 00 00 00       	mov    $0x0,%eax
80103bb7:	eb 7a                	jmp    80103c33 <mpconfig+0x9f>
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80103bb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bbc:	8b 40 04             	mov    0x4(%eax),%eax
80103bbf:	05 00 00 00 80       	add    $0x80000000,%eax
80103bc4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103bc7:	83 ec 04             	sub    $0x4,%esp
80103bca:	6a 04                	push   $0x4
80103bcc:	68 2d 86 10 80       	push   $0x8010862d
80103bd1:	ff 75 f0             	pushl  -0x10(%ebp)
80103bd4:	e8 84 16 00 00       	call   8010525d <memcmp>
80103bd9:	83 c4 10             	add    $0x10,%esp
80103bdc:	85 c0                	test   %eax,%eax
80103bde:	74 07                	je     80103be7 <mpconfig+0x53>
    return 0;
80103be0:	b8 00 00 00 00       	mov    $0x0,%eax
80103be5:	eb 4c                	jmp    80103c33 <mpconfig+0x9f>
  if(conf->version != 1 && conf->version != 4)
80103be7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bea:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103bee:	3c 01                	cmp    $0x1,%al
80103bf0:	74 12                	je     80103c04 <mpconfig+0x70>
80103bf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bf5:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103bf9:	3c 04                	cmp    $0x4,%al
80103bfb:	74 07                	je     80103c04 <mpconfig+0x70>
    return 0;
80103bfd:	b8 00 00 00 00       	mov    $0x0,%eax
80103c02:	eb 2f                	jmp    80103c33 <mpconfig+0x9f>
  if(sum((uchar*)conf, conf->length) != 0)
80103c04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c07:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c0b:	0f b7 c0             	movzwl %ax,%eax
80103c0e:	83 ec 08             	sub    $0x8,%esp
80103c11:	50                   	push   %eax
80103c12:	ff 75 f0             	pushl  -0x10(%ebp)
80103c15:	e8 1d fe ff ff       	call   80103a37 <sum>
80103c1a:	83 c4 10             	add    $0x10,%esp
80103c1d:	84 c0                	test   %al,%al
80103c1f:	74 07                	je     80103c28 <mpconfig+0x94>
    return 0;
80103c21:	b8 00 00 00 00       	mov    $0x0,%eax
80103c26:	eb 0b                	jmp    80103c33 <mpconfig+0x9f>
  *pmp = mp;
80103c28:	8b 45 08             	mov    0x8(%ebp),%eax
80103c2b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103c2e:	89 10                	mov    %edx,(%eax)
  return conf;
80103c30:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103c33:	c9                   	leave  
80103c34:	c3                   	ret    

80103c35 <mpinit>:

void
mpinit(void)
{
80103c35:	55                   	push   %ebp
80103c36:	89 e5                	mov    %esp,%ebp
80103c38:	83 ec 28             	sub    $0x28,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80103c3b:	83 ec 0c             	sub    $0xc,%esp
80103c3e:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103c41:	50                   	push   %eax
80103c42:	e8 4d ff ff ff       	call   80103b94 <mpconfig>
80103c47:	83 c4 10             	add    $0x10,%esp
80103c4a:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c4d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c51:	75 0d                	jne    80103c60 <mpinit+0x2b>
    panic("Expect to run on an SMP");
80103c53:	83 ec 0c             	sub    $0xc,%esp
80103c56:	68 32 86 10 80       	push   $0x80108632
80103c5b:	e8 3c c9 ff ff       	call   8010059c <panic>
  ismp = 1;
80103c60:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
  lapic = (uint*)conf->lapicaddr;
80103c67:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c6a:	8b 40 24             	mov    0x24(%eax),%eax
80103c6d:	a3 fc 36 11 80       	mov    %eax,0x801136fc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103c72:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c75:	83 c0 2c             	add    $0x2c,%eax
80103c78:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c7b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c7e:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c82:	0f b7 d0             	movzwl %ax,%edx
80103c85:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c88:	01 d0                	add    %edx,%eax
80103c8a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80103c8d:	eb 7b                	jmp    80103d0a <mpinit+0xd5>
    switch(*p){
80103c8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c92:	0f b6 00             	movzbl (%eax),%eax
80103c95:	0f b6 c0             	movzbl %al,%eax
80103c98:	83 f8 04             	cmp    $0x4,%eax
80103c9b:	77 65                	ja     80103d02 <mpinit+0xcd>
80103c9d:	8b 04 85 6c 86 10 80 	mov    -0x7fef7994(,%eax,4),%eax
80103ca4:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103ca6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ca9:	89 45 e0             	mov    %eax,-0x20(%ebp)
      if(ncpu < NCPU) {
80103cac:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80103cb1:	83 f8 07             	cmp    $0x7,%eax
80103cb4:	7f 28                	jg     80103cde <mpinit+0xa9>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80103cb6:	8b 15 80 3d 11 80    	mov    0x80113d80,%edx
80103cbc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103cbf:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103cc3:	69 d2 b0 00 00 00    	imul   $0xb0,%edx,%edx
80103cc9:	81 c2 00 38 11 80    	add    $0x80113800,%edx
80103ccf:	88 02                	mov    %al,(%edx)
        ncpu++;
80103cd1:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80103cd6:	83 c0 01             	add    $0x1,%eax
80103cd9:	a3 80 3d 11 80       	mov    %eax,0x80113d80
      }
      p += sizeof(struct mpproc);
80103cde:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103ce2:	eb 26                	jmp    80103d0a <mpinit+0xd5>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103ce4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ce7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103cea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103ced:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103cf1:	a2 e0 37 11 80       	mov    %al,0x801137e0
      p += sizeof(struct mpioapic);
80103cf6:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103cfa:	eb 0e                	jmp    80103d0a <mpinit+0xd5>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103cfc:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103d00:	eb 08                	jmp    80103d0a <mpinit+0xd5>
    default:
      ismp = 0;
80103d02:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      break;
80103d09:	90                   	nop
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103d0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d0d:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80103d10:	0f 82 79 ff ff ff    	jb     80103c8f <mpinit+0x5a>
    }
  }
  if(!ismp)
80103d16:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103d1a:	75 0d                	jne    80103d29 <mpinit+0xf4>
    panic("Didn't find a suitable machine");
80103d1c:	83 ec 0c             	sub    $0xc,%esp
80103d1f:	68 4c 86 10 80       	push   $0x8010864c
80103d24:	e8 73 c8 ff ff       	call   8010059c <panic>

  if(mp->imcrp){
80103d29:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103d2c:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103d30:	84 c0                	test   %al,%al
80103d32:	74 30                	je     80103d64 <mpinit+0x12f>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103d34:	83 ec 08             	sub    $0x8,%esp
80103d37:	6a 70                	push   $0x70
80103d39:	6a 22                	push   $0x22
80103d3b:	e8 d8 fc ff ff       	call   80103a18 <outb>
80103d40:	83 c4 10             	add    $0x10,%esp
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103d43:	83 ec 0c             	sub    $0xc,%esp
80103d46:	6a 23                	push   $0x23
80103d48:	e8 ae fc ff ff       	call   801039fb <inb>
80103d4d:	83 c4 10             	add    $0x10,%esp
80103d50:	83 c8 01             	or     $0x1,%eax
80103d53:	0f b6 c0             	movzbl %al,%eax
80103d56:	83 ec 08             	sub    $0x8,%esp
80103d59:	50                   	push   %eax
80103d5a:	6a 23                	push   $0x23
80103d5c:	e8 b7 fc ff ff       	call   80103a18 <outb>
80103d61:	83 c4 10             	add    $0x10,%esp
  }
}
80103d64:	90                   	nop
80103d65:	c9                   	leave  
80103d66:	c3                   	ret    

80103d67 <outb>:
{
80103d67:	55                   	push   %ebp
80103d68:	89 e5                	mov    %esp,%ebp
80103d6a:	83 ec 08             	sub    $0x8,%esp
80103d6d:	8b 55 08             	mov    0x8(%ebp),%edx
80103d70:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d73:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103d77:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103d7a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103d7e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103d82:	ee                   	out    %al,(%dx)
}
80103d83:	90                   	nop
80103d84:	c9                   	leave  
80103d85:	c3                   	ret    

80103d86 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80103d86:	55                   	push   %ebp
80103d87:	89 e5                	mov    %esp,%ebp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103d89:	68 ff 00 00 00       	push   $0xff
80103d8e:	6a 21                	push   $0x21
80103d90:	e8 d2 ff ff ff       	call   80103d67 <outb>
80103d95:	83 c4 08             	add    $0x8,%esp
  outb(IO_PIC2+1, 0xFF);
80103d98:	68 ff 00 00 00       	push   $0xff
80103d9d:	68 a1 00 00 00       	push   $0xa1
80103da2:	e8 c0 ff ff ff       	call   80103d67 <outb>
80103da7:	83 c4 08             	add    $0x8,%esp
}
80103daa:	90                   	nop
80103dab:	c9                   	leave  
80103dac:	c3                   	ret    

80103dad <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103dad:	55                   	push   %ebp
80103dae:	89 e5                	mov    %esp,%ebp
80103db0:	83 ec 18             	sub    $0x18,%esp
  struct pipe *p;

  p = 0;
80103db3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103dba:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dbd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103dc3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dc6:	8b 10                	mov    (%eax),%edx
80103dc8:	8b 45 08             	mov    0x8(%ebp),%eax
80103dcb:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103dcd:	e8 25 d2 ff ff       	call   80100ff7 <filealloc>
80103dd2:	89 c2                	mov    %eax,%edx
80103dd4:	8b 45 08             	mov    0x8(%ebp),%eax
80103dd7:	89 10                	mov    %edx,(%eax)
80103dd9:	8b 45 08             	mov    0x8(%ebp),%eax
80103ddc:	8b 00                	mov    (%eax),%eax
80103dde:	85 c0                	test   %eax,%eax
80103de0:	0f 84 ca 00 00 00    	je     80103eb0 <pipealloc+0x103>
80103de6:	e8 0c d2 ff ff       	call   80100ff7 <filealloc>
80103deb:	89 c2                	mov    %eax,%edx
80103ded:	8b 45 0c             	mov    0xc(%ebp),%eax
80103df0:	89 10                	mov    %edx,(%eax)
80103df2:	8b 45 0c             	mov    0xc(%ebp),%eax
80103df5:	8b 00                	mov    (%eax),%eax
80103df7:	85 c0                	test   %eax,%eax
80103df9:	0f 84 b1 00 00 00    	je     80103eb0 <pipealloc+0x103>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103dff:	e8 7d ee ff ff       	call   80102c81 <kalloc>
80103e04:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103e07:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103e0b:	0f 84 a2 00 00 00    	je     80103eb3 <pipealloc+0x106>
    goto bad;
  p->readopen = 1;
80103e11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e14:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103e1b:	00 00 00 
  p->writeopen = 1;
80103e1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e21:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103e28:	00 00 00 
  p->nwrite = 0;
80103e2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e2e:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103e35:	00 00 00 
  p->nread = 0;
80103e38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e3b:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103e42:	00 00 00 
  initlock(&p->lock, "pipe");
80103e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e48:	83 ec 08             	sub    $0x8,%esp
80103e4b:	68 80 86 10 80       	push   $0x80108680
80103e50:	50                   	push   %eax
80103e51:	e8 f7 10 00 00       	call   80104f4d <initlock>
80103e56:	83 c4 10             	add    $0x10,%esp
  (*f0)->type = FD_PIPE;
80103e59:	8b 45 08             	mov    0x8(%ebp),%eax
80103e5c:	8b 00                	mov    (%eax),%eax
80103e5e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103e64:	8b 45 08             	mov    0x8(%ebp),%eax
80103e67:	8b 00                	mov    (%eax),%eax
80103e69:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103e6d:	8b 45 08             	mov    0x8(%ebp),%eax
80103e70:	8b 00                	mov    (%eax),%eax
80103e72:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103e76:	8b 45 08             	mov    0x8(%ebp),%eax
80103e79:	8b 00                	mov    (%eax),%eax
80103e7b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e7e:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103e81:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e84:	8b 00                	mov    (%eax),%eax
80103e86:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103e8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e8f:	8b 00                	mov    (%eax),%eax
80103e91:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103e95:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e98:	8b 00                	mov    (%eax),%eax
80103e9a:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ea1:	8b 00                	mov    (%eax),%eax
80103ea3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ea6:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103ea9:	b8 00 00 00 00       	mov    $0x0,%eax
80103eae:	eb 51                	jmp    80103f01 <pipealloc+0x154>

//PAGEBREAK: 20
 bad:
80103eb0:	90                   	nop
80103eb1:	eb 01                	jmp    80103eb4 <pipealloc+0x107>
    goto bad;
80103eb3:	90                   	nop
  if(p)
80103eb4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103eb8:	74 0e                	je     80103ec8 <pipealloc+0x11b>
    kfree((char*)p);
80103eba:	83 ec 0c             	sub    $0xc,%esp
80103ebd:	ff 75 f4             	pushl  -0xc(%ebp)
80103ec0:	e8 22 ed ff ff       	call   80102be7 <kfree>
80103ec5:	83 c4 10             	add    $0x10,%esp
  if(*f0)
80103ec8:	8b 45 08             	mov    0x8(%ebp),%eax
80103ecb:	8b 00                	mov    (%eax),%eax
80103ecd:	85 c0                	test   %eax,%eax
80103ecf:	74 11                	je     80103ee2 <pipealloc+0x135>
    fileclose(*f0);
80103ed1:	8b 45 08             	mov    0x8(%ebp),%eax
80103ed4:	8b 00                	mov    (%eax),%eax
80103ed6:	83 ec 0c             	sub    $0xc,%esp
80103ed9:	50                   	push   %eax
80103eda:	e8 d6 d1 ff ff       	call   801010b5 <fileclose>
80103edf:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80103ee2:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ee5:	8b 00                	mov    (%eax),%eax
80103ee7:	85 c0                	test   %eax,%eax
80103ee9:	74 11                	je     80103efc <pipealloc+0x14f>
    fileclose(*f1);
80103eeb:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eee:	8b 00                	mov    (%eax),%eax
80103ef0:	83 ec 0c             	sub    $0xc,%esp
80103ef3:	50                   	push   %eax
80103ef4:	e8 bc d1 ff ff       	call   801010b5 <fileclose>
80103ef9:	83 c4 10             	add    $0x10,%esp
  return -1;
80103efc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f01:	c9                   	leave  
80103f02:	c3                   	ret    

80103f03 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103f03:	55                   	push   %ebp
80103f04:	89 e5                	mov    %esp,%ebp
80103f06:	83 ec 08             	sub    $0x8,%esp
  acquire(&p->lock);
80103f09:	8b 45 08             	mov    0x8(%ebp),%eax
80103f0c:	83 ec 0c             	sub    $0xc,%esp
80103f0f:	50                   	push   %eax
80103f10:	e8 5a 10 00 00       	call   80104f6f <acquire>
80103f15:	83 c4 10             	add    $0x10,%esp
  if(writable){
80103f18:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103f1c:	74 23                	je     80103f41 <pipeclose+0x3e>
    p->writeopen = 0;
80103f1e:	8b 45 08             	mov    0x8(%ebp),%eax
80103f21:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103f28:	00 00 00 
    wakeup(&p->nread);
80103f2b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f2e:	05 34 02 00 00       	add    $0x234,%eax
80103f33:	83 ec 0c             	sub    $0xc,%esp
80103f36:	50                   	push   %eax
80103f37:	e8 da 0c 00 00       	call   80104c16 <wakeup>
80103f3c:	83 c4 10             	add    $0x10,%esp
80103f3f:	eb 21                	jmp    80103f62 <pipeclose+0x5f>
  } else {
    p->readopen = 0;
80103f41:	8b 45 08             	mov    0x8(%ebp),%eax
80103f44:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103f4b:	00 00 00 
    wakeup(&p->nwrite);
80103f4e:	8b 45 08             	mov    0x8(%ebp),%eax
80103f51:	05 38 02 00 00       	add    $0x238,%eax
80103f56:	83 ec 0c             	sub    $0xc,%esp
80103f59:	50                   	push   %eax
80103f5a:	e8 b7 0c 00 00       	call   80104c16 <wakeup>
80103f5f:	83 c4 10             	add    $0x10,%esp
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103f62:	8b 45 08             	mov    0x8(%ebp),%eax
80103f65:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103f6b:	85 c0                	test   %eax,%eax
80103f6d:	75 2c                	jne    80103f9b <pipeclose+0x98>
80103f6f:	8b 45 08             	mov    0x8(%ebp),%eax
80103f72:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103f78:	85 c0                	test   %eax,%eax
80103f7a:	75 1f                	jne    80103f9b <pipeclose+0x98>
    release(&p->lock);
80103f7c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f7f:	83 ec 0c             	sub    $0xc,%esp
80103f82:	50                   	push   %eax
80103f83:	e8 55 10 00 00       	call   80104fdd <release>
80103f88:	83 c4 10             	add    $0x10,%esp
    kfree((char*)p);
80103f8b:	83 ec 0c             	sub    $0xc,%esp
80103f8e:	ff 75 08             	pushl  0x8(%ebp)
80103f91:	e8 51 ec ff ff       	call   80102be7 <kfree>
80103f96:	83 c4 10             	add    $0x10,%esp
80103f99:	eb 0f                	jmp    80103faa <pipeclose+0xa7>
  } else
    release(&p->lock);
80103f9b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f9e:	83 ec 0c             	sub    $0xc,%esp
80103fa1:	50                   	push   %eax
80103fa2:	e8 36 10 00 00       	call   80104fdd <release>
80103fa7:	83 c4 10             	add    $0x10,%esp
}
80103faa:	90                   	nop
80103fab:	c9                   	leave  
80103fac:	c3                   	ret    

80103fad <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103fad:	55                   	push   %ebp
80103fae:	89 e5                	mov    %esp,%ebp
80103fb0:	53                   	push   %ebx
80103fb1:	83 ec 14             	sub    $0x14,%esp
  int i;

  acquire(&p->lock);
80103fb4:	8b 45 08             	mov    0x8(%ebp),%eax
80103fb7:	83 ec 0c             	sub    $0xc,%esp
80103fba:	50                   	push   %eax
80103fbb:	e8 af 0f 00 00       	call   80104f6f <acquire>
80103fc0:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < n; i++){
80103fc3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103fca:	e9 ad 00 00 00       	jmp    8010407c <pipewrite+0xcf>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || myproc()->killed){
80103fcf:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd2:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103fd8:	85 c0                	test   %eax,%eax
80103fda:	74 0c                	je     80103fe8 <pipewrite+0x3b>
80103fdc:	e8 98 02 00 00       	call   80104279 <myproc>
80103fe1:	8b 40 24             	mov    0x24(%eax),%eax
80103fe4:	85 c0                	test   %eax,%eax
80103fe6:	74 19                	je     80104001 <pipewrite+0x54>
        release(&p->lock);
80103fe8:	8b 45 08             	mov    0x8(%ebp),%eax
80103feb:	83 ec 0c             	sub    $0xc,%esp
80103fee:	50                   	push   %eax
80103fef:	e8 e9 0f 00 00       	call   80104fdd <release>
80103ff4:	83 c4 10             	add    $0x10,%esp
        return -1;
80103ff7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ffc:	e9 a9 00 00 00       	jmp    801040aa <pipewrite+0xfd>
      }
      wakeup(&p->nread);
80104001:	8b 45 08             	mov    0x8(%ebp),%eax
80104004:	05 34 02 00 00       	add    $0x234,%eax
80104009:	83 ec 0c             	sub    $0xc,%esp
8010400c:	50                   	push   %eax
8010400d:	e8 04 0c 00 00       	call   80104c16 <wakeup>
80104012:	83 c4 10             	add    $0x10,%esp
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104015:	8b 45 08             	mov    0x8(%ebp),%eax
80104018:	8b 55 08             	mov    0x8(%ebp),%edx
8010401b:	81 c2 38 02 00 00    	add    $0x238,%edx
80104021:	83 ec 08             	sub    $0x8,%esp
80104024:	50                   	push   %eax
80104025:	52                   	push   %edx
80104026:	e8 05 0b 00 00       	call   80104b30 <sleep>
8010402b:	83 c4 10             	add    $0x10,%esp
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010402e:	8b 45 08             	mov    0x8(%ebp),%eax
80104031:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104037:	8b 45 08             	mov    0x8(%ebp),%eax
8010403a:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104040:	05 00 02 00 00       	add    $0x200,%eax
80104045:	39 c2                	cmp    %eax,%edx
80104047:	74 86                	je     80103fcf <pipewrite+0x22>
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104049:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010404c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010404f:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104052:	8b 45 08             	mov    0x8(%ebp),%eax
80104055:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010405b:	8d 48 01             	lea    0x1(%eax),%ecx
8010405e:	8b 55 08             	mov    0x8(%ebp),%edx
80104061:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80104067:	25 ff 01 00 00       	and    $0x1ff,%eax
8010406c:	89 c1                	mov    %eax,%ecx
8010406e:	0f b6 13             	movzbl (%ebx),%edx
80104071:	8b 45 08             	mov    0x8(%ebp),%eax
80104074:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
  for(i = 0; i < n; i++){
80104078:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010407c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010407f:	3b 45 10             	cmp    0x10(%ebp),%eax
80104082:	7c aa                	jl     8010402e <pipewrite+0x81>
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104084:	8b 45 08             	mov    0x8(%ebp),%eax
80104087:	05 34 02 00 00       	add    $0x234,%eax
8010408c:	83 ec 0c             	sub    $0xc,%esp
8010408f:	50                   	push   %eax
80104090:	e8 81 0b 00 00       	call   80104c16 <wakeup>
80104095:	83 c4 10             	add    $0x10,%esp
  release(&p->lock);
80104098:	8b 45 08             	mov    0x8(%ebp),%eax
8010409b:	83 ec 0c             	sub    $0xc,%esp
8010409e:	50                   	push   %eax
8010409f:	e8 39 0f 00 00       	call   80104fdd <release>
801040a4:	83 c4 10             	add    $0x10,%esp
  return n;
801040a7:	8b 45 10             	mov    0x10(%ebp),%eax
}
801040aa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801040ad:	c9                   	leave  
801040ae:	c3                   	ret    

801040af <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801040af:	55                   	push   %ebp
801040b0:	89 e5                	mov    %esp,%ebp
801040b2:	83 ec 18             	sub    $0x18,%esp
  int i;

  acquire(&p->lock);
801040b5:	8b 45 08             	mov    0x8(%ebp),%eax
801040b8:	83 ec 0c             	sub    $0xc,%esp
801040bb:	50                   	push   %eax
801040bc:	e8 ae 0e 00 00       	call   80104f6f <acquire>
801040c1:	83 c4 10             	add    $0x10,%esp
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801040c4:	eb 3e                	jmp    80104104 <piperead+0x55>
    if(myproc()->killed){
801040c6:	e8 ae 01 00 00       	call   80104279 <myproc>
801040cb:	8b 40 24             	mov    0x24(%eax),%eax
801040ce:	85 c0                	test   %eax,%eax
801040d0:	74 19                	je     801040eb <piperead+0x3c>
      release(&p->lock);
801040d2:	8b 45 08             	mov    0x8(%ebp),%eax
801040d5:	83 ec 0c             	sub    $0xc,%esp
801040d8:	50                   	push   %eax
801040d9:	e8 ff 0e 00 00       	call   80104fdd <release>
801040de:	83 c4 10             	add    $0x10,%esp
      return -1;
801040e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040e6:	e9 be 00 00 00       	jmp    801041a9 <piperead+0xfa>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801040eb:	8b 45 08             	mov    0x8(%ebp),%eax
801040ee:	8b 55 08             	mov    0x8(%ebp),%edx
801040f1:	81 c2 34 02 00 00    	add    $0x234,%edx
801040f7:	83 ec 08             	sub    $0x8,%esp
801040fa:	50                   	push   %eax
801040fb:	52                   	push   %edx
801040fc:	e8 2f 0a 00 00       	call   80104b30 <sleep>
80104101:	83 c4 10             	add    $0x10,%esp
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104104:	8b 45 08             	mov    0x8(%ebp),%eax
80104107:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010410d:	8b 45 08             	mov    0x8(%ebp),%eax
80104110:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104116:	39 c2                	cmp    %eax,%edx
80104118:	75 0d                	jne    80104127 <piperead+0x78>
8010411a:	8b 45 08             	mov    0x8(%ebp),%eax
8010411d:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104123:	85 c0                	test   %eax,%eax
80104125:	75 9f                	jne    801040c6 <piperead+0x17>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104127:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010412e:	eb 48                	jmp    80104178 <piperead+0xc9>
    if(p->nread == p->nwrite)
80104130:	8b 45 08             	mov    0x8(%ebp),%eax
80104133:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104139:	8b 45 08             	mov    0x8(%ebp),%eax
8010413c:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104142:	39 c2                	cmp    %eax,%edx
80104144:	74 3c                	je     80104182 <piperead+0xd3>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104146:	8b 45 08             	mov    0x8(%ebp),%eax
80104149:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010414f:	8d 48 01             	lea    0x1(%eax),%ecx
80104152:	8b 55 08             	mov    0x8(%ebp),%edx
80104155:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
8010415b:	25 ff 01 00 00       	and    $0x1ff,%eax
80104160:	89 c1                	mov    %eax,%ecx
80104162:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104165:	8b 45 0c             	mov    0xc(%ebp),%eax
80104168:	01 c2                	add    %eax,%edx
8010416a:	8b 45 08             	mov    0x8(%ebp),%eax
8010416d:	0f b6 44 08 34       	movzbl 0x34(%eax,%ecx,1),%eax
80104172:	88 02                	mov    %al,(%edx)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104174:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104178:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010417e:	7c b0                	jl     80104130 <piperead+0x81>
80104180:	eb 01                	jmp    80104183 <piperead+0xd4>
      break;
80104182:	90                   	nop
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104183:	8b 45 08             	mov    0x8(%ebp),%eax
80104186:	05 38 02 00 00       	add    $0x238,%eax
8010418b:	83 ec 0c             	sub    $0xc,%esp
8010418e:	50                   	push   %eax
8010418f:	e8 82 0a 00 00       	call   80104c16 <wakeup>
80104194:	83 c4 10             	add    $0x10,%esp
  release(&p->lock);
80104197:	8b 45 08             	mov    0x8(%ebp),%eax
8010419a:	83 ec 0c             	sub    $0xc,%esp
8010419d:	50                   	push   %eax
8010419e:	e8 3a 0e 00 00       	call   80104fdd <release>
801041a3:	83 c4 10             	add    $0x10,%esp
  return i;
801041a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801041a9:	c9                   	leave  
801041aa:	c3                   	ret    

801041ab <readeflags>:
{
801041ab:	55                   	push   %ebp
801041ac:	89 e5                	mov    %esp,%ebp
801041ae:	83 ec 10             	sub    $0x10,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801041b1:	9c                   	pushf  
801041b2:	58                   	pop    %eax
801041b3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801041b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801041b9:	c9                   	leave  
801041ba:	c3                   	ret    

801041bb <sti>:
{
801041bb:	55                   	push   %ebp
801041bc:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801041be:	fb                   	sti    
}
801041bf:	90                   	nop
801041c0:	5d                   	pop    %ebp
801041c1:	c3                   	ret    

801041c2 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801041c2:	55                   	push   %ebp
801041c3:	89 e5                	mov    %esp,%ebp
801041c5:	83 ec 08             	sub    $0x8,%esp
  initlock(&ptable.lock, "ptable");
801041c8:	83 ec 08             	sub    $0x8,%esp
801041cb:	68 88 86 10 80       	push   $0x80108688
801041d0:	68 a0 3d 11 80       	push   $0x80113da0
801041d5:	e8 73 0d 00 00       	call   80104f4d <initlock>
801041da:	83 c4 10             	add    $0x10,%esp
}
801041dd:	90                   	nop
801041de:	c9                   	leave  
801041df:	c3                   	ret    

801041e0 <cpuid>:

// Must be called with interrupts disabled
int
cpuid() {
801041e0:	55                   	push   %ebp
801041e1:	89 e5                	mov    %esp,%ebp
801041e3:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801041e6:	e8 16 00 00 00       	call   80104201 <mycpu>
801041eb:	89 c2                	mov    %eax,%edx
801041ed:	b8 00 38 11 80       	mov    $0x80113800,%eax
801041f2:	29 c2                	sub    %eax,%edx
801041f4:	89 d0                	mov    %edx,%eax
801041f6:	c1 f8 04             	sar    $0x4,%eax
801041f9:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801041ff:	c9                   	leave  
80104200:	c3                   	ret    

80104201 <mycpu>:

// Must be called with interrupts disabled to avoid the caller being
// rescheduled between reading lapicid and running through the loop.
struct cpu*
mycpu(void)
{
80104201:	55                   	push   %ebp
80104202:	89 e5                	mov    %esp,%ebp
80104204:	83 ec 18             	sub    $0x18,%esp
  int apicid, i;
  
  if(readeflags()&FL_IF)
80104207:	e8 9f ff ff ff       	call   801041ab <readeflags>
8010420c:	25 00 02 00 00       	and    $0x200,%eax
80104211:	85 c0                	test   %eax,%eax
80104213:	74 0d                	je     80104222 <mycpu+0x21>
    panic("mycpu called with interrupts enabled\n");
80104215:	83 ec 0c             	sub    $0xc,%esp
80104218:	68 90 86 10 80       	push   $0x80108690
8010421d:	e8 7a c3 ff ff       	call   8010059c <panic>
  
  apicid = lapicid();
80104222:	e8 b0 ed ff ff       	call   80102fd7 <lapicid>
80104227:	89 45 f0             	mov    %eax,-0x10(%ebp)
  // APIC IDs are not guaranteed to be contiguous. Maybe we should have
  // a reverse map, or reserve a register to store &cpus[i].
  for (i = 0; i < ncpu; ++i) {
8010422a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104231:	eb 2d                	jmp    80104260 <mycpu+0x5f>
    if (cpus[i].apicid == apicid)
80104233:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104236:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010423c:	05 00 38 11 80       	add    $0x80113800,%eax
80104241:	0f b6 00             	movzbl (%eax),%eax
80104244:	0f b6 c0             	movzbl %al,%eax
80104247:	39 45 f0             	cmp    %eax,-0x10(%ebp)
8010424a:	75 10                	jne    8010425c <mycpu+0x5b>
      return &cpus[i];
8010424c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010424f:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80104255:	05 00 38 11 80       	add    $0x80113800,%eax
8010425a:	eb 1b                	jmp    80104277 <mycpu+0x76>
  for (i = 0; i < ncpu; ++i) {
8010425c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104260:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80104265:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80104268:	7c c9                	jl     80104233 <mycpu+0x32>
  }
  panic("unknown apicid\n");
8010426a:	83 ec 0c             	sub    $0xc,%esp
8010426d:	68 b6 86 10 80       	push   $0x801086b6
80104272:	e8 25 c3 ff ff       	call   8010059c <panic>
}
80104277:	c9                   	leave  
80104278:	c3                   	ret    

80104279 <myproc>:

// Disable interrupts so that we are not rescheduled
// while reading proc from the cpu structure
struct proc*
myproc(void) {
80104279:	55                   	push   %ebp
8010427a:	89 e5                	mov    %esp,%ebp
8010427c:	83 ec 18             	sub    $0x18,%esp
  struct cpu *c;
  struct proc *p;
  pushcli();
8010427f:	e8 66 0e 00 00       	call   801050ea <pushcli>
  c = mycpu();
80104284:	e8 78 ff ff ff       	call   80104201 <mycpu>
80104289:	89 45 f4             	mov    %eax,-0xc(%ebp)
  p = c->proc;
8010428c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010428f:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104295:	89 45 f0             	mov    %eax,-0x10(%ebp)
  popcli();
80104298:	e8 9b 0e 00 00       	call   80105138 <popcli>
  return p;
8010429d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801042a0:	c9                   	leave  
801042a1:	c3                   	ret    

801042a2 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801042a2:	55                   	push   %ebp
801042a3:	89 e5                	mov    %esp,%ebp
801042a5:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801042a8:	83 ec 0c             	sub    $0xc,%esp
801042ab:	68 a0 3d 11 80       	push   $0x80113da0
801042b0:	e8 ba 0c 00 00       	call   80104f6f <acquire>
801042b5:	83 c4 10             	add    $0x10,%esp

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801042b8:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
801042bf:	eb 0e                	jmp    801042cf <allocproc+0x2d>
    if(p->state == UNUSED)
801042c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042c4:	8b 40 0c             	mov    0xc(%eax),%eax
801042c7:	85 c0                	test   %eax,%eax
801042c9:	74 27                	je     801042f2 <allocproc+0x50>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801042cb:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801042cf:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
801042d6:	72 e9                	jb     801042c1 <allocproc+0x1f>
      goto found;

  release(&ptable.lock);
801042d8:	83 ec 0c             	sub    $0xc,%esp
801042db:	68 a0 3d 11 80       	push   $0x80113da0
801042e0:	e8 f8 0c 00 00       	call   80104fdd <release>
801042e5:	83 c4 10             	add    $0x10,%esp
  return 0;
801042e8:	b8 00 00 00 00       	mov    $0x0,%eax
801042ed:	e9 b4 00 00 00       	jmp    801043a6 <allocproc+0x104>
      goto found;
801042f2:	90                   	nop

found://set up the new process’s kernel stack 内存模型详见book-rev11 Figure 1-4
  p->state = EMBRYO;
801042f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042f6:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801042fd:	a1 00 b0 10 80       	mov    0x8010b000,%eax
80104302:	8d 50 01             	lea    0x1(%eax),%edx
80104305:	89 15 00 b0 10 80    	mov    %edx,0x8010b000
8010430b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010430e:	89 42 10             	mov    %eax,0x10(%edx)

  release(&ptable.lock);
80104311:	83 ec 0c             	sub    $0xc,%esp
80104314:	68 a0 3d 11 80       	push   $0x80113da0
80104319:	e8 bf 0c 00 00       	call   80104fdd <release>
8010431e:	83 c4 10             	add    $0x10,%esp

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104321:	e8 5b e9 ff ff       	call   80102c81 <kalloc>
80104326:	89 c2                	mov    %eax,%edx
80104328:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010432b:	89 50 08             	mov    %edx,0x8(%eax)
8010432e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104331:	8b 40 08             	mov    0x8(%eax),%eax
80104334:	85 c0                	test   %eax,%eax
80104336:	75 11                	jne    80104349 <allocproc+0xa7>
    p->state = UNUSED;
80104338:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010433b:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104342:	b8 00 00 00 00       	mov    $0x0,%eax
80104347:	eb 5d                	jmp    801043a6 <allocproc+0x104>
  }
  /*
    SP/ESP/RSP: Stack pointer for top address of the stack.
  */
  sp = p->kstack + KSTACKSIZE;
80104349:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010434c:	8b 40 08             	mov    0x8(%eax),%eax
8010434f:	05 00 10 00 00       	add    $0x1000,%eax
80104354:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104357:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp; //trapframe which stores the user registers.
8010435b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104361:	89 50 18             	mov    %edx,0x18(%eax)
/*allocproc does part of this work
by setting up return program counter values that will cause the new process’s kernel
thread to first execute in forkret and then in trapret*/
  // Set up new context to start executing at forkret,
  // which returns to trapret. 
  sp -= 4;
80104364:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret; //define in trapasm.S   that is where forkret will return.
80104368:	ba bd 65 10 80       	mov    $0x801065bd,%edx
8010436d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104370:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104372:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104376:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104379:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010437c:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010437f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104382:	8b 40 1c             	mov    0x1c(%eax),%eax
80104385:	83 ec 04             	sub    $0x4,%esp
80104388:	6a 14                	push   $0x14
8010438a:	6a 00                	push   $0x0
8010438c:	50                   	push   %eax
8010438d:	e8 64 0e 00 00       	call   801051f6 <memset>
80104392:	83 c4 10             	add    $0x10,%esp
  The kernel thread
  will start executing with register contents copied from p->context. Thus setting p-
  >context->eip to forkret will cause the kernel thread to execute at the start of
  forkret
  */
  p->context->eip = (uint)forkret;
80104395:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104398:	8b 40 1c             	mov    0x1c(%eax),%eax
8010439b:	ba ea 4a 10 80       	mov    $0x80104aea,%edx
801043a0:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801043a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801043a6:	c9                   	leave  
801043a7:	c3                   	ret    

801043a8 <userinit>:
the process’s kernel thread. If the memory allocation fails, allocproc changes the
state back to UNUSED and returns zero to signal failure.
*/
void
userinit(void)
{
801043a8:	55                   	push   %ebp
801043a9:	89 e5                	mov    %esp,%ebp
801043ab:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];

  p = allocproc();
801043ae:	e8 ef fe ff ff       	call   801042a2 <allocproc>
801043b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  initproc = p;
801043b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043b9:	a3 20 b6 10 80       	mov    %eax,0x8010b620
  if((p->pgdir = setupkvm()) == 0)
801043be:	e8 41 37 00 00       	call   80107b04 <setupkvm>
801043c3:	89 c2                	mov    %eax,%edx
801043c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c8:	89 50 04             	mov    %edx,0x4(%eax)
801043cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043ce:	8b 40 04             	mov    0x4(%eax),%eax
801043d1:	85 c0                	test   %eax,%eax
801043d3:	75 0d                	jne    801043e2 <userinit+0x3a>
    panic("userinit: out of memory?");
801043d5:	83 ec 0c             	sub    $0xc,%esp
801043d8:	68 c6 86 10 80       	push   $0x801086c6
801043dd:	e8 ba c1 ff ff       	call   8010059c <panic>
  /*the linker embeds that binary in the kernel and defines two special symbols, 
  _binary_initcode_start and _binary_initcode_size, indicating the location and size of the binary. 
  Userinit copies that binary into the new process’s memory by calling inituvm,*/
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801043e2:	ba 2c 00 00 00       	mov    $0x2c,%edx
801043e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043ea:	8b 40 04             	mov    0x4(%eax),%eax
801043ed:	83 ec 04             	sub    $0x4,%esp
801043f0:	52                   	push   %edx
801043f1:	68 c0 b4 10 80       	push   $0x8010b4c0
801043f6:	50                   	push   %eax
801043f7:	e8 73 39 00 00       	call   80107d6f <inituvm>
801043fc:	83 c4 10             	add    $0x10,%esp
  p->sz = PGSIZE;
801043ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104402:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104408:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010440b:	8b 40 18             	mov    0x18(%eax),%eax
8010440e:	83 ec 04             	sub    $0x4,%esp
80104411:	6a 4c                	push   $0x4c
80104413:	6a 00                	push   $0x0
80104415:	50                   	push   %eax
80104416:	e8 db 0d 00 00       	call   801051f6 <memset>
8010441b:	83 c4 10             	add    $0x10,%esp
  userinit writes values at the top of the new stack that look just like those that would be there if the 
  process had entered the kernel via an interrupt userinit (2533) set up the low bits of %cs to run the process’s user code at CPL=3
means that the user code can only use pages with PTE_U set, and cannot modify sensitive hardware registers 
such as %cr3. So the process is constrained to using only its own memory
*/
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER; //user mode rather than kernel mode
8010441e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104421:	8b 40 18             	mov    0x18(%eax),%eax
80104424:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010442a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010442d:	8b 40 18             	mov    0x18(%eax),%eax
80104430:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104436:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104439:	8b 50 18             	mov    0x18(%eax),%edx
8010443c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010443f:	8b 40 18             	mov    0x18(%eax),%eax
80104442:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104446:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010444a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010444d:	8b 50 18             	mov    0x18(%eax),%edx
80104450:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104453:	8b 40 18             	mov    0x18(%eax),%eax
80104456:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010445a:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF; //The %eflags FL_IF bit is set to allow hardware interrupts
8010445e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104461:	8b 40 18             	mov    0x18(%eax),%eax
80104464:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010446b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010446e:	8b 40 18             	mov    0x18(%eax),%eax
80104471:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104478:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010447b:	8b 40 18             	mov    0x18(%eax),%eax
8010447e:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
if the process had entered the kernel via an interrupt (2533-2539), so that the ordinary code for returning from 
the kernel back to the process’s user code will work.
*/
//The function userinit sets p->name to initcode mainly for debugging. Setting
//p->cwd sets the process’s current working directory
  safestrcpy(p->name, "initcode", sizeof(p->name));
80104485:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104488:	83 c0 6c             	add    $0x6c,%eax
8010448b:	83 ec 04             	sub    $0x4,%esp
8010448e:	6a 10                	push   $0x10
80104490:	68 df 86 10 80       	push   $0x801086df
80104495:	50                   	push   %eax
80104496:	e8 5e 0f 00 00       	call   801053f9 <safestrcpy>
8010449b:	83 c4 10             	add    $0x10,%esp
  p->cwd = namei("/");
8010449e:	83 ec 0c             	sub    $0xc,%esp
801044a1:	68 e8 86 10 80       	push   $0x801086e8
801044a6:	e8 91 e0 ff ff       	call   8010253c <namei>
801044ab:	83 c4 10             	add    $0x10,%esp
801044ae:	89 c2                	mov    %eax,%edx
801044b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b3:	89 50 68             	mov    %edx,0x68(%eax)

  // this assignment to p->state lets other cores
  // run this process. the acquire forces the above
  // writes to be visible, and the lock is also needed
  // because the assignment might not be atomic.
  acquire(&ptable.lock);
801044b6:	83 ec 0c             	sub    $0xc,%esp
801044b9:	68 a0 3d 11 80       	push   $0x80113da0
801044be:	e8 ac 0a 00 00       	call   80104f6f <acquire>
801044c3:	83 c4 10             	add    $0x10,%esp

  p->state = RUNNABLE;
801044c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044c9:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
801044d0:	83 ec 0c             	sub    $0xc,%esp
801044d3:	68 a0 3d 11 80       	push   $0x80113da0
801044d8:	e8 00 0b 00 00       	call   80104fdd <release>
801044dd:	83 c4 10             	add    $0x10,%esp
}
801044e0:	90                   	nop
801044e1:	c9                   	leave  
801044e2:	c3                   	ret    

801044e3 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801044e3:	55                   	push   %ebp
801044e4:	89 e5                	mov    %esp,%ebp
801044e6:	83 ec 18             	sub    $0x18,%esp
  uint sz;
  struct proc *curproc = myproc();
801044e9:	e8 8b fd ff ff       	call   80104279 <myproc>
801044ee:	89 45 f0             	mov    %eax,-0x10(%ebp)

  sz = curproc->sz;
801044f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044f4:	8b 00                	mov    (%eax),%eax
801044f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801044f9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801044fd:	7e 2e                	jle    8010452d <growproc+0x4a>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
801044ff:	8b 55 08             	mov    0x8(%ebp),%edx
80104502:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104505:	01 c2                	add    %eax,%edx
80104507:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010450a:	8b 40 04             	mov    0x4(%eax),%eax
8010450d:	83 ec 04             	sub    $0x4,%esp
80104510:	52                   	push   %edx
80104511:	ff 75 f4             	pushl  -0xc(%ebp)
80104514:	50                   	push   %eax
80104515:	e8 92 39 00 00       	call   80107eac <allocuvm>
8010451a:	83 c4 10             	add    $0x10,%esp
8010451d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104520:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104524:	75 3b                	jne    80104561 <growproc+0x7e>
      return -1;
80104526:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010452b:	eb 4f                	jmp    8010457c <growproc+0x99>
  } else if(n < 0){
8010452d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104531:	79 2e                	jns    80104561 <growproc+0x7e>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80104533:	8b 55 08             	mov    0x8(%ebp),%edx
80104536:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104539:	01 c2                	add    %eax,%edx
8010453b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010453e:	8b 40 04             	mov    0x4(%eax),%eax
80104541:	83 ec 04             	sub    $0x4,%esp
80104544:	52                   	push   %edx
80104545:	ff 75 f4             	pushl  -0xc(%ebp)
80104548:	50                   	push   %eax
80104549:	e8 63 3a 00 00       	call   80107fb1 <deallocuvm>
8010454e:	83 c4 10             	add    $0x10,%esp
80104551:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104554:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104558:	75 07                	jne    80104561 <growproc+0x7e>
      return -1;
8010455a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010455f:	eb 1b                	jmp    8010457c <growproc+0x99>
  }
  curproc->sz = sz;
80104561:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104564:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104567:	89 10                	mov    %edx,(%eax)
  switchuvm(curproc);
80104569:	83 ec 0c             	sub    $0xc,%esp
8010456c:	ff 75 f0             	pushl  -0x10(%ebp)
8010456f:	e8 5a 36 00 00       	call   80107bce <switchuvm>
80104574:	83 c4 10             	add    $0x10,%esp
  return 0;
80104577:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010457c:	c9                   	leave  
8010457d:	c3                   	ret    

8010457e <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010457e:	55                   	push   %ebp
8010457f:	89 e5                	mov    %esp,%ebp
80104581:	57                   	push   %edi
80104582:	56                   	push   %esi
80104583:	53                   	push   %ebx
80104584:	83 ec 1c             	sub    $0x1c,%esp
  int i, pid;
  struct proc *np;
  struct proc *curproc = myproc();
80104587:	e8 ed fc ff ff       	call   80104279 <myproc>
8010458c:	89 45 e0             	mov    %eax,-0x20(%ebp)

  // Allocate process.
  if((np = allocproc()) == 0){
8010458f:	e8 0e fd ff ff       	call   801042a2 <allocproc>
80104594:	89 45 dc             	mov    %eax,-0x24(%ebp)
80104597:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
8010459b:	75 0a                	jne    801045a7 <fork+0x29>
    return -1;
8010459d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045a2:	e9 4e 01 00 00       	jmp    801046f5 <fork+0x177>
  }

  // Copy process state from proc.
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801045a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045aa:	8b 10                	mov    (%eax),%edx
801045ac:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045af:	8b 40 04             	mov    0x4(%eax),%eax
801045b2:	83 ec 08             	sub    $0x8,%esp
801045b5:	52                   	push   %edx
801045b6:	50                   	push   %eax
801045b7:	e8 93 3b 00 00       	call   8010814f <copyuvm>
801045bc:	83 c4 10             	add    $0x10,%esp
801045bf:	89 c2                	mov    %eax,%edx
801045c1:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045c4:	89 50 04             	mov    %edx,0x4(%eax)
801045c7:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045ca:	8b 40 04             	mov    0x4(%eax),%eax
801045cd:	85 c0                	test   %eax,%eax
801045cf:	75 30                	jne    80104601 <fork+0x83>
    kfree(np->kstack);
801045d1:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045d4:	8b 40 08             	mov    0x8(%eax),%eax
801045d7:	83 ec 0c             	sub    $0xc,%esp
801045da:	50                   	push   %eax
801045db:	e8 07 e6 ff ff       	call   80102be7 <kfree>
801045e0:	83 c4 10             	add    $0x10,%esp
    np->kstack = 0;
801045e3:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045e6:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801045ed:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045f0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801045f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045fc:	e9 f4 00 00 00       	jmp    801046f5 <fork+0x177>
  }
  np->sz = curproc->sz;
80104601:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104604:	8b 10                	mov    (%eax),%edx
80104606:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104609:	89 10                	mov    %edx,(%eax)
  np->parent = curproc;
8010460b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010460e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104611:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *curproc->tf;
80104614:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104617:	8b 48 18             	mov    0x18(%eax),%ecx
8010461a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010461d:	8b 40 18             	mov    0x18(%eax),%eax
80104620:	89 c2                	mov    %eax,%edx
80104622:	89 cb                	mov    %ecx,%ebx
80104624:	b8 13 00 00 00       	mov    $0x13,%eax
80104629:	89 d7                	mov    %edx,%edi
8010462b:	89 de                	mov    %ebx,%esi
8010462d:	89 c1                	mov    %eax,%ecx
8010462f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104631:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104634:	8b 40 18             	mov    0x18(%eax),%eax
80104637:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
8010463e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104645:	eb 3d                	jmp    80104684 <fork+0x106>
    if(curproc->ofile[i])
80104647:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010464a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010464d:	83 c2 08             	add    $0x8,%edx
80104650:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104654:	85 c0                	test   %eax,%eax
80104656:	74 28                	je     80104680 <fork+0x102>
      np->ofile[i] = filedup(curproc->ofile[i]);
80104658:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010465b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010465e:	83 c2 08             	add    $0x8,%edx
80104661:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104665:	83 ec 0c             	sub    $0xc,%esp
80104668:	50                   	push   %eax
80104669:	e8 f6 c9 ff ff       	call   80101064 <filedup>
8010466e:	83 c4 10             	add    $0x10,%esp
80104671:	89 c1                	mov    %eax,%ecx
80104673:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104676:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104679:	83 c2 08             	add    $0x8,%edx
8010467c:	89 4c 90 08          	mov    %ecx,0x8(%eax,%edx,4)
  for(i = 0; i < NOFILE; i++)
80104680:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104684:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104688:	7e bd                	jle    80104647 <fork+0xc9>
  np->cwd = idup(curproc->cwd);
8010468a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010468d:	8b 40 68             	mov    0x68(%eax),%eax
80104690:	83 ec 0c             	sub    $0xc,%esp
80104693:	50                   	push   %eax
80104694:	e8 2e d3 ff ff       	call   801019c7 <idup>
80104699:	83 c4 10             	add    $0x10,%esp
8010469c:	89 c2                	mov    %eax,%edx
8010469e:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046a1:	89 50 68             	mov    %edx,0x68(%eax)

  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
801046a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046a7:	8d 50 6c             	lea    0x6c(%eax),%edx
801046aa:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046ad:	83 c0 6c             	add    $0x6c,%eax
801046b0:	83 ec 04             	sub    $0x4,%esp
801046b3:	6a 10                	push   $0x10
801046b5:	52                   	push   %edx
801046b6:	50                   	push   %eax
801046b7:	e8 3d 0d 00 00       	call   801053f9 <safestrcpy>
801046bc:	83 c4 10             	add    $0x10,%esp

  pid = np->pid;
801046bf:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046c2:	8b 40 10             	mov    0x10(%eax),%eax
801046c5:	89 45 d8             	mov    %eax,-0x28(%ebp)

  acquire(&ptable.lock);
801046c8:	83 ec 0c             	sub    $0xc,%esp
801046cb:	68 a0 3d 11 80       	push   $0x80113da0
801046d0:	e8 9a 08 00 00       	call   80104f6f <acquire>
801046d5:	83 c4 10             	add    $0x10,%esp

  np->state = RUNNABLE;
801046d8:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046db:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
801046e2:	83 ec 0c             	sub    $0xc,%esp
801046e5:	68 a0 3d 11 80       	push   $0x80113da0
801046ea:	e8 ee 08 00 00       	call   80104fdd <release>
801046ef:	83 c4 10             	add    $0x10,%esp

  return pid;
801046f2:	8b 45 d8             	mov    -0x28(%ebp),%eax
}
801046f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
801046f8:	5b                   	pop    %ebx
801046f9:	5e                   	pop    %esi
801046fa:	5f                   	pop    %edi
801046fb:	5d                   	pop    %ebp
801046fc:	c3                   	ret    

801046fd <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801046fd:	55                   	push   %ebp
801046fe:	89 e5                	mov    %esp,%ebp
80104700:	83 ec 18             	sub    $0x18,%esp
  struct proc *curproc = myproc();
80104703:	e8 71 fb ff ff       	call   80104279 <myproc>
80104708:	89 45 ec             	mov    %eax,-0x14(%ebp)
  struct proc *p;
  int fd;

  if(curproc == initproc)
8010470b:	a1 20 b6 10 80       	mov    0x8010b620,%eax
80104710:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80104713:	75 0d                	jne    80104722 <exit+0x25>
    panic("init exiting");
80104715:	83 ec 0c             	sub    $0xc,%esp
80104718:	68 ea 86 10 80       	push   $0x801086ea
8010471d:	e8 7a be ff ff       	call   8010059c <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104722:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104729:	eb 3f                	jmp    8010476a <exit+0x6d>
    if(curproc->ofile[fd]){
8010472b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010472e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104731:	83 c2 08             	add    $0x8,%edx
80104734:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104738:	85 c0                	test   %eax,%eax
8010473a:	74 2a                	je     80104766 <exit+0x69>
      fileclose(curproc->ofile[fd]);
8010473c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010473f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104742:	83 c2 08             	add    $0x8,%edx
80104745:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104749:	83 ec 0c             	sub    $0xc,%esp
8010474c:	50                   	push   %eax
8010474d:	e8 63 c9 ff ff       	call   801010b5 <fileclose>
80104752:	83 c4 10             	add    $0x10,%esp
      curproc->ofile[fd] = 0;
80104755:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104758:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010475b:	83 c2 08             	add    $0x8,%edx
8010475e:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104765:	00 
  for(fd = 0; fd < NOFILE; fd++){
80104766:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010476a:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010476e:	7e bb                	jle    8010472b <exit+0x2e>
    }
  }

  begin_op();
80104770:	e8 ae ed ff ff       	call   80103523 <begin_op>
  iput(curproc->cwd);
80104775:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104778:	8b 40 68             	mov    0x68(%eax),%eax
8010477b:	83 ec 0c             	sub    $0xc,%esp
8010477e:	50                   	push   %eax
8010477f:	e8 de d3 ff ff       	call   80101b62 <iput>
80104784:	83 c4 10             	add    $0x10,%esp
  end_op();
80104787:	e8 23 ee ff ff       	call   801035af <end_op>
  curproc->cwd = 0;
8010478c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010478f:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104796:	83 ec 0c             	sub    $0xc,%esp
80104799:	68 a0 3d 11 80       	push   $0x80113da0
8010479e:	e8 cc 07 00 00       	call   80104f6f <acquire>
801047a3:	83 c4 10             	add    $0x10,%esp

  // Parent might be sleeping in wait().
  wakeup1(curproc->parent);
801047a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801047a9:	8b 40 14             	mov    0x14(%eax),%eax
801047ac:	83 ec 0c             	sub    $0xc,%esp
801047af:	50                   	push   %eax
801047b0:	e8 22 04 00 00       	call   80104bd7 <wakeup1>
801047b5:	83 c4 10             	add    $0x10,%esp

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047b8:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
801047bf:	eb 37                	jmp    801047f8 <exit+0xfb>
    if(p->parent == curproc){
801047c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c4:	8b 40 14             	mov    0x14(%eax),%eax
801047c7:	39 45 ec             	cmp    %eax,-0x14(%ebp)
801047ca:	75 28                	jne    801047f4 <exit+0xf7>
      p->parent = initproc;
801047cc:	8b 15 20 b6 10 80    	mov    0x8010b620,%edx
801047d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047d5:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801047d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047db:	8b 40 0c             	mov    0xc(%eax),%eax
801047de:	83 f8 05             	cmp    $0x5,%eax
801047e1:	75 11                	jne    801047f4 <exit+0xf7>
        wakeup1(initproc);
801047e3:	a1 20 b6 10 80       	mov    0x8010b620,%eax
801047e8:	83 ec 0c             	sub    $0xc,%esp
801047eb:	50                   	push   %eax
801047ec:	e8 e6 03 00 00       	call   80104bd7 <wakeup1>
801047f1:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047f4:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801047f8:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
801047ff:	72 c0                	jb     801047c1 <exit+0xc4>
    }
  }

  // Jump into the scheduler, never to return.
  curproc->state = ZOMBIE;
80104801:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104804:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
8010480b:	e8 e5 01 00 00       	call   801049f5 <sched>
  panic("zombie exit");
80104810:	83 ec 0c             	sub    $0xc,%esp
80104813:	68 f7 86 10 80       	push   $0x801086f7
80104818:	e8 7f bd ff ff       	call   8010059c <panic>

8010481d <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
8010481d:	55                   	push   %ebp
8010481e:	89 e5                	mov    %esp,%ebp
80104820:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  int havekids, pid;
  struct proc *curproc = myproc();
80104823:	e8 51 fa ff ff       	call   80104279 <myproc>
80104828:	89 45 ec             	mov    %eax,-0x14(%ebp)
  
  acquire(&ptable.lock);
8010482b:	83 ec 0c             	sub    $0xc,%esp
8010482e:	68 a0 3d 11 80       	push   $0x80113da0
80104833:	e8 37 07 00 00       	call   80104f6f <acquire>
80104838:	83 c4 10             	add    $0x10,%esp
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
8010483b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104842:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104849:	e9 a1 00 00 00       	jmp    801048ef <wait+0xd2>
      if(p->parent != curproc)
8010484e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104851:	8b 40 14             	mov    0x14(%eax),%eax
80104854:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80104857:	0f 85 8d 00 00 00    	jne    801048ea <wait+0xcd>
        continue;
      havekids = 1;
8010485d:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104867:	8b 40 0c             	mov    0xc(%eax),%eax
8010486a:	83 f8 05             	cmp    $0x5,%eax
8010486d:	75 7c                	jne    801048eb <wait+0xce>
        // Found one.
        pid = p->pid;
8010486f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104872:	8b 40 10             	mov    0x10(%eax),%eax
80104875:	89 45 e8             	mov    %eax,-0x18(%ebp)
        kfree(p->kstack);
80104878:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010487b:	8b 40 08             	mov    0x8(%eax),%eax
8010487e:	83 ec 0c             	sub    $0xc,%esp
80104881:	50                   	push   %eax
80104882:	e8 60 e3 ff ff       	call   80102be7 <kfree>
80104887:	83 c4 10             	add    $0x10,%esp
        p->kstack = 0;
8010488a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010488d:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104894:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104897:	8b 40 04             	mov    0x4(%eax),%eax
8010489a:	83 ec 0c             	sub    $0xc,%esp
8010489d:	50                   	push   %eax
8010489e:	e8 d2 37 00 00       	call   80108075 <freevm>
801048a3:	83 c4 10             	add    $0x10,%esp
        p->pid = 0;
801048a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048a9:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801048b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048b3:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801048ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048bd:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801048c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048c4:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        p->state = UNUSED;
801048cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048ce:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        release(&ptable.lock);
801048d5:	83 ec 0c             	sub    $0xc,%esp
801048d8:	68 a0 3d 11 80       	push   $0x80113da0
801048dd:	e8 fb 06 00 00       	call   80104fdd <release>
801048e2:	83 c4 10             	add    $0x10,%esp
        return pid;
801048e5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801048e8:	eb 51                	jmp    8010493b <wait+0x11e>
        continue;
801048ea:	90                   	nop
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801048eb:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801048ef:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
801048f6:	0f 82 52 ff ff ff    	jb     8010484e <wait+0x31>
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || curproc->killed){
801048fc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104900:	74 0a                	je     8010490c <wait+0xef>
80104902:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104905:	8b 40 24             	mov    0x24(%eax),%eax
80104908:	85 c0                	test   %eax,%eax
8010490a:	74 17                	je     80104923 <wait+0x106>
      release(&ptable.lock);
8010490c:	83 ec 0c             	sub    $0xc,%esp
8010490f:	68 a0 3d 11 80       	push   $0x80113da0
80104914:	e8 c4 06 00 00       	call   80104fdd <release>
80104919:	83 c4 10             	add    $0x10,%esp
      return -1;
8010491c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104921:	eb 18                	jmp    8010493b <wait+0x11e>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80104923:	83 ec 08             	sub    $0x8,%esp
80104926:	68 a0 3d 11 80       	push   $0x80113da0
8010492b:	ff 75 ec             	pushl  -0x14(%ebp)
8010492e:	e8 fd 01 00 00       	call   80104b30 <sleep>
80104933:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80104936:	e9 00 ff ff ff       	jmp    8010483b <wait+0x1e>
  }
}
8010493b:	c9                   	leave  
8010493c:	c3                   	ret    

8010493d <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
8010493d:	55                   	push   %ebp
8010493e:	89 e5                	mov    %esp,%ebp
80104940:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  struct cpu *c = mycpu();
80104943:	e8 b9 f8 ff ff       	call   80104201 <mycpu>
80104948:	89 45 f0             	mov    %eax,-0x10(%ebp)
  c->proc = 0;
8010494b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010494e:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80104955:	00 00 00 
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
80104958:	e8 5e f8 ff ff       	call   801041bb <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010495d:	83 ec 0c             	sub    $0xc,%esp
80104960:	68 a0 3d 11 80       	push   $0x80113da0
80104965:	e8 05 06 00 00       	call   80104f6f <acquire>
8010496a:	83 c4 10             	add    $0x10,%esp
    //looks for a process with p->state set to RUNNABLE
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010496d:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104974:	eb 61                	jmp    801049d7 <scheduler+0x9a>
      if(p->state != RUNNABLE)
80104976:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104979:	8b 40 0c             	mov    0xc(%eax),%eax
8010497c:	83 f8 03             	cmp    $0x3,%eax
8010497f:	75 51                	jne    801049d2 <scheduler+0x95>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      c->proc = p;
80104981:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104984:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104987:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
      switchuvm(p);
8010498d:	83 ec 0c             	sub    $0xc,%esp
80104990:	ff 75 f4             	pushl  -0xc(%ebp)
80104993:	e8 36 32 00 00       	call   80107bce <switchuvm>
80104998:	83 c4 10             	add    $0x10,%esp
      p->state = RUNNING;
8010499b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010499e:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
so scheduler tells swtch to save the current hardware registers in per-cpu storage
(cpu->scheduler) rather than in any process’s kernel thread context. swtch then
loads the saved registers of the target kernel thread (p->context) into the x86 hardware
registers, including the stack pointer and instruction pointer
      */
      swtch(&(c->scheduler), p->context);
801049a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049a8:	8b 40 1c             	mov    0x1c(%eax),%eax
801049ab:	8b 55 f0             	mov    -0x10(%ebp),%edx
801049ae:	83 c2 04             	add    $0x4,%edx
801049b1:	83 ec 08             	sub    $0x8,%esp
801049b4:	50                   	push   %eax
801049b5:	52                   	push   %edx
801049b6:	e8 af 0a 00 00       	call   8010546a <swtch>
801049bb:	83 c4 10             	add    $0x10,%esp
      switchkvm();
801049be:	e8 f2 31 00 00       	call   80107bb5 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
801049c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049c6:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801049cd:	00 00 00 
801049d0:	eb 01                	jmp    801049d3 <scheduler+0x96>
        continue;
801049d2:	90                   	nop
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049d3:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801049d7:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
801049de:	72 96                	jb     80104976 <scheduler+0x39>
    }
    release(&ptable.lock);
801049e0:	83 ec 0c             	sub    $0xc,%esp
801049e3:	68 a0 3d 11 80       	push   $0x80113da0
801049e8:	e8 f0 05 00 00       	call   80104fdd <release>
801049ed:	83 c4 10             	add    $0x10,%esp
    sti();
801049f0:	e9 63 ff ff ff       	jmp    80104958 <scheduler+0x1b>

801049f5 <sched>:
// be proc->intena and proc->ncli, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
801049f5:	55                   	push   %ebp
801049f6:	89 e5                	mov    %esp,%ebp
801049f8:	83 ec 18             	sub    $0x18,%esp
  int intena;
  struct proc *p = myproc();
801049fb:	e8 79 f8 ff ff       	call   80104279 <myproc>
80104a00:	89 45 f4             	mov    %eax,-0xc(%ebp)

  if(!holding(&ptable.lock))
80104a03:	83 ec 0c             	sub    $0xc,%esp
80104a06:	68 a0 3d 11 80       	push   $0x80113da0
80104a0b:	e8 99 06 00 00       	call   801050a9 <holding>
80104a10:	83 c4 10             	add    $0x10,%esp
80104a13:	85 c0                	test   %eax,%eax
80104a15:	75 0d                	jne    80104a24 <sched+0x2f>
    panic("sched ptable.lock");
80104a17:	83 ec 0c             	sub    $0xc,%esp
80104a1a:	68 03 87 10 80       	push   $0x80108703
80104a1f:	e8 78 bb ff ff       	call   8010059c <panic>
  if(mycpu()->ncli != 1)
80104a24:	e8 d8 f7 ff ff       	call   80104201 <mycpu>
80104a29:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
80104a2f:	83 f8 01             	cmp    $0x1,%eax
80104a32:	74 0d                	je     80104a41 <sched+0x4c>
    panic("sched locks");
80104a34:	83 ec 0c             	sub    $0xc,%esp
80104a37:	68 15 87 10 80       	push   $0x80108715
80104a3c:	e8 5b bb ff ff       	call   8010059c <panic>
  if(p->state == RUNNING)
80104a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a44:	8b 40 0c             	mov    0xc(%eax),%eax
80104a47:	83 f8 04             	cmp    $0x4,%eax
80104a4a:	75 0d                	jne    80104a59 <sched+0x64>
    panic("sched running");
80104a4c:	83 ec 0c             	sub    $0xc,%esp
80104a4f:	68 21 87 10 80       	push   $0x80108721
80104a54:	e8 43 bb ff ff       	call   8010059c <panic>
  if(readeflags()&FL_IF)
80104a59:	e8 4d f7 ff ff       	call   801041ab <readeflags>
80104a5e:	25 00 02 00 00       	and    $0x200,%eax
80104a63:	85 c0                	test   %eax,%eax
80104a65:	74 0d                	je     80104a74 <sched+0x7f>
    panic("sched interruptible");
80104a67:	83 ec 0c             	sub    $0xc,%esp
80104a6a:	68 2f 87 10 80       	push   $0x8010872f
80104a6f:	e8 28 bb ff ff       	call   8010059c <panic>
  intena = mycpu()->intena;
80104a74:	e8 88 f7 ff ff       	call   80104201 <mycpu>
80104a79:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104a7f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  swtch(&p->context, mycpu()->scheduler);
80104a82:	e8 7a f7 ff ff       	call   80104201 <mycpu>
80104a87:	8b 40 04             	mov    0x4(%eax),%eax
80104a8a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a8d:	83 c2 1c             	add    $0x1c,%edx
80104a90:	83 ec 08             	sub    $0x8,%esp
80104a93:	50                   	push   %eax
80104a94:	52                   	push   %edx
80104a95:	e8 d0 09 00 00       	call   8010546a <swtch>
80104a9a:	83 c4 10             	add    $0x10,%esp
  mycpu()->intena = intena;
80104a9d:	e8 5f f7 ff ff       	call   80104201 <mycpu>
80104aa2:	89 c2                	mov    %eax,%edx
80104aa4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aa7:	89 82 a8 00 00 00    	mov    %eax,0xa8(%edx)
}
80104aad:	90                   	nop
80104aae:	c9                   	leave  
80104aaf:	c3                   	ret    

80104ab0 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104ab0:	55                   	push   %ebp
80104ab1:	89 e5                	mov    %esp,%ebp
80104ab3:	83 ec 08             	sub    $0x8,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104ab6:	83 ec 0c             	sub    $0xc,%esp
80104ab9:	68 a0 3d 11 80       	push   $0x80113da0
80104abe:	e8 ac 04 00 00       	call   80104f6f <acquire>
80104ac3:	83 c4 10             	add    $0x10,%esp
  myproc()->state = RUNNABLE;
80104ac6:	e8 ae f7 ff ff       	call   80104279 <myproc>
80104acb:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104ad2:	e8 1e ff ff ff       	call   801049f5 <sched>
  release(&ptable.lock);
80104ad7:	83 ec 0c             	sub    $0xc,%esp
80104ada:	68 a0 3d 11 80       	push   $0x80113da0
80104adf:	e8 f9 04 00 00       	call   80104fdd <release>
80104ae4:	83 c4 10             	add    $0x10,%esp
}
80104ae7:	90                   	nop
80104ae8:	c9                   	leave  
80104ae9:	c3                   	ret    

80104aea <forkret>:
Allocproc arranged that the top word on the stack after p->context is popped off
would be trapret, so now trapret begins executing, with %esp set to p->tf.
*/
void
forkret(void)
{
80104aea:	55                   	push   %ebp
80104aeb:	89 e5                	mov    %esp,%ebp
80104aed:	83 ec 08             	sub    $0x8,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104af0:	83 ec 0c             	sub    $0xc,%esp
80104af3:	68 a0 3d 11 80       	push   $0x80113da0
80104af8:	e8 e0 04 00 00       	call   80104fdd <release>
80104afd:	83 c4 10             	add    $0x10,%esp

  if (first) {
80104b00:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104b05:	85 c0                	test   %eax,%eax
80104b07:	74 24                	je     80104b2d <forkret+0x43>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot
    // be run from main().
    first = 0;
80104b09:	c7 05 04 b0 10 80 00 	movl   $0x0,0x8010b004
80104b10:	00 00 00 
    iinit(ROOTDEV);
80104b13:	83 ec 0c             	sub    $0xc,%esp
80104b16:	6a 01                	push   $0x1
80104b18:	e8 72 cb ff ff       	call   8010168f <iinit>
80104b1d:	83 c4 10             	add    $0x10,%esp
    initlog(ROOTDEV);
80104b20:	83 ec 0c             	sub    $0xc,%esp
80104b23:	6a 01                	push   $0x1
80104b25:	e8 db e7 ff ff       	call   80103305 <initlog>
80104b2a:	83 c4 10             	add    $0x10,%esp
  }

  // Return to "caller", actually trapret (see allocproc).
}
80104b2d:	90                   	nop
80104b2e:	c9                   	leave  
80104b2f:	c3                   	ret    

80104b30 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104b30:	55                   	push   %ebp
80104b31:	89 e5                	mov    %esp,%ebp
80104b33:	83 ec 18             	sub    $0x18,%esp
  struct proc *p = myproc();
80104b36:	e8 3e f7 ff ff       	call   80104279 <myproc>
80104b3b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  if(p == 0)
80104b3e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104b42:	75 0d                	jne    80104b51 <sleep+0x21>
    panic("sleep");
80104b44:	83 ec 0c             	sub    $0xc,%esp
80104b47:	68 43 87 10 80       	push   $0x80108743
80104b4c:	e8 4b ba ff ff       	call   8010059c <panic>

  if(lk == 0)
80104b51:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104b55:	75 0d                	jne    80104b64 <sleep+0x34>
    panic("sleep without lk");
80104b57:	83 ec 0c             	sub    $0xc,%esp
80104b5a:	68 49 87 10 80       	push   $0x80108749
80104b5f:	e8 38 ba ff ff       	call   8010059c <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104b64:	81 7d 0c a0 3d 11 80 	cmpl   $0x80113da0,0xc(%ebp)
80104b6b:	74 1e                	je     80104b8b <sleep+0x5b>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104b6d:	83 ec 0c             	sub    $0xc,%esp
80104b70:	68 a0 3d 11 80       	push   $0x80113da0
80104b75:	e8 f5 03 00 00       	call   80104f6f <acquire>
80104b7a:	83 c4 10             	add    $0x10,%esp
    release(lk);
80104b7d:	83 ec 0c             	sub    $0xc,%esp
80104b80:	ff 75 0c             	pushl  0xc(%ebp)
80104b83:	e8 55 04 00 00       	call   80104fdd <release>
80104b88:	83 c4 10             	add    $0x10,%esp
  }
  // Go to sleep.
  p->chan = chan;
80104b8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b8e:	8b 55 08             	mov    0x8(%ebp),%edx
80104b91:	89 50 20             	mov    %edx,0x20(%eax)
  p->state = SLEEPING;
80104b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b97:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  sched();
80104b9e:	e8 52 fe ff ff       	call   801049f5 <sched>

  // Tidy up.
  p->chan = 0;
80104ba3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba6:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104bad:	81 7d 0c a0 3d 11 80 	cmpl   $0x80113da0,0xc(%ebp)
80104bb4:	74 1e                	je     80104bd4 <sleep+0xa4>
    release(&ptable.lock);
80104bb6:	83 ec 0c             	sub    $0xc,%esp
80104bb9:	68 a0 3d 11 80       	push   $0x80113da0
80104bbe:	e8 1a 04 00 00       	call   80104fdd <release>
80104bc3:	83 c4 10             	add    $0x10,%esp
    acquire(lk);
80104bc6:	83 ec 0c             	sub    $0xc,%esp
80104bc9:	ff 75 0c             	pushl  0xc(%ebp)
80104bcc:	e8 9e 03 00 00       	call   80104f6f <acquire>
80104bd1:	83 c4 10             	add    $0x10,%esp
  }
}
80104bd4:	90                   	nop
80104bd5:	c9                   	leave  
80104bd6:	c3                   	ret    

80104bd7 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104bd7:	55                   	push   %ebp
80104bd8:	89 e5                	mov    %esp,%ebp
80104bda:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104bdd:	c7 45 fc d4 3d 11 80 	movl   $0x80113dd4,-0x4(%ebp)
80104be4:	eb 24                	jmp    80104c0a <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104be6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104be9:	8b 40 0c             	mov    0xc(%eax),%eax
80104bec:	83 f8 02             	cmp    $0x2,%eax
80104bef:	75 15                	jne    80104c06 <wakeup1+0x2f>
80104bf1:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104bf4:	8b 40 20             	mov    0x20(%eax),%eax
80104bf7:	39 45 08             	cmp    %eax,0x8(%ebp)
80104bfa:	75 0a                	jne    80104c06 <wakeup1+0x2f>
      p->state = RUNNABLE;
80104bfc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104bff:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c06:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104c0a:	81 7d fc d4 5c 11 80 	cmpl   $0x80115cd4,-0x4(%ebp)
80104c11:	72 d3                	jb     80104be6 <wakeup1+0xf>
}
80104c13:	90                   	nop
80104c14:	c9                   	leave  
80104c15:	c3                   	ret    

80104c16 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104c16:	55                   	push   %ebp
80104c17:	89 e5                	mov    %esp,%ebp
80104c19:	83 ec 08             	sub    $0x8,%esp
  acquire(&ptable.lock);
80104c1c:	83 ec 0c             	sub    $0xc,%esp
80104c1f:	68 a0 3d 11 80       	push   $0x80113da0
80104c24:	e8 46 03 00 00       	call   80104f6f <acquire>
80104c29:	83 c4 10             	add    $0x10,%esp
  wakeup1(chan);
80104c2c:	83 ec 0c             	sub    $0xc,%esp
80104c2f:	ff 75 08             	pushl  0x8(%ebp)
80104c32:	e8 a0 ff ff ff       	call   80104bd7 <wakeup1>
80104c37:	83 c4 10             	add    $0x10,%esp
  release(&ptable.lock);
80104c3a:	83 ec 0c             	sub    $0xc,%esp
80104c3d:	68 a0 3d 11 80       	push   $0x80113da0
80104c42:	e8 96 03 00 00       	call   80104fdd <release>
80104c47:	83 c4 10             	add    $0x10,%esp
}
80104c4a:	90                   	nop
80104c4b:	c9                   	leave  
80104c4c:	c3                   	ret    

80104c4d <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104c4d:	55                   	push   %ebp
80104c4e:	89 e5                	mov    %esp,%ebp
80104c50:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104c53:	83 ec 0c             	sub    $0xc,%esp
80104c56:	68 a0 3d 11 80       	push   $0x80113da0
80104c5b:	e8 0f 03 00 00       	call   80104f6f <acquire>
80104c60:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c63:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104c6a:	eb 45                	jmp    80104cb1 <kill+0x64>
    if(p->pid == pid){
80104c6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c6f:	8b 40 10             	mov    0x10(%eax),%eax
80104c72:	39 45 08             	cmp    %eax,0x8(%ebp)
80104c75:	75 36                	jne    80104cad <kill+0x60>
      p->killed = 1;
80104c77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c7a:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104c81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c84:	8b 40 0c             	mov    0xc(%eax),%eax
80104c87:	83 f8 02             	cmp    $0x2,%eax
80104c8a:	75 0a                	jne    80104c96 <kill+0x49>
        p->state = RUNNABLE;
80104c8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c8f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104c96:	83 ec 0c             	sub    $0xc,%esp
80104c99:	68 a0 3d 11 80       	push   $0x80113da0
80104c9e:	e8 3a 03 00 00       	call   80104fdd <release>
80104ca3:	83 c4 10             	add    $0x10,%esp
      return 0;
80104ca6:	b8 00 00 00 00       	mov    $0x0,%eax
80104cab:	eb 22                	jmp    80104ccf <kill+0x82>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104cad:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104cb1:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
80104cb8:	72 b2                	jb     80104c6c <kill+0x1f>
    }
  }
  release(&ptable.lock);
80104cba:	83 ec 0c             	sub    $0xc,%esp
80104cbd:	68 a0 3d 11 80       	push   $0x80113da0
80104cc2:	e8 16 03 00 00       	call   80104fdd <release>
80104cc7:	83 c4 10             	add    $0x10,%esp
  return -1;
80104cca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104ccf:	c9                   	leave  
80104cd0:	c3                   	ret    

80104cd1 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104cd1:	55                   	push   %ebp
80104cd2:	89 e5                	mov    %esp,%ebp
80104cd4:	83 ec 48             	sub    $0x48,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104cd7:	c7 45 f0 d4 3d 11 80 	movl   $0x80113dd4,-0x10(%ebp)
80104cde:	e9 d7 00 00 00       	jmp    80104dba <procdump+0xe9>
    if(p->state == UNUSED)
80104ce3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ce6:	8b 40 0c             	mov    0xc(%eax),%eax
80104ce9:	85 c0                	test   %eax,%eax
80104ceb:	0f 84 c4 00 00 00    	je     80104db5 <procdump+0xe4>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104cf1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cf4:	8b 40 0c             	mov    0xc(%eax),%eax
80104cf7:	83 f8 05             	cmp    $0x5,%eax
80104cfa:	77 23                	ja     80104d1f <procdump+0x4e>
80104cfc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cff:	8b 40 0c             	mov    0xc(%eax),%eax
80104d02:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104d09:	85 c0                	test   %eax,%eax
80104d0b:	74 12                	je     80104d1f <procdump+0x4e>
      state = states[p->state];
80104d0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d10:	8b 40 0c             	mov    0xc(%eax),%eax
80104d13:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104d1a:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104d1d:	eb 07                	jmp    80104d26 <procdump+0x55>
    else
      state = "???";
80104d1f:	c7 45 ec 5a 87 10 80 	movl   $0x8010875a,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104d26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d29:	8d 50 6c             	lea    0x6c(%eax),%edx
80104d2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d2f:	8b 40 10             	mov    0x10(%eax),%eax
80104d32:	52                   	push   %edx
80104d33:	ff 75 ec             	pushl  -0x14(%ebp)
80104d36:	50                   	push   %eax
80104d37:	68 5e 87 10 80       	push   $0x8010875e
80104d3c:	e8 bb b6 ff ff       	call   801003fc <cprintf>
80104d41:	83 c4 10             	add    $0x10,%esp
    if(p->state == SLEEPING){
80104d44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d47:	8b 40 0c             	mov    0xc(%eax),%eax
80104d4a:	83 f8 02             	cmp    $0x2,%eax
80104d4d:	75 54                	jne    80104da3 <procdump+0xd2>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104d4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d52:	8b 40 1c             	mov    0x1c(%eax),%eax
80104d55:	8b 40 0c             	mov    0xc(%eax),%eax
80104d58:	83 c0 08             	add    $0x8,%eax
80104d5b:	89 c2                	mov    %eax,%edx
80104d5d:	83 ec 08             	sub    $0x8,%esp
80104d60:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104d63:	50                   	push   %eax
80104d64:	52                   	push   %edx
80104d65:	e8 c5 02 00 00       	call   8010502f <getcallerpcs>
80104d6a:	83 c4 10             	add    $0x10,%esp
      for(i=0; i<10 && pc[i] != 0; i++)
80104d6d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104d74:	eb 1c                	jmp    80104d92 <procdump+0xc1>
        cprintf(" %p", pc[i]);
80104d76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d79:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104d7d:	83 ec 08             	sub    $0x8,%esp
80104d80:	50                   	push   %eax
80104d81:	68 67 87 10 80       	push   $0x80108767
80104d86:	e8 71 b6 ff ff       	call   801003fc <cprintf>
80104d8b:	83 c4 10             	add    $0x10,%esp
      for(i=0; i<10 && pc[i] != 0; i++)
80104d8e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104d92:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104d96:	7f 0b                	jg     80104da3 <procdump+0xd2>
80104d98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d9b:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104d9f:	85 c0                	test   %eax,%eax
80104da1:	75 d3                	jne    80104d76 <procdump+0xa5>
    }
    cprintf("\n");
80104da3:	83 ec 0c             	sub    $0xc,%esp
80104da6:	68 6b 87 10 80       	push   $0x8010876b
80104dab:	e8 4c b6 ff ff       	call   801003fc <cprintf>
80104db0:	83 c4 10             	add    $0x10,%esp
80104db3:	eb 01                	jmp    80104db6 <procdump+0xe5>
      continue;
80104db5:	90                   	nop
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104db6:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104dba:	81 7d f0 d4 5c 11 80 	cmpl   $0x80115cd4,-0x10(%ebp)
80104dc1:	0f 82 1c ff ff ff    	jb     80104ce3 <procdump+0x12>
  }
}
80104dc7:	90                   	nop
80104dc8:	c9                   	leave  
80104dc9:	c3                   	ret    

80104dca <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80104dca:	55                   	push   %ebp
80104dcb:	89 e5                	mov    %esp,%ebp
80104dcd:	83 ec 08             	sub    $0x8,%esp
  initlock(&lk->lk, "sleep lock");
80104dd0:	8b 45 08             	mov    0x8(%ebp),%eax
80104dd3:	83 c0 04             	add    $0x4,%eax
80104dd6:	83 ec 08             	sub    $0x8,%esp
80104dd9:	68 97 87 10 80       	push   $0x80108797
80104dde:	50                   	push   %eax
80104ddf:	e8 69 01 00 00       	call   80104f4d <initlock>
80104de4:	83 c4 10             	add    $0x10,%esp
  lk->name = name;
80104de7:	8b 45 08             	mov    0x8(%ebp),%eax
80104dea:	8b 55 0c             	mov    0xc(%ebp),%edx
80104ded:	89 50 38             	mov    %edx,0x38(%eax)
  lk->locked = 0;
80104df0:	8b 45 08             	mov    0x8(%ebp),%eax
80104df3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->pid = 0;
80104df9:	8b 45 08             	mov    0x8(%ebp),%eax
80104dfc:	c7 40 3c 00 00 00 00 	movl   $0x0,0x3c(%eax)
}
80104e03:	90                   	nop
80104e04:	c9                   	leave  
80104e05:	c3                   	ret    

80104e06 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80104e06:	55                   	push   %ebp
80104e07:	89 e5                	mov    %esp,%ebp
80104e09:	83 ec 08             	sub    $0x8,%esp
  acquire(&lk->lk);
80104e0c:	8b 45 08             	mov    0x8(%ebp),%eax
80104e0f:	83 c0 04             	add    $0x4,%eax
80104e12:	83 ec 0c             	sub    $0xc,%esp
80104e15:	50                   	push   %eax
80104e16:	e8 54 01 00 00       	call   80104f6f <acquire>
80104e1b:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80104e1e:	eb 15                	jmp    80104e35 <acquiresleep+0x2f>
    sleep(lk, &lk->lk);
80104e20:	8b 45 08             	mov    0x8(%ebp),%eax
80104e23:	83 c0 04             	add    $0x4,%eax
80104e26:	83 ec 08             	sub    $0x8,%esp
80104e29:	50                   	push   %eax
80104e2a:	ff 75 08             	pushl  0x8(%ebp)
80104e2d:	e8 fe fc ff ff       	call   80104b30 <sleep>
80104e32:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80104e35:	8b 45 08             	mov    0x8(%ebp),%eax
80104e38:	8b 00                	mov    (%eax),%eax
80104e3a:	85 c0                	test   %eax,%eax
80104e3c:	75 e2                	jne    80104e20 <acquiresleep+0x1a>
  }
  lk->locked = 1;
80104e3e:	8b 45 08             	mov    0x8(%ebp),%eax
80104e41:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  lk->pid = myproc()->pid;
80104e47:	e8 2d f4 ff ff       	call   80104279 <myproc>
80104e4c:	8b 50 10             	mov    0x10(%eax),%edx
80104e4f:	8b 45 08             	mov    0x8(%ebp),%eax
80104e52:	89 50 3c             	mov    %edx,0x3c(%eax)
  release(&lk->lk);
80104e55:	8b 45 08             	mov    0x8(%ebp),%eax
80104e58:	83 c0 04             	add    $0x4,%eax
80104e5b:	83 ec 0c             	sub    $0xc,%esp
80104e5e:	50                   	push   %eax
80104e5f:	e8 79 01 00 00       	call   80104fdd <release>
80104e64:	83 c4 10             	add    $0x10,%esp
}
80104e67:	90                   	nop
80104e68:	c9                   	leave  
80104e69:	c3                   	ret    

80104e6a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80104e6a:	55                   	push   %ebp
80104e6b:	89 e5                	mov    %esp,%ebp
80104e6d:	83 ec 08             	sub    $0x8,%esp
  acquire(&lk->lk);
80104e70:	8b 45 08             	mov    0x8(%ebp),%eax
80104e73:	83 c0 04             	add    $0x4,%eax
80104e76:	83 ec 0c             	sub    $0xc,%esp
80104e79:	50                   	push   %eax
80104e7a:	e8 f0 00 00 00       	call   80104f6f <acquire>
80104e7f:	83 c4 10             	add    $0x10,%esp
  lk->locked = 0;
80104e82:	8b 45 08             	mov    0x8(%ebp),%eax
80104e85:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->pid = 0;
80104e8b:	8b 45 08             	mov    0x8(%ebp),%eax
80104e8e:	c7 40 3c 00 00 00 00 	movl   $0x0,0x3c(%eax)
  wakeup(lk);
80104e95:	83 ec 0c             	sub    $0xc,%esp
80104e98:	ff 75 08             	pushl  0x8(%ebp)
80104e9b:	e8 76 fd ff ff       	call   80104c16 <wakeup>
80104ea0:	83 c4 10             	add    $0x10,%esp
  release(&lk->lk);
80104ea3:	8b 45 08             	mov    0x8(%ebp),%eax
80104ea6:	83 c0 04             	add    $0x4,%eax
80104ea9:	83 ec 0c             	sub    $0xc,%esp
80104eac:	50                   	push   %eax
80104ead:	e8 2b 01 00 00       	call   80104fdd <release>
80104eb2:	83 c4 10             	add    $0x10,%esp
}
80104eb5:	90                   	nop
80104eb6:	c9                   	leave  
80104eb7:	c3                   	ret    

80104eb8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80104eb8:	55                   	push   %ebp
80104eb9:	89 e5                	mov    %esp,%ebp
80104ebb:	53                   	push   %ebx
80104ebc:	83 ec 14             	sub    $0x14,%esp
  int r;
  
  acquire(&lk->lk);
80104ebf:	8b 45 08             	mov    0x8(%ebp),%eax
80104ec2:	83 c0 04             	add    $0x4,%eax
80104ec5:	83 ec 0c             	sub    $0xc,%esp
80104ec8:	50                   	push   %eax
80104ec9:	e8 a1 00 00 00       	call   80104f6f <acquire>
80104ece:	83 c4 10             	add    $0x10,%esp
  r = lk->locked && (lk->pid == myproc()->pid);
80104ed1:	8b 45 08             	mov    0x8(%ebp),%eax
80104ed4:	8b 00                	mov    (%eax),%eax
80104ed6:	85 c0                	test   %eax,%eax
80104ed8:	74 19                	je     80104ef3 <holdingsleep+0x3b>
80104eda:	8b 45 08             	mov    0x8(%ebp),%eax
80104edd:	8b 58 3c             	mov    0x3c(%eax),%ebx
80104ee0:	e8 94 f3 ff ff       	call   80104279 <myproc>
80104ee5:	8b 40 10             	mov    0x10(%eax),%eax
80104ee8:	39 c3                	cmp    %eax,%ebx
80104eea:	75 07                	jne    80104ef3 <holdingsleep+0x3b>
80104eec:	b8 01 00 00 00       	mov    $0x1,%eax
80104ef1:	eb 05                	jmp    80104ef8 <holdingsleep+0x40>
80104ef3:	b8 00 00 00 00       	mov    $0x0,%eax
80104ef8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&lk->lk);
80104efb:	8b 45 08             	mov    0x8(%ebp),%eax
80104efe:	83 c0 04             	add    $0x4,%eax
80104f01:	83 ec 0c             	sub    $0xc,%esp
80104f04:	50                   	push   %eax
80104f05:	e8 d3 00 00 00       	call   80104fdd <release>
80104f0a:	83 c4 10             	add    $0x10,%esp
  return r;
80104f0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104f10:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f13:	c9                   	leave  
80104f14:	c3                   	ret    

80104f15 <readeflags>:
{
80104f15:	55                   	push   %ebp
80104f16:	89 e5                	mov    %esp,%ebp
80104f18:	83 ec 10             	sub    $0x10,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104f1b:	9c                   	pushf  
80104f1c:	58                   	pop    %eax
80104f1d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104f20:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f23:	c9                   	leave  
80104f24:	c3                   	ret    

80104f25 <cli>:
{
80104f25:	55                   	push   %ebp
80104f26:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104f28:	fa                   	cli    
}
80104f29:	90                   	nop
80104f2a:	5d                   	pop    %ebp
80104f2b:	c3                   	ret    

80104f2c <sti>:
{
80104f2c:	55                   	push   %ebp
80104f2d:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104f2f:	fb                   	sti    
}
80104f30:	90                   	nop
80104f31:	5d                   	pop    %ebp
80104f32:	c3                   	ret    

80104f33 <xchg>:
{
80104f33:	55                   	push   %ebp
80104f34:	89 e5                	mov    %esp,%ebp
80104f36:	83 ec 10             	sub    $0x10,%esp
  asm volatile("lock; xchgl %0, %1" :
80104f39:	8b 55 08             	mov    0x8(%ebp),%edx
80104f3c:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f3f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104f42:	f0 87 02             	lock xchg %eax,(%edx)
80104f45:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return result;
80104f48:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f4b:	c9                   	leave  
80104f4c:	c3                   	ret    

80104f4d <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104f4d:	55                   	push   %ebp
80104f4e:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104f50:	8b 45 08             	mov    0x8(%ebp),%eax
80104f53:	8b 55 0c             	mov    0xc(%ebp),%edx
80104f56:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104f59:	8b 45 08             	mov    0x8(%ebp),%eax
80104f5c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104f62:	8b 45 08             	mov    0x8(%ebp),%eax
80104f65:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104f6c:	90                   	nop
80104f6d:	5d                   	pop    %ebp
80104f6e:	c3                   	ret    

80104f6f <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104f6f:	55                   	push   %ebp
80104f70:	89 e5                	mov    %esp,%ebp
80104f72:	53                   	push   %ebx
80104f73:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104f76:	e8 6f 01 00 00       	call   801050ea <pushcli>
  if(holding(lk))
80104f7b:	8b 45 08             	mov    0x8(%ebp),%eax
80104f7e:	83 ec 0c             	sub    $0xc,%esp
80104f81:	50                   	push   %eax
80104f82:	e8 22 01 00 00       	call   801050a9 <holding>
80104f87:	83 c4 10             	add    $0x10,%esp
80104f8a:	85 c0                	test   %eax,%eax
80104f8c:	74 0d                	je     80104f9b <acquire+0x2c>
    panic("acquire");
80104f8e:	83 ec 0c             	sub    $0xc,%esp
80104f91:	68 a2 87 10 80       	push   $0x801087a2
80104f96:	e8 01 b6 ff ff       	call   8010059c <panic>

  // The xchg is atomic.
  while(xchg(&lk->locked, 1) != 0)
80104f9b:	90                   	nop
80104f9c:	8b 45 08             	mov    0x8(%ebp),%eax
80104f9f:	83 ec 08             	sub    $0x8,%esp
80104fa2:	6a 01                	push   $0x1
80104fa4:	50                   	push   %eax
80104fa5:	e8 89 ff ff ff       	call   80104f33 <xchg>
80104faa:	83 c4 10             	add    $0x10,%esp
80104fad:	85 c0                	test   %eax,%eax
80104faf:	75 eb                	jne    80104f9c <acquire+0x2d>
    ;

  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen after the lock is acquired.
  __sync_synchronize();
80104fb1:	f0 83 0c 24 00       	lock orl $0x0,(%esp)

  // Record info about lock acquisition for debugging.
  lk->cpu = mycpu();
80104fb6:	8b 5d 08             	mov    0x8(%ebp),%ebx
80104fb9:	e8 43 f2 ff ff       	call   80104201 <mycpu>
80104fbe:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80104fc1:	8b 45 08             	mov    0x8(%ebp),%eax
80104fc4:	83 c0 0c             	add    $0xc,%eax
80104fc7:	83 ec 08             	sub    $0x8,%esp
80104fca:	50                   	push   %eax
80104fcb:	8d 45 08             	lea    0x8(%ebp),%eax
80104fce:	50                   	push   %eax
80104fcf:	e8 5b 00 00 00       	call   8010502f <getcallerpcs>
80104fd4:	83 c4 10             	add    $0x10,%esp
}
80104fd7:	90                   	nop
80104fd8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fdb:	c9                   	leave  
80104fdc:	c3                   	ret    

80104fdd <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104fdd:	55                   	push   %ebp
80104fde:	89 e5                	mov    %esp,%ebp
80104fe0:	83 ec 08             	sub    $0x8,%esp
  if(!holding(lk))
80104fe3:	83 ec 0c             	sub    $0xc,%esp
80104fe6:	ff 75 08             	pushl  0x8(%ebp)
80104fe9:	e8 bb 00 00 00       	call   801050a9 <holding>
80104fee:	83 c4 10             	add    $0x10,%esp
80104ff1:	85 c0                	test   %eax,%eax
80104ff3:	75 0d                	jne    80105002 <release+0x25>
    panic("release");
80104ff5:	83 ec 0c             	sub    $0xc,%esp
80104ff8:	68 aa 87 10 80       	push   $0x801087aa
80104ffd:	e8 9a b5 ff ff       	call   8010059c <panic>

  lk->pcs[0] = 0;
80105002:	8b 45 08             	mov    0x8(%ebp),%eax
80105005:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
8010500c:	8b 45 08             	mov    0x8(%ebp),%eax
8010500f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that all the stores in the critical
  // section are visible to other cores before the lock is released.
  // Both the C compiler and the hardware may re-order loads and
  // stores; __sync_synchronize() tells them both not to.
  __sync_synchronize();
80105016:	f0 83 0c 24 00       	lock orl $0x0,(%esp)

  // Release the lock, equivalent to lk->locked = 0.
  // This code can't use a C assignment, since it might
  // not be atomic. A real OS would use C atomics here.
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
8010501b:	8b 45 08             	mov    0x8(%ebp),%eax
8010501e:	8b 55 08             	mov    0x8(%ebp),%edx
80105021:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  popcli();
80105027:	e8 0c 01 00 00       	call   80105138 <popcli>
}
8010502c:	90                   	nop
8010502d:	c9                   	leave  
8010502e:	c3                   	ret    

8010502f <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
8010502f:	55                   	push   %ebp
80105030:	89 e5                	mov    %esp,%ebp
80105032:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80105035:	8b 45 08             	mov    0x8(%ebp),%eax
80105038:	83 e8 08             	sub    $0x8,%eax
8010503b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
8010503e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105045:	eb 38                	jmp    8010507f <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105047:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
8010504b:	74 53                	je     801050a0 <getcallerpcs+0x71>
8010504d:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105054:	76 4a                	jbe    801050a0 <getcallerpcs+0x71>
80105056:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
8010505a:	74 44                	je     801050a0 <getcallerpcs+0x71>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010505c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010505f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105066:	8b 45 0c             	mov    0xc(%ebp),%eax
80105069:	01 c2                	add    %eax,%edx
8010506b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010506e:	8b 40 04             	mov    0x4(%eax),%eax
80105071:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105073:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105076:	8b 00                	mov    (%eax),%eax
80105078:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
8010507b:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010507f:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105083:	7e c2                	jle    80105047 <getcallerpcs+0x18>
  }
  for(; i < 10; i++)
80105085:	eb 19                	jmp    801050a0 <getcallerpcs+0x71>
    pcs[i] = 0;
80105087:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010508a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105091:	8b 45 0c             	mov    0xc(%ebp),%eax
80105094:	01 d0                	add    %edx,%eax
80105096:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  for(; i < 10; i++)
8010509c:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801050a0:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801050a4:	7e e1                	jle    80105087 <getcallerpcs+0x58>
}
801050a6:	90                   	nop
801050a7:	c9                   	leave  
801050a8:	c3                   	ret    

801050a9 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801050a9:	55                   	push   %ebp
801050aa:	89 e5                	mov    %esp,%ebp
801050ac:	53                   	push   %ebx
801050ad:	83 ec 14             	sub    $0x14,%esp
  int r;
  pushcli();
801050b0:	e8 35 00 00 00       	call   801050ea <pushcli>
  r = lock->locked && lock->cpu == mycpu();
801050b5:	8b 45 08             	mov    0x8(%ebp),%eax
801050b8:	8b 00                	mov    (%eax),%eax
801050ba:	85 c0                	test   %eax,%eax
801050bc:	74 16                	je     801050d4 <holding+0x2b>
801050be:	8b 45 08             	mov    0x8(%ebp),%eax
801050c1:	8b 58 08             	mov    0x8(%eax),%ebx
801050c4:	e8 38 f1 ff ff       	call   80104201 <mycpu>
801050c9:	39 c3                	cmp    %eax,%ebx
801050cb:	75 07                	jne    801050d4 <holding+0x2b>
801050cd:	b8 01 00 00 00       	mov    $0x1,%eax
801050d2:	eb 05                	jmp    801050d9 <holding+0x30>
801050d4:	b8 00 00 00 00       	mov    $0x0,%eax
801050d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  popcli();
801050dc:	e8 57 00 00 00       	call   80105138 <popcli>
  return r;
801050e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801050e4:	83 c4 14             	add    $0x14,%esp
801050e7:	5b                   	pop    %ebx
801050e8:	5d                   	pop    %ebp
801050e9:	c3                   	ret    

801050ea <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801050ea:	55                   	push   %ebp
801050eb:	89 e5                	mov    %esp,%ebp
801050ed:	83 ec 18             	sub    $0x18,%esp
  int eflags;

  eflags = readeflags();
801050f0:	e8 20 fe ff ff       	call   80104f15 <readeflags>
801050f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  cli();
801050f8:	e8 28 fe ff ff       	call   80104f25 <cli>
  if(mycpu()->ncli == 0)
801050fd:	e8 ff f0 ff ff       	call   80104201 <mycpu>
80105102:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
80105108:	85 c0                	test   %eax,%eax
8010510a:	75 15                	jne    80105121 <pushcli+0x37>
    mycpu()->intena = eflags & FL_IF;
8010510c:	e8 f0 f0 ff ff       	call   80104201 <mycpu>
80105111:	89 c2                	mov    %eax,%edx
80105113:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105116:	25 00 02 00 00       	and    $0x200,%eax
8010511b:	89 82 a8 00 00 00    	mov    %eax,0xa8(%edx)
  mycpu()->ncli += 1;
80105121:	e8 db f0 ff ff       	call   80104201 <mycpu>
80105126:	8b 90 a4 00 00 00    	mov    0xa4(%eax),%edx
8010512c:	83 c2 01             	add    $0x1,%edx
8010512f:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
}
80105135:	90                   	nop
80105136:	c9                   	leave  
80105137:	c3                   	ret    

80105138 <popcli>:

void
popcli(void)
{
80105138:	55                   	push   %ebp
80105139:	89 e5                	mov    %esp,%ebp
8010513b:	83 ec 08             	sub    $0x8,%esp
  if(readeflags()&FL_IF)
8010513e:	e8 d2 fd ff ff       	call   80104f15 <readeflags>
80105143:	25 00 02 00 00       	and    $0x200,%eax
80105148:	85 c0                	test   %eax,%eax
8010514a:	74 0d                	je     80105159 <popcli+0x21>
    panic("popcli - interruptible");
8010514c:	83 ec 0c             	sub    $0xc,%esp
8010514f:	68 b2 87 10 80       	push   $0x801087b2
80105154:	e8 43 b4 ff ff       	call   8010059c <panic>
  if(--mycpu()->ncli < 0)
80105159:	e8 a3 f0 ff ff       	call   80104201 <mycpu>
8010515e:	8b 90 a4 00 00 00    	mov    0xa4(%eax),%edx
80105164:	83 ea 01             	sub    $0x1,%edx
80105167:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
8010516d:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
80105173:	85 c0                	test   %eax,%eax
80105175:	79 0d                	jns    80105184 <popcli+0x4c>
    panic("popcli");
80105177:	83 ec 0c             	sub    $0xc,%esp
8010517a:	68 c9 87 10 80       	push   $0x801087c9
8010517f:	e8 18 b4 ff ff       	call   8010059c <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80105184:	e8 78 f0 ff ff       	call   80104201 <mycpu>
80105189:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
8010518f:	85 c0                	test   %eax,%eax
80105191:	75 14                	jne    801051a7 <popcli+0x6f>
80105193:	e8 69 f0 ff ff       	call   80104201 <mycpu>
80105198:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
8010519e:	85 c0                	test   %eax,%eax
801051a0:	74 05                	je     801051a7 <popcli+0x6f>
    sti();
801051a2:	e8 85 fd ff ff       	call   80104f2c <sti>
}
801051a7:	90                   	nop
801051a8:	c9                   	leave  
801051a9:	c3                   	ret    

801051aa <stosb>:
{
801051aa:	55                   	push   %ebp
801051ab:	89 e5                	mov    %esp,%ebp
801051ad:	57                   	push   %edi
801051ae:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801051af:	8b 4d 08             	mov    0x8(%ebp),%ecx
801051b2:	8b 55 10             	mov    0x10(%ebp),%edx
801051b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801051b8:	89 cb                	mov    %ecx,%ebx
801051ba:	89 df                	mov    %ebx,%edi
801051bc:	89 d1                	mov    %edx,%ecx
801051be:	fc                   	cld    
801051bf:	f3 aa                	rep stos %al,%es:(%edi)
801051c1:	89 ca                	mov    %ecx,%edx
801051c3:	89 fb                	mov    %edi,%ebx
801051c5:	89 5d 08             	mov    %ebx,0x8(%ebp)
801051c8:	89 55 10             	mov    %edx,0x10(%ebp)
}
801051cb:	90                   	nop
801051cc:	5b                   	pop    %ebx
801051cd:	5f                   	pop    %edi
801051ce:	5d                   	pop    %ebp
801051cf:	c3                   	ret    

801051d0 <stosl>:
{
801051d0:	55                   	push   %ebp
801051d1:	89 e5                	mov    %esp,%ebp
801051d3:	57                   	push   %edi
801051d4:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801051d5:	8b 4d 08             	mov    0x8(%ebp),%ecx
801051d8:	8b 55 10             	mov    0x10(%ebp),%edx
801051db:	8b 45 0c             	mov    0xc(%ebp),%eax
801051de:	89 cb                	mov    %ecx,%ebx
801051e0:	89 df                	mov    %ebx,%edi
801051e2:	89 d1                	mov    %edx,%ecx
801051e4:	fc                   	cld    
801051e5:	f3 ab                	rep stos %eax,%es:(%edi)
801051e7:	89 ca                	mov    %ecx,%edx
801051e9:	89 fb                	mov    %edi,%ebx
801051eb:	89 5d 08             	mov    %ebx,0x8(%ebp)
801051ee:	89 55 10             	mov    %edx,0x10(%ebp)
}
801051f1:	90                   	nop
801051f2:	5b                   	pop    %ebx
801051f3:	5f                   	pop    %edi
801051f4:	5d                   	pop    %ebp
801051f5:	c3                   	ret    

801051f6 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801051f6:	55                   	push   %ebp
801051f7:	89 e5                	mov    %esp,%ebp
  if ((int)dst%4 == 0 && n%4 == 0){
801051f9:	8b 45 08             	mov    0x8(%ebp),%eax
801051fc:	83 e0 03             	and    $0x3,%eax
801051ff:	85 c0                	test   %eax,%eax
80105201:	75 43                	jne    80105246 <memset+0x50>
80105203:	8b 45 10             	mov    0x10(%ebp),%eax
80105206:	83 e0 03             	and    $0x3,%eax
80105209:	85 c0                	test   %eax,%eax
8010520b:	75 39                	jne    80105246 <memset+0x50>
    c &= 0xFF;
8010520d:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105214:	8b 45 10             	mov    0x10(%ebp),%eax
80105217:	c1 e8 02             	shr    $0x2,%eax
8010521a:	89 c1                	mov    %eax,%ecx
8010521c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010521f:	c1 e0 18             	shl    $0x18,%eax
80105222:	89 c2                	mov    %eax,%edx
80105224:	8b 45 0c             	mov    0xc(%ebp),%eax
80105227:	c1 e0 10             	shl    $0x10,%eax
8010522a:	09 c2                	or     %eax,%edx
8010522c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010522f:	c1 e0 08             	shl    $0x8,%eax
80105232:	09 d0                	or     %edx,%eax
80105234:	0b 45 0c             	or     0xc(%ebp),%eax
80105237:	51                   	push   %ecx
80105238:	50                   	push   %eax
80105239:	ff 75 08             	pushl  0x8(%ebp)
8010523c:	e8 8f ff ff ff       	call   801051d0 <stosl>
80105241:	83 c4 0c             	add    $0xc,%esp
80105244:	eb 12                	jmp    80105258 <memset+0x62>
  } else
    stosb(dst, c, n);
80105246:	8b 45 10             	mov    0x10(%ebp),%eax
80105249:	50                   	push   %eax
8010524a:	ff 75 0c             	pushl  0xc(%ebp)
8010524d:	ff 75 08             	pushl  0x8(%ebp)
80105250:	e8 55 ff ff ff       	call   801051aa <stosb>
80105255:	83 c4 0c             	add    $0xc,%esp
  return dst;
80105258:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010525b:	c9                   	leave  
8010525c:	c3                   	ret    

8010525d <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
8010525d:	55                   	push   %ebp
8010525e:	89 e5                	mov    %esp,%ebp
80105260:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;

  s1 = v1;
80105263:	8b 45 08             	mov    0x8(%ebp),%eax
80105266:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105269:	8b 45 0c             	mov    0xc(%ebp),%eax
8010526c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
8010526f:	eb 30                	jmp    801052a1 <memcmp+0x44>
    if(*s1 != *s2)
80105271:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105274:	0f b6 10             	movzbl (%eax),%edx
80105277:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010527a:	0f b6 00             	movzbl (%eax),%eax
8010527d:	38 c2                	cmp    %al,%dl
8010527f:	74 18                	je     80105299 <memcmp+0x3c>
      return *s1 - *s2;
80105281:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105284:	0f b6 00             	movzbl (%eax),%eax
80105287:	0f b6 d0             	movzbl %al,%edx
8010528a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010528d:	0f b6 00             	movzbl (%eax),%eax
80105290:	0f b6 c0             	movzbl %al,%eax
80105293:	29 c2                	sub    %eax,%edx
80105295:	89 d0                	mov    %edx,%eax
80105297:	eb 1a                	jmp    801052b3 <memcmp+0x56>
    s1++, s2++;
80105299:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010529d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  while(n-- > 0){
801052a1:	8b 45 10             	mov    0x10(%ebp),%eax
801052a4:	8d 50 ff             	lea    -0x1(%eax),%edx
801052a7:	89 55 10             	mov    %edx,0x10(%ebp)
801052aa:	85 c0                	test   %eax,%eax
801052ac:	75 c3                	jne    80105271 <memcmp+0x14>
  }

  return 0;
801052ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801052b3:	c9                   	leave  
801052b4:	c3                   	ret    

801052b5 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801052b5:	55                   	push   %ebp
801052b6:	89 e5                	mov    %esp,%ebp
801052b8:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
801052bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801052be:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
801052c1:	8b 45 08             	mov    0x8(%ebp),%eax
801052c4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
801052c7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052ca:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801052cd:	73 54                	jae    80105323 <memmove+0x6e>
801052cf:	8b 55 fc             	mov    -0x4(%ebp),%edx
801052d2:	8b 45 10             	mov    0x10(%ebp),%eax
801052d5:	01 d0                	add    %edx,%eax
801052d7:	39 45 f8             	cmp    %eax,-0x8(%ebp)
801052da:	73 47                	jae    80105323 <memmove+0x6e>
    s += n;
801052dc:	8b 45 10             	mov    0x10(%ebp),%eax
801052df:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801052e2:	8b 45 10             	mov    0x10(%ebp),%eax
801052e5:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801052e8:	eb 13                	jmp    801052fd <memmove+0x48>
      *--d = *--s;
801052ea:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801052ee:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801052f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052f5:	0f b6 10             	movzbl (%eax),%edx
801052f8:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052fb:	88 10                	mov    %dl,(%eax)
    while(n-- > 0)
801052fd:	8b 45 10             	mov    0x10(%ebp),%eax
80105300:	8d 50 ff             	lea    -0x1(%eax),%edx
80105303:	89 55 10             	mov    %edx,0x10(%ebp)
80105306:	85 c0                	test   %eax,%eax
80105308:	75 e0                	jne    801052ea <memmove+0x35>
  if(s < d && s + n > d){
8010530a:	eb 24                	jmp    80105330 <memmove+0x7b>
  } else
    while(n-- > 0)
      *d++ = *s++;
8010530c:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010530f:	8d 42 01             	lea    0x1(%edx),%eax
80105312:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105315:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105318:	8d 48 01             	lea    0x1(%eax),%ecx
8010531b:	89 4d f8             	mov    %ecx,-0x8(%ebp)
8010531e:	0f b6 12             	movzbl (%edx),%edx
80105321:	88 10                	mov    %dl,(%eax)
    while(n-- > 0)
80105323:	8b 45 10             	mov    0x10(%ebp),%eax
80105326:	8d 50 ff             	lea    -0x1(%eax),%edx
80105329:	89 55 10             	mov    %edx,0x10(%ebp)
8010532c:	85 c0                	test   %eax,%eax
8010532e:	75 dc                	jne    8010530c <memmove+0x57>

  return dst;
80105330:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105333:	c9                   	leave  
80105334:	c3                   	ret    

80105335 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105335:	55                   	push   %ebp
80105336:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80105338:	ff 75 10             	pushl  0x10(%ebp)
8010533b:	ff 75 0c             	pushl  0xc(%ebp)
8010533e:	ff 75 08             	pushl  0x8(%ebp)
80105341:	e8 6f ff ff ff       	call   801052b5 <memmove>
80105346:	83 c4 0c             	add    $0xc,%esp
}
80105349:	c9                   	leave  
8010534a:	c3                   	ret    

8010534b <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
8010534b:	55                   	push   %ebp
8010534c:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
8010534e:	eb 0c                	jmp    8010535c <strncmp+0x11>
    n--, p++, q++;
80105350:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105354:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105358:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  while(n > 0 && *p && *p == *q)
8010535c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105360:	74 1a                	je     8010537c <strncmp+0x31>
80105362:	8b 45 08             	mov    0x8(%ebp),%eax
80105365:	0f b6 00             	movzbl (%eax),%eax
80105368:	84 c0                	test   %al,%al
8010536a:	74 10                	je     8010537c <strncmp+0x31>
8010536c:	8b 45 08             	mov    0x8(%ebp),%eax
8010536f:	0f b6 10             	movzbl (%eax),%edx
80105372:	8b 45 0c             	mov    0xc(%ebp),%eax
80105375:	0f b6 00             	movzbl (%eax),%eax
80105378:	38 c2                	cmp    %al,%dl
8010537a:	74 d4                	je     80105350 <strncmp+0x5>
  if(n == 0)
8010537c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105380:	75 07                	jne    80105389 <strncmp+0x3e>
    return 0;
80105382:	b8 00 00 00 00       	mov    $0x0,%eax
80105387:	eb 16                	jmp    8010539f <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105389:	8b 45 08             	mov    0x8(%ebp),%eax
8010538c:	0f b6 00             	movzbl (%eax),%eax
8010538f:	0f b6 d0             	movzbl %al,%edx
80105392:	8b 45 0c             	mov    0xc(%ebp),%eax
80105395:	0f b6 00             	movzbl (%eax),%eax
80105398:	0f b6 c0             	movzbl %al,%eax
8010539b:	29 c2                	sub    %eax,%edx
8010539d:	89 d0                	mov    %edx,%eax
}
8010539f:	5d                   	pop    %ebp
801053a0:	c3                   	ret    

801053a1 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801053a1:	55                   	push   %ebp
801053a2:	89 e5                	mov    %esp,%ebp
801053a4:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
801053a7:	8b 45 08             	mov    0x8(%ebp),%eax
801053aa:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
801053ad:	90                   	nop
801053ae:	8b 45 10             	mov    0x10(%ebp),%eax
801053b1:	8d 50 ff             	lea    -0x1(%eax),%edx
801053b4:	89 55 10             	mov    %edx,0x10(%ebp)
801053b7:	85 c0                	test   %eax,%eax
801053b9:	7e 2c                	jle    801053e7 <strncpy+0x46>
801053bb:	8b 55 0c             	mov    0xc(%ebp),%edx
801053be:	8d 42 01             	lea    0x1(%edx),%eax
801053c1:	89 45 0c             	mov    %eax,0xc(%ebp)
801053c4:	8b 45 08             	mov    0x8(%ebp),%eax
801053c7:	8d 48 01             	lea    0x1(%eax),%ecx
801053ca:	89 4d 08             	mov    %ecx,0x8(%ebp)
801053cd:	0f b6 12             	movzbl (%edx),%edx
801053d0:	88 10                	mov    %dl,(%eax)
801053d2:	0f b6 00             	movzbl (%eax),%eax
801053d5:	84 c0                	test   %al,%al
801053d7:	75 d5                	jne    801053ae <strncpy+0xd>
    ;
  while(n-- > 0)
801053d9:	eb 0c                	jmp    801053e7 <strncpy+0x46>
    *s++ = 0;
801053db:	8b 45 08             	mov    0x8(%ebp),%eax
801053de:	8d 50 01             	lea    0x1(%eax),%edx
801053e1:	89 55 08             	mov    %edx,0x8(%ebp)
801053e4:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
801053e7:	8b 45 10             	mov    0x10(%ebp),%eax
801053ea:	8d 50 ff             	lea    -0x1(%eax),%edx
801053ed:	89 55 10             	mov    %edx,0x10(%ebp)
801053f0:	85 c0                	test   %eax,%eax
801053f2:	7f e7                	jg     801053db <strncpy+0x3a>
  return os;
801053f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801053f7:	c9                   	leave  
801053f8:	c3                   	ret    

801053f9 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801053f9:	55                   	push   %ebp
801053fa:	89 e5                	mov    %esp,%ebp
801053fc:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
801053ff:	8b 45 08             	mov    0x8(%ebp),%eax
80105402:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105405:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105409:	7f 05                	jg     80105410 <safestrcpy+0x17>
    return os;
8010540b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010540e:	eb 31                	jmp    80105441 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105410:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105414:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105418:	7e 1e                	jle    80105438 <safestrcpy+0x3f>
8010541a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010541d:	8d 42 01             	lea    0x1(%edx),%eax
80105420:	89 45 0c             	mov    %eax,0xc(%ebp)
80105423:	8b 45 08             	mov    0x8(%ebp),%eax
80105426:	8d 48 01             	lea    0x1(%eax),%ecx
80105429:	89 4d 08             	mov    %ecx,0x8(%ebp)
8010542c:	0f b6 12             	movzbl (%edx),%edx
8010542f:	88 10                	mov    %dl,(%eax)
80105431:	0f b6 00             	movzbl (%eax),%eax
80105434:	84 c0                	test   %al,%al
80105436:	75 d8                	jne    80105410 <safestrcpy+0x17>
    ;
  *s = 0;
80105438:	8b 45 08             	mov    0x8(%ebp),%eax
8010543b:	c6 00 00             	movb   $0x0,(%eax)
  return os;
8010543e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105441:	c9                   	leave  
80105442:	c3                   	ret    

80105443 <strlen>:

int
strlen(const char *s)
{
80105443:	55                   	push   %ebp
80105444:	89 e5                	mov    %esp,%ebp
80105446:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105449:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105450:	eb 04                	jmp    80105456 <strlen+0x13>
80105452:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105456:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105459:	8b 45 08             	mov    0x8(%ebp),%eax
8010545c:	01 d0                	add    %edx,%eax
8010545e:	0f b6 00             	movzbl (%eax),%eax
80105461:	84 c0                	test   %al,%al
80105463:	75 ed                	jne    80105452 <strlen+0xf>
    ;
  return n;
80105465:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105468:	c9                   	leave  
80105469:	c3                   	ret    

8010546a <swtch>:
trapret just above it; that is where forkret will return. trapret restores user registers
 from values stored at the top of the kernel stack and jumps into the process
*/
.globl swtch
swtch:
  movl 4(%esp), %eax # this instruction loads 32-bit value from address %esp + 4 and stores it in register %eax   eax 保存了 &(c->scheduler)
8010546a:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx # %edx 保存了
8010546e:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80105472:	55                   	push   %ebp
  pushl %ebx
80105473:	53                   	push   %ebx
  pushl %esi
80105474:	56                   	push   %esi
  pushl %edi
80105475:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105476:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105478:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
8010547a:	5f                   	pop    %edi
  popl %esi
8010547b:	5e                   	pop    %esi
  popl %ebx
8010547c:	5b                   	pop    %ebx
  popl %ebp
8010547d:	5d                   	pop    %ebp
  ret
8010547e:	c3                   	ret    

8010547f <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
8010547f:	55                   	push   %ebp
80105480:	89 e5                	mov    %esp,%ebp
80105482:	83 ec 18             	sub    $0x18,%esp
  struct proc *curproc = myproc();
80105485:	e8 ef ed ff ff       	call   80104279 <myproc>
8010548a:	89 45 f4             	mov    %eax,-0xc(%ebp)

  if(addr >= curproc->sz || addr+4 > curproc->sz)
8010548d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105490:	8b 00                	mov    (%eax),%eax
80105492:	39 45 08             	cmp    %eax,0x8(%ebp)
80105495:	73 0f                	jae    801054a6 <fetchint+0x27>
80105497:	8b 45 08             	mov    0x8(%ebp),%eax
8010549a:	8d 50 04             	lea    0x4(%eax),%edx
8010549d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054a0:	8b 00                	mov    (%eax),%eax
801054a2:	39 c2                	cmp    %eax,%edx
801054a4:	76 07                	jbe    801054ad <fetchint+0x2e>
    return -1;
801054a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054ab:	eb 0f                	jmp    801054bc <fetchint+0x3d>
  *ip = *(int*)(addr);
801054ad:	8b 45 08             	mov    0x8(%ebp),%eax
801054b0:	8b 10                	mov    (%eax),%edx
801054b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801054b5:	89 10                	mov    %edx,(%eax)
  return 0;
801054b7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801054bc:	c9                   	leave  
801054bd:	c3                   	ret    

801054be <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801054be:	55                   	push   %ebp
801054bf:	89 e5                	mov    %esp,%ebp
801054c1:	83 ec 18             	sub    $0x18,%esp
  char *s, *ep;
  struct proc *curproc = myproc();
801054c4:	e8 b0 ed ff ff       	call   80104279 <myproc>
801054c9:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if(addr >= curproc->sz)
801054cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054cf:	8b 00                	mov    (%eax),%eax
801054d1:	39 45 08             	cmp    %eax,0x8(%ebp)
801054d4:	72 07                	jb     801054dd <fetchstr+0x1f>
    return -1;
801054d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054db:	eb 43                	jmp    80105520 <fetchstr+0x62>
  *pp = (char*)addr;
801054dd:	8b 55 08             	mov    0x8(%ebp),%edx
801054e0:	8b 45 0c             	mov    0xc(%ebp),%eax
801054e3:	89 10                	mov    %edx,(%eax)
  ep = (char*)curproc->sz;
801054e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054e8:	8b 00                	mov    (%eax),%eax
801054ea:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(s = *pp; s < ep; s++){
801054ed:	8b 45 0c             	mov    0xc(%ebp),%eax
801054f0:	8b 00                	mov    (%eax),%eax
801054f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801054f5:	eb 1c                	jmp    80105513 <fetchstr+0x55>
    if(*s == 0)
801054f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054fa:	0f b6 00             	movzbl (%eax),%eax
801054fd:	84 c0                	test   %al,%al
801054ff:	75 0e                	jne    8010550f <fetchstr+0x51>
      return s - *pp;
80105501:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105504:	8b 45 0c             	mov    0xc(%ebp),%eax
80105507:	8b 00                	mov    (%eax),%eax
80105509:	29 c2                	sub    %eax,%edx
8010550b:	89 d0                	mov    %edx,%eax
8010550d:	eb 11                	jmp    80105520 <fetchstr+0x62>
  for(s = *pp; s < ep; s++){
8010550f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105513:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105516:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80105519:	72 dc                	jb     801054f7 <fetchstr+0x39>
  }
  return -1;
8010551b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105520:	c9                   	leave  
80105521:	c3                   	ret    

80105522 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105522:	55                   	push   %ebp
80105523:	89 e5                	mov    %esp,%ebp
80105525:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80105528:	e8 4c ed ff ff       	call   80104279 <myproc>
8010552d:	8b 40 18             	mov    0x18(%eax),%eax
80105530:	8b 40 44             	mov    0x44(%eax),%eax
80105533:	8b 55 08             	mov    0x8(%ebp),%edx
80105536:	c1 e2 02             	shl    $0x2,%edx
80105539:	01 d0                	add    %edx,%eax
8010553b:	83 c0 04             	add    $0x4,%eax
8010553e:	83 ec 08             	sub    $0x8,%esp
80105541:	ff 75 0c             	pushl  0xc(%ebp)
80105544:	50                   	push   %eax
80105545:	e8 35 ff ff ff       	call   8010547f <fetchint>
8010554a:	83 c4 10             	add    $0x10,%esp
}
8010554d:	c9                   	leave  
8010554e:	c3                   	ret    

8010554f <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010554f:	55                   	push   %ebp
80105550:	89 e5                	mov    %esp,%ebp
80105552:	83 ec 18             	sub    $0x18,%esp
  int i;
  struct proc *curproc = myproc();
80105555:	e8 1f ed ff ff       	call   80104279 <myproc>
8010555a:	89 45 f4             	mov    %eax,-0xc(%ebp)
 
  if(argint(n, &i) < 0)
8010555d:	83 ec 08             	sub    $0x8,%esp
80105560:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105563:	50                   	push   %eax
80105564:	ff 75 08             	pushl  0x8(%ebp)
80105567:	e8 b6 ff ff ff       	call   80105522 <argint>
8010556c:	83 c4 10             	add    $0x10,%esp
8010556f:	85 c0                	test   %eax,%eax
80105571:	79 07                	jns    8010557a <argptr+0x2b>
    return -1;
80105573:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105578:	eb 3b                	jmp    801055b5 <argptr+0x66>
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
8010557a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010557e:	78 1f                	js     8010559f <argptr+0x50>
80105580:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105583:	8b 00                	mov    (%eax),%eax
80105585:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105588:	39 d0                	cmp    %edx,%eax
8010558a:	76 13                	jbe    8010559f <argptr+0x50>
8010558c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010558f:	89 c2                	mov    %eax,%edx
80105591:	8b 45 10             	mov    0x10(%ebp),%eax
80105594:	01 c2                	add    %eax,%edx
80105596:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105599:	8b 00                	mov    (%eax),%eax
8010559b:	39 c2                	cmp    %eax,%edx
8010559d:	76 07                	jbe    801055a6 <argptr+0x57>
    return -1;
8010559f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055a4:	eb 0f                	jmp    801055b5 <argptr+0x66>
  *pp = (char*)i;
801055a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055a9:	89 c2                	mov    %eax,%edx
801055ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801055ae:	89 10                	mov    %edx,(%eax)
  return 0;
801055b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055b5:	c9                   	leave  
801055b6:	c3                   	ret    

801055b7 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801055b7:	55                   	push   %ebp
801055b8:	89 e5                	mov    %esp,%ebp
801055ba:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
801055bd:	83 ec 08             	sub    $0x8,%esp
801055c0:	8d 45 f4             	lea    -0xc(%ebp),%eax
801055c3:	50                   	push   %eax
801055c4:	ff 75 08             	pushl  0x8(%ebp)
801055c7:	e8 56 ff ff ff       	call   80105522 <argint>
801055cc:	83 c4 10             	add    $0x10,%esp
801055cf:	85 c0                	test   %eax,%eax
801055d1:	79 07                	jns    801055da <argstr+0x23>
    return -1;
801055d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055d8:	eb 12                	jmp    801055ec <argstr+0x35>
  return fetchstr(addr, pp);
801055da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055dd:	83 ec 08             	sub    $0x8,%esp
801055e0:	ff 75 0c             	pushl  0xc(%ebp)
801055e3:	50                   	push   %eax
801055e4:	e8 d5 fe ff ff       	call   801054be <fetchstr>
801055e9:	83 c4 10             	add    $0x10,%esp
}
801055ec:	c9                   	leave  
801055ed:	c3                   	ret    

801055ee <syscall>:
};*/


void
syscall(void)
{
801055ee:	55                   	push   %ebp
801055ef:	89 e5                	mov    %esp,%ebp
801055f1:	83 ec 18             	sub    $0x18,%esp
  int num;
  struct proc *curproc = myproc();
801055f4:	e8 80 ec ff ff       	call   80104279 <myproc>
801055f9:	89 45 f4             	mov    %eax,-0xc(%ebp)

  num = curproc->tf->eax;
801055fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055ff:	8b 40 18             	mov    0x18(%eax),%eax
80105602:	8b 40 1c             	mov    0x1c(%eax),%eax
80105605:	89 45 f0             	mov    %eax,-0x10(%ebp)
  //调用系统调用时
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105608:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010560c:	7e 2f                	jle    8010563d <syscall+0x4f>
8010560e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105611:	83 f8 16             	cmp    $0x16,%eax
80105614:	77 27                	ja     8010563d <syscall+0x4f>
80105616:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105619:	8b 04 85 20 b0 10 80 	mov    -0x7fef4fe0(,%eax,4),%eax
80105620:	85 c0                	test   %eax,%eax
80105622:	74 19                	je     8010563d <syscall+0x4f>
    curproc->tf->eax = syscalls[num]();
80105624:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105627:	8b 04 85 20 b0 10 80 	mov    -0x7fef4fe0(,%eax,4),%eax
8010562e:	ff d0                	call   *%eax
80105630:	89 c2                	mov    %eax,%edx
80105632:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105635:	8b 40 18             	mov    0x18(%eax),%eax
80105638:	89 50 1c             	mov    %edx,0x1c(%eax)
8010563b:	eb 2b                	jmp    80105668 <syscall+0x7a>
    //cprintf("%s \n",syscall_name[num]);  这样就可以打印系统调用名和编号了不过会影响shell所以注释掉
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
8010563d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105640:	8d 50 6c             	lea    0x6c(%eax),%edx
    cprintf("%d %s: unknown sys call %d\n",
80105643:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105646:	8b 40 10             	mov    0x10(%eax),%eax
80105649:	ff 75 f0             	pushl  -0x10(%ebp)
8010564c:	52                   	push   %edx
8010564d:	50                   	push   %eax
8010564e:	68 d0 87 10 80       	push   $0x801087d0
80105653:	e8 a4 ad ff ff       	call   801003fc <cprintf>
80105658:	83 c4 10             	add    $0x10,%esp
    curproc->tf->eax = -1;
8010565b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010565e:	8b 40 18             	mov    0x18(%eax),%eax
80105661:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105668:	90                   	nop
80105669:	c9                   	leave  
8010566a:	c3                   	ret    

8010566b <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.一个文件描述符对应一个file结构体
static int
argfd(int n, int *pfd, struct file **pf)
{
8010566b:	55                   	push   %ebp
8010566c:	89 e5                	mov    %esp,%ebp
8010566e:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105671:	83 ec 08             	sub    $0x8,%esp
80105674:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105677:	50                   	push   %eax
80105678:	ff 75 08             	pushl  0x8(%ebp)
8010567b:	e8 a2 fe ff ff       	call   80105522 <argint>
80105680:	83 c4 10             	add    $0x10,%esp
80105683:	85 c0                	test   %eax,%eax
80105685:	79 07                	jns    8010568e <argfd+0x23>
    return -1;
80105687:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010568c:	eb 51                	jmp    801056df <argfd+0x74>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
8010568e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105691:	85 c0                	test   %eax,%eax
80105693:	78 22                	js     801056b7 <argfd+0x4c>
80105695:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105698:	83 f8 0f             	cmp    $0xf,%eax
8010569b:	7f 1a                	jg     801056b7 <argfd+0x4c>
8010569d:	e8 d7 eb ff ff       	call   80104279 <myproc>
801056a2:	89 c2                	mov    %eax,%edx
801056a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056a7:	83 c0 08             	add    $0x8,%eax
801056aa:	8b 44 82 08          	mov    0x8(%edx,%eax,4),%eax
801056ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
801056b1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801056b5:	75 07                	jne    801056be <argfd+0x53>
    return -1;
801056b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056bc:	eb 21                	jmp    801056df <argfd+0x74>
  if(pfd)
801056be:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801056c2:	74 08                	je     801056cc <argfd+0x61>
    *pfd = fd;
801056c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056c7:	8b 45 0c             	mov    0xc(%ebp),%eax
801056ca:	89 10                	mov    %edx,(%eax)
  if(pf)
801056cc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801056d0:	74 08                	je     801056da <argfd+0x6f>
    *pf = f;
801056d2:	8b 45 10             	mov    0x10(%ebp),%eax
801056d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056d8:	89 10                	mov    %edx,(%eax)
  return 0;
801056da:	b8 00 00 00 00       	mov    $0x0,%eax
}
801056df:	c9                   	leave  
801056e0:	c3                   	ret    

801056e1 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801056e1:	55                   	push   %ebp
801056e2:	89 e5                	mov    %esp,%ebp
801056e4:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct proc *curproc = myproc();
801056e7:	e8 8d eb ff ff       	call   80104279 <myproc>
801056ec:	89 45 f0             	mov    %eax,-0x10(%ebp)

  for(fd = 0; fd < NOFILE; fd++){
801056ef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801056f6:	eb 2a                	jmp    80105722 <fdalloc+0x41>
    if(curproc->ofile[fd] == 0){
801056f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056fb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056fe:	83 c2 08             	add    $0x8,%edx
80105701:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105705:	85 c0                	test   %eax,%eax
80105707:	75 15                	jne    8010571e <fdalloc+0x3d>
      curproc->ofile[fd] = f;
80105709:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010570c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010570f:	8d 4a 08             	lea    0x8(%edx),%ecx
80105712:	8b 55 08             	mov    0x8(%ebp),%edx
80105715:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105719:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010571c:	eb 0f                	jmp    8010572d <fdalloc+0x4c>
  for(fd = 0; fd < NOFILE; fd++){
8010571e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105722:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80105726:	7e d0                	jle    801056f8 <fdalloc+0x17>
    }
  }
  return -1;
80105728:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010572d:	c9                   	leave  
8010572e:	c3                   	ret    

8010572f <sys_dup>:

int
sys_dup(void)
{
8010572f:	55                   	push   %ebp
80105730:	89 e5                	mov    %esp,%ebp
80105732:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
80105735:	83 ec 04             	sub    $0x4,%esp
80105738:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010573b:	50                   	push   %eax
8010573c:	6a 00                	push   $0x0
8010573e:	6a 00                	push   $0x0
80105740:	e8 26 ff ff ff       	call   8010566b <argfd>
80105745:	83 c4 10             	add    $0x10,%esp
80105748:	85 c0                	test   %eax,%eax
8010574a:	79 07                	jns    80105753 <sys_dup+0x24>
    return -1;
8010574c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105751:	eb 31                	jmp    80105784 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105753:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105756:	83 ec 0c             	sub    $0xc,%esp
80105759:	50                   	push   %eax
8010575a:	e8 82 ff ff ff       	call   801056e1 <fdalloc>
8010575f:	83 c4 10             	add    $0x10,%esp
80105762:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105765:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105769:	79 07                	jns    80105772 <sys_dup+0x43>
    return -1;
8010576b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105770:	eb 12                	jmp    80105784 <sys_dup+0x55>
  filedup(f);
80105772:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105775:	83 ec 0c             	sub    $0xc,%esp
80105778:	50                   	push   %eax
80105779:	e8 e6 b8 ff ff       	call   80101064 <filedup>
8010577e:	83 c4 10             	add    $0x10,%esp
  return fd;
80105781:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105784:	c9                   	leave  
80105785:	c3                   	ret    

80105786 <sys_read>:



int
sys_read(void)
{
80105786:	55                   	push   %ebp
80105787:	89 e5                	mov    %esp,%ebp
80105789:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010578c:	83 ec 04             	sub    $0x4,%esp
8010578f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105792:	50                   	push   %eax
80105793:	6a 00                	push   $0x0
80105795:	6a 00                	push   $0x0
80105797:	e8 cf fe ff ff       	call   8010566b <argfd>
8010579c:	83 c4 10             	add    $0x10,%esp
8010579f:	85 c0                	test   %eax,%eax
801057a1:	78 2e                	js     801057d1 <sys_read+0x4b>
801057a3:	83 ec 08             	sub    $0x8,%esp
801057a6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801057a9:	50                   	push   %eax
801057aa:	6a 02                	push   $0x2
801057ac:	e8 71 fd ff ff       	call   80105522 <argint>
801057b1:	83 c4 10             	add    $0x10,%esp
801057b4:	85 c0                	test   %eax,%eax
801057b6:	78 19                	js     801057d1 <sys_read+0x4b>
801057b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057bb:	83 ec 04             	sub    $0x4,%esp
801057be:	50                   	push   %eax
801057bf:	8d 45 ec             	lea    -0x14(%ebp),%eax
801057c2:	50                   	push   %eax
801057c3:	6a 01                	push   $0x1
801057c5:	e8 85 fd ff ff       	call   8010554f <argptr>
801057ca:	83 c4 10             	add    $0x10,%esp
801057cd:	85 c0                	test   %eax,%eax
801057cf:	79 07                	jns    801057d8 <sys_read+0x52>
    return -1;
801057d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057d6:	eb 17                	jmp    801057ef <sys_read+0x69>
  return fileread(f, p, n);
801057d8:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801057db:	8b 55 ec             	mov    -0x14(%ebp),%edx
801057de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057e1:	83 ec 04             	sub    $0x4,%esp
801057e4:	51                   	push   %ecx
801057e5:	52                   	push   %edx
801057e6:	50                   	push   %eax
801057e7:	e8 08 ba ff ff       	call   801011f4 <fileread>
801057ec:	83 c4 10             	add    $0x10,%esp
}
801057ef:	c9                   	leave  
801057f0:	c3                   	ret    

801057f1 <sys_write>:

int
sys_write(void)
{
801057f1:	55                   	push   %ebp
801057f2:	89 e5                	mov    %esp,%ebp
801057f4:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801057f7:	83 ec 04             	sub    $0x4,%esp
801057fa:	8d 45 f4             	lea    -0xc(%ebp),%eax
801057fd:	50                   	push   %eax
801057fe:	6a 00                	push   $0x0
80105800:	6a 00                	push   $0x0
80105802:	e8 64 fe ff ff       	call   8010566b <argfd>
80105807:	83 c4 10             	add    $0x10,%esp
8010580a:	85 c0                	test   %eax,%eax
8010580c:	78 2e                	js     8010583c <sys_write+0x4b>
8010580e:	83 ec 08             	sub    $0x8,%esp
80105811:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105814:	50                   	push   %eax
80105815:	6a 02                	push   $0x2
80105817:	e8 06 fd ff ff       	call   80105522 <argint>
8010581c:	83 c4 10             	add    $0x10,%esp
8010581f:	85 c0                	test   %eax,%eax
80105821:	78 19                	js     8010583c <sys_write+0x4b>
80105823:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105826:	83 ec 04             	sub    $0x4,%esp
80105829:	50                   	push   %eax
8010582a:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010582d:	50                   	push   %eax
8010582e:	6a 01                	push   $0x1
80105830:	e8 1a fd ff ff       	call   8010554f <argptr>
80105835:	83 c4 10             	add    $0x10,%esp
80105838:	85 c0                	test   %eax,%eax
8010583a:	79 07                	jns    80105843 <sys_write+0x52>
    return -1;
8010583c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105841:	eb 17                	jmp    8010585a <sys_write+0x69>
  return filewrite(f, p, n);
80105843:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105846:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010584c:	83 ec 04             	sub    $0x4,%esp
8010584f:	51                   	push   %ecx
80105850:	52                   	push   %edx
80105851:	50                   	push   %eax
80105852:	e8 55 ba ff ff       	call   801012ac <filewrite>
80105857:	83 c4 10             	add    $0x10,%esp
}
8010585a:	c9                   	leave  
8010585b:	c3                   	ret    

8010585c <sys_close>:

int
sys_close(void)
{
8010585c:	55                   	push   %ebp
8010585d:	89 e5                	mov    %esp,%ebp
8010585f:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
80105862:	83 ec 04             	sub    $0x4,%esp
80105865:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105868:	50                   	push   %eax
80105869:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010586c:	50                   	push   %eax
8010586d:	6a 00                	push   $0x0
8010586f:	e8 f7 fd ff ff       	call   8010566b <argfd>
80105874:	83 c4 10             	add    $0x10,%esp
80105877:	85 c0                	test   %eax,%eax
80105879:	79 07                	jns    80105882 <sys_close+0x26>
    return -1;
8010587b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105880:	eb 29                	jmp    801058ab <sys_close+0x4f>
  myproc()->ofile[fd] = 0;
80105882:	e8 f2 e9 ff ff       	call   80104279 <myproc>
80105887:	89 c2                	mov    %eax,%edx
80105889:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010588c:	83 c0 08             	add    $0x8,%eax
8010588f:	c7 44 82 08 00 00 00 	movl   $0x0,0x8(%edx,%eax,4)
80105896:	00 
  fileclose(f);
80105897:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010589a:	83 ec 0c             	sub    $0xc,%esp
8010589d:	50                   	push   %eax
8010589e:	e8 12 b8 ff ff       	call   801010b5 <fileclose>
801058a3:	83 c4 10             	add    $0x10,%esp
  return 0;
801058a6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801058ab:	c9                   	leave  
801058ac:	c3                   	ret    

801058ad <sys_fstat>:

int
sys_fstat(void)
{
801058ad:	55                   	push   %ebp
801058ae:	89 e5                	mov    %esp,%ebp
801058b0:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  struct stat *st;

  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801058b3:	83 ec 04             	sub    $0x4,%esp
801058b6:	8d 45 f4             	lea    -0xc(%ebp),%eax
801058b9:	50                   	push   %eax
801058ba:	6a 00                	push   $0x0
801058bc:	6a 00                	push   $0x0
801058be:	e8 a8 fd ff ff       	call   8010566b <argfd>
801058c3:	83 c4 10             	add    $0x10,%esp
801058c6:	85 c0                	test   %eax,%eax
801058c8:	78 17                	js     801058e1 <sys_fstat+0x34>
801058ca:	83 ec 04             	sub    $0x4,%esp
801058cd:	6a 14                	push   $0x14
801058cf:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058d2:	50                   	push   %eax
801058d3:	6a 01                	push   $0x1
801058d5:	e8 75 fc ff ff       	call   8010554f <argptr>
801058da:	83 c4 10             	add    $0x10,%esp
801058dd:	85 c0                	test   %eax,%eax
801058df:	79 07                	jns    801058e8 <sys_fstat+0x3b>
    return -1;
801058e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058e6:	eb 13                	jmp    801058fb <sys_fstat+0x4e>
  return filestat(f, st);
801058e8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801058eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058ee:	83 ec 08             	sub    $0x8,%esp
801058f1:	52                   	push   %edx
801058f2:	50                   	push   %eax
801058f3:	e8 a5 b8 ff ff       	call   8010119d <filestat>
801058f8:	83 c4 10             	add    $0x10,%esp
}
801058fb:	c9                   	leave  
801058fc:	c3                   	ret    

801058fd <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801058fd:	55                   	push   %ebp
801058fe:	89 e5                	mov    %esp,%ebp
80105900:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105903:	83 ec 08             	sub    $0x8,%esp
80105906:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105909:	50                   	push   %eax
8010590a:	6a 00                	push   $0x0
8010590c:	e8 a6 fc ff ff       	call   801055b7 <argstr>
80105911:	83 c4 10             	add    $0x10,%esp
80105914:	85 c0                	test   %eax,%eax
80105916:	78 15                	js     8010592d <sys_link+0x30>
80105918:	83 ec 08             	sub    $0x8,%esp
8010591b:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010591e:	50                   	push   %eax
8010591f:	6a 01                	push   $0x1
80105921:	e8 91 fc ff ff       	call   801055b7 <argstr>
80105926:	83 c4 10             	add    $0x10,%esp
80105929:	85 c0                	test   %eax,%eax
8010592b:	79 0a                	jns    80105937 <sys_link+0x3a>
    return -1;
8010592d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105932:	e9 68 01 00 00       	jmp    80105a9f <sys_link+0x1a2>

  begin_op();
80105937:	e8 e7 db ff ff       	call   80103523 <begin_op>
  if((ip = namei(old)) == 0){
8010593c:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010593f:	83 ec 0c             	sub    $0xc,%esp
80105942:	50                   	push   %eax
80105943:	e8 f4 cb ff ff       	call   8010253c <namei>
80105948:	83 c4 10             	add    $0x10,%esp
8010594b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010594e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105952:	75 0f                	jne    80105963 <sys_link+0x66>
    end_op();
80105954:	e8 56 dc ff ff       	call   801035af <end_op>
    return -1;
80105959:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010595e:	e9 3c 01 00 00       	jmp    80105a9f <sys_link+0x1a2>
  }

  ilock(ip);
80105963:	83 ec 0c             	sub    $0xc,%esp
80105966:	ff 75 f4             	pushl  -0xc(%ebp)
80105969:	e8 93 c0 ff ff       	call   80101a01 <ilock>
8010596e:	83 c4 10             	add    $0x10,%esp
  if(ip->type == T_DIR){
80105971:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105974:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105978:	66 83 f8 01          	cmp    $0x1,%ax
8010597c:	75 1d                	jne    8010599b <sys_link+0x9e>
    iunlockput(ip);
8010597e:	83 ec 0c             	sub    $0xc,%esp
80105981:	ff 75 f4             	pushl  -0xc(%ebp)
80105984:	e8 a9 c2 ff ff       	call   80101c32 <iunlockput>
80105989:	83 c4 10             	add    $0x10,%esp
    end_op();
8010598c:	e8 1e dc ff ff       	call   801035af <end_op>
    return -1;
80105991:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105996:	e9 04 01 00 00       	jmp    80105a9f <sys_link+0x1a2>
  }

  ip->nlink++;
8010599b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010599e:	0f b7 40 56          	movzwl 0x56(%eax),%eax
801059a2:	83 c0 01             	add    $0x1,%eax
801059a5:	89 c2                	mov    %eax,%edx
801059a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059aa:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
801059ae:	83 ec 0c             	sub    $0xc,%esp
801059b1:	ff 75 f4             	pushl  -0xc(%ebp)
801059b4:	e8 6b be ff ff       	call   80101824 <iupdate>
801059b9:	83 c4 10             	add    $0x10,%esp
  iunlock(ip);
801059bc:	83 ec 0c             	sub    $0xc,%esp
801059bf:	ff 75 f4             	pushl  -0xc(%ebp)
801059c2:	e8 4d c1 ff ff       	call   80101b14 <iunlock>
801059c7:	83 c4 10             	add    $0x10,%esp

  if((dp = nameiparent(new, name)) == 0)
801059ca:	8b 45 dc             	mov    -0x24(%ebp),%eax
801059cd:	83 ec 08             	sub    $0x8,%esp
801059d0:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801059d3:	52                   	push   %edx
801059d4:	50                   	push   %eax
801059d5:	e8 7e cb ff ff       	call   80102558 <nameiparent>
801059da:	83 c4 10             	add    $0x10,%esp
801059dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
801059e0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801059e4:	74 71                	je     80105a57 <sys_link+0x15a>
    goto bad;
  ilock(dp);
801059e6:	83 ec 0c             	sub    $0xc,%esp
801059e9:	ff 75 f0             	pushl  -0x10(%ebp)
801059ec:	e8 10 c0 ff ff       	call   80101a01 <ilock>
801059f1:	83 c4 10             	add    $0x10,%esp
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801059f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059f7:	8b 10                	mov    (%eax),%edx
801059f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059fc:	8b 00                	mov    (%eax),%eax
801059fe:	39 c2                	cmp    %eax,%edx
80105a00:	75 1d                	jne    80105a1f <sys_link+0x122>
80105a02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a05:	8b 40 04             	mov    0x4(%eax),%eax
80105a08:	83 ec 04             	sub    $0x4,%esp
80105a0b:	50                   	push   %eax
80105a0c:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105a0f:	50                   	push   %eax
80105a10:	ff 75 f0             	pushl  -0x10(%ebp)
80105a13:	e8 89 c8 ff ff       	call   801022a1 <dirlink>
80105a18:	83 c4 10             	add    $0x10,%esp
80105a1b:	85 c0                	test   %eax,%eax
80105a1d:	79 10                	jns    80105a2f <sys_link+0x132>
    iunlockput(dp);
80105a1f:	83 ec 0c             	sub    $0xc,%esp
80105a22:	ff 75 f0             	pushl  -0x10(%ebp)
80105a25:	e8 08 c2 ff ff       	call   80101c32 <iunlockput>
80105a2a:	83 c4 10             	add    $0x10,%esp
    goto bad;
80105a2d:	eb 29                	jmp    80105a58 <sys_link+0x15b>
  }
  iunlockput(dp);
80105a2f:	83 ec 0c             	sub    $0xc,%esp
80105a32:	ff 75 f0             	pushl  -0x10(%ebp)
80105a35:	e8 f8 c1 ff ff       	call   80101c32 <iunlockput>
80105a3a:	83 c4 10             	add    $0x10,%esp
  iput(ip);
80105a3d:	83 ec 0c             	sub    $0xc,%esp
80105a40:	ff 75 f4             	pushl  -0xc(%ebp)
80105a43:	e8 1a c1 ff ff       	call   80101b62 <iput>
80105a48:	83 c4 10             	add    $0x10,%esp

  end_op();
80105a4b:	e8 5f db ff ff       	call   801035af <end_op>

  return 0;
80105a50:	b8 00 00 00 00       	mov    $0x0,%eax
80105a55:	eb 48                	jmp    80105a9f <sys_link+0x1a2>
    goto bad;
80105a57:	90                   	nop

bad:
  ilock(ip);
80105a58:	83 ec 0c             	sub    $0xc,%esp
80105a5b:	ff 75 f4             	pushl  -0xc(%ebp)
80105a5e:	e8 9e bf ff ff       	call   80101a01 <ilock>
80105a63:	83 c4 10             	add    $0x10,%esp
  ip->nlink--;
80105a66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a69:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105a6d:	83 e8 01             	sub    $0x1,%eax
80105a70:	89 c2                	mov    %eax,%edx
80105a72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a75:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105a79:	83 ec 0c             	sub    $0xc,%esp
80105a7c:	ff 75 f4             	pushl  -0xc(%ebp)
80105a7f:	e8 a0 bd ff ff       	call   80101824 <iupdate>
80105a84:	83 c4 10             	add    $0x10,%esp
  iunlockput(ip);
80105a87:	83 ec 0c             	sub    $0xc,%esp
80105a8a:	ff 75 f4             	pushl  -0xc(%ebp)
80105a8d:	e8 a0 c1 ff ff       	call   80101c32 <iunlockput>
80105a92:	83 c4 10             	add    $0x10,%esp
  end_op();
80105a95:	e8 15 db ff ff       	call   801035af <end_op>
  return -1;
80105a9a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a9f:	c9                   	leave  
80105aa0:	c3                   	ret    

80105aa1 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105aa1:	55                   	push   %ebp
80105aa2:	89 e5                	mov    %esp,%ebp
80105aa4:	83 ec 28             	sub    $0x28,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105aa7:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105aae:	eb 40                	jmp    80105af0 <isdirempty+0x4f>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105ab0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ab3:	6a 10                	push   $0x10
80105ab5:	50                   	push   %eax
80105ab6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105ab9:	50                   	push   %eax
80105aba:	ff 75 08             	pushl  0x8(%ebp)
80105abd:	e8 2b c4 ff ff       	call   80101eed <readi>
80105ac2:	83 c4 10             	add    $0x10,%esp
80105ac5:	83 f8 10             	cmp    $0x10,%eax
80105ac8:	74 0d                	je     80105ad7 <isdirempty+0x36>
      panic("isdirempty: readi");
80105aca:	83 ec 0c             	sub    $0xc,%esp
80105acd:	68 ec 87 10 80       	push   $0x801087ec
80105ad2:	e8 c5 aa ff ff       	call   8010059c <panic>
    if(de.inum != 0)
80105ad7:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105adb:	66 85 c0             	test   %ax,%ax
80105ade:	74 07                	je     80105ae7 <isdirempty+0x46>
      return 0;
80105ae0:	b8 00 00 00 00       	mov    $0x0,%eax
80105ae5:	eb 1b                	jmp    80105b02 <isdirempty+0x61>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aea:	83 c0 10             	add    $0x10,%eax
80105aed:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105af0:	8b 45 08             	mov    0x8(%ebp),%eax
80105af3:	8b 50 58             	mov    0x58(%eax),%edx
80105af6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105af9:	39 c2                	cmp    %eax,%edx
80105afb:	77 b3                	ja     80105ab0 <isdirempty+0xf>
  }
  return 1;
80105afd:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105b02:	c9                   	leave  
80105b03:	c3                   	ret    

80105b04 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105b04:	55                   	push   %ebp
80105b05:	89 e5                	mov    %esp,%ebp
80105b07:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105b0a:	83 ec 08             	sub    $0x8,%esp
80105b0d:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105b10:	50                   	push   %eax
80105b11:	6a 00                	push   $0x0
80105b13:	e8 9f fa ff ff       	call   801055b7 <argstr>
80105b18:	83 c4 10             	add    $0x10,%esp
80105b1b:	85 c0                	test   %eax,%eax
80105b1d:	79 0a                	jns    80105b29 <sys_unlink+0x25>
    return -1;
80105b1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b24:	e9 bf 01 00 00       	jmp    80105ce8 <sys_unlink+0x1e4>

  begin_op();
80105b29:	e8 f5 d9 ff ff       	call   80103523 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105b2e:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105b31:	83 ec 08             	sub    $0x8,%esp
80105b34:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105b37:	52                   	push   %edx
80105b38:	50                   	push   %eax
80105b39:	e8 1a ca ff ff       	call   80102558 <nameiparent>
80105b3e:	83 c4 10             	add    $0x10,%esp
80105b41:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b44:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105b48:	75 0f                	jne    80105b59 <sys_unlink+0x55>
    end_op();
80105b4a:	e8 60 da ff ff       	call   801035af <end_op>
    return -1;
80105b4f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b54:	e9 8f 01 00 00       	jmp    80105ce8 <sys_unlink+0x1e4>
  }

  ilock(dp);
80105b59:	83 ec 0c             	sub    $0xc,%esp
80105b5c:	ff 75 f4             	pushl  -0xc(%ebp)
80105b5f:	e8 9d be ff ff       	call   80101a01 <ilock>
80105b64:	83 c4 10             	add    $0x10,%esp

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105b67:	83 ec 08             	sub    $0x8,%esp
80105b6a:	68 fe 87 10 80       	push   $0x801087fe
80105b6f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b72:	50                   	push   %eax
80105b73:	e8 54 c6 ff ff       	call   801021cc <namecmp>
80105b78:	83 c4 10             	add    $0x10,%esp
80105b7b:	85 c0                	test   %eax,%eax
80105b7d:	0f 84 49 01 00 00    	je     80105ccc <sys_unlink+0x1c8>
80105b83:	83 ec 08             	sub    $0x8,%esp
80105b86:	68 00 88 10 80       	push   $0x80108800
80105b8b:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b8e:	50                   	push   %eax
80105b8f:	e8 38 c6 ff ff       	call   801021cc <namecmp>
80105b94:	83 c4 10             	add    $0x10,%esp
80105b97:	85 c0                	test   %eax,%eax
80105b99:	0f 84 2d 01 00 00    	je     80105ccc <sys_unlink+0x1c8>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105b9f:	83 ec 04             	sub    $0x4,%esp
80105ba2:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105ba5:	50                   	push   %eax
80105ba6:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105ba9:	50                   	push   %eax
80105baa:	ff 75 f4             	pushl  -0xc(%ebp)
80105bad:	e8 35 c6 ff ff       	call   801021e7 <dirlookup>
80105bb2:	83 c4 10             	add    $0x10,%esp
80105bb5:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105bb8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105bbc:	0f 84 0d 01 00 00    	je     80105ccf <sys_unlink+0x1cb>
    goto bad;
  ilock(ip);
80105bc2:	83 ec 0c             	sub    $0xc,%esp
80105bc5:	ff 75 f0             	pushl  -0x10(%ebp)
80105bc8:	e8 34 be ff ff       	call   80101a01 <ilock>
80105bcd:	83 c4 10             	add    $0x10,%esp

  if(ip->nlink < 1)
80105bd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bd3:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105bd7:	66 85 c0             	test   %ax,%ax
80105bda:	7f 0d                	jg     80105be9 <sys_unlink+0xe5>
    panic("unlink: nlink < 1");
80105bdc:	83 ec 0c             	sub    $0xc,%esp
80105bdf:	68 03 88 10 80       	push   $0x80108803
80105be4:	e8 b3 a9 ff ff       	call   8010059c <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105be9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bec:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105bf0:	66 83 f8 01          	cmp    $0x1,%ax
80105bf4:	75 25                	jne    80105c1b <sys_unlink+0x117>
80105bf6:	83 ec 0c             	sub    $0xc,%esp
80105bf9:	ff 75 f0             	pushl  -0x10(%ebp)
80105bfc:	e8 a0 fe ff ff       	call   80105aa1 <isdirempty>
80105c01:	83 c4 10             	add    $0x10,%esp
80105c04:	85 c0                	test   %eax,%eax
80105c06:	75 13                	jne    80105c1b <sys_unlink+0x117>
    iunlockput(ip);
80105c08:	83 ec 0c             	sub    $0xc,%esp
80105c0b:	ff 75 f0             	pushl  -0x10(%ebp)
80105c0e:	e8 1f c0 ff ff       	call   80101c32 <iunlockput>
80105c13:	83 c4 10             	add    $0x10,%esp
    goto bad;
80105c16:	e9 b5 00 00 00       	jmp    80105cd0 <sys_unlink+0x1cc>
  }

  memset(&de, 0, sizeof(de));
80105c1b:	83 ec 04             	sub    $0x4,%esp
80105c1e:	6a 10                	push   $0x10
80105c20:	6a 00                	push   $0x0
80105c22:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105c25:	50                   	push   %eax
80105c26:	e8 cb f5 ff ff       	call   801051f6 <memset>
80105c2b:	83 c4 10             	add    $0x10,%esp
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105c2e:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105c31:	6a 10                	push   $0x10
80105c33:	50                   	push   %eax
80105c34:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105c37:	50                   	push   %eax
80105c38:	ff 75 f4             	pushl  -0xc(%ebp)
80105c3b:	e8 04 c4 ff ff       	call   80102044 <writei>
80105c40:	83 c4 10             	add    $0x10,%esp
80105c43:	83 f8 10             	cmp    $0x10,%eax
80105c46:	74 0d                	je     80105c55 <sys_unlink+0x151>
    panic("unlink: writei");
80105c48:	83 ec 0c             	sub    $0xc,%esp
80105c4b:	68 15 88 10 80       	push   $0x80108815
80105c50:	e8 47 a9 ff ff       	call   8010059c <panic>
  if(ip->type == T_DIR){
80105c55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c58:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105c5c:	66 83 f8 01          	cmp    $0x1,%ax
80105c60:	75 21                	jne    80105c83 <sys_unlink+0x17f>
    dp->nlink--;
80105c62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c65:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105c69:	83 e8 01             	sub    $0x1,%eax
80105c6c:	89 c2                	mov    %eax,%edx
80105c6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c71:	66 89 50 56          	mov    %dx,0x56(%eax)
    iupdate(dp);
80105c75:	83 ec 0c             	sub    $0xc,%esp
80105c78:	ff 75 f4             	pushl  -0xc(%ebp)
80105c7b:	e8 a4 bb ff ff       	call   80101824 <iupdate>
80105c80:	83 c4 10             	add    $0x10,%esp
  }
  iunlockput(dp);
80105c83:	83 ec 0c             	sub    $0xc,%esp
80105c86:	ff 75 f4             	pushl  -0xc(%ebp)
80105c89:	e8 a4 bf ff ff       	call   80101c32 <iunlockput>
80105c8e:	83 c4 10             	add    $0x10,%esp

  ip->nlink--;
80105c91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c94:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105c98:	83 e8 01             	sub    $0x1,%eax
80105c9b:	89 c2                	mov    %eax,%edx
80105c9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ca0:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105ca4:	83 ec 0c             	sub    $0xc,%esp
80105ca7:	ff 75 f0             	pushl  -0x10(%ebp)
80105caa:	e8 75 bb ff ff       	call   80101824 <iupdate>
80105caf:	83 c4 10             	add    $0x10,%esp
  iunlockput(ip);
80105cb2:	83 ec 0c             	sub    $0xc,%esp
80105cb5:	ff 75 f0             	pushl  -0x10(%ebp)
80105cb8:	e8 75 bf ff ff       	call   80101c32 <iunlockput>
80105cbd:	83 c4 10             	add    $0x10,%esp

  end_op();
80105cc0:	e8 ea d8 ff ff       	call   801035af <end_op>

  return 0;
80105cc5:	b8 00 00 00 00       	mov    $0x0,%eax
80105cca:	eb 1c                	jmp    80105ce8 <sys_unlink+0x1e4>

bad:
80105ccc:	90                   	nop
80105ccd:	eb 01                	jmp    80105cd0 <sys_unlink+0x1cc>
    goto bad;
80105ccf:	90                   	nop
  iunlockput(dp);
80105cd0:	83 ec 0c             	sub    $0xc,%esp
80105cd3:	ff 75 f4             	pushl  -0xc(%ebp)
80105cd6:	e8 57 bf ff ff       	call   80101c32 <iunlockput>
80105cdb:	83 c4 10             	add    $0x10,%esp
  end_op();
80105cde:	e8 cc d8 ff ff       	call   801035af <end_op>
  return -1;
80105ce3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ce8:	c9                   	leave  
80105ce9:	c3                   	ret    

80105cea <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105cea:	55                   	push   %ebp
80105ceb:	89 e5                	mov    %esp,%ebp
80105ced:	83 ec 38             	sub    $0x38,%esp
80105cf0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105cf3:	8b 55 10             	mov    0x10(%ebp),%edx
80105cf6:	8b 45 14             	mov    0x14(%ebp),%eax
80105cf9:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105cfd:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105d01:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105d05:	83 ec 08             	sub    $0x8,%esp
80105d08:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105d0b:	50                   	push   %eax
80105d0c:	ff 75 08             	pushl  0x8(%ebp)
80105d0f:	e8 44 c8 ff ff       	call   80102558 <nameiparent>
80105d14:	83 c4 10             	add    $0x10,%esp
80105d17:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d1e:	75 0a                	jne    80105d2a <create+0x40>
    return 0;
80105d20:	b8 00 00 00 00       	mov    $0x0,%eax
80105d25:	e9 8e 01 00 00       	jmp    80105eb8 <create+0x1ce>
  ilock(dp);
80105d2a:	83 ec 0c             	sub    $0xc,%esp
80105d2d:	ff 75 f4             	pushl  -0xc(%ebp)
80105d30:	e8 cc bc ff ff       	call   80101a01 <ilock>
80105d35:	83 c4 10             	add    $0x10,%esp

  if((ip = dirlookup(dp, name, 0)) != 0){
80105d38:	83 ec 04             	sub    $0x4,%esp
80105d3b:	6a 00                	push   $0x0
80105d3d:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105d40:	50                   	push   %eax
80105d41:	ff 75 f4             	pushl  -0xc(%ebp)
80105d44:	e8 9e c4 ff ff       	call   801021e7 <dirlookup>
80105d49:	83 c4 10             	add    $0x10,%esp
80105d4c:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d4f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d53:	74 50                	je     80105da5 <create+0xbb>
    iunlockput(dp);
80105d55:	83 ec 0c             	sub    $0xc,%esp
80105d58:	ff 75 f4             	pushl  -0xc(%ebp)
80105d5b:	e8 d2 be ff ff       	call   80101c32 <iunlockput>
80105d60:	83 c4 10             	add    $0x10,%esp
    ilock(ip);
80105d63:	83 ec 0c             	sub    $0xc,%esp
80105d66:	ff 75 f0             	pushl  -0x10(%ebp)
80105d69:	e8 93 bc ff ff       	call   80101a01 <ilock>
80105d6e:	83 c4 10             	add    $0x10,%esp
    if(type == T_FILE && ip->type == T_FILE)
80105d71:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105d76:	75 15                	jne    80105d8d <create+0xa3>
80105d78:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d7b:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105d7f:	66 83 f8 02          	cmp    $0x2,%ax
80105d83:	75 08                	jne    80105d8d <create+0xa3>
      return ip;
80105d85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d88:	e9 2b 01 00 00       	jmp    80105eb8 <create+0x1ce>
    iunlockput(ip);
80105d8d:	83 ec 0c             	sub    $0xc,%esp
80105d90:	ff 75 f0             	pushl  -0x10(%ebp)
80105d93:	e8 9a be ff ff       	call   80101c32 <iunlockput>
80105d98:	83 c4 10             	add    $0x10,%esp
    return 0;
80105d9b:	b8 00 00 00 00       	mov    $0x0,%eax
80105da0:	e9 13 01 00 00       	jmp    80105eb8 <create+0x1ce>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105da5:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105da9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dac:	8b 00                	mov    (%eax),%eax
80105dae:	83 ec 08             	sub    $0x8,%esp
80105db1:	52                   	push   %edx
80105db2:	50                   	push   %eax
80105db3:	e8 95 b9 ff ff       	call   8010174d <ialloc>
80105db8:	83 c4 10             	add    $0x10,%esp
80105dbb:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105dbe:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105dc2:	75 0d                	jne    80105dd1 <create+0xe7>
    panic("create: ialloc");
80105dc4:	83 ec 0c             	sub    $0xc,%esp
80105dc7:	68 24 88 10 80       	push   $0x80108824
80105dcc:	e8 cb a7 ff ff       	call   8010059c <panic>

  ilock(ip);
80105dd1:	83 ec 0c             	sub    $0xc,%esp
80105dd4:	ff 75 f0             	pushl  -0x10(%ebp)
80105dd7:	e8 25 bc ff ff       	call   80101a01 <ilock>
80105ddc:	83 c4 10             	add    $0x10,%esp
  ip->major = major;
80105ddf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105de2:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105de6:	66 89 50 52          	mov    %dx,0x52(%eax)
  ip->minor = minor;
80105dea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ded:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105df1:	66 89 50 54          	mov    %dx,0x54(%eax)
  ip->nlink = 1;
80105df5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105df8:	66 c7 40 56 01 00    	movw   $0x1,0x56(%eax)
  iupdate(ip);
80105dfe:	83 ec 0c             	sub    $0xc,%esp
80105e01:	ff 75 f0             	pushl  -0x10(%ebp)
80105e04:	e8 1b ba ff ff       	call   80101824 <iupdate>
80105e09:	83 c4 10             	add    $0x10,%esp

  if(type == T_DIR){  // Create . and .. entries.
80105e0c:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105e11:	75 6a                	jne    80105e7d <create+0x193>
    dp->nlink++;  // for ".."
80105e13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e16:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105e1a:	83 c0 01             	add    $0x1,%eax
80105e1d:	89 c2                	mov    %eax,%edx
80105e1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e22:	66 89 50 56          	mov    %dx,0x56(%eax)
    iupdate(dp);
80105e26:	83 ec 0c             	sub    $0xc,%esp
80105e29:	ff 75 f4             	pushl  -0xc(%ebp)
80105e2c:	e8 f3 b9 ff ff       	call   80101824 <iupdate>
80105e31:	83 c4 10             	add    $0x10,%esp
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105e34:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e37:	8b 40 04             	mov    0x4(%eax),%eax
80105e3a:	83 ec 04             	sub    $0x4,%esp
80105e3d:	50                   	push   %eax
80105e3e:	68 fe 87 10 80       	push   $0x801087fe
80105e43:	ff 75 f0             	pushl  -0x10(%ebp)
80105e46:	e8 56 c4 ff ff       	call   801022a1 <dirlink>
80105e4b:	83 c4 10             	add    $0x10,%esp
80105e4e:	85 c0                	test   %eax,%eax
80105e50:	78 1e                	js     80105e70 <create+0x186>
80105e52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e55:	8b 40 04             	mov    0x4(%eax),%eax
80105e58:	83 ec 04             	sub    $0x4,%esp
80105e5b:	50                   	push   %eax
80105e5c:	68 00 88 10 80       	push   $0x80108800
80105e61:	ff 75 f0             	pushl  -0x10(%ebp)
80105e64:	e8 38 c4 ff ff       	call   801022a1 <dirlink>
80105e69:	83 c4 10             	add    $0x10,%esp
80105e6c:	85 c0                	test   %eax,%eax
80105e6e:	79 0d                	jns    80105e7d <create+0x193>
      panic("create dots");
80105e70:	83 ec 0c             	sub    $0xc,%esp
80105e73:	68 33 88 10 80       	push   $0x80108833
80105e78:	e8 1f a7 ff ff       	call   8010059c <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105e7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e80:	8b 40 04             	mov    0x4(%eax),%eax
80105e83:	83 ec 04             	sub    $0x4,%esp
80105e86:	50                   	push   %eax
80105e87:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105e8a:	50                   	push   %eax
80105e8b:	ff 75 f4             	pushl  -0xc(%ebp)
80105e8e:	e8 0e c4 ff ff       	call   801022a1 <dirlink>
80105e93:	83 c4 10             	add    $0x10,%esp
80105e96:	85 c0                	test   %eax,%eax
80105e98:	79 0d                	jns    80105ea7 <create+0x1bd>
    panic("create: dirlink");
80105e9a:	83 ec 0c             	sub    $0xc,%esp
80105e9d:	68 3f 88 10 80       	push   $0x8010883f
80105ea2:	e8 f5 a6 ff ff       	call   8010059c <panic>

  iunlockput(dp);
80105ea7:	83 ec 0c             	sub    $0xc,%esp
80105eaa:	ff 75 f4             	pushl  -0xc(%ebp)
80105ead:	e8 80 bd ff ff       	call   80101c32 <iunlockput>
80105eb2:	83 c4 10             	add    $0x10,%esp

  return ip;
80105eb5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105eb8:	c9                   	leave  
80105eb9:	c3                   	ret    

80105eba <sys_open>:

int
sys_open(void)
{
80105eba:	55                   	push   %ebp
80105ebb:	89 e5                	mov    %esp,%ebp
80105ebd:	83 ec 28             	sub    $0x28,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105ec0:	83 ec 08             	sub    $0x8,%esp
80105ec3:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105ec6:	50                   	push   %eax
80105ec7:	6a 00                	push   $0x0
80105ec9:	e8 e9 f6 ff ff       	call   801055b7 <argstr>
80105ece:	83 c4 10             	add    $0x10,%esp
80105ed1:	85 c0                	test   %eax,%eax
80105ed3:	78 15                	js     80105eea <sys_open+0x30>
80105ed5:	83 ec 08             	sub    $0x8,%esp
80105ed8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105edb:	50                   	push   %eax
80105edc:	6a 01                	push   $0x1
80105ede:	e8 3f f6 ff ff       	call   80105522 <argint>
80105ee3:	83 c4 10             	add    $0x10,%esp
80105ee6:	85 c0                	test   %eax,%eax
80105ee8:	79 0a                	jns    80105ef4 <sys_open+0x3a>
    return -1;
80105eea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eef:	e9 61 01 00 00       	jmp    80106055 <sys_open+0x19b>

  begin_op();
80105ef4:	e8 2a d6 ff ff       	call   80103523 <begin_op>

  if(omode & O_CREATE){
80105ef9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105efc:	25 00 02 00 00       	and    $0x200,%eax
80105f01:	85 c0                	test   %eax,%eax
80105f03:	74 2a                	je     80105f2f <sys_open+0x75>
    ip = create(path, T_FILE, 0, 0);
80105f05:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f08:	6a 00                	push   $0x0
80105f0a:	6a 00                	push   $0x0
80105f0c:	6a 02                	push   $0x2
80105f0e:	50                   	push   %eax
80105f0f:	e8 d6 fd ff ff       	call   80105cea <create>
80105f14:	83 c4 10             	add    $0x10,%esp
80105f17:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80105f1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f1e:	75 75                	jne    80105f95 <sys_open+0xdb>
      end_op();
80105f20:	e8 8a d6 ff ff       	call   801035af <end_op>
      return -1;
80105f25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f2a:	e9 26 01 00 00       	jmp    80106055 <sys_open+0x19b>
    }
  } else {
    if((ip = namei(path)) == 0){
80105f2f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f32:	83 ec 0c             	sub    $0xc,%esp
80105f35:	50                   	push   %eax
80105f36:	e8 01 c6 ff ff       	call   8010253c <namei>
80105f3b:	83 c4 10             	add    $0x10,%esp
80105f3e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f41:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f45:	75 0f                	jne    80105f56 <sys_open+0x9c>
      end_op();
80105f47:	e8 63 d6 ff ff       	call   801035af <end_op>
      return -1;
80105f4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f51:	e9 ff 00 00 00       	jmp    80106055 <sys_open+0x19b>
    }
    ilock(ip);
80105f56:	83 ec 0c             	sub    $0xc,%esp
80105f59:	ff 75 f4             	pushl  -0xc(%ebp)
80105f5c:	e8 a0 ba ff ff       	call   80101a01 <ilock>
80105f61:	83 c4 10             	add    $0x10,%esp
    if(ip->type == T_DIR && omode != O_RDONLY){
80105f64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f67:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105f6b:	66 83 f8 01          	cmp    $0x1,%ax
80105f6f:	75 24                	jne    80105f95 <sys_open+0xdb>
80105f71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f74:	85 c0                	test   %eax,%eax
80105f76:	74 1d                	je     80105f95 <sys_open+0xdb>
      iunlockput(ip);
80105f78:	83 ec 0c             	sub    $0xc,%esp
80105f7b:	ff 75 f4             	pushl  -0xc(%ebp)
80105f7e:	e8 af bc ff ff       	call   80101c32 <iunlockput>
80105f83:	83 c4 10             	add    $0x10,%esp
      end_op();
80105f86:	e8 24 d6 ff ff       	call   801035af <end_op>
      return -1;
80105f8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f90:	e9 c0 00 00 00       	jmp    80106055 <sys_open+0x19b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105f95:	e8 5d b0 ff ff       	call   80100ff7 <filealloc>
80105f9a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f9d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105fa1:	74 17                	je     80105fba <sys_open+0x100>
80105fa3:	83 ec 0c             	sub    $0xc,%esp
80105fa6:	ff 75 f0             	pushl  -0x10(%ebp)
80105fa9:	e8 33 f7 ff ff       	call   801056e1 <fdalloc>
80105fae:	83 c4 10             	add    $0x10,%esp
80105fb1:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105fb4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105fb8:	79 2e                	jns    80105fe8 <sys_open+0x12e>
    if(f)
80105fba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105fbe:	74 0e                	je     80105fce <sys_open+0x114>
      fileclose(f);
80105fc0:	83 ec 0c             	sub    $0xc,%esp
80105fc3:	ff 75 f0             	pushl  -0x10(%ebp)
80105fc6:	e8 ea b0 ff ff       	call   801010b5 <fileclose>
80105fcb:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80105fce:	83 ec 0c             	sub    $0xc,%esp
80105fd1:	ff 75 f4             	pushl  -0xc(%ebp)
80105fd4:	e8 59 bc ff ff       	call   80101c32 <iunlockput>
80105fd9:	83 c4 10             	add    $0x10,%esp
    end_op();
80105fdc:	e8 ce d5 ff ff       	call   801035af <end_op>
    return -1;
80105fe1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fe6:	eb 6d                	jmp    80106055 <sys_open+0x19b>
  }
  iunlock(ip);
80105fe8:	83 ec 0c             	sub    $0xc,%esp
80105feb:	ff 75 f4             	pushl  -0xc(%ebp)
80105fee:	e8 21 bb ff ff       	call   80101b14 <iunlock>
80105ff3:	83 c4 10             	add    $0x10,%esp
  end_op();
80105ff6:	e8 b4 d5 ff ff       	call   801035af <end_op>

  f->type = FD_INODE;
80105ffb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ffe:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106004:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106007:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010600a:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010600d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106010:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106017:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010601a:	83 e0 01             	and    $0x1,%eax
8010601d:	85 c0                	test   %eax,%eax
8010601f:	0f 94 c0             	sete   %al
80106022:	89 c2                	mov    %eax,%edx
80106024:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106027:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010602a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010602d:	83 e0 01             	and    $0x1,%eax
80106030:	85 c0                	test   %eax,%eax
80106032:	75 0a                	jne    8010603e <sys_open+0x184>
80106034:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106037:	83 e0 02             	and    $0x2,%eax
8010603a:	85 c0                	test   %eax,%eax
8010603c:	74 07                	je     80106045 <sys_open+0x18b>
8010603e:	b8 01 00 00 00       	mov    $0x1,%eax
80106043:	eb 05                	jmp    8010604a <sys_open+0x190>
80106045:	b8 00 00 00 00       	mov    $0x0,%eax
8010604a:	89 c2                	mov    %eax,%edx
8010604c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010604f:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106052:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106055:	c9                   	leave  
80106056:	c3                   	ret    

80106057 <sys_mkdir>:

int
sys_mkdir(void)
{
80106057:	55                   	push   %ebp
80106058:	89 e5                	mov    %esp,%ebp
8010605a:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010605d:	e8 c1 d4 ff ff       	call   80103523 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106062:	83 ec 08             	sub    $0x8,%esp
80106065:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106068:	50                   	push   %eax
80106069:	6a 00                	push   $0x0
8010606b:	e8 47 f5 ff ff       	call   801055b7 <argstr>
80106070:	83 c4 10             	add    $0x10,%esp
80106073:	85 c0                	test   %eax,%eax
80106075:	78 1b                	js     80106092 <sys_mkdir+0x3b>
80106077:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010607a:	6a 00                	push   $0x0
8010607c:	6a 00                	push   $0x0
8010607e:	6a 01                	push   $0x1
80106080:	50                   	push   %eax
80106081:	e8 64 fc ff ff       	call   80105cea <create>
80106086:	83 c4 10             	add    $0x10,%esp
80106089:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010608c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106090:	75 0c                	jne    8010609e <sys_mkdir+0x47>
    end_op();
80106092:	e8 18 d5 ff ff       	call   801035af <end_op>
    return -1;
80106097:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010609c:	eb 18                	jmp    801060b6 <sys_mkdir+0x5f>
  }
  iunlockput(ip);
8010609e:	83 ec 0c             	sub    $0xc,%esp
801060a1:	ff 75 f4             	pushl  -0xc(%ebp)
801060a4:	e8 89 bb ff ff       	call   80101c32 <iunlockput>
801060a9:	83 c4 10             	add    $0x10,%esp
  end_op();
801060ac:	e8 fe d4 ff ff       	call   801035af <end_op>
  return 0;
801060b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060b6:	c9                   	leave  
801060b7:	c3                   	ret    

801060b8 <sys_mknod>:

int
sys_mknod(void)
{
801060b8:	55                   	push   %ebp
801060b9:	89 e5                	mov    %esp,%ebp
801060bb:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
801060be:	e8 60 d4 ff ff       	call   80103523 <begin_op>
  if((argstr(0, &path)) < 0 ||
801060c3:	83 ec 08             	sub    $0x8,%esp
801060c6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060c9:	50                   	push   %eax
801060ca:	6a 00                	push   $0x0
801060cc:	e8 e6 f4 ff ff       	call   801055b7 <argstr>
801060d1:	83 c4 10             	add    $0x10,%esp
801060d4:	85 c0                	test   %eax,%eax
801060d6:	78 4f                	js     80106127 <sys_mknod+0x6f>
     argint(1, &major) < 0 ||
801060d8:	83 ec 08             	sub    $0x8,%esp
801060db:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060de:	50                   	push   %eax
801060df:	6a 01                	push   $0x1
801060e1:	e8 3c f4 ff ff       	call   80105522 <argint>
801060e6:	83 c4 10             	add    $0x10,%esp
  if((argstr(0, &path)) < 0 ||
801060e9:	85 c0                	test   %eax,%eax
801060eb:	78 3a                	js     80106127 <sys_mknod+0x6f>
     argint(2, &minor) < 0 ||
801060ed:	83 ec 08             	sub    $0x8,%esp
801060f0:	8d 45 e8             	lea    -0x18(%ebp),%eax
801060f3:	50                   	push   %eax
801060f4:	6a 02                	push   $0x2
801060f6:	e8 27 f4 ff ff       	call   80105522 <argint>
801060fb:	83 c4 10             	add    $0x10,%esp
     argint(1, &major) < 0 ||
801060fe:	85 c0                	test   %eax,%eax
80106100:	78 25                	js     80106127 <sys_mknod+0x6f>
     (ip = create(path, T_DEV, major, minor)) == 0){
80106102:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106105:	0f bf c8             	movswl %ax,%ecx
80106108:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010610b:	0f bf d0             	movswl %ax,%edx
8010610e:	8b 45 f0             	mov    -0x10(%ebp),%eax
     argint(2, &minor) < 0 ||
80106111:	51                   	push   %ecx
80106112:	52                   	push   %edx
80106113:	6a 03                	push   $0x3
80106115:	50                   	push   %eax
80106116:	e8 cf fb ff ff       	call   80105cea <create>
8010611b:	83 c4 10             	add    $0x10,%esp
8010611e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106121:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106125:	75 0c                	jne    80106133 <sys_mknod+0x7b>
    end_op();
80106127:	e8 83 d4 ff ff       	call   801035af <end_op>
    return -1;
8010612c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106131:	eb 18                	jmp    8010614b <sys_mknod+0x93>
  }
  iunlockput(ip);
80106133:	83 ec 0c             	sub    $0xc,%esp
80106136:	ff 75 f4             	pushl  -0xc(%ebp)
80106139:	e8 f4 ba ff ff       	call   80101c32 <iunlockput>
8010613e:	83 c4 10             	add    $0x10,%esp
  end_op();
80106141:	e8 69 d4 ff ff       	call   801035af <end_op>
  return 0;
80106146:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010614b:	c9                   	leave  
8010614c:	c3                   	ret    

8010614d <sys_chdir>:

int
sys_chdir(void)
{
8010614d:	55                   	push   %ebp
8010614e:	89 e5                	mov    %esp,%ebp
80106150:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80106153:	e8 21 e1 ff ff       	call   80104279 <myproc>
80106158:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  begin_op();
8010615b:	e8 c3 d3 ff ff       	call   80103523 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106160:	83 ec 08             	sub    $0x8,%esp
80106163:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106166:	50                   	push   %eax
80106167:	6a 00                	push   $0x0
80106169:	e8 49 f4 ff ff       	call   801055b7 <argstr>
8010616e:	83 c4 10             	add    $0x10,%esp
80106171:	85 c0                	test   %eax,%eax
80106173:	78 18                	js     8010618d <sys_chdir+0x40>
80106175:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106178:	83 ec 0c             	sub    $0xc,%esp
8010617b:	50                   	push   %eax
8010617c:	e8 bb c3 ff ff       	call   8010253c <namei>
80106181:	83 c4 10             	add    $0x10,%esp
80106184:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106187:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010618b:	75 0c                	jne    80106199 <sys_chdir+0x4c>
    end_op();
8010618d:	e8 1d d4 ff ff       	call   801035af <end_op>
    return -1;
80106192:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106197:	eb 68                	jmp    80106201 <sys_chdir+0xb4>
  }
  ilock(ip);
80106199:	83 ec 0c             	sub    $0xc,%esp
8010619c:	ff 75 f0             	pushl  -0x10(%ebp)
8010619f:	e8 5d b8 ff ff       	call   80101a01 <ilock>
801061a4:	83 c4 10             	add    $0x10,%esp
  if(ip->type != T_DIR){
801061a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061aa:	0f b7 40 50          	movzwl 0x50(%eax),%eax
801061ae:	66 83 f8 01          	cmp    $0x1,%ax
801061b2:	74 1a                	je     801061ce <sys_chdir+0x81>
    iunlockput(ip);
801061b4:	83 ec 0c             	sub    $0xc,%esp
801061b7:	ff 75 f0             	pushl  -0x10(%ebp)
801061ba:	e8 73 ba ff ff       	call   80101c32 <iunlockput>
801061bf:	83 c4 10             	add    $0x10,%esp
    end_op();
801061c2:	e8 e8 d3 ff ff       	call   801035af <end_op>
    return -1;
801061c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061cc:	eb 33                	jmp    80106201 <sys_chdir+0xb4>
  }
  iunlock(ip);
801061ce:	83 ec 0c             	sub    $0xc,%esp
801061d1:	ff 75 f0             	pushl  -0x10(%ebp)
801061d4:	e8 3b b9 ff ff       	call   80101b14 <iunlock>
801061d9:	83 c4 10             	add    $0x10,%esp
  iput(curproc->cwd);
801061dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061df:	8b 40 68             	mov    0x68(%eax),%eax
801061e2:	83 ec 0c             	sub    $0xc,%esp
801061e5:	50                   	push   %eax
801061e6:	e8 77 b9 ff ff       	call   80101b62 <iput>
801061eb:	83 c4 10             	add    $0x10,%esp
  end_op();
801061ee:	e8 bc d3 ff ff       	call   801035af <end_op>
  curproc->cwd = ip;
801061f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061f6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801061f9:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801061fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106201:	c9                   	leave  
80106202:	c3                   	ret    

80106203 <sys_exec>:

int
sys_exec(void)
{
80106203:	55                   	push   %ebp
80106204:	89 e5                	mov    %esp,%ebp
80106206:	81 ec 98 00 00 00    	sub    $0x98,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
8010620c:	83 ec 08             	sub    $0x8,%esp
8010620f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106212:	50                   	push   %eax
80106213:	6a 00                	push   $0x0
80106215:	e8 9d f3 ff ff       	call   801055b7 <argstr>
8010621a:	83 c4 10             	add    $0x10,%esp
8010621d:	85 c0                	test   %eax,%eax
8010621f:	78 18                	js     80106239 <sys_exec+0x36>
80106221:	83 ec 08             	sub    $0x8,%esp
80106224:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
8010622a:	50                   	push   %eax
8010622b:	6a 01                	push   $0x1
8010622d:	e8 f0 f2 ff ff       	call   80105522 <argint>
80106232:	83 c4 10             	add    $0x10,%esp
80106235:	85 c0                	test   %eax,%eax
80106237:	79 0a                	jns    80106243 <sys_exec+0x40>
    return -1;
80106239:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010623e:	e9 c6 00 00 00       	jmp    80106309 <sys_exec+0x106>
  }
  memset(argv, 0, sizeof(argv));
80106243:	83 ec 04             	sub    $0x4,%esp
80106246:	68 80 00 00 00       	push   $0x80
8010624b:	6a 00                	push   $0x0
8010624d:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106253:	50                   	push   %eax
80106254:	e8 9d ef ff ff       	call   801051f6 <memset>
80106259:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
8010625c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106263:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106266:	83 f8 1f             	cmp    $0x1f,%eax
80106269:	76 0a                	jbe    80106275 <sys_exec+0x72>
      return -1;
8010626b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106270:	e9 94 00 00 00       	jmp    80106309 <sys_exec+0x106>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106275:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106278:	c1 e0 02             	shl    $0x2,%eax
8010627b:	89 c2                	mov    %eax,%edx
8010627d:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106283:	01 c2                	add    %eax,%edx
80106285:	83 ec 08             	sub    $0x8,%esp
80106288:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
8010628e:	50                   	push   %eax
8010628f:	52                   	push   %edx
80106290:	e8 ea f1 ff ff       	call   8010547f <fetchint>
80106295:	83 c4 10             	add    $0x10,%esp
80106298:	85 c0                	test   %eax,%eax
8010629a:	79 07                	jns    801062a3 <sys_exec+0xa0>
      return -1;
8010629c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062a1:	eb 66                	jmp    80106309 <sys_exec+0x106>
    if(uarg == 0){
801062a3:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801062a9:	85 c0                	test   %eax,%eax
801062ab:	75 27                	jne    801062d4 <sys_exec+0xd1>
      argv[i] = 0;
801062ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062b0:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801062b7:	00 00 00 00 
      break;
801062bb:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801062bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062bf:	83 ec 08             	sub    $0x8,%esp
801062c2:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801062c8:	52                   	push   %edx
801062c9:	50                   	push   %eax
801062ca:	e8 cb a8 ff ff       	call   80100b9a <exec>
801062cf:	83 c4 10             	add    $0x10,%esp
801062d2:	eb 35                	jmp    80106309 <sys_exec+0x106>
    if(fetchstr(uarg, &argv[i]) < 0)
801062d4:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801062da:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062dd:	c1 e2 02             	shl    $0x2,%edx
801062e0:	01 c2                	add    %eax,%edx
801062e2:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801062e8:	83 ec 08             	sub    $0x8,%esp
801062eb:	52                   	push   %edx
801062ec:	50                   	push   %eax
801062ed:	e8 cc f1 ff ff       	call   801054be <fetchstr>
801062f2:	83 c4 10             	add    $0x10,%esp
801062f5:	85 c0                	test   %eax,%eax
801062f7:	79 07                	jns    80106300 <sys_exec+0xfd>
      return -1;
801062f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062fe:	eb 09                	jmp    80106309 <sys_exec+0x106>
  for(i=0;; i++){
80106300:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(i >= NELEM(argv))
80106304:	e9 5a ff ff ff       	jmp    80106263 <sys_exec+0x60>
}
80106309:	c9                   	leave  
8010630a:	c3                   	ret    

8010630b <sys_pipe>:

int
sys_pipe(void)
{
8010630b:	55                   	push   %ebp
8010630c:	89 e5                	mov    %esp,%ebp
8010630e:	83 ec 28             	sub    $0x28,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106311:	83 ec 04             	sub    $0x4,%esp
80106314:	6a 08                	push   $0x8
80106316:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106319:	50                   	push   %eax
8010631a:	6a 00                	push   $0x0
8010631c:	e8 2e f2 ff ff       	call   8010554f <argptr>
80106321:	83 c4 10             	add    $0x10,%esp
80106324:	85 c0                	test   %eax,%eax
80106326:	79 0a                	jns    80106332 <sys_pipe+0x27>
    return -1;
80106328:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010632d:	e9 b0 00 00 00       	jmp    801063e2 <sys_pipe+0xd7>
  if(pipealloc(&rf, &wf) < 0)
80106332:	83 ec 08             	sub    $0x8,%esp
80106335:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106338:	50                   	push   %eax
80106339:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010633c:	50                   	push   %eax
8010633d:	e8 6b da ff ff       	call   80103dad <pipealloc>
80106342:	83 c4 10             	add    $0x10,%esp
80106345:	85 c0                	test   %eax,%eax
80106347:	79 0a                	jns    80106353 <sys_pipe+0x48>
    return -1;
80106349:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010634e:	e9 8f 00 00 00       	jmp    801063e2 <sys_pipe+0xd7>
  fd0 = -1;
80106353:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
8010635a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010635d:	83 ec 0c             	sub    $0xc,%esp
80106360:	50                   	push   %eax
80106361:	e8 7b f3 ff ff       	call   801056e1 <fdalloc>
80106366:	83 c4 10             	add    $0x10,%esp
80106369:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010636c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106370:	78 18                	js     8010638a <sys_pipe+0x7f>
80106372:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106375:	83 ec 0c             	sub    $0xc,%esp
80106378:	50                   	push   %eax
80106379:	e8 63 f3 ff ff       	call   801056e1 <fdalloc>
8010637e:	83 c4 10             	add    $0x10,%esp
80106381:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106384:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106388:	79 40                	jns    801063ca <sys_pipe+0xbf>
    if(fd0 >= 0)
8010638a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010638e:	78 15                	js     801063a5 <sys_pipe+0x9a>
      myproc()->ofile[fd0] = 0;
80106390:	e8 e4 de ff ff       	call   80104279 <myproc>
80106395:	89 c2                	mov    %eax,%edx
80106397:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010639a:	83 c0 08             	add    $0x8,%eax
8010639d:	c7 44 82 08 00 00 00 	movl   $0x0,0x8(%edx,%eax,4)
801063a4:	00 
    fileclose(rf);
801063a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801063a8:	83 ec 0c             	sub    $0xc,%esp
801063ab:	50                   	push   %eax
801063ac:	e8 04 ad ff ff       	call   801010b5 <fileclose>
801063b1:	83 c4 10             	add    $0x10,%esp
    fileclose(wf);
801063b4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063b7:	83 ec 0c             	sub    $0xc,%esp
801063ba:	50                   	push   %eax
801063bb:	e8 f5 ac ff ff       	call   801010b5 <fileclose>
801063c0:	83 c4 10             	add    $0x10,%esp
    return -1;
801063c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063c8:	eb 18                	jmp    801063e2 <sys_pipe+0xd7>
  }
  fd[0] = fd0;
801063ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063d0:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801063d2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063d5:	8d 50 04             	lea    0x4(%eax),%edx
801063d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063db:	89 02                	mov    %eax,(%edx)
  return 0;
801063dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063e2:	c9                   	leave  
801063e3:	c3                   	ret    

801063e4 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801063e4:	55                   	push   %ebp
801063e5:	89 e5                	mov    %esp,%ebp
801063e7:	83 ec 08             	sub    $0x8,%esp
  return fork();
801063ea:	e8 8f e1 ff ff       	call   8010457e <fork>
}
801063ef:	c9                   	leave  
801063f0:	c3                   	ret    

801063f1 <sys_exit>:

int
sys_exit(void)
{
801063f1:	55                   	push   %ebp
801063f2:	89 e5                	mov    %esp,%ebp
801063f4:	83 ec 08             	sub    $0x8,%esp
  exit();
801063f7:	e8 01 e3 ff ff       	call   801046fd <exit>
  return 0;  // not reached
801063fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106401:	c9                   	leave  
80106402:	c3                   	ret    

80106403 <sys_wait>:

int
sys_wait(void)
{
80106403:	55                   	push   %ebp
80106404:	89 e5                	mov    %esp,%ebp
80106406:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106409:	e8 0f e4 ff ff       	call   8010481d <wait>
}
8010640e:	c9                   	leave  
8010640f:	c3                   	ret    

80106410 <sys_kill>:

int
sys_kill(void)
{
80106410:	55                   	push   %ebp
80106411:	89 e5                	mov    %esp,%ebp
80106413:	83 ec 18             	sub    $0x18,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106416:	83 ec 08             	sub    $0x8,%esp
80106419:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010641c:	50                   	push   %eax
8010641d:	6a 00                	push   $0x0
8010641f:	e8 fe f0 ff ff       	call   80105522 <argint>
80106424:	83 c4 10             	add    $0x10,%esp
80106427:	85 c0                	test   %eax,%eax
80106429:	79 07                	jns    80106432 <sys_kill+0x22>
    return -1;
8010642b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106430:	eb 0f                	jmp    80106441 <sys_kill+0x31>
  return kill(pid);
80106432:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106435:	83 ec 0c             	sub    $0xc,%esp
80106438:	50                   	push   %eax
80106439:	e8 0f e8 ff ff       	call   80104c4d <kill>
8010643e:	83 c4 10             	add    $0x10,%esp
}
80106441:	c9                   	leave  
80106442:	c3                   	ret    

80106443 <sys_getpid>:

int
sys_getpid(void)
{
80106443:	55                   	push   %ebp
80106444:	89 e5                	mov    %esp,%ebp
80106446:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80106449:	e8 2b de ff ff       	call   80104279 <myproc>
8010644e:	8b 40 10             	mov    0x10(%eax),%eax
}
80106451:	c9                   	leave  
80106452:	c3                   	ret    

80106453 <sys_sbrk>:

int
sys_sbrk(void)
{
80106453:	55                   	push   %ebp
80106454:	89 e5                	mov    %esp,%ebp
80106456:	83 ec 18             	sub    $0x18,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106459:	83 ec 08             	sub    $0x8,%esp
8010645c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010645f:	50                   	push   %eax
80106460:	6a 00                	push   $0x0
80106462:	e8 bb f0 ff ff       	call   80105522 <argint>
80106467:	83 c4 10             	add    $0x10,%esp
8010646a:	85 c0                	test   %eax,%eax
8010646c:	79 07                	jns    80106475 <sys_sbrk+0x22>
    return -1;
8010646e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106473:	eb 27                	jmp    8010649c <sys_sbrk+0x49>
  addr = myproc()->sz;
80106475:	e8 ff dd ff ff       	call   80104279 <myproc>
8010647a:	8b 00                	mov    (%eax),%eax
8010647c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010647f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106482:	83 ec 0c             	sub    $0xc,%esp
80106485:	50                   	push   %eax
80106486:	e8 58 e0 ff ff       	call   801044e3 <growproc>
8010648b:	83 c4 10             	add    $0x10,%esp
8010648e:	85 c0                	test   %eax,%eax
80106490:	79 07                	jns    80106499 <sys_sbrk+0x46>
    return -1;
80106492:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106497:	eb 03                	jmp    8010649c <sys_sbrk+0x49>
  return addr;
80106499:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010649c:	c9                   	leave  
8010649d:	c3                   	ret    

8010649e <sys_sleep>:

int
sys_sleep(void)
{
8010649e:	55                   	push   %ebp
8010649f:	89 e5                	mov    %esp,%ebp
801064a1:	83 ec 18             	sub    $0x18,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
801064a4:	83 ec 08             	sub    $0x8,%esp
801064a7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064aa:	50                   	push   %eax
801064ab:	6a 00                	push   $0x0
801064ad:	e8 70 f0 ff ff       	call   80105522 <argint>
801064b2:	83 c4 10             	add    $0x10,%esp
801064b5:	85 c0                	test   %eax,%eax
801064b7:	79 07                	jns    801064c0 <sys_sleep+0x22>
    return -1;
801064b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064be:	eb 76                	jmp    80106536 <sys_sleep+0x98>
  acquire(&tickslock);
801064c0:	83 ec 0c             	sub    $0xc,%esp
801064c3:	68 e0 5c 11 80       	push   $0x80115ce0
801064c8:	e8 a2 ea ff ff       	call   80104f6f <acquire>
801064cd:	83 c4 10             	add    $0x10,%esp
  ticks0 = ticks;
801064d0:	a1 20 65 11 80       	mov    0x80116520,%eax
801064d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801064d8:	eb 38                	jmp    80106512 <sys_sleep+0x74>
    if(myproc()->killed){
801064da:	e8 9a dd ff ff       	call   80104279 <myproc>
801064df:	8b 40 24             	mov    0x24(%eax),%eax
801064e2:	85 c0                	test   %eax,%eax
801064e4:	74 17                	je     801064fd <sys_sleep+0x5f>
      release(&tickslock);
801064e6:	83 ec 0c             	sub    $0xc,%esp
801064e9:	68 e0 5c 11 80       	push   $0x80115ce0
801064ee:	e8 ea ea ff ff       	call   80104fdd <release>
801064f3:	83 c4 10             	add    $0x10,%esp
      return -1;
801064f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064fb:	eb 39                	jmp    80106536 <sys_sleep+0x98>
    }
    sleep(&ticks, &tickslock);
801064fd:	83 ec 08             	sub    $0x8,%esp
80106500:	68 e0 5c 11 80       	push   $0x80115ce0
80106505:	68 20 65 11 80       	push   $0x80116520
8010650a:	e8 21 e6 ff ff       	call   80104b30 <sleep>
8010650f:	83 c4 10             	add    $0x10,%esp
  while(ticks - ticks0 < n){
80106512:	a1 20 65 11 80       	mov    0x80116520,%eax
80106517:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010651a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010651d:	39 d0                	cmp    %edx,%eax
8010651f:	72 b9                	jb     801064da <sys_sleep+0x3c>
  }
  release(&tickslock);
80106521:	83 ec 0c             	sub    $0xc,%esp
80106524:	68 e0 5c 11 80       	push   $0x80115ce0
80106529:	e8 af ea ff ff       	call   80104fdd <release>
8010652e:	83 c4 10             	add    $0x10,%esp
  return 0;
80106531:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106536:	c9                   	leave  
80106537:	c3                   	ret    

80106538 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106538:	55                   	push   %ebp
80106539:	89 e5                	mov    %esp,%ebp
8010653b:	83 ec 18             	sub    $0x18,%esp
  uint xticks;

  acquire(&tickslock);
8010653e:	83 ec 0c             	sub    $0xc,%esp
80106541:	68 e0 5c 11 80       	push   $0x80115ce0
80106546:	e8 24 ea ff ff       	call   80104f6f <acquire>
8010654b:	83 c4 10             	add    $0x10,%esp
  xticks = ticks;
8010654e:	a1 20 65 11 80       	mov    0x80116520,%eax
80106553:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106556:	83 ec 0c             	sub    $0xc,%esp
80106559:	68 e0 5c 11 80       	push   $0x80115ce0
8010655e:	e8 7a ea ff ff       	call   80104fdd <release>
80106563:	83 c4 10             	add    $0x10,%esp
  return xticks;
80106566:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106569:	c9                   	leave  
8010656a:	c3                   	ret    

8010656b <sys_date>:


int 
sys_date(void)
{
8010656b:	55                   	push   %ebp
8010656c:	89 e5                	mov    %esp,%ebp
8010656e:	83 ec 18             	sub    $0x18,%esp
  struct rtcdate* r;
  if(argptr(0,(void *)&r,sizeof(*r)))
80106571:	83 ec 04             	sub    $0x4,%esp
80106574:	6a 18                	push   $0x18
80106576:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106579:	50                   	push   %eax
8010657a:	6a 00                	push   $0x0
8010657c:	e8 ce ef ff ff       	call   8010554f <argptr>
80106581:	83 c4 10             	add    $0x10,%esp
80106584:	85 c0                	test   %eax,%eax
80106586:	74 07                	je     8010658f <sys_date+0x24>
    return -1;
80106588:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010658d:	eb 14                	jmp    801065a3 <sys_date+0x38>

  cmostime(r);    //从cmos中获取时间
8010658f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106592:	83 ec 0c             	sub    $0xc,%esp
80106595:	50                   	push   %eax
80106596:	e8 03 cc ff ff       	call   8010319e <cmostime>
8010659b:	83 c4 10             	add    $0x10,%esp
  return 0;
8010659e:	b8 00 00 00 00       	mov    $0x0,%eax
801065a3:	c9                   	leave  
801065a4:	c3                   	ret    

801065a5 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801065a5:	1e                   	push   %ds
  pushl %es
801065a6:	06                   	push   %es
  pushl %fs
801065a7:	0f a0                	push   %fs
  pushl %gs
801065a9:	0f a8                	push   %gs
  pushal
801065ab:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
801065ac:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801065b0:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801065b2:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
801065b4:	54                   	push   %esp
  call trap
801065b5:	e8 d7 01 00 00       	call   80106791 <trap>
  addl $4, %esp
801065ba:	83 c4 04             	add    $0x4,%esp

801065bd <trapret>:
GS: Extra data #3
*/
  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801065bd:	61                   	popa   
  popl %gs
801065be:	0f a9                	pop    %gs
  popl %fs
801065c0:	0f a1                	pop    %fs
  popl %es
801065c2:	07                   	pop    %es
  popl %ds
801065c3:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801065c4:	83 c4 08             	add    $0x8,%esp
  iret
801065c7:	cf                   	iret   

801065c8 <lidt>:
{
801065c8:	55                   	push   %ebp
801065c9:	89 e5                	mov    %esp,%ebp
801065cb:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
801065ce:	8b 45 0c             	mov    0xc(%ebp),%eax
801065d1:	83 e8 01             	sub    $0x1,%eax
801065d4:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801065d8:	8b 45 08             	mov    0x8(%ebp),%eax
801065db:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801065df:	8b 45 08             	mov    0x8(%ebp),%eax
801065e2:	c1 e8 10             	shr    $0x10,%eax
801065e5:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
801065e9:	8d 45 fa             	lea    -0x6(%ebp),%eax
801065ec:	0f 01 18             	lidtl  (%eax)
}
801065ef:	90                   	nop
801065f0:	c9                   	leave  
801065f1:	c3                   	ret    

801065f2 <rcr2>:

static inline uint
rcr2(void)
{
801065f2:	55                   	push   %ebp
801065f3:	89 e5                	mov    %esp,%ebp
801065f5:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801065f8:	0f 20 d0             	mov    %cr2,%eax
801065fb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
801065fe:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106601:	c9                   	leave  
80106602:	c3                   	ret    

80106603 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106603:	55                   	push   %ebp
80106604:	89 e5                	mov    %esp,%ebp
80106606:	83 ec 18             	sub    $0x18,%esp
  int i;

  for(i = 0; i < 256; i++)
80106609:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106610:	e9 c3 00 00 00       	jmp    801066d8 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106615:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106618:	8b 04 85 7c b0 10 80 	mov    -0x7fef4f84(,%eax,4),%eax
8010661f:	89 c2                	mov    %eax,%edx
80106621:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106624:	66 89 14 c5 20 5d 11 	mov    %dx,-0x7feea2e0(,%eax,8)
8010662b:	80 
8010662c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010662f:	66 c7 04 c5 22 5d 11 	movw   $0x8,-0x7feea2de(,%eax,8)
80106636:	80 08 00 
80106639:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010663c:	0f b6 14 c5 24 5d 11 	movzbl -0x7feea2dc(,%eax,8),%edx
80106643:	80 
80106644:	83 e2 e0             	and    $0xffffffe0,%edx
80106647:	88 14 c5 24 5d 11 80 	mov    %dl,-0x7feea2dc(,%eax,8)
8010664e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106651:	0f b6 14 c5 24 5d 11 	movzbl -0x7feea2dc(,%eax,8),%edx
80106658:	80 
80106659:	83 e2 1f             	and    $0x1f,%edx
8010665c:	88 14 c5 24 5d 11 80 	mov    %dl,-0x7feea2dc(,%eax,8)
80106663:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106666:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
8010666d:	80 
8010666e:	83 e2 f0             	and    $0xfffffff0,%edx
80106671:	83 ca 0e             	or     $0xe,%edx
80106674:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
8010667b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010667e:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
80106685:	80 
80106686:	83 e2 ef             	and    $0xffffffef,%edx
80106689:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
80106690:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106693:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
8010669a:	80 
8010669b:	83 e2 9f             	and    $0xffffff9f,%edx
8010669e:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
801066a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066a8:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
801066af:	80 
801066b0:	83 ca 80             	or     $0xffffff80,%edx
801066b3:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
801066ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066bd:	8b 04 85 7c b0 10 80 	mov    -0x7fef4f84(,%eax,4),%eax
801066c4:	c1 e8 10             	shr    $0x10,%eax
801066c7:	89 c2                	mov    %eax,%edx
801066c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066cc:	66 89 14 c5 26 5d 11 	mov    %dx,-0x7feea2da(,%eax,8)
801066d3:	80 
  for(i = 0; i < 256; i++)
801066d4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801066d8:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801066df:	0f 8e 30 ff ff ff    	jle    80106615 <tvinit+0x12>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801066e5:	a1 7c b1 10 80       	mov    0x8010b17c,%eax
801066ea:	66 a3 20 5f 11 80    	mov    %ax,0x80115f20
801066f0:	66 c7 05 22 5f 11 80 	movw   $0x8,0x80115f22
801066f7:	08 00 
801066f9:	0f b6 05 24 5f 11 80 	movzbl 0x80115f24,%eax
80106700:	83 e0 e0             	and    $0xffffffe0,%eax
80106703:	a2 24 5f 11 80       	mov    %al,0x80115f24
80106708:	0f b6 05 24 5f 11 80 	movzbl 0x80115f24,%eax
8010670f:	83 e0 1f             	and    $0x1f,%eax
80106712:	a2 24 5f 11 80       	mov    %al,0x80115f24
80106717:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
8010671e:	83 c8 0f             	or     $0xf,%eax
80106721:	a2 25 5f 11 80       	mov    %al,0x80115f25
80106726:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
8010672d:	83 e0 ef             	and    $0xffffffef,%eax
80106730:	a2 25 5f 11 80       	mov    %al,0x80115f25
80106735:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
8010673c:	83 c8 60             	or     $0x60,%eax
8010673f:	a2 25 5f 11 80       	mov    %al,0x80115f25
80106744:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
8010674b:	83 c8 80             	or     $0xffffff80,%eax
8010674e:	a2 25 5f 11 80       	mov    %al,0x80115f25
80106753:	a1 7c b1 10 80       	mov    0x8010b17c,%eax
80106758:	c1 e8 10             	shr    $0x10,%eax
8010675b:	66 a3 26 5f 11 80    	mov    %ax,0x80115f26

  initlock(&tickslock, "time");
80106761:	83 ec 08             	sub    $0x8,%esp
80106764:	68 50 88 10 80       	push   $0x80108850
80106769:	68 e0 5c 11 80       	push   $0x80115ce0
8010676e:	e8 da e7 ff ff       	call   80104f4d <initlock>
80106773:	83 c4 10             	add    $0x10,%esp
}
80106776:	90                   	nop
80106777:	c9                   	leave  
80106778:	c3                   	ret    

80106779 <idtinit>:

void
idtinit(void)
{
80106779:	55                   	push   %ebp
8010677a:	89 e5                	mov    %esp,%ebp
  lidt(idt, sizeof(idt));
8010677c:	68 00 08 00 00       	push   $0x800
80106781:	68 20 5d 11 80       	push   $0x80115d20
80106786:	e8 3d fe ff ff       	call   801065c8 <lidt>
8010678b:	83 c4 08             	add    $0x8,%esp
}
8010678e:	90                   	nop
8010678f:	c9                   	leave  
80106790:	c3                   	ret    

80106791 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106791:	55                   	push   %ebp
80106792:	89 e5                	mov    %esp,%ebp
80106794:	57                   	push   %edi
80106795:	56                   	push   %esi
80106796:	53                   	push   %ebx
80106797:	83 ec 1c             	sub    $0x1c,%esp
  if(tf->trapno == T_SYSCALL){
8010679a:	8b 45 08             	mov    0x8(%ebp),%eax
8010679d:	8b 40 30             	mov    0x30(%eax),%eax
801067a0:	83 f8 40             	cmp    $0x40,%eax
801067a3:	75 3d                	jne    801067e2 <trap+0x51>
    if(myproc()->killed)
801067a5:	e8 cf da ff ff       	call   80104279 <myproc>
801067aa:	8b 40 24             	mov    0x24(%eax),%eax
801067ad:	85 c0                	test   %eax,%eax
801067af:	74 05                	je     801067b6 <trap+0x25>
      exit();
801067b1:	e8 47 df ff ff       	call   801046fd <exit>
    myproc()->tf = tf;
801067b6:	e8 be da ff ff       	call   80104279 <myproc>
801067bb:	89 c2                	mov    %eax,%edx
801067bd:	8b 45 08             	mov    0x8(%ebp),%eax
801067c0:	89 42 18             	mov    %eax,0x18(%edx)
    syscall();
801067c3:	e8 26 ee ff ff       	call   801055ee <syscall>
    if(myproc()->killed)
801067c8:	e8 ac da ff ff       	call   80104279 <myproc>
801067cd:	8b 40 24             	mov    0x24(%eax),%eax
801067d0:	85 c0                	test   %eax,%eax
801067d2:	0f 84 04 02 00 00    	je     801069dc <trap+0x24b>
      exit();
801067d8:	e8 20 df ff ff       	call   801046fd <exit>
    return;
801067dd:	e9 fa 01 00 00       	jmp    801069dc <trap+0x24b>
  }

  switch(tf->trapno){
801067e2:	8b 45 08             	mov    0x8(%ebp),%eax
801067e5:	8b 40 30             	mov    0x30(%eax),%eax
801067e8:	83 e8 20             	sub    $0x20,%eax
801067eb:	83 f8 1f             	cmp    $0x1f,%eax
801067ee:	0f 87 b5 00 00 00    	ja     801068a9 <trap+0x118>
801067f4:	8b 04 85 f8 88 10 80 	mov    -0x7fef7708(,%eax,4),%eax
801067fb:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
801067fd:	e8 de d9 ff ff       	call   801041e0 <cpuid>
80106802:	85 c0                	test   %eax,%eax
80106804:	75 3d                	jne    80106843 <trap+0xb2>
      acquire(&tickslock);
80106806:	83 ec 0c             	sub    $0xc,%esp
80106809:	68 e0 5c 11 80       	push   $0x80115ce0
8010680e:	e8 5c e7 ff ff       	call   80104f6f <acquire>
80106813:	83 c4 10             	add    $0x10,%esp
      ticks++;
80106816:	a1 20 65 11 80       	mov    0x80116520,%eax
8010681b:	83 c0 01             	add    $0x1,%eax
8010681e:	a3 20 65 11 80       	mov    %eax,0x80116520
      wakeup(&ticks);
80106823:	83 ec 0c             	sub    $0xc,%esp
80106826:	68 20 65 11 80       	push   $0x80116520
8010682b:	e8 e6 e3 ff ff       	call   80104c16 <wakeup>
80106830:	83 c4 10             	add    $0x10,%esp
      release(&tickslock);
80106833:	83 ec 0c             	sub    $0xc,%esp
80106836:	68 e0 5c 11 80       	push   $0x80115ce0
8010683b:	e8 9d e7 ff ff       	call   80104fdd <release>
80106840:	83 c4 10             	add    $0x10,%esp
    }
    lapiceoi();
80106843:	e8 b1 c7 ff ff       	call   80102ff9 <lapiceoi>
    break;
80106848:	e9 0f 01 00 00       	jmp    8010695c <trap+0x1cb>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
8010684d:	e8 21 c0 ff ff       	call   80102873 <ideintr>
    lapiceoi();
80106852:	e8 a2 c7 ff ff       	call   80102ff9 <lapiceoi>
    break;
80106857:	e9 00 01 00 00       	jmp    8010695c <trap+0x1cb>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010685c:	e8 e1 c5 ff ff       	call   80102e42 <kbdintr>
    lapiceoi();
80106861:	e8 93 c7 ff ff       	call   80102ff9 <lapiceoi>
    break;
80106866:	e9 f1 00 00 00       	jmp    8010695c <trap+0x1cb>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010686b:	e8 40 03 00 00       	call   80106bb0 <uartintr>
    lapiceoi();
80106870:	e8 84 c7 ff ff       	call   80102ff9 <lapiceoi>
    break;
80106875:	e9 e2 00 00 00       	jmp    8010695c <trap+0x1cb>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010687a:	8b 45 08             	mov    0x8(%ebp),%eax
8010687d:	8b 70 38             	mov    0x38(%eax),%esi
            cpuid(), tf->cs, tf->eip);
80106880:	8b 45 08             	mov    0x8(%ebp),%eax
80106883:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106887:	0f b7 d8             	movzwl %ax,%ebx
8010688a:	e8 51 d9 ff ff       	call   801041e0 <cpuid>
8010688f:	56                   	push   %esi
80106890:	53                   	push   %ebx
80106891:	50                   	push   %eax
80106892:	68 58 88 10 80       	push   $0x80108858
80106897:	e8 60 9b ff ff       	call   801003fc <cprintf>
8010689c:	83 c4 10             	add    $0x10,%esp
    lapiceoi();
8010689f:	e8 55 c7 ff ff       	call   80102ff9 <lapiceoi>
    break;
801068a4:	e9 b3 00 00 00       	jmp    8010695c <trap+0x1cb>

  //PAGEBREAK: 13
  default:
    if(myproc() == 0 || (tf->cs&3) == 0){
801068a9:	e8 cb d9 ff ff       	call   80104279 <myproc>
801068ae:	85 c0                	test   %eax,%eax
801068b0:	74 11                	je     801068c3 <trap+0x132>
801068b2:	8b 45 08             	mov    0x8(%ebp),%eax
801068b5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801068b9:	0f b7 c0             	movzwl %ax,%eax
801068bc:	83 e0 03             	and    $0x3,%eax
801068bf:	85 c0                	test   %eax,%eax
801068c1:	75 3b                	jne    801068fe <trap+0x16d>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801068c3:	e8 2a fd ff ff       	call   801065f2 <rcr2>
801068c8:	89 c6                	mov    %eax,%esi
801068ca:	8b 45 08             	mov    0x8(%ebp),%eax
801068cd:	8b 58 38             	mov    0x38(%eax),%ebx
801068d0:	e8 0b d9 ff ff       	call   801041e0 <cpuid>
801068d5:	89 c2                	mov    %eax,%edx
801068d7:	8b 45 08             	mov    0x8(%ebp),%eax
801068da:	8b 40 30             	mov    0x30(%eax),%eax
801068dd:	83 ec 0c             	sub    $0xc,%esp
801068e0:	56                   	push   %esi
801068e1:	53                   	push   %ebx
801068e2:	52                   	push   %edx
801068e3:	50                   	push   %eax
801068e4:	68 7c 88 10 80       	push   $0x8010887c
801068e9:	e8 0e 9b ff ff       	call   801003fc <cprintf>
801068ee:	83 c4 20             	add    $0x20,%esp
              tf->trapno, cpuid(), tf->eip, rcr2());
      panic("trap");
801068f1:	83 ec 0c             	sub    $0xc,%esp
801068f4:	68 ae 88 10 80       	push   $0x801088ae
801068f9:	e8 9e 9c ff ff       	call   8010059c <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801068fe:	e8 ef fc ff ff       	call   801065f2 <rcr2>
80106903:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106906:	8b 45 08             	mov    0x8(%ebp),%eax
80106909:	8b 78 38             	mov    0x38(%eax),%edi
8010690c:	e8 cf d8 ff ff       	call   801041e0 <cpuid>
80106911:	89 45 e0             	mov    %eax,-0x20(%ebp)
80106914:	8b 45 08             	mov    0x8(%ebp),%eax
80106917:	8b 70 34             	mov    0x34(%eax),%esi
8010691a:	8b 45 08             	mov    0x8(%ebp),%eax
8010691d:	8b 58 30             	mov    0x30(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, tf->trapno,
80106920:	e8 54 d9 ff ff       	call   80104279 <myproc>
80106925:	8d 48 6c             	lea    0x6c(%eax),%ecx
80106928:	89 4d dc             	mov    %ecx,-0x24(%ebp)
8010692b:	e8 49 d9 ff ff       	call   80104279 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106930:	8b 40 10             	mov    0x10(%eax),%eax
80106933:	ff 75 e4             	pushl  -0x1c(%ebp)
80106936:	57                   	push   %edi
80106937:	ff 75 e0             	pushl  -0x20(%ebp)
8010693a:	56                   	push   %esi
8010693b:	53                   	push   %ebx
8010693c:	ff 75 dc             	pushl  -0x24(%ebp)
8010693f:	50                   	push   %eax
80106940:	68 b4 88 10 80       	push   $0x801088b4
80106945:	e8 b2 9a ff ff       	call   801003fc <cprintf>
8010694a:	83 c4 20             	add    $0x20,%esp
            tf->err, cpuid(), tf->eip, rcr2());
    myproc()->killed = 1;
8010694d:	e8 27 d9 ff ff       	call   80104279 <myproc>
80106952:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106959:	eb 01                	jmp    8010695c <trap+0x1cb>
    break;
8010695b:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010695c:	e8 18 d9 ff ff       	call   80104279 <myproc>
80106961:	85 c0                	test   %eax,%eax
80106963:	74 23                	je     80106988 <trap+0x1f7>
80106965:	e8 0f d9 ff ff       	call   80104279 <myproc>
8010696a:	8b 40 24             	mov    0x24(%eax),%eax
8010696d:	85 c0                	test   %eax,%eax
8010696f:	74 17                	je     80106988 <trap+0x1f7>
80106971:	8b 45 08             	mov    0x8(%ebp),%eax
80106974:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106978:	0f b7 c0             	movzwl %ax,%eax
8010697b:	83 e0 03             	and    $0x3,%eax
8010697e:	83 f8 03             	cmp    $0x3,%eax
80106981:	75 05                	jne    80106988 <trap+0x1f7>
    exit();
80106983:	e8 75 dd ff ff       	call   801046fd <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80106988:	e8 ec d8 ff ff       	call   80104279 <myproc>
8010698d:	85 c0                	test   %eax,%eax
8010698f:	74 1d                	je     801069ae <trap+0x21d>
80106991:	e8 e3 d8 ff ff       	call   80104279 <myproc>
80106996:	8b 40 0c             	mov    0xc(%eax),%eax
80106999:	83 f8 04             	cmp    $0x4,%eax
8010699c:	75 10                	jne    801069ae <trap+0x21d>
     tf->trapno == T_IRQ0+IRQ_TIMER)
8010699e:	8b 45 08             	mov    0x8(%ebp),%eax
801069a1:	8b 40 30             	mov    0x30(%eax),%eax
  if(myproc() && myproc()->state == RUNNING &&
801069a4:	83 f8 20             	cmp    $0x20,%eax
801069a7:	75 05                	jne    801069ae <trap+0x21d>
    yield();
801069a9:	e8 02 e1 ff ff       	call   80104ab0 <yield>

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801069ae:	e8 c6 d8 ff ff       	call   80104279 <myproc>
801069b3:	85 c0                	test   %eax,%eax
801069b5:	74 26                	je     801069dd <trap+0x24c>
801069b7:	e8 bd d8 ff ff       	call   80104279 <myproc>
801069bc:	8b 40 24             	mov    0x24(%eax),%eax
801069bf:	85 c0                	test   %eax,%eax
801069c1:	74 1a                	je     801069dd <trap+0x24c>
801069c3:	8b 45 08             	mov    0x8(%ebp),%eax
801069c6:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801069ca:	0f b7 c0             	movzwl %ax,%eax
801069cd:	83 e0 03             	and    $0x3,%eax
801069d0:	83 f8 03             	cmp    $0x3,%eax
801069d3:	75 08                	jne    801069dd <trap+0x24c>
    exit();
801069d5:	e8 23 dd ff ff       	call   801046fd <exit>
801069da:	eb 01                	jmp    801069dd <trap+0x24c>
    return;
801069dc:	90                   	nop
}
801069dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
801069e0:	5b                   	pop    %ebx
801069e1:	5e                   	pop    %esi
801069e2:	5f                   	pop    %edi
801069e3:	5d                   	pop    %ebp
801069e4:	c3                   	ret    

801069e5 <inb>:
{
801069e5:	55                   	push   %ebp
801069e6:	89 e5                	mov    %esp,%ebp
801069e8:	83 ec 14             	sub    $0x14,%esp
801069eb:	8b 45 08             	mov    0x8(%ebp),%eax
801069ee:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801069f2:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801069f6:	89 c2                	mov    %eax,%edx
801069f8:	ec                   	in     (%dx),%al
801069f9:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801069fc:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80106a00:	c9                   	leave  
80106a01:	c3                   	ret    

80106a02 <outb>:
{
80106a02:	55                   	push   %ebp
80106a03:	89 e5                	mov    %esp,%ebp
80106a05:	83 ec 08             	sub    $0x8,%esp
80106a08:	8b 55 08             	mov    0x8(%ebp),%edx
80106a0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80106a0e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106a12:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106a15:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106a19:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106a1d:	ee                   	out    %al,(%dx)
}
80106a1e:	90                   	nop
80106a1f:	c9                   	leave  
80106a20:	c3                   	ret    

80106a21 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106a21:	55                   	push   %ebp
80106a22:	89 e5                	mov    %esp,%ebp
80106a24:	83 ec 18             	sub    $0x18,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106a27:	6a 00                	push   $0x0
80106a29:	68 fa 03 00 00       	push   $0x3fa
80106a2e:	e8 cf ff ff ff       	call   80106a02 <outb>
80106a33:	83 c4 08             	add    $0x8,%esp

  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106a36:	68 80 00 00 00       	push   $0x80
80106a3b:	68 fb 03 00 00       	push   $0x3fb
80106a40:	e8 bd ff ff ff       	call   80106a02 <outb>
80106a45:	83 c4 08             	add    $0x8,%esp
  outb(COM1+0, 115200/9600);
80106a48:	6a 0c                	push   $0xc
80106a4a:	68 f8 03 00 00       	push   $0x3f8
80106a4f:	e8 ae ff ff ff       	call   80106a02 <outb>
80106a54:	83 c4 08             	add    $0x8,%esp
  outb(COM1+1, 0);
80106a57:	6a 00                	push   $0x0
80106a59:	68 f9 03 00 00       	push   $0x3f9
80106a5e:	e8 9f ff ff ff       	call   80106a02 <outb>
80106a63:	83 c4 08             	add    $0x8,%esp
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106a66:	6a 03                	push   $0x3
80106a68:	68 fb 03 00 00       	push   $0x3fb
80106a6d:	e8 90 ff ff ff       	call   80106a02 <outb>
80106a72:	83 c4 08             	add    $0x8,%esp
  outb(COM1+4, 0);
80106a75:	6a 00                	push   $0x0
80106a77:	68 fc 03 00 00       	push   $0x3fc
80106a7c:	e8 81 ff ff ff       	call   80106a02 <outb>
80106a81:	83 c4 08             	add    $0x8,%esp
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106a84:	6a 01                	push   $0x1
80106a86:	68 f9 03 00 00       	push   $0x3f9
80106a8b:	e8 72 ff ff ff       	call   80106a02 <outb>
80106a90:	83 c4 08             	add    $0x8,%esp

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106a93:	68 fd 03 00 00       	push   $0x3fd
80106a98:	e8 48 ff ff ff       	call   801069e5 <inb>
80106a9d:	83 c4 04             	add    $0x4,%esp
80106aa0:	3c ff                	cmp    $0xff,%al
80106aa2:	74 61                	je     80106b05 <uartinit+0xe4>
    return;
  uart = 1;
80106aa4:	c7 05 24 b6 10 80 01 	movl   $0x1,0x8010b624
80106aab:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106aae:	68 fa 03 00 00       	push   $0x3fa
80106ab3:	e8 2d ff ff ff       	call   801069e5 <inb>
80106ab8:	83 c4 04             	add    $0x4,%esp
  inb(COM1+0);
80106abb:	68 f8 03 00 00       	push   $0x3f8
80106ac0:	e8 20 ff ff ff       	call   801069e5 <inb>
80106ac5:	83 c4 04             	add    $0x4,%esp
  ioapicenable(IRQ_COM1, 0);
80106ac8:	83 ec 08             	sub    $0x8,%esp
80106acb:	6a 00                	push   $0x0
80106acd:	6a 04                	push   $0x4
80106acf:	e8 3c c0 ff ff       	call   80102b10 <ioapicenable>
80106ad4:	83 c4 10             	add    $0x10,%esp

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106ad7:	c7 45 f4 78 89 10 80 	movl   $0x80108978,-0xc(%ebp)
80106ade:	eb 19                	jmp    80106af9 <uartinit+0xd8>
    uartputc(*p);
80106ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ae3:	0f b6 00             	movzbl (%eax),%eax
80106ae6:	0f be c0             	movsbl %al,%eax
80106ae9:	83 ec 0c             	sub    $0xc,%esp
80106aec:	50                   	push   %eax
80106aed:	e8 16 00 00 00       	call   80106b08 <uartputc>
80106af2:	83 c4 10             	add    $0x10,%esp
  for(p="xv6...\n"; *p; p++)
80106af5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106af9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106afc:	0f b6 00             	movzbl (%eax),%eax
80106aff:	84 c0                	test   %al,%al
80106b01:	75 dd                	jne    80106ae0 <uartinit+0xbf>
80106b03:	eb 01                	jmp    80106b06 <uartinit+0xe5>
    return;
80106b05:	90                   	nop
}
80106b06:	c9                   	leave  
80106b07:	c3                   	ret    

80106b08 <uartputc>:

void
uartputc(int c)
{
80106b08:	55                   	push   %ebp
80106b09:	89 e5                	mov    %esp,%ebp
80106b0b:	83 ec 18             	sub    $0x18,%esp
  int i;

  if(!uart)
80106b0e:	a1 24 b6 10 80       	mov    0x8010b624,%eax
80106b13:	85 c0                	test   %eax,%eax
80106b15:	74 53                	je     80106b6a <uartputc+0x62>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106b17:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106b1e:	eb 11                	jmp    80106b31 <uartputc+0x29>
    microdelay(10);
80106b20:	83 ec 0c             	sub    $0xc,%esp
80106b23:	6a 0a                	push   $0xa
80106b25:	e8 ea c4 ff ff       	call   80103014 <microdelay>
80106b2a:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106b2d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106b31:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106b35:	7f 1a                	jg     80106b51 <uartputc+0x49>
80106b37:	83 ec 0c             	sub    $0xc,%esp
80106b3a:	68 fd 03 00 00       	push   $0x3fd
80106b3f:	e8 a1 fe ff ff       	call   801069e5 <inb>
80106b44:	83 c4 10             	add    $0x10,%esp
80106b47:	0f b6 c0             	movzbl %al,%eax
80106b4a:	83 e0 20             	and    $0x20,%eax
80106b4d:	85 c0                	test   %eax,%eax
80106b4f:	74 cf                	je     80106b20 <uartputc+0x18>
  outb(COM1+0, c);
80106b51:	8b 45 08             	mov    0x8(%ebp),%eax
80106b54:	0f b6 c0             	movzbl %al,%eax
80106b57:	83 ec 08             	sub    $0x8,%esp
80106b5a:	50                   	push   %eax
80106b5b:	68 f8 03 00 00       	push   $0x3f8
80106b60:	e8 9d fe ff ff       	call   80106a02 <outb>
80106b65:	83 c4 10             	add    $0x10,%esp
80106b68:	eb 01                	jmp    80106b6b <uartputc+0x63>
    return;
80106b6a:	90                   	nop
}
80106b6b:	c9                   	leave  
80106b6c:	c3                   	ret    

80106b6d <uartgetc>:

static int
uartgetc(void)
{
80106b6d:	55                   	push   %ebp
80106b6e:	89 e5                	mov    %esp,%ebp
  if(!uart)
80106b70:	a1 24 b6 10 80       	mov    0x8010b624,%eax
80106b75:	85 c0                	test   %eax,%eax
80106b77:	75 07                	jne    80106b80 <uartgetc+0x13>
    return -1;
80106b79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b7e:	eb 2e                	jmp    80106bae <uartgetc+0x41>
  if(!(inb(COM1+5) & 0x01))
80106b80:	68 fd 03 00 00       	push   $0x3fd
80106b85:	e8 5b fe ff ff       	call   801069e5 <inb>
80106b8a:	83 c4 04             	add    $0x4,%esp
80106b8d:	0f b6 c0             	movzbl %al,%eax
80106b90:	83 e0 01             	and    $0x1,%eax
80106b93:	85 c0                	test   %eax,%eax
80106b95:	75 07                	jne    80106b9e <uartgetc+0x31>
    return -1;
80106b97:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b9c:	eb 10                	jmp    80106bae <uartgetc+0x41>
  return inb(COM1+0);
80106b9e:	68 f8 03 00 00       	push   $0x3f8
80106ba3:	e8 3d fe ff ff       	call   801069e5 <inb>
80106ba8:	83 c4 04             	add    $0x4,%esp
80106bab:	0f b6 c0             	movzbl %al,%eax
}
80106bae:	c9                   	leave  
80106baf:	c3                   	ret    

80106bb0 <uartintr>:

void
uartintr(void)
{
80106bb0:	55                   	push   %ebp
80106bb1:	89 e5                	mov    %esp,%ebp
80106bb3:	83 ec 08             	sub    $0x8,%esp
  consoleintr(uartgetc);
80106bb6:	83 ec 0c             	sub    $0xc,%esp
80106bb9:	68 6d 6b 10 80       	push   $0x80106b6d
80106bbe:	e8 6d 9c ff ff       	call   80100830 <consoleintr>
80106bc3:	83 c4 10             	add    $0x10,%esp
}
80106bc6:	90                   	nop
80106bc7:	c9                   	leave  
80106bc8:	c3                   	ret    

80106bc9 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106bc9:	6a 00                	push   $0x0
  pushl $0
80106bcb:	6a 00                	push   $0x0
  jmp alltraps
80106bcd:	e9 d3 f9 ff ff       	jmp    801065a5 <alltraps>

80106bd2 <vector1>:
.globl vector1
vector1:
  pushl $0
80106bd2:	6a 00                	push   $0x0
  pushl $1
80106bd4:	6a 01                	push   $0x1
  jmp alltraps
80106bd6:	e9 ca f9 ff ff       	jmp    801065a5 <alltraps>

80106bdb <vector2>:
.globl vector2
vector2:
  pushl $0
80106bdb:	6a 00                	push   $0x0
  pushl $2
80106bdd:	6a 02                	push   $0x2
  jmp alltraps
80106bdf:	e9 c1 f9 ff ff       	jmp    801065a5 <alltraps>

80106be4 <vector3>:
.globl vector3
vector3:
  pushl $0
80106be4:	6a 00                	push   $0x0
  pushl $3
80106be6:	6a 03                	push   $0x3
  jmp alltraps
80106be8:	e9 b8 f9 ff ff       	jmp    801065a5 <alltraps>

80106bed <vector4>:
.globl vector4
vector4:
  pushl $0
80106bed:	6a 00                	push   $0x0
  pushl $4
80106bef:	6a 04                	push   $0x4
  jmp alltraps
80106bf1:	e9 af f9 ff ff       	jmp    801065a5 <alltraps>

80106bf6 <vector5>:
.globl vector5
vector5:
  pushl $0
80106bf6:	6a 00                	push   $0x0
  pushl $5
80106bf8:	6a 05                	push   $0x5
  jmp alltraps
80106bfa:	e9 a6 f9 ff ff       	jmp    801065a5 <alltraps>

80106bff <vector6>:
.globl vector6
vector6:
  pushl $0
80106bff:	6a 00                	push   $0x0
  pushl $6
80106c01:	6a 06                	push   $0x6
  jmp alltraps
80106c03:	e9 9d f9 ff ff       	jmp    801065a5 <alltraps>

80106c08 <vector7>:
.globl vector7
vector7:
  pushl $0
80106c08:	6a 00                	push   $0x0
  pushl $7
80106c0a:	6a 07                	push   $0x7
  jmp alltraps
80106c0c:	e9 94 f9 ff ff       	jmp    801065a5 <alltraps>

80106c11 <vector8>:
.globl vector8
vector8:
  pushl $8
80106c11:	6a 08                	push   $0x8
  jmp alltraps
80106c13:	e9 8d f9 ff ff       	jmp    801065a5 <alltraps>

80106c18 <vector9>:
.globl vector9
vector9:
  pushl $0
80106c18:	6a 00                	push   $0x0
  pushl $9
80106c1a:	6a 09                	push   $0x9
  jmp alltraps
80106c1c:	e9 84 f9 ff ff       	jmp    801065a5 <alltraps>

80106c21 <vector10>:
.globl vector10
vector10:
  pushl $10
80106c21:	6a 0a                	push   $0xa
  jmp alltraps
80106c23:	e9 7d f9 ff ff       	jmp    801065a5 <alltraps>

80106c28 <vector11>:
.globl vector11
vector11:
  pushl $11
80106c28:	6a 0b                	push   $0xb
  jmp alltraps
80106c2a:	e9 76 f9 ff ff       	jmp    801065a5 <alltraps>

80106c2f <vector12>:
.globl vector12
vector12:
  pushl $12
80106c2f:	6a 0c                	push   $0xc
  jmp alltraps
80106c31:	e9 6f f9 ff ff       	jmp    801065a5 <alltraps>

80106c36 <vector13>:
.globl vector13
vector13:
  pushl $13
80106c36:	6a 0d                	push   $0xd
  jmp alltraps
80106c38:	e9 68 f9 ff ff       	jmp    801065a5 <alltraps>

80106c3d <vector14>:
.globl vector14
vector14:
  pushl $14
80106c3d:	6a 0e                	push   $0xe
  jmp alltraps
80106c3f:	e9 61 f9 ff ff       	jmp    801065a5 <alltraps>

80106c44 <vector15>:
.globl vector15
vector15:
  pushl $0
80106c44:	6a 00                	push   $0x0
  pushl $15
80106c46:	6a 0f                	push   $0xf
  jmp alltraps
80106c48:	e9 58 f9 ff ff       	jmp    801065a5 <alltraps>

80106c4d <vector16>:
.globl vector16
vector16:
  pushl $0
80106c4d:	6a 00                	push   $0x0
  pushl $16
80106c4f:	6a 10                	push   $0x10
  jmp alltraps
80106c51:	e9 4f f9 ff ff       	jmp    801065a5 <alltraps>

80106c56 <vector17>:
.globl vector17
vector17:
  pushl $17
80106c56:	6a 11                	push   $0x11
  jmp alltraps
80106c58:	e9 48 f9 ff ff       	jmp    801065a5 <alltraps>

80106c5d <vector18>:
.globl vector18
vector18:
  pushl $0
80106c5d:	6a 00                	push   $0x0
  pushl $18
80106c5f:	6a 12                	push   $0x12
  jmp alltraps
80106c61:	e9 3f f9 ff ff       	jmp    801065a5 <alltraps>

80106c66 <vector19>:
.globl vector19
vector19:
  pushl $0
80106c66:	6a 00                	push   $0x0
  pushl $19
80106c68:	6a 13                	push   $0x13
  jmp alltraps
80106c6a:	e9 36 f9 ff ff       	jmp    801065a5 <alltraps>

80106c6f <vector20>:
.globl vector20
vector20:
  pushl $0
80106c6f:	6a 00                	push   $0x0
  pushl $20
80106c71:	6a 14                	push   $0x14
  jmp alltraps
80106c73:	e9 2d f9 ff ff       	jmp    801065a5 <alltraps>

80106c78 <vector21>:
.globl vector21
vector21:
  pushl $0
80106c78:	6a 00                	push   $0x0
  pushl $21
80106c7a:	6a 15                	push   $0x15
  jmp alltraps
80106c7c:	e9 24 f9 ff ff       	jmp    801065a5 <alltraps>

80106c81 <vector22>:
.globl vector22
vector22:
  pushl $0
80106c81:	6a 00                	push   $0x0
  pushl $22
80106c83:	6a 16                	push   $0x16
  jmp alltraps
80106c85:	e9 1b f9 ff ff       	jmp    801065a5 <alltraps>

80106c8a <vector23>:
.globl vector23
vector23:
  pushl $0
80106c8a:	6a 00                	push   $0x0
  pushl $23
80106c8c:	6a 17                	push   $0x17
  jmp alltraps
80106c8e:	e9 12 f9 ff ff       	jmp    801065a5 <alltraps>

80106c93 <vector24>:
.globl vector24
vector24:
  pushl $0
80106c93:	6a 00                	push   $0x0
  pushl $24
80106c95:	6a 18                	push   $0x18
  jmp alltraps
80106c97:	e9 09 f9 ff ff       	jmp    801065a5 <alltraps>

80106c9c <vector25>:
.globl vector25
vector25:
  pushl $0
80106c9c:	6a 00                	push   $0x0
  pushl $25
80106c9e:	6a 19                	push   $0x19
  jmp alltraps
80106ca0:	e9 00 f9 ff ff       	jmp    801065a5 <alltraps>

80106ca5 <vector26>:
.globl vector26
vector26:
  pushl $0
80106ca5:	6a 00                	push   $0x0
  pushl $26
80106ca7:	6a 1a                	push   $0x1a
  jmp alltraps
80106ca9:	e9 f7 f8 ff ff       	jmp    801065a5 <alltraps>

80106cae <vector27>:
.globl vector27
vector27:
  pushl $0
80106cae:	6a 00                	push   $0x0
  pushl $27
80106cb0:	6a 1b                	push   $0x1b
  jmp alltraps
80106cb2:	e9 ee f8 ff ff       	jmp    801065a5 <alltraps>

80106cb7 <vector28>:
.globl vector28
vector28:
  pushl $0
80106cb7:	6a 00                	push   $0x0
  pushl $28
80106cb9:	6a 1c                	push   $0x1c
  jmp alltraps
80106cbb:	e9 e5 f8 ff ff       	jmp    801065a5 <alltraps>

80106cc0 <vector29>:
.globl vector29
vector29:
  pushl $0
80106cc0:	6a 00                	push   $0x0
  pushl $29
80106cc2:	6a 1d                	push   $0x1d
  jmp alltraps
80106cc4:	e9 dc f8 ff ff       	jmp    801065a5 <alltraps>

80106cc9 <vector30>:
.globl vector30
vector30:
  pushl $0
80106cc9:	6a 00                	push   $0x0
  pushl $30
80106ccb:	6a 1e                	push   $0x1e
  jmp alltraps
80106ccd:	e9 d3 f8 ff ff       	jmp    801065a5 <alltraps>

80106cd2 <vector31>:
.globl vector31
vector31:
  pushl $0
80106cd2:	6a 00                	push   $0x0
  pushl $31
80106cd4:	6a 1f                	push   $0x1f
  jmp alltraps
80106cd6:	e9 ca f8 ff ff       	jmp    801065a5 <alltraps>

80106cdb <vector32>:
.globl vector32
vector32:
  pushl $0
80106cdb:	6a 00                	push   $0x0
  pushl $32
80106cdd:	6a 20                	push   $0x20
  jmp alltraps
80106cdf:	e9 c1 f8 ff ff       	jmp    801065a5 <alltraps>

80106ce4 <vector33>:
.globl vector33
vector33:
  pushl $0
80106ce4:	6a 00                	push   $0x0
  pushl $33
80106ce6:	6a 21                	push   $0x21
  jmp alltraps
80106ce8:	e9 b8 f8 ff ff       	jmp    801065a5 <alltraps>

80106ced <vector34>:
.globl vector34
vector34:
  pushl $0
80106ced:	6a 00                	push   $0x0
  pushl $34
80106cef:	6a 22                	push   $0x22
  jmp alltraps
80106cf1:	e9 af f8 ff ff       	jmp    801065a5 <alltraps>

80106cf6 <vector35>:
.globl vector35
vector35:
  pushl $0
80106cf6:	6a 00                	push   $0x0
  pushl $35
80106cf8:	6a 23                	push   $0x23
  jmp alltraps
80106cfa:	e9 a6 f8 ff ff       	jmp    801065a5 <alltraps>

80106cff <vector36>:
.globl vector36
vector36:
  pushl $0
80106cff:	6a 00                	push   $0x0
  pushl $36
80106d01:	6a 24                	push   $0x24
  jmp alltraps
80106d03:	e9 9d f8 ff ff       	jmp    801065a5 <alltraps>

80106d08 <vector37>:
.globl vector37
vector37:
  pushl $0
80106d08:	6a 00                	push   $0x0
  pushl $37
80106d0a:	6a 25                	push   $0x25
  jmp alltraps
80106d0c:	e9 94 f8 ff ff       	jmp    801065a5 <alltraps>

80106d11 <vector38>:
.globl vector38
vector38:
  pushl $0
80106d11:	6a 00                	push   $0x0
  pushl $38
80106d13:	6a 26                	push   $0x26
  jmp alltraps
80106d15:	e9 8b f8 ff ff       	jmp    801065a5 <alltraps>

80106d1a <vector39>:
.globl vector39
vector39:
  pushl $0
80106d1a:	6a 00                	push   $0x0
  pushl $39
80106d1c:	6a 27                	push   $0x27
  jmp alltraps
80106d1e:	e9 82 f8 ff ff       	jmp    801065a5 <alltraps>

80106d23 <vector40>:
.globl vector40
vector40:
  pushl $0
80106d23:	6a 00                	push   $0x0
  pushl $40
80106d25:	6a 28                	push   $0x28
  jmp alltraps
80106d27:	e9 79 f8 ff ff       	jmp    801065a5 <alltraps>

80106d2c <vector41>:
.globl vector41
vector41:
  pushl $0
80106d2c:	6a 00                	push   $0x0
  pushl $41
80106d2e:	6a 29                	push   $0x29
  jmp alltraps
80106d30:	e9 70 f8 ff ff       	jmp    801065a5 <alltraps>

80106d35 <vector42>:
.globl vector42
vector42:
  pushl $0
80106d35:	6a 00                	push   $0x0
  pushl $42
80106d37:	6a 2a                	push   $0x2a
  jmp alltraps
80106d39:	e9 67 f8 ff ff       	jmp    801065a5 <alltraps>

80106d3e <vector43>:
.globl vector43
vector43:
  pushl $0
80106d3e:	6a 00                	push   $0x0
  pushl $43
80106d40:	6a 2b                	push   $0x2b
  jmp alltraps
80106d42:	e9 5e f8 ff ff       	jmp    801065a5 <alltraps>

80106d47 <vector44>:
.globl vector44
vector44:
  pushl $0
80106d47:	6a 00                	push   $0x0
  pushl $44
80106d49:	6a 2c                	push   $0x2c
  jmp alltraps
80106d4b:	e9 55 f8 ff ff       	jmp    801065a5 <alltraps>

80106d50 <vector45>:
.globl vector45
vector45:
  pushl $0
80106d50:	6a 00                	push   $0x0
  pushl $45
80106d52:	6a 2d                	push   $0x2d
  jmp alltraps
80106d54:	e9 4c f8 ff ff       	jmp    801065a5 <alltraps>

80106d59 <vector46>:
.globl vector46
vector46:
  pushl $0
80106d59:	6a 00                	push   $0x0
  pushl $46
80106d5b:	6a 2e                	push   $0x2e
  jmp alltraps
80106d5d:	e9 43 f8 ff ff       	jmp    801065a5 <alltraps>

80106d62 <vector47>:
.globl vector47
vector47:
  pushl $0
80106d62:	6a 00                	push   $0x0
  pushl $47
80106d64:	6a 2f                	push   $0x2f
  jmp alltraps
80106d66:	e9 3a f8 ff ff       	jmp    801065a5 <alltraps>

80106d6b <vector48>:
.globl vector48
vector48:
  pushl $0
80106d6b:	6a 00                	push   $0x0
  pushl $48
80106d6d:	6a 30                	push   $0x30
  jmp alltraps
80106d6f:	e9 31 f8 ff ff       	jmp    801065a5 <alltraps>

80106d74 <vector49>:
.globl vector49
vector49:
  pushl $0
80106d74:	6a 00                	push   $0x0
  pushl $49
80106d76:	6a 31                	push   $0x31
  jmp alltraps
80106d78:	e9 28 f8 ff ff       	jmp    801065a5 <alltraps>

80106d7d <vector50>:
.globl vector50
vector50:
  pushl $0
80106d7d:	6a 00                	push   $0x0
  pushl $50
80106d7f:	6a 32                	push   $0x32
  jmp alltraps
80106d81:	e9 1f f8 ff ff       	jmp    801065a5 <alltraps>

80106d86 <vector51>:
.globl vector51
vector51:
  pushl $0
80106d86:	6a 00                	push   $0x0
  pushl $51
80106d88:	6a 33                	push   $0x33
  jmp alltraps
80106d8a:	e9 16 f8 ff ff       	jmp    801065a5 <alltraps>

80106d8f <vector52>:
.globl vector52
vector52:
  pushl $0
80106d8f:	6a 00                	push   $0x0
  pushl $52
80106d91:	6a 34                	push   $0x34
  jmp alltraps
80106d93:	e9 0d f8 ff ff       	jmp    801065a5 <alltraps>

80106d98 <vector53>:
.globl vector53
vector53:
  pushl $0
80106d98:	6a 00                	push   $0x0
  pushl $53
80106d9a:	6a 35                	push   $0x35
  jmp alltraps
80106d9c:	e9 04 f8 ff ff       	jmp    801065a5 <alltraps>

80106da1 <vector54>:
.globl vector54
vector54:
  pushl $0
80106da1:	6a 00                	push   $0x0
  pushl $54
80106da3:	6a 36                	push   $0x36
  jmp alltraps
80106da5:	e9 fb f7 ff ff       	jmp    801065a5 <alltraps>

80106daa <vector55>:
.globl vector55
vector55:
  pushl $0
80106daa:	6a 00                	push   $0x0
  pushl $55
80106dac:	6a 37                	push   $0x37
  jmp alltraps
80106dae:	e9 f2 f7 ff ff       	jmp    801065a5 <alltraps>

80106db3 <vector56>:
.globl vector56
vector56:
  pushl $0
80106db3:	6a 00                	push   $0x0
  pushl $56
80106db5:	6a 38                	push   $0x38
  jmp alltraps
80106db7:	e9 e9 f7 ff ff       	jmp    801065a5 <alltraps>

80106dbc <vector57>:
.globl vector57
vector57:
  pushl $0
80106dbc:	6a 00                	push   $0x0
  pushl $57
80106dbe:	6a 39                	push   $0x39
  jmp alltraps
80106dc0:	e9 e0 f7 ff ff       	jmp    801065a5 <alltraps>

80106dc5 <vector58>:
.globl vector58
vector58:
  pushl $0
80106dc5:	6a 00                	push   $0x0
  pushl $58
80106dc7:	6a 3a                	push   $0x3a
  jmp alltraps
80106dc9:	e9 d7 f7 ff ff       	jmp    801065a5 <alltraps>

80106dce <vector59>:
.globl vector59
vector59:
  pushl $0
80106dce:	6a 00                	push   $0x0
  pushl $59
80106dd0:	6a 3b                	push   $0x3b
  jmp alltraps
80106dd2:	e9 ce f7 ff ff       	jmp    801065a5 <alltraps>

80106dd7 <vector60>:
.globl vector60
vector60:
  pushl $0
80106dd7:	6a 00                	push   $0x0
  pushl $60
80106dd9:	6a 3c                	push   $0x3c
  jmp alltraps
80106ddb:	e9 c5 f7 ff ff       	jmp    801065a5 <alltraps>

80106de0 <vector61>:
.globl vector61
vector61:
  pushl $0
80106de0:	6a 00                	push   $0x0
  pushl $61
80106de2:	6a 3d                	push   $0x3d
  jmp alltraps
80106de4:	e9 bc f7 ff ff       	jmp    801065a5 <alltraps>

80106de9 <vector62>:
.globl vector62
vector62:
  pushl $0
80106de9:	6a 00                	push   $0x0
  pushl $62
80106deb:	6a 3e                	push   $0x3e
  jmp alltraps
80106ded:	e9 b3 f7 ff ff       	jmp    801065a5 <alltraps>

80106df2 <vector63>:
.globl vector63
vector63:
  pushl $0
80106df2:	6a 00                	push   $0x0
  pushl $63
80106df4:	6a 3f                	push   $0x3f
  jmp alltraps
80106df6:	e9 aa f7 ff ff       	jmp    801065a5 <alltraps>

80106dfb <vector64>:
.globl vector64
vector64:
  pushl $0
80106dfb:	6a 00                	push   $0x0
  pushl $64
80106dfd:	6a 40                	push   $0x40
  jmp alltraps
80106dff:	e9 a1 f7 ff ff       	jmp    801065a5 <alltraps>

80106e04 <vector65>:
.globl vector65
vector65:
  pushl $0
80106e04:	6a 00                	push   $0x0
  pushl $65
80106e06:	6a 41                	push   $0x41
  jmp alltraps
80106e08:	e9 98 f7 ff ff       	jmp    801065a5 <alltraps>

80106e0d <vector66>:
.globl vector66
vector66:
  pushl $0
80106e0d:	6a 00                	push   $0x0
  pushl $66
80106e0f:	6a 42                	push   $0x42
  jmp alltraps
80106e11:	e9 8f f7 ff ff       	jmp    801065a5 <alltraps>

80106e16 <vector67>:
.globl vector67
vector67:
  pushl $0
80106e16:	6a 00                	push   $0x0
  pushl $67
80106e18:	6a 43                	push   $0x43
  jmp alltraps
80106e1a:	e9 86 f7 ff ff       	jmp    801065a5 <alltraps>

80106e1f <vector68>:
.globl vector68
vector68:
  pushl $0
80106e1f:	6a 00                	push   $0x0
  pushl $68
80106e21:	6a 44                	push   $0x44
  jmp alltraps
80106e23:	e9 7d f7 ff ff       	jmp    801065a5 <alltraps>

80106e28 <vector69>:
.globl vector69
vector69:
  pushl $0
80106e28:	6a 00                	push   $0x0
  pushl $69
80106e2a:	6a 45                	push   $0x45
  jmp alltraps
80106e2c:	e9 74 f7 ff ff       	jmp    801065a5 <alltraps>

80106e31 <vector70>:
.globl vector70
vector70:
  pushl $0
80106e31:	6a 00                	push   $0x0
  pushl $70
80106e33:	6a 46                	push   $0x46
  jmp alltraps
80106e35:	e9 6b f7 ff ff       	jmp    801065a5 <alltraps>

80106e3a <vector71>:
.globl vector71
vector71:
  pushl $0
80106e3a:	6a 00                	push   $0x0
  pushl $71
80106e3c:	6a 47                	push   $0x47
  jmp alltraps
80106e3e:	e9 62 f7 ff ff       	jmp    801065a5 <alltraps>

80106e43 <vector72>:
.globl vector72
vector72:
  pushl $0
80106e43:	6a 00                	push   $0x0
  pushl $72
80106e45:	6a 48                	push   $0x48
  jmp alltraps
80106e47:	e9 59 f7 ff ff       	jmp    801065a5 <alltraps>

80106e4c <vector73>:
.globl vector73
vector73:
  pushl $0
80106e4c:	6a 00                	push   $0x0
  pushl $73
80106e4e:	6a 49                	push   $0x49
  jmp alltraps
80106e50:	e9 50 f7 ff ff       	jmp    801065a5 <alltraps>

80106e55 <vector74>:
.globl vector74
vector74:
  pushl $0
80106e55:	6a 00                	push   $0x0
  pushl $74
80106e57:	6a 4a                	push   $0x4a
  jmp alltraps
80106e59:	e9 47 f7 ff ff       	jmp    801065a5 <alltraps>

80106e5e <vector75>:
.globl vector75
vector75:
  pushl $0
80106e5e:	6a 00                	push   $0x0
  pushl $75
80106e60:	6a 4b                	push   $0x4b
  jmp alltraps
80106e62:	e9 3e f7 ff ff       	jmp    801065a5 <alltraps>

80106e67 <vector76>:
.globl vector76
vector76:
  pushl $0
80106e67:	6a 00                	push   $0x0
  pushl $76
80106e69:	6a 4c                	push   $0x4c
  jmp alltraps
80106e6b:	e9 35 f7 ff ff       	jmp    801065a5 <alltraps>

80106e70 <vector77>:
.globl vector77
vector77:
  pushl $0
80106e70:	6a 00                	push   $0x0
  pushl $77
80106e72:	6a 4d                	push   $0x4d
  jmp alltraps
80106e74:	e9 2c f7 ff ff       	jmp    801065a5 <alltraps>

80106e79 <vector78>:
.globl vector78
vector78:
  pushl $0
80106e79:	6a 00                	push   $0x0
  pushl $78
80106e7b:	6a 4e                	push   $0x4e
  jmp alltraps
80106e7d:	e9 23 f7 ff ff       	jmp    801065a5 <alltraps>

80106e82 <vector79>:
.globl vector79
vector79:
  pushl $0
80106e82:	6a 00                	push   $0x0
  pushl $79
80106e84:	6a 4f                	push   $0x4f
  jmp alltraps
80106e86:	e9 1a f7 ff ff       	jmp    801065a5 <alltraps>

80106e8b <vector80>:
.globl vector80
vector80:
  pushl $0
80106e8b:	6a 00                	push   $0x0
  pushl $80
80106e8d:	6a 50                	push   $0x50
  jmp alltraps
80106e8f:	e9 11 f7 ff ff       	jmp    801065a5 <alltraps>

80106e94 <vector81>:
.globl vector81
vector81:
  pushl $0
80106e94:	6a 00                	push   $0x0
  pushl $81
80106e96:	6a 51                	push   $0x51
  jmp alltraps
80106e98:	e9 08 f7 ff ff       	jmp    801065a5 <alltraps>

80106e9d <vector82>:
.globl vector82
vector82:
  pushl $0
80106e9d:	6a 00                	push   $0x0
  pushl $82
80106e9f:	6a 52                	push   $0x52
  jmp alltraps
80106ea1:	e9 ff f6 ff ff       	jmp    801065a5 <alltraps>

80106ea6 <vector83>:
.globl vector83
vector83:
  pushl $0
80106ea6:	6a 00                	push   $0x0
  pushl $83
80106ea8:	6a 53                	push   $0x53
  jmp alltraps
80106eaa:	e9 f6 f6 ff ff       	jmp    801065a5 <alltraps>

80106eaf <vector84>:
.globl vector84
vector84:
  pushl $0
80106eaf:	6a 00                	push   $0x0
  pushl $84
80106eb1:	6a 54                	push   $0x54
  jmp alltraps
80106eb3:	e9 ed f6 ff ff       	jmp    801065a5 <alltraps>

80106eb8 <vector85>:
.globl vector85
vector85:
  pushl $0
80106eb8:	6a 00                	push   $0x0
  pushl $85
80106eba:	6a 55                	push   $0x55
  jmp alltraps
80106ebc:	e9 e4 f6 ff ff       	jmp    801065a5 <alltraps>

80106ec1 <vector86>:
.globl vector86
vector86:
  pushl $0
80106ec1:	6a 00                	push   $0x0
  pushl $86
80106ec3:	6a 56                	push   $0x56
  jmp alltraps
80106ec5:	e9 db f6 ff ff       	jmp    801065a5 <alltraps>

80106eca <vector87>:
.globl vector87
vector87:
  pushl $0
80106eca:	6a 00                	push   $0x0
  pushl $87
80106ecc:	6a 57                	push   $0x57
  jmp alltraps
80106ece:	e9 d2 f6 ff ff       	jmp    801065a5 <alltraps>

80106ed3 <vector88>:
.globl vector88
vector88:
  pushl $0
80106ed3:	6a 00                	push   $0x0
  pushl $88
80106ed5:	6a 58                	push   $0x58
  jmp alltraps
80106ed7:	e9 c9 f6 ff ff       	jmp    801065a5 <alltraps>

80106edc <vector89>:
.globl vector89
vector89:
  pushl $0
80106edc:	6a 00                	push   $0x0
  pushl $89
80106ede:	6a 59                	push   $0x59
  jmp alltraps
80106ee0:	e9 c0 f6 ff ff       	jmp    801065a5 <alltraps>

80106ee5 <vector90>:
.globl vector90
vector90:
  pushl $0
80106ee5:	6a 00                	push   $0x0
  pushl $90
80106ee7:	6a 5a                	push   $0x5a
  jmp alltraps
80106ee9:	e9 b7 f6 ff ff       	jmp    801065a5 <alltraps>

80106eee <vector91>:
.globl vector91
vector91:
  pushl $0
80106eee:	6a 00                	push   $0x0
  pushl $91
80106ef0:	6a 5b                	push   $0x5b
  jmp alltraps
80106ef2:	e9 ae f6 ff ff       	jmp    801065a5 <alltraps>

80106ef7 <vector92>:
.globl vector92
vector92:
  pushl $0
80106ef7:	6a 00                	push   $0x0
  pushl $92
80106ef9:	6a 5c                	push   $0x5c
  jmp alltraps
80106efb:	e9 a5 f6 ff ff       	jmp    801065a5 <alltraps>

80106f00 <vector93>:
.globl vector93
vector93:
  pushl $0
80106f00:	6a 00                	push   $0x0
  pushl $93
80106f02:	6a 5d                	push   $0x5d
  jmp alltraps
80106f04:	e9 9c f6 ff ff       	jmp    801065a5 <alltraps>

80106f09 <vector94>:
.globl vector94
vector94:
  pushl $0
80106f09:	6a 00                	push   $0x0
  pushl $94
80106f0b:	6a 5e                	push   $0x5e
  jmp alltraps
80106f0d:	e9 93 f6 ff ff       	jmp    801065a5 <alltraps>

80106f12 <vector95>:
.globl vector95
vector95:
  pushl $0
80106f12:	6a 00                	push   $0x0
  pushl $95
80106f14:	6a 5f                	push   $0x5f
  jmp alltraps
80106f16:	e9 8a f6 ff ff       	jmp    801065a5 <alltraps>

80106f1b <vector96>:
.globl vector96
vector96:
  pushl $0
80106f1b:	6a 00                	push   $0x0
  pushl $96
80106f1d:	6a 60                	push   $0x60
  jmp alltraps
80106f1f:	e9 81 f6 ff ff       	jmp    801065a5 <alltraps>

80106f24 <vector97>:
.globl vector97
vector97:
  pushl $0
80106f24:	6a 00                	push   $0x0
  pushl $97
80106f26:	6a 61                	push   $0x61
  jmp alltraps
80106f28:	e9 78 f6 ff ff       	jmp    801065a5 <alltraps>

80106f2d <vector98>:
.globl vector98
vector98:
  pushl $0
80106f2d:	6a 00                	push   $0x0
  pushl $98
80106f2f:	6a 62                	push   $0x62
  jmp alltraps
80106f31:	e9 6f f6 ff ff       	jmp    801065a5 <alltraps>

80106f36 <vector99>:
.globl vector99
vector99:
  pushl $0
80106f36:	6a 00                	push   $0x0
  pushl $99
80106f38:	6a 63                	push   $0x63
  jmp alltraps
80106f3a:	e9 66 f6 ff ff       	jmp    801065a5 <alltraps>

80106f3f <vector100>:
.globl vector100
vector100:
  pushl $0
80106f3f:	6a 00                	push   $0x0
  pushl $100
80106f41:	6a 64                	push   $0x64
  jmp alltraps
80106f43:	e9 5d f6 ff ff       	jmp    801065a5 <alltraps>

80106f48 <vector101>:
.globl vector101
vector101:
  pushl $0
80106f48:	6a 00                	push   $0x0
  pushl $101
80106f4a:	6a 65                	push   $0x65
  jmp alltraps
80106f4c:	e9 54 f6 ff ff       	jmp    801065a5 <alltraps>

80106f51 <vector102>:
.globl vector102
vector102:
  pushl $0
80106f51:	6a 00                	push   $0x0
  pushl $102
80106f53:	6a 66                	push   $0x66
  jmp alltraps
80106f55:	e9 4b f6 ff ff       	jmp    801065a5 <alltraps>

80106f5a <vector103>:
.globl vector103
vector103:
  pushl $0
80106f5a:	6a 00                	push   $0x0
  pushl $103
80106f5c:	6a 67                	push   $0x67
  jmp alltraps
80106f5e:	e9 42 f6 ff ff       	jmp    801065a5 <alltraps>

80106f63 <vector104>:
.globl vector104
vector104:
  pushl $0
80106f63:	6a 00                	push   $0x0
  pushl $104
80106f65:	6a 68                	push   $0x68
  jmp alltraps
80106f67:	e9 39 f6 ff ff       	jmp    801065a5 <alltraps>

80106f6c <vector105>:
.globl vector105
vector105:
  pushl $0
80106f6c:	6a 00                	push   $0x0
  pushl $105
80106f6e:	6a 69                	push   $0x69
  jmp alltraps
80106f70:	e9 30 f6 ff ff       	jmp    801065a5 <alltraps>

80106f75 <vector106>:
.globl vector106
vector106:
  pushl $0
80106f75:	6a 00                	push   $0x0
  pushl $106
80106f77:	6a 6a                	push   $0x6a
  jmp alltraps
80106f79:	e9 27 f6 ff ff       	jmp    801065a5 <alltraps>

80106f7e <vector107>:
.globl vector107
vector107:
  pushl $0
80106f7e:	6a 00                	push   $0x0
  pushl $107
80106f80:	6a 6b                	push   $0x6b
  jmp alltraps
80106f82:	e9 1e f6 ff ff       	jmp    801065a5 <alltraps>

80106f87 <vector108>:
.globl vector108
vector108:
  pushl $0
80106f87:	6a 00                	push   $0x0
  pushl $108
80106f89:	6a 6c                	push   $0x6c
  jmp alltraps
80106f8b:	e9 15 f6 ff ff       	jmp    801065a5 <alltraps>

80106f90 <vector109>:
.globl vector109
vector109:
  pushl $0
80106f90:	6a 00                	push   $0x0
  pushl $109
80106f92:	6a 6d                	push   $0x6d
  jmp alltraps
80106f94:	e9 0c f6 ff ff       	jmp    801065a5 <alltraps>

80106f99 <vector110>:
.globl vector110
vector110:
  pushl $0
80106f99:	6a 00                	push   $0x0
  pushl $110
80106f9b:	6a 6e                	push   $0x6e
  jmp alltraps
80106f9d:	e9 03 f6 ff ff       	jmp    801065a5 <alltraps>

80106fa2 <vector111>:
.globl vector111
vector111:
  pushl $0
80106fa2:	6a 00                	push   $0x0
  pushl $111
80106fa4:	6a 6f                	push   $0x6f
  jmp alltraps
80106fa6:	e9 fa f5 ff ff       	jmp    801065a5 <alltraps>

80106fab <vector112>:
.globl vector112
vector112:
  pushl $0
80106fab:	6a 00                	push   $0x0
  pushl $112
80106fad:	6a 70                	push   $0x70
  jmp alltraps
80106faf:	e9 f1 f5 ff ff       	jmp    801065a5 <alltraps>

80106fb4 <vector113>:
.globl vector113
vector113:
  pushl $0
80106fb4:	6a 00                	push   $0x0
  pushl $113
80106fb6:	6a 71                	push   $0x71
  jmp alltraps
80106fb8:	e9 e8 f5 ff ff       	jmp    801065a5 <alltraps>

80106fbd <vector114>:
.globl vector114
vector114:
  pushl $0
80106fbd:	6a 00                	push   $0x0
  pushl $114
80106fbf:	6a 72                	push   $0x72
  jmp alltraps
80106fc1:	e9 df f5 ff ff       	jmp    801065a5 <alltraps>

80106fc6 <vector115>:
.globl vector115
vector115:
  pushl $0
80106fc6:	6a 00                	push   $0x0
  pushl $115
80106fc8:	6a 73                	push   $0x73
  jmp alltraps
80106fca:	e9 d6 f5 ff ff       	jmp    801065a5 <alltraps>

80106fcf <vector116>:
.globl vector116
vector116:
  pushl $0
80106fcf:	6a 00                	push   $0x0
  pushl $116
80106fd1:	6a 74                	push   $0x74
  jmp alltraps
80106fd3:	e9 cd f5 ff ff       	jmp    801065a5 <alltraps>

80106fd8 <vector117>:
.globl vector117
vector117:
  pushl $0
80106fd8:	6a 00                	push   $0x0
  pushl $117
80106fda:	6a 75                	push   $0x75
  jmp alltraps
80106fdc:	e9 c4 f5 ff ff       	jmp    801065a5 <alltraps>

80106fe1 <vector118>:
.globl vector118
vector118:
  pushl $0
80106fe1:	6a 00                	push   $0x0
  pushl $118
80106fe3:	6a 76                	push   $0x76
  jmp alltraps
80106fe5:	e9 bb f5 ff ff       	jmp    801065a5 <alltraps>

80106fea <vector119>:
.globl vector119
vector119:
  pushl $0
80106fea:	6a 00                	push   $0x0
  pushl $119
80106fec:	6a 77                	push   $0x77
  jmp alltraps
80106fee:	e9 b2 f5 ff ff       	jmp    801065a5 <alltraps>

80106ff3 <vector120>:
.globl vector120
vector120:
  pushl $0
80106ff3:	6a 00                	push   $0x0
  pushl $120
80106ff5:	6a 78                	push   $0x78
  jmp alltraps
80106ff7:	e9 a9 f5 ff ff       	jmp    801065a5 <alltraps>

80106ffc <vector121>:
.globl vector121
vector121:
  pushl $0
80106ffc:	6a 00                	push   $0x0
  pushl $121
80106ffe:	6a 79                	push   $0x79
  jmp alltraps
80107000:	e9 a0 f5 ff ff       	jmp    801065a5 <alltraps>

80107005 <vector122>:
.globl vector122
vector122:
  pushl $0
80107005:	6a 00                	push   $0x0
  pushl $122
80107007:	6a 7a                	push   $0x7a
  jmp alltraps
80107009:	e9 97 f5 ff ff       	jmp    801065a5 <alltraps>

8010700e <vector123>:
.globl vector123
vector123:
  pushl $0
8010700e:	6a 00                	push   $0x0
  pushl $123
80107010:	6a 7b                	push   $0x7b
  jmp alltraps
80107012:	e9 8e f5 ff ff       	jmp    801065a5 <alltraps>

80107017 <vector124>:
.globl vector124
vector124:
  pushl $0
80107017:	6a 00                	push   $0x0
  pushl $124
80107019:	6a 7c                	push   $0x7c
  jmp alltraps
8010701b:	e9 85 f5 ff ff       	jmp    801065a5 <alltraps>

80107020 <vector125>:
.globl vector125
vector125:
  pushl $0
80107020:	6a 00                	push   $0x0
  pushl $125
80107022:	6a 7d                	push   $0x7d
  jmp alltraps
80107024:	e9 7c f5 ff ff       	jmp    801065a5 <alltraps>

80107029 <vector126>:
.globl vector126
vector126:
  pushl $0
80107029:	6a 00                	push   $0x0
  pushl $126
8010702b:	6a 7e                	push   $0x7e
  jmp alltraps
8010702d:	e9 73 f5 ff ff       	jmp    801065a5 <alltraps>

80107032 <vector127>:
.globl vector127
vector127:
  pushl $0
80107032:	6a 00                	push   $0x0
  pushl $127
80107034:	6a 7f                	push   $0x7f
  jmp alltraps
80107036:	e9 6a f5 ff ff       	jmp    801065a5 <alltraps>

8010703b <vector128>:
.globl vector128
vector128:
  pushl $0
8010703b:	6a 00                	push   $0x0
  pushl $128
8010703d:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107042:	e9 5e f5 ff ff       	jmp    801065a5 <alltraps>

80107047 <vector129>:
.globl vector129
vector129:
  pushl $0
80107047:	6a 00                	push   $0x0
  pushl $129
80107049:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010704e:	e9 52 f5 ff ff       	jmp    801065a5 <alltraps>

80107053 <vector130>:
.globl vector130
vector130:
  pushl $0
80107053:	6a 00                	push   $0x0
  pushl $130
80107055:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010705a:	e9 46 f5 ff ff       	jmp    801065a5 <alltraps>

8010705f <vector131>:
.globl vector131
vector131:
  pushl $0
8010705f:	6a 00                	push   $0x0
  pushl $131
80107061:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107066:	e9 3a f5 ff ff       	jmp    801065a5 <alltraps>

8010706b <vector132>:
.globl vector132
vector132:
  pushl $0
8010706b:	6a 00                	push   $0x0
  pushl $132
8010706d:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107072:	e9 2e f5 ff ff       	jmp    801065a5 <alltraps>

80107077 <vector133>:
.globl vector133
vector133:
  pushl $0
80107077:	6a 00                	push   $0x0
  pushl $133
80107079:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010707e:	e9 22 f5 ff ff       	jmp    801065a5 <alltraps>

80107083 <vector134>:
.globl vector134
vector134:
  pushl $0
80107083:	6a 00                	push   $0x0
  pushl $134
80107085:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010708a:	e9 16 f5 ff ff       	jmp    801065a5 <alltraps>

8010708f <vector135>:
.globl vector135
vector135:
  pushl $0
8010708f:	6a 00                	push   $0x0
  pushl $135
80107091:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107096:	e9 0a f5 ff ff       	jmp    801065a5 <alltraps>

8010709b <vector136>:
.globl vector136
vector136:
  pushl $0
8010709b:	6a 00                	push   $0x0
  pushl $136
8010709d:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801070a2:	e9 fe f4 ff ff       	jmp    801065a5 <alltraps>

801070a7 <vector137>:
.globl vector137
vector137:
  pushl $0
801070a7:	6a 00                	push   $0x0
  pushl $137
801070a9:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801070ae:	e9 f2 f4 ff ff       	jmp    801065a5 <alltraps>

801070b3 <vector138>:
.globl vector138
vector138:
  pushl $0
801070b3:	6a 00                	push   $0x0
  pushl $138
801070b5:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801070ba:	e9 e6 f4 ff ff       	jmp    801065a5 <alltraps>

801070bf <vector139>:
.globl vector139
vector139:
  pushl $0
801070bf:	6a 00                	push   $0x0
  pushl $139
801070c1:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801070c6:	e9 da f4 ff ff       	jmp    801065a5 <alltraps>

801070cb <vector140>:
.globl vector140
vector140:
  pushl $0
801070cb:	6a 00                	push   $0x0
  pushl $140
801070cd:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801070d2:	e9 ce f4 ff ff       	jmp    801065a5 <alltraps>

801070d7 <vector141>:
.globl vector141
vector141:
  pushl $0
801070d7:	6a 00                	push   $0x0
  pushl $141
801070d9:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801070de:	e9 c2 f4 ff ff       	jmp    801065a5 <alltraps>

801070e3 <vector142>:
.globl vector142
vector142:
  pushl $0
801070e3:	6a 00                	push   $0x0
  pushl $142
801070e5:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801070ea:	e9 b6 f4 ff ff       	jmp    801065a5 <alltraps>

801070ef <vector143>:
.globl vector143
vector143:
  pushl $0
801070ef:	6a 00                	push   $0x0
  pushl $143
801070f1:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801070f6:	e9 aa f4 ff ff       	jmp    801065a5 <alltraps>

801070fb <vector144>:
.globl vector144
vector144:
  pushl $0
801070fb:	6a 00                	push   $0x0
  pushl $144
801070fd:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107102:	e9 9e f4 ff ff       	jmp    801065a5 <alltraps>

80107107 <vector145>:
.globl vector145
vector145:
  pushl $0
80107107:	6a 00                	push   $0x0
  pushl $145
80107109:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010710e:	e9 92 f4 ff ff       	jmp    801065a5 <alltraps>

80107113 <vector146>:
.globl vector146
vector146:
  pushl $0
80107113:	6a 00                	push   $0x0
  pushl $146
80107115:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010711a:	e9 86 f4 ff ff       	jmp    801065a5 <alltraps>

8010711f <vector147>:
.globl vector147
vector147:
  pushl $0
8010711f:	6a 00                	push   $0x0
  pushl $147
80107121:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107126:	e9 7a f4 ff ff       	jmp    801065a5 <alltraps>

8010712b <vector148>:
.globl vector148
vector148:
  pushl $0
8010712b:	6a 00                	push   $0x0
  pushl $148
8010712d:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107132:	e9 6e f4 ff ff       	jmp    801065a5 <alltraps>

80107137 <vector149>:
.globl vector149
vector149:
  pushl $0
80107137:	6a 00                	push   $0x0
  pushl $149
80107139:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010713e:	e9 62 f4 ff ff       	jmp    801065a5 <alltraps>

80107143 <vector150>:
.globl vector150
vector150:
  pushl $0
80107143:	6a 00                	push   $0x0
  pushl $150
80107145:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010714a:	e9 56 f4 ff ff       	jmp    801065a5 <alltraps>

8010714f <vector151>:
.globl vector151
vector151:
  pushl $0
8010714f:	6a 00                	push   $0x0
  pushl $151
80107151:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107156:	e9 4a f4 ff ff       	jmp    801065a5 <alltraps>

8010715b <vector152>:
.globl vector152
vector152:
  pushl $0
8010715b:	6a 00                	push   $0x0
  pushl $152
8010715d:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107162:	e9 3e f4 ff ff       	jmp    801065a5 <alltraps>

80107167 <vector153>:
.globl vector153
vector153:
  pushl $0
80107167:	6a 00                	push   $0x0
  pushl $153
80107169:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010716e:	e9 32 f4 ff ff       	jmp    801065a5 <alltraps>

80107173 <vector154>:
.globl vector154
vector154:
  pushl $0
80107173:	6a 00                	push   $0x0
  pushl $154
80107175:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010717a:	e9 26 f4 ff ff       	jmp    801065a5 <alltraps>

8010717f <vector155>:
.globl vector155
vector155:
  pushl $0
8010717f:	6a 00                	push   $0x0
  pushl $155
80107181:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107186:	e9 1a f4 ff ff       	jmp    801065a5 <alltraps>

8010718b <vector156>:
.globl vector156
vector156:
  pushl $0
8010718b:	6a 00                	push   $0x0
  pushl $156
8010718d:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107192:	e9 0e f4 ff ff       	jmp    801065a5 <alltraps>

80107197 <vector157>:
.globl vector157
vector157:
  pushl $0
80107197:	6a 00                	push   $0x0
  pushl $157
80107199:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010719e:	e9 02 f4 ff ff       	jmp    801065a5 <alltraps>

801071a3 <vector158>:
.globl vector158
vector158:
  pushl $0
801071a3:	6a 00                	push   $0x0
  pushl $158
801071a5:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801071aa:	e9 f6 f3 ff ff       	jmp    801065a5 <alltraps>

801071af <vector159>:
.globl vector159
vector159:
  pushl $0
801071af:	6a 00                	push   $0x0
  pushl $159
801071b1:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801071b6:	e9 ea f3 ff ff       	jmp    801065a5 <alltraps>

801071bb <vector160>:
.globl vector160
vector160:
  pushl $0
801071bb:	6a 00                	push   $0x0
  pushl $160
801071bd:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801071c2:	e9 de f3 ff ff       	jmp    801065a5 <alltraps>

801071c7 <vector161>:
.globl vector161
vector161:
  pushl $0
801071c7:	6a 00                	push   $0x0
  pushl $161
801071c9:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801071ce:	e9 d2 f3 ff ff       	jmp    801065a5 <alltraps>

801071d3 <vector162>:
.globl vector162
vector162:
  pushl $0
801071d3:	6a 00                	push   $0x0
  pushl $162
801071d5:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801071da:	e9 c6 f3 ff ff       	jmp    801065a5 <alltraps>

801071df <vector163>:
.globl vector163
vector163:
  pushl $0
801071df:	6a 00                	push   $0x0
  pushl $163
801071e1:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801071e6:	e9 ba f3 ff ff       	jmp    801065a5 <alltraps>

801071eb <vector164>:
.globl vector164
vector164:
  pushl $0
801071eb:	6a 00                	push   $0x0
  pushl $164
801071ed:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801071f2:	e9 ae f3 ff ff       	jmp    801065a5 <alltraps>

801071f7 <vector165>:
.globl vector165
vector165:
  pushl $0
801071f7:	6a 00                	push   $0x0
  pushl $165
801071f9:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801071fe:	e9 a2 f3 ff ff       	jmp    801065a5 <alltraps>

80107203 <vector166>:
.globl vector166
vector166:
  pushl $0
80107203:	6a 00                	push   $0x0
  pushl $166
80107205:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
8010720a:	e9 96 f3 ff ff       	jmp    801065a5 <alltraps>

8010720f <vector167>:
.globl vector167
vector167:
  pushl $0
8010720f:	6a 00                	push   $0x0
  pushl $167
80107211:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107216:	e9 8a f3 ff ff       	jmp    801065a5 <alltraps>

8010721b <vector168>:
.globl vector168
vector168:
  pushl $0
8010721b:	6a 00                	push   $0x0
  pushl $168
8010721d:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107222:	e9 7e f3 ff ff       	jmp    801065a5 <alltraps>

80107227 <vector169>:
.globl vector169
vector169:
  pushl $0
80107227:	6a 00                	push   $0x0
  pushl $169
80107229:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010722e:	e9 72 f3 ff ff       	jmp    801065a5 <alltraps>

80107233 <vector170>:
.globl vector170
vector170:
  pushl $0
80107233:	6a 00                	push   $0x0
  pushl $170
80107235:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010723a:	e9 66 f3 ff ff       	jmp    801065a5 <alltraps>

8010723f <vector171>:
.globl vector171
vector171:
  pushl $0
8010723f:	6a 00                	push   $0x0
  pushl $171
80107241:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107246:	e9 5a f3 ff ff       	jmp    801065a5 <alltraps>

8010724b <vector172>:
.globl vector172
vector172:
  pushl $0
8010724b:	6a 00                	push   $0x0
  pushl $172
8010724d:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107252:	e9 4e f3 ff ff       	jmp    801065a5 <alltraps>

80107257 <vector173>:
.globl vector173
vector173:
  pushl $0
80107257:	6a 00                	push   $0x0
  pushl $173
80107259:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010725e:	e9 42 f3 ff ff       	jmp    801065a5 <alltraps>

80107263 <vector174>:
.globl vector174
vector174:
  pushl $0
80107263:	6a 00                	push   $0x0
  pushl $174
80107265:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010726a:	e9 36 f3 ff ff       	jmp    801065a5 <alltraps>

8010726f <vector175>:
.globl vector175
vector175:
  pushl $0
8010726f:	6a 00                	push   $0x0
  pushl $175
80107271:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107276:	e9 2a f3 ff ff       	jmp    801065a5 <alltraps>

8010727b <vector176>:
.globl vector176
vector176:
  pushl $0
8010727b:	6a 00                	push   $0x0
  pushl $176
8010727d:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107282:	e9 1e f3 ff ff       	jmp    801065a5 <alltraps>

80107287 <vector177>:
.globl vector177
vector177:
  pushl $0
80107287:	6a 00                	push   $0x0
  pushl $177
80107289:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010728e:	e9 12 f3 ff ff       	jmp    801065a5 <alltraps>

80107293 <vector178>:
.globl vector178
vector178:
  pushl $0
80107293:	6a 00                	push   $0x0
  pushl $178
80107295:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010729a:	e9 06 f3 ff ff       	jmp    801065a5 <alltraps>

8010729f <vector179>:
.globl vector179
vector179:
  pushl $0
8010729f:	6a 00                	push   $0x0
  pushl $179
801072a1:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801072a6:	e9 fa f2 ff ff       	jmp    801065a5 <alltraps>

801072ab <vector180>:
.globl vector180
vector180:
  pushl $0
801072ab:	6a 00                	push   $0x0
  pushl $180
801072ad:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801072b2:	e9 ee f2 ff ff       	jmp    801065a5 <alltraps>

801072b7 <vector181>:
.globl vector181
vector181:
  pushl $0
801072b7:	6a 00                	push   $0x0
  pushl $181
801072b9:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801072be:	e9 e2 f2 ff ff       	jmp    801065a5 <alltraps>

801072c3 <vector182>:
.globl vector182
vector182:
  pushl $0
801072c3:	6a 00                	push   $0x0
  pushl $182
801072c5:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801072ca:	e9 d6 f2 ff ff       	jmp    801065a5 <alltraps>

801072cf <vector183>:
.globl vector183
vector183:
  pushl $0
801072cf:	6a 00                	push   $0x0
  pushl $183
801072d1:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801072d6:	e9 ca f2 ff ff       	jmp    801065a5 <alltraps>

801072db <vector184>:
.globl vector184
vector184:
  pushl $0
801072db:	6a 00                	push   $0x0
  pushl $184
801072dd:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801072e2:	e9 be f2 ff ff       	jmp    801065a5 <alltraps>

801072e7 <vector185>:
.globl vector185
vector185:
  pushl $0
801072e7:	6a 00                	push   $0x0
  pushl $185
801072e9:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801072ee:	e9 b2 f2 ff ff       	jmp    801065a5 <alltraps>

801072f3 <vector186>:
.globl vector186
vector186:
  pushl $0
801072f3:	6a 00                	push   $0x0
  pushl $186
801072f5:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801072fa:	e9 a6 f2 ff ff       	jmp    801065a5 <alltraps>

801072ff <vector187>:
.globl vector187
vector187:
  pushl $0
801072ff:	6a 00                	push   $0x0
  pushl $187
80107301:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107306:	e9 9a f2 ff ff       	jmp    801065a5 <alltraps>

8010730b <vector188>:
.globl vector188
vector188:
  pushl $0
8010730b:	6a 00                	push   $0x0
  pushl $188
8010730d:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107312:	e9 8e f2 ff ff       	jmp    801065a5 <alltraps>

80107317 <vector189>:
.globl vector189
vector189:
  pushl $0
80107317:	6a 00                	push   $0x0
  pushl $189
80107319:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
8010731e:	e9 82 f2 ff ff       	jmp    801065a5 <alltraps>

80107323 <vector190>:
.globl vector190
vector190:
  pushl $0
80107323:	6a 00                	push   $0x0
  pushl $190
80107325:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010732a:	e9 76 f2 ff ff       	jmp    801065a5 <alltraps>

8010732f <vector191>:
.globl vector191
vector191:
  pushl $0
8010732f:	6a 00                	push   $0x0
  pushl $191
80107331:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107336:	e9 6a f2 ff ff       	jmp    801065a5 <alltraps>

8010733b <vector192>:
.globl vector192
vector192:
  pushl $0
8010733b:	6a 00                	push   $0x0
  pushl $192
8010733d:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107342:	e9 5e f2 ff ff       	jmp    801065a5 <alltraps>

80107347 <vector193>:
.globl vector193
vector193:
  pushl $0
80107347:	6a 00                	push   $0x0
  pushl $193
80107349:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
8010734e:	e9 52 f2 ff ff       	jmp    801065a5 <alltraps>

80107353 <vector194>:
.globl vector194
vector194:
  pushl $0
80107353:	6a 00                	push   $0x0
  pushl $194
80107355:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010735a:	e9 46 f2 ff ff       	jmp    801065a5 <alltraps>

8010735f <vector195>:
.globl vector195
vector195:
  pushl $0
8010735f:	6a 00                	push   $0x0
  pushl $195
80107361:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107366:	e9 3a f2 ff ff       	jmp    801065a5 <alltraps>

8010736b <vector196>:
.globl vector196
vector196:
  pushl $0
8010736b:	6a 00                	push   $0x0
  pushl $196
8010736d:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107372:	e9 2e f2 ff ff       	jmp    801065a5 <alltraps>

80107377 <vector197>:
.globl vector197
vector197:
  pushl $0
80107377:	6a 00                	push   $0x0
  pushl $197
80107379:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
8010737e:	e9 22 f2 ff ff       	jmp    801065a5 <alltraps>

80107383 <vector198>:
.globl vector198
vector198:
  pushl $0
80107383:	6a 00                	push   $0x0
  pushl $198
80107385:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
8010738a:	e9 16 f2 ff ff       	jmp    801065a5 <alltraps>

8010738f <vector199>:
.globl vector199
vector199:
  pushl $0
8010738f:	6a 00                	push   $0x0
  pushl $199
80107391:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107396:	e9 0a f2 ff ff       	jmp    801065a5 <alltraps>

8010739b <vector200>:
.globl vector200
vector200:
  pushl $0
8010739b:	6a 00                	push   $0x0
  pushl $200
8010739d:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801073a2:	e9 fe f1 ff ff       	jmp    801065a5 <alltraps>

801073a7 <vector201>:
.globl vector201
vector201:
  pushl $0
801073a7:	6a 00                	push   $0x0
  pushl $201
801073a9:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801073ae:	e9 f2 f1 ff ff       	jmp    801065a5 <alltraps>

801073b3 <vector202>:
.globl vector202
vector202:
  pushl $0
801073b3:	6a 00                	push   $0x0
  pushl $202
801073b5:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801073ba:	e9 e6 f1 ff ff       	jmp    801065a5 <alltraps>

801073bf <vector203>:
.globl vector203
vector203:
  pushl $0
801073bf:	6a 00                	push   $0x0
  pushl $203
801073c1:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801073c6:	e9 da f1 ff ff       	jmp    801065a5 <alltraps>

801073cb <vector204>:
.globl vector204
vector204:
  pushl $0
801073cb:	6a 00                	push   $0x0
  pushl $204
801073cd:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801073d2:	e9 ce f1 ff ff       	jmp    801065a5 <alltraps>

801073d7 <vector205>:
.globl vector205
vector205:
  pushl $0
801073d7:	6a 00                	push   $0x0
  pushl $205
801073d9:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801073de:	e9 c2 f1 ff ff       	jmp    801065a5 <alltraps>

801073e3 <vector206>:
.globl vector206
vector206:
  pushl $0
801073e3:	6a 00                	push   $0x0
  pushl $206
801073e5:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801073ea:	e9 b6 f1 ff ff       	jmp    801065a5 <alltraps>

801073ef <vector207>:
.globl vector207
vector207:
  pushl $0
801073ef:	6a 00                	push   $0x0
  pushl $207
801073f1:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801073f6:	e9 aa f1 ff ff       	jmp    801065a5 <alltraps>

801073fb <vector208>:
.globl vector208
vector208:
  pushl $0
801073fb:	6a 00                	push   $0x0
  pushl $208
801073fd:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107402:	e9 9e f1 ff ff       	jmp    801065a5 <alltraps>

80107407 <vector209>:
.globl vector209
vector209:
  pushl $0
80107407:	6a 00                	push   $0x0
  pushl $209
80107409:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
8010740e:	e9 92 f1 ff ff       	jmp    801065a5 <alltraps>

80107413 <vector210>:
.globl vector210
vector210:
  pushl $0
80107413:	6a 00                	push   $0x0
  pushl $210
80107415:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
8010741a:	e9 86 f1 ff ff       	jmp    801065a5 <alltraps>

8010741f <vector211>:
.globl vector211
vector211:
  pushl $0
8010741f:	6a 00                	push   $0x0
  pushl $211
80107421:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107426:	e9 7a f1 ff ff       	jmp    801065a5 <alltraps>

8010742b <vector212>:
.globl vector212
vector212:
  pushl $0
8010742b:	6a 00                	push   $0x0
  pushl $212
8010742d:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107432:	e9 6e f1 ff ff       	jmp    801065a5 <alltraps>

80107437 <vector213>:
.globl vector213
vector213:
  pushl $0
80107437:	6a 00                	push   $0x0
  pushl $213
80107439:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
8010743e:	e9 62 f1 ff ff       	jmp    801065a5 <alltraps>

80107443 <vector214>:
.globl vector214
vector214:
  pushl $0
80107443:	6a 00                	push   $0x0
  pushl $214
80107445:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010744a:	e9 56 f1 ff ff       	jmp    801065a5 <alltraps>

8010744f <vector215>:
.globl vector215
vector215:
  pushl $0
8010744f:	6a 00                	push   $0x0
  pushl $215
80107451:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107456:	e9 4a f1 ff ff       	jmp    801065a5 <alltraps>

8010745b <vector216>:
.globl vector216
vector216:
  pushl $0
8010745b:	6a 00                	push   $0x0
  pushl $216
8010745d:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107462:	e9 3e f1 ff ff       	jmp    801065a5 <alltraps>

80107467 <vector217>:
.globl vector217
vector217:
  pushl $0
80107467:	6a 00                	push   $0x0
  pushl $217
80107469:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
8010746e:	e9 32 f1 ff ff       	jmp    801065a5 <alltraps>

80107473 <vector218>:
.globl vector218
vector218:
  pushl $0
80107473:	6a 00                	push   $0x0
  pushl $218
80107475:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010747a:	e9 26 f1 ff ff       	jmp    801065a5 <alltraps>

8010747f <vector219>:
.globl vector219
vector219:
  pushl $0
8010747f:	6a 00                	push   $0x0
  pushl $219
80107481:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107486:	e9 1a f1 ff ff       	jmp    801065a5 <alltraps>

8010748b <vector220>:
.globl vector220
vector220:
  pushl $0
8010748b:	6a 00                	push   $0x0
  pushl $220
8010748d:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107492:	e9 0e f1 ff ff       	jmp    801065a5 <alltraps>

80107497 <vector221>:
.globl vector221
vector221:
  pushl $0
80107497:	6a 00                	push   $0x0
  pushl $221
80107499:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
8010749e:	e9 02 f1 ff ff       	jmp    801065a5 <alltraps>

801074a3 <vector222>:
.globl vector222
vector222:
  pushl $0
801074a3:	6a 00                	push   $0x0
  pushl $222
801074a5:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801074aa:	e9 f6 f0 ff ff       	jmp    801065a5 <alltraps>

801074af <vector223>:
.globl vector223
vector223:
  pushl $0
801074af:	6a 00                	push   $0x0
  pushl $223
801074b1:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801074b6:	e9 ea f0 ff ff       	jmp    801065a5 <alltraps>

801074bb <vector224>:
.globl vector224
vector224:
  pushl $0
801074bb:	6a 00                	push   $0x0
  pushl $224
801074bd:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801074c2:	e9 de f0 ff ff       	jmp    801065a5 <alltraps>

801074c7 <vector225>:
.globl vector225
vector225:
  pushl $0
801074c7:	6a 00                	push   $0x0
  pushl $225
801074c9:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801074ce:	e9 d2 f0 ff ff       	jmp    801065a5 <alltraps>

801074d3 <vector226>:
.globl vector226
vector226:
  pushl $0
801074d3:	6a 00                	push   $0x0
  pushl $226
801074d5:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801074da:	e9 c6 f0 ff ff       	jmp    801065a5 <alltraps>

801074df <vector227>:
.globl vector227
vector227:
  pushl $0
801074df:	6a 00                	push   $0x0
  pushl $227
801074e1:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801074e6:	e9 ba f0 ff ff       	jmp    801065a5 <alltraps>

801074eb <vector228>:
.globl vector228
vector228:
  pushl $0
801074eb:	6a 00                	push   $0x0
  pushl $228
801074ed:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801074f2:	e9 ae f0 ff ff       	jmp    801065a5 <alltraps>

801074f7 <vector229>:
.globl vector229
vector229:
  pushl $0
801074f7:	6a 00                	push   $0x0
  pushl $229
801074f9:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801074fe:	e9 a2 f0 ff ff       	jmp    801065a5 <alltraps>

80107503 <vector230>:
.globl vector230
vector230:
  pushl $0
80107503:	6a 00                	push   $0x0
  pushl $230
80107505:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
8010750a:	e9 96 f0 ff ff       	jmp    801065a5 <alltraps>

8010750f <vector231>:
.globl vector231
vector231:
  pushl $0
8010750f:	6a 00                	push   $0x0
  pushl $231
80107511:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107516:	e9 8a f0 ff ff       	jmp    801065a5 <alltraps>

8010751b <vector232>:
.globl vector232
vector232:
  pushl $0
8010751b:	6a 00                	push   $0x0
  pushl $232
8010751d:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107522:	e9 7e f0 ff ff       	jmp    801065a5 <alltraps>

80107527 <vector233>:
.globl vector233
vector233:
  pushl $0
80107527:	6a 00                	push   $0x0
  pushl $233
80107529:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010752e:	e9 72 f0 ff ff       	jmp    801065a5 <alltraps>

80107533 <vector234>:
.globl vector234
vector234:
  pushl $0
80107533:	6a 00                	push   $0x0
  pushl $234
80107535:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010753a:	e9 66 f0 ff ff       	jmp    801065a5 <alltraps>

8010753f <vector235>:
.globl vector235
vector235:
  pushl $0
8010753f:	6a 00                	push   $0x0
  pushl $235
80107541:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107546:	e9 5a f0 ff ff       	jmp    801065a5 <alltraps>

8010754b <vector236>:
.globl vector236
vector236:
  pushl $0
8010754b:	6a 00                	push   $0x0
  pushl $236
8010754d:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107552:	e9 4e f0 ff ff       	jmp    801065a5 <alltraps>

80107557 <vector237>:
.globl vector237
vector237:
  pushl $0
80107557:	6a 00                	push   $0x0
  pushl $237
80107559:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010755e:	e9 42 f0 ff ff       	jmp    801065a5 <alltraps>

80107563 <vector238>:
.globl vector238
vector238:
  pushl $0
80107563:	6a 00                	push   $0x0
  pushl $238
80107565:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010756a:	e9 36 f0 ff ff       	jmp    801065a5 <alltraps>

8010756f <vector239>:
.globl vector239
vector239:
  pushl $0
8010756f:	6a 00                	push   $0x0
  pushl $239
80107571:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107576:	e9 2a f0 ff ff       	jmp    801065a5 <alltraps>

8010757b <vector240>:
.globl vector240
vector240:
  pushl $0
8010757b:	6a 00                	push   $0x0
  pushl $240
8010757d:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107582:	e9 1e f0 ff ff       	jmp    801065a5 <alltraps>

80107587 <vector241>:
.globl vector241
vector241:
  pushl $0
80107587:	6a 00                	push   $0x0
  pushl $241
80107589:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
8010758e:	e9 12 f0 ff ff       	jmp    801065a5 <alltraps>

80107593 <vector242>:
.globl vector242
vector242:
  pushl $0
80107593:	6a 00                	push   $0x0
  pushl $242
80107595:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
8010759a:	e9 06 f0 ff ff       	jmp    801065a5 <alltraps>

8010759f <vector243>:
.globl vector243
vector243:
  pushl $0
8010759f:	6a 00                	push   $0x0
  pushl $243
801075a1:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801075a6:	e9 fa ef ff ff       	jmp    801065a5 <alltraps>

801075ab <vector244>:
.globl vector244
vector244:
  pushl $0
801075ab:	6a 00                	push   $0x0
  pushl $244
801075ad:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801075b2:	e9 ee ef ff ff       	jmp    801065a5 <alltraps>

801075b7 <vector245>:
.globl vector245
vector245:
  pushl $0
801075b7:	6a 00                	push   $0x0
  pushl $245
801075b9:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801075be:	e9 e2 ef ff ff       	jmp    801065a5 <alltraps>

801075c3 <vector246>:
.globl vector246
vector246:
  pushl $0
801075c3:	6a 00                	push   $0x0
  pushl $246
801075c5:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801075ca:	e9 d6 ef ff ff       	jmp    801065a5 <alltraps>

801075cf <vector247>:
.globl vector247
vector247:
  pushl $0
801075cf:	6a 00                	push   $0x0
  pushl $247
801075d1:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801075d6:	e9 ca ef ff ff       	jmp    801065a5 <alltraps>

801075db <vector248>:
.globl vector248
vector248:
  pushl $0
801075db:	6a 00                	push   $0x0
  pushl $248
801075dd:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801075e2:	e9 be ef ff ff       	jmp    801065a5 <alltraps>

801075e7 <vector249>:
.globl vector249
vector249:
  pushl $0
801075e7:	6a 00                	push   $0x0
  pushl $249
801075e9:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801075ee:	e9 b2 ef ff ff       	jmp    801065a5 <alltraps>

801075f3 <vector250>:
.globl vector250
vector250:
  pushl $0
801075f3:	6a 00                	push   $0x0
  pushl $250
801075f5:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801075fa:	e9 a6 ef ff ff       	jmp    801065a5 <alltraps>

801075ff <vector251>:
.globl vector251
vector251:
  pushl $0
801075ff:	6a 00                	push   $0x0
  pushl $251
80107601:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107606:	e9 9a ef ff ff       	jmp    801065a5 <alltraps>

8010760b <vector252>:
.globl vector252
vector252:
  pushl $0
8010760b:	6a 00                	push   $0x0
  pushl $252
8010760d:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107612:	e9 8e ef ff ff       	jmp    801065a5 <alltraps>

80107617 <vector253>:
.globl vector253
vector253:
  pushl $0
80107617:	6a 00                	push   $0x0
  pushl $253
80107619:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
8010761e:	e9 82 ef ff ff       	jmp    801065a5 <alltraps>

80107623 <vector254>:
.globl vector254
vector254:
  pushl $0
80107623:	6a 00                	push   $0x0
  pushl $254
80107625:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010762a:	e9 76 ef ff ff       	jmp    801065a5 <alltraps>

8010762f <vector255>:
.globl vector255
vector255:
  pushl $0
8010762f:	6a 00                	push   $0x0
  pushl $255
80107631:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107636:	e9 6a ef ff ff       	jmp    801065a5 <alltraps>

8010763b <lgdt>:
{
8010763b:	55                   	push   %ebp
8010763c:	89 e5                	mov    %esp,%ebp
8010763e:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80107641:	8b 45 0c             	mov    0xc(%ebp),%eax
80107644:	83 e8 01             	sub    $0x1,%eax
80107647:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010764b:	8b 45 08             	mov    0x8(%ebp),%eax
8010764e:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107652:	8b 45 08             	mov    0x8(%ebp),%eax
80107655:	c1 e8 10             	shr    $0x10,%eax
80107658:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
8010765c:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010765f:	0f 01 10             	lgdtl  (%eax)
}
80107662:	90                   	nop
80107663:	c9                   	leave  
80107664:	c3                   	ret    

80107665 <ltr>:
{
80107665:	55                   	push   %ebp
80107666:	89 e5                	mov    %esp,%ebp
80107668:	83 ec 04             	sub    $0x4,%esp
8010766b:	8b 45 08             	mov    0x8(%ebp),%eax
8010766e:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107672:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107676:	0f 00 d8             	ltr    %ax
}
80107679:	90                   	nop
8010767a:	c9                   	leave  
8010767b:	c3                   	ret    

8010767c <lcr3>:

static inline void
lcr3(uint val)
{
8010767c:	55                   	push   %ebp
8010767d:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010767f:	8b 45 08             	mov    0x8(%ebp),%eax
80107682:	0f 22 d8             	mov    %eax,%cr3
}
80107685:	90                   	nop
80107686:	5d                   	pop    %ebp
80107687:	c3                   	ret    

80107688 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107688:	55                   	push   %ebp
80107689:	89 e5                	mov    %esp,%ebp
8010768b:	83 ec 18             	sub    $0x18,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpuid()];
8010768e:	e8 4d cb ff ff       	call   801041e0 <cpuid>
80107693:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80107699:	05 00 38 11 80       	add    $0x80113800,%eax
8010769e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801076a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a4:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801076aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ad:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801076b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076b6:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801076ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076bd:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801076c1:	83 e2 f0             	and    $0xfffffff0,%edx
801076c4:	83 ca 0a             	or     $0xa,%edx
801076c7:	88 50 7d             	mov    %dl,0x7d(%eax)
801076ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076cd:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801076d1:	83 ca 10             	or     $0x10,%edx
801076d4:	88 50 7d             	mov    %dl,0x7d(%eax)
801076d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076da:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801076de:	83 e2 9f             	and    $0xffffff9f,%edx
801076e1:	88 50 7d             	mov    %dl,0x7d(%eax)
801076e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801076eb:	83 ca 80             	or     $0xffffff80,%edx
801076ee:	88 50 7d             	mov    %dl,0x7d(%eax)
801076f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076f4:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076f8:	83 ca 0f             	or     $0xf,%edx
801076fb:	88 50 7e             	mov    %dl,0x7e(%eax)
801076fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107701:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107705:	83 e2 ef             	and    $0xffffffef,%edx
80107708:	88 50 7e             	mov    %dl,0x7e(%eax)
8010770b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010770e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107712:	83 e2 df             	and    $0xffffffdf,%edx
80107715:	88 50 7e             	mov    %dl,0x7e(%eax)
80107718:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010771b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010771f:	83 ca 40             	or     $0x40,%edx
80107722:	88 50 7e             	mov    %dl,0x7e(%eax)
80107725:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107728:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010772c:	83 ca 80             	or     $0xffffff80,%edx
8010772f:	88 50 7e             	mov    %dl,0x7e(%eax)
80107732:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107735:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107739:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010773c:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107743:	ff ff 
80107745:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107748:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010774f:	00 00 
80107751:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107754:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
8010775b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010775e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107765:	83 e2 f0             	and    $0xfffffff0,%edx
80107768:	83 ca 02             	or     $0x2,%edx
8010776b:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107771:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107774:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010777b:	83 ca 10             	or     $0x10,%edx
8010777e:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107784:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107787:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010778e:	83 e2 9f             	and    $0xffffff9f,%edx
80107791:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107797:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010779a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801077a1:	83 ca 80             	or     $0xffffff80,%edx
801077a4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801077aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ad:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077b4:	83 ca 0f             	or     $0xf,%edx
801077b7:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c0:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077c7:	83 e2 ef             	and    $0xffffffef,%edx
801077ca:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d3:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077da:	83 e2 df             	and    $0xffffffdf,%edx
801077dd:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e6:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077ed:	83 ca 40             	or     $0x40,%edx
801077f0:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f9:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107800:	83 ca 80             	or     $0xffffff80,%edx
80107803:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107809:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780c:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107813:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107816:	66 c7 80 88 00 00 00 	movw   $0xffff,0x88(%eax)
8010781d:	ff ff 
8010781f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107822:	66 c7 80 8a 00 00 00 	movw   $0x0,0x8a(%eax)
80107829:	00 00 
8010782b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010782e:	c6 80 8c 00 00 00 00 	movb   $0x0,0x8c(%eax)
80107835:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107838:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
8010783f:	83 e2 f0             	and    $0xfffffff0,%edx
80107842:	83 ca 0a             	or     $0xa,%edx
80107845:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
8010784b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010784e:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
80107855:	83 ca 10             	or     $0x10,%edx
80107858:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
8010785e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107861:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
80107868:	83 ca 60             	or     $0x60,%edx
8010786b:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
80107871:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107874:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
8010787b:	83 ca 80             	or     $0xffffff80,%edx
8010787e:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
80107884:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107887:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
8010788e:	83 ca 0f             	or     $0xf,%edx
80107891:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
80107897:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010789a:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
801078a1:	83 e2 ef             	and    $0xffffffef,%edx
801078a4:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
801078aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ad:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
801078b4:	83 e2 df             	and    $0xffffffdf,%edx
801078b7:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
801078bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c0:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
801078c7:	83 ca 40             	or     $0x40,%edx
801078ca:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
801078d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d3:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
801078da:	83 ca 80             	or     $0xffffff80,%edx
801078dd:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
801078e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e6:	c6 80 8f 00 00 00 00 	movb   $0x0,0x8f(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801078ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078f0:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801078f7:	ff ff 
801078f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078fc:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107903:	00 00 
80107905:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107908:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010790f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107912:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107919:	83 e2 f0             	and    $0xfffffff0,%edx
8010791c:	83 ca 02             	or     $0x2,%edx
8010791f:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107925:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107928:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010792f:	83 ca 10             	or     $0x10,%edx
80107932:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107938:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010793b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107942:	83 ca 60             	or     $0x60,%edx
80107945:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010794b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010794e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107955:	83 ca 80             	or     $0xffffff80,%edx
80107958:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010795e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107961:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107968:	83 ca 0f             	or     $0xf,%edx
8010796b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107971:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107974:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010797b:	83 e2 ef             	and    $0xffffffef,%edx
8010797e:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107984:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107987:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010798e:	83 e2 df             	and    $0xffffffdf,%edx
80107991:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107997:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010799a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079a1:	83 ca 40             	or     $0x40,%edx
801079a4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ad:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079b4:	83 ca 80             	or     $0xffffff80,%edx
801079b7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c0:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
801079c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ca:	83 c0 70             	add    $0x70,%eax
801079cd:	83 ec 08             	sub    $0x8,%esp
801079d0:	6a 30                	push   $0x30
801079d2:	50                   	push   %eax
801079d3:	e8 63 fc ff ff       	call   8010763b <lgdt>
801079d8:	83 c4 10             	add    $0x10,%esp
}
801079db:	90                   	nop
801079dc:	c9                   	leave  
801079dd:	c3                   	ret    

801079de <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
801079de:	55                   	push   %ebp
801079df:	89 e5                	mov    %esp,%ebp
801079e1:	83 ec 18             	sub    $0x18,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801079e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801079e7:	c1 e8 16             	shr    $0x16,%eax
801079ea:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801079f1:	8b 45 08             	mov    0x8(%ebp),%eax
801079f4:	01 d0                	add    %edx,%eax
801079f6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801079f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801079fc:	8b 00                	mov    (%eax),%eax
801079fe:	83 e0 01             	and    $0x1,%eax
80107a01:	85 c0                	test   %eax,%eax
80107a03:	74 14                	je     80107a19 <walkpgdir+0x3b>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80107a05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a08:	8b 00                	mov    (%eax),%eax
80107a0a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107a0f:	05 00 00 00 80       	add    $0x80000000,%eax
80107a14:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107a17:	eb 42                	jmp    80107a5b <walkpgdir+0x7d>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107a19:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107a1d:	74 0e                	je     80107a2d <walkpgdir+0x4f>
80107a1f:	e8 5d b2 ff ff       	call   80102c81 <kalloc>
80107a24:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107a27:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107a2b:	75 07                	jne    80107a34 <walkpgdir+0x56>
      return 0;
80107a2d:	b8 00 00 00 00       	mov    $0x0,%eax
80107a32:	eb 3e                	jmp    80107a72 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107a34:	83 ec 04             	sub    $0x4,%esp
80107a37:	68 00 10 00 00       	push   $0x1000
80107a3c:	6a 00                	push   $0x0
80107a3e:	ff 75 f4             	pushl  -0xc(%ebp)
80107a41:	e8 b0 d7 ff ff       	call   801051f6 <memset>
80107a46:	83 c4 10             	add    $0x10,%esp
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80107a49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a4c:	05 00 00 00 80       	add    $0x80000000,%eax
80107a51:	83 c8 07             	or     $0x7,%eax
80107a54:	89 c2                	mov    %eax,%edx
80107a56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a59:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107a5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a5e:	c1 e8 0c             	shr    $0xc,%eax
80107a61:	25 ff 03 00 00       	and    $0x3ff,%eax
80107a66:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107a6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a70:	01 d0                	add    %edx,%eax
}
80107a72:	c9                   	leave  
80107a73:	c3                   	ret    

80107a74 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107a74:	55                   	push   %ebp
80107a75:	89 e5                	mov    %esp,%ebp
80107a77:	83 ec 18             	sub    $0x18,%esp
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80107a7a:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a7d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107a82:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107a85:	8b 55 0c             	mov    0xc(%ebp),%edx
80107a88:	8b 45 10             	mov    0x10(%ebp),%eax
80107a8b:	01 d0                	add    %edx,%eax
80107a8d:	83 e8 01             	sub    $0x1,%eax
80107a90:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107a95:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107a98:	83 ec 04             	sub    $0x4,%esp
80107a9b:	6a 01                	push   $0x1
80107a9d:	ff 75 f4             	pushl  -0xc(%ebp)
80107aa0:	ff 75 08             	pushl  0x8(%ebp)
80107aa3:	e8 36 ff ff ff       	call   801079de <walkpgdir>
80107aa8:	83 c4 10             	add    $0x10,%esp
80107aab:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107aae:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107ab2:	75 07                	jne    80107abb <mappages+0x47>
      return -1;
80107ab4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107ab9:	eb 47                	jmp    80107b02 <mappages+0x8e>
    if(*pte & PTE_P)
80107abb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107abe:	8b 00                	mov    (%eax),%eax
80107ac0:	83 e0 01             	and    $0x1,%eax
80107ac3:	85 c0                	test   %eax,%eax
80107ac5:	74 0d                	je     80107ad4 <mappages+0x60>
      panic("remap");
80107ac7:	83 ec 0c             	sub    $0xc,%esp
80107aca:	68 80 89 10 80       	push   $0x80108980
80107acf:	e8 c8 8a ff ff       	call   8010059c <panic>
    *pte = pa | perm | PTE_P;
80107ad4:	8b 45 18             	mov    0x18(%ebp),%eax
80107ad7:	0b 45 14             	or     0x14(%ebp),%eax
80107ada:	83 c8 01             	or     $0x1,%eax
80107add:	89 c2                	mov    %eax,%edx
80107adf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107ae2:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107ae4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ae7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107aea:	74 10                	je     80107afc <mappages+0x88>
      break;
    a += PGSIZE;
80107aec:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107af3:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107afa:	eb 9c                	jmp    80107a98 <mappages+0x24>
      break;
80107afc:	90                   	nop
  }
  return 0;
80107afd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107b02:	c9                   	leave  
80107b03:	c3                   	ret    

80107b04 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107b04:	55                   	push   %ebp
80107b05:	89 e5                	mov    %esp,%ebp
80107b07:	53                   	push   %ebx
80107b08:	83 ec 14             	sub    $0x14,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107b0b:	e8 71 b1 ff ff       	call   80102c81 <kalloc>
80107b10:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107b13:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107b17:	75 07                	jne    80107b20 <setupkvm+0x1c>
    return 0;
80107b19:	b8 00 00 00 00       	mov    $0x0,%eax
80107b1e:	eb 78                	jmp    80107b98 <setupkvm+0x94>
  memset(pgdir, 0, PGSIZE);
80107b20:	83 ec 04             	sub    $0x4,%esp
80107b23:	68 00 10 00 00       	push   $0x1000
80107b28:	6a 00                	push   $0x0
80107b2a:	ff 75 f0             	pushl  -0x10(%ebp)
80107b2d:	e8 c4 d6 ff ff       	call   801051f6 <memset>
80107b32:	83 c4 10             	add    $0x10,%esp
  if (P2V(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107b35:	c7 45 f4 80 b4 10 80 	movl   $0x8010b480,-0xc(%ebp)
80107b3c:	eb 4e                	jmp    80107b8c <setupkvm+0x88>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80107b3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b41:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0) {
80107b44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b47:	8b 50 04             	mov    0x4(%eax),%edx
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80107b4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b4d:	8b 58 08             	mov    0x8(%eax),%ebx
80107b50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b53:	8b 40 04             	mov    0x4(%eax),%eax
80107b56:	29 c3                	sub    %eax,%ebx
80107b58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b5b:	8b 00                	mov    (%eax),%eax
80107b5d:	83 ec 0c             	sub    $0xc,%esp
80107b60:	51                   	push   %ecx
80107b61:	52                   	push   %edx
80107b62:	53                   	push   %ebx
80107b63:	50                   	push   %eax
80107b64:	ff 75 f0             	pushl  -0x10(%ebp)
80107b67:	e8 08 ff ff ff       	call   80107a74 <mappages>
80107b6c:	83 c4 20             	add    $0x20,%esp
80107b6f:	85 c0                	test   %eax,%eax
80107b71:	79 15                	jns    80107b88 <setupkvm+0x84>
      freevm(pgdir);
80107b73:	83 ec 0c             	sub    $0xc,%esp
80107b76:	ff 75 f0             	pushl  -0x10(%ebp)
80107b79:	e8 f7 04 00 00       	call   80108075 <freevm>
80107b7e:	83 c4 10             	add    $0x10,%esp
      return 0;
80107b81:	b8 00 00 00 00       	mov    $0x0,%eax
80107b86:	eb 10                	jmp    80107b98 <setupkvm+0x94>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107b88:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107b8c:	81 7d f4 c0 b4 10 80 	cmpl   $0x8010b4c0,-0xc(%ebp)
80107b93:	72 a9                	jb     80107b3e <setupkvm+0x3a>
    }
  return pgdir;
80107b95:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107b98:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80107b9b:	c9                   	leave  
80107b9c:	c3                   	ret    

80107b9d <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107b9d:	55                   	push   %ebp
80107b9e:	89 e5                	mov    %esp,%ebp
80107ba0:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107ba3:	e8 5c ff ff ff       	call   80107b04 <setupkvm>
80107ba8:	a3 24 65 11 80       	mov    %eax,0x80116524
  switchkvm();
80107bad:	e8 03 00 00 00       	call   80107bb5 <switchkvm>
}
80107bb2:	90                   	nop
80107bb3:	c9                   	leave  
80107bb4:	c3                   	ret    

80107bb5 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107bb5:	55                   	push   %ebp
80107bb6:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80107bb8:	a1 24 65 11 80       	mov    0x80116524,%eax
80107bbd:	05 00 00 00 80       	add    $0x80000000,%eax
80107bc2:	50                   	push   %eax
80107bc3:	e8 b4 fa ff ff       	call   8010767c <lcr3>
80107bc8:	83 c4 04             	add    $0x4,%esp
}
80107bcb:	90                   	nop
80107bcc:	c9                   	leave  
80107bcd:	c3                   	ret    

80107bce <switchuvm>:
// Switch TSS and h/w page table to correspond to process p.
//switchuvm to tell the
//hardware to start using the target process’s page table
void
switchuvm(struct proc *p)
{
80107bce:	55                   	push   %ebp
80107bcf:	89 e5                	mov    %esp,%ebp
80107bd1:	56                   	push   %esi
80107bd2:	53                   	push   %ebx
80107bd3:	83 ec 10             	sub    $0x10,%esp
  if(p == 0)
80107bd6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107bda:	75 0d                	jne    80107be9 <switchuvm+0x1b>
    panic("switchuvm: no process");
80107bdc:	83 ec 0c             	sub    $0xc,%esp
80107bdf:	68 86 89 10 80       	push   $0x80108986
80107be4:	e8 b3 89 ff ff       	call   8010059c <panic>
  if(p->kstack == 0)
80107be9:	8b 45 08             	mov    0x8(%ebp),%eax
80107bec:	8b 40 08             	mov    0x8(%eax),%eax
80107bef:	85 c0                	test   %eax,%eax
80107bf1:	75 0d                	jne    80107c00 <switchuvm+0x32>
    panic("switchuvm: no kstack");
80107bf3:	83 ec 0c             	sub    $0xc,%esp
80107bf6:	68 9c 89 10 80       	push   $0x8010899c
80107bfb:	e8 9c 89 ff ff       	call   8010059c <panic>
  if(p->pgdir == 0)
80107c00:	8b 45 08             	mov    0x8(%ebp),%eax
80107c03:	8b 40 04             	mov    0x4(%eax),%eax
80107c06:	85 c0                	test   %eax,%eax
80107c08:	75 0d                	jne    80107c17 <switchuvm+0x49>
    panic("switchuvm: no pgdir");
80107c0a:	83 ec 0c             	sub    $0xc,%esp
80107c0d:	68 b1 89 10 80       	push   $0x801089b1
80107c12:	e8 85 89 ff ff       	call   8010059c <panic>

  pushcli();
80107c17:	e8 ce d4 ff ff       	call   801050ea <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80107c1c:	e8 e0 c5 ff ff       	call   80104201 <mycpu>
80107c21:	89 c3                	mov    %eax,%ebx
80107c23:	e8 d9 c5 ff ff       	call   80104201 <mycpu>
80107c28:	83 c0 08             	add    $0x8,%eax
80107c2b:	89 c6                	mov    %eax,%esi
80107c2d:	e8 cf c5 ff ff       	call   80104201 <mycpu>
80107c32:	83 c0 08             	add    $0x8,%eax
80107c35:	c1 e8 10             	shr    $0x10,%eax
80107c38:	88 45 f7             	mov    %al,-0x9(%ebp)
80107c3b:	e8 c1 c5 ff ff       	call   80104201 <mycpu>
80107c40:	83 c0 08             	add    $0x8,%eax
80107c43:	c1 e8 18             	shr    $0x18,%eax
80107c46:	89 c2                	mov    %eax,%edx
80107c48:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80107c4f:	67 00 
80107c51:	66 89 b3 9a 00 00 00 	mov    %si,0x9a(%ebx)
80107c58:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
80107c5c:	88 83 9c 00 00 00    	mov    %al,0x9c(%ebx)
80107c62:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107c69:	83 e0 f0             	and    $0xfffffff0,%eax
80107c6c:	83 c8 09             	or     $0x9,%eax
80107c6f:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107c75:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107c7c:	83 c8 10             	or     $0x10,%eax
80107c7f:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107c85:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107c8c:	83 e0 9f             	and    $0xffffff9f,%eax
80107c8f:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107c95:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107c9c:	83 c8 80             	or     $0xffffff80,%eax
80107c9f:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107ca5:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107cac:	83 e0 f0             	and    $0xfffffff0,%eax
80107caf:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107cb5:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107cbc:	83 e0 ef             	and    $0xffffffef,%eax
80107cbf:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107cc5:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107ccc:	83 e0 df             	and    $0xffffffdf,%eax
80107ccf:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107cd5:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107cdc:	83 c8 40             	or     $0x40,%eax
80107cdf:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107ce5:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107cec:	83 e0 7f             	and    $0x7f,%eax
80107cef:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107cf5:	88 93 9f 00 00 00    	mov    %dl,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80107cfb:	e8 01 c5 ff ff       	call   80104201 <mycpu>
80107d00:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d07:	83 e2 ef             	and    $0xffffffef,%edx
80107d0a:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80107d10:	e8 ec c4 ff ff       	call   80104201 <mycpu>
80107d15:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80107d1b:	8b 45 08             	mov    0x8(%ebp),%eax
80107d1e:	8b 40 08             	mov    0x8(%eax),%eax
80107d21:	89 c3                	mov    %eax,%ebx
80107d23:	e8 d9 c4 ff ff       	call   80104201 <mycpu>
80107d28:	89 c2                	mov    %eax,%edx
80107d2a:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
80107d30:	89 42 0c             	mov    %eax,0xc(%edx)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80107d33:	e8 c9 c4 ff ff       	call   80104201 <mycpu>
80107d38:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  //sets up a task state segment SEG_TSS that instructs the hardware to execute system calls and interrupts
  //on the process’s kernel stack. 
  ltr(SEG_TSS << 3);//Load Task Register
80107d3e:	83 ec 0c             	sub    $0xc,%esp
80107d41:	6a 28                	push   $0x28
80107d43:	e8 1d f9 ff ff       	call   80107665 <ltr>
80107d48:	83 c4 10             	add    $0x10,%esp
  lcr3(V2P(p->pgdir));  // switch to process's address space 
80107d4b:	8b 45 08             	mov    0x8(%ebp),%eax
80107d4e:	8b 40 04             	mov    0x4(%eax),%eax
80107d51:	05 00 00 00 80       	add    $0x80000000,%eax
80107d56:	83 ec 0c             	sub    $0xc,%esp
80107d59:	50                   	push   %eax
80107d5a:	e8 1d f9 ff ff       	call   8010767c <lcr3>
80107d5f:	83 c4 10             	add    $0x10,%esp
  popcli();
80107d62:	e8 d1 d3 ff ff       	call   80105138 <popcli>
}
80107d67:	90                   	nop
80107d68:	8d 65 f8             	lea    -0x8(%ebp),%esp
80107d6b:	5b                   	pop    %ebx
80107d6c:	5e                   	pop    %esi
80107d6d:	5d                   	pop    %ebp
80107d6e:	c3                   	ret    

80107d6f <inituvm>:
// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
//Userinit copies that binary into the new process’s memory by calling inituvm
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107d6f:	55                   	push   %ebp
80107d70:	89 e5                	mov    %esp,%ebp
80107d72:	83 ec 18             	sub    $0x18,%esp
  char *mem;

  if(sz >= PGSIZE)
80107d75:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107d7c:	76 0d                	jbe    80107d8b <inituvm+0x1c>
    panic("inituvm: more than a page");
80107d7e:	83 ec 0c             	sub    $0xc,%esp
80107d81:	68 c5 89 10 80       	push   $0x801089c5
80107d86:	e8 11 88 ff ff       	call   8010059c <panic>
  mem = kalloc();
80107d8b:	e8 f1 ae ff ff       	call   80102c81 <kalloc>
80107d90:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107d93:	83 ec 04             	sub    $0x4,%esp
80107d96:	68 00 10 00 00       	push   $0x1000
80107d9b:	6a 00                	push   $0x0
80107d9d:	ff 75 f4             	pushl  -0xc(%ebp)
80107da0:	e8 51 d4 ff ff       	call   801051f6 <memset>
80107da5:	83 c4 10             	add    $0x10,%esp
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80107da8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dab:	05 00 00 00 80       	add    $0x80000000,%eax
80107db0:	83 ec 0c             	sub    $0xc,%esp
80107db3:	6a 06                	push   $0x6
80107db5:	50                   	push   %eax
80107db6:	68 00 10 00 00       	push   $0x1000
80107dbb:	6a 00                	push   $0x0
80107dbd:	ff 75 08             	pushl  0x8(%ebp)
80107dc0:	e8 af fc ff ff       	call   80107a74 <mappages>
80107dc5:	83 c4 20             	add    $0x20,%esp
  memmove(mem, init, sz);
80107dc8:	83 ec 04             	sub    $0x4,%esp
80107dcb:	ff 75 10             	pushl  0x10(%ebp)
80107dce:	ff 75 0c             	pushl  0xc(%ebp)
80107dd1:	ff 75 f4             	pushl  -0xc(%ebp)
80107dd4:	e8 dc d4 ff ff       	call   801052b5 <memmove>
80107dd9:	83 c4 10             	add    $0x10,%esp
}
80107ddc:	90                   	nop
80107ddd:	c9                   	leave  
80107dde:	c3                   	ret    

80107ddf <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107ddf:	55                   	push   %ebp
80107de0:	89 e5                	mov    %esp,%ebp
80107de2:	83 ec 18             	sub    $0x18,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107de5:	8b 45 0c             	mov    0xc(%ebp),%eax
80107de8:	25 ff 0f 00 00       	and    $0xfff,%eax
80107ded:	85 c0                	test   %eax,%eax
80107def:	74 0d                	je     80107dfe <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107df1:	83 ec 0c             	sub    $0xc,%esp
80107df4:	68 e0 89 10 80       	push   $0x801089e0
80107df9:	e8 9e 87 ff ff       	call   8010059c <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107dfe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107e05:	e9 8f 00 00 00       	jmp    80107e99 <loaduvm+0xba>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107e0a:	8b 55 0c             	mov    0xc(%ebp),%edx
80107e0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e10:	01 d0                	add    %edx,%eax
80107e12:	83 ec 04             	sub    $0x4,%esp
80107e15:	6a 00                	push   $0x0
80107e17:	50                   	push   %eax
80107e18:	ff 75 08             	pushl  0x8(%ebp)
80107e1b:	e8 be fb ff ff       	call   801079de <walkpgdir>
80107e20:	83 c4 10             	add    $0x10,%esp
80107e23:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107e26:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107e2a:	75 0d                	jne    80107e39 <loaduvm+0x5a>
      panic("loaduvm: address should exist");
80107e2c:	83 ec 0c             	sub    $0xc,%esp
80107e2f:	68 03 8a 10 80       	push   $0x80108a03
80107e34:	e8 63 87 ff ff       	call   8010059c <panic>
    pa = PTE_ADDR(*pte);
80107e39:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107e3c:	8b 00                	mov    (%eax),%eax
80107e3e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e43:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107e46:	8b 45 18             	mov    0x18(%ebp),%eax
80107e49:	2b 45 f4             	sub    -0xc(%ebp),%eax
80107e4c:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107e51:	77 0b                	ja     80107e5e <loaduvm+0x7f>
      n = sz - i;
80107e53:	8b 45 18             	mov    0x18(%ebp),%eax
80107e56:	2b 45 f4             	sub    -0xc(%ebp),%eax
80107e59:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107e5c:	eb 07                	jmp    80107e65 <loaduvm+0x86>
    else
      n = PGSIZE;
80107e5e:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, P2V(pa), offset+i, n) != n)
80107e65:	8b 55 14             	mov    0x14(%ebp),%edx
80107e68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e6b:	01 d0                	add    %edx,%eax
80107e6d:	8b 55 e8             	mov    -0x18(%ebp),%edx
80107e70:	81 c2 00 00 00 80    	add    $0x80000000,%edx
80107e76:	ff 75 f0             	pushl  -0x10(%ebp)
80107e79:	50                   	push   %eax
80107e7a:	52                   	push   %edx
80107e7b:	ff 75 10             	pushl  0x10(%ebp)
80107e7e:	e8 6a a0 ff ff       	call   80101eed <readi>
80107e83:	83 c4 10             	add    $0x10,%esp
80107e86:	39 45 f0             	cmp    %eax,-0x10(%ebp)
80107e89:	74 07                	je     80107e92 <loaduvm+0xb3>
      return -1;
80107e8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107e90:	eb 18                	jmp    80107eaa <loaduvm+0xcb>
  for(i = 0; i < sz; i += PGSIZE){
80107e92:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107e99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e9c:	3b 45 18             	cmp    0x18(%ebp),%eax
80107e9f:	0f 82 65 ff ff ff    	jb     80107e0a <loaduvm+0x2b>
  }
  return 0;
80107ea5:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107eaa:	c9                   	leave  
80107eab:	c3                   	ret    

80107eac <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107eac:	55                   	push   %ebp
80107ead:	89 e5                	mov    %esp,%ebp
80107eaf:	83 ec 18             	sub    $0x18,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107eb2:	8b 45 10             	mov    0x10(%ebp),%eax
80107eb5:	85 c0                	test   %eax,%eax
80107eb7:	79 0a                	jns    80107ec3 <allocuvm+0x17>
    return 0;
80107eb9:	b8 00 00 00 00       	mov    $0x0,%eax
80107ebe:	e9 ec 00 00 00       	jmp    80107faf <allocuvm+0x103>
  if(newsz < oldsz)
80107ec3:	8b 45 10             	mov    0x10(%ebp),%eax
80107ec6:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107ec9:	73 08                	jae    80107ed3 <allocuvm+0x27>
    return oldsz;
80107ecb:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ece:	e9 dc 00 00 00       	jmp    80107faf <allocuvm+0x103>

  a = PGROUNDUP(oldsz);
80107ed3:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ed6:	05 ff 0f 00 00       	add    $0xfff,%eax
80107edb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ee0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107ee3:	e9 b8 00 00 00       	jmp    80107fa0 <allocuvm+0xf4>
    mem = kalloc();
80107ee8:	e8 94 ad ff ff       	call   80102c81 <kalloc>
80107eed:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107ef0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107ef4:	75 2e                	jne    80107f24 <allocuvm+0x78>
      cprintf("allocuvm out of memory\n");
80107ef6:	83 ec 0c             	sub    $0xc,%esp
80107ef9:	68 21 8a 10 80       	push   $0x80108a21
80107efe:	e8 f9 84 ff ff       	call   801003fc <cprintf>
80107f03:	83 c4 10             	add    $0x10,%esp
      deallocuvm(pgdir, newsz, oldsz);
80107f06:	83 ec 04             	sub    $0x4,%esp
80107f09:	ff 75 0c             	pushl  0xc(%ebp)
80107f0c:	ff 75 10             	pushl  0x10(%ebp)
80107f0f:	ff 75 08             	pushl  0x8(%ebp)
80107f12:	e8 9a 00 00 00       	call   80107fb1 <deallocuvm>
80107f17:	83 c4 10             	add    $0x10,%esp
      return 0;
80107f1a:	b8 00 00 00 00       	mov    $0x0,%eax
80107f1f:	e9 8b 00 00 00       	jmp    80107faf <allocuvm+0x103>
    }
    memset(mem, 0, PGSIZE);
80107f24:	83 ec 04             	sub    $0x4,%esp
80107f27:	68 00 10 00 00       	push   $0x1000
80107f2c:	6a 00                	push   $0x0
80107f2e:	ff 75 f0             	pushl  -0x10(%ebp)
80107f31:	e8 c0 d2 ff ff       	call   801051f6 <memset>
80107f36:	83 c4 10             	add    $0x10,%esp
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80107f39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f3c:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
80107f42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f45:	83 ec 0c             	sub    $0xc,%esp
80107f48:	6a 06                	push   $0x6
80107f4a:	52                   	push   %edx
80107f4b:	68 00 10 00 00       	push   $0x1000
80107f50:	50                   	push   %eax
80107f51:	ff 75 08             	pushl  0x8(%ebp)
80107f54:	e8 1b fb ff ff       	call   80107a74 <mappages>
80107f59:	83 c4 20             	add    $0x20,%esp
80107f5c:	85 c0                	test   %eax,%eax
80107f5e:	79 39                	jns    80107f99 <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
80107f60:	83 ec 0c             	sub    $0xc,%esp
80107f63:	68 39 8a 10 80       	push   $0x80108a39
80107f68:	e8 8f 84 ff ff       	call   801003fc <cprintf>
80107f6d:	83 c4 10             	add    $0x10,%esp
      deallocuvm(pgdir, newsz, oldsz);
80107f70:	83 ec 04             	sub    $0x4,%esp
80107f73:	ff 75 0c             	pushl  0xc(%ebp)
80107f76:	ff 75 10             	pushl  0x10(%ebp)
80107f79:	ff 75 08             	pushl  0x8(%ebp)
80107f7c:	e8 30 00 00 00       	call   80107fb1 <deallocuvm>
80107f81:	83 c4 10             	add    $0x10,%esp
      kfree(mem);
80107f84:	83 ec 0c             	sub    $0xc,%esp
80107f87:	ff 75 f0             	pushl  -0x10(%ebp)
80107f8a:	e8 58 ac ff ff       	call   80102be7 <kfree>
80107f8f:	83 c4 10             	add    $0x10,%esp
      return 0;
80107f92:	b8 00 00 00 00       	mov    $0x0,%eax
80107f97:	eb 16                	jmp    80107faf <allocuvm+0x103>
  for(; a < newsz; a += PGSIZE){
80107f99:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107fa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fa3:	3b 45 10             	cmp    0x10(%ebp),%eax
80107fa6:	0f 82 3c ff ff ff    	jb     80107ee8 <allocuvm+0x3c>
    }
  }
  return newsz;
80107fac:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107faf:	c9                   	leave  
80107fb0:	c3                   	ret    

80107fb1 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107fb1:	55                   	push   %ebp
80107fb2:	89 e5                	mov    %esp,%ebp
80107fb4:	83 ec 18             	sub    $0x18,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107fb7:	8b 45 10             	mov    0x10(%ebp),%eax
80107fba:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107fbd:	72 08                	jb     80107fc7 <deallocuvm+0x16>
    return oldsz;
80107fbf:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fc2:	e9 ac 00 00 00       	jmp    80108073 <deallocuvm+0xc2>

  a = PGROUNDUP(newsz);
80107fc7:	8b 45 10             	mov    0x10(%ebp),%eax
80107fca:	05 ff 0f 00 00       	add    $0xfff,%eax
80107fcf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107fd4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107fd7:	e9 88 00 00 00       	jmp    80108064 <deallocuvm+0xb3>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107fdc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fdf:	83 ec 04             	sub    $0x4,%esp
80107fe2:	6a 00                	push   $0x0
80107fe4:	50                   	push   %eax
80107fe5:	ff 75 08             	pushl  0x8(%ebp)
80107fe8:	e8 f1 f9 ff ff       	call   801079de <walkpgdir>
80107fed:	83 c4 10             	add    $0x10,%esp
80107ff0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107ff3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107ff7:	75 16                	jne    8010800f <deallocuvm+0x5e>
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80107ff9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ffc:	c1 e8 16             	shr    $0x16,%eax
80107fff:	83 c0 01             	add    $0x1,%eax
80108002:	c1 e0 16             	shl    $0x16,%eax
80108005:	2d 00 10 00 00       	sub    $0x1000,%eax
8010800a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010800d:	eb 4e                	jmp    8010805d <deallocuvm+0xac>
    else if((*pte & PTE_P) != 0){
8010800f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108012:	8b 00                	mov    (%eax),%eax
80108014:	83 e0 01             	and    $0x1,%eax
80108017:	85 c0                	test   %eax,%eax
80108019:	74 42                	je     8010805d <deallocuvm+0xac>
      pa = PTE_ADDR(*pte);
8010801b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010801e:	8b 00                	mov    (%eax),%eax
80108020:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108025:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108028:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010802c:	75 0d                	jne    8010803b <deallocuvm+0x8a>
        panic("kfree");
8010802e:	83 ec 0c             	sub    $0xc,%esp
80108031:	68 55 8a 10 80       	push   $0x80108a55
80108036:	e8 61 85 ff ff       	call   8010059c <panic>
      char *v = P2V(pa);
8010803b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010803e:	05 00 00 00 80       	add    $0x80000000,%eax
80108043:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108046:	83 ec 0c             	sub    $0xc,%esp
80108049:	ff 75 e8             	pushl  -0x18(%ebp)
8010804c:	e8 96 ab ff ff       	call   80102be7 <kfree>
80108051:	83 c4 10             	add    $0x10,%esp
      *pte = 0;
80108054:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108057:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  for(; a  < oldsz; a += PGSIZE){
8010805d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108064:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108067:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010806a:	0f 82 6c ff ff ff    	jb     80107fdc <deallocuvm+0x2b>
    }
  }
  return newsz;
80108070:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108073:	c9                   	leave  
80108074:	c3                   	ret    

80108075 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108075:	55                   	push   %ebp
80108076:	89 e5                	mov    %esp,%ebp
80108078:	83 ec 18             	sub    $0x18,%esp
  uint i;

  if(pgdir == 0)
8010807b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010807f:	75 0d                	jne    8010808e <freevm+0x19>
    panic("freevm: no pgdir");
80108081:	83 ec 0c             	sub    $0xc,%esp
80108084:	68 5b 8a 10 80       	push   $0x80108a5b
80108089:	e8 0e 85 ff ff       	call   8010059c <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010808e:	83 ec 04             	sub    $0x4,%esp
80108091:	6a 00                	push   $0x0
80108093:	68 00 00 00 80       	push   $0x80000000
80108098:	ff 75 08             	pushl  0x8(%ebp)
8010809b:	e8 11 ff ff ff       	call   80107fb1 <deallocuvm>
801080a0:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NPDENTRIES; i++){
801080a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801080aa:	eb 48                	jmp    801080f4 <freevm+0x7f>
    if(pgdir[i] & PTE_P){
801080ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080af:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801080b6:	8b 45 08             	mov    0x8(%ebp),%eax
801080b9:	01 d0                	add    %edx,%eax
801080bb:	8b 00                	mov    (%eax),%eax
801080bd:	83 e0 01             	and    $0x1,%eax
801080c0:	85 c0                	test   %eax,%eax
801080c2:	74 2c                	je     801080f0 <freevm+0x7b>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801080c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801080ce:	8b 45 08             	mov    0x8(%ebp),%eax
801080d1:	01 d0                	add    %edx,%eax
801080d3:	8b 00                	mov    (%eax),%eax
801080d5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801080da:	05 00 00 00 80       	add    $0x80000000,%eax
801080df:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801080e2:	83 ec 0c             	sub    $0xc,%esp
801080e5:	ff 75 f0             	pushl  -0x10(%ebp)
801080e8:	e8 fa aa ff ff       	call   80102be7 <kfree>
801080ed:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NPDENTRIES; i++){
801080f0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801080f4:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801080fb:	76 af                	jbe    801080ac <freevm+0x37>
    }
  }
  kfree((char*)pgdir);
801080fd:	83 ec 0c             	sub    $0xc,%esp
80108100:	ff 75 08             	pushl  0x8(%ebp)
80108103:	e8 df aa ff ff       	call   80102be7 <kfree>
80108108:	83 c4 10             	add    $0x10,%esp
}
8010810b:	90                   	nop
8010810c:	c9                   	leave  
8010810d:	c3                   	ret    

8010810e <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010810e:	55                   	push   %ebp
8010810f:	89 e5                	mov    %esp,%ebp
80108111:	83 ec 18             	sub    $0x18,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108114:	83 ec 04             	sub    $0x4,%esp
80108117:	6a 00                	push   $0x0
80108119:	ff 75 0c             	pushl  0xc(%ebp)
8010811c:	ff 75 08             	pushl  0x8(%ebp)
8010811f:	e8 ba f8 ff ff       	call   801079de <walkpgdir>
80108124:	83 c4 10             	add    $0x10,%esp
80108127:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010812a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010812e:	75 0d                	jne    8010813d <clearpteu+0x2f>
    panic("clearpteu");
80108130:	83 ec 0c             	sub    $0xc,%esp
80108133:	68 6c 8a 10 80       	push   $0x80108a6c
80108138:	e8 5f 84 ff ff       	call   8010059c <panic>
  *pte &= ~PTE_U;
8010813d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108140:	8b 00                	mov    (%eax),%eax
80108142:	83 e0 fb             	and    $0xfffffffb,%eax
80108145:	89 c2                	mov    %eax,%edx
80108147:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010814a:	89 10                	mov    %edx,(%eax)
}
8010814c:	90                   	nop
8010814d:	c9                   	leave  
8010814e:	c3                   	ret    

8010814f <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010814f:	55                   	push   %ebp
80108150:	89 e5                	mov    %esp,%ebp
80108152:	83 ec 28             	sub    $0x28,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108155:	e8 aa f9 ff ff       	call   80107b04 <setupkvm>
8010815a:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010815d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108161:	75 0a                	jne    8010816d <copyuvm+0x1e>
    return 0;
80108163:	b8 00 00 00 00       	mov    $0x0,%eax
80108168:	e9 f8 00 00 00       	jmp    80108265 <copyuvm+0x116>
  for(i = 0; i < sz; i += PGSIZE){
8010816d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108174:	e9 c7 00 00 00       	jmp    80108240 <copyuvm+0xf1>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108179:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817c:	83 ec 04             	sub    $0x4,%esp
8010817f:	6a 00                	push   $0x0
80108181:	50                   	push   %eax
80108182:	ff 75 08             	pushl  0x8(%ebp)
80108185:	e8 54 f8 ff ff       	call   801079de <walkpgdir>
8010818a:	83 c4 10             	add    $0x10,%esp
8010818d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108190:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108194:	75 0d                	jne    801081a3 <copyuvm+0x54>
      panic("copyuvm: pte should exist");
80108196:	83 ec 0c             	sub    $0xc,%esp
80108199:	68 76 8a 10 80       	push   $0x80108a76
8010819e:	e8 f9 83 ff ff       	call   8010059c <panic>
    if(!(*pte & PTE_P))
801081a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801081a6:	8b 00                	mov    (%eax),%eax
801081a8:	83 e0 01             	and    $0x1,%eax
801081ab:	85 c0                	test   %eax,%eax
801081ad:	75 0d                	jne    801081bc <copyuvm+0x6d>
      panic("copyuvm: page not present");
801081af:	83 ec 0c             	sub    $0xc,%esp
801081b2:	68 90 8a 10 80       	push   $0x80108a90
801081b7:	e8 e0 83 ff ff       	call   8010059c <panic>
    pa = PTE_ADDR(*pte);
801081bc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801081bf:	8b 00                	mov    (%eax),%eax
801081c1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081c6:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
801081c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801081cc:	8b 00                	mov    (%eax),%eax
801081ce:	25 ff 0f 00 00       	and    $0xfff,%eax
801081d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
801081d6:	e8 a6 aa ff ff       	call   80102c81 <kalloc>
801081db:	89 45 e0             	mov    %eax,-0x20(%ebp)
801081de:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801081e2:	74 6d                	je     80108251 <copyuvm+0x102>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801081e4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801081e7:	05 00 00 00 80       	add    $0x80000000,%eax
801081ec:	83 ec 04             	sub    $0x4,%esp
801081ef:	68 00 10 00 00       	push   $0x1000
801081f4:	50                   	push   %eax
801081f5:	ff 75 e0             	pushl  -0x20(%ebp)
801081f8:	e8 b8 d0 ff ff       	call   801052b5 <memmove>
801081fd:	83 c4 10             	add    $0x10,%esp
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
80108200:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80108203:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108206:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
8010820c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010820f:	83 ec 0c             	sub    $0xc,%esp
80108212:	52                   	push   %edx
80108213:	51                   	push   %ecx
80108214:	68 00 10 00 00       	push   $0x1000
80108219:	50                   	push   %eax
8010821a:	ff 75 f0             	pushl  -0x10(%ebp)
8010821d:	e8 52 f8 ff ff       	call   80107a74 <mappages>
80108222:	83 c4 20             	add    $0x20,%esp
80108225:	85 c0                	test   %eax,%eax
80108227:	79 10                	jns    80108239 <copyuvm+0xea>
      kfree(mem);
80108229:	83 ec 0c             	sub    $0xc,%esp
8010822c:	ff 75 e0             	pushl  -0x20(%ebp)
8010822f:	e8 b3 a9 ff ff       	call   80102be7 <kfree>
80108234:	83 c4 10             	add    $0x10,%esp
      goto bad;
80108237:	eb 19                	jmp    80108252 <copyuvm+0x103>
  for(i = 0; i < sz; i += PGSIZE){
80108239:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108240:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108243:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108246:	0f 82 2d ff ff ff    	jb     80108179 <copyuvm+0x2a>
    }
  }
  return d;
8010824c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010824f:	eb 14                	jmp    80108265 <copyuvm+0x116>
      goto bad;
80108251:	90                   	nop

bad:
  freevm(d);
80108252:	83 ec 0c             	sub    $0xc,%esp
80108255:	ff 75 f0             	pushl  -0x10(%ebp)
80108258:	e8 18 fe ff ff       	call   80108075 <freevm>
8010825d:	83 c4 10             	add    $0x10,%esp
  return 0;
80108260:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108265:	c9                   	leave  
80108266:	c3                   	ret    

80108267 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108267:	55                   	push   %ebp
80108268:	89 e5                	mov    %esp,%ebp
8010826a:	83 ec 18             	sub    $0x18,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010826d:	83 ec 04             	sub    $0x4,%esp
80108270:	6a 00                	push   $0x0
80108272:	ff 75 0c             	pushl  0xc(%ebp)
80108275:	ff 75 08             	pushl  0x8(%ebp)
80108278:	e8 61 f7 ff ff       	call   801079de <walkpgdir>
8010827d:	83 c4 10             	add    $0x10,%esp
80108280:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108283:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108286:	8b 00                	mov    (%eax),%eax
80108288:	83 e0 01             	and    $0x1,%eax
8010828b:	85 c0                	test   %eax,%eax
8010828d:	75 07                	jne    80108296 <uva2ka+0x2f>
    return 0;
8010828f:	b8 00 00 00 00       	mov    $0x0,%eax
80108294:	eb 22                	jmp    801082b8 <uva2ka+0x51>
  if((*pte & PTE_U) == 0)
80108296:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108299:	8b 00                	mov    (%eax),%eax
8010829b:	83 e0 04             	and    $0x4,%eax
8010829e:	85 c0                	test   %eax,%eax
801082a0:	75 07                	jne    801082a9 <uva2ka+0x42>
    return 0;
801082a2:	b8 00 00 00 00       	mov    $0x0,%eax
801082a7:	eb 0f                	jmp    801082b8 <uva2ka+0x51>
  return (char*)P2V(PTE_ADDR(*pte));
801082a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ac:	8b 00                	mov    (%eax),%eax
801082ae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801082b3:	05 00 00 00 80       	add    $0x80000000,%eax
}
801082b8:	c9                   	leave  
801082b9:	c3                   	ret    

801082ba <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801082ba:	55                   	push   %ebp
801082bb:	89 e5                	mov    %esp,%ebp
801082bd:	83 ec 18             	sub    $0x18,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801082c0:	8b 45 10             	mov    0x10(%ebp),%eax
801082c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801082c6:	eb 7f                	jmp    80108347 <copyout+0x8d>
    va0 = (uint)PGROUNDDOWN(va);
801082c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801082cb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801082d0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801082d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082d6:	83 ec 08             	sub    $0x8,%esp
801082d9:	50                   	push   %eax
801082da:	ff 75 08             	pushl  0x8(%ebp)
801082dd:	e8 85 ff ff ff       	call   80108267 <uva2ka>
801082e2:	83 c4 10             	add    $0x10,%esp
801082e5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801082e8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801082ec:	75 07                	jne    801082f5 <copyout+0x3b>
      return -1;
801082ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801082f3:	eb 61                	jmp    80108356 <copyout+0x9c>
    n = PGSIZE - (va - va0);
801082f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082f8:	2b 45 0c             	sub    0xc(%ebp),%eax
801082fb:	05 00 10 00 00       	add    $0x1000,%eax
80108300:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108303:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108306:	3b 45 14             	cmp    0x14(%ebp),%eax
80108309:	76 06                	jbe    80108311 <copyout+0x57>
      n = len;
8010830b:	8b 45 14             	mov    0x14(%ebp),%eax
8010830e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108311:	8b 45 0c             	mov    0xc(%ebp),%eax
80108314:	2b 45 ec             	sub    -0x14(%ebp),%eax
80108317:	89 c2                	mov    %eax,%edx
80108319:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010831c:	01 d0                	add    %edx,%eax
8010831e:	83 ec 04             	sub    $0x4,%esp
80108321:	ff 75 f0             	pushl  -0x10(%ebp)
80108324:	ff 75 f4             	pushl  -0xc(%ebp)
80108327:	50                   	push   %eax
80108328:	e8 88 cf ff ff       	call   801052b5 <memmove>
8010832d:	83 c4 10             	add    $0x10,%esp
    len -= n;
80108330:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108333:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108336:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108339:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010833c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010833f:	05 00 10 00 00       	add    $0x1000,%eax
80108344:	89 45 0c             	mov    %eax,0xc(%ebp)
  while(len > 0){
80108347:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010834b:	0f 85 77 ff ff ff    	jne    801082c8 <copyout+0xe>
  }
  return 0;
80108351:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108356:	c9                   	leave  
80108357:	c3                   	ret    
