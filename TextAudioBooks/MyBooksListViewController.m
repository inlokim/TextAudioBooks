/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Controller for the main table view of the LazyTable sample.
 This table view controller works off the AppDelege's data model.
 produce a three-stage lazy load:
 1. No data (i.e. an empty table)
 2. Text-only data from the model's RSS feed
 3. Images loaded over the network asynchronously
 
 This process allows for asynchronous loading of the table to keep the UI responsive.
 Stage 3 is managed by the AppRecord corresponding to each row/cell.
 
 Images are scaled to the desired height.
 If rapid scrolling is in progress, downloads do not begin until scrolling has ended.
 */

#import "MyBooksListViewController.h"
#import "Utils.h"
#import "AppRecord.h"
#import "MyBooksCell.h"
#import "BookCoverViewController.h"
#import "CustomSegue.h"
#import "CustomUnwindSegue.h"
#import "AppDelegate.h"
#import "FileDownloadInfo.h"
#import "SSZipArchive.h"
//#import "AFURLSessionManager.h"
//#import "UIProgressView+AFNetworking.h"

#define SAMPLE NO
#define FULL YES
#define CellProgressBarTagValue         40
#define MYBOOKS_PLIST  @"myBooks.plist"

static NSString *fileHome = @"http://inlokim.com/textAudioBooks/files/";

#pragma mark -

@interface MyBooksListViewController ()
{
    NSMutableArray *entries;
    AppRecord *aBook;
    AppDelegate *app;
    Boolean downloadType;
    NSString *fileName;
    
    Boolean downloadCompleted;
}

//@property (nonatomic, strong) NSMutableArray *products;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURL *docDirectoryURL;
@property (nonatomic, strong) NSMutableArray *arrFileDownloadData;

@end


#pragma mark -

@implementation MyBooksListViewController

static NSString *CellIdentifier = @"MyBooksCell";
//static NSString *PlaceholderCellIdentifier = @"PlaceholderCell";

// -------------------------------------------------------------------------------
//	viewDidLoad
// -------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    downloadCompleted = NO;
       // [self.tableView registerClass:[StoreCell class] forCellReuseIdentifier:CellIdentifier];
    
    [self getPesistence];
    
    //NSLog(@"entries count : %d", (int)entries.count);
    
    [self.tableView reloadData];
    
    //after auto tab bar changed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeTableData:)
                                                 name:@"changeTableData" object:nil];
    
    
    //price
   // self.products = [[NSMutableArray alloc] initWithCapacity:0];
    
    //download
    
    app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //Download
    
    //[self initializeFileDownloadDataArray];
    
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    self.docDirectoryURL = [URLs objectAtIndex:0];
    
    //NSLog(@"docDirectoryURL : %@",[self.docDirectoryURL path] );

    //u_int32_t value = arc4random();
    int value = 0;
    NSString *sessionId = [NSString stringWithFormat:@"kr.co.highwill.TextAudioBooks_%d",value];
    
    //NSLog(@"session id = %@", sessionId);
    
    NSURLSessionConfiguration *sessionConfiguration
    = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionId];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 2;
    
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
}

- (void)didChangeTableData:(NSNotification *)notification
{
    if ([notification.object isKindOfClass:[AppRecord class]])
    {
        aBook = [notification object];

        if ([aBook.bookType isEqualToString:@"1"]) downloadType = SAMPLE;
        else if ([aBook.bookType isEqualToString:@"2"]) downloadType = FULL;
        
        [self startDownload];
    }
    else
    {
        //NSLog(@"Error, object not recognised.");
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"changeTableData"
                                                  object:aBook];
}


// -------------------------------------------------------------------------------
//	didReceiveMemoryWarning
// -------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
/*
- (void)viewWillAppear:(BOOL)animated
{
    //NSLog(@"viewWillAppear");
    
    [self.tableView reloadData];
}
*/

#pragma mark - loadTableData


- (void)getPesistence
{
    NSString *filePath =
    [[Utils homeDir] stringByAppendingPathComponent:MYBOOKS_PLIST];

    NSMutableArray *myBooks = [[NSMutableArray alloc] initWithCapacity:10];
    /*
     myBooks.plist 구조
     <plist version="1.0">
     <array>
     <string>chimes:The Chimes:Charles Dickens:1</string>
     <string>Tales_From_Shakespeare2:Tales From Shakespeare Vol.2:Charles Lamb, Mary Lamb:1</string>
     </array>
     </plist>
     */
    
    //BookType sample=1, buy=2
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSArray *array = [[NSArray alloc] initWithContentsOfFile:filePath];
        //NSLog(@"array count = %d",(int)[array count]);
        

            // for (int i=0; i < [array count] ; i ++)
            for (int i=(int)[array count]-1 ; i >= 0 ; i --)
            {
                //역순으로 넣기
                NSString *string = [array objectAtIndex:i];
                NSArray *chunks = [string componentsSeparatedByString: @":"];
                
                AppRecord  *appRecord =[[AppRecord alloc]init];
                appRecord.bookId = [chunks objectAtIndex:0];
                ////NSLog(@"aBook.bookId=%@",appRecord.bookId);
                
                ////NSLog(@"chunks2 : %@ ",[chunks objectAtIndex:2]);
                ////NSLog(@"chunks3 : %@ ",[chunks objectAtIndex:3]);
                ////NSLog(@"chunks4 : %@ ",[chunks objectAtIndex:4]);
                
                ////NSLog(@"chunks count : %d", (int)chunks.count);
                
                if (chunks.count > 1)
                {
                    appRecord.title = [chunks objectAtIndex:1];
                    ////NSLog(@"title : %@ ",[chunks objectAtIndex:1]);
                }
                
                if (chunks.count > 2)
                {
                    appRecord.author = [chunks objectAtIndex:2];
                    ////NSLog(@"author : %@ ",[chunks objectAtIndex:2]);
                }
                
                if (chunks.count > 3)
                {
                    appRecord.bookType = [chunks objectAtIndex:3];
                    ////NSLog(@"bookType : %@ ",[chunks objectAtIndex:3]);
                }
                
                [myBooks addObject:appRecord];
                
                /******************************
                 GET Local Image
                 ******************************/
                appRecord.localImageURL =
                [NSString stringWithFormat:@"%@/%@_cover.png", [Utils homeDir], appRecord.bookId];
                //////NSLog(@"aBook.localImageURL=%@",appRecord.localImageURL);
            }
            entries = myBooks;
     
    }
}


-(void)emptySandbox
{
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *files = [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    while (files.count > 0) {
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error];
        if (error == nil) {
            for (NSString *path in directoryContents) {
                NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:path];
                BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
                files = [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:nil];
                if (!removeSuccess) {
                    // Error
                }
            }
        } else {
            // Error
        }
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return entries.count;
}


// -------------------------------------------------------------------------------
//	tableView:cellForRowAtIndexPath:
// -------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //StoreCell *cell = nil;
    MyBooksCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Set up the cell representing the app
    AppRecord * appRecord = [entries objectAtIndex:indexPath.row];
    
   // //NSLog(@"appRecord title : %@", appRecord.title);
   // //NSLog(@"indexPath row : %d", (int)indexPath.row);
    
    [cell.imageView.layer setBorderColor: [[UIColor lightGrayColor] CGColor]];
    [cell.imageView.layer setBorderWidth: 1.0];
    
    cell.titleLabel.text= appRecord.title;
    cell.authorLabel.text = appRecord.author;
    cell.imageView.image = [UIImage imageWithContentsOfFile:appRecord.localImageURL];
    
    [cell.progressView setHidden:YES];
    [cell.progressLabel setHidden:YES];
    
    cell.progressView.progress = 0.0;
    
    if ([appRecord.bookType isEqualToString:@"1"])//sample=1
    {
        [cell.sampleView setHidden:NO];
    }
    else //full
    {
        [cell.sampleView setHidden:YES];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2)
    {
        [cell setBackgroundColor:[UIColor colorWithRed:.99 green:.99 blue:.99 alpha:1]];
    }
    else [cell setBackgroundColor:[UIColor whiteColor]];
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    NSString *filePath =
    [[Utils homeDir] stringByAppendingPathComponent:MYBOOKS_PLIST];
    NSMutableArray *array = [[NSMutableArray alloc] initWithContentsOfFile:filePath];

    AppRecord * appRecord = [entries objectAtIndex:indexPath.row];
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        /*********************************
         My Books - MyBooks.plist 수정
         **********************************/

        //NSLog(@"array count = %d",(int)[array count]);
        
        for (int i=0; i < [array count] ; i ++)
        {
            NSString *string = [array objectAtIndex:i];
            NSArray *chunks = [string componentsSeparatedByString: @":"];
            

            NSString *myBookId = [chunks objectAtIndex:0];
            
            if ([myBookId isEqual:appRecord.bookId]){
                [array removeObjectAtIndex:i];
            }
        }
        
        [array writeToFile:filePath atomically:YES];
        
        /*********************************
         My Books - 관련 파일 삭제
         **********************************/
        //BookType sample=1, buy=2
        NSString *flag = [[NSString alloc] init];
        if ([appRecord.bookType isEqualToString:@"1"]) flag = @"_preview";
        else if ([appRecord.bookType isEqualToString:@"2"]) flag = @"_full";
        
        //NSLog(@"Delete Files");
        
        NSString *fName = [Utils fileDir:appRecord.bookType bookId:appRecord.bookId];
        NSString *file = [NSString stringWithFormat:@"%@/%@", [Utils homeDir], fName];
        
        NSString *imageFile = [NSString stringWithFormat:@"%@/%@_cover.png", [Utils homeDir], appRecord.bookId];
        NSString *macFile = [NSString stringWithFormat:@"%@/_MACOSX", [Utils homeDir]];
        //NSString *zipFile = [NSString stringWithFormat:@"%@/%@%@", [Utils homeDir], appRecord.bookId,flag];

       // NSString *plistFile = [NSString stringWithFormat:@"%@/%@.plist", [Utils homeDir], fileName];
        //NSLog(@"fileName : %@", fileName);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:file error:NULL];
        [fileManager removeItemAtPath:imageFile error:NULL];
        [fileManager removeItemAtPath:macFile error:NULL];
        //[fileManager removeItemAtPath:zipFile error:NULL];
        
       // [fileManager removeItemAtPath:plistFile error:NULL];
        
        // Delete the row from the data source.
        [entries removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        
        if (entries.count == 0) [self emptySandbox];
    }
    // else if (editingStyle == UITableViewCellEditingStyleInsert) {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    // }
}



/*- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"didSelectRowAtIndexPath");
 
   // self.someProperty = [self.someArray objectAtIndex:indexPath.row];
        MyBooksCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ([cell.progressLabel.text isEqualToString:@"100.0"])
    {
        [self performSegueWithIdentifier:@"showDetail" sender:self];
    }
}

*/


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //NSLog(@"prepareForSegue");
    
    if ([[segue identifier] isEqualToString:@"showDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        AppRecord *appRecord = (entries)[indexPath.row];
        
        //NSLog(@"appRecord.title : %@",appRecord.title);
        
        //NSDate *object = self.objects[indexPath.row];
        BookCoverViewController *controller =
        (BookCoverViewController *)[[segue destinationViewController] topViewController];
        
        [controller setAppRecord:appRecord];
    }
}

/*
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    downloadCompleted = NO;
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSLog(@"indexPath.row : %ld", (long)indexPath.row);
    if ([app.arrFileDownloadData count] > 0)
    {
        
        FileDownloadInfo *fdi = [app.arrFileDownloadData objectAtIndex:indexPath.row];
        
        if (fdi.isDownloading == YES) downloadCompleted = NO;
        else downloadCompleted = YES;
    }
    //다운로드 된 이후에 segue가 작동한다.
    return downloadCompleted;
}
 */


// This is the IBAction method referenced in the Storyboard Exit for the Unwind segue.
// It needs to be here to create a link for the unwind segue.
// But we'll do nothing with it.
- (IBAction)unwindFromViewController:(UIStoryboardSegue *)sender
{
    //NSLog(@"unwindFromViewController");
}

// We need to over-ride this method from UIViewController to provide a custom segue for unwinding
- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    // Instantiate a new CustomUnwindSegue
    CustomUnwindSegue *segue = [[CustomUnwindSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    // Set the target point for the animation to the center of the button in this VC
    segue.targetPoint = self.view.center;
    
    return segue;
}

#pragma mark - Download

/*-(void)initializeFileDownloadDataArray
{
    //app.arrFileDownloadData = [[NSMutableArray alloc] init];
    NSLog(@"app.arrFileDownloadData count:%d", [app.arrFileDownloadData count]);

    if (downloadType == SAMPLE)
        fileName = [NSString stringWithFormat:@"%@_preview.zip",aBook.bookId];
    else if (downloadType == FULL)
        fileName = [NSString stringWithFormat:@"%@_full.zip",aBook.bookId];
    
    //NSLog(@"##downloadType : %d", downloadType);
    NSLog(@"##fileName : %@", fileName);
    
    [app.arrFileDownloadData addObject:[[FileDownloadInfo alloc] initWithFileTitle:aBook.bookId andDownloadSource:[fileHome stringByAppendingString:fileName]]];
}
*/

-(int)getFileDownloadInfoIndexWithTaskIdentifier:(unsigned long)taskIdentifier
{
    int index = 0;
    
    /*NSArray *sortedArray = [app.arrFileDownloadData sortedArrayUsingDescriptors:
                            @[[NSSortDescriptor sortDescriptorWithKey:nil
                                                            ascending:NO
                                                             selector:@selector(localizedCompare:)
                               ]]];*/
    
    
    NSArray* reversed = [[app.arrFileDownloadData reverseObjectEnumerator] allObjects];
    
    for (int i=0; i<[app.arrFileDownloadData count]; i++)
    {
        FileDownloadInfo *fdi = [reversed objectAtIndex:i];
  
        if (fdi.taskIdentifier == taskIdentifier)
        {
            index = i;
            break;
        }
    }
    
    return index;
}

- (void) startDownload
{
    NSLog(@"startDownload");
    
    if (downloadType == SAMPLE)
        fileName = [NSString stringWithFormat:@"%@_preview.zip",aBook.bookId];
    else if (downloadType == FULL)
        fileName = [NSString stringWithFormat:@"%@_full.zip",aBook.bookId];
    
    //NSLog(@"##downloadType : %d", downloadType);
    NSLog(@"##fileName : %@", fileName);
    
    if ([app.arrFileDownloadData count] == 0)
    {
        [app.arrFileDownloadData addObject:[[FileDownloadInfo alloc] initWithFileTitle:aBook.bookId andDownloadSource:[fileHome stringByAppendingString:fileName]]];
        
        [self getPesistence];
        //[self.tableView reloadData];
        
        FileDownloadInfo *fdi = [app.arrFileDownloadData objectAtIndex:0];
        
        // Check if should create a new download task using a URL, or using resume data.
        if (fdi.taskIdentifier == -1)
        {
            //NSLog(@"taskIdentifier == -1");
            fdi.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
        }
        else
        {
            fdi.downloadTask = [self.session downloadTaskWithResumeData:fdi.taskResumeData];
        }
        
        // Keep the new taskIdentifier.
        fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
        
        // Start the download.
        [fdi.downloadTask resume];
        
        // Indicate for each file that is being downloaded.
        fdi.isDownloading = YES;
        
    }
    else
    {
        NSLog(@"You can download only one book at a time.");
        
        [self alertWithTitle:@"Sorry." message:@"You can download only one book at a time."];
    }
    
/*
    
    NSLog(@"##app.arrFileDownloadData count : %lu", [app.arrFileDownloadData count]);
    
    // Access all FileDownloadInfo objects using a loop.
    for (int i=0; i<[app.arrFileDownloadData count]; i++)
    {
        FileDownloadInfo *fdi = [app.arrFileDownloadData objectAtIndex:i];
        
        // Check if a file is already being downloaded or not.
        // 다운로중이 아니라면
        if (!fdi.isDownloading)
        {
            [self getPesistence];
            //[self.tableView reloadData];
            
            // Check if should create a new download task using a URL, or using resume data.
            if (fdi.taskIdentifier == -1)
            {
                //NSLog(@"taskIdentifier == -1");
                fdi.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
            }
            else
            {
                fdi.downloadTask = [self.session downloadTaskWithResumeData:fdi.taskResumeData];
            }
            
            // Keep the new taskIdentifier.
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
            
            // Start the download.
            [fdi.downloadTask resume];
            
            // Indicate for each file that is being downloaded.
            fdi.isDownloading = YES;
        }
        else
        {
            NSLog(@"you can download only one book at a time.");
        }
    }*/
}

#pragma mark Display message

-(void)alertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}




#pragma mark - NSURLSession Delegate method implementation

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *destinationFilename = downloadTask.originalRequest.URL.lastPathComponent;
    NSURL *destinationURL = [self.docDirectoryURL URLByAppendingPathComponent:destinationFilename];
    
    if ([fileManager fileExistsAtPath:[destinationURL path]]) {
        [fileManager removeItemAtURL:destinationURL error:nil];
    }
    
    BOOL success = [fileManager copyItemAtURL:location
                                        toURL:destinationURL
                                        error:&error];
    
    if (success)
    {
        NSLog(@"download success");
        
        // Change the flag values of the respective FileDownloadInfo object.
        //int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
        
        FileDownloadInfo *fdi = [app.arrFileDownloadData objectAtIndex:0];
        
        fdi.isDownloading = NO;
        fdi.downloadComplete = YES;
        
        // Set the initial value to the taskIdentifier property of the fdi object,
        // so when the start button gets tapped again to start over the file download.
        fdi.taskIdentifier = -1;
        
        // In case there is any resume data stored in the fdi object, just make it nil.
        fdi.taskResumeData = nil;
        
       // [self unZipping : fdi.fileTitle];
       // [self deleteFile : fdi.fileTitle];
        
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
 
            // Reload the respective table view row using the main thread.
              [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                   withRowAnimation:UITableViewRowAnimationNone];
            
        }];
    }
    else
    {
        NSLog(@"Unable to copy temp file. Error: %@", [error localizedDescription]);
    }
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
   
    if (error != nil)
    {
        NSLog(@"Download completed with error: %@", [error localizedDescription]);
    }
    else
    {
        NSLog(@"Download finished successfully.");
       
        //다운로딩이 더 이상 없다면 배열을 초기화한다.
        app.arrFileDownloadData = [[NSMutableArray alloc] init];
    }
    
    [self unZipAndDeleteFiles];
}

-(void)unZipAndDeleteFiles
{
    NSLog(@"unZipAndDeleteFiles");
    
    NSString *match = @"*.zip";
    NSArray *results = [self matchFiles:match];
    
    for (int i = 0; i < results.count; i++)
    {
        NSLog(@"results : %@",[results objectAtIndex:i]);
        
        NSString *zipFile = [results objectAtIndex:i];
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",[Utils homeDir], zipFile];
        
        [SSZipArchive unzipFileAtPath:fullPath toDestination:[Utils homeDir]];
        
        //만일 full과 동일한 preview path가 존재한다면 preview path를 삭제한다.
        NSRange range = [zipFile  rangeOfString: @"_full" options: NSCaseInsensitiveSearch];
        NSLog(@"found: %@", (range.location != NSNotFound) ? @"Yes" : @"No");
        
        NSMutableString *mutableString = [zipFile mutableCopy];
        
        if (range.location != NSNotFound)
        {
            NSString* searchWord = @"_full.zip";
            NSString* replaceWord = @"_preview";
            
            [mutableString replaceOccurrencesOfString:searchWord withString:replaceWord options: (NSStringCompareOptions)nil range:NSMakeRange(0, [mutableString length])];
            NSLog(@"%@", mutableString);
            
            NSString *prevFile = [NSString stringWithFormat:@"%@/%@",[Utils homeDir],[NSString stringWithString:mutableString]];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:prevFile error:NULL];
        }
        
        //zip 파일을 삭제한다.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:fullPath error:NULL];
    }
}


- (NSArray *) matchFiles:(NSString *)match
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *defaultPath = [Utils homeDir];
    NSError *error;
    
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:defaultPath
                                                                  error:&error];
    //NSString *match = @"*.zip";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", match];
    NSArray *results = [directoryContents filteredArrayUsingPredicate:predicate];
    
    return results;
}


/*

- (void)unZipping : (NSString *)fileTitle
{
    
    NSString *filePath;
    
    if (downloadType == SAMPLE)
        filePath = [NSString stringWithFormat:@"%@/%@_preview.zip",[Utils homeDir],fileTitle];
    else if (downloadType == FULL)
        filePath = [NSString stringWithFormat:@"%@/%@_full.zip",[Utils homeDir],fileTitle];

    NSLog(@"unZip : filePath : %@", filePath);
    
    [SSZipArchive unzipFileAtPath:filePath toDestination:[Utils homeDir]];
}

- (void)deleteFile : (NSString *)fileTitle
{
    NSString *filePath;
    
    if (downloadType == SAMPLE)
        filePath = [NSString stringWithFormat:@"%@/%@_preview.zip",[Utils homeDir],fileTitle];
    else if (downloadType == FULL)
        filePath = [NSString stringWithFormat:@"%@/%@_full.zip",[Utils homeDir],fileTitle];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:NULL];
    
    if (downloadType == FULL)
    {
        NSString *prevFile = [NSString stringWithFormat:@"%@/%@_preview",[Utils homeDir],fileTitle];
        fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:prevFile error:NULL];
    }
}
*/
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown)
    {
        NSLog(@"Unknown transfer size");
    }
    else
    {
        // Locate the FileDownloadInfo object among all based on the taskIdentifier property of the task.
        int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
        
        //NSLog(@"index = %d", index);
        //NSLog(@"downloadTask.taskIdentifier : %d", downloadTask.taskIdentifier);
        
        FileDownloadInfo *fdi = [app.arrFileDownloadData objectAtIndex:index];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Calculate the progress.
            fdi.downloadProgress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            
            // Get the progress view of the appropriate cell and update its progress.
            //NSLog(@"index : %d", index);
 
            MyBooksCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            
            [cell.progressView setHidden:NO];
            [cell.progressLabel setHidden:NO];
            
            //UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:CellProgressBarTagValue];
            
         /*   if ([[NSString stringWithFormat:@"%.1f",fdi.downloadProgress] isEqualToString:@"1.0"])
            {
                NSLog(@"fdi.downloadProgress : %.1f", fdi.downloadProgress);
                fdi.isDownloading = NO;
                fdi.downloadComplete = YES;
                fdi.taskIdentifier = -1;
                fdi.taskResumeData = nil;
            }*/
            
            cell.progressView.progress = fdi.downloadProgress;
            cell.progressLabel.text = [NSString stringWithFormat:@"%.1f %%", fdi.downloadProgress*100];
        }];
    }
}

-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    //NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    // Check if all download tasks have been finished.
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        if ([downloadTasks count] == 0)
        {
            if (appDelegate.backgroundTransferCompletionHandler != nil) {
                // Copy locally the completion handler.
                void(^completionHandler)() = appDelegate.backgroundTransferCompletionHandler;
                
                // Make nil the backgroundTransferCompletionHandler.
                appDelegate.backgroundTransferCompletionHandler = nil;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // Call the completion handler to tell the system that there are no other background transfers.
                    completionHandler();
                    
                    // Show a local notification when all downloads are over.
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody = @"All files have been downloaded!";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }];
            }
        }
    }];
}


-(void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}



@end
