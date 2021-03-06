//
//  AnnoSingleton.h
//  UserSource
//
//  Created by Rishi Diwan on 22/10/14.
//
//

#import <Foundation/Foundation.h>
#import <UserSourceStatic/annoCordovaPlugin.h>

@interface AnnoSingleton : NSObject {
    AnnoCordovaPlugin *annoPlugin;
    CommunityViewController *communityViewController;
    IntroViewController *introViewController;
    OptionFeedbackViewController *optionFeedbackViewController;
    NSString *email, *displayName, *userImageURL, *teamKey, *teamSecret;
    NSMutableArray *viewControllerList, *annoDrawViewControllerList;
    AnnoUtils *utils;
    BOOL isPlugin, newAnnoCreated;
    Class infoViewControllerClass;
    int unreadCount;
    NSArray *shakeSensitivityValues;
    BOOL allowShake;
    NSInteger shakeValue;
    NSMutableDictionary *shakeSettingsData;
}

@property (strong, retain) CommunityViewController *communityViewController;
@property (strong, retain) AnnoCordovaPlugin *annoPlugin;
@property (strong, retain) AnnoUtils *utils;
@property (strong, retain) NSString *email, *displayName, *userImageURL, *teamKey, *teamSecret;
@property NSMutableArray *viewControllerList;
@property NSMutableArray *annoDrawViewControllerList;
@property BOOL isPlugin, newAnnoCreated;
@property (assign) Class infoViewControllerClass;
@property int unreadCount;
@property NSArray *shakeSensitivityValues;
@property BOOL allowShake;
@property NSInteger shakeValue;
@property NSMutableDictionary *shakeSettingsData;

+ (id) sharedInstance;

- (void) showCommunityPage;
- (void) showIntroPage;
- (void) showOptionFeedback;
- (void) exitActivity;
- (void) notificationsForTarget:(id)target performSelector:(SEL)selector;
- (NSDictionary*) readServerConfiguration;

- (UIViewController*) getTopMostViewController;

- (void) showAnnoDraw:(NSString*)imageURI
           levelValue:(int)levelValue
        editModeValue:(BOOL)editModeValue
   landscapeModeValue:(BOOL)landscapeModeValue;

- (void) setupWithEmail:(NSString*)email
            displayName:(NSString*)displayName
           userImageURL:(NSString*)userImageURL
                teamKey:(NSString*)teamKey
             teamSecret:(NSString*)teamSecret;

- (void) saveAllowShake:(BOOL)allowShakeValue;
- (void) saveShakeValue:(NSInteger)shakeValueNumber;

@end