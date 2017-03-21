//
//  CaTreeModel.h
//  SEM
//
//  Created by xlc on 16/11/2.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Node.h"

@interface CaTreeModel : NSObject

@property (nonatomic,strong) Node *node;

@property (nonatomic,copy) NSString *MpID;

@property (nonatomic,assign) BOOL selected;


@end
