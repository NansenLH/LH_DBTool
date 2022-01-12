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

/// 默认的文件名 LHDB.db
@property (nonatomic, copy, readonly) NSString *defaultFileName;

+ (LH_DBTool *)defaultTool;

/// 开启数据库,指定文件存储的沙盒路径
- (void)startInDBPath:(NSString *)dbPath;

/// 停止数据库的工作. 调用该方法后,所有的增删改查都无效,保护数据库防止被意外污染.
/// 必须重新调用 start 方法之后才可重新使用增删改查
- (void)stopDB;

/// 设置默认的数据库文件名, 不设置,默认为 LHDB.db. 设置之后,所有的默认增删改查都会在新数据库中执行
- (void)setDefaultDBFileName:(NSString *)dbName;


#pragma mark - ======== 表操作 ========
/// 表的创建会默认处理.


/// 删除指定数据表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名或者是自定义的表名
/// @param dbName 数据库文件名,不用加后缀. 
- (BOOL)removeTable:(NSString *)tableName
           inDBName:(NSString * _Nullable)dbName;


#pragma mark - ======== 数据操作 ========
#pragma mark ---- 增,改 ----
/// 增加或者更新一条数据
/// 默认数据库, 默认使用类名作为表名
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj;

/// 添加或者更新一条数据
/// 默认数据库, 指定表名
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param tableName 指定的表名
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
    toCustomTable:(NSString *)tableName;

/// 添加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
    toCustomTable:(NSString * _Nullable)tableName
         inDBName:(NSString * _Nullable)dbName;


/// 增加或者更新一组数据. 默认数据库, 默认使用类名作为表名
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
- (BOOL)addObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs;

/// 增加或者更新一组数据.
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
/// @param tableName 指定表名
- (BOOL)addObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
         toCustomTable:(NSString *)tableName;

/// 增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
/// @param tableName 指定表名, 若为 nil, 则使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)addObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
         toCustomTable:(NSString * _Nullable)tableName
              inDBName:(NSString * _Nullable)dbName;




#pragma mark ---- 删 ----
/// 默认数据库中删除一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj;


/// 数据库中删除一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param tableName 指定表名
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
     fromCustomTable:(NSString *)tableName;

/// 从数据库中删除一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
     fromCustomTable:(NSString * _Nullable)tableName
            inDBName:(NSString * _Nullable)dbName;



/// 删除一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
- (BOOL)deleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs;


/// 删除一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
/// @param tableName tableName 指定表名
- (BOOL)deleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
          fromCustomTable:(NSString *)tableName;

/// 删除一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)deleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
          fromCustomTable:(NSString * _Nullable)tableName
                 inDBName:(NSString * _Nullable)dbName;


/// 删除指定表中的所有数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
- (BOOL)deleteAllObjectsFromClass:(Class)clazz;

/// 删除指定表中的所有数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param tableName 指定表名
- (BOOL)deleteAllObjectsFromClass:(Class)clazz
                  fromCustomTable:(NSString *)tableName;

/// 删除指定表中的所有数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)deleteAllObjectsFromClass:(Class)clazz
                  fromCustomTable:(NSString * _Nullable)tableName
                         InDBName:(NSString * _Nullable)dbName;




                        
#pragma mark ---- 查 ----
/// 获取默认数据库中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
- (NSArray *)searchAllObjectsFromClass:(Class)clazz;

/// 获取全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param tableName 指定表名
- (NSArray *)searchAllObjectsFromClass:(Class)clazz
                           customTable:(NSString *)tableName;

/// 获取全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (NSArray *)searchAllObjectsFromClass:(Class)clazz
                           customTable:(NSString * _Nullable)tableName
                              inDBName:(NSString * _Nullable)dbName;



/// 根据一个限定条件查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
- (NSArray *)searchObjectsFromClass:(Class)clazz
                       conditionKey:(NSString *)conditionKey
                     conditionValue:(NSString *)conditionValue;

/// 根据一个限定条件查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
/// @param tableName 指定表名
- (NSArray *)searchObjectsFromClass:(Class)clazz
                       conditionKey:(NSString *)conditionKey
                     conditionValue:(NSString *)conditionValue
                        customTable:(NSString *)tableName;

/// 根据一个限定条件查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (NSArray *)searchObjectsFromClass:(Class)clazz
                       conditionKey:(NSString *)conditionKey
                     conditionValue:(NSString *)conditionValue
                        customTable:(NSString * _Nullable)tableName
                           inDBName:(NSString * _Nullable)dbName;



/// 根据条件查询默认数据库中的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition;

/// 根据条件查询默认数据库,指定表中的数据
/// @param clazz clazz 遵循<LH_DBObjectProtocol>的类
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param tableName 指定表名
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition
                          tableName:(NSString *)tableName;

/// 根据条件获取对应的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition
                          tableName:(NSString * _Nullable)tableName
                           inDBName:(NSString * _Nullable)dbName;







/// 获取默认数据库中的分页查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param sortKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param ascending 是否升序. 升序-YES, 降序-NO
/// @param pageIndex 第几页. 从 1 开始
/// @param pageSize 每页的个数. 最小 1, 建议不大于 50. 限制最大值 100
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          sortByKey:(NSString *)sortKey
                          ascending:(BOOL)ascending
                          pageIndex:(NSInteger)pageIndex
                           pageSize:(NSInteger)pageSize;


/// 分页查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param sortKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param ascending 是否升序. 升序-YES, 降序-NO
/// @param pageIndex 第几页. 从 1 开始
/// @param pageSize 每页的个数. 最小 1, 建议不大于 50. 限制最大值 100
/// @param tableName 指定表名
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          sortByKey:(NSString *)sortKey
                          ascending:(BOOL)ascending
                          pageIndex:(NSInteger)pageIndex
                           pageSize:(NSInteger)pageSize
                          tableName:(NSString *)tableName;

/// 分页查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param sortKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param ascending 是否升序. 升序-YES, 降序-NO
/// @param pageIndex 第几页. 从 1 开始
/// @param pageSize 每页的个数. 最小 1, 建议不大于 50. 限制最大值 100
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          sortByKey:(NSString *)sortKey
                          ascending:(BOOL)ascending
                          pageIndex:(NSInteger)pageIndex
                           pageSize:(NSInteger)pageSize
                          tableName:(NSString * _Nullable)tableName
                           inDBName:(NSString * _Nullable)dbName;


@end

NS_ASSUME_NONNULL_END
