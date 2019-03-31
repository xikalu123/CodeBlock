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


__unused static id (*orig_objc_msgSend)(id, SEL, ...);

/*
 需要明白的汇编知识:
 1.
 __asm volatile C语言内嵌汇编语言  volatile表示编译器不要优化代码
 ARM64拥有31个64位通用q寄存器X0-X30.
 stp
 mov
 ldp
 aub
 add
 
 */
static void hook_Objc_msgSend(){ //由于objc_msgSend 方法是汇编写的，所以需要在调用 objc_msgSend 前后记录时间，然后相减，即可得到每个方法的耗时。
    
}


void chCallTraceStart()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rebind_symbols((struct rebinding[1]){"objc_msgSend",
            hook_Objc_msgSend, (void *)&orig_objc_msgSend}, 1);
    });
}


//#else
//如果不支持arm64位，说明是模拟器，执行空函数

//void replace(){}

//#endif
