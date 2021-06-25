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

/// 开启数据库,指定文件存储的沙盒路径
- (void)startInDBPath:(NSString *)dbPath;

/// 停止数据库的工作. 调用该方法后,所有的增删改查都无效,保护数据库防止被意外污染.
/// 必须重新调用 start 方法之后才可重新使用增删改查
- (void)stopDB;

#pragma mark - ======== 存储的时候指定数据库文件名 ========
#pragma mark ---- 增,删,改,查 ----
/// 往数据库中增加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
         inDBName:(NSString *)dbName;

/// 往数据库中增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的一组对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)addObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
              inDBName:(NSString *)dbName;

/// 从数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
            inDBName:(NSString *)dbName;
- (BOOL)deleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
                 inDBName:(NSString *)dbName;


/// 根据条件获取对应的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition
                           inDBName:(NSString *)dbName;

/// 根据限定条件获取数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (NSArray *)searchObjectsFromClass:(Class)clazz
                       conditionKey:(NSString *)conditionKey
                     conditionValue:(NSString *)conditionValue
                           inDBName:(NSString *)dbName;

/// 获取数据表中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (NSArray *)searchAllObjectsFromClass:(Class)clazz
                              inDBName:(NSString *)dbName;

#warning TODO : NOT Finish -
/// 分页查询数据 - 未实现,待处理
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          pageIndex:(NSInteger)pageIndex
                           pageSize:(NSInteger)pageSize
                           inDBName:(NSString *)dbName;


/// 删除数据表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)removeTable:(NSString *)tableName
           inDBName:(NSString *)dbName;




#pragma mark - ======== 直接存储,默认会存储在 LHDB.db 中 ========
/// 设置默认的数据库文件名, 不设置,默认为 LHDB.db. 设置之后,下面的所有增删改查都会在新数据库中执行
- (void)setDefaultDBFileName:(NSString *)dbName;

#pragma mark ---- 增,删,改,查 ----
/// 默认数据库中增加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)defaultAddObject:(id<LH_DBObjectProtocol>)obj;

/// 默认数据库中增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的一组对象
- (BOOL)defaultAddObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs;

/// 默认数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)defaultDeleteObject:(id<LH_DBObjectProtocol>)obj;
- (BOOL)defaultDeleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs;


/// 根据条件查询默认数据库中的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)defaultSearchObjectsFromClass:(Class)clazz
                                 condition:(NSDictionary<NSString *, NSString *> *)condition;

/// 根据限定条件查询默认数据库的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
- (NSArray *)defaultSearchObjectsFromClass:(Class)clazz
                              conditionKey:(NSString *)conditionKey
                            conditionValue:(NSString *)conditionValue;

/// 获取默认数据库中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
- (NSArray *)defaultSearchAllObjectsFromClass:(Class)clazz;


/// 删除默认数据库中的指定表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名
- (BOOL)defaultRemoveTable:(NSString *)tableName;

@end

NS_ASSUME_NONNULL_END
