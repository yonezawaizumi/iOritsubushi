//
//  StationInformationViewController.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/29.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class Station;

@interface StationInformationViewController : UITableViewController </*DatabaseUpdateNotificationProtocol*/DatabaseUpdateNotificationObserverProtocol>

@property(nonatomic,strong) Station *station;
@property(nonatomic,strong) IBOutlet UIView *titleView;
@property(nonatomic,strong) IBOutlet UILabel *updatedDateLabel;

- (id)initWithStation:(Station *)station;

@end
