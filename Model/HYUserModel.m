//
//  HYUserModel.m
//  HYSEM
//
//  Created by xlc on 16/11/23.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYUserModel.h"

@implementation HYUserModel

- (id)init
{
    self = [super init];
    if (self) {
//        self.isRequest = true;
        self.request_Type = @"user";
    }
    return self;
}



@end
