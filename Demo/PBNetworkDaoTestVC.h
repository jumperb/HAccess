//
//  PBNetworkDaoTestVC.h
//  HAccess
//
//  Created by goingta on 16/3/11.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTestVC.h"

@interface PBNetworkDaoTestVC : HTestVC

@end


#import "HNetworkDAO.h"

@interface PBDemoNetworkDAO : HNetworkDAO
@property (nonatomic) NSString *appkey;
@property (nonatomic) NSString *info;
@property (nonatomic) NSString *userid;
@end