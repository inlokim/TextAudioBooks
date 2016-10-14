//
//  ContentsViewController.h
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 6..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppRecord.h"


@interface ContentsViewController : UITableViewController <NSXMLParserDelegate>

@property (strong, nonatomic) AppRecord *appRecord;

@end
