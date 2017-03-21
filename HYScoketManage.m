//
//  HYScoketManage.m
//  HYSEM
//
//  Created by 王一成 on 2017/2/24.
//  Copyright © 2017年 WGM. All rights reserved.
//

#import "HYScoketManage.h"
#import "DeviceModel.h"
#import "DataModel.h"
#import "DateModel.h"
@interface HYScoketManage()


@property (nonatomic,strong) __block NSMutableArray * timeArray;

@end
@implementation HYScoketManage
{
    NSMutableData *mData;
    int isAppend;
    int appendLen;
//    NSString *ipv6Addr;
    GCDAsyncSocket * _sendSocket;
    NSString * _tag;
    __block int addNum;
    __block NSString * end;
    int _time;
    int isError;//表示错误信息
    NSMutableArray * _timeArr;
    int requestType ;
}


static HYScoketManage * manage = nil;
+ (id)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manage = [[HYScoketManage alloc] init];
        
    });
    
    return manage;
    
}

//
- (BOOL)validateSocket
{
    if ([_sendSocket isConnected]) {
        return YES;
    }else{
        return false;
    }
}

- (void)getNetworkDatawithIP:(NSString *)ipv6Addr withTag:(NSString *)tag
{
    _tag = tag;
    isError = 0;
    end = [[NSString alloc] init];
    NSString * ipv6 = [self convertHostToAddress:SocketHOST];
    if (![self validateSocket]) {
        _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
  BOOL  ret =  [_sendSocket connectToHost:ipv6 onPort:SocketonPort withTimeout:10 error:nil];
    NSLog(@"socket连接%d",ret);
}

//处理支持IPv6
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


//建立连接
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    int tag = [_tag intValue];
    switch (tag) {
        case 2:
        {
//            self.timeArray = [self returnTimeArray:3];
//            [self writeDataToHost];
            [SVProgressHUD showWithStatus:@"通讯中..."];
            [_sendSocket readDataWithTimeout:10 tag:0];
        }
            
            break;
        case 1:
        {//用户请求
            HYExplainManager *manager = [HYExplainManager shareManager];
            Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
            unsigned char outbuf[1024];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *username = [defaults objectForKey:@"username"];
            NSString *password = [defaults objectForKey:@"password"];
            int aaa = [manager TSR376_Get_Land_Fame:inbuf :username :password :outbuf];
            NSData *data = [NSData dataWithBytes:outbuf length:aaa];
            [_sendSocket writeData:data withTimeout:10 tag:0];
            [sock readDataWithTimeout:10 tag:0];
            
            break;
        }
            
        case 3:
        {//状态tag = 3
            //            self.timeArray = [self returnTimeArray:3];
            //            [self writeDataToHost];
            [SVProgressHUD showWithStatus:@"通讯中..."];
            [_sendSocket readDataWithTimeout:10 tag:0];
        }
            
            break;
            
        case 4:
        {//表码
            HYExplainManager *expalin = [HYExplainManager shareManager];
            HYSingleManager *manager = [HYSingleManager sharedManager];
            for (int i = 0; i<manager.archiveUser.child_obj.count; i++) {
                CCompanyModel *company = manager.archiveUser.child_obj[i];
                for (int j = 0; j<company.child_obj1.count; j++) {
                    CTerminalModel *terminal = company.child_obj1[j];
                    unsigned int Pn[20];
                    int len = 0;
                    for (int k = 0; k<terminal.child_obj.count; k++,len++) {
                        CMPModel *mp = terminal.child_obj[k];
                        Pn[k] = mp.mp_point;
                    }
                    unsigned char outbuf[1024];
                    int bufLength = [expalin TSR376_GetACK_TableCodeInfFame:terminal.term_ID mp_pointArr:Pn mp_pointNum:len Usr_checkID:manager.user.check_ID OurBufData:outbuf];
                    NSData *data = [NSData dataWithBytes:outbuf length:bufLength];
                    [_sendSocket writeData:data withTimeout:10 tag:0];
                }
            }
            [sock readDataWithTimeout:10 tag:0];

        }
        default:
            break;
    }
    
}


//接收数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(@"%@",data);
    HYExplainManager *manager = [HYExplainManager shareManager];
    unsigned char outbuf[1024*4];
    int rLen;
    int i = 0,len = 0;
    Byte *dataBytes;
    if (1 == isAppend) {
        [mData appendData:data];
        dataBytes = (Byte *)[mData bytes];
        appendLen += [data length];
    }else{
        dataBytes = (Byte *)[data bytes];
        appendLen = (int)[data length];
    }
    //首先分析是否粘包
    while (8<appendLen-i) {
        len = [manager TSR376_Get_All_frame:&dataBytes[i] :(appendLen-i) :outbuf :&rLen];
        if (1 == len) {
            //开始解析
            [self TSR376_Analysis_All_Frame:&dataBytes[i] :rLen];
            isAppend = 0;
        }else if (0 == len){
            NSLog(@"存储不够长度的帧---%d", rLen);
            mData = [NSMutableData data];
            [mData appendBytes:outbuf length:rLen];
            appendLen = rLen;
            isAppend = 1;
        }else if (-1 == len){
            NSLog(@"帧不对");
            isAppend = 0;
            mData = [NSMutableData data];
            break;
        }
        if (0 == rLen) {
            isAppend = 0;
            break;
        }
        i += rLen;
    }
    //处理use Power _tag ==2表明处理用量数据
    if ([_tag isEqualToString:@"2"] ) {
    //判断所有数据是否请求完成
        BOOL ret = [self isFinished];
        if (ret) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"getData" object:nil];
        }
    }
    //处理状态模块
    if ([_tag isEqualToString:@"3"]) {
        BOOL ret = [self isFinished1];
        if (ret) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"getStatusData" object:nil];
        }
    }
    
    //表码模块
    if ([_tag isEqualToString:@"4"]) {
        //判断数据是否都已经解析完
        BOOL ret = [self JudgeTableCodeFrameIsRequest];
        if (ret) {
            [SVProgressHUD showSuccessWithStatus:@"获取表码成功"];
            [SVProgressHUD dismiss];
            //获取数据源
            [[NSNotificationCenter defaultCenter] postNotificationName:@"getTableCodeData" object:nil];
        }
    }
    [sock readDataWithTimeout:10 tag:0];
}


//判断表码信息是否完成
-(BOOL)JudgeTableCodeFrameIsRequest
{
    //依据是档案字典里的key的个数是否和表码字典里的key的个数相等
    HYSingleManager *manager = [HYSingleManager sharedManager];
    NSMutableArray *arr = [NSMutableArray array];
    NSArray *tableKeys = manager.memory_Array;
    for (int i = 0; i<manager.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = manager.archiveUser.child_obj[i];
        for (int j = 0; j<company.child_obj1.count; j++) {
            CTerminalModel *terminal = company.child_obj1[j];
            for (int k = 0; k<terminal.child_obj.count; k++) {
                CMPModel *mp = terminal.child_obj[k];
                [arr addObject:[NSString stringWithFormat:@"%llu",mp.strID]];
            }
        }
    }
    if (tableKeys.count == arr.count) {
        return YES;
    }
    return NO;
}

- (BOOL)isFinished
{
    NSData * data = [HY_NSusefDefaults objectForKey:@"usePowerData"];
    NSArray * dataArr = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    HYSingleManager *manager1 = [HYSingleManager sharedManager];
    int terminalNum = 0;
    for (int a = 0; a<manager1.archiveUser.child_obj.count; a++) {
        CCompanyModel *company = manager1.archiveUser.child_obj[a];
        for (int b = 0; b<company.child_obj1.count; b++) {
            CTerminalModel *terminal = company.child_obj1[b];
            for (int c = 0; c<terminal.child_obj.count; c++) {
                CMPModel *mp = terminal.child_obj[c];
                terminalNum ++;
            }
        }
    }
    
    int num = 0;
    for (DeviceModel * de in dataArr) {
        for (DataModel * data in de.dataArr) {
            num ++;
        }
    }
    if (num == (_time +1)*terminalNum)
    {
        //接受完毕
        [HY_NSusefDefaults setObject:nil forKey:@"NextData"];
        return true;
    }
    NSLog(@"%d---%d",num,terminalNum);
    NSMutableArray * errorData = [HY_NSusefDefaults objectForKey:@"NextData"];
    for (int i = 0; i < errorData.count; i++)
    {
        num ++;
    }
    if (num == (_time +1)*terminalNum ) {
        if (errorData.count ==0) {
            [HY_NSusefDefaults removeObjectForKey:@"NextData"];
            return true;
        }
        for (int i = 0; i < errorData.count; i++) {
            NSDictionary * dic = errorData[i];
            isError = 2;//错误
            [self writeDataToHost1WithTime:dic[@"Time"] andPn:[dic[@"Pn"] intValue] andAddress:dic[@"Address"]];
        }
        return false;
    }else{
        return false;
    }
}

#pragma mark --Judge首先判断所有的数据是否请求完
- (BOOL)JudgeAllFrameIsRequest
{
    //依据是字典里边的key在其他value里是否存在
    NSString * s = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    HYSingleManager *single = [HYSingleManager sharedManager];
    NSArray *allKeys = [single.obj_dict allKeys];
    NSArray *allVaules = [single.obj_dict allValues];
    BOOL ret1 = YES;
    BOOL ret2 = YES;
    BOOL ret3 = YES;
    if (allKeys.count == 0||!allKeys) {
        return false;
    }
    for (int i = 0; i<allKeys.count; i++) {
        HYBaseModel *baseModel = allVaules[i];
        if ([baseModel.request_Type isEqualToString:@"company"]) {
            CCompanyModel *company = allVaules[i];
            for (int j = 0; j<company.children.count; j++) {
                //占线是否都存在
                ret1 = [allKeys containsObject:company.children[j]];
                if (ret1 == NO) {
                    return false;
                }
            }
            for (int j = 0; j<company.children1.count; j++) {
                //终端是否都存在
                ret2 = [allKeys containsObject:company.children1[j]];
                if (ret2 == NO) {
                    
                    return false;
                }
            }
        }else{
            //其他   （组、设备)
            for (int j = 0; j<baseModel.children.count; j++) {
                ret3 = [allKeys containsObject:baseModel.children[j]];
                if (ret3 == NO) {
                    return false;
                }
            }
        }
    }
    return true;
    
}
//登录
#pragma mark -- 验证登录帧的正确性
- (void)TSR376_Analysis_Land_return:(unsigned char*)dataBytes :(int)length
{
    HYExplainManager *manager = [HYExplainManager shareManager];
    int value = [manager TSR376_Analysis_Land_return:dataBytes :length];
    switch (value) {
        case 1:
            [SVProgressHUD showErrorWithStatus:@"错误帧"];
            break;
        case 2:
            [SVProgressHUD showErrorWithStatus:@"错误帧"];
            break;
        case 3:
            [SVProgressHUD showErrorWithStatus:@"普通确认帧"];
            break;
        case 4:
            [SVProgressHUD showErrorWithStatus:@"否认帧"];
            break;
        case 0:
        {//保存用户信息,用户名、密码、验证ID等等
            //请求用户信息
            unsigned char outbuf[1024];
            Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
            HYSingleManager *single = [HYSingleManager sharedManager];
            int length = [manager TSR376_GetACK_UsrInfFame:inbuf :single.user.user_ID :single.user.check_ID :outbuf];
            NSData *data = [NSData dataWithBytes:outbuf length:length];
            [_sendSocket writeData:data withTimeout:10 tag:0];
            break;
        }
        default:
            break;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"Exit"] || ![defaults objectForKey:@"isNoFirstLogin"] || ![defaults objectForKey:@"AutoLogin"]) {
        NSDate *currentDate = [NSDate date];//获取当前时间，日期
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"hh:mm:ss"];
        NSString *date = [dateFormatter stringFromDate:currentDate];
        [defaults setObject:date forKey:@"date"];
        
    }
    [defaults setObject:@"aaa" forKey:@"loginTimer"];
    [defaults setObject:nil forKey:@"Exit"];
    // 登录成功
    [defaults setObject:@"Yes" forKey:@"isNoFirstLogin"];
    [defaults synchronize];
}


#pragma mark --解析所有帧
- (void)TSR376_Analysis_All_Frame:(unsigned char*)dataBytes :(unsigned int)length
{
    HYExplainManager *manager = [HYExplainManager shareManager];
    HYSingleManager *single = [HYSingleManager sharedManager];
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
                {//验证码过期否认
                    [SVProgressHUD showErrorWithStatus:@"验证码过期,请重新登录"];
                    NSLog(@"aufsgfyugyegruyegrheklhragwwjjoadhiawhdawi");
                    [_sendSocket disconnect];
                    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                    [delegate uninstall];
                    [delegate login];
                    break;
                }
                case 4:
                    //用户验证ID,登录帧
                    [self TSR376_Analysis_Land_return:dataBytes :length];
                    break;
                case 5:
                {//接收到用户档案
                    int iEnd;
                    [manager TSR376_Analysis_UsrInf:dataBytes :length :single.user.user_ID :iEnd];
                    unsigned char outbuf[1024];
                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
                    
                    NSArray *keyArr = [single.obj_dict allKeys];
                    NSArray *valueArr = [single.obj_dict allValues];
                    for (int i = 0; i<keyArr.count; i++) {
                        HYBaseModel *model = valueArr[i];
                        if ([model.request_Type isEqualToString:@"user"]) {
                            HYUserModel *user = valueArr[i];
                            if (user.isRequest == false) {
                                //请求单位档案
                                for (int j = 0; j<user.children.count; j++) {
                                    int length = [manager TSR376_GetACK_CompanyInfFame:inbuf Company_ID:[user StringToUInt64:user.children[j]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data1 = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data1 withTimeout:10 tag:0];
                                }
                                user.isRequest = true;       //发送完一个就将请求状态设置为true
                            }
                        }
                    }
                    
                    break;}
                case 6:
                    //群档案
                    
                    break;
                case 7:
                {//接收单位档案
                    int iEnd;
                    [manager TSR376_Analysis_CompanyInf:dataBytes bufer_len:length Company_ID:single.company.strID iEnd:iEnd];
                    unsigned char outbuf[1024];
                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
                    
                    NSArray *keyArr = [single.obj_dict allKeys];
                    NSArray *valueArr = [single.obj_dict allValues];
                    for (int i = 0; i<keyArr.count; i++) {
                        HYBaseModel *model = valueArr[i];
                        if ([model.request_Type isEqualToString:@"company"]) {
                            CCompanyModel *company = valueArr[i];
                            if (company.isRequest == false) {
                                //请求占线
                                for (int j = 0; j<company.children.count; j++) {
                                    int length = [manager TSR376_GetACK_LineInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Line_ID:[company StringToUInt64:company.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data2 = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data2 withTimeout:10 tag:0];
                                }
                                //请求终端
                                for (int k = 0; k<company.children1.count; k++) {
                                    int length = [manager TSR376_GetACK_TerminalInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Terminal_ID:[company StringToUInt64:company.children1[k]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data3 = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data3 withTimeout:10 tag:0];
                                }
                                company.isRequest = true;
                            }
                        }else if ([model.request_Type isEqualToString:@"transit"]){
                            //请求组档案
                            CTransitModel *transit = valueArr[i];
                            if (transit.isRequest == false) {
                                for (int j = 0; j<transit.children.count; j++) {
                                    int length = [manager TSR376_GetACK_SetInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Set_ID:[transit StringToUInt64:transit.children[j]] Usr_CheckID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data withTimeout:10 tag:0];
                                }
                                transit.isRequest = true;
                                
                            }
                            
                        }else if ([model.request_Type isEqualToString:@"set"]){
                            //请求设备档案
                            CSetModel *set = valueArr[i];
                            if (set.isRequest == false) {
                                for (int j = 0; j<set.children.count; j++) {
                                    int length = [manager TSR376_GetACK_MPPowerInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] MPPower_ID:[set StringToUInt64:set.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data withTimeout:10 tag:0];
                                }
                                set.isRequest = true;
                            }
                            
                        }
                    }
                    
                    break;}
                case 8:
                {//接收线路档案
                    int iEnd;
                    [manager TSR376_Analysis_LineInf:dataBytes bufer_len:length Company_ID:single.company.strID Line_ID:[single.company.children[0] strID] iEnd:iEnd];
                    
                    //请求组档案
                    unsigned char outbuf[1024];
                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
                    
                    NSArray *keyArr = [single.obj_dict allKeys];
                    NSArray *valueArr = [single.obj_dict allValues];
                    for (int i = 0; i<keyArr.count; i++) {
                        HYBaseModel *model = valueArr[i];
                        if ([model.request_Type isEqualToString:@"company"]) {
                            ////请求占线档案
                            CCompanyModel *company = valueArr[i];
                            if (company.isRequest == false) {
                                //占线
                                for (int j = 0; j<company.children.count; j++) {
                                    int length = [manager TSR376_GetACK_LineInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Line_ID:[company StringToUInt64:company.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data2 = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data2 withTimeout:10 tag:0];
                                }
                                //终端
                                for (int k = 0; k<company.children1.count; k++) {
                                    int length = [manager TSR376_GetACK_TerminalInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Terminal_ID:[company StringToUInt64:company.children1[k]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data3 = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data3 withTimeout:10 tag:0];
                                }
                                company.isRequest = true;
                                
                            }
                        }else if ([model.request_Type isEqualToString:@"transit"]){
                            //请求组档案
                            CTransitModel *transit = valueArr[i];
                            if (transit.isRequest == false) {
                                for (int j = 0; j<transit.children.count; j++) {
                                    int length = [manager TSR376_GetACK_SetInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Set_ID:[transit StringToUInt64:transit.children[j]] Usr_CheckID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data withTimeout:10 tag:0];
                                }
                                transit.isRequest = true;
                                
                            }
                        }else if ([model.request_Type isEqualToString:@"set"]){
                            //请求设备档案
                            CSetModel *set = valueArr[i];
                            if (set.isRequest == false) {
                                for (int j = 0; j<set.children.count; j++) {
                                    int length = [manager TSR376_GetACK_MPPowerInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] MPPower_ID:[set StringToUInt64:set.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data withTimeout:10 tag:0];
                                }
                                set.isRequest = true;
                            }
                            
                        }
                    }
                    break;}
                case 9:
                    //站线档案
                    
                    break;
                case 10:
                {
                    //终接收端档案
                    int iEnd;
                    CSetModel *model = [single.company.children[0] children][0];
                    [manager TSR376_Analysis_TerminalInf:dataBytes bufer_len:length Company_ID:single.company.strID Terminal_ID:model.strID iEnd:iEnd];
                    break;}
                case 11:
                {//组档案
                    int iEnd;
                    CSetModel *modle = [single.company.children[0] children][0];
                    [manager TSR376_Analysis_SetInf:dataBytes bufer_len:length Company_ID:single.company.strID Set_ID:modle.strID iEnd:iEnd];
                    unsigned char outbuf[1024];
                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
                    
                    NSArray *keyArr = [single.obj_dict allKeys];
                    NSArray *valueArr = [single.obj_dict allValues];
                    for (int i = 0; i<keyArr.count; i++) {
                        HYBaseModel *model = valueArr[i];
                        if ([model.request_Type isEqualToString:@"company"]) {
                            ////请求占线档案
                            CCompanyModel *company = valueArr[i];
                            if (company.isRequest == false) {
                                //占线
                                for (int j = 0; j<company.children.count; j++) {
                                    int length = [manager TSR376_GetACK_LineInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Line_ID:[company StringToUInt64:company.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data2 = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data2 withTimeout:10 tag:0];
                                }
                                //终端
                                for (int k = 0; k<company.children1.count; k++) {
                                    int length = [manager TSR376_GetACK_TerminalInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Terminal_ID:[company StringToUInt64:company.children1[k]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data3 = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data3 withTimeout:10 tag:0];
                                }
                                company.isRequest = true;
                            }
                        }else if ([model.request_Type isEqualToString:@"transit"]){
                            //请求组档案
                            CTransitModel *transit = valueArr[i];
                            if (transit.isRequest == false) {
                                for (int j = 0; j<transit.children.count; j++) {
                                    int length = [manager TSR376_GetACK_SetInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Set_ID:[transit StringToUInt64:transit.children[j]] Usr_CheckID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data withTimeout:10 tag:0];
                                }
                                transit.isRequest = true;
                                
                            }
                        }else if ([model.request_Type isEqualToString:@"set"]){
                            //请求设备档案
                            CSetModel *set = valueArr[i];
                            if (set.isRequest == false) {
                                for (int j = 0; j<set.children.count; j++) {
                                    int length = [manager TSR376_GetACK_MPPowerInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] MPPower_ID:[set StringToUInt64:set.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data withTimeout:10 tag:0];
                                }
                                set.isRequest = true;
                            }
                        }
                    }
                    
                    break;}
                case 12:
                {//设备档案
                    int iEnd;
                    [manager TSR376_Analysis_MPPowerInf:dataBytes bufer_len:length Company_ID:single.company.strID MPPower_ID:single.company.strID iEnd:iEnd];
                    unsigned char outbuf[1024];
                    Byte inbuf[5] = {0x00,0x00,0x00,0x00,0x00};
                    NSArray *keyArr = [single.obj_dict allKeys];
                    NSArray *valueArr = [single.obj_dict allValues];
                    for (int i = 0; i<keyArr.count; i++) {
                        HYBaseModel *model = valueArr[i];
                        if ([model.request_Type isEqualToString:@"company"]) {
                            ////请求占线档案
                            CCompanyModel *company = valueArr[i];
                            if (company.isRequest == false) {
                                //占线
                                for (int j = 0; j<company.children.count; j++) {
                                    int length = [manager TSR376_GetACK_LineInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Line_ID:[company StringToUInt64:company.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data2 = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data2 withTimeout:10 tag:0];
                                }
                                //终端
                                for (int k = 0; k<company.children1.count; k++) {
                                    int length = [manager TSR376_GetACK_TerminalInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Terminal_ID:[company StringToUInt64:company.children1[k]] Usr_checkID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data3 = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data3 withTimeout:10 tag:0];
                                }
                                company.isRequest = true;
                            }
                        }else if ([model.request_Type isEqualToString:@"transit"]){
                            //请求组档案
                            CTransitModel *transit = valueArr[i];
                            if (transit.isRequest == false) {
                                for (int j = 0; j<transit.children.count; j++) {
                                    int length = [manager TSR376_GetACK_SetInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] Set_ID:[transit StringToUInt64:transit.children[j]] Usr_CheckID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data withTimeout:10 tag:0];
                                }
                                transit.isRequest = true;
                            }
                        }else if ([model.request_Type isEqualToString:@"set"]){
                            //请求设备档案
                            CSetModel *set = valueArr[i];
                            if (set.isRequest == false) {
                                for (int j = 0; j<set.children.count; j++) {
                                    int length = [manager TSR376_GetACK_MPPowerInfFame:inbuf Company_ID:[model StringToUInt64:keyArr[i]] MPPower_ID:[set StringToUInt64:set.children[j]] Usr_check_ID:single.user.check_ID OutBufData:outbuf];
                                    NSData *data = [NSData dataWithBytes:outbuf length:length];
                                    [_sendSocket writeData:data withTimeout:10 tag:0];
                                }
                                set.isRequest = true;
                            }
                        }
                    }
                    
                    break;}
                default:
                    break;
            }
        case 13:
        {//查询2类数据o
            int iEnd;
            if ([_tag intValue] == 2) {
                if (isError == 1 ) {
                    //next请求，修正错误信息(useless)
                    [manager TSR376_Analysis_TableCodeForHourInfNextFame:dataBytes bufer_len:length iEnd:&iEnd With:end];
                }else if(isError ==2){//请求数据超过六次
                    [manager TSR376_Analysis_TableCodeForHourInfNextFame:dataBytes bufer_len:length iEnd:&iEnd With:end];
                    
                }else{
                    [manager TSR376_Analysis_TableCodeForHourInfFame:dataBytes bufer_len:length iEnd:&iEnd With:end];
                }
            }else if([_tag intValue] == 3){
                //状态模块
                [manager TSR376_Analysis_QueryInfFame:dataBytes bufer_len:length iEnd:&iEnd];
            }else if ([_tag intValue] == 4){
                [manager TSR376_Analysis_TableCodeInf:dataBytes bufer_len:length iEnd:&iEnd];
            }
            break;
        }
        default:
            break;
    }
    if ([_tag isEqualToString:@"1"]) {
        //判断所有的数据是否请求完
        if ([self JudgeAllFrameIsRequest] == YES) {
            //建立档案
            [self SetArchives];
        }

    }
}

//建立档案
- (void)SetArchives
{
    HYSingleManager *manager = [HYSingleManager sharedManager];
    HYUserModel *user = [[HYUserModel alloc]init];
    NSArray *allKeys = [manager.obj_dict allKeys];
    
    NSArray *allValues = [manager.obj_dict allValues];
    
    for (int i = 0; i<allKeys.count; i++) {
        
        HYBaseModel *baseModel = allValues[i];
        baseModel.archiveModel = [[HYBaseModel alloc]init];
        if ([baseModel.request_Type isEqualToString:@"user"]) {
            user = (HYUserModel *)baseModel;
        }
        if ([baseModel.request_Type isEqualToString:@"terminal"]) {
            for (int j = 0; j<baseModel.children.count; j++) {
                HYBaseModel *model = manager.obj_dict[baseModel.children[j]];
                model.nd_terminal_Parent = baseModel;
                [baseModel addChildren:model];
            }
        }else{
            for (int j = 0; j<baseModel.children.count; j++) {
                HYBaseModel *model = manager.obj_dict[baseModel.children[j]];
                model.nd_parent = baseModel;
                [baseModel addChildren:model];
            }
            for (int j = 0; j<baseModel.children1.count; j++) {
                HYBaseModel *model = manager.obj_dict[baseModel.children1[j]];
                model.nd_parent = baseModel;
                [baseModel addChildren1:model];
            }
            
        }
        
    }
    
    manager.archiveUser = user;
    [self.delegate sendMessage];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downData" object:nil];
}


/*
usePower模块
*/
#pragma mark -- 进行组帧请求
- (void)writeDataToHostWithL:(NSString *)l
{
    _time = [l intValue];
    self.timeArray = [self returnTimeArray:[l intValue]];
    [self writeDataToHost0];
}

-(void)writeDataToHost0{
    isError = 0;
    HYExplainManager *expalin = [HYExplainManager shareManager];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    for (int i = 0; i<manager.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = manager.archiveUser.child_obj[i];
        for (int j = 0; j<company.child_obj1.count; j++) {
            CTerminalModel *terminal = company.child_obj1[j];
            unsigned int Pn[20];
            int len = 0;
            for (int k = 0; k<terminal.child_obj.count; k++,len++) {
                CMPModel *mp = terminal.child_obj[k];
                Pn[k] = mp.mp_point;
            }
            unsigned char outbuf[1024];
            for (int l = 0; l<self.timeArray.count; l++) {
                expalin.sendUsePowerNextData =^(NSArray *data ,unsigned int pn ,NSString * terminal_adress){
                    [self writeDataToHost1WithTime:data andPn:pn andAddress:terminal_adress];
                };
                NSArray *time = self.timeArray[l];
                int length = [expalin TSR376_GetACK_TableCodeForHourInfFame:terminal.term_ID mp_pointArr:Pn mp_pointNum:len timeArr:time Usr_checkID:manager.user.check_ID OutBufData:outbuf];
                NSData *data = [NSData dataWithBytes:outbuf length:length];
                [_sendSocket writeData:data withTimeout:10 tag:0];
            }
        }
    }

}


#pragma mark --出错信息请求下一个时间

-(void)writeDataToHost1WithTime:(NSArray *)time andPn: (unsigned int)Pn andAddress:(NSString *) address{
    HYExplainManager *expalin = [HYExplainManager shareManager];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    UInt64 checkID ;
    for (int i = 0; i<manager.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = manager.archiveUser.child_obj[i];
        checkID = manager.user.check_ID;
        for (int j = 0; j<company.child_obj1.count; j++)
        {
            CTerminalModel *terminal = company.child_obj1[j];
            int len = 0;
            for (int k = 0; k<terminal.child_obj.count; k++,len++)
            {
                CMPModel *mp = terminal.child_obj[k];
            }
        }
    }
    unsigned char outbuf[1024];
    int length = [expalin TSR376_GetACK_TableCodeForHourInfFame:address mp_pointArr:&Pn mp_pointNum:1 timeArr:time Usr_checkID:checkID OutBufData:outbuf];
    NSData *data = [NSData dataWithBytes:outbuf length:length];
    [_sendSocket writeData:data withTimeout:10 tag:0];
    
}

//输入一个整型,返回一个时间戳数组(往前推几天,并且都是零点,再加上截止到现在的时间)
- (NSMutableArray *)returnTimeArray:(int)day
{
    NSMutableArray * record = [[NSMutableArray alloc] init];//日期数组record[1]存储第一天的数组
    NSDate * currentDate = [NSDate date];
    NSDateFormatter * dateFormatter =[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY/MM/dd/HH/mm"];
    NSTimeInterval  oneDay = 24*60*60*1;  //1天的长度
    for (int i = day -1; i>=0; i--) {
        NSDate *theDate1;
        theDate1 = [currentDate initWithTimeIntervalSinceNow: -oneDay*i];
        NSString *dateString1 = [dateFormatter stringFromDate:theDate1];
        NSArray *arr1 = [dateString1 componentsSeparatedByString:@"/"];// '/'分割日期字符串,得到一数组
        [record addObject:arr1];
    }
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i<record.count; i++) {
        NSMutableArray *arr = record[i];
        [arr replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"00"]];
        [arr replaceObjectAtIndex:4 withObject:[NSString stringWithFormat:@"00"]];
        [array addObject:arr];
    }
    NSString *dataString = [dateFormatter stringFromDate:currentDate];
    NSArray *arr = [dataString componentsSeparatedByString:@"/"];
    NSMutableArray *a = [NSMutableArray arrayWithArray:arr];
    [a replaceObjectAtIndex:4 withObject:[NSString stringWithFormat:@"00"]];
    [array addObject:a];
    return array;
}

//输入一个起始时间,返回一个时间戳数组
- (NSMutableArray *)compare:(int)a :(int)b :(int)day
{
    NSMutableArray * date = [[NSMutableArray alloc] init];
    for (int i = 0; i<day; i++) {
        date[i] = [[NSMutableArray alloc] init];
        for (int j=0; j<2; j++) {
            date[i][j] = [[NSMutableArray alloc] init];
        }
    }
    
    NSMutableArray * record = [[NSMutableArray alloc] init];//日期数组record[1]存储第一天的数组
    NSDate * currentDate = [NSDate date];
    NSDateFormatter * dateFormatter =[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY/MM/dd/HH/mm"];
    NSTimeInterval  oneDay = 24*60*60*1;  //1天的长度
    for (int i = day -1; i>=0; i--) {
        NSDate *theDate1;
        theDate1 = [currentDate initWithTimeIntervalSinceNow: -oneDay*i];
        NSString *dateString1 = [dateFormatter stringFromDate:theDate1];
        NSArray *arr1 = [dateString1 componentsSeparatedByString:@"/"];// '/'分割日期字符串,得到一数组
        [record addObject:arr1];
    }
    if (a>b) {
        for (int i=0 ; i<day; i++) {
            
            if (i == day -1) {
                if (a < [record[i][3] intValue]) {
                    //最后一天时间从开始到当前时间
                    for (int k = 0; k<5; k++) {
                        [date[i][0] addObject:record[i][k]];
                    }
                    [date[i][0] replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%d",a] ];
                    
                    date[i][1] = record[i];
                }else{
                    //最后一天时间没到
                }
            }else{
                
                for (int k = 0; k<5; k++) {
                    [date[i][0] addObject:record[i][k]];
                }
                [date[i][0] replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%d",a] ];
                
                //下面处理结束时间点
                if(i ==  day -2){
                    //处理倒数第二天的结束超过当前时间
                    if (b >= [record[i][3] intValue]) {
                        for (int k = 0; k<5; k++) {
                            [date[i][1] addObject:record[i+1][k]];
                        }
                        
                    }else{//正常情况
                        for (int k = 0; k<5; k++) {
                            [date[i][1] addObject:record[i+1][k]];
                        }
                        [date[i][1] replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%d",b] ];
                    }
                    
                }else{  //除去倒数第一和倒数第二的处理
                    
                    for (int k = 0; k<5; k++) {
                        [date[i][1] addObject:record[i+1][k]];
                    }
                    [date[i][1] replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%d",b] ];
                    
                }
                //结束
                
            }
            
        }
        
    }else{           //不隔天
        
        for (int i=0 ; i<day; i++) {
            
            if (i == day - 1) { //  最后一天
                if (a < [record[i][3] intValue]) {
                    //最后一天时间从开始到当前时间
                    for (int k = 0; k<5; k++) {
                        [date[i][0] addObject:record[i][k]];
                    }
                    [date[i][0] replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%d",a] ];
                    
                    if (b <= [record[i][3] intValue]) {
                        for (int k = 0; k<5; k++) {
                            [date[i][1] addObject:record[i][k]];
                        }
                        [date[i][1] replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%d",b] ];
                    }else{
                        for (int k = 0; k<5; k++) {
                            [date[i][1] addObject:record[i][k]];
                            
                        }
                        
                    }
                    
                }else{
                    //最后一天时间没到
                }
            }else{ //前两天
                
                for (int k = 0; k<5; k++) {
                    [date[i][0] addObject:record[i][k]];
                }
                [date[i][0] replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%d",a] ];
                
                
                for (int k = 0; k<5; k++) {
                    [date[i][1] addObject:record[i][k]];
                }
                [date[i][1] replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%d",b] ];
                
            }
            
        }
        
    }
    NSMutableArray *sendArr = [NSMutableArray array];
    for (int i = 0; i<date.count; i++) {
        NSArray *arr = date[i];
        for (int i = 0; i<arr.count; i++) {
            if ([arr[i] count] != 0) {
                [sendArr addObject:arr[i]];
            }
        }
    }
    return sendArr;
}



#pragma mark -- 状态处理模块

- (void)writeDataToHostStatusWithTimeArr:(NSArray *)timeArr WithRequest_type:(int ) request_type
{
    HYExplainManager *expalin = [HYExplainManager shareManager];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    manager.memory_Array = [[NSMutableArray alloc] init];
    _timeArr = timeArr;
    request_type = request_type;
    for (int i = 0; i<manager.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = manager.archiveUser.child_obj[i];
        for (int j = 0; j<company.child_obj1.count; j++) {
            CTerminalModel *terminal = company.child_obj1[j];
            unsigned int Pn[20];
            int len = 0;
            for (int k = 0; k<terminal.child_obj.count; k++,len++) {
                CMPModel *mp = terminal.child_obj[k];
                Pn[k] = mp.mp_point;
            }
            unsigned char outbuf[1024];
            for (int l = 0; l<timeArr.count; l++) {
                NSArray *time = timeArr[l];
                int length = [expalin TSR376_GetACK_QueryInfFame:terminal.term_ID mp_pointArr:Pn mp_pointNum:len timeArr:time request_type:request_type Usr_checkID:manager.user.check_ID OutBufData:outbuf];
                NSData *data = [NSData dataWithBytes:outbuf length:length];
                [_sendSocket writeData:data withTimeout:10 tag:0];
            }
        }
    }
}


-(BOOL)isFinished1{
    HYSingleManager * manager = [HYSingleManager sharedManager];
    int mpNum = 0;
    for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
        CCompanyModel *company = manager.archiveUser.child_obj[a];
        for (int b = 0; b<company.child_obj1.count; b++) {
            CTerminalModel *terminal = company.child_obj1[b];
                for (int c = 0; c<terminal.child_obj.count; c++) {
                    CMPModel *mp = terminal.child_obj[c];
                    mpNum ++;
                }
        }
    }
    if (manager.memory_Array.count == mpNum) {
        return  YES;
    }
    return NO;
}

@end
