//
//  HNetworkMultiDataObj.m
//  HAccess
//
//  Created by zhangchutian on 16/3/21.
//  Copyright © 2016年 zhangchutian. All rights reserved.
//

#import "HNetworkMultiDataObj.h"

@implementation HNetworkMultiDataObj

- (id)init
{
    self = [super init];
    if(self)
    {
        self.filePath = nil;
        self.fileName = @"file.jpg";
        self.mimeType = @"image/jpg";
        self.data = nil;
        self.datas = nil;
    }
    return self;
}

@end