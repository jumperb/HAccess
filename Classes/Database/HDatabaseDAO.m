//
//  HDatabaseDAO.m
//  HodorMVC
//
//  Created by zhangchutian on 12-10-23.
//  Copyright (c) 2012年 zhangchutian. All rights reserved.
//

#import "HDatabaseDAO.h"
#import "HEntityMgr.h"
#import <objc/runtime.h>
#import <HCommon.h>

@implementation HEntity (DBExtend)

- (void)setWithResultSet:(FMResultSet*)result
{
    self.ID = [result stringForColumn:@"id"];
    self.created = [result longForColumn:@"created"];
    self.modified = [result longForColumn:@"modified"];
    NSArray *pplist = [[HEntityMgr shared] entityPropertylist:NSStringFromClass(self.class) isDepSearch:YES];
    for (NSString *p in pplist)
    {
        if(result.columnNameToIndexMap[p])
        {
            id value = [result objectForColumnName:p];
            if (![value isKindOfClass:[NSString class]] || ![value isEqualToString:@"(null)"])
            {
                [self hSetValue:value forKey:p];
            }
        }
    }
}
@end


@interface HDatabaseDAO ()
@property (nonatomic, assign) BOOL shouldAddToQueue;
@end

@implementation HDatabaseDAO

#pragma mark - init dealloc
- (id)init
{
    self = [super init];
    if (self)
    {
        _shouldAddToQueue = YES;
        [self setupQueue];
    }
    return self;
}

- (void)setupQueue
{
    queue = [HDBMgr queue];
}

#pragma mark - queue wapping
- (instancetype)alreadyInQueue
{
    if (currentDB)
    {
        self.shouldAddToQueue = NO;
    }
    else
    {
        NSAssert(NO, @"you are invoking alreadyInQueue, but you are not in a queue block");
    }
    return self;
}
- (instancetype)alreadyInQueue:(FMDatabase *)db
{
    currentDB = db;
    return [self alreadyInQueue];
}

- (void)inDatabase:(void (^)(FMDatabase *db))block {

    @synchronized(self)
    {
        if (!_shouldAddToQueue&&currentDB)
        {
            _shouldAddToQueue = YES;
            block(currentDB);
        }
        else
        {
            [queue inDatabase:^(FMDatabase *db) {
#if DEBUG
                db.crashOnErrors = YES;
#else
#endif
                currentDB = db;
                block(db);
                currentDB = nil;
            }];
        }
    }
}
- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block
{
    @synchronized(self)
    {
        if (!_shouldAddToQueue&&currentDB)
        {
            _shouldAddToQueue = YES;
            block(currentDB, NULL);
        }
        else
        {
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
#if DEBUG
                db.crashOnErrors = YES;
#else
#endif
                currentDB = db;
                block(db, rollback);
                currentDB = nil;
            }];
        }
    }
}
- (void)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block
{
    @synchronized(self)
    {
        if (!_shouldAddToQueue&&currentDB)
        {
            _shouldAddToQueue = YES;
            block(currentDB, NULL);
        }
        else
        {
            [queue inDeferredTransaction:^(FMDatabase *db, BOOL *rollback) {
#if DEBUG
                db.crashOnErrors = YES;
#else
#endif
                currentDB = db;
                block(db, rollback);
                currentDB = nil;
            }];
        }
    }
}
#pragma mark - operations
- (BOOL)save:(HEntity *)entity
{
    return [self save:entity keypp:[entity keyProperty]];
}

- (BOOL)save:(HEntity *)entity keypp:(NSString *)keypp
{
    if (keypp.length == 0) return NO;
    NSString *IDValue = [HDatabaseDAO cleanValue:entity.ID];
    if (![keypp isEqualToString:@"id"]) IDValue = [entity hValueForKey:keypp];
    if(nil == [self get:IDValue])
    {
        return [self add:entity];
    }
    else
    {
        return [self update:entity keypp:keypp];
    }
    
}

- (BOOL)add:(HEntity *)entity
{
    if (!tableName) return NO;
    __block BOOL res = YES;

    [self inDatabase:^(FMDatabase* db)
     {
         NSArray *pplist = [[HEntityMgr shared] entityPropertylist:[[HDBMgr shared] entityNameWithTableName:tableName] isDepSearch:NO];
         NSString *fields = [[HEntityMgr shared] entityPropertylistString:[[HDBMgr shared] entityNameWithTableName:tableName] isDepSearch:NO];
         NSMutableString *values = [[NSMutableString alloc] init];
         int index = 0;
         for (NSString *p in pplist)
         {
             if (index != 0)
             {
                 [values appendString:@","];
             }
             [values appendFormat:@"'%@'",[HDatabaseDAO cleanValue:[entity hValueForKey:p]]];
             index ++;
         }

         long nowtime = time(NULL);
         fields = [fields stringByAppendingString:@",created,modified"];
         [values appendFormat:@",'%li','%li'", nowtime, nowtime];
         if (entity.ID)
         {
             fields = [fields stringByAppendingString:@",id"];
             [values appendFormat:@",'%@'", [HDatabaseDAO cleanValue:entity.ID]];
         }
         NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName,fields,values];
         res = [db executeUpdate:sql];
         if (res)
         {
             entity.ID = [[self alreadyInQueue] lastInsertedID];
             entity.created = nowtime;
             entity.modified = nowtime;
         }
     }];
    return res;
}

- (NSString *)lastInsertedID
{
    return [self lastInsertedIDOfTable:tableName];
}

- (BOOL)remove:(NSString *)key
{
    if (!tableName) return NO;
    __block BOOL res = YES;
    NSString *className = [[HDBMgr shared].datasource entityClassNameForTable:tableName];
    Class aclass = NSClassFromString(className);
    if (!aclass) return NO;
    HEntity *entity = [[aclass alloc] init];
    if (![entity isKindOfClass:[HEntity class]])
    {
        return NO;
    }
    NSString *keypp1 = [entity keyProperty];
    [self inDatabase:^(FMDatabase* db)
     {
         NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = '%@'", tableName, keypp1, [HDatabaseDAO cleanValue:key]];
         res = [db executeUpdate:sql];
     }];
    return res;
}

- (BOOL)update:(HEntity *)entity
{
    return [self update:entity keypp:[entity keyProperty]];
}

- (BOOL)update:(HEntity *)entity keypp:(NSString *)keypp
{
    if (!tableName) return NO;
    __block BOOL res = YES;
    [self inDatabase:^(FMDatabase* db)
     {
         NSMutableString *settes =[[NSMutableString alloc] init];
         NSArray *pplist = [[HEntityMgr shared] entityPropertylist:[[HDBMgr shared] entityNameWithTableName:tableName] isDepSearch:NO];
         int index = 0;
         for (NSString *p in pplist)
         {
             if (index != 0)
             {
                 [settes appendString:@","];
             }
             [settes appendFormat:@" %@ ='%@'", p, [HDatabaseDAO cleanValue:[entity hValueForKey:p]]];
             index ++;
         }

         long nowtime = time(NULL);
         [settes appendFormat:@", modified = '%li'", nowtime];
         NSString *IDValue = [HDatabaseDAO cleanValue:entity.ID];
         if (![keypp isEqualToString:@"id"]) IDValue = [entity hValueForKey:keypp];
         NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = '%@'", tableName, settes, keypp, IDValue];
         res = [db executeUpdate:sql];
         if (res)
         {
             entity.modified = nowtime;
         }
     }];
    return res;
}
- (BOOL)update:(HEntity *)entity keyppList:(NSArray *)keyppList
{
    if (!tableName) return NO;
    __block BOOL res = YES;
    [self inDatabase:^(FMDatabase* db)
     {
         NSMutableString *settes =[[NSMutableString alloc] init];
         NSArray *pplist = [[HEntityMgr shared] entityPropertylist:[[HDBMgr shared] entityNameWithTableName:tableName] isDepSearch:NO];
         int index = 0;
         for (NSString *p in pplist)
         {
             if (index != 0)
             {
                 [settes appendString:@","];
             }
             [settes appendFormat:@" %@ ='%@'", p, [HDatabaseDAO cleanValue:[entity hValueForKey:p]]];
             index ++;
         }
         
         
         long nowtime = time(NULL);
         [settes appendFormat:@", modified = '%li'", nowtime];

         NSMutableString *whereStatment = [[NSMutableString alloc] init];
         for (NSString *pp in keyppList)
         {
             id value = [HDatabaseDAO cleanValue:entity.ID];
             if (![pp isEqualToString:@"id"]) value = [entity hValueForKey:pp];
             [whereStatment appendFormat:@" and %@ = '%@'",pp,[HDatabaseDAO cleanValue:[value stringValue]]];
         }
         NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE 1 %@", tableName, settes, whereStatment];
         res = [db executeUpdate:sql];
         if (res)
         {
             entity.modified = nowtime;
         }
     }];
    return res;
}

- (HEntity *)get:(NSString *)key
{
    __block HEntity *entity;
    if (!tableName) return nil;
    if (!key) return nil;
    NSString *className = [[HDBMgr shared].datasource entityClassNameForTable:tableName];
    Class aclass = NSClassFromString(className);
    if (!aclass) return nil;
    HEntity *tempEntity = [[aclass alloc] init];
    if (![tempEntity isKindOfClass:[HEntity class]])
    {
        return nil;
    }
    NSString *keypp = [tempEntity keyProperty];
    key = [HDatabaseDAO cleanValue:key];


    [self inDatabase:^(FMDatabase* db)
     {
         NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = '%@'", tableName, keypp, key];
         FMResultSet* result = [db executeQuery:sql];
         if([result next])
         {
             if ([[HDBMgr shared].datasource respondsToSelector:@selector(entityClassNameForTable:)])
             {
                 NSString *className = [[HDBMgr shared].datasource entityClassNameForTable:tableName];
                 Class aclass = NSClassFromString(className);
                 if (class_getInstanceMethod(aclass, @selector(setWithResultSet:)))
                 {
                     if (!entity) entity = (HEntity *)[[aclass alloc] init];
                     if (![entity isKindOfClass:[HEntity class]])
                     {
                         NSLog(@"this class does not a subclass of HEntity");
                         abort();
                     }
                     [entity setWithResultSet:result];
                 }
                 else
                 {
                     NSLog(@"this class does not a subclass of HEntity");
                     abort();
                 }
             }
             else
             {
                 NSLog(@"you need set the mapping between entity class name and table name in datasource, if you want use quick method");
                 abort();
             }
         }
         [result close];
     }];
    return entity;
}

- (HEntity *)getWithCondition:(NSString *)condition
{
    if (!tableName) return nil;
    if (!condition) return nil;
    NSString *className = [[HDBMgr shared].datasource entityClassNameForTable:tableName];
    Class aclass = NSClassFromString(className);
    if (!aclass) return nil;
    HEntity *tempEntity = [[aclass alloc] init];
    if (![tempEntity isKindOfClass:[HEntity class]])
    {
        return nil;
    }
    __block HEntity *entity = nil;
    [self inDatabase:^(FMDatabase* db)
     {
         NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@", tableName, condition];
         FMResultSet* result = [db executeQuery:sql];
         if([result next])
         {
             if ([[HDBMgr shared].datasource respondsToSelector:@selector(entityClassNameForTable:)])
             {
                 NSString *className = [[HDBMgr shared].datasource entityClassNameForTable:tableName];
                 Class aclass = NSClassFromString(className);
                 if (class_getInstanceMethod(aclass, @selector(setWithResultSet:)))
                 {
                     entity = (HEntity *)[[aclass alloc] init];
                     if (![entity isKindOfClass:[HEntity class]])
                     {
                         NSLog(@"this class does not a subclass of HEntity");
                         abort();
                     }
                     [entity setWithResultSet:result];
                 }
                 else
                 {
                     NSLog(@"this class does not a subclass of HEntity");
                     abort();
                 }
             }
             else
             {
                 NSLog(@"you need set the mapping between entity class name and table name in datasource, if you want use quick method");
                 abort();
             }
         }
         [result close];
     }];
    return entity;
}
- (HEntity *)getWithCondition2:(NSDictionary *)conditions
{
    return [self getWithCondition:[self conditonsStringFromDict:conditions]];
}

- (BOOL)adds:(NSArray *)entities
{
    if (!tableName) return NO;
    if ([entities count] == 0) return NO;
    NSString *entityClassName = [[HDBMgr shared] entityNameWithTableName:tableName];
    NSArray *pplist = [[HEntityMgr shared] entityPropertylist:entityClassName isDepSearch:NO];
    NSString *fields = [[HEntityMgr shared] entityPropertylistString:entityClassName isDepSearch:NO];
    fields = [fields stringByAppendingString:@",created,modified"];

    __block BOOL res = YES;
    [self inTransaction:^(FMDatabase* db, BOOL *rollback)
     {
         NSMutableString *values = [[NSMutableString alloc] init];
         int i = 0;
         long nowtime = time(NULL);
         for (HEntity *entity in entities)
         {
             if (i != 0)
             {
                 [values appendString:@","];
             }
             [values appendString:@"("];
             int j = 0;
             for (NSString *p in pplist)
             {
                 if (j != 0)
                 {
                     [values appendString:@","];
                 }
                 [values appendFormat:@"'%@'",[HDatabaseDAO cleanValue:[entity hValueForKey:p]]];
                 j ++;
             }
             [values appendFormat:@",'%li','%li'",nowtime,nowtime];
             [values appendString:@")"];
             i ++;
         }

         NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES %@", tableName,fields,values];
         res = [db executeUpdate:sql];
     }];
    return res;
}

- (BOOL)updates:(NSArray *)entities
{
    __block BOOL res = YES;
    [self inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (HEntity *entity in entities)
        {
            res = [self.alreadyInQueue update:entity];
            if (!res)
            {
                if (rollback != NULL) *rollback = YES;
                break;
            }
        }
    }];
    return res;
}
- (BOOL)updates:(NSArray *)entities keyppList:(NSArray *)keyppList
{
    __block BOOL res = YES;
    [self inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (HEntity *entity in entities)
        {
            res = [self.alreadyInQueue update:entity keyppList:keyppList];
            if (!res)
            {
                if (rollback != NULL) *rollback = YES;
                break;
            }
        }
    }];
    return res;
}

- (BOOL)updatesWithSetters:(NSDictionary *)setters conditions:(NSString *)conditions
{
    if (!tableName) return NO;
    __block BOOL res = YES;
    [self inTransaction:^(FMDatabase* db, BOOL *rollback)
     {
         NSMutableString *settesString =[[NSMutableString alloc] init];
         int index = 0;
         for (NSString *key in setters)
         {
             NSString *value = [HDatabaseDAO cleanValue:setters[key]];
             if (index != 0)
             {
                 [settesString appendString:@","];
             }
             [settesString appendFormat:@" %@ ='%@'", key, value];
             index ++;
         }

         long nowtime = time(NULL);
         [settesString appendFormat:@", modified = '%li'", nowtime];
         NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@", tableName, settesString, conditions];
         res = [db executeUpdate:sql];
     }];
    return res;
}



- (BOOL)removes:(NSString *)conditions
{
    if (!tableName) return NO;
    if (!conditions) conditions = @"1";
    __block BOOL res = YES;
    [self inDatabase:^(FMDatabase* db)
     {
         NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", tableName, conditions];
         res = [db executeUpdate:sql];
     }];
    return res;
}

- (NSArray *)list2:(NSDictionary *)conditions
{
    return [self list:[self conditonsStringFromDict:conditions]];
}
- (NSArray *)list:(NSString *)conditions;
{
    if (!tableName) return nil;
    if ([[HDBMgr shared].datasource respondsToSelector:@selector(entityClassNameForTable:)])
    {
        NSString *className = [[HDBMgr shared].datasource entityClassNameForTable:tableName];
        Class aclass = NSClassFromString(className);
        if (!class_getInstanceMethod(aclass, @selector(setWithResultSet:)))
        {
            NSLog(@"this class does not a subclass of HEntity");
            abort();
        }


        if (!conditions) conditions = @"1";
        __block NSMutableArray *res = [[NSMutableArray alloc] init];
        [self inDatabase:^(FMDatabase* db)
         {

             NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@", tableName, conditions];
             FMResultSet* result = [db executeQuery:sql];
             while ([result next])
             {
                 HEntity *entity = (HEntity *)[[aclass alloc] init];
                 if (![entity isKindOfClass:[HEntity class]])
                 {
                     NSLog(@"this class does not a subclass of HEntity");
                     abort();
                 }
                 [entity setWithResultSet:result];
                 [res addObject:entity];
             }
             [result close];
         }];
        return res;
    }
    else
    {
        NSLog(@"you need set the mapping between entity class name and table name in datasource, if you want use quick method");
        abort();
    }
}


- (long)count:(NSString *)conditions
{
    if (!tableName) return -1;
    if (!conditions) conditions = @"1";
    __block long res = -1;
    [self inDatabase:^(FMDatabase* db)
     {
         NSString *sql = [NSString stringWithFormat:@"SELECT count(*) as cnt FROM %@ WHERE  %@", tableName, conditions];
         FMResultSet* result = [db executeQuery:sql];
         if([result next])
         {
             res = [result longForColumn:@"cnt"];
         }
         [result close];
     }];
    return res;
}
- (long)count2:(NSDictionary *)conditions
{
    return [self count:[self conditonsStringFromDict:conditions]];
}
#pragma mark - other

- (NSString *)lastInsertedIDOfTable:(NSString *)_tableName
{
    if (!_tableName) return @"-1";
    __block long res = -1;
    [self inDatabase:^(FMDatabase* db)
     {
         NSString *sql = [NSString stringWithFormat:@"SELECT seq FROM sqlite_sequence WHERE name = '%@'", _tableName];
         FMResultSet* result = [db executeQuery:sql];
         if([result next])
         {
             res = [result longForColumn:@"seq"];
         }
         [result close];
     }];
    return [NSString stringWithFormat:@"%li",res];
}

+ (NSString *)AutoIDForDomain:(NSString *)domainName
{
    NSString *key = [NSString stringWithFormat:@"AIK_%@",domainName];
    unsigned long long value = 100;
    NSString *res = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if(res) value = [res longLongValue];
    value ++;
    res = [NSString stringWithFormat:@"%qu",value];
    [[NSUserDefaults standardUserDefaults] setObject:res forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return res;
}

+ (id)cleanValue:(id)value
{
    if (!value) return nil;
    if (![value isKindOfClass:[NSString class]]) return value;
    NSString *valueStr = value;
    NSUInteger length = [valueStr length];
    NSMutableString *newValue = [NSMutableString new];
    for (NSUInteger i = 0; i < length; ++i) {
        unichar current = [valueStr characterAtIndex:i];
        switch (current) {
            case '\'':
            {
                [newValue appendString:@"\""];
                break;
            }
            default:
                [newValue appendFormat:@"%C",current];
                break;
        }
    }
    return newValue;
}
- (NSString *)conditonsStringFromDict:(NSDictionary *)dict
{
    NSMutableString *str = [[NSMutableString alloc] init];
    int index = 0;
    for (NSString *key in dict) {
        NSString *value = dict[key];
        if (index != 0)
        {
            [str appendString:@" and "];
        }
        if ([value isKindOfClass:[NSString class]]) [str appendFormat:@"%@='%@'",key,[HDatabaseDAO cleanValue:value]];
        else [str appendFormat:@"%@=%@",key,[value stringValue]];
        index ++;
    }
    return str;
}
@end


