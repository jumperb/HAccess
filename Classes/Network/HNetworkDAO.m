//
//  HNetworkDAO.m
//  TestDemoCocoaPod
//
//  Created by jeremyLyu on 14-9-17.
//  Copyright (c) 2014年 jeremyLyu. All rights reserved.
//

#import "HNetworkDAO.h"
#import "HDeserializableObject.h"
#import <HCache/HFileCache.h>
#import <Hodor/NSObject+ext.h>
#import <Hodor/NSError+ext.h>
#import <Hodor/HDefines.h>
#import <Hodor/HClassManager.h>

/**
 *  property desc
 */
@interface HNetworkDAOPropertyExt : NSObject
@property (nonatomic) BOOL isHead;
@property (nonatomic) NSString *keyMapto;
@property (nonatomic) BOOL isIgnore;
@end

@implementation HNetworkDAOPropertyExt
- (instancetype)initWithObjs:(id)objs
{
    self = [super init];
    if (self) {
        if ([objs isKindOfClass:[NSArray class]])
        {
            for (id obj in (NSArray *)objs)
            {
                [self setWithObj:obj];
            }
        }
    }
    return self;
}
- (void)setWithObj:(id)obj
{
    if ([obj isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = obj;
        NSString *mapTo = dict[@"mapto"];
        if (mapTo)
        {
            self.keyMapto = mapTo;
            return;
        }
    }
    else if ([obj isEqualToString:HPHeader])
    {
        self.isHead = YES;
    }
    else if ([obj isEqualToString:HPIgnore])
    {
        self.isIgnore = YES;
    }
}
@end

@interface HNetworkDAO()
@property (nonatomic) HNetworkDAO* holdSelf;
@property (nonatomic) NSString *fileDownloadPath;
@property (nonatomic) id<HNetworkProvider> provider;
@end

@implementation HNetworkDAO

- (id)init
{
    self = [super init];
    if(self)
    {
        _queueName = nil;
        self.baseURL = nil;
        self.pathURL = nil;
        
        _failedBlock = nil;
        _holdSelf = nil;
        self.method = @"GET";
        self.timeoutInterval = 30;
    }
    return self;
}
- (void)dealloc
{
    [self cancel];
}
- (id<HNDeserializer>)deserializer
{
    if (!_deserializer)
    {
        _deserializer = [HNJsonDeserializer new];
    }
    return _deserializer;
}
#pragma mark - request

- (NSString *)fullurl
{
    //combine
    NSURL* baseUrl = [NSURL URLWithString:self.baseURL];
    NSString* urlString = self.baseURL;
    if (self.pathURL) urlString =[[NSURL URLWithString:self.pathURL relativeToURL:baseUrl] absoluteString];
    return urlString;
}
- (void)willSendRequest:(NSMutableURLRequest *)request
{
    //do nothing
}
- (void)startWithQueueName:(NSString*)queueName
{
    _queueName = queueName;
    
    
    
    NSString* urlString = [self fullurl];
    
#ifdef DEBUG
    if (self.isMock)
    {
        [self doMockFileRequest];
        return;
    }
#endif
    
    NSURL *testURL = [NSURL URLWithString:urlString];
    if (!testURL || !testURL.host) {
        [self requestFinishedFailureWithError:herr(kNoDataErrorCode, ([NSString stringWithFormat:@"url is not approved %@", urlString]))];
        return;
    }
    //prepare file download path
    if (self.isFileDownload)
    {
        self.fileDownloadPath = [self createTempFilePath:urlString];
    }
    else self.fileDownloadPath = nil;
    
    
    //if is file access url
    if ([urlString hasPrefix:@"file://"])
    {
        [self doLocalFileRequest:urlString];
    }
    
    
    //if is bundle access url
    else if ([urlString hasPrefix:@"bundle://"])
    {
        NSString *path = [urlString substringFromIndex:[@"bundle://" length]];
        path = [[NSBundle mainBundle] URLForResource:path withExtension:nil].absoluteString;
        [self doLocalFileRequest:path];
    }
    
    
    
    
    //network
    else
    {
        //set http headers
        NSMutableDictionary *headers = [NSMutableDictionary new];
        [self setupHeader:headers];
        
        id params = [self setupParams];
        
        //request
        @weakify(self)
        _holdSelf = self;
        
        NSString *className = [HClassManager getClassNameForKey:HNetworkProviderRegKey];
        Class class = NSClassFromString(className);
        
        if (!class)
        {
            [self requestFinishedFailureWithError:herr(kInnerErrorCode, @"can't find any Class for HNetworkProviderRegKey")];
            return;
        }
        if (self.provider)
        {
            [self.provider cancel];
            self.provider = nil;
        }
        self.provider = [class new];
        if (![self.provider conformsToProtocol:@protocol(HNetworkProvider)])
        {
            [self requestFinishedFailureWithError:herr(kInnerErrorCode, ([NSString stringWithFormat:@"%@ is not a HNetworkProvider", className]))];
            return;
        }
        
        [self willSendRequest:urlString method:self.method headers:headers params:params];
        
        [self.provider setUrlString:urlString];
        [self.provider setHeadParameters:headers];
        [self.provider setParams:params];
        [self.provider setMethod:self.method];
        [self.provider setRequstContentType:self.requstContentType];
        NSLog(@"mehtod = %@", [self.provider method]);
//            if([self.provider method] == nil)
//            {
//                NSAssert(NO, @"");
//            }
        [self.provider setQueueName:queueName];
        
        [self.provider setTimeoutInterval:self.timeoutInterval];
        [self.provider setShouldContinueInBack:self.shouldContinueInBack];
        [self.provider setFileDownloadPath:self.fileDownloadPath];
        if ([self.cacheType isKindOfClass:[HNSystemCacheStrategy class]])
        {
            [self.provider setCachePolicy:[(HNSystemCacheStrategy *)self.cacheType policy]];
        }
        [self.provider setSuccessCallback:^(id sender, NSURLResponse *response, NSData *data){
            @strongify(self)
            NSLog(@"#### revc response:\n%@", [self fullurl]);
            
            if (!self.fileDownloadPath)
            {
                self.responseData = data;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) self.httpResponse = (NSHTTPURLResponse *)response;
                [self requestFinishedSucessWithInfo:data response:response];
            }
            else
            {
                HDownloadFileInfo *info = [HDownloadFileInfo new];
                info.filePath = self.fileDownloadPath;
                info.MIMEType = [response MIMEType];
                info.length = [response expectedContentLength];
                info.suggestedFilename = [response suggestedFilename];
                //delete after 1 min
                [[HFileCache shareCache] setExpire:[NSDate dateWithTimeIntervalSinceNow:3600] forFilePath:info.filePath];
                [self downloadFinished:info];
            }
        }];
        
        [self.provider setFailCallback:^(id sender, NSURLResponse *response, NSError *error){
            @strongify(self)
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) self.httpResponse = (NSHTTPURLResponse *)response;
            [self requestFinishedFailureWithError:[NSError errorWithDomain:@"Network" code:error.code description:error.localizedDescription]];
        }];
        
        [self.provider setProgressCallback:^(id sender, double progress){
            @strongify(self)
            if (self.progressBlock) self.progressBlock(self, progress);
        }];
        
        [self.provider setWillSendCallback:^(NSMutableURLRequest *request){
            @strongify(self)
            [self willSendRequest:request];
        }];
        
        
        [self.provider sendRequest];
        
    }
}
- (void)start:(void(^)(id sender, id data))sucess failure:(void(^)(id sender, NSError *error))failure
{
    [self startWithQueueName:nil sucess:sucess failure:failure];
}
- (void)startWithQueueName:(NSString *)queueName
                    sucess:(void (^)(id, id))sucess
                   failure:(void (^)(id, NSError *))failure
{
    self.onRequesting = YES;
    _sucessBlock = sucess;
    _failedBlock = failure;
    [self cacheLogic:queueName];
    
}
- (void)start:(void(^)(id sender, id data, NSError *error))finish
{
    [self startWithQueueName:nil finish:finish];
}
- (void)startWithQueueName:(NSString *)queueName
                    finish:(void(^)(id sender, id data, NSError *error))finish
{
    _sucessBlock = ^(id sender, id data){
        if (finish) finish(sender, data, nil);
    };
    _failedBlock = ^(id sender, NSError *error){
        if (finish) finish(sender, nil, error);
    };
    [self cacheLogic:queueName];
}

- (void)cancel
{
    [self.provider cancel];
    //clear
    _failedBlock = nil;
    _sucessBlock = nil;
    _holdSelf = nil;
    self.onRequesting = NO;
}

- (void)setupHeader:(NSMutableDictionary *)headers
{
    NSArray *pplist = [self ppList];
    for (NSString *key in pplist)
    {
        NSArray *exts = [[self class] annotations:key];
        HNetworkDAOPropertyExt *extsObj = [[HNetworkDAOPropertyExt alloc] initWithObjs:exts];
        if (extsObj.isHead)
        {
            [headers setValue:[self valueForKey:key] forKey:extsObj.keyMapto?:key];
        }
    }
}
- (id)setupParams
{
    //set params
    NSMutableDictionary *params = [NSMutableDictionary new];
    [self setupParams:params];
    [self didSetupParams:params];
    return params;
}
- (void)setupParams:(NSMutableDictionary *)params
{
    if (self.class == [HNetworkDAO class]) return;
    NSArray* pplist = [self ppList];
    
    for(NSString* key in pplist)
    {
        NSArray *exts = [[self class] annotations:key];
        HNetworkDAOPropertyExt *extsObj = [[HNetworkDAOPropertyExt alloc] initWithObjs:exts];
        if (extsObj.isHead)
        {
            continue;
        }
        if (extsObj.isIgnore)
        {
            continue;
        }
        id value = [self valueForKey:key];
        if (!value) continue;
        
        [params setValue:value forKey:extsObj.keyMapto?:key];
    }
}
- (void)didSetupParams:(NSMutableDictionary *)params
{
    
}
- (void)willSendRequest:(NSString *)urlString method:(NSString *)method headers:(NSMutableDictionary *)headers params:(NSMutableDictionary *)params
{
}
- (id)processData:(NSData *)responseInfo
{
    [self.deserializer setDeserializeKeyPath:self.deserializeKeyPath];
    
    id processRes = responseInfo;
    if ([self.deserializer respondsToSelector:@selector(preprocess:)])
    {
        processRes = [self.deserializer preprocess:responseInfo];
        if ([processRes isKindOfClass:[NSError class]])
        {
            return processRes;
        }
    }
    
    id responseEntity = [self getOutputEntiy:processRes];
    if (!responseEntity)
    {
        NSString *errorStr = [NSString stringWithFormat:@"inner error:%@.getOutputEntiy return nil", NSStringFromClass(self.class)];
        return herr(kInnerErrorCode, errorStr);
    }
    return responseEntity;
}
//output
- (id)getOutputEntiy:(id)responseObject
{
    if (!self.deserializer) return responseObject;
    return [self.deserializer deserialization:responseObject];
}

//local request
- (void)doLocalFileRequest:(NSString *)urlString
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *fileData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        if (!fileData)
        {
            [self requestFinishedFailureWithError:[NSError errorWithDomain:@"Network" code:kNetWorkErrorCode description:[NSString stringWithFormat:@"%@ file not exsit", urlString]]];
            return ;
        }
        if (!self.isFileDownload)
        {
            NSLog(@"\n\n#### revc response \n%@", [self fullurl]);
            self.responseData = fileData;
            [self requestFinishedSucessWithInfo:fileData response:nil];
        }
        else
        {
            [fileData writeToFile:self.fileDownloadPath atomically:YES];
            
            HDownloadFileInfo *info = [HDownloadFileInfo new];
            info.filePath = self.fileDownloadPath;
            info.MIMEType = @"unkown";
            info.length = fileData.length;
            info.suggestedFilename = [urlString lastPathComponent];
            //设置为1小时后删除
            [[HFileCache shareCache] setExpire:[NSDate dateWithTimeIntervalSinceNow:3600] forFilePath:info.filePath];
            
            [self downloadFinished:info];
        }
    });
}

#ifdef DEBUG
//mock request
- (void)doMockFileRequest
{
    NSString *bundleName = @"HNetworkDAO.bundle";
    if (self.mockBundleName)
    {
        bundleName = self.mockBundleName;
    }
    NSBundle *mockFileBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:bundleName ofType:nil]];
    
    if (mockFileBundle)
    {
        NSString *mockFilePath = nil;
        if (self.mockFileName)
        {
             mockFilePath = [mockFileBundle pathForResource:self.mockFileName ofType:nil];
        }
        else
        {
            NSString *fileType = nil;
            if ([self.deserializer respondsToSelector:@selector(mockFileType)]) fileType = [self.deserializer mockFileType];
            mockFilePath = [mockFileBundle pathForResource:NSStringFromClass([self class]) ofType:fileType];
        }
        
        mockFilePath = [NSURL fileURLWithPath:mockFilePath].absoluteString;
        [self doLocalFileRequest:mockFilePath];
    }
    else
    {
        [self requestFinishedFailureWithError:[NSError errorWithDomain:@"Network" code:kInnerErrorCode description:[NSString stringWithFormat:@"%@ not exsit", bundleName]]];
    }
    
}
#endif

#pragma mark - about cache

- (NSString *)cacheKey
{
    return [NSString stringWithFormat:@"%@%@",self.baseURL, self.pathURL];
}

- (void)cacheLogic:(NSString *)queueName
{
    if ([self.cacheType isKindOfClass:[HNCustomCacheStrategy class]])
    {
        HNCustomCacheStrategy *customCacheStrategy = self.cacheType;
        customCacheStrategy.cacheKey = self.cacheKey;
        @weakify(self)
        @weakify(customCacheStrategy);
        [customCacheStrategy cacheLogic:^(BOOL shouldRequest, NSData *cachedData) {
            @strongify(self)
            @strongify(customCacheStrategy);
            if (cachedData)
            {
                id res = [self processData:cachedData];
                if ([res isKindOfClass:[NSError class]] || [res isEqual:HNDRedirectedResp])
                {
                    NSLog(@"warning : cache data is not correct, it will be deleted");
                    //delete cache
                    [customCacheStrategy deleteCache];
                    shouldRequest = YES;
                }
                else
                {
                    if(self.sucessBlock) self.sucessBlock(nil, res);
                }
            }
            if (shouldRequest)
            {
                [self startWithQueueName:queueName];
            }
            else
            {
                self.failedBlock = nil;
                self.sucessBlock = nil;
                self.holdSelf = nil;
            }
        }];
    }
    else [self startWithQueueName:queueName];
}

#pragma mark - queue
+ (void)initQueueWithName:(NSString *)queueName maxMaxConcurrent:(NSInteger)maxMaxConcurrent
{
    [HNQueueManager initQueueWithName:queueName maxMaxConcurrent:maxMaxConcurrent];
}
+ (void)queue:(NSString *)queueName finish:(void(^)(id sender))finish
{
    [HNQueueManager queue:queueName finish:finish];
}
+ (BOOL)cancelQueueWithName:(NSString*)queueName
{
    if(queueName)
    {
        [HNQueueManager destoryOperationQueueWithName:queueName];
        return YES;
    }
    return NO;
}
#pragma mark - netWorking finished

- (void)requestFinishedSucessWithInfo:(NSData *)responInfo response:(NSURLResponse *)response
{
    id res = [self processData:responInfo];
    if ([res isKindOfClass:[NSError class]])
    {
        [self requestFinishedFailureWithError:res];
    }
    else if ([res isEqual:HNDRedirectedResp])
    {
        return;
    }
    else
    {
        if ([self.cacheType isKindOfClass:[HNCustomCacheStrategy class]])
        {
            HNCustomCacheStrategy *customCacheStrategy = self.cacheType;
            [customCacheStrategy handleRespInfo:responInfo];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self->_sucessBlock) self->_sucessBlock(self, res);
            
            //clear
            self->_failedBlock = nil;
            self->_sucessBlock = nil;
            self->_holdSelf = nil;
            self.onRequesting = NO;
        });
    }
}


- (void)requestFinishedFailureWithError:(NSError*)error
{
    NSLog(@"\n\n#### request error:\n%li,%@,%@ \n url = %@", (long)error.code,error.domain,error.localizedDescription, [self fullurl]);
    if (self.responseData) NSLog(@"data:\n%@", [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self->_failedBlock) self->_failedBlock(self,  error);
        
        //clear
        self->_failedBlock = nil;
        self->_sucessBlock = nil;
        self->_holdSelf = nil;
        self.onRequesting = NO;
        
    });
}

- (void)downloadFinished:(HDownloadFileInfo *)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self->_sucessBlock) self->_sucessBlock(self, info);
        
        //clear
        _failedBlock = nil;
        _sucessBlock = nil;
        _holdSelf = nil;
        self.onRequesting = NO;
    });
}



#pragma mark - downdload

- (NSString *)createTempFilePath:(NSString *)url
{
    NSDate *date = [NSDate new];
    return [[HFileCache shareCache] cachePathForKey:[NSString stringWithFormat:@"%.3f|%@", [date timeIntervalSince1970], url]];
}

#pragma mark - other
- (void)holdNetwork
{
    _holdSelf = self;
}
- (void)unHoldNetwork
{
    _holdSelf = nil;
}
- (NSString *)responseString
{
    return [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
}
@end


@implementation HDownloadFileInfo
@end
