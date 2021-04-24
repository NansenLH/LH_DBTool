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

@end

@implementation LH_ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        TestModel *m1 = [[TestModel alloc] init];
        m1.name = [NSString stringWithFormat:@"Name - %d", i];
        m1.page = i;
        m1.count = i+100;
        [arr addObject:m1];
    }
    
    NSLog(@"docDir = %@", docDir);
    
    [[LH_DBTool defaultTool] startWithDBPath:docDir dbName:@"abc.db"];
    
    [[LH_DBTool defaultTool] addObjectsInTransaction:arr];
    
    [[LH_DBTool defaultTool] startWithDBPath:docDir dbName:@"bcd.db"];
    
    NSMutableArray *arr2 = [NSMutableArray array];
    for (int i = 20; i < 30; i++) {
        TestModel *m1 = [[TestModel alloc] init];
        m1.name = [NSString stringWithFormat:@"Name - %d", i];
        m1.page = i;
        m1.count = i+100;
        [arr2 addObject:m1];
    }
    
    
    [[LH_DBTool defaultTool] addObjectsInTransaction:arr2];
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
