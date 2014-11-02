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
    return 30 + [self heightForText:cellObject.post.title fontSize:20] + [self heightForText:cellObject.post.subtitle fontSize:16];
    return 100;
}

+ (CGFloat)heightForText:(NSString *)text fontSize:(CGFloat)fontSize {
    NSDictionary *attrs = @{ NSFontAttributeName: [UIFont systemFontOfSize:fontSize] };
    CGRect rect = [text boundingRectWithSize:CGSizeMake(280, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil];
    return rect.size.height;
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
@property (nonatomic, strong) NIMutableTableViewModel *model;
@property (nonatomic, strong) NITableViewActions *actions;
@property (nonatomic, strong) NICellFactory *cellFactory;
@property (nonatomic) NSInteger daysAgo;

@end

@implementation ProductListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.headerView = [[ActivityView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    
    self.footerView = [[ActivityView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    
    self.footerView.backgroundColor = [UIColor greenColor];
    
    self.cellFactory = [NICellFactory new];
    
    self.model = [[NIMutableTableViewModel alloc] initWithDelegate:self.cellFactory];
    
    self.tableView.dataSource = self.model;
    
    self.actions = [[NITableViewActions alloc] initWithTarget:self];
    [self.actions forwardingTo:self];
    self.tableView.delegate = self.actions;
    
    WEAK_VAR(self);
    [self.actions attachToClass:[PostCellObject class] navigationBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
        PostCellObject *postObject = object;
        ProductDetailViewController *controller = [[ProductDetailViewController alloc] initWithPost:postObject.post];
        [_self.navigationController pushViewController:controller animated:YES];
        return NO;
    }];
    
    [ProductHuntSession registerWithAppKey:kProductHuntKey appSecret:kProductHuntSecret];
    
    [self refresh];
    
    UISegmentedControl *statFilter = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"All", @"Unread", @"Read", nil]];
    [statFilter sizeToFit];
    [statFilter addTarget:self action:@selector(filterPost) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = statFilter;
    
    statFilter.selectedSegmentIndex = 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.cellFactory tableView:tableView heightForRowAtIndexPath:indexPath model:self.model];
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

- (void)refresh {
    [super refresh];
    self.daysAgo = 0;
    [self loadModel];
}

- (void)loadMore {
    [super loadMore];
    [self loadModel];
}

- (void)loadModel {
    [[ProductHuntSession sharedSession] fetchPostsDaysAgo:self.daysAgo delegate:self];
}

- (void)session:(ProductHuntSession *)session didFailLoadWithError:(NSError *)error {
    
}

- (void)session:(ProductHuntSession *)session didFinishLoadWithPosts:(NSArray *)posts onDate:(NSDate *)date {
    if (self.daysAgo == 0) {
        self.model = [[NIMutableTableViewModel alloc] initWithDelegate:self.cellFactory];
        self.tableView.dataSource = self.model;
    }
    
    NSIndexSet *indexSet = [self.model addSectionWithTitle:DefStr(@"%@", date)];
    //NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:posts.count];
    [posts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
   //     [items addObject:[[PostCellObject alloc] initWithPost:obj]];
        [self.model addObject:[[PostCellObject alloc] initWithPost:obj] toSection:indexSet.firstIndex];
    }];
    
    [self.tableView reloadData];
    
    if (self.isRefreshing) {
        [self refreshCompleted];
    }
    
    if (self.isLoadingMore) {
        [self loadMoreCompleted];
    }
    
    self.daysAgo++;
}

- (void)filterPost {
    NIDPRINTMETHODNAME();
}

@end
