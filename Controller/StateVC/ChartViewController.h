//
//  ChartViewController.h
//  HYSEM
//
//  Created by xlc on 16/12/6.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChartViewController : UIViewController


//接收上一页传递过来的数据
@property (nonatomic,copy) NSString *mpName;

//数据项名字数组
@property (nonatomic,strong) NSArray *mpNameArray;

//X轴数据
@property (nonatomic,strong) NSArray *timeArray;

@property (nonatomic,strong) NSArray *dataA;

@property (nonatomic,strong) NSArray *dataB;

@property (nonatomic,strong) NSArray *dataC;

@end
