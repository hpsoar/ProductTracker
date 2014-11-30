//
//  ProductListTableViewController.m
//  ProductHunt
//
//  Created by HuangPeng on 11/1/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "ProductListViewController.h"
#import "NIMutableTableViewModel.h"
#import "NITableViewActions.h"
#import "ProductDetailViewController.h"
#import "AppDelegate.h"
#import <ENSDK/ENSDK.h>
#import <ENSDK/Advanced/ENSDKAdvanced.h>
#import "PostCellObject.h"
#import "FavorDB.h"
#import "FavoredPostsViewController.h"
#import "FavorDBiCloud.h"

@interface ProductListViewController () <PostCellObjectDelegate, UMSocialUIDelegate>
@property (nonatomic) ENNotebook *notebook;
@property (nonatomic) NSInteger loadedPostCount;
@property (nonatomic) NSInteger daysAgo;
@end

@implementation ProductListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.allowLoadMore = YES;
        self.allowDragRefresh = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = @"Products";
    titleLabel.font = [UIFont systemFontOfSize:20];
    [titleLabel sizeToFit];
    titleLabel.textColor = [UIColor whiteColor];
    self.navigationItem.titleView = titleLabel;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"favor-bar-icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showMarkedPosts)];
    
    UIButton *downBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [downBtn setImage:[UIImage imageNamed:@"down-arrow.png"] forState:UIControlStateNormal];
    [downBtn addTarget:self action:@selector(gotoNextSection) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *downItem = [[UIBarButtonItem alloc] initWithCustomView:downBtn];
    
    UIButton *upBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [upBtn setImage:[UIImage imageNamed:@"up-arrow.png"] forState:UIControlStateNormal];
    [upBtn addTarget:self action:@selector(gotoPreviousSection) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *upItem = [[UIBarButtonItem alloc] initWithCustomView:upBtn];

    self.navigationItem.leftBarButtonItems = @[ upItem, downItem ];
    
    WEAK_VAR(self);
    [self.actions attachToClass:[PostCellObject class] tapBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
        PostCellObject *postObject = object;
        ProductDetailViewController *controller = [[ProductDetailViewController alloc] initWithPost:postObject.post];
        [_self.navigationController pushViewController:controller animated:YES];
        return NO;
    }];
    
    [ProductHuntSession registerWithAppKey:kProductHuntKey appSecret:kProductHuntSecret];
    
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //[[FavorDB sharedDB] syncWithiCloud];
    
    [ProductHuntPost clearExpiredImageFiles];
//    FavorDB *favorDB = [[FavorDB alloc] initWithDBPath:@"6C16DD0C2CFB4A77B9986BCE6DF2CC12_hunt_posts.db"];
//    NSArray *posts = [favorDB favoredPosts];
//    for (ProductHuntPost *post in posts) {
//        [[FavorDBiCloud sharedDB] favorPost:post];
//    }
    [self.tableView reloadData];
}

- (void)loadView {
    [super loadView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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

- (void)resetModel {
    [super resetModel];
    
    NSDate *date = [NSDate date];
    self.loadedPostCount = 0;
    for (int i = 0; i < 7; ++i) {
        NSArray *posts = [[ProductHuntSession sharedSession] cachedPostsForDate:date];
        if (posts.count > 0) {
            [self addPosts:posts forDate:date];
            if (self.loadedPostCount > 2) break;
        }
        date = [NSDate dateWithTimeInterval:-24 * 3600 sinceDate:date];
    }
}

// after resetModel, page-->0,
// then it will increase one by one
- (void)loadModelAtPage:(NSInteger)page {
    self.daysAgo = page;
    [[ProductHuntSession sharedSession] fetchPostsDaysAgo:page delegate:self];
}

- (void)session:(ProductHuntSession *)session didFailLoadWithError:(NSError *)error {
}

- (void)session:(ProductHuntSession *)session didFinishLoadWithPosts:(NSArray *)posts date:(NSDate *)date daysAgo:(NSInteger)daysAgo fromCache:(BOOL)fromCache {
    
    // use self.daysAgo to legacy(launched before resetMode) request
    if (daysAgo <= self.daysAgo) {
        NSInteger oldSectionCount = [self.model numberOfSectionsInTableView:self.tableView];
        NSIndexSet *indexSet = [self addPosts:posts forDate:date];
        if (indexSet) {
            [self.tableView reloadData];
            
            BOOL addedSection = oldSectionCount != [self.model numberOfSectionsInTableView:self.tableView];
            if (addedSection) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:indexSet.firstIndex];
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        }
        
        if (!fromCache) {
            if (daysAgo == 0) {
                [self refreshCompleted];
            }
            else {
                [self loadMoreCompleted];
            }
        }
    }
    
    if (self.loadedPostCount < 2 && !self.isRefreshing) {
        [self loadMore];
    }
}

- (NSIndexSet *)indexSetWithDate:(NSDate *)date {
    NSString *sectionTitle = [date formatWith:@"yyyy-MM-dd"];
    NSInteger count = [self.model numberOfSectionsInTableView:self.tableView];
    NSInteger index = 0;
    for (; index < count; ++index) {
        NSString *currentTitle = [self.model tableView:self.tableView titleForHeaderInSection:index];
        NSComparisonResult result = [sectionTitle compare:currentTitle];
        if (result == NSOrderedSame) {
            [self.model removeSectionAtIndex:index];
            break;
        }
        else if (result == NSOrderedDescending) {
            break;
        }
    }
    return [self.model insertSectionWithTitle:sectionTitle atIndex:index];
}

- (NSIndexSet *)addPosts:(NSArray *)posts forDate:(NSDate *)date {
    if (posts.count > 0) {
        @synchronized(self) {
            NSIndexSet *indexSet = [self indexSetWithDate:date];
            [posts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                PostCellObject *object = [[PostCellObject alloc] initWithPost:obj];
                object.delegate = self;
                [self.model addObject:object toSection:indexSet.firstIndex];
            }];
            self.loadedPostCount += posts.count;
            return indexSet;
        }
    }
    return nil;
}

- (void)filterPost {
    NIDPRINTMETHODNAME();
}

- (void)search {
    
}

- (void)showMarkedPosts {
    FavoredPostsViewController *controller = [FavoredPostsViewController new];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)gotoPreviousSection {
    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
    NSIndexPath *indexPath = visibleRows.firstObject;
    NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:0 inSection:MAX(indexPath.section - 1, 0)];
    if (indexPath.row > 0) {
        toIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
    }
    [self.tableView scrollToRowAtIndexPath:toIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)gotoNextSection {
    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
    NSIndexPath *indexPath = visibleRows.lastObject;
    if (indexPath.section + 1 < self.tableView.numberOfSections) {
        NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section + 1];
        [self.tableView scrollToRowAtIndexPath:toIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else {
        NSInteger rows = [self.model tableView:self.tableView numberOfRowsInSection:indexPath.section];
        if (rows > 0) {
            NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:rows - 1 inSection:indexPath.section];
            [self.tableView scrollToRowAtIndexPath:toIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            [self loadMore];
        }
    }
}

- (void)showShareOptionsForCell:(PostCell *)cell {
    [self selectCell:cell];
    
    [[ShareKit kit] sharePost:cell.post inController:self];
}

- (void)selectCell:(PostCell *)cell {
    NSIndexPath *indexPath =  [self.tableView indexPathForCell:cell];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}

- (void)didFavorPostForCell:(PostCell *)cell favor:(BOOL)favor {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)savePostToEvernoteForCell:(PostCell *)cell {
    if ([[ENSession sharedSession] isAuthenticated]) {
        [self savePostToEverNote:cell.post];
    }
    else {
        [[ENSession sharedSession] authenticateWithViewController:self
                                               preferRegistration:NO
                                                       completion:^(NSError *authenticateError) {
                                                           if (!authenticateError) {
                                                               [self savePostToEverNote:cell.post];
                                                           } else if (authenticateError.code != ENErrorCodeCancelled) {
                                                               NIDPRINT(@"%@", authenticateError);
                                                           }
                                                       }];
    }
}

- (void)savePostToEverNote:(ProductHuntPost *)post {
    NSString *notebookName = @"ProductsTracker";
  
    
    if (self.notebook) {
        [self savePost:post toNoteBook:self.notebook];
    }
    else {
        [self findNotebookWithName:notebookName success:^(ENNotebook *notebook) {
            if (notebook) {
                [self savePost:post toNoteBook:notebook];
            }
            else {
                [self createNotebookWithName:notebookName success:^(EDAMNotebook *notebook) {
                    [self findNotebookWithName:notebookName success:^(ENNotebook *notebook) {
                        if (notebook) {
                            [self savePost:post toNoteBook:notebook];
                        }
                    } failure:^(NSError *error) {
                        
                    }];
                } failure:^(NSError *error) {
                    
                }];
            }
        } failure:^(NSError *error) {
            
        }];
    }
}

- (void)createNotebookWithName:(NSString *)notebookName success:(void(^)(EDAMNotebook *notebook))success failure:(void(^)(NSError *error))failure {
    EDAMNotebook *notebook = [EDAMNotebook new];
    notebook.name = notebookName;
    
    [[ENSession sharedSession].primaryNoteStore createNotebook:notebook success:^(EDAMNotebook *notebook) {
        success(notebook);
    } failure:^(NSError *error) {
        NIDPRINT(@"%@", error);
        failure(error);
    }];
}

- (void)findNotebookWithName:(NSString *)notebookName success:(void(^)(ENNotebook *notebook))success failure:(void(^)(NSError *error))failure {
    [[ENSession sharedSession] listNotebooksWithCompletion:^(NSArray *notebooks, NSError *listNotebooksError) {
        if (listNotebooksError) {
            NIDPRINT(@"%@", listNotebooksError);
            failure(listNotebooksError);
        }
        else {
            ENNotebook *notebook;
            for (ENNotebook *nb in notebooks) {
                if ([nb.name isEqualToString:notebookName]) {
                    notebook = nb;
                    break;
                }
            }
            success(notebook);
        }
    }];
}

- (void)savePost:(ProductHuntPost *)post toNoteBook:(ENNotebook *)notebook {
    self.notebook = notebook;
    
    // Build note with resource.
    ENNote * note = [[ENNote alloc] init];
    note.title = post.title;
    note.content = [[ENNoteContent alloc] initWithENML:post.subtitle];
    if (post.image) {
        ENResource * resource = [[ENResource alloc] initWithImage:post.image];
        [note addResource:resource];
    }

    [[ENSession sharedSession] uploadNote:note notebook:notebook completion:^(ENNoteRef *noteRef, NSError *uploadNoteError) {
        NSString * message = nil;
        if (noteRef) {
            message = @"Photo note created.";
        } else {
            message = @"Failed to create photo note.";
        }
        NIDPRINT(@"%@", message);
    }];
}

@end
