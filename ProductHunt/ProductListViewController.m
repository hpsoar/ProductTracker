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
#import "AppDelegate.h"

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
    NINetworkImageView *_thumbnailView;
    PostCellObject *_object;
    
    UILabel *_popularityLabel;
}

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    PostCellObject *cellObject = object;
    CGFloat titleHeight = [Utility heightForText:cellObject.post.title fontSize:20 width:280];
    CGFloat subtitleHeight = [Utility heightForText:cellObject.post.subtitle fontSize:16 width:280];
    return 30 + titleHeight + subtitleHeight + 210 + 20;
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
        
        _popularityLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _popularityLabel.font = [UIFont systemFontOfSize:12];
        _popularityLabel.left = _titleLabel.left;
        _popularityLabel.textColor = [UIColor orangeColor];
        [self.contentView addSubview:_popularityLabel];
        
        _thumbnailView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(10, 0, self.width - 20, 210)];
        self.contentView.layer.cornerRadius = 3;
        self.contentView.layer.borderColor = RGBCOLOR_HEX(0xd7d7d7).CGColor;
        self.contentView.layer.borderWidth = 0.5;
        _thumbnailView.clipsToBounds = YES;
        _thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_thumbnailView];
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showShareView)];
        swipe.direction = UISwipeGestureRecognizerDirectionLeft;
        self.contentView.userInteractionEnabled = YES;
        [self.contentView addGestureRecognizer:swipe];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(self.width - 50, 5, 44, 44)];
        [btn setImage:[UIImage imageNamed:@"share-icon.png"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(showShareView) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:btn];
    }
    return self;
}

- (ProductHuntPost *)post {
    return _object.post;
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    _object = object;
    
    _titleLabel.text = self.post.title;
    [_titleLabel sizeToFit];
    
    _subtitleLabel.text = self.post.subtitle;
    _subtitleLabel.width = self.width - 2 * _subtitleLabel.left - 10;
    [_subtitleLabel sizeToFit];
    
    _subtitleLabel.top = _titleLabel.bottom + 5;
    
    _popularityLabel.text = DefStr(@"%d votes  %d comments", self.post.voteCount, self.post.commentCount);
    [_popularityLabel sizeToFit];
    _popularityLabel.top = _subtitleLabel.bottom + 2;
    
    if (self.post.image) {
        _thumbnailView.image = self.post.image;
    }
    else {
        _thumbnailView.image = [UIImage imageNamed:@"default-image.png"];
    }
    [_thumbnailView setPathToNetworkImage:self.post.imageLink];
    _thumbnailView.top = _popularityLabel.bottom + 5;
    
    NIDPRINT(@"%@", self.post.imageLink);
    
    return YES;
}

- (void)showShareView {
    [_object.delegate showShareOptionsForCell:self];
}

@end


@interface ProductListViewController () <PostCellObjectDelegate, UMSocialUIDelegate>
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
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = @"Products";
    [titleLabel sizeToFit];
    titleLabel.textColor = [UIColor orangeColor];
    self.navigationItem.titleView = titleLabel;
    
   // self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search)];
    
    WEAK_VAR(self);
    [self.actions attachToClass:[PostCellObject class] tapBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
        PostCellObject *postObject = object;
        ProductDetailViewController *controller = [[ProductDetailViewController alloc] initWithPost:postObject.post];
        [_self.navigationController pushViewController:controller animated:YES];
        return NO;
    }];
    
    [ProductHuntSession registerWithAppKey:kProductHuntKey appSecret:kProductHuntSecret];
    
    NSDictionary *posts = [[ProductHuntSession sharedSession] queryLatestCachedPosts];
    
    NSArray *dates = [posts.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    for (NSDate *date in dates) {
        [self addPosts:posts[date] forDate:date];
    }
    
    [self refresh];
    
    [self.tableView reloadData];
}

- (void)loadView {
    [super loadView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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
    
    [self addPosts:posts forDate:date];
    
    [self reloadTableView];
    
    self.daysAgo++;
}

- (void)addPosts:(NSArray *)posts forDate:(NSDate *)date {
    NSIndexSet *indexSet = [self.model addSectionWithTitle:[date formatWith:@"yyyy-MM-dd"]];
    [posts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PostCellObject *object = [[PostCellObject alloc] initWithPost:obj];
        object.delegate = self;
        [self.model addObject:object toSection:indexSet.firstIndex];
    }];
}

- (void)filterPost {
    NIDPRINTMETHODNAME();
}

- (void)search {
    
}

- (void)showShareOptionsForCell:(PostCell *)cell {
    NSIndexPath *indexPath =  [self.tableView indexPathForCell:cell];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    
    ProductHuntPost *post = cell.post;
    NSArray *snsNames = @[ UMShareToSina, UMShareToTencent, UMShareToWechatSession, UMShareToWechatTimeline, UMShareToWechatFavorite, UMShareToQQ, UMShareToQzone, UMShareToEmail, UMShareToSms];
    NSString *text = DefStr(@"%@: %@\n %@", post.title, post.subtitle, post.productLink);
    [UMSocialSnsService presentSnsIconSheetView:self appKey:UmengAppkey shareText:text shareImage:post.image shareToSnsNames:snsNames delegate:self];
}

@end
