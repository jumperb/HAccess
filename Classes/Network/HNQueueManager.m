//
//  HNQueueManager.m
//  TestDemoCocoaPod
//
//  Created by jeremyLyu on 14-9-17.
//  Copyright (c) 2014年 jeremyLyu. All rights reserved.
//

#import "HNQueueManager.h"

@interface HNQueue ()
@property (nonatomic) NSInteger concurrent;
@property (nonatomic) dispatch_queue_t dataQueue;
@property (nonatomic) NSMutableArray *waitingPool;
@property (nonatomic) NSMutableArray *runingPool;
@end

@implementation HNQueue

- (instancetype)initWithConcurrent:(NSInteger)concurrent
{
    self = [super init];
    if (self) {
        _concurrent = concurrent;
        _dataQueue = dispatch_queue_create("com.hnetwork.queue.dataqueue", DISPATCH_QUEUE_SERIAL);
        _waitingPool = [NSMutableArray new];
        _runingPool = [NSMutableArray new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinish:) name:HNQueueTaskFinishNotification object:nil];
    }
    return self;
}
- (instancetype)init
{
    return [self initWithConcurrent:10];
}
- (void)addTask:(NSURLSessionTask *)task
{
    dispatch_async(self.dataQueue, ^{
        [self.waitingPool addObject:task];
        [self flushWaitingPool];
    });
}
- (void)cancelAllTask
{
    dispatch_async(self.dataQueue, ^{
        for (NSURLSessionTask *task in self.waitingPool)
        {
            [task cancel];
        }
        [self.waitingPool removeAllObjects];
        for (NSURLSessionTask *task in self.runingPool)
        {
            [task cancel];
        }
        [self.runingPool removeAllObjects];
    });
}

- (void)taskFinish:(NSNotification *)noti
{
    NSURLSessionTask *targetTask = noti.userInfo[@"data"];
    if (!targetTask) return;
    dispatch_async(self.dataQueue, ^{
        [self.runingPool removeObject:targetTask];
        [self.waitingPool removeObject:targetTask];
        [self flushWaitingPool];
    });
}

- (void)flushWaitingPool
{
    dispatch_async(self.dataQueue, ^{
        [self _flushWaitingPool];
    });
}
- (void)_flushWaitingPool
{
    if (self.runingPool.count < self.concurrent)
    {
        NSURLSessionTask *task = [self.waitingPool firstObject];
        if (task)
        {
            [self.runingPool addObject:task];
            [task resume];
            [self _flushWaitingPool];
        }
    }
}
@end

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
        _globalQueue = [HNQueue new];
        _queueDict = [NSMutableDictionary new];
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
        HNQueue* operationQueue = [self.queueDict valueForKey:name];
        if(operationQueue)
        {
            [operationQueue cancelAllTask];
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
- (HNQueue*)getOperationQueueWithName:(NSString*)name maxMaxConcurrent:(NSInteger)maxMaxConcurrent
{
    HNQueue* operationQueue = [self.queueDict valueForKey:name];
    if(operationQueue == nil)
    {
        operationQueue = [[HNQueue alloc] initWithConcurrent:maxMaxConcurrent];
        [self.queueDict setValue:operationQueue forKey:name];
    }
    return operationQueue;
}

- (HNQueue*)getOperationQueueWithName:(NSString*)name
{
    __block HNQueue* operationQueue;
    dispatch_sync(self.myQueue, ^{
        operationQueue = [self getOperationQueueWithName:name maxMaxConcurrent:1];
    });
    return operationQueue;
}
@end
