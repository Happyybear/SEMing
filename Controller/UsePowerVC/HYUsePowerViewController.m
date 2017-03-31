//
//  HYUsePowerViewController.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYUsePowerViewController.h"
#import "MyCell.h"
#import "HYScoketManage.h"
#import "DeviceModel.h"
#import "DataModel.h"
#include <sys/types.h>
#include <sys/sysctl.h>
@interface HYUsePowerViewController ()<TWlALertviewDelegate,UITableViewDelegate,UITableViewDataSource>
{
    GCDAsyncSocket *_sendSocket;
    TWLAlertView *alertView;
    int isAppend;
    int appendLen;
    NSMutableData *mData;
    NSMutableArray *_nameArr;
    NSMutableArray *_dataSource;
    NSMutableArray * _data; //存储所有对象
    NSMutableArray *_timeArr;
    int request_type;//区分请求类型,全天查询还是分段查询 (0 全天  1 分段)
    NSString *ipv6Addr;
    int dayNum; //选择的天数
}

@property (nonatomic,strong) NSMutableArray *timeArray;

@property (nonatomic,strong) UITableView *tableView;

@end

@implementation HYUsePowerViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [HY_NSusefDefaults setObject:nil forKey:@"usePowerData"];
    [HY_NSusefDefaults setObject:nil forKey:@"NextData"];
    // Do any additional setup after loading the view from its nib.
    ipv6Addr = [self convertHostToAddress:SocketHOST];
    [self createTableView];
    [self getData];
    self.titleLabel.text = @"用量分析";
    [SVProgressHUD setDefaultMaskType:1];
    [self createBaseUI];
    [self initArrAndDict];
    [self createLastSearchUI];
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


- (void)createLastSearchUI
{
    UIButton *btn1 = (UIButton *)[alertView viewWithTag:10000000];
    UIButton *btn3 = (UIButton *)[alertView viewWithTag:100000000];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"santian"] && [defaults boolForKey:@"quantian"]) {
        [self removeTableViewAndArray];
        //
        request_type = 0;
        HYScoketManage * manage = [HYScoketManage shareManager];
        [manage getNetworkDatawithIP:ipv6Addr withTag:@"2"];
        [SVProgressHUD showWithStatus:@"通讯中..."];
        dayNum = 3;
        [manage writeDataToHostWithL:@"3"];
        [self cancleView];
        //
        
    }else if ([defaults boolForKey:@"santian"] && [defaults boolForKey:@"yiduan"]){
        NSString *a = [[NSUserDefaults standardUserDefaults] objectForKey:@"st1"];
        NSString *b = [[NSUserDefaults standardUserDefaults] objectForKey:@"end1"];
        [self removeTableViewAndArray];
        _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
        request_type = 1;
        dayNum = 3;
        self.timeArray = [self compare:[a intValue] :[b intValue] :3];
        [SVProgressHUD showWithStatus:@"通讯中..."];
        [self writeDataToHost];
        [self cancleView];
        
        
    }else if ([defaults boolForKey:@"santian"] && [defaults boolForKey:@"liangduan"]){
        NSString *a = [[NSUserDefaults standardUserDefaults] objectForKey:@"st2"];
        NSString *b = [[NSUserDefaults standardUserDefaults] objectForKey:@"end2"];
        NSString *c = [[NSUserDefaults standardUserDefaults] objectForKey:@"st3"];
        NSString *d = [[NSUserDefaults standardUserDefaults] objectForKey:@"end3"];
        dayNum = 3;
        NSArray *arr1 = [self compare:[a intValue] :[b intValue] :3];
        NSArray *arr2 = [self compare:[c intValue] :[d intValue] :3];
        [self removeTableViewAndArray];
        _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
        request_type = 1;
        for (int i = 0; i<arr1.count; i++) {
            [self.timeArray addObject:arr1[i]];
        }
        for (int i = 0; i<arr2.count; i++) {
            [self.timeArray addObject:arr2[i]];
        }
        [SVProgressHUD showWithStatus:@"通讯中..."];
        [self writeDataToHost];
        [self cancleView];
        
    }else if ([defaults boolForKey:@"santian"] && [defaults boolForKey:@"sanduan"]){
        
        NSString *a = [[NSUserDefaults standardUserDefaults] objectForKey:@"st4"];
        NSString *b = [[NSUserDefaults standardUserDefaults] objectForKey:@"end4"];
        NSString *c = [[NSUserDefaults standardUserDefaults] objectForKey:@"st5"];
        NSString *d = [[NSUserDefaults standardUserDefaults] objectForKey:@"end5"];
        NSString *e = [[NSUserDefaults standardUserDefaults] objectForKey:@"st6"];
        NSString *f = [[NSUserDefaults standardUserDefaults] objectForKey:@"end6"];
        dayNum = 3;
        NSArray *arr1 = [self compare:[a intValue] :[b intValue] :3];
        NSArray *arr2 = [self compare:[c intValue] :[d intValue] :3];
        NSArray *arr3 = [self compare:[e intValue] :[f intValue] :3];
        [self removeTableViewAndArray];
        _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
        request_type = 1;
        for (int i = 0; i<arr1.count; i++) {
            [self.timeArray addObject:arr1[i]];
        }
        for (int i = 0; i<arr2.count; i++) {
            [self.timeArray addObject:arr2[i]];
        }
        for (int i = 0; i<arr3.count; i++) {
            [self.timeArray addObject:arr3[i]];
        }
        [SVProgressHUD showWithStatus:@"通讯中..."];
        [self writeDataToHost];
        [self cancleView];

        
    }else if ([defaults boolForKey:@"yizhou"] && [defaults boolForKey:@"quantian"]){
        
        [self removeTableViewAndArray];
        HYScoketManage * manage = [HYScoketManage shareManager];
        request_type = 0;
        [manage getNetworkDatawithIP:ipv6Addr withTag:@"2"];
        [SVProgressHUD showWithStatus:@"通讯中..."];
        dayNum = 7;
        [manage writeDataToHostWithL:@"7"];
        [self cancleView];
        
    }else if ([defaults boolForKey:@"yizhou"] && [defaults boolForKey:@"yiduan"]){
        [self removeTableViewAndArray];
        NSString *a = [[NSUserDefaults standardUserDefaults] objectForKey:@"st1"];
        NSString *b = [[NSUserDefaults standardUserDefaults] objectForKey:@"end1"];
        dayNum = 7;
        self.timeArray = [self compare:[a intValue] :[b intValue] :7];
        _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
        request_type = 1;
        [SVProgressHUD showWithStatus:@"通讯中..."];
        [self writeDataToHost];
        [self cancleView];
        
    }else if ([defaults boolForKey:@"yizhou"] && [defaults boolForKey:@"liangduan"]){
        NSString *a = [[NSUserDefaults standardUserDefaults] objectForKey:@"st2"];
        NSString *b = [[NSUserDefaults standardUserDefaults] objectForKey:@"end2"];
        NSString *c = [[NSUserDefaults standardUserDefaults] objectForKey:@"st3"];
        NSString *d = [[NSUserDefaults standardUserDefaults] objectForKey:@"end3"];
        dayNum = 7;
        NSArray *arr1 = [self compare:[a intValue] :[b intValue] :7];
        NSArray *arr2 = [self compare:[c intValue] :[d intValue] :7];
        [self removeTableViewAndArray];
        _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
        request_type = 1;
        for (int i = 0; i<arr1.count; i++) {
            [self.timeArray addObject:arr1[i]];
        }
        for (int i = 0; i<arr2.count; i++) {
            [self.timeArray addObject:arr2[i]];
        }
        [SVProgressHUD showWithStatus:@"通讯中..."];
        [self writeDataToHost];
        [self cancleView];
        
        
    }else if ([defaults boolForKey:@"yizhou"] && [defaults boolForKey:@"sanduan"]){
        NSString *a = [[NSUserDefaults standardUserDefaults] objectForKey:@"st4"];
        NSString *b = [[NSUserDefaults standardUserDefaults] objectForKey:@"end4"];
        NSString *c = [[NSUserDefaults standardUserDefaults] objectForKey:@"st5"];
        NSString *d = [[NSUserDefaults standardUserDefaults] objectForKey:@"end5"];
        NSString *e = [[NSUserDefaults standardUserDefaults] objectForKey:@"st6"];
        NSString *f = [[NSUserDefaults standardUserDefaults] objectForKey:@"end6"];
        dayNum = 7;
        NSArray *arr1 = [self compare:[a intValue] :[b intValue] :7];
        NSArray *arr2 = [self compare:[c intValue] :[d intValue] :7];
        NSArray *arr3 = [self compare:[e intValue] :[f intValue] :7];
        [self removeTableViewAndArray];
        _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
        request_type = 1;
        for (int i = 0; i<arr1.count; i++) {
            [self.timeArray addObject:arr1[i]];
        }
        for (int i = 0; i<arr2.count; i++) {
            [self.timeArray addObject:arr2[i]];
        }
        for (int i = 0; i<arr3.count; i++) {
            [self.timeArray addObject:arr3[i]];
        }
        [SVProgressHUD showWithStatus:@"通讯中..."];
        [self writeDataToHost];
        [self cancleView];
        
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"firstStarta"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstStarta"];
        [defaults setBool:btn1.selected forKey:@"santian"];
        [defaults setBool:btn3.selected forKey:@"quantian"];
    }
    }
}


- (void)initArrAndDict
{
    self.timeArray = [[NSMutableArray alloc]init];
    _nameArr = [NSMutableArray array];
    _timeArr = [NSMutableArray array];
    _dataSource = [NSMutableArray array];
    _data = [NSMutableArray array];
    isAppend = 0;
    appendLen = 0;
    [HY_NSusefDefaults removeObjectForKey:@"NextData"];
    mData = [[NSMutableData alloc]init];
    //首先初始化存放用量的字典
    HYSingleManager *manager = [HYSingleManager sharedManager];
    manager.usepower_dict = [NSMutableDictionary dictionary];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    [sock readDataWithTimeout:10 tag:0];

}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
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
    
    //判断所有数据是否请求完成
    BOOL ret = [self isFinished];
    if (ret) {
        [self createDataSource1];
    }
    
    [sock readDataWithTimeout:10 tag:0];
}



-(void)getData{
    if (request_type == 0) {
        //全天
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createDataSource) name:@"getData" object:nil];
    }else{
        //分段
    }
    
}
- (void)createDataSource{
    [SVProgressHUD dismiss];
    _nameArr = [NSMutableArray array];
    _timeArr = [NSMutableArray array];
    NSData * data = [HY_NSusefDefaults objectForKey:@"usePowerData"];
    NSArray * dataArr = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    int min= 0,position =0;
    for (DeviceModel * model  in dataArr) {
        for (int i = 0; i < model.dataArr.count -1 ; i++) {
            DataModel * data = model.dataArr[i];
             min =  [data.day intValue] *24 + [data.Month intValue] * 30 * 24 +[data.hour intValue];
            position = i;
            for (int j = i + 1; j < model.dataArr.count; j++) {
                DataModel * data2 = model.dataArr[j];
                int num2 =  [data2.day intValue] *24 + [data2.Month intValue] * 30 * 24 +[data2.hour intValue];
                if (min > num2) {
                    min = num2;
                    position = j;
                }
            }
            if (position != i) {
                DataModel * temp = model.dataArr[i];
                model.dataArr[i] = model.dataArr[position];
                model.dataArr[position] = temp;
            }
        }
    }
    _data = dataArr;
    //时间
    for (int j = 0; j<dataArr.count; j++) {
        for (int i = dayNum-1; i >= 0; i--) {
            NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:-(60*60*24)*i];
            NSDateFormatter * dateFormatter =[[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM-dd"];
            NSString * time = [dateFormatter stringFromDate:currentDate];
            [_timeArr addObject:time];
        }
    }
        //计算用量存入_dataSource
    _dataSource = [[NSMutableArray alloc] init];
    for (int k = 0; k < _data.count; k++)
    {
        DeviceModel * de = _data[k];
        for (int i = 0; i<de.dataArr.count - 1; i++)
        {
            DataModel * data = de.dataArr[i];
            int j = i +1;
            DataModel * data1 = de.dataArr[j];
            double count = 0;
            NSString * countString = [[NSString alloc] init];
            if ([self isFloatText:data1.data] && [self isFloatText:data.data]) {
                count = [data1.data doubleValue] * [data1.ct doubleValue] * [data1.pt doubleValue] - [data.data doubleValue] * [data.ct doubleValue] * [data.pt doubleValue];
                countString = [NSString stringWithFormat:@"%.4f",count];
            }else{
                countString = @"--------";
            }
            
            [_dataSource addObject:countString];
            
        }
    }
    [self.tableView reloadData];
}

- (BOOL)isFloatText:(NSString *)str{
    NSString * regex        = @"^[0-9]*[.][0-9]*$";
    NSPredicate * pred      = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    BOOL isMatch            = [pred evaluateWithObject:str];
    if (isMatch) {
        return YES;
    }else{
        return NO;
    }
}

- (void)createDataSource1
{
    _nameArr = [NSMutableArray array];
    _timeArr = [NSMutableArray array];
    _data = [NSMutableArray array];
    //初始化时间和name
    HYSingleManager *single = [HYSingleManager sharedManager];
    NSMutableArray *name_ID = [[NSMutableArray alloc]init];
    for (int i = 0; i<single.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = single.archiveUser.child_obj[i];
        for (int j = 0; j<company.child_obj1.count; j++) {
            CTerminalModel *terminal = company.child_obj1[j];
            for (int k = 0; k<terminal.child_obj.count; k++) {
                CMPModel *mp = terminal.child_obj[k];
                [name_ID addObject:[NSString stringWithFormat:@"%llu",mp.strID]];
            }
        }
    }
    //排序算法
    NSComparator cmptr = ^(id obj1, id obj2){
        
    if ([obj1 integerValue] > [obj2 integerValue]) {
            
        return (NSComparisonResult)NSOrderedDescending;
    }
    if ([obj1 integerValue] < [obj2 integerValue]) {
        
        return (NSComparisonResult)NSOrderedAscending;
    }
    return (NSComparisonResult)NSOrderedSame;
        
    };
    ////时间处理
    NSMutableArray * dayArr = [self getCurrentDay];
    NSMutableArray * dealTime = [[NSMutableArray alloc] init];
    for (int d = 0; d < dayNum; d++) {
        for (int i = 0; i<self.timeArray.count/2; i++)
        {
            if ([dayArr[d] intValue] == [self.timeArray[i*2][2] intValue] ) {
                [dealTime addObject:self.timeArray[i*2]];
                [dealTime addObject:self.timeArray[i*2+1]];
            }
        }
    }

    _timeArray = dealTime;
    ////时间处理
    
    NSMutableArray * valueArrary = [[NSMutableArray alloc]init];
    for (int i = 0; i < name_ID.count; i++) {
        NSDictionary *dict = [single.usepower_dict objectForKey:name_ID[i]];
        NSMutableArray * arr = [[NSMutableArray alloc] init];
        for (int j = 0; j < _timeArray.count; j++) {
            NSArray * time = _timeArray[j];
            NSString * date1 = [NSString stringWithFormat:@"%@%@%@%02d",time[0],time[1],time[2],[time[3] intValue]];
            [arr addObject:dict[date1]];
        }
        [valueArrary addObject:arr];
    }
    //将数据存入_dataSource
    _dataSource = [[NSMutableArray alloc] init];
    for (int i = 0; i<name_ID.count; i++) {
        CMPModel *mp = [self FindMpCTAndPT:name_ID[i]];
        NSDictionary *dict = [single.usepower_dict objectForKey:name_ID[i]];
        NSArray *keys = [dict allKeys];
        NSArray *array = [keys sortedArrayUsingComparator:cmptr];
        NSMutableArray *outputAfter = [NSMutableArray array];
        //按照时间先后进行排序
        for (NSString *str in array) {
            [outputAfter addObject:str];
        }
        double CTPT = mp.mp_CT*mp.mp_PT;
        if (request_type == 0) {
            for (int j = 0; j<outputAfter.count-1; j++) {
                NSString *str1 = valueArrary[i][j][0];
                BOOL ret1 = [self judgeTableCode:[NSString stringWithFormat:@"%@",str1]];
                NSString *str = valueArrary[i][j+1][0];
                BOOL ret = [self judgeTableCode:[NSString stringWithFormat:@"%@",str]];
                if (ret1&&ret) {
                    double code = [str1 doubleValue]*CTPT - [str doubleValue]*CTPT;
                    [_dataSource addObject:[NSString stringWithFormat:@"%.4f",code]];
                }else{
                    [_dataSource addObject:[NSString stringWithFormat:@"---------"]];
                }
                NSString *month = [outputAfter[j] substringWithRange:NSMakeRange(2, 2)];
                NSString *day = [outputAfter[j] substringWithRange:NSMakeRange(4, 2)];
                [_timeArr addObject:[NSString stringWithFormat:@"%@-%@",month,day]];
                [_nameArr addObject:mp.name];
            }

        }else{
            NSArray * value = valueArrary[i];
            for (int j = 0; j<value.count/2; j++) {
                NSString *str1 = value[j * 2 + 1][0];
                BOOL ret1 = [self judgeTableCode:[NSString stringWithFormat:@"%@",str1]];
                NSString *str = value[j * 2][0];
                BOOL ret = [self judgeTableCode:[NSString stringWithFormat:@"%@",str]];

                if (ret1&&ret) {
                    double code = [str1 doubleValue]*CTPT - [str doubleValue]*CTPT;
                    [_dataSource addObject:[NSString stringWithFormat:@"%.4f",code]];
                }else{
                    [_dataSource addObject:[NSString stringWithFormat:@"---------"]];
                }
                [_nameArr addObject:mp.name];
            }
        }
        //时间
        for (int i = 0; i <self.timeArray.count / 2; i++) {
            [_timeArr addObject:[NSString stringWithFormat:@"%@-%@ %@ %@-%@ %@",self.timeArray[i * 2][1],self.timeArray[i*2 ][2],self.timeArray[i * 2][3],self.timeArray[i * 2 + 1][1],self.timeArray[i * 2 + 1][2],self.timeArray[i * 2 + 1][3]]];
        }

    }
    [SVProgressHUD showSuccessWithStatus:@"通讯成功"];
    [SVProgressHUD dismiss];
    [self.tableView reloadData];
    
}

- (void)createTableView
{
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0,30,SCREEN_W , SCREEN_H-76) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_tableView];
}

//根据表ID返回指针
- (CMPModel *)FindMpCTAndPT:(NSString *)mp_ID
{
    HYSingleManager *manager = [HYSingleManager sharedManager];
    for (int i = 0; i<manager.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = manager.archiveUser.child_obj[i];
        for (int j = 0; j<company.child_obj1.count; j++) {
            CTerminalModel *terminal = company.child_obj1[j];
            for (int k = 0; k<terminal.child_obj.count; k++) {
                CMPModel *mp = terminal.child_obj[k];
                if ([mp_ID isEqualToString:[NSString stringWithFormat:@"%llu",mp.strID]]) {
                    return mp;
                }
            }
        }
    }
    return 0;
}

//判断表码是否有效,依据是否有非0~9字符
- (BOOL)judgeTableCode:(NSString *)tableCode
{
    NSScanner* scan = [NSScanner scannerWithString:tableCode];
    double val;
    return [scan scanDouble:&val] && [scan isAtEnd];
}

- (BOOL)isNumText:(NSString *)str{
    NSString * regex        = @"^[0-1]\\d|2[0-3]|\\d$";
    NSPredicate * pred      = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    BOOL isMatch            = [pred evaluateWithObject:str];
    if (isMatch) {
        return YES;
    }else{
        return NO;
    }
}


- (BOOL)isFinished
{
    HYSingleManager *single = [HYSingleManager sharedManager];
    //取出所有的表
    NSMutableArray *name_ID = [[NSMutableArray alloc]init];
    for (int i = 0; i<single.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = single.archiveUser.child_obj[i];
        for (int j = 0; j<company.child_obj1.count; j++) {
            CTerminalModel *terminal = company.child_obj1[j];
            for (int k = 0; k<terminal.child_obj.count; k++) {
                CMPModel *mp = terminal.child_obj[k];
                [name_ID addObject:[NSString stringWithFormat:@"%llu",mp.strID]];
            }
        }
    }
    NSArray *allKeys = [single.usepower_dict allKeys];
    NSMutableArray * timeArray = [[NSMutableArray alloc] init];
    for (int i = 0; i< self.timeArray.count; i++) {
        NSArray * t = self.timeArray[i];
        NSString * tS = [NSString stringWithFormat:@"%@%@",t[2],t[3]];
        if (![timeArray containsObject:tS]) {
            [timeArray addObject:tS];
        }
    }
    for (int i = 0; i<allKeys.count; i++) {
        NSDictionary *dict = single.usepower_dict[allKeys[i]];
        if (!([[dict allValues] count] == timeArray.count)) {
            return NO;
        }
    }
    if (!(allKeys.count == name_ID.count)) {
        return NO;
    }
    return YES;
}

- (void)TSR376_Analysis_All_Frame:(unsigned char*)dataBytes :(unsigned int)length
{
    HYExplainManager *manager = [HYExplainManager shareManager];
    unsigned int val = [manager GW09_Checkout:dataBytes :length];
    unsigned int AFN = [manager TSR376_Get_AFN_Frame:dataBytes];
    switch (val) {
        case 0:
            //错误帧
            [SVProgressHUD showErrorWithStatus:@"网络错误,请重新尝试"];
            break;
        case 1:
            switch (AFN) {
                case 0:
                    //全部确认
                    break;
                case 1:
                    //全部否认
                    [SVProgressHUD showErrorWithStatus:@"网络错误,请重新尝试"];
                    break;
                case 2:
                    //数据单元标识确认和否认:对收到报文中的全部数据单元标识进行逐个确认/否认
                    break;
                case 3:
                {//验证码过期否认
                    [SVProgressHUD showErrorWithStatus:@"登录过期,请重新登录"];
                    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                    [delegate login];
                    break;}
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
                    [manager TSR376_Analysis_TableCodeForHourInfFame:dataBytes bufer_len:length iEnd:&iEnd ];
                    break;
                }
                default:
                    break;
            }
            
        default:
            break;
    }
}

#pragma mark -- 进行组帧请求
- (void)writeDataToHost
{
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
                NSArray *time = self.timeArray[l];
                int length = [expalin TSR376_GetACK_TableCodeForHourInfFame:terminal.term_ID mp_pointArr:Pn mp_pointNum:len timeArr:time Usr_checkID:manager.user.check_ID OutBufData:outbuf];
                NSData *data = [NSData dataWithBytes:outbuf length:length];
                [_sendSocket writeData:data withTimeout:10 tag:0];
            }
        }
    }
}

- (void)initDataSourceWithStartTime:(NSInteger)startTime endTime:(NSInteger)endTime
{
    HYSingleManager *manager = [HYSingleManager sharedManager];
    //要先乘以CT PT
    //获取当前时间整点
    int currentTime = (int)[self getCurrentDate];
    
    NSMutableArray *mp_IDArr = [NSMutableArray array];
    NSMutableArray *nameArr = [NSMutableArray array];
    for (int i = 0; i<manager.archiveUser.child_obj.count; i++) {
        CCompanyModel *company = manager.archiveUser.child_obj[i];
        for (int j = 0; j<company.child_obj1.count; j++) {
            CTerminalModel *terminal = company.child_obj1[j];
            for (int k = 0; k<terminal.child_obj.count; k++) {
                CMPModel *mp = terminal.child_obj[k];
                [nameArr addObject:mp.name];
                [mp_IDArr addObject:[NSString stringWithFormat:@"%llu",mp.strID]];
            }
        }
    }
    NSMutableArray *valueArr = [NSMutableArray array];
    for (int i = 0; i<mp_IDArr.count; i++) {
        NSArray *ar = manager.tableCode_dict[mp_IDArr[i]];
        [valueArr addObject:ar];
    }
    
    
    if ((startTime >= 0)&&(startTime <= 23)&&((endTime >= 0)&&(endTime <= 23))) {
        if ((startTime == 0&&endTime == 0)||(startTime == 0&&endTime == 23)) {
            //先对获得的表码进行排序
            //第一种情况:取全天数据
            
            
        }else if ((startTime < endTime)&&(endTime <= currentTime)){
            //第二种情况:时间都在当前时间内,并且开始时间小于结束时间
            //这种情况要取6个时间点
            
        }else if ((startTime >= endTime)&&(endTime < currentTime)){
            //第三种情况:开始时间大于结束时间,并且结束时间小于当前时间,这种情况只能取到两组数值
            
        }else if ((startTime < endTime)&&(endTime > currentTime)&&(startTime < currentTime)){
            //第四种情况:开始时间小于结束时间,结束时间大于当前时间
            //取6个时间点,最后一天取到当前时间
            
        }else if ((startTime > endTime)&&(endTime >= currentTime)){
            //第五种情况:开始时间大于结束时间,并且结束时间大于当前时间
            //这种情况取4个时间点
            
        }
    }else{
        [SVProgressHUD showErrorWithStatus:@"自定义区间错误"];
    }
}

//创建socket
- (void)createSocket
{
    _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
}

- (void)leftButtonClick
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)rightButtonClick
{
    [self loadAlertView:@"请选择" contentStr:nil btnNum:2 btnStrArr:[NSArray arrayWithObjects:@"取消",@"确定",nil] type:14];
}

- (void)loadAlertView:(NSString *)title contentStr:(NSString *)content btnNum:(NSInteger)num btnStrArr:(NSArray *)array type:(NSInteger)typeStr
{
    UIButton *btn1 = (UIButton *)[alertView viewWithTag:10000000];
    UIButton *btn2 = (UIButton *)[alertView viewWithTag:10000001];
    UIButton *btn3 = (UIButton *)[alertView viewWithTag:100000000];
    UIButton *btn4 = (UIButton *)[alertView viewWithTag:100000001];
    UIButton *btn5 = (UIButton *)[alertView viewWithTag:100000002];
    UIButton *btn6 = (UIButton *)[alertView viewWithTag:100000003];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"santian"]) {
        btn1.selected = YES;
    }else if ([defaults boolForKey:@"yizhou"]){
        btn2.selected = YES;
    }
    if ([defaults boolForKey:@"quantian"]) {
        btn3.selected = YES;
    }else if ([defaults boolForKey:@"yiduan"]){
        btn4.selected = YES;
    }else if ([defaults boolForKey:@"liangduan"]){
        btn5.selected = YES;
    }else if ([defaults objectForKey:@"sanduan"]){
        btn6.selected = YES;
    }
    alertView = [[TWLAlertView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W, SCREEN_H)];
    [alertView initWithTitle:title contentStr:content type:typeStr btnNum:num btntitleArr:array];
    alertView.delegate = self;
    UIView *keywindow = [[UIApplication sharedApplication] keyWindow];
    [keywindow addSubview:alertView];
    [self dealKeyBoard];
    
}
#pragma mark --处理键盘弹起
- (void)dealKeyBoard
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSValue *animationDurationValue = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    [UIView animateWithDuration:animationDuration animations:^{
        alertView.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H );
    } completion:^(BOOL finished) {
        
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyBoardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
     NSValue *animationDurationValue = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [self beginMoveAnimition:keyBoardFrame andAnimitionDurationValue:animationDurationValue];
}

-(void)beginMoveAnimition:(CGRect)keyBoardFrame andAnimitionDurationValue:(NSValue *)animationDurationValue
{
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    if ([[self getCurrentDeviceModel] isEqualToString:@"iPhone4"] || [[self getCurrentDeviceModel] isEqualToString:@"iPhone4s"] || [[self getCurrentDeviceModel] isEqualToString:@"iPhone5"] || [[self getCurrentDeviceModel] isEqualToString:@"iPhone5s"] ||[[self getCurrentDeviceModel] isEqualToString:@"iPhone5c"]) {
        [UIView animateWithDuration:animationDuration animations:^{
            alertView.frame = CGRectMake(0, -(keyBoardFrame.origin.y -(self.view.center.y-keyBoardFrame.size.height + 190) - 20 ), SCREEN_W, SCREEN_H );
        } completion:^(BOOL finished) {
            
        }];

    }else{
        [UIView animateWithDuration:animationDuration animations:^{
            alertView.frame = CGRectMake(0, -40, SCREEN_W, SCREEN_H );
        } completion:^(BOOL finished) {
            
        }];
    }
}

-(void)didClickButtonAtIndex:(NSUInteger)index password:(NSString *)password{
    switch (index) {
        case 101:
        {
            [self createNewUI];
            break;}
        case 100:
        {
            [self cancleView];
            break;}
        default:
            break;
    }
}

- (void)removeTableViewAndArray
{
//    [_tableView removeFromSuperview];
//    _nameArr = [NSMutableArray array];
//    _timeArr = [NSMutableArray array];
//    _dataSource = [NSMutableArray array];
    self.timeArray = [NSMutableArray array];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    manager.usepower_dict = [[NSMutableDictionary alloc] init];
    [HY_NSusefDefaults setObject:nil forKey:@"usePowerData"];
}

#pragma mark -- 查询数据
- (void)createNewUI
{
    HYSingleManager *manager = [HYSingleManager sharedManager];
    int user_type = manager.user.user_type;
    //下面的button是选择弹出框的按钮

    UIButton *btn1 = (UIButton *)[alertView viewWithTag:10000000];
    UIButton *btn2 = (UIButton *)[alertView viewWithTag:10000001];
    UIButton *btn3 = (UIButton *)[alertView viewWithTag:100000000];
    UIButton *btn4 = (UIButton *)[alertView viewWithTag:100000001];
    UIButton *btn5 = (UIButton *)[alertView viewWithTag:100000002];
    UIButton *btn6 = (UIButton *)[alertView viewWithTag:100000003];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([btn1 isSelected]&&[btn3 isSelected]) {
        
        [defaults setBool:btn1.selected forKey:@"santian"];
        [defaults setBool:btn3.selected forKey:@"quantian"];
        [defaults removeObjectForKey:@"yizhou"];
        [defaults removeObjectForKey:@"yiduan"];
        [defaults removeObjectForKey:@"liangduan"];
        [defaults removeObjectForKey:@"sanduan"];
        [defaults synchronize];
        //移除tableview并且清空数据源
        [self removeTableViewAndArray];
        request_type = 0;
        dayNum = 3;
        HYScoketManage * manage = [HYScoketManage shareManager];
        [manage getNetworkDatawithIP:ipv6Addr withTag:@"2"];
        [SVProgressHUD showWithStatus:@"通讯中..."];
        [manage writeDataToHostWithL:@"3"];
        [self cancleView];
    }else if ([btn1 isSelected]&&[btn4 isSelected]){
        if (![alertView.startF1.text isEqualToString:@""] && ![alertView.endF1.text isEqualToString:@""]) {
            if (!([self isNumText:alertView.startF1.text] && [self isNumText:alertView.endF1.text] )) {
                [UIView addMJNotifierWithText:@"请输入正确的时间" dismissAutomatically:YES];
                return;
            }
            [defaults setBool:btn1.selected forKey:@"santian"];
            [defaults setBool:btn4.selected forKey:@"yiduan"];
            [defaults removeObjectForKey:@"yizhou"];
            [defaults removeObjectForKey:@"quantian"];
            [defaults removeObjectForKey:@"liangduan"];
            [defaults removeObjectForKey:@"sanduan"];
            [defaults synchronize];
             [self removeTableViewAndArray];
            dayNum = 3;
            _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
            [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
            request_type = 1;
            int start1 = [alertView.startF1.text intValue];
            int end1 = [alertView.endF1.text intValue];
            self.timeArray = [self compare:start1 :end1 :3];
            [SVProgressHUD showWithStatus:@"通讯中..."];
            [self writeDataToHost];
            [self cancleView];
            
        }else{
            [UIView addMJNotifierWithText:@"起始时间输入错误" dismissAutomatically:YES];
        }
    }else if ([btn1 isSelected]&&[btn5 isSelected]){
        if (![alertView.startF2.text isEqualToString:@""] && ![alertView.endF2.text isEqualToString:@""]&&![alertView.startF3.text isEqualToString:@""] &&! [alertView.endF3.text isEqualToString:@""]) {
            if (!([self isNumText:alertView.startF2.text] && [self isNumText:alertView.endF2.text] && [self isNumText:alertView.startF3.text] && [self isNumText:alertView.endF3.text])) {
                [UIView addMJNotifierWithText:@"请输入正确的时间" dismissAutomatically:YES];
                return;
            }
            if (user_type == 4) {
                //提示失败
                [UIView addMJNotifierWithText:@"对不起,权限不够" dismissAutomatically:YES];
            }else{
                [defaults setBool:btn1.selected forKey:@"santian"];
                [defaults setBool:btn5.selected forKey:@"liangduan"];
                [defaults removeObjectForKey:@"yizhou"];
                [defaults removeObjectForKey:@"quantian"];
                [defaults removeObjectForKey:@"yiduan"];
                [defaults removeObjectForKey:@"sanduan"];
                [defaults synchronize];
                [self removeTableViewAndArray];
                _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
                [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
                request_type = 1;
                dayNum = 3;
                int start2 = [alertView.startF2.text intValue];
                int end2 = [alertView.endF2.text intValue];
                int start3 = [alertView.startF3.text intValue];
                int end3 = [alertView.endF3.text intValue];
                NSArray *arr1 = [self compare:start2 :end2 :3];
                NSArray *arr2 = [self compare:start3 :end3 :3];
                for (int i = 0; i<arr1.count; i++) {
                    [self.timeArray addObject:arr1[i]];
                }
                for (int i = 0; i<arr2.count; i++) {
                    [self.timeArray addObject:arr2[i]];
                }
                [SVProgressHUD showWithStatus:@"通讯中..."];
                [self writeDataToHost];
                [self cancleView];
            }
            
        }else{
            [UIView addMJNotifierWithText:@"起始时间输入错误" dismissAutomatically:YES];
        }
    }else if ([btn1 isSelected] && [btn6 isSelected]){
        if (![alertView.startF4.text isEqualToString:@""] && ![alertView.endF4.text isEqualToString:@""] && ![alertView.startF5.text isEqualToString:@""] && ![alertView.endF5.text isEqualToString:@""] && ![alertView.startF6.text isEqualToString:@""] && ![alertView.endF6.text isEqualToString:@""]) {
            
            if (!([self isNumText:alertView.startF4.text] && [self isNumText:alertView.endF4.text]&&[self isNumText:alertView.startF5.text] && [self isNumText:alertView.endF5.text]&&[self isNumText:alertView.startF6.text] && [self isNumText:alertView.endF6.text])) {
                [UIView addMJNotifierWithText:@"请输入正确的时间" dismissAutomatically:YES];
                return;
            }
            if (user_type == 4) {
                //提示
                [UIView addMJNotifierWithText:@"对不起,权限不够" dismissAutomatically:YES];
            }else{
                [defaults setBool:btn1.selected forKey:@"santian"];
                [defaults setBool:btn6.selected forKey:@"sanduan"];
                [defaults removeObjectForKey:@"yizhou"];
                [defaults removeObjectForKey:@"quantian"];
                [defaults removeObjectForKey:@"yiduan"];
                [defaults removeObjectForKey:@"liangduan"];
                [defaults synchronize];
                 [self removeTableViewAndArray];
                _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
                [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
                request_type = 1;
                int start4 = [alertView.startF4.text intValue];
                int end4 = [alertView.endF4.text intValue];
                int start5 = [alertView.startF5.text intValue];
                int end5 = [alertView.endF5.text intValue];
                int start6 = [alertView.startF6.text intValue];
                int end6 = [alertView.endF6.text intValue];
                dayNum = 3;
                NSArray *arr1 = [self compare:start4 :end4 :3];
                NSArray *arr2 = [self compare:start5 :end5 :3];
                NSArray *arr3 = [self compare:start6 :end6 :3];
                for (int i = 0; i<arr1.count; i++) {
                    [self.timeArray addObject:arr1[i]];
                }
                for (int i = 0; i<arr2.count; i++) {
                    [self.timeArray addObject:arr2[i]];
                }
                for (int i = 0; i<arr3.count; i++) {
                    [self.timeArray addObject:arr3[i]];
                }
                [SVProgressHUD showWithStatus:@"通讯中..."];
                [self writeDataToHost];
                [self cancleView];
            }
            
            
        }else{
            [UIView addMJNotifierWithText:@"起始时间输入错误" dismissAutomatically:YES];
        }
    }else if ([btn2 isSelected] && [btn3 isSelected]){
        
        if (user_type == 4) {
            //提示
            [UIView addMJNotifierWithText:@"对不起,权限不够" dismissAutomatically:YES];
        }else{
            [defaults setBool:btn2.selected forKey:@"yizhou"];
            [defaults setBool:btn3.selected forKey:@"quantian"];
            [defaults removeObjectForKey:@"santian"];
            [defaults removeObjectForKey:@"sanduan"];
            [defaults removeObjectForKey:@"yiduan"];
            [defaults removeObjectForKey:@"liangduan"];
            [defaults synchronize];
             [self removeTableViewAndArray];
            request_type = 0;
            dayNum = 7;
            HYScoketManage * manage = [HYScoketManage shareManager];
            [manage getNetworkDatawithIP:ipv6Addr withTag:@"2"];
            [SVProgressHUD showWithStatus:@"通讯中..."];
            [manage writeDataToHostWithL:@"7"];
            [self cancleView];

        }
        
    }else if ([btn2 isSelected] && [btn4 isSelected]){
        if (![alertView.startF1.text isEqualToString:@""] && ![alertView.endF1.text isEqualToString:@""]) {
            
            if (!([self isNumText:alertView.startF1.text] && [self isNumText:alertView.endF1.text])) {
                [UIView addMJNotifierWithText:@"请输入正确的时间" dismissAutomatically:YES];
                return;
            }
            if (user_type == 4) {
                //提示
                [UIView addMJNotifierWithText:@"对不起,权限不够" dismissAutomatically:YES];
            }else{
                [defaults setBool:btn2.selected forKey:@"yizhou"];
                [defaults setBool:btn4.selected forKey:@"yiduan"];
                [defaults removeObjectForKey:@"santian"];
                [defaults removeObjectForKey:@"quantian"];
                [defaults removeObjectForKey:@"liangduan"];
                [defaults removeObjectForKey:@"sanduan"];
                [defaults synchronize];
                 [self removeTableViewAndArray];
                _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
                [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
                request_type = 1;
                int start1 = [alertView.startF1.text intValue];
                int end1 = [alertView.endF1.text intValue];
                dayNum = 7;
                self.timeArray = [self compare:start1 :end1 :7];
                [SVProgressHUD showWithStatus:@"通讯中..."];
                [self writeDataToHost];
                [self cancleView];
            }
            
           
        }else{
            [UIView addMJNotifierWithText:@"起始时间输入错误" dismissAutomatically:YES];
        }
    }else if ([btn2 isSelected] && [btn5 isSelected]){
        if (![alertView.startF2.text isEqualToString:@""] && ![alertView.endF2.text isEqualToString:@""]&&![alertView.startF3.text isEqualToString:@""] &&! [alertView.endF3.text isEqualToString:@""]) {
            
            if (!([self isNumText:alertView.startF2.text] && [self isNumText:alertView.endF2.text] && [self isNumText:alertView.startF3.text] && [self isNumText:alertView.endF3.text])) {
                [UIView addMJNotifierWithText:@"请输入正确的时间" dismissAutomatically:YES];
                return;
            }

            if (user_type == 4) {
                //提示
                [UIView addMJNotifierWithText:@"对不起,权限不够" dismissAutomatically:YES];
            }else{
                [defaults setBool:btn2.selected forKey:@"yizhou"];
                [defaults setBool:btn5.selected forKey:@"liangduan"];
                [defaults removeObjectForKey:@"santian"];
                [defaults removeObjectForKey:@"quantian"];
                [defaults removeObjectForKey:@"yiduan"];
                [defaults removeObjectForKey:@"sanduan"];
                [defaults synchronize];
                 [self removeTableViewAndArray];
                _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
                [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
                request_type = 1;
                int start2 = [alertView.startF2.text intValue];
                int end2 = [alertView.endF2.text intValue];
                int start3 = [alertView.startF3.text intValue];
                int end3 = [alertView.endF3.text intValue];
                dayNum = 7;
                NSArray *arr1 = [self compare:start2 :end2 :7];
                NSArray *arr2 = [self compare:start3 :end3 :7];
                for (int i = 0; i<arr1.count; i++) {
                    [self.timeArray addObject:arr1[i]];
                }
                for (int i = 0; i<arr2.count; i++) {
                    [self.timeArray addObject:arr2[i]];
                }
                [SVProgressHUD showWithStatus:@"通讯中..."];
                [self writeDataToHost];
                [self cancleView];
            }
            
           
        }else{
            [UIView addMJNotifierWithText:@"起始时间输入错误" dismissAutomatically:YES];
        }
    }else if ([btn2 isSelected] && [btn6 isSelected]){
        if (![alertView.startF4.text isEqualToString:@""] && ![alertView.endF4.text isEqualToString:@""] && ![alertView.startF5.text isEqualToString:@""] && ![alertView.endF5.text isEqualToString:@""] && ![alertView.startF6.text isEqualToString:@""] && ![alertView.endF6.text isEqualToString:@""]) {
            if (!([self isNumText:alertView.startF4.text] && [self isNumText:alertView.startF5.text] && [self isNumText:alertView.startF6.text] && [self isNumText:alertView.endF4.text] && [self isNumText:alertView.endF5.text] && [self isNumText:alertView.endF6.text])) {
                [UIView addMJNotifierWithText:@"请输入正确的时间" dismissAutomatically:YES];
                return;
            }
            if (user_type == 4) {
                //提示
                [UIView addMJNotifierWithText:@"对不起,权限不够" dismissAutomatically:YES];
            }else{
                [defaults setBool:btn2.selected forKey:@"yizhou"];
                [defaults setBool:btn6.selected forKey:@"sanduan"];
                [defaults removeObjectForKey:@"santian"];
                [defaults removeObjectForKey:@"quantian"];
                [defaults removeObjectForKey:@"yiduan"];
                [defaults removeObjectForKey:@"liangduan"];
                [defaults synchronize];
                 [self removeTableViewAndArray];
                _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
                [_sendSocket connectToHost:ipv6Addr onPort:SocketonPort withTimeout:10 error:nil];
                request_type = 1;
                int start4 = [alertView.startF4.text intValue];
                int end4 = [alertView.endF4.text intValue];
                int start5 = [alertView.startF5.text intValue];
                int end5 = [alertView.endF5.text intValue];
                int start6 = [alertView.startF6.text intValue];
                int end6 = [alertView.endF6.text intValue];
                dayNum = 7;
                NSArray *arr1 = [self compare:start4 :end4 :7];
                NSArray *arr2 = [self compare:start5 :end5 :7];
                NSArray *arr3 = [self compare:start6 :end6 :7];
                for (int i = 0; i<arr1.count; i++) {
                    [self.timeArray addObject:arr1[i]];
                }
                for (int i = 0; i<arr2.count; i++) {
                    [self.timeArray addObject:arr2[i]];
                }
                for (int i = 0; i<arr3.count; i++) {
                    [self.timeArray addObject:arr3[i]];
                }
                [SVProgressHUD showWithStatus:@"通讯中..."];
                [self writeDataToHost];
                [self cancleView];
            }
            
            
        }else{
            [UIView addMJNotifierWithText:@"起始时间输入错误" dismissAutomatically:YES];
        }
    }

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

- (void)createBaseUI
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W, 30)];
    UILabel *setName = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W/3, 30)];
    setName.text = @"名称";
    [setName setFont:[UIFont systemFontOfSize:12]];
    setName.backgroundColor = RGB(1,127,80);
    [setName setTextColor:[UIColor whiteColor]];
    setName.textAlignment = NSTextAlignmentCenter;
    UILabel *date = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/3, 0, SCREEN_W/3, 30)];
    date.text = @"日期";
    [date setFont:[UIFont systemFontOfSize:12]];
    date.backgroundColor = RGB(67, 205, 128);
    [date setTextColor:[UIColor whiteColor]];
    date.textAlignment = NSTextAlignmentCenter;
    UILabel *tableCode = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_W/3)*2, 0, SCREEN_W/3, 30)];
    tableCode.text = @"用量";
    [tableCode setFont:[UIFont systemFontOfSize:12]];
    tableCode.backgroundColor = RGB(1,127,80);
    [tableCode setTextColor:[UIColor whiteColor]];
    tableCode.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:view];
    [view addSubview:setName];
    [view addSubview:date];
    [view addSubview:tableCode];
    [self.leftButton setImage:[UIImage imageNamed:@"icon_function"] forState:UIControlStateNormal];
    [self setLeftButtonClick:@selector(leftButtonClick)];
    [self.rightButton setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [self setRightButtonClick:@selector(rightButtonClick)];
}

//获取当前时间
- (NSInteger)getCurrentDate
{
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY/MM/dd/HH/mm"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    NSArray *arr = [dateString componentsSeparatedByString:@"/"];// '/'分割日期字符串,得到一数组
    NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1lx",[arr[3] integerValue]]];
    UInt64 currentHour = strtoull([hexString UTF8String], 0, 16);
    NSInteger current = (NSInteger)(currentHour);
    return current;
}

- (NSMutableArray *)getCurrentDay
{
    NSMutableArray * dayArr = [[NSMutableArray alloc] init];
    for (int i = dayNum-1; i >=0 ; i--) {
        NSDate *currentDate = [NSDate dateWithTimeIntervalSinceNow:-60*60*24*i];//获取当前时间，日期
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YY/MM/dd/HH/mm"];
        NSString *dateString = [dateFormatter stringFromDate:currentDate];
        NSArray *arr = [dateString componentsSeparatedByString:@"/"];// '/'分割日期字符串,得到一数组
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1lx",[arr[2] integerValue]]];
        UInt64 currentHour = strtoull([hexString UTF8String], 0, 16);
        NSInteger current = (NSInteger)(currentHour);
        [dayArr addObject:[NSString stringWithFormat:@"%ld",current]];
    }
    return dayArr;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataSource.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
    NSLog(@"tableCode%ld--%@",error.code,error.userInfo);
    if (error.code == 3) {
        NSLog(@"超时");
        [SVProgressHUD dismiss];
        [UIView addMJNotifierWithText:@"请检查您的网络环境" dismissAutomatically:YES];
    }else if(error.code == 51){
        [SVProgressHUD dismiss];
        [UIView addMJNotifierWithText:@"网络无连接" dismissAutomatically:YES];
    }else if(error.code == 0){
        
    }else if(error.code == 4){
        [SVProgressHUD dismiss];
        NSLog(@"Socket 断开链接%d",[_sendSocket isConnected]);
    }else if(error.code == 61){
        [SVProgressHUD dismiss];
        [UIView addMJNotifierWithText:@"无法连接到服务器" dismissAutomatically:YES];
    }else{
        [SVProgressHUD dismiss];
        [UIView addMJNotifierWithText:@"获取数据失败" dismissAutomatically:YES];
    }
    
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellDentifier = @"usepowercell";
    MyCell *cell = [tableView dequeueReusableCellWithIdentifier:cellDentifier];
    if (cell == nil) {
        cell = [[MyCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellDentifier];
    }
    [cell.timeLabel setFont:[UIFont systemFontOfSize:9]];
    [cell.timeLabel adjustsFontSizeToFitWidth];
    if (request_type == 0)
    {
        for (DeviceModel * de  in _data) {
            for (int i = 0 ;i < de.dataArr.count - 1;i++) {
                DataModel * data = de.dataArr[i];
                [_nameArr addObject:data.name];
//                NSString * time = [NSString stringWithFormat:@"%@-%@",data.Month,data.day];
//                [_timeArr addObject:time];
            }
        }
    }
    [cell setNameLabel:_nameArr[indexPath.row] timeLabel:_timeArr[indexPath.row] tableCodeLabel:_dataSource[indexPath.row]];
    
    return cell;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//获得设备型号
- (NSString *)getCurrentDeviceModel
{
    int mib[2];
    size_t len;
    char *machine;
    
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    machine = malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    // iPhone
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone2G";
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone3G";
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone3GS";
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone4";
    if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone4";
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone4";
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone4S";
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone5";
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone5";
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone5c";
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone5c";
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone5s";
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone5s";
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone6";
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone6Plus";
    if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone6s";
    if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone6sPlus";
    if ([platform isEqualToString:@"iPhone8,3"]) return @"iPhoneSE";
    if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhoneSE";
    if ([platform isEqualToString:@"iPhone9,1"]) return @"iPhone7";
    if ([platform isEqualToString:@"iPhone9,2"]) return @"iPhone7Plus";
    
    //iPod Touch
    if ([platform isEqualToString:@"iPod1,1"])   return @"iPodTouch";
    if ([platform isEqualToString:@"iPod2,1"])   return @"iPodTouch2G";
    if ([platform isEqualToString:@"iPod3,1"])   return @"iPodTouch3G";
    if ([platform isEqualToString:@"iPod4,1"])   return @"iPodTouch4G";
    if ([platform isEqualToString:@"iPod5,1"])   return @"iPodTouch5G";
    if ([platform isEqualToString:@"iPod7,1"])   return @"iPodTouch6G";
    
    //iPad
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])   return @"iPad2";
    if ([platform isEqualToString:@"iPad2,2"])   return @"iPad2";
    if ([platform isEqualToString:@"iPad2,3"])   return @"iPad2";
    if ([platform isEqualToString:@"iPad2,4"])   return @"iPad2";
    if ([platform isEqualToString:@"iPad3,1"])   return @"iPad3";
    if ([platform isEqualToString:@"iPad3,2"])   return @"iPad3";
    if ([platform isEqualToString:@"iPad3,3"])   return @"iPad3";
    if ([platform isEqualToString:@"iPad3,4"])   return @"iPad4";
    if ([platform isEqualToString:@"iPad3,5"])   return @"iPad4";
    if ([platform isEqualToString:@"iPad3,6"])   return @"iPad4";
    
    //iPad Air
    if ([platform isEqualToString:@"iPad4,1"])   return @"iPadAir";
    if ([platform isEqualToString:@"iPad4,2"])   return @"iPadAir";
    if ([platform isEqualToString:@"iPad4,3"])   return @"iPadAir";
    if ([platform isEqualToString:@"iPad5,3"])   return @"iPadAir2";
    if ([platform isEqualToString:@"iPad5,4"])   return @"iPadAir2";
    
    //iPad mini
    if ([platform isEqualToString:@"iPad2,5"])   return @"iPadmini1G";
    if ([platform isEqualToString:@"iPad2,6"])   return @"iPadmini1G";
    if ([platform isEqualToString:@"iPad2,7"])   return @"iPadmini1G";
    if ([platform isEqualToString:@"iPad4,4"])   return @"iPadmini2";
    if ([platform isEqualToString:@"iPad4,5"])   return @"iPadmini2";
    if ([platform isEqualToString:@"iPad4,6"])   return @"iPadmini2";
    if ([platform isEqualToString:@"iPad4,7"])   return @"iPadmini3";
    if ([platform isEqualToString:@"iPad4,8"])   return @"iPadmini3";
    if ([platform isEqualToString:@"iPad4,9"])   return @"iPadmini3";
    if ([platform isEqualToString:@"iPad5,1"])   return @"iPadmini4";
    if ([platform isEqualToString:@"iPad5,2"])   return @"iPadmini4";
    
    if ([platform isEqualToString:@"i386"])      return @"iPhoneSimulator";
    if ([platform isEqualToString:@"x86_64"])    return @"iPhoneSimulator";
    return platform;
}
@end
