//
//  LineTypes.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/24.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "LineTypes.h"
#import "Misc.h"

static NSString *lineTypes[] = {
    nil,
    @"新幹線",
    @"JR在来線",
    nil,
    nil,
    nil,
    @"大手私鉄",
    @"路面電車",
    @"準大手私鉄",
    @"路面電車",
    @"公営交通",
    @"路面電車",
    @"中小私鉄",
    @"路面電車",
    nil,
    nil,
    @"モノレール",
    nil,
    @"新交通システム",
    nil,
    @"ケーブルカー",
    nil,
    @"トロリーバス",
    nil,
    @"浮上式鉄道"
};

static BOOL initialized = NO;

@implementation LineTypes

+ (void)initialize
{
    for(int i = 0; i < countof(lineTypes); ++i) {
        if(lineTypes[i]) lineTypes[i] = NSLocalizedString(lineTypes[i], nil);
    }
    initialized = YES;
}

+ (NSString *)stringWithType:(LineType)type
{
    if(!initialized)    [LineTypes initialize];
    return type < countof(lineTypes) ? lineTypes[type] : nil;
}

+ (LineType)typeWithString:(NSString *)string
{
    if(!initialized)    [LineTypes initialize];
    for(int i = 1/*lineTypes[0] is nil*/; i < countof(lineTypes); ++i) {
        if([string isEqualToString:lineTypes[i]]) {
            return (LineType)i;
        }
    }
    return LINE_TYPE_ERROR;
}

@end
