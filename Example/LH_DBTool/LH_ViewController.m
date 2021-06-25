//
//  LH_ViewController.m
//  LH_DBTool
//
//  Created by NansenLH on 04/15/2021.
//  Copyright (c) 2021 NansenLH. All rights reserved.
//

#import "LH_ViewController.h"
#import "TestModel.h"

static NSString *const DBName1 = @"111";
static NSString *const DBName2 = @"222";

@interface LH_ViewController ()
<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<TestModel *> *dataArray;

@property (nonatomic, assign) NSInteger segIndex;
@property (nonatomic, copy) NSString *dbName;

@end

@implementation LH_ViewController

- (NSMutableArray *)dataArray
{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.segIndex = 0;
    self.dbName = @"LHDB";
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    [[LH_DBTool defaultTool] startInDBPath:docDir];
    
    [self.view addSubview:self.tableView];
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
        
    self.segIndex = sender.selectedSegmentIndex;
    
    [self.dataArray removeAllObjects];
    if (self.segIndex == 0) {
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] defaultSearchAllObjectsFromClass:[TestModel class]]];
    }
    else if (self.segIndex == 1) {
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] searchAllObjectsFromClass:[TestModel class] inDBName:DBName1]];
    }
    else {
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] searchAllObjectsFromClass:[TestModel class] inDBName:DBName2]];
    }
    
    [self.tableView reloadData];
}

- (void)setSegIndex:(NSInteger)segIndex
{
    _segIndex = segIndex;
    
    if (segIndex == 0) {
        self.dbName = @"LHDB";
    }
    else if (segIndex == 1) {
        self.dbName = DBName1;
    }
    else {
        self.dbName = DBName2;
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
    return self.dataArray.count;
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
    
    
    TestModel *m = self.dataArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@; %zd; %d", m.name, m.page, m.count];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}


- (IBAction)addAction:(id)sender
{
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        TestModel *m1 = [[TestModel alloc] init];
        m1.name = [NSString stringWithFormat:@"%@ - %d", self.dbName, i];
        m1.page = i;
        m1.count = 200;
        [arr addObject:m1];
    }
    
    [self.dataArray removeAllObjects];
    if (self.segIndex == 0) {
        [[LH_DBTool defaultTool] defaultAddObjectArray:arr];
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] defaultSearchAllObjectsFromClass:[TestModel class]]];
    }
    else if (self.segIndex == 1) {
        [[LH_DBTool defaultTool] addObjectArray:arr inDBName:self.dbName];
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] searchAllObjectsFromClass:[TestModel class] inDBName:self.dbName]];
    }
    else {
        [[LH_DBTool defaultTool] addObjectArray:arr inDBName:self.dbName];
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] searchAllObjectsFromClass:[TestModel class] inDBName:self.dbName]];
    }
    
    [self.tableView reloadData];
}

- (IBAction)removeAction:(id)sender
{
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        TestModel *m1 = [[TestModel alloc] init];
        m1.name = [NSString stringWithFormat:@"%@ - %d", self.dbName, i];
        m1.page = i;
        m1.count = i+100;
        [arr addObject:m1];
    }
    
    if (self.segIndex == 0) {
        [[LH_DBTool defaultTool] defaultDeleteObjectArray:arr];
        [self.dataArray removeAllObjects];
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] defaultSearchAllObjectsFromClass:[TestModel class]]];
    }
    else {
        [[LH_DBTool defaultTool] deleteObjectArray:arr inDBName:self.dbName];
        [self.dataArray removeAllObjects];
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] searchAllObjectsFromClass:[TestModel class] inDBName:self.dbName]];
    }
    
    [self.tableView reloadData];
}

- (IBAction)changeAction:(id)sender
{
    TestModel *m1 = [[TestModel alloc] init];
    m1.name = [NSString stringWithFormat:@"%@ - %d", self.dbName, 6];
    m1.page = 6;
    m1.count = 666;
    
    if (self.segIndex == 0) {
        [[LH_DBTool defaultTool] defaultAddObject:m1];
        [self.dataArray removeAllObjects];
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] defaultSearchAllObjectsFromClass:[TestModel class]]];
    }
    else {
        [[LH_DBTool defaultTool] addObject:m1 inDBName:self.dbName];
        [self.dataArray removeAllObjects];
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] searchAllObjectsFromClass:[TestModel class] inDBName:self.dbName]];
    }
    
    [self.tableView reloadData];
}

- (IBAction)searchAction:(id)sender
{
    [self.dataArray removeAllObjects];
    if (self.segIndex == 0) {
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] defaultSearchObjectsFromClass:[TestModel class] conditionKey:TestModel_SearchKey_Count conditionValue:@"200"]];
    }
    else {
        [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] searchObjectsFromClass:[TestModel class] conditionKey:TestModel_SearchKey_Count conditionValue:@"200" inDBName:self.dbName]];
    }
    
    [self.tableView reloadData];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
