//
//  PlaceSelectViewController.m
//  Oritsubushi
//
//  Created by yonezawaizumi on 2013/09/17.
//  Copyright (c) 2013年 合資会社ダブルエスエフ. All rights reserved.
//

#import "PlaceSelectViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Consts.h"

enum {
    PlaceSelectViewControllerIndexCancelled = -1,
    PlaceSelectViewControllerIndexKilled = -2
} PlaceSelectViewControllerIndex;

@interface PlaceSelectViewController ()

@property(nonatomic,strong) NSArray *placeCandidates;

@end

@implementation PlaceSelectViewController

@synthesize placeCandidates;
@synthesize selectDelegate = selectDelegate_;
@synthesize locationsTableView;
@synthesize bottomSeparator;

- (id)initWithPlaceCandidates:(NSArray *)candidates delegate:(id<PlaceSelectViewControllerDelegate>)selectDelegate
{
    self = [super initWithNibName:@"PlaceSelectViewController" bundle:nil];
    if (self) {
        self.locationsTableView.rowHeight = PLACE_SELECT_ROW_HEIGHT;

        self.placeCandidates = candidates;
        self.selectDelegate = selectDelegate;

        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.view.layer setCornerRadius:5.0f];
    [self.view setClipsToBounds:YES];

    // iOS8から self.locationTableView.rowHeightが0になってしまう？ のでやむなく即値
    CGFloat margin = self.locationsTableView.frame.size.height - 44 * self.placeCandidates.count;
    if(margin > 0) {
        CGRect frame = self.view.frame;
        frame.size.height -= margin;
        self.view.frame = frame;
    }
    //BK: IBで高さ0.5を指定しても、移動で1に勝手に変更されてしまうので再設定というあたまわるさ…
    CGRect frame = self.bottomSeparator.frame;
    frame.size.height = 0.5;
    self.bottomSeparator.frame = frame;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(self.locationsTableView.frame.size.height < self.locationsTableView.contentSize.height) {
        [self.locationsTableView flashScrollIndicators];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    self.placeCandidates = nil;
    self.selectDelegate = nil;
    self.locationsTableView = nil;
    self.bottomSeparator = nil;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self.selectDelegate placeSelectViewController:self didSelected:nil atIndex:PlaceSelectViewControllerIndexKilled];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.placeCandidates.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlaceSelectViewController";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = ((GoogleMapsLocation *)[self.placeCandidates objectAtIndex:indexPath.row]).address;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectDelegate placeSelectViewController:self didSelected:[self.placeCandidates objectAtIndex:indexPath.row] atIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
}

- (void)cancel:(id)sender
{
    [self.selectDelegate placeSelectViewController:self didSelected:nil atIndex:PlaceSelectViewControllerIndexCancelled];
}

@end
