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
@property(nonatomic,strong,readwrite) Database *database;
@property(nonatomic,strong) NSMutableArray *databaseUpdateNotificationObservers;
@property(nonatomic,strong) NSMutableArray *memoryWarningNotificationObservers;
@property(nonatomic,strong) UIAlertView *alertView;
@property(nonatomic,readwrite) NSInteger osVersion;

- (void)setDefaultSettings;
- (void)loadCookies;
- (void)cancelAlertView;

@end

@implementation AppDelegate

@synthesize tabBarController;
@synthesize window = _window;
@synthesize mapViewController;
@synthesize alertView;
@synthesize database;
@synthesize databaseUpdateNotificationObservers;
@synthesize memoryWarningNotificationObservers;

- (void)addTabViewControllerWithClass:(Class)class viewControllers:(NSMutableArray *)viewControllers customizedViewControllers:(NSMutableArray *)customizedViewControllers
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
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSArray *aOsVersions = [[[UIDevice currentDevice]systemVersion] componentsSeparatedByString:@"."];
    self.osVersion = [[aOsVersions objectAtIndex:0] intValue];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarningDidReceive) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    self.databaseUpdateNotificationObservers = [NSMutableArray array];
    self.memoryWarningNotificationObservers = [NSMutableArray array];
    
    [self setDefaultSettings];
    [self loadCookies];
    
    self.database = [[Database alloc] init];
    NSString *errorMessage = [self.database prepareDatabase];
    
    CGRect frame = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:frame];
    
    if(errorMessage) {
        [self showAlertViewWithTitle:NSLocalizedString(@"致命的なエラー", nil) message:NSLocalizedString(@"データベースを開けません", nil) buttonTitle:NSLocalizedString(@"確認", nil)];        
    } else {
        NSMutableArray *viewControllers = [NSMutableArray arrayWithCapacity:7];
        NSMutableArray *customizableViewControllers = [NSMutableArray arrayWithCapacity:5];

        [self addTabViewControllerWithClass:[MapViewController class] viewControllers:viewControllers customizedViewControllers:nil];
        self.mapViewController = (MapViewController *)((UINavigationController *)[viewControllers objectAtIndex:0]).topViewController;
        [self addTabViewControllerWithClass:[OperatorTypesViewController class] viewControllers:viewControllers customizedViewControllers:nil];
        [self addTabViewControllerWithClass:[PlaceViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        [self addTabViewControllerWithClass:[CompletionYearViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        [self addTabViewControllerWithClass:[YomiViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        [self addTabViewControllerWithClass:[InformationViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        [self addTabViewControllerWithClass:[SyncViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        [self addTabViewControllerWithClass:[SettingsViewController class] viewControllers:viewControllers customizedViewControllers:customizableViewControllers];
        
        self.tabBarController = [[TabBarController alloc] initWithTintColor:OS7_TINT_COLOR];
        self.tabBarController.viewControllers = viewControllers;
        self.tabBarController.customizableViewControllers = customizableViewControllers;
        self.tabBarController.tabBar.tintColor = OS7_TINT_COLOR;

        self.window.rootViewController = self.tabBarController;
    }
    [self.window makeKeyAndVisible];
    
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
    [self cancelAlertView];
    [self saveCookies];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveCookies];
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
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
    self.alertView = nil;
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle
{
    [self cancelAlertView];
    if(!buttonTitle) {
        buttonTitle = NSLocalizedString(@"確認", nil);
    }
    self.alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:buttonTitle otherButtonTitles:nil];
    [self.alertView show];
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
