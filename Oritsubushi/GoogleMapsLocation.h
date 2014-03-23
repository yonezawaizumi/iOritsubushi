//
//  GoogleMapsLocation.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface GoogleMapsLocation : NSObject

@property(nonatomic,strong) NSString *address;
@property(nonatomic,assign) CLLocationCoordinate2D coordinate;

- (id)initWithAddress:(NSString *)address coordinate:(CLLocationCoordinate2D)coordinate;

@end
