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
#import "HNetworkMultiDataObj.h"
#import "HNQueueManager.h"

@interface HNProvider_AF3 ()
@property (nonatomic) NSURLSessionTask *myTask;
@end

@implementation HNProvider_AF3
@synthesize urlString;
@synthesize params;
@synthesize method;
@synthesize queueName;

@synthesize timeoutInterval;
@synthesize shouldContinueInBack;
@synthesize fileDownloadPath;
@synthesize headParameters;
@synthesize cachePolicy;

@synthesize successCallback;
@synthesize failCallback;
@synthesize progressCallback;
@synthesize willSendCallback;


HReg(HNetworkProviderRegKey)



static dispatch_queue_t HNProviderProcessingQueue() {
    static dispatch_queue_t HNProviderProcessingQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HNProviderProcessingQueue = dispatch_queue_create("com.hnetwork.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return HNProviderProcessingQueue;
}
- (AFHTTPSessionManager *)sessionManager {
    
    if (!self.shouldContinueInBack)
    {
        static AFHTTPSessionManager *manager1;
        static dispatch_once_t onceToken1;
        dispatch_once(&onceToken1, ^{
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            configuration.timeoutIntervalForRequest = 30;
            manager1 = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
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
        });
        return manager2;
    }
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    }
    return self;
}

- (NSURLSessionTask *)sendRequest
{
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
    
    @weakify(self)
    //multi Data
    if(multiDataDict.allKeys.count > 0)
    {
        
        request = [requestSerializer multipartFormRequestWithMethod:@"POST" URLString:urlString parameters:parametersDict constructingBodyWithBlock:^(id <AFMultipartFormData> multipartFormData)
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
        request = [requestSerializer requestWithMethod:self.method URLString:urlString parameters:parametersDict error:nil];
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
        [paramString appendFormat:@"%@=%@", key, [parametersDict[key] stringValue]];
    }
    
    NSLog(@"\n\n#### send request:\n%@ %@\n%@",self.method, urlString, paramString.length>0?paramString:@"");
    if (multiDataDict.count > 0)
    {
        NSLog(@"\n\n#### multiData: %@", paramString);
    }
    

    NSURLSessionTask *task = [self requestTask:request progress:^(NSProgress * _Nullable progress) {
        
        @strongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.progressCallback) self.progressCallback(self, progress.fractionCompleted);
        });
        
    } completion:^(NSURLResponse *response, id responseObject, NSError *error) {
        @strongify(self)
        
        dispatch_async(HNProviderProcessingQueue(), ^{
            if (!error)
            {
                if (self.successCallback) self.successCallback(self, response, responseObject);
            }
            else
            {
                if (self.failCallback) self.failCallback(self, error);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:HNQueueTaskFinishNotification object:nil userInfo:@{@"data":self.myTask}];
        });
    }];
    
    self.myTask = task;
    if (self.willSendCallback) self.willSendCallback(request);
    
    HNQueue *operataionQueue;
    if(self.queueName) operataionQueue = [[HNQueueManager instance] getOperationQueueWithName:queueName];
    else operataionQueue = [HNQueueManager instance].globalQueue;
    [operataionQueue addTask:self.myTask];
    
    return self.myTask;
}
- (NSURLSessionTask *)requestTask:(NSMutableURLRequest *)request progress:(nullable void (^)(NSProgress *nsprogress))progress completion:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completion {
    
    __block NSURLSessionTask *task = nil;
    
    if (self.fileDownloadPath)
    {
        @weakify(self)
        task = [[self sessionManager] downloadTaskWithRequest:request progress:progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            @strongify(self)
            return [NSURL fileURLWithPath:self.fileDownloadPath];
        } completionHandler:completion];
    }
    else
    {
        if ([self.method isEqualToString:@"POST"])
        {
            task = [[self sessionManager] uploadTaskWithStreamedRequest:request
                                                               progress:progress
                                                      completionHandler:completion];
        }
        else {
            task = [[self sessionManager] dataTaskWithRequest:request
                                            completionHandler:completion];
        }
    }
    
    return task;
}
- (void)cancel
{
    [self.myTask cancel];
    [[NSNotificationCenter defaultCenter] postNotificationName:HNQueueTaskFinishNotification object:nil userInfo:@{@"data":self.myTask}];
}
@end
