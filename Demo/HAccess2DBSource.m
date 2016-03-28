//
//  HAccessDBDatasource.m
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

#import "HAccess2DBSource.h"
#import <HCommon.h>


#define HDBDatasourceKey (@"HAccess2")

@implementation HAccess2DBSource

HReg2(HDBMgrDatasourceRegKey, HDBDatasourceKey)

- (NSString *)databasePathInBundle
{
    NSString *path = [[NSBundle mainBundle] pathForResource:HDBDatasourceKey ofType:@"sqlite"];
    return path;
    
}


- (NSString *)setupPath
{
    return [NSFileManager libPath:[NSString stringWithFormat:@"%@.sqlite", HDBDatasourceKey]];
}

- (NSString *)entityClassNameForTable:(NSString *)tableName
{
    return tableName;
}

- (void)databaseQueueSetupedAtDBQueue:(FMDatabaseQueue *)dbqueue isNew:(BOOL)isNew
{
    NSLog(@"");
}

@end
