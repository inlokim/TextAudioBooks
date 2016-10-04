//
//  BookViewController.m
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 10. 3..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BookViewController.h"
#import "Utils.h"


@interface BookViewController ()
{
    BOOL xmlExists;
}

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableArray *arrNeighboursData;
@property (nonatomic, strong) NSMutableDictionary *dictTempDataStorage;
@property (nonatomic, strong) NSMutableString *foundValue;
@property (nonatomic, strong) NSString *currentElement;

@end

@implementation BookViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self XMLSetup];

}

#pragma mark - ViewDisplay

- (void)XMLSetup
{
    xmlExists = false;
    
    NSString *xmlFile = [NSString stringWithFormat:@"%@/out/%@",[Utils homeDir], @"lesson1.xml" ];
    NSString *path;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:xmlFile])
    {
        path = xmlFile;
        xmlExists = true;
    }
    else {
        //use Sample file
        path = [[NSBundle mainBundle] pathForResource:@"aroundtheworldineightydays_01_verne_64kb" ofType:@"xml"];
    }
    
    self.xmlParser = [[NSXMLParser alloc] initWithData:[NSData dataWithContentsOfFile:path]];
    self.foundValue = [[NSMutableString alloc] init];
    self.xmlParser.delegate = self;
    [self.xmlParser parse];
}

#pragma mark - NSXMLParser

-(void)parserDidStartDocument:(NSXMLParser *)parser{
    // Initialize the neighbours data array.
    self.arrNeighboursData = [[NSMutableArray alloc] init];
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{
    // When the parsing has been finished then simply reload the table view.
    //[self.tblNeighbours reloadData];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
    // If the current element name is equal to "geoname" then initialize the temporary dictionary.
    if ([elementName isEqualToString:@"SYNC"]) {
        self.dictTempDataStorage = [[NSMutableDictionary alloc] init];
        //NSLog(@"START : %@", [attributeDict objectForKey:@"START"]);
    }
    
    // Keep the current element.
    self.currentElement = elementName;
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    if ([elementName isEqualToString:@"SYNC"]) {
        // If the closing element equals to "geoname" then the all the data of a neighbour country has been parsed and the dictionary should be added to the neighbours data array.
        [self.arrNeighboursData addObject:[[NSDictionary alloc] initWithDictionary:self.dictTempDataStorage]];
    }
    else if ([elementName isEqualToString:@"DESC"]){
        
        NSLog(@"DESC : %@", [NSString stringWithString:self.foundValue]);
        
        // If the country name element was found then store it.
        [self.dictTempDataStorage setObject:[NSString stringWithString:self.foundValue] forKey:@"Description"];
    }
    // Clear the mutable string.
    [self.foundValue setString:@""];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    // Store the found characters if only we're interested in the current element.
    if ([self.currentElement isEqualToString:@"DESC"])
    {
        if (![string isEqualToString:@"\n"]) {
            
            string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [self.foundValue appendString:string];
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


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrNeighboursData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //static NSString *CellIdentifier = @"Cell";
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.textLabel setHighlightedTextColor:[UIColor blueColor]];
    [cell setBackgroundColor:[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1]];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text =
    [[self.arrNeighboursData objectAtIndex:indexPath.row] objectForKey:@"Description"];
    
    

    return cell;
}

/*
- (CGFloat)tableView:(UITableView *)myTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *cellText =
    [[self.arrNeighboursData objectAtIndex:indexPath.row] objectForKey:@"Description"];
    UIFont *cellFont;
    
    CGFloat width = 300.0f;
    
    CGSize constraintSize = CGSizeMake(width, MAXFLOAT);
    CGSize labelSize =
    [cellText sizeWithFont:cellFont constrainedToSize:constraintSize
                                lineBreakMode:UILineBreakModeWordWrap];
    [cellText si]
  
    return labelSize.height+20;
}
*/


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}




@end
