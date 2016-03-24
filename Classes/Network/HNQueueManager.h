//
//  HNQueueManager.h
//  TestDemoCocoaPod
//
//  Created by jeremyLyu on 14-9-17.
//  Copyright (c) 2014年 jeremyLyu. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 *  this is a queue manager
 */

@interface HNQueueManager: NSObject
//singleton
+ (instancetype)instance;

@property (nonatomic, readonly) NSOperationQueue* globalQueue;

// get special queue
- (NSOperationQueue*)getOperationQueueWithName:(NSString*)name;
// distroy queue
- (void)destoryOperationQueueWithName:(NSString*)name;
// init queue manually
+ (void)initQueueWithName:(NSString *)queueName maxMaxConcurrent:(NSInteger)maxMaxConcurrent;
@end
