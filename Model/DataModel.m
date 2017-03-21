//
//  DataModel.m
//  HYSEM
//
//  Created by 王一成 on 2017/2/28.
//  Copyright © 2017年 WGM. All rights reserved.
//

#import "DataModel.h"

@implementation DataModel

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.point = [aDecoder decodeObjectForKey:@"point"];
        self.data_density = [aDecoder decodeObjectForKey:@"data_density"];
        self.mm = [aDecoder decodeObjectForKey:@"mm"];
        self.hour = [aDecoder decodeObjectForKey:@"hour"];
        self.day = [aDecoder decodeObjectForKey:@"day"];
        self.Month = [aDecoder decodeObjectForKey:@"Month"];
        self.year = [aDecoder decodeObjectForKey:@"year"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.D_id = [aDecoder decodeObjectForKey:@"D_id"];
        self.data = [aDecoder decodeObjectForKey:@"data"];
        self.ct = [aDecoder decodeObjectForKey:@"ct"];
        self.pt = [aDecoder decodeObjectForKey:@"pt"];
        self.total_actPower = [aDecoder decodeObjectForKey:@"total_actPower"];
        self.total_reactPower = [aDecoder decodeObjectForKey:@"total_reactPower"];
        self.total_apparentPower = [aDecoder decodeObjectForKey:@"total_apparentPower"];
        self.voltageA = [aDecoder decodeObjectForKey:@"voltageA"];
        self.voltageB = [aDecoder decodeObjectForKey:@"voltageB"];
        self.voltageC = [aDecoder decodeObjectForKey:@"voltageC"];
        self.electricA = [aDecoder decodeObjectForKey:@"electricA"];
        self.electricB = [aDecoder decodeObjectForKey:@"electricB"];
        self.electricC = [aDecoder decodeObjectForKey:@"electricC"];
        self.activeA = [aDecoder decodeObjectForKey:@"activeA"];
        self.activeB = [aDecoder decodeObjectForKey:@"activeB"];
        self.activeC = [aDecoder decodeObjectForKey:@"activeC"];
        self.reactiveA = [aDecoder decodeObjectForKey:@"reactiveA"];
        self.reactiveB = [aDecoder decodeObjectForKey:@"reactiveB"];
        self.reactiveC = [aDecoder decodeObjectForKey:@"reactiveC"];
        self.powerFactor = [aDecoder decodeObjectForKey:@"powerFactor"];
        self.my_id = [aDecoder decodeObjectForKey:@"my_id"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.point forKey:@"point"];
    [aCoder encodeObject:self.data_density forKey:@"data_density"];
    [aCoder encodeObject:self.mm forKey:@"mm"];
    [aCoder encodeObject:self.hour forKey:@"hour"];
    [aCoder encodeObject:self.day forKey:@"day"];
    [aCoder encodeObject:self.Month forKey:@"Month"];
    [aCoder encodeObject:self.year forKey:@"year"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.D_id forKey:@"D_id"];
    [aCoder encodeObject:self.data forKey:@"data"];
    [aCoder encodeObject:self.ct forKey:@"ct"];
    [aCoder encodeObject:self.pt forKey:@"pt"];
    [aCoder encodeObject:self.total_actPower forKey:@"total_actPower"];
    [aCoder encodeObject:self.total_reactPower forKey:@"total_reactPower"];
    [aCoder encodeObject:self.total_apparentPower forKey:@"total_apparentPower"];
    [aCoder encodeObject:self.voltageA forKey:@"voltageA"];
    [aCoder encodeObject:self.voltageB forKey:@"voltageB"];
    [aCoder encodeObject:self.voltageC forKey:@"voltageC"];
    [aCoder encodeObject:self.activeA forKey:@"activeA"];
    [aCoder encodeObject:self.activeB forKey:@"activeB"];
    [aCoder encodeObject:self.activeC forKey:@"activeC"];
    [aCoder encodeObject:self.reactiveA forKey:@"reactiveA"];
    [aCoder encodeObject:self.reactiveB forKey:@"reactiveB"];
    [aCoder encodeObject:self.reactiveC forKey:@"reactiveC"];
    [aCoder encodeObject:self.powerFactor forKey:@"powerFactor"];
    [aCoder encodeObject:self.my_id forKey:@"my_id"];
}
@end
