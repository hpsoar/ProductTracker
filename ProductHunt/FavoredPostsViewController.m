//
//  FavoredPostsViewController.m
//  ProductHunt
//
//  Created by HuangPeng on 11/19/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "FavoredPostsViewController.h"
#import "PostCellObject.h"
#import "ProductDetailViewController.h"
#import "FavorDB.h"
#import "UMSocial.h"
#import "AppDelegate.h"

@interface FavoredPostsViewController () <PostCellObjectDelegate, UMSocialUIDelegate>

@end

@implementation FavoredPostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = @"Favored Posts";
    [titleLabel sizeToFit];
    titleLabel.textColor = [UIColor whiteColor];
    self.navigationItem.titleView = titleLabel;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    WEAK_VAR(self);
    [self.actions attachToClass:[PostCellObject class] tapBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
        PostCellObject *postObject = object;
        ProductDetailViewController *controller = [[ProductDetailViewController alloc] initWithPost:postObject.post];
        [_self.navigationController pushViewController:controller animated:YES];
        return NO;
    }];
    
    NSArray *posts = [[FavorDB sharedDB] favoredPosts];
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:posts.count];
    [posts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PostCellObject *item = [[PostCellObject alloc] initWithPost:obj];
        item.delegate = self;
        [items addObject:item];
    }];
    [self.model addObjectsFromArray:items];
    
    [self.tableView reloadData];
}


- (void)didFavorPostForCell:(PostCell *)cell favor:(BOOL)favor {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.model removeObjectAtIndexPath:indexPath];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)showShareOptionsForCell:(PostCell *)cell {
    [self selectCell:cell];
    
    ProductHuntPost *post = cell.post;
    NSArray *snsNames = @[ UMShareToSina, UMShareToTencent, UMShareToWechatSession, UMShareToWechatTimeline, UMShareToWechatFavorite, UMShareToQQ, UMShareToQzone, UMShareToEmail, UMShareToSms];
    NSString *text = DefStr(@"%@: %@\n %@", post.title, post.subtitle, post.productLink);
    [UMSocialSnsService presentSnsIconSheetView:self appKey:UmengAppkey shareText:text shareImage:post.image shareToSnsNames:snsNames delegate:self];
}

- (void)selectCell:(PostCell *)cell {
    NSIndexPath *indexPath =  [self.tableView indexPathForCell:cell];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}

@end