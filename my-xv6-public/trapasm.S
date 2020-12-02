#include "mmu.h"

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
  pushl %es
  pushl %fs
  pushl %gs
  pushal
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
  movw %ax, %ds
  movw %ax, %es

  # Call trap(tf), where tf=%esp
  pushl %esp
  call trap
  addl $4, %esp
/*
trapret restores user registers from values stored at the top of the kernel stack and jumps into the process
This setup is the same for ordinary fork and for creating the first process, though in
the latter case the process will start executing at user-space location zero rather than at
a return from fork
CS: Code
DS: Data
SS: Stack
ES: Extra data
FS: Extra data #2
GS: Extra data #3
*/
  # Return falls through to trapret...
.globl trapret
trapret:
  popal
  popl %gs
  popl %fs
  popl %es
  popl %ds
  addl $0x8, %esp  # trapno and errcode
  iret
