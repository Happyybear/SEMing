//
//  HYExplainManager.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYExplainManager : NSObject

+(id)shareManager;


//基本的判断帧格式是否正确
- (unsigned int)GW09_Checkout:(unsigned char*)pBuf :(unsigned int)nLen;

//校验帧是否粘包
- (unsigned int)TSR376_Get_All_frame:(unsigned char*)pBuf :(int)nLen :(unsigned char*)rBuf :(int*)rLen;

//判断AFN
- (unsigned int)TSR376_Get_AFN_Frame:(unsigned char*)pBuf;



-(NSData*)stringToByte:(NSString*)string;


//登录
- (int)TSR376_Get_Land_Fame:(unsigned char *)m_Inaddr :(NSString *)strUsrName :(NSString *)strUsrPW :(unsigned char*)OutBufData;
- (int)TSR376_Analysis_Land_return:(unsigned char *)in_bufer :(int)bufer_len;

//用户信息
- (int)TSR376_GetACK_UsrInfFame:(unsigned char *)m_Inaddr :(UInt64)Usr_ID :(UInt64)Usr_checkID :(unsigned char *)OutBufData;
- (int)TSR376_Analysis_UsrInf:(unsigned char *)in_bufer :(int)bufer_len :(UInt64)Usr_ID :(int)iEnd;

//单位档案
- (int)TSR376_GetACK_CompanyInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID Usr_checkID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData;
- (int)TSR376_Analysis_CompanyInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)Company_ID iEnd:(int)iEnd;

//线路档案
- (int)TSR376_GetACK_LineInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID Line_ID:(UInt64)Line_ID Usr_check_ID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData;
- (int)TSR376_Analysis_LineInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)  Company_ID Line_ID:(UInt64)Line_ID iEnd:(int)iEnd;

//组档案
- (int)TSR376_GetACK_SetInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID Set_ID:(UInt64)Set_ID Usr_CheckID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData;
- (int)TSR376_Analysis_SetInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)Company_ID Set_ID:(UInt64)Set_ID iEnd:(int)iEnd;

//终端档案
- (int)TSR376_GetACK_TerminalInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID Terminal_ID:(UInt64)Terminal_ID Usr_checkID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData;
- (int)TSR376_Analysis_TerminalInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)Company_ID Terminal_ID:(UInt64) Terminal_ID iEnd:(int) iEnd;

//设备档案(测量点信息)
- (int)TSR376_GetACK_MPPowerInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID MPPower_ID:(UInt64)MPPower_ID Usr_check_ID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData;
- (int)TSR376_Analysis_MPPowerInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)Company_ID MPPower_ID:(UInt64)MPPower_ID iEnd:(int)iEnd;

//表码 默认三天
- (int)TSR376_GetACK_TableCodeInfFame:(NSString *)m_Inaddr mp_pointArr:(unsigned int *)mp_pointArr mp_pointNum:(int)mp_pointNum Usr_checkID:(UInt64)Usr_checkID OurBufData:(unsigned char *)OutBufData;
- (int)TSR376_Analysis_TableCodeInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd;


//查询某个终端下所有表的某些时间点的数据
- (int)TSR376_GetACK_TableCodeForHourInfFame:(NSString *)m_Inaddr mp_pointArr:(unsigned int *)mp_pointArr mp_pointNum:(int)mp_pointNum timeArr:(NSArray *)timeArr Usr_checkID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData;
- (int)TSR376_Analysis_TableCodeForHourInfFame:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd With:(NSString *)end;

//查询状态
- (int)TSR376_GetACK_QueryInfFame:(NSString *)m_Inaddr mp_pointArr:(unsigned int *)mp_pointArr mp_pointNum:(int)mp_pointNum timeArr:(NSArray *)timeArr request_type:(int)request_type Usr_checkID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData;
- (int)TSR376_Analysis_QueryInfFame:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd;

//遥控
/**
 *  遥控
 *
 *  @param terminalAddress 终端地址
 *  @param mpAddress       电表地址
 *  Type：动作类型
 *  0：跳闸， 1：合闸，2：报警，3：报警解除，
    4：保电，5：保电解除(这两项功能暂时没有)
 *  @return 返回遥控帧
 */
- (NSData *)combinRemoteControlFrame:(NSString *)terminalAddress :(NSString *)mpAddress :(int)type :(UInt64)Usr_checkID;
/*
 入参：pHostBuf 收到的电表远程控制返回数据帧
 返回：0错误帧
 1确认帧
 2异常返回帧
 */

- (unsigned int)GW09_AnalysisTripControl:(unsigned char*)pHostBuf :(unsigned int)nLen;


//返回表吗数据
@property(nonatomic,copy) void(^getTableCodeData)(NSArray *data);

@property(nonatomic,copy) void(^getUsePowerData)(NSArray *data);

@property(nonatomic,copy) void(^sendUsePowerNextData)(NSArray *data ,unsigned int pn ,NSString * terminal_adress);

//修正错误信息的上一时间点的请求
- (int)TSR376_Analysis_TableCodeForHourInfNextFame:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd With:(NSString *)end;
//解析分段数据
- (int)TSR376_Analysis_TableCodeForHourInfFame:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd;

+(UIButton *)createButtonWithFrame:(CGRect)frame title:(NSString *)title titleColor:(UIColor *)titleColor imageName:(NSString *)imageName backgroundImageName:(NSString *)backgroundImageName target:(id)target selector:(SEL)selector;

@end
