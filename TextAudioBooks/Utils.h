//
//  Utils.h
//  PictureEnglish
//
//  Created by 김인로 on 2016. 8. 31..
//  Copyright © 2016년 김인로. All rights reserved.
//

@interface Utils : NSObject

+ (NSString *)homeDir;
//+ (NSString *)cacheDir;
+ (NSString *)fileDir :(NSString *)bookType bookId:(NSString *)bookId;
@end
