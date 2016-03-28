//
//  HNSystemCacheStrategy.m
//  HAccess
//
//  Created by zhangchutian on 16/3/25.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HNSystemCacheStrategy.h"

@implementation HNSystemCacheStrategy
+ (instancetype)create:(NSURLRequestCachePolicy)systemCachePolicy
{
    HNSystemCacheStrategy *cacheStrategy = [HNSystemCacheStrategy new];
    cacheStrategy.policy = systemCachePolicy;
    return cacheStrategy;
}
@end
