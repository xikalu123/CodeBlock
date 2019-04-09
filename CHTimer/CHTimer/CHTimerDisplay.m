//
//  CHTimerDisplay.m
//  CHTimer
//
//  Created by chenyuliang on 2019/4/9.
//  Copyright © 2019 didi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHTimerDisplay.h"

@interface CHTimerDisplay()

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) UILabel *time;

@end

@implementation CHTimerDisplay

+ (instancetype)shareDisplay
{
    static CHTimerDisplay * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self.window addSubview:self.time];
    }
    return self;
}

- (UILabel *)time
{
    if (!_time) {
        _time = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
        _time.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        _time.backgroundColor = [UIColor grayColor];
        _time.textAlignment = NSTextAlignmentCenter;
        _time.text = @"0";
    }
    return _time;
}

- (UIWindow *)window
{
    if (!_window) {
        _window = [[UIWindow alloc] initWithFrame:CGRectMake(40, 400, 100, 100)];
        _window.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
        _window.windowLevel =  UIWindowLevelAlert + 1;
        [_window makeKeyAndVisible];
    }
    return _window;
}


- (void)display:(NSString *)str
{
    self.time.text = str;
}

- (void)dismiss
{
    
}

@end
