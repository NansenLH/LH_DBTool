//
//  LH_ViewController.m
//  LH_DBTool
//
//  Created by NansenLH on 04/15/2021.
//  Copyright (c) 2021 NansenLH. All rights reserved.
//

#import "LH_ViewController.h"
#import "TestModel.h"


@interface LH_ViewController ()
<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *testDBArray;

@property (nonatomic, strong) NSMutableArray *abcDBArray;

@property (nonatomic, strong) NSMutableArray *tttDBArray;

@property (nonatomic, assign) NSInteger segIndex;

@end

@implementation LH_ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.segIndex = 0;
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSLog(@"docDir = %@", docDir);
    [[LH_DBTool defaultTool] startInDBPath:docDir];
    
    [[LH_DBTool defaultTool] startInDBPath:docDir dbName:@"testDB"];
    
    [self.view addSubview:self.tableView];
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
        
    self.segIndex = sender.selectedSegmentIndex;
    
    self.testDBArray = nil;
    [self.testDBArray count];
    self.abcDBArray = nil;
    [self.abcDBArray count];
    self.tttDBArray = nil;
    [self.tttDBArray count];
    
    [self.tableView reloadData];
}



- (NSMutableArray *)abcDBArray
{
    if (!_abcDBArray) {
        _abcDBArray = [NSMutableArray array];
        
        [_abcDBArray addObjectsFromArray:[[LH_DBTool defaultTool] getAllObjectsWithClass:[TestModel class] fromDBName:@"abc"]];
    }
    return _abcDBArray;
}

- (NSMutableArray *)testDBArray
{
    if (!_testDBArray) {
        _testDBArray = [NSMutableArray array];
        [_testDBArray addObjectsFromArray:[[LH_DBTool defaultTool] getAllObjectsWithClass:[TestModel class]]];
    }
    return _testDBArray;
}

- (NSMutableArray *)tttDBArray
{
    if (!_tttDBArray) {
        _tttDBArray = [NSMutableArray array];
        
        [_tttDBArray addObjectsFromArray:[[LH_DBTool defaultTool] getAllObjectsWithClass:[TestModel class] fromDBName:@"ttt"]];
    }
    return _tttDBArray;
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
    if (self.segIndex == 0) {
        return self.testDBArray.count;
    }
    else if (self.segIndex == 1) {
        return self.abcDBArray.count;
    }
    else {
        return self.tttDBArray.count;
    }
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
    
    
    TestModel *m = nil;
    if (self.segIndex == 0) {
        m = self.testDBArray[indexPath.row];
    }
    else if (self.segIndex == 1) {
        m = self.abcDBArray[indexPath.row];
    }
    else {
        m = self.tttDBArray[indexPath.row];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@; %zd; %d", m.name, m.page, m.count];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}


- (IBAction)addAction:(id)sender
{
    NSString *name = @"testDB";
    NSMutableArray *currentArray = self.testDBArray;
    
    if (self.segIndex == 1) {
        name = @"abc";
        currentArray = self.abcDBArray;
    }
    else if (self.segIndex == 2) {
        name = @"ttt";
        currentArray = self.tttDBArray;
    }
    
    [currentArray removeAllObjects];
    
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        TestModel *m1 = [[TestModel alloc] init];
        m1.name = [NSString stringWithFormat:@"%@ - %d", name, i];
        m1.page = i;
        m1.count = 200;
        [arr addObject:m1];
    }

    [[LH_DBTool defaultTool] addObjectsInTransaction:arr inDBName:name];
    [currentArray addObjectsFromArray:[[LH_DBTool defaultTool] getAllObjectsWithClass:[TestModel class] fromDBName:name]];
    [self.tableView reloadData];
}

- (IBAction)removeAction:(id)sender {
    
    NSString *name = @"testDB";
    NSMutableArray *currentArray = self.testDBArray;
    
    if (self.segIndex == 1) {
        name = @"abc";
        currentArray = self.abcDBArray;
    }
    else if (self.segIndex == 2) {
        name = @"ttt";
        currentArray = self.tttDBArray;
    }
    
    
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        TestModel *m1 = [[TestModel alloc] init];
        m1.name = [NSString stringWithFormat:@"%@ - %d", name, i];
        m1.page = i;
        m1.count = i+100;
        [arr addObject:m1];
    }
    
    [[LH_DBTool defaultTool] deleteObjects:arr fromDBName:name];
    
    [currentArray removeAllObjects];
    [currentArray addObjectsFromArray:[[LH_DBTool defaultTool] getAllObjectsWithClass:[TestModel class]]];
    [self.tableView reloadData];
}

- (IBAction)changeAction:(id)sender {
    
    NSString *name = @"testDB";
    NSMutableArray *currentArray = self.testDBArray;
    
    if (self.segIndex == 1) {
        name = @"abc";
        currentArray = self.abcDBArray;
    }
    else if (self.segIndex == 2) {
        name = @"ttt";
        currentArray = self.tttDBArray;
    }
    
    TestModel *m1 = [[TestModel alloc] init];
    m1.name = [NSString stringWithFormat:@"%@ - %d", name, 6];
    m1.page = 6;
    m1.count = 666;
    
    [[LH_DBTool defaultTool] addObject:m1 inDBName:name];
    
    [currentArray removeAllObjects];
    [currentArray addObjectsFromArray:[[LH_DBTool defaultTool] getAllObjectsWithClass:[TestModel class] fromDBName:name]];
    [self.tableView reloadData];
}

- (IBAction)searchAction:(id)sender {
    
    NSString *name = @"testDB";
    NSMutableArray *currentArray = self.testDBArray;
    
    if (self.segIndex == 1) {
        name = @"abc";
        currentArray = self.abcDBArray;
    }
    else if (self.segIndex == 2) {
        name = @"ttt";
        currentArray = self.tttDBArray;
    }
    
    [currentArray removeAllObjects];
    [currentArray addObjectsFromArray:[[LH_DBTool defaultTool] getObjectsWithClass:[TestModel class] conditionKey:TestModel_SearchKey_Count conditionValue:@"200" fromDBName:name]];
    [self.tableView reloadData];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
