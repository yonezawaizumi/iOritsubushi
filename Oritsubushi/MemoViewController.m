//
//  MemoViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/01.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "MemoViewController.h"
#import "Station.h"
#import "AppDelegate.h"

@implementation MemoViewController

@synthesize cell;
@synthesize station = station_;

- (id)initWithStation:(Station *)station
{
    self = [super initWithNibName:@"MemoViewController" bundle:nil];
    if (self) {
        // Custom initialization
        self.station = station;
        self.title = NSLocalizedString(@"メモ", nil);
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.cell = nil;
}

- (void)dealloc
{
    self.cell = nil;
    self.station = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self.cell viewWithTag:1] becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    UITextView *textView = (UITextView *)[self.cell viewWithTag:1];
    self.station.memo = textView.text;
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    [delegate.database updateCompletion:self.station];
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
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cell.frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ((UITextView *)[self.cell viewWithTag:1]).text = self.station.memo;
    return self.cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
