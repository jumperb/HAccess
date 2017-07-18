//
//  HNQueueManager.h
//  TestDemoCocoaPod
//
//  Created by jeremyLyu on 14-9-17.
//  Copyright (c) 2014年 jeremyLyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hodor/HCommonBlock.h>
#define HNQueueTaskFinishNotification @"HNQueueTaskFinishNotification"

@interface HNQueue : NSObject
@property (nonatomic, readonly)NSInteger maxConcurrentCount;
@property (nonatomic) simple_callback emptyCallback;

- (void)addTask:(NSURLSessionTask *)task;
- (void)cancelAllTask;
@end

/*
 *  this is a queue manager
 */

@interface HNQueueManager: NSObject
//singleton
+ (instancetype)instance;

@property (nonatomic, readonly) HNQueue* globalQueue;

// get special queue
- (HNQueue*)getOperationQueueWithName:(NSString*)name;
// distroy queue
+ (void)destoryOperationQueueWithName:(NSString*)name;
// init queue manually
+ (void)initQueueWithName:(NSString *)queueName maxMaxConcurrent:(NSInteger)maxMaxConcurrent;
// queue finish callback
+ (void)queue:(NSString *)queueName finish:(simple_callback)finish;
@end
