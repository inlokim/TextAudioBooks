

#import "CustomSlideSegue.h"

@implementation CustomSlideSegue

- (void)perform
{
    UIViewController *sourceViewController = (UIViewController *) self.sourceViewController;
    UIViewController *destinationViewController = (UIViewController *) self.destinationViewController;
    
    [sourceViewController.view addSubview:destinationViewController.view];
    [destinationViewController.view setFrame:sourceViewController.view.window.frame];
    
    [destinationViewController.view setBounds:sourceViewController.view.bounds];
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    if ( !self.slideLeft ) {
        [UIView animateWithDuration:kAnimationDuration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [destinationViewController.view setCenter:CGPointMake(screenSize.height + screenSize.height/2, screenSize.height/2 - 138)];
                             [destinationViewController.view setCenter:CGPointMake(screenSize.width/2 + 127, screenSize.height/2 - 138)];
                         }
                         completion:^(BOOL finished){
                             [destinationViewController.view removeFromSuperview];
                             [sourceViewController presentViewController:destinationViewController animated:NO completion:nil];
                         }];
    } else {
        [UIView animateWithDuration:kAnimationDuration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [destinationViewController.view setCenter:CGPointMake(-1*screenSize.height/2, screenSize.height/2 - 138)];
                             [destinationViewController.view setCenter:CGPointMake(screenSize.width/2 + 127, screenSize.height/2 - 138)];
                         }
                         completion:^(BOOL finished){
                             [destinationViewController.view removeFromSuperview];
                             [sourceViewController presentViewController:destinationViewController animated:NO completion:nil];
                         }];
    }
}
