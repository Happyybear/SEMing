//
//  UIImage+ColorAtPoint.h
//  SEM
//
//  Created by xlc on 16/11/10.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ColorAtPoint)

/**
 *  次点区域的色值
 *
 *  @param point CGPoint
 *
 *  @return 色值
 */
- (UIColor *)colorAtPoint:(CGPoint)point;

@end
