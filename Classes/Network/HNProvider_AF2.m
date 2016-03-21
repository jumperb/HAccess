//
//  HNProvider_AF2.m
//  HAccess
//
//  Created by zhangchutian on 16/3/21.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HNProvider_AF2.h"
#import "HNQueueManager.h"
#import "HNetworkMultiDataObj.h"
#import <AFNetworking.h>
#import <HClassManager.h>

@interface HNProvider_AF2 ()
@property (nonatomic) NSOperation *myOperation;
@end

@implementation HNProvider_AF2
@synthesize urlString;
@synthesize params;
@synthesize method;
@synthesize queueName;

@synthesize timeoutInterval;
@synthesize shouldContinueInBack;
@synthesize fileDownloadPath;
@synthesize headParameters;

@synthesize successCallback;
@synthesize failCallback;
@synthesize progressCallback;
@synthesize willSendCallback;


HReg(HNetworkProviderRegKey)

- (NSOperation *)sendRequest
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
        request = [requestSerializer requestWithMethod:self.method URLString:urlString parameters:parametersDict error:nil];
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
    NSLog(@"#### %@ %@",self.method, urlString);
    if (paramString.length > 0)
    {
        NSLog(@"#### param: %@", paramString);
    }
    if (multiDataDict.count > 0)
    {
        NSLog(@"#### multiData: %@", paramString);
    }
    NSLog(@" ");
    
    __weak typeof(self) weakSelf = self;
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.successCallback) weakSelf.successCallback(operation, operation.response, responseObject);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.failCallback) weakSelf.failCallback(operation, error);
        });
    }];
    
    self.myOperation = operation;
    
    if (self.fileDownloadPath)
    {
        [operation setDownloadProgressBlock:self.progressCallback];
        [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:self.fileDownloadPath append:NO]];
    }
    else if (multiDataDict.count > 0)
    {
        [operation setUploadProgressBlock:self.progressCallback];
    }
    
    if (self.shouldContinueInBack)
    {
        [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    }
    
    if (self.willSendCallback) self.willSendCallback(request);
    
    NSOperationQueue* operataionQueue = nil;
    if(queueName) operataionQueue = [[HNQueueManager instance] getOperationQueueWithName:queueName];
    else operataionQueue = [HNQueueManager instance].globalQueue;
    [operataionQueue addOperation:operation];
    
    return operation;
}
- (void)cancel
{
    [self.myOperation cancel];
}
@end
