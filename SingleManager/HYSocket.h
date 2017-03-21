//
//  HYSocket.h
//  HYSEM
//
//  Created by xlc on 16/11/21.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYSocket : NSObject

+(instancetype)shareZheartBeatSocket;
- (void)initZheartBeatSocket;//创建单例内部的GCDAsyncSocket
- (void)runTimerWhenAppEnterBackGround;//如果需要在APP进入后台开启NSTimer

@end
