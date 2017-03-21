//
//  MyCell.h
//  SEM
//
//  Created by xlc on 16/8/16.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataModel.h"
@interface MyCell : UITableViewCell
//{
//    UILabel *_nameLabel;
//    UILabel *_timeLabel;
//    UILabel *_tableCodeLabel;
//}

@property (nonatomic,strong) UILabel *nameLabel;

@property (nonatomic,strong) UILabel *timeLabel;

@property (nonatomic,strong) UILabel *tableCodeLabel;

- (void)setNameLabel:(NSString *)text1 timeLabel:(NSString *)text2 tableCodeLabel:(NSString *)text3;
-(void)setCellWithModel:(DataModel *)data;

@end
