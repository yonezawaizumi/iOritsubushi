//
//  AppDelegate.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/10/29.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "Settings.h"
#import <CoreLocation/CoreLocation.h>

@protocol LocationUpdatedDelegate

- (void)beginLocating:(BOOL)enabled;
- (void)locationWasUpdated:(CLLocationCoordinate2D)location;

@end

@class Station;

@interface AppDelegate : UIResponder<UIApplicationDelegate, CLLocationManagerDelegate>

@property(strong, nonatomic) UIWindow *window;
@property(nonatomic,strong,readonly) Database *database;
@property(nonatomic,readonly) NSInteger osVersion;
@property(nonatomic) id<LocationUpdatedDelegate> locationDelegate;

- (void)mapViewUpdateFilterWithFilterType:(DatabaseFilterType)type filterValue:(NSString *)value;
- (void)mapViewMoveToStation:(Station *)station;
- (void)mapViewRequestUpdate;

- (void)saveCookies;
- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle;

@end
