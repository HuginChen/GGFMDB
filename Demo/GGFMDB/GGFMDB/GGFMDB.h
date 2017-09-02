//
//  Created by Hugin on 16/8/31.
//  Copyright © 2016年 Hugin. All rights reserved.
//
//  GitHub: https://github.com/HuginChen/GGFMDB.git
//

#import "FMDB.h"

/**
 *  大量 "增删改查" 时最好使用下面线程安全操作的方法:
 *      - (void)gg_inDatabase:(void (^)(void))block;
 *      - (void)gg_inTransaction:(void(^)(BOOL *rollback))block;
 *  这两个方法亲测(99.99%)不会出现循环引用
 */
@interface GGFMDB : NSObject

#pragma mark - 初始化
/**
 *  使用 shareDatabase创建, 则默认在 NSDocumentDirectory下创建 Database.sqlite, 参数可随意或 nil
 *
 *  dbName 数据库的名称 如: @"Users.sqlite", 如果 dbName = nil, 则默认 dbName = @"Database.sqlite"
 *  dbPath 数据库的路径, 如果 dbPath = nil, 则路径默认为 NSDocumentDirectory
 */
+ (instancetype)shareDatabase;
+ (instancetype)shareDatabase:(NSString *)dbName;
+ (instancetype)shareDatabase:(NSString *)dbName path:(NSString *)dbPath;

#pragma mark - 其他数据操作
/**
 *  返回最后一条数据的主键id
 *
 *  @param tableName 表的名称
 *  @return 返回最后插入的 primary key id
 */
- (NSInteger)gg_lastInsertPrimaryKeyId:(NSString *)tableName;

/**
 *  分页查询部分数据 *** 从第0页开始算 ***
 *
 *  @param tableName    表的名称
 *  @param parameters   每条查找结果放入 model (可以是[Person class] or @"Person" or Person实例) 或 dictionary (格式: @{@"name":@"TEXT"})中
 *  @param number      ]\[p\][p 第几页 (从第0页开始)
 *  @param length       每页数据长度
 *  @return return      将结果存入 array, 数组中的元素的类型为 parameters的类型
 */
- (NSArray *)gg_pagingQueryPartDataTable:(NSString *)tableName dicOrModel:(id)parameters whichPage:(int)number dataLength:(int)length;

/**
 *  分页查询全部数据
 *  @param tableName    表的名称
 *  @param parameters   每条查找结果放入 model (可以是[Person class] or @"Person" or Person实例) 或 dictionary (格式: @{@"name":@"TEXT"})中
 *  @param length       每页数据长度
 *  @return return      将结果存入 array, 数组中的元素的类型为 parameters的类型
 *  @return return      返回分好组(页)数组A, 数组A中的元素是数组B, 数组B的每一组(页)的数据, 数组B中的元素的类型为 parameters的类型
 */
- (NSArray<NSArray *> *)gg_pagingQueryAllDataTable:(NSString *)tableName dicOrModel:(id)parameters dataLength:(int)length;

#pragma mark - 创建表
/**
 *  创建表 通过传入的model或dictionary(如果是字典注意类型要写对), 虽然都可以不过还是推荐以下都用model
 *
 *  @param tableName   表的名称
 *  @param parameters  设置表的字段, 可以传model(runtime自动生成字段)或字典(格式: @{@"name":@"TEXT"}), 也可以传 modelClassName...
 *  @return            是否创建成功
 */
- (BOOL)gg_createTable:(NSString *)tableName dicOrModel:(id)parameters;

/**
 *  效果同上
 *  @param nameArr 不允许model或dic里的属性/key生成表的字段, 如:nameArr = @[@"name"], 则不允许名为name的属性/key 生成表的字段
 */
- (BOOL)gg_createTable:(NSString *)tableName dicOrModel:(id)parameters excludeName:(NSArray *)nameArr;

#pragma mark - 增删改查
/**
 *  增加: 向表中插入数据
 *
 *  @param tableName   表的名称
 *  @param parameters  要插入的数据, 可以是model或dictionary(格式:@{@"name":@"Hugin"})
 *  @return            是否插入成功
 */
- (BOOL)gg_insertTable:(NSString *)tableName dicOrModel:(id)parameters;

/**
 *  批量插入或更改
 *
 *  @param     dicOrModelArray 要insert/update数据的数组, 也可以将 model和 dictionary混合装入array
 *  @return    返回的数组存储未插入成功的下标, 数组中元素类型为NSNumber
 */
- (NSArray *)gg_insertTable:(NSString *)tableName dicOrModelArray:(NSArray *)dicOrModelArray;

/**
 *  删除: 根据条件删除表中数据
 *
 *  @param tableName           表的名称
 *  @param format              条件语句, 如: @"where name = 'Hugin'"
 *                                        @"where name = 'Hugin' and age = 18"
 *  @return                    是否删除成功
 */
- (BOOL)gg_deleteTable:(NSString *)tableName whereFormat:(NSString *)format;

/**
 *  更改: 根据条件更改表中数据
 *
 *  @param tableName   表的名称
 *  @param parameters  要更改的数据, 可以是 model或 dictionary (格式:@{@"name":@"张三"})
 *  @param format      条件语句, 如: @"where name = '小李'"
 *                                 @"where name = 'Hugin' and age = 18"
 *  @return            是否更改成功
 */
- (BOOL)gg_updateTable:(NSString *)tableName dicOrModel:(id)parameters whereFormat:(NSString *)format;

/**
 *  查找: 根据条件查找表中数据
 *
 *  @param tableName   表的名称
 *  @param parameters  每条查找结果放入 model (可以是[Person class] or @"Person" or Person实例) 或 dictionary (格式: @{@"name":@"TEXT"})中
 *  @param format      条件语句, 如: @"where name = 'Hugin'"
 *                                @"where name = 'Hugin' and age = 18"
 *  @return            将结果存入 array, 数组中的元素的类型为 parameters的类型
 */
- (NSArray *)gg_queryTable:(NSString *)tableName dicOrModel:(id)parameters whereFormat:(NSString *)format;

#pragma mark - 其他表操作
/** 删除表 */
- (BOOL)gg_deleteTable:(NSString *)tableName;
/** 清空表 */
- (BOOL)gg_deleteAllDataFromTable:(NSString *)tableName;
/** 是否存在表 */
- (BOOL)gg_isExistTable:(NSString *)tableName;
/** 表中共有多少条数据 */
- (int)gg_tableItemCount:(NSString *)tableName;
/** 返回表中的字段名 */
- (NSArray *)gg_columnNameArray:(NSString *)tableName;

#pragma mark 该操作已在事务中执行
/**
 *  增加新字段 该操作已在事务中执行
 *  在建表后还想新增字段, 可以在原建表 model或新 model中新增对应属性, 然后传入即可新增该字段
 *
 *  @param tableName   表的名称
 *  @param parameters  如果传Model: 数据库新增字段为建表时 model所没有的属性,
 *                     如果传dictionary 格式为 @{@"newname":@"TEXT"}
 *  @param nameArr     不允许生成字段的属性名的数组
 *  @return            是否成功
 */
- (BOOL)gg_alterTable:(NSString *)tableName dicOrModel:(id)parameters excludeName:(NSArray *)nameArr;
- (BOOL)gg_alterTable:(NSString *)tableName dicOrModel:(id)parameters;

#pragma mark - 线程安全操作
/**
 *  将操作语句放入block中即可保证线程安全,
 *
 *  如:
 *      Person *p = [[Person alloc] init];
 *      p.name = @"Hugin";
 *
 *      [ggdb gg_inDatabase:^{
 *          [ggdb gg_insertTable:@"users" dicOrModel:p];
 *      }];
 */
- (void)gg_inDatabase:(void (^)(void))block;

/**
 *  事务: 将操作语句放入block中可执行回滚操作(*rollback = YES;)
 *
 *  如:
 *      Person *p = [[Person alloc] init];
 *      p.name = @"Hugin";
 *
 *      for (int i=0, i < 1000, i++) {
 *          [ggdb gg_inTransaction:^(BOOL *rollback) {
 *              BOOL flag = [ggdb gg_insertTable:@"users" dicOrModel:p];
 *              if (!flag) {
 *                  *rollback = YES; //只要有一次不成功, 则进行回滚操作
 *                  return;
 *              }
 *          }];
 *      }
 */
- (void)gg_inTransaction:(void(^)(BOOL *rollback))block;

#pragma mark - FMDB 原生SQL操作
- (FMResultSet *)gg_fm_executeQuery:(NSString*)sql, ... ;
- (BOOL)gg_fm_executeUpdate:(NSString*)sql, ... ;
- (BOOL)gg_fm_executeStatements:(NSString *)sql ;
- (BOOL)gg_fm_executeStatements:(NSString *)sql withResultBlock:(FMDBExecuteStatementsCallbackBlock)block;

@end
