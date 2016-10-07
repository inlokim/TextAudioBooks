//
//  BookViewController.h
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 3..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <UIKit/UIKit.h>

@import AVFoundation;

@interface BookViewController : UITableViewController <NSXMLParserDelegate,  AVAudioPlayerDelegate>

@property (strong, nonatomic) NSString *fileID;
@property (strong, nonatomic) NSString *title;

@end
