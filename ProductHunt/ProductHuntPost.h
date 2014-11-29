//
//  ProductHuntPost.h
//  ProductHunt
//
//  Created by HuangPeng on 11/19/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProductHuntPost : NSObject

@property NSInteger postId;
@property NSString *productLink;
@property NSString *title;
@property NSString *subtitle;
@property NSString *imageLink;
@property NSString *commentLink;
@property NSInteger commentCount;
@property NSInteger voteCount;
@property NSString *date;
@property (nonatomic, readonly) UIImage *image;

- (id)initWithData:(NSDictionary *)data;

+ (void)clearExpiredImageFiles;

@end

@interface ProductHuntComment : NSObject

- (id)initWithData:(NSDictionary *)data;

@property NSInteger commentId;
@property NSString *body;
@property NSDate *date;
@property NSArray *childComments;

@property NSInteger userId;
@property NSInteger postId;
@property NSInteger parentId;
@end
