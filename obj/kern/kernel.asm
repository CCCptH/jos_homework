
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
	# until we set up our real page table in mem_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 8c 79 11 f0       	mov    $0xf011798c,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 27 38 00 00       	call   f010388f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8b 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 60 3d 10 f0 	movl   $0xf0103d60,(%esp)
f010007c:	e8 6b 2c 00 00       	call   f0102cec <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 8f 11 00 00       	call   f0101215 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 44 07 00 00       	call   f01007d6 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 00 73 11 f0 00 	cmpl   $0x0,0xf0117300
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 00 73 11 f0    	mov    %esi,0xf0117300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 7b 3d 10 f0 	movl   $0xf0103d7b,(%esp)
f01000c8:	e8 1f 2c 00 00       	call   f0102cec <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 e0 2b 00 00       	call   f0102cb9 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 0a 45 10 f0 	movl   $0xf010450a,(%esp)
f01000e0:	e8 07 2c 00 00       	call   f0102cec <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 e5 06 00 00       	call   f01007d6 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 93 3d 10 f0 	movl   $0xf0103d93,(%esp)
f0100112:	e8 d5 2b 00 00       	call   f0102cec <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 93 2b 00 00       	call   f0102cb9 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 0a 45 10 f0 	movl   $0xf010450a,(%esp)
f010012d:	e8 ba 2b 00 00       	call   f0102cec <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 44 75 11 f0       	mov    0xf0117544,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 44 75 11 f0    	mov    %ecx,0xf0117544
f0100179:	88 90 40 73 11 f0    	mov    %dl,-0xfee8cc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 44 75 11 f0 00 	movl   $0x0,0xf0117544
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 ef 00 00 00    	je     f010029d <kbd_proc_data+0xfd>
f01001ae:	b2 60                	mov    $0x60,%dl
f01001b0:	ec                   	in     (%dx),%al
f01001b1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b3:	3c e0                	cmp    $0xe0,%al
f01001b5:	75 0d                	jne    f01001c4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001b7:	83 0d 20 73 11 f0 40 	orl    $0x40,0xf0117320
		return 0;
f01001be:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001c3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c4:	55                   	push   %ebp
f01001c5:	89 e5                	mov    %esp,%ebp
f01001c7:	53                   	push   %ebx
f01001c8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001cb:	84 c0                	test   %al,%al
f01001cd:	79 37                	jns    f0100206 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cf:	8b 0d 20 73 11 f0    	mov    0xf0117320,%ecx
f01001d5:	89 cb                	mov    %ecx,%ebx
f01001d7:	83 e3 40             	and    $0x40,%ebx
f01001da:	83 e0 7f             	and    $0x7f,%eax
f01001dd:	85 db                	test   %ebx,%ebx
f01001df:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e2:	0f b6 d2             	movzbl %dl,%edx
f01001e5:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f01001ec:	83 c8 40             	or     $0x40,%eax
f01001ef:	0f b6 c0             	movzbl %al,%eax
f01001f2:	f7 d0                	not    %eax
f01001f4:	21 c1                	and    %eax,%ecx
f01001f6:	89 0d 20 73 11 f0    	mov    %ecx,0xf0117320
		return 0;
f01001fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100201:	e9 9d 00 00 00       	jmp    f01002a3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100206:	8b 0d 20 73 11 f0    	mov    0xf0117320,%ecx
f010020c:	f6 c1 40             	test   $0x40,%cl
f010020f:	74 0e                	je     f010021f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100211:	83 c8 80             	or     $0xffffff80,%eax
f0100214:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100216:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100219:	89 0d 20 73 11 f0    	mov    %ecx,0xf0117320
	}

	shift |= shiftcode[data];
f010021f:	0f b6 d2             	movzbl %dl,%edx
f0100222:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f0100229:	0b 05 20 73 11 f0    	or     0xf0117320,%eax
	shift ^= togglecode[data];
f010022f:	0f b6 8a 00 3e 10 f0 	movzbl -0xfefc200(%edx),%ecx
f0100236:	31 c8                	xor    %ecx,%eax
f0100238:	a3 20 73 11 f0       	mov    %eax,0xf0117320

	c = charcode[shift & (CTL | SHIFT)][data];
f010023d:	89 c1                	mov    %eax,%ecx
f010023f:	83 e1 03             	and    $0x3,%ecx
f0100242:	8b 0c 8d e0 3d 10 f0 	mov    -0xfefc220(,%ecx,4),%ecx
f0100249:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100250:	a8 08                	test   $0x8,%al
f0100252:	74 1b                	je     f010026f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100254:	89 da                	mov    %ebx,%edx
f0100256:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100259:	83 f9 19             	cmp    $0x19,%ecx
f010025c:	77 05                	ja     f0100263 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010025e:	83 eb 20             	sub    $0x20,%ebx
f0100261:	eb 0c                	jmp    f010026f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100263:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100266:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100269:	83 fa 19             	cmp    $0x19,%edx
f010026c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026f:	f7 d0                	not    %eax
f0100271:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100273:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100275:	f6 c2 06             	test   $0x6,%dl
f0100278:	75 29                	jne    f01002a3 <kbd_proc_data+0x103>
f010027a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100280:	75 21                	jne    f01002a3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100282:	c7 04 24 ad 3d 10 f0 	movl   $0xf0103dad,(%esp)
f0100289:	e8 5e 2a 00 00       	call   f0102cec <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100293:	b8 03 00 00 00       	mov    $0x3,%eax
f0100298:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100299:	89 d8                	mov    %ebx,%eax
f010029b:	eb 06                	jmp    f01002a3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010029d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002a3:	83 c4 14             	add    $0x14,%esp
f01002a6:	5b                   	pop    %ebx
f01002a7:	5d                   	pop    %ebp
f01002a8:	c3                   	ret    

f01002a9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002a9:	55                   	push   %ebp
f01002aa:	89 e5                	mov    %esp,%ebp
f01002ac:	57                   	push   %edi
f01002ad:	56                   	push   %esi
f01002ae:	53                   	push   %ebx
f01002af:	83 ec 1c             	sub    $0x1c,%esp
f01002b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002b5:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002ba:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002bb:	a8 20                	test   $0x20,%al
f01002bd:	75 21                	jne    f01002e0 <cons_putc+0x37>
f01002bf:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01002c4:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ce:	89 ca                	mov    %ecx,%edx
f01002d0:	ec                   	in     (%dx),%al
f01002d1:	ec                   	in     (%dx),%al
f01002d2:	ec                   	in     (%dx),%al
f01002d3:	ec                   	in     (%dx),%al
f01002d4:	89 f2                	mov    %esi,%edx
f01002d6:	ec                   	in     (%dx),%al
f01002d7:	a8 20                	test   $0x20,%al
f01002d9:	75 05                	jne    f01002e0 <cons_putc+0x37>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002db:	83 eb 01             	sub    $0x1,%ebx
f01002de:	75 ee                	jne    f01002ce <cons_putc+0x25>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01002e0:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e4:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002e9:	89 f8                	mov    %edi,%eax
f01002eb:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ec:	b2 79                	mov    $0x79,%dl
f01002ee:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002ef:	84 c0                	test   %al,%al
f01002f1:	78 21                	js     f0100314 <cons_putc+0x6b>
f01002f3:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01002f8:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fd:	be 79 03 00 00       	mov    $0x379,%esi
f0100302:	89 ca                	mov    %ecx,%edx
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
f0100306:	ec                   	in     (%dx),%al
f0100307:	ec                   	in     (%dx),%al
f0100308:	89 f2                	mov    %esi,%edx
f010030a:	ec                   	in     (%dx),%al
f010030b:	84 c0                	test   %al,%al
f010030d:	78 05                	js     f0100314 <cons_putc+0x6b>
f010030f:	83 eb 01             	sub    $0x1,%ebx
f0100312:	75 ee                	jne    f0100302 <cons_putc+0x59>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	ba 78 03 00 00       	mov    $0x378,%edx
f0100319:	89 f8                	mov    %edi,%eax
f010031b:	ee                   	out    %al,(%dx)
f010031c:	b2 7a                	mov    $0x7a,%dl
f010031e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100323:	ee                   	out    %al,(%dx)
f0100324:	b8 08 00 00 00       	mov    $0x8,%eax
f0100329:	ee                   	out    %al,(%dx)
static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	// if (!(c & ~0xFF))
		c |= 0x0400;
f010032a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010032d:	80 cc 04             	or     $0x4,%ah

	switch (c & 0xff) {
f0100330:	83 ff 09             	cmp    $0x9,%edi
f0100333:	74 76                	je     f01003ab <cons_putc+0x102>
f0100335:	83 ff 09             	cmp    $0x9,%edi
f0100338:	7f 0b                	jg     f0100345 <cons_putc+0x9c>
f010033a:	83 ff 08             	cmp    $0x8,%edi
f010033d:	74 18                	je     f0100357 <cons_putc+0xae>
f010033f:	90                   	nop
f0100340:	e9 9a 00 00 00       	jmp    f01003df <cons_putc+0x136>
f0100345:	83 ff 0a             	cmp    $0xa,%edi
f0100348:	74 3b                	je     f0100385 <cons_putc+0xdc>
f010034a:	83 ff 0d             	cmp    $0xd,%edi
f010034d:	8d 76 00             	lea    0x0(%esi),%esi
f0100350:	74 3b                	je     f010038d <cons_putc+0xe4>
f0100352:	e9 88 00 00 00       	jmp    f01003df <cons_putc+0x136>
	case '\b':
		if (crt_pos > 0) {
f0100357:	0f b7 15 48 75 11 f0 	movzwl 0xf0117548,%edx
f010035e:	66 85 d2             	test   %dx,%dx
f0100361:	0f 84 e3 00 00 00    	je     f010044a <cons_putc+0x1a1>
			crt_pos--;
f0100367:	83 ea 01             	sub    $0x1,%edx
f010036a:	66 89 15 48 75 11 f0 	mov    %dx,0xf0117548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100371:	0f b7 d2             	movzwl %dx,%edx
f0100374:	b0 00                	mov    $0x0,%al
f0100376:	83 c8 20             	or     $0x20,%eax
f0100379:	8b 0d 4c 75 11 f0    	mov    0xf011754c,%ecx
f010037f:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100383:	eb 78                	jmp    f01003fd <cons_putc+0x154>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100385:	66 83 05 48 75 11 f0 	addw   $0x50,0xf0117548
f010038c:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038d:	0f b7 05 48 75 11 f0 	movzwl 0xf0117548,%eax
f0100394:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010039a:	c1 e8 16             	shr    $0x16,%eax
f010039d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a0:	c1 e0 04             	shl    $0x4,%eax
f01003a3:	66 a3 48 75 11 f0    	mov    %ax,0xf0117548
f01003a9:	eb 52                	jmp    f01003fd <cons_putc+0x154>
		break;
	case '\t':
		cons_putc(' ');
f01003ab:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b0:	e8 f4 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003b5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ba:	e8 ea fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 e0 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 d6 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 cc fe ff ff       	call   f01002a9 <cons_putc>
f01003dd:	eb 1e                	jmp    f01003fd <cons_putc+0x154>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003df:	0f b7 15 48 75 11 f0 	movzwl 0xf0117548,%edx
f01003e6:	8d 4a 01             	lea    0x1(%edx),%ecx
f01003e9:	66 89 0d 48 75 11 f0 	mov    %cx,0xf0117548
f01003f0:	0f b7 d2             	movzwl %dx,%edx
f01003f3:	8b 0d 4c 75 11 f0    	mov    0xf011754c,%ecx
f01003f9:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fd:	66 81 3d 48 75 11 f0 	cmpw   $0x7cf,0xf0117548
f0100404:	cf 07 
f0100406:	76 42                	jbe    f010044a <cons_putc+0x1a1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100408:	a1 4c 75 11 f0       	mov    0xf011754c,%eax
f010040d:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100414:	00 
f0100415:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010041f:	89 04 24             	mov    %eax,(%esp)
f0100422:	e8 b5 34 00 00       	call   f01038dc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100427:	8b 15 4c 75 11 f0    	mov    0xf011754c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010042d:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100432:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100438:	83 c0 01             	add    $0x1,%eax
f010043b:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100440:	75 f0                	jne    f0100432 <cons_putc+0x189>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 48 75 11 f0 	subw   $0x50,0xf0117548
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 50 75 11 f0    	mov    0xf0117550,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 48 75 11 f0 	movzwl 0xf0117548,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	83 c4 1c             	add    $0x1c,%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	83 3d 54 75 11 f0 00 	cmpl   $0x0,0xf0117554
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f0100494:	e8 c3 fc ff ff       	call   f010015c <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004a7:	e8 b0 fc ff ff       	call   f010015c <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f01004c3:	3b 05 44 75 11 f0    	cmp    0xf0117544,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 40 75 11 f0    	mov    %edx,0xf0117540
f01004d4:	0f b6 88 40 73 11 f0 	movzbl -0xfee8cc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 40 75 11 f0 00 	movl   $0x0,0xf0117540
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 50 75 11 f0 b4 	movl   $0x3b4,0xf0117550
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 50 75 11 f0 d4 	movl   $0x3d4,0xf0117550
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 0d 50 75 11 f0    	mov    0xf0117550,%ecx
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 ca                	mov    %ecx,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 f0             	movzbl %al,%esi
f010055c:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 ca                	mov    %ecx,%edx
f0100566:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 3d 4c 75 11 f0    	mov    %edi,0xf011754c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100570:	0f b6 d8             	movzbl %al,%ebx
f0100573:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100575:	66 89 35 48 75 11 f0 	mov    %si,0xf0117548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057c:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100581:	b8 00 00 00 00       	mov    $0x0,%eax
f0100586:	89 f2                	mov    %esi,%edx
f0100588:	ee                   	out    %al,(%dx)
f0100589:	b2 fb                	mov    $0xfb,%dl
f010058b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100590:	ee                   	out    %al,(%dx)
f0100591:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100596:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059b:	89 da                	mov    %ebx,%edx
f010059d:	ee                   	out    %al,(%dx)
f010059e:	b2 f9                	mov    $0xf9,%dl
f01005a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a5:	ee                   	out    %al,(%dx)
f01005a6:	b2 fb                	mov    $0xfb,%dl
f01005a8:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ad:	ee                   	out    %al,(%dx)
f01005ae:	b2 fc                	mov    $0xfc,%dl
f01005b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	b2 f9                	mov    $0xf9,%dl
f01005b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005be:	b2 fd                	mov    $0xfd,%dl
f01005c0:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c1:	3c ff                	cmp    $0xff,%al
f01005c3:	0f 95 c1             	setne  %cl
f01005c6:	0f b6 c9             	movzbl %cl,%ecx
f01005c9:	89 0d 54 75 11 f0    	mov    %ecx,0xf0117554
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	85 c9                	test   %ecx,%ecx
f01005d7:	75 0c                	jne    f01005e5 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f01005d9:	c7 04 24 b9 3d 10 f0 	movl   $0xf0103db9,(%esp)
f01005e0:	e8 07 27 00 00       	call   f0102cec <cprintf>
}
f01005e5:	83 c4 1c             	add    $0x1c,%esp
f01005e8:	5b                   	pop    %ebx
f01005e9:	5e                   	pop    %esi
f01005ea:	5f                   	pop    %edi
f01005eb:	5d                   	pop    %ebp
f01005ec:	c3                   	ret    

f01005ed <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005ed:	55                   	push   %ebp
f01005ee:	89 e5                	mov    %esp,%ebp
f01005f0:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01005f6:	e8 ae fc ff ff       	call   f01002a9 <cons_putc>
}
f01005fb:	c9                   	leave  
f01005fc:	c3                   	ret    

f01005fd <getchar>:

int
getchar(void)
{
f01005fd:	55                   	push   %ebp
f01005fe:	89 e5                	mov    %esp,%ebp
f0100600:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100603:	e8 a6 fe ff ff       	call   f01004ae <cons_getc>
f0100608:	85 c0                	test   %eax,%eax
f010060a:	74 f7                	je     f0100603 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010060c:	c9                   	leave  
f010060d:	c3                   	ret    

f010060e <iscons>:

int
iscons(int fdnum)
{
f010060e:	55                   	push   %ebp
f010060f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100611:	b8 01 00 00 00       	mov    $0x1,%eax
f0100616:	5d                   	pop    %ebp
f0100617:	c3                   	ret    
f0100618:	66 90                	xchg   %ax,%ax
f010061a:	66 90                	xchg   %ax,%ax
f010061c:	66 90                	xchg   %ax,%ax
f010061e:	66 90                	xchg   %ax,%ax

f0100620 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100626:	c7 44 24 08 0b 45 10 	movl   $0xf010450b,0x8(%esp)
f010062d:	f0 
f010062e:	c7 44 24 04 00 40 10 	movl   $0xf0104000,0x4(%esp)
f0100635:	f0 
f0100636:	c7 04 24 0a 40 10 f0 	movl   $0xf010400a,(%esp)
f010063d:	e8 aa 26 00 00       	call   f0102cec <cprintf>
f0100642:	c7 44 24 08 13 40 10 	movl   $0xf0104013,0x8(%esp)
f0100649:	f0 
f010064a:	c7 44 24 04 31 40 10 	movl   $0xf0104031,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 0a 40 10 f0 	movl   $0xf010400a,(%esp)
f0100659:	e8 8e 26 00 00       	call   f0102cec <cprintf>
f010065e:	c7 44 24 08 c8 40 10 	movl   $0xf01040c8,0x8(%esp)
f0100665:	f0 
f0100666:	c7 44 24 04 36 40 10 	movl   $0xf0104036,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 0a 40 10 f0 	movl   $0xf010400a,(%esp)
f0100675:	e8 72 26 00 00       	call   f0102cec <cprintf>
	return 0;
}
f010067a:	b8 00 00 00 00       	mov    $0x0,%eax
f010067f:	c9                   	leave  
f0100680:	c3                   	ret    

f0100681 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100687:	c7 04 24 3f 40 10 f0 	movl   $0xf010403f,(%esp)
f010068e:	e8 59 26 00 00       	call   f0102cec <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100693:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010069a:	00 
f010069b:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006a2:	f0 
f01006a3:	c7 04 24 f0 40 10 f0 	movl   $0xf01040f0,(%esp)
f01006aa:	e8 3d 26 00 00       	call   f0102cec <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006af:	c7 44 24 08 57 3d 10 	movl   $0x103d57,0x8(%esp)
f01006b6:	00 
f01006b7:	c7 44 24 04 57 3d 10 	movl   $0xf0103d57,0x4(%esp)
f01006be:	f0 
f01006bf:	c7 04 24 14 41 10 f0 	movl   $0xf0104114,(%esp)
f01006c6:	e8 21 26 00 00       	call   f0102cec <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006cb:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006d2:	00 
f01006d3:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006da:	f0 
f01006db:	c7 04 24 38 41 10 f0 	movl   $0xf0104138,(%esp)
f01006e2:	e8 05 26 00 00       	call   f0102cec <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e7:	c7 44 24 08 8c 79 11 	movl   $0x11798c,0x8(%esp)
f01006ee:	00 
f01006ef:	c7 44 24 04 8c 79 11 	movl   $0xf011798c,0x4(%esp)
f01006f6:	f0 
f01006f7:	c7 04 24 5c 41 10 f0 	movl   $0xf010415c,(%esp)
f01006fe:	e8 e9 25 00 00       	call   f0102cec <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100703:	b8 8b 7d 11 f0       	mov    $0xf0117d8b,%eax
f0100708:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010070d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100713:	85 c0                	test   %eax,%eax
f0100715:	0f 48 c2             	cmovs  %edx,%eax
f0100718:	c1 f8 0a             	sar    $0xa,%eax
f010071b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071f:	c7 04 24 80 41 10 f0 	movl   $0xf0104180,(%esp)
f0100726:	e8 c1 25 00 00       	call   f0102cec <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010072b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100730:	c9                   	leave  
f0100731:	c3                   	ret    

f0100732 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100732:	55                   	push   %ebp
f0100733:	89 e5                	mov    %esp,%ebp
f0100735:	56                   	push   %esi
f0100736:	53                   	push   %ebx
f0100737:	83 ec 10             	sub    $0x10,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010073a:	89 ee                	mov    %ebp,%esi
	// Your code here.
	volatile uint32_t* ebp = (uint32_t*)read_ebp();
f010073c:	89 f3                	mov    %esi,%ebx
	// uint32_t* esp = (uint32_t*)read_esp();
	cprintf("Stack backtrace:\n");
f010073e:	c7 04 24 58 40 10 f0 	movl   $0xf0104058,(%esp)
f0100745:	e8 a2 25 00 00       	call   f0102cec <cprintf>
	while(ebp)
f010074a:	85 f6                	test   %esi,%esi
f010074c:	74 7c                	je     f01007ca <mon_backtrace+0x98>
	{
		cprintf("ebp %x, eip %x args", ebp, ebp[1]);
f010074e:	8b 43 04             	mov    0x4(%ebx),%eax
f0100751:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100755:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100759:	c7 04 24 6a 40 10 f0 	movl   $0xf010406a,(%esp)
f0100760:	e8 87 25 00 00       	call   f0102cec <cprintf>
		cprintf(" %08x", ebp[2]);
f0100765:	8b 43 08             	mov    0x8(%ebx),%eax
f0100768:	89 44 24 04          	mov    %eax,0x4(%esp)
f010076c:	c7 04 24 7e 40 10 f0 	movl   $0xf010407e,(%esp)
f0100773:	e8 74 25 00 00       	call   f0102cec <cprintf>
		cprintf(" %08x", ebp[3]);
f0100778:	8b 43 0c             	mov    0xc(%ebx),%eax
f010077b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077f:	c7 04 24 7e 40 10 f0 	movl   $0xf010407e,(%esp)
f0100786:	e8 61 25 00 00       	call   f0102cec <cprintf>
		cprintf(" %08x", ebp[4]);
f010078b:	8b 43 10             	mov    0x10(%ebx),%eax
f010078e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100792:	c7 04 24 7e 40 10 f0 	movl   $0xf010407e,(%esp)
f0100799:	e8 4e 25 00 00       	call   f0102cec <cprintf>
		cprintf(" %08x", ebp[5]);
f010079e:	8b 43 14             	mov    0x14(%ebx),%eax
f01007a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a5:	c7 04 24 7e 40 10 f0 	movl   $0xf010407e,(%esp)
f01007ac:	e8 3b 25 00 00       	call   f0102cec <cprintf>
		cprintf(" %08x\n", ebp[6]);
f01007b1:	8b 43 18             	mov    0x18(%ebx),%eax
f01007b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b8:	c7 04 24 84 40 10 f0 	movl   $0xf0104084,(%esp)
f01007bf:	e8 28 25 00 00       	call   f0102cec <cprintf>
		// cprintf("----->  esp: %x", esp);
		ebp = (uint32_t*) *ebp;
f01007c4:	8b 1b                	mov    (%ebx),%ebx
{
	// Your code here.
	volatile uint32_t* ebp = (uint32_t*)read_ebp();
	// uint32_t* esp = (uint32_t*)read_esp();
	cprintf("Stack backtrace:\n");
	while(ebp)
f01007c6:	85 db                	test   %ebx,%ebx
f01007c8:	75 84                	jne    f010074e <mon_backtrace+0x1c>
		// cprintf("=====>  esp: %x \n", esp);
		// cprintf("=====> *ebp: %x \n", *ebp);
		// cprintf("=====> *esp: %x \n", *esp);
	}
	return 0;
}
f01007ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01007cf:	83 c4 10             	add    $0x10,%esp
f01007d2:	5b                   	pop    %ebx
f01007d3:	5e                   	pop    %esi
f01007d4:	5d                   	pop    %ebp
f01007d5:	c3                   	ret    

f01007d6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007d6:	55                   	push   %ebp
f01007d7:	89 e5                	mov    %esp,%ebp
f01007d9:	57                   	push   %edi
f01007da:	56                   	push   %esi
f01007db:	53                   	push   %ebx
f01007dc:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007df:	c7 04 24 ac 41 10 f0 	movl   $0xf01041ac,(%esp)
f01007e6:	e8 01 25 00 00       	call   f0102cec <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007eb:	c7 04 24 d0 41 10 f0 	movl   $0xf01041d0,(%esp)
f01007f2:	e8 f5 24 00 00       	call   f0102cec <cprintf>


	while (1) {
		buf = readline("K> ");
f01007f7:	c7 04 24 8b 40 10 f0 	movl   $0xf010408b,(%esp)
f01007fe:	e8 dd 2d 00 00       	call   f01035e0 <readline>
f0100803:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100805:	85 c0                	test   %eax,%eax
f0100807:	74 ee                	je     f01007f7 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100809:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100810:	be 00 00 00 00       	mov    $0x0,%esi
f0100815:	eb 0a                	jmp    f0100821 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100817:	c6 03 00             	movb   $0x0,(%ebx)
f010081a:	89 f7                	mov    %esi,%edi
f010081c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010081f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100821:	0f b6 03             	movzbl (%ebx),%eax
f0100824:	84 c0                	test   %al,%al
f0100826:	74 6a                	je     f0100892 <monitor+0xbc>
f0100828:	0f be c0             	movsbl %al,%eax
f010082b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010082f:	c7 04 24 8f 40 10 f0 	movl   $0xf010408f,(%esp)
f0100836:	e8 f3 2f 00 00       	call   f010382e <strchr>
f010083b:	85 c0                	test   %eax,%eax
f010083d:	75 d8                	jne    f0100817 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010083f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100842:	74 4e                	je     f0100892 <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100844:	83 fe 0f             	cmp    $0xf,%esi
f0100847:	75 16                	jne    f010085f <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100849:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100850:	00 
f0100851:	c7 04 24 94 40 10 f0 	movl   $0xf0104094,(%esp)
f0100858:	e8 8f 24 00 00       	call   f0102cec <cprintf>
f010085d:	eb 98                	jmp    f01007f7 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010085f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100862:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100866:	0f b6 03             	movzbl (%ebx),%eax
f0100869:	84 c0                	test   %al,%al
f010086b:	75 0c                	jne    f0100879 <monitor+0xa3>
f010086d:	eb b0                	jmp    f010081f <monitor+0x49>
			buf++;
f010086f:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100872:	0f b6 03             	movzbl (%ebx),%eax
f0100875:	84 c0                	test   %al,%al
f0100877:	74 a6                	je     f010081f <monitor+0x49>
f0100879:	0f be c0             	movsbl %al,%eax
f010087c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100880:	c7 04 24 8f 40 10 f0 	movl   $0xf010408f,(%esp)
f0100887:	e8 a2 2f 00 00       	call   f010382e <strchr>
f010088c:	85 c0                	test   %eax,%eax
f010088e:	74 df                	je     f010086f <monitor+0x99>
f0100890:	eb 8d                	jmp    f010081f <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f0100892:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100899:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010089a:	85 f6                	test   %esi,%esi
f010089c:	0f 84 55 ff ff ff    	je     f01007f7 <monitor+0x21>
f01008a2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008a7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008aa:	8b 04 85 00 42 10 f0 	mov    -0xfefbe00(,%eax,4),%eax
f01008b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b5:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008b8:	89 04 24             	mov    %eax,(%esp)
f01008bb:	e8 ea 2e 00 00       	call   f01037aa <strcmp>
f01008c0:	85 c0                	test   %eax,%eax
f01008c2:	75 24                	jne    f01008e8 <monitor+0x112>
			return commands[i].func(argc, argv, tf);
f01008c4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c7:	8b 55 08             	mov    0x8(%ebp),%edx
f01008ca:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008ce:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008d1:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01008d5:	89 34 24             	mov    %esi,(%esp)
f01008d8:	ff 14 85 08 42 10 f0 	call   *-0xfefbdf8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008df:	85 c0                	test   %eax,%eax
f01008e1:	78 27                	js     f010090a <monitor+0x134>
f01008e3:	e9 0f ff ff ff       	jmp    f01007f7 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008e8:	83 c3 01             	add    $0x1,%ebx
f01008eb:	83 fb 03             	cmp    $0x3,%ebx
f01008ee:	66 90                	xchg   %ax,%ax
f01008f0:	75 b5                	jne    f01008a7 <monitor+0xd1>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008f2:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f9:	c7 04 24 b1 40 10 f0 	movl   $0xf01040b1,(%esp)
f0100900:	e8 e7 23 00 00       	call   f0102cec <cprintf>
f0100905:	e9 ed fe ff ff       	jmp    f01007f7 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010090a:	83 c4 5c             	add    $0x5c,%esp
f010090d:	5b                   	pop    %ebx
f010090e:	5e                   	pop    %esi
f010090f:	5f                   	pop    %edi
f0100910:	5d                   	pop    %ebp
f0100911:	c3                   	ret    

f0100912 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100912:	55                   	push   %ebp
f0100913:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100915:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100918:	5d                   	pop    %ebp
f0100919:	c3                   	ret    
f010091a:	66 90                	xchg   %ax,%ax
f010091c:	66 90                	xchg   %ax,%ax
f010091e:	66 90                	xchg   %ax,%ax

f0100920 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100920:	55                   	push   %ebp
f0100921:	89 e5                	mov    %esp,%ebp
f0100923:	53                   	push   %ebx
f0100924:	83 ec 14             	sub    $0x14,%esp
f0100927:	89 c3                	mov    %eax,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100929:	83 3d 58 75 11 f0 00 	cmpl   $0x0,0xf0117558
f0100930:	75 1b                	jne    f010094d <boot_alloc+0x2d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100932:	b8 8b 89 11 f0       	mov    $0xf011898b,%eax
f0100937:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010093c:	a3 58 75 11 f0       	mov    %eax,0xf0117558
		cprintf("initial boot_alloc\n");
f0100941:	c7 04 24 24 42 10 f0 	movl   $0xf0104224,(%esp)
f0100948:	e8 9f 23 00 00       	call   f0102cec <cprintf>
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
		return next;
	}
	else
	{
		return nextfree;
f010094d:	a1 58 75 11 f0       	mov    0xf0117558,%eax
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//

	if (n!=0)
f0100952:	85 db                	test   %ebx,%ebx
f0100954:	74 13                	je     f0100969 <boot_alloc+0x49>
	{
		char* next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f0100956:	8d 94 18 ff 0f 00 00 	lea    0xfff(%eax,%ebx,1),%edx
f010095d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100963:	89 15 58 75 11 f0    	mov    %edx,0xf0117558
	}

	// LAB 2: Your code here.

	return NULL;
}
f0100969:	83 c4 14             	add    $0x14,%esp
f010096c:	5b                   	pop    %ebx
f010096d:	5d                   	pop    %ebp
f010096e:	c3                   	ret    

f010096f <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010096f:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100975:	c1 f8 03             	sar    $0x3,%eax
f0100978:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010097b:	89 c2                	mov    %eax,%edx
f010097d:	c1 ea 0c             	shr    $0xc,%edx
f0100980:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100986:	72 26                	jb     f01009ae <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct Page *pp)
{
f0100988:	55                   	push   %ebp
f0100989:	89 e5                	mov    %esp,%ebp
f010098b:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010098e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100992:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0100999:	f0 
f010099a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01009a1:	00 
f01009a2:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f01009a9:	e8 e6 f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01009ae:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
}
f01009b3:	c3                   	ret    

f01009b4 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009b4:	89 d1                	mov    %edx,%ecx
f01009b6:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009b9:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009bc:	a8 01                	test   $0x1,%al
f01009be:	74 5d                	je     f0100a1d <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009c0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009c5:	89 c1                	mov    %eax,%ecx
f01009c7:	c1 e9 0c             	shr    $0xc,%ecx
f01009ca:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f01009d0:	72 26                	jb     f01009f8 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009d2:	55                   	push   %ebp
f01009d3:	89 e5                	mov    %esp,%ebp
f01009d5:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009d8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009dc:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f01009e3:	f0 
f01009e4:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f01009eb:	00 
f01009ec:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01009f3:	e8 9c f6 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009f8:	c1 ea 0c             	shr    $0xc,%edx
f01009fb:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a01:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a08:	89 c2                	mov    %eax,%edx
f0100a0a:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a0d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a12:	85 d2                	test   %edx,%edx
f0100a14:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a19:	0f 44 c2             	cmove  %edx,%eax
f0100a1c:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a22:	c3                   	ret    

f0100a23 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a23:	55                   	push   %ebp
f0100a24:	89 e5                	mov    %esp,%ebp
f0100a26:	57                   	push   %edi
f0100a27:	56                   	push   %esi
f0100a28:	53                   	push   %ebx
f0100a29:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a2c:	85 c0                	test   %eax,%eax
f0100a2e:	0f 85 35 03 00 00    	jne    f0100d69 <check_page_free_list+0x346>
f0100a34:	e9 42 03 00 00       	jmp    f0100d7b <check_page_free_list+0x358>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a39:	c7 44 24 08 6c 45 10 	movl   $0xf010456c,0x8(%esp)
f0100a40:	f0 
f0100a41:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
f0100a48:	00 
f0100a49:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100a50:	e8 3f f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100a55:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a58:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a5b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a5e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a61:	89 c2                	mov    %eax,%edx
f0100a63:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a69:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a6f:	0f 95 c2             	setne  %dl
f0100a72:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a75:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a79:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a7b:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a7f:	8b 00                	mov    (%eax),%eax
f0100a81:	85 c0                	test   %eax,%eax
f0100a83:	75 dc                	jne    f0100a61 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a85:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a88:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a91:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a94:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a96:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a99:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a9e:	89 c3                	mov    %eax,%ebx
f0100aa0:	85 c0                	test   %eax,%eax
f0100aa2:	74 6c                	je     f0100b10 <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100aa4:	be 01 00 00 00       	mov    $0x1,%esi
f0100aa9:	89 d8                	mov    %ebx,%eax
f0100aab:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100ab1:	c1 f8 03             	sar    $0x3,%eax
f0100ab4:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ab7:	89 c2                	mov    %eax,%edx
f0100ab9:	c1 ea 16             	shr    $0x16,%edx
f0100abc:	39 f2                	cmp    %esi,%edx
f0100abe:	73 4a                	jae    f0100b0a <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ac0:	89 c2                	mov    %eax,%edx
f0100ac2:	c1 ea 0c             	shr    $0xc,%edx
f0100ac5:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100acb:	72 20                	jb     f0100aed <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100acd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ad1:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0100ad8:	f0 
f0100ad9:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ae0:	00 
f0100ae1:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f0100ae8:	e8 a7 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aed:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100af4:	00 
f0100af5:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100afc:	00 
	return (void *)(pa + KERNBASE);
f0100afd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b02:	89 04 24             	mov    %eax,(%esp)
f0100b05:	e8 85 2d 00 00       	call   f010388f <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b0a:	8b 1b                	mov    (%ebx),%ebx
f0100b0c:	85 db                	test   %ebx,%ebx
f0100b0e:	75 99                	jne    f0100aa9 <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b10:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b15:	e8 06 fe ff ff       	call   f0100920 <boot_alloc>
f0100b1a:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b1d:	8b 15 5c 75 11 f0    	mov    0xf011755c,%edx
f0100b23:	85 d2                	test   %edx,%edx
f0100b25:	0f 84 f2 01 00 00    	je     f0100d1d <check_page_free_list+0x2fa>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b2b:	8b 1d 88 79 11 f0    	mov    0xf0117988,%ebx
f0100b31:	39 da                	cmp    %ebx,%edx
f0100b33:	72 3f                	jb     f0100b74 <check_page_free_list+0x151>
		assert(pp < pages + npages);
f0100b35:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0100b3a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b3d:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b40:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b43:	39 c2                	cmp    %eax,%edx
f0100b45:	73 56                	jae    f0100b9d <check_page_free_list+0x17a>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b47:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b4a:	89 d0                	mov    %edx,%eax
f0100b4c:	29 d8                	sub    %ebx,%eax
f0100b4e:	a8 07                	test   $0x7,%al
f0100b50:	75 78                	jne    f0100bca <check_page_free_list+0x1a7>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b52:	c1 f8 03             	sar    $0x3,%eax
f0100b55:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b58:	85 c0                	test   %eax,%eax
f0100b5a:	0f 84 98 00 00 00    	je     f0100bf8 <check_page_free_list+0x1d5>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b60:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b65:	0f 85 dc 00 00 00    	jne    f0100c47 <check_page_free_list+0x224>
f0100b6b:	e9 b3 00 00 00       	jmp    f0100c23 <check_page_free_list+0x200>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b70:	39 d3                	cmp    %edx,%ebx
f0100b72:	76 24                	jbe    f0100b98 <check_page_free_list+0x175>
f0100b74:	c7 44 24 0c 52 42 10 	movl   $0xf0104252,0xc(%esp)
f0100b7b:	f0 
f0100b7c:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100b83:	f0 
f0100b84:	c7 44 24 04 22 02 00 	movl   $0x222,0x4(%esp)
f0100b8b:	00 
f0100b8c:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100b93:	e8 fc f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100b98:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b9b:	72 24                	jb     f0100bc1 <check_page_free_list+0x19e>
f0100b9d:	c7 44 24 0c 73 42 10 	movl   $0xf0104273,0xc(%esp)
f0100ba4:	f0 
f0100ba5:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100bac:	f0 
f0100bad:	c7 44 24 04 23 02 00 	movl   $0x223,0x4(%esp)
f0100bb4:	00 
f0100bb5:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100bbc:	e8 d3 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bc1:	89 d0                	mov    %edx,%eax
f0100bc3:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bc6:	a8 07                	test   $0x7,%al
f0100bc8:	74 24                	je     f0100bee <check_page_free_list+0x1cb>
f0100bca:	c7 44 24 0c 90 45 10 	movl   $0xf0104590,0xc(%esp)
f0100bd1:	f0 
f0100bd2:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100bd9:	f0 
f0100bda:	c7 44 24 04 24 02 00 	movl   $0x224,0x4(%esp)
f0100be1:	00 
f0100be2:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100be9:	e8 a6 f4 ff ff       	call   f0100094 <_panic>
f0100bee:	c1 f8 03             	sar    $0x3,%eax
f0100bf1:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bf4:	85 c0                	test   %eax,%eax
f0100bf6:	75 24                	jne    f0100c1c <check_page_free_list+0x1f9>
f0100bf8:	c7 44 24 0c 87 42 10 	movl   $0xf0104287,0xc(%esp)
f0100bff:	f0 
f0100c00:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100c07:	f0 
f0100c08:	c7 44 24 04 27 02 00 	movl   $0x227,0x4(%esp)
f0100c0f:	00 
f0100c10:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100c17:	e8 78 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c1c:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c21:	75 2e                	jne    f0100c51 <check_page_free_list+0x22e>
f0100c23:	c7 44 24 0c 98 42 10 	movl   $0xf0104298,0xc(%esp)
f0100c2a:	f0 
f0100c2b:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100c32:	f0 
f0100c33:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
f0100c3a:	00 
f0100c3b:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100c42:	e8 4d f4 ff ff       	call   f0100094 <_panic>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c47:	be 00 00 00 00       	mov    $0x0,%esi
f0100c4c:	bf 00 00 00 00       	mov    $0x0,%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c51:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c56:	75 24                	jne    f0100c7c <check_page_free_list+0x259>
f0100c58:	c7 44 24 0c c4 45 10 	movl   $0xf01045c4,0xc(%esp)
f0100c5f:	f0 
f0100c60:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100c67:	f0 
f0100c68:	c7 44 24 04 29 02 00 	movl   $0x229,0x4(%esp)
f0100c6f:	00 
f0100c70:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100c77:	e8 18 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c7c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c81:	75 24                	jne    f0100ca7 <check_page_free_list+0x284>
f0100c83:	c7 44 24 0c b1 42 10 	movl   $0xf01042b1,0xc(%esp)
f0100c8a:	f0 
f0100c8b:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100c92:	f0 
f0100c93:	c7 44 24 04 2a 02 00 	movl   $0x22a,0x4(%esp)
f0100c9a:	00 
f0100c9b:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100ca2:	e8 ed f3 ff ff       	call   f0100094 <_panic>
f0100ca7:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ca9:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cae:	76 57                	jbe    f0100d07 <check_page_free_list+0x2e4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cb0:	c1 e8 0c             	shr    $0xc,%eax
f0100cb3:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100cb6:	77 20                	ja     f0100cd8 <check_page_free_list+0x2b5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cb8:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100cbc:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0100cc3:	f0 
f0100cc4:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ccb:	00 
f0100ccc:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f0100cd3:	e8 bc f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100cd8:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100cde:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f0100ce1:	76 29                	jbe    f0100d0c <check_page_free_list+0x2e9>
f0100ce3:	c7 44 24 0c e8 45 10 	movl   $0xf01045e8,0xc(%esp)
f0100cea:	f0 
f0100ceb:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100cf2:	f0 
f0100cf3:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
f0100cfa:	00 
f0100cfb:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100d02:	e8 8d f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d07:	83 c7 01             	add    $0x1,%edi
f0100d0a:	eb 03                	jmp    f0100d0f <check_page_free_list+0x2ec>
		else
			++nfree_extmem;
f0100d0c:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d0f:	8b 12                	mov    (%edx),%edx
f0100d11:	85 d2                	test   %edx,%edx
f0100d13:	0f 85 57 fe ff ff    	jne    f0100b70 <check_page_free_list+0x14d>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d19:	85 ff                	test   %edi,%edi
f0100d1b:	7f 24                	jg     f0100d41 <check_page_free_list+0x31e>
f0100d1d:	c7 44 24 0c cb 42 10 	movl   $0xf01042cb,0xc(%esp)
f0100d24:	f0 
f0100d25:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100d2c:	f0 
f0100d2d:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0100d34:	00 
f0100d35:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100d3c:	e8 53 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d41:	85 f6                	test   %esi,%esi
f0100d43:	7f 53                	jg     f0100d98 <check_page_free_list+0x375>
f0100d45:	c7 44 24 0c dd 42 10 	movl   $0xf01042dd,0xc(%esp)
f0100d4c:	f0 
f0100d4d:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0100d54:	f0 
f0100d55:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
f0100d5c:	00 
f0100d5d:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100d64:	e8 2b f3 ff ff       	call   f0100094 <_panic>
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d69:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f0100d6e:	85 c0                	test   %eax,%eax
f0100d70:	0f 85 df fc ff ff    	jne    f0100a55 <check_page_free_list+0x32>
f0100d76:	e9 be fc ff ff       	jmp    f0100a39 <check_page_free_list+0x16>
f0100d7b:	83 3d 5c 75 11 f0 00 	cmpl   $0x0,0xf011755c
f0100d82:	0f 84 b1 fc ff ff    	je     f0100a39 <check_page_free_list+0x16>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d88:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d8e:	be 00 04 00 00       	mov    $0x400,%esi
f0100d93:	e9 11 fd ff ff       	jmp    f0100aa9 <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100d98:	83 c4 3c             	add    $0x3c,%esp
f0100d9b:	5b                   	pop    %ebx
f0100d9c:	5e                   	pop    %esi
f0100d9d:	5f                   	pop    %edi
f0100d9e:	5d                   	pop    %ebp
f0100d9f:	c3                   	ret    

f0100da0 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100da0:	55                   	push   %ebp
f0100da1:	89 e5                	mov    %esp,%ebp
f0100da3:	56                   	push   %esi
f0100da4:	53                   	push   %ebx
f0100da5:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	cprintf("page_init called\n");
f0100da8:	c7 04 24 ee 42 10 f0 	movl   $0xf01042ee,(%esp)
f0100daf:	e8 38 1f 00 00       	call   f0102cec <cprintf>
	for (i = 1; i < npages_basemem; i++) {
f0100db4:	8b 35 60 75 11 f0    	mov    0xf0117560,%esi
f0100dba:	83 fe 01             	cmp    $0x1,%esi
f0100dbd:	0f 86 2b 01 00 00    	jbe    f0100eee <page_init+0x14e>
f0100dc3:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
f0100dc9:	b8 01 00 00 00       	mov    $0x1,%eax
f0100dce:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100dd5:	89 d1                	mov    %edx,%ecx
f0100dd7:	03 0d 88 79 11 f0    	add    0xf0117988,%ecx
f0100ddd:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100de3:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100de5:	03 15 88 79 11 f0    	add    0xf0117988,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	cprintf("page_init called\n");
	for (i = 1; i < npages_basemem; i++) {
f0100deb:	83 c0 01             	add    $0x1,%eax
f0100dee:	39 f0                	cmp    %esi,%eax
f0100df0:	72 0b                	jb     f0100dfd <page_init+0x5d>
f0100df2:	89 15 5c 75 11 f0    	mov    %edx,0xf011755c
f0100df8:	e9 f1 00 00 00       	jmp    f0100eee <page_init+0x14e>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100dfd:	89 d3                	mov    %edx,%ebx
f0100dff:	eb cd                	jmp    f0100dce <page_init+0x2e>
	}
	for (i = IOPHYSMEM/PGSIZE;i < EXTPHYSMEM/PGSIZE;i++)
	{
		pages[i].pp_ref=1;
f0100e01:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for (i = 1; i < npages_basemem; i++) {
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	for (i = IOPHYSMEM/PGSIZE;i < EXTPHYSMEM/PGSIZE;i++)
f0100e08:	83 c3 01             	add    $0x1,%ebx
f0100e0b:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100e11:	75 ee                	jne    f0100e01 <page_init+0x61>
f0100e13:	eb 0f                	jmp    f0100e24 <page_init+0x84>
	{
		pages[i].pp_ref=1;
	}
	for (i = EXTPHYSMEM/PGSIZE;i<PADDR(boot_alloc(0))/PGSIZE;i++)
	{
		pages[i].pp_ref = 1;
f0100e15:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0100e1a:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	}
	for (i = IOPHYSMEM/PGSIZE;i < EXTPHYSMEM/PGSIZE;i++)
	{
		pages[i].pp_ref=1;
	}
	for (i = EXTPHYSMEM/PGSIZE;i<PADDR(boot_alloc(0))/PGSIZE;i++)
f0100e21:	83 c3 01             	add    $0x1,%ebx
f0100e24:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e29:	e8 f2 fa ff ff       	call   f0100920 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e2e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e33:	77 20                	ja     f0100e55 <page_init+0xb5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e35:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e39:	c7 44 24 08 30 46 10 	movl   $0xf0104630,0x8(%esp)
f0100e40:	f0 
f0100e41:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
f0100e48:	00 
f0100e49:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100e50:	e8 3f f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e55:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e5a:	c1 e8 0c             	shr    $0xc,%eax
f0100e5d:	39 c3                	cmp    %eax,%ebx
f0100e5f:	72 b4                	jb     f0100e15 <page_init+0x75>
	{
		pages[i].pp_ref = 1;
	}
	for(i = PADDR(boot_alloc(0))/PGSIZE;i<npages;i++)
f0100e61:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e66:	e8 b5 fa ff ff       	call   f0100920 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e6b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e70:	77 20                	ja     f0100e92 <page_init+0xf2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e72:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e76:	c7 44 24 08 30 46 10 	movl   $0xf0104630,0x8(%esp)
f0100e7d:	f0 
f0100e7e:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
f0100e85:	00 
f0100e86:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0100e8d:	e8 02 f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e92:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100e98:	c1 ea 0c             	shr    $0xc,%edx
f0100e9b:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100ea1:	73 3d                	jae    f0100ee0 <page_init+0x140>
f0100ea3:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
f0100ea9:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
	{
		pages[i].pp_ref = 0;
f0100eb0:	89 c1                	mov    %eax,%ecx
f0100eb2:	03 0d 88 79 11 f0    	add    0xf0117988,%ecx
f0100eb8:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ebe:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100ec0:	89 c1                	mov    %eax,%ecx
f0100ec2:	03 0d 88 79 11 f0    	add    0xf0117988,%ecx
	}
	for (i = EXTPHYSMEM/PGSIZE;i<PADDR(boot_alloc(0))/PGSIZE;i++)
	{
		pages[i].pp_ref = 1;
	}
	for(i = PADDR(boot_alloc(0))/PGSIZE;i<npages;i++)
f0100ec8:	83 c2 01             	add    $0x1,%edx
f0100ecb:	83 c0 08             	add    $0x8,%eax
f0100ece:	39 15 80 79 11 f0    	cmp    %edx,0xf0117980
f0100ed4:	76 04                	jbe    f0100eda <page_init+0x13a>
	{
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100ed6:	89 cb                	mov    %ecx,%ebx
f0100ed8:	eb d6                	jmp    f0100eb0 <page_init+0x110>
f0100eda:	89 0d 5c 75 11 f0    	mov    %ecx,0xf011755c
	}
	cprintf("page_init returned\n");
f0100ee0:	c7 04 24 00 43 10 f0 	movl   $0xf0104300,(%esp)
f0100ee7:	e8 00 1e 00 00       	call   f0102cec <cprintf>
f0100eec:	eb 0f                	jmp    f0100efd <page_init+0x15d>
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	for (i = IOPHYSMEM/PGSIZE;i < EXTPHYSMEM/PGSIZE;i++)
	{
		pages[i].pp_ref=1;
f0100eee:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0100ef3:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0100ef8:	e9 04 ff ff ff       	jmp    f0100e01 <page_init+0x61>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	cprintf("page_init returned\n");
}
f0100efd:	83 c4 10             	add    $0x10,%esp
f0100f00:	5b                   	pop    %ebx
f0100f01:	5e                   	pop    %esi
f0100f02:	5d                   	pop    %ebp
f0100f03:	c3                   	ret    

f0100f04 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100f04:	55                   	push   %ebp
f0100f05:	89 e5                	mov    %esp,%ebp
f0100f07:	53                   	push   %ebx
f0100f08:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if (page_free_list) {
f0100f0b:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
f0100f11:	85 db                	test   %ebx,%ebx
f0100f13:	74 69                	je     f0100f7e <page_alloc+0x7a>
		struct Page *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100f15:	8b 03                	mov    (%ebx),%eax
f0100f17:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
		if (alloc_flags & ALLOC_ZERO)
			memset(page2kva(ret), 0, PGSIZE);
		return ret;	
f0100f1c:	89 d8                	mov    %ebx,%eax
{
	// Fill this function in
	if (page_free_list) {
		struct Page *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
		if (alloc_flags & ALLOC_ZERO)
f0100f1e:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f22:	74 5f                	je     f0100f83 <page_alloc+0x7f>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f24:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100f2a:	c1 f8 03             	sar    $0x3,%eax
f0100f2d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f30:	89 c2                	mov    %eax,%edx
f0100f32:	c1 ea 0c             	shr    $0xc,%edx
f0100f35:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100f3b:	72 20                	jb     f0100f5d <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f3d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f41:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0100f48:	f0 
f0100f49:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f50:	00 
f0100f51:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f0100f58:	e8 37 f1 ff ff       	call   f0100094 <_panic>
			memset(page2kva(ret), 0, PGSIZE);
f0100f5d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f64:	00 
f0100f65:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f6c:	00 
	return (void *)(pa + KERNBASE);
f0100f6d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f72:	89 04 24             	mov    %eax,(%esp)
f0100f75:	e8 15 29 00 00       	call   f010388f <memset>
		return ret;	
f0100f7a:	89 d8                	mov    %ebx,%eax
f0100f7c:	eb 05                	jmp    f0100f83 <page_alloc+0x7f>
	}
	return 0;
f0100f7e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f83:	83 c4 14             	add    $0x14,%esp
f0100f86:	5b                   	pop    %ebx
f0100f87:	5d                   	pop    %ebp
f0100f88:	c3                   	ret    

f0100f89 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f89:	55                   	push   %ebp
f0100f8a:	89 e5                	mov    %esp,%ebp
f0100f8c:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f0100f8f:	8b 15 5c 75 11 f0    	mov    0xf011755c,%edx
f0100f95:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f97:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
}
f0100f9c:	5d                   	pop    %ebp
f0100f9d:	c3                   	ret    

f0100f9e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f9e:	55                   	push   %ebp
f0100f9f:	89 e5                	mov    %esp,%ebp
f0100fa1:	83 ec 04             	sub    $0x4,%esp
f0100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100fa7:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100fab:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100fae:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100fb2:	66 85 d2             	test   %dx,%dx
f0100fb5:	75 08                	jne    f0100fbf <page_decref+0x21>
		page_free(pp);
f0100fb7:	89 04 24             	mov    %eax,(%esp)
f0100fba:	e8 ca ff ff ff       	call   f0100f89 <page_free>
}
f0100fbf:	c9                   	leave  
f0100fc0:	c3                   	ret    

f0100fc1 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100fc1:	55                   	push   %ebp
f0100fc2:	89 e5                	mov    %esp,%ebp
f0100fc4:	56                   	push   %esi
f0100fc5:	53                   	push   %ebx
f0100fc6:	83 ec 10             	sub    $0x10,%esp
f0100fc9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	int dindex = PDX(va), tindex = PTX(va);
f0100fcc:	89 de                	mov    %ebx,%esi
f0100fce:	c1 ee 0c             	shr    $0xc,%esi
f0100fd1:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100fd7:	c1 eb 16             	shr    $0x16,%ebx
	if (!(pgdir[dindex]&PTE_P))
f0100fda:	c1 e3 02             	shl    $0x2,%ebx
f0100fdd:	03 5d 08             	add    0x8(%ebp),%ebx
f0100fe0:	f6 03 01             	testb  $0x1,(%ebx)
f0100fe3:	75 2c                	jne    f0101011 <pgdir_walk+0x50>
	{
		if (create)
f0100fe5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fe9:	74 63                	je     f010104e <pgdir_walk+0x8d>
		{
			struct Page* pg = page_alloc(ALLOC_ZERO);
f0100feb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100ff2:	e8 0d ff ff ff       	call   f0100f04 <page_alloc>
			if (!pg)
f0100ff7:	85 c0                	test   %eax,%eax
f0100ff9:	74 5a                	je     f0101055 <pgdir_walk+0x94>
				return NULL;
			pg->pp_ref++;
f0100ffb:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101000:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0101006:	c1 f8 03             	sar    $0x3,%eax
f0101009:	c1 e0 0c             	shl    $0xc,%eax
			pgdir[dindex] = page2pa(pg)|PTE_P|PTE_U|PTE_W;
f010100c:	83 c8 07             	or     $0x7,%eax
f010100f:	89 03                	mov    %eax,(%ebx)
		else
		{
			return NULL;
		}
	}
	pte_t *p = KADDR(PTE_ADDR(pgdir[dindex]));
f0101011:	8b 03                	mov    (%ebx),%eax
f0101013:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101018:	89 c2                	mov    %eax,%edx
f010101a:	c1 ea 0c             	shr    $0xc,%edx
f010101d:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0101023:	72 20                	jb     f0101045 <pgdir_walk+0x84>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101025:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101029:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0101030:	f0 
f0101031:	c7 44 24 04 79 01 00 	movl   $0x179,0x4(%esp)
f0101038:	00 
f0101039:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101040:	e8 4f f0 ff ff       	call   f0100094 <_panic>
	return p+tindex;
f0101045:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f010104c:	eb 0c                	jmp    f010105a <pgdir_walk+0x99>
			pg->pp_ref++;
			pgdir[dindex] = page2pa(pg)|PTE_P|PTE_U|PTE_W;
		}
		else
		{
			return NULL;
f010104e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101053:	eb 05                	jmp    f010105a <pgdir_walk+0x99>
	{
		if (create)
		{
			struct Page* pg = page_alloc(ALLOC_ZERO);
			if (!pg)
				return NULL;
f0101055:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
		}
	}
	pte_t *p = KADDR(PTE_ADDR(pgdir[dindex]));
	return p+tindex;
}
f010105a:	83 c4 10             	add    $0x10,%esp
f010105d:	5b                   	pop    %ebx
f010105e:	5e                   	pop    %esi
f010105f:	5d                   	pop    %ebp
f0101060:	c3                   	ret    

f0101061 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101061:	55                   	push   %ebp
f0101062:	89 e5                	mov    %esp,%ebp
f0101064:	57                   	push   %edi
f0101065:	56                   	push   %esi
f0101066:	53                   	push   %ebx
f0101067:	83 ec 2c             	sub    $0x2c,%esp
f010106a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// Fill this function in
	int i;
	for (i=0; i<size/PGSIZE; ++i, va += PGSIZE, pa +=PGSIZE)
f010106d:	c1 e9 0c             	shr    $0xc,%ecx
f0101070:	85 c9                	test   %ecx,%ecx
f0101072:	74 6b                	je     f01010df <boot_map_region+0x7e>
f0101074:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101077:	89 d3                	mov    %edx,%ebx
f0101079:	be 00 00 00 00       	mov    $0x0,%esi
f010107e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101081:	29 d0                	sub    %edx,%eax
f0101083:	89 45 e0             	mov    %eax,-0x20(%ebp)
	{
		pte_t *pte = pgdir_walk(pgdir, (void*)va,1);
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
f0101086:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101089:	83 c8 01             	or     $0x1,%eax
f010108c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010108f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101092:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
{
	// Fill this function in
	int i;
	for (i=0; i<size/PGSIZE; ++i, va += PGSIZE, pa +=PGSIZE)
	{
		pte_t *pte = pgdir_walk(pgdir, (void*)va,1);
f0101095:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010109c:	00 
f010109d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010a1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010a4:	89 04 24             	mov    %eax,(%esp)
f01010a7:	e8 15 ff ff ff       	call   f0100fc1 <pgdir_walk>
		if (!pte) panic("boot_map_region panic, out of memory");
f01010ac:	85 c0                	test   %eax,%eax
f01010ae:	75 1c                	jne    f01010cc <boot_map_region+0x6b>
f01010b0:	c7 44 24 08 54 46 10 	movl   $0xf0104654,0x8(%esp)
f01010b7:	f0 
f01010b8:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
f01010bf:	00 
f01010c0:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01010c7:	e8 c8 ef ff ff       	call   f0100094 <_panic>
		*pte = pa | perm | PTE_P;
f01010cc:	0b 7d d8             	or     -0x28(%ebp),%edi
f01010cf:	89 38                	mov    %edi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int i;
	for (i=0; i<size/PGSIZE; ++i, va += PGSIZE, pa +=PGSIZE)
f01010d1:	83 c6 01             	add    $0x1,%esi
f01010d4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01010da:	3b 75 dc             	cmp    -0x24(%ebp),%esi
f01010dd:	75 b0                	jne    f010108f <boot_map_region+0x2e>
	{
		pte_t *pte = pgdir_walk(pgdir, (void*)va,1);
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
	}
}
f01010df:	83 c4 2c             	add    $0x2c,%esp
f01010e2:	5b                   	pop    %ebx
f01010e3:	5e                   	pop    %esi
f01010e4:	5f                   	pop    %edi
f01010e5:	5d                   	pop    %ebp
f01010e6:	c3                   	ret    

f01010e7 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010e7:	55                   	push   %ebp
f01010e8:	89 e5                	mov    %esp,%ebp
f01010ea:	53                   	push   %ebx
f01010eb:	83 ec 14             	sub    $0x14,%esp
f01010ee:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f01010f1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010f8:	00 
f01010f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101100:	8b 45 08             	mov    0x8(%ebp),%eax
f0101103:	89 04 24             	mov    %eax,(%esp)
f0101106:	e8 b6 fe ff ff       	call   f0100fc1 <pgdir_walk>
	if (!pte || !(*pte & PTE_P)) return NULL;
f010110b:	85 c0                	test   %eax,%eax
f010110d:	74 3f                	je     f010114e <page_lookup+0x67>
f010110f:	f6 00 01             	testb  $0x1,(%eax)
f0101112:	74 41                	je     f0101155 <page_lookup+0x6e>
	if (pte_store)
f0101114:	85 db                	test   %ebx,%ebx
f0101116:	74 02                	je     f010111a <page_lookup+0x33>
		*pte_store = pte;
f0101118:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f010111a:	8b 00                	mov    (%eax),%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010111c:	c1 e8 0c             	shr    $0xc,%eax
f010111f:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0101125:	72 1c                	jb     f0101143 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f0101127:	c7 44 24 08 7c 46 10 	movl   $0xf010467c,0x8(%esp)
f010112e:	f0 
f010112f:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101136:	00 
f0101137:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f010113e:	e8 51 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101143:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
f0101149:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010114c:	eb 0c                	jmp    f010115a <page_lookup+0x73>
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if (!pte || !(*pte & PTE_P)) return NULL;
f010114e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101153:	eb 05                	jmp    f010115a <page_lookup+0x73>
f0101155:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f010115a:	83 c4 14             	add    $0x14,%esp
f010115d:	5b                   	pop    %ebx
f010115e:	5d                   	pop    %ebp
f010115f:	c3                   	ret    

f0101160 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101160:	55                   	push   %ebp
f0101161:	89 e5                	mov    %esp,%ebp
f0101163:	53                   	push   %ebx
f0101164:	83 ec 24             	sub    $0x24,%esp
f0101167:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct Page *pg = page_lookup(pgdir, va, &pte);
f010116a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010116d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101171:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101175:	8b 45 08             	mov    0x8(%ebp),%eax
f0101178:	89 04 24             	mov    %eax,(%esp)
f010117b:	e8 67 ff ff ff       	call   f01010e7 <page_lookup>
	if (!pg || !(*pte & PTE_P)) return;
f0101180:	85 c0                	test   %eax,%eax
f0101182:	74 1c                	je     f01011a0 <page_remove+0x40>
f0101184:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101187:	f6 02 01             	testb  $0x1,(%edx)
f010118a:	74 14                	je     f01011a0 <page_remove+0x40>
	page_decref(pg);
f010118c:	89 04 24             	mov    %eax,(%esp)
f010118f:	e8 0a fe ff ff       	call   f0100f9e <page_decref>
	*pte = 0;
f0101194:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101197:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010119d:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f01011a0:	83 c4 24             	add    $0x24,%esp
f01011a3:	5b                   	pop    %ebx
f01011a4:	5d                   	pop    %ebp
f01011a5:	c3                   	ret    

f01011a6 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01011a6:	55                   	push   %ebp
f01011a7:	89 e5                	mov    %esp,%ebp
f01011a9:	57                   	push   %edi
f01011aa:	56                   	push   %esi
f01011ab:	53                   	push   %ebx
f01011ac:	83 ec 1c             	sub    $0x1c,%esp
f01011af:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011b2:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t * pte = pgdir_walk(pgdir, va, 1);
f01011b5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01011bc:	00 
f01011bd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01011c4:	89 04 24             	mov    %eax,(%esp)
f01011c7:	e8 f5 fd ff ff       	call   f0100fc1 <pgdir_walk>
f01011cc:	89 c3                	mov    %eax,%ebx
	if (!pte)
f01011ce:	85 c0                	test   %eax,%eax
f01011d0:	74 36                	je     f0101208 <page_insert+0x62>
		return -E_NO_MEM;
	pp->pp_ref++;
f01011d2:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*pte & PTE_P)
f01011d7:	f6 00 01             	testb  $0x1,(%eax)
f01011da:	74 0f                	je     f01011eb <page_insert+0x45>
		page_remove(pgdir, va);
f01011dc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e3:	89 04 24             	mov    %eax,(%esp)
f01011e6:	e8 75 ff ff ff       	call   f0101160 <page_remove>
	*pte = page2pa(pp) | perm | PTE_P;
f01011eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ee:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01011f1:	2b 35 88 79 11 f0    	sub    0xf0117988,%esi
f01011f7:	c1 fe 03             	sar    $0x3,%esi
f01011fa:	c1 e6 0c             	shl    $0xc,%esi
f01011fd:	09 c6                	or     %eax,%esi
f01011ff:	89 33                	mov    %esi,(%ebx)
	return 0;
f0101201:	b8 00 00 00 00       	mov    $0x0,%eax
f0101206:	eb 05                	jmp    f010120d <page_insert+0x67>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
	// Fill this function in
	pte_t * pte = pgdir_walk(pgdir, va, 1);
	if (!pte)
		return -E_NO_MEM;
f0101208:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;
	if (*pte & PTE_P)
		page_remove(pgdir, va);
	*pte = page2pa(pp) | perm | PTE_P;
	return 0;
}
f010120d:	83 c4 1c             	add    $0x1c,%esp
f0101210:	5b                   	pop    %ebx
f0101211:	5e                   	pop    %esi
f0101212:	5f                   	pop    %edi
f0101213:	5d                   	pop    %ebp
f0101214:	c3                   	ret    

f0101215 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101215:	55                   	push   %ebp
f0101216:	89 e5                	mov    %esp,%ebp
f0101218:	57                   	push   %edi
f0101219:	56                   	push   %esi
f010121a:	53                   	push   %ebx
f010121b:	83 ec 3c             	sub    $0x3c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010121e:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101225:	e8 52 1a 00 00       	call   f0102c7c <mc146818_read>
f010122a:	89 c3                	mov    %eax,%ebx
f010122c:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101233:	e8 44 1a 00 00       	call   f0102c7c <mc146818_read>
f0101238:	c1 e0 08             	shl    $0x8,%eax
f010123b:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010123d:	89 d8                	mov    %ebx,%eax
f010123f:	c1 e0 0a             	shl    $0xa,%eax
f0101242:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101248:	85 c0                	test   %eax,%eax
f010124a:	0f 48 c2             	cmovs  %edx,%eax
f010124d:	c1 f8 0c             	sar    $0xc,%eax
f0101250:	a3 60 75 11 f0       	mov    %eax,0xf0117560
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101255:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010125c:	e8 1b 1a 00 00       	call   f0102c7c <mc146818_read>
f0101261:	89 c3                	mov    %eax,%ebx
f0101263:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010126a:	e8 0d 1a 00 00       	call   f0102c7c <mc146818_read>
f010126f:	c1 e0 08             	shl    $0x8,%eax
f0101272:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101274:	89 d8                	mov    %ebx,%eax
f0101276:	c1 e0 0a             	shl    $0xa,%eax
f0101279:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010127f:	85 c0                	test   %eax,%eax
f0101281:	0f 48 c2             	cmovs  %edx,%eax
f0101284:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101287:	85 c0                	test   %eax,%eax
f0101289:	74 0e                	je     f0101299 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010128b:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101291:	89 15 80 79 11 f0    	mov    %edx,0xf0117980
f0101297:	eb 0c                	jmp    f01012a5 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101299:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f010129f:	89 15 80 79 11 f0    	mov    %edx,0xf0117980

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01012a5:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012a8:	c1 e8 0a             	shr    $0xa,%eax
f01012ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012af:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f01012b4:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012b7:	c1 e8 0a             	shr    $0xa,%eax
f01012ba:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012be:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f01012c3:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012c6:	c1 e8 0a             	shr    $0xa,%eax
f01012c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012cd:	c7 04 24 9c 46 10 f0 	movl   $0xf010469c,(%esp)
f01012d4:	e8 13 1a 00 00       	call   f0102cec <cprintf>
	// Remove this line when you're ready to test this function.
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012d9:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012de:	e8 3d f6 ff ff       	call   f0100920 <boot_alloc>
f01012e3:	a3 84 79 11 f0       	mov    %eax,0xf0117984
	cprintf("kern_pgdir: %x\n");
f01012e8:	c7 04 24 14 43 10 f0 	movl   $0xf0104314,(%esp)
f01012ef:	e8 f8 19 00 00       	call   f0102cec <cprintf>
	memset(kern_pgdir, 0, PGSIZE);
f01012f4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012fb:	00 
f01012fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101303:	00 
f0101304:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101309:	89 04 24             	mov    %eax,(%esp)
f010130c:	e8 7e 25 00 00       	call   f010388f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101311:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101316:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010131b:	77 20                	ja     f010133d <mem_init+0x128>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010131d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101321:	c7 44 24 08 30 46 10 	movl   $0xf0104630,0x8(%esp)
f0101328:	f0 
f0101329:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0101330:	00 
f0101331:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101338:	e8 57 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010133d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101343:	83 ca 05             	or     $0x5,%edx
f0101346:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page*) boot_alloc(sizeof(struct Page) * npages);
f010134c:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0101351:	c1 e0 03             	shl    $0x3,%eax
f0101354:	e8 c7 f5 ff ff       	call   f0100920 <boot_alloc>
f0101359:	a3 88 79 11 f0       	mov    %eax,0xf0117988
	cprintf("npages: %d\n", npages);
f010135e:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0101363:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101367:	c7 04 24 24 43 10 f0 	movl   $0xf0104324,(%esp)
f010136e:	e8 79 19 00 00       	call   f0102cec <cprintf>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101373:	e8 28 fa ff ff       	call   f0100da0 <page_init>

	check_page_free_list(1);
f0101378:	b8 01 00 00 00       	mov    $0x1,%eax
f010137d:	e8 a1 f6 ff ff       	call   f0100a23 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101382:	83 3d 88 79 11 f0 00 	cmpl   $0x0,0xf0117988
f0101389:	75 1c                	jne    f01013a7 <mem_init+0x192>
		panic("'pages' is a null pointer!");
f010138b:	c7 44 24 08 30 43 10 	movl   $0xf0104330,0x8(%esp)
f0101392:	f0 
f0101393:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
f010139a:	00 
f010139b:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01013a2:	e8 ed ec ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013a7:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f01013ac:	85 c0                	test   %eax,%eax
f01013ae:	74 10                	je     f01013c0 <mem_init+0x1ab>
f01013b0:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f01013b5:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013b8:	8b 00                	mov    (%eax),%eax
f01013ba:	85 c0                	test   %eax,%eax
f01013bc:	75 f7                	jne    f01013b5 <mem_init+0x1a0>
f01013be:	eb 05                	jmp    f01013c5 <mem_init+0x1b0>
f01013c0:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013cc:	e8 33 fb ff ff       	call   f0100f04 <page_alloc>
f01013d1:	89 c7                	mov    %eax,%edi
f01013d3:	85 c0                	test   %eax,%eax
f01013d5:	75 24                	jne    f01013fb <mem_init+0x1e6>
f01013d7:	c7 44 24 0c 4b 43 10 	movl   $0xf010434b,0xc(%esp)
f01013de:	f0 
f01013df:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01013e6:	f0 
f01013e7:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f01013ee:	00 
f01013ef:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01013f6:	e8 99 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013fb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101402:	e8 fd fa ff ff       	call   f0100f04 <page_alloc>
f0101407:	89 c6                	mov    %eax,%esi
f0101409:	85 c0                	test   %eax,%eax
f010140b:	75 24                	jne    f0101431 <mem_init+0x21c>
f010140d:	c7 44 24 0c 61 43 10 	movl   $0xf0104361,0xc(%esp)
f0101414:	f0 
f0101415:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010141c:	f0 
f010141d:	c7 44 24 04 4e 02 00 	movl   $0x24e,0x4(%esp)
f0101424:	00 
f0101425:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010142c:	e8 63 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101431:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101438:	e8 c7 fa ff ff       	call   f0100f04 <page_alloc>
f010143d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101440:	85 c0                	test   %eax,%eax
f0101442:	75 24                	jne    f0101468 <mem_init+0x253>
f0101444:	c7 44 24 0c 77 43 10 	movl   $0xf0104377,0xc(%esp)
f010144b:	f0 
f010144c:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101453:	f0 
f0101454:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
f010145b:	00 
f010145c:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101463:	e8 2c ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101468:	39 f7                	cmp    %esi,%edi
f010146a:	75 24                	jne    f0101490 <mem_init+0x27b>
f010146c:	c7 44 24 0c 8d 43 10 	movl   $0xf010438d,0xc(%esp)
f0101473:	f0 
f0101474:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010147b:	f0 
f010147c:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0101483:	00 
f0101484:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010148b:	e8 04 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101490:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101493:	39 c6                	cmp    %eax,%esi
f0101495:	74 04                	je     f010149b <mem_init+0x286>
f0101497:	39 c7                	cmp    %eax,%edi
f0101499:	75 24                	jne    f01014bf <mem_init+0x2aa>
f010149b:	c7 44 24 0c d8 46 10 	movl   $0xf01046d8,0xc(%esp)
f01014a2:	f0 
f01014a3:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01014aa:	f0 
f01014ab:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f01014b2:	00 
f01014b3:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01014ba:	e8 d5 eb ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01014bf:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014c5:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f01014ca:	c1 e0 0c             	shl    $0xc,%eax
f01014cd:	89 f9                	mov    %edi,%ecx
f01014cf:	29 d1                	sub    %edx,%ecx
f01014d1:	c1 f9 03             	sar    $0x3,%ecx
f01014d4:	c1 e1 0c             	shl    $0xc,%ecx
f01014d7:	39 c1                	cmp    %eax,%ecx
f01014d9:	72 24                	jb     f01014ff <mem_init+0x2ea>
f01014db:	c7 44 24 0c 9f 43 10 	movl   $0xf010439f,0xc(%esp)
f01014e2:	f0 
f01014e3:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01014ea:	f0 
f01014eb:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f01014f2:	00 
f01014f3:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01014fa:	e8 95 eb ff ff       	call   f0100094 <_panic>
f01014ff:	89 f1                	mov    %esi,%ecx
f0101501:	29 d1                	sub    %edx,%ecx
f0101503:	c1 f9 03             	sar    $0x3,%ecx
f0101506:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101509:	39 c8                	cmp    %ecx,%eax
f010150b:	77 24                	ja     f0101531 <mem_init+0x31c>
f010150d:	c7 44 24 0c bc 43 10 	movl   $0xf01043bc,0xc(%esp)
f0101514:	f0 
f0101515:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010151c:	f0 
f010151d:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f0101524:	00 
f0101525:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010152c:	e8 63 eb ff ff       	call   f0100094 <_panic>
f0101531:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101534:	29 d1                	sub    %edx,%ecx
f0101536:	89 ca                	mov    %ecx,%edx
f0101538:	c1 fa 03             	sar    $0x3,%edx
f010153b:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010153e:	39 d0                	cmp    %edx,%eax
f0101540:	77 24                	ja     f0101566 <mem_init+0x351>
f0101542:	c7 44 24 0c d9 43 10 	movl   $0xf01043d9,0xc(%esp)
f0101549:	f0 
f010154a:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101551:	f0 
f0101552:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0101559:	00 
f010155a:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101561:	e8 2e eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101566:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f010156b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010156e:	c7 05 5c 75 11 f0 00 	movl   $0x0,0xf011755c
f0101575:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101578:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010157f:	e8 80 f9 ff ff       	call   f0100f04 <page_alloc>
f0101584:	85 c0                	test   %eax,%eax
f0101586:	74 24                	je     f01015ac <mem_init+0x397>
f0101588:	c7 44 24 0c f6 43 10 	movl   $0xf01043f6,0xc(%esp)
f010158f:	f0 
f0101590:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101597:	f0 
f0101598:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f010159f:	00 
f01015a0:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01015a7:	e8 e8 ea ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015ac:	89 3c 24             	mov    %edi,(%esp)
f01015af:	e8 d5 f9 ff ff       	call   f0100f89 <page_free>
	page_free(pp1);
f01015b4:	89 34 24             	mov    %esi,(%esp)
f01015b7:	e8 cd f9 ff ff       	call   f0100f89 <page_free>
	page_free(pp2);
f01015bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015bf:	89 04 24             	mov    %eax,(%esp)
f01015c2:	e8 c2 f9 ff ff       	call   f0100f89 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ce:	e8 31 f9 ff ff       	call   f0100f04 <page_alloc>
f01015d3:	89 c6                	mov    %eax,%esi
f01015d5:	85 c0                	test   %eax,%eax
f01015d7:	75 24                	jne    f01015fd <mem_init+0x3e8>
f01015d9:	c7 44 24 0c 4b 43 10 	movl   $0xf010434b,0xc(%esp)
f01015e0:	f0 
f01015e1:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01015e8:	f0 
f01015e9:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f01015f0:	00 
f01015f1:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01015f8:	e8 97 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101604:	e8 fb f8 ff ff       	call   f0100f04 <page_alloc>
f0101609:	89 c7                	mov    %eax,%edi
f010160b:	85 c0                	test   %eax,%eax
f010160d:	75 24                	jne    f0101633 <mem_init+0x41e>
f010160f:	c7 44 24 0c 61 43 10 	movl   $0xf0104361,0xc(%esp)
f0101616:	f0 
f0101617:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010161e:	f0 
f010161f:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f0101626:	00 
f0101627:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010162e:	e8 61 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101633:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010163a:	e8 c5 f8 ff ff       	call   f0100f04 <page_alloc>
f010163f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101642:	85 c0                	test   %eax,%eax
f0101644:	75 24                	jne    f010166a <mem_init+0x455>
f0101646:	c7 44 24 0c 77 43 10 	movl   $0xf0104377,0xc(%esp)
f010164d:	f0 
f010164e:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101655:	f0 
f0101656:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f010165d:	00 
f010165e:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101665:	e8 2a ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010166a:	39 fe                	cmp    %edi,%esi
f010166c:	75 24                	jne    f0101692 <mem_init+0x47d>
f010166e:	c7 44 24 0c 8d 43 10 	movl   $0xf010438d,0xc(%esp)
f0101675:	f0 
f0101676:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010167d:	f0 
f010167e:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f0101685:	00 
f0101686:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010168d:	e8 02 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101692:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101695:	39 c7                	cmp    %eax,%edi
f0101697:	74 04                	je     f010169d <mem_init+0x488>
f0101699:	39 c6                	cmp    %eax,%esi
f010169b:	75 24                	jne    f01016c1 <mem_init+0x4ac>
f010169d:	c7 44 24 0c d8 46 10 	movl   $0xf01046d8,0xc(%esp)
f01016a4:	f0 
f01016a5:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01016ac:	f0 
f01016ad:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f01016b4:	00 
f01016b5:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01016bc:	e8 d3 e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01016c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016c8:	e8 37 f8 ff ff       	call   f0100f04 <page_alloc>
f01016cd:	85 c0                	test   %eax,%eax
f01016cf:	74 24                	je     f01016f5 <mem_init+0x4e0>
f01016d1:	c7 44 24 0c f6 43 10 	movl   $0xf01043f6,0xc(%esp)
f01016d8:	f0 
f01016d9:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01016e0:	f0 
f01016e1:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f01016e8:	00 
f01016e9:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01016f0:	e8 9f e9 ff ff       	call   f0100094 <_panic>
f01016f5:	89 f0                	mov    %esi,%eax
f01016f7:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f01016fd:	c1 f8 03             	sar    $0x3,%eax
f0101700:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101703:	89 c2                	mov    %eax,%edx
f0101705:	c1 ea 0c             	shr    $0xc,%edx
f0101708:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f010170e:	72 20                	jb     f0101730 <mem_init+0x51b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101710:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101714:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f010171b:	f0 
f010171c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101723:	00 
f0101724:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f010172b:	e8 64 e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101730:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101737:	00 
f0101738:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010173f:	00 
	return (void *)(pa + KERNBASE);
f0101740:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101745:	89 04 24             	mov    %eax,(%esp)
f0101748:	e8 42 21 00 00       	call   f010388f <memset>
	page_free(pp0);
f010174d:	89 34 24             	mov    %esi,(%esp)
f0101750:	e8 34 f8 ff ff       	call   f0100f89 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101755:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010175c:	e8 a3 f7 ff ff       	call   f0100f04 <page_alloc>
f0101761:	85 c0                	test   %eax,%eax
f0101763:	75 24                	jne    f0101789 <mem_init+0x574>
f0101765:	c7 44 24 0c 05 44 10 	movl   $0xf0104405,0xc(%esp)
f010176c:	f0 
f010176d:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101774:	f0 
f0101775:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f010177c:	00 
f010177d:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101784:	e8 0b e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101789:	39 c6                	cmp    %eax,%esi
f010178b:	74 24                	je     f01017b1 <mem_init+0x59c>
f010178d:	c7 44 24 0c 23 44 10 	movl   $0xf0104423,0xc(%esp)
f0101794:	f0 
f0101795:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010179c:	f0 
f010179d:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f01017a4:	00 
f01017a5:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01017ac:	e8 e3 e8 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01017b1:	89 f2                	mov    %esi,%edx
f01017b3:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01017b9:	c1 fa 03             	sar    $0x3,%edx
f01017bc:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017bf:	89 d0                	mov    %edx,%eax
f01017c1:	c1 e8 0c             	shr    $0xc,%eax
f01017c4:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f01017ca:	72 20                	jb     f01017ec <mem_init+0x5d7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017cc:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017d0:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f01017d7:	f0 
f01017d8:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017df:	00 
f01017e0:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f01017e7:	e8 a8 e8 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017ec:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01017f3:	75 11                	jne    f0101806 <mem_init+0x5f1>
f01017f5:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
f01017fb:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f0101801:	80 38 00             	cmpb   $0x0,(%eax)
f0101804:	74 24                	je     f010182a <mem_init+0x615>
f0101806:	c7 44 24 0c 33 44 10 	movl   $0xf0104433,0xc(%esp)
f010180d:	f0 
f010180e:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101815:	f0 
f0101816:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f010181d:	00 
f010181e:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101825:	e8 6a e8 ff ff       	call   f0100094 <_panic>
f010182a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010182d:	39 d0                	cmp    %edx,%eax
f010182f:	75 d0                	jne    f0101801 <mem_init+0x5ec>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101831:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101834:	a3 5c 75 11 f0       	mov    %eax,0xf011755c

	// free the pages we took
	page_free(pp0);
f0101839:	89 34 24             	mov    %esi,(%esp)
f010183c:	e8 48 f7 ff ff       	call   f0100f89 <page_free>
	page_free(pp1);
f0101841:	89 3c 24             	mov    %edi,(%esp)
f0101844:	e8 40 f7 ff ff       	call   f0100f89 <page_free>
	page_free(pp2);
f0101849:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010184c:	89 04 24             	mov    %eax,(%esp)
f010184f:	e8 35 f7 ff ff       	call   f0100f89 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101854:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f0101859:	85 c0                	test   %eax,%eax
f010185b:	74 09                	je     f0101866 <mem_init+0x651>
		--nfree;
f010185d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101860:	8b 00                	mov    (%eax),%eax
f0101862:	85 c0                	test   %eax,%eax
f0101864:	75 f7                	jne    f010185d <mem_init+0x648>
		--nfree;
	assert(nfree == 0);
f0101866:	85 db                	test   %ebx,%ebx
f0101868:	74 24                	je     f010188e <mem_init+0x679>
f010186a:	c7 44 24 0c 3d 44 10 	movl   $0xf010443d,0xc(%esp)
f0101871:	f0 
f0101872:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101879:	f0 
f010187a:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101881:	00 
f0101882:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101889:	e8 06 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010188e:	c7 04 24 f8 46 10 f0 	movl   $0xf01046f8,(%esp)
f0101895:	e8 52 14 00 00       	call   f0102cec <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010189a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018a1:	e8 5e f6 ff ff       	call   f0100f04 <page_alloc>
f01018a6:	89 c3                	mov    %eax,%ebx
f01018a8:	85 c0                	test   %eax,%eax
f01018aa:	75 24                	jne    f01018d0 <mem_init+0x6bb>
f01018ac:	c7 44 24 0c 4b 43 10 	movl   $0xf010434b,0xc(%esp)
f01018b3:	f0 
f01018b4:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01018bb:	f0 
f01018bc:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f01018c3:	00 
f01018c4:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01018cb:	e8 c4 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018d7:	e8 28 f6 ff ff       	call   f0100f04 <page_alloc>
f01018dc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018df:	85 c0                	test   %eax,%eax
f01018e1:	75 24                	jne    f0101907 <mem_init+0x6f2>
f01018e3:	c7 44 24 0c 61 43 10 	movl   $0xf0104361,0xc(%esp)
f01018ea:	f0 
f01018eb:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01018f2:	f0 
f01018f3:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f01018fa:	00 
f01018fb:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101902:	e8 8d e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101907:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010190e:	e8 f1 f5 ff ff       	call   f0100f04 <page_alloc>
f0101913:	89 c6                	mov    %eax,%esi
f0101915:	85 c0                	test   %eax,%eax
f0101917:	75 24                	jne    f010193d <mem_init+0x728>
f0101919:	c7 44 24 0c 77 43 10 	movl   $0xf0104377,0xc(%esp)
f0101920:	f0 
f0101921:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101928:	f0 
f0101929:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f0101930:	00 
f0101931:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101938:	e8 57 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010193d:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101940:	75 24                	jne    f0101966 <mem_init+0x751>
f0101942:	c7 44 24 0c 8d 43 10 	movl   $0xf010438d,0xc(%esp)
f0101949:	f0 
f010194a:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101951:	f0 
f0101952:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f0101959:	00 
f010195a:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101961:	e8 2e e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101966:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101969:	74 04                	je     f010196f <mem_init+0x75a>
f010196b:	39 c3                	cmp    %eax,%ebx
f010196d:	75 24                	jne    f0101993 <mem_init+0x77e>
f010196f:	c7 44 24 0c d8 46 10 	movl   $0xf01046d8,0xc(%esp)
f0101976:	f0 
f0101977:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010197e:	f0 
f010197f:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f0101986:	00 
f0101987:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010198e:	e8 01 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101993:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f0101998:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010199b:	c7 05 5c 75 11 f0 00 	movl   $0x0,0xf011755c
f01019a2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019a5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019ac:	e8 53 f5 ff ff       	call   f0100f04 <page_alloc>
f01019b1:	85 c0                	test   %eax,%eax
f01019b3:	74 24                	je     f01019d9 <mem_init+0x7c4>
f01019b5:	c7 44 24 0c f6 43 10 	movl   $0xf01043f6,0xc(%esp)
f01019bc:	f0 
f01019bd:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01019c4:	f0 
f01019c5:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f01019cc:	00 
f01019cd:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01019d4:	e8 bb e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019d9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019dc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019e0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019e7:	00 
f01019e8:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01019ed:	89 04 24             	mov    %eax,(%esp)
f01019f0:	e8 f2 f6 ff ff       	call   f01010e7 <page_lookup>
f01019f5:	85 c0                	test   %eax,%eax
f01019f7:	74 24                	je     f0101a1d <mem_init+0x808>
f01019f9:	c7 44 24 0c 18 47 10 	movl   $0xf0104718,0xc(%esp)
f0101a00:	f0 
f0101a01:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101a08:	f0 
f0101a09:	c7 44 24 04 e9 02 00 	movl   $0x2e9,0x4(%esp)
f0101a10:	00 
f0101a11:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101a18:	e8 77 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a1d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a24:	00 
f0101a25:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a2c:	00 
f0101a2d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a30:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a34:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101a39:	89 04 24             	mov    %eax,(%esp)
f0101a3c:	e8 65 f7 ff ff       	call   f01011a6 <page_insert>
f0101a41:	85 c0                	test   %eax,%eax
f0101a43:	78 24                	js     f0101a69 <mem_init+0x854>
f0101a45:	c7 44 24 0c 50 47 10 	movl   $0xf0104750,0xc(%esp)
f0101a4c:	f0 
f0101a4d:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101a54:	f0 
f0101a55:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f0101a5c:	00 
f0101a5d:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101a64:	e8 2b e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a69:	89 1c 24             	mov    %ebx,(%esp)
f0101a6c:	e8 18 f5 ff ff       	call   f0100f89 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a71:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a78:	00 
f0101a79:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a80:	00 
f0101a81:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a84:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a88:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101a8d:	89 04 24             	mov    %eax,(%esp)
f0101a90:	e8 11 f7 ff ff       	call   f01011a6 <page_insert>
f0101a95:	85 c0                	test   %eax,%eax
f0101a97:	74 24                	je     f0101abd <mem_init+0x8a8>
f0101a99:	c7 44 24 0c 80 47 10 	movl   $0xf0104780,0xc(%esp)
f0101aa0:	f0 
f0101aa1:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101aa8:	f0 
f0101aa9:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101ab0:	00 
f0101ab1:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101ab8:	e8 d7 e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101abd:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ac3:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0101ac8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101acb:	8b 17                	mov    (%edi),%edx
f0101acd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ad3:	89 d9                	mov    %ebx,%ecx
f0101ad5:	29 c1                	sub    %eax,%ecx
f0101ad7:	89 c8                	mov    %ecx,%eax
f0101ad9:	c1 f8 03             	sar    $0x3,%eax
f0101adc:	c1 e0 0c             	shl    $0xc,%eax
f0101adf:	39 c2                	cmp    %eax,%edx
f0101ae1:	74 24                	je     f0101b07 <mem_init+0x8f2>
f0101ae3:	c7 44 24 0c b0 47 10 	movl   $0xf01047b0,0xc(%esp)
f0101aea:	f0 
f0101aeb:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101af2:	f0 
f0101af3:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0101afa:	00 
f0101afb:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101b02:	e8 8d e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b07:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b0c:	89 f8                	mov    %edi,%eax
f0101b0e:	e8 a1 ee ff ff       	call   f01009b4 <check_va2pa>
f0101b13:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b16:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b19:	c1 fa 03             	sar    $0x3,%edx
f0101b1c:	c1 e2 0c             	shl    $0xc,%edx
f0101b1f:	39 d0                	cmp    %edx,%eax
f0101b21:	74 24                	je     f0101b47 <mem_init+0x932>
f0101b23:	c7 44 24 0c d8 47 10 	movl   $0xf01047d8,0xc(%esp)
f0101b2a:	f0 
f0101b2b:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101b32:	f0 
f0101b33:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f0101b3a:	00 
f0101b3b:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101b42:	e8 4d e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b47:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b4a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b4f:	74 24                	je     f0101b75 <mem_init+0x960>
f0101b51:	c7 44 24 0c 48 44 10 	movl   $0xf0104448,0xc(%esp)
f0101b58:	f0 
f0101b59:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101b60:	f0 
f0101b61:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f0101b68:	00 
f0101b69:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101b70:	e8 1f e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b75:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b7a:	74 24                	je     f0101ba0 <mem_init+0x98b>
f0101b7c:	c7 44 24 0c 59 44 10 	movl   $0xf0104459,0xc(%esp)
f0101b83:	f0 
f0101b84:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101b8b:	f0 
f0101b8c:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0101b93:	00 
f0101b94:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101b9b:	e8 f4 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ba0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ba7:	00 
f0101ba8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101baf:	00 
f0101bb0:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101bb4:	89 3c 24             	mov    %edi,(%esp)
f0101bb7:	e8 ea f5 ff ff       	call   f01011a6 <page_insert>
f0101bbc:	85 c0                	test   %eax,%eax
f0101bbe:	74 24                	je     f0101be4 <mem_init+0x9cf>
f0101bc0:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f0101bc7:	f0 
f0101bc8:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101bcf:	f0 
f0101bd0:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0101bd7:	00 
f0101bd8:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101bdf:	e8 b0 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101be4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101be9:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101bee:	e8 c1 ed ff ff       	call   f01009b4 <check_va2pa>
f0101bf3:	89 f2                	mov    %esi,%edx
f0101bf5:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101bfb:	c1 fa 03             	sar    $0x3,%edx
f0101bfe:	c1 e2 0c             	shl    $0xc,%edx
f0101c01:	39 d0                	cmp    %edx,%eax
f0101c03:	74 24                	je     f0101c29 <mem_init+0xa14>
f0101c05:	c7 44 24 0c 44 48 10 	movl   $0xf0104844,0xc(%esp)
f0101c0c:	f0 
f0101c0d:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101c14:	f0 
f0101c15:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0101c1c:	00 
f0101c1d:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101c24:	e8 6b e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c29:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c2e:	74 24                	je     f0101c54 <mem_init+0xa3f>
f0101c30:	c7 44 24 0c 6a 44 10 	movl   $0xf010446a,0xc(%esp)
f0101c37:	f0 
f0101c38:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101c3f:	f0 
f0101c40:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0101c47:	00 
f0101c48:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101c4f:	e8 40 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c54:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c5b:	e8 a4 f2 ff ff       	call   f0100f04 <page_alloc>
f0101c60:	85 c0                	test   %eax,%eax
f0101c62:	74 24                	je     f0101c88 <mem_init+0xa73>
f0101c64:	c7 44 24 0c f6 43 10 	movl   $0xf01043f6,0xc(%esp)
f0101c6b:	f0 
f0101c6c:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101c73:	f0 
f0101c74:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f0101c7b:	00 
f0101c7c:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101c83:	e8 0c e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c88:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c8f:	00 
f0101c90:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c97:	00 
f0101c98:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c9c:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101ca1:	89 04 24             	mov    %eax,(%esp)
f0101ca4:	e8 fd f4 ff ff       	call   f01011a6 <page_insert>
f0101ca9:	85 c0                	test   %eax,%eax
f0101cab:	74 24                	je     f0101cd1 <mem_init+0xabc>
f0101cad:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f0101cb4:	f0 
f0101cb5:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101cbc:	f0 
f0101cbd:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0101cc4:	00 
f0101cc5:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101ccc:	e8 c3 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cd1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cd6:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101cdb:	e8 d4 ec ff ff       	call   f01009b4 <check_va2pa>
f0101ce0:	89 f2                	mov    %esi,%edx
f0101ce2:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101ce8:	c1 fa 03             	sar    $0x3,%edx
f0101ceb:	c1 e2 0c             	shl    $0xc,%edx
f0101cee:	39 d0                	cmp    %edx,%eax
f0101cf0:	74 24                	je     f0101d16 <mem_init+0xb01>
f0101cf2:	c7 44 24 0c 44 48 10 	movl   $0xf0104844,0xc(%esp)
f0101cf9:	f0 
f0101cfa:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101d01:	f0 
f0101d02:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f0101d09:	00 
f0101d0a:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101d11:	e8 7e e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101d16:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d1b:	74 24                	je     f0101d41 <mem_init+0xb2c>
f0101d1d:	c7 44 24 0c 6a 44 10 	movl   $0xf010446a,0xc(%esp)
f0101d24:	f0 
f0101d25:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101d2c:	f0 
f0101d2d:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f0101d34:	00 
f0101d35:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101d3c:	e8 53 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d41:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d48:	e8 b7 f1 ff ff       	call   f0100f04 <page_alloc>
f0101d4d:	85 c0                	test   %eax,%eax
f0101d4f:	74 24                	je     f0101d75 <mem_init+0xb60>
f0101d51:	c7 44 24 0c f6 43 10 	movl   $0xf01043f6,0xc(%esp)
f0101d58:	f0 
f0101d59:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101d60:	f0 
f0101d61:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101d68:	00 
f0101d69:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101d70:	e8 1f e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d75:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f0101d7b:	8b 02                	mov    (%edx),%eax
f0101d7d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d82:	89 c1                	mov    %eax,%ecx
f0101d84:	c1 e9 0c             	shr    $0xc,%ecx
f0101d87:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f0101d8d:	72 20                	jb     f0101daf <mem_init+0xb9a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d8f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d93:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0101d9a:	f0 
f0101d9b:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101da2:	00 
f0101da3:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101daa:	e8 e5 e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101daf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101db4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101db7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dbe:	00 
f0101dbf:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101dc6:	00 
f0101dc7:	89 14 24             	mov    %edx,(%esp)
f0101dca:	e8 f2 f1 ff ff       	call   f0100fc1 <pgdir_walk>
f0101dcf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101dd2:	8d 51 04             	lea    0x4(%ecx),%edx
f0101dd5:	39 d0                	cmp    %edx,%eax
f0101dd7:	74 24                	je     f0101dfd <mem_init+0xbe8>
f0101dd9:	c7 44 24 0c 74 48 10 	movl   $0xf0104874,0xc(%esp)
f0101de0:	f0 
f0101de1:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101de8:	f0 
f0101de9:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101df0:	00 
f0101df1:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101df8:	e8 97 e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101dfd:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e04:	00 
f0101e05:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e0c:	00 
f0101e0d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e11:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101e16:	89 04 24             	mov    %eax,(%esp)
f0101e19:	e8 88 f3 ff ff       	call   f01011a6 <page_insert>
f0101e1e:	85 c0                	test   %eax,%eax
f0101e20:	74 24                	je     f0101e46 <mem_init+0xc31>
f0101e22:	c7 44 24 0c b4 48 10 	movl   $0xf01048b4,0xc(%esp)
f0101e29:	f0 
f0101e2a:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101e31:	f0 
f0101e32:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0101e39:	00 
f0101e3a:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101e41:	e8 4e e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e46:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0101e4c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e51:	89 f8                	mov    %edi,%eax
f0101e53:	e8 5c eb ff ff       	call   f01009b4 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e58:	89 f2                	mov    %esi,%edx
f0101e5a:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101e60:	c1 fa 03             	sar    $0x3,%edx
f0101e63:	c1 e2 0c             	shl    $0xc,%edx
f0101e66:	39 d0                	cmp    %edx,%eax
f0101e68:	74 24                	je     f0101e8e <mem_init+0xc79>
f0101e6a:	c7 44 24 0c 44 48 10 	movl   $0xf0104844,0xc(%esp)
f0101e71:	f0 
f0101e72:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101e79:	f0 
f0101e7a:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101e81:	00 
f0101e82:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101e89:	e8 06 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e8e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e93:	74 24                	je     f0101eb9 <mem_init+0xca4>
f0101e95:	c7 44 24 0c 6a 44 10 	movl   $0xf010446a,0xc(%esp)
f0101e9c:	f0 
f0101e9d:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101ea4:	f0 
f0101ea5:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101eac:	00 
f0101ead:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101eb4:	e8 db e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101eb9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ec0:	00 
f0101ec1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ec8:	00 
f0101ec9:	89 3c 24             	mov    %edi,(%esp)
f0101ecc:	e8 f0 f0 ff ff       	call   f0100fc1 <pgdir_walk>
f0101ed1:	f6 00 04             	testb  $0x4,(%eax)
f0101ed4:	75 24                	jne    f0101efa <mem_init+0xce5>
f0101ed6:	c7 44 24 0c f4 48 10 	movl   $0xf01048f4,0xc(%esp)
f0101edd:	f0 
f0101ede:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101ee5:	f0 
f0101ee6:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101eed:	00 
f0101eee:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101ef5:	e8 9a e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101efa:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101eff:	f6 00 04             	testb  $0x4,(%eax)
f0101f02:	75 24                	jne    f0101f28 <mem_init+0xd13>
f0101f04:	c7 44 24 0c 7b 44 10 	movl   $0xf010447b,0xc(%esp)
f0101f0b:	f0 
f0101f0c:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101f13:	f0 
f0101f14:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101f1b:	00 
f0101f1c:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101f23:	e8 6c e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f28:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f2f:	00 
f0101f30:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f37:	00 
f0101f38:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f3c:	89 04 24             	mov    %eax,(%esp)
f0101f3f:	e8 62 f2 ff ff       	call   f01011a6 <page_insert>
f0101f44:	85 c0                	test   %eax,%eax
f0101f46:	78 24                	js     f0101f6c <mem_init+0xd57>
f0101f48:	c7 44 24 0c 28 49 10 	movl   $0xf0104928,0xc(%esp)
f0101f4f:	f0 
f0101f50:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101f57:	f0 
f0101f58:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101f5f:	00 
f0101f60:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101f67:	e8 28 e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f6c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f73:	00 
f0101f74:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f7b:	00 
f0101f7c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f7f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f83:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101f88:	89 04 24             	mov    %eax,(%esp)
f0101f8b:	e8 16 f2 ff ff       	call   f01011a6 <page_insert>
f0101f90:	85 c0                	test   %eax,%eax
f0101f92:	74 24                	je     f0101fb8 <mem_init+0xda3>
f0101f94:	c7 44 24 0c 60 49 10 	movl   $0xf0104960,0xc(%esp)
f0101f9b:	f0 
f0101f9c:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101fa3:	f0 
f0101fa4:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101fab:	00 
f0101fac:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101fb3:	e8 dc e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fb8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fbf:	00 
f0101fc0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fc7:	00 
f0101fc8:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101fcd:	89 04 24             	mov    %eax,(%esp)
f0101fd0:	e8 ec ef ff ff       	call   f0100fc1 <pgdir_walk>
f0101fd5:	f6 00 04             	testb  $0x4,(%eax)
f0101fd8:	74 24                	je     f0101ffe <mem_init+0xde9>
f0101fda:	c7 44 24 0c 9c 49 10 	movl   $0xf010499c,0xc(%esp)
f0101fe1:	f0 
f0101fe2:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0101fe9:	f0 
f0101fea:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101ff1:	00 
f0101ff2:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0101ff9:	e8 96 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ffe:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0102004:	ba 00 00 00 00       	mov    $0x0,%edx
f0102009:	89 f8                	mov    %edi,%eax
f010200b:	e8 a4 e9 ff ff       	call   f01009b4 <check_va2pa>
f0102010:	89 c1                	mov    %eax,%ecx
f0102012:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102015:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102018:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f010201e:	c1 f8 03             	sar    $0x3,%eax
f0102021:	c1 e0 0c             	shl    $0xc,%eax
f0102024:	39 c1                	cmp    %eax,%ecx
f0102026:	74 24                	je     f010204c <mem_init+0xe37>
f0102028:	c7 44 24 0c d4 49 10 	movl   $0xf01049d4,0xc(%esp)
f010202f:	f0 
f0102030:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102037:	f0 
f0102038:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f010203f:	00 
f0102040:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102047:	e8 48 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010204c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102051:	89 f8                	mov    %edi,%eax
f0102053:	e8 5c e9 ff ff       	call   f01009b4 <check_va2pa>
f0102058:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010205b:	74 24                	je     f0102081 <mem_init+0xe6c>
f010205d:	c7 44 24 0c 00 4a 10 	movl   $0xf0104a00,0xc(%esp)
f0102064:	f0 
f0102065:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010206c:	f0 
f010206d:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0102074:	00 
f0102075:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010207c:	e8 13 e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102081:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102084:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0102089:	74 24                	je     f01020af <mem_init+0xe9a>
f010208b:	c7 44 24 0c 91 44 10 	movl   $0xf0104491,0xc(%esp)
f0102092:	f0 
f0102093:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010209a:	f0 
f010209b:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f01020a2:	00 
f01020a3:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01020aa:	e8 e5 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01020af:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020b4:	74 24                	je     f01020da <mem_init+0xec5>
f01020b6:	c7 44 24 0c a2 44 10 	movl   $0xf01044a2,0xc(%esp)
f01020bd:	f0 
f01020be:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01020c5:	f0 
f01020c6:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f01020cd:	00 
f01020ce:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01020d5:	e8 ba df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01020da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020e1:	e8 1e ee ff ff       	call   f0100f04 <page_alloc>
f01020e6:	85 c0                	test   %eax,%eax
f01020e8:	74 04                	je     f01020ee <mem_init+0xed9>
f01020ea:	39 c6                	cmp    %eax,%esi
f01020ec:	74 24                	je     f0102112 <mem_init+0xefd>
f01020ee:	c7 44 24 0c 30 4a 10 	movl   $0xf0104a30,0xc(%esp)
f01020f5:	f0 
f01020f6:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01020fd:	f0 
f01020fe:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0102105:	00 
f0102106:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010210d:	e8 82 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102112:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102119:	00 
f010211a:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010211f:	89 04 24             	mov    %eax,(%esp)
f0102122:	e8 39 f0 ff ff       	call   f0101160 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102127:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f010212d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102132:	89 f8                	mov    %edi,%eax
f0102134:	e8 7b e8 ff ff       	call   f01009b4 <check_va2pa>
f0102139:	83 f8 ff             	cmp    $0xffffffff,%eax
f010213c:	74 24                	je     f0102162 <mem_init+0xf4d>
f010213e:	c7 44 24 0c 54 4a 10 	movl   $0xf0104a54,0xc(%esp)
f0102145:	f0 
f0102146:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010214d:	f0 
f010214e:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0102155:	00 
f0102156:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010215d:	e8 32 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102162:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102167:	89 f8                	mov    %edi,%eax
f0102169:	e8 46 e8 ff ff       	call   f01009b4 <check_va2pa>
f010216e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102171:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102177:	c1 fa 03             	sar    $0x3,%edx
f010217a:	c1 e2 0c             	shl    $0xc,%edx
f010217d:	39 d0                	cmp    %edx,%eax
f010217f:	74 24                	je     f01021a5 <mem_init+0xf90>
f0102181:	c7 44 24 0c 00 4a 10 	movl   $0xf0104a00,0xc(%esp)
f0102188:	f0 
f0102189:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102190:	f0 
f0102191:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0102198:	00 
f0102199:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01021a0:	e8 ef de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01021a5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021a8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021ad:	74 24                	je     f01021d3 <mem_init+0xfbe>
f01021af:	c7 44 24 0c 48 44 10 	movl   $0xf0104448,0xc(%esp)
f01021b6:	f0 
f01021b7:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01021be:	f0 
f01021bf:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f01021c6:	00 
f01021c7:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01021ce:	e8 c1 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021d3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021d8:	74 24                	je     f01021fe <mem_init+0xfe9>
f01021da:	c7 44 24 0c a2 44 10 	movl   $0xf01044a2,0xc(%esp)
f01021e1:	f0 
f01021e2:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01021e9:	f0 
f01021ea:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f01021f1:	00 
f01021f2:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01021f9:	e8 96 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021fe:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102205:	00 
f0102206:	89 3c 24             	mov    %edi,(%esp)
f0102209:	e8 52 ef ff ff       	call   f0101160 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010220e:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0102214:	ba 00 00 00 00       	mov    $0x0,%edx
f0102219:	89 f8                	mov    %edi,%eax
f010221b:	e8 94 e7 ff ff       	call   f01009b4 <check_va2pa>
f0102220:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102223:	74 24                	je     f0102249 <mem_init+0x1034>
f0102225:	c7 44 24 0c 54 4a 10 	movl   $0xf0104a54,0xc(%esp)
f010222c:	f0 
f010222d:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102234:	f0 
f0102235:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f010223c:	00 
f010223d:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102244:	e8 4b de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102249:	ba 00 10 00 00       	mov    $0x1000,%edx
f010224e:	89 f8                	mov    %edi,%eax
f0102250:	e8 5f e7 ff ff       	call   f01009b4 <check_va2pa>
f0102255:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102258:	74 24                	je     f010227e <mem_init+0x1069>
f010225a:	c7 44 24 0c 78 4a 10 	movl   $0xf0104a78,0xc(%esp)
f0102261:	f0 
f0102262:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102269:	f0 
f010226a:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102271:	00 
f0102272:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102279:	e8 16 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010227e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102281:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102286:	74 24                	je     f01022ac <mem_init+0x1097>
f0102288:	c7 44 24 0c b3 44 10 	movl   $0xf01044b3,0xc(%esp)
f010228f:	f0 
f0102290:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102297:	f0 
f0102298:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f010229f:	00 
f01022a0:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01022a7:	e8 e8 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01022ac:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01022b1:	74 24                	je     f01022d7 <mem_init+0x10c2>
f01022b3:	c7 44 24 0c a2 44 10 	movl   $0xf01044a2,0xc(%esp)
f01022ba:	f0 
f01022bb:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01022c2:	f0 
f01022c3:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f01022ca:	00 
f01022cb:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01022d2:	e8 bd dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01022d7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022de:	e8 21 ec ff ff       	call   f0100f04 <page_alloc>
f01022e3:	85 c0                	test   %eax,%eax
f01022e5:	74 05                	je     f01022ec <mem_init+0x10d7>
f01022e7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01022ea:	74 24                	je     f0102310 <mem_init+0x10fb>
f01022ec:	c7 44 24 0c a0 4a 10 	movl   $0xf0104aa0,0xc(%esp)
f01022f3:	f0 
f01022f4:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01022fb:	f0 
f01022fc:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0102303:	00 
f0102304:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010230b:	e8 84 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102310:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102317:	e8 e8 eb ff ff       	call   f0100f04 <page_alloc>
f010231c:	85 c0                	test   %eax,%eax
f010231e:	74 24                	je     f0102344 <mem_init+0x112f>
f0102320:	c7 44 24 0c f6 43 10 	movl   $0xf01043f6,0xc(%esp)
f0102327:	f0 
f0102328:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010232f:	f0 
f0102330:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0102337:	00 
f0102338:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010233f:	e8 50 dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102344:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102349:	8b 08                	mov    (%eax),%ecx
f010234b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102351:	89 da                	mov    %ebx,%edx
f0102353:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102359:	c1 fa 03             	sar    $0x3,%edx
f010235c:	c1 e2 0c             	shl    $0xc,%edx
f010235f:	39 d1                	cmp    %edx,%ecx
f0102361:	74 24                	je     f0102387 <mem_init+0x1172>
f0102363:	c7 44 24 0c b0 47 10 	movl   $0xf01047b0,0xc(%esp)
f010236a:	f0 
f010236b:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102372:	f0 
f0102373:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f010237a:	00 
f010237b:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102382:	e8 0d dd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102387:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010238d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102392:	74 24                	je     f01023b8 <mem_init+0x11a3>
f0102394:	c7 44 24 0c 59 44 10 	movl   $0xf0104459,0xc(%esp)
f010239b:	f0 
f010239c:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01023a3:	f0 
f01023a4:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f01023ab:	00 
f01023ac:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01023b3:	e8 dc dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01023b8:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01023be:	89 1c 24             	mov    %ebx,(%esp)
f01023c1:	e8 c3 eb ff ff       	call   f0100f89 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01023c6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01023cd:	00 
f01023ce:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01023d5:	00 
f01023d6:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01023db:	89 04 24             	mov    %eax,(%esp)
f01023de:	e8 de eb ff ff       	call   f0100fc1 <pgdir_walk>
f01023e3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01023e6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01023e9:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f01023ef:	8b 7a 04             	mov    0x4(%edx),%edi
f01023f2:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023f8:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f01023fe:	89 f8                	mov    %edi,%eax
f0102400:	c1 e8 0c             	shr    $0xc,%eax
f0102403:	39 c8                	cmp    %ecx,%eax
f0102405:	72 20                	jb     f0102427 <mem_init+0x1212>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102407:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010240b:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0102412:	f0 
f0102413:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f010241a:	00 
f010241b:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102422:	e8 6d dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102427:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010242d:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102430:	74 24                	je     f0102456 <mem_init+0x1241>
f0102432:	c7 44 24 0c c4 44 10 	movl   $0xf01044c4,0xc(%esp)
f0102439:	f0 
f010243a:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102441:	f0 
f0102442:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102449:	00 
f010244a:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102451:	e8 3e dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102456:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f010245d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102463:	89 d8                	mov    %ebx,%eax
f0102465:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f010246b:	c1 f8 03             	sar    $0x3,%eax
f010246e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102471:	89 c2                	mov    %eax,%edx
f0102473:	c1 ea 0c             	shr    $0xc,%edx
f0102476:	39 d1                	cmp    %edx,%ecx
f0102478:	77 20                	ja     f010249a <mem_init+0x1285>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010247a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010247e:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0102485:	f0 
f0102486:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010248d:	00 
f010248e:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f0102495:	e8 fa db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010249a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024a1:	00 
f01024a2:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01024a9:	00 
	return (void *)(pa + KERNBASE);
f01024aa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024af:	89 04 24             	mov    %eax,(%esp)
f01024b2:	e8 d8 13 00 00       	call   f010388f <memset>
	page_free(pp0);
f01024b7:	89 1c 24             	mov    %ebx,(%esp)
f01024ba:	e8 ca ea ff ff       	call   f0100f89 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01024bf:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024c6:	00 
f01024c7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024ce:	00 
f01024cf:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01024d4:	89 04 24             	mov    %eax,(%esp)
f01024d7:	e8 e5 ea ff ff       	call   f0100fc1 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024dc:	89 da                	mov    %ebx,%edx
f01024de:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01024e4:	c1 fa 03             	sar    $0x3,%edx
f01024e7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024ea:	89 d0                	mov    %edx,%eax
f01024ec:	c1 e8 0c             	shr    $0xc,%eax
f01024ef:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f01024f5:	72 20                	jb     f0102517 <mem_init+0x1302>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024f7:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01024fb:	c7 44 24 08 48 45 10 	movl   $0xf0104548,0x8(%esp)
f0102502:	f0 
f0102503:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010250a:	00 
f010250b:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f0102512:	e8 7d db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102517:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010251d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102520:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102527:	75 11                	jne    f010253a <mem_init+0x1325>
f0102529:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
f010252f:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f0102535:	f6 00 01             	testb  $0x1,(%eax)
f0102538:	74 24                	je     f010255e <mem_init+0x1349>
f010253a:	c7 44 24 0c dc 44 10 	movl   $0xf01044dc,0xc(%esp)
f0102541:	f0 
f0102542:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102549:	f0 
f010254a:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102551:	00 
f0102552:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102559:	e8 36 db ff ff       	call   f0100094 <_panic>
f010255e:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102561:	39 d0                	cmp    %edx,%eax
f0102563:	75 d0                	jne    f0102535 <mem_init+0x1320>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102565:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010256a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102570:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102576:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102579:	a3 5c 75 11 f0       	mov    %eax,0xf011755c

	// free the pages we took
	page_free(pp0);
f010257e:	89 1c 24             	mov    %ebx,(%esp)
f0102581:	e8 03 ea ff ff       	call   f0100f89 <page_free>
	page_free(pp1);
f0102586:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102589:	89 04 24             	mov    %eax,(%esp)
f010258c:	e8 f8 e9 ff ff       	call   f0100f89 <page_free>
	page_free(pp2);
f0102591:	89 34 24             	mov    %esi,(%esp)
f0102594:	e8 f0 e9 ff ff       	call   f0100f89 <page_free>

	cprintf("check_page() succeeded!\n");
f0102599:	c7 04 24 f3 44 10 f0 	movl   $0xf01044f3,(%esp)
f01025a0:	e8 47 07 00 00       	call   f0102cec <cprintf>
	page_init();

	check_page_free_list(1);
	check_page_alloc();
	check_page();
	cprintf("checked!\n");
f01025a5:	c7 04 24 0c 45 10 f0 	movl   $0xf010450c,(%esp)
f01025ac:	e8 3b 07 00 00       	call   f0102cec <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01025b1:	a1 88 79 11 f0       	mov    0xf0117988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025b6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025bb:	77 20                	ja     f01025dd <mem_init+0x13c8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025c1:	c7 44 24 08 30 46 10 	movl   $0xf0104630,0x8(%esp)
f01025c8:	f0 
f01025c9:	c7 44 24 04 ba 00 00 	movl   $0xba,0x4(%esp)
f01025d0:	00 
f01025d1:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01025d8:	e8 b7 da ff ff       	call   f0100094 <_panic>
f01025dd:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01025e4:	00 
	return (physaddr_t)kva - KERNBASE;
f01025e5:	05 00 00 00 10       	add    $0x10000000,%eax
f01025ea:	89 04 24             	mov    %eax,(%esp)
f01025ed:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025f2:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025f7:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01025fc:	e8 60 ea ff ff       	call   f0101061 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102601:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f0102606:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010260c:	77 20                	ja     f010262e <mem_init+0x1419>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010260e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102612:	c7 44 24 08 30 46 10 	movl   $0xf0104630,0x8(%esp)
f0102619:	f0 
f010261a:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f0102621:	00 
f0102622:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102629:	e8 66 da ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010262e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102635:	00 
f0102636:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f010263d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102642:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102647:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010264c:	e8 10 ea ff ff       	call   f0101061 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f0102651:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102658:	00 
f0102659:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102660:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102665:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010266a:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010266f:	e8 ed e9 ff ff       	call   f0101061 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102674:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f010267a:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f010267f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102682:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f0102689:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010268e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102691:	0f 84 84 00 00 00    	je     f010271b <mem_init+0x1506>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102697:	8b 35 88 79 11 f0    	mov    0xf0117988,%esi
	return (physaddr_t)kva - KERNBASE;
f010269d:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01026a3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01026a6:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026ab:	89 f8                	mov    %edi,%eax
f01026ad:	e8 02 e3 ff ff       	call   f01009b4 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026b2:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01026b8:	77 20                	ja     f01026da <mem_init+0x14c5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026ba:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01026be:	c7 44 24 08 30 46 10 	movl   $0xf0104630,0x8(%esp)
f01026c5:	f0 
f01026c6:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01026cd:	00 
f01026ce:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01026d5:	e8 ba d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026da:	ba 00 00 00 00       	mov    $0x0,%edx
f01026df:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01026e2:	01 d1                	add    %edx,%ecx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026e4:	39 c1                	cmp    %eax,%ecx
f01026e6:	74 24                	je     f010270c <mem_init+0x14f7>
f01026e8:	c7 44 24 0c c4 4a 10 	movl   $0xf0104ac4,0xc(%esp)
f01026ef:	f0 
f01026f0:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01026f7:	f0 
f01026f8:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01026ff:	00 
f0102700:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102707:	e8 88 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010270c:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f0102712:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102715:	0f 87 3a 05 00 00    	ja     f0102c55 <mem_init+0x1a40>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010271b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010271e:	c1 e0 0c             	shl    $0xc,%eax
f0102721:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102724:	85 c0                	test   %eax,%eax
f0102726:	0f 84 0a 05 00 00    	je     f0102c36 <mem_init+0x1a21>
f010272c:	be 00 00 00 00       	mov    $0x0,%esi
f0102731:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102737:	89 f8                	mov    %edi,%eax
f0102739:	e8 76 e2 ff ff       	call   f01009b4 <check_va2pa>
f010273e:	39 c6                	cmp    %eax,%esi
f0102740:	74 24                	je     f0102766 <mem_init+0x1551>
f0102742:	c7 44 24 0c f8 4a 10 	movl   $0xf0104af8,0xc(%esp)
f0102749:	f0 
f010274a:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102751:	f0 
f0102752:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f0102759:	00 
f010275a:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102761:	e8 2e d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102766:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010276c:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010276f:	72 c0                	jb     f0102731 <mem_init+0x151c>
f0102771:	e9 c0 04 00 00       	jmp    f0102c36 <mem_init+0x1a21>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102776:	39 c6                	cmp    %eax,%esi
f0102778:	74 24                	je     f010279e <mem_init+0x1589>
f010277a:	c7 44 24 0c 20 4b 10 	movl   $0xf0104b20,0xc(%esp)
f0102781:	f0 
f0102782:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102789:	f0 
f010278a:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f0102791:	00 
f0102792:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102799:	e8 f6 d8 ff ff       	call   f0100094 <_panic>
f010279e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01027a4:	81 fe 00 50 11 00    	cmp    $0x115000,%esi
f01027aa:	0f 85 77 04 00 00    	jne    f0102c27 <mem_init+0x1a12>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01027b0:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f01027b5:	89 f8                	mov    %edi,%eax
f01027b7:	e8 f8 e1 ff ff       	call   f01009b4 <check_va2pa>
f01027bc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027bf:	74 24                	je     f01027e5 <mem_init+0x15d0>
f01027c1:	c7 44 24 0c 68 4b 10 	movl   $0xf0104b68,0xc(%esp)
f01027c8:	f0 
f01027c9:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f01027d0:	f0 
f01027d1:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f01027d8:	00 
f01027d9:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01027e0:	e8 af d8 ff ff       	call   f0100094 <_panic>
f01027e5:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01027ea:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01027f0:	83 fa 02             	cmp    $0x2,%edx
f01027f3:	77 2e                	ja     f0102823 <mem_init+0x160e>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01027f5:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01027f9:	0f 85 aa 00 00 00    	jne    f01028a9 <mem_init+0x1694>
f01027ff:	c7 44 24 0c 16 45 10 	movl   $0xf0104516,0xc(%esp)
f0102806:	f0 
f0102807:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010280e:	f0 
f010280f:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0102816:	00 
f0102817:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010281e:	e8 71 d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102823:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102828:	76 55                	jbe    f010287f <mem_init+0x166a>
				assert(pgdir[i] & PTE_P);
f010282a:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010282d:	f6 c2 01             	test   $0x1,%dl
f0102830:	75 24                	jne    f0102856 <mem_init+0x1641>
f0102832:	c7 44 24 0c 16 45 10 	movl   $0xf0104516,0xc(%esp)
f0102839:	f0 
f010283a:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102841:	f0 
f0102842:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102849:	00 
f010284a:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102851:	e8 3e d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102856:	f6 c2 02             	test   $0x2,%dl
f0102859:	75 4e                	jne    f01028a9 <mem_init+0x1694>
f010285b:	c7 44 24 0c 27 45 10 	movl   $0xf0104527,0xc(%esp)
f0102862:	f0 
f0102863:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010286a:	f0 
f010286b:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0102872:	00 
f0102873:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f010287a:	e8 15 d8 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f010287f:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102883:	74 24                	je     f01028a9 <mem_init+0x1694>
f0102885:	c7 44 24 0c 38 45 10 	movl   $0xf0104538,0xc(%esp)
f010288c:	f0 
f010288d:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102894:	f0 
f0102895:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f010289c:	00 
f010289d:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01028a4:	e8 eb d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01028a9:	83 c0 01             	add    $0x1,%eax
f01028ac:	3d 00 04 00 00       	cmp    $0x400,%eax
f01028b1:	0f 85 33 ff ff ff    	jne    f01027ea <mem_init+0x15d5>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01028b7:	c7 04 24 98 4b 10 f0 	movl   $0xf0104b98,(%esp)
f01028be:	e8 29 04 00 00       	call   f0102cec <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028c3:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028c8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028cd:	77 20                	ja     f01028ef <mem_init+0x16da>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028d3:	c7 44 24 08 30 46 10 	movl   $0xf0104630,0x8(%esp)
f01028da:	f0 
f01028db:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
f01028e2:	00 
f01028e3:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01028ea:	e8 a5 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01028ef:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01028f4:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01028f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01028fc:	e8 22 e1 ff ff       	call   f0100a23 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102901:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102904:	83 e0 f3             	and    $0xfffffff3,%eax
f0102907:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010290c:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010290f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102916:	e8 e9 e5 ff ff       	call   f0100f04 <page_alloc>
f010291b:	89 c3                	mov    %eax,%ebx
f010291d:	85 c0                	test   %eax,%eax
f010291f:	75 24                	jne    f0102945 <mem_init+0x1730>
f0102921:	c7 44 24 0c 4b 43 10 	movl   $0xf010434b,0xc(%esp)
f0102928:	f0 
f0102929:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102930:	f0 
f0102931:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0102938:	00 
f0102939:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102940:	e8 4f d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102945:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010294c:	e8 b3 e5 ff ff       	call   f0100f04 <page_alloc>
f0102951:	89 c7                	mov    %eax,%edi
f0102953:	85 c0                	test   %eax,%eax
f0102955:	75 24                	jne    f010297b <mem_init+0x1766>
f0102957:	c7 44 24 0c 61 43 10 	movl   $0xf0104361,0xc(%esp)
f010295e:	f0 
f010295f:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102966:	f0 
f0102967:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f010296e:	00 
f010296f:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102976:	e8 19 d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010297b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102982:	e8 7d e5 ff ff       	call   f0100f04 <page_alloc>
f0102987:	89 c6                	mov    %eax,%esi
f0102989:	85 c0                	test   %eax,%eax
f010298b:	75 24                	jne    f01029b1 <mem_init+0x179c>
f010298d:	c7 44 24 0c 77 43 10 	movl   $0xf0104377,0xc(%esp)
f0102994:	f0 
f0102995:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f010299c:	f0 
f010299d:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f01029a4:	00 
f01029a5:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f01029ac:	e8 e3 d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01029b1:	89 1c 24             	mov    %ebx,(%esp)
f01029b4:	e8 d0 e5 ff ff       	call   f0100f89 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01029b9:	89 f8                	mov    %edi,%eax
f01029bb:	e8 af df ff ff       	call   f010096f <page2kva>
f01029c0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029c7:	00 
f01029c8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01029cf:	00 
f01029d0:	89 04 24             	mov    %eax,(%esp)
f01029d3:	e8 b7 0e 00 00       	call   f010388f <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01029d8:	89 f0                	mov    %esi,%eax
f01029da:	e8 90 df ff ff       	call   f010096f <page2kva>
f01029df:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029e6:	00 
f01029e7:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01029ee:	00 
f01029ef:	89 04 24             	mov    %eax,(%esp)
f01029f2:	e8 98 0e 00 00       	call   f010388f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01029f7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01029fe:	00 
f01029ff:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a06:	00 
f0102a07:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102a0b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102a10:	89 04 24             	mov    %eax,(%esp)
f0102a13:	e8 8e e7 ff ff       	call   f01011a6 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a18:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a1d:	74 24                	je     f0102a43 <mem_init+0x182e>
f0102a1f:	c7 44 24 0c 48 44 10 	movl   $0xf0104448,0xc(%esp)
f0102a26:	f0 
f0102a27:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102a2e:	f0 
f0102a2f:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0102a36:	00 
f0102a37:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102a3e:	e8 51 d6 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a43:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a4a:	01 01 01 
f0102a4d:	74 24                	je     f0102a73 <mem_init+0x185e>
f0102a4f:	c7 44 24 0c b8 4b 10 	movl   $0xf0104bb8,0xc(%esp)
f0102a56:	f0 
f0102a57:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102a5e:	f0 
f0102a5f:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0102a66:	00 
f0102a67:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102a6e:	e8 21 d6 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a73:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a7a:	00 
f0102a7b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a82:	00 
f0102a83:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102a87:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102a8c:	89 04 24             	mov    %eax,(%esp)
f0102a8f:	e8 12 e7 ff ff       	call   f01011a6 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a94:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a9b:	02 02 02 
f0102a9e:	74 24                	je     f0102ac4 <mem_init+0x18af>
f0102aa0:	c7 44 24 0c dc 4b 10 	movl   $0xf0104bdc,0xc(%esp)
f0102aa7:	f0 
f0102aa8:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102aaf:	f0 
f0102ab0:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0102ab7:	00 
f0102ab8:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102abf:	e8 d0 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102ac4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ac9:	74 24                	je     f0102aef <mem_init+0x18da>
f0102acb:	c7 44 24 0c 6a 44 10 	movl   $0xf010446a,0xc(%esp)
f0102ad2:	f0 
f0102ad3:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102ada:	f0 
f0102adb:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0102ae2:	00 
f0102ae3:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102aea:	e8 a5 d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102aef:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102af4:	74 24                	je     f0102b1a <mem_init+0x1905>
f0102af6:	c7 44 24 0c b3 44 10 	movl   $0xf01044b3,0xc(%esp)
f0102afd:	f0 
f0102afe:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102b05:	f0 
f0102b06:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0102b0d:	00 
f0102b0e:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102b15:	e8 7a d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b1a:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b21:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b24:	89 f0                	mov    %esi,%eax
f0102b26:	e8 44 de ff ff       	call   f010096f <page2kva>
f0102b2b:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102b31:	74 24                	je     f0102b57 <mem_init+0x1942>
f0102b33:	c7 44 24 0c 00 4c 10 	movl   $0xf0104c00,0xc(%esp)
f0102b3a:	f0 
f0102b3b:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102b42:	f0 
f0102b43:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0102b4a:	00 
f0102b4b:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102b52:	e8 3d d5 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b57:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102b5e:	00 
f0102b5f:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102b64:	89 04 24             	mov    %eax,(%esp)
f0102b67:	e8 f4 e5 ff ff       	call   f0101160 <page_remove>
	assert(pp2->pp_ref == 0);
f0102b6c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102b71:	74 24                	je     f0102b97 <mem_init+0x1982>
f0102b73:	c7 44 24 0c a2 44 10 	movl   $0xf01044a2,0xc(%esp)
f0102b7a:	f0 
f0102b7b:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102b82:	f0 
f0102b83:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0102b8a:	00 
f0102b8b:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102b92:	e8 fd d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b97:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102b9c:	8b 08                	mov    (%eax),%ecx
f0102b9e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ba4:	89 da                	mov    %ebx,%edx
f0102ba6:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102bac:	c1 fa 03             	sar    $0x3,%edx
f0102baf:	c1 e2 0c             	shl    $0xc,%edx
f0102bb2:	39 d1                	cmp    %edx,%ecx
f0102bb4:	74 24                	je     f0102bda <mem_init+0x19c5>
f0102bb6:	c7 44 24 0c b0 47 10 	movl   $0xf01047b0,0xc(%esp)
f0102bbd:	f0 
f0102bbe:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102bc5:	f0 
f0102bc6:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0102bcd:	00 
f0102bce:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102bd5:	e8 ba d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102bda:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102be0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102be5:	74 24                	je     f0102c0b <mem_init+0x19f6>
f0102be7:	c7 44 24 0c 59 44 10 	movl   $0xf0104459,0xc(%esp)
f0102bee:	f0 
f0102bef:	c7 44 24 08 5e 42 10 	movl   $0xf010425e,0x8(%esp)
f0102bf6:	f0 
f0102bf7:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0102bfe:	00 
f0102bff:	c7 04 24 46 42 10 f0 	movl   $0xf0104246,(%esp)
f0102c06:	e8 89 d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102c0b:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c11:	89 1c 24             	mov    %ebx,(%esp)
f0102c14:	e8 70 e3 ff ff       	call   f0100f89 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c19:	c7 04 24 2c 4c 10 f0 	movl   $0xf0104c2c,(%esp)
f0102c20:	e8 c7 00 00 00       	call   f0102cec <cprintf>
f0102c25:	eb 42                	jmp    f0102c69 <mem_init+0x1a54>
f0102c27:	8d 14 33             	lea    (%ebx,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c2a:	89 f8                	mov    %edi,%eax
f0102c2c:	e8 83 dd ff ff       	call   f01009b4 <check_va2pa>
f0102c31:	e9 40 fb ff ff       	jmp    f0102776 <mem_init+0x1561>
f0102c36:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102c3b:	89 f8                	mov    %edi,%eax
f0102c3d:	e8 72 dd ff ff       	call   f01009b4 <check_va2pa>
f0102c42:	be 00 d0 10 00       	mov    $0x10d000,%esi
f0102c47:	ba 00 80 bf df       	mov    $0xdfbf8000,%edx
f0102c4c:	29 da                	sub    %ebx,%edx
f0102c4e:	89 d3                	mov    %edx,%ebx
f0102c50:	e9 21 fb ff ff       	jmp    f0102776 <mem_init+0x1561>
f0102c55:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102c5b:	89 f8                	mov    %edi,%eax
f0102c5d:	e8 52 dd ff ff       	call   f01009b4 <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102c62:	89 f2                	mov    %esi,%edx
f0102c64:	e9 76 fa ff ff       	jmp    f01026df <mem_init+0x14ca>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c69:	83 c4 3c             	add    $0x3c,%esp
f0102c6c:	5b                   	pop    %ebx
f0102c6d:	5e                   	pop    %esi
f0102c6e:	5f                   	pop    %edi
f0102c6f:	5d                   	pop    %ebp
f0102c70:	c3                   	ret    

f0102c71 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102c71:	55                   	push   %ebp
f0102c72:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102c74:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c77:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102c7a:	5d                   	pop    %ebp
f0102c7b:	c3                   	ret    

f0102c7c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102c7c:	55                   	push   %ebp
f0102c7d:	89 e5                	mov    %esp,%ebp
f0102c7f:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c83:	ba 70 00 00 00       	mov    $0x70,%edx
f0102c88:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102c89:	b2 71                	mov    $0x71,%dl
f0102c8b:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102c8c:	0f b6 c0             	movzbl %al,%eax
}
f0102c8f:	5d                   	pop    %ebp
f0102c90:	c3                   	ret    

f0102c91 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102c91:	55                   	push   %ebp
f0102c92:	89 e5                	mov    %esp,%ebp
f0102c94:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c98:	ba 70 00 00 00       	mov    $0x70,%edx
f0102c9d:	ee                   	out    %al,(%dx)
f0102c9e:	b2 71                	mov    $0x71,%dl
f0102ca0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ca3:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ca4:	5d                   	pop    %ebp
f0102ca5:	c3                   	ret    

f0102ca6 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ca6:	55                   	push   %ebp
f0102ca7:	89 e5                	mov    %esp,%ebp
f0102ca9:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102cac:	8b 45 08             	mov    0x8(%ebp),%eax
f0102caf:	89 04 24             	mov    %eax,(%esp)
f0102cb2:	e8 36 d9 ff ff       	call   f01005ed <cputchar>
	*cnt++;
}
f0102cb7:	c9                   	leave  
f0102cb8:	c3                   	ret    

f0102cb9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102cb9:	55                   	push   %ebp
f0102cba:	89 e5                	mov    %esp,%ebp
f0102cbc:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102cbf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102cc6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cc9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ccd:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cd0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102cd4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102cd7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cdb:	c7 04 24 a6 2c 10 f0 	movl   $0xf0102ca6,(%esp)
f0102ce2:	e8 8d 04 00 00       	call   f0103174 <vprintfmt>
	return cnt;
}
f0102ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102cea:	c9                   	leave  
f0102ceb:	c3                   	ret    

f0102cec <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102cec:	55                   	push   %ebp
f0102ced:	89 e5                	mov    %esp,%ebp
f0102cef:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102cf2:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102cf5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cf9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cfc:	89 04 24             	mov    %eax,(%esp)
f0102cff:	e8 b5 ff ff ff       	call   f0102cb9 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d04:	c9                   	leave  
f0102d05:	c3                   	ret    
f0102d06:	66 90                	xchg   %ax,%ax
f0102d08:	66 90                	xchg   %ax,%ax
f0102d0a:	66 90                	xchg   %ax,%ax
f0102d0c:	66 90                	xchg   %ax,%ax
f0102d0e:	66 90                	xchg   %ax,%ax

f0102d10 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d10:	55                   	push   %ebp
f0102d11:	89 e5                	mov    %esp,%ebp
f0102d13:	57                   	push   %edi
f0102d14:	56                   	push   %esi
f0102d15:	53                   	push   %ebx
f0102d16:	83 ec 10             	sub    $0x10,%esp
f0102d19:	89 c6                	mov    %eax,%esi
f0102d1b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d1e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d21:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d24:	8b 1a                	mov    (%edx),%ebx
f0102d26:	8b 01                	mov    (%ecx),%eax
f0102d28:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d2b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102d32:	eb 77                	jmp    f0102dab <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102d34:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d37:	01 d8                	add    %ebx,%eax
f0102d39:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102d3e:	99                   	cltd   
f0102d3f:	f7 f9                	idiv   %ecx
f0102d41:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d43:	eb 01                	jmp    f0102d46 <stab_binsearch+0x36>
			m--;
f0102d45:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d46:	39 d9                	cmp    %ebx,%ecx
f0102d48:	7c 1d                	jl     f0102d67 <stab_binsearch+0x57>
f0102d4a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102d4d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102d52:	39 fa                	cmp    %edi,%edx
f0102d54:	75 ef                	jne    f0102d45 <stab_binsearch+0x35>
f0102d56:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102d59:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102d5c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102d60:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102d63:	73 18                	jae    f0102d7d <stab_binsearch+0x6d>
f0102d65:	eb 05                	jmp    f0102d6c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102d67:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102d6a:	eb 3f                	jmp    f0102dab <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102d6c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102d6f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102d71:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d74:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102d7b:	eb 2e                	jmp    f0102dab <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102d7d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102d80:	73 15                	jae    f0102d97 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102d82:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102d85:	48                   	dec    %eax
f0102d86:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d89:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102d8c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d8e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102d95:	eb 14                	jmp    f0102dab <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102d97:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102d9a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102d9d:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102d9f:	ff 45 0c             	incl   0xc(%ebp)
f0102da2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102da4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102dab:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102dae:	7e 84                	jle    f0102d34 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102db0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102db4:	75 0d                	jne    f0102dc3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102db6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102db9:	8b 00                	mov    (%eax),%eax
f0102dbb:	48                   	dec    %eax
f0102dbc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dbf:	89 07                	mov    %eax,(%edi)
f0102dc1:	eb 22                	jmp    f0102de5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102dc3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102dc6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102dc8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102dcb:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102dcd:	eb 01                	jmp    f0102dd0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102dcf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102dd0:	39 c1                	cmp    %eax,%ecx
f0102dd2:	7d 0c                	jge    f0102de0 <stab_binsearch+0xd0>
f0102dd4:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102dd7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102ddc:	39 fa                	cmp    %edi,%edx
f0102dde:	75 ef                	jne    f0102dcf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102de0:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102de3:	89 07                	mov    %eax,(%edi)
	}
}
f0102de5:	83 c4 10             	add    $0x10,%esp
f0102de8:	5b                   	pop    %ebx
f0102de9:	5e                   	pop    %esi
f0102dea:	5f                   	pop    %edi
f0102deb:	5d                   	pop    %ebp
f0102dec:	c3                   	ret    

f0102ded <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102ded:	55                   	push   %ebp
f0102dee:	89 e5                	mov    %esp,%ebp
f0102df0:	57                   	push   %edi
f0102df1:	56                   	push   %esi
f0102df2:	53                   	push   %ebx
f0102df3:	83 ec 2c             	sub    $0x2c,%esp
f0102df6:	8b 75 08             	mov    0x8(%ebp),%esi
f0102df9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102dfc:	c7 03 58 4c 10 f0    	movl   $0xf0104c58,(%ebx)
	info->eip_line = 0;
f0102e02:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e09:	c7 43 08 58 4c 10 f0 	movl   $0xf0104c58,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e10:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e17:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e1a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e21:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e27:	76 12                	jbe    f0102e3b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e29:	b8 95 c8 10 f0       	mov    $0xf010c895,%eax
f0102e2e:	3d 69 ab 10 f0       	cmp    $0xf010ab69,%eax
f0102e33:	0f 86 8b 01 00 00    	jbe    f0102fc4 <debuginfo_eip+0x1d7>
f0102e39:	eb 1c                	jmp    f0102e57 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102e3b:	c7 44 24 08 62 4c 10 	movl   $0xf0104c62,0x8(%esp)
f0102e42:	f0 
f0102e43:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102e4a:	00 
f0102e4b:	c7 04 24 6f 4c 10 f0 	movl   $0xf0104c6f,(%esp)
f0102e52:	e8 3d d2 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e57:	80 3d 94 c8 10 f0 00 	cmpb   $0x0,0xf010c894
f0102e5e:	0f 85 67 01 00 00    	jne    f0102fcb <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102e64:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102e6b:	b8 68 ab 10 f0       	mov    $0xf010ab68,%eax
f0102e70:	2d 8c 4e 10 f0       	sub    $0xf0104e8c,%eax
f0102e75:	c1 f8 02             	sar    $0x2,%eax
f0102e78:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102e7e:	83 e8 01             	sub    $0x1,%eax
f0102e81:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102e84:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102e88:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102e8f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102e92:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102e95:	b8 8c 4e 10 f0       	mov    $0xf0104e8c,%eax
f0102e9a:	e8 71 fe ff ff       	call   f0102d10 <stab_binsearch>
	if (lfile == 0)
f0102e9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ea2:	85 c0                	test   %eax,%eax
f0102ea4:	0f 84 28 01 00 00    	je     f0102fd2 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102eaa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102ead:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102eb0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102eb3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102eb7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102ebe:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102ec1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102ec4:	b8 8c 4e 10 f0       	mov    $0xf0104e8c,%eax
f0102ec9:	e8 42 fe ff ff       	call   f0102d10 <stab_binsearch>

	if (lfun <= rfun) {
f0102ece:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102ed1:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102ed4:	7f 2e                	jg     f0102f04 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102ed6:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102ed9:	8d 90 8c 4e 10 f0    	lea    -0xfefb174(%eax),%edx
f0102edf:	8b 80 8c 4e 10 f0    	mov    -0xfefb174(%eax),%eax
f0102ee5:	b9 95 c8 10 f0       	mov    $0xf010c895,%ecx
f0102eea:	81 e9 69 ab 10 f0    	sub    $0xf010ab69,%ecx
f0102ef0:	39 c8                	cmp    %ecx,%eax
f0102ef2:	73 08                	jae    f0102efc <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102ef4:	05 69 ab 10 f0       	add    $0xf010ab69,%eax
f0102ef9:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102efc:	8b 42 08             	mov    0x8(%edx),%eax
f0102eff:	89 43 10             	mov    %eax,0x10(%ebx)
f0102f02:	eb 06                	jmp    f0102f0a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f04:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f0a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f11:	00 
f0102f12:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f15:	89 04 24             	mov    %eax,(%esp)
f0102f18:	e8 47 09 00 00       	call   f0103864 <strfind>
f0102f1d:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f20:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f23:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102f26:	39 cf                	cmp    %ecx,%edi
f0102f28:	7c 5c                	jl     f0102f86 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0102f2a:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102f2d:	8d b0 8c 4e 10 f0    	lea    -0xfefb174(%eax),%esi
f0102f33:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0102f37:	80 fa 84             	cmp    $0x84,%dl
f0102f3a:	74 2b                	je     f0102f67 <debuginfo_eip+0x17a>
f0102f3c:	05 80 4e 10 f0       	add    $0xf0104e80,%eax
f0102f41:	eb 15                	jmp    f0102f58 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102f43:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f46:	39 cf                	cmp    %ecx,%edi
f0102f48:	7c 3c                	jl     f0102f86 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0102f4a:	89 c6                	mov    %eax,%esi
f0102f4c:	83 e8 0c             	sub    $0xc,%eax
f0102f4f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0102f53:	80 fa 84             	cmp    $0x84,%dl
f0102f56:	74 0f                	je     f0102f67 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102f58:	80 fa 64             	cmp    $0x64,%dl
f0102f5b:	75 e6                	jne    f0102f43 <debuginfo_eip+0x156>
f0102f5d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0102f61:	74 e0                	je     f0102f43 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102f63:	39 f9                	cmp    %edi,%ecx
f0102f65:	7f 1f                	jg     f0102f86 <debuginfo_eip+0x199>
f0102f67:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102f6a:	8b 87 8c 4e 10 f0    	mov    -0xfefb174(%edi),%eax
f0102f70:	ba 95 c8 10 f0       	mov    $0xf010c895,%edx
f0102f75:	81 ea 69 ab 10 f0    	sub    $0xf010ab69,%edx
f0102f7b:	39 d0                	cmp    %edx,%eax
f0102f7d:	73 07                	jae    f0102f86 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102f7f:	05 69 ab 10 f0       	add    $0xf010ab69,%eax
f0102f84:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102f86:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102f89:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102f8c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102f91:	39 ca                	cmp    %ecx,%edx
f0102f93:	7d 5e                	jge    f0102ff3 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0102f95:	8d 42 01             	lea    0x1(%edx),%eax
f0102f98:	39 c1                	cmp    %eax,%ecx
f0102f9a:	7e 3d                	jle    f0102fd9 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102f9c:	6b d0 0c             	imul   $0xc,%eax,%edx
f0102f9f:	80 ba 90 4e 10 f0 a0 	cmpb   $0xa0,-0xfefb170(%edx)
f0102fa6:	75 38                	jne    f0102fe0 <debuginfo_eip+0x1f3>
f0102fa8:	81 c2 80 4e 10 f0    	add    $0xf0104e80,%edx
		     lline++)
			info->eip_fn_narg++;
f0102fae:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102fb2:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102fb5:	39 c1                	cmp    %eax,%ecx
f0102fb7:	7e 2e                	jle    f0102fe7 <debuginfo_eip+0x1fa>
f0102fb9:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102fbc:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0102fc0:	74 ec                	je     f0102fae <debuginfo_eip+0x1c1>
f0102fc2:	eb 2a                	jmp    f0102fee <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102fc4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102fc9:	eb 28                	jmp    f0102ff3 <debuginfo_eip+0x206>
f0102fcb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102fd0:	eb 21                	jmp    f0102ff3 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102fd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102fd7:	eb 1a                	jmp    f0102ff3 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102fd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fde:	eb 13                	jmp    f0102ff3 <debuginfo_eip+0x206>
f0102fe0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fe5:	eb 0c                	jmp    f0102ff3 <debuginfo_eip+0x206>
f0102fe7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fec:	eb 05                	jmp    f0102ff3 <debuginfo_eip+0x206>
f0102fee:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102ff3:	83 c4 2c             	add    $0x2c,%esp
f0102ff6:	5b                   	pop    %ebx
f0102ff7:	5e                   	pop    %esi
f0102ff8:	5f                   	pop    %edi
f0102ff9:	5d                   	pop    %ebp
f0102ffa:	c3                   	ret    
f0102ffb:	66 90                	xchg   %ax,%ax
f0102ffd:	66 90                	xchg   %ax,%ax
f0102fff:	90                   	nop

f0103000 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103000:	55                   	push   %ebp
f0103001:	89 e5                	mov    %esp,%ebp
f0103003:	57                   	push   %edi
f0103004:	56                   	push   %esi
f0103005:	53                   	push   %ebx
f0103006:	83 ec 3c             	sub    $0x3c,%esp
f0103009:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010300c:	89 d7                	mov    %edx,%edi
f010300e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103011:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103014:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103017:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010301a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010301d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103022:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103025:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103028:	39 f1                	cmp    %esi,%ecx
f010302a:	72 14                	jb     f0103040 <printnum+0x40>
f010302c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f010302f:	76 0f                	jbe    f0103040 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103031:	8b 45 14             	mov    0x14(%ebp),%eax
f0103034:	8d 70 ff             	lea    -0x1(%eax),%esi
f0103037:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010303a:	85 f6                	test   %esi,%esi
f010303c:	7f 60                	jg     f010309e <printnum+0x9e>
f010303e:	eb 72                	jmp    f01030b2 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103040:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103043:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103047:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010304a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f010304d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103051:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103055:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103059:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010305d:	89 c3                	mov    %eax,%ebx
f010305f:	89 d6                	mov    %edx,%esi
f0103061:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103064:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103067:	89 54 24 08          	mov    %edx,0x8(%esp)
f010306b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010306f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103072:	89 04 24             	mov    %eax,(%esp)
f0103075:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103078:	89 44 24 04          	mov    %eax,0x4(%esp)
f010307c:	e8 4f 0a 00 00       	call   f0103ad0 <__udivdi3>
f0103081:	89 d9                	mov    %ebx,%ecx
f0103083:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103087:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010308b:	89 04 24             	mov    %eax,(%esp)
f010308e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103092:	89 fa                	mov    %edi,%edx
f0103094:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103097:	e8 64 ff ff ff       	call   f0103000 <printnum>
f010309c:	eb 14                	jmp    f01030b2 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010309e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030a2:	8b 45 18             	mov    0x18(%ebp),%eax
f01030a5:	89 04 24             	mov    %eax,(%esp)
f01030a8:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01030aa:	83 ee 01             	sub    $0x1,%esi
f01030ad:	75 ef                	jne    f010309e <printnum+0x9e>
f01030af:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01030b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030b6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01030ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01030bd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01030c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030c4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01030c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030cb:	89 04 24             	mov    %eax,(%esp)
f01030ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030d5:	e8 26 0b 00 00       	call   f0103c00 <__umoddi3>
f01030da:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030de:	0f be 80 7d 4c 10 f0 	movsbl -0xfefb383(%eax),%eax
f01030e5:	89 04 24             	mov    %eax,(%esp)
f01030e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030eb:	ff d0                	call   *%eax
}
f01030ed:	83 c4 3c             	add    $0x3c,%esp
f01030f0:	5b                   	pop    %ebx
f01030f1:	5e                   	pop    %esi
f01030f2:	5f                   	pop    %edi
f01030f3:	5d                   	pop    %ebp
f01030f4:	c3                   	ret    

f01030f5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01030f5:	55                   	push   %ebp
f01030f6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01030f8:	83 fa 01             	cmp    $0x1,%edx
f01030fb:	7e 0e                	jle    f010310b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01030fd:	8b 10                	mov    (%eax),%edx
f01030ff:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103102:	89 08                	mov    %ecx,(%eax)
f0103104:	8b 02                	mov    (%edx),%eax
f0103106:	8b 52 04             	mov    0x4(%edx),%edx
f0103109:	eb 22                	jmp    f010312d <getuint+0x38>
	else if (lflag)
f010310b:	85 d2                	test   %edx,%edx
f010310d:	74 10                	je     f010311f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010310f:	8b 10                	mov    (%eax),%edx
f0103111:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103114:	89 08                	mov    %ecx,(%eax)
f0103116:	8b 02                	mov    (%edx),%eax
f0103118:	ba 00 00 00 00       	mov    $0x0,%edx
f010311d:	eb 0e                	jmp    f010312d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010311f:	8b 10                	mov    (%eax),%edx
f0103121:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103124:	89 08                	mov    %ecx,(%eax)
f0103126:	8b 02                	mov    (%edx),%eax
f0103128:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010312d:	5d                   	pop    %ebp
f010312e:	c3                   	ret    

f010312f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010312f:	55                   	push   %ebp
f0103130:	89 e5                	mov    %esp,%ebp
f0103132:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103135:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103139:	8b 10                	mov    (%eax),%edx
f010313b:	3b 50 04             	cmp    0x4(%eax),%edx
f010313e:	73 0a                	jae    f010314a <sprintputch+0x1b>
		*b->buf++ = ch;
f0103140:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103143:	89 08                	mov    %ecx,(%eax)
f0103145:	8b 45 08             	mov    0x8(%ebp),%eax
f0103148:	88 02                	mov    %al,(%edx)
}
f010314a:	5d                   	pop    %ebp
f010314b:	c3                   	ret    

f010314c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010314c:	55                   	push   %ebp
f010314d:	89 e5                	mov    %esp,%ebp
f010314f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103152:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103155:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103159:	8b 45 10             	mov    0x10(%ebp),%eax
f010315c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103160:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103163:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103167:	8b 45 08             	mov    0x8(%ebp),%eax
f010316a:	89 04 24             	mov    %eax,(%esp)
f010316d:	e8 02 00 00 00       	call   f0103174 <vprintfmt>
	va_end(ap);
}
f0103172:	c9                   	leave  
f0103173:	c3                   	ret    

f0103174 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103174:	55                   	push   %ebp
f0103175:	89 e5                	mov    %esp,%ebp
f0103177:	57                   	push   %edi
f0103178:	56                   	push   %esi
f0103179:	53                   	push   %ebx
f010317a:	83 ec 3c             	sub    $0x3c,%esp
f010317d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103180:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103183:	eb 1b                	jmp    f01031a0 <vprintfmt+0x2c>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103185:	85 c0                	test   %eax,%eax
f0103187:	0f 84 c6 03 00 00    	je     f0103553 <vprintfmt+0x3df>
				return;
			putch(ch | 0x0200, putdat);
f010318d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103191:	80 cc 02             	or     $0x2,%ah
f0103194:	89 04 24             	mov    %eax,(%esp)
f0103197:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010319a:	89 f3                	mov    %esi,%ebx
f010319c:	eb 02                	jmp    f01031a0 <vprintfmt+0x2c>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f010319e:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01031a0:	8d 73 01             	lea    0x1(%ebx),%esi
f01031a3:	0f b6 03             	movzbl (%ebx),%eax
f01031a6:	83 f8 25             	cmp    $0x25,%eax
f01031a9:	75 da                	jne    f0103185 <vprintfmt+0x11>
f01031ab:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f01031af:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01031b6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01031bd:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01031c4:	ba 00 00 00 00       	mov    $0x0,%edx
f01031c9:	eb 1d                	jmp    f01031e8 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031cb:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01031cd:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f01031d1:	eb 15                	jmp    f01031e8 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031d3:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01031d5:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f01031d9:	eb 0d                	jmp    f01031e8 <vprintfmt+0x74>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01031db:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031de:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01031e1:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031e8:	8d 5e 01             	lea    0x1(%esi),%ebx
f01031eb:	0f b6 06             	movzbl (%esi),%eax
f01031ee:	0f b6 c8             	movzbl %al,%ecx
f01031f1:	83 e8 23             	sub    $0x23,%eax
f01031f4:	3c 55                	cmp    $0x55,%al
f01031f6:	0f 87 2f 03 00 00    	ja     f010352b <vprintfmt+0x3b7>
f01031fc:	0f b6 c0             	movzbl %al,%eax
f01031ff:	ff 24 85 08 4d 10 f0 	jmp    *-0xfefb2f8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103206:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0103209:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f010320c:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0103210:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0103213:	83 f9 09             	cmp    $0x9,%ecx
f0103216:	77 50                	ja     f0103268 <vprintfmt+0xf4>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103218:	89 de                	mov    %ebx,%esi
f010321a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010321d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0103220:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103223:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103227:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010322a:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010322d:	83 fb 09             	cmp    $0x9,%ebx
f0103230:	76 eb                	jbe    f010321d <vprintfmt+0xa9>
f0103232:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103235:	eb 33                	jmp    f010326a <vprintfmt+0xf6>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103237:	8b 45 14             	mov    0x14(%ebp),%eax
f010323a:	8d 48 04             	lea    0x4(%eax),%ecx
f010323d:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103240:	8b 00                	mov    (%eax),%eax
f0103242:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103245:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103247:	eb 21                	jmp    f010326a <vprintfmt+0xf6>
f0103249:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010324c:	85 c9                	test   %ecx,%ecx
f010324e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103253:	0f 49 c1             	cmovns %ecx,%eax
f0103256:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103259:	89 de                	mov    %ebx,%esi
f010325b:	eb 8b                	jmp    f01031e8 <vprintfmt+0x74>
f010325d:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010325f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103266:	eb 80                	jmp    f01031e8 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103268:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010326a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010326e:	0f 89 74 ff ff ff    	jns    f01031e8 <vprintfmt+0x74>
f0103274:	e9 62 ff ff ff       	jmp    f01031db <vprintfmt+0x67>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103279:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010327c:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010327e:	e9 65 ff ff ff       	jmp    f01031e8 <vprintfmt+0x74>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103283:	8b 45 14             	mov    0x14(%ebp),%eax
f0103286:	8d 50 04             	lea    0x4(%eax),%edx
f0103289:	89 55 14             	mov    %edx,0x14(%ebp)
f010328c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103290:	8b 00                	mov    (%eax),%eax
f0103292:	89 04 24             	mov    %eax,(%esp)
f0103295:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103298:	e9 03 ff ff ff       	jmp    f01031a0 <vprintfmt+0x2c>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010329d:	8b 45 14             	mov    0x14(%ebp),%eax
f01032a0:	8d 50 04             	lea    0x4(%eax),%edx
f01032a3:	89 55 14             	mov    %edx,0x14(%ebp)
f01032a6:	8b 00                	mov    (%eax),%eax
f01032a8:	99                   	cltd   
f01032a9:	31 d0                	xor    %edx,%eax
f01032ab:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01032ad:	83 f8 06             	cmp    $0x6,%eax
f01032b0:	7f 0b                	jg     f01032bd <vprintfmt+0x149>
f01032b2:	8b 14 85 60 4e 10 f0 	mov    -0xfefb1a0(,%eax,4),%edx
f01032b9:	85 d2                	test   %edx,%edx
f01032bb:	75 20                	jne    f01032dd <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
f01032bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032c1:	c7 44 24 08 95 4c 10 	movl   $0xf0104c95,0x8(%esp)
f01032c8:	f0 
f01032c9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01032d0:	89 04 24             	mov    %eax,(%esp)
f01032d3:	e8 74 fe ff ff       	call   f010314c <printfmt>
f01032d8:	e9 c3 fe ff ff       	jmp    f01031a0 <vprintfmt+0x2c>
			else
				printfmt(putch, putdat, "%s", p);
f01032dd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01032e1:	c7 44 24 08 70 42 10 	movl   $0xf0104270,0x8(%esp)
f01032e8:	f0 
f01032e9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01032f0:	89 04 24             	mov    %eax,(%esp)
f01032f3:	e8 54 fe ff ff       	call   f010314c <printfmt>
f01032f8:	e9 a3 fe ff ff       	jmp    f01031a0 <vprintfmt+0x2c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032fd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103300:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103303:	8b 45 14             	mov    0x14(%ebp),%eax
f0103306:	8d 50 04             	lea    0x4(%eax),%edx
f0103309:	89 55 14             	mov    %edx,0x14(%ebp)
f010330c:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f010330e:	85 c0                	test   %eax,%eax
f0103310:	ba 8e 4c 10 f0       	mov    $0xf0104c8e,%edx
f0103315:	0f 45 d0             	cmovne %eax,%edx
f0103318:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f010331b:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f010331f:	74 04                	je     f0103325 <vprintfmt+0x1b1>
f0103321:	85 f6                	test   %esi,%esi
f0103323:	7f 19                	jg     f010333e <vprintfmt+0x1ca>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103325:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103328:	8d 70 01             	lea    0x1(%eax),%esi
f010332b:	0f b6 10             	movzbl (%eax),%edx
f010332e:	0f be c2             	movsbl %dl,%eax
f0103331:	85 c0                	test   %eax,%eax
f0103333:	0f 85 95 00 00 00    	jne    f01033ce <vprintfmt+0x25a>
f0103339:	e9 85 00 00 00       	jmp    f01033c3 <vprintfmt+0x24f>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010333e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103342:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103345:	89 04 24             	mov    %eax,(%esp)
f0103348:	e8 85 03 00 00       	call   f01036d2 <strnlen>
f010334d:	29 c6                	sub    %eax,%esi
f010334f:	89 f0                	mov    %esi,%eax
f0103351:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103354:	85 f6                	test   %esi,%esi
f0103356:	7e cd                	jle    f0103325 <vprintfmt+0x1b1>
					putch(padc, putdat);
f0103358:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f010335c:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010335f:	89 c3                	mov    %eax,%ebx
f0103361:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103365:	89 34 24             	mov    %esi,(%esp)
f0103368:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010336b:	83 eb 01             	sub    $0x1,%ebx
f010336e:	75 f1                	jne    f0103361 <vprintfmt+0x1ed>
f0103370:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103373:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103376:	eb ad                	jmp    f0103325 <vprintfmt+0x1b1>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103378:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010337c:	74 1e                	je     f010339c <vprintfmt+0x228>
f010337e:	0f be d2             	movsbl %dl,%edx
f0103381:	83 ea 20             	sub    $0x20,%edx
f0103384:	83 fa 5e             	cmp    $0x5e,%edx
f0103387:	76 13                	jbe    f010339c <vprintfmt+0x228>
					putch('?', putdat);
f0103389:	8b 45 0c             	mov    0xc(%ebp),%eax
f010338c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103390:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103397:	ff 55 08             	call   *0x8(%ebp)
f010339a:	eb 0d                	jmp    f01033a9 <vprintfmt+0x235>
				else
					putch(ch, putdat);
f010339c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010339f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01033a3:	89 04 24             	mov    %eax,(%esp)
f01033a6:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01033a9:	83 ef 01             	sub    $0x1,%edi
f01033ac:	83 c6 01             	add    $0x1,%esi
f01033af:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01033b3:	0f be c2             	movsbl %dl,%eax
f01033b6:	85 c0                	test   %eax,%eax
f01033b8:	75 20                	jne    f01033da <vprintfmt+0x266>
f01033ba:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01033bd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01033c0:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01033c3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01033c7:	7f 25                	jg     f01033ee <vprintfmt+0x27a>
f01033c9:	e9 d2 fd ff ff       	jmp    f01031a0 <vprintfmt+0x2c>
f01033ce:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01033d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01033d4:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01033d7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01033da:	85 db                	test   %ebx,%ebx
f01033dc:	78 9a                	js     f0103378 <vprintfmt+0x204>
f01033de:	83 eb 01             	sub    $0x1,%ebx
f01033e1:	79 95                	jns    f0103378 <vprintfmt+0x204>
f01033e3:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01033e6:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01033e9:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01033ec:	eb d5                	jmp    f01033c3 <vprintfmt+0x24f>
f01033ee:	8b 75 08             	mov    0x8(%ebp),%esi
f01033f1:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01033f4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01033f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033fb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103402:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103404:	83 eb 01             	sub    $0x1,%ebx
f0103407:	75 ee                	jne    f01033f7 <vprintfmt+0x283>
f0103409:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010340c:	e9 8f fd ff ff       	jmp    f01031a0 <vprintfmt+0x2c>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103411:	83 fa 01             	cmp    $0x1,%edx
f0103414:	7e 16                	jle    f010342c <vprintfmt+0x2b8>
		return va_arg(*ap, long long);
f0103416:	8b 45 14             	mov    0x14(%ebp),%eax
f0103419:	8d 50 08             	lea    0x8(%eax),%edx
f010341c:	89 55 14             	mov    %edx,0x14(%ebp)
f010341f:	8b 50 04             	mov    0x4(%eax),%edx
f0103422:	8b 00                	mov    (%eax),%eax
f0103424:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103427:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010342a:	eb 32                	jmp    f010345e <vprintfmt+0x2ea>
	else if (lflag)
f010342c:	85 d2                	test   %edx,%edx
f010342e:	74 18                	je     f0103448 <vprintfmt+0x2d4>
		return va_arg(*ap, long);
f0103430:	8b 45 14             	mov    0x14(%ebp),%eax
f0103433:	8d 50 04             	lea    0x4(%eax),%edx
f0103436:	89 55 14             	mov    %edx,0x14(%ebp)
f0103439:	8b 30                	mov    (%eax),%esi
f010343b:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010343e:	89 f0                	mov    %esi,%eax
f0103440:	c1 f8 1f             	sar    $0x1f,%eax
f0103443:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103446:	eb 16                	jmp    f010345e <vprintfmt+0x2ea>
	else
		return va_arg(*ap, int);
f0103448:	8b 45 14             	mov    0x14(%ebp),%eax
f010344b:	8d 50 04             	lea    0x4(%eax),%edx
f010344e:	89 55 14             	mov    %edx,0x14(%ebp)
f0103451:	8b 30                	mov    (%eax),%esi
f0103453:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0103456:	89 f0                	mov    %esi,%eax
f0103458:	c1 f8 1f             	sar    $0x1f,%eax
f010345b:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010345e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103461:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103464:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103469:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010346d:	0f 89 80 00 00 00    	jns    f01034f3 <vprintfmt+0x37f>
				putch('-', putdat);
f0103473:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103477:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010347e:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103481:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103484:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103487:	f7 d8                	neg    %eax
f0103489:	83 d2 00             	adc    $0x0,%edx
f010348c:	f7 da                	neg    %edx
			}
			base = 10;
f010348e:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103493:	eb 5e                	jmp    f01034f3 <vprintfmt+0x37f>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103495:	8d 45 14             	lea    0x14(%ebp),%eax
f0103498:	e8 58 fc ff ff       	call   f01030f5 <getuint>
			base = 10;
f010349d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01034a2:	eb 4f                	jmp    f01034f3 <vprintfmt+0x37f>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01034a4:	8d 45 14             	lea    0x14(%ebp),%eax
f01034a7:	e8 49 fc ff ff       	call   f01030f5 <getuint>
			base = 8;
f01034ac:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01034b1:	eb 40                	jmp    f01034f3 <vprintfmt+0x37f>

		// pointer
		case 'p':
			putch('0', putdat);
f01034b3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034b7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01034be:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01034c1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034c5:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01034cc:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01034cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01034d2:	8d 50 04             	lea    0x4(%eax),%edx
f01034d5:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01034d8:	8b 00                	mov    (%eax),%eax
f01034da:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01034df:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01034e4:	eb 0d                	jmp    f01034f3 <vprintfmt+0x37f>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01034e6:	8d 45 14             	lea    0x14(%ebp),%eax
f01034e9:	e8 07 fc ff ff       	call   f01030f5 <getuint>
			base = 16;
f01034ee:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01034f3:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01034f7:	89 74 24 10          	mov    %esi,0x10(%esp)
f01034fb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01034fe:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103502:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103506:	89 04 24             	mov    %eax,(%esp)
f0103509:	89 54 24 04          	mov    %edx,0x4(%esp)
f010350d:	89 fa                	mov    %edi,%edx
f010350f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103512:	e8 e9 fa ff ff       	call   f0103000 <printnum>
			break;
f0103517:	e9 84 fc ff ff       	jmp    f01031a0 <vprintfmt+0x2c>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010351c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103520:	89 0c 24             	mov    %ecx,(%esp)
f0103523:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103526:	e9 75 fc ff ff       	jmp    f01031a0 <vprintfmt+0x2c>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010352b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010352f:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103536:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103539:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010353d:	0f 84 5b fc ff ff    	je     f010319e <vprintfmt+0x2a>
f0103543:	89 f3                	mov    %esi,%ebx
f0103545:	83 eb 01             	sub    $0x1,%ebx
f0103548:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010354c:	75 f7                	jne    f0103545 <vprintfmt+0x3d1>
f010354e:	e9 4d fc ff ff       	jmp    f01031a0 <vprintfmt+0x2c>
				/* do nothing */;
			break;
		}
	}
}
f0103553:	83 c4 3c             	add    $0x3c,%esp
f0103556:	5b                   	pop    %ebx
f0103557:	5e                   	pop    %esi
f0103558:	5f                   	pop    %edi
f0103559:	5d                   	pop    %ebp
f010355a:	c3                   	ret    

f010355b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010355b:	55                   	push   %ebp
f010355c:	89 e5                	mov    %esp,%ebp
f010355e:	83 ec 28             	sub    $0x28,%esp
f0103561:	8b 45 08             	mov    0x8(%ebp),%eax
f0103564:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103567:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010356a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010356e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103571:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103578:	85 c0                	test   %eax,%eax
f010357a:	74 30                	je     f01035ac <vsnprintf+0x51>
f010357c:	85 d2                	test   %edx,%edx
f010357e:	7e 2c                	jle    f01035ac <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103580:	8b 45 14             	mov    0x14(%ebp),%eax
f0103583:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103587:	8b 45 10             	mov    0x10(%ebp),%eax
f010358a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010358e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103591:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103595:	c7 04 24 2f 31 10 f0 	movl   $0xf010312f,(%esp)
f010359c:	e8 d3 fb ff ff       	call   f0103174 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01035a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035a4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01035a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01035aa:	eb 05                	jmp    f01035b1 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01035ac:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01035b1:	c9                   	leave  
f01035b2:	c3                   	ret    

f01035b3 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01035b3:	55                   	push   %ebp
f01035b4:	89 e5                	mov    %esp,%ebp
f01035b6:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01035b9:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01035bc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035c0:	8b 45 10             	mov    0x10(%ebp),%eax
f01035c3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035c7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01035d1:	89 04 24             	mov    %eax,(%esp)
f01035d4:	e8 82 ff ff ff       	call   f010355b <vsnprintf>
	va_end(ap);

	return rc;
}
f01035d9:	c9                   	leave  
f01035da:	c3                   	ret    
f01035db:	66 90                	xchg   %ax,%ax
f01035dd:	66 90                	xchg   %ax,%ax
f01035df:	90                   	nop

f01035e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01035e0:	55                   	push   %ebp
f01035e1:	89 e5                	mov    %esp,%ebp
f01035e3:	57                   	push   %edi
f01035e4:	56                   	push   %esi
f01035e5:	53                   	push   %ebx
f01035e6:	83 ec 1c             	sub    $0x1c,%esp
f01035e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01035ec:	85 c0                	test   %eax,%eax
f01035ee:	74 10                	je     f0103600 <readline+0x20>
		cprintf("%s", prompt);
f01035f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035f4:	c7 04 24 70 42 10 f0 	movl   $0xf0104270,(%esp)
f01035fb:	e8 ec f6 ff ff       	call   f0102cec <cprintf>

	i = 0;
	echoing = iscons(0);
f0103600:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103607:	e8 02 d0 ff ff       	call   f010060e <iscons>
f010360c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010360e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103613:	e8 e5 cf ff ff       	call   f01005fd <getchar>
f0103618:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010361a:	85 c0                	test   %eax,%eax
f010361c:	79 17                	jns    f0103635 <readline+0x55>
			cprintf("read error: %e\n", c);
f010361e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103622:	c7 04 24 7c 4e 10 f0 	movl   $0xf0104e7c,(%esp)
f0103629:	e8 be f6 ff ff       	call   f0102cec <cprintf>
			return NULL;
f010362e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103633:	eb 6d                	jmp    f01036a2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103635:	83 f8 7f             	cmp    $0x7f,%eax
f0103638:	74 05                	je     f010363f <readline+0x5f>
f010363a:	83 f8 08             	cmp    $0x8,%eax
f010363d:	75 19                	jne    f0103658 <readline+0x78>
f010363f:	85 f6                	test   %esi,%esi
f0103641:	7e 15                	jle    f0103658 <readline+0x78>
			if (echoing)
f0103643:	85 ff                	test   %edi,%edi
f0103645:	74 0c                	je     f0103653 <readline+0x73>
				cputchar('\b');
f0103647:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010364e:	e8 9a cf ff ff       	call   f01005ed <cputchar>
			i--;
f0103653:	83 ee 01             	sub    $0x1,%esi
f0103656:	eb bb                	jmp    f0103613 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103658:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010365e:	7f 1c                	jg     f010367c <readline+0x9c>
f0103660:	83 fb 1f             	cmp    $0x1f,%ebx
f0103663:	7e 17                	jle    f010367c <readline+0x9c>
			if (echoing)
f0103665:	85 ff                	test   %edi,%edi
f0103667:	74 08                	je     f0103671 <readline+0x91>
				cputchar(c);
f0103669:	89 1c 24             	mov    %ebx,(%esp)
f010366c:	e8 7c cf ff ff       	call   f01005ed <cputchar>
			buf[i++] = c;
f0103671:	88 9e 80 75 11 f0    	mov    %bl,-0xfee8a80(%esi)
f0103677:	8d 76 01             	lea    0x1(%esi),%esi
f010367a:	eb 97                	jmp    f0103613 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010367c:	83 fb 0d             	cmp    $0xd,%ebx
f010367f:	74 05                	je     f0103686 <readline+0xa6>
f0103681:	83 fb 0a             	cmp    $0xa,%ebx
f0103684:	75 8d                	jne    f0103613 <readline+0x33>
			if (echoing)
f0103686:	85 ff                	test   %edi,%edi
f0103688:	74 0c                	je     f0103696 <readline+0xb6>
				cputchar('\n');
f010368a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103691:	e8 57 cf ff ff       	call   f01005ed <cputchar>
			buf[i] = 0;
f0103696:	c6 86 80 75 11 f0 00 	movb   $0x0,-0xfee8a80(%esi)
			return buf;
f010369d:	b8 80 75 11 f0       	mov    $0xf0117580,%eax
		}
	}
}
f01036a2:	83 c4 1c             	add    $0x1c,%esp
f01036a5:	5b                   	pop    %ebx
f01036a6:	5e                   	pop    %esi
f01036a7:	5f                   	pop    %edi
f01036a8:	5d                   	pop    %ebp
f01036a9:	c3                   	ret    
f01036aa:	66 90                	xchg   %ax,%ax
f01036ac:	66 90                	xchg   %ax,%ax
f01036ae:	66 90                	xchg   %ax,%ax

f01036b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01036b0:	55                   	push   %ebp
f01036b1:	89 e5                	mov    %esp,%ebp
f01036b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01036b6:	80 3a 00             	cmpb   $0x0,(%edx)
f01036b9:	74 10                	je     f01036cb <strlen+0x1b>
f01036bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01036c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01036c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01036c7:	75 f7                	jne    f01036c0 <strlen+0x10>
f01036c9:	eb 05                	jmp    f01036d0 <strlen+0x20>
f01036cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01036d0:	5d                   	pop    %ebp
f01036d1:	c3                   	ret    

f01036d2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01036d2:	55                   	push   %ebp
f01036d3:	89 e5                	mov    %esp,%ebp
f01036d5:	53                   	push   %ebx
f01036d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01036d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01036dc:	85 c9                	test   %ecx,%ecx
f01036de:	74 1c                	je     f01036fc <strnlen+0x2a>
f01036e0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01036e3:	74 1e                	je     f0103703 <strnlen+0x31>
f01036e5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01036ea:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01036ec:	39 ca                	cmp    %ecx,%edx
f01036ee:	74 18                	je     f0103708 <strnlen+0x36>
f01036f0:	83 c2 01             	add    $0x1,%edx
f01036f3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01036f8:	75 f0                	jne    f01036ea <strnlen+0x18>
f01036fa:	eb 0c                	jmp    f0103708 <strnlen+0x36>
f01036fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0103701:	eb 05                	jmp    f0103708 <strnlen+0x36>
f0103703:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103708:	5b                   	pop    %ebx
f0103709:	5d                   	pop    %ebp
f010370a:	c3                   	ret    

f010370b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010370b:	55                   	push   %ebp
f010370c:	89 e5                	mov    %esp,%ebp
f010370e:	53                   	push   %ebx
f010370f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103712:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103715:	89 c2                	mov    %eax,%edx
f0103717:	83 c2 01             	add    $0x1,%edx
f010371a:	83 c1 01             	add    $0x1,%ecx
f010371d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103721:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103724:	84 db                	test   %bl,%bl
f0103726:	75 ef                	jne    f0103717 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103728:	5b                   	pop    %ebx
f0103729:	5d                   	pop    %ebp
f010372a:	c3                   	ret    

f010372b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010372b:	55                   	push   %ebp
f010372c:	89 e5                	mov    %esp,%ebp
f010372e:	56                   	push   %esi
f010372f:	53                   	push   %ebx
f0103730:	8b 75 08             	mov    0x8(%ebp),%esi
f0103733:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103736:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103739:	85 db                	test   %ebx,%ebx
f010373b:	74 17                	je     f0103754 <strncpy+0x29>
f010373d:	01 f3                	add    %esi,%ebx
f010373f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0103741:	83 c1 01             	add    $0x1,%ecx
f0103744:	0f b6 02             	movzbl (%edx),%eax
f0103747:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010374a:	80 3a 01             	cmpb   $0x1,(%edx)
f010374d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103750:	39 d9                	cmp    %ebx,%ecx
f0103752:	75 ed                	jne    f0103741 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103754:	89 f0                	mov    %esi,%eax
f0103756:	5b                   	pop    %ebx
f0103757:	5e                   	pop    %esi
f0103758:	5d                   	pop    %ebp
f0103759:	c3                   	ret    

f010375a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010375a:	55                   	push   %ebp
f010375b:	89 e5                	mov    %esp,%ebp
f010375d:	57                   	push   %edi
f010375e:	56                   	push   %esi
f010375f:	53                   	push   %ebx
f0103760:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103763:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103766:	8b 75 10             	mov    0x10(%ebp),%esi
f0103769:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010376b:	85 f6                	test   %esi,%esi
f010376d:	74 34                	je     f01037a3 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010376f:	83 fe 01             	cmp    $0x1,%esi
f0103772:	74 26                	je     f010379a <strlcpy+0x40>
f0103774:	0f b6 0b             	movzbl (%ebx),%ecx
f0103777:	84 c9                	test   %cl,%cl
f0103779:	74 23                	je     f010379e <strlcpy+0x44>
f010377b:	83 ee 02             	sub    $0x2,%esi
f010377e:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0103783:	83 c0 01             	add    $0x1,%eax
f0103786:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103789:	39 f2                	cmp    %esi,%edx
f010378b:	74 13                	je     f01037a0 <strlcpy+0x46>
f010378d:	83 c2 01             	add    $0x1,%edx
f0103790:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103794:	84 c9                	test   %cl,%cl
f0103796:	75 eb                	jne    f0103783 <strlcpy+0x29>
f0103798:	eb 06                	jmp    f01037a0 <strlcpy+0x46>
f010379a:	89 f8                	mov    %edi,%eax
f010379c:	eb 02                	jmp    f01037a0 <strlcpy+0x46>
f010379e:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01037a0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01037a3:	29 f8                	sub    %edi,%eax
}
f01037a5:	5b                   	pop    %ebx
f01037a6:	5e                   	pop    %esi
f01037a7:	5f                   	pop    %edi
f01037a8:	5d                   	pop    %ebp
f01037a9:	c3                   	ret    

f01037aa <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01037aa:	55                   	push   %ebp
f01037ab:	89 e5                	mov    %esp,%ebp
f01037ad:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01037b0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01037b3:	0f b6 01             	movzbl (%ecx),%eax
f01037b6:	84 c0                	test   %al,%al
f01037b8:	74 15                	je     f01037cf <strcmp+0x25>
f01037ba:	3a 02                	cmp    (%edx),%al
f01037bc:	75 11                	jne    f01037cf <strcmp+0x25>
		p++, q++;
f01037be:	83 c1 01             	add    $0x1,%ecx
f01037c1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01037c4:	0f b6 01             	movzbl (%ecx),%eax
f01037c7:	84 c0                	test   %al,%al
f01037c9:	74 04                	je     f01037cf <strcmp+0x25>
f01037cb:	3a 02                	cmp    (%edx),%al
f01037cd:	74 ef                	je     f01037be <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01037cf:	0f b6 c0             	movzbl %al,%eax
f01037d2:	0f b6 12             	movzbl (%edx),%edx
f01037d5:	29 d0                	sub    %edx,%eax
}
f01037d7:	5d                   	pop    %ebp
f01037d8:	c3                   	ret    

f01037d9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01037d9:	55                   	push   %ebp
f01037da:	89 e5                	mov    %esp,%ebp
f01037dc:	56                   	push   %esi
f01037dd:	53                   	push   %ebx
f01037de:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01037e1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037e4:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01037e7:	85 f6                	test   %esi,%esi
f01037e9:	74 29                	je     f0103814 <strncmp+0x3b>
f01037eb:	0f b6 03             	movzbl (%ebx),%eax
f01037ee:	84 c0                	test   %al,%al
f01037f0:	74 30                	je     f0103822 <strncmp+0x49>
f01037f2:	3a 02                	cmp    (%edx),%al
f01037f4:	75 2c                	jne    f0103822 <strncmp+0x49>
f01037f6:	8d 43 01             	lea    0x1(%ebx),%eax
f01037f9:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f01037fb:	89 c3                	mov    %eax,%ebx
f01037fd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103800:	39 f0                	cmp    %esi,%eax
f0103802:	74 17                	je     f010381b <strncmp+0x42>
f0103804:	0f b6 08             	movzbl (%eax),%ecx
f0103807:	84 c9                	test   %cl,%cl
f0103809:	74 17                	je     f0103822 <strncmp+0x49>
f010380b:	83 c0 01             	add    $0x1,%eax
f010380e:	3a 0a                	cmp    (%edx),%cl
f0103810:	74 e9                	je     f01037fb <strncmp+0x22>
f0103812:	eb 0e                	jmp    f0103822 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103814:	b8 00 00 00 00       	mov    $0x0,%eax
f0103819:	eb 0f                	jmp    f010382a <strncmp+0x51>
f010381b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103820:	eb 08                	jmp    f010382a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103822:	0f b6 03             	movzbl (%ebx),%eax
f0103825:	0f b6 12             	movzbl (%edx),%edx
f0103828:	29 d0                	sub    %edx,%eax
}
f010382a:	5b                   	pop    %ebx
f010382b:	5e                   	pop    %esi
f010382c:	5d                   	pop    %ebp
f010382d:	c3                   	ret    

f010382e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010382e:	55                   	push   %ebp
f010382f:	89 e5                	mov    %esp,%ebp
f0103831:	53                   	push   %ebx
f0103832:	8b 45 08             	mov    0x8(%ebp),%eax
f0103835:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0103838:	0f b6 18             	movzbl (%eax),%ebx
f010383b:	84 db                	test   %bl,%bl
f010383d:	74 1d                	je     f010385c <strchr+0x2e>
f010383f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0103841:	38 d3                	cmp    %dl,%bl
f0103843:	75 06                	jne    f010384b <strchr+0x1d>
f0103845:	eb 1a                	jmp    f0103861 <strchr+0x33>
f0103847:	38 ca                	cmp    %cl,%dl
f0103849:	74 16                	je     f0103861 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010384b:	83 c0 01             	add    $0x1,%eax
f010384e:	0f b6 10             	movzbl (%eax),%edx
f0103851:	84 d2                	test   %dl,%dl
f0103853:	75 f2                	jne    f0103847 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0103855:	b8 00 00 00 00       	mov    $0x0,%eax
f010385a:	eb 05                	jmp    f0103861 <strchr+0x33>
f010385c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103861:	5b                   	pop    %ebx
f0103862:	5d                   	pop    %ebp
f0103863:	c3                   	ret    

f0103864 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103864:	55                   	push   %ebp
f0103865:	89 e5                	mov    %esp,%ebp
f0103867:	53                   	push   %ebx
f0103868:	8b 45 08             	mov    0x8(%ebp),%eax
f010386b:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010386e:	0f b6 18             	movzbl (%eax),%ebx
f0103871:	84 db                	test   %bl,%bl
f0103873:	74 17                	je     f010388c <strfind+0x28>
f0103875:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0103877:	38 d3                	cmp    %dl,%bl
f0103879:	75 07                	jne    f0103882 <strfind+0x1e>
f010387b:	eb 0f                	jmp    f010388c <strfind+0x28>
f010387d:	38 ca                	cmp    %cl,%dl
f010387f:	90                   	nop
f0103880:	74 0a                	je     f010388c <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103882:	83 c0 01             	add    $0x1,%eax
f0103885:	0f b6 10             	movzbl (%eax),%edx
f0103888:	84 d2                	test   %dl,%dl
f010388a:	75 f1                	jne    f010387d <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010388c:	5b                   	pop    %ebx
f010388d:	5d                   	pop    %ebp
f010388e:	c3                   	ret    

f010388f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010388f:	55                   	push   %ebp
f0103890:	89 e5                	mov    %esp,%ebp
f0103892:	57                   	push   %edi
f0103893:	56                   	push   %esi
f0103894:	53                   	push   %ebx
f0103895:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103898:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010389b:	85 c9                	test   %ecx,%ecx
f010389d:	74 36                	je     f01038d5 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010389f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01038a5:	75 28                	jne    f01038cf <memset+0x40>
f01038a7:	f6 c1 03             	test   $0x3,%cl
f01038aa:	75 23                	jne    f01038cf <memset+0x40>
		c &= 0xFF;
f01038ac:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01038b0:	89 d3                	mov    %edx,%ebx
f01038b2:	c1 e3 08             	shl    $0x8,%ebx
f01038b5:	89 d6                	mov    %edx,%esi
f01038b7:	c1 e6 18             	shl    $0x18,%esi
f01038ba:	89 d0                	mov    %edx,%eax
f01038bc:	c1 e0 10             	shl    $0x10,%eax
f01038bf:	09 f0                	or     %esi,%eax
f01038c1:	09 c2                	or     %eax,%edx
f01038c3:	89 d0                	mov    %edx,%eax
f01038c5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01038c7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01038ca:	fc                   	cld    
f01038cb:	f3 ab                	rep stos %eax,%es:(%edi)
f01038cd:	eb 06                	jmp    f01038d5 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01038cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038d2:	fc                   	cld    
f01038d3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01038d5:	89 f8                	mov    %edi,%eax
f01038d7:	5b                   	pop    %ebx
f01038d8:	5e                   	pop    %esi
f01038d9:	5f                   	pop    %edi
f01038da:	5d                   	pop    %ebp
f01038db:	c3                   	ret    

f01038dc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01038dc:	55                   	push   %ebp
f01038dd:	89 e5                	mov    %esp,%ebp
f01038df:	57                   	push   %edi
f01038e0:	56                   	push   %esi
f01038e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01038e4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01038e7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01038ea:	39 c6                	cmp    %eax,%esi
f01038ec:	73 35                	jae    f0103923 <memmove+0x47>
f01038ee:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01038f1:	39 d0                	cmp    %edx,%eax
f01038f3:	73 2e                	jae    f0103923 <memmove+0x47>
		s += n;
		d += n;
f01038f5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01038f8:	89 d6                	mov    %edx,%esi
f01038fa:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01038fc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103902:	75 13                	jne    f0103917 <memmove+0x3b>
f0103904:	f6 c1 03             	test   $0x3,%cl
f0103907:	75 0e                	jne    f0103917 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103909:	83 ef 04             	sub    $0x4,%edi
f010390c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010390f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103912:	fd                   	std    
f0103913:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103915:	eb 09                	jmp    f0103920 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103917:	83 ef 01             	sub    $0x1,%edi
f010391a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010391d:	fd                   	std    
f010391e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103920:	fc                   	cld    
f0103921:	eb 1d                	jmp    f0103940 <memmove+0x64>
f0103923:	89 f2                	mov    %esi,%edx
f0103925:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103927:	f6 c2 03             	test   $0x3,%dl
f010392a:	75 0f                	jne    f010393b <memmove+0x5f>
f010392c:	f6 c1 03             	test   $0x3,%cl
f010392f:	75 0a                	jne    f010393b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103931:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103934:	89 c7                	mov    %eax,%edi
f0103936:	fc                   	cld    
f0103937:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103939:	eb 05                	jmp    f0103940 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010393b:	89 c7                	mov    %eax,%edi
f010393d:	fc                   	cld    
f010393e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103940:	5e                   	pop    %esi
f0103941:	5f                   	pop    %edi
f0103942:	5d                   	pop    %ebp
f0103943:	c3                   	ret    

f0103944 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103944:	55                   	push   %ebp
f0103945:	89 e5                	mov    %esp,%ebp
f0103947:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010394a:	8b 45 10             	mov    0x10(%ebp),%eax
f010394d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103951:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103954:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103958:	8b 45 08             	mov    0x8(%ebp),%eax
f010395b:	89 04 24             	mov    %eax,(%esp)
f010395e:	e8 79 ff ff ff       	call   f01038dc <memmove>
}
f0103963:	c9                   	leave  
f0103964:	c3                   	ret    

f0103965 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103965:	55                   	push   %ebp
f0103966:	89 e5                	mov    %esp,%ebp
f0103968:	57                   	push   %edi
f0103969:	56                   	push   %esi
f010396a:	53                   	push   %ebx
f010396b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010396e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103971:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103974:	8d 78 ff             	lea    -0x1(%eax),%edi
f0103977:	85 c0                	test   %eax,%eax
f0103979:	74 36                	je     f01039b1 <memcmp+0x4c>
		if (*s1 != *s2)
f010397b:	0f b6 03             	movzbl (%ebx),%eax
f010397e:	0f b6 0e             	movzbl (%esi),%ecx
f0103981:	ba 00 00 00 00       	mov    $0x0,%edx
f0103986:	38 c8                	cmp    %cl,%al
f0103988:	74 1c                	je     f01039a6 <memcmp+0x41>
f010398a:	eb 10                	jmp    f010399c <memcmp+0x37>
f010398c:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103991:	83 c2 01             	add    $0x1,%edx
f0103994:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103998:	38 c8                	cmp    %cl,%al
f010399a:	74 0a                	je     f01039a6 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010399c:	0f b6 c0             	movzbl %al,%eax
f010399f:	0f b6 c9             	movzbl %cl,%ecx
f01039a2:	29 c8                	sub    %ecx,%eax
f01039a4:	eb 10                	jmp    f01039b6 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01039a6:	39 fa                	cmp    %edi,%edx
f01039a8:	75 e2                	jne    f010398c <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01039aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01039af:	eb 05                	jmp    f01039b6 <memcmp+0x51>
f01039b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039b6:	5b                   	pop    %ebx
f01039b7:	5e                   	pop    %esi
f01039b8:	5f                   	pop    %edi
f01039b9:	5d                   	pop    %ebp
f01039ba:	c3                   	ret    

f01039bb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01039bb:	55                   	push   %ebp
f01039bc:	89 e5                	mov    %esp,%ebp
f01039be:	53                   	push   %ebx
f01039bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01039c5:	89 c2                	mov    %eax,%edx
f01039c7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01039ca:	39 d0                	cmp    %edx,%eax
f01039cc:	73 14                	jae    f01039e2 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f01039ce:	89 d9                	mov    %ebx,%ecx
f01039d0:	38 18                	cmp    %bl,(%eax)
f01039d2:	75 06                	jne    f01039da <memfind+0x1f>
f01039d4:	eb 0c                	jmp    f01039e2 <memfind+0x27>
f01039d6:	38 08                	cmp    %cl,(%eax)
f01039d8:	74 08                	je     f01039e2 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01039da:	83 c0 01             	add    $0x1,%eax
f01039dd:	39 d0                	cmp    %edx,%eax
f01039df:	90                   	nop
f01039e0:	75 f4                	jne    f01039d6 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01039e2:	5b                   	pop    %ebx
f01039e3:	5d                   	pop    %ebp
f01039e4:	c3                   	ret    

f01039e5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01039e5:	55                   	push   %ebp
f01039e6:	89 e5                	mov    %esp,%ebp
f01039e8:	57                   	push   %edi
f01039e9:	56                   	push   %esi
f01039ea:	53                   	push   %ebx
f01039eb:	8b 55 08             	mov    0x8(%ebp),%edx
f01039ee:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01039f1:	0f b6 0a             	movzbl (%edx),%ecx
f01039f4:	80 f9 09             	cmp    $0x9,%cl
f01039f7:	74 05                	je     f01039fe <strtol+0x19>
f01039f9:	80 f9 20             	cmp    $0x20,%cl
f01039fc:	75 10                	jne    f0103a0e <strtol+0x29>
		s++;
f01039fe:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a01:	0f b6 0a             	movzbl (%edx),%ecx
f0103a04:	80 f9 09             	cmp    $0x9,%cl
f0103a07:	74 f5                	je     f01039fe <strtol+0x19>
f0103a09:	80 f9 20             	cmp    $0x20,%cl
f0103a0c:	74 f0                	je     f01039fe <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103a0e:	80 f9 2b             	cmp    $0x2b,%cl
f0103a11:	75 0a                	jne    f0103a1d <strtol+0x38>
		s++;
f0103a13:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103a16:	bf 00 00 00 00       	mov    $0x0,%edi
f0103a1b:	eb 11                	jmp    f0103a2e <strtol+0x49>
f0103a1d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103a22:	80 f9 2d             	cmp    $0x2d,%cl
f0103a25:	75 07                	jne    f0103a2e <strtol+0x49>
		s++, neg = 1;
f0103a27:	83 c2 01             	add    $0x1,%edx
f0103a2a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103a2e:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103a33:	75 15                	jne    f0103a4a <strtol+0x65>
f0103a35:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a38:	75 10                	jne    f0103a4a <strtol+0x65>
f0103a3a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103a3e:	75 0a                	jne    f0103a4a <strtol+0x65>
		s += 2, base = 16;
f0103a40:	83 c2 02             	add    $0x2,%edx
f0103a43:	b8 10 00 00 00       	mov    $0x10,%eax
f0103a48:	eb 10                	jmp    f0103a5a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f0103a4a:	85 c0                	test   %eax,%eax
f0103a4c:	75 0c                	jne    f0103a5a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103a4e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103a50:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a53:	75 05                	jne    f0103a5a <strtol+0x75>
		s++, base = 8;
f0103a55:	83 c2 01             	add    $0x1,%edx
f0103a58:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0103a5a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103a5f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103a62:	0f b6 0a             	movzbl (%edx),%ecx
f0103a65:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103a68:	89 f0                	mov    %esi,%eax
f0103a6a:	3c 09                	cmp    $0x9,%al
f0103a6c:	77 08                	ja     f0103a76 <strtol+0x91>
			dig = *s - '0';
f0103a6e:	0f be c9             	movsbl %cl,%ecx
f0103a71:	83 e9 30             	sub    $0x30,%ecx
f0103a74:	eb 20                	jmp    f0103a96 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f0103a76:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103a79:	89 f0                	mov    %esi,%eax
f0103a7b:	3c 19                	cmp    $0x19,%al
f0103a7d:	77 08                	ja     f0103a87 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0103a7f:	0f be c9             	movsbl %cl,%ecx
f0103a82:	83 e9 57             	sub    $0x57,%ecx
f0103a85:	eb 0f                	jmp    f0103a96 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0103a87:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103a8a:	89 f0                	mov    %esi,%eax
f0103a8c:	3c 19                	cmp    $0x19,%al
f0103a8e:	77 16                	ja     f0103aa6 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0103a90:	0f be c9             	movsbl %cl,%ecx
f0103a93:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103a96:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103a99:	7d 0f                	jge    f0103aaa <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103a9b:	83 c2 01             	add    $0x1,%edx
f0103a9e:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103aa2:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103aa4:	eb bc                	jmp    f0103a62 <strtol+0x7d>
f0103aa6:	89 d8                	mov    %ebx,%eax
f0103aa8:	eb 02                	jmp    f0103aac <strtol+0xc7>
f0103aaa:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103aac:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103ab0:	74 05                	je     f0103ab7 <strtol+0xd2>
		*endptr = (char *) s;
f0103ab2:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ab5:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103ab7:	f7 d8                	neg    %eax
f0103ab9:	85 ff                	test   %edi,%edi
f0103abb:	0f 44 c3             	cmove  %ebx,%eax
}
f0103abe:	5b                   	pop    %ebx
f0103abf:	5e                   	pop    %esi
f0103ac0:	5f                   	pop    %edi
f0103ac1:	5d                   	pop    %ebp
f0103ac2:	c3                   	ret    
f0103ac3:	66 90                	xchg   %ax,%ax
f0103ac5:	66 90                	xchg   %ax,%ax
f0103ac7:	66 90                	xchg   %ax,%ax
f0103ac9:	66 90                	xchg   %ax,%ax
f0103acb:	66 90                	xchg   %ax,%ax
f0103acd:	66 90                	xchg   %ax,%ax
f0103acf:	90                   	nop

f0103ad0 <__udivdi3>:
f0103ad0:	55                   	push   %ebp
f0103ad1:	57                   	push   %edi
f0103ad2:	56                   	push   %esi
f0103ad3:	83 ec 0c             	sub    $0xc,%esp
f0103ad6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103ada:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103ade:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103ae2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103ae6:	85 c0                	test   %eax,%eax
f0103ae8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103aec:	89 ea                	mov    %ebp,%edx
f0103aee:	89 0c 24             	mov    %ecx,(%esp)
f0103af1:	75 2d                	jne    f0103b20 <__udivdi3+0x50>
f0103af3:	39 e9                	cmp    %ebp,%ecx
f0103af5:	77 61                	ja     f0103b58 <__udivdi3+0x88>
f0103af7:	85 c9                	test   %ecx,%ecx
f0103af9:	89 ce                	mov    %ecx,%esi
f0103afb:	75 0b                	jne    f0103b08 <__udivdi3+0x38>
f0103afd:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b02:	31 d2                	xor    %edx,%edx
f0103b04:	f7 f1                	div    %ecx
f0103b06:	89 c6                	mov    %eax,%esi
f0103b08:	31 d2                	xor    %edx,%edx
f0103b0a:	89 e8                	mov    %ebp,%eax
f0103b0c:	f7 f6                	div    %esi
f0103b0e:	89 c5                	mov    %eax,%ebp
f0103b10:	89 f8                	mov    %edi,%eax
f0103b12:	f7 f6                	div    %esi
f0103b14:	89 ea                	mov    %ebp,%edx
f0103b16:	83 c4 0c             	add    $0xc,%esp
f0103b19:	5e                   	pop    %esi
f0103b1a:	5f                   	pop    %edi
f0103b1b:	5d                   	pop    %ebp
f0103b1c:	c3                   	ret    
f0103b1d:	8d 76 00             	lea    0x0(%esi),%esi
f0103b20:	39 e8                	cmp    %ebp,%eax
f0103b22:	77 24                	ja     f0103b48 <__udivdi3+0x78>
f0103b24:	0f bd e8             	bsr    %eax,%ebp
f0103b27:	83 f5 1f             	xor    $0x1f,%ebp
f0103b2a:	75 3c                	jne    f0103b68 <__udivdi3+0x98>
f0103b2c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103b30:	39 34 24             	cmp    %esi,(%esp)
f0103b33:	0f 86 9f 00 00 00    	jbe    f0103bd8 <__udivdi3+0x108>
f0103b39:	39 d0                	cmp    %edx,%eax
f0103b3b:	0f 82 97 00 00 00    	jb     f0103bd8 <__udivdi3+0x108>
f0103b41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103b48:	31 d2                	xor    %edx,%edx
f0103b4a:	31 c0                	xor    %eax,%eax
f0103b4c:	83 c4 0c             	add    $0xc,%esp
f0103b4f:	5e                   	pop    %esi
f0103b50:	5f                   	pop    %edi
f0103b51:	5d                   	pop    %ebp
f0103b52:	c3                   	ret    
f0103b53:	90                   	nop
f0103b54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b58:	89 f8                	mov    %edi,%eax
f0103b5a:	f7 f1                	div    %ecx
f0103b5c:	31 d2                	xor    %edx,%edx
f0103b5e:	83 c4 0c             	add    $0xc,%esp
f0103b61:	5e                   	pop    %esi
f0103b62:	5f                   	pop    %edi
f0103b63:	5d                   	pop    %ebp
f0103b64:	c3                   	ret    
f0103b65:	8d 76 00             	lea    0x0(%esi),%esi
f0103b68:	89 e9                	mov    %ebp,%ecx
f0103b6a:	8b 3c 24             	mov    (%esp),%edi
f0103b6d:	d3 e0                	shl    %cl,%eax
f0103b6f:	89 c6                	mov    %eax,%esi
f0103b71:	b8 20 00 00 00       	mov    $0x20,%eax
f0103b76:	29 e8                	sub    %ebp,%eax
f0103b78:	89 c1                	mov    %eax,%ecx
f0103b7a:	d3 ef                	shr    %cl,%edi
f0103b7c:	89 e9                	mov    %ebp,%ecx
f0103b7e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103b82:	8b 3c 24             	mov    (%esp),%edi
f0103b85:	09 74 24 08          	or     %esi,0x8(%esp)
f0103b89:	89 d6                	mov    %edx,%esi
f0103b8b:	d3 e7                	shl    %cl,%edi
f0103b8d:	89 c1                	mov    %eax,%ecx
f0103b8f:	89 3c 24             	mov    %edi,(%esp)
f0103b92:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103b96:	d3 ee                	shr    %cl,%esi
f0103b98:	89 e9                	mov    %ebp,%ecx
f0103b9a:	d3 e2                	shl    %cl,%edx
f0103b9c:	89 c1                	mov    %eax,%ecx
f0103b9e:	d3 ef                	shr    %cl,%edi
f0103ba0:	09 d7                	or     %edx,%edi
f0103ba2:	89 f2                	mov    %esi,%edx
f0103ba4:	89 f8                	mov    %edi,%eax
f0103ba6:	f7 74 24 08          	divl   0x8(%esp)
f0103baa:	89 d6                	mov    %edx,%esi
f0103bac:	89 c7                	mov    %eax,%edi
f0103bae:	f7 24 24             	mull   (%esp)
f0103bb1:	39 d6                	cmp    %edx,%esi
f0103bb3:	89 14 24             	mov    %edx,(%esp)
f0103bb6:	72 30                	jb     f0103be8 <__udivdi3+0x118>
f0103bb8:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103bbc:	89 e9                	mov    %ebp,%ecx
f0103bbe:	d3 e2                	shl    %cl,%edx
f0103bc0:	39 c2                	cmp    %eax,%edx
f0103bc2:	73 05                	jae    f0103bc9 <__udivdi3+0xf9>
f0103bc4:	3b 34 24             	cmp    (%esp),%esi
f0103bc7:	74 1f                	je     f0103be8 <__udivdi3+0x118>
f0103bc9:	89 f8                	mov    %edi,%eax
f0103bcb:	31 d2                	xor    %edx,%edx
f0103bcd:	e9 7a ff ff ff       	jmp    f0103b4c <__udivdi3+0x7c>
f0103bd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103bd8:	31 d2                	xor    %edx,%edx
f0103bda:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bdf:	e9 68 ff ff ff       	jmp    f0103b4c <__udivdi3+0x7c>
f0103be4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103be8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103beb:	31 d2                	xor    %edx,%edx
f0103bed:	83 c4 0c             	add    $0xc,%esp
f0103bf0:	5e                   	pop    %esi
f0103bf1:	5f                   	pop    %edi
f0103bf2:	5d                   	pop    %ebp
f0103bf3:	c3                   	ret    
f0103bf4:	66 90                	xchg   %ax,%ax
f0103bf6:	66 90                	xchg   %ax,%ax
f0103bf8:	66 90                	xchg   %ax,%ax
f0103bfa:	66 90                	xchg   %ax,%ax
f0103bfc:	66 90                	xchg   %ax,%ax
f0103bfe:	66 90                	xchg   %ax,%ax

f0103c00 <__umoddi3>:
f0103c00:	55                   	push   %ebp
f0103c01:	57                   	push   %edi
f0103c02:	56                   	push   %esi
f0103c03:	83 ec 14             	sub    $0x14,%esp
f0103c06:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103c0a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103c0e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103c12:	89 c7                	mov    %eax,%edi
f0103c14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c18:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103c1c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103c20:	89 34 24             	mov    %esi,(%esp)
f0103c23:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c27:	85 c0                	test   %eax,%eax
f0103c29:	89 c2                	mov    %eax,%edx
f0103c2b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c2f:	75 17                	jne    f0103c48 <__umoddi3+0x48>
f0103c31:	39 fe                	cmp    %edi,%esi
f0103c33:	76 4b                	jbe    f0103c80 <__umoddi3+0x80>
f0103c35:	89 c8                	mov    %ecx,%eax
f0103c37:	89 fa                	mov    %edi,%edx
f0103c39:	f7 f6                	div    %esi
f0103c3b:	89 d0                	mov    %edx,%eax
f0103c3d:	31 d2                	xor    %edx,%edx
f0103c3f:	83 c4 14             	add    $0x14,%esp
f0103c42:	5e                   	pop    %esi
f0103c43:	5f                   	pop    %edi
f0103c44:	5d                   	pop    %ebp
f0103c45:	c3                   	ret    
f0103c46:	66 90                	xchg   %ax,%ax
f0103c48:	39 f8                	cmp    %edi,%eax
f0103c4a:	77 54                	ja     f0103ca0 <__umoddi3+0xa0>
f0103c4c:	0f bd e8             	bsr    %eax,%ebp
f0103c4f:	83 f5 1f             	xor    $0x1f,%ebp
f0103c52:	75 5c                	jne    f0103cb0 <__umoddi3+0xb0>
f0103c54:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103c58:	39 3c 24             	cmp    %edi,(%esp)
f0103c5b:	0f 87 e7 00 00 00    	ja     f0103d48 <__umoddi3+0x148>
f0103c61:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103c65:	29 f1                	sub    %esi,%ecx
f0103c67:	19 c7                	sbb    %eax,%edi
f0103c69:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c6d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c71:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103c75:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103c79:	83 c4 14             	add    $0x14,%esp
f0103c7c:	5e                   	pop    %esi
f0103c7d:	5f                   	pop    %edi
f0103c7e:	5d                   	pop    %ebp
f0103c7f:	c3                   	ret    
f0103c80:	85 f6                	test   %esi,%esi
f0103c82:	89 f5                	mov    %esi,%ebp
f0103c84:	75 0b                	jne    f0103c91 <__umoddi3+0x91>
f0103c86:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c8b:	31 d2                	xor    %edx,%edx
f0103c8d:	f7 f6                	div    %esi
f0103c8f:	89 c5                	mov    %eax,%ebp
f0103c91:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103c95:	31 d2                	xor    %edx,%edx
f0103c97:	f7 f5                	div    %ebp
f0103c99:	89 c8                	mov    %ecx,%eax
f0103c9b:	f7 f5                	div    %ebp
f0103c9d:	eb 9c                	jmp    f0103c3b <__umoddi3+0x3b>
f0103c9f:	90                   	nop
f0103ca0:	89 c8                	mov    %ecx,%eax
f0103ca2:	89 fa                	mov    %edi,%edx
f0103ca4:	83 c4 14             	add    $0x14,%esp
f0103ca7:	5e                   	pop    %esi
f0103ca8:	5f                   	pop    %edi
f0103ca9:	5d                   	pop    %ebp
f0103caa:	c3                   	ret    
f0103cab:	90                   	nop
f0103cac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cb0:	8b 04 24             	mov    (%esp),%eax
f0103cb3:	be 20 00 00 00       	mov    $0x20,%esi
f0103cb8:	89 e9                	mov    %ebp,%ecx
f0103cba:	29 ee                	sub    %ebp,%esi
f0103cbc:	d3 e2                	shl    %cl,%edx
f0103cbe:	89 f1                	mov    %esi,%ecx
f0103cc0:	d3 e8                	shr    %cl,%eax
f0103cc2:	89 e9                	mov    %ebp,%ecx
f0103cc4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cc8:	8b 04 24             	mov    (%esp),%eax
f0103ccb:	09 54 24 04          	or     %edx,0x4(%esp)
f0103ccf:	89 fa                	mov    %edi,%edx
f0103cd1:	d3 e0                	shl    %cl,%eax
f0103cd3:	89 f1                	mov    %esi,%ecx
f0103cd5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103cd9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103cdd:	d3 ea                	shr    %cl,%edx
f0103cdf:	89 e9                	mov    %ebp,%ecx
f0103ce1:	d3 e7                	shl    %cl,%edi
f0103ce3:	89 f1                	mov    %esi,%ecx
f0103ce5:	d3 e8                	shr    %cl,%eax
f0103ce7:	89 e9                	mov    %ebp,%ecx
f0103ce9:	09 f8                	or     %edi,%eax
f0103ceb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103cef:	f7 74 24 04          	divl   0x4(%esp)
f0103cf3:	d3 e7                	shl    %cl,%edi
f0103cf5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103cf9:	89 d7                	mov    %edx,%edi
f0103cfb:	f7 64 24 08          	mull   0x8(%esp)
f0103cff:	39 d7                	cmp    %edx,%edi
f0103d01:	89 c1                	mov    %eax,%ecx
f0103d03:	89 14 24             	mov    %edx,(%esp)
f0103d06:	72 2c                	jb     f0103d34 <__umoddi3+0x134>
f0103d08:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103d0c:	72 22                	jb     f0103d30 <__umoddi3+0x130>
f0103d0e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103d12:	29 c8                	sub    %ecx,%eax
f0103d14:	19 d7                	sbb    %edx,%edi
f0103d16:	89 e9                	mov    %ebp,%ecx
f0103d18:	89 fa                	mov    %edi,%edx
f0103d1a:	d3 e8                	shr    %cl,%eax
f0103d1c:	89 f1                	mov    %esi,%ecx
f0103d1e:	d3 e2                	shl    %cl,%edx
f0103d20:	89 e9                	mov    %ebp,%ecx
f0103d22:	d3 ef                	shr    %cl,%edi
f0103d24:	09 d0                	or     %edx,%eax
f0103d26:	89 fa                	mov    %edi,%edx
f0103d28:	83 c4 14             	add    $0x14,%esp
f0103d2b:	5e                   	pop    %esi
f0103d2c:	5f                   	pop    %edi
f0103d2d:	5d                   	pop    %ebp
f0103d2e:	c3                   	ret    
f0103d2f:	90                   	nop
f0103d30:	39 d7                	cmp    %edx,%edi
f0103d32:	75 da                	jne    f0103d0e <__umoddi3+0x10e>
f0103d34:	8b 14 24             	mov    (%esp),%edx
f0103d37:	89 c1                	mov    %eax,%ecx
f0103d39:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103d3d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103d41:	eb cb                	jmp    f0103d0e <__umoddi3+0x10e>
f0103d43:	90                   	nop
f0103d44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d48:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103d4c:	0f 82 0f ff ff ff    	jb     f0103c61 <__umoddi3+0x61>
f0103d52:	e9 1a ff ff ff       	jmp    f0103c71 <__umoddi3+0x71>
