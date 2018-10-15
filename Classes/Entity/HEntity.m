//
//  HEntity.m
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

#import "HEntity.h"
#import "HPropertyMgr.h"


@implementation HEntity

ppx(ID, HPOptional)
ppx(created, HPOptional)
ppx(modified, HPOptional)

- (NSString *)keyProperty
{
    return @"id";
}
- (void)setWithEntity:(HEntity *)entity
{
    if (![entity isKindOfClass:[HEntity class]]) return;
    NSArray *pplist = [[HPropertyMgr shared] entityPropertylist:NSStringFromClass(self.class) deepTo:[HDeserializableObject class]];
    for (NSString *p in pplist)
    {
        if ([p isEqualToString:@"ID"] && self.ID == nil)
        {
            self.ID = entity.ID;
        }
        else if ([p isEqualToString:@"created"] && self.created == 0)
        {
            self.created = entity.created;
        }
        else if ([p isEqualToString:@"modified"] && self.modified == 0)
        {
            self.modified = entity.modified;
        }
        else
        {
            id v = [entity valueForKey:p];
            //if has to property
            if(v)
            {
                id oldV = [self valueForKey:p];
                if ([oldV isEqual:v]) continue;
                
                if([v isKindOfClass:[NSString class]])
                {
                    [self setValue:[v stringValue] forKey:p];
                }
                else
                {
                    [self setValue:v forKey:p];
                }
            }
        }
    }
}
- (id)valueForUndefinedKey:(NSString *)key
{
    //do nothing
    return nil;
}

- (void)hSetValue:(id)value forKey:(NSString *)key
{
    [self setValue:value forKeyPath:key];
}
- (id)hValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"id"]) return self.ID;
    else return [super valueForKey:key];
}
@end
