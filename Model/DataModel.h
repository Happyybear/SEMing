//
//  DataModel.h
//  HYSEM
//
//  Created by 王一成 on 2017/2/28.
//  Copyright © 2017年 WGM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataModel : NSObject <NSCoding>
@property (nonatomic,copy) NSString * my_id;
@property (nonatomic,copy) NSString * point; //时间偏移量

@property (nonatomic,copy) NSString * data_density;

@property (nonatomic,copy) NSString * mm;
@property (nonatomic,copy) NSString * hour;
@property (nonatomic,copy) NSString * day;
@property (nonatomic,copy) NSString * Month;
@property (nonatomic,copy) NSString * year;

@property (nonatomic,copy) NSString * name;

@property (nonatomic,copy) NSString * D_id;

@property (nonatomic,copy) NSString * data;

@property (nonatomic,copy) NSString * ct;

@property (nonatomic,copy) NSString * pt;

//总有功功率
@property (nonatomic,copy) NSString *total_actPower;

//总无功功率
@property (nonatomic,copy) NSString *total_reactPower;

//总视在功率
@property (nonatomic,copy) NSString *total_apparentPower;

//A相电压
@property (nonatomic,copy) NSString *voltageA;

//B相电压
@property (nonatomic,copy) NSString *voltageB;

//C相电压
@property (nonatomic,copy) NSString *voltageC;

//A相电流
@property (nonatomic,copy) NSString *electricA;

//B相电流
@property (nonatomic,copy) NSString *electricB;

//C相电流
@property (nonatomic,copy) NSString *electricC;

//A相有功功率
@property (nonatomic,copy) NSString *activeA;

//B相有功功率
@property (nonatomic,copy) NSString *activeB;

//C相有功功率
@property (nonatomic,copy) NSString *activeC;

//A相无功功率
@property (nonatomic,copy) NSString *reactiveA;

//B相无功功率
@property (nonatomic,copy) NSString *reactiveB;

//C相无功功率
@property (nonatomic,copy) NSString *reactiveC;

//总功率因数
@property (nonatomic,copy) NSString *powerFactor;
@end
