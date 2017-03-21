//
//  HYSingleManager.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYSingleManager.h"

@implementation HYSingleManager

static HYSingleManager *manager = nil;

+(id)sharedManager {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        manager = [[self alloc] init];
   
    });
    return manager;
}

+(id)allocWithZone:(NSZone *)zone{
    if (manager==nil) {
        manager=[super allocWithZone:zone];
    }
    return manager;
}

//这是在拷贝对象时防止重复创建
-(id)copyWithZone:(NSZone *)zone{
    return manager;
}

@end
