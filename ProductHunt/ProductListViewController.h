//
//  ProductListTableViewController.h
//  ProductHunt
//
//  Created by HuangPeng on 11/1/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NICellFactory.h"
#import "ProductHuntSession.h"
#import "PHTableViewController.h"

@interface ProductListViewController : PHTableViewController  <ProductHuntSessionDelegate>

@end

@interface  PostCell: UITableViewCell <NICell>

@end