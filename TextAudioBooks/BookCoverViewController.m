//
//  ContentsViewController.m
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 6..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BookCoverViewController.h"
#import "ContentsViewController.h"
#import "Utils.h"


@interface BookCoverViewController ()
{
    IBOutlet UIImageView *imageView;
    IBOutlet UIButton *contentsButton;
    IBOutlet UIActivityIndicatorView *activityIndicator;
}
@property (strong, nonatomic) UIView *overlayView;


@end

@implementation BookCoverViewController

@synthesize appRecord;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [imageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [imageView.layer setBorderWidth: 3.0];
    
    [activityIndicator setHidden:YES];
    
    NSString *fileName = [Utils fileDir:appRecord.bookType bookId:appRecord.bookId];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@/images/iPhoneBack.png", [Utils homeDir], fileName];
    imageView.image =  [UIImage imageWithContentsOfFile:path];

    if (imageView.image == nil)
    {
        NSLog(@"Wait a moment...");

        [activityIndicator setHidden:NO];
        [contentsButton setEnabled:NO];
    }
    
    
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"])
    {
        ContentsViewController *controller = (ContentsViewController *)[segue destinationViewController];
        
        [controller setAppRecord:appRecord];

        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}


@end
