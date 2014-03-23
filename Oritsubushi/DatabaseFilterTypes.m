//
//  DatabaseFilterTypes.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/05.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "DatabaseFilterTypes.h"
#import "Misc.h"
#import "Consts.h"

static BOOL initialized = NO;
static NSString *format = @"%@:%@ %@";
static NSString *prefixLabels[] = {
    @"地点",
    @"都道府県",
    @"駅名",
    @"駅名",
    @"読み",
    @"読み",
    @"路線",
    @"路線",
    @"乗下車日"
};
static NSString *suffixLabels[] = {
    @"",
    @"",
    @"で始まる",
    @"を含む",
    @"で始まる",
    @"を含む",
    @"で始まる",
    @"を含む",
    @""
};

@implementation DatabaseFilterTypes

+ (NSString *)formattedStringWithFilterType:(DatabaseFilterType)filterType searchKeyword:(NSString *)searchKeyword
{
    if(filterType >= NUM_DATABASE_FILTER_TYPES || ![searchKeyword length]) {
        return @"";
    }
    if(!initialized) {
        format = NSLocalizedString(format, nil);
        for(int index = 0; index < countof(prefixLabels); ++index) {
            prefixLabels[index] = NSLocalizedString(prefixLabels[index], nil);
        }
        for(int index = 0; index < countof(suffixLabels); ++index) {
            suffixLabels[index] = NSLocalizedString(suffixLabels[index], nil);
        }
        initialized = YES;
    }
    return [[NSString stringWithFormat:format, prefixLabels[filterType], searchKeyword, suffixLabels[filterType]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}


@end
