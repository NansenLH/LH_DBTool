//
//  LH_SecondViewController.m
//  LH_DBTool_Example
//
//  Created by Nansen on 2021/6/29.
//  Copyright © 2021 NansenLH. All rights reserved.
//

#import "LH_SecondViewController.h"

#import "LH_TestBaseModel.h"

@interface LH_SecondViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<LH_TestBaseModel *> *dataArray;
@property (nonatomic, strong) NSMutableArray<LH_TestSecondModel *> *data2Array;

@property (nonatomic, assign) BOOL isBase;

@end

@implementation LH_SecondViewController
- (NSMutableArray *)dataArray
{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
        
        [_dataArray addObjectsFromArray:[[LH_DBTool defaultTool] searchAllObjectsFromClass:[LH_TestBaseModel class]]];
    }
    return _dataArray;
}

- (NSMutableArray *)data2Array
{
    if (!_data2Array) {
        _data2Array = [NSMutableArray array];
        
        [_data2Array addObjectsFromArray:[[LH_DBTool defaultTool] searchAllObjectsFromClass:[LH_TestSecondModel class]]];
    }
    return _data2Array;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    [[LH_DBTool defaultTool] startInDBPath:docDir];
    
    
    NSMutableArray *baseArr = [NSMutableArray array];
    NSMutableArray *secondArr = [NSMutableArray array];
    for (int i = 0; i < 20; i++) {
        LH_TestBaseModel *baseM = [[LH_TestBaseModel alloc] init];
        baseM.identify = i;
        baseM.name = @"base";
        [baseArr addObject:baseM];
        
        LH_TestSecondModel *secondM = [[LH_TestSecondModel alloc] init];
        secondM.identify = i;
        secondM.name = @"second";
        secondM.age = i+10;
        [secondArr addObject:secondM];
    }
    [[LH_DBTool defaultTool] addObjectArray:baseArr];
    [[LH_DBTool defaultTool] addObjectArray:secondArr];
    
    self.isBase = YES;
    [self.view addSubview:self.tableView];
}

- (IBAction)baseSelect:(id)sender {
    self.isBase = YES;
    self.dataArray = nil;
    [self.tableView reloadData];
}
- (IBAction)secondSelect:(id)sender {
    self.isBase = NO;
    self.data2Array = nil;
    [self.tableView reloadData];
}
- (IBAction)changeAction:(id)sender {
    
    if (self.isBase) {
        LH_TestBaseModel *base = [[LH_DBTool defaultTool] searchObjectsFromClass:[LH_TestBaseModel class] conditionKey:LH_TestBaseModel_Primarykey_Identify conditionValue:@"1"].firstObject;
        if (base) {
            base.name = @"base changed";
            [[LH_DBTool defaultTool] addObject:base];
            self.dataArray = nil;
            [self.tableView reloadData];
        }
    }
    else {
        LH_TestBaseModel *second = [[LH_DBTool defaultTool] searchObjectsFromClass:[LH_TestSecondModel class] conditionKey:LH_TestSecondModelPrimarykey_Age conditionValue:@"11"].firstObject;
//        LH_TestSecondModel *second = [[LH_DBTool defaultTool] defaultSearchObjectsFromClass:[LH_TestSecondModel class] conditionKey:LH_TestSecondModelPrimarykey_Age conditionValue:@"11"].firstObject;
        if (second) {
            second.identify = 30;
            second.name = @"second changed";
            [[LH_DBTool defaultTool] addObject:second];
            self.data2Array = nil;
            [self.tableView reloadData];
        }
    }
}
- (IBAction)deleteAction:(id)sender {
    
    if (self.isBase) {
        LH_TestBaseModel *base = [[LH_DBTool defaultTool] searchObjectsFromClass:[LH_TestBaseModel class] conditionKey:LH_TestBaseModel_Primarykey_Identify conditionValue:@"5"].firstObject;
        if (base) {
            [[LH_DBTool defaultTool] deleteObject:base];
            self.dataArray = nil;
            [self.tableView reloadData];
        }
    }
    else {
        LH_TestSecondModel *second = [[LH_DBTool defaultTool] searchObjectsFromClass:[LH_TestSecondModel class] conditionKey:LH_TestSecondModelPrimarykey_Age conditionValue:@"15"].firstObject;
        if (second) {
            [[LH_DBTool defaultTool] deleteObject:second];
            self.data2Array = nil;
            [self.tableView reloadData];
        }
    }
}



#pragma mark - ======== TableView ========
- (UITableView *)tableView
{
    if (!_tableView) {
        UIColor *tableViewBgColor = [UIColor clearColor];
        CGFloat tableViewRowHeight = 44.0f;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 200, self.view.bounds.size.width, self.view.bounds.size.height-200) style:UITableViewStylePlain];
        _tableView.backgroundColor = tableViewBgColor;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.rowHeight = tableViewRowHeight;
        
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            _tableView.estimatedRowHeight = 0;
            _tableView.estimatedSectionHeaderHeight = 0;
            _tableView.estimatedSectionFooterHeight = 0;
        }
    }
    return _tableView;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.isBase ? self.dataArray.count : self.data2Array.count;
}

#pragma mark ---- Cell ----
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCellStyleSubtitle"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCellStyleSubtitle"];
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCellStyleSubtitle"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (self.isBase) {
        LH_TestBaseModel *m = self.dataArray[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"Name:%@ - Identify:%zd", m.name, m.identify];
    }
    else {
        LH_TestSecondModel *m = self.data2Array[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"Name:%@ - Identify:%zd; Age:%zd", m.name, m.identify, m.age];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}


@end
