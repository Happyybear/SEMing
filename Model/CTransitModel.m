//
//  CTransitModel.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "CTransitModel.h"

@implementation CTransitModel

- (id)init
{
    self = [super init];
    if (self) {
        self.isRequest = false;
        self.request_Type = @"transit";
    }
    return self;
}

- (void)addSetChildren:(CSetModel *)set
{
    [self.children addObject:set];
}

@end
