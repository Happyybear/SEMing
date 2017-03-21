//
//  CCompanyModel.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "CCompanyModel.h"

@implementation CCompanyModel

- (id)init
{
    self = [super init];
    if (self) {
        self.isRequest = false;
        self.request_Type = @"company";
    }
    return self;
}

- (void)addTerminalChildren:(CTerminalModel *)terminal
{
    [self.children1 addObject:terminal];
}

- (void)addTransitChildren:(CTransitModel *)transit
{
    [self.children addObject:transit];
}

@end
