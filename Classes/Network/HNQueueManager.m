//
//  HNQueueManager.m
//  TestDemoCocoaPod
//
//  Created by jeremyLyu on 14-9-17.
//  Copyright (c) 2014年 jeremyLyu. All rights reserved.
//

#import "HNQueueManager.h"

@interface HNQueueManager()
//queue index
@property (nonatomic) NSMutableDictionary* queueDict;
@end

@implementation HNQueueManager

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _globalQueue = [[NSOperationQueue alloc] init];
        _queueDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - public methods

+ (id)instance
{
    static dispatch_once_t onceToken;
    static HNQueueManager* requestManager = nil;
    dispatch_once(&onceToken, ^{
        requestManager = [[HNQueueManager alloc] init];
    });
    return requestManager;
}

- (void)destoryOperationQueueWithName:(NSString *)name
{
    NSOperationQueue* operationQueue = [self.queueDict valueForKey:name];
    if(operationQueue)
    {
        [operationQueue cancelAllOperations];
        [self.queueDict setValue:nil forKey:name];
    }
}

+ (void)initQueueWithName:(NSString *)queueName maxMaxConcurrent:(NSInteger)maxMaxConcurrent
{
    [[self instance] getOperationQueueWithName:queueName maxMaxConcurrent:maxMaxConcurrent];
}

//get a queue by queue name
- (NSOperationQueue*)getOperationQueueWithName:(NSString*)name maxMaxConcurrent:(NSInteger)maxMaxConcurrent
{
    NSOperationQueue* operationQueue = [self.queueDict valueForKey:name];
    if(operationQueue == nil)
    {
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:maxMaxConcurrent];
        [self.queueDict setValue:operationQueue forKey:name];
    }
    return operationQueue;
}

- (NSOperationQueue*)getOperationQueueWithName:(NSString*)name
{
    return [self getOperationQueueWithName:name maxMaxConcurrent:1];
}
@end
