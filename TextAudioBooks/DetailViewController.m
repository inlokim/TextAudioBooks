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
    
}

@end

@implementation DetailViewController

@synthesize appRecord;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = appRecord.title;
    
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"appRecord.title :%@", appRecord.title);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
