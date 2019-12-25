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

//----线程安全字典
#import "AsyncTestTableViewController.h"
#import "SyncMutableDictionary.h"


@interface ViewController ()
@property (strong, nonatomic) UIButton *btn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self testInterceptors];
//    [self testSyncDic];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.btn];
}


- (UIButton *)btn{
    if (!_btn) {
        _btn = [UIButton buttonWithType:UIButtonTypeCustom];
        _btn.frame = CGRectMake(20, 100, 60, 50);
        _btn.layer.borderWidth = 1;
        [_btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_btn setTitle:@"Testin" forState:UIControlStateNormal];
        [_btn addTarget:self action:@selector(testLayer) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btn;
}

- (void)testLayer{
    
    AsyncTestTableViewController *test = [AsyncTestTableViewController new];
    [self presentViewController:test animated:YES completion:nil];
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

- (void)testSyncDic{
    __block SyncMutableDictionary *safeDic = [SyncMutableDictionary new];
    for (int i = 0; i<1000; i++) {
        [safeDic setObject:[NSString stringWithFormat:@"第%d个数据：数据是%d",i,i] forKey:[NSString stringWithFormat:@"key%d",i]];
    }
    
    for (int i = 0; i<1000; i++) {
        if(i<200){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"%@====%@",[NSString stringWithFormat:@"key%d",i],[safeDic objectForKey:[NSString stringWithFormat:@"key%d",i]]);
            });
        }
        if (i>=200 && i<700) {
            NSLog(@"ssss=====%d",i);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [safeDic setObject:[NSString stringWithFormat:@"修改了数%d",i] forKey:[NSString stringWithFormat:@"key%d",i]];
            });
        }
        if(i>=700){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"%@====%@",[NSString stringWithFormat:@"key%d",i],[safeDic objectForKey:[NSString stringWithFormat:@"key%d",i]]);
            });
        }
    }
    
    dispatch_barrier_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"chen-----------------------------chen");
    });
    
    for (int i = 0; i<1000; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"%@====%@",[NSString stringWithFormat:@"key%d",i],[safeDic objectForKey:[NSString stringWithFormat:@"key%d",i]]);
        });
    }
    
}


@end
