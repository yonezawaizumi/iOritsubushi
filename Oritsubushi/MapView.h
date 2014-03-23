//
//  MapView.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/10/30.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <MapKit/MapKit.h>

@class MapView;

@protocol MapViewDelegate<MKMapViewDelegate>

- (void)mapViewWasSingleTapped:(MapView *)mapView;

@end

@interface MapView : MKMapView <UIGestureRecognizerDelegate>

@end
