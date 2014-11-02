//
//  HttpSessionManager.h
//  ProductHunt
//
//  Created by HuangPeng on 11/1/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface ProductHuntPost : NSObject

@property NSString *productLink;
@property NSString *title;
@property NSString *subtitle;
@property NSString *imageLink;
@property NSString *commentLink;
@property NSInteger commentCount;
@property NSInteger voteCount;

- (id)initWithData:(NSDictionary *)data;

@end

#define kProductHuntKey @"e9af2cf386088f8348d8b4b1077d437ff3b72eaa4133ae55a81f6ca9e4f02829"
#define kProductHuntSecret @"96d1a541080f78260044b228693e98d105fa9c3edd5150742ad6c31ae8baa0be"
#define kProductHuntSessionException @"Product Hunt Session Exception"

@class ProductHuntSession;
@protocol ProductHuntSessionDelegate <NSObject>

- (void)session:(ProductHuntSession *)session didFinishLoadWithPosts:(NSArray *)post onDate:(NSDate *)date;
- (void)session:(ProductHuntSession *)session didFailLoadWithError:(NSError *)error;

@end

@interface ProductHuntSession : AFHTTPSessionManager

+ (void)registerWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret;
+ (instancetype)sharedSession;

- (void)fetchPostsDaysAgo:(NSInteger)days delegate:(id<ProductHuntSessionDelegate>)delegate;

- (NSArray *)queryCacheForPostsDaysAgo:(NSInteger)days;

@property (nonatomic, readonly) BOOL sessionIsValid;

@property (nonatomic, readonly) NSArray *posts;

@end
