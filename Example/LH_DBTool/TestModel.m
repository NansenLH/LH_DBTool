//
//  TestModel.m
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import "TestModel.h"
#import <YYModel/YYModel.h>

NSString * const TestModel_Key_Name = @"name";
NSString * const TestModel_Key_Page = @"page";
NSString * const TestModel_SearchKey_Count = @"count";


@implementation TestSubModel

@end

@implementation Shadow

@end


@implementation TestModel

- (NSString *)description {
    return [self yy_modelDescription];
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [self yy_modelEncodeWithCoder:aCoder];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    return [self yy_modelInitWithCoder:aDecoder];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self yy_modelCopy];
}

- (NSUInteger)hash {
    return [self yy_modelHash];
}

- (BOOL)isEqual:(id)object {
    return [self yy_modelIsEqual:object];
}

+ (NSDictionary *)modelCustomPropertyMapper
{
    //前面是model中的名字,后面是json中的名字
    return @{
       
    };
}

+ (NSDictionary *)modelContainerPropertyGenericClass
{
    return @{@"shadows" : [Shadow class]};
}


- (nonnull NSArray<NSString *> *)LH_Primarykey {
    return @[TestModel_Key_Name, TestModel_Key_Page];
}

- (nonnull NSArray<NSString *> *)LH_SearchKey {
    return @[TestModel_SearchKey_Count];
}

@end
