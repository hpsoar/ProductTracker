//
//  ShareKit.m
//  ProductHunt
//
//  Created by HuangPeng on 11/24/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "ShareKit.h"
#import <TencentOpenAPI/TencentOAuth.h>

@interface ShareKit () <UMSocialUIDelegate>

@end

@implementation ShareKit

+ (instancetype)kit {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ShareKit new];
    });
    return instance;
}

- (void)sharePost:(ProductHuntPost*)post inController:(UIViewController *)controller {
    NSArray *snsNames = @[ UMShareToSina, UMShareToTencent, UMShareToWechatSession, UMShareToWechatTimeline, UMShareToWechatFavorite, UMShareToQQ, UMShareToQzone, UMShareToEmail ];
    if (![TencentOAuth iphoneQQInstalled]) {
        snsNames = @[ UMShareToSina, UMShareToTencent, UMShareToWechatSession, UMShareToWechatTimeline, UMShareToWechatFavorite, UMShareToEmail ];
    }
    NSString *text = DefStr(@"%@: %@\n %@", post.title, post.subtitle, post.productLink);
    
    [UMSocialSnsService presentSnsIconSheetView:controller appKey:UmengAppkey shareText:text shareImage:post.image shareToSnsNames:snsNames delegate:self];
}

@end
