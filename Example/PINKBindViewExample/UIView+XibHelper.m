//
//  UIView+XibHelper.m
//  PINKBindViewExample
//
//  Created by Pinka on 15-1-22.
//  Copyright (c) 2015年 Pinka. All rights reserved.
//

#import "UIView+XibHelper.h"

@implementation UIView (XibHelper)

+ (instancetype)createViewFromXib
{
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self)
                                         owner:nil
                                       options:nil][0];
}

+ (UINib *)viewNib
{
    return [UINib nibWithNibName:NSStringFromClass(self)
                          bundle:nil];
}

@end
