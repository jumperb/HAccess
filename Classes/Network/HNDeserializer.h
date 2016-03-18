//
//  HNDeserializer.h
//  HAccess
//
//  Created by zhangchutian on 16/3/9.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 *  deserializer protocal
 */
@protocol HNDeserializer <NSObject>
@property (nonatomic) NSString *deserializeKeyPath;

@required
/**
 *  do deserialize
 *
 *  @param rudeData
 *
 *  @return entity
 */
- (id)deserialization:(id)data;

@optional

/**
 *  preprocess data
 *
 *  @param rudeData
 *
 *  @return
 */
- (id)preprocess:(id)rudeData;

/**
 *  return a mockFileName
 *
 *  @return mockFileName
 */
- (NSString *)mockFileType;
@end
