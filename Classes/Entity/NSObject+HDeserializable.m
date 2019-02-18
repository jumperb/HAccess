//
//  NSObject+HDeserializable.m
//  HAccess
//
//  Created by zct on 2019/2/15.
//  Copyright © 2019 zhangchutian. All rights reserved.
//

#import "NSObject+HDeserializable.h"


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

@implementation NSObject (HDeserializable)
- (instancetype)h_initWithDictionary:(NSDictionary *)dict error:(NSError **)error
{
    id res = [self init];
    if (res) {
        NSError *e = [res h_setWithDictionary:dict enableKeyMap:YES couldEmpty:NO];
        if (e) {
            *error = e;
            return nil;
        }
    }
    return res;
}
- (instancetype)h_initWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty error:(NSError **)error
{
    id res = [self init];
    if (res) {
        NSError *e = [res h_setWithDictionary:dict enableKeyMap:enableKeyMap couldEmpty:couldEmpty];
        if (e) {
            *error = e;
            return nil;
        }
    }
    return res;
}
- (NSError *)h_setWithDictionary:(NSDictionary *)dict enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty
{
    if (![dict isKindOfClass:[NSDictionary class]])
    {
        NSString *format_error = [NSString stringWithFormat:@"%@ key's value must be a NSDictionary", NSStringFromClass(self.class)];
        return herr(kDataFormatErrorCode, format_error);
    }
    
    NSArray *pplist = [[HPropertyMgr shared] entityPropertyDetailList:NSStringFromClass(self.class) deepTo:[NSObject class]];
    
    for (HPropertyDetail *ppDetail in pplist)
    {
        NSArray *exts = [[self class] annotations:ppDetail.name];
        HDOPropertyExt *propertyExts = [[HDOPropertyExt alloc] initWithObjs:exts];
        if (propertyExts.isIgnore) continue;
        
        NSString *mappedKey = nil;
        if (enableKeyMap) mappedKey = propertyExts.keyMapto;
        if (!mappedKey) mappedKey = ppDetail.name;
        
        id value = [dict valueForKeyPath:mappedKey];
        if (value)
        {
            NSError *er = [self h_setValue:value forProperty:ppDetail exts:propertyExts enableKeyMap:enableKeyMap couldEmpty:couldEmpty];
            if (er) return er;
        }
        else
        {
            if (couldEmpty) continue;
            if(!propertyExts.isOptional)
            {
                NSString *format_error = [NSString stringWithFormat:@"%@:%@ can not be empty", NSStringFromClass(self.class), ppDetail.name];
                return herr(kDataFormatErrorCode, format_error);
            }
        }
    }
    return nil;
}
- (NSError *)h_setValue:(id)value forProperty:(HPropertyDetail *)ppDetail exts:(HDOPropertyExt *)propertyExts enableKeyMap:(BOOL)enableKeyMap couldEmpty:(BOOL)couldEmpty {
    id oldValue = value;
    value = [self h_preMapValue:value forKey:ppDetail.name];
    if ([value isKindOfClass:[NSError class]]) return value;
    if (!value) value = [NSNull null];
    if ([value isKindOfClass:[NSNull class]])
    {
        if(!propertyExts.isOptional)
        {
            NSString *format_error = [NSString stringWithFormat:@"%@:%@ can not be empty", NSStringFromClass(self.class),ppDetail.name];
            return herr(kDataFormatErrorCode, format_error);
        }
    }
    else if ([value isKindOfClass:[NSString class]])
    {
        
        if ([ppDetail.typeString isEqualToString:NSStringFromClass([NSString class])] || [ppDetail.typeString isEqualToString:NSStringFromClass([NSMutableString class])])
        {
            [self setValue:[value stringValue] forKey:ppDetail.name];
        }
        else if (!ppDetail.isObj && propertyExts.isAutocast)
        {
            //基本类型
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
                NSString *format_error = [NSString stringWithFormat:@"%@:%@ value is out of scope (%@, %@)", NSStringFromClass(self.class), ppDetail.name, propertyExts.from, propertyExts.to];
                return herr(kDataFormatErrorCode, format_error);
            }
        }
        else if (ppDetail.isObj && propertyExts.isAutocast && [ppDetail.typeString isEqualToString:NSStringFromClass([NSNumber class])])
        {
            //NSNumber
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
                NSString *format_error = [NSString stringWithFormat:@"%@:%@ value is out of scope (%@, %@)", NSStringFromClass(self.class), ppDetail.name, propertyExts.from, propertyExts.to];
                return herr(kDataFormatErrorCode, format_error);
            }
        }
        else if (ppDetail.isObj && propertyExts.isAutocast && [ppDetail.typeString isEqualToString:NSStringFromClass([NSDate class])])
        {
            //NSDate
            double date = [value floatValue];
            if ([propertyExts isInRange:@(date)])
            {
                [self setValue:[NSDate dateWithTimeIntervalSince1970:date] forKey:ppDetail.name];
            }
            else
            {
                NSString *format_error = [NSString stringWithFormat:@"%@:%@ value is out of scope (%@, %@)", NSStringFromClass(self.class), ppDetail.name, propertyExts.from, propertyExts.to];
                return herr(kDataFormatErrorCode, format_error);
            }
        }
        else
        {
            NSString *format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
            return herr(kDataFormatErrorCode, format_error);
        }
        
        
    }
    else if ([value isKindOfClass:[NSNumber class]])
    {
        
        if (!ppDetail.isObj || [ppDetail.typeString isEqualToString:NSStringFromClass([NSNumber class])])
        {
            if ([propertyExts isInRange:value])
            {
                [self setValue:value forKey:ppDetail.name];
            }
            else
            {
                NSString *format_error = [NSString stringWithFormat:@"%@:%@value is out of scope(%@, %@)", NSStringFromClass(self.class), ppDetail.name, propertyExts.from, propertyExts.to];
                return herr(kDataFormatErrorCode, format_error);
            }
        }
        else if (propertyExts.isAutocast && ([ppDetail.typeString isEqualToString:NSStringFromClass([NSString class])] || [ppDetail.typeString isEqualToString:NSStringFromClass([NSMutableString class])]))
        {
            //NSString
            [self setValue:[value stringValue] forKey:ppDetail.name];
        }
        else if (propertyExts.isAutocast && ([ppDetail.typeString isEqualToString:NSStringFromClass([NSDate class])]))
        {
            //NSDate
            if ([propertyExts isInRange:value])
            {
                [self setValue:[NSDate dateWithTimeIntervalSince1970:[value doubleValue]] forKey:ppDetail.name];
            }
            else
            {
                NSString *format_error = [NSString stringWithFormat:@"%@:%@value is out of scope(%@, %@)", NSStringFromClass(self.class), ppDetail.name, propertyExts.from, propertyExts.to];
                return herr(kDataFormatErrorCode, format_error);
            }
        }
        else
        {
            NSString *format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
            return herr(kDataFormatErrorCode, format_error);
        }
        
    }
    else if ([value isKindOfClass:[NSArray class]])
    {
        if (!ppDetail.isObj)
        {
            NSString *format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
            return herr(kDataFormatErrorCode, format_error);
        }
        if (![ppDetail.typeString isEqualToString:NSStringFromClass([NSArray class])] &&
            ![ppDetail.typeString isEqualToString:NSStringFromClass([NSMutableArray class])])
        {
            NSString *format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
            return herr(kDataFormatErrorCode, format_error);
        }
        
        
        NSMutableArray *objs = [NSMutableArray new];
        for (id arrayItem in (NSArray *)value)
        {
            NSError *err;
            Class theClass = [self h_classInArray:arrayItem ppDetail:ppDetail error:&err];
            if (err) return err;
            if (!theClass) continue;
            
            if (theClass != [arrayItem class])
            {
                if ([arrayItem isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *dict2 = arrayItem;
                    id obj = [self h_createObjectWithClass:theClass];
                    NSError *err = [obj h_setWithDictionary:dict2 enableKeyMap:enableKeyMap couldEmpty:couldEmpty];
                    if (err)
                    {
                        return err;
                    }
                    else
                    {
                        [objs addObject:obj];
                    }
                    
                }
                else
                {
                    NSString *format_error = [NSString stringWithFormat:@"%@:%@ must be NSDictionary type", NSStringFromClass(self.class), ppDetail.name];
                    return herr(kDataFormatErrorCode, format_error);
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
            NSString *format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
            return herr(kDataFormatErrorCode, format_error);
        }
        if ([ppDetail.typeString isEqualToString:NSStringFromClass([NSString class])] ||
            [ppDetail.typeString isEqualToString:NSStringFromClass([NSNumber class])] ||
            [ppDetail.typeString isEqualToString:NSStringFromClass([NSArray class])] ||
            [ppDetail.typeString isEqualToString:NSStringFromClass([NSMutableArray class])])
        {
            NSString *format_error = [NSString stringWithFormat:@"%@:%@ must be %c%@ type", NSStringFromClass(self.class), ppDetail.name, ppDetail.typeCode ,ppDetail.typeString];
            return herr(kDataFormatErrorCode, format_error);
        }
        NSError *err;
        Class theClass = [self h_classForDictionary:value ppDetail:ppDetail error:&err];
        if (err) return err;
        
        if (theClass == [value class])
        {
            [self setValue:value forKey:ppDetail.name];
        }
        else
        {
            id obj = [self h_createObjectWithClass:theClass];
            NSError *err = [obj h_setWithDictionary:value enableKeyMap:enableKeyMap couldEmpty:couldEmpty];
            if (err)
            {
                return err;
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
            NSString *format_error = [NSString stringWithFormat:@"%@:%@ is unsupport type %@", NSStringFromClass(self.class), ppDetail.name, NSStringFromClass([value class])];
            return herr(kDataFormatErrorCode, format_error);
        }
        else //value has converted
        {
            [self setValue:value forKey:ppDetail.name];
        }
    }
    return nil;
}

- (id)h_preMapValue:(id)value forKey:(NSString *)key
{
    return value;
}
- (Class)h_getClassWithDivideTypeForItem:(id)item propertyExts:(HDOPropertyExt *)propertyExts ppName:(NSString *)ppName error:(NSError **)error
{
    if ([item isKindOfClass:[NSDictionary class]])
    {
        if ([propertyExts.divideType count] < 3)
        {
            NSString *format_error = [NSString stringWithFormat:@"%@的HNDividedType参数个数至少是3个", ppName];
            *error = herr(kDataFormatErrorCode, format_error);
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
                        NSString *format_error = [NSString stringWithFormat:@"%@的HNDividedType参数个数错误", ppName];
                        *error = herr(kDataFormatErrorCode, format_error);
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
        NSString *format_error = [NSString stringWithFormat:@"%@对应的数据并不是一个字典", ppName];
        *error = herr(kDataFormatErrorCode, format_error);
        return nil;
    }
}
- (Class)h_classInArray:(id)item ppDetail:(HPropertyDetail *)ppDetail error:(NSError **)error
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
            return [self h_getClassWithDivideTypeForItem:item propertyExts:propertyExts ppName:ppDetail.name error:error];
        }
        else
        {
            //            NSAssert(NO, @"you did not specified a type in array");
            return [item class];
        }
    }
}
- (Class)h_classForDictionary:(NSDictionary *)item ppDetail:(HPropertyDetail *)ppDetail error:(NSError **)error
{
    //innerType has highest prioruty
    HDOPropertyExt *propertyExts = [[HDOPropertyExt alloc] initWithObjs:[[self class] annotations:ppDetail.name]];
    if (propertyExts.innerType)
    {
        return propertyExts.innerType;
    }
    else if (propertyExts.divideType)
    {
        Class theClass = [self h_getClassWithDivideTypeForItem:item propertyExts:propertyExts ppName:ppDetail.name error:error];
        if (error && *error) return nil;
        if (!theClass)
        {
            NSString *format_error = [NSString stringWithFormat:@"can not decide the type of %@", ppDetail.name];
            *error = herr(kDataFormatErrorCode, format_error);
            return nil;
        }
        else return theClass;
    }
    else
    {
        if ([ppDetail.typeString isEqualToString:@""])
        {
            NSAssert(NO, @"you did not specified a type of a dictionary");
            return [item class];
        }
        else
        {
            Class theClass = NSClassFromString(ppDetail.typeString);
            if (!theClass)
            {
                NSString *format_error = [NSString stringWithFormat:@"%@ type is not exsit", ppDetail.typeString];
                *error = herr(kDataFormatErrorCode, format_error);
                return nil;
            }
            else return theClass;
        }
    }
}
- (id)h_createObjectWithClass:(Class)cls {
    return [cls new];
}
@end
