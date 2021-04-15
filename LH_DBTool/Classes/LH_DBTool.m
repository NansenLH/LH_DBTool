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

@property (nonatomic, strong) LH_DBCore *database;

@end


@implementation LH_DBTool

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



/// 初始化数据库
/// @param dbPath 数据库沙盒路径
/// @param dbName 数据库名称 xxx.db
- (void)startWithDBPath:(NSString *)dbPath
                 dbName:(NSString *)dbName
{
    if (self.database) {
        self.database = nil;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dbPath] == NO) {
        [fm createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *db = [dbPath stringByAppendingPathComponent:dbName];
    self.database = [[LH_DBCore alloc] initWithDBPath:db];
    NSLog(@"初始化数据库");
}


#pragma mark - ======== 增,删,改,查 ========
/// 往数据库中增加或者更新一条数据<不开启事务>
/// @param obj 遵循<LH_DBObjectProtocol, YYModel>的对象
- (BOOL)addObject:(id<LH_DBObjectProtocol, YYModel>)obj
{
    if (!obj) {
        NSLog(@"Warning: addObject -> 参数不对");
        return NO;
    }
    
    return [self addObjectsInTransaction:@[obj]];
}

/// 往数据库中增加或者更新一组数据,开始事务
/// @param objs 遵循<LH_DBObjectProtocol, YYModel>的一组对象
- (BOOL)addObjectsInTransaction:(NSArray<id<LH_DBObjectProtocol, YYModel>> *)objs
{
    if (objs == nil || objs.count == 0) {
        NSLog(@"Warning: addObjectsInTransaction -> 参数不对");
        return NO;
    }
    
    for (id<LH_DBObjectProtocol, YYModel> obj in objs) {
        [self.database tableCheck:obj];
    }
    
    __block NSMutableArray *array = [NSMutableArray array];
    [self.database.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (id<LH_DBObjectProtocol, YYModel> obj in objs) {
            NSString *query = [self.database getInsertRecordQuery:obj];
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

/// 从数据库中删除一条(组)数据
/// @param obj 遵循<LH_DBObjectProtocol, YYModel>的对象
- (BOOL)deleteObject:(id<LH_DBObjectProtocol, YYModel>)obj
{
    if (obj == nil) {
        NSLog(@"Warning: deleteObject -> 参数不对");
        return NO;
    }
    
    [self.database tableCheck:obj];
    
    return [self deleteObjects:@[obj]];
}

- (BOOL)deleteObjects:(NSArray<id<LH_DBObjectProtocol, YYModel>> *)objs
{
    for (id<LH_DBObjectProtocol, YYModel> obj in objs) {
        [self.database tableCheck:obj];
    }
    
    __block BOOL isSuccess = NO;
    [self.database.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [objs enumerateObjectsUsingBlock:^(id<LH_DBObjectProtocol,YYModel>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *query = [self.database formatDeleteSQLWithObjc:obj];
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
/// @param clazz 遵循<LH_DBObjectProtocol, YYModel>的类
/// @param condition 条件:<主键属性, 条件值>的字典.  key 必须是 <LH_DBObjectProtocol> 中 LH_Primarykey和LH_SearchKey包含的属性
- (NSArray *)getObjectsWithClass:(Class)clazz
                       condition:(NSDictionary<NSString *, NSString *> *)condition
{
    NSObject<LH_DBObjectProtocol> *obj = [[clazz alloc] init];
    if ([obj respondsToSelector:@selector(LH_Primarykey)] == NO) {
        NSLog(@"Warning: 条件查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    
    [self.database tableCheck:obj];
    
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
    
    
    NSString *sql = [self.database formatCondition:condition WithClass:clazz];
    return [self.database excuteSql:sql withClass:clazz];
}

/// 获取数据表中的全部数据
/// @param clazz 遵循<LH_DBObjectProtocol, YYModel>的类
- (NSArray *)getAllObjectsWithClass:(Class)clazz
{
    NSObject<LH_DBObjectProtocol> *obj = [[clazz alloc] init];
    if ([obj respondsToSelector:@selector(LH_Primarykey)] == NO) {
        NSLog(@"Warning: 全部查询 -> %@ 未遵循<LH_DBObjectProtocol>", NSStringFromClass(clazz));
        return @[];
    }
    [self.database tableCheck:obj];
    
    NSString *tableName = NSStringFromClass(clazz);
    NSString *sql = [NSString stringWithFormat:@"select * from %s", [tableName UTF8String]];
    return [self.database excuteSql:sql withClass:clazz];
}


/// 删除数据表
/// @param tableName 遵循<LH_DBObjectProtocol, YYModel>的类名
- (BOOL)removeTable:(NSString *)tableName
{
    __block BOOL tf = NO;
    NSString *sql = [@"DROP TABLE " stringByAppendingString:tableName];
    tf = [self.database.dataBase executeUpdate:sql,nil];
    return tf;
}





@end
