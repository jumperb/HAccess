//
//  TestNetworkDAO.h
//  HAccess
//
//  Created by zhangchutian on 16/3/9.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HEntity.h"
#import "HNetworkDAO.h"


//document http://apistore.baidu.com/apiworks/servicedetail/794.html

@interface SimpleNetDAO : HNetworkDAO
@property (nonatomic) NSString *mobile;
@property (nonatomic) NSString *apikey;
@end

@interface SimpleEntity : HEntity
@property (nonatomic) NSString *supplier;
@property (nonatomic) NSString *province;
@property (nonatomic) NSString *city;
@end

//document http://apistore.baidu.com/apiworks/servicedetail/1626.html

@interface StockNetDAO : HNetworkDAO
@property (nonatomic) NSString *date;
@end

@interface StockNetDAO2 : StockNetDAO

@end


@interface StockItem : HEntity
@property (nonatomic) long numorder;
@property (nonatomic) long numbmount;
@property (nonatomic) long numsmount;
@property (nonatomic) long numsummount;
@property (nonatomic) NSString *vc2name;
@property (nonatomic) float numratio;
@property (nonatomic) NSString *vc2marcode;
@property (nonatomic) float numclose;
@end