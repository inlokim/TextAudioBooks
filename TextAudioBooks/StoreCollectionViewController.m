//
//  BookViewController.m
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 3..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoreCollectionViewController.h"
#import "StoreCell.h"
#import "Utils.h"

@interface StoreCollectionViewController ()
{
    //XML
    NSXMLParser *xmlParser;
    NSMutableArray *arrNeighboursData;
    NSMutableDictionary *dictTempDataStorage;
    NSMutableString *foundValue;
    NSString *currentElement;
    NSString *currentAttribute;
}

@end

@implementation StoreCollectionViewController

static NSString *url = @"http://inlokim.com/textAudioBooks/list.php";
static NSString *cellID = @"MyCell";


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self XMLSetup];
}

#pragma mark - collectionView

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return arrNeighboursData.count;

}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    // we're going to use a custom UICollectionViewCell, which will hold an image and its label
    //
    StoreCell *cell = [cv dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    
    // make the cell's title the actual NSIndexPath value
    //cell.label.text = [NSString stringWithFormat:@"{%ld,%ld}", (long)indexPath.row, (long)indexPath.section];
    
    cell.label.text
    = [[arrNeighboursData objectAtIndex:indexPath.row] objectForKey:@"tab_title"];
    
    NSLog(@"title : %@",[[arrNeighboursData objectAtIndex:indexPath.row] objectForKey:@"tab_title"]);
    
    
    // load the image for this cell
    NSString *imageToLoad = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    cell.image.image = [UIImage imageNamed:imageToLoad];
    
    return cell;
}

// the user tapped a collection item, load and set the image on the detail view controller
//
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showDetail"])
    {
        NSIndexPath *selectedIndexPath = [self.collectionView indexPathsForSelectedItems][0];
        
        // load the image, to prevent it from being cached we use 'initWithContentsOfFile'
        NSString *imageNameToLoad = [NSString stringWithFormat:@"%ld_full", (long)selectedIndexPath.row];
        UIImage *image = [UIImage imageNamed:imageNameToLoad];
        //DetailViewController *detailViewController = segue.destinationViewController;
        //detailViewController.image = image;
    }
}


#pragma mark - ViewDisplay

- (void)XMLSetup
{
    xmlParser =
    [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    
   // [[NSXMLParser alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    
    foundValue = [[NSMutableString alloc] init];
    xmlParser.delegate = self;
    [xmlParser parse];
}

#pragma mark - NSXMLParser

-(void)parserDidStartDocument:(NSXMLParser *)parser{
    // Initialize the neighbours data array.
    arrNeighboursData = [[NSMutableArray alloc] init];
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{
    // When the parsing has been finished then simply reload the table view.
    //[self.tblNeighbours reloadData];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
    NSLog(@"elementName : %@", elementName);
    
    // If the current element name is equal to "geoname" then initialize the temporary dictionary.
    if ([elementName isEqualToString:@"entry"]) {
        dictTempDataStorage = [[NSMutableDictionary alloc] init];
        //NSLog(@"START : %@", [attributeDict objectForKey:@"START"]);
        //currentAttribute = [attributeDict objectForKey:@"START"];
    }
    
    // Keep the current element.
    currentElement = elementName;
    //currentAttribute = attributeValue;
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    if ([elementName isEqualToString:@"entry"]) {
        [arrNeighboursData addObject:[[NSDictionary alloc] initWithDictionary:dictTempDataStorage]];
        
    }
    else if ([elementName isEqualToString:@"tab_id"]){
        
        [dictTempDataStorage setObject:[NSString stringWithString:foundValue] forKey:@"tab_id"];
    }
    else if ([elementName isEqualToString:@"tab_title"]){
        
        [dictTempDataStorage setObject:[NSString stringWithString:foundValue] forKey:@"tab_title"];
        
        //NSLog(@"START : %@", [attributeDict objectForKey:@"START"]);
    }
    else if ([elementName isEqualToString:@"tab_image"]){
        
        [dictTempDataStorage setObject:[NSString stringWithString:foundValue] forKey:@"tab_image"];
    }

    // Clear the mutable string.
    [foundValue setString:@""];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    // Store the found characters if only we're interested in the current element.
    if ([currentElement isEqualToString:@"entry"]
        ||[currentElement isEqualToString:@"tab_id"]
        ||[currentElement isEqualToString:@"tab_title"])
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

- (void)viewWillAppear:(BOOL)animated {
    //    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
