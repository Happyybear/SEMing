//
//  HYRemoteViewController.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYRemoteViewController.h"
#import "WGMSectorButton.h"

@interface HYRemoteViewController ()<TWlALertviewDelegate>
{
    TWLAlertView *alertView;
    NSString *_mpID;
    GCDAsyncSocket *_sendSocket;
    NSString *ipv6Addr;
}
@property (strong, nonatomic) IBOutlet WGMSectorButton *offBtn;
@property (strong, nonatomic) IBOutlet WGMSectorButton *relieveBtn;
@property (strong, nonatomic) IBOutlet WGMSectorButton *warningBtn;
@property (strong, nonatomic) IBOutlet WGMSectorButton *onBtn;
@property (strong, nonatomic) IBOutlet WGMSectorButton *middleBtn;
@property (strong, nonatomic) IBOutlet UIImageView *middleImage;

@end

@implementation HYRemoteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.titleLabel.text = @"遥控器";
    [self.leftButton setImage:[UIImage imageNamed:@"icon_function"] forState:UIControlStateNormal];
    [self setLeftButtonClick:@selector(leftButtonClick)];
    ipv6Addr = [self convertHostToAddress:SocketHOST];
    _middleImage.image = [UIImage imageNamed:@"image_lock1"];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
}

-(NSString *)convertHostToAddress:(NSString *)host {
    
    NSError *err = nil;
    
    NSMutableArray *addresses = [GCDAsyncSocket lookupHost:host port:0 error:&err];
    
    //    NSLog(@"address%@",addresses);
    
    NSData *address4 = nil;
    NSData *address6 = nil;
    
    for (NSData *address in addresses)
    {
        if (!address4 && [GCDAsyncSocket isIPv4Address:address])
        {
            address4 = address;
        }
        else if (!address6 && [GCDAsyncSocket isIPv6Address:address])
        {
            address6 = address;
        }
    }
    
    NSString *ip;
    
    if (address6) {
        //        NSLog(@"ipv6%@",[GCDAsyncSocket hostFromAddress:address6]);
        ip = [GCDAsyncSocket hostFromAddress:address6];
    }else {
        //        NSLog(@"ipv4%@",[GCDAsyncSocket hostFromAddress:address4]);
        ip = [GCDAsyncSocket hostFromAddress:address4];
    }
    
    return ip;
    
}


- (void)initSocket
{
    if ([_sendSocket isConnected]) {
        [_sendSocket disconnect];
    }
    _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
}

//告警
- (IBAction)warningClick:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"jiesuo"] == YES) {
        if ([self judgeMpBlank] == YES) {
            if ([self judgeMpCorrect] == YES) {
                //组帧
                [self initSocket];
                [self writeDataToHost:2];
                
            }else{
                [UIView addMJNotifierWithText:@"请选择正确表" dismissAutomatically:NO];
            }
        }else{
            [UIView addMJNotifierWithText:@"请选择一块表" dismissAutomatically:NO];
        }
    }else{
        [UIView addMJNotifierWithText:@"请先解锁" dismissAutomatically:NO];
    }
}

//停电
- (IBAction)offPowerClick:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"jiesuo"] == YES) {
        if ([self judgeMpBlank] == YES) {
            if ([self judgeMpCorrect] == YES) {
                //组帧
                [self initSocket];
                [self writeDataToHost:0];
            }else{
                [UIView addMJNotifierWithText:@"请选择正确表" dismissAutomatically:NO];
            }
        }else{
            [UIView addMJNotifierWithText:@"请选择一块表" dismissAutomatically:YES];
        }
        
    }else{
        [UIView addMJNotifierWithText:@"请先解锁" dismissAutomatically:NO];
    }
}

//送电
- (IBAction)onPowerClick:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"jiesuo"] == YES) {
        if ([self judgeMpBlank] == YES) {
            if ([self judgeMpCorrect] == YES) {
                //组帧
                [self initSocket];
                [self writeDataToHost:1];
            }else{
                [UIView addMJNotifierWithText:@"请选择正确表" dismissAutomatically:NO];
            }
        }else{
            [UIView addMJNotifierWithText:@"请选择一块表" dismissAutomatically:YES];
        }
        
    }else{
        [UIView addMJNotifierWithText:@"请先解锁" dismissAutomatically:NO];
    }
}

//解除
- (IBAction)relieveClick:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"jiesuo"] == YES) {
        if ([self judgeMpBlank] == YES) {
            if ([self judgeMpCorrect] == YES) {
                //组帧
                [self initSocket];
                [self writeDataToHost:3];
            }else{
                [UIView addMJNotifierWithText:@"请选择正确表" dismissAutomatically:NO];
            }
        }else{
            [UIView addMJNotifierWithText:@"请选择一块表" dismissAutomatically:YES];
        }
        
    }else{
        [UIView addMJNotifierWithText:@"请先解锁" dismissAutomatically:NO];
    }
}

//中间
- (IBAction)middleBtnClick:(id)sender {
    NSLog(@"点击了中间");
    HYSingleManager *manager = [HYSingleManager sharedManager];
    if (manager.user.user_type == 4) {
        [UIView addMJNotifierWithText:@"对不起,权限不足!" dismissAutomatically:NO];
    }else{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"jiesuo"] == YES) {
            
        }else{
            [self loadAlertView:@"操作选项" contentStr:nil btnNum:2 btnStrArr:[NSArray arrayWithObjects:@"确定",@"取消",nil] type:17];
        }

    }
}

- (void)writeDataToHost:(int)type
{
    NSString *terminal_ID;
    NSString *mp_add;
    HYSingleManager *manager = [HYSingleManager sharedManager];
    for (int i = 0; i<manager.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = manager.archiveUser.child_obj[i];
        for (int j = 0; j<company.child_obj1.count; j++) {
            CTerminalModel *terminal = company.child_obj1[j];
            for (int k = 0; k<terminal.child_obj.count; k++) {
                CMPModel *mp = terminal.child_obj[k];
                if ([_mpID isEqualToString:[NSString stringWithFormat:@"%llu",mp.strID]]) {
                    terminal_ID = terminal.term_ID;
                    mp_add = mp.mp_csAddr;
                }
            }
        }
    }
    HYExplainManager *explain = [HYExplainManager shareManager];
    NSData *data = [explain combinRemoteControlFrame:terminal_ID :mp_add :type :manager.user.check_ID];
    NSLog(@"%@",data);
    [_sendSocket writeData:data withTimeout:10 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    [sock readDataWithTimeout:10 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    Byte *dataBytes = (Byte *)[data bytes];
    HYExplainManager *manager = [HYExplainManager shareManager];
    int nLen = (int)[data length];
    Byte dataByte[nLen];
    for (int i = 0; i<[data length]; i++) {
        dataByte[i] = dataBytes[i];
    }
    int rValue = [manager GW09_AnalysisTripControl:dataByte :nLen];
    
    if (rValue == 0) {
        [SVProgressHUD showErrorWithStatus:@"通讯异常"];
    }else if (rValue == 1){
        [SVProgressHUD showSuccessWithStatus:@"通讯成功"];
    }else if (rValue == 2){
        [SVProgressHUD showErrorWithStatus:@"通讯失败"];
    }

    
    [sock readDataWithTimeout:10 tag:0];
}

- (void)TSR376_Analysis_All_Frame:(unsigned char*)dataBytes :(unsigned int)length
{
    HYExplainManager *manager = [HYExplainManager shareManager];
    unsigned int val = [manager GW09_Checkout:dataBytes :length];
    unsigned int AFN = [manager TSR376_Get_AFN_Frame:dataBytes];
    switch (val) {
        case 0:
            //错误帧
            [SVProgressHUD showErrorWithStatus:@"错误帧"];
            break;
        case 1:
            switch (AFN) {
                case 0:
                    //全部确认
                    break;
                case 1:
                    //全部否认
                    [SVProgressHUD showErrorWithStatus:@"错误帧"];
                    break;
                case 2:
                    //数据单元标识确认和否认:对收到报文中的全部数据单元标识进行逐个确认/否认
                    break;
                case 3:
                    //验证码过期否认
                    [SVProgressHUD showErrorWithStatus:@"验证码过期,请重新登录"];
                    break;
                case 4:
                    //用户验证ID,登录帧
                    
                    break;
                case 5:
                {//接收到用户档案
                    
                    break;}
                case 6:
                    //群档案
                    
                    break;
                case 7:
                {//接收单位档案
                    
                    
                    break;}
                case 8:
                {//接收线路档案
                    
                    break;}
                case 9:
                    //站线档案
                    
                    break;
                case 10:
                {
                    //终接收端档案
                    
                    break;}
                case 11:
                {//组档案
                    
                    break;}
                case 12:
                {//设备档案
                    
                    break;}
                case 13:
                {//查询2类数据
                    int iEnd;
                    [manager TSR376_Analysis_QueryInfFame:dataBytes bufer_len:length iEnd:&iEnd];
                    break;
                }
                default:
                    break;
            }
            
        default:
            break;
    }
}


//判断所选表是否为空
- (BOOL)judgeMpBlank
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _mpID = [defaults objectForKey:@"mpID"];
    if ([self isBlankString:_mpID] == NO) {
        return YES;
    }
    return NO;
}

//判断字符串是否为空
- (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

//判断所选表是否正确
- (BOOL)judgeMpCorrect
{
    NSMutableArray *mp_IDArr = [NSMutableArray array];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    for (int i = 0; i<manager.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = manager.archiveUser.child_obj[i];
        for (int j = 0; j<company.child_obj1.count; j++) {
            CTerminalModel *terminal = company.child_obj1[j];
            for (int k = 0; k<terminal.child_obj.count; k++) {
                CMPModel *mp = terminal.child_obj[k];
                [mp_IDArr addObject:[NSString stringWithFormat:@"%llu",mp.strID]];
            }
        }
    }
    for (int i = 0; i<mp_IDArr.count; i++) {
        if ([_mpID isEqualToString:mp_IDArr[i]]) {
            return YES;
        }
    }
    return NO;
}

//判断密码是否正确
- (void)judgePassWord
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UITextField *textField = (UITextField *)[alertView viewWithTag:8888];
    UITextField *textField1 = (UITextField *)[alertView viewWithTag:8889];
    NSString *string = textField.text;
    NSString *string1 = textField1.text;
    if ([string isEqualToString:[defaults objectForKey:@"password"]]) {
        if ([string1 isEqualToString:@"000000"]) {
            [_middleImage setImage:[UIImage imageNamed:@"image_unlock1"]];
            [self cancleView];
            [defaults setBool:YES forKey:@"jiesuo"];
            [defaults synchronize];
            [self performSelector:@selector(offButton) withObject:nil afterDelay:20.0f];
        }else{
            [UIView addMJNotifierWithText:@"设备密码错误,请重新输入" dismissAutomatically:NO];
        }
    }else{
        [UIView addMJNotifierWithText:@"操作员密码错误,请重新输入" dismissAutomatically:NO];
    }
}

- (void)loadAlertView:(NSString *)title contentStr:(NSString *)content btnNum:(NSInteger)num btnStrArr:(NSArray *)array type:(NSInteger)typeStr
{
    alertView = [[TWLAlertView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W, SCREEN_H)];
    [alertView initWithTitle:title contentStr:content type:typeStr btnNum:num btntitleArr:array];
    alertView.delegate = self;
    UIView *keywindow = [[UIApplication sharedApplication] keyWindow];
    [keywindow addSubview:alertView];
}

-(void)didClickButtonAtIndex:(NSUInteger)index password:(NSString *)password{
    switch (index) {
        case 101:
            [self cancleView];
            break;
        case 100:
            //判断管理员密码是否正确
            [self judgePassWord];
            break;
        default:
            break;
    }
}

//关闭按钮
- (void)offButton
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"jiesuo"];
    [_middleImage setImage:[UIImage imageNamed:@"image_lock1"]];
}

- (void)cancleView
{
    [UIView animateWithDuration:0.3 animations:^{
        alertView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [alertView removeFromSuperview];
        alertView = nil;
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)leftButtonClick
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
