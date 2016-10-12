//
//  Utils.m
//  PictureEnglish
//
//  Created by 김인로 on 2016. 8. 31..
//  Copyright © 2016년 김인로. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Utils.h"

@implementation Utils


+ (NSString *)homeDir
{
    NSArray *paths =
    //NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    return paths[0];
}

/*
+ (NSString *)cacheDir
{
    NSArray *paths =
    NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths[0];
}
*/


@end
