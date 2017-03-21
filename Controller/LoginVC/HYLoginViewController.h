//
//  HYLoginViewController.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYBaseViewController.h"
#import "GCDAsyncSocket.h"

@interface HYLoginViewController : HYBaseViewController

@property (nonatomic,strong) GCDAsyncSocket *sendSocket;

@property (nonatomic,copy) void(^block)();


@end
