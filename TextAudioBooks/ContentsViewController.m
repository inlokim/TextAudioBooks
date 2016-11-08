//
//  ContentsViewController.m
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 6..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentsViewController.h"
#import "BookViewController.h"
#import "Utils.h"


@interface ContentsViewController ()
{
    BOOL xmlExists;
    NSUInteger indexRow;
    
    NSXMLParser *xmlParser;
    NSMutableArray *arrayData;
    NSMutableDictionary *dictTempDataStorage;
    NSMutableString *foundValue;
    
    NSString *currentElement;
    NSString *currentAttribute;
    NSUInteger currentRow;
    NSArray * listArray;

}

@end

@implementation ContentsViewController

@synthesize appRecord;

static NSString *cellIdentifier = @"MyCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];

    [self XMLSetup];
    
    NSLog(@"ContentsViewController");
    
   /* NSString *fileName = [Utils fileDir:appRecord.bookType bookId:appRecord.bookId];
    NSString *path = [NSString stringWithFormat:@"%@/%@/images/iPhoneBack.png", [Utils homeDir], fileName];
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
    [tempImageView setFrame:self.tableView.frame];
    
    self.tableView.backgroundView = tempImageView;*/
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
        listArray = array;
        //NSLog(@"array count = %d",[array count]);
        
        //맨 마지막 선택
        NSString *string = [array lastObject];
        NSArray *chunks = [string componentsSeparatedByString: @":"];
        NSString *listIndexRow = [chunks objectAtIndex:0];
        
        currentRow = [listIndexRow intValue];
    }
}

#pragma mark - ViewDisplay

- (void)XMLSetup
{
    xmlExists = false;
    
    NSString *fileName = [Utils fileDir:appRecord.bookType bookId:appRecord.bookId];
    NSString *path = [NSString stringWithFormat:@"%@/%@/audios/list.xml", [Utils homeDir], fileName];
    
    NSLog(@"path : %@", path);
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        xmlParser = [[NSXMLParser alloc] initWithData:[NSData dataWithContentsOfFile:path]];
        foundValue = [[NSMutableString alloc] init];
        xmlParser.delegate = self;
        [xmlParser parse];
        
    }
}


#pragma mark - NSXMLParser

-(void)parserDidStartDocument:(NSXMLParser *)parser{
    // Initialize the neighbours data array.
    arrayData = [[NSMutableArray alloc] init];
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{
    // When the parsing has been finished then simply reload the table view.
    //[self.tblNeighbours reloadData];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
    ///NSString *attributeValue;
    
    // If the current element name is equal to "geoname" then initialize the temporary dictionary.
    if ([elementName isEqualToString:@"item"]) {
        dictTempDataStorage = [[NSMutableDictionary alloc] init];
        //NSLog(@"START : %@", [attributeDict objectForKey:@"START"]);
        currentAttribute = [attributeDict objectForKey:@"key"];
    }
    
    // Keep the current element.
    currentElement = elementName;
    //currentAttribute = attributeValue;
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    if ([elementName isEqualToString:@"item"]) {
        [arrayData addObject:[[NSDictionary alloc] initWithDictionary:dictTempDataStorage]];
        
    }
    else if ([elementName isEqualToString:@"title"]){
        
        //NSLog(@"DESC : %@", [NSString stringWithString:foundValue]);
        [dictTempDataStorage setObject:[NSString stringWithString:foundValue] forKey:@"title"];
        
        //NSLog(@"currentAttribute : %@", currentAttribute);
        [dictTempDataStorage setObject:currentAttribute forKey:@"key"];
    }
    // Clear the mutable string.
    [foundValue setString:@""];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    // Store the found characters if only we're interested in the current element.
    if ([currentElement isEqualToString:@"title"])
    {
        if (![string isEqualToString:@"\n"]) {
            
            string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [foundValue appendString:string];
        }
    }
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"%@", [parseError localizedDescription]);
}



#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return arrayData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text
    = [[arrayData objectAtIndex:indexPath.row] objectForKey:@"title"];
    
   /* cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    tableView.backgroundColor = [UIColor clearColor];*/
    
 /*   NSLog(@"indexPath.row : %d, currentRow : %d", indexPath.row, currentRow);
    UIView *backgroundView = [[UIView alloc]initWithFrame:self.tableView.bounds];
    backgroundView.layer.backgroundColor = [[UIColor colorWithRed:0.529 green:0.808 blue:0.822 alpha:0.5]CGColor];
    if (indexPath.row == currentRow)
    {
        //UIImageView * imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,20,20)];
        //UIImage * image = [UIImage imageNamed:@"select.png"];
        //imgView.image = image;

        [cell addSubview:backgroundView];
        
        //cell.selectedBackgroundView = backgroundView;
        //[cell addSubview:imgView];
    }
*/   
    //cell.selectedBackgroundView = backgroundView;
    
    return cell;
}
/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}
*/

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
 //       NSString *fileId =
 //       [[arrayData objectAtIndex:indexPath.row] objectForKey:@"key"];
        
        //NSString *title =
        //[[arrayData objectAtIndex:indexPath.row] objectForKey:@"title"];
        
        //NSLog(@"##title : %@, ##fileID : %@", title, fileId);
       
        //NSDate *object = self.objects[indexPath.row];
        BookViewController *controller =
        (BookViewController *)[segue destinationViewController];
        
        [controller setAppRecord:appRecord];
        [controller setContentsIndex:indexPath];
        [controller setContentsArray:arrayData];
        
        /*controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
         controller.navigationItem.leftItemsSupplementBackButton = YES;*/
        
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    currentRow = 0;
    
    [self getPersistData];
    NSLog(@"ContentsViewController viewWillAppear ");
   // NSLog(@"currentRow :%d", currentRow);
    
    /******
     ROW
     ******/
    NSIndexPath * theIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:0];
    
    //첫 로우
    if (currentRow == 0)
    {
        [self.tableView selectRowAtIndexPath:theIndexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
    }
    //마지막 로우
    else if (listArray.count == currentRow)
    {
        NSLog(@"lastRow");
        [self.tableView selectRowAtIndexPath:theIndexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];
    }
    else
    {
        [self.tableView selectRowAtIndexPath:theIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    
    [self.tableView reloadData];
}


@end
