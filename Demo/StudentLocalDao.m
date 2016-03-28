//
//  StudentLocalDao.m
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

#import "StudentLocalDao.h"

@implementation StudentLocalDao

- (NSString *)databaseKey
{
    return @"HAccess2";
}
- (NSString *)tableName
{
    return @"student";
}

@end
