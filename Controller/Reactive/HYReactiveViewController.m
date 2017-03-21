//
//  HYReactiveViewController.m
//  HYSEM
//
//  Created by 王广明 on 2016/12/30.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYReactiveViewController.h"
#import "MyCell.h"
#import "CaTreeModel.h"
#import "HYScoketManage.h"
#import "DeviceModel.h"
#import "DataModel.h"
#import "DateModel.h"
@interface HYReactiveViewController ()<TWlALertviewDelegate,UITableViewDelegate,UITableViewDataSource>
{
    GCDAsyncSocket *_sendSocket;
    NSString *ipv6Addr;
    int isAppend;//区分粘包
    NSMutableData *mData;
    int appendLen;
    int _days;
    TWLAlertView *alertView;
    NSMutableArray *_dataSource;//数据数组
    NSMutableArray *_timeArray;//时间数组
    NSMutableArray *_nameArray;//名字数组
}

@property (nonatomic,strong) NSMutableArray *timeArr;

@property (nonatomic,strong) UITableView *tableView;


@end

@implementation HYReactiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    HYSingleManager *manager = [HYSingleManager sharedManager];
    manager.memory_Array = [[NSMutableArray alloc] init];
    if (manager.user.user_type == 4) {
        //提示升级
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [UIView addMJNotifierWithText:@"对不起,权限不足!" dismissAutomatically:NO];
    }else{
        //点击表的通知
        [self createTableView];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clickMp:) name:@"selected" object:nil];
        [self loadData];
        [self createBaseUI];
        [self initDict];
        [self initData];
        isAppend = 0;
        appendLen = 0;
        mData = [NSMutableData data];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [self createLastSearchUI];
    }
    self.titleLabel.text = @"无功分析";
}

- (void)initData{
    _dataSource = [NSMutableArray array];
    _timeArray = [NSMutableArray array];
    _nameArray = [NSMutableArray array];
}
- (void)clickMp:(NSNotification *)notification
{
    CaTreeModel *model = [notification object];
    if (model == nil) {
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
        [self refreshTableView:mp_IDArr[0] :nameArr[0]];
    }else{
        
        [self refreshTableView:model.node.MpID :model.node.name];
    }
}

- (void)refreshTableView:(NSString *)mpID :(NSString *)mpName
{
    //首先初始化数组并移除原来的tableView
    [_tableView removeFromSuperview];
    _dataSource = [NSMutableArray array];
    _timeArray = [NSMutableArray array];
    _nameArray = [NSMutableArray array];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    NSDictionary *dict = manager.powerFactor_dict[mpID];
    for (int k = _days-1; k>=0; k--) {
        NSArray *array = dict[[NSString stringWithFormat:@"%d",k]];
        for (int n = 0; n<array.count; n++) {
            [_dataSource addObject:[NSString stringWithFormat:@"%@",array[n]]];
        }
    }
    //时间
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
    for (int j = 0; j<a.count; j++) {
        [_timeArray addObject:a[j]];
    }
    //表名字
    for (int i = 0; i<_timeArray.count; i++) {
        [_nameArray addObject:mpName];
    }
}

- (void)createLastSearchUI
{
    [self loadData];
    HYSingleManager * manager1 = [HYSingleManager sharedManager];
    manager1.memory_Array = [[NSMutableArray alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *number = [defaults objectForKey:@"whichBtn"];
    NSString *string = [NSString stringWithFormat:@"%@",number];
    HYScoketManage * manager = [HYScoketManage shareManager];
    if ([self isBlankString:string]) {
        _days = 1;
        self.timeArr = [self getCurrentTime:_days];
        [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
        [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:6];
    }else{
        int value = [number intValue];
        switch (value) {
            case 0:
            {
                _days = 1;
                self.timeArr = [self getCurrentTime:_days];
                [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
                [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:6];
                break;
            }
            case 1:
            {
                _days = 3;
                self.timeArr = [self getCurrentTime:_days];
                [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
                [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:6];
                break;
            }
            case 2:
            {
                _days = 7;
                self.timeArr = [self getCurrentTime:_days];
                [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
                [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:6];
                break;
            }
            default:
                break;
        }
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

- (void)initDict
{
    HYSingleManager *manager = [HYSingleManager sharedManager];
    manager.powerFactor_dict = [NSMutableDictionary dictionary];
    manager.memory_Array = [[NSMutableArray alloc] init];
    self.timeArr = [NSMutableArray array];
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
    tableCode.text = @"功率因数";
    [tableCode setFont:[UIFont systemFontOfSize:12]];
    tableCode.backgroundColor = RGB(1,127,80);
    [tableCode setTextColor:[UIColor whiteColor]];
    tableCode.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:view];
    [view addSubview:setName];
    [view addSubview:date];
    [view addSubview:tableCode];

    [self.rightButton setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [self setRightButtonClick:@selector(rightButtonClick)];
    [self.leftButton setImage:[UIImage imageNamed:@"icon_function"] forState:UIControlStateNormal];
    [self setLeftButtonClick:@selector(leftButtonClick)];
}

- (void)leftButtonClick
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)loadData{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createDataSource) name:@"getStatusData" object:nil];
}

- (void)createDataSource
{
    [self initData];
    HYSingleManager * manager = [HYSingleManager sharedManager];
    _dataSource = manager.memory_Array;
    [SVProgressHUD showSuccessWithStatus:@"通讯成功"];
    [SVProgressHUD dismiss];
    //功率因数
    NSMutableArray *nameArr = [NSMutableArray array];
    NSMutableArray *mp_IDArr = [NSMutableArray array];
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
    
    
    //时间
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
    
    for (int i = 0; i<nameArr.count; i++) {
        for (int j = 0; j<a.count; j++) {
            [_timeArray addObject:a[j]];
        }
    }
    
    //表名字数组
    for (int i = 0; i<nameArr.count; i++) {
        for (int j = 0; j<a.count; j++) {
            [_nameArray addObject:nameArr[i]];
        }
    }
    [_tableView reloadData];
}


- (void)createTableView
{
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 30, SCREEN_W, SCREEN_H) style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

//TableView代理方法
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

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellDentifier = @"powerFactorcell";
    MyCell *cell = [tableView dequeueReusableCellWithIdentifier:cellDentifier];
    if (cell == nil) {
        cell = [[MyCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellDentifier];
    }
    
    //设置timeLabel字体大小
    [cell.timeLabel setFont:[UIFont systemFontOfSize:11]];
    DeviceModel * de = _dataSource[indexPath.section];
    DateModel * date = de.dataArr[(indexPath.row ) / 96];
    int num = indexPath.row % 96;
    DataModel * data = date.data[num];
    NSString * label1Data, *label2Data ,* label3Data, * timeString;
    label1Data =data.powerFactor;
    [cell setNameLabel:data.name timeLabel:_timeArray[indexPath.row] tableCodeLabel:label1Data];
    
    if ([label1Data floatValue] < 0.9) {
        cell.tableCodeLabel.textColor = [UIColor redColor];
        cell.nameLabel.textColor = [UIColor redColor];
        cell.timeLabel.textColor = [UIColor redColor];
    }else{
        cell.tableCodeLabel.textColor = [UIColor blackColor];
        cell.nameLabel.textColor = [UIColor blackColor];
        cell.timeLabel.textColor = [UIColor blackColor];
    }
    
    return cell;

}

- (void)rightButtonClick
{
    [self loadAlertView:@"请选择" contentStr:nil btnNum:2 btnStrArr:[NSArray arrayWithObjects:@"查询",@"关闭",nil] type:18];
}

- (void)loadAlertView:(NSString *)title contentStr:(NSString *)content btnNum:(NSInteger)num btnStrArr:(NSArray *)array type:(NSInteger)typeStr
{
    
    UIButton *btn1 = (UIButton *)[alertView viewWithTag:777];
    UIButton *btn2 = (UIButton *)[alertView viewWithTag:778];
    UIButton *btn3 = (UIButton *)[alertView viewWithTag:779];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"powerFactorTerday"]) {
        btn1.selected = YES;
    }else if ([defaults boolForKey:@"powerFactorThree"]){
        btn2.selected = YES;
    }else if ([defaults boolForKey:@"powerFactorSeven"]){
        btn3.selected = YES;
    }
    
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
            NSLog(@"查询");
            [self cancleView];
            [SVProgressHUD showWithStatus:@"通讯中..."];
            [self createNewUI];
            break;
        default:
            break;
    }
}

- (void)createNewUI
{
    UIButton *btn1 = (UIButton *)[alertView viewWithTag:777];//当天
    UIButton *btn2 = (UIButton *)[alertView viewWithTag:778];//三天
    UIButton *btn3 = (UIButton *)[alertView viewWithTag:779];//一周
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    HYScoketManage * manager = [HYScoketManage shareManager];
    if ([btn1 isSelected]) {
        //当天
        [defaults setBool:btn1.selected forKey:@"powerFactorTerday"];
        [defaults removeObjectForKey:@"powerFactorThree"];
        [defaults removeObjectForKey:@"powerFactorSeven"];
        [defaults setObject:[NSNumber numberWithInt:0] forKey:@"whichBtn"];
        [defaults synchronize];
        [self initDict];
        _days = 1;
        self.timeArr = [self getCurrentTime:_days];
        [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
        [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:6];
    }else if ([btn2 isSelected]){
        //三天
        [defaults setBool:btn2.selected forKey:@"powerFactorThree"];
        [defaults removeObjectForKey:@"powerFactorTerday"];
        [defaults removeObjectForKey:@"powerFactorSeven"];
        [defaults setObject:[NSNumber numberWithInt:1] forKey:@"whichBtn"];
        [defaults synchronize];
        [self initDict];
        _days = 3;
        self.timeArr = [self getCurrentTime:_days];
        [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
        [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:6];
    }else if ([btn3 isSelected]){
        //一周
        [defaults setBool:btn3.selected forKey:@"powerFactorSeven"];
        [defaults removeObjectForKey:@"powerFactorThree"];
        [defaults removeObjectForKey:@"powerFactorTerday"];
        [defaults setObject:[NSNumber numberWithInt:2] forKey:@"whichBtn"];
        [defaults synchronize];
        [self initDict];
        _days = 7;
        self.timeArr = [self getCurrentTime:_days];
        [manager getNetworkDatawithIP:ipv6Addr withTag:@"3"];
        [manager writeDataToHostStatusWithTimeArr:self.timeArr WithRequest_type:6];
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

- (void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getStatusData" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
