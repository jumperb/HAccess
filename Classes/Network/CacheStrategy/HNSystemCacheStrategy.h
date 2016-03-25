//
//  HNSystemCacheStrategy.h
//  HAccess
//
//  Created by zhangchutian on 16/3/25.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNCacheStrategy.h"

@interface HNSystemCacheStrategy : NSObject <HNCacheStrategy>
@property (nonatomic) NSURLRequestCachePolicy policy;
+ (instancetype)create:(NSURLRequestCachePolicy)systemCachePolicy;
@end
