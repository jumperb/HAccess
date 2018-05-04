//
//  HDatabaseDAO.h
//  HodorMVC
//
//  Created by zhangchutian on 12-10-23.
//  Copyright (c) 2012年 zhangchutian. All rights reserved.

//@convention every database table must has three fields: id(INTEGER) created(INTEGER) modified(INTEGER)
//@convention the 'id' field must be auto increasing

#import <Foundation/Foundation.h>
#import "HDBMgr.h"
#import "HEntity.h"


/**
 * this is the base class of 'data access operation' of database
 */
@interface HDatabaseDAO : NSObject
{
    FMDatabaseQueue *queue;
    //current data base connection
    FMDatabase *currentDB;
}
//if this dao is apply to a single table, please set this tableName, then u can use these quick method
@property (nonatomic, readonly) NSString *tableName;
@property (nonatomic, readonly) NSString *databaseKey;
/**
 *  init access queue, u can rewrite it to access other db if you have one more db
 */
- (void)setupQueue;

/**
 *  set the dao already in queue, then when you invoke quick method it will excute without queue block
 *  if you are already in queue, doing some search operation then you want invoke other method for some data, then you will be deadlocked， but you could use this method to resolve the problem
 *  note that : don't invoke this method outside queue block
 *
 *  @return self
 */
- (instancetype)alreadyInQueue;
- (instancetype)alreadyInQueue:(FMDatabase *)db;


/**
 *  warping FMDB queue methods
 *  please use these methods to excute the block of code in queue, not use FMDB method directly.
 *  then alreadyInQueue method take effect
 *  @param block
 */
- (void)inDatabase:(void (^)(FMDatabase *db))block;
- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;
- (void)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

#pragma mark quick methods
//note: if you are operating mass of data, you can write sql manual, it could be more quickly

#pragma mark - create

//save，if entity already exsit, the update
- (BOOL)save:(HEntity *)entity;
//keypp: which property is the key, use for check exsit and update
- (BOOL)save:(HEntity *)entity keypp:(NSString *)keypp;
//add
- (BOOL)add:(HEntity *)entity;
//get last auto increasmented ID
- (NSString *)lastInsertedID;
//batch add , it will not set value reversed, such as ID, created, modified
- (BOOL)adds:(NSArray *)entities;

#pragma mark add index
- (BOOL)addIndex:(NSString *)conditions;

#pragma mark - delete
//delete
- (BOOL)remove:(NSString *)keyppValue;
//batch delete
- (BOOL)removes:(NSString *)conditions;


#pragma mark - update
//update
- (BOOL)update:(HEntity *)entity;
//keypp: which property is the key, use for check exsit and update
- (BOOL)update:(HEntity *)entity keypp:(NSString *)keypp;
//keyppList: which properties are the keys, use for check exsit and update
- (BOOL)update:(HEntity *)entity keyppList:(NSArray *)keyppList;

//batch update
- (BOOL)updates:(NSArray *)entities;
//keyppList: which properties are the keys, use for check exsit and update
- (BOOL)updates:(NSArray *)entities keyppList:(NSArray *)keyppList;
- (BOOL)updatesWithSetters:(NSDictionary *)setters conditions:(NSString *)conditions;

#pragma mark - read
//get an entity
- (HEntity *)get:(NSString *)keyppValue;
//get an entity with conditions, carefully write the quotes
- (HEntity *)getWithCondition:(NSString *)condition;
//get an entity with conditions, key is the property
- (HEntity *)getWithCondition2:(NSDictionary *)condition;
//get a a list, carefully write the quotes
- (NSArray *)list:(NSString *)conditions;
//key is the property
- (NSArray *)list2:(NSDictionary *)conditions;
//query count
- (long)count:(NSString *)conditions;
- (long)count2:(NSDictionary *)conditions;


#pragma mark - other
//get last auto ID
- (NSString *)lastInsertedIDOfTable:(NSString *)tableName;

//get a auto ID， this ID is not generate by DB, and it is distinctly
+ (NSString *)AutoIDForDomain:(NSString *)domainName;

//auto add quotes
+ (NSString *)cleanValue:(NSString *)value;

/**
 *  init with dbkey and tableName, but most times u just use init without params
 *
 *  @param dbkey: which db
 *  @param tableName: which table
 *
 *  @return
 */
- (instancetype)initWithDbKey:(NSString *)dbkey tableName:(NSString *)tableName;
@end


//ignore property in DB
#define HPIgnoreInDB @"ignoreInDB"

@interface HEntity (DBExtend)

//set data with query result
- (void)setWithResultSet:(FMResultSet*)result;

@end
