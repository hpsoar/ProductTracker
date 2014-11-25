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
        item.confirmOnUnfavor = YES;
        item.delegate = self;
        [items addObject:item];
    }];
    [self.model addObjectsFromArray:items];
    
    [self.tableView reloadData];
    
    [self updateRightBarButton];
}

- (void)updateRightBarButton {
    
    NSInteger count = [self.model tableView:self.tableView numberOfRowsInSection:0];
    
    if (count > 1) {
        static NSInteger lastIndex = 0;
        static NSInteger lastCount = 0;
        NSArray *visibleIndexPathes = [self.tableView indexPathsForVisibleRows];
        
        NSIndexPath *indexPath = visibleIndexPathes.firstObject;
        if (visibleIndexPathes.count > 1) {
            CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:indexPath];
            CGRect rectInSuperview = [self.tableView convertRect:rectInTableView toView:[self.tableView superview]];
            
            if (rectInSuperview.origin.y < -50) {
                indexPath = visibleIndexPathes[1];
            }
        }
        
        if (lastIndex != indexPath.row || lastCount != count) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.textColor = [UIColor whiteColor];
            label.text = DefStr(@"%d/%d", indexPath.row + 1, count);
            [label sizeToFit];
            UIBarButtonItem *favorCountItem = [[UIBarButtonItem alloc] initWithCustomView:label];
            self.navigationItem.rightBarButtonItem = favorCountItem;
            
            lastCount = count;
            lastIndex = indexPath.row;
        }
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)didFavorPostForCell:(PostCell *)cell favor:(BOOL)favor {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.model removeObjectAtIndexPath:indexPath];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    if ([self.model tableView:self.tableView numberOfRowsInSection:0] == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [self updateRightBarButton];
}

- (void)showShareOptionsForCell:(PostCell *)cell {
    [self selectCell:cell];
    
    [[ShareKit kit] sharePost:cell.post inController:self];
}

- (void)selectCell:(PostCell *)cell {
    NSIndexPath *indexPath =  [self.tableView indexPathForCell:cell];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateRightBarButton];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.tableView reloadData];
    [self updateRightBarButton];
}

@end