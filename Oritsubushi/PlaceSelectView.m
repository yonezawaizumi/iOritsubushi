//
//  PlaceSelectView.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "PlaceSelectView.h"
#import "QuartzCore/QuartzCore.h"
#import "Consts.h"


@interface PlaceSelectView () {
    BOOL initialized;
}

@property(nonatomic,strong) NSArray *placeCandidates;
@property(nonatomic,strong) UITableView *tableView;

@end

@implementation PlaceSelectView

@synthesize placeCandidates;
@synthesize tableView = tableView_;
@synthesize selectDelegate = selectDelegate_;

- (id)initWithPlaceCandidates:(NSArray *)candidates delegate:(id<PlaceSelectViewDelegate>)selectDelegate
{
    self = [super init];
    if(self) {
        self.placeCandidates = candidates;
        
        self.title = NSLocalizedString(@"もしかして…", nil);
        self.message = @"";
        self.selectDelegate = selectDelegate;
        [super setDelegate:self];
        [self addButtonWithTitle:NSLocalizedString(@"キャンセル", nil)];
        self.cancelButtonIndex = 0;
        
        int numRows = [candidates count];
        CGRect frame = CGRectMake(0,
                                  0,
                                  100,
                                  (numRows > (int)PLACE_SELECT_MAX_NUM_ROWS ? PLACE_SELECT_MAX_NUM_ROWS : numRows) * PLACE_SELECT_ROW_HEIGHT
                                  );
        self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        self.tableView.rowHeight = PLACE_SELECT_ROW_HEIGHT;
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        UIView* view = [[UIView alloc] initWithFrame:frame];
        view.backgroundColor = PLACE_SELECT_BACKGROUND_COLOR;
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = PLACE_SELECT_CORNER_RADIUS;
        [view addSubview:self.tableView];
        [self addSubview:view];

        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    self.placeCandidates = nil;
    self.tableView = nil;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self dismissWithClickedButtonIndex:self.cancelButtonIndex animated:NO];
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    if(!initialized) {
        CGRect frame = self.frame;
        frame.origin.y -= self.tableView.frame.size.height / 2;
        frame.size.height += self.tableView.frame.size.height;
        self.frame = frame;
        CGRect selectFrame = self.tableView.frame;
        selectFrame.size.width = frame.size.width - PLACE_SELECT_MARGIN_LEFT * 2;
        self.tableView.frame = selectFrame;
        selectFrame.origin.x = PLACE_SELECT_MARGIN_LEFT;
        selectFrame.origin.y = PLACE_SELECT_MARGIN_TOP;
        self.tableView.superview.frame = selectFrame;
        
        for(UIView *view in self.subviews) {
            frame = view.frame;
            if(frame.origin.y > PLACE_SELECT_MARGIN_TOP) {
                frame.origin.y += selectFrame.size.height;
                view.frame = frame;
            }
        }
        initialized = YES;
    }
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
    if([placeCandidates count] > (int)PLACE_SELECT_MAX_NUM_ROWS) {
        [self.tableView flashScrollIndicators];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    [self.selectDelegate placeSelectView:self didSelected:nil atIndex:-1];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [placeCandidates count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"PlaceSelectViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    cell.textLabel.text = ((GoogleMapsLocation *)[placeCandidates objectAtIndex:indexPath.row]).address;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectDelegate placeSelectView:self didSelected:[placeCandidates objectAtIndex:indexPath.row] atIndex:indexPath.row];
    [self dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)dismiss
{
    [self dismissWithClickedButtonIndex:0 animated:NO];
}

@end
