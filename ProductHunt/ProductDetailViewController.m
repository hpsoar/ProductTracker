//
//  ProductDetailViewController.m
//  ProductHunt
//
//  Created by HuangPeng on 11/2/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "ProductDetailViewController.h"
#import "NINetworkImageView.h"
#import "Utility.h"

@interface CommentItem : NICellObject
@property (nonatomic, readonly) ProductHuntComment *comment;

- (id)initWithComment:(ProductHuntComment *)comment;
@end

@implementation CommentItem

- (id)initWithComment:(ProductHuntComment *)comment {
    self = [super initWithCellClass:[CommentItemCell class]];
    if (self) {
        _comment = comment;
    }
    return self;
}

@end

@implementation CommentItemCell {
    UILabel *_bodyLabel;
}

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    CommentItem *item = object;
    return 16 + [Utility heightForText:item.comment.body font:[self commentFont] width:300];
}

+ (UIFont *)commentFont {
    return [UIFont systemFontOfSize:15];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _bodyLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 8, self.width - 40, 0)];
        _bodyLabel.textColor = RGBCOLOR_HEX(0x7d7d7d);
        _bodyLabel.font = [CommentItemCell commentFont];
        _bodyLabel.numberOfLines = 0;
        [self.contentView addSubview:_bodyLabel];
    }
    return self;
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    CommentItem *item = object;
    _bodyLabel.text = item.comment.body;
    _bodyLabel.width = self.width - 40;
    [_bodyLabel sizeToFit];
    return YES;
}

@end

@interface LoadingView : UIView
- (void)show;
- (void)hide;
@end

@implementation LoadingView {
    UIActivityIndicatorView *_activityIndicator;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.center = CGPointMake(self.width / 2, self.height / 2);
        [self addSubview:_activityIndicator];
        
    }
    return self;
}

- (void)show {
    self.hidden = NO;
    [_activityIndicator startAnimating];
}

- (void)hide {
    self.hidden = YES;
    [_activityIndicator stopAnimating];
}

@end

@interface ProductDetailViewController () <UIWebViewDelegate, ProductHuntSessionDelegate, NINetworkImageViewDelegate>
@property (nonatomic, strong) NINetworkImageView *screenshotView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic) NSInteger lastCommentId;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIView *tableHeader;
@property (nonatomic, strong) LoadingView *loadingView;
@end

@implementation ProductDetailViewController

- (id)initWithPost:(ProductHuntPost *)post {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _post = post;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableHeader = [self creatTopView];
    //self.tableView.tableHeaderView = [self creatTopView];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    UISegmentedControl *segControl = [[UISegmentedControl alloc] initWithItems:@[ @"Comments", @"HomePage"]];
    [segControl addTarget:self action:@selector(segValueChanged) forControlEvents:UIControlEventValueChanged];
    
    segControl.selectedSegmentIndex = 0;
    
    self.navigationItem.titleView = segControl;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
    
    [self refresh];
    
}

- (void)segValueChanged {
    self.tableView.hidden = !self.tableView.hidden;
    
    if (self.tableView.hidden && self.webView == nil) {
        self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:self.webView];
        self.webView.delegate = self;
        
        self.loadingView = [[LoadingView alloc] initWithFrame:CGRectMake(0, 0, self.webView.width, 44)];
        [self.webView addSubview:self.loadingView];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.post.productLink]];
        [self.webView loadRequest:request];
    }
    self.webView.hidden = !self.tableView.hidden;
}

- (void)share {
    
}

- (UIView *)creatTopView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.height, 0)];

    self.screenshotView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 250)];
    self.screenshotView.contentMode = UIViewContentModeScaleAspectFill;
    self.screenshotView.delegate = self;
    [self.screenshotView setPathToNetworkImage:self.post.imageLink];
    [headerView addSubview:self.screenshotView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.screenshotView.bottom + 5, self.view.width - 20, 30)];
    self.titleLabel.text = self.post.title;
    self.titleLabel.textColor = [UIColor orangeColor];
    self.titleLabel.numberOfLines = 0;
    [self.titleLabel sizeToFit];
    [headerView addSubview:self.titleLabel];
    
    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.titleLabel.bottom + 5, self.view.width - 20, 0)];
    self.subtitleLabel.textColor = RGBCOLOR_HEX(0x3d3d3d);
    self.subtitleLabel.text = self.post.subtitle;
    self.subtitleLabel.numberOfLines = 0;
    [self.subtitleLabel sizeToFit];
    [headerView addSubview:self.subtitleLabel];
  
    headerView.height = self.subtitleLabel.bottom;
    
    return headerView;
}

- (void)networkImageView:(NINetworkImageView *)imageView didLoadImage:(UIImage *)image {
    self.tableView.tableHeaderView = self.tableHeader;
}

- (void)networkImageView:(NINetworkImageView *)imageView didFailWithError:(NSError *)error {
    NIDPRINT(@"%@", error);
}

- (void)resetModelState {
    self.lastCommentId = 0;
}

- (void)loadModel {
    [[ProductHuntSession sharedSession] commentsForPost:self.post.postId lastCommentId:self.lastCommentId count:5 delegate:self];
}

- (void)session:(ProductHuntSession *)session didFailLoadCommentsForPost:(NSInteger)postId withError:(NSError *)error {
    
}

- (void)session:(ProductHuntSession *)session didFinishLoadComments:(NSArray *)comments forPost:(NSInteger)postId {
    if (self.lastCommentId == 0) {
        [self resetModel];
    }
    
    [comments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CommentItem *item = [[CommentItem alloc] initWithComment:obj];
        [self.model addObject:item];
    }];
    
    self.lastCommentId = [comments.firstObject commentId];
    
    [self reloadTableView];
}

#pragma mark - webview
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NIDPRINT(@"%@", error);
    [self.loadingView hide];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
  //  [self.loadingView hide];
}
- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.loadingView show];
}
@end
