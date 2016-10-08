/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 NSOperation subclass for parsing the RSS feed.
 */

#import "ParseOperation.h"
#import "AppRecord.h"


// string contants found in the RSS feed
static NSString *kIDStr			= @"tab_id";
static NSString *kTitleStr		= @"tab_title";
static NSString *kImageStr		= @"tab_image";
static NSString *kAuthorStr		= @"tab_author";
static NSString *kReaderStr		= @"tab_reader";
static NSString *kPriceStr		= @"tab_price";
static NSString *kSizeStr		= @"tab_size";
static NSString *kTimeStr		= @"tab_time";
static NSString *kPrevStr		= @"tab_preview";
static NSString *kFullStr		= @"tab_full";
static NSString *kContentStr	= @"tab_content";
static NSString *kReleaseStr	= @"tab_release";

static NSString *kEntryStr		= @"entry";


@interface ParseOperation () <NSXMLParserDelegate>

// Redeclare appRecordList so we can modify it within this class
@property (nonatomic, strong) NSArray *appRecordList;

@property (nonatomic, strong) NSData *dataToParse;
@property (nonatomic, strong) NSMutableArray *workingArray;
@property (nonatomic, strong) AppRecord *workingEntry;  // the current app record or XML entry being parsed
@property (nonatomic, strong) NSMutableString *workingPropertyString;
@property (nonatomic, strong) NSArray *elementsToParse;
@property (nonatomic, readwrite) BOOL storingCharacterData;

@end


#pragma mark -

@implementation ParseOperation

// -------------------------------------------------------------------------------
//	initWithData:
// -------------------------------------------------------------------------------
- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self != nil)
    {
        _dataToParse = data;
        _elementsToParse = @[kIDStr, kTitleStr, kImageStr, kAuthorStr, kReaderStr,
                             kSizeStr, kTimeStr, kContentStr, kFullStr, kPrevStr, kPriceStr, kReleaseStr];
    }
    return self;
}

// -------------------------------------------------------------------------------
//	main
//  Entry point for the operation.
//  Given data to parse, use NSXMLParser and process all the top paid apps.
// -------------------------------------------------------------------------------
- (void)main
{
    // The default implemetation of the -start method sets up an autorelease pool
    // just before invoking -main however it does NOT setup an excption handler
    // before invoking -main.  If an exception is thrown here, the app will be
    // terminated.
    
    _workingArray = [NSMutableArray array];
    _workingPropertyString = [NSMutableString string];
    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not
    // desirable because it gives less control over the network, particularly in responding to
    // connection errors.
    //
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.dataToParse];
    [parser setDelegate:self];
    [parser parse];
    
    if (![self isCancelled])
    {
        // Set appRecordList to the result of our parsing
        self.appRecordList = [NSArray arrayWithArray:self.workingArray];
    }
    
    self.workingArray = nil;
    self.workingPropertyString = nil;
    self.dataToParse = nil;
}


#pragma mark - RSS processing

// -------------------------------------------------------------------------------
//	parser:didStartElement:namespaceURI:qualifiedName:attributes:
// -------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    // entry: { id (link), im:name (app name), im:image (variable height) }
    //
    if ([elementName isEqualToString:kEntryStr])
    {
        self.workingEntry = [[AppRecord alloc] init];
    }
    self.storingCharacterData = [self.elementsToParse containsObject:elementName];
}

// -------------------------------------------------------------------------------
//	parser:didEndElement:namespaceURI:qualifiedName:
// -------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if (self.workingEntry != nil)
    {
        if (self.storingCharacterData)
        {
            NSString *trimmedString =
            [self.workingPropertyString stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [self.workingPropertyString setString:@""];  // clear the string for next time
            
            if ([elementName isEqualToString:kIDStr])
            {
                //self.workingEntry.appURLString = trimmedString;
                self.workingEntry.bookId = trimmedString;
                //NSLog(@"trimmedString =%@",trimmedString);
            }
            else if ([elementName isEqualToString:kTitleStr])
            {
                self.workingEntry.title = trimmedString;
            }
            else if ([elementName isEqualToString:kImageStr])
            {
                self.workingEntry.imageURL = trimmedString;
            }
            else if ([elementName isEqualToString:kAuthorStr])
            {
                self.workingEntry.author = trimmedString;
            }
            else if ([elementName isEqualToString:kReaderStr])
            {
                self.workingEntry.reader = trimmedString;
            }
            else if ([elementName isEqualToString:kSizeStr])
            {
                self.workingEntry.size = trimmedString;
            }
            else if ([elementName isEqualToString:kTimeStr])
            {
                self.workingEntry.time = trimmedString;
            }
            else if ([elementName isEqualToString:kPrevStr])
            {
                self.workingEntry.prevURL = trimmedString;
            }
            else if ([elementName isEqualToString:kFullStr])
            {
                self.workingEntry.fullURL = trimmedString;
            }
            else if ([elementName isEqualToString:kContentStr])
            {
                self.workingEntry.content = trimmedString;
            }
            else if ([elementName isEqualToString:kPriceStr])
            {
                self.workingEntry.price = trimmedString;
            }
            else if ([elementName isEqualToString:kReleaseStr])
            {
                self.workingEntry.release1 = trimmedString;
            }
        }
        else if ([elementName isEqualToString:kEntryStr])
        {
            [self.workingArray addObject:self.workingEntry];
            self.workingEntry = nil;
        }
    }
}

// -------------------------------------------------------------------------------
//	parser:foundCharacters:
// -------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (self.storingCharacterData)
    {
        [self.workingPropertyString appendString:string];
    }
}

// -------------------------------------------------------------------------------
//	parser:parseErrorOccurred:
// -------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    if (self.errorHandler)
    {
        self.errorHandler(parseError);
    }
}

@end
