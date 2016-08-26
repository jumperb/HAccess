//
//  HEntity+Persistence.h
//  HAccess
//
//  Created by zhangchutian on 16/3/18.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HEntity.h"
#import "FMDatabaseQueue.h"
#import "HDatabaseDAO.h"

@interface HEntity (Persistence)

#pragma mark - you can implement

//my table name, default is my class name, you can custom it
+ (NSString *)tableName;

//which db
+ (NSString *)databaseKey;

#pragma mark - create

//save，if entity already exsit, the update
- (BOOL)save;
//keypp: which property is the key, use for check exsit and update
- (BOOL)save:(NSString *)keypp;
//add
- (BOOL)add;
//get last auto increasmented ID
+ (NSString *)lastInsertedID;
//batch add , it will not set value reversed, such as ID, created, modified
+ (BOOL)adds:(NSArray *)entities;


#pragma mark - delete
//delete
- (BOOL)remove;
- (BOOL)remove:(NSString *)keyppValue;
//batch delete
+ (BOOL)removes:(NSString *)conditions;


#pragma mark - update
//update
- (BOOL)update;
//keypp: which property is the key, use for check exsit and update
- (BOOL)update:(NSString *)keypp;
//keyppList: which properties are the keys, use for check exsit and update
- (BOOL)update2:(NSArray *)keyppList;

//batch update
+ (BOOL)updates:(NSArray *)entities;
//keyppList: which properties are the keys, use for check exsit and update
+ (BOOL)updates:(NSArray *)entities keyppList:(NSArray *)keyppList;
+ (BOOL)updatesWithSetters:(NSDictionary *)setters conditions:(NSString *)conditions;

#pragma mark - read
//get an entity
+ (HEntity *)get:(NSString *)keyppValue;
//get an entity with conditions, carefully write the quotes
+ (HEntity *)getWithCondition:(NSString *)condition;
//get an entity with conditions, key is the property
+ (HEntity *)getWithCondition2:(NSDictionary *)condition;
//get a a list, carefully write the quotes
+ (NSArray *)list:(NSString *)conditions;
//key is the property
+ (NSArray *)list2:(NSDictionary *)conditions;
//query count
+ (long)count:(NSString *)conditions;
+ (long)count2:(NSDictionary *)conditions;


@end
