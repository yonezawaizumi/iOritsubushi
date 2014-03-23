//
//  Operator.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/24.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "Operator.h"

@implementation Operator

@synthesize name, code, type;

- (void)dealloc
{
    self.name = nil;
}

@end
