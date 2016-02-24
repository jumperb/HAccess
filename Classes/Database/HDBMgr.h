//
//  HDBMgr.h
//  HAccess
//
//  Created by zhangchutian on 14-9-17.
//  Copyright (c) 2012年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
#import "HEntity.h"

#define HDBMgrDatasourceRegKey @"HDBMgrDatasourceRegKey"

@protocol HDBMgrDatasource <NSObject>

//what is the default db's name
- (NSString *)defaultDatabaseKey;

//where is the orignal db path
- (NSString *)databasePathInBundleForKey:(NSString *)key;

//where is the setup path
- (NSString *)setupPathForKey:(NSString *)key;

//what is the mapping relation between table name and entity name
- (NSString *)entityClassNameForTable:(NSString *)tableName;

/**
 *  database queue inited
 *  you can do database upgrade there, if the 'isNew' is NO
 *
 *  @param key     name of database
 *  @param dbqueue access queue
 *  @param isNew   is new setup or already exsit
 */
- (void)databaseQueueSetuped:(NSString *)key dbqueue:(FMDatabaseQueue *)dbqueue isNew:(BOOL)isNew;
@end




@interface HDBMgr : NSObject
@property (nonatomic, strong) id<HDBMgrDatasource> datasource;

//singleton
+ (instancetype)shared;

//get entity name by table name
- (NSString *)entityNameWithTableName:(NSString *)tableName;

#pragma mark - queue

+ (FMDatabaseQueue *)queue;

//name: name of db, config in HDBMgrDatasource
+ (FMDatabaseQueue *)queueWithKey:(NSString *)key;


@end


