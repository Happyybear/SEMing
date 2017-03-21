//
//  AppDelegate.h
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>


@property (strong, nonatomic) UIWindow *window;

@property (nonatomic,retain) MMDrawerController *drawerVC;

- (void)login;

- (void)uninstall;

@end

