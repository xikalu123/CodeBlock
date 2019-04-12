//
//  ViewController.m
//  CHTimer
//
//  Created by chenyuliang on 2019/4/7.
//  Copyright © 2019 didi. All rights reserved.
//

#import "ViewController.h"

#import "NSTimerViewController.h"
#import "CADisplayLinkViewController.h"

@interface ViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;


@end

static NSArray *tableData;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    tableData = @[@"NSTimer",@"CADisplayLink",@"GCDTimer"];
    [self.tableView reloadData];
//    [self.collecView reloadData];
    // Do any additional setup after loading the view, typically from a nib.
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.rowHeight = 80;
        [self.view addSubview:_tableView];
    }
    return _tableView;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chen"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"chen"];
        cell.textLabel.text = [tableData objectAtIndex:indexPath.row];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [self testNSTimer];
            break;
        case 1:
            [self testCADisplayLink];
            break;
        case 2:
            [self testGCDTimer];
            break;
            
            
        default:
            break;
    }
}

#pragma mark -- Timer


- (void)testNSTimer
{
    NSTimerViewController *timerVC = [[NSTimerViewController alloc] init];
    [self presentViewController:timerVC animated:YES completion:nil];
}

- (void)testCADisplayLink
{
    CADisplayLinkViewController *cadisVC = [[CADisplayLinkViewController alloc] init];
    [self presentViewController:cadisVC animated:YES completion:nil];
}

- (void)testGCDTimer
{
    
}

@end
