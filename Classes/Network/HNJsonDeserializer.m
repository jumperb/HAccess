//
//  HNJsonDeserializer.m
//  HAccess
//
//  Created by zhangchutian on 16/3/9.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HNJsonDeserializer.h"
#import "NSError+ext.h"
#import "NSData+ext.h"

@implementation HNJsonDeserializer
@synthesize deserializeKeyPath;
- (id)preprocess:(id)rudeData
{
    if (![rudeData isKindOfClass:[NSData class]])
    {
        NSString *errorMsg = [NSString stringWithFormat:@"HNJsonDeserializer: need NSData as input but your data is '%@'", NSStringFromClass([rudeData class])];
        return herr(kDataFormatErrorCode, errorMsg);
    }
    id jsonValue = [rudeData JSONValue];
    if (!jsonValue)
    {
        return [NSError errorWithDomain:@"com.haccess.HNJsonDeserializer"
                                   code:kDataFormatErrorCode
                            description:@"HNJsonDeserializer: json decode fail"];
    }
    
    return jsonValue;
}
- (id)deserialization:(id)rudeData
{
    id jsonValue = rudeData;
    if (self.deserializeKeyPath)
    {
        jsonValue = [jsonValue valueForKeyPath:self.deserializeKeyPath];
        if (!jsonValue)
        {
            return [NSError errorWithDomain:@"com.haccess.HNJsonDeserializer"
                                       code:kDataFormatErrorCode
                                description:[NSString stringWithFormat:@"target path is not exist%@",self.deserializeKeyPath]];
        }
    }
    return jsonValue;
}
- (NSString *)mockFileType
{
    return @"json";
}
@end


#pragma mark - deserialize
#import "HDeserializableObject.h"

@interface HNEntityDeserializer ()
@property (nonatomic) Class entityClass;
@end

@implementation HNEntityDeserializer

+ (instancetype)deserializerWithClass:(Class)aClass
{
    HNEntityDeserializer *obj = [self new];
    obj.entityClass = aClass;
    return obj;
}
- (id)deserialization:(id)rudeData
{
    rudeData = [super deserialization:rudeData];
    if ([rudeData isKindOfClass:[NSError class]]) return rudeData;
    
    if(self.entityClass == NULL)
    {
        NSString *errorMsg = [NSString stringWithFormat:@"%s, can't get the entity class", __FUNCTION__];
        return herr(kInnerErrorCode, errorMsg);
    }
    //create entity
    
    HDeserializableObject *entity = (HDeserializableObject *)[[self.entityClass alloc]init];
    if (![entity isKindOfClass:[HDeserializableObject class]])
    {
        
        NSString *errorMsg = [NSString stringWithFormat:@"%s, %@ is not a subclass of HDeserializableObject", __FUNCTION__, NSStringFromClass(self.entityClass)];
        return herr(kInnerErrorCode, errorMsg);
    }
    
    
    [entity setWithDictionary:rudeData];
    if (entity.format_error)
    {
        return [NSError errorWithDomain:@"com.haccess.HNJsonDeserializer.HNEntityDeserializer" code:kDataFormatErrorCode description:entity.format_error];
    }
    else return entity;
    
}
@end






@interface HNArrayDeserializer ()
@property (nonatomic) Class objClass;
@end

@implementation HNArrayDeserializer

+ (instancetype)deserializerWithClass:(Class)aClass
{
    HNArrayDeserializer *obj = [self new];
    obj.objClass = aClass;
    return obj;
}
- (Class)classForItem:(NSDictionary *)dict
{
    return self.objClass;
}
- (id)deserialization:(id)rudeData
{
    rudeData = [super deserialization:rudeData];
    if ([rudeData isKindOfClass:[NSError class]]) return rudeData;
    
    if (![rudeData isKindOfClass:[NSArray class]])
    {
        NSString *errInfo = [NSString stringWithFormat:@"%@:%@", NSStringFromClass(self.class), @"expect a NSArray"];
        return [NSError errorWithDomain:@"com.haccess.HNJsonDeserializer.HNArrayDeserializer" code:kDataFormatErrorCode description:errInfo];
    }
    NSArray *dataArray = rudeData;
    NSMutableArray *res = [NSMutableArray new];
    for (NSDictionary *dict in dataArray)
    {
        Class targetClass = [self classForItem:dict];
        if(targetClass == NULL)
        {
            NSString *errorMsg = [NSString stringWithFormat:@"%@: cannot get entity class", NSStringFromClass(self.class)];
            return herr(kInnerErrorCode, errorMsg);
        }
        
        if (![targetClass isSubclassOfClass:[HDeserializableObject class]])
        {
            NSString *errorMsg = [NSString stringWithFormat:@"%@: is not subclass of HDeserializableObject", NSStringFromClass(self.class)];
            return herr(kInnerErrorCode, errorMsg);
        }
        
        HDeserializableObject *entity = (HDeserializableObject *)[[targetClass alloc]init];
        [entity setWithDictionary:dict];
        if (entity.format_error)
        {
            NSString *errInfo = [NSString stringWithFormat:@"%@:%@", NSStringFromClass(self.class), entity.format_error];
            return [NSError errorWithDomain:@"com.haccess.HNJsonDeserializer.HNArrayDeserializer" code:kDataFormatErrorCode description:errInfo];
        }
        [res addObject:entity];
    }
    return res;
}

@end

@interface HNManualDeserializer ()
@property (nonatomic, copy) DeserializeBlock block;
@end

@implementation HNManualDeserializer

+ (instancetype)deserializerWithBlock:(DeserializeBlock)block
{
    HNManualDeserializer *obj = [self new];
    obj.block = block;
    return obj;
}
- (id)deserialization:(id)rudeData
{
    rudeData = [super deserialization:rudeData];
    if ([rudeData isKindOfClass:[NSError class]]) return rudeData;
    if (self.block) return self.block(rudeData);
    else return nil;
}
@end