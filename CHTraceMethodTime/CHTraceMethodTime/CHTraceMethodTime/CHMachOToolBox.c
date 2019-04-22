//
//  CHMachOToolBox.c
//  CHTraceMethodTime
//
//  Created by chenyuliang on 2019/4/17.
//  Copyright © 2019 didi. All rights reserved.
//

#include "CHMachOToolBox.h"
#include <stdlib.h>

static chMachO *_chMachOArray;


extern chMachO *getMachOs()
{
   
    _chMachOArray = malloc(sizeof(chMachO) * _dyld_image_count());
    
    uint32_t imageCount = _dyld_image_count();
    
    for (uint32_t i = 0; i<imageCount; i++) {
        chMachO *macho = &_chMachOArray[i];
        macho->image_header = _dyld_get_image_header(i);
        macho->image_vaaddr_slide = _dyld_get_image_vmaddr_slide(i);
        macho->image_name = _dyld_get_image_name(i);
    }
    return _chMachOArray;
}

extern struct segment_command_64 * segment_command(struct mach_header *header)
{
    return (struct segment_command_64 *)(header + sizeof(struct mach_header));
}

