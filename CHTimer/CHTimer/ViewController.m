//
//  ViewController.m
//  CHTimer
//
//  Created by chenyuliang on 2019/4/7.
//  Copyright © 2019 didi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collecView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self collecView];
//    [self.collecView reloadData];
    // Do any additional setup after loading the view, typically from a nib.
}


- (UICollectionView *)collecView
{
    if (!_collecView) {
        UICollectionViewFlowLayout *fl = [[UICollectionViewFlowLayout alloc] init];
        fl.minimumInteritemSpacing = 5;
        fl.minimumLineSpacing = 5;
        _collecView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:fl];
        _collecView.delegate = self;
        _collecView.dataSource = self;
        _collecView.backgroundColor = [UIColor whiteColor];
        [_collecView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"collec_timer"];
        [self.view addSubview:_collecView];
    
    }
    return _collecView;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *timerCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collec_timer" forIndexPath:indexPath];
    timerCell.backgroundColor = [UIColor grayColor];
    return timerCell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return CGSizeMake(100, 100);
}


@end
