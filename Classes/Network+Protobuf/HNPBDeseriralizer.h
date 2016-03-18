//
//  HNPBDeseriralizer.h
//  HAccess
//
//  Created by goingta on 16/3/12.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNDeserializer.h"

@interface HNPBDeseriralizer : NSObject <HNDeserializer>

+ (instancetype)deserializerWithClass:(Class)aClass;

@end
