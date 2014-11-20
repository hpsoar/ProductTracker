//
//  FavorDB.h
//  ProductHunt
//
//  Created by HuangPeng on 11/19/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProductHuntPost.h"

@interface FavorDB : NSObject

+ (instancetype)sharedDB;

- (void)favorPost:(ProductHuntPost *)post;
- (void)unfavorPostWithId:(NSInteger)postId;
- (NSArray *)favoredPosts;
- (BOOL)isPostFavored:(NSInteger)postId;

- (void)syncWithiCloud;

@end
