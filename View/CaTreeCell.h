//
//  CaTreeCell.h
//  SEM
//
//  Created by xlc on 16/11/2.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Node.h"
#import "UIButton+flag.h"

@interface CaTreeCell : UITableViewCell

@property (nonatomic,strong) UILabel *label;

@property (nonatomic,strong) UIButton *btn;

@property (nonatomic,assign) NSInteger cellLevel;

@property (nonatomic,strong) UIView *view;

@property (nonatomic,assign) NSInteger isSelected;

@property (nonatomic,strong) NSMutableArray * btnArr;

-(void)refreshWithNode:(Node *)node;

@property (nonatomic,copy) void(^bthClick)();

@property (nonatomic,strong) NSMutableArray * tempData;

@property (nonatomic,strong) NSMutableArray * dataSource;

-(void)UI;

@end
