//
//  QueryCell.h
//  SEM
//
//  Created by xlc on 16/9/29.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataModel.h"

@interface QueryCell : UITableViewCell

@property (nonatomic,strong) UILabel *nameLabel;

@property (nonatomic,strong) UILabel *timeLabel;

@property (nonatomic,strong) UILabel *tableCodeLabel1;

@property (nonatomic,strong) UILabel *tableCodeLabel2;

@property (nonatomic,strong) UILabel *tableCodeLabel3;


- (void)setNameLabel:(NSString *)name timeLabel:(DataModel *)data tableCodeLabel1:(NSString *)text1  tableCodeLabel2:(NSString *)text2 tableCodeLable3:(NSString *)text3 andWithRequest_Value:(int )value;

@end
