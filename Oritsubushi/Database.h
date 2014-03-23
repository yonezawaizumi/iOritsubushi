//
//  Database.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/19.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Prefs.h"
#import "DatabaseFilterTypes.h"
#import "Types.h"
#import "OperatorTypes.h"

@class Operator;
@class Line;
@class Station;
@class Group;

@protocol DatabaseUpdateNotificationObserverProtocol

- (void)databaseWasUpdatedWithNotification:(NSNotification *)notification;

@end

@interface Database : NSObject

@property(assign,getter=isCancelling) BOOL cancelling;

+ (void)addObserver:(id<DatabaseUpdateNotificationObserverProtocol>)observer;
+ (void)removeObserver:(id<DatabaseUpdateNotificationObserverProtocol>)observer;

- (NSString *)prepareDatabase;
- (void)reloadDatabase;
- (BOOL)reloadDatabaseWithSQLFilePath:(NSString *)SQLFilePath;
- (NSInteger)userVersion;

- (void)updateVisibilityType:(VisibilityType)type;
- (void)updateFilterWithFilterType:(DatabaseFilterType)type filterValue:(NSString *)value;
- (NSMutableArray *)stationsWithRegion:(MKCoordinateRegion)region limitCount:(NSInteger)limitCount;

- (Operator *)operatorWithCode:(NSNumber *)code;
- (NSArray *)linesWithStation:(Station *)station;
- (NSArray *)stationsWithLineCode:(NSNumber *)code;
- (NSArray *)stationsWithPref:(PrefType)type;
- (NSArray *)stationsWithYomiPrefix:(NSString *)yomiPrefix;
- (NSArray *)stationsWithCompletionDate:(NSNumber *)completionDate;

- (Group *)allTotalGroup;
- (NSArray *)operatorTypeGroups;
- (void)reloadOperatorTypeGroup:(Group *)group;
- (NSArray *)operatorGroupsNoStatisticsWithOperatorTypeGroup:(Group *)group_ cacheKey:(NSString *)cacheKey;
- (NSArray *)operatorGroupsWithOperatorTypeGroup:(Group *)group cacheKey:(NSString *)cacheKey;
- (void)reloadOperatorGroup:(Group *)group;
- (NSArray *)lineGroupsWithOperatorGroup:(Group *)group;
- (void)reloadLineGroup:(Group *)group;
- (NSArray *)yomiGroups;
- (void)reloadYomiGroup:(Group *)group;
- (NSArray *)yomiGroupsWithYomiGroup:(Group *)group;
- (NSArray *)prefGroups;
- (void)reloadPrefGroup:(Group *)group;
- (NSArray *)completionYearGroups;
- (void)reloadCompletionYearGroup:(Group *)group;
- (NSArray *)completionMonthGroupsWithYearGroup:(Group *)group;
- (void)reloadCompletionMonthGroup:(Group *)group;
- (NSArray *)completionDateGroupsWithMonthGroup:(Group *)group;
- (void)reloadCompletionDateGroup:(Group *)group;


- (void)updateCompletion:(Station *)station;
- (BOOL)writeSyncFileWithHandle:(NSFileHandle *)handle recentUpdateDate:(NSInteger)updateDate;

@end
