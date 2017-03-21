//
//  DateModel.h
//  HYSEM
//
//  Created by 王一成 on 2017/3/14.
//  Copyright © 2017年 WGM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataModel.h"
@interface DateModel : NSObject

@property (nonatomic,copy) NSString * day;

@property (nonatomic,strong) NSMutableArray * data;

@end
