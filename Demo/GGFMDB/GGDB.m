//
//  GGDB.m
//  GGFMDB
//
//  Created by Hugin on 16/9/2.
//  Copyright © 2016年 Hugin. All rights reserved.
//

#import "GGDB.h"
#import "Person.h"

@interface GGDB()

@property(nonatomic, strong) GGFMDB *db;

@end

@implementation GGDB
+ (void)load
{
    [super load];
    [[GGFMDB shareDatabase] gg_createTable:@"person" dicOrModel:[Person class] excludeName:nil];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _db = [GGFMDB shareDatabase];
    }
    return self;
}

- (void)insertMethod1:(BLOCK)block
{
    Person *person = [[Person alloc] init];
    person.name = [self randomName];
    person.phoneNum = @(10086);
    person.photoData = UIImageJPEGRepresentation([UIImage imageNamed:@"icon.jpg"], 1.0);
    person.age = arc4random_uniform(100)+1;
    person.height = 180.18;
    person.weight = 140.18;
    
    [_db gg_insertTable:@"person" dicOrModel:person];
    block();
}
- (void)insertMethod2:(BLOCK)block
{
    for (int i = 0; i < 3; i++) {
        Person *person = [[Person alloc] init];
        person.name = [self randomName];
        person.phoneNum = @(10086);
        person.photoData = UIImageJPEGRepresentation([UIImage imageNamed:@"icon.jpg"], 1.0);
        person.age = arc4random_uniform(100)+1;
        person.height = 180.18;
        person.weight = 140.18;
        [_db gg_insertTable:@"person" dicOrModel:person];
    }
    block();
}
- (void)insertMethod3:(BLOCK)block
{
    [_db gg_inDatabase:^{
        Person *person = [[Person alloc] init];
        person.name = [self randomName];
        person.phoneNum = @(10086);
        person.photoData = UIImageJPEGRepresentation([UIImage imageNamed:@"icon.jpg"], 1.0);
        person.age = arc4random_uniform(100)+1;
        person.height = 180.18;
        person.weight = 140.18;
        
        [_db gg_insertTable:@"person" dicOrModel:person];
        block();
    }];
}
- (void)insertMethod4:(BLOCK)block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_db gg_inDatabase:^{
            Person *person = [[Person alloc] init];
            person.name = [self randomName];
            person.phoneNum = @(10086);
            person.photoData = UIImageJPEGRepresentation([UIImage imageNamed:@"icon.jpg"], 1.0);
            person.age = arc4random_uniform(100)+1;
            person.height = 180.18;
            person.weight = 140.18;
            
            [_db gg_insertTable:@"person" dicOrModel:person];
            dispatch_sync(dispatch_get_main_queue(), ^{
                block();
            });
        }];
    });
}

- (void)deleteMethod1:(BLOCK)block
{
    long pkid = [_db gg_lastInsertPrimaryKeyId:@"person"];
    [_db gg_deleteTable:@"person" whereFormat:[NSString stringWithFormat:@"where pkid = %ld", pkid]];
    block();
}
- (void)deleteMethod2:(BLOCK)block
{
    [_db gg_deleteAllDataFromTable:@"person"];
    block();
}
- (void)deleteMethod3:(BLOCK)block
{
    [_db gg_inDatabase:^{
        long pkid = [_db gg_lastInsertPrimaryKeyId:@"person"];
        [_db gg_deleteTable:@"person" whereFormat:[NSString stringWithFormat:@"where pkid = %ld", pkid]];
        block();
    }];
}
- (void)deleteMethod4:(BLOCK)block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_db gg_inDatabase:^{
            long pkid = [_db gg_lastInsertPrimaryKeyId:@"person"];
            [_db gg_deleteTable:@"person" whereFormat:[NSString stringWithFormat:@"where pkid = %ld", pkid]];
            dispatch_sync(dispatch_get_main_queue(), ^{
                block();
            });
        }];
    });
}

- (void)updateMethod1:(BLOCK)block
{
    long pkid = [_db gg_lastInsertPrimaryKeyId:@"person"];
    [_db gg_updateTable:@"person" dicOrModel:@{@"name":@"Hugin"} whereFormat:[NSString stringWithFormat:@"where pkid = %ld", pkid]];
    block();
}
- (void)updateMethod2:(BLOCK)block
{
    [_db gg_updateTable:@"person" dicOrModel:@{@"name":@"Hugin"} whereFormat:nil];
    block();
}
- (void)updateMethod3:(BLOCK)block
{
    [_db gg_inDatabase:^{
        long pkid = [_db gg_lastInsertPrimaryKeyId:@"person"];
        [_db gg_updateTable:@"person" dicOrModel:@{@"name":[self randomName]} whereFormat:[NSString stringWithFormat:@"where pkid = %ld", pkid]];
        block();
    }];
}
- (void)updateMethod4:(BLOCK)block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_db gg_inDatabase:^{
            long pkid = [_db gg_lastInsertPrimaryKeyId:@"person"];
            [_db gg_updateTable:@"person" dicOrModel:@{@"name":[self randomName]} whereFormat:[NSString stringWithFormat:@"where pkid = %ld", pkid]];
            dispatch_sync(dispatch_get_main_queue(), ^{
                block();
            });
        }];
    });
}

- (void)queryMethod1:(BlockQuery)block
{
    NSArray *arr = [_db gg_queryTable:@"person" dicOrModel:[Person class] whereFormat:@"where name = 'Hugin'"];
    block(arr);
}
- (void)queryMethod2:(BlockQuery)block
{
    NSArray *arr = [_db gg_queryTable:@"person" dicOrModel:[Person class] whereFormat:nil];
    block(arr);
}
- (void)queryMethod3:(BlockQuery)block
{
    [_db gg_inDatabase:^{
        NSArray *arr = [_db gg_queryTable:@"person" dicOrModel:[Person class] whereFormat:@"where name = 'Hugin'"];
        block(arr);
    }];
}
- (void)queryMethod4:(BlockQuery)block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_db gg_inDatabase:^{
            NSArray *arr = [_db gg_queryTable:@"person" dicOrModel:[Person class] whereFormat:@"where name = 'Hugin'"];
            dispatch_sync(dispatch_get_main_queue(), ^{
                block(arr);
            });
        }];
    });
}

- (void)transactionMethod1:(BLOCK)block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_db gg_inTransaction:^(BOOL *rollback) {
            for (int i = 0; i < 1000; i++) {
                @autoreleasepool {
                    Person *person = [[Person alloc] init];
                    person.name = [self randomName];
                    person.phoneNum = @(10086);
                    person.photoData = UIImageJPEGRepresentation([UIImage imageNamed:@"icon.jpg"], 1.0);
                    person.age = arc4random_uniform(100)+1;
                    person.height = 180.18;
                    person.weight = 140.18;
                    BOOL flag = [_db gg_insertTable:@"person" dicOrModel:person];
                    if (flag == NO) {
                        *rollback = YES; //回滚操作
                        return; //不加return会一直循环完1000
                    }
                }
            }
            block();
        }];
    });
}

- (void)pagingQueryAllData:(BlockQuery)block;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray<NSArray *> *arr = [_db gg_pagingQueryAllDataTable:@"person" dicOrModel:[Person class] dataLength:3];
        block(arr);
    });
}

- (void)transferWithPage:(int)page row:(int)row block:(BlockAll)block
{
    switch (page) {
        case 0:
            switch (row) {
                case 0:
                {
                    [self insertMethod1:^{
                        block(nil);
                    }];
                }
                    break;
                case 1:
                {
                    [self insertMethod2:^{
                        block(nil);
                    }];
                }
                    break;
                case 2:
                {
                    [self insertMethod3:^{
                        block(nil);
                    }];
                }
                    break;
                case 3:
                {
                    [self insertMethod4:^{
                        block(nil);
                    }];
                }
                    break;
            }
            break;
        case 1:
            switch (row) {
                case 0:
                {
                    [self deleteMethod1:^{
                        block(nil);
                    }];
                }
                    break;
                case 1:
                {
                    [self deleteMethod2:^{
                        block(nil);
                    }];
                }
                    break;
                case 2:
                {
                    [self deleteMethod3:^{
                        block(nil);
                    }];
                }
                    break;
                case 3:
                {
                    [self deleteMethod4:^{
                        block(nil);
                    }];
                }
                    break;
            }
            break;
        case 2:
            switch (row) {
                case 0:
                {
                    [self queryMethod1:^(NSArray *arr) {
                        block(arr);
                    }];
                }
                    break;
                case 1:
                {
                    [self queryMethod2:^(NSArray *arr) {
                        block(arr);
                    }];
                }
                    break;
                case 2:
                {
                    [self queryMethod3:^(NSArray *arr) {
                        block(arr);
                    }];
                }
                    break;
                case 3:
                {
                    [self queryMethod4:^(NSArray *arr) {
                        block(arr);
                    }];
                }
                    break;
            }
            break;
        case 3:
            switch (row) {
                case 0:
                {
                    [self updateMethod1:^{
                        block(nil);
                    }];
                }
                    break;
                case 1:
                {
                    [self updateMethod2:^{
                        block(nil);
                    }];
                }
                    break;
                case 2:
                {
                    [self updateMethod3:^{
                        block(nil);
                    }];
                }
                    break;
                case 3:
                {
                    [self updateMethod4:^{
                        block(nil);
                    }];
                }
                    break;
            }
            break;
    }
}

// 获得随机名称
static NSArray *nameList;
- (NSString *)randomName {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nameList = [NSArray arrayWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"nameList.strings" withExtension:nil]];
    });
    unsigned int i = arc4random_uniform((unsigned int)nameList.count);
    return nameList[i];
}


@end
