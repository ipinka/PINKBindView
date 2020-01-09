//
//  PINKBindTableView.m
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

#import <ReactiveCocoa/RACEXTScope.h>

#import "PINKBindTableView.h"
#import "PINKMessageInterceptor.h"
#import "PINKBindCellProtocol.h"

typedef NS_OPTIONS(NSInteger, PINKBindTableView_DataSource_MethodType) {
    PINKBindTableView_DataSource_MethodType_numberOfSectionsInTableView  = 1 << 0,
    PINKBindTableView_DataSource_MethodType_numberOfRowsInSection        = 1 << 1,
    PINKBindTableView_DataSource_MethodType_cellForRowAtIndexPath        = 1 << 2,
};


typedef NS_OPTIONS(NSInteger, PINKBindTableView_Delegate_MethodType) {
    PINKBindTableView_Delegate_MethodType_heightForRowAtIndexPath  = 1 << 0,
};

@interface PINKBindTableView ()<UITableViewDataSource, UITableViewDelegate>
{
    PINKMessageInterceptor *_dataSourceInterceptor;
    PINKMessageInterceptor *_delegateInterceptor;
    
    PINKBindTableView_DataSource_MethodType _dataSourceMethodType;
    PINKBindTableView_Delegate_MethodType _delegateMethodType;
}

/**
 *  tableData为nil时，若dataSource或delegate实现了对应方法，则调用。
 */
@property (nonatomic, strong) NSArray *tableData;
@property (nonatomic, strong) RACCommand *didSelectedCommand;
@property (nonatomic, unsafe_unretained) Class<PINKBindCellProtocol> cellClass;
@property (nonatomic, strong) UINib *cellNib;
@property (nonatomic, strong) NSString *cellReuseIdentifier;
@property (nonatomic, copy) PINKBindTableViewCreateCellBlock createCellBlock;

@property (nonatomic, strong) UITableViewCell<PINKBindCellProtocol> *cacheCell;
@property (nonatomic, strong) RACDisposable *dataSourceDisposer;

@property (nonatomic, strong) RACDisposable *dataSourceDeallocDisposer;
@property (nonatomic, strong) RACDisposable *delegateDeallocDisposer;

@end

@implementation PINKBindTableView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self _PINKBindTableView_customInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    
    if (self) {
        [self _PINKBindTableView_customInit];
    }
    
    return self;
}

- (void)dealloc
{
    [[(NSObject *)_dataSourceInterceptor.receiver rac_deallocDisposable] removeDisposable:self.dataSourceDeallocDisposer];
    [[(NSObject *)_delegateInterceptor.receiver rac_deallocDisposable] removeDisposable:self.delegateDeallocDisposer];
}

#pragma mark - Private Initialize
- (void)_PINKBindTableView_customInit
{
    _autoCheckDataSource = YES;
    _autoDeselect = YES;
    _autoReload = YES;
    
    _dataSourceInterceptor = [[PINKMessageInterceptor alloc] init];
    _dataSourceInterceptor.middleMan = self;
    _dataSourceInterceptor.receiver = [super dataSource];
    [super setDataSource:(id<UITableViewDataSource>)_dataSourceInterceptor];
    
    _delegateInterceptor = [[PINKMessageInterceptor alloc] init];
    _delegateInterceptor.middleMan = self;
    _delegateInterceptor.receiver = [super delegate];
    [super setDelegate:(id<UITableViewDelegate>)_delegateInterceptor];
}

#pragma mark - Overwrite DataSource
- (void)setDataSource:(id<UITableViewDataSource>)dataSource
{
    [[(NSObject *)_dataSourceInterceptor.receiver rac_deallocDisposable] removeDisposable:self.dataSourceDeallocDisposer];
    _dataSourceInterceptor.receiver = dataSource;
    //UITableViewDataSource有类似缓存机制优化，所以先设置nil
    [super setDataSource:nil];
    [super setDataSource:(id<UITableViewDataSource>)_dataSourceInterceptor];
    
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

- (id<UITableViewDataSource>)realDataSource
{
    return _dataSourceInterceptor.receiver;
}

#pragma mark - Overwrite Delegate
- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
    [[(NSObject *)_delegateInterceptor.receiver rac_deallocDisposable] removeDisposable:self.delegateDeallocDisposer];
    _delegateInterceptor.receiver = delegate;
    
    [super setDelegate:nil];
    [super setDelegate:(id<UITableViewDelegate>)_delegateInterceptor];
    
    [self updateDelegateMethodType];
    
    if (delegate) {
        @weakify(self);
        self.delegateDeallocDisposer = [RACDisposable disposableWithBlock:^{
            @strongify(self);
            self.delegate = nil;
        }];
        [[(NSObject *)delegate rac_deallocDisposable] addDisposable:self.delegateDeallocDisposer];
    }
}

- (id<UITableViewDelegate>)realDelegate
{
    return _delegateInterceptor.receiver;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!_tableData &&
        _dataSourceMethodType & PINKBindTableView_DataSource_MethodType_numberOfSectionsInTableView) {
        return [_dataSourceInterceptor.receiver numberOfSectionsInTableView:tableView];
    } else
        return _tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!_tableData &&
        _dataSourceMethodType & PINKBindTableView_DataSource_MethodType_numberOfRowsInSection) {
        return [_dataSourceInterceptor.receiver tableView:tableView numberOfRowsInSection:section];
    } else
        return [_tableData[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_tableData &&
        _dataSourceMethodType & PINKBindTableView_DataSource_MethodType_cellForRowAtIndexPath) {
        return [_dataSourceInterceptor.receiver tableView:tableView cellForRowAtIndexPath:indexPath];
    } else {
        UITableViewCell *cell = nil;
        if (_createCellBlock) {
            cell = _createCellBlock(indexPath, NO);
            if (!cell) {
                cell = [tableView dequeueReusableCellWithIdentifier:_cellReuseIdentifier];
            }
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:_cellReuseIdentifier];
        }
        
        CGRect realFrame = cell.frame;
        realFrame.size.width = self.frame.size.width;
        cell.frame = realFrame;
        [(id<PINKBindCellProtocol>)cell bindCellViewModel:_tableData[indexPath.section][indexPath.row]
                                                indexPath:indexPath
                                              displayFlag:YES];
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_autoDeselect) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    if (_tableData && _didSelectedCommand) {
        if (_tableData.count > indexPath.section) {
            NSArray *subArray = _tableData[indexPath.section];
            if (subArray.count > indexPath.row) {
                [_didSelectedCommand execute:_tableData[indexPath.section][indexPath.row]];
            }
        }
    }
    
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [_delegateInterceptor.receiver tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_autoCellHeight && _cacheCell) {
        CGRect newCellFrame = _cacheCell.frame;
        newCellFrame.size.width = self.frame.size.width;
        _cacheCell.frame = newCellFrame;
        
        [_cacheCell bindCellViewModel:_tableData[indexPath.section][indexPath.row]
                            indexPath:indexPath
                          displayFlag:NO];
        return [_cacheCell cellHeight];
    }
    
    if (_delegateMethodType & PINKBindTableView_Delegate_MethodType_heightForRowAtIndexPath) {
        return [_delegateInterceptor.receiver tableView:tableView
                                heightForRowAtIndexPath:indexPath];
    }
    
    return tableView.rowHeight;
}

#pragma mark - 缓存DataSource方法
- (void)updateDataSourceMethodType
{
    _dataSourceMethodType = 0;
    
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        _dataSourceMethodType |= PINKBindTableView_DataSource_MethodType_numberOfSectionsInTableView;
    }
    
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
        _dataSourceMethodType |= PINKBindTableView_DataSource_MethodType_numberOfRowsInSection;
    }
    
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
        _dataSourceMethodType |= PINKBindTableView_DataSource_MethodType_cellForRowAtIndexPath;
    }
}

#pragma mark - 缓存Delegate方法
- (void)updateDelegateMethodType
{
    _delegateMethodType = 0;
    
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        _delegateMethodType |= PINKBindTableView_Delegate_MethodType_heightForRowAtIndexPath;
    }
}

#pragma mark - API
- (void)setDataSourceSignal:(RACSignal *)sourceSignal
           selectionCommand:(RACCommand *)selection
                  cellClass:(Class<PINKBindCellProtocol>)cellClass
{
    self.cellClass = cellClass;
    self.cellNib = nil;
    self.createCellBlock = nil;
    self.didSelectedCommand = selection;
    [self configCellReuseIdentifierAndCellHeight];
    [self _PINKBindTableView_configDataSource:sourceSignal];
}

- (void)setDataSourceSignal:(RACSignal *)sourceSignal
           selectionCommand:(RACCommand *)selection
                    cellNib:(UINib *)cellNib
{
    self.cellClass = nil;
    self.cellNib = cellNib;
    self.createCellBlock = nil;
    self.didSelectedCommand = selection;
    [self configCellReuseIdentifierAndCellHeight];
    [self _PINKBindTableView_configDataSource:sourceSignal];
}

- (void)setDataSourceSignal:(RACSignal *)sourceSignal
           selectionCommand:(RACCommand *)selection
            createCellBlock:(PINKBindTableViewCreateCellBlock)createCellBlock
{
    self.cellClass = nil;
    self.cellNib = nil;
    self.createCellBlock = createCellBlock;
    self.didSelectedCommand = selection;
    [self configCellReuseIdentifierAndCellHeight];
    [self _PINKBindTableView_configDataSource:sourceSignal];
}

- (void)configCellReuseIdentifierAndCellHeight
{
    UITableViewCell *oneCell = nil;
    if (_cellClass) {
        oneCell = [[(Class)_cellClass alloc] init];
        _cellReuseIdentifier = oneCell.reuseIdentifier;
        [self registerClass:_cellClass forCellReuseIdentifier:_cellReuseIdentifier];
    } else if (_cellNib) {
        oneCell = [_cellNib instantiateWithOwner:nil options:nil][0];
        _cellReuseIdentifier = oneCell.reuseIdentifier;
        [self registerNib:_cellNib forCellReuseIdentifier:_cellReuseIdentifier];
    } else if (_createCellBlock) {
        oneCell = _createCellBlock([NSIndexPath indexPathForRow:0 inSection:0], YES);
        _cellReuseIdentifier = oneCell.reuseIdentifier;
    }
    self.rowHeight = oneCell.frame.size.height;
    
    if (_autoCellHeight &&
        [oneCell respondsToSelector:@selector(cellHeight)]) {
        _cacheCell = (UITableViewCell<PINKBindCellProtocol> *)oneCell;
    }
}

#pragma mark - Properties
- (void)setTableData:(NSArray *)tableData
{
    if (_autoCheckDataSource &&
        tableData.count &&
        ![tableData[0] isKindOfClass:[NSArray class]]) {
        _tableData = @[tableData];
    } else {
        _tableData = tableData;
    }
}

- (void)setAutoCellHeight:(BOOL)autoCellHeight
{
    _autoCellHeight = autoCellHeight;
    
    if (_autoCellHeight) {
        if (_cellClass) {
            _cacheCell = [[(Class)_cellClass alloc] init];
        } else if (_cellNib) {
            _cacheCell = [_cellNib instantiateWithOwner:nil options:nil][0];
        } else if (_createCellBlock) {
            _cacheCell = (UITableViewCell<PINKBindCellProtocol> *)_createCellBlock([NSIndexPath indexPathForRow:0 inSection:0], YES);
        }
        [self reloadData];
    } else {
        _cacheCell = nil;
    }
}

- (void)_PINKBindTableView_configDataSource:(RACSignal *)sourceSignal
{
    @weakify(self);
    [self.dataSourceDisposer dispose];
    self.dataSourceDisposer =
    [[sourceSignal takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(NSArray *source) {
         @strongify(self);
         self.tableData = source;
         if (self.isAutoReload)
             [self reloadData];
     }];
}

@end
