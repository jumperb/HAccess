//
//  TestEntity.m
//  HAccess
//
//  Created by zhangchutian on 15/9/2.
//  Copyright (c) 2015年 zhangchutian. All rights reserved.
//

#import "TestEntity1.h"

@implementation TestEntity
@end

@implementation TestEntity1
ppx(ar, HPOptional, HPMapto(@"123"))
ppx(a, HPScope(1, 10), HPAutoCast);
ppx(b, HPScope(1, 10));
@end

@implementation TestEntity2
ppx(b, HPInnerType([NSDictionary class]))
@end

@implementation TestEntity3

ppx(b, HPOptional)

- (id)preMapValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:pp_name(c)])
    {
        return [value stringValue];
    }
    return value;
}
@end


@implementation TestEntity4
ppx(e, HPInnerType([TestEntity1 class]))
@end

@implementation TestEntity5
@end


@implementation TestEntity6
ppx(a, HPOptional)
ppx(b, HPOptional, HPMapto(@"cc"))
@end


@implementation TestEntity7
@end


@implementation TestEntity8

ppx(a, HPAutoCast)
ppx(b, HPAutoCast)
ppx(c, HPAutoCast)
ppx(d, HPAutoCast)
@end


@implementation TestProtocalIMP

ppx(a, HPOptional)
ppx(b, HPIgnore)
ppx(c, HPOptional)
ppx(e, HPAutoCast)

- (id)a
{
    return self.e;
}
- (double)b
{
    return [self.f doubleValue];
}
- (double)c
{
    return [self.f doubleValue];
}

- (NSString *)fun1
{
    return @"";
}

- (long)fun2:(NSString *)userLocation
{
    return 1;
}
@end


@implementation TestEntity9
ppx(b, HPInnerType([TestProtocalIMP class]));
@end


@implementation TestEntity10
ppx(pp, HPDivideType(@"type", @"TestEntity", [TestEntity class], @(4), [TestProtocalIMP class]));
ppx(arr, HPDivideType(@"type", @"TestEntity", [TestEntity class], @(4), [TestProtocalIMP class]));
@end


@implementation TestEntity11
ppx(server_created, HPMapto(@"created"))
ppx(server_modified, HPMapto(@"modified"))
ppx(created, HPIgnore)
ppx(modified, HPIgnore)
@end