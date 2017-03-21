//
//  HYBaseModel.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYBaseModel.h"

@implementation HYBaseModel

- (id)init
{
    self = [super init];
    if (self) {
        //self.archiveModel = [[HYBaseModel alloc]init];
        self.children = [NSMutableArray array];
        self.children1 = [NSMutableArray array];
        self.child_obj = [NSMutableArray array];
        self.child_obj1 = [NSMutableArray array];
    }
    return self;
}

- (id)initWithName:(NSString *)name children:(NSMutableArray *)children strID:(UInt64)strID
{
    self = [super init];
    if (self) {
        self.name = name;
        self.strID = strID;
        self.children = children;
        self.nd_parent->_name = name;
        self->_name = name;
    }
    return self;
}

- (void)addChildren:(HYBaseModel *)model
{
    [self.child_obj addObject:model];
}

- (void)addChildren1:(HYBaseModel *)model
{
    [self.child_obj1 addObject:model];
}

- (NSString *)UInt64ToString:(UInt64)strID
{
    NSString *str = [NSString stringWithFormat:@"%llu",strID];
    
    return str;
}

- (UInt64)StringToUInt64:(NSString *)str
{
    UInt64 buff_str = atoll([str UTF8String]);
    return buff_str;
}

- (id)copyWithZone:(NSZone *)zone {
    HYBaseModel *instance = [[HYBaseModel alloc] init];
    if (instance) {
        instance.strID = self.strID;
        instance.name = [self.name copyWithZone:zone];
        instance.children = [self.children copyWithZone:zone];
    }
    return instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    HYBaseModel *instance = [[HYBaseModel alloc] init];
    if (instance) {
        instance.strID = self.strID;
        instance.name = [self.name mutableCopyWithZone:zone];
        instance.children = [self.children mutableCopyWithZone:zone];
    }
    return instance;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt64:self.strID forKey:@"strID"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.children forKey:@"children"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.strID = [aDecoder decodeInt64ForKey:@"strID"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.children = [aDecoder decodeObjectForKey:@"children"];
    }
    return self;
}

+ (id)dataObjectWithName:(NSString *)name children:(NSMutableArray *)children strID:(UInt64)strID
{
    return [[self alloc]initWithName:name children:children strID:strID];
}


@end
