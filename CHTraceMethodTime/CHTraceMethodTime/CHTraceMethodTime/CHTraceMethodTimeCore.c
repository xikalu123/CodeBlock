//
//  CHTraceMethodTimeCore.c
//  CHTraceMethodTime
//
//  Created by chenyuliang on 2019/3/29.
//  Copyright © 2019 didi. All rights reserved.
//

#include "CHTraceMethodTimeCore.h"

//#ifdef __aarch64__ //如果支持arm64位，说明是用真机测试，否则则执行空函数

#pragma mark - fishhook
#include <stddef.h>
#include <stdint.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>

//64位系统 宏定义
#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
//32位系统 宏定义
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT

#endif


#ifndef SEG_DATA_CONST
#define SEG_DATA_CONST  "__DATA_CONST"
#endif

/*
 * A structure representing a particular intended rebinding from a symbol
 * name to its replacement
 */

struct rebinding {
    const char *name;
    void *replacement;
    void **replaced;
};


struct rebindings_entry {
    struct rebinding *rebindings;
    size_t rebindings_nel;
    struct rebindings_entry *next;
};

static struct rebindings_entry  *_rebindings_head;

static int prepend_rebindings(struct rebindings_entry **rebindings_head,
                              struct rebinding rebindings[],
                              size_t nel){
    struct rebindings_entry *new_enty = (struct rebindings_entry *)malloc(sizeof(struct rebindings_entry));
    
    if (!new_enty) {
        return - 1;
    }
    
    new_enty->rebindings = malloc(sizeof(struct rebinding) * nel);
    if (!new_enty->rebindings) {
        free(new_enty);
        return -1;
    }
    memcpy(new_enty->rebindings,rebindings,sizeof(struct rebinding) * nel);
    new_enty->rebindings_nel = nel;
    new_enty->next = *rebindings_head;  //采用头插法建立链表，每个节点是传入的rebindings数组。
    *rebindings_head = new_enty;
    
    return 0;
}

//从lazy symbol pointers  和 non-lazy symbol pointers表中遍历所有函数，看是否满足条件，如果有的话就替换


static void perform_rebinding_with_section(struct rebindings_entry *rebindings,
                                           section_t *section,
                                           intptr_t slide,
                                           nlist_t *symtab,
                                           char *strtab,
                                           uint32_t *indirect_symtab)
{
    uint32_t *indirect_symbol_indices = indirect_symtab + section->reserved1; //找出section表在indirect symtab 第一次出现的 地址
    
    void **indirect_symbol_bindings = (void **)((uintptr_t)slide + section->addr);// 找出对应的所有已经绑定的函数指针的数组
    
    for (uint i = 0; i<section->size/ sizeof(void *); i++) { //遍历表中是所有的函数指针
        uint32_t symtab_index = indirect_symbol_indices[i]; //取出在 symtab 表中的下标,根据下标可以取出对应的函数的信息
        if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL ||
            symtab_index == (INDIRECT_SYMBOL_LOCAL   | INDIRECT_SYMBOL_ABS)) { //剔除
            continue ;
        }
        
        uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx; //在 strtab 中对应的偏移地址
        char *symbol_name = strtab + strtab_offset; //函数对应的地址
        bool symbol_name_longer_than_1 = symbol_name[0] && symbol_name[1] ; //函数的名字 必须有名字，因为第一个是_  例如NSLog -> _NSLog
        
        struct rebindings_entry *cur = rebindings; //遍历我们构造的链接，里面存储需要替换的所有函数
        
        while (cur) {
            
            for (uint j = 0; j<cur->rebindings_nel; j++) {
                if (symbol_name_longer_than_1 &&
                    strcmp(&symbol_name[1], cur->rebindings[j].name) == 0) { //找到了需要替换的函数
                    
                    if (cur->rebindings[j].replaced != NULL &&
                        indirect_symbol_bindings[i] != cur->rebindings[j].replacement) {
                        
                        *(cur->rebindings[j].replaced) = indirect_symbol_bindings[i]; //先存储之前的系统函数
                    }
                    indirect_symbol_bindings[i]  = cur->rebindings[j].replacement;
                    
                    goto symbol_loop;
                    
                }
            }
            
            
            cur = cur->next;
        }
    symbol_loop:;
        
    }
}

void rebind_symbols_for_image(struct rebindings_entry *rebindings,
                              const struct mach_header * header,
                              intptr_t slide){
    Dl_info info;
    if (dladdr(header, &info) == 0) {
        return ;
    }
    
    /*现在需要三个表，分别是indirect_symtab,symbol table,string table.
      所以先要找可以计算这三个表地址的 load command segment，分别是：
     1.linkedit_segment 为了得到基址，通过偏移量得到下面三个表
     2.LC_SYMTAB  为了获得 symbol table / string string.
     3.LC_DYSYMTAB 为了获得 indirect_symtab
     */
    
    segment_command_t *cur_seg_cmd;
    segment_command_t *linkedit_segment = NULL;
    struct symtab_command *symtab_cmd = NULL;
    struct dysymtab_command *dysymtab_cmd = NULL;
    
    uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
    
    //mach_header 里面存储有几个segment_command_t，以及对应的大小。
    for (uint i = 0; i < header->ncmds; i++,cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur; //遍历每一个 segment_command
        
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit_segment = cur_seg_cmd;
            }
        }
        else if (cur_seg_cmd->cmd == LC_SYMTAB){
            symtab_cmd = (struct symtab_command *)cur_seg_cmd;
        }
        else if (cur_seg_cmd->cmd == LC_DYSYMTAB){
            dysymtab_cmd = (struct dysymtab_command *)cur_seg_cmd;
        }
    }
    
    if (!symtab_cmd || !dysymtab_cmd || !linkedit_segment || !dysymtab_cmd->nindirectsyms) {
        return ;
    }
    
    //step 1: find linkedit_base , 因为 symbol/string table 偏移地址是相对于 linkedit_base 基址的
    uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
    
    //step 2: finde symbol/string table address
    nlist_t *symtab = (nlist_t *)(linkedit_base + symtab_cmd->symoff);
    char *strtab = (char *)(linkedit_base + symtab_cmd->stroff);
    
    //step 3:finde indirect symbol table (array of uint32_t indices into symbol table)
    uint32_t *indirect_symtab = (uint32_t *)(linkedit_base + dysymtab_cmd->indirectsymoff);
    
    
    
    //第二次遍历，遍历_DATA段所有的 lazy symbol pointers  和 non-lazy symbol pointers 的，然后通过两个表的下标找到
    //所有函数对应的 string table的位置，如何相等的话，就替换掉。
    cur = (uintptr_t)header + sizeof(mach_header_t);
    
    for (uint i = 0; i < header->ncmds; i++,cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) { //包括 _PAGEZERO _TEXT _DATA _LINKEDIT
            if ((strcmp(cur_seg_cmd->segname, SEG_DATA) != 0) //只挑选 _DATA
                && (strcmp(cur_seg_cmd->segname, SEG_DATA_CONST) != 0))
            {
                continue ;
            }
            
            for (uint j = 0; j< cur_seg_cmd->nsects; j++) {
                section_t *sect = (section_t *)(cur + sizeof(segment_command_t)) + j; // 现在不明白为什么这样表示 ????
                if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
                    perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab,indirect_symtab);
                }
                
                if (((sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS)) {
                    perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab,indirect_symtab);
                }
            }
        }
    }
    
    
}

void _rebind_symbols_for_image(const struct mach_header * header,
                               intptr_t slide){
    rebind_symbols_for_image(_rebindings_head,header,slide);
}

static int rebind_symbols(struct rebinding rebindings[],size_t rebindings_nel){
    int retval = prepend_rebindings(&_rebindings_head,rebindings,rebindings_nel);
    if (retval < 0) {
        return retval;
    }
    
    if (!_rebindings_head->next) { //初次调用，只有一个链表节点，说明业务最早调用fish_rebind_symbols
        _dyld_register_func_for_add_image(_rebind_symbols_for_image);
    }else{
        uint32_t c = _dyld_image_count();
        for (uint32_t i = 0; i< c; i++) {
            _rebind_symbols_for_image(_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i));
        }
        
    }
    
    return retval;
}

#pragma  mark ---- 替换 objc_msgsend 的实现

#include <objc/runtime.h>
#include <dispatch/dispatch.h>
#include <pthread.h>
#include <sys/time.h>

static bool _call_record_enabled = true;
static pthread_key_t _thread_key; //线程私有数据的key值
__unused static id (*orig_objc_msgSend)(id, SEL, ...);

static uint64_t _min_time_cost = 1000; //us
static int _max_call_depth = 3;

static smCallRecord *_smCallRecords; //数组地址，保存需要打印的数据结构。
//static int otp_record_num;
//static int otp_record_alloc;
static int _smRecordNum;
static int _smRecordAlloc;

//缓存的thread_call_stack  如何转化为  显示的 _smCallRecords 。

typedef struct {
    id self; //通过 object_getClass 能够得到 Class 再通过 NSStringFromClass 能够得到类名
    Class cls;
    SEL cmd;// 选择子，通过NSStringFromSelector获得方法名
    uint64_t time;// us
    uintptr_t lr; //link register
} thread_call_record;

typedef struct{
    thread_call_record *stack;
    int allocated_length;
    int index;
    bool is_main_thread;
    
} thread_call_stack;


//线程退出时释放函数
static void release_thread_call_stack(void *ptr){
    thread_call_stack *cs = (thread_call_stack *)ptr;
    if (!cs) return;
    if (cs->stack) free(cs->stack);
    free(cs);
}

//线程获取私有数据的方法，如果为空，则初始化进行设置。
static inline thread_call_stack * get_thread_call_stack()
{
    thread_call_stack *cs = (thread_call_stack *)pthread_getspecific(_thread_key);
    if (cs == NULL) {
        cs = (thread_call_stack *)malloc(sizeof(thread_call_stack)); //分配内存中可以是任意值
        cs->stack = (thread_call_record *)calloc(128, sizeof(thread_call_record)); //分配的128 个内存块设置为 0
        cs->allocated_length = 64;
        cs->index = -1;
        cs->is_main_thread = pthread_main_np(); //是否是主线程
        pthread_setspecific(_thread_key, cs);//线程设置私有值
    }
    return cs;
}

//开始记录,构造一个新的record用来记录数据
static inline void push_call_record(id _self, Class _cls, SEL _cmd, uintptr_t lr)
{
    thread_call_stack *cs  = get_thread_call_stack();//获取线程私有数据数组的地址
    if (cs) {
        int nextIndex = (++cs->index); //下一个存储的地方
        if (nextIndex >= cs->allocated_length) { //存储的内存已经，在扩充64个
            cs->allocated_length += 64;
            cs->stack = (thread_call_record *)realloc(cs->stack, cs->allocated_length * sizeof(thread_call_record));
        }
        thread_call_record *newRecord = &cs->stack[nextIndex];
        newRecord->self = _self;
        newRecord->cls = _cls;
        newRecord->cmd = _cmd;
        newRecord->lr = lr;
        if (cs->is_main_thread && _call_record_enabled) {
            struct timeval now;
            gettimeofday(&now, NULL); //获取当前时间
            newRecord->time = (now.tv_sec % 100) * 1000000 + now.tv_usec; //秒 + us
        }
    }
}

//结束记录，缓存数据  thread_call_stack  数据转化为  _smCallRecords
static inline uintptr_t pop_call_record()
{
    thread_call_stack *cs = get_thread_call_stack();
    int curIndex = cs->index;
    int nextIndex = cs->index--;
    thread_call_record *pRecord = &cs->stack[nextIndex]; //取出改方法 push时 的记录
    
    if (cs->is_main_thread && _call_record_enabled) {
        struct timeval now;
        gettimeofday(&now, NULL);
        uint64_t time = (now.tv_sec % 100) * 1000000 + now.tv_usec;
        if (time < pRecord->time) {
            time += 100 * 1000000;
        }
        uint64_t cost = time - pRecord->time; //取出时间相减，得到方法的时长。
        if (cost > _min_time_cost && cs->index < _max_call_depth) {
            if (!_smCallRecords) {
                _smRecordAlloc = 1024;
                _smCallRecords = malloc(sizeof(smCallRecord) * _smRecordAlloc);
            }
            _smRecordNum ++;
            
            if (_smRecordNum >= _smRecordAlloc) {
                _smRecordAlloc += 1024;
                _smCallRecords = realloc(_smCallRecords, sizeof(smCallRecord) * _smRecordAlloc);
            }
            
            smCallRecord *log = &_smCallRecords[_smRecordNum - 1];
            log->cls = pRecord->cls;
            log->depth = curIndex;
            log->sel = pRecord->cmd;
            log->time = cost;
        }
        
    }
    
    return pRecord->lr;
}

//作用等同于push pop，在汇编中需要执行的函数。
void before_objc_msgSend(id self, SEL _cmd, uintptr_t lr) {
    push_call_record(self, object_getClass(self), _cmd, lr);
}

uintptr_t after_objc_msgSend() {
    return pop_call_record();
}




/*
 需要明白的汇编知识:
 https://blog.cnbluebox.com/blog/2017/07/24/arm64-start/
 1.
 __asm volatile C语言内嵌汇编语言  volatile表示编译器不要优化代码
 通用寄存器：ARM64拥有31个64位通用q寄存器X0-X30(64位) r0-r30 是32位
 LR:Link register 保存着最后一次函数调用指令之后下一条指令的内存地址，函数调用栈的跟踪
 SP寄存器：stack pointer 存放栈的偏移地址 实际是X31
 PC寄存器：当前执行的指令的地址，不能改写
 VO-V31：向量寄存器，浮点型寄存器
 stp 入栈指令，将两个寄存器内容写入栈  例子 "stp x8, x9, [sp, #-16]!\n"
 mov src desc  将desc的值传给 src。 例子 "mov x2, lr\n" 将lr的值传给x2
 ldp 出栈指令，从地址读取两个寄存器内容，分别写入。 例子 "ldp x0, x1, [sp], #16\n"
 sub 相减运算 "sub sp, sp, #16\n" 将sp - 16 写入sp
 add 相加运算 "add sp, sp, #16\n" 将sp + 16 写入sp
 
 */

//保存objc_msgSend函数的入参，x0是传入的对象，x1是选择子_cmd。 syscall 的number会放到 x8里。

/*
 依次将x9-x0寄存器的内容写入栈上，栈顶指针依次移动.(栈是从高地址向低地址移动的，所以一直 - 16字节)
 */
#define save() \
__asm volatile (\
 "stp x8, x9, [sp, #-16]!\n"\
 "stp x6, x7, [sp, #-16]!\n"\
 "stp x4, x5, [sp, #-16]!\n"\
 "stp x2, x3, [sp, #-16]!\n"\
 "stp x0, x1, [sp, #-16]!\n");



static void hook_Objc_msgSend(){ //由于objc_msgSend 方法是汇编写的，所以需要在调用 objc_msgSend 前后记录时间，然后相减，即可得到每个方法的耗时。
    
}

/*
 1. pthread_key_create 创建一个key。
 2. pthread_setspecific 通过一个key 在线程设置私有数据
 3. pthread_getspecific 通过一个key 从线程读取私有数据。
 所有线程可以访问key，但是会自己保存不同的值，相当于一个同名而不同值的全局变量。
 */


void chCallTraceStart()
{
    static dispatch_once_t onceToken;
    _call_record_enabled = true;
    dispatch_once(&onceToken, ^{
        pthread_key_create(&_thread_key, &release_thread_call_stack);
        rebind_symbols((struct rebinding[1]){"objc_msgSend",
            hook_Objc_msgSend, (void *)&orig_objc_msgSend}, 1);
    });
}



//#else
//如果不支持arm64位，说明是模拟器，执行空函数

//void replace(){}

//#endif
