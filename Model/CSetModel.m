//
//  CSetModel.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "CSetModel.h"

@implementation CSetModel

- (id)init
{
    self = [super init];
    if (self) {
        self.isRequest = false;
        self.request_Type = @"set";
    }
    return self;
}

- (void)addMpChildren:(CMPModel *)mp
{
    [self.children addObject:mp];
}

@end
