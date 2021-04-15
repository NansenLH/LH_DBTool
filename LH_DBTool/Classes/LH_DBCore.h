//
//  LH_DBCore.h
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import "LH_DBObjectProtocol.h"
#import <YYModel/YYModel.h>

@class FMDatabaseQueue, FMDatabase;

NS_ASSUME_NONNULL_BEGIN

@interface LH_DBCore : NSObject

@property (nonatomic, strong, readonly) FMDatabase * dataBase;

@property (nonatomic, strong, nullable) FMDatabaseQueue *dbQueue;

- (instancetype)initWithDBPath:(NSString*)dbPath;

#pragma mark - table check
- (void)tableCheck:(id<LH_DBObjectProtocol, YYModel>)dataObject;

#pragma mark - insert record Method
- (NSString *)getInsertRecordQuery:(id<LH_DBObjectProtocol, YYModel>)dataObject;

#pragma mark - excuteSql Method
- (NSArray*)excuteSql:(NSString*)sql withClass:(Class)clazz;

#pragma mark - SQL format Method
- (NSString *)formatDeleteSQLWithObjc:(id<LH_DBObjectProtocol, YYModel>)data_obj;

#pragma mark - help Method
- (NSString *)formatCondition:(NSDictionary<NSString *, NSString *> *)condition
                    WithClass:(Class<LH_DBObjectProtocol, YYModel>)clazz;

@end

NS_ASSUME_NONNULL_END
