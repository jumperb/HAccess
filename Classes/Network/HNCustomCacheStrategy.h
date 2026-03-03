//
//  HNCustomCacheStrategy.h
//  HAccess
//
//  Created by zhangchutian on 16/3/25.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNCacheStrategy.h"

typedef void(^HNCustomCacheCallback)(BOOL shouldContinue, NSData *cachedData);


/**
 *  this is custom cache strategy, and you can write a subclass yourself
 */
@interface HNCustomCacheStrategy : NSObject <HNCacheStrategy>
//you don,t need set this property, it is setted by HNetworkDAO
@property (nonatomic) NSString *cacheKey;
//how long the cache lives, default is a week
@property (nonatomic) long long cacheDuration;
//excute cache logic before request
- (void)cacheLogic:(HNCustomCacheCallback)cacheCallback;
//excute cache logic on request fail
- (void)cacheLogicOnFail:(NSError *)error cacheCallback:(HNCustomCacheCallback)cacheCallback;
//handle response, mostly we just write cache
- (NSData *)handleRespInfo:(NSData *)respInfo;
//is my cache usable, if not exist or cache is too old return NO
- (BOOL)isCacheUseable:(NSString *)cacheKey;
//deleteCache
- (void)deleteCache;
@end


/**
 *  not read any cache, directly send request 
 *  but it will save a cache if success
 */
@interface HNCacheTypeOnlyWrite : HNCustomCacheStrategy
+ (instancetype)createWtihCacheDuration:(long long)cacheDuration;
@end


/**
 *  if cache is usable, read the cache, and it will directly send request, 
 *  and it will save a cache if success
 */
@interface HNCacheTypeBoth : HNCustomCacheStrategy
+ (instancetype)createWtihCacheDuration:(long long)cacheDuration;
@end


/**
 *  if cache is usable and now time is not over 'nextRequestInterval' , read cache only, 
 *  else send request and save a cache if success
 */
@interface HNCacheTypeAlternative : HNCustomCacheStrategy
+ (instancetype)createWtihNextRequstInterval:(long long)nextRequestInterval;
@end


/**
 * When the request fails, if there is a cache, first you will get cached response for success block, then you will get a fail block
 */
@interface HNCacheTypeUseCacheOnFail : HNCustomCacheStrategy
+ (instancetype)createWtihCacheDuration:(long long)cacheDuration;
@end
