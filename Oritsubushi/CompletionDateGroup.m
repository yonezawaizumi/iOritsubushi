//
//  CompletionDateGroup.m
//  Oritsubushi
//
//  Created by よねざわいずみ on 12/10/09.
//  Copyright (c) 2012年 合資会社ダブルエスエフ. All rights reserved.
//

#import "CompletionDateGroup.h"

@implementation CompletionDateGroup


- (NSString *)description
{
    NSInteger ratio_ = self.ratio;
    return ratio_ >= 0 ? [NSString stringWithFormat:NSLocalizedString(@"%d駅中 %d駅　%d.%d%%", nil),
                          self.total, self.completions, self.ratio / 10, self.ratio % 10] : nil;
}

- (NSString *)title
{
    NSInteger date = [self.code integerValue];
    if(date < 0) {
        return @"未乗下車";
    } else if(!date) {
        return @"年月日不明";
    } else if(date <= 9999) {
        return [NSString stringWithFormat:@"%d年", date];
    } else if(date <= 999912) {
        NSInteger year = date / 100;
        NSInteger month = date % 100;
        return month ? [NSString stringWithFormat:@"%d年%d月", year, month] : [NSString stringWithFormat:@"%d年 月日不明", year];
    } else {
        NSInteger year = date / 10000;
        NSInteger month = date / 100 % 100;
        NSInteger day = date % 100;
        return day ? [NSString stringWithFormat:@"%d年%d月%d日", year, month, day] : [NSString stringWithFormat:@"%d年%d月 日付不明", year, month];
    }
}

- (NSString *)headerTitle
{
    NSInteger date = [self.code integerValue];
    if(date <= 999912) {
        return self.title;
    } else {
        NSInteger month = date / 100 % 100;
        NSInteger day = date % 100;
        return day ? [NSString stringWithFormat:@"%d月%d日", month, day] : [NSString stringWithFormat:@"%d月 日付不明", month];
    }
}

- (NSString *)cellTitle
{
    NSInteger date = [self.code integerValue];
    if(date <= 9999) {
        return self.title;
    } else if(date <= 999912) {
        NSInteger month = date % 100;
        return month ? [NSString stringWithFormat:@"%d月", month] : @"月日不明";
    } else {
        NSInteger day = date % 100;
        return day ? [NSString stringWithFormat:@"%d日", day] : @"日付不明";
    }
}

+ (BOOL)completionDateRangeWithSearchKeyword:(NSString *)searchKeyword range:(NSRange *)range
{
    if(!range) {
        return NO;
    }
    BOOL isAmbigous = [searchKeyword rangeOfString:@"不明"].location != NSNotFound;
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    NSScanner *scanner = [NSScanner scannerWithString:searchKeyword];
    NSMutableArray *ints = [NSMutableArray arrayWithCapacity:4];
    while(![scanner isAtEnd]) {
        NSInteger value;
        if([scanner scanInteger:&value] && value > 0) {
            [ints addObject:[NSNumber numberWithInt:value]];
        } else {
            break;
        }
        [scanner scanUpToCharactersFromSet:characterSet intoString:NULL];
    }
    switch([ints count]) {
        case 0:
            if(isAmbigous) {
                range->location = 1;
                range->length = 0;
                return YES;
            } else {
                return NO;
            }
        case 1:
            range->location = [[ints objectAtIndex:0] integerValue] * 10000;
            range->length = isAmbigous ? 0 : 1231;
            return YES;
        case 2:
            range->location = [[ints objectAtIndex:0] intValue] * 10000 + [[ints objectAtIndex:1] intValue] * 100;
            range->length = isAmbigous ? 0 : 31;
            return YES;
        case 3:
            if(isAmbigous) {
                return NO;
            } else {
                range->location = [[ints objectAtIndex:0] intValue] * 10000 + [[ints objectAtIndex:1] intValue] * 100 + [[ints objectAtIndex:2] intValue];
                range->length = 0;
                return YES;
            }
        default:
            return NO;
    }
    
}

@end

