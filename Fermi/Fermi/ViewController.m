//
//  ViewController.m
//  Fermi
//
//  Created by chenyuliang on 2019/11/20.
//  Copyright © 2019 didi. All rights reserved.
//

#import "ViewController.h"
#import "Interceptor.h"
#import "handleInterceptorOne.h"
#import "handleInterceptorTwo.h"
#import "handleInterceptorThree.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self testInterceptors];
    // Do any additional setup after loading the view.
}


- (void)testInterceptors{
    NSMutableArray<InterceptorProtocol> *interceptors = [NSMutableArray new];
    [interceptors addObject:[handleInterceptorOne new]];
    [interceptors addObject:[handleInterceptorTwo new]];
    [interceptors addObject:[handleInterceptorThree new]];
    
    NSDictionary *input = @{@"aaa":@"1111",@"bbb":@"2222",@"ccc":@"3333"};
    
    id<RealInterceptorChainProtocol> chain = [[RealInterceptorChain alloc] initWithInterceptors:interceptors.copy originDic:input index:0];
    
    NSError *error;
    NSDictionary *output =  [chain proceed:input error:&error];
    
    NSLog(@"asdasd ===== %@",output);
    
}


@end
