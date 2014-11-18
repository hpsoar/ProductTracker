//
//  ProductStreamViewController.m
//  ProductHunt
//
//  Created by HuangPeng on 11/2/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "ProductStreamViewController.h"
#import "ProductHuntSession.h"

@interface ProductStreamViewController ()
@end

@implementation ProductStreamViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemHistory tag:0];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Stream";
}

@end
