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
#import "MyModel.h"
#import "StoreManager.h"
#import "StoreObserver.h"
#import "LatestViewController.h"
#import "DetailViewController.h"
#import "StoreCell.h"
#import "AppRecord.h"
#import "IconDownloader.h"
#import "ParseOperation.h"

#define kCustomRowCount 1

static NSString *CellIdentifier = @"LazyTableCell";
static NSString *PlaceholderCellIdentifier = @"PlaceholderCell";


#pragma mark -

@interface LatestViewController () <UIScrollViewDelegate>
{
    Boolean productsDownloadCompleted;
    UIActivityIndicatorView *spinner;
}

// the set of IconDownloader objects for each app
@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;
// the queue to run our "ParseOperation"
@property (nonatomic, strong) NSOperationQueue *queue;
// the NSOperation driving the parsing of the RSS feed
@property (nonatomic, strong) ParseOperation *parser;

@property (nonatomic, strong) NSMutableArray *products;

@end


#pragma mark -

@implementation LatestViewController
static NSString *const latestList = @"http://inlokim.com/textAudioBooks/list.php";

// -------------------------------------------------------------------------------
//	viewDidLoad
// -------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    productsDownloadCompleted = NO;
    
    [self urlRequestHandler];
    
    //[self.tableView registerClass:[StoreCell class] forCellReuseIdentifier:CellIdentifier];
    
    
    [self.tableView registerClass:[StoreCell class] forCellReuseIdentifier:PlaceholderCellIdentifier];
    
    
    _imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    
    
    //purchase
    
    self.products = [[NSMutableArray alloc] initWithCapacity:0];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleProductRequestNotification:)
                                                 name:IAPProductRequestNotification
                                               object:[StoreManager sharedInstance]];
    
    //Activity
    
 /*   UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGRect frame = spinner.frame;
    frame.origin.x = self.tableView.frame.size.width / 2 - frame.size.width / 2;
    frame.origin.y = self.tableView.frame.size.height / 2 - frame.size.height / 2;
    spinner.frame = frame;
    [self.tableView addSubview:spinner];
    [spinner startAnimating];*/
    
    [self setActivity];
}

-(void) setActivity
{
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    UIView *view = self.parentViewController.view;
    
    //CGRect frame = spinner.frame;
    //frame.origin.x = view.frame.size.width / 2 - frame.size.width / 2;
    //frame.origin.y = self.view.frame.size.height / 2 - frame.size.height / 2;
    //spinner.frame = frame;
    spinner.center = view.center;
    [view addSubview: spinner];
    [view bringSubviewToFront:spinner];
    spinner.hidesWhenStopped = YES;
    spinner.hidden = NO;
    [spinner startAnimating];
}

- (void)urlRequestHandler
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:latestList]];

    // create an session data task to obtain and the XML feed
    NSURLSessionDataTask *sessionTask =
    [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // in case we want to know the response status code
            //NSInteger HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
 
        if (error != nil)
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
 
                if ([error code] == NSURLErrorAppTransportSecurityRequiresSecureConnection)
                {
                    // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    //
                    abort();
                }
                else
                {
                    [self handleError:error];
                }
            }];
        }
        else
        {
            // create the queue to run our ParseOperation
            self.queue = [[NSOperationQueue alloc] init];
 
            // create an ParseOperation (NSOperation subclass) to parse the RSS feed data so that the UI is not blocked
            _parser = [[ParseOperation alloc] initWithData:data];
 
            __weak LatestViewController *weakSelf = self;
 
            self.parser.errorHandler = ^(NSError *parseError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    [weakSelf handleError:parseError];
                });
            };
 
            // referencing parser from within its completionBlock would create a retain cycle
            __weak ParseOperation *weakParser = self.parser;
 
            self.parser.completionBlock = ^(void) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                if (weakParser.appRecordList != nil)
                {
                    // The completion block may execute on any thread.  Because operations
                    // involving the UI are about to be performed, make sure they execute on the main thread.
                    //
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // The root rootViewController is the only child of the navigation
                        // controller, which is the window's rootViewController.
                        //
                        
                        //LatestViewController *rootViewController =
                        //(LatestViewController*)[(UINavigationController*)weakSelf.window.rootViewController topViewController];
                        //__weak typeof(self) weakSelf = self;
                        weakSelf.entries = weakParser.appRecordList;
                        
                        [weakSelf fetchProductInformation];
                        
                        // tell our table view to reload its data, now that parsing has completed
                        //[weakSelf.tableView reloadData];
                        
                    });
                }
                // we are finished with the queue and our ParseOperation
                weakSelf.queue = nil;
            };
 
            [self.queue addOperation:self.parser]; // this will start the "ParseOperation"
        }
    }];
 
 [sessionTask resume];
 
// show in the status bar that network activity is starting
[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

}

// -------------------------------------------------------------------------------
//	handleError:error
//  Reports any error with an alert which was received from connection or loading failures.
// -------------------------------------------------------------------------------
- (void)handleError:(NSError *)error
{
    NSString *errorMessage = [error localizedDescription];
    
    // alert user that our current record was deleted, and then we leave this view controller
    //
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Show Top Paid Apps"
                                                                   message:errorMessage
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         // dissmissal of alert completed
                                                     }];
    
    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}






// -------------------------------------------------------------------------------
//	terminateAllDownloads
// -------------------------------------------------------------------------------
- (void)terminateAllDownloads
{
    // terminate all pending download connections
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    [self.imageDownloadsInProgress removeAllObjects];
}

// -------------------------------------------------------------------------------
//	dealloc
//  If this view controller is going away, we need to cancel all outstanding downloads.
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [self terminateAllDownloads];
    
    
    // Unregister for StoreManager's notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IAPProductRequestNotification
                                                  object:[StoreManager sharedInstance]];
    
    // Unregister for StoreObserver's notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IAPPurchaseNotification
                                                  object:[StoreObserver sharedInstance]];
}


// -------------------------------------------------------------------------------
//	didReceiveMemoryWarning
// -------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // terminate all pending download connections
    [self terminateAllDownloads];
}


#pragma mark - UITableViewDataSource

// -------------------------------------------------------------------------------
//	tableView:numberOfRowsInSection:
//  Customize the number of rows in the table view.
// -------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = self.entries.count;
    
    // if there's no data yet, return enough rows to fill the screen
    if (count == 0)
    {
        return kCustomRowCount;
    }
    return count;
}

// -------------------------------------------------------------------------------
//	tableView:cellForRowAtIndexPath:
// -------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StoreCell *cell = nil;
    
    NSUInteger nodeCount = self.entries.count;
    
    if (nodeCount == 0 && indexPath.row == 0)
    {
        // add a placeholder cell while waiting on table data
        cell = [tableView dequeueReusableCellWithIdentifier:PlaceholderCellIdentifier forIndexPath:indexPath];
        
        cell.titleLabel.text = @"";
        cell.authorLabel.text = @"";
        
        return cell;
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Leave cells empty if there's no data yet
        if (nodeCount > 0)
        {
            // Set up the cell representing the app
            AppRecord *appRecord = (self.entries)[indexPath.row];
            
            cell.titleLabel.text= appRecord.title;
            cell.authorLabel.text = appRecord.author;

            //NSLog(@"author : %@", appRecord.author);
            
            [cell.imageView.layer setBorderColor: [[UIColor lightGrayColor] CGColor]];
            [cell.imageView.layer setBorderWidth: 1.0];
            
            // Only load cached images; defer new downloads until scrolling ends
            if (!appRecord.appIcon)
            {
                if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
                {
                    [self startIconDownload:appRecord forIndexPath:indexPath];
                }
                // if a download is deferred or in progress, return a placeholder image
                cell.imageView.image = [UIImage imageNamed:@"Placeholder.png"];
            }
            else
            {
                cell.imageView.image = appRecord.appIcon;
            }
        }
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


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"productsDownloadCompleted : %d", productsDownloadCompleted);

        if ([[segue identifier] isEqualToString:@"showDetail"])
        {
            NSLog(@"segue");
            
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            AppRecord *appRecord = (self.entries)[indexPath.row];
            
            NSLog(@"appRecord.title : %@",appRecord.title);
            
            
            //Price
            
//            NSLog(@"self.products count : %d", [self.products count]);
            
            MyModel *model = (self.products)[0];
            NSArray *productRequestResponse = model.elements;
            
//            NSLog(@"productRequestResponse count :%d", [productRequestResponse count]);
            
            NSString *price;
            SKProduct *aProduct;
            
            for (int i = 0; productRequestResponse.count > i ; i ++)
            {
                NSString *productId = [@"kr.co.highwill.TextAudioBooks." stringByAppendingString:appRecord.bookId];
                
                aProduct = productRequestResponse[i];
                
                if ([aProduct.productIdentifier isEqualToString:productId])
                {
                    //NSString *titleName = aProduct.localizedTitle;
                    
                    price = [NSString stringWithFormat:@"%@ %@",[aProduct.priceLocale objectForKey:NSLocaleCurrencySymbol],aProduct.price];
                    
                    //NSLog(@"title : %@", titleName);
                    NSLog(@"price : %@", price);
                    NSLog(@"prod id : %@", aProduct.productIdentifier);
                    
                    appRecord.price = price;
                    
                    break;
                }
            }
            
            
            //NSDate *object = self.objects[indexPath.row];
            DetailViewController *controller =
            (DetailViewController *)[segue destinationViewController];
            
            [controller setAppRecord:appRecord];
            [controller setSkProduct:aProduct];
            
            controller.navigationItem.leftItemsSupplementBackButton = YES;
        }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    //appstore의 Skproduct이 완전히 다운로드 된 이후에 segue가 작동한다.

    return productsDownloadCompleted;
}



#pragma mark - Table cell image support

// -------------------------------------------------------------------------------
//	startIconDownload:forIndexPath:
// -------------------------------------------------------------------------------
- (void)startIconDownload:(AppRecord *)appRecord forIndexPath:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = (self.imageDownloadsInProgress)[indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.appRecord = appRecord;
        [iconDownloader setCompletionHandler:^{
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            // Display the newly loaded image
            cell.imageView.image = appRecord.appIcon;
            
            // Remove the IconDownloader from the in progress list.
            // This will result in it being deallocated.
            [self.imageDownloadsInProgress removeObjectForKey:indexPath];
            
        }];
        (self.imageDownloadsInProgress)[indexPath] = iconDownloader;
        [iconDownloader startDownload];
    }
}

// -------------------------------------------------------------------------------
//	loadImagesForOnscreenRows
//  This method is used in case the user scrolled into a set of cells that don't
//  have their app icons yet.
// -------------------------------------------------------------------------------
- (void)loadImagesForOnscreenRows
{
    if (self.entries.count > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            AppRecord *appRecord = (self.entries)[indexPath.row];
            
            if (!appRecord.appIcon)
            // Avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:appRecord forIndexPath:indexPath];
            }
        }
    }
}


#pragma mark - UIScrollViewDelegate

// -------------------------------------------------------------------------------
//	scrollViewDidEndDragging:willDecelerate:
//  Load images for all onscreen rows when scrolling is finished.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self loadImagesForOnscreenRows];
    }
}

// -------------------------------------------------------------------------------
//	scrollViewDidEndDecelerating:scrollView
//  When scrolling stops, proceed to load the app icons that are on screen.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}

#pragma mark Fetch product information
// Retrieve product information from the App Store
-(void)fetchProductInformation
{
    
    NSLog(@"fetchProductInformation");
    
    // Query the App Store for product information if the user is is allowed to make purchases.
    // Display an alert, otherwise.
    if([SKPaymentQueue canMakePayments])
    {
 //       NSLog(@"self.entries.count %d", self.entries.count);
        
        NSMutableArray *productIds = [NSMutableArray array];
        for (int i =0; i < self.entries.count; i++)
        {
            AppRecord *appRecord = (AppRecord *)[self.entries objectAtIndex:i];
            NSString *productId = [@"kr.co.highwill.TextAudioBooks." stringByAppendingString:appRecord.bookId];
            
            //NSLog(@"productId : %@", productId);
            
            [productIds addObject:productId];
        }
        
        //NSLog(@"products Ids count %d", productIds.count);
        
        [[StoreManager sharedInstance] fetchProductInformationForIds:productIds];
    }
    else
    {
        // Warn the user that they are not allowed to make purchases.
        [self alertWithTitle:@"Warning" message:@"Purchases are disabled on this device."];
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

#pragma mark Handle product request notification

// Update the UI according to the product request notification result
-(void)handleProductRequestNotification:(NSNotification *)notification
{
    
    NSLog(@"handleProductRequestNotification");
    
    
    StoreManager *productRequestNotification = (StoreManager*)notification.object;
    IAPProductRequestStatus result = (IAPProductRequestStatus)productRequestNotification.status;
    
    if (result == IAPProductRequestResponse)
    {
        // Switch to the iOSProductsList view controller and display its view
        //   [self cycleFromViewController:self.currentViewController toViewController:self.productsList];
        
        // Set the data source for the Products view
        // [self.productsList reloadUIWithData:productRequestNotification.productRequestResponse];
        
        self.products = productRequestNotification.productRequestResponse;
        
//        NSLog(@"productRequestNotification.productRequestResponse count = %d", [productRequestNotification.productRequestResponse count]);
        
         
       /*  MyModel *model = (self.products)[0];
         NSArray *productRequestResponse = model.elements;
         
        if ([self.products count] > 0)
        {
            SKProduct *aProduct = productRequestResponse[0];
            
            NSString *titleName = aProduct.localizedTitle;
            
            NSString *price = [NSString stringWithFormat:@"%@ %@",[aProduct.priceLocale objectForKey:NSLocaleCurrencySymbol],aProduct.price];
            
            NSLog(@"title : %@", titleName);
            NSLog(@"price : %@", price);
        }*/
        
        productsDownloadCompleted = YES;
        [spinner stopAnimating];
        [self.tableView reloadData];
    }
}








@end
