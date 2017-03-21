//
//  HYUserModel.h
//  HYSEM
//
//  Created by xlc on 16/11/23.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HYUserModel : HYBaseModel

@property (nonatomic,assign) UInt64 user_ID;

@property (nonatomic,assign) UInt64 check_ID;

@property (nonatomic,assign) Byte user_type; //用户类型,1 2 3 4 是4的话说明是试用版,只有部分功能

@property (nonatomic,copy) NSString *username;

@property (nonatomic,copy) NSString *password;

@end
