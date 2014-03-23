//
//  AnnotationView.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/26.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "Station.h"

@interface AnnotationView : MKPinAnnotationView

+ (AnnotationView *)annotationViewWithStation:(Station *)station mapView:(MKMapView *)mapView;

@end
