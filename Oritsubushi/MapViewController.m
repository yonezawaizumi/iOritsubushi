//
//  MapViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/10/30.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "MapViewController.h"
#import "Station.h"
#import "AnnotationView.h"
#import "SearchBar.h"
#import "SearchScopeBar.h"
#import "LoadingView.h"
#import "Consts.h"
#import "Misc.h"
#import "StationInformationViewController.h"
#import "DatabaseFilterTypes.h"
#import "AppDelegate.h"
#import "Settings.h"

#import "UIViewController+MJPopupViewController.h"

typedef enum {
    FirstLocatingWait,
    FirstLocatingTemporary,
    FirstLocatingDone
} FirstLocatingStatus;

typedef enum {
    MapStyleMap,
    MapStyleSattelite,
    MapStyleHybrid,
    MapStyleList,
    NUM_MAP_STYLE_MODE
} MapStyleMode;

static NSString *mapStyleModeLabel[] = {
    @"地図",
    @"空撮",
    @"複合",
    @"一覧",    
};

static NSString *mapStyleModeTitle[] = {
    @"地図",
    @"航空写真",
    @"地図・空撮",
    @"一覧",    
};


static NSString *visibilityTypeLabel[] = {
    @"全駅",
    @"済",
    @"未",
};
/*static CGFloat visibilityTypeLabelWidth[] = {
    40,
    32,
    32,
};*/

static BOOL stringsAreLocalized = NO;

static void *settingsContext = (void *)2;

@interface MapViewController () {
    FirstLocatingStatus firstLocatingStatus;
    BOOL isShowBars;
    BOOL annotationWasTappedRecently;
    NSInteger numberOfIcons;
    
    BOOL locatingEnabled;
    
    dispatch_queue_t queue;
}

@property(nonatomic,strong) MapView *mapView;
@property(nonatomic,strong) SearchBar *searchBar;
@property(nonatomic,strong) MapWrapper *mapWrapper;
@property(nonatomic,strong) LoadingView *loadingView;
@property(nonatomic,strong) UIView *listView;
@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSIndexPath *selectedIndexPath;
@property(nonatomic,strong) UIBarButtonItem *presentButton;
@property(nonatomic,strong) UISegmentedControl *mapStyleModeSegmentedControl;
@property(nonatomic,strong) UISegmentedControl *visibilitySegmentedControl;
@property(nonatomic,strong) NSMutableDictionary *stations;
@property(nonatomic,strong) NSArray *stationsForList;
@property(nonatomic,strong) NSNumber *reservedStationCode;
@property(nonatomic,strong) SearchScopeBar *searchScopeBar;
@property(nonatomic,strong) NSString *searchKeyword;
@property(nonatomic,strong) GoogleMapsService *GMapService;
@property(nonatomic,strong) UIActivityIndicatorView *mapIndicator;
@property(nonatomic,strong) UIToolbar *myToolbar;
@property(nonatomic,assign) BOOL logoInitialized;
@property(nonatomic,assign) BOOL inAnimation;
@property(nonatomic,assign) DatabaseFilterType recentFilterType;
@property(nonatomic,assign) BOOL mustSearch;

@property(assign) MKCoordinateRegion recentRegion;

- (void)present;
- (void)swapMapAndList;
- (void)mapStyleModeWantsToChange;
- (void)visibilityWantsToChange;
- (void)showHideBars:(BOOL)show animated:(BOOL)animated;
- (void)setButtonsEnabled:(BOOL)enabled;

- (void)finishFirstLocatingIfDecided;
- (void)terminateFirstLocating;

- (void)updateAnnotations:(NSMutableArray *)newStations;

- (void)setFormattedSearchText;

- (void)setLocation:(CLLocationCoordinate2D)coordinate setDelta:(BOOL)setDelta;

- (void)showStationInformationWithStation:(Station *)station;

@end

@implementation MapViewController

@synthesize mapView;
@synthesize mapWrapper;
@synthesize loadingView;
@synthesize searchBar;
@synthesize listView, tableView, selectedIndexPath;
@synthesize presentButton;
@synthesize mapStyleModeSegmentedControl;
@synthesize visibilitySegmentedControl;
@synthesize stations, stationsForList;
@synthesize reservedStationCode;
@synthesize searchScopeBar;
@synthesize searchKeyword;
@synthesize GMapService;
@synthesize mapIndicator;

@synthesize recentRegion;

@synthesize cell = cell_;

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"地図", nil) image:[UIImage imageNamed:@"tabicon_map"] tag:0];
    }
    return self;
}

- (void)dealloc
{
    if(queue) {
        //dispatch_release(queue);
        queue = nil;    //20111229
    }
    self.mapView.delegate = nil;
    self.mapView = nil;
    self.mapWrapper = nil;
    self.loadingView = nil;
    self.searchBar = nil;
    self.presentButton = nil;
    self.mapStyleModeSegmentedControl = nil;
    self.visibilitySegmentedControl = nil;
    self.stations = nil;
    self.stationsForList = nil;
    self.listView = nil;
    self.tableView = nil;
    self.selectedIndexPath = nil;
    self.reservedStationCode = nil;
    self.searchScopeBar = nil;
    self.searchKeyword = nil;
    self.GMapService = nil;
    self.mapIndicator = nil;
}

- (void)initializeLogo
{
    //iOS11のMkMapViewの著作権表示リンクはツールバーの高さを勝手に忖度してSafeAreaに基づいてずれる
    //かつ、それ以外にずらす方法がないので、なにもしないでよい
    if (IS_OS_11_OR_LATER) {
        self.logoInitialized = YES;
    } else {
        for(UIView *v in self.mapView.subviews) {
            if([v isKindOfClass:[UILabel class]]) {
                CGRect frame = v.frame;
                frame.origin.y -= 44;
                v.frame = frame;
                self.logoInitialized = YES;
                return;
            }
        }
    }
}

- (void)loadView
{
    [super loadView];
    // ビュー初期化
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    CGRect frame = appDelegate.window.frame;

    self.view = [[UIView alloc] initWithFrame:frame];
    self.navigationItem.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.mapView = [[MapView alloc] initWithFrame:frame];
    self.mapView.showsUserLocation = NO;
    self.mapView.delegate = self;

    [self.view addSubview:self.mapView];
    self.mapIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.mapIndicator.hidesWhenStopped = YES;
    self.mapIndicator.frame = CGRectMake(4, 48, 21, 21);
    [self.view addSubview:self.mapIndicator];
    self.loadingView = [[LoadingView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.view addSubview:self.loadingView];

    //TODO: 仮の実装 iPad版では動的に算出しなければならない！
    self.listView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height - (IS_IPHONE_X ? 44 : 0))];
    self.listView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.listView.backgroundColor = [UIColor whiteColor];
    self.listView.hidden = YES;
    [self.view addSubview:self.listView];
    //20120919 corrected
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //AD HOC!!!
    UIEdgeInsets insets = UIEdgeInsetsMake(69, 0, 88 + 4, 0);
    if (IS_OS_11_OR_LATER) {
        if (@available(iOS 11.0, *)) {
            self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        if (IS_IPHONE_X_SIZE) {
            insets.top += 20;
            insets.bottom += 44;
        }
    }
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset = insets;
    [self.listView addSubview:self.tableView];
    
    self.mapWrapper = [[MapWrapper alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.mapWrapper.delegate = self;
    [self.view addSubview:self.mapWrapper];
    self.searchScopeBar = [[SearchScopeBar alloc] initWithFrame:CGRectMake(
                                                                           0,
                                                                           (IS_IPHONE_X ? 88 : 64) - SCOPE_BAR_HEIGHT,
                                                                           frame.size.width,
                                                                           SCOPE_BAR_HEIGHT)];
    [self.view addSubview:self.searchScopeBar];
    self.searchScopeBar.filterType = self.recentFilterType = DatabaseFilterTypeNone;
    
    isShowBars = YES;
    
    // ボタン初期化
    if(!stringsAreLocalized) {
        //関数マクロでこれを書くとARC enabledなLLVMに怒られる。ぶっちゃけ、Cマクロが使えなくなるなんて、Objective-Cの利便性放棄ぢゃん…
        for(int index = 0; index < countof(mapStyleModeLabel); ++index) {
            mapStyleModeLabel[index] = NSLocalizedString(mapStyleModeLabel[index], nil);
            mapStyleModeTitle[index] = NSLocalizedString(mapStyleModeTitle[index], nil);
        }
        for(int index = 0; index < NUM_VISIBILITY_TYPES; ++index) {
            visibilityTypeLabel[index] = NSLocalizedString(visibilityTypeLabel[index], nil);
        }
        stringsAreLocalized = YES;
    }
    
    self.presentButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:100 target:self action:@selector(present)];
    self.presentButton.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = self.presentButton;
    
    self.searchBar = [[SearchBar alloc] initWithFrame:CGRectMake(0, 0, 100/*仮の値、横幅決定後に修正*/, SEARCH_BAR_HEIGHT)];
    self.searchBar.delegate = self;
    self.searchKeyword = @"";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
    
    self.mapStyleModeSegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:mapStyleModeLabel count:countof(mapStyleModeLabel)]];
    self.mapStyleModeSegmentedControl.selectedSegmentIndex = MapStyleMap;
    self.mapStyleModeSegmentedControl.tintColor = OS7_TINT_COLOR;
    [self.mapStyleModeSegmentedControl addTarget:self action:@selector(mapStyleModeWantsToChange) forControlEvents:UIControlEventValueChanged];
    
    self.visibilitySegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:visibilityTypeLabel count:NUM_VISIBILITY_TYPES]];
    self.visibilitySegmentedControl.selectedSegmentIndex = VisibilityAllStations;
    self.visibilitySegmentedControl.tintColor = OS7_TINT_COLOR;
    [self.visibilitySegmentedControl addTarget:self action:@selector(visibilityWantsToChange) forControlEvents:UIControlEventValueChanged];

    NSArray* toolbarItems = [NSArray arrayWithObjects:
                         [[UIBarButtonItem alloc] initWithCustomView:self.visibilitySegmentedControl],
                         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc] initWithCustomView:self.mapStyleModeSegmentedControl],
                         nil];
    if (IS_IPHONE_X_TAB_BUG) {
        //iPhone Xでは、タブバーとナビゲーションコントローラーのツールバーが両方あるとこの計算にバグる
        //そのため、メインビューに直接ツールバーを貼ってごまかす
        CGRect rect = self.view.bounds;
        rect.origin.y = rect.size.height - 44 - 62 - 20;
        rect.size.height = 44;
        self.myToolbar = [[UIToolbar alloc]  initWithFrame:rect];
        self.myToolbar.items = toolbarItems;
        self.myToolbar.hidden = YES;
        [self.view addSubview:self.myToolbar];
        //iOS11のMkMapViewの著作権表示リンクはツールバーの高さを勝手に忖度してSafeAreaに基づいてずれる
        //かつ、それ以外にずらす方法がない
        //なので、iPhone Xではとりあえず透明にしたカラのナビゲーションツールバーを表示した上でずらさせる
        [self.navigationController.toolbar setBackgroundImage:[UIImage new]
                        forToolbarPosition:UIBarPositionAny
                                barMetrics:UIBarMetricsDefault];
        [self.navigationController.toolbar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionAny];
    } else {
        self.toolbarItems = toolbarItems;
    }

    [self updateFilterWithFilterType:self.recentFilterType filterValue:self.searchKeyword];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    queue = dispatch_queue_create("com.wsf-lp.oritsubushi.update-annotations", NULL);

    // Do any additional setup after loading the view from its nib.
    self.navigationController.toolbarHidden = NO;
    [self setButtonsEnabled:NO];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    numberOfIcons = [userDefaults integerForKey:SETTINGS_KEY_NUMBER_OF_ICONS];
    [userDefaults addObserver:self forKeyPath:SETTINGS_KEY_NUMBER_OF_ICONS options:0 context:settingsContext];

    [Database addObserver:self];
    
    [self setLocation:[self.mapView.userLocation.location coordinate] setDelta:YES];
    firstLocatingStatus = FirstLocatingWait;
    [self performSelector:@selector(finishFirstLocatingIfDecided) withObject:nil afterDelay:FIRST_LOCATING_DECIDE_DELAY];
    ((AppDelegate *)[UIApplication sharedApplication].delegate).locationDelegate = self;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect frame = self.searchBar.frame;
    frame.size.width = self.view.frame.size.width - SEARCH_BAR_LEFT_MARGIN;
    self.searchBar.frame = frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self showHideBars:isShowBars animated:animated];
    [self mapStyleModeWantsToChange];
    if(!self.logoInitialized) {
        [self initializeLogo];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(self.selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];
        self.selectedIndexPath = nil;
    }
}

- (void)alertWithTitle:(NSString *)title message:(NSString *)message
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate showAlertViewWithTitle:NSLocalizedString(title, nil) message:message buttonTitle:nil viewController:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == settingsContext) {
        numberOfIcons = [[NSUserDefaults standardUserDefaults] integerForKey:SETTINGS_KEY_NUMBER_OF_ICONS];
        [self requestUpdate];
    }
}

- (void)finishFirstLocatingIfDecided
{
    if(!self.logoInitialized) {
        [self initializeLogo];
    }
    if(firstLocatingStatus == FirstLocatingWait) {
        firstLocatingStatus = FirstLocatingTemporary;
    }
}

- (void)terminateFirstLocating
{
    if(firstLocatingStatus != FirstLocatingDone) {
        firstLocatingStatus = FirstLocatingDone;
        //[self.mapView.userLocation removeObserver:self forKeyPath:@"location"];
        [self setButtonsEnabled:YES];
        if (locatingEnabled) {
            self.mapView.showsUserLocation = YES;
            [self mapView:self.mapView regionDidChangeAnimated:NO];
        }
    }
}

- (void)beginLocating:(BOOL)enabled {
    if (enabled) {
        switch(firstLocatingStatus) {
            case FirstLocatingWait:
            case FirstLocatingTemporary:
                firstLocatingStatus = FirstLocatingTemporary;
                [self performSelector:@selector(terminateFirstLocating) withObject:nil afterDelay:FIRST_LOCATING_TERMINATE_DELAY];
                break;
            default:
                break;
        }
    } else {
        [self terminateFirstLocating];
    }
}

- (void)locationWasUpdated:(CLLocationCoordinate2D)location {
    switch(firstLocatingStatus) {
        case FirstLocatingWait:
        case FirstLocatingTemporary:
            [self setLocation:location setDelta:NO];
            locatingEnabled = YES;
            break;
        default:
            break;
    }
    [self terminateFirstLocating];
}

- (void)requestUpdateForce:(BOOL)force
{
    if(!queue) {
        return;
    }
    //[self performSelector:@selector(updateAnnotations) withObject:nil afterDelay:0];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    Database *database = appDelegate.database;
    [self.mapIndicator startAnimating];
    NSInteger numberOfIcons_ = numberOfIcons;
    dispatch_async(queue, ^ {
        MKCoordinateRegion region = self.recentRegion;
        NSMutableArray *newStations;
        do {
            newStations = [database stationsWithRegion:region limitCount:numberOfIcons_];
            if(!force) {
                MKCoordinateRegion recent = self.recentRegion;
                if(memcmp(&region, &recent, sizeof(MKCoordinateRegion))) {
                    region = recent;
                    continue;
                }
            }
        } while(NO);
        [self performSelectorOnMainThread:@selector(updateAnnotations:) withObject:newStations waitUntilDone:NO];
    });
}

- (void)mapView:(MKMapView *)mapView_ regionDidChangeAnimated:(BOOL)animated
{
    if(firstLocatingStatus == FirstLocatingDone) {
        MKCoordinateRegion recent = self.recentRegion;
        MKCoordinateRegion region = mapView_.region;
        if(memcmp(&region, &recent, sizeof(MKCoordinateRegion))) {
            self.recentRegion = region;
            [self requestUpdateForce:NO];
        }
    }
}

- (void)requestUpdate
{
    [self requestUpdateForce:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView_ viewForAnnotation:(id<MKAnnotation>)annotation
{
    if([annotation isKindOfClass:[Station class]]) {
        Station *station = (Station *)annotation;
        AnnotationView *annotationView = [AnnotationView annotationViewWithStation:station mapView:mapView_];
        return annotationView;
    } else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView_ didSelectAnnotationView:(MKAnnotationView *)view
{
    annotationWasTappedRecently = YES;
    if(self.reservedStationCode) {
        self.reservedStationCode = nil;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(selectStation) object:nil];
    }
}


- (void)mapView:(MKMapView *)mapView_ annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    annotationWasTappedRecently = YES;
    if([view.annotation isKindOfClass:[Station class]]) {
        [self showStationInformationWithStation:(Station *)view.annotation];
    }
}

- (void)mapView:(MKMapView *)mapView_ didAddAnnotationViews:(NSArray *)views
{
    for(MKAnnotationView *annotationView in views) {
        id<MKAnnotation> annotation = annotationView.annotation;
        if([annotation isKindOfClass:[Station class]]) {
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    annotationWasTappedRecently = YES;
}


#pragma mark - Table view data source

- (void)refleshStationsForList
{
    if(!self.stationsForList) {
        NSArray *results = [self.stations allValues];
        for(Station *station in results) {
            station.centerCoordinate = self.mapView.centerCoordinate;
        }
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES]];
        self.stationsForList = [results sortedArrayUsingDescriptors:sortDescriptors];
    }    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    [self refleshStationsForList];
    return [self.stationsForList count];
}

- (UITableViewCell *)tableViewCell
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupsCell"];
    if(!self.cell) {
        [[NSBundle mainBundle] loadNibNamed:@"MapTableViewCell" owner:self options:nil];
        cell = self.cell;
        self.cell = nil;
    }
    return cell;
}
- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self refleshStationsForList];

    Station *station = [self.stationsForList objectAtIndex:indexPath.row];

    UITableViewCell *cell = [self tableViewCell];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    imageView.image = [UIImage imageNamed:station.statusIconName];
    ((UILabel *)[cell viewWithTag:2]).text = station.name;
    ((UILabel *)[cell viewWithTag:3]).text = station.operator.name;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Station *station = [self.stationsForList objectAtIndex:indexPath.row];
    self.selectedIndexPath = indexPath;
    [self showStationInformationWithStation:station];
}


- (void)selectStation
{
    if(self.reservedStationCode) {
        Station *currentStation = [self.stations objectForKey:self.reservedStationCode];
        if(currentStation && [self.mapView viewForAnnotation:currentStation]) {
            self.reservedStationCode = nil;
            [self.mapView selectAnnotation:currentStation animated:YES];
            return;
        }
    }
    [self performSelector:@selector(selectStation) withObject:nil afterDelay:ANNOTATION_UPDATE_DELAY];
}

- (void)moveToStation:(Station *)station
{
    self.mapView.centerCoordinate = station.coordinate;
    self.reservedStationCode = station.code;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(selectStation) object:nil];
    [self selectStation];
}

//- (void)databaseWasUpdatedWithStation:(Station *)station
- (void)databaseWasUpdatedWithNotification:(NSNotification *)notification
{
    Station *station = [notification object];
    if(station) {
        BOOL add, readd;
        switch(self.visibilitySegmentedControl.selectedSegmentIndex) {
            case VisibilityCompletedStations:
                add = readd = station.completionDate;
                break;
            case VisibilityIncompletedStations:
                add = readd = !station.completionDate;
                break;
            default:
                add = NO;
                readd = YES;
        }
        Station *currentStation = [self.stations objectForKey:station.code];
        NSInteger recentCompletionDate = currentStation.completionDate;
        if(currentStation) {
            if(currentStation != station) {
                currentStation.completionDate = station.completionDate;
                currentStation.memo = station.memo;
                currentStation.updatedDate = station.updatedDate;
            }
            if(currentStation == station || !recentCompletionDate != !station.completionDate) {
                BOOL selected = [[self.mapView selectedAnnotations] containsObject:currentStation];
                [self.mapView removeAnnotation:currentStation];
                if(readd) {
                   [self.mapView addAnnotation:currentStation];
                   if(selected) {
                       [self.mapView selectAnnotation:currentStation animated:NO];
                   }
                }
            }
        } else if(add) {
            [self.stations setObject:station forKey:station.code];
            [self.mapView addAnnotation:station];
        }
        [self.tableView reloadData];
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.mapView removeAnnotations:[self.stations allValues]]; 
        self.stations = nil;
        [self requestUpdate];
    }
}

- (void)updateAnnotations:(NSMutableArray *)newStations
{
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAnnotations) object:nil];

    NSMutableDictionary *newStationsDictionary = [NSMutableDictionary dictionaryWithCapacity:numberOfIcons];
    NSMutableArray *appendStations = [NSMutableArray arrayWithCapacity:numberOfIcons];

    //NSLog(@"before:%d", [self.stations count]);
    //for(Station *station in [delegate.database stationsWithRegion:mapView.region limitCount:numberOfIcons]) {
    for(Station *station in newStations) {
        Station *st = [self.stations objectForKey:station.code];
        if(st) {
            [self.stations removeObjectForKey:station.code];
            [newStationsDictionary setObject:st forKey:station.code];
        } else {
            [appendStations addObject:station];
            [newStationsDictionary setObject:station forKey:station.code];
        }
    }
    //NSLog(@"after:remove:%d/add:%d", [self.stations count], [appendStations count]);

    if([appendStations count] || [self.stations count]) {
        [self.mapView removeAnnotations:[self.stations allValues]];
        [self.mapView addAnnotations:appendStations];
    }
    self.stations = newStationsDictionary;

    //NSLog(@"total:%d", [mapView.annotations count]);

    self.stationsForList = nil;
    // 常に呼び出さないとリストの更新中に通知が来たときに矛盾が起こる
    [self.tableView reloadData];
    if(!self.listView.hidden) {
        [self.tableView flashScrollIndicators];
    }
    [self.mapIndicator stopAnimating];
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView_
{
    if(firstLocatingStatus == FirstLocatingDone) {
        [self mapView:mapView_ regionDidChangeAnimated:YES];
    }
}

- (void)mapViewWasSingleTapped:(MapView *)mapView
{
    [self performSelector:@selector(toggleBars) withObject:nil afterDelay:SINGLE_TAP_DELAY];
}

- (void)showHideBars:(BOOL)show animated:(BOOL)animated
{
    isShowBars = show;
    [self.navigationController setNavigationBarHidden:!show animated:animated];
    if (IS_IPHONE_X_TAB_BUG) {
        if (show) {
            self.myToolbar.hidden = NO;
            if (animated) {
                CGRect frame = self.myToolbar.frame;
                frame.origin.y += frame.size.height;
                self.myToolbar.frame = frame;
                frame.origin.y -= frame.size.height;
                [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                    self.myToolbar.frame = frame;
                }];
            }
        } else {
            if (animated) {
                CGRect origFrame = self.myToolbar.frame;
                CGRect frame = origFrame;
                frame.origin.y += frame.size.height;
                [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                    self.myToolbar.frame = frame;
                } completion:^(BOOL finished) {
                    self.myToolbar.frame = origFrame;
                    self.myToolbar.hidden = YES;
                }];
            } else {
                self.myToolbar.hidden = YES;
            }
        }
    } else {
        [self.navigationController setToolbarHidden:!show animated:animated];
    }
}


- (void)setButtonsEnabled:(BOOL)enabled
{
    enabled = enabled && self.mapWrapper.hidden;
    self.presentButton.enabled = enabled && locatingEnabled;
    self.visibilitySegmentedControl.enabled = enabled;
    self.mapStyleModeSegmentedControl.enabled = enabled;
}



- (void)present
{
    if(self.presentButton.enabled) {
        [self setLocation:[self.mapView.userLocation.location coordinate] setDelta:NO];    
    }
}

- (void)swapMapAndList
{
    BOOL inListMode = self.mapView.hidden;
    UIView *visibleView = inListMode ? self.mapView : self.listView;
    UIView *invisibleView = inListMode ? self.listView : self.mapView;
    visibleView.alpha = 0;
    visibleView.hidden = NO;
    self.mapStyleModeSegmentedControl.enabled = NO;
    if(!inListMode) {
        [self.tableView reloadData];
        [self showHideBars:YES animated:YES];
    }
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^(void) {
                         visibleView.alpha = 1;
                         invisibleView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         invisibleView.hidden = YES;
                         self.mapStyleModeSegmentedControl.enabled = YES;
                         if(!inListMode) {
                             [self.tableView flashScrollIndicators];
                         }
                     }];
    
}

- (void)mapStyleModeWantsToChange
{
    if(!self.mapStyleModeSegmentedControl.enabled) {
        return;
    }
    BOOL listMode = NO;
    switch(self.mapStyleModeSegmentedControl.selectedSegmentIndex) {
        case MapStyleSattelite:
            self.mapView.mapType = MKMapTypeSatellite;
            self.title = mapStyleModeTitle[MapStyleSattelite];
            break;
        case MapStyleHybrid:
            self.mapView.mapType = MKMapTypeHybrid;
            self.title = mapStyleModeTitle[MapStyleHybrid];
            break;
        case MapStyleList:
            listMode = YES;
            self.title = mapStyleModeTitle[MapStyleList];
            break;
        default:
            self.mapView.mapType = MKMapTypeStandard;
            self.title = mapStyleModeTitle[MapStyleMap];
            break;
    }
    if(listMode == self.listView.hidden) {
        [self swapMapAndList];
    }
}

- (void)placeSelectViewController:(PlaceSelectViewController *)placeSelectViewController_ didSelected:(GoogleMapsLocation *)place atIndex:(NSInteger)index
{
    if(place) {
        self.mapView.centerCoordinate = place.coordinate;
    }
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)GoogleMapsServiceDidFinish:(GoogleMapsService *)service
{
    self.loadingView.hidden = YES;
    if(service.errorMessage) {
        [self alertWithTitle:@"検索エラー" message:NSLocalizedString(service.errorMessage, nil)];
    } else if([service.locations count] > 1) {
        PlaceSelectViewController *placeSelectViewController = [[PlaceSelectViewController alloc] initWithPlaceCandidates:service.locations delegate:self];
        [self presentPopupViewController:placeSelectViewController animationType:MJPopupViewAnimationFade];
    } else {
        self.mapView.centerCoordinate = ((GoogleMapsLocation *)[service.locations objectAtIndex:0]).coordinate;
    }
}

- (void)updateFilterWithFilterType:(DatabaseFilterType)type filterValue:(NSString *)value
{
    self.recentFilterType = type;
    self.searchKeyword = value ? value : @"";
    [self setFormattedSearchText];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.database updateFilterWithFilterType:self.recentFilterType filterValue:self.searchKeyword];
}

- (void)doSearch
{
    if(![self.searchKeyword length]) {
        self.recentFilterType = DatabaseFilterTypeNone;
        [self.searchScopeBar setFilterType:DatabaseFilterTypeNone];
    } else if(self.recentFilterType == DatabaseFilterTypeNone) {
        if(!self.GMapService) {
            self.GMapService = [[GoogleMapsService alloc] initWithDelegate:self];
        }
        [self.GMapService geocodeInJapanWithAddress:self.searchKeyword];
        return;
    }
    self.loadingView.hidden = YES;
    [self updateFilterWithFilterType:self.recentFilterType filterValue:self.searchKeyword];
    [self requestUpdate];
    if(!self.tableView.hidden) {
        [self.tableView reloadData];
    }
}

- (void)setFormattedSearchText
{
    self.searchBar.text = [DatabaseFilterTypes formattedStringWithFilterType:self.recentFilterType searchKeyword:self.searchKeyword];
}

- (BOOL)beginEndSearchInput:(BOOL)beginning
{
    if(self.inAnimation || firstLocatingStatus != FirstLocatingDone) {
        return NO;
    }
    self.inAnimation = YES;
    
    if(beginning) {
        self.mustSearch = NO;
        [self setButtonsEnabled:NO];
        self.searchBar.text = self.searchKeyword;
        self.searchScopeBar.filterType = self.recentFilterType;
    }
    
    [self.mapWrapper prepareAnimationWithShowing:beginning];
    [self.searchScopeBar prepareAnimationWithShowing:beginning];
	
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^{
                         [self.mapWrapper setAnimationWithShowing:beginning];
                         [self.searchScopeBar setAnimationWithShowing:beginning];
					 }
                     completion:^(BOOL finished){
                         self.inAnimation = NO;
                         [self.mapWrapper finishAnimationWithShowing:beginning];
                         [self.searchScopeBar finishAnimationWithShowing:beginning];
                         if(!beginning) {
                             [self setButtonsEnabled:YES];
                             if(self.mustSearch) {
                                 self.recentFilterType = self.searchScopeBar.filterType;
                                 self.searchKeyword = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                 self.loadingView.hidden = NO;
                                 [self setFormattedSearchText];
                                 [self performSelector:@selector(doSearch) withObject:nil afterDelay:0];
                             } else {
                                 [self setFormattedSearchText];
                             }
                         }
					 }
	 ];
    return YES;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return [self beginEndSearchInput:YES];
}

//検索文字列入力が終了する
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    [self beginEndSearchInput:NO];
    return YES;
}

//検索文字列入力時に「検索」ボタンがタップされる
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
{
    if(firstLocatingStatus == FirstLocatingDone && !self.inAnimation) {
        [searchBar_ endEditing:YES];
        self.mustSearch = YES;
    }
}


- (void)mapWrapperWasTouched:(MapWrapper *)mapWrapper
{
    if(!self.inAnimation) {
        if ([self.searchBar.text length] || ![self.searchKeyword length]) {
            self.searchBar.text = self.searchKeyword;
            self.mustSearch = NO;
        } else {
            self.mustSearch = YES;
        }
        [self.searchBar endEditing:NO];
    } 
}

- (void)visibilityWantsToChange
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.database updateVisibilityType:(VisibilityType)self.visibilitySegmentedControl.selectedSegmentIndex];
    //[self updateAnnotations];
    //if(!self.tableView.hidden) {
        //[self.tableView reloadData];
    //}
    [self requestUpdate];
}

- (void)toggleBars
{
    if(annotationWasTappedRecently) {
        annotationWasTappedRecently = NO;
    } else {
        [self showHideBars:self.navigationController.navigationBarHidden animated:YES];
    }    
}

- (void)setLocation:(CLLocationCoordinate2D)coordinate setDelta:(BOOL)setDelta
{
    MKCoordinateRegion zoom = mapView.region;
    if(coordinate.latitude < JAPAN_MIN_LATITUDE || JAPAN_MAX_LATITUDE < coordinate.latitude || coordinate.longitude < JAPAN_MIN_LONGITUDE || JAPAN_MAX_LONGITUDE < coordinate.longitude) {
        coordinate.latitude = JAPAN_HESO_LATITUDE;
        coordinate.longitude = JAPAN_HESO_LONGITUDE;
    }
   zoom.center = coordinate;
    if(setDelta) {
        zoom.span.latitudeDelta = INITIAL_REGION_DELTA;
        zoom.span.longitudeDelta = INITIAL_REGION_DELTA;
    }
    [mapView setRegion:zoom animated:YES];    
}


- (void)showStationInformationWithStation:(Station *)station
{
    StationInformationViewController *viewController = [[StationInformationViewController alloc] initWithStation:station];
    [self.navigationController pushViewController:viewController animated:YES];
}


@end
