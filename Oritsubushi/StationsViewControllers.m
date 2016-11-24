//
//  StationsViewControllers.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/02.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "StationsViewControllers.h"
#import "Station.h"
#import "Group.h"
#import "CompletionDateGroup.h"
#import "StationInformationViewController.h"

//完全に扱いが変わる
//self.groups_にはStation *の配列

@implementation StationsViewControllerBase

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    StationInformationViewController *childViewController = [[StationInformationViewController alloc] initWithStation:[self.groups objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:childViewController animated:YES];
    self.selectedIndexPath = indexPath;
}

- (void)checkDirtyWithStation:(Station *)station
{
    for(Station *station_ in self.groups) {
        if([station_.code isEqualToNumber:station.code]) {
            headerGroupIsDirty = groupsAreDirty = YES;
            return;
        }
    }
}

@end

@implementation StationsViewController

@synthesize cell = cell_;

- (id)initWithHeaderGroup:(Group *)headerGroup
{
    self = [super initWithHeaderGroup:headerGroup];
    if(self) {
        [self setMapFilterButtonWithFilterType:DatabaseFilterTypeLineForward word:headerGroup.title];
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableViewCell];
    Station *station = [self.groups objectAtIndex:indexPath.row];
    [self setTableViewCell:cell withTitle:station.name description:station.completionDateString statusIconName:station.statusIconName];
    return cell;
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.database reloadLineGroup:self.headerGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database stationsWithLineCode:self.headerGroup.code];
    [super reloadGroups];
}


@end

@implementation PrefStationsViewController

- (id)initWithHeaderGroup:(Group *)headerGroup
{
    self = [super initWithHeaderGroup:headerGroup];
    if(self) {
        [self setMapFilterButtonWithFilterType:DatabaseFilterTypePref word:headerGroup.title];
    }
    return self;
}

//20120120
- (void)checkDirtyWithStation:(Station *)station
{
    if(station.pref == [self.headerGroup.code intValue]) {
        headerGroupIsDirty = groupsAreDirty = YES;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableViewCell];
    Station *station = [self.groups objectAtIndex:indexPath.row];
    [self setTableViewCell:cell withTitle:station.name description:[NSString stringWithFormat:@"%@ : %@", station.completionDateShortString, station.address] statusIconName:station.statusIconName];    
    return cell;
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.database reloadPrefGroup:self.headerGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database stationsWithPref:[self.headerGroup.code intValue]];
    [super reloadGroups];
}

@end

@implementation YomiStationsViewController

- (id)initWithHeaderGroup:(Group *)headerGroup
{
    self = [super initWithHeaderGroup:headerGroup];
    if(self) {
        [self setMapFilterButtonWithFilterType:DatabaseFilterTypeYomiForward word:headerGroup.title];
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableViewCell];
    Station *station = [self.groups objectAtIndex:indexPath.row];
    [self setTableViewCell:cell
                 withTitle:station.name
               description:[NSString stringWithFormat:@"%@ : %@ / %@",
                            station.completionDateShortString,
                            station.yomi,
                            station.operator.name]
            statusIconName:station.statusIconName];    
    return cell;
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.database reloadYomiGroup:self.headerGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database stationsWithYomiPrefix:self.headerGroup.title];
    [super reloadGroups];
}

@end

@implementation CompletionDateStationsViewController

- (id)initWithHeaderGroup:(Group *)headerGroup
{
    self = [super initWithHeaderGroup:headerGroup];
    if(self) {
        if([headerGroup.code integerValue] >= 0) {
            [self setMapFilterButtonWithFilterType:DatabaseFilterTypeDate word:((CompletionDateGroup *)headerGroup).title];
        }
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableViewCell];
    Station *station = [self.groups objectAtIndex:indexPath.row];
    [self setTableViewCell:cell withTitle:station.name description:[NSString stringWithFormat:@"%@ / %@", station.operator.name, station.address] statusIconName:station.statusIconName];
    return cell;
}

- (void)reloadHeaderGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.database reloadCompletionDateGroup:self.headerGroup];
    [super reloadHeaderGroup];
}

- (void)reloadGroups
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.groups = [appDelegate.database stationsWithCompletionDate:self.headerGroup.code];
    [super reloadGroups];
}

@end
