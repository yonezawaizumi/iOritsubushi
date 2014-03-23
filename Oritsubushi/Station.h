//
//  Station.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/10/31.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "FMDatabase.h"
#import "Prefs.h"
#import "Operator.h"

@interface Station : NSObject <MKAnnotation>

@property(nonatomic,strong) NSNumber *code;
@property(nonatomic) CLLocationCoordinate2D coordinate;
@property(nonatomic,strong) NSString *name;
@property(nonatomic,strong) NSString *yomi;
@property(nonatomic,strong) NSString *wiki;
@property(nonatomic) PrefType pref;
@property(nonatomic,strong) NSString *address;
@property(nonatomic) NSInteger operatorCode;

@property(nonatomic) CLLocationCoordinate2D centerCoordinate;
@property(nonatomic,readonly) CGFloat distance;
@property(nonatomic,strong,readonly) NSString *distanceString;

@property(nonatomic,strong,readonly) Operator *operator;
@property(nonatomic,strong,readonly) NSArray *lines;

@property(nonatomic,readonly) BOOL isCompleted;
@property(nonatomic) NSInteger completionDate;
@property(nonatomic,strong,readonly) NSString *completionDateString;
@property(nonatomic,strong,readonly) NSString *completionDateShortString;
@property(nonatomic,strong,readonly) NSString *statusIconName;
@property(nonatomic,strong) NSString *memo;
//V2.1
@property(nonatomic) NSTimeInterval updatedDate;
@property(nonatomic,strong,readonly) NSString *updatedDateString;

- (id)initWithFMResultSet:(FMResultSet *)resultSet;
- (NSString *)distanceStringFrom:(CLLocationCoordinate2D)coodinate;
- (void)setTodayCompletion;
+ (NSString *)statusIconNameWithCompleted:(BOOL)isCompleted;

@end
