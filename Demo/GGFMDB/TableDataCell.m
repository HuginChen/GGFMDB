//
//  TableDataCell.m
//  GGFMDB
//
//  Created by Hugin on 16/9/2.
//  Copyright © 2016年 Hugin. All rights reserved.
//

#import "TableDataCell.h"

@interface TableDataCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *heightLabel;
@property (weak, nonatomic) IBOutlet UILabel *weightLabel;

@end

@implementation TableDataCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setModel:(Person *)model
{
    _model = model;
    _iconImageView.image = [UIImage imageWithData:model.photoData];
    _nameLabel.text = model.name;
    _idLabel.text = @(model.pkid).description;
    _ageLabel.text = @(model.age).description;
    _phoneLabel.text = model.phoneNum.stringValue;
    _heightLabel.text = @(model.height).description;
    _weightLabel.text = @(model.weight).description;
}
@end
