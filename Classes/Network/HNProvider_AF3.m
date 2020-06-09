//
//  HNProvider_AF3.m
//  HAccess
//
//  Created by zct on 2017/5/22.
//  Copyright © 2017年 zhangchutian. All rights reserved.
//

#import "HNProvider_AF3.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <Hodor/HClassManager.h>
#import <Hodor/HDefines.h>
#import <Hodor/HGCDext.h>
#import "HNetworkMultiDataObj.h"
#import "HNQueueManager.h"

@interface HNProvider_AF3 ()
@property (nonatomic) NSURLSessionTask *myTask;
@property (nonatomic) dispatch_queue_t queue;
@end

@implementation HNProvider_AF3



HReg(HNetworkProviderRegKey)



- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        self.queue = hCreateQueue("com.hnetwork.processing", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
+ (AFHTTPResponseSerializer *)responseSerializer
{
    AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
    serializer.acceptableContentTypes = [NSSet setWithObjects:
                                         @"application/json",
                                         @"text/json",
                                         @"text/javascript",
                                         @"text/html",
                                         @"text/plain",
                                         @"application/atom+xml",
                                         @"application/xml",
                                         @"text/xml",
                                         @"image/png",
                                         @"image/jpeg", nil];
    return serializer;
}
- (AFHTTPSessionManager *)sessionManager {
    
    //    if (!self.shouldContinueInBack)
    if (1)
    {
        static AFHTTPSessionManager *manager1;
        static dispatch_once_t onceToken1;
        dispatch_once(&onceToken1, ^{
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            configuration.timeoutIntervalForRequest = 30;
            manager1 = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
            manager1.responseSerializer = [HNProvider_AF3 responseSerializer];
            
        });
        return manager1;
    }
    else
    {
        static AFHTTPSessionManager *manager2;
        static dispatch_once_t onceToken2;
        dispatch_once(&onceToken2, ^{
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.hnetwork.provider"];
            configuration.timeoutIntervalForRequest = 30;
            manager2 = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
            AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
            manager2.responseSerializer = [HNProvider_AF3 responseSerializer];
        });
        return manager2;
    }
}


- (NSURLSessionTask *)sendRequest
{
    syncAtQueue(self.queue, ^{
        NSMutableDictionary* parametersDict = nil;
        NSMutableDictionary* multiDataDict = nil;
        if ([self.params isKindOfClass:[NSDictionary class]])
        {
            parametersDict = [NSMutableDictionary new];
            multiDataDict = [NSMutableDictionary new];
            NSMutableDictionary *rudeParam = self.params;
            for (NSString *key in rudeParam)
            {
                id value = rudeParam[key];
                if ([value isKindOfClass:[HNetworkMultiDataObj class]])
                {
                    [multiDataDict setObject:value forKey:key];
                }
                else
                {
                    [parametersDict setObject:value forKey:key];
                }
            }
        }
        AFHTTPRequestSerializer *requestSerializer = nil;
        if ([self.requstContentType.lowercaseString isEqualToString:@"application/json"]) {
            requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        }
        else {
            requestSerializer = [AFHTTPRequestSerializer serializer];
        }
        //timeout
        requestSerializer.timeoutInterval = self.timeoutInterval;
        //HEAD
        for (NSString *key in self.headParameters)
        {
            [requestSerializer setValue:self.headParameters[key] forHTTPHeaderField:key];
        }
        //2.get an Operation
        NSMutableURLRequest* request = nil;
        
        @weakify(self)
        //multi Data
        if(multiDataDict.allKeys.count > 0)
        {
            
            request = [requestSerializer multipartFormRequestWithMethod:@"POST" URLString:self.urlString parameters:parametersDict constructingBodyWithBlock:^(id <AFMultipartFormData> multipartFormData)
                       {
                           @strongify(self)
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
            request = [requestSerializer requestWithMethod:self.method URLString:self.urlString parameters:parametersDict error:nil];
        }
        
        //set to body directly
        if ([self.params isKindOfClass:[NSData class]])
        {
            request.HTTPBody = self.params;
        }
        request.cachePolicy = self.cachePolicy;
        
        
        //print param
        NSMutableString *paramString = [NSMutableString new];
        for (NSString *key in parametersDict)
        {
            if (paramString.length > 0) [paramString appendFormat:@"&"];
            [paramString appendFormat:@"%@=%@", key, parametersDict[key]];
        }
        
        NSLog(@"\n\n#### send request:\n%@ %@\n%@",self.method, self.urlString, paramString.length>0?paramString:@"");
        if (multiDataDict.count > 0)
        {
            NSLog(@"\n\n#### multiData: %@", paramString);
        }
        
        if (self.willSendCallback) self.willSendCallback(request);
        NSURLSessionTask *task = [self requestTask:request progress:^(NSProgress * _Nullable progress) {
            
            @strongify(self)
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.progressCallback) self.progressCallback(self, progress.fractionCompleted);
            });
            
        } completion:^(NSURLResponse *response, id responseObject, NSError *error) {
            asyncAtQueue(self.queue, ^{
                @strongify(self)
                if (!error)
                {
                    if (self.successCallback) self.successCallback(self, response, responseObject);
                }
                else
                {
                    if (self.failCallback) self.failCallback(self, response, error);
                }
                if (self.myTask)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:HNQueueTaskFinishNotification object:nil userInfo:@{@"data":self.myTask, @"queue":self.queueName?:@"global"}];
                    self.myTask = nil;
                }
                
            });
        }];
        
        self.myTask = task;
        
        HNQueue *operataionQueue;
        if(self.queueName) operataionQueue = [[HNQueueManager instance] getOperationQueueWithName:self.queueName];
        else operataionQueue = [HNQueueManager instance].globalQueue;
        [operataionQueue addTask:self.myTask];
    });
    return self.myTask;
}
- (NSURLSessionTask *)requestTask:(NSMutableURLRequest *)request progress:(nullable void (^)(NSProgress *downloadProgress))progressBlock completion:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completion {
    
    __block NSURLSessionTask *task = nil;
    
    if (self.fileDownloadPath)
    {
        @weakify(self)
        task = [[self sessionManager] downloadTaskWithRequest:request progress:progressBlock destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            @strongify(self)
            return [NSURL fileURLWithPath:self.fileDownloadPath];
        } completionHandler:completion];
    }
    else
    {
        if ([self.method isEqualToString:@"POST"])
        {
            task = [[self sessionManager] uploadTaskWithStreamedRequest:request
                                                               progress:progressBlock
                                                      completionHandler:completion];
        }
        else {
            task = [[self sessionManager] dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:completion];        
        }
    }
    
    return task;
}
- (void)cancel
{
    syncAtQueue(self.queue, ^{
        if (self.myTask)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:HNQueueTaskFinishNotification object:nil userInfo:@{@"data":self.myTask, @"queue":self.queueName?:@"global"}];
            [self.myTask cancel];
            self.myTask = nil;
        }
    });
}
@end
