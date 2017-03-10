//
//  HDBMgr.m
//  HAccess
//
//  Created by zhangchutian on 14-9-17.
//  Copyright (c) 2012年 zhangchutian. All rights reserved.
//

#import "HDBMgr.h"
#import <Hodor/HClassManager.h>
#import <Hodor/HGCDext.h>

@interface HDBMgr ()
@property (nonatomic, strong) FMDatabaseQueue *defaultQueue;
@property (nonatomic, strong) NSMutableDictionary *queuesDict;
@property (nonatomic, strong) NSMutableDictionary *tableToEntityClassNameCache;
@property (nonatomic, strong) dispatch_queue_t operateQueue;
@end

@implementation HDBMgr


#pragma mark - init, dealloc
+ (instancetype)shared
{
    static dispatch_once_t pred;
    static HDBMgr *o = nil;

    dispatch_once(&pred, ^{ o = [[self alloc] init]; });
    return o;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _queuesDict = [[NSMutableDictionary alloc] init];
        _tableToEntityClassNameCache = [[NSMutableDictionary alloc] init];
        _operateQueue = dispatch_queue_create("HDBMgr", 0);
    }
    return self;
}
#pragma mark - queue

+ (FMDatabaseQueue *)queue
{
    return [[HDBMgr shared] defaultQueue];
}


+ (FMDatabaseQueue *)queueWithKey:(NSString *)key
{
    return [[HDBMgr shared] queueWithKey:key];
}

- (FMDatabaseQueue *)queueWithKey:(NSString *)key
{
    __block FMDatabaseQueue *res = nil;
    dispatch_sync(self.operateQueue, ^{
        FMDatabaseQueue *queue = _queuesDict[key];
        if (!queue)
        {
            //create
            queue = [self queueInitWithKey:key];
        }
        res = queue;
    });
    return res;
}

//close queue
+ (void)closeQueue:(NSString *)key
{
    dispatch_sync([HDBMgr shared].operateQueue, ^{
        FMDatabaseQueue *queue = [HDBMgr shared].queuesDict[key];
        [queue close];
        [[HDBMgr shared].queuesDict removeObjectForKey:key];
    });
}
+ (void)closeAllQueue
{
    dispatch_sync([HDBMgr shared].operateQueue, ^{
        for (NSString *key in [HDBMgr shared].queuesDict)
        {
            FMDatabaseQueue *queue = [HDBMgr shared].queuesDict[key];
            [queue close];
        }
        [[HDBMgr shared].queuesDict removeAllObjects];
    });
}
//reload queue
+ (void)reloadQueue:(NSString *)key
{
    [self closeQueue:key];
}
+ (void)reloadAllQueue
{
    [self closeAllQueue];
}
#pragma mark - db connect
- (id<HDBMgrDatasource>)getDBSourceWithKey:(NSString *)key
{
    __block id<HDBMgrDatasource> dataSource = nil;
    [HClassManager scanClassForKey:HDBMgrDatasourceRegKey fetchblock:^(__unsafe_unretained Class aclass, id userInfo) {
        if ([userInfo isEqualToString:key])
        {
            dataSource = (id<HDBMgrDatasource>) [aclass new];
        }
    }];
    if (!dataSource)
    {
        NSAssert(NO, @"must give me a db source 'HDBMgrDatasource'");
        abort();
    }
    if (![dataSource conformsToProtocol:@protocol(HDBMgrDatasource)])
    {
        NSAssert(NO, @"%@ must conform HDBMgrDatasource", NSStringFromClass([dataSource class]));
        abort();
    }
    return dataSource;
}
//init db file: unzip db to target directory
- (FMDatabaseQueue *)queueInitWithKey:(NSString *)key
{
    id<HDBMgrDatasource> dataSource = [self getDBSourceWithKey:key];
    
    NSString *setupPath =[dataSource setupPath];
    if (!setupPath)
    {
        NSAssert(NO, @"%@ db setup path is not exist",key);
        abort();
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL find = [fileManager fileExistsAtPath:setupPath];
    if (!find) {

        NSString *sourcePath = [dataSource databasePathInBundle];
        [self safeCopyItemAtPath:sourcePath toPath:setupPath atomically:YES isOverwrite:YES error:nil];
    }
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:setupPath];
    if (!dbQueue)
    {
        return nil;
    }
    [_queuesDict setObject:dbQueue forKey:key];
    if ([dataSource respondsToSelector:@selector(databaseQueueSetupedAtDBQueue:isNew:)])
    {
        [dataSource databaseQueueSetupedAtDBQueue:dbQueue isNew:!find];
    }
    return dbQueue;
}
- (NSString *)entityClassNameForTable:(NSString *)tableName dbkey:(NSString *)dbkey
{
    __block NSString *entityClassName = nil;
    syncAtQueue(self.operateQueue, ^{
        id<HDBMgrDatasource> dataSource = [self getDBSourceWithKey:dbkey];
        entityClassName = _tableToEntityClassNameCache[tableName];
        if (!entityClassName)
        {
            entityClassName = [dataSource entityClassNameForTable:tableName];
            [_tableToEntityClassNameCache setObject:entityClassName forKey:tableName];
        }
    });
    return entityClassName;
}
#pragma mark - helper method
- (BOOL)safeCopyItemAtPath:(NSString *)srcPath
                toPath:(NSString *)dstPath
            atomically:(BOOL)atomically
           isOverwrite:(BOOL)overwrite
                 error:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!srcPath || !dstPath)
    {
        return NO;
    }
    
    if (!atomically)
    {
        return [fileManager copyItemAtPath:srcPath toPath:dstPath error:error];
    }
    NSString *dstPathTemp = [dstPath stringByAppendingString:@".temp"];
    //1.delete temp file/dir
    [fileManager removeItemAtPath:dstPathTemp error:nil];
    //2.copy to temp dile/dir
    BOOL res = [fileManager copyItemAtPath:srcPath toPath:dstPathTemp error:error];
    if (!res)
    {
        //copy error, delete temp file/dir
        [fileManager removeItemAtPath:dstPathTemp error:nil];
        return res;
    }
    //3.rename
    if (overwrite)
    {
        if ([fileManager fileExistsAtPath:dstPath])
        {
            [fileManager removeItemAtPath:dstPath error:nil];
        }
    }
    return [fileManager moveItemAtPath:dstPathTemp toPath:dstPath error:error];
}

@end
