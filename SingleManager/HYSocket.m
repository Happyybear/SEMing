//
//  HYSocket.m
//  HYSEM
//
//  Created by xlc on 16/11/21.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYSocket.h"

@interface HYSocket()<GCDAsyncSocketDelegate>
{
    GCDAsyncSocket *_asyncSocket;
    NSString *_getStr;
    BOOL _isInContentPerform;
}

@property (nonatomic, retain) NSTimer *connectTimer; // 计时器

@end

@implementation HYSocket

//单例
+ (instancetype)shareZheartBeatSocket
{
    static dispatch_once_t onceToken;
    static HYSocket *instance;
    dispatch_once(&onceToken, ^{
        instance = [[HYSocket alloc]init];
    });
    return instance;
}

//初始化 GCDAsyncSocket
- (void)initZheartBeatSocket{
    [self creatSocket];
    
    //注册APP退到后台，之后每十分钟发送的通知，与VOIP无关，由于等待时间必须大于600s，不使用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(creatSocket) name:@"CreatGcdSocket" object:nil];
}

//INT_MAX 最大时间链接,心跳必须!
- (void)creatSocket
{
    if (_asyncSocket == nil||[_asyncSocket isDisconnected]) {
        //初始化 GCDAsyncSocket
        _asyncSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_asyncSocket enableBackgroundingOnSocket];
        
        NSError *error = nil;
        if (![_asyncSocket connectToHost:SocketHOST onPort:SocketonPort withTimeout:INT_MAX error:&error]) {
            //socket通讯已经链接
        }
    }else{
        //读取socket通讯内容
        [_asyncSocket readDataWithTimeout:INT_MAX tag:0];
        //编写Socket通讯提交服务器
        NSString *inputMsgStr = [NSString stringWithFormat:@"客户端收到%@",_getStr];
        NSString * content = [inputMsgStr stringByAppendingString:@"\r\n"];
        NSData *data = [content dataUsingEncoding:NSISOLatin1StringEncoding];
        [_asyncSocket writeData:data withTimeout:INT_MAX tag:0];
        
        [self heartbeat];
    }
}

- (void)heartbeat
{
    /*
     *此处是一个心跳请求链接（自己的服务器），Timeout时间随意
     */
    NSLog(@"heart live-----------------");
}

#pragma mark - <GCDasyncSocketDelegate>
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    [_asyncSocket disconnect];
    [_asyncSocket disconnectAfterReading];
    [_asyncSocket disconnectAfterWriting];
    [_asyncSocket disconnectAfterReadingAndWriting];
    // 服务器掉线，重连（不知道为什么我们的服务器每两分钟重连一次），必须添加
    if (!_isInContentPerform) {
        _isInContentPerform = YES;
        [self performSelector:@selector(perform) withObject:nil afterDelay:2];
    }
}

- (void)perform{
    _isInContentPerform = NO;
    //_asyncSocket  = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    [_asyncSocket connectToHost:SocketHOST onPort:SocketonPort withTimeout:INT_MAX error:&error];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    [self creatSocket];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //接收到消息。
    _getStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //读取消息
    [self creatSocket];
}

#pragma mark - <可选接入，当服务器退入后台启动timer,包括之前所有的>
- (void)runTimerWhenAppEnterBackGround{
    // 每隔30s像服务器发送心跳包
    if (self.connectTimer == nil) {
        self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(heartbeat) userInfo:nil repeats:YES];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:self.connectTimer forMode:NSDefaultRunLoopMode];
    }
    [self.connectTimer fire];
    
    //配置所有添加RunLoop后台的NSTimer可用!
    UIApplication* app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask;
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(),^{
            if(bgTask != UIBackgroundTaskInvalid){
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if(bgTask != UIBackgroundTaskInvalid){
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    });
}

@end
