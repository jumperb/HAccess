//
//  HPropertyMgr.m
//  HAccess
//
//  Created by zhangchutian on 15/9/15.
//  Copyright (c) 2015年 zhangchutian. All rights reserved.
//

#import "HPropertyMgr.h"
#import <objc/runtime.h>
#import <HCommon.h>
#import "HDeserializableObject.h"

@interface HPropertyStructCacheData : NSObject
@property (nonatomic) NSArray *pplist;
@property (nonatomic) NSString *pplistString;
@property (nonatomic) NSArray *ppDetailList;
@end

@implementation HPropertyStructCacheData

@end

@interface HPropertyMgr ()
@property (nonatomic) NSMutableDictionary *propertyStructCache;
@end


@implementation HPropertyMgr
+ (instancetype)shared
{
    static dispatch_once_t pred;
    static HPropertyMgr *o = nil;

    dispatch_once(&pred, ^{ o = [[self alloc] init]; });
    return o;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _propertyStructCache = [[NSMutableDictionary alloc] init];
        self.strictModle = YES;
    }
    return self;
}


- (NSArray *)entityPropertylist:(NSString *)entityClassName
{
    return [self entityPropertylist:entityClassName isDepSearch:NO];
}

- (NSArray *)entityPropertylist:(NSString *)entityClassName isDepSearch:(BOOL)deepSearch;
{
    NSString *key = entityClassName;
    if (deepSearch) key = [entityClassName stringByAppendingString:@"nodeep"];
    HPropertyStructCacheData *cacheData = _propertyStructCache[key];

    if (!cacheData)
    {
        cacheData = [[HPropertyStructCacheData alloc] init];
        [_propertyStructCache setObject:cacheData forKey:key];
    }
    if (!cacheData.pplist)
    {
        NSMutableArray *pplist = [[NSMutableArray alloc] init];
        Class theClass = NSClassFromString(entityClassName);
        if (!theClass) return nil;
        while (theClass != [HDeserializableObject class]) {
            unsigned int count, i;
            objc_property_t *properties = class_copyPropertyList(theClass, &count);
            if (count)
            {
                for (i = 0; i < count; i++)
                {
                    objc_property_t property = properties[i];
                    NSString *key = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
                    if ([key isEqualToString:@"hash"]) continue;
                    else if ([key isEqualToString:@"superclass"]) continue;
                    else if ([key isEqualToString:@"description"]) continue;
                    else if ([key isEqualToString:@"debugDescription"]) continue;
                    else if ([key hasPrefix:@"tmp_"]) continue;
                    else if ([key isEqualToString:@"format_error"]) continue;
                    [pplist addObject:key];
                }
            }
            free(properties);
            if (!deepSearch) break;
            theClass = class_getSuperclass(theClass);
        }
        cacheData.pplist = pplist;
    }
    return cacheData.pplist;
}


- (NSString *)entityPropertylistString:(NSString *)entityClassName
{
    return [self entityPropertylistString:entityClassName isDepSearch:YES];
}
- (NSString *)entityPropertylistString:(NSString *)entityClassName isDepSearch:(BOOL)deepSearch;
{
    NSString *key = entityClassName;
    if (deepSearch) key = [entityClassName stringByAppendingString:@"nodeep"];
    HPropertyStructCacheData *cacheData = _propertyStructCache[key];
    if (!cacheData)
    {
        cacheData = [[HPropertyStructCacheData alloc] init];
        [_propertyStructCache setObject:cacheData forKey:key];
    }
    if (!cacheData.pplistString)
    {
        NSArray *pplist = [self entityPropertylist:entityClassName isDepSearch:deepSearch];
        NSMutableString *fields = [[NSMutableString alloc] init];
        int index = 0;
        for (NSString *p in pplist)
        {
            if (index != 0)
            {
                [fields appendString:@","];
            }
            [fields appendString:p];
            index ++;
        }
        cacheData.pplistString = fields;
    }
    return cacheData.pplistString;
}



- (NSArray *)entityPropertyDetailList:(NSString *)entityClassName isDepSearch:(BOOL)deepSearch
{
    NSString *key = entityClassName;
    if (deepSearch) key = [entityClassName stringByAppendingString:@"nodeep"];
    HPropertyStructCacheData *cacheData = _propertyStructCache[key];
    if (!cacheData)
    {
        cacheData = [[HPropertyStructCacheData alloc] init];
        [_propertyStructCache setObject:cacheData forKey:key];
    }
    if (!cacheData.ppDetailList)
    {
        NSMutableArray *detailList = [NSMutableArray new];
        Class theClass = NSClassFromString(entityClassName);
        if (!theClass) return nil;
        NSArray *pplist = [self entityPropertylist:entityClassName isDepSearch:deepSearch];
        for (NSString *p in pplist)
        {
            //get properties
            objc_property_t pp_t = class_getProperty(theClass, [p cStringUsingEncoding:NSUTF8StringEncoding]);
            if (!pp_t)
            {
                NSAssert(NO, @"can not get property attr : %@",p);
                return nil;
            }
            const char* attr = property_getAttributes(pp_t);
            //T@"Test",&,N,V_c"
            //Ti,N,V_a
            //T@"NSNumber<HEOptional>",&,N,V_z
            //T@,&,N
            unsigned long len = strlen(attr);

            if (len < 2)
            {
                NSAssert(NO, @"property attr format error : %@",p);
                return nil;
            }

            BOOL isObj = (attr[1] == '@');
            NSString *typeString = nil;
            NSString *protocalString = nil;
            BOOL hasProtocal = NO;
            char *leftJian = NULL;
            char *rightJian = NULL;



            if (isObj)
            {
                char *firstDouhao = strstr(attr, ",");
                if (firstDouhao == NULL)
                {
                    NSAssert(NO, @"property attr format error : %@",p);
                    return nil;
                }

                leftJian = strstr(attr, "<");
                rightJian = NULL;
                if (leftJian != NULL)
                {

                    rightJian = strstr(attr, ">");
                    if (rightJian == NULL)
                    {
                        NSAssert(NO, @"property attr format error : %@",p);
                        return nil;
                    }
                    hasProtocal = YES;
                }

                NSString *attrString = [NSString stringWithCString:attr encoding:NSUTF8StringEncoding];
                NSString *rudeTypeString = nil;
                if (firstDouhao - attr > 4)
                {
                    rudeTypeString = [attrString substringWithRange:NSMakeRange(3, firstDouhao - attr - 3 - 1)];
                }
                else
                {
                    rudeTypeString = @"";
                }
                if (!hasProtocal) typeString = rudeTypeString;
                else
                {
                    typeString = [attrString substringWithRange:NSMakeRange(3, leftJian - attr - 3)];
                    protocalString = [attrString substringWithRange:NSMakeRange(leftJian - attr + 1, rightJian - leftJian - 1)];
                }
            }
            HPropertyDetail *detail = [HPropertyDetail new];
            detail.name = p;
            detail.isObj = isObj;
            detail.typeCode = attr[1];
            detail.typeString = typeString;
            detail.protocalString = protocalString;
            [detailList addObject:detail];
        }
        cacheData.ppDetailList = detailList;
    }
    return cacheData.ppDetailList;
}
@end




@implementation HPropertyDetail

@end