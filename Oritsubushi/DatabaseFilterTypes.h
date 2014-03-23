//
//  DatabaseFilterTypes.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/05.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    DatabaseFilterTypeNone,
    DatabaseFilterTypePref,
    DatabaseFilterTypeNameForward,
    DatabaseFilterTypeName,
    DatabaseFilterTypeYomiForward,
    DatabaseFilterTypeYomi,
    DatabaseFilterTypeLineForward,
    DatabaseFilterTypeLine,
    DatabaseFilterTypeDate,
    NUM_DATABASE_FILTER_TYPES
} DatabaseFilterType;

@interface DatabaseFilterTypes : NSObject

+ (NSString *)formattedStringWithFilterType:(DatabaseFilterType)filterType searchKeyword:(NSString *)searchKeyword;

@end
