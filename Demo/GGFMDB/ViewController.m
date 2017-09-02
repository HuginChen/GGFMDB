//
//  ViewController.m
//  GGFMDB
//
//  Created by Hugin on 16/9/1.
//  Copyright © 2016年 Hugin. All rights reserved.
//

#import "ViewController.h"
#import "GGDB.h"
#import "TableDataCell.h"

@interface ViewController ()<UITableViewDataSource>
@property(weak, nonatomic) IBOutlet UITableView *tableView;
@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property(strong, nonatomic) NSArray *dataSource;
@property(nonatomic, strong) NSArray<NSArray *> *pagingDataSoure;
@property(strong, nonatomic) UITableView *pagingTableView;
@end

@implementation ViewController
- (IBAction)valueChanged:(UISegmentedControl *)sender
{
    NSUInteger page = sender.selectedSegmentIndex;
    CGSize size = self.view.bounds.size;
    CGFloat width = page * size.width;
    
    [_scrollView setContentOffset:CGPointMake(width, 0) animated:YES];
}

- (void)setupUI
{
    NSArray *arr = nil;
    _scrollView.contentSize = CGSizeMake(_scrollView.bounds.size.width * 5, _scrollView.bounds.size.height);
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.bounces = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.scrollEnabled = NO;
    for (int i = 0; i < 5; i++) {
        switch (i) {
            case 0:
                arr = @[@"插入一条数据",@"插入一组数据",@"保证线程安全插入一条数据",@"异步(防止UI卡死)插入一条数据"];
                break;
            case 1:
                arr = @[@"删除最后一条数据",@"删除全部数据",@"保证线程安全删除最后一条数据",@"异步(防止UI卡死)删除最后一条数据"];
                break;
            case 2:
                arr = @[@"查找name=Hugin的数据",@"查找表中所有数据",@"保证线程安全查找name=Hugin",@"异步(防止UI卡死)查找name=Hugin"];
                break;
            case 3:
                arr = @[@"更新最后一条数据的name=Hugin",@"把表中的name全部改成Hugin",@"保证线程安全更新最后一条数据",@"异步(防止UI卡死)更新最后一条数据"];
                break;
            case 4:
                arr = @[@"用事务插入1000条数据", @"分页查询(开始 加载一个tableView)", @"分页查询(返回原来页面)"];
                break;
        }
        CGRect bounds = _scrollView.bounds;
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.backgroundColor = [UIColor whiteColor];
        view.frame = CGRectMake(i*bounds.size.width, 0, bounds.size.width, bounds.size.height);
        for (int j = 0; j < arr.count; j++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(20, (40*(j+1))+(j*30), bounds.size.width-40, 30);
            [btn setTitle:arr[j] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            btn.backgroundColor = [UIColor lightGrayColor];
            [btn.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
            btn.layer.cornerRadius = 5;
            btn.tag = i*1000+j*10; // 用于区分btn
            [btn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
            [view addSubview:btn];
        }
        [self.scrollView addSubview:view];
    }
}

- (void)clickBtn:(UIButton *)btn
{
    long page = btn.tag / 1000;
    long row = (btn.tag % 1000) / 10;
    
    // 其他操作
    if (page == 4) {
        switch (row) {
            case 0:
            {
                [[[GGDB alloc] init] transactionMethod1:^{
                    [[[GGDB alloc] init] queryMethod2:^(NSArray *arr) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _dataSource = arr;
                            [_tableView reloadData];
                        });
                    }];
                }];
            }
                break;
            case 1:
            {
                _pagingTableView = [[UITableView alloc] initWithFrame:_tableView.frame];
                [self.view addSubview:_pagingTableView];
                _pagingTableView.dataSource = self;
                _pagingTableView.rowHeight = 76;
                [_pagingTableView registerNib:[UINib nibWithNibName:@"tableData" bundle:nil] forCellReuseIdentifier:@"identifier"];
                
                [[[GGDB alloc] init] pagingQueryAllData:^(NSArray *arr) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _pagingDataSoure = arr;
                        [_pagingTableView reloadData];
                    });
                }];
                
            }
                break;
            case 2:
            {
                [_pagingTableView removeFromSuperview];
                _pagingTableView = nil;
            }
                break;
        }
        return;
    }
    
    // 增删查改
    [[[GGDB alloc] init] transferWithPage:(int)page row:(int)row block:^(NSArray * _Nullable arr) {
        if (arr) {
            _dataSource = arr;
            [_tableView reloadData];
        } else {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[[GGDB alloc] init] queryMethod2:^(NSArray *arr) {
                    _dataSource = arr;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [_tableView reloadData];
                    });
                }];
            });
        }
    }];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [_tableView registerNib:[UINib nibWithNibName:@"tableData" bundle:nil] forCellReuseIdentifier:@"identifier"];
    _tableView.rowHeight = 76;
    _tableView.dataSource = self;
    [[[GGDB alloc] init] queryMethod2:^(NSArray *arr) {
        _dataSource = arr;
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupUI];
    });
}

// 获得随机名称
static NSArray *nameList;
- (NSString *)randomName {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nameList = [NSArray arrayWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"nameList.strings" withExtension:nil]];
    });
    unsigned int i = arc4random_uniform((unsigned int)nameList.count);
    return nameList[i];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == _tableView) {
        return 1;
    } else {
        if (_pagingDataSoure) {
            return _pagingDataSoure.count;
        }
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _tableView) {
        if (_dataSource) {
            return _dataSource.count;
        }
        return 0;
    } else {
        if (_pagingDataSoure) {
            return _pagingDataSoure[section].count;
        }
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"identifier" forIndexPath:indexPath];
    if (tableView == _tableView) {
        cell.model = _dataSource[indexPath.row];
    } else {
        cell.model = _pagingDataSoure[indexPath.section][indexPath.row];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == _tableView) {
        return nil;
    } else {
        return @(section).description;
    }
}

@end

