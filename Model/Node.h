//
//  Node.h
//  SEM
//
//  Created by xlc on 16/7/27.
//  Copyright © 2016年 王广明. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Node : NSObject

@property (nonatomic,assign) long long parentId;//父节点的id,如果为-1表示该节点为根节点

@property (nonatomic,assign) long long nodeId;//本节点的id

@property (nonatomic,copy) NSString *name;//本节点的名称

@property (nonatomic,assign) int depth;//该节点的深度

@property (nonatomic,assign) BOOL expand;//该节点是否处于展开状态;

@property (nonatomic,copy) NSString *MpID;//表的id

//快速实例化该对象模型

- (instancetype)initWithParentId : (long long)parentId nodeId : (long long)nodeId name : (NSString *)name depth : (int)depth expand : (BOOL)expand mpID : (NSString *)mpID;

@end
