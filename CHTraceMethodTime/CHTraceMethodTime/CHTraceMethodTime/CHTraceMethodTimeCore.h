//
//  CHTraceMethodTimeCore.h
//  CHTraceMethodTime
//
//  Created by chenyuliang on 2019/3/29.
//  Copyright © 2019 didi. All rights reserved.
//

#ifndef CHTraceMethodTimeCore_h
#define CHTraceMethodTimeCore_h

#include <stdio.h>
#include <objc/objc.h>

typedef struct{
    __unsafe_unretained Class cls;
    SEL sel;
    uint64_t time ; // us (1/1000 ms)
    int depth;
} smCallRecord;  //打印出来方法的数据结构，会传出这样一个数据结构的数组。

extern void replace(void);

#endif /* CHTraceMethodTimeCore_h */
