//
//  PBTestNetworkDAO.m
//  HAccess
//
//  Created by goingta on 16/3/12.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "PBTestNetworkDAO.h"
#import "HNPBDeseriralizer.h"
#import "Person.pbobjc.h"
#import <NSString+ext.h>
#import <NSError+ext.h>
#import "User.pbobjc.h"
#import "Photo.pbobjc.h"

@implementation PBSimpleNetDAO

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.baseURL = @"http://apis.baidu.com";
        self.pathURL = @"apistore/mobilenumber/mobilenumber";
        //3
//        self.deserializeKeyPath = @"retData";
        self.isMock = YES;
        //4
        self.deserializer = [HNPBDeseriralizer deserializerWithClass:[Person class]];
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

@end

@implementation PBArraryNetDAO

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.baseURL = @"http://apis.baidu.com";
        self.pathURL = @"apistore/mobilenumber/mobilenumber";
        self.isMock = YES;
        self.deserializer = [HNPBDeseriralizer deserializerWithClass:[UserInfo class]];
    }
    return self;
}

@end

@implementation PBManualNetDAO

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.baseURL = @"http://apis.baidu.com";
        self.pathURL = @"apistore/mobilenumber/mobilenumber";
        self.isMock = YES;
        self.deserializer = [HNPBDeseriralizer deserializerWithClass:[PhotoInfo class]];
    }

    return self;
}

@end