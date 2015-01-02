//
//  PINKBindTableView.h
//  PINKBindView
//
//  Created by Pinka on 14-7-15.
//  Copyright (c) 2015 Pinka
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import "ReactiveCocoa.h"

@protocol PINKBindCellProtocol;

typedef UITableViewCell *(^PINKBindTableViewCreateCellBlock)(NSIndexPath *indexPath);

@interface PINKBindTableView : UITableView

@property (nonatomic, getter = isAutoCheckDataSource) BOOL autoCheckDataSource;
@property (nonatomic, getter = isAutoDeselect) BOOL autoDeselect;
@property (nonatomic, getter = isAutoReload) BOOL autoReload;
@property (nonatomic, getter = isAutoCellHeight) BOOL autoCellHeight;

@property (nonatomic, readonly) id<UITableViewDataSource> realDataSource;
@property (nonatomic, readonly) id<UITableViewDelegate> realDelegate;

- (void)setDataSourceSignal:(RACSignal *)sourceSignal
           selectionCommand:(RACCommand *)selection
                  cellClass:(Class<PINKBindCellProtocol>)cellClass;

- (void)setDataSourceSignal:(RACSignal *)sourceSignal
           selectionCommand:(RACCommand *)selection
            createCellBlock:(PINKBindTableViewCreateCellBlock)createCellBlock;

@end

//以下是截获了的方法，继承子类时可以直接重写，但还是要调用super
@interface PINKBindTableView (UITableViewDataSourceIntercept)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface PINKBindTableView (UITableViewDelegateIntercept)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
