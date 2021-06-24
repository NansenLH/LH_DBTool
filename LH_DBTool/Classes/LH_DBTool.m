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

@property (nonatomic, strong) LH_DBCore *defaultCore;

@property (nonatomic, strong) NSMutableDictionary<NSString *, LH_DBCore *> *dbDict;

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

#pragma mark ---- 指定路径,存储的时候指定数据库文件名 ----
/// 数据库存储的路径
- (void)startInDBPath:(NSString *)dbPath
{
    self.dbPath = dbPath;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dbPath] == NO) {
        [fm createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (LH_DBCore * _Nullable)getDBCoreByDBName:(NSString *)dbName
{
    if (self.dbPath == nil) {
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


#pragma mark ---- 增,删,改,查 ----
/// 往数据库中增加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
         inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        NSLog(@"LH_DBTool 请先调用 start... 方法");
        return NO;
    }
    
    return [self saveObject:obj byCore:dbCore];
}

/// 往数据库中增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的一组对象
- (BOOL)addObjectsInTransaction:(NSArray<id<LH_DBObjectProtocol>> *)objs
                       inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        NSLog(@"LH_DBTool 请先调用 start... 方法");
        return NO;
    }
    
    return [self saveObjects:objs byCore:dbCore];
}

/// 从数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
          fromDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        NSLog(@"LH_DBTool 请先调用 start... 方法");
        return NO;
    }
    
    return [self removeObject:obj byCore:dbCore];
}

- (BOOL)deleteObjects:(NSArray<id<LH_DBObjectProtocol>> *)objs
           fromDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        NSLog(@"LH_DBTool 请先调用 start... 方法");
        return NO;
    }
    
    return [self removeObjects:objs byCore:dbCore];
}


/// 根据条件获取对应的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)getObjectsWithClass:(Class)clazz
                       condition:(NSDictionary<NSString *, NSString *> *)condition
                      fromDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        NSLog(@"LH_DBTool 请先调用 start... 方法");
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz condition:condition byCore:dbCore];
}

/// 根据限定条件获取数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
- (NSArray *)getObjectsWithClass:(Class)clazz
                    conditionKey:(NSString *)conditionKey
                  conditionValue:(NSString *)conditionValue
                      fromDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        NSLog(@"LH_DBTool 请先调用 start... 方法");
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz conditionKey:conditionKey conditionValue:conditionValue byCore:dbCore];
}

/// 获取数据表中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
- (NSArray *)getAllObjectsWithClass:(Class)clazz
                         fromDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        NSLog(@"LH_DBTool 请先调用 start... 方法");
        return @[];
    }
    
    return [self allObjectsWithClass:clazz byCore:dbCore];
}


/// 删除数据表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名
- (BOOL)removeTable:(NSString *)tableName
           inDBName:(NSString *)dbName
{
    LH_DBCore *dbCore = [self getDBCoreByDBName:dbName];
    if (dbCore == nil) {
        NSLog(@"LH_DBTool 请先调用 start... 方法");
        return NO;
    }
    
    return [self deleteTable:tableName byCore:dbCore];
}







#pragma mark - ======== 指定路径和文件名, 直接存储 ========
/// 初始化数据库
/// @param dbPath 数据库沙盒路径
/// @param dbName 数据库名称 xxx
- (void)startInDBPath:(NSString *)dbPath
               dbName:(NSString *)dbName
{
    if (self.defaultCore) {
        self.defaultCore = nil;
    }
    
    self.dbPath = dbPath;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dbPath] == NO) {
        [fm createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *db = [dbPath stringByAppendingPathComponent:dbName];
    self.defaultCore = [[LH_DBCore alloc] initWithDBPath:db];
    NSLog(@"初始化数据库");
}

#pragma mark ---- 增,删,改,查 ----
/// 往数据库中增加或者更新一条数据<不开启事务>
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath:dbName: 方法");
        return NO;
    }
    
    return [self saveObject:obj byCore:self.defaultCore];
}

/// 往数据库中增加或者更新一组数据,开始事务
/// @param objs 遵循<LH_DBObjectProtocol>的一组对象
- (BOOL)addObjectsInTransaction:(NSArray<id<LH_DBObjectProtocol>> *)objs
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath:dbName: 方法");
        return NO;
    }
    
    return [self saveObjects:objs byCore:self.defaultCore];
}


/// 从数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath:dbName: 方法");
        return NO;
    }
    
    return [self removeObject:obj byCore:self.defaultCore];
}

- (BOOL)deleteObjects:(NSArray<id<LH_DBObjectProtocol>> *)objs
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath:dbName: 方法");
        return NO;
    }
    
    return [self removeObjects:objs byCore:self.defaultCore];
}


/// 根据条件获取对应的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)getObjectsWithClass:(Class)clazz
                       condition:(NSDictionary<NSString *, NSString *> *)condition
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath:dbName: 方法");
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz condition:condition byCore:self.defaultCore];
}

/// 根据限定条件获取数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
- (NSArray *)getObjectsWithClass:(Class)clazz
                    conditionKey:(NSString *)conditionKey
                  conditionValue:(NSString *)conditionValue
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath:dbName: 方法");
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz conditionKey:conditionKey conditionValue:conditionValue byCore:self.defaultCore];
}




/// 获取数据表中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
- (NSArray *)getAllObjectsWithClass:(Class)clazz
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath:dbName: 方法");
        return @[];
    }
    
    return [self allObjectsWithClass:clazz byCore:self.defaultCore];
}


/// 删除数据表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名
- (BOOL)removeTable:(NSString *)tableName
{
    if (self.defaultCore == nil) {
        NSLog(@"LH_DBTool 请先调用 startInDBPath:dbName: 方法");
        return NO;
    }
    
    return [self deleteTable:tableName byCore:self.defaultCore];
}





@end
