//
//  HYBaseViewController.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HYBaseViewController : UIViewController

@property (nonatomic,strong) UIButton *leftButton;
@property (nonatomic,strong) UIButton *rightButton;
@property (nonatomic,strong) UILabel *titleLabel;

//响应事件
- (void)setLeftButtonClick:(SEL)selector;
- (void)setRightButtonClick:(SEL)selector;

@end
