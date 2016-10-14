//
//  BookViewController.h
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 3..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppRecord.h"


@import AVFoundation;

@interface BookViewController : UITableViewController <NSXMLParserDelegate,  AVAudioPlayerDelegate>

@property (strong, nonatomic) AppRecord *appRecord;
@property (strong, nonatomic) NSString *fileId;

@end
