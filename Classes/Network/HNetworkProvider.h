//
//  HNetworkProvider.h
//  HAccess
//
//  Created by zhangchutian on 16/3/21.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^HNPSuccessCallback)(id sender, NSURLResponse *response, NSData *data);
typedef void (^HNPFailCallback)(id sender, NSURLResponse *response, NSError *error);
typedef void (^HNProgressBlock)(id sender, double progress);
typedef void (^HNPWillSendCallback)(NSMutableURLRequest *request);


#define HNetworkProviderRegKey @"HNetworkProviderRegKey"

@protocol HNetworkProvider <NSObject>
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
- (NSOperation *)sendRequest;
- (void)cancel;
@end
