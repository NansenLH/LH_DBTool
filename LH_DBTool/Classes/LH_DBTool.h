//
//  LH_DBTool.h
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import "LH_DBObjectProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface LH_DBTool : NSObject

+ (LH_DBTool *)defaultTool;

#pragma mark - ======== 指定路径,存储的时候指定数据库文件名 ========
/// 数据库存储的路径
- (void)startInDBPath:(NSString *)dbPath;

#pragma mark ---- 增,删,改,查 ----
/// 往数据库中增加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
         inDBName:(NSString *)dbName;

/// 往数据库中增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的一组对象
- (BOOL)addObjectsInTransaction:(NSArray<id<LH_DBObjectProtocol>> *)objs
                       inDBName:(NSString *)dbName;

/// 从数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
          fromDBName:(NSString *)dbName;

- (BOOL)deleteObjects:(NSArray<id<LH_DBObjectProtocol>> *)objs
           fromDBName:(NSString *)dbName;


/// 根据条件获取对应的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)getObjectsWithClass:(Class)clazz
                       condition:(NSDictionary<NSString *, NSString *> *)condition
                      fromDBName:(NSString *)dbName;

/// 根据限定条件获取数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
- (NSArray *)getObjectsWithClass:(Class)clazz
                    conditionKey:(NSString *)conditionKey
                  conditionValue:(NSString *)conditionValue
                      fromDBName:(NSString *)dbName;

/// 获取数据表中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
- (NSArray *)getAllObjectsWithClass:(Class)clazz
                         fromDBName:(NSString *)dbName;


/// 删除数据表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名
- (BOOL)removeTable:(NSString *)tableName
           inDBName:(NSString *)dbName;




#pragma mark - ======== 指定路径和文件名, 直接存储 ========

/// 初始化数据库
/// @param dbPath 数据库沙盒路径
/// @param dbName 数据库名称. 不用加 .db 后缀
- (void)startInDBPath:(NSString *)dbPath
               dbName:(NSString *)dbName;

#pragma mark ---- 增,删,改,查 ----
/// 往数据库中增加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj;

/// 往数据库中增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的一组对象
- (BOOL)addObjectsInTransaction:(NSArray<id<LH_DBObjectProtocol>> *)objs;

/// 从数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj;

- (BOOL)deleteObjects:(NSArray<id<LH_DBObjectProtocol>> *)objs;


/// 根据条件获取对应的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)getObjectsWithClass:(Class)clazz
                       condition:(NSDictionary<NSString *, NSString *> *)condition;

/// 根据限定条件获取数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
- (NSArray *)getObjectsWithClass:(Class)clazz
                    conditionKey:(NSString *)conditionKey
                  conditionValue:(NSString *)conditionValue;

/// 获取数据表中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
- (NSArray *)getAllObjectsWithClass:(Class)clazz;


/// 删除数据表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名
- (BOOL)removeTable:(NSString *)tableName;

@end

NS_ASSUME_NONNULL_END
