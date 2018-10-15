//
//  HPropertyMgr.h
//  HAccess
//
//  Created by zhangchutian on 15/9/15.
//  Copyright (c) 2015年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  property desc
 */
@interface HPropertyDetail : NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) BOOL isObj;
@property (nonatomic) char typeCode;
@property (nonatomic) NSString *typeString;
@property (nonatomic) NSString *protocalString;
@end

@interface HPropertyMgr : NSObject
//singleton
+ (instancetype)shared;

//get the cached property list
- (NSArray *)entityPropertylist:(NSString *)entityClassName;

//deepSearch: should search iteratively by inherit relation
- (NSArray *)entityPropertylist:(NSString *)entityClassName deepTo:(Class)deepToClass;
- (NSArray<HPropertyDetail *> *)entityPropertyDetailList:(NSString *)entityClassName deepTo:(Class)deepToClass;


@end




