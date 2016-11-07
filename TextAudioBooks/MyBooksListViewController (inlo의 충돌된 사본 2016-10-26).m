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
#import "AFURLSessionManager.h"


#define SAMPLE NO
#define FULL YES

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
    
    NSLog(@"entries count : %d", (int)entries.count);
    
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
    
    [self initializeFileDownloadDataArray];
    
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    self.docDirectoryURL = [URLs objectAtIndex:0];
    
    NSLog(@"docDirectoryURL : %@",[self.docDirectoryURL path] );

    //u_int32_t value = arc4random();
    int value = 0;
    NSString *sessionId = [NSString stringWithFormat:@"kr.co.highwill.TextAudioBooks_%d",value];
    
    NSLog(@"session id = %@", sessionId);
    
    NSURLSessionConfiguration *sessionConfiguration
    = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionId];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 2;
    
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
}

- (void)didChangeTableData:(NSNotification *)notification
{
    NSLog(@"didChangeTableData");
    if ([notification.object isKindOfClass:[AppRecord class]])
    {
        aBook = [notification object];
        // do stuff here with your message data
        [self viewDidLoad];
        //[self viewWillAppear:YES];
        //[self.tableView reloadData];
        
        if ([aBook.bookType isEqualToString:@"1"]) downloadType = SAMPLE;
        else if ([aBook.bookType isEqualToString:@"2"]) downloadType = FULL;
        
        [self startDownload];
    }
    else
    {
        NSLog(@"Error, object not recognised.");
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
    NSLog(@"viewWillAppear");
    
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
        NSLog(@"array count = %d",(int)[array count]);
        

            // for (int i=0; i < [array count] ; i ++)
            for (int i=(int)[array count]-1 ; i >= 0 ; i --)
            {
                //역순으로 넣기
                NSString *string = [array objectAtIndex:i];
                NSArray *chunks = [string componentsSeparatedByString: @":"];
                
                AppRecord  *appRecord =[[AppRecord alloc]init];
                appRecord.bookId = [chunks objectAtIndex:0];
                NSLog(@"aBook.bookId=%@",appRecord.bookId);
                
                NSLog(@"chunks2 : %@ ",[chunks objectAtIndex:2]);
                NSLog(@"chunks3 : %@ ",[chunks objectAtIndex:3]);
                //NSLog(@"chunks4 : %@ ",[chunks objectAtIndex:4]);
                
                NSLog(@"chunks count : %d", (int)chunks.count);
                
                if (chunks.count > 1)
                {
                    appRecord.title = [chunks objectAtIndex:1];
                    NSLog(@"title : %@ ",[chunks objectAtIndex:1]);
                }
                
                if (chunks.count > 2)
                {
                    appRecord.author = [chunks objectAtIndex:2];
                    NSLog(@"author : %@ ",[chunks objectAtIndex:2]);
                }
                
                if (chunks.count > 3)
                {
                    appRecord.bookType = [chunks objectAtIndex:3];
                    NSLog(@"bookType : %@ ",[chunks objectAtIndex:3]);
                }
                
                [myBooks addObject:appRecord];
                
                /******************************
                 GET Local Image
                 ******************************/
                appRecord.localImageURL =
                [NSString stringWithFormat:@"%@/%@_cover.png", [Utils homeDir], appRecord.bookId];
                NSLog(@"aBook.localImageURL=%@",appRecord.localImageURL);
            }
            entries = myBooks;
     
    }
}


-(void)EmptySandbox
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
    
   // NSLog(@"appRecord title : %@", appRecord.title);
   // NSLog(@"indexPath row : %d", (int)indexPath.row);
    
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

        NSLog(@"array count = %d",(int)[array count]);
        
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
        
        NSLog(@"Delete Files");
        
        NSString *fName = [Utils fileDir:appRecord.bookType bookId:appRecord.bookId];
        
        NSString *file = [NSString stringWithFormat:@"%@/%@", [Utils homeDir], fName];
        
        NSString *imageFile = [NSString stringWithFormat:@"%@/%@_cover.png", [Utils homeDir], appRecord.bookId];
       // NSString *plistFile = [NSString stringWithFormat:@"%@/%@.plist", [Utils homeDir], fileName];
        NSLog(@"fileName : %@", fileName);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:file error:NULL];
        [fileManager removeItemAtPath:imageFile error:NULL];
       // [fileManager removeItemAtPath:plistFile error:NULL];
        
        // Delete the row from the data source.
        [entries removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    // else if (editingStyle == UITableViewCellEditingStyleInsert) {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    // }
}



/*- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath");
 
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
    NSLog(@"prepareForSegue");
    
    if ([[segue identifier] isEqualToString:@"showDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        AppRecord *appRecord = (entries)[indexPath.row];
        
        NSLog(@"appRecord.title : %@",appRecord.title);
        
        //NSDate *object = self.objects[indexPath.row];
        BookCoverViewController *controller =
        (BookCoverViewController *)[[segue destinationViewController] topViewController];
        
        [controller setAppRecord:appRecord];
    }
}

/*
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSLog(@"shouldPerformSegueWithIdentifier");
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    AppRecord *appRecord = (entries)[indexPath.row];
    //다운로드 된 이후에 segue가 작동한다.
    return downloadCompleted;
}
*/

// This is the IBAction method referenced in the Storyboard Exit for the Unwind segue.
// It needs to be here to create a link for the unwind segue.
// But we'll do nothing with it.
- (IBAction)unwindFromViewController:(UIStoryboardSegue *)sender
{
    NSLog(@"unwindFromViewController");
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

-(void)initializeFileDownloadDataArray
{
    self.arrFileDownloadData = [[NSMutableArray alloc] init];
    
    if (downloadType == SAMPLE)
        fileName = [NSString stringWithFormat:@"%@_preview.zip",aBook.bookId];
    else if (downloadType == FULL)
        fileName = [NSString stringWithFormat:@"%@_full.zip",aBook.bookId];
    
    NSLog(@"##downloadType : %d", downloadType);
    NSLog(@"##fileName : %@", fileName);
    
    [self.arrFileDownloadData addObject:[[FileDownloadInfo alloc] initWithFileTitle:aBook.bookId andDownloadSource:[fileHome stringByAppendingString:fileName]]];
}

-(int)getFileDownloadInfoIndexWithTaskIdentifier:(unsigned long)taskIdentifier
{
    int index = 0;
    for (int i=0; i<[self.arrFileDownloadData count]; i++)
    {
        FileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:i];
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
/*    [self initializeFileDownloadDataArray];
    
    NSLog(@"##downloadType : %d", downloadType);
    
    // Access all FileDownloadInfo objects using a loop.
    for (int i=0; i<[self.arrFileDownloadData count]; i++)
    {
        FileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:i];
        
        // Check if a file is already being downloaded or not.
        if (!fdi.isDownloading)
        {
            // Check if should create a new download task using a URL, or using resume data.
            if (fdi.taskIdentifier == -1)
            {
                NSLog(@"taskIdentifier == -1");
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
    }*/
    
    [self createDownloadTask];
}

- (void)createDownloadTask
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    
    if (downloadType == SAMPLE)
        fileName = [NSString stringWithFormat:@"%@_preview.zip",aBook.bookId];
    else if (downloadType == FULL)
        fileName = [NSString stringWithFormat:@"%@_full.zip",aBook.bookId];
    
    fileName = [NSString stringWithFormat:@"%@/%@",fileHome,fileName];
    
    NSURL *URL = [NSURL URLWithString:fileName];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response)
    {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
    }];
    [downloadTask resume];
}

#pragma mark - NSURLSession Delegate method implementation

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
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
        int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
        FileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:index];
        
        fdi.isDownloading = NO;
        fdi.downloadComplete = YES;
        
        // Set the initial value to the taskIdentifier property of the fdi object,
        // so when the start button gets tapped again to start over the file download.
        fdi.taskIdentifier = -1;
        
        // In case there is any resume data stored in the fdi object, just make it nil.
        fdi.taskResumeData = nil;
        
        [self unZipping : fdi.fileTitle];
        [self deleteFile];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Reload the respective table view row using the main thread.
              [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                   withRowAnimation:UITableViewRowAnimationNone];
        }];
    }
    else{
        NSLog(@"Unable to copy temp file. Error: %@", [error localizedDescription]);
    }
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError");
    
    if (error != nil)
    {
        NSLog(@"Download completed with error: %@", [error localizedDescription]);
    }
    else
    {
        NSLog(@"Download finished successfully.");
        downloadCompleted = YES;
    }
}

- (void)unZipping : (NSString *)fileTile
{
    NSLog(@"unZip : file Title : %@", fileTile);
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",[Utils homeDir],fileTile];
    NSString *zipPath = filePath;
    
    [SSZipArchive unzipFileAtPath:zipPath toDestination:[Utils homeDir]];
}

- (void)deleteFile
{
    NSLog(@"Delete Zip Files");
    
    NSString *zipFile = [NSString stringWithFormat:@"%@/%@",[Utils homeDir],fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:zipFile error:NULL];
    
    if (downloadType == FULL)
    {
        NSString *prevFile = [NSString stringWithFormat:@"%@/%@_preview",[Utils homeDir],aBook.bookId];
        fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:prevFile error:NULL];
    }
}

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
        FileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:index];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Calculate the progress.
            fdi.downloadProgress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            
            // Get the progress view of the appropriate cell and update its progress.
           MyBooksCell *cell =
            [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            
            [cell.progressView setHidden:NO];
            [cell.progressLabel setHidden:NO];
            
            //UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:CellProgressBarTagValue];
            
            cell.progressView.progress = fdi.downloadProgress;
            cell.progressLabel.text = [NSString stringWithFormat:@"%.1f %%", fdi.downloadProgress*100];
        }];
    }
}


-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
    
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






@end
