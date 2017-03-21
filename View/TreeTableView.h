//
//  TreeTableView.h
//  SEM
//
//  Created by xlc on 16/7/27.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Node;

@protocol TreeTableCellDelegate <NSObject>

- (void)cellClick:(Node *)node;

@end

@interface TreeTableView : UITableView

@property (nonatomic,weak) id<TreeTableCellDelegate> treeTableCellDelegate;

- (instancetype)initWithFrame:(CGRect)frame withData:(NSArray *)data;


@end
