//
//  LinesViewControllers.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/02.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "LinesViewControllers.h"
#import "StationsViewControllers.h"
#import "Station.h"
#import "Group.h"
#import "OperatorTypes.h"

@implementation OperatorTypesViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"路線", nil) image:[UIImage imageNamed:@"tabicon_operator"] tag:0];
    }
    return self;
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.headerGroup = [appDelegate.database allTotalGroup];
    [super reloadHeaderGroup];
}

- (void)setHeaderTitle
{
    self.navigationItem.title = NSLocalizedString(@"全事業者", nil);
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database operatorTypeGroups];
    [super reloadGroups];
}

- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    return [[OperatorsViewController alloc] initWithHeaderGroup:headerGroup];
}

//- (void)databaseWasUpdatedWithStation:(Station *)station
- (void)databaseWasUpdatedWithNotification:(NSNotification *)notification
{
    Station *station = [notification object];
    if(station) {
        [super databaseWasUpdatedWithNotification:notification];
    } else if(self.isActive) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self reloadHeaderGroup];
        [self reloadGroups];
        headerGroupIsDirty = groupsAreDirty = NO;
    } else {
        headerGroupIsDirty = groupsAreDirty = YES;
    }
}

@end

@interface OperatorsViewController () {
    dispatch_queue_t queue;
}

@property(assign) BOOL controllerIsEnabled;
@property(nonatomic,strong) NSString *cacheKey;

@end


@implementation OperatorsViewController

@synthesize controllerIsEnabled;
@synthesize cacheKey;

- (void)viewDidLoad
{
    self.controllerIsEnabled = YES;
    queue = dispatch_queue_create("com.wsf-lp.oritsubushi.update-operators-statistics", 0);
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    self.cacheKey = nil;
    self.controllerIsEnabled = NO;
    [super viewDidUnload];
    if(queue) {
        //dispatch_release(queue);
        queue = nil;
    }
}

- (void)dealloc
{
    self.cacheKey = nil;
    if(queue) {
        //dispatch_release(queue);
    }
}

- (void)reloadIfNeededDelayed
{
    [super reloadIfNeeded];
}

- (void)reloadIfNeeded
{
    self.cacheKey = [OperatorTypes heavyQueryKeyWithType:[self.headerGroup.code intValue]];
    [super reloadIfNeeded];
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.database reloadOperatorTypeGroup:self.headerGroup];
    [super reloadHeaderGroup];
}

- (void)updateGroups:(NSArray *)groups
{
    self.busy = NO;
    if(self.controllerIsEnabled) {
        self.groups = groups;
        [super reloadGroups];
    }
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    Database *database = appDelegate.database;
    self.groups = [database operatorGroupsNoStatisticsWithOperatorTypeGroup:self.headerGroup cacheKey:self.cacheKey];
    if(self.groups) {
        self.busy = YES;
        dispatch_async(queue, ^ {
            NSArray *groups = [database operatorGroupsWithOperatorTypeGroup:self.headerGroup cacheKey:self.cacheKey];
            [self performSelectorOnMainThread:@selector(updateGroups:) withObject:groups waitUntilDone:NO];
        });
    } else {
        self.groups = [database operatorGroupsWithOperatorTypeGroup:self.headerGroup cacheKey:cacheKey];
    }
    [super reloadGroups];
}

- (void)checkDirtyWithStation:(Station *)station
{
    NSInteger operatorCode = station.operatorCode;
    for(Group *group in self.groups) {
        if([group.code intValue] == operatorCode) {
            headerGroupIsDirty = groupsAreDirty = YES;
            return;
        }
    }
}

- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    return [[LinesViewController alloc] initWithHeaderGroup:headerGroup];
}

@end

@implementation LinesViewController

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.database reloadOperatorGroup:self.headerGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database lineGroupsWithOperatorGroup:self.headerGroup];
    [super reloadGroups];
}

- (void)checkDirtyWithStation:(Station *)station
{
    if(station.operatorCode == [self.headerGroup.code intValue]) {
        headerGroupIsDirty = groupsAreDirty = YES;
    }
}

- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    return [[StationsViewController alloc] initWithHeaderGroup:headerGroup];
}

@end
