//
//  FavorDBiCloud.m
//  ProductHunt
//
//  Created by HuangPeng on 11/28/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "FavorDBiCloud.h"

@implementation FavorDBiCloud {
    NSString *_entityName;
}

+ (instancetype)sharedDB {
    static FavorDBiCloud *db;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        db = [FavorDBiCloud new];
    });
    return db;
}

- (id)init {
    self = [super initWithModelName:@"FavoredPost" storeURL:[Utility filepath:@"favored_posts.sqlite"]];
    if (self) {
        _entityName = @"FavoredPosts";
    }
    return self;
}

- (void)favorPost:(ProductHuntPost *)post {
    FavoredPost *favoredPost = [self insertObjectForEntityWithName:_entityName];
    favoredPost.postId = @(post.postId);
    favoredPost.title = post.title;
    favoredPost.subtitle = post.subtitle;
    favoredPost.imageURL = post.imageLink;
    favoredPost.postURL = post.productLink;
    favoredPost.date = post.date;
    favoredPost.voteCount = @(post.voteCount);
    favoredPost.commentCount = @(post.commentCount);
    [self saveContext];
}

- (void)unfavorPostWithId:(NSInteger)postId {
    FavoredPost *favoredPost = [self favoredPostWithId:postId];
    if (favoredPost) {
        [self deleteObject:favoredPost];
        [self saveContext];
    }
}

- (FavoredPost *)favoredPostWithId:(NSInteger)postId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"postId == %d", postId ];
    return [self queryOneFromEntityWithName:_entityName withPredicate:predicate];
}

- (BOOL)isPostFavored:(NSInteger)postId {
    return [self favoredPostWithId:postId] != nil;
}

- (NSArray *)favoredPosts {
    NSArray *managedObjects = [self queryFromEntityWithName:_entityName withPredicate:nil];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:managedObjects.count];
    for (FavoredPost *favoredPost in managedObjects) {
        ProductHuntPost *post = [ProductHuntPost new];
        post.postId = [favoredPost.postId integerValue];
        post.title = favoredPost.title;
        post.subtitle = favoredPost.subtitle;
        post.imageLink = favoredPost.imageURL;
        post.productLink = favoredPost.postURL;
        post.date = favoredPost.date;
        post.commentCount = [favoredPost.commentCount integerValue];
        post.voteCount = [favoredPost.voteCount integerValue];
        [result addObject:post];
    }
    return result;
}

@end
