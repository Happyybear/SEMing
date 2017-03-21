//
//  HYStateViewController.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYBaseViewController.h"

@interface HYStateViewController : HYBaseViewController

@property (nonatomic,assign) UIViewController *first;

@property (nonatomic,assign) UIViewController *second;

@property (nonatomic,strong) NSMutableArray *time;

@property (nonatomic,strong) NSMutableArray *dataA;

@property (nonatomic,strong) NSMutableArray *dataB;

@property (nonatomic,strong) NSMutableArray *dataC;

@end
