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

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation LH_ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSLog(@"docDir = %@", docDir);
    [[LH_DBTool defaultTool] startWithDBPath:docDir dbName:@"abc.db"];
    
    [self.view addSubview:self.tableView];
}

- (NSMutableArray *)dataArray
{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
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
    [self.dataArray removeAllObjects];
    
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        TestModel *m1 = [[TestModel alloc] init];
        m1.name = [NSString stringWithFormat:@"Name - %d", i];
        m1.page = i;
        m1.count = 200;
        [arr addObject:m1];
    }

    [[LH_DBTool defaultTool] addObjectsInTransaction:arr];
    
    [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] getAllObjectsWithClass:[TestModel class]]];
    [self.tableView reloadData];
    
}

- (IBAction)removeAction:(id)sender {
    
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        TestModel *m1 = [[TestModel alloc] init];
        m1.name = [NSString stringWithFormat:@"Name - %d", i];
        m1.page = i;
        m1.count = i+100;
        [arr addObject:m1];
    }
    [[LH_DBTool defaultTool] deleteObjects:arr];
    
    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] getAllObjectsWithClass:[TestModel class]]];
    [self.tableView reloadData];
}
- (IBAction)changeAction:(id)sender {
    
    TestModel *m1 = [[TestModel alloc] init];
    m1.name = [NSString stringWithFormat:@"Name - %d", 6];
    m1.page = 6;
    m1.count = 666;
    
    [[LH_DBTool defaultTool] addObject:m1];
    
    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] getAllObjectsWithClass:[TestModel class]]];
    [self.tableView reloadData];
}
- (IBAction)searchAction:(id)sender {
    
    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:[[LH_DBTool defaultTool] getObjectsWithClass:[TestModel class] conditionKey:TestModel_SearchKey_Count conditionValue:@"200"]];
    [self.tableView reloadData];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
