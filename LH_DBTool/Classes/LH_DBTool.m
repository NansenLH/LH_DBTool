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
         tableName:(NSString *)tableName
{
    [database tableCheck:obj tableName:tableName];
    
    NSString *query = [database getInsertRecordQuery:obj tableName:tableName];
    BOOL isSuccess = [database.dataBase executeUpdate:query, nil];
    return isSuccess;
}

- (BOOL)saveObjects:(NSArray<id<LH_DBObjectProtocol>> *)objs
             byCore:(LH_DBCore *)dataBase
          tableName:(NSString *)tableName
{
    [dataBase tableCheck:objs.firstObject tableName:tableName];
    
    __block NSMutableArray *array = [NSMutableArray array];
    [dataBase.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (id<LH_DBObjectProtocol> obj in objs) {
            NSString *query = [dataBase getInsertRecordQuery:obj tableName:tableName];
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
           tableName:(NSString *)tableName
{
    if (obj == nil) {
        NSLog(@"LH_DBTool Warning: removeObject -> obj=nil");
        return NO;
    }
    
    [dbCore tableCheck:obj tableName:tableName];
    return [self removeObjects:@[obj] byCore:dbCore tableName:tableName];
}

- (BOOL)removeObjects:(NSArray<id<LH_DBObjectProtocol>> *)objs
               byCore:(LH_DBCore *)dbCore
            tableName:(NSString *)tableName
{
    [dbCore tableCheck:objs.firstObject tableName:tableName];
    
    __block BOOL isSuccess = NO;
    [dbCore.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [objs enumerateObjectsUsingBlock:^(id<LH_DBObjectProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *query = [dbCore formatDeleteSQLWithObjc:obj tableName:tableName];
            isSuccess = [db executeUpdate:query, nil];
            if (!isSuccess) {
                NSObject *deleteObjc = obj;
                NSLog(@"LH_DBTool Warning: deleteObject failed -> obj = %@", [deleteObjc yy_modelDescription]);
                *rollback = YES;
            }
        }];
    }];
    return isSuccess;
}

- (BOOL)removeAllObjects:(Class)clazz
                  byCore:(LH_DBCore *)dbCore
               tableName:(NSString *)tableName
{
    id<LH_DBObjectProtocol> obj = [clazz new];
    [dbCore tableCheck:obj tableName:tableName];
    
    NSString *query = [dbCore formatDeleteAllSQLWithTableName:tableName];
    return [dbCore.dataBase executeUpdate:query, nil];
}


/// 根据条件获取对应的数据
- (NSArray *)searchObjectsWithClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition
                             byCore:(LH_DBCore *)dbCore
                          tableName:(NSString *)tableName
{
    if (class_conformsToProtocol(clazz, @protocol(LH_DBObjectProtocol)) == NO) {
        NSLog(@"LH_DBTool Warning: 条件查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    
    id<LH_DBObjectProtocol> obj = [clazz new];
    
    [dbCore tableCheck:obj tableName:tableName];
    
    NSMutableArray *availableProperties = [NSMutableArray array];
    [availableProperties addObjectsFromArray:[obj LH_Primarykey]];
    [availableProperties addObjectsFromArray:[obj LH_SearchKey]];
    
    BOOL isOkey = YES;
    for (NSString *key in condition.allKeys) {
        if ([availableProperties containsObject:key] == NO) {
            NSLog(@"LH_DBTool Warning: 条件查询 -> key=%@ 不合法", key);
            isOkey = NO;
        }
    }
    if (isOkey == NO) {
        return @[];
    }
    
    NSString *sql = [dbCore formatCondition:condition WithClass:clazz tableName:tableName];
    return [dbCore excuteSql:sql withClass:clazz];
}

/// 根据限定条件获取数据
- (NSArray *)searchObjectsWithClass:(Class)clazz
                       conditionKey:(NSString *)conditionKey
                     conditionValue:(NSString *)conditionValue
                             byCore:(LH_DBCore *)dbCore
                          tableName:(NSString *)tableName
{
    if (class_conformsToProtocol(clazz, @protocol(LH_DBObjectProtocol)) == NO) {
        NSLog(@"LH_DBTool Warning: 条件查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    
    id<LH_DBObjectProtocol> obj = [clazz new];
    
    [dbCore tableCheck:obj tableName:tableName];

    NSMutableArray *availableProperties = [NSMutableArray array];
    [availableProperties addObjectsFromArray:[obj LH_Primarykey]];
    [availableProperties addObjectsFromArray:[obj LH_SearchKey]];
    
    if (conditionKey && conditionValue && [availableProperties containsObject:conditionKey]) {
        NSString *sql = [dbCore formatCondition:@{conditionKey : conditionValue} WithClass:clazz tableName:tableName];
        return [dbCore excuteSql:sql withClass:clazz];
    }
    else {
        NSLog(@"LH_DBTool Warning: 条件查询 -> key=%@ 不合法", conditionKey);
        return @[];
    }
}


/// 根据限定条件获取数据
- (NSArray *)searchPageObjectsWithClass:(Class)clazz
                              sortByKey:(NSString *)sortKey
                              ascending:(BOOL)ascending
                              pageIndex:(NSInteger)pageIndex
                               pageSize:(NSInteger)pageSize
                                 byCore:(LH_DBCore *)dbCore
                              tableName:(NSString *)tableName
{
    if (class_conformsToProtocol(clazz, @protocol(LH_DBObjectProtocol)) == NO) {
        NSLog(@"LH_DBTool Warning: 分页查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    
    if (pageIndex < 1) {
        NSLog(@"LH_DBTool Warning: 分页查询 pageIndex[%zd] 参数不合法", pageIndex);
        return @[];
    }
    
    if (pageSize < 1 || pageSize > 100) {
        NSLog(@"LH_DBTool Warning: 分页查询 pageSize[%zd] 参数不合法", pageSize);
        return @[];
    }
    
    id<LH_DBObjectProtocol> obj = [clazz new];
    
    [dbCore tableCheck:obj tableName:tableName];
    
    NSMutableArray *availableProperties = [NSMutableArray array];
    [availableProperties addObjectsFromArray:[obj LH_Primarykey]];
    [availableProperties addObjectsFromArray:[obj LH_SearchKey]];
    
    if ([availableProperties containsObject:sortKey] == NO) {
        NSLog(@"LH_DBTool Warning: 分页查询 -> sortKey=%@ 不合法", sortKey);
        return @[];
    }
    
    NSString *sql = [dbCore pageSearchSQLWithOrderKey:sortKey ascending:ascending pageIndex:pageIndex pageSize:pageSize withClass:clazz tableName:tableName];
    return [dbCore excuteSql:sql withClass:clazz];
}


/// 获取数据表中的全部数据
- (NSArray *)allObjectsWithClass:(Class)clazz
                          byCore:(LH_DBCore *)dbCore
                       tableName:(NSString *)tableName
{
    if (class_conformsToProtocol(clazz, @protocol(LH_DBObjectProtocol)) == NO) {
        NSLog(@"LH_DBTool Warning: 全部查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    
    id<LH_DBObjectProtocol> obj = [clazz new];
    
    [dbCore tableCheck:obj tableName:tableName];
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
    
    _defaultFileName = @"LHDB.db";
    NSString *db = [self.dbPath stringByAppendingPathComponent:_defaultFileName];
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





/// 设置默认的数据库文件名, 不设置,默认为 LHDB.db. 设置之后,所有的默认增删改查都会在新数据库中执行
- (void)setDefaultDBFileName:(NSString *)dbName
{
    if (self.dbPath == nil) {
        NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        return;
    }

    _defaultFileName = [NSString stringWithFormat:@"%@.db", dbName];
    NSString *db = [self.dbPath stringByAppendingPathComponent:_defaultFileName];
    self.defaultCore = [[LH_DBCore alloc] initWithDBPath:db];
}


#pragma mark ---- 增,改 ----
/// 增加或者更新一条数据
/// 默认数据库, 默认使用类名作为表名
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
{
    return [self addObject:obj toCustomTable:nil inDBName:nil];
}

/// 添加或者更新一条数据
/// 默认数据库, 指定表名
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param tableName 指定的表名
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
    toCustomTable:(NSString *)tableName
{
    return [self addObject:obj toCustomTable:tableName inDBName:nil];
}

/// 添加或者更新一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)addObject:(id<LH_DBObjectProtocol>)obj
    toCustomTable:(NSString * _Nullable)tableName
         inDBName:(NSString * _Nullable)dbName
{
    if (obj == nil) {
        NSLog(@"LH_DBTool Error: addObject == nil");
        return NO;
    }
    
    if (tableName == nil) {
        tableName = NSStringFromClass([obj class]);
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return NO;
    }
    
    return [self saveObject:obj byCore:dbCore tableName:tableName];
}


/// 增加或者更新一组数据. 默认数据库, 默认使用类名作为表名
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
- (BOOL)addObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
{
    return [self addObjectArray:objs toCustomTable:nil inDBName:nil];
}

/// 增加或者更新一组数据.
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
/// @param tableName 指定表名
- (BOOL)addObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
         toCustomTable:(NSString *)tableName
{
    return [self addObjectArray:objs toCustomTable:tableName inDBName:nil];
}

/// 增加或者更新一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
/// @param tableName 指定表名, 若为 nil, 则使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)addObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
         toCustomTable:(NSString * _Nullable)tableName
              inDBName:(NSString * _Nullable)dbName
{
    if (objs == nil || objs.count == 0) {
        NSLog(@"LH_DBTool Error: addObjectArray 空数组!");
        return NO;
    }
    
    if (tableName == nil) {
        tableName = NSStringFromClass([objs.firstObject class]);
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return NO;
    }
    
    return [self saveObjects:objs byCore:dbCore tableName:tableName];
}




#pragma mark ---- 删 ----
/// 默认数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
{
    return [self deleteObject:obj fromCustomTable:nil inDBName:nil];
}


/// 数据库中删除一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param tableName 指定表名
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
     fromCustomTable:(NSString *)tableName
{
    return [self deleteObject:obj fromCustomTable:tableName inDBName:nil];
}

/// 从数据库中删除一条数据
/// @param obj 遵循<LH_DBObjectProtocol>的对象
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)deleteObject:(id<LH_DBObjectProtocol>)obj
     fromCustomTable:(NSString * _Nullable)tableName
            inDBName:(NSString * _Nullable)dbName
{
    if (obj == nil) {
        NSLog(@"LH_DBTool Error: deleteObject == nil");
        return NO;
    }
    
    if (tableName == nil) {
        tableName = NSStringFromClass([obj class]);
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return NO;
    }
    
    return [self removeObject:obj byCore:dbCore tableName:tableName];
}



/// 删除一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
- (BOOL)deleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
{
    return [self deleteObjectArray:objs fromCustomTable:nil inDBName:nil];
}


/// 删除一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
/// @param tableName tableName 指定表名
- (BOOL)deleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
          fromCustomTable:(NSString *)tableName
{
    return [self deleteObjectArray:objs fromCustomTable:tableName inDBName:nil];
}

/// 删除一组数据
/// @param objs 遵循<LH_DBObjectProtocol>的同一类的一组对象
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)deleteObjectArray:(NSArray<id<LH_DBObjectProtocol>> *)objs
          fromCustomTable:(NSString * _Nullable)tableName
                 inDBName:(NSString * _Nullable)dbName
{
    if (objs == nil || objs.count == 0) {
        NSLog(@"LH_DBTool Error: deleteArray 为空!");
        return NO;
    }
    
    
    if (tableName == nil) {
        tableName = NSStringFromClass([objs.firstObject class]);
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return NO;
    }
    
    return [self removeObjects:objs byCore:dbCore tableName:tableName];
}


/// 删除指定表中的所有数据
/// @param clazz 遵循<LH_DBObjectProtocol>的对象
- (BOOL)deleteAllObjectsFromClass:(Class)clazz
{
    return [self deleteAllObjectsFromClass:clazz fromCustomTable:nil InDBName:nil];
}

/// 删除指定表中的所有数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param tableName 指定表名
- (BOOL)deleteAllObjectsFromClass:(Class)clazz
                  fromCustomTable:(NSString *)tableName
{
    return [self deleteAllObjectsFromClass:clazz fromCustomTable:tableName InDBName:nil];
}

/// 删除指定表中的所有数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (BOOL)deleteAllObjectsFromClass:(Class)clazz
                  fromCustomTable:(NSString * _Nullable)tableName
                         InDBName:(NSString * _Nullable)dbName
{
    if (tableName == nil) {
        tableName = NSStringFromClass(clazz);
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return NO;
    }
    
    return [self removeAllObjects:clazz byCore:dbCore tableName:tableName];
}


/// 删除指定数据表
/// @param tableName 遵循<LH_DBObjectProtocol>的类名
/// @param dbName 数据库文件名,不用加后缀. 会用该文件名创建 dbName.db 的数据库文件
- (BOOL)removeTable:(NSString *)tableName
           inDBName:(NSString * _Nullable)dbName
{
    if (tableName == nil || tableName.length == 0) {
        NSLog(@"LH_DBTool Error: removeTable -> tableName == nil");
        return NO;
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return NO;
    }
    
    return [self deleteTable:tableName byCore:dbCore];
}

                        
#pragma mark ---- 查 ----
/// 获取默认数据库中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
- (NSArray *)searchAllObjectsFromClass:(Class)clazz
{
    return [self searchAllObjectsFromClass:clazz customTable:nil inDBName:nil];
}

/// 获取全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param tableName 指定表名
- (NSArray *)searchAllObjectsFromClass:(Class)clazz
                           customTable:(NSString *)tableName
{
    return [self searchAllObjectsFromClass:clazz customTable:tableName inDBName:nil];
}

/// 获取全部数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (NSArray *)searchAllObjectsFromClass:(Class)clazz
                           customTable:(NSString * _Nullable)tableName
                              inDBName:(NSString * _Nullable)dbName
{
    if (tableName == nil) {
        tableName = NSStringFromClass(clazz);
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return @[];
    }
    
    return [self allObjectsWithClass:clazz byCore:dbCore tableName:tableName];
}



/// 根据一个限定条件查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
- (NSArray *)searchObjectsFromClass:(Class)clazz
                       conditionKey:(NSString *)conditionKey
                     conditionValue:(NSString *)conditionValue
{
    return [self searchObjectsFromClass:clazz conditionKey:conditionKey conditionValue:conditionValue customTable:nil inDBName:nil];
}

/// 根据一个限定条件查询数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param conditionKey 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param conditionValue 限定值. NSString 类型
/// @param tableName 指定表名
- (NSArray *)searchObjectsFromClass:(Class)clazz
                       conditionKey:(NSString *)conditionKey
                     conditionValue:(NSString *)conditionValue
                        customTable:(NSString *)tableName
{
    return [self searchObjectsFromClass:clazz conditionKey:conditionKey conditionValue:conditionValue customTable:tableName inDBName:nil];
}

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
                           inDBName:(NSString * _Nullable)dbName
{
    if (tableName == nil) {
        tableName = NSStringFromClass(clazz);
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz conditionKey:conditionKey conditionValue:conditionValue byCore:dbCore tableName:tableName];
}



/// 根据条件查询默认数据库中的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition
{
    return [self searchObjectsFromClass:clazz condition:condition tableName:nil inDBName:nil];
}

/// 根据条件查询默认数据库,指定表中的数据
/// @param clazz clazz 遵循<LH_DBObjectProtocol>的类
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param tableName 指定表名
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition
                          tableName:(NSString *)tableName
{
    return [self searchObjectsFromClass:clazz condition:condition tableName:tableName inDBName:nil];
}

/// 根据条件获取对应的数据
/// @param clazz 遵循<LH_DBObjectProtocol>的类
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
/// @param tableName 指定表名,若传 nil,则默认使用类名
/// @param dbName 指定数据库文件名,不用加后缀.会用该文件名创建 dbName.db 的数据库文件. 若为 nil,则默认使用 defaultFileName
- (NSArray *)searchObjectsFromClass:(Class)clazz
                          condition:(NSDictionary<NSString *, NSString *> *)condition
                          tableName:(NSString * _Nullable)tableName
                           inDBName:(NSString * _Nullable)dbName
{
    if (tableName == nil) {
        tableName = NSStringFromClass(clazz);
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return @[];
    }
    
    return [self searchObjectsWithClass:clazz condition:condition byCore:dbCore tableName:tableName];
}



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
                           pageSize:(NSInteger)pageSize
{
    return [self searchObjectsFromClass:clazz sortByKey:sortKey ascending:ascending pageIndex:pageIndex pageSize:pageSize tableName:nil inDBName:nil];
}


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
                          tableName:(NSString *)tableName
{
    return [self searchObjectsFromClass:clazz sortByKey:sortKey ascending:ascending pageIndex:pageIndex pageSize:pageSize tableName:tableName inDBName:nil];
}

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
                           inDBName:(NSString * _Nullable)dbName
{
    if (tableName == nil) {
        tableName = NSStringFromClass(clazz);
    }
    
    LH_DBCore *dbCore = nil;
    if (dbName == nil) {
        dbCore = self.defaultCore;
        if (self.defaultCore == nil) {
            NSLog(@"LH_DBTool Error: 请先调用 startInDBPath: 方法");
        }
    }
    else {
        dbCore = [self getDBCoreByDBName:dbName];
    }

    if (dbCore == nil) {
        return @[];
    }
    
    return [self searchPageObjectsWithClass:clazz sortByKey:sortKey ascending:ascending pageIndex:pageIndex pageSize:pageSize byCore:dbCore tableName:tableName];
}



@end
