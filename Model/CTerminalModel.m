//
//  CTerminalModel.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "CTerminalModel.h"

@implementation CTerminalModel

- (id)init
{
    self = [super init];
    if (self) {
        self.request_Type = @"terminal";
        self.isRequest = true;
    }
    return self;
}

- (void)addMpChildren:(CMPModel *)mp
{
    [self.children addObject:mp];
}

@end
