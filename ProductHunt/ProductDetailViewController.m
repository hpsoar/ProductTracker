//
//  ProductDetailViewController.m
//  ProductHunt
//
//  Created by HuangPeng on 11/2/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "ProductDetailViewController.h"
#import "NINetworkImageView.h"
#import "AppDelegate.h"
#import "ProductHuntSession.h"
#import "FavorDB.h"
#import "PostCellObject.h"

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
    UIWebView *_webView;
}

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    CommentItem *item = object;
    return 16 + [Utility heightForText:item.comment.body font:[self commentFont] width:tableView.width - 40];
}

+ (UIFont *)commentFont {
    return [UIFont systemFontOfSize:15];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _webView = [[UIWebView alloc] initWithFrame:self.bounds];
        _webView.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
        _webView.scrollView.scrollEnabled = NO;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.opaque = NO;
        [self.contentView addSubview:_webView];
    }
    return self;
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (NSString *)htmlWithBody:(NSString *)body {
    NSString *html = @"<html><head></head><body>"
    @"<div style='font-size:15;color:#7d7d7d; white-space:pre-wrap;'>%@</div>"
    @"</body></html>";
    
    return DefStr(html, body);
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    CommentItem *item = object;
    
    [_webView loadHTMLString:[self htmlWithBody:item.comment.body] baseURL:nil];
    
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

@interface ProductDetailViewController () <UIWebViewDelegate, ProductHuntSessionDelegate, UMSocialUIDelegate, PostCellObjectDelegate>
@property (nonatomic, strong) NINetworkImageView *screenshotView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic) NSInteger lastCommentId;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIView *tableHeader;
@property (nonatomic, strong) LoadingView *loadingView;
@property (nonatomic, strong) UISegmentedControl *segControl;
@end

@implementation ProductDetailViewController

- (id)initWithPost:(ProductHuntPost *)post {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _post = post;
        self.allowDragRefresh = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.segControl = [[UISegmentedControl alloc] initWithItems:@[ @"Comments", @"HomePage"]];
    [self.segControl addTarget:self action:@selector(segValueChanged) forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.titleView = self.segControl;
    
    self.segControl.selectedSegmentIndex = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.segControl.selectedSegmentIndex == 0) {
        [self showComments];
    }
    else {
        [self showHomePage];
    }
}

- (UIWebView *)webView {
    if (_webView == nil) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:_webView];
        _webView.delegate = self;
        
        self.loadingView = [[LoadingView alloc] initWithFrame:CGRectMake(0, 0, self.webView.width, 44)];
        [_webView addSubview:self.loadingView];
    }
    return _webView;
}

- (void)showHomePage {
    if (self.webView.request == nil) {
        NSString *urlString = self.post.productLink;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        [self.webView loadRequest:request];
    }
    
    self.tableView.hidden = YES;
    self.webView.hidden = NO;
}

- (void)showComments {
    self.tableView.hidden = NO;
    self.webView.hidden = YES;
    
    NSInteger rows = [self.model tableView:self.tableView numberOfRowsInSection:0];
    if (rows < 2) {
        [self refresh];
    }
}

- (void)segValueChanged {
    if (self.tableView.hidden) {
        [self showComments];
    }
    else {
        [self showHomePage];
    }
}

- (void)loadModelAtPage:(NSInteger)page {
    [[ProductHuntSession sharedSession] commentsForPost:self.post.postId lastCommentId:self.lastCommentId count:5 delegate:self];
}

- (void)session:(ProductHuntSession *)session didFailLoadCommentsForPost:(NSInteger)postId withError:(NSError *)error {
    
}

- (void)session:(ProductHuntSession *)session didFinishLoadComments:(NSArray *)comments forPost:(NSInteger)postId {
    PostCellObject *object = [[PostCellObject alloc] initWithPost:self.post];
    object.delegate = self;
    [self.model addObject:object];
    
    [comments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CommentItem *item = [[CommentItem alloc] initWithComment:obj];
        [self.model addObject:item];
    }];
    
    [self.tableView reloadData];
    [self refreshCompleted];
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

- (void)didFavorPostForCell:(PostCell *)cell favor:(BOOL)favor {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)showShareOptionsForCell:(PostCell *)cell {
    [self selectCell:cell];
    
    [[ShareKit kit] sharePost:cell.post inController:self];
}

- (void)selectCell:(PostCell *)cell {
    NSIndexPath *indexPath =  [self.tableView indexPathForCell:cell];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}

@end
