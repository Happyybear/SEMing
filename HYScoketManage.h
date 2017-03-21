//
//  HYScoketManage.h
//  HYSEM
//
//  Created by 王一成 on 2017/2/24.
//  Copyright © 2017年 WGM. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol sendMessage <NSObject>

-(void)sendMessage;

@end

@interface HYScoketManage : NSObject

+(id)shareManager;

//登录，获取用户相关信息
-(void)getNetworkDatawithIP:(NSString *)ipv6Addr withTag:(NSString *)tag;

-(void)writeDataToHostWithL:(NSString *)l;

//用量
-(void)writeDataToHost1;

//状态
- (void)writeDataToHostStatusWithTimeArr:(NSArray *)timeArr WithRequest_type:(int ) request_type;

//validateSocket
- (BOOL)validateSocket;

@property (nonatomic,weak) id delegate;
@end
