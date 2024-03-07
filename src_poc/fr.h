#ifndef FR_H
#define FR_H

#define likely(expr) __builtin_expect(!!(expr), 1)

#define __cacheline_aligned					\
  __attribute__((__aligned__(64),			\
		 __section__(".data..cacheline_aligned")))

static inline unsigned long probe_timing(char *adrs) {
    volatile unsigned long time;

    asm __volatile__(
        "    mfence             \n"
        "    lfence             \n"
        "    rdtsc              \n"
        "    lfence             \n"
        "    movl %%eax, %%esi  \n"
        "    movl (%1), %%eax   \n"
        "    lfence             \n"
        "    rdtsc              \n"
        "    subl %%esi, %%eax  \n"
        "    clflush 0(%1)      \n"
        : "=a" (time)
        : "c" (adrs)
        : "%esi", "%edx"
    );
    return time;
}

static inline unsigned long long rdtsc() {
	unsigned long long a, d;
	asm volatile ("mfence");
	asm volatile ("rdtsc" : "=a" (a), "=d" (d));
	a = (d<<32) | a;
	asm volatile ("mfence");
	return a;
}

#define maccess(p) \
  asm volatile ("movq (%0), %%rax\n" \
    : \
    : "c" (p) \
    : "rax")

#define flush(p) \
    asm volatile ("clflush 0(%0)\n" \
      : \
      : "c" (p) \
      : "rax")

#endif
