//
//  LH_TestBaseModel.h
//  LH_DBTool_Example
//
//  Created by Nansen on 2021/6/29.
//  Copyright © 2021 NansenLH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LH_DBTool/LH_DBTool.h>


NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString * const LH_TestBaseModel_Primarykey_Identify;


@interface LH_TestBaseModel : NSObject<LH_DBObjectProtocol>

@property (nonatomic, assign) NSInteger identify;
@property (nonatomic, copy) NSString *name;

@end


UIKIT_EXTERN NSString * const LH_TestSecondModelPrimarykey_Age;

@interface LH_TestSecondModel : LH_TestBaseModel<LH_DBObjectProtocol>

@property (nonatomic, assign) NSInteger age;

@end



NS_ASSUME_NONNULL_END
