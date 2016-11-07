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
#import "TBXML.h"
#import "Script.h"

#define MYBOOKS_PLIST  @"myBooks.plist"


@interface BookViewController ()
{
    BOOL xmlExists;
    
    //XML
    NSXMLParser *xmlParser;
    NSMutableArray *arrNeighboursData;
    NSMutableDictionary *dictTempDataStorage;
    NSMutableString *foundValue;
    NSString *currentElement;
    NSString *currentAttribute;
    
    
    TBXML					* tbxml;
    
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
    
    //NSString *fileId;
    
    IBOutlet UIBarButtonItem * playButton;
    IBOutlet UIBarButtonItem * prevButton;
    IBOutlet UIBarButtonItem * nextButton;
}

@end

@implementation BookViewController

@synthesize appRecord;
//@synthesize fileId;
@synthesize contentsIndex;
@synthesize contentsArray;

static NSString *cellIdentifier = @"MyCell";

/*void RouteChangeListener(void *                  inClientData,
 AudioSessionPropertyID	 inID,
 UInt32                  inDataSize,
 const void *            inData);*/


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:NO animated:NO];
    
    self.title = [[contentsArray objectAtIndex:contentsIndex.row] objectForKey:@"title"];
    
    firstTime = TRUE;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize:)
                                                 name:UIContentSizeCategoryDidChangeNotification object:nil];
    //가변적인 테이블 높이를 위해 기본 값 설정
    self.tableView.estimatedRowHeight = 1000.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self XMLSetup];
    [self loadAudio];
    
    
    //Terminate
    
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:app];
    //Buttons
    
    //Contents index
    if (contentsIndex.row > 0) prevButton.enabled = YES;
    else prevButton.enabled = NO;
    
    if (contentsIndex.row < contentsArray.count - 1) nextButton.enabled = YES;
    else nextButton.enabled = NO;
    
}

- (void)viewWillLayoutSubviews {
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0);
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
    /*    xmlExists = false;
     
     NSString *path = [self getAudioPath:@"xml"];
     
     if ([[NSFileManager defaultManager] fileExistsAtPath:path])
     {
     xmlParser = [[NSXMLParser alloc] initWithData:[NSData dataWithContentsOfFile:path]];
     foundValue = [[NSMutableString alloc] init];
     xmlParser.delegate = self;
     [xmlParser parse];
     }*/
    arrNeighboursData = [[NSMutableArray alloc] initWithCapacity:10];
    xmlExists = false;
    
    NSString *path = [self getAudioPath:@"xml"];
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
    
    //  if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    //  {
    NSError *error = nil;
    tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
    
    // if an error occured, log it
    if (error) {
        NSLog(@"Error! %@ %@", [error localizedDescription], [error userInfo]);
        
    } else {
        
        // Obtain root element
        TBXMLElement * root = tbxml.rootXMLElement;
        
        // if root element is valid
        if (root) {
            
            TBXMLElement * sync = [TBXML childElementNamed:@"SYNC" parentElement:root];
            
            while (sync != nil)
            {
                Script * aScript = [[Script alloc] init];
                aScript.startTime = [TBXML valueOfAttributeNamed:@"START" forElement:sync];
                //NSLog(@"startTime=%@",aScript.startTime);
                
                
                TBXMLElement * desc = [TBXML childElementNamed:@"DESC" parentElement:sync];
                aScript.description = [TBXML textForElement:desc];
               // NSLog(@"description=%@",aScript.description);
                
                [arrNeighboursData addObject:aScript];
                
                sync = [TBXML nextSiblingNamed:@"SYNC" searchFromElement:sync];
            }
        }
        
        //NSLog(@"arrNeighboursData count : %d", arrNeighboursData.count);
    }
    
    
}

- (NSString *)getAudioPath : (NSString *) type
{
    //type : xml, mp3
    NSString *fileName = [Utils fileDir:appRecord.bookType bookId:appRecord.bookId];
    NSString *fileId = [[contentsArray objectAtIndex:contentsIndex.row] objectForKey:@"key"];
    NSString *path =
    [NSString stringWithFormat:@"%@/%@/audios/%@.%@", [Utils homeDir], fileName, fileId, type];
    
    return path;
}

-(void)titleBarPressed
{
    NSLog(@"titlePressed");
    if (!player.playing) {
        NSIndexPath *myIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:myIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}
/*
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
        NSString *content = [foundValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [dictTempDataStorage setObject:content forKey:@"Description"];
        
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
        //if (![string isEqualToString:@"\n"]) {
        
        //string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [foundValue appendString:string];
        //}
    }
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    NSLog(@"%@", [parseError localizedDescription]);
}
*/
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
    
    if ([cell isKindOfClass:[BookTableViewCell class]])
    {
        Script * aScript = [arrNeighboursData objectAtIndex:indexPath.row];
        cell.textLabel.text = aScript.description;
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        
        /*
         UIView *backgroundView = [[UIView alloc]initWithFrame:self.tableView.bounds];
         backgroundView.layer.backgroundColor = [[UIColor colorWithRed:0.529 green:0.808 blue:0.822 alpha:0.5]CGColor];
         
         //backgroundView.layer.borderWidth = 0.0f;
         if (indexPath.row == currentRow)
         {
         NSLog(@"#indexPath.row : %d, #currentRow : %d", indexPath.row, currentRow);
         cell.backgroundView = backgroundView;
         }
         
         
         // [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LightYellow.png"]] autorelease];*/
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Script * aScript = [arrNeighboursData objectAtIndex:indexPath.row];
    NSString *startTime = aScript.startTime;
    
    player.currentTime = [startTime floatValue] / 1000;
    currentRow = indexPath.row;
}

#pragma mark - AudioSession handlers

/**************************
 * 오디오를 로드한다.
 *************************/

- (void) loadAudio
{
    NSString *path = [self getAudioPath:@"mp3"];
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
        //NSLog(@"last Row");
        if (!player.playing){
            [updateTimer invalidate];
            updateTimer = nil;
            
            [playButton setTitle:@"Play"];
            //firstTime true로 해주면 마지막 로우에서 버튼 클릭해도 문제 안생김
            firstTime = TRUE;
            
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }
        
        //spleep모드로 빠지는 것을 허가한다.
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    else
    {
        Script *aScript = [self aScriptObject:(int)currentRow+1];
        NSString *startTime = aScript.startTime;
        
        //[[arrNeighboursData objectAtIndex:currentRow+1] objectForKey:@"StartTime"];
        
        float thisEndTime = [startTime floatValue] / 1000;
        
        if (endTime > thisEndTime)
        {
            theIndexPath = [NSIndexPath indexPathForRow:currentRow+1 inSection:0];
            
            //Cell
            BookTableViewCell *cell =
            [self.tableView cellForRowAtIndexPath:theIndexPath];
            cellHeight = (NSUInteger)cell.contentView.frame.size.height;
            
            if ( cellHeight > 300 )
            {
                NSLog(@"Cell height: %f", cell.contentView.frame.size.height);
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

- (Script *)aScriptObject:(int)index
{
    return [arrNeighboursData objectAtIndex:index];
}

#pragma mark - Persistence

/******************************
 GET Persitence Data
 ******************************/

- (void) getPersistData
{
    NSString *fileName = [appRecord.bookId stringByAppendingString:@".plist"];
    NSString *filePath =
    [[Utils homeDir] stringByAppendingPathComponent:fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSArray *array = [[NSArray alloc] initWithContentsOfFile:filePath];
        //NSLog(@"array count = %d",[array count]);
        
        for (int i=0; i < [array count] ; i ++)
        {
            NSString *string = [array objectAtIndex:i];
            NSArray *chunks = [string componentsSeparatedByString: @":"];
            
            NSString *listIndexRow = [chunks objectAtIndex:0];
            NSString *detailIndexRow = [chunks objectAtIndex:1];
            
            if ([listIndexRow isEqualToString:[NSString stringWithFormat:@"%ld",(long)contentsIndex.row]])
            {
                currentRow = [detailIndexRow intValue];
                break;
            }
            else
            {
                currentRow = 0;
            }
        }
    }
    
}

- (void) savePersistData
{
    /*********************************
     SAVE Persistence Data
     **********************************/
    NSString *fileName = [appRecord.bookId stringByAppendingString:@".plist"];
    NSString *filePath =
    [[Utils homeDir] stringByAppendingPathComponent:fileName];
    
    NSMutableArray *array = nil;
    
    //bookId.plist로부터 데이터를 가져온다.
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        array = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    }
    else
    {
        array = [[NSMutableArray alloc] init];
    }
    //NSLog(@"array count = %d",[array count]);
    
    //bookId.plist안에 같은 인덱스 로우 정보가 있다면 삭제한다.
    for (int i=0; i < [array count] ; i ++)
    {
        NSString *string = [array objectAtIndex:i];
        NSArray *chunks = [string componentsSeparatedByString: @":"];
        
        NSString *listIndexRow = [chunks objectAtIndex:0];
        // NSString *detailIndexRow = [chunks objectAtIndex:1];
        
        //       NSLog(@"listIndexRow=%@",listIndexRow);
        //        NSLog(@"detailIndexRow=%@",detailIndexRow);
        
        if ([listIndexRow isEqualToString:[NSString stringWithFormat:@"%d",(int)contentsIndex.row]])
        {
            [array removeObjectAtIndex:i];
        }
    }
    //NSLog(@"indexRow : %d, currentRow : %d ",contentsIndex.row,currentRow);
    [array addObject:[NSString stringWithFormat:@"%d:%d",(int)contentsIndex.row, (int)currentRow]];
    [array writeToFile:filePath atomically:YES];
}

//Buttons

- (IBAction)prevButton:(id)sender
{
    NSLog(@"prevButton");
    [self buttonHandler:contentsIndex.row-1];
}

- (IBAction)nextButton:(id)sender
{
    NSLog(@"nextButton");
    [self buttonHandler:contentsIndex.row+1];
}

- (void)buttonHandler : (NSUInteger)indexRow
{
    [self stopPlayer];
    [playButton setTitle:@"Play"];
    contentsIndex = [NSIndexPath indexPathForRow:indexRow inSection:0];
    [self viewDidLoad];
    [self viewWillAppear:YES];
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
            Script *aScript = [arrNeighboursData objectAtIndex:currentRow];
            NSString *startTime = aScript.startTime;
            
            player.currentTime = [startTime floatValue] / 1000;
            
            if (currentRow == 0) {
                
                NSLog(@"currentRow == 0");
                [self.tableView selectRowAtIndexPath:theIndexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
            }
            
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
    
    //NSLog(@"wwcurrentTime=%f",p.currentTime);
    
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
    
    [self savePersistData];
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
    
    
    [self savePersistData];
}
/*
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
 */

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
    
    
    [self getPersistData];
    
    //NSLog(@"currentRow : %d", currentRow);
    
    /******
     ROW
     ******/
    theIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:0];
    [self.tableView reloadData];
    //첫 로우
    /*    if (currentRow == 0)
     {
     NSLog(@"UITableViewScrollPositionTop");
     [self.tableView selectRowAtIndexPath:theIndexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
     }*/
    //마지막 로우
    if ([arrNeighboursData count] == currentRow)
    {
        NSLog(@"UITableViewScrollPositionBottom");
        [self.tableView selectRowAtIndexPath:theIndexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    }
    else
    {
        //NSLog(@"UITableViewScrollPositionMiddle");
        //NSLog(@"theIndexPath.row : %d", theIndexPath.row);
        
        [self.tableView selectRowAtIndexPath:theIndexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    
    NSLog(@"viewWillDisappear");
    
    [self savePersistData];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSLog(@"terminate");
    [self savePersistData];
}


@end
