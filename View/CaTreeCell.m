//
//  CaTreeCell.m
//  SEM
//
//  Created by xlc on 16/11/2.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import "CaTreeCell.h"
#import "CaTreeModel.h"

@implementation CaTreeCell
{
    Node *node1;
}

static NSMutableArray * dataArrary;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _btnArr = [NSMutableArray new];
    }
    return self;
}

- (void)UI
{
    _view = [[UIView alloc]init];
    [self createButton];
    [self.contentView addSubview:_view];
    if (_btn.selected) {
        [_btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_10"] forState:UIControlStateNormal];
    }else{
        [_btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_11"] forState:UIControlStateNormal];
    }
    [_btn addTarget:self action:@selector(btnSection) forControlEvents:UIControlEventTouchUpInside];
    self.label = [[UILabel alloc]initWithFrame:CGRectMake(40, 10, SCREEN_W-40, 20)];
//    [_view addSubview:self.btn];
    [_view addSubview:_label];
    self.btn.frame = CGRectMake(10, 10, 20, 20);
}

- (void)createButton{
    dataArrary = [[NSMutableArray alloc] initWithObjects:_tempData, nil];
    NSLog(@"%d",dataArrary.count);
    for (Node * node in _tempData) {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.selected = NO;
        if (btn.selected) {
            [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_10"] forState:UIControlStateNormal];
        }else{
            [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_11"] forState:UIControlStateNormal];
        }
        btn.frame = CGRectMake(10, 10, 20, 20);
        [btn setIntFlag:(node.nodeId + 201212)];
        [_btnArr addObject:btn];
    }
}

- (void)btnSection
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (_btn.selected) {
        _btn.selected = NO;
        [_btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_11"] forState:UIControlStateNormal];
        CaTreeModel *model = [[CaTreeModel alloc]init];
        model.node = node1;
        model.selected = NO;
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"selected" object:nil];
        [defaults removeObjectForKey:@"mpID"];
        
        
        int level = 0;
        for (Node * node in _tempData) {
            if (node.nodeId == _btn.intFlag - 201212) {
                level = node.depth;
            }
        }
        [self btnActionWith:NO andButton:_btn andLevel:level];
        self.bthClick();
    }else{
        _btn.selected = YES;
        [_btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_10"] forState:UIControlStateNormal];
        CaTreeModel *model = [[CaTreeModel alloc]init];
        model.node = node1;
        model.selected = YES;
        int level = 0;
        for (Node * node in _tempData) {
            if (node.nodeId == _btn.intFlag - 201212) {
                level = node.depth;
            }
        }
        if (level == 3) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"selected" object:model];
            [defaults setObject:model.node.MpID forKey:@"mpID"];
        }
        [self btnActionWith:YES andButton:_btn andLevel:level];
        self.bthClick();
    }
    [defaults synchronize];
}

- (void)refreshWithNode:(Node *)node
{
    node1 = node;
    [_label setFont:[UIFont systemFontOfSize:14]];
    _label.text = node.name;
    _view.frame = CGRectMake(30 * node.depth,0,[[UIScreen mainScreen] bounds].size.width , 40);
    NSMutableArray * arr = [HY_NSusefDefaults objectForKey:@"BTN"];
    for (int i = 0; i < _btnArr .count; i++ ) {
        UIButton * btn = _btnArr[i];
        if (arr.count> 0) {
            btn.selected = [arr[i] intValue];
        }
        if (btn.intFlag == 201212 + node.nodeId) {
            if (_btn) {
                [_btn removeFromSuperview];
            }
            _btn = btn;
            [_view addSubview:_btn];
            _btn.frame = CGRectMake(10, 10, 20, 20);
            [_btn addTarget:self action:@selector(btnSection) forControlEvents:UIControlEventTouchUpInside];
            if (_btn.selected) {
                [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_10"] forState:UIControlStateNormal];
            }else{
                [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_11"] forState:UIControlStateNormal];
            }
        }
    }
}


-(void)btnActionWith:(BOOL) flag1 andButton:(UIButton *) btn andLevel:(int ) level{
    BOOL flag = YES;
    flag = flag1;
    //level 3
    switch (level) {
        case 0:
            //0
            for (Node * node in _tempData) {
                for (UIButton * button in _btnArr) {
                    if ((button.intFlag -201212) == node.nodeId && node.parentId == (btn.intFlag -201212)) {
                        if (node.depth == 1) {
                            button.selected = flag;
                            [self btnActionWith:flag1 andButton:button andLevel:1];
                        }
                    }
                }
            }
            break;
        case 1:
            //1
            for (Node * node in _tempData) {
                for (UIButton * button in _btnArr) {
                    if ((button.intFlag -201212) == node.nodeId) {
                        if (node.depth == 2 && node.parentId == (btn.intFlag -201212)) {
                            button.selected = flag;
                            [self btnActionWith:flag1 andButton:button andLevel:2];
                        }
                    }
                }
            }
            break;
        case 2:
            //2
            for (Node * node in _tempData) {
                for (UIButton * button in _btnArr) {
                    if ((button.intFlag -201212) == node.nodeId) {
                        if (node.depth == 3 && node.parentId == (btn.intFlag -201212)) {
                            button.selected = flag;
//                            [self btnActionWith:flag1 andButton:button andLevel:3];
                        }
                    }
                }
            }
            break;
        case 3:
            for (Node * node in _tempData) {
                for (UIButton * button in _btnArr) {
                    if (node.depth == 3 && (button.intFlag - 201212) == node.nodeId) {
                        if ((btn.intFlag - 201212) == node.nodeId && btn.intFlag == button.intFlag)
                        {
                            button.selected = flag;
                        }else{
                            if (flag) {
                                button.selected = !flag;
                            }
                        }
                    }
                }
            }

            break;
            
        default:
            break;
    }
    NSMutableArray * btnTagArr = [[NSMutableArray alloc] init];
    for (UIButton * btn in _btnArr) {
        if (btn.selected) {
            [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_10"] forState:UIControlStateNormal];
        }else{
            [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_11"] forState:UIControlStateNormal];
        }
        NSInteger tag = btn.selected;
        [btnTagArr addObject:[NSString stringWithFormat:@"%ld",tag]];
    }
    [HY_NSusefDefaults setObject:btnTagArr forKey:@"BTN"];
    [HY_NSusefDefaults synchronize];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
