//
//  HttpSessionManager.m
//  ProductHunt
//
//  Created by HuangPeng on 11/1/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "ProductHuntSession.h"
#import "NIDebuggingTools.h"
#import "Utility.h"

#define kProductLink @"productLink"
#define kTitle @"title"
#define kSubtitle @"subtitle"
#define kImageLink @"imageLink"
#define kCommentLink @"commentLink"

@implementation ProductHuntPost

- (id)initWithData:(NSDictionary *)data {
    self = [super init];
    if (self) {
        self.postId = [data[@"id"] integerValue];
        self.productLink = data[@"redirect_url"];
        self.title = data[@"name"];
        self.subtitle = data[@"tagline"];
        self.commentLink = data[@"discussion_url"];
        self.imageLink = data[@"screenshot_url"][@"300px"];
        self.commentCount = [data[@"comments_count"] integerValue];
        self.voteCount = [data[@"votes_count"] integerValue];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.productLink forKey:kProductLink];
    [coder encodeObject:self.title forKey:kTitle];
    [coder encodeObject:self.subtitle forKey:kSubtitle];
    [coder encodeObject:self.imageLink forKey:kImageLink];
    [coder encodeObject:self.commentLink forKey:kCommentLink];
}

-(id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    self.productLink = [decoder decodeObjectForKey:kProductLink];
    self.title = [decoder decodeObjectForKey:kTitle];
    self.subtitle = [decoder decodeObjectForKey:kSubtitle];
    self.imageLink = [decoder decodeObjectForKey:kImageLink];
    self.commentLink = [decoder decodeObjectForKey:kCommentLink];
    
    return  self;
}

- (NSString *)description {
    return [[self.title stringByAppendingString:@": "] stringByAppendingString:self.productLink];
}

@end

@implementation ProductHuntComment

/*
 * "id": 7,
 "body": "This is like the 103th best comment ever",
 "created_at": "2014-10-26T04:07:18.537-07:00",
 "post_id": 1,
 "parent_comment_id": null,
 "user_id": 8,
 "child_comments_count": 2,
 "maker": false,
 "user": {
 "id": 8,
 "name": "Karl User the 321th",
 "headline": "Product Hunter",
 "created_at": "2014-10-26T04:07:18.531-07:00",
 "username": "producthunter319",
 "image_url": {
 "48px": "/assets/ph-logo.png",
 "73px": "/assets/ph-logo.png",
 "original": "/assets/ph-logo.png"
 },
 "profile_url": "http://www.producthunt.com/producthunter319"
 },
 "child_comments":
 */
- (id)initWithData:(NSDictionary *)data {
    self = [super init];
    if (self) {
        self.commentId = [data[@"id"] integerValue];
        self.body = data[@"body"];
        // date
        self.userId = [data[@"user_id"] integerValue];
        self.postId = [data[@"post_id"] integerValue];
        
        // parent id
        id parentCommentId = data[@"parent_comment_id"];
        if ([parentCommentId isKindOfClass:[NSNumber class]]) {
            self.parentId = [parentCommentId integerValue];
        }
        else {
            self.parentId = -1;
        }
        
        // child
        NSArray *json = data[@"child_comments"];
        NSMutableArray *childComments = [[NSMutableArray alloc] initWithCapacity:json.count];
        for (id obj in data[@"child_comments"]) {
            ProductHuntComment *comment = [[ProductHuntComment alloc] initWithData:obj];
            [childComments addObject:comment];
        }
        self.childComments = childComments;
    }
    return self;
}

@end

#define kProductHuntRootPath @"https://api.producthunt.com"

@interface ProductHuntSession ()
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *apiSecret;
@property (nonatomic, strong) NSString *accessToken;
@end

@implementation ProductHuntSession {
    NSMutableArray *_posts;
}

+ (instancetype)sharedSession {
    static id session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        session = [[ProductHuntSession alloc] initWithBaseURL:[NSURL URLWithString:kProductHuntRootPath]];
    });
    return session;
}

+ (void)registerWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret {
    [ProductHuntSession sharedSession].apiSecret = appSecret;
    [ProductHuntSession sharedSession].apiKey = appKey;
}

- (void)authorize:(void(^)())success {
    if (self.apiSecret == nil || self.apiKey == nil) {
        [NSException raise:kProductHuntSessionException format:@"api key and api secret must be set before this session is used"];
    }
    
    NSString *path = @"/v1/oauth/token";
    NSDictionary *params = @{ @"client_id": self.apiKey,
                              @"client_secret": self.apiSecret,
                              @"grant_type": @"client_credentials" };
    WEAK_VAR(self);
    [self POST:path parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NIDPRINT(@"%@", responseObject);
        [_self processAuthorizationResponse:responseObject];
        _self.sessionIsValid = YES;
        success();
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NIDPRINT(@"%@", error);
        _self.sessionIsValid = NO;
    }];
}

- (void)processAuthorizationResponse:(NSDictionary *)json {
    self.accessToken = json[@"access_token"];
}

- (void)setSessionIsValid:(BOOL)sessionIsValid {
    _sessionIsValid = sessionIsValid;
}

- (NSString *)cacheFileForDate:(NSDate *)date {
    NSString *filename = DefStr(@"product_hunts_%@.cache", date);
    return [Utility filepath:filename];
}

- (NSArray *)queryCacheForPostsDaysAgo:(NSInteger)days {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-days * 24 * 3600];
    NSString *filepath = [self cacheFileForDate:date];
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    return [self parsePosts:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
}

- (void)cachePosts:(NSArray *)posts forDate:(NSDate *)date {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:posts];
    NSString *filepath = [self cacheFileForDate:date];
    [data writeToFile:filepath atomically:YES];
}

- (void)fetchPostsDaysAgo:(NSInteger)days delegate:(id<ProductHuntSessionDelegate>)delegate {
    if (!self.sessionIsValid) {
        WEAK_VAR(self);
        [self authorize:^{
            [_self _fetchPostsDaysAgo:days delegate:delegate];
        }];
    }
    else {
        [self _fetchPostsDaysAgo:days delegate:delegate];
    }
}

- (void)_fetchPostsDaysAgo:(NSInteger)days delegate:(id<ProductHuntSessionDelegate>)delegate {
    NSString *url = @"/v1/posts";
    
    [self.requestSerializer setValue:DefStr(@"Bearer %@", self.accessToken) forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params;
    if (days > 0) {
        params = @{ @"days_ago": @(days) };
    }
    
    WEAK_VAR(self);
    [self GET:url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NIDPRINT(@"%@", responseObject);
        [self cacheFileForDate:responseObject[@"posts"]];
        
        NSArray *postObjects = [_self parsePosts:responseObject[@"posts"]];
        
        [delegate session:_self didFinishLoadWithPosts:postObjects onDate:[NSDate dateWithTimeIntervalSinceNow:-days * 24 * 3600]];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NIDPRINT(@"%@", error);
        [delegate session:_self didFailLoadWithError:error];
    }];
}

- (NSArray *)parsePosts:(NSArray *)json {
    NSMutableArray *posts = [[NSMutableArray alloc] initWithCapacity:json.count];
    for (NSDictionary *obj in json) {
        ProductHuntPost *post = [[ProductHuntPost alloc] initWithData:obj];
        [posts addObject:post];
    }
    return posts;
}

- (void)commentsForPost:(NSInteger)postId lastCommentId:(NSInteger)lastCommentId count:(NSInteger)count delegate:(id<ProductHuntSessionDelegate>)delegate {
    NSString *url = DefStr(@"/v1/posts/%d/comments", postId);
    NSDictionary *params = nil ;//@{ @"older:": @(lastCommentId),
                             // @"per_page": @(count),
                              //@"order": @"desc"};
    WEAK_VAR(self);
    [self GET:url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NIDPRINT(@"%@", responseObject);
        
        NSArray *comments = [_self parseComments:responseObject[@"comments"]];
        [delegate session:_self didFinishLoadComments:comments forPost:postId];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NIDPRINT(@"%@", error);
        [delegate session:_self didFailLoadCommentsForPost:postId withError:error];
    }];
}

- (NSArray *)parseComments:(NSArray *)json {
    NSMutableArray *comments = [[NSMutableArray alloc] initWithCapacity:json.count];
    for (id obj in json) {
        ProductHuntComment *comment = [[ProductHuntComment alloc] initWithData:obj];
        [comments addObject:comment];
    };
    return comments;
}

@end
