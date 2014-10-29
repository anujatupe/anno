//
//  AnnoSingleton.m
//  UserSource
//
//  Created by Rishi Diwan on 22/10/14.
//
//

#import "AnnoSingleton.h"

@implementation AnnoSingleton
@synthesize utils;

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

    - (void) showCommunityPage {
        CDVViewController *currentViewController = [self.viewControllerList lastObject];
        
        if (self.email == nil || self.teamKey == nil || self.teamSecret == nil) {
            /* Show email controller */
            NSLog(@"Please specify email, teamKey, and teamSecret");
            return;
        }
        
        if (currentViewController != self.communityViewController) {
            [currentViewController presentViewController:self.communityViewController animated:YES completion:nil];
            [self.viewControllerList addObject:self.communityViewController];
        }
    }

    - (void) ShowIntroPage {
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
        CDVViewController *currentViewController = [self.viewControllerList lastObject];
        AnnoDrawViewController *annoDrawViewController = [[AnnoDrawViewController alloc] init];
        [currentViewController presentViewController:annoDrawViewController animated:NO completion:nil];
        
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
            self.communityViewController = nil;
        } else if ([currentViewController isKindOfClass:[IntroViewController class]]) {
            [introViewController dismissViewControllerAnimated:YES completion:nil];
            introViewController = nil;
        } else if ([currentViewController isKindOfClass:[OptionFeedbackViewController class]]) {
            [optionFeedbackViewController dismissViewControllerAnimated:YES completion:nil];
            optionFeedbackViewController = nil;
        } else if ([currentViewController isKindOfClass:[AnnoDrawViewController class]]) {
            AnnoDrawViewController *currentAnnoDrawViewController = [self.annoDrawViewControllerList lastObject];
            [currentAnnoDrawViewController dismissViewControllerAnimated:YES completion:nil];
            currentAnnoDrawViewController = nil;
            [self.annoDrawViewControllerList removeLastObject];
        }
        
        [self.viewControllerList removeLastObject];
    }

@end
