//
//  LH_DBObjectProtocol.h
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LH_DBObjectProtocol <NSObject>

@required
/// 自定义主键, 必须是该 Model 的属性名. 而且属性只限于 NSString, int, NSInteger 这三种
/// 如果返回多个字段.会默认创建多主键表.返回一个字段会创建单主键表,这里不能返回数组
- (NSArray<NSString *> *)LH_Primarykey;

/// 用于查询的属性.必须是该 Model 的属性名. 而且属性只限于 NSString, int, NSInteger 这三种
/// 不能和 LH_Primarykey 重复, 仅限用于查询的 condition 中使用
- (NSArray<NSString *> *)LH_SearchKey;

@end

NS_ASSUME_NONNULL_END
