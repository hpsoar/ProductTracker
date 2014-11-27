//
//  HttpSessionManager.m
//  ProductHunt
//
//  Created by HuangPeng on 11/1/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "ProductHuntSession.h"
#import "ProductHuntPost.h"

#define kProductHuntRootPath @"https://api.producthunt.com"

@interface ProductHuntSession ()
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *apiSecret;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSDate *expireDate;
@property (nonatomic, strong) NSDate *refrenceToday;
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

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        NSDictionary *dict = [Utility userDefaultObjectForKey:@"hunt_authorization"];
        if (dict) {
            self.accessToken = dict[@"access_token"];
            self.expireDate = dict[@"expiration_date"];
            if ([self.expireDate compare:[NSDate date]] != NSOrderedDescending) {
                self.accessToken = nil;
                self.expireDate = nil;
            }
        }
    }
    return self;
}

- (BOOL)sessionIsValid {
    return self.accessToken != nil;
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
        success();
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NIDPRINT(@"%@", error);
    }];
}

- (void)processAuthorizationResponse:(NSDictionary *)json {
    self.accessToken = json[@"access_token"];
    NSTimeInterval interval = MAX([json[@"expires_in"] doubleValue] - 60, 0);
    self.expireDate = [NSDate dateWithTimeInterval:interval sinceDate:[NSDate date]];
    [Utility setUserDefaultObjects:@{ @"hunt_authorization": @{
                                              @"access_token": self.accessToken,
                                              @"expiration_date": self.expireDate,
                                              }}];
}

- (NSString *)cacheFileForDate:(NSDate *)date {
    NSString *dateStr = [date formatWith:@"yyyyMMdd"];
    NSString *filename = DefStr(@"hunts.%@.cache", dateStr);
    return [Utility filepath:filename];
}

- (NSArray *)queryCacheForPostsDaysAgo:(NSInteger)days {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-days * 24 * 3600];
    NSString *filepath = [self cacheFileForDate:date];
    return [self postsFromFile:filepath];
}

- (NSArray *)postsFromFile:(NSString *)filepath {
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    return [self parsePosts:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
}

- (NSDictionary *)queryLatestCachedPosts {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:[Utility documentPath] error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.cache'"];
    NSArray *files = [dirContents filteredArrayUsingPredicate:fltr];
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (NSString *filename in files) {
        NSArray *comps = [filename componentsSeparatedByString:@"."];
        NSDate *date = [NSDate dateWithFormatter:@"yyyyMMdd" dateStr:comps[1]];
        NSString *filepath = [Utility filepath:filename];
        NSArray *posts = [self postsFromFile:filepath];
        
        result[date] = posts;
    }
    return result;
}

- (NSArray *)cachedPostsForDate:(NSDate *)date {
    NSString *filepath = [self cacheFileForDate:date];
    return [self postsFromFile:filepath];
}

- (void)cachePosts:(NSArray *)posts forDate:(NSDate *)date {
    if (posts.count > 0) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:posts];
        NSString *filepath = [self cacheFileForDate:date];
        [data writeToFile:filepath atomically:YES];
    }
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
    if (days > 0 && self.refrenceToday) {
        NSDate *date = [NSDate dateWithTimeInterval:-days * 24 * 3600 sinceDate:self.refrenceToday];
        NSArray *result = [self cachedPostsForDate:date];
        if (result.count > 0) {
            [delegate session:self didFinishLoadWithPosts:result date:date daysAgo:days fromCache:YES];
        }
    }
    
    [self fetchPostsDaysAgo:days fromServerWithDelegate:delegate];
}

- (void)fetchPostsDaysAgo:(NSInteger)days fromServerWithDelegate:(id<ProductHuntSessionDelegate>)delegate {
    NSString *url = @"/v1/posts";
    
    [self.requestSerializer setValue:DefStr(@"Bearer %@", self.accessToken) forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params;
    if (days > 0) {
        params = @{ @"days_ago": @(days) };
    }
    
    WEAK_VAR(self);
    [self GET:url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NIDPRINT(@"%@", responseObject);
        NSArray *posts = responseObject[@"posts"];
        NSDate *date;
        if (posts.count > 0) {
            date = [NSDate dateWithFormatter:@"yyyy-MM-dd" dateStr:posts[0][@"day"]];
            self.refrenceToday = [NSDate dateWithTimeInterval:days * 24 * 3600 sinceDate:date];
        }
        
        [self cachePosts:responseObject[@"posts"] forDate:date];
        
        NSArray *postObjects = [_self parsePosts:posts];
        
        [delegate session:_self didFinishLoadWithPosts:postObjects date:date daysAgo:days fromCache:NO];
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
