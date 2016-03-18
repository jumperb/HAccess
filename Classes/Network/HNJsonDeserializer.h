//
//  HNJsonDeserializer.h
//  HAccess
//
//  Created by zhangchutian on 16/3/9.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNDeserializer.h"

@interface HNJsonDeserializer : NSObject <HNDeserializer>
@end

#pragma mark - about deserialize

/**
 *  HNDeserializer which target is a HDeserializableObject
 */
@interface HNEntityDeserializer : HNJsonDeserializer
//create
+ (instancetype)deserializerWithClass:(Class)aClass;
@end

/**
 *  HNDeserializer which target is a NSArray
 */
@interface HNArrayDeserializer : HNJsonDeserializer

//create
+ (instancetype)deserializerWithClass:(Class)aClass;

/**
 *  decide the class in array
 *
 *  @param dict data
 *
 *  @return class
 */
- (Class)classForItem:(NSDictionary *)dict;
@end


typedef id (^DeserializeBlock)(id data);


/**
 * HNDeserializer which is handle by yourself
 */
@interface HNManualDeserializer : HNJsonDeserializer
+ (instancetype)deserializerWithBlock:(DeserializeBlock)block;
@end
