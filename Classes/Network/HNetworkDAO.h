//
//  HNetworkDAO.h
//  TestDemoCocoaPod
//
//  Created by jeremyLyu on 14-9-17.
//  Copyright (c) 2014年 jeremyLyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNetworkDAOManager.h"
#import <NSObject+annotation.h>
#import "HNDeserializer.h"
//in most situation, you use json Deserializer
#import "HNJsonDeserializer.h"

#pragma mark - file upload object，

/**
 *  this is a file object ， use for file upload
 *  just use it as a param of any network dao
 */
@interface HNetworkMultiDataObj : NSObject
@property (nonatomic, strong) NSString* filePath;
//default： file.jpg
@property (nonatomic, strong) NSString* fileName;
//default： image/jpg
@property (nonatomic, strong) NSString* mimeType;
//default：nil. if data is not null it will ignore filePath
@property (nonatomic, strong) NSData* data;
//default：nil. if datas is not null it will ignore filePath and data
@property (nonatomic, strong) NSArray* datas;
@end


/**
 *  cache type
 *  it is not the same as NSURLRequestCachePolicy
 */
typedef enum
{
    HFileCacheTypeNone = 0, //no cache, directly and no cache result
    HFileCacheTypeBoth,     //if has cache read cache and callback then request and callback, this type will callback twice if has cache
    HFileCacheTypeExclusive, //if has cache read cache and callback , if not request and callback
    HFileCacheTypeForceRefresh //will not read cache, but will save cache after get requst
} HFileCacheType;


@class HNetworkDAO;


typedef void(^HNetworkDAOFinishBlock)(HNetworkDAO* request, id resultInfo);


//ppx annotation
#define HPHeader @"header" //if this property is a head attr in request, tag this
//HPMapto: already defined in HDeserializableObject
//HPIgnore: already defined in HDeserializableObject


/**
 *  network data access operation
 *  we advice you to construct a inheric tree base on this class， and it will be flexable and beautiful.
 *  params: create a subclass and write some property in .h file, then it will convert to request params automaticly.
 *  output: set 'deserializeKeyPath' to let it know witch part of data you concern, then set a kind of 'HEDeserialize' to 'deserializer' property.
 *          the 'HEDeserialize' has tree imp, 'HNEntityDeserializer','HNArrayDescerializer','HNManualDescerializer', use any one kind for special data format
 *  cache:  read the cache type define, it is very simple and useful, and actrually most case could be constructed by cache instead of database.
 *          you need not concern about the cache size, it do every thing automaticly. 
 *          use 'cache type' with some special 'cacheDuration' will get more flexable
 */
@interface HNetworkDAO : NSObject
{
    HNetworkDAOFinishBlock _sucessBlock;
    HNetworkDAOFinishBlock _failedBlock;
}
//set URL , it support these prefix: 'http://', 'https://', 'file://', 'bundle://'
@property (nonatomic, strong) NSString* baseURL;
@property (nonatomic, strong) NSString* pathURL;
#ifdef DEBUG
@property (nonatomic) BOOL isMock;
#endif
//GET|POST default is GET
@property (nonatomic, strong) NSString* method;
//what is the queue name
@property (nonatomic, strong, readonly) NSString* queueName;
//deserializer object, indicate how to convert data to object, default is 'HNJsonDeserializer'
@property (nonatomic, strong) id<HNDeserializer> deserializer;
//deserialize path, indicate which part of data you concern, you can set a key path to it like 'a.b.c'
@property (nonatomic, strong) NSString *deserializeKeyPath;
//timeout
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
//upload progress or download progress
@property (nonatomic, strong) HNProgressBlock progressBlock;
//should continue when app is not active
@property (nonatomic, assign) BOOL shouldContinueInBack;
//this is a user info, indicate who send the request
@property (nonatomic, weak) id sender;
//this is a user info, carry some user info could help you know the context in callback
@property (nonatomic, strong) id userInfo;
//rude data, if the request is file download ,it will not work
@property (nonatomic, strong) NSData *responseData;
//cache type
@property (nonatomic) HFileCacheType cacheType;
//how long the cache lives, default is a week
@property (nonatomic) long cacheDuration;
//if it is file download request, set the to YES.
@property (nonatomic) BOOL isFileDownload;

/**
 *  begin request
 *
 *  @param queueName queue name, if you don't care about serail/concurrent set 'nil', 
 *         if you set a name ,it will create a serail queue automaticly if queue not exsit.
 *  @param sucess    callback when request success
 *  @param failure   callback when request fail
 */
- (void)startWithQueueName:(NSString *)queueName
                    sucess:(void(^)(id sender, id data))sucess
                   failure:(void(^)(id sender, NSError *error))failure;


/**
 *  begin request
 *
 *  @param queueName queue name, if you don't care about serail/concurrent set 'nil',
 *         if you set a name ,it will create a serail queue automaticly if queue not exsit.
 *  @param finish    callback when success or fail
 */
- (void)startWithQueueName:(NSString *)queueName
                    finish:(void(^)(id sender, id data, NSError *error))finish;
/**
 *  manual create a queue
 *  if you want create a concurrent queue with special concurrent count, you should use this
 *
 *  @param queueName
 *  @param maxMaxConcurrent
 */
+ (void)initQueueWithName:(NSString *)queueName maxMaxConcurrent:(NSInteger)maxMaxConcurrent;

/**
 *  cancel current request, and cancel the operation
 */
- (void)cancel;

/**
 *  kill a operationQueue
 *  @param queueName
 *
 *  @return is success
 */
+ (BOOL)cancelQueueWithName:(NSString*)queueName;

/**
 *  is my cache usable, if not exist or cache is too old return NO
 */
- (BOOL)isCacheUseable;




#pragma mark - extention

/**
 *  set request headers, default operation is search property of 'HPHeader' tag, then set the key and value
 *  @param headers: empty NSMutableDictionary
 */
- (void)setupHeader:(NSMutableDictionary *)headers;

/**
 *  set request params, if method is 'GET', will append to url, if 'POST' will append to request body
 *  default operation is search property (no 'HPHeader' tag), then set the key and value
 *  @param params empty NSMutableDictionary
 */
- (void)setupParams:(NSMutableDictionary *)params;

/**
 *  after set all params
 *  usually we gen signature there
 *  @param params: contain all params
 */
- (void)didSetupParams:(NSMutableDictionary *)params;

/**
 *  send request
 *
 *  @param queueName
 */
- (void)startWithQueueName:(NSString*)queueName;


/**
 *  after recv response, default operation is invoke getOutputEntiy and write cache
 *  u can do some status code examlation there
 */
- (void)requestFinishedSucessWithInfo:(id)responInfo;

/**
 *  deal response data and convert to a object as new response, if return NSError, it will route to fail callback
 *  @param responseObject: rude response data, usally is a NSDictionary or NSArray by json decode
 *
 *  @return object
 */
- (id)getOutputEntiy:(id)responseObject;

/**
 *  after recv error, default operation is fail callback
 *  @param error
 */
- (void)requestFinishedFailureWithError:(NSError*)error;

/**
 *  my cache key, 
 *  u can special a request' cache key by rewrite this method.
 *  return baseURL+pathURL by default
 *  @return key
 */
- (NSString *)cacheKey;

#ifdef DEBUG
/**
 *  custom Request,support local file.json
 */
- (void)doMockFileRequest;
#endif

#pragma mark - other

//hold self

/**
 *  hold self
 *  startWithQueueName will hold self
 */
- (void)holdNetwork;

/**
 *  unhold self
 *  requestFinishedSucessWithInfo/requestFinishedFailWithInfo will unhold self
 */
- (void)unHoldNetwork;

@end

/**
 *  file download info
 *  if HNetworkDAO.isFileDownload is YES, you will recv a response of this type if successed
 *  once you have downloaded, move the file to other place, otherwise it will be deleted after 1 minute
 */
@interface HDownloadFileInfo : NSObject
@property (nonatomic) NSString *filePath;
@property (nonatomic) NSString *MIMEType;
@property (nonatomic) long long length;
@property (nonatomic) NSString *suggestedFilename;
@end