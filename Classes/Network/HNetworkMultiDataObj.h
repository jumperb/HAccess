//
//  HNetworkMultiDataObj.h
//  HAccess
//
//  Created by zhangchutian on 16/3/21.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - file upload object，

/**
 *  this is a file object ， use for file upload
 *  just use it as a param of any network dao
 */
@interface HNetworkMultiDataObj : NSObject
@property (nonatomic, strong) NSString* filePath;
//default： file.jpg
@property (nonatomic, strong) NSString* fileName;
//default： image/jpg
@property (nonatomic, strong) NSString* mimeType;
//default：nil. if data is not null it will ignore filePath
@property (nonatomic, strong) NSData* data;
//default：nil. if datas is not null it will ignore filePath and data
@property (nonatomic, strong) NSArray* datas;
@end
