//
//  CHMachOToolBox.h
//  CHTraceMethodTime
//
//  Created by chenyuliang on 2019/4/17.
//  Copyright © 2019 didi. All rights reserved.
//

#ifndef CHMachOToolBox_h
#define CHMachOToolBox_h

#include <stdio.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>

typedef struct {
    struct mach_header* image_header;
    intptr_t image_vaaddr_slide;
    char* image_name;
} chMachO;

extern chMachO *getMachOs();

extern struct segment_command_64 * segment_command(struct mach_header *header);

#endif /* CHMachOToolBox_h */
