//
//  FavorDB.m
//  ProductHunt
//
//  Created by HuangPeng on 11/19/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "FavorDB.h"
#import "FMDB.h"
#import <iCloud/iCloud.h>

@interface FavorDB () <iCloudDelegate>

@end

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
    self = [self initWithDBPath:[Utility filepath:[self dbFilename]]];
    if (self) {
    }
    return self;
}

- (id)initWithDBPath:(NSString *)dbPath {
    self = [super init];
    if (self) {
        _fmDB = [FMDatabase databaseWithPath:dbPath];
        [_fmDB open];
        [_fmDB executeStatements:@"CREATE TABLE IF NOT EXISTS favored_posts "
         @"(post_id integer primary key, title text, subtitle text, image_url text, url text, date integer);"];
        
        [_fmDB executeStatements:@"create table if not exists unfavored_posts (post_id integer primary key, date integer);"];
    }
    return self;
}

- (NSString *)dbFilename {
    NSString *name = @"hunt_posts.db";
    if ([self uuid]) {
        name = DefStr(@"%@_hunt_posts.db", [self uuid]);
    }
    
    return name;
}

- (NSString *)uuid {
    NSString *key = @"hunt_posts_db_uuid";
    NSString *uuidStr = [Utility userDefaultObjectForKey:key];
    if (uuidStr == nil) {
        uuidStr = [Utility UUID];
        if (uuidStr) {
            [Utility setUserDefaultObjects:@{ key: uuidStr }];
        }
    }
    return uuidStr;
}

- (void)dealloc {
    [_fmDB close];
}

- (void)favorPost:(ProductHuntPost *)post {
    NSArray *keys = @[ @"post_id", @"title", @"subtitle", @"image_url", @"url", @"date" ];
    NSMutableArray *questions = [[NSMutableArray alloc] initWithCapacity:keys.count];
    while (questions.count < keys.count) {
        [questions addObject:@"?"];
    }
    
    NSArray *params = @[ @(post.postId), post.title, post.subtitle, post.imageLink, post.productLink , @([[NSDate date] timeIntervalSince1970])];
    
    NSString *format = @"INSERT OR REPLACE INTO favored_posts (%@) VALUES (%@);";
    NSString *sql = DefStr(format, [keys componentsJoinedByString:@","], [questions componentsJoinedByString:@","]);
    
    [_fmDB executeUpdate:sql withArgumentsInArray:params];
}

- (void)unfavorPostWithId:(NSInteger)postId {
    [_fmDB executeStatements:DefStr(@"INSERT OR Replace into unfavored_posts values(%d, %.0f);", postId, [[NSDate date] timeIntervalSince1970])];
    [_fmDB executeStatements:DefStr(@"DELETE from favored_posts where post_id=%d;", postId)];
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

- (BOOL)isPostFavored:(NSInteger)postId {
    FMResultSet *s = [_fmDB executeQueryWithFormat:@"SELECT * from favored_posts where post_id=%d", postId];
    return [s next];
}

- (void)syncWithiCloud {
    [[iCloud sharedCloud] setDelegate:self];
    [[iCloud sharedCloud] setVerboseLogging:YES];
    
    if (![[iCloud sharedCloud] checkCloudAvailability]) {
        NIDPRINT(@"iCloud not availabe");
    }
    
    [[iCloud sharedCloud] updateFiles];
    
    [[iCloud sharedCloud] uploadLocalDocumentToCloudWithName:[self dbFilename] completion:^(NSError *error) {
        if (error) {
            NIDPRINT(@"%@", error);
        }
    }];
}

- (void)syncFromFavorDB:(FavorDB *)favorDB {
    
}

#pragma mark - iCloud Methods

- (void)iCloudAvailabilityDidChangeToState:(BOOL)cloudIsAvailable withUbiquityToken:(id)ubiquityToken withUbiquityContainer:(NSURL *)ubiquityContainer {
    if (!cloudIsAvailable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud Unavailable" message:@"iCloud is no longer available. Make sure that you are signed into a valid iCloud account." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)iCloudFilesDidChange:(NSMutableArray *)files withNewFileNames:(NSMutableArray *)fileNames {
    // Get the query results
    NIDPRINT(@"Files: %@", fileNames);
    for (NSString *filename in fileNames) {
        if (![filename isEqualToString:[self dbFilename]]) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:[Utility filepath:filename]]) {
                [[iCloud sharedCloud] retrieveCloudDocumentWithName:filename completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error) {
                    [documentData writeToFile:[Utility filepath:filename] atomically:YES];
                    
                    FavorDB *favorDB = [[FavorDB alloc] initWithDBPath:[Utility filepath:filename]];
                    [self syncFromFavorDB:favorDB];
                }];
            }
        }
    }
}

@end
