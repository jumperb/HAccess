//
//  HNPBDeseriralizer.m
//  HAccess
//
//  Created by goingta on 16/3/12.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HNPBDeseriralizer.h"
#import <NSError+ext.h>
#import <NSData+ext.h>
#import "GPBMessage.h"

@interface HNPBDeseriralizer ()
@property (nonatomic) Class entityClass;
@end

@implementation HNPBDeseriralizer

@synthesize deserializeKeyPath;
+ (instancetype)deserializerWithClass:(Class)aClass
{
    HNPBDeseriralizer *obj = [self new];
    obj.entityClass = aClass;
    return obj;
}

- (id)preprocess:(id)rudeData
{
    if (![rudeData isKindOfClass:[NSData class]])
    {
        NSString *errorMsg = [NSString stringWithFormat:@"HNPBDeseriralizer: need NSData as input but your data is '%@'", NSStringFromClass([rudeData class])];
        return herr(kDataFormatErrorCode, errorMsg);
    }

    return rudeData;
}

- (id)deserialization:(id)rudeData
{
    if(self.entityClass == NULL)
    {
        NSString *errorMsg = [NSString stringWithFormat:@"%s, can't get the entity class", __FUNCTION__];
        return herr(kDataFormatErrorCode, errorMsg);
    }

    NSError *err = [NSError new];

    id entity = [self.entityClass parseFromData:rudeData error:&err];

    if (err)
    {
        return herr(kDataFormatErrorCode, err.description);
    }

    return entity;
}

- (NSString *)mockFileType
{
    return @"pb";
}

@end
