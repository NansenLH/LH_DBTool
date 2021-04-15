//
//  TestModel.m
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import "TestModel.h"

@implementation TestSubModel

@end

@implementation Shadow

@end


@implementation TestModel

// 返回容器类中的所需要存放的数据类型 (以 Class 或 Class Name 的形式)。
+ (NSDictionary *)modelContainerPropertyGenericClass
{
    return @{@"shadows" : [Shadow class]};
}


- (nonnull NSArray<NSString *> *)LH_Primarykey {
    return @[@"name", @"page"];
}

- (nonnull NSArray<NSString *> *)LH_SearchKey {
    return @[@"count"];
}

@end
