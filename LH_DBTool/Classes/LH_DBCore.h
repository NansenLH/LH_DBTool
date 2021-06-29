//
//  LH_DBCore.h
//  podtest
//
//  Created by Nansen on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import "LH_DBObjectProtocol.h"

@class FMDatabaseQueue, FMDatabase;

NS_ASSUME_NONNULL_BEGIN

@interface LH_DBCore : NSObject

@property (nonatomic, strong, readonly) FMDatabase * dataBase;

@property (nonatomic, strong, nullable) FMDatabaseQueue *dbQueue;

- (instancetype)initWithDBPath:(NSString*)dbPath;

#pragma mark - table check
- (void)tableCheck:(id<LH_DBObjectProtocol>)dataObject;

#pragma mark - insert record Method
- (NSString *)getInsertRecordQuery:(id<LH_DBObjectProtocol>)dataObject;

#pragma mark - excuteSql Method
- (NSArray*)excuteSql:(NSString*)sql withClass:(Class)clazz;

#pragma mark - SQL format Method
- (NSString *)formatDeleteAllSQLWithClass:(Class)clazz;
- (NSString *)formatDeleteSQLWithObjc:(id<LH_DBObjectProtocol>)data_obj;

#pragma mark - help Method
- (NSString *)formatCondition:(NSDictionary<NSString *, NSString *> *)condition
                    WithClass:(Class<LH_DBObjectProtocol>)clazz;


- (NSString *)pageSearchSQLWithOrderKey:(NSString *)orderKey
                              ascending:(BOOL)ascending
                              pageIndex:(NSInteger)pageIndex
                               pageSize:(NSInteger)pageSize
                              withClass:(Class<LH_DBObjectProtocol>)clazz;

- (NSString *)pageSearchSQLWithKey1:(NSString *)key1
                      key1Ascending:(BOOL)ascending1
                               key2:(NSString *)key2
                      key2Ascending:(BOOL)ascending2
                          pageIndex:(NSInteger)pageIndex
                           pageSize:(NSInteger)pageSize
                          withClass:(Class<LH_DBObjectProtocol>)clazz;


@end

NS_ASSUME_NONNULL_END
