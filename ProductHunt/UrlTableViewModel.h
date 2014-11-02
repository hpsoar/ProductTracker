//
//  UrlTableViewModel.h
//  ProductHunt
//
//  Created by HuangPeng on 11/1/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "NIMutableTableViewModel.h"

@class UrlTableViewModel;
@protocol UrlTableViewModelDelegate <NSObject>

@optional
- (void)didFinishLoadingFromUrl:(NSString *)url;

- (void)didFailWithError:(NSError *)error;

@end

@interface UrlTableViewModel : NIMutableTableViewModel

- (id)initWithUrl:(NSString *)url delegate:(id<NIMutableTableViewModelDelegate>)delegate;

- (void)load;

@property (nonatomic) BOOL localCacheOn;

@property (nonatomic, readonly) NSString *url;

@end
