//
//  HNetworkDAOManager.m
//  TestDemoCocoaPod
//
//  Created by jeremyLyu on 14-9-17.
//  Copyright (c) 2014年 jeremyLyu. All rights reserved.
//

#import "HNetworkDAOManager.h"
#import <AFNetworking/AFNetworking.h>
#import "HNetworkDAO.h"

@interface HNetworkDAOManager()
{
    AFHTTPResponseSerializer* _responseSerializer;
    NSOperationQueue* _operationQueue;
    AFNetworkReachabilityManager* _reachabilityManager;
    dispatch_queue_t _completionQueue;
    
}
//queue index
@property (nonatomic) NSMutableDictionary* queueDict;
@end

@implementation HNetworkDAOManager

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _timeoutInterval = 30;
        _responseSerializer = [AFHTTPResponseSerializer serializer];
        _operationQueue = [[NSOperationQueue alloc] init];
        _reachabilityManager = [AFNetworkReachabilityManager sharedManager];
        _queueDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    _timeoutInterval = timeoutInterval;
}

#pragma mark - public methods

+ (id)instance
{
    static dispatch_once_t onceToken;
    static HNetworkDAOManager* requestManager = nil;
    dispatch_once(&onceToken, ^{
        requestManager = [[HNetworkDAOManager alloc] init];
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
//request
- (AFHTTPRequestOperation*)requestWithURLString:(NSString*)urlString
                                     parameters:(id)parameters
                                      queueName:(NSString*)queueName
                                           mode:(NSString*)mode
                                         sucess:(void(^)(AFHTTPRequestOperation* operation, id responseObject))sucess
                                        failure:(void(^)(AFHTTPRequestOperation* operation, NSError* error))failure
                                  progressBlock:(HNProgressBlock)progressBlock
{
    //1.get a queue operationQueue
    NSOperationQueue* operataionQueue = nil;
    if(queueName)
        operataionQueue = [self getOperationQueueWithName:queueName];
    else
        operataionQueue = _operationQueue;
    AFHTTPResponseSerializer *responseSerializer = nil;
    if (!self.fileDownloadPath)
    {
        //use json serializer by default
        responseSerializer = [AFJSONResponseSerializer serializer];
        NSMutableSet *acceptableTypes = [[NSMutableSet alloc] initWithSet:responseSerializer.acceptableContentTypes];
        //add type edit by goingta 2015.12.16
        [acceptableTypes addObject:@"text/html"];
        [acceptableTypes addObject:@"text/plain"];
        responseSerializer.acceptableContentTypes = acceptableTypes;
    }
    //param
    NSMutableDictionary* parametersDict = [NSMutableDictionary new];
    NSMutableDictionary* multiDataDict = [NSMutableDictionary new];
    for (NSString *key in parameters)
    {
        id value = parameters[key];
        if ([value isKindOfClass:[HNetworkMultiDataObj class]])
        {
            [multiDataDict setObject:value forKey:key];
        }
        else
        {
            [parametersDict setObject:value forKey:key];
        }
    }
    
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    //timeout
    requestSerializer.timeoutInterval = self.timeoutInterval;
    //HEAD
    for (NSString *key in self.headParameters)
    {
        [requestSerializer setValue:self.headParameters[key] forHTTPHeaderField:key];
    }
    //2.get an Operation
    NSMutableURLRequest* request = nil;
    //multi Data
    if(multiDataDict.allKeys.count > 0)
    {
        request = [requestSerializer multipartFormRequestWithMethod:@"POST" URLString:urlString parameters:parametersDict constructingBodyWithBlock:^(id <AFMultipartFormData> multipartFormData)
                   {
                       //get file
                       for(NSString* key in multiDataDict.allKeys)
                       {
                           HNetworkMultiDataObj* multiDataObj = [multiDataDict valueForKey:key];
                           if(multiDataObj.datas)
                           {
                               //datas
                               NSString* newKey = [NSString stringWithFormat:@"%@[]",key];
                               for(NSData* data in multiDataObj.datas)
                               {
                                   [multipartFormData appendPartWithFileData:data name:newKey fileName:multiDataObj.fileName mimeType:multiDataObj.mimeType];
                               }
                           }
                           else if(multiDataObj.data)
                           {
                               //data
                               [multipartFormData appendPartWithFileData:multiDataObj.data name:key fileName:multiDataObj.fileName mimeType:multiDataObj.mimeType];
                           }
                           else
                           {
                               //url
                               if(multiDataObj.filePath == nil)
                               {
                                   NSLog(@"%s:file not found", __FUNCTION__);
                                   continue ;
                               }
                               //is filePath validate
                               if(![[NSFileManager defaultManager] fileExistsAtPath:multiDataObj.filePath])
                               {
                                   NSLog(@"%s: file not found", __FUNCTION__);
                                   continue;
                               }
                               
                               NSURL* url = [NSURL fileURLWithPath:multiDataObj.filePath];
                               NSError* error = nil;
                               BOOL isFailed =  [multipartFormData  appendPartWithFileURL:url name:key fileName:multiDataObj.fileName mimeType:multiDataObj.mimeType error:&error];
                               if(isFailed)
                               {
                                   NSLog(@"multiDataError:%@", error.localizedDescription);
                               }
                           }
                       }
                   }error:nil];
    }
    else
    {
        request = [requestSerializer requestWithMethod:mode URLString:urlString parameters:parametersDict error:nil];
    }
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    //print param
    NSMutableString *paramString = [NSMutableString new];
    for (NSString *key in parametersDict)
    {
        if (paramString.length > 0) [paramString appendFormat:@"&"];
        [paramString appendFormat:@"%@=%@", key, [parametersDict[key] stringValue]];
    }
    
    NSLog(@" ");
    NSLog(@"#### send request");
    NSLog(@"#### %@ %@",mode, urlString);
    if (paramString.length > 0)
    {
        NSLog(@"#### param: %@", paramString);
    }
    if (multiDataDict.count > 0)
    {
        NSLog(@"#### multiData: %@", paramString);
    }
    NSLog(@" ");
    
    AFHTTPRequestOperation* operation = [self HTTPRequestOperationWithRequest:request responseSerializer:responseSerializer success:sucess failure:failure];
    
    if (self.fileDownloadPath)
    {
        [operation setDownloadProgressBlock:progressBlock];
        [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:self.fileDownloadPath append:NO]];
    }
    else if (multiDataDict.count > 0)
    {
        [operation setUploadProgressBlock:progressBlock];
    }
    
    
    if (_shouldContinueInBack)
    {
        [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    }
    //run opration
    [operataionQueue addOperation:operation];
    return operation;
}

#pragma mark - enter methods
//get requestOperation
- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                         responseSerializer:(AFHTTPResponseSerializer*)responseSerializer
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    //get requestOperation
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    //set seriallzer
    if (responseSerializer) operation.responseSerializer = responseSerializer;
    [operation setCompletionBlockWithSuccess:success failure:failure];
    operation.completionQueue = _completionQueue;
    return operation;
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
