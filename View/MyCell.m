//
//  MyCell.m
//  SEM
//
//  Created by xlc on 16/8/16.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import "MyCell.h"

@implementation MyCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0,SCREEN_W/3, 30)];
        [self.nameLabel setFont:[UIFont systemFontOfSize:11]];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.nameLabel];
        self.timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/3,0 ,SCREEN_W/3, 30)];
        //self.timeLabel.adjustsFontSizeToFitWidth = YES;
        self.timeLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.timeLabel];
        self.tableCodeLabel = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/3*2, 0,SCREEN_W/3, 30)];
        [self.tableCodeLabel setFont:[UIFont systemFontOfSize:11]];
        self.tableCodeLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.tableCodeLabel];
    }
    return self;
}

- (void)setNameLabel:(NSString *)text1 timeLabel:(NSString *)text2 tableCodeLabel:(NSString *)text3
{
    _nameLabel.text = text1;
    _timeLabel.text = text2;
    _tableCodeLabel.text = text3;
}

-(void)setCellWithModel:(DataModel *)data
{
    _nameLabel.text = data.name;
    _timeLabel.text = [NSString stringWithFormat:@"20%@-%@-%@ %@:%@",data.year,data.Month,data.day,data.hour,data.mm];
    _tableCodeLabel.text = data.data ;
}

@end