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

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.actions attachToClass:[PostCellObject class] tapBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
        PostCellObject *postObject = object;
        ProductDetailViewController *controller = [[ProductDetailViewController alloc] initWithPost:postObject.post];
        [self.navigationController pushViewController:controller animated:YES];
        self.selectedRow = indexPath;
        return YES;
    }];
    
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

- (void)showShareOptionsForCell:(PostCell *)cell {
    [self selectCell:cell];
    
    [[ShareKit kit] sharePost:cell.post inController:self];
}

- (void)selectCell:(PostCell *)cell {
    NSIndexPath *indexPath =  [self.tableView indexPathForCell:cell];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}

@end