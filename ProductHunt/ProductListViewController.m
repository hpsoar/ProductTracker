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

@interface ProductListViewController () <PostCellObjectDelegate, UMSocialUIDelegate>
@property (nonatomic) NSInteger daysAgo;
@property (nonatomic) ENNotebook *notebook;
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
    [titleLabel sizeToFit];
    titleLabel.textColor = [UIColor whiteColor];
    self.navigationItem.titleView = titleLabel;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(showMarkedPosts)];
    
    WEAK_VAR(self);
    [self.actions attachToClass:[PostCellObject class] tapBlock:^BOOL(id object, id target, NSIndexPath *indexPath) {
        PostCellObject *postObject = object;
        ProductDetailViewController *controller = [[ProductDetailViewController alloc] initWithPost:postObject.post];
        [_self.navigationController pushViewController:controller animated:YES];
        return NO;
    }];
    
    [ProductHuntSession registerWithAppKey:kProductHuntKey appSecret:kProductHuntSecret];
    
    [self addPosts:[[ProductHuntSession sharedSession] cachedPostsForDate:[NSDate date]]  forDate:[NSDate date]];
    
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
    label.textColor = [UIColor blackColor];
    label.text = [self.model tableView:tableView titleForHeaderInSection:section];
    [v addSubview:label];
    return v;
}

- (void)resetModelState {
    self.daysAgo = 0;
}

- (void)loadModel {
    [[ProductHuntSession sharedSession] fetchPostsDaysAgo:self.daysAgo delegate:self];
}

- (void)session:(ProductHuntSession *)session didFailLoadWithError:(NSError *)error {
    
}

- (void)session:(ProductHuntSession *)session didFinishLoadWithPosts:(NSArray *)posts onDate:(NSDate *)date {
    if (self.daysAgo == 0) {
        [self resetModel];
    }
    
    [self addPosts:posts forDate:date];
    
    [self reloadTableView];
    
    self.daysAgo++;
}

- (void)addPosts:(NSArray *)posts forDate:(NSDate *)date {
    NSIndexSet *indexSet = [self.model addSectionWithTitle:[date formatWith:@"yyyy-MM-dd"]];
    [posts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PostCellObject *object = [[PostCellObject alloc] initWithPost:obj];
        object.delegate = self;
        [self.model addObject:object toSection:indexSet.firstIndex];
    }];
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
