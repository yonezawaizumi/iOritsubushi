//
//  SettingsViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/23.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "SettingsViewController.h"
#import "NumberOfIconsViewController.h"
#import "Settings.h"
#import "AppDelegate.h"

@interface SettingsViewController ()

@property(nonatomic) NSInteger numberOfIcons;
@property(nonatomic,strong) UITableViewCell *numberOfIconsCell;

@end

@implementation SettingsViewController

@synthesize numberOfIcons;
@synthesize numberOfIconsCell;

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"設定", nil);
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"tabicon_settings"] tag:0];
        NSUserDefaults *userDefaluts = [NSUserDefaults standardUserDefaults];
        self.numberOfIcons = [userDefaluts integerForKey:SETTINGS_KEY_NUMBER_OF_ICONS];
    }
    return self;
}

- (void)dealloc
{
    self.numberOfIconsCell = nil;    
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
    self.numberOfIconsCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    self.numberOfIconsCell.textLabel.text = NSLocalizedString(@"ピンの数", nil);
    self.numberOfIconsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.numberOfIconsCell = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.numberOfIcons = [userDefaults integerForKey:SETTINGS_KEY_NUMBER_OF_ICONS];
    self.numberOfIconsCell.detailTextLabel.text = [NumberOfIconsViewController labelWithValue:self.numberOfIcons];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case 0:
            return NSLocalizedString(@"地図", nil);
        default:
            return nil;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case 0:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case 0:
            switch(indexPath.row) {
                case 0:
                    return self.numberOfIconsCell;
                default:
                    return nil;
            }
        default:
            return nil;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case 0:
            switch(indexPath.row) {
                case 0:
                {
                    NumberOfIconsViewController *viewController = [[NumberOfIconsViewController alloc] initWithStyle:UITableViewStylePlain];
                    viewController.numberOfIcons = self.numberOfIcons;
                    [self.navigationController pushViewController:viewController animated:YES];
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }
}


@end
