//
//  HDBMgr.m
//  HAccess
//
//  Created by zhangchutian on 14-9-17.
//  Copyright (c) 2012年 zhangchutian. All rights reserved.
//

#import "HDBMgr.h"
#import <HClassManager.h>

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
        
        NSString *datasourceClassName = [HClassManager getClassNameForKey:HDBMgrDatasourceRegKey];
        NSAssert(datasourceClassName, @"need reg HDBMgrDatasource");
        Class klass = NSClassFromString(datasourceClassName);
        NSAssert(klass, @"need reg HDBMgrDatasource");
        id obj = [[klass alloc] init];
        NSAssert([obj conformsToProtocol:@protocol(HDBMgrDatasource)], @"must implement HDBMgrDatasource");
        self.datasource = obj;
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
- (FMDatabaseQueue *)defaultQueue
{
    dispatch_sync(self.operateQueue, ^{
        if (!_defaultQueue)
        {
            _defaultQueue = [self queueInitWithKey:[self defaultDatabaseKey]];
        }
    });
    return _defaultQueue;
}


#pragma mark - db connect

//init db file: unzip db to target directory
- (FMDatabaseQueue *)queueInitWithKey:(NSString *)key
{
    NSString *setupPath =[self setupPathForKey:key];
    if (!setupPath)
    {
        NSLog(@"%@ db setup path is not exist",key);
        abort();
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL find = [fileManager fileExistsAtPath:setupPath];
    if (!find) {

        NSString *sourcePath = [self databasePathInBundleForKey:key];
        [self safeCopyItemAtPath:sourcePath toPath:setupPath atomically:YES isOverwrite:YES error:nil];
    }
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:setupPath];
    if (!dbQueue)
    {
        return nil;
    }
    [_queuesDict setObject:dbQueue forKey:key];
    [self databaseQueueSetuped:key  dbqueue:dbQueue isNew:!find];
    return dbQueue;
}

#pragma mark - config


- (NSString *)defaultDatabaseKey
{
    if (!_datasource) abort();
    return [_datasource defaultDatabaseKey];
}

- (NSString *)databasePathInBundleForKey:(NSString *)key
{
    if (!_datasource) abort();
    return [_datasource databasePathInBundleForKey:key];
}

- (NSString *)setupPathForKey:(NSString *)key
{
    if (!_datasource) abort();
    return [_datasource setupPathForKey:key];
}

- (void)databaseQueueSetuped:(NSString *)key dbqueue:(FMDatabaseQueue *)dbqueue isNew:(BOOL)isNew
{
    if (!_datasource) abort();
    return [_datasource databaseQueueSetuped:key dbqueue:dbqueue isNew:isNew];
}


- (NSString *)entityNameWithTableName:(NSString *)tableName
{
    NSString *entityClassName = _tableToEntityClassNameCache[tableName];
    if (!entityClassName)
    {
        entityClassName = [_datasource entityClassNameForTable:tableName];
        [_tableToEntityClassNameCache setObject:entityClassName forKey:tableName];
    }
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
