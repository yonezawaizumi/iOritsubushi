//
//  Station.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/10/31.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "Station.h"
#import "AppDelegate.h"
#import "Line.h"
#import "Misc.h"
#import "Consts.h"

static NSInteger completionDateIndex = -1;
static NSInteger memoIndex = -1;
static NSInteger updatedDateIndex = -1;
static NSDateFormatter *updatedDateFormatter;

@interface Station ()

@property(nonatomic) CLLocationCoordinate2D centerCoordinate_;
@property(nonatomic) CGFloat distance_;
@property(nonatomic,strong) NSString *distanceString_;
@property(nonatomic,strong) NSString *subtitle_;
@property(nonatomic,strong) Operator *operator_;
@property(nonatomic,strong) NSArray *lines_;
@property(nonatomic,strong) NSString *wiki_;

@end

@implementation Station

@synthesize code;
@synthesize name;
@synthesize coordinate;

@synthesize yomi;
@synthesize wiki_;
@synthesize pref;
@synthesize address;
@synthesize operatorCode;

@synthesize completionDate;
@synthesize memo;
@synthesize updatedDate;

@synthesize centerCoordinate_, distance_, distanceString_, subtitle_, operator_, lines_;

- (id)initWithFMResultSet:(FMResultSet *)resultSet
{
    self = [super init];
    if(self) {
        if(completionDateIndex < 0) {
            completionDateIndex = [resultSet columnIndexForName:@"comp_date"];
            memoIndex = [resultSet columnIndexForName:@"memo"];
            updatedDateIndex = [resultSet columnIndexForName:@"update_date"];
        }
        self.code = [NSNumber numberWithInt:[resultSet intForColumnIndex:0]];
        self.name = [resultSet stringForColumnIndex:1];
        self.yomi = [resultSet stringForColumnIndex:2];
        self.wiki_ = [resultSet stringForColumnIndex:3];
        self.pref = (PrefType)[resultSet intForColumnIndex:4];
        self.address = [resultSet stringForColumnIndex:5];
        self.coordinate = CLLocationCoordinate2DMake((CLLocationDegrees)[resultSet intForColumnIndex:6] / 1e6,
                                                     (CLLocationDegrees)[resultSet intForColumnIndex:7] / 1e6);
        self.operatorCode = [resultSet intForColumnIndex:8];
        self.completionDate = [resultSet intForColumnIndex:completionDateIndex];
        self.memo = [resultSet stringForColumnIndex:memoIndex];
        self.updatedDate = [resultSet intForColumnIndex:updatedDateIndex];
        
        self.distance_ = -1;
        self.distanceString_ = nil;
    }
    return self;
}

- (void)dealloc
{
    self.code = nil;
    self.name = nil;
    self.yomi = nil;
    self.wiki_ = nil;
    self.address = nil;
    self.distanceString_ = nil;
    self.memo = nil;    
    self.operator_ = nil;
    self.lines_ = nil;
}


- (double)calculateDistanceFrom:(CLLocationCoordinate2D)coordinate_
{
    double y1 = self.coordinate.latitude * M_PI / 180;
	double x1 = self.coordinate.longitude * M_PI / 180;
	double y2 = coordinate_.latitude * M_PI / 180;
	double x2 = coordinate_.longitude * M_PI / 180;
    double earth_r = 6378137;
    
	double deg = sin(y1) * sin(y2) + cos(y1) * cos(y2) * cos(x2 - x1);
	return earth_r * (atan(-deg / sqrt(-deg * deg + 1)) + M_PI / 2) / 1000;
}

- (NSString *)distanceStringWithDistance:(double)distance
{
    if(self.distance_ <= 0.01) {
        return NSLocalizedString(@"すぐそば", nil);
    } else if(distance_ < 1) {
        NSString *formatString = NSLocalizedString(@"%dm", nil);
        return [NSString stringWithFormat:formatString, (int)(self.distance_ * 1000)];
    } else if(distance_ < 10) {
        NSString *formatString = NSLocalizedString(@"%.1fkm", nil);
        return [NSString stringWithFormat:formatString, self.distance_];
    } else {
        NSString *formatString = NSLocalizedString(@"%dkm", nil);
        return [NSString stringWithFormat:formatString, (int)self.distance_];        
    }    
}

- (CGFloat)distance
{
    if(self.distance_ < 0) {
        self.distance_ = [self calculateDistanceFrom:self.centerCoordinate];
    }
    return self.distance_;
}

- (NSString *)distanceString
{
    if(self.distance_ < 0) {
        self.distance_ = [self calculateDistanceFrom:self.centerCoordinate];
    }
    if(!self.distanceString_) {
        self.distanceString_ = [self distanceStringWithDistance:self.distance_];
    }
    return self.distanceString_;
}

- (NSString *)distanceStringFrom:(CLLocationCoordinate2D)coodinate
{
    return [self distanceStringWithDistance:[self calculateDistanceFrom:coordinate]];
}

- (CLLocationCoordinate2D)centerCoordinate
{
    return self.centerCoordinate_;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
{
    self.centerCoordinate_ = centerCoordinate;
    self.distance_ = -2;
    self.distanceString_ = nil;
}

- (BOOL)isCompleted
{
    return self.completionDate > 0;
}

- (NSString *)wiki
{
    return [self.wiki_ length] ? self.wiki_ : self.name;
}

- (void)setWiki:(NSString *)wiki
{
    self.wiki_ = wiki;
}

//MKAnnotation protocol
- (NSString *)title
{
    return self.name;
}

- (NSString *)subtitle
{
    if(!self.subtitle_) {
        NSMutableString *subtitle = [NSMutableString stringWithFormat:@"%@ / ", self.operator.name];
        for(Line *line in self.lines) {
            [subtitle appendFormat:@"%@, ", line.name];
        }
        self.subtitle_ = [subtitle substringToIndex:([subtitle length] - 2)];
    }
    return self.subtitle_;
}

- (Operator *)operator
{
    if(!self.operator_) {
        AppDelegate *delegate = [UIApplication sharedApplication].delegate;
        self.operator_ = [delegate.database operatorWithCode:[NSNumber numberWithInt:self.operatorCode]];
    }
    return self.operator_;
}

- (NSArray *)lines
{
    if(!self.lines_) {
        AppDelegate *delegate = [UIApplication sharedApplication].delegate;
        self.lines_ = [delegate.database linesWithStation:self];
    }
    return self.lines_;
}

- (NSString *)completionDateString
{
    if(self.completionDate <= 0) {
        return INCOMPLETION_STRING;
    } else if(0 < self.completionDate && self.completionDate < 19000000) {
        return NSLocalizedString(@"乗下車済 (日付不明)", nil);
    }
    NSInteger year = self.completionDate / 10000;
    NSInteger month = self.completionDate % 10000 / 100;
    NSInteger day = self.completionDate % 100;
    if(!month) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d年頃", nil), year];
    } else if(!day) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d年%d月頃", nil), year, month];
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"%d年%d月%d日", nil), year, month, day];
    }
}

- (NSString *)completionDateShortString
{
    if(self.completionDate <= 0) {
        return NSLocalizedString(@"未", nil);
    } else if(0 < self.completionDate && self.completionDate < 19000000) {
        return NSLocalizedString(@"日付不明", nil);
    }
    NSInteger year = self.completionDate / 10000 % 100;
    NSInteger month = self.completionDate % 10000 / 100;
    NSInteger day = self.completionDate % 100;
    if(!month) {
        return [NSString stringWithFormat:NSLocalizedString(@"%02d年頃", nil), year];
    } else if(!day) {
        return [NSString stringWithFormat:NSLocalizedString(@"%02d/%d頃", nil), year, month];
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"%02d/%d/%d", nil), year, month, day];
    }    
}

+ (NSString *)statusIconNameWithCompleted:(BOOL)isCompleted
{
    return isCompleted ? @"statusicon_comp" : @"statusicon_incomp";
}

- (NSString *)statusIconName
{
    return [Station statusIconNameWithCompleted:self.isCompleted];
}

- (void)setTodayCompletion
{
    self.completionDate = [Misc today];
}

- (NSString *)updatedDateString
{
    if(self.updatedDate > 0) {
        if(!updatedDateFormatter) {
            updatedDateFormatter = [[NSDateFormatter alloc] init];
            updatedDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
            updatedDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Tokyo"];
            updatedDateFormatter.dateFormat = NSLocalizedString(@"yyyy/MM/dd HH:mm:ss z", nil);
        }
        return [NSLocalizedString(@"最終更新日時　", nil) stringByAppendingString:[updatedDateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.updatedDate]]];
    } else {
        return NSLocalizedString(@"(一度も更新されていません)", nil);
    }
}

@end
