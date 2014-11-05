//
//  ProductListTableViewController.m
//  ProductHunt
//
//  Created by HuangPeng on 11/1/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "ProductListViewController.h"
#import "NIMutableTableViewModel.h"
#import "NITableViewActions.h"
#import "NINetworkImageView.h"
#import "Utility.h"
#import "ProductDetailViewController.h"

@interface PostCellObject : NICellObject
@property (nonatomic, readonly) ProductHuntPost *post;

- (id)initWithPost:(ProductHuntPost *)post;

@end

@implementation PostCellObject

- (id)initWithPost:(ProductHuntPost *)post {
    self = [super init];
    if (self) {
        _post = post;
    }
    return self;
}

- (Class)cellClass {
    return [PostCell class];
}

@end

@implementation PostCell {
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
}

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    PostCellObject *cellObject = object;
    CGFloat titleHeight = [Utility heightForText:cellObject.post.title fontSize:20 width:280];
    CGFloat subtitleHeight = [Utility heightForText:cellObject.post.subtitle fontSize:16 width:280];
    return 30 + titleHeight + subtitleHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.left = 10;
        _titleLabel.top = 10;
        _titleLabel.font = [UIFont systemFontOfSize:20];
        _titleLabel.textColor = RGBCOLOR_HEX(0xda552f);
        [self.contentView addSubview:_titleLabel];
        
        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.font = [UIFont systemFontOfSize:16];
        _subtitleLabel.left = _titleLabel.left;
        _subtitleLabel.numberOfLines = 0;
        _subtitleLabel.textColor = RGBCOLOR_HEX(0x7d7d7d);
        [self.contentView addSubview:_subtitleLabel];
    }
    return self;
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    PostCellObject *postObject = object;
    
    _titleLabel.text = postObject.post.title;
    [_titleLabel sizeToFit];
    
    _subtitleLabel.text = postObject.post.subtitle;
    _subtitleLabel.width = self.width - 2 * _subtitleLabel.left - 10;
    [_subtitleLabel sizeToFit];
    
    _subtitleLabel.top = _titleLabel.bottom + 5;
    
    return YES;
}

@end


@interface ProductListViewController () 
@property (nonatomic) NSInteger daysAgo;

@end

@implementation ProductListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.allowLoadMore = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WEAK_VAR(self);
    [self.actions attachToClass:[PostCellObject class] navigationBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
        PostCellObject *postObject = object;
        ProductDetailViewController *controller = [[ProductDetailViewController alloc] initWithPost:postObject.post];
        [_self.navigationController pushViewController:controller animated:YES];
        return NO;
    }];
    
    [ProductHuntSession registerWithAppKey:kProductHuntKey appSecret:kProductHuntSecret];
    
    UISegmentedControl *statFilter = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"All", @"Unread", @"Read", nil]];
    [statFilter addTarget:self action:@selector(filterPost) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = statFilter;
    
    statFilter.selectedSegmentIndex = 0;
    
    [self refresh];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = RGBCOLOR_HEX(0xdedede);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 320, 28)];
    label.textColor = RGBCOLOR_HEX(0x5d5d5d);
    label.text = [self.model tableView:tableView titleForHeaderInSection:section];
    [v addSubview:label];
    return v;
}

- (void)resetModelState {
    self.daysAgo = 0;
}

- (void)loadModel {
    [[ProductHuntSession sharedSession] fetchPostsDaysAgo:self.daysAgo delegate:self];
}

- (void)session:(ProductHuntSession *)session didFailLoadWithError:(NSError *)error {
    
}

- (void)session:(ProductHuntSession *)session didFinishLoadWithPosts:(NSArray *)posts onDate:(NSDate *)date {
    if (self.daysAgo == 0) {
        [self resetModel];
    }
    
    NSIndexSet *indexSet = [self.model addSectionWithTitle:[date formatWith:@"yyyy/MM/dd"]];
    [posts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.model addObject:[[PostCellObject alloc] initWithPost:obj] toSection:indexSet.firstIndex];
    }];
    
    [self reloadTableView];
    
    self.daysAgo++;
}

- (void)filterPost {
    NIDPRINTMETHODNAME();
}

@end
