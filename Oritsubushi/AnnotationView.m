//
//  AnnotationView.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/26.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "AnnotationView.h"

#define REUSE_IDENTIFIER    @"AnnotationViewId"

@implementation AnnotationView

+ (AnnotationView *)annotationViewWithStation:(Station *)station mapView:(MKMapView *)mapView
{
    AnnotationView *annotationView = (AnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:REUSE_IDENTIFIER];
    if(!annotationView) {
        annotationView = [[AnnotationView alloc] initWithAnnotation:station reuseIdentifier:REUSE_IDENTIFIER];
    }
    annotationView.canShowCallout = YES;
    annotationView.pinColor = station.isCompleted ? MKPinAnnotationColorGreen : MKPinAnnotationColorRed;
    return annotationView;
}

@end
