//
//  CTransitModel.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYBaseModel.h"
#import "CSetModel.h"

@interface CTransitModel : HYBaseModel

@property (nonatomic,copy) NSString *trans_companyID;//所属公司ID

@property (nonatomic,copy) NSString *trans_parentType;//上级节点类型

@property (nonatomic,copy) NSString *trans_parentID;//上级节点ID

@property (nonatomic,copy) NSString *trans_UI_local;//显示位置

@property (nonatomic,strong) NSArray *trans_subDetail;//线路下变电站个数n,变电站1...变电站n

@property (nonatomic,strong) NSArray *trans_setDetail;//线路下组的个数n,组1...组n

- (void)addSetChildren:(CSetModel *)set;

@end
