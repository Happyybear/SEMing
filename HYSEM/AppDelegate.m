//
//  AppDelegate.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "AppDelegate.h"
#import "HYSocket.h"

@interface AppDelegate ()
{
    HYSocket *_socket;
}

@property (nonatomic,strong) HYRootViewController *rootVC;
@property (nonatomic,strong) HYLoginViewController *loginVC;


@end

@implementation AppDelegate


- (BOOL)shouldAutorotate
{
    return NO;
    
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return  UIInterfaceOrientationPortrait ;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [self judgeExpired];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLogin"])
    {
        //已登陆，直接进入主页面
        [self login];
        
    }else{
        //否则，进入Login页面
        [self login];
        
    }
    
    [self.window makeKeyWindow];
    return YES;
}

-(void)judgeExpired
{
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh"];
    NSString *date = [dateFormatter stringFromDate:currentDate];
    NSInteger time = [date integerValue] - [[[NSUserDefaults standardUserDefaults] objectForKey:@"date"] integerValue];
    if (time >= 0) {
        //[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"AutoLogin"];
        //NSLog(@"%ld...%@",(long)time,[[NSUserDefaults standardUserDefaults] objectForKey:@"date"]);
    }
}

#pragma mark-  login
- (void)login
{
    HYLoginViewController *login = [[HYLoginViewController alloc] init];
    self.window.rootViewController = login;
    //block
    login.block = ^{
        [self createRootViewController];
    };
}

- (void)uninstall{
    self.window.rootViewController = nil;
}
#pragma mark-  首页
- (void)createRootViewController
{
    self.rootVC = [[HYRootViewController alloc]init];
    HYLeftViewController *leftVC = [[HYLeftViewController alloc]init];
    _drawerVC = [[MMDrawerController alloc]initWithCenterViewController:self.rootVC leftDrawerViewController:leftVC];
    _drawerVC.openDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
    _drawerVC.closeDrawerGestureModeMask = MMCloseDrawerGestureModeAll;
    self.window.rootViewController = _drawerVC;
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    //进入后台,之后每10分钟发一次通知
    [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateGcdSocket" object:nil userInfo:nil];
        //如果需要添加NSTimer
    }];
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
