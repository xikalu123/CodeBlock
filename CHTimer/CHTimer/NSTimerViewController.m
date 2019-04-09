//
//  NSTimerViewController.m
//  CHTimer
//
//  Created by chenyuliang on 2019/4/8.
//  Copyright © 2019 didi. All rights reserved.
//

#import "NSTimerViewController.h"
#import "CHTimerDisplay.h"

@interface NSTimerViewController ()

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UIButton *exit;

@property (nonatomic, assign) NSInteger count;

@end

@implementation NSTimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _count = 1;
    self.view.backgroundColor = [UIColor whiteColor];
    [self exit];
    [self resetTimer];
    // Do any additional setup after loading the view.
}

- (UIButton *)exit
{
    if (!_exit) {
        _exit = [UIButton buttonWithType:UIButtonTypeCustom];
        _exit.frame = CGRectMake(100, 250, 100, 100);
        _exit.backgroundColor = [UIColor redColor];
        [self.view addSubview:_exit];
        [_exit addTarget:self action:@selector(quit) forControlEvents:UIControlEventTouchUpInside];
    }
    return _exit;
}

- (void)quit
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
 1. 需要创建NSTimer
 2. 加载到线上对应的runloop 的 mode上
 
 ⚠️ 构造NSTimer时，传入的 target 都会被 NSTimer强引用，NStimer加入到 runloop执行时，都会被runloop强引用。所以在VC退出时，runloop->nstimer->VC  所以VC不能释放。
 ⚠️ runloop 如果想移除和释放NSTimer，则唯一的方法是 invalidate。所以要找合适的h时机调用 stopTimer, 最好是VC释放时调用。

 
 */

- (void)resetTimer
{
    _timer = [CHTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addCount) userInfo:nil repeats:YES];
    
}

- (void)stopTimer
{
    [_timer invalidate];
    _timer = nil;
}


- (void)addCount
{
    _count++;
    [[CHTimerDisplay shareDisplay] display:[NSString stringWithFormat:@"%ld",(long)_count]];
}

- (void)dealloc
{
    
}

@end


/*1.破除循环引用的方法
 
 VC --强引用---》自定义Timer---强引用---》NSTimer
 |              |                   |
 |              |                   |
 |---弱引用----- | ----- 强引用 ----  |
 
 */

@interface CHTimer()

@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) NSTimer *nsTimer;
@property (nonatomic, weak) id cTarget;
@property (nonatomic, strong) id userInfo;
@property (nonatomic, assign) BOOL repeat;
@property (nonatomic, copy) dispatch_block_t tickBlock;


@end


@implementation CHTimer

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo
{
    CHTimer *timer = [[CHTimer alloc] init];
    timer.cTarget = aTarget;
    timer.selector = aSelector;
    timer.userInfo = userInfo;
    timer.repeat = yesOrNo;
    
    timer.nsTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:timer selector:@selector(timerFired) userInfo:userInfo repeats:yesOrNo];
    return timer.nsTimer;
    
}

//如果仿照 NSTimer 使用Block时，可以发现没有target传进来的话，无法找到调用方式。
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo tickBlock:(void (^)(void))block
{
    CHTimer *timer = [[CHTimer alloc] init];
    timer.repeat = yesOrNo;
    timer.tickBlock = block;
    
    timer.nsTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:timer selector:@selector(timerFired) userInfo:nil repeats:yesOrNo];
    return timer.nsTimer;
}

- (void)timerFired
{
    if (self.cTarget && [self.cTarget respondsToSelector:self.selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.cTarget performSelector:self.selector];
#pragma clang diagnostic pop
    }
    else
    {
        [self stopTimer];
    }
}

- (void)stopTimer
{
    [self.nsTimer invalidate];
    self.nsTimer = nil;
}

@end
