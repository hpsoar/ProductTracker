//
//  ProductHuntPost.m
//  ProductHunt
//
//  Created by HuangPeng on 11/19/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "ProductHuntPost.h"

#define kProductLink @"productLink"
#define kTitle @"title"
#define kSubtitle @"subtitle"
#define kImageLink @"imageLink"
#define kCommentLink @"commentLink"

@implementation ProductHuntPost
@synthesize image = _image;

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

- (BOOL)createCacheFolderIfNotExists {
    NSString *imageCacheFolder = @"image_cache";
    NSString *filepath = [Utility filepath:imageCacheFolder];
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath isDirectory:&isDir]) {
        NIDASSERT(isDir);
        return YES;
    }
    else {
        NSError *error;
        if ([[NSFileManager defaultManager] createDirectoryAtPath:filepath withIntermediateDirectories:NO attributes:nil error:&error]) {
            return YES;
        }
        else {
            NIDPRINT(@"%@", error);
            return NO;
        }
    }
}

- (UIImage *)image {
    if (_image == nil && [self createCacheFolderIfNotExists]) {
        NSString *filename = DefStr(@"%@/%@", @"image_cache", [Utility md5:self.imageLink]);
        NSString *filepath = [Utility filepath:filename];
        NSData *data = [NSData dataWithContentsOfFile:filepath];
        if (data) {
            _image = [UIImage imageWithData:data];
        }
        else {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.imageLink]];
                if (data) {
                    [data writeToFile:filepath atomically:YES];
                }
            });
        }
    }
    return _image;
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
