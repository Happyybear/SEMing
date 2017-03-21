//
//  CTerminalModel.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYBaseModel.h"
#import "CMPModel.h"

@interface CTerminalModel : HYBaseModel

@property (nonatomic,copy) NSString *term_companyID;//所属公司ID

@property (nonatomic,copy) NSString *term_UI_local;//显示位置

@property (nonatomic,copy) NSString *term_ID;//终端地址(前四个终端地址,最后一个主站地址)

@property (nonatomic,copy) NSString *term_SIM;//sim卡号地址

@property (nonatomic,copy) NSString *term_IP;//终端IP

@property (nonatomic,copy) NSString *term_port;//终端端口

@property (nonatomic,copy) NSString *term_type;//终端类型

@property (nonatomic,strong) NSArray *term_detail;//测量点个数,测量点1...测量点n

- (void)addMpChildren:(CMPModel *)mp;

@end
