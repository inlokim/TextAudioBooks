//
//  BackgroundSessionManager.h
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 11. 7..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface BackgroundSessionManager : AFHTTPSessionManager

+ (instancetype)sharedManager;

@property (nonatomic, copy) void (^savedCompletionHandler)(void);

@end
