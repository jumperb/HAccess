//
//  PBTestNetworkDAO.h
//  HAccess
//
//  Created by goingta on 16/3/12.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNetworkDAO.h"

@interface PBSimpleNetDAO : HNetworkDAO
@property (nonatomic) NSString *mobile;
@end

@interface PBArraryNetDAO : HNetworkDAO
@end

@interface PBManualNetDAO : HNetworkDAO

@end