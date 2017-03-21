//
//  CCompanyModel.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYBaseModel.h"
#import "CTerminalModel.h"
#import "CTransitModel.h"

@interface CCompanyModel : HYBaseModel

@property (nonatomic,copy) NSString *comp_parentID;//所属群ID

@property (nonatomic,copy) NSString *comp_UI_local;//显示位置

@property (nonatomic,copy) NSString *comp_transDetail;//单位下线路的个数n,线路1...线路n

@property (nonatomic,strong) NSMutableArray *comp_terminal;

- (void)addTerminalChildren:(CTerminalModel *)terminal;

- (void)addTransitChildren:(CTransitModel *)transit;

@end
