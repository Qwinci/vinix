#include <stdint.h>
#include <stddef.h>
#include <string.h>

extern char kprint__syscall_kprint[];
extern char memory__mmap__syscall_mmap[];
extern char fs__syscall_openat[];
extern char fs__syscall_read[];
extern char fs__syscall_write[];
extern char fs__syscall_seek[];
extern char fs__syscall_close[];
extern char x86__cpu__syscall_set_fs_base[];
extern char x86__cpu__syscall_set_gs_base[];
extern char fs__syscall_ioctl[];
extern char fs__syscall_fstat[];
extern char fs__syscall_fstatat[];
extern char file__syscall_fcntl[];
extern char file__syscall_dup3[];
extern char userland__syscall_fork[];
extern char userland__syscall_exit[];
extern char userland__syscall_waitpid[];
extern char userland__syscall_execve[];
extern char fs__syscall_chdir[];
extern char fs__syscall_readdir[];
extern char fs__syscall_faccessat[];
extern char pipe__syscall_pipe[];
extern char fs__syscall_mkdirat[];
extern char futex__syscall_futex_wait[];
extern char futex__syscall_futex_wake[];
extern char fs__syscall_getcwd[];

__attribute__((used)) void *syscall_table[] = {
    kprint__syscall_kprint, // 0
    memory__mmap__syscall_mmap, // 1
    fs__syscall_openat, // 2
    fs__syscall_read, // 3
    fs__syscall_write, // 4
    fs__syscall_seek, // 5
    fs__syscall_close, // 6
    x86__cpu__syscall_set_fs_base, // 7
    x86__cpu__syscall_set_gs_base, // 8
    fs__syscall_ioctl, // 9
    fs__syscall_fstat, // 10
    fs__syscall_fstatat, // 11
    file__syscall_fcntl, // 12
    file__syscall_dup3, // 13
    userland__syscall_fork, // 14
    userland__syscall_exit, // 15
    userland__syscall_waitpid, // 16
    userland__syscall_execve, // 17
    fs__syscall_chdir, // 18
    fs__syscall_readdir, // 19
    fs__syscall_faccessat, // 20
    pipe__syscall_pipe, // 21
    fs__syscall_mkdirat, // 22
    futex__syscall_futex_wait, // 23
    futex__syscall_futex_wake, // 24
    fs__syscall_getcwd, // 25
};

extern char interrupt_thunk_begin[], interrupt_thunk_end[], interrupt_thunk_storage[];
extern uint64_t interrupt_thunk_offset;
extern uint32_t interrupt_thunk_number;
extern uint64_t interrupt_thunk_size;
extern void *interrupt_table[];
extern void *interrupt_thunks[];

void prepare_interrupt_thunks(void) {
    for (size_t i = 0; i < 256; i++) {
        interrupt_thunk_offset = (uintptr_t)&interrupt_table[i];
        interrupt_thunk_number = i;
        void *ptr = interrupt_thunk_storage + i * interrupt_thunk_size;
        memcpy(ptr, interrupt_thunk_begin, interrupt_thunk_size);
        uint64_t shift = 0;
        switch (i) {
            case 8: case 10: case 11: case 12: case 13: case 14:
            case 17: case 30:
                shift = 2;
                break;
        }
        interrupt_thunks[i] = ptr + shift;
    }
}
