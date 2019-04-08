//
//  NSTimerViewController.m
//  CHTimer
//
//  Created by chenyuliang on 2019/4/8.
//  Copyright © 2019 didi. All rights reserved.
//

#import "NSTimerViewController.h"

@interface NSTimerViewController ()

@property (nonatomic, strong) UILabel *time;

@property (nonatomic, strong) UIButton *exit;

@end

@implementation NSTimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self time];
    [self exit];
    // Do any additional setup after loading the view.
}

- (UILabel *)time
{
    if (!_time) {
        _time = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
        _time.text = @"00:00";
        _time.textColor = [UIColor blackColor];
        [self.view addSubview:_time];
    }
    return _time;
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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
