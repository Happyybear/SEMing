//
//  DeviceModel.h
//  HYSEM
//
//  Created by 王一成 on 2017/2/28.
//  Copyright © 2017年 WGM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataModel.h"
@interface DeviceModel : NSObject<NSCoding>

@property (nonatomic,copy) NSString * De_addr;
//@property (nonatomic,copy) NSString * De_addr1;
@property (nonatomic,copy) NSString * pointNum;
@property (nonatomic,strong) NSMutableArray * dataArr;
@end
