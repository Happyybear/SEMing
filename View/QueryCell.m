//
//  QueryCell.m
//  SEM
//
//  Created by xlc on 16/9/29.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import "QueryCell.h"

@implementation QueryCell

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
        
        self.timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W/5, 30)];
        self.timeLabel.backgroundColor = RGB(67, 205, 128);
        [self.timeLabel setTextColor:[UIColor whiteColor]];
        [self.timeLabel setFont:[UIFont systemFontOfSize:11]];
        self.timeLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.timeLabel];
        
        self.nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/5, 0, SCREEN_W/5, 30)];
        self.nameLabel.backgroundColor = RGB(67, 205, 128);
        [self.nameLabel setTextColor:[UIColor whiteColor]];
        [self.nameLabel setFont:[UIFont systemFontOfSize:11]];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.nameLabel];
        
        self.tableCodeLabel1 = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/5*2, 0, SCREEN_W/5, 30)];
        [self.tableCodeLabel1 setFont:[UIFont systemFontOfSize:11]];
        self.tableCodeLabel1.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.tableCodeLabel1];
        
        self.tableCodeLabel2 = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/5*3, 0, SCREEN_W/5, 30)];
        [self.tableCodeLabel2 setFont:[UIFont systemFontOfSize:11]];
        self.tableCodeLabel2.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.tableCodeLabel2];
        
        self.tableCodeLabel3 = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/5*4, 0, SCREEN_W/5, 30)];
        [self.tableCodeLabel3 setFont:[UIFont systemFontOfSize:11]];
        self.tableCodeLabel3.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.tableCodeLabel3];
        
    }
    return self;
}

- (void)setNameLabel:(NSString *)name timeLabel:(DataModel *)data tableCodeLabel1:(NSString *)text1 tableCodeLabel2:(NSString *)text2 tableCodeLable3:(NSString *)text3 andWithRequest_Value:(int )value
{
    
    NSString * timeString = [[NSString alloc] init];
//    NSString * hour,* minute;
    int hour = 0, minute = 0;
    minute = minute + [data.point intValue] * 15;
    hour = minute / 60;
    minute = minute % 60;
    timeString = [NSString stringWithFormat:@"%02d-%02d %02d:%02d",[data.Month intValue] ,[data.day intValue],hour,minute];
    _timeLabel.text = timeString;
    _nameLabel.text = name;
    if (value == 1) {//2value
        float t1 = [text1 floatValue] * [data.pt intValue] * [data.ct intValue];
        float t2 = [text2 floatValue] * [data.pt intValue] * [data.ct intValue];
        float t3 = [text3 floatValue] * [data.pt intValue] * [data.ct intValue];
        text1 = [NSString stringWithFormat:@"%f",t1];
        text2 = [NSString stringWithFormat:@"%f",t2];
        text3 = [NSString stringWithFormat:@"%f",t3];
    }
    _tableCodeLabel1.text = [NSString stringWithFormat:@"%.4f",[text1 floatValue]];
    _tableCodeLabel2.text = [NSString stringWithFormat:@"%.4f",[text2 floatValue]];
    _tableCodeLabel3.text = [NSString stringWithFormat:@"%.4f",[text3 floatValue]];
}

@end
