//
//  PlaceSelectViewController.h
//  Oritsubushi
//
//  Created by yonezawaizumi on 2013/09/17.
//  Copyright (c) 2013年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoogleMapsLocation.h"

enum {
    PlaceSelectViewControllerIndexCancelled = -1,
    PlaceSelectViewControllerIndexKilled = -2
} PlaceSelectViewControllerIndex;

@class PlaceSelectViewController;

@protocol PlaceSelectViewControllerDelegate <NSObject>

- (void)placeSelectViewController:(PlaceSelectViewController *)placeSelectViewController didSelected:(GoogleMapsLocation *)location atIndex:(NSInteger)index;

@end

@interface PlaceSelectViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithPlaceCandidates:(NSArray *)candidates delegate:(id<PlaceSelectViewControllerDelegate>)selectDelegate;

@property(nonatomic,assign) id<PlaceSelectViewControllerDelegate> selectDelegate;

@property(nonatomic,strong) IBOutlet UITableView *locationsTableView;
@property(nonatomic,strong) IBOutlet UIView *bottomSeparator;

- (IBAction)cancel:(id)sender;

@end
