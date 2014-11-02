//
//  ProductDetailViewController.h
//  ProductHunt
//
//  Created by HuangPeng on 11/2/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ProductHuntSession.h"

@interface ProductDetailViewController : UIViewController

- (id)initWithPost:(ProductHuntPost *)post;

@property (nonatomic, readonly) ProductHuntPost *post;
@end
