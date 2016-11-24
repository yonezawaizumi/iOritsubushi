//
//  CompletionDateViewController.m
//  Oritsubushi
//
//  Created by よねざわいずみ on 12/10/03.
//  Copyright (c) 2012年 合資会社ダブルエスエフ. All rights reserved.
//

#import "CompletionDateViewController.h"
#import "StationsViewControllers.h"
#import "CompletionDateGroup.h"
#import "Station.h"
#import "Consts.h"

@implementation CompletionYearViewController


- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"乗下車日", nil) image:[UIImage imageNamed:@"tabicon_date"] tag:0];
    }
    return self;
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.headerGroup = [appDelegate.database allTotalGroup];
    self.headerGroup.title = NSLocalizedString(@"乗下車年別", nil);
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database completionYearGroups];
    [super reloadGroups];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableViewCell];
    Group *group = [self.groups objectAtIndex:indexPath.row];
    [self setTableViewCell:cell
                 withTitle:group.title
               description:group.description
            statusIconName:[Station statusIconNameWithCompleted:[group.code integerValue] >= 0]];
    return cell;
}

- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    if([headerGroup.code intValue] > 0) {
        return [[CompletionMonthViewController alloc] initWithHeaderGroup:headerGroup];
    } else {
        return [[CompletionDateStationsViewController alloc] initWithHeaderGroup:headerGroup];
    }
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

@implementation CompletionMonthViewController

- (id)initWithHeaderGroup:(Group *)headerGroup
{
    self = [super initWithHeaderGroup:headerGroup];
    if(self) {
        [self setMapFilterButtonWithFilterType:DatabaseFilterTypeDate word:headerGroup.title];
    }
    return self;
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.database reloadCompletionYearGroup:self.headerGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database completionMonthGroupsWithYearGroup:self.headerGroup];
    [super reloadGroups];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableViewCell];
    CompletionDateGroup *group = [self.groups objectAtIndex:indexPath.row];
    [self setTableViewCell:cell
                 withTitle:group.cellTitle
               description:group.description
            statusIconName:[Station statusIconNameWithCompleted:YES]];
    return cell;
}

- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    if([headerGroup.code intValue] % 100) {
        return [[CompletionDateViewController alloc] initWithHeaderGroup:headerGroup];
    } else {
        return [[CompletionDateStationsViewController alloc] initWithHeaderGroup:headerGroup];
    }
}

//- (void)databaseWasUpdatedWithStation:(Station *)station
- (void)databaseWasUpdatedWithNotification:(NSNotification *)notification
{
    Station *station = [notification object];
    //if(station) {
        //[super databaseWasUpdatedWithStation:station];
        //[super databaseWasUpdatedWithNotification:notification];
    //} else if(self.isActive) {
    if(station || self.isActive) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self reloadHeaderGroup];
        [self reloadGroups];
        headerGroupIsDirty = groupsAreDirty = NO;
    } else {
        headerGroupIsDirty = groupsAreDirty = YES;
    }
}


@end

@implementation CompletionDateViewController

- (id)initWithHeaderGroup:(Group *)headerGroup
{
    self = [super initWithHeaderGroup:headerGroup];
    if(self) {
        [self setMapFilterButtonWithFilterType:DatabaseFilterTypeDate word:headerGroup.title];
    }
    return self;
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.database reloadCompletionMonthGroup:self.headerGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database completionDateGroupsWithMonthGroup:self.headerGroup];
    [super reloadGroups];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableViewCell];
    CompletionDateGroup *group = [self.groups objectAtIndex:indexPath.row];
    [self setTableViewCell:cell
                 withTitle:group.cellTitle
               description:group.description
            statusIconName:[Station statusIconNameWithCompleted:YES]];
    return cell;
}

- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    return [[CompletionDateStationsViewController alloc] initWithHeaderGroup:headerGroup];
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

