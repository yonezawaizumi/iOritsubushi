//
//  PlaceViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/19.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "PlaceViewController.h"
#import "StationsViewControllers.h"
#import "Group.h"
#import "Station.h"

@implementation PlaceViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"都道府県", nil) image:[UIImage imageNamed:@"tabicon_place"] tag:0];
    }
    return self;
}

- (void)setHeaderTitle
{
    self.navigationItem.title = NSLocalizedString(@"全都道府県", nil);
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.headerGroup = [appDelegate.database allTotalGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database prefGroups];
    [super reloadGroups];
}

- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    return [[PrefStationsViewController alloc] initWithHeaderGroup:headerGroup];
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
