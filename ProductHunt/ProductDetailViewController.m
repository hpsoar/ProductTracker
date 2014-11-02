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

@interface ProductDetailViewController ()
@property (nonatomic, strong) NINetworkImageView *screenshotView;
@property (nonatomic, strong) UILabel *subtitleLabel;
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
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = self.post.title;

    self.screenshotView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 250)];
    self.screenshotView.contentMode = UIViewContentModeScaleAspectFill;
    [self.screenshotView setPathToNetworkImage:self.post.imageLink];
    [self.view addSubview:self.screenshotView];
    
    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.screenshotView.bottom + 5, self.view.width - 20, 0)];
    self.subtitleLabel.textColor = RGBCOLOR_HEX(0x9d9d9d);
    self.subtitleLabel.text = self.post.subtitle;
    self.subtitleLabel.numberOfLines = 0;
    [self.subtitleLabel sizeToFit];
    [self.view addSubview:self.subtitleLabel];
}

@end
