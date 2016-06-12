//
//  HNCustomCacheStrategy.m
//  HAccess
//
//  Created by zhangchutian on 16/3/25.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HNCustomCacheStrategy.h"
#import <HFileCache.h>
#import <NSDate+ext.h>

@implementation HNCustomCacheStrategy
- (instancetype)init
{
    self = [super init];
    if (self) {
        _cacheDuration = 60*60*24*7;
    }
    return self;
}
- (BOOL)isCacheUseable:(NSString *)cacheKey
{
    BOOL cacheUsable = NO;
    if (self.cacheDuration > 0)
    {
        NSString *cachePath = [[HFileCache shareCache] cachePathForKey:cacheKey];
        if (cachePath)
        {
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:nil];
            if (fileAttributes)
            {
                NSDate *createDate = fileAttributes[NSFileCreationDate];
                long interval = [[NSDate date] timeIntervalSinceDate:createDate];
                if (interval < self.cacheDuration)
                {
                    cacheUsable = YES;
                }
            }
        }
    }
    return cacheUsable;
}
- (void)setCacheDuration:(long long)cacheDuration
{
    _cacheDuration = cacheDuration;
    if (cacheDuration > 60*60*24*30)
    {
        NSLog(@"#warning#: you set a too long duration, do you want a cache really ?");
    }
}
- (void)cacheLogic:(HNCustomCacheCallback)cacheCallback
{
    
}
- (NSData *)handleRespInfo:(id)respInfo
{
    [self writeCache:respInfo];
    return respInfo;
}
- (void)writeCache:(NSData *)data
{
    [[HFileCache shareCache] setData:data forKey:self.cacheKey
                              expire:[NSDate dateWithTimeInterval:self.cacheDuration sinceDate:[NSDate date]]];
}
@end

@implementation HNCacheTypeOnlyWrite
+ (instancetype)createWtihCacheDuration:(long long)cacheDuration
{
    HNCacheTypeOnlyWrite *cacheType = [HNCacheTypeOnlyWrite new];
    cacheType.cacheDuration = cacheDuration;
    return cacheType;
}
- (void)cacheLogic:(HNCustomCacheCallback)cacheCallback
{
    cacheCallback(YES, nil);
}
@end

@implementation HNCacheTypeBoth

+ (instancetype)createWtihCacheDuration:(long long)cacheDuration
{
    HNCacheTypeBoth *cacheType = [HNCacheTypeBoth new];
    cacheType.cacheDuration = cacheDuration;
    return cacheType;
}
- (void)cacheLogic:(HNCustomCacheCallback)cacheCallback
{
    NSData *data = nil;
    if ([self isCacheUseable:self.cacheKey])
    {
        data = [[HFileCache shareCache] dataForKey:self.cacheKey];
    }
    cacheCallback(YES, data);
}
@end


@interface HNCacheTypeAlternative ()
@property (nonatomic) long long requstInterval;
@end

@implementation HNCacheTypeAlternative
+ (instancetype)createWtihCacheDuration:(long long)cacheDuration nextRequstInterval:(long long)nextRequestInterval
{
    HNCacheTypeAlternative *cacheType = [HNCacheTypeAlternative new];
    cacheType.cacheDuration = cacheDuration;
    cacheType.requstInterval = nextRequestInterval;
    return cacheType;
}
- (void)cacheLogic:(HNCustomCacheCallback)cacheCallback
{
    NSData *data = nil;

    NSString *cachePath = [[HFileCache shareCache] cachePathForKey:self.cacheKey];
    if (cachePath)
    {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:nil];
        if (fileAttributes)
        {
            NSDate *createDate = fileAttributes[NSFileCreationDate];
            long interval = [[NSDate date] timeIntervalSinceDate:createDate];
            if (interval < self.requstInterval && interval < self.cacheDuration)
            {
                data = [[HFileCache shareCache] dataForKey:self.cacheKey];
            }
        }
    }
    cacheCallback((data == nil), data);
}
@end