//
//  UIButton+flag.m
//  HYSEM
//
//  Created by 王一成 on 2017/3/20.
//  Copyright © 2017年 WGM. All rights reserved.
//

#import "UIButton+flag.h"

#import <objc/runtime.h>

@implementation UIButton (flag)

static NSString * _flagStr;
static int * _intFlag;

- (void)setFlag:(NSString *) flag{
    objc_setAssociatedObject(self, &_flagStr, flag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- ( NSString *)flagStr{
    return  objc_getAssociatedObject(self, &_flagStr);
}

-(void) setIntFlag:(long long)intFlag{
    NSNumber * t = @(intFlag);
    objc_setAssociatedObject(self, &_intFlag, t, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (long long)intFlag{
    NSNumber * t = objc_getAssociatedObject(self, &_intFlag);
    return [t longLongValue];
}

@end
