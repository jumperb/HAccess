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
@property (nonatomic) dispatch_queue_t myQueue;
@end

@implementation HNQueueManager

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _globalQueue = [[NSOperationQueue alloc] init];
        _queueDict = [[NSMutableDictionary alloc] init];
        _myQueue = dispatch_queue_create("HNQueueManager.queue", DISPATCH_QUEUE_SERIAL);
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
    dispatch_sync(self.myQueue, ^{
        NSOperationQueue* operationQueue = [self.queueDict valueForKey:name];
        if(operationQueue)
        {
            [operationQueue cancelAllOperations];
            [self.queueDict setValue:nil forKey:name];
        }
    });
}

+ (void)initQueueWithName:(NSString *)queueName maxMaxConcurrent:(NSInteger)maxMaxConcurrent
{
    dispatch_sync([HNQueueManager instance].myQueue, ^{
        [[self instance] getOperationQueueWithName:queueName maxMaxConcurrent:maxMaxConcurrent];
    });
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
    __block NSOperationQueue* operationQueue;
    dispatch_sync(self.myQueue, ^{
        operationQueue = [self getOperationQueueWithName:name maxMaxConcurrent:1];
    });
    return operationQueue;
}
@end
