//
//  BookViewController.m
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 3..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BookViewController.h"
#import "BookTableViewCell.h"
#import "Utils.h"

@interface BookViewController ()
{
    BOOL xmlExists;
    NSUInteger indexRow;

    
    //XML
    NSXMLParser *xmlParser;
    NSMutableArray *arrNeighboursData;
    NSMutableDictionary *dictTempDataStorage;
    NSMutableString *foundValue;
    NSString *currentElement;
    NSString *currentAttribute;
    
    
    //Audio
    AVAudioPlayer *player;
    NSTimer	*updateTimer;
    
    NSUInteger				currentRow;
    NSUInteger				cellHeight;

    NSString				* myTitle;
    float					endTime;
    
    NSIndexPath				* theIndexPath;
    NSIndexPath				* activateIndexPath;
    
    BOOL					firstTime;
    
    IBOutlet UIBarButtonItem * playButton;
   
}

@end

@implementation BookViewController

@synthesize appRecord;
@synthesize fileId;

static NSString *cellIdentifier = @"MyCell";

void RouteChangeListener(void *                  inClientData,
                         AudioSessionPropertyID	 inID,
                         UInt32                  inDataSize,
                         const void *            inData);


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = appRecord.title;
    
    firstTime = TRUE;
    currentRow = 0;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize:)
                                                 name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    self.tableView.estimatedRowHeight = 200.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
  //  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];

    
    [self XMLSetup];
    [self loadAudio];
    
    /******
     AUDIO
     ******/
 /*   OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, NULL);
    if (result)
        NSLog(@"Error initializing audio session! %ld", result);
    
    [[AVAudioSession sharedInstance] setDelegate: self];
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
    if (setCategoryError)
        NSLog(@"Error setting category! %@", setCategoryError);
    
    result = AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange, RouteChangeListener, (__bridge void *)(self));
    if (result)
        NSLog(@"Could not add property listener! %ld", result);
    
    
  */
    /******
     ROW
     ******/
    theIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:0];
    
/*    //첫 로우
    if (currentRow == 0)
    {
        [self selectRowAtIndexPath:theIndexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
    //마지막 로우
    else if (scripts.count == currentRow)
    {
        NSLog(@"lastRow");
        [tableView selectRowAtIndexPath:theIndexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    }
    else
    {
        [tableView selectRowAtIndexPath:theIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
    */
}

- (void)didChangePreferredContentSize:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIContentSizeCategoryDidChangeNotification
                                                  object:nil];
}



#pragma mark - ViewDisplay


- (void)XMLSetup
{
    xmlExists = false;
    
    NSString *fileName = [Utils fileDir:appRecord.bookType bookId:appRecord.bookId];
    NSString *path =
    [NSString stringWithFormat:@"%@/%@/audios/%@.xml", [Utils homeDir], fileName, fileId];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        xmlParser = [[NSXMLParser alloc] initWithData:[NSData dataWithContentsOfFile:path]];
        foundValue = [[NSMutableString alloc] init];
        xmlParser.delegate = self;
        [xmlParser parse];
    }
}


#pragma mark - NSXMLParser

-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    // Initialize the neighbours data array.
    arrNeighboursData = [[NSMutableArray alloc] init];
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{
    // When the parsing has been finished then simply reload the table view.
    //[self.tblNeighbours reloadData];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
    ///NSString *attributeValue;
    
    // If the current element name is equal to "geoname" then initialize the temporary dictionary.
    if ([elementName isEqualToString:@"SYNC"]) {
        dictTempDataStorage = [[NSMutableDictionary alloc] init];
        //NSLog(@"START : %@", [attributeDict objectForKey:@"START"]);
        currentAttribute = [attributeDict objectForKey:@"START"];
    }
    
    // Keep the current element.
    currentElement = elementName;
    //currentAttribute = attributeValue;
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    if ([elementName isEqualToString:@"SYNC"]) {
        [arrNeighboursData addObject:[[NSDictionary alloc] initWithDictionary:dictTempDataStorage]];
        
    }
    else if ([elementName isEqualToString:@"DESC"]){
        
        //NSLog(@"DESC : %@", [NSString stringWithString:foundValue]);
        
        [dictTempDataStorage setObject:[NSString stringWithString:foundValue] forKey:@"Description"];
        
        //NSLog(@"currentAttribute : %@", currentAttribute);
        [dictTempDataStorage setObject:currentAttribute forKey:@"StartTime"];
    }
    // Clear the mutable string.
    [foundValue setString:@""];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    // Store the found characters if only we're interested in the current element.
    if ([currentElement isEqualToString:@"DESC"])
    {
        if (![string isEqualToString:@"\n"]) {
            
            string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [foundValue appendString:string];
        }
    }
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    NSLog(@"%@", [parseError localizedDescription]);
}

#pragma mark - ViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table View


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return arrNeighboursData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BookTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}


- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[BookTableViewCell class]])
    {
        BookTableViewCell *textCell = (BookTableViewCell *)cell;
        textCell.textLabel.text
        = [[arrNeighboursData objectAtIndex:indexPath.row] objectForKey:@"Description"];
        textCell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *startTime = [[arrNeighboursData objectAtIndex:indexPath.row] objectForKey:@"StartTime"];
    player.currentTime = [startTime floatValue] / 1000;
    
    currentRow = indexPath.row;
}

#pragma mark - AudioSession handlers

/**************************
 * 오디오를 로드한다.
 *************************/

- (void) loadAudio
{
    
    NSString *fileName = [Utils fileDir:appRecord.bookType bookId:appRecord.bookId];
    NSString *path =
    [NSString stringWithFormat:@"%@/%@/audios/%@.mp3", [Utils homeDir], fileName, fileId];
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
    
}

/******************************************
 * 타이머 핸들링
 ******************************************/
- (void)updateCurrentTime
{
    endTime = player.currentTime ;
   
    //마지막 로우
    if (currentRow == (arrNeighboursData.count-1))
    {
        NSLog(@"last Row");
        if (!player.playing){
            [updateTimer invalidate];
            updateTimer = nil;

           // [playButton setImage:playBtnBG forState:UIControlStateNormal];
            //firstTime true로 해주면 마지막 로우에서 버튼 클릭해도 문제 안생김
            firstTime = TRUE;
            
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }
        
        //spleep모드로 빠지는 것을 허가한다.
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    else {
        NSString *startTime = [[arrNeighboursData objectAtIndex:currentRow + 1] objectForKey:@"StartTime"];
        float thisEndTime = [startTime floatValue] / 1000;
        
        
        if (endTime > thisEndTime)
        {
           
            theIndexPath = [NSIndexPath indexPathForRow:currentRow+1 inSection:0];

            //Cell Highlighted
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:theIndexPath];
            cellHeight = (NSUInteger)cell.contentView.frame.size.height;
            
            if ( cellHeight > 300 )
            {
                //NSLog(@"Cell height: %f", cell.contentView.frame.size.height);
                [self.tableView selectRowAtIndexPath:theIndexPath animated:YES
                                 scrollPosition:UITableViewScrollPositionTop];
            }
            else
            {
                [self.tableView
                 selectRowAtIndexPath:theIndexPath animated:YES
                                 scrollPosition:UITableViewScrollPositionMiddle];
            }
          
            currentRow = currentRow + 1;
            
        }
    }
}

/******************************************
 * 버튼 클릭 핸들링
 ******************************************/
- (IBAction)playSound:(id)sender
{
    //플레이중
    if (player.playing)
    {
        NSLog(@"playing pause");
        [playButton setTitle:@"Play"];
        [self pausePlayer:player];
    }
    //플레이가 아니라면
    else
    {
        NSLog(@"playing play");
        [playButton setTitle:@"Stop"];
        
        //이번 화면이 처음 시작이라면 해당 로우를 찾는다.
        if (firstTime)
        {
            NSString *startTime = [[arrNeighboursData objectAtIndex:currentRow] objectForKey:@"StartTime"];

            player.currentTime = [startTime floatValue] / 1000;
            /*if (currentRow == 0) {
             
             NSLog(@"currentRow == 0");
             [tableView selectRowAtIndexPath:theIndexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
             }*/
            theIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:0];
            firstTime = FALSE;
        }

        [self startPlayer:player];
    }
}

/**************
 * 음성 시작
 *************/
-(void)startPlayer:(AVAudioPlayer*)p
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    NSLog(@"wwcurrentTime=%f",p.currentTime);
    
    [p play];
    
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01
                                                   target:self selector:@selector(updateCurrentTime)
                                                 userInfo:player repeats:YES];
    
    //spleep모드로 빠지는 것을 막는다.
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

/**************
 * 음성 멈춤
 *************/
-(void)pausePlayer:(AVAudioPlayer*)p
{
   // [playButton setImage:playBtnBG forState:UIControlStateNormal];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [p pause];
    if ([updateTimer isValid]) {
        NSLog(@"updateTimer isValid");
        [updateTimer invalidate];
        updateTimer = nil;
    }
    
    //spleep모드로 빠지는 것을 허가한다.
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
   // [self savePersistData];
}

/**************
 * 플레이어 stop
 *************/
-(void)stopPlayer {
    
    NSLog(@"Stop Player");
    [player stop];
    if ([updateTimer isValid]) {
        NSLog(@"updateTimer isValid");
        [updateTimer invalidate];
        updateTimer = nil;
    }
    
    //spleep모드로 빠지는 것을 허가한다.
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    
  //  [self savePersistData];
}

void RouteChangeListener(void *                  inClientData,
                         AudioSessionPropertyID	 inID,
                         UInt32                  inDataSize,
                         const void *            inData)
{
    BookViewController* This = (BookViewController*)CFBridgingRelease(inClientData);
    
    if (inID == kAudioSessionProperty_AudioRouteChange) {
        
        CFDictionaryRef routeDict = (CFDictionaryRef)inData;
        NSNumber* reasonValue = (NSNumber*)CFDictionaryGetValue(routeDict, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
        
        int reason = [reasonValue intValue];
        
        if (reason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            
            [This pausePlayer:This->player];
        }
    }
}


#pragma mark AVAudioPlayer delegate methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)p successfully:(BOOL)flag
{
    NSLog(@"test");
    
    if (flag == NO)
        NSLog(@"Playback finished unsuccessfully");
    
    [p setCurrentTime:0.];
    //[self updateViewForPlayerState:p];
}

- (void)playerDecodeErrorDidOccur:(AVAudioPlayer *)p error:(NSError *)error
{
    NSLog(@"ERROR IN DECODE: %@\n", error); 
}


// we will only get these notifications if playback was interrupted
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)p
{
    NSLog(@"Interruption begin. Updating UI for new state");
    // the object has already been paused,	we just need to update UI
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)p
{
    NSLog(@"Interruption ended. Resuming playback");
    [self startPlayer:p];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}


@end
