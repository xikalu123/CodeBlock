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

@property (nonatomic, strong) CHPerfectTimer *perfectTimer;

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
 
 所以总的破除思路： 只要没有强引用持有VC就行，这样在VC释放时观测，随之调用 invalidate 释放NSTimer。

 
 */

- (void)resetTimer
{
//    _timer = [CHTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addCount) userInfo:nil repeats:YES];
    
    
//    __weak typeof(self) weakself = self;
//    _timer = [NSTimer ch_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        __weak typeof(self) strongself = weakself;
//        [strongself addCount];
//    }];
    
    _perfectTimer = [CHPerfectTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addCount) userInfo:nil repeats:YES];
    [_perfectTimer start];
    
}

- (void)stopTimer
{
    [_timer invalidate];
    _timer = nil;
    [_perfectTimer stop];
}


- (void)addCount
{
    _count++;
    [[CHTimerDisplay shareDisplay] display:[NSString stringWithFormat:@"%ld",(long)_count]];
}

- (void)dealloc
{
    [self stopTimer];
}

@end


/*方法 一
 
 VC --强引用---》自定义Timer---强引用---》NSTimer
 |              |                   |
 |              |                   |
 |---弱引用----- | ----- 强引用 ----  |
 
 1. NSTimer 强引用一个 间接的 target ，然后间接target 做处理。这里只能模拟使用非BLock的调用方式。
 
 弊端：但是无法模拟NStimer的block方式，因为首先没有传入VC的self，它是在 block 里面持有的。
 
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
    
    //因为NSTimer 与 CHTimer 互相强引用，如果用block，不知道NSTimer什么时候销毁停止。
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


/*方法 二

 分类实现
 */

@implementation NSTimer (unRetainWithBlock)

+ (NSTimer *)ch_scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)repeats block:(void (^)(NSTimer * _Nonnull))block
{
    return [NSTimer scheduledTimerWithTimeInterval:ti target:self selector:@selector(blockInvoke:) userInfo:[block copy] repeats:repeats];
}

+ (void)blockInvoke:(NSTimer *)timer
{
    void (^block)(NSTimer *timer) = timer.userInfo;
    if (block) {
        block(timer);
    }
}

@end


/*方法 三
 
 既使用 间接target 又使用 NSPoxy
 
 */

@interface ONEProxy : NSObject

@property (weak, nonatomic) id realTarget;

@end


@implementation ONEProxy

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.realTarget respondsToSelector:aSelector]) {
        return self.realTarget;
    }
    return nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature* signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        signature = [self.realTarget methodSignatureForSelector:aSelector];
    }
    
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    SEL invSEL = anInvocation.selector;
    if ([self.realTarget respondsToSelector:invSEL]) {
        [anInvocation invokeWithTarget:self.realTarget];
    }
    else{
        [self doesNotRecognizeSelector:invSEL];
    }
}

@end


@interface CHPerfectTimer()

@property (nonatomic, strong) ONEProxy *proxy;
@property (nonatomic, strong, readwrite) NSTimer *timer;

@property (nonatomic, weak) id cTarget;
@property (nonatomic, assign) SEL cSelector;
@property (nonatomic, strong) id userInfo;
@property (nonatomic, assign) NSTimeInterval ti;
@property (nonatomic, assign) BOOL repeats;
@property (nonatomic, copy) dispatch_block_t tickBlock;


@end

@implementation CHPerfectTimer

+ (instancetype )scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo
{
    CHPerfectTimer *realTarget = [[CHPerfectTimer alloc] init];
    realTarget.cTarget = aTarget;
    realTarget.cSelector = aSelector;
    realTarget.userInfo = userInfo;
    realTarget.repeats = yesOrNo;
    realTarget.ti = ti;
    
    ONEProxy *proxy = [[ONEProxy alloc] init];
    proxy.realTarget = realTarget;
    realTarget.proxy = proxy;
    
    return realTarget;
    
}

+ (instancetype )scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)repeats block:(dispatch_block_t )block
{
    CHPerfectTimer *realTarget = [[CHPerfectTimer alloc] init];
    realTarget.tickBlock = block;
    realTarget.repeats = repeats;
    realTarget.ti = ti;
    
    ONEProxy *proxy = [[ONEProxy alloc] init];
    proxy.realTarget = realTarget;
    realTarget.proxy = proxy;
    
    return realTarget;
}

- (void)timerFired:(NSTimer *)theTimer
{
    if (self.cTarget && [self.cTarget respondsToSelector:self.cSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.cTarget performSelector:self.cSelector];
#pragma clang diagnostic pop
    }
    
    if (self.tickBlock) {
        self.tickBlock();
    }
}

- (void)start
{
    [self stop];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.ti target:self.proxy selector:@selector(timerFired:) userInfo:self.userInfo repeats:self.repeats];
}
    


- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;
}

- (BOOL)isValid {
    return self.timer.isValid;
}

- (void)dealloc
{
    [self stop];
}



@end

