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
#import "FavorDBiCloud.h"
#import "UMSocial.h"
#import "AppDelegate.h"

@interface FavoredPostsViewController () <PostCellObjectDelegate, UMSocialUIDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) NSInteger totalCount;
@end

@implementation FavoredPostsViewController

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController == nil) {
        _fetchedResultsController = [[FavorDBiCloud sharedDB] fetchedResultsControllerSectioned:YES];
        NSError *error;
        [_fetchedResultsController performFetch:&error];
        if (error == nil) {
            self.totalCount = [self computeTotalCount];
            _fetchedResultsController.delegate = self;
        }
        else {
            NIDPRINT(@"%@", error);
        }
    }
    return _fetchedResultsController;
}

- (NSInteger)computeTotalCount {
    NSInteger totalCount = 0;
    for (id<NSFetchedResultsSectionInfo> section in _fetchedResultsController.sections) {
         totalCount += [section numberOfObjects];
    }
    return totalCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView reloadData];
    
    [self updateTitle];
}

- (void)updateTitle {
    if (self.totalCount > 1) {
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
        
        if (lastIndex != indexPath.row || lastCount != self.totalCount || self.navigationItem.titleView == nil) {
            [self updateTitleViewWithTitle:DefStr(@"Favored (%d/%d)", indexPath.row + 1, self.totalCount)];
            
            lastCount = self.totalCount;
            lastIndex = indexPath.row;
        }
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
    [self updateTitle];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.tableView reloadData];
    [self updateTitle];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PostCellObject *object = [self objectAtIndexPath:indexPath];
    return [PostCell heightForObject:object atIndexPath:indexPath tableView:tableView];
}

- (PostCellObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    ProductHuntPost *post = [FavorDBiCloud convert:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    PostCellObject *object = [[PostCellObject alloc] initWithPost:post];
    object.delegate = self;
    return object;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo name];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"favored_post_cell";
    PostCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[PostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
   
    [cell shouldUpdateCellWithObject:[self objectAtIndexPath:indexPath]];
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PostCellObject *object = [self objectAtIndexPath:indexPath];
    PostCellObject *postObject = object;
    ProductDetailViewController *controller = [[ProductDetailViewController alloc] initWithPost:postObject.post];
    [self.navigationController pushViewController:controller animated:YES];
    return indexPath;
}

#pragma mark -

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        self.totalCount = [self computeTotalCount];
        if (self.totalCount == 0) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        [self updateTitle];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

@end