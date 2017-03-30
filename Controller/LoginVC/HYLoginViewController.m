//
//  HYLoginViewController.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYLoginViewController.h"
#import "HYScoketManage.h"

#define m_inaddr Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00}

@interface HYLoginViewController ()<sendMessage>{
    IBOutlet UITextField *userNameText;
    
    IBOutlet UITextField *passWordText;
    IBOutlet UIButton *savePass;
    
    IBOutlet UIButton *zidongLogin;
    
    GCDAsyncSocket *_sendSocket;
    NSMutableData *mData;
    int isAppend;
    int appendLen;
    NSString *ipv6Addr;
}

@end

@implementation HYLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    passWordText.secureTextEntry = YES;
    mData = [[NSMutableData alloc]init];
    isAppend = 0;
    appendLen = 0;
    ipv6Addr = [self convertHostToAddress:SocketHOST];
    //判断是否为第一次登陆
    [self judgeFirstLogin];
    //配置按钮图片
    [self configButtonImage];
    
    [self loginInput];
//    _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
}

-(void)loginInput{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //判断是否记住密码Remeber
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Remeber"]) {
        userNameText.placeholder = [defaults objectForKey:@"username"];
        NSString * a = [defaults objectForKey:@"username"];
        userNameText.text = [defaults objectForKey:@"username"];
        passWordText.text = [defaults objectForKey:@"password"];
    }else{
        userNameText.placeholder = [defaults objectForKey:@"username"];
        userNameText.text = [defaults objectForKey:@"username"];
    }
}


-(void)login
{
    Reachability *r = [Reachability reachabilityForInternetConnection];
    if ([r currentReachabilityStatus] == NotReachable) {
        [UIView addMJNotifierWithText:@"网络错误" dismissAutomatically:NO];
    }else{
        [self btnClick];
    }
}

-(void)configButtonImage{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Remeber"]) {
        savePass.selected = YES;
        
    }else{
        savePass.selected = NO;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLogin"]) {
        zidongLogin.selected = YES;
    }else{
        zidongLogin.selected = NO;
    }
    [savePass setImage:[UIImage imageNamed:@"05-2登录_10"] forState:UIControlStateSelected];
    
    //判断是否自动登录
    [zidongLogin setImage:[UIImage imageNamed:@"05-2登录_10"] forState:UIControlStateSelected];
    
}

- (void)btnClick
{
    if ([_sendSocket isConnected]) {
        [_sendSocket disconnect];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userNameText.text forKey:@"username"];
    [defaults setObject:passWordText.text forKey:@"password"];
//    [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:-1 error:nil];
    [self putSocket];
    [SVProgressHUD showWithStatus:@"正在登陆"];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
}

-(void)putSocket{
    HYScoketManage * manage = [HYScoketManage shareManager];
    manage.delegate = self;
    [manage getNetworkDatawithIP:ipv6Addr withTag:@"1"];
}

#pragma mark -- 协议方法
-(void)sendMessage{
    [SVProgressHUD showSuccessWithStatus:@"登录成功"];
    [SVProgressHUD dismiss];
    //通知侧滑页面去展示UI

    [self performSelector:@selector(SingInFirstView) withObject:nil afterDelay:1];
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


#pragma mark  --判断是否为第一次登陆
-(void)judgeFirstLogin
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"isNoFirstLogin"]) {
        //first
        savePass.selected = YES;
        [[NSUserDefaults standardUserDefaults] setObject:@"Yes" forKey:@"Remeber"];
        
        zidongLogin.selected = YES;
        [[NSUserDefaults standardUserDefaults] setObject:@"Yes" forKey:@"AutoLogin"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else{
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLogin"]) {
            if (![[NSUserDefaults standardUserDefaults] objectForKey:@"Exit"]) {
                NSLog(@"%@",userNameText.text);
                //if ([[defaults objectForKey:@"username"] length] != 0 && [[defaults objectForKey:@"password"] length] != 0) {
                [self loginInput];
                [self login];
                //}
            }
        }
    }
}


- (IBAction)loginClick:(id)sender {
    //首先判断网络状态
    Reachability *r = [Reachability reachabilityForInternetConnection];
    if ([r currentReachabilityStatus] == NotReachable) {
        [UIView addMJNotifierWithText:@"网络错误" dismissAutomatically:NO];
    }else{
        [self btnClick];
    }
}

- (IBAction)savePassClick:(id)sender {
    if(!savePass.selected){
        savePass.selected = YES;
        //记住密码
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSString stringWithFormat:@"%@",passWordText.text] forKey:@"password"];
        //记住密码
        [defaults setObject:@"yes" forKey:@"Remeber"];
        [defaults synchronize];//同步
    }else{
        savePass.selected = NO;
        //记住密码
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:nil forKey:@"password"];
        //记住密码
        [defaults setObject:nil forKey:@"Remeber"];
        [defaults synchronize];//同步
        
    }

}

- (IBAction)zidongLoginClick:(id)sender {
    if(!zidongLogin.selected){
        zidongLogin.selected = YES;
        //自动登录
        [[NSUserDefaults standardUserDefaults] setObject:@"aa" forKey:@"AutoLogin"];
    }else{
        zidongLogin.selected = NO;
        //自动登录
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"AutoLogin"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

////建立连接
//- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
//    
//    HYExplainManager *manager = [HYExplainManager shareManager];
//    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
//    unsigned char outbuf[1024];
//    //组建登录帧
//    int aaa = [manager TSR376_Get_Land_Fame:inbuf :userNameText.text :passWordText.text :outbuf];
//    //帧的长度
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:userNameText.text forKey:@"username"];
//    [defaults setObject:passWordText.text forKey:@"password"];
//    [defaults synchronize];
//    NSData *data = [NSData dataWithBytes:outbuf length:aaa];
//    [_sendSocket writeData:data withTimeout:10 tag:0];
////    NSLog(@"%@",data);
//    [sock readDataWithTimeout:10 tag:0];
//    
//}
////接收数据
//- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
//    HYExplainManager *manager = [HYExplainManager shareManager];
//    unsigned char outbuf[1024*4];
//    int rLen;
//    int i = 0,len = 0;
//    Byte *dataBytes;
//    if (1 == isAppend) {
//        [mData appendData:data];
//        dataBytes = (Byte *)[mData bytes];
//        appendLen += [data length];
//    }else{
//        dataBytes = (Byte *)[data bytes];
//        appendLen = (int)[data length];
//        
//    }
//    //首先分析是否粘包
//    while (8<appendLen-i) {//一个完整的帧至少有8位
//        len = [manager TSR376_Get_All_frame:&dataBytes[i] :(appendLen-i) :outbuf :&rLen];
//        if (1 == len) {
//            //开始解析
//            [self TSR376_Analysis_All_Frame:&dataBytes[i] :rLen];
//            isAppend = 0;
//        }else if (0 == len){
//            NSLog(@"存储不够长度的帧---%d", rLen);
//            mData = [NSMutableData data];
//            [mData appendBytes:outbuf length:rLen];
//            appendLen = rLen;
//            isAppend = 1;
//        }else if (-1 == len){
//            NSLog(@"帧不对");
//            isAppend = 0;
//            mData = [NSMutableData data];
//            break;
//        }
//        if (0 == rLen) {
//            isAppend = 0;
//            break;
//        }
//        i += rLen;
//    }
//    
//    [sock readDataWithTimeout:10 tag:0];
//}
//
//
//#pragma mark --  首先判断所有的数据是否请求完
//- (BOOL)JudgeAllFrameIsRequest
//{
//    //依据是字典里边的key在其他value里是否存在
//    HYSingleManager *single = [HYSingleManager sharedManager];
//    NSArray *allKeys = [single.obj_dict allKeys];
//    NSArray *allVaules = [single.obj_dict allValues];
//    BOOL ret1 = YES;
//    BOOL ret2 = YES;
//    BOOL ret3 = YES;
//    if (allKeys.count == 0||!allKeys) {
//        return false;
//    }
//    for (int i = 0; i<allKeys.count; i++) {
//        HYBaseModel *baseModel = allVaules[i];
//        if ([baseModel.request_Type isEqualToString:@"company"]) {
//            CCompanyModel *company = allVaules[i];
//            for (int j = 0; j<company.children.count; j++) {
//                //占线是否都存在
//                ret1 = [allKeys containsObject:company.children[j]];
//                if (ret1 == NO) {
//                    return false;
//                }
//            }
//            for (int j = 0; j<company.children1.count; j++) {
//                //终端是否都存在
//                ret2 = [allKeys containsObject:company.children1[j]];
//                if (ret2 == NO) {
//                    
//                    return false;
//                }
//            }
//        }else{
//            //其他   （组、设备)
//            for (int j = 0; j<baseModel.children.count; j++) {
//                ret3 = [allKeys containsObject:baseModel.children[j]];
//                if (ret3 == NO) {
//                    return false;
//                }
//            }
//        }
//    }
//    return true;
//
//}
//#pragma mark --开始解析正确的帧
//- (void)TSR376_Analysis_All_Frame:(unsigned char*)dataBytes :(unsigned int)length
//{
//    HYExplainManager *manager = [HYExplainManager shareManager];
//    HYSingleManager *single = [HYSingleManager sharedManager];
//    unsigned int val = [manager GW09_Checkout:dataBytes :length];//验证是否符合标准
//    unsigned int AFN = [manager TSR376_Get_AFN_Frame:dataBytes];
//    switch (val) {
//        case 0:
//            //错误帧
//            [SVProgressHUD showErrorWithStatus:@"错误帧"];
//            break;
//        case 1:
//            switch (AFN) {
//                case 0:
//                    //全部确认
//                    break;
//                case 1:
//                    //全部否认
//                    [SVProgressHUD showErrorWithStatus:@"错误帧"];
//                    break;
//                case 2:
//                    //数据单元标识确认和否认:对收到报文中的全部数据单元标识进行逐个确认/否认
//                    break;
//                case 3:
//                    //验证码过期否认
//                    [SVProgressHUD showErrorWithStatus:@"登录过期,请重新登录"];
//                    break;
//                case 4:
//                    //用户验证ID,登录帧
//                    [self TSR376_Analysis_Land_return:dataBytes :length];
//                    break;
//                case 5:
//                {//接收到用户档案
//#warning po
//                    int iEnd;
//                    [manager TSR376_Analysis_UsrInf:dataBytes :length :single.user.user_ID :iEnd];
//                    unsigned char outbuf[1024];
//                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
//                    
//                    NSArray *keyArr = [single.obj_dict allKeys];
//                    NSArray *valueArr = [single.obj_dict allValues];
//                    for (int i = 0; i<keyArr.count; i++) {
//                        HYBaseModel *model = valueArr[i];
//                        if ([model.request_Type isEqualToString:@"user"]) {
//                            HYUserModel *user = valueArr[i];
//                            if (user.isRequest == false) {
//                                //请求单位档案
//                                for (int j = 0; j<user.children.count; j++) {
//                                    int bufLength = [manager TSR376_GetACK_CompanyInfFame:inbuf Company_ID:[user StringToUInt64:user.children[j]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data1 = [NSData dataWithBytes:outbuf length:bufLength];
//                                    
//                                    [_sendSocket writeData:data1 withTimeout:10 tag:0];
//                                }
//                                user.isRequest = true;       //发送完一个就将请求状态设置为true
//                            }
//                        }
//                    }
//                    
//                    break;}
//                case 6:
//                    //群档案
//                    
//                    break;
//                case 7:
//                {//接收单位档案
//                /*
//                 
//                 
//                 iEnd字段表示是否
//                 inbuf数组是请求时用到的地址
//                 isRequest表示某该单元下的数据是否请求结束
//                 request_type表示保存数据类型,根据此字段可得到将要请求的类型
//                 组装请求占线的帧，返回帧的长度- (int)TSR376_GetACK_LineInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID Line_ID:(UInt64)Line_ID Usr_check_ID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData
//                     */
//                    int iEnd;
//                    [manager TSR376_Analysis_CompanyInf:dataBytes bufer_len:length Company_ID:single.company.strID iEnd:iEnd];
//                    unsigned char outbuf[1024];
//                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
//                    
//                    NSArray *keyArr = [single.obj_dict allKeys];
//                    NSArray *valueArr = [single.obj_dict allValues];
//                    for (int i = 0; i<keyArr.count; i++) {
//                        HYBaseModel *model = valueArr[i];
//                        if ([model.request_Type isEqualToString:@"company"]) {
//                            CCompanyModel *company = valueArr[i];
//                            if (company.isRequest == false) {
//                                //请求占线
//                                for (int j = 0; j<company.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_LineInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Line_ID:[company StringToUInt64:company.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data2 = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data2 withTimeout:10 tag:0];
//                                }
//                                //请求终端
//                                for (int k = 0; k<company.children1.count; k++) {
//                                    int length = [manager TSR376_GetACK_TerminalInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Terminal_ID:[company StringToUInt64:company.children1[k]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data3 = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data3 withTimeout:10 tag:0];
//                                }
//                                company.isRequest = true;
//                            }
//                        }else if ([model.request_Type isEqualToString:@"transit"]){
//                            //请求组档案
//                            CTransitModel *transit = valueArr[i];
//                            if (transit.isRequest == false) {
//                                for (int j = 0; j<transit.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_SetInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Set_ID:[transit StringToUInt64:transit.children[j]] Usr_CheckID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data withTimeout:10 tag:0];
//                                }
//                                transit.isRequest = true;
//                                
//                            }
//
//                        }else if ([model.request_Type isEqualToString:@"set"]){
//                            //请求设备档案
//                            CSetModel *set = valueArr[i];
//                            if (set.isRequest == false) {
//                                for (int j = 0; j<set.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_MPPowerInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] MPPower_ID:[set StringToUInt64:set.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data withTimeout:10 tag:0];
//                                }
//                                set.isRequest = true;
//                            }
//
//                        }
//                    }
//                    
//                    break;}
//                case 8:
//                {//接收线路档案
//                    int iEnd;
//                    [manager TSR376_Analysis_LineInf:dataBytes bufer_len:length Company_ID:single.company.strID Line_ID:[single.company.children[0] strID] iEnd:iEnd];
//                    
//                    //请求组档案
//                    unsigned char outbuf[1024];
//                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
//                    
//                    NSArray *keyArr = [single.obj_dict allKeys];
//                    NSArray *valueArr = [single.obj_dict allValues];
//                    for (int i = 0; i<keyArr.count; i++) {
//                        HYBaseModel *model = valueArr[i];
//                        if ([model.request_Type isEqualToString:@"company"]) {
//                            ////请求占线档案
//                            CCompanyModel *company = valueArr[i];
//                            if (company.isRequest == false) {
//                                //占线
//                                for (int j = 0; j<company.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_LineInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Line_ID:[company StringToUInt64:company.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data2 = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data2 withTimeout:10 tag:0];
//                                }
//                                //终端
//                                for (int k = 0; k<company.children1.count; k++) {
//                                    int length = [manager TSR376_GetACK_TerminalInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Terminal_ID:[company StringToUInt64:company.children1[k]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data3 = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data3 withTimeout:10 tag:0];
//                                }
//                                company.isRequest = true;
//
//                            }
//                        }else if ([model.request_Type isEqualToString:@"transit"]){
//                            //请求组档案
//                            CTransitModel *transit = valueArr[i];
//                            if (transit.isRequest == false) {
//                                for (int j = 0; j<transit.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_SetInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Set_ID:[transit StringToUInt64:transit.children[j]] Usr_CheckID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data withTimeout:10 tag:0];
//                                }
//                                transit.isRequest = true;
//
//                            }
//                            }else if ([model.request_Type isEqualToString:@"set"]){
//                            //请求设备档案
//                                CSetModel *set = valueArr[i];
//                                if (set.isRequest == false) {
//                                    for (int j = 0; j<set.children.count; j++) {
//                                        int length = [manager TSR376_GetACK_MPPowerInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] MPPower_ID:[set StringToUInt64:set.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
//                                        NSData *data = [NSData dataWithBytes:outbuf length:length];
//                                        [_sendSocket writeData:data withTimeout:10 tag:0];
//                                    }
//                                    set.isRequest = true;
//                                }
//
//                        }
//                    }
//                    break;}
//                case 9:
//                    //站线档案
//                    
//                    break;
//                case 10:
//                {
//                    //终接收端档案
//                    int iEnd;
//                    CSetModel *model = [single.company.children[0] children][0];
//                    [manager TSR376_Analysis_TerminalInf:dataBytes bufer_len:length Company_ID:single.company.strID Terminal_ID:model.strID iEnd:iEnd];
//                    break;}
//                case 11:
//                {//组档案
//                    int iEnd;
//                    CSetModel *modle = [single.company.children[0] children][0];
//                    [manager TSR376_Analysis_SetInf:dataBytes bufer_len:length Company_ID:single.company.strID Set_ID:modle.strID iEnd:iEnd];
//                    unsigned char outbuf[1024];
//                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
//                    
//                    NSArray *keyArr = [single.obj_dict allKeys];
//                    NSArray *valueArr = [single.obj_dict allValues];
//                    for (int i = 0; i<keyArr.count; i++) {
//                        HYBaseModel *model = valueArr[i];
//                        if ([model.request_Type isEqualToString:@"company"]) {
//                            ////请求占线档案
//                            CCompanyModel *company = valueArr[i];
//                            if (company.isRequest == false) {
//                                //占线
//                                for (int j = 0; j<company.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_LineInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Line_ID:[company StringToUInt64:company.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data2 = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data2 withTimeout:10 tag:0];
//                                }
//                                //终端
//                                for (int k = 0; k<company.children1.count; k++) {
//                                    int length = [manager TSR376_GetACK_TerminalInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Terminal_ID:[company StringToUInt64:company.children1[k]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data3 = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data3 withTimeout:10 tag:0];
//                                }
//                                company.isRequest = true;
//                            }
//                        }else if ([model.request_Type isEqualToString:@"transit"]){
//                            //请求组档案
//                            CTransitModel *transit = valueArr[i];
//                            if (transit.isRequest == false) {
//                                for (int j = 0; j<transit.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_SetInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Set_ID:[transit StringToUInt64:transit.children[j]] Usr_CheckID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data withTimeout:10 tag:0];
//                                }
//                                transit.isRequest = true;
//                                
//                            }
//                        }else if ([model.request_Type isEqualToString:@"set"]){
//                            //请求设备档案
//                            CSetModel *set = valueArr[i];
//                            if (set.isRequest == false) {
//                                for (int j = 0; j<set.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_MPPowerInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] MPPower_ID:[set StringToUInt64:set.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data withTimeout:10 tag:0];
//                                }
//                                set.isRequest = true;
//                            }
//                        }
//                    }
//                    
//                    break;}
//                case 12:
//                {//设备档案
//                    int iEnd;
//                    [manager TSR376_Analysis_MPPowerInf:dataBytes bufer_len:length Company_ID:single.company.strID MPPower_ID:single.company.strID iEnd:iEnd];
//                    unsigned char outbuf[1024];
//                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
//                    NSArray *keyArr = [single.obj_dict allKeys];
//                    NSArray *valueArr = [single.obj_dict allValues];
//                    for (int i = 0; i<keyArr.count; i++) {
//                        HYBaseModel *model = valueArr[i];
//                        if ([model.request_Type isEqualToString:@"company"]) {
//                            ////请求占线档案
//                            CCompanyModel *company = valueArr[i];
//                            if (company.isRequest == false) {
//                                //占线
//                                for (int j = 0; j<company.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_LineInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Line_ID:[company StringToUInt64:company.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data2 = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data2 withTimeout:10 tag:0];
//                                }
//                                //终端
//                                for (int k = 0; k<company.children1.count; k++) {
//                                    int length = [manager TSR376_GetACK_TerminalInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Terminal_ID:[company StringToUInt64:company.children1[k]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data3 = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data3 withTimeout:10 tag:0];
//                                }
//                                company.isRequest = true;
//                            }
//                        }else if ([model.request_Type isEqualToString:@"transit"]){
//                            //请求组档案
//                            CTransitModel *transit = valueArr[i];
//                            if (transit.isRequest == false) {
//                                for (int j = 0; j<transit.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_SetInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Set_ID:[transit StringToUInt64:transit.children[j]] Usr_CheckID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data withTimeout:10 tag:0];
//                                }
//                                transit.isRequest = true;
//                            }
//                        }else if ([model.request_Type isEqualToString:@"set"]){
//                            //请求设备档案
//                            CSetModel *set = valueArr[i];
//                            if (set.isRequest == false) {
//                                for (int j = 0; j<set.children.count; j++) {
//                                    int length = [manager TSR376_GetACK_MPPowerInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] MPPower_ID:[set StringToUInt64:set.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
//                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
//                                    [_sendSocket writeData:data withTimeout:10 tag:0];
//                                }
//                                set.isRequest = true;
//                            }
//                        }
//                    }
//
//                    break;}
//                default:
//                    break;
//            }
//            
//        default:
//            break;
//    }
//    //判断所有的数据是否请求完
//    if ([self JudgeAllFrameIsRequest] == YES) {
//        //建立档案
//        [self SetArchives];
//    }
//
//}
//
//
//
//#pragma mark --建立档案
//- (void)SetArchives
//{
//    HYSingleManager *manager = [HYSingleManager sharedManager];
//    HYUserModel *user = [[HYUserModel alloc]init];
//    
//    NSArray *allKeys = [manager.obj_dict allKeys];
//    
//    NSArray *allValues = [manager.obj_dict allValues];
//    
//    for (int i = 0; i<allKeys.count; i++) {
//        
//        HYBaseModel *baseModel = allValues[i];
//        baseModel.archiveModel = [[HYBaseModel alloc]init];
//        if ([baseModel.request_Type isEqualToString:@"user"]) {
//            user = (HYUserModel *)baseModel;
//        }
//        if (![baseModel.request_Type isEqualToString:@"company"]) {
//            for (int j = 0; j<baseModel.children.count; j++) {
//                HYBaseModel *model = manager.obj_dict[baseModel.children[j]];
//                model.nd_terminal_Parent = baseModel;
//                [baseModel addChildren:model];
//            }
//        }else{
//            for (int j = 0; j<baseModel.children.count; j++) {
//                HYBaseModel *model = manager.obj_dict[baseModel.children[j]];
//                model.nd_parent = baseModel;
//                [baseModel addChildren:model];
//            }
//            for (int j = 0; j<baseModel.children1.count; j++) {
//                HYBaseModel *model = manager.obj_dict[baseModel.children1[j]];
//                model.nd_parent = baseModel;
//                [baseModel addChildren1:model];
//            }
//
//        }
//
//    }
//    
//    manager.archiveUser = user;
//    [SVProgressHUD showSuccessWithStatus:@"登录成功"];
//    [SVProgressHUD dismiss];
//    //通知侧滑页面去展示UI
////    [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateUI" object:nil];
//    [self performSelector:@selector(SingInFirstView) withObject:nil afterDelay:1];
//}

- (void)SingInFirstView
{
    //block回调
    self.block();
}

////登录
//#pragma mark -- 验证登录帧的正确性
//- (void)TSR376_Analysis_Land_return:(unsigned char*)dataBytes :(int)length
//{
//    HYExplainManager *manager = [HYExplainManager shareManager];
//    int value = [manager TSR376_Analysis_Land_return:dataBytes :length];
//    switch (value) {
//        case 1:
//            [SVProgressHUD showErrorWithStatus:@"错误帧"];
//            break;
//        case 2:
//            [SVProgressHUD showErrorWithStatus:@"错误帧"];
//            break;
//        case 3:
//            [SVProgressHUD showErrorWithStatus:@"普通确认帧"];
//            break;
//        case 4:
//            [SVProgressHUD showErrorWithStatus:@"否认帧"];
//            break;
//        case 0:
//        {//保存用户信息,用户名、密码、验证ID等等
//            //请求用户信息
//            unsigned char outbuf[1024];
//            Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
//            HYSingleManager *single = [HYSingleManager sharedManager];
//            int length = [manager TSR376_GetACK_UsrInfFame:inbuf :single.user.user_ID :single.user.check_ID :outbuf];
//            NSData *data = [NSData dataWithBytes:outbuf length:length];
//            [_sendSocket writeData:data withTimeout:10 tag:0];
//            break;}
//        default:
//            break;
//    }
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    if ([defaults objectForKey:@"Exit"] || ![defaults objectForKey:@"isNoFirstLogin"] || ![defaults objectForKey:@"AutoLogin"]) {
//        
//        NSDate *currentDate = [NSDate date];//获取当前时间，日期
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setDateFormat:@"hh:mm:ss"];
//        NSString *date = [dateFormatter stringFromDate:currentDate];
//        [defaults setObject:date forKey:@"date"];
//        
//    }
//    [defaults setObject:@"aaa" forKey:@"loginTimer"];
//    [defaults setObject:nil forKey:@"Exit"];
//    // 登录成功
//    [defaults setObject:@"Yes" forKey:@"isNoFirstLogin"];
//    [defaults synchronize];
//}

UInt64 StringToUInt64(NSString *str)
{
    UInt64 ull = atoll([str UTF8String]);
    return ull;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [userNameText resignFirstResponder];
    [passWordText resignFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated{
    //[SVProgressHUD dismiss];
    [_sendSocket disconnect];
    _sendSocket = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
