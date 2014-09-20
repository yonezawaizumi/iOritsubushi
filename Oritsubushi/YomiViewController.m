//
//  YomiViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/19.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "YomiViewController.h"
#import "StationsViewControllers.h"
#import "Station.h"
#import "Group.h"

@implementation YomiViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"読み", nil) image:[UIImage imageNamed:@"tabicon_yomi"] tag:0];
    }
    return self;
}

- (void)setHeaderTitle
{
    self.navigationItem.title = @"読み";
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.headerGroup = [appDelegate.database allTotalGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database yomiGroups];
    [super reloadGroups];
}

- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    return [[Yomi2ViewController alloc] initWithHeaderGroup:headerGroup];
}

//- (void)databaseWasUpdatedWithStation:(Station *)station
- (void)databaseWasUpdatedWithNotification:(NSNotification *)notification
{
    Station *station = [notification object];
    if(station) {
        //[super databaseWasUpdatedWithStation:station];
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

@implementation Yomi2ViewController

- (id)initWithHeaderGroup:(Group *)headerGroup
{
    self = [super initWithHeaderGroup:headerGroup];
    if(self) {
        [self setMapFilterButtonWithFilterType:DatabaseFilterTypeYomiForward word:headerGroup.title];
    }
    return self;
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.database reloadYomiGroup:self.headerGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database yomiGroupsWithYomiGroup:self.headerGroup];
    [super reloadGroups];
}

- (void)checkDirtyWithStation:(Station *)station
{
    if([[station.yomi substringToIndex:1] isEqualToString:self.headerGroup.title]) {
        headerGroupIsDirty = groupsAreDirty = YES;
    }
}

- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    return [[YomiStationsViewController alloc] initWithHeaderGroup:headerGroup];
}

@end
