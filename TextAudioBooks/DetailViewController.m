//
//  DetailViewController.m
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 2..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import "DetailViewController.h"
#import "FileDownloadInfo.h"
#import "Utils.h"
#import "SSZipArchive.h"
#import "AppDelegate.h"
#import "MyModel.h"
#import "StoreManager.h"
#import "StoreObserver.h"

#define SAMPLE NO
#define FULL YES
#define MYBOOKS_PLIST  @"myBooks.plist"

static NSString *fileHome = @"http://inlokim.com/textAudioBooks/files/";

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
    
    
    IBOutlet UIButton *purchaseButton;
    IBOutlet UIButton *sampleButton;
    
    IBOutlet UIProgressView *getSampleProgressView;
    IBOutlet UIProgressView *purchaseProgressView;
    IBOutlet UILabel *getSampleProgressLabel;
    IBOutlet UILabel *purchaseProgressLabel;
    
    NSString *fileName;
    Boolean downloadType;
    UIActivityIndicatorView *spinner;
}

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableArray *arrFileDownloadData;
@property (nonatomic, strong) NSURL *docDirectoryURL;

@end

@implementation DetailViewController

@synthesize appRecord;
@synthesize skProduct;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = appRecord.title;
    
    downloadType = SAMPLE;
    
    [getSampleProgressView setHidden:YES];
    [getSampleProgressLabel setHidden:YES];
    
    [purchaseProgressView setHidden:YES];
    [purchaseProgressLabel setHidden:YES];
    
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"appRecord.title :%@", appRecord.title);
    
    authorLabel.text = appRecord.author;
    titleLabel.text = appRecord.title;
    
    readByLabel.text = [@"Read By " stringByAppendingString:appRecord.reader];
    sizeLabel.text = [@"Size : " stringByAppendingString:appRecord.size];
    runningTimeLabel.text = [@"Running Time : " stringByAppendingString:appRecord.time];

    [purchaseButton setTitle:appRecord.price forState:UIControlStateNormal];
    
    contentLabel.text = appRecord.content;
    
    [imageView.layer setBorderColor: [[UIColor grayColor] CGColor]];
    [imageView.layer setBorderWidth: 1.0];
    imageView.image = appRecord.appIcon;
    
    //Download
    
   // [self initializeFileDownloadDataArray];
    
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    self.docDirectoryURL = [URLs objectAtIndex:0];
    
    NSLog(@"docDirectoryURL : %@",[self.docDirectoryURL path] );
    u_int32_t randomNumber = arc4random();
    NSString *sessionId = [NSString stringWithFormat:@"%@.%@%d", @"kr.co.highwill.TextAudioBooks", appRecord.bookId, randomNumber];
    
    NSLog(@"session id = %@", sessionId);
    
    NSURLSessionConfiguration *sessionConfiguration
    = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionId];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
    
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
    
    
    //purchase
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePurchasesNotification:)
                                                 name:IAPPurchaseNotification
                                               object:[StoreObserver sharedInstance]];
    
    
}

-(void) viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear");
    
    //[self viewDidLoad];
}


-(void) viewWillDisappear:(BOOL)animated
{
    //[self activityIndicatorVisible:NO];
}

-(void) viewWillAppear:(BOOL)animated
{
     NSLog(@"viewWillAppear");
    //-------------------
    // 버튼 SHOW/HIDE
    //-------------------
    [self buttonShowHide];
}

-(void) buttonShowHide
{
    //-------------------
    // 버튼 SHOW/HIDE
    //-------------------
    
    // myBooks.plist로부터 데이터를 가져온다.
    NSString *filePath =
    [[Utils homeDir] stringByAppendingPathComponent:MYBOOKS_PLIST];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSArray *array = [[NSArray alloc] initWithContentsOfFile:filePath];

        if (array.count > 0)
        {
            
            for (int i=0; i < [array count] ; i ++)
            {
                NSString *string = [array objectAtIndex:i];
                NSArray *chunks = [string componentsSeparatedByString: @":"];
                
                NSString *myBookId = [chunks objectAtIndex:0];
                NSLog(@"myBookId=%@ appRecord.bookId=%@",myBookId, appRecord.bookId);
                
                NSString *flag = [chunks objectAtIndex:3];
                
                //My Books에 같은 책이 존재한다면 버튼을 Hide
                if ([myBookId isEqual:appRecord.bookId])
                {
                    if ([flag isEqual:@"1"])
                    {
                        sampleButton.hidden = YES;
                    }
                    else if ([flag isEqual:@"2"])
                    {
                        sampleButton.hidden = YES;
                        purchaseButton.hidden = YES;
                    }
                    break;
                }
            }
        }
        else
        {
            sampleButton.hidden = NO;
            purchaseButton.hidden = NO;
        }
    }
}

-(void) activityIndicatorVisible:(Boolean)show
{
    if (show)
    {
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        UIView *view = self.parentViewController.view;
        
        spinner.center = view.center;
        [view addSubview: spinner];
        [view bringSubviewToFront:spinner];
        spinner.hidesWhenStopped = YES;
        spinner.hidden = NO;
        [spinner startAnimating];
    }
    else
    {
        [spinner stopAnimating];
        [spinner removeFromSuperview];
    }
}

-(void)viewDidLayoutSubviews
{
    [contentLabel sizeToFit];
    
    //NSLog(@"%@", NSStringFromCGRect(contentLabel.frame));
    
    [scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetHeight(contentLabel.frame) + 340)];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - purchase

- (IBAction)purchaseButtonPressed:(id)sender
{
    
    downloadType = FULL;
    
 //   NSLog(@"##prod id : %@", skProduct.productIdentifier);
 //  [[StoreObserver sharedInstance] buy:skProduct];
    [self initializeFileDownloadDataArray];
    [self startDownload];
}


#pragma mark - Get Sample

- (IBAction)getSampleButtonPressed:(id)sender {
    
    downloadType = SAMPLE;
    [self initializeFileDownloadDataArray];
    [self startDownload];
}

#pragma mark - File Download

-(void) savePersistence
{
    NSLog(@"START ************   savePersistence  *****************");
    NSMutableArray *array = nil;
    NSString *homeDir = [Utils homeDir];
    NSString *plist = [homeDir stringByAppendingPathComponent:MYBOOKS_PLIST];
    
    //myBooks.plist로부터 데이터를 가져온다.
    if ([[NSFileManager defaultManager] fileExistsAtPath:plist])
        array = [[NSMutableArray alloc] initWithContentsOfFile:plist];
    else
        array = [[NSMutableArray alloc] init];
    
    NSLog(@"array count = %d",(int)[array count]);
    
    //myBooks.plist안에 샘플 정보가 있다면 삭제한다.
    for (int i=0; i < [array count] ; i ++)
    {
        NSString *string = [array objectAtIndex:i];
        NSArray *chunks = [string componentsSeparatedByString: @":"];
        
        NSString *mybookId = [chunks objectAtIndex:0];
        NSString *mybookType = [chunks objectAtIndex:3];
        
        NSLog(@"bookId : %@   bookType : %@ ",mybookId, mybookType);
        
        if ([mybookId isEqualToString:appRecord.bookId] &&
            [mybookType isEqualToString:@"1"]) //sample
        {
            NSLog(@"appRecord.bookId : %@   mybookId : %@ mybookType :%@",appRecord.bookId, mybookId, mybookType);
            
            [array removeObjectAtIndex:i];
        }
    }
    
    //BookType sample=1, buy=2
    if (downloadType == SAMPLE) appRecord.bookType = @"1";
    else if (downloadType == FULL) appRecord.bookType = @"2";
    
    //download = 1, complete = 2
    
    [array addObject:
     [NSString stringWithFormat:@"%@:%@:%@:%@",appRecord.bookId, appRecord.title, appRecord.author, appRecord.bookType]];
    
    [array writeToFile:plist atomically:YES];
    
    NSLog(@"END ************   savePersistence  *****************");
}

// -------------------------------------------------------------------------------
//	image를 파일로 저장
// -------------------------------------------------------------------------------

-(void)saveSmallCoverImage
{
    NSLog(@"saveSmallCoverImage");
    //NSString *homeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *homeDir = [Utils homeDir];
    NSString *imageFile = [NSString stringWithFormat:@"%@/%@_cover.png", homeDir,appRecord.bookId];
    NSLog(@"imageFile=%@",imageFile);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imageFile])
    {
        NSLog(@"[NSFileManager defaultManager");
        //UIImage *img = appRecord.appIcon;
        NSData *dataObj = UIImagePNGRepresentation(imageView.image);
        [dataObj writeToFile:imageFile atomically:YES];
    }
}


-(void)initializeFileDownloadDataArray
{
    self.arrFileDownloadData = [[NSMutableArray alloc] init];

    if (downloadType == SAMPLE)
        fileName = [NSString stringWithFormat:@"%@_preview.zip",appRecord.bookId];
    else if (downloadType == FULL)
        fileName = [NSString stringWithFormat:@"%@_full.zip",appRecord.bookId];
    
    NSLog(@"##downloadType : %d", downloadType);
    NSLog(@"##fileName : %@", fileName);
    
    [self.arrFileDownloadData addObject:[[FileDownloadInfo alloc] initWithFileTitle:appRecord.bookId andDownloadSource:[fileHome stringByAppendingString:fileName]]];
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
    [self activityIndicatorVisible:YES];
    //self.navigationController.navigationItem.backBarButtonItem.enabled = NO;
    self.navigationController.navigationItem.leftBarButtonItem.enabled = NO;
    
    NSLog(@"##downloadType : %d", downloadType);
    //NSLog(@"homeDir : %@", [Utils homeDir]);
    
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
    }
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
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Reload the respective table view row using the main thread.
            //  [self.tblFiles reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
            //                       withRowAnimation:UITableViewRowAnimationNone];
            
        }];
        
        fdi.downloadProgress = 0.0;
        
        
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
       /* UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello!"
                                                        message:@"Hello!" delegate:self
                                              cancelButtonTitle:@"Done"
                                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show)
                                withObject:nil
                             waitUntilDone:NO];*/
        [self unZipping];
        [self deleteFile];
        [self savePersistence];
        [self saveSmallCoverImage];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTableData"
                                                            object:self];
        
        NSLog(@"Download finished successfully.");
        
        [self activityIndicatorVisible:NO];
        
        //self.navigationController.navigationItem.backBarButtonItem.enabled = YES;
        
        self.navigationController.navigationItem.leftBarButtonItem.enabled = YES;
        
        [self.tabBarController setSelectedIndex:0];
        
       // [alert dismissWithClickedButtonIndex:0 animated:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self viewDidLoad];
            [self viewWillAppear:YES];
        });
        
        
  /*      // Cancel the task.
        [fdi.downloadTask cancel];
        
        // Change all related properties.
        fdi.isDownloading = NO;
        fdi.taskIdentifier = -1;
        fdi.downloadProgress = 0.0;*/

        

    }
}

- (void)unZipping {
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",[Utils homeDir],fileName];
    NSString *zipPath = filePath;
    
    [SSZipArchive unzipFileAtPath:zipPath toDestination:[Utils homeDir]];
}

- (void)deleteFile {
    
    NSLog(@"Delete Zip Files");
    
    NSString *zipFile = [NSString stringWithFormat:@"%@/%@",[Utils homeDir],fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:zipFile error:NULL];
    
    if (downloadType == FULL)
    {
        NSString *prevFile = [NSString stringWithFormat:@"%@/%@_preview",[Utils homeDir],appRecord.bookId];
        fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:prevFile error:NULL];
    }
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
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
            //            UITableViewCell *cell = [self.tblFiles cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            //            UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:CellProgressBarTagValue];
           
            if (downloadType == SAMPLE)
            {
                [sampleButton setHidden:YES];
                
                [getSampleProgressView setHidden:NO];
                [getSampleProgressLabel setHidden:NO];
              
                getSampleProgressView.progress = fdi.downloadProgress;
            
                double value = (double)totalBytesWritten / (double)totalBytesExpectedToWrite * 100;
                getSampleProgressLabel.text = [NSString stringWithFormat:@"%.1f %%", value];
            }
            else if (downloadType == FULL)
            {
                [purchaseButton setHidden:YES];
                [sampleButton setHidden:YES];
                
                [purchaseProgressView setHidden:NO];
                [purchaseProgressLabel setHidden:NO];
                
                purchaseProgressView.progress = fdi.downloadProgress;
                
                double value = (double)totalBytesWritten / (double)totalBytesExpectedToWrite * 100;
                purchaseProgressLabel.text = [NSString stringWithFormat:@"%.1f %%", value];
            }
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



#pragma mark Handle purchase request notification

// Update the UI according to the purchase request notification result
-(void)handlePurchasesNotification:(NSNotification *)notification
{
    NSLog(@"handlePurchasesNotification");
    
    
    StoreObserver *purchasesNotification = (StoreObserver *)notification.object;
    IAPPurchaseNotificationStatus status = (IAPPurchaseNotificationStatus)purchasesNotification.status;
    
    switch (status)
    {
            
        case IAPPurchaseSucceeded:
        {
            NSLog(@"IAPPurchaseSucceeded !!!");
            [self startDownload];
        }
            break;
        case IAPPurchaseFailed:
        {
            [self alertWithTitle:@"Purchase Status" message:purchasesNotification.message];
        }
            break;
            // Switch to the iOSPurchasesList view controller when receiving a successful restore notification
        case IAPRestoredSucceeded:
        {
            
            NSLog(@"IAPRestoredSucceeded");
            
            [self startDownload];
            
        }
            break;
        case IAPRestoredFailed:
        {
            NSLog(@"IAPRestoredFailed");
            
            [self alertWithTitle:@"Purchase Status" message:purchasesNotification.message];
        }
            break;
            // Notify the user that downloading is about to start when receiving a download started notification
        case IAPDownloadStarted:
        {
            NSLog(@"IAPDownloadStarted");
            //  self.hasDownloadContent = YES;
            //  [self.view addSubview:self.statusMessage];
        }
            break;
            // Display a status message showing the download progress
        case IAPDownloadInProgress:
        {
            NSLog(@"IAPDownloadInProgress");
            
            //  self.hasDownloadContent = YES;
            //  NSString *title = [[StoreManager sharedInstance] titleMatchingProductIdentifier:purchasesNotification.purchasedID];
            //  NSString *displayedTitle = (title.length > 0) ? title : purchasesNotification.purchasedID;
            // self.statusMessage.text = [NSString stringWithFormat:@" Downloading %@   %.2f%%",displayedTitle, purchasesNotification.downloadProgress];
        }
            break;
            // Downloading is done, remove the status message
        case IAPDownloadSucceeded:
        {
            NSLog(@"IAPDownloadSucceeded");
            
            
            //  self.hasDownloadContent = NO;
            //  self.statusMessage.text = @"Download complete: 100%";
            
            // Remove the message after 2 seconds
            //[self performSelector:@selector(hideStatusMessage) withObject:nil afterDelay:2];
        }
            break;
        default:
            break;
    }
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


@end
