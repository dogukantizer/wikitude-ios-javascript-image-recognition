//
//  WTAugmentedRealityViewController.m
//  SDKExamples
//
//  Created by Andreas Schacherbauer on 23/09/14.
//  Copyright (c) 2014 Wikitude. All rights reserved.
//

#import "WTAugmentedRealityViewController.h"

#import "NSURL+ParameterQuery.h"

#import "WTAugmentedRealityExperience.h"

#import "WTAugmentedRealityViewController+ExampleCategoryManagement.h"
#import "WTAugmentedRealityViewController+PresentingPoiDetails.h"
#import "WTAugmentedRealityViewController+ScreenshotSharing.h"
#import "WTAugmentedRealityViewController+SaveAndLoadCurrentInstantTarget.h"



/* Wikitude SDK license key (only valid for this application's bundle identifier) */
#define kWT_LICENSE_KEY @"NGBXvYi66YY4pT3CqeLvcv31N9xl4uasQSZwF5xPfJ5lcrI5leTkRrzzVihYTbEbRWRf9S9hWqkeCykxd1IgU/qbg5WJjwSK7dk9f/zHwlV1Qa/JYIB6l+sh2OjrdrXO7E9Qdqih1RYGF+3MDt7CC3BmMUrhkFanOvCf/eXMmX1TYWx0ZWRfX6PikQ4qQBjn7mRR7l4e36y3jrIqcuQfE4vdeKCDiD2pePwQ41U/FnA7HSShjqq9TcTpQaASuWQL+nnrKUU3ybpck+50zKokc0nK6tX0rjqAE3cKZJIXMV1VRszX2rUJFFzM80eMWNQ2FN6I3e0LlyY3gkAt05XUiTq4YaOVb62gRlytIPNvaxwFoj3Xvh5+vR4afdbKAgdAlxT4KLazRObTUBuYHWeKU9/cXR4RagzSDUt+mpYzEVpZTB8OjGFWKf+j+5kCRrQ/ra4gYIuf3KqYFy0JsuAeN2keaI5M34saqcTNSUV7Ng1V/ZjJg9Ac56TLC+D1FuMDdpZ6c3eWTsaccwc4tMmnyiA8Y60GqXIeFOClE1locWR0Fu/MXmOkoFSXGy/ldfzVOo756Mhb4xCSTvbN+PUKbyM9EYWrmj3Yu88wxglud9L+G8etmi+Mr1wO4SGCfIQdzu1Pt9go8QhZpIB7Nyk1IirWW99b10Kzh8rW1fj8ReVBddHb4SU5+r2/CmAUMrbohodJFBefpbagBhQ7EV8sg/1ylBYaNVXUi3bfCt437rcwNniWV6/Pm4thryejMMflAji9gp+TgioY4r1ex6LDzzzRrHGZ+Qypwrm41oxWpz5Gw4hbkeakbqhVT7AgTq2bvQ++Gkksaw5RO54rIzuh2QOu1Ad+XY81VHLYMnudcLzWuY3WcrQEqgQ/jRIGOH4ZywKTOqtXozF4Us85z5CWHfdESc2foe68ZbOem/pn7a9Hk+foWy9oFp8/0lEKjoVCZp264eeU7EsdQoHNnPDq8w3UZSfVGd3sOytAIQAkeFER/5GNQBXM+gsoCU3cd5Wrfvj9LHrC223CqdDENpyVc2uHc+RfyOAhXMZxtw0+Hi2etkJXkC+6y4ncxwKt8wlThhBtpDfgE0wB6wZ0sHLE+fmK7LOSUipj8qc7s6sD01la+xHL7yrcpWDJIJ46cgiycaVb7AWSW5c8wXpKK+i/JgI8IDVDPqMFZVfhFhfW8jg="




@interface WTAugmentedRealityViewController ()

@property (nonatomic, assign) BOOL                                          showsBackButtonOnlyInNavigationItem;
@property (nonatomic, weak) WTAugmentedRealityExperience                    *augmentedRealityExperience;
@property (nonatomic, copy) WTNavigation                                    *loadedArchitectWorldNavigation;
@property (nonatomic, weak) WTNavigation                                    *loadingArchitectWorldNavigation;
@property (nonatomic, assign) AVCaptureDevicePosition                       currentlyActiveCaptureDevicePosition;

@end


@implementation WTAugmentedRealityViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    /* Architect view specific initialization code 
     * - a license key is set to enable all SDK features
     * - the architect view delegate is set so that the application can react on SDK specific events
     */
    [self.architectView setLicenseKey:kWT_LICENSE_KEY];
    self.architectView.delegate = self;

    self.currentlyActiveCaptureDevicePosition = AVCaptureDevicePositionUnspecified;


    /* The architect view needs to be paused/resumed when the application is not active. We use UIApplication specific notifications to pause/resume architet view rendering depending on the application state */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveApplicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /* Set’s a nicely formatted navigation item title based on from where this view controller was pushed onto the navigation stack */
    NSString *navigationItemTitle = self.augmentedRealityExperience.title;
    if ( UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom] )
    {
        NSString *urlString = [self.augmentedRealityExperience.URL isFileURL] ? @"" : [NSString stringWithFormat:@" - %@", [self.augmentedRealityExperience.URL absoluteString]];
        navigationItemTitle = [NSString stringWithFormat:@"%@%@", self.augmentedRealityExperience.title, urlString];
    }
    self.navigationItem.title = navigationItemTitle;
    
    if ( self.showsBackButtonOnlyInNavigationItem )
    {
        self.navigationItem.rightBarButtonItem = nil;
    }

    /* Setting the interativePopGestureRecognizer delegate and implementing the -gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer like shown in the vc is important for Wikitude gestures to work */
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    
    /* Depending on the currently load architect world a new world will be loaded */
    [self checkExperienceLoadingStatus];
    /* And the Wikitude SDK rendering is resumed if it’s currently paused */
    [self startArchitectViewRendering];
    /* Just to make sure that the Wikitude SDK is rendering in the correct interface orientation just in case the orientation changed while this view was not visible */
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self.architectView setShouldRotate:YES toInterfaceOrientation:orientation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    /* iOS 8 requires to set the interactivePopGestureRecognizer to nil in order to prevent a crash in the underlying vc */
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    /* Pause architect view rendering when this view is not visible anymore */
    [self stopArchitectViewRendering];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Public Methods

- (void)loadAugmentedRealityExperience:(WTAugmentedRealityExperience *)experience showOnlyBackButton:(BOOL)showBackButtonOnlyInNavigationItem
{
    /* iOS 9 seems to have some problems with WKWebView and pause/resume, so we only allow it for iOS 10 or newer */
    if ( [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}] )
    {
        WTArchitectView.shouldUseWebKit = YES;
    }

    /* This method could be called at any time so we keep a referenz to the experience object and load it’s architect world once it’s guaranteed that the architect view is loaded from the storyboard */
    self.augmentedRealityExperience = experience;
    
    
    /* Depending from where this view controller was pushed we want to display the back button only or an additional done button. */
    self.showsBackButtonOnlyInNavigationItem = showBackButtonOnlyInNavigationItem;
}


#pragma mark - Layout / Rotation

/* Wikitude SDK Rotation handling
 *
 * viewWillTransitionToSize -> iOS 8 and newer
 * willRotateToInterfaceOrientation -> iOS 7
 *
 * Overriding both methods seems to work for all the currently supported iOS Versions
 * (7, 8, 9). The run-time version check is included nonetheless. Better safe than sorry.
*/

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
   if (coordinator)
   {
       [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
        {
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            [self.architectView setShouldRotate:YES toInterfaceOrientation:orientation];

        } completion:nil];
   }
   else
   {
       UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
       [self.architectView setShouldRotate:YES toInterfaceOrientation:orientation];
   }

   [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //if iOS 8.0 or greater according to http://stackoverflow.com/questions/3339722/how-to-check-ios-version
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
        return;
    }
    [self.architectView setShouldRotate:YES toInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark - Delegation
#pragma mark WTArchitectView

/* This architect view delegate method is used to keep the currently loaded architect world url. Every time this view becomes visible again, the controller checks if the current url is not equal to the new one and then loads the architect world */
- (void)architectView:(WTArchitectView *)architectView didFinishLoadArchitectWorldNavigation:(WTNavigation *)navigation
{
    if ( [self.loadingArchitectWorldNavigation isEqual:navigation] )
    {
        self.loadedArchitectWorldNavigation = navigation;
    }
}

- (void)architectView:(WTArchitectView *)architectView didFailToLoadArchitectWorldNavigation:(WTNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"architect view '%@' \ndid fail to load navigation '%@' \nwith error '%@'", architectView, navigation, error);
}

- (UIViewController *)presentingViewControllerForViewControllerPresentationInArchitectView:(WTArchitectView *)architectView
{
    return self;
}

/* As mentioned before, some architect examples require iOS specific implementation details.
 * Here is the decision made which iOS specific details should be executed
 */
- (void)architectView:(WTArchitectView *)architectView receivedJSONObject:(NSDictionary *)jsonObject
{
    id actionObject = [jsonObject objectForKey:@"action"];
    if ( actionObject
        &&
         [actionObject isKindOfClass:[NSString class]]
        )
    {
        NSString *action = (NSString *)actionObject;
        if ( [action isEqualToString:@"capture_screen"] )
        {
            [self captureScreen];
        }
        else if ( [action isEqualToString:@"present_native_details"] )
        {
            [self presentPoiDetails:jsonObject];
        }
        else if ( [action isEqualToString:@"save_current_instant_target"] )
        {
            NSString *currentAugmentationsStringRepresentation = [jsonObject objectForKey:@"augmentations"];
            [self saveCurrentInstantTarget:currentAugmentationsStringRepresentation];
        }
        else if ( [action isEqualToString:@"load_existing_instant_target"] )
        {
            [self loadExistingInstantTarget];
        }
    }
}

/* Use this method to implement/show your own custom device sensor calibration mechanism.
 *  You can also use the system calibration screen, but pls. read the WTStartupConfiguration documentation for more details.
 */
- (void)architectViewNeedsDeviceSensorCalibration:(WTArchitectView *)architectView
{
    NSLog(@"Device sensor calibration needed. Rotate the device 360 degree around it's Y-Axis");
}

/* When this method is called, the device sensors are calibrated enough to deliver accurate values again.
 * In case a custom calibration screen was shown, it can now be dismissed.
 */
- (void)architectViewFinishedDeviceSensorsCalibration:(WTArchitectView *)architectView
{
    NSLog(@"Device sensors calibrated");
}

- (void)architectView:(WTArchitectView *)architectView didSwitchToActiveCaptureDevicePosition:(AVCaptureDevicePosition)activeCaptureDevicePosition
{
    self.currentlyActiveCaptureDevicePosition = activeCaptureDevicePosition;
}

#pragma mark UIGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Notifications
/* UIApplication specific notifications are used to pause/resume the architect view rendering */
- (void)didReceiveApplicationWillResignActiveNotification:(NSNotification *)notification
{
    [self stopArchitectViewRendering];
}

- (void)didReceiveApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self startArchitectViewRendering];
}


#pragma mark - Private Methods

/* The method that is invoked everytime the view becomes visible again and then decides if a new architect world needs to be loaded or not */
- (void)checkExperienceLoadingStatus
{
    if ( ![self.loadedArchitectWorldNavigation.originalURL isEqual:self.augmentedRealityExperience.URL] )
    {
        /* A few architect world examples require additional iOS specific implementation details. These details are given in class extensions that are loaded here. */
        [self loadExampleSpecificCategoryForAugmentedRealityExperience:self.augmentedRealityExperience];

        self.architectView.requiredFeatures = self.augmentedRealityExperience.requiredFeatures;
        self.loadingArchitectWorldNavigation = [self.architectView loadArchitectWorldFromURL:self.augmentedRealityExperience.URL];
    }
}

/* The next two methods actually start/stop architect view rendering */
- (void)startArchitectViewRendering
{
    if ( ![self.architectView isRunning] )
    {
        [self.architectView start:^(WTArchitectStartupConfiguration *configuration)
         {
             if ( self.currentlyActiveCaptureDevicePosition != AVCaptureDevicePositionUnspecified )
             {
                 configuration.captureDevicePosition = self.currentlyActiveCaptureDevicePosition;
             }
             else
             {
                 NSString *captureDevicePositionString = [self.augmentedRealityExperience.startupParameters objectForKey:kWTAugmentedRealityExperienceStartupParameterKey_CaptureDevicePosition];
                 configuration.captureDevicePosition = [captureDevicePositionString isEqualToString:kWTAugmentedRealityExperienceStartupParameterKey_CaptureDevicePosition_Back] ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
             }

            NSString *captureDeviceResolutionString = [self.augmentedRealityExperience.startupParameters objectForKey:kWTAugmentedRealityExperienceStartupParameterKey_CaptureDeviceResolution];
            if ( captureDeviceResolutionString )
            {
                if ( [kWTAugmentedRealityExperienceStartupParameterKey_CaptureDeviceResolution_Auto isEqualToString:captureDeviceResolutionString] )
                {
                    configuration.captureDeviceResolution = WTCaptureDeviceResolution_AUTO;
                }
                else if ( [kWTAugmentedRealityExperienceStartupParameterKey_CaptureDeviceResolution_SD_640x480 isEqualToString:captureDeviceResolutionString] )
                {
                    configuration.captureDeviceResolution = WTCaptureDeviceResolution_SD_640x480;
                }
                else if ( [kWTAugmentedRealityExperienceStartupParameterKey_CaptureDeviceResolution_HD_1280x720 isEqualToString:captureDeviceResolutionString] )
                {
                    configuration.captureDeviceResolution = WTCaptureDeviceResolution_HD_1280x720;
                }
                else if ( [kWTAugmentedRealityExperienceStartupParameterKey_CaptureDeviceResolution_FULL_HD_1920x1080 isEqualToString:captureDeviceResolutionString] )
                {
                    configuration.captureDeviceResolution = WTCaptureDeviceResolution_FULL_HD_1920x1080;
                }
            }
             
             NSString *captureDeviceManualFocusDistanceString = [self.augmentedRealityExperience.startupParameters objectForKey:kWTAugmentedRealityExperienceStartupParameterKey_ManualFocusDistance];
             configuration.captureDeviceFocusDistance = [captureDeviceManualFocusDistanceString floatValue];
        }
        completion:^(BOOL isRunning, NSError *error) {
            if ( !isRunning )
            {
                NSString *title = @"Unable to start WTArchitectView";
                if ( [@"com.wikitude.architect.AuthorizationStates" isEqualToString:[error domain]] )
                {
                    if ( 960 == [error code] )
                    {
                        NSDictionary *unauthorizedAPIInfo = [[error userInfo] objectForKey:kWTUnauthorizedAppleiOSSDKAPIsKey];

                        NSMutableString *detailedAuthorizationErrorLogMessage = [[NSMutableString alloc] initWithFormat:@"The following authorization states do not meet the requirements:"];
                        NSMutableString *missingAuthorizations = [[NSMutableString alloc] initWithFormat:@"In order to use the Wikitude SDK, please grant access to the following:"];
                        for (NSString *unauthorizedAPIKey in [unauthorizedAPIInfo allKeys])
                        {
                            [missingAuthorizations appendFormat:@"\n* %@", [WTAuthorizationRequestManager humanReadableDescriptionForUnauthorizedAppleiOSSDKAPI:unauthorizedAPIKey]];

                            [detailedAuthorizationErrorLogMessage appendFormat:@"\n%@ = %@", unauthorizedAPIKey, [WTAuthorizationRequestManager stringFromAuthorizationStatus:[[unauthorizedAPIInfo objectForKey:unauthorizedAPIKey] integerValue] forUnauthorizedAppleiOSSDKAPI:unauthorizedAPIKey]];
                        }
                        NSLog(@"%@", detailedAuthorizationErrorLogMessage);
                        UIAlertController *architectNotStartedAlertController = [UIAlertController alertControllerWithTitle:title message:missingAuthorizations preferredStyle:UIAlertControllerStyleAlert];
                        [architectNotStartedAlertController addAction:[UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                        }]];
                        [architectNotStartedAlertController addAction:[UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDestructive handler:nil]];

                        [self presentViewController:architectNotStartedAlertController animated:YES completion:nil];
                    }
                }
            }
        }];
    }
}

- (void)stopArchitectViewRendering
{
    if ( [self.architectView isRunning] )
    {
        [self.architectView stop];
    }
}

@end
