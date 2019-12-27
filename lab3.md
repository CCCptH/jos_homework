lab3
===

# Part A

## 练习1

> 修改 `kern/pmap.c` 中的 `mem_init()` 函数来**分配**并**映射**`envs` 数组。这个数组恰好包含`NENV`个`Env`结构体实例，这与你分配`pages`数组的方式非常相似。另一个相似之处是，支持`envs`的内存储应该被只读映射在页表中`UENVS`的位置（于`inc/memlayout.h`中定义），所以，用户进程可以从这一数组读取数据。
> 
> 修改好后，check_kern_pgdir() 应该能够成功执行。

```Cpp
	size_t env_size = ROUNDUP(NENV * sizeof(struct Env), PGSIZE);
	envs = (struct Env* )boot_alloc(env_size);
```

分配` NENV * sizeof(struct Env)`大小的空间, 存放`envs`数组

```Cpp
	boot_map_region(kern_pgdir, UENVS, env_size, PADDR(envs), PTE_U | PTE_P);
```

将虚拟地址映射到`envs`数组上, 并设置权限

## 练习2

> 在`env.c`中，完成接下来的这些函数：
> 
> + `env_init()`初始化全部`envs`数组中的`Env`结构体，并将它们加入到`env_free_list` 中。还要调用`env_init_percpu` ，这个函数会通过配置段硬件，将其分隔为特权等级 0 (内核) 和特权等级 3（用户）两个不同的段。
> 
> + `env_setup_vm()`为新的进程分配一个页目录，并初始化新进程的地址空间对应的内核部分。
> 
> + `region_alloc()`为进程分配和映射物理内存。
> 
> + `load_icode()`你需要处理 ELF 二进制映像，就像是引导加载程序(boot loader)已经做好的那样，并将映像内容读入新进程的用户地址空间。
> 
> + `env_create()`通过调用 env_alloc 分配一个新进程，并调用`load_icode`读入`ELF`二进制映像。
> 
> + `env_run()`启动给定的在用户模式运行的进程。
> 
> 当你在完成这些函数时，你也许会发现 cprintf 的新的`%e`很好用，它会打印出与错误代码相对应的描述，例如：`r = -E_NO_MEM; panic("env_alloc: %e", r);` 会 panic 并打印出 `env_alloc: out of memory`。

### 1. `env_init()`

```Cpp
	env_free_list = NULL;
	int i;
    for (i = NENV-1; i>=0; i--)
	{
		envs[i].env_id = 0;
		envs[i].env_status = ENV_FREE;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
```

+ 由于要求第一次调用`env_alloc()`返回`envs[0]`, 所以从`NENV-1`开始遍历, 当迭代结束时,`env_free_list`指向`env[0]`

+ 根据要求, 他们的`env_ids`置为`0`, 他们的`env_status`置为`ENV_FREE`

### 2. `env_setup_vm()`

为进程分配页目录, 初始化新进程的地址空间对应的内核部分

```Cpp
	(p->pp_ref)++;
	pde_t* page_dir = page2kva(p);
	memmove(page_dir, kern_pgdir, PGSIZE);
	e->env_pgdir = page_dir;
```

+ 根据要求, 需要`pp_ref`自增1使`env_free`正常工作

+ `page2kva`获取虚拟地址, 赋值给`env_pgdir`, `env_pgdir`储存着这个进程的页目录的内核虚拟地址

+ 用`memcpy`复制到内核上

### 3. `region_alloc`

为进程分配和映射物理内存

```Cpp
	void* start = (void*)ROUNDDOWN((uint32_t)va, PGSIZE);
	void* end = (void*)ROUNDUP((uint32_t)(va+len), PGSIZE);
	struct Page* p;
	int ret = 0;
	void *i;
    for (i = start; i<end; i+=PGSIZE)
	{
		p = page_alloc(0);
		if (p == NULL)
			panic("region alloc, allocation fail");
		
		ret = page_insert(e->env_pgdir, p, i, PTE_U|PTE_W);

		if (ret!=0)
			panic("region alloc error");
	}
```

+ 根据`Hint`,对`va`向下取余, 对`len`向上取余

+ 通过`page_alloc`请求一个新页, 并将页插入页表

### 4. `load_icode()`

读入`ELF`镜像

```Cpp
    struct Elf* elfhdr = (struct Elf *)binary;
    struct Proghdr *ph, *eph;
    
    if(elfhdr->e_magic != ELF_MAGIC)
    {
        panic("elf header's magic is not correct\n");
    }

    ph = (struct Proghdr *)((uint8_t *)elfhdr + elfhdr->e_phoff);

    eph = ph + elfhdr->e_phnum;

    lcr3(PADDR(e->env_pgdir));

    for(;ph < eph; ph++)
    {
        if(ph->p_type != ELF_PROG_LOAD)
        {
            continue;
        }

        if(ph->p_filesz > ph->p_memsz)
        {
            panic("file size is great than memory size\n");
        }

        region_alloc(e, (void *)ph->p_va, ph->p_memsz);
        memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);

        memset((void *)ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
    }
```

+ `lcr3(PADDR(e->env_pgdir))`中, `cr3`寄存器存页目录表基址，表示当前执行进程

+ `ELF`的结构如下

    `struct ELF`中
    ```Cpp
        uint32_t e_magic;           // 标识是否为ELF
        uint8_t e_elf[12];          // 
        uint16_t e_type;            // 文件类型
        uint16_t e_machine;         // 针对体系结构
        uint32_t e_version;         // 版本信息
        uint32_t e_entry;           // 程序入口
        uint32_t e_phoff;           // 程序头表偏移量
        uint32_t e_shoff;           // 节头表偏移量
        uint32_t e_flags;           // 处理器特定标志
        uint16_t e_ehsize;          // 文件头长度
        uint16_t e_phentsize;       // 程序头长度
        uint16_t e_phnum;           // 程序头个数
        uint16_t e_shentsize;       // 节头部长度
        uint16_t e_shnum;           // 节头部个数
        uint16_t e_shstrndx;        // 节头部引索 
    ```

    `struct Proghdr` 中
    ```Cpp
    	uint32_t p_type;            // 段类型
        uint32_t p_offset;          // 段位置相对于文件开始处的偏移量
        uint32_t p_va;              // 段在内存中的虚拟地址
        uint32_t p_pa;              // 段的物理地址
        uint32_t p_filesz;          // 段在文件中的长度
        uint32_t p_memsz;           // 段在内存中的长度
        uint32_t p_flags;           // 段标志
        uint32_t p_align;           // 段在内存中的对齐标志
    ```

    `ph = (struct Proghdr *)((uint8_t *)elfhdr + elfhdr->e_phoff);`通过偏移量找到段头部, `eph = ph + elfhdr->e_phnum;`找到程序段结尾.

+ 根据要求, 只加载类型为`ELF_PROG_LOAD`的段

+ 通过`region_alloc`为程序分配和映射物理内存

+ 根据要求, `ELF`二进制文件中的`ph->p_filesz`字节，从`binary+ ph->p_offset`开始，应该复制到虚拟地址`ph->p_va`.

+ 根据要求, 剩余内存置为`0`

```Cpp
	lcr3(PADDR(kern_pgdir));

    e->env_tf.tf_eip = elfhdr->e_entry;

    region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
```

+ `lcr3(PADDR(kern_pgdir));`返回原来的`cr3`

+ 根据要求, 用`region_alloc`在`USTACKTOP-PGSIZE`映射一页的内存

### 5. `env_create()`

通过调用`env_alloc`分配一个新进程，并调用`load_icode`读入`ELF`二进制映像

```Cpp

    int ret = 0;
    struct Env *e = NULL;
    ret = env_alloc(&e, 0);

    if(ret < 0)
    {
        panic("env_create: %e\n", ret);
    }

    load_icode(e, binary);
    e->env_type = type;

```

+ `env_alloc`作用是从`env_free_list`返回一个`env`

+ 根据要求, 调用`load_icode`读入二进制代码

### 6. `env_run()`

启动给定的在用户模式运行的进程

```Cpp
	if(curenv && curenv->env_status == ENV_RUNNING)
    {
        curenv->env_status = ENV_RUNNABLE;
    }

    curenv = e;
    e->env_status = ENV_RUNNING;
    e->env_runs++;

    lcr3(PADDR(e->env_pgdir));

    env_pop_tf(&(e->env_tf));
```

+ 根据要求, 判断`curenv`是否正则运行, 运行则把状态变为`RUNNABLE`

+ 转换`cr3`为当前页目录

+ `env_top_tf` 储存新进程寄存器的值

## 练习4

> 编辑 `trapentry.S` 和 `trap.c`，以实现上面描述的功能。 `trapentry.S` 中的宏定义 `TRAPHANDLER` 和 `TRAPHANDLER_NOEC`，还有在 `inc/trap.h` 中的那些 `T_` 开头的宏定义应该能帮到你。你需要在 `trapentry.S` 中用那些宏定义为每一个 `inc/trap.h` 中的 `trap` (陷阱) 添加一个新的入口点，你也要提供 `TRAPHANDLER` 宏所指向的 `_alltraps` 的代码。你还要修改 `trap_init()` 来初始化 `IDT`，使其指向每一个定义在 `trapentry.S` 中的入口点。`SETGATE` 宏定义在这里会很有帮助。 你的 `_alltraps` 应该
> 
> + 将一些值压栈，使栈帧看起来像是一个 `struct Trapframe`
> + 将 `GD_KD` 读入 `%ds` 和 `%es`
> + `push %esp` 来传递一个指向这个 `Trapframe` 的指针，作为传给 `trap()` 的参数
> + `call trap` （思考：trap 这个函数会返回吗？）
> 
> 考虑使用 `pushal` 这条指令。它在形成 `struct Trapframe` 的层次结构时非常合适。
> 
> 用一些 `user` 目录下会造成异常的程序测试一下你的陷阱处理代码，比如 `user/divzero`。现在，你应该能在 make grade 中通过 `divzero`, `softint` 和 `badsegment` 了。

### `trapentry.S`

```cpp
    TRAPHANDLER_NOEC(th0, T_DIVIDE)
    TRAPHANDLER_NOEC(th1, T_DEBUG)
    TRAPHANDLER_NOEC(th3, T_BRKPT)
    TRAPHANDLER_NOEC(th4, T_OFLOW)
    TRAPHANDLER_NOEC(th5, T_BOUND)
    TRAPHANDLER_NOEC(th6, T_ILLOP)
    TRAPHANDLER_NOEC(th7, T_DEVICE)
    TRAPHANDLER(th8, T_DBLFLT)
    TRAPHANDLER_NOEC(th9, 9)
    TRAPHANDLER(th10, T_TSS)
    TRAPHANDLER(th11, T_SEGNP)
    TRAPHANDLER(th12, T_STACK)
    TRAPHANDLER(th13, T_GPFLT)
    TRAPHANDLER(th14, T_PGFLT)
    TRAPHANDLER_NOEC(th16, T_FPERR)
```

`TRAPHANDLER_NOEC` 不需要`error code`

将`error code`压栈, 跳转到`_alltraps`

```asm
_alltraps:
	pushl %ds               ; 压栈
	pushl %es               ; 压栈
	pushal                  ; 使用这个指令使得非常像`TrapFrame`
	
    movl $GD_KD, %eax       ; 将GD_KD读入%ds和%es
	movw %ax,%ds
	movw %ax,%es

	pushl %esp              ; 传递一个指向TrapFrame的帧
	call trap               ; 调用trap函数
```

### `trap.c`

```cpp
void
trap_init(void)
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	void th0();
	void th1();
	void th3();
	void th4();
	void th5();
	void th6();
	void th7();
	void th8();
	void th9();
	void th10();
	void th11();
	void th12();
	void th13();
	void th14();
	void th16();

	SETGATE(idt[0], 0, GD_KT, th0, 0);
	SETGATE(idt[1], 0, GD_KT, th1, 0);
	SETGATE(idt[3], 0, GD_KT, th3, 0);
	SETGATE(idt[4], 0, GD_KT, th4, 0);
	SETGATE(idt[5], 0, GD_KT, th5, 0);
	SETGATE(idt[6], 0, GD_KT, th6, 0);
	SETGATE(idt[7], 0, GD_KT, th7, 0);
	SETGATE(idt[8], 0, GD_KT, th8, 0);
	SETGATE(idt[9], 0, GD_KT, th9, 0);
	SETGATE(idt[10], 0, GD_KT, th10, 0);
	SETGATE(idt[11], 0, GD_KT, th11, 0);
	SETGATE(idt[12], 0, GD_KT, th12, 0);
	SETGATE(idt[13], 0, GD_KT, th13, 0);
	SETGATE(idt[14], 0, GD_KT, th14, 0);
	SETGATE(idt[16], 0, GD_KT, th16, 0);

	// Per-CPU setup 
	trap_init_percpu();
}

```

宏`SETGATE`的作用是设置中断描述符, 最后的参数是特权等级

# Part B

## 练习5

> 修改 `trap_dispatch()`，将缺页异常分发给 `page_fault_handler()`。你现在应该能够让 make grade 通过 `faultread`，`faultreadkernel`，`faultwrite` 和 `faultwritekernel` 这些测试了。如果这些中的某一个不能正常工作，你应该找找为什么，并且解决它。记住，你可以用 `make run-x` 或者 `make run-x-nox` 来直接使 JOS 启动某个特定的用户程序。


```Cpp
	if (tf->tf_trapno == T_PGFLT)
		page_fault_handler(tf);
```

当发生缺页错误时, 调用`page_fault_handler`

## 练习6

> 修改 `trap_dispatch()` 使断点异常唤起内核监视器。现在，你应该能够让 make grade 在 breakpoint 测试中成功了。

```Cpp
	if (tf->tf_trapno == T_BRKPT)
		monitor(tf);
```

## 练习7

> 在内核中断描述符表中为中断向量 `T_SYSCALL` 添加一个处理函数。你需要编辑 `kern/trapentry.S` 和 `kern/trap.c` 的 `trap_init()` 方法。你也需要修改 `trap_dispath(`) 来将系统调用中断分发给在 `kern/syscall.c` 中定义的 `syscall()`。确保如果系统调用号不合法，`syscall()` 返回 `-E_INVAL`。你应该读一读并且理解 `lib/syscall.c`（尤其是内联汇编例程）来确定你已经理解了系统调用接口。通过调用相应的内核函数，处理在 `inc/syscall.h` 中定义的所有系统调用。

```Cpp
# syscall.c

int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	switch (syscallno)
	{
	case SYS_cputs:
		sys_cputs((const char*)a1, (size_t)a2);
		break;
	case SYS_cgetc:
		sys_cgetc();
		break;
	case SYS_getenvid:
		return sys_getenvid();
		break;
	case SYS_env_destroy:
		return sys_env_destroy((envid_t)a1);
		break;
	default:
		return -E_INVAL;
		break;
	}
	return -E_UNSPECIFIED;
	// panic("syscall not implemented");
}
```

根据不同的系统调用编号执行不同的代码.

系统调用类型在`inc/syscall.h`

```Cpp

# trap.c

void
trap_init(void)
{
    ...
    void t_syscall();
    ...
    SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
}

static void
trap_dispatch(struct Trapframe *tf)
{
    ...
	if (tf->tf_trapno == T_SYSCALL)
	{
		tf->tf_regs.reg_eax = syscall(
			tf->tf_regs.reg_eax,
			tf->tf_regs.reg_edx,
			tf->tf_regs.reg_ecx,
			tf->tf_regs.reg_ebx,
			tf->tf_regs.reg_edi,
			tf->tf_regs.reg_esi
		);
		return ;
	}
    ...
}
```

`eax`为系统调用号, `syscall`返回系统调用号

## 练习8

> 在用户库文件中补全所需要的代码，并启动你的内核。你应该能看到 `user/hello` 打出了 `hello, world` 和 `i am environment 00001000`。接下来，`user/hello` 尝试通过调用 `sys_env_destory()` 方法退出（在 `lib/libmain.c` 和 `lib/exit.c`）。因为内核目前只支持单用户进程，它应该会报告它已经销毁了这个唯一的进程并进入内核监视器。在这时，你应该能够在` make grade `中通过 hello 这个测试了。

```Cpp
# lib/libmain.c

	thisenv = envs + ENVX(sys_getenvid());
```

+ 根据要求, `thisenv`应该指向当前运行的进程在`envs[]`的位置

## 练习9

> 修改 `kern/trap.c`，如果缺页发生在内核模式，应该恐慌。
> 
> 提示：要判断缺页是发生在用户模式还是内核模式下，只需检查 `tf_cs` 的低位。
> 
> 读一读 `kern/pmap.c` 中的 `user_mem_assert` 并实现同一文件下的 `user_mem_check`。
> 
> 调整 `kern/syscall.c` 来验证系统调用的参数。
> 
> 启动你的内核，运行 `user/buggyhello` (make run-buggyhello)。这个进程应该会被销毁，内核 不应该 恐慌，你应该能够看见类似
> ```
> [00001000] user_mem_check assertion failure for va 00000001
> [00001000] free env 00001000
> Destroyed the only environment - nothing more to do!
> ```
> 这样的消息。
> 
> 最后，修改在`kern/kdebug.c` 的 `debuginfo_eip`，对 `usd, stabs, stabstr` 都要调用 `user_mem_check`。修改之后，如果你运行 `user/breakpoint` ，你应该能在内核监视器下输入 `backtrace` 并且看到调用堆栈遍历到 `lib/libmain.c`，接下来内核会缺页并恐慌。是什么造成的内核缺页？你不需要解决这个问题，但是你应该知道为什么会发生缺页。（注：如果整个过程都没发生缺页，说明上面的实现可能有问题。如果在能够看到 `lib/libmain.c` 前就发生了缺页，可能说明之前某次实验的代码存在问题，也可能是由于 GCC 的优化，它没有遵守使我们这个功能得以正常工作的函数调用传统，如果你能合理解释它，即使不能看到预期的结果也没有关系。）

```Cpp
# kern/trap.c

	if (tf->tf_cs & 3 == 0)
	{
		panic("kernel page fault at:%x\n", fault_va);
	}
```

检查最后`cs`寄存器后两位

```Cpp
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uint32_t begin = (uint32_t) ROUNDDOWN(va, PGSIZE); 
	uint32_t end = (uint32_t) ROUNDUP(va+len, PGSIZE);
	uint32_t i;
	for (i = (uint32_t)begin; i < end; i+=PGSIZE) {
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);
		pprint(pte);
		if ((i>=ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm)) {
			user_mem_check_addr = (i<(uint32_t)va?(uint32_t)va:i);
			return -E_FAULT;
		}
	}
	return 0;
}
```

+ `begin`指向`va`所在页, `end`指向`va+len`的下一页

+ 调用`pgdir_walk`, 给定一个进程的页目录表指针, 返回线性虚拟地址对应的`PageTable`的内容, `create`位置为`0`, 无内容返回空指针

+ 检查权限

```Cpp
# kern/kdebug.c

    ...
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
			return -1;

		stabs = usd->stabs;
		stab_end = usd->stab_end;
		stabstr = usd->stabstr;
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (user_mem_check(curenv, stabs, sizeof(struct Stab), PTE_U))
			return -1;

		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
			return -1;
    ...
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if(rline >= lline)
    {
        info->eip_line = stabs[lline].n_desc;
    }
    else
    {
        return -1;
    }
```

+ 根据要求, 调用`user_mem_check`检查`usd`,`stabs`,`stabstr`

+ 根据要求, 未找到返回`-1`