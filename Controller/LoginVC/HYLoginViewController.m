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


- (void)SingInFirstView
{
    //block回调
    self.block();
}


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
