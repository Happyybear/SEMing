//
//  HYSingleManager.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCompanyModel.h"
#import "HYUserModel.h"
#import "CMPModel.h"
#import "CSetModel.h"
#import "CTransitModel.h"
#import "CMPModel.h"
#import "CTerminalModel.h"

@interface HYSingleManager : NSObject

@property (nonatomic,strong) HYUserModel *user;

@property (nonatomic,strong) CCompanyModel *company;

@property (nonatomic,strong) CTransitModel *transitM;

@property (nonatomic,strong) CSetModel *setM;

@property (nonatomic,strong) CMPModel *cmpM;

@property (nonatomic,strong) CTerminalModel *terminalM;

@property (nonatomic,strong) HYUserModel *archiveUser;

//用来存放档案  ID为key
@property (nonatomic,strong) NSMutableDictionary *obj_dict;

//用来存放表码数据,表ID作为key,数据作为value
@property (nonatomic,strong) NSMutableDictionary *tableCode_dict;

//总有功功率
@property (nonatomic,strong) NSMutableDictionary *total_actPower_dict;

//总无功功率
@property (nonatomic,strong) NSMutableDictionary *total_reactPower_dict;

//总视在功率
@property (nonatomic,strong) NSMutableDictionary *total_apparentPower_dict;

//A相电压
@property (nonatomic,strong) NSMutableDictionary *voltageA_dict;

//B相电压
@property (nonatomic,strong) NSMutableDictionary *voltageB_dict;

//C相电压
@property (nonatomic,strong) NSMutableDictionary *voltageC_dict;

//A相电流
@property (nonatomic,strong) NSMutableDictionary *electricA_dict;

//B相电流
@property (nonatomic,strong) NSMutableDictionary *electricB_dict;

//C相电流
@property (nonatomic,strong) NSMutableDictionary *electricC_dict;

//A相有功功率
@property (nonatomic,strong) NSMutableDictionary *activeA_dict;

//B相有功功率
@property (nonatomic,strong) NSMutableDictionary *activeB_dict;

//C相有功功率
@property (nonatomic,strong) NSMutableDictionary *activeC_dict;

//A相无功功率
@property (nonatomic,strong) NSMutableDictionary *reactiveA_dict;

//B相无功功率
@property (nonatomic,strong) NSMutableDictionary *reactiveB_dict;

//C相无功功率
@property (nonatomic,strong) NSMutableDictionary *reactiveC_dict;

//总功率因数
@property (nonatomic,strong) NSMutableDictionary *powerFactor_dict;

//用来存放用量数据,实际上是表码,需要再做差,表ID作为key
@property (nonatomic,strong) NSMutableDictionary *usepower_dict;

//存储
@property (nonatomic,strong) NSMutableArray * memory_Array;

@property (nonatomic,strong) NSMutableArray * rea_memory_Array;
+(id)sharedManager;

@end
