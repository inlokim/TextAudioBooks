//
//  DetailViewController.m
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 2..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
{
    IBOutlet UIScrollView *scrollView;
    IBOutlet UILabel *authorLabel;
    IBOutlet UILabel *titleLabel;
    IBOutlet UILabel *readByLabel;
    IBOutlet UILabel *sizeLabel;
    IBOutlet UILabel *runningTimeLabel;
    IBOutlet UILabel *contentLabel;
    IBOutlet UIImageView *imageView;
}

@end

@implementation DetailViewController

@synthesize appRecord;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = appRecord.title;
    
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"appRecord.title :%@", appRecord.title);
    
    authorLabel.text = appRecord.author;
    titleLabel.text = appRecord.title;
    
    readByLabel.text = [@"Read By " stringByAppendingString:appRecord.reader];
    sizeLabel.text = [@"Size : " stringByAppendingString:appRecord.size];
    runningTimeLabel.text = [@"Running Time : " stringByAppendingString:appRecord.time];
    
    
    contentLabel.text = appRecord.content;
    
    [imageView.layer setBorderColor: [[UIColor grayColor] CGColor]];
    [imageView.layer setBorderWidth: 2.0];
    imageView.image = appRecord.appIcon;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
