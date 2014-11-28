//
//  FavorDBiCloud.h
//  ProductHunt
//
//  Created by HuangPeng on 11/28/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "iCloudCoreData.h"
#import "FavoredPost.h"

@interface FavorDBiCloud : iCloudCoreData

+ (instancetype)sharedDB;

- (void)favorPost:(ProductHuntPost *)post;
- (void)unfavorPostWithId:(NSInteger)postId;
- (BOOL)isPostFavored:(NSInteger)postId;

- (NSArray *)favoredPosts;

- (NSFetchedResultsController *)fetchedResultsControllerSectioned:(BOOL)sectioned;

+ (ProductHuntPost *)convert:(FavoredPost *)favoredPost;

@end
