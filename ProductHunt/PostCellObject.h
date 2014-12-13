//
//  PostCellObject.h
//  ProductHunt
//
//  Created by HuangPeng on 11/19/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NICellFactory.h"
#import "ProductHuntPost.h"

@class PostCell;
@protocol PostCellObjectDelegate <NSObject>

- (void)showShareOptionsForCell:(PostCell *)cell;

- (void)savePostToEvernoteForCell:(PostCell *)cell;

- (void)didFavorPostForCell:(PostCell *)cell favor:(BOOL)favor;

@optional
- (void)didSelectCell:(PostCell *)cell;

@end

@interface PostCellObject : NICellObject
- (id)initWithPost:(ProductHuntPost *)post;

@property (nonatomic, readonly) ProductHuntPost *post;
@property (nonatomic, readonly) BOOL favored;
@property (nonatomic) BOOL confirmOnUnfavor;

@property (nonatomic, weak) id<PostCellObjectDelegate> delegate;

@end

@interface  PostCell: UITableViewCell <NICell>

@property (nonatomic, readonly) ProductHuntPost *post;

@end
