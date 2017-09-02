//
//  GGDB.h
//  GGFMDB
//
//  Created by Hugin on 16/9/2.
//  Copyright © 2016年 Hugin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GGFMDB.h"

typedef void(^BLOCK)(void);
typedef void(^BlockQuery)(NSArray *arr);
typedef void(^BlockAll)(NSArray *arr);

@interface GGDB : NSObject

- (void)insertMethod1:(BLOCK)block;
- (void)insertMethod2:(BLOCK)block;
- (void)insertMethod3:(BLOCK)block;
- (void)insertMethod4:(BLOCK)block;

- (void)deleteMethod1:(BLOCK)block;
- (void)deleteMethod2:(BLOCK)block;
- (void)deleteMethod3:(BLOCK)block;
- (void)deleteMethod4:(BLOCK)block;

- (void)updateMethod1:(BLOCK)block;
- (void)updateMethod2:(BLOCK)block;
- (void)updateMethod3:(BLOCK)block;
- (void)updateMethod4:(BLOCK)block;

- (void)queryMethod1:(BlockQuery)block;
- (void)queryMethod2:(BlockQuery)block;
- (void)queryMethod3:(BlockQuery)block;
- (void)queryMethod4:(BlockQuery)block;

- (void)transactionMethod1:(BLOCK)block;
- (void)pagingQueryAllData:(BlockQuery)block;
- (void)transferWithPage:(int)page row:(int)row block:(BlockAll)block;

@end
