//
//  TestNetworkDAO.m
//  HAccess
//
//  Created by zhangchutian on 16/3/9.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "TestNetworkDAO.h"
#import <NSString+ext.h>
#import <NSError+ext.h>

@implementation SimpleNetDAO

ppx(apikey, HPHeader) //2
ppx(mobile, HPMapto(@"phone"))

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.baseURL = @"http://apis.baidu.com";
        self.pathURL = @"apistore/mobilenumber/mobilenumber";
        //3
        self.deserializeKeyPath = @"retData";
        //4
        self.deserializer = [HNEntityDeserializer deserializerWithClass:[SimpleEntity class]];
    }
    return self;
}
- (void)didSetupParams:(NSMutableDictionary *)params
{
    NSMutableString *paramsStr = [NSMutableString new];
    //compute a sign code
    NSArray *allKeys = [params keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    for (NSString *key in allKeys)
    {
        [paramsStr appendFormat:@"%@%@",key, params[key]];
    }
    NSString *md5String = [paramsStr md5];
    [params setValue:md5String forKey:@"sign"];
}
- (id)getOutputEntiy:(id)responseObject
{
    NSDictionary* responseDict = (NSDictionary*)responseObject;
    //errNum indecate is server return correct data
    NSNumber* errCode = responseDict[@"errNum"];
    //0 indecate success
    if(errCode.integerValue != 0)
    {
        NSString* message = responseDict[@"retMsg"];
        NSMutableDictionary* userInfo = [NSMutableDictionary new];
        if (message) [userInfo setValue:message forKey:NSLocalizedDescriptionKey];
        NSError* error = [[NSError alloc] initWithDomain:@"Server" code:errCode.integerValue userInfo:userInfo];
        return error;
    }
    else return [super getOutputEntiy:responseObject];
}
@end

@implementation SimpleEntity

@end


@implementation StockNetDAO
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.baseURL = @"http://apis.baidu.com";
        self.pathURL = @"tehir/stockassistant/hgtten";
        self.deserializer = [HNArrayDeserializer deserializerWithClass:[StockItem class]];
    }
    return self;
}
- (void)setupHeader:(NSMutableDictionary *)headers
{
    [headers setValue:@"e05d64b077fe8dfd9559d01a54fad68d" forKey:@"apikey"];
}

- (id)getOutputEntiy:(id)responseObject
{
    NSDictionary* responseDict = (NSDictionary*)responseObject;
    //0 indecate success
    NSNumber* errCode = responseDict[@"errNum"];
    if(errCode.integerValue != 0)
    {
        NSString* message = responseDict[@"retMsg"];
        //建立userInfo
        NSMutableDictionary* userInfo = [NSMutableDictionary new];
        if (message) [userInfo setValue:message forKey:NSLocalizedDescriptionKey];
        NSError* error = [[NSError alloc] initWithDomain:@"Server" code:errCode.integerValue userInfo:userInfo];
        return error;
    }
    else return [super getOutputEntiy:responseObject];
}
@end


@implementation StockNetDAO2
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.deserializeKeyPath = @"rows";
        self.deserializer = [HNManualDeserializer deserializerWithBlock:^id(id data) {
            if (![data isKindOfClass:[NSArray class]])
            {
                NSString *errInfo = [NSString stringWithFormat:@"%@:%@", NSStringFromClass(self.class), @"expect a array"];
                return herr(kDataFormatErrorCode, errInfo);
            }
            NSArray *dataArray = data;
            NSMutableArray *res = [NSMutableArray new];
            for (NSDictionary *dict in dataArray)
            {
                StockItem *item = [StockItem new];
                [item setWithDictionary:dict];
                if (item.format_error)
                {
                    return herr(kDataFormatErrorCode, item.format_error);
                }
                [res addObject:item];
            }
            return res;
        }];
    }
    return self;
}
@end


@implementation StockItem
ppx(numorder, HPAutoCast)
ppx(numbmount, HPAutoCast)
ppx(numsmount, HPAutoCast)
ppx(numsummount, HPAutoCast)
ppx(numratio, HPAutoCast)
ppx(numclose, HPAutoCast)
@end