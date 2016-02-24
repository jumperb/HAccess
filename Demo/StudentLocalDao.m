//
//  StudentLocalDao.m
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

#import "StudentLocalDao.h"

@implementation StudentLocalDao

- (void)setupQueue
{
    queue = [HDBMgr queueWithKey:@"HAccess2"];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        tableName = @"student";
    }
    return self;
}
@end
