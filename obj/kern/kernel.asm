
obj/kern/kernel：     文件格式 elf32-i386


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
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
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
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

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
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 40 1a 10 f0 	movl   $0xf0101a40,(%esp)
f0100055:	e8 66 09 00 00       	call   f01009c0 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 0b 07 00 00       	call   f0100792 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 5c 1a 10 f0 	movl   $0xf0101a5c,(%esp)
f0100092:	e8 29 09 00 00       	call   f01009c0 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 9a 14 00 00       	call   f010155f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 8e 04 00 00       	call   f0100558 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 77 1a 10 f0 	movl   $0xf0101a77,(%esp)
f01000d9:	e8 e2 08 00 00       	call   f01009c0 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 40 07 00 00       	call   f0100836 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 92 1a 10 f0 	movl   $0xf0101a92,(%esp)
f010012c:	e8 8f 08 00 00       	call   f01009c0 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 50 08 00 00       	call   f010098d <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ce 1a 10 f0 	movl   $0xf0101ace,(%esp)
f0100144:	e8 77 08 00 00       	call   f01009c0 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 e1 06 00 00       	call   f0100836 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 aa 1a 10 f0 	movl   $0xf0101aaa,(%esp)
f0100176:	e8 45 08 00 00       	call   f01009c0 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 03 08 00 00       	call   f010098d <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ce 1a 10 f0 	movl   $0xf0101ace,(%esp)
f0100191:	e8 2a 08 00 00       	call   f01009c0 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001d9:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 20 1c 10 f0 	movzbl -0xfefe3e0(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 20 1c 10 f0 	movzbl -0xfefe3e0(%edx),%eax
f0100289:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 00 1b 10 f0 	mov    -0xfefe500(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 c4 1a 10 f0 	movl   $0xf0101ac4,(%esp)
f01002e9:	e8 d2 06 00 00       	call   f01009c0 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100315:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010031a:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010031b:	a8 20                	test   $0x20,%al
f010031d:	75 21                	jne    f0100340 <cons_putc+0x37>
f010031f:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100324:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100329:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032e:	89 ca                	mov    %ecx,%edx
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	ec                   	in     (%dx),%al
f0100334:	89 f2                	mov    %esi,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	a8 20                	test   $0x20,%al
f0100339:	75 05                	jne    f0100340 <cons_putc+0x37>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033b:	83 eb 01             	sub    $0x1,%ebx
f010033e:	75 ee                	jne    f010032e <cons_putc+0x25>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f0100340:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100344:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100349:	89 f8                	mov    %edi,%eax
f010034b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034c:	b2 79                	mov    $0x79,%dl
f010034e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010034f:	84 c0                	test   %al,%al
f0100351:	78 21                	js     f0100374 <cons_putc+0x6b>
f0100353:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100358:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035d:	be 79 03 00 00       	mov    $0x379,%esi
f0100362:	89 ca                	mov    %ecx,%edx
f0100364:	ec                   	in     (%dx),%al
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	89 f2                	mov    %esi,%edx
f010036a:	ec                   	in     (%dx),%al
f010036b:	84 c0                	test   %al,%al
f010036d:	78 05                	js     f0100374 <cons_putc+0x6b>
f010036f:	83 eb 01             	sub    $0x1,%ebx
f0100372:	75 ee                	jne    f0100362 <cons_putc+0x59>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100374:	ba 78 03 00 00       	mov    $0x378,%edx
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	ee                   	out    %al,(%dx)
f010037c:	b2 7a                	mov    $0x7a,%dl
f010037e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100383:	ee                   	out    %al,(%dx)
f0100384:	b8 08 00 00 00       	mov    $0x8,%eax
f0100389:	ee                   	out    %al,(%dx)
static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	// if (!(c & ~0xFF))
		c |= 0x0400;
f010038a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010038d:	80 cc 04             	or     $0x4,%ah

	switch (c & 0xff) {
f0100390:	83 ff 09             	cmp    $0x9,%edi
f0100393:	74 76                	je     f010040b <cons_putc+0x102>
f0100395:	83 ff 09             	cmp    $0x9,%edi
f0100398:	7f 0b                	jg     f01003a5 <cons_putc+0x9c>
f010039a:	83 ff 08             	cmp    $0x8,%edi
f010039d:	74 18                	je     f01003b7 <cons_putc+0xae>
f010039f:	90                   	nop
f01003a0:	e9 9a 00 00 00       	jmp    f010043f <cons_putc+0x136>
f01003a5:	83 ff 0a             	cmp    $0xa,%edi
f01003a8:	74 3b                	je     f01003e5 <cons_putc+0xdc>
f01003aa:	83 ff 0d             	cmp    $0xd,%edi
f01003ad:	8d 76 00             	lea    0x0(%esi),%esi
f01003b0:	74 3b                	je     f01003ed <cons_putc+0xe4>
f01003b2:	e9 88 00 00 00       	jmp    f010043f <cons_putc+0x136>
	case '\b':
		if (crt_pos > 0) {
f01003b7:	0f b7 15 48 25 11 f0 	movzwl 0xf0112548,%edx
f01003be:	66 85 d2             	test   %dx,%dx
f01003c1:	0f 84 e3 00 00 00    	je     f01004aa <cons_putc+0x1a1>
			crt_pos--;
f01003c7:	83 ea 01             	sub    $0x1,%edx
f01003ca:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d1:	0f b7 d2             	movzwl %dx,%edx
f01003d4:	b0 00                	mov    $0x0,%al
f01003d6:	83 c8 20             	or     $0x20,%eax
f01003d9:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01003df:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01003e3:	eb 78                	jmp    f010045d <cons_putc+0x154>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003e5:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f01003ec:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003ed:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003f4:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003fa:	c1 e8 16             	shr    $0x16,%eax
f01003fd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100400:	c1 e0 04             	shl    $0x4,%eax
f0100403:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f0100409:	eb 52                	jmp    f010045d <cons_putc+0x154>
		break;
	case '\t':
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 f4 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 ea fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 e0 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100429:	b8 20 00 00 00       	mov    $0x20,%eax
f010042e:	e8 d6 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100433:	b8 20 00 00 00       	mov    $0x20,%eax
f0100438:	e8 cc fe ff ff       	call   f0100309 <cons_putc>
f010043d:	eb 1e                	jmp    f010045d <cons_putc+0x154>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010043f:	0f b7 15 48 25 11 f0 	movzwl 0xf0112548,%edx
f0100446:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100449:	66 89 0d 48 25 11 f0 	mov    %cx,0xf0112548
f0100450:	0f b7 d2             	movzwl %dx,%edx
f0100453:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f0100459:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010045d:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f0100464:	cf 07 
f0100466:	76 42                	jbe    f01004aa <cons_putc+0x1a1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100468:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f010046d:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100474:	00 
f0100475:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010047b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010047f:	89 04 24             	mov    %eax,(%esp)
f0100482:	e8 25 11 00 00       	call   f01015ac <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100487:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048d:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100492:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100498:	83 c0 01             	add    $0x1,%eax
f010049b:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004a0:	75 f0                	jne    f0100492 <cons_putc+0x189>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004a2:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f01004a9:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004aa:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01004b0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004b5:	89 ca                	mov    %ecx,%edx
f01004b7:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004b8:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004bf:	8d 71 01             	lea    0x1(%ecx),%esi
f01004c2:	89 d8                	mov    %ebx,%eax
f01004c4:	66 c1 e8 08          	shr    $0x8,%ax
f01004c8:	89 f2                	mov    %esi,%edx
f01004ca:	ee                   	out    %al,(%dx)
f01004cb:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004d0:	89 ca                	mov    %ecx,%edx
f01004d2:	ee                   	out    %al,(%dx)
f01004d3:	89 d8                	mov    %ebx,%eax
f01004d5:	89 f2                	mov    %esi,%edx
f01004d7:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004d8:	83 c4 1c             	add    $0x1c,%esp
f01004db:	5b                   	pop    %ebx
f01004dc:	5e                   	pop    %esi
f01004dd:	5f                   	pop    %edi
f01004de:	5d                   	pop    %ebp
f01004df:	c3                   	ret    

f01004e0 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004e0:	83 3d 54 25 11 f0 00 	cmpl   $0x0,0xf0112554
f01004e7:	74 11                	je     f01004fa <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ef:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004f4:	e8 c3 fc ff ff       	call   f01001bc <cons_intr>
}
f01004f9:	c9                   	leave  
f01004fa:	f3 c3                	repz ret 

f01004fc <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004fc:	55                   	push   %ebp
f01004fd:	89 e5                	mov    %esp,%ebp
f01004ff:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100502:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f0100507:	e8 b0 fc ff ff       	call   f01001bc <cons_intr>
}
f010050c:	c9                   	leave  
f010050d:	c3                   	ret    

f010050e <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010050e:	55                   	push   %ebp
f010050f:	89 e5                	mov    %esp,%ebp
f0100511:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100514:	e8 c7 ff ff ff       	call   f01004e0 <serial_intr>
	kbd_intr();
f0100519:	e8 de ff ff ff       	call   f01004fc <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010051e:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f0100523:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100529:	74 26                	je     f0100551 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010052b:	8d 50 01             	lea    0x1(%eax),%edx
f010052e:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f0100534:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010053b:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010053d:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100543:	75 11                	jne    f0100556 <cons_getc+0x48>
			cons.rpos = 0;
f0100545:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f010054c:	00 00 00 
f010054f:	eb 05                	jmp    f0100556 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100551:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100556:	c9                   	leave  
f0100557:	c3                   	ret    

f0100558 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100558:	55                   	push   %ebp
f0100559:	89 e5                	mov    %esp,%ebp
f010055b:	57                   	push   %edi
f010055c:	56                   	push   %esi
f010055d:	53                   	push   %ebx
f010055e:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100561:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100568:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056f:	5a a5 
	if (*cp != 0xA55A) {
f0100571:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100578:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010057c:	74 11                	je     f010058f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010057e:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f0100585:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100588:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010058d:	eb 16                	jmp    f01005a5 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100596:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f010059d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a0:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a5:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01005ab:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b0:	89 ca                	mov    %ecx,%edx
f01005b2:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005b3:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b6:	89 da                	mov    %ebx,%edx
f01005b8:	ec                   	in     (%dx),%al
f01005b9:	0f b6 f0             	movzbl %al,%esi
f01005bc:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005bf:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c4:	89 ca                	mov    %ecx,%edx
f01005c6:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c7:	89 da                	mov    %ebx,%edx
f01005c9:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ca:	89 3d 4c 25 11 f0    	mov    %edi,0xf011254c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d0:	0f b6 d8             	movzbl %al,%ebx
f01005d3:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005d5:	66 89 35 48 25 11 f0 	mov    %si,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005dc:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e6:	89 f2                	mov    %esi,%edx
f01005e8:	ee                   	out    %al,(%dx)
f01005e9:	b2 fb                	mov    $0xfb,%dl
f01005eb:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f0:	ee                   	out    %al,(%dx)
f01005f1:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005f6:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005fb:	89 da                	mov    %ebx,%edx
f01005fd:	ee                   	out    %al,(%dx)
f01005fe:	b2 f9                	mov    $0xf9,%dl
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	ee                   	out    %al,(%dx)
f0100606:	b2 fb                	mov    $0xfb,%dl
f0100608:	b8 03 00 00 00       	mov    $0x3,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	b2 fc                	mov    $0xfc,%dl
f0100610:	b8 00 00 00 00       	mov    $0x0,%eax
f0100615:	ee                   	out    %al,(%dx)
f0100616:	b2 f9                	mov    $0xf9,%dl
f0100618:	b8 01 00 00 00       	mov    $0x1,%eax
f010061d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010061e:	b2 fd                	mov    $0xfd,%dl
f0100620:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100621:	3c ff                	cmp    $0xff,%al
f0100623:	0f 95 c1             	setne  %cl
f0100626:	0f b6 c9             	movzbl %cl,%ecx
f0100629:	89 0d 54 25 11 f0    	mov    %ecx,0xf0112554
f010062f:	89 f2                	mov    %esi,%edx
f0100631:	ec                   	in     (%dx),%al
f0100632:	89 da                	mov    %ebx,%edx
f0100634:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100635:	85 c9                	test   %ecx,%ecx
f0100637:	75 0c                	jne    f0100645 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100639:	c7 04 24 d0 1a 10 f0 	movl   $0xf0101ad0,(%esp)
f0100640:	e8 7b 03 00 00       	call   f01009c0 <cprintf>
}
f0100645:	83 c4 1c             	add    $0x1c,%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5f                   	pop    %edi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100653:	8b 45 08             	mov    0x8(%ebp),%eax
f0100656:	e8 ae fc ff ff       	call   f0100309 <cons_putc>
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <getchar>:

int
getchar(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100663:	e8 a6 fe ff ff       	call   f010050e <cons_getc>
f0100668:	85 c0                	test   %eax,%eax
f010066a:	74 f7                	je     f0100663 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <iscons>:

int
iscons(int fdnum)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100671:	b8 01 00 00 00       	mov    $0x1,%eax
f0100676:	5d                   	pop    %ebp
f0100677:	c3                   	ret    
f0100678:	66 90                	xchg   %ax,%ax
f010067a:	66 90                	xchg   %ax,%ax
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 cf 1a 10 	movl   $0xf0101acf,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 20 1d 10 	movl   $0xf0101d20,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 2a 1d 10 f0 	movl   $0xf0101d2a,(%esp)
f010069d:	e8 1e 03 00 00       	call   f01009c0 <cprintf>
f01006a2:	c7 44 24 08 33 1d 10 	movl   $0xf0101d33,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 51 1d 10 	movl   $0xf0101d51,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 2a 1d 10 f0 	movl   $0xf0101d2a,(%esp)
f01006b9:	e8 02 03 00 00       	call   f01009c0 <cprintf>
f01006be:	c7 44 24 08 e8 1d 10 	movl   $0xf0101de8,0x8(%esp)
f01006c5:	f0 
f01006c6:	c7 44 24 04 56 1d 10 	movl   $0xf0101d56,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 2a 1d 10 f0 	movl   $0xf0101d2a,(%esp)
f01006d5:	e8 e6 02 00 00       	call   f01009c0 <cprintf>
	return 0;
}
f01006da:	b8 00 00 00 00       	mov    $0x0,%eax
f01006df:	c9                   	leave  
f01006e0:	c3                   	ret    

f01006e1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006e1:	55                   	push   %ebp
f01006e2:	89 e5                	mov    %esp,%ebp
f01006e4:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006e7:	c7 04 24 5f 1d 10 f0 	movl   $0xf0101d5f,(%esp)
f01006ee:	e8 cd 02 00 00       	call   f01009c0 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006f3:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006fa:	00 
f01006fb:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100702:	f0 
f0100703:	c7 04 24 10 1e 10 f0 	movl   $0xf0101e10,(%esp)
f010070a:	e8 b1 02 00 00       	call   f01009c0 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010070f:	c7 44 24 08 27 1a 10 	movl   $0x101a27,0x8(%esp)
f0100716:	00 
f0100717:	c7 44 24 04 27 1a 10 	movl   $0xf0101a27,0x4(%esp)
f010071e:	f0 
f010071f:	c7 04 24 34 1e 10 f0 	movl   $0xf0101e34,(%esp)
f0100726:	e8 95 02 00 00       	call   f01009c0 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010072b:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100732:	00 
f0100733:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010073a:	f0 
f010073b:	c7 04 24 58 1e 10 f0 	movl   $0xf0101e58,(%esp)
f0100742:	e8 79 02 00 00       	call   f01009c0 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100747:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f010074e:	00 
f010074f:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100756:	f0 
f0100757:	c7 04 24 7c 1e 10 f0 	movl   $0xf0101e7c,(%esp)
f010075e:	e8 5d 02 00 00       	call   f01009c0 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100763:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100768:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010076d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100773:	85 c0                	test   %eax,%eax
f0100775:	0f 48 c2             	cmovs  %edx,%eax
f0100778:	c1 f8 0a             	sar    $0xa,%eax
f010077b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077f:	c7 04 24 a0 1e 10 f0 	movl   $0xf0101ea0,(%esp)
f0100786:	e8 35 02 00 00       	call   f01009c0 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010078b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100790:	c9                   	leave  
f0100791:	c3                   	ret    

f0100792 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100792:	55                   	push   %ebp
f0100793:	89 e5                	mov    %esp,%ebp
f0100795:	56                   	push   %esi
f0100796:	53                   	push   %ebx
f0100797:	83 ec 10             	sub    $0x10,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010079a:	89 ee                	mov    %ebp,%esi
	// Your code here.
	volatile uint32_t* ebp = (uint32_t*)read_ebp();
f010079c:	89 f3                	mov    %esi,%ebx
	// uint32_t* esp = (uint32_t*)read_esp();
	cprintf("Stack backtrace:\n");
f010079e:	c7 04 24 78 1d 10 f0 	movl   $0xf0101d78,(%esp)
f01007a5:	e8 16 02 00 00       	call   f01009c0 <cprintf>
	while(ebp)
f01007aa:	85 f6                	test   %esi,%esi
f01007ac:	74 7c                	je     f010082a <mon_backtrace+0x98>
	{
		cprintf("ebp %x, eip %x args", ebp, ebp[1]);
f01007ae:	8b 43 04             	mov    0x4(%ebx),%eax
f01007b1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007b5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007b9:	c7 04 24 8a 1d 10 f0 	movl   $0xf0101d8a,(%esp)
f01007c0:	e8 fb 01 00 00       	call   f01009c0 <cprintf>
		cprintf(" %08x", ebp[2]);
f01007c5:	8b 43 08             	mov    0x8(%ebx),%eax
f01007c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007cc:	c7 04 24 9e 1d 10 f0 	movl   $0xf0101d9e,(%esp)
f01007d3:	e8 e8 01 00 00       	call   f01009c0 <cprintf>
		cprintf(" %08x", ebp[3]);
f01007d8:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007df:	c7 04 24 9e 1d 10 f0 	movl   $0xf0101d9e,(%esp)
f01007e6:	e8 d5 01 00 00       	call   f01009c0 <cprintf>
		cprintf(" %08x", ebp[4]);
f01007eb:	8b 43 10             	mov    0x10(%ebx),%eax
f01007ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f2:	c7 04 24 9e 1d 10 f0 	movl   $0xf0101d9e,(%esp)
f01007f9:	e8 c2 01 00 00       	call   f01009c0 <cprintf>
		cprintf(" %08x", ebp[5]);
f01007fe:	8b 43 14             	mov    0x14(%ebx),%eax
f0100801:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100805:	c7 04 24 9e 1d 10 f0 	movl   $0xf0101d9e,(%esp)
f010080c:	e8 af 01 00 00       	call   f01009c0 <cprintf>
		cprintf(" %08x\n", ebp[6]);
f0100811:	8b 43 18             	mov    0x18(%ebx),%eax
f0100814:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100818:	c7 04 24 a4 1d 10 f0 	movl   $0xf0101da4,(%esp)
f010081f:	e8 9c 01 00 00       	call   f01009c0 <cprintf>
		// cprintf("----->  esp: %x", esp);
		ebp = (uint32_t*) *ebp;
f0100824:	8b 1b                	mov    (%ebx),%ebx
{
	// Your code here.
	volatile uint32_t* ebp = (uint32_t*)read_ebp();
	// uint32_t* esp = (uint32_t*)read_esp();
	cprintf("Stack backtrace:\n");
	while(ebp)
f0100826:	85 db                	test   %ebx,%ebx
f0100828:	75 84                	jne    f01007ae <mon_backtrace+0x1c>
		// cprintf("=====>  esp: %x \n", esp);
		// cprintf("=====> *ebp: %x \n", *ebp);
		// cprintf("=====> *esp: %x \n", *esp);
	}
	return 0;
}
f010082a:	b8 00 00 00 00       	mov    $0x0,%eax
f010082f:	83 c4 10             	add    $0x10,%esp
f0100832:	5b                   	pop    %ebx
f0100833:	5e                   	pop    %esi
f0100834:	5d                   	pop    %ebp
f0100835:	c3                   	ret    

f0100836 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100836:	55                   	push   %ebp
f0100837:	89 e5                	mov    %esp,%ebp
f0100839:	57                   	push   %edi
f010083a:	56                   	push   %esi
f010083b:	53                   	push   %ebx
f010083c:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010083f:	c7 04 24 cc 1e 10 f0 	movl   $0xf0101ecc,(%esp)
f0100846:	e8 75 01 00 00       	call   f01009c0 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010084b:	c7 04 24 f0 1e 10 f0 	movl   $0xf0101ef0,(%esp)
f0100852:	e8 69 01 00 00       	call   f01009c0 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100857:	c7 04 24 ab 1d 10 f0 	movl   $0xf0101dab,(%esp)
f010085e:	e8 4d 0a 00 00       	call   f01012b0 <readline>
f0100863:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100865:	85 c0                	test   %eax,%eax
f0100867:	74 ee                	je     f0100857 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100869:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100870:	be 00 00 00 00       	mov    $0x0,%esi
f0100875:	eb 0a                	jmp    f0100881 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100877:	c6 03 00             	movb   $0x0,(%ebx)
f010087a:	89 f7                	mov    %esi,%edi
f010087c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010087f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100881:	0f b6 03             	movzbl (%ebx),%eax
f0100884:	84 c0                	test   %al,%al
f0100886:	74 6a                	je     f01008f2 <monitor+0xbc>
f0100888:	0f be c0             	movsbl %al,%eax
f010088b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088f:	c7 04 24 af 1d 10 f0 	movl   $0xf0101daf,(%esp)
f0100896:	e8 63 0c 00 00       	call   f01014fe <strchr>
f010089b:	85 c0                	test   %eax,%eax
f010089d:	75 d8                	jne    f0100877 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010089f:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a2:	74 4e                	je     f01008f2 <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a4:	83 fe 0f             	cmp    $0xf,%esi
f01008a7:	75 16                	jne    f01008bf <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a9:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008b0:	00 
f01008b1:	c7 04 24 b4 1d 10 f0 	movl   $0xf0101db4,(%esp)
f01008b8:	e8 03 01 00 00       	call   f01009c0 <cprintf>
f01008bd:	eb 98                	jmp    f0100857 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008bf:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c2:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01008c6:	0f b6 03             	movzbl (%ebx),%eax
f01008c9:	84 c0                	test   %al,%al
f01008cb:	75 0c                	jne    f01008d9 <monitor+0xa3>
f01008cd:	eb b0                	jmp    f010087f <monitor+0x49>
			buf++;
f01008cf:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d2:	0f b6 03             	movzbl (%ebx),%eax
f01008d5:	84 c0                	test   %al,%al
f01008d7:	74 a6                	je     f010087f <monitor+0x49>
f01008d9:	0f be c0             	movsbl %al,%eax
f01008dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e0:	c7 04 24 af 1d 10 f0 	movl   $0xf0101daf,(%esp)
f01008e7:	e8 12 0c 00 00       	call   f01014fe <strchr>
f01008ec:	85 c0                	test   %eax,%eax
f01008ee:	74 df                	je     f01008cf <monitor+0x99>
f01008f0:	eb 8d                	jmp    f010087f <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008f2:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f9:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008fa:	85 f6                	test   %esi,%esi
f01008fc:	0f 84 55 ff ff ff    	je     f0100857 <monitor+0x21>
f0100902:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100907:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010090a:	8b 04 85 20 1f 10 f0 	mov    -0xfefe0e0(,%eax,4),%eax
f0100911:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100915:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100918:	89 04 24             	mov    %eax,(%esp)
f010091b:	e8 5a 0b 00 00       	call   f010147a <strcmp>
f0100920:	85 c0                	test   %eax,%eax
f0100922:	75 24                	jne    f0100948 <monitor+0x112>
			return commands[i].func(argc, argv, tf);
f0100924:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100927:	8b 55 08             	mov    0x8(%ebp),%edx
f010092a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010092e:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100931:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100935:	89 34 24             	mov    %esi,(%esp)
f0100938:	ff 14 85 28 1f 10 f0 	call   *-0xfefe0d8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010093f:	85 c0                	test   %eax,%eax
f0100941:	78 27                	js     f010096a <monitor+0x134>
f0100943:	e9 0f ff ff ff       	jmp    f0100857 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100948:	83 c3 01             	add    $0x1,%ebx
f010094b:	83 fb 03             	cmp    $0x3,%ebx
f010094e:	66 90                	xchg   %ax,%ax
f0100950:	75 b5                	jne    f0100907 <monitor+0xd1>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100952:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100955:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100959:	c7 04 24 d1 1d 10 f0 	movl   $0xf0101dd1,(%esp)
f0100960:	e8 5b 00 00 00       	call   f01009c0 <cprintf>
f0100965:	e9 ed fe ff ff       	jmp    f0100857 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010096a:	83 c4 5c             	add    $0x5c,%esp
f010096d:	5b                   	pop    %ebx
f010096e:	5e                   	pop    %esi
f010096f:	5f                   	pop    %edi
f0100970:	5d                   	pop    %ebp
f0100971:	c3                   	ret    

f0100972 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100972:	55                   	push   %ebp
f0100973:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100975:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100978:	5d                   	pop    %ebp
f0100979:	c3                   	ret    

f010097a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010097a:	55                   	push   %ebp
f010097b:	89 e5                	mov    %esp,%ebp
f010097d:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100980:	8b 45 08             	mov    0x8(%ebp),%eax
f0100983:	89 04 24             	mov    %eax,(%esp)
f0100986:	e8 c2 fc ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f010098b:	c9                   	leave  
f010098c:	c3                   	ret    

f010098d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010098d:	55                   	push   %ebp
f010098e:	89 e5                	mov    %esp,%ebp
f0100990:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100993:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010099a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010099d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01009a4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009a8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009af:	c7 04 24 7a 09 10 f0 	movl   $0xf010097a,(%esp)
f01009b6:	e8 89 04 00 00       	call   f0100e44 <vprintfmt>
	return cnt;
}
f01009bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009be:	c9                   	leave  
f01009bf:	c3                   	ret    

f01009c0 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009c0:	55                   	push   %ebp
f01009c1:	89 e5                	mov    %esp,%ebp
f01009c3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009c6:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01009d0:	89 04 24             	mov    %eax,(%esp)
f01009d3:	e8 b5 ff ff ff       	call   f010098d <vcprintf>
	va_end(ap);

	return cnt;
}
f01009d8:	c9                   	leave  
f01009d9:	c3                   	ret    
f01009da:	66 90                	xchg   %ax,%ax
f01009dc:	66 90                	xchg   %ax,%ax
f01009de:	66 90                	xchg   %ax,%ax

f01009e0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009e0:	55                   	push   %ebp
f01009e1:	89 e5                	mov    %esp,%ebp
f01009e3:	57                   	push   %edi
f01009e4:	56                   	push   %esi
f01009e5:	53                   	push   %ebx
f01009e6:	83 ec 10             	sub    $0x10,%esp
f01009e9:	89 c6                	mov    %eax,%esi
f01009eb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009ee:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009f1:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009f4:	8b 1a                	mov    (%edx),%ebx
f01009f6:	8b 01                	mov    (%ecx),%eax
f01009f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009fb:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100a02:	eb 77                	jmp    f0100a7b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a04:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a07:	01 d8                	add    %ebx,%eax
f0100a09:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a0e:	99                   	cltd   
f0100a0f:	f7 f9                	idiv   %ecx
f0100a11:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a13:	eb 01                	jmp    f0100a16 <stab_binsearch+0x36>
			m--;
f0100a15:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a16:	39 d9                	cmp    %ebx,%ecx
f0100a18:	7c 1d                	jl     f0100a37 <stab_binsearch+0x57>
f0100a1a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a1d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a22:	39 fa                	cmp    %edi,%edx
f0100a24:	75 ef                	jne    f0100a15 <stab_binsearch+0x35>
f0100a26:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a29:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a2c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a30:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a33:	73 18                	jae    f0100a4d <stab_binsearch+0x6d>
f0100a35:	eb 05                	jmp    f0100a3c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a37:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a3a:	eb 3f                	jmp    f0100a7b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a3c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a3f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a41:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a44:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a4b:	eb 2e                	jmp    f0100a7b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a4d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a50:	73 15                	jae    f0100a67 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a52:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a55:	48                   	dec    %eax
f0100a56:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a59:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a5c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a5e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a65:	eb 14                	jmp    f0100a7b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a67:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a6a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a6d:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a6f:	ff 45 0c             	incl   0xc(%ebp)
f0100a72:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a74:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100a7b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a7e:	7e 84                	jle    f0100a04 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a80:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a84:	75 0d                	jne    f0100a93 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a86:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a89:	8b 00                	mov    (%eax),%eax
f0100a8b:	48                   	dec    %eax
f0100a8c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a8f:	89 07                	mov    %eax,(%edi)
f0100a91:	eb 22                	jmp    f0100ab5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a96:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a98:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a9b:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a9d:	eb 01                	jmp    f0100aa0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a9f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aa0:	39 c1                	cmp    %eax,%ecx
f0100aa2:	7d 0c                	jge    f0100ab0 <stab_binsearch+0xd0>
f0100aa4:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100aa7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100aac:	39 fa                	cmp    %edi,%edx
f0100aae:	75 ef                	jne    f0100a9f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ab0:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100ab3:	89 07                	mov    %eax,(%edi)
	}
}
f0100ab5:	83 c4 10             	add    $0x10,%esp
f0100ab8:	5b                   	pop    %ebx
f0100ab9:	5e                   	pop    %esi
f0100aba:	5f                   	pop    %edi
f0100abb:	5d                   	pop    %ebp
f0100abc:	c3                   	ret    

f0100abd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100abd:	55                   	push   %ebp
f0100abe:	89 e5                	mov    %esp,%ebp
f0100ac0:	57                   	push   %edi
f0100ac1:	56                   	push   %esi
f0100ac2:	53                   	push   %ebx
f0100ac3:	83 ec 2c             	sub    $0x2c,%esp
f0100ac6:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ac9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100acc:	c7 03 44 1f 10 f0    	movl   $0xf0101f44,(%ebx)
	info->eip_line = 0;
f0100ad2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ad9:	c7 43 08 44 1f 10 f0 	movl   $0xf0101f44,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ae0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ae7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100aea:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100af1:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100af7:	76 12                	jbe    f0100b0b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100af9:	b8 3a 74 10 f0       	mov    $0xf010743a,%eax
f0100afe:	3d d1 5a 10 f0       	cmp    $0xf0105ad1,%eax
f0100b03:	0f 86 8b 01 00 00    	jbe    f0100c94 <debuginfo_eip+0x1d7>
f0100b09:	eb 1c                	jmp    f0100b27 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b0b:	c7 44 24 08 4e 1f 10 	movl   $0xf0101f4e,0x8(%esp)
f0100b12:	f0 
f0100b13:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b1a:	00 
f0100b1b:	c7 04 24 5b 1f 10 f0 	movl   $0xf0101f5b,(%esp)
f0100b22:	e8 d1 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b27:	80 3d 39 74 10 f0 00 	cmpb   $0x0,0xf0107439
f0100b2e:	0f 85 67 01 00 00    	jne    f0100c9b <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b34:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b3b:	b8 d0 5a 10 f0       	mov    $0xf0105ad0,%eax
f0100b40:	2d 7c 21 10 f0       	sub    $0xf010217c,%eax
f0100b45:	c1 f8 02             	sar    $0x2,%eax
f0100b48:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b4e:	83 e8 01             	sub    $0x1,%eax
f0100b51:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b54:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b58:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b5f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b62:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b65:	b8 7c 21 10 f0       	mov    $0xf010217c,%eax
f0100b6a:	e8 71 fe ff ff       	call   f01009e0 <stab_binsearch>
	if (lfile == 0)
f0100b6f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b72:	85 c0                	test   %eax,%eax
f0100b74:	0f 84 28 01 00 00    	je     f0100ca2 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b7a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b7d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b80:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b83:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b87:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b8e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b91:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b94:	b8 7c 21 10 f0       	mov    $0xf010217c,%eax
f0100b99:	e8 42 fe ff ff       	call   f01009e0 <stab_binsearch>

	if (lfun <= rfun) {
f0100b9e:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100ba1:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100ba4:	7f 2e                	jg     f0100bd4 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ba6:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100ba9:	8d 90 7c 21 10 f0    	lea    -0xfefde84(%eax),%edx
f0100baf:	8b 80 7c 21 10 f0    	mov    -0xfefde84(%eax),%eax
f0100bb5:	b9 3a 74 10 f0       	mov    $0xf010743a,%ecx
f0100bba:	81 e9 d1 5a 10 f0    	sub    $0xf0105ad1,%ecx
f0100bc0:	39 c8                	cmp    %ecx,%eax
f0100bc2:	73 08                	jae    f0100bcc <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bc4:	05 d1 5a 10 f0       	add    $0xf0105ad1,%eax
f0100bc9:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bcc:	8b 42 08             	mov    0x8(%edx),%eax
f0100bcf:	89 43 10             	mov    %eax,0x10(%ebx)
f0100bd2:	eb 06                	jmp    f0100bda <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bd4:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bd7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bda:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100be1:	00 
f0100be2:	8b 43 08             	mov    0x8(%ebx),%eax
f0100be5:	89 04 24             	mov    %eax,(%esp)
f0100be8:	e8 47 09 00 00       	call   f0101534 <strfind>
f0100bed:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bf0:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bf3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100bf6:	39 cf                	cmp    %ecx,%edi
f0100bf8:	7c 5c                	jl     f0100c56 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100bfa:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bfd:	8d b0 7c 21 10 f0    	lea    -0xfefde84(%eax),%esi
f0100c03:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0100c07:	80 fa 84             	cmp    $0x84,%dl
f0100c0a:	74 2b                	je     f0100c37 <debuginfo_eip+0x17a>
f0100c0c:	05 70 21 10 f0       	add    $0xf0102170,%eax
f0100c11:	eb 15                	jmp    f0100c28 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c13:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c16:	39 cf                	cmp    %ecx,%edi
f0100c18:	7c 3c                	jl     f0100c56 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100c1a:	89 c6                	mov    %eax,%esi
f0100c1c:	83 e8 0c             	sub    $0xc,%eax
f0100c1f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0100c23:	80 fa 84             	cmp    $0x84,%dl
f0100c26:	74 0f                	je     f0100c37 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c28:	80 fa 64             	cmp    $0x64,%dl
f0100c2b:	75 e6                	jne    f0100c13 <debuginfo_eip+0x156>
f0100c2d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0100c31:	74 e0                	je     f0100c13 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c33:	39 f9                	cmp    %edi,%ecx
f0100c35:	7f 1f                	jg     f0100c56 <debuginfo_eip+0x199>
f0100c37:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c3a:	8b 87 7c 21 10 f0    	mov    -0xfefde84(%edi),%eax
f0100c40:	ba 3a 74 10 f0       	mov    $0xf010743a,%edx
f0100c45:	81 ea d1 5a 10 f0    	sub    $0xf0105ad1,%edx
f0100c4b:	39 d0                	cmp    %edx,%eax
f0100c4d:	73 07                	jae    f0100c56 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c4f:	05 d1 5a 10 f0       	add    $0xf0105ad1,%eax
f0100c54:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c56:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c59:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c5c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c61:	39 ca                	cmp    %ecx,%edx
f0100c63:	7d 5e                	jge    f0100cc3 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0100c65:	8d 42 01             	lea    0x1(%edx),%eax
f0100c68:	39 c1                	cmp    %eax,%ecx
f0100c6a:	7e 3d                	jle    f0100ca9 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c6c:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c6f:	80 ba 80 21 10 f0 a0 	cmpb   $0xa0,-0xfefde80(%edx)
f0100c76:	75 38                	jne    f0100cb0 <debuginfo_eip+0x1f3>
f0100c78:	81 c2 70 21 10 f0    	add    $0xf0102170,%edx
		     lline++)
			info->eip_fn_narg++;
f0100c7e:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c82:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c85:	39 c1                	cmp    %eax,%ecx
f0100c87:	7e 2e                	jle    f0100cb7 <debuginfo_eip+0x1fa>
f0100c89:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c8c:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0100c90:	74 ec                	je     f0100c7e <debuginfo_eip+0x1c1>
f0100c92:	eb 2a                	jmp    f0100cbe <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c99:	eb 28                	jmp    f0100cc3 <debuginfo_eip+0x206>
f0100c9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca0:	eb 21                	jmp    f0100cc3 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ca2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca7:	eb 1a                	jmp    f0100cc3 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100ca9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cae:	eb 13                	jmp    f0100cc3 <debuginfo_eip+0x206>
f0100cb0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb5:	eb 0c                	jmp    f0100cc3 <debuginfo_eip+0x206>
f0100cb7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cbc:	eb 05                	jmp    f0100cc3 <debuginfo_eip+0x206>
f0100cbe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cc3:	83 c4 2c             	add    $0x2c,%esp
f0100cc6:	5b                   	pop    %ebx
f0100cc7:	5e                   	pop    %esi
f0100cc8:	5f                   	pop    %edi
f0100cc9:	5d                   	pop    %ebp
f0100cca:	c3                   	ret    
f0100ccb:	66 90                	xchg   %ax,%ax
f0100ccd:	66 90                	xchg   %ax,%ax
f0100ccf:	90                   	nop

f0100cd0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cd0:	55                   	push   %ebp
f0100cd1:	89 e5                	mov    %esp,%ebp
f0100cd3:	57                   	push   %edi
f0100cd4:	56                   	push   %esi
f0100cd5:	53                   	push   %ebx
f0100cd6:	83 ec 3c             	sub    $0x3c,%esp
f0100cd9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cdc:	89 d7                	mov    %edx,%edi
f0100cde:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ce1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ce4:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100ce7:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100cea:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ced:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100cf2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cf5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100cf8:	39 f1                	cmp    %esi,%ecx
f0100cfa:	72 14                	jb     f0100d10 <printnum+0x40>
f0100cfc:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100cff:	76 0f                	jbe    f0100d10 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d01:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d04:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100d07:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d0a:	85 f6                	test   %esi,%esi
f0100d0c:	7f 60                	jg     f0100d6e <printnum+0x9e>
f0100d0e:	eb 72                	jmp    f0100d82 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d10:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d13:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d17:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100d1a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100d1d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d25:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d29:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d2d:	89 c3                	mov    %eax,%ebx
f0100d2f:	89 d6                	mov    %edx,%esi
f0100d31:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d34:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d37:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d3b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d3f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d42:	89 04 24             	mov    %eax,(%esp)
f0100d45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d48:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d4c:	e8 4f 0a 00 00       	call   f01017a0 <__udivdi3>
f0100d51:	89 d9                	mov    %ebx,%ecx
f0100d53:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d57:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d5b:	89 04 24             	mov    %eax,(%esp)
f0100d5e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d62:	89 fa                	mov    %edi,%edx
f0100d64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d67:	e8 64 ff ff ff       	call   f0100cd0 <printnum>
f0100d6c:	eb 14                	jmp    f0100d82 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d6e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d72:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d75:	89 04 24             	mov    %eax,(%esp)
f0100d78:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d7a:	83 ee 01             	sub    $0x1,%esi
f0100d7d:	75 ef                	jne    f0100d6e <printnum+0x9e>
f0100d7f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d82:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d86:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d8a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d8d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d90:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d94:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d98:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d9b:	89 04 24             	mov    %eax,(%esp)
f0100d9e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100da1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100da5:	e8 26 0b 00 00       	call   f01018d0 <__umoddi3>
f0100daa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dae:	0f be 80 69 1f 10 f0 	movsbl -0xfefe097(%eax),%eax
f0100db5:	89 04 24             	mov    %eax,(%esp)
f0100db8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dbb:	ff d0                	call   *%eax
}
f0100dbd:	83 c4 3c             	add    $0x3c,%esp
f0100dc0:	5b                   	pop    %ebx
f0100dc1:	5e                   	pop    %esi
f0100dc2:	5f                   	pop    %edi
f0100dc3:	5d                   	pop    %ebp
f0100dc4:	c3                   	ret    

f0100dc5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100dc5:	55                   	push   %ebp
f0100dc6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100dc8:	83 fa 01             	cmp    $0x1,%edx
f0100dcb:	7e 0e                	jle    f0100ddb <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100dcd:	8b 10                	mov    (%eax),%edx
f0100dcf:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100dd2:	89 08                	mov    %ecx,(%eax)
f0100dd4:	8b 02                	mov    (%edx),%eax
f0100dd6:	8b 52 04             	mov    0x4(%edx),%edx
f0100dd9:	eb 22                	jmp    f0100dfd <getuint+0x38>
	else if (lflag)
f0100ddb:	85 d2                	test   %edx,%edx
f0100ddd:	74 10                	je     f0100def <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ddf:	8b 10                	mov    (%eax),%edx
f0100de1:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100de4:	89 08                	mov    %ecx,(%eax)
f0100de6:	8b 02                	mov    (%edx),%eax
f0100de8:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ded:	eb 0e                	jmp    f0100dfd <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100def:	8b 10                	mov    (%eax),%edx
f0100df1:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100df4:	89 08                	mov    %ecx,(%eax)
f0100df6:	8b 02                	mov    (%edx),%eax
f0100df8:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100dfd:	5d                   	pop    %ebp
f0100dfe:	c3                   	ret    

f0100dff <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100dff:	55                   	push   %ebp
f0100e00:	89 e5                	mov    %esp,%ebp
f0100e02:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e05:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e09:	8b 10                	mov    (%eax),%edx
f0100e0b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e0e:	73 0a                	jae    f0100e1a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e10:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e13:	89 08                	mov    %ecx,(%eax)
f0100e15:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e18:	88 02                	mov    %al,(%edx)
}
f0100e1a:	5d                   	pop    %ebp
f0100e1b:	c3                   	ret    

f0100e1c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e1c:	55                   	push   %ebp
f0100e1d:	89 e5                	mov    %esp,%ebp
f0100e1f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e22:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e25:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e29:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e2c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e30:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e33:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e37:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e3a:	89 04 24             	mov    %eax,(%esp)
f0100e3d:	e8 02 00 00 00       	call   f0100e44 <vprintfmt>
	va_end(ap);
}
f0100e42:	c9                   	leave  
f0100e43:	c3                   	ret    

f0100e44 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e44:	55                   	push   %ebp
f0100e45:	89 e5                	mov    %esp,%ebp
f0100e47:	57                   	push   %edi
f0100e48:	56                   	push   %esi
f0100e49:	53                   	push   %ebx
f0100e4a:	83 ec 3c             	sub    $0x3c,%esp
f0100e4d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e50:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e53:	eb 1b                	jmp    f0100e70 <vprintfmt+0x2c>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e55:	85 c0                	test   %eax,%eax
f0100e57:	0f 84 c6 03 00 00    	je     f0101223 <vprintfmt+0x3df>
				return;
			putch(ch | 0x0200, putdat);
f0100e5d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e61:	80 cc 02             	or     $0x2,%ah
f0100e64:	89 04 24             	mov    %eax,(%esp)
f0100e67:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e6a:	89 f3                	mov    %esi,%ebx
f0100e6c:	eb 02                	jmp    f0100e70 <vprintfmt+0x2c>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100e6e:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e70:	8d 73 01             	lea    0x1(%ebx),%esi
f0100e73:	0f b6 03             	movzbl (%ebx),%eax
f0100e76:	83 f8 25             	cmp    $0x25,%eax
f0100e79:	75 da                	jne    f0100e55 <vprintfmt+0x11>
f0100e7b:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100e7f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e86:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100e8d:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100e94:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e99:	eb 1d                	jmp    f0100eb8 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e9b:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e9d:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100ea1:	eb 15                	jmp    f0100eb8 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea3:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ea5:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100ea9:	eb 0d                	jmp    f0100eb8 <vprintfmt+0x74>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100eab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100eae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100eb1:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb8:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100ebb:	0f b6 06             	movzbl (%esi),%eax
f0100ebe:	0f b6 c8             	movzbl %al,%ecx
f0100ec1:	83 e8 23             	sub    $0x23,%eax
f0100ec4:	3c 55                	cmp    $0x55,%al
f0100ec6:	0f 87 2f 03 00 00    	ja     f01011fb <vprintfmt+0x3b7>
f0100ecc:	0f b6 c0             	movzbl %al,%eax
f0100ecf:	ff 24 85 f8 1f 10 f0 	jmp    *-0xfefe008(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100ed6:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100ed9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100edc:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100ee0:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100ee3:	83 f9 09             	cmp    $0x9,%ecx
f0100ee6:	77 50                	ja     f0100f38 <vprintfmt+0xf4>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee8:	89 de                	mov    %ebx,%esi
f0100eea:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100eed:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100ef0:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100ef3:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100ef7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100efa:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100efd:	83 fb 09             	cmp    $0x9,%ebx
f0100f00:	76 eb                	jbe    f0100eed <vprintfmt+0xa9>
f0100f02:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100f05:	eb 33                	jmp    f0100f3a <vprintfmt+0xf6>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f07:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f0a:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f0d:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f10:	8b 00                	mov    (%eax),%eax
f0100f12:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f15:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f17:	eb 21                	jmp    f0100f3a <vprintfmt+0xf6>
f0100f19:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f1c:	85 c9                	test   %ecx,%ecx
f0100f1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f23:	0f 49 c1             	cmovns %ecx,%eax
f0100f26:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f29:	89 de                	mov    %ebx,%esi
f0100f2b:	eb 8b                	jmp    f0100eb8 <vprintfmt+0x74>
f0100f2d:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f2f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f36:	eb 80                	jmp    f0100eb8 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f38:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100f3a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f3e:	0f 89 74 ff ff ff    	jns    f0100eb8 <vprintfmt+0x74>
f0100f44:	e9 62 ff ff ff       	jmp    f0100eab <vprintfmt+0x67>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f49:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4c:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f4e:	e9 65 ff ff ff       	jmp    f0100eb8 <vprintfmt+0x74>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f53:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f56:	8d 50 04             	lea    0x4(%eax),%edx
f0100f59:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f5c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f60:	8b 00                	mov    (%eax),%eax
f0100f62:	89 04 24             	mov    %eax,(%esp)
f0100f65:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f68:	e9 03 ff ff ff       	jmp    f0100e70 <vprintfmt+0x2c>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f70:	8d 50 04             	lea    0x4(%eax),%edx
f0100f73:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f76:	8b 00                	mov    (%eax),%eax
f0100f78:	99                   	cltd   
f0100f79:	31 d0                	xor    %edx,%eax
f0100f7b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f7d:	83 f8 06             	cmp    $0x6,%eax
f0100f80:	7f 0b                	jg     f0100f8d <vprintfmt+0x149>
f0100f82:	8b 14 85 50 21 10 f0 	mov    -0xfefdeb0(,%eax,4),%edx
f0100f89:	85 d2                	test   %edx,%edx
f0100f8b:	75 20                	jne    f0100fad <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
f0100f8d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f91:	c7 44 24 08 81 1f 10 	movl   $0xf0101f81,0x8(%esp)
f0100f98:	f0 
f0100f99:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fa0:	89 04 24             	mov    %eax,(%esp)
f0100fa3:	e8 74 fe ff ff       	call   f0100e1c <printfmt>
f0100fa8:	e9 c3 fe ff ff       	jmp    f0100e70 <vprintfmt+0x2c>
			else
				printfmt(putch, putdat, "%s", p);
f0100fad:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fb1:	c7 44 24 08 8a 1f 10 	movl   $0xf0101f8a,0x8(%esp)
f0100fb8:	f0 
f0100fb9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fbd:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fc0:	89 04 24             	mov    %eax,(%esp)
f0100fc3:	e8 54 fe ff ff       	call   f0100e1c <printfmt>
f0100fc8:	e9 a3 fe ff ff       	jmp    f0100e70 <vprintfmt+0x2c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fcd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100fd0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100fd3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd6:	8d 50 04             	lea    0x4(%eax),%edx
f0100fd9:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fdc:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f0100fde:	85 c0                	test   %eax,%eax
f0100fe0:	ba 7a 1f 10 f0       	mov    $0xf0101f7a,%edx
f0100fe5:	0f 45 d0             	cmovne %eax,%edx
f0100fe8:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0100feb:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f0100fef:	74 04                	je     f0100ff5 <vprintfmt+0x1b1>
f0100ff1:	85 f6                	test   %esi,%esi
f0100ff3:	7f 19                	jg     f010100e <vprintfmt+0x1ca>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100ff5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100ff8:	8d 70 01             	lea    0x1(%eax),%esi
f0100ffb:	0f b6 10             	movzbl (%eax),%edx
f0100ffe:	0f be c2             	movsbl %dl,%eax
f0101001:	85 c0                	test   %eax,%eax
f0101003:	0f 85 95 00 00 00    	jne    f010109e <vprintfmt+0x25a>
f0101009:	e9 85 00 00 00       	jmp    f0101093 <vprintfmt+0x24f>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010100e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101012:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101015:	89 04 24             	mov    %eax,(%esp)
f0101018:	e8 85 03 00 00       	call   f01013a2 <strnlen>
f010101d:	29 c6                	sub    %eax,%esi
f010101f:	89 f0                	mov    %esi,%eax
f0101021:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101024:	85 f6                	test   %esi,%esi
f0101026:	7e cd                	jle    f0100ff5 <vprintfmt+0x1b1>
					putch(padc, putdat);
f0101028:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f010102c:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010102f:	89 c3                	mov    %eax,%ebx
f0101031:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101035:	89 34 24             	mov    %esi,(%esp)
f0101038:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010103b:	83 eb 01             	sub    $0x1,%ebx
f010103e:	75 f1                	jne    f0101031 <vprintfmt+0x1ed>
f0101040:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101043:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101046:	eb ad                	jmp    f0100ff5 <vprintfmt+0x1b1>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101048:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010104c:	74 1e                	je     f010106c <vprintfmt+0x228>
f010104e:	0f be d2             	movsbl %dl,%edx
f0101051:	83 ea 20             	sub    $0x20,%edx
f0101054:	83 fa 5e             	cmp    $0x5e,%edx
f0101057:	76 13                	jbe    f010106c <vprintfmt+0x228>
					putch('?', putdat);
f0101059:	8b 45 0c             	mov    0xc(%ebp),%eax
f010105c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101060:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101067:	ff 55 08             	call   *0x8(%ebp)
f010106a:	eb 0d                	jmp    f0101079 <vprintfmt+0x235>
				else
					putch(ch, putdat);
f010106c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010106f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101073:	89 04 24             	mov    %eax,(%esp)
f0101076:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101079:	83 ef 01             	sub    $0x1,%edi
f010107c:	83 c6 01             	add    $0x1,%esi
f010107f:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0101083:	0f be c2             	movsbl %dl,%eax
f0101086:	85 c0                	test   %eax,%eax
f0101088:	75 20                	jne    f01010aa <vprintfmt+0x266>
f010108a:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f010108d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101090:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101093:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101097:	7f 25                	jg     f01010be <vprintfmt+0x27a>
f0101099:	e9 d2 fd ff ff       	jmp    f0100e70 <vprintfmt+0x2c>
f010109e:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010a4:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010a7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010aa:	85 db                	test   %ebx,%ebx
f01010ac:	78 9a                	js     f0101048 <vprintfmt+0x204>
f01010ae:	83 eb 01             	sub    $0x1,%ebx
f01010b1:	79 95                	jns    f0101048 <vprintfmt+0x204>
f01010b3:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01010b6:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010b9:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010bc:	eb d5                	jmp    f0101093 <vprintfmt+0x24f>
f01010be:	8b 75 08             	mov    0x8(%ebp),%esi
f01010c1:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010c4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010cb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010d2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010d4:	83 eb 01             	sub    $0x1,%ebx
f01010d7:	75 ee                	jne    f01010c7 <vprintfmt+0x283>
f01010d9:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010dc:	e9 8f fd ff ff       	jmp    f0100e70 <vprintfmt+0x2c>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010e1:	83 fa 01             	cmp    $0x1,%edx
f01010e4:	7e 16                	jle    f01010fc <vprintfmt+0x2b8>
		return va_arg(*ap, long long);
f01010e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e9:	8d 50 08             	lea    0x8(%eax),%edx
f01010ec:	89 55 14             	mov    %edx,0x14(%ebp)
f01010ef:	8b 50 04             	mov    0x4(%eax),%edx
f01010f2:	8b 00                	mov    (%eax),%eax
f01010f4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010f7:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010fa:	eb 32                	jmp    f010112e <vprintfmt+0x2ea>
	else if (lflag)
f01010fc:	85 d2                	test   %edx,%edx
f01010fe:	74 18                	je     f0101118 <vprintfmt+0x2d4>
		return va_arg(*ap, long);
f0101100:	8b 45 14             	mov    0x14(%ebp),%eax
f0101103:	8d 50 04             	lea    0x4(%eax),%edx
f0101106:	89 55 14             	mov    %edx,0x14(%ebp)
f0101109:	8b 30                	mov    (%eax),%esi
f010110b:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010110e:	89 f0                	mov    %esi,%eax
f0101110:	c1 f8 1f             	sar    $0x1f,%eax
f0101113:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101116:	eb 16                	jmp    f010112e <vprintfmt+0x2ea>
	else
		return va_arg(*ap, int);
f0101118:	8b 45 14             	mov    0x14(%ebp),%eax
f010111b:	8d 50 04             	lea    0x4(%eax),%edx
f010111e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101121:	8b 30                	mov    (%eax),%esi
f0101123:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101126:	89 f0                	mov    %esi,%eax
f0101128:	c1 f8 1f             	sar    $0x1f,%eax
f010112b:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010112e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101131:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101134:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101139:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010113d:	0f 89 80 00 00 00    	jns    f01011c3 <vprintfmt+0x37f>
				putch('-', putdat);
f0101143:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101147:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010114e:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101151:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101154:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101157:	f7 d8                	neg    %eax
f0101159:	83 d2 00             	adc    $0x0,%edx
f010115c:	f7 da                	neg    %edx
			}
			base = 10;
f010115e:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101163:	eb 5e                	jmp    f01011c3 <vprintfmt+0x37f>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101165:	8d 45 14             	lea    0x14(%ebp),%eax
f0101168:	e8 58 fc ff ff       	call   f0100dc5 <getuint>
			base = 10;
f010116d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101172:	eb 4f                	jmp    f01011c3 <vprintfmt+0x37f>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101174:	8d 45 14             	lea    0x14(%ebp),%eax
f0101177:	e8 49 fc ff ff       	call   f0100dc5 <getuint>
			base = 8;
f010117c:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101181:	eb 40                	jmp    f01011c3 <vprintfmt+0x37f>

		// pointer
		case 'p':
			putch('0', putdat);
f0101183:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101187:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010118e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101191:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101195:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010119c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010119f:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a2:	8d 50 04             	lea    0x4(%eax),%edx
f01011a5:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011a8:	8b 00                	mov    (%eax),%eax
f01011aa:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011af:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01011b4:	eb 0d                	jmp    f01011c3 <vprintfmt+0x37f>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011b6:	8d 45 14             	lea    0x14(%ebp),%eax
f01011b9:	e8 07 fc ff ff       	call   f0100dc5 <getuint>
			base = 16;
f01011be:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011c3:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01011c7:	89 74 24 10          	mov    %esi,0x10(%esp)
f01011cb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01011ce:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01011d2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01011d6:	89 04 24             	mov    %eax,(%esp)
f01011d9:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011dd:	89 fa                	mov    %edi,%edx
f01011df:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e2:	e8 e9 fa ff ff       	call   f0100cd0 <printnum>
			break;
f01011e7:	e9 84 fc ff ff       	jmp    f0100e70 <vprintfmt+0x2c>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011ec:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011f0:	89 0c 24             	mov    %ecx,(%esp)
f01011f3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01011f6:	e9 75 fc ff ff       	jmp    f0100e70 <vprintfmt+0x2c>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011ff:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101206:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101209:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010120d:	0f 84 5b fc ff ff    	je     f0100e6e <vprintfmt+0x2a>
f0101213:	89 f3                	mov    %esi,%ebx
f0101215:	83 eb 01             	sub    $0x1,%ebx
f0101218:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010121c:	75 f7                	jne    f0101215 <vprintfmt+0x3d1>
f010121e:	e9 4d fc ff ff       	jmp    f0100e70 <vprintfmt+0x2c>
				/* do nothing */;
			break;
		}
	}
}
f0101223:	83 c4 3c             	add    $0x3c,%esp
f0101226:	5b                   	pop    %ebx
f0101227:	5e                   	pop    %esi
f0101228:	5f                   	pop    %edi
f0101229:	5d                   	pop    %ebp
f010122a:	c3                   	ret    

f010122b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010122b:	55                   	push   %ebp
f010122c:	89 e5                	mov    %esp,%ebp
f010122e:	83 ec 28             	sub    $0x28,%esp
f0101231:	8b 45 08             	mov    0x8(%ebp),%eax
f0101234:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101237:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010123a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010123e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101241:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101248:	85 c0                	test   %eax,%eax
f010124a:	74 30                	je     f010127c <vsnprintf+0x51>
f010124c:	85 d2                	test   %edx,%edx
f010124e:	7e 2c                	jle    f010127c <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101250:	8b 45 14             	mov    0x14(%ebp),%eax
f0101253:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101257:	8b 45 10             	mov    0x10(%ebp),%eax
f010125a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010125e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101261:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101265:	c7 04 24 ff 0d 10 f0 	movl   $0xf0100dff,(%esp)
f010126c:	e8 d3 fb ff ff       	call   f0100e44 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101271:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101274:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101277:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010127a:	eb 05                	jmp    f0101281 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010127c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101281:	c9                   	leave  
f0101282:	c3                   	ret    

f0101283 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101283:	55                   	push   %ebp
f0101284:	89 e5                	mov    %esp,%ebp
f0101286:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101289:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010128c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101290:	8b 45 10             	mov    0x10(%ebp),%eax
f0101293:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101297:	8b 45 0c             	mov    0xc(%ebp),%eax
f010129a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010129e:	8b 45 08             	mov    0x8(%ebp),%eax
f01012a1:	89 04 24             	mov    %eax,(%esp)
f01012a4:	e8 82 ff ff ff       	call   f010122b <vsnprintf>
	va_end(ap);

	return rc;
}
f01012a9:	c9                   	leave  
f01012aa:	c3                   	ret    
f01012ab:	66 90                	xchg   %ax,%ax
f01012ad:	66 90                	xchg   %ax,%ax
f01012af:	90                   	nop

f01012b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012b0:	55                   	push   %ebp
f01012b1:	89 e5                	mov    %esp,%ebp
f01012b3:	57                   	push   %edi
f01012b4:	56                   	push   %esi
f01012b5:	53                   	push   %ebx
f01012b6:	83 ec 1c             	sub    $0x1c,%esp
f01012b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012bc:	85 c0                	test   %eax,%eax
f01012be:	74 10                	je     f01012d0 <readline+0x20>
		cprintf("%s", prompt);
f01012c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c4:	c7 04 24 8a 1f 10 f0 	movl   $0xf0101f8a,(%esp)
f01012cb:	e8 f0 f6 ff ff       	call   f01009c0 <cprintf>

	i = 0;
	echoing = iscons(0);
f01012d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012d7:	e8 92 f3 ff ff       	call   f010066e <iscons>
f01012dc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01012de:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01012e3:	e8 75 f3 ff ff       	call   f010065d <getchar>
f01012e8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012ea:	85 c0                	test   %eax,%eax
f01012ec:	79 17                	jns    f0101305 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f2:	c7 04 24 6c 21 10 f0 	movl   $0xf010216c,(%esp)
f01012f9:	e8 c2 f6 ff ff       	call   f01009c0 <cprintf>
			return NULL;
f01012fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0101303:	eb 6d                	jmp    f0101372 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101305:	83 f8 7f             	cmp    $0x7f,%eax
f0101308:	74 05                	je     f010130f <readline+0x5f>
f010130a:	83 f8 08             	cmp    $0x8,%eax
f010130d:	75 19                	jne    f0101328 <readline+0x78>
f010130f:	85 f6                	test   %esi,%esi
f0101311:	7e 15                	jle    f0101328 <readline+0x78>
			if (echoing)
f0101313:	85 ff                	test   %edi,%edi
f0101315:	74 0c                	je     f0101323 <readline+0x73>
				cputchar('\b');
f0101317:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010131e:	e8 2a f3 ff ff       	call   f010064d <cputchar>
			i--;
f0101323:	83 ee 01             	sub    $0x1,%esi
f0101326:	eb bb                	jmp    f01012e3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101328:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010132e:	7f 1c                	jg     f010134c <readline+0x9c>
f0101330:	83 fb 1f             	cmp    $0x1f,%ebx
f0101333:	7e 17                	jle    f010134c <readline+0x9c>
			if (echoing)
f0101335:	85 ff                	test   %edi,%edi
f0101337:	74 08                	je     f0101341 <readline+0x91>
				cputchar(c);
f0101339:	89 1c 24             	mov    %ebx,(%esp)
f010133c:	e8 0c f3 ff ff       	call   f010064d <cputchar>
			buf[i++] = c;
f0101341:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101347:	8d 76 01             	lea    0x1(%esi),%esi
f010134a:	eb 97                	jmp    f01012e3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010134c:	83 fb 0d             	cmp    $0xd,%ebx
f010134f:	74 05                	je     f0101356 <readline+0xa6>
f0101351:	83 fb 0a             	cmp    $0xa,%ebx
f0101354:	75 8d                	jne    f01012e3 <readline+0x33>
			if (echoing)
f0101356:	85 ff                	test   %edi,%edi
f0101358:	74 0c                	je     f0101366 <readline+0xb6>
				cputchar('\n');
f010135a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101361:	e8 e7 f2 ff ff       	call   f010064d <cputchar>
			buf[i] = 0;
f0101366:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f010136d:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101372:	83 c4 1c             	add    $0x1c,%esp
f0101375:	5b                   	pop    %ebx
f0101376:	5e                   	pop    %esi
f0101377:	5f                   	pop    %edi
f0101378:	5d                   	pop    %ebp
f0101379:	c3                   	ret    
f010137a:	66 90                	xchg   %ax,%ax
f010137c:	66 90                	xchg   %ax,%ax
f010137e:	66 90                	xchg   %ax,%ax

f0101380 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101380:	55                   	push   %ebp
f0101381:	89 e5                	mov    %esp,%ebp
f0101383:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101386:	80 3a 00             	cmpb   $0x0,(%edx)
f0101389:	74 10                	je     f010139b <strlen+0x1b>
f010138b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101390:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101393:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101397:	75 f7                	jne    f0101390 <strlen+0x10>
f0101399:	eb 05                	jmp    f01013a0 <strlen+0x20>
f010139b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01013a0:	5d                   	pop    %ebp
f01013a1:	c3                   	ret    

f01013a2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013a2:	55                   	push   %ebp
f01013a3:	89 e5                	mov    %esp,%ebp
f01013a5:	53                   	push   %ebx
f01013a6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01013a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013ac:	85 c9                	test   %ecx,%ecx
f01013ae:	74 1c                	je     f01013cc <strnlen+0x2a>
f01013b0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01013b3:	74 1e                	je     f01013d3 <strnlen+0x31>
f01013b5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01013ba:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013bc:	39 ca                	cmp    %ecx,%edx
f01013be:	74 18                	je     f01013d8 <strnlen+0x36>
f01013c0:	83 c2 01             	add    $0x1,%edx
f01013c3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01013c8:	75 f0                	jne    f01013ba <strnlen+0x18>
f01013ca:	eb 0c                	jmp    f01013d8 <strnlen+0x36>
f01013cc:	b8 00 00 00 00       	mov    $0x0,%eax
f01013d1:	eb 05                	jmp    f01013d8 <strnlen+0x36>
f01013d3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01013d8:	5b                   	pop    %ebx
f01013d9:	5d                   	pop    %ebp
f01013da:	c3                   	ret    

f01013db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013db:	55                   	push   %ebp
f01013dc:	89 e5                	mov    %esp,%ebp
f01013de:	53                   	push   %ebx
f01013df:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013e5:	89 c2                	mov    %eax,%edx
f01013e7:	83 c2 01             	add    $0x1,%edx
f01013ea:	83 c1 01             	add    $0x1,%ecx
f01013ed:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01013f1:	88 5a ff             	mov    %bl,-0x1(%edx)
f01013f4:	84 db                	test   %bl,%bl
f01013f6:	75 ef                	jne    f01013e7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013f8:	5b                   	pop    %ebx
f01013f9:	5d                   	pop    %ebp
f01013fa:	c3                   	ret    

f01013fb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013fb:	55                   	push   %ebp
f01013fc:	89 e5                	mov    %esp,%ebp
f01013fe:	56                   	push   %esi
f01013ff:	53                   	push   %ebx
f0101400:	8b 75 08             	mov    0x8(%ebp),%esi
f0101403:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101406:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101409:	85 db                	test   %ebx,%ebx
f010140b:	74 17                	je     f0101424 <strncpy+0x29>
f010140d:	01 f3                	add    %esi,%ebx
f010140f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0101411:	83 c1 01             	add    $0x1,%ecx
f0101414:	0f b6 02             	movzbl (%edx),%eax
f0101417:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010141a:	80 3a 01             	cmpb   $0x1,(%edx)
f010141d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101420:	39 d9                	cmp    %ebx,%ecx
f0101422:	75 ed                	jne    f0101411 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101424:	89 f0                	mov    %esi,%eax
f0101426:	5b                   	pop    %ebx
f0101427:	5e                   	pop    %esi
f0101428:	5d                   	pop    %ebp
f0101429:	c3                   	ret    

f010142a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010142a:	55                   	push   %ebp
f010142b:	89 e5                	mov    %esp,%ebp
f010142d:	57                   	push   %edi
f010142e:	56                   	push   %esi
f010142f:	53                   	push   %ebx
f0101430:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101433:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101436:	8b 75 10             	mov    0x10(%ebp),%esi
f0101439:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010143b:	85 f6                	test   %esi,%esi
f010143d:	74 34                	je     f0101473 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010143f:	83 fe 01             	cmp    $0x1,%esi
f0101442:	74 26                	je     f010146a <strlcpy+0x40>
f0101444:	0f b6 0b             	movzbl (%ebx),%ecx
f0101447:	84 c9                	test   %cl,%cl
f0101449:	74 23                	je     f010146e <strlcpy+0x44>
f010144b:	83 ee 02             	sub    $0x2,%esi
f010144e:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0101453:	83 c0 01             	add    $0x1,%eax
f0101456:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101459:	39 f2                	cmp    %esi,%edx
f010145b:	74 13                	je     f0101470 <strlcpy+0x46>
f010145d:	83 c2 01             	add    $0x1,%edx
f0101460:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101464:	84 c9                	test   %cl,%cl
f0101466:	75 eb                	jne    f0101453 <strlcpy+0x29>
f0101468:	eb 06                	jmp    f0101470 <strlcpy+0x46>
f010146a:	89 f8                	mov    %edi,%eax
f010146c:	eb 02                	jmp    f0101470 <strlcpy+0x46>
f010146e:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101470:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101473:	29 f8                	sub    %edi,%eax
}
f0101475:	5b                   	pop    %ebx
f0101476:	5e                   	pop    %esi
f0101477:	5f                   	pop    %edi
f0101478:	5d                   	pop    %ebp
f0101479:	c3                   	ret    

f010147a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010147a:	55                   	push   %ebp
f010147b:	89 e5                	mov    %esp,%ebp
f010147d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101480:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101483:	0f b6 01             	movzbl (%ecx),%eax
f0101486:	84 c0                	test   %al,%al
f0101488:	74 15                	je     f010149f <strcmp+0x25>
f010148a:	3a 02                	cmp    (%edx),%al
f010148c:	75 11                	jne    f010149f <strcmp+0x25>
		p++, q++;
f010148e:	83 c1 01             	add    $0x1,%ecx
f0101491:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101494:	0f b6 01             	movzbl (%ecx),%eax
f0101497:	84 c0                	test   %al,%al
f0101499:	74 04                	je     f010149f <strcmp+0x25>
f010149b:	3a 02                	cmp    (%edx),%al
f010149d:	74 ef                	je     f010148e <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010149f:	0f b6 c0             	movzbl %al,%eax
f01014a2:	0f b6 12             	movzbl (%edx),%edx
f01014a5:	29 d0                	sub    %edx,%eax
}
f01014a7:	5d                   	pop    %ebp
f01014a8:	c3                   	ret    

f01014a9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014a9:	55                   	push   %ebp
f01014aa:	89 e5                	mov    %esp,%ebp
f01014ac:	56                   	push   %esi
f01014ad:	53                   	push   %ebx
f01014ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014b1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014b4:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01014b7:	85 f6                	test   %esi,%esi
f01014b9:	74 29                	je     f01014e4 <strncmp+0x3b>
f01014bb:	0f b6 03             	movzbl (%ebx),%eax
f01014be:	84 c0                	test   %al,%al
f01014c0:	74 30                	je     f01014f2 <strncmp+0x49>
f01014c2:	3a 02                	cmp    (%edx),%al
f01014c4:	75 2c                	jne    f01014f2 <strncmp+0x49>
f01014c6:	8d 43 01             	lea    0x1(%ebx),%eax
f01014c9:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f01014cb:	89 c3                	mov    %eax,%ebx
f01014cd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014d0:	39 f0                	cmp    %esi,%eax
f01014d2:	74 17                	je     f01014eb <strncmp+0x42>
f01014d4:	0f b6 08             	movzbl (%eax),%ecx
f01014d7:	84 c9                	test   %cl,%cl
f01014d9:	74 17                	je     f01014f2 <strncmp+0x49>
f01014db:	83 c0 01             	add    $0x1,%eax
f01014de:	3a 0a                	cmp    (%edx),%cl
f01014e0:	74 e9                	je     f01014cb <strncmp+0x22>
f01014e2:	eb 0e                	jmp    f01014f2 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01014e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01014e9:	eb 0f                	jmp    f01014fa <strncmp+0x51>
f01014eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01014f0:	eb 08                	jmp    f01014fa <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014f2:	0f b6 03             	movzbl (%ebx),%eax
f01014f5:	0f b6 12             	movzbl (%edx),%edx
f01014f8:	29 d0                	sub    %edx,%eax
}
f01014fa:	5b                   	pop    %ebx
f01014fb:	5e                   	pop    %esi
f01014fc:	5d                   	pop    %ebp
f01014fd:	c3                   	ret    

f01014fe <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014fe:	55                   	push   %ebp
f01014ff:	89 e5                	mov    %esp,%ebp
f0101501:	53                   	push   %ebx
f0101502:	8b 45 08             	mov    0x8(%ebp),%eax
f0101505:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101508:	0f b6 18             	movzbl (%eax),%ebx
f010150b:	84 db                	test   %bl,%bl
f010150d:	74 1d                	je     f010152c <strchr+0x2e>
f010150f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101511:	38 d3                	cmp    %dl,%bl
f0101513:	75 06                	jne    f010151b <strchr+0x1d>
f0101515:	eb 1a                	jmp    f0101531 <strchr+0x33>
f0101517:	38 ca                	cmp    %cl,%dl
f0101519:	74 16                	je     f0101531 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010151b:	83 c0 01             	add    $0x1,%eax
f010151e:	0f b6 10             	movzbl (%eax),%edx
f0101521:	84 d2                	test   %dl,%dl
f0101523:	75 f2                	jne    f0101517 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101525:	b8 00 00 00 00       	mov    $0x0,%eax
f010152a:	eb 05                	jmp    f0101531 <strchr+0x33>
f010152c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101531:	5b                   	pop    %ebx
f0101532:	5d                   	pop    %ebp
f0101533:	c3                   	ret    

f0101534 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101534:	55                   	push   %ebp
f0101535:	89 e5                	mov    %esp,%ebp
f0101537:	53                   	push   %ebx
f0101538:	8b 45 08             	mov    0x8(%ebp),%eax
f010153b:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010153e:	0f b6 18             	movzbl (%eax),%ebx
f0101541:	84 db                	test   %bl,%bl
f0101543:	74 17                	je     f010155c <strfind+0x28>
f0101545:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101547:	38 d3                	cmp    %dl,%bl
f0101549:	75 07                	jne    f0101552 <strfind+0x1e>
f010154b:	eb 0f                	jmp    f010155c <strfind+0x28>
f010154d:	38 ca                	cmp    %cl,%dl
f010154f:	90                   	nop
f0101550:	74 0a                	je     f010155c <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101552:	83 c0 01             	add    $0x1,%eax
f0101555:	0f b6 10             	movzbl (%eax),%edx
f0101558:	84 d2                	test   %dl,%dl
f010155a:	75 f1                	jne    f010154d <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010155c:	5b                   	pop    %ebx
f010155d:	5d                   	pop    %ebp
f010155e:	c3                   	ret    

f010155f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010155f:	55                   	push   %ebp
f0101560:	89 e5                	mov    %esp,%ebp
f0101562:	57                   	push   %edi
f0101563:	56                   	push   %esi
f0101564:	53                   	push   %ebx
f0101565:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101568:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010156b:	85 c9                	test   %ecx,%ecx
f010156d:	74 36                	je     f01015a5 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010156f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101575:	75 28                	jne    f010159f <memset+0x40>
f0101577:	f6 c1 03             	test   $0x3,%cl
f010157a:	75 23                	jne    f010159f <memset+0x40>
		c &= 0xFF;
f010157c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101580:	89 d3                	mov    %edx,%ebx
f0101582:	c1 e3 08             	shl    $0x8,%ebx
f0101585:	89 d6                	mov    %edx,%esi
f0101587:	c1 e6 18             	shl    $0x18,%esi
f010158a:	89 d0                	mov    %edx,%eax
f010158c:	c1 e0 10             	shl    $0x10,%eax
f010158f:	09 f0                	or     %esi,%eax
f0101591:	09 c2                	or     %eax,%edx
f0101593:	89 d0                	mov    %edx,%eax
f0101595:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101597:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010159a:	fc                   	cld    
f010159b:	f3 ab                	rep stos %eax,%es:(%edi)
f010159d:	eb 06                	jmp    f01015a5 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010159f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015a2:	fc                   	cld    
f01015a3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015a5:	89 f8                	mov    %edi,%eax
f01015a7:	5b                   	pop    %ebx
f01015a8:	5e                   	pop    %esi
f01015a9:	5f                   	pop    %edi
f01015aa:	5d                   	pop    %ebp
f01015ab:	c3                   	ret    

f01015ac <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015ac:	55                   	push   %ebp
f01015ad:	89 e5                	mov    %esp,%ebp
f01015af:	57                   	push   %edi
f01015b0:	56                   	push   %esi
f01015b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01015b4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015b7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015ba:	39 c6                	cmp    %eax,%esi
f01015bc:	73 35                	jae    f01015f3 <memmove+0x47>
f01015be:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015c1:	39 d0                	cmp    %edx,%eax
f01015c3:	73 2e                	jae    f01015f3 <memmove+0x47>
		s += n;
		d += n;
f01015c5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015c8:	89 d6                	mov    %edx,%esi
f01015ca:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015cc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015d2:	75 13                	jne    f01015e7 <memmove+0x3b>
f01015d4:	f6 c1 03             	test   $0x3,%cl
f01015d7:	75 0e                	jne    f01015e7 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015d9:	83 ef 04             	sub    $0x4,%edi
f01015dc:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015df:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015e2:	fd                   	std    
f01015e3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015e5:	eb 09                	jmp    f01015f0 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015e7:	83 ef 01             	sub    $0x1,%edi
f01015ea:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015ed:	fd                   	std    
f01015ee:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015f0:	fc                   	cld    
f01015f1:	eb 1d                	jmp    f0101610 <memmove+0x64>
f01015f3:	89 f2                	mov    %esi,%edx
f01015f5:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015f7:	f6 c2 03             	test   $0x3,%dl
f01015fa:	75 0f                	jne    f010160b <memmove+0x5f>
f01015fc:	f6 c1 03             	test   $0x3,%cl
f01015ff:	75 0a                	jne    f010160b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101601:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101604:	89 c7                	mov    %eax,%edi
f0101606:	fc                   	cld    
f0101607:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101609:	eb 05                	jmp    f0101610 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010160b:	89 c7                	mov    %eax,%edi
f010160d:	fc                   	cld    
f010160e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101610:	5e                   	pop    %esi
f0101611:	5f                   	pop    %edi
f0101612:	5d                   	pop    %ebp
f0101613:	c3                   	ret    

f0101614 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101614:	55                   	push   %ebp
f0101615:	89 e5                	mov    %esp,%ebp
f0101617:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010161a:	8b 45 10             	mov    0x10(%ebp),%eax
f010161d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101621:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101624:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101628:	8b 45 08             	mov    0x8(%ebp),%eax
f010162b:	89 04 24             	mov    %eax,(%esp)
f010162e:	e8 79 ff ff ff       	call   f01015ac <memmove>
}
f0101633:	c9                   	leave  
f0101634:	c3                   	ret    

f0101635 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101635:	55                   	push   %ebp
f0101636:	89 e5                	mov    %esp,%ebp
f0101638:	57                   	push   %edi
f0101639:	56                   	push   %esi
f010163a:	53                   	push   %ebx
f010163b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010163e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101641:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101644:	8d 78 ff             	lea    -0x1(%eax),%edi
f0101647:	85 c0                	test   %eax,%eax
f0101649:	74 36                	je     f0101681 <memcmp+0x4c>
		if (*s1 != *s2)
f010164b:	0f b6 03             	movzbl (%ebx),%eax
f010164e:	0f b6 0e             	movzbl (%esi),%ecx
f0101651:	ba 00 00 00 00       	mov    $0x0,%edx
f0101656:	38 c8                	cmp    %cl,%al
f0101658:	74 1c                	je     f0101676 <memcmp+0x41>
f010165a:	eb 10                	jmp    f010166c <memcmp+0x37>
f010165c:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101661:	83 c2 01             	add    $0x1,%edx
f0101664:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101668:	38 c8                	cmp    %cl,%al
f010166a:	74 0a                	je     f0101676 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010166c:	0f b6 c0             	movzbl %al,%eax
f010166f:	0f b6 c9             	movzbl %cl,%ecx
f0101672:	29 c8                	sub    %ecx,%eax
f0101674:	eb 10                	jmp    f0101686 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101676:	39 fa                	cmp    %edi,%edx
f0101678:	75 e2                	jne    f010165c <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010167a:	b8 00 00 00 00       	mov    $0x0,%eax
f010167f:	eb 05                	jmp    f0101686 <memcmp+0x51>
f0101681:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101686:	5b                   	pop    %ebx
f0101687:	5e                   	pop    %esi
f0101688:	5f                   	pop    %edi
f0101689:	5d                   	pop    %ebp
f010168a:	c3                   	ret    

f010168b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010168b:	55                   	push   %ebp
f010168c:	89 e5                	mov    %esp,%ebp
f010168e:	53                   	push   %ebx
f010168f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101692:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0101695:	89 c2                	mov    %eax,%edx
f0101697:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010169a:	39 d0                	cmp    %edx,%eax
f010169c:	73 14                	jae    f01016b2 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f010169e:	89 d9                	mov    %ebx,%ecx
f01016a0:	38 18                	cmp    %bl,(%eax)
f01016a2:	75 06                	jne    f01016aa <memfind+0x1f>
f01016a4:	eb 0c                	jmp    f01016b2 <memfind+0x27>
f01016a6:	38 08                	cmp    %cl,(%eax)
f01016a8:	74 08                	je     f01016b2 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016aa:	83 c0 01             	add    $0x1,%eax
f01016ad:	39 d0                	cmp    %edx,%eax
f01016af:	90                   	nop
f01016b0:	75 f4                	jne    f01016a6 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016b2:	5b                   	pop    %ebx
f01016b3:	5d                   	pop    %ebp
f01016b4:	c3                   	ret    

f01016b5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016b5:	55                   	push   %ebp
f01016b6:	89 e5                	mov    %esp,%ebp
f01016b8:	57                   	push   %edi
f01016b9:	56                   	push   %esi
f01016ba:	53                   	push   %ebx
f01016bb:	8b 55 08             	mov    0x8(%ebp),%edx
f01016be:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016c1:	0f b6 0a             	movzbl (%edx),%ecx
f01016c4:	80 f9 09             	cmp    $0x9,%cl
f01016c7:	74 05                	je     f01016ce <strtol+0x19>
f01016c9:	80 f9 20             	cmp    $0x20,%cl
f01016cc:	75 10                	jne    f01016de <strtol+0x29>
		s++;
f01016ce:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016d1:	0f b6 0a             	movzbl (%edx),%ecx
f01016d4:	80 f9 09             	cmp    $0x9,%cl
f01016d7:	74 f5                	je     f01016ce <strtol+0x19>
f01016d9:	80 f9 20             	cmp    $0x20,%cl
f01016dc:	74 f0                	je     f01016ce <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016de:	80 f9 2b             	cmp    $0x2b,%cl
f01016e1:	75 0a                	jne    f01016ed <strtol+0x38>
		s++;
f01016e3:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016e6:	bf 00 00 00 00       	mov    $0x0,%edi
f01016eb:	eb 11                	jmp    f01016fe <strtol+0x49>
f01016ed:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016f2:	80 f9 2d             	cmp    $0x2d,%cl
f01016f5:	75 07                	jne    f01016fe <strtol+0x49>
		s++, neg = 1;
f01016f7:	83 c2 01             	add    $0x1,%edx
f01016fa:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016fe:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101703:	75 15                	jne    f010171a <strtol+0x65>
f0101705:	80 3a 30             	cmpb   $0x30,(%edx)
f0101708:	75 10                	jne    f010171a <strtol+0x65>
f010170a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010170e:	75 0a                	jne    f010171a <strtol+0x65>
		s += 2, base = 16;
f0101710:	83 c2 02             	add    $0x2,%edx
f0101713:	b8 10 00 00 00       	mov    $0x10,%eax
f0101718:	eb 10                	jmp    f010172a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f010171a:	85 c0                	test   %eax,%eax
f010171c:	75 0c                	jne    f010172a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010171e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101720:	80 3a 30             	cmpb   $0x30,(%edx)
f0101723:	75 05                	jne    f010172a <strtol+0x75>
		s++, base = 8;
f0101725:	83 c2 01             	add    $0x1,%edx
f0101728:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010172a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010172f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101732:	0f b6 0a             	movzbl (%edx),%ecx
f0101735:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101738:	89 f0                	mov    %esi,%eax
f010173a:	3c 09                	cmp    $0x9,%al
f010173c:	77 08                	ja     f0101746 <strtol+0x91>
			dig = *s - '0';
f010173e:	0f be c9             	movsbl %cl,%ecx
f0101741:	83 e9 30             	sub    $0x30,%ecx
f0101744:	eb 20                	jmp    f0101766 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f0101746:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101749:	89 f0                	mov    %esi,%eax
f010174b:	3c 19                	cmp    $0x19,%al
f010174d:	77 08                	ja     f0101757 <strtol+0xa2>
			dig = *s - 'a' + 10;
f010174f:	0f be c9             	movsbl %cl,%ecx
f0101752:	83 e9 57             	sub    $0x57,%ecx
f0101755:	eb 0f                	jmp    f0101766 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0101757:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010175a:	89 f0                	mov    %esi,%eax
f010175c:	3c 19                	cmp    $0x19,%al
f010175e:	77 16                	ja     f0101776 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0101760:	0f be c9             	movsbl %cl,%ecx
f0101763:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101766:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0101769:	7d 0f                	jge    f010177a <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010176b:	83 c2 01             	add    $0x1,%edx
f010176e:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101772:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101774:	eb bc                	jmp    f0101732 <strtol+0x7d>
f0101776:	89 d8                	mov    %ebx,%eax
f0101778:	eb 02                	jmp    f010177c <strtol+0xc7>
f010177a:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010177c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101780:	74 05                	je     f0101787 <strtol+0xd2>
		*endptr = (char *) s;
f0101782:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101785:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0101787:	f7 d8                	neg    %eax
f0101789:	85 ff                	test   %edi,%edi
f010178b:	0f 44 c3             	cmove  %ebx,%eax
}
f010178e:	5b                   	pop    %ebx
f010178f:	5e                   	pop    %esi
f0101790:	5f                   	pop    %edi
f0101791:	5d                   	pop    %ebp
f0101792:	c3                   	ret    
f0101793:	66 90                	xchg   %ax,%ax
f0101795:	66 90                	xchg   %ax,%ax
f0101797:	66 90                	xchg   %ax,%ax
f0101799:	66 90                	xchg   %ax,%ax
f010179b:	66 90                	xchg   %ax,%ax
f010179d:	66 90                	xchg   %ax,%ax
f010179f:	90                   	nop

f01017a0 <__udivdi3>:
f01017a0:	55                   	push   %ebp
f01017a1:	57                   	push   %edi
f01017a2:	56                   	push   %esi
f01017a3:	83 ec 0c             	sub    $0xc,%esp
f01017a6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017aa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01017ae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01017b2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017b6:	85 c0                	test   %eax,%eax
f01017b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017bc:	89 ea                	mov    %ebp,%edx
f01017be:	89 0c 24             	mov    %ecx,(%esp)
f01017c1:	75 2d                	jne    f01017f0 <__udivdi3+0x50>
f01017c3:	39 e9                	cmp    %ebp,%ecx
f01017c5:	77 61                	ja     f0101828 <__udivdi3+0x88>
f01017c7:	85 c9                	test   %ecx,%ecx
f01017c9:	89 ce                	mov    %ecx,%esi
f01017cb:	75 0b                	jne    f01017d8 <__udivdi3+0x38>
f01017cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01017d2:	31 d2                	xor    %edx,%edx
f01017d4:	f7 f1                	div    %ecx
f01017d6:	89 c6                	mov    %eax,%esi
f01017d8:	31 d2                	xor    %edx,%edx
f01017da:	89 e8                	mov    %ebp,%eax
f01017dc:	f7 f6                	div    %esi
f01017de:	89 c5                	mov    %eax,%ebp
f01017e0:	89 f8                	mov    %edi,%eax
f01017e2:	f7 f6                	div    %esi
f01017e4:	89 ea                	mov    %ebp,%edx
f01017e6:	83 c4 0c             	add    $0xc,%esp
f01017e9:	5e                   	pop    %esi
f01017ea:	5f                   	pop    %edi
f01017eb:	5d                   	pop    %ebp
f01017ec:	c3                   	ret    
f01017ed:	8d 76 00             	lea    0x0(%esi),%esi
f01017f0:	39 e8                	cmp    %ebp,%eax
f01017f2:	77 24                	ja     f0101818 <__udivdi3+0x78>
f01017f4:	0f bd e8             	bsr    %eax,%ebp
f01017f7:	83 f5 1f             	xor    $0x1f,%ebp
f01017fa:	75 3c                	jne    f0101838 <__udivdi3+0x98>
f01017fc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101800:	39 34 24             	cmp    %esi,(%esp)
f0101803:	0f 86 9f 00 00 00    	jbe    f01018a8 <__udivdi3+0x108>
f0101809:	39 d0                	cmp    %edx,%eax
f010180b:	0f 82 97 00 00 00    	jb     f01018a8 <__udivdi3+0x108>
f0101811:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101818:	31 d2                	xor    %edx,%edx
f010181a:	31 c0                	xor    %eax,%eax
f010181c:	83 c4 0c             	add    $0xc,%esp
f010181f:	5e                   	pop    %esi
f0101820:	5f                   	pop    %edi
f0101821:	5d                   	pop    %ebp
f0101822:	c3                   	ret    
f0101823:	90                   	nop
f0101824:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101828:	89 f8                	mov    %edi,%eax
f010182a:	f7 f1                	div    %ecx
f010182c:	31 d2                	xor    %edx,%edx
f010182e:	83 c4 0c             	add    $0xc,%esp
f0101831:	5e                   	pop    %esi
f0101832:	5f                   	pop    %edi
f0101833:	5d                   	pop    %ebp
f0101834:	c3                   	ret    
f0101835:	8d 76 00             	lea    0x0(%esi),%esi
f0101838:	89 e9                	mov    %ebp,%ecx
f010183a:	8b 3c 24             	mov    (%esp),%edi
f010183d:	d3 e0                	shl    %cl,%eax
f010183f:	89 c6                	mov    %eax,%esi
f0101841:	b8 20 00 00 00       	mov    $0x20,%eax
f0101846:	29 e8                	sub    %ebp,%eax
f0101848:	89 c1                	mov    %eax,%ecx
f010184a:	d3 ef                	shr    %cl,%edi
f010184c:	89 e9                	mov    %ebp,%ecx
f010184e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101852:	8b 3c 24             	mov    (%esp),%edi
f0101855:	09 74 24 08          	or     %esi,0x8(%esp)
f0101859:	89 d6                	mov    %edx,%esi
f010185b:	d3 e7                	shl    %cl,%edi
f010185d:	89 c1                	mov    %eax,%ecx
f010185f:	89 3c 24             	mov    %edi,(%esp)
f0101862:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101866:	d3 ee                	shr    %cl,%esi
f0101868:	89 e9                	mov    %ebp,%ecx
f010186a:	d3 e2                	shl    %cl,%edx
f010186c:	89 c1                	mov    %eax,%ecx
f010186e:	d3 ef                	shr    %cl,%edi
f0101870:	09 d7                	or     %edx,%edi
f0101872:	89 f2                	mov    %esi,%edx
f0101874:	89 f8                	mov    %edi,%eax
f0101876:	f7 74 24 08          	divl   0x8(%esp)
f010187a:	89 d6                	mov    %edx,%esi
f010187c:	89 c7                	mov    %eax,%edi
f010187e:	f7 24 24             	mull   (%esp)
f0101881:	39 d6                	cmp    %edx,%esi
f0101883:	89 14 24             	mov    %edx,(%esp)
f0101886:	72 30                	jb     f01018b8 <__udivdi3+0x118>
f0101888:	8b 54 24 04          	mov    0x4(%esp),%edx
f010188c:	89 e9                	mov    %ebp,%ecx
f010188e:	d3 e2                	shl    %cl,%edx
f0101890:	39 c2                	cmp    %eax,%edx
f0101892:	73 05                	jae    f0101899 <__udivdi3+0xf9>
f0101894:	3b 34 24             	cmp    (%esp),%esi
f0101897:	74 1f                	je     f01018b8 <__udivdi3+0x118>
f0101899:	89 f8                	mov    %edi,%eax
f010189b:	31 d2                	xor    %edx,%edx
f010189d:	e9 7a ff ff ff       	jmp    f010181c <__udivdi3+0x7c>
f01018a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018a8:	31 d2                	xor    %edx,%edx
f01018aa:	b8 01 00 00 00       	mov    $0x1,%eax
f01018af:	e9 68 ff ff ff       	jmp    f010181c <__udivdi3+0x7c>
f01018b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018b8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01018bb:	31 d2                	xor    %edx,%edx
f01018bd:	83 c4 0c             	add    $0xc,%esp
f01018c0:	5e                   	pop    %esi
f01018c1:	5f                   	pop    %edi
f01018c2:	5d                   	pop    %ebp
f01018c3:	c3                   	ret    
f01018c4:	66 90                	xchg   %ax,%ax
f01018c6:	66 90                	xchg   %ax,%ax
f01018c8:	66 90                	xchg   %ax,%ax
f01018ca:	66 90                	xchg   %ax,%ax
f01018cc:	66 90                	xchg   %ax,%ax
f01018ce:	66 90                	xchg   %ax,%ax

f01018d0 <__umoddi3>:
f01018d0:	55                   	push   %ebp
f01018d1:	57                   	push   %edi
f01018d2:	56                   	push   %esi
f01018d3:	83 ec 14             	sub    $0x14,%esp
f01018d6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01018da:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01018de:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01018e2:	89 c7                	mov    %eax,%edi
f01018e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018e8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01018ec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018f0:	89 34 24             	mov    %esi,(%esp)
f01018f3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018f7:	85 c0                	test   %eax,%eax
f01018f9:	89 c2                	mov    %eax,%edx
f01018fb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018ff:	75 17                	jne    f0101918 <__umoddi3+0x48>
f0101901:	39 fe                	cmp    %edi,%esi
f0101903:	76 4b                	jbe    f0101950 <__umoddi3+0x80>
f0101905:	89 c8                	mov    %ecx,%eax
f0101907:	89 fa                	mov    %edi,%edx
f0101909:	f7 f6                	div    %esi
f010190b:	89 d0                	mov    %edx,%eax
f010190d:	31 d2                	xor    %edx,%edx
f010190f:	83 c4 14             	add    $0x14,%esp
f0101912:	5e                   	pop    %esi
f0101913:	5f                   	pop    %edi
f0101914:	5d                   	pop    %ebp
f0101915:	c3                   	ret    
f0101916:	66 90                	xchg   %ax,%ax
f0101918:	39 f8                	cmp    %edi,%eax
f010191a:	77 54                	ja     f0101970 <__umoddi3+0xa0>
f010191c:	0f bd e8             	bsr    %eax,%ebp
f010191f:	83 f5 1f             	xor    $0x1f,%ebp
f0101922:	75 5c                	jne    f0101980 <__umoddi3+0xb0>
f0101924:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101928:	39 3c 24             	cmp    %edi,(%esp)
f010192b:	0f 87 e7 00 00 00    	ja     f0101a18 <__umoddi3+0x148>
f0101931:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101935:	29 f1                	sub    %esi,%ecx
f0101937:	19 c7                	sbb    %eax,%edi
f0101939:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010193d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101941:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101945:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101949:	83 c4 14             	add    $0x14,%esp
f010194c:	5e                   	pop    %esi
f010194d:	5f                   	pop    %edi
f010194e:	5d                   	pop    %ebp
f010194f:	c3                   	ret    
f0101950:	85 f6                	test   %esi,%esi
f0101952:	89 f5                	mov    %esi,%ebp
f0101954:	75 0b                	jne    f0101961 <__umoddi3+0x91>
f0101956:	b8 01 00 00 00       	mov    $0x1,%eax
f010195b:	31 d2                	xor    %edx,%edx
f010195d:	f7 f6                	div    %esi
f010195f:	89 c5                	mov    %eax,%ebp
f0101961:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101965:	31 d2                	xor    %edx,%edx
f0101967:	f7 f5                	div    %ebp
f0101969:	89 c8                	mov    %ecx,%eax
f010196b:	f7 f5                	div    %ebp
f010196d:	eb 9c                	jmp    f010190b <__umoddi3+0x3b>
f010196f:	90                   	nop
f0101970:	89 c8                	mov    %ecx,%eax
f0101972:	89 fa                	mov    %edi,%edx
f0101974:	83 c4 14             	add    $0x14,%esp
f0101977:	5e                   	pop    %esi
f0101978:	5f                   	pop    %edi
f0101979:	5d                   	pop    %ebp
f010197a:	c3                   	ret    
f010197b:	90                   	nop
f010197c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101980:	8b 04 24             	mov    (%esp),%eax
f0101983:	be 20 00 00 00       	mov    $0x20,%esi
f0101988:	89 e9                	mov    %ebp,%ecx
f010198a:	29 ee                	sub    %ebp,%esi
f010198c:	d3 e2                	shl    %cl,%edx
f010198e:	89 f1                	mov    %esi,%ecx
f0101990:	d3 e8                	shr    %cl,%eax
f0101992:	89 e9                	mov    %ebp,%ecx
f0101994:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101998:	8b 04 24             	mov    (%esp),%eax
f010199b:	09 54 24 04          	or     %edx,0x4(%esp)
f010199f:	89 fa                	mov    %edi,%edx
f01019a1:	d3 e0                	shl    %cl,%eax
f01019a3:	89 f1                	mov    %esi,%ecx
f01019a5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019a9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01019ad:	d3 ea                	shr    %cl,%edx
f01019af:	89 e9                	mov    %ebp,%ecx
f01019b1:	d3 e7                	shl    %cl,%edi
f01019b3:	89 f1                	mov    %esi,%ecx
f01019b5:	d3 e8                	shr    %cl,%eax
f01019b7:	89 e9                	mov    %ebp,%ecx
f01019b9:	09 f8                	or     %edi,%eax
f01019bb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01019bf:	f7 74 24 04          	divl   0x4(%esp)
f01019c3:	d3 e7                	shl    %cl,%edi
f01019c5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019c9:	89 d7                	mov    %edx,%edi
f01019cb:	f7 64 24 08          	mull   0x8(%esp)
f01019cf:	39 d7                	cmp    %edx,%edi
f01019d1:	89 c1                	mov    %eax,%ecx
f01019d3:	89 14 24             	mov    %edx,(%esp)
f01019d6:	72 2c                	jb     f0101a04 <__umoddi3+0x134>
f01019d8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01019dc:	72 22                	jb     f0101a00 <__umoddi3+0x130>
f01019de:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01019e2:	29 c8                	sub    %ecx,%eax
f01019e4:	19 d7                	sbb    %edx,%edi
f01019e6:	89 e9                	mov    %ebp,%ecx
f01019e8:	89 fa                	mov    %edi,%edx
f01019ea:	d3 e8                	shr    %cl,%eax
f01019ec:	89 f1                	mov    %esi,%ecx
f01019ee:	d3 e2                	shl    %cl,%edx
f01019f0:	89 e9                	mov    %ebp,%ecx
f01019f2:	d3 ef                	shr    %cl,%edi
f01019f4:	09 d0                	or     %edx,%eax
f01019f6:	89 fa                	mov    %edi,%edx
f01019f8:	83 c4 14             	add    $0x14,%esp
f01019fb:	5e                   	pop    %esi
f01019fc:	5f                   	pop    %edi
f01019fd:	5d                   	pop    %ebp
f01019fe:	c3                   	ret    
f01019ff:	90                   	nop
f0101a00:	39 d7                	cmp    %edx,%edi
f0101a02:	75 da                	jne    f01019de <__umoddi3+0x10e>
f0101a04:	8b 14 24             	mov    (%esp),%edx
f0101a07:	89 c1                	mov    %eax,%ecx
f0101a09:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a0d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a11:	eb cb                	jmp    f01019de <__umoddi3+0x10e>
f0101a13:	90                   	nop
f0101a14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a18:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a1c:	0f 82 0f ff ff ff    	jb     f0101931 <__umoddi3+0x61>
f0101a22:	e9 1a ff ff ff       	jmp    f0101941 <__umoddi3+0x71>
