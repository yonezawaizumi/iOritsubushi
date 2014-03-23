//
//  Group.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/02.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface Group : NSObject

@property(nonatomic,strong) NSNumber *code;
@property(nonatomic,strong,readonly) NSString *headerTitle;
@property(nonatomic,strong) NSString *title;
@property(nonatomic) NSInteger total;
@property(nonatomic) NSInteger completions;
@property(nonatomic,readonly) NSInteger incompletions;
@property(nonatomic,readonly) NSInteger ratio;
@property(nonatomic,strong,readonly) NSString *description;
@property(nonatomic,strong,readonly) NSString *statusIconName;

+ (NSString *)statusIconNameWithCompletions:(NSInteger)completions total:(NSInteger)total;

@end
