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
#import "StoreCell.h"
#import "BookCoverViewController.h"
#import "CustomSegue.h"
#import "CustomUnwindSegue.h"

#define MYBOOKS_PLIST  @"myBooks.plist"


#pragma mark -

@interface MyBooksListViewController ()
{
    NSMutableArray *entries;
    AppRecord *aBook;
}

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

       // [self.tableView registerClass:[StoreCell class] forCellReuseIdentifier:CellIdentifier];
    
    [self getPesistence];
    
    NSLog(@"entries count : %d", (int)entries.count);
    
    [self.tableView reloadData];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeTableData:)
                                                 name:@"changeTableData" object:nil];
}

- (void)didChangeTableData:(NSNotification *)notification
{
    NSLog(@"didChangeTableData");
    [self viewDidLoad];
    [self viewWillAppear:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"changeTableData"
                                                  object:nil];
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
            NSString *fileName =
            [NSString stringWithFormat:@"%@/%@_cover.png", [Utils homeDir], appRecord.bookId];
            
            appRecord.localImageURL = fileName;
            NSLog(@"aBook.localImageURL=%@",appRecord.localImageURL);
        }
        
        entries = myBooks;
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
    StoreCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Set up the cell representing the app
    AppRecord * appRecord = [entries objectAtIndex:indexPath.row];
    
    NSLog(@"appRecord title : %@", appRecord.title);
    NSLog(@"indexPath row : %d", (int)indexPath.row);
    
    [cell.imageView.layer setBorderColor: [[UIColor lightGrayColor] CGColor]];
    [cell.imageView.layer setBorderWidth: 1.0];
    
    cell.titleLabel.text= appRecord.title;
    cell.authorLabel.text = appRecord.author;
    cell.imageView.image = [UIImage imageWithContentsOfFile:appRecord.localImageURL];
    
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
        
        NSString *fileName = [Utils fileDir:appRecord.bookType bookId:appRecord.bookId];
        
        NSString *file = [NSString stringWithFormat:@"%@/%@", [Utils homeDir], fileName];
        
        NSString *imageFile = [NSString stringWithFormat:@"%@/%@_cover.png", [Utils homeDir], fileName];
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


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  /*  if ([[segue identifier] isEqualToString:@"showDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        AppRecord *appRecord = (entries)[indexPath.row];
        
        NSLog(@"appRecord.title : %@",appRecord.title);
        
        //NSDate *object = self.objects[indexPath.row];
        BookCoverViewController *controller =
        (BookCoverViewController *)[segue destinationViewController];
        
        [controller setAppRecord:appRecord];
    }*/
    
    if([segue isKindOfClass:[CustomSegue class]])
    {
        ((CustomSegue *)segue).originatingPoint = self.view.center;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        AppRecord *appRecord = (entries)[indexPath.row];
        
        NSLog(@"appRecord.title : %@",appRecord.title);
        
        //NSDate *object = self.objects[indexPath.row];
        BookCoverViewController *controller =
        (BookCoverViewController *)[segue destinationViewController];
        
        [controller setAppRecord:appRecord];
    }
}


// This is the IBAction method referenced in the Storyboard Exit for the Unwind segue.
// It needs to be here to create a link for the unwind segue.
// But we'll do nothing with it.
- (IBAction)unwindFromViewController:(UIStoryboardSegue *)sender {
}

// We need to over-ride this method from UIViewController to provide a custom segue for unwinding
- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    // Instantiate a new CustomUnwindSegue
    CustomUnwindSegue *segue = [[CustomUnwindSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    // Set the target point for the animation to the center of the button in this VC
    segue.targetPoint = self.view.center;
    
    return segue;
}

@end
