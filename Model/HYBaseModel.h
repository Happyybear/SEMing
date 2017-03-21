//
//  HYBaseModel.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYBaseModel : NSObject<NSCoding,NSCopying>

@property (nonatomic,copy) NSString *name;//名字

@property (nonatomic,assign) UInt64 strID;//ID

@property (nonatomic,strong) HYBaseModel *nd_parent;//指向父类的指针

@property (nonatomic,strong) HYBaseModel *nd_terminal_Parent;//指向父类的指针（这个指向的是终端，继承与基类的指向单位）

@property (nonatomic,strong) NSMutableArray *children;//子节点数组     /*这个和下边的是用来请求档案时用的*/

@property (nonatomic,strong) NSMutableArray *children1;//子节点数组(用于存放单位下的终端)

@property (nonatomic,strong) NSMutableArray *child_obj;//子节点数组  /*建立档案时使用的*/

@property (nonatomic,strong) NSMutableArray *child_obj1;//子节点数组(用于存放单位下的终端)

@property (nonatomic,strong) HYBaseModel* archiveModel;//建档案用的

@property (nonatomic,assign) BOOL isRequest;//是否已请求

@property (nonatomic,copy) NSString *request_Type;

@property (nonatomic,strong) NSMutableDictionary *children_dict;

//添加子节点(占线)
- (void)addChildren:(HYBaseModel *)model;

//添加子节点(终端)
- (void)addChildren1:(HYBaseModel *)model;

//初始化一个model
- (id)initWithName:(NSString *)name children:(NSMutableArray *)children strID:(UInt64)strID;

//遍历构造器
+ (id)dataObjectWithName:(NSString *)name children:(NSMutableArray *)children strID:(UInt64)strID;

- (NSString *)UInt64ToString:(UInt64)strID;

- (UInt64)StringToUInt64:(NSString *)str;

@end
