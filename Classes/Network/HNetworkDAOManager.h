//
//  HNetworkDAOManager.h
//  TestDemoCocoaPod
//
//  Created by jeremyLyu on 14-9-17.
//  Copyright (c) 2014年 jeremyLyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>


typedef void (^HNProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);

/*
 *  this is a network manager base on AFNetWorking
 */

@interface HNetworkDAOManager: NSObject
//singleton
+ (instancetype)instance;
@property (nonatomic) NSTimeInterval timeoutInterval;
@property (nonatomic) BOOL shouldContinueInBack;
@property (nonatomic) NSString *fileDownloadPath;
@property (nonatomic) NSDictionary *headParameters;
//request
- (AFHTTPRequestOperation*)requestWithURLString:(NSString*)urlString
                                     parameters:(id)parameters
                                      queueName:(NSString*)queueName
                                           mode:(NSString*)mode
                                         sucess:(void(^)(AFHTTPRequestOperation* operation, id responseObject))sucess
                                        failure:(void(^)(AFHTTPRequestOperation* operation, NSError* error))failure
                                  progressBlock:(HNProgressBlock)progressBlock;
//distroy queue
- (void)destoryOperationQueueWithName:(NSString*)name;

/**
 *  init queue manually
 *
 *  @param queueName
 *  @param maxMaxConcurrent
 */
+ (void)initQueueWithName:(NSString *)queueName maxMaxConcurrent:(NSInteger)maxMaxConcurrent;
@end
