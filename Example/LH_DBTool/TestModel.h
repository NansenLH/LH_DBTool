//
//  TestModel.h
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <LH_DBTool/LH_DBTool.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString * const TestModel_Key_Name;
UIKIT_EXTERN NSString * const TestModel_Key_Page;

UIKIT_EXTERN NSString * const TestModel_SearchKey_Count;

@interface TestSubModel : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDate *birthday;

@end


@interface Shadow : NSObject

@property (nonatomic, assign) NSInteger size;

@end

@interface TestModel : NSObject<LH_DBObjectProtocol>

@property (nonatomic, copy) NSString *name;

@property (nonatomic, assign) NSInteger page;

@property (nonatomic, assign) int count;

@property (nonatomic, strong) TestSubModel *subModel;

@property (nonatomic, strong) NSArray<Shadow *> *shadows;

@end





NS_ASSUME_NONNULL_END
