//
//  ViewController.m
//  AnalyzePromiseKit
//
//  Created by chenyuliang on 2019/5/7.
//  Copyright © 2019 didi. All rights reserved.
//

#import "ViewController.h"
#import "PromiseKit.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIAlertView *alet = [[UIAlertView alloc] initWithTitle:@"i am title" message:@"hahahah" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"ok", nil];
    [alet show];
    [alet promise].then(^(NSNumber *dismissedButtonIndex){
        NSLog(@"ss====%@",dismissedButtonIndex);
    });
}


@end
