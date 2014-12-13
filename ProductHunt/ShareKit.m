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

- (void)didSelectSocialPlatform:(NSString *)platformName withSocialData:(UMSocialData *)socialData {
    
}

-(void)didCloseUIViewController:(UMSViewControllerType)fromViewControllerType {
    NSLog(@"didClose is %d",fromViewControllerType);
}

//下面得到分享完成的回调
-(void)didFinishGetUMSocialDataInViewController:(UMSocialResponseEntity *)response {
    NSLog(@"didFinishGetUMSocialDataInViewController with response is %@",response);
    //根据`responseCode`得到发送结果,如果分享成功
    if(response.responseCode == UMSResponseCodeSuccess) {
        //得到分享到的微博平台名
        NSLog(@"share to sns name is %@",[[response.data allKeys] objectAtIndex:0]);
    }
}

@end
