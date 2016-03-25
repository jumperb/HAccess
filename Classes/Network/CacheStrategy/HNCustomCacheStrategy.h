//
//  HNCustomCacheStrategy.h
//  HAccess
//
//  Created by zhangchutian on 16/3/25.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNCacheStrategy.h"

typedef void(^HNCustomCacheCallback)(BOOL shouldRequest, NSData *cachedData);

@interface HNCustomCacheStrategy : NSObject <HNCacheStrategy>
//you don,t need set this property, it is setted by HNetworkDAO
@property (nonatomic) NSString *cacheKey;
// how long the cache lives, default is a week
@property (nonatomic) long long cacheDuration;
// excute cache logic
- (void)cacheLogic:(HNCustomCacheCallback)cacheCallback;
// write
- (void)writeCache:(NSData *)data;
// is my cache usable, if not exist or cache is too old return NO
- (BOOL)isCacheUseable:(NSString *)cacheKey;
@end

@interface HNCacheTypeOnlyWrite : HNCustomCacheStrategy
+ (instancetype)createWtihCacheDuration:(long long)cacheDuration;
@end

@interface HNCacheTypeBoth : HNCustomCacheStrategy
+ (instancetype)createWtihCacheDuration:(long long)cacheDuration;
@end


@interface HNCacheTypeAlternative : HNCustomCacheStrategy
+ (instancetype)createWtihCacheDuration:(long long)cacheDuration nextRequstInterval:(long long)nextRequestInterval;
@end