//
//  NumberOfIconsViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/23.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "NumberOfIconsViewController.h"
#import "Consts.h"
#import "Settings.h"
#import "Misc.h"
#import "AppDelegate.h"

static int selectionList[] = NUMBER_OF_ICONS_LIST;

@interface NumberOfIconsViewController ()

@property(nonatomic) NSInteger selectedRow;

@end

@implementation NumberOfIconsViewController

@synthesize numberOfIcons = numberOfIcons_;
@synthesize selectedRow;

+ (NSString *)labelWithValue:(NSInteger)value
{
    return value > 0 ? [NSString stringWithFormat:NSLocalizedString(@"%d個以内", nil), value] : NSLocalizedString(@"無制限(危険!)", nil);
}


- (id)initWithNumberOfIcons:(NSInteger)numberOfIcons
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        self.numberOfIcons = numberOfIcons;
        self.selectedRow = -1;
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

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:self.numberOfIcons] forKey:SETTINGS_KEY_NUMBER_OF_ICONS];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return countof(selectionList);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NumberOfIconsCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [self.class labelWithValue:selectionList[indexPath.row]];
    if(self.numberOfIcons == selectionList[indexPath.row]) {
        self.selectedRow = indexPath.row;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(selectedRow != indexPath.row) {
        self.numberOfIcons = selectionList[indexPath.row];
        [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        if(selectedRow >= 0) {
            [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:0]].accessoryType = UITableViewCellAccessoryNone;
        }
        selectedRow = indexPath.row;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
