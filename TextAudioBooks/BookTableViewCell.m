//
//  BookTableViewCell.m
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 6..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import "BookTableViewCell.h"

@implementation BookTableViewCell
@synthesize textLabel;

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutIfNeeded];
    self.textLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.textLabel.frame);
}


@end

