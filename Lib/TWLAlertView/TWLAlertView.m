//
//  TWLAlertView.m
//  DefinedSelf
//
//  Created by 涂婉丽 on 15/12/15.
//  Copyright © 2015年 涂婉丽. All rights reserved.
//eregfg

#import "TWLAlertView.h"
#import "RadioButton.h"


#define k_w [UIScreen mainScreen].bounds.size.width
#define k_h [UIScreen mainScreen].bounds.size.height
@implementation TWLAlertView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //创建遮罩
        _blackView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, k_w, k_h)];
        _blackView.backgroundColor = [UIColor blackColor];
        _blackView.alpha = 0.5;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(blackClick)];
        [self.blackView addGestureRecognizer:tap];
        [self addSubview:_blackView];
        //创建alert
        self.alertview = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 270, 190)];
        self.alertview.center = self.center;
        self.alertview.layer.cornerRadius = 17;
        self.alertview.clipsToBounds = YES;
        self.alertview.backgroundColor = [UIColor whiteColor];
        [self addSubview:_alertview];
        [self exChangeOut:self.alertview dur:0.6];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _tipLable = [[UILabel alloc]initWithFrame:CGRectMake(0,0,270,43)];
    _tipLable.textAlignment = NSTextAlignmentCenter;
    [_tipLable setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    _tipLable.text = _title;
    [_tipLable setFont:[UIFont systemFontOfSize:18]];
    [_tipLable setTextColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]];
    
    [self.alertview addSubview:_tipLable];
    
    switch (_type) {
        case 10:
            self.alertview.frame = CGRectMake(0, 0, 270, 250);

            [self creatViewInAlert];
            break;
        case 11:
            self.alertview.frame = CGRectMake(0, 0, 270, 170);
            
            [self creatViewWithAlert];
            break;
        case 12:
            self.alertview.frame = CGRectMake(0, 0, 270, 170);
            [self creatViewWithPidAlert];
            break;
        case 13:
            self.alertview.frame = CGRectMake(0, 0, 270, 310);
            [self createRadioButtonAlert];
            break;
        case 14:
            self.alertview.frame = CGRectMake(0, 0, 270, 380);
            [self createRadioButtonOneAlert];
            break;
        case 15:
            self.alertview.frame = CGRectMake(0, 0, 270, 420);
            [self createRadioButtonTwoAlert];
            break;
        case 16:
            self.alertview.frame = CGRectMake(0, 0, 270, 220);
            [self createThirdAlert];
            break;
        case 17:
            self.alertview.frame = CGRectMake(0, 0, 270, 230);
            [self createFourthAlert];
            break;
        case 18:
            self.alertview.frame = CGRectMake(0, 0, 270, 180);
            [self createFifthAlert];
            break;
        default:
            break;
    }
    self.alertview.center = CGPointMake(self.center.x, self.center.y-20);
    
    [self createBtnTitle:_btnTitleArr];
}

//功率因数
- (void)createFifthAlert
{
    NSArray *labelArr = @[@"时段选择"];
    for (int i = 0; i<labelArr.count; i++) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10, 40+i*50, 100, 30)];
        label.text = labelArr[i];
        [label setFont:[UIFont systemFontOfSize:14]];
        [self.alertview addSubview:label];
    }
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:2];
    NSArray *arr = @[@"当天",@"三天",@"一周"];
    for (int i = 0; i<arr.count; i++) {
        NSString *optionTitle = arr[i];
        RadioButton* btn = [[RadioButton alloc] initWithFrame:CGRectMake(20+80*i, 65, 80, 30)];
        btn.tag = 777+i;
        
        [btn setTitle:optionTitle forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [btn setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 6,0 , 6);
        [self.alertview addSubview:btn];
        [buttons addObject:btn];
    }
    
    [buttons[0] setSelected:YES];
    [buttons[0] setGroupButtons:buttons];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"powerFactorTerday"]) {
        
        [buttons[0] setSelected:YES];
        
    }else if ([defaults boolForKey:@"powerFactorThree"]){
        
        [buttons[1] setSelected:YES];
        
    }else if ([defaults boolForKey:@"powerFactorSeven"]){
        
        [buttons[2] setSelected:YES];
        
    }
}

//遥控界面
- (void)createFourthAlert
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    UILabel *label1 = [[UILabel alloc]initWithFrame:CGRectMake(10, 55, 100, 20)];
    label1.text = @"操作员名称:";
    //    [label1 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:label1];
    UITextField *textField1 = [[UITextField alloc]initWithFrame:CGRectMake(110, 50, 100, 30)];
    textField1.layer.borderWidth = 1.0f;
    [textField1 setEnabled:NO];
    textField1.layer.borderColor = [[UIColor grayColor]CGColor];
    textField1.text = [defaults objectForKey:@"username"];
    textField1.delegate = self;
    [self.alertview addSubview:textField1];
    
    UILabel *label2 = [[UILabel alloc]initWithFrame:CGRectMake(10, 95, 100, 20)];
    label2.text = @"操作员密码:";
    //    [label2 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:label2];
    
    UITextField *textField2 = [[UITextField alloc]initWithFrame:CGRectMake(110, 90, 100, 30)];
    textField2.layer.borderWidth = 1.0f;
    textField2.tag = 8888;
    textField2.secureTextEntry = YES;
    textField2.delegate = self;
    textField2.layer.borderColor = [[UIColor grayColor]CGColor];
    [self.alertview addSubview:textField2];
    
    UILabel *label3 = [[UILabel alloc]initWithFrame:CGRectMake(10, 135, 100, 20)];
    //    [label3 setFont:[UIFont systemFontOfSize:13]];
    label3.text = @"设备密码:";
    [self.alertview addSubview:label3];
    
    UITextField *textField3 = [[UITextField alloc]initWithFrame:CGRectMake(110, 130, 100, 30)];
    textField3.layer.borderWidth = 1.0f;
    textField3.tag = 8889;
    textField3.layer.borderColor = [[UIColor grayColor]CGColor];
    textField3.text = @"000000";
    textField3.secureTextEntry = YES;
    textField3.delegate = self;
    [self.alertview addSubview:textField3];
}

- (void)createThirdAlert
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [defaults objectForKey:@"xiangqing"];
    _timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 50,50, 20)];
    _timeLabel.text = @"时间:";
    [_timeLabel setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_timeLabel];
    _timeLabel1 = [[UILabel alloc]initWithFrame:CGRectMake(70, 50, 100, 20)];
    _timeLabel1.text = dict[@"textOne"];
    [_timeLabel1 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_timeLabel1];
    
    _nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 75, 50, 20)];
    _nameLabel.text = @"名称:";
    [_nameLabel setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_nameLabel];
    _nameLabel1 = [[UILabel alloc]initWithFrame:CGRectMake(70, 75, 100, 20)];
    _nameLabel1.text = dict[@"textTwo"];
    [_nameLabel1 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_nameLabel1];
    
    _labelA = [[UILabel alloc]initWithFrame:CGRectMake(10, 100, 80, 20)];
    _labelA.text = dict[@"textSix"];
    [_labelA setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_labelA];
    _labelA1 = [[UILabel alloc]initWithFrame:CGRectMake(95, 100, 100, 20)];
    _labelA1.text = dict[@"textThree"];
    [_labelA1 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_labelA1];
    
    _labelB = [[UILabel alloc]initWithFrame:CGRectMake(10, 125, 80, 20)];
    _labelB.text = dict[@"textSeven"];
    [_labelB setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_labelB];
    _labelB1 = [[UILabel alloc]initWithFrame:CGRectMake(95, 125, 100, 20)];
    _labelB1.text = dict[@"textFour"];
    [_labelB1 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_labelB1];
    
    _labelC = [[UILabel alloc]initWithFrame:CGRectMake(10, 150, 80, 20)];
    _labelC.text = dict[@"textEight"];
    [_labelC setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_labelC];
    _labelC1 = [[UILabel alloc]initWithFrame:CGRectMake(95, 150, 100, 20)];
    _labelC1.text = dict[@"textFive"];
    [_labelC1 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:_labelC1];
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(80, 180, 110, 30)];
    [btn setTitle:@"关闭" forState:UIControlStateNormal];
    btn.layer.cornerRadius = 5;
    [btn setBackgroundColor:[UIColor colorWithRed:255/255.0 green:102/255.0 blue:102/255.0 alpha:1.0]];
    [self.alertview addSubview:btn];
    [btn addTarget:self action:@selector(blackClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)createRadioButtonTwoAlert
{
    NSArray *labelArr = @[@"一、显示项",@"二、时间项",@"三、数据项"];
    for (int i = 0; i<labelArr.count; i++) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10, 40+i*50, 100, 30)];
        label.text = labelArr[i];
        [label setFont:[UIFont systemFontOfSize:14]];
        [self.alertview addSubview:label];
    }
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:2];
    NSArray *arr = @[@"一次值",@"二次值"];
    for (int i = 0; i<arr.count; i++) {
        NSString *optionTitle = arr[i];
        RadioButton* btn = [[RadioButton alloc] initWithFrame:CGRectMake(20+80*i, 65, 80, 30)];
        btn.tag = 200+i;
        
        [btn setTitle:optionTitle forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [btn setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 6,0 , 6);
        [self.alertview addSubview:btn];
        [buttons addObject:btn];
    }
    NSMutableArray *buttons1 = [NSMutableArray arrayWithCapacity:3];
    //此处删除了'两周'的选项,待服务端能查之后重新添加即可
    NSArray *arr1 = @[@"三天",@"一周"];
    for (int i = 0; i<arr1.count; i++) {
        NSString *optionTitle = arr1[i];
        RadioButton* btn = [[RadioButton alloc] initWithFrame:CGRectMake(20+60*i, 115, 70, 30)];
        btn.tag =2000+i;
        [btn setTitle:optionTitle forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [btn setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 6,0 , 6);
        [self.alertview addSubview:btn];
        [buttons1 addObject:btn];
    }
    
    NSMutableArray *buttons2 = [NSMutableArray arrayWithCapacity:5];
    NSArray *arr2 = @[@"总功率(总有功功率、总无功功率、总视在功率)",@"电压(A相电压、B相电压、C相电压)",@"电流(A相电流、B相电流、C相电流)",@"有功功率(A相有功功率、B相有功功率、C相有功功率)",@"无功功率(A相无功功率、B相无功功率、C相无功功率)"];
    for (int i = 0; i<arr2.count; i++) {
        NSString *optionTitle = arr2[i];
        RadioButton* btn = [[RadioButton alloc] initWithFrame:CGRectMake(20, 150+40*i, 200, 60)];
        btn.titleLabel.numberOfLines = 0;
        btn.tag =20000+i;
        [btn setTitle:optionTitle forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [btn setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 6,0 , 6);
        [self.alertview addSubview:btn];
        [buttons2 addObject:btn];
    }
    [buttons[0] setSelected:YES];
    [buttons[0] setGroupButtons:buttons];
    [buttons1[0] setSelected:YES];
    [buttons1[0] setGroupButtons:buttons1];
    [buttons2[0] setSelected:YES];
    [buttons2[0] setGroupButtons:buttons2];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //判断是否第一次
    if (![defaults boolForKey:@"firstStartaaa"]) {
        [buttons[0] setSelected:YES];
        [buttons1[0] setSelected:YES];
        [buttons2[0] setSelected:YES];
    }
    //显示项
    if ([defaults boolForKey:@"yici"]) {
        [buttons[0] setSelected:YES];
    }else if ([defaults boolForKey:@"liangci"]){
        [buttons[1] setSelected:YES];
    }
    //时间项
    if ([defaults boolForKey:@"san"]) {
        [buttons1[0] setSelected:YES];
    }else if ([defaults boolForKey:@"qi"]){
        [buttons1[1] setSelected:YES];
    }else if ([defaults boolForKey:@"shisi"]){
        [buttons1[2] setSelected:YES];
    }
    //数据项
    if ([defaults boolForKey:@"zonggong"]) {
        [buttons2[0] setSelected:YES];
    }else if ([defaults boolForKey:@"dianya"]){
        [buttons2[1] setSelected:YES];
    }else if ([defaults boolForKey:@"dianliu"]){
        [buttons2[2] setSelected:YES];
    }else if ([defaults boolForKey:@"yougong"]){
        [buttons2[3] setSelected:YES];
    }else if ([defaults boolForKey:@"wugong"]){
        [buttons2[4] setSelected:YES];
    }
}

- (void)createRadioButtonOneAlert
{
    NSArray *labelArr = @[@"一、时长",@"二、时段",@"三、时段设置"];
    for (int i = 0; i<labelArr.count; i++) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10, 40+i*50, 100, 30)];
        label.text = labelArr[i];
        [label setFont:[UIFont systemFontOfSize:13]];
        [self.alertview addSubview:label];
    }
    
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:2];
    NSArray *arr = @[@"三日",@"一周"];
    for (int i = 0; i<arr.count; i++) {
        NSString *optionTitle = arr[i];
        RadioButton* btn = [[RadioButton alloc] initWithFrame:CGRectMake(20+60*i, 65, 70, 30)];
        btn.tag = 10000000+i;
        
        [btn setTitle:optionTitle forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [btn setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 6,0 , 6);
        [self.alertview addSubview:btn];
        [buttons addObject:btn];
    }
    NSMutableArray *buttons1 = [NSMutableArray arrayWithCapacity:4];
    NSArray *arr1 = @[@"全天",@"一段",@"两段",@"三段"];
    for (int i = 0; i<arr1.count; i++) {
        NSString *optionTitle = arr1[i];
        RadioButton* btn = [[RadioButton alloc] initWithFrame:CGRectMake(20+60*i, 110, 70, 30)];
        btn.tag =100000000+i;
        [btn setTitle:optionTitle forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [btn setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 6,0 , 6);
        [self.alertview addSubview:btn];
        [buttons1 addObject:btn];
    }
    
    _startF1 = [[UITextField alloc]initWithFrame:CGRectMake(65, 170,60 , 20)];
    _endF1= [[UITextField alloc]initWithFrame:CGRectMake(165, 170,60 , 20)];
    [_startF1 setBorderStyle:UITextBorderStyleLine];
    _startF1.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _startF1.returnKeyType = UIReturnKeyDone;
    [_endF1 setBorderStyle:UITextBorderStyleLine];
    _endF1.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _endF1.returnKeyType = UIReturnKeyDone;
    _startF1.delegate = self;
    _endF1.delegate = self;
    [self.alertview addSubview:_startF1];
    [self.alertview addSubview:_endF1];
    
    UILabel *label1 = [[UILabel alloc]initWithFrame:CGRectMake(125, 170, 40, 20)];
    label1.text = @"~";
    label1.textAlignment = NSTextAlignmentCenter;
    [self.alertview addSubview:label1];
    UILabel *title1 = [[UILabel alloc]initWithFrame:CGRectMake(20, 170, 45, 20)];
    title1.text = @"一时段:";
    [title1 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:title1];
    
    
    
    _startF2 = [[UITextField alloc]initWithFrame:CGRectMake(65, 195, 60, 20)];
    _endF2 = [[UITextField alloc]initWithFrame:CGRectMake(165, 195, 60, 20)];
    [_startF2 setBorderStyle:UITextBorderStyleLine];
    _startF2.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _startF2.returnKeyType = UIReturnKeyDone;
    [_endF2 setBorderStyle:UITextBorderStyleLine];
    _endF2.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _endF2.returnKeyType = UIReturnKeyDone;
    _startF2.delegate = self;
    _endF2.delegate = self;
    [self.alertview addSubview:_startF2];
    [self.alertview addSubview:_endF2];
    
    UILabel *label2 = [[UILabel alloc]initWithFrame:CGRectMake(125, 195, 40, 20)];
    label2.text = @"~";
    label2.textAlignment = NSTextAlignmentCenter;
    [self.alertview addSubview:label2];
    UILabel *title2 = [[UILabel alloc]initWithFrame:CGRectMake(20, 195, 45, 20)];
    title2.text = @"二时段:";
    [title2 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:title2];
    _startF3 = [[UITextField alloc]initWithFrame:CGRectMake(65, 220, 60, 20)];
    _endF3 = [[UITextField alloc]initWithFrame:CGRectMake(165, 220, 60, 20)];
    [_startF3 setBorderStyle:UITextBorderStyleLine];
    _startF3.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _startF3.returnKeyType = UIReturnKeyDone;
    [_endF3 setBorderStyle:UITextBorderStyleLine];
    _endF3.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _endF3.returnKeyType = UIReturnKeyDone;
    _startF3.delegate = self;
    _endF3.delegate = self;
    [self.alertview addSubview:_startF3];
    [self.alertview addSubview:_endF3];
    
    UILabel *label3 = [[UILabel alloc]initWithFrame:CGRectMake(125, 220, 40, 20)];
    label3.text = @"~";
    label3.textAlignment = NSTextAlignmentCenter;
    [self.alertview addSubview:label3];
    
    
    _startF4 = [[UITextField alloc]initWithFrame:CGRectMake(65, 245, 60, 20)];
    _endF4 = [[UITextField alloc]initWithFrame:CGRectMake(165, 245, 60, 20)];
    [_startF4 setBorderStyle:UITextBorderStyleLine];
    _startF4.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _startF4.returnKeyType = UIReturnKeyDone;
    [_endF4 setBorderStyle:UITextBorderStyleLine];
    _endF4.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _endF4.returnKeyType = UIReturnKeyDone;
    _startF4.delegate = self;
    _endF4.delegate = self;
    [self.alertview addSubview:_startF4];
    [self.alertview addSubview:_endF4];
    
    UILabel *label4 = [[UILabel alloc]initWithFrame:CGRectMake(125, 245, 40, 20)];
    label4.text = @"~";
    label4.textAlignment = NSTextAlignmentCenter;
    [self.alertview addSubview:label4];
    UILabel *title4 = [[UILabel alloc]initWithFrame:CGRectMake(20, 245, 45, 20)];
    title4.text = @"三时段:";
    [title4 setFont:[UIFont systemFontOfSize:13]];
    [self.alertview addSubview:title4];
    
    _startF5 = [[UITextField alloc]initWithFrame:CGRectMake(65, 270, 60, 20)];
    _endF5 = [[UITextField alloc]initWithFrame:CGRectMake(165, 270, 60, 20)];
    [_startF5 setBorderStyle:UITextBorderStyleLine];
    _startF5.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _startF5.returnKeyType = UIReturnKeyDone;
    [_endF5 setBorderStyle:UITextBorderStyleLine];
    _endF5.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _endF5.returnKeyType = UIReturnKeyDone;
    _startF5.delegate = self;
    _endF5.delegate = self;
    [self.alertview addSubview:_startF5];
    [self.alertview addSubview:_endF5];
    
    UILabel *label5 = [[UILabel alloc]initWithFrame:CGRectMake(125, 270, 40, 20)];
    label5.text = @"~";
    label5.textAlignment = NSTextAlignmentCenter;
    [self.alertview addSubview:label5];
    _startF6 = [[UITextField alloc]initWithFrame:CGRectMake(65, 295, 60, 20)];
    _endF6 = [[UITextField alloc]initWithFrame:CGRectMake(165, 295, 60, 20)];
    [_startF6 setBorderStyle:UITextBorderStyleLine];
    _startF6.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _startF6.returnKeyType = UIReturnKeyDone;
    [_endF6 setBorderStyle:UITextBorderStyleLine];
    _endF6.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _endF6.returnKeyType = UIReturnKeyDone;
    _startF6.delegate = self;
    _endF6.delegate = self;
    [self.alertview addSubview:_startF6];
    [self.alertview addSubview:_endF6];
    
    UILabel *label6 = [[UILabel alloc]initWithFrame:CGRectMake(125, 295, 40, 20)];
    label6.text = @"~";
    label6.textAlignment = NSTextAlignmentCenter;
    [self.alertview addSubview:label6];
    
    [buttons[0] setGroupButtons:buttons];
    [buttons[0] setSelected:YES];
    [buttons1[0] setGroupButtons:buttons1];
    [buttons1[0] setSelected:YES];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _startF1.text = [defaults objectForKey:@"st1"];
    _endF1.text = [defaults objectForKey:@"end1"];
    _startF2.text = [defaults objectForKey:@"st2"];
    _endF2.text = [defaults objectForKey:@"end2"];
    _startF3.text = [defaults objectForKey:@"st3"];
    _endF3.text = [defaults objectForKey:@"end3"];
    _startF4.text = [defaults objectForKey:@"st4"];
    _endF4.text = [defaults objectForKey:@"end4"];
    _startF5.text = [defaults objectForKey:@"st5"];
    _endF5.text = [defaults objectForKey:@"end5"];
    _startF6.text = [defaults objectForKey:@"st6"];
    _endF6.text = [defaults objectForKey:@"end6"];
    if ([defaults boolForKey:@"firstStarta"]) {
        [buttons[0] setSelected:YES];
        [buttons1[0] setSelected:YES];
    }
    if ([defaults boolForKey:@"santian"]) {
        [buttons[0] setSelected:YES];
        

    }else if ([defaults boolForKey:@"yizhou"]){
        [buttons[1] setSelected:YES];
        
    }
    
    if ([defaults boolForKey:@"quantian"]) {
        [buttons1[0] setSelected:YES];
       
    }else if ([defaults boolForKey:@"yiduan"]){
        [buttons1[1] setSelected:YES];
        
        
    }else if ([defaults boolForKey:@"liangduan"]){
        [buttons1[2] setSelected:YES];
        
        
    }else if ([defaults boolForKey:@"sanduan"]){
        [buttons1[3] setSelected:YES];
        
        
    }
}

- (void)oneWeekClick
{
    UIButton *btn2 = (UIButton *)[self.alertview viewWithTag:10000001];
    UIButton *btn3 = (UIButton *)[self.alertview viewWithTag:100000000];
    if ([btn2 isSelected]) {
        btn3.selected = YES;
    }
}

- (void)createRadioButtonAlert
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:4];
    NSArray *arr = @[@"全天(0:00~24:00)",@"日间(6:00~18:00)",@"夜间(18:00~6:00)",@"自定义"];
    CGRect btnRect = CGRectMake(20, _tipLable.frame.origin.y+8+ _tipLable.frame.size.height, self.alertview.frame.size.width-80, 30);
    
    for (int i = 0; i<arr.count; i++) {
        NSString *optionTitle = arr[i];
        RadioButton* btn = [[RadioButton alloc] initWithFrame:btnRect];
        //[btn addTarget:self action:@selector(onRadioButtonValueChanged:) forControlEvents:UIControlEventValueChanged];
        btn.tag = 1000000+i;
        btnRect.origin.y += 40;
        [btn setTitle:optionTitle forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        [btn setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
        [self.alertview addSubview:btn];
        [buttons addObject:btn];
    }
    _startF1 = [[UITextField alloc]initWithFrame:CGRectMake(55, 210,60 , 30)];
    _endF1= [[UITextField alloc]initWithFrame:CGRectMake(155, 210,60 , 30)];
    [_startF1 setBorderStyle:UITextBorderStyleLine];
    _startF1.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _startF1.returnKeyType = UIReturnKeyDone;
    [_endF1 setBorderStyle:UITextBorderStyleLine];
    _endF1.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _endF1.returnKeyType = UIReturnKeyDone;
    //[_startF becomeFirstResponder];
    //[_endF becomeFirstResponder];
    _startF1.delegate = self;
    _endF1.delegate = self;
    [self.alertview addSubview:_startF1];
    [self.alertview addSubview:_endF1];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(115, 210, 40, 30)];
    label.text = @"~";
    label.textAlignment = NSTextAlignmentCenter;
    [self.alertview addSubview:label];
    [buttons[0] setGroupButtons:buttons];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"firstStarta"]) {
        [buttons[0] setSelected:YES];
    }
    if ([defaults boolForKey:@"quantian"]) {
        [buttons[0] setSelected:YES];
    }else if ([defaults boolForKey:@"rijian"]){
        [buttons[1] setSelected:YES];
    }else if ([defaults boolForKey:@"yejian"]){
        [buttons[2] setSelected:YES];
    }else if ([defaults boolForKey:@"zidingyi"]){
        [buttons[3] setSelected:YES];
        _startF1.text = [defaults objectForKey:@"kaishi"];
        _endF1.text = [defaults objectForKey:@"jieshu"];
    }
    _startF1.text = [defaults objectForKey:@"kaishi"];
    _endF1.text = [defaults objectForKey:@"jieshu"];
}

- (void)creatViewInAlert
{
    UILabel *isCreate = [[UILabel alloc]initWithFrame:CGRectMake(20, _tipLable.frame.origin.y+8+ _tipLable.frame.size.height, self.alertview.frame.size.width-40, 30)];
    isCreate.text = @"是否创建一个就诊号？";
    isCreate.font = [UIFont boldSystemFontOfSize:16];
    UILabel *attenL = [[UILabel alloc]initWithFrame:CGRectMake(isCreate.frame.origin.x, isCreate.frame.origin.y+20, self.alertview.frame.size.width-40, 130)];
    attenL.font = [UIFont systemFontOfSize:15];
    attenL.text = _contentStr;
    
    attenL.numberOfLines = 0;
    attenL.font = [UIFont systemFontOfSize:14];
    attenL.textColor = [UIColor redColor];
    [self.alertview addSubview:attenL];
    [self.alertview addSubview:isCreate];
}
- (void)creatViewWithAlert
{
    _textF =[[UITextField alloc]initWithFrame:CGRectMake(15, _tipLable.frame.origin.y+20+ _tipLable.frame.size.height, self.alertview.frame.size.width-30, 40)];
    _textF.placeholder = @"登录密码";
    _textF.secureTextEntry = YES;
    _textF.borderStyle = UITextBorderStyleRoundedRect;
    _textF.returnKeyType = UIReturnKeyDone;
    _textF.delegate = self;
    [_textF becomeFirstResponder];
    UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_textF.frame)+20, self.alertview.frame.size.width, 0.5)];
    line.backgroundColor = [UIColor lightGrayColor];
    [self.alertview addSubview:_textF];
    
}

- (void)creatViewWithPidAlert
{
    UILabel *showL = [[UILabel alloc]initWithFrame:CGRectMake(20, _tipLable.frame.origin.y+_tipLable.frame.size.height, self.alertview.frame.size.width-40, self.alertview.frame.size.height-43-48)];
    [showL setTextColor:[UIColor colorWithRed:149/255.0 green:149/255.0 blue:149/255.0 alpha:1.0]];
    showL.numberOfLines = 0;
    [showL setFont:[UIFont systemFontOfSize:18]];
    [showL setText:_contentStr];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:showL.text];;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    [paragraphStyle setLineSpacing:9];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, showL.text.length)];
    
    showL.attributedText = attributedString;
    showL.textAlignment = NSTextAlignmentCenter;
    
    
    [self.alertview addSubview:showL];
    
}
- (void)createBtnTitle:(NSArray *)titleArr
{
    
    CGFloat m = self.alertview.frame.size.width;
    
    for (int i=0; i<_numBtn; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        if (_numBtn == 1) {
            btn.frame = CGRectMake(20, self.alertview.frame.size.height-48,(m-40), 33);
        }else{
            
            btn.frame = CGRectMake(20+i*(20+(m-60)/2), self.alertview.frame.size.height-48, (m-60)/2, 33);
        }
        
        [btn setTitle:titleArr[i] forState:UIControlStateNormal];
        btn.tag = 100+i;
        btn.layer.cornerRadius = 5;
        btn.clipsToBounds = YES;
        [btn addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:18]];
        if ([titleArr[i] isEqualToString:@"确定"]||[titleArr[i] isEqualToString:@"退出页面"]) {
//            [btn setBackgroundColor:[UIColor colorWithHexString:[ThemeSingleton sharedInstance].UINavgationBar alpha:1]];
            [btn setBackgroundColor:[UIColor colorWithRed:46/255.0 green:149/255.0 blue:250/255.0 alpha:1.0]];
        }else{
            
            [btn setBackgroundColor:[UIColor colorWithRed:255/255.0 green:102/255.0 blue:102/255.0 alpha:1.0]];
        }
        [self.alertview addSubview:btn];
    }
}
- (void)blackClick
{
    [self cancleView];
}
- (void)cancleView
{
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.alertview = nil;
    }];
    
}
-(void)exChangeOut:(UIView *)changeOutView dur:(CFTimeInterval)dur{
    
    CAKeyframeAnimation * animation;
    
    animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.duration = dur;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 0.9)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    animation.values = values;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: @"easeInEaseOut"];
    [changeOutView.layer addAnimation:animation forKey:nil];
}

-(void)clickButton:(UIButton *)button{
//    DLog(@"%ld",button.tag);
    if ([self.delegate respondsToSelector:@selector(didClickButtonAtIndex:password:)]) {
        if (_password == nil) {
            [self textFieldShouldEndEditing:_textF];
            [_textF resignFirstResponder];
        }
        if ([button.titleLabel.text isEqualToString:@"退出页面"]) {
            button.tag = 101;
        }
        [self.delegate didClickButtonAtIndex:button.tag password:_password];
    }
    //[self cancleView];
}
-(void)initWithTitle:(NSString *) title contentStr:(NSString *)content type:(NSInteger)type btnNum:(NSInteger)btnNum btntitleArr:(NSArray *)btnTitleArr

{
    _title = title;
    _type = type;
    _numBtn = btnNum;
    _btnTitleArr = btnTitleArr;
    _contentStr = content;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_startF1.text forKey:@"st1"];
    [defaults setObject:_endF1.text forKey:@"end1"];
    [defaults setObject:_startF2.text forKey:@"st2"];
    [defaults setObject:_endF2.text forKey:@"end2"];
    [defaults setObject:_startF3.text forKey:@"st3"];
    [defaults setObject:_endF3.text forKey:@"end3"];
    [defaults setObject:_startF4.text forKey:@"st4"];
    [defaults setObject:_endF4.text forKey:@"end4"];
    [defaults setObject:_startF5.text forKey:@"st5"];
    [defaults setObject:_endF5.text forKey:@"end5"];
    [defaults setObject:_startF6.text forKey:@"st6"];
    [defaults setObject:_endF6.text forKey:@"end6"];
    [defaults synchronize];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    [textField resignFirstResponder];
    return YES;
}
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
