//
//  ProductListTableViewController.h
//  ProductHunt
//
//  Created by HuangPeng on 11/1/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NICellFactory.h"
#import "ProductHuntSession.h"
#import "PHTableViewController.h"

@interface ProductListViewController : PHTableViewController  <ProductHuntSessionDelegate>

@end

@class PostCell;
@protocol PostCellObjectDelegate <NSObject>

- (void)showShareOptionsForCell:(PostCell *)cell;

@end

@interface PostCellObject : NICellObject
@property (nonatomic, readonly) ProductHuntPost *post;

- (id)initWithPost:(ProductHuntPost *)post;

@property (nonatomic, weak) id<PostCellObjectDelegate> delegate;

@end

@interface  PostCell: UITableViewCell <NICell>

@property (nonatomic, readonly) ProductHuntPost *post;

@end