//
//  User.h
//  HAccess
//
//  Created by zhangchutian on 14-9-19.
//  Copyright (c) 2014年 zhangchutian. All rights reserved.
//

#import "HEntity+Persistence.h"

@interface User : HEntity
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) int sex;
@property (nonatomic, assign) long birth;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSArray *groups;
@end
