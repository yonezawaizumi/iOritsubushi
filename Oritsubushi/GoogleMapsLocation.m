//
//  GoogleMapsLocation.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "GoogleMapsLocation.h"

@implementation GoogleMapsLocation

@synthesize address = address_;
@synthesize coordinate = coordinate_;

- (id)initWithAddress:(NSString *)address coordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    if(self) {
        self.address = address;
        self.coordinate = coordinate;
    }
    return self;
}

- (void)dealloc
{
    self.address = nil;
}

@end
