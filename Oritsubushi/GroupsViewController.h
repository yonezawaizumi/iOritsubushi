//
//  GroupsViewController.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/02.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadingView.h"
#import "AppDelegate.h"
#import "DatabaseFilterTypes.h"

@class Station;
@class Group;

@interface GroupsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, /*DatabaseUpdateNotificationProtocol*/DatabaseUpdateNotificationObserverProtocol> {
@protected
    BOOL headerGroupIsDirty;
    BOOL groupsAreDirty;
}

@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) Group *headerGroup;
@property(nonatomic,strong) NSArray *groups;
@property(nonatomic,strong) NSIndexPath *selectedIndexPath;
@property(nonatomic,strong) IBOutlet UITableViewCell *cell;
@property(nonatomic,assign,readonly,getter=isActive) BOOL active;
@property(nonatomic,assign,getter=isBusy) BOOL busy;

- (id)initWithHeaderGroup:(Group *)headerGroup;
- (void)setHeaderTitle;
- (void)checkDirtyWithStation:(Station *)station;
- (BOOL)needsReload;
- (void)reloadIfNeeded;
- (void)reloadHeaderGroup;
- (void)reloadGroups;
- (void)setMapFilterButtonWithFilterType:(DatabaseFilterType)filterType word:(NSString *)word;
- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup;

- (UITableViewCell *)tableViewCell;
- (void)setTableViewCell:(UITableViewCell *)cell withTitle:(NSString *)title description:(NSString *)description statusIconName:(NSString *)statusIconName;

@end
