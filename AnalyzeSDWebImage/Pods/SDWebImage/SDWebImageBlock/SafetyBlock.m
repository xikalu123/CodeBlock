//
//  SafetyBlock.m
//  SDWebImage
//
//  Created by chenyuliang on 2019/5/6.
//

#import "SafetyBlock.h"

@implementation SafetyBlock

inline void ch_dispatch_main_async_safe(dispatch_block_t block)
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

inline void ch_dispatch_main_sync_safe(dispatch_block_t block)
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end
