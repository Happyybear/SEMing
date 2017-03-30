//
//  HYStateViewController.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYStateViewController.h"
#import "QueryCell.h"
#import "CaTreeModel.h"
#import "ChartViewController.h"
#import "HYSEM-Bridging-Header.h"
#import "HYScoketManage.h"
#import "DeviceModel.h"
#import "DataModel.h"
#import "DateModel.h"
#import "HYExplainManager.h"
@interface HYStateViewController ()<TWlALertviewDelegate,UITableViewDelegate,UITableViewDataSource,ChartViewDelegate,IChartAxisValueFormatter>
{
    GCDAsyncSocket *_sendSocket;
    int requestValue;//区分一次二次值,0 表示一次值  1表示二次值
    TWLAlertView *alertView;
    int request_type;
    NSString *_label1;
    NSString *_label2;
    NSString *_label3;
    int isAppend;//区分粘包
    NSMutableData *mData;
    int appendLen;
    UITableView *_tableView;
    NSMutableArray *_dataSource;
    NSMutableArray *_dataSourceA;
    NSMutableArray *_dataSourceB;
    NSMutableArray *_dataSourceC;
    NSMutableArray *_timeArray;//时间数组
    NSMutableArray *_nameArr;//名字数组
    int _days;
    NSString *_MpName;//用来创建折线图时接收通知传值
    NSString *_MpID;//同上
    UILabel *_MpLabel;//webVied上边表示表名字的label
    NSString *ipv6Addr;
    NSString * nameA;
    NSString * nameB;
    NSString * nameC;
    int _indexSegment;//区分是列表还是图像,0:列表  1:图像
}

@property (nonatomic,strong) NSMutableArray *timeArr;

@property (nonatomic,strong) LineChartView *LineChartView;

@end

@implementation HYStateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    manager.memory_Array = [[NSMutableArray alloc] init];
    [self recieveData];
    if (manager.user.user_type == 4) {
        //提示升级
        self.titleLabel.text = @"状态分析";
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [UIView addMJNotifierWithText:@"对不起,权限不足!" dismissAutomatically:NO];
    }else{
        isAppend = 0;
        appendLen = 0;
        mData = [[NSMutableData alloc]init];
        ipv6Addr = [self convertHostToAddress:SocketHOST];
        [self initDictionary];
        [self createBaseUI];
        _sendSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        //点击表的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clickMp:) name:@"selected" object:nil];
        //默认情况下是选择第一块表
        NSMutableArray *nameArr = [NSMutableArray array];
        NSMutableArray *mp_IDArr = [NSMutableArray array];
        HYSingleManager *manager = [HYSingleManager sharedManager];
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
        _MpID = mp_IDArr[0];
        _MpName = nameArr[0];
    }
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *number = [defaults objectForKey:@"whichOption"];
    NSString *string = [NSString stringWithFormat:@"%@",number];
    if ([self isBlankString:string]) {
        _label1 = @"总有功功率";
        _label2 = @"总无功功率";
        _label3 = @"总视在功率";
        _days = 3;
        _timeArray = [self returnTime:_days];
        request_type = 1;
        requestValue = 0;
        HYScoketManage * manger = [HYScoketManage shareManager];
        //tag=3表示是状态模块请求
        [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
        [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
    }else{
        [self whichOption];
    }
}

- (void)whichOption
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *number = [defaults objectForKey:@"whichOption"];
    int value = [number intValue];
    HYScoketManage * manger = [HYScoketManage shareManager];
    switch (value) {
        case 0:
        {
            _label1 = @"总有功功率";
            _label2 = @"总无功功率";
            _label3 = @"总视在功率";
            _days = 3;
            self.timeArr = [self getCurrentTime:_days];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"YY/MM/dd"];
            NSArray * t = self.timeArr[0];
            NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%@/%@/%@",t[2],t[3],t[4]]];
            NSTimeInterval dis = [curDate timeIntervalSince1970];
            NSString * tString = [NSString stringWithFormat:@"%f",dis];
            [HY_NSusefDefaults setObject:tString forKey:@"TIME"];
            
            request_type = 1;
            requestValue = 0;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 1:
        {
            _label1 = @"A相电压";
            _label2 = @"B相电压";
            _label3 = @"C相电压";
            _days = 3;
            request_type = 2;
            self.timeArr = [self getCurrentTime:_days];
            requestValue = 0;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 2:
        {
            _label1 = @"A相电流";
            _label2 = @"B相电流";
            _label3 = @"C相电流";
            _days = 3;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 3;
            requestValue = 0;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 3:
        {
            _label1 = @"A相有功功率";
            _label2 = @"B相有功功率";
            _label3 = @"C相有功功率";
            _days = 3;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 4;
            requestValue = 0;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
           [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 4:
        {
            _label1 = @"A相无功功率";
            _label2 = @"B相无功功率";
            _label3 = @"C相无功功率";
            _days = 3;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 5;
            requestValue = 0;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 5:
        {
            _label1 = @"总有功功率";
            _label2 = @"总无功功率";
            _label3 = @"总视在功率";
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 1;
            requestValue = 0;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];            break;
        }
        case 6:
        {
            _label1 = @"A相电压";
            _label2 = @"B相电压";
            _label3 = @"C相电压";
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 2;
            requestValue = 0;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 7:
        {
            _label1 = @"A相电流";
            _label2 = @"B相电流";
            _label3 = @"C相电流";
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 3;
            requestValue = 0;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 8:
        {
            _label1 = @"A相有功功率";
            _label2 = @"B相有功功率";
            _label3 = @"C相有功功率";
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 4;
            requestValue = 0;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
           [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];            break;
        }
        case 9:
        {
            _label1 = @"A相无功功率";
            _label2 = @"B相无功功率";
            _label3 = @"C相无功功率";
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 5;
            requestValue = 0;
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 10:
        {
            break;
        }
        case 11:
        {
            break;
        }
        case 12:
        {
            break;
        }
        case 13:
        {
            break;
        }
        case 14:
        {
            break;
        }
        case 15:
        {
            _label1 = @"总有功功率";
            _label2 = @"总无功功率";
            _label3 = @"总视在功率";
            _days = 3;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 1;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];            break;
        }
        case 16:
        {
            _label1 = @"A相电压";
            _label2 = @"B相电压";
            _label3 = @"C相电压";
            _days = 3;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 2;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
           [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 17:
        {
            _label1 = @"A相电流";
            _label2 = @"B相电流";
            _label3 = @"C相电流";
            _days = 3;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 3;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 18:
        {
            _label1 = @"A相有功功率";
            _label2 = @"B相有功功率";
            _label3 = @"C相有功功率";
            _days = 3;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 4;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 19:
        {
            _label1 = @"A相无功功率";
            _label2 = @"B相无功功率";
            _label3 = @"C相无功功率";
            _days = 3;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 5;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 20:
        {
            _label1 = @"总有功功率";
            _label2 = @"总无功功率";
            _label3 = @"总视在功率";
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 1;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 21:
        {
            _label1 = @"A相电压";
            _label2 = @"B相电压";
            _label3 = @"C相电压";
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 2;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 22:
        {
            _label1 = @"A相电流";
            _label2 = @"B相电流";
            _label3 = @"C相电流";
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 3;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 23:
        {
            _label1 = @"A相有功功率";
            _label2 = @"B相有功功率";
            _label3 = @"C相有功功率";
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 4;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        case 24:
        {
            _label1 = @"A相无功功率";
            _label2 = @"B相无功功率";
            _label3 = @"C相无功功率";
            _days = 7;
            self.timeArr = [self getCurrentTime:_days];
            request_type = 5;
            requestValue = 1;
            [manger getNetworkDatawithIP:@"123.233.120.197" withTag:@"3"];
            [manger writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
            break;
        }
        default:
            break;
    }
}


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

//接收通知传递过来的表信息
- (void)clickMp:(NSNotification *)notification
{
    CaTreeModel *model = [notification object];
    if (model != nil) {
        _MpID = model.node.MpID;
        _MpName = model.node.name;
    }else{
        //默认情况下是选择第一块表
        NSMutableArray *nameArr = [NSMutableArray array];
        NSMutableArray *mp_IDArr = [NSMutableArray array];
        HYSingleManager *manager = [HYSingleManager sharedManager];
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
        _MpID = mp_IDArr[0];
        _MpName = nameArr[0];
    }
    //刷新折线图
    [self refreshChartView];
}

- (void)refreshChartView
{
    //先将原来的折线图从父视图移除(别忘了webview上边表示表名字的lable)
    [_MpLabel removeFromSuperview];
    for (UIView * view in self.second.view.subviews) {
        [view removeFromSuperview];
    }
    [self.LineChartView removeFromSuperview];
    //重新创建折线图`
    [self createChartView];
}


- (void)createTableView
{
    self.first.view.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
    self.first.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.first.view];
    [self.first didMoveToParentViewController:self];
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0,30,SCREEN_W , SCREEN_H-76) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.first.view addSubview:_tableView];
}



//初始化单例中可变字典
- (void)initDictionary
{
    HYSingleManager *manager = [HYSingleManager sharedManager];
    self.timeArr = [NSMutableArray array];
    manager.total_actPower_dict = [NSMutableDictionary dictionary];
    manager.total_reactPower_dict = [NSMutableDictionary dictionary];
    manager.total_apparentPower_dict = [NSMutableDictionary dictionary];
    manager.voltageA_dict = [NSMutableDictionary dictionary];
    manager.voltageB_dict = [NSMutableDictionary dictionary];
    manager.voltageC_dict = [NSMutableDictionary dictionary];
    manager.electricA_dict = [NSMutableDictionary dictionary];
    manager.electricB_dict = [NSMutableDictionary dictionary];
    manager.electricC_dict = [NSMutableDictionary dictionary];
    manager.activeA_dict = [NSMutableDictionary dictionary];
    manager.activeB_dict = [NSMutableDictionary dictionary];
    manager.activeC_dict = [NSMutableDictionary dictionary];
    manager.reactiveA_dict = [NSMutableDictionary dictionary];
    manager.reactiveB_dict = [NSMutableDictionary dictionary];
    manager.reactiveC_dict = [NSMutableDictionary dictionary];
    _dataSourceA = [NSMutableArray array];
    _dataSourceB = [NSMutableArray array];
    _dataSourceC = [NSMutableArray array];
    _dataSource = [NSMutableArray array];
    _timeArr = [NSMutableArray array];
    _nameArr = [NSMutableArray array];
    
}


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

-(void) recieveData{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createDataSource) name:@"getStatusData" object:nil];
}


-(void) createDataSource{
    [self createTableHead];
    HYSingleManager * manager = [HYSingleManager sharedManager];
    manager.rea_memory_Array = [[NSMutableArray alloc] init];
    manager.rea_memory_Array = manager.memory_Array;
    _dataSource = manager.memory_Array;
    
    [SVProgressHUD showSuccessWithStatus:@"通讯成功"];
    [SVProgressHUD dismiss];
    
    if (_indexSegment == 0) {
        self.first.view.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
        self.first.view.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.first.view];
        [self.first didMoveToParentViewController:self];
        [self createTableView];
    }else{
        self.second.view.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
        self.second.view.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.second.view];
        [self.second didMoveToParentViewController:self];
        [self performSelector:@selector(refreshChartView) withObject:nil afterDelay:0.3f];
    }
    
    
    //时间数据源
    NSArray *time = [self getCurrentTime:_days];
    NSMutableArray *a = [NSMutableArray array];
    _timeArray = [NSMutableArray array];
    for (int i = 0; i<time.count; i++) {
        NSArray *arr = time[i];
        if (i == (time.count -1)) {
            int hour = [self getCurrentHour];
            for (int j = 0; j<hour; j++) {
                NSString *str1 = [NSString stringWithFormat:@"%@-%@ %02d:00",arr[3],arr[4],j];
                [a addObject:str1];
                NSString *str2 = [NSString stringWithFormat:@"%@-%@ %02d:15",arr[3],arr[4],j];
                [a addObject:str2];
                NSString *str3 = [NSString stringWithFormat:@"%@-%@ %02d:30",arr[3],arr[4],j];
                [a addObject:str3];
                NSString *str4 = [NSString stringWithFormat:@"%@-%@ %02d:45",arr[3],arr[4],j];
                [a addObject:str4];
            }
        }else{
            for (int k = 0; k<24; k++) {
                NSString *str1 = [NSString stringWithFormat:@"%@-%@ %02d:00",arr[3],arr[4],k];
                [a addObject:str1];
                NSString *str2 = [NSString stringWithFormat:@"%@-%@ %02d:15",arr[3],arr[4],k];
                [a addObject:str2];
                NSString *str3 = [NSString stringWithFormat:@"%@-%@ %02d:30",arr[3],arr[4],k];
                [a addObject:str3];
                NSString *str4 = [NSString stringWithFormat:@"%@-%@ %02d:45",arr[3],arr[4],k];
                [a addObject:str4];
            }
        }
    }
    for (int i = 0; i<_dataSource.count; i++) {
        for (int j = 0; j<a.count; j++) {
            [_timeArray addObject:a[j]];
        }
    }

    
    //图表数据
}

- (NSMutableArray *)returnTime:(int)day
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
        NSMutableArray *time = [NSMutableArray arrayWithArray:arr1];
        [time insertObject:@"1" atIndex:0];
        [time insertObject:[NSString stringWithFormat:@"%d",24] atIndex:0];
        [time replaceObjectAtIndex:5 withObject:@"0"];
        [time replaceObjectAtIndex:6 withObject:@"0"];
        [record addObject:time];
    }
    
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i<record.count; i++) {
        NSMutableArray *arr = [NSMutableArray array];
        [array addObject:arr];
        NSArray *arrrr = record[i];
        
        for (int j = 0; j<arrrr.count; j++) {
            [array[i] addObject:arrrr[j]];
        }
    }
    
    return array;
}

//获取当前时间整点
- (int)getCurrentHour
{
    NSDate * currentDate = [NSDate date];
    NSDateFormatter * dateFormatter =[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY/MM/dd/HH/mm"];
    NSDate *nowDate = [currentDate initWithTimeIntervalSinceNow:0];
    NSString *strNow = [dateFormatter stringFromDate:nowDate];
    NSArray *nowArr = [strNow componentsSeparatedByString:@"/"];
    return [nowArr[3] intValue];
}

- (NSMutableArray *)getCurrentTime:(int)days
{
    NSMutableArray * record = [[NSMutableArray alloc] init];//日期数组record[1]存储第一天的数组
    NSDate * currentDate = [NSDate date];
    NSDateFormatter * dateFormatter =[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY/MM/dd/HH/mm"];
    NSTimeInterval  oneDay = 24*60*60*1;  //1天的长度
    NSDate *nowDate = [currentDate initWithTimeIntervalSinceNow:0];
    NSString *strNow = [dateFormatter stringFromDate:nowDate];
    NSArray *nowArr = [strNow componentsSeparatedByString:@"/"];
    for (int i = days -1; i>=0; i--) {
        NSDate *theDate1;
        theDate1 = [currentDate initWithTimeIntervalSinceNow: -oneDay*i];
        NSString *dateString1 = [dateFormatter stringFromDate:theDate1];
        NSArray *arr1 = [dateString1 componentsSeparatedByString:@"/"];// '/'分割日期字符串,得到一数组
        NSMutableArray *time = [NSMutableArray arrayWithArray:arr1];
        [time insertObject:@"1" atIndex:0];
        if (0 == i) {
            [time insertObject:[NSString stringWithFormat:@"%d",[nowArr[3] intValue]*4] atIndex:0];
        }else{
            [time insertObject:[NSString stringWithFormat:@"%d",24*4] atIndex:0];
        }
        //[time insertObject:[NSString stringWithFormat:@"%d",24] atIndex:0];
        [time replaceObjectAtIndex:5 withObject:@"0"];
        [time replaceObjectAtIndex:6 withObject:@"0"];
        [record addObject:time];
    }
    
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i<record.count; i++) {
        NSMutableArray *arr = [NSMutableArray array];
        [array addObject:arr];
        NSArray *arrrr = record[i];
        
        for (int j = 0; j<arrrr.count; j++) {
            [array[i] addObject:arrrr[j]];
        }
    }
    
    return record;
}

//十进制转换为16进制字符串
- (NSString *)ToHex:(uint16_t)tmpid
{
    NSString *nLetterValue;
    NSString *str =@"";
    uint16_t ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
        
    }
    return str;
}


//判断是否解析完
- (BOOL)isFinished
{
    HYSingleManager *single = [HYSingleManager sharedManager];
    NSArray *arr1 = [single.total_actPower_dict allValues];
    NSArray *arr2 = [single.total_reactPower_dict allValues];
    NSArray *arr3 = [single.total_apparentPower_dict allValues];
    NSArray *arr4 = [single.voltageA_dict allValues];
    NSArray *arr5 = [single.voltageB_dict allValues];
    NSArray *arr6 = [single.voltageC_dict allValues];
    NSArray *arr7 = [single.electricA_dict allValues];
    NSArray *arr8 = [single.electricB_dict allValues];
    NSArray *arr9 = [single.electricC_dict allValues];
    NSArray *arr10 = [single.activeA_dict allValues];
    NSArray *arr11 = [single.activeB_dict allValues];
    NSArray *arr12 = [single.activeC_dict allValues];
    NSArray *arr13 = [single.reactiveA_dict allValues];
    NSArray *arr14 = [single.reactiveB_dict allValues];
    NSArray *arr15 = [single.reactiveC_dict allValues];
    NSMutableArray *dicArr = [[NSMutableArray alloc]init];

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
    
    if (request_type == 1) {
        [dicArr addObject:arr1];
        [dicArr addObject:arr2];
        [dicArr addObject:arr3];
        for (int i = 0; i<dicArr.count; i++) {
            NSArray *dic = dicArr[i];//allValues
            if (dic.count == name_ID.count) {
                for (int j = 0; j<dic.count; j++) {
                    NSDictionary *dict = dic[j];
                    NSArray *keys = [dict allKeys];
                    for (int k = 0; k<_days; k++) {
                        if (![keys containsObject:[NSString stringWithFormat:@"%d",k]]) {
                            return NO;
                        }
                    }
                }
            }else{
                return NO;
            }
        }

    }else if (request_type == 2){
        [dicArr addObject:arr4];
        [dicArr addObject:arr5];
        [dicArr addObject:arr6];
        for (int i = 0; i<dicArr.count; i++) {
            NSArray *dic = dicArr[i];//allValues
            if (dic.count == name_ID.count) {
                for (int j = 0; j<dic.count; j++) {
                    NSDictionary *dict = dic[j];
                    NSArray *keys = [dict allKeys];
                    for (int k = 0; k<_days; k++) {
                        if (![keys containsObject:[NSString stringWithFormat:@"%d",k]]) {
                            return NO;
                        }
                    }
                }
            }else{
                return NO;
            }
        }
    }else if (request_type == 3){
        [dicArr addObject:arr7];
        [dicArr addObject:arr8];
        [dicArr addObject:arr9];
        for (int i = 0; i<dicArr.count; i++) {
            NSArray *dic = dicArr[i];//allValues
            if (dic.count == name_ID.count) {
                for (int j = 0; j<dic.count; j++) {
                    NSDictionary *dict = dic[j];
                    NSArray *keys = [dict allKeys];
                    for (int k = 0; k<_days; k++) {
                        if (![keys containsObject:[NSString stringWithFormat:@"%d",k]]) {
                            return NO;
                        }
                    }
                }
            }else{
                return NO;
            }
        }
    }else if (request_type == 4){
        [dicArr addObject:arr10];
        [dicArr addObject:arr11];
        [dicArr addObject:arr12];
        for (int i = 0; i<dicArr.count; i++) {
            NSArray *dic = dicArr[i];//allValues
            if (dic.count == name_ID.count) {
                for (int j = 0; j<dic.count; j++) {
                    NSDictionary *dict = dic[j];
                    NSArray *keys = [dict allKeys];
                    for (int k = 0; k<_days; k++) {
                        if (![keys containsObject:[NSString stringWithFormat:@"%d",k]]) {
                            return NO;
                        }
                    }
                }
            }else{
                return NO;
            }
        }
    }else if (request_type == 5){
        [dicArr addObject:arr13];
        [dicArr addObject:arr14];
        [dicArr addObject:arr15];
        for (int i = 0; i<dicArr.count; i++) {
            NSArray *dic = dicArr[i];//allValues
            if (dic.count == name_ID.count) {
                for (int j = 0; j<dic.count; j++) {
                    NSDictionary *dict = dic[j];
                    NSArray *keys = [dict allKeys];
                    for (int k = 0; k<_days; k++) {
                        if (![keys containsObject:[NSString stringWithFormat:@"%d",k]]) {
                            return NO;
                        }
                    }
                }
            }else{
                return NO;
            }
        }
    }
    
    return YES;

}

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
            for (int l = 0; l<self.timeArr.count; l++) {
                NSArray *time = self.timeArr[l];
                int length = [expalin TSR376_GetACK_QueryInfFame:terminal.term_ID mp_pointArr:Pn mp_pointNum:len timeArr:time request_type:request_type Usr_checkID:manager.user.check_ID OutBufData:outbuf];
                NSData *data = [NSData dataWithBytes:outbuf length:length];
                [_sendSocket writeData:data withTimeout:10 tag:0];
            }
        }
    }
}

//弹出框的点击事件
- (void)createNewUI
{
    HYSingleManager * manager = [HYSingleManager sharedManager];
    manager.memory_Array = [[NSMutableArray alloc] init];
    UIButton *btn1 = (UIButton *)[alertView viewWithTag:200];//一次值
    UIButton *btn2 = (UIButton *)[alertView viewWithTag:201];//二次
    UIButton *btn3 = (UIButton *)[alertView viewWithTag:2000];//三天
    UIButton *btn4 = (UIButton *)[alertView viewWithTag:2001];//七天
    UIButton *btn5 = (UIButton *)[alertView viewWithTag:2002];//两周
    UIButton *btn6 = (UIButton *)[alertView viewWithTag:20000];//总功率
    UIButton *btn7 = (UIButton *)[alertView viewWithTag:20001];//电压
    UIButton *btn8 = (UIButton *)[alertView viewWithTag:20002];//电流
    UIButton *btn9 = (UIButton *)[alertView viewWithTag:20003];//有功
    UIButton *btn10 = (UIButton *)[alertView viewWithTag:20004];//无功
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([btn1 isSelected]&&[btn3 isSelected]&&[btn6 isSelected]) {
        NSLog(@"一次值,三天,总功率");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn6.selected forKey:@"zonggong"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:0] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 1;
        requestValue = 0;//0 表示一次值 1 表示二次值
        _label1 = @"总有功功率";
        _label2 = @"总无功功率";
        _label3 = @"总视在功率";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
        
    }else if ([btn1 isSelected]&&[btn3 isSelected]&&[btn7 isSelected]){
        NSLog(@"一次值,三天,电压");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn7.selected forKey:@"dianya"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:1] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 2;
        requestValue = 0;
        _label1 = @"A相电压";
        _label2 = @"B相电压";
        _label3 = @"C相电压";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn1 isSelected]&&[btn3 isSelected]&&[btn8 isSelected]){
        NSLog(@"一次值,三天,电流");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn8.selected forKey:@"dianliu"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:2] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 3;
        requestValue = 0;
        _label1 = @"A相电流";
        _label2 = @"B相电流";
        _label3 = @"C相电流";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];        }
        
    }else if ([btn1 isSelected]&&[btn3 isSelected]&&[btn9 isSelected]){
        NSLog(@"一次值,三天,有功");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn9.selected forKey:@"yougong"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:3] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 4;
        requestValue = 0;
        _label1 = @"A相有功功率";
        _label2 = @"B相有功功率";
        _label3 = @"C相有功功率";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn1 isSelected]&&[btn3 isSelected]&&[btn10 isSelected]){
        NSLog(@"一次值,三天,无功");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn10.selected forKey:@"wugong"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults setObject:[NSNumber numberWithInt:4] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 5;
        requestValue = 0;
        _label1 = @"A相无功功率";
        _label2 = @"B相无功功率";
        _label3 = @"C相无功功率";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn1 isSelected]&&[btn4 isSelected]&&[btn6 isSelected]){
        NSLog(@"一次值,一周,总功率");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn6.selected forKey:@"zonggong"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:5] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 1;
        requestValue = 0;
        _label1 = @"总有功功率";
        _label2 = @"总无功功率";
        _label3 = @"总视在功率";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn1 isSelected]&&[btn4 isSelected]&&[btn7 isSelected]){
        NSLog(@"一次值,一周,电压");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn7.selected forKey:@"dianya"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:6] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 2;
        requestValue = 0;
        _label1 = @"A相电压";
        _label2 = @"B相电压";
        _label3 = @"C相电压";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn1 isSelected]&&[btn4 isSelected]&&[btn8 isSelected]){
        NSLog(@"一次值,一周,电流");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn8.selected forKey:@"dianliu"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:7] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 3;
        requestValue = 0;
        _label1 = @"A相电流";
        _label2 = @"B相电流";
        _label3 = @"C相电流";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];        }
        
        
    }else if ([btn1 isSelected]&&[btn4 isSelected]&&[btn9 isSelected]){
        NSLog(@"一次值,一周,有功");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn9.selected forKey:@"yougong"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:8] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 4;
        requestValue = 0;
        _label1 = @"A相有功功率";
        _label2 = @"B相有功功率";
        _label3 = @"C相有功功率";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            NSLog(@"aaa");
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn1 isSelected]&&[btn4 isSelected]&&[btn10 isSelected]){
        NSLog(@"一次值,一周,无功");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn10.selected forKey:@"wugong"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults setObject:[NSNumber numberWithInt:9] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 5;
        requestValue = 0;
        _label1 = @"A相无功功率";
        _label2 = @"B相无功功率";
        _label3 = @"C相无功功率";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn1 isSelected]&&[btn5 isSelected]&&[btn6 isSelected]){
        NSLog(@"一次值,两周,总功率");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn6.selected forKey:@"zonggong"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:10] forKey:@"whichOption"];
        [defaults synchronize];
        
        
    }else if ([btn1 isSelected]&&[btn5 isSelected]&&[btn7 isSelected]){
        NSLog(@"一次值,两周,电压");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn6.selected forKey:@"dianya"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:11] forKey:@"whichOption"];
        [defaults synchronize];
       
        
    }else if ([btn1 isSelected]&&[btn5 isSelected]&&[btn8 isSelected]){
        NSLog(@"一次值,两周,电流");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn8.selected forKey:@"dianliu"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:12] forKey:@"whichOption"];
        [defaults synchronize];
        
        
        
    }else if ([btn1 isSelected]&&[btn5 isSelected]&&[btn9 isSelected]){
        NSLog(@"一次值,两周,有功");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn9.selected forKey:@"yougong"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:13] forKey:@"whichOption"];
        [defaults synchronize];
       
        
    }else if ([btn1 isSelected]&&[btn5 isSelected]&&[btn10 isSelected]){
        NSLog(@"一次值,两周,无功");
        [defaults setBool:btn1.selected forKey:@"yici"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn10.selected forKey:@"wugong"];
        [defaults removeObjectForKey:@"liangci"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults setObject:[NSNumber numberWithInt:14] forKey:@"whichOption"];
        [defaults synchronize];
        
    }else if ([btn2 isSelected]&&[btn3 isSelected]&&[btn6 isSelected]){
        NSLog(@"两次值,三天,总功率");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn6.selected forKey:@"zonggong"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:15] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 1;
        requestValue = 1;
        _label1 = @"总有功功率";
        _label2 = @"总无功功率";
        _label3 = @"总视在功率";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn2 isSelected]&&[btn3 isSelected]&&[btn7 isSelected]){
        NSLog(@"两次值,三天,电压");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn7.selected forKey:@"dianya"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"qi "];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:16] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 2;
        requestValue = 1;
        _label1 = @"A相电压";
        _label2 = @"B相电压";
        _label3 = @"C相电压";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn2 isSelected]&&[btn3 isSelected]&&[btn8 isSelected]){
        NSLog(@"两次值,三天,电流");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn8.selected forKey:@"dianliu"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:17] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 3;
        requestValue = 1;
        _label1 = @"A相电流";
        _label2 = @"B相电流";
        _label3 = @"C相电流";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn2 isSelected]&&[btn3 isSelected]&&[btn9 isSelected]){
        NSLog(@"两次值,三天,有功");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn9.selected forKey:@"yougong"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:18] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 4;
        requestValue = 1;
        _label1 = @"A相有功功率";
        _label2 = @"B相有功功率";
        _label3 = @"C相有功功率";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn2 isSelected]&&[btn3 isSelected]&&[btn10 isSelected]){
        NSLog(@"两次值,三天,无功");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn3.selected forKey:@"san"];
        [defaults setBool:btn10.selected forKey:@"wugong"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults setObject:[NSNumber numberWithInt:19] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 5;
        requestValue = 1;
        _label1 = @"A相无功功率";
        _label2 = @"B相无功功率";
        _label3 = @"C相无功功率";
        _days = 3;
        self.timeArr = [self getCurrentTime:3];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn2 isSelected]&&[btn4 isSelected]&&[btn6 isSelected]){
        NSLog(@"两次值,一周,总功率");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn6.selected forKey:@"zonggong"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:20] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 1;
        requestValue = 1;
        _label1 = @"总有功功率";
        _label2 = @"总无功功率";
        _label3 = @"总视在功率";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn2 isSelected]&&[btn4 isSelected]&&[btn7 isSelected]){
        NSLog(@"两次值,一周,电压");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn7.selected forKey:@"dianya"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:21] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 2;
        requestValue = 1;
        _label1 = @"A相电压";
        _label2 = @"B相电压";
        _label3 = @"C相电压";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn2 isSelected]&&[btn4 isSelected]&&[btn8 isSelected]){
        NSLog(@"两次值,一周,电流");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn8.selected forKey:@"dianliu"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:22] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 3;
        requestValue = 1;
        _label1 = @"A相电流";
        _label2 = @"B相电流";
        _label3 = @"C相电流";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn2 isSelected]&&[btn4 isSelected]&&[btn9 isSelected]){
        NSLog(@"两次值,一周,有功");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn9.selected forKey:@"yougong"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults setObject:[NSNumber numberWithInt:23] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 4;
        requestValue = 1;
        _label1 = @"A相有功功率";
        _label2 = @"B相有功功率";
        _label3 = @"C相有功功率";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
        
    }else if ([btn2 isSelected]&&[btn4 isSelected]&&[btn10 isSelected]){
        NSLog(@"两次值,一周,无功");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn4.selected forKey:@"qi"];
        [defaults setBool:btn10.selected forKey:@"wugong"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"shisi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults setObject:[NSNumber numberWithInt:24] forKey:@"whichOption"];
        [defaults synchronize];
        [self initDictionary];
        request_type = 5;
        requestValue = 1;
        _label1 = @"A相无功功率";
        _label2 = @"B相无功功率";
        _label3 = @"C相无功功率";
        _days = 7;
        self.timeArr = [self getCurrentTime:7];
        if ([_sendSocket isConnected]) {
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }else{
            HYScoketManage * manager =[HYScoketManage shareManager];
            [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
            [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:request_type];
        }
        
    }else if ([btn2 isSelected]&&[btn5 isSelected]&&[btn6 isSelected]){
        NSLog(@"两次值,两周,总功率");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn6.selected forKey:@"zonggong"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults synchronize];
        
        
    }else if ([btn2 isSelected]&&[btn5 isSelected]&&[btn7 isSelected]){
        NSLog(@"两次值,两周,电压");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn7.selected forKey:@"dianya"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults synchronize];
       
        
        
    }else if ([btn2 isSelected]&&[btn5 isSelected]&&[btn8 isSelected]){
        NSLog(@"两次值,两周,电流");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn8.selected forKey:@"dianliu"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults synchronize];
       
        
        
    }else if ([btn2 isSelected]&&[btn5 isSelected]&&[btn9 isSelected]){
        NSLog(@"两次值,两周,有功");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn9.selected forKey:@"yougong"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults removeObjectForKey:@"wugong"];
        [defaults synchronize];
       
        
        
    }else if ([btn2 isSelected]&&[btn5 isSelected]&&[btn10 isSelected]){
        NSLog(@"两次值,两周,无功");
        [defaults setBool:btn2.selected forKey:@"liangci"];
        [defaults setBool:btn5.selected forKey:@"shisi"];
        [defaults setBool:btn10.selected forKey:@"wugong"];
        [defaults removeObjectForKey:@"yici"];
        [defaults removeObjectForKey:@"qi"];
        [defaults removeObjectForKey:@"san"];
        [defaults removeObjectForKey:@"dianya"];
        [defaults removeObjectForKey:@"dianliu"];
        [defaults removeObjectForKey:@"yougong"];
        [defaults removeObjectForKey:@"zonggong"];
        [defaults synchronize];
        
    }
    if (_MpLabel) {
        [_MpLabel removeFromSuperview];
    }
    if (self.LineChartView) {
        [self.LineChartView removeFromSuperview];
    }
    
}

#pragma mark --选择
-(void)didClickButtonAtIndex:(NSUInteger)index password:(NSString *)password{
    switch (index) {
        case 101:
            [self cancleView];
            break;
        case 100:
            NSLog(@"查询");
            [self cancleView];
            [SVProgressHUD showWithStatus:@"通讯中..."];
            [self createNewUI];
            break;
        default:
            break;
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
    NSArray *segmentedArray = [NSArray arrayWithObjects:@"列表",@"图像",nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems:segmentedArray];
    segmentedControl.frame = CGRectMake(0, 0, 150, 30.0);
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.tintColor = [UIColor whiteColor];
    [segmentedControl addTarget:self  action:@selector(indexDidChangeForSegmentedControl:)
               forControlEvents:UIControlEventValueChanged];
    
    UIViewController *first = [[UIViewController alloc]init];
    self.first = first;
    first.view.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
    [self addChildViewController:first];
    
    UIViewController *second = [[UIViewController alloc]init];
    self.second = second;
    second.view.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
    [self addChildViewController:second];
    
    [self.navigationItem setTitleView:segmentedControl];
    
    [self.leftButton setImage:[UIImage imageNamed:@"icon_function"] forState:UIControlStateNormal];
    [self.rightButton setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [self setRightButtonClick:@selector(rightButtonClick)];
    [self setLeftButtonClick:@selector(leftButtonClick)];
}


- (void)createTableHead
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W, 30)];
    UILabel *setName = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W/5, 30)];
    setName.text = @"时间";
    [setName setFont:[UIFont systemFontOfSize:11]];
    setName.backgroundColor = RGB(1,127,80);
    [setName setTextColor:[UIColor whiteColor]];
    setName.textAlignment = NSTextAlignmentCenter;
    UILabel *date = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/5, 0, SCREEN_W/5, 30)];
    date.text = @"名称";
    [date setFont:[UIFont systemFontOfSize:11]];
    date.backgroundColor = RGB(1, 127, 80);
    [date setTextColor:[UIColor whiteColor]];
    date.textAlignment = NSTextAlignmentCenter;
    UILabel *tableCode1 = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_W/5)*2, 0, SCREEN_W/5, 30)];
    tableCode1.text = _label1;
    [tableCode1 setFont:[UIFont systemFontOfSize:11]];
    tableCode1.backgroundColor = RGB(1,127,80);
    [tableCode1 setTextColor:[UIColor whiteColor]];
    tableCode1.textAlignment = NSTextAlignmentCenter;
    UILabel *tableCode2 = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_W/5)*3, 0, SCREEN_W/5, 30)];
    tableCode2.text = _label2;
    [tableCode2 setFont:[UIFont systemFontOfSize:11]];
    tableCode2.backgroundColor = RGB(1,127,80);
    [tableCode2 setTextColor:[UIColor whiteColor]];
    tableCode2.textAlignment = NSTextAlignmentCenter;
    UILabel *tableCode3 = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_W/5)*4, 0, SCREEN_W/5, 30)];
    tableCode3.text = _label3;
    [tableCode3 setFont:[UIFont systemFontOfSize:11]];
    tableCode3.backgroundColor = RGB(1,127,80);
    [tableCode3 setTextColor:[UIColor whiteColor]];
    tableCode3.textAlignment = NSTextAlignmentCenter;

    [view addSubview:setName];
    [view addSubview:date];
    [view addSubview:tableCode1];
    [view addSubview:tableCode2];
    [view addSubview:tableCode3];
    [self.first.view addSubview:view];
}

- (void)indexDidChangeForSegmentedControl:(UISegmentedControl *)segmentedControl
{
    if (segmentedControl.selectedSegmentIndex == 0) {
        _indexSegment = 0;
        self.first.view.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
        self.first.view.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.first.view];
        //首先移除表名字label和已创建的折线图
        if (_MpLabel) {
            [_MpLabel removeFromSuperview];
        }
        if (self.LineChartView) {
            [self.LineChartView removeFromSuperview];
        }
        
        
        [self.first didMoveToParentViewController:self];
    }else if (segmentedControl.selectedSegmentIndex == 1){
        self.second.view.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
        self.second.view.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.second.view];
        [self.second didMoveToParentViewController:self];
        _indexSegment = 1;
    
//        [self performSelector:@selector(createChartView) withObject:nil afterDelay:0.0f];
        [self refreshChartView];
    }
}

-(void)getChartViewData{
    int j = 0;
    _dataSourceA = [[NSMutableArray alloc] init];
    _dataSourceB = [[NSMutableArray alloc] init];
    _dataSourceC = [[NSMutableArray alloc] init];
    HYSingleManager * manager = [HYSingleManager sharedManager];
    for (DeviceModel * de in manager.rea_memory_Array) {
        for (DateModel * date in de.dataArr) {
            for (DataModel * data in date.data) {
                switch (request_type) {
                    case 1:
                    {
                        [_dataSourceA addObject:data.total_actPower];
                        [_dataSourceB addObject:data.total_reactPower];
                        [_dataSourceC addObject:data.total_apparentPower];
                        break;
                    }
                    case 2:
                    {
                        [_dataSourceA addObject:data.voltageA];
                        [_dataSourceB addObject:data.voltageB];
                        [_dataSourceC addObject:data.voltageC];
                        break;
                    }
                    case 3:
                    {
                        [_dataSourceA addObject:data.electricA];
                        [_dataSourceB addObject:data.electricB];
                        [_dataSourceC addObject:data.electricC];
                        break;
                    }
                    case 4:
                    {
                        [_dataSourceA addObject:data.activeA];
                        [_dataSourceB addObject:data.activeB];
                        [_dataSourceC addObject:data.activeC];

                        break;
                    }
                    case 5:
                    {
                        [_dataSourceA addObject:data.reactiveA];
                        [_dataSourceB addObject:data.reactiveB];
                        [_dataSourceC addObject:data.reactiveC];
                        break;
                    }
                    default:
                        break;
                }
                
            }
        }
    }
}

- (void)createChartView
{
    [self getChartViewData];
    [self dealChartDataWithFlag:0];
    _MpLabel = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/2-75, 10, 150, 30)];
    [_MpLabel setFont:[UIFont systemFontOfSize:12]];
    _MpLabel.textAlignment = NSTextAlignmentCenter;
    _MpLabel.text = [NSString stringWithFormat:@"%@折线图",_MpName];
    [self.second.view addSubview:_MpLabel];
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_W-60,10, 40, 30)];
    btn.layer.cornerRadius = 5;
    [btn setTitle:@"全屏" forState:UIControlStateNormal];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:13]];
    btn.backgroundColor = RGB(1,127,80);
    [self.second.view addSubview:btn];
    [btn addTarget:self action:@selector(pushSecondController) forControlEvents:UIControlEventTouchUpInside];
    
    //
    if (self.LineChartView) {
        [self.LineChartView removeFromSuperview];
    }
    self.LineChartView = [[LineChartView alloc]initWithFrame:CGRectMake(0, 40, SCREEN_W, SCREEN_H-100)];
    self.LineChartView.delegate = self;
    [self.second.view addSubview:self.LineChartView];
    
    //    self.LineChartView.backgroundColor = RGB(230, 253, 253);
    //设置交互样式
    self.LineChartView.scaleYEnabled = NO;//取消Y轴缩放
    self.LineChartView.doubleTapToZoomEnabled = NO;//取消双击缩放
    self.LineChartView.dragEnabled = YES;//启用拖拽图标
    self.LineChartView.dragDecelerationEnabled = YES;//拖拽后是否有惯性效果
    self.LineChartView.dragDecelerationFrictionCoef = 0.9;//拖拽后惯性效果的摩擦系数(0~1)，数值越小，惯性越不明显
    //    [self.LineChartView zoomWithScaleX:2 scaleY:3 x:2 y:3];
    
    //X轴样式
    ChartXAxis *xAxis = self.LineChartView.xAxis;
    xAxis.axisLineWidth = 1.0/[UIScreen mainScreen].scale;//设置X轴线宽
    xAxis.labelPosition = XAxisLabelPositionBottom;//X轴的显示位置，默认是显示在上面的
    xAxis.drawGridLinesEnabled = YES;//绘制网格线
    xAxis.granularity = 1.0; //间隔
    xAxis.labelRotatedHeight = 10;
    xAxis.labelRotationAngle = 40;
    xAxis.valueFormatter = self;
    //    xAxis.spaceBetweenLabels = 4;//设置label间隔
    //    xAxis.labelTextColor = [self colorWithHexString:@"#057748"];//label文字颜色
    //设置Y轴样式
    self.LineChartView.rightAxis.enabled = NO;//不绘制右边轴
    ChartYAxis *leftAxis = self.LineChartView.leftAxis;//获取左边Y轴
    leftAxis.labelCount = 5;//Y轴label数量，数值不一定，如果forceLabelsEnabled等于YES, 则强制绘制制定数量的label, 但是可能不平均
    leftAxis.forceLabelsEnabled = NO;//不强制绘制指定数量的label
    //    leftAxis.showOnlyMinMaxEnabled = YES;//是否只显示最大值和最小值
    //    leftAxis.axisMinValue = 0;//设置Y轴的最小值
    //    leftAxis.startAtZeroEnabled = YES;//从0开始绘制
    //    leftAxis.axisMaxValue = 105;//设置Y轴的最大值
    leftAxis.inverted = NO;//是否将Y轴进行上下翻转
    leftAxis.axisLineWidth = 1.0/[UIScreen mainScreen].scale;//Y轴线宽
    leftAxis.axisLineColor = [UIColor blackColor];//Y轴颜色
    //    leftAxis.valueFormatter = [[NSNumberFormatter alloc] init];//自定义格式
    //    leftAxis.valueFormatter.positiveSuffix = @" $";//数字后缀单位
    leftAxis.labelPosition = YAxisLabelPositionOutsideChart;//label位置
    //    leftAxis.labelTextColor = [self colorWithHexString:@"#057748"];//文字颜色
    leftAxis.labelFont = [UIFont systemFontOfSize:10.0f];//文字字体
    
    leftAxis.gridLineDashLengths = @[@3.0f, @3.0f];//设置虚线样式的网格线
    leftAxis.gridColor = [UIColor colorWithRed:200/255.0f green:200/255.0f blue:200/255.0f alpha:1];//网格线颜色
    leftAxis.gridAntialiasEnabled = YES;//开启抗锯齿
    
    leftAxis.drawLimitLinesBehindDataEnabled = YES;//设置限制线绘制在折线图的后面
    
    [self.LineChartView setDescriptionText:@""];//折线图描述
    [self.LineChartView setDescriptionTextColor:[UIColor darkGrayColor]];
    self.LineChartView.legend.form = ChartLegendFormLine;//图例的样式
    self.LineChartView.legend.position = ChartLegendPositionAboveChartCenter;//图例位置
    self.LineChartView.legend.formSize = 30;//图例中线条的长度
    self.LineChartView.legend.textColor = [UIColor darkGrayColor];//图例文字颜色
    self.LineChartView.data = [self setDataWithTag1:0 andTag2:0 andTag3:0];
    
    [self addButton];
}

- (void)addButton
{
    //添加按钮
    UIButton * btn1 = [HYExplainManager createButtonWithFrame:CGRectMake(SCREEN_W/2-60-35-35,0, 35 +50, 15) title:nil titleColor:[UIColor greenColor] imageName:nil backgroundImageName:nil target:self selector:@selector(action:)];
    [btn1 addTarget:self action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
    btn1.tag = 666;
    UIButton * btn2 = [HYExplainManager createButtonWithFrame:CGRectMake(SCREEN_W/2-35,0, 35 + 50, 15) title:nil titleColor:[UIColor greenColor] imageName:nil backgroundImageName:nil target:self selector:@selector(action:)];
    btn2.tag = 667;
    UIButton * btn3 = [HYExplainManager createButtonWithFrame:CGRectMake(SCREEN_W/2+60,0, 35 + 50, 15) title:nil titleColor:[UIColor greenColor] imageName:nil backgroundImageName:nil target:self selector:@selector(action:)];
    btn3.tag = 668;
    self.second.view.userInteractionEnabled = YES;
    UILabel * label1 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2-60-35-35, 7, 30, 3)];
    label1.backgroundColor = RGB(255, 238, 0);
    
    UILabel * labelName1 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2-60-35-35+30+5, 0, 47, 14)];
    labelName1.text =_label1;
    labelName1.textColor = [UIColor grayColor];
    labelName1.adjustsFontSizeToFitWidth = YES;
    
    UILabel * label2 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2-35, 7, 30, 3)];
    label2.backgroundColor = RGB(61, 145, 64);
    
    UILabel * labelName2 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2-35+30+5, 0, 47, 14)];
    labelName2.text =  _label2;
    labelName2.textColor = [UIColor grayColor];
    labelName2.adjustsFontSizeToFitWidth = YES;
    
    UILabel * label3 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2+60, 7, 30, 3)];
    label3.backgroundColor = RGB(255, 0, 0);
    
    UILabel * labelName3 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2+60+30+5, 0, 47, 14)];
    labelName3.text = _label3;
    labelName3.textColor = [UIColor grayColor];
    labelName3.adjustsFontSizeToFitWidth = YES;
    
    UIView * backView = [[UIView alloc] initWithFrame:CGRectMake(0, 42, SCREEN_W, 30)];
    backView.backgroundColor = [UIColor whiteColor];
    [self.second.view addSubview:backView];
    [backView addSubview:label1];
    [backView addSubview:labelName1];
    [backView addSubview:label2];
    [backView addSubview:labelName2];
    [backView addSubview:label3];
    [backView addSubview:labelName3];
    [backView addSubview:btn1];
    [backView addSubview:btn2];
    [backView addSubview:btn3];
}

- (void)dealChartDataWithFlag:(NSInteger)flag
{
    NSMutableArray *nameArr = [NSMutableArray array];
    NSMutableArray *mp_IDArr = [NSMutableArray array];
    HYSingleManager *manager = [HYSingleManager sharedManager];
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
    NSMutableArray *aray = [NSMutableArray array];
    for (int i = 0; i<mp_IDArr.count; i++) {
        if ([mp_IDArr[i] isEqualToString:_MpID]) {
            [aray addObject:[NSString stringWithFormat:@"%d",i]];
        }
    }
    int tableNum = 0;//每块表的数据个数
    tableNum = (int)(_dataSourceA.count/nameArr.count);
    if (aray.count == 0) {
        return;
    }
    int mpStart = [aray[0] intValue];
    self.time = [NSMutableArray array];
    self.dataA = [NSMutableArray array];
    self.dataB = [NSMutableArray array];
    self.dataC = [NSMutableArray array];
    if (flag == 0) {
        for (int i = mpStart*tableNum; i<mpStart*tableNum+tableNum; i++) {
            [self.time addObject:_timeArray[i]];
            [self.dataA addObject:_dataSourceA[i]];
            [self.dataB addObject:_dataSourceB[i]];
            [self.dataC addObject:_dataSourceC[i]];
        }
    }else if (flag == 1){
        for (int i = mpStart*tableNum; i<mpStart*tableNum+tableNum; i++) {
            [self.time addObject:_timeArray[i]];
            [self.dataA addObject:_dataSourceA[i]];
        }
    }else if (flag == 2){
        for (int i = mpStart*tableNum; i<mpStart*tableNum+tableNum; i++) {
            [self.time addObject:_timeArray[i]];
            [self.dataB addObject:_dataSourceB[i]];
        }
    }else if (flag == 3){
        for (int i = mpStart*tableNum; i<mpStart*tableNum+tableNum; i++) {
            [self.time addObject:_timeArray[i]];
            [self.dataC addObject:_dataSourceC[i]];
        }
    }

}

- (void)updataChartWithTag1:(NSInteger)tag1 andTag2:(NSInteger)tag2 andTag3:(NSInteger)tag3
{
   self.LineChartView.data = [self setDataWithTag1:tag1 andTag2:tag2 andTag3:tag3];
}

- (void)action:(UIButton *)button
{
    
    switch (button.tag) {
        case 666:
            //按钮1
        {
            if ([button isSelected]) {
                button.selected = NO;
            }else{
                button.selected = YES;
            }
            break;
        }
        case 667:
            //2
        {
            if ([button isSelected]) {
                button.selected = NO;
            }else{
                button.selected = YES;
            }
            break;
        }
        case 668:
            //3
        {
            if ([button isSelected]) {
                button.selected = NO;
            }else{
                button.selected = YES;
            }
            break;
        }
        default:
            break;
    }
    UIButton * btn1 = [self.second.view viewWithTag:666];
    UIButton * btn2 = [self.second.view viewWithTag:667];
    UIButton * btn3 = [self.second.view viewWithTag:668];
    NSInteger tag1,tag2,tag3;
    if ([btn1 isSelected]) {
        tag1 = 1;
    }else{
        tag1 = 0;
    }
    if ([btn2 isSelected]) {
        tag2 = 1;
    }else{
        tag2 = 0;
    }
    if ([btn3 isSelected]) {
        tag3 = 1;
    }else{
        tag3 = 0;
    }
    [self updataChartWithTag1:tag1 andTag2:tag2 andTag3:tag3];
}
- (LineChartData *)setDataWithTag1:(NSInteger) tag1 andTag2:(NSInteger)tag2 andTag3:(NSInteger)tag3
{
    //Y轴数据
    NSMutableArray *yVals1 = [NSMutableArray array];
    NSMutableArray *yVals2 = [NSMutableArray array];
    NSMutableArray *yVals3 = [NSMutableArray array];
    for (int i = 0; i < self.dataA.count; i++) {
        //首先判断第一个是否无效，无效则置为0
        //其次判断其他是否有效，如果无效，就向前取
        double val;
        if ([self.dataA[0] isEqualToString:@"eee.e"]||[self.dataA[0] isEqualToString:@"ee.eeee"]) {
            self.dataA[0] = @"0";
        }
        if ([self.dataA[i] isEqualToString:@"eee.e"]||[self.dataA[i] isEqualToString:@"ee.eeee"]) {
            val = [self.dataA[i-1] doubleValue];
        }else{
            val = [self.dataA[i] doubleValue];
        }
        ChartDataEntry *entry = [[ChartDataEntry alloc] initWithX:i y:val];
        [yVals1 addObject:entry];
    }
    for (int i = 0; i<self.dataB.count; i++) {
        double val;
        if ([self.dataB[0] isEqualToString:@"eee.e"]||[self.dataB[0] isEqualToString:@"ee.eeee"]) {
            self.dataB[0] = @"0";
        }
        if ([self.dataB[i] isEqualToString:@"eee.e"]||[self.dataB[i] isEqualToString:@"ee.eeee"]) {
            val = [self.dataB[i-1] doubleValue];
        }else{
            val = [self.dataB[i] doubleValue];
        }
        
        ChartDataEntry *entry = [[ChartDataEntry alloc] initWithX:i y:val];
        [yVals2 addObject:entry];
    }
    for (int i = 0; i<self.dataC.count; i++) {
        double val;
        if ([self.dataC[0] isEqualToString:@"eee.e"]||[self.dataC[0] isEqualToString:@"ee.eeee"]) {
            self.dataC[0] = @"0";
        }
        if ([self.dataC[i] isEqualToString:@"eee.e"]||[self.dataC[i] isEqualToString:@"ee.eeee"]) {
            val = [self.dataC[i-1] doubleValue];
        }else{
            val = [self.dataC[i] doubleValue];
        }
        
        ChartDataEntry *entry = [[ChartDataEntry alloc] initWithX:i y:val];
        [yVals3 addObject:entry];
    }
    
    LineChartDataSet *set1 = nil;
    LineChartDataSet *set2 = nil;
    LineChartDataSet *set3 = nil;
//    if (self.LineChartView.data.dataSetCount > 0) {
//        LineChartData *data = (LineChartData *)self.LineChartView.data;
//        set1 = (LineChartDataSet *)data.dataSets[0];
//        set1.values = yVals1;
//        set2 = (LineChartDataSet *)data.dataSets[0];
//        set2.values = yVals2;
//        set3 = (LineChartDataSet *)data.dataSets[0];
//        set3.values = yVals3;
//        return data;
//    }else{
        //创建LineChartDataSet对象
        set1 = [[LineChartDataSet alloc] initWithValues:yVals1 label:_label1];
        //设置折线的样式
        set1.lineWidth = 1.0/[UIScreen mainScreen].scale;//折线宽度
        set1.drawValuesEnabled = YES;//是否在拐点处显示数据

        if (tag1 == 1) {
            set1.valueColors = @[[UIColor clearColor]];//折线拐点处显示数据的颜色
            [set1 setColor:RGBA(0, 0, 0, 0)];//折线颜色
        }else{
            set1.valueColors = @[[UIColor yellowColor]];//折线拐点处显示数据的颜色
            [set1 setColor:RGB(255, 238, 0)];//折线颜色
        }
    
        set1.drawSteppedEnabled = NO;//是否开启绘制阶梯样式的折线图
        //折线拐点样式
        set1.drawCirclesEnabled = NO;//是否绘制拐点
        set1.circleRadius = 1.0f;//拐点半径
        set1.circleColors = @[[UIColor redColor], [UIColor greenColor]];//拐点颜色
        //拐点中间的空心样式
        set1.drawCircleHoleEnabled = NO;//是否绘制中间的空心
        set1.circleHoleRadius = 2.0f;//空心的半径
        set1.circleHoleColor = [UIColor blackColor];//空心的颜色
        //折线的颜色填充样式
        //第一种填充样式:单色填充
        //        set1.drawFilledEnabled = YES;//是否填充颜色
        //        set1.fillColor = [UIColor redColor];//填充颜色
        //        set1.fillAlpha = 0.3;//填充颜色的透明度
        //第二种填充样式:渐变填充
        set1.drawFilledEnabled = NO;//是否填充颜色
        NSArray *gradientColors = @[(id)[ChartColorTemplates colorFromString:@"#FFFFFFFF"].CGColor,
                                    (id)[ChartColorTemplates colorFromString:@"#FF007FFF"].CGColor];
        CGGradientRef gradientRef = CGGradientCreateWithColors(nil, (CFArrayRef)gradientColors, nil);
        set1.fillAlpha = 0.3f;//透明度
        set1.fill = [ChartFill fillWithLinearGradient:gradientRef angle:90.0f];//赋值填充颜色对象
        CGGradientRelease(gradientRef);//释放gradientRef
        
        //点击选中拐点的交互样式
        set1.highlightEnabled = NO;//选中拐点,是否开启高亮效果(显示十字线)
        //        set1.highlightLineWidth = 1.0/[UIScreen mainScreen].scale;//十字线宽度
        //        set1.highlightLineDashLengths = @[@5, @5];//十字线的虚线样式
        
        //将 LineChartDataSet 对象放入数组中
        NSMutableArray *dataSets = [[NSMutableArray alloc] init];
        [dataSets addObject:set1];
        
        //添加第二个LineChartDataSet对象
        set2 = [[LineChartDataSet alloc]initWithValues:yVals2 label:_label2];
        [set2 setColor:[UIColor redColor]];
        set2.highlightEnabled = NO;
        set2.drawFilledEnabled = NO;//是否填充颜色
        if (tag2 == 1) {
            set2.valueColors = @[[UIColor clearColor]];//折线拐点处显示数据的颜色
            set2.drawCircleHoleEnabled = NO;//是否绘制中间的空心
            set2.drawCirclesEnabled = NO;//是否绘制拐点
            [set2 setColor:RGBA(0, 0, 0, 0)];//折线颜色
            set2.fillColor = [UIColor clearColor];//填充颜色
            set2.fillAlpha = 0.1;//填充颜色的透明度
            [set2 setColor:[UIColor clearColor]];
        }else{
            set2.valueColors = @[[UIColor greenColor]];//折线拐点处显示数据的颜色
            set2.drawCircleHoleEnabled = NO;//是否绘制中间的空心
            set2.drawCirclesEnabled = NO;//是否绘制拐点
            [set2 setColor:RGB(61, 145, 64)];//折线颜色
            set2.fillColor = [UIColor redColor];//填充颜色
            set2.fillAlpha = 0.1;//填充颜色的透明度

        }
        [dataSets addObject:set2];
        
        set3 = [[LineChartDataSet alloc]initWithValues:yVals3 label:_label3];
        if (tag3 == 1) {
            [set3 setColor:[UIColor clearColor]];
            set3.drawFilledEnabled = NO;//是否填充颜色
            set3.drawCirclesEnabled = NO;//是否绘制拐点
            set3.valueColors = @[[UIColor clearColor]];//折线拐点处显示数据的颜色
            set3.drawCircleHoleEnabled = NO;//是否绘制中间的空心
            set3.highlightEnabled = NO;
            set3.fillColor = [UIColor clearColor];//填充颜色
            set3.fillAlpha = 0.1;//填充颜色的透明度
            [set3 setColor:RGBA(0, 0, 0, 0)];//折线颜色

        }else{
            [set3 setColor:[UIColor redColor]];
            set3.drawFilledEnabled = NO;//是否填充颜色
            set3.drawCirclesEnabled = NO;//是否绘制拐点
            set3.valueColors = @[[UIColor redColor]];//折线拐点处显示数据的颜色
            set3.drawCircleHoleEnabled = NO;//是否绘制中间的空心
            set3.highlightEnabled = NO;
            set3.fillColor = [UIColor redColor];//填充颜色
            set3.fillAlpha = 0.1;//填充颜色的透明度
            [set3 setColor:RGB(255, 0, 0)];//折线颜色
        }
        [dataSets addObject:set3];
    
        //创建 LineChartData 对象, 此对象就是lineChartView需要最终数据对象
        
        LineChartData *data = [[LineChartData alloc] initWithDataSets:dataSets];
        [data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:8.f]];//文字字体
//        [data setValueTextColor:[UIColor grayColor]];//文字颜色
    
        return data;
    

}

- (void)pushSecondController
{
    ChartViewController *chartVC = [[ChartViewController alloc]init];
    chartVC.mpName = _MpName;
    chartVC.mpNameArray = @[_label1,_label2,_label3];
    chartVC.dataA = self.dataA;
    chartVC.dataB = self.dataB;
    chartVC.dataC = self.dataC;
    chartVC.timeArray = self.time;
    [self presentViewController:chartVC animated:NO completion:nil];
}

- (void)leftButtonClick
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)rightButtonClick
{
//    [self initArray];
    [self loadAlertView:@"请选择" contentStr:nil btnNum:2 btnStrArr:[NSArray arrayWithObjects:@"查询",@"关闭",nil] type:15];
}

- (void)loadAlertView:(NSString *)title contentStr:(NSString *)content btnNum:(NSInteger)num btnStrArr:(NSArray *)array type:(NSInteger)typeStr
{
    
    alertView = [[TWLAlertView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W, SCREEN_H)];
    [alertView initWithTitle:title contentStr:content type:typeStr btnNum:num btntitleArr:array];
    alertView.delegate = self;
    UIView *keywindow = [[UIApplication sharedApplication] keyWindow];
    [keywindow addSubview:alertView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DeviceModel * de = _dataSource[section];
    int num = 0;
    for (DateModel * date in de.dataArr) {
        for (DataModel * data in date.data) {
            num ++;
        }
    }
    return num;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _dataSource.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellDentifier = @"usepowercell";
    QueryCell *cell = [tableView dequeueReusableCellWithIdentifier:cellDentifier];
    if (cell == nil) {
        cell = [[QueryCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellDentifier];
    }
    [cell.timeLabel setFont:[UIFont systemFontOfSize:9]];
    DeviceModel * de = _dataSource[indexPath.section];
    DateModel * date = de.dataArr[(indexPath.row ) / 96];
    int num = indexPath.row % 96;
    DataModel * data = date.data[num];
    NSString * label1Data, *label2Data ,* label3Data, * timeString;
    //判断类型选择不同的数据
    switch (request_type) {
        case 1:
            label1Data = data.total_actPower;
            label2Data = data.total_reactPower;
            label3Data = data.total_apparentPower;
            break;
        case 2:
            label1Data = data.voltageA;
            label2Data = data.voltageB;
            label3Data = data.voltageC;
            break;
        case 3:
            label1Data = data.electricA;
            label2Data = data.electricB;
            label3Data = data.electricC;
            break;
        case 4:
            label1Data = data.activeA;
            label2Data = data.activeB;
            label3Data = data.activeC;
            break;
        case 5:
            label1Data = data.reactiveA;
            label2Data = data.reactiveB;
            label3Data = data.reactiveC;
            break;
        default:
            break;
    }
    [cell setNameLabel:data.name timeLabel:data tableCodeLabel1:label1Data tableCodeLabel2:label2Data tableCodeLable3:label3Data andWithRequest_Value:requestValue];
    return cell;
}

//cell的点击事件
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QueryCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //将点击的cell上的信息传递到弹出框(本来想用通知的,但是不知道为什么通知没有传递过去)
    NSDictionary *dict =[[NSDictionary alloc] initWithObjectsAndKeys:cell.timeLabel.text,@"textOne",cell.nameLabel.text,@"textTwo",cell.tableCodeLabel1.text,@"textThree",cell.tableCodeLabel2.text,@"textFour",cell.tableCodeLabel3.text,@"textFive",_label1,@"textSix",_label2,@"textSeven",_label3,@"textEight", nil];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"xiangqing"];
    //点击cell后,过段时间cell自动取消选中
    [self performSelector:@selector(deselect) withObject:nil afterDelay:0.5f];
    [self loadAlertView:@"详情" contentStr:nil btnNum:0 btnStrArr:nil type:16];
}

- (NSString *)stringForValue:(double)value axis:(ChartAxisBase *)axis
{
    return self.time[(int)value % self.time.count];
}


- (void)deselect
{
    [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
