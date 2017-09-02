//
//  Person.h
//  GGFMDBDemo
//
//  Created by Hugin on 16/9/1.
//  Copyright © 2016年 Hugin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

// 可省略, 默认的主键id, 如果需要获取主键id的值, 可在自己的model中添加下面这个属性
@property(nonatomic, assign) NSInteger pkid;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSNumber *phoneNum;
@property(nonatomic, strong) NSData *photoData;
@property(nonatomic, assign) int age;
@property(nonatomic, assign) float height;  //float类型存入172.12会变成172.19995,取值时%.2f等于原值172.12
@property(nonatomic, assign) double weight;


@end
