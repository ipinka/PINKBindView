//
//  ExampleTableViewCell.m
//  PINKBindViewExample
//
//  Created by Pinka on 15-1-22.
//  Copyright (c) 2015年 Pinka. All rights reserved.
//

#import "ExampleTableViewCell.h"

@interface ExampleTableViewCell ()

@property (weak, nonatomic) IBOutlet UIView *realContentView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

@end

@implementation ExampleTableViewCell

- (void)bindCellViewModel:(id)viewModel indexPath:(NSIndexPath *)indexPath displayFlag:(BOOL)displayFlag
{
    NSDictionary *dict = viewModel;
    
    if (displayFlag) {
        self.titleLabel.text = dict[@"title"];
    }
    self.contentLabel.text = dict[@"content"];
}

- (CGFloat)cellHeight
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    return self.realContentView.frame.size.height;
}

@end
