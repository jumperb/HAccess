//
//  HAccessDBDatasource.m
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

#import "HDBDatasource.h"
#import <HCommon.h>
@implementation HDBDatasource

HReg(HDBMgrDatasourceRegKey)

- (NSString *)defaultDatabaseKey
{
    return @"HAccess1";
}


- (NSString *)databasePathInBundleForKey:(NSString *)key
{
    if ([key isEqualToString:@"HAccess1"])
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:key ofType:@"sqlite"];
        return path;
    }
    return nil;
}


- (NSString *)setupPathForKey:(NSString *)key
{
    if ([key isEqualToString:@"HAccess1"])
    {
        return [NSFileManager libPath:[NSString stringWithFormat:@"%@.sqlite",key]];
    }
    else if ([key isEqualToString:@"HAccess2"])
    {
        return [NSFileManager libPath:[NSString stringWithFormat:@"%@.sqlite",key]];
    }
    return nil;
}


- (NSString *)entityClassNameForTable:(NSString *)tableName
{
    return tableName;
}


- (void)databaseQueueSetuped:(NSString *)key dbqueue:(FMDatabaseQueue *)dbqueue isNew:(BOOL)isNew
{
    NSLog(@"");
}

@end
