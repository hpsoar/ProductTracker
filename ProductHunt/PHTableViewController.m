//
//  PHTableViewController.m
//  ProductHunt
//
//  Created by HuangPeng on 12/13/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "PHTableViewController.h"

@implementation PHTableViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (iOSOver(8)) {
        self.tableView.preservesSuperviewLayoutMargins = NO;
        self.tableView.layoutMargins = UIEdgeInsetsZero;
        self.tableView.separatorInset = UIEdgeInsetsZero;
    }
}

@end
