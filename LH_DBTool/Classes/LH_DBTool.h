//
//  LH_DBTool.h
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import "LH_DBObjectProtocol.h"
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface LH_DBTool : NSObject

+ (LH_DBTool *)defaultTool;


/// 初始化数据库
/// @param dbPath 数据库沙盒路径
/// @param dbName 数据库名称 xxx.db
- (void)startWithDBPath:(NSString *)dbPath
                 dbName:(NSString *)dbName;






#pragma mark - ======== 增,删,改,查 ========
/// 往数据库中增加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol, YYModel>的对象
- (BOOL)addObject:(id<LH_DBObjectProtocol, YYModel>)obj;

/// 往数据库中增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol, YYModel>的一组对象
- (BOOL)addObjectsInTransaction:(NSArray<id<LH_DBObjectProtocol, YYModel>> *)objs;

/// 从数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol, YYModel>的对象
- (BOOL)deleteObject:(id<LH_DBObjectProtocol, YYModel>)obj;
- (BOOL)deleteObjects:(NSArray<id<LH_DBObjectProtocol, YYModel>> *)objs;


/// 根据条件获取对应的数据
/// @param clazz 遵循<LH_DBObjectProtocol, YYModel>的对象
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)getObjectsWithClass:(Class)clazz
                       condition:(NSDictionary<NSString *, NSString *> *)condition;

/// 获取数据表中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol, YYModel>的对象
- (NSArray *)getAllObjectsWithClass:(Class)clazz;


/// 删除数据表
/// @param tableName 遵循<LH_DBObjectProtocol, YYModel>的类名
- (BOOL)removeTable:(NSString *)tableName;

@end

NS_ASSUME_NONNULL_END
