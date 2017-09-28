//
//  HNProvider_AF3.h
//  HAccess
//
//  Created by zct on 2017/5/22.
//  Copyright © 2017年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNetworkProvider.h"
@interface HNProvider_AF3 : NSObject <HNetworkProvider>
@property (nonatomic) NSString *urlString;
@property (nonatomic) id params;
@property (nonatomic) NSString *method;
@property (nonatomic) NSString *queueName;

@property (nonatomic) NSTimeInterval timeoutInterval;
@property (nonatomic) BOOL shouldContinueInBack;
@property (nonatomic) NSString *fileDownloadPath;
@property (nonatomic) NSDictionary *headParameters;
@property (nonatomic) NSURLRequestCachePolicy cachePolicy;

@property (nonatomic, strong) HNPSuccessCallback successCallback;
@property (nonatomic, strong) HNPFailCallback failCallback;
@property (nonatomic, strong) HNProgressBlock progressCallback;
@property (nonatomic, strong) HNPWillSendCallback willSendCallback;
@end
