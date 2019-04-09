//
//  NSTimerViewController.h
//  CHTimer
//
//  Created by chenyuliang on 2019/4/8.
//  Copyright © 2019 didi. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimerViewController : UIViewController

@end

//破除循环引用
@interface CHTimer : NSObject

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo;

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo tickBlock:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END
