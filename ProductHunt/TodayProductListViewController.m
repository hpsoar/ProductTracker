//
//  TodayProductListViewController.m
//  ProductHunt
//
//  Created by HuangPeng on 11/2/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "TodayProductListViewController.h"
#import "ProductHuntSession.h"

@interface TodayProductListViewController ()

@end

@implementation TodayProductListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMostRecent tag:0];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Today";
}

@end
