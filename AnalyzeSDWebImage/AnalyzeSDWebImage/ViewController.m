//
//  ViewController.m
//  AnalyzeSDWebImage
//
//  Created by chenyuliang on 2019/4/30.
//  Copyright © 2019 didi. All rights reserved.
//

#import "ViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ViewController ()

@property (nonatomic, strong) UIImageView *sdIamgeView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.sdIamgeView];
    [self.sdIamgeView sd_setImageWithURL:[NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1556605087431&di=48560b6fda9f617b263e2e3f93481da1&imgtype=0&src=http%3A%2F%2Fa.hiphotos.baidu.com%2Fzhidao%2Fpic%2Fitem%2F6d81800a19d8bc3e21992111898ba61ea9d34553.jpg"]];
    // Do any additional setup after loading the view, typically from a nib.
}


- (UIImageView *)sdIamgeView
{
    if (!_sdIamgeView) {
        _sdIamgeView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 60, 60)];
        _sdIamgeView.backgroundColor = [UIColor redColor];
    }
    return _sdIamgeView;
}

@end
