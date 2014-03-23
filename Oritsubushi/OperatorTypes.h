//
//  OperatorTypes.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/24.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OperatorTypeJR = 1,
    OperatorTypeMajor = 2,
    OperatorTypeSemiMajor = 3,
    OperatorTypeMunicipal = 4,
    OperatorTypeLocal = 5,
    OperatorTypeMonorail = 6,
    OperatorTypeNTS = 7,
    OperatorTypeFunicular = 8,
    OperatorTypeTrolleybus = 9,
    OperatorTypeLevitated = 10,
    OPERATOR_TYPE_ERROR = 0
} OperatorType;

@interface OperatorTypes : NSObject

+ (NSInteger)numberOfOperatorTypes;
+ (NSString *)stringWithType:(OperatorType)type;
+ (OperatorType)typeWithString:(NSString *)string;
+ (NSArray *)operatorTypes;
+ (NSString *)heavyQueryKeyWithType:(OperatorType)type;

@end
