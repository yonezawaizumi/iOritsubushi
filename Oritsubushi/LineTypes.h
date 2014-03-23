//
//  LineTypes.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/24.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    LineTypeBullet = 1,
    LineTypeJRConventional = 2,
    LineTypeMajor = 6,
    LineTypeMajorTram = 7,
    LineTypeSemiMajor = 8,
    LineTypeSemiMajorTram = 9,
    LineTypeMunicipal = 10,
    LineTypeMunicipalTram = 11,
    LineTypeLocal = 12,
    LineTypeLocalTram = 13,
    LineTypeMonorail = 16,
    LineTypeNTS = 18,
    LineTypeFunicular = 20,
    LineTypeTrolleybus = 22,
    LineTypeLevitated = 24,
    LINE_TYPE_ERROR = 0
} LineType;

@interface LineTypes : NSObject

+ (NSString *)stringWithType:(LineType)type;
+ (LineType)typeWithString:(NSString *)string;

@end
