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


#define SAMPLE NO
#define FULL YES


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
    
}

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableArray *arrFileDownloadData;
@property (nonatomic, strong) NSURL *docDirectoryURL;





@end

@implementation DetailViewController

@synthesize appRecord;



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = appRecord.title;
    
    downloadType = SAMPLE;
    
    [getSampleProgressView setHidden:YES];
    [getSampleProgressLabel setHidden:YES];
    
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
    
    //Download
    
    [self initializeFileDownloadDataArray];
    
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    self.docDirectoryURL = [URLs objectAtIndex:0];
    
    NSLog(@"docDirectoryURL : %@",[self.docDirectoryURL path] );
    
    NSString *sessionId = [NSString stringWithFormat:@"%@.%@", @"kr.co.highwill.TextAudioBooks", appRecord.bookId];
    
    NSURLSessionConfiguration *sessionConfiguration
    = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionId];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
    
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
}

-(void)viewDidLayoutSubviews
{
    [contentLabel sizeToFit];
    
    NSLog(@"%@", NSStringFromCGRect(contentLabel.frame));
    
    [scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetHeight(contentLabel.frame) + 340)];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - purchase

- (IBAction)purchaseButtonPressed:(id)sender {
    
    downloadType = FULL;

}


#pragma mark - Get Sample

- (IBAction)getSampleButtonPressed:(id)sender {
    
    downloadType = SAMPLE;
    [self startDownload];
}

#pragma mark - File Download

-(void)initializeFileDownloadDataArray
{
    self.arrFileDownloadData = [[NSMutableArray alloc] init];

    if (downloadType == SAMPLE) fileName = [NSString stringWithFormat:@"%@_preview.zip",appRecord.bookId];
    else if (downloadType == FULL) fileName = [NSString stringWithFormat:@"%@_full.zip",appRecord.bookId];
    
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
    
    NSLog(@"homeDir : %@", [Utils homeDir]);
    
    // Access all FileDownloadInfo objects using a loop.
    for (int i=0; i<[self.arrFileDownloadData count]; i++) {
        FileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:i];
        
        // Check if a file is already being downloaded or not.
        if (!fdi.isDownloading) {
            // Check if should create a new download task using a URL, or using resume data.
            if (fdi.taskIdentifier == -1) {
                fdi.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
            }
            else{
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
    
    if (success) {
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
        
    }
    else{
        NSLog(@"Unable to copy temp file. Error: %@", [error localizedDescription]);
    }
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error != nil) {
        NSLog(@"Download completed with error: %@", [error localizedDescription]);
    }
    else{
        [self unZipping];
        [self deleteFile];
        NSLog(@"Download finished successfully.");
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self viewDidLoad];
            [self viewWillAppear:YES];
        });
        
        //[self.view setNeedsDisplay];
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
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
        NSLog(@"Unknown transfer size");
    }
    else{
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
                
                getSampleProgressView.progress = fdi.downloadProgress;
                
                double value = (double)totalBytesWritten / (double)totalBytesExpectedToWrite * 100;
                getSampleProgressLabel.text = [NSString stringWithFormat:@"%.1f %%", value];
            }
        }];
    }
}


-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    // Check if all download tasks have been finished.
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        if ([downloadTasks count] == 0) {
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
