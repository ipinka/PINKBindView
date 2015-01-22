//
//  UIView+XibHelper.h
//  PINKBindViewExample
//
//  Created by Pinka on 15-1-22.
//  Copyright (c) 2015年 Pinka. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (XibHelper)

+ (instancetype)createViewFromXib;
+ (UINib *)viewNib;

@end
