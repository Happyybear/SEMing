//
//  DeviceModel.m
//  HYSEM
//
//  Created by 王一成 on 2017/2/28.
//  Copyright © 2017年 WGM. All rights reserved.
//

#import "DeviceModel.h"

@implementation DeviceModel

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.De_addr =[aDecoder decodeObjectForKey:@"De_addr"];
        self.pointNum =[aDecoder decodeObjectForKey:@"pointNum"];
        self.dataArr =[aDecoder decodeObjectForKey:@"dataArr"];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.De_addr forKey:@"De_addr"];
    [aCoder encodeObject:self.pointNum forKey:@"pointNum"];
    [aCoder encodeObject:self.dataArr forKey:@"dataArr"];
}
@end
