//
//  TWLAlertView.h
//  DefinedSelf
//
//  Created by 涂婉丽 on 15/12/15.
//  Copyright © 2015年 涂婉丽. All rights reserved.
//xchjds

#import <UIKit/UIKit.h>
@protocol TWlALertviewDelegate<NSObject>
@optional
-(void)didClickButtonAtIndex:(NSUInteger)index password:(NSString *)password;
- (void)successPassword;
@end
@interface TWLAlertView : UIView<UITextFieldDelegate>
@property (nonatomic,strong)UIView *blackView;
@property (strong,nonatomic)UIView * alertview;
@property (strong,nonatomic)NSString * title;
@property (nonatomic,copy)NSString *contentStr;
@property (nonatomic,strong)UILabel *tipLable;
@property (weak,nonatomic) id<TWlALertviewDelegate> delegate;
@property (nonatomic,assign)NSInteger type;
@property (nonatomic,assign)NSInteger numBtn;
@property (nonatomic,copy)NSString *password;
@property (nonatomic,retain)NSArray *btnTitleArr;
@property (nonatomic,retain)UITextField *textF;
@property (nonatomic,retain)UITextField *startF1;
@property (nonatomic,retain)UITextField *endF1;
@property (nonatomic,retain)UITextField *startF2;
@property (nonatomic,retain)UITextField *endF2;
@property (nonatomic,retain)UITextField *startF3;
@property (nonatomic,retain)UITextField *endF3;
@property (nonatomic,retain)UITextField *startF4;
@property (nonatomic,retain)UITextField *endF4;
@property (nonatomic,retain)UITextField *startF5;
@property (nonatomic,retain)UITextField *endF5;
@property (nonatomic,retain)UITextField *startF6;
@property (nonatomic,retain)UITextField *endF6;

@property (nonatomic,retain)UILabel *nameLabel;
@property (nonatomic,retain)UILabel *timeLabel;
@property (nonatomic,retain)UILabel *labelA;
@property (nonatomic,retain)UILabel *labelB;
@property (nonatomic,retain)UILabel *labelC;
@property (nonatomic,retain)UILabel *nameLabel1;
@property (nonatomic,retain)UILabel *timeLabel1;
@property (nonatomic,retain)UILabel *labelA1;
@property (nonatomic,retain)UILabel *labelB1;
@property (nonatomic,retain)UILabel *labelC1;

@property (nonatomic,copy) NSString *str1;
@property (nonatomic,copy) NSString *str2;
@property (nonatomic,copy) NSString *str3;
@property (nonatomic,copy) NSString *str4;
@property (nonatomic,copy) NSString *str5;
@property (nonatomic,copy) NSString *str6;

-(void)initWithTitle:(NSString *) title contentStr:(NSString *)content type:(NSInteger)type btnNum:(NSInteger)btnNum btntitleArr:(NSArray *)btnTitleArr;
@end
