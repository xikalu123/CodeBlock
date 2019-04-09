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
//    [self resetTimer];
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
 ⚠️ runloop 如果想移除和释放NSTimer，则唯一的方法是 invalidate。
 
 */

- (void)resetTimer
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addCount) userInfo:nil repeats:YES];
    
}







- (void)addCount
{
    _count++;
    [[CHTimerDisplay shareDisplay] display:[NSString stringWithFormat:@"%ld",(long)_count]];
}

- (void)dealloc
{
    
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
