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



//方法一 NStimer间接持有 target 破除循环引用
@interface CHTimer : NSObject

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo;

@end

//方法二 NSTimer 可以使用分类 来模拟block的调用方式

@interface NSTimer (unRetainWithBlock)

+ (NSTimer *)ch_scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block;

@end



//方法三 既使用中间Target 又使用NSPoxy  NStimer持有 NSPoxy 持有间接Target 破除循环引用
@interface CHPerfectTimer : NSObject

@property (nonatomic, strong, readonly) NSTimer *timer;
- (void)start;
- (void)stop;
- (BOOL)isValid;

+ (instancetype )scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo;

+ (instancetype )scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)repeats block:(dispatch_block_t )block;

@end


NS_ASSUME_NONNULL_END
