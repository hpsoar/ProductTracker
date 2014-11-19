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

@implementation PostCell {
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    NINetworkImageView *_thumbnailView;
    PostCellObject *_object;
    
    UILabel *_popularityLabel;
    
    UIButton *_favorBtn;
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
        
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(saveToEvernote)];
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        [self.contentView addGestureRecognizer:swipeRight];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(self.width - 40, 5, 32, 32)];
        [btn setImage:[UIImage imageNamed:@"icon-share.png"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(showShareView) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:btn];
        
        _favorBtn = [[UIButton alloc] initWithFrame:CGRectMake(btn.left - 32, 5, 32, 32)];
        [_favorBtn setImage:[UIImage imageNamed:@"icon-favor.png"] forState:UIControlStateNormal];
        [_favorBtn setImage:[UIImage imageNamed:@"icon-favored.png"] forState:UIControlStateSelected];
        [_favorBtn addTarget:self action:@selector(saveToEvernote) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_favorBtn];
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
    
    _favorBtn.selected = _object.favored;
    
    NIDPRINT(@"%@", self.post.imageLink);
    
    return YES;
}

- (void)showShareView {
    [_object.delegate showShareOptionsForCell:self];
}

- (void)saveToEvernote {
    if (_object.favored) {
        [[FavorDB sharedDB] unfavorPostWithId:_object.post.postId];
        [_object.delegate didFavorPostForCell:self favor:NO];
    }
    else {
        [[FavorDB sharedDB] favorPost:_object.post];
        [_object.delegate didFavorPostForCell:self favor:YES];
    }
}

@end
