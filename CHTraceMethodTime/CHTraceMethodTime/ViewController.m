//
//  ViewController.m
//  CHTraceMethodTime
//
//  Created by chenyuliang on 2019/3/29.
//  Copyright © 2019 didi. All rights reserved.
//

#import "ViewController.h"
#include "CHTraceMethodTimeCore.h"
#include "CHMachOToolBox.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    replace();
    
    chMachO *array  = getMachOs();
    
    uint32_t count = _dyld_image_count();
    
    printf("sss=====%d\n",count);

    chMachO *macho = &array[100];
    
    //打印header
    printf("magic=====%d\n",macho->image_header->magic);
    printf("cputype=====%d\n",macho->image_header->cputype);
    printf("cpusubtype=====%d\n",macho->image_header->cpusubtype);
    printf("filetype=====%d\n",macho->image_header->filetype);
    printf("ncmds=====%d\n",macho->image_header->ncmds);
    printf("sizeofcmds=====%d\n",macho->image_header->sizeofcmds);
    printf("cpusubtype=====%d\n",macho->image_header->flags);

    //打印segment
    struct segment_command_64 * segment = segment_command(macho->image_header);
    printf("segment=================================\n");
    
    printf("cmd=====%d\n",segment->cmd);
    printf("cmdsize=====%d\n",segment->cmdsize);
    printf("segname=====%s\n",segment->segname);
    printf("vmaddr=====%d\n",segment->vmaddr);
    printf("vmsize=====%d\n",segment->vmsize);
    printf("fileoff=====%d\n",segment->fileoff);
    printf("filesize=====%d\n",segment->filesize);
    printf("maxprot=====%d\n",segment->maxprot);
    printf("initprot=====%d\n",segment->initprot);
    printf("nsects=====%d\n",segment->nsects);
    printf("flags=====%d\n",segment->flags);
}


@end
