//
//  ViewController.m
//  PINKBindViewExample
//
//  Created by Pinka on 15-1-22.
//  Copyright (c) 2015年 Pinka. All rights reserved.
//

#import "RACEXTScope.h"
#import "PINKBindTableView.h"
#import "UIView+XibHelper.h"

#import "ViewController.h"
#import "DetailViewController.h"
#import "ExampleTableViewCell.h"

@interface ViewController ()

@property (nonatomic, copy) NSArray *list;

@property (weak, nonatomic) IBOutlet PINKBindTableView *bindTableView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.list = @[@{@"title": @"1",
                    @"content": @"这是一行文字"},
                  @{@"title": @"2",
                    @"content": @"这是两行文字这是两行文字这是两行文字这是两行文字这是两行文字这是两行文字这是两行文字"},
                  @{@"title": @"3",
                    @"content": @"这是三行文字这是三行文字这是三行文字这是三行文字这是三行文字这是三行文字这是三行文字这是三行文字这是三行文字这是三行文字这是三行文字"},
                  @{@"title": @"4",
                    @"content": @"这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字这是四行文字"},
                  @{@"title": @"5",
                    @"content": @"这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字这是五行文字"},
                  @{@"title": @"6",
                    @"content": @"这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字这是六行文字"},
                  @{@"title": @"7",
                    @"content": @"这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字这是七行文字"},
                  @{@"title": @"8",
                    @"content": @"这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字这是八行文字"},
                  @{@"title": @"9",
                    @"content": @"这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字这是九行文字"}];
    
    self.bindTableView.autoCellHeight = YES;
    @weakify(self);
    [self.bindTableView setDataSourceSignal:RACObserve(self, list)
                           selectionCommand:[[RACCommand alloc]
                                             initWithSignalBlock:^RACSignal *(NSDictionary *input) {
                                                 @strongify(self);
                                                 DetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Detail"];
                                                 vc.model = input;
                                                 [self.navigationController pushViewController:vc animated:YES];
                                                 return [RACSignal empty];
                                             }]
                                    cellNib:ExampleTableViewCell.viewNib];
}

@end
