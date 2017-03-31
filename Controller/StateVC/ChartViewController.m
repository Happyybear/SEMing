//
//  ChartViewController.m
//  HYSEM
//
//  Created by xlc on 16/12/6.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "ChartViewController.h"
#import "HYSEM-Bridging-Header.h"

#define SCREEN_WIDTH MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
#define SCREEN_HEIGHT MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width)

@interface ChartViewController ()<ChartViewDelegate,IChartAxisValueFormatter>

@property (nonatomic,strong) LineChartView *LineChartView;

@end

@implementation ChartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.transform = CGAffineTransformMakeRotation(M_PI/2);
    [self createChartView];
    
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}
- (void)createChartView
{
    self.LineChartView = [[LineChartView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH)];
    
    self.LineChartView.delegate = self;
    [self.view addSubview:self.LineChartView];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, 30)];
    nameLabel.text = [NSString stringWithFormat:@"%@折线图",self.mpName];
    [nameLabel setFont:[UIFont systemFontOfSize:12]];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:nameLabel];
    
    self.LineChartView.backgroundColor = RGB(230, 253, 253);
    //设置交互样式
    self.LineChartView.scaleYEnabled = NO;//取消Y轴缩放
    self.LineChartView.doubleTapToZoomEnabled = NO;//取消双击缩放
    self.LineChartView.dragEnabled = YES;//启用拖拽图标
    self.LineChartView.dragDecelerationEnabled = YES;//拖拽后是否有惯性效果
    self.LineChartView.dragDecelerationFrictionCoef = 0.9;//拖拽后惯性效果的摩擦系数(0~1)，数值越小，惯性越不明显
//    [self.LineChartView zoomWithScaleX:1 scaleY:1 x:1 y:1];//用来设置初始化时候的方法倍数
//    [self.LineChartView setVisibleXRangeWithMinXRange:3 maxXRange:10];//用来设置缩放的最大值最小值  换成Y可以设置Y轴
    
    //X轴样式
    ChartXAxis *xAxis = self.LineChartView.xAxis;
    xAxis.axisLineWidth = 1.0/[UIScreen mainScreen].scale;//设置X轴线宽
    xAxis.labelPosition = XAxisLabelPositionBottom;//X轴的显示位置，默认是显示在上面的
    xAxis.drawGridLinesEnabled = YES;//不绘制网格线
    xAxis.granularity = 1.0;
    xAxis.labelRotatedHeight = 10;
    xAxis.labelRotationAngle = 40;
    xAxis.valueFormatter = self;

    //    xAxis.spaceBetweenLabels = 4;//设置label间隔
    //    xAxis.labelTextColor = [self colorWithHexString:@"#057748"];//label文字颜色
    //设置Y轴样式
    self.LineChartView.rightAxis.enabled = NO;//不绘制右边轴
    ChartYAxis *leftAxis = self.LineChartView.leftAxis;//获取左边Y轴
    leftAxis.labelCount = 5;//Y轴label数量，数值不一定，如果forceLabelsEnabled等于YES, 则强制绘制制定数量的label, 但是可能不平均
//    leftAxis.spaceTop = 20;
    leftAxis.forceLabelsEnabled = NO;//不强制绘制指定数量的label
//    leftAxis.spaceTop = 10;
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
    //返回上一页按钮
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_H-50,10, 40, 30)];
    btn.layer.cornerRadius = 5;
    [btn setTitle:@"返回" forState:UIControlStateNormal];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:13]];
    btn.backgroundColor = RGB(1,127,80);
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(pushSecondController) forControlEvents:UIControlEventTouchUpInside];
    [self addButton];
    self.LineChartView.data = [self setDataWithTag1:0 andTag2:0 andTag3:0];
}

- (void)addButton
{
    //添加按钮
    UIButton * btn1 = [HYExplainManager createButtonWithFrame:CGRectMake(SCREEN_W/2-60-35-35,0, 35 +50, 30) title:nil titleColor:[UIColor greenColor] imageName:nil backgroundImageName:nil target:self selector:@selector(action:)];
    [btn1 addTarget:self action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
    btn1.tag = 1666;
    UIButton * btn2 = [HYExplainManager createButtonWithFrame:CGRectMake(SCREEN_W/2-35,0, 35 + 50, 30) title:nil titleColor:[UIColor greenColor] imageName:nil backgroundImageName:nil target:self selector:@selector(action:)];
    btn2.tag = 1667;
    UIButton * btn3 = [HYExplainManager createButtonWithFrame:CGRectMake(SCREEN_W/2+60,0, 35 + 50, 30) title:nil titleColor:[UIColor greenColor] imageName:nil backgroundImageName:nil target:self selector:@selector(action:)];
    btn3.tag = 1668;
    UILabel * label1 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2-60-35-35, 7, 30, 3)];
    label1.backgroundColor = RGB(255, 238, 0);
    
    UILabel * labelName1 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2-60-35-35+30+5, 0, 47, 14)];
    labelName1.text =self.mpNameArray[0];
    labelName1.textColor = [UIColor grayColor];
    labelName1.adjustsFontSizeToFitWidth = YES;
    
    UILabel * label2 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2-35, 7, 30, 3)];
    label2.backgroundColor = RGB(61, 145, 64);
    
    UILabel * labelName2 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2-35+30+5, 0, 47, 14)];
    labelName2.text =  self.mpNameArray[1];
    labelName2.textColor = [UIColor grayColor];
    labelName2.adjustsFontSizeToFitWidth = YES;
    
    UILabel * label3 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2+60, 7, 30, 3)];
    label3.backgroundColor = RGB(255, 0, 0);
    
    UILabel * labelName3 = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W/2+60+30+5, 0, 47, 14)];
    labelName3.text = self.mpNameArray[2];
    labelName3.textColor = [UIColor grayColor];
    labelName3.adjustsFontSizeToFitWidth = YES;
    
    UIView * backView = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_H/2 - SCREEN_W/2, 0, SCREEN_H/2 + SCREEN_W/2 -60, 30)];
    backView.backgroundColor = RGB(230, 253, 253);
    [self.view addSubview:backView];
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

- (void)action:(UIButton *)button
{
    
    switch (button.tag) {
        case 1666:
            //按钮1
        {
            if ([button isSelected]) {
                button.selected = NO;
            }else{
                button.selected = YES;
            }
            break;
        }
        case 1667:
            //2
        {
            if ([button isSelected]) {
                button.selected = NO;
            }else{
                button.selected = YES;
            }
            break;
        }
        case 1668:
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
    UIButton * btn1 = [self.view viewWithTag:1666];
    UIButton * btn2 = [self.view viewWithTag:1667];
    UIButton * btn3 = [self.view viewWithTag:1668];
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

- (void)updataChartWithTag1:(NSInteger)tag1 andTag2:(NSInteger)tag2 andTag3:(NSInteger)tag3
{
    self.LineChartView.data = [self setDataWithTag1:tag1 andTag2:tag2 andTag3:tag3];
}

- (LineChartData *)setDataWithTag1:(NSInteger) tag1 andTag2:(NSInteger)tag2 andTag3:(NSInteger)tag3
{
    //Y轴数据
    NSMutableArray *yVals1 = [NSMutableArray array];
    NSMutableArray *yVals2 = [NSMutableArray array];
    NSMutableArray *yVals3 = [NSMutableArray array];
    for (int i = 0; i < self.dataA.count; i++) {
        //首先判断数据是否有效，如果无效，就向前取
        double val;
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
        set1 = [[LineChartDataSet alloc] initWithValues:yVals1 label:self.mpNameArray[0]];
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
        set2 = [[LineChartDataSet alloc]initWithValues:yVals2 label:self.mpNameArray[1]];
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
        
        set3 = [[LineChartDataSet alloc]initWithValues:yVals3 label:self.mpNameArray[2]];
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
    [self dismissViewControllerAnimated:NO completion:nil];
}

//设置屏幕横屏
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskLandscapeRight;
//}

- (void)dismissView
{
    [self dismissViewControllerAnimated:NO completion:nil];
    
}

- (NSString *)stringForValue:(double)value axis:(ChartAxisBase *)axis
{
    return self.timeArray[(int)value % self.timeArray.count];
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
