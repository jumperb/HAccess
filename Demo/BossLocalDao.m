//
//  BossLocalDao.m
//  HAccess
//
//  Created by zhangchutian on 14/11/3.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

#import "BossLocalDao.h"
#import "UserLocalDao.h"

@interface BossLocalDao ()
@property (nonatomic, strong) UserLocalDao *userDao;
@end

@implementation BossLocalDao
- (instancetype)init
{
    self = [super init];
    if (self) {
        _userDao = [[UserLocalDao alloc] init];
    }
    return self;
}
- (NSString *)tableName
{
    return @"Boss";
}
- (NSString *)databaseKey
{
    return @"HAccess1";
}
- (HEntity *)getWithCondition:(NSString *)condition
{
    abort();
}

- (BOOL)updatesWithSetters:(NSDictionary *)setters conditions:(NSString *)conditions
{
    abort();
}


- (BOOL)removes:(NSString *)conditions
{
    abort();
}


- (NSArray *)list:(NSString *)conditions
{
    abort();
}
- (NSArray *)list2:(NSDictionary *)conditions
{
    abort();
}

- (long)count:(NSString *)conditions
{
    abort();
}

@end
