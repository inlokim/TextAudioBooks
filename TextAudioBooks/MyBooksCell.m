/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Custom collection view cell for image and its label.
*/

#import "MyBooksCell.h"
//#import "CustomCellBackground.h"
#import "QuartzCore/QuartzCore.h"

@implementation MyBooksCell
@synthesize titleLabel;
@synthesize authorLabel;
@synthesize imageView;
@synthesize sampleView;
@synthesize progressView;
@synthesize progressLabel;


/*
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // change to our custom selected background view
        CustomCellBackground *backgroundView = [[CustomCellBackground alloc] initWithFrame:CGRectZero];
        self.selectedBackgroundView = backgroundView;
    }
    return self;
}
*/



- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}
/*

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutIfNeeded];
    self.titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.titleLabel.frame);
}
*/
 
@end
