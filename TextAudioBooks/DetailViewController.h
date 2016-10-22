//
//  DetailViewController.h
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 2..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "AppRecord.h"

@interface DetailViewController : UIViewController <NSURLSessionDelegate>


@property (strong, nonatomic) AppRecord *appRecord;
@property (strong, nonatomic) SKProduct *skProduct;

@end

