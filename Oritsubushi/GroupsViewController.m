//
//  GroupsViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/02.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "GroupsViewController.h"
#import "Group.h"
#import "Consts.h"
#import "AppDelegate.h"

//#import "Prompt7View.h"

@interface GroupsViewController ()

@property(nonatomic,strong) NSString *promptText;
@property(nonatomic,strong) UILabel *prompt;
//@property(nonatomic,strong) Prompt7View *promptHolder;

@property(nonatomic,assign) DatabaseFilterType mapFilterType; 
@property(nonatomic,strong) NSString *mapFilterWord;
@property(nonatomic,strong) UIActivityIndicatorView *indicator;

@end

@implementation GroupsViewController

@synthesize promptText;
@synthesize tableView = tableView_;
@synthesize headerGroup = headerGroup_;
@synthesize groups = groups_;
@synthesize prompt;
@synthesize selectedIndexPath;
@synthesize mapFilterType, mapFilterWord;
@synthesize cell = cell_;
@synthesize indicator;
@synthesize active;

- (id)initWithHeaderGroup:(Group *)headerGroup
{
    self = [super init];
    if(self) {
        self.headerGroup = headerGroup;
        [self setHeaderTitle];
        self.promptText = headerGroup.description;
        [Database addObserver:self];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if(self) {
        [Database addObserver:self];
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

- (void)loadView
{
    [super loadView];
    // Custom initialization
    BOOL os7 = ((AppDelegate *)[UIApplication sharedApplication].delegate).osVersion >= 7;
    
    NSInteger promptHeight = PROMPT_HEIGHT;
    
    //20120919
    CGSize screenSize = [[UIScreen mainScreen] applicationFrame].size;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat tableY;
    CGFloat tableHeight;
    UIEdgeInsets insets;
    
    if(os7) {
        tableY = 0;
        tableHeight = screenSize.height + 24;
        //AD HOC!!!
        insets = UIEdgeInsetsMake(promptHeight, 0, -promptHeight / 2 - 6 + 24, 0);
    } else {
        tableY = promptHeight;
        tableHeight = screenSize.height - promptHeight - tabBarHeight - navBarHeight;
        insets = UIEdgeInsetsZero;
        self.prompt = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, promptHeight)];
        self.prompt.textAlignment = NSTextAlignmentCenter;
        self.prompt.font = PROMPT_FONT;
        self.prompt.textColor = PROMPT_TEXT_COLOR;
        self.prompt.backgroundColor = PROMPT_COLOR;
        [self.view addSubview:self.prompt];
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, tableY, screenSize.width, tableHeight) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = self.tableView.scrollIndicatorInsets = insets;
    [self.view addSubview:self.tableView];
    
    if(os7) {
        //self.promptHolder = [[Prompt7View alloc] initWithFrame:CGRectMake(0, navBarHeight + 20, screenSize.width, promptHeight) parent:self.tableView];
        //self.prompt = self.promptHolder.textLabel;
        self.prompt = [[UILabel alloc] initWithFrame:CGRectMake(0, navBarHeight + 20, screenSize.width, promptHeight)];
        self.prompt.textAlignment = NSTextAlignmentCenter;
        self.prompt.font = PROMPT_FONT;
        self.prompt.textColor = OS7_PROMPT_TEXT_COLOR;
        self.prompt.backgroundColor = OS7_PROMPT_COLOR_TEMP;
        //self.prompt.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        UIView *edge = [[UIView alloc] initWithFrame:CGRectMake(0, promptHeight - 0.5, screenSize.width, 0.5)];
        edge.backgroundColor = OS7_PROPMT_BOTTOM_EDGE_COLOR;
        [self.prompt addSubview:edge];
        //[self.view addSubview:self.promptHolder];
        [self.view addSubview:self.prompt];
    }
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.indicator.hidesWhenStopped = YES;
    [self.indicator stopAnimating];
    CGRect rect = self.indicator.frame;
    rect.origin.x = PROMPT_INDICATOR_MARGIN;
    rect.origin.y = (NSInteger)((promptHeight - rect.size.height) / 2);
    self.indicator.frame = rect;
    [self.prompt addSubview:self.indicator];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.prompt.text = self.promptText;
    active = YES;
}

- (void)viewDidUnload
{
    active = NO;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;    
    self.prompt = nil;
    //self.promptHolder = nil;
    self.tableView = nil;
    self.mapFilterWord = nil;
    self.indicator = nil;
}

- (void)dealloc
{
    [Database removeObserver:self];
    self.prompt = nil;
    //self.promptHolder = nil;
    self.tableView = nil;
    self.selectedIndexPath = nil;
    self.mapFilterWord = nil;
    self.headerGroup = nil;
    self.groups = nil;
    self.promptText = nil;
    self.indicator = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    BOOL os6 = ((AppDelegate *)[UIApplication sharedApplication].delegate).osVersion < 7;
    if(os6) {
        self.navigationController.navigationBar.translucent = NO;
        self.navigationController.toolbar.translucent = NO;
    } else {
        //[self.promptHolder blurWithColor:[BLRColorComponents defaultEffect] updateInterval:0.2f];
    }
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self.tableView flashScrollIndicators];
    [self reloadIfNeeded];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //[self.promptHolder pauseBlur];
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
    return [self.groups count];
}

- (UITableViewCell *)tableViewCell
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"GroupsCell"];
    if(!self.cell) {
        [[NSBundle mainBundle] loadNibNamed:@"GroupsCell" owner:self options:nil];
        cell = self.cell;
        self.cell = nil;
    }
    
    return cell;
}

- (void)setTableViewCell:(UITableViewCell *)cell withTitle:(NSString *)title description:(NSString *)description statusIconName:(NSString *)statusIconName
{
    ((UILabel *)[cell viewWithTag:2]).text = title;
    ((UILabel *)[cell viewWithTag:3]).text = description;
    //if(description) {
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
        imageView.hidden = NO;
        imageView.image = [UIImage imageNamed:statusIconName];
        //[((UIActivityIndicatorView *)[cell viewWithTag:10]) stopAnimating];
    //} else {
    //    [cell viewWithTag:1].hidden = YES;
        //[((UIActivityIndicatorView *)[cell viewWithTag:10]) startAnimating];        
    //}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableViewCell];
    Group *group = [self.groups objectAtIndex:indexPath.row];
    [self setTableViewCell:cell withTitle:group.title description:group.description statusIconName:group.statusIconName];
    return cell;
}

- (BOOL)isBusy
{
    return !self.indicator.hidden;
}

- (void)setBusy:(BOOL)busy
{
    if(busy) {
        [self.indicator startAnimating];
    } else {
        [self.indicator stopAnimating];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GroupsViewController *childViewController = [self childViewControllerWithHeaderGroup:[self.groups objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:childViewController animated:YES];
    self.selectedIndexPath = indexPath;
}

- (void)setMapFilter
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate mapViewUpdateFilterWithFilterType:self.mapFilterType filterValue:self.mapFilterWord];
    [appDelegate mapViewRequestUpdate];
}

- (void)setMapFilterButtonWithFilterType:(DatabaseFilterType)filterType word:(NSString *)word
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"地図選択", nil) style:UIBarButtonItemStylePlain target:self action:@selector(setMapFilter)];
    self.mapFilterType = filterType;
    self.mapFilterWord = word;
}

//- (void)databaseWasUpdatedWithStation:(Station *)station
- (void)databaseWasUpdatedWithNotification:(NSNotification *)notification
{
    Station *station = [notification object];
    if(station) {
        [self checkDirtyWithStation:station];
        if(self.navigationController.topViewController == self && self.navigationController.tabBarController.selectedViewController == self.navigationController) {
            [self reloadGroups];
        }
    }
}

- (void)setHeaderTitle
{
    self.navigationItem.title = self.headerGroup.headerTitle;
}

- (BOOL)needsReload
{
    return headerGroupIsDirty || !self.headerGroup || groupsAreDirty || !self.groups;
}

- (void)reloadIfNeeded
{
    if(headerGroupIsDirty || !self.headerGroup) {
        [self reloadHeaderGroup];
    }
    if(groupsAreDirty || !self.groups) {
        [self reloadGroups];
    }
    if(self.selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];
        self.selectedIndexPath = nil;
    }
    headerGroupIsDirty = groupsAreDirty = NO;
}

- (void)reloadHeaderGroup
{
    [self setHeaderTitle];
    self.prompt.text = self.promptText = self.headerGroup.description;
}

- (void)reloadGroups
{
    [self.tableView reloadData];
    if(self.selectedIndexPath) {
        [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:0];
    }
}

- (void)checkDirtyWithStation:(Station *)station
{
    headerGroupIsDirty = YES;
    groupsAreDirty = YES;
}

//ABSTRACT
- (GroupsViewController *)childViewControllerWithHeaderGroup:(Group *)headerGroup
{
    return nil;
}


@end
