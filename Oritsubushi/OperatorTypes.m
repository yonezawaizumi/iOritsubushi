//
//  OperatorTypes.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/24.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "OperatorTypes.h"
#import "Misc.h"

static NSString *operatorTypes_[] = {
    nil,
    @"JR旅客会社",
    @"大手私鉄",
    @"準大手私鉄",
    @"公営交通",
    @"中小私鉄",
    @"モノレール",
    @"新交通システム",
    @"ケーブルカー",
    @"トロリーバス",
    @"浮上式鉄道"
};

static BOOL initialized = NO;

@implementation OperatorTypes

+ (void)initialize
{
    for(int i = 0; i < countof(operatorTypes_); ++i) {
        if(operatorTypes_[i]) operatorTypes_[i] = NSLocalizedString(operatorTypes_[i], nil);
    }
    initialized = YES;
}

+ (NSInteger)numberOfOperatorTypes
{
    return countof(operatorTypes_) - 1;
}

+ (NSString *)stringWithType:(OperatorType)type
{
    if(!initialized)    [OperatorTypes initialize];
    return type < countof(operatorTypes_) ? operatorTypes_[type] : nil;
}

+ (OperatorType)typeWithString:(NSString *)string
{
    if(!initialized)    [OperatorTypes initialize];
    for(int i = 1/*operatorTypes[0] is nil*/; i < countof(operatorTypes_); ++i) {
        if([string isEqualToString:operatorTypes_[i]]) {
            return (OperatorType)i;
        }
    }
    return OPERATOR_TYPE_ERROR;
}

+ (NSArray *)operatorTypes
{
    static NSArray *results = nil;
    if(!results) {
        NSMutableArray *results_ = [NSMutableArray arrayWithCapacity:countof(operatorTypes_) - 1];
        for(int i = 1; i < countof(operatorTypes_); ++i) {
            [results_ addObject:[NSNumber numberWithInt:i]];
        }
        results = results_;
    }
    return results;
}

+ (NSString *)heavyQueryKeyWithType:(OperatorType)type
{
    return type == OperatorTypeLocal ? operatorTypes_[type] : nil;
}

@end
