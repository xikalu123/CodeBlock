//
//  CHGCDTimer.m
//  CHTimer
//
//  Created by chenyuliang on 2019/4/14.
//  Copyright © 2019 didi. All rights reserved.
//

#import "CHGCDTimer.h"
#import "CHTimerDisplay.h"

#define screenWidth  ([[UIScreen mainScreen] bounds].size.width)
#define screenHeight ([[UIScreen mainScreen] bounds].size.height)

@interface CHGCDTimer ()

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) UIButton *exit;
@property (nonatomic, assign) NSUInteger cout;
@end

@implementation CHGCDTimer

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _cout = 0;
    [self exit];
    __weak typeof(self) wself = self;
    [self scheduledDispatchTimerWithTimeInterval:1.0f queue:dispatch_get_main_queue() repeats:YES action:^{
         __strong typeof(self) sself = wself;
        [sself update];
    }];
    // Do any additional setup after loading the view.
}

- (UIButton *)exit
{
    if (!_exit) {
        _exit = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth/2, 400, 40, 40)];
        _exit.backgroundColor = [UIColor redColor];
        [_exit addTarget:self action:@selector(quit) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_exit];
    }
    return _exit;
}

- (void)quit
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark GCD Timer
- (void)scheduledDispatchTimerWithTimeInterval:(double)interval
                                 queue:(dispatch_queue_t)queue
                               repeats:(BOOL)repeats
                                action:(dispatch_block_t)action
{
    dispatch_queue_t innerqueue = queue;
    if (innerqueue == nil) {
        innerqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    _timer =  dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, innerqueue);
    
    dispatch_resume(_timer);
    
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    
    __weak typeof(self) wself = self;
    dispatch_source_set_event_handler(_timer, ^{
        __strong typeof(self) sself = wself;
        action();
        if (!repeats) {
            [sself removeTimer];
        }
        
    });
    
}

- (void)update
{
    _cout ++;
    [[CHTimerDisplay shareDisplay] display:[NSString stringWithFormat:@"%ld",(long)_cout]];
}

- (void)removeTimer
{
    dispatch_source_cancel(_timer);
}

-(void)dealloc
{
    [self removeTimer];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
