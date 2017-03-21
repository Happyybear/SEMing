//
//  CMPModel.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "CMPModel.h"

@implementation CMPModel

- (id)init
{
    self = [super init];
    if (self) {
        self.isRequest = true;
        self.request_Type = @"mp";
    }
    return self;
}

@end
