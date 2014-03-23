//
//  Line.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/24.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "Line.h"

@implementation Line

@synthesize code, name, type, operatorCode;

- (id)initWithFMResultSet:(FMResultSet *)resultSet
{
    self = [super init];
    if(self) {
        self.code = [resultSet intForColumnIndex:0];
        self.name = [resultSet stringForColumnIndex:1];
        self.operatorCode = [resultSet intForColumnIndex:2];
        self.type = [resultSet intForColumnIndex:4];
    }
    return self;
}

- (void)dealloc
{
    self.name = nil;
}

@end
