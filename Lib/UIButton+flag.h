//
//  UIButton+flag.h
//  HYSEM
//
//  Created by 王一成 on 2017/3/20.
//  Copyright © 2017年 WGM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (flag)
// 对象属性的set和get
- (void)setFlag:(NSString *)strFlag;
- (NSString *)flagStr;

// 非对象属性的set和get
- (void)setIntFlag:(long long)intFlag;
- (long long)intFlag;
@end
