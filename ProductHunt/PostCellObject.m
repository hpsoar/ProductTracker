//
//  PostCellObject.m
//  ProductHunt
//
//  Created by HuangPeng on 11/19/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "PostCellObject.h"
#import "NINetworkImageView.h"
#import "FavorDB.h"

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

- (BOOL)favored {
    return [[FavorDB sharedDB] isPostFavored:self.post.postId];
}

@end

@interface MyTextView : UITextView <UITextViewDelegate>

@end

@implementation MyTextView {
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        self.inputView = [[UIView alloc] initWithFrame:CGRectZero];
        self.textContainerInset = UIEdgeInsetsZero;
        self.scrollEnabled = NO;
    }
    return self;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copy:) || action == @selector(selectAll:) || action == @selector(select:)) {
        return YES;
    }
    return NO;
}

- (void)copy:(id)sender {
    if (self.selectedRange.length == 0) {
        [self select:nil];
    }
    [super copy:sender];
}

@end

@interface PostCell () <UIAlertViewDelegate, UIGestureRecognizerDelegate>

@end

@implementation PostCell {
    NINetworkImageView *_thumbnailView;
    PostCellObject *_object;
    
    UILabel *_popularityLabel;
    
    UIButton *_favorBtn;
    UIButton *_shareBtn;
    
    UIWebView *_webView;
}

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    PostCellObject *cellObject = object;
    CGFloat width = tableView.width - 40;
    CGFloat titleHeight = [Utility heightForText:cellObject.post.title fontSize:20 width:width - 80];
    CGFloat subtitleHeight = [Utility heightForText:cellObject.post.subtitle fontSize:16 width:width];
    return 30 + titleHeight + subtitleHeight + 210 + 20;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _webView = [[UIWebView alloc] initWithFrame:self.bounds];
        _webView.scrollView.scrollEnabled = NO;
        _webView.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.opaque = NO;
        [self.contentView addSubview:_webView];
        
        _popularityLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _popularityLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        _popularityLabel.font = [UIFont systemFontOfSize:12];
        _popularityLabel.left = 8;
        _popularityLabel.textColor = [UIColor orangeColor];
        [self.contentView addSubview:_popularityLabel];
        
        _thumbnailView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(10, 0, self.width - 20, 210)];
        _thumbnailView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        _thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        _thumbnailView.initialImage = [UIImage imageNamed:@"default-image.png"];
        [self.contentView addSubview:_thumbnailView];
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(saveToEvernote)];
        swipe.direction = UISwipeGestureRecognizerDirectionLeft;
        self.contentView.userInteractionEnabled = YES;
        [self.contentView addGestureRecognizer:swipe];
        
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showShareView)];
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        [self.contentView addGestureRecognizer:swipeRight];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPost)];
        tap.delegate = self;
        [self.contentView addGestureRecognizer:tap];
        
        _shareBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.width - 40, 5, 32, 32)];
        [_shareBtn setImage:[UIImage imageNamed:@"icon-share.png"] forState:UIControlStateNormal];
        [_shareBtn addTarget:self action:@selector(showShareView) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_shareBtn];
        
        _favorBtn = [[UIButton alloc] initWithFrame:CGRectMake(_shareBtn.left - 32, 5, 32, 32)];
        [_favorBtn setImage:[UIImage imageNamed:@"icon-favor.png"] forState:UIControlStateNormal];
        [_favorBtn setImage:[UIImage imageNamed:@"icon-favored.png"] forState:UIControlStateSelected];
        [_favorBtn addTarget:self action:@selector(saveToEvernote) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_favorBtn];
    }
    return self;
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}

- (ProductHuntPost *)post {
    return _object.post;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self doLayout];
}

- (NSString *)htmlWithPost:(ProductHuntPost *)post {
    NSString *html =  @"<html><head></head><body>"
    @"<div style='color:#da552f; font-size:20; padding-right:80px; white-space: pre-wrap;'>%@</div>"
    @"<div style='color:#7d7d7d; font-size:16; padding-top:5px'>%@</div>"
    @"</body></html>";
    return DefStr(html, post.title, post.subtitle);
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    _object = object;
    
    _popularityLabel.text = DefStr(@"%d votes  %d comments", self.post.voteCount, self.post.commentCount);
    [_popularityLabel sizeToFit];
    
    [_thumbnailView prepareForReuse];
    if (self.post.image) {
        _thumbnailView.image = self.post.image;
    }
    else {
        [_thumbnailView setPathToNetworkImage:self.post.imageLink];
    }

    [_webView loadHTMLString:[self htmlWithPost:_object.post] baseURL:nil];
    
    _favorBtn.selected = _object.favored;
    
    [self doLayout];
    
    NIDPRINT(@"%@", self.post.imageLink);
    
    return YES;
}

- (void)doLayout {
    _thumbnailView.centerX = self.width / 2;
    _thumbnailView.bottom = self.height - 10;
    
    _popularityLabel.bottom = _thumbnailView.top - 5;
    
    _shareBtn.left = self.width - 40;
    _favorBtn.left = _shareBtn.left - 32;
}

- (void)showShareView {
    [_object.delegate showShareOptionsForCell:self];
}

- (void)selectPost {
    if ([_object.delegate respondsToSelector:@selector(didSelectCell:)]) {
        [_object.delegate didSelectCell:self];
    }
}

- (void)saveToEvernote {
    if (_object.favored) {
        if (_object.confirmOnUnfavor) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Caution" message:@"Do you want to unfavor this post?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
            [alertView show];
        }
        else {
            [self unfavorPost];
        }
    }
    else {
        [[FavorDB sharedDB] favorPost:_object.post];
        [_object.delegate didFavorPostForCell:self favor:YES];
    }
}

- (void)unfavorPost {
    [[FavorDB sharedDB] unfavorPostWithId:_object.post.postId];
    
    [_object.delegate didFavorPostForCell:self favor:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        [self unfavorPost];
    }
}

@end
