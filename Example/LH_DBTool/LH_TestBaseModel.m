//
//  LH_TestBaseModel.m
//  LH_DBTool_Example
//
//  Created by Nansen on 2021/6/29.
//  Copyright © 2021 NansenLH. All rights reserved.
//

#import "LH_TestBaseModel.h"
#import <YYModel/YYModel.h>

NSString * const LH_TestBaseModel_Primarykey_Identify = @"identify";


@implementation LH_TestBaseModel

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




- (nonnull NSArray<NSString *> *)LH_Primarykey { 
    return @[LH_TestBaseModel_Primarykey_Identify];
}

- (nonnull NSArray<NSString *> *)LH_SearchKey {
    return @[];
}

@end

NSString * const LH_TestSecondModelPrimarykey_Age = @"age";

@implementation LH_TestSecondModel

- (NSString *)description {
    return [self yy_modelDescription];
}


- (nonnull NSArray<NSString *> *)LH_Primarykey {
    return @[LH_TestSecondModelPrimarykey_Age];
}

- (nonnull NSArray<NSString *> *)LH_SearchKey {
    return @[];
}

@end
