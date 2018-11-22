//
//  HNQueueManager.m
//  TestDemoCocoaPod
//
//  Created by jeremyLyu on 14-9-17.
//  Copyright (c) 2014年 jeremyLyu. All rights reserved.
//

#import "HNQueueManager.h"
#import <Hodor/HGCDext.h>
#import <Hodor/HDefines.h>

@interface HNQueue ()
@property (nonatomic) NSString *name;
@property (nonatomic) NSInteger concurrent;
@property (nonatomic) dispatch_queue_t dataQueue;
@property (nonatomic) NSMutableArray *waitingPool;
@property (nonatomic) NSMutableArray *runingPool;
@end

@implementation HNQueue

- (instancetype)initWithConcurrent:(NSInteger)concurrent name:(NSString *)name
{
    self = [super init];
    if (self) {
        _concurrent = concurrent;
        NSString *queueName = [NSString stringWithFormat:@"com.hnetwork.hnqueue.%@", name];
        char *queueNameStr = (char *)[queueName cStringUsingEncoding:NSUTF8StringEncoding];
        _dataQueue = hCreateQueue(queueNameStr, DISPATCH_QUEUE_SERIAL);
        _name = name;
        _waitingPool = [NSMutableArray new];
        _runingPool = [NSMutableArray new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinish:) name:HNQueueTaskFinishNotification object:nil];
    }
    return self;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)addTask:(NSURLSessionTask *)task
{
    asyncAtQueue(self.dataQueue, ^{
        [self.waitingPool addObject:task];
        [self flushWaitingPool];
    });
}
- (void)cancelAllTask
{
    asyncAtQueue(self.dataQueue, ^{
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
    NSString *queueName = noti.userInfo[@"queue"];
    if (![queueName isEqual:self.name]) return;
    NSURLSessionTask *targetTask = noti.userInfo[@"data"];
    if (!targetTask) return;
    asyncAtQueue(self.dataQueue, ^{
        [self.runingPool removeObject:targetTask];
        [self.waitingPool removeObject:targetTask];
        if (self.runingPool.count == 0 && self.waitingPool.count == 0)
        {
            if (self.emptyCallback) self.emptyCallback(self);
        }
        [self flushWaitingPool];
    });
}

- (void)flushWaitingPool
{
    asyncAtQueue(self.dataQueue, ^{
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
            [self.waitingPool removeObjectAtIndex:0];
            [task resume];
            [self _flushWaitingPool];
        }
    }
}
@end

@interface HNQueueManager()
//queue index
@property (nonatomic) NSMutableDictionary *queueDict;
@property (nonatomic) NSMutableDictionary *queueCallbackDict;
@property (nonatomic) dispatch_queue_t myQueue;
@end

@implementation HNQueueManager

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _globalQueue = [[HNQueue alloc] initWithConcurrent:10 name:@"global"];
        _queueDict = [NSMutableDictionary new];
        _queueCallbackDict = [NSMutableDictionary new];
        _myQueue = hCreateQueue("HNQueueManager.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - public methods

+ (instancetype)instance
{
    static dispatch_once_t onceToken;
    static HNQueueManager* requestManager = nil;
    dispatch_once(&onceToken, ^{
        requestManager = [[HNQueueManager alloc] init];
    });
    return requestManager;
}

+ (void)destoryOperationQueueWithName:(NSString *)name
{
    syncAtQueue([HNQueueManager instance].myQueue, ^{
        HNQueue* operationQueue = [[HNQueueManager instance].queueDict valueForKey:name];
        if(operationQueue)
        {
            [operationQueue cancelAllTask];
            [[HNQueueManager instance].queueDict setValue:nil forKey:name];
        }
    });
}

+ (void)initQueueWithName:(NSString *)queueName maxMaxConcurrent:(NSInteger)maxMaxConcurrent
{
    syncAtQueue([HNQueueManager instance].myQueue, ^{
        [[self instance] getOperationQueueWithName:queueName maxMaxConcurrent:maxMaxConcurrent];
    });
}
+ (void)queue:(NSString *)queueName finish:(void(^)(id sender))finish
{
    syncAtQueue([HNQueueManager instance].myQueue, ^{
        [[self instance] queue:queueName finish:finish];
    });
}
//get a queue by queue name
- (HNQueue*)getOperationQueueWithName:(NSString*)name maxMaxConcurrent:(NSInteger)maxMaxConcurrent
{
    HNQueue* operationQueue = [self.queueDict valueForKey:name];
    if(operationQueue == nil)
    {
        operationQueue = [[HNQueue alloc] initWithConcurrent:maxMaxConcurrent name:name];
        @weakify(self)
        [operationQueue setEmptyCallback:^(HNQueue *sender){
            @strongify(self)
            asyncAtQueue(self.myQueue, ^{
                NSArray *callbacks = self.queueCallbackDict[sender.name];
                for (simple_callback aCallback in callbacks)
                {
                    aCallback(sender.name);
                }
                [self.queueCallbackDict removeObjectForKey:sender.name];
            });
        }];
        [self.queueDict setValue:operationQueue forKey:name];
    }
    return operationQueue;
}

- (HNQueue*)getOperationQueueWithName:(NSString*)name
{
    __block HNQueue* operationQueue;
    
    syncAtQueue(self.myQueue, ^{
        operationQueue = [self getOperationQueueWithName:name maxMaxConcurrent:1];
    });
    return operationQueue;
}
- (void)queue:(NSString *)name finish:(simple_callback)finish
{
    if (name.length == 0 || finish == nil) return;
    NSMutableArray *callbacks = self.queueCallbackDict[name];
    if (!callbacks)
    {
        callbacks = [NSMutableArray new];
        self.queueCallbackDict[name] = callbacks;
    }
    [callbacks addObject:finish];
}
@end
