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

#define kFavorChangeTimeKey @"kFavorChangeTimeKey"
#define kUploadTimeKey @"kUploadTimeKey"

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
         @"(post_id integer primary key, date text, title text, subtitle text, image_url text, url text, timestamp integer);"];
        
        [_fmDB executeStatements:@"create table if not exists unfavored_posts (post_id integer primary key, timestamp integer);"];
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
    NSDictionary *dict = @{ @"post_id": @(post.postId),
                            @"title": post.title,
                            @"subtitle": post.subtitle,
                            @"image_url": post.imageLink,
                            @"url": post.productLink,
                            @"date": post.date,
                            @"timestamp": @([[NSDate date] timeIntervalSince1970]) };
    [self favorRawPost:dict];
    
    [Utility setUserDefaultObjects:@{ kFavorChangeTimeKey: [NSDate date] }];
}

- (BOOL)favorRawPost:(NSDictionary *)post {
    NSMutableArray *questions = [[NSMutableArray alloc] initWithCapacity:post.allKeys.count];
    while (questions.count < post.allKeys.count) {
        [questions addObject:@"?"];
    }
    
    NSString *format = @"INSERT OR REPLACE INTO favored_posts (%@) VALUES (%@);";
    NSString *sql = DefStr(format, [post.allKeys componentsJoinedByString:@","], [questions componentsJoinedByString:@","]);
    
    return [_fmDB executeUpdate:sql withArgumentsInArray:post.allValues];
}

- (void)unfavorPostWithId:(NSInteger)postId timestamp:(NSTimeInterval)timestamp {
    [_fmDB executeStatements:DefStr(@"INSERT OR Replace into unfavored_posts values(%d, %.0f);", postId, timestamp)];
    [_fmDB executeStatements:DefStr(@"DELETE from favored_posts where post_id=%d;", postId)];
    
    [Utility setUserDefaultObjects:@{ kFavorChangeTimeKey: [NSDate date] }];
}

- (void)unfavorPostWithId:(NSInteger)postId {
    [self unfavorPostWithId:postId timestamp:[[NSDate date] timeIntervalSince1970]];
}

- (NSArray *)favoredPosts {
    NSArray *rawPosts = [self rawFavoredPosts];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:rawPosts.count];
    for (NSDictionary *dict in rawPosts) {
        ProductHuntPost *post = [ProductHuntPost new];
        post.postId = [dict[@"post_id"] integerValue];
        post.title = dict[@"title"];
        post.subtitle = dict[@"subtitle"];
        post.imageLink = dict[@"image_url"];
        post.productLink = dict[@"url"];
        post.date = dict[@"date"];
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
        return;
    }
    
    NSDate *uploadTime = [Utility userDefaultObjectForKey:kUploadTimeKey];
    NSDate *changeTime = [Utility userDefaultObjectForKey:kFavorChangeTimeKey];
    
    NSDate *now = [NSDate date];
    if (uploadTime == nil || [changeTime compare:uploadTime] == NSOrderedDescending) {
        NSData *data = [NSData dataWithContentsOfFile:[Utility filepath:[self dbFilename]]];
        [[iCloud sharedCloud] saveAndCloseDocumentWithName:[self dbFilename] withContent:data completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error) {
            if (error) {
                NIDPRINT(@"%@", error);
            }
            else {
                [Utility setUserDefaultObjects:@{ kUploadTimeKey: now }];
                
                [[iCloud sharedCloud] updateFiles];
            }
        }];
    }
    else {
        [[iCloud sharedCloud] updateFiles];
    }
}

- (NSArray *)deletionMarks {
    FMResultSet *s = [_fmDB executeQueryWithFormat:@"select * from unfavored_posts;"];
    NSMutableArray *result = [NSMutableArray new];
    while ([s next]) {
        [result addObject:[self rawRecord:s]];
    }
    return result;
}

- (NSDictionary *)rawRecord:(FMResultSet *)s {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:[s columnCount]];
    for (int i = 0; i < s.columnCount; ++i) {
        dict[[s columnNameForIndex:i]] = [s objectForColumnIndex:i];
    }
    return dict;
}

- (NSDictionary *)deletionMarkWithId:(NSInteger)postId {
    FMResultSet *s = [_fmDB executeQueryWithFormat:@"select * from unfavored_posts where post_id=%d;", postId];
    if ([s next]) {
        return [self rawRecord:s];
    }
    return nil;
}

- (void)cleanDeletionMarks {
    /*
     * for each deletion mark, if there's a favorite (failed to delete after mark deletion), delete the deletion mark
     */
//    NSArray *deletionMarks = [self deletionMarks];
}

- (NSDictionary *)rawFavoredPostWithId:(NSInteger)postId {
    FMResultSet *s = [_fmDB executeQueryWithFormat:@"select * from favored_posts where post_id=%d", postId];
    if ([s next]) {
        return [self rawRecord:s];
    }
    return nil;
}

- (void)syncDeletionsFromFavorDB:(FavorDB *)favorDB {
    NSArray *deletionMarks = [favorDB deletionMarks];
    for (NSDictionary *obj in deletionMarks) {
        NSInteger postId = [[obj objectForKey:@"post_id"] integerValue];
        NSInteger deletionTimestamp = [[obj objectForKey:@"timestamp"] doubleValue];
        NSDictionary  *post = [self rawFavoredPostWithId:postId];
        NSTimeInterval timestamp = [post[@"timestamp"] doubleValue];
        
        if (timestamp > 0 && timestamp < deletionTimestamp) {
            [self unfavorPostWithId:postId timestamp:deletionTimestamp];
        }
    }
}

- (NSArray *)rawFavoredPosts {
    FMResultSet *s = [_fmDB executeQueryWithFormat:@"select * from favored_posts order by date DESC;"];
    NSMutableArray *result = [NSMutableArray new];
    while ([s next]) {
        [result addObject:[self rawRecord:s]];
    }
    return result;
}

- (void)syncFavoredPostsFromFavorDb:(FavorDB *)favorDB {
    NSArray *posts = [favorDB rawFavoredPosts];
    for (NSDictionary *post in posts) {
        NSInteger postId = [post[@"post_id"] integerValue];
        NSDictionary *deletion = [self deletionMarkWithId:postId];
        BOOL shouldAdd = YES;
        if (deletion) {
            NSTimeInterval deletionTimestamp = [deletion[@"timestamp"] doubleValue];
            NSTimeInterval timestamp = [post[@"timestamp"] doubleValue];
            if (timestamp < deletionTimestamp) {
                shouldAdd = NO;
            }
        }
        if (shouldAdd) {
            if (![self favorRawPost:post]) {
                NIDPRINT(@"%@", _fmDB.lastErrorMessage);
            }
        }
    }
}

- (void)syncFromFavorDB:(FavorDB *)favorDB {
    [favorDB cleanDeletionMarks];
    
    /* sync B into A:
     * 1. for each deletion B.deletion, check the corresponding favorite A.favorite:
     *     a. if B.deletion.timestamp > A.favorite.timestamp delete A.favorite
     *     b. otherwise, leave it along
     * 2. for each favorite B.favorite, check the corresponding deletion mark A.deletion:
     *     a. if B.timestamp < A.timestamp, discard B;
     *     b. otherwise, add B to A;
     */
    [self syncDeletionsFromFavorDB:favorDB];
    
    [self syncFavoredPostsFromFavorDb:favorDB];
}

#pragma mark - iCloud Methods

- (void)iCloudAvailabilityDidChangeToState:(BOOL)cloudIsAvailable withUbiquityToken:(id)ubiquityToken withUbiquityContainer:(NSURL *)ubiquityContainer {
    if (!cloudIsAvailable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud Unavailable" message:@"iCloud is no longer available. Make sure that you are signed into a valid iCloud account." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)deleteiCloudFiles:(NSArray *)filenames {
    for (NSString *filename in filenames) {
        [[iCloud sharedCloud] deleteDocumentWithName:filename completion:^(NSError *error) {
            if (error) NIDPRINT(@"%@", error);
        }];
    }
}

- (void)iCloudFilesDidChange:(NSMutableArray *)files withNewFileNames:(NSMutableArray *)fileNames {
    // Get the query results
    NIDPRINT(@"Files: %@", fileNames);
    NIDPRINT(@"%@", files);
    
    for (int i = 0; i < files.count; ++i) {
        NSString *filename = fileNames[i];
        
        if ([filename isEqualToString:[self dbFilename]]) continue;
        
        NSMetadataItem *metaItem = files[i];
        NIDPRINT(@"%@", metaItem.attributes);
        NSDate *updateTime = [metaItem valueForKey:@"kMDItemFSContentChangeDate"];
        NIDPRINT(@"%@", updateTime);
        NSString *syncTimeKey = DefStr(@"favordb_sync_time_%@", filename);
        NSDate *syncTime = [Utility userDefaultObjectForKey:syncTimeKey];
        if (syncTime == nil || [syncTime compare:updateTime] == NSOrderedAscending) {
            [[iCloud sharedCloud] retrieveCloudDocumentWithName:filename completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error) {
                [documentData writeToFile:[Utility filepath:filename] atomically:YES];
                
                FavorDB *favorDB = [[FavorDB alloc] initWithDBPath:[Utility filepath:filename]];
                [self syncFromFavorDB:favorDB];
                
                [Utility setUserDefaultObjects:@{ syncTimeKey: updateTime }];
            }];
        }
    }
}

@end
