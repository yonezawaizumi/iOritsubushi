//
//  Database.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/19.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "Database.h"
#import "FMDatabase.h"
#import "FMDBHelper.h"
#import "Operator.h"
#import "Line.h"
#import "Station.h"
#import "Group.h"
#import "CompletionDateGroup.h"
#import "OperatorTypes.h"
#import "LineTypes.h"
#import "Prefs.h"
#import "NSString+CountSubstrings.h"
#import "NSFileHandle+TextReader.h"
#import "Consts.h"
#import "AppDelegate.h"


@interface Database ()

@property(strong) FMDatabase *database;
@property(strong) NSDictionary *operators;
@property(strong) NSString *tablesForFilterCondition;
@property(strong) NSString *filterSQLCondition;
@property(assign) VisibilityType visibilityType;
@property(strong) NSString *wordSQLCondition;

@property(strong) NSMutableDictionary *operatorsGroupCaches;

- (void)updateFilterSQLCondition;

@end

@implementation Database

@synthesize database = database_;
@synthesize operators;
@synthesize tablesForFilterCondition;
@synthesize filterSQLCondition;
@synthesize visibilityType;
@synthesize wordSQLCondition;

@synthesize cancelling;

@synthesize operatorsGroupCaches;

static NSArray *sortDescriptors = nil;
static NSArray *titleSortDescriptors = nil;

static NSString *DATABASE_UPDATE_NOTIFICATION = @"DatabaseUpdateNotification";

+ (void)addObserver:(id<DatabaseUpdateNotificationObserverProtocol>)observer
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(databaseWasUpdatedWithNotification:) name:DATABASE_UPDATE_NOTIFICATION object:nil];
}

+ (void)removeObserver:(id<DatabaseUpdateNotificationObserverProtocol>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:DATABASE_UPDATE_NOTIFICATION object:nil];
}

- (void)dealloc
{
    [self.database close];
    self.database = nil;
    self.operators = nil;
    self.tablesForFilterCondition = nil;
    self.filterSQLCondition = nil;
    self.wordSQLCondition = nil;
    self.operatorsGroupCaches = nil;
}

- (NSString *)prepareDatabase
{
    if(self.database) {
        return nil;
    }
    if(!sortDescriptors) {
        sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"code" ascending:YES]];
        titleSortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES]];
    }
    
    static NSString *databaseName = @"oritsubushi.sqlite";
    [FMDBHelper moveOldDatabase:databaseName];
    NSString *writableDBPath = [FMDBHelper getWritablePath:databaseName];
    BOOL copied;
    NSError *error = [FMDBHelper prepareDatabase:databaseName writableDBPath:writableDBPath userVersion:DATABASE_USER_VERSION fileCopied:&copied];
    if(!error) {
        self.database = [FMDatabase databaseWithPath:writableDBPath];
        if(self.database) {
            [self.database open];
            self.database.logsErrors = YES;
            //self.database.shouldCacheStatements = YES;
            self.database.shouldCacheStatements = NO;
            databaseName = @"completions.sqlite";
            [FMDBHelper moveOldDatabase:databaseName];
            writableDBPath = [FMDBHelper getWritablePath:databaseName];
            /*error = [FMDBHelper prepareDatabase:databaseName writableDBPath:writableDBPath userVersion:0];
            if(!error) {
                [self.database executeUpdate:[NSString stringWithFormat:@"ATTACH DATABASE \"%@\" AS completions", writableDBPath]];
                [self reloadDatabase];
                self.visibilityType = VisibilityAllStations;
                [self updateFilterWithFilterType:DatabaseFilterTypeNone filterValue:nil];
                return nil;
            }*/
            FMDatabase *database = [FMDatabase databaseWithPath:writableDBPath];
            if(!database || ![database open]) {
                return NSLocalizedString(@"データベースが開けません", nil);
            }
            [database executeUpdate:@"CREATE TABLE completions (s_id INTEGER PRIMARY KEY NOT NULL, comp_date INTEGER NOT NULL DEFAULT(0), update_date INTEGER NOT NULL DEFAULT (0), memo TEXT)"];
            [database close];
            [self.database executeUpdate:[NSString stringWithFormat:@"ATTACH DATABASE \"%@\" AS completions", writableDBPath]];
            if(copied) {
                for(int i = 0; ; ++i) {
                    if (!duplicaters[i].version) {
                        break;
                    } else if (duplicaters[i].version > DATABASE_USER_VERSION) {
                        continue;
                    }
                    NSString *query = [NSString stringWithFormat:@"INSERT OR IGNORE INTO completions SELECT %d, comp_date, strftime('%%s', 'now'), memo FROM completions WHERE s_id = %d AND comp_date > 0", duplicaters[i].newKey, duplicaters[i].oldKey];
                    [self.database executeUpdate:query];
                    if (duplicaters[i].oldKey2) {
                        query = [NSString stringWithFormat:@"INSERT OR IGNORE INTO completions SELECT %d, comp_date, strftime('%%s', 'now'), memo FROM completions WHERE s_id = %d AND comp_date > 0", duplicaters[i].newKey, duplicaters[i].oldKey2];
                        [self.database executeUpdate:query];
                    }
                    if (duplicaters[i].oldKey3) {
                        query = [NSString stringWithFormat:@"INSERT OR IGNORE INTO completions SELECT %d, comp_date, strftime('%%s', 'now'), memo FROM completions WHERE s_id = %d AND comp_date > 0", duplicaters[i].newKey, duplicaters[i].oldKey3];
                        [self.database executeUpdate:query];
                    }
                }
                [self.database executeUpdate:@"INSERT OR IGNORE INTO completions SELECT s_id, 0, 0, \"\" FROM stations"];
            }
            [self reloadDatabase];
            self.visibilityType = VisibilityAllStations;
            [self updateFilterWithFilterType:DatabaseFilterTypeNone filterValue:nil];
            return nil;
            
        }
    }
    return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"データベースが開けません", nil), error ? [error localizedDescription] : @""];
}

- (void)reloadDatabase
{
    self.cancelling = YES;
    //reload operators
    NSMutableDictionary *ops = [NSMutableDictionary dictionary];
    FMResultSet *result = [self.database executeQuery:@"SELECT o_id, operator, type FROM operators WHERE enabled = 1 ORDER BY type, o_id"];
    while([result next]) {
        Operator *operator = [[Operator alloc] init];
        operator.code = [result intForColumnIndex:0];
        operator.name = [result stringForColumnIndex:1];
        operator.type = [result intForColumnIndex:2];
        [ops setObject:operator forKey:[NSNumber numberWithInteger:operator.code]];
    }
    self.operators = ops;
    [result close];
    self.cancelling = NO;
    
    self.operatorsGroupCaches = [NSMutableDictionary dictionary];

    //AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    //[appDelegate databaseWasUpdatedAll];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:DATABASE_UPDATE_NOTIFICATION object:nil];
}

- (BOOL)reloadDatabaseWithSQLFilePath:(NSString *)SQLFilePath
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:SQLFilePath];
    if(handle) {
        [self.database beginTransaction];
        BOOL succeeded = YES;
        BOOL updated = NO;
        @try {
            for(;;) {
                NSString *line = [handle readLine];
                if(!line) {
                    break;
                }
                NSUInteger count = [line countSubstrings:@"'"];
                if(count % 2) {
                    NSMutableString *multiline = [NSMutableString stringWithString:line];
                    do {
                        line = [handle readLine];
                        if(!line) {
                            line = nil;
                            break;
                        }
                        count += [line countSubstrings:@"'"];
                        [multiline appendString:line];
                    } while(count % 2);
                    if(multiline) {
                        line = multiline;
                    }
                }
                if(!line) {
                    break;
                }
                //NSLog(@"DB:%@", line);
                [self.database executeUpdate:line];
                updated = YES;
            }
        } @catch (NSException *e) {
            succeeded = NO;
        }
        [handle closeFile];
        if(succeeded && updated) {
            [self.database commit];
            [self.database executeUpdate:@"VACUUM"];
        } else {
            [self.database rollback];
        }
        if(!succeeded) {
            return NO;
        } else if(!updated) {
            return YES;
        }
    }
    [self performSelectorOnMainThread:@selector(reloadDatabase) withObject:nil waitUntilDone:NO];
    return YES;
}

- (NSInteger)userVersion
{
    FMResultSet *result = [self.database executeQuery:@"PRAGMA user_version;"];
    NSInteger currentUserVersion = result && [result next] ? [result intForColumnIndex:0] : 0;
    [result close];
    return currentUserVersion;
}

- (void)updateFilterSQLCondition
{
    NSString *typeFilterSQL;
    switch(self.visibilityType) {
        case VisibilityCompletedStations:
            typeFilterSQL = @"AND completions.comp_date > 0";
            break;
        case VisibilityIncompletedStations:
            typeFilterSQL = @"AND completions.comp_date = 0";
            break;
        default:
            typeFilterSQL = @"";
            break;
    }
    self.filterSQLCondition = [NSString stringWithFormat:@"stations.enabled = 1 AND %@ AND completions.s_id = stations.s_id %@", self.wordSQLCondition, typeFilterSQL];
}

- (void)updateVisibilityType:(VisibilityType)type
{
    self.visibilityType = type;
    [self updateFilterSQLCondition];
}

- (void)updateFilterWithFilterType:(DatabaseFilterType)type filterValue:(NSString *)value
{
    NSString *tables = @"stations, completions";
    if([value length]) {
        NSString *word = [NSString stringWithString:value];
        NSRange escapeChars = [word rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"%_"]];
        BOOL escape = type != DatabaseFilterTypePref && escapeChars.location != NSNotFound;
        if(escape) {
            word = [[[word stringByReplacingOccurrencesOfString:@"*" withString:@"**"]
                     stringByReplacingOccurrencesOfString:@"%" withString:@"*%"]
                    stringByReplacingOccurrencesOfString:@"_" withString:@"*_"];
        }
        word = [word stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        NSString *format;
        BOOL formatted = NO;
        switch(type) {
            case DatabaseFilterTypeNameForward:
                format = @"stations.station LIKE '%@%%'";
                break;
            case DatabaseFilterTypeName:
                format = @"stations.station LIKE '%%%@%%'";
                break;
            case DatabaseFilterTypeLineForward:
                tables = @"stations, completions, stations_lines, \"lines\"";
                format = @"stations_lines.s_id = stations.s_id AND lines.l_id = stations_lines.l_id AND lines.line LIKE '%@%%' AND lines.enabled = 1";
                break;
            case DatabaseFilterTypeLine:
                tables = @"stations, completions, stations_lines, \"lines\"";
                format = @"stations_lines.s_id = stations.s_id AND lines.l_id = stations_lines.l_id AND lines.line LIKE '%%%@%%' AND lines.enabled = 1";
                break;
            case DatabaseFilterTypeYomiForward:
                format = @"stations.yomi LIKE '%@%%'";
                break;
            case DatabaseFilterTypeYomi:
                format = @"stations.yomi LIKE '%%%@%%'";
                break;
            case DatabaseFilterTypePref:
            {
                NSArray *prefs = [Prefs matchPrefsWithString:word];
                format = [prefs count] ? [NSString stringWithFormat:@"stations.pref IN (%@)", [prefs componentsJoinedByString:@","]] : @"0";
                word = @"";
                break;
            }
            case DatabaseFilterTypeDate:
            {
                NSRange range;
                if(![CompletionDateGroup completionDateRangeWithSearchKeyword:value range:&range]) {
                    self.wordSQLCondition = @"1 ";
                } else if(range.length) {
                    self.wordSQLCondition = [NSString stringWithFormat:@"completions.comp_date BETWEEN %lu AND %lu", (unsigned long)range.location, (unsigned long)NSMaxRange(range)];
                } else {
                    self.wordSQLCondition = [NSString stringWithFormat:@"completions.comp_date = %lu", (unsigned long)range.location];
                }
                escape = NO;
                formatted = YES;
                break;
            }
            default:
                escape = NO;
                formatted = YES;
                self.wordSQLCondition = @"1 ";
                break;
        }
        if(!formatted) {
            self.wordSQLCondition = [NSString stringWithFormat:@"%@ %@ ", [NSString stringWithFormat:format, word], escape ? @"ESCAPE '*'" : @""];
        }
    } else {
        self.wordSQLCondition = @"1 ";
    }
    self.tablesForFilterCondition = tables;
    [self updateFilterSQLCondition];
}

- (NSMutableArray *)stationsWithRegion:(MKCoordinateRegion)region limitCount:(NSInteger)limitCount
{
    NSInteger latDelta = (NSInteger)(region.span.latitudeDelta * 1e6 * ANNOTATION_CACHING_AREA);
    NSInteger lat = (NSInteger)(region.center.latitude * 1e6) - latDelta / 2;
    NSInteger lngDelta = (NSInteger)(region.span.longitudeDelta * 1e6 * ANNOTATION_CACHING_AREA);
    NSInteger lng = (NSInteger)(region.center.longitude * 1e6) - lngDelta / 2; 
    
    
    NSNumber *minLat = [NSNumber numberWithInteger:lat];
    NSNumber *maxLat = [NSNumber numberWithInteger:(lat + latDelta)];
    NSNumber *minLng = [NSNumber numberWithInteger:lng];
    NSNumber *maxLng = [NSNumber numberWithInteger:(lng + lngDelta)];
    NSNumber *centerLat = [NSNumber numberWithInteger:(NSInteger)(region.center.latitude * 1e6)];
    NSNumber *centerLng = [NSNumber numberWithInteger:(NSInteger)(region.center.longitude * 1e6)];
    NSString *sql = [NSString stringWithFormat:@"SELECT stations.*, completions.comp_date, completions.memo, completions.update_date, "
                     @"(lat - ?1) * (lat - ?1) + (lng - ?2) * (lng - ?2) AS distance FROM %@ "
                     @"WHERE stations.lat >= ?3 AND stations.lat < ?4 AND stations.lng >= ?5 AND stations.lng < ?6 "
                     @"AND %@ ORDER BY stations.weight, distance LIMIT ?7",  
                     self.tablesForFilterCondition, self.filterSQLCondition];

    FMResultSet *result = [self.database executeQuery:sql, centerLat, centerLng, minLat, maxLat, minLng, maxLng, [NSNumber numberWithInteger:limitCount]];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:limitCount];
    while([result next]) {
        Station *station = [[Station alloc] initWithFMResultSet:result];
        [results addObject:station];
    }
    [result close];
    return results;
}

- (NSArray *)operatorsWithOperatorType:(OperatorType)type
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:([self.operators count] - 1)];
    [self.operators enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        Operator *operator = (Operator *)obj;
        if(operator.type == type) {
            [results addObject:operator];
        }
    }];
    return results;
}

- (Operator *)operatorWithCode:(NSNumber *)code
{
    return (Operator *)[self.operators objectForKey:code];
}


- (NSArray *)linesWithOperatorCode:(NSInteger)code
{
    NSMutableArray *results = [NSMutableArray array];
    FMResultSet *result = [self.database executeQuery:@"SELECT * FROM 'lines' WHERE enabled = 1 AND o_id = ? ORDER BY l_id", [NSNumber numberWithInteger:code]];
    while([result next]) {
        Line *line = [[Line alloc] initWithFMResultSet:result];
        [results addObject:line];
    }
    [result close];
    return results;
}

- (NSArray *)linesWithStation:(Station *)station
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:4];
    FMResultSet *result = [self.database executeQuery:@"SELECT 'lines'.* FROM 'lines', stations_lines WHERE stations_lines.s_id = ? AND lines.l_id = stations_lines.l_id AND lines.enabled = 1 ORDER BY lines.l_id", station.code];
    while([result next]) {
        Line *line = [[Line alloc] initWithFMResultSet:result];
        [results addObject:line];
    }
    [result close];
    return results;
}

- (NSArray *)stationsWithLineCode:(NSNumber *)code
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:4];
    FMResultSet *result = [self.database executeQuery:@"SELECT stations.*, completions.comp_date, completions.memo, completions.update_date FROM stations, stations_lines, completions WHERE stations_lines.l_id = ? AND stations.s_id = stations_lines.s_id AND stations.enabled = 1 AND completions.s_id = stations.s_id ORDER BY stations_lines.s_sort", code];
    while([result next]) {
        Station *station = [[Station alloc] initWithFMResultSet:result];
        [results addObject:station];
    }
    [result close];
    return results;
}

//yomiのバリデーションは済んでいるという仮定(^^;;)
- (NSArray *)stationsWithYomiPrefix:(NSString *)yomiPrefix
{
    //20131120 津駅対応
    //NSNumber *length = [NSNumber numberWithInt:[yomiPrefix length]];
    NSMutableArray *results = [NSMutableArray array];
    //FMResultSet *result = [self.database executeQuery:@"SELECT stations.*, completions.comp_date, completions.memo, completions.update_date FROM stations, completions WHERE stations.enabled = 1 AND SUBSTR(yomi, 1, ?) = ? AND completions.s_id = stations.s_id ORDER BY stations.yomi", length, yomiPrefix];
    FMResultSet *result = [self.database executeQuery:@"SELECT stations.*, completions.comp_date, completions.memo, completions.update_date FROM stations, completions WHERE stations.enabled = 1 AND SUBSTR(yomi, 1, 2) = ? AND completions.s_id = stations.s_id ORDER BY stations.yomi", yomiPrefix];
    while([result next]) {
        Station *station = [[Station alloc] initWithFMResultSet:result];
        [results addObject:station];
    }
    [result close];
    return results;
}

- (NSArray *)stationsWithPref:(PrefType)pref
{
    NSMutableArray *results = [NSMutableArray array];
    FMResultSet *result = [self.database executeQuery:@"SELECT stations.*, completions.comp_date, completions.memo, completions.update_date FROM stations, completions WHERE stations.pref = ? AND stations.enabled = 1 AND completions.s_id = stations.s_id ORDER BY stations.address", [NSNumber numberWithInt:pref]];
    while([result next]) {
        Station *station= [[Station alloc] initWithFMResultSet:result];
        [results addObject:station];
    }
    [result close];
    return results;  
}

- (NSArray *)stationsWithCompletionDate:(NSNumber*)completionDate
{
    NSInteger date = [completionDate intValue];
    if(date < 0) {
        completionDate = @0;
    } else if(!date) {
        completionDate = @1;
    } else if(date <= 9999) {
        completionDate = [NSNumber numberWithInteger:date * 10000];
    } else if(date <= 999912) {
        completionDate = [NSNumber numberWithInteger:date * 100];
    }
    NSMutableArray *results = [NSMutableArray array];
    FMResultSet *result = [self.database executeQuery:@"SELECT stations.*, completions.comp_date, completions.memo, completions.update_date FROM stations, completions WHERE completions.comp_date = ? AND stations.enabled = 1 AND completions.s_id = stations.s_id ORDER BY stations.s_id", completionDate];
    while([result next]) {
        Station *station= [[Station alloc] initWithFMResultSet:result];
        [results addObject:station];
    }
    [result close];
    return results;
}

- (void)updateCompletion:(Station *)station
{
    [self.database executeUpdate:@"BEGIN TRANSACTION"];
    FMResultSet *result = [self.database executeQuery:@"SELECT s_id FROM completions WHERE s_id = ? AND comp_date = ? AND memo = ?", station.code, [NSNumber numberWithInteger:station.completionDate], station.memo];
    BOOL changed = ![result next] || ![result intForColumnIndex:0];
    [result close];
    if(changed) {
        station.updatedDate = [[NSDate date] timeIntervalSince1970];
        [self.database executeUpdate:
         @"REPLACE INTO completions VALUES (?, ?, ?, ?)",
         station.code,
         [NSNumber numberWithInteger:station.completionDate],
         [NSNumber numberWithUnsignedInteger:(NSUInteger)station.updatedDate],
         station.memo
         ];
        [self.database executeUpdate:@"COMMIT"];
        [self.operatorsGroupCaches removeObjectForKey:[NSNumber numberWithInt:station.operator.type]];
       // AppDelegate *delegate = [UIApplication sharedApplication].delegate;
       // [delegate databaseWasUpdatedWithStation:station];
        [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_UPDATE_NOTIFICATION object:station];
    } else {
        //NSLog(@"completions no change");
        [self.database executeUpdate:@"ROLLBACK"];
    }/*
    [self.database executeUpdate:@"UPDATE completions SET comp_date = ?2, update_date = ?3, memo = ?4 "
     @"WHERE s_id = ?1 AND (comp_date != ?2 OR memo != ?4)",
     station.code, [NSNumber numberWithInt:station.completionDate], [NSNumber numberWithUnsignedInteger:(NSUInteger)[[NSDate date] timeIntervalSince1970]], station.memo];
    if([self.database changes]) {
        //AppDelegate *delegate = [UIApplication sharedApplication].delegate;
        //[delegate databaseWasUpdatedWithStation:station];
        [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_UPDATE_NOTIFICATION object:station];
    }*/
}

- (BOOL)writeSyncFileWithHandle:(NSFileHandle *)handle recentUpdateDate:(NSInteger)updateDate;
{
    FMResultSet *result = [self.database executeQuery:@"SELECT * FROM completions WHERE update_date > ?", [NSNumber numberWithInteger:updateDate]];
    while([result next]) {
        NSString *string = [NSString stringWithFormat:@"%d\t%d\t%d\t%@\n",
                            [result intForColumnIndex:0],
                            [result intForColumnIndex:1], 
                            [result intForColumnIndex:2],
                            [[[result stringForColumnIndex:3] stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]
                            ];
        @try {
            [handle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
        } @catch (NSException *ne) {
            return NO;
        }
    }
    return YES;
}

- (Group *)allTotalGroup
{
    FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(*) FROM stations WHERE enabled = 1"];
    Group *group = [[Group alloc] init];
    if([result next]) {
        group.total = [result intForColumnIndex:0];
    }
    [result close];
    result = [self.database executeQuery:@"SELECT COUNT(completions.s_id) FROM completions, stations WHERE completions.comp_date > 0 AND stations.s_id = completions.s_id AND stations.enabled = 1"];
    if([result next]) {
        group.completions = [result intForColumnIndex:0];
    }
    [result close];
    return group;
}

- (NSArray *)operatorTypeGroups
{
    FMResultSet *result = [self.database executeQuery:@"SELECT operators.type, COUNT(stations.s_id) FROM operators, stations WHERE operators.enabled = 1 AND stations.o_id = operators.o_id AND stations.enabled = 1 GROUP BY operators.type"];
    NSMutableDictionary *groups = [NSMutableDictionary dictionaryWithCapacity:[OperatorTypes numberOfOperatorTypes]];
    while([result next]) {
        Group *group = [[Group alloc] init];
        NSInteger code = [result intForColumnIndex:0];
        group.code = [NSNumber numberWithInteger:code];
        group.title = [OperatorTypes stringWithType:(int)code];
        group.total = [result intForColumnIndex:1];
        group.completions = 0;
        [groups setObject:group forKey:group.code];
    }
    [result close];
    result = [self.database executeQuery:@"SELECT operators.type, COUNT(completions.s_id) FROM operators, stations, completions WHERE operators.enabled = 1 AND stations.o_id = operators.o_id AND stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0 GROUP BY operators.type"];
    while([result next]) {
        NSNumber *code = [NSNumber numberWithInt:[result intForColumnIndex:0]];
        Group *group = [groups objectForKey:code];
        if(group) {
            group.completions = [result intForColumnIndex:1];
        }
    }
    [result close];
    
    return [[groups allValues] sortedArrayUsingDescriptors:sortDescriptors];
}

- (void)reloadOperatorTypeGroup:(Group *)group
{
    FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(stations.s_id) FROM stations, operators WHERE operators.type = ? AND operators.enabled = 1 AND stations.o_id = operators.o_id AND stations.enabled = 1", group.code];
    if([result next]) {
        group.total = [result intForColumnIndex:0];
    }
    [result close];
    result = [self.database executeQuery:@"SELECT COUNT(completions.s_id) FROM operators, stations, completions WHERE operators.type = ? AND operators.enabled = 1 AND stations.o_id = operators.o_id AND stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0", group.code];
    if([result next]) {
        group.completions = [result intForColumnIndex:0];
    }
    [result close];    
}

- (NSArray *)operatorGroupsNoStatisticsWithOperatorTypeGroup:(Group *)group_ cacheKey:(NSString *)cacheKey
{
    if(cacheKey && [self.operatorsGroupCaches objectForKey:cacheKey]) {
        return nil;
    }
    FMResultSet *result = [self.database executeQuery:@"SELECT operators.o_id, operators.operator FROM operators WHERE operators.type = ? AND operators.enabled = 1", group_.code];
    NSMutableDictionary *groups = [NSMutableDictionary dictionaryWithCapacity:[OperatorTypes numberOfOperatorTypes]];
    while([result next]) {
        Group *group = [[Group alloc] init];
        NSInteger code = [result intForColumnIndex:0];
        group.code = [NSNumber numberWithInteger:code];
        group.title = [result stringForColumnIndex:1];
        group.total = 0;
        group.completions = 0;
        [groups setObject:group forKey:group.code];
    }
    [result close];
    return [[groups allValues] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)operatorGroupsWithOperatorTypeGroup:(Group *)group_ cacheKey:(NSString *)cacheKey
{
    if(cacheKey) {
        NSArray *cache = [self.operatorsGroupCaches objectForKey:cacheKey];
        if(cache) {
            return cache;
        }
    }
    FMResultSet *result = [self.database executeQuery:@"SELECT operators.o_id, operators.operator, COUNT(stations.s_id) FROM operators, stations WHERE operators.type = ? AND operators.enabled = 1 AND stations.o_id = operators.o_id AND stations.enabled = 1 GROUP BY operators.o_id", group_.code];
    NSMutableDictionary *groups = [NSMutableDictionary dictionaryWithCapacity:[OperatorTypes numberOfOperatorTypes]];
    while([result next]) {
        Group *group = [[Group alloc] init];
        NSInteger code = [result intForColumnIndex:0];
        group.code = [NSNumber numberWithInteger:code];
        group.title = [result stringForColumnIndex:1];
        group.total = [result intForColumnIndex:2];
        group.completions = 0;
        [groups setObject:group forKey:group.code];
    }
    [result close];
    result = [self.database executeQuery:@"SELECT operators.o_id, COUNT(completions.s_id) FROM operators, stations, completions WHERE operators.type = ? AND operators.enabled = 1 AND stations.o_id = operators.o_id AND stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0 GROUP BY operators.o_id", group_.code];
    while([result next]) {
        NSNumber *code = [NSNumber numberWithInt:[result intForColumnIndex:0]];
        Group *group = [groups objectForKey:code];
        if(group) {
            group.completions = [result intForColumnIndex:1];
        }
    }
    [result close];
    //sleep(2);
    NSArray *results = [[groups allValues] sortedArrayUsingDescriptors:sortDescriptors];
    if(cacheKey) {
        [self.operatorsGroupCaches setObject:results forKey:cacheKey];
    }
    return results;
}

- (void)reloadOperatorGroup:(Group *)group
{
    FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(*) FROM stations WHERE o_id = ? AND enabled = 1", group.code];
    if([result next]) {
        group.total = [result intForColumnIndex:0];
    } else {
        group.total = 0;
    }
    [result close];
    result = [self.database executeQuery:@"SELECT COUNT(completions.s_id) FROM stations, completions WHERE stations.o_id = ? AND stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0", group.code];
    if([result next]) {
        group.completions = [result intForColumnIndex:0];
    } else {
        group.completions = 0;
    }
    [result close];
}

- (NSArray *)lineGroupsWithOperatorGroup:(Group *)group_
{
    FMResultSet *result = [self.database executeQuery:@"SELECT lines.l_id, lines.line, COUNT(stations.s_id) FROM \"lines\", stations, stations_lines WHERE lines.o_id = ? AND lines.enabled = 1 AND stations_lines.l_id = lines.l_id AND stations.s_id = stations_lines.s_id  AND stations.enabled = 1 GROUP BY lines.l_id", group_.code];
    NSMutableDictionary *groups = [NSMutableDictionary dictionaryWithCapacity:[OperatorTypes numberOfOperatorTypes]];
    while([result next]) {
        Group *group = [[Group alloc] init];
        NSInteger code = [result intForColumnIndex:0];
        group.code = [NSNumber numberWithInteger:code];
        group.title = [result stringForColumnIndex:1];
        group.total = [result intForColumnIndex:2];
        group.completions = 0;
        [groups setObject:group forKey:group.code];
    }
    [result close];
    result = [self.database executeQuery:@"SELECT lines.l_id, COUNT(completions.s_id) FROM \"lines\", stations, stations_lines, completions WHERE lines.o_id = ? AND lines.enabled = 1 AND stations_lines.l_id = lines.l_id AND stations.s_id = stations_lines.s_id  AND stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0 GROUP BY lines.l_id", group_.code];
    while([result next]) {
        NSNumber *code = [NSNumber numberWithInt:[result intForColumnIndex:0]];
        Group *group = [groups objectForKey:code];
        if(group) {
            group.completions = [result intForColumnIndex:1];
        }
    }
    [result close];
    
    return [[groups allValues] sortedArrayUsingDescriptors:sortDescriptors];
}

- (void)reloadLineGroup:(Group *)group
{
    FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(stations.s_id) FROM \"lines\", stations, stations_lines WHERE lines.l_id = ? AND lines.enabled = 1 AND stations_lines.l_id = lines.l_id AND stations.s_id = stations_lines.s_id  AND stations.enabled = 1", group.code];
    if([result next]) {
        group.total = [result intForColumnIndex:0];
    } else {
        group.total = 0;
    }
    [result close];
    result = [self.database executeQuery:@"SELECT COUNT(completions.s_id) FROM \"lines\", stations, stations_lines, completions WHERE lines.l_id = ? AND lines.enabled = 1 AND stations_lines.l_id = lines.l_id AND stations.s_id = stations_lines.s_id  AND stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0", group.code];
    if([result next]) {
        group.completions = [result intForColumnIndex:0];
    } else {
        group.completions = 0;
    }
    [result close];
}

- (NSArray *)yomiGroups
{
    FMResultSet *result = [self.database executeQuery:@"SELECT SUBSTR(stations.yomi, 1, 1) AS yomi1, COUNT(stations.s_id) FROM stations WHERE stations.enabled = 1 GROUP BY yomi1 ORDER BY yomi1"];
    NSMutableDictionary *groups = [NSMutableDictionary dictionary];
    NSInteger index = 0;
    while([result next]) {
        Group *group = [[Group alloc] init];
        group.code = [NSNumber numberWithInteger:++index];
        group.title = [result stringForColumnIndex:0];
        group.total = [result intForColumnIndex:1];
        group.completions = 0;
        [groups setObject:group forKey:group.title];
    }
    [result close];
    result = [self.database executeQuery:@"SELECT SUBSTR(stations.yomi, 1, 1) AS yomi1, COUNT(completions.s_id) FROM stations, completions WHERE stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0 GROUP BY yomi1"];
    while([result next]) {
        Group *group = [groups objectForKey:[result stringForColumnIndex:0]];
        if(group) {
            group.completions = [result intForColumnIndex:1];
        }
    }
    [result close];
    
    return [[groups allValues] sortedArrayUsingDescriptors:titleSortDescriptors];
}

- (NSArray *)yomiGroupsWithYomiGroup:(Group *)group
{
    NSNumber *length = [NSNumber numberWithInteger:[group.title length]];
    FMResultSet *result = [self.database executeQuery:@"SELECT SUBSTR(stations.yomi, 1, ?1 + 1) AS yomi1, COUNT(stations.s_id) FROM stations WHERE stations.enabled = 1 AND SUBSTR(stations.yomi, 1, ?1) = ?2 GROUP BY yomi1 ORDER BY yomi1", length, group.title];
    NSMutableDictionary *groups = [NSMutableDictionary dictionary];
    NSInteger index = 0;
    while([result next]) {
        Group *group = [[Group alloc] init];
        group.code = [NSNumber numberWithInteger:++index];
        group.title = [result stringForColumnIndex:0];
        group.total = [result intForColumnIndex:1];
        group.completions = 0;
        [groups setObject:group forKey:group.title];
    }
    [result close];
    result = [self.database executeQuery:@"SELECT SUBSTR(stations.yomi, 1, ?1 + 1) AS yomi1, COUNT(completions.s_id) FROM stations, completions WHERE stations.enabled = 1 AND SUBSTR(stations.yomi, 1, ?1) = ?2 AND completions.s_id = stations.s_id AND completions.comp_date > 0 GROUP BY yomi1", length, group.title];
    while([result next]) {
        Group *group = [groups objectForKey:[result stringForColumnIndex:0]];
        if(group) {
            group.completions = [result intForColumnIndex:1];
        }
    }
    [result close];
    
    return [[groups allValues] sortedArrayUsingDescriptors:titleSortDescriptors];
}

- (void)reloadYomiGroup:(Group *)group
{
    NSNumber *length = [NSNumber numberWithInteger:[group.title length]];
    FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(*) FROM stations WHERE SUBSTR(stations.yomi, 1, ?) = ? AND enabled = 1", length, group.title];
    if([result next]) {
        group.total = [result intForColumnIndex:0];
    } else {
        group.total = 0;
    }
    [result close];
    result = [self.database executeQuery:@"SELECT COUNT(completions.s_id) FROM stations, completions WHERE SUBSTR(stations.yomi, 1, ?) = ? AND stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0", length, group.title];
    if([result next]) {
        group.completions = [result intForColumnIndex:0];
    } else {
        group.completions = 0;
    }
    [result close];
}

- (NSArray *)prefGroups
{
    FMResultSet *result = [self.database executeQuery:@"SELECT stations.pref, COUNT(stations.s_id) FROM stations WHERE stations.enabled = 1 GROUP BY stations.pref"];
    NSMutableDictionary *groups = [NSMutableDictionary dictionary];
    while([result next]) {
        Group *group = [[Group alloc] init];
        PrefType code = [result intForColumnIndex:0];
        group.code = [NSNumber numberWithInt:code];
        group.title = [Prefs stringWithType:code];
        group.total = [result intForColumnIndex:1];
        group.completions = 0;
        [groups setObject:group forKey:group.code];
    }
    [result close];
    result = [self.database executeQuery:@"SELECT stations.pref, COUNT(completions.s_id) FROM stations, completions WHERE stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0 GROUP BY stations.pref"];
    while([result next]) {
        NSNumber *code = [NSNumber numberWithInt:[result intForColumnIndex:0]];
        Group *group = [groups objectForKey:code];
        if(group) {
            group.completions = [result intForColumnIndex:1];
        }
    }
    [result close];
    
    return [[groups allValues] sortedArrayUsingDescriptors:sortDescriptors];
}

- (void)reloadPrefGroup:(Group *)group
{
    FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(*) FROM stations WHERE pref = ? AND enabled = 1", group.code];
    if([result next]) {
        group.total = [result intForColumnIndex:0];
    } else {
        group.total = 0;
    }
    [result close];
    result = [self.database executeQuery:@"SELECT COUNT(completions.s_id) FROM stations, completions WHERE stations.pref = ? AND stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0", group.code]; //20120120 bug (group.title)tomi
    if([result next]) {
        group.completions = [result intForColumnIndex:0];
    } else {
        group.completions = 0;
    }
    [result close];
}

- (NSArray *)completionYearGroups
{
    FMResultSet *result = [self.database executeQuery:@"SELECT completions.comp_date != 0 as done, COUNT(completions.s_id) FROM stations, completions WHERE stations.enabled = 1 AND completions.s_id = stations.s_id GROUP BY done ORDER BY done"];
    NSInteger incompletions, completions;
    if(![result next]) {
        incompletions = completions = 0;
    } else if([result boolForColumnIndex:0]){
        incompletions = 0;
        completions = [result intForColumnIndex:1];
    } else {
        incompletions = [result intForColumnIndex:1];
        completions = [result next] ? [result intForColumnIndex:1] : 0;
    }
    [result close];
    result = [self.database executeQuery:@"SELECT completions.comp_date / 10000 AS year, COUNT(stations.s_id) FROM stations, completions WHERE completions.s_id = stations.s_id AND stations.enabled = 1 AND completions.comp_date > 0 GROUP BY year ORDER BY year DESC"];
    NSMutableArray* groups = [NSMutableArray array];
    while([result next]) {
        CompletionDateGroup *group = [[CompletionDateGroup alloc] init];
        NSInteger year = [result intForColumnIndex:0];
        group.code = [NSNumber numberWithInteger:year];
        group.total = completions;
        group.completions = [result intForColumnIndex:1];
        [groups addObject:group];
    }
    [result close];

    if(incompletions) {
        CompletionDateGroup *group = [[CompletionDateGroup alloc] init];
        group.code = @-1;
        group.total = completions + incompletions;
        group.completions = incompletions;
        [groups addObject:group];
    }

    return groups;
}

- (void)reloadCompletionYearGroup:(Group *)group
{
    NSInteger year = [group.code intValue];
    if(year >= 0) {
        FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(completions.s_id) FROM stations, completions WHERE stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date > 0"];
        group.total = [result next] ? [result intForColumnIndex:0] : 0;
        [result close];
        NSInteger maxYear, minYear;
        if(year) {
            minYear = year * 10000;
            maxYear = minYear + 1231;
        } else {
            minYear = maxYear = 1;
        }
        result = [self.database executeQuery:@"SELECT COUNT(stations.s_id) FROM stations, completions WHERE completions.s_id = stations.s_id AND stations.enabled = 1 AND completions.comp_date BETWEEN ? AND ?", [NSNumber numberWithInteger:minYear], [NSNumber numberWithInteger:maxYear]];
        group.completions = [result next] ? [result intForColumnIndex:0] : 0;
        [result close];
    } else {
        FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(completions.s_id) FROM stations, completions WHERE stations.enabled = 1 AND completions.s_id = stations.s_id AND completions.comp_date = 0"];
        group.total = [result next] ? [result intForColumnIndex:0] : 0;
        [result close];
    }
}

- (NSArray *)completionMonthGroupsWithYearGroup:(Group *)group
{
    NSInteger completions = group.completions;
    NSInteger minDate = [group.code intValue] * 10000;
    NSInteger maxDate = minDate + 1231;
    FMResultSet *result = [self.database executeQuery:@"SELECT completions.comp_date / 100 AS month, COUNT(stations.s_id) FROM stations, completions WHERE completions.s_id = stations.s_id AND stations.enabled = 1 AND completions.comp_date BETWEEN ? AND ? GROUP BY month ORDER BY month", [NSNumber numberWithInteger:minDate], [NSNumber numberWithInteger:maxDate]];
    NSMutableArray* groups = [NSMutableArray array];
    Group* ambiguous = nil;
    while([result next]) {
        CompletionDateGroup *group = [[CompletionDateGroup alloc] init];
        NSInteger month = [result intForColumnIndex:0];
        group.code = [NSNumber numberWithInteger:month];
        group.total = completions;
        group.completions = [result intForColumnIndex:1];
        if(month % 100) {
            [groups addObject:group];
        } else {
            ambiguous = group;
        }
    }
    [result close];
    
    if(ambiguous) {
        [groups addObject:ambiguous];
    }
    
    return groups;
}

- (void)reloadCompletionMonthGroup:(Group *)group
{
    NSInteger month = [group.code intValue] * 100;
    NSInteger minDate = month - (month % 10000);
    NSInteger maxDate = minDate + 1231;
    FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(stations.s_id) FROM stations, completions WHERE completions.s_id = stations.s_id AND stations.enabled = 1 AND completions.comp_date BETWEEN ? AND ? GROUP BY month ORDER BY month", [NSNumber numberWithInteger:minDate], [NSNumber numberWithInteger:maxDate]];
    group.total = [result next] ? [result intForColumnIndex:0] : 0;
    if(group.completions) {
        minDate = month;
        maxDate = month + 31;
        result = [self.database executeQuery:@"SELECT COUNT(stations.s_id) FROM stations, completions WHERE completions.s_id = stations.s_id AND stations.enabled = 1 AND completions.comp_date BETWEEN ? AND ? GROUP BY month ORDER BY month", [NSNumber numberWithInteger:minDate], [NSNumber numberWithInteger:maxDate]];
        group.completions = [result next] ? [result intForColumnIndex:0] : 0;
    } else {
        group.completions = 0;
    }
}

- (NSArray *)completionDateGroupsWithMonthGroup:(Group *)group
{
    NSInteger completions = group.completions;
    NSInteger minDate = [group.code intValue] * 100;
    NSInteger maxDate = minDate + 31;
    FMResultSet *result = [self.database executeQuery:@"SELECT completions.comp_date, COUNT(stations.s_id) FROM stations, completions WHERE completions.s_id = stations.s_id AND stations.enabled = 1 AND completions.comp_date BETWEEN ? AND ? GROUP BY completions.comp_date ORDER BY completions.comp_date", [NSNumber numberWithInteger:minDate], [NSNumber numberWithInteger:maxDate]];
    NSMutableArray* groups = [NSMutableArray array];
    Group* ambiguous = nil;
    while([result next]) {
        CompletionDateGroup *group = [[CompletionDateGroup alloc] init];
        NSInteger date = [result intForColumnIndex:0];
        group.code = [NSNumber numberWithInteger:date];
        group.total = completions;
        group.completions = [result intForColumnIndex:1];
        if(date % 100) {
            [groups addObject:group];
        } else {
            ambiguous = group;
        }
    }
    [result close];
    
    if(ambiguous) {
        [groups addObject:ambiguous];
    }
    
    return groups;
}

- (void)reloadCompletionDateGroup:(Group *)group
{
    NSInteger day = [group.code intValue];
    NSInteger minDate = day - (day % 10000);
    NSInteger maxDate = day + 31;
    FMResultSet *result = [self.database executeQuery:@"SELECT COUNT(stations.s_id) FROM stations, completions WHERE completions.s_id = stations.s_id AND stations.enabled = 1 AND completions.comp_date BETWEEN ? AND ?", [NSNumber numberWithInteger:minDate], [NSNumber numberWithInteger:maxDate]];
    group.total = [result next] ? [result intForColumnIndex:0] : 0;
    if(group.completions) {
        result = [self.database executeQuery:@"SELECT COUNT(stations.s_id) FROM stations, completions WHERE completions.s_id = stations.s_id AND stations.enabled = 1 AND completions.comp_date = ?", group.code];
        group.completions = [result next] ? [result intForColumnIndex:0] : 0;
    } else {
        group.completions = 0;
    }
}




@end
