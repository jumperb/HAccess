//
//  HDeserializableObject.m
//  HAccess
//
//  Created by zhangchutian on 16/3/2.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HDeserializableObject.h"





@implementation HDeserializableObject
- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    return [self initWithDictionary:dict enableKeyMap:YES couldEmpty:NO];
}
- (instancetype)initWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty
{
    self = [super init];
    if (self) {
        NSError *err = [self h_setWithDictionary:dict enableKeyMap:enableKeyMap couldEmpty:couldEmpty];
        if (err) {
            self.format_error = err.localizedDescription;
        }
    }
    return self;
}
- (void)setWithDictionary:(NSDictionary *)dict
{
    [self setWithDictionary:dict enableKeyMap:YES couldEmpty:NO];
}
- (void)setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap
{
    [self setWithDictionary:dict enableKeyMap:enableKeyMap couldEmpty:NO];
}
- (NSError *)h_setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty {
    [self setWithDictionary:dict enableKeyMap:enableKeyMap couldEmpty:couldEmpty];
    if (self.format_error) return herr(kDataFormatErrorCode, self.format_error);
    else return nil;
}
- (void)setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty
{
    NSError *err = [super h_setWithDictionary:dict enableKeyMap:enableKeyMap couldEmpty:couldEmpty];
    if (err) {
        self.format_error = err.localizedDescription;
    }
}

- (NSError *)h_setValue:(id)value forProperty:(HPropertyDetail *)ppDetail exts:(HDOPropertyExt *)propertyExts enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty {
    [self setValue:value forProperty:ppDetail exts:propertyExts enableKeyMap:enableKeyMap couldEmpty:couldEmpty];
    if (self.format_error) return herr(kDataFormatErrorCode, self.format_error);
    else return nil;
}
- (void)setValue:(id)value forProperty:(HPropertyDetail *)ppDetail exts:(HDOPropertyExt *)propertyExts enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty {
    NSError *err = [super h_setValue:value forProperty:ppDetail exts:propertyExts enableKeyMap:enableKeyMap couldEmpty:couldEmpty];
    if (err) {
        self.format_error = err.localizedDescription;
    }
}
- (void)setWithDObj:(HDeserializableObject *)obj
{
    if (![obj isKindOfClass:[HDeserializableObject class]]) return;
    NSArray *pplist = [[HPropertyMgr shared] entityPropertylist:NSStringFromClass(obj.class) deepTo:[HDeserializableObject class]];
    for (NSString *p in pplist)
    {
        id v = [obj valueForKey:p];
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
- (id)h_preMapValue:(id)value forKey:(NSString *)key {
    return [self preMapValue:value forKey:key];
}
- (id)preMapValue:(id)value forKey:(NSString *)key
{
    return value;
}
- (Class)h_classInArray:(id)item ppDetail:(HPropertyDetail *)ppDetail error:(NSError **)error {
    Class c = [self classInArray:item ppDetail:ppDetail];
    if (self.format_error) {
        *error = herr(kDataFormatErrorCode, self.format_error);
        return nil;
    }
    return c;
}
- (Class)classInArray:(id)item ppDetail:(HPropertyDetail *)ppDetail
{
    NSError *error;
    Class c = [super h_classInArray:item ppDetail:ppDetail error:&error];
    if (error) {
        self.format_error = error.localizedDescription;
        return nil;
    }
    return c;
}
- (Class)h_classForDictionary:(NSDictionary *)item ppDetail:(HPropertyDetail *)ppDetail error:(NSError * _Nullable __autoreleasing *)error {
    Class c = [self classForDictionary:item ppDetail:ppDetail];
    if (self.format_error) {
        *error = herr(kDataFormatErrorCode, self.format_error);
        return nil;
    }
    return c;
}
- (Class)classForDictionary:(NSDictionary *)item ppDetail:(HPropertyDetail *)ppDetail
{
    NSError *error;
    Class c = [super h_classForDictionary:item ppDetail:ppDetail error:&error];
    if (error) {
        self.format_error = error.localizedDescription;
        return nil;
    }
    return c;
}
- (id)h_createObjectWithClass:(Class)cls {
    return [self createObjectWithClass:cls];
}

- (id)createObjectWithClass:(Class)cls {
    return [cls new];
}

#pragma mark - NSCoping
- (id)copyWithZone:(nullable NSZone *)zone
{
    id copy = [[self class] new];
    if (copy) {
        NSArray *pplist = [[HPropertyMgr shared] entityPropertylist:NSStringFromClass(self.class) deepTo:[HDeserializableObject class]];
        for (NSString *p in pplist)
        {
            id v = [self valueForKey:p];
            if(v)
            {
                
                if([v isKindOfClass:[NSString class]])
                {
                    [copy setValue:[[v stringValue] copyWithZone:zone] forKey:p];
                }
                else if ([v isKindOfClass:[NSArray class]]) //default array cannot deep copy
                {
                    NSMutableArray *newArr = [NSMutableArray new];
                    for (id o in (NSArray *)v)
                    {
                        if ([o conformsToProtocol:@protocol(NSCopying)])
                        {
                            [newArr addObject:[o copyWithZone:zone]];
                        }
                        else
                        {
                            [newArr addObject:o];
                        }
                    }
                    [copy setValue:newArr forKey:p];
                }
                else if ([v isKindOfClass:[NSDictionary class]])
                {
                    NSMutableDictionary *newDict = [NSMutableDictionary new];
                    for (id key in (NSDictionary *)v)
                    {
                        id o = [(NSDictionary *)v objectForKey:key];
                        if ([o conformsToProtocol:@protocol(NSCopying)])
                        {
                            [newDict setObject:[o copyWithZone:zone] forKey:key];
                        }
                        else
                        {
                            [newDict setObject:o forKey:key];
                        }
                    }
                    [copy setValue:newDict forKey:p];
                }
                else if ([v conformsToProtocol:@protocol(NSCopying)])
                {
                    [copy setValue:[v copyWithZone:zone] forKey:p];
                }
                else
                {
                    [copy setValue:v forKey:p];
                }
            }
        }
    }
    
    return copy;
}
@end
