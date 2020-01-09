//
//  PINKBindCollectionView.h
//  PINKBindView
//
//  Created by Pinka on 14-10-22.
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
#import <ReactiveCocoa/ReactiveCocoa.h>

@protocol PINKBindCellProtocol;

@interface PINKBindCollectionView : UICollectionView

@property (nonatomic, getter = isAutoCheckDataSource) BOOL autoCheckDataSource;
@property (nonatomic, getter = isAutoDeselect) BOOL autoDeselect;
@property (nonatomic, getter = isAutoReload) BOOL autoReload;

@property (nonatomic, readonly) id<UICollectionViewDataSource> realDataSource;
@property (nonatomic, readonly) id<UICollectionViewDelegate> realDelegate;

- (void)setDataSourceSignal:(RACSignal *)sourceSignal
           selectionCommand:(RACCommand *)selection
                  cellClass:(Class<PINKBindCellProtocol>)cellClass;

- (void)setDataSourceSignal:(RACSignal *)sourceSignal
           selectionCommand:(RACCommand *)selection
                    cellNib:(UINib *)cellNib;

@end

//以下是截获了的方法，继承子类时可以直接重写，但还是要调用super
@interface PINKBindCollectionView (UICollectionViewDataSourceIntercept)

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface PINKBindCollectionView (UICollectionViewDelegateIntercept)

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end
