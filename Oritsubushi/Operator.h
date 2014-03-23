//
//  Operator.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/24.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OperatorTypes.h"

@interface Operator : NSObject

@property(nonatomic) NSInteger code;
@property(nonatomic) OperatorType type;
@property(nonatomic,strong) NSString *name;

@end
