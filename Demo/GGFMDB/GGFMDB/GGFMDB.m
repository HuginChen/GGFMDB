//
//  Created by Hugin on 16/8/31.
//  Copyright © 2016年 Hugin. All rights reserved.
//
//  GitHub: https://github.com/HuginChen/GGFMDB.git
//

#import "GGFMDB.h"
#import <objc/runtime.h>

// 数据库中常见的几种类型
#define SQL_TEXT     @"TEXT"    //文本
#define SQL_INTEGER  @"INTEGER" //int long integer ...
#define SQL_REAL     @"REAL"    //浮点
#define SQL_BLOB     @"BLOB"    //data

@interface GGFMDB()

@property(nonatomic, strong) FMDatabase *db;
@property(nonatomic, strong) FMDatabaseQueue *dbQueue;
@property(nonatomic, strong) NSString *dbPath;

@end

@implementation GGFMDB

#pragma mark - 初始化
+ (instancetype)shareDatabase {
    return [self shareDatabase:nil];
}
+ (instancetype)shareDatabase:(NSString *)dbName {
    return [self shareDatabase:dbName path:nil];
}
+ (instancetype)shareDatabase:(NSString *)dbName path:(NSString *)dbPath
{
    __block NSString *dbNameTemp = dbName;
    __block NSString *dbPathTemp = dbPath;
    
    static GGFMDB *instance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        if (!dbNameTemp) {
            dbNameTemp = @"Database.sqlite";
        }
        if (!dbPathTemp) {
            dbPathTemp = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dbName];
        }
        NSString * path = [dbPathTemp stringByAppendingPathComponent:dbNameTemp];
        NSLog(@"数制库路径:%@", path);
        
        FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
        
        // 99.99% 传的路径有问题
        NSAssert(dbQueue != nil, @"数据库初始化失败");
        
        instance.dbQueue = dbQueue;
        instance.db = [dbQueue valueForKey:@"_db"];;
        instance.dbPath = path;
    });
    return instance;
}

#pragma mark - 其他数据操作
- (NSInteger)gg_lastInsertPrimaryKeyId:(NSString *)tableName
{
    NSString *sqlstr = [NSString stringWithFormat:@"SELECT * FROM %@ where pkid = (SELECT max(pkid) FROM %@)", tableName, tableName];
    FMResultSet *set = [_db executeQuery:sqlstr];
    while ([set next])
    {
        return [set longLongIntForColumn:@"pkid"];
    }
    return 0;
}

- (NSArray *)gg_pagingQueryPartDataTable:(NSString *)tableName dicOrModel:(id)parameters whichPage:(int)number dataLength:(int)length
{
    // 开始索引 = (第几页-1) * 长度 可是我们从第 0 页开始数, 就不用 number - 1 了
    NSString *startIndex = @(number * length).description;
    FMResultSet *set = [_db executeQuery:[NSString stringWithFormat:@"select * from %@ limit %d offset %@", tableName, length, startIndex]];
    // 解析结果集数据
    return [self analyzeTheResultSetData:set tableName:tableName dicOrModel:parameters];
}

- (NSArray<NSArray *> *)gg_pagingQueryAllDataTable:(NSString *)tableName dicOrModel:(id)parameters dataLength:(int)length
{
    NSMutableArray<NSArray *> *arrM = [NSMutableArray arrayWithCapacity:5];
    // 查询表中数据数量
    FMResultSet *set = [_db executeQuery:[NSString stringWithFormat:@"select count(1) from %@", tableName]];
    long count = 0;
    while ([set next]) {
        count = [set longForColumnIndex:0];
    }
    // 计算页数
    long pageNumber = (count / length) + ((count % length) == 0 ? 0 : 1);
    for (int i = 0; i < pageNumber; i++) {
        // 查询第 i 页的数据
        [arrM addObject:[self gg_pagingQueryPartDataTable:tableName dicOrModel:parameters whichPage:i dataLength:length]];
    }
    return arrM.copy;
}

#pragma mark - 创建表
- (BOOL)gg_createTable:(NSString *)tableName dicOrModel:(id)parameters {
    return [self gg_createTable:tableName dicOrModel:parameters excludeName:nil];
}
- (BOOL)gg_createTable:(NSString *)tableName dicOrModel:(id)parameters excludeName:(NSArray *)nameArr
{
    NSDictionary *dic;
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        dic = parameters;
    } else {
        // 根据 model生成 class对象
        Class cls = [self classWithModel:parameters];
        // 把 model属性转成数据库字段dic
        dic = [self modelToDictionary:cls excludePropertyName:nameArr];
    }
    
    NSMutableString *fieldStr = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (pkid  INTEGER PRIMARY KEY,", tableName];
    
    int keyCount = 0;
    for (NSString *key in dic) {
        keyCount++;
        // 不允许生成的字段
        if ((nameArr == nil && [nameArr containsObject:key]) || [key isEqualToString:@"pkid"]) {
            continue;
        }
        // 拼接最后一个字段
        if (keyCount == dic.count) {
            [fieldStr appendFormat:@" %@ %@)", key, dic[key]];
            break;
        }
        // 拼接字段
        [fieldStr appendFormat:@" %@ %@,", key, dic[key]];
    }
    BOOL creatFlag = [_db executeUpdate:fieldStr];
    return creatFlag;
}

#pragma mark - 增删改查
- (BOOL)gg_insertTable:(NSString *)tableName dicOrModel:(id)parameters
{
    // 得到表里的字段名称
    NSArray *columnArr = [self getColumnArr:tableName db:_db];
    // 向表中插入数据
    return [self insertTable:tableName dicOrModel:parameters columnArr:columnArr];
    
}
- (NSArray *)gg_insertTable:(NSString *)tableName dicOrModelArray:(NSArray *)dicOrModelArray
{
    int errorIndex = 0;
    NSMutableArray *resultMArr = [NSMutableArray arrayWithCapacity:5];
    NSArray *columnArr = [self getColumnArr:tableName db:_db];
    for (id parameters in dicOrModelArray) {
        // 向表中插入数据
        BOOL flag = [self insertTable:tableName dicOrModel:parameters columnArr:columnArr];
        if (!flag) {
            [resultMArr addObject:@(errorIndex)];
        }
        errorIndex++;
    }
    return resultMArr;
}
/** 向表中插入数据 */
- (BOOL)insertTable:(NSString *)tableName dicOrModel:(id)parameters columnArr:(NSArray *)columnArr
{
    NSDictionary *dic;
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        dic = parameters;
    }else {
        // model转dic
        dic = [self getModelPropertyKeyValue:parameters tableName:tableName clomnArr:columnArr];
    }
    
    NSMutableString *finalStr = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ (", tableName];
    NSMutableString *tempStr = [NSMutableString stringWithCapacity:5];
    NSMutableArray *argumentsArr = [NSMutableArray arrayWithCapacity:5];
    
    // 拼接添加 SQL
    for (NSString *key in dic) {
        // 不允许生成的字段
        if (columnArr.count == 0 || ![columnArr containsObject:key] || [key isEqualToString:@"pkid"]) {
            continue;
        }
        [finalStr appendFormat:@"%@,", key];
        [tempStr appendString:@"?,"];
        
        [argumentsArr addObject:dic[key]];
    }
    
    // 删除 finalStr最后一个 ','
    [finalStr deleteCharactersInRange:NSMakeRange(finalStr.length-1, 1)];
    if(tempStr.length > 0) {
        // 删除 tempStr最后一个 ','
        [tempStr deleteCharactersInRange:NSMakeRange(tempStr.length-1, 1)];
    }
    [finalStr appendFormat:@") values (%@)", tempStr];
    // 执行 SQl并添加参数
    BOOL flag = [_db executeUpdate:finalStr withArgumentsInArray:argumentsArr];
    return flag;
}

- (BOOL)gg_deleteTable:(NSString *)tableName whereFormat:(NSString *)format
{
    NSString *finalStr = [[NSString alloc] initWithFormat:@"delete from %@ %@", tableName,format];
    BOOL flag = [_db executeUpdate:finalStr];
    return flag;
}

- (BOOL)gg_updateTable:(NSString *)tableName dicOrModel:(id)parameters whereFormat:(NSString *)format
{
    NSDictionary *dic;
    // 得到表里的字段名称
    NSArray *columnArr = [self getColumnArr:tableName db:_db];
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        dic = parameters;
    }else {
        // model转dic
        dic = [self getModelPropertyKeyValue:parameters tableName:tableName clomnArr:columnArr];
    }
    
    NSMutableString *finalStr = [[NSMutableString alloc] initWithFormat:@"update %@ set ", tableName];
    NSMutableArray *argumentsArr = [NSMutableArray arrayWithCapacity:5];
    
    for (NSString *key in dic) {
        // 不允许生成的字段
        if (columnArr.count == 0 || ![columnArr containsObject:key] || [key isEqualToString:@"pkid"]) {
            continue;
        }
        // 拼接SQL
        [finalStr appendFormat:@"%@ = %@,", key, @"?"];
        // 参数
        [argumentsArr addObject:dic[key]];
    }
    // 删除 finalStr最后一个 ','
    [finalStr deleteCharactersInRange:NSMakeRange(finalStr.length - 1, 1)];
    if (format.length) {
        [finalStr appendFormat:@" %@", format];
    }
    // 执行SQL并添加参数
    BOOL flag =  [_db executeUpdate:finalStr withArgumentsInArray:argumentsArr];
    return flag;
}

- (NSArray *)gg_queryTable:(NSString *)tableName dicOrModel:(id)parameters whereFormat:(NSString *)format
{
    // 拼接SQL
    NSMutableString *finalStr = [[NSMutableString alloc] initWithFormat:@"select * from %@ %@",
                                 tableName,
                                 format ? format : @""];
    // 执行SQL
    FMResultSet *set = [_db executeQuery:finalStr];
    
    // 解析结果集数据
    return [self analyzeTheResultSetData:set tableName:tableName dicOrModel:parameters];;
}

#pragma mark - 其他操作
- (BOOL)gg_deleteTable:(NSString *)tableName
{
    NSString *sqlstr = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
    if (![_db executeUpdate:sqlstr])
    {
        return NO;
    }
    return YES;
}

- (BOOL)gg_deleteAllDataFromTable:(NSString *)tableName
{
    NSString *sqlstr = [NSString stringWithFormat:@"DELETE FROM %@", tableName];
    if (![_db executeUpdate:sqlstr])
    {
        return NO;
    }
    return YES;
}

- (BOOL)gg_isExistTable:(NSString *)tableName
{
    FMResultSet *set = [_db executeQuery:@"SELECT count(*) as 'count' FROM sqlite_master WHERE type ='table' and name = ?", tableName];
    while ([set next])
    {
        NSInteger count = [set intForColumn:@"count"];
        if (count == 0) {
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

- (int)gg_tableItemCount:(NSString *)tableName
{
    NSString *sqlstr = [NSString stringWithFormat:@"SELECT count(*) as 'count' FROM %@", tableName];
    FMResultSet *set = [_db executeQuery:sqlstr];
    while ([set next])
    {
        return [set intForColumn:@"count"];
    }
    return 0;
}

- (NSArray *)gg_columnNameArray:(NSString *)tableName
{
    return [self getColumnArr:tableName db:_db];
}

- (BOOL)gg_alterTable:(NSString *)tableName dicOrModel:(id)parameters
{
    return [self gg_alterTable:tableName dicOrModel:parameters excludeName:nil];
}

- (BOOL)gg_alterTable:(NSString *)tableName dicOrModel:(id)parameters excludeName:(NSArray *)nameArr
{
    __block BOOL flag;
    // 这里是同步串行队列
    [self gg_inTransaction:^(BOOL *rollback) {
        if ([parameters isKindOfClass:[NSDictionary class]]) {
            for (NSString *key in parameters) {
                // 不允许生成字段
                if ([nameArr containsObject:key]) {
                    continue;
                }
                flag = [_db executeUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", tableName, key, parameters[key]]];
                if (!flag) {
                    // 出错就回滚事务
                    *rollback = YES;
                    return;
                }
            }
        } else {
            // 根据 model生成 class对象
            Class cls = [self classWithModel:parameters];
            // 把 model属性转成数据库字段dic
            NSDictionary *modelDic = [self modelToDictionary:cls excludePropertyName:nameArr];
            // 得到表里的字段名称
            NSArray *columnArr = [self getColumnArr:tableName db:_db];
            for (NSString *key in modelDic) {
                // 生成的属性字段 --> (存在表里的字段dic || 不存在不允许字段dic)
                if ([columnArr containsObject:key] && ![nameArr containsObject:key]) {
                    flag = [_db executeUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", tableName, key, modelDic[key]]];
                    if (!flag) {
                        // 出错就回滚事务
                        *rollback = YES;
                        return;
                    }
                }
            }
        }
    }];
    return flag;
}

#pragma mark - 线程安全操作
- (void)gg_inDatabase:(void(^)(void))block
{
    [[self dbQueue] inDatabase:^(FMDatabase *db) {
        block();
    }];
}

- (void)gg_inTransaction:(void(^)(BOOL *rollback))block
{
    [[self dbQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        block(rollback);
    }];
}

#pragma mark - FMDB 原生SQL操作
- (FMResultSet *)gg_fm_executeQuery:(NSString*)sql, ... {
    return [_db executeQuery:sql];
}
- (BOOL)gg_fm_executeUpdate:(NSString*)sql, ... {
    return [_db executeUpdate:sql];
}
- (BOOL)gg_fm_executeStatements:(NSString *)sql {
    return [_db executeStatements:sql];
}
- (BOOL)gg_fm_executeStatements:(NSString *)sql withResultBlock:(FMDBExecuteStatementsCallbackBlock)block {
    return [_db executeStatements:sql withResultBlock:block];
}

#pragma mark - private
/**
 *  OC类型转成数据库类型
 *
 *  @param typeStr OC类型
 *  @return 数据库类型
 */
- (NSString *)propertTypeConvert:(NSString *)typeStr
{
    NSString *resultStr = nil;
    if ([typeStr hasPrefix:@"T@\"NSString\""]) {
        resultStr = SQL_TEXT;
    } else if ([typeStr hasPrefix:@"T@\"NSData\""]) {
        resultStr = SQL_BLOB;
    } else if ([typeStr hasPrefix:@"Ti"]||[typeStr hasPrefix:@"TI"]||[typeStr hasPrefix:@"Ts"]||[typeStr hasPrefix:@"TS"]||[typeStr hasPrefix:@"T@\"NSNumber\""]||[typeStr hasPrefix:@"TB"]||[typeStr hasPrefix:@"Tq"]||[typeStr hasPrefix:@"TQ"]) {
        resultStr = SQL_INTEGER;
    } else if ([typeStr hasPrefix:@"Tf"] || [typeStr hasPrefix:@"Td"]){
        resultStr= SQL_REAL;
    }
    return resultStr;
}

/** 得到表里的字段名称 */
- (NSArray *)getColumnArr:(NSString *)tableName db:(FMDatabase *)db
{
    NSMutableArray *mArr = [NSMutableArray arrayWithCapacity:0];
    
    FMResultSet *resultSet = [db getTableSchema:tableName];
    
    while ([resultSet next]) {
        [mArr addObject:[resultSet stringForColumn:@"name"]];
    }
    
    return mArr.copy;
}

/**
 *  根据 model生成 class对象, 若不能就崩溃 --> NSAssert
 *
 *  @param model 如: [Person class] or @"Person" or Person实例
 *  @return      class对象
 */
- (Class)classWithModel:(id)model
{
    Class cls;
    if ([model isKindOfClass:[NSString class]]) {
        if (NSClassFromString(model)) {
            // 字符串生成 Class
            cls = NSClassFromString(model);
        } else {
            cls = nil;
        }
    } else if ([model isKindOfClass:[NSObject class]]) {
        // NSObject 子类对象或者是 Class对象
        cls = [model class];
    } else {
        NSAssert(cls != nil, @"传的参数有问题");
    }
    return cls;
}

/**
 *  解析结果集的数据
 *
 *  @param set         结果集
 *  @param tableName   表名
 *  @param parameters  每条查找结果放入 model 或 dictionary 中
 *  @return            将结果存入 array, 数组中的元素的类型为 parameters的类型
 */
- (NSArray *)analyzeTheResultSetData:(FMResultSet *)set tableName:(NSString *)tableName dicOrModel:(id)parameters
{
    NSMutableArray *resultMArr = [NSMutableArray arrayWithCapacity:5];
    
    // 得到表里的字段名称
    NSArray *clomnArr = [self getColumnArr:tableName db:_db];
    
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        // 参数是字典
        NSDictionary *dic = parameters;
        while ([set next]) {
            NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:5];
            for (NSString *key in dic) {
                if ([dic[key] isEqualToString:SQL_TEXT]) {
                    id value = [set stringForColumn:key];
                    if (value) {
                        [resultDic setObject:value forKey:key];
                    }
                } else if ([dic[key] isEqualToString:SQL_INTEGER]) {
                    [resultDic setObject:@([set longLongIntForColumn:key]) forKey:key];
                } else if ([dic[key] isEqualToString:SQL_REAL]) {
                    [resultDic setObject:[NSNumber numberWithDouble:[set doubleForColumn:key]] forKey:key];
                } else if ([dic[key] isEqualToString:SQL_BLOB]) {
                    id value = [set dataForColumn:key];
                    if (value) {
                        [resultDic setObject:value forKey:key];
                    }
                }
            }
            // 添加字典到数组
            if (resultDic) {
                [resultMArr addObject:resultDic];
            }
        }
    } else {
        // 根据 model生成 class对象
        Class cls = [self classWithModel:parameters];
        // 把 model属性转成数据库字段dic
        NSDictionary *propertyType = [self modelToDictionary:cls excludePropertyName:nil];
        while ([set next]) {
            id model = [[cls alloc] init];
            for (NSString *name in clomnArr) {
                if ([propertyType[name] isEqualToString:SQL_TEXT]) {
                    id value = [set stringForColumn:name];
                    if (value) {
                        [model setValue:value forKey:name];
                    }
                } else if ([propertyType[name] isEqualToString:SQL_INTEGER]) {
                    [model setValue:@([set longLongIntForColumn:name]) forKey:name];
                } else if ([propertyType[name] isEqualToString:SQL_REAL]) {
                    [model setValue:[NSNumber numberWithDouble:[set doubleForColumn:name]] forKey:name];
                } else if ([propertyType[name] isEqualToString:SQL_BLOB]) {
                    id value = [set dataForColumn:name];
                    if (value) {
                        [model setValue:value forKey:name];
                    }
                }
            }
            // 添加对象到数组
            [resultMArr addObject:model];
        }
    }
    
    return resultMArr;
}

#pragma mark - runtime
/**
 把 model属性转成数据库字段dic
 
 @param cls model.class
 @param nameArr 不允许生成的字段
 @return 数据库字段dic
 */
- (NSDictionary *)modelToDictionary:(Class)cls excludePropertyName:(NSArray *)nameArr
{
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:5];
    // 属性列表次数
    unsigned int outCount;
    // 拿到 model的属性列表
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    // 遍历属性列表
    for (int i = 0; i < outCount; i++) {
        // 属性name
        NSString *name = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
        // 不允许生成的字段
        if ([nameArr containsObject:name]) {
            continue;
        }
        // 拿到属性的 OC类型 如下:
        // T@"NSString",C,N,V_name   -> NSString
        // Ti,N,V_age                -> int
        NSString *type = [NSString stringWithCString:property_getAttributes(properties[i]) encoding:NSUTF8StringEncoding];
        
        // OC类型转成数据库类型
        id value = [self propertTypeConvert:type];
        
        if (value) {
            [mDic setObject:value forKey:name];
        }
    }
    // 释放资源
    free(properties);
    // 返回数据库字段dic
    return mDic;
}

// 获取model的key和value
- (NSDictionary *)getModelPropertyKeyValue:(id)model tableName:(NSString *)tableName clomnArr:(NSArray *)clomnArr
{
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:0];
    // 属性列表次数
    unsigned int outCount;
    // 拿到 model的属性列表
    objc_property_t *properties = class_copyPropertyList([model class], &outCount);
    // 遍历属性列表
    for (int i = 0; i < outCount; i++) {
        // 属性name
        NSString *name = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
        // 允许生成的字段
        if ([clomnArr containsObject:name] == NO) {
            continue;
        }
        // 取 model属性的值
        id value = [model valueForKey:name];
        if (value) {
            [mDic setObject:value forKey:name];
        }
    }
    // 释放资源
    free(properties);
    // 返回数据库字段dic
    return mDic;
}
@end
