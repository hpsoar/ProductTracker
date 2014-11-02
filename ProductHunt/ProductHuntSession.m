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
    return [self processPosts:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
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
        
        NSArray *postObjects = [_self processPosts:responseObject[@"posts"]];
        
        [delegate session:self didFinishLoadWithPosts:postObjects onDate:[NSDate dateWithTimeIntervalSinceNow:-days * 24 * 3600]];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NIDPRINT(@"%@", error);
        [delegate session:_self didFailLoadWithError:error];
    }];
}

- (NSArray *)processPosts:(NSArray *)posts {
    if ([posts isKindOfClass:[NSArray class]]) {
        NSMutableArray *postObjects = [[NSMutableArray alloc] initWithCapacity:posts.count];
        for (NSDictionary *post in posts) {
            ProductHuntPost *postObject = [[ProductHuntPost alloc] initWithData:post];
            [postObjects addObject:postObject];
        }
        return postObjects;
    }
    else {
        return nil;
    }
}

@end
