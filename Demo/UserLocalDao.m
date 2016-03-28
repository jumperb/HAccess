//
//  UserLocalDao.m
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

#import "UserLocalDao.h"

@implementation UserLocalDao

- (NSString *)databaseKey
{
    return @"HAccess1";
}
- (NSString *)tableName
{
    return @"User";
}
@end
