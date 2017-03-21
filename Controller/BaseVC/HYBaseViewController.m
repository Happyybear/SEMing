//
//  HYBaseViewController.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYBaseViewController.h"

@interface HYBaseViewController ()

@end

@implementation HYBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self createRootNav];
}

- (void)createRootNav
{
    self.navigationController.navigationBar.translucent = NO;
    //    self.navigationController.navigationBar.barTintColor = RGBA(255, 156, 187, 1);
    self.navigationController.navigationBar.barTintColor = RGB(1,127,105);
    //左按钮
    self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.leftButton.frame = CGRectMake(0, 0, 44, 44);
    //[self.leftButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.leftButton];
    
    //标题
    self.titleLabel = [[UILabel alloc]init];
    self.titleLabel.frame = CGRectMake(0, 0, 100, 25);
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:20];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = self.titleLabel;
    
    //右按钮
    self.rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rightButton.frame = CGRectMake(0, 0, 44, 44);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.rightButton];
    
}

//添加响应事件
- (void)setLeftButtonClick:(SEL)selector
{
    [self.leftButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
}
- (void)setRightButtonClick:(SEL)selector
{
    [self.rightButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
}




- (BOOL)shouldAutorotate
{
    return NO;
    //return [self.viewControllers.lastObject shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return  UIInterfaceOrientationPortrait ;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
