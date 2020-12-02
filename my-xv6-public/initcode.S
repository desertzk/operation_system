# Initial process execs /init.
# This code runs in user space.

#include "syscall.h"
#include "traps.h"
/*
The first process is going to execute a small program (initcode.S; (8400)). The
process needs physical memory in which to store this program, the program needs to 
be copied to that memory, and the process needs a page table that maps user-space
addresses to that memory.
Initcode.S (8409) begins by pushing three values on the stack—$argv, $init,
and $0—and then sets %eax to SYS_exec and executes int T_SYSCALL: it is asking the
kernel to run the exec system call. If all goes well, exec never returns: it starts running the program named by $init, which is a pointer to the NUL-terminated string
/init .   The other argument is the argv array of command-line arguments;the zero at the end of the array marks its end. If the exec fails and does return, initcode 
loops calling the exit system call, which definitely should not return (8416-8420).
*/

# exec(init, argv)
.globl start
start:
  pushl $argv
  pushl $init
  pushl $0  // where caller pc would be
  movl $SYS_exec, %eax
  int $T_SYSCALL

# for(;;) exit();
exit:
  movl $SYS_exit, %eax
  int $T_SYSCALL
  jmp exit

# char init[] = "/init\0";
init:
  .string "/init\0"

# char *argv[] = { init, 0 };
.p2align 2
argv:
  .long init
  .long 0

