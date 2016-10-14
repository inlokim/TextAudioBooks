//
//  CustomSlideSegue.h
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 13..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomSlideSegue : UIStoryboardSegue

@property (strong, nonatomic) UIViewController *sourceViewController;
@property (strong, nonatomic) UIViewController *destinationViewController;

@end
