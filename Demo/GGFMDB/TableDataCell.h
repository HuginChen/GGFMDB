//
//  TableDataCell.h
//  GGFMDB
//
//  Created by Hugin on 16/9/2.
//  Copyright © 2016年 Hugin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Person.h"

@interface TableDataCell : UITableViewCell

@property(nonatomic, strong) Person *model;

@end
