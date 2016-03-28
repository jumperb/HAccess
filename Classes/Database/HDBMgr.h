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


// database config , one or more config could exsit in project
@protocol HDBMgrDatasource <NSObject>

//where is the orignal db path
- (NSString *)databasePathInBundle;

//where is the setup path
- (NSString *)setupPath;

//what is the mapping relation between table name and entity name
- (NSString *)entityClassNameForTable:(NSString *)tableName;
@optional
/**
 *  database queue inited
 *  you can do database upgrade there, if the 'isNew' is NO
 *
 *  @param dbqueue access queue
 *  @param isNew   is new setup or already exsit
 */
- (void)databaseQueueSetupedAtDBQueue:(FMDatabaseQueue *)dbqueue isNew:(BOOL)isNew;
@end




@interface HDBMgr : NSObject

//singleton
+ (instancetype)shared;

//get entity name by table name
- (NSString *)entityClassNameForTable:(NSString *)tableName dbkey:(NSString *)dbkey;

#pragma mark - queue

//+ (FMDatabaseQueue *)queue;

//name: name of db, config in HDBMgrDatasource
+ (FMDatabaseQueue *)queueWithKey:(NSString *)key;


@end


