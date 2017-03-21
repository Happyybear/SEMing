//
//  TreeTableView.m
//  SEM
//
//  Created by xlc on 16/7/27.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import "TreeTableView.h"
#import "Node.h"
#import "CaTreeCell.h"

@interface TreeTableView ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic , strong) NSArray *data;//传递过来已经组织好的数据（全量数据）

@property (nonatomic , strong) NSMutableArray *tempData;//用于存储数据源（部分数据）

@property (nonatomic , strong) NSMutableArray *btnArr;//用于存储数据源（部分数据）

@end

@implementation TreeTableView

-(instancetype)initWithFrame:(CGRect)frame withData : (NSArray *)data{
    _tempData = [[NSMutableArray alloc]init];
    self = [super initWithFrame:frame style:UITableViewStylePlain];
    if (self) {
        self.dataSource = self;
        self.delegate = self;
        _data = data;
        _btnArr = [NSMutableArray new];
        _tempData = [self createTempData:data];
        [self createButton];
    }
    return self;
}

/**
 * 初始化数据源
 */
-(NSMutableArray *)createTempData : (NSArray *)data{
    NSMutableArray *tempArray = [NSMutableArray array];
    for (int i=0; i<data.count; i++) {
        Node *node = [_data objectAtIndex:i];
        if (node.expand) {
            [tempArray addObject:node];
        }
    }
    return tempArray;
}


#pragma mark - UITableViewDataSource

#pragma mark - Required

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _tempData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *NODE_CELL_ID = @"node_cell_id";
    CaTreeCell *cell = [tableView dequeueReusableCellWithIdentifier:NODE_CELL_ID];
    cell = [[CaTreeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NODE_CELL_ID];
    cell.tempData = _tempData;
    cell.dataSource = _data;
    [cell UI];
    Node *node = [_tempData objectAtIndex:indexPath.row];
    // cell有缩进的方法
    //cell.indentationLevel = node.depth; // 缩进级别
    //cell.indentationWidth = 30.f; // 每个缩进级别的距离
    cell.selectionStyle = UITableViewCellAccessoryNone;
    cell.bthClick = ^(){
        [self reloadData];
    };

    [cell refreshWithNode:node];
    return cell;
}


#pragma mark - Optional
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}


#pragma mark - UITableViewDelegate

#pragma mark - Optional
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //先修改数据源
    Node *parentNode = [_tempData objectAtIndex:indexPath.row];
    if (_treeTableCellDelegate && [_treeTableCellDelegate respondsToSelector:@selector(cellClick:)]) {
        [_treeTableCellDelegate cellClick:parentNode];
    }
    
    NSUInteger startPosition = indexPath.row+1;
    NSUInteger endPosition = startPosition;
    BOOL expand = NO;
    for (int i=0; i<_data.count; i++) {
        Node *node = [_data objectAtIndex:i];
        if (node.parentId == parentNode.nodeId) {
            node.expand = !node.expand;
            if (node.expand) {
                [_tempData insertObject:node atIndex:endPosition];
                expand = YES;
                endPosition++;
            }else{
                expand = NO;
                endPosition = [self removeAllNodesAtParentNode:parentNode];
                break;
            }
        }
    }
    //获得需要修正的indexPath
    NSMutableArray *indexPathArray = [NSMutableArray array];
    for (NSUInteger i=startPosition; i<endPosition; i++) {
        NSIndexPath *tempIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [indexPathArray addObject:tempIndexPath];
    }
    
    //插入或者删除相关节点
    if (expand) {
        [self insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationNone];
    }else{
        [self deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationNone];
    }
}

/**
 *  删除该父节点下的所有子节点（包括孙子节点）
 *
 *  @param parentNode 父节点
 *
 *  @return 该父节点下一个相邻的统一级别的节点的位置
 */
-(NSUInteger)removeAllNodesAtParentNode : (Node *)parentNode{
    NSUInteger startPosition = [_tempData indexOfObject:parentNode];
    NSUInteger endPosition = startPosition;
    for (NSUInteger i=startPosition+1; i<_tempData.count; i++) {
        Node *node = [_tempData objectAtIndex:i];
        endPosition++;
        if (node.depth <= parentNode.depth) {
            break;
        }
        if(endPosition == _tempData.count-1){
            endPosition++;
            node.expand = NO;
            break;
        }
        node.expand = NO;
    }
    if (endPosition>startPosition) {
        [_tempData removeObjectsInRange:NSMakeRange(startPosition+1, endPosition-startPosition-1)];
    }
    return endPosition;
}


- (void)createButton{
    
    for (Node * node in _tempData) {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.selected = NO;
        if (btn.selected) {
            [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_10"] forState:UIControlStateNormal];
        }else{
            [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_11"] forState:UIControlStateNormal];
        }
        btn.frame = CGRectMake(10, 10, 20, 20);
        btn.tag  = 201212 + node.nodeId;
        [_btnArr addObject:btn];
        btn.frame = CGRectMake(10, 10, 20, 20);
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
                    if ((button.tag -201212) == node.nodeId && node.parentId == (btn.tag -201212)) {
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
                    if ((button.tag -201212) == node.nodeId) {
                        if (node.depth == 2 && node.parentId == (btn.tag -201212)) {
                            button.selected = flag;
                            [self btnActionWith:flag1 andButton:button andLevel:2];
                            }
                        }
                    }
                }
            break;
        case 2:
            //2
            for (Node * node in _data) {
                for (UIButton * button in _btnArr) {
                    if ((button.tag -201212) == node.nodeId) {
                        if (node.depth == 3 && node.parentId == (btn.tag -201212)) {
                            button.selected = flag;
                            [self btnActionWith:flag1 andButton:button andLevel:3];
                        }
                    }
                }
            }
            break;
        case 3:

            break;
            
        default:
            break;
    }
    for (UIButton * btn in _btnArr) {
        if (btn.selected) {
            [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_10"] forState:UIControlStateNormal];
        }else{
            [btn setBackgroundImage:[UIImage imageNamed:@"05-2登录_11"] forState:UIControlStateNormal];
        }
    }
}
@end
