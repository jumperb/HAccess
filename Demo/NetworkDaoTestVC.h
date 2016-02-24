//
//  NetworkDaoTestVC.h
//  HAccess
//
//  Created by zhangchutian on 15/7/3.
//  Copyright (c) 2015年 zhangchutian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NetworkDaoTestVC : UIViewController

@end


#import "HNetworkDAO.h"

@interface DemoNetworkDAO : HNetworkDAO
@property (nonatomic) NSString *appkey;
@property (nonatomic) NSString *info;
@property (nonatomic) NSString *userid;
@end

#import "HEntity.h"

@interface DemoEntity : HEntity
@property (nonatomic) NSString *text;
@property (nonatomic) NSMutableArray *otherInfo;
@end