// Per-CPU state
struct cpu {
  uchar apicid;                // Local APIC ID
  struct context *scheduler;   // swtch() here to enter scheduler
  struct taskstate ts;         // Used by x86 to find stack for interrupt
  struct segdesc gdt[NSEGS];   // x86 global descriptor table
  volatile uint started;       // Has the CPU started?
  int ncli;                    // Depth of pushcli nesting.
  int intena;                  // Were interrupts enabled before pushcli?
  struct proc *proc;           // The process running on this cpu or null
};

extern struct cpu cpus[NCPU];
extern int ncpu;

//PAGEBREAK: 17
// Saved registers for kernel context switches.
// Don't need to save all the segment registers (%cs, etc),
// because they are constant across kernel contexts.
// Don't need to save %eax, %ecx, %edx, because the
// x86 convention is that the caller has saved them.
// Contexts are stored at the bottom of the stack they
// describe; the stack pointer is the address of the context.
// The layout of the context matches the layout of the stack in swtch.S
// at the "Switch stacks" comment. Switch doesn't save eip explicitly,
// but it is on the stack and allocproc() manipulates it.
struct context {
  uint edi;
  uint esi;
  uint ebx;
  uint ebp;
  uint eip;
};

enum procstate { UNUSED, EMBRYO, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };
/*
Each process has two stacks: a user
stack and a kernel stack (p->kstack). When the process is executing user instructions,
only its user stack is in use, and its kernel stack is empty. When the process enters the
kernel (for a system call or interrupt), the kernel code executes on the process’s kernel
stack; while a process is in the kernel, its user stack still contains saved data, but isn’t
actively used. A process’s thread alternates between actively using its user stack and its
kernel stack. The kernel stack is separate (and protected from user code) so that the
kernel can execute even if a process has wrecked its user stack.
When a process makes a system call, the processor switch
*/
// Per-process state
struct proc {
  uint sz;                     // Size of process memory (bytes)
/*pgdir holds the process’s page table, in the format that the x86 hardware expects. xv6 causes the paging hardware to use a process’s p->pgdir when executing
that process. A process’s page table also serves as the record of the addresses of the
physical pages allocated to store the process’s memory.*/
  pde_t* pgdir;                // Page table 
  char *kstack;                // Bottom of kernel stack for this process
  enum procstate state;        // Process state indicates whether the process is allocated, ready to run, running, waiting for I/O, or exiting.
  int pid;                     // Process ID
  struct proc *parent;         // Parent process
  struct trapframe *tf;        // Trap frame for current syscall
  struct context *context;     // swtch() here to run process
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)
};

// Process memory is laid out contiguously, low addresses first:
//   text
//   original data and bss
//   fixed-size stack
//   expandable heap
