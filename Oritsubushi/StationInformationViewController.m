//
//  StationInformationViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/29.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "StationInformationViewController.h"
#import "Line.h"
#import "Station.h"
#import "Prefs.h"
#import "Misc.h"
#import "Consts.h"
#import "MemoViewController.h"
#import "CompletionViewController.h"

@interface StationInformationViewController ()

@property(nonatomic) BOOL recentCompletion;
@property(nonatomic,strong) Station *station_;
@property(nonatomic,strong) UITableViewCell *completionCell;
@property(nonatomic,strong) UITableViewCell *memoCell;
@property(nonatomic,strong) NSIndexPath *selectedIndexPath;

- (void)updateCompletion;

@end

@implementation StationInformationViewController

@synthesize recentCompletion;
@synthesize titleView;
@synthesize updatedDateLabel;
@synthesize station_;
@synthesize completionCell, memoCell;
@synthesize selectedIndexPath;

- (id)initWithStation:(Station *)station
{
    self = [super initWithNibName:@"StationInformationViewController" bundle:nil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"駅情報", nil);
        self.station = station;
        self.recentCompletion = station.isCompleted;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.completionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    self.completionCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.completionCell.textLabel.text = NSLocalizedString(@"乗下車", nil);

    self.memoCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    self.memoCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.memoCell.textLabel.text = NSLocalizedString(@"メモ", nil);

    //自前管理する
    self.clearsSelectionOnViewWillAppear = NO;
    /*NSLog(@"%d:%p:%ld", __LINE__, (__bridge void*)self, CFGetRetainCount((__bridge void*)self));
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate addDatabaseUpdateNotificationObserver:self];
    NSLog(@"%d:%p:%ld", __LINE__, (__bridge void*)self, CFGetRetainCount((__bridge void*)self));*/
    [Database addObserver:self];
}

- (void)viewDidUnload
{
    /*NSLog(@"%d:%p:%ld", __LINE__, (__bridge void*)self, CFGetRetainCount((__bridge void*)self));
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate removeDatabaseUpdateNotificationObserver:self];
    NSLog(@"%d:%p:%ld", __LINE__, (__bridge void*)self, CFGetRetainCount((__bridge void*)self));*/
    //[Database removeObserver:self];
    [super viewDidUnload];
//    NSLog(@"%d:%p:%ld", __LINE__, (__bridge void*)self, CFGetRetainCount((__bridge void*)self));
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.titleView = nil;
    self.memoCell = nil;
    self.updatedDateLabel = nil;
    self.selectedIndexPath = nil;
}

- (void)dealloc
{
//    NSLog(@"%d:%p:%ld", __LINE__, (__bridge void*)self, CFGetRetainCount((__bridge void*)self));
    [Database removeObserver:self];
    self.titleView = nil;
    self.updatedDateLabel = nil;
    self.memoCell = nil;
    self.selectedIndexPath = nil;
    self.station = nil;
    self.completionCell = nil;    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    self.completionCell.detailTextLabel.text = self.station.completionDateString;
    self.memoCell.detailTextLabel.text = [self.station.memo stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    if(self.selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:animated];
        self.selectedIndexPath = nil;
    }
    [self updateUpdatedDate];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case 0:
            return 2;
        case 1:
            return self.station.isCompleted ? 2 : 3;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case 0:
        case 2:
            return @"";
        default:
            return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case 0:
            return self.titleView.frame.size.height;
        case 2:
            return self.updatedDateLabel.frame.size.height;
        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case 0:
        {
            Station *station = self.station_;
            ((UIImageView *)[self.titleView viewWithTag:1]).image = [UIImage imageNamed:(station.isCompleted ? @"statusicon_comp" : @"statusicon_incomp")];
            ((UILabel *)[self.titleView viewWithTag:2]).text = station.name;
            ((UILabel *)[self.titleView viewWithTag:3]).text = station.yomi;
            NSMutableString *str = [NSMutableString stringWithFormat:@"%@ ", station.operator.name];
            for(Line *line in station.lines) {
                [str appendFormat:@"%@, ", line.name];
            }
            ((UILabel *)[self.titleView viewWithTag:4]).text = [str substringToIndex:([str length] - 2)];
            ((UILabel *)[self.titleView viewWithTag:5]).text = [NSString stringWithFormat:@"%@%@", [Prefs stringWithType:station.pref], station.address];
            return self.titleView;
        }
        case 2:
            return self.updatedDateLabel;
        default:
            return nil;
    }
}

- (UITableViewCell *)genericCell
{
    static NSString *CellIdentifier = @"StationInformationCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    NSInteger row = indexPath.row;
    switch(indexPath.section) {
        case 0:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch(row) {
                case 0:
                    return self.completionCell;
                case 1:
                    return self.memoCell;
            }
            break;
        case 1:
            cell = [self genericCell];
            cell.accessoryType = UITableViewCellAccessoryNone;
            if(self.station.isCompleted) {
                ++row;
            }
            switch(row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"今日、乗下車しました！", nil);
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"この駅をウィキペディアで見る…", nil);
                    break;
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"この駅を地図の中心に表示…", nil);
                    break;
            }
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    BOOL deselect = NO;
    switch(indexPath.section) {
        case 0:
            switch(row) {
                case 0:
                {
                    CompletionViewController *viewController = [[CompletionViewController alloc] initWithStation:self.station];
                    [self.navigationController pushViewController:viewController animated:YES];
                    break;
                }
                case 1:
                {
                    MemoViewController *viewController = [[MemoViewController alloc] initWithStation:self.station];
                    [self.navigationController pushViewController:viewController animated:YES];
                    break;
                }
            }
            break;
        case 1:
            if(self.station.isCompleted) {
                ++row;
            }
            switch(row) {
                case 0:
                    [self updateCompletion];
                    deselect = YES;
                    break;
                case 1:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://ja.m.wikipedia.org/wiki/%@", [Misc URLEncode:self.station.wiki]]]];
                    deselect = YES;
                    break;
                case 2:
                    [((AppDelegate *)[UIApplication sharedApplication].delegate) mapViewMoveToStation:self.station];
                    deselect = YES;
                    break;
            }
    }
    if(deselect) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        self.selectedIndexPath = indexPath;
    }
}

- (void)reloadData
{
    self.completionCell.detailTextLabel.text = self.station.completionDateString;
    [self.tableView reloadData];
    [self updateUpdatedDate];
    if(self.selectedIndexPath) {
        [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:0];
    }
}

- (void)updateUpdatedDate
{
    self.updatedDateLabel.text = self.station ? self.station.updatedDateString : @"";
}

//- (void)databaseWasUpdatedWithStation:(Station *)station
- (void)databaseWasUpdatedWithNotification:(NSNotification *)notification
{
    Station *station = [notification object];
    if(station && [station.code intValue] == [self.station.code intValue]) {
        self.station.completionDate = station.completionDate;
        self.station.memo = station.memo;
        self.station.updatedDate = station.updatedDate;
        [self reloadData];
    }
}

- (void)updateCompletion
{
    self.station.completionDate = [Misc today];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.database updateCompletion:self.station];
//    [self performSelector:@selector(reloadData) withObject:nil afterDelay:ANIMATION_DURATION];
}

- (Station *)station
{
    return self.station_;
}

- (void)setStation:(Station *)station
{
    self.station_ = station;
    //20111229
    if(station) {
        [self.tableView reloadData];
    }
}

@end
