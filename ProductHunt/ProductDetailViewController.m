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

@interface ProductDetailViewController () <UIWebViewDelegate, ProductHuntSessionDelegate, NINetworkImageViewDelegate, UMSocialUIDelegate>
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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateRightBarButtons];
    
    self.tableHeader = [self createTopView];
    if (self.screenshotView.image) {
        self.tableView.tableHeaderView = self.tableHeader;
    }
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.segControl = [[UISegmentedControl alloc] initWithItems:@[ @"Comments", @"HomePage"]];
    [self.segControl addTarget:self action:@selector(segValueChanged) forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.titleView = self.segControl;
    
    [self showComments];
    
    self.segControl.selectedSegmentIndex = 0;
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    self.tableView.userInteractionEnabled = YES;
    [self.tableView addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    self.webView.userInteractionEnabled = YES;
    [self.webView addGestureRecognizer:swipeRight];
}

- (void)updateRightBarButtons {
    NSString *favorIcon = [[FavorDB sharedDB] isPostFavored:self.post.postId] ? @"icon-favored.png": @"icon-favor.png";
    UIButton *favorBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [favorBtn setImage:[UIImage imageNamed:favorIcon] forState:UIControlStateNormal];
    [favorBtn addTarget:self action:@selector(favorPost) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *favorItem = [[UIBarButtonItem alloc] initWithCustomView:favorBtn];
    
    UIButton *shareBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [shareBtn setImage:[UIImage imageNamed:@"icon-share.png"] forState:UIControlStateNormal];
    [shareBtn addTarget:self action:@selector(sharePost) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithCustomView:shareBtn];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                       target:nil action:nil];
    negativeSpacer.width = -8;
    
    self.navigationItem.rightBarButtonItems = @[ negativeSpacer, shareItem, favorItem ];
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
    if ([self.model tableView:self.tableView numberOfRowsInSection:0] == 0) {
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

- (void)swipeRight {
    if (self.segControl.selectedSegmentIndex == 0) {
        self.segControl.selectedSegmentIndex = 1;
        [self segValueChanged];
    }
}

- (void)swipeLeft {
    if (self.segControl.selectedSegmentIndex == 1) {
        self.segControl.selectedSegmentIndex = 0;
        [self segValueChanged];
    }
}

- (void)didSelectSocialPlatform:(NSString *)platformName withSocialData:(UMSocialData *)socialData {
    
}

-(void)didCloseUIViewController:(UMSViewControllerType)fromViewControllerType
{
    NSLog(@"didClose is %d",fromViewControllerType);
}

//下面得到分享完成的回调
-(void)didFinishGetUMSocialDataInViewController:(UMSocialResponseEntity *)response
{
    NSLog(@"didFinishGetUMSocialDataInViewController with response is %@",response);
    //根据`responseCode`得到发送结果,如果分享成功
    if(response.responseCode == UMSResponseCodeSuccess)
    {
        //得到分享到的微博平台名
        NSLog(@"share to sns name is %@",[[response.data allKeys] objectAtIndex:0]);
    }
}

- (UIView *)createTopView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];

    self.screenshotView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 250)];
    self.screenshotView.contentMode = UIViewContentModeScaleAspectFill;
    if (self.post.image) {
        self.screenshotView.image = self.post.image;
    }
    else {
        self.screenshotView.delegate = self;
        [self.screenshotView setPathToNetworkImage:self.post.imageLink];
    }
    
    self.screenshotView.centerX = self.view.width / 2;
    [headerView addSubview:self.screenshotView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.screenshotView.bottom + 5, self.view.width - 20, 30)];
    self.titleLabel.text = self.post.title;
    self.titleLabel.textColor = RGBCOLOR_HEX(0xda552f);
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

- (void)favorPost {
    if ([[FavorDB sharedDB] isPostFavored:self.post.postId]) {
        [[FavorDB sharedDB] unfavorPostWithId:self.post.postId];
    }
    else {
        [[FavorDB sharedDB] favorPost:self.post];
    }
    [self updateRightBarButtons];
}

- (void)sharePost {
    [[ShareKit kit] sharePost:self.post inController:self];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.tableView reloadData];
    
    CGRect bounds = [[UIScreen mainScreen] bounds]; // portrait bounds
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        bounds.size = CGSizeMake(bounds.size.height, bounds.size.width);
    }
    
    CGFloat centerX;
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        centerX = bounds.size.height / 2;
    }
    else {
        centerX = bounds.size.width / 2;
    }
    
    self.screenshotView.centerX = centerX;
}

@end
