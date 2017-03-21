//
//  HYTableCodeViewController.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYTableCodeViewController.h"
#import "MyCell.h"
#import "DeviceModel.h"
#import "DataModel.h"
#import "HYScoketManage.h"
@interface HYTableCodeViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    GCDAsyncSocket *_sendSocket;
    UITableView *_tableView;
    NSMutableData *mData;
    int isAppend;
    int appendLen;
    NSString *ipv6Addr;
    NSArray * code_Data;
    NSMutableArray * display_Data;
}

@property (nonatomic,strong) NSMutableArray *nameArr;

@property (nonatomic,strong) NSMutableArray *timeArr;

@property (nonatomic,strong) NSMutableArray *tableCodeArr;

@end

@implementation HYTableCodeViewController


- (BOOL)shouldAutorotate
{
    return NO;
    //return [self.viewControllers.lastObject shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return  UIInterfaceOrientationPortrait ;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self createNavigition];
    [self initDataSource];
    [self loadData];
    [self createBaseUI];
    [self createSocket];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    manager.tableCode_dict = [NSMutableDictionary dictionary];
    isAppend = 0;
    appendLen = 0;
    mData = [[NSMutableData alloc]init];
}

//初始化数组
- (void)initDataSource
{
    self.nameArr = [NSMutableArray array];
    self.timeArr = [NSMutableArray array];
    self.tableCodeArr = [NSMutableArray array];
    display_Data = [[NSMutableArray alloc] init];
    HYSingleManager * manager = [HYSingleManager sharedManager];
    manager.memory_Array = [NSMutableArray array];
}

- (void)createSocket
{
    HYScoketManage * manager = [HYScoketManage shareManager];
    [manager getNetworkDatawithIP:ipv6Addr withTag:@"4"];
    [SVProgressHUD showWithStatus:@"通讯中..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
}
//创建TableView
- (void)createTableView
{
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0,30,SCREEN_W , SCREEN_H-76) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

/**
 *  tableView代理方法
 */

//设置行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

//分区个数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    return 1;

    return display_Data.count;
}

//每个分区行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    HYSingleManager *manager = [HYSingleManager sharedManager];
    
    NSArray *allKeys = [manager.tableCode_dict allKeys];
    
    NSArray *value = [manager.tableCode_dict allValues][0];
    
//    return allKeys.count*value.count;
    DeviceModel *model = display_Data[section];
    return model.dataArr.count;
}

#pragma mark --3D
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
    [UIView animateWithDuration:1 animations:^{
        cell.layer.transform = CATransform3DMakeScale(1, 1, 1);
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellDentifier = @"cell";
    MyCell *cell = [tableView dequeueReusableCellWithIdentifier:cellDentifier];
    if (cell == nil) {
        cell = [[MyCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellDentifier];
    }
    
    //设置timeLabel字体大小
    [cell.timeLabel setFont:[UIFont systemFontOfSize:11]];
    
    DeviceModel *model = display_Data[indexPath.section];
    DataModel * dataModel = model.dataArr[indexPath.row];
//    [cell setNameLabel:self.nameArr[indexPath.row] timeLabel:self.timeArr[indexPath.row] tableCodeLabel:self.tableCodeArr[indexPath.row]];
    [cell setCellWithModel:dataModel];
    return cell;
}

//获取名字、时间、表码
#pragma mark --getData
- (void)GetDataSource
{
    HYSingleManager * manager = [HYSingleManager sharedManager];
    display_Data = manager.memory_Array;
    [self createTableView];
}


-(void) loadData{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GetDataSource) name:@"getTableCodeData" object:nil];
}

- (void)createNavigition
{
    self.titleLabel.text = @"表码分析";
    [self.leftButton setImage:[UIImage imageNamed:@"icon_function"] forState:UIControlStateNormal];
    [self setLeftButtonClick:@selector(leftButtonClick)];
    [self.rightButton setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [self setRightButtonClick:@selector(rightButtonClick)];
    
}

//创建baseUI
- (void)createBaseUI
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W, 30)];
    UILabel *setName = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W/3, 30)];
    setName.text = @"名称";
    [setName setFont:[UIFont systemFontOfSize:12]];
    [setName setTextColor:[UIColor whiteColor]];
    setName.backgroundColor = RGB(1,127,80);
    setName.textAlignment = NSTextAlignmentCenter;
    UILabel *date = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_W/3, 0, SCREEN_W/3, 30)];
    date.text = @"日期";
    [date setFont:[UIFont systemFontOfSize:12]];
    [date setTextColor:[UIColor whiteColor]];
    date.backgroundColor = RGB(67,205, 128);
    date.textAlignment = NSTextAlignmentCenter;
    UILabel *tableCode = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_W/3)*2, 0, SCREEN_W/3, 30)];
    tableCode.text = @"正向有功总";
    [tableCode setFont:[UIFont systemFontOfSize:12]];
    [tableCode setTextColor:[UIColor whiteColor]];
    tableCode.backgroundColor = RGB(1,127,80);
    tableCode.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:view];
    [view addSubview:setName];
    [view addSubview:date];
    [view addSubview:tableCode];
}


- (void)leftButtonClick
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)rightButtonClick
{
    HYSingleManager *manager = [HYSingleManager sharedManager];
    manager.tableCode_dict = [NSMutableDictionary dictionary];
    manager.memory_Array = [NSMutableArray array];
    HYScoketManage * manager1 = [HYScoketManage shareManager];
    [manager1 getNetworkDatawithIP:SocketHOST withTag:@"4"];
    [SVProgressHUD showSuccessWithStatus:@"正在请求表码"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_sendSocket disconnect];
    _sendSocket = nil;
}

//获取当前时间
- (NSInteger)getCurrentDate
{
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY/MM/dd/HH/mm"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    NSArray *arr = [dateString componentsSeparatedByString:@"/"];// '/'分割日期字符串,得到一数组
    NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1lx",(long)[arr[3] integerValue]]];
    UInt64 currentHour = strtoull([hexString UTF8String], 0, 16);
    NSInteger current = (NSInteger)(currentHour);
    return current;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
