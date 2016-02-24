//
//  UserLocalDao.m
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

#import "UserLocalDao.h"

@implementation UserLocalDao
- (instancetype)init
{
    self = [super init];
    if (self) {
        tableName = @"User";
    }
    return self;
}
@end
