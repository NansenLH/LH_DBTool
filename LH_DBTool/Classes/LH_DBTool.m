//
//  LH_DBTool.m
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import "LH_DBTool.h"
#import "LH_DBCore.h"
#import <fmdb/FMDB.h>
#import <YYModel/YYModel.h>

@interface LH_DBTool ()

@property (nonatomic, copy) NSString *dbPath;
@property (nonatomic, strong) NSMutableDictionary<NSString *, LH_DBCore *> *dbDict;

@property (nonatomic, strong, nullable) LH_DBCore *defaultCore;

@end


@implementation LH_DBTool

- (NSMutableDictionary *)dbDict
{
    if (!_dbDict) {
        _dbDict = [NSMutableDictionary dictionary];
    }
    return _dbDict;
}

- (BOOL)saveObject:(id<LH_DBObjectProtocol>)obj
            byCore:(LH_DBCore *)database
{
    [database tableCheck:obj];
    
    NSString *query = [database getInsertRecordQuery:obj];
    BOOL isSuccess = [database.dataBase executeUpdate:query, nil];
    
    return isSuccess;
}

- (BOOL)saveObjects:(NSArray<id<LH_DBObjectProtocol>> *)objs
             byCore:(LH_DBCore *)dataBase
{
    for (id<LH_DBObjectProtocol> obj in objs) {
        [dataBase tableCheck:obj];
    }
    
    __block NSMutableArray *array = [NSMutableArray array];
    [dataBase.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (id<LH_DBObjectProtocol> obj in objs) {
            NSString *query = [dataBase getInsertRecordQuery:obj];
            BOOL isSuccess = [db executeUpdate:query, nil];
            if (isSuccess == NO) {
                NSObject *errorObj = obj;
                NSLog(@"add obj failed -> obj = %@", [errorObj yy_modelDescription]);
                [array addObject:obj];
                *rollback = YES;
            }
        }
    }];
    return !(array.count > 0);
}


- (BOOL)removeObject:(id<LH_DBObjectProtocol>)obj
              byCore:(LH_DBCore *)dbCore
{
    if (obj == nil) {
        NSLog(@"Warning: deleteObject -> 参数不对");
        return NO;
    }
    
    [dbCore tableCheck:obj];
    
    return [self removeObjects:@[obj] byCore:dbCore];
}

- (BOOL)removeObjects:(NSArray<id<LH_DBObjectProtocol>> *)objs
               byCore:(LH_DBCore *)dbCore
{
    for (id<LH_DBObjectProtocol> obj in objs) {
        [dbCore tableCheck:obj];
    }
    
    __block BOOL isSuccess = NO;
    [dbCore.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [objs enumerateObjectsUsingBlock:^(id<LH_DBObjectProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *query = [dbCore formatDeleteSQLWithObjc:obj];
            isSuccess = [db executeUpdate:query, nil];
            if (!isSuccess) {
                NSObject *deleteObjc = obj;
                NSLog(@"deleteObject failed -> obj = %@", [deleteObjc yy_modelDescription]);
                *rollback = YES;
            }
        }];
    }];
    return isSuccess;
}


/// 根据条件获取对应的数据
- (NSArray *)searchObjectsWithClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition
                             byCore:(LH_DBCore *)dbCore
{
    NSObject<LH_DBObjectProtocol> *obj = [[clazz alloc] init];
    if ([obj respondsToSelector:@selector(LH_Primarykey)] == NO) {
        NSLog(@"Warning: 条件查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    
    [dbCore tableCheck:obj];
    
    NSMutableArray *availableProperties = [NSMutableArray array];
    [availableProperties addObjectsFromArray:[obj LH_Primarykey]];
    
    if ([obj respondsToSelector:@selector(LH_SearchKey)]) {
        [availableProperties addObjectsFromArray:[obj LH_SearchKey]];
    }
    
    BOOL isOkey = YES;
    for (NSString *key in condition.allKeys) {
        if ([availableProperties containsObject:key] == NO) {
            NSLog(@"Warning: 条件查询 -> key=%@ 不合法", key);
            isOkey = NO;
        }
    }
    if (isOkey == NO) {
        return @[];
    }
    
    NSString *sql = [dbCore formatCondition:condition WithClass:clazz];
    return [dbCore excuteSql:sql withClass:clazz];
}

/// 根据限定条件获取数据
- (NSArray *)searchObjectsWithClass:(Class)clazz
                       conditionKey:(NSString *)conditionKey
                     conditionValue:(NSString *)conditionValue
                             byCore:(LH_DBCore *)dbCore
{
    if (class_conformsToProtocol(clazz, @protocol(LH_DBObjectProtocol)) == NO) {
        NSLog(@"Warning: 条件查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    
    id<LH_DBObjectProtocol> obj = [clazz new];
    
    [dbCore tableCheck:obj];

    NSMutableArray *availableProperties = [NSMutableArray array];
    [availableProperties addObjectsFromArray:[obj LH_Primarykey]];
    
    if ([obj respondsToSelector:@selector(LH_SearchKey)]) {
        [availableProperties addObjectsFromArray:[obj LH_SearchKey]];
    }
    
    if ([availableProperties containsObject:conditionKey] == NO) {
        NSLog(@"Warning: 条件查询 -> key=%@ 不合法", conditionKey);
        return @[];
    }
    
    NSString *sql = [dbCore formatCondition:@{conditionKey : conditionValue} WithClass:clazz];
    return [dbCore excuteSql:sql withClass:clazz];
}


/// 根据限定条件获取数据
- (NSArray *)searchPageObjectsWithClass:(Class)clazz
                              sortByKey:(NSString *)sortKey
                              ascending:(BOOL)ascending
                              pageIndex:(NSInteger)pageIndex
                               pageSize:(NSInteger)pageSize
                                 byCore:(LH_DBCore *)dbCore
{
    if (class_conformsToProtocol(clazz, @protocol(LH_DBObjectProtocol)) == NO) {
        NSLog(@"Warning: 分页查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    
    if (pageIndex < 1) {
        NSLog(@"Warning: 分页查询 pageIndex[%zd] 参数不合法", pageIndex);
        return @[];
    }
    
    if (pageSize < 1 || pageSize > 100) {
        NSLog(@"Warning: 分页查询 pageSize[%zd] 参数不合法", pageSize);
        return @[];
    }
    
    id<LH_DBObjectProtocol> obj = [clazz new];
    
    [dbCore tableCheck:obj];
    
    NSMutableArray *availableProperties = [NSMutableArray array];
    [availableProperties addObjectsFromArray:[obj LH_Primarykey]];
    [availableProperties addObjectsFromArray:[obj LH_SearchKey]];
    
    if ([availableProperties containsObject:sortKey] == NO) {
        NSLog(@"Warning: 分页查询 -> sortKey=%@ 不合法", sortKey);
        return @[];
    }
    
    NSString *sql = [dbCore pageSearchSQLWithOrderKey:sortKey ascending:ascending pageIndex:pageIndex pageSize:pageSize withClass:clazz];
    return [dbCore excuteSql:sql withClass:clazz];
}


/// 获取数据表中的全部数据
- (NSArray *)allObjectsWithClass:(Class)clazz
                          byCore:(LH_DBCore *)dbCore
{
    if (class_conformsToProtocol(clazz, @protocol(LH_DBObjectProtocol)) == NO) {
        NSLog(@"Warning: 全部查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    
    id<LH_DBObjectProtocol> obj = [clazz new];
    
    [dbCore tableCheck:obj];
    
    NSString *tableName = NSStringFromClass(clazz);
    NSString *sql = [NSString stringWithFormat:@"select * from %s", [tableName UTF8String]];
    return [dbCore excuteSql:sql withClass:clazz];
}


/// 删除数据表
- (BOOL)deleteTable:(NSString *)tableName
             byCore:(LH_DBCore *)dbCore
{
    __block BOOL tf = NO;
    NSString *sql = [@"DROP TABLE " stringByAppendingString:tableName];
    tf = [dbCore.dataBase executeUpdate:sql,nil];
    return tf;
}

- (LH_DBCore * _Nullable)getDBCoreByDBName:(NSString *)dbName
{
    if (self.dbPath == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return nil;
    }
    
    LH_DBCore *dbCore = [self.dbDict objectForKey:dbName];
    if (dbCore == nil) {
        NSString *name = [NSString stringWithFormat:@"%@.db", dbName];
        NSString *dbFilePath = [self.dbPath stringByAppendingPathComponent:name];
        dbCore = [[LH_DBCore alloc] initWithDBPath:dbFilePath];
        [self.dbDict setObject:dbCore forKey:dbName];
    }
    return dbCore;
}


+ (LH_DBTool *)defaultTool
{
    static dispatch_once_t onceToken;
    static LH_DBTool *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [self defaultTool];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [LH_DBTool defaultTool];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [LH_DBTool defaultTool];
}


/// 开启数据库,指定文件存储的沙盒路径
- (void)startInDBPath:(NSString *)dbPath
{
    if (self.dbPath && [self.dbPath isEqualToString:dbPath]) {
        
        if ([self.dbPath isEqualToString:dbPath]) {
            return;
        }
        else {
            self.dbPath = nil;
            [self.dbDict removeAllObjects];
        }
    }
    
    self.dbPath = dbPath;
    
    NSLog(@"LH_DBTool startInDBPath:%@", dbPath);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dbPath] == NO) {
        [fm createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *db = [self.dbPath stringByAppendingPathComponent:@"LHDB.db"];
    self.defaultCore = [[LH_DBCore alloc] initWithDBPath:db];
}


/// 停止数据库的工作. 调用该方法后,所有的增删改查都无效.
- (void)stopDB
{
    NSLog(@"LH_DBTool stopDB");
    self.dbPath = nil;
    [self.dbDict removeAllObjects];
    
    self.defaultCore = nil;
}



#pragma mark - ======== 存储的时候指定数据库文件名 ========
#pragma mark ---- 增,删,改,查 ----
/// 往数据库中增加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
         inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        return NO;
    }
    
    return [self saveObject:obj byCore:dbCore];
}

/// 往数据库中增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的一组对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)addObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
              inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        return NO;
    }
    
    return [self saveObjects:objs byCore:dbCore];
}

/// 从数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
            inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        return NO;
    }
    
    return [self removeObject:obj byCore:dbCore];
}

- (BOOL)deleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
                 inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        return NO;
    }
    
    return [self removeObjects:objs byCore:dbCore];
}


/// 根据条件获取对应的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition
                           inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz condition:condition byCore:dbCore];
}

/// 根据限定条件获取数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (NSArray *)searchObjectsFromClass:(Class)clazz
                       conditionKey:(NSString *)conditionKey
                     conditionValue:(NSString *)conditionValue
                           inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz conditionKey:conditionKey conditionValue:conditionValue byCore:dbCore];
}


/// 获取数据表中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (NSArray *)searchAllObjectsFromClass:(Class)clazz
                              inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        return @[];
    }
    
    return [self allObjectsWithClass:clazz byCore:dbCore];
}


/// 分页查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param sortKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param ascending 是否升序. 升序-YES, 降序-NO
/// @param pageIndex 第几页. 从 1 开始
/// @param pageSize 每页的个数. 最小 1, 建议不大于 50. 限制最大值 100
/// @param dbName 数据库文件名
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          sortByKey:(NSString *)sortKey
                          ascending:(BOOL)ascending
                          pageIndex:(NSInteger)pageIndex
                           pageSize:(NSInteger)pageSize
                           inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        return @[];
    }
    
    return [self searchPageObjectsWithClass:clazz sortByKey:sortKey ascending:ascending pageIndex:pageIndex pageSize:pageSize byCore:dbCore];
}


/// 删除数据表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)removeTable:(NSString *)tableName
           inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        return NO;
    }
    
    return [self deleteTable:tableName byCore:dbCore];
}


#pragma mark - ======== 直接存储,默认会存储在 LHDB.db 中 ========
/// 设置默认的数据库文件名. e.g. @"abc", 会使用 abc.db 作为数据库文件, 不设置,默认为 LHDB.db. 设置之后,下面的所有增删改查都会在新数据库中执行
- (void)setDefaultDBFileName:(NSString *)dbName
{
    if (self.dbPath == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return;
    }
    
    NSString *name = [NSString stringWithFormat:@"%@.db", dbName];
    NSString *db = [self.dbPath stringByAppendingPathComponent:name];
    self.defaultCore = [[LH_DBCore alloc] initWithDBPath:db];
}


#pragma mark ---- 增,删,改,查 ----
/// 默认数据库中增加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)defaultAddObject:(id<LH_DBObjectProtocol>)obj
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return NO;
    }
    
    return [self saveObject:obj byCore:self.defaultCore];
}

/// 默认数据库中增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的一组对象
- (BOOL)defaultAddObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return NO;
    }
    
    return [self saveObjects:objs byCore:self.defaultCore];
}


/// 默认数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)defaultDeleteObject:(id<LH_DBObjectProtocol>)obj
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return NO;
    }
    
    return [self removeObject:obj byCore:self.defaultCore];
}


- (BOOL)defaultDeleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return NO;
    }
    
    return [self removeObjects:objs byCore:self.defaultCore];
}


/// 根据条件查询默认数据库中的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)defaultSearchObjectsFromClass:(Class)clazz
                                 condition:(NSDictionary<NSString *, NSString *> *)condition
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz condition:condition byCore:self.defaultCore];
}

/// 根据限定条件查询默认数据库的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
- (NSArray *)defaultSearchObjectsFromClass:(Class)clazz
                              conditionKey:(NSString *)conditionKey
                            conditionValue:(NSString *)conditionValue
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz conditionKey:conditionKey conditionValue:conditionValue byCore:self.defaultCore];
}

/// 获取默认数据库中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
- (NSArray *)defaultSearchAllObjectsFromClass:(Class)clazz
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return @[];
    }
    
    return [self allObjectsWithClass:clazz byCore:self.defaultCore];
}


/// 获取默认数据库中的分页查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param sortKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param ascending 是否升序. 升序-YES, 降序-NO
/// @param pageIndex 第几页. 从 1 开始
/// @param pageSize 每页的个数. 最小 1, 建议不大于 50. 限制最大值 100
- (NSArray *)defaultSearchObjectsFromClass:(Class)clazz
                                 sortByKey:(NSString *)sortKey
                                 ascending:(BOOL)ascending
                                 pageIndex:(NSInteger)pageIndex
                                  pageSize:(NSInteger)pageSize
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return @[];
    }
    
    return [self searchPageObjectsWithClass:clazz sortByKey:sortKey ascending:ascending pageIndex:pageIndex pageSize:pageSize byCore:self.defaultCore];
}


/// 删除默认数据库中的指定表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名
- (BOOL)defaultRemoveTable:(NSString *)tableName
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        return NO;
    }
    
    return [self deleteTable:tableName byCore:self.defaultCore];
}





@end
