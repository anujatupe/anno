//
//  AnnoDrawViewController.m
//  UserSource
//
//  Created by Imran Ahmed on 08/04/14.
//

#import "AnnoDrawViewController.h"
#import "AnnoCordovaPlugin.h"

@implementation AnnoDrawViewController

@synthesize isPractice, editMode, level, screenshotPath;
bool landscape_mode = NO;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.startPage = @"anno/pages/annodraw/main.html";
        level = 0;
        screenshotPath = @"";
        // Uncomment to override the CDVCommandDelegateImpl used
        // _commandDelegate = [[AnnoDrawCommandDelegate alloc] initWithViewController:self];
        // Uncomment to override the CDVCommandQueue used
        // _commandQueue = [[AnnoDrawCommandQueue alloc] initWithViewController:self];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.startPage = @"anno/pages/annodraw/main.html";
        level = 0;
        screenshotPath = @"";
        // Uncomment to override the CDVCommandDelegateImpl used
        // _commandDelegate = [[AnnoDrawCommandDelegate alloc] initWithViewController:self];
        // Uncomment to override the CDVCommandQueue used
        // _commandQueue = [[AnnoDrawCommandQueue alloc] initWithViewController:self];
    }
    return self;
}

- (void) makeLandscape {
    landscape_mode = YES;
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
    UIViewController *c = [[UIViewController alloc] init];
    [self presentViewController:c animated:NO completion:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

/**
 Saves URL of image which is to be shared via UserSource
 @param imageURI
        URL of image which is to be shared
 @param levelValue
        level value for viewcontroller
 @param isPracticeValue
        YES if it is for practice else NO
 @param editModeValue
        YES if it for editing anno item else NO
 */
- (void) handleFromShareImage:(NSString *)imageURI
                   levelValue:(int)levelValue
              isPracticeValue:(BOOL)isPracticeValue
                editModeValue:(BOOL)editModeValue
                landscapeMode:(BOOL)landscapeMode {

    if (editModeValue) {
        editMode = editModeValue;
        if (landscapeMode) {
            [self makeLandscape];
        }
        return;
    }

    screenshotPath = @"";
    level = levelValue + 1;
    isPractice = isPracticeValue;
    editMode = editModeValue;
    
    if (imageURI != nil) {
        // getting UIImage of specified image
        // for this, first we are getting NSData of image using URL of image
        // and then we are making UIImage from NSData
        UIImage *drawableImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURI]]];
        
        @try {
            NSString *orientation = [annoUtils isLandscapeOrPortrait:drawableImage];
            if ([annoUtils.IMAGE_ORIENTATION_LANDSCAPE isEqualToString:orientation]) {
                [self makeLandscape];
                /* // rotating image by 90 degrees if image is landscape
                drawableImage = [annoUtils rotateImage:drawableImage rotatedByDegrees:90.0];

                // saving rotated image in 'tmp' directory
                screenshotPath = [annoUtils saveImageToTemp:drawableImage];
            } else {
                screenshotPath = imageURI;*/
            }
            screenshotPath = imageURI;
        }
        @catch (NSException *exception) {
            if (annoUtils.debugEnabled) {
                NSLog(@"Exception while handling from share image: %@", exception);
            }
        }
    }
}

/**
 Get screenshot path associated with that viewcontroller
 @return path of screenshot
 */
- (NSString*) getScreenshotPath {
    return screenshotPath;
}

/**
 Get level associated with that viewcontroller
 @return value of level
 */
- (int) getLevel {
    return level;
}

/**
 Get editMode value associated with that viewcontroller
 @return value of editMode
 */
- (BOOL) isEditMode {
    return editMode;
}

/**
 Set level value associated with viewcontroller
 @param levelValue
        value for level
 */
- (void) setLevel:(int)levelValue {
    level = levelValue;
}

- (void) setEditMode:(BOOL)editModeValue {
    editMode = editModeValue;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark View lifecycle

- (void) viewWillAppear:(BOOL)animated {
    // View defaults to full size.  If you want to customize the view's size, or its subviews (e.g. webView),
    // you can do so here.
    [super viewWillAppear:animated];
}

- (void) viewDidLoad {
    [super viewDidLoad];

    NSArray *versionCompatibility = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    NSInteger iOSVersion = [[versionCompatibility objectAtIndex:0] intValue];

    if (iOSVersion == 7) {
        CGFloat viewWidth = self.view.frame.size.width;
        CGFloat viewHeight = self.view.frame.size.height;
        [self.webView setFrame:CGRectMake(0, 20, viewWidth, viewHeight - 20)];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (NSUInteger) supportedInterfaceOrientations {
    if (landscape_mode) {
        return UIInterfaceOrientationMaskLandscape;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

/* Comment out the block below to over-ride */

/*
- (UIWebView*) newCordovaViewWithFrame:(CGRect)bounds
{
    return[super newCordovaViewWithFrame:bounds];
}
*/

#pragma mark UIWebDelegate implementation

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    // Black base color for background matches the native apps
    theWebView.backgroundColor = [UIColor blackColor];

    return [super webViewDidFinishLoad:theWebView];
}

/* Comment out the block below to over-ride */

/*

- (void) webViewDidStartLoad:(UIWebView*)theWebView
{
    return [super webViewDidStartLoad:theWebView];
}

- (void) webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    return [super webView:theWebView didFailLoadWithError:error];
}

- (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    return [super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
}
*/

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

@implementation AnnoDrawCommandDelegate

/* To override the methods, uncomment the line in the init function(s)
   in AnnoDrawViewController.m
 */

#pragma mark CDVCommandDelegate implementation

- (id)getCommandInstance:(NSString*)className
{
    return [super getCommandInstance:className];
}

/*
   NOTE: this will only inspect execute calls coming explicitly from native plugins,
   not the commandQueue (from JavaScript). To see execute calls from JavaScript, see
   AnnoDrawCommandQueue below
*/
- (BOOL)execute:(CDVInvokedUrlCommand*)command
{
    return [super execute:command];
}

- (NSString*)pathForResource:(NSString*)resourcepath;
{
    return [super pathForResource:resourcepath];
}

@end

@implementation AnnoDrawCommandQueue

/* To override, uncomment the line in the init function(s)
   in AnnoDrawViewController.m
 */
- (BOOL)execute:(CDVInvokedUrlCommand*)command
{
    return [super execute:command];
}

@end
