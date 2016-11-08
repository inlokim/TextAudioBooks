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
#import "MyModel.h"

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
    
    NSLog(@"viewDidLoad");
    
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
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 1;
    
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
    
    
    //purchase
    
    // Attach an observer to the payment queue
    //[[SKPaymentQueue defaultQueue] addTransactionObserver:[StoreObserver sharedInstance]];
    
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
    appRecord.bookType = @"2";
    downloadType = FULL;
    
    //[self downloadBook];
    [[StoreObserver sharedInstance] buy:skProduct];
}


#pragma mark - Get Sample

- (IBAction)getSampleButtonPressed:(id)sender
{
    appRecord.bookType = @"1";
    downloadType = SAMPLE;
    
    [self downloadBook];
}

-(void)sucessPurchaseMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:@"Thank you for your purchase."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // the user clicked OK
    if (buttonIndex == 0) {
        [self downloadBook];
    }
}

-(void)downloadBook
{
//    [self savePersistence];
//    [self saveSmallCoverImage];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTableData"
                                                        object:appRecord];
    [self.tabBarController setSelectedIndex:0];

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
        
        //NSLog(@"bookId : %@   bookType : %@ ",mybookId, mybookType);
        
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
        //NSLog(@"[NSFileManager defaultManager");
        //UIImage *img = appRecord.appIcon;
        NSData *dataObj = UIImagePNGRepresentation(imageView.image);
        [dataObj writeToFile:imageFile atomically:YES];
    }
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
            NSLog(@"##IAPPurchaseSucceeded !!!");
            [self sucessPurchaseMessage];
        }
            break;
        case IAPPurchaseFailed:
        {
           // [self alertWithTitle:@"Purchase Status" message:purchasesNotification.message];
        }
            break;
            // Switch to the iOSPurchasesList view controller when receiving a successful restore notification
        case IAPRestoredSucceeded:
        {
            NSLog(@"##IAPRestoredSucceeded");
            [self sucessPurchaseMessage];
            
        }
            break;
        case IAPRestoredFailed:
        {
            NSLog(@"IAPRestoredFailed");
            
           // [self alertWithTitle:@"Purchase Status" message:purchasesNotification.message];
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

- (void)dealloc
{
   
    // Unregister for StoreObserver's notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IAPPurchaseNotification
                                                  object:[StoreObserver sharedInstance]];
}



@end
