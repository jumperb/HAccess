//
//  HEntityMgr.h
//  HAccess
//
//  Created by zhangchutian on 15/9/15.
//  Copyright (c) 2015年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HEntityMgr : NSObject
//singleton
+ (instancetype)shared;


//default is NO, in strict modle, the example progress is very strict
@property (nonatomic, assign) BOOL strictModle;

//get the cached property list
- (NSArray *)entityPropertylist:(NSString *)entityClassName;

//deepSearch: should search iteratively by inherit relation
- (NSArray *)entityPropertylist:(NSString *)entityClassName isDepSearch:(BOOL)deepSearch;
- (NSArray *)entityPropertyDetailList:(NSString *)entityClassName isDepSearch:(BOOL)deepSearch;

//get property list string, like "field1,field2,field3"
- (NSString *)entityPropertylistString:(NSString *)entityClassName;
- (NSString *)entityPropertylistString:(NSString *)entityClassName isDepSearch:(BOOL)deepSearch;
@end

/**
 *  property desc
 */
@interface HEntityPropertyDetail : NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) BOOL isObj;
@property (nonatomic) char typeCode;
@property (nonatomic) NSString *typeString;
@property (nonatomic) NSString *protocalString;
@end


