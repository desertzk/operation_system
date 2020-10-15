/* See COPYRIGHT for copyright information. */

#ifndef JOS_KERN_PMAP_H
#define JOS_KERN_PMAP_H
#ifndef JOS_KERNEL
# error "This is a JOS kernel header; user programs should not #include it"
#endif

#include <inc/memlayout.h>
#include <inc/assert.h>

extern char bootstacktop[], bootstack[];

extern struct PageInfo *pages;
extern size_t npages;

extern pde_t *kern_pgdir;


/* This macro takes a kernel virtual address -- an address that points above
 * KERNBASE, where the machine's maximum 256MB of physical memory is mapped --
 * and returns the corresponding physical address.  It panics if you pass it a
 * non-kernel virtual address. 应该就是在计算 虚拟地址所对应的真实物理地址
 * 虚拟地址 - 0xF0000000转化为物理地址
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
}

/* This macro takes a physical address and returns the corresponding kernel
 * virtual address.  It panics if you pass an invalid physical address. 这个实现
 * 就是把 pa加上一个0xF0000000 
 * 内核虚拟地址 与 物理地址之间就差0xF0000000 */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
}


enum {
	// For page_alloc, zero the returned physical page.
	ALLOC_ZERO = 1<<0,
};

void	mem_init(void);
// 初始化一个页面结构和page_free_list。
void	page_init(void);

// 分配物理页
struct PageInfo *page_alloc(int alloc_flags);
// 释放页面，将页面加入page_free_list
void	page_free(struct PageInfo *pp);

// 将物理页pp映射到虚拟地址va，权限设置为 perm | PTE_P
int	page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm);
// 移除虚拟地址va的映射
void	page_remove(pde_t *pgdir, void *va);
// 返回虚拟地址va映射的物理页的PageInfo地址
struct PageInfo *page_lookup(pde_t *pgdir, void *va, pte_t **pte_store);

void	page_decref(struct PageInfo *pp);

void	tlb_invalidate(pde_t *pgdir, void *va);

// 由PageInfo结构得到页面物理地址这里没看懂
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pages PageInfo数组首地址 所以通过pp(pages[i])-pages可以得到页的编号i，
	//在通过i<<12就可以得到pp所对应的页的物理内存，由于实现系统的物理内存和虚拟内存的转换比较简单，
	//虚拟内存=物理内存+ 0xF0000000.所以通过pages这个结构体，在知道具体的物理页时，就可以很容易得到物理页对应的物理地址和虚拟地址
	return (pp - pages) << PGSHIFT;
}

// 由物理地址得到PageInfo结构体
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
}


// 与 page2pa 类似，只不过返回的是 PageInfo 结构 pp 所对应的物理页面的内核首地址(虚拟地址)
static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}

// 给定页目录地址pgdir，检查虚拟地址va是否可以用页表翻译，若能，返回页表项地址，
// 否则根据需要创建页表项并返回页表项的内核地址，注意不是物理地址。
pte_t *pgdir_walk(pde_t *pgdir, const void *va, int create);

#endif /* !JOS_KERN_PMAP_H */
