//
//  AppDelegate.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/10/29.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "AppDelegate.h"
#import "MapViewController.h"
#import "LinesViewControllers.h"
#import "PlaceViewController.h"
#import "YomiViewController.h"
#import "CompletionDateViewController.h"
#import "InformationViewController.h"
#import "SettingsViewController.h"
#import "SyncViewController.h"
#import "Consts.h"
#import "Settings.h"
#import "Firebase.h"

@interface TabBarController : UITabBarController<UITabBarControllerDelegate>

@end

@implementation TabBarController

- (id)initWithTintColor:(UIColor *)tintColor
{
    self = [super init];
    if(self) {
        self.moreNavigationController.navigationBar.tintColor = tintColor;
        self.delegate = self;
    }
    return self;
}

- (void)tabBarController:(UITabBarController*)tabBarController willBeginCustomizingViewControllers:(NSArray*)viewControllers
{
    UIView* subviews = [tabBarController.view.subviews objectAtIndex:1];
    UINavigationBar* navigationBar = [[subviews subviews] objectAtIndex:0];
    navigationBar.tintColor = BAR_COLOR;
}

@end

@interface AppDelegate ()

@property(nonatomic,strong) TabBarController *tabBarController;
@property(nonatomic,strong) MapViewController *mapViewController;
@property(nonatomic,strong) InformationViewController *informationViewController;
@property(nonatomic,strong) UINavigationController *informationNavigationController;
@property(nonatomic,strong,readwrite) Database *database;
@property(nonatomic,strong) NSMutableArray *databaseUpdateNotificationObservers;
@property(nonatomic,strong) NSMutableArray *memoryWarningNotificationObservers;
@property(nonatomic,strong) UIAlertController *alertController;
@property(nonatomic,readwrite) NSInteger osVersion;
@property(nonatomic,strong) CLLocationManager *locationManager;
@property(nonatomic,assign) BOOL fromBg;
@property(nonatomic,strong) NSDictionary *initialUserInfo;
@property(nonatomic,assign) BOOL firstLocatingDone;
@property(nonatomic,assign) BOOL locatingEnabled;
@property(nonatomic,assign) CLLocationCoordinate2D currentLocation;

- (void)setDefaultSettings;
- (void)loadCookies;
- (void)cancelAlertView;

@end

@implementation AppDelegate

@synthesize tabBarController;
@synthesize window = _window;
@synthesize mapViewController;
@synthesize alertController;
@synthesize database;
@synthesize databaseUpdateNotificationObservers;
@synthesize memoryWarningNotificationObservers;
@synthesize locationManager;
@synthesize locationDelegate = _locationDelegate;

- (UINavigationController *)addTabViewControllerWithClass:(Class)class viewControllers:(NSMutableArray *)viewControllers customizedViewControllers:(NSMutableArray *)customizedViewControllers
{
    UIViewController *viewController = [[class alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBar.tintColor = OS7_TINT_COLOR;
    navigationController.toolbar.tintColor = OS7_TINT_COLOR;
    navigationController.tabBarItem = viewController.tabBarItem;
    [viewControllers addObject:navigationController];
    if(customizedViewControllers) {
        [customizedViewControllers addObject:navigationController];
    }
    return navigationController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSArray *aOsVersions = [[[UIDevice currentDevice]systemVersion] componentsSeparatedByString:@"."];
    self.osVersion = [[aOsVersions objectAtIndex:0] intValue];

    [self tryRegisterNotification:application];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarningDidReceive) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

    self.databaseUpdateNotificationObservers = [NSMutableArray array];
    self.memoryWarningNotificationObservers = [NSMutableArray array];
    
    [self setDefaultSettings];
    [self loadCookies];
    
    self.database = [[Database alloc] init];
    NSString *errorMessage = [self.database prepareDatabase];
    
    CGRect frame = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:frame];
    
    self.tabBarController = [[TabBarController alloc] initWithTintColor:OS7_TINT_COLOR];

    if(errorMessage) {
        [self showAlertViewWithTitle:NSLocalizedString(@"致命的なエラー", nil) message:NSLocalizedString(@"データベースを開けません", nil) buttonTitle:NSLocalizedString(@"確認", nil) viewController:self.tabBarController];
    } else {
        NSMutableArray *viewControllers = [NSMutableArray arrayWithCapacity:7];
        NSMutableArray *customizableViewControllers = [NSMutableArray arrayWithCapacity:5];

        self.mapViewController = (MapViewController *)[self addTabViewControllerWithClass:[MapViewController class] viewControllers:viewControllers customizedViewControllers:nil].topViewController;
        [self addTabViewControllerWithClass:[OperatorTypesViewController class] viewControllers:viewControllers customizedViewControllers:nil];
        [self addTabViewControllerWithClass:[PlaceViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        [self addTabViewControllerWithClass:[CompletionYearViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        [self addTabViewControllerWithClass:[YomiViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        self.informationNavigationController = [self addTabViewControllerWithClass:[InformationViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        self.informationViewController = (InformationViewController *)[self.informationNavigationController.viewControllers firstObject];
        [self addTabViewControllerWithClass:[SyncViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        [self addTabViewControllerWithClass:[SettingsViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        
        self.tabBarController.viewControllers = viewControllers;
        self.tabBarController.customizableViewControllers = customizableViewControllers;
        self.tabBarController.tabBar.tintColor = OS7_TINT_COLOR;

        self.window.rootViewController = self.tabBarController;
    }
    [self.window makeKeyAndVisible];

    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        self.initialUserInfo = userInfo;
    }
    self.fromBg = YES;

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    self.initialUserInfo = nil;
    [self cancelAlertView];
    [self saveCookies];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    self.fromBg = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.initialUserInfo) {
        if (self.fromBg) {
            [self changeTab:self.initialUserInfo[@"fragment"]];
            self.fromBg = NO;
        } else {
            [self showPushNotificationAlertWithUserInfo:self.initialUserInfo];
        }
        self.initialUserInfo = nil;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveCookies];
}

- (void)tryRegisterNotification:(UIApplication *)application {
    [FIRApp configure];
    
    UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [application registerUserNotificationSettings:mySettings];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
    [[FIRMessaging messaging] subscribeToTopic:@"/topics/ioritsubushi"];
    
    [self tryRegisterLocationNotification:application];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken {
    NSLog(@"%@", [[FIRInstanceID instanceID] token]);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self tryRegisterLocationNotification:application];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (application.applicationState == UIApplicationStateActive) {
        [self showPushNotificationAlertWithUserInfo:userInfo];
    } else {
        self.initialUserInfo = userInfo;
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)changeTab:(NSString *)tabName {
    if ([@"info" isEqualToString:tabName]) {
        if (self.tabBarController.selectedViewController == self.informationNavigationController) {
            [self.informationViewController load];
        } else {
            self.tabBarController.selectedViewController = self.informationNavigationController;
        }
    }
}

- (void)tryRegisterLocationNotification:(UIApplication *)application {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            self.locatingEnabled = YES;
            [self.locationDelegate beginLocating:YES];
            [self.locationManager startUpdatingLocation];
            break;
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            self.firstLocatingDone = YES;
            self.locatingEnabled = NO;
            [self.locationDelegate beginLocating:NO];
            break;
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    self.currentLocation = [location coordinate];
    self.firstLocatingDone = YES;
    [self.locationManager stopUpdatingLocation];
    [self.locationDelegate locationWasUpdated:self.currentLocation];
}

- (void)setLocationDelegate:(id<LocationUpdatedDelegate>)locationDelegate {
    _locationDelegate = locationDelegate;
    if (self.firstLocatingDone) {
        [locationDelegate beginLocating:self.locatingEnabled];
        if (self.locatingEnabled) {
            [locationDelegate locationWasUpdated:self.currentLocation];
        }
    }
}

- (void)memoryWarningDidReceive
{
    [self cancelAlertView];
}

- (void)mapViewMoveToStation:(Station *)station
{
    [self.mapViewController moveToStation:station];
}

- (void)mapViewUpdateFilterWithFilterType:(DatabaseFilterType)type filterValue:(NSString *)value
{
    [self.mapViewController updateFilterWithFilterType:type filterValue:value];
}

- (void)mapViewRequestUpdate
{
    [self.mapViewController requestUpdate];
}

- (void)cancelAlertView
{
    [self.alertController dismissViewControllerAnimated:YES completion:nil];
    self.alertController = nil;
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle viewController:(UIViewController *)viewController
{
    [self cancelAlertView];
    if(!buttonTitle) {
        buttonTitle = NSLocalizedString(@"確認", nil);
    }
    self.alertController = [UIAlertController alertControllerWithTitle:title
                                                               message:message
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [self.alertController addAction:[UIAlertAction actionWithTitle:buttonTitle
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}]];
    [viewController presentViewController:self.alertController animated:YES completion:nil];
}

- (void)showPushNotificationAlertWithUserInfo:(NSDictionary *)userInfo {
    [self cancelAlertView];
    self.alertController = [UIAlertController alertControllerWithTitle:userInfo[@"aps"][@"alert"][@"title"]
                                                               message:userInfo[@"aps"][@"alert"][@"body"]
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"詳細を見る", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               [self changeTab:userInfo[@"fragment"]];
                                                           }]];
    [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"キャンセル", nil)
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {}]];
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    [topController presentViewController:self.alertController animated:YES completion:nil];
}

- (void)setDefaultSettings
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if(![userDefaults integerForKey:SETTINGS_KEY_NUMBER_OF_ICONS]) {
        NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:1];
        [settings setObject:[NSNumber numberWithInt:NUMBER_OF_ICONS_DEFAULT] forKey:SETTINGS_KEY_NUMBER_OF_ICONS];
        [userDefaults registerDefaults:settings];
    }
}

- (void)loadCookies
{
    NSData *cookiesData = [[NSUserDefaults standardUserDefaults] objectForKey:SETTINGS_KEY_COOKIES];
    if (cookiesData) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
    
}
- (void)saveCookies
{
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[NSUserDefaults standardUserDefaults] setObject:cookiesData forKey:SETTINGS_KEY_COOKIES];    
}

@end
