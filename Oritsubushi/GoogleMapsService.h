//
//  GoogleMapsService.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "ASIHTTPRequest.h"

@class GoogleMapsService;

@protocol GoogleMapsServiceDelegate <NSObject>

- (void)GoogleMapsServiceDidFinish:(GoogleMapsService *)service;

@end

@interface GoogleMapsService : NSObject <ASIHTTPRequestDelegate>

@property(nonatomic,assign) CGFloat timeoutSecond;
@property(nonatomic,strong) NSArray *locations;
@property(nonatomic,strong) NSString *errorMessage;
@property(nonatomic,assign) id<GoogleMapsServiceDelegate> delegate;

- (id)initWithDelegate:(id<GoogleMapsServiceDelegate>)delegate;
- (id)initWithDelegate:(id<GoogleMapsServiceDelegate>)delegate timeoutSecond:(CGFloat)timeoutSecond;
- (void)geocodeWithAddress:(NSString *)address country:(NSString *)country;
- (void)geocodeInJapanWithAddress:(NSString *)address;

@end
