//
//  CompletionViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/01.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "CompletionViewController.h"
#import "Station.h"
#import "Misc.h"
#import "Settings.h"
#import "AppDelegate.h"

@interface CompletionViewController ()

@property(nonatomic) NSInteger initialCompletionDate;
@property(nonatomic) NSInteger today;

- (void)setPickerValueWithInteger:(NSInteger)date animated:(BOOL)animated;
- (NSInteger)intPickerValue;

@end

@implementation CompletionViewController

@synthesize tableView = tableView_;
@synthesize pickerView = pickerView_;
@synthesize station = station_;
@synthesize compCell;
@synthesize compLabel;
@synthesize compSwitch;
@synthesize titleLabel;
@synthesize initialCompletionDate;
@synthesize today;

- (id)initWithStation:(Station *)station
{
    NSString *nibName;
    if(((AppDelegate *)[UIApplication sharedApplication].delegate).osVersion >= 7) {
        nibName = @"CompletionViewController7";
    } else {
        nibName = @"CompletionViewController";
    }
    self = [super initWithNibName:nibName bundle:nil];
    if (self) {
        // Custom initialization
        self.station = station;
        self.title = NSLocalizedString(@"乗下車日", nil);
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.tableView = nil;
    self.pickerView = nil;
    self.compCell = nil;
    self.compLabel = nil;
    self.compSwitch = nil;
    self.titleLabel = nil;
}

- (void)dealloc
{
    self.tableView = nil;
    self.pickerView = nil;
    self.compCell = nil;
    self.compLabel = nil;
    self.compSwitch = nil;
    self.titleLabel = nil;
    self.station = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.initialCompletionDate = self.station.completionDate;
    self.today = [Misc today];
    self.compLabel.text = self.station.completionDateString;
    self.compSwitch.on = self.station.isCompleted;
    self.titleLabel.text = self.station.title;

    CGRect frame = self.tableView.frame;
    frame.size.height = self.pickerView.frame.origin.y - frame.origin.y;
    self.tableView.frame = frame;

    NSInteger date;
    if(self.station.isCompleted) {
        date = self.station.completionDate;
    } else {
        date = [[NSUserDefaults standardUserDefaults] integerForKey:SETTINGS_KEY_RECENT_DATE];
        if(date <= 0 || self.today < date) {
            date = self.today;
        }
    }
    [self setPickerValueWithInteger:date animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate.database updateCompletion:self.station];
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:[self intPickerValue]] forKey:SETTINGS_KEY_RECENT_DATE];
    [super viewWillDisappear:animated];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)valueDidChange
{
    self.station.completionDate = self.compSwitch.on ? [self intPickerValue] : 0;
    self.compLabel.text = self.station.completionDateString;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.titleLabel.frame.size.height;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.titleLabel;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.row) {
        case 0:
            return self.compCell;
        case 1:
        {
            static NSString *CellIdentifier = @"StationInformationCell";
            
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"今日、乗下車しました！", nil);
            return cell;
        }
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.row) {
        case 1:
        {
            NSInteger newToday = [Misc today];
            if(newToday / 10000 > self.today / 10000) {
                self.today = newToday;
                [self.pickerView reloadAllComponents];
            }
            [self.compSwitch setOn:YES animated:YES];
            self.station.completionDate = self.today;
            self.compLabel.text = self.station.completionDateString;
            [self setPickerValueWithInteger:self.today animated:YES];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

#pragma mark - Picker view data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

static const NSInteger ROW_MAX = 16384;

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return ROW_MAX;
}

- (NSUInteger)radixWithComponent:(NSInteger)component
{
    switch(component) {
        case 0:
            return self.today / 10000 - 1900 + 1;
        case 1:
            return 13;
        case 2:
            return 32;
        default:
            return 0;
    }
}

- (NSInteger)optimizedRowWithRow:(NSInteger)row component:(NSInteger)component
{
    NSUInteger radix = [self radixWithComponent:component];
    return row % radix + ROW_MAX / 2 / radix * radix;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    row %= [self radixWithComponent:component];
    switch(component) {
        case 0:
            return row ? [NSString stringWithFormat:NSLocalizedString(@"%d年", nil), 1900 + row] : NSLocalizedString(@"不明", nil);
        case 1:
            return row ? [NSString stringWithFormat:NSLocalizedString(@"%d月", nil), row] : NSLocalizedString(@"----", nil);
        case 2:
            return row ? [NSString stringWithFormat:NSLocalizedString(@"%d日", nil), row] : NSLocalizedString(@"----", nil);
    }
    return nil;;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [pickerView selectRow:[self optimizedRowWithRow:row component:component] inComponent:component animated:NO];
    if(self.compSwitch.on) {
        self.station.completionDate = [self intPickerValue];
        self.compLabel.text = self.station.completionDateString;
    }
}

- (void)setPickerValueWithInteger:(NSInteger)date animated:(BOOL)animated
{
    NSInteger year = [self optimizedRowWithRow:date <= 1 ? 0 : date / 10000 - 1900 component:0];
    NSInteger month = [self optimizedRowWithRow:date % 10000 / 100 component:1];
    NSInteger day = [self optimizedRowWithRow:date == 1 ? 0 : date % 100 component:2];
    [self.pickerView selectRow:year inComponent:0 animated:animated];
    [self.pickerView selectRow:month inComponent:1 animated:animated];
    [self.pickerView selectRow:day inComponent:2 animated:animated];
}

- (NSInteger)intPickerValue
{
    NSUInteger radix = [self radixWithComponent:0];
    NSInteger year = [self.pickerView selectedRowInComponent:0] % radix;
    if(!year) {
        return 1;
    }
    year += 1900;
    NSInteger comp = year * 10000;
    radix = [self radixWithComponent:1];
    NSInteger month = [self.pickerView selectedRowInComponent:1] % radix;
    comp += month * 100;
    radix = [self radixWithComponent:2];
    NSInteger day = [self.pickerView selectedRowInComponent:2] % radix;
    NSInteger maxDay;
    switch(month) {
        case 0:
            maxDay = 0;
            break;
        case 4:
        case 6:
        case 9:
        case 11:
            maxDay = 30;
            break;
        case 2:
            if(year % 4) {
                maxDay = 28;
            } else if(year % 100) {
                maxDay = 29;
            } else if(year % 400) {
                maxDay = 28;
            } else {
                maxDay = 29;
            }
            break;
        default:
            maxDay = 31;
            break;
    }
    return comp + (day <= maxDay ? day : 0);
}

@end
