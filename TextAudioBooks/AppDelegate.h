//
//  AppDelegate.h
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 2..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) NSMutableArray *arrFileDownloadData;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, copy) void(^backgroundTransferCompletionHandler)();

@end

