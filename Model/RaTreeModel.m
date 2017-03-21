//
//  RaTreeModel.m
//  SEM
//
//  Created by xlc on 16/7/18.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import "RaTreeModel.h"

@implementation RaTreeModel

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.strID forKey:@"strID"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self.name = [decoder decodeObjectForKey:@"name"];
    self.strID = [decoder decodeObjectForKey:@"strID"];
    return self;
}


@end
