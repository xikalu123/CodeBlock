//
//  CADisplayLinkViewController.m
//  CHTimer
//
//  Created by chenyuliang on 2019/4/12.
//  Copyright © 2019 didi. All rights reserved.
//

#import "CADisplayLinkViewController.h"
#import "CHTimerDisplay.h"

@interface CADisplayLinkViewController ()

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) CFTimeInterval timeStamp;

@property (nonatomic, strong) UIButton *exit;

@property (nonatomic, assign) NSUInteger cout;

@end

@implementation CADisplayLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _cout = 0;
    self.view.backgroundColor = [UIColor whiteColor];
    [self exit];
    [self displayLink];
    [self startAnimation];
    // Do any additional setup after loading the view.
}

//跟NSTimer一样  也是强引用 self的  所以解决方法类似。
- (CADisplayLink *)displayLink
{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateUI:)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return _displayLink;
}

- (UIButton *)exit
{
    if (!_exit) {
        _exit = [[UIButton alloc] initWithFrame:CGRectMake(30, 200, 40, 40)];
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

- (void)startAnimation{
    self.displayLink.paused = NO;
}
- (void)stopAnimation{
    self.displayLink.paused = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)updateUI:(CADisplayLink *)link
{
    _cout++;
    
    if (_timeStamp == 0) {
        _timeStamp = link.timestamp;
    }
    
    CFTimeInterval timePassed = link.timestamp - _timeStamp;
    
    if (timePassed >= 1.f) { //  fps == 一秒钟屏幕刷新的次数  / 运行的时间
        
        CGFloat fps = _cout / timePassed;
        
        [[CHTimerDisplay shareDisplay] display:[NSString stringWithFormat:@"fps :%ld",(long)_cout]];
        
        _timeStamp = link.timestamp;
        _cout = 0;
    }
    
}

-(void)dealloc
{
    [self stopAnimation];
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
