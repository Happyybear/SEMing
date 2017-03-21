//
//  RaTreeModel.h
//  SEM
//
//  Created by xlc on 16/7/18.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RaTreeModel : NSObject<NSCoding>

@property (nonatomic,copy) NSString *name;//名字

@property (nonatomic,copy) NSString *strID;//ID

@property (nonatomic,strong) NSArray *children;//子节点数组


@end
