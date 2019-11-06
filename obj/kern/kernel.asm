
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
f0100063:	e8 67 37 00 00       	call   f01037cf <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8b 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 a0 3c 10 f0 	movl   $0xf0103ca0,(%esp)
f010007c:	e8 b4 2b 00 00       	call   f0102c35 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 e9 10 00 00       	call   f010116f <mem_init>

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
f01000c1:	c7 04 24 bb 3c 10 f0 	movl   $0xf0103cbb,(%esp)
f01000c8:	e8 68 2b 00 00       	call   f0102c35 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 29 2b 00 00       	call   f0102c02 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 36 4b 10 f0 	movl   $0xf0104b36,(%esp)
f01000e0:	e8 50 2b 00 00       	call   f0102c35 <cprintf>
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
f010010b:	c7 04 24 d3 3c 10 f0 	movl   $0xf0103cd3,(%esp)
f0100112:	e8 1e 2b 00 00       	call   f0102c35 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 dc 2a 00 00       	call   f0102c02 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 36 4b 10 f0 	movl   $0xf0104b36,(%esp)
f010012d:	e8 03 2b 00 00       	call   f0102c35 <cprintf>
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
f01001e5:	0f b6 82 40 3e 10 f0 	movzbl -0xfefc1c0(%edx),%eax
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
f0100222:	0f b6 82 40 3e 10 f0 	movzbl -0xfefc1c0(%edx),%eax
f0100229:	0b 05 20 73 11 f0    	or     0xf0117320,%eax
	shift ^= togglecode[data];
f010022f:	0f b6 8a 40 3d 10 f0 	movzbl -0xfefc2c0(%edx),%ecx
f0100236:	31 c8                	xor    %ecx,%eax
f0100238:	a3 20 73 11 f0       	mov    %eax,0xf0117320

	c = charcode[shift & (CTL | SHIFT)][data];
f010023d:	89 c1                	mov    %eax,%ecx
f010023f:	83 e1 03             	and    $0x3,%ecx
f0100242:	8b 0c 8d 20 3d 10 f0 	mov    -0xfefc2e0(,%ecx,4),%ecx
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
f0100282:	c7 04 24 ed 3c 10 f0 	movl   $0xf0103ced,(%esp)
f0100289:	e8 a7 29 00 00       	call   f0102c35 <cprintf>
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
f0100422:	e8 f5 33 00 00       	call   f010381c <memmove>
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
f01005d9:	c7 04 24 f9 3c 10 f0 	movl   $0xf0103cf9,(%esp)
f01005e0:	e8 50 26 00 00       	call   f0102c35 <cprintf>
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
f0100626:	c7 44 24 08 37 4b 10 	movl   $0xf0104b37,0x8(%esp)
f010062d:	f0 
f010062e:	c7 44 24 04 40 3f 10 	movl   $0xf0103f40,0x4(%esp)
f0100635:	f0 
f0100636:	c7 04 24 4a 3f 10 f0 	movl   $0xf0103f4a,(%esp)
f010063d:	e8 f3 25 00 00       	call   f0102c35 <cprintf>
f0100642:	c7 44 24 08 53 3f 10 	movl   $0xf0103f53,0x8(%esp)
f0100649:	f0 
f010064a:	c7 44 24 04 71 3f 10 	movl   $0xf0103f71,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 4a 3f 10 f0 	movl   $0xf0103f4a,(%esp)
f0100659:	e8 d7 25 00 00       	call   f0102c35 <cprintf>
f010065e:	c7 44 24 08 08 40 10 	movl   $0xf0104008,0x8(%esp)
f0100665:	f0 
f0100666:	c7 44 24 04 76 3f 10 	movl   $0xf0103f76,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 4a 3f 10 f0 	movl   $0xf0103f4a,(%esp)
f0100675:	e8 bb 25 00 00       	call   f0102c35 <cprintf>
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
f0100687:	c7 04 24 7f 3f 10 f0 	movl   $0xf0103f7f,(%esp)
f010068e:	e8 a2 25 00 00       	call   f0102c35 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100693:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010069a:	00 
f010069b:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006a2:	f0 
f01006a3:	c7 04 24 30 40 10 f0 	movl   $0xf0104030,(%esp)
f01006aa:	e8 86 25 00 00       	call   f0102c35 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006af:	c7 44 24 08 97 3c 10 	movl   $0x103c97,0x8(%esp)
f01006b6:	00 
f01006b7:	c7 44 24 04 97 3c 10 	movl   $0xf0103c97,0x4(%esp)
f01006be:	f0 
f01006bf:	c7 04 24 54 40 10 f0 	movl   $0xf0104054,(%esp)
f01006c6:	e8 6a 25 00 00       	call   f0102c35 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006cb:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006d2:	00 
f01006d3:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006da:	f0 
f01006db:	c7 04 24 78 40 10 f0 	movl   $0xf0104078,(%esp)
f01006e2:	e8 4e 25 00 00       	call   f0102c35 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e7:	c7 44 24 08 8c 79 11 	movl   $0x11798c,0x8(%esp)
f01006ee:	00 
f01006ef:	c7 44 24 04 8c 79 11 	movl   $0xf011798c,0x4(%esp)
f01006f6:	f0 
f01006f7:	c7 04 24 9c 40 10 f0 	movl   $0xf010409c,(%esp)
f01006fe:	e8 32 25 00 00       	call   f0102c35 <cprintf>
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
f010071f:	c7 04 24 c0 40 10 f0 	movl   $0xf01040c0,(%esp)
f0100726:	e8 0a 25 00 00       	call   f0102c35 <cprintf>
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
f010073e:	c7 04 24 98 3f 10 f0 	movl   $0xf0103f98,(%esp)
f0100745:	e8 eb 24 00 00       	call   f0102c35 <cprintf>
	while(ebp)
f010074a:	85 f6                	test   %esi,%esi
f010074c:	74 7c                	je     f01007ca <mon_backtrace+0x98>
	{
		cprintf("ebp %x, eip %x args", ebp, ebp[1]);
f010074e:	8b 43 04             	mov    0x4(%ebx),%eax
f0100751:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100755:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100759:	c7 04 24 aa 3f 10 f0 	movl   $0xf0103faa,(%esp)
f0100760:	e8 d0 24 00 00       	call   f0102c35 <cprintf>
		cprintf(" %08x", ebp[2]);
f0100765:	8b 43 08             	mov    0x8(%ebx),%eax
f0100768:	89 44 24 04          	mov    %eax,0x4(%esp)
f010076c:	c7 04 24 be 3f 10 f0 	movl   $0xf0103fbe,(%esp)
f0100773:	e8 bd 24 00 00       	call   f0102c35 <cprintf>
		cprintf(" %08x", ebp[3]);
f0100778:	8b 43 0c             	mov    0xc(%ebx),%eax
f010077b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077f:	c7 04 24 be 3f 10 f0 	movl   $0xf0103fbe,(%esp)
f0100786:	e8 aa 24 00 00       	call   f0102c35 <cprintf>
		cprintf(" %08x", ebp[4]);
f010078b:	8b 43 10             	mov    0x10(%ebx),%eax
f010078e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100792:	c7 04 24 be 3f 10 f0 	movl   $0xf0103fbe,(%esp)
f0100799:	e8 97 24 00 00       	call   f0102c35 <cprintf>
		cprintf(" %08x", ebp[5]);
f010079e:	8b 43 14             	mov    0x14(%ebx),%eax
f01007a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a5:	c7 04 24 be 3f 10 f0 	movl   $0xf0103fbe,(%esp)
f01007ac:	e8 84 24 00 00       	call   f0102c35 <cprintf>
		cprintf(" %08x\n", ebp[6]);
f01007b1:	8b 43 18             	mov    0x18(%ebx),%eax
f01007b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b8:	c7 04 24 c4 3f 10 f0 	movl   $0xf0103fc4,(%esp)
f01007bf:	e8 71 24 00 00       	call   f0102c35 <cprintf>
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
f01007df:	c7 04 24 ec 40 10 f0 	movl   $0xf01040ec,(%esp)
f01007e6:	e8 4a 24 00 00       	call   f0102c35 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007eb:	c7 04 24 10 41 10 f0 	movl   $0xf0104110,(%esp)
f01007f2:	e8 3e 24 00 00       	call   f0102c35 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007f7:	c7 04 24 cb 3f 10 f0 	movl   $0xf0103fcb,(%esp)
f01007fe:	e8 1d 2d 00 00       	call   f0103520 <readline>
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
f010082f:	c7 04 24 cf 3f 10 f0 	movl   $0xf0103fcf,(%esp)
f0100836:	e8 33 2f 00 00       	call   f010376e <strchr>
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
f0100851:	c7 04 24 d4 3f 10 f0 	movl   $0xf0103fd4,(%esp)
f0100858:	e8 d8 23 00 00       	call   f0102c35 <cprintf>
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
f0100880:	c7 04 24 cf 3f 10 f0 	movl   $0xf0103fcf,(%esp)
f0100887:	e8 e2 2e 00 00       	call   f010376e <strchr>
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
f01008aa:	8b 04 85 40 41 10 f0 	mov    -0xfefbec0(,%eax,4),%eax
f01008b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b5:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008b8:	89 04 24             	mov    %eax,(%esp)
f01008bb:	e8 2a 2e 00 00       	call   f01036ea <strcmp>
f01008c0:	85 c0                	test   %eax,%eax
f01008c2:	75 24                	jne    f01008e8 <monitor+0x112>
			return commands[i].func(argc, argv, tf);
f01008c4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c7:	8b 55 08             	mov    0x8(%ebp),%edx
f01008ca:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008ce:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008d1:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01008d5:	89 34 24             	mov    %esi,(%esp)
f01008d8:	ff 14 85 48 41 10 f0 	call   *-0xfefbeb8(,%eax,4)


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
f01008f9:	c7 04 24 f1 3f 10 f0 	movl   $0xf0103ff1,(%esp)
f0100900:	e8 30 23 00 00       	call   f0102c35 <cprintf>
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
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100923:	83 3d 58 75 11 f0 00 	cmpl   $0x0,0xf0117558
f010092a:	75 11                	jne    f010093d <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010092c:	ba 8b 89 11 f0       	mov    $0xf011898b,%edx
f0100931:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100937:	89 15 58 75 11 f0    	mov    %edx,0xf0117558
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
		return next;
	}
	else
	{
		return nextfree;
f010093d:	8b 15 58 75 11 f0    	mov    0xf0117558,%edx
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//

	if (n!=0)
f0100943:	85 c0                	test   %eax,%eax
f0100945:	74 11                	je     f0100958 <boot_alloc+0x38>
	{
		char* next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f0100947:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f010094e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100953:	a3 58 75 11 f0       	mov    %eax,0xf0117558
	}

	// LAB 2: Your code here.

	return NULL;
}
f0100958:	89 d0                	mov    %edx,%eax
f010095a:	5d                   	pop    %ebp
f010095b:	c3                   	ret    

f010095c <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010095c:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100962:	c1 f8 03             	sar    $0x3,%eax
f0100965:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100968:	89 c2                	mov    %eax,%edx
f010096a:	c1 ea 0c             	shr    $0xc,%edx
f010096d:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100973:	72 26                	jb     f010099b <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct Page *pp)
{
f0100975:	55                   	push   %ebp
f0100976:	89 e5                	mov    %esp,%ebp
f0100978:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010097b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010097f:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f0100986:	f0 
f0100987:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010098e:	00 
f010098f:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f0100996:	e8 f9 f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010099b:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
}
f01009a0:	c3                   	ret    

f01009a1 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009a1:	89 d1                	mov    %edx,%ecx
f01009a3:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009a6:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009a9:	a8 01                	test   $0x1,%al
f01009ab:	74 5d                	je     f0100a0a <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009b2:	89 c1                	mov    %eax,%ecx
f01009b4:	c1 e9 0c             	shr    $0xc,%ecx
f01009b7:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f01009bd:	72 26                	jb     f01009e5 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009bf:	55                   	push   %ebp
f01009c0:	89 e5                	mov    %esp,%ebp
f01009c2:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009c9:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f01009d0:	f0 
f01009d1:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f01009d8:	00 
f01009d9:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01009e0:	e8 af f6 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009e5:	c1 ea 0c             	shr    $0xc,%edx
f01009e8:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009ee:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009f5:	89 c2                	mov    %eax,%edx
f01009f7:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009ff:	85 d2                	test   %edx,%edx
f0100a01:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a06:	0f 44 c2             	cmove  %edx,%eax
f0100a09:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a0f:	c3                   	ret    

f0100a10 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a10:	55                   	push   %ebp
f0100a11:	89 e5                	mov    %esp,%ebp
f0100a13:	57                   	push   %edi
f0100a14:	56                   	push   %esi
f0100a15:	53                   	push   %ebx
f0100a16:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a19:	85 c0                	test   %eax,%eax
f0100a1b:	0f 85 36 03 00 00    	jne    f0100d57 <check_page_free_list+0x347>
f0100a21:	e9 43 03 00 00       	jmp    f0100d69 <check_page_free_list+0x359>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a26:	c7 44 24 08 88 41 10 	movl   $0xf0104188,0x8(%esp)
f0100a2d:	f0 
f0100a2e:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
f0100a35:	00 
f0100a36:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100a3d:	e8 52 f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100a42:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a45:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a48:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a4b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a4e:	89 c2                	mov    %eax,%edx
f0100a50:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a56:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a5c:	0f 95 c2             	setne  %dl
f0100a5f:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a62:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a66:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a68:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a6c:	8b 00                	mov    (%eax),%eax
f0100a6e:	85 c0                	test   %eax,%eax
f0100a70:	75 dc                	jne    f0100a4e <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a72:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a75:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a7b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a7e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a81:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a83:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a86:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a8b:	89 c3                	mov    %eax,%ebx
f0100a8d:	85 c0                	test   %eax,%eax
f0100a8f:	74 6c                	je     f0100afd <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a91:	be 01 00 00 00       	mov    $0x1,%esi
f0100a96:	89 d8                	mov    %ebx,%eax
f0100a98:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100a9e:	c1 f8 03             	sar    $0x3,%eax
f0100aa1:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100aa4:	89 c2                	mov    %eax,%edx
f0100aa6:	c1 ea 16             	shr    $0x16,%edx
f0100aa9:	39 f2                	cmp    %esi,%edx
f0100aab:	73 4a                	jae    f0100af7 <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aad:	89 c2                	mov    %eax,%edx
f0100aaf:	c1 ea 0c             	shr    $0xc,%edx
f0100ab2:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100ab8:	72 20                	jb     f0100ada <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100abe:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f0100ac5:	f0 
f0100ac6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100acd:	00 
f0100ace:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f0100ad5:	e8 ba f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100ada:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100ae1:	00 
f0100ae2:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100ae9:	00 
	return (void *)(pa + KERNBASE);
f0100aea:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100aef:	89 04 24             	mov    %eax,(%esp)
f0100af2:	e8 d8 2c 00 00       	call   f01037cf <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100af7:	8b 1b                	mov    (%ebx),%ebx
f0100af9:	85 db                	test   %ebx,%ebx
f0100afb:	75 99                	jne    f0100a96 <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100afd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b02:	e8 19 fe ff ff       	call   f0100920 <boot_alloc>
f0100b07:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b0a:	8b 15 5c 75 11 f0    	mov    0xf011755c,%edx
f0100b10:	85 d2                	test   %edx,%edx
f0100b12:	0f 84 f3 01 00 00    	je     f0100d0b <check_page_free_list+0x2fb>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b18:	8b 1d 88 79 11 f0    	mov    0xf0117988,%ebx
f0100b1e:	39 da                	cmp    %ebx,%edx
f0100b20:	72 40                	jb     f0100b62 <check_page_free_list+0x152>
		assert(pp < pages + npages);
f0100b22:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0100b27:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b2a:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b2d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b30:	39 c2                	cmp    %eax,%edx
f0100b32:	73 57                	jae    f0100b8b <check_page_free_list+0x17b>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b34:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b37:	89 d0                	mov    %edx,%eax
f0100b39:	29 d8                	sub    %ebx,%eax
f0100b3b:	a8 07                	test   $0x7,%al
f0100b3d:	75 79                	jne    f0100bb8 <check_page_free_list+0x1a8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b3f:	c1 f8 03             	sar    $0x3,%eax
f0100b42:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b45:	85 c0                	test   %eax,%eax
f0100b47:	0f 84 99 00 00 00    	je     f0100be6 <check_page_free_list+0x1d6>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b4d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b52:	0f 85 dd 00 00 00    	jne    f0100c35 <check_page_free_list+0x225>
f0100b58:	e9 b4 00 00 00       	jmp    f0100c11 <check_page_free_list+0x201>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b5d:	39 d3                	cmp    %edx,%ebx
f0100b5f:	90                   	nop
f0100b60:	76 24                	jbe    f0100b86 <check_page_free_list+0x176>
f0100b62:	c7 44 24 0c 8e 48 10 	movl   $0xf010488e,0xc(%esp)
f0100b69:	f0 
f0100b6a:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100b71:	f0 
f0100b72:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
f0100b79:	00 
f0100b7a:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100b81:	e8 0e f5 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100b86:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b89:	72 24                	jb     f0100baf <check_page_free_list+0x19f>
f0100b8b:	c7 44 24 0c af 48 10 	movl   $0xf01048af,0xc(%esp)
f0100b92:	f0 
f0100b93:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100b9a:	f0 
f0100b9b:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
f0100ba2:	00 
f0100ba3:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100baa:	e8 e5 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100baf:	89 d0                	mov    %edx,%eax
f0100bb1:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bb4:	a8 07                	test   $0x7,%al
f0100bb6:	74 24                	je     f0100bdc <check_page_free_list+0x1cc>
f0100bb8:	c7 44 24 0c ac 41 10 	movl   $0xf01041ac,0xc(%esp)
f0100bbf:	f0 
f0100bc0:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100bc7:	f0 
f0100bc8:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
f0100bcf:	00 
f0100bd0:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100bd7:	e8 b8 f4 ff ff       	call   f0100094 <_panic>
f0100bdc:	c1 f8 03             	sar    $0x3,%eax
f0100bdf:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100be2:	85 c0                	test   %eax,%eax
f0100be4:	75 24                	jne    f0100c0a <check_page_free_list+0x1fa>
f0100be6:	c7 44 24 0c c3 48 10 	movl   $0xf01048c3,0xc(%esp)
f0100bed:	f0 
f0100bee:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100bf5:	f0 
f0100bf6:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
f0100bfd:	00 
f0100bfe:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100c05:	e8 8a f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c0a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c0f:	75 2e                	jne    f0100c3f <check_page_free_list+0x22f>
f0100c11:	c7 44 24 0c d4 48 10 	movl   $0xf01048d4,0xc(%esp)
f0100c18:	f0 
f0100c19:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100c20:	f0 
f0100c21:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
f0100c28:	00 
f0100c29:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100c30:	e8 5f f4 ff ff       	call   f0100094 <_panic>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c35:	be 00 00 00 00       	mov    $0x0,%esi
f0100c3a:	bf 00 00 00 00       	mov    $0x0,%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c3f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c44:	75 24                	jne    f0100c6a <check_page_free_list+0x25a>
f0100c46:	c7 44 24 0c e0 41 10 	movl   $0xf01041e0,0xc(%esp)
f0100c4d:	f0 
f0100c4e:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100c55:	f0 
f0100c56:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
f0100c5d:	00 
f0100c5e:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100c65:	e8 2a f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c6a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c6f:	75 24                	jne    f0100c95 <check_page_free_list+0x285>
f0100c71:	c7 44 24 0c ed 48 10 	movl   $0xf01048ed,0xc(%esp)
f0100c78:	f0 
f0100c79:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100c80:	f0 
f0100c81:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
f0100c88:	00 
f0100c89:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100c90:	e8 ff f3 ff ff       	call   f0100094 <_panic>
f0100c95:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c97:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c9c:	76 57                	jbe    f0100cf5 <check_page_free_list+0x2e5>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c9e:	c1 e8 0c             	shr    $0xc,%eax
f0100ca1:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100ca4:	77 20                	ja     f0100cc6 <check_page_free_list+0x2b6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ca6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100caa:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f0100cb1:	f0 
f0100cb2:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cb9:	00 
f0100cba:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f0100cc1:	e8 ce f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100cc6:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100ccc:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f0100ccf:	76 29                	jbe    f0100cfa <check_page_free_list+0x2ea>
f0100cd1:	c7 44 24 0c 04 42 10 	movl   $0xf0104204,0xc(%esp)
f0100cd8:	f0 
f0100cd9:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100ce0:	f0 
f0100ce1:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
f0100ce8:	00 
f0100ce9:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100cf0:	e8 9f f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100cf5:	83 c7 01             	add    $0x1,%edi
f0100cf8:	eb 03                	jmp    f0100cfd <check_page_free_list+0x2ed>
		else
			++nfree_extmem;
f0100cfa:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cfd:	8b 12                	mov    (%edx),%edx
f0100cff:	85 d2                	test   %edx,%edx
f0100d01:	0f 85 56 fe ff ff    	jne    f0100b5d <check_page_free_list+0x14d>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d07:	85 ff                	test   %edi,%edi
f0100d09:	7f 24                	jg     f0100d2f <check_page_free_list+0x31f>
f0100d0b:	c7 44 24 0c 07 49 10 	movl   $0xf0104907,0xc(%esp)
f0100d12:	f0 
f0100d13:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100d1a:	f0 
f0100d1b:	c7 44 24 04 29 02 00 	movl   $0x229,0x4(%esp)
f0100d22:	00 
f0100d23:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100d2a:	e8 65 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d2f:	85 f6                	test   %esi,%esi
f0100d31:	7f 53                	jg     f0100d86 <check_page_free_list+0x376>
f0100d33:	c7 44 24 0c 19 49 10 	movl   $0xf0104919,0xc(%esp)
f0100d3a:	f0 
f0100d3b:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0100d42:	f0 
f0100d43:	c7 44 24 04 2a 02 00 	movl   $0x22a,0x4(%esp)
f0100d4a:	00 
f0100d4b:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100d52:	e8 3d f3 ff ff       	call   f0100094 <_panic>
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d57:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f0100d5c:	85 c0                	test   %eax,%eax
f0100d5e:	0f 85 de fc ff ff    	jne    f0100a42 <check_page_free_list+0x32>
f0100d64:	e9 bd fc ff ff       	jmp    f0100a26 <check_page_free_list+0x16>
f0100d69:	83 3d 5c 75 11 f0 00 	cmpl   $0x0,0xf011755c
f0100d70:	0f 84 b0 fc ff ff    	je     f0100a26 <check_page_free_list+0x16>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d76:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d7c:	be 00 04 00 00       	mov    $0x400,%esi
f0100d81:	e9 10 fd ff ff       	jmp    f0100a96 <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100d86:	83 c4 3c             	add    $0x3c,%esp
f0100d89:	5b                   	pop    %ebx
f0100d8a:	5e                   	pop    %esi
f0100d8b:	5f                   	pop    %edi
f0100d8c:	5d                   	pop    %ebp
f0100d8d:	c3                   	ret    

f0100d8e <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d8e:	55                   	push   %ebp
f0100d8f:	89 e5                	mov    %esp,%ebp
f0100d91:	56                   	push   %esi
f0100d92:	53                   	push   %ebx
f0100d93:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	cprintf("page_init called\n");
f0100d96:	c7 04 24 2a 49 10 f0 	movl   $0xf010492a,(%esp)
f0100d9d:	e8 93 1e 00 00       	call   f0102c35 <cprintf>
	for (i = 1; i < npages_basemem; i++) {
f0100da2:	8b 35 60 75 11 f0    	mov    0xf0117560,%esi
f0100da8:	83 fe 01             	cmp    $0x1,%esi
f0100dab:	76 39                	jbe    f0100de6 <page_init+0x58>
f0100dad:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
f0100db3:	b8 01 00 00 00       	mov    $0x1,%eax
f0100db8:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100dbf:	89 d1                	mov    %edx,%ecx
f0100dc1:	03 0d 88 79 11 f0    	add    0xf0117988,%ecx
f0100dc7:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100dcd:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100dcf:	03 15 88 79 11 f0    	add    0xf0117988,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	cprintf("page_init called\n");
	for (i = 1; i < npages_basemem; i++) {
f0100dd5:	83 c0 01             	add    $0x1,%eax
f0100dd8:	39 f0                	cmp    %esi,%eax
f0100dda:	73 04                	jae    f0100de0 <page_init+0x52>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100ddc:	89 d3                	mov    %edx,%ebx
f0100dde:	eb d8                	jmp    f0100db8 <page_init+0x2a>
f0100de0:	89 15 5c 75 11 f0    	mov    %edx,0xf011755c
	}
	int med = (int)ROUNDUP(((char*)pages)+(sizeof(struct Page)*npages)-0xf0000000, PGSIZE)/PGSIZE;
f0100de6:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f0100dec:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0100df1:	8d 84 c8 ff 0f 00 10 	lea    0x10000fff(%eax,%ecx,8),%eax
f0100df8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100dfd:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e03:	85 c0                	test   %eax,%eax
f0100e05:	0f 48 c2             	cmovs  %edx,%eax
f0100e08:	c1 f8 0c             	sar    $0xc,%eax
	for(i=med; i<npages;i++) {
f0100e0b:	89 c2                	mov    %eax,%edx
f0100e0d:	39 c1                	cmp    %eax,%ecx
f0100e0f:	76 39                	jbe    f0100e4a <page_init+0xbc>
f0100e11:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
f0100e17:	c1 e0 03             	shl    $0x3,%eax
		pages[i].pp_ref = 0;
f0100e1a:	89 c1                	mov    %eax,%ecx
f0100e1c:	03 0d 88 79 11 f0    	add    0xf0117988,%ecx
f0100e22:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link=page_free_list;
f0100e28:	89 19                	mov    %ebx,(%ecx)
		page_free_list=&pages[i];
f0100e2a:	89 c1                	mov    %eax,%ecx
f0100e2c:	03 0d 88 79 11 f0    	add    0xf0117988,%ecx
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	int med = (int)ROUNDUP(((char*)pages)+(sizeof(struct Page)*npages)-0xf0000000, PGSIZE)/PGSIZE;
	for(i=med; i<npages;i++) {
f0100e32:	83 c2 01             	add    $0x1,%edx
f0100e35:	83 c0 08             	add    $0x8,%eax
f0100e38:	39 15 80 79 11 f0    	cmp    %edx,0xf0117980
f0100e3e:	76 04                	jbe    f0100e44 <page_init+0xb6>
		pages[i].pp_ref = 0;
		pages[i].pp_link=page_free_list;
		page_free_list=&pages[i];
f0100e40:	89 cb                	mov    %ecx,%ebx
f0100e42:	eb d6                	jmp    f0100e1a <page_init+0x8c>
f0100e44:	89 0d 5c 75 11 f0    	mov    %ecx,0xf011755c
	}
	cprintf("page_init returned\n");
f0100e4a:	c7 04 24 3c 49 10 f0 	movl   $0xf010493c,(%esp)
f0100e51:	e8 df 1d 00 00       	call   f0102c35 <cprintf>
}
f0100e56:	83 c4 10             	add    $0x10,%esp
f0100e59:	5b                   	pop    %ebx
f0100e5a:	5e                   	pop    %esi
f0100e5b:	5d                   	pop    %ebp
f0100e5c:	c3                   	ret    

f0100e5d <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100e5d:	55                   	push   %ebp
f0100e5e:	89 e5                	mov    %esp,%ebp
f0100e60:	53                   	push   %ebx
f0100e61:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if (page_free_list) {
f0100e64:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
f0100e6a:	85 db                	test   %ebx,%ebx
f0100e6c:	74 69                	je     f0100ed7 <page_alloc+0x7a>
		struct Page *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100e6e:	8b 03                	mov    (%ebx),%eax
f0100e70:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
		if (alloc_flags & ALLOC_ZERO)
			memset(page2kva(ret), 0, PGSIZE);
		return ret;	
f0100e75:	89 d8                	mov    %ebx,%eax
{
	// Fill this function in
	if (page_free_list) {
		struct Page *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
		if (alloc_flags & ALLOC_ZERO)
f0100e77:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e7b:	74 5f                	je     f0100edc <page_alloc+0x7f>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e7d:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100e83:	c1 f8 03             	sar    $0x3,%eax
f0100e86:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e89:	89 c2                	mov    %eax,%edx
f0100e8b:	c1 ea 0c             	shr    $0xc,%edx
f0100e8e:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100e94:	72 20                	jb     f0100eb6 <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e96:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e9a:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f0100ea1:	f0 
f0100ea2:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ea9:	00 
f0100eaa:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f0100eb1:	e8 de f1 ff ff       	call   f0100094 <_panic>
			memset(page2kva(ret), 0, PGSIZE);
f0100eb6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100ebd:	00 
f0100ebe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100ec5:	00 
	return (void *)(pa + KERNBASE);
f0100ec6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ecb:	89 04 24             	mov    %eax,(%esp)
f0100ece:	e8 fc 28 00 00       	call   f01037cf <memset>
		return ret;	
f0100ed3:	89 d8                	mov    %ebx,%eax
f0100ed5:	eb 05                	jmp    f0100edc <page_alloc+0x7f>
	}
	return 0;
f0100ed7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100edc:	83 c4 14             	add    $0x14,%esp
f0100edf:	5b                   	pop    %ebx
f0100ee0:	5d                   	pop    %ebp
f0100ee1:	c3                   	ret    

f0100ee2 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100ee2:	55                   	push   %ebp
f0100ee3:	89 e5                	mov    %esp,%ebp
f0100ee5:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f0100ee8:	8b 15 5c 75 11 f0    	mov    0xf011755c,%edx
f0100eee:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100ef0:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
}
f0100ef5:	5d                   	pop    %ebp
f0100ef6:	c3                   	ret    

f0100ef7 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100ef7:	55                   	push   %ebp
f0100ef8:	89 e5                	mov    %esp,%ebp
f0100efa:	83 ec 04             	sub    $0x4,%esp
f0100efd:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f00:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f04:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100f07:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f0b:	66 85 d2             	test   %dx,%dx
f0100f0e:	75 08                	jne    f0100f18 <page_decref+0x21>
		page_free(pp);
f0100f10:	89 04 24             	mov    %eax,(%esp)
f0100f13:	e8 ca ff ff ff       	call   f0100ee2 <page_free>
}
f0100f18:	c9                   	leave  
f0100f19:	c3                   	ret    

f0100f1a <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f1a:	55                   	push   %ebp
f0100f1b:	89 e5                	mov    %esp,%ebp
f0100f1d:	56                   	push   %esi
f0100f1e:	53                   	push   %ebx
f0100f1f:	83 ec 10             	sub    $0x10,%esp
f0100f22:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	int dindex = PDX(va), tindex = PTX(va);
f0100f25:	89 de                	mov    %ebx,%esi
f0100f27:	c1 ee 0c             	shr    $0xc,%esi
f0100f2a:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100f30:	c1 eb 16             	shr    $0x16,%ebx
	if (!(pgdir[dindex]&PTE_P))
f0100f33:	c1 e3 02             	shl    $0x2,%ebx
f0100f36:	03 5d 08             	add    0x8(%ebp),%ebx
f0100f39:	f6 03 01             	testb  $0x1,(%ebx)
f0100f3c:	75 2c                	jne    f0100f6a <pgdir_walk+0x50>
	{
		if (create)
f0100f3e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f42:	74 63                	je     f0100fa7 <pgdir_walk+0x8d>
		{
			struct Page* pg = page_alloc(ALLOC_ZERO);
f0100f44:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100f4b:	e8 0d ff ff ff       	call   f0100e5d <page_alloc>
			if (!pg)
f0100f50:	85 c0                	test   %eax,%eax
f0100f52:	74 5a                	je     f0100fae <pgdir_walk+0x94>
				return NULL;
			pg->pp_ref++;
f0100f54:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f59:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100f5f:	c1 f8 03             	sar    $0x3,%eax
f0100f62:	c1 e0 0c             	shl    $0xc,%eax
			pgdir[dindex] = page2pa(pg)|PTE_P|PTE_U|PTE_W;
f0100f65:	83 c8 07             	or     $0x7,%eax
f0100f68:	89 03                	mov    %eax,(%ebx)
		else
		{
			return NULL;
		}
	}
	pte_t *p = KADDR(PTE_ADDR(pgdir[dindex]));
f0100f6a:	8b 03                	mov    (%ebx),%eax
f0100f6c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f71:	89 c2                	mov    %eax,%edx
f0100f73:	c1 ea 0c             	shr    $0xc,%edx
f0100f76:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100f7c:	72 20                	jb     f0100f9e <pgdir_walk+0x84>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f7e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f82:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f0100f89:	f0 
f0100f8a:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f0100f91:	00 
f0100f92:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0100f99:	e8 f6 f0 ff ff       	call   f0100094 <_panic>
	return p+tindex;
f0100f9e:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100fa5:	eb 0c                	jmp    f0100fb3 <pgdir_walk+0x99>
			pg->pp_ref++;
			pgdir[dindex] = page2pa(pg)|PTE_P|PTE_U|PTE_W;
		}
		else
		{
			return NULL;
f0100fa7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fac:	eb 05                	jmp    f0100fb3 <pgdir_walk+0x99>
	{
		if (create)
		{
			struct Page* pg = page_alloc(ALLOC_ZERO);
			if (!pg)
				return NULL;
f0100fae:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
		}
	}
	pte_t *p = KADDR(PTE_ADDR(pgdir[dindex]));
	return p+tindex;
}
f0100fb3:	83 c4 10             	add    $0x10,%esp
f0100fb6:	5b                   	pop    %ebx
f0100fb7:	5e                   	pop    %esi
f0100fb8:	5d                   	pop    %ebp
f0100fb9:	c3                   	ret    

f0100fba <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100fba:	55                   	push   %ebp
f0100fbb:	89 e5                	mov    %esp,%ebp
f0100fbd:	57                   	push   %edi
f0100fbe:	56                   	push   %esi
f0100fbf:	53                   	push   %ebx
f0100fc0:	83 ec 2c             	sub    $0x2c,%esp
f0100fc3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// Fill this function in
	int i;
	for (i=0; i<size/PGSIZE; ++i, va += PGSIZE, pa +=PGSIZE)
f0100fc6:	c1 e9 0c             	shr    $0xc,%ecx
f0100fc9:	85 c9                	test   %ecx,%ecx
f0100fcb:	74 6b                	je     f0101038 <boot_map_region+0x7e>
f0100fcd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100fd0:	89 d3                	mov    %edx,%ebx
f0100fd2:	be 00 00 00 00       	mov    $0x0,%esi
f0100fd7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fda:	29 d0                	sub    %edx,%eax
f0100fdc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	{
		pte_t *pte = pgdir_walk(pgdir, (void*)va,1);
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
f0100fdf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fe2:	83 c8 01             	or     $0x1,%eax
f0100fe5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fe8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100feb:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
{
	// Fill this function in
	int i;
	for (i=0; i<size/PGSIZE; ++i, va += PGSIZE, pa +=PGSIZE)
	{
		pte_t *pte = pgdir_walk(pgdir, (void*)va,1);
f0100fee:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100ff5:	00 
f0100ff6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ffa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ffd:	89 04 24             	mov    %eax,(%esp)
f0101000:	e8 15 ff ff ff       	call   f0100f1a <pgdir_walk>
		if (!pte) panic("boot_map_region panic, out of memory");
f0101005:	85 c0                	test   %eax,%eax
f0101007:	75 1c                	jne    f0101025 <boot_map_region+0x6b>
f0101009:	c7 44 24 08 4c 42 10 	movl   $0xf010424c,0x8(%esp)
f0101010:	f0 
f0101011:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
f0101018:	00 
f0101019:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101020:	e8 6f f0 ff ff       	call   f0100094 <_panic>
		*pte = pa | perm | PTE_P;
f0101025:	0b 7d d8             	or     -0x28(%ebp),%edi
f0101028:	89 38                	mov    %edi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int i;
	for (i=0; i<size/PGSIZE; ++i, va += PGSIZE, pa +=PGSIZE)
f010102a:	83 c6 01             	add    $0x1,%esi
f010102d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101033:	3b 75 dc             	cmp    -0x24(%ebp),%esi
f0101036:	75 b0                	jne    f0100fe8 <boot_map_region+0x2e>
	{
		pte_t *pte = pgdir_walk(pgdir, (void*)va,1);
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
	}
}
f0101038:	83 c4 2c             	add    $0x2c,%esp
f010103b:	5b                   	pop    %ebx
f010103c:	5e                   	pop    %esi
f010103d:	5f                   	pop    %edi
f010103e:	5d                   	pop    %ebp
f010103f:	c3                   	ret    

f0101040 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101040:	55                   	push   %ebp
f0101041:	89 e5                	mov    %esp,%ebp
f0101043:	53                   	push   %ebx
f0101044:	83 ec 14             	sub    $0x14,%esp
f0101047:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f010104a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101051:	00 
f0101052:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101055:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101059:	8b 45 08             	mov    0x8(%ebp),%eax
f010105c:	89 04 24             	mov    %eax,(%esp)
f010105f:	e8 b6 fe ff ff       	call   f0100f1a <pgdir_walk>
	if (!pte || !(*pte & PTE_P)) return NULL;
f0101064:	85 c0                	test   %eax,%eax
f0101066:	74 40                	je     f01010a8 <page_lookup+0x68>
f0101068:	f6 00 01             	testb  $0x1,(%eax)
f010106b:	74 42                	je     f01010af <page_lookup+0x6f>
	if (pte_store)
f010106d:	85 db                	test   %ebx,%ebx
f010106f:	90                   	nop
f0101070:	74 02                	je     f0101074 <page_lookup+0x34>
		*pte_store = pte;
f0101072:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f0101074:	8b 00                	mov    (%eax),%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101076:	c1 e8 0c             	shr    $0xc,%eax
f0101079:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f010107f:	72 1c                	jb     f010109d <page_lookup+0x5d>
		panic("pa2page called with invalid pa");
f0101081:	c7 44 24 08 74 42 10 	movl   $0xf0104274,0x8(%esp)
f0101088:	f0 
f0101089:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101090:	00 
f0101091:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f0101098:	e8 f7 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010109d:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
f01010a3:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01010a6:	eb 0c                	jmp    f01010b4 <page_lookup+0x74>
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if (!pte || !(*pte & PTE_P)) return NULL;
f01010a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ad:	eb 05                	jmp    f01010b4 <page_lookup+0x74>
f01010af:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f01010b4:	83 c4 14             	add    $0x14,%esp
f01010b7:	5b                   	pop    %ebx
f01010b8:	5d                   	pop    %ebp
f01010b9:	c3                   	ret    

f01010ba <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010ba:	55                   	push   %ebp
f01010bb:	89 e5                	mov    %esp,%ebp
f01010bd:	53                   	push   %ebx
f01010be:	83 ec 24             	sub    $0x24,%esp
f01010c1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct Page *pg = page_lookup(pgdir, va, &pte);
f01010c4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010c7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010cb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01010d2:	89 04 24             	mov    %eax,(%esp)
f01010d5:	e8 66 ff ff ff       	call   f0101040 <page_lookup>
	if (!pg || !(*pte & PTE_P)) return;
f01010da:	85 c0                	test   %eax,%eax
f01010dc:	74 1c                	je     f01010fa <page_remove+0x40>
f01010de:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010e1:	f6 02 01             	testb  $0x1,(%edx)
f01010e4:	74 14                	je     f01010fa <page_remove+0x40>
	page_decref(pg);
f01010e6:	89 04 24             	mov    %eax,(%esp)
f01010e9:	e8 09 fe ff ff       	call   f0100ef7 <page_decref>
	*pte = 0;
f01010ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010f1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010f7:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f01010fa:	83 c4 24             	add    $0x24,%esp
f01010fd:	5b                   	pop    %ebx
f01010fe:	5d                   	pop    %ebp
f01010ff:	c3                   	ret    

f0101100 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101100:	55                   	push   %ebp
f0101101:	89 e5                	mov    %esp,%ebp
f0101103:	57                   	push   %edi
f0101104:	56                   	push   %esi
f0101105:	53                   	push   %ebx
f0101106:	83 ec 1c             	sub    $0x1c,%esp
f0101109:	8b 75 0c             	mov    0xc(%ebp),%esi
f010110c:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t * pte = pgdir_walk(pgdir, va, 1);
f010110f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101116:	00 
f0101117:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010111b:	8b 45 08             	mov    0x8(%ebp),%eax
f010111e:	89 04 24             	mov    %eax,(%esp)
f0101121:	e8 f4 fd ff ff       	call   f0100f1a <pgdir_walk>
f0101126:	89 c3                	mov    %eax,%ebx
	if (!pte)
f0101128:	85 c0                	test   %eax,%eax
f010112a:	74 36                	je     f0101162 <page_insert+0x62>
		return -E_NO_MEM;
	pp->pp_ref++;
f010112c:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*pte & PTE_P)
f0101131:	f6 00 01             	testb  $0x1,(%eax)
f0101134:	74 0f                	je     f0101145 <page_insert+0x45>
		page_remove(pgdir, va);
f0101136:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010113a:	8b 45 08             	mov    0x8(%ebp),%eax
f010113d:	89 04 24             	mov    %eax,(%esp)
f0101140:	e8 75 ff ff ff       	call   f01010ba <page_remove>
	*pte = page2pa(pp) | perm | PTE_P;
f0101145:	8b 45 14             	mov    0x14(%ebp),%eax
f0101148:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010114b:	2b 35 88 79 11 f0    	sub    0xf0117988,%esi
f0101151:	c1 fe 03             	sar    $0x3,%esi
f0101154:	c1 e6 0c             	shl    $0xc,%esi
f0101157:	09 c6                	or     %eax,%esi
f0101159:	89 33                	mov    %esi,(%ebx)
	return 0;
f010115b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101160:	eb 05                	jmp    f0101167 <page_insert+0x67>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
	// Fill this function in
	pte_t * pte = pgdir_walk(pgdir, va, 1);
	if (!pte)
		return -E_NO_MEM;
f0101162:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;
	if (*pte & PTE_P)
		page_remove(pgdir, va);
	*pte = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0101167:	83 c4 1c             	add    $0x1c,%esp
f010116a:	5b                   	pop    %ebx
f010116b:	5e                   	pop    %esi
f010116c:	5f                   	pop    %edi
f010116d:	5d                   	pop    %ebp
f010116e:	c3                   	ret    

f010116f <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010116f:	55                   	push   %ebp
f0101170:	89 e5                	mov    %esp,%ebp
f0101172:	57                   	push   %edi
f0101173:	56                   	push   %esi
f0101174:	53                   	push   %ebx
f0101175:	83 ec 3c             	sub    $0x3c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101178:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f010117f:	e8 41 1a 00 00       	call   f0102bc5 <mc146818_read>
f0101184:	89 c3                	mov    %eax,%ebx
f0101186:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010118d:	e8 33 1a 00 00       	call   f0102bc5 <mc146818_read>
f0101192:	c1 e0 08             	shl    $0x8,%eax
f0101195:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101197:	89 d8                	mov    %ebx,%eax
f0101199:	c1 e0 0a             	shl    $0xa,%eax
f010119c:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011a2:	85 c0                	test   %eax,%eax
f01011a4:	0f 48 c2             	cmovs  %edx,%eax
f01011a7:	c1 f8 0c             	sar    $0xc,%eax
f01011aa:	a3 60 75 11 f0       	mov    %eax,0xf0117560
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01011af:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01011b6:	e8 0a 1a 00 00       	call   f0102bc5 <mc146818_read>
f01011bb:	89 c3                	mov    %eax,%ebx
f01011bd:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01011c4:	e8 fc 19 00 00       	call   f0102bc5 <mc146818_read>
f01011c9:	c1 e0 08             	shl    $0x8,%eax
f01011cc:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01011ce:	89 d8                	mov    %ebx,%eax
f01011d0:	c1 e0 0a             	shl    $0xa,%eax
f01011d3:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011d9:	85 c0                	test   %eax,%eax
f01011db:	0f 48 c2             	cmovs  %edx,%eax
f01011de:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01011e1:	85 c0                	test   %eax,%eax
f01011e3:	74 0e                	je     f01011f3 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01011e5:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01011eb:	89 15 80 79 11 f0    	mov    %edx,0xf0117980
f01011f1:	eb 0c                	jmp    f01011ff <mem_init+0x90>
	else
		npages = npages_basemem;
f01011f3:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f01011f9:	89 15 80 79 11 f0    	mov    %edx,0xf0117980

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01011ff:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101202:	c1 e8 0a             	shr    $0xa,%eax
f0101205:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101209:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f010120e:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101211:	c1 e8 0a             	shr    $0xa,%eax
f0101214:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101218:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f010121d:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101220:	c1 e8 0a             	shr    $0xa,%eax
f0101223:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101227:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010122e:	e8 02 1a 00 00       	call   f0102c35 <cprintf>
	// Remove this line when you're ready to test this function.
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101233:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101238:	e8 e3 f6 ff ff       	call   f0100920 <boot_alloc>
f010123d:	a3 84 79 11 f0       	mov    %eax,0xf0117984
	memset(kern_pgdir, 0, PGSIZE);
f0101242:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101249:	00 
f010124a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101251:	00 
f0101252:	89 04 24             	mov    %eax,(%esp)
f0101255:	e8 75 25 00 00       	call   f01037cf <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010125a:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010125f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101264:	77 20                	ja     f0101286 <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101266:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010126a:	c7 44 24 08 d0 42 10 	movl   $0xf01042d0,0x8(%esp)
f0101271:	f0 
f0101272:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f0101279:	00 
f010127a:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101281:	e8 0e ee ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101286:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010128c:	83 ca 05             	or     $0x5,%edx
f010128f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page*) boot_alloc(sizeof(struct Page) * npages);
f0101295:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f010129a:	c1 e0 03             	shl    $0x3,%eax
f010129d:	e8 7e f6 ff ff       	call   f0100920 <boot_alloc>
f01012a2:	a3 88 79 11 f0       	mov    %eax,0xf0117988
	cprintf("npages: %d\n", npages);
f01012a7:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f01012ac:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012b0:	c7 04 24 50 49 10 f0 	movl   $0xf0104950,(%esp)
f01012b7:	e8 79 19 00 00       	call   f0102c35 <cprintf>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012bc:	e8 cd fa ff ff       	call   f0100d8e <page_init>

	check_page_free_list(1);
f01012c1:	b8 01 00 00 00       	mov    $0x1,%eax
f01012c6:	e8 45 f7 ff ff       	call   f0100a10 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01012cb:	83 3d 88 79 11 f0 00 	cmpl   $0x0,0xf0117988
f01012d2:	75 1c                	jne    f01012f0 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f01012d4:	c7 44 24 08 5c 49 10 	movl   $0xf010495c,0x8(%esp)
f01012db:	f0 
f01012dc:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f01012e3:	00 
f01012e4:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01012eb:	e8 a4 ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012f0:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f01012f5:	85 c0                	test   %eax,%eax
f01012f7:	74 10                	je     f0101309 <mem_init+0x19a>
f01012f9:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f01012fe:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101301:	8b 00                	mov    (%eax),%eax
f0101303:	85 c0                	test   %eax,%eax
f0101305:	75 f7                	jne    f01012fe <mem_init+0x18f>
f0101307:	eb 05                	jmp    f010130e <mem_init+0x19f>
f0101309:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010130e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101315:	e8 43 fb ff ff       	call   f0100e5d <page_alloc>
f010131a:	89 c7                	mov    %eax,%edi
f010131c:	85 c0                	test   %eax,%eax
f010131e:	75 24                	jne    f0101344 <mem_init+0x1d5>
f0101320:	c7 44 24 0c 77 49 10 	movl   $0xf0104977,0xc(%esp)
f0101327:	f0 
f0101328:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010132f:	f0 
f0101330:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f0101337:	00 
f0101338:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010133f:	e8 50 ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101344:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010134b:	e8 0d fb ff ff       	call   f0100e5d <page_alloc>
f0101350:	89 c6                	mov    %eax,%esi
f0101352:	85 c0                	test   %eax,%eax
f0101354:	75 24                	jne    f010137a <mem_init+0x20b>
f0101356:	c7 44 24 0c 8d 49 10 	movl   $0xf010498d,0xc(%esp)
f010135d:	f0 
f010135e:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101365:	f0 
f0101366:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f010136d:	00 
f010136e:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101375:	e8 1a ed ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010137a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101381:	e8 d7 fa ff ff       	call   f0100e5d <page_alloc>
f0101386:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101389:	85 c0                	test   %eax,%eax
f010138b:	75 24                	jne    f01013b1 <mem_init+0x242>
f010138d:	c7 44 24 0c a3 49 10 	movl   $0xf01049a3,0xc(%esp)
f0101394:	f0 
f0101395:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010139c:	f0 
f010139d:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
f01013a4:	00 
f01013a5:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01013ac:	e8 e3 ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013b1:	39 f7                	cmp    %esi,%edi
f01013b3:	75 24                	jne    f01013d9 <mem_init+0x26a>
f01013b5:	c7 44 24 0c b9 49 10 	movl   $0xf01049b9,0xc(%esp)
f01013bc:	f0 
f01013bd:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01013c4:	f0 
f01013c5:	c7 44 24 04 48 02 00 	movl   $0x248,0x4(%esp)
f01013cc:	00 
f01013cd:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01013d4:	e8 bb ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013d9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013dc:	39 c6                	cmp    %eax,%esi
f01013de:	74 04                	je     f01013e4 <mem_init+0x275>
f01013e0:	39 c7                	cmp    %eax,%edi
f01013e2:	75 24                	jne    f0101408 <mem_init+0x299>
f01013e4:	c7 44 24 0c f4 42 10 	movl   $0xf01042f4,0xc(%esp)
f01013eb:	f0 
f01013ec:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01013f3:	f0 
f01013f4:	c7 44 24 04 49 02 00 	movl   $0x249,0x4(%esp)
f01013fb:	00 
f01013fc:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101403:	e8 8c ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101408:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010140e:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0101413:	c1 e0 0c             	shl    $0xc,%eax
f0101416:	89 f9                	mov    %edi,%ecx
f0101418:	29 d1                	sub    %edx,%ecx
f010141a:	c1 f9 03             	sar    $0x3,%ecx
f010141d:	c1 e1 0c             	shl    $0xc,%ecx
f0101420:	39 c1                	cmp    %eax,%ecx
f0101422:	72 24                	jb     f0101448 <mem_init+0x2d9>
f0101424:	c7 44 24 0c cb 49 10 	movl   $0xf01049cb,0xc(%esp)
f010142b:	f0 
f010142c:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101433:	f0 
f0101434:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
f010143b:	00 
f010143c:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101443:	e8 4c ec ff ff       	call   f0100094 <_panic>
f0101448:	89 f1                	mov    %esi,%ecx
f010144a:	29 d1                	sub    %edx,%ecx
f010144c:	c1 f9 03             	sar    $0x3,%ecx
f010144f:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101452:	39 c8                	cmp    %ecx,%eax
f0101454:	77 24                	ja     f010147a <mem_init+0x30b>
f0101456:	c7 44 24 0c e8 49 10 	movl   $0xf01049e8,0xc(%esp)
f010145d:	f0 
f010145e:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101465:	f0 
f0101466:	c7 44 24 04 4b 02 00 	movl   $0x24b,0x4(%esp)
f010146d:	00 
f010146e:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101475:	e8 1a ec ff ff       	call   f0100094 <_panic>
f010147a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010147d:	29 d1                	sub    %edx,%ecx
f010147f:	89 ca                	mov    %ecx,%edx
f0101481:	c1 fa 03             	sar    $0x3,%edx
f0101484:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101487:	39 d0                	cmp    %edx,%eax
f0101489:	77 24                	ja     f01014af <mem_init+0x340>
f010148b:	c7 44 24 0c 05 4a 10 	movl   $0xf0104a05,0xc(%esp)
f0101492:	f0 
f0101493:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010149a:	f0 
f010149b:	c7 44 24 04 4c 02 00 	movl   $0x24c,0x4(%esp)
f01014a2:	00 
f01014a3:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01014aa:	e8 e5 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014af:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f01014b4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014b7:	c7 05 5c 75 11 f0 00 	movl   $0x0,0xf011755c
f01014be:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014c8:	e8 90 f9 ff ff       	call   f0100e5d <page_alloc>
f01014cd:	85 c0                	test   %eax,%eax
f01014cf:	74 24                	je     f01014f5 <mem_init+0x386>
f01014d1:	c7 44 24 0c 22 4a 10 	movl   $0xf0104a22,0xc(%esp)
f01014d8:	f0 
f01014d9:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01014e0:	f0 
f01014e1:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f01014e8:	00 
f01014e9:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01014f0:	e8 9f eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01014f5:	89 3c 24             	mov    %edi,(%esp)
f01014f8:	e8 e5 f9 ff ff       	call   f0100ee2 <page_free>
	page_free(pp1);
f01014fd:	89 34 24             	mov    %esi,(%esp)
f0101500:	e8 dd f9 ff ff       	call   f0100ee2 <page_free>
	page_free(pp2);
f0101505:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101508:	89 04 24             	mov    %eax,(%esp)
f010150b:	e8 d2 f9 ff ff       	call   f0100ee2 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101510:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101517:	e8 41 f9 ff ff       	call   f0100e5d <page_alloc>
f010151c:	89 c6                	mov    %eax,%esi
f010151e:	85 c0                	test   %eax,%eax
f0101520:	75 24                	jne    f0101546 <mem_init+0x3d7>
f0101522:	c7 44 24 0c 77 49 10 	movl   $0xf0104977,0xc(%esp)
f0101529:	f0 
f010152a:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101531:	f0 
f0101532:	c7 44 24 04 5a 02 00 	movl   $0x25a,0x4(%esp)
f0101539:	00 
f010153a:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101541:	e8 4e eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101546:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010154d:	e8 0b f9 ff ff       	call   f0100e5d <page_alloc>
f0101552:	89 c7                	mov    %eax,%edi
f0101554:	85 c0                	test   %eax,%eax
f0101556:	75 24                	jne    f010157c <mem_init+0x40d>
f0101558:	c7 44 24 0c 8d 49 10 	movl   $0xf010498d,0xc(%esp)
f010155f:	f0 
f0101560:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101567:	f0 
f0101568:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f010156f:	00 
f0101570:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101577:	e8 18 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010157c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101583:	e8 d5 f8 ff ff       	call   f0100e5d <page_alloc>
f0101588:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010158b:	85 c0                	test   %eax,%eax
f010158d:	75 24                	jne    f01015b3 <mem_init+0x444>
f010158f:	c7 44 24 0c a3 49 10 	movl   $0xf01049a3,0xc(%esp)
f0101596:	f0 
f0101597:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010159e:	f0 
f010159f:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
f01015a6:	00 
f01015a7:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01015ae:	e8 e1 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015b3:	39 fe                	cmp    %edi,%esi
f01015b5:	75 24                	jne    f01015db <mem_init+0x46c>
f01015b7:	c7 44 24 0c b9 49 10 	movl   $0xf01049b9,0xc(%esp)
f01015be:	f0 
f01015bf:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01015c6:	f0 
f01015c7:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f01015ce:	00 
f01015cf:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01015d6:	e8 b9 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015db:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015de:	39 c7                	cmp    %eax,%edi
f01015e0:	74 04                	je     f01015e6 <mem_init+0x477>
f01015e2:	39 c6                	cmp    %eax,%esi
f01015e4:	75 24                	jne    f010160a <mem_init+0x49b>
f01015e6:	c7 44 24 0c f4 42 10 	movl   $0xf01042f4,0xc(%esp)
f01015ed:	f0 
f01015ee:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01015f5:	f0 
f01015f6:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f01015fd:	00 
f01015fe:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101605:	e8 8a ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f010160a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101611:	e8 47 f8 ff ff       	call   f0100e5d <page_alloc>
f0101616:	85 c0                	test   %eax,%eax
f0101618:	74 24                	je     f010163e <mem_init+0x4cf>
f010161a:	c7 44 24 0c 22 4a 10 	movl   $0xf0104a22,0xc(%esp)
f0101621:	f0 
f0101622:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101629:	f0 
f010162a:	c7 44 24 04 60 02 00 	movl   $0x260,0x4(%esp)
f0101631:	00 
f0101632:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101639:	e8 56 ea ff ff       	call   f0100094 <_panic>
f010163e:	89 f0                	mov    %esi,%eax
f0101640:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0101646:	c1 f8 03             	sar    $0x3,%eax
f0101649:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010164c:	89 c2                	mov    %eax,%edx
f010164e:	c1 ea 0c             	shr    $0xc,%edx
f0101651:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0101657:	72 20                	jb     f0101679 <mem_init+0x50a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101659:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010165d:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f0101664:	f0 
f0101665:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010166c:	00 
f010166d:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f0101674:	e8 1b ea ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101679:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101680:	00 
f0101681:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101688:	00 
	return (void *)(pa + KERNBASE);
f0101689:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010168e:	89 04 24             	mov    %eax,(%esp)
f0101691:	e8 39 21 00 00       	call   f01037cf <memset>
	page_free(pp0);
f0101696:	89 34 24             	mov    %esi,(%esp)
f0101699:	e8 44 f8 ff ff       	call   f0100ee2 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010169e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016a5:	e8 b3 f7 ff ff       	call   f0100e5d <page_alloc>
f01016aa:	85 c0                	test   %eax,%eax
f01016ac:	75 24                	jne    f01016d2 <mem_init+0x563>
f01016ae:	c7 44 24 0c 31 4a 10 	movl   $0xf0104a31,0xc(%esp)
f01016b5:	f0 
f01016b6:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01016bd:	f0 
f01016be:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f01016c5:	00 
f01016c6:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01016cd:	e8 c2 e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01016d2:	39 c6                	cmp    %eax,%esi
f01016d4:	74 24                	je     f01016fa <mem_init+0x58b>
f01016d6:	c7 44 24 0c 4f 4a 10 	movl   $0xf0104a4f,0xc(%esp)
f01016dd:	f0 
f01016de:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01016e5:	f0 
f01016e6:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f01016ed:	00 
f01016ee:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01016f5:	e8 9a e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01016fa:	89 f2                	mov    %esi,%edx
f01016fc:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101702:	c1 fa 03             	sar    $0x3,%edx
f0101705:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101708:	89 d0                	mov    %edx,%eax
f010170a:	c1 e8 0c             	shr    $0xc,%eax
f010170d:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0101713:	72 20                	jb     f0101735 <mem_init+0x5c6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101715:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101719:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f0101720:	f0 
f0101721:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101728:	00 
f0101729:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f0101730:	e8 5f e9 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101735:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f010173c:	75 11                	jne    f010174f <mem_init+0x5e0>
f010173e:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
f0101744:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f010174a:	80 38 00             	cmpb   $0x0,(%eax)
f010174d:	74 24                	je     f0101773 <mem_init+0x604>
f010174f:	c7 44 24 0c 5f 4a 10 	movl   $0xf0104a5f,0xc(%esp)
f0101756:	f0 
f0101757:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010175e:	f0 
f010175f:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f0101766:	00 
f0101767:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010176e:	e8 21 e9 ff ff       	call   f0100094 <_panic>
f0101773:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101776:	39 d0                	cmp    %edx,%eax
f0101778:	75 d0                	jne    f010174a <mem_init+0x5db>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010177a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010177d:	a3 5c 75 11 f0       	mov    %eax,0xf011755c

	// free the pages we took
	page_free(pp0);
f0101782:	89 34 24             	mov    %esi,(%esp)
f0101785:	e8 58 f7 ff ff       	call   f0100ee2 <page_free>
	page_free(pp1);
f010178a:	89 3c 24             	mov    %edi,(%esp)
f010178d:	e8 50 f7 ff ff       	call   f0100ee2 <page_free>
	page_free(pp2);
f0101792:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101795:	89 04 24             	mov    %eax,(%esp)
f0101798:	e8 45 f7 ff ff       	call   f0100ee2 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010179d:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f01017a2:	85 c0                	test   %eax,%eax
f01017a4:	74 09                	je     f01017af <mem_init+0x640>
		--nfree;
f01017a6:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017a9:	8b 00                	mov    (%eax),%eax
f01017ab:	85 c0                	test   %eax,%eax
f01017ad:	75 f7                	jne    f01017a6 <mem_init+0x637>
		--nfree;
	assert(nfree == 0);
f01017af:	85 db                	test   %ebx,%ebx
f01017b1:	74 24                	je     f01017d7 <mem_init+0x668>
f01017b3:	c7 44 24 0c 69 4a 10 	movl   $0xf0104a69,0xc(%esp)
f01017ba:	f0 
f01017bb:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01017c2:	f0 
f01017c3:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f01017ca:	00 
f01017cb:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01017d2:	e8 bd e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017d7:	c7 04 24 14 43 10 f0 	movl   $0xf0104314,(%esp)
f01017de:	e8 52 14 00 00       	call   f0102c35 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017ea:	e8 6e f6 ff ff       	call   f0100e5d <page_alloc>
f01017ef:	89 c3                	mov    %eax,%ebx
f01017f1:	85 c0                	test   %eax,%eax
f01017f3:	75 24                	jne    f0101819 <mem_init+0x6aa>
f01017f5:	c7 44 24 0c 77 49 10 	movl   $0xf0104977,0xc(%esp)
f01017fc:	f0 
f01017fd:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101804:	f0 
f0101805:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f010180c:	00 
f010180d:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101814:	e8 7b e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101819:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101820:	e8 38 f6 ff ff       	call   f0100e5d <page_alloc>
f0101825:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101828:	85 c0                	test   %eax,%eax
f010182a:	75 24                	jne    f0101850 <mem_init+0x6e1>
f010182c:	c7 44 24 0c 8d 49 10 	movl   $0xf010498d,0xc(%esp)
f0101833:	f0 
f0101834:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010183b:	f0 
f010183c:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
f0101843:	00 
f0101844:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010184b:	e8 44 e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101850:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101857:	e8 01 f6 ff ff       	call   f0100e5d <page_alloc>
f010185c:	89 c6                	mov    %eax,%esi
f010185e:	85 c0                	test   %eax,%eax
f0101860:	75 24                	jne    f0101886 <mem_init+0x717>
f0101862:	c7 44 24 0c a3 49 10 	movl   $0xf01049a3,0xc(%esp)
f0101869:	f0 
f010186a:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101871:	f0 
f0101872:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f0101879:	00 
f010187a:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101881:	e8 0e e8 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101886:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101889:	75 24                	jne    f01018af <mem_init+0x740>
f010188b:	c7 44 24 0c b9 49 10 	movl   $0xf01049b9,0xc(%esp)
f0101892:	f0 
f0101893:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010189a:	f0 
f010189b:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f01018a2:	00 
f01018a3:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01018aa:	e8 e5 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018af:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018b2:	74 04                	je     f01018b8 <mem_init+0x749>
f01018b4:	39 c3                	cmp    %eax,%ebx
f01018b6:	75 24                	jne    f01018dc <mem_init+0x76d>
f01018b8:	c7 44 24 0c f4 42 10 	movl   $0xf01042f4,0xc(%esp)
f01018bf:	f0 
f01018c0:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01018c7:	f0 
f01018c8:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f01018cf:	00 
f01018d0:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01018d7:	e8 b8 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018dc:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f01018e1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018e4:	c7 05 5c 75 11 f0 00 	movl   $0x0,0xf011755c
f01018eb:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018f5:	e8 63 f5 ff ff       	call   f0100e5d <page_alloc>
f01018fa:	85 c0                	test   %eax,%eax
f01018fc:	74 24                	je     f0101922 <mem_init+0x7b3>
f01018fe:	c7 44 24 0c 22 4a 10 	movl   $0xf0104a22,0xc(%esp)
f0101905:	f0 
f0101906:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010190d:	f0 
f010190e:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0101915:	00 
f0101916:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010191d:	e8 72 e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101922:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101925:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101929:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101930:	00 
f0101931:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101936:	89 04 24             	mov    %eax,(%esp)
f0101939:	e8 02 f7 ff ff       	call   f0101040 <page_lookup>
f010193e:	85 c0                	test   %eax,%eax
f0101940:	74 24                	je     f0101966 <mem_init+0x7f7>
f0101942:	c7 44 24 0c 34 43 10 	movl   $0xf0104334,0xc(%esp)
f0101949:	f0 
f010194a:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101951:	f0 
f0101952:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f0101959:	00 
f010195a:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101961:	e8 2e e7 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101966:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010196d:	00 
f010196e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101975:	00 
f0101976:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101979:	89 44 24 04          	mov    %eax,0x4(%esp)
f010197d:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101982:	89 04 24             	mov    %eax,(%esp)
f0101985:	e8 76 f7 ff ff       	call   f0101100 <page_insert>
f010198a:	85 c0                	test   %eax,%eax
f010198c:	78 24                	js     f01019b2 <mem_init+0x843>
f010198e:	c7 44 24 0c 6c 43 10 	movl   $0xf010436c,0xc(%esp)
f0101995:	f0 
f0101996:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010199d:	f0 
f010199e:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f01019a5:	00 
f01019a6:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01019ad:	e8 e2 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019b2:	89 1c 24             	mov    %ebx,(%esp)
f01019b5:	e8 28 f5 ff ff       	call   f0100ee2 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019ba:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019c1:	00 
f01019c2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019c9:	00 
f01019ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019d1:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01019d6:	89 04 24             	mov    %eax,(%esp)
f01019d9:	e8 22 f7 ff ff       	call   f0101100 <page_insert>
f01019de:	85 c0                	test   %eax,%eax
f01019e0:	74 24                	je     f0101a06 <mem_init+0x897>
f01019e2:	c7 44 24 0c 9c 43 10 	movl   $0xf010439c,0xc(%esp)
f01019e9:	f0 
f01019ea:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01019f1:	f0 
f01019f2:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f01019f9:	00 
f01019fa:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101a01:	e8 8e e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a06:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a0c:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0101a11:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a14:	8b 17                	mov    (%edi),%edx
f0101a16:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a1c:	89 d9                	mov    %ebx,%ecx
f0101a1e:	29 c1                	sub    %eax,%ecx
f0101a20:	89 c8                	mov    %ecx,%eax
f0101a22:	c1 f8 03             	sar    $0x3,%eax
f0101a25:	c1 e0 0c             	shl    $0xc,%eax
f0101a28:	39 c2                	cmp    %eax,%edx
f0101a2a:	74 24                	je     f0101a50 <mem_init+0x8e1>
f0101a2c:	c7 44 24 0c cc 43 10 	movl   $0xf01043cc,0xc(%esp)
f0101a33:	f0 
f0101a34:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101a3b:	f0 
f0101a3c:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
f0101a43:	00 
f0101a44:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101a4b:	e8 44 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a50:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a55:	89 f8                	mov    %edi,%eax
f0101a57:	e8 45 ef ff ff       	call   f01009a1 <check_va2pa>
f0101a5c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101a5f:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a62:	c1 fa 03             	sar    $0x3,%edx
f0101a65:	c1 e2 0c             	shl    $0xc,%edx
f0101a68:	39 d0                	cmp    %edx,%eax
f0101a6a:	74 24                	je     f0101a90 <mem_init+0x921>
f0101a6c:	c7 44 24 0c f4 43 10 	movl   $0xf01043f4,0xc(%esp)
f0101a73:	f0 
f0101a74:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101a7b:	f0 
f0101a7c:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
f0101a83:	00 
f0101a84:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101a8b:	e8 04 e6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101a90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a93:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a98:	74 24                	je     f0101abe <mem_init+0x94f>
f0101a9a:	c7 44 24 0c 74 4a 10 	movl   $0xf0104a74,0xc(%esp)
f0101aa1:	f0 
f0101aa2:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101aa9:	f0 
f0101aaa:	c7 44 24 04 e9 02 00 	movl   $0x2e9,0x4(%esp)
f0101ab1:	00 
f0101ab2:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101ab9:	e8 d6 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101abe:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ac3:	74 24                	je     f0101ae9 <mem_init+0x97a>
f0101ac5:	c7 44 24 0c 85 4a 10 	movl   $0xf0104a85,0xc(%esp)
f0101acc:	f0 
f0101acd:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101ad4:	f0 
f0101ad5:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0101adc:	00 
f0101add:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101ae4:	e8 ab e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ae9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101af0:	00 
f0101af1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101af8:	00 
f0101af9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101afd:	89 3c 24             	mov    %edi,(%esp)
f0101b00:	e8 fb f5 ff ff       	call   f0101100 <page_insert>
f0101b05:	85 c0                	test   %eax,%eax
f0101b07:	74 24                	je     f0101b2d <mem_init+0x9be>
f0101b09:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f0101b10:	f0 
f0101b11:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101b18:	f0 
f0101b19:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0101b20:	00 
f0101b21:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101b28:	e8 67 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b2d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b32:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101b37:	e8 65 ee ff ff       	call   f01009a1 <check_va2pa>
f0101b3c:	89 f2                	mov    %esi,%edx
f0101b3e:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101b44:	c1 fa 03             	sar    $0x3,%edx
f0101b47:	c1 e2 0c             	shl    $0xc,%edx
f0101b4a:	39 d0                	cmp    %edx,%eax
f0101b4c:	74 24                	je     f0101b72 <mem_init+0xa03>
f0101b4e:	c7 44 24 0c 60 44 10 	movl   $0xf0104460,0xc(%esp)
f0101b55:	f0 
f0101b56:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101b5d:	f0 
f0101b5e:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f0101b65:	00 
f0101b66:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101b6d:	e8 22 e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b72:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b77:	74 24                	je     f0101b9d <mem_init+0xa2e>
f0101b79:	c7 44 24 0c 96 4a 10 	movl   $0xf0104a96,0xc(%esp)
f0101b80:	f0 
f0101b81:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101b88:	f0 
f0101b89:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f0101b90:	00 
f0101b91:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101b98:	e8 f7 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b9d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ba4:	e8 b4 f2 ff ff       	call   f0100e5d <page_alloc>
f0101ba9:	85 c0                	test   %eax,%eax
f0101bab:	74 24                	je     f0101bd1 <mem_init+0xa62>
f0101bad:	c7 44 24 0c 22 4a 10 	movl   $0xf0104a22,0xc(%esp)
f0101bb4:	f0 
f0101bb5:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101bbc:	f0 
f0101bbd:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f0101bc4:	00 
f0101bc5:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101bcc:	e8 c3 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bd1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bd8:	00 
f0101bd9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101be0:	00 
f0101be1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101be5:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101bea:	89 04 24             	mov    %eax,(%esp)
f0101bed:	e8 0e f5 ff ff       	call   f0101100 <page_insert>
f0101bf2:	85 c0                	test   %eax,%eax
f0101bf4:	74 24                	je     f0101c1a <mem_init+0xaab>
f0101bf6:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f0101bfd:	f0 
f0101bfe:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101c05:	f0 
f0101c06:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f0101c0d:	00 
f0101c0e:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101c15:	e8 7a e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c1a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c1f:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101c24:	e8 78 ed ff ff       	call   f01009a1 <check_va2pa>
f0101c29:	89 f2                	mov    %esi,%edx
f0101c2b:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101c31:	c1 fa 03             	sar    $0x3,%edx
f0101c34:	c1 e2 0c             	shl    $0xc,%edx
f0101c37:	39 d0                	cmp    %edx,%eax
f0101c39:	74 24                	je     f0101c5f <mem_init+0xaf0>
f0101c3b:	c7 44 24 0c 60 44 10 	movl   $0xf0104460,0xc(%esp)
f0101c42:	f0 
f0101c43:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101c4a:	f0 
f0101c4b:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f0101c52:	00 
f0101c53:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101c5a:	e8 35 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c5f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c64:	74 24                	je     f0101c8a <mem_init+0xb1b>
f0101c66:	c7 44 24 0c 96 4a 10 	movl   $0xf0104a96,0xc(%esp)
f0101c6d:	f0 
f0101c6e:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101c75:	f0 
f0101c76:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0101c7d:	00 
f0101c7e:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101c85:	e8 0a e4 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c8a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c91:	e8 c7 f1 ff ff       	call   f0100e5d <page_alloc>
f0101c96:	85 c0                	test   %eax,%eax
f0101c98:	74 24                	je     f0101cbe <mem_init+0xb4f>
f0101c9a:	c7 44 24 0c 22 4a 10 	movl   $0xf0104a22,0xc(%esp)
f0101ca1:	f0 
f0101ca2:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101ca9:	f0 
f0101caa:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0101cb1:	00 
f0101cb2:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101cb9:	e8 d6 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cbe:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f0101cc4:	8b 02                	mov    (%edx),%eax
f0101cc6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ccb:	89 c1                	mov    %eax,%ecx
f0101ccd:	c1 e9 0c             	shr    $0xc,%ecx
f0101cd0:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f0101cd6:	72 20                	jb     f0101cf8 <mem_init+0xb89>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cd8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101cdc:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f0101ce3:	f0 
f0101ce4:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
f0101ceb:	00 
f0101cec:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101cf3:	e8 9c e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101cf8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101cfd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d00:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d07:	00 
f0101d08:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d0f:	00 
f0101d10:	89 14 24             	mov    %edx,(%esp)
f0101d13:	e8 02 f2 ff ff       	call   f0100f1a <pgdir_walk>
f0101d18:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d1b:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d1e:	39 d0                	cmp    %edx,%eax
f0101d20:	74 24                	je     f0101d46 <mem_init+0xbd7>
f0101d22:	c7 44 24 0c 90 44 10 	movl   $0xf0104490,0xc(%esp)
f0101d29:	f0 
f0101d2a:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101d31:	f0 
f0101d32:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0101d39:	00 
f0101d3a:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101d41:	e8 4e e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d46:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d4d:	00 
f0101d4e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d55:	00 
f0101d56:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d5a:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101d5f:	89 04 24             	mov    %eax,(%esp)
f0101d62:	e8 99 f3 ff ff       	call   f0101100 <page_insert>
f0101d67:	85 c0                	test   %eax,%eax
f0101d69:	74 24                	je     f0101d8f <mem_init+0xc20>
f0101d6b:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f0101d72:	f0 
f0101d73:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101d7a:	f0 
f0101d7b:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101d82:	00 
f0101d83:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101d8a:	e8 05 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d8f:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0101d95:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d9a:	89 f8                	mov    %edi,%eax
f0101d9c:	e8 00 ec ff ff       	call   f01009a1 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101da1:	89 f2                	mov    %esi,%edx
f0101da3:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101da9:	c1 fa 03             	sar    $0x3,%edx
f0101dac:	c1 e2 0c             	shl    $0xc,%edx
f0101daf:	39 d0                	cmp    %edx,%eax
f0101db1:	74 24                	je     f0101dd7 <mem_init+0xc68>
f0101db3:	c7 44 24 0c 60 44 10 	movl   $0xf0104460,0xc(%esp)
f0101dba:	f0 
f0101dbb:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101dc2:	f0 
f0101dc3:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101dca:	00 
f0101dcb:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101dd2:	e8 bd e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101dd7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ddc:	74 24                	je     f0101e02 <mem_init+0xc93>
f0101dde:	c7 44 24 0c 96 4a 10 	movl   $0xf0104a96,0xc(%esp)
f0101de5:	f0 
f0101de6:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101ded:	f0 
f0101dee:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101df5:	00 
f0101df6:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101dfd:	e8 92 e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e02:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e09:	00 
f0101e0a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e11:	00 
f0101e12:	89 3c 24             	mov    %edi,(%esp)
f0101e15:	e8 00 f1 ff ff       	call   f0100f1a <pgdir_walk>
f0101e1a:	f6 00 04             	testb  $0x4,(%eax)
f0101e1d:	75 24                	jne    f0101e43 <mem_init+0xcd4>
f0101e1f:	c7 44 24 0c 10 45 10 	movl   $0xf0104510,0xc(%esp)
f0101e26:	f0 
f0101e27:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101e2e:	f0 
f0101e2f:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101e36:	00 
f0101e37:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101e3e:	e8 51 e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e43:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101e48:	f6 00 04             	testb  $0x4,(%eax)
f0101e4b:	75 24                	jne    f0101e71 <mem_init+0xd02>
f0101e4d:	c7 44 24 0c a7 4a 10 	movl   $0xf0104aa7,0xc(%esp)
f0101e54:	f0 
f0101e55:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101e5c:	f0 
f0101e5d:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101e64:	00 
f0101e65:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101e6c:	e8 23 e2 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e71:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e78:	00 
f0101e79:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101e80:	00 
f0101e81:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e85:	89 04 24             	mov    %eax,(%esp)
f0101e88:	e8 73 f2 ff ff       	call   f0101100 <page_insert>
f0101e8d:	85 c0                	test   %eax,%eax
f0101e8f:	78 24                	js     f0101eb5 <mem_init+0xd46>
f0101e91:	c7 44 24 0c 44 45 10 	movl   $0xf0104544,0xc(%esp)
f0101e98:	f0 
f0101e99:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101ea0:	f0 
f0101ea1:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101ea8:	00 
f0101ea9:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101eb0:	e8 df e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101eb5:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ebc:	00 
f0101ebd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ec4:	00 
f0101ec5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ec8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ecc:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101ed1:	89 04 24             	mov    %eax,(%esp)
f0101ed4:	e8 27 f2 ff ff       	call   f0101100 <page_insert>
f0101ed9:	85 c0                	test   %eax,%eax
f0101edb:	74 24                	je     f0101f01 <mem_init+0xd92>
f0101edd:	c7 44 24 0c 7c 45 10 	movl   $0xf010457c,0xc(%esp)
f0101ee4:	f0 
f0101ee5:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101eec:	f0 
f0101eed:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0101ef4:	00 
f0101ef5:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101efc:	e8 93 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f01:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f08:	00 
f0101f09:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f10:	00 
f0101f11:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101f16:	89 04 24             	mov    %eax,(%esp)
f0101f19:	e8 fc ef ff ff       	call   f0100f1a <pgdir_walk>
f0101f1e:	f6 00 04             	testb  $0x4,(%eax)
f0101f21:	74 24                	je     f0101f47 <mem_init+0xdd8>
f0101f23:	c7 44 24 0c b8 45 10 	movl   $0xf01045b8,0xc(%esp)
f0101f2a:	f0 
f0101f2b:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101f32:	f0 
f0101f33:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101f3a:	00 
f0101f3b:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101f42:	e8 4d e1 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101f47:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0101f4d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f52:	89 f8                	mov    %edi,%eax
f0101f54:	e8 48 ea ff ff       	call   f01009a1 <check_va2pa>
f0101f59:	89 c1                	mov    %eax,%ecx
f0101f5b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f5e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f61:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0101f67:	c1 f8 03             	sar    $0x3,%eax
f0101f6a:	c1 e0 0c             	shl    $0xc,%eax
f0101f6d:	39 c1                	cmp    %eax,%ecx
f0101f6f:	74 24                	je     f0101f95 <mem_init+0xe26>
f0101f71:	c7 44 24 0c f0 45 10 	movl   $0xf01045f0,0xc(%esp)
f0101f78:	f0 
f0101f79:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101f80:	f0 
f0101f81:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101f88:	00 
f0101f89:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101f90:	e8 ff e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f95:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f9a:	89 f8                	mov    %edi,%eax
f0101f9c:	e8 00 ea ff ff       	call   f01009a1 <check_va2pa>
f0101fa1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101fa4:	74 24                	je     f0101fca <mem_init+0xe5b>
f0101fa6:	c7 44 24 0c 1c 46 10 	movl   $0xf010461c,0xc(%esp)
f0101fad:	f0 
f0101fae:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101fb5:	f0 
f0101fb6:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101fbd:	00 
f0101fbe:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101fc5:	e8 ca e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101fca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fcd:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101fd2:	74 24                	je     f0101ff8 <mem_init+0xe89>
f0101fd4:	c7 44 24 0c bd 4a 10 	movl   $0xf0104abd,0xc(%esp)
f0101fdb:	f0 
f0101fdc:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0101fe3:	f0 
f0101fe4:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101feb:	00 
f0101fec:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0101ff3:	e8 9c e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0101ff8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ffd:	74 24                	je     f0102023 <mem_init+0xeb4>
f0101fff:	c7 44 24 0c ce 4a 10 	movl   $0xf0104ace,0xc(%esp)
f0102006:	f0 
f0102007:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010200e:	f0 
f010200f:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102016:	00 
f0102017:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010201e:	e8 71 e0 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102023:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010202a:	e8 2e ee ff ff       	call   f0100e5d <page_alloc>
f010202f:	85 c0                	test   %eax,%eax
f0102031:	74 04                	je     f0102037 <mem_init+0xec8>
f0102033:	39 c6                	cmp    %eax,%esi
f0102035:	74 24                	je     f010205b <mem_init+0xeec>
f0102037:	c7 44 24 0c 4c 46 10 	movl   $0xf010464c,0xc(%esp)
f010203e:	f0 
f010203f:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102046:	f0 
f0102047:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f010204e:	00 
f010204f:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102056:	e8 39 e0 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010205b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102062:	00 
f0102063:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102068:	89 04 24             	mov    %eax,(%esp)
f010206b:	e8 4a f0 ff ff       	call   f01010ba <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102070:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0102076:	ba 00 00 00 00       	mov    $0x0,%edx
f010207b:	89 f8                	mov    %edi,%eax
f010207d:	e8 1f e9 ff ff       	call   f01009a1 <check_va2pa>
f0102082:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102085:	74 24                	je     f01020ab <mem_init+0xf3c>
f0102087:	c7 44 24 0c 70 46 10 	movl   $0xf0104670,0xc(%esp)
f010208e:	f0 
f010208f:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102096:	f0 
f0102097:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f010209e:	00 
f010209f:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01020a6:	e8 e9 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020ab:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020b0:	89 f8                	mov    %edi,%eax
f01020b2:	e8 ea e8 ff ff       	call   f01009a1 <check_va2pa>
f01020b7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01020ba:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01020c0:	c1 fa 03             	sar    $0x3,%edx
f01020c3:	c1 e2 0c             	shl    $0xc,%edx
f01020c6:	39 d0                	cmp    %edx,%eax
f01020c8:	74 24                	je     f01020ee <mem_init+0xf7f>
f01020ca:	c7 44 24 0c 1c 46 10 	movl   $0xf010461c,0xc(%esp)
f01020d1:	f0 
f01020d2:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01020d9:	f0 
f01020da:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f01020e1:	00 
f01020e2:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01020e9:	e8 a6 df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01020ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020f1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020f6:	74 24                	je     f010211c <mem_init+0xfad>
f01020f8:	c7 44 24 0c 74 4a 10 	movl   $0xf0104a74,0xc(%esp)
f01020ff:	f0 
f0102100:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102107:	f0 
f0102108:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f010210f:	00 
f0102110:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102117:	e8 78 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010211c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102121:	74 24                	je     f0102147 <mem_init+0xfd8>
f0102123:	c7 44 24 0c ce 4a 10 	movl   $0xf0104ace,0xc(%esp)
f010212a:	f0 
f010212b:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102132:	f0 
f0102133:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f010213a:	00 
f010213b:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102142:	e8 4d df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102147:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010214e:	00 
f010214f:	89 3c 24             	mov    %edi,(%esp)
f0102152:	e8 63 ef ff ff       	call   f01010ba <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102157:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f010215d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102162:	89 f8                	mov    %edi,%eax
f0102164:	e8 38 e8 ff ff       	call   f01009a1 <check_va2pa>
f0102169:	83 f8 ff             	cmp    $0xffffffff,%eax
f010216c:	74 24                	je     f0102192 <mem_init+0x1023>
f010216e:	c7 44 24 0c 70 46 10 	movl   $0xf0104670,0xc(%esp)
f0102175:	f0 
f0102176:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010217d:	f0 
f010217e:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0102185:	00 
f0102186:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010218d:	e8 02 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102192:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102197:	89 f8                	mov    %edi,%eax
f0102199:	e8 03 e8 ff ff       	call   f01009a1 <check_va2pa>
f010219e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021a1:	74 24                	je     f01021c7 <mem_init+0x1058>
f01021a3:	c7 44 24 0c 94 46 10 	movl   $0xf0104694,0xc(%esp)
f01021aa:	f0 
f01021ab:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01021b2:	f0 
f01021b3:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f01021ba:	00 
f01021bb:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01021c2:	e8 cd de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01021c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ca:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01021cf:	74 24                	je     f01021f5 <mem_init+0x1086>
f01021d1:	c7 44 24 0c df 4a 10 	movl   $0xf0104adf,0xc(%esp)
f01021d8:	f0 
f01021d9:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01021e0:	f0 
f01021e1:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f01021e8:	00 
f01021e9:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01021f0:	e8 9f de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021f5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021fa:	74 24                	je     f0102220 <mem_init+0x10b1>
f01021fc:	c7 44 24 0c ce 4a 10 	movl   $0xf0104ace,0xc(%esp)
f0102203:	f0 
f0102204:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010220b:	f0 
f010220c:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0102213:	00 
f0102214:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010221b:	e8 74 de ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102220:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102227:	e8 31 ec ff ff       	call   f0100e5d <page_alloc>
f010222c:	85 c0                	test   %eax,%eax
f010222e:	74 05                	je     f0102235 <mem_init+0x10c6>
f0102230:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0102233:	74 24                	je     f0102259 <mem_init+0x10ea>
f0102235:	c7 44 24 0c bc 46 10 	movl   $0xf01046bc,0xc(%esp)
f010223c:	f0 
f010223d:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102244:	f0 
f0102245:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f010224c:	00 
f010224d:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102254:	e8 3b de ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102259:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102260:	e8 f8 eb ff ff       	call   f0100e5d <page_alloc>
f0102265:	85 c0                	test   %eax,%eax
f0102267:	74 24                	je     f010228d <mem_init+0x111e>
f0102269:	c7 44 24 0c 22 4a 10 	movl   $0xf0104a22,0xc(%esp)
f0102270:	f0 
f0102271:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102278:	f0 
f0102279:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0102280:	00 
f0102281:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102288:	e8 07 de ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010228d:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102292:	8b 08                	mov    (%eax),%ecx
f0102294:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010229a:	89 da                	mov    %ebx,%edx
f010229c:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01022a2:	c1 fa 03             	sar    $0x3,%edx
f01022a5:	c1 e2 0c             	shl    $0xc,%edx
f01022a8:	39 d1                	cmp    %edx,%ecx
f01022aa:	74 24                	je     f01022d0 <mem_init+0x1161>
f01022ac:	c7 44 24 0c cc 43 10 	movl   $0xf01043cc,0xc(%esp)
f01022b3:	f0 
f01022b4:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01022bb:	f0 
f01022bc:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f01022c3:	00 
f01022c4:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01022cb:	e8 c4 dd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01022d0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01022d6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01022db:	74 24                	je     f0102301 <mem_init+0x1192>
f01022dd:	c7 44 24 0c 85 4a 10 	movl   $0xf0104a85,0xc(%esp)
f01022e4:	f0 
f01022e5:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01022ec:	f0 
f01022ed:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f01022f4:	00 
f01022f5:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01022fc:	e8 93 dd ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102301:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102307:	89 1c 24             	mov    %ebx,(%esp)
f010230a:	e8 d3 eb ff ff       	call   f0100ee2 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010230f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102316:	00 
f0102317:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010231e:	00 
f010231f:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102324:	89 04 24             	mov    %eax,(%esp)
f0102327:	e8 ee eb ff ff       	call   f0100f1a <pgdir_walk>
f010232c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010232f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102332:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f0102338:	8b 7a 04             	mov    0x4(%edx),%edi
f010233b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102341:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f0102347:	89 f8                	mov    %edi,%eax
f0102349:	c1 e8 0c             	shr    $0xc,%eax
f010234c:	39 c8                	cmp    %ecx,%eax
f010234e:	72 20                	jb     f0102370 <mem_init+0x1201>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102350:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102354:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f010235b:	f0 
f010235c:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0102363:	00 
f0102364:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010236b:	e8 24 dd ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102370:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102376:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102379:	74 24                	je     f010239f <mem_init+0x1230>
f010237b:	c7 44 24 0c f0 4a 10 	movl   $0xf0104af0,0xc(%esp)
f0102382:	f0 
f0102383:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010238a:	f0 
f010238b:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0102392:	00 
f0102393:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010239a:	e8 f5 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010239f:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01023a6:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01023ac:	89 d8                	mov    %ebx,%eax
f01023ae:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f01023b4:	c1 f8 03             	sar    $0x3,%eax
f01023b7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023ba:	89 c2                	mov    %eax,%edx
f01023bc:	c1 ea 0c             	shr    $0xc,%edx
f01023bf:	39 d1                	cmp    %edx,%ecx
f01023c1:	77 20                	ja     f01023e3 <mem_init+0x1274>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01023c7:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f01023ce:	f0 
f01023cf:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01023d6:	00 
f01023d7:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f01023de:	e8 b1 dc ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01023e3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01023ea:	00 
f01023eb:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01023f2:	00 
	return (void *)(pa + KERNBASE);
f01023f3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023f8:	89 04 24             	mov    %eax,(%esp)
f01023fb:	e8 cf 13 00 00       	call   f01037cf <memset>
	page_free(pp0);
f0102400:	89 1c 24             	mov    %ebx,(%esp)
f0102403:	e8 da ea ff ff       	call   f0100ee2 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102408:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010240f:	00 
f0102410:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102417:	00 
f0102418:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010241d:	89 04 24             	mov    %eax,(%esp)
f0102420:	e8 f5 ea ff ff       	call   f0100f1a <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102425:	89 da                	mov    %ebx,%edx
f0102427:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f010242d:	c1 fa 03             	sar    $0x3,%edx
f0102430:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102433:	89 d0                	mov    %edx,%eax
f0102435:	c1 e8 0c             	shr    $0xc,%eax
f0102438:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f010243e:	72 20                	jb     f0102460 <mem_init+0x12f1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102440:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102444:	c7 44 24 08 64 41 10 	movl   $0xf0104164,0x8(%esp)
f010244b:	f0 
f010244c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102453:	00 
f0102454:	c7 04 24 74 48 10 f0 	movl   $0xf0104874,(%esp)
f010245b:	e8 34 dc ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102460:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102466:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102469:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102470:	75 11                	jne    f0102483 <mem_init+0x1314>
f0102472:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
f0102478:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f010247e:	f6 00 01             	testb  $0x1,(%eax)
f0102481:	74 24                	je     f01024a7 <mem_init+0x1338>
f0102483:	c7 44 24 0c 08 4b 10 	movl   $0xf0104b08,0xc(%esp)
f010248a:	f0 
f010248b:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102492:	f0 
f0102493:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f010249a:	00 
f010249b:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01024a2:	e8 ed db ff ff       	call   f0100094 <_panic>
f01024a7:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01024aa:	39 d0                	cmp    %edx,%eax
f01024ac:	75 d0                	jne    f010247e <mem_init+0x130f>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01024ae:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01024b3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01024b9:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f01024bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01024c2:	a3 5c 75 11 f0       	mov    %eax,0xf011755c

	// free the pages we took
	page_free(pp0);
f01024c7:	89 1c 24             	mov    %ebx,(%esp)
f01024ca:	e8 13 ea ff ff       	call   f0100ee2 <page_free>
	page_free(pp1);
f01024cf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024d2:	89 04 24             	mov    %eax,(%esp)
f01024d5:	e8 08 ea ff ff       	call   f0100ee2 <page_free>
	page_free(pp2);
f01024da:	89 34 24             	mov    %esi,(%esp)
f01024dd:	e8 00 ea ff ff       	call   f0100ee2 <page_free>

	cprintf("check_page() succeeded!\n");
f01024e2:	c7 04 24 1f 4b 10 f0 	movl   $0xf0104b1f,(%esp)
f01024e9:	e8 47 07 00 00       	call   f0102c35 <cprintf>
	page_init();

	check_page_free_list(1);
	check_page_alloc();
	check_page();
	cprintf("checked!\n");
f01024ee:	c7 04 24 38 4b 10 f0 	movl   $0xf0104b38,(%esp)
f01024f5:	e8 3b 07 00 00       	call   f0102c35 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01024fa:	a1 88 79 11 f0       	mov    0xf0117988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024ff:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102504:	77 20                	ja     f0102526 <mem_init+0x13b7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102506:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010250a:	c7 44 24 08 d0 42 10 	movl   $0xf01042d0,0x8(%esp)
f0102511:	f0 
f0102512:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
f0102519:	00 
f010251a:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102521:	e8 6e db ff ff       	call   f0100094 <_panic>
f0102526:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f010252d:	00 
	return (physaddr_t)kva - KERNBASE;
f010252e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102533:	89 04 24             	mov    %eax,(%esp)
f0102536:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010253b:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102540:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102545:	e8 70 ea ff ff       	call   f0100fba <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010254a:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f010254f:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102555:	77 20                	ja     f0102577 <mem_init+0x1408>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102557:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010255b:	c7 44 24 08 d0 42 10 	movl   $0xf01042d0,0x8(%esp)
f0102562:	f0 
f0102563:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
f010256a:	00 
f010256b:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102572:	e8 1d db ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102577:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010257e:	00 
f010257f:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102586:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010258b:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102590:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102595:	e8 20 ea ff ff       	call   f0100fba <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f010259a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01025a1:	00 
f01025a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025a9:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01025ae:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01025b3:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01025b8:	e8 fd e9 ff ff       	call   f0100fba <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01025bd:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f01025c3:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f01025c8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01025cb:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f01025d2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01025d7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01025da:	0f 84 84 00 00 00    	je     f0102664 <mem_init+0x14f5>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01025e0:	8b 35 88 79 11 f0    	mov    0xf0117988,%esi
	return (physaddr_t)kva - KERNBASE;
f01025e6:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01025ec:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01025ef:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025f4:	89 f8                	mov    %edi,%eax
f01025f6:	e8 a6 e3 ff ff       	call   f01009a1 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025fb:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102601:	77 20                	ja     f0102623 <mem_init+0x14b4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102603:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102607:	c7 44 24 08 d0 42 10 	movl   $0xf01042d0,0x8(%esp)
f010260e:	f0 
f010260f:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0102616:	00 
f0102617:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010261e:	e8 71 da ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102623:	ba 00 00 00 00       	mov    $0x0,%edx
f0102628:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010262b:	01 d1                	add    %edx,%ecx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010262d:	39 c1                	cmp    %eax,%ecx
f010262f:	74 24                	je     f0102655 <mem_init+0x14e6>
f0102631:	c7 44 24 0c e0 46 10 	movl   $0xf01046e0,0xc(%esp)
f0102638:	f0 
f0102639:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102640:	f0 
f0102641:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0102648:	00 
f0102649:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102650:	e8 3f da ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102655:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f010265b:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f010265e:	0f 87 3a 05 00 00    	ja     f0102b9e <mem_init+0x1a2f>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102664:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102667:	c1 e0 0c             	shl    $0xc,%eax
f010266a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010266d:	85 c0                	test   %eax,%eax
f010266f:	0f 84 0a 05 00 00    	je     f0102b7f <mem_init+0x1a10>
f0102675:	be 00 00 00 00       	mov    $0x0,%esi
f010267a:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102680:	89 f8                	mov    %edi,%eax
f0102682:	e8 1a e3 ff ff       	call   f01009a1 <check_va2pa>
f0102687:	39 c6                	cmp    %eax,%esi
f0102689:	74 24                	je     f01026af <mem_init+0x1540>
f010268b:	c7 44 24 0c 14 47 10 	movl   $0xf0104714,0xc(%esp)
f0102692:	f0 
f0102693:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010269a:	f0 
f010269b:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f01026a2:	00 
f01026a3:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01026aa:	e8 e5 d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01026af:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01026b5:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01026b8:	72 c0                	jb     f010267a <mem_init+0x150b>
f01026ba:	e9 c0 04 00 00       	jmp    f0102b7f <mem_init+0x1a10>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01026bf:	39 c6                	cmp    %eax,%esi
f01026c1:	74 24                	je     f01026e7 <mem_init+0x1578>
f01026c3:	c7 44 24 0c 3c 47 10 	movl   $0xf010473c,0xc(%esp)
f01026ca:	f0 
f01026cb:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01026d2:	f0 
f01026d3:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f01026da:	00 
f01026db:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01026e2:	e8 ad d9 ff ff       	call   f0100094 <_panic>
f01026e7:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01026ed:	81 fe 00 50 11 00    	cmp    $0x115000,%esi
f01026f3:	0f 85 77 04 00 00    	jne    f0102b70 <mem_init+0x1a01>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01026f9:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f01026fe:	89 f8                	mov    %edi,%eax
f0102700:	e8 9c e2 ff ff       	call   f01009a1 <check_va2pa>
f0102705:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102708:	74 24                	je     f010272e <mem_init+0x15bf>
f010270a:	c7 44 24 0c 84 47 10 	movl   $0xf0104784,0xc(%esp)
f0102711:	f0 
f0102712:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102719:	f0 
f010271a:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0102721:	00 
f0102722:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102729:	e8 66 d9 ff ff       	call   f0100094 <_panic>
f010272e:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102733:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f0102739:	83 fa 02             	cmp    $0x2,%edx
f010273c:	77 2e                	ja     f010276c <mem_init+0x15fd>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010273e:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102742:	0f 85 aa 00 00 00    	jne    f01027f2 <mem_init+0x1683>
f0102748:	c7 44 24 0c 42 4b 10 	movl   $0xf0104b42,0xc(%esp)
f010274f:	f0 
f0102750:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102757:	f0 
f0102758:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
f010275f:	00 
f0102760:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102767:	e8 28 d9 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010276c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102771:	76 55                	jbe    f01027c8 <mem_init+0x1659>
				assert(pgdir[i] & PTE_P);
f0102773:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102776:	f6 c2 01             	test   $0x1,%dl
f0102779:	75 24                	jne    f010279f <mem_init+0x1630>
f010277b:	c7 44 24 0c 42 4b 10 	movl   $0xf0104b42,0xc(%esp)
f0102782:	f0 
f0102783:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f010278a:	f0 
f010278b:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f0102792:	00 
f0102793:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f010279a:	e8 f5 d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f010279f:	f6 c2 02             	test   $0x2,%dl
f01027a2:	75 4e                	jne    f01027f2 <mem_init+0x1683>
f01027a4:	c7 44 24 0c 53 4b 10 	movl   $0xf0104b53,0xc(%esp)
f01027ab:	f0 
f01027ac:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01027b3:	f0 
f01027b4:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
f01027bb:	00 
f01027bc:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01027c3:	e8 cc d8 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f01027c8:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01027cc:	74 24                	je     f01027f2 <mem_init+0x1683>
f01027ce:	c7 44 24 0c 64 4b 10 	movl   $0xf0104b64,0xc(%esp)
f01027d5:	f0 
f01027d6:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01027dd:	f0 
f01027de:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
f01027e5:	00 
f01027e6:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01027ed:	e8 a2 d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01027f2:	83 c0 01             	add    $0x1,%eax
f01027f5:	3d 00 04 00 00       	cmp    $0x400,%eax
f01027fa:	0f 85 33 ff ff ff    	jne    f0102733 <mem_init+0x15c4>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102800:	c7 04 24 b4 47 10 f0 	movl   $0xf01047b4,(%esp)
f0102807:	e8 29 04 00 00       	call   f0102c35 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010280c:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102811:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102816:	77 20                	ja     f0102838 <mem_init+0x16c9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102818:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010281c:	c7 44 24 08 d0 42 10 	movl   $0xf01042d0,0x8(%esp)
f0102823:	f0 
f0102824:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
f010282b:	00 
f010282c:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102833:	e8 5c d8 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102838:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010283d:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102840:	b8 00 00 00 00       	mov    $0x0,%eax
f0102845:	e8 c6 e1 ff ff       	call   f0100a10 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010284a:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f010284d:	83 e0 f3             	and    $0xfffffff3,%eax
f0102850:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102855:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102858:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010285f:	e8 f9 e5 ff ff       	call   f0100e5d <page_alloc>
f0102864:	89 c3                	mov    %eax,%ebx
f0102866:	85 c0                	test   %eax,%eax
f0102868:	75 24                	jne    f010288e <mem_init+0x171f>
f010286a:	c7 44 24 0c 77 49 10 	movl   $0xf0104977,0xc(%esp)
f0102871:	f0 
f0102872:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102879:	f0 
f010287a:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102881:	00 
f0102882:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102889:	e8 06 d8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010288e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102895:	e8 c3 e5 ff ff       	call   f0100e5d <page_alloc>
f010289a:	89 c7                	mov    %eax,%edi
f010289c:	85 c0                	test   %eax,%eax
f010289e:	75 24                	jne    f01028c4 <mem_init+0x1755>
f01028a0:	c7 44 24 0c 8d 49 10 	movl   $0xf010498d,0xc(%esp)
f01028a7:	f0 
f01028a8:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01028af:	f0 
f01028b0:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f01028b7:	00 
f01028b8:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01028bf:	e8 d0 d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01028c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028cb:	e8 8d e5 ff ff       	call   f0100e5d <page_alloc>
f01028d0:	89 c6                	mov    %eax,%esi
f01028d2:	85 c0                	test   %eax,%eax
f01028d4:	75 24                	jne    f01028fa <mem_init+0x178b>
f01028d6:	c7 44 24 0c a3 49 10 	movl   $0xf01049a3,0xc(%esp)
f01028dd:	f0 
f01028de:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01028e5:	f0 
f01028e6:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f01028ed:	00 
f01028ee:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01028f5:	e8 9a d7 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01028fa:	89 1c 24             	mov    %ebx,(%esp)
f01028fd:	e8 e0 e5 ff ff       	call   f0100ee2 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102902:	89 f8                	mov    %edi,%eax
f0102904:	e8 53 e0 ff ff       	call   f010095c <page2kva>
f0102909:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102910:	00 
f0102911:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102918:	00 
f0102919:	89 04 24             	mov    %eax,(%esp)
f010291c:	e8 ae 0e 00 00       	call   f01037cf <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102921:	89 f0                	mov    %esi,%eax
f0102923:	e8 34 e0 ff ff       	call   f010095c <page2kva>
f0102928:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010292f:	00 
f0102930:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102937:	00 
f0102938:	89 04 24             	mov    %eax,(%esp)
f010293b:	e8 8f 0e 00 00       	call   f01037cf <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102940:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102947:	00 
f0102948:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010294f:	00 
f0102950:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102954:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102959:	89 04 24             	mov    %eax,(%esp)
f010295c:	e8 9f e7 ff ff       	call   f0101100 <page_insert>
	assert(pp1->pp_ref == 1);
f0102961:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102966:	74 24                	je     f010298c <mem_init+0x181d>
f0102968:	c7 44 24 0c 74 4a 10 	movl   $0xf0104a74,0xc(%esp)
f010296f:	f0 
f0102970:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102977:	f0 
f0102978:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f010297f:	00 
f0102980:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102987:	e8 08 d7 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010298c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102993:	01 01 01 
f0102996:	74 24                	je     f01029bc <mem_init+0x184d>
f0102998:	c7 44 24 0c d4 47 10 	movl   $0xf01047d4,0xc(%esp)
f010299f:	f0 
f01029a0:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01029a7:	f0 
f01029a8:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f01029af:	00 
f01029b0:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f01029b7:	e8 d8 d6 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01029bc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01029c3:	00 
f01029c4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029cb:	00 
f01029cc:	89 74 24 04          	mov    %esi,0x4(%esp)
f01029d0:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01029d5:	89 04 24             	mov    %eax,(%esp)
f01029d8:	e8 23 e7 ff ff       	call   f0101100 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01029dd:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01029e4:	02 02 02 
f01029e7:	74 24                	je     f0102a0d <mem_init+0x189e>
f01029e9:	c7 44 24 0c f8 47 10 	movl   $0xf01047f8,0xc(%esp)
f01029f0:	f0 
f01029f1:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f01029f8:	f0 
f01029f9:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0102a00:	00 
f0102a01:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102a08:	e8 87 d6 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102a0d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102a12:	74 24                	je     f0102a38 <mem_init+0x18c9>
f0102a14:	c7 44 24 0c 96 4a 10 	movl   $0xf0104a96,0xc(%esp)
f0102a1b:	f0 
f0102a1c:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102a23:	f0 
f0102a24:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0102a2b:	00 
f0102a2c:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102a33:	e8 5c d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102a38:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102a3d:	74 24                	je     f0102a63 <mem_init+0x18f4>
f0102a3f:	c7 44 24 0c df 4a 10 	movl   $0xf0104adf,0xc(%esp)
f0102a46:	f0 
f0102a47:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102a4e:	f0 
f0102a4f:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102a56:	00 
f0102a57:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102a5e:	e8 31 d6 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102a63:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102a6a:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102a6d:	89 f0                	mov    %esi,%eax
f0102a6f:	e8 e8 de ff ff       	call   f010095c <page2kva>
f0102a74:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102a7a:	74 24                	je     f0102aa0 <mem_init+0x1931>
f0102a7c:	c7 44 24 0c 1c 48 10 	movl   $0xf010481c,0xc(%esp)
f0102a83:	f0 
f0102a84:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102a8b:	f0 
f0102a8c:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0102a93:	00 
f0102a94:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102a9b:	e8 f4 d5 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102aa0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102aa7:	00 
f0102aa8:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102aad:	89 04 24             	mov    %eax,(%esp)
f0102ab0:	e8 05 e6 ff ff       	call   f01010ba <page_remove>
	assert(pp2->pp_ref == 0);
f0102ab5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102aba:	74 24                	je     f0102ae0 <mem_init+0x1971>
f0102abc:	c7 44 24 0c ce 4a 10 	movl   $0xf0104ace,0xc(%esp)
f0102ac3:	f0 
f0102ac4:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102acb:	f0 
f0102acc:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0102ad3:	00 
f0102ad4:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102adb:	e8 b4 d5 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ae0:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102ae5:	8b 08                	mov    (%eax),%ecx
f0102ae7:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102aed:	89 da                	mov    %ebx,%edx
f0102aef:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102af5:	c1 fa 03             	sar    $0x3,%edx
f0102af8:	c1 e2 0c             	shl    $0xc,%edx
f0102afb:	39 d1                	cmp    %edx,%ecx
f0102afd:	74 24                	je     f0102b23 <mem_init+0x19b4>
f0102aff:	c7 44 24 0c cc 43 10 	movl   $0xf01043cc,0xc(%esp)
f0102b06:	f0 
f0102b07:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102b0e:	f0 
f0102b0f:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f0102b16:	00 
f0102b17:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102b1e:	e8 71 d5 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102b23:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102b29:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102b2e:	74 24                	je     f0102b54 <mem_init+0x19e5>
f0102b30:	c7 44 24 0c 85 4a 10 	movl   $0xf0104a85,0xc(%esp)
f0102b37:	f0 
f0102b38:	c7 44 24 08 9a 48 10 	movl   $0xf010489a,0x8(%esp)
f0102b3f:	f0 
f0102b40:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0102b47:	00 
f0102b48:	c7 04 24 82 48 10 f0 	movl   $0xf0104882,(%esp)
f0102b4f:	e8 40 d5 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102b54:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102b5a:	89 1c 24             	mov    %ebx,(%esp)
f0102b5d:	e8 80 e3 ff ff       	call   f0100ee2 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102b62:	c7 04 24 48 48 10 f0 	movl   $0xf0104848,(%esp)
f0102b69:	e8 c7 00 00 00       	call   f0102c35 <cprintf>
f0102b6e:	eb 42                	jmp    f0102bb2 <mem_init+0x1a43>
f0102b70:	8d 14 33             	lea    (%ebx,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b73:	89 f8                	mov    %edi,%eax
f0102b75:	e8 27 de ff ff       	call   f01009a1 <check_va2pa>
f0102b7a:	e9 40 fb ff ff       	jmp    f01026bf <mem_init+0x1550>
f0102b7f:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102b84:	89 f8                	mov    %edi,%eax
f0102b86:	e8 16 de ff ff       	call   f01009a1 <check_va2pa>
f0102b8b:	be 00 d0 10 00       	mov    $0x10d000,%esi
f0102b90:	ba 00 80 bf df       	mov    $0xdfbf8000,%edx
f0102b95:	29 da                	sub    %ebx,%edx
f0102b97:	89 d3                	mov    %edx,%ebx
f0102b99:	e9 21 fb ff ff       	jmp    f01026bf <mem_init+0x1550>
f0102b9e:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102ba4:	89 f8                	mov    %edi,%eax
f0102ba6:	e8 f6 dd ff ff       	call   f01009a1 <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102bab:	89 f2                	mov    %esi,%edx
f0102bad:	e9 76 fa ff ff       	jmp    f0102628 <mem_init+0x14b9>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102bb2:	83 c4 3c             	add    $0x3c,%esp
f0102bb5:	5b                   	pop    %ebx
f0102bb6:	5e                   	pop    %esi
f0102bb7:	5f                   	pop    %edi
f0102bb8:	5d                   	pop    %ebp
f0102bb9:	c3                   	ret    

f0102bba <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102bba:	55                   	push   %ebp
f0102bbb:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102bbd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bc0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102bc3:	5d                   	pop    %ebp
f0102bc4:	c3                   	ret    

f0102bc5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102bc5:	55                   	push   %ebp
f0102bc6:	89 e5                	mov    %esp,%ebp
f0102bc8:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102bcc:	ba 70 00 00 00       	mov    $0x70,%edx
f0102bd1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102bd2:	b2 71                	mov    $0x71,%dl
f0102bd4:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102bd5:	0f b6 c0             	movzbl %al,%eax
}
f0102bd8:	5d                   	pop    %ebp
f0102bd9:	c3                   	ret    

f0102bda <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102bda:	55                   	push   %ebp
f0102bdb:	89 e5                	mov    %esp,%ebp
f0102bdd:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102be1:	ba 70 00 00 00       	mov    $0x70,%edx
f0102be6:	ee                   	out    %al,(%dx)
f0102be7:	b2 71                	mov    $0x71,%dl
f0102be9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bec:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102bed:	5d                   	pop    %ebp
f0102bee:	c3                   	ret    

f0102bef <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102bef:	55                   	push   %ebp
f0102bf0:	89 e5                	mov    %esp,%ebp
f0102bf2:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102bf5:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bf8:	89 04 24             	mov    %eax,(%esp)
f0102bfb:	e8 ed d9 ff ff       	call   f01005ed <cputchar>
	*cnt++;
}
f0102c00:	c9                   	leave  
f0102c01:	c3                   	ret    

f0102c02 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102c02:	55                   	push   %ebp
f0102c03:	89 e5                	mov    %esp,%ebp
f0102c05:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102c08:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102c0f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c12:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c16:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c19:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102c1d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102c20:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c24:	c7 04 24 ef 2b 10 f0 	movl   $0xf0102bef,(%esp)
f0102c2b:	e8 84 04 00 00       	call   f01030b4 <vprintfmt>
	return cnt;
}
f0102c30:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102c33:	c9                   	leave  
f0102c34:	c3                   	ret    

f0102c35 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102c35:	55                   	push   %ebp
f0102c36:	89 e5                	mov    %esp,%ebp
f0102c38:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102c3b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102c3e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c42:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c45:	89 04 24             	mov    %eax,(%esp)
f0102c48:	e8 b5 ff ff ff       	call   f0102c02 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102c4d:	c9                   	leave  
f0102c4e:	c3                   	ret    
f0102c4f:	90                   	nop

f0102c50 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102c50:	55                   	push   %ebp
f0102c51:	89 e5                	mov    %esp,%ebp
f0102c53:	57                   	push   %edi
f0102c54:	56                   	push   %esi
f0102c55:	53                   	push   %ebx
f0102c56:	83 ec 10             	sub    $0x10,%esp
f0102c59:	89 c6                	mov    %eax,%esi
f0102c5b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102c5e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102c61:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102c64:	8b 1a                	mov    (%edx),%ebx
f0102c66:	8b 01                	mov    (%ecx),%eax
f0102c68:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102c6b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102c72:	eb 77                	jmp    f0102ceb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102c74:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102c77:	01 d8                	add    %ebx,%eax
f0102c79:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102c7e:	99                   	cltd   
f0102c7f:	f7 f9                	idiv   %ecx
f0102c81:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102c83:	eb 01                	jmp    f0102c86 <stab_binsearch+0x36>
			m--;
f0102c85:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102c86:	39 d9                	cmp    %ebx,%ecx
f0102c88:	7c 1d                	jl     f0102ca7 <stab_binsearch+0x57>
f0102c8a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102c8d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102c92:	39 fa                	cmp    %edi,%edx
f0102c94:	75 ef                	jne    f0102c85 <stab_binsearch+0x35>
f0102c96:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102c99:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102c9c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102ca0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102ca3:	73 18                	jae    f0102cbd <stab_binsearch+0x6d>
f0102ca5:	eb 05                	jmp    f0102cac <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102ca7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102caa:	eb 3f                	jmp    f0102ceb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102cac:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102caf:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102cb1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102cb4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102cbb:	eb 2e                	jmp    f0102ceb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102cbd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102cc0:	73 15                	jae    f0102cd7 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102cc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102cc5:	48                   	dec    %eax
f0102cc6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102cc9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102ccc:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102cce:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102cd5:	eb 14                	jmp    f0102ceb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102cd7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102cda:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102cdd:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102cdf:	ff 45 0c             	incl   0xc(%ebp)
f0102ce2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102ce4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102ceb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102cee:	7e 84                	jle    f0102c74 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102cf0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102cf4:	75 0d                	jne    f0102d03 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102cf6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102cf9:	8b 00                	mov    (%eax),%eax
f0102cfb:	48                   	dec    %eax
f0102cfc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cff:	89 07                	mov    %eax,(%edi)
f0102d01:	eb 22                	jmp    f0102d25 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102d03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d06:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102d08:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102d0b:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102d0d:	eb 01                	jmp    f0102d10 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102d0f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102d10:	39 c1                	cmp    %eax,%ecx
f0102d12:	7d 0c                	jge    f0102d20 <stab_binsearch+0xd0>
f0102d14:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102d17:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102d1c:	39 fa                	cmp    %edi,%edx
f0102d1e:	75 ef                	jne    f0102d0f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102d20:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102d23:	89 07                	mov    %eax,(%edi)
	}
}
f0102d25:	83 c4 10             	add    $0x10,%esp
f0102d28:	5b                   	pop    %ebx
f0102d29:	5e                   	pop    %esi
f0102d2a:	5f                   	pop    %edi
f0102d2b:	5d                   	pop    %ebp
f0102d2c:	c3                   	ret    

f0102d2d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102d2d:	55                   	push   %ebp
f0102d2e:	89 e5                	mov    %esp,%ebp
f0102d30:	57                   	push   %edi
f0102d31:	56                   	push   %esi
f0102d32:	53                   	push   %ebx
f0102d33:	83 ec 2c             	sub    $0x2c,%esp
f0102d36:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d39:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102d3c:	c7 03 72 4b 10 f0    	movl   $0xf0104b72,(%ebx)
	info->eip_line = 0;
f0102d42:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102d49:	c7 43 08 72 4b 10 f0 	movl   $0xf0104b72,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102d50:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102d57:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102d5a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102d61:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102d67:	76 12                	jbe    f0102d7b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102d69:	b8 f1 c6 10 f0       	mov    $0xf010c6f1,%eax
f0102d6e:	3d c5 a9 10 f0       	cmp    $0xf010a9c5,%eax
f0102d73:	0f 86 8b 01 00 00    	jbe    f0102f04 <debuginfo_eip+0x1d7>
f0102d79:	eb 1c                	jmp    f0102d97 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102d7b:	c7 44 24 08 7c 4b 10 	movl   $0xf0104b7c,0x8(%esp)
f0102d82:	f0 
f0102d83:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102d8a:	00 
f0102d8b:	c7 04 24 89 4b 10 f0 	movl   $0xf0104b89,(%esp)
f0102d92:	e8 fd d2 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102d97:	80 3d f0 c6 10 f0 00 	cmpb   $0x0,0xf010c6f0
f0102d9e:	0f 85 67 01 00 00    	jne    f0102f0b <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102da4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102dab:	b8 c4 a9 10 f0       	mov    $0xf010a9c4,%eax
f0102db0:	2d a8 4d 10 f0       	sub    $0xf0104da8,%eax
f0102db5:	c1 f8 02             	sar    $0x2,%eax
f0102db8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102dbe:	83 e8 01             	sub    $0x1,%eax
f0102dc1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102dc4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102dc8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102dcf:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102dd2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102dd5:	b8 a8 4d 10 f0       	mov    $0xf0104da8,%eax
f0102dda:	e8 71 fe ff ff       	call   f0102c50 <stab_binsearch>
	if (lfile == 0)
f0102ddf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102de2:	85 c0                	test   %eax,%eax
f0102de4:	0f 84 28 01 00 00    	je     f0102f12 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102dea:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102ded:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102df0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102df3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102df7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102dfe:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102e01:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102e04:	b8 a8 4d 10 f0       	mov    $0xf0104da8,%eax
f0102e09:	e8 42 fe ff ff       	call   f0102c50 <stab_binsearch>

	if (lfun <= rfun) {
f0102e0e:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102e11:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102e14:	7f 2e                	jg     f0102e44 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102e16:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102e19:	8d 90 a8 4d 10 f0    	lea    -0xfefb258(%eax),%edx
f0102e1f:	8b 80 a8 4d 10 f0    	mov    -0xfefb258(%eax),%eax
f0102e25:	b9 f1 c6 10 f0       	mov    $0xf010c6f1,%ecx
f0102e2a:	81 e9 c5 a9 10 f0    	sub    $0xf010a9c5,%ecx
f0102e30:	39 c8                	cmp    %ecx,%eax
f0102e32:	73 08                	jae    f0102e3c <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102e34:	05 c5 a9 10 f0       	add    $0xf010a9c5,%eax
f0102e39:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102e3c:	8b 42 08             	mov    0x8(%edx),%eax
f0102e3f:	89 43 10             	mov    %eax,0x10(%ebx)
f0102e42:	eb 06                	jmp    f0102e4a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102e44:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102e47:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102e4a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102e51:	00 
f0102e52:	8b 43 08             	mov    0x8(%ebx),%eax
f0102e55:	89 04 24             	mov    %eax,(%esp)
f0102e58:	e8 47 09 00 00       	call   f01037a4 <strfind>
f0102e5d:	2b 43 08             	sub    0x8(%ebx),%eax
f0102e60:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102e63:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e66:	39 cf                	cmp    %ecx,%edi
f0102e68:	7c 5c                	jl     f0102ec6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0102e6a:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102e6d:	8d b0 a8 4d 10 f0    	lea    -0xfefb258(%eax),%esi
f0102e73:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0102e77:	80 fa 84             	cmp    $0x84,%dl
f0102e7a:	74 2b                	je     f0102ea7 <debuginfo_eip+0x17a>
f0102e7c:	05 9c 4d 10 f0       	add    $0xf0104d9c,%eax
f0102e81:	eb 15                	jmp    f0102e98 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102e83:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102e86:	39 cf                	cmp    %ecx,%edi
f0102e88:	7c 3c                	jl     f0102ec6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0102e8a:	89 c6                	mov    %eax,%esi
f0102e8c:	83 e8 0c             	sub    $0xc,%eax
f0102e8f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0102e93:	80 fa 84             	cmp    $0x84,%dl
f0102e96:	74 0f                	je     f0102ea7 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102e98:	80 fa 64             	cmp    $0x64,%dl
f0102e9b:	75 e6                	jne    f0102e83 <debuginfo_eip+0x156>
f0102e9d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0102ea1:	74 e0                	je     f0102e83 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102ea3:	39 f9                	cmp    %edi,%ecx
f0102ea5:	7f 1f                	jg     f0102ec6 <debuginfo_eip+0x199>
f0102ea7:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102eaa:	8b 87 a8 4d 10 f0    	mov    -0xfefb258(%edi),%eax
f0102eb0:	ba f1 c6 10 f0       	mov    $0xf010c6f1,%edx
f0102eb5:	81 ea c5 a9 10 f0    	sub    $0xf010a9c5,%edx
f0102ebb:	39 d0                	cmp    %edx,%eax
f0102ebd:	73 07                	jae    f0102ec6 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102ebf:	05 c5 a9 10 f0       	add    $0xf010a9c5,%eax
f0102ec4:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102ec6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ec9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102ecc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102ed1:	39 ca                	cmp    %ecx,%edx
f0102ed3:	7d 5e                	jge    f0102f33 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0102ed5:	8d 42 01             	lea    0x1(%edx),%eax
f0102ed8:	39 c1                	cmp    %eax,%ecx
f0102eda:	7e 3d                	jle    f0102f19 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102edc:	6b d0 0c             	imul   $0xc,%eax,%edx
f0102edf:	80 ba ac 4d 10 f0 a0 	cmpb   $0xa0,-0xfefb254(%edx)
f0102ee6:	75 38                	jne    f0102f20 <debuginfo_eip+0x1f3>
f0102ee8:	81 c2 9c 4d 10 f0    	add    $0xf0104d9c,%edx
		     lline++)
			info->eip_fn_narg++;
f0102eee:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102ef2:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102ef5:	39 c1                	cmp    %eax,%ecx
f0102ef7:	7e 2e                	jle    f0102f27 <debuginfo_eip+0x1fa>
f0102ef9:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102efc:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0102f00:	74 ec                	je     f0102eee <debuginfo_eip+0x1c1>
f0102f02:	eb 2a                	jmp    f0102f2e <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102f04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102f09:	eb 28                	jmp    f0102f33 <debuginfo_eip+0x206>
f0102f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102f10:	eb 21                	jmp    f0102f33 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102f12:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102f17:	eb 1a                	jmp    f0102f33 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102f19:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f1e:	eb 13                	jmp    f0102f33 <debuginfo_eip+0x206>
f0102f20:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f25:	eb 0c                	jmp    f0102f33 <debuginfo_eip+0x206>
f0102f27:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f2c:	eb 05                	jmp    f0102f33 <debuginfo_eip+0x206>
f0102f2e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102f33:	83 c4 2c             	add    $0x2c,%esp
f0102f36:	5b                   	pop    %ebx
f0102f37:	5e                   	pop    %esi
f0102f38:	5f                   	pop    %edi
f0102f39:	5d                   	pop    %ebp
f0102f3a:	c3                   	ret    
f0102f3b:	66 90                	xchg   %ax,%ax
f0102f3d:	66 90                	xchg   %ax,%ax
f0102f3f:	90                   	nop

f0102f40 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102f40:	55                   	push   %ebp
f0102f41:	89 e5                	mov    %esp,%ebp
f0102f43:	57                   	push   %edi
f0102f44:	56                   	push   %esi
f0102f45:	53                   	push   %ebx
f0102f46:	83 ec 3c             	sub    $0x3c,%esp
f0102f49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102f4c:	89 d7                	mov    %edx,%edi
f0102f4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f51:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102f54:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102f57:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102f5a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102f5d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f62:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f65:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f68:	39 f1                	cmp    %esi,%ecx
f0102f6a:	72 14                	jb     f0102f80 <printnum+0x40>
f0102f6c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0102f6f:	76 0f                	jbe    f0102f80 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102f71:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f74:	8d 70 ff             	lea    -0x1(%eax),%esi
f0102f77:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102f7a:	85 f6                	test   %esi,%esi
f0102f7c:	7f 60                	jg     f0102fde <printnum+0x9e>
f0102f7e:	eb 72                	jmp    f0102ff2 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102f80:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0102f83:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0102f87:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0102f8a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0102f8d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102f91:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f95:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102f99:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0102f9d:	89 c3                	mov    %eax,%ebx
f0102f9f:	89 d6                	mov    %edx,%esi
f0102fa1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fa4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102fa7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102fab:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102faf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fb2:	89 04 24             	mov    %eax,(%esp)
f0102fb5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102fb8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fbc:	e8 4f 0a 00 00       	call   f0103a10 <__udivdi3>
f0102fc1:	89 d9                	mov    %ebx,%ecx
f0102fc3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102fc7:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102fcb:	89 04 24             	mov    %eax,(%esp)
f0102fce:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102fd2:	89 fa                	mov    %edi,%edx
f0102fd4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fd7:	e8 64 ff ff ff       	call   f0102f40 <printnum>
f0102fdc:	eb 14                	jmp    f0102ff2 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102fde:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102fe2:	8b 45 18             	mov    0x18(%ebp),%eax
f0102fe5:	89 04 24             	mov    %eax,(%esp)
f0102fe8:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102fea:	83 ee 01             	sub    $0x1,%esi
f0102fed:	75 ef                	jne    f0102fde <printnum+0x9e>
f0102fef:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102ff2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102ff6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0102ffa:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ffd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103000:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103004:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103008:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010300b:	89 04 24             	mov    %eax,(%esp)
f010300e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103011:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103015:	e8 26 0b 00 00       	call   f0103b40 <__umoddi3>
f010301a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010301e:	0f be 80 97 4b 10 f0 	movsbl -0xfefb469(%eax),%eax
f0103025:	89 04 24             	mov    %eax,(%esp)
f0103028:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010302b:	ff d0                	call   *%eax
}
f010302d:	83 c4 3c             	add    $0x3c,%esp
f0103030:	5b                   	pop    %ebx
f0103031:	5e                   	pop    %esi
f0103032:	5f                   	pop    %edi
f0103033:	5d                   	pop    %ebp
f0103034:	c3                   	ret    

f0103035 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103035:	55                   	push   %ebp
f0103036:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103038:	83 fa 01             	cmp    $0x1,%edx
f010303b:	7e 0e                	jle    f010304b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010303d:	8b 10                	mov    (%eax),%edx
f010303f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103042:	89 08                	mov    %ecx,(%eax)
f0103044:	8b 02                	mov    (%edx),%eax
f0103046:	8b 52 04             	mov    0x4(%edx),%edx
f0103049:	eb 22                	jmp    f010306d <getuint+0x38>
	else if (lflag)
f010304b:	85 d2                	test   %edx,%edx
f010304d:	74 10                	je     f010305f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010304f:	8b 10                	mov    (%eax),%edx
f0103051:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103054:	89 08                	mov    %ecx,(%eax)
f0103056:	8b 02                	mov    (%edx),%eax
f0103058:	ba 00 00 00 00       	mov    $0x0,%edx
f010305d:	eb 0e                	jmp    f010306d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010305f:	8b 10                	mov    (%eax),%edx
f0103061:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103064:	89 08                	mov    %ecx,(%eax)
f0103066:	8b 02                	mov    (%edx),%eax
f0103068:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010306d:	5d                   	pop    %ebp
f010306e:	c3                   	ret    

f010306f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010306f:	55                   	push   %ebp
f0103070:	89 e5                	mov    %esp,%ebp
f0103072:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103075:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103079:	8b 10                	mov    (%eax),%edx
f010307b:	3b 50 04             	cmp    0x4(%eax),%edx
f010307e:	73 0a                	jae    f010308a <sprintputch+0x1b>
		*b->buf++ = ch;
f0103080:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103083:	89 08                	mov    %ecx,(%eax)
f0103085:	8b 45 08             	mov    0x8(%ebp),%eax
f0103088:	88 02                	mov    %al,(%edx)
}
f010308a:	5d                   	pop    %ebp
f010308b:	c3                   	ret    

f010308c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010308c:	55                   	push   %ebp
f010308d:	89 e5                	mov    %esp,%ebp
f010308f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103092:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103095:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103099:	8b 45 10             	mov    0x10(%ebp),%eax
f010309c:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01030aa:	89 04 24             	mov    %eax,(%esp)
f01030ad:	e8 02 00 00 00       	call   f01030b4 <vprintfmt>
	va_end(ap);
}
f01030b2:	c9                   	leave  
f01030b3:	c3                   	ret    

f01030b4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01030b4:	55                   	push   %ebp
f01030b5:	89 e5                	mov    %esp,%ebp
f01030b7:	57                   	push   %edi
f01030b8:	56                   	push   %esi
f01030b9:	53                   	push   %ebx
f01030ba:	83 ec 3c             	sub    $0x3c,%esp
f01030bd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01030c0:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01030c3:	eb 1b                	jmp    f01030e0 <vprintfmt+0x2c>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01030c5:	85 c0                	test   %eax,%eax
f01030c7:	0f 84 c6 03 00 00    	je     f0103493 <vprintfmt+0x3df>
				return;
			putch(ch | 0x0200, putdat);
f01030cd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030d1:	80 cc 02             	or     $0x2,%ah
f01030d4:	89 04 24             	mov    %eax,(%esp)
f01030d7:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01030da:	89 f3                	mov    %esi,%ebx
f01030dc:	eb 02                	jmp    f01030e0 <vprintfmt+0x2c>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f01030de:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01030e0:	8d 73 01             	lea    0x1(%ebx),%esi
f01030e3:	0f b6 03             	movzbl (%ebx),%eax
f01030e6:	83 f8 25             	cmp    $0x25,%eax
f01030e9:	75 da                	jne    f01030c5 <vprintfmt+0x11>
f01030eb:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f01030ef:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01030f6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01030fd:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0103104:	ba 00 00 00 00       	mov    $0x0,%edx
f0103109:	eb 1d                	jmp    f0103128 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010310b:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010310d:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0103111:	eb 15                	jmp    f0103128 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103113:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103115:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0103119:	eb 0d                	jmp    f0103128 <vprintfmt+0x74>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010311b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010311e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103121:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103128:	8d 5e 01             	lea    0x1(%esi),%ebx
f010312b:	0f b6 06             	movzbl (%esi),%eax
f010312e:	0f b6 c8             	movzbl %al,%ecx
f0103131:	83 e8 23             	sub    $0x23,%eax
f0103134:	3c 55                	cmp    $0x55,%al
f0103136:	0f 87 2f 03 00 00    	ja     f010346b <vprintfmt+0x3b7>
f010313c:	0f b6 c0             	movzbl %al,%eax
f010313f:	ff 24 85 24 4c 10 f0 	jmp    *-0xfefb3dc(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103146:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0103149:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f010314c:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0103150:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0103153:	83 f9 09             	cmp    $0x9,%ecx
f0103156:	77 50                	ja     f01031a8 <vprintfmt+0xf4>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103158:	89 de                	mov    %ebx,%esi
f010315a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010315d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0103160:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103163:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103167:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010316a:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010316d:	83 fb 09             	cmp    $0x9,%ebx
f0103170:	76 eb                	jbe    f010315d <vprintfmt+0xa9>
f0103172:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103175:	eb 33                	jmp    f01031aa <vprintfmt+0xf6>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103177:	8b 45 14             	mov    0x14(%ebp),%eax
f010317a:	8d 48 04             	lea    0x4(%eax),%ecx
f010317d:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103180:	8b 00                	mov    (%eax),%eax
f0103182:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103185:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103187:	eb 21                	jmp    f01031aa <vprintfmt+0xf6>
f0103189:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010318c:	85 c9                	test   %ecx,%ecx
f010318e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103193:	0f 49 c1             	cmovns %ecx,%eax
f0103196:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103199:	89 de                	mov    %ebx,%esi
f010319b:	eb 8b                	jmp    f0103128 <vprintfmt+0x74>
f010319d:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010319f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01031a6:	eb 80                	jmp    f0103128 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031a8:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01031aa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01031ae:	0f 89 74 ff ff ff    	jns    f0103128 <vprintfmt+0x74>
f01031b4:	e9 62 ff ff ff       	jmp    f010311b <vprintfmt+0x67>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01031b9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031bc:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01031be:	e9 65 ff ff ff       	jmp    f0103128 <vprintfmt+0x74>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01031c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01031c6:	8d 50 04             	lea    0x4(%eax),%edx
f01031c9:	89 55 14             	mov    %edx,0x14(%ebp)
f01031cc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031d0:	8b 00                	mov    (%eax),%eax
f01031d2:	89 04 24             	mov    %eax,(%esp)
f01031d5:	ff 55 08             	call   *0x8(%ebp)
			break;
f01031d8:	e9 03 ff ff ff       	jmp    f01030e0 <vprintfmt+0x2c>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01031dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01031e0:	8d 50 04             	lea    0x4(%eax),%edx
f01031e3:	89 55 14             	mov    %edx,0x14(%ebp)
f01031e6:	8b 00                	mov    (%eax),%eax
f01031e8:	99                   	cltd   
f01031e9:	31 d0                	xor    %edx,%eax
f01031eb:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01031ed:	83 f8 06             	cmp    $0x6,%eax
f01031f0:	7f 0b                	jg     f01031fd <vprintfmt+0x149>
f01031f2:	8b 14 85 7c 4d 10 f0 	mov    -0xfefb284(,%eax,4),%edx
f01031f9:	85 d2                	test   %edx,%edx
f01031fb:	75 20                	jne    f010321d <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
f01031fd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103201:	c7 44 24 08 af 4b 10 	movl   $0xf0104baf,0x8(%esp)
f0103208:	f0 
f0103209:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010320d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103210:	89 04 24             	mov    %eax,(%esp)
f0103213:	e8 74 fe ff ff       	call   f010308c <printfmt>
f0103218:	e9 c3 fe ff ff       	jmp    f01030e0 <vprintfmt+0x2c>
			else
				printfmt(putch, putdat, "%s", p);
f010321d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103221:	c7 44 24 08 ac 48 10 	movl   $0xf01048ac,0x8(%esp)
f0103228:	f0 
f0103229:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010322d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103230:	89 04 24             	mov    %eax,(%esp)
f0103233:	e8 54 fe ff ff       	call   f010308c <printfmt>
f0103238:	e9 a3 fe ff ff       	jmp    f01030e0 <vprintfmt+0x2c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010323d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103240:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103243:	8b 45 14             	mov    0x14(%ebp),%eax
f0103246:	8d 50 04             	lea    0x4(%eax),%edx
f0103249:	89 55 14             	mov    %edx,0x14(%ebp)
f010324c:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f010324e:	85 c0                	test   %eax,%eax
f0103250:	ba a8 4b 10 f0       	mov    $0xf0104ba8,%edx
f0103255:	0f 45 d0             	cmovne %eax,%edx
f0103258:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f010325b:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f010325f:	74 04                	je     f0103265 <vprintfmt+0x1b1>
f0103261:	85 f6                	test   %esi,%esi
f0103263:	7f 19                	jg     f010327e <vprintfmt+0x1ca>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103265:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103268:	8d 70 01             	lea    0x1(%eax),%esi
f010326b:	0f b6 10             	movzbl (%eax),%edx
f010326e:	0f be c2             	movsbl %dl,%eax
f0103271:	85 c0                	test   %eax,%eax
f0103273:	0f 85 95 00 00 00    	jne    f010330e <vprintfmt+0x25a>
f0103279:	e9 85 00 00 00       	jmp    f0103303 <vprintfmt+0x24f>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010327e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103282:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103285:	89 04 24             	mov    %eax,(%esp)
f0103288:	e8 85 03 00 00       	call   f0103612 <strnlen>
f010328d:	29 c6                	sub    %eax,%esi
f010328f:	89 f0                	mov    %esi,%eax
f0103291:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103294:	85 f6                	test   %esi,%esi
f0103296:	7e cd                	jle    f0103265 <vprintfmt+0x1b1>
					putch(padc, putdat);
f0103298:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f010329c:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010329f:	89 c3                	mov    %eax,%ebx
f01032a1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032a5:	89 34 24             	mov    %esi,(%esp)
f01032a8:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01032ab:	83 eb 01             	sub    $0x1,%ebx
f01032ae:	75 f1                	jne    f01032a1 <vprintfmt+0x1ed>
f01032b0:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01032b3:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01032b6:	eb ad                	jmp    f0103265 <vprintfmt+0x1b1>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01032b8:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01032bc:	74 1e                	je     f01032dc <vprintfmt+0x228>
f01032be:	0f be d2             	movsbl %dl,%edx
f01032c1:	83 ea 20             	sub    $0x20,%edx
f01032c4:	83 fa 5e             	cmp    $0x5e,%edx
f01032c7:	76 13                	jbe    f01032dc <vprintfmt+0x228>
					putch('?', putdat);
f01032c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032d0:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01032d7:	ff 55 08             	call   *0x8(%ebp)
f01032da:	eb 0d                	jmp    f01032e9 <vprintfmt+0x235>
				else
					putch(ch, putdat);
f01032dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01032df:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01032e3:	89 04 24             	mov    %eax,(%esp)
f01032e6:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01032e9:	83 ef 01             	sub    $0x1,%edi
f01032ec:	83 c6 01             	add    $0x1,%esi
f01032ef:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01032f3:	0f be c2             	movsbl %dl,%eax
f01032f6:	85 c0                	test   %eax,%eax
f01032f8:	75 20                	jne    f010331a <vprintfmt+0x266>
f01032fa:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01032fd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103300:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103303:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103307:	7f 25                	jg     f010332e <vprintfmt+0x27a>
f0103309:	e9 d2 fd ff ff       	jmp    f01030e0 <vprintfmt+0x2c>
f010330e:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103311:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103314:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103317:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010331a:	85 db                	test   %ebx,%ebx
f010331c:	78 9a                	js     f01032b8 <vprintfmt+0x204>
f010331e:	83 eb 01             	sub    $0x1,%ebx
f0103321:	79 95                	jns    f01032b8 <vprintfmt+0x204>
f0103323:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0103326:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103329:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010332c:	eb d5                	jmp    f0103303 <vprintfmt+0x24f>
f010332e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103331:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103334:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103337:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010333b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103342:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103344:	83 eb 01             	sub    $0x1,%ebx
f0103347:	75 ee                	jne    f0103337 <vprintfmt+0x283>
f0103349:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010334c:	e9 8f fd ff ff       	jmp    f01030e0 <vprintfmt+0x2c>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103351:	83 fa 01             	cmp    $0x1,%edx
f0103354:	7e 16                	jle    f010336c <vprintfmt+0x2b8>
		return va_arg(*ap, long long);
f0103356:	8b 45 14             	mov    0x14(%ebp),%eax
f0103359:	8d 50 08             	lea    0x8(%eax),%edx
f010335c:	89 55 14             	mov    %edx,0x14(%ebp)
f010335f:	8b 50 04             	mov    0x4(%eax),%edx
f0103362:	8b 00                	mov    (%eax),%eax
f0103364:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103367:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010336a:	eb 32                	jmp    f010339e <vprintfmt+0x2ea>
	else if (lflag)
f010336c:	85 d2                	test   %edx,%edx
f010336e:	74 18                	je     f0103388 <vprintfmt+0x2d4>
		return va_arg(*ap, long);
f0103370:	8b 45 14             	mov    0x14(%ebp),%eax
f0103373:	8d 50 04             	lea    0x4(%eax),%edx
f0103376:	89 55 14             	mov    %edx,0x14(%ebp)
f0103379:	8b 30                	mov    (%eax),%esi
f010337b:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010337e:	89 f0                	mov    %esi,%eax
f0103380:	c1 f8 1f             	sar    $0x1f,%eax
f0103383:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103386:	eb 16                	jmp    f010339e <vprintfmt+0x2ea>
	else
		return va_arg(*ap, int);
f0103388:	8b 45 14             	mov    0x14(%ebp),%eax
f010338b:	8d 50 04             	lea    0x4(%eax),%edx
f010338e:	89 55 14             	mov    %edx,0x14(%ebp)
f0103391:	8b 30                	mov    (%eax),%esi
f0103393:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0103396:	89 f0                	mov    %esi,%eax
f0103398:	c1 f8 1f             	sar    $0x1f,%eax
f010339b:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010339e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01033a1:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01033a4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01033a9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01033ad:	0f 89 80 00 00 00    	jns    f0103433 <vprintfmt+0x37f>
				putch('-', putdat);
f01033b3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033b7:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01033be:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01033c1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01033c4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01033c7:	f7 d8                	neg    %eax
f01033c9:	83 d2 00             	adc    $0x0,%edx
f01033cc:	f7 da                	neg    %edx
			}
			base = 10;
f01033ce:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01033d3:	eb 5e                	jmp    f0103433 <vprintfmt+0x37f>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01033d5:	8d 45 14             	lea    0x14(%ebp),%eax
f01033d8:	e8 58 fc ff ff       	call   f0103035 <getuint>
			base = 10;
f01033dd:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01033e2:	eb 4f                	jmp    f0103433 <vprintfmt+0x37f>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01033e4:	8d 45 14             	lea    0x14(%ebp),%eax
f01033e7:	e8 49 fc ff ff       	call   f0103035 <getuint>
			base = 8;
f01033ec:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01033f1:	eb 40                	jmp    f0103433 <vprintfmt+0x37f>

		// pointer
		case 'p':
			putch('0', putdat);
f01033f3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033f7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01033fe:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103401:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103405:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010340c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010340f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103412:	8d 50 04             	lea    0x4(%eax),%edx
f0103415:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103418:	8b 00                	mov    (%eax),%eax
f010341a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010341f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103424:	eb 0d                	jmp    f0103433 <vprintfmt+0x37f>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103426:	8d 45 14             	lea    0x14(%ebp),%eax
f0103429:	e8 07 fc ff ff       	call   f0103035 <getuint>
			base = 16;
f010342e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103433:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0103437:	89 74 24 10          	mov    %esi,0x10(%esp)
f010343b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010343e:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103442:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103446:	89 04 24             	mov    %eax,(%esp)
f0103449:	89 54 24 04          	mov    %edx,0x4(%esp)
f010344d:	89 fa                	mov    %edi,%edx
f010344f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103452:	e8 e9 fa ff ff       	call   f0102f40 <printnum>
			break;
f0103457:	e9 84 fc ff ff       	jmp    f01030e0 <vprintfmt+0x2c>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010345c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103460:	89 0c 24             	mov    %ecx,(%esp)
f0103463:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103466:	e9 75 fc ff ff       	jmp    f01030e0 <vprintfmt+0x2c>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010346b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010346f:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103476:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103479:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010347d:	0f 84 5b fc ff ff    	je     f01030de <vprintfmt+0x2a>
f0103483:	89 f3                	mov    %esi,%ebx
f0103485:	83 eb 01             	sub    $0x1,%ebx
f0103488:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010348c:	75 f7                	jne    f0103485 <vprintfmt+0x3d1>
f010348e:	e9 4d fc ff ff       	jmp    f01030e0 <vprintfmt+0x2c>
				/* do nothing */;
			break;
		}
	}
}
f0103493:	83 c4 3c             	add    $0x3c,%esp
f0103496:	5b                   	pop    %ebx
f0103497:	5e                   	pop    %esi
f0103498:	5f                   	pop    %edi
f0103499:	5d                   	pop    %ebp
f010349a:	c3                   	ret    

f010349b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010349b:	55                   	push   %ebp
f010349c:	89 e5                	mov    %esp,%ebp
f010349e:	83 ec 28             	sub    $0x28,%esp
f01034a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01034a4:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01034a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01034aa:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01034ae:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01034b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01034b8:	85 c0                	test   %eax,%eax
f01034ba:	74 30                	je     f01034ec <vsnprintf+0x51>
f01034bc:	85 d2                	test   %edx,%edx
f01034be:	7e 2c                	jle    f01034ec <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01034c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01034c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034c7:	8b 45 10             	mov    0x10(%ebp),%eax
f01034ca:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034ce:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01034d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034d5:	c7 04 24 6f 30 10 f0 	movl   $0xf010306f,(%esp)
f01034dc:	e8 d3 fb ff ff       	call   f01030b4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01034e1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01034e4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01034e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01034ea:	eb 05                	jmp    f01034f1 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01034ec:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01034f1:	c9                   	leave  
f01034f2:	c3                   	ret    

f01034f3 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01034f3:	55                   	push   %ebp
f01034f4:	89 e5                	mov    %esp,%ebp
f01034f6:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01034f9:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01034fc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103500:	8b 45 10             	mov    0x10(%ebp),%eax
f0103503:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103507:	8b 45 0c             	mov    0xc(%ebp),%eax
f010350a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010350e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103511:	89 04 24             	mov    %eax,(%esp)
f0103514:	e8 82 ff ff ff       	call   f010349b <vsnprintf>
	va_end(ap);

	return rc;
}
f0103519:	c9                   	leave  
f010351a:	c3                   	ret    
f010351b:	66 90                	xchg   %ax,%ax
f010351d:	66 90                	xchg   %ax,%ax
f010351f:	90                   	nop

f0103520 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103520:	55                   	push   %ebp
f0103521:	89 e5                	mov    %esp,%ebp
f0103523:	57                   	push   %edi
f0103524:	56                   	push   %esi
f0103525:	53                   	push   %ebx
f0103526:	83 ec 1c             	sub    $0x1c,%esp
f0103529:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010352c:	85 c0                	test   %eax,%eax
f010352e:	74 10                	je     f0103540 <readline+0x20>
		cprintf("%s", prompt);
f0103530:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103534:	c7 04 24 ac 48 10 f0 	movl   $0xf01048ac,(%esp)
f010353b:	e8 f5 f6 ff ff       	call   f0102c35 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103540:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103547:	e8 c2 d0 ff ff       	call   f010060e <iscons>
f010354c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010354e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103553:	e8 a5 d0 ff ff       	call   f01005fd <getchar>
f0103558:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010355a:	85 c0                	test   %eax,%eax
f010355c:	79 17                	jns    f0103575 <readline+0x55>
			cprintf("read error: %e\n", c);
f010355e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103562:	c7 04 24 98 4d 10 f0 	movl   $0xf0104d98,(%esp)
f0103569:	e8 c7 f6 ff ff       	call   f0102c35 <cprintf>
			return NULL;
f010356e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103573:	eb 6d                	jmp    f01035e2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103575:	83 f8 7f             	cmp    $0x7f,%eax
f0103578:	74 05                	je     f010357f <readline+0x5f>
f010357a:	83 f8 08             	cmp    $0x8,%eax
f010357d:	75 19                	jne    f0103598 <readline+0x78>
f010357f:	85 f6                	test   %esi,%esi
f0103581:	7e 15                	jle    f0103598 <readline+0x78>
			if (echoing)
f0103583:	85 ff                	test   %edi,%edi
f0103585:	74 0c                	je     f0103593 <readline+0x73>
				cputchar('\b');
f0103587:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010358e:	e8 5a d0 ff ff       	call   f01005ed <cputchar>
			i--;
f0103593:	83 ee 01             	sub    $0x1,%esi
f0103596:	eb bb                	jmp    f0103553 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103598:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010359e:	7f 1c                	jg     f01035bc <readline+0x9c>
f01035a0:	83 fb 1f             	cmp    $0x1f,%ebx
f01035a3:	7e 17                	jle    f01035bc <readline+0x9c>
			if (echoing)
f01035a5:	85 ff                	test   %edi,%edi
f01035a7:	74 08                	je     f01035b1 <readline+0x91>
				cputchar(c);
f01035a9:	89 1c 24             	mov    %ebx,(%esp)
f01035ac:	e8 3c d0 ff ff       	call   f01005ed <cputchar>
			buf[i++] = c;
f01035b1:	88 9e 80 75 11 f0    	mov    %bl,-0xfee8a80(%esi)
f01035b7:	8d 76 01             	lea    0x1(%esi),%esi
f01035ba:	eb 97                	jmp    f0103553 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01035bc:	83 fb 0d             	cmp    $0xd,%ebx
f01035bf:	74 05                	je     f01035c6 <readline+0xa6>
f01035c1:	83 fb 0a             	cmp    $0xa,%ebx
f01035c4:	75 8d                	jne    f0103553 <readline+0x33>
			if (echoing)
f01035c6:	85 ff                	test   %edi,%edi
f01035c8:	74 0c                	je     f01035d6 <readline+0xb6>
				cputchar('\n');
f01035ca:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01035d1:	e8 17 d0 ff ff       	call   f01005ed <cputchar>
			buf[i] = 0;
f01035d6:	c6 86 80 75 11 f0 00 	movb   $0x0,-0xfee8a80(%esi)
			return buf;
f01035dd:	b8 80 75 11 f0       	mov    $0xf0117580,%eax
		}
	}
}
f01035e2:	83 c4 1c             	add    $0x1c,%esp
f01035e5:	5b                   	pop    %ebx
f01035e6:	5e                   	pop    %esi
f01035e7:	5f                   	pop    %edi
f01035e8:	5d                   	pop    %ebp
f01035e9:	c3                   	ret    
f01035ea:	66 90                	xchg   %ax,%ax
f01035ec:	66 90                	xchg   %ax,%ax
f01035ee:	66 90                	xchg   %ax,%ax

f01035f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01035f0:	55                   	push   %ebp
f01035f1:	89 e5                	mov    %esp,%ebp
f01035f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01035f6:	80 3a 00             	cmpb   $0x0,(%edx)
f01035f9:	74 10                	je     f010360b <strlen+0x1b>
f01035fb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0103600:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103603:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103607:	75 f7                	jne    f0103600 <strlen+0x10>
f0103609:	eb 05                	jmp    f0103610 <strlen+0x20>
f010360b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103610:	5d                   	pop    %ebp
f0103611:	c3                   	ret    

f0103612 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103612:	55                   	push   %ebp
f0103613:	89 e5                	mov    %esp,%ebp
f0103615:	53                   	push   %ebx
f0103616:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103619:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010361c:	85 c9                	test   %ecx,%ecx
f010361e:	74 1c                	je     f010363c <strnlen+0x2a>
f0103620:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103623:	74 1e                	je     f0103643 <strnlen+0x31>
f0103625:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010362a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010362c:	39 ca                	cmp    %ecx,%edx
f010362e:	74 18                	je     f0103648 <strnlen+0x36>
f0103630:	83 c2 01             	add    $0x1,%edx
f0103633:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103638:	75 f0                	jne    f010362a <strnlen+0x18>
f010363a:	eb 0c                	jmp    f0103648 <strnlen+0x36>
f010363c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103641:	eb 05                	jmp    f0103648 <strnlen+0x36>
f0103643:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103648:	5b                   	pop    %ebx
f0103649:	5d                   	pop    %ebp
f010364a:	c3                   	ret    

f010364b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010364b:	55                   	push   %ebp
f010364c:	89 e5                	mov    %esp,%ebp
f010364e:	53                   	push   %ebx
f010364f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103652:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103655:	89 c2                	mov    %eax,%edx
f0103657:	83 c2 01             	add    $0x1,%edx
f010365a:	83 c1 01             	add    $0x1,%ecx
f010365d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103661:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103664:	84 db                	test   %bl,%bl
f0103666:	75 ef                	jne    f0103657 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103668:	5b                   	pop    %ebx
f0103669:	5d                   	pop    %ebp
f010366a:	c3                   	ret    

f010366b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010366b:	55                   	push   %ebp
f010366c:	89 e5                	mov    %esp,%ebp
f010366e:	56                   	push   %esi
f010366f:	53                   	push   %ebx
f0103670:	8b 75 08             	mov    0x8(%ebp),%esi
f0103673:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103676:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103679:	85 db                	test   %ebx,%ebx
f010367b:	74 17                	je     f0103694 <strncpy+0x29>
f010367d:	01 f3                	add    %esi,%ebx
f010367f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0103681:	83 c1 01             	add    $0x1,%ecx
f0103684:	0f b6 02             	movzbl (%edx),%eax
f0103687:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010368a:	80 3a 01             	cmpb   $0x1,(%edx)
f010368d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103690:	39 d9                	cmp    %ebx,%ecx
f0103692:	75 ed                	jne    f0103681 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103694:	89 f0                	mov    %esi,%eax
f0103696:	5b                   	pop    %ebx
f0103697:	5e                   	pop    %esi
f0103698:	5d                   	pop    %ebp
f0103699:	c3                   	ret    

f010369a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010369a:	55                   	push   %ebp
f010369b:	89 e5                	mov    %esp,%ebp
f010369d:	57                   	push   %edi
f010369e:	56                   	push   %esi
f010369f:	53                   	push   %ebx
f01036a0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01036a3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01036a6:	8b 75 10             	mov    0x10(%ebp),%esi
f01036a9:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01036ab:	85 f6                	test   %esi,%esi
f01036ad:	74 34                	je     f01036e3 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f01036af:	83 fe 01             	cmp    $0x1,%esi
f01036b2:	74 26                	je     f01036da <strlcpy+0x40>
f01036b4:	0f b6 0b             	movzbl (%ebx),%ecx
f01036b7:	84 c9                	test   %cl,%cl
f01036b9:	74 23                	je     f01036de <strlcpy+0x44>
f01036bb:	83 ee 02             	sub    $0x2,%esi
f01036be:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f01036c3:	83 c0 01             	add    $0x1,%eax
f01036c6:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01036c9:	39 f2                	cmp    %esi,%edx
f01036cb:	74 13                	je     f01036e0 <strlcpy+0x46>
f01036cd:	83 c2 01             	add    $0x1,%edx
f01036d0:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01036d4:	84 c9                	test   %cl,%cl
f01036d6:	75 eb                	jne    f01036c3 <strlcpy+0x29>
f01036d8:	eb 06                	jmp    f01036e0 <strlcpy+0x46>
f01036da:	89 f8                	mov    %edi,%eax
f01036dc:	eb 02                	jmp    f01036e0 <strlcpy+0x46>
f01036de:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01036e0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01036e3:	29 f8                	sub    %edi,%eax
}
f01036e5:	5b                   	pop    %ebx
f01036e6:	5e                   	pop    %esi
f01036e7:	5f                   	pop    %edi
f01036e8:	5d                   	pop    %ebp
f01036e9:	c3                   	ret    

f01036ea <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01036ea:	55                   	push   %ebp
f01036eb:	89 e5                	mov    %esp,%ebp
f01036ed:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01036f0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01036f3:	0f b6 01             	movzbl (%ecx),%eax
f01036f6:	84 c0                	test   %al,%al
f01036f8:	74 15                	je     f010370f <strcmp+0x25>
f01036fa:	3a 02                	cmp    (%edx),%al
f01036fc:	75 11                	jne    f010370f <strcmp+0x25>
		p++, q++;
f01036fe:	83 c1 01             	add    $0x1,%ecx
f0103701:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103704:	0f b6 01             	movzbl (%ecx),%eax
f0103707:	84 c0                	test   %al,%al
f0103709:	74 04                	je     f010370f <strcmp+0x25>
f010370b:	3a 02                	cmp    (%edx),%al
f010370d:	74 ef                	je     f01036fe <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010370f:	0f b6 c0             	movzbl %al,%eax
f0103712:	0f b6 12             	movzbl (%edx),%edx
f0103715:	29 d0                	sub    %edx,%eax
}
f0103717:	5d                   	pop    %ebp
f0103718:	c3                   	ret    

f0103719 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103719:	55                   	push   %ebp
f010371a:	89 e5                	mov    %esp,%ebp
f010371c:	56                   	push   %esi
f010371d:	53                   	push   %ebx
f010371e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103721:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103724:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0103727:	85 f6                	test   %esi,%esi
f0103729:	74 29                	je     f0103754 <strncmp+0x3b>
f010372b:	0f b6 03             	movzbl (%ebx),%eax
f010372e:	84 c0                	test   %al,%al
f0103730:	74 30                	je     f0103762 <strncmp+0x49>
f0103732:	3a 02                	cmp    (%edx),%al
f0103734:	75 2c                	jne    f0103762 <strncmp+0x49>
f0103736:	8d 43 01             	lea    0x1(%ebx),%eax
f0103739:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f010373b:	89 c3                	mov    %eax,%ebx
f010373d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103740:	39 f0                	cmp    %esi,%eax
f0103742:	74 17                	je     f010375b <strncmp+0x42>
f0103744:	0f b6 08             	movzbl (%eax),%ecx
f0103747:	84 c9                	test   %cl,%cl
f0103749:	74 17                	je     f0103762 <strncmp+0x49>
f010374b:	83 c0 01             	add    $0x1,%eax
f010374e:	3a 0a                	cmp    (%edx),%cl
f0103750:	74 e9                	je     f010373b <strncmp+0x22>
f0103752:	eb 0e                	jmp    f0103762 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103754:	b8 00 00 00 00       	mov    $0x0,%eax
f0103759:	eb 0f                	jmp    f010376a <strncmp+0x51>
f010375b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103760:	eb 08                	jmp    f010376a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103762:	0f b6 03             	movzbl (%ebx),%eax
f0103765:	0f b6 12             	movzbl (%edx),%edx
f0103768:	29 d0                	sub    %edx,%eax
}
f010376a:	5b                   	pop    %ebx
f010376b:	5e                   	pop    %esi
f010376c:	5d                   	pop    %ebp
f010376d:	c3                   	ret    

f010376e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010376e:	55                   	push   %ebp
f010376f:	89 e5                	mov    %esp,%ebp
f0103771:	53                   	push   %ebx
f0103772:	8b 45 08             	mov    0x8(%ebp),%eax
f0103775:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0103778:	0f b6 18             	movzbl (%eax),%ebx
f010377b:	84 db                	test   %bl,%bl
f010377d:	74 1d                	je     f010379c <strchr+0x2e>
f010377f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0103781:	38 d3                	cmp    %dl,%bl
f0103783:	75 06                	jne    f010378b <strchr+0x1d>
f0103785:	eb 1a                	jmp    f01037a1 <strchr+0x33>
f0103787:	38 ca                	cmp    %cl,%dl
f0103789:	74 16                	je     f01037a1 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010378b:	83 c0 01             	add    $0x1,%eax
f010378e:	0f b6 10             	movzbl (%eax),%edx
f0103791:	84 d2                	test   %dl,%dl
f0103793:	75 f2                	jne    f0103787 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0103795:	b8 00 00 00 00       	mov    $0x0,%eax
f010379a:	eb 05                	jmp    f01037a1 <strchr+0x33>
f010379c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01037a1:	5b                   	pop    %ebx
f01037a2:	5d                   	pop    %ebp
f01037a3:	c3                   	ret    

f01037a4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01037a4:	55                   	push   %ebp
f01037a5:	89 e5                	mov    %esp,%ebp
f01037a7:	53                   	push   %ebx
f01037a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01037ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01037ae:	0f b6 18             	movzbl (%eax),%ebx
f01037b1:	84 db                	test   %bl,%bl
f01037b3:	74 17                	je     f01037cc <strfind+0x28>
f01037b5:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01037b7:	38 d3                	cmp    %dl,%bl
f01037b9:	75 07                	jne    f01037c2 <strfind+0x1e>
f01037bb:	eb 0f                	jmp    f01037cc <strfind+0x28>
f01037bd:	38 ca                	cmp    %cl,%dl
f01037bf:	90                   	nop
f01037c0:	74 0a                	je     f01037cc <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01037c2:	83 c0 01             	add    $0x1,%eax
f01037c5:	0f b6 10             	movzbl (%eax),%edx
f01037c8:	84 d2                	test   %dl,%dl
f01037ca:	75 f1                	jne    f01037bd <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f01037cc:	5b                   	pop    %ebx
f01037cd:	5d                   	pop    %ebp
f01037ce:	c3                   	ret    

f01037cf <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01037cf:	55                   	push   %ebp
f01037d0:	89 e5                	mov    %esp,%ebp
f01037d2:	57                   	push   %edi
f01037d3:	56                   	push   %esi
f01037d4:	53                   	push   %ebx
f01037d5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01037d8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01037db:	85 c9                	test   %ecx,%ecx
f01037dd:	74 36                	je     f0103815 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01037df:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01037e5:	75 28                	jne    f010380f <memset+0x40>
f01037e7:	f6 c1 03             	test   $0x3,%cl
f01037ea:	75 23                	jne    f010380f <memset+0x40>
		c &= 0xFF;
f01037ec:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01037f0:	89 d3                	mov    %edx,%ebx
f01037f2:	c1 e3 08             	shl    $0x8,%ebx
f01037f5:	89 d6                	mov    %edx,%esi
f01037f7:	c1 e6 18             	shl    $0x18,%esi
f01037fa:	89 d0                	mov    %edx,%eax
f01037fc:	c1 e0 10             	shl    $0x10,%eax
f01037ff:	09 f0                	or     %esi,%eax
f0103801:	09 c2                	or     %eax,%edx
f0103803:	89 d0                	mov    %edx,%eax
f0103805:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103807:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010380a:	fc                   	cld    
f010380b:	f3 ab                	rep stos %eax,%es:(%edi)
f010380d:	eb 06                	jmp    f0103815 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010380f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103812:	fc                   	cld    
f0103813:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103815:	89 f8                	mov    %edi,%eax
f0103817:	5b                   	pop    %ebx
f0103818:	5e                   	pop    %esi
f0103819:	5f                   	pop    %edi
f010381a:	5d                   	pop    %ebp
f010381b:	c3                   	ret    

f010381c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010381c:	55                   	push   %ebp
f010381d:	89 e5                	mov    %esp,%ebp
f010381f:	57                   	push   %edi
f0103820:	56                   	push   %esi
f0103821:	8b 45 08             	mov    0x8(%ebp),%eax
f0103824:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103827:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010382a:	39 c6                	cmp    %eax,%esi
f010382c:	73 35                	jae    f0103863 <memmove+0x47>
f010382e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103831:	39 d0                	cmp    %edx,%eax
f0103833:	73 2e                	jae    f0103863 <memmove+0x47>
		s += n;
		d += n;
f0103835:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0103838:	89 d6                	mov    %edx,%esi
f010383a:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010383c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103842:	75 13                	jne    f0103857 <memmove+0x3b>
f0103844:	f6 c1 03             	test   $0x3,%cl
f0103847:	75 0e                	jne    f0103857 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103849:	83 ef 04             	sub    $0x4,%edi
f010384c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010384f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103852:	fd                   	std    
f0103853:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103855:	eb 09                	jmp    f0103860 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103857:	83 ef 01             	sub    $0x1,%edi
f010385a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010385d:	fd                   	std    
f010385e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103860:	fc                   	cld    
f0103861:	eb 1d                	jmp    f0103880 <memmove+0x64>
f0103863:	89 f2                	mov    %esi,%edx
f0103865:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103867:	f6 c2 03             	test   $0x3,%dl
f010386a:	75 0f                	jne    f010387b <memmove+0x5f>
f010386c:	f6 c1 03             	test   $0x3,%cl
f010386f:	75 0a                	jne    f010387b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103871:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103874:	89 c7                	mov    %eax,%edi
f0103876:	fc                   	cld    
f0103877:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103879:	eb 05                	jmp    f0103880 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010387b:	89 c7                	mov    %eax,%edi
f010387d:	fc                   	cld    
f010387e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103880:	5e                   	pop    %esi
f0103881:	5f                   	pop    %edi
f0103882:	5d                   	pop    %ebp
f0103883:	c3                   	ret    

f0103884 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103884:	55                   	push   %ebp
f0103885:	89 e5                	mov    %esp,%ebp
f0103887:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010388a:	8b 45 10             	mov    0x10(%ebp),%eax
f010388d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103891:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103894:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103898:	8b 45 08             	mov    0x8(%ebp),%eax
f010389b:	89 04 24             	mov    %eax,(%esp)
f010389e:	e8 79 ff ff ff       	call   f010381c <memmove>
}
f01038a3:	c9                   	leave  
f01038a4:	c3                   	ret    

f01038a5 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01038a5:	55                   	push   %ebp
f01038a6:	89 e5                	mov    %esp,%ebp
f01038a8:	57                   	push   %edi
f01038a9:	56                   	push   %esi
f01038aa:	53                   	push   %ebx
f01038ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01038ae:	8b 75 0c             	mov    0xc(%ebp),%esi
f01038b1:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01038b4:	8d 78 ff             	lea    -0x1(%eax),%edi
f01038b7:	85 c0                	test   %eax,%eax
f01038b9:	74 36                	je     f01038f1 <memcmp+0x4c>
		if (*s1 != *s2)
f01038bb:	0f b6 03             	movzbl (%ebx),%eax
f01038be:	0f b6 0e             	movzbl (%esi),%ecx
f01038c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01038c6:	38 c8                	cmp    %cl,%al
f01038c8:	74 1c                	je     f01038e6 <memcmp+0x41>
f01038ca:	eb 10                	jmp    f01038dc <memcmp+0x37>
f01038cc:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01038d1:	83 c2 01             	add    $0x1,%edx
f01038d4:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01038d8:	38 c8                	cmp    %cl,%al
f01038da:	74 0a                	je     f01038e6 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01038dc:	0f b6 c0             	movzbl %al,%eax
f01038df:	0f b6 c9             	movzbl %cl,%ecx
f01038e2:	29 c8                	sub    %ecx,%eax
f01038e4:	eb 10                	jmp    f01038f6 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01038e6:	39 fa                	cmp    %edi,%edx
f01038e8:	75 e2                	jne    f01038cc <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01038ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01038ef:	eb 05                	jmp    f01038f6 <memcmp+0x51>
f01038f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038f6:	5b                   	pop    %ebx
f01038f7:	5e                   	pop    %esi
f01038f8:	5f                   	pop    %edi
f01038f9:	5d                   	pop    %ebp
f01038fa:	c3                   	ret    

f01038fb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01038fb:	55                   	push   %ebp
f01038fc:	89 e5                	mov    %esp,%ebp
f01038fe:	53                   	push   %ebx
f01038ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103902:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0103905:	89 c2                	mov    %eax,%edx
f0103907:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010390a:	39 d0                	cmp    %edx,%eax
f010390c:	73 14                	jae    f0103922 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f010390e:	89 d9                	mov    %ebx,%ecx
f0103910:	38 18                	cmp    %bl,(%eax)
f0103912:	75 06                	jne    f010391a <memfind+0x1f>
f0103914:	eb 0c                	jmp    f0103922 <memfind+0x27>
f0103916:	38 08                	cmp    %cl,(%eax)
f0103918:	74 08                	je     f0103922 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010391a:	83 c0 01             	add    $0x1,%eax
f010391d:	39 d0                	cmp    %edx,%eax
f010391f:	90                   	nop
f0103920:	75 f4                	jne    f0103916 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103922:	5b                   	pop    %ebx
f0103923:	5d                   	pop    %ebp
f0103924:	c3                   	ret    

f0103925 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103925:	55                   	push   %ebp
f0103926:	89 e5                	mov    %esp,%ebp
f0103928:	57                   	push   %edi
f0103929:	56                   	push   %esi
f010392a:	53                   	push   %ebx
f010392b:	8b 55 08             	mov    0x8(%ebp),%edx
f010392e:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103931:	0f b6 0a             	movzbl (%edx),%ecx
f0103934:	80 f9 09             	cmp    $0x9,%cl
f0103937:	74 05                	je     f010393e <strtol+0x19>
f0103939:	80 f9 20             	cmp    $0x20,%cl
f010393c:	75 10                	jne    f010394e <strtol+0x29>
		s++;
f010393e:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103941:	0f b6 0a             	movzbl (%edx),%ecx
f0103944:	80 f9 09             	cmp    $0x9,%cl
f0103947:	74 f5                	je     f010393e <strtol+0x19>
f0103949:	80 f9 20             	cmp    $0x20,%cl
f010394c:	74 f0                	je     f010393e <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f010394e:	80 f9 2b             	cmp    $0x2b,%cl
f0103951:	75 0a                	jne    f010395d <strtol+0x38>
		s++;
f0103953:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103956:	bf 00 00 00 00       	mov    $0x0,%edi
f010395b:	eb 11                	jmp    f010396e <strtol+0x49>
f010395d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103962:	80 f9 2d             	cmp    $0x2d,%cl
f0103965:	75 07                	jne    f010396e <strtol+0x49>
		s++, neg = 1;
f0103967:	83 c2 01             	add    $0x1,%edx
f010396a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010396e:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103973:	75 15                	jne    f010398a <strtol+0x65>
f0103975:	80 3a 30             	cmpb   $0x30,(%edx)
f0103978:	75 10                	jne    f010398a <strtol+0x65>
f010397a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010397e:	75 0a                	jne    f010398a <strtol+0x65>
		s += 2, base = 16;
f0103980:	83 c2 02             	add    $0x2,%edx
f0103983:	b8 10 00 00 00       	mov    $0x10,%eax
f0103988:	eb 10                	jmp    f010399a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f010398a:	85 c0                	test   %eax,%eax
f010398c:	75 0c                	jne    f010399a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010398e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103990:	80 3a 30             	cmpb   $0x30,(%edx)
f0103993:	75 05                	jne    f010399a <strtol+0x75>
		s++, base = 8;
f0103995:	83 c2 01             	add    $0x1,%edx
f0103998:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010399a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010399f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01039a2:	0f b6 0a             	movzbl (%edx),%ecx
f01039a5:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01039a8:	89 f0                	mov    %esi,%eax
f01039aa:	3c 09                	cmp    $0x9,%al
f01039ac:	77 08                	ja     f01039b6 <strtol+0x91>
			dig = *s - '0';
f01039ae:	0f be c9             	movsbl %cl,%ecx
f01039b1:	83 e9 30             	sub    $0x30,%ecx
f01039b4:	eb 20                	jmp    f01039d6 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f01039b6:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01039b9:	89 f0                	mov    %esi,%eax
f01039bb:	3c 19                	cmp    $0x19,%al
f01039bd:	77 08                	ja     f01039c7 <strtol+0xa2>
			dig = *s - 'a' + 10;
f01039bf:	0f be c9             	movsbl %cl,%ecx
f01039c2:	83 e9 57             	sub    $0x57,%ecx
f01039c5:	eb 0f                	jmp    f01039d6 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f01039c7:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01039ca:	89 f0                	mov    %esi,%eax
f01039cc:	3c 19                	cmp    $0x19,%al
f01039ce:	77 16                	ja     f01039e6 <strtol+0xc1>
			dig = *s - 'A' + 10;
f01039d0:	0f be c9             	movsbl %cl,%ecx
f01039d3:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01039d6:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01039d9:	7d 0f                	jge    f01039ea <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01039db:	83 c2 01             	add    $0x1,%edx
f01039de:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01039e2:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01039e4:	eb bc                	jmp    f01039a2 <strtol+0x7d>
f01039e6:	89 d8                	mov    %ebx,%eax
f01039e8:	eb 02                	jmp    f01039ec <strtol+0xc7>
f01039ea:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01039ec:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01039f0:	74 05                	je     f01039f7 <strtol+0xd2>
		*endptr = (char *) s;
f01039f2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01039f5:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01039f7:	f7 d8                	neg    %eax
f01039f9:	85 ff                	test   %edi,%edi
f01039fb:	0f 44 c3             	cmove  %ebx,%eax
}
f01039fe:	5b                   	pop    %ebx
f01039ff:	5e                   	pop    %esi
f0103a00:	5f                   	pop    %edi
f0103a01:	5d                   	pop    %ebp
f0103a02:	c3                   	ret    
f0103a03:	66 90                	xchg   %ax,%ax
f0103a05:	66 90                	xchg   %ax,%ax
f0103a07:	66 90                	xchg   %ax,%ax
f0103a09:	66 90                	xchg   %ax,%ax
f0103a0b:	66 90                	xchg   %ax,%ax
f0103a0d:	66 90                	xchg   %ax,%ax
f0103a0f:	90                   	nop

f0103a10 <__udivdi3>:
f0103a10:	55                   	push   %ebp
f0103a11:	57                   	push   %edi
f0103a12:	56                   	push   %esi
f0103a13:	83 ec 0c             	sub    $0xc,%esp
f0103a16:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103a1a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103a1e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103a22:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103a26:	85 c0                	test   %eax,%eax
f0103a28:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103a2c:	89 ea                	mov    %ebp,%edx
f0103a2e:	89 0c 24             	mov    %ecx,(%esp)
f0103a31:	75 2d                	jne    f0103a60 <__udivdi3+0x50>
f0103a33:	39 e9                	cmp    %ebp,%ecx
f0103a35:	77 61                	ja     f0103a98 <__udivdi3+0x88>
f0103a37:	85 c9                	test   %ecx,%ecx
f0103a39:	89 ce                	mov    %ecx,%esi
f0103a3b:	75 0b                	jne    f0103a48 <__udivdi3+0x38>
f0103a3d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103a42:	31 d2                	xor    %edx,%edx
f0103a44:	f7 f1                	div    %ecx
f0103a46:	89 c6                	mov    %eax,%esi
f0103a48:	31 d2                	xor    %edx,%edx
f0103a4a:	89 e8                	mov    %ebp,%eax
f0103a4c:	f7 f6                	div    %esi
f0103a4e:	89 c5                	mov    %eax,%ebp
f0103a50:	89 f8                	mov    %edi,%eax
f0103a52:	f7 f6                	div    %esi
f0103a54:	89 ea                	mov    %ebp,%edx
f0103a56:	83 c4 0c             	add    $0xc,%esp
f0103a59:	5e                   	pop    %esi
f0103a5a:	5f                   	pop    %edi
f0103a5b:	5d                   	pop    %ebp
f0103a5c:	c3                   	ret    
f0103a5d:	8d 76 00             	lea    0x0(%esi),%esi
f0103a60:	39 e8                	cmp    %ebp,%eax
f0103a62:	77 24                	ja     f0103a88 <__udivdi3+0x78>
f0103a64:	0f bd e8             	bsr    %eax,%ebp
f0103a67:	83 f5 1f             	xor    $0x1f,%ebp
f0103a6a:	75 3c                	jne    f0103aa8 <__udivdi3+0x98>
f0103a6c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103a70:	39 34 24             	cmp    %esi,(%esp)
f0103a73:	0f 86 9f 00 00 00    	jbe    f0103b18 <__udivdi3+0x108>
f0103a79:	39 d0                	cmp    %edx,%eax
f0103a7b:	0f 82 97 00 00 00    	jb     f0103b18 <__udivdi3+0x108>
f0103a81:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103a88:	31 d2                	xor    %edx,%edx
f0103a8a:	31 c0                	xor    %eax,%eax
f0103a8c:	83 c4 0c             	add    $0xc,%esp
f0103a8f:	5e                   	pop    %esi
f0103a90:	5f                   	pop    %edi
f0103a91:	5d                   	pop    %ebp
f0103a92:	c3                   	ret    
f0103a93:	90                   	nop
f0103a94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103a98:	89 f8                	mov    %edi,%eax
f0103a9a:	f7 f1                	div    %ecx
f0103a9c:	31 d2                	xor    %edx,%edx
f0103a9e:	83 c4 0c             	add    $0xc,%esp
f0103aa1:	5e                   	pop    %esi
f0103aa2:	5f                   	pop    %edi
f0103aa3:	5d                   	pop    %ebp
f0103aa4:	c3                   	ret    
f0103aa5:	8d 76 00             	lea    0x0(%esi),%esi
f0103aa8:	89 e9                	mov    %ebp,%ecx
f0103aaa:	8b 3c 24             	mov    (%esp),%edi
f0103aad:	d3 e0                	shl    %cl,%eax
f0103aaf:	89 c6                	mov    %eax,%esi
f0103ab1:	b8 20 00 00 00       	mov    $0x20,%eax
f0103ab6:	29 e8                	sub    %ebp,%eax
f0103ab8:	89 c1                	mov    %eax,%ecx
f0103aba:	d3 ef                	shr    %cl,%edi
f0103abc:	89 e9                	mov    %ebp,%ecx
f0103abe:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103ac2:	8b 3c 24             	mov    (%esp),%edi
f0103ac5:	09 74 24 08          	or     %esi,0x8(%esp)
f0103ac9:	89 d6                	mov    %edx,%esi
f0103acb:	d3 e7                	shl    %cl,%edi
f0103acd:	89 c1                	mov    %eax,%ecx
f0103acf:	89 3c 24             	mov    %edi,(%esp)
f0103ad2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103ad6:	d3 ee                	shr    %cl,%esi
f0103ad8:	89 e9                	mov    %ebp,%ecx
f0103ada:	d3 e2                	shl    %cl,%edx
f0103adc:	89 c1                	mov    %eax,%ecx
f0103ade:	d3 ef                	shr    %cl,%edi
f0103ae0:	09 d7                	or     %edx,%edi
f0103ae2:	89 f2                	mov    %esi,%edx
f0103ae4:	89 f8                	mov    %edi,%eax
f0103ae6:	f7 74 24 08          	divl   0x8(%esp)
f0103aea:	89 d6                	mov    %edx,%esi
f0103aec:	89 c7                	mov    %eax,%edi
f0103aee:	f7 24 24             	mull   (%esp)
f0103af1:	39 d6                	cmp    %edx,%esi
f0103af3:	89 14 24             	mov    %edx,(%esp)
f0103af6:	72 30                	jb     f0103b28 <__udivdi3+0x118>
f0103af8:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103afc:	89 e9                	mov    %ebp,%ecx
f0103afe:	d3 e2                	shl    %cl,%edx
f0103b00:	39 c2                	cmp    %eax,%edx
f0103b02:	73 05                	jae    f0103b09 <__udivdi3+0xf9>
f0103b04:	3b 34 24             	cmp    (%esp),%esi
f0103b07:	74 1f                	je     f0103b28 <__udivdi3+0x118>
f0103b09:	89 f8                	mov    %edi,%eax
f0103b0b:	31 d2                	xor    %edx,%edx
f0103b0d:	e9 7a ff ff ff       	jmp    f0103a8c <__udivdi3+0x7c>
f0103b12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103b18:	31 d2                	xor    %edx,%edx
f0103b1a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b1f:	e9 68 ff ff ff       	jmp    f0103a8c <__udivdi3+0x7c>
f0103b24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b28:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103b2b:	31 d2                	xor    %edx,%edx
f0103b2d:	83 c4 0c             	add    $0xc,%esp
f0103b30:	5e                   	pop    %esi
f0103b31:	5f                   	pop    %edi
f0103b32:	5d                   	pop    %ebp
f0103b33:	c3                   	ret    
f0103b34:	66 90                	xchg   %ax,%ax
f0103b36:	66 90                	xchg   %ax,%ax
f0103b38:	66 90                	xchg   %ax,%ax
f0103b3a:	66 90                	xchg   %ax,%ax
f0103b3c:	66 90                	xchg   %ax,%ax
f0103b3e:	66 90                	xchg   %ax,%ax

f0103b40 <__umoddi3>:
f0103b40:	55                   	push   %ebp
f0103b41:	57                   	push   %edi
f0103b42:	56                   	push   %esi
f0103b43:	83 ec 14             	sub    $0x14,%esp
f0103b46:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103b4a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103b4e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103b52:	89 c7                	mov    %eax,%edi
f0103b54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b58:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103b5c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103b60:	89 34 24             	mov    %esi,(%esp)
f0103b63:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103b67:	85 c0                	test   %eax,%eax
f0103b69:	89 c2                	mov    %eax,%edx
f0103b6b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103b6f:	75 17                	jne    f0103b88 <__umoddi3+0x48>
f0103b71:	39 fe                	cmp    %edi,%esi
f0103b73:	76 4b                	jbe    f0103bc0 <__umoddi3+0x80>
f0103b75:	89 c8                	mov    %ecx,%eax
f0103b77:	89 fa                	mov    %edi,%edx
f0103b79:	f7 f6                	div    %esi
f0103b7b:	89 d0                	mov    %edx,%eax
f0103b7d:	31 d2                	xor    %edx,%edx
f0103b7f:	83 c4 14             	add    $0x14,%esp
f0103b82:	5e                   	pop    %esi
f0103b83:	5f                   	pop    %edi
f0103b84:	5d                   	pop    %ebp
f0103b85:	c3                   	ret    
f0103b86:	66 90                	xchg   %ax,%ax
f0103b88:	39 f8                	cmp    %edi,%eax
f0103b8a:	77 54                	ja     f0103be0 <__umoddi3+0xa0>
f0103b8c:	0f bd e8             	bsr    %eax,%ebp
f0103b8f:	83 f5 1f             	xor    $0x1f,%ebp
f0103b92:	75 5c                	jne    f0103bf0 <__umoddi3+0xb0>
f0103b94:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103b98:	39 3c 24             	cmp    %edi,(%esp)
f0103b9b:	0f 87 e7 00 00 00    	ja     f0103c88 <__umoddi3+0x148>
f0103ba1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103ba5:	29 f1                	sub    %esi,%ecx
f0103ba7:	19 c7                	sbb    %eax,%edi
f0103ba9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103bad:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103bb1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103bb5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103bb9:	83 c4 14             	add    $0x14,%esp
f0103bbc:	5e                   	pop    %esi
f0103bbd:	5f                   	pop    %edi
f0103bbe:	5d                   	pop    %ebp
f0103bbf:	c3                   	ret    
f0103bc0:	85 f6                	test   %esi,%esi
f0103bc2:	89 f5                	mov    %esi,%ebp
f0103bc4:	75 0b                	jne    f0103bd1 <__umoddi3+0x91>
f0103bc6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bcb:	31 d2                	xor    %edx,%edx
f0103bcd:	f7 f6                	div    %esi
f0103bcf:	89 c5                	mov    %eax,%ebp
f0103bd1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103bd5:	31 d2                	xor    %edx,%edx
f0103bd7:	f7 f5                	div    %ebp
f0103bd9:	89 c8                	mov    %ecx,%eax
f0103bdb:	f7 f5                	div    %ebp
f0103bdd:	eb 9c                	jmp    f0103b7b <__umoddi3+0x3b>
f0103bdf:	90                   	nop
f0103be0:	89 c8                	mov    %ecx,%eax
f0103be2:	89 fa                	mov    %edi,%edx
f0103be4:	83 c4 14             	add    $0x14,%esp
f0103be7:	5e                   	pop    %esi
f0103be8:	5f                   	pop    %edi
f0103be9:	5d                   	pop    %ebp
f0103bea:	c3                   	ret    
f0103beb:	90                   	nop
f0103bec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103bf0:	8b 04 24             	mov    (%esp),%eax
f0103bf3:	be 20 00 00 00       	mov    $0x20,%esi
f0103bf8:	89 e9                	mov    %ebp,%ecx
f0103bfa:	29 ee                	sub    %ebp,%esi
f0103bfc:	d3 e2                	shl    %cl,%edx
f0103bfe:	89 f1                	mov    %esi,%ecx
f0103c00:	d3 e8                	shr    %cl,%eax
f0103c02:	89 e9                	mov    %ebp,%ecx
f0103c04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c08:	8b 04 24             	mov    (%esp),%eax
f0103c0b:	09 54 24 04          	or     %edx,0x4(%esp)
f0103c0f:	89 fa                	mov    %edi,%edx
f0103c11:	d3 e0                	shl    %cl,%eax
f0103c13:	89 f1                	mov    %esi,%ecx
f0103c15:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c19:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103c1d:	d3 ea                	shr    %cl,%edx
f0103c1f:	89 e9                	mov    %ebp,%ecx
f0103c21:	d3 e7                	shl    %cl,%edi
f0103c23:	89 f1                	mov    %esi,%ecx
f0103c25:	d3 e8                	shr    %cl,%eax
f0103c27:	89 e9                	mov    %ebp,%ecx
f0103c29:	09 f8                	or     %edi,%eax
f0103c2b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103c2f:	f7 74 24 04          	divl   0x4(%esp)
f0103c33:	d3 e7                	shl    %cl,%edi
f0103c35:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c39:	89 d7                	mov    %edx,%edi
f0103c3b:	f7 64 24 08          	mull   0x8(%esp)
f0103c3f:	39 d7                	cmp    %edx,%edi
f0103c41:	89 c1                	mov    %eax,%ecx
f0103c43:	89 14 24             	mov    %edx,(%esp)
f0103c46:	72 2c                	jb     f0103c74 <__umoddi3+0x134>
f0103c48:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103c4c:	72 22                	jb     f0103c70 <__umoddi3+0x130>
f0103c4e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103c52:	29 c8                	sub    %ecx,%eax
f0103c54:	19 d7                	sbb    %edx,%edi
f0103c56:	89 e9                	mov    %ebp,%ecx
f0103c58:	89 fa                	mov    %edi,%edx
f0103c5a:	d3 e8                	shr    %cl,%eax
f0103c5c:	89 f1                	mov    %esi,%ecx
f0103c5e:	d3 e2                	shl    %cl,%edx
f0103c60:	89 e9                	mov    %ebp,%ecx
f0103c62:	d3 ef                	shr    %cl,%edi
f0103c64:	09 d0                	or     %edx,%eax
f0103c66:	89 fa                	mov    %edi,%edx
f0103c68:	83 c4 14             	add    $0x14,%esp
f0103c6b:	5e                   	pop    %esi
f0103c6c:	5f                   	pop    %edi
f0103c6d:	5d                   	pop    %ebp
f0103c6e:	c3                   	ret    
f0103c6f:	90                   	nop
f0103c70:	39 d7                	cmp    %edx,%edi
f0103c72:	75 da                	jne    f0103c4e <__umoddi3+0x10e>
f0103c74:	8b 14 24             	mov    (%esp),%edx
f0103c77:	89 c1                	mov    %eax,%ecx
f0103c79:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103c7d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103c81:	eb cb                	jmp    f0103c4e <__umoddi3+0x10e>
f0103c83:	90                   	nop
f0103c84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c88:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103c8c:	0f 82 0f ff ff ff    	jb     f0103ba1 <__umoddi3+0x61>
f0103c92:	e9 1a ff ff ff       	jmp    f0103bb1 <__umoddi3+0x71>
