//
//  MapViewController.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/10/30.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "MapView.h"
#import "MapWrapper.h"
#import "GoogleMapsService.h"
#import "PlaceSelectView.h"
#import "PlaceSelectViewController.h"

@interface MapViewController : UIViewController <MapViewDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, /*DatabaseUpdateNotificationProtocol*/DatabaseUpdateNotificationObserverProtocol, MapWrapperTouchDelegate, GoogleMapsServiceDelegate,
    PlaceSelectViewDelegate,
    PlaceSelectViewControllerDelegate
>

- (void)moveToStation:(Station *)station;
- (void)updateFilterWithFilterType:(DatabaseFilterType)type filterValue:(NSString *)value;
- (void)requestUpdate;

@end
