//
//  FavorDB.m
//  ProductHunt
//
//  Created by HuangPeng on 11/19/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "FavorDB.h"
#import "FMDB.h"

@implementation FavorDB {
    FMDatabase *_fmDB;
}

+ (instancetype)sharedDB {
    static FavorDB *db;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        db = [FavorDB new];
    });
    return db;
}

- (id)init {
    self = [super init];
    if (self) {
        NSString *name = @"hunt_posts.db";
        NSString *filepath = [Utility filepath:name];
        _fmDB = [FMDatabase databaseWithPath:filepath];
        [_fmDB executeStatements:@"CREATE TABLE IF NOT EXISTS favored_posts "
         @"(id integer primary key autoincrement, post_id integer, title text, subtitle text, image_url text, url text"];
    }
    return self;
}

- (void)favorPost:(ProductHuntPost *)post {
    NSArray *keys = @[ @"post_id", @"title", @"subtitle", @"image_url", @"url" ];
    NSMutableArray *questions = [[NSMutableArray alloc] initWithCapacity:keys.count];
    while (questions.count < keys.count) {
        [questions addObject:@"?"];
    }
    
    NSArray *params = @[ @(post.postId), post.title, post.subtitle, post.imageLink, post.productLink ];
    
    NSString *format = @"INSERT OR REPLACE INTO favored_posts (%@) VALUES (%@);";
    NSString *sql = DefStr(format, [keys componentsJoinedByString:@","], [questions componentsJoinedByString:@","]);
    
    [_fmDB executeUpdate:sql withArgumentsInArray:params];
}

- (void)unfavorPostWithId:(NSInteger)postId {
    [_fmDB executeStatements:DefStr(@"DELETE from favored_posts where post_id=%d", postId)];
}

- (NSArray *)favoredPosts {
    FMResultSet *s = [_fmDB executeQueryWithFormat:@"SELECT * from favored_posts;"];
    NSMutableArray *result = [NSMutableArray new];
    while ([s next]) {
        ProductHuntPost *post = [ProductHuntPost new];
        post.postId = [s intForColumn:@"post_id"];
        post.title = [s stringForColumn:@"title"];
        post.subtitle = [s stringForColumn:@"subtitle"];
        post.imageLink = [s stringForColumn:@"image_url"];
        post.productLink = [s stringForColumn:@"url"];
        [result addObject:post];
    }
    return result;
}

@end
