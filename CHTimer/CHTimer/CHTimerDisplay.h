//
//  CHTimerDisplay.h
//  CHTimer
//
//  Created by chenyuliang on 2019/4/9.
//  Copyright © 2019 didi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHTimerDisplay : NSObject

+ (instancetype)shareDisplay;

- (void)display:(NSString *)str;

- (void)dismiss;


@end

NS_ASSUME_NONNULL_END
