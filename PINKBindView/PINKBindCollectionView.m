//
//  PINKBindCollectionView.m
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

#import <ReactiveCocoa/RACEXTScope.h>

#import "PINKBindCollectionView.h"
#import "PINKMessageInterceptor.h"
#import "PINKBindCellProtocol.h"

typedef NS_OPTIONS(NSInteger, PINKBindCollectionView_DataSource_MethodType) {
    PINKBindCollectionView_DataSource_MethodType_numberOfSectionsInCollectionView   = 1 << 0,
    PINKBindCollectionView_DataSource_MethodType_numberOfItemsInSection             = 1 << 1,
    PINKBindCollectionView_DataSource_MethodType_cellForItemAtIndexPath             = 1 << 2,
};

@interface PINKBindCollectionView ()<UICollectionViewDataSource, UICollectionViewDelegate>
{
    PINKMessageInterceptor *_dataSourceInterceptor;
    PINKMessageInterceptor *_delegateInterceptor;
    
    PINKBindCollectionView_DataSource_MethodType _dataSourceMethodType;
}

/**
 *  collectionData为nil时，若dataSource或delegate实现了对应方法，则调用。
 */
@property (nonatomic, strong) NSArray *collectionData;
@property (nonatomic, strong) RACCommand *didSelectedCommand;
@property (nonatomic, unsafe_unretained) Class<PINKBindCellProtocol> cellClass;
@property (nonatomic, strong) NSString *cellReuseIdentifier;
@property (nonatomic, strong) UINib *cellNib;

@property (nonatomic, strong) UICollectionViewCell<PINKBindCellProtocol> *cacheCell;
@property (nonatomic, strong) RACDisposable *dataSourceDisposer;

@property (nonatomic, strong) RACDisposable *dataSourceDeallocDisposer;
@property (nonatomic, strong) RACDisposable *delegateDeallocDisposer;

@end

@implementation PINKBindCollectionView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self _PINKBindCollectionView_customInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];

    if (self) {
        [self _PINKBindCollectionView_customInit];
    }

    return self;
}

- (void)dealloc
{
    [[(NSObject *)_dataSourceInterceptor.receiver rac_deallocDisposable] removeDisposable:self.dataSourceDeallocDisposer];
    [[(NSObject *)_delegateInterceptor.receiver rac_deallocDisposable] removeDisposable:self.delegateDeallocDisposer];
}

#pragma mark - Private Initialize
- (void)_PINKBindCollectionView_customInit
{
    _cellReuseIdentifier = @"PINKBindCollectionViewCell";
    _autoCheckDataSource = YES;
    _autoDeselect = YES;
    _autoReload = YES;
    
    _dataSourceInterceptor = [[PINKMessageInterceptor alloc] init];
    _dataSourceInterceptor.middleMan = self;
    _dataSourceInterceptor.receiver = [super dataSource];
    [super setDataSource:(id<UICollectionViewDataSource>)_dataSourceInterceptor];
    
    _delegateInterceptor = [[PINKMessageInterceptor alloc] init];
    _delegateInterceptor.middleMan = self;
    _delegateInterceptor.receiver = [super delegate];
    [super setDelegate:(id<UICollectionViewDelegate>)_delegateInterceptor];
}

#pragma mark - Overwrite DataSource
- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource
{
    [[(NSObject *)_dataSourceInterceptor.receiver rac_deallocDisposable] removeDisposable:self.dataSourceDeallocDisposer];
    _dataSourceInterceptor.receiver = dataSource;
    //UICollectionViewDataSource有类似缓存机制优化，所以先设置nil
    [super setDataSource:nil];
    [super setDataSource:(id<UICollectionViewDataSource>)_dataSourceInterceptor];
    
    [self updateDataSourceMethodType];
    
    if (dataSource) {
        @weakify(self);
        self.dataSourceDeallocDisposer = [RACDisposable disposableWithBlock:^{
            @strongify(self);
            self.dataSource = nil;
        }];
        [[(NSObject *)dataSource rac_deallocDisposable] addDisposable:self.dataSourceDeallocDisposer];
    }
}

- (id<UICollectionViewDataSource>)realDataSource
{
    return _dataSourceInterceptor.receiver;
}

#pragma mark - Overwrite Delegate
- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
    [[(NSObject *)_delegateInterceptor.receiver rac_deallocDisposable] removeDisposable:self.delegateDeallocDisposer];
    _delegateInterceptor.receiver = delegate;
    
    [super setDelegate:nil];
    [super setDelegate:(id<UICollectionViewDelegate>)_delegateInterceptor];
    
    if (delegate) {
        @weakify(self);
        self.delegateDeallocDisposer = [RACDisposable disposableWithBlock:^{
            @strongify(self);
            self.delegate = nil;
        }];
        [[(NSObject *)delegate rac_deallocDisposable] addDisposable:self.delegateDeallocDisposer];
    }
}

- (id<UICollectionViewDelegate>)realDelegate
{
    return _delegateInterceptor.receiver;
}

#pragma mark - 缓存DataSource方法
- (void)updateDataSourceMethodType
{
    _dataSourceMethodType = 0;
    
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        _dataSourceMethodType |= PINKBindCollectionView_DataSource_MethodType_numberOfSectionsInCollectionView;
    }
    
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
        _dataSourceMethodType |= PINKBindCollectionView_DataSource_MethodType_numberOfItemsInSection;
    }
    
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(collectionView:cellForItemAtIndexPath:)]) {
        _dataSourceMethodType |= PINKBindCollectionView_DataSource_MethodType_cellForItemAtIndexPath;
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (!_collectionData &&
        _dataSourceMethodType & PINKBindCollectionView_DataSource_MethodType_numberOfSectionsInCollectionView) {
        return [_dataSourceInterceptor.receiver numberOfSectionsInCollectionView:collectionView];
    } else
        return _collectionData.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (!_collectionData &&
        _dataSourceMethodType & PINKBindCollectionView_DataSource_MethodType_numberOfItemsInSection) {
        return [_dataSourceInterceptor.receiver collectionView:collectionView numberOfItemsInSection:section];
    } else
        return [_collectionData[section] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_collectionData &&
        _dataSourceMethodType & PINKBindCollectionView_DataSource_MethodType_cellForItemAtIndexPath) {
        return [_dataSourceInterceptor.receiver collectionView:collectionView cellForItemAtIndexPath:indexPath];
    } else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:_cellReuseIdentifier forIndexPath:indexPath];
        [(id<PINKBindCellProtocol>)cell bindCellViewModel:_collectionData[indexPath.section][indexPath.item]
                                                indexPath:indexPath
                                              displayFlag:YES];
        
        return cell;
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_autoDeselect) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
    if (_collectionData && _didSelectedCommand) {
        if (_collectionData.count > indexPath.section) {
            NSArray *subArray = _collectionData[indexPath.section];
            if (subArray.count > indexPath.item) {
                [_didSelectedCommand execute:_collectionData[indexPath.section][indexPath.item]];
            }
        }
    }
    
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
        [_delegateInterceptor.receiver collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

#pragma mark - API
- (void)setDataSourceSignal:(RACSignal *)sourceSignal
           selectionCommand:(RACCommand *)selection
                  cellClass:(Class<PINKBindCellProtocol>)cellClass
{
    self.cellClass = cellClass;
    self.cellNib = nil;
    self.didSelectedCommand = selection;
    [self configCellReuseIdentifier];
    
    @weakify(self);
    [self.dataSourceDisposer dispose];
    self.dataSourceDisposer =
    [[sourceSignal takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(NSArray *source) {
         @strongify(self);
         self.collectionData = source;
         if (self.isAutoReload)
             [self reloadData];
     }];
}

- (void)setDataSourceSignal:(RACSignal *)sourceSignal
           selectionCommand:(RACCommand *)selection
                    cellNib:(UINib *)cellNib
{
    self.cellClass = nil;
    self.cellNib = cellNib;
    self.didSelectedCommand = selection;
    [self configCellReuseIdentifier];
    
    @weakify(self);
    [self.dataSourceDisposer dispose];
    self.dataSourceDisposer =
    [[sourceSignal takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(NSArray *source) {
         @strongify(self);
         self.collectionData = source;
         if (self.isAutoReload)
             [self reloadData];
     }];
}

- (void)configCellReuseIdentifier
{
    UICollectionViewCell *oneCell = nil;
    if (_cellClass) {
        oneCell = [[(Class)_cellClass alloc] init];
        self.cellReuseIdentifier = oneCell.reuseIdentifier;
        
        [self registerClass:_cellClass forCellWithReuseIdentifier:_cellReuseIdentifier];
    } else if (_cellNib) {
        oneCell = [_cellNib instantiateWithOwner:nil options:nil][0];
        self.cellReuseIdentifier = oneCell.reuseIdentifier;
        
        [self registerNib:_cellNib forCellWithReuseIdentifier:_cellReuseIdentifier];
    }
}

#pragma mark - Properties
- (void)setCollectionData:(NSArray *)collectionData
{
    if (_autoCheckDataSource &&
        collectionData.count &&
        ![collectionData[0] isKindOfClass:[NSArray class]]) {
        _collectionData = @[collectionData];
    } else {
        _collectionData = collectionData;
    }
}

- (void)setCellReuseIdentifier:(NSString *)cellReuseIdentifier
{
    if ([cellReuseIdentifier isKindOfClass:[NSString class]] &&
        cellReuseIdentifier.length) {
        _cellReuseIdentifier = cellReuseIdentifier;
    }
}

@end
