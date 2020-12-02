# Context switch
#
#   void swtch(struct context **old, struct context *new);
# 
# Save the current registers on the stack, creating
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.
/*
The context switch code  sets the stack pointer to point just beyond the
end of p->context. allocproc places p->context on the stack, and puts a pointer to
trapret just above it; that is where forkret will return. trapret restores user registers
 from values stored at the top of the kernel stack and jumps into the process
*/
.globl swtch
swtch:
  movl 4(%esp), %eax # this instruction loads 32-bit value from address %esp + 4 and stores it in register %eax   eax 保存了 &(c->scheduler)
  movl 8(%esp), %edx # %edx 保存了

  # Save old callee-saved registers
  pushl %ebp
  pushl %ebx
  pushl %esi
  pushl %edi

  # Switch stacks
  movl %esp, (%eax)
  movl %edx, %esp

  # Load new callee-saved registers
  popl %edi
  popl %esi
  popl %ebx
  popl %ebp
  ret
