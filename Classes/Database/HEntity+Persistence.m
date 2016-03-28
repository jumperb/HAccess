//
//  HEntity+Persistence.m
//  HAccess
//
//  Created by zhangchutian on 16/3/18.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HEntity+Persistence.h"
#import "HDatabaseDAO.h"

@implementation HEntity (Persistence)

+ (NSString *)tableName
{
    return NSStringFromClass([self class]);
}

+ (NSString *)databaseKey
{
    return @"default";
}
+ (HDatabaseDAO *)dao
{
    HDatabaseDAO *dao = [[HDatabaseDAO alloc] initWithDbKey:[self.class databaseKey] tableName:[self.class tableName]];
    return dao;
}
#pragma mark - create

- (BOOL)save
{
    return [[self.class dao] save:self];
}

- (BOOL)save:(NSString *)keypp
{
    return [[self.class dao] save:self keypp:keypp];
}

- (BOOL)add
{
    return [[self.class dao] add:self];
}

+ (NSString *)lastInsertedID
{
    return [[self dao] lastInsertedID];
}

+ (BOOL)adds:(NSArray *)entities
{
    return [[self dao] adds:entities];
}


#pragma mark - delete

- (BOOL)remove
{
    NSString *keyPP = [self keyProperty];
    id value = [self hValueForKey:keyPP];
    return [[self.class dao] remove:[HDatabaseDAO cleanValue:value]];
}
- (BOOL)remove:(NSString *)keyppValue
{
    return [[self.class dao] remove:keyppValue];
}

+ (BOOL)removes:(NSString *)conditions
{
    return [[self dao] removes:conditions];
}


#pragma mark - update

- (BOOL)update
{
    return [[self.class dao] update:self];
}

- (BOOL)update:(NSString *)keypp
{
    return [[self.class dao] update:self keypp:keypp];
}

- (BOOL)update2:(NSArray *)keyppList
{
    return [[self.class dao] update:self keyppList:keyppList];
}

+ (BOOL)updates:(NSArray *)entities
{
    return [[self dao] updates:entities];
}

+ (BOOL)updates:(NSArray *)entities keyppList:(NSArray *)keyppList
{
    return [[self dao] updates:entities keyppList:keyppList];
}
+ (BOOL)updatesWithSetters:(NSDictionary *)setters conditions:(NSString *)conditions
{
    return [[self dao] updatesWithSetters:setters conditions:conditions];
}

#pragma mark - read

+ (HEntity *)get:(NSString *)keyppValue
{
    return [[self dao] get:keyppValue];
}

+ (HEntity *)getWithCondition:(NSString *)condition
{
    return [[self dao] getWithCondition:condition];
}

+ (HEntity *)getWithCondition2:(NSDictionary *)condition
{
    return [[self dao] getWithCondition2:condition];
}

+ (NSArray *)list:(NSString *)conditions
{
    return [[self dao] list:conditions];
}

+ (NSArray *)list2:(NSDictionary *)conditions
{
    return [[self dao] list2:conditions];
}

+ (long)count:(NSString *)conditions
{
    return [[self dao] count:conditions];
}
+ (long)count2:(NSDictionary *)conditions
{
    return [[self dao] count2:conditions];
}
@end
