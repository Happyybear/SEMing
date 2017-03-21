//
//  CSetModel.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYBaseModel.h"
#import "CMPModel.h"

@interface CSetModel : HYBaseModel

@property (nonatomic,copy) NSString *set_type;//组类型

@property (nonatomic,copy) NSString *set_companyID;//所属公司ID

@property (nonatomic,copy) NSString *set_parentType;//上级节点类型(1线路 2站)

@property (nonatomic,copy) NSString *set_parentID;//上级节点ID

@property (nonatomic,copy) NSString *set_UI_local;//显示位置

@property (nonatomic,copy) NSString *set_detail;//组下设备个数,设备1...设备n

- (void)addMpChildren:(CMPModel *)mp;


@end
