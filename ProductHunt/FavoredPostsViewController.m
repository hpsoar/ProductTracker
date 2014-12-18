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
@property (nonatomic) NSInteger totalCount;
@property (nonatomic, strong) NSIndexPath *selectedRow;
@end

@implementation FavoredPostsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.model numberOfSectionsInTableView:self.tableView] == 0) {
        [self loadModeWithPosts:[[FavorDB sharedDB] favoredPosts]];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.selectedRow) {
        PostCellObject *obj = [self.model objectAtIndexPath:self.selectedRow];
        if (![[FavorDB sharedDB] isPostFavored:obj.post.postId]) {
            [self didFavorPostForCell:(PostCell *)[self.tableView cellForRowAtIndexPath:self.selectedRow] favor:NO];
        }
        self.selectedRow = nil;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (iOSOver(8)) {
        self.tableView.preservesSuperviewLayoutMargins = NO;
        self.tableView.layoutMargins = UIEdgeInsetsZero;
        self.tableView.separatorInset = UIEdgeInsetsZero;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = RGBCOLOR_HEX(0xdedede);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 320, 28)];
    label.textColor = [UIColor whiteColor];
    label.text = [self.model tableView:tableView titleForHeaderInSection:section];
    [v addSubview:label];
    return v;
}

- (void)loadModeWithPosts:(NSArray *)posts {
    self.totalCount = posts.count;
    
    NSString *date = nil;
    NSIndexSet *sectionIndex;
    for (ProductHuntPost *post in posts) {
        if (date == nil) {
            date = post.date;
            sectionIndex = [self.model addSectionWithTitle:date];
        }
        else if (![date isEqualToString:post.date]) {
            date = post.date;
            sectionIndex = [self.model addSectionWithTitle:date];
        }
        PostCellObject *obj = [[PostCellObject alloc] initWithPost:post];
        obj.delegate = self;
        [self.model addObject:obj toSection:sectionIndex.firstIndex];
    }
    
    [self updateTitle];
}

- (void)updateTitle {
    if (self.totalCount > 1) {
        [self updateTitleViewWithTitle:DefStr(@"Favored (%d)", self.totalCount)];
    }
    else {
        [self updateTitleViewWithTitle:@"Favored"];
    }
}

- (void)updateTitleViewWithTitle:(NSString *)title {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = title;
    [titleLabel sizeToFit];
    titleLabel.textColor = [UIColor whiteColor];
    self.navigationItem.titleView = titleLabel;
}

- (void)didFavorPostForCell:(PostCell *)cell favor:(BOOL)favor {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.model removeObjectAtIndexPath:indexPath];
    
    NSInteger rows = [self.model tableView:self.tableView numberOfRowsInSection:indexPath.section];
    if (rows == 0) {
        [self.model removeSectionAtIndex:indexPath.section];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    self.totalCount--;
    
    [self updateTitle];
}

- (void)didSelectCell:(PostCell *)cell {
    ProductDetailViewController *controller = [[ProductDetailViewController alloc] initWithPost:cell.post];
    [self.navigationController pushViewController:controller animated:YES];
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