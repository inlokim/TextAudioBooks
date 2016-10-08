
#import <UIKit/UIKit.h>

@interface AppRecord : NSObject
{
	NSString *bookId;
    NSString *bookType; //sample=1, buy=2
    NSString *title;
    NSString *author;
	NSString *reader;
	NSString *content;
	NSString *size;
	NSString *time;
	NSString *price;
	NSString *imageURL;
	NSString *localImageURL;
	NSString *prevURL;
	NSString *fullURL;
    NSString *release1;
    NSString *downloadFlag;
    UIImage  *appIcon;
    UIImage  *appLargeIcon;
    NSString *appURLString;
    NSString *localHome;
    NSString *fullFlag; //1 = sample, 2 = full
	
}

@property (nonatomic, retain) NSString *bookId;
@property (nonatomic, retain) NSString *bookType;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *reader;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSString *size;
@property (nonatomic, retain) NSString *time;
@property (nonatomic, retain) NSString *price;
@property (nonatomic, retain) NSString *imageURL;
@property (nonatomic, retain) NSString *localImageURL;
@property (nonatomic, retain) NSString *prevURL;
@property (nonatomic, retain) NSString *fullURL;
@property (nonatomic, retain) UIImage  *appIcon;
@property (nonatomic, retain) UIImage  *appLargeIcon;
@property (nonatomic, retain) NSString *appURLString;
@property (nonatomic, retain) NSString *localHome;
@property (nonatomic, retain) NSString *release1;
@property (nonatomic, retain) NSString *downloadFlag;
@property (nonatomic, retain) NSString *fullFlag;

@end
