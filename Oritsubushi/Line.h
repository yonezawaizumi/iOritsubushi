//
//  Line.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/24.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LineTypes.h"
#import "FMDatabase.h"

@interface Line : NSObject

@property(nonatomic) NSInteger code;
@property(nonatomic) LineType type;
@property(nonatomic,strong) NSString *name;
@property(nonatomic) NSInteger operatorCode;

- (id)initWithFMResultSet:(FMResultSet *)resultSet;

@end
