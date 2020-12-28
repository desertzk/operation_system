/* See COPYRIGHT for copyright information. */

#ifndef JOS_INC_ENV_H
#define JOS_INC_ENV_H

#include <inc/types.h>
#include <inc/trap.h>
#include <inc/memlayout.h>

typedef int32_t envid_t;

// An environment ID 'envid_t' has three parts:
//
// +1+---------------21-----------------+--------10--------+
// |0|          Uniqueifier             |   Environment    |
// | |                                  |      Index       |
// +------------------------------------+------------------+
//                                       \--- ENVX(eid) --/
//
// The environment index ENVX(eid) equals the environment's index in the
// 'envs[]' array.  The uniqueifier distinguishes environments that were
// created at different times, but share the same environment index.
//
// All real environments are greater than 0 (so the sign bit is zero).
// envid_ts less than 0 signify errors.  The envid_t == 0 is special, and
// stands for the current environment.

#define LOG2NENV		10
#define NENV			(1 << LOG2NENV)
#define ENVX(envid)		((envid) & (NENV - 1))

// Values of env_status in struct Env
enum {
	ENV_FREE = 0,
	ENV_DYING,
	ENV_RUNNABLE,
	ENV_RUNNING,
	ENV_NOT_RUNNABLE
};

// Special environment types
enum EnvType {
	ENV_TYPE_USER = 0,
};

struct Env {
	/*
	This structure, defined in inc/trap.h, holds the saved register values for the environment while that 
	environment is not running: i.e., when the kernel or a different environment is running. 
	The kernel saves these when switching from user to kernel mode, so that the environment can later be resumed where it left off.
	*/
	struct Trapframe env_tf;	// Saved registers
	//This is a link to the next Env on the env_free_list. env_free_list points to the first free environment on the list.
	struct Env *env_link;		// Next free Env
	/*The kernel stores here a value that uniquely identifiers the environment currently using this Env structure 
	(i.e., using this particular slot in the envs array). After a user environment terminates, the kernel may re-allocate 
	the same Envstructure to a different environment - but the new environment will have a different env_id from the old 
	one even though the new environment is re-using the same slot in the envs array.*/
	envid_t env_id;			// Unique environment identifier
	/*
	The kernel stores here the env_id of the environment that created this environment. In this way the environments can 
	form a “family tree,” which will be useful for making security decisions about which environments are allowed to do what to whom.
	*/
	envid_t env_parent_id;		// env_id of this env's parent
	/*
	This is used to distinguish special environments. For most environments, it will be ENV_TYPE_USER. 
	We'll introduce a few more types for special system service environments in later labs.
	*/
	enum EnvType env_type;		// Indicates special system environments
	/*
	This variable holds one of the following values:
	ENV_FREE:
	Indicates that the Env structure is inactive, and therefore on the env_free_list.
	ENV_RUNNABLE:
	Indicates that the Env structure represents an environment that is waiting to run on the processor.
	ENV_RUNNING:
	Indicates that the Env structure represents the currently running environment.
	ENV_NOT_RUNNABLE:
	Indicates that the Env structure represents a currently active environment, but it is not currently ready to run: for example, because it is waiting for an interprocess communication (IPC) from another environment.
	ENV_DYING:
	Indicates that the Env structure represents a zombie environment. A zombie environment will be freed the next time it traps to the kernel. We will not use this flag until Lab 4.
	*/
	unsigned env_status;		// Status of the environment
	uint32_t env_runs;		// Number of times environment has run

	// Address space
	/*This variable holds the kernel virtual address of this environment's page directory.
Like a Unix process, a JOS environment couples the concepts of "thread" and "address space". The thread is defined primarily by the saved registers (the env_tf field), and the address space is defined by the page directory and page tables pointed to by env_pgdir. 
To run an environment, the kernel must set up the CPU with both the saved registers and the appropriate address space.
Our struct Env is analogous to struct proc in xv6. Both structures hold the environment's (i.e., process's) user-mode register state in a Trapframe structure. In JOS, individual environments do not have their own kernel stacks as processes do in xv6.
 There can be only one JOS environment active in the kernel at a time, so JOS needs only a single kernel stack.*/
	pde_t *env_pgdir;		// Kernel virtual address of page dir
};

#endif // !JOS_INC_ENV_H
