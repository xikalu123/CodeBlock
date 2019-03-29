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

static size_t (*origin_strlen)(const char *__s1);


size_t chen_strlen(const char *__s1)
{
    printf("wo cao le");
    
    return origin_strlen(__s1);
}

void replace()
{
    struct rebinding chen_rebinding = {
        "strlen",
        chen_strlen,
        (void *)&origin_strlen
    };
    rebind_symbols((struct rebinding[1]){ chen_rebinding }, 1);
    
    printf("ss == %d",strlen("chen"));
    
}

//#else
//如果不支持arm64位，说明是模拟器，执行空函数

//void replace(){}

//#endif
