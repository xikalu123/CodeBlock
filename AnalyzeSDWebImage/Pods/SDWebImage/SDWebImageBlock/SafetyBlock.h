//
//  SafetyBlock.h
//  SDWebImage
//
//  Created by chenyuliang on 2019/5/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SafetyBlock : NSObject

void ch_dispatch_main_async_safe(dispatch_block_t block);

void ch_dispatch_main_sync_safe(dispatch_block_t block);


@end

NS_ASSUME_NONNULL_END
