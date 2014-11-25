//
//  ShareKit.h
//  ProductHunt
//
//  Created by HuangPeng on 11/24/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProductHuntPost.h"

@interface ShareKit : NSObject

+ (instancetype)kit;

- (void)sharePost:(ProductHuntPost*)post inController:(UIViewController *)controller;

@end
