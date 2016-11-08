//
//  BackgroundSessionManager.m
//  TextAudioBooks
//
//  Created by 김인로 on 2016. 11. 7..
//  Copyright © 2016년 highwill. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BackgroundSessionManager.h"

static NSString * const kBackgroundSessionIdentifier = @"com.domain.backgroundsession";

@implementation BackgroundSessionManager

+ (instancetype)sharedManager
{
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionIdentifier];
    self = [super initWithSessionConfiguration:configuration];
    if (self) {
        [self configureDownloadFinished];            // when download done, save file
        [self configureBackgroundSessionFinished];   // when entire background session done, call completion handler
        [self configureAuthentication];              // my server uses authentication, so let's handle that; if you don't use authentication challenges, you can remove this
    }
    return self;
}

- (void)configureDownloadFinished
{
    // just save the downloaded file to documents folder using filename from URL
    
    [self setDownloadTaskDidFinishDownloadingBlock:^NSURL *(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location) {
        if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)downloadTask.response statusCode];
            if (statusCode != 200) {
                // handle error here, e.g.
                
                NSLog(@"%@ failed (statusCode = %ld)", [downloadTask.originalRequest.URL lastPathComponent], statusCode);
                return nil;
            }
        }
        
        NSString *filename      = [downloadTask.originalRequest.URL lastPathComponent];
        NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *path          = [documentsPath stringByAppendingPathComponent:filename];
        return [NSURL fileURLWithPath:path];
    }];
    
    [self setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        if (error) {
            // handle error here, e.g.,
            
            NSLog(@"%@: %@", [task.originalRequest.URL lastPathComponent], error);
        }
    }];
}

- (void)configureBackgroundSessionFinished
{
    typeof(self) __weak weakSelf = self;
    
    [self setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        if (weakSelf.savedCompletionHandler) {
            weakSelf.savedCompletionHandler();
            weakSelf.savedCompletionHandler = nil;
        }
    }];
}

- (void)configureAuthentication
{
    NSURLCredential *myCredential = [NSURLCredential credentialWithUser:@"userid" password:@"password" persistence:NSURLCredentialPersistenceForSession];
    
    [self setTaskDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing *credential) {
        if (challenge.previousFailureCount == 0) {
            *credential = myCredential;
            return NSURLSessionAuthChallengeUseCredential;
        } else {
            return NSURLSessionAuthChallengePerformDefaultHandling;
        }
    }];
}

@end
