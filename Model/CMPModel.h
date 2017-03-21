//
//  CMPModel.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYBaseModel.h"

@interface CMPModel : HYBaseModel

@property (nonatomic,copy) NSString *mp_UI_local;//界面显示位置

@property (nonatomic,copy) NSString *mp_parentType;//所属组上级节点类型

@property (nonatomic,copy) NSString *mp_parentID;//所属组上级节点ID

@property (nonatomic,copy) NSString *mp_setID;//所属组ID

@property (nonatomic,copy) NSString *mp_SIM;//用户SIM

@property (nonatomic,copy) NSString *mp_type;//设备类型type(0:电表  1:无功设备,其他备用)

@property (nonatomic,assign) int mp_point;//所属测量点号

@property (nonatomic,copy) NSString *mp_speedAndPord;//通信速率与端口号

@property (nonatomic,copy) NSString *mp_csType;//通信协议类型

@property (nonatomic,copy) NSString *mp_csAddr;//通信地址

@property (nonatomic,copy) NSString *mp_csPass;//通信密码

@property (nonatomic,assign) int mp_electricNum;//Electric energy rate 电能费率个数

@property (nonatomic,copy) NSString *mp_collectAddr;//所属采集器地址

@property (nonatomic,copy) NSString *mp_waterAddr;//水表地址

@property (nonatomic,assign) int mp_CT;//CT变比

@property (nonatomic,assign) int mp_PT;//PT变比

@property (nonatomic,assign) int MIS_User;//MIS户号

@property (nonatomic,assign) int mp_type1;//电表类型1

@property (nonatomic,assign) int mp_type2;//电表类型2

@property (nonatomic,copy) NSString *table_MAX;//最大表码

@property (nonatomic,copy) NSString *table_StartAndEnd;//起始表码

@property (nonatomic,assign) int lossPress_check;//失压检查

@property (nonatomic,assign) int electric_Percent;//用电差额报警百分比

@property (nonatomic,assign) int electricity_rates;//电费费率

@property (nonatomic,assign) int mp_state;//电表状态

@property (nonatomic,assign) int rated_voltage;//额定电压

@property (nonatomic,assign) int rated_electric;//额定电流

@property (nonatomic,assign) int rated_load;//额定负荷

@property (nonatomic,assign) int meterReading_type;//抄表方案类型

@property (nonatomic,assign) int remain_electric;//剩余电量

@property (nonatomic,assign) int basicCostStandard;//基本费用标准

@property (nonatomic,assign) int basicCostStandard_parameter;//基本费用标准参数

@property (nonatomic,assign) int interest_standard;//利率标准

@property (nonatomic,assign) int region;//地区

@property (nonatomic,assign) int fund_subtotal;//基金小计

@property (nonatomic,assign) int national_water_funds;//国家重大水利基金

@property (nonatomic,assign) int siteToloan;//农网还贷

@property (nonatomic,assign) int additional_urban_public_utilities;//城市公共事业附加

@property (nonatomic,assign) int large_medium_supportFund;//大中型水库移民后期扶持资金

@property (nonatomic,assign) int Local_supportFund;//地方水库移民后期扶持资金

@property (nonatomic,assign) int renewable_energy_electricity_price_attached;//可再生能源电价附加

@property (nonatomic,assign) int site_maintenance;//农网维护费

@property (nonatomic,assign) int demand_MAX;//最大需量

@property (nonatomic,assign) int transformer_capacity;//变压器容量

@property (nonatomic,assign) int tip_period_electricityAll;//尖段电价(含基金及附加)

@property (nonatomic,assign) int peak_period_electricityAll;//峰段电价(含基金及附加)

@property (nonatomic,assign) int flat_period_electricityAll;//平段电价(含基金及附加)

@property (nonatomic,assign) int valley_period_electricityAll;//谷段电价(含基金及附加)

@property (nonatomic,assign) int tip_period_electricity;//尖段电价(不含基金及附加)

@property (nonatomic,assign) int peak_period_electricity;//峰段电价(不含基金及附加)

@property (nonatomic,assign) int flat_period_electricity;//平段电价(不含基金及附加)

@property (nonatomic,assign) int valley_period_electricity;//谷段电价(不含基金及附加)



@property (nonatomic,copy) NSString *tableCode;//表示电表某一时间下表码数据

@property (nonatomic,copy) NSString *time;//查询时间(精确到 年 月 日 时 分)


@end
