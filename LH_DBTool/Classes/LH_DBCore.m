//
//  LH_DBCore.m
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import "LH_DBCore.h"
#import "LH_DBObjectProtocol.h"
#import <fmdb/FMDB.h>
#import <YYModel/YYModel.h>

static NSString *const LH_DBModelColumnName = @"LH_ModelColumn";
static NSString *const LH_DBModelColumnType = @"blob";

@interface LH_DBCore ()
{
    BOOL _isExist;
}

@property (nonatomic, copy  , nullable) NSString * dbFile;

@property (nonatomic, strong) NSArray * sqliteReservedWords;

@end

@implementation LH_DBCore

- (instancetype)initWithDBPath:(NSString*)dbPath
{
    if (self = [super init]) {
        self.dbFile = dbPath;
        self.sqliteReservedWords = [LH_DBCore getSQLiteReservedWords];
        [self connect];
        self.dbQueue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
        NSLog(@"DBFile:%@", self.dbFile);
    }
    return self;
}

- (void)dealloc
{
    [self close];
    self.dbFile = nil;
    self.dbQueue = nil;
}

#pragma mark - public Method

-(BOOL)isDbFileExist
{
    BOOL result = _isExist;
    if (_isExist) {
        _isExist = NO;
    }
    return result;
}

#pragma mark - private Method

- (void)close
{
    [_dataBase close];
    _dataBase = nil;
}

- (void)connect
{
    if (!_dataBase) {
        _dataBase = [FMDatabase databaseWithPath:self.dbFile];
    }
    if (![_dataBase open]) {
        NSAssert(NO, @"can not open db file");
    } else {
        _isExist = YES;
    }
}


#pragma mark - table check
- (void)tableCheck:(id<LH_DBObjectProtocol, YYModel>)data_obj
{
    NSString* tableName = NSStringFromClass([data_obj class]);
    Class objClass = [data_obj class];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        // 表是否存在
        NSString* sql = [NSString stringWithFormat:@"select count(*) from sqlite_master where type='table' and name='%@'", tableName];
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:@[]];
        
        while ([rs next]) {
            if ([rs intForColumnIndex:0] == 0) {
                NSArray *property_name_array = [data_obj LH_Primarykey];
                NSArray *searchKeys = [data_obj LH_SearchKey];
                [self createTable:db table_name:tableName primaryKey:property_name_array searchKey:searchKeys objClass:objClass];
                [rs close];
                return ;
            }
        }
        [rs close];
    }];
}

#pragma mark - table Create Method
- (void)createTable:(FMDatabase *)db
         table_name:(NSString *)table_name
         primaryKey:(NSArray<NSString *> *)primaryKey
          searchKey:(NSArray<NSString *> *)searchKey
           objClass:(Class)objClass
{
    if (primaryKey.count > 1) {
        [self createTableMutablePK:db table_name:table_name primaryKey:primaryKey searchKey:searchKey objClass:objClass];
    } else {
        [self createTableSingleKey:db table_name:table_name primaryKey:primaryKey.firstObject searchKey:searchKey objClass:objClass];
    }
}

- (void)createTableMutablePK:(FMDatabase *)db
                  table_name:(NSString *)table_name
                  primaryKey:(NSArray<NSString *> *)primaryKeyArr
                   searchKey:(NSArray<NSString *> *)searchKey
                    objClass:(Class)objClass
{
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (", table_name];
    
    NSMutableArray *keys = [NSMutableArray arrayWithArray:searchKey];
    [keys addObjectsFromArray:primaryKeyArr];
    
    for (NSString* property_name in keys) {
        objc_property_t objProperty = class_getProperty(objClass, [property_name UTF8String]);
        NSString *propertyType = [self getSqlKindbyProperty:objProperty];
        NSString *propertyname = [self processReservedWord:property_name];
        NSString *propertyStr = [NSString stringWithFormat:@"%@ %@, ", propertyname, propertyType];
        [sql appendString:propertyStr];
    }
    
    [sql appendFormat:@"%@ %@, ", LH_DBModelColumnName, LH_DBModelColumnType];
    
    [sql appendFormat:@"CONSTRAINT pk_id PRIMARY KEY ("];
    for (NSString *key in primaryKeyArr) {
        NSString * keyname = [self processReservedWord:key];
        [sql appendString:keyname];
        if (key != primaryKeyArr.lastObject) {
            [sql appendString:@", "];
        }
    }
    [sql appendString:@"))"];
    
    [db executeUpdate:sql];
}


- (void)createTableSingleKey:(FMDatabase *)db
                  table_name:(NSString *)table_name
                  primaryKey:(NSString *)primaryKey
                   searchKey:(NSArray<NSString *> *)searchKey
                    objClass:(Class)objClass
{
    objc_property_t objProperty = class_getProperty(objClass, [primaryKey UTF8String]);
    NSString *propertyType = [self getSqlKindbyProperty:objProperty];
    NSString *propertyname = [self processReservedWord:primaryKey];
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (%@ %@ primary key, %@ %@, ", table_name, propertyname, propertyType, LH_DBModelColumnName, LH_DBModelColumnType];
    
    for (NSString* property_name in searchKey) {
        objc_property_t objProperty = class_getProperty(objClass, [property_name UTF8String]);
        NSString *propertyType = [self getSqlKindbyProperty:objProperty];
        NSString *propertyname = [self processReservedWord:property_name];
        NSString *propertyStr = [NSString stringWithFormat:@"%@ %@, ", propertyname, propertyType];
        [sql appendString:propertyStr];
    }
    
    [sql deleteCharactersInRange:NSMakeRange([sql length] - 2, 2)];
    [sql appendString:@")"];
    
    [db executeUpdate:sql];
}


#pragma mark - insert record Method
- (NSString *)getInsertRecordQuery:(id<LH_DBObjectProtocol, YYModel>)dataObject
{
    NSString *table_name = NSStringFromClass([dataObject class]);
    NSObject *data_obj = dataObject;
    
    NSMutableArray *fileds = [NSMutableArray array];
    [fileds addObject:LH_DBModelColumnName];
    [fileds addObjectsFromArray:[dataObject LH_Primarykey]];
    [fileds addObjectsFromArray:[dataObject LH_SearchKey]];
    
    NSMutableString *query = [[NSMutableString alloc] initWithFormat:@"insert or replace into %@ (", table_name];
    NSMutableString *values = [[NSMutableString alloc] initWithString:@") values ("];
    
    for (NSString *property_name in fileds) {
        //sqlite 关键字过滤
        NSString * propertyname = [self processReservedWord:property_name];
        NSString * property_key  = [NSString stringWithFormat:@"%@,", propertyname];
        [query appendString:property_key];
        
        NSString *property_value = nil;
        if ([property_name isEqualToString:LH_DBModelColumnName]) {
            NSString *jsonStr = [data_obj yy_modelToJSONString];
            property_value = [NSString stringWithFormat:@"'%@',", jsonStr];
        }
        else {
            objc_property_t property = class_getProperty([data_obj class], property_name.UTF8String);
            NSString *type = [self getSqlKindbyProperty:property];
            if ([type isEqualToString:@"integer"] ||
                [type isEqualToString:@"bool"] ||
                [type isEqualToString:@"real"]) {
                property_value = [NSString stringWithFormat:@"%@,", [[data_obj valueForKey:property_name] stringValue]];
            }
            else {
                NSString *value = [data_obj valueForKey:property_name];
                property_value = [NSString stringWithFormat:@"'%@',", value];
            }
        }
        
        [values appendString:property_value];
    }
    
    if ([query hasSuffix:@","]) {
        [query deleteCharactersInRange:NSMakeRange([query length] - 1, 1)];
    }
    
    if ([values hasSuffix:@","]) {
        [values deleteCharactersInRange:NSMakeRange([values length] - 1, 1)];
    }
    
    [values appendString:@")"];
    
    [query appendString:values];
    
    return query;
}


- (NSArray*)excuteSql:(NSString*)sql withClass:(Class)clazz
{
    NSMutableArray *models = [NSMutableArray array];
    
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        FMResultSet *rs = [db executeQuery:sql,nil];
        while ([rs next]) {
            NSString *jsonStr = [rs objectForColumn:LH_DBModelColumnName];
            id model = [clazz yy_modelWithJSON:jsonStr];
            [models addObject:model];
        }
        [rs close];
    }];

    return models;
}



- (NSString *)formatDeleteSQLWithObjc:(id<LH_DBObjectProtocol, YYModel>)data_obj
{
    NSMutableString *query = nil;
    
    if (data_obj) {
        NSString *table_name = NSStringFromClass([data_obj class]);
        NSArray *property_name_array = [data_obj LH_Primarykey];
        NSString *condition = nil;
        if (property_name_array.count > 1) {
            condition = [self formatMutableConditionSQLWithObjc:data_obj pkArr:property_name_array];
        } else {
            condition = [self formatSingleConditionSQLWithObjc:data_obj property_name:property_name_array.firstObject];
        }
        
        query = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %@ WHERE %@", table_name, condition];
    }
    
    return query;
}

- (NSString *)formatMutableConditionSQLWithObjc:(id<LH_DBObjectProtocol, YYModel>)data_obj pkArr:(NSArray *)pkArr
{
    NSMutableString *condition = [[NSMutableString alloc] init];
    NSObject *OBJECT = data_obj;
    for (NSString *property_name in pkArr) {
        objc_property_t property = class_getProperty([data_obj class], property_name.UTF8String);
        NSString *proName = [self processReservedWord:property_name];
        if ([[self getSqlKindbyProperty:property] isEqualToString:@"text"]) {
            NSString *value = [NSString stringWithFormat:@"%@" , [OBJECT valueForKey:property_name]];
            [condition appendString:[NSString stringWithFormat:@"%@ = '%@'", proName, value]];
        }
        else {
            [condition appendString:[NSString stringWithFormat:@"%@ = %@", proName, [[OBJECT valueForKey:property_name] stringValue]]];
        }
        
        if (NO == [property_name isEqual:pkArr.lastObject]) {
            [condition appendString:@" AND "];
        }
    }
    
    return condition;
}

- (NSString *)formatSingleConditionSQLWithObjc:(id<LH_DBObjectProtocol, YYModel>)data_obj property_name:(NSString *)property_name
{
    NSObject *OBJECT = data_obj;
    NSString* condition = nil;
    objc_property_t property = class_getProperty([data_obj class], property_name.UTF8String);
    NSString *proName = [self processReservedWord:property_name];
    if ([[self getSqlKindbyProperty:property] isEqualToString:@"text"]) {
        NSString* value = [NSString stringWithFormat:@"%@" , [OBJECT valueForKey:property_name]];
        condition = [NSString stringWithFormat:@"%@='%@',", proName, value];
    } else {
        condition = [NSString stringWithFormat:@"%@=%@,", proName, [[OBJECT valueForKey:property_name] stringValue]];
    }
    if ([condition hasSuffix:@","]) {
        NSMutableString *mutableString = [NSMutableString stringWithString:condition];
        [mutableString replaceCharactersInRange:NSMakeRange(mutableString.length - 1, 1) withString:@""];
        condition = mutableString;
    }
    
    return condition;
}




#pragma mark - help Method
/// condition -> string
- (NSString *)formatCondition:(NSDictionary<NSString *, NSString *> *)condition
                    WithClass:(Class<LH_DBObjectProtocol, YYModel>)clazz
{
    NSString *tableName = NSStringFromClass(clazz);
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select * from %s", [tableName UTF8String]];
    if (condition.count > 0) {
        [sql appendString:@" where "];
        [condition enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *column = [self processReservedWord:key];
            objc_property_t property = class_getProperty(clazz, key.UTF8String);
            NSString *str = nil;
            if ([[self getSqlKindbyProperty:property] isEqualToString:@"text"]) {
                str = [NSString stringWithFormat:@"%@ = '%@' and ", column, obj];
            } else {
                str = [NSString stringWithFormat:@"%@ = %@ and ", column, obj];
            }
            
            [sql appendString:str];
        }];
        
        if ([sql hasSuffix:@"and "]) {
            [sql replaceCharactersInRange:NSMakeRange(sql.length - 4, 4) withString:@""];
        }
    }

    return sql;
}




//    @"f":@"float",
//    @"i":@"int",
//    @"d":@"double",
//    @"l":@"long",
//    @"c":@"BOOL",
//    @"s":@"short",
//    @"q":@"long, NSInteger",
//    @"I":@"NSInteger",
//    @"Q":@"NSUInteger",
//    @"B":@"BOOL",
//    @"@":@"id"
- (NSString*)getSqlKindbyProperty:(objc_property_t)property
{
    NSString *firstType = [self getPropertySign:property];

    if ([firstType isEqualToString:@"i"] ||
        [firstType isEqualToString:@"q"]) {
        return @"integer";
    } else if ([firstType isEqualToString:@"f"]) {
        return @"real";
    } else if([firstType isEqualToString:@"d"]){
        return @"real";
    } else if([firstType isEqualToString:@"l"]){
        return @"real";
    } else if([firstType isEqualToString:@"c"] || [firstType isEqualToString:@"B"]){
        return @"bool";
    } else if([firstType isEqualToString:@"s"]){
        return @"integer";
    } else if([firstType isEqualToString:@"I"]){
        return @"integer";
    } else if([firstType isEqualToString:@"Q"]){
        return @"integer";
    } else if([firstType isEqualToString:@"@\"NSData\""]){
        return @"text";
    } else if([firstType isEqualToString:@"@\"NSDate\""]){
        return @"text";
    } else if([firstType isEqualToString:@"@\"NSString\""]){
        return @"text";
    } else if([firstType isEqualToString:@"@"]){
        return @"text";
    } else {
        return @"text";
    }
    return nil;
}

- (NSString*)getPropertySign:(objc_property_t)property
{
    return [[[[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","] firstObject] substringFromIndex:1];
}

- (NSString*)processReservedWord:(NSString*)property_key
{
    NSString *str = property_key;
    if ([self.sqliteReservedWords containsObject:[str uppercaseString]]) {
        str = [NSString stringWithFormat:@"[%@]",property_key];
    }
    return str;
}




/**
 获取sqlite 保留字段集合
 
 @return NSArray
 */
+ (NSArray * )getSQLiteReservedWords
{
    return @[@"ABORT",
             @"ACTION" ,
             @"ADD" ,
             @"AFTER",
             @"ALL",
             @"ALTER",
             @"ANALYZE",
             @"AND",
             @"AS",
             @"ASC",
             @"ATTACH",
             @"AUTOINCREMENT",
             @"BEFORE",
             @"BEGIN"  ,
             @"BETWEEN"  ,
             @"BY"   ,
             @"CASCADE" ,
             @"CASE"    ,
             @"CAST"     ,
             @"CHECK"     ,
             @"COLLATE"     ,
             @"COLUMN"     ,
             @"COMMIT"     ,
             @"CONFLICT"     ,
             @"CONSTRAINT"     ,
             @"CREATE"     ,
             @"CROSS"     ,
             @"CURRENT_DATE"     ,
             @"CURRENT_TIME"     ,
             @"CURRENT_TIMESTAMP"     ,
             @"DATABASE"     ,
             @"DEFAULT"     ,
             @"DEFERRABLE"     ,
             @"DEFERRED"     ,
             @"DELETE"     ,
             @"DESC"     ,
             @"DETACH"     ,
             @"DISTINCT"     ,
             @"DROP"     ,
             @"EACH"     ,
             @"ELSE"     ,
             @"END"     ,
             @"ESCAPE"     ,
             @"EXCEPT"     ,
             @"EXCLUSIVE"     ,
             @"EXISTS"     ,
             @"EXPLAIN"     ,
             @"FAIL"     ,
             @"FOR"     ,
             @"FOREIGN"     ,
             @"FROM"     ,
             @"FULL"     ,
             @"GLOB"     ,
             @"GROUP"     ,
             @"HAVING"     ,
             @"IF"     ,
             @"IGNORE"     ,
             @"IMMEDIATE"     ,
             @"IN"     ,
             @"INDEX"     ,
             @"INDEXED"     ,
             @"INITIALLY"     ,
             @"INNER"     ,
             @"INSERT"     ,
             @"INSTEAD"     ,
             @"INTERSECT"     ,
             @"INTO"     ,
             @"IS"     ,
             @"ISNULL"     ,
             @"JOIN"     ,
             @"KEY"     ,
             @"LEFT"     ,
             @"LIKE"     ,
             @"LIMIT"     ,
             @"MATCH"     ,
             @"NATURAL"     ,
             @"NO"     ,
             @"NOT"     ,
             @"NOTNULL"     ,
             @"NULL"     ,
             @"OF"     ,
             @"OFFSET"     ,
             @"ON"     ,
             @"OR"     ,
             @"ORDER"     ,
             @"OUTER"     ,
             @"PLAN"     ,
             @"PRAGMA"     ,
             @"PRIMARY"     ,
             @"QUERY"     ,
             @"RAISE"     ,
             @"RECURSIVE"     ,
             @"REFERENCES"     ,
             @"REGEXP"     ,
             @"REINDEX"     ,
             @"RELEASE"     ,
             @"RENAME"     ,
             @"REPLACE"     ,
             @"RESTRICT"     ,
             @"RIGHT"     ,
             @"TO"    ,
             @"ROLLBACK"    ,
             @"SAVEPOINT"    ,
             @"SELECT"    ,
             @"SET"    ,
             @"TABLE"    ,
             @"TEMP"    ,
             @"TEMPORARY"    ,
             @"THEN",
             @"TRANSACTION",
             @"TRIGGER",
             @"UNION" ,
             @"UNIQUE",
             @"UPDATE",
             @"USING",
             @"VACUUM",
             @"VALUES",
             @"VIEW",
             @"VIRTUAL" ,
             @"WHEN" ,
             @"WHERE",
             @"WITH",
             @"WITHOU",];
}

@end
