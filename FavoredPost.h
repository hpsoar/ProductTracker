//
//  FavoredPost.h
//  ProductHunt
//
//  Created by HuangPeng on 11/28/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface FavoredPost : NSManagedObject

@property (nonatomic, retain) NSNumber * postId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * postURL;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSNumber * voteCount;
@property (nonatomic, retain) NSNumber * commentCount;

@end
