//
//  HDeserializableObject.m
//  HAccess
//
//  Created by zhangchutian on 16/3/2.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HDeserializableObject.h"
/**
 *  propert extend attr
 */
@interface HDOPropertyExt : NSObject
@property (nonatomic) BOOL isOptional;
@property (nonatomic) BOOL isIgnore;
@property (nonatomic) BOOL isAutocast;
@property (nonatomic) NSString *keyMapto;
@property (nonatomic) Class innerType;
@property (nonatomic) NSArray *divideType;
@property (nonatomic) NSNumber *from;
@property (nonatomic) NSNumber *to;
- (BOOL)isInRange:(NSNumber *)value;
@end

@implementation HDOPropertyExt
- (instancetype)initWithObjs:(id)objs
{
    self = [super init];
    if (self) {
        if ([objs isKindOfClass:[NSArray class]])
        {
            for (id obj in (NSArray *)objs)
            {
                [self setWithObj:obj];
            }
        }
    }
    return self;
}
- (void)setWithObj:(id)obj
{
    if ([obj isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = obj;
        NSString *mapTo = dict[@"mapto"];
        if (mapTo)
        {
            self.keyMapto = mapTo;
            return;
        }
        NSDictionary *scope = dict[@"scope"];
        if (scope)
        {
            NSNumber *from = scope[@"from"];
            if (from)
            {
                self.from = from;
                self.to = scope[@"to"];
            }
            return;
        }
        Class innerType = dict[@"innertype"];
        if (innerType)
        {
            self.innerType = innerType;
            return;
        }
        
        NSArray *divideType = dict[@"dividetype"];
        if (divideType)
        {
            self.divideType = divideType;
        }
    }
    else if ([obj isEqualToString:HPIgnore])
    {
        self.isIgnore = YES;
    }
    else if ([obj isEqualToString:HPOptional])
    {
        self.isOptional = YES;
    }
    else if ([obj isEqualToString:HPAutoCast])
    {
        self.isAutocast = YES;
    }
}
- (BOOL)isInRange:(NSNumber *)value
{
    BOOL isInRange = YES;
    if (self.from)
    {
        if ([self.from compare:value] == NSOrderedDescending || [self.to compare:value] == NSOrderedAscending)
        {
            isInRange = NO;
        }
    }
    return isInRange;
}
@end



@implementation HDeserializableObject
- (void)setWithDictionary:(NSDictionary *)dict
{
    [self setWithDictionary:dict enableKeyMap:YES];
}
- (void)setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap
{
    if (![dict isKindOfClass:[NSDictionary class]])
    {
        self.format_error = [NSString stringWithFormat:@"%@ key's value must be a NSDictionary", NSStringFromClass(self.class)];
        return;
    }
    
    NSArray *pplist = [[HPropertyMgr shared] entityPropertyDetailList:NSStringFromClass(self.class) isDepSearch:YES];
    
    for (HPropertyDetail *ppDetail in pplist)
    {
        NSArray *exts = [[self class] annotations:ppDetail.name];
        HDOPropertyExt *propertyExts = [[HDOPropertyExt alloc] initWithObjs:exts];
        if (propertyExts.isIgnore) continue;
        
        NSString *mappedKey = nil;
        if (enableKeyMap) mappedKey = propertyExts.keyMapto;
        if (!mappedKey) mappedKey = ppDetail.name;
        
        id value = [dict valueForKey:mappedKey];
        if (value)
        {
            id oldValue = value;
            value = [self preMapValue:value forKey:ppDetail.name];
            if (self.format_error) return;
            if (!value) value = [NSNull null];
            if ([value isKindOfClass:[NSNull class]])
            {
                if (![HPropertyMgr shared].strictModle) continue;
                if(!propertyExts.isOptional)
                {
                    self.format_error = [NSString stringWithFormat:@"%@:%@ can not be empty", NSStringFromClass(self.class),ppDetail.name];
                    return;
                }
            }
            else if ([value isKindOfClass:[NSString class]])
            {
                if (![HPropertyMgr shared].strictModle)
                {
                    [self setValue:[value stringValue] forKey:ppDetail.name];
                }
                else
                {
                    if ([ppDetail.typeString isEqualToString:NSStringFromClass([NSString class])] || [ppDetail.typeString isEqualToString:NSStringFromClass([NSMutableString class])])
                    {
                        [self setValue:[value stringValue] forKey:ppDetail.name];
                    }
                    else if (!ppDetail.isObj && propertyExts.isAutocast)
                    {
                        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                        NSNumber *valueNum = [formatter numberFromString:value];
                        //if cannot convert value to number , set to 0 by defaylt
                        if (!valueNum) valueNum = @(0);
                        if ([propertyExts isInRange:valueNum])
                        {
                            [self setValue:valueNum forKey:ppDetail.name];
                        }
                        else
                        {
                            self.format_error = [NSString stringWithFormat:@"%@:%@ value is out of scope (%@, %@)", NSStringFromClass(self.class), ppDetail.name, propertyExts.from, propertyExts.to];
                            return;
                        }
                    }
                    else
                    {
                        self.format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
                        return;
                    }
                    
                }
            }
            else if ([value isKindOfClass:[NSNumber class]])
            {
                if (![HPropertyMgr shared].strictModle)
                {
                    [self setValue:value forKey:ppDetail.name];
                }
                else
                {
                    if (!ppDetail.isObj || [ppDetail.typeString isEqualToString:NSStringFromClass([NSNumber class])])
                    {
                        if ([propertyExts isInRange:value])
                        {
                            [self setValue:value forKey:ppDetail.name];
                        }
                        else
                        {
                            self.format_error = [NSString stringWithFormat:@"%@:%@value is out of scope(%@, %@)", NSStringFromClass(self.class), ppDetail.name, propertyExts.from, propertyExts.to];
                            return;
                        }
                    }
                    else if (propertyExts.isAutocast && ([ppDetail.typeString isEqualToString:NSStringFromClass([NSString class])] || [ppDetail.typeString isEqualToString:NSStringFromClass([NSMutableString class])]))
                    {
                        [self setValue:[value stringValue] forKey:ppDetail.name];
                    }
                    else
                    {
                        self.format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
                        return;
                    }
                }
            }
            else if ([value isKindOfClass:[NSArray class]])
            {
                if (!ppDetail.isObj)
                {
                    self.format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
                    return;
                }
                if (![ppDetail.typeString isEqualToString:NSStringFromClass([NSArray class])] &&
                    ![ppDetail.typeString isEqualToString:NSStringFromClass([NSMutableArray class])])
                {
                    self.format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
                    return;
                }
                
                
                NSMutableArray *objs = [NSMutableArray new];
                for (id arrayItem in (NSArray *)value)
                {
                    Class theClass = [self classInArray:arrayItem ppDetail:ppDetail];
                    if (self.format_error) return;
                    if (!theClass) continue;
                    
                    if ([theClass isSubclassOfClass:[HDeserializableObject class]])
                    {
                        if ([arrayItem isKindOfClass:[NSDictionary class]])
                        {
                            NSDictionary *dict2 = arrayItem;
                            id obj = [[theClass alloc] init];
                            [(HDeserializableObject *)obj setWithDictionary:dict2 enableKeyMap:enableKeyMap];
                            if ([(HDeserializableObject *)obj format_error])
                            {
                                self.format_error = [(HDeserializableObject *)obj format_error];
                                return;
                            }
                            else
                            {
                                [objs addObject:obj];
                            }
                            
                        }
                        else
                        {
                            self.format_error = [NSString stringWithFormat:@"%@:%@ must be NSDictionary type", NSStringFromClass(self.class), ppDetail.name];
                            return;
                        }
                    }
                    else
                    {
                        [objs addObject:arrayItem];
                    }
                }
                [self setValue:objs forKey:ppDetail.name];
                
            }
            else if ([value isKindOfClass:[NSDictionary class]])
            {
                if (!ppDetail.isObj)
                {
                    self.format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
                    return;
                }
                if ([ppDetail.typeString isEqualToString:NSStringFromClass([NSString class])] ||
                    [ppDetail.typeString isEqualToString:NSStringFromClass([NSNumber class])] ||
                    [ppDetail.typeString isEqualToString:NSStringFromClass([NSArray class])] ||
                    [ppDetail.typeString isEqualToString:NSStringFromClass([NSMutableArray class])])
                {
                    self.format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
                    return;
                }
                
                Class theClass = [self classForDictionary:value ppDetail:ppDetail];
                if (self.format_error) return;
                
                if ([theClass isSubclassOfClass:[NSDictionary class]])
                {
                    [self setValue:value forKey:ppDetail.name];
                }
                else if ([theClass isSubclassOfClass:[HDeserializableObject class]])
                {
                    id obj = [[theClass alloc] init];
                    [(HDeserializableObject *)obj setWithDictionary:value enableKeyMap:enableKeyMap];
                    if ([(HDeserializableObject *)obj format_error])
                    {
                        self.format_error = [(HDeserializableObject *)obj format_error];
                        return;
                    }
                    else
                    {
                        [self setValue:obj forKey:ppDetail.name];
                    }
                }
            }
            else
            {
                if (oldValue == value) //value not converted
                {
                    self.format_error = [NSString stringWithFormat:@"%@:%@ is unsupport type %@", NSStringFromClass(self.class), ppDetail.name, NSStringFromClass([value class])];
                    return;
                }
                else //value has converted
                {
                    [self setValue:value forKey:ppDetail.name];
                }
            }
        }
        else
        {
            if (![HPropertyMgr shared].strictModle) continue;
            if(!propertyExts.isOptional)
            {
                self.format_error = [NSString stringWithFormat:@"%@:%@ can not be empty", NSStringFromClass(self.class), ppDetail.name];
                return;
            }
        }
    }
}
- (id)preMapValue:(id)value forKey:(NSString *)key
{
    return value;
}
- (Class)getClassWithDivideTypeForItem:(id)item propertyExts:(HDOPropertyExt *)propertyExts ppName:(NSString *)ppName
{
    if ([item isKindOfClass:[NSDictionary class]])
    {
        if ([propertyExts.divideType count] < 3)
        {
            self.format_error = [NSString stringWithFormat:@"%@的HNDividedType参数个数至少是3个", ppName];
            return nil;
        }
        else
        {
            NSString *key = propertyExts.divideType[0];
            id typeValue = item[key];
            if ([typeValue isKindOfClass:[NSNumber class]]) typeValue = [(NSNumber *)typeValue stringValue];
            Class theClass = nil;
            for (int i = 1; i < propertyExts.divideType.count; i += 2)
            {
                id value = propertyExts.divideType[i];
                if ([value isKindOfClass:[NSNumber class]]) value = [(NSNumber *)value stringValue];
                if ([typeValue isEqual:value])
                {
                    if (i + 1 >= propertyExts.divideType.count)
                    {
                        self.format_error = [NSString stringWithFormat:@"%@的HNDividedType参数个数错误", ppName];
                        return nil;
                    }
                    theClass = propertyExts.divideType[i + 1];
                }
            }
            if (theClass)
            {
                return theClass;
            }
            else
            {
                //return nil mean to ignorl the value
                return nil;
            }
        }
    }
    else
    {
        self.format_error = [NSString stringWithFormat:@"%@对应的数据并不是一个字典", ppName];
        return nil;
    }
}
- (Class)classInArray:(id)item ppDetail:(HPropertyDetail *)ppDetail
{
    if (ppDetail.protocalString)
    {
        Class theClass = NSClassFromString(ppDetail.protocalString);
        return theClass;
    }
    else
    {
        HDOPropertyExt *propertyExts = [[HDOPropertyExt alloc] initWithObjs:[[self class] annotations:ppDetail.name]];
        if (propertyExts.innerType)
        {
            return propertyExts.innerType;
        }
        else if (propertyExts.divideType)
        {
            return [self getClassWithDivideTypeForItem:item propertyExts:propertyExts ppName:ppDetail.name];
        }
        else
        {
            return [item class];
        }
    }
}
- (Class)classForDictionary:(NSDictionary *)item ppDetail:(HPropertyDetail *)ppDetail
{
    //innerType has highest prioruty
    HDOPropertyExt *propertyExts = [[HDOPropertyExt alloc] initWithObjs:[[self class] annotations:ppDetail.name]];
    if (propertyExts.innerType)
    {
        return propertyExts.innerType;
    }
    else if (propertyExts.divideType)
    {
        Class theClass = [self getClassWithDivideTypeForItem:item propertyExts:propertyExts ppName:ppDetail.name];
        if (!theClass)
        {
            self.format_error = [NSString stringWithFormat:@"can not decide the type of %@", ppDetail.name];
            return nil;
        }
        else return theClass;
    }
    else
    {
        if ([ppDetail.typeString isEqualToString:@""])
        {
            return [item class];
        }
        else
        {
            Class theClass = NSClassFromString(ppDetail.typeString);
            if (!theClass)
            {
                self.format_error = [NSString stringWithFormat:@"%@ type is not exsit", ppDetail.typeString];
                return nil;
            }
            else return theClass;
        }
    }
}
@end
