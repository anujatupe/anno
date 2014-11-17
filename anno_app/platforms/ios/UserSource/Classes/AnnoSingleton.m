//
//  AnnoSingleton.m
//  UserSource
//
//  Created by Rishi Diwan on 22/10/14.
//
//

#import "AnnoSingleton.h"

#define UNREAD_URL @"/anno/1.0/user/unread"

@implementation AnnoSingleton {
    NSDictionary *serverConfig;
    NSString *cloudHost;
}

@synthesize utils, infoViewControllerClass;

    static AnnoSingleton *sharedInstance = nil;

    // Get the shared instance and create it if necessary.
    + (AnnoSingleton *)sharedInstance {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[AnnoSingleton alloc] init];
            // Do any other initialisation stuff here
        });
        return sharedInstance;
    }

    // We can still have a regular init method, that will get called the first time the Singleton is used.
    - (id)init
    {
        self = [super init];
        
        if (self) {
            // Work your initialising magic here as you normally would
            utils = [[AnnoUtils alloc] init];
            self.isPlugin = (![utils isAnno:[[NSBundle mainBundle] bundleIdentifier]]);
            infoViewControllerClass = nil;
            self.newAnnoCreated = FALSE;
            cloudHost = @"http://localhost:8081";
            
            [self performSelectorInBackground:@selector(readServerConfiguration) withObject:nil];
            
        }
        
        return self;
    }

    // Equally, we don't want to generate multiple copies of the singleton.
    - (id)copyWithZone:(NSZone *)zone {
        return self;
    }

    - (void) setupWithEmail:(NSString*)emailValue
                displayName:(NSString*)displayNameValue
               userImageURL:(NSString*)userImageURLValue
                    teamKey:(NSString*)teamKeyValue
                 teamSecret:(NSString*)teamSecretValue {
        self.communityViewController = [[CommunityViewController alloc] init];
        self.email = emailValue;
        self.displayName = displayNameValue;
        self.userImageURL = userImageURLValue;
        self.teamKey = teamKeyValue;
        self.teamSecret = teamSecretValue;
        
        
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        if (window.rootViewController == nil) {
            NSLog(@"WARNING! CommunityViewController being set as rootViewController");
            window.rootViewController = self.communityViewController;
        }
        self.viewControllerList = [[NSMutableArray alloc] initWithObjects:window.rootViewController, nil];
        self.annoDrawViewControllerList = [[NSMutableArray alloc] init];
    }

    - (UIViewController*) getTopMostViewController {
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        UIViewController* cvc = window.rootViewController;
        UIViewController* last_cvc = nil;
        
        // 10 iteration safe loop
        for (int max = 10; max && last_cvc != cvc; max --) {
            last_cvc = cvc;
            // Is there a navigation controller
            if (cvc.navigationController) {
                cvc = cvc.navigationController.topViewController;
            }
            
            // Is another controller presented
            if (cvc.presentedViewController) {
                cvc = cvc.presentedViewController;
            }
        }
        
        return cvc;
    }

    - (void) showCommunityPage {
//        CDVViewController *currentViewController = [self.viewControllerList lastObject];
        UIViewController* currentViewController = [self getTopMostViewController];
        
        if (self.email == nil || [self.email isEqualToString:@""]) {
            NSLog(@"Email address is not specified");
            return;
        }

        if (self.teamKey == nil || self.teamSecret == nil) {
            NSLog(@"teamKey and teamSecret are not specified.");
            return;
        }
        
        if (currentViewController != self.communityViewController) {
            if (self.communityViewController.presentingViewController == nil) {
                [currentViewController presentViewController:self.communityViewController animated:YES completion:nil];
                [self.viewControllerList addObject:self.communityViewController];
            } else {
                [self.communityViewController dismissViewControllerAnimated:NO completion:^{
                    UIViewController *vc = [self getTopMostViewController];
                    [vc presentViewController:self.communityViewController animated:YES completion:nil];
                    [self.viewControllerList addObject:self.communityViewController];
                }];
            }
        }
    }

    - (void) showCustomIntroPage {
        UIViewController *infoViewController = [[infoViewControllerClass alloc] init];
        NSLog(@"custom intro view: %@", infoViewController);
        [[self.viewControllerList lastObject] presentViewController:infoViewController animated:YES completion:nil];
    }

    - (void) showIntroPage {
        if (self.isPlugin && (infoViewControllerClass != nil)) {
            NSLog(@"Showing custom intro page");
            [self showCustomIntroPage];
            return;
        }

        if (introViewController == nil) {
            introViewController = [[IntroViewController alloc] init];
        }
        
        [[self.viewControllerList lastObject] presentViewController:introViewController animated:YES completion:nil];
        [self.viewControllerList addObject:introViewController];
    }

    - (void) showOptionFeedback {
        if (optionFeedbackViewController == nil) {
            optionFeedbackViewController = [[OptionFeedbackViewController alloc] init];
        }
        
        [[self.viewControllerList lastObject] presentViewController:optionFeedbackViewController animated:YES completion:nil];
        [self.viewControllerList addObject:optionFeedbackViewController];
    }

    - (void) showAnnoDraw:(NSString*)imageURI
               levelValue:(int)levelValue
            editModeValue:(BOOL)editModeValue
       landscapeModeValue:(BOOL)landscapeModeValue {
//        CDVViewController *currentViewController = [self.viewControllerList lastObject];
        UIViewController* currentViewController = [self getTopMostViewController];

        if ((self.isPlugin) && (self.email == nil || [self.email isEqualToString:@""])) {
            NSLog(@"Email address is not specified");
            return;
        }

        AnnoDrawViewController *annoDrawViewController = [[AnnoDrawViewController alloc] init];
        [currentViewController presentViewController:annoDrawViewController animated:YES completion:nil];
        
        // Adding back lastObject of viewControllerList beacause it gets deleted after calling
        // presentViewController on lastObject of viewControllerList with annoDrawViewController
        if ([currentViewController isKindOfClass:[AnnoDrawViewController class]]) {
            [self.viewControllerList addObject:currentViewController];
            [self.annoDrawViewControllerList addObject:currentViewController];
        }
        
        [self.viewControllerList addObject:annoDrawViewController];
        [self.annoDrawViewControllerList addObject:annoDrawViewController];
        [annoDrawViewController handleFromShareImage:imageURI
                                          levelValue:levelValue
                                     isPracticeValue:false
                                       editModeValue:editModeValue
                                  landscapeModeValue:landscapeModeValue];
    }

    - (void) exitActivity {
        CDVViewController *currentViewController = [self.viewControllerList lastObject];
        
        if ([currentViewController isKindOfClass:[CommunityViewController class]]) {
            [self.communityViewController dismissViewControllerAnimated:YES completion:nil];
        } else if ([currentViewController isKindOfClass:[IntroViewController class]]) {
            [introViewController dismissViewControllerAnimated:YES completion:nil];
        } else if ([currentViewController isKindOfClass:[OptionFeedbackViewController class]]) {
            [optionFeedbackViewController dismissViewControllerAnimated:YES completion:nil];
        } else if ([currentViewController isKindOfClass:[AnnoDrawViewController class]]) {
            AnnoDrawViewController *currentAnnoDrawViewController = [self.annoDrawViewControllerList lastObject];
            [currentAnnoDrawViewController dismissViewControllerAnimated:YES completion:nil];
            [self.annoDrawViewControllerList removeLastObject];

            if (self.newAnnoCreated) {
                [self.communityViewController.webView stringByEvaluatingJavaScriptFromString:@"reloadListData()"];
                self.newAnnoCreated = FALSE;
            }
        }
        
        [self.viewControllerList removeLastObject];
    }

/**
 * Make a request and the number of unread notifications for a user, after setupWithEmail
 */
- (void) notificationsForTarget:(id)target performSelector:(SEL)selector {
    if (!self.email) {
        NSLog(@"No Email setup yet, call this method after (setupWithEmail:)");
        return;
    }
    
    NSString *url = [cloudHost stringByAppendingString:UNREAD_URL];
    url = [url stringByAppendingFormat:@"?user_email=%@", self.email];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSOperationQueue *q = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:q
                           completionHandler:^(NSURLResponse *resp, NSData *data, NSError* error) {
                               NSNumber *count = 0;
                               if (error != nil) {
                                   NSLog(@"Error requesting unread notifications %@", error);
                                   return;
                               }
                               NSDictionary *json = [self parseJSONData:data];
                               if (json != nil) {
                                   count = (NSNumber*)[json valueForKey:@"unread_count"];
                               }
                               if ([target respondsToSelector:selector]) {
                                   [target performSelectorOnMainThread:selector withObject:count waitUntilDone:NO];
                               }
                           }];
}

- (NSDictionary*) readJSONFromFile:(NSString*)filePath {
    NSDictionary *json = nil;
    NSError *err = nil;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&err];
    if (err == nil) {
        json = [self parseJSONData:data];
    } else {
        NSLog(@"Error reading file %@ %@", filePath, err);
    }
    return json;
}

- (NSDictionary*) readServerConfiguration {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"server-url" ofType:@"json" inDirectory:@"/www/anno/scripts"];
    NSDictionary *dict = nil;
    if (filePath) {
        dict = [self readJSONFromFile:filePath];
        serverConfig = [dict copy];
        cloudHost = [[serverConfig valueForKey:@"4"] valueForKey:@"apiRoot"];
    }
    
    return dict;
}

- (NSDictionary*) parseJSONData:(NSData*) data {
    NSDictionary *json = nil;
    NSError *error = nil;
    @try {
        json = [NSJSONSerialization JSONObjectWithData:data
                                               options:kNilOptions error:&error];
        if (error) {
            NSLog(@"Error Parsing JSON %@", error);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Unable to process JSON data %@ %@", data, exception);
    }
    @finally {
    }
    
    return json;
}
@end
