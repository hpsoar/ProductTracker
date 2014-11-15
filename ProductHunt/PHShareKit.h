//
//  PHShareKit.h
//  ProductHunt
//
//  Created by HuangPeng on 11/7/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PHShareObject : NSObject

+ (instancetype)objectWithTitle:(NSString *)title description:(NSString *)description image:(UIImage *)image sourceURL:(NSString *)sourceURL;

@end

@interface PHShareKit : NSObject

+ (instancetype)sharedInstance;

- (void)share:(PHShareObject *)object;

@end
