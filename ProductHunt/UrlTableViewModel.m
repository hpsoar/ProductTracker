//
//  UrlTableViewModel.m
//  ProductHunt
//
//  Created by HuangPeng on 11/1/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "UrlTableViewModel.h"
#import "Utility.h"
#import "AFHTTPSessionManager.h"

@implementation UrlTableViewModel

- (id)initWithUrl:(NSString *)url delegate:(id<NIMutableTableViewModelDelegate>)delegate {
    self = [super initWithDelegate:delegate];
    if (self) {
        _url = url;
    }
    return self;
}

- (void)load {
    if (self.localCacheOn) {
        [self loadFromFile];
    }
    
    [self loadFromUrl:self.url];
}

- (void)loadFromUrl:(NSString *)url {
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil];
    
}

- (void)loadFromFile {
    //NSString *filename = [Utility md5:self.url];
}

- (void)saveToFile {
    
}



@end
